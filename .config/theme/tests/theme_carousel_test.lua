-- Run the theme carousel's two entries (the switcher service and the overlay
-- layer) against a fake Noctalia host: a shared, asynchronously delivered
-- plugin state channel, a controllable clock, recorded subprocesses, frame
-- ticks and update() calls. This verifies behaviour and timing, not native
-- layout, painting, keyboard focus or Mango's key mode.
--   lua theme_carousel_test.lua <plugin directory>
local dir = assert(arg[1], "usage: lua theme_carousel_test.lua <plugin dir>")

local function readAll(path)
    local file = assert(io.open(path, "r"))
    local text = file:read("a")
    file:close()
    return text
end
local SERVICE, CAROUSEL = readAll(dir .. "/service.luau"), readAll(dir .. "/carousel.luau")

local function copy(value)
    if type(value) ~= "table" then
        return value
    end
    local out = {}
    for k, v in pairs(value) do
        out[k] = copy(v)
    end
    return out
end

-- The host -----------------------------------------------------------------------------

local H -- host state, rebuilt for every scenario
local function reset(options)
    options = options or {}
    H = {
        clock = 1000000,
        settings = {
            ["theme.source"] = "custom", ["theme.custom_palette"] = "tokyo-night",
            ["accessibility.ui_scale"] = 1.1, ["shell.animation.enabled"] = true,
            ["shell.animation.speed"] = 1,
        },
        wallpaper = "/w/tokyo-night/b.jpg",
        store = {}, watchers = {}, mail = {},
        procs = {}, fired = {}, logs = {}, notices = {},
        shown = false, shows = 0, hides = 0,
        layerEnv = nil, tree = nil, ticking = false, interval = {},
    }
    for k, v in pairs(options.settings or {}) do
        H.settings[k] = v
    end
end

local function sample(themes)
    -- themes: { { id, { picture names... }, remembered } }
    local catalog = { themes = {}, missing = 0 }
    for _, t in ipairs(themes) do
        local walls = {}
        for _, name in ipairs(t[2]) do
            table.insert(walls, { path = "/w/" .. t[1] .. "/" .. name, name = name, card = "/c/" .. name .. ".png",
                ready = true })
        end
        table.insert(catalog.themes, { id = t[1], name = t[1], colors = { primary = "#7aa2f7", surface = "#1a1b26" },
            remembered = t[3] and ("/w/" .. t[1] .. "/" .. t[3]) or nil, wallpapers = walls,
            placeholder = "/c/placeholder.png" })
    end
    return catalog
end
local CATALOG = sample({
    { "catppuccin", { "a.jpg", "b.jpg" }, "b.jpg" },
    { "tokyo-night", { "a.jpg", "b.jpg", "c.jpg" }, "b.jpg" },
    { "ultra-dark", { "a.jpg", "b.jpg" }, "a.jpg" },
})

local function makeUi()
    return setmetatable({}, { __index = function(_, kind)
        return function(props, children)
            return { kind = kind, props = props or {}, children = children or {} }
        end
    end })
end

local function makeNoctalia(entry)
    return {
        nowMs = function() return H.clock end,
        getSetting = function(path) return H.settings[path] end,
        wallpaperPath = function() return H.wallpaper end,
        outputs = function() return { { name = "HEADLESS-1", width = 1920, height = 1080, scale = 1 } } end,
        expandPath = function() return "/home/test user/.local/bin/theme" end,
        commandExists = function(name) return name == "mmsg" end,
        runAsync = function(argv, callback)
            if H.reject then
                return false
            end
            local proc = { argv = argv, callback = callback, entry = entry }
            if callback then
                table.insert(H.procs, proc)
            else
                table.insert(H.fired, proc)
            end
            return true
        end,
        json = { decode = function(text) return H.decoded and H.decoded[text] end },
        log = function(text) table.insert(H.logs, text) end,
        notifyError = function(_, body) table.insert(H.notices, body) end,
        setUpdateInterval = function(ms) H.interval[entry] = ms end,
        state = {
            set = function(key, value)
                H.store[key] = copy(value)
                for _, w in ipairs(H.watchers[key] or {}) do
                    table.insert(H.mail, { fn = w, value = copy(value) })
                end
            end,
            get = function(key) return copy(H.store[key]) end,
            watch = function(key, fn)
                H.watchers[key] = H.watchers[key] or {}
                table.insert(H.watchers[key], fn)
            end,
        },
        layer = {
            show = function(id)
                assert(id == "carousel")
                if not H.shown then
                    H.shown, H.shows = true, H.shows + 1
                    H.startLayer()
                end
            end,
            hide = function(id)
                assert(id == "carousel")
                if H.shown then
                    H.shown, H.hides = false, H.hides + 1
                    H.stopLayer()
                end
            end,
        },
    }
end

local function loadEntry(source, name, globals)
    local env = setmetatable(globals, { __index = _G })
    local chunk = assert(load(source, "=" .. name, "t", env))
    chunk()
    return env
end

local S -- the service's environment
local function startService()
    S = loadEntry(SERVICE, "service.luau", { noctalia = makeNoctalia("service"), ui = makeUi() })
end

local function startHost(options)
    reset(options)
    H.startLayer = function()
        local before = {}
        for key, list in pairs(H.watchers) do
            before[key] = #list
        end
        H.layerWatchStart = before
        H.layerEnv = loadEntry(CAROUSEL, "carousel.luau", {
            noctalia = makeNoctalia("layer"), ui = makeUi(),
            layer = {
                render = function(tree) H.tree = tree end,
                setNeedsFrameTick = function(on) H.ticking = on end,
                outputName = function() return "HEADLESS-1" end,
            },
        })
    end
    H.stopLayer = function()
        -- Hiding destroys the runtime: its watchers go away with it.
        for key, list in pairs(H.watchers) do
            local keep = H.layerWatchStart[key] or 0
            while #list > keep do
                table.remove(list)
            end
        end
        H.layerEnv, H.tree, H.ticking = nil, nil, false
    end
    startService()
end

-- Deliver queued state notifications (the host does this between callbacks).
local function pump()
    local guard = 0
    while #H.mail > 0 do
        local m = table.remove(H.mail, 1)
        m.fn(m.value)
        guard = guard + 1
        assert(guard < 1000, "state notifications never settle")
    end
end

local function finish(proc, stdout, code)
    proc.callback({ exitCode = code or 0, stdout = stdout or "", stderr = code and code ~= 0 and "boom" or "",
        timedOut = false })
    pump()
end

local function catalogProc()
    for i, p in ipairs(H.procs) do
        if p.argv[2] == "catalog" then
            return table.remove(H.procs, i)
        end
    end
end

local function serveCatalog(catalog)
    H.decoded = { catalog = catalog or CATALOG }
    local proc = catalogProc()
    while proc do
        finish(proc, "catalog")
        proc = catalogProc()
    end
end

local function switchProcs()
    local out = {}
    for _, p in ipairs(H.procs) do
        if p.argv[2] == "set" or p.argv[2] == "wallpaper" then
            table.insert(out, p)
        end
    end
    return out
end

local function takeSwitch()
    for i, p in ipairs(H.procs) do
        if p.argv[2] == "set" or p.argv[2] == "wallpaper" then
            return table.remove(H.procs, i)
        end
    end
end

-- Advance time: frame ticks every 16 ms while the layer wants them, update()
-- every 100 ms for both entries, state delivered after each callback.
local function advance(ms)
    local stop = H.clock + ms
    local nextUpdate = H.clock + 100
    while H.clock < stop do
        H.clock = math.min(stop, H.clock + 16)
        if H.layerEnv and H.ticking then
            H.layerEnv.onFrameTick("16")
            pump()
        end
        if H.clock >= nextUpdate then
            nextUpdate = nextUpdate + 100
            if H.layerEnv and H.layerEnv.update then
                H.layerEnv.update()
                pump()
            end
            if S.update then
                S.update()
                pump()
            end
        end
    end
end

local function ipcService(event, payload)
    S.onIpc(event, payload or "")
    pump()
end
local function key(event, payload)
    assert(H.layerEnv, "the overlay is not shown")
    H.layerEnv.onIpc(event, payload or "")
    pump()
end

-- Tree inspection --------------------------------------------------------------------------

local function find(predicate, node)
    node = node or H.tree
    if not node then
        return nil
    end
    if predicate(node) then
        return node
    end
    for _, child in ipairs(node.children or {}) do
        local found = find(predicate, child)
        if found then
            return found
        end
    end
end
local function keyed(k)
    return find(function(n) return n.props.key == k end)
end
local function label(k)
    local n = keyed(k)
    return n and n.props.text
end
local function centreSlot()
    -- The card drawn last in the band is the centre one.
    local band = keyed("band")
    for i = #band.children, 1, -1 do
        local n = band.children[i]
        if string.match(n.props.key, "^s%-?%d+$") then
            return n
        end
    end
end
local function selected()
    return label("theme") .. "/" .. label("wallpaper")
end
local function requests()
    return H.store.request
end
local function modes()
    local out = {}
    for _, p in ipairs(H.fired) do
        if p.argv[1] == "mmsg" then table.insert(out, p.argv[3]) end
    end
    return out
end

-- Read the overlay's motion state (its locals) through the debug library.
local function upvalue(fn, name, seen)
    seen = seen or {}
    if type(fn) ~= "function" or seen[fn] then
        return nil
    end
    seen[fn] = true
    local i = 1
    while true do
        local n, v = debug.getupvalue(fn, i)
        if not n then
            return nil
        end
        if n == name then
            return v
        end
        local found = upvalue(v, name, seen)
        if found ~= nil then
            return found
        end
        i = i + 1
    end
end
local function motion()
    return { target = upvalue(H.layerEnv.onFrameTick, "target"), pos = upvalue(H.layerEnv.onFrameTick, "pos") }
end

local function open()
    ipcService("toggle")
    serveCatalog()
    advance(300) -- the opening animation
end

local passed = 0
local function check(_name, fn)
    fn()
    passed = passed + 1
end

-- Scenarios -------------------------------------------------------------------------------------

check("opening shows the live card, enters the key mode and never applies", function()
    startHost()
    serveCatalog() -- the catalog read at service start
    assert(H.store.catalog and #H.store.catalog.themes == 3)
    ipcService("toggle")
    assert(H.shown and H.shows == 1)
    local m = modes()
    assert(m[#m] == "setkeymode,themes", "key mode: " .. tostring(m[#m]))
    assert(H.tree and keyed("band"), "the band renders from the cached catalog at once")
    advance(5000)
    assert(selected() == "tokyo-night/b.jpg", selected())
    assert(requests() == nil and #switchProcs() == 0, "opening applied something")
    assert(find(function(n) return n.props.key and string.match(n.props.key, "^live") end), "current marker")
    assert(not H.ticking, "frame ticks stop once everything has settled")
end)

check("dwell: nothing before 600 ms, exactly one switch after settling", function()
    startHost()
    open()
    key("press", "right")
    key("release", "right")
    advance(560) -- motion (~140 ms) + most of the dwell
    assert(requests() == nil, "applied before the dwell elapsed")
    advance(400)
    local r = requests()
    assert(r and r.theme == "tokyo-night" and r.wallpaper == "/w/tokyo-night/c.jpg", "one request for the landing")
    local procs = switchProcs()
    assert(#procs == 1, "one switch runs")
    -- Same theme: only the wallpaper changes.
    assert(procs[1].argv[2] == "wallpaper" and procs[1].argv[3] == "/w/tokyo-night/c.jpg")
    advance(2000)
    assert(#switchProcs() == 1, "no repeated apply while waiting")
end)

check("browsing steps faster than the dwell never apply; another theme uses theme set", function()
    startHost()
    open()
    for _ = 1, 4 do
        key("press", "right")
        key("release", "right")
        advance(300)
    end
    assert(requests() == nil and #switchProcs() == 0, "applied while browsing")
    advance(700)
    local procs = switchProcs()
    assert(#procs == 1)
    -- tokyo-night/b -> 4 steps right: c, ultra-dark/a, ultra-dark/b, catppuccin/a (wrapped)
    assert(procs[1].argv[2] == "set" and procs[1].argv[3] == "catppuccin" and procs[1].argv[4] == "--wallpaper"
        and procs[1].argv[5] == "/w/catppuccin/a.jpg", table.concat(procs[1].argv, " "))
end)

check("latest wins: one switch at a time, intermediate targets are skipped", function()
    startHost()
    open()
    key("press", "right"); key("release", "right")
    advance(900) -- tokyo-night/c applies (running)
    assert(#switchProcs() == 1)
    key("press", "right"); key("release", "right")
    advance(900) -- ultra-dark/a lands while c runs: queued
    key("press", "right"); key("release", "right")
    advance(900) -- ultra-dark/b replaces it
    assert(#switchProcs() == 1, "a second switch started while one runs")
    finish(takeSwitch())
    local procs = switchProcs()
    assert(#procs == 1 and procs[1].argv[3] == "ultra-dark" and procs[1].argv[5] == "/w/ultra-dark/b.jpg",
        "the latest target runs next: " .. (procs[1] and table.concat(procs[1].argv, " ") or "none"))
    H.settings["theme.custom_palette"] = "ultra-dark"
    finish(takeSwitch())
    advance(1000)
    assert(#switchProcs() == 0, "the skipped target never runs")
end)

check("Enter applies at once and closes; Escape closes keeping what was applied", function()
    startHost()
    open()
    key("press", "left"); key("release", "left")
    advance(200)
    key("press", "return")
    assert(requests() and requests().wallpaper == "/w/tokyo-night/a.jpg", "Enter requested the selection")
    advance(400)
    assert(not H.shown and H.hides == 1, "Enter closed the overlay")
    local m = modes()
    assert(m[#m] == "setkeymode,default", "key mode restored")
    assert(#switchProcs() == 1, "the switch continues after the overlay closed")
    finish(takeSwitch())
    -- Escape: a pending dwell is dropped, nothing is applied.
    open()
    local before = requests()
    key("press", "right"); key("release", "right")
    advance(300)
    key("close")
    advance(1500)
    assert(not H.shown and requests() == before and #switchProcs() == 0, "Escape applied the browsed card")
end)

check("the ring wraps both ways and Up/Down jump between themes", function()
    startHost()
    open()
    -- Up: catppuccin at its remembered b.jpg; Up again wraps to ultra-dark (remembered a.jpg).
    key("press", "up"); key("release", "up")
    advance(250)
    assert(selected() == "catppuccin/b.jpg", selected())
    key("press", "up"); advance(250)
    assert(selected() == "ultra-dark/a.jpg", "Up wraps to the last theme: " .. selected())
    key("press", "down"); advance(250)
    assert(selected() == "catppuccin/b.jpg", selected())
    key("press", "tab"); advance(250)
    assert(selected() == "tokyo-night/b.jpg", selected())
    key("press", "backtab"); advance(250)
    assert(selected() == "catppuccin/b.jpg", selected())
    -- Left from the first card wraps to the last.
    key("press", "left"); key("release", "left"); advance(200)
    assert(selected() == "catppuccin/a.jpg", selected())
    key("press", "left"); key("release", "left"); advance(200)
    assert(selected() == "ultra-dark/b.jpg", "Left wraps: " .. selected())
    key("press", "right"); key("release", "right"); advance(200)
    assert(selected() == "catppuccin/a.jpg", "Right wraps back: " .. selected())
end)

check("holding an arrow repeats smoothly and the motion never trails by more than two cards", function()
    startHost()
    open()
    local home = motion().target
    key("press", "right")
    local worst = 0
    for _ = 1, 120 do -- 1.9 s held
        advance(16)
        local m = motion()
        local lag = math.abs(m.target - m.pos)
        if lag > worst then worst = lag end
    end
    key("release", "right")
    local steps = motion().target - home
    -- one step, then 320 ms later one every 110 ms: 1 + floor((1920 - 320) / 110) + 1
    assert(steps >= 14 and steps <= 17, "steps while held: " .. steps)
    assert(worst <= 2.0001, "lag " .. worst)
    advance(150)
    local stopped = motion().target
    advance(500)
    assert(motion().target == stopped, "repeat continued after release")
    -- Clicking a side card glides to it; clicking the centre card applies and closes.
    local band = keyed("band")
    local side
    for _, n in ipairs(band.children) do
        if n.props.key == "s" .. (stopped + 2) then side = n end
    end
    assert(side, "side card two to the right is drawn")
    side.props.onClick()
    pump()
    advance(300)
    assert(motion().target == stopped + 2 and math.abs(motion().pos - (stopped + 2)) < 0.01)
    local landed = selected()
    centreSlot().props.onClick()
    pump()
    advance(400)
    assert(not H.shown, "a centre click closes")
    local r = requests()
    if landed ~= "tokyo-night/b.jpg" then -- the live card needs no switch
        assert(r and r.theme .. "/" .. string.match(r.wallpaper, "[^/]+$") == landed,
            "a centre click applies the card: " .. landed)
    end
end)

check("after the last switch the overlay closes when idle for 2.5 s", function()
    startHost()
    open()
    key("press", "right"); key("release", "right")
    advance(900)
    finish(takeSwitch())
    advance(2000)
    assert(H.shown, "closed before 2.5 s of idle")
    key("press", "left"); key("release", "left") -- input restarts the wait; lands on the old card
    advance(900)
    finish(takeSwitch())
    advance(2300)
    assert(H.shown, "input did not restart the idle wait")
    advance(600)
    assert(not H.shown, "never auto-closed")
end)

check("a failed switch shows an error, keeps it while browsing and Enter retries the same target", function()
    startHost()
    open()
    key("press", "right"); key("release", "right")
    advance(900)
    finish(takeSwitch(), "", 1)
    local message = keyed("message")
    assert(message.props.opacity == 1 and string.find(message.props.text, "Enter to retry", 1, true),
        "error line: " .. tostring(message.props.text))
    assert(H.shown, "a failure must not close the overlay")
    advance(4000)
    assert(H.shown and #switchProcs() == 0, "no auto-retry and no auto-close on failure")
    key("press", "left"); key("release", "left"); advance(200)
    key("press", "right"); key("release", "right"); advance(1000)
    assert(keyed("message").props.opacity == 1, "the error survives browsing away and back")
    key("press", "return")
    local procs = switchProcs()
    assert(#procs == 1 and procs[1].argv[2] == "set" and procs[1].argv[3] == "tokyo-night",
        "retry runs the whole switch")
    assert(H.shown, "a retry stays open until it lands")
    finish(takeSwitch())
    advance(400)
    assert(not H.shown, "a successful retry closes")
end)

check("toggle closes; reduced motion snaps; a previous opening's result changes nothing", function()
    startHost({ settings = { ["shell.animation.enabled"] = false } })
    open()
    key("press", "right"); key("release", "right")
    assert(motion().pos == motion().target, "reduced motion snaps")
    key("press", "return") -- applies tokyo-night/c and closes; the switch is still running
    advance(50)
    assert(not H.shown)
    ipcService("toggle")
    serveCatalog()
    assert(H.shown and H.shows == 2)
    finish(takeSwitch()) -- the earlier opening's switch lands now
    advance(3000)
    assert(H.shown, "another opening's result started this one's auto-close")
    ipcService("toggle")
    advance(100)
    assert(not H.shown, "toggle closed the overlay")
end)

check("rejected switches fail visibly; a reloaded service replays nothing", function()
    startHost()
    open()
    H.reject = true
    key("press", "right"); key("release", "right")
    advance(900)
    assert(keyed("message").props.opacity == 1, "a switch that could not start shows the error")
    H.reject = false
    local before = H.store.request
    startService() -- a hot reload sees the last request as history
    serveCatalog()
    assert(H.store.request == before and #switchProcs() == 0, "a reload replayed an old request")
end)

check("a refreshed catalog keeps the selection, and a vanished card is never applied by itself", function()
    startHost()
    open()
    key("press", "right"); key("release", "right")
    advance(200)
    assert(selected() == "tokyo-night/c.jpg")
    -- Same pictures, new order around it: the selection stays on its card.
    local more = sample({
        { "catppuccin", { "a.jpg", "b.jpg", "new.jpg" }, "b.jpg" },
        { "tokyo-night", { "a.jpg", "b.jpg", "c.jpg" }, "b.jpg" },
        { "ultra-dark", { "a.jpg", "b.jpg" }, "a.jpg" },
    })
    S.onIpc("refresh", "")
    serveCatalog(more)
    assert(selected() == "tokyo-night/c.jpg", "selection moved: " .. selected())
    advance(1000)
    local r = requests()
    assert(r and r.wallpaper == "/w/tokyo-night/c.jpg", "the dwell still applies the selected card")
    finish(takeSwitch())
    -- The selected picture disappears: the card that slides in is not applied.
    key("press", "right"); key("release", "right")
    advance(200)
    local gone = sample({
        { "catppuccin", { "a.jpg", "b.jpg" }, "b.jpg" },
        { "tokyo-night", { "a.jpg", "b.jpg", "c.jpg" }, "b.jpg" },
        { "ultra-dark", { "b.jpg" }, "b.jpg" },
    })
    local before = requests()
    S.onIpc("refresh", "")
    serveCatalog(gone)
    advance(2000)
    assert(requests() == before and #switchProcs() == 0, "a card nobody chose was applied")
end)

print(string.format("Theme carousel checks passed (%d scenarios)", passed))
