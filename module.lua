local m = {}

-- services

m.pls = game:GetService("Players")
m.run = game:GetService("RunService")
m.uis = game:GetService("UserInputService")
m.cas = game:GetService("ContextActionService")
m.rs = game:GetService("ReplicatedStorage")
m.rf = game:GetService("ReplicatedFirst")
m.light = game:GetService("Lighting")

-- runservice

m.h = m.run.Heartbeat
m.pr = m.run.PreRender
m.pre = m.run.PreSimulation
m.post = m.run.PostSimulation

-- player

m.lp = m.pls.LocalPlayer
m.cam = workspace.CurrentCamera

m.char = m.lp.Character or m.lp.CharacterAdded:Wait()
m.hum = m.char:WaitForChild("Humanoid")
m.hrp = m.char:WaitForChild("HumanoidRootPart")

m.lp.CharacterAdded:Connect(function(char)
	if m.unblockragdoll then
		m.unblockragdoll()
	end

	m.char = char
	m.hum = char:WaitForChild("Humanoid")
	m.hrp = char:WaitForChild("HumanoidRootPart")
end)

-- ftap
m.sintoys = workspace:FindFirstChild(m.lp.Name .. "SpawnedInToys")
m.ce = m.rs.CharacterEvents
m.ge = m.rs.GrabEvents
m.mt = m.rs.MenuToys

-- connections

m.connections = {}

function m.con(name, signal, callback)
	m.disc(name)

	local connection = signal:Connect(callback)
	m.connections[name] = connection

	return connection
end

function m.disc(name)
	local connection = m.connections[name]

	if connection then
		connection:Disconnect()
		m.connections[name] = nil
	end
end

function m.discall()
	for name in m.connections do
		m.connections[name]:Disconnect()
	end

	table.clear(m.connections)
end

-- utilities

function m.fsearch(parent, name, timeout)
	if not parent then return false end

	local object = parent:FindFirstChild(name)
	if object then return object end

	local start = os.clock()
	repeat
		object = parent:FindFirstChild(name)
		if object then return object end
		task.wait()
	until os.clock() - start >= (timeout or 30) or not parent.Parent

	return false
end

m.earlyconnections = {}

function m.blockearly()
	if #m.earlyconnections > 0 then return end

	for _, con in getconnections(m.ge.EndGrabEarly.OnClientEvent) do
		m.earlyconnections[#m.earlyconnections + 1] = con
		con:Disable()
	end
end

function m.unblockearly()
	for i = 1, #m.earlyconnections do
		m.earlyconnections[i]:Enable()
	end

	m.earlyconnections = {}
end

function rejoin()
	m.lp:Destroy()
	
	game:GetService("TeleportService"):TeleportToPlaceInstance(
		game.PlaceId,
		m.lp
	)
	

	task.wait()

	while task.wait(0.1) do
		TeleportService:Teleport(game.PlaceId, lp)
	end
end

m.blockragdolldata = {
	motors = {},
	auto = nil,
	sit = nil,
	timer = nil,
	character = nil,
}

function m.unblockragdoll()
	local d = m.blockragdolldata

	if d.timer then task.cancel(d.timer) end

	for motor, con in d.motors do
		con:Disconnect()
		d.motors[motor] = nil
	end

	if d.auto then d.auto:Disconnect() end
	if d.sit then d.sit:Disconnect() end

	d.timer = nil
	d.auto = nil
	d.sit = nil
	d.character = nil
end

function m.blockragdoll(time)
	local d = m.blockragdolldata
	local char = m.char
	local hum = m.hum
	local hrp = m.hrp
	local torso = char and char:FindFirstChild("Torso")

	if not torso or not hum or not hrp then return end

	if d.character ~= char then
		m.unblockragdoll()
		d.character = char
	end

	for _, motor in torso:GetChildren() do
		if not motor:IsA("Motor6D") then continue end

		motor.Enabled = true

		if d.motors[motor] then continue end

		d.motors[motor] = motor:GetPropertyChangedSignal("Enabled"):Connect(function()
			motor.Enabled = true
		end)
	end

	if not d.auto then
		d.auto = hum:GetPropertyChangedSignal("AutoRotate"):Connect(function()
			hum.AutoRotate = true
		end)
	end

	if not d.sit then
		d.sit = hum:GetPropertyChangedSignal("Sit"):Connect(function()
			if not hum.Sit then return end

			hum.Sit = false
			hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
			m.cas:UnbindAction("JumpRemover")

			local root = hrp:FindFirstChild("RootJoint")
			if root then root.Enabled = true end
		end)
	end

	hum.AutoRotate = true
	hum.Sit = false
	hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
	m.cas:UnbindAction("JumpRemover")

	local root = hrp:FindFirstChild("RootJoint")
	if root then root.Enabled = true end

	if d.timer then task.cancel(d.timer) end

	d.timer = task.delay(time or 1, function()
		d.timer = nil
		m.unblockragdoll()
	end)
end

-- ftap functions

function m.sit(seat)
	if replicatesignal then
		replicatesignal(seat.RemoteCreateSeatWeld, m.hum)
		return
	end

	seat:Sit(m.hum)
end

function m.so(part, times)
	times = times or 1

	for _ = 1, times do
		m.ge.SetNetworkOwner:FireServer(part, part.CFrame)
	end
end

function m.cline(part, cframe)
	m.ge.CreateGrabLine:FireServer(part, cframe or part.CFrame)
end

function m.ragdoll(time)
	m.ce.RagdollRemote:FireServer(m.hrp, time)
end

function m.spawn(name, cframe)
	local toys = m.lp.PlayerGui.MenuGui.Menu.TabContents.Toys.Contents

	if toys:FindFirstChild(name) then
		return m.mt.SpawnToyRemoteFunction:InvokeServer(
			name,
			cframe or m.hrp.CFrame,
			Vector3.zero
		)
	end
end

function m.destroy(name)
	m.mt.DestroyToy:FireServer(name)
end

-- performance

m.pingdata = {
	stat = game:GetService("Stats").Network.ServerStatsItem["Data Ping"],
	current = 0,
	trend = 0,
	lasttime = os.clock(),
	interval = 0.1,
}

function m.ping()
	local data = m.pingdata

	if data.current == 0 then
		data.current = data.stat:GetValue()
	end

	local latest = data.stat:GetValue()

	if latest ~= data.current then
		local now = os.clock()
		local delta = math.max(now - data.lasttime, 0.001)

		data.trend += ((latest - data.current) / delta - data.trend) * 0.5
		data.interval += (delta - data.interval) * 0.25
		data.current = latest
		data.lasttime = now
	end

	return math.round(math.max(
		0,
		data.current + data.trend * math.min(data.interval, 0.25)
	))
end

m.fpsdata = {
	value = 0,
	connection = nil,
}

function m.fps()
	if not m.fpsdata.connection then
		m.fpsdata.connection = m.h:Connect(function(dt)
			m.fpsdata.value = math.round(1 / dt)
		end)
	end

	return m.fpsdata.value
end

-- players

function m.players()
	local result = {}
	local players = m.pls:GetPlayers()

	for index = 1, #players do
		local player = players[index]

		if player ~= m.lp then
			result[#result + 1] = player
		end
	end

	return result
end

function m.closer(radius)
	local closest = nil
	local distance = radius * radius
	local players = m.pls:GetPlayers()

	for index = 1, #players do
		local player = players[index]

		if player ~= m.lp then
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")

			if root and m.hrp then
				local offset = root.Position - m.hrp.Position
				local dist = offset:Dot(offset)

				if dist <= distance then
					closest = player
					distance = dist
				end
			end
		end
	end

	if closest then
		return closest, math.sqrt(distance)
	end
end

return m
