local blush = loadstring(game:HttpGet("https://raw.githubusercontent.com/Tracoskibidi/blush/refs/heads/main/blush.lua"))()
if not blush then return end

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
})

local home = window:AddTab("Home", "home")
local combat = window:AddTab("Combat", "target")
local player = window:AddTab("Player", "user")

local welcome = home:AddLeftSection("Welcome", "home")
local info = home:AddRightSection("Info", "user")

welcome:AddLabel("blush UI")
welcome:AddToggle("Enabled", true)
welcome:AddSlider("Volume", 0, 100, 50, "%")

welcome:AddDropdown(
    "Mode",
    {"Normal", "Fast", "Safe"},
    "Normal"
)

info:AddAvatar(
    "Player",
    game:GetService("Players").LocalPlayer
)

local aim = combat:AddLeftSection("Aim", "target")
local visuals = combat:AddRightSection("Visuals", "visuals")

aim:AddToggleKey(
    "Aim Assist",
    false,
    Enum.KeyCode.F
)

aim:AddSlider("FOV", 0, 360, 120, "px")

aim:AddDropdown(
    "Bone",
    {"Head", "Torso", "Arms", "Legs"},
    "Head",
    nil,
    nil,
    {
        searchable = true,
    }
)

visuals:AddToggleColor(
    "ESP",
    true,
    Color3.fromRGB(255, 255, 255)
)

visuals:AddColorPicker(
    "Accent",
    Color3.fromRGB(180, 120, 255)
)

local movement = player:AddLeftSection("Movement", "gauge")

movement:AddToggle("Speed", false)
movement:AddSlider("WalkSpeed", 1, 100, 16, "")

movement:AddDropdown(
    "Method",
    {"WalkSpeed", "Velocity", "CFrame"},
    "WalkSpeed"
)

window:SelectTab("Home")
