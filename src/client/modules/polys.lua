Polys = {}

local CFG_POLY <const> = Config.Poly
local SCALE <const> = 10 ^ Config.Precision
local SAVE_DELAY <const> = Config.SaveDelay
local KVP_KEY <const> = 'polys'
local HEADER <const> = 6

local List = {}
local saveSerial = 0
local dirty = false

local function round(value)
    local rounded = math.floor(value * SCALE + 0.5) / SCALE
    if rounded == 0 then return 0.0 end

    return rounded
end

local function thicknessOf(value)
    return math.min(math.max(round(value), CFG_POLY.thickness_min), CFG_POLY.thickness_max)
end

local function vertexOf(coords)
    return vec3(round(coords.x), round(coords.y), round(coords.z))
end

local function defaultColor()
    local color = CFG_POLY.color

    return { color[1], color[2], color[3], color[4] }
end

local function save()
    dirty = false

    local rows = {}

    for i = 1, #List do
        local poly = List[i]
        local color = poly.color
        local vertices = poly.points
        local row = { poly.label, poly.thickness, color[1], color[2], color[3], color[4] }

        for j = 1, #vertices do
            local vertex = vertices[j]
            local at = HEADER + (j - 1) * 3
            row[at + 1] = vertex.x
            row[at + 2] = vertex.y
            row[at + 3] = vertex.z
        end

        rows[i] = row
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

function Polys.load()
    local raw = GetResourceKvpString(KVP_KEY)
    if not raw then return end

    local rows = json.decode(raw)
    if type(rows) ~= 'table' then return end

    for i = 1, #rows do
        local row = rows[i]
        local vertices, n = {}, 0

        for at = HEADER + 1, #row, 3 do
            n += 1
            vertices[n] = vec3(row[at], row[at + 1], row[at + 2])
        end

        List[i] = { label = row[1], thickness = row[2], color = { row[3], row[4], row[5], row[6] }, points = vertices }
    end
end

function Polys.flush()
    if dirty then save() end
end

---@return integer
function Polys.count()
    return #List
end

---@param index integer
---@return table?
function Polys.get(index)
    return List[index]
end

---@return integer?
function Polys.create()
    local index = #List + 1
    if index > CFG_POLY.limit then return nil end

    List[index] = { label = '', thickness = thicknessOf(CFG_POLY.thickness), color = defaultColor(), points = {} }
    schedule()

    return index
end

---@param index integer
function Polys.remove(index)
    local count = #List

    for i = index, count - 1 do
        List[i] = List[i + 1]
    end

    List[count] = nil
    schedule()
end

---@param index integer
---@param label string
---@param thickness number
---@param color integer[]
function Polys.update(index, label, thickness, color)
    local poly = List[index]
    poly.label = label
    poly.thickness = thicknessOf(thickness)
    poly.color = color
    schedule()
end

---@param index integer
---@param coords vector3
---@return integer?
function Polys.addVertex(index, coords)
    local vertices = List[index].points
    local vertex = #vertices + 1
    if vertex > CFG_POLY.vertices then return nil end

    vertices[vertex] = vertexOf(coords)
    schedule()

    return vertex
end

---@param index integer
---@param vertex integer
---@param coords vector3
function Polys.setVertex(index, vertex, coords)
    List[index].points[vertex] = vertexOf(coords)
    schedule()
end

---@param index integer
---@param vertex integer
function Polys.removeVertex(index, vertex)
    local vertices = List[index].points
    local count = #vertices

    for i = vertex, count - 1 do
        vertices[i] = vertices[i + 1]
    end

    vertices[count] = nil
    schedule()
end

---@param index integer
---@return boolean
function Polys.flatten(index)
    local vertices = List[index].points
    local count = #vertices
    if count == 0 then return false end

    local total = 0.0

    for i = 1, count do
        total += vertices[i].z
    end

    local z = round(total / count)

    for i = 1, count do
        local vertex = vertices[i]
        vertices[i] = vec3(vertex.x, vertex.y, z)
    end

    schedule()

    return true
end

---@param index integer
---@return table
function Polys.wire(index)
    local poly = List[index]
    local vertices = poly.points
    local list = {}

    for i = 1, #vertices do
        local vertex = vertices[i]
        list[i] = { x = vertex.x, y = vertex.y, z = vertex.z }
    end

    return { label = poly.label, thickness = poly.thickness, color = poly.color, points = list }
end

---@return table[]
function Polys.wireAll()
    local list = {}

    for i = 1, #List do
        list[i] = Polys.wire(i)
    end

    return list
end
