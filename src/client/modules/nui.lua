Nui = {}

local CFG_COMMAND <const> = Config.Command
local CFG_KEY <const> = Config.Key
local CFG_LOCALE <const> = Config.Locale
local CFG_RADIUS <const> = Config.Radius
local CFG_NUI <const> = Config.Nui
local PRECISION <const> = Config.Precision
local LIMIT <const> = Config.Limit
local LABEL_LENGTH <const> = Config.LabelLength
local MODEL_LENGTH <const> = Config.Prop.length
local CFG_BLIP <const> = Config.Blip
local CFG_MARKER <const> = Config.Marker

local uiReady = false
local opened = false

local function send(action, payload)
    if not uiReady then return end

    SendNUIMessage({ action = action, payload = payload })
end

local function keyOf(command, fallback)
    local label = GetControlInstructionalButton(0, joaat(command) | 0x80000000, true)

    return type(label) == 'string' and label:match('^t_(.+)$') or fallback
end

local function keysOf()
    return {
        add = keyOf(CFG_COMMAND.add, CFG_KEY.add),
        menu = keyOf(CFG_COMMAND.menu, CFG_KEY.menu),
    }
end

function Nui.ready()
    uiReady = true

    send('hydrate', {
        scale = CFG_NUI.scale,
        locale = CFG_LOCALE.ui,
        keys = keysOf(),
        precision = PRECISION,
        radius = CFG_RADIUS,
        limit = LIMIT,
        labelLength = LABEL_LENGTH,
        modelLength = MODEL_LENGTH,
        blip = {
            spriteMax = CFG_BLIP.sprite_max,
            colorMax = CFG_BLIP.color_max,
            scaleMin = CFG_BLIP.scale_min,
            scaleMax = CFG_BLIP.scale_max,
        },
        marker = {
            sizeMin = CFG_MARKER.size_min,
            sizeMax = CFG_MARKER.size_max,
        },
        visible = Marks.isVisible(),
        points = Points.wireAll(),
    })
end

---@return boolean
function Nui.isOpen()
    return opened
end

function Nui.open()
    if not uiReady or opened then return end

    opened = true
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(false)
    send('open', { keys = keysOf() })
end

---@param fromUi boolean
function Nui.close(fromUi)
    if not opened then return end

    opened = false
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)

    if not fromUi then send('close', nil) end
end

---@param index integer
function Nui.added(index)
    send('add', { index = index, point = Points.wire(index), keys = keysOf() })
end

function Nui.full()
    send('full', nil)
end

---@param value boolean
function Nui.visible(value)
    send('visible', value)
end
