# blush UI

Compact reference for the current blush API.

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
    Position = nil,

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

    Scale = 100,
    Transparency = 0,
    Roundness = 12,
    Stroke = true,
    Shadow = true,

    Glow = true,
    GlowIntensity = 16,
    GlowSize = 10,
    GlowAlpha = 1,

    SidebarResize = true,
    SidebarWidth = 190,

    SettingsTab = {
        Enabled = true,
        Name = "Settings",
        Icon = "settings",
    },
})
```

Useful optional window fields:

`MinSize`, `MaxSize`, `LogoColor`, `GlowColor`, `Theme`, `Background`, `BackgroundOpacity`, `BackgroundBlur`, `BackgroundExcludeSidebar`, `AutoBackgroundColors`, `WatermarkInfo`, `NotifyLoaded`.

## Window API

```lua
window:SetVisible(true)
window:Toggle()
window:Destroy()

window:SetTitle("new title")
window:SetVersion("v2")
window:SetLogo("home")
window:SetMenuKey(Enum.KeyCode.RightShift)

window:SetSize(Vector2.new(900, 650))
window:SetPosition(Vector2.new(100, 100))
window:SetMinSize(Vector2.new(620, 440))
window:SetMaxSize(Vector2.new(1200, 800))

window:SetResizeEnabled(true)
window:SetDraggable(true)
window:SetMinimizeButtonVisible(true)
window:SetSidebarResizeEnabled(true)
window:SetSidebarWidth(190)

window:SetScale(100)
window:SetTransparency(0)
window:SetRoundness(12)
window:SetStrokeVisible(true)
window:SetShadowVisible(true)

window:SetSearch(true)
window:SetAnimations(true)
window:SetNotifications(true)
window:SetSettingsVisible(true)

window:SetWatermark(true)
window:SetHotkeyList(true)

window:SetGlowEnabled(true)
window:SetGlowColor(Color3.new(1, 1, 1))
window:SetGlowIntensity(16)
window:SetGlowSize(10)
window:SetGlowAlpha(1)
```

Getters:

```lua
window:GetSize()
window:GetPosition()
window:GetSidebarWidth()
window:GetTheme()
window:GetGui()
window:GetTab("Main")
window:GetSettingsTab()
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

## Notifications

```lua
window:Notify("Title", "Message", 3)
```

With button:

```lua
window:Notify("Delete?", "This cannot be undone", 5, function()
    print("clicked")
end, "Delete")
```

## Tabs

```lua
local main = window:AddTab({
    Name = "Main",
    Icon = "home",
})

local misc = window:AddTab({
    Name = "Misc",
    Icon = "wrench",
    Group = "other",
})
```

```lua
main:Select()
main:SetName("Combat")
main:SetIcon("target")
main:SetVisible(true)
main:GetPage()

window:SelectTab("Combat")
```

## Sections

```lua
local left = main:AddLeftSection({
    Name = "Aim",
    Icon = "target",
})

local right = main:AddRightSection({
    Name = "Visuals",
    Icon = "eye",
})
```

Generic form:

```lua
local section = main:AddSection({
    Name = "Section",
    Side = "left", -- left / right
    Icon = "settings",
})
```

---

# Elements

## Toggle

```lua
local toggle = left:AddToggle({
    Name = "Enabled",
    Default = false,
    Keybindable = true,
    Badge = "NEW",

    Callback = function(value)
        print(value)
    end,
})
```

```lua
toggle:Get()
toggle:Set(true)
```

Right-click a keybindable toggle for `Toggle`, `Hold`, or `Always On`.

## Toggle + Key

```lua
local toggle = left:AddToggleKey({
    Name = "Aim Assist",
    Default = false,
    Key = Enum.KeyCode.F,

    Callback = function(value)
        print(value)
    end,

    KeyCallback = function(key)
        print(key)
    end,
})
```

## Toggle + Color

```lua
local toggle = right:AddToggleColor({
    Name = "ESP",
    Default = true,
    Color = Color3.fromRGB(255, 255, 255),
    Keybindable = true,

    Callback = function(value)
        print(value)
    end,

    ColorCallback = function(color, alpha)
        print(color, alpha)
    end,
})
```

## Toggle + Color + Key

```lua
right:AddToggleColorKey({
    Name = "ESP",
    Default = true,
    Color = Color3.new(1, 1, 1),
    Key = Enum.KeyCode.E,

    ToggleCallback = function(value)
        print(value)
    end,

    ColorCallback = function(color, alpha)
        print(color, alpha)
    end,

    KeyCallback = function(key)
        print(key)
    end,
})
```

## Slider

```lua
local slider = left:AddSlider({
    Name = "FOV",
    Min = 0,
    Max = 360,
    Default = 120,
    Suffix = "°",

    Callback = function(value)
        print(value)
    end,
})
```

```lua
slider:Get()
slider:Set(180)
```

## Range Slider

```lua
local range = left:AddRangeSlider({
    Name = "Distance",
    Min = 0,
    Max = 5000,
    DefaultMin = 100,
    DefaultMax = 1500,
    Suffix = "m",
})
```

```lua
range:Get()
range:Set(250, 2000)
```

## Dropdown

```lua
local dropdown = left:AddDropdown({
    Name = "Bone",
    Options = {"Head", "Torso", "Arms", "Legs"},
    Default = "Head",
    Searchable = true,

    Callback = function(value)
        print(value)
    end,
})
```

```lua
dropdown:Get()
dropdown:Set("Torso")
dropdown:SetOptions({"Head", "Torso"})
```

Options can include metadata:

```lua
Options = {
    {Name = "Head", Icon = "target", Color = Color3.new(1, 1, 1)},
    {Divider = true, Text = "Other"},
    {Name = "Torso"},
}
```

Right-click a dropdown option to assign a keybind.

## Multi Dropdown

```lua
local dropdown = left:AddMultiDropdown({
    Name = "Hitboxes",
    Options = {"Head", "Torso", "Arms", "Legs"},
    Default = {"Head", "Torso"},
})
```

```lua
dropdown:Get()
dropdown:Set({"Head", "Arms"})
dropdown:SetOptions({"Head", "Torso"})
```

## Player Dropdown

```lua
local players = left:AddPlayerDropdown({
    Name = "Target",
    Default = nil,
    Searchable = true,
    Everyone = true,
    PlayersDivider = "Players",

    Callback = function(value)
        print(value)
    end,
})
```

You can also add custom entries:

```lua
Options = {"Closest", "Random"}
```

## Multi Player Dropdown

```lua
left:AddMultiPlayerDropdown({
    Name = "Targets",
    Default = {"Everyone"},
    Searchable = true,
    Everyone = true,
})
```

## Input

```lua
local input = left:AddInput({
    Name = "Name",
    Default = "",
    Placeholder = "type here...",

    Callback = function(text)
        print(text)
    end,
})
```

`AddInput` returns the TextBox, so `input.Text` is available directly.

## Key Picker

```lua
local key = left:AddKeyPicker({
    Name = "Key",
    Default = Enum.KeyCode.F,

    Callback = function(value)
        print(value)
    end,
})
```

```lua
key:Get()
key:Set(Enum.KeyCode.Q)
```

Keyboard and supported mouse binds are accepted.

## Color Picker

```lua
local color = right:AddColorPicker({
    Name = "Color",
    Color = Color3.fromRGB(255, 255, 255),

    Callback = function(value, alpha)
        print(value, alpha)
    end,
})
```

```lua
color:Set(Color3.fromRGB(255, 0, 0), 1)
```

Color picker supports alpha, rainbow and fade controls in its popup.

## Radio

```lua
local radio = left:AddRadio({
    Name = "Mode",
    Options = {"Normal", "Safe", "Fast"},
    Default = "Normal",
})
```

```lua
radio:Get()
radio:Set("Fast")
```

## Button

```lua
left:AddButton({
    Name = "Execute",
    Callback = function()
        print("clicked")
    end,
})
```

## Button Group

```lua
left:AddButtonGroup({
    Buttons = {
        {Text = "Load", Callback = function() end},
        {Text = "Save", Callback = function() end},
        {Text = "Delete", Callback = function() end},
    },
})
```

## Row

```lua
local row = left:AddRow({
    Spacing = 8,
    Height = 32,
})

row:AddButton({Name = "A"})
row:AddButton({Name = "B"})
row:AddToggle({Name = "C", Default = false})
```

Useful for compact horizontal controls.

## Label

```lua
left:AddLabel({
    Text = "Example text",
    Wrap = true,
})
```

## Divider

```lua
left:AddDivider({Text = "Advanced"})
```

## Separator

```lua
left:AddSeparator()
```

## Badge / Status

```lua
local badge = left:AddBadge({
    Name = "Status",
    Text = "Ready",
    Color = Color3.fromRGB(100, 220, 140),
})
```

```lua
badge:SetText("Running")
badge:SetColor(Color3.fromRGB(255, 180, 80))
```

## Progress Bar

```lua
local progress = left:AddProgressBar({
    Name = "Progress",
    Default = 25,
    Suffix = "%",
})
```

```lua
progress:Get()
progress:Set(80)
```

## Image

```lua
local image = right:AddImage({
    Name = "Preview",
    Asset = "rbxassetid://123456",
    Height = 120,
})
```

Returns the `ImageLabel`.

## Avatar

```lua
right:AddAvatar({
    Name = "Player",
    Player = game.Players.LocalPlayer,
})
```

`Player`, `Source`, or `UserId` can be used.

## Loading Spinner

```lua
left:AddLoadingSpinner({Name = "Loading"})
```

## Loading Bar

```lua
left:AddLoadingBar({Name = "Loading"})
```

## Context Menu

```lua
left:AddContextMenu({
    Name = "Actions",
    Entries = {
        {Text = "Copy", Icon = "copy", Callback = function() end},
        {Divider = true},
        {Text = "Delete", Icon = "trash", Callback = function() end},
    },
})
```

Right-click the button to open it.

## Confirm Button

```lua
left:AddConfirmButton({
    Name = "Delete",
    Title = "Confirm",
    Body = "Delete this item?",
    Callback = function()
        print("confirmed")
    end,
})
```

## Modal Button

```lua
left:AddModalButton({
    Name = "Info",
    Title = "Information",
    Body = "Example message",
})
```

---

# Subtabs

```lua
local subtabs = left:AddSubTabs({
    Tabs = {"Main", "Visuals", "Misc"},
})
```

Put controls inside a subtab with `Target`:

```lua
left:AddToggle({
    Name = "Enabled",
    Default = true,
    Target = subtabs:Get("Main"),
})
```

```lua
subtabs:Get("Main")
subtabs:Select("Visuals")
subtabs:SetCollapsed(true)
subtabs:IsCollapsed()
```

---

# Settings Tab

Built-in settings already handle interface, themes, background, configs, hotkeys and auto-load.

```lua
local settings = window:GetSettingsTab()
```

Add custom sections:

```lua
local scriptsettings = settings:AddRightSection({
    Name = "Script",
    Icon = "wrench",
})

scriptsettings:AddToggle({
    Name = "Auto Farm",
    Default = false,
})
```

Settings API:

```lua
settings:Select()
settings:SetVisible(true)
settings:Configure({
    Enabled = true,
    Name = "Settings",
    Icon = "settings",
    GroupName = "Other",
    Sections = {
        Interface = true,
        Themes = true,
        Background = true,
        Configs = true,
    },
})
```

---

# Theme

```lua
window:SetTheme({
    Background = Color3.fromRGB(15, 15, 16),
    Accent = Color3.fromRGB(255, 255, 255),
    Font = Color3.fromRGB(240, 240, 240),

    BackgroundAlpha = 1,
    AccentAlpha = 1,
    FontAlpha = 1,

    Animate = true,
})
```

```lua
local theme = window:GetTheme()
```

---

# Background

```lua
window:SetBackground("https://example.com/image.png", 70, 4)
window:SetBackgroundOpacity(70)
window:SetBackgroundBlur(4)
window:SetBackgroundExcludeSidebar(false)
window:SetAutoBackgroundColors(false)
window:ClearBackground()
```

---

# Configs / Hotkeys

Configs are managed from the built-in `Settings > Saves` section.

Saved configs include control/UI state and assigned keybinds. `Auto load` can automatically load the selected config on startup.

Checkboxes and dropdown options can use right-click keybind configuration. Available modes are:

`Toggle` · `Hold` · `Always On`

The Hotkey List shows registered binds and their active state.

---

# Minimal Example

```lua
local blush = loadstring(game:HttpGet("https://raw.githubusercontent.com/Tracoskibidi/blush/refs/heads/main/blush.lua"))()

local window = blush:CreateWindow({
    Title = "example",
    Watermark = true,
    HotkeyList = true,
})

local main = window:AddTab({
    Name = "Main",
    Icon = "home",
})

local section = main:AddLeftSection({
    Name = "Player",
    Icon = "user",
})

section:AddToggleKey({
    Name = "Enabled",
    Default = false,
    Key = Enum.KeyCode.F,
})

section:AddSlider({
    Name = "Speed",
    Min = 0,
    Max = 100,
    Default = 50,
})

section:AddDropdown({
    Name = "Mode",
    Options = {"Normal", "Fast", "Safe"},
    Default = "Normal",
})
```
