local m = {}

-- services

m.pls = game:GetService("Players")
m.run = game:GetService("RunService")
m.uis = game:GetService("UserInputService")
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
	m.char = char
	m.hum = char:WaitForChild("Humanoid")
	m.hrp = char:WaitForChild("HumanoidRootPart")
end)

-- ftap

m.ce = m.rs.CharacterEvents
m.ge = m.rs.GrabEvents
m.mt = m.rs.MenuToys

-- connections

m.connections = {}

function m.connect(name, signal, callback)
	m.disconnect(name)

	local connection = signal:Connect(callback)
	m.connections[name] = connection

	return connection
end

function m.disconnect(name)
	local connection = m.connections[name]

	if connection then
		connection:Disconnect()
		m.connections[name] = nil
	end
end

function m.disconnectall()
	for name in m.connections do
		m.connections[name]:Disconnect()
	end

	table.clear(m.connections)
end

-- utilities

function m.fsearch(parent, name, timeout)
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
	local added
	local removed

	local function finish(result)
		if done then
			return
		end

		done = true
		added:Disconnect()
		removed:Disconnect()

		task.spawn(thread, result)
	end

	added = parent.ChildAdded:Connect(function(child)
		if child.Name == name then
			finish(child)
		end
	end)

	removed = parent.Destroying:Connect(function()
		finish(false)
	end)

	task.delay(timeout, finish, false)

	return coroutine.yield()
end

-- ftap functions

function m.sit(seat)
	if replicatesignal then
		replicatesignal(seat.RemoteCreateSeatWeld, m.hum)
		return
	end

	seat:Sit(m.hum)
end

function m.dline(part)
	m.ge.DestroyGrabLine(part)
end

function m.so(part, times)
	times = times or 1

	for _ = 1, times do
		m.ce.SetNetworkOwner:FireServer(part, part.CFrame)
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

-- performance

m.pingdata = {
	stat = game:GetService("Stats").Network.ServerStatsItem["Data Ping"],
	current = 0,
	trend = 0,
	lasttime = os.clock(),
	interval = .1,
}

function m.ping()
	local data = m.pingdata

	if data.current == 0 then
		data.current = data.stat:GetValue()
	end

	local latest = data.stat:GetValue()

	if latest ~= data.current then
		local now = os.clock()
		local delta = math.max(now - data.lasttime, .001)

		data.trend += ((latest - data.current) / delta - data.trend) * .5
		data.interval += (delta - data.interval) * .25
		data.current = latest
		data.lasttime = now
	end

	return math.round(math.max(
		0,
		data.current + data.trend * math.min(data.interval, .25)
	))
end

m.fpsdata = {
	value = 0,
	connection = nil,
}

function m.fps()
	if not m.fpsdata.connection then
		m.fpsdata.connection = m.pr:Connect(function(dt)
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



function m.gp()
	m.connect("grabparts", workspace.ChildAdded, function(grab)
		if grab.Name == "GrabParts" then
			m.grabpart = m.fsearch(m.fsearch(grab, "GrabPart"), "WeldConstraint").Part1

			grab.Destroying:Once(function()
				m.grabpart = nil
			end)
		end
	end)

	return m.grabpart
end


return m
