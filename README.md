# blush UI

Desktop-only Roblox/Luau UI library.

## Load

```lua
local blush = loadstring(game:HttpGet("https://raw.githubusercontent.com/Tracoskibidi/blush/refs/heads/main/blush.lua"))()
```

## Window

```lua
local window = blush:CreateWindow({
    Title = "my hub",
    Version = "v1.0.0",
    Size = Vector2.new(926, 676),

    Resize = true,
    Draggable = true,
    MinimizeButton = true,

    Logo = "sliders",
    MenuKey = Enum.KeyCode.RightShift,

    Search = true,
    Animations = true,
    Notifications = true,

    Watermark = true,
    HotkeyList = false,

    Glow = true,
    GlowIntensity = 16,
    GlowSize = 10,

    SettingsTab = {
        Enabled = true,
        Name = "Settings",
        Icon = "settings",
    },
})
```

Useful methods:

```lua
window:SetVisible(true)
window:Toggle()

window:SetResizeEnabled(true)
window:SetDraggable(true)
window:SetMinimizeButtonVisible(true)

window:SetScale(100)
window:SetWatermark(true)
window:SetHotkeyList(true)

window:SetGlowEnabled(true)
window:SetGlowIntensity(16)
window:SetGlowSize(10)
window:SetGlowAlpha(1)

window:Notify("Title", "Message", 3)
window:Destroy()
```

## Watermark

```lua
window:SetWatermarkInfo({
    Player = true,
    Fps = true,
    Ping = true,
    Time = true,
    PlayerMode = "Display name",
})
```

`PlayerMode`: `Display name`, `Username`, `Both`.

## Tabs

```lua
local combat = window:AddTab({
    Name = "Combat",
    Icon = "target",
})
```

Other group:

```lua
local misc = window:AddTab({
    Name = "Misc",
    Icon = "wrench",
    Group = "other",
})
```

## Sections

```lua
local aim = combat:AddLeftSection({
    Name = "Aim",
    Icon = "target",
})

local visuals = combat:AddRightSection({
    Name = "Visuals",
    Icon = "visuals",
})
```

## Toggle

```lua
local toggle = aim:AddToggle({
    Name = "Enabled",
    Default = false,

    Callback = function(value)
        print(value)
    end,
})
```

```lua
toggle:Get()
toggle:Set(true)
```

Right-click a toggle to configure: `Toggle`, `Hold`, or `Always On`.

## Toggle + Keybind

```lua
aim:AddToggleKey({
    Name = "Aim Assist",
    Default = false,
    Key = Enum.KeyCode.F,
})
```

## Toggle + Color

```lua
visuals:AddToggleColor({
    Name = "ESP",
    Default = true,
    Color = Color3.fromRGB(255, 255, 255),
})
```

## Slider

```lua
aim:AddSlider({
    Name = "FOV",
    Min = 0,
    Max = 360,
    Default = 120,
    Suffix = "px",
})
```

## Range Slider

```lua
aim:AddRangeSlider({
    Name = "Distance",
    Min = 0,
    Max = 5000,
    DefaultMin = 100,
    DefaultMax = 1500,
    Suffix = "m",
})
```

## Dropdown

```lua
aim:AddDropdown({
    Name = "Bone",
    Options = {"Head", "Torso", "Arms", "Legs"},
    Default = "Head",
    Searchable = true,
})
```

Dropdown options can also be right-clicked to assign keybinds.

## Multi Dropdown

```lua
aim:AddMultiDropdown({
    Name = "Hitboxes",
    Options = {"Head", "Torso", "Arms", "Legs"},
    Default = {"Head", "Torso"},
})
```

## Player Dropdown

```lua
aim:AddPlayerDropdown({
    Name = "Target",
    Searchable = true,
    Everyone = true,
    PlayersDivider = "Players",
})
```

## Input

```lua
aim:AddInput({
    Name = "Name",
    Default = "",
    Placeholder = "type here...",
})
```

## Key Picker

```lua
aim:AddKeyPicker({
    Name = "Key",
    Default = Enum.KeyCode.F,
})
```

## Color Picker

```lua
visuals:AddColorPicker({
    Name = "Color",
    Color = Color3.fromRGB(255, 255, 255),
})
```

## Radio

```lua
aim:AddRadio({
    Name = "Mode",
    Options = {"Normal", "Safe", "Fast"},
    Default = "Normal",
})
```

## Button

```lua
aim:AddButton({
    Name = "Execute",
    Callback = function()
        print("clicked")
    end,
})
```

## Label / Divider / Badge

```lua
aim:AddLabel({ Text = "Example text" })
aim:AddDivider({ Text = "Advanced" })

aim:AddBadge({
    Name = "Status",
    Text = "Ready",
    Color = Color3.fromRGB(100, 220, 140),
})
```

## Subtabs

```lua
local tabs = aim:AddSubTabs({
    Tabs = {"Main", "Visuals", "Misc"},
})
```

Use `Target` to place a control inside a subtab:

```lua
aim:AddToggle({
    Name = "Enabled",
    Default = true,
    Target = tabs:Get("Main"),
})
```

## Settings Tab

The library already includes its own Settings tab:

```lua
local settings = window:GetSettingsTab()
```

Add custom sections if needed:

```lua
local script = settings:AddRightSection({
    Name = "Script",
    Icon = "wrench",
})
```

Built-in Settings includes interface, themes, background, configs, hotkeys and auto-load.

## Theme

```lua
window:SetTheme({
    Background = Color3.fromRGB(15, 15, 16),
    Accent = Color3.fromRGB(255, 255, 255),
    Font = Color3.fromRGB(240, 240, 240),
})
```

## Background

```lua
window:SetBackground("https://example.com/image.png", 70, 4)
window:SetBackgroundOpacity(70)
window:SetBackgroundBlur(4)
window:ClearBackground()
```

## Minimal Example

```lua
local blush = loadstring(game:HttpGet("https://raw.githubusercontent.com/Tracoskibidi/blush/refs/heads/main/blush.lua"))()

local window = blush:CreateWindow({
    Title = "example",
    Watermark = true,
})

local tab = window:AddTab({
    Name = "Main",
    Icon = "home",
})

local section = tab:AddLeftSection({
    Name = "Example",
    Icon = "sliders",
})

section:AddToggle({
    Name = "Enabled",
    Default = false,
})

section:AddSlider({
    Name = "Speed",
    Min = 0,
    Max = 100,
    Default = 50,
})

section:AddDropdown({
    Name = "Mode",
    Options = {"A", "B", "C"},
    Default = "A",
})
```
