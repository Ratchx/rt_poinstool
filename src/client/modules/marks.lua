Marks = {}

local CFG_LOCALE <const> = Config.Locale
local DRAW_DISTANCE <const> = Config.Draw.distance
local HEADING_LENGTH <const> = Config.Draw.heading
local DOT_SIZE <const> = Config.Draw.dot
local SHOW_LABEL <const> = Config.Draw.label
local SHOW_SPHERE <const> = Config.Draw.sphere
local RING <const> = Config.Draw.ring
local SELECTED <const> = Config.Draw.selected
local RING_SEGMENTS <const> = Config.Draw.segments
local LINE <const> = Config.Draw.line
local SPHERE <const> = Config.Draw.sphere_color
local PROP_TIMEOUT <const> = Config.Prop.timeout
local PROP_COLLISION <const> = Config.Prop.collision
local MARKER_CYLINDER <const> = 1
local MARKER_SPHERE <const> = 28
local GROUND_PROBE <const> = 0.5
local GROUND_FALLBACK <const> = 1.0
local LABEL_LIFT <const> = 0.35
local RING_LIFT <const> = 0.03
local ARROW_BACK <const> = 0.3
local ARROW_SIDE <const> = 0.15
local HasModelLoaded <const> = HasModelLoaded
local GetGameTimer <const> = GetGameTimer
local DrawLine <const> = DrawLine

local Shapes = {}
local RingCos = {}
local RingSin = {}
local selected = 0
local visible = Config.Visible

for i = 0, RING_SEGMENTS do
    local angle = i / RING_SEGMENTS * math.pi * 2.0
    RingCos[i] = math.cos(angle)
    RingSin[i] = math.sin(angle)
end

local function hashOf(model)
    if model == '' then return 0 end

    return joaat(model)
end

local function groundOrFallback(coords)
    return Marks.groundOf(coords) or coords.z - GROUND_FALLBACK
end

local function textOf(index, point)
    local label = point.label
    if label == '' or label:find('[\128-\255]') then return CFG_LOCALE.label:format(index, point.radius) end

    return CFG_LOCALE.label_named:format(index, point.radius, label)
end

local function loadModel(hash)
    if HasModelLoaded(hash) then return true end

    RequestModel(hash)

    local deadline = GetGameTimer() + PROP_TIMEOUT

    while not HasModelLoaded(hash) do
        if GetGameTimer() > deadline then return false end

        Wait(0)
    end

    return true
end

local function deleteProp(shape)
    shape.serial += 1

    local prop = shape.prop
    if not prop then return end

    shape.prop = nil
    if DoesEntityExist(prop) then DeleteEntity(prop) end
end

local function spawnProp(shape)
    local hash = shape.hash
    if hash == 0 or shape.prop then return end

    shape.serial += 1
    local serial = shape.serial

    CreateThread(function()
        local loaded = loadModel(hash)

        if not loaded or serial ~= shape.serial then
            SetModelAsNoLongerNeeded(hash)
            return
        end

        local coords = shape.coords
        local prop = CreateObjectNoOffset(hash, coords.x, coords.y, coords.z, false, false, false)

        SetModelAsNoLongerNeeded(hash)
        SetEntityRotation(prop, 0.0, 0.0, shape.heading, 2, false)
        FreezeEntityPosition(prop, true)
        SetEntityCollision(prop, PROP_COLLISION, PROP_COLLISION)
        shape.prop = prop
    end)
end

local function drawLabel(x, y, z, text)
    SetTextScale(0.0, 0.3)
    SetTextFont(0)
    SetTextCentre(true)
    SetTextColour(255, 255, 255, 230)
    SetTextOutline()
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(text)
    SetDrawOrigin(x, y, z, 0)
    EndTextCommandDisplayText(0.0, 0.0)
    ClearDrawOrigin()
end

local function draw(self)
    local coords = self.coords
    local x, y, z = coords.x, coords.y, coords.z
    local ground = self.ground
    local reach = self.reach
    local size = self.size
    local tint = self.tint
    local ring = self.index == selected and SELECTED or RING
    local red, green, blue, alpha = ring[1], ring[2], ring[3], ring[4]
    local lift = ground + RING_LIFT
    local fromX, fromY = x + reach, y

    for i = 1, RING_SEGMENTS do
        local toX, toY = x + RingCos[i] * reach, y + RingSin[i] * reach
        DrawLine(fromX, fromY, lift, toX, toY, lift, red, green, blue, alpha)
        fromX, fromY = toX, toY
    end

    if tint[4] > 0 then
        DrawMarker(MARKER_CYLINDER, x, y, ground, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, size.x, size.y, size.z, tint[1], tint[2], tint[3], tint[4], false, false, 2, false, nil, nil, false)
    end

    if SHOW_SPHERE then
        DrawMarker(MARKER_SPHERE, x, y, z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, reach, reach, reach, SPHERE[1], SPHERE[2], SPHERE[3], SPHERE[4], false, false, 2, false, nil, nil, false)
    end

    DrawMarker(MARKER_SPHERE, x, y, z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, DOT_SIZE, DOT_SIZE, DOT_SIZE, LINE[1], LINE[2], LINE[3], LINE[4], false, false, 2, false, nil, nil, false)
    DrawLine(x, y, ground, x, y, z, LINE[1], LINE[2], LINE[3], LINE[4])
    local tipX, tipY = x + self.dx, y + self.dy

    DrawLine(x, y, z, tipX, tipY, z, LINE[1], LINE[2], LINE[3], LINE[4])
    DrawLine(tipX, tipY, z, x + self.leftX, y + self.leftY, z, LINE[1], LINE[2], LINE[3], LINE[4])
    DrawLine(tipX, tipY, z, x + self.rightX, y + self.rightY, z, LINE[1], LINE[2], LINE[3], LINE[4])

    if SHOW_LABEL then drawLabel(x, y, z + LABEL_LIFT, self.text) end
end

local function enter(self)
    self.near = true
    self.ground = groundOrFallback(self.coords)
    spawnProp(self)
end

local function leave(self)
    self.near = false
    deleteProp(self)
end

local function patch(shape, index, point)
    local radius = point.radius
    local heading = point.heading
    local angle = math.rad(heading)

    shape.radius = DRAW_DISTANCE + radius
    shape.index = index
    shape.reach = radius
    shape.size = point.size
    shape.tint = point.tint
    shape.heading = heading
    local forwardX, forwardY = -math.sin(angle), math.cos(angle)
    local backX, backY = forwardX * (HEADING_LENGTH - ARROW_BACK), forwardY * (HEADING_LENGTH - ARROW_BACK)
    local sideX, sideY = forwardY * ARROW_SIDE, -forwardX * ARROW_SIDE

    shape.dx = forwardX * HEADING_LENGTH
    shape.dy = forwardY * HEADING_LENGTH
    shape.leftX = backX - sideX
    shape.leftY = backY - sideY
    shape.rightX = backX + sideX
    shape.rightY = backY + sideY
    shape.text = textOf(index, point)

    if shape.prop then SetEntityRotation(shape.prop, 0.0, 0.0, heading, 2, false) end
end

local function carry(from, to)
    local prop = from.prop

    to.hash = from.hash
    from.serial += 1
    from.prop = nil

    if not prop then return end

    local coords = to.coords
    SetEntityCoordsNoOffset(prop, coords.x, coords.y, coords.z, false, false, false)
    to.prop = prop
end

local function remodel(shape, point)
    local hash = hashOf(point.model)
    if hash == shape.hash then return end

    deleteProp(shape)
    shape.hash = hash

    if shape.near then spawnProp(shape) end
end

local function build(index, previous)
    local point = Points.get(index)
    local shape = {
        coords = point.coords,
        distance = DRAW_DISTANCE + point.radius,
        ground = groundOrFallback(point.coords),
        hash = hashOf(point.model),
        serial = 0,
        near = false,
        onEnter = enter,
        onExit = leave,
        nearby = draw,
    }

    if previous then carry(previous, shape) end

    patch(shape, index, point)
    Shapes[index] = lib.points.new(shape)
end

local function drop(shape)
    deleteProp(shape)
    shape:remove()
end

local function buildAll()
    for i = 1, Points.count() do
        build(i)
    end
end

local function dropAll()
    for i = 1, #Shapes do
        drop(Shapes[i])
    end

    Shapes = {}
end

---@param coords vector3
---@return number?
function Marks.groundOf(coords)
    local found, z = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z + GROUND_PROBE, false)
    if found then return z end
end

---@return boolean
function Marks.isVisible()
    return visible
end

---@param value boolean
---@return boolean changed
function Marks.setVisible(value)
    if value == visible then return false end

    visible = value

    if value then
        buildAll()
    else
        dropAll()
    end

    return true
end

---@param index integer
function Marks.select(index)
    selected = index
end

function Marks.build()
    if visible then buildAll() end
end

---@param index integer
function Marks.add(index)
    if visible then build(index) end
end

---@param index integer
function Marks.refresh(index)
    if not visible then return end

    local shape = Shapes[index]
    local point = Points.get(index)
    local from, to = shape.coords, point.coords

    if from.x == to.x and from.y == to.y and from.z == to.z then
        patch(shape, index, point)
    else
        shape:remove()
        build(index, shape)
        shape = Shapes[index]
    end

    remodel(shape, point)
end

local function shiftSelected(removed)
    if selected == 0 then return end

    if removed[selected] then
        selected = 0
        return
    end

    local shift = 0

    for i = 1, selected - 1 do
        if removed[i] then shift += 1 end
    end

    selected -= shift
end

---@param removed table<integer, true>
function Marks.remove(removed)
    shiftSelected(removed)

    if not visible then return end

    local count = #Shapes
    local kept = 0

    for i = 1, count do
        local shape = Shapes[i]

        if removed[i] then
            drop(shape)
        else
            kept += 1
            Shapes[kept] = shape
            if kept ~= i then patch(shape, kept, Points.get(kept)) end
        end
    end

    for i = kept + 1, count do
        Shapes[i] = nil
    end
end

function Marks.clear()
    selected = 0
    dropAll()
end

function Marks.teardown()
    dropAll()
end
