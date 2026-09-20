# blush UI

A desktop-only Roblox/Luau UI library.

> Mobile is not supported.

## Load

```lua
local blush = loadstring(game:HttpGet("https://raw.githubusercontent.com/Tracoskibidi/blush/refs/heads/main/blush.lua"))()
```

## Recommended syntax

Use **config tables**. You do not need to remember argument order or fill unused arguments with `nil`.

```lua
section:AddDropdown({
    Name = "Bone",
    Options = {"Head", "Torso", "Arms", "Legs"},
    Default = "Head",
    Searchable = true,

    Callback = function(value)
        print(value)
    end,
})
```

The old positional syntax is still supported, but this README uses the config-table API.

---

# 1. Create a Window

```lua
local blush = loadstring(game:HttpGet("https://raw.githubusercontent.com/Tracoskibidi/blush/refs/heads/main/blush.lua"))()
if not blush then return end

local window = blush:CreateWindow({
    Title = "my hub",
    Version = "v1.0.0",

    Size = Vector2.new(926, 676),

    Resize = true,
    Draggable = true,
    MinimizeButton = true,

    MinSize = Vector2.new(620, 440),

    Roundness = 12,
    Stroke = true,
    Shadow = true,
    Scale = 100,

    MenuKey = Enum.KeyCode.RightShift,

    Animations = true,
    Search = true,
    Notifications = true,
    Watermark = false,
    CheckboxList = false,

    SettingsTab = {
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
    },

    NotifyLoaded = true,
})
```

### Window options

| Option | Type | What it does |
|---|---|---|
| `Title` | string | Window/library name |
| `Version` | string | Version shown in the sidebar |
| `Size` | `Vector2` | Initial window size |
| `Position` | `UDim2` | Initial position; omit to center |
| `Resize` | boolean | Enables window resizing |
| `Draggable` | boolean | Enables window dragging |
| `MinimizeButton` | boolean | Shows the `X` minimize button |
| `MinSize` | `Vector2` | Minimum resize size |
| `MaxSize` | `Vector2` or `nil` | Maximum resize size |
| `Roundness` | number | Window corner radius |
| `Stroke` | boolean | Window border |
| `Shadow` | boolean | Window shadow |
| `Scale` | number | UI scale percentage |
| `MenuKey` | `Enum.KeyCode` / string | Show/hide key |
| `Animations` | boolean | UI animations |
| `Search` | boolean | Page search |
| `Notifications` | boolean | Notifications |
| `Watermark` | boolean | Watermark |
| `CheckboxList` | boolean | External checkbox list |
| `SettingsTab` | table / boolean | Built-in library Settings tab |
| `Theme` | table | Initial theme |
| `Background` | string | Initial background image |
| `BackgroundOpacity` | number | Background image opacity |
| `BackgroundBlur` | number | Background blur |
| `BackgroundExcludeSidebar` | boolean | Keeps sidebar outside background |
| `AutoBackgroundColors` | boolean | Samples colors from background |
| `NotifyLoaded` | boolean | Loaded notification |

---

# 2. Built-in Settings Tab

The Settings tab is part of the library. You do not need to create it.

```lua
SettingsTab = {
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
}
```

Change it later:

```lua
window:SetSettingsTab({
    Enabled = true,
    Name = "Library",
    Icon = "wrench",
    GroupName = "System",

    Sections = {
        Interface = true,
        Themes = true,
        Background = false,
        Configs = true,
    },
})
```

You can also add your own sections directly to the library Settings tab:

```lua
local settings = window:GetSettingsTab()

local scriptSettings = settings:AddLeftSection({
    Name = "Script",
    Icon = "wrench",
})

scriptSettings:AddToggle({
    Name = "Auto Load",
    Default = false,

    Callback = function(value)
        print(value)
    end,
})
```

Settings tab methods:

```lua
local settings = window:GetSettingsTab()

settings:Select()
settings:SetVisible(true)

settings:Configure({
    Enabled = true,
    Name = "Settings",
    Icon = "settings",
})

settings:AddLeftSection({ Name = "Left" })
settings:AddRightSection({ Name = "Right" })
```

Shortcut:

```lua
window.Settings
```

---

# 3. Window Methods

```lua
window:SetVisible(true)
window:Toggle()

window:SetResizeEnabled(true)
window:SetDraggable(true)
window:SetMinimizeButtonVisible(true)

window:SetMinSize(Vector2.new(620, 440))
window:SetMaxSize(Vector2.new(1200, 900))
window:SetMaxSize(nil)

window:SetSize(Vector2.new(900, 650))
window:SetSize(Vector2.new(900, 650), true) -- resize + recenter

local size = window:GetSize()

window:SetPosition(UDim2.fromOffset(100, 100))
local position = window:GetPosition()

window:SetRoundness(12)
window:SetStrokeVisible(true)
window:SetShadowVisible(true)

window:SetMenuKey(Enum.KeyCode.Insert)
window:SetScale(100)

window:SetWatermark(true)
window:SetCheckboxList(true)
window:SetAnimations(true)
window:SetSearch(true)
window:SetNotifications(true)

window:SetSettingsVisible(true)

window:SetTitle("my hub")
window:SetVersion("v2.0.0")

window:Notify("Title", "Message", 3)

local gui = window:GetGui()

window:Destroy()
```

---

# 4. Theme

At creation:

```lua
local window = blush:CreateWindow({
    Theme = {
        Background = Color3.fromRGB(15, 15, 16),
        Accent = Color3.fromRGB(255, 255, 255),
        Font = Color3.fromRGB(240, 240, 240),

        BackgroundAlpha = 1,
        AccentAlpha = 1,
        FontAlpha = 1,

        Animate = true,
    },
})
```

Later:

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

local currentTheme = window:GetTheme()
```

---

# 5. Background

At creation:

```lua
local window = blush:CreateWindow({
    Background = "https://example.com/image.png",
    BackgroundOpacity = 70,
    BackgroundBlur = 4,
    BackgroundExcludeSidebar = false,
    AutoBackgroundColors = false,
})
```

Later:

```lua
window:SetBackground(
    "https://example.com/image.png",
    70,
    4
)

window:SetBackgroundOpacity(70)
window:SetBackgroundBlur(4)
window:SetBackgroundExcludeSidebar(true)
window:SetAutoBackgroundColors(true)

window:ClearBackground()
```

---

# 6. Tabs

```lua
local combat = window:AddTab({
    Name = "Combat",
    Icon = "target",
    Group = "main",
})

local misc = window:AddTab({
    Name = "Misc",
    Icon = "wrench",
    Group = "other",
})
```

`Group`:

```text
main
other
```

Tab methods:

```lua
combat:Select()
combat:SetName("Aim")
combat:SetIcon("target")
combat:SetVisible(true)

local page = combat:GetPage()

window:SelectTab("Combat")
local tab = window:GetTab("Combat")
```

---

# 7. Sections / Groupboxes

```lua
local aim = combat:AddSection({
    Name = "Aim",
    Side = "left",
    Icon = "target",
})

local visuals = combat:AddSection({
    Name = "Visuals",
    Side = "right",
    Icon = "visuals",
})
```

Shortcuts:

```lua
local left = combat:AddLeftSection({
    Name = "Movement",
    Icon = "gauge",
})

local right = combat:AddRightSection({
    Name = "Utility",
    Icon = "wrench",
})
```

---

# 8. Common Control Fields

Most controls use these fields:

```lua
{
    Name = "Control name",
    Default = ...,
    Callback = function(value) end,
}
```

`Target` is only needed when putting the control inside a subtab.

Example:

```lua
local tabs = aim:AddSubTabs({
    Tabs = {"Main", "Extra"},
})

aim:AddToggle({
    Name = "Enabled",
    Default = true,
    Target = tabs:Get("Main"),
})
```

---

# 9. Label

```lua
section:AddLabel({
    Text = "Hello",
    Wrap = true,
})
```

---

# 10. Button

```lua
section:AddButton({
    Name = "Execute",

    Callback = function()
        print("clicked")
    end,
})
```

---

# 11. Button Group

```lua
section:AddButtonGroup({
    Buttons = {
        {
            Text = "Save",
            Callback = function() end,
        },

        {
            Text = "Load",
            Callback = function() end,
        },

        {
            Text = "Delete",
            Callback = function() end,
        },
    },
})
```

---

# 12. Row

```lua
local row = section:AddRow({
    Spacing = 8,
    Height = 32,
})
```

Buttons:

```lua
row:AddButton({
    Name = "A",
    Callback = function() end,
})

row:AddButton({
    Name = "B",
    Callback = function() end,
})
```

Toggle:

```lua
row:AddToggle({
    Name = "Enabled",
    Default = false,
    Keybind = false,

    Callback = function(value)
        print(value)
    end,
})
```

---

# 13. Toggle / Checkbox

```lua
local toggle = section:AddToggle({
    Name = "Enabled",
    Default = false,

    Callback = function(value)
        print(value)
    end,
})
```

Optional fields:

```lua
local toggle = section:AddToggle({
    Name = "Aim",
    Default = false,

    Keybind = true,
    Badge = "NEW",

    Callback = function(value)
        print(value)
    end,
})
```

Methods:

```lua
toggle:Get()
toggle:Set(true)
toggle:Set(false, false) -- false = do not fire Callback
```

---

# 14. Toggle + Keybind

```lua
local flight = section:AddToggleKey({
    Name = "Flight",
    Default = false,
    Key = Enum.KeyCode.F,

    Callback = function(enabled)
        print(enabled)
    end,

    KeyCallback = function(key)
        print(key)
    end,
})
```

---

# 15. Toggle + Color

```lua
local esp = section:AddToggleColor({
    Name = "ESP",
    Default = true,
    Color = Color3.fromRGB(255, 255, 255),

    Callback = function(enabled)
        print(enabled)
    end,

    ColorCallback = function(color, alpha)
        print(color, alpha)
    end,
})
```

Color API:

```lua
esp.Color:color()
esp.Color:currentalpha()

esp.Color:Set(
    Color3.fromRGB(255, 0, 0),
    0.8
)
```

---

# 16. Toggle + Color + Keybind

```lua
section:AddToggleColorKey({
    Name = "Chams",
    Default = true,
    Color = Color3.fromRGB(180, 120, 255),
    Key = Enum.KeyCode.Q,

    Callback = function(enabled) end,
    ColorCallback = function(color, alpha) end,
    KeyCallback = function(key) end,
})
```

---

# 17. Slider

```lua
local speed = section:AddSlider({
    Name = "Speed",

    Min = 0,
    Max = 100,
    Default = 16,

    Suffix = "",

    Callback = function(value)
        print(value)
    end,
})
```

Methods:

```lua
speed:Get()
speed:Set(30)
```

---

# 18. Range Slider

```lua
local distance = section:AddRangeSlider({
    Name = "Distance",

    Min = 0,
    Max = 5000,

    DefaultMin = 100,
    DefaultMax = 1500,

    Suffix = "m",

    Callback = function(minimum, maximum)
        print(minimum, maximum)
    end,
})
```

Methods:

```lua
local minimum, maximum = distance:Get()
distance:Set(250, 2000)
```

---

# 19. Dropdown

Simple:

```lua
local mode = section:AddDropdown({
    Name = "Mode",

    Options = {
        "Legit",
        "Rage",
        "Silent",
    },

    Default = "Legit",

    Callback = function(value)
        print(value)
    end,
})
```

Searchable:

```lua
local bone = section:AddDropdown({
    Name = "Bone",

    Options = {
        "Head",
        "Torso",
        "Arms",
        "Legs",
    },

    Default = "Head",
    Searchable = true,

    Callback = function(value)
        print(value)
    end,
})
```

Icons, colors and dividers:

```lua
section:AddDropdown({
    Name = "Category",
    Searchable = true,

    Options = {
        {
            Value = "Target",
            Icon = blush.Icons.target,
        },

        {
            Divider = true,
            Text = "Other",
        },

        {
            Value = "Settings",
            Icon = blush.Icons.settings,
        },
    },

    Default = "Target",

    Icons = {
        Target = blush.Icons.target,
    },

    Colors = {
        Target = Color3.fromRGB(255, 100, 100),
    },
})
```

Methods:

```lua
mode:Get()
mode:Set("Rage")
mode:Set("Rage", false)
mode:SetOptions({"A", "B", "C"}, "B")
```

---

# 20. Multi Dropdown

```lua
local hitboxes = section:AddMultiDropdown({
    Name = "Hitboxes",

    Options = {
        "Head",
        "Torso",
        "Arms",
        "Legs",
    },

    Default = {
        "Head",
        "Torso",
    },

    Callback = function(values)
        print(values)
    end,
})
```

Methods:

```lua
hitboxes:Get()
hitboxes:Set({"Head", "Arms"})
```

---

# 21. Player Dropdown

```lua
local target = section:AddPlayerDropdown({
    Name = "Target",

    Options = {
        {
            Value = "Closest",
            Icon = blush.Icons.target,
        },
    },

    Default = "Closest",

    Searchable = true,
    Everyone = true,
    PlayersDivider = "Players",

    Callback = function(value)
        print(value)
    end,
})
```

Optional fields:

```lua
{
    Searchable = true,
    Everyone = true,
    MultiSelect = false,
    PlayersDivider = "Players",
    Icons = {},
    Colors = {},
}
```

---

# 22. Multi Player Dropdown

```lua
local targets = section:AddMultiPlayerDropdown({
    Name = "Players",

    Default = {
        "Everyone",
    },

    Searchable = true,
    Everyone = true,
    PlayersDivider = "Players",

    Callback = function(values)
        print(values)
    end,
})
```

---

# 23. Input

```lua
local input = section:AddInput({
    Name = "Profile",

    Default = "",
    Placeholder = "type here...",

    Callback = function(text)
        print(text)
    end,
})
```

The returned object is the `TextBox`:

```lua
print(input.Text)
input.Text = "hello"
```

---

# 24. Key Picker

```lua
local key = section:AddKeyPicker({
    Name = "Menu Key",
    Default = Enum.KeyCode.RightShift,

    Callback = function(value)
        print(value)
    end,
})
```

Methods:

```lua
key:Get()
key:Set(Enum.KeyCode.Insert)
key:Set("F", false)
```

---

# 25. Color Picker

```lua
local picker = section:AddColorPicker({
    Name = "Color",
    Color = Color3.fromRGB(255, 255, 255),

    Callback = function(color, alpha)
        print(color, alpha)
    end,
})
```

Methods:

```lua
picker:color()
picker:currentalpha()

picker:Set(
    Color3.fromRGB(255, 80, 120),
    0.75
)
```

---

# 26. Radio

```lua
local radio = section:AddRadio({
    Name = "Mode",

    Options = {
        "Normal",
        "Safe",
        "Fast",
    },

    Default = "Normal",

    Callback = function(value)
        print(value)
    end,
})
```

Methods:

```lua
radio:Get()
radio:Set("Safe")
```

---

# 27. Badge / Status

```lua
local status = section:AddBadge({
    Name = "Status",
    Text = "Ready",
    Color = Color3.fromRGB(110, 210, 150),
})
```

Methods:

```lua
status:SetText("Running")
status:SetColor(Color3.fromRGB(255, 190, 80))
```

---

# 28. Divider

With text:

```lua
section:AddDivider({
    Text = "Advanced",
})
```

Without text:

```lua
section:AddDivider({})
```

Separator:

```lua
section:AddSeparator({})
```

---

# 29. Image

```lua
local image = section:AddImage({
    Name = "Preview",
    Asset = "rbxassetid://123456789",
    Height = 96,
})
```

---

# 30. Avatar

Player instance:

```lua
section:AddAvatar({
    Name = "Player",
    Player = game:GetService("Players").LocalPlayer,
})
```

UserId:

```lua
section:AddAvatar({
    Name = "Player",
    UserId = 123456789,
})
```

---

# 31. Progress Bar

```lua
local progress = section:AddProgressBar({
    Name = "Progress",
    Default = 50,
    Suffix = "%",
})
```

Methods:

```lua
progress:Get()
progress:Set(80)
```

---

# 32. Loading Spinner

```lua
section:AddLoadingSpinner({
    Name = "Loading",
})
```

---

# 33. Loading Bar

```lua
section:AddLoadingBar({
    Name = "Loading",
})
```

---

# 34. Context Menu

```lua
section:AddContextMenu({
    Name = "Actions",

    Entries = {
        {
            Text = "Open",
            Icon = blush.Icons.right,

            Callback = function()
                print("open")
            end,
        },

        {
            Divider = true,
        },

        {
            Text = "Delete",

            Callback = function()
                print("delete")
            end,
        },
    },
})
```

---

# 35. Confirm Button

```lua
section:AddConfirmButton({
    Name = "Reset",
    Title = "Reset Settings",
    Body = "Are you sure?",

    Callback = function()
        print("confirmed")
    end,
})
```

---

# 36. Modal Button

```lua
section:AddModalButton({
    Name = "About",
    Title = "About",
    Body = "blush UI",
})
```

---

# 37. Subtabs

```lua
local subtabs = section:AddSubTabs({
    Tabs = {
        "Main",
        "Visuals",
        "Misc",
    },
})
```

Add controls to a subtab using `Target`:

```lua
section:AddToggle({
    Name = "Enabled",
    Default = true,
    Target = subtabs:Get("Main"),
})

section:AddSlider({
    Name = "FOV",
    Min = 0,
    Max = 360,
    Default = 120,
    Suffix = "px",
    Target = subtabs:Get("Main"),
})

section:AddColorPicker({
    Name = "ESP Color",
    Color = Color3.fromRGB(255, 255, 255),
    Target = subtabs:Get("Visuals"),
})
```

Subtab methods:

```lua
subtabs:Get("Main")
subtabs:Select("Visuals")

subtabs:SetCollapsed(true)
subtabs:SetCollapsed(false, false)

subtabs:IsCollapsed()
```

---

# 38. Icons

Built-in names:

```text
home
combat
visuals
extras
farming
settings
search
target
palette
filter
gauge
wrench
sliders
user
check
down
right
keyboard
userround
menu
columns2
wallpaper
```

Usage:

```lua
Icon = "target"
```

or:

```lua
Icon = blush.Icons.target
```

Custom asset:

```lua
Icon = "rbxassetid://123456789"
```

---

# 39. Full Example

```lua
local blush = loadstring(game:HttpGet("https://raw.githubusercontent.com/Tracoskibidi/blush/refs/heads/main/blush.lua"))()
if not blush then return end

local window = blush:CreateWindow({
    Title = "example hub",
    Version = "v1.0.0",

    Size = Vector2.new(900, 650),

    Resize = true,
    Draggable = true,
    MinimizeButton = true,

    MenuKey = Enum.KeyCode.RightShift,

    SettingsTab = {
        Enabled = true,
        Name = "Settings",
        Icon = "settings",
    },

    Animations = true,
    Search = true,
    Notifications = true,

    Watermark = false,
    CheckboxList = false,
})

local home = window:AddTab({
    Name = "Home",
    Icon = "home",
})

local combat = window:AddTab({
    Name = "Combat",
    Icon = "target",
})

local player = window:AddTab({
    Name = "Player",
    Icon = "user",
})

local welcome = home:AddLeftSection({
    Name = "Welcome",
    Icon = "home",
})

local info = home:AddRightSection({
    Name = "Info",
    Icon = "user",
})

welcome:AddLabel({
    Text = "blush UI example",
})

welcome:AddToggle({
    Name = "Enabled",
    Default = true,

    Callback = function(value)
        print("enabled:", value)
    end,
})

welcome:AddSlider({
    Name = "Volume",
    Min = 0,
    Max = 100,
    Default = 50,
    Suffix = "%",
})

welcome:AddDropdown({
    Name = "Mode",

    Options = {
        "Normal",
        "Fast",
        "Safe",
    },

    Default = "Normal",
    Searchable = true,
})

info:AddAvatar({
    Name = "Player",
    Player = game:GetService("Players").LocalPlayer,
})

local aim = combat:AddLeftSection({
    Name = "Aim",
    Icon = "target",
})

local visuals = combat:AddRightSection({
    Name = "Visuals",
    Icon = "visuals",
})

aim:AddToggleKey({
    Name = "Aim Assist",
    Default = false,
    Key = Enum.KeyCode.F,
})

aim:AddSlider({
    Name = "FOV",
    Min = 0,
    Max = 360,
    Default = 120,
    Suffix = "px",
})

aim:AddDropdown({
    Name = "Bone",

    Options = {
        "Head",
        "Torso",
        "Arms",
        "Legs",
    },

    Default = "Head",
    Searchable = true,
})

visuals:AddToggleColor({
    Name = "ESP",
    Default = true,
    Color = Color3.fromRGB(255, 255, 255),
})

local movement = player:AddLeftSection({
    Name = "Movement",
    Icon = "gauge",
})

movement:AddToggle({
    Name = "Speed",
    Default = false,
})

movement:AddSlider({
    Name = "WalkSpeed",
    Min = 1,
    Max = 100,
    Default = 16,
})

movement:AddDropdown({
    Name = "Method",

    Options = {
        "WalkSpeed",
        "Velocity",
        "CFrame",
    },

    Default = "WalkSpeed",
})

local scriptSettings = window.Settings:AddLeftSection({
    Name = "Script",
    Icon = "wrench",
})

scriptSettings:AddToggle({
    Name = "Auto Load",
    Default = false,
})

window:SelectTab("Home")
```
