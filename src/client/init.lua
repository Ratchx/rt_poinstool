local CFG_COMMAND <const> = Config.Command
local CFG_KEY <const> = Config.Key
local CFG_LOCALE <const> = Config.Locale
local CFG_BLIP <const> = Config.Blip
local LABEL_LENGTH <const> = Config.LabelLength
local MODEL_LENGTH <const> = Config.Prop.length
local ADD_DELAY <const> = Config.AddDelay
local CHANNEL_MAX <const> = 255

local nextAddAt = 0

local function indexOf(data)
    local index = type(data) == 'table' and math.tointeger(data.index)
    if not index or not Points.get(index) then return nil end

    return index
end

local function indexesOf(data)
    if type(data) ~= 'table' or type(data.indexes) ~= 'table' then return nil end

    local list = data.indexes
    local count = #list
    if count == 0 or count > Points.count() then return nil end

    local removed = {}

    for i = 1, count do
        local index = math.tointeger(list[i])
        if not index or not Points.get(index) or removed[index] then return nil end

        removed[index] = true
    end

    return removed
end

local function polyOf(data)
    local index = type(data) == 'table' and math.tointeger(data.index)
    if not index or not Polys.get(index) then return nil end

    return index
end

local function vertexOf(data, poly)
    local vertex = math.tointeger(data.vertex)
    if not vertex or not Polys.get(poly).points[vertex] then return nil end

    return vertex
end

local function numberOf(value)
    if type(value) ~= 'number' or value ~= value or value == math.huge or value == -math.huge then return nil end

    return value
end

local function integerOf(value, max)
    local number = math.tointeger(value)
    if not number or number < 0 or number > max then return nil end

    return number
end

local function booleanOf(value)
    if type(value) ~= 'boolean' then return nil end

    return value
end

local function sizeOf(value)
    if type(value) ~= 'table' then return nil end

    local x, y, z = numberOf(value[1]), numberOf(value[2]), numberOf(value[3])
    if not (x and y and z) then return nil end

    return vec3(x, y, z)
end

local function tintOf(value)
    if type(value) ~= 'table' then return nil end

    local r, g, b, a = integerOf(value[1], CHANNEL_MAX), integerOf(value[2], CHANNEL_MAX), integerOf(value[3], CHANNEL_MAX), integerOf(value[4], CHANNEL_MAX)
    if not (r and g and b and a) then return nil end

    return { r, g, b, a }
end

local function labelOf(value)
    if type(value) ~= 'string' or value:find('%c') then return nil end

    local length = utf8.len(value)
    if not length or length > LABEL_LENGTH then return nil end

    return value
end

local function modelOf(value)
    if type(value) ~= 'string' or #value > MODEL_LENGTH or not value:find('^[%w_%-]*$') then return nil end

    return value
end

local function isProp(model)
    if model == '' then return true end

    local hash = joaat(model)

    return IsModelInCdimage(hash) and not IsModelAVehicle(hash) and not IsModelAPed(hash)
end

local function setVisible(value)
    Blips.setVisible(value)
    Walls.setVisible(value)

    return Marks.setVisible(value)
end

local function startPlace(poly)
    if setVisible(true) then Nui.visible(true) end

    Place.start(poly)
end

local function addPoint()
    local now = GetGameTimer()
    if now < nextAddAt then return end

    nextAddAt = now + ADD_DELAY

    local index = Points.add()

    if not index then
        Nui.full()
        return
    end

    Marks.add(index)
    if setVisible(true) then Nui.visible(true) end
    Nui.added(index)
end

local function teleport(point)
    local coords = point.coords

    RequestCollisionAtCoord(coords.x, coords.y, coords.z)
    SetPedCoordsKeepVehicle(cache.ped, coords.x, coords.y, coords.z)
    SetEntityHeading(cache.vehicle or cache.ped, point.heading)
end

local function changed(index)
    Marks.refresh(index)
    Blips.refresh(index)
end

RegisterNuiCallback('uiReady', function(_, cb)
    cb(1)
    Nui.ready()
end)

RegisterNuiCallback('close', function(_, cb)
    cb(1)
    Nui.close(true)
end)

RegisterNuiCallback('select', function(data, cb)
    cb(1)
    Marks.select(indexOf(data) or 0)
end)

RegisterNuiCallback('visible', function(data, cb)
    if type(data) ~= 'table' or type(data.value) ~= 'boolean' then return cb(0) end

    cb(1)
    setVisible(data.value)
end)

RegisterNuiCallback('update', function(data, cb)
    local index = indexOf(data)
    if not index then return cb(0) end

    local fields = {
        x = numberOf(data.x),
        y = numberOf(data.y),
        z = numberOf(data.z),
        heading = numberOf(data.h),
        radius = numberOf(data.r),
        label = labelOf(data.label),
        blip = booleanOf(data.blip),
        sprite = integerOf(data.sprite, CFG_BLIP.sprite_max),
        color = integerOf(data.color, CFG_BLIP.color_max),
        scale = numberOf(data.scale),
        area = booleanOf(data.area),
        size = sizeOf(data.size),
        tint = tintOf(data.tint),
    }

    if not (fields.x and fields.y and fields.z and fields.heading and fields.radius and fields.label)
        or not (fields.sprite and fields.color and fields.scale)
        or not (fields.size and fields.tint)
        or fields.blip == nil
        or fields.area == nil
    then
        return cb(0)
    end

    cb(1)
    Points.update(index, fields)
    changed(index)
end)

RegisterNuiCallback('model', function(data, cb)
    local index = indexOf(data)
    if not index then return cb(0) end

    local model = modelOf(data.model)
    if not model or not isProp(model) then return cb(0) end

    cb(1)
    Points.setModel(index, model)
    Marks.refresh(index)
end)

RegisterNuiCallback('ground', function(data, cb)
    local index = indexOf(data)
    if not index then return cb(0) end

    local z = Marks.groundOf(Points.get(index).coords)
    if not z then return cb(0) end

    Points.setZ(index, z)
    changed(index)
    cb(Points.wire(index))
end)

RegisterNuiCallback('here', function(data, cb)
    local index = indexOf(data)
    if not index then return cb(0) end

    Points.move(index)
    changed(index)
    cb(Points.wire(index))
end)

RegisterNuiCallback('teleport', function(data, cb)
    local index = indexOf(data)
    if not index then return cb(0) end

    cb(1)
    Nui.close(false)
    teleport(Points.get(index))
end)

RegisterNuiCallback('remove', function(data, cb)
    local removed = indexesOf(data)
    if not removed then return cb(0) end

    cb(1)
    Points.remove(removed)
    Marks.remove(removed)
    Blips.rebuild()
end)

RegisterNuiCallback('clear', function(_, cb)
    cb(1)
    Points.clear()
    Marks.clear()
    Blips.rebuild()
end)

RegisterNuiCallback('polyCreate', function(_, cb)
    local index = Polys.create()
    if not index then return cb(0) end

    cb({ index = index, poly = Polys.wire(index) })
end)

RegisterNuiCallback('polyUpdate', function(data, cb)
    local index = polyOf(data)
    if not index then return cb(0) end

    local label, thickness, color = labelOf(data.label), numberOf(data.thickness), tintOf(data.color)
    if not (label and thickness and color) then return cb(0) end

    cb(1)
    Polys.update(index, label, thickness, color)
    Walls.refresh(index)
end)

RegisterNuiCallback('polyRemove', function(data, cb)
    local index = polyOf(data)
    if not index then return cb(0) end

    cb(1)
    Polys.remove(index)
    Walls.remove(index)
    Place.onPolyRemoved(index)
end)

RegisterNuiCallback('polySelect', function(data, cb)
    local index = polyOf(data) or 0
    local vertex = index > 0 and vertexOf(data, index) or 0

    cb(1)
    Walls.select(index, vertex)
    Place.setTarget(index)
end)

RegisterNuiCallback('polyFlatten', function(data, cb)
    local index = polyOf(data)
    if not index or not Polys.flatten(index) then return cb(0) end

    Walls.refresh(index)
    cb(Polys.wire(index))
end)

RegisterNuiCallback('vertexUpdate', function(data, cb)
    local index = polyOf(data)
    local vertex = index and vertexOf(data, index)
    if not vertex then return cb(0) end

    local x, y, z = numberOf(data.x), numberOf(data.y), numberOf(data.z)
    if not (x and y and z) then return cb(0) end

    cb(1)
    Polys.setVertex(index, vertex, vec3(x, y, z))
    Walls.refresh(index)
end)

RegisterNuiCallback('vertexRemove', function(data, cb)
    local index = polyOf(data)
    local vertex = index and vertexOf(data, index)
    if not vertex then return cb(0) end

    cb(1)
    Polys.removeVertex(index, vertex)
    Walls.refresh(index)
end)

RegisterNuiCallback('place', function(data, cb)
    cb(1)
    Nui.close(false)
    startPlace(polyOf(data) or 0)
end)

RegisterCommand(CFG_COMMAND.add, function()
    addPoint()
end, false)

RegisterCommand(CFG_COMMAND.menu, function()
    Place.stop()
    Nui.open()
end, false)

RegisterCommand(CFG_COMMAND.place, function()
    if Place.isActive() then return Place.stop() end

    startPlace()
end, false)

RegisterCommand(CFG_COMMAND.undo, function()
    Place.undo()
end, false)

RegisterKeyMapping(CFG_COMMAND.add, CFG_LOCALE.key_add, 'keyboard', CFG_KEY.add)
RegisterKeyMapping(CFG_COMMAND.menu, CFG_LOCALE.key_menu, 'keyboard', CFG_KEY.menu)
RegisterKeyMapping(CFG_COMMAND.place, CFG_LOCALE.key_place, 'keyboard', CFG_KEY.place)
RegisterKeyMapping(CFG_COMMAND.undo, CFG_LOCALE.key_undo, 'keyboard', CFG_KEY.undo)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end

    Place.stop()
    Points.flush()
    Polys.flush()
    Marks.teardown()
    Blips.teardown()
    Walls.teardown()
    Nui.close(false)
end)

Points.load()
Polys.load()
Marks.build()
Blips.build()
Walls.build()
