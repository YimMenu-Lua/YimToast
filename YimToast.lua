---@diagnostic disable: undefined-global, lowercase-global

local __init__ = false
local __instance__ = nil

local bgColors = {
    [0] = {r = 0.15, g = 0.15, b = 0.15, a = 1.0},
    [1] = {r = 0.2, g = 0.6, b = 0.2, a = 0.9},
    [2] = {r = 0.8, g = 0.6, b = 0.2, a = 0.8},
    [3] = {r = 0.8, g = 0.2, b = 0.2, a = 0.8},
}

local textColors = {
    [0] = {r = 1.0, g = 1.0, b = 1.0, a = 1.0},
    [1] = {r = 1.0, g = 1.0, b = 1.0, a = 0.8},
    [2] = {r = 0.01, g = 0.01, b = 0.01, a = 1.0},
    [3] = {r = 0.01, g = 0.01, b = 0.01, a = 1.0},
}

local frontendSounds = {
    [0] = {
        soundName = "PIN_CENTRED",
        soundRef = "DLC_HEIST_BIOLAB_PREP_HACKING_SOUNDS"
    },
    [1] = {
        soundName = "PIN_GOOD",
        soundRef = "DLC_HEIST_BIOLAB_PREP_HACKING_SOUNDS"
    },
    [2] = {
        soundName = "PIN_BAD",
        soundRef = "DLC_HEIST_BIOLAB_PREP_HACKING_SOUNDS"
    },
    [3] = {
        soundName = "ERROR",
        soundRef = "HUD_FRONTEND_DEFAULT_SOUNDSET"
    },
}

local logLevels = {
    [0] = log.info,
    [1] = log.info,
    [2] = log.warning,
}

---@param caller string
---@param message string
local function logError(caller, message)
    log.warning(("[ERROR] (%s): %s"):format(caller, message))
end

local function GetScreenResolution()
    local scr = {x = 0, y = 0}
    local sr_ptr = memory.scan_pattern("66 0F 6E 0D ? ? ? ? 0F B7 3D")
    if sr_ptr:is_valid() then
        scr.x = sr_ptr:sub(0x4):rip():get_word()
        scr.y = sr_ptr:add(0x4):rip():get_word()
    end
    return scr
end


---@alias ToastLevel integer
---| 0 # Default
---| 1 # Success
---| 2 # Warning
---| 3 # Error

---@class Toast
---@field caller string The notification title.
---@field message string The notification body.
---@field level ToastLevel The type of message to show.
---@field duration float **Optional:** The duration of the notification *(default 3s)*.
---@field start_time float Time at which the notification was first shown.
---@field should_draw boolean Whether the notification UI should be drawn.
---@field screen_resolution table The game's screen resolution.
local Toast = {}
Toast.__index = Toast

---@param caller string The notification title.
---@param message string The notification body.
---@param level ToastLevel The type of message to show.
---@param duration float **Optional:** The duration of the notification *(default 3s)*.
---@param log boolean **Optional:** Log to console as well.
function Toast.new(caller, message, level, duration, log)
    return setmetatable({
        caller = caller or "YimToast",
        message = message,
        level = level or 0,
        duration = duration or 3.0,
        start_time = os.clock(),
        should_draw = false,
        screen_resolution = GetScreenResolution(),
        should_log = log
    }, Toast)
end

function Toast:Draw()
    if not self.should_draw then
        return
    end
    local screenResolution = self.screen_resolution
    local windowBgCol = bgColors[self.level] or bgColors[0]
    local textCol = textColors[self.level] or textColors[0]
    local notifWindowWidth = 320
    local notifPosX = screenResolution.x - notifWindowWidth - 10

    if __instance__ and #__instance__.queue > 0 then
        __caller__ = string.format("%s  (+%d)", self.caller, #__instance__.queue)
    else
        __caller__ = self.caller
    end

    ImGui.SetNextWindowSizeConstraints(notifWindowWidth, 100, notifWindowWidth, 400)
    ImGui.SetNextWindowBgAlpha(0.7)
    ImGui.SetNextWindowPos(notifPosX, 20)
    ImGui.PushStyleColor(
        ImGuiCol.WindowBg,
        windowBgCol.r,
        windowBgCol.g,
        windowBgCol.b,
        windowBgCol.a
    )
    if ImGui.Begin(("YimToast%s"):format(self.start_time),
            ImGuiWindowFlags.AlwaysAutoResize |
            ImGuiWindowFlags.NoTitleBar |
            ImGuiWindowFlags.NoResize |
            ImGuiWindowFlags.NoMove |
            ImGuiWindowFlags.NoCollapse |
            ImGuiWindowFlags.NoFocusOnAppearing |
            ImGuiWindowFlags.NoSavedSettings |
            ImGuiWindowFlags.NoScrollbar |
            ImGuiWindowFlags.NoScrollWithMouse
    ) then
        ImGui.PushTextWrapPos(notifWindowWidth - (ImGui.GetFontSize() / 2))
        local callerTextWidth, _ = ImGui.CalcTextSize(__caller__)
        local elapsed = os.clock() - self.start_time
        local progress = 1.0 - (elapsed / self.duration)
        ImGui.Dummy((notifWindowWidth / 2) - callerTextWidth, 1); ImGui.SameLine()
        ImGui.TextColored(
            textCol.r,
            textCol.g,
            textCol.b,
            textCol.a,
            __caller__
        )
        ImGui.Separator()
        ImGui.TextColored(
            textCol.r,
            textCol.g,
            textCol.b,
            textCol.a,
            self.message
        )
        ImGui.Dummy(1, 10)
        ImGui.ProgressBar(progress, -1, 3)
        ImGui.PopTextWrapPos()
        ImGui.PopStyleColor()
        ImGui.End()
    end
end


---@class Notifier
---@field queue Toast[]
local Notifier = {}
Notifier.__index = Notifier

function Notifier.new()
    __init__ = true
    __instance__ = setmetatable(
        {
            queue = {},
            active = nil,
            should_draw = false,
        },
        Notifier
    )
    return __instance__
end

---@param caller string The notification title.
---@param message string The notification body.
---@param level ToastLevel The notification type.
---@param withLog? boolean **Optional:** Log to console as well.
---@param duration? float **Optional:** The duration of the notification *(default 3s)*.
function Notifier:ShowToast(caller, message, level, withLog, duration)
    table.insert(self.queue, Toast.new(caller, message, level, duration or 3.0, withLog or false))
end

---@param caller string The notification title.
---@param message string The notification body.
---@param withLog? boolean **Optional:** Log to console as well.
---@param duration? float **Optional:** The duration of the notification *(default 3s)*.
function Notifier:ShowMessage(caller, message, withLog, duration)
    table.insert(self.queue, Toast.new(caller, message, 0, duration or 3.0, withLog or false))
end

---@param caller string The notification title.
---@param message string The notification body.
---@param withLog? boolean **Optional:** Log to console as well.
---@param duration? float **Optional:** The duration of the notification *(default 3s)*.
function Notifier:ShowSuccess(caller, message, withLog, duration)
    table.insert(self.queue, Toast.new(caller, message, 1, duration or 3.0, withLog or false))
end

---@param caller string The notification title.
---@param message string The notification body.
---@param withLog? boolean **Optional:** Log to console as well.
---@param duration? float **Optional:** The duration of the notification *(default 3s)*.
function Notifier:ShowWarning(caller, message, withLog, duration)
    table.insert(self.queue, Toast.new(caller, message, 2, duration or 3.0, withLog or false))
end

---@param caller string The notification title.
---@param message string The notification body.
---@param withLog? boolean **Optional:** Log to console as well.
---@param duration? float **Optional:** The duration of the notification *(default 3s)*.
function Notifier:ShowError(caller, message, withLog, duration)
    table.insert(self.queue, Toast.new(caller, message, 3, duration or 3.0, withLog or false))
end

function Notifier:Update()
    if not self.active and #self.queue > 0 then
        self.active = table.remove(self.queue, 1)
        self.active.start_time = os.clock()
        self.active.should_draw = true
        self.should_draw = true

        script.run_in_fiber(function()
            AUDIO.PLAY_SOUND_FRONTEND(
                -1,
                frontendSounds[self.active.level].soundName,
                frontendSounds[self.active.level].soundRef,
                false
            )
        end)

        if self.active.should_log then
            if self.active.level < 3 then
                logFunc = logLevels[self.active.level] or log.info
                logFunc(("(%s): %s"):format(self.active.caller, self.active.message))
            else
                logError(self.active.caller, self.active.message)
            end
        end
    end
    if self.active then
        if os.clock() - self.active.start_time >= self.active.duration then
            self.active.should_draw = false
            self.active = nil
            self.should_draw = false
        end
    end
end

function Notifier:Draw()
    if self.should_draw and self.active then
        self.active:Draw()
    end
end


local YimToast = Notifier.new()
assert(YimToast ~= nil, "YimToast failed to load!")
if __init__ then
    gui.add_always_draw_imgui(function()
        YimToast:Draw()
    end)

    script.register_looped("YimToast", function(yimtoast)
        YimToast:Update()
        yimtoast:sleep(100)
    end)
end

return YimToast
