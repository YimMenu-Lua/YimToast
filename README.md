# YimToast
Lightweight GUI notification system for Lua developers.

![showcase](https://github.com/user-attachments/assets/7a09b9a2-4bea-4998-a977-7fe29498665f)

## Features

🔃 **In/Out animations.**

🔊 **Sound feedback.**

⏱️ **Time feedback.**

⏳ **First In First Out queue.**

## Methods

### `Show*(caller, message, withLog, duration)`

  > `ShowMessage` `ShowSuccess` `ShowWarning` `ShowError`

- Param `caller`: string: The title of your notification.
- Param `message`: string: The body of your notification.
- Param `withLog`: boolean: **Optional:** If true, log to console as well.
- Param `duration`: number: **Optional:** Set the display duration *(defaults to 3 seconds)*

### `Notify(caller, message, level, withLog, duration)`

- Param `caller`: string: The title of your notification.
- Param `message`: string: The body of your notification.
- Param `level`: number: A number between 0 and 3 representing `normal`, `success`, `warning`, and `error` respectively.
- Param `withLog`: boolean: **Optional:** If true, log to console as well.
- Param `duration`: number: **Optional:** Set the display duration *(defaults to 3 seconds)*

## Usage Example:

```Lua
local YimToast = require("YimToast")
local test_tab = gui.add_tab("YimToast-Test")
test_tab:add_imgui(function()

    -- default normal notification
    if ImGui.Button("Message") then
        YimToast:ShowMessage("Script", "Message")
    end

    -- default "success" notification
    if ImGui.Button("Success") then
        YimToast:ShowSuccess("Script", "Success!")
    end

    -- Notify and log to console:
    if ImGui.Button("Warning") then
        YimToast:ShowWarning("System", "Warning!", true)
    end

    -- Notify and log to console with custom toast duration:
    if ImGui.Button("Error") then
        YimToast:ShowError("Error", "Something went wrong.", true, 10)
    end

    -- long message to test text wrapping
    if ImGui.Button("Long Message") then
        YimToast:ShowMessage(
          "Script",
          "Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test TestTest Test"
        )
    end
end)
```

## TODO

- [ ] Add controller vibration feedback.
- [ ] Add callback support.
- [ ] Add a configurable `dismiss` hotkey.
- [ ] Decide whether to keep the **First In First Out** behavior or switch to **Last In First Out**.
