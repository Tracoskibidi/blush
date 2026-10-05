

```lua
local blush = loadstring(game:HttpGet("https://raw.githubusercontent.com/Tracoskibidi/blush/refs/heads/main/blush.lua"))()
```

---

## Window

```lua
local window = blush:CreateWindow({
	Title = "My Hub",
	Subtitle = "v1.0",
	Size = Vector2.new(650, 500),
})
```

### Window options

```lua
{
	Title = "My Hub",
	Subtitle = "v1.0",
	Size = Vector2.new(650, 500),
	Position = UDim2.fromOffset(300, 200),
	Username = "7orm",
	Logo = "settings",
	LogoColor = Color3.new(1, 1, 1),
	Draggable = true,
	SidebarWidth = 160,
	Roundness = 10,
	Shadow = true,
	Glow = true,
	Transparency = 0,
	Theme = "Default",
	Settings = true,
	SettingsTab = {},
	Watermark = false,
	WatermarkInfo = {},
	Keybinds = false,
	AutoSave = false,
	TopNavigation = false,
}
```

---

## Tabs

```lua
local tab = window:CreateTab({
	Name = "Combat",
	Icon = "swords",
})
```

Also:

```lua
window:AddTab(...)
window:CreateTabGroup(...)
window:GetTab("Combat")
window:SelectTab("Combat")
```

### Tab methods

```lua
tab:Select()
tab:SetName("Combat")
tab:SetIcon("swords")
tab:SetGradient("Rainbow")
tab:SetVisible(true)
tab:GetPage()
```

### Sections

```lua
local left = tab:AddLeftSection({Name = "Main", Icon = "settings"})
local right = tab:AddRightSection({Name = "Extra", Icon = "plus"})
```

Or:

```lua
local section = tab:AddSection({
	Name = "Main",
	Side = "left",
	Icon = "settings",
})
```

---

# Controls

## Label

```lua
section:AddLabel("Hello")
```

```lua
section:AddLabel({
	Text = "Hello",
	Wrap = true,
})
```

## Button

```lua
section:AddButton({
	Name = "Load",
	Callback = function()
	end,
})
```

## Row

```lua
local row = section:AddRow({
	Spacing = 8,
	Height = 30,
})
```

Rows support:

```lua
row:AddButton(...)
row:AddToggle(...)
row:AddKeyPicker(...)
row:AddDropdown(...)
row:AddMultiDropdown(...)
row:AddColorPicker(...)
```

---

## Toggle

```lua
section:AddToggle({
	Name = "Enabled",
	Default = false,
	Callback = function(value)
	end,
})
```

Also:

```lua
section:AddToggle("Enabled", false, function(value)
end)
```

### Toggle + key

```lua
section:AddToggleKey({
	Name = "Fly",
	Default = false,
	Key = Enum.KeyCode.F,
	Callback = function(value)
	end,
})
```

### Toggle + color

```lua
section:AddToggleColor({
	Name = "ESP",
	Default = true,
	Color = Color3.fromRGB(255, 70, 70),
	ToggleCallback = function(value)
	end,
	ColorCallback = function(color)
	end,
})
```

### Toggle + color + key

```lua
section:AddToggleColorKey({
	Name = "ESP",
	Default = true,
	Color = Color3.fromRGB(255, 70, 70),
	Key = Enum.KeyCode.E,
	ToggleCallback = function(value)
	end,
	ColorCallback = function(color)
	end,
	KeyCallback = function(key)
	end,
})
```

---

## Slider

```lua
section:AddSlider({
	Name = "Speed",
	Min = 16,
	Max = 100,
	Default = 16,
	Suffix = " studs",
	Round = 0,
	Callback = function(value)
	end,
})
```

Aliases:

```text
Min / Minimum
Max / Maximum
Default / Value
```

---

## Range Slider

```lua
section:AddRangeSlider({
	Name = "Distance",
	Min = 0,
	Max = 500,
	DefaultMin = 50,
	DefaultMax = 250,
	Suffix = " studs",
	MinimumDistance = 10,
	Callback = function(min, max)
	end,
})
```

Also supports:

```text
ValueMin
ValueMax
Low
High
MinDistance
MinGap
```

---

## Dropdown

```lua
section:AddDropdown({
	Name = "Mode",
	Options = {"Legit", "Rage", "Silent"},
	Default = "Legit",
	Callback = function(value)
	end,
})
```

Supports:

```text
Options / Values / Items
Default / Selected
Searchable
Locked
```

---

## Multi Dropdown

```lua
section:AddMultiDropdown({
	Name = "Modes",
	Options = {"Legit", "Rage", "Silent"},
	Default = {"Legit"},
	Callback = function(values)
	end,
})
```

Also supports:

```text
Options / Values / Items
Default / Selected
Searchable
KeyPicker
KeyPickerLabel
KeyFormatter
Locked
```

---

## Player Dropdown

```lua
section:AddPlayerDropdown({
	Name = "Target",
	Searchable = true,
	Callback = function(player)
	end,
})
```

Supports:

```text
Searchable
MultiSelect
Everyone
PlayersDivider
Icons
Colors
Locked
```

---

## Multi Player Dropdown

```lua
section:AddMultiPlayerDropdown({
	Name = "Targets",
	Default = {},
	Searchable = true,
	Everyone = true,
	Callback = function(players)
	end,
})
```

---

## Input

```lua
section:AddInput({
	Name = "Username",
	Default = "",
	Placeholder = "Username...",
	Callback = function(value)
	end,
})
```

---

## Key Picker

```lua
section:AddKeyPicker({
	Name = "Menu Key",
	Default = Enum.KeyCode.RightShift,
	Callback = function(key)
	end,
})
```

Capture options:

```lua
{
	AllowBlacklisted = true,
	AllowEscape = true,
	KeepDelete = true,
}
```

---

## Color Picker

```lua
section:AddColorPicker({
	Name = "Color",
	Color = Color3.fromRGB(255, 0, 0),
	Callback = function(color)
	end,
})
```

---

## Divider

```lua
section:AddDivider("Combat")
```

Or:

```lua
section:AddDivider({
	Text = "Combat",
})
```

## Separator

```lua
section:AddSeparator()
```

---

## Image

```lua
section:AddImage({
	Name = "Preview",
	Asset = "rbxassetid://123456789",
	Height = 100,
})
```

Also accepts:

```text
Image
```

---

## Avatar

```lua
section:AddAvatar({
	Name = "Player",
	Player = game.Players.LocalPlayer,
})
```

Also supports:

```text
UserId
```

---

## Context Menu

```lua
section:AddContextMenu({
	Name = "Actions",
	Entries = {
		{Name = "Copy", Callback = function() end},
		{Name = "Delete", Callback = function() end},
	},
})
```

---

## Confirm Button

```lua
section:AddConfirmButton({
	Name = "Delete",
	Title = "Delete",
	Body = "Are you sure?",
	Callback = function()
	end,
})
```

---

## Modal Button

```lua
section:AddModalButton({
	Name = "Info",
	Title = "Info",
	Body = "Hello.",
})
```

---

## Button Group

```lua
section:AddButtonGroup({
	Buttons = {
		{Name = "Load", Callback = function() end},
		{Name = "Save", Callback = function() end},
	},
})
```

Also supports:

```text
Spacing
Height
```

---

## Sub Tabs

```lua
local subtabs = section:AddSubTabs({
	{Name = "Main", Icon = "home"},
	{Name = "Extra", Icon = "settings"},
})
```

---

# Window API

```lua
window:CreateTab(...)
window:AddTab(...)
window:CreateTabGroup(...)
window:GetTab(...)
window:SelectTab(...)

window:Notify(...)

window:SetVisible(...)
window:Toggle()

window:SetSize(...)
window:GetSize()

window:SetPosition(...)
window:GetPosition()

window:SetSidebarWidth(...)
window:GetSidebarWidth()

window:SetTopNavigation(...)
window:SetDraggable(...)

window:SetLogo(...)

window:SetGlow(...)
window:SetGlowEnabled(...)
window:SetGlowIntensity(...)
window:SetGlowSize(...)
window:SetGlowAlpha(...)
window:SetGlowColor(...)

window:SetTransparency(...)
window:SetRoundness(...)
window:SetShadowVisible(...)

window:SetSettingsTab(...)
window:GetSettingsTab(...)
window:SetSettingsVisible(...)

window:SetMenuKey(...)

window:SetWatermark(...)
window:SetWatermarkInfo(...)

window:SetKeybindList(...)
window:SetKeybinds(...)

window:SetAutoSave(...)
window:GetAutoSave()

window:SavePreset(...)
window:LoadPreset(...)
window:DeletePreset(...)
window:GetPresets()

window:SetAnimations(...)
window:SetSearch(...)
window:SetNotifications(...)

window:SetTheme(...)
window:GetTheme()

window:SetTitle(...)
window:SetSubtitle(...)

window:SetUsername(...)
window:GetUsername()

window:SetGradient(...)
window:SetTitleGradient(...)
window:GetGradientThemes()

window:GetGui()
window:Destroy()
```

---

# Library API

```lua
blush:CreateWindow(...)
blush:GetSettingsTab()

blush:Notify(...)

blush:SetLocked(element, true)
blush:IsLocked(element)

blush:SetGradient(element, "Rainbow")
blush:GetGradientThemes()

blush:Destroy()
```

---

# Locking

Any supported control can be locked.

```lua
local toggle = section:AddToggle({
	Name = "Premium",
})

toggle:SetLocked(true)
```

Or:

```lua
blush:SetLocked(toggle, true)
```

Check:

```lua
toggle:IsLocked()
```

Or:

```lua
blush:IsLocked(toggle)
```

---

# Gradients

```lua
window:SetGradient(element, "Rainbow")
```

Animated:

```lua
window:SetGradient(element, "Rainbow", true, 1)
```

Title:

```lua
window:SetTitleGradient("Rainbow", true, 1)
```

Available themes:

```lua
local themes = blush:GetGradientThemes()
```

---

# Notifications

```lua
window:Notify("Success", "Loaded!", 5)
```

With config:

```lua
window:Notify({
	Title = "Success",
	Content = "Loaded!",
	Duration = 5,
})
```

Supports:

```text
title
body
duration
action
callback
icon
```

---

# Themes

```lua
window:SetTheme("Default")
```

Custom:

```lua
window:SetTheme({
	Background = Color3.fromRGB(13, 13, 15),
	Main = Color3.fromRGB(19, 19, 21),
	Highlight = Color3.fromRGB(246, 246, 248),
	Accent = Color3.fromRGB(246, 246, 248),
	Font = Color3.fromRGB(235, 235, 239),
	SecondaryText = Color3.fromRGB(113, 113, 116),
})
```

Alpha values:

```text
BackgroundAlpha
MainAlpha
HighlightAlpha
AccentAlpha
FontAlpha
SecondaryTextAlpha
```

Animation:

```lua
Animate = true
```

Get current theme:

```lua
local theme = window:GetTheme()
```

---

# Presets

```lua
window:SavePreset("Main")
window:LoadPreset("Main")
window:DeletePreset("Main")

local presets = window:GetPresets()
```

---

# Icons

```lua
local icons = blush.Icons
```

Use an icon by name:

```lua
Icon = "settings"
```

Get every icon:

```lua
for name, asset in pairs(blush.Icons) do
	print(name, asset)
end
```

---

# example

```lua
local blush = loadstring(game:HttpGet("https://raw.githubusercontent.com/Tracoskibidi/blush/refs/heads/main/blush.lua"))()

local window = blush:CreateWindow({
	Title = "My Hub",
	Size = Vector2.new(650, 500),
})

local tab = window:CreateTab({Name = "Main", Icon = "home"})
local section = tab:AddLeftSection({Name = "Main"})

section:AddToggle({
	Name = "Enabled",
	Default = false,
	Callback = function(value)
		print(value)
	end,
})

section:AddSlider({
	Name = "Speed",
	Min = 16,
	Max = 100,
	Default = 16,
	Callback = function(value)
		print(value)
	end,
})
```
