-- ============================================================
--  MECHANIC PANEL — Modern UI  |  v20.0
--  Complete rewrite with modern glassmorphism design
-- ============================================================

local PANEL_W, PANEL_H = 680, 500
local INTERACT_DIST = 3.5

-- ── Color Palette ──────────────────────────────────────────
local C = {
    -- Backgrounds
    bg          = {14, 16, 22, 248},
    bgCard      = {20, 23, 32, 255},
    bgCardHov   = {28, 32, 44, 255},
    bgHeader    = {18, 20, 28, 255},
    bgOverlay   = {10, 12, 18, 200},

    -- Borders
    border      = {40, 45, 60, 255},
    borderLight = {55, 62, 80, 180},

    -- Accents
    accent      = {255, 165, 0, 255},      -- Orange primary
    accentDim   = {255, 165, 0, 100},
    accentSoft  = {255, 165, 0, 50},

    -- Status
    success     = {80, 220, 130, 255},
    successDim  = {80, 220, 130, 120},
    successSoft = {80, 220, 130, 40},
    danger      = {255, 80, 80, 255},
    dangerDim   = {255, 80, 80, 120},
    dangerSoft  = {255, 80, 80, 40},

    -- Category colors
    catBody     = {255, 165, 0, 255},
    catTire     = {100, 190, 255, 255},
    catEngine   = {255, 110, 60, 255},
    catGlass    = {150, 215, 255, 255},

    -- Text
    textPrimary   = {240, 244, 252, 255},
    textSecondary = {160, 170, 190, 255},
    textMuted     = {90, 100, 120, 255},
    textWhite     = {255, 255, 255, 255},

    -- Track / Bars
    track       = {28, 32, 42, 255},
    trackFill   = {38, 42, 55, 255},

    -- Misc
    shadow      = {0, 0, 0, 160},
    white       = {255, 255, 255, 255},
    black       = {0, 0, 0, 255},
    transparent = {0, 0, 0, 0},
    air         = {100, 190, 255, 255},
}

-- ── Helpers ────────────────────────────────────────────────
local floor, abs, cos, sin, rad, max, min = math.floor, math.abs, math.cos, math.sin, math.rad, math.max, math.min
local function I(v) return floor(v + 0.5) end
local function lerp(a, b, t) return a + (b - a) * t end
local function clamp(v, lo, hi) return v < lo and lo or (v > hi and hi or v) end
local function tc(r, g, b, a) return tocolor(r, g, b, a or 255) end
local function tcC(c, a) return tocolor(c[1], c[2], c[3], a or c[4] or 255) end

local function easeOutBack(t)
    local c1, c3 = 1.70158, 2.70158
    return 1 + c3 * (t - 1)^3 + c1 * (t - 1)^2
end
local function easeOutCubic(t) return 1 - (1 - t)^3 end
local function easeOutQuint(t) return 1 - (1 - t)^5 end

local function smoothstep(edge0, edge1, x)
    local t = clamp((x - edge0) / (edge1 - edge0), 0, 1)
    return t * t * (3 - 2 * t)
end

-- ── Drawing Primitives ─────────────────────────────────────
local function rr(x, y, w, h, r, color)
    x, y, w, h, r = I(x), I(y), I(w), I(h), I(r)
    if w <= 0 or h <= 0 then return end
    if r * 2 > w then r = floor(w / 2) end
    if r * 2 > h then r = floor(h / 2) end
    if r < 1 then dxDrawRectangle(x, y, w, h, color) return end
    -- Center + sides
    dxDrawRectangle(x + r, y, w - r * 2, h, color)
    dxDrawRectangle(x, y + r, r, h - r * 2, color)
    dxDrawRectangle(x + w - r, y + r, r, h - r * 2, color)
    -- Corners
    local seg = 24
    dxDrawCircle(x + r, y + r, r, 0, 360, color, color, seg)
    dxDrawCircle(x + w - r, y + r, r, 0, 360, color, color, seg)
    dxDrawCircle(x + r, y + h - r, r, 0, 360, color, color, seg)
    dxDrawCircle(x + w - r, y + h - r, r, 0, 360, color, color, seg)
end

local function rrOutline(x, y, w, h, r, color, thickness)
    thickness = thickness or 1
    for i = 0, thickness - 1 do
        local xi, yi, wi, hi = x - i, y - i, w + i * 2, h + i * 2
        dxDrawLine(xi + r, yi, xi + wi - r, yi, color)
        dxDrawLine(xi + r, yi + hi, xi + wi - r, yi + hi, color)
        dxDrawLine(xi, yi + r, xi, yi + hi - r, color)
        dxDrawLine(xi + wi, yi + r, xi + wi, yi + hi - r, color)
    end
end

local function shadow(x, y, w, h, r, spread, alpha)
    alpha = alpha or 60
    for i = 1, spread do
        local a = I(alpha * (1 - i / spread) * 0.5)
        if a > 0 then
            rr(x - i, y - i + 2, w + i * 2, h + i * 2, r + i, tc(0, 0, 0, a))
        end
    end
end

local function gradient(x, y, w, h, topColor, bottomColor, steps)
    steps = steps or 20
    local sh = h / steps
    for i = 0, steps - 1 do
        local t = i / (steps - 1)
        local r = I(lerp(topColor[1], bottomColor[1], t))
        local g = I(lerp(topColor[2], bottomColor[2], t))
        local b = I(lerp(topColor[3], bottomColor[3], t))
        local a = I(lerp(topColor[4] or 255, bottomColor[4] or 255, t))
        dxDrawRectangle(I(x), I(y + i * sh), I(w), I(sh + 1), tc(r, g, b, a))
    end
end

local function txt(str, x, y, w, h, color, scale, font, ax, ay)
    x, y, w, h = I(x), I(y), I(w), I(h)
    -- Shadow
    dxDrawText(str, x + 1, y + 1, w + 1, h + 1, tc(0, 0, 0, 120), scale, font or "default-bold", ax or "center", ay or "center")
    -- Main
    dxDrawText(str, x, y, w, h, color, scale, font or "default-bold", ax or "center", ay or "center")
end

local function txtNoShadow(str, x, y, w, h, color, scale, font, ax, ay)
    dxDrawText(str, I(x), I(y), I(w), I(h), color, scale, font or "default-bold", ax or "center", ay or "center")
end

-- ── Modern Icon: Gear ──────────────────────────────────────
local function iconGear(cx, cy, r, rot, color)
    cx, cy, r = I(cx), I(cy), I(r)
    -- Outer teeth
    for i = 0, 7 do
        local ang = rad(rot + i * 45)
        local tx = cx + cos(ang) * r * 0.85
        local ty = cy + sin(ang) * r * 0.85
        dxDrawCircle(I(tx), I(ty), I(r * 0.2), 0, 360, color, color, 12)
    end
    -- Main body
    dxDrawCircle(cx, cy, I(r * 0.65), 0, 360, color, color, 32)
    -- Hole
    dxDrawCircle(cx, cy, I(r * 0.25), 0, 360, tcC(C.bgHeader), tcC(C.bgHeader), 20)
end

-- ── Modern Icon: Checkmark ─────────────────────────────────
local function iconCheck(cx, cy, size, color, bg)
    cx, cy, size = I(cx), I(cy), I(size)
    if bg then
        dxDrawCircle(cx, cy, size, 0, 360, bg, bg, 32)
    end
    local s = size * 0.45
    -- Draw checkmark as small circles along the path
    local points = {
        {cx - s * 0.6, cy},
        {cx - s * 0.2, cy + s * 0.5},
        {cx + s * 0.7, cy - s * 0.5},
    }
    for i = 1, #points - 1 do
        dxDrawLine(I(points[i][1]), I(points[i][2]), I(points[i+1][1]), I(points[i+1][2]), color, 3)
    end
end

-- ── Modern Bolt Drawing ────────────────────────────────────
local function drawBolt(cx, cy, r, state, hover, number, alphaMul)
    alphaMul = alphaMul or 1
    local A = function(v) return I(clamp(v * alphaMul, 0, 255)) end
    cx, cy, r = I(cx), I(cy), I(r)

    -- Color schemes
    local schemes = {
        intact = {
            ring    = tc(50, 56, 70, A(200)),
            top     = tc(100, 108, 125, A(255)),
            mid     = tc(75, 82, 98, A(255)),
            bottom  = tc(55, 60, 75, A(255)),
            shine   = tc(180, 185, 200, A(160)),
            line    = tc(40, 44, 55, A(220)),
        },
        done = {
            ring    = tc(40, 100, 60, A(200)),
            top     = tc(90, 220, 140, A(255)),
            mid     = tc(60, 180, 110, A(255)),
            bottom  = tc(35, 120, 70, A(255)),
            shine   = tc(160, 255, 200, A(140)),
            line    = tc(25, 80, 45, A(220)),
        },
        next = {
            ring    = tc(180, 130, 20, A(200)),
            top     = tc(255, 210, 90, A(255)),
            mid     = tc(220, 170, 40, A(255)),
            bottom  = tc(180, 120, 20, A(255)),
            shine   = tc(255, 240, 160, A(140)),
            line    = tc(140, 90, 10, A(220)),
        },
        disabled = {
            ring    = tc(35, 38, 48, A(150)),
            top     = tc(65, 70, 85, A(200)),
            mid     = tc(50, 55, 68, A(200)),
            bottom  = tc(38, 42, 52, A(200)),
            shine   = tc(90, 95, 110, A(100)),
            line    = tc(30, 33, 42, A(180)),
        },
    }
    local s = schemes[state] or schemes.intact

    -- Outer shadow
    for i = 3, 1, -1 do
        dxDrawCircle(cx + 1, cy + 2, r + i + 2, 0, 360, tc(0, 0, 0, A(30 - i * 8)), tc(0, 0, 0, 0), 32)
    end

    -- Hover glow
    if hover then
        dxDrawCircle(cx, cy, r + 10, 0, 360, tc(255, 255, 255, A(25)), tc(255, 255, 255, 0), 36)
    end

    -- Ring
    dxDrawCircle(cx, cy, r + 3, 0, 360, s.ring, s.ring, 48)

    -- Gradient layers (top → bottom)
    local layers = {
        {1.00, s.top},
        {0.88, s.mid},
        {0.72, s.bottom},
        {0.52, s.bottom},
    }
    for _, L in ipairs(layers) do
        dxDrawCircle(cx, cy, I(r * L[1]), 0, 360, L[2], L[2], 48)
    end

    -- Shine highlight
    dxDrawCircle(cx - I(r * 0.3), cy - I(r * 0.3), I(r * 0.2), 0, 360, s.shine, tc(0, 0, 0, 0), 24)

    -- Cross groove
    local grooveLen = I(r * 0.7)
    dxDrawLine(cx - grooveLen, cy, cx + grooveLen, cy, s.line, 2)
    dxDrawLine(cx, cy - grooveLen, cx, cy + grooveLen, s.line, 2)

    -- Number
    if number then
        txt(tostring(number), cx - r, cy - r, cx + r, cy + r, tcC(C.textPrimary), 1.3)
    end
end

-- ── State ──────────────────────────────────────────────────
local isMechanicMode = false
local heldDoorObject = nil
local doorButtons = {}
local isWorking = false
local progress = 0
local actionType, actionVehicle, actionDoor = nil, nil, nil
local actionIsPanel = false
local actionWheelIndex = nil
local actionIsEngine = false
local actionIsGlass = false
local nearbyVehicle, lastVehicleCheck = nil, 0

local errorMessage = nil
local errorTick = 0
local spaceHeld = false
local airStarted = false

local P = {
    active = false, openTick = 0,
    vehicle = nil, targetIndex = nil, panelKind = "door",
    panelX = 0, panelY = 0,
    stage = 1,
    bolts = {}, unscrewed = 0,
    hammerPos = 0, hammerDir = 1, hammerSpeed = 65,
    hammerHits = 0, hammerNeeded = 3,
    zoneStart = 35, zoneEnd = 65,
    flashType = 0, flashTimer = 0,
    tightenBolts = {}, nextOrder = 1, tightenTotal = 5,
    airPressure = 0, airTarget = 80, airSpeed = 40, airOvershoot = false,
    glassCracks = {}, glassCleaned = 0,
    timingBars = {}, timingLocked = 0, timingTotal = 3,
    oilPressure = 0, oilTarget = 65,
    oilZoneStart = 55, oilZoneEnd = 75,
    oilSpeed = 28, oilHoldTime = 0, oilRequired = 800,
    cylinders = {}, firingOrder = {}, nextFire = 1,
    -- Animation state
    particles = {},
    shakeTimer = 0, shakeIntensity = 0,
}

local BOLT_R = 32
local BOLT_LAYOUT = {
    {155, 245}, {330, 245}, {505, 245},
    {242, 345}, {417, 345}
}
local ORDER_LAYOUT = { 3, 1, 4, 5, 2 }

-- ── Names ──────────────────────────────────────────────────
local PART_FA = {
    door = {
        [0] = "کاپوت", [1] = "صندوق",
        [2] = "درب جلو چپ", [3] = "درب جلو راست",
        [4] = "درب عقب چپ", [5] = "درب عقب راست",
    },
    panel = {
        [4] = "شیشه جلو",
        [5] = "سپر جلو", [6] = "سپر عقب",
    },
    wheel = {
        [0] = "تایر جلو چپ", [1] = "تایر عقب چپ",
        [2] = "تایر جلو راست", [3] = "تایر عقب راست",
    },
    engine = { [0] = "موتور" },
    glass = {
        [0] = "شیشه جلو", [1] = "شیشه کنار راننده",
        [2] = "شیشه کنار سرنشین", [3] = "شیشه عقب",
    },
}

local DOOR_NAMES = {
    [0] = "Hood", [1] = "Trunk",
    [2] = "Front Left Door", [3] = "Front Right Door",
    [4] = "Rear Left Door", [5] = "Rear Right Door",
}
local PANEL_NAMES = {
    [4] = "Windshield", [5] = "Front Bumper", [6] = "Rear Bumper",
}
local WHEEL_NAMES = {
    [0] = "Front Left Tire", [1] = "Rear Left Tire",
    [2] = "Front Right Tire", [3] = "Rear Right Tire",
}
local GLASS_NAMES = {
    [0] = "Windshield", [1] = "Left Window",
    [2] = "Right Window", [3] = "Rear Window",
}

-- ── Category Helpers ───────────────────────────────────────
local function getCatColor(kind)
    if kind == "wheel" then return C.catTire
    elseif kind == "engine" then return C.catEngine
    elseif kind == "glass" then return C.catGlass
    else return C.catBody end
end

local function getCatLabel(kind, idx)
    if kind == "wheel" then return "TIRE"
    elseif kind == "engine" then return "ENGINE"
    elseif kind == "glass" then return "GLASS"
    elseif kind == "panel" then
        if idx == 5 or idx == 6 then return "BUMP" end
        return "PANEL"
    end
    if idx == 0 then return "HOOD"
    elseif idx == 1 then return "TRUNK" end
    return "DOOR"
end

-- ── Particle System ────────────────────────────────────────
local function spawnParticles(cx, cy, count, color, speed)
    for i = 1, count do
        local angle = rad(math.random(0, 360))
        local spd = speed * (0.5 + math.random() * 0.5)
        table.insert(P.particles, {
            x = cx, y = cy,
            vx = cos(angle) * spd, vy = sin(angle) * spd,
            life = 1.0,
            decay = 1.5 + math.random() * 1.5,
            size = 2 + math.random() * 4,
            color = color,
        })
    end
end

local function updateParticles(dt)
    for i = #P.particles, 1, -1 do
        local p = P.particles[i]
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.vy = p.vy + 40 * dt -- gravity
        p.life = p.life - p.decay * dt
        if p.life <= 0 then
            table.remove(P.particles, i)
        end
    end
end

local function drawParticles()
    for _, p in ipairs(P.particles) do
        local a = I(255 * clamp(p.life, 0, 1))
        local s = I(p.size * p.life)
        if s > 0 and a > 0 then
            dxDrawCircle(I(p.x), I(p.y), s, 0, 360,
                tc(p.color[1], p.color[2], p.color[3], a),
                tc(p.color[1], p.color[2], p.color[3], a), 12)
        end
    end
end

-- ── Reset Functions ────────────────────────────────────────
local function resetStage1()
    P.stage = 1
    P.bolts, P.unscrewed = {}, 0
    for i, p in ipairs(BOLT_LAYOUT) do
        P.bolts[i] = { x = P.panelX + p[1], y = P.panelY + p[2], unscrewed = false }
    end
end

local function resetStage2()
    P.stage = 2
    P.hammerPos, P.hammerDir, P.hammerSpeed = 0, 1, 65
    P.hammerHits, P.flashType, P.flashTimer = 0, 0, 0
end

local function resetStage3()
    P.stage = 3
    P.tightenBolts, P.nextOrder = {}, 1
    for i, p in ipairs(BOLT_LAYOUT) do
        P.tightenBolts[i] = {
            x = P.panelX + p[1], y = P.panelY + p[2],
            order = ORDER_LAYOUT[i], done = false,
        }
    end
end

local function resetWheelStage1() resetStage1(); spaceHeld = false; airStarted = false end
local function resetWheelStage2() resetStage2(); spaceHeld = false; airStarted = false end
local function resetWheelStage3()
    P.stage = 3
    P.airPressure = 0; P.airTarget = 80; P.airSpeed = 35
    P.airOvershoot = false; P.flashType = 0; P.flashTimer = 0
    spaceHeld = false; airStarted = false
end

local function resetGlassStage1() resetStage1() end
local function resetGlassStage2()
    P.stage = 2; P.glassCracks = {}; P.glassCleaned = 0
    local layout = {
        {200, 220}, {320, 260}, {440, 220},
        {260, 320}, {400, 320}
    }
    for i, pos in ipairs(layout) do
        P.glassCracks[i] = { x = P.panelX + pos[1], y = P.panelY + pos[2], cleaned = false }
    end
end
local function resetGlassStage3()
    P.stage = 3; P.tightenBolts, P.nextOrder = {}, 1
    for i, p in ipairs(BOLT_LAYOUT) do
        P.tightenBolts[i] = {
            x = P.panelX + p[1], y = P.panelY + p[2],
            order = ORDER_LAYOUT[i], done = false,
        }
    end
end

local function resetEngineStage1()
    P.stage = 1; P.timingBars = {}; P.timingLocked = 0; P.timingTotal = 3
    local spacing = 150
    local startX = P.panelX + 190
    for i = 1, 3 do
        P.timingBars[i] = {
            x = startX + (i - 1) * spacing, y = P.panelY + 200,
            w = 46, h = 210,
            value = 0, dir = 1, speed = 105 + i * 20,
            locked = false,
            zoneStart = 42 + math.random(0, 10) + i * 5,
            zoneEnd = 42 + math.random(0, 10) + i * 5 + 16,
        }
    end
end

local function resetEngineStage2()
    P.stage = 2; P.oilPressure = 0; P.oilTarget = 65
    P.oilZoneStart = 55; P.oilZoneEnd = 75
    P.oilSpeed = 28; P.oilHoldTime = 0; P.oilRequired = 800
    P.flashType = 0; P.flashTimer = 0
end

local function resetEngineStage3()
    P.stage = 3; P.cylinders = {}; P.firingOrder = {1, 3, 4, 2}; P.nextFire = 1
    local positions = {{200, 230}, {460, 230}, {200, 350}, {460, 350}}
    for i = 1, 4 do
        P.cylinders[i] = {
            x = P.panelX + positions[i][1], y = P.panelY + positions[i][2],
            number = i, fired = false, flashTimer = 0,
        }
    end
end

local function failAndReset(reason)
    errorMessage = reason or "خطا! از اول شروع کن"
    errorTick = getTickCount()
    playSoundFrontEnd(4)
    P.flashType = 2; P.flashTimer = 40
    P.shakeTimer = 0.3; P.shakeIntensity = 6
    if P.panelKind == "wheel" then resetWheelStage1()
    elseif P.panelKind == "engine" then resetEngineStage1()
    elseif P.panelKind == "glass" then resetGlassStage1()
    else resetStage1() end
end

-- ── Panel Open / Close ─────────────────────────────────────
local function openPanel(vehicle, targetIndex, panelKind)
    local sw, sh = guiGetScreenSize()
    P.panelX = I((sw - PANEL_W) / 2)
    P.panelY = I((sh - PANEL_H) / 2)
    P.active = true
    P.openTick = getTickCount()
    P.vehicle = vehicle
    P.targetIndex = targetIndex
    P.panelKind = panelKind
    P.particles = {}
    errorMessage = nil; spaceHeld = false; airStarted = false

    if panelKind == "wheel" then resetWheelStage1()
    elseif panelKind == "engine" then resetEngineStage1()
    elseif panelKind == "glass" then resetGlassStage1()
    else resetStage1() end

    showCursor(true)
    setElementFrozen(localPlayer, true)
    setPedAnimation(localPlayer, "benchpress", "gym_bp_down", -1, true, false, false, false)
end

local function closePanel()
    P.active = false; P.vehicle, P.targetIndex = nil, nil
    P.particles = {}; errorMessage = nil; spaceHeld = false; airStarted = false
    showCursor(false)
    setElementFrozen(localPlayer, false)
    setPedAnimation(localPlayer)
end

-- ── Vehicle Detection ──────────────────────────────────────
local function getNearbyVehicleCached()
    local now = getTickCount()
    if now - lastVehicleCheck < 500 then return nearbyVehicle end
    lastVehicleCheck = now
    local px, py, pz = getElementPosition(localPlayer)
    local cd, cv = 4.0, nil
    for _, v in ipairs(getElementsWithinRange(px, py, pz, 5, "vehicle")) do
        if getPedOccupiedVehicle(localPlayer) ~= v then
            local vx, vy, vz = getElementPosition(v)
            local d = getDistanceBetweenPoints3D(px, py, pz, vx, vy, vz)
            if d < cd then cd, cv = d, v end
        end
    end
    nearbyVehicle = cv
    return cv
end

local function getPanelPositions(vehicle)
    local out = {}
    local vx, vy, vz = getElementPosition(vehicle)
    local _, _, rz = getElementRotation(vehicle)
    local r = rad(rz)
    local cr, sr = cos(r), sin(r)
    local function off(key, ox, oy, oz)
        out[key] = { vx + ox * cr - oy * sr, vy + ox * sr + oy * cr, vz + oz }
    end
    for i = 0, 5 do
        local doorOff = {[0]={0,2.2,0.4}, [1]={0,-2.2,0.4}, [-1]={-1,1,0.5}, [-2]={1,1,0.5}, [-3]={-1,-1,0.5}, [-4]={1,-1,0.5}}
    end
    off("d0", 0, 2.2, 0.4); off("d1", 0, -2.2, 0.4)
    off("d2", -1, 1, 0.5); off("d3", 1, 1, 0.5)
    off("d4", -1, -1, 0.5); off("d5", 1, -1, 0.5)
    off("p5", 0, 2.6, 0.1); off("p6", 0, -2.6, 0.1)
    off("w0", -1, 1.3, 0.2); off("w1", -1, -1.3, 0.2)
    off("w2", 1, 1.3, 0.2); off("w3", 1, -1.3, 0.2)
    off("e0", -1.4, 2.0, 0.2)
    off("g0", 0, 0.7, 0.7); off("g1", -1, 0, 0.7)
    off("g2", 1, 0, 0.7); off("g3", 0, -0.7, 0.7)
    return out
end

local function partNeedsAttention(kind, state)
    if kind == "wheel" then return state == 1 or state == 2
    elseif kind == "panel" then return state >= 1
    elseif kind == "engine" then return state >= 1
    elseif kind == "glass" then return state >= 1
    else return state == 2 or state == 3 or state == 4 end
end

-- ── Mechanic Mode Toggle ───────────────────────────────────
addCommandHandler("mechanic", function()
    triggerServerEvent("onPlayerRequestMechanicMode", resourceRoot)
end)

addEvent("onClientMechanicModeResponse", true)
addEventHandler("onClientMechanicModeResponse", resourceRoot, function(allowed)
    if not allowed then
        outputChatBox("#FF4444[مکانیک] #FFFFFFشما مکانیک نیستید!", 255, 255, 255, true)
        return
    end
    isMechanicMode = not isMechanicMode
    outputChatBox(isMechanicMode
        and "#00FF00[مکانیک] #FFFFFFحالت مکانیک فعال شد."
        or  "#FF4444[مکانیک] #FFFFFFحالت مکانیک غیرفعال شد.",
        255, 255, 255, true)
end)

-- ══════════════════════════════════════════════════════════
--  DRAWING FUNCTIONS
-- ══════════════════════════════════════════════════════════

-- ── Step Pill (Header Indicator) ───────────────────────────
local function drawStepPill(x, y, w, h, num, label, state, alphaMul)
    local A = function(v) return I(clamp(v * alphaMul, 0, 255)) end
    x, y, w, h = I(x), I(y), I(w), I(h)

    -- Background
    local bgCol, circBg, circFg, txtCol, numCol
    if state == "done" then
        bgCol   = tc(C.success[1], C.success[2], C.success[3], A(35))
        circBg  = tc(C.success[1], C.success[2], C.success[3], A(200))
        circFg  = tc(14, 16, 22, A(255))
        txtCol  = tc(C.success[1], C.success[2], C.success[3], A(220))
        numCol  = tc(14, 16, 22, A(255))
    elseif state == "active" then
        bgCol   = tc(C.accent[1], C.accent[2], C.accent[3], A(25))
        circBg  = tc(C.accent[1], C.accent[2], C.accent[3], A(230))
        circFg  = tc(14, 16, 22, A(255))
        txtCol  = tc(C.textPrimary[1], C.textPrimary[2], C.textPrimary[3], A(255))
        numCol  = tc(14, 16, 22, A(255))
    else
        bgCol   = tc(C.bgCard[1], C.bgCard[2], C.bgCard[3], A(200))
        circBg  = tc(C.border[1], C.border[2], C.border[3], A(150))
        circFg  = tc(C.textMuted[1], C.textMuted[2], C.textMuted[3], A(255))
        txtCol  = tc(C.textMuted[1], C.textMuted[2], C.textMuted[3], A(200))
        numCol  = tc(C.textMuted[1], C.textMuted[2], C.textMuted[3], A(200))
    end

    -- Pill background
    rr(x, y, w, h, h / 2, bgCol)
    -- Active pill border
    if state == "active" then
        rr(x, y, w, h, h / 2, tc(C.accent[1], C.accent[2], C.accent[3], A(60)))
    end

    -- Circle
    local cx = x + 22
    local cy = y + I(h / 2)
    dxDrawCircle(cx, cy, 12, 0, 360, circBg, circBg, 28)

    if state == "done" then
        iconCheck(cx, cy, 12, circFg)
    else
        txtNoShadow(tostring(num), cx - 12, cy - 12, cx + 12, cy + 12, numCol, 1.0, "default-bold")
    end

    -- Label
    txtNoShadow(label, x + 42, y, x + w - 10, y + h, txtCol, 0.92, "default-bold", "left", "center")

    -- Connecting line between pills (subtle)
    if state == "done" then
        -- Small dot to indicate flow
    end
end

-- ── Engine Content Renderer ────────────────────────────────
local function renderEngineContent(px, py, pw, ph, alphaMul, catColor, mx, my)
    local A = function(v) return I(clamp(v * alphaMul, 0, 255)) end

    if P.stage == 1 then
        -- Timing Bars
        for i, bar in ipairs(P.timingBars) do
            -- Bar background
            rr(bar.x, bar.y, bar.w, bar.h, 10, tc(22, 24, 32, A(255)))
            -- Inner track
            rr(bar.x + 3, bar.y + 3, bar.w - 6, bar.h - 6, 8, tc(C.track[1], C.track[2], C.track[3], A(255)))

            -- Target zone (red/green)
            local zy1 = bar.y + 3 + (bar.h - 6) * (1 - bar.zoneEnd / 100)
            local zy2 = bar.y + 3 + (bar.h - 6) * (1 - bar.zoneStart / 100)
            rr(bar.x + 3, I(zy1), bar.w - 6, I(zy2 - zy1), 4,
                tc(C.success[1], C.success[2], C.success[3], A(100)))

            -- Moving marker
            local markerY = bar.y + 3 + (bar.h - 6) * (1 - bar.value / 100)
            local markerCol = bar.locked and C.success or C.white
            rr(bar.x + 5, I(markerY - 2), bar.w - 10, 4, 2,
                tc(markerCol[1], markerCol[2], markerCol[3], A(255)))
            -- Marker glow
            if not bar.locked then
                rr(bar.x + 3, I(markerY - 4), bar.w - 6, 8, 4,
                    tc(markerCol[1], markerCol[2], markerCol[3], A(60)))
            end

            -- Locked overlay
            if bar.locked then
                rr(bar.x, bar.y, bar.w, bar.h, 10,
                    tc(C.success[1], C.success[2], C.success[3], A(20)))
                txtNoShadow("✓", bar.x, bar.y - 32, bar.x + bar.w, bar.y - 8,
                    tc(C.success[1], C.success[2], C.success[3], A(255)), 1.4, "default-bold")
            end

            -- Label
            txtNoShadow("BAR " .. i, bar.x, bar.y + bar.h + 10, bar.x + bar.w, bar.y + bar.h + 30,
                tc(C.textMuted[1], C.textMuted[2], C.textMuted[3], A(200)), 0.8, "default-bold")
        end

        -- Status text
        txt("قفل‌شده: " .. P.timingLocked .. " / " .. P.timingTotal,
            px, py + 170, px + pw, py + 195, tc(C.textPrimary[1], C.textPrimary[2], C.textPrimary[3], A(255)), 1.05)

        -- Hint
        txt("وقتی نشانگر هر میله توی ناحیه سبز بود، SPACE بزن",
            px, py + ph - 65, px + pw, py + ph - 38, tc(C.textMuted[1], C.textMuted[2], C.textMuted[3], A(180)), 0.82)

    elseif P.stage == 2 then
        -- Oil Pressure Gauge
        local cx = I(px + pw / 2)
        local cy = I(py + 250)
        local gr = 110

        -- Outer ring
        dxDrawCircle(cx, cy, gr + 16, 0, 360, tc(C.bgCard[1], C.bgCard[2], C.bgCard[3], A(255)), tc(C.bgCard[1], C.bgCard[2], C.bgCard[3], A(255)), 64)
        -- Inner face
        dxDrawCircle(cx, cy, gr, 0, 360, tc(24, 28, 38, A(255)), tc(24, 28, 38, A(255)), 64)

        -- Green arc zone
        local arcSegs = 28
        local startA = 180 + 180 * (P.oilZoneStart / 100)
        local endA = 180 + 180 * (P.oilZoneEnd / 100)
        for i = 0, arcSegs - 1 do
            local t1 = rad(startA + (endA - startA) * (i / arcSegs))
            local t2 = rad(startA + (endA - startA) * ((i + 1) / arcSegs))
            dxDrawLine(
                I(cx + cos(t1) * gr), I(cy + sin(t1) * gr),
                I(cx + cos(t2) * gr), I(cy + sin(t2) * gr),
                tc(C.success[1], C.success[2], C.success[3], A(180)), 12
            )
        end

        -- Tick marks
        for i = 0, 10 do
            local ang = rad(180 + i * 18)
            local x1 = cx + cos(ang) * (gr - 20)
            local y1 = cy + sin(ang) * (gr - 20)
            local x2 = cx + cos(ang) * (gr - 5)
            local y2 = cy + sin(ang) * (gr - 5)
            dxDrawLine(I(x1), I(y1), I(x2), I(y2), tc(120, 128, 145, A(180)), 2)
        end

        -- Needle
        local needleAng = rad(180 + 180 * (P.oilPressure / 100))
        local nx = cx + cos(needleAng) * (gr - 25)
        local ny = cy + sin(needleAng) * (gr - 25)
        -- Needle shadow
        dxDrawLine(cx + 1, cy + 2, I(nx) + 1, I(ny) + 2, tc(0, 0, 0, A(80)), 3)
        dxDrawLine(cx, cy, I(nx), I(ny), tc(C.catEngine[1], C.catEngine[2], C.catEngine[3], A(255)), 3)

        -- Center cap
        dxDrawCircle(cx, cy, 14, 0, 360, tc(C.catEngine[1], C.catEngine[2], C.catEngine[3], A(255)), tc(C.catEngine[1], C.catEngine[2], C.catEngine[3], A(255)), 24)
        dxDrawCircle(cx, cy, 6, 0, 360, tc(24, 28, 38, A(255)), tc(24, 28, 38, A(255)), 16)

        -- Flash ring
        if P.flashTimer > 0 then
            local fa = min(140, P.flashTimer * 5)
            local fc = P.flashType == 1 and C.success or C.danger
            dxDrawCircle(cx, cy, gr + 20, 0, 360,
                tc(fc[1], fc[2], fc[3], A(fa)), tc(fc[1], fc[2], fc[3], A(0)), 48)
        end

        -- Labels
        txtNoShadow("OIL PRESSURE", cx - 90, cy + 35, cx + 90, cy + 55,
            tc(C.textSecondary[1], C.textSecondary[2], C.textSecondary[3], A(200)), 0.9, "default-bold")
        txtNoShadow(string.format("%d PSI", I(P.oilPressure)), cx - 90, cy + 55, cx + 90, cy + 85,
            tc(C.textPrimary[1], C.textPrimary[2], C.textPrimary[3], A(255)), 1.35, "default-bold")

        -- Hold progress bar
        local barX = cx - 150
        local barY = cy + gr + 35
        local barW = 300
        local barH = 16
        rr(barX, barY, barW, barH, barH / 2, tc(C.track[1], C.track[2], C.track[3], A(255)))

        local holdPct = clamp(P.oilHoldTime / P.oilRequired, 0, 1)
        if holdPct > 0 then
            local isInZone = P.oilPressure >= P.oilZoneStart and P.oilPressure <= P.oilZoneEnd
            local fillC = isInZone and C.success or C.accent
            rr(barX + 2, barY + 2, max(0, I((barW - 4) * holdPct)), barH - 4, (barH - 4) / 2,
                tc(fillC[1], fillC[2], fillC[3], A(230)))
        end

        txtNoShadow(I(holdPct * 100) .. "%", barX, barY, barX + barW, barY + barH,
            tc(C.textWhite[1], C.textWhite[2], C.textWhite[3], A(220)), 0.82, "default-bold")
        txtNoShadow("فشار رو توی ناحیه سبز نگه دار", barX, barY + 22, barX + barW, barY + 42,
            tc(C.textMuted[1], C.textMuted[2], C.textMuted[3], A(160)), 0.78, "default")

        txt("SPACE رو نگه دار تا فشار بالا بره — توی ناحیه سبز نگهش دار",
            px, py + ph - 65, px + pw, py + ph - 38, tc(C.textMuted[1], C.textMuted[2], C.textMuted[3], A(180)), 0.78)

    elseif P.stage == 3 then
        -- Firing order header
        local orderText = "Firing Order:  1 → 3 → 4 → 2"
        txtNoShadow(orderText, px + pw / 2 - 200, py + 155, px + pw / 2 + 200, py + 180,
            tc(C.textSecondary[1], C.textSecondary[2], C.textSecondary[3], A(200)), 0.95, "default-bold")

        -- Cylinders
        for _, cyl in ipairs(P.cylinders) do
            local hover = false
            if mx and not cyl.fired then
                local dx2, dy2 = mx - cyl.x, my - cyl.y
                hover = (dx2 * dx2 + dy2 * dy2) <= (50 * 50)
            end

            local cr2 = 50
            local isNext = (P.firingOrder[P.nextFire] == cyl.number) and not cyl.fired

            -- Pulse ring for next target
            if isNext then
                local pulse = (sin(getTickCount() / 220) + 1) / 2
                dxDrawCircle(cyl.x, cyl.y, cr2 + 14 + pulse * 6, 0, 360,
                    tc(C.accent[1], C.accent[2], C.accent[3], A(50 + 30 * pulse)),
                    tc(C.accent[1], C.accent[2], C.accent[3], A(0)), 40)
            end

            -- Fire flash
            if cyl.flashTimer > 0 then
                local fa = min(200, cyl.flashTimer * 8)
                dxDrawCircle(cyl.x, cyl.y, cr2 + 22, 0, 360,
                    tc(255, 230, 100, A(fa)), tc(255, 230, 100, A(0)), 40)
            end

            -- Background circle
            local bgC = cyl.fired and C.success or (hover and C.bgCardHov or C.bgCard)
            dxDrawCircle(cyl.x, cyl.y, cr2, 0, 360,
                tc(bgC[1], bgC[2], bgC[3], A(255)), tc(bgC[1], bgC[2], bgC[3], A(255)), 48)
            -- Border
            local borderC = cyl.fired and C.success or catColor
            dxDrawCircle(cyl.x, cyl.y, cr2, 0, 360,
                tc(0, 0, 0, A(0)), tc(borderC[1], borderC[2], borderC[3], A(cyl.fired and 220 or 150)), 48)

            -- Number
            local numCol = cyl.fired and tc(C.bgCard[1], C.bgCard[2], C.bgCard[3], A(255))
                or tc(C.textPrimary[1], C.textPrimary[2], C.textPrimary[3], A(255))
            txtNoShadow(tostring(cyl.number), cyl.x - 35, cyl.y - 35, cyl.x + 35, cyl.y + 35,
                numCol, 1.9, "default-bold")

            -- Checkmark
            if cyl.fired then
                iconCheck(cyl.x + cr2 - 10, cyl.y - cr2 + 10, 11,
                    tc(C.bgCard[1], C.bgCard[2], C.bgCard[3], A(255)),
                    tc(C.success[1], C.success[2], C.success[3], A(255)))
            end
        end

        txt("سیلندرها: " .. (P.nextFire - 1) .. " / 4",
            px, py + ph - 65, px + pw, py + ph - 38, tc(C.textMuted[1], C.textMuted[2], C.textMuted[3], A(180)), 0.88)
    end
end

-- ── Glass Content Renderer ─────────────────────────────────
local function renderGlassContent(px, py, pw, ph, alphaMul, catColor, mx, my)
    local A = function(v) return I(clamp(v * alphaMul, 0, 255)) end

    if P.stage == 1 then
        for _, b in ipairs(P.bolts) do
            local hover = false
            if mx and not b.unscrewed then
                local dx2, dy2 = mx - b.x, my - b.y
                hover = (dx2 * dx2 + dy2 * dy2) <= BOLT_R * BOLT_R
            end
            drawBolt(b.x, b.y, BOLT_R, b.unscrewed and "done" or "intact", hover, nil, alphaMul)
        end

    elseif P.stage == 2 then
        -- Glass panel
        local gx, gy = px + 120, py + 185
        local gw, gh = pw - 240, 190

        -- Glass background with transparency effect
        rr(gx, gy, gw, gh, 14, tc(C.catGlass[1], C.catGlass[2], C.catGlass[3], A(25)))
        rr(gx + 3, gy + 3, gw - 6, gh - 6, 12, tc(C.catGlass[1], C.catGlass[2], C.catGlass[3], A(15)))

        -- Highlight streak
        gradient(gx + 20, gy + 10, 3, gh - 20,
            {255, 255, 255, A(40)}, {255, 255, 255, A(0)}, 10)

        -- Cracks
        for _, c in ipairs(P.glassCracks) do
            if not c.cleaned then
                local hover = false
                if mx then
                    local dx2, dy2 = mx - c.x, my - c.y
                    hover = (dx2 * dx2 + dy2 * dy2) <= 30 * 30
                end

                -- Crack lines
                dxDrawLine(c.x - 16, c.y - 12, c.x + 16, c.y + 12, tc(40, 55, 80, A(220)), 2)
                dxDrawLine(c.x - 12, c.y + 10, c.x + 14, c.y - 14, tc(40, 55, 80, A(200)), 2)
                dxDrawLine(c.x, c.y - 16, c.x + 2, c.y + 16, tc(50, 65, 90, A(180)), 1)

                if hover then
                    dxDrawCircle(c.x, c.y, 24, 0, 360,
                        tc(C.textWhite[1], C.textWhite[2], C.textWhite[3], A(50)),
                        tc(C.textWhite[1], C.textWhite[2], C.textWhite[3], A(0)), 28)
                end
            else
                -- Cleaned spot
                dxDrawCircle(c.x, c.y, 12, 0, 360,
                    tc(C.catGlass[1], C.catGlass[2], C.catGlass[3], A(50)),
                    tc(C.catGlass[1], C.catGlass[2], C.catGlass[3], A(0)), 20)
            end
        end

        txt("روی هر ترک کلیک کن تا تمیز بشه", px, py + 160, px + pw, py + 180,
            tc(C.textSecondary[1], C.textSecondary[2], C.textSecondary[3], A(200)), 0.85)
        txt("ترک‌ها: " .. P.glassCleaned .. " / " .. #P.glassCracks,
            px, py + ph - 65, px + pw, py + ph - 38, tc(C.textMuted[1], C.textMuted[2], C.textMuted[3], A(180)), 0.88)

    elseif P.stage == 3 then
        local pulse = (sin(getTickCount() / 240) + 1) / 2
        for _, b in ipairs(P.tightenBolts) do
            local hover = false
            if mx and not b.done then
                local dx2, dy2 = mx - b.x, my - b.y
                hover = (dx2 * dx2 + dy2 * dy2) <= BOLT_R * BOLT_R
            end
            local state
            if b.done then state = "done"
            elseif b.order == P.nextOrder then state = "next"
            else state = "disabled" end

            if state == "next" then
                dxDrawCircle(b.x, b.y, BOLT_R + 12 + I(pulse * 5), 0, 360,
                    tc(catColor[1], catColor[2], catColor[3], A(50 * pulse)),
                    tc(catColor[1], catColor[2], catColor[3], A(0)), 36)
            end
            drawBolt(b.x, b.y, BOLT_R, state, hover, b.order, alphaMul)
        end
    end
end

-- ── Progress Bar (Footer) ──────────────────────────────────
local function drawProgressBar(px, py, pw, alphaMul, catColor)
    local A = function(v) return I(clamp(v * alphaMul, 0, 255)) end

    local divY = py - 4
    dxDrawRectangle(px, divY, pw, 1, tc(C.border[1], C.border[2], C.border[3], A(120)))

    local barX = px
    local barY = divY + 20
    local barW = pw
    local barH = 8

    -- Track
    rr(barX, barY, barW, barH, 4, tc(C.track[1], C.track[2], C.track[3], A(255)))

    local pct, label, value
    if P.panelKind == "engine" then
        if P.stage == 1 then
            pct = P.timingLocked / P.timingTotal
            label = "قفل‌شده"; value = P.timingLocked .. " / " .. P.timingTotal
        elseif P.stage == 2 then
            pct = clamp(P.oilHoldTime / P.oilRequired, 0, 1)
            label = "فشار نگه‌داشته"; value = I(pct * 100) .. "%"
        else
            pct = (P.nextFire - 1) / 4
            label = "سیلندرها"; value = (P.nextFire - 1) .. " / 4"
        end
    elseif P.panelKind == "glass" then
        if P.stage == 1 then
            pct = P.unscrewed / #P.bolts
            label = "بازشده"; value = P.unscrewed .. " / " .. #P.bolts
        elseif P.stage == 2 then
            pct = P.glassCleaned / #P.glassCracks
            label = "تمیزشده"; value = P.glassCleaned .. " / " .. #P.glassCracks
        else
            pct = (P.nextOrder - 1) / P.tightenTotal
            label = "سفتشده"; value = (P.nextOrder - 1) .. " / " .. P.tightenTotal
        end
    elseif P.stage == 1 then
        pct = P.unscrewed / #P.bolts
        label = "بازشده"; value = P.unscrewed .. " / " .. #P.bolts
    elseif P.stage == 2 then
        pct = P.hammerHits / P.hammerNeeded
        label = P.panelKind == "wheel" and "ترمیم‌شده" or "ضربه‌های موفق"
        value = P.hammerHits .. " / " .. P.hammerNeeded
    else
        if P.panelKind == "wheel" then
            pct = P.airPressure / 100
            label = "باد شده"; value = I(P.airPressure) .. "%"
        else
            pct = (P.nextOrder - 1) / P.tightenTotal
            label = "سفتشده"; value = (P.nextOrder - 1) .. " / " .. P.tightenTotal
        end
    end

    -- Fill
    if pct > 0 then
        local fillC = catColor
        if P.stage == 3 and P.panelKind == "wheel" then fillC = C.air end
        rr(barX + 1, barY + 1, max(0, I((barW - 2) * pct)), barH - 2, 3,
            tc(fillC[1], fillC[2], fillC[3], A(230)))
    end

    -- Labels
    txtNoShadow(label, barX, barY + 14, barX + barW / 2, barY + 34,
        tc(C.textSecondary[1], C.textSecondary[2], C.textSecondary[3], A(200)), 0.85, "default-bold", "left", "center")
    txtNoShadow(value, barX + barW / 2, barY + 14, barX + barW, barY + 34,
        tc(C.textPrimary[1], C.textPrimary[2], C.textPrimary[3], A(220)), 0.85, "default-bold", "right", "center")
end

-- ══════════════════════════════════════════════════════════
--  MAIN PANEL RENDER
-- ══════════════════════════════════════════════════════════
local function renderPanel()
    local now = getTickCount()
    local t = clamp((now - P.openTick) / 300, 0, 1)
    local scale = 0.92 + 0.08 * easeOutBack(t)
    local alphaMul = easeOutCubic(t)

    -- Shake effect
    local shakeX, shakeY = 0, 0
    if P.shakeTimer > 0 then
        shakeX = (math.random() - 0.5) * P.shakeIntensity * (P.shakeTimer / 0.3)
        shakeY = (math.random() - 0.5) * P.shakeIntensity * (P.shakeTimer / 0.3)
    end

    local pw = I(PANEL_W * scale)
    local ph = I(PANEL_H * scale)
    local px = I(P.panelX + (PANEL_W - pw) / 2 + shakeX)
    local py = I(P.panelY + (PANEL_H - ph) / 2 + shakeY)

    local A = function(v) return I(clamp(v * alphaMul, 0, 255)) end
    local catColor = getCatColor(P.panelKind)

    -- Mouse position
    local mx, my = getCursorPosition()
    if mx then
        local sw, sh = guiGetScreenSize()
        mx, my = I(mx * sw), I(my * sh)
    end

    -- ── Shadow layers ──────────────────────────────────────
    shadow(px, py, pw, ph, 16, 12, A(80))

    -- ── Main panel background ──────────────────────────────
    rr(px, py, pw, ph, 16, tc(C.bg[1], C.bg[2], C.bg[3], A(252)))
    -- Border
    rr(px, py, pw, ph, 16, tc(C.border[1], C.border[2], C.border[3], A(100)))

    -- ── Header ─────────────────────────────────────────────
    local headerH = 76
    -- Header background with slight gradient
    rr(px + 1, py + 1, pw - 2, headerH, 15, tc(C.bgHeader[1], C.bgHeader[2], C.bgHeader[3], A(255)))
    -- Bottom corners fix
    dxDrawRectangle(px + 1, py + headerH - 15, pw - 2, 15, tc(C.bgHeader[1], C.bgHeader[2], C.bgHeader[3], A(255)))
    -- Accent line
    dxDrawRectangle(px + 1, py + headerH, pw - 2, 2, tc(catColor[1], catColor[2], catColor[3], A(180)))

    -- Gear icon
    local gearRot = (now / 45) % 360
    iconGear(px + 38, py + 38, 18, gearRot, tc(catColor[1], catColor[2], catColor[3], A(230)))

    -- Title
    txtNoShadow("MECHANIC", px + 70, py + 14, px + pw - 80, py + 40,
        tc(C.textPrimary[1], C.textPrimary[2], C.textPrimary[3], A(255)), 1.3, "default-bold", "left", "center")

    -- Part name
    local partName
    if P.panelKind == "wheel" then partName = WHEEL_NAMES[P.targetIndex] or "Tire"
    elseif P.panelKind == "engine" then partName = "Engine Block"
    elseif P.panelKind == "glass" then partName = GLASS_NAMES[P.targetIndex] or "Glass"
    elseif P.panelKind == "panel" then partName = PANEL_NAMES[P.targetIndex] or "Body Panel"
    else partName = DOOR_NAMES[P.targetIndex] or "Door" end

    txtNoShadow(partName .. " — Repair System", px + 72, py + 40, px + pw - 80, py + 60,
        tc(C.textSecondary[1], C.textSecondary[2], C.textSecondary[3], A(200)), 0.82, "default-bold", "left", "center")

    -- Close button
    local cbCX, cbCY, cbs = px + pw - 34, py + 38, 28
    local hoverClose = mx and abs(mx - cbCX) < 16 and abs(my - cbCY) < 16
    local cbBg = hoverClose and C.danger or C.bgCard
    local cbFg = hoverClose and C.textWhite or C.textMuted
    rr(cbCX - cbs / 2, cbCY - cbs / 2, cbs, cbs, 8,
        tc(cbBg[1], cbBg[2], cbBg[3], A(220)))
    txtNoShadow("✕", cbCX - cbs / 2, cbCY - cbs / 2, cbCX + cbs / 2, cbCY + cbs / 2,
        tc(cbFg[1], cbFg[2], cbFg[3], A(230)), 1.1, "default-bold")

    -- ── Step Indicators ────────────────────────────────────
    local padX = 28
    local pillY = py + headerH + 24
    local pillH = 42
    local gap = 14
    local pillW = I((pw - padX * 2 - gap * 2) / 3)

    local stageStates = {"waiting", "waiting", "waiting"}
    for i = 1, 3 do
        if i < P.stage then stageStates[i] = "done"
        elseif i == P.stage then stageStates[i] = "active" end
    end

    local stepLabels
    if P.panelKind == "wheel" then stepLabels = {"بازکردن", "ترمیم", "بادکردن"}
    elseif P.panelKind == "engine" then stepLabels = {"زمان‌بندی", "روغن", "احتراق"}
    elseif P.panelKind == "glass" then stepLabels = {"بازکردن", "تمیزکردن", "نصب"}
    else stepLabels = {"بازکردن", "ضربه", "سفتکردن"} end

    for i = 1, 3 do
        local sx = px + padX + (i - 1) * (pillW + gap)
        drawStepPill(sx, pillY, pillW, pillH, i, stepLabels[i], stageStates[i], alphaMul)
    end

    -- Divider
    local divY = pillY + pillH + 20
    dxDrawRectangle(px + padX, divY, pw - padX * 2, 1,
        tc(C.border[1], C.border[2], C.border[3], A(100)))

    -- ── Error Message ──────────────────────────────────────
    if errorMessage then
        local elapsed = now - errorTick
        if elapsed < 2500 then
            local errA = elapsed < 2000 and 255 or I(255 * (1 - (elapsed - 2000) / 500))
            local errY = divY + 8
            rr(px + padX, errY, pw - padX * 2, 30, 8,
                tc(C.danger[1], C.danger[2], C.danger[3], I(errA * 0.8)))
            -- Left accent bar
            rr(px + padX, errY, 3, 30, 1, tc(C.danger[1], C.danger[2], C.danger[3], errA))
            txtNoShadow(errorMessage, px + padX + 12, errY, px + pw - padX, errY + 30,
                tc(C.textWhite[1], C.textWhite[2], C.textWhite[3], errA), 0.85, "default-bold")
        else
            errorMessage = nil
        end
    end

    -- ── Content Area ───────────────────────────────────────
    if P.panelKind == "engine" then
        renderEngineContent(px, py, pw, ph, alphaMul, catColor, mx, my)
    elseif P.panelKind == "glass" then
        renderGlassContent(px, py, pw, ph, alphaMul, catColor, mx, my)
    else
        -- Standard door/panel/wheel content
        if P.stage == 1 then
            -- Unscrew bolts
            for _, b in ipairs(P.bolts) do
                local hover = false
                if mx and not b.unscrewed then
                    local dx2, dy2 = mx - b.x, my - b.y
                    hover = (dx2 * dx2 + dy2 * dy2) <= BOLT_R * BOLT_R
                end
                drawBolt(b.x, b.y, BOLT_R, b.unscrewed and "done" or "intact", hover, nil, alphaMul)
            end

        elseif P.stage == 2 then
            -- Timing bar
            local barX = px + 120
            local barY = py + 260
            local barW = pw - 240
            local barH = 50

            -- Track
            rr(barX, barY, barW, barH, 12, tc(C.track[1], C.track[2], C.track[3], A(255)))

            -- Target zone
            local z1 = I(barX + barW * (P.zoneStart / 100))
            local z2 = I(barX + barW * (P.zoneEnd / 100))
            rr(z1, barY, z2 - z1, barH, 8,
                tc(C.success[1], C.success[2], C.success[3], A(80)))
            -- Zone borders
            dxDrawRectangle(z1, barY, 2, barH, tc(C.success[1], C.success[2], C.success[3], A(200)))
            dxDrawRectangle(z2 - 2, barY, 2, barH, tc(C.success[1], C.success[2], C.success[3], A(200)))

            -- Moving marker
            local markX = I(barX + barW * (P.hammerPos / 100))
            rr(markX - 2, barY - 8, 4, barH + 16, 2, tc(C.textPrimary[1], C.textPrimary[2], C.textPrimary[3], A(255)))
            -- Marker caps
            rr(markX - 6, barY - 12, 12, 4, 2, tc(catColor[1], catColor[2], catColor[3], A(230)))
            rr(markX - 6, barY + barH + 8, 12, 4, 2, tc(catColor[1], catColor[2], catColor[3], A(230)))

            -- Flash
            if P.flashTimer > 0 then
                local fa = min(140, P.flashTimer * 5)
                local fc = P.flashType == 1 and C.success or C.danger
                rr(barX, barY, barW, barH, 12, tc(fc[1], fc[2], fc[3], A(fa)))
            end

            -- Hit indicators (dots)
            local dotsY = barY + barH + 30
            local dotSpacing = 48
            local totalDotW = (P.hammerNeeded - 1) * dotSpacing
            local dotStartX = I(px + pw / 2 - totalDotW / 2)
            for i = 1, P.hammerNeeded do
                local dotX = dotStartX + (i - 1) * dotSpacing
                local filled = i <= P.hammerHits
                if filled then
                    dxDrawCircle(dotX, dotsY, 11, 0, 360,
                        tc(C.success[1], C.success[2], C.success[3], A(220)),
                        tc(C.success[1], C.success[2], C.success[3], A(220)), 28)
                    iconCheck(dotX, dotsY, 11, tc(C.bgCard[1], C.bgCard[2], C.bgCard[3], A(255)))
                else
                    dxDrawCircle(dotX, dotsY, 11, 0, 360,
                        tc(C.track[1], C.track[2], C.track[3], A(255)),
                        tc(C.border[1], C.border[2], C.border[3], A(150)), 28)
                end
            end

            -- Hint
            local hint = P.panelKind == "wheel"
                and "وقتی نشانگر توی ناحیه سبز بود، SPACE بزن"
                or  "وقتی نشانگر توی ناحیه سبز بود، SPACE بزن"
            txt(hint, px, py + ph - 65, px + pw, py + ph - 38,
                tc(C.textMuted[1], C.textMuted[2], C.textMuted[3], A(180)), 0.82)

        elseif P.stage == 3 then
            if P.panelKind == "wheel" then
                -- Tire pressure bar
                local barX = px + 120
                local barY = py + 245
                local barW = pw - 240
                local barH = 65

                -- Track
                rr(barX, barY, barW, barH, 12, tc(C.track[1], C.track[2], C.track[3], A(255)))

                -- Target line
                local targetX = I(barX + barW * (P.airTarget / 100))
                dxDrawRectangle(targetX - 2, barY - 10, 4, barH + 20,
                    tc(C.success[1], C.success[2], C.success[3], A(220)))

                -- Fill
                local fillW = I(barW * (P.airPressure / 100))
                if fillW > 0 then
                    local fillC = P.airOvershoot and C.danger or C.air
                    rr(barX, barY, fillW, barH, 12,
                        tc(fillC[1], fillC[2], fillC[3], A(180)))
                end

                -- Marker
                local markX = I(barX + barW * (P.airPressure / 100))
                rr(markX - 2, barY - 12, 4, barH + 24, 2, tc(C.textWhite[1], C.textWhite[2], C.textWhite[3], A(255)))

                -- Flash
                if P.flashTimer > 0 then
                    local fa = min(140, P.flashTimer * 5)
                    local fc = P.flashType == 1 and C.success or C.danger
                    rr(barX, barY, barW, barH, 12, tc(fc[1], fc[2], fc[3], A(fa)))
                end

                -- Labels
                txtNoShadow("Tire Pressure", px, barY - 32, px + pw, barY - 8,
                    tc(C.textSecondary[1], C.textSecondary[2], C.textSecondary[3], A(200)), 0.95, "default-bold")
                txtNoShadow(string.format("%d PSI", I(P.airPressure)), px, barY + barH + 10, px + pw, barY + barH + 38,
                    tc(P.airOvershoot and C.danger[1] or C.textPrimary[1],
                       P.airOvershoot and C.danger[2] or C.textPrimary[2],
                       P.airOvershoot and C.danger[3] or C.textPrimary[3], A(255)), 1.25, "default-bold")

                -- Hint
                local hintText
                if not airStarted then hintText = "SPACE رو نگه دار تا باد بزنه"
                elseif spaceHeld then hintText = "رها کن وقتی نشانگر روی خط سبزه"
                else hintText = "در حال رها شدن..." end
                txt(hintText, px, py + ph - 65, px + pw, py + ph - 38,
                    tc(C.textMuted[1], C.textMuted[2], C.textMuted[3], A(180)), 0.82)

            else
                -- Tighten bolts in order
                local pulse = (sin(now / 240) + 1) / 2
                for _, b in ipairs(P.tightenBolts) do
                    local hover = false
                    if mx and not b.done then
                        local dx2, dy2 = mx - b.x, my - b.y
                        hover = (dx2 * dx2 + dy2 * dy2) <= BOLT_R * BOLT_R
                    end
                    local state
                    if b.done then state = "done"
                    elseif b.order == P.nextOrder then state = "next"
                    else state = "disabled" end

                    if state == "next" then
                        dxDrawCircle(b.x, b.y, BOLT_R + 12 + I(pulse * 5), 0, 360,
                            tc(catColor[1], catColor[2], catColor[3], A(50 * pulse)),
                            tc(catColor[1], catColor[2], catColor[3], A(0)), 36)
                    end
                    drawBolt(b.x, b.y, BOLT_R, state, hover, b.order, alphaMul)
                end
            end
        end
    end

    -- ── Particles ──────────────────────────────────────────
    drawParticles()

    -- ── Footer Progress Bar ────────────────────────────────
    local footerY = py + ph - 50
    drawProgressBar(px + padX, footerY, pw - padX * 2, alphaMul, catColor)
end

-- ══════════════════════════════════════════════════════════
--  WORLD BUTTONS & OVERLAYS
-- ══════════════════════════════════════════════════════════

local function drawWorldButton(x, y, w, h, kind, idx, text, accentColor, data, ref)
    x, y, w, h = I(x), I(y), I(w), I(h)
    local catCol = getCatColor(kind)
    local catLbl = getCatLabel(kind, idx)

    -- Background
    shadow(x, y, w, h, 8, 6, 50)
    rr(x, y, w, h, 8, tc(C.bgCard[1], C.bgCard[2], C.bgCard[3], 240))
    -- Border
    rr(x, y, w, h, 8, tc(C.border[1], C.border[2], C.border[3], 160))
    -- Top accent line
    rr(x + 8, y, w - 16, 2, 1, tc(accentColor[1], accentColor[2], accentColor[3], 255))
    -- Category dot
    dxDrawCircle(x + 16, y + h / 2, 4, 0, 360,
        tc(catCol[1], catCol[2], catCol[3], 230),
        tc(catCol[1], catCol[2], catCol[3], 230), 14)
    -- Text
    txtNoShadow(text, x + 28, y, x + w - 50, y + h,
        tc(C.textPrimary[1], C.textPrimary[2], C.textPrimary[3], 240), 0.88, "default-bold", "left", "center")
    -- Category label
    txtNoShadow(catLbl, x + w - 55, y, x + w - 8, y + h,
        tc(catCol[1], catCol[2], catCol[3], 180), 0.7, "default-bold", "right", "center")

    if data then
        table.insert(ref, {
            x = x, y = y, w = w, h = h,
            vehicle = data.vehicle, doorIndex = data.doorIndex,
            action = data.action, isPanel = data.isPanel,
            isWheel = data.isWheel, isEngine = data.isEngine,
            isGlass = data.isGlass,
        })
    end
end

local function drawBottomHint(partNameFa, isBroken)
    local sw, sh = guiGetScreenSize()
    local boxW, boxH = 360, 44
    local boxX = I((sw - boxW) / 2)
    local boxY = I(sh - 145)
    local accentCol = isBroken and C.danger or C.success

    shadow(boxX, boxY, boxW, boxH, 10, 8, 60)
    rr(boxX, boxY, boxW, boxH, 10, tc(C.bgCard[1], C.bgCard[2], C.bgCard[3], 240))
    rr(boxX, boxY, boxW, boxH, 10, tc(C.border[1], C.border[2], C.border[3], 140))
    -- Left accent bar
    rr(boxX, boxY + 8, 3, boxH - 16, 1,
        tc(accentCol[1], accentCol[2], accentCol[3], 230))

    -- Pulse dot
    local pulse = (sin(getTickCount() / 320) + 1) / 2
    dxDrawCircle(boxX + 22, boxY + boxH / 2, 5, 0, 360,
        tc(accentCol[1], accentCol[2], accentCol[3], I(130 + 125 * pulse)),
        tc(accentCol[1], accentCol[2], accentCol[3], I(130 + 125 * pulse)), 16)

    -- Part name
    txtNoShadow(partNameFa, boxX + 38, boxY, boxX + boxW - 16, boxY + boxH,
        tc(C.textPrimary[1], C.textPrimary[2], C.textPrimary[3], 255), 0.98, "default-bold", "left", "center")
    -- Status
    txtNoShadow(isBroken and "آسیب دیده" or "سالم",
        boxX, boxY, boxX + boxW - 16, boxY + boxH,
        tc(accentCol[1], accentCol[2], accentCol[3], 210), 0.8, "default-bold", "right", "center")
end

-- ══════════════════════════════════════════════════════════
--  MAIN RENDER LOOP
-- ══════════════════════════════════════════════════════════
addEventHandler("onClientRender", root, function()
    if P.active then
        renderPanel()
        return
    end

    -- Working progress bar
    if isWorking then
        local sw, sh = guiGetScreenSize()
        local bw, bh = 420, 28
        local bx = I((sw - bw) / 2)
        local by = I(sh - 125)

        shadow(bx, by, bw, bh, 10, 8, 60)
        rr(bx, by, bw, bh, 10, tc(C.bgCard[1], C.bgCard[2], C.bgCard[3], 245))
        rr(bx, by, bw, bh, 10, tc(C.border[1], C.border[2], C.border[3], 160))
        if progress > 0 then
            rr(bx + 2, by + 2, max(0, I((bw - 4) * (progress / 100))), bh - 4, 8,
                tc(C.accent[1], C.accent[2], C.accent[3], 240))
        end
        txt((actionType == "detach" and "Removing..." or "Installing...") .. "  " .. floor(progress) .. "%",
            bx, by, bx + bw, by + bh, tc(C.textWhite[1], C.textWhite[2], C.textWhite[3], 255), 0.95)
    end

    if not isMechanicMode or isWorking or P.active then
        doorButtons = {}
        return
    end

    -- Vehicle proximity check
    local veh = getNearbyVehicleCached()
    if not veh or not isElement(veh) then doorButtons = {}; return end

    local positions = getPanelPositions(veh)
    doorButtons = {}
    local px2, py2, pz2 = getElementPosition(localPlayer)

    local closestKey, closestDist = nil, INTERACT_DIST
    for key, pos in pairs(positions) do
        local d = getDistanceBetweenPoints3D(px2, py2, pz2, pos[1], pos[2], pos[3])
        if d < closestDist then closestDist = d; closestKey = key end
    end
    if not closestKey then return end

    local kind = "door"
    local idx
    local prefix = closestKey:sub(1, 1)
    if prefix == "d" then kind = "door"; idx = tonumber(closestKey:sub(2))
    elseif prefix == "p" then kind = "panel"; idx = tonumber(closestKey:sub(2))
    elseif prefix == "w" then kind = "wheel"; idx = tonumber(closestKey:sub(2))
    elseif prefix == "e" then kind = "engine"; idx = 0
    elseif prefix == "g" then kind = "glass"; idx = tonumber(closestKey:sub(2)) end

    -- Get state
    local state
    if kind == "engine" then
        local hp = getElementHealth(veh)
        if hp >= 600 then state = 0 elseif hp >= 350 then state = 1 else state = 2 end
    elseif kind == "glass" then
        state = getVehiclePanelState(veh, 4)
    elseif kind == "wheel" then
        local fl, rl, fr, rr_s = getVehicleWheelStates(veh)
        local ws = {fl, rl, fr, rr_s}
        state = ws[idx + 1]
    elseif kind == "panel" then
        state = getVehiclePanelState(veh, idx)
    else
        state = getVehicleDoorState(veh, idx)
    end

    local partFa = (PART_FA[kind] and PART_FA[kind][idx]) or "قطعه"
    local needsFix = partNeedsAttention(kind, state)

    drawBottomHint(partFa, needsFix)
    if not needsFix then return end

    -- Draw action buttons
    local pos = positions[closestKey]
    local sx, sy = getScreenFromWorldPosition(pos[1], pos[2], pos[3] + 0.5)
    if not sx or not sy then return end
    sx, sy = I(sx), I(sy)
    local bw2, bh2 = 125, 30

    if kind == "engine" then
        local bx2, by2 = sx - bw2 / 2, sy - bh2 / 2
        drawWorldButton(bx2, by2, bw2, bh2, kind, idx, "Repair", C.catEngine,
            {vehicle = veh, doorIndex = idx, action = "repair", isPanel = false, isEngine = true},
            doorButtons)
    elseif kind == "glass" then
        if state >= 1 then
            local bx2, by2 = sx - bw2 / 2, sy - bh2 / 2
            drawWorldButton(bx2, by2, bw2, bh2, kind, idx, "Repair", C.catGlass,
                {vehicle = veh, doorIndex = idx, action = "repair", isPanel = false, isGlass = true},
                doorButtons)
        end
    elseif kind == "wheel" then
        local bx2, by2 = sx - bw2 / 2, sy - bh2 / 2
        if state == 1 then
            drawWorldButton(bx2, by2, bw2, bh2, kind, idx, "Repair", C.air,
                {vehicle = veh, doorIndex = idx, action = "repair", isPanel = false, isWheel = true},
                doorButtons)
        elseif state == 2 then
            drawWorldButton(bx2, by2, bw2, bh2, kind, idx, "Attach", C.success,
                {vehicle = veh, doorIndex = idx, action = "attach", isPanel = false, isWheel = true},
                doorButtons)
        end
    elseif kind == "panel" then
        if state >= 1 then
            local bx2, by2 = sx - bw2 / 2, sy - bh2 / 2
            drawWorldButton(bx2, by2, bw2, bh2, kind, idx, "Repair", C.success,
                {vehicle = veh, doorIndex = idx, action = "repair", isPanel = true},
                doorButtons)
        end
    else
        if state == 4 then
            local bx2, by2 = sx - bw2 / 2, sy - bh2 / 2
            drawWorldButton(bx2, by2, bw2, bh2, kind, idx, "Attach", C.success,
                {vehicle = veh, doorIndex = idx, action = "attach", isPanel = false},
                doorButtons)
        elseif state == 2 or state == 3 then
            local gap2 = 10
            local tw = bw2 * 2 + gap2
            local startX = I(sx - tw / 2)
            local by2 = sy - bh2 / 2
            drawWorldButton(startX, by2, bw2, bh2, kind, idx, "Detach", C.danger,
                {vehicle = veh, doorIndex = idx, action = "detach", isPanel = false},
                doorButtons)
            drawWorldButton(startX + bw2 + gap2, by2, bw2, bh2, kind, idx, "Repair", C.success,
                {vehicle = veh, doorIndex = idx, action = "repair", isPanel = false},
                doorButtons)
        end
    end
end)

-- ══════════════════════════════════════════════════════════
--  CLICK HANDLER
-- ══════════════════════════════════════════════════════════
addEventHandler("onClientClick", root, function(button, state2, absX, absY)
    if button ~= "left" or state2 ~= "down" then return end

    if P.active then
        -- Close button
        local cbCX = P.panelX + PANEL_W - 34
        local cbCY = P.panelY + 38
        if abs(absX - cbCX) < 16 and abs(absY - cbCY) < 16 then
            closePanel()
            return
        end

        -- Engine stage 3: cylinder clicks
        if P.panelKind == "engine" then
            if P.stage == 3 then
                for _, cyl in ipairs(P.cylinders) do
                    if not cyl.fired then
                        local dx2, dy2 = absX - cyl.x, absY - cyl.y
                        if dx2 * dx2 + dy2 * dy2 <= 50 * 50 then
                            if P.firingOrder[P.nextFire] == cyl.number then
                                cyl.fired = true; cyl.flashTimer = 30
                                P.nextFire = P.nextFire + 1
                                playSoundFrontEnd(1)
                                spawnParticles(cyl.x, cyl.y, 12, C.success, 60)
                                if P.nextFire > 4 then
                                    local v, d = P.vehicle, P.targetIndex
                                    closePanel()
                                    triggerServerEvent("onPlayerFinishDoorWork", resourceRoot, v, d, "repair", false, false, true)
                                end
                            else
                                failAndReset("ترتیب جرقه اشتباه! از مرحله ۱ شروع کن")
                            end
                            return
                        end
                    end
                end
            end
            return
        end

        -- Glass stages
        if P.panelKind == "glass" then
            if P.stage == 1 then
                for _, b in ipairs(P.bolts) do
                    if not b.unscrewed then
                        local dx2, dy2 = absX - b.x, absY - b.y
                        if dx2 * dx2 + dy2 * dy2 <= BOLT_R * BOLT_R then
                            b.unscrewed = true; P.unscrewed = P.unscrewed + 1
                            playSoundFrontEnd(1)
                            spawnParticles(b.x, b.y, 8, C.textSecondary, 40)
                            if P.unscrewed >= #P.bolts then resetGlassStage2() end
                            return
                        end
                    end
                end
            elseif P.stage == 2 then
                for _, c in ipairs(P.glassCracks) do
                    if not c.cleaned then
                        local dx2, dy2 = absX - c.x, absY - c.y
                        if dx2 * dx2 + dy2 * dy2 <= 30 * 30 then
                            c.cleaned = true; P.glassCleaned = P.glassCleaned + 1
                            playSoundFrontEnd(1)
                            spawnParticles(c.x, c.y, 6, C.catGlass, 30)
                            if P.glassCleaned >= #P.glassCracks then resetGlassStage3() end
                            return
                        end
                    end
                end
            elseif P.stage == 3 then
                for _, b in ipairs(P.tightenBolts) do
                    if not b.done then
                        local dx2, dy2 = absX - b.x, absY - b.y
                        if dx2 * dx2 + dy2 * dy2 <= BOLT_R * BOLT_R then
                            if b.order == P.nextOrder then
                                b.done = true; P.nextOrder = P.nextOrder + 1
                                playSoundFrontEnd(1)
                                spawnParticles(b.x, b.y, 8, C.success, 50)
                                if P.nextOrder > P.tightenTotal then
                                    local v, d = P.vehicle, P.targetIndex
                                    closePanel()
                                    triggerServerEvent("onPlayerFinishDoorWork", resourceRoot, v, d, "repair", false, false, false, true)
                                end
                            else
                                failAndReset("ترتیب اشتباه! از مرحله ۱ شروع کن")
                            end
                            return
                        end
                    end
                end
            end
            return
        end

        -- Standard bolt stages (door/panel/wheel)
        if P.stage == 1 then
            for _, b in ipairs(P.bolts) do
                if not b.unscrewed then
                    local dx2, dy2 = absX - b.x, absY - b.y
                    if dx2 * dx2 + dy2 * dy2 <= BOLT_R * BOLT_R then
                        b.unscrewed = true; P.unscrewed = P.unscrewed + 1
                        playSoundFrontEnd(1)
                        spawnParticles(b.x, b.y, 8, C.textSecondary, 40)
                        if P.unscrewed >= #P.bolts then
                            if P.panelKind == "wheel" then resetWheelStage2()
                            else resetStage2() end
                        end
                        return
                    end
                end
            end
        elseif P.stage == 3 and P.panelKind ~= "wheel" then
            for _, b in ipairs(P.tightenBolts) do
                if not b.done then
                    local dx2, dy2 = absX - b.x, absY - b.y
                    if dx2 * dx2 + dy2 * dy2 <= BOLT_R * BOLT_R then
                        if b.order == P.nextOrder then
                            b.done = true; P.nextOrder = P.nextOrder + 1
                            playSoundFrontEnd(1)
                            spawnParticles(b.x, b.y, 8, C.success, 50)
                            if P.nextOrder > P.tightenTotal then
                                local v, d = P.vehicle, P.targetIndex
                                local k = P.panelKind
                                closePanel()
                                triggerServerEvent("onPlayerFinishDoorWork", resourceRoot, v, d, "repair", k == "panel", k == "wheel")
                            end
                        else
                            failAndReset("ترتیب اشتباه! از مرحله ۱ شروع کن")
                        end
                        return
                    end
                end
            end
        end
        return
    end

    -- World buttons
    if not isMechanicMode or isWorking then return end
    for _, btn in ipairs(doorButtons) do
        if absX >= btn.x and absX <= btn.x + btn.w and absY >= btn.y and absY <= btn.y + btn.h then
            if btn.action == "repair" then
                local k = "door"
                if btn.isWheel then k = "wheel"
                elseif btn.isPanel then k = "panel"
                elseif btn.isEngine then k = "engine"
                elseif btn.isGlass then k = "glass" end
                openPanel(btn.vehicle, btn.doorIndex, k)
                return
            end
            actionType = btn.action
            actionVehicle = btn.vehicle
            actionDoor = btn.doorIndex
            actionIsPanel = btn.isPanel
            actionIsEngine = btn.isEngine
            actionIsGlass = btn.isGlass
            actionWheelIndex = btn.isWheel and btn.doorIndex or nil
            progress = 0
            isWorking = true
            setElementFrozen(localPlayer, true)
            setPedAnimation(localPlayer, "benchpress", "gym_bp_down", -1, true, false, false, false)
            triggerServerEvent("onPlayerStartDoorWork", resourceRoot, btn.vehicle, btn.doorIndex, btn.action, btn.isPanel, btn.isWheel, btn.isEngine)
            return
        end
    end
end)

-- ══════════════════════════════════════════════════════════
--  KEY HANDLERS
-- ══════════════════════════════════════════════════════════
bindKey("space", "down", function()
    if not P.active then return end

    -- Engine timing bars
    if P.panelKind == "engine" and P.stage == 1 then
        for i, bar in ipairs(P.timingBars) do
            if not bar.locked then
                if bar.value >= bar.zoneStart and bar.value <= bar.zoneEnd then
                    bar.locked = true; P.timingLocked = P.timingLocked + 1
                    playSoundFrontEnd(1)
                    P.flashType = 1; P.flashTimer = 20
                    spawnParticles(bar.x + bar.w / 2, bar.y + bar.h * (1 - bar.value / 100), 10, C.success, 45)
                    if P.timingLocked >= P.timingTotal then resetEngineStage2() end
                    return
                end
            end
        end
        failAndReset("هیچ میله‌ای توی ناحیه سبز نبود! از مرحله ۱ شروع کن")
        return
    end

    -- Engine oil pressure hold
    if P.panelKind == "engine" and P.stage == 2 then
        spaceHeld = true; return
    end

    -- Wheel seal
    if P.stage == 2 and P.panelKind == "wheel" then
        if P.hammerPos >= P.zoneStart and P.hammerPos <= P.zoneEnd then
            P.hammerHits = P.hammerHits + 1; P.flashType = 1; P.flashTimer = 30
            playSoundFrontEnd(1)
            P.hammerSpeed = min(140, P.hammerSpeed + 15)
            spawnParticles(P.panelX + 330, P.panelY + 260, 10, C.success, 50)
            if P.hammerHits >= P.hammerNeeded then resetWheelStage3() end
        else
            failAndReset("ضربه اشتباه! از مرحله ۱ شروع کن")
        end
        return
    end

    -- Standard hammer stage
    if P.stage == 2 and P.panelKind ~= "engine" then
        if P.hammerPos >= P.zoneStart and P.hammerPos <= P.zoneEnd then
            P.hammerHits = P.hammerHits + 1; P.flashType = 1; P.flashTimer = 30
            playSoundFrontEnd(1)
            P.hammerSpeed = min(140, P.hammerSpeed + 15)
            spawnParticles(P.panelX + 330, P.panelY + 260, 10, C.success, 50)
            if P.hammerHits >= P.hammerNeeded then resetStage3() end
        else
            failAndReset("ضربه اشتباه! از مرحله ۱ شروع کن")
        end
        return
    end

    -- Wheel inflate start
    if P.stage == 3 and P.panelKind == "wheel" then
        spaceHeld = true; airStarted = true
    end
end)

bindKey("space", "up", function()
    if not P.active then return end

    -- Engine oil release
    if P.panelKind == "engine" and P.stage == 2 then
        spaceHeld = false; return
    end

    -- Wheel inflate release
    if P.stage == 3 and P.panelKind == "wheel" then
        if not airStarted then spaceHeld = false; return end
        spaceHeld = false
        if P.airPressure < 15 then P.airPressure = 0; airStarted = false; return end
        local diff = abs(P.airPressure - P.airTarget)
        if diff <= 10 then
            P.flashType = 1; P.flashTimer = 40
            playSoundFrontEnd(1)
            spawnParticles(P.panelX + 330, P.panelY + 260, 15, C.air, 70)
            local v, d = P.vehicle, P.targetIndex
            closePanel()
            triggerServerEvent("onPlayerFinishDoorWork", resourceRoot, v, d, "repair", false, true)
        else
            failAndReset("فشار اشتباه! از مرحله ۱ شروع کن")
        end
    end
end)

-- ══════════════════════════════════════════════════════════
--  UPDATE LOOP
-- ══════════════════════════════════════════════════════════
addEventHandler("onClientPreRender", root, function(dt)
    local dtS = dt / 1000

    if P.active then
        -- Particles
        updateParticles(dtS)

        -- Shake decay
        if P.shakeTimer > 0 then
            P.shakeTimer = max(0, P.shakeTimer - dtS)
        end

        if P.panelKind == "engine" then
            if P.stage == 1 then
                for _, bar in ipairs(P.timingBars) do
                    if not bar.locked then
                        bar.value = bar.value + bar.dir * bar.speed * dtS
                        if bar.value >= 100 then bar.value = 100; bar.dir = -1
                        elseif bar.value <= 0 then bar.value = 0; bar.dir = 1 end
                    end
                end
            elseif P.stage == 2 then
                if spaceHeld then
                    P.oilPressure = P.oilPressure + P.oilSpeed * dtS
                else
                    P.oilPressure = P.oilPressure - P.oilSpeed * dtS * 0.6
                end
                P.oilPressure = clamp(P.oilPressure, 0, 100)
                if P.oilPressure >= P.oilZoneStart and P.oilPressure <= P.oilZoneEnd then
                    P.oilHoldTime = P.oilHoldTime + dt
                    if P.oilHoldTime >= P.oilRequired then
                        P.flashType = 1; P.flashTimer = 40
                        playSoundFrontEnd(1)
                        spawnParticles(P.panelX + PANEL_W / 2, P.panelY + 250, 20, C.success, 80)
                        resetEngineStage3()
                    end
                else
                    P.oilHoldTime = max(0, P.oilHoldTime - dt * 0.15)
                end
            elseif P.stage == 3 then
                for _, cyl in ipairs(P.cylinders) do
                    if cyl.flashTimer > 0 then cyl.flashTimer = cyl.flashTimer - 1 end
                end
            end
        else
            if P.stage == 2 then
                P.hammerPos = P.hammerPos + P.hammerDir * P.hammerSpeed * dtS
                if P.hammerPos >= 100 then P.hammerPos, P.hammerDir = 100, -1
                elseif P.hammerPos <= 0 then P.hammerPos, P.hammerDir = 0, 1 end
            elseif P.stage == 3 and P.panelKind == "wheel" then
                if spaceHeld then
                    P.airPressure = P.airPressure + P.airSpeed * dtS
                    if P.airPressure > 100 then P.airPressure = 100; P.airOvershoot = true end
                end
            end
        end

        -- Flash timer
        if P.flashTimer > 0 then
            P.flashTimer = P.flashTimer - 1
            if P.flashTimer <= 0 then P.flashType = 0 end
        end
    end

    -- Working progress
    if not isWorking then return end
    progress = progress + (dt / 25)
    if progress >= 100 then
        progress = 100
        isWorking = false
        setElementFrozen(localPlayer, false)
        setPedAnimation(localPlayer)
        triggerServerEvent("onPlayerFinishDoorWork", resourceRoot,
            actionVehicle, actionDoor, actionType, actionIsPanel,
            actionWheelIndex ~= nil, actionIsEngine, actionIsGlass)
        actionVehicle, actionDoor, actionType, actionIsPanel, actionWheelIndex, actionIsEngine, actionIsGlass = nil, nil, nil, false, nil, false, false
    end
end)

-- ══════════════════════════════════════════════════════════
--  DOOR HOLD / DROP EVENTS
-- ══════════════════════════════════════════════════════════
addEvent("onClientHoldDoor", true)
addEventHandler("onClientHoldDoor", resourceRoot, function(model, ox, oy, oz, rx, ry, rz)
    if heldDoorObject and isElement(heldDoorObject) then destroyElement(heldDoorObject) end
    heldDoorObject = createObject(model, 0, 0, 0)
    if heldDoorObject then
        setElementCollisionsEnabled(heldDoorObject, false)
        attachElements(heldDoorObject, localPlayer, ox, oy, oz, rx, ry, rz)
    end
end)

addEvent("onClientDropDoor", true)
addEventHandler("onClientDropDoor", resourceRoot, function()
    if heldDoorObject and isElement(heldDoorObject) then
        destroyElement(heldDoorObject)
        heldDoorObject = nil
    end
end)

bindKey("q", "down", function()
    if P.active then return end
    if heldDoorObject and isElement(heldDoorObject) then
        triggerServerEvent("onPlayerDropHeldDoor", resourceRoot)
    end
end)