local m = {}

-- services

m.pls   = game:GetService("Players")
m.run   = game:GetService("RunService")
m.uis   = game:GetService("UserInputService")
m.tween = game:GetService("TweenService")
m.rs    = game:GetService("ReplicatedStorage")
m.rf    = game:GetService("ReplicatedFirst")
m.light = game:GetService("Lighting")
m.gui   = game:GetService("GuiService")
m.tp    = game:GetService("TeleportService")
m.ws    = game:GetService("Workspace")

-- runservice

m.h  = m.run.Heartbeat
m.pr = m.run.PreRender

-- workspace

m.cam = m.ws.CurrentCamera
m.tr  = m.ws.Terrain

-- player

m.lp = m.pls.LocalPlayer
m.bp = m.lp:FindFirstChildOfClass("Backpack")

-- connections

m.connections = {}

function m.connect(name: string, signal: RBXScriptSignal, callback)
	local connection = m.connections[name]

	if connection then
		connection:Disconnect()
	end

	connection          = signal:Connect(callback)
	m.connections[name] = connection

	return connection
end

function m.disconnect(name: string)
	local connection = m.connections[name]

	if connection then
		connection:Disconnect()
		m.connections[name] = nil
	end
end

function m.disconnectall()
	for name, connection in m.connections do
		connection:Disconnect()
		m.connections[name] = nil
	end
end

-- utilities

function m.fsearch(parent: Instance, name: string, timeout: number?)
	local start = os.clock()

	while task.wait() do
		if not parent.Parent then
			return false
		end

		local object = parent:FindFirstChild(name)

		if object then
			return object
		end

		if os.clock() - start >= (timeout or 30) then
			return false
		end
	end
end

-- character

m.char = m.lp.Character or m.lp.CharacterAdded:Wait()
m.hum  = m.fsearch(m.char, "Humanoid", 5)
m.hrp  = m.fsearch(m.char, "HumanoidRootPart", 5)

m.lp.CharacterAdded:Connect(function(char)
	m.char = char
	m.hum  = m.fsearch(char, "Humanoid", 5)
	m.hrp  = m.fsearch(char, "HumanoidRootPart", 5)
end)

-- performance

function m.ping()
	m.pingdata = m.pingdata or {
		stat     = game:GetService("Stats").Network.ServerStatsItem["Data Ping"],
		current  = 0,
		trend    = 0,
		lasttime = os.clock(),
		interval = .1,
	}

	if m.pingdata.current == 0 then
		m.pingdata.current = m.pingdata.stat:GetValue()
	end

	m.pingdata.latest = m.pingdata.stat:GetValue()

	if m.pingdata.latest ~= m.pingdata.current then
		m.pingdata.now   = os.clock()
		m.pingdata.delta = math.max(m.pingdata.now - m.pingdata.lasttime, .001)

		m.pingdata.trend    += ((m.pingdata.latest - m.pingdata.current) / m.pingdata.delta - m.pingdata.trend) * .5
		m.pingdata.interval += (m.pingdata.delta - m.pingdata.interval) * .25
		m.pingdata.current   = m.pingdata.latest
		m.pingdata.lasttime  = m.pingdata.now
	end

	return math.round(math.max(
		0,
		m.pingdata.current + m.pingdata.trend * math.min(m.pingdata.interval, .25)
	))
end

function m.fps()
	m.fpsdata = m.fpsdata or {
		value = 0,
	}

	if not m.fpsdata.connection then
		m.fpsdata.connection = m.pr:Connect(function(dt)
			m.fpsdata.value = math.round(1 / dt)
		end)
	end

	return m.fpsdata.value
end

-- players

function m.players()
	local players = {}

	for _, player in m.pls:GetPlayers() do
		if player ~= m.lp then
			players[#players + 1] = player
		end
	end

	return players
end

function m.closer(radius: number)
	local closest     = nil
	local closestdist = radius * radius

	for _, player in m.pls:GetPlayers() do
		if player ~= m.lp then
			local char = player.Character
			local hrp  = char and char:FindFirstChild("HumanoidRootPart")

			if hrp and m.hrp then
				local offset = hrp.Position - m.hrp.Position
				local dist   = offset:Dot(offset)

				if dist <= closestdist then
					closest     = player
					closestdist = dist
				end
			end
		end
	end

	return closest, closest and math.sqrt(closestdist) or nil
end

return m
