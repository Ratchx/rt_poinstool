Place = {}

local PLACE_DISTANCE <const> = Config.Place.distance
local POINT_LIFT <const> = vec3(0.0, 0.0, Config.Place.point_lift)
local PROBE_FLAGS <const> = Config.Place.flags
local PREVIEW <const> = Config.Draw.line
local VERTEX_LIMIT <const> = Config.Poly.vertices
local PROBE_OPTIONS <const> = 7
local PROBE_PENDING <const> = 1
local ROTATION_ORDER <const> = 2
local FACE_CAMERA <const> = 180.0
local PAD_PLAYER <const> = 0
local PAD_FRONTEND <const> = 2
local CONTROL_ATTACK <const> = 24
local CONTROL_AIM <const> = 25
local CONTROL_PAUSE <const> = 200
local CONTROL_LOOK_X <const> = 1
local CONTROL_LOOK_Y <const> = 2
local CONTROL_CURSOR_ACCEPT <const> = 237
local CONTROL_CURSOR_CANCEL <const> = 238
local BLOCKED_CONTROLS <const> = { 24, 25, 37, 140, 141, 142, 257, 263, 264, 200 }
local PREVIEW_HEIGHT <const> = vec3(0.0, 0.0, 1.5)
local PREVIEW_DOT <const> = 0.12
local MARKER_SPHERE <const> = 28
local DisableControlAction <const> = DisableControlAction
local IsDisabledControlPressed <const> = IsDisabledControlPressed
local IsDisabledControlJustPressed <const> = IsDisabledControlJustPressed
local SetMouseCursorThisFrame <const> = SetMouseCursorThisFrame
local GetNuiCursorPosition <const> = GetNuiCursorPosition
local GetActualScreenResolution <const> = GetActualScreenResolution
local GetWorldCoordFromScreenCoord <const> = GetWorldCoordFromScreenCoord
local GetFinalRenderedCamRot <const> = GetFinalRenderedCamRot
local StartShapeTestLosProbe <const> = StartShapeTestLosProbe
local GetShapeTestResult <const> = GetShapeTestResult
local DrawLine <const> = DrawLine
local DrawMarker <const> = DrawMarker

local HistoryPoly = {}
local HistoryIndex = {}
local historyCount = 0
local active = false
local target = 0
local probe = nil
local hover = nil

local function clicked()
    return IsDisabledControlJustPressed(PAD_PLAYER, CONTROL_ATTACK) or IsDisabledControlJustPressed(PAD_FRONTEND, CONTROL_CURSOR_ACCEPT)
end

local function looking()
    return IsDisabledControlPressed(PAD_PLAYER, CONTROL_AIM) or IsDisabledControlPressed(PAD_FRONTEND, CONTROL_CURSOR_CANCEL)
end

local function didHit(value)
    return value == true or value == 1
end

local function rayFromCursor()
    local width, height = GetActualScreenResolution()
    local x, y = GetNuiCursorPosition()

    return GetWorldCoordFromScreenCoord(x / width, y / height)
end

local function updateHover()
    if probe then
        local status, hit, coords = GetShapeTestResult(probe)
        if status == PROBE_PENDING then return end

        probe = nil
        hover = didHit(hit) and coords or nil
    end

    local origin, direction = rayFromCursor()
    local finish = origin + direction * PLACE_DISTANCE

    probe = StartShapeTestLosProbe(origin.x, origin.y, origin.z, finish.x, finish.y, finish.z, PROBE_FLAGS, cache.ped, PROBE_OPTIONS)
end

local function drawPreview()
    if not hover then return end

    local red, green, blue, alpha = PREVIEW[1], PREVIEW[2], PREVIEW[3], PREVIEW[4]
    local top = hover + PREVIEW_HEIGHT

    DrawLine(hover.x, hover.y, hover.z, top.x, top.y, top.z, red, green, blue, alpha)
    DrawMarker(MARKER_SPHERE, hover.x, hover.y, hover.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, PREVIEW_DOT, PREVIEW_DOT, PREVIEW_DOT, red, green, blue, alpha, false, false, 2, false, nil, nil, false)

    if target == 0 then return end

    local vertices = Polys.get(target).points
    local count = #vertices
    if count == 0 then return end

    local last = vertices[count]
    DrawLine(last.x, last.y, last.z, hover.x, hover.y, hover.z, red, green, blue, alpha)

    if count < 2 then return end

    local first = vertices[1]
    DrawLine(hover.x, hover.y, hover.z, first.x, first.y, first.z, red, green, blue, alpha)
end

local function remember(poly, index)
    historyCount += 1
    HistoryPoly[historyCount] = poly
    HistoryIndex[historyCount] = index
end

local function forget()
    HistoryPoly = {}
    HistoryIndex = {}
    historyCount = 0
end

local function placePoint(heading)
    local index = Points.addAt(hover + POINT_LIFT, heading)
    if not index then return Nui.full() end

    Marks.add(index)
    Nui.added(index)
    remember(0, index)
end

local function placeVertex()
    local vertex = Polys.addVertex(target, hover)
    if not vertex then return Nui.toast('vertex_full', VERTEX_LIMIT) end

    Walls.refresh(target)
    Nui.poly(target, vertex)
    remember(target, vertex)
end

local function place()
    if target > 0 then return placeVertex() end

    local yaw = GetFinalRenderedCamRot(ROTATION_ORDER).z
    placePoint(math.floor(yaw + FACE_CAMERA + 0.5) % 360)
end

local function run()
    CreateThread(function()
        while active do
            for i = 1, #BLOCKED_CONTROLS do
                DisableControlAction(PAD_PLAYER, BLOCKED_CONTROLS[i], true)
            end

            if IsDisabledControlJustPressed(PAD_PLAYER, CONTROL_PAUSE) then
                Place.stop()
            elseif not looking() then
                DisableControlAction(PAD_PLAYER, CONTROL_LOOK_X, true)
                DisableControlAction(PAD_PLAYER, CONTROL_LOOK_Y, true)
                SetMouseCursorThisFrame()
                updateHover()
                drawPreview()

                if clicked() then
                    if hover then
                        place()
                    else
                        Nui.toast('place_miss')
                    end
                end
            end

            Wait(0)
        end
    end)
end

---@return boolean
function Place.isActive()
    return active
end

---@param poly integer?
function Place.start(poly)
    if active then return end

    if poly then target = poly end

    active = true
    forget()
    Nui.place(true, target)
    run()
end

function Place.stop()
    if not active then return end

    active = false
    probe = nil
    hover = nil
    forget()
    Nui.place(false, target)
end

---@param poly integer
function Place.setTarget(poly)
    target = poly
    if active then Nui.place(true, target) end
end

---@param poly integer
function Place.onPolyRemoved(poly)
    if target == poly then
        target = 0
    elseif target > poly then
        target -= 1
    end
end

function Place.undo()
    if not active or historyCount == 0 then return end

    local poly, index = HistoryPoly[historyCount], HistoryIndex[historyCount]

    HistoryPoly[historyCount] = nil
    HistoryIndex[historyCount] = nil
    historyCount -= 1

    if poly == 0 then
        local removed = { [index] = true }
        Points.remove(removed)
        Marks.remove(removed)
        Blips.rebuild()
        Nui.removed(index)
    else
        Polys.removeVertex(poly, index)
        Walls.refresh(poly)
        Nui.poly(poly, 0)
    end

    Nui.toast('undone')
end
