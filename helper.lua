if not game:IsLoaded() then
	game.Loaded:Wait()
end

local pls = game:GetService("Players")
local uis = game:GetService("UserInputService")
local tp = game:GetService("TeleportService")
local rs = game:GetService("ReplicatedStorage")
local tcs = game:GetService("TextChatService")

local lp = pls.LocalPlayer
local g = getgenv()

if g.hinput then
	g.hinput:Disconnect()
end

if g.hchat then
	g.hchat:Disconnect()
end

if g.htp then
	g.htp:Disconnect()
end

local scripts = {
	[Enum.KeyCode.Insert] = "https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source",
	[Enum.KeyCode.Delete] = "https://github.com/AZYsGithub/DexPlusPlus/releases/latest/download/out.lua",
	[Enum.KeyCode.Home] = "https://gitlab.com/upio/cobalt/-/releases/permalink/latest/downloads/Cobalt.luau",
}

g.hinput = uis.InputBegan:Connect(function(input)
	local url = scripts[input.KeyCode]

	if url then
		local ok, err = pcall(function()
			local source = game:HttpGet(url)
			local fn, loaderr = loadstring(source)

			if not fn then
				error(loaderr)
			end

			fn()
		end)

		if not ok then
			warn("[h]", input.KeyCode.Name, "fail:", err)
		end

		return
	end

	if input.KeyCode == Enum.KeyCode.End then
		warn("[h] 3p")

		lp.CameraMode = Enum.CameraMode.Classic
		lp.CameraMinZoomDistance = 10
		lp.CameraMaxZoomDistance = 1000

		task.wait()

		lp.CameraMinZoomDistance = 0
	end
end)

g.hchat = lp.Chatted:Connect(function(message)
	if message == "rj" then
		warn("[h] rj")

		tp:TeleportToPlaceInstance(game.PlaceId, game.JobId, lp)

		while task.wait(0.1) do
			tp:Teleport(game.PlaceId, lp)
		end
	end

	if message == "/shutdown" and game.PlaceId == 6961824067 then
		warn("[h] shutdown")

		tcs.TextChannels.RBXGeneral:SendAsync("Shutting down server...")

		lp.PlayerGui:Destroy()
		lp.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Dead)

		task.wait(0.1)

		local events = rs.DataEvents

		events.UpdateTexturesChoice:FireServer("a")
		events.UpdateLineColorsEvent:FireServer("a")

		task.wait(0.1)

		events.DataRemoteEvent:FireServer()
	end
end)

g.htp = tp.TeleportInitFailed:Connect(function(player, result, message)
	if player == lp then
		warn("[h] tp fail:", result.Name, message)
	end
end)

warn("[h] ready")
