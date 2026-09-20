# blush UI Library

`blush.lua` is a desktop-only Roblox Luau UI library. It is designed to be hosted as a raw GitHub file and loaded with `loadstring(game:HttpGet(...))()`.

> Mobile is intentionally unsupported. On a touch/mobile client the library only sends `Mobile não é suportado.` and stops before creating the interface.

## Files

```text
blush.lua       -- library source; upload this to GitHub
example.lua     -- complete usage example
README.md       -- this documentation
```

## Installation / GitHub loadstring

Upload `blush.lua` to your repository, then use the **raw** GitHub URL:

```lua
local blush = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/USERNAME/REPOSITORY/main/blush.lua"
))()

if not blush then
    return
end
```

The file returns the `blush` library table. The UI is kept hidden until `CreateWindow` is called.

Running the library again automatically cleans up the previous `blush` instance.

---

# Quick start

```lua
local blush = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/USERNAME/REPOSITORY/main/blush.lua"
))()

if not blush then
    return
end

local window = blush:CreateWindow({
    Title = "my hub",
    Version = "v1.0.0",
    MenuKey = Enum.KeyCode.RightShift,
    Settings = true,
    Watermark = false,
    CheckboxList = false,
})

local combat = window:AddTab("Combat", "target")

local aimbot = combat:AddLeftSection("Aimbot", "target")
local visuals = combat:AddRightSection("Visuals", "visuals")

aimbot:AddToggle("Enabled", false, function(value)
    print("aimbot:", value)
end)

aimbot:AddSlider("FOV", 0, 360, 120, "px", function(value)
    print("fov:", value)
end)

visuals:AddColorPicker(
    "ESP color",
    Color3.fromRGB(255, 255, 255),
    function(color, alpha)
        print(color, alpha)
    end
)

window:Notify("blush", "Loaded", 3)
```

---

# Library

## `blush.Version`

Current library version string.

```lua
print(blush.Version)
```

## `blush.Icons`

Built-in icon asset table.

Available names:

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
resize
keyboard
userround
menu
columns2
wallpaper
```

You can use either a built-in icon name:

```lua
window:AddTab("Combat", "target")
```

or a Roblox image asset:

```lua
window:AddTab("Combat", "rbxassetid://123456789")
```

## `blush:CreateWindow(options)`

Creates/configures the single blush window and returns the Window object.

```lua
local window = blush:CreateWindow({
    Title = "blush.",
    Version = "v1.0.0",

    Size = Vector2.new(926, 676),
    Position = UDim2.fromOffset(200, 120),

    MenuKey = Enum.KeyCode.RightShift,

    Settings = true,
    Animations = true,
    Search = true,
    Notifications = true,
    Watermark = false,
    CheckboxList = false,

    Background = "https://example.com/background.png",
    BackgroundOpacity = 65,
    BackgroundBlur = 0,

    NotifyLoaded = true,
})
```

### Window options

| Option | Type | Default | Description |
|---|---|---:|---|
| `Title` / `Name` | string | `"blush."` | Sidebar, reopen button and watermark title. |
| `Version` | string | library version | Sidebar version text. |
| `Size` | `Vector2` | `Vector2.new(926,676)` | Window size. |
| `Position` | `UDim2` | centered | Initial position. |
| `MenuKey` | `EnumItem` / string | `RightShift` | Show/hide key. |
| `Settings` | boolean | `true` | Shows the built-in Settings tab. |
| `Animations` | boolean | saved/default | Enables UI animations. |
| `Search` | boolean | saved/default | Enables page search. |
| `Notifications` | boolean | saved/default | Enables notifications. |
| `Watermark` | boolean | saved/default | Initial watermark state. |
| `CheckboxList` | boolean | saved/default | Initial checkbox-list state. |
| `Background` | string | none | Background source. |
| `BackgroundOpacity` | number | current | Image opacity, `0-100`. |
| `BackgroundBlur` | number | current | Background blur amount. |
| `NotifyLoaded` | boolean | `true` | Sends the initial loaded notification. |

`CreateWindow` returns the same Window object if called more than once from the same loaded library instance.

---

# Window API

## `window:AddTab(name, icon?, group?)`

```lua
local tab = window:AddTab("Combat", "target")
```

Table form:

```lua
local tab = window:AddTab({
    Name = "Combat",
    Icon = "target",
    Group = "main",
})
```

`Group` may be `"main"` or `"other"`. Normal user tabs should generally use `"main"`.

Desktop main tabs retain the library's drag/reorder behavior.

## `window:GetTab(name)`

```lua
local combat = window:GetTab("Combat")
```

Returns the Tab object or `nil`.

## `window:SelectTab(tabOrName)`

```lua
window:SelectTab("Combat")
window:SelectTab(combat)
```

Returns `true` when a tab was found.

## `window:Notify(title, body, duration?, callback?, buttonText?, icon?)`

```lua
window:Notify(
    "Saved",
    "Configuration saved.",
    3,
    nil,
    nil,
    blush.Icons.check
)
```

## `window:SetVisible(value)`

```lua
window:SetVisible(false)
window:SetVisible(true)
```

Uses the normal blush fade/minimize system.

## `window:Toggle()`

```lua
window:Toggle()
```

Equivalent to pressing the configured menu key.

## `window:SetMenuKey(key)`

```lua
window:SetMenuKey(Enum.KeyCode.Insert)
window:SetMenuKey("RightShift")
```

Returns `false` for an invalid key.

## `window:SetWatermark(value)`

```lua
window:SetWatermark(true)
```

## `window:SetCheckboxList(value)`

```lua
window:SetCheckboxList(true)
```

The checkbox list is the compact external panel containing registered checkbox/toggle bindings.

## `window:SetAnimations(value)`

```lua
window:SetAnimations(false)
```

## `window:SetSearch(value)`

```lua
window:SetSearch(true)
```

## `window:SetNotifications(value)`

```lua
window:SetNotifications(true)
```

## `window:SetScale(percent)`

```lua
window:SetScale(100)
window:SetScale(85)
```

Internally clamped to the UI scale range supported by the library.

## `window:SetSettingsVisible(value)`

```lua
window:SetSettingsVisible(false)
```

Shows/hides the built-in Settings category.

## `window:SetBackground(source, opacity?, blur?)`

Supported source formats include the formats accepted by the library's background loader, such as Roblox assets, supported local/custom assets, data URLs and HTTP URLs when the runtime provides the required request/asset APIs.

```lua
window:SetBackground(
    "https://cdn.example.com/background.png",
    70,
    4
)
```

Clear it with:

```lua
window:ClearBackground()
```

Additional controls:

```lua
window:SetBackgroundOpacity(60)
window:SetBackgroundBlur(8)
window:SetBackgroundExcludeSidebar(true)
window:SetAutoBackgroundColors(true)
```

## `window:SetTheme(config)`

```lua
window:SetTheme({
    Background = Color3.fromRGB(15, 15, 16),
    Accent = Color3.fromRGB(245, 245, 247),
    Font = Color3.fromRGB(240, 240, 242),

    BackgroundAlpha = 1,
    AccentAlpha = 1,
    FontAlpha = 1,

    Animate = true,
})
```

## `window:GetTheme()`

```lua
local theme = window:GetTheme()
print(theme.Background, theme.Accent, theme.Font)
```

## `window:SetTitle(value)`

```lua
window:SetTitle("imperial")
```

## `window:SetVersion(value)`

```lua
window:SetVersion("v2.4.0")
```

## `window:GetGui()`

Returns the root `ScreenGui`.

```lua
local gui = window:GetGui()
```

## `window:Destroy()`

Destroys the complete library instance and disconnects tracked connections.

```lua
window:Destroy()
```

---

# Tabs

A Tab owns one page with independent left/right scrolling columns.

```lua
local playerTab = window:AddTab("Player", "user")
```

## `tab:AddSection(title, column?, icon?)`

```lua
local movement = playerTab:AddSection(
    "Movement",
    "left",
    "gauge"
)
```

`column`:
- `"left"`
- `"right"`

## `tab:AddLeftSection(title, icon?)`

```lua
local movement = playerTab:AddLeftSection("Movement", "gauge")
```

## `tab:AddRightSection(title, icon?)`

```lua
local misc = playerTab:AddRightSection("Misc", "wrench")
```

## `tab:Select()`

```lua
playerTab:Select()
```

## `tab:SetName(name)`

```lua
playerTab:SetName("Local Player")
```

## `tab:SetIcon(icon)`

```lua
playerTab:SetIcon("user")
```

## `tab:SetVisible(value)`

```lua
playerTab:SetVisible(false)
```

## `tab:GetPage()`

Returns the internal page object.

---

# Sections

All UI elements are added through a Section.

```lua
local section = tab:AddLeftSection("Example", "sliders")
```

The section header supports the library's normal collapse and desktop movement behavior.

## Targets

Most controls accept an optional final `target` argument. This is primarily used with `AddSubTabs`.

```lua
local subtabs = section:AddSubTabs({
    "Main",
    "Visuals",
    "Misc",
})

section:AddToggle(
    "Enabled",
    false,
    function(value)
        print(value)
    end,
    subtabs:Get("Main")
)
```

---

# Text

## `section:AddLabel(text, wrap?, target?)`

```lua
section:AddLabel("Simple text")

section:AddLabel(
    '<font color="rgb(170,170,180)">RichText works here</font>',
    true
)
```

Returns the `TextLabel`.

---

# Buttons

## `section:AddButton(name, callback?, target?)`

```lua
local button = section:AddButton("Execute", function()
    print("clicked")
end)
```

Returns the `TextButton`.

## `section:AddButtonGroup(buttons, target?)`

```lua
local row = section:AddButtonGroup({
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
})
```

Returns a Row object.

---

# Rows

## `section:AddRow(spacing?, height?, target?)`

```lua
local row = section:AddRow(8, 32)
```

### `row:AddButton(name, callback?)`

```lua
row:AddButton("A", function() end)
row:AddButton("B", function() end)
```

### `row:AddToggle(name, default?, callback?, keybindable?, badge?)`

```lua
local enabled = row:AddToggle(
    "Enabled",
    false,
    function(value)
        print(value)
    end
)
```

`row:Refresh()` manually recalculates the row widths.

---

# Toggle / Checkbox

## `section:AddToggle(name, default?, callback?, target?, keybindable?, badge?)`

```lua
local toggle = section:AddToggle(
    "Enabled",
    false,
    function(value)
        print("Enabled:", value)
    end
)
```

Keybindable checkbox:

```lua
local toggle = section:AddToggle(
    "Aim",
    false,
    function(value) end,
    nil,
    true
)
```

Badge:

```lua
section:AddToggle(
    "New feature",
    false,
    nil,
    nil,
    false,
    "NEW"
)
```

Return:

```lua
toggle:Get()
toggle:Set(true)
toggle:Set(false, false) -- second arg false = do not fire callback

toggle.Object
toggle.Binding
toggle.TextObject
toggle.KeyObject
```

---

# Toggle + keybind

## `section:AddToggleKey(name, default, defaultKey, callback?, keyCallback?, target?, badge?)`

```lua
local control = section:AddToggleKey(
    "Flight",
    false,
    Enum.KeyCode.F,
    function(enabled)
        print("flight:", enabled)
    end,
    function(key)
        print("new key:", key)
    end
)
```

The returned object is the toggle control and also contains its key object.

---

# Toggle + color

## `section:AddToggleColor(name, default, color, toggleCallback?, colorCallback?, target?, keybindable?)`

```lua
local esp = section:AddToggleColor(
    "ESP",
    true,
    Color3.fromRGB(255, 255, 255),
    function(enabled)
        print("esp:", enabled)
    end,
    function(color, alpha)
        print("color:", color, "alpha:", alpha)
    end
)
```

Return:

```lua
esp:Get()
esp:Set(true)

esp.Color:color()
esp.Color:currentalpha()
esp.Color:Set(Color3.fromRGB(255, 0, 0), 0.8)
```

## `section:AddToggleColorKey(...)`

Signature:

```lua
section:AddToggleColorKey(
    name,
    default,
    color,
    defaultKey,
    toggleCallback,
    colorCallback,
    keyCallback,
    target
)
```

Example:

```lua
section:AddToggleColorKey(
    "Chams",
    true,
    Color3.fromRGB(170, 120, 255),
    Enum.KeyCode.Q,
    function(enabled) end,
    function(color, alpha) end,
    function(key) end
)
```

---

# Slider

## `section:AddSlider(name, min, max, default, suffix?, callback?, target?)`

```lua
local speed = section:AddSlider(
    "Speed",
    0,
    100,
    16,
    "",
    function(value)
        print(value)
    end
)

print(speed:Get())
speed:Set(30)
```

---

# Range slider

## `section:AddRangeSlider(name, min, max, defaultMin, defaultMax, suffix?, callback?, target?)`

```lua
local distance = section:AddRangeSlider(
    "Distance",
    0,
    5000,
    100,
    1500,
    "m",
    function(low, high)
        print(low, high)
    end
)

local low, high = distance:Get()
distance:Set(250, 2000)
distance:Set(250, 2000, false)
```

---

# Dropdown

## `section:AddDropdown(name, options, default, callback?, target?, config?)`

Basic:

```lua
local mode = section:AddDropdown(
    "Mode",
    {
        "Legit",
        "Rage",
        "Silent",
    },
    "Legit",
    function(value)
        print(value)
    end
)
```

Searchable:

```lua
section:AddDropdown(
    "Bone",
    {
        "Head",
        "Torso",
        "Right Arm",
        "Left Arm",
        "Right Leg",
        "Left Leg",
    },
    "Head",
    nil,
    nil,
    {
        searchable = true,
    }
)
```

Rich options:

```lua
section:AddDropdown(
    "Category",
    {
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
    "Target",
    nil,
    nil,
    {
        searchable = true,
    }
)
```

Config fields:

```lua
{
    searchable = true,

    dividers = {
        ["Value"] = "Divider title",
    },

    icons = {
        ["Value"] = "rbxassetid://...",
    },

    colors = {
        ["Value"] = Color3.fromRGB(255, 100, 100),
    },
}
```

Return:

```lua
mode:Get()
mode:Set("Rage")
mode:Set("Rage", false)
mode:SetOptions({"A", "B", "C"}, "B")
```

---

# Multi dropdown

## `section:AddMultiDropdown(name, options, default?, callback?, target?)`

```lua
local hitboxes = section:AddMultiDropdown(
    "Hitboxes",
    {
        "Head",
        "Torso",
        "Arms",
        "Legs",
    },
    {
        "Head",
        "Torso",
    },
    function(values)
        for _, value in ipairs(values) do
            print(value)
        end
    end
)
```

Return:

```lua
hitboxes:Get()
hitboxes:Set({"Head", "Arms"})
hitboxes:Set({"Head"}, false)
hitboxes:SetOptions({"Head", "Torso"})
```

---

# Player dropdown

## `section:AddPlayerDropdown(name, options?, default?, callback?, target?, config?)`

It combines custom entries with current Roblox players.

```lua
local target = section:AddPlayerDropdown(
    "Target",
    {
        {
            Value = "Closest",
            Icon = blush.Icons.target,
        },
        {
            Value = "Random",
            Icon = blush.Icons.user,
        },
    },
    "Closest",
    function(value)
        print(value)
    end,
    nil,
    {
        searchable = true,
        playersDivider = "Players",
        everyone = true,
    }
)
```

Player rows use the actual Roblox avatar/headshot.

Config:

```lua
{
    searchable = true,      -- default true
    playersDivider = "Players",
    multiselect = false,
    everyone = true,        -- default true

    icons = {},
    colors = {},
}
```

Return:

```lua
target:Get()
target:Set(value)
target:Set(value, false)
target:SetOptions(newCustomOptions)
target.Multi
```

## `section:AddMultiPlayerDropdown(name, default?, callback?, target?, config?)`

```lua
local players = section:AddMultiPlayerDropdown(
    "Players",
    {"Everyone"},
    function(values)
        print(#values)
    end,
    nil,
    {
        searchable = true,
        everyone = true,
    }
)
```

---

# Input

## `section:AddInput(name, default?, placeholder?, callback?, target?)`

```lua
local input = section:AddInput(
    "Name",
    "",
    "type here...",
    function(text)
        print(text)
    end
)
```

Returns the actual `TextBox`.

```lua
print(input.Text)
input.Text = "hello"
```

The callback fires on `FocusLost`.

---

# Key picker

## `section:AddKeyPicker(name, defaultKey?, callback?, target?)`

```lua
local key = section:AddKeyPicker(
    "Menu key",
    Enum.KeyCode.RightShift,
    function(value)
        print(value)
    end
)

print(key:Get())
key:Set(Enum.KeyCode.Insert)
key:Set("F", false)
```

Mouse buttons supported by the picker use `Enum.UserInputType`.

---

# Color picker

## `section:AddColorPicker(name, color, callback?, target?)`

```lua
local picker = section:AddColorPicker(
    "Accent",
    Color3.fromRGB(255, 255, 255),
    function(color, alpha)
        print(color, alpha)
    end
)
```

Color state API:

```lua
picker:color()
picker:currentalpha()

picker:Set(
    Color3.fromRGB(255, 80, 120),
    0.75
)

picker:Set(
    Color3.fromRGB(255, 80, 120),
    0.75,
    false
)
```

The picker also supports the library's rainbow/fade behavior through its UI.

---

# Divider / separator

## `section:AddDivider(text?, target?)`

```lua
section:AddDivider("Advanced")
```

Without text:

```lua
section:AddDivider()
```

Returns the divider Frame.

## `section:AddSeparator(target?)`

```lua
section:AddSeparator()
```

Alias for a divider without text.

---

# Progress bar

## `section:AddProgressBar(name, default?, suffix?, target?)`

```lua
local progress = section:AddProgressBar(
    "Download",
    35,
    "%"
)

print(progress:Get())
progress:Set(80)
```

Range is `0-100`.

---

# Radio buttons

## `section:AddRadio(name, options, default?, callback?, target?)`

```lua
local radio = section:AddRadio(
    "Mode",
    {
        "A",
        "B",
        "C",
    },
    "A",
    function(value)
        print(value)
    end
)

radio:Set("B")
print(radio:Get())
```

---

# Status / badge

## `section:AddBadge(name, text?, color?, target?)`

```lua
local status = section:AddBadge(
    "Status",
    "Ready",
    Color3.fromRGB(110, 210, 150)
)

status:SetText("Running")
status:SetColor(Color3.fromRGB(255, 190, 80))
```

---

# Image

## `section:AddImage(name?, asset, height?, target?)`

```lua
local image = section:AddImage(
    "Preview",
    "rbxassetid://123456789",
    96
)

image.Image = "rbxassetid://987654321"
```

Returns the `ImageLabel`.

---

# Avatar

## `section:AddAvatar(name, playerOrUserId?, target?)`

```lua
section:AddAvatar(
    "Current player",
    game:GetService("Players").LocalPlayer
)
```

or:

```lua
section:AddAvatar("User", 123456789)
```

Returns the holder Frame.

---

# Loading components

## `section:AddLoadingSpinner(name, target?)`

```lua
local spinner = section:AddLoadingSpinner("Loading")
```

Returns the spinner ImageLabel.

## `section:AddLoadingBar(name, target?)`

```lua
local bar = section:AddLoadingBar("Loading")
```

Returns the animated bar Frame.

---

# Context menu

## `section:AddContextMenu(name, entries, target?)`

```lua
section:AddContextMenu("Actions", {
    {
        Text = "Open",
        Icon = blush.Icons.right,
        Callback = function()
            print("open")
        end,
    },

    {
        Text = "Duplicate",
        Callback = function()
            print("duplicate")
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
})
```

A context menu is useful for secondary actions that do not need permanent space in the groupbox.

---

# Confirmation dialog

## `section:AddConfirmButton(name, title, body, callback, target?)`

```lua
section:AddConfirmButton(
    "Reset",
    "Reset settings",
    "Reset all settings?",
    function()
        print("confirmed")
    end
)
```

---

# Modal

## `section:AddModalButton(name, title, body, target?)`

```lua
section:AddModalButton(
    "About",
    "About",
    "blush UI example"
)
```

---

# Section tabs / subtabs

## `section:AddSubTabs(names)`

```lua
local subtabs = section:AddSubTabs({
    "Main",
    "Visuals",
    "Misc",
})
```

Get a subtab container and place controls inside it:

```lua
section:AddToggle(
    "Enabled",
    true,
    nil,
    subtabs:Get("Main")
)

section:AddSlider(
    "FOV",
    0,
    360,
    120,
    "px",
    nil,
    subtabs:Get("Main")
)

section:AddToggle(
    "Boxes",
    true,
    nil,
    subtabs:Get("Visuals")
)
```

API:

```lua
subtabs:Get("Main")
subtabs:Select("Visuals")

subtabs:SetCollapsed(true)
subtabs:SetCollapsed(false, false)

print(subtabs:IsCollapsed())
```

On desktop, section-tab drag/reorder behavior remains available.

---

# Complete example

```lua
local blush = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/USERNAME/REPOSITORY/main/blush.lua"
))()

if not blush then
    return
end

local players = game:GetService("Players")

local window = blush:CreateWindow({
    Title = "example hub",
    Version = "v1.0.0",

    MenuKey = Enum.KeyCode.RightShift,

    Settings = true,
    Animations = true,
    Search = true,
    Notifications = true,

    Watermark = false,
    CheckboxList = false,

    NotifyLoaded = true,
})

local home = window:AddTab("Home", "home")
local combat = window:AddTab("Combat", "combat")
local player = window:AddTab("Player", "user")
local misc = window:AddTab("Misc", "wrench")

local welcome = home:AddLeftSection("Welcome", "home")
local session = home:AddRightSection("Session", "user")

welcome:AddLabel(
    "blush UI library example"
)

welcome:AddButton("Notification", function()
    window:Notify(
        "Example",
        "Button clicked.",
        3,
        nil,
        nil,
        blush.Icons.check
    )
end)

local enabled = welcome:AddToggle(
    "Enabled",
    true,
    function(value)
        print("enabled:", value)
    end
)

welcome:AddInput(
    "Profile name",
    "",
    "default",
    function(value)
        print("profile:", value)
    end
)

session:AddAvatar(
    "Local player",
    players.LocalPlayer
)

session:AddPlayerDropdown(
    "Target",
    {
        {
            Value = "Closest",
            Icon = blush.Icons.target,
        },
    },
    "Closest",
    function(value)
        print("target:", value)
    end,
    nil,
    {
        searchable = true,
        playersDivider = "Players",
        everyone = true,
    }
)

local aim = combat:AddLeftSection("Aim", "target")
local esp = combat:AddRightSection("Visuals", "visuals")

aim:AddToggleKey(
    "Aim assist",
    false,
    Enum.KeyCode.F,
    function(value)
        print("aim:", value)
    end,
    function(key)
        print("aim key:", key)
    end
)

aim:AddSlider(
    "FOV",
    0,
    360,
    120,
    "px",
    function(value)
        print("fov:", value)
    end
)

aim:AddRangeSlider(
    "Distance",
    0,
    5000,
    0,
    1500,
    "m"
)

aim:AddDropdown(
    "Bone",
    {
        "Head",
        "Torso",
        "Right Arm",
        "Left Arm",
        "Right Leg",
        "Left Leg",
    },
    "Head",
    function(value)
        print("bone:", value)
    end,
    nil,
    {
        searchable = true,
    }
)

aim:AddMultiDropdown(
    "Hitboxes",
    {
        "Head",
        "Torso",
        "Arms",
        "Legs",
    },
    {
        "Head",
        "Torso",
    }
)

esp:AddToggleColorKey(
    "ESP",
    true,
    Color3.fromRGB(255, 255, 255),
    Enum.KeyCode.Q,
    function(value)
        print("esp:", value)
    end,
    function(color, alpha)
        print("esp color:", color, alpha)
    end,
    function(key)
        print("esp key:", key)
    end
)

esp:AddColorPicker(
    "Accent",
    Color3.fromRGB(180, 120, 255)
)

local movement = player:AddLeftSection("Movement", "gauge")
local utility = player:AddRightSection("Utility", "wrench")

movement:AddToggle("Speed", false)
movement:AddSlider("WalkSpeed", 1, 100, 16, "")

movement:AddDropdown(
    "Method",
    {
        "WalkSpeed",
        "Velocity",
        "CFrame",
    },
    "WalkSpeed"
)

utility:AddRadio(
    "Mode",
    {
        "Normal",
        "Safe",
        "Fast",
    },
    "Normal"
)

local status = utility:AddBadge(
    "Status",
    "Ready",
    Color3.fromRGB(110, 210, 150)
)

utility:AddButton("Set running", function()
    status:SetText("Running")
    status:SetColor(
        Color3.fromRGB(255, 190, 80)
    )
end)

local advanced = misc:AddLeftSection(
    "Advanced",
    "sliders"
)

local subtabs = advanced:AddSubTabs({
    "Main",
    "Network",
    "Visual",
})

advanced:AddToggle(
    "Main option",
    true,
    nil,
    subtabs:Get("Main")
)

advanced:AddSlider(
    "Rate",
    1,
    100,
    50,
    "%",
    nil,
    subtabs:Get("Network")
)

advanced:AddColorPicker(
    "Color",
    Color3.fromRGB(255, 100, 140),
    nil,
    subtabs:Get("Visual")
)

local actions = misc:AddRightSection(
    "Actions",
    "extras"
)

actions:AddContextMenu("Context Menu", {
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
})

actions:AddConfirmButton(
    "Confirm",
    "Confirm action",
    "Are you sure?",
    function()
        window:Notify(
            "Confirmed",
            "Action confirmed.",
            2
        )
    end
)

actions:AddModalButton(
    "About",
    "About",
    "Complete blush UI example."
)

actions:AddProgressBar(
    "Progress",
    68,
    "%"
)

actions:AddLoadingSpinner("Loading Spinner")
actions:AddLoadingBar("Loading Bar")

window:SelectTab("Home")
```

---

# Recommended repository structure

```text
your-repository/
├─ blush.lua
├─ example.lua
└─ README.md
```

Then the loader is simply:

```lua
local blush = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/YOUR_NAME/YOUR_REPOSITORY/main/blush.lua"
))()
```

Do **not** use the regular GitHub page URL. Use the `raw.githubusercontent.com` URL.

---

# Runtime notes

- Desktop only.
- The library creates one window per loaded instance.
- Loading the script again destroys the prior blush runtime before creating a new one.
- `RightShift` is the default menu key unless changed by saved settings or `CreateWindow`.
- The built-in Settings page contains interface, theme, background and config controls.
- File-backed config/theme/background features depend on the executor/runtime exposing the relevant file/request/custom-asset functions.
- HTTP `loadstring` usage depends on the environment providing `game:HttpGet` and `loadstring`.
- Search filters controls in the currently selected page.
- The optional target argument on controls is intended for subtab containers returned by `AddSubTabs():Get(name)`.
