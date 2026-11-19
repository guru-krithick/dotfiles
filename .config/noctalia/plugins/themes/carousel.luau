--!nonstrict
-- The theme carousel: every wallpaper of every theme as one ring of slanted
-- cards floating across the focused screen over a dimmed desktop. Landing on
-- a card and staying DWELL_MS applies it (that theme with that picture)
-- through the switcher service; Enter applies at once and closes; Escape
-- closes and keeps whatever was applied. Keys arrive as IPC events from
-- Mango's `themes` key mode (see mango/config.conf); clicks work directly.
-- A new runtime starts for every opening, so all state here is per opening.

local DWELL_MS = 600 -- settled on a card this long without input: apply it
local AUTO_CLOSE_MS = 2500 -- after the last apply, close when idle this long
local OPEN_MS, CLOSE_MS = 220, 160
local REPEAT_DELAY_MS, REPEAT_MS = 320, 110 -- holding an arrow
local HOLD_LIMIT_MS = 6000 -- stop a hold whose release never arrived
local SPRING = 40 -- critically damped, 1/s: one step settles in ~140 ms
local MAX_LAG = 2 -- cards the painted position may trail the selection
local SCRIM = 0.45 -- the desktop dims to the theme's surface colour

-- Card geometry in screen pixels for a 1920 px wide output. `theme catalog`
-- reports the size of its cards (a 560x315 picture, the slant of its top
-- edge, a shadow margin); by distance from the centre each card has a scale
-- and an opacity, and neighbours meet along the slant.
local CARD_W, CARD_H, SLANT, PAD = 560, 315, 63, 28
local SCALES = { 1.0, 0.62, 0.5, 0.42, 0.36 }
local ALPHAS = { 1.0, 0.8, 0.5, 0.25, 0.0 }
local OVERLAP = 12
local REACH = 4 -- cards drawn on each side of the centre
local FIRST_FRAMES_MS = 50 -- after opening, draw only the nearest cards this long
local DOT_ROLES = { "primary", "secondary", "tertiary", "surface_container", "on_surface" }

-- Centre offsets of the cards at whole distances: each meets its neighbour
-- along the slant, with a small overlap.
local OFFSETS = {}
local function layoutOffsets()
    OFFSETS = { 0 }
    for k = 1, #SCALES - 1 do
        OFFSETS[k + 1] = OFFSETS[k] + CARD_W * (SCALES[k] + SCALES[k + 1]) / 2 - OVERLAP
    end
end
layoutOffsets()

local function now()
    return noctalia.nowMs()
end

local session = string.format("%.0f", now())
local output = layer.outputName()
local ring, groups = {}, {}
local target, pos, vel = 1, 1, 0 -- selected slot (unwrapped) and painted position
local lagLimit = MAX_LAG
local phase, phaseStart = "opening", now()
local closeFrom = 1 -- open progress the closing animation starts from
local moved = false -- dwell applies only after the user has browsed
local settledAt = nil
local held = nil
local lastInput = now()
local lastTick = now()
local requests, seq = {}, 0 -- request id -> card key
local committed = nil -- key of the latest card asked for
local applying = nil -- key whose switch is running
local failure = nil -- { key, message }
local appliedAt = nil -- last successful switch in this opening
local closeOnDone = nil
local liveKey = nil
local loaded = false
local ticking = false
local render

-- Shell settings -------------------------------------------------------------

local uiScale, animate, speed = 1, true, 1
local function readSettings()
    uiScale = math.max(0.5, tonumber(noctalia.getSetting("accessibility.ui_scale")) or 1)
    animate = noctalia.getSetting("shell.animation.enabled") ~= false
    speed = math.max(0.1, tonumber(noctalia.getSetting("shell.animation.speed")) or 1)
end

local function currentKey()
    local source = noctalia.getSetting("theme.source")
    local theme = nil
    if source == "custom" then
        theme = noctalia.getSetting("theme.custom_palette")
    end
    if not theme then
        return nil, nil
    end
    local wallpaper = output and noctalia.wallpaperPath(output) or nil
    return theme .. "|" .. tostring(wallpaper or ""), theme
end

local function outputWidth()
    for _, o in ipairs(noctalia.outputs() or {}) do
        if o.name == output then
            return tonumber(o.width) or 1920
        end
    end
    return 1920
end

-- Ring -------------------------------------------------------------------------

local function wrap(slot)
    local n = #ring
    return ((slot - 1) % n) + 1
end

local function cardAt(slot)
    return ring[wrap(slot)]
end

local function indexOf(key)
    for i, card in ipairs(ring) do
        if card.key == key then
            return i
        end
    end
    return nil
end

local function build(catalog)
    local list, themes = {}, {}
    for gi, theme in ipairs(catalog.themes or {}) do
        local group = { id = theme.id, first = #list + 1, remembered = theme.remembered }
        local walls = theme.wallpapers or {}
        if #walls == 0 then
            walls = { { name = "no wallpaper" } }
        end
        for _, wall in ipairs(walls) do
            local colors = theme.colors or {}
            table.insert(list, {
                key = tostring(theme.id) .. "|" .. tostring(wall.path or ""),
                group = gi,
                theme = theme.id,
                themeName = theme.name or theme.id,
                path = wall.path,
                name = wall.name or "",
                image = (wall.ready and wall.card) or theme.placeholder,
                surface = colors.surface or "#232327",
                colors = colors,
            })
        end
        group.last = #list
        table.insert(themes, group)
    end
    return list, themes
end

-- The live card, else that theme's remembered card, else its first card.
local function homeIndex()
    local key, theme = currentKey()
    local index = key and indexOf(key)
    if index then
        return index
    end
    for _, group in ipairs(groups) do
        if group.id == theme then
            return (group.remembered and indexOf(theme .. "|" .. group.remembered)) or group.first
        end
    end
    return 1
end

local function adopt(catalog)
    if type(catalog) ~= "table" or type(catalog.themes) ~= "table" then
        return
    end
    local card = catalog.card
    if type(card) == "table" and tonumber(card.width) and tonumber(card.height) then
        CARD_W, CARD_H = tonumber(card.width), tonumber(card.height)
        SLANT, PAD = tonumber(card.slant) or SLANT, tonumber(card.pad) or 0
        layoutOffsets()
    end
    local selectedKey = (#ring > 0) and cardAt(target).key or nil
    local oldIndex = (#ring > 0) and wrap(target) or nil
    ring, groups = build(catalog)
    loaded = true
    if #ring == 0 then
        return
    end
    if not selectedKey or not moved then
        -- Until the user browses, the overlay stays on what the desktop shows.
        target = homeIndex()
        pos, vel = target, 0
    else
        local index = indexOf(selectedKey)
        if index then
            target = target + (index - oldIndex)
            pos = pos + (index - oldIndex)
        else
            -- The selected picture or theme is gone: whatever card now sits in
            -- the middle was not chosen, so nothing applies before new input.
            moved, settledAt = false, nil
        end
    end
end

-- Motion -----------------------------------------------------------------------

local function openProgress()
    local t = now() - phaseStart
    if phase == "opening" then
        local x = animate and math.min(1, t / (OPEN_MS / speed)) or 1
        return 1 - (1 - x) ^ 3
    elseif phase == "closing" then
        local x = animate and math.min(1, t / (CLOSE_MS / speed)) or 1
        return closeFrom * (1 - x * x * x)
    end
    return 1
end

local function settled()
    return pos == target and vel == 0
end

-- Exact step of a critically damped spring toward the selection: stable for
-- any frame time, and the lag stays bounded however fast keys arrive.
local function advance(dt)
    if not animate then
        pos, vel = target, 0
        return
    end
    local w = SPRING * speed
    local e = pos - target
    local c = vel + w * e
    local decay = math.exp(-w * dt)
    pos = target + (e + c * dt) * decay
    vel = (vel - w * c * dt) * decay
    if pos < target - lagLimit then
        pos = target - lagLimit
    elseif pos > target + lagLimit then
        pos = target + lagLimit
    end
    if math.abs(pos - target) < 0.002 and math.abs(vel) < 0.02 then
        pos, vel = target, 0
        lagLimit = MAX_LAG
    end
end

local function needsApply(card)
    return moved and card.key ~= (committed or liveKey) and not (failure and failure.key == card.key)
end

local function busy()
    if phase ~= "open" or not settled() or held then
        return true
    end
    local card = #ring > 0 and cardAt(target)
    return card and (needsApply(card) or applying == card.key) or false
end

local function wake()
    if not animate then
        pos, vel = target, 0 -- reduced motion: no glide
    end
    if not ticking then
        ticking = true
        lastTick = now()
        layer.setNeedsFrameTick(true)
    end
    render()
end

-- Applying ---------------------------------------------------------------------

local function request(card, force)
    seq = seq + 1
    local id = session .. ":" .. seq
    requests[id] = card.key
    committed = card.key
    if failure and failure.key == card.key then
        failure = nil
    end
    noctalia.state.set("request", { id = id, theme = card.theme, wallpaper = card.path,
        name = card.themeName, force = force or false })
end

local function close()
    if phase == "closing" then
        return
    end
    closeFrom = openProgress()
    phase, phaseStart = "closing", now()
    held, settledAt = nil, nil
    wake()
end

local function input()
    lastInput = now()
    settledAt = nil
end

local function step(delta)
    if #ring == 0 or phase == "closing" then
        return
    end
    input()
    moved = true
    target = target + delta
    lagLimit = MAX_LAG
    wake()
end

-- Glide to another slot without the lag limit (clicks and theme jumps).
local function glide(delta)
    if #ring == 0 or phase == "closing" or delta == 0 then
        return
    end
    input()
    moved = true
    target = target + delta
    lagLimit = math.abs(target - pos) + 1
    wake()
end

-- Up/Down, Tab: the previous/next theme, at its remembered wallpaper.
local function jumpTheme(direction)
    if #ring == 0 or #groups < 2 or phase == "closing" then
        return
    end
    local gi = cardAt(target).group
    local group = groups[((gi - 1 + direction) % #groups) + 1]
    local index = (group.remembered and indexOf(group.id .. "|" .. group.remembered)) or group.first
    local n = #ring
    local delta
    if direction > 0 then
        delta = (index - wrap(target)) % n
    else
        delta = -((wrap(target) - index) % n)
    end
    glide(delta)
end

local function choose()
    if phase == "closing" then
        return
    elseif #ring == 0 then
        close()
        return
    end
    input()
    local card = cardAt(target)
    if failure and failure.key == card.key then
        closeOnDone = card.key -- retry; close once it lands
        request(card, true)
        wake()
        return
    end
    if card.key ~= (committed or liveKey) then
        request(card, false)
    end
    close()
end

local function press(key)
    held = nil -- Mango reports a release only for the last key pressed
    if key == "left" or key == "right" then
        local direction = key == "left" and -1 or 1
        step(direction)
        held = { direction = direction, since = now(), nextAt = now() + REPEAT_DELAY_MS }
    elseif key == "up" or key == "backtab" then
        jumpTheme(-1)
    elseif key == "down" or key == "tab" then
        jumpTheme(1)
    elseif key == "return" then
        choose()
    end
end

-- Painting -----------------------------------------------------------------------

local function curve(values, d)
    d = math.abs(d)
    local i = math.floor(d)
    if i >= #values - 1 then
        return values[#values]
    end
    local f = d - i
    if i == 0 then
        f = f * f * (3 - 2 * f) -- the centre card eases in and out of its size
    end
    return values[i + 1] + (values[i + 2] - values[i + 1]) * f
end

local function offset(d)
    local a = math.abs(d)
    local i = math.floor(a)
    local x
    if i >= #OFFSETS - 1 then
        x = OFFSETS[#OFFSETS] + (a - (#OFFSETS - 1)) * CARD_W * SCALES[#SCALES]
    else
        x = OFFSETS[i + 1] + (OFFSETS[i + 2] - OFFSETS[i + 1]) * (a - i)
    end
    return d < 0 and -x or x
end

local function withAlpha(hex, alpha)
    if type(hex) == "string" and string.match(hex, "^#%x%x%x%x%x%x$") then
        return hex .. string.format("%02x", math.floor(alpha * 255 + 0.5))
    end
    return nil
end

local function caption(card, unit)
    local accent = card.colors.primary or "on_surface_variant"
    local track = withAlpha(card.colors.primary, 0.25) or "on_surface_variant/0.25"
    local progress, pulse = 0, 1
    local t = now()
    if failure and failure.key == card.key then
        accent, track, progress = "error", "error/0.25", 1
    elseif applying == card.key then
        progress = 1
        pulse = 0.6 + 0.4 * (0.5 + 0.5 * math.cos(t / 1100 * 2 * math.pi))
    elseif needsApply(card) then
        progress = settledAt and math.min(1, (t - settledAt) / DWELL_MS) or 0
    else
        progress = 1
    end
    local tabW, tabH = 64, 5
    local dots = {}
    for _, role in ipairs(DOT_ROLES) do
        local color = card.colors[role]
        if color then
            table.insert(dots, ui.box({ key = role, width = 9, height = 9, radius = 4.5, fill = color,
                border = "on_surface/0.3", borderWidth = 1 }))
        end
    end
    local message = failure and failure.key == card.key and (failure.message .. " · Enter to retry") or ""
    return ui.column({ key = "caption", align = "center", translateX = -SLANT / 2 * unit }, {
        ui.row({ key = "tab", width = tabW, height = tabH, radius = tabH / 2, fill = track }, {
            ui.box({ key = "fill", width = tabW, height = tabH, radius = tabH / 2, fill = accent,
                opacity = pulse, scaleX = math.max(0.001, progress),
                translateX = -(1 - progress) * tabW / 2, visible = progress > 0.01 }),
        }),
        ui.row({ key = "gap1", height = 14 }, {}),
        ui.label({ key = "theme", text = card.themeName, fontSize = 17, fontWeight = "semibold",
            color = "on_surface", maxLines = 1, shadow = true }),
        ui.row({ key = "gap2", height = 3 }, {}),
        ui.label({ key = "wallpaper", text = card.name, fontSize = 14, color = "on_surface",
            opacity = 0.78, maxLines = 1, shadow = true }),
        ui.row({ key = "gap3", height = 12 }, {}),
        ui.row({ key = "dots", gap = 7, align = "center", height = 9 }, dots),
        ui.row({ key = "status", height = 26, align = "end" }, {
            ui.label({ key = "message", text = message ~= "" and message or " ", fontSize = 12,
                color = "error", opacity = message ~= "" and 1 or 0, maxLines = 1, shadow = true }),
        }),
    })
end

render = function()
    local open = openProgress()
    local scrim = string.format("surface/%.3f", SCRIM * open)
    local onScrim = function()
        close()
    end
    if #ring == 0 then
        local text = loaded and "No themes found" or ""
        layer.render(ui.column({ key = "root", flexGrow = 1, fill = scrim, justify = "center",
            align = "center", onClick = onScrim }, {
            ui.label({ key = "empty", text = text, fontSize = 14, color = "on_surface_variant",
                opacity = open }),
        }))
        return
    end
    local f = math.max(0.75, math.min(1.5, outputWidth() / 1920))
    local unit = f / uiScale -- screen pixels at 1920 -> layer units
    local cardW, cardH = (CARD_W + SLANT + 2 * PAD) * unit, (CARD_H + 2 * PAD) * unit
    local rectH = CARD_H * unit
    -- The first frames hold only the centre card and its neighbours, so the
    -- overlay appears before the farther pictures have been decoded.
    local reach = (phase == "opening" and now() - phaseStart < FIRST_FRAMES_MS) and 1.5 or REACH
    local slots = {}
    for slot = math.floor(pos) - REACH, math.ceil(pos) + REACH do
        if math.abs(slot - pos) < reach then
            table.insert(slots, slot)
        end
    end
    table.sort(slots, function(a, b)
        return math.abs(a - pos) > math.abs(b - pos)
    end)
    local children = {}
    for _, slot in ipairs(slots) do
        local card = cardAt(slot)
        local d = slot - pos
        local scale, alpha, x = curve(SCALES, d), curve(ALPHAS, d), offset(d) * unit
        local onClick = function()
            if slot == target then
                choose()
            else
                glide(slot - target)
            end
        end
        if card.image then
            table.insert(children, { kind = "image", x = x, w = cardW, props = { key = "s" .. slot,
                path = card.image, width = cardW, height = cardH, fit = "stretch", scale = scale,
                opacity = alpha, onClick = onClick } })
        else
            table.insert(children, { kind = "box", x = x, w = CARD_W * unit, props = { key = "s" .. slot,
                width = CARD_W * unit, height = rectH, radius = 12 * unit, fill = card.surface,
                scale = scale, opacity = alpha, onClick = onClick } })
        end
        if card.key == liveKey then
            local size = 6
            table.insert(children, { kind = "box", x = x + SLANT / 2 * unit * scale, w = size, props = {
                key = "live" .. slot, width = size, height = size, radius = size / 2, fill = "on_surface",
                opacity = alpha * 0.85, scale = scale, translateY = -(rectH / 2 + 12 * unit) * scale } })
        end
    end
    -- Children sit side by side in a row exactly as wide as all of them; each
    -- is moved from its place in that row to its place on the curve.
    local total = 0
    for _, child in ipairs(children) do
        total = total + child.w
    end
    local left, nodes = -total / 2, {}
    for _, child in ipairs(children) do
        child.props.translateX = child.x - (left + child.w / 2)
        left = left + child.w
        table.insert(nodes, ui[child.kind](child.props))
    end
    local band = ui.row({ key = "band", width = total, minWidth = total, height = cardH, align = "center",
        opacity = open, scale = 0.85 + 0.15 * open }, nodes)
    layer.render(ui.column({ key = "root", flexGrow = 1, fill = scrim, justify = "center", align = "center",
        onClick = onScrim }, {
        band, -- its shadow margin is the gap between the card and the caption
        ui.column({ key = "under", align = "center", opacity = open }, { caption(cardAt(target), unit) }),
    }))
end

-- Frames and timers ----------------------------------------------------------------

local function tick()
    local t = now()
    local dt = math.min(0.064, math.max(0, (t - lastTick) / 1000))
    lastTick = t
    if held then
        if t - held.since > HOLD_LIMIT_MS then
            held = nil
        elseif t >= held.nextAt then
            target = target + held.direction
            lastInput = t
            settledAt = nil
            held.nextAt = math.max(held.nextAt + REPEAT_MS, t + REPEAT_MS / 2)
        end
    end
    if #ring > 0 then
        advance(dt)
    end
    if phase == "opening" and openProgress() >= 1 then
        phase = "open"
    elseif phase == "closing" and openProgress() <= 0 then
        layer.setNeedsFrameTick(false)
        ticking = false
        render()
        -- The service hides the layer and restores Mango's key mode; hiding
        -- here too means a closed overlay never lingers holding the keyboard.
        noctalia.state.set("layer", { closed = true, at = t })
        noctalia.layer.hide("carousel")
        return
    end
    if phase == "open" and #ring > 0 and not held then
        local card = cardAt(target)
        if math.abs(pos - target) < 0.03 and needsApply(card) then
            settledAt = settledAt or t
            if t - settledAt >= DWELL_MS then
                request(card, false)
            end
        else
            settledAt = nil
        end
    end
    render()
    if not busy() then
        layer.setNeedsFrameTick(false)
        ticking = false
    end
end

function onFrameTick(_deltaMs)
    if ticking then
        tick()
    end
end

-- Idle check for the auto-close (no frames needed while nothing moves).
function update()
    if phase ~= "open" or not appliedAt or held or ticking then
        return
    end
    local card = #ring > 0 and cardAt(target)
    if next(requests) ~= nil or (card and (needsApply(card) or (failure and failure.key == card.key))) then
        return
    end
    if now() - math.max(appliedAt, lastInput) >= AUTO_CLOSE_MS then
        close()
    end
end

-- Inputs -----------------------------------------------------------------------------

function onIpc(event, payload)
    local key = string.lower(string.match(tostring(payload or ""), "^%s*(.-)%s*$"))
    if event == "press" then
        press(key)
    elseif event == "release" then
        held = nil -- Mango reports the release of the last key pressed
    elseif event == "close" then
        close()
    elseif event == "next" then
        step(1)
    elseif event == "prev" then
        step(-1)
    elseif event == "next-theme" then
        jumpTheme(1)
    elseif event == "prev-theme" then
        jumpTheme(-1)
    elseif event == "apply" then
        choose()
    end
end

local function onStatus(status)
    if type(status) ~= "table" or not requests[status.id] then
        return
    end
    local key = requests[status.id]
    if status.state == "applying" then
        applying = key
    elseif status.state == "done" or status.state == "failed" or status.state == "replaced" then
        requests[status.id] = nil
        if applying == key then
            applying = nil
        end
        if status.state == "done" then
            liveKey = key
            appliedAt = now()
            if closeOnDone == key then
                closeOnDone = nil
                close()
            end
        elseif status.state == "failed" then
            failure = { key = key, message = status.message or "Could not apply" }
            closeOnDone = nil
        end
    end
    wake()
end

function onConfigChanged()
    readSettings()
    local key = currentKey()
    if key and not applying then
        liveKey = key
    end
    render()
end

-- Start ---------------------------------------------------------------------------------

readSettings()
liveKey = currentKey()
local initialCommand = noctalia.state.get("command")
local initialSeq = type(initialCommand) == "table" and initialCommand.seq or nil
noctalia.state.watch("catalog", function(catalog)
    adopt(catalog)
    render()
end)
noctalia.state.watch("status", onStatus)
noctalia.state.watch("command", function(command)
    if type(command) == "table" and command.kind == "close" and command.seq ~= initialSeq then
        close()
    end
end)
noctalia.setUpdateInterval(100)
adopt(noctalia.state.get("catalog"))
wake()
