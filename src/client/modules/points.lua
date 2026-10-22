Points = {}

local CFG_RADIUS <const> = Config.Radius
local CFG_BLIP <const> = Config.Blip
local USE_VEHICLE <const> = Config.Capture.vehicle
local SCALE <const> = 10 ^ Config.Precision
local LIMIT <const> = Config.Limit
local SAVE_DELAY <const> = Config.SaveDelay
local KVP_KEY <const> = 'points'

local List = {}
local saveSerial = 0
local dirty = false

local function round(value)
    local rounded = math.floor(value * SCALE + 0.5) / SCALE
    if rounded == 0 then return 0.0 end

    return rounded
end

local function headingOf(value)
    local heading = round(value % 360.0)
    if heading >= 360.0 then return 0.0 end

    return heading
end

local function radiusOf(value)
    return math.min(math.max(round(value), CFG_RADIUS.min), CFG_RADIUS.max)
end

local function blipScaleOf(value)
    return math.min(math.max(round(value), CFG_BLIP.scale_min), CFG_BLIP.scale_max)
end

local function capture()
    local entity = USE_VEHICLE and cache.vehicle or cache.ped
    local coords = GetEntityCoords(entity, false)

    return vec3(round(coords.x), round(coords.y), round(coords.z)), headingOf(GetEntityHeading(entity))
end

local function save()
    dirty = false

    local rows = {}

    for i = 1, #List do
        local point = List[i]
        local coords = point.coords
        rows[i] = {
            coords.x, coords.y, coords.z, point.heading, point.radius, point.label,
            point.model, point.blip, point.sprite, point.color, point.scale, point.area,
        }
    end

    SetResourceKvp(KVP_KEY, json.encode(rows))
end

local function schedule()
    dirty = true
    saveSerial += 1
    local mine = saveSerial

    SetTimeout(SAVE_DELAY, function()
        if mine ~= saveSerial then return end

        save()
    end)
end

function Points.load()
    local raw = GetResourceKvpString(KVP_KEY)
    if not raw then return end

    local rows = json.decode(raw)
    if type(rows) ~= 'table' then return end

    for i = 1, #rows do
        local row = rows[i]
        List[i] = {
            coords = vec3(row[1], row[2], row[3]),
            heading = row[4],
            radius = row[5],
            label = row[6] or '',
            model = row[7] or '',
            blip = row[8] == true,
            sprite = row[9] or CFG_BLIP.sprite,
            color = row[10] or CFG_BLIP.color,
            scale = row[11] or CFG_BLIP.scale,
            area = row[12] == true,
        }
    end
end

function Points.flush()
    if dirty then save() end
end

---@return integer
function Points.count()
    return #List
end

---@param index integer
---@return table?
function Points.get(index)
    return List[index]
end

---@return integer?
function Points.add()
    local index = #List + 1
    if index > LIMIT then return nil end

    local coords, heading = capture()
    List[index] = {
        coords = coords,
        heading = heading,
        radius = radiusOf(CFG_RADIUS.default),
        label = '',
        model = '',
        blip = false,
        sprite = CFG_BLIP.sprite,
        color = CFG_BLIP.color,
        scale = blipScaleOf(CFG_BLIP.scale),
        area = false,
    }
    schedule()

    return index
end

---@param index integer
---@param fields { x: number, y: number, z: number, heading: number, radius: number, label: string, blip: boolean, sprite: integer, color: integer, scale: number, area: boolean }
function Points.update(index, fields)
    local point = List[index]
    point.coords = vec3(round(fields.x), round(fields.y), round(fields.z))
    point.heading = headingOf(fields.heading)
    point.radius = radiusOf(fields.radius)
    point.label = fields.label
    point.blip = fields.blip
    point.sprite = fields.sprite
    point.color = fields.color
    point.scale = blipScaleOf(fields.scale)
    point.area = fields.area
    schedule()
end

---@param index integer
---@param model string
function Points.setModel(index, model)
    List[index].model = model
    schedule()
end

---@param index integer
---@param z number
function Points.setZ(index, z)
    local point = List[index]
    local coords = point.coords
    point.coords = vec3(coords.x, coords.y, round(z))
    schedule()
end

---@param index integer
function Points.move(index)
    local point = List[index]
    point.coords, point.heading = capture()
    schedule()
end

---@param index integer
function Points.remove(index)
    local count = #List

    for i = index, count - 1 do
        List[i] = List[i + 1]
    end

    List[count] = nil
    schedule()
end

function Points.clear()
    List = {}
    schedule()
end

---@param index integer
---@return table
function Points.wire(index)
    local point = List[index]
    local coords = point.coords

    return {
        x = coords.x,
        y = coords.y,
        z = coords.z,
        h = point.heading,
        r = point.radius,
        label = point.label,
        model = point.model,
        blip = point.blip,
        sprite = point.sprite,
        color = point.color,
        scale = point.scale,
        area = point.area,
    }
end

---@return table[]
function Points.wireAll()
    local list = {}

    for i = 1, #List do
        list[i] = Points.wire(i)
    end

    return list
end
