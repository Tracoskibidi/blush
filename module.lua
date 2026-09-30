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

function m.disconnectall()
	while next(m.connections) do
		local name = next(m.connections)

		m.disc(name)
	end
end

m.con("character", m.lp.CharacterAdded, function(char)
	if m.unblockragdoll then
		m.unblockragdoll()
	end

	m.char = char
	m.hum = char:WaitForChild("Humanoid")
	m.hrp = char:WaitForChild("HumanoidRootPart")
end)

-- ftap

m.sintoys = workspace:FindFirstChild(m.lp.Name .. "SpawnedInToys") or workspace:FindFirstChild("PlotItems")
m.ce = m.rs.CharacterEvents
m.ge = m.rs.GrabEvents
m.mt = m.rs.MenuToys

-- utilities

function m.fsearch(parent, name, timeout)
	if not parent then
		return false
	end

	local object = parent:FindFirstChild(name)

	if object then
		return object
	end

	if not parent.Parent then
		return false
	end

	timeout = timeout or 30

	local thread = coroutine.running()
	local done = false
	local added = {}
	local removed = {}

	local function finish(result)
		if done then return end

		done = true

		m.disc(added)
		m.disc(removed)

		task.spawn(thread, result)
	end

	m.con(added, parent.ChildAdded, function(child)
		if child.Name == name then
			finish(child)
		end
	end)

	m.con(removed, parent.Destroying, function()
		finish(false)
	end)

	task.delay(timeout, finish, false)

	return coroutine.yield()
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

-- ragdoll blocker

m.blockragdolldata = {
	motors = {},
	auto = nil,
	sit = nil,
	timer = nil,
	character = nil,
}

function m.unblockragdoll()
	local data = m.blockragdolldata

	if data.timer then
		task.cancel(data.timer)
		data.timer = nil
	end

	for motor in data.motors do
		m.disc(motor)
		data.motors[motor] = nil
	end

	if data.auto then
		m.disc("blockragdollauto")
		data.auto = nil
	end

	if data.sit then
		m.disc("blockragdollsit")
		data.sit = nil
	end

	data.character = nil
end

function m.blockragdoll(time)
	local data = m.blockragdolldata
	local char = m.char
	local hum = m.hum
	local hrp = m.hrp
	local torso = char and char:FindFirstChild("Torso")

	if not torso or not hum or not hrp then
		return
	end

	if data.character ~= char then
		m.unblockragdoll()
		data.character = char
	end

	for _, motor in torso:GetChildren() do
		if motor:IsA("Motor6D") then
			motor.Enabled = true

			if not data.motors[motor] then
				data.motors[motor] = m.con(
					motor,
					motor:GetPropertyChangedSignal("Enabled"),
					function()
						if not motor.Enabled then
							motor.Enabled = true
						end
					end
				)
			end
		end
	end

	if not data.auto then
		data.auto = m.con(
			"blockragdollauto",
			hum:GetPropertyChangedSignal("AutoRotate"),
			function()
				if not hum.AutoRotate then
					hum.AutoRotate = true
				end
			end
		)
	end

	if not data.sit then
		data.sit = m.con(
			"blockragdollsit",
			hum:GetPropertyChangedSignal("Sit"),
			function()
				if not hum.Sit then return end

				hum.Sit = false
				hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)

				m.cas:UnbindAction("JumpRemover")

				local root = hrp:FindFirstChild("RootJoint")

				if root then
					root.Enabled = true
				end
			end
		)
	end

	hum.AutoRotate = true
	hum.Sit = false
	hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)

	m.cas:UnbindAction("JumpRemover")

	local root = hrp:FindFirstChild("RootJoint")

	if root then
		root.Enabled = true
	end

	if data.timer then
		task.cancel(data.timer)
	end

	data.timer = task.delay(time or 1, function()
		data.timer = nil
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
	if not m.fpsdata.connection or not m.fpsdata.connection.Connected then
		m.fpsdata.connection = m.con("fps", m.h, function(dt)
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
