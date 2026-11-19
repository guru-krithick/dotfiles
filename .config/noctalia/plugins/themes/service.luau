--!nonstrict
-- The long-lived half of the theme carousel. It keeps `theme catalog` ready so
-- the overlay opens at once, draws missing cards in the background, shows and
-- hides the overlay (and Mango's key mode for it), and applies what the
-- overlay settles on, one switch at a time: a target that lands while a
-- switch runs replaces any waiting one and starts when the running one ends.
-- It runs for the whole session, so switches finish after the overlay closes.
local command = noctalia.expandPath("~/.local/bin/theme")
local LAYER = "carousel"
local KEYMODE = "themes" -- Mango key mode that forwards the arrows (mango/config.conf)
local CLOSE_FALLBACK_MS = 1200 -- hide even if the overlay never reports its close

local catalog = nil
local reading, readAgain = false, false
local drawing, drawRuns = false, 0
local shown = false
local closeDeadline = nil
local closeSeq = 0
local running, queued = nil, nil
local handled = {}
local drawCards

local function now()
    return noctalia.nowMs()
end

local function setKeymode(mode)
    if noctalia.commandExists("mmsg") then
        noctalia.runAsync({ "mmsg", "dispatch", "setkeymode," .. mode })
    end
end

local function liveTheme()
    local source = noctalia.getSetting("theme.source")
    if source == "custom" then
        return noctalia.getSetting("theme.custom_palette")
    end
    return nil
end

local function readCatalog()
    if reading then
        readAgain = true
        return
    end
    reading = true
    local accepted = noctalia.runAsync({ command, "catalog" }, function(result)
        reading = false
        local data = result.exitCode == 0 and not result.timedOut and noctalia.json.decode(result.stdout) or nil
        if type(data) == "table" and type(data.themes) == "table" then
            catalog = data
            noctalia.state.set("catalog", catalog)
            if (tonumber(data.missing) or 0) > 0 then
                drawCards()
            else
                drawRuns = 0
            end
        else
            noctalia.log("theme catalog failed: " .. tostring(result.stderr))
            if catalog == nil then
                noctalia.state.set("catalog", { themes = {}, failed = true })
            end
        end
        if readAgain then
            readAgain = false
            readCatalog()
        end
    end, 30000)
    if not accepted then
        reading = false
    end
end

-- `theme cards` marks pictures ffmpeg cannot read, so this converges; the
-- run limit only guards against a cache that cannot be written at all.
drawCards = function()
    if drawing or drawRuns >= 3 then
        return
    end
    drawing = true
    drawRuns = drawRuns + 1
    local accepted = noctalia.runAsync({ command, "cards" }, function(result)
        drawing = false
        if result.exitCode ~= 0 or result.timedOut then
            noctalia.log("theme cards failed: " .. tostring(result.stderr))
        end
        readCatalog()
    end, 600000)
    if not accepted then
        drawing = false
    end
end

local start
local function finish(job, ok, detail)
    running = nil
    if not ok then
        noctalia.log("theme switch failed: " .. tostring(detail))
        if not shown then
            noctalia.notifyError("Theme", "Could not apply " .. tostring(job.name or job.theme))
        end
    end
    noctalia.state.set("status", { id = job.id, state = ok and "done" or "failed",
        message = ok and "" or "Could not apply " .. tostring(job.name or job.theme) })
    local nextJob = queued
    queued = nil
    -- A waiting target equal to the one that just landed needs no second run.
    if nextJob and ok and not nextJob.force and nextJob.theme == job.theme
        and nextJob.wallpaper == job.wallpaper then
        noctalia.state.set("status", { id = nextJob.id, state = "done", message = "" })
        nextJob = nil
    end
    if nextJob then
        start(nextJob)
    else
        readCatalog() -- remembered wallpapers have changed
    end
end

start = function(job)
    running = job
    noctalia.state.set("status", { id = job.id, state = "applying", message = "" })
    -- Same theme: only the picture changes. Another theme, or a retry after a
    -- partial failure: the whole switch, palette, bar, folder and picture.
    local argv
    if job.force or not job.wallpaper or job.theme ~= liveTheme() then
        argv = { command, "set", job.theme }
        if job.wallpaper then
            table.insert(argv, "--wallpaper")
            table.insert(argv, job.wallpaper)
        end
    else
        argv = { command, "wallpaper", job.wallpaper }
    end
    local accepted = noctalia.runAsync(argv, function(result)
        finish(job, result.exitCode == 0 and not result.timedOut, result.stderr)
    end, 60000)
    if not accepted then
        finish(job, false, "could not start " .. command)
    end
end

local function request(job)
    if type(job) ~= "table" or type(job.id) ~= "string" or type(job.theme) ~= "string" or handled[job.id] then
        return
    end
    handled[job.id] = true
    if running then
        if queued then
            noctalia.state.set("status", { id = queued.id, state = "replaced", message = "" })
        end
        queued = job
        noctalia.state.set("status", { id = job.id, state = "queued", message = "" })
    else
        start(job)
    end
end

local function show()
    if shown then
        return
    end
    shown = true
    closeDeadline = nil
    noctalia.layer.show(LAYER)
    setKeymode(KEYMODE)
    readCatalog()
end

local function hide()
    shown = false
    closeDeadline = nil
    noctalia.layer.hide(LAYER)
    setKeymode("default")
end

local function close()
    if not shown then
        return
    end
    closeSeq = closeSeq + 1
    noctalia.state.set("command", { kind = "close", seq = closeSeq, at = now() })
    closeDeadline = now() + CLOSE_FALLBACK_MS
    noctalia.setUpdateInterval(250)
end

function update()
    if closeDeadline and now() >= closeDeadline then
        noctalia.log("carousel did not close itself; hiding it")
        hide()
    end
    if not closeDeadline then
        noctalia.setUpdateInterval(60000)
    end
end

function onIpc(event, payload)
    if event == "toggle" then
        if shown then close() else show() end
    elseif event == "open" then
        show()
    elseif event == "close" then
        close()
    elseif event == "refresh" then
        readCatalog()
    end
end

function onConfigChanged()
    -- Only liveTheme() reads shell settings; nothing to refresh eagerly.
end

-- The overlay reports when its closing animation has finished.
noctalia.state.watch("layer", function(value)
    if type(value) == "table" and value.closed then
        hide()
    end
end)
noctalia.state.watch("request", request)

-- Requests and closes published before a reload are history, not new work.
local previous = noctalia.state.get("request")
if type(previous) == "table" and type(previous.id) == "string" then
    handled[previous.id] = true
end
noctalia.setUpdateInterval(60000)
-- A shell restart while the carousel was open leaves Mango in its key mode.
if noctalia.commandExists("mmsg") then
    noctalia.runAsync({ "mmsg", "get", "keymode" }, function(result)
        if result.exitCode == 0 and string.find(result.stdout or "", '"' .. KEYMODE .. '"', 1, true) then
            setKeymode("default")
        end
    end)
end
readCatalog()
