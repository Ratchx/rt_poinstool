Blips = {}

local CFG_LOCALE <const> = Config.Locale
local AREA_ALPHA <const> = Config.Blip.area_alpha

local Icons = {}
local Areas = {}
local visible = Config.Visible

local function nameOf(index, point)
    local label = point.label
    if label == '' or label:find('[\128-\255]') then return CFG_LOCALE.blip_name:format(index) end

    return label
end

local function create(index)
    local point = Points.get(index)
    local coords = point.coords

    if point.blip then
        local icon = AddBlipForCoord(coords.x, coords.y, coords.z)
        SetBlipSprite(icon, point.sprite)
        SetBlipColour(icon, point.color)
        SetBlipScale(icon, point.scale)
        SetBlipAsShortRange(icon, false)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(nameOf(index, point))
        EndTextCommandSetBlipName(icon)
        Icons[index] = icon
    end

    if point.area then
        local area = AddBlipForRadius(coords.x, coords.y, coords.z, point.radius)
        SetBlipColour(area, point.color)
        SetBlipAlpha(area, AREA_ALPHA)
        Areas[index] = area
    end
end

local function destroy(index)
    local icon = Icons[index]
    if icon then RemoveBlip(icon) end

    local area = Areas[index]
    if area then RemoveBlip(area) end

    Icons[index] = nil
    Areas[index] = nil
end

local function createAll()
    for i = 1, Points.count() do
        create(i)
    end
end

local function destroyAll()
    for _, icon in pairs(Icons) do
        RemoveBlip(icon)
    end

    for _, area in pairs(Areas) do
        RemoveBlip(area)
    end

    Icons = {}
    Areas = {}
end

---@param value boolean
function Blips.setVisible(value)
    if value == visible then return end

    visible = value

    if value then
        createAll()
    else
        destroyAll()
    end
end

function Blips.build()
    if visible then createAll() end
end

---@param index integer
function Blips.refresh(index)
    if not visible then return end

    destroy(index)
    create(index)
end

function Blips.rebuild()
    if not visible then return end

    destroyAll()
    createAll()
end

function Blips.teardown()
    destroyAll()
end
