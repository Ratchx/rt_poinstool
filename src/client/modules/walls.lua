Walls = {}

local DRAW_DISTANCE <const> = Config.Draw.distance
local SHOW_LABEL <const> = Config.Draw.label
local LINE <const> = Config.Draw.line
local SELECTED <const> = Config.Draw.selected
local DOT_SIZE <const> = Config.Draw.dot
local EDGE_ALPHA <const> = 225
local MARKER_SPHERE <const> = 28
local SELECTED_DOT <const> = 3.0
local SPAN_SLACK <const> = 50.0
local DrawPoly <const> = DrawPoly
local DrawLine <const> = DrawLine
local DrawMarker <const> = DrawMarker
local SetTextScale <const> = SetTextScale
local SetTextFont <const> = SetTextFont
local SetTextCentre <const> = SetTextCentre
local SetTextColour <const> = SetTextColour
local SetTextOutline <const> = SetTextOutline
local BeginTextCommandDisplayText <const> = BeginTextCommandDisplayText
local AddTextComponentSubstringPlayerName <const> = AddTextComponentSubstringPlayerName
local SetDrawOrigin <const> = SetDrawOrigin
local EndTextCommandDisplayText <const> = EndTextCommandDisplayText
local ClearDrawOrigin <const> = ClearDrawOrigin

local Shapes = {}
local selectedPoly = 0
local selectedVertex = 0
local visible = Config.Visible

local function drawNumber(x, y, z, text)
    SetTextScale(0.0, 0.32)
    SetTextFont(0)
    SetTextCentre(true)
    SetTextColour(255, 255, 255, 235)
    SetTextOutline()
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(text)
    SetDrawOrigin(x, y, z, 0)
    EndTextCommandDisplayText(0.0, 0.0)
    ClearDrawOrigin()
end

local function draw(self)
    local vertices = self.vertices
    local count = #vertices
    local half = self.half
    local color = self.color
    local red, green, blue, alpha = color[1], color[2], color[3], color[4]
    local edges = count > 2 and count or count - 1
    local mine = self.index == selectedPoly

    for i = 1, edges do
        local a = vertices[i]
        local b = vertices[i % count + 1]
        local ax, ay, az = a.x, a.y, a.z
        local bx, by, bz = b.x, b.y, b.z
        local aTop, aBottom, bTop, bBottom = az + half, az - half, bz + half, bz - half

        DrawPoly(ax, ay, aTop, ax, ay, aBottom, bx, by, bTop, red, green, blue, alpha)
        DrawPoly(bx, by, bTop, ax, ay, aBottom, ax, ay, aTop, red, green, blue, alpha)
        DrawPoly(ax, ay, aBottom, bx, by, bTop, bx, by, bBottom, red, green, blue, alpha)
        DrawPoly(bx, by, bBottom, bx, by, bTop, ax, ay, aBottom, red, green, blue, alpha)
        DrawLine(ax, ay, aTop, bx, by, bTop, red, green, blue, EDGE_ALPHA)
        DrawLine(ax, ay, aBottom, bx, by, bBottom, red, green, blue, EDGE_ALPHA)
    end

    for i = 1, count do
        local vertex = vertices[i]
        local x, y, z = vertex.x, vertex.y, vertex.z
        local picked = mine and i == selectedVertex
        local dot = picked and DOT_SIZE * SELECTED_DOT or DOT_SIZE
        local tint = picked and SELECTED or LINE

        DrawLine(x, y, z - half, x, y, z + half, red, green, blue, EDGE_ALPHA)
        DrawMarker(MARKER_SPHERE, x, y, z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, dot, dot, dot, tint[1], tint[2], tint[3], tint[4], false, false, 2, false, nil, nil, false)

        if SHOW_LABEL then drawNumber(x, y, z + half, self.numbers[i]) end
    end
end

local function centerOf(vertices)
    local count = #vertices
    local sumX, sumY, sumZ = 0.0, 0.0, 0.0

    for i = 1, count do
        local vertex = vertices[i]
        sumX += vertex.x
        sumY += vertex.y
        sumZ += vertex.z
    end

    return vec3(sumX / count, sumY / count, sumZ / count)
end

local function numbersOf(count)
    local numbers = {}

    for i = 1, count do
        numbers[i] = tostring(i)
    end

    return numbers
end

local function patch(shape, index, poly)
    local vertices = poly.points

    shape.index = index
    shape.vertices = vertices
    shape.half = poly.thickness * 0.5
    shape.color = poly.color
    shape.numbers = numbersOf(#vertices)
end

local function farthest(vertices, center)
    local reach = 0.0

    for i = 1, #vertices do
        reach = math.max(reach, #(vertices[i] - center))
    end

    return reach
end

local function build(index)
    local poly = Polys.get(index)
    local vertices = poly.points
    if #vertices == 0 then return end

    local center = centerOf(vertices)
    local span = farthest(vertices, center) + SPAN_SLACK
    local shape = {
        coords = center,
        distance = DRAW_DISTANCE + span,
        span = span,
        nearby = draw,
    }

    patch(shape, index, poly)
    Shapes[index] = lib.points.new(shape)
end

local function drop(index)
    local shape = Shapes[index]
    if not shape then return end

    shape:remove()
    Shapes[index] = nil
end

local function buildAll()
    for i = 1, Polys.count() do
        build(i)
    end
end

local function dropAll()
    for _, shape in pairs(Shapes) do
        shape:remove()
    end

    Shapes = {}
end

---@param value boolean
function Walls.setVisible(value)
    if value == visible then return end

    visible = value

    if value then
        buildAll()
    else
        dropAll()
    end
end

function Walls.build()
    if visible then buildAll() end
end

---@param poly integer
---@param vertex integer
function Walls.select(poly, vertex)
    selectedPoly = poly
    selectedVertex = vertex
end

---@param index integer
function Walls.refresh(index)
    if not visible then return end

    local shape = Shapes[index]
    local poly = Polys.get(index)
    local vertices = poly.points

    if not shape or #vertices == 0 then
        drop(index)
        return build(index)
    end

    local needed = farthest(vertices, shape.coords)

    if needed > shape.span then
        drop(index)
        return build(index)
    end

    patch(shape, index, poly)
    shape.radius = DRAW_DISTANCE + needed
end

---@param index integer
function Walls.remove(index)
    if selectedPoly == index then
        selectedPoly = 0
        selectedVertex = 0
    elseif selectedPoly > index then
        selectedPoly -= 1
    end

    if not visible then return end

    drop(index)

    local count = Polys.count() + 1

    for i = index + 1, count do
        local shape = Shapes[i]
        Shapes[i] = nil

        if shape then
            shape.index = i - 1
            Shapes[i - 1] = shape
        end
    end
end

function Walls.teardown()
    dropAll()
end
