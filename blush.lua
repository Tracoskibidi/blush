local state = { base = getfenv() }
setmetatable(state, { __index = state.base })
setfenv(1, state)

function invoke(callback, ...)
	return true, callback(...)
end

players = game:GetService("Players")
uis = game:GetService("UserInputService")
tweenservice = game:GetService("TweenService")
runservice = game:GetService("RunService")
stats = game:GetService("Stats")
textservice = game:GetService("TextService")
httpservice = game:GetService("HttpService")
guiservice = game:GetService("GuiService")
contextactionservice = game:GetService("ContextActionService")
assetservice = game:GetService("AssetService")

player = players.LocalPlayer
parent = gethui and gethui() or player:WaitForChild("PlayerGui")
env = state

runtimebridge = parent:FindFirstChild("blush_runtime")
if runtimebridge and runtimebridge:IsA("BindableEvent") then
	runtimebridge:Fire()
	runtimebridge:Destroy()
end

if uis.TouchEnabled then
	task.defer(function()
		game:GetService("StarterGui"):SetCore("SendNotification", {
			Title = "blush UI",
			Text = "Mobile is not supported.",
			Duration = 5,
		})
	end)

	return
end

runtimebridge = Instance.new("BindableEvent")
runtimebridge.Name = "blush_runtime"
runtimebridge.Parent = parent

gui = nil
watermarkgui = nil
connections = {}

function connect(signal, callback)
	if #connections >= 64
		and #connections % 32 == 0
	then
		for index = #connections, 1, -1 do
			if not connections[index].Connected then
				table.remove(connections, index)
			end
		end
	end

	local connection = signal:Connect(callback)
	table.insert(connections, connection)
	return connection
end

env.__blush_cleanup = function()
	runservice:UnbindFromRenderStep("__blush_force_cursor")
	contextactionservice:UnbindAction("__blush_menu_key")
	if interactionrenderconnection
		and interactionrenderconnection.Connected
	then
		interactionrenderconnection:Disconnect()
		interactionrenderconnection = nil
	end

	if pickeranimationconnection
		and pickeranimationconnection.Connected
	then
		pickeranimationconnection:Disconnect()
		pickeranimationconnection = nil
	end

	if animateduiconnection
		and animateduiconnection.Connected
	then
		animateduiconnection:Disconnect()
		animateduiconnection = nil
	end

	if rainbowtextconnection
		and rainbowtextconnection.Connected
	then
		rainbowtextconnection:Disconnect()
		rainbowtextconnection = nil
	end

	if watermarkstatsconnection
		and watermarkstatsconnection.Connected
	then
		watermarkstatsconnection:Disconnect()
		watermarkstatsconnection = nil
	end

	local autosavetask = env.__blush_autosave_task
	if autosavetask
		and coroutine.status(autosavetask) == "suspended"
	then
		pcall(task.cancel, autosavetask)
	end
	env.__blush_autosave_task = nil

	local settingstask = env.__blush_save_task
	if settingstask
		and coroutine.status(settingstask) == "suspended"
	then
		pcall(task.cancel, settingstask)
	end
	env.__blush_save_task = nil

	if restorecursorstate then
		restorecursorstate()
	end

	if destroybackgroundeditable then
		destroybackgroundeditable()
	end

	for _, connection in ipairs(connections) do
		if connection.Connected then
			connection:Disconnect()
		end
	end

	table.clear(connections)

	if gui and gui.Parent then
		gui:Destroy()
	end

	if mobilemenugui and mobilemenugui.Parent then
		mobilemenugui:Destroy()
	end

	if reopengui and reopengui.Parent then
		reopengui:Destroy()
	end

	if watermarkgui and watermarkgui.Parent then
		watermarkgui:Destroy()
	end

	if runtimebridge and runtimebridge.Parent then
		runtimebridge:Destroy()
	end

	env.__blush_notify = nil
	env.__blush_background = nil
end

table.insert(
	connections,
	runtimebridge.Event:Connect(env.__blush_cleanup)
)

old = parent:FindFirstChild("blush")

if old then
	old:Destroy()
end

oldmobile = parent:FindFirstChild("blush_mobile")
if oldmobile then
	oldmobile:Destroy()
end

oldreopen = parent:FindFirstChild("blush_reopen")
if oldreopen then
	oldreopen:Destroy()
end

oldwatermark = parent:FindFirstChild("blush_watermark")
if oldwatermark then
	oldwatermark:Destroy()
end

function playerthumb(targetplayer)
	local userid = targetplayer and targetplayer.UserId or player.UserId
	return string.format(
		"rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150",
		userid
	)
end

thumbnail = playerthumb(player)

function getplayerthumbnail(targetplayer)
	return playerthumb(targetplayer)
end

gui = Instance.new("ScreenGui")
gui.Name = "blush"
gui.IgnoreGuiInset = not uis.TouchEnabled
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
if uis.TouchEnabled then
	gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
end
gui.Parent = parent

watermarkgui = Instance.new("ScreenGui")
watermarkgui.Name = "blush_watermark"
watermarkgui.IgnoreGuiInset = not uis.TouchEnabled
watermarkgui.ResetOnSpawn = false
watermarkgui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
watermarkgui.DisplayOrder = 1000
if uis.TouchEnabled then
	watermarkgui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
end
watermarkgui.Parent = parent

theme = {
	-- exact Default preset from first render; all theme bindings start in the correct role
	window = Color3.fromRGB(13, 13, 15),
	sidebar = Color3.fromRGB(10, 10, 11),

	section = Color3.fromRGB(26, 26, 28),
	input = Color3.fromRGB(19, 19, 21),
	hover = Color3.fromRGB(31, 31, 34),

	track = Color3.fromRGB(44, 44, 47),
	border = Color3.fromRGB(41, 41, 44),

	scroll = Color3.fromRGB(42, 42, 45),
	scrollTrack = Color3.fromRGB(24, 24, 26),
	popup = Color3.fromRGB(16, 16, 18),
	notification = Color3.fromRGB(22, 22, 24),

	text = Color3.fromRGB(235, 235, 239),
	text2 = Color3.fromRGB(173, 173, 176),
	text3 = Color3.fromRGB(113, 113, 116),

	white = Color3.fromRGB(246, 246, 248),
	black = Color3.fromRGB(14, 14, 15),
	font = Color3.fromRGB(235, 235, 239),

	accentAlpha = 1,
	backgroundAlpha = 1,
	fontAlpha = 1,
}

icons = {
	home = "rbxassetid://98755624629571",
	combat = "rbxassetid://134242818164054",
	visuals = "rbxassetid://100033680381365",
	extras = "rbxassetid://138635884129147",
	farming = "rbxassetid://85261952080359",
	settings = "rbxassetid://80758916183665",
	search = "rbxassetid://121018724060431",

	target = "rbxassetid://87563802520297",
	palette = "rbxassetid://86350350950064",
	filter = "rbxassetid://108829540827529",
	gauge = "rbxassetid://110273524101447",
	wrench = "rbxassetid://112148279212860",
	sliders = "rbxassetid://85538382643347",
	user = "rbxassetid://136485052187963",

	check = "rbxassetid://93898873302694",
	down = "rbxassetid://134243273101015",
	right = "rbxassetid://92473583511724",
	resize = "rbxassetid://79701968834514",
	keyboard = "rbxassetid://121474456068237",
	userround = "rbxassetid://136485052187963",
	menu = "rbxassetid://77021539815611",
	columns2 = "rbxassetid://113004100221850",
	wallpaper = "rbxassetid://74682121235494",
}

font = Enum.Font.BuilderSans
medium = Enum.Font.BuilderSansMedium
bold = Enum.Font.BuilderSansBold

animationsenabled = true
searchenabled = true
uitransparency = 0
menukey = Enum.KeyCode.RightShift
keypickercapturing = false
keypickersuppress = nil


defaultnotificationduration = 3.5
maxnotifications = 5

ti = TweenInfo.new(
	.20,
	Enum.EasingStyle.Quint,
	Enum.EasingDirection.Out
)

fastti = TweenInfo.new(
	.16,
	Enum.EasingStyle.Quint,
	Enum.EasingDirection.Out
)

hoverti = TweenInfo.new(
	.18,
	Enum.EasingStyle.Quart,
	Enum.EasingDirection.Out
)

checkti = TweenInfo.new(
	.16,
	Enum.EasingStyle.Quint,
	Enum.EasingDirection.Out
)

tabti = TweenInfo.new(
	.20,
	Enum.EasingStyle.Quint,
	Enum.EasingDirection.Out
)

sectionti = TweenInfo.new(
	.24,
	Enum.EasingStyle.Quint,
	Enum.EasingDirection.Out
)

dropti = TweenInfo.new(
	.18,
	Enum.EasingStyle.Quint,
	Enum.EasingDirection.Out
)

themekeys = {
	"window",
	"sidebar",
	"section",
	"input",
	"hover",
	"track",
	"border",
	"scroll",
	"scrollTrack",
	"popup",
	"notification",
	"text",
	"text2",
	"text3",
	"white",
	"black",
}

themebindings = {}

function themerole(color)
	if typeof(color) ~= "Color3" then
		return nil
	end

	for _, key in ipairs(themekeys) do
		if color == theme[key] then
			return key
		end
	end

	return nil
end

function bindtheme(object, property, value)
	local role = themerole(value)

	if not role then
		return
	end

	themebindings[#themebindings + 1] = {
		object = object,
		property = property,
		role = role,
	}

	registeraccentalpha(
		object,
		property,
		role
	)

	registerfontalpha(
		object,
		property,
		role
	)

	local alphafield =
		alphaproperty(object, property)

	if alphafield then
		if role == "white"
			or role == "black"
		then
			local entries =
				env.__blush_accent_alpha[object]

			if entries
				and entries[alphafield] ~= nil
			then
				object[alphafield] =
					effectiveaccentalpha(
						entries[alphafield]
					)
			end

		elseif role == "text"
			or role == "text2"
			or role == "text3"
		then
			local entries =
				env.__blush_font_alpha[object]

			if entries
				and entries[alphafield] ~= nil
			then
				object[alphafield] =
					effectivefontalpha(
						entries[alphafield]
					)
			end
		end
	end
end

function syncbinding(object, property, value)
	local role = themerole(value)

	if not role then
		return
	end

	for i = #themebindings, 1, -1 do
		local binding = themebindings[i]

		if not binding.object.Parent then
			table.remove(themebindings, i)
		elseif binding.object == object
			and binding.property == property
		then
			binding.role = role

			if role == "white"
				or role == "black"
			then
				registeraccentalpha(
					object,
					property,
					role
				)
			end

			if role == "text"
				or role == "text2"
				or role == "text3"
			then
				registerfontalpha(
					object,
					property,
					role
				)
			end

			return
		end
	end

	bindtheme(object, property, value)
end



env.__blush_accent_alpha = setmetatable({}, {
	__mode = "k",
})

function alphaproperty(object, colorproperty)
	if colorproperty == "BackgroundColor3"
		and object:IsA("GuiObject")
	then
		return "BackgroundTransparency"
	end

	if colorproperty == "TextColor3"
		and (object:IsA("TextLabel")
			or object:IsA("TextButton")
			or object:IsA("TextBox"))
	then
		return "TextTransparency"
	end

	if colorproperty == "ImageColor3"
		and (object:IsA("ImageLabel")
			or object:IsA("ImageButton"))
	then
		return "ImageTransparency"
	end

	if colorproperty == "ScrollBarImageColor3"
		and object:IsA("ScrollingFrame")
	then
		return "ScrollBarImageTransparency"
	end

	if colorproperty == "Color"
		and object:IsA("UIStroke")
	then
		return "Transparency"
	end

	return nil
end

function registeraccentalpha(object, colorproperty, role)
	if role ~= "white"
		and role ~= "black"
	then
		return
	end

	local property =
		alphaproperty(object, colorproperty)

	if not property then
		return
	end

	local entries =
		env.__blush_accent_alpha[object]

	if not entries then
		entries = {}
		env.__blush_accent_alpha[object] = entries
	end

	if entries[property] == nil then
		local ok, value = invoke(function()
			return object[property]
		end)

		if ok then
			entries[property] = value
		end
	end
end

function setaccentalphabase(object, property, value)
	local entries =
		env.__blush_accent_alpha[object]

	if entries
		and entries[property] ~= nil
	then
		entries[property] = value
		return true
	end

	return false
end

function effectiveaccentalpha(value)
	return 1
		- (1 - value)
			* math.clamp(
				theme.accentAlpha or 1,
				0,
				1
			)
end

function applyaccentalpha(value)
	theme.accentAlpha =
		math.clamp(value or 1, 0, 1)

	for object, entries in pairs(
		env.__blush_accent_alpha
	) do
		if not object.Parent then
			env.__blush_accent_alpha[object] = nil
		else
			for property, base in pairs(entries) do
				invoke(function()
					object[property] =
						effectiveaccentalpha(base)
				end)
			end
		end
	end
end

env.__blush_font_alpha = setmetatable({}, {
	__mode = "k",
})

function registerfontalpha(object, colorproperty, role)
	if role ~= "text"
		and role ~= "text2"
		and role ~= "text3"
	then
		return
	end

	local property =
		alphaproperty(object, colorproperty)

	if not property then
		return
	end

	local entries =
		env.__blush_font_alpha[object]

	if not entries then
		entries = {}
		env.__blush_font_alpha[object] = entries
	end

	if entries[property] == nil then
		local ok, value = invoke(function()
			return object[property]
		end)

		if ok then
			entries[property] = value
		end
	end
end

function setfontalphabase(object, property, value)
	local entries =
		env.__blush_font_alpha[object]

	if entries
		and entries[property] ~= nil
	then
		entries[property] = value
		return true
	end

	return false
end

function effectivefontalpha(value)
	return 1
		- (1 - value)
			* math.clamp(
				theme.fontAlpha or 1,
				0,
				1
			)
end

function applyfontalpha(value)
	theme.fontAlpha =
		math.clamp(value or 1, 0, 1)

	for object, entries in pairs(
		env.__blush_font_alpha
	) do
		if not object.Parent then
			env.__blush_font_alpha[object] = nil
		else
			for property, base in pairs(entries) do
				invoke(function()
					object[property] =
						effectivefontalpha(base)
				end)
			end
		end
	end
end

transparencyroles = {
	window = true,
	sidebar = true,
	section = true,
	input = true,
	hover = true,
	popup = true,
	notification = true,
}

transparencybase = setmetatable({}, {
	__mode = "k",
})

env.__blush_background_visibility = env.__blush_background_visibility or 0

function effectivetransparency(value, role)
	return 1
		- (1 - value)
			* math.clamp(
				theme.backgroundAlpha or 1,
				0,
				1
			)
end

function applyuitransparency(value)
	uitransparency = math.clamp((tonumber(value) or 0) / 100, 0, .90)

	for object, data in pairs(transparencybase) do
		if object and object.Parent then
			local detached =
				draglayer
				and draglayer.Parent
				and object:IsDescendantOf(draglayer)

			object.BackgroundTransparency =
				effectivetransparency(
					data.base,
					data.role
				)
		end
	end

	if window and window.Parent then
		window.GroupTransparency = uitransparency
	end

	if popuplayer and popuplayer.Parent then
		popuplayer.GroupTransparency = uitransparency
	end

	if draglayer and draglayer.Parent then
		draglayer.GroupTransparency = 0
	end
end

mobilefontscale = 1
env.__blush_mobilefontsizes = setmetatable({}, { __mode = "k" })

function registermobiletext(object)
	if not uis.TouchEnabled or not object then
		return
	end

	if object:IsA("TextLabel")
		or object:IsA("TextButton")
		or object:IsA("TextBox")
	then
		local base = env.__blush_mobilefontsizes[object] or object.TextSize
		env.__blush_mobilefontsizes[object] = base
		object.TextSize = math.max(9, math.floor(base * mobilefontscale + .5))
	end
end

function rawnew(class, properties)
	local object = Instance.new(class)

	for property, value in pairs(properties or {}) do
		object[property] = value
	end

	return object
end

function new(class, properties)
	local object = Instance.new(class)

	for property, value in pairs(properties or {}) do
		object[property] = value
	end

	if (class == "TextLabel" or class == "TextButton")
		and (not properties or properties.RichText == nil)
	then
		object.RichText = true
	end

	for property, value in pairs(properties or {}) do
		if property == "BackgroundColor3"
			or property == "TextColor3"
			or property == "ImageColor3"
			or property == "ScrollBarImageColor3"
			or (class == "UIStroke" and property == "Color")
		then
			bindtheme(object, property, value)
		end
	end

	local backgroundrole =
		properties
		and properties.BackgroundColor3
		and themerole(properties.BackgroundColor3)

	if backgroundrole
		and transparencyroles[backgroundrole]
		and object:IsA("GuiObject")
	then
		local base =
			properties.BackgroundTransparency

		if base == nil then
			base = 0
		end

		transparencybase[object] = {
			base = base,
			role = backgroundrole,
		}
		object.BackgroundTransparency =
			effectivetransparency(base, backgroundrole)
	end

	return object
end

function tween(object, properties, info, raw)
	if not object or not object.Parent then
		return
	end

	local goals = {}

	for property, value in pairs(properties) do
		if raw then
			goals[property] = value
		else
			if property == "BackgroundColor3"
				or property == "TextColor3"
				or property == "ImageColor3"
				or property == "ScrollBarImageColor3"
				or (object:IsA("UIStroke") and property == "Color")
			then
				syncbinding(object, property, value)
			end

			if property == "BackgroundTransparency"
				and transparencybase[object] ~= nil
			then
				transparencybase[object].base = value
				goals[property] = effectivetransparency(
					value,
					transparencybase[object].role
				)
			elseif setaccentalphabase(object, property, value) then
				goals[property] = effectiveaccentalpha(value)
			elseif setfontalphabase(object, property, value) then
				goals[property] = effectivefontalpha(value)
			else
				goals[property] = value
			end
		end
	end

	local groupshadows

	if object:IsA("CanvasGroup") and goals.GroupTransparency ~= nil then
		local grouptarget = math.clamp(goals.GroupTransparency, 0, 1)
		groupshadows = {}

		for _, child in ipairs(object:GetChildren()) do
			if child:IsA("UIShadow") then
				local base = child:GetAttribute("BlushBaseTransparency")

				if type(base) ~= "number" then
					base = child.Transparency
					child:SetAttribute("BlushBaseTransparency", base)
				end

				groupshadows[#groupshadows + 1] = {
					object = child,
					target = 1 - (1 - base) * (1 - grouptarget),
				}
			end
		end
	end

	if not animationsenabled then
		for property, value in pairs(goals) do
			object[property] = value
		end

		for _, shadow in ipairs(groupshadows or {}) do
			shadow.object.Transparency = shadow.target
		end

		return nil
	end

	local tweeninfo = info or ti
	local animation = tweenservice:Create(object, tweeninfo, goals)

	for _, shadow in ipairs(groupshadows or {}) do
		local shadowanimation = tweenservice:Create(
			shadow.object,
			tweeninfo,
			{Transparency = shadow.target}
		)
		shadowanimation:Play()
	end

	animation:Play()
	return animation
end

function buildtheme(background, accent, fontcolor)
	local h, s, v = background:ToHSV()
	local direction = v > .56 and -1 or 1

	local function surface(offset, saturation)
		return Color3.fromHSV(
			h,
			math.clamp(s * (saturation or .72), 0, 1),
			math.clamp(v + direction * offset, 0, 1)
		)
	end

	local luminance =
		background.R * .2126
		+ background.G * .7152
		+ background.B * .0722

	local light = luminance <= .52

	local primarytext =
		fontcolor
		or (
			light
			and Color3.fromRGB(240, 240, 242)
			or Color3.fromRGB(28, 28, 31)
		)

	local accentluminance =
		accent.R * .2126
		+ accent.G * .7152
		+ accent.B * .0722

	return {
		window = background,
		sidebar = surface(-.016, .72),
		section = surface(.052, .66),
		input = surface(.024, .70),
		hover = surface(.074, .62),
		track = surface(.126, .56),
		border = surface(.112, .50),
		scroll = surface(.118, .44),
		scrollTrack = surface(.045, .56),
		popup = surface(.012, .70),
		notification = surface(.036, .66),
		text = primarytext,
		text2 = background:Lerp(primarytext, .72),
		text3 = background:Lerp(primarytext, .45),
		white = accent,
		black = accentluminance > .55
			and Color3.fromRGB(14, 14, 15)
			or Color3.fromRGB(245, 245, 247),
		font = primarytext,
	}
end

function applytheme(
	background,
	accent,
	backgroundalpha,
	accentalpha,
	fontcolor,
	fontalpha,
	animate
)
	local oldbackground = theme.window
	local oldaccent = theme.white
	local oldfont = theme.font
	local oldbackgroundalpha = theme.backgroundAlpha
	local oldaccentalpha = theme.accentAlpha
	local oldfontalpha = theme.fontAlpha

	local nexttheme = buildtheme(
		background,
		accent,
		fontcolor or theme.font
	)

	local changedroles = {}
	for key, value in pairs(nexttheme) do
		if theme[key] ~= value then
			changedroles[key] = true
			theme[key] = value
		end
	end

	if backgroundalpha ~= nil then
		theme.backgroundAlpha = math.clamp(backgroundalpha, 0, 1)
	end

	if accentalpha ~= nil then
		theme.accentAlpha = math.clamp(accentalpha, 0, 1)
	end

	if fontalpha ~= nil then
		theme.fontAlpha = math.clamp(fontalpha, 0, 1)
	end

	local backgroundalphachanged = oldbackgroundalpha ~= theme.backgroundAlpha
	local accentalphachanged = oldaccentalpha ~= theme.accentAlpha
	local fontalphachanged = oldfontalpha ~= theme.fontAlpha
	local backgroundchanged = oldbackground ~= theme.window
	local accentchanged = oldaccent ~= theme.white
	local fontchanged = oldfont ~= theme.font

	env.__blush_theme_tweens = env.__blush_theme_tweens or setmetatable({}, { __mode = "k" })

	for i = #themebindings, 1, -1 do
		local binding = themebindings[i]

		if not binding.object.Parent then
			table.remove(themebindings, i)
		elseif changedroles[binding.role] then
			invoke(function()
				local target = theme[binding.role]
				local gradienttext = binding.property == "TextColor3"
					and env.__blush_gradientstates
					and env.__blush_gradientstates[binding.object]

				if gradienttext then
					binding.object.TextColor3 = Color3.new(1, 1, 1)
				elseif animate == true and animationsenabled then
					local objecttweens = env.__blush_theme_tweens[binding.object]
					if not objecttweens then
						objecttweens = {}
						env.__blush_theme_tweens[binding.object] = objecttweens
					end

					local previous = objecttweens[binding.property]
					if previous then
						invoke(function() previous:Cancel() end)
					end

					local animation = tweenservice:Create(
						binding.object,
						TweenInfo.new(.16, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
						{ [binding.property] = target }
					)

					objecttweens[binding.property] = animation
					animation:Play()
				else
					binding.object[binding.property] = target
				end
			end)
		end
	end

	if backgroundalphachanged then
		applyuitransparency(uitransparency * 100)
	end

	if accentalphachanged then
		applyaccentalpha(theme.accentAlpha)
	end

	if fontalphachanged then
		applyfontalpha(theme.fontAlpha)
	end

	if refreshcheckboxcolors
		and (
			accentchanged
			or changedroles.border
			or changedroles.input
			or changedroles.black
			or accentalphachanged
		)
	then
		refreshcheckboxcolors()
	end

	if backgroundchanged and updatebackgroundtone then
		updatebackgroundtone()
	end

	if accentchanged and syncwindowglowcolor then
		syncwindowglowcolor(animate == true)
	end

	if accentpicker
		and not accentpicker.dragging
		and not accentpicker.fading
		and not accentpicker.rainbow
		and (accentchanged or accentalphachanged)
	then
		accentpicker:Set(theme.white, theme.accentAlpha, false)
	end

	if backgroundpicker
		and not backgroundpicker.dragging
		and not backgroundpicker.fading
		and not backgroundpicker.rainbow
		and (backgroundchanged or backgroundalphachanged)
	then
		backgroundpicker:Set(theme.window, theme.backgroundAlpha, false)
	end

	if fontpicker
		and not fontpicker.dragging
		and not fontpicker.fading
		and not fontpicker.rainbow
		and (fontchanged or fontalphachanged)
	then
		fontpicker:Set(theme.font, theme.fontAlpha, false)
	end
end

function corner(object, radius)
	return new("UICorner", {
		Parent = object,
		CornerRadius = UDim.new(0, radius),
	})
end

function stroke(object, transparency, color, thickness)
	return new("UIStroke", {
		Parent = object,

		Color = color or theme.border,
		Transparency = transparency or 0,
		Thickness = thickness or 1,
	})
end

function padding(object, left, right, top, bottom)
	return new("UIPadding", {
		Parent = object,

		PaddingLeft = UDim.new(0, left or 0),
		PaddingRight = UDim.new(0, right or 0),
		PaddingTop = UDim.new(0, top or 0),
		PaddingBottom = UDim.new(0, bottom or 0),
	})
end

function list(object, spacing)
	return new("UIListLayout", {
		Parent = object,

		Padding = UDim.new(0, spacing or 0),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
end


function plaintext(value)
	value = tostring(value or "")
	value = string.gsub(value, "<[bB][rR]%s*/?>", "\n")
	value = string.gsub(value, "<[^>]->", "")
	value = string.gsub(value, "&nbsp;", " ")
	value = string.gsub(value, "&quot;", '"')
	value = string.gsub(value, "&#39;", "'")
	value = string.gsub(value, "&lt;", "<")
	value = string.gsub(value, "&gt;", ">")
	value = string.gsub(value, "&amp;", "&")
	value = string.gsub(value, "&#(%d+);", function(code)
		local number = tonumber(code)

		if not number
			or number < 0
			or number > 255
		then
			return ""
		end

		return string.char(number)
	end)

	return value
end

function measuretext(value, size, face, bounds)
	return textservice:GetTextSize(
		plaintext(value),
		size,
		face,
		bounds
	)
end

function richrgb(textvalue, r, g, b)
	r = math.clamp(math.round(tonumber(r) or 255), 0, 255)
	g = math.clamp(math.round(tonumber(g) or 255), 0, 255)
	b = math.clamp(math.round(tonumber(b) or 255), 0, 255)

	return string.format(
		'<font color="rgb(%d,%d,%d)">%s</font>',
		r,
		g,
		b,
		tostring(textvalue or "")
	)
end

env.__blush_rgb = richrgb

env.__blush_gradienttargets = setmetatable({}, { __mode = "k" })
env.__blush_gradientstates = setmetatable({}, { __mode = "k" })
env.__blush_rainbowgradients = setmetatable({}, { __mode = "k" })
rainbowtextconnection = nil
rainbowtextphase = 0
rainbowtextsequence = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 1, 1)),
	ColorSequenceKeypoint.new(.2, Color3.fromHSV(.16, 1, 1)),
	ColorSequenceKeypoint.new(.4, Color3.fromHSV(.33, 1, 1)),
	ColorSequenceKeypoint.new(.6, Color3.fromHSV(.5, 1, 1)),
	ColorSequenceKeypoint.new(.8, Color3.fromHSV(.66, 1, 1)),
	ColorSequenceKeypoint.new(1, Color3.fromHSV(.83, 1, 1)),
})

function registergradienttarget(target, textobject)
	if target and textobject then
		env.__blush_gradienttargets[target] = textobject
	end

	return target
end

function resolvegradienttarget(target)
	if type(target) == "table" then
		if target.TextObject then
			target = target.TextObject
		elseif target.Object then
			target = target.Object
		elseif target.Button then
			target = target.Button
		elseif target.Frame then
			target = target.Frame
		end
	end

	if typeof(target) ~= "Instance" then
		return nil
	end

	if target:IsA("TextLabel")
		or target:IsA("TextButton")
		or target:IsA("TextBox")
	then
		return target
	end

	local mapped = env.__blush_gradienttargets[target]
	if mapped
		and mapped.Parent
		and (
			mapped:IsA("TextLabel")
			or mapped:IsA("TextButton")
			or mapped:IsA("TextBox")
		)
	then
		return mapped
	end

	return nil
end

function normalizetextgradient(value)
	if value == nil or value == false then
		return nil, false
	end

	if type(value) == "string"
		and string.lower(value) == "rainbow"
	then
		return rainbowtextsequence, true
	end

	if typeof(value) == "ColorSequence" then
		return value, false
	end

	if type(value) == "table" then
		if value.Rainbow == true or value.rainbow == true then
			return rainbowtextsequence, true
		end

		local keypoints = value.Keypoints or value.keypoints or value
		if #keypoints >= 2 then
			return ColorSequence.new(keypoints), false
		end
	end

	return nil, false
end

function textgradientrole(textobject)
	for index = #themebindings, 1, -1 do
		local binding = themebindings[index]
		if binding.object == textobject
			and binding.property == "TextColor3"
		then
			return binding.role
		end
	end

	return nil
end

function stoprainbowtextloop()
	if rainbowtextconnection and rainbowtextconnection.Connected then
		rainbowtextconnection:Disconnect()
	end
	rainbowtextconnection = nil
end

function ensurerainbowtextloop()
	if rainbowtextconnection and rainbowtextconnection.Connected then
		return
	end

	rainbowtextconnection = runservice.RenderStepped:Connect(function(dt)
		if next(env.__blush_rainbowgradients) == nil then
			stoprainbowtextloop()
			return
		end

		rainbowtextphase = (rainbowtextphase + dt * 2.15) % (math.pi * 2)
		local offset = Vector2.new(math.sin(rainbowtextphase) * .28, 0)

		for textobject, gradient in pairs(env.__blush_rainbowgradients) do
			if not textobject.Parent or not gradient.Parent then
				env.__blush_rainbowgradients[textobject] = nil
			else
				gradient.Offset = offset
			end
		end
	end)
end

function settextgradient(target, value)
	local textobject = resolvegradienttarget(target)
	if not textobject then
		return false
	end

	local previous = env.__blush_gradientstates[textobject]
	local role = previous and previous.role or textgradientrole(textobject)
	local basecolor = previous and previous.basecolor or textobject.TextColor3

	if previous then
		env.__blush_rainbowgradients[textobject] = nil
		if previous.gradient and previous.gradient.Parent then
			previous.gradient:Destroy()
		end
		env.__blush_gradientstates[textobject] = nil
	end

	local sequence, rainbow = normalizetextgradient(value)
	if not sequence then
		if textobject.Parent then
			textobject.TextColor3 = role and theme[role] or basecolor
		end
		if next(env.__blush_rainbowgradients) == nil then
			stoprainbowtextloop()
		end
		return value == nil or value == false
	end

	local gradient = rawnew("UIGradient", {
		Name = "BlushGradient",
		Parent = textobject,
		Color = sequence,
		Offset = Vector2.zero,
	})

	local state = {
		gradient = gradient,
		role = role,
		basecolor = basecolor,
		rainbow = rainbow,
	}

	env.__blush_gradientstates[textobject] = state
	textobject.TextColor3 = Color3.new(1, 1, 1)

	if rainbow then
		env.__blush_rainbowgradients[textobject] = gradient
		ensurerainbowtextloop()
	end

	return true
end

function settextrainbow(target, enabled)
	return settextgradient(target, enabled == true and "Rainbow" or nil)
end

function label(parentobject, value, size, face, color)
	local object = new("TextLabel", {
		Parent = parentobject,
		Size = size,

		BackgroundTransparency = 1,
		BorderSizePixel = 0,

		Text = value,
		TextColor3 = color or theme.text,

		Font = face or font,
		TextSize = 17,

		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
	})

	registergradienttarget(object, object)
	return object
end

function image(parentobject, asset, size, color, zindex)
	return new("ImageLabel", {
		Parent = parentobject,

		Size = UDim2.fromOffset(size, size),

		BackgroundTransparency = 1,
		BorderSizePixel = 0,

		Image = asset,
		ImageColor3 = color or theme.text2,

		ScaleType = Enum.ScaleType.Fit,

		ZIndex = zindex or 1,
	})
end

function addshadow(
	parentobject,
	name,
	transparency,
	blur,
	spread,
	zindex,
	color,
	offset,
	bindcolor
)
	local success, shadow = invoke(function()
		local object = Instance.new("UIShadow")

		object.Name = name
		object.Color = color or theme.white
		object:SetAttribute("BlushBaseTransparency", transparency)

		local parentgroupalpha = 0
		if parentobject:IsA("CanvasGroup") then
			parentgroupalpha = parentobject.GroupTransparency
		end

		object.Transparency = 1 - (1 - transparency) * (1 - parentgroupalpha)
		object.BlurRadius = UDim.new(0, blur)
		object.Spread = UDim2.fromOffset(spread, spread)
		object.Offset = offset or UDim2.fromOffset(0, 0)
		object.ZIndex = zindex or -1
		object.Parent = parentobject

		if bindcolor ~= false
			and object.Color == theme.white
		then
			bindtheme(object, "Color", theme.white)
		end

		return object
	end)

	return success and shadow or nil
end

function addglow(object, preset)
	if preset ~= "active" then
		return nil
	end

	return addshadow(
		object,
		"ActiveGlow",
		.76,
		9,
		1,
		-1,
		theme.white,
		UDim2.fromOffset(0, 0)
	)
end

function adddepthshadow(object, preset)
	if preset == "window" then
		return addshadow(
			object,
			"DepthShadow",
			.48,
			28,
			4,
			-3,
			Color3.fromRGB(0, 0, 0),
			UDim2.fromOffset(0, 8)
		)
	end

	if preset == "floating" then
		return addshadow(
			object,
			"DepthShadow",
			.58,
			16,
			2,
			-2,
			Color3.fromRGB(0, 0, 0),
			UDim2.fromOffset(0, 5)
		)
	end

	if preset == "popup" then
		return addshadow(
			object,
			"DepthShadow",
			.62,
			14,
			2,
			-2,
			Color3.fromRGB(0, 0, 0),
			UDim2.fromOffset(0, 4)
		)
	end

	return nil
end

function point(input)
	return Vector2.new(
		input.Position.X,
		input.Position.Y
	)
end

function offsetposition(position, delta)
	return UDim2.new(
		position.X.Scale,
		position.X.Offset + delta.X,

		position.Y.Scale,
		position.Y.Offset + delta.Y
	)
end

function inside(object, position)
	local p = object.AbsolutePosition
	local s = object.AbsoluteSize

	return position.X >= p.X
		and position.Y >= p.Y
		and position.X <= p.X + s.X
		and position.Y <= p.Y + s.Y
end

function guivisible(object)
	local current = object

	while current
		and current ~= gui
	do
		if current:IsA("GuiObject")
			and not current.Visible
		then
			return false
		end

		current = current.Parent
	end

	return current == gui
end

originalposition = UDim2.fromScale(.5, .52)
originalwindowsize = Vector2.new(926, 676)

function centeredwindowposition(size, scale)
	size = size or originalwindowsize
	scale = scale or 1

	local camera = workspace.CurrentCamera
	local viewport = camera and camera.ViewportSize or gui.AbsoluteSize

	return UDim2.fromOffset(
		math.round(viewport.X * originalposition.X.Scale - size.X * scale * .5),
		math.round(viewport.Y * originalposition.Y.Scale - size.Y * scale * .5)
	)
end

-- window

shell = new("Frame", {
	Parent = gui,

	AnchorPoint = Vector2.zero,
	Position = centeredwindowposition(originalwindowsize, 1),

	Size = UDim2.fromOffset(originalwindowsize.X, originalwindowsize.Y),

	BackgroundTransparency = 1,
	BorderSizePixel = 0,

	ZIndex = 10,
})

env.__blush_shellscale = new("UIScale", {
	Parent = shell,
	Scale = 1,
})

modalguard = new("TextButton", {
	Parent = gui,
	Position = UDim2.fromOffset(0, 0),
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Text = "",
	AutoButtonColor = false,
	Active = false,
	Selectable = false,
	Modal = false,
	Visible = false,
	ZIndex = 1,
})

cursorstate = {
	captured = false,
	mousebehavior = nil,
	mouseiconenabled = nil,
	override = nil,
}

function capturecursorstate()
	if cursorstate.captured or uis.TouchEnabled then
		return
	end

	cursorstate.captured = true
	cursorstate.mousebehavior = uis.MouseBehavior
	cursorstate.mouseiconenabled = uis.MouseIconEnabled

	if gethiddenproperty then
		invoke(function()
			cursorstate.override = gethiddenproperty(
				uis,
				"OverrideMouseIconBehavior"
			)
		end)
	end
end

function forcecursorvisible()
	if uis.TouchEnabled then
		return
	end

	capturecursorstate()

	invoke(function()
		uis.MouseBehavior = Enum.MouseBehavior.Default
		uis.MouseIconEnabled = true
	end)

	if sethiddenproperty then
		invoke(function()
			sethiddenproperty(
				uis,
				"OverrideMouseIconBehavior",
				Enum.OverrideMouseIconBehavior.ForceShow
			)
		end)
	end
end

function restorecursorstate()
	if not cursorstate.captured or uis.TouchEnabled then
		return
	end

	invoke(function()
		if cursorstate.mousebehavior ~= nil then
			uis.MouseBehavior = cursorstate.mousebehavior
		end

		if cursorstate.mouseiconenabled ~= nil then
			uis.MouseIconEnabled = cursorstate.mouseiconenabled
		end
	end)

	if sethiddenproperty then
		invoke(function()
			sethiddenproperty(
				uis,
				"OverrideMouseIconBehavior",
				cursorstate.override or Enum.OverrideMouseIconBehavior.None
			)
		end)
	end

	cursorstate.captured = false
	cursorstate.mousebehavior = nil
	cursorstate.mouseiconenabled = nil
	cursorstate.override = nil
end

invoke(function()
	runservice:UnbindFromRenderStep("__blush_force_cursor")
end)

runservice:BindToRenderStep(
	"__blush_force_cursor",
	Enum.RenderPriority.Last.Value + 100,
	function()
		if gui
			and gui.Parent
			and gui.Enabled
			and env.__blush_windowvisible == true
		then
			forcecursorvisible()
		end
	end
)

forcecursorvisible()

function applyuiscale(value)
	local scale = math.clamp(tonumber(value) or 100, 70, 130) / 100

	if env.__blush_shellscale
		and env.__blush_shellscale.Parent
	then
		env.__blush_shellscale.Scale = scale
	end
end

window = new("CanvasGroup", {
	Parent = shell,

	Size = UDim2.fromScale(1, 1),

	BackgroundColor3 = theme.window,
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ClipsDescendants = true,
	GroupTransparency = 0,

	ZIndex = 10,
})

windowcorner = corner(window, 12)
windowstroke = stroke(window, .76, theme.border, 1)
windowshadow = adddepthshadow(window, "window")
windowglow = addshadow(
	window,
	"WindowGlow",
	.88,
	18,
	2,
	-2,
	theme.white,
	UDim2.fromOffset(0, 0)
)

windowresizeenabled = true
windowdragenabled = true
windowminimizebuttonenabled = true
windowminsize = Vector2.new(620, 440)
windowmaxsize = nil

windowshadowenabled = true
windowglowenabled = true
windowglowintensity = 16
windowglowsize = 10
windowglowcolor = theme.white
windowglowalpha = 1
windowglowrenderalpha = 1
windowglowcolorpicker = nil

function applywindowshadow()
	if not windowshadow then
		return
	end

	local base = windowshadowenabled and .40 or 1

	windowshadow:SetAttribute(
		"BlushBaseTransparency",
		base
	)

	windowshadow.Transparency = base
end

function applywindowglow()
	if not windowglow then
		return
	end

	local strength = math.clamp(
		tonumber(windowglowintensity) or 16,
		0,
		100
	)

	local size = math.clamp(
		tonumber(windowglowsize) or 10,
		0,
		24
	)

	local alpha = math.clamp(
		tonumber(windowglowrenderalpha) or windowglowalpha or 1,
		0,
		1
	)

	local opacity =
		(strength / 100)
		* .58
		* alpha

	local transparency =
		1 - opacity

	windowglow:SetAttribute(
		"BlushBaseTransparency",
		transparency
	)

	windowglow.Color = windowglowcolor

	windowglow.Transparency =
		windowglowenabled
		and transparency
		or 1

	windowglow.BlurRadius =
		UDim.new(0, size)

	windowglow.Spread =
		UDim2.fromOffset(
			size >= 14 and 1 or 0,
			size >= 14 and 1 or 0
		)
end

function syncwindowglowcolor(animate)
	windowglowcolor = theme.white

	if windowglowcolorpicker then
		windowglowcolorpicker:Set(
			windowglowcolor,
			windowglowalpha,
			false
		)

		windowglowrenderalpha =
			windowglowcolorpicker:currentalpha()
	else
		windowglowrenderalpha =
			windowglowalpha
	end

	if windowglow and windowglow.Parent then
		if animate == true and animationsenabled then
			tween(
				windowglow,
				{ Color = windowglowcolor },
				TweenInfo.new(
					.24,
					Enum.EasingStyle.Quart,
					Enum.EasingDirection.Out
				)
			)
		else
			windowglow.Color = windowglowcolor
		end
	end

	applywindowglow()
end

applywindowshadow()
applywindowglow()

backgroundholder = rawnew("Frame", {
	Parent = window,
	Position = UDim2.fromOffset(0, 0),
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ClipsDescendants = true,
	Active = false,
	ZIndex = 9,
})

backgroundimage = rawnew("ImageLabel", {
	Parent = backgroundholder,
	AnchorPoint = Vector2.new(.5, .5),
	Position = UDim2.fromScale(.5, .5),
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Image = "",
	ImageColor3 = Color3.new(1, 1, 1),
	ImageTransparency = 1,
	ScaleType = Enum.ScaleType.Crop,
	Visible = false,
	ZIndex = 9,
})

backgroundlayers = { backgroundimage }
backgroundresolvedasset = nil
backgroundeditable = nil
backgroundblureditable = nil
backgroundblurbaseasset = nil
backgroundblurbasepixels = nil
backgroundblurbasewidth = 0
backgroundblurbaseheight = 0
backgroundblurlastsignature = nil
backgroundblurtoken = 0
backgroundblurdebounce = 0
backgroundblurtask = nil
backgroundsectionframes = setmetatable({}, { __mode = "k" })

backgroundblurdisplay = rawnew("ImageLabel", {
	Parent = backgroundholder,
	AnchorPoint = Vector2.new(.5, .5),
	Position = UDim2.fromScale(.5, .5),
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Image = "",
	ImageColor3 = Color3.new(1, 1, 1),
	ImageTransparency = 1,
	ScaleType = Enum.ScaleType.Crop,
	Visible = false,
	ZIndex = 9,
})

function destroybackgroundeditable()
	backgroundblurtoken += 1

	if backgroundblurtask
		and coroutine.status(backgroundblurtask) == "suspended"
	then
		pcall(task.cancel, backgroundblurtask)
	end
	backgroundblurtask = nil

	if backgroundeditable then
		invoke(function()
			backgroundeditable:Destroy()
		end)
		backgroundeditable = nil
	end

	backgroundblurbaseasset = nil
	backgroundblurbasepixels = nil
	backgroundblurbasewidth = 0
	backgroundblurbaseheight = 0
	backgroundblurlastsignature = nil

	if backgroundblureditable then
		invoke(function()
			backgroundblureditable:Destroy()
		end)
		backgroundblureditable = nil
	end

	if backgroundblurdisplay and backgroundblurdisplay.Parent then
		backgroundblurdisplay.Visible = false
		backgroundblurdisplay.ImageTransparency = 1
		invoke(function()
			backgroundblurdisplay.ImageContent = Content.none
		end)
	end
end

backgroundtoneoverlay = rawnew("Frame", {
	Parent = backgroundholder,
	Position = UDim2.fromOffset(0, 0),
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.new(1, 1, 1),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Visible = false,
	Active = false,
	ZIndex = 9,
})

rawnew("UIGradient", {
	Parent = backgroundtoneoverlay,
	Rotation = 90,
	Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, .06),
		NumberSequenceKeypoint.new(.55, .22),
		NumberSequenceKeypoint.new(1, .08),
	}),
})

backgroundexcludesidebar = false
autobackgroundcolors = false
topnavigationenabled = false

function updatebackgroundbounds()
	if not backgroundholder or not backgroundholder.Parent then
		return
	end

	local exclude = backgroundexcludesidebar == true
	local mobilepanel = env.__blush_mobilepanelopen == true

	if exclude and uis.TouchEnabled and mobilepanel then
		backgroundholder.Position = UDim2.fromOffset(0, 0)
		backgroundholder.Size = UDim2.fromOffset(0, 0)
	elseif exclude then
		local width = math.max(0, (sidebarwidth or 215) - 1)
		backgroundholder.Position = UDim2.fromOffset(width, 0)
		backgroundholder.Size = UDim2.new(1, -width, 1, 0)
	else
		backgroundholder.Position = UDim2.fromOffset(0, 0)
		backgroundholder.Size = UDim2.fromScale(1, 1)
	end
end

function updatebackgroundtone()
	if not backgroundtoneoverlay or not backgroundtoneoverlay.Parent then
		return
	end

	local visible = backgroundimagesource ~= nil
		and backgroundimagesource ~= ""
		and backgroundresolvedasset ~= nil

	if not visible then
		backgroundtoneoverlay.Visible = false
		backgroundtoneoverlay.BackgroundTransparency = 1
		return
	end

	local luminance = theme.window.R * .2126
		+ theme.window.G * .7152
		+ theme.window.B * .0722
	local lighttheme = luminance >= .62

	backgroundtoneoverlay.Visible = true
	if lighttheme then
		backgroundtoneoverlay.BackgroundColor3 = Color3.new(1, 1, 1)
		backgroundtoneoverlay.BackgroundTransparency = .91
	else
		backgroundtoneoverlay.BackgroundColor3 = Color3.new(0, 0, 0)
		backgroundtoneoverlay.BackgroundTransparency = .965
	end

	if updatebackgroundsurfaces then
		updatebackgroundsurfaces()
	end
end

function setbackgroundexcludesidebar(value)
	backgroundexcludesidebar = value == true
	updatebackgroundbounds()
	if updatebackgroundsurfaces then
		updatebackgroundsurfaces()
	end
end

reopengui = Instance.new("ScreenGui")
reopengui.Name = "blush_reopen"
reopengui.IgnoreGuiInset = not uis.TouchEnabled
reopengui.ResetOnSpawn = false
reopengui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
reopengui.DisplayOrder = 1001
reopengui.Enabled = false
reopengui.Parent = parent

reopenbutton = new("TextButton", {
	Parent = reopengui,
	AnchorPoint = Vector2.new(.5, 0),
	Position = UDim2.new(.5, 0, 0, 12),
	Size = UDim2.fromOffset(uis.TouchEnabled and 124 or 112, uis.TouchEnabled and 42 or 34),
	BackgroundColor3 = theme.window,
	BackgroundTransparency = .04,
	BorderSizePixel = 0,
	Text = "",
	AutoButtonColor = false,
	ZIndex = 10,
})
corner(reopenbutton, 9)
reopenstroke = stroke(reopenbutton, .62, theme.border, .6)
reopenshadow = adddepthshadow(reopenbutton, "floating")
env.__blush_reopenanimations = {}
env.__blush_reopen_fading = false

reopenlabel = label(
	reopenbutton,
	"blush.",
	UDim2.new(1, -24, 1, 0),
	medium,
	theme.text
)
reopenlabel.Position = UDim2.fromOffset(12, 0)
reopenlabel.TextSize = 15
reopenlabel.ZIndex = 11

reopenarrow = image(
	reopenbutton,
	icons.down,
	13,
	theme.text3,
	11
)
reopenarrow.AnchorPoint = Vector2.new(1, .5)
reopenarrow.Position = UDim2.new(1, -10, .5, 0)
reopenarrow.Rotation = 180
reopenarrow.Visible = false

reopenbutton.MouseEnter:Connect(function()
	if env.__blush_reopen_fading then
		return
	end

	tween(reopenlabel, {TextColor3 = theme.white}, hoverti)
end)

reopenbutton.MouseLeave:Connect(function()
	if env.__blush_reopen_fading then
		return
	end

	tween(reopenlabel, {TextColor3 = theme.text}, hoverti)
end)

reopenbutton.Activated:Connect(function()
	requestvisibilitytoggle()
end)

sidebarwidth = 215
sidebarcompactthreshold = 118
sidebarminwidth = 68
sidebarmaxwidth = 300
sidebarresize = nil
sidebarresizelasttap = 0
sidebarcompact = false

sidebar = new("Frame", {
	Parent = window,

	Size = UDim2.new(0, sidebarwidth, 1, 0),

	BackgroundColor3 = theme.sidebar,
	BorderSizePixel = 0,

	ZIndex = 10,
})


main = new("Frame", {
	Parent = window,

	Position = UDim2.fromOffset(sidebarwidth - 1, 0),
	Size = UDim2.new(1, -(sidebarwidth - 1), 1, 0),

	BackgroundColor3 = theme.window,
	BorderSizePixel = 0,

	ZIndex = 10,
})


function updatebackgroundsurfaces()
	if not main or not main.Parent or not sidebar or not sidebar.Parent then
		return
	end

	local visible = backgroundimagesource ~= nil
		and backgroundimagesource ~= ""
		and backgroundresolvedasset ~= nil

	local luminance = theme.window.R * .2126
		+ theme.window.G * .7152
		+ theme.window.B * .0722
	local lighttheme = luminance >= .62

	-- Wallpaper transparency belongs to the surfaces/groupboxes, never to the image-opacity control.
	local mainbase = visible and (lighttheme and .12 or .24) or 0
	local sidebarbase = visible
		and not backgroundexcludesidebar
		and (lighttheme and .06 or .14)
		or 0
	local sectionbase = visible and (lighttheme and .76 or .82) or .10

	local maindata = transparencybase[main]
	if maindata then
		maindata.base = mainbase
		main.BackgroundTransparency = effectivetransparency(mainbase, maindata.role)
	else
		main.BackgroundTransparency = mainbase
	end

	local sidebardata = transparencybase[sidebar]
	if sidebardata then
		sidebardata.base = sidebarbase
		sidebar.BackgroundTransparency = effectivetransparency(sidebarbase, sidebardata.role)
	else
		sidebar.BackgroundTransparency = sidebarbase
	end

	for frame, defaultbase in pairs(backgroundsectionframes) do
		if frame and frame.Parent then
			local base = visible and sectionbase or defaultbase
			local data = transparencybase[frame]
			if data then
				data.base = base
				frame.BackgroundTransparency = effectivetransparency(base, data.role)
			else
				frame.BackgroundTransparency = base
			end
		else
			backgroundsectionframes[frame] = nil
		end
	end
end

sidebardivider = new("Frame", {
	Parent = window,

	Position = UDim2.fromOffset(sidebarwidth - 1, 0),
	Size = UDim2.new(0, 1, 1, 0),

	BackgroundColor3 = theme.border,
	BackgroundTransparency = .36,

	BorderSizePixel = 0,

	ZIndex = 12,
})

-- resize

resizehandlesize = uis.TouchEnabled and 38 or 28
windowresize = nil
lastresizetap = 0

resizehandle = new("TextButton", {
	Parent = window,
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, -1, 1, -1),
	Size = UDim2.fromOffset(resizehandlesize, resizehandlesize),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Text = "",
	AutoButtonColor = false,
	Active = true,
	ZIndex = 80,
})

resizeicon = image(
	resizehandle,
	icons.resize,
	14,
	theme.text3,
	81
)
resizeicon.AnchorPoint = Vector2.new(.5, .5)
resizeicon.Position = UDim2.fromScale(.62, .62)
resizeicon.Rotation = -45
resizeicon.ImageTransparency = .42
addshadow(
	resizeicon,
	"ResizeGlow",
	.982,
	9,
	0,
	-1,
	theme.white,
	UDim2.fromOffset(0, 0),
	true
)

resizehandle.MouseEnter:Connect(function()
	tween(resizeicon, {
		ImageColor3 = theme.text,
		ImageTransparency = .05,
	}, hoverti)
end)

resizehandle.MouseLeave:Connect(function()
	tween(resizeicon, {
		ImageColor3 = theme.text3,
		ImageTransparency = .42,
	}, hoverti)
end)


-- watermark

watermark = new("Frame", {
	Parent = watermarkgui,

	AnchorPoint = Vector2.new(1, 0),

	Position = UDim2.new(
		1,
		-18,
		0,
		18
	),

	Size = UDim2.fromOffset(
		140,
		38
	),

	BackgroundColor3 = theme.popup,

	BorderSizePixel = 0,

	Active = true,
	Visible = true,

	ZIndex = 100,
})

watermarkshown = true
watermarkfadetoken = 0
watermarkfadeanimations = {}
watermarkstatsconnection = nil

corner(watermark, 8)
watermarkshadow = adddepthshadow(watermark, "floating")
watermarkfadeparts = {
	{watermark, "BackgroundTransparency", 0, "background"},
}

if watermarkshadow then
	watermarkfadeparts[#watermarkfadeparts + 1] = {
		watermarkshadow,
		"Transparency",
		watermarkshadow:GetAttribute("BlushBaseTransparency") or watermarkshadow.Transparency,
		"direct",
	}
end

watermarkcontent = new("Frame", {
	Parent = watermark,

	Position = UDim2.fromOffset(
		10,
		0
	),

	Size = UDim2.new(
		1,
		-20,
		1,
		0
	),

	BackgroundTransparency = 1,

	ZIndex = 101,
})

watermarklayout = new("UIListLayout", {
	Parent = watermarkcontent,

	FillDirection =
		Enum.FillDirection.Horizontal,

	HorizontalAlignment =
		Enum.HorizontalAlignment.Center,

	VerticalAlignment =
		Enum.VerticalAlignment.Center,

	Padding = UDim.new(
		0,
		8
	),

	SortOrder =
		Enum.SortOrder.LayoutOrder,
})

watermarkorder = 0

function setwatermarkvisible(value, animate)
	value = value == true
	local changed = watermarkshown ~= value
	watermarkshown = value
	watermark.Active = value

	if setwatermarkstatsactive then
		setwatermarkstatsactive(value)
	end

	watermarkfadetoken += 1
	local token = watermarkfadetoken

	for _, animation in ipairs(watermarkfadeanimations) do
		invoke(function() animation:Cancel() end)
	end
	table.clear(watermarkfadeanimations)

	if value then
		watermark.Visible = true
	end

	local function targetalpha(part)
		if not value then
			return 1
		end

		if part[4] == "background" then
			return effectivetransparency(part[3], "popup")
		elseif part[4] == "font" then
			return effectivefontalpha(part[3])
		end

		return part[3]
	end

	if not animate or not animationsenabled or not changed then
		for _, part in ipairs(watermarkfadeparts) do
			if part[1] and part[1].Parent then
				part[1][part[2]] = targetalpha(part)
			end
		end
		watermark.Visible = value
		return
	end

	local primary
	for _, part in ipairs(watermarkfadeparts) do
		local object = part[1]
		if object and object.Parent then
			local animation = tween(
				object,
				{[part[2]] = targetalpha(part)},
				TweenInfo.new(.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
				true
			)
			if animation then
				watermarkfadeanimations[#watermarkfadeanimations + 1] = animation
				primary = primary or animation
			end
		end
	end

	local function finish()
		if token ~= watermarkfadetoken then
			return
		end
		table.clear(watermarkfadeanimations)
		if not watermarkshown then
			watermark.Visible = false
		end
	end

	if primary then
		primary.Completed:Connect(finish)
	else
		finish()
	end
end

function watermarktext(
	value,
	strong,
	width
)
	watermarkorder += 1

	local object = label(
		watermarkcontent,
		value,
		UDim2.fromOffset(
			width,
			38
		),
		strong and bold or font,
		strong and theme.text or theme.text3
	)

	object.LayoutOrder =
		watermarkorder

	object.TextSize =
		strong and 16 or 15

	object.TextXAlignment =
		Enum.TextXAlignment.Center

	object.TextTruncate =
		Enum.TextTruncate.AtEnd

	object.ZIndex = 102
	watermarkfadeparts[#watermarkfadeparts + 1] = {
		object,
		"TextTransparency",
		0,
		"font",
	}

	return object
end

function watermarkdivider()
	watermarkorder += 1

	local object = new("Frame", {
		Parent = watermarkcontent,

		LayoutOrder =
			watermarkorder,

		Size =
			UDim2.fromOffset(
				1,
				15
			),

		BackgroundColor3 =
			theme.border,

		BackgroundTransparency =
			.16,

		BorderSizePixel = 0,

		ZIndex = 102,
	})

	watermarkfadeparts[#watermarkfadeparts + 1] = {
		object,
		"BackgroundTransparency",
		.16,
		"direct",
	}

	return object
end

watermarkconfig = {
	Player = true,
	FPS = true,
	Ping = true,
	Time = true,
	PlayerMode = "Display",
}

env.__blush_watermark_title = watermarktext(
	"blush.",
	true,
	48
)

env.__blush_watermark_divider_player = watermarkdivider()
env.__blush_watermark_player = watermarktext(
	player.DisplayName,
	false,
	64
)

env.__blush_watermark_divider_fps = watermarkdivider()
env.__blush_watermark_fps = watermarktext(
	"0 fps",
	false,
	48
)

env.__blush_watermark_divider_ping = watermarkdivider()
env.__blush_watermark_ping = watermarktext(
	"0 ms",
	false,
	48
)

env.__blush_watermark_divider_time = watermarkdivider()
env.__blush_watermark_time = watermarktext(
	os.date("%H:%M"),
	false,
	42
)

function watermarkplayertext()
	if watermarkconfig.PlayerMode == "Username" then
		return player.Name
	elseif watermarkconfig.PlayerMode == "Both" then
		return player.DisplayName .. " @" .. player.Name
	end

	return player.DisplayName
end

function normalizewatermarkplayermode(value)
	value = tostring(value or "Display")

	if value == "DisplayName"
		or value == "Display name"
	then
		value = "Display"
	end

	if value ~= "Display"
		and value ~= "Username"
		and value ~= "Both"
	then
		value = "Display"
	end

	return value
end

function resizewatermarktext(object, value, strong)
	if not object or not object.Parent then
		return
	end

	value = tostring(value or "")

	local size = strong and 16 or 15
	local fontface = strong and bold or font

	local bounds = measuretext(
		value,
		size,
		fontface,
		Vector2.new(4096, 38)
	)

	object.Text = value
	object.TextTruncate = Enum.TextTruncate.None
	object.Size = UDim2.fromOffset(
		math.max(
			strong and 48 or 36,
			math.ceil(bounds.X) + 2
		),
		38
	)
end

function updatewatermarksize()
	if not watermark
		or not watermark.Parent
		or not watermarklayout
	then
		return
	end

	local width = math.ceil(
		watermarklayout.AbsoluteContentSize.X
	) + 20

	watermark.Size = UDim2.fromOffset(
		math.max(84, width),
		38
	)
end

connect(
	watermarklayout:GetPropertyChangedSignal(
		"AbsoluteContentSize"
	),
	updatewatermarksize
)

function updatewatermarklayout()
	local playerenabled =
		watermarkconfig.Player == true

	local fpsenabled =
		watermarkconfig.FPS == true

	local pingenabled =
		watermarkconfig.Ping == true

	local timeenabled =
		watermarkconfig.Time == true

	env.__blush_watermark_player.Visible =
		playerenabled

	env.__blush_watermark_fps.Visible =
		fpsenabled

	env.__blush_watermark_ping.Visible =
		pingenabled

	env.__blush_watermark_time.Visible =
		timeenabled

	env.__blush_watermark_divider_player.Visible =
		playerenabled

	env.__blush_watermark_divider_fps.Visible =
		fpsenabled

	env.__blush_watermark_divider_ping.Visible =
		pingenabled

	env.__blush_watermark_divider_time.Visible =
		timeenabled

	resizewatermarktext(
		env.__blush_watermark_player,
		watermarkplayertext(),
		false
	)

	updatewatermarksize()
end

function setwatermarktitle(value)
	value = tostring(value or "blush.")

	resizewatermarktext(
		env.__blush_watermark_title,
		value,
		true
	)

	updatewatermarksize()
end

updatewatermarklayout()

env.__blush_watermark_frames = 0
env.__blush_watermark_elapsed = 0
env.__blush_last_ping = 0

function calculatewatermarkping()
	local ok, value = invoke(function()
		local network = stats:FindFirstChild("Network")
		local serverstats = network and network:FindFirstChild("ServerStatsItem")
		local dataping = serverstats and serverstats:FindFirstChild("Data Ping")

		if dataping then
			local measured = dataping:GetValue()
			if type(measured) == "number" and measured >= 0 then
				return measured
			end
		end

		return player:GetNetworkPing() * 1000
	end)

	if not ok or type(value) ~= "number" then
		return env.__blush_last_ping or 0
	end

	value = math.max(0, value)
	env.__blush_last_ping = value
	return value
end

function updatewatermarkstats(dt)
	env.__blush_watermark_frames += 1
	env.__blush_watermark_elapsed += dt

	if env.__blush_watermark_elapsed < 1 then
		return
	end

	local elapsed = math.max(env.__blush_watermark_elapsed, .001)
	local frames = math.max(env.__blush_watermark_frames, 1)
	local fps = math.floor(frames / elapsed + .5)
	local ping = math.floor(calculatewatermarkping() + .5)

	if env.__blush_watermark_fps and env.__blush_watermark_fps.Parent then
		resizewatermarktext(env.__blush_watermark_fps, tostring(fps) .. " fps", false)
	end

	if env.__blush_watermark_ping and env.__blush_watermark_ping.Parent then
		resizewatermarktext(env.__blush_watermark_ping, tostring(ping) .. " ms", false)
	end

	if env.__blush_watermark_time and env.__blush_watermark_time.Parent then
		resizewatermarktext(env.__blush_watermark_time, os.date("%H:%M"), false)
	end

	if env.__blush_watermark_player and env.__blush_watermark_player.Parent then
		resizewatermarktext(env.__blush_watermark_player, watermarkplayertext(), false)
	end

	updatewatermarksize()
	env.__blush_watermark_frames = 0
	env.__blush_watermark_elapsed = 0
end

function setwatermarkstatsactive(value)
	if value then
		if not watermarkstatsconnection or not watermarkstatsconnection.Connected then
			watermarkstatsconnection = runservice.PreRender:Connect(updatewatermarkstats)
		end
		return
	end

	if watermarkstatsconnection and watermarkstatsconnection.Connected then
		watermarkstatsconnection:Disconnect()
	end

	watermarkstatsconnection = nil
	env.__blush_watermark_frames = 0
	env.__blush_watermark_elapsed = 0
end

setwatermarkstatsactive(watermarkshown)
calculatewatermarkping()

watermarkdragarea = new("TextButton", {
	Parent = watermark,

	Size = UDim2.fromScale(
		1,
		1
	),

	BackgroundTransparency = 1,
	BorderSizePixel = 0,

	Text = "",
	AutoButtonColor = false,

	ZIndex = 110,
})

-- sidebar

avat = new("ImageLabel", {
	Parent = sidebar,

	AnchorPoint = Vector2.new(.5, .5),

	Position =
		UDim2.fromOffset(
			39,
			45
		),

	Size =
		UDim2.fromOffset(
			22,
			22
		),

	BackgroundTransparency = 1,
	BorderSizePixel = 0,

	Image = icons.sliders,
	ImageColor3 = theme.text2,
	ScaleType = Enum.ScaleType.Fit,

	ZIndex = 14,
})

logocoloroverride = nil

brand = label(
	sidebar,
	"blush.",
	UDim2.fromOffset(
		125,
		23
	),
	bold
)

brand.Position =
	UDim2.fromOffset(
		72,
		23
	)

brand.TextSize = 21
brand.ZIndex = 14

version = label(
	sidebar,
	"v1.0.0",
	UDim2.fromOffset(
		48,
		18
	),
	font,
	theme.text3
)

version.Position =
	UDim2.fromOffset(
		72,
		48
	)

version.TextSize = 15
version.ZIndex = 14

versiondivider = new("Frame", {
	Parent = sidebar,

	Position =
		UDim2.fromOffset(
			124,
			51
		),

	Size =
		UDim2.fromOffset(
			1,
			12
		),

	BackgroundColor3 =
		theme.border,

	BackgroundTransparency =
		.18,

	BorderSizePixel = 0,
	ZIndex = 14,
})

username = label(
	sidebar,
	player.Name,
	UDim2.fromOffset(
		72,
		18
	),
	font,
	theme.text3
)

username.Position =
	UDim2.fromOffset(
		132,
		48
	)

username.TextSize = 15
username.TextTruncate =
	Enum.TextTruncate.AtEnd
username.ZIndex = 14

function updatebrandlayout()
	if not sidebar or not sidebar.Parent then
		return
	end

	local width = math.max(1, sidebar.AbsoluteSize.X)
	local hasicon = avat.Visible and avat.Image ~= ""
	local left = 42
	local iconwidth = hasicon and 22 or 0
	local icongap = hasicon and 11 or 0
	local textleft = hasicon and (left + iconwidth + icongap) or left
	local available = math.max(40, width - textleft - 14)

	local brandwidth = brand.Visible and math.min(
		math.ceil(measuretext(brand.Text, brand.TextSize, brand.Font, Vector2.new(100000, 23)).X),
		available
	) or 0
	local versionwidth = version.Visible and version.Text ~= ""
		and math.ceil(measuretext(version.Text, version.TextSize, version.Font, Vector2.new(100000, 18)).X)
		or 0
	local usernamewidth = username.Visible and username.Text ~= ""
		and math.ceil(measuretext(username.Text, username.TextSize, username.Font, Vector2.new(100000, 18)).X)
		or 0

	if hasicon then
		avat.Position = UDim2.fromOffset(left + 11, 45)
	end

	brand.Position = UDim2.fromOffset(textleft, 23)
	brand.Size = UDim2.fromOffset(math.max(1, math.min(brandwidth, available)), 23)

	version.Position = UDim2.fromOffset(textleft, 48)
	version.Size = UDim2.fromOffset(math.min(versionwidth, available), 18)

	local hasversion = versionwidth > 0
	local hasusername = usernamewidth > 0
	local usernamex = textleft + (hasversion and math.min(versionwidth, available) or 0)

	versiondivider.Visible = hasversion and hasusername
	if versiondivider.Visible then
		versiondivider.Position = UDim2.fromOffset(usernamex + 8, 51)
		usernamex += 17
	end

	username.Position = UDim2.fromOffset(usernamex, 48)
	username.Size = UDim2.fromOffset(
		math.max(0, math.min(usernamewidth, width - usernamex - 14)),
		18
	)
end

for _, object in ipairs({brand, version, username}) do
	connect(object:GetPropertyChangedSignal("Text"), updatebrandlayout)
	connect(object:GetPropertyChangedSignal("TextSize"), updatebrandlayout)
	connect(object:GetPropertyChangedSignal("Font"), updatebrandlayout)
	connect(object:GetPropertyChangedSignal("Visible"), updatebrandlayout)
end
connect(sidebar:GetPropertyChangedSignal("AbsoluteSize"), updatebrandlayout)
connect(avat:GetPropertyChangedSignal("Image"), updatebrandlayout)
connect(avat:GetPropertyChangedSignal("Visible"), updatebrandlayout)
updatebrandlayout()

sideheaderdrag = new("TextButton", {
	Parent = sidebar,

	Position =
		UDim2.fromOffset(
			0,
			0
		),

	Size =
		UDim2.new(
			1,
			0,
			0,
			75
		),

	BackgroundTransparency = 1,
	BorderSizePixel = 0,

	Text = "",
	AutoButtonColor = false,

	ZIndex = 13,
})

category = new("TextButton", {
	Parent = sidebar,
	Position = UDim2.fromOffset(14, 92),
	Size = UDim2.new(1, -28, 0, 28),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Text = "",
	AutoButtonColor = false,
	Visible = false,
	ZIndex = 13,
})

categorytext = label(
	category,
	"Main",
	UDim2.new(1, -30, 1, 0),
	medium,
	theme.text3
)
categorytext.Position = UDim2.fromOffset(8, 0)
categorytext.TextSize = 14
categorytext.ZIndex = 14

categoryarrow = image(
	category,
	icons.down,
	11,
	theme.text3,
	14
)
categoryarrow.AnchorPoint = Vector2.new(1, .5)
categoryarrow.Position = UDim2.new(1, -7, .5, 0)
categoryarrow.ImageTransparency = .18

nav = new("ScrollingFrame", {
	Parent = sidebar,
	Position = UDim2.fromOffset(14, 92),
	Size = UDim2.new(1, -28, 1, -164),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	CanvasSize = UDim2.fromOffset(0, 0),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ScrollBarThickness = 0,
	ScrollingDirection = Enum.ScrollingDirection.Y,
	ElasticBehavior = Enum.ElasticBehavior.Never,
	ClipsDescendants = true,
	ZIndex = 12,
})

list(nav, 3)
new("UIPadding", {
	Parent = nav,
	PaddingBottom = UDim.new(0, 10),
})

maingroup = new("Frame", {
	Parent = nav,
	Size = UDim2.new(1, 0, 0, 0),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ClipsDescendants = true,
	LayoutOrder = 1,
	ZIndex = 12,
})

maincontent = new("Frame", {
	Parent = maingroup,
	Size = UDim2.new(1, 0, 0, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ZIndex = 12,
})

maincontentlayout = list(maincontent, 3)
maincategorycollapsed = false


-- main header

header = new("Frame", {
	Parent = main,

	Size =
		UDim2.new(
			1,
			0,
			0,
			62
		),

	BackgroundTransparency = 1,

	Active = true,

	ZIndex = 12,
})

breadcrumb = new("Frame", {
	Parent = header,

	AnchorPoint =
		Vector2.new(
			0,
			.5
		),

	Position =
		UDim2.fromOffset(
			21,
			31
		),

	Size =
		UDim2.new(
			1,
			uis.TouchEnabled and -225 or -187,
			0,
			28
		),

	BackgroundTransparency = 1,

	ZIndex = 14,
})

new("UIListLayout", {
	Parent = breadcrumb,

	FillDirection =
		Enum.FillDirection.Horizontal,

	VerticalAlignment =
		Enum.VerticalAlignment.Center,

	Padding =
		UDim.new(
			0,
			5
		),

	SortOrder =
		Enum.SortOrder.LayoutOrder,
})

titleprimary = label(
	breadcrumb,
	"Combat",
	UDim2.fromOffset(
		0,
		28
	),
	bold
)

titleprimary.LayoutOrder = 1

titleprimary.TextSize = 20
titleprimary.ZIndex = 14

arrowholder = new("Frame", {
	Parent = breadcrumb,

	Size =
		UDim2.fromOffset(
			14,
			28
		),

	BackgroundTransparency = 1,
	BorderSizePixel = 0,

	LayoutOrder = 2,
	ZIndex = 14,
})

breadcrumbarrow = image(
	arrowholder,
	icons.right,
	14,
	theme.text3,
	14
)

breadcrumbarrow.AnchorPoint =
	Vector2.new(
		.5,
		.5
	)

breadcrumbarrow.Position =
	UDim2.new(
		.5,
		0,
		.5,
		1
	)

titlesecondary = label(
	breadcrumb,
	"Main",
	UDim2.fromOffset(
		0,
		28
	),
	medium,
	theme.text3
)

titlesecondary.LayoutOrder = 3

titlesecondary.TextSize = 18
titlesecondary.ZIndex = 14

closebutton = new("TextButton", {
	Parent = header,
	AnchorPoint = Vector2.new(1, .5),
	Position = UDim2.new(1, -14, .5, 0),
	Size = UDim2.fromOffset(uis.TouchEnabled and 36 or 30, uis.TouchEnabled and 36 or 30),
	BackgroundColor3 = theme.hover,
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Text = "",
	AutoButtonColor = false,
	Active = uis.TouchEnabled,
	Visible = uis.TouchEnabled,
	ZIndex = 16,
})
corner(closebutton, 7)

closeline1 = new("Frame", {
	Parent = closebutton,
	AnchorPoint = Vector2.new(.5, .5),
	Position = UDim2.fromScale(.5, .5),
	Size = UDim2.fromOffset(14, 2.3),
	Rotation = 45,
	BackgroundColor3 = theme.text3,
	BackgroundTransparency = .08,
	BorderSizePixel = 0,
	ZIndex = 17,
})
corner(closeline1, 999)

closeline2 = new("Frame", {
	Parent = closebutton,
	AnchorPoint = Vector2.new(.5, .5),
	Position = UDim2.fromScale(.5, .5),
	Size = UDim2.fromOffset(14, 2.3),
	Rotation = -45,
	BackgroundColor3 = theme.text3,
	BackgroundTransparency = .08,
	BorderSizePixel = 0,
	ZIndex = 17,
})
corner(closeline2, 999)

closebutton.MouseEnter:Connect(function()
	if not windowminimizebuttonenabled then
		return
	end

	closeline1.BackgroundTransparency = 0
	closeline2.BackgroundTransparency = 0
	tween(closeline1, {BackgroundColor3 = theme.text}, hoverti)
	tween(closeline2, {BackgroundColor3 = theme.text}, hoverti)
end)

closebutton.MouseLeave:Connect(function()
	if not windowminimizebuttonenabled then
		return
	end

	closeline1.BackgroundTransparency = .08
	closeline2.BackgroundTransparency = .08
	tween(closeline1, {BackgroundColor3 = theme.text3}, hoverti)
	tween(closeline2, {BackgroundColor3 = theme.text3}, hoverti)
end)

closebutton.Activated:Connect(function()
	requestvisibilitytoggle()
end)

searchholder = new("Frame", {
	Parent = header,

	AnchorPoint =
		Vector2.new(
			1,
			.5
		),

	Position =
		UDim2.new(
			1,
			-52,
			.5,
			0
		),

	Size =
		UDim2.fromOffset(
			150,
			38
		),

	BackgroundColor3 =
		theme.input,

	BorderSizePixel = 0,

	Active = true,

	ZIndex = 14,
})

searchfadetoken = 0
searchfadeanimations = {}
minimizelineanimation1 = nil
minimizelineanimation2 = nil

corner(searchholder, 9)
searchshadow = addshadow(searchholder, "SearchShadow", .94, 8, 1, -1, Color3.fromRGB(0, 0, 0), UDim2.fromOffset(0, 2), false)

function updatebreadcrumblayout()
	if not header or not header.Parent then
		return
	end

	local width = math.max(1, header.AbsoluteSize.X)
	local closevisible = windowminimizebuttonenabled == true
	local rightinset = closevisible and 52 or 14
	local searchvisible = searchenabled and not uis.TouchEnabled
	local searchwidth = searchvisible and searchholder.AbsoluteSize.X or 0
	local left = uis.TouchEnabled and 58 or 21
	local right = searchvisible
		and width - rightinset - searchwidth - 12
		or width - rightinset
	local available = math.max(40, right - left)

	local primarywidth = math.ceil(measuretext(
		titleprimary.Text,
		titleprimary.TextSize,
		titleprimary.Font,
		Vector2.new(100000, 28)
	).X)
	local hassubtitle = titlesecondary.Visible and titlesecondary.Text ~= ""
	local secondarywidth = hassubtitle and math.ceil(measuretext(
		titlesecondary.Text,
		titlesecondary.TextSize,
		titlesecondary.Font,
		Vector2.new(100000, 28)
	).X) or 0

	if hassubtitle then
		local textspace = math.max(0, available - 24)
		if primarywidth + secondarywidth > textspace then
			local primarymax = math.max(32, math.floor(textspace * .6))
			primarywidth = math.min(primarywidth, primarymax)
			secondarywidth = math.min(secondarywidth, math.max(0, textspace - primarywidth))
		end
	else
		primarywidth = math.min(primarywidth, available)
	end

	titleprimary.Size = UDim2.fromOffset(math.max(1, primarywidth), 28)
	titleprimary.TextTruncate = Enum.TextTruncate.AtEnd
	titlesecondary.Size = UDim2.fromOffset(math.max(0, secondarywidth), 28)
	titlesecondary.TextTruncate = Enum.TextTruncate.AtEnd

	local contentwidth = primarywidth + (hassubtitle and (secondarywidth + 24) or 0)
	contentwidth = math.min(contentwidth, available)
	breadcrumb.AnchorPoint = Vector2.new(.5, .5)
	breadcrumb.Position = UDim2.fromOffset(math.round((left + right) * .5), 31)
	breadcrumb.Size = UDim2.fromOffset(math.max(1, contentwidth), 28)
end

function updateheadercontrols()
	if not header or not header.Parent then
		return
	end

	local width = math.max(0, header.AbsoluteSize.X)
	local closevisible = windowminimizebuttonenabled == true
	local rightinset = closevisible and 52 or 14
	local searchwidth = math.clamp(width - 190, 96, 150)

	searchholder.Size = UDim2.fromOffset(searchwidth, 38)
	searchholder.Position = UDim2.new(1, -rightinset, .5, 0)
	closebutton.Size = UDim2.fromOffset(30, 30)
	closebutton.Position = UDim2.new(1, -14, .5, 0)
	updatebreadcrumblayout()
end

connect(
	header:GetPropertyChangedSignal("AbsoluteSize"),
	updateheadercontrols
)

updateheadercontrols()

for _, object in ipairs({titleprimary, titlesecondary}) do
	connect(object:GetPropertyChangedSignal("Text"), updatebreadcrumblayout)
	connect(object:GetPropertyChangedSignal("TextSize"), updatebreadcrumblayout)
	connect(object:GetPropertyChangedSignal("Font"), updatebreadcrumblayout)
	connect(object:GetPropertyChangedSignal("Visible"), updatebreadcrumblayout)
end

function setminimizebuttonvisible(value, animate)
	value = value == true
	local changed = windowminimizebuttonenabled ~= value
	windowminimizebuttonenabled = value

	for _, animation in ipairs({minimizelineanimation1, minimizelineanimation2}) do
		if animation then
			invoke(function() animation:Cancel() end)
		end
	end

	minimizelineanimation1 = nil
	minimizelineanimation2 = nil
	closebutton.Active = value

	if value then
		closebutton.Visible = true
	end

	updateheadercontrols()
	if topnavigationenabled and updatetopnavigationlayout then
		updatetopnavigationlayout()
	end

	if not animate or not animationsenabled or not changed then
		closebutton.Visible = value
		closeline1.BackgroundTransparency = value and .08 or 1
		closeline2.BackgroundTransparency = value and .08 or 1
		return
	end

	local target = value and .08 or 1
	if value then
		closeline1.BackgroundTransparency = 1
		closeline2.BackgroundTransparency = 1
	end

	local info = TweenInfo.new(.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	minimizelineanimation1 = tween(closeline1, {BackgroundTransparency = target}, info)
	minimizelineanimation2 = tween(closeline2, {BackgroundTransparency = target}, info)

	local animation = minimizelineanimation2 or minimizelineanimation1
	if animation then
		animation.Completed:Connect(function()
			if minimizelineanimation2 ~= animation and minimizelineanimation1 ~= animation then
				return
			end

			minimizelineanimation1 = nil
			minimizelineanimation2 = nil
			if not windowminimizebuttonenabled then
				closebutton.Visible = false
			end
		end)
	end
end

function setsearchvisible(value, animate)
	value = value == true and not uis.TouchEnabled
	local changed = searchenabled ~= value
	searchenabled = value
	searchfadetoken += 1
	local token = searchfadetoken
	searchholder.Active = value

	if search then
		search.Active = value
		search.TextEditable = value
	end

	for _, animation in ipairs(searchfadeanimations) do
		invoke(function() animation:Cancel() end)
	end
	table.clear(searchfadeanimations)

	if value then
		searchholder.Visible = true
	end

	updateheadercontrols()
	if topnavigationenabled and updatetopnavigationlayout then
		updatetopnavigationlayout()
	end

	local parts = {
		{searchholder, "BackgroundTransparency", value and effectivetransparency(0, "input") or 1},
	}

	if searchicon and searchicon.Parent then
		parts[#parts + 1] = {searchicon, "ImageTransparency", value and effectivefontalpha(0) or 1}
	end

	if search and search.Parent then
		parts[#parts + 1] = {search, "TextTransparency", value and effectivefontalpha(0) or 1}
	end

	if searchshadow and searchshadow.Parent then
		local base = searchshadow:GetAttribute("BlushBaseTransparency") or .94
		parts[#parts + 1] = {searchshadow, "Transparency", value and base or 1}
	end

	if not animate or not animationsenabled or not changed then
		for _, part in ipairs(parts) do
			part[1][part[2]] = part[3]
		end
		searchholder.Visible = value
		return
	end

	local primary
	for _, part in ipairs(parts) do
		local animation = tween(
			part[1],
			{[part[2]] = part[3]},
			TweenInfo.new(.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
			true
		)
		if animation then
			searchfadeanimations[#searchfadeanimations + 1] = animation
			primary = primary or animation
		end
	end

	local function finish()
		if token ~= searchfadetoken then
			return
		end
		table.clear(searchfadeanimations)
		if not searchenabled then
			searchholder.Visible = false
		end
	end

	if primary then
		primary.Completed:Connect(finish)
	else
		finish()
	end
end

searchicon = image(
	searchholder,
	icons.search,
	20,
	theme.text3,
	15
)

searchicon.AnchorPoint =
	Vector2.new(
		0,
		.5
	)

searchicon.Position =
	UDim2.fromOffset(
		10,
		19
	)

search = new("TextBox", {
	Parent = searchholder,

	Position =
		UDim2.fromOffset(
			38,
			-1
		),

	Size =
		UDim2.new(
			1,
			-46,
			1,
			0
		),

	BackgroundTransparency = 1,
	BorderSizePixel = 0,

	Text = "",
	PlaceholderText = "search...",

	PlaceholderColor3 =
		theme.text3,

	TextColor3 =
		theme.text,

	Font = font,
	TextSize = 18,

	TextXAlignment =
		Enum.TextXAlignment.Left,

	ClearTextOnFocus = false,

	ZIndex = 15,
})

content = new("Frame", {
	Parent = main,

	Position =
		UDim2.fromOffset(
			14,
			62
		),

	Size =
		UDim2.new(
			1,
			-28,
			1,
			-76
		),

	BackgroundTransparency = 1,

	ZIndex = 12,
})

popuplayer = new("CanvasGroup", {
	Parent = gui,

	Size =
		UDim2.fromScale(
			1,
			1
		),

	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	GroupTransparency = 0,

	ClipsDescendants = false,

	ZIndex = 500,
})

draglayer = new("CanvasGroup", {
	Parent = gui,

	Size =
		UDim2.fromScale(
			1,
			1
		),

	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	GroupTransparency = 0,

	ClipsDescendants = false,

	ZIndex = 400,
})

function makedragghost(source, zindex)
	local absolute = source.AbsolutePosition - draglayer.AbsolutePosition
	local size = source.AbsoluteSize
	local holder = rawnew("Frame", {
		Parent = draglayer,
		Position = UDim2.fromOffset(absolute.X, absolute.Y),
		Size = UDim2.fromOffset(size.X, size.Y),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ClipsDescendants = false,
		ZIndex = zindex or 460,
	})

	local clone = source:Clone()
	clone.Parent = holder
	clone.AnchorPoint = Vector2.zero
	clone.Position = UDim2.fromOffset(0, 0)
	clone.Size = UDim2.fromScale(1, 1)
	clone.LayoutOrder = 0

	for _, object in ipairs(clone:GetDescendants()) do
		if object:IsA("GuiObject") then
			object.ZIndex += (zindex or 460)
		end
	end
	clone.ZIndex += (zindex or 460)

	return holder, clone
end

function hideforghost(source)
	local state = {}
	local objects = {source}
	for _, object in ipairs(source:GetDescendants()) do
		objects[#objects + 1] = object
	end

	for _, object in ipairs(objects) do
		if object:IsA("GuiObject") then
			local props = {}
			if object.BackgroundTransparency ~= nil then
				props.BackgroundTransparency = object.BackgroundTransparency
				object.BackgroundTransparency = 1
			end
			if object:IsA("TextLabel") or object:IsA("TextButton") then
				props.TextTransparency = object.TextTransparency
				object.TextTransparency = 1
			end
			if object:IsA("ImageLabel") or object:IsA("ImageButton") then
				props.ImageTransparency = object.ImageTransparency
				object.ImageTransparency = 1
			end
			if next(props) then
				state[#state + 1] = {object = object, props = props}
			end
		elseif object:IsA("UIStroke") or object:IsA("UIShadow") then
			state[#state + 1] = {object = object, props = {Transparency = object.Transparency}}
			object.Transparency = 1
		end
	end

	return state
end

function restorefromghost(state)
	for _, entry in ipairs(state or {}) do
		local object = entry.object
		if object and object.Parent then
			for property, value in pairs(entry.props) do
				object[property] = value
			end
		end
	end
end

-- notifications

notificationdrag = nil

notificationholder = new("Frame", {
	Parent = gui,

	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -18, 0, 18),
	Size = UDim2.fromOffset(336, 560),

	BackgroundTransparency = 1,
	BorderSizePixel = 0,

	ClipsDescendants = false,
	ZIndex = 700,
})

new("UIListLayout", {
	Parent = notificationholder,

	FillDirection = Enum.FillDirection.Vertical,
	HorizontalAlignment = Enum.HorizontalAlignment.Right,
	VerticalAlignment = Enum.VerticalAlignment.Top,

	Padding = UDim.new(0, 8),
	SortOrder = Enum.SortOrder.LayoutOrder,
})

notifications = {}
notificationorder = 0

notificationin = TweenInfo.new(
	.24,
	Enum.EasingStyle.Quint,
	Enum.EasingDirection.Out
)

notificationout = TweenInfo.new(
	.20,
	Enum.EasingStyle.Quint,
	Enum.EasingDirection.Out
)

notificationreturn = TweenInfo.new(
	.24,
	Enum.EasingStyle.Quint,
	Enum.EasingDirection.Out
)

function notificationasset(value)
	if value == nil then
		return nil
	end

	if type(value) == "number" then
		return "rbxassetid://" .. tostring(value)
	end

	local result = tostring(value)

	if string.match(result, "^%d+$") then
		return "rbxassetid://" .. result
	end

	return result ~= "" and result or nil
end

function removenotification(data)
	for i = #notifications, 1, -1 do
		if notifications[i] == data then
			table.remove(notifications, i)
			break
		end
	end
end

function dismissnotification(data, velocity)
	if not data or data.closing then
		return
	end

	data.closing = true
	removenotification(data)

	if notificationdrag
		and notificationdrag.data == data
	then
		notificationdrag = nil
	end

	local wrapper = data.wrapper
	local card = data.card

	if not wrapper or not wrapper.Parent then
		return
	end

	local animation

	if card and card.Parent then
		animation =
			tween(
				card,
				{GroupTransparency = 1},
				notificationout
			)
	end

	local function destroy()
		if wrapper and wrapper.Parent then
			wrapper:Destroy()
		end
	end

	if animation then
		animation.Completed:Connect(
			destroy
		)
	else
		destroy()
	end
end

function notify(
	titletext,
	bodytext,
	duration,
	actiontext,
	actioncallback,
	iconasset
)
	if notificationsenabled == false then
		return
	end

	local options

	if type(actiontext) == "table" then
		options = actiontext

		actiontext =
			options.action
			or options.button
			or options.actiontext

		actioncallback =
			options.callback
			or options.actioncallback

		iconasset = options.icon
	end

	notificationorder += 1

	local titlevalue = tostring(titletext or "blush.")
	local bodyvalue = tostring(bodytext or "")
	local lifetime = math.max(1, tonumber(duration) or defaultnotificationduration)
	local actionvalue = actiontext and tostring(actiontext) or nil
	local iconvalue = notificationasset(iconasset)

	local hasaction =
		actionvalue ~= nil
		and actionvalue ~= ""

	local hasicon =
		iconvalue ~= nil
		and iconvalue ~= ""

	local viewportwidth = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.X or 360
	local cardwidth = uis.TouchEnabled
		and math.min(316, math.max(220, viewportwidth - 36))
		or 316
	local leftpadding = hasicon and 48 or 14
	local rightpadding = 14
	local textwidth =
		cardwidth
		- leftpadding
		- rightpadding

	local bodysize = measuretext(
		plaintext(bodyvalue),
		15,
		font,
		Vector2.new(textwidth, 1000)
	)

	local contentheight = math.max(18, bodysize.Y)

	local height = math.max(
		hasaction and 88 or 60,
		36
			+ contentheight
			+ (hasaction and 34 or 7)
	)

	local wrapper = new("Frame", {
		Parent = notificationholder,

		LayoutOrder = notificationorder,
		Size = UDim2.fromOffset(cardwidth, height),

		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ClipsDescendants = false,

		ZIndex = 701,
	})

	local card = new("CanvasGroup", {
		Parent = wrapper,

		Position = UDim2.fromOffset(0, 0),
		Size = UDim2.fromOffset(cardwidth, height),

		BackgroundColor3 = theme.popup,
		BackgroundTransparency = 0,
		BorderSizePixel = 0,

		GroupTransparency = 1,
		ClipsDescendants = false,
		Active = true,

		ZIndex = 701,
	})

	corner(card, 9)
	adddepthshadow(card, "floating")
	stroke(
		card,
		.5,
		theme.border,
		.6
	)

	local dragarea = new("TextButton", {
		Parent = card,
		Size = UDim2.fromScale(1, 1),

		BackgroundColor3 = theme.hover,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,

		Text = "",
		AutoButtonColor = false,

		ZIndex = 702,
	})

	corner(dragarea, 9)

	local iconobject

	if hasicon then
		iconobject = image(
			card,
			iconvalue,
			23,
			theme.text2,
			704
		)

		iconobject.Position = UDim2.fromOffset(14, 10)
	end

	local title = label(
		card,
		titlevalue,
		UDim2.new(1, -leftpadding - rightpadding, 0, 21),
		bold,
		theme.text
	)

	title.Position = UDim2.fromOffset(leftpadding, 7)
	title.TextSize = 16
	title.TextTruncate = Enum.TextTruncate.AtEnd
	title.ZIndex = 704

	local bodytextobject = label(
		card,
		bodyvalue,
		UDim2.new(
			1,
			-leftpadding - rightpadding,
			0,
			contentheight + 2
		),
		font,
		theme.text3
	)

	bodytextobject.Position = UDim2.fromOffset(leftpadding, 29)
	bodytextobject.TextSize = 15
	bodytextobject.TextWrapped = true
	bodytextobject.TextYAlignment = Enum.TextYAlignment.Top
	bodytextobject.ZIndex = 704

	local actionbutton

	if hasaction then
		actionbutton = new("TextButton", {
			Parent = card,

			AnchorPoint = Vector2.new(1, 1),
			Position = UDim2.new(1, -11, 1, -10),
			Size = UDim2.fromOffset(
				math.clamp(
					measuretext(
						plaintext(actionvalue),
						14,
						medium,
						Vector2.new(180, 22)
					).X + 22,
					58,
					160
				),
				27
			),

			BackgroundColor3 = theme.white,
			BackgroundTransparency = 0,
			BorderSizePixel = 0,

			Text = actionvalue,
			TextColor3 = theme.black,
			TextSize = 14,
			Font = medium,
			AutoButtonColor = false,

			ZIndex = 706,
		})

		corner(actionbutton, 6)
	end

	local data = {
		wrapper = wrapper,
		card = card,
		dragarea = dragarea,
		closing = false,
	}

	table.insert(notifications, data)

	while #notifications > maxnotifications do
		dismissnotification(notifications[1])
	end


	dragarea.InputBegan:Connect(function(input)
		if data.closing then
			return
		end

		if input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch
		then
			return
		end

		local start = point(input)

		notificationdrag = {
			data = data,
			input = input,
			start = start,
			current = start,
			last = start,
			lasttime = os.clock(),
			velocity = 0,
		}
	end)

	if actionbutton then
		actionbutton.MouseEnter:Connect(function()
			tween(actionbutton, {TextTransparency = .14}, hoverti)
		end)

		actionbutton.MouseLeave:Connect(function()
			tween(actionbutton, {TextTransparency = 0}, hoverti)
		end)

		actionbutton.Activated:Connect(function()
			if data.closing then
				return
			end

			if actioncallback then
				task.spawn(function()
					invoke(actioncallback)
				end)
			end

			dismissnotification(data)
		end)
	end

	tween(
		card,
		{GroupTransparency = 0},
		notificationin
	)

	task.delay(lifetime, function()
		if data
			and not data.closing
			and data.card
			and data.card.Parent
		then
			dismissnotification(data)
		end
	end)

	return data
end

env.__blush_notify = notify

pages = {}

currentpage = nil
currentnav = nil
currentsub = nil

activepopup = nil
topprimarypopup = nil
interactionowner = nil
topprimarygesture = nil

windowdrag = nil
watermarkdrag = nil
sliderdrag = nil
pickerdrag = nil
sectiondrag = nil

animatedpickers = {}
pickeranimationconnection = nil
interactionrenderconnection = nil
animateduielements = setmetatable({}, { __mode = "k" })
animateduiconnection = nil

function stopanimateduiloop()
	local connection = animateduiconnection
	animateduiconnection = nil

	if connection and connection.Connected then
		connection:Disconnect()
	end
end

function ensureanimateduiloop()
	if animateduiconnection and animateduiconnection.Connected then
		return
	end

	animateduiconnection = runservice.RenderStepped:Connect(function(dt)
		if next(animateduielements) == nil then
			stopanimateduiloop()
			return
		end

		for object, data in pairs(animateduielements) do
			if not object.Parent then
				animateduielements[object] = nil
			elseif data.kind == "spinner" then
				if animationsenabled then
					data.value = (data.value + dt * 180) % 360
					object.Rotation = data.value
				end
			elseif data.kind == "bar" then
				if animationsenabled then
					data.value = (data.value + dt * .7) % 1
					object.Position = UDim2.new(-.28 + data.value * 1.28, 0, 0, 0)
				else
					object.Position = UDim2.new(.36, 0, 0, 0)
				end
			end
		end
	end)
end

function registeranimatedui(object, kind)
	animateduielements[object] = { kind = kind, value = 0 }
	ensureanimateduiloop()

	object.Destroying:Connect(function()
		animateduielements[object] = nil
		if next(animateduielements) == nil then
			stopanimateduiloop()
		end
	end)
end

function stoppickeranimationloop()
	local connection = pickeranimationconnection
	pickeranimationconnection = nil

	if connection and connection.Connected then
		connection:Disconnect()
	end
end

function ensurepickeranimationloop()
	if pickeranimationconnection
		and pickeranimationconnection.Connected
	then
		return
	end

	pickeranimationconnection =
		runservice.RenderStepped:Connect(function(dt)
			if next(animatedpickers) == nil then
				stoppickeranimationloop()
				return
			end

			for pickerstate in pairs(animatedpickers) do
				pickerstate:update(dt)
			end
		end)
end

function acquireinteraction(kind, owner)
	if interactionowner
		and interactionowner.owner ~= owner
	then
		return false
	end

	interactionowner = {
		kind = kind,
		owner = owner,
	}

	return true
end

function releaseinteraction(owner)
	if interactionowner
		and (
			owner == nil
			or interactionowner.owner == owner
		)
	then
		interactionowner = nil
	end
end

-- popup

function closepopup()
	if not activepopup then
		return
	end

	local popup = activepopup
	activepopup = nil

	if popup.onclose then
		popup.onclose()
	end

	if popup.blocker and popup.blocker.Parent then
		popup.blocker:Destroy()
	end

	if not popup.panel or not popup.panel.Parent then
		return
	end

	local animation =
		tween(
			popup.panel,
			{GroupTransparency = 1},
			dropti
		)

	local function destroy()
		if popup.panel
			and popup.panel.Parent
		then
			popup.panel:Destroy()
		end
	end

	if animation then
		local completed
		completed = animation.Completed:Connect(function()
			if completed then
				completed:Disconnect()
				completed = nil
			end

			destroy()
		end)
	else
		destroy()
	end
end

function createpopup(
	position,
	width,
	height,
	zindex,
	kind
)
	closepopup()

	local rootsize =
		popuplayer.AbsoluteSize

	local x =
		math.clamp(
			position.X,
			8,
			math.max(
				8,
				rootsize.X
					- width
					- 8
			)
		)

	local y =
		position.Y

	local blocker = nil

	local panel
	local animationobject

	if kind == "color" then
		local margin = 12

		local group = new("CanvasGroup", {
			Parent = popuplayer,

			Position =
				UDim2.fromOffset(
					x - margin,
					y - margin
				),

			Size =
				UDim2.fromOffset(
					width + margin * 2,
					height + margin * 2
				),

			BackgroundTransparency = 1,
			BorderSizePixel = 0,

			GroupTransparency = 1,
			ClipsDescendants = true,
			Active = true,

			ZIndex = zindex + 1,
		})

		panel = new("Frame", {
			Parent = group,

			Position =
				UDim2.fromOffset(
					margin,
					margin
				),

			Size =
				UDim2.fromOffset(
					width,
					height
				),

			BackgroundColor3 =
				theme.popup,

			BorderSizePixel = 0,
			ClipsDescendants = false,
			Active = true,

			ZIndex = zindex + 1,
		})

		corner(panel, 9)
		local popupshadow = adddepthshadow(panel, "popup")
		if popupshadow then
			popupshadow:SetAttribute("BlushBaseTransparency", .62)
		end
		animationobject = group
	else
		panel = new("CanvasGroup", {
			Parent = popuplayer,

			Position =
				UDim2.fromOffset(
					x,
					y
				),

			Size =
				UDim2.fromOffset(
					width,
					height
				),

			BackgroundColor3 =
				theme.popup,

			BorderSizePixel = 0,
			GroupTransparency = 1,
			ClipsDescendants = true,
			Active = true,

			ZIndex = zindex + 1,
		})

		corner(panel, 9)
		local popupshadow = adddepthshadow(panel, "popup")
		if popupshadow then
			popupshadow:SetAttribute("BlushBaseTransparency", .62)
		end
		animationobject = panel
	end

	local popup = {
		panel = animationobject,
		content = panel,
		blocker = blocker,

		width = width,
		height = height,

		kind = kind,
	}

	activepopup = popup

	tween(
		animationobject,
		{GroupTransparency = 0},
		dropti
	)

	if uis.TouchEnabled then
		task.defer(function()
			applymobiletextscale(mobilefontscale)
		end)
	end

	return panel, popup
end

connect(uis.InputBegan, function(input)
	if not activepopup then
		return
	end

	local kind = input.UserInputType
	if kind ~= Enum.UserInputType.MouseButton1
		and kind ~= Enum.UserInputType.MouseButton2
		and kind ~= Enum.UserInputType.Touch
	then
		return
	end

	local inputpoint = point(input)

	if topprimarypopup
		and activepopup == topprimarypopup
		and topprimarybutton
		and topprimarybutton.Parent
		and inside(topprimarybutton, inputpoint)
	then
		return
	end

	if kind == Enum.UserInputType.MouseButton1
		and activepopup.anchor
		and activepopup.anchor.Parent
		and inside(activepopup.anchor, inputpoint)
	then
		return
	end

	if kind == Enum.UserInputType.MouseButton1
		and activepopup.toggleconfig
		and activepopup.binding
		and activepopup.binding.configbutton
		and activepopup.binding.configbutton.Parent
		and inside(activepopup.binding.configbutton, inputpoint)
	then
		return
	end

	local content = activepopup.content
	if content
		and content.Parent
		and inside(content, inputpoint)
	then
		return
	end

	closepopup()
end)

function overlayposition(object)
	return object.AbsolutePosition
		- popuplayer.AbsolutePosition
end


function opencontextmenu(position, entries)
	local width = 190
	local height = 8

	for _, entry in ipairs(entries or {}) do
		height += entry.Divider and 14 or 30
	end

	local rootpos = popuplayer.AbsolutePosition
	local localpos = position - rootpos
	local panel, popup = createpopup(
		Vector2.new(localpos.X + 4, localpos.Y + 4),
		width,
		height,
		560,
		"dropdown"
	)

	local content = new("Frame", {
		Parent = panel,
		Position = UDim2.fromOffset(4, 4),
		Size = UDim2.new(1, -8, 1, -8),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 562,
	})
	list(content, 2)

	for _, entry in ipairs(entries or {}) do
		if entry.Divider then
			local holder = new("Frame", {
				Parent = content,
				Size = UDim2.new(1, 0, 0, 12),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ZIndex = 563,
			})
			local line = new("Frame", {
				Parent = holder,
				AnchorPoint = Vector2.new(.5, .5),
				Position = UDim2.fromScale(.5, .5),
				Size = UDim2.new(1, -10, 0, 1),
				BackgroundColor3 = theme.border,
				BackgroundTransparency = .48,
				BorderSizePixel = 0,
				ZIndex = 564,
			})
			corner(line, 999)
		else
			local button = new("TextButton", {
				Parent = content,
				Size = UDim2.new(1, 0, 0, 28),
				BackgroundColor3 = theme.hover,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Text = "",
				AutoButtonColor = false,
				ZIndex = 563,
			})
			corner(button, 6)

			local x = 9
			if entry.Icon then
				local iconobject = image(button, entry.Icon, 16, theme.text2, 564)
				iconobject.AnchorPoint = Vector2.new(0, .5)
				iconobject.Position = UDim2.fromOffset(9, 14)
				x = 32
			end

			local textobject = label(
				button,
				entry.Text or entry.Name or "Option",
				UDim2.new(1, -(x + 8), 1, 0),
				font,
				theme.text2
			)
			textobject.Position = UDim2.fromOffset(x, 0)
			textobject.TextSize = 15
			textobject.ZIndex = 564

			button.MouseEnter:Connect(function()
				tween(textobject, {TextColor3 = theme.text}, hoverti)
			end)
			button.MouseLeave:Connect(function()
				tween(textobject, {TextColor3 = theme.text2}, hoverti)
			end)
			button.Activated:Connect(function()
				closepopup()
				if entry.Callback then
					entry.Callback()
				end
			end)
		end
	end

	return panel, popup
end

function attachcontextmenu(object, entries)
	object.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			opencontextmenu(point(input), entries)
		end
	end)

	object.TouchLongPress:Connect(function(touches, state)
		if state == Enum.UserInputState.Begin then
			local position = typeof(touches) == "table" and touches[1]
			if position then
				opencontextmenu(position, entries)
			end
		end
	end)

	return object
end

function closemodal()
	local modal = env.__blush_modal
	env.__blush_modal = nil

	if not modal
		or not modal.root
		or not modal.root.Parent
	then
		return
	end

	local root = modal.root
	local blocker = modal.blocker
	local card = modal.card

	if blocker and blocker.Parent then
		tween(
			blocker,
			{BackgroundTransparency = 1},
			TweenInfo.new(.24, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
		)
	end

	local animation
	if card and card.Parent then
		animation = tween(
			card,
			{GroupTransparency = 1},
			TweenInfo.new(.24, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
		)
	end

	if animation then
		animation.Completed:Connect(function()
			if root.Parent then
				root:Destroy()
			end
		end)
	else
		root:Destroy()
	end
end

function showmodal(titletext, bodytext, actions)
	closepopup()
	closemodal()

	local root = new("Frame", {
		Parent = popuplayer,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 700,
	})

	local blocker = new("TextButton", {
		Parent = root,
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 700,
	})

	local modalviewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(800, 450)
	local modalwidth = uis.TouchEnabled and math.min(360, math.max(260, modalviewport.X - 28)) or 360

	local card = new("CanvasGroup", {
		Parent = root,
		AnchorPoint = Vector2.new(.5, .5),
		Position = UDim2.fromScale(.5, .5),
		Size = UDim2.fromOffset(modalwidth, uis.TouchEnabled and 178 or 170),
		BackgroundColor3 = theme.popup,
		BackgroundTransparency = .025,
		BorderSizePixel = 0,
		GroupTransparency = 1,
		ZIndex = 701,
	})
	corner(card, 10)
	stroke(card, .48, theme.border, .6)
	addshadow(card, "ModalShadow", .76, 20, 3, -1, Color3.fromRGB(0, 0, 0), UDim2.fromOffset(0, 5), false)

	local titleobject = label(
		card,
		titletext or "Dialog",
		UDim2.new(1, -32, 0, 28),
		bold,
		theme.text
	)
	titleobject.Position = UDim2.fromOffset(16, 13)
	titleobject.TextSize = 19
	titleobject.ZIndex = 702

	local bodyobject = label(
		card,
		bodytext or "",
		UDim2.new(1, -32, 0, 64),
		font,
		theme.text2
	)
	bodyobject.Position = UDim2.fromOffset(16, 46)
	bodyobject.TextSize = 15
	bodyobject.TextWrapped = true
	bodyobject.TextYAlignment = Enum.TextYAlignment.Top
	bodyobject.ZIndex = 702

	local divider = new("Frame", {
		Parent = card,
		Position = UDim2.new(0, 16, 1, -55),
		Size = UDim2.new(1, -32, 0, 1),
		BackgroundColor3 = theme.border,
		BackgroundTransparency = .52,
		BorderSizePixel = 0,
		ZIndex = 702,
	})
	corner(divider, 999)

	local actionrow = new("Frame", {
		Parent = card,
		Position = UDim2.new(0, 16, 1, -45),
		Size = UDim2.new(1, -32, 0, 32),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 702,
	})
	new("UIListLayout", {
		Parent = actionrow,
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 7),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	for index, action in ipairs(actions or {{ Text = "Close" }}) do
		local primary = action.Primary == true
		local button = new("TextButton", {
			Parent = actionrow,
			LayoutOrder = index,
			Size = UDim2.fromOffset(94, 30),
			BackgroundColor3 = primary and theme.white or theme.input,
			BackgroundTransparency = primary and .02 or .04,
			BorderSizePixel = 0,
			Text = action.Text or "Action",
			TextColor3 = primary and theme.black or theme.text2,
			Font = medium,
			TextSize = 15,
			AutoButtonColor = false,
			ZIndex = 703,
		})
		corner(button, 7)
		stroke(button, primary and .78 or .62, primary and theme.white or theme.border, .55)

		button.MouseEnter:Connect(function()
			tween(button, {
				TextColor3 = primary and theme.black or theme.text,
				TextTransparency = 0,
			}, hoverti)
		end)
		button.MouseLeave:Connect(function()
			tween(button, {
				TextColor3 = primary and theme.black or theme.text2,
				TextTransparency = 0,
			}, hoverti)
		end)
		button.Activated:Connect(function()
			closemodal()
			if action.Callback then
				action.Callback()
			end
		end)
	end

	blocker.Activated:Connect(closemodal)
	env.__blush_modal = {
		root = root,
		blocker = blocker,
		card = card,
	}

	tween(
		blocker,
		{BackgroundTransparency = .58},
		TweenInfo.new(.24, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	)
	tween(
		card,
		{GroupTransparency = 0},
		TweenInfo.new(.24, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	)

	return root
end

function confirmdialog(titletext, bodytext, callback)
	return showmodal(
		titletext or "Confirm",
		bodytext or "Are you sure?",
		{
			{ Text = "Cancel", Cancel = true },
			{ Text = "Confirm", Primary = true, Callback = callback },
		}
	)
end

env.__blush_togglebindings = {}
env.__blush_pending_keybinds = {}

hotkeyfontsize = 14
hotkeylistwidth = 268
hotkeyminimized = false

hotkeylist = new("CanvasGroup", {
	Parent = gui,
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -18, .5, -27),
	Size = UDim2.fromOffset(hotkeylistwidth, 54),
	BackgroundColor3 = theme.popup,
	BackgroundTransparency = 0,
	BorderSizePixel = 0,
	Visible = false,
	GroupTransparency = 0,
	ZIndex = 320,
})
corner(hotkeylist, 9)
stroke(hotkeylist, .62, theme.border, .55)
adddepthshadow(hotkeylist, "floating")
addshadow(
	hotkeylist,
	"HotkeyPanelGlow",
	.965,
	12,
	0,
	-2,
	theme.white,
	UDim2.fromOffset(0, 0),
	true
)

hotkeyheadericon = image(
	hotkeylist,
	icons.keyboard,
	15,
	theme.text3,
	323
)
hotkeyheadericon.AnchorPoint = Vector2.new(0, .5)
hotkeyheadericon.Position = UDim2.fromOffset(12, 16)
hotkeyheadericon.ImageTransparency = .08

hotkeytitle = label(hotkeylist, "Keybinds", UDim2.new(1, -72, 0, 30), medium, theme.text)
hotkeytitle.Position = UDim2.fromOffset(34, 1)
hotkeytitle.TextXAlignment = Enum.TextXAlignment.Left
hotkeytitle.TextSize = 16
hotkeytitle.ZIndex = 321

hotkeycollapse = new("ImageButton", {
	Parent = hotkeylist,
	AnchorPoint = Vector2.new(1, .5),
	Position = UDim2.new(1, -8, 0, 16),
	Size = UDim2.fromOffset(20, 20),
	BackgroundColor3 = theme.hover,
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Image = icons.down,
	ImageColor3 = theme.text3,
	ImageTransparency = .12,
	AutoButtonColor = false,
	ZIndex = 325,
})
corner(hotkeycollapse, 6)

hotkeydragarea = rawnew("TextButton", {
	Parent = hotkeylist,
	Position = UDim2.fromOffset(0, 0),
	Size = UDim2.new(1, -36, 0, 31),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Text = "",
	AutoButtonColor = false,
	Active = true,
	ZIndex = 324,
})

hotkeycontent = new("CanvasGroup", {
	Parent = hotkeylist,
	Position = UDim2.fromOffset(8, 32),
	Size = UDim2.new(1, -16, 1, -39),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ClipsDescendants = true,
	GroupTransparency = 0,
	ZIndex = 321,
})

hotkeyscroll = new("ScrollingFrame", {
	Parent = hotkeycontent,
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	CanvasSize = UDim2.fromOffset(0, 0),
	ScrollBarThickness = 0,
	ScrollingDirection = Enum.ScrollingDirection.Y,
	ElasticBehavior = Enum.ElasticBehavior.Never,
	ZIndex = 322,
})
list(hotkeyscroll, 2)
hotkeyshown = false
hotkeytargetposition = hotkeylist.Position
hotkeydrag = nil
hotkeymoveanimation = nil
hotkeycontentanimation = nil
hotkeycollapseanimation = nil
hotkeysizeanimation = nil
hotkeyvisibilitytoken = 0
hotkeyminimizetoken = 0
hotkeyminimizeanimating = false
hotkeyanimti = TweenInfo.new(.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
hotkeyfullheight = 54
hotkeyrows = setmetatable({}, { __mode = "k" })
hotkeygroups = {}
hotkeyempty = nil
hotkeydirty = false

function requesthotkeyrefresh(binding)
	if not hotkeylist.Visible then
		hotkeydirty = true
		return
	end

	if binding then
		local data = hotkeyrows[binding]
		if data and data.row and data.row.Parent then
			local active = false
			local ok, value = invoke(binding.get)
			if ok then
				active = value == true
			end

			updatehotkeyrow(
				data,
				binding,
				active,
				data.row.LayoutOrder,
				true
			)
			hotkeydirty = false
			return
		end
	end

	refreshhotkeylist()
end

function sethotkeyheight(targetheight)
	targetheight = math.max(32, math.round(targetheight))
	hotkeylist.Size = UDim2.fromOffset(hotkeylistwidth, targetheight)
end

function synchotkeyminimizedstate()
	if hotkeyminimizeanimating then
		return
	end

	if hotkeycontentanimation then
		invoke(function()
			hotkeycontentanimation:Cancel()
		end)
		hotkeycontentanimation = nil
	end

	if hotkeyminimized then
		sethotkeyheight(32)
		hotkeycontent.GroupTransparency = 1
		hotkeycontent.Visible = false
		hotkeycollapse.Rotation = -90
	else
		sethotkeyheight(hotkeyfullheight)
		hotkeycontent.Visible = true
		hotkeycontent.GroupTransparency = 0
		hotkeycollapse.Rotation = 0
	end
end

function sethotkeyminimized(value, animate)
	value = value == true
	local changed = hotkeyminimized ~= value
	hotkeyminimized = value
	hotkeyminimizetoken += 1
	local token = hotkeyminimizetoken

	if hotkeycontentanimation then
		invoke(function()
			hotkeycontentanimation:Cancel()
		end)
		hotkeycontentanimation = nil
	end

	if hotkeycollapseanimation then
		invoke(function()
			hotkeycollapseanimation:Cancel()
		end)
		hotkeycollapseanimation = nil
	end

	if hotkeysizeanimation then
		invoke(function()
			hotkeysizeanimation:Cancel()
		end)
		hotkeysizeanimation = nil
	end

	local targetheight = value and 32 or hotkeyfullheight
	local rotation = value and -90 or 0

	if not animate or not changed then
		hotkeyminimizeanimating = false
		sethotkeyheight(targetheight)
		hotkeycontent.Visible = not value
		hotkeycontent.GroupTransparency = value and 1 or 0
		hotkeycollapse.Rotation = rotation
		return
	end

	-- Keep the top-left position completely fixed. Only height/transparency/rotation animate.
	hotkeyminimizeanimating = true
	hotkeycontent.Visible = true

	hotkeysizeanimation = tween(
		hotkeylist,
		{Size = UDim2.fromOffset(hotkeylistwidth, targetheight)},
		TweenInfo.new(.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	)

	hotkeycollapseanimation = tween(
		hotkeycollapse,
		{Rotation = rotation},
		TweenInfo.new(.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	)

	hotkeycontentanimation = tween(
		hotkeycontent,
		{GroupTransparency = value and 1 or 0},
		TweenInfo.new(.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	)

	if hotkeysizeanimation then
		hotkeysizeanimation.Completed:Connect(function()
			if token ~= hotkeyminimizetoken then
				return
			end

			hotkeyminimizeanimating = false

			if value then
				hotkeycontent.Visible = false
				hotkeycontent.GroupTransparency = 1
			else
				hotkeycontent.Visible = true
				hotkeycontent.GroupTransparency = 0
			end
		end)
	end
end

hotkeycollapse.MouseEnter:Connect(function()
	tween(hotkeycollapse, {
		ImageColor3 = theme.text2,
		ImageTransparency = 0,
	}, hoverti)
end)
hotkeycollapse.MouseLeave:Connect(function()
	tween(hotkeycollapse, {
		ImageColor3 = theme.text3,
		ImageTransparency = .12,
	}, hoverti)
end)
hotkeycollapse.Activated:Connect(function()
	sethotkeyminimized(not hotkeyminimized, true)
end)

hotkeydragarea.InputBegan:Connect(function(input)
	if input.UserInputType ~= Enum.UserInputType.MouseButton1
		and input.UserInputType ~= Enum.UserInputType.Touch
	then
		return
	end

	hotkeydrag = {
		input = input,
		start = point(input),
		position = hotkeytargetposition,
	}
end)

connect(uis.InputChanged, function(input)
	if not hotkeydrag then return end
	local ismouse = input.UserInputType == Enum.UserInputType.MouseMovement
	local istouch = input.UserInputType == Enum.UserInputType.Touch and input == hotkeydrag.input
	if not ismouse and not istouch then return end

	local delta = point(input) - hotkeydrag.start
	local target = offsetposition(hotkeydrag.position, delta)
	local size = hotkeylist.AbsoluteSize
	local root = popuplayer.AbsoluteSize
	local x = math.clamp(target.X.Offset, -root.X + size.X + 8, -8)
	local y = math.clamp(target.Y.Offset, -root.Y * .5 + 8, root.Y * .5 - size.Y - 8)
	hotkeytargetposition = UDim2.new(1, x, .5, y)
	hotkeylist.Position = hotkeytargetposition
end)

connect(uis.InputEnded, function(input)
	if not hotkeydrag then return end
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input ~= hotkeydrag.input then return end
	hotkeydrag = nil
end)

function sethotkeylistvisible(value)
	value = value == true
	if value == hotkeyshown and hotkeylist.Visible == value then
		if value then
			refreshhotkeylist()
		end
		return
	end

	hotkeyshown = value
	hotkeyvisibilitytoken += 1
	local token = hotkeyvisibilitytoken

	if hotkeymoveanimation then
		invoke(function()
			hotkeymoveanimation:Cancel()
		end)
		hotkeymoveanimation = nil
	end

	if value then
		hotkeylist.Visible = true
		hotkeylist.GroupTransparency = 1
		refreshhotkeylist()
		synchotkeyminimizedstate()
		hotkeymoveanimation = tween(
			hotkeylist,
			{GroupTransparency = 0},
			hotkeyanimti
		)
	else
		if not hotkeylist.Visible then
			return
		end

		hotkeymoveanimation = tween(
			hotkeylist,
			{GroupTransparency = 1},
			hotkeyanimti
		)

		local function finish()
			if token ~= hotkeyvisibilitytoken or hotkeyshown then
				return
			end

			hotkeylist.Visible = false
			hotkeylist.GroupTransparency = 0
		end

		if hotkeymoveanimation then
			hotkeymoveanimation.Completed:Connect(finish)
		else
			finish()
		end
	end
end

function hotkeycategoryicon(binding)
	if not binding then
		return nil
	end

	if binding.page
		and binding.page.icon ~= nil
	then
		return binding.page.icon
	end

	return binding.categoryicon
end


function updatehotkeygroup(data, category, binding)
	local asset = hotkeycategoryicon(binding)
	data.category = category

	if data.asset ~= asset then
		data.asset = asset

		if data.icon and data.icon.Parent then
			data.icon:Destroy()
		end

		data.icon = nil

		if asset ~= nil and tostring(asset) ~= "" then
			data.icon = image(data.holder, asset, 13, theme.text3, 323)
			data.icon.AnchorPoint = Vector2.new(0, .5)
			data.icon.Position = UDim2.fromOffset(4, 22)
			data.icon.ImageTransparency = .08
		end
	end

	local textx = data.icon and 23 or 4
	data.text.Text = tostring(category)
	data.text.Position = UDim2.fromOffset(textx, 10)
	data.text.Size = UDim2.new(1, -textx - 4, 0, 24)
end

function createhotkeygroup(key, category, binding)
	local holder = new("Frame", {
		Parent = hotkeyscroll,
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 322,
	})

	local textobject = label(
		holder,
		tostring(category),
		UDim2.new(1, -8, 0, 24),
		medium,
		theme.text2
	)
	textobject.Position = UDim2.fromOffset(4, 10)
	textobject.TextSize = 13
	textobject.TextXAlignment = Enum.TextXAlignment.Left
	textobject.ZIndex = 323

	local data = {
		holder = holder,
		icon = nil,
		text = textobject,
		category = category,
		asset = nil,
		key = key,
	}

	updatehotkeygroup(data, category, binding)
	hotkeygroups[key] = data
	return data
end

function createhotkeyrow(binding)
	local row = new("TextButton", {
		Parent = hotkeyscroll,
		Size = UDim2.new(1, 0, 0, 26),
		BackgroundColor3 = theme.hover,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 322,
	})
	corner(row, 6)

	local checkbox, rendercheckbox = makecheckbox(
		row,
		15,
		false
	)
	checkbox.AnchorPoint = Vector2.new(0, .5)
	checkbox.Position = UDim2.new(0, 5, .5, 0)

	local nametext = label(
		row,
		tostring(binding.name or "Toggle"),
		UDim2.new(1, -82, 1, 0),
		font,
		theme.text3
	)
	nametext.Position = UDim2.fromOffset(28, 0)
	nametext.TextSize = 13
	nametext.TextXAlignment = Enum.TextXAlignment.Left
	nametext.TextTruncate = Enum.TextTruncate.AtEnd
	nametext.ZIndex = 323

	local keyholder = new("Frame", {
		Parent = row,
		AnchorPoint = Vector2.new(1, .5),
		Position = UDim2.new(1, -4, .5, 0),
		Size = UDim2.fromOffset(34, 22),
		BackgroundColor3 = theme.input,
		BackgroundTransparency = .34,
		BorderSizePixel = 0,
		ZIndex = 323,
	})
	corner(keyholder, 6)
	stroke(keyholder, .7, theme.border, .6)

	local keytext = label(
		keyholder,
		"",
		UDim2.fromScale(1, 1),
		medium,
		theme.text3
	)
	keytext.TextSize = 13
	keytext.TextXAlignment = Enum.TextXAlignment.Center
	keytext.ZIndex = 324

	local data = {
		binding = binding,
		row = row,
		nametext = nametext,
		keyholder = keyholder,
		keytext = keytext,
		checkbox = checkbox,
		rendercheckbox = rendercheckbox,
		active = nil,
		name = nil,
		keyname = nil,
	}

	row.MouseEnter:Connect(function()
		if row.Parent then
			tween(nametext, {TextColor3 = theme.text}, hoverti)
			tween(keytext, {TextColor3 = theme.text2}, hoverti)
		end
	end)

	row.MouseLeave:Connect(function()
		if row.Parent then
			local color = data.active and theme.text2 or theme.text3
			tween(nametext, {TextColor3 = color}, hoverti)
			tween(keytext, {TextColor3 = color}, hoverti)
		end
	end)

	row.Activated:Connect(function()
		local ok, current = invoke(binding.get)
		if ok and binding.set then
			binding.set(not (current == true), true)
		end
	end)

	hotkeyrows[binding] = data
	return data
end

function updatehotkeyrow(data, binding, active, layoutorder, animate)
	local name = tostring(binding.name or "Toggle")
	local keyname = togglekeyname(binding.key)
	data.row.LayoutOrder = layoutorder

	if data.name ~= name then
		data.name = name
		data.nametext.Text = name
	end

	if data.keyname ~= keyname then
		data.keyname = keyname
		data.keytext.Text = keyname
	end

	local keybounds = measuretext(keyname, 13, medium, Vector2.new(200, 22))
	local singlecharacter = #plaintext(keyname) == 1
	local keywidth = math.clamp(
		math.ceil(keybounds.X) + (singlecharacter and 14 or 18),
		singlecharacter and 28 or 38,
		88
	)

	data.keyholder.Size = UDim2.fromOffset(keywidth, 22)
	data.nametext.Size = UDim2.new(1, -keywidth - 48, 1, 0)

	local changed = data.active ~= active
	if data.rendercheckbox then
		data.rendercheckbox(active)
	end
	data.active = active
	local color = active and theme.text2 or theme.text3

	if changed and animate then
		tween(data.nametext, {TextColor3 = color}, hotkeyanimti)
		tween(data.keytext, {TextColor3 = color}, hotkeyanimti)
		tween(data.keyholder, {BackgroundTransparency = active and .18 or .34}, hotkeyanimti)
	else
		data.nametext.TextColor3 = color
		data.keytext.TextColor3 = color
		data.keyholder.BackgroundTransparency = active and .18 or .34
	end
end

function refreshhotkeylist()
	if not hotkeylist.Visible then
		hotkeydirty = true
		return
	end

	hotkeydirty = false

	local seen = {}
	local seengroups = {}
	local groups = {}
	local groupmap = {}
	local count = 0

	for _, binding in ipairs(env.__blush_togglebindings or {}) do
		if binding.key ~= nil
			and (
				not binding.anchor
				or binding.anchor.Parent
			)
		then
			local category = tostring(
				binding.subpage
					or binding.category
					or "Misc"
			)

			local groupkey =
				binding.page
				or category
			local group = groupmap[groupkey]

			if not group then
				group = {
					key = groupkey,
					name = category,
					bindings = {},
					first = binding,
				}

				groupmap[groupkey] = group
				groups[#groups + 1] = group
			end

			group.bindings[#group.bindings + 1] = binding
			count += 1
		end
	end

	local layoutorder = 0
	local contentheight = 0
	local itemcount = 0

	for _, group in ipairs(groups) do
		local groupdata = hotkeygroups[group.key]

		if not groupdata
			or not groupdata.holder
			or not groupdata.holder.Parent
		then
			groupdata =
				createhotkeygroup(
					group.key,
					group.name,
					group.first
				)
		else
			updatehotkeygroup(
				groupdata,
				group.name,
				group.first
			)
		end

		seengroups[group.key] = true
		layoutorder += 1
		groupdata.holder.LayoutOrder = layoutorder
		contentheight += 36
		itemcount += 1

		for _, binding in ipairs(group.bindings) do
			seen[binding] = true
			local active = false
			local ok, value = invoke(binding.get)

			if ok then
				active = value == true
			end

			local data = hotkeyrows[binding]
			local created = false

			if not data
				or not data.row
				or not data.row.Parent
			then
				data = createhotkeyrow(binding)
				created = true
			end

			layoutorder += 1
			updatehotkeyrow(
				data,
				binding,
				active,
				layoutorder,
				not created
			)
			contentheight += 26
			itemcount += 1
		end
	end

	for binding, data in pairs(hotkeyrows) do
		if not seen[binding] then
			if data.row and data.row.Parent then
				data.row:Destroy()
			end

			hotkeyrows[binding] = nil
		end
	end

	for groupkey, data in pairs(hotkeygroups) do
		if not seengroups[groupkey] then
			if data.holder and data.holder.Parent then
				data.holder:Destroy()
			end

			hotkeygroups[groupkey] = nil
		end
	end

	if count == 0 then
		if not hotkeyempty
			or not hotkeyempty.Parent
		then
			hotkeyempty = label(
				hotkeyscroll,
				"No keybinds",
				UDim2.new(1, 0, 0, 26),
				font,
				theme.text3
			)
			hotkeyempty.TextSize = hotkeyfontsize
			hotkeyempty.ZIndex = 322
		end

		contentheight = 26
		itemcount = 1
	else
		if hotkeyempty
			and hotkeyempty.Parent
		then
			hotkeyempty:Destroy()
		end

		hotkeyempty = nil
	end

	if itemcount > 1 then
		contentheight += (itemcount - 1) * 2
	end

	hotkeyscroll.CanvasSize =
		UDim2.fromOffset(
			0,
			math.max(26, contentheight)
		)

	local maxcontent =
		uis.TouchEnabled
		and 220
		or 340

	hotkeyfullheight =
		39
		+ math.min(
			math.max(26, contentheight),
			maxcontent
		)

	synchotkeyminimizedstate()
end


function togglekeyname(key)
	if not key then
		return "None"
	end

	local aliases = {
		LeftShift = "LShift",
		RightShift = "RShift",
		LeftControl = "LCtrl",
		RightControl = "RCtrl",
		LeftAlt = "LAlt",
		RightAlt = "RAlt",
		Backquote = "`",
		CapsLock = "Caps",
		Return = "Enter",
		MouseButton1 = "M1",
		MouseButton2 = "M2",
		MouseButton3 = "M3",
	}

	return aliases[key.Name]
		or key.Name
end

function validmousebind(inputtype)
	return inputtype == Enum.UserInputType.MouseButton1
		or inputtype == Enum.UserInputType.MouseButton2
		or inputtype == Enum.UserInputType.MouseButton3
end

keyeditbuttons = setmetatable({}, { __mode = "k" })

function iskeyeditclick(input)
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
		return false
	end

	local position = point(input)
	for button in pairs(keyeditbuttons) do
		if button.Parent and button.Visible and guivisible(button) and inside(button, position) then
			return true
		end
	end

	return false
end

function bindingmatchesinput(key, input)
	if not key then
		return false
	end

	if key.EnumType == Enum.KeyCode then
		return input.UserInputType == Enum.UserInputType.Keyboard
			and input.KeyCode == key
	end

	if key.EnumType == Enum.UserInputType then
		return validmousebind(key)
			and input.UserInputType == key
	end

	return false
end

keybindblacklistdefaults = {
	"MouseButton1",
	"W",
	"A",
	"S",
	"D",
	"Space",
}

keybindblacklist = {}

keybindblacklistlabelmap = {
	MouseButton1 = "M1",
	MouseButton2 = "M2",
	MouseButton3 = "M3",
	Zero = "0",
	One = "1",
	Two = "2",
	Three = "3",
	Four = "4",
	Five = "5",
	Six = "6",
	Seven = "7",
	Eight = "8",
	Nine = "9",
	Backquote = "`",
	Minus = "-",
	Equals = "=",
	LeftBracket = "[",
	RightBracket = "]",
	BackSlash = "\\",
	Semicolon = ";",
	Quote = "'",
	Comma = ",",
	Period = ".",
	Slash = "/",
	Return = "Enter",
	Escape = "Esc",
	Delete = "Del",
	Insert = "Ins",
	PageUp = "PgUp",
	PageDown = "PgDn",
	Up = "↑",
	Down = "↓",
	Left = "←",
	Right = "→",
	LeftShift = "LShift",
	RightShift = "RShift",
	LeftControl = "LCtrl",
	RightControl = "RCtrl",
	LeftAlt = "LAlt",
	RightAlt = "RAlt",
}

keybindblacklistreverse = {}
for name, labelvalue in pairs(keybindblacklistlabelmap) do
	keybindblacklistreverse[labelvalue] = name
end

keybindblacklistoptions = {
	"M1", "M2", "M3",
	"A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M",
	"N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z",
	"0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
	"Space", "Tab", "Enter", "Esc", "Backspace", "Del", "Ins", "Home", "End", "PgUp", "PgDn",
	"↑", "↓", "←", "→",
	"LShift", "RShift", "LCtrl", "RCtrl", "LAlt", "RAlt",
	"`", "-", "=", "[", "]", "\\", ";", "'", ",", ".", "/",
	"F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8", "F9", "F10", "F11", "F12",
}

function keybindblacklistcanonical(value)
	value = tostring(value or "")
	return keybindblacklistreverse[value] or value
end

function keybindblacklistlabel(value)
	value = tostring(value or "")
	return keybindblacklistlabelmap[value] or value
end

function setkeybindblacklist(values)
	table.clear(keybindblacklist)

	for _, value in ipairs(
		type(values) == "table"
			and values
			or keybindblacklistdefaults
	) do
		keybindblacklist[keybindblacklistcanonical(value)] = true
	end
end

function getkeybindblacklistlabels()
	local result = {}

	for _, labelvalue in ipairs(keybindblacklistoptions) do
		if keybindblacklist[keybindblacklistcanonical(labelvalue)] then
			result[#result + 1] = labelvalue
		end
	end

	return result
end

function getkeybindblacklistnames()
	local result = {}

	for _, labelvalue in ipairs(keybindblacklistoptions) do
		local name = keybindblacklistcanonical(labelvalue)

		if keybindblacklist[name] then
			result[#result + 1] = name
		end
	end

	return result
end

function iskeybindblacklisted(key)
	return key ~= nil
		and keybindblacklist[key.Name] == true
end

setkeybindblacklist(keybindblacklistdefaults)

keycaptureowner = nil

function capturephysicalkey(input)
	if input.UserInputType == Enum.UserInputType.Keyboard then
		return input.KeyCode
	end

	if validmousebind(input.UserInputType) then
		return input.UserInputType
	end

	return nil
end

function beginkeycapture(owner, cancelcallback, selectcallback, ignorecallback)
	if keycaptureowner and keycaptureowner.owner ~= owner then
		local previous = keycaptureowner
		keycaptureowner = nil

		if previous.cancel then
			previous.cancel()
		end

		releaseinteraction(previous.owner)
	end

	if not acquireinteraction("keycapture", owner) then
		return false
	end

	keycaptureowner = {
		owner = owner,
		cancel = cancelcallback,
		select = selectcallback,
		ignore = ignorecallback,
	}
	keypickercapturing = true
	return true
end

function endkeycapture(owner, suppresskey)
	if keycaptureowner and keycaptureowner.owner ~= owner then
		return false
	end

	keycaptureowner = nil
	keypickercapturing = false
	releaseinteraction(owner)

	if suppresskey then
		keypickersuppress = suppresskey
	end

	return true
end

function dispatchtogglebinding(key, began)
	if keypickercapturing
		or keypickersuppress == key
	then
		return
	end

	for _, binding in ipairs(
		env.__blush_togglebindings or {}
	) do
		local anchor = binding.anchor

		if binding.key == key
			and (
				not anchor
				or anchor.Parent
			)
		then
			if began then
				if not binding.held then
					binding.held = true

					if binding.mode == "Toggle" then
						binding.set(
							not binding.get(),
							true
						)

					elseif binding.mode == "Hold"
						or binding.mode == "Always On"
					then
						binding.set(true, true)
					end
				end
			else
				binding.held = false

				if binding.mode == "Hold" then
					binding.set(false, true)
				end
			end
		end
	end
end

function setbindingkey(binding, key, persist)
	if not binding then
		return
	end

	local previous = binding.key

	if previous == key then
		binding.held = false

		if binding.refreshkey then
			binding.refreshkey()
		end

		requesthotkeyrefresh(binding)
		return
	end

	binding.key = key
	binding.held = false


	if binding.refreshkey then
		binding.refreshkey()
	end
	requesthotkeyrefresh(binding)

	if persist ~= false then
		requestconfigautosave()
	end
end

function unregistertogglebinding(binding)
	if not binding then
		return
	end

	local previous = binding.key

	for index = #env.__blush_togglebindings, 1, -1 do
		if env.__blush_togglebindings[index] == binding then
			table.remove(env.__blush_togglebindings, index)
			break
		end
	end


	local row = hotkeyrows[binding]
	if row and row.row and row.row.Parent then
		row.row:Destroy()
	end
	hotkeyrows[binding] = nil
	requesthotkeyrefresh()
end

function opentoggleconfig(anchor, binding, clickposition, togglesame)
	if activepopup
		and activepopup.toggleconfig
	then
		if activepopup.binding == binding then
			if togglesame == true then
				closepopup()
			end
			return
		end

		local previous = activepopup
		activepopup = nil

		if previous.onclose then
			previous.onclose()
		end

		if previous.blocker
			and previous.blocker.Parent
		then
			previous.blocker:Destroy()
		end

		if previous.panel
			and previous.panel.Parent
		then
			previous.panel:Destroy()
		end
	end

	local anchorpos =
		overlayposition(anchor)

	local anchorsize =
		anchor.AbsoluteSize

	local width = 228
	local hasinlinekey = binding.inlinekey == true
	local collapsedheight = hasinlinekey and 72 or 103
	local expandedheight = hasinlinekey and 166 or 197

	local popuporigin

	if typeof(clickposition) == "Vector2" then
		popuporigin =
			clickposition
			- popuplayer.AbsolutePosition
	else
		popuporigin =
			Vector2.new(
				anchorpos.X
					+ math.min(
						28,
						anchorsize.X * .18
					),
				anchorpos.Y
					+ anchorsize.Y
			)
	end

	local x = popuporigin.X + 7
	local y = popuporigin.Y + 7

	x = math.clamp(
		x,
		8,
		math.max(
			8,
			popuplayer.AbsoluteSize.X
				- width
				- 8
		)
	)

	y = math.clamp(
		y,
		8,
		math.max(
			8,
			popuplayer.AbsoluteSize.Y
				- expandedheight
				- 8
		)
	)

	local panel, popup =
		createpopup(
			Vector2.new(x, y),
			width,
			collapsedheight,
			540,
			"dropdown"
		)

	popup.toggleconfig = true
	popup.binding = binding

	if popup.blocker
		and popup.blocker.Parent
	then
		popup.blocker:Destroy()
		popup.blocker = nil
	end

	stroke(
		panel,
		.44,
		theme.border,
		.65
	)

	local title = label(
		panel,
		binding.name,
		UDim2.new(
			1,
			-20,
			0,
			28
		),
		bold,
		theme.text
	)

	title.Position =
		UDim2.fromOffset(
			10,
			5
		)

	title.TextSize = 16
	title.ZIndex = 544


	local keylabel = label(
		panel,
		"Key",
		UDim2.fromOffset(
			90,
			28
		),
		font,
		theme.text2
	)

	keylabel.Position =
		UDim2.fromOffset(
			10,
			37
		)
	keylabel.Visible = not hasinlinekey

	keylabel.TextSize = 15
	keylabel.ZIndex = 544

	local keybutton = new("TextButton", {
		Parent = panel,
		Visible = not hasinlinekey,

		AnchorPoint =
			Vector2.new(1, 0),

		Position =
			UDim2.new(
				1,
				-10,
				0,
				37
			),

		Size =
			UDim2.fromOffset(
				54,
				27
			),

		BackgroundColor3 = theme.input,
		BackgroundTransparency = .04,
		BorderSizePixel = 0,

		Text = "",
		AutoButtonColor = false,
		ZIndex = 545,
	})

	corner(keybutton, 6)
	keyeditbuttons[keybutton] = true

	local keybuttonstroke =
		stroke(
			keybutton,
			.66,
			theme.border,
			.6
		)

	local keytext = label(
		keybutton,
		"",
		UDim2.fromScale(1, 1),
		medium,
		theme.text2
	)

	keytext.TextSize = 14
	keytext.TextXAlignment =
		Enum.TextXAlignment.Center
	keytext.ZIndex = 546

	local modelabel = label(
		panel,
		"Mode",
		UDim2.fromOffset(
			90,
			28
		),
		font,
		theme.text2
	)

	modelabel.Position =
		UDim2.fromOffset(
			10,
			hasinlinekey and 37 or 68
		)

	modelabel.TextSize = 15
	modelabel.ZIndex = 544

	local modebutton = new("TextButton", {
		Parent = panel,

		AnchorPoint =
			Vector2.new(1, 0),

		Position =
			UDim2.new(
				1,
				-10,
				0,
				hasinlinekey and 37 or 68
			),

		Size =
			UDim2.fromOffset(
				108,
				27
			),

		BackgroundColor3 = theme.input,
		BackgroundTransparency = .04,
		BorderSizePixel = 0,

		Text = "",
		AutoButtonColor = false,
		ZIndex = 545,
	})

	corner(modebutton, 6)
	stroke(
		modebutton,
		.66,
		theme.border,
		.6
	)

	local modetext = label(
		modebutton,
		binding.mode,
		UDim2.new(
			1,
			-28,
			1,
			0
		),
		font,
		theme.text2
	)

	modetext.Position =
		UDim2.fromOffset(
			9,
			0
		)

	modetext.TextSize = 14
	modetext.ZIndex = 546

	local modearrow = image(
		modebutton,
		icons.down,
		12,
		theme.text3,
		546
	)

	modearrow.AnchorPoint =
		Vector2.new(1, .5)

	modearrow.Position =
		UDim2.new(
			1,
			-8,
			.5,
			0
		)

	local options = new("Frame", {
		Parent = panel,

		Position =
			UDim2.fromOffset(
				10,
				hasinlinekey and 73 or 104
			),

		Size =
			UDim2.new(
				1,
				-20,
				0,
				88
			),

		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 545,
	})

	list(options, 2)

	local listening = false
	local modeopen = false
	local modeentries = {}

	local function rendermode()
		modetext.Text = binding.mode

		for mode, button in pairs(modeentries) do
			button.TextColor3 =
				mode == binding.mode
				and theme.text
				or theme.text2
		end
	end

	local function renderkey()
		local value =
			listening
			and "..."
			or togglekeyname(binding.key)

		keytext.Text = value

		local bounds =
			measuretext(
				value,
				14,
				medium,
				Vector2.new(
					200,
					27
				)
			)

		local widthvalue =
			math.clamp(
				math.ceil(bounds.X) + 20,
				42,
				112
			)

		tween(
			keybutton,
			{
				Size =
					UDim2.fromOffset(
						widthvalue,
						27
					),
			},
			fastti
		)

		tween(
			keybuttonstroke,
			{
				Color = theme.border,
				Transparency =
					listening
					and .38
					or .66,
			},
			fastti
		)

		if binding.refreshkey then
			binding.refreshkey()
		end
	end

	local function setmodeopen(value)
		modeopen = value == true
		options.Visible = modeopen

		tween(
			modearrow,
			{
				Rotation =
					modeopen
					and 180
					or 0,
			},
			tabti
		)

		popup.height =
			modeopen
			and expandedheight
			or collapsedheight

		tween(
			panel,
			{
				Size =
					UDim2.fromOffset(
						width,
						popup.height
					),
			},
			dropti
		)
	end

	for _, mode in ipairs({
		"Toggle",
		"Hold",
		"Always On",
	}) do
		local option = new("TextButton", {
			Parent = options,
			Size =
				UDim2.new(
					1,
					0,
					0,
					28
				),
			BackgroundColor3 = theme.hover,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Text = mode,
			TextColor3 =
				mode == binding.mode
				and theme.text
				or theme.text2,
			Font = font,
			TextSize = 14,
			TextXAlignment =
				Enum.TextXAlignment.Left,
			AutoButtonColor = false,
			ZIndex = 546,
		})

		corner(option, 6)
		padding(option, 9, 9)
		modeentries[mode] = option

		option.MouseEnter:Connect(function()
			tween(option, {TextColor3 = theme.text}, hoverti)
		end)

		option.MouseLeave:Connect(function()
			tween(option, {
				TextColor3 = mode == binding.mode and theme.text or theme.text2,
			}, hoverti)
		end)

		option.Activated:Connect(function()
			binding.mode = mode
			rendermode()
			requesthotkeyrefresh(binding)
			requestconfigautosave()

			if mode == "Always On" then
				binding.set(true, true)
			elseif mode == "Hold" then
				binding.held = false
				binding.set(false, true)
			end

			setmodeopen(false)
		end)
	end

	keybutton.MouseEnter:Connect(function()
		tween(keytext, {TextColor3 = theme.text}, hoverti)
	end)

	keybutton.MouseLeave:Connect(function()
		tween(keytext, {TextColor3 = theme.text2}, hoverti)
	end)

	modebutton.MouseEnter:Connect(function()
		tween(modetext, {TextColor3 = theme.text}, hoverti)
	end)

	modebutton.MouseLeave:Connect(function()
		tween(modetext, {TextColor3 = theme.text2}, hoverti)
	end)

	modebutton.Activated:Connect(function()
		setmodeopen(not modeopen)
	end)

	if not hasinlinekey then
		keybutton.Activated:Connect(function()
			if listening then
				listening = false
				endkeycapture(popup, nil)
				renderkey()
				return
			end

			listening = true

			if not beginkeycapture(
				popup,
				function()
					listening = false
					renderkey()
				end,
				function(selectedkey)
					listening = false
					setbindingkey(binding, selectedkey)
					renderkey()
				end,
				function(input)
					return input.UserInputType == Enum.UserInputType.MouseButton1
						and inside(keybutton, point(input))
				end
			) then
				listening = false
			end

			renderkey()
		end)
	end


	popup.onclose = function()
		listening = false
		endkeycapture(popup, false)
	end

	rendermode()
	renderkey()
end

function hotkeybindingid(binding)
	return table.concat({
		tostring(binding.kind or "Toggle"),
		tostring(binding.category or ""),
		tostring(binding.subpage or ""),
		tostring(binding.sectionname or ""),
		tostring(binding.name or ""),
	}, "|")
end

function applysavedkeybind(binding, data)
	if not binding or type(data) ~= "table" then
		return
	end

	local key =
		data.key
		and keyfromname(data.key)
		or nil

	if key ~= nil then
		setbindingkey(binding, key, false)
	elseif data.key == false
		or data.key == "None"
	then
		setbindingkey(binding, nil, false)
	end

	local mode =
		tostring(data.mode or binding.mode or "Toggle")

	if mode ~= "Toggle"
		and mode ~= "Hold"
		and mode ~= "Always On"
	then
		mode = "Toggle"
	end

	binding.mode = mode
	binding.held = false

	if binding.refreshkey then
		binding.refreshkey()
	end

	if mode == "Always On"
		and binding.set
	then
		binding.set(true, false)
	end
	requesthotkeyrefresh(binding)
end

function currentkeybindpayload()
	local payload = {}

	for _, binding in ipairs(
		env.__blush_togglebindings or {}
	) do
		local id =
			binding.id
			or hotkeybindingid(binding)

		binding.id = id

		payload[id] = {
			key = binding.key
				and binding.key.Name
				or false,

			mode = binding.mode
				or "Toggle",
		}
	end

	return payload
end

function applykeybindpayload(payload)
	env.__blush_pending_keybinds =
		type(payload) == "table"
		and payload
		or {}

	for _, binding in ipairs(
		env.__blush_togglebindings or {}
	) do
		local id =
			binding.id
			or hotkeybindingid(binding)

		binding.id = id

		local data =
			env.__blush_pending_keybinds[id]

		if data then
			applysavedkeybind(
				binding,
				data
			)
		end
	end

	refreshhotkeylist()
end

function registertogglebinding(binding)
	if not binding then
		return
	end

	for _, current in ipairs(env.__blush_togglebindings) do
		if current == binding then
			return
		end
	end

	binding.id =
		binding.id
		or hotkeybindingid(binding)

	table.insert(env.__blush_togglebindings, binding)

	local pending =
		env.__blush_pending_keybinds
		and env.__blush_pending_keybinds[
			binding.id
		]

	if pending then
		applysavedkeybind(
			binding,
			pending
		)
	end
	requesthotkeyrefresh(binding)
end

function attachtoggleconfig(anchor, binding)
	if binding.configattached
		and binding.anchor
		and binding.anchor.Parent
	then
		return
	end

	binding.configattached = true
	binding.anchor = anchor

	registertogglebinding(binding)

	local destroying
	destroying = anchor.Destroying:Connect(function()
		if destroying then
			destroying:Disconnect()
			destroying = nil
		end

		unregistertogglebinding(binding)
	end)

	anchor.TouchLongPress:Connect(function(touchpositions, state)
		if state == Enum.UserInputState.Begin then
			binding.suppressclick = true

			local touchpoint

			if typeof(touchpositions) == "table" then
				touchpoint = touchpositions[1]
			end

			opentoggleconfig(
				anchor,
				binding,
				touchpoint
			)

		elseif state == Enum.UserInputState.End then
			binding.suppressclick = false
		end
	end)
end

function addtoggleconfigicon(
	anchor,
	binding,
	iconparent,
	rightinset
)
	local parentobject =
		iconparent or anchor

	local button = new("TextButton", {
		Parent = parentobject,
		AnchorPoint = Vector2.new(1, .5),
		Position = UDim2.new(1, -(rightinset or 0), .5, 0),
		Size = UDim2.fromOffset(20, 18),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 20,
	})

	keyeditbuttons[button] = true

	local iconobject = image(
		button,
		icons.keyboard,
		16,
		theme.text3,
		21
	)
	iconobject.AnchorPoint = Vector2.new(.5, .5)
	iconobject.Position = UDim2.fromScale(.5, .5)
	iconobject.ImageTransparency = .14

	binding.configbutton = button

	button.MouseEnter:Connect(function()
		tween(iconobject, {
			ImageColor3 = theme.text2,
			ImageTransparency = 0,
		}, hoverti)
	end)

	button.MouseLeave:Connect(function()
		tween(iconobject, {
			ImageColor3 = theme.text3,
			ImageTransparency = .14,
		}, hoverti)
	end)

	local clickposition

	button.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			clickposition = point(input)
		end
	end)

	button.Activated:Connect(function()
		binding.suppressclick = true

		opentoggleconfig(
			anchor,
			binding,
			clickposition or uis:GetMouseLocation(),
			true
		)

		clickposition = nil
		binding.suppressclick = false
	end)

	return button
end

connect(
	uis.InputBegan,
	function(input)
		if uis.TouchEnabled then
			return
		end

		local capture = keycaptureowner
		if capture then
			if capture.ignore and capture.ignore(input) then
				return
			end

			local physical = capturephysicalkey(input)
			if not physical or physical == Enum.KeyCode.Unknown then
				return
			end

			if physical == Enum.KeyCode.Escape then
				local cancel = capture.cancel
				endkeycapture(capture.owner, physical)
				if cancel then
					cancel()
				end
				return
			end

			local selected = physical
			if physical == Enum.KeyCode.Backspace or physical == Enum.KeyCode.Delete then
				selected = nil
			elseif iskeybindblacklisted(physical) then
				return
			end

			local selectcallback = capture.select
			endkeycapture(capture.owner, physical)
			if selectcallback then
				selectcallback(selected, input)
			end
			return
		end

		if bindingmatchesinput(keypickersuppress, input) or iskeyeditclick(input) then
			return
		end

		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			local inputpoint = point(input)

			for index = #env.__blush_togglebindings, 1, -1 do
				local binding = env.__blush_togglebindings[index]
				local anchor = binding.anchor

				if anchor and anchor.Parent and guivisible(anchor) and inside(anchor, inputpoint) then
					binding.suppressclick = true
					opentoggleconfig(anchor, binding, inputpoint, false)
					binding.suppressclick = false
					return
				end
			end
		end

		local physical = capturephysicalkey(input)
		if physical and physical ~= Enum.KeyCode.Unknown then
			dispatchtogglebinding(physical, true)
		end
	end
)

connect(
	uis.InputEnded,
	function(input)
		if bindingmatchesinput(keypickersuppress, input) then
			keypickersuppress = nil
			return
		end

		if uis.TouchEnabled then
			return
		end

		local physical = capturephysicalkey(input)
		if physical and physical ~= Enum.KeyCode.Unknown then
			dispatchtogglebinding(physical, false)
		end
	end
)

inlinekeycapture = nil

function stopinlinekeycapture(suppresskey)
	local state = inlinekeycapture
	if not state then
		return
	end

	inlinekeycapture = nil
	state.listening = false
	endkeycapture(state, suppresskey)

	if state.render then
		state.render()
	end

end

function attachinlinekeypicker(
	row,
	binding,
	textobject,
	defaultkey,
	keycallback
)
	attachtoggleconfig(row, binding)
	setbindingkey(binding, defaultkey or binding.key or Enum.KeyCode.F, false)
	binding.inlinekey = true

	local configbutton = addtoggleconfigicon(
		row,
		binding,
		row,
		0
	)

	local keybutton = new("TextButton", {
		Parent = row,
		AnchorPoint = Vector2.new(1, .5),
		Position = UDim2.new(1, -27, .5, 0),
		Size = UDim2.fromOffset(48, 20),
		BackgroundColor3 = theme.input,
		BackgroundTransparency = .08,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		Active = true,
		ZIndex = 19,
	})
	corner(keybutton, 6)
	keyeditbuttons[keybutton] = true
	stroke(keybutton, .72, theme.border, .6)

	local keytext = label(
		keybutton,
		"",
		UDim2.fromScale(1, 1),
		medium,
		theme.text2
	)
	keytext.TextSize = 13
	keytext.TextXAlignment = Enum.TextXAlignment.Center
	keytext.ZIndex = 20

	local state = {
		button = keybutton,
		binding = binding,
		listening = false,
		callback = keycallback,
	}

	local function renderkey()
		local value = state.listening and "..." or togglekeyname(binding.key)
		keytext.Text = value

		local bounds = measuretext(
			value,
			13,
			medium,
			Vector2.new(120, 20)
		)

		local width = math.clamp(math.ceil(bounds.X) + 18, 36, 72)
		keybutton.Size = UDim2.fromOffset(width, 20)

		if textobject and textobject.Parent then
			textobject.Size = UDim2.new(1, -(width + 72), 1, 0)
		end
	end

	state.render = renderkey
	binding.refreshkey = renderkey

	keybutton.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			binding.suppressclick = true
		end
	end)

	keybutton.Activated:Connect(function()
		if inlinekeycapture == state then
			stopinlinekeycapture(nil)
			binding.suppressclick = false
			return
		end

		if inlinekeycapture then
			stopinlinekeycapture(nil)
		end

		inlinekeycapture = state
		state.listening = true

		if not beginkeycapture(
			state,
			function()
				if inlinekeycapture == state then
					inlinekeycapture = nil
				end
				state.listening = false
				renderkey()
			end,
			function(selectedkey)
				inlinekeycapture = nil
				state.listening = false
				setbindingkey(binding, selectedkey)
				renderkey()

				if state.callback then
					state.callback(binding.key)
				end
			end,
			function(input)
				return input.UserInputType == Enum.UserInputType.MouseButton1
					and inside(keybutton, point(input))
			end
		) then
			inlinekeycapture = nil
			state.listening = false
		end

		renderkey()
		binding.suppressclick = false
	end)

	keybutton.MouseEnter:Connect(function()
		tween(keytext, {TextColor3 = theme.text}, hoverti)
	end)

	keybutton.MouseLeave:Connect(function()
		tween(keytext, {TextColor3 = theme.text2}, hoverti)
	end)

	renderkey()
	refreshhotkeylist()

	return keybutton, configbutton
end

-- page scrollbar

function createscrollbar(
	page,
	scroll,
	side
)
	local track = new("Frame", {
		Parent = page,

		AnchorPoint =
			Vector2.new(
				1,
				0
			),

		Position =
			side == "left"
			and UDim2.new(
				.5,
				-8,
				0,
				5
			)
			or UDim2.new(
				1,
				-2,
				0,
				5
			),

		Size =
			UDim2.new(
				0,
				2,
				1,
				-10
			),

		BackgroundColor3 =
			theme.scrollTrack,

		BackgroundTransparency =
			.86,

		BorderSizePixel = 0,

		ZIndex = 40,
	})

	corner(track, 999)

	local thumb = new("Frame", {
		Parent = track,

		Position =
			UDim2.fromOffset(
				0,
				0
			),

		Size =
			UDim2.fromOffset(
				2,
				24
			),

		BackgroundColor3 =
			theme.scroll,

		BackgroundTransparency =
			.38,

		BorderSizePixel = 0,

		Visible = false,

		ZIndex = 41,
	})

	corner(thumb, 999)

	local function update()
		local viewport =
			scroll.AbsoluteSize.Y

		local total =
			scroll.CanvasSize.Y.Offset

		local trackheight =
			track.AbsoluteSize.Y

		if viewport <= 0
			or total <= viewport + 1
			or trackheight <= 0
		then
			thumb.Visible = false
			track.BackgroundTransparency = 1
			return
		end

		thumb.Visible = true
		track.BackgroundTransparency = .86

		local height =
			math.clamp(
				viewport
					/ total
					* trackheight,
				22,
				trackheight
			)

		local maxcanvas =
			math.max(
				1,
				total - viewport
			)

		local ratio =
			math.clamp(
				scroll.CanvasPosition.Y
					/ maxcanvas,
				0,
				1
			)

		local travel =
			trackheight - height

		thumb.Size =
			UDim2.fromOffset(
				2,
				height
			)

		thumb.Position =
			UDim2.fromOffset(
				0,
				travel * ratio
			)
	end

	scroll:GetPropertyChangedSignal(
		"CanvasPosition"
	):Connect(update)

	scroll:GetPropertyChangedSignal(
		"AbsoluteSize"
	):Connect(update)

	scroll:GetPropertyChangedSignal(
		"CanvasSize"
	):Connect(update)

	track:GetPropertyChangedSignal(
		"AbsoluteSize"
	):Connect(update)

	return update
end

-- pages

function createpage(
	name,
	primary,
	secondary
)
	local pageframe = new("CanvasGroup", {
		Parent = content,

		Size =
			UDim2.fromScale(
				1,
				1
			),

		BackgroundTransparency = 1,
		GroupTransparency = 1,

		Visible = false,

		ZIndex = 12,
	})

	local left = new("ScrollingFrame", {
		Parent = pageframe,

		Size =
			UDim2.new(
				.5,
				-6,
				1,
				0
			),

		BackgroundTransparency = 1,
		BorderSizePixel = 0,

		CanvasSize =
			UDim2.fromOffset(
				0,
				0
			),

		ScrollBarThickness = 0,

		ScrollingDirection =
			Enum.ScrollingDirection.Y,

		ZIndex = 12,
	})

	local right = new("ScrollingFrame", {
		Parent = pageframe,

		AnchorPoint =
			Vector2.new(
				1,
				0
			),

		Position =
			UDim2.fromScale(
				1,
				0
			),

		Size =
			UDim2.new(
				.5,
				-6,
				1,
				0
			),

		BackgroundTransparency = 1,
		BorderSizePixel = 0,

		CanvasSize =
			UDim2.fromOffset(
				0,
				0
			),

		ScrollBarThickness = 0,

		ScrollingDirection =
			Enum.ScrollingDirection.Y,

		ZIndex = 12,
	})

	local page = {
		name = name,

		primary = primary,
		secondary = secondary,

		frame = pageframe,

		left = left,
		right = right,

		sections = {},
		order = 0,

		scrollupdates = {},
	}

	page.scrollupdates.left =
		createscrollbar(
			pageframe,
			left,
			"left"
		)

	page.scrollupdates.right =
		createscrollbar(
			pageframe,
			right,
			"right"
		)

	local function sectionvisible(section)
		return not section.floating
			and (
				section.dragging
				or section.frame.Visible
			)
	end

	function page:sorted(
		column,
		excluded
	)
		local result = {}

		for _, section in ipairs(
			self.sections
		) do
			if section ~= excluded
				and section.column == column
			then
				table.insert(
					result,
					section
				)
			end
		end

		table.sort(
			result,
			function(a, b)
				return a.order
					< b.order
			end
		)

		return result
	end

	function page:normalize(column)
		local index = 0

		for _, section in ipairs(
			self:sorted(column)
		) do
			index += 1
			section.order = index
		end
	end

	env.__blush_section_reflow_tweens = env.__blush_section_reflow_tweens or setmetatable({}, { __mode = "k" })

	function page:reflow(
		column,
		animate
	)
		if uis.TouchEnabled
			and self.mobilelayoutactive
			and column == "left"
		then
			for _, section in ipairs(self:sorted("left")) do
				if section.frame and section.frame.Parent then
					section.frame.LayoutOrder = section.order
					section.frame.Position = UDim2.fromOffset(0, 0)
				end
			end

			self.left.CanvasSize = UDim2.fromOffset(0, 0)
			self.left.AutomaticCanvasSize = Enum.AutomaticSize.Y
			self.scrollupdates.left()
			return
		end

		local y = 0

		for _, section in ipairs(
			self:sorted(column)
		) do
			if sectionvisible(section) then
				section.targety = y

				local target =
					UDim2.fromOffset(
						0,
						y
					)

				local previous = env.__blush_section_reflow_tweens[section]
				if previous then
					invoke(function()
						previous:Cancel()
					end)
					env.__blush_section_reflow_tweens[section] = nil
				end

				if animate
					and not section.dragging
					and section.frame.Visible
				then
					local animation = tween(
						section.frame,
						{Position = target},
						sectionti
					)
					env.__blush_section_reflow_tweens[section] = animation
				else
					section.frame.Position = target
				end

				y += (
					section.targetheight
					or section.frame.Size.Y.Offset
				)
					+ 10
			end
		end

		if y > 0 then
			y -= 10
		end

		local scroll =
			self[column]

		local bottompadding = uis.TouchEnabled and 24 or 0

		scroll.CanvasSize =
			UDim2.fromOffset(
				0,
				math.max(
					y + bottompadding,
					scroll.AbsoluteSize.Y
				)
			)

		self.scrollupdates[column]()
	end

	function page:reflowall(animate)
		self:reflow(
			"left",
			animate
		)

		self:reflow(
			"right",
			animate
		)
	end

	left:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		if left.Parent and not uis.TouchEnabled then
			page:reflow("left", false)
		end
	end)

	right:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		if right.Parent and not uis.TouchEnabled then
			page:reflow("right", false)
		end
	end)

	pages[name] = page

	return page
end

function fadepage(page, transparency, callback)
	local previous = page.fadeanimation
	page.fadeanimation = nil

	if previous then
		invoke(function() previous:Cancel() end)
	end

	local animation = tween(
		page.frame,
		{GroupTransparency = transparency},
		TweenInfo.new(.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	)

	page.fadeanimation = animation

	if not animation then
		if callback then
			callback()
		end
		return
	end

	animation.Completed:Connect(function()
		if page.fadeanimation ~= animation then
			return
		end

		page.fadeanimation = nil
		if callback then
			callback()
		end
	end)
end

function showpage(name)
	local page = pages[name]

	if not page or page == currentpage then
		return
	end

	closepopup()

	local previous = currentpage
	currentpage = page

	titleprimary.Text = page.primary

	local hassubtitle = page.secondary ~= nil and page.secondary ~= ""
	arrowholder.Visible = hassubtitle
	titlesecondary.Visible = hassubtitle
	titlesecondary.Text = page.secondary or ""

	if updatetopnavigationstate then
		updatetopnavigationstate()
	end

	if previous then
		fadepage(previous, 1, function()
			if previous ~= currentpage then
				previous.frame.Visible = false
			end
		end)
	end

	local wasvisible = page.frame.Visible
	page.frame.Visible = true
	page.frame.Position = UDim2.fromOffset(0, 0)
	if not wasvisible then
		page.frame.GroupTransparency = 1
	end
	page:reflowall(false)
	fadepage(page, 0)

	search.Text = ""
end

-- checkbox

env.__blush_checkboxstates =
	env.__blush_checkboxstates
	or setmetatable({}, { __mode = "k" })

function refreshcheckboxcolors()
	for box, data in pairs(env.__blush_checkboxstates) do
		if not box.Parent then
			env.__blush_checkboxstates[box] = nil
		else
			local checked = data.checked == true
			local strokecolor = checked and theme.white or theme.border

			if data.stroke and data.stroke.Parent then
				syncbinding(data.stroke, "Color", strokecolor)
				data.stroke.Color = strokecolor
				data.stroke.Transparency = checked and .26 or .4
			end

			if data.fill and data.fill.Parent then
				syncbinding(data.fill, "BackgroundColor3", theme.white)
				data.fill.BackgroundColor3 = theme.white
				data.fill.BackgroundTransparency = checked and 0 or 1
			end

			if data.glow and data.glow.Parent then
				syncbinding(data.glow, "Color", theme.white)
				data.glow.Color = theme.white
				data.glow.Transparency = checked and .64 or 1
			end

			if data.check and data.check.Parent then
				syncbinding(data.check, "ImageColor3", theme.black)
				data.check.ImageColor3 = theme.black
			end
		end
	end
end

function makecheckbox(
	parentobject,
	size,
	default
)
	local checked = default == true
	local indicatortween

	local box = new("Frame", {
		Parent = parentobject,
		Size = UDim2.fromOffset(size, size),
		BackgroundColor3 = theme.input,
		BorderSizePixel = 0,
		ZIndex = 16,
	})
	corner(box, 5)

	local boxstroke = stroke(
		box,
		checked and .26 or .4,
		checked and theme.white or theme.border,
		.7
	)

	local fill = new("Frame", {
		Parent = box,
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = theme.white,
		BackgroundTransparency = checked and 0 or 1,
		BorderSizePixel = 0,
		ZIndex = 17,
	})
	corner(fill, 5)

	local checkedglow = addshadow(
		fill,
		"CheckedGlow",
		checked and .64 or 1,
		7,
		1,
		-1
	)

	local check = new("ImageLabel", {
		Parent = box,
		AnchorPoint = Vector2.new(.5, .5),
		Position = UDim2.new(.5, -.5, .5, .333),
		Size = UDim2.fromOffset(
			math.max(size - 4, 12),
			math.max(size - 4, 12)
		),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Image = icons.check,
		ImageColor3 = theme.black,
		ImageTransparency = checked and .02 or 1,
		ScaleType = Enum.ScaleType.Fit,
		ZIndex = 18,
	})

	local checkboxstate = {
		checked = checked,
		stroke = boxstroke,
		fill = fill,
		glow = checkedglow,
		check = check,
	}

	env.__blush_checkboxstates[box] = checkboxstate

	local function render(value)
		checked = value == true
		checkboxstate.checked = checked

		if indicatortween then
			invoke(function()
				indicatortween:Cancel()
			end)
			indicatortween = nil
		end

		local strokecolor = checked and theme.white or theme.border
		if boxstroke then
			syncbinding(boxstroke, "Color", strokecolor)
			boxstroke.Color = strokecolor
			boxstroke.Transparency = checked and .26 or .4
		end

		fill.BackgroundTransparency = checked and 0 or 1

		if checkedglow then
			checkedglow.Transparency = checked and .64 or 1
		end

		local target = checked and .02 or 1
		if not animationsenabled then
			check.ImageTransparency = target
			return
		end

		indicatortween = tween(
			check,
			{ImageTransparency = target},
			checkti
		)

		local current = indicatortween
		if current then
			current.Completed:Connect(function()
				if indicatortween == current then
					indicatortween = nil
				end
			end)
		end
	end

	return box, render
end

function colorbyte(value)
	return math.clamp(
		math.floor(value * 255 + .5),
		0,
		255
	)
end

function formatrgba(colorvalue, alphavalue)
	return string.format(
		"%d, %d, %d, %d",
		colorbyte(colorvalue.R),
		colorbyte(colorvalue.G),
		colorbyte(colorvalue.B),
		math.clamp(
			math.floor((alphavalue or 1) * 255 + .5),
			0,
			255
		)
	)
end

function formathexalpha(colorvalue, alphavalue)
	return string.format(
		"#%02X%02X%02X%02X",
		colorbyte(colorvalue.R),
		colorbyte(colorvalue.G),
		colorbyte(colorvalue.B),
		math.clamp(
			math.floor((alphavalue or 1) * 255 + .5),
			0,
			255
		)
	)
end

function parsergba(value)
	local r, g, b, a =
		tostring(value or ""):match(
			"^%s*([%+%-]?%d+)%s*,%s*([%+%-]?%d+)%s*,%s*([%+%-]?%d+)%s*,%s*([%+%-]?%d+)%s*$"
		)

	if not r then
		return nil
	end

	r = math.clamp(tonumber(r) or 0, 0, 255)
	g = math.clamp(tonumber(g) or 0, 0, 255)
	b = math.clamp(tonumber(b) or 0, 0, 255)
	a = math.clamp(tonumber(a) or 0, 0, 255)

	return Color3.fromRGB(r, g, b), a / 255
end

function parsehexalpha(value)
	local hex = tostring(value or "")
		:gsub("%s+", "")
		:gsub("^#", "")

	if #hex ~= 8
		or not hex:match("^%x%x%x%x%x%x%x%x$")
	then
		return nil
	end

	local r = tonumber(hex:sub(1, 2), 16)
	local g = tonumber(hex:sub(3, 4), 16)
	local b = tonumber(hex:sub(5, 6), 16)
	local a = tonumber(hex:sub(7, 8), 16)

	if not r or not g or not b or not a then
		return nil
	end

	return Color3.fromRGB(r, g, b), a / 255
end

-- colorpicker state

function createcolorstate(
	color,
	callback,
	swatch
)
	local h, s, v =
		color:ToHSV()

	local state = {
		h = h,
		s = s,
		v = v,

		alpha = 1,

		fadevalue = 1,
		fadedirection = -1,

		fading = false,
		rainbow = false,

		dragging = false,

		callback = callback,
		swatch = swatch,
		swatchglow = nil,

		popup = nil,
	}

	function state:color()
		return Color3.fromHSV(
			self.h,
			self.s,
			self.v
		)
	end

	function state:currentalpha()
		if self.fading then
			return self.fadevalue
		end

		return self.alpha
	end

	function state:syncinputs(force)
		local popup = self.popup

		if not popup
			or not popup.panel
			or not popup.panel.Parent
			or popup.inputupdating
		then
			return
		end

		local colorvalue = self:color()
		local alphavalue = self:currentalpha()
		popup.inputupdating = true

		if force
			or not popup.rgba:IsFocused()
		then
			popup.rgba.Text =
				formatrgba(
					colorvalue,
					alphavalue
				)
		end

		if force
			or not popup.hex:IsFocused()
		then
			popup.hex.Text =
				formathexalpha(
					colorvalue,
					alphavalue
				)
		end

		popup.inputupdating = false
	end

	function state:apply()
		local colorvalue =
			self:color()

		local alphavalue =
			self:currentalpha()

		if self.swatch then
			self.swatch.BackgroundColor3 =
				colorvalue

			self.swatch.BackgroundTransparency =
				math.clamp(1 - alphavalue, 0, 1)

			if self.swatchglow then
				self.swatchglow.Color = colorvalue
				self.swatchglow.Transparency =
					math.clamp(.58 + (1 - alphavalue) * .26, .58, .9)
			end
		end

		if self.callback then
			self.callback(
				colorvalue,
				alphavalue
			)
		end

		if self.hotkeybinding then
			requesthotkeyrefresh(self.hotkeybinding)
		end

		local popup =
			self.popup

		if not popup
			or not popup.panel
			or not popup.panel.Parent
		then
			return
		end

		popup.sv.BackgroundColor3 =
			Color3.fromHSV(
				self.h,
				1,
				1
			)

		popup.svcursor.Position =
			UDim2.fromScale(
				self.s,
				1 - self.v
			)

		popup.huecursor.Position =
			UDim2.fromScale(
				self.h,
				.5
			)

		popup.alphafield.BackgroundColor3 =
			colorvalue

		popup.alphacursor.Position =
			UDim2.fromScale(
				alphavalue,
				.5
			)

		if popup.svglow then
			popup.svglow.Color = colorvalue
		end

		if popup.hueglow then
			popup.hueglow.Color = Color3.fromHSV(self.h, 1, 1)
		end

		if popup.alphaglow then
			popup.alphaglow.Color = colorvalue
		end

		self:syncinputs(false)
	end

	function state:refresh()
		if self.fading
			or self.rainbow
		then
			animatedpickers[self] =
				true
			ensurepickeranimationloop()
		else
			animatedpickers[self] =
				nil

			self.fadevalue =
				self.alpha
		end

		self:apply()
	end

	function state:Set(colorvalue, alphavalue, fire)
		self.h, self.s, self.v = colorvalue:ToHSV()

		if alphavalue ~= nil then
			local previousalpha = self.alpha
			self.alpha = math.clamp(alphavalue, 0, 1)

			if self.fading then
				if previousalpha > 0 then
					self.fadevalue = math.clamp(
						self.fadevalue * self.alpha / previousalpha,
						0,
						self.alpha
					)
				else
					self.fadevalue = self.alpha
				end
			else
				self.fadevalue = self.alpha
				self.fadedirection = -1
			end
		end

		if fire == false then
			local callback = self.callback
			self.callback = nil
			self:apply()
			self.callback = callback
		else
			self:apply()

			if self.onpersist then
				self.onpersist()
			end
		end
	end

	function state:update(dt)
		if self.dragging then
			return
		end

		if not self.swatch
			or not self.swatch.Parent
		then
			animatedpickers[self] = nil
			return
		end

		local active = false

		if self.rainbow then
			self.h = (self.h + dt * .27) % 1
			active = true
		end

		if self.fading then
			local limit = math.clamp(self.alpha, 0, 1)

			if limit <= 0 then
				self.fadevalue = 0
			else
				local normalized = math.clamp(self.fadevalue / limit, 0, 1)
				local eased = .18 + .82 * math.sin(normalized * math.pi)
				local step = dt * .34 * eased
				local nextvalue = self.fadevalue + step * self.fadedirection

				if self.fadedirection < 0 and nextvalue <= 0 then
					self.fadevalue = 0
					self.fadedirection = 1
				elseif self.fadedirection > 0 and nextvalue >= limit then
					self.fadevalue = limit
					self.fadedirection = -1
				else
					self.fadevalue = math.clamp(nextvalue, 0, limit)
				end
			end

			active = true
		end

		if not active then
			animatedpickers[self] =
				nil

			return
		end

		self:apply()
	end

	if swatch then
		swatch.Destroying:Connect(function()
			animatedpickers[state] = nil
			state.fading = false
			state.rainbow = false
			state.dragging = false

			if pickerdrag
				and pickerdrag.state == state
			then
				local input = pickerdrag.input
				pickerdrag = nil
				releaseinteraction(input)
			end

			if state.popup
				and activepopup == state.popup
			then
				closepopup()
			end

			state.popup = nil
			state.swatch = nil
			state.swatchglow = nil
			state.callback = nil
			state.onpersist = nil

			if next(animatedpickers) == nil then
				stoppickeranimationloop()
			end
		end)
	end

	return state
end

function opencolorpicker(
	anchor,
	state
)
	local anchorpos =
		overlayposition(anchor)

	local anchorsize =
		anchor.AbsoluteSize

	local width = 244
	local height = 266

	local x =
		anchorpos.X
		+ anchorsize.X
		- width

	local y =
		anchorpos.Y
		+ anchorsize.Y
		+ 6

	x = math.clamp(
		x,
		8,
		math.max(
			8,
			popuplayer.AbsoluteSize.X
				- width
				- 8
		)
	)

	y = math.clamp(
		y,
		8,
		math.max(
			8,
			popuplayer.AbsoluteSize.Y
				- height
				- 8
		)
	)

	local panel, popup =
		createpopup(
			Vector2.new(
				x,
				y
			),
			width,
			height,
			520,
			"color"
		)

	local svholder = new("Frame", {
		Parent = panel,

		Position =
			UDim2.fromOffset(
				10,
				10
			),

		Size =
			UDim2.new(
				1,
				-20,
				0,
				126
			),

		BackgroundTransparency = 1,
		BorderSizePixel = 0,

		ClipsDescendants = false,

		ZIndex = 524,
	})

	local sv = rawnew("CanvasGroup", {
		Parent = svholder,

		Size =
			UDim2.fromScale(
				1,
				1
			),

		BackgroundColor3 =
			Color3.fromHSV(
				state.h,
				1,
				1
			),

		GroupTransparency = 0,
		BorderSizePixel = 0,

		ClipsDescendants = true,

		ZIndex = 524,
	})

	corner(sv, 7)

	local white = rawnew("Frame", {
		Parent = sv,

		Size =
			UDim2.fromScale(
				1,
				1
			),

		BackgroundColor3 =
			Color3.new(
				1,
				1,
				1
			),

		BorderSizePixel = 0,

		ZIndex = 525,
	})

	local black = rawnew("Frame", {
		Parent = sv,

		Size =
			UDim2.fromScale(
				1,
				1
			),

		BackgroundColor3 =
			Color3.new(
				0,
				0,
				0
			),

		BorderSizePixel = 0,

		ZIndex = 526,
	})

	new("UIGradient", {
		Parent = white,

		Transparency =
			NumberSequence.new({
				NumberSequenceKeypoint.new(
					0,
					0
				),

				NumberSequenceKeypoint.new(
					1,
					1
				),
			}),
	})

	new("UIGradient", {
		Parent = black,

		Rotation = 90,

		Transparency =
			NumberSequence.new({
				NumberSequenceKeypoint.new(
					0,
					1
				),

				NumberSequenceKeypoint.new(
					1,
					0
				),
			}),
	})

	local svcursor = rawnew("Frame", {
		Parent = svholder,

		AnchorPoint =
			Vector2.new(
				.5,
				.5
			),

		Position =
			UDim2.fromScale(
				state.s,
				1 - state.v
			),

		Size =
			UDim2.fromOffset(
				10,
				10
			),

		BackgroundColor3 =
			Color3.fromRGB(248, 248, 250),

		BorderSizePixel = 0,

		ZIndex = 530,
	})

	corner(svcursor, 999)
	rawnew("UIStroke", {
		Parent = svcursor,
		Color = Color3.fromRGB(14, 14, 15),
		Transparency = .2,
		Thickness = 1,
	})
	local svglow =
		addshadow(
			svcursor,
			"PickerGlow",
			.68,
			6,
			1,
			-1,
			Color3.fromRGB(248, 248, 250),
			UDim2.fromOffset(0, 0),
			false
		)

	local svhit = new("TextButton", {
		Parent = svholder,

		Size =
			UDim2.fromScale(
				1,
				1
			),

		BackgroundTransparency = 1,
		BorderSizePixel = 0,

		Text = "",
		AutoButtonColor = false,

		ZIndex = 531,
	})

	local function colorslider(
		yposition,
		colorsequence,
		transparencysequence,
		value,
		backgroundcolor
	)
		local holder = new("Frame", {
			Parent = panel,

			Position =
				UDim2.fromOffset(
					10,
					yposition
				),

			Size =
				UDim2.new(
					1,
					-20,
					0,
					14
				),

			BackgroundTransparency = 1,
			BorderSizePixel = 0,

			ZIndex = 524,
		})

		local field = rawnew("Frame", {
			Parent = holder,

			Size =
				UDim2.fromScale(
					1,
					1
				),

			BackgroundColor3 =
				backgroundcolor
				or Color3.fromRGB(248, 248, 250),

			BorderSizePixel = 0,

			ClipsDescendants = true,

			ZIndex = 524,
		})

		corner(field, 4)

		local gradient =
			new("UIGradient", {
				Parent = field,

				Transparency =
					transparencysequence
					or NumberSequence.new(
						0
					),
			})

		if colorsequence then
			gradient.Color =
				colorsequence
		end

		local cursor = rawnew("Frame", {
			Parent = holder,

			AnchorPoint =
				Vector2.new(
					.5,
					.5
				),

			Position =
				UDim2.fromScale(
					value,
					.5
				),

			Size =
				UDim2.fromOffset(
					4,
					18
				),

			BackgroundColor3 =
				Color3.fromRGB(248, 248, 250),

			BorderSizePixel = 0,

			ZIndex = 530,
		})

		corner(cursor, 2)
		local cursorglow =
			addshadow(
				cursor,
				"PickerGlow",
				.72,
				5,
				1,
				-1,
				Color3.fromRGB(248, 248, 250),
				UDim2.fromOffset(0, 0),
				false
			)

		local hit = new("TextButton", {
			Parent = holder,

			Size =
				UDim2.fromScale(
					1,
					1
				),

			BackgroundTransparency = 1,
			BorderSizePixel = 0,

			Text = "",
			AutoButtonColor = false,

			ZIndex = 531,
		})

		return holder,
			field,
			cursor,
			hit,
			cursorglow
	end

	local rainbowsequence =
		ColorSequence.new({
			ColorSequenceKeypoint.new(
				0,
				Color3.fromHSV(
					0,
					1,
					1
				)
			),

			ColorSequenceKeypoint.new(
				1 / 6,
				Color3.fromHSV(
					1 / 6,
					1,
					1
				)
			),

			ColorSequenceKeypoint.new(
				2 / 6,
				Color3.fromHSV(
					2 / 6,
					1,
					1
				)
			),

			ColorSequenceKeypoint.new(
				3 / 6,
				Color3.fromHSV(
					3 / 6,
					1,
					1
				)
			),

			ColorSequenceKeypoint.new(
				4 / 6,
				Color3.fromHSV(
					4 / 6,
					1,
					1
				)
			),

			ColorSequenceKeypoint.new(
				5 / 6,
				Color3.fromHSV(
					5 / 6,
					1,
					1
				)
			),

			ColorSequenceKeypoint.new(
				1,
				Color3.fromHSV(
					1,
					1,
					1
				)
			),
		})

	local hueholder,
		_,
		huecursor,
		huehit,
		hueglow =
		colorslider(
			147,
			rainbowsequence,
			nil,
			state.h
		)

	local alphaholder,
		alphafield,
		alphacursor,
		alphahit,
		alphaglow =
		colorslider(
			176,
			nil,
			NumberSequence.new({
				NumberSequenceKeypoint.new(
					0,
					1
				),

				NumberSequenceKeypoint.new(
					1,
					0
				),
			}),
			state:currentalpha(),
			state:color()
		)

	local inputrow = new("Frame", {
		Parent = panel,
		Position = UDim2.fromOffset(10, 198),
		Size = UDim2.new(1, -20, 0, 27),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 524,
	})

	local function colorinput(position, size, placeholder)
		local box = new("TextBox", {
			Parent = inputrow,
			Position = position,
			Size = size,
			BackgroundColor3 = theme.input,
			BackgroundTransparency = .04,
			BorderSizePixel = 0,
			Text = "",
			PlaceholderText = placeholder,
			PlaceholderColor3 = theme.text3,
			TextColor3 = theme.text2,
			Font = font,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
			ClearTextOnFocus = false,
			MultiLine = false,
			ZIndex = 525,
		})

		corner(box, 6)
		stroke(box, .72, theme.border, .55)

		new("UIPadding", {
			Parent = box,
			PaddingLeft = UDim.new(0, 8),
			PaddingRight = UDim.new(0, 8),
		})

		return box
	end

	local rgba =
		colorinput(
			UDim2.fromOffset(0, 0),
			UDim2.new(.5, -3, 1, 0),
			"RGBA"
		)

	local hex =
		colorinput(
			UDim2.new(.5, 3, 0, 0),
			UDim2.new(.5, -3, 1, 0),
			"HEX"
		)

	local options = new("Frame", {
		Parent = panel,

		Position =
			UDim2.fromOffset(
				10,
				231
			),

		Size =
			UDim2.new(
				1,
				-20,
				0,
				27
			),

		BackgroundTransparency = 1,

		ZIndex = 524,
	})

	local function optiontoggle(
		name,
		position,
		getter,
		setter
	)
		local button = new("TextButton", {
			Parent = options,

			Position = position,

			Size =
				UDim2.new(
					.5,
					-6,
					1,
					0
				),

			BackgroundTransparency = 1,
			BorderSizePixel = 0,

			Text = "",
			AutoButtonColor = false,

			ZIndex = 525,
		})

		local box, render =
			makecheckbox(
				button,
				17,
				getter()
			)

		box.AnchorPoint =
			Vector2.new(
				0,
				.5
			)

		box.Position = UDim2.new(0, 0, .5, 0)

		local textobject =
			label(
				button,
				name,
				UDim2.new(
					1,
					-30,
					1,
					0
				),
				font,
				theme.text2
			)

		textobject.Position =
			UDim2.fromOffset(
				30,
				0
			)

		textobject.TextSize = 15
		textobject.ZIndex = 526

		button.Activated:Connect(function()
			local value =
				not getter()

			setter(value)
			render(value)

			state:refresh()

			if state.onpersist then
				state.onpersist()
			end
		end)
	end

	optiontoggle(
		"Fading",
		UDim2.fromOffset(
			0,
			0
		),

		function()
			return state.fading
		end,

		function(value)
			state.fading = value
			state.fadevalue = state.alpha
			state.fadedirection = -1
		end
	)

	optiontoggle(
		"Rainbow",
		UDim2.new(
			.5,
			6,
			0,
			0
		),

		function()
			return state.rainbow
		end,

		function(value)
			state.rainbow =
				value
		end
	)

	state.popup = {
		panel = panel,
		rgba = rgba,
		hex = hex,
		inputupdating = false,

		sv = sv,
		svcursor = svcursor,
		svglow = svglow,

		huecursor = huecursor,
		hueglow = hueglow,

		alphafield = alphafield,
		alphacursor = alphacursor,
		alphaglow = alphaglow,
	}

	state:syncinputs(true)

	local function commitcolorinput(box, parser, normalize)
		if state.popup == nil
			or state.popup.inputupdating
		then
			return false
		end

		local colorvalue, alphavalue =
			parser(box.Text)

		if not colorvalue then
			if normalize then
				state:syncinputs(true)
			end
			return false
		end

		state:Set(
			colorvalue,
			alphavalue,
			true
		)

		if normalize then
			state:syncinputs(true)
		end

		return true
	end

	rgba:GetPropertyChangedSignal("Text"):Connect(function()
		if rgba:IsFocused()
			and state.popup
			and not state.popup.inputupdating
		then
			commitcolorinput(
				rgba,
				parsergba,
				false
			)
		end
	end)

	hex:GetPropertyChangedSignal("Text"):Connect(function()
		if hex:IsFocused()
			and state.popup
			and not state.popup.inputupdating
		then
			commitcolorinput(
				hex,
				parsehexalpha,
				false
			)
		end
	end)

	rgba.FocusLost:Connect(function()
		commitcolorinput(
			rgba,
			parsergba,
			true
		)
	end)

	hex.FocusLost:Connect(function()
		commitcolorinput(
			hex,
			parsehexalpha,
			true
		)
	end)

	local function updatepicker(
		drag,
		position
	)
		local localposition =
			position
			- drag.holder.AbsolutePosition

		if drag.type == "sv" then
			state.s =
				math.clamp(
					localposition.X
						/ drag.holder.AbsoluteSize.X,
					0,
					1
				)

			state.v =
				1
				- math.clamp(
					localposition.Y
						/ drag.holder.AbsoluteSize.Y,
					0,
					1
				)

		elseif drag.type == "hue" then
			state.h =
				math.clamp(
					localposition.X
						/ drag.holder.AbsoluteSize.X,
					0,
					1
				)

		elseif drag.type == "alpha" then
			local value =
				math.clamp(
					localposition.X
						/ drag.holder.AbsoluteSize.X,
					0,
					1
				)

			state.alpha = value
			state.fadevalue = value
		end

		state:apply()
	end

	local function beginpicker(
		input,
		typename,
		holder,
		cursor
	)
		if not acquireinteraction(
			"colorpicker",
			input
		) then
			return
		end

		state.dragging = true
		state:refresh()

		pickerdrag = {
			input = input,

			type = typename,

			holder = holder,
			cursor = cursor,

			state = state,

			update = updatepicker,
		}

		updatepicker(
			pickerdrag,
			point(input)
		)
	end

	svhit.InputBegan:Connect(function(input)
		if input.UserInputType
				~= Enum.UserInputType.MouseButton1
			and input.UserInputType
				~= Enum.UserInputType.Touch
		then
			return
		end

		beginpicker(
			input,
			"sv",
			svholder,
			svcursor
		)
	end)

	huehit.InputBegan:Connect(function(input)
		if input.UserInputType
				~= Enum.UserInputType.MouseButton1
			and input.UserInputType
				~= Enum.UserInputType.Touch
		then
			return
		end

		beginpicker(
			input,
			"hue",
			hueholder,
			huecursor
		)
	end)

	alphahit.InputBegan:Connect(function(input)
		if input.UserInputType
				~= Enum.UserInputType.MouseButton1
			and input.UserInputType
				~= Enum.UserInputType.Touch
		then
			return
		end

		beginpicker(
			input,
			"alpha",
			alphaholder,
			alphacursor
		)
	end)

	popup.onclose = function()
		local draginput =
			pickerdrag
			and pickerdrag.state == state
			and pickerdrag.input
			or nil

		state.dragging = false
		state.popup = nil

		if pickerdrag
			and pickerdrag.state == state
		then
			pickerdrag = nil
		end

		if draginput then
			releaseinteraction(
				draginput
			)
		end
	end

	state:refresh()
end

-- section movement

function sectiontargetindex(
	page,
	column,
	excluded,
	y
)
	local items =
		page:sorted(
			column,
			excluded
		)

	local visible = {}

	for _, section in ipairs(items) do
		if section.frame.Visible then
			table.insert(
				visible,
				section
			)
		end
	end

	local scroll =
		page[column]

	local index =
		#visible + 1

	for i, section in ipairs(
		visible
	) do
		local center =
			scroll.AbsolutePosition.Y
			+ (
				section.targety
				or section.frame.Position.Y.Offset
			)
			- scroll.CanvasPosition.Y
			+ (
				section.targetheight
				or section.frame.Size.Y.Offset
			) / 2

		if y < center then
			index = i
			break
		end
	end

	return index, visible
end

function movesection(
	section,
	column,
	index
)
	local page =
		section.page

	local oldcolumn =
		section.column

	local targetitems =
		page:sorted(
			column,
			section
		)

	local visible = {}

	for _, object in ipairs(
		targetitems
	) do
		if object.frame.Visible then
			table.insert(
				visible,
				object
			)
		end
	end

	index =
		math.clamp(
			index,
			1,
			#visible + 1
		)

	section.column =
		column

	if section.frame.Parent
		~= page[column]
	then
		section.frame.Parent =
			page[column]
	end

	local orderlist = {}

	for _, object in ipairs(
		page:sorted(
			column,
			section
		)
	) do
		if object.frame.Visible then
			table.insert(
				orderlist,
				object
			)
		end
	end

	table.insert(
		orderlist,
		index,
		section
	)

	for i, object in ipairs(
		orderlist
	) do
		object.order = i
	end

	page:normalize(column)

	if oldcolumn ~= column then
		page:normalize(oldcolumn)

		page:reflow(
			oldcolumn,
			true
		)
	end

	page:reflow(
		column,
		true
	)
end


function transfersectionpage(section, targetpage)
	local oldpage = section.page

	if not targetpage or oldpage == targetpage then
		return
	end

	for index = #oldpage.sections, 1, -1 do
		if oldpage.sections[index] == section then
			table.remove(oldpage.sections, index)
			break
		end
	end

	oldpage:normalize(section.column)
	oldpage:reflow(section.column, true)

	section.page = targetpage
	targetpage.order += 1
	section.order = targetpage.order
	table.insert(targetpage.sections, section)
end

function beginsectiondrag(drag)
	if draglayer and draglayer.Parent then
		draglayer.GroupTransparency = 0
	end

	local section =
		drag.section

	drag.wascollapsed =
		section.collapsed

	drag.wasfloating =
		section.floating == true

	drag.reopen =
		not section.collapsed

	local absolute =
		section.frame.AbsolutePosition
		- draglayer.AbsolutePosition

	local originalsize =
		section.frame.AbsoluteSize

	drag.width = originalsize.X
	drag.expandedheight = math.max(
		43,
		section.targetheight or originalsize.Y,
		originalsize.Y
	)

	drag.grab =
		drag.current
		- section.frame.AbsolutePosition

	local ghost = new("Frame", {
		Parent = draglayer,

		Position =
			UDim2.fromOffset(
				absolute.X,
				absolute.Y
			),

		Size =
			UDim2.fromOffset(
				originalsize.X,
				originalsize.Y
			),

		BackgroundTransparency = 1,
		BorderSizePixel = 0,

		ClipsDescendants = false,

		ZIndex = 410,
	})

	corner(ghost, 10)

	local clone =
		section.frame:Clone()

	clone.Parent =
		ghost

	clone.Position =
		UDim2.fromOffset(
			0,
			0
		)

	clone.Size =
		UDim2.fromOffset(
			originalsize.X,
			originalsize.Y
		)

	for _, object in ipairs(
		clone:GetDescendants()
	) do
		if object:IsA("GuiObject") then
			object.ZIndex += 400
		end
	end

	clone.ZIndex += 400

	section.dragging = true
	section.frame.Visible = false

	drag.started = true
	drag.ghost = ghost
	drag.clone = clone
	drag.cloneanimations = {}

	drag.previewcolumn =
		section.column

	drag.previewindex =
		-1

	if drag.reopen then
		section:SetCollapsed(
			true,
			false,
			true
		)

		local clonedcollapse =
			clone:FindFirstChild(
				"SectionCollapse"
			)

		local cloneddivider =
			clone:FindFirstChild(
				"SectionDivider"
			)

		local clonedclip =
			clone:FindFirstChild(
				"SectionClip"
			)

		if clonedcollapse then
			drag.cloneanimations[#drag.cloneanimations + 1] = tween(
				clonedcollapse,
				{
					Rotation = -90,
				},
				tabti
			)
		end

		if cloneddivider then
			drag.cloneanimations[#drag.cloneanimations + 1] = tween(
				cloneddivider,
				{
					BackgroundTransparency = 1,
				},
				tabti
			)
		end

		if clonedclip then
			clonedclip.ClipsDescendants = true
			drag.cloneanimations[#drag.cloneanimations + 1] = tween(
				clonedclip,
				{
					Size =
						UDim2.new(
							1,
							0,
							0,
							0
						),
				},
				tabti
			)
		end

		drag.cloneanimations[#drag.cloneanimations + 1] = tween(
			clone,
			{
				Size =
					UDim2.fromOffset(
						originalsize.X,
						43
					),
			},
			tabti
		)

		drag.ghostsizeanimation = tween(
			ghost,
			{Size = UDim2.fromOffset(originalsize.X, 43)},
			sectionti
		)
	end

	section.page:reflow(
		section.column,
		true
	)
end

function updatesectiondrag(drag)
	local section = drag.section

	local position =
		drag.current
		- drag.grab
		- draglayer.AbsolutePosition

	drag.ghost.Position =
		UDim2.fromOffset(
			position.X,
			position.Y
		)

	local canattach =
		currentpage ~= nil
		and inside(
			window,
			drag.current
		)

	drag.outside = not canattach

	if drag.outside then
		if not section.floating then
			section.floating = true

			if section.frame.Parent ~= draglayer then
				section.frame.Parent = draglayer
			end

			section.page:reflow(
				section.column,
				true
			)
		end

		return
	end

	if currentpage ~= section.page then
		transfersectionpage(section, currentpage)
	end

	local page = section.page

	if section.floating then
		section.floating = false
		section.floatingwidth = nil

		if section.shadow then
			section.shadow.Enabled = false
		end
	end

	local centerx = drag.current.X
	local centery = drag.current.Y

	local split =
		(
			page.left.AbsolutePosition.X
			+ page.left.AbsoluteSize.X
			+ page.right.AbsolutePosition.X
		)
		/ 2

	local column =
		centerx < split
		and "left"
		or "right"

	local index =
		sectiontargetindex(
			page,
			column,
			section,
			centery
		)

	if column ~= drag.previewcolumn
		or index ~= drag.previewindex
		or section.frame.Parent ~= page[column]
	then
		drag.previewcolumn = column
		drag.previewindex = index

		movesection(
			section,
			column,
			index
		)
	end
end

function attachsectiontransition(drag)
	local section = drag.section
	local ghost = drag.ghost

	if drag.ghostsizeanimation then
		invoke(function()
			drag.ghostsizeanimation:Cancel()
		end)
		drag.ghostsizeanimation = nil
	end

	for _, animation in ipairs(drag.cloneanimations or {}) do
		if animation then
			invoke(function()
				animation:Cancel()
			end)
		end
	end
	drag.cloneanimations = nil

	section.floating = false
	section.floatingwidth = nil
	section.dragging = true
	section.frame.Visible = false

	if section.shadow then
		section.shadow.Enabled = false
	end

	local targetparent = section.page[section.column]
	if section.frame.Parent ~= targetparent then
		section.frame.Parent = targetparent
	end

	section:SetCollapsed(drag.wascollapsed, false, false)
	if section.RefreshLayout then
		section:RefreshLayout(false, false)
	end

	local preservedheight = drag.wascollapsed
		and 43
		or math.max(
			43,
			section.targetheight or 43,
			drag.expandedheight or 43
		)

	section.targetheight = preservedheight
	section.frame.Size = UDim2.new(1, -7, 0, preservedheight)
	section.clip.Size = UDim2.new(
		1,
		0,
		0,
		drag.wascollapsed and 0 or math.max(0, preservedheight - 43)
	)
	section.clip.ClipsDescendants = true
	section.page:reflow(section.column, false)
	applyuitransparency(uitransparency * 100)

	local target = section.frame.AbsolutePosition - draglayer.AbsolutePosition
	local targetheight = preservedheight
	local targetsize = UDim2.fromOffset(section.frame.AbsoluteSize.X, targetheight)
	local clone = drag.clone

	if clone and clone.Parent then
		local clonedcollapse = clone:FindFirstChild("SectionCollapse")
		local cloneddivider = clone:FindFirstChild("SectionDivider")
		local clonedclip = clone:FindFirstChild("SectionClip")
		local visibleheight = drag.wascollapsed and 0 or math.max(0, targetheight - 43)

		tween(clone, {Size = targetsize}, sectionti)
		if clonedclip then
			clonedclip.ClipsDescendants = true
			tween(clonedclip, {Size = UDim2.new(1, 0, 0, visibleheight)}, sectionti)
		end
		if clonedcollapse then
			tween(clonedcollapse, {Rotation = drag.wascollapsed and -90 or 0}, sectionti)
		end
		if cloneddivider then
			tween(cloneddivider, {BackgroundTransparency = drag.wascollapsed and 1 or .52}, sectionti)
		end
	end

	local finished = false
	local function finish()
		if finished then
			return
		end

		finished = true
		section.dragging = false
		section.frame.Visible = true

		if section.RefreshLayout then
			section:RefreshLayout(false, false)
		end

		section.clip.ClipsDescendants = section.collapsed
		section.page:reflow(section.column, false)
		applyuitransparency(uitransparency * 100)

		if ghost and ghost.Parent then
			ghost:Destroy()
		end

		if drag.wasfloating then
			notify("Section attached", section.name, 2.25)
		end
	end

	if not ghost or not ghost.Parent then
		finish()
		return
	end

	local animation = tween(
		ghost,
		{
			Position = UDim2.fromOffset(target.X, target.Y),
			Size = targetsize,
		},
		sectionti
	)

	if animation then
		animation.Completed:Connect(finish)
	else
		finish()
	end
end

function finishsectiondrag()
	if draglayer and draglayer.Parent then
		draglayer.GroupTransparency = 0
	end

	local drag =
		sectiondrag

	sectiondrag = nil

	if drag then
		releaseinteraction(
			drag.input
		)
	end

	if not drag
		or not drag.started
	then
		return
	end

	local section =
		drag.section

	section.lastdragend = os.clock()
	section.headerdragged = false

	if drag.outside then
		local floatingposition =
			drag.ghost.AbsolutePosition
			- draglayer.AbsolutePosition

		local viewport =
			draglayer.AbsoluteSize

		local detachedheight =
			math.max(
				43,
				drag.ghost.AbsoluteSize.Y
			)

		floatingposition = Vector2.new(
			math.clamp(
				floatingposition.X,
				6,
				math.max(
					6,
					viewport.X - drag.width - 6
				)
			),
			math.clamp(
				floatingposition.Y,
				6,
				math.max(
					6,
					viewport.Y - detachedheight - 6
				)
			)
		)

		section.floating = true
		section.floatingwidth =
			drag.width

		section.frame.Parent =
			draglayer

		section.frame.Position =
			UDim2.fromOffset(
				floatingposition.X,
				floatingposition.Y
			)

		section.frame.Size =
			UDim2.fromOffset(
				drag.width,
				43
			)

		section.dragging = false
		section.frame.Visible = true

		if section.shadow then
			section.shadow.Enabled = true
		end

		applyuitransparency(
			uitransparency * 100
		)

		if drag.ghost
			and drag.ghost.Parent
		then
			drag.ghost:Destroy()
		end

		section.page:reflow(
			section.column,
			true
		)

		section:SetCollapsed(
			drag.wascollapsed,
			true,
			false
		)

		notify(
			"Section detached",
			section.name,
			2.25
		)

		return
	end

	attachsectiontransition(drag)

end

-- section

function createsection(
	page,
	column,
	titletext,
	sectionicon
)
	page.order += 1

	local frame = new("Frame", {
		Parent = page[column],

		Position =
			UDim2.fromOffset(
				0,
				0
			),

		Size =
			UDim2.new(
				1,
				-7,
				0,
				43
			),

		BackgroundColor3 =
			theme.section,

		BackgroundTransparency =
			.1,

		BorderSizePixel = 0,

		ZIndex = 13,
	})

	corner(frame, 10)
	backgroundsectionframes[frame] = .10
	if updatebackgroundsurfaces then
		updatebackgroundsurfaces()
	end

	local floatingshadow =
		adddepthshadow(
			frame,
			"floating"
		)

	if floatingshadow then
		floatingshadow.Enabled = false
	end

	local headerobject = new("Frame", {
		Parent = frame,

		Size =
			UDim2.new(
				1,
				0,
				0,
				42
			),

		BackgroundTransparency = 1,

		ZIndex = 14,
	})

	local titleoffset = 14

	if sectionicon then
		local sectionimage =
			image(
				headerobject,
				sectionicon,
				18,
				theme.text2,
				15
			)

		sectionimage.AnchorPoint =
			Vector2.new(
				0,
				.5
			)

		sectionimage.Position =
			UDim2.fromOffset(
				14,
				21
			)

		titleoffset = 41
	end

	local titleobject =
		label(
			headerobject,
			titletext,
			UDim2.new(
				1,
				-titleoffset - 42,
				1,
				0
			),
			bold
		)

	titleobject.Position =
		UDim2.fromOffset(
			titleoffset,
			0
		)

	titleobject.TextSize = 17
	titleobject.ZIndex = 15

	local draghandle = new("TextButton", {
		Parent = headerobject,

		Size =
			UDim2.new(
				1,
				0,
				1,
				0
			),

		BackgroundTransparency = 1,
		BorderSizePixel = 0,

		Text = "",
		AutoButtonColor = false,

		ZIndex = 18,
	})

	local collapse = new("ImageLabel", {
		Name = "SectionCollapse",
		Parent = headerobject,

		AnchorPoint =
			Vector2.new(
				1,
				.5
			),

		Position =
			UDim2.new(
				1,
				-13,
				.5,
				0
			),

		Size =
			UDim2.fromOffset(
				16,
				16
			),

		BackgroundTransparency = 1,
		BorderSizePixel = 0,

		Image = icons.down,
		ImageColor3 = theme.text3,

		ZIndex = 17,
	})

	local divider = new("Frame", {
		Name = "SectionDivider",
		Parent = frame,

		Position =
			UDim2.fromOffset(
				12,
				42
			),

		Size =
			UDim2.new(
				1,
				-24,
				0,
				1
			),

		BackgroundColor3 =
			theme.border,

		BackgroundTransparency =
			.52,

		BorderSizePixel = 0,

		ZIndex = 14,
	})

	local clip = new("Frame", {
		Name = "SectionClip",
		Parent = frame,

		Position =
			UDim2.fromOffset(
				0,
				43
			),

		Size =
			UDim2.new(
				1,
				0,
				0,
				0
			),

		BackgroundTransparency = 1,
		BorderSizePixel = 0,

		ClipsDescendants = true,

		ZIndex = 14,
	})

	local body = new("Frame", {
		Parent = clip,

		Size =
			UDim2.new(
				1,
				0,
				0,
				0
			),

		BackgroundTransparency = 1,
		BorderSizePixel = 0,

		ZIndex = 14,
	})

	padding(
		body,
		14,
		14,
		10,
		11
	)

	local bodylayout =
		list(
			body,
			9
		)

	local section = {
		page = page,
		column = column,

		order = page.order,

		frame = frame,
		body = body,
		clip = clip,
		shadow = floatingshadow,
		TextObject = titleobject,

		name = titletext,

		controls = {},
		transitions = {},

		collapsed = false,
		dragging = false,
		floating = false,
		floatingwidth = nil,

		targetheight = 43,
		targety = 0,

		ready = false,
		headerdragged = false,
		lastdragend = 0,
	}

	local function sectiontransition(key, object, properties, animate)
		local previous = section.transitions[key]
		section.transitions[key] = nil

		if previous then
			invoke(function() previous:Cancel() end)
		end

		if not animate or not animationsenabled then
			for property, value in pairs(properties) do
				object[property] = value
			end
			return nil
		end

		local animation = tween(object, properties, tabti)
		section.transitions[key] = animation

		if animation then
			animation.Completed:Connect(function()
				if section.transitions[key] == animation then
					section.transitions[key] = nil
				end
			end)
		end

		return animation
	end

	table.insert(
		page.sections,
		section
	)

	local function resize(
		animate,
		layoutanimate
	)
		if uis.TouchEnabled then
			local bodyheight = math.max(
				0,
				bodylayout.AbsoluteContentSize.Y + 30
			)

			body.Size = UDim2.new(
				1,
				0,
				0,
				bodyheight
			)

			local visibleheight = section.collapsed
				and 0
				or bodyheight

			section.targetheight = 43 + visibleheight

			frame.Size = UDim2.new(
				1,
				-6,
				0,
				section.targetheight
			)

			clip.Size = UDim2.new(
				1,
				0,
				0,
				visibleheight
			)

			frame.ClipsDescendants = false
			clip.ClipsDescendants = section.collapsed

			if page.mobilelayoutactive then
				frame.LayoutOrder = section.order
			else
				page:reflow(section.column, false)
			end

			return
		end

		local bodyheight =
			bodylayout.AbsoluteContentSize.Y
			+ 21

		body.Size =
			UDim2.new(
				1,
				0,
				0,
				bodyheight
			)

		local visibleheight =
			section.collapsed
			and 0
			or bodyheight

		section.targetheight =
			43
			+ visibleheight

		local framesize

		if section.floating then
			framesize =
				UDim2.fromOffset(
					section.floatingwidth
						or math.max(
							1,
							frame.AbsoluteSize.X
						),
					section.targetheight
				)
		else
			framesize =
				UDim2.new(
					1,
					-7,
					0,
					section.targetheight
				)
		end

		local clipsize =
			UDim2.new(
				1,
				0,
				0,
				visibleheight
			)

		sectiontransition("frame", frame, {Size = framesize}, animate)

		local clipanimation
		if animate and animationsenabled then
			clip.ClipsDescendants = true
			clipanimation = sectiontransition("clip", clip, {Size = clipsize}, true)
		else
			clip.ClipsDescendants = section.collapsed
			sectiontransition("clip", clip, {Size = clipsize}, false)
		end

		if clipanimation and not section.collapsed then
			clipanimation.Completed:Connect(function()
				if not section.collapsed and clip.Parent then
					clip.ClipsDescendants = false
				end
			end)
		end

		page:reflow(
			section.column,
			layoutanimate == true
		)
	end

	function section:RefreshLayout(animate, layoutanimate)
		resize(animate == true, layoutanimate == true)
	end

	function section:SetCollapsed(
		value,
		animate,
		layoutanimate
	)
		self.collapsed =
			value == true

		if uis.TouchEnabled then
			animate = false
			layoutanimate = false
		end

		-- The body clip handles the collapse. Keep the outer section unclipped so
		-- shadows/glows do not change appearance during the animation.
		frame.ClipsDescendants = false

		sectiontransition(
			"collapse",
			collapse,
			{Rotation = self.collapsed and -90 or 0},
			animate
		)

		sectiontransition(
			"divider",
			divider,
			{BackgroundTransparency = self.collapsed and 1 or .52},
			animate
		)

		resize(
			animate,
			layoutanimate
		)

	end

	function section:RefreshMobileLayout()
		if not uis.TouchEnabled then
			return
		end

		resize(false, false)
	end

	bodylayout:GetPropertyChangedSignal(
		"AbsoluteContentSize"
	):Connect(function()
		resize(
			section.ready and not uis.TouchEnabled,
			section.ready and not uis.TouchEnabled
		)

		if uis.TouchEnabled then
			section:RefreshMobileLayout()
		end
	end)

	section.ready = true
	resize(false, false)

	if uis.TouchEnabled then
		section:RefreshMobileLayout()
	else
		page:reflow(column, false)
	end

	draghandle.Activated:Connect(function()
		if (sectiondrag
			and sectiondrag.section == section
			and sectiondrag.started)
			or os.clock() - (section.lastdragend or 0) < .12
		then
			return
		end

		section:SetCollapsed(
			not section.collapsed,
			true,
			true
		)
	end)

	draghandle.InputBegan:Connect(function(input)
		if uis.TouchEnabled then
			return
		end

		if input.UserInputType
				~= Enum.UserInputType.MouseButton1
			and input.UserInputType
				~= Enum.UserInputType.Touch
		then
			return
		end

		if not acquireinteraction(
			"sectiondrag",
			input
		) then
			return
		end

		closepopup()

		section.headerdragged = false

		sectiondrag = {
			input = input,

			section = section,

			start = point(input),
			current = point(input),

			started = false,
		}
	end)

	local function register(
		row,
		name
	)
		table.insert(
			section.controls,
			{
				row = row,
				name = string.lower(plaintext(name)),
			}
		)

		if row:IsA("TextLabel")
			or row:IsA("TextButton")
			or row:IsA("TextBox")
		then
			registergradienttarget(row, row)
			return
		end

		local expected = string.lower(plaintext(name))
		local fallback

		for _, object in ipairs(row:GetDescendants()) do
			if object:IsA("TextLabel")
				or object:IsA("TextButton")
				or object:IsA("TextBox")
			then
				local visible = string.lower(plaintext(object.Text))

				if visible ~= "" and not fallback then
					fallback = object
				end

				if visible == expected then
					registergradienttarget(row, object)
					return
				end
			end
		end

		if fallback then
			registergradienttarget(row, fallback)
		end
	end


	-- label

	function section:AddLabel(
		text,
		wrap,
		target
	)
		local parentobject = target or body

		local object = label(
			parentobject,
			text,
			UDim2.new(1, 0, 0, 20),
			font,
			theme.text2
		)

		object.TextSize = 16
		object.TextWrapped = wrap ~= false
		object.TextYAlignment = Enum.TextYAlignment.Top
		object.AutomaticSize =
			wrap ~= false
			and Enum.AutomaticSize.Y
			or Enum.AutomaticSize.None

		register(object, text)

		return object
	end

	-- button

	function section:AddButton(
		name,
		callback,
		target
	)
		local parentobject =
			target or body

		local button = new("TextButton", {
			Parent = parentobject,

			Size = UDim2.new(
				1,
				0,
				0,
				32
			),

			BackgroundColor3 = theme.input,
			BackgroundTransparency = .08,
			BorderSizePixel = 0,

			Text = name,
			TextColor3 = theme.text2,
			TextSize = 16,
			Font = medium,
			TextXAlignment = Enum.TextXAlignment.Center,

			AutoButtonColor = false,
			ZIndex = 15,
		})

		corner(button, 7)
		stroke(
			button,
			.68,
			theme.border,
			.6
		)

		button.MouseEnter:Connect(function()
			tween(button, {TextColor3 = theme.text}, hoverti)
		end)

		button.MouseLeave:Connect(function()
			tween(button, {TextColor3 = theme.text2}, hoverti)
		end)

		button.Activated:Connect(function()
			if callback then
				callback()
			end
		end)

		register(
			button,
			name
		)

		return button
	end

	-- row

	function section:AddRow(spacing, height, target)
		local gap = tonumber(spacing) or 8
		local rowheight = tonumber(height) or 32
		local parentobject = target or body

		local holder = new("Frame", {
			Parent = parentobject,
			Size = UDim2.new(1, 0, 0, rowheight),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = 15,
		})

		local rowlayout = new("UIListLayout", {
			Parent = holder,
			FillDirection = uis.TouchEnabled
				and Enum.FillDirection.Vertical
				or Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, gap),
			SortOrder = Enum.SortOrder.LayoutOrder,
		})

		local row = {
			Frame = holder,
			Layout = rowlayout,
			Items = {},
		}

		function row:Refresh()
			local count = #self.Items

			if count == 0 then
				return
			end

			if uis.TouchEnabled then
				self.Frame.Size = UDim2.new(
					1,
					0,
					0,
					count * rowheight + gap * (count - 1)
				)

				for index, item in ipairs(self.Items) do
					item.LayoutOrder = index
					item.Size = UDim2.new(
						1,
						0,
						0,
						rowheight
					)
				end

				return
			end

			local offset =
				-gap * (count - 1) / count

			for index, item in ipairs(self.Items) do
				item.LayoutOrder = index
				item.Size = UDim2.new(
					1 / count,
					offset,
					0,
					rowheight
				)
			end
		end

		function row:AddButton(name, callback)
			local button =
				section:AddButton(
					name,
					callback,
					holder
				)

			table.insert(self.Items, button)
			self:Refresh()

			return button
		end

		function row:AddToggle(name, default, callback, keybindable, badge)
			local control =
				section:AddToggle(
					name,
					default,
					callback,
					holder,
					keybindable,
					badge
				)

			table.insert(self.Items, control.Object)
			self:Refresh()

			return control
		end

		return row
	end

	-- toggle

	function section:AddToggle(
		name,
		default,
		callback,
		target,
		keybindable,
		badge
	)
		local parentobject =
			target or body

		local hasbinding =
			keybindable == true
			and not uis.TouchEnabled

		local row = new("TextButton", {
			Parent = parentobject,

			Position = UDim2.fromOffset(0, 0),

			Size = UDim2.new(1, 0, 0, 24),

			BackgroundColor3 = theme.hover,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,

			Text = "",
			AutoButtonColor = false,

			ZIndex = 15,
		})

		corner(row, 6)


		local box, render =
			makecheckbox(
				row,
				19,
				default
			)

		box.AnchorPoint =
			Vector2.new(
				0,
				.5
			)

		box.Position = UDim2.new(0, 0, .5, 0)

		local textobject =
			label(
				row,
				name,
				UDim2.new(
					1,
					hasbinding and -58 or -30,
					1,
					0
				),
				font
			)

		textobject.Position = UDim2.fromOffset(29, 0)

		textobject.TextSize = 17
		textobject.TextTruncate = Enum.TextTruncate.AtEnd
		textobject.ZIndex = 16

		textobject.TextColor3 = theme.text2
		row.MouseEnter:Connect(function()
			tween(textobject, {TextColor3 = theme.text}, hoverti)
		end)
		row.MouseLeave:Connect(function()
			tween(textobject, {TextColor3 = theme.text2}, hoverti)
		end)

		if badge then
			local badgetext =
				type(badge) == "table"
				and (badge.Text or badge.text or "NEW")
				or tostring(badge)

			local textbounds =
				measuretext(
					plaintext(name),
					17,
					font,
					Vector2.new(260, 24)
				)

			local badgebounds =
				measuretext(
					badgetext,
					11,
					bold,
					Vector2.new(100, 16)
				)

			local badgeobject = new("TextLabel", {
				Parent = row,
				AnchorPoint = Vector2.new(0, .5),
				Position = UDim2.fromOffset(
					29 + math.ceil(textbounds.X) + 7,
					12
				),
				Size = UDim2.fromOffset(
					math.ceil(badgebounds.X) + 10,
					17
				),
				BackgroundColor3 =
					type(badge) == "table"
					and (badge.Color or badge.color)
					or theme.text,
				BackgroundTransparency = .04,
				BorderSizePixel = 0,
				Text = badgetext,
				TextColor3 =
					type(badge) == "table"
					and (badge.TextColor or badge.textcolor)
					or theme.window,
				Font = bold,
				TextSize = 11,
				ZIndex = 18,
			})

			corner(badgeobject, 4)
		end

		local enabled =
			default == true

		local binding

		local function setenabled(value, fire)
			enabled = value == true
			render(enabled)
			requesthotkeyrefresh(binding)

			if fire ~= false
				and callback
			then
				callback(enabled)
			end
		end

		binding = {
			name = name,
			category = section.page.primary or "Misc",
			categoryicon = section.page.icon,
			page = section.page,
			subpage = section.page.secondary,
			sectionname = section.name,
			key = nil,
			mode = "Toggle",
			held = false,
			suppressclick = false,
			get = function()
				return enabled
			end,
			set = setenabled,
		}

		registertogglebinding(binding)

		if not uis.TouchEnabled then
			attachtoggleconfig(
				row,
				binding
			)
		end

		local keyobject
		if hasbinding then
			keyobject = attachinlinekeypicker(
				row,
				binding,
				textobject,
				Enum.KeyCode.F
			)
		end

		row.Activated:Connect(function()
			if binding.suppressclick then
				binding.suppressclick = false
				return
			end

			if binding.mode == "Always On" then
				setenabled(true, true)
				return
			end

			setenabled(
				not enabled,
				true
			)
		end)

		register(
			row,
			name
		)

		return {
			Get = function()
				return enabled
			end,

			Set = function(_, value, fire)
				setenabled(value, fire)
			end,

			Object = row,
			Binding = binding,
			TextObject = textobject,
			KeyObject = keyobject,
		}
	end

	-- checkbox + inline key picker

	function section:AddToggleKey(
		name,
		default,
		defaultkey,
		callback,
		keycallback,
		target,
		badge
	)
		local control = self:AddToggle(
			name,
			default,
			callback,
			target,
			false,
			badge
		)

		if uis.TouchEnabled then
			return control
		end

		local keybutton = attachinlinekeypicker(
			control.Object,
			control.Binding,
			control.TextObject,
			defaultkey or Enum.KeyCode.F,
			keycallback
		)

		control.KeyObject = keybutton
		return control
	end

	-- toggle color

	function section:AddToggleColor(
		name,
		default,
		color,
		togglecallback,
		colorcallback,
		target,
		keybindable
	)
		local parentobject =
			target or body

		local hasbinding =
			keybindable == true
			and not uis.TouchEnabled

		local row = new("Frame", {
			Parent = parentobject,

			Size =
				UDim2.new(
					1,
					0,
					0,
					24
				),

			BackgroundTransparency = 1,

			ZIndex = 15,
		})

		local togglebutton =
			new("TextButton", {
				Parent = row,

				Position = UDim2.fromOffset(0, 0),

				Size = UDim2.new(1, -33, 1, 0),

				BackgroundColor3 = theme.hover,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,

				Text = "",
				AutoButtonColor = false,

				ZIndex = 16,
			})

		corner(togglebutton, 6)


		local box, render =
			makecheckbox(
				togglebutton,
				19,
				default
			)

		box.AnchorPoint =
			Vector2.new(
				0,
				.5
			)

		box.Position = UDim2.new(0, 0, .5, 0)

		local textobject =
			label(
				togglebutton,
				name,
				UDim2.new(
					1,
					hasbinding and -48 or -29,
					1,
					0
				),
				font
			)

		textobject.Position = UDim2.fromOffset(29, 0)

		textobject.TextSize = 17
		textobject.TextTruncate = Enum.TextTruncate.AtEnd
		textobject.ZIndex = 17

		textobject.TextColor3 = theme.text2
		togglebutton.MouseEnter:Connect(function()
			tween(textobject, {TextColor3 = theme.text}, hoverti)
		end)
		togglebutton.MouseLeave:Connect(function()
			tween(textobject, {TextColor3 = theme.text2}, hoverti)
		end)

		local pickerbutton =
			new("TextButton", {
				Parent = row,

				AnchorPoint =
					Vector2.new(
						1,
						.5
					),

				Position =
					UDim2.new(
						1,
						0,
						.5,
						0
					),

				Size =
					UDim2.fromOffset(
						22,
						22
					),

				BackgroundTransparency = 1,
				BorderSizePixel = 0,

				Text = "",
				AutoButtonColor = false,

				ZIndex = 16,
			})

		local swatch = new("Frame", {
			Parent = pickerbutton,

			Size =
				UDim2.fromScale(
					1,
					1
				),

			BackgroundColor3 =
				color,

			BorderSizePixel = 0,

			ZIndex = 17,
		})

		corner(swatch, 5)

		local swatchglow =
			addshadow(
				swatch,
				"ColorGlow",
				.62,
				7,
				1,
				-1,
				color,
				UDim2.fromOffset(0, 0),
				false
			)

		local colorstate =
			createcolorstate(
				color,
				colorcallback,
				swatch
			)

		colorstate.swatchglow = swatchglow
		colorstate:apply()

		local enabled =
			default == true

		local binding

		local function setenabled(value, fire)
			enabled = value == true
			render(enabled)
			requesthotkeyrefresh(binding)

			if fire ~= false
				and togglecallback
			then
				togglecallback(enabled)
			end
		end

		binding = {
			name = name,
			category = section.page.primary or "Misc",
			categoryicon = section.page.icon,
			page = section.page,
			subpage = section.page.secondary,
			sectionname = section.name,
			key = nil,
			mode = "Toggle",
			held = false,
			suppressclick = false,
			get = function()
				return enabled
			end,
			set = setenabled,
			hotkeycolor = function()
				return colorstate:color()
			end,
		}
		colorstate.hotkeybinding = binding
		registertogglebinding(binding)

		if not uis.TouchEnabled then
			attachtoggleconfig(
				togglebutton,
				binding
			)
		end

		if hasbinding then
			addtoggleconfigicon(
				togglebutton,
				binding,
				row,
				0
			)
			pickerbutton.Position = UDim2.new(1, -26, .5, 0)
			togglebutton.Size = UDim2.new(1, -52, 1, 0)
			textobject.Size = UDim2.new(1, -58, 1, 0)
		end

		togglebutton.Activated:Connect(function()
			if binding.suppressclick then
				binding.suppressclick = false
				return
			end

			if binding.mode == "Always On" then
				setenabled(true, true)
				return
			end

			setenabled(
				not enabled,
				true
			)
		end)

		pickerbutton.Activated:Connect(function()
			opencolorpicker(
				pickerbutton,
				colorstate
			)
		end)

		register(
			row,
			name
		)

		return {
			Get = function()
				return enabled
			end,

			Set = function(_, value, fire)
				setenabled(value, fire)
			end,

			Color = colorstate,
			Binding = binding,
			Object = row,
			ToggleObject = togglebutton,
			PickerObject = pickerbutton,
			TextObject = textobject,
		}
	end

	-- checkbox + color picker + key picker

	function section:AddToggleColorKey(
		name,
		default,
		color,
		defaultkey,
		togglecallback,
		colorcallback,
		keycallback,
		target
	)
		local control = self:AddToggleColor(
			name,
			default,
			color,
			togglecallback,
			colorcallback,
			target,
			false
		)

		if uis.TouchEnabled then
			return control
		end

		local row = control.Object
		local togglebutton = control.ToggleObject
		local pickerbutton = control.PickerObject
		local binding = control.Binding

		setbindingkey(
			binding,
			defaultkey or Enum.KeyCode.F,
			false
		)
		binding.inlinekey = true

		togglebutton.Size = UDim2.new(1, -106, 1, 0)
		control.TextObject.Size = UDim2.new(1, -38, 1, 0)

		local keybutton = new("TextButton", {
			Parent = row,
			AnchorPoint = Vector2.new(1, .5),
			Position = UDim2.new(1, -29, .5, 0),
			Size = UDim2.fromOffset(54, 22),
			BackgroundColor3 = theme.input,
			BackgroundTransparency = .08,
			BorderSizePixel = 0,
			Text = "",
			AutoButtonColor = false,
			ZIndex = 18,
		})
		corner(keybutton, 6)
	keyeditbuttons[keybutton] = true
		stroke(keybutton, .72, theme.border, .6)

		local keytext = label(
			keybutton,
			"",
			UDim2.fromScale(1, 1),
			medium,
			theme.text2
		)
		keytext.TextSize = 13
		keytext.TextXAlignment = Enum.TextXAlignment.Center
		keytext.ZIndex = 19

		local configbutton = addtoggleconfigicon(
			row,
			binding,
			row,
			0
		)
		pickerbutton.Position = UDim2.new(1, -26, .5, 0)

		local listening = false

		local function renderkey()
			local value = listening and "..." or togglekeyname(binding.key)
			keytext.Text = value

			local bounds = measuretext(
				value,
				13,
				medium,
				Vector2.new(120, 22)
			)

			local width = math.clamp(math.ceil(bounds.X) + 18, 38, 76)
			keybutton.Size = UDim2.fromOffset(width, 22)
			keybutton.Position = UDim2.new(1, -54, .5, 0)
			configbutton.Position = UDim2.new(1, 0, .5, 0)
			pickerbutton.Position = UDim2.new(1, -26, .5, 0)
			togglebutton.Size = UDim2.new(1, -(width + 78), 1, 0)
			control.TextObject.Size = UDim2.new(1, -40, 1, 0)
		end

		binding.refreshkey = renderkey

		keybutton.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch
			then
				binding.suppressclick = true
			end
		end)

		keybutton.Activated:Connect(function()
			if listening then
				listening = false
				endkeycapture(row, nil)
				binding.suppressclick = false
				renderkey()
				return
			end

			listening = true

			if not beginkeycapture(
				row,
				function()
					listening = false
					renderkey()
				end,
				function(selectedkey)
					listening = false
					setbindingkey(binding, selectedkey)
					renderkey()

					if keycallback then
						keycallback(binding.key)
					end
				end,
				function(input)
					return input.UserInputType == Enum.UserInputType.MouseButton1
						and inside(keybutton, point(input))
				end
			) then
				listening = false
			end

			binding.suppressclick = false
			renderkey()
		end)

		connect(
			row.Destroying,
			function()
				if listening then
					listening = false
					endkeycapture(row, nil)
				end
			end
		)

		keybutton.MouseEnter:Connect(function()
			tween(keytext, {TextColor3 = theme.text}, hoverti)
		end)

		keybutton.MouseLeave:Connect(function()
			tween(keytext, {TextColor3 = theme.text2}, hoverti)
		end)

		renderkey()
		refreshhotkeylist()

		control.KeyObject = keybutton
		return control
	end

	-- slider

	function section:AddSlider(
		name,
		minimum,
		maximum,
		default,
		suffix,
		callback,
		target
	)
		local parentobject =
			target or body

		local holder = new("Frame", {
			Parent = parentobject,

			Size =
				UDim2.new(
					1,
					0,
					0,
					43
				),

			BackgroundColor3 = theme.hover,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Active = true,

			ZIndex = 15,
		})

		corner(holder, 6)


		local title =
			label(
				holder,
				name,
				UDim2.new(
					1,
					-80,
					0,
					19
				),
				font
			)

		title.TextSize = 17

		local valueobject =
			label(
				holder,
				"",
				UDim2.fromOffset(
					80,
					19
				),
				medium,
				theme.text3
			)

		valueobject.AnchorPoint =
			Vector2.new(
				1,
				0
			)

		valueobject.Position =
			UDim2.new(
				1,
				0,
				0,
				0
			)

		valueobject.TextXAlignment =
			Enum.TextXAlignment.Right

		valueobject.TextSize = 16

		holder.MouseEnter:Connect(function()
			tween(title, {TextColor3 = theme.text}, hoverti)
			tween(valueobject, {TextColor3 = theme.text2}, hoverti)
		end)
		holder.MouseLeave:Connect(function()
			tween(title, {TextColor3 = theme.text}, hoverti)
			tween(valueobject, {TextColor3 = theme.text3}, hoverti)
		end)

		local track = new("TextButton", {
			Parent = holder,

			Position =
				UDim2.fromOffset(
					0,
					32
				),

			Size =
				UDim2.new(
					1,
					0,
					0,
					5
				),

			BackgroundColor3 =
				theme.track,

			BorderSizePixel = 0,

			Text = "",
			AutoButtonColor = false,

			ZIndex = 16,
		})

		corner(track, 999)


		local fill = new("Frame", {
			Parent = track,

			Size =
				UDim2.fromScale(
					0,
					1
				),

			BackgroundColor3 =
				theme.white,

			BorderSizePixel = 0,

			ZIndex = 17,
		})

		corner(fill, 999)
		local fillglow =
			addglow(
				fill,
				"active"
			)

		if fillglow then
			fillglow.Transparency = .66
		end

		local knob = new("Frame", {
			Parent = track,

			AnchorPoint =
				Vector2.new(
					.5,
					.5
				),

			Position =
				UDim2.fromScale(
					0,
					.5
				),

			Size =
				UDim2.fromOffset(
					13,
					13
				),

			BackgroundColor3 =
				theme.white,

			BorderSizePixel = 0,

			ZIndex = 18,
		})

		corner(knob, 999)

		local sliderhit = new("TextButton", {
			Parent = holder,

			Position =
				UDim2.fromOffset(
					0,
					27
				),

			Size =
				UDim2.new(
					1,
					0,
					0,
					16
				),

			BackgroundTransparency = 1,
			BorderSizePixel = 0,

			Text = "",
			AutoButtonColor = false,

			ZIndex = 19,
		})

		local value =
			default

		local function format(number)
			if math.abs(
				number
					- math.round(number)
			) < .001
			then
				return tostring(
					math.round(number)
				)
			end

			return string.format(
				"%.2f",
				number
			)
		end

		local function set(
			number,
			fire
		)
			number =
				math.clamp(
					number,
					minimum,
					maximum
				)

			local alpha =
				maximum == minimum
				and 0
				or (
					number - minimum
				)
					/ (
						maximum
						- minimum
					)

			value = number

			fill.Size =
				UDim2.fromScale(
					alpha,
					1
				)

			knob.Position =
				UDim2.fromScale(
					alpha,
					.5
				)

			valueobject.Text =
				format(number)
				.. (suffix or "")

			if fire
				and callback
			then
				callback(number)
			end
		end

		local function update(position)
			local alpha =
				math.clamp(
					(
						position.X
						- track.AbsolutePosition.X
					)
						/ track.AbsoluteSize.X,
					0,
					1
				)

			set(
				minimum
				+ (
					maximum
					- minimum
				)
					* alpha,
				true
			)
		end

		sliderhit.InputBegan:Connect(function(input)
			if input.UserInputType
					~= Enum.UserInputType.MouseButton1
				and input.UserInputType
					~= Enum.UserInputType.Touch
			then
				return
			end

			if not acquireinteraction(
				"slider",
				input
			) then
				return
			end

			sliderdrag = {
				input = input,
				update = update,

				knobs = {
					knob,
				},
			}

			update(
				point(input)
			)

			tween(
				knob,
				{
					Size =
						UDim2.fromOffset(
							15,
							15
						),
				},
				fastti
			)
		end)

		set(
			default,
			false
		)

		register(
			holder,
			name
		)

		return {
			Get = function()
				return value
			end,

			Set = function(_, number)
				set(
					number,
					true
				)
			end,

			Object = holder,
			TextObject = title,
		}
	end

	-- range slider

	function section:AddRangeSlider(
		name,
		minimum,
		maximum,
		defaultmin,
		defaultmax,
		suffix,
		callback,
		target
	)
		local parentobject =
			target or body

		local holder = new("Frame", {
			Parent = parentobject,

			Size =
				UDim2.new(
					1,
					0,
					0,
					43
				),

			BackgroundColor3 = theme.hover,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Active = true,

			ZIndex = 15,
		})

		corner(holder, 6)


		local title =
			label(
				holder,
				name,
				UDim2.new(
					1,
					-130,
					0,
					19
				),
				font
			)

		title.TextSize = 17

		local valueobject =
			label(
				holder,
				"",
				UDim2.fromOffset(
					130,
					19
				),
				medium,
				theme.text3
			)

		valueobject.AnchorPoint =
			Vector2.new(
				1,
				0
			)

		valueobject.Position =
			UDim2.new(
				1,
				0,
				0,
				0
			)

		valueobject.TextXAlignment =
			Enum.TextXAlignment.Right

		valueobject.TextSize = 16

		holder.MouseEnter:Connect(function()
			tween(title, {TextColor3 = theme.text}, hoverti)
			tween(valueobject, {TextColor3 = theme.text2}, hoverti)
		end)
		holder.MouseLeave:Connect(function()
			tween(title, {TextColor3 = theme.text}, hoverti)
			tween(valueobject, {TextColor3 = theme.text3}, hoverti)
		end)

		local track = new("TextButton", {
			Parent = holder,

			Position =
				UDim2.fromOffset(
					0,
					32
				),

			Size =
				UDim2.new(
					1,
					0,
					0,
					5
				),

			BackgroundColor3 =
				theme.track,

			BorderSizePixel = 0,

			Text = "",
			AutoButtonColor = false,

			ZIndex = 16,
		})

		corner(track, 999)


		local rangefill = new("Frame", {
			Parent = track,

			BackgroundColor3 =
				theme.white,

			BorderSizePixel = 0,

			ZIndex = 17,
		})

		corner(rangefill, 999)
		local rangeglow =
			addglow(
				rangefill,
				"active"
			)

		if rangeglow then
			rangeglow.Transparency = .66
		end

		local lowknob = new("Frame", {
			Parent = track,

			AnchorPoint =
				Vector2.new(
					.5,
					.5
				),

			Size =
				UDim2.fromOffset(
					13,
					13
				),

			BackgroundColor3 =
				theme.white,

			BorderSizePixel = 0,

			ZIndex = 18,
		})

		corner(lowknob, 999)

		local highknob = new("Frame", {
			Parent = track,

			AnchorPoint =
				Vector2.new(
					.5,
					.5
				),

			Size =
				UDim2.fromOffset(
					13,
					13
				),

			BackgroundColor3 =
				theme.white,

			BorderSizePixel = 0,

			ZIndex = 18,
		})

		corner(highknob, 999)

		local rangehit = new("TextButton", {
			Parent = holder,

			Position =
				UDim2.fromOffset(
					0,
					27
				),

			Size =
				UDim2.new(
					1,
					0,
					0,
					16
				),

			BackgroundTransparency = 1,
			BorderSizePixel = 0,

			Text = "",
			AutoButtonColor = false,

			ZIndex = 19,
		})

		local low =
			math.clamp(
				math.min(
					defaultmin,
					defaultmax
				),
				minimum,
				maximum
			)

		local high =
			math.clamp(
				math.max(
					defaultmin,
					defaultmax
				),
				minimum,
				maximum
			)

		local active =
			"low"

		local function format(value)
			if math.abs(
				value
					- math.round(value)
			) < .001
			then
				return tostring(
					math.round(value)
				)
			end

			return string.format(
				"%.2f",
				value
			)
		end

		local function render(fire)
			local denominator =
				math.max(
					.0001,
					maximum - minimum
				)

			local lowalpha =
				(low - minimum)
					/ denominator

			local highalpha =
				(high - minimum)
					/ denominator

			lowknob.Position =
				UDim2.fromScale(
					lowalpha,
					.5
				)

			highknob.Position =
				UDim2.fromScale(
					highalpha,
					.5
				)

			rangefill.Position =
				UDim2.fromScale(
					lowalpha,
					0
				)

			rangefill.Size =
				UDim2.new(
					highalpha
						- lowalpha,
					0,
					1,
					0
				)

			valueobject.Text =
				format(low)
				.. (suffix or "")
				.. " - "
				.. format(high)
				.. (suffix or "")

			if fire
				and callback
			then
				callback(
					low,
					high
				)
			end
		end

		local function update(position)
			local alpha =
				math.clamp(
					(
						position.X
						- track.AbsolutePosition.X
					)
						/ track.AbsoluteSize.X,
					0,
					1
				)

			local value =
				minimum
				+ (
					maximum
					- minimum
				)
					* alpha

			if active == "low" then
				low =
					math.clamp(
						value,
						minimum,
						high
					)
			else
				high =
					math.clamp(
						value,
						low,
						maximum
					)
			end

			render(true)
		end

		rangehit.InputBegan:Connect(function(input)
			if input.UserInputType
					~= Enum.UserInputType.MouseButton1
				and input.UserInputType
					~= Enum.UserInputType.Touch
			then
				return
			end

			local p =
				point(input)

			local lowx =
				lowknob.AbsolutePosition.X
				+ lowknob.AbsoluteSize.X / 2

			local highx =
				highknob.AbsolutePosition.X
				+ highknob.AbsoluteSize.X / 2

			active =
				math.abs(
					p.X - lowx
				)
					<= math.abs(
						p.X - highx
					)
				and "low"
				or "high"

			local knob =
				active == "low"
				and lowknob
				or highknob

			if not acquireinteraction(
				"slider",
				input
			) then
				return
			end

			sliderdrag = {
				input = input,
				update = update,

				knobs = {
					knob,
				},
			}

			update(p)

			tween(
				knob,
				{
					Size =
						UDim2.fromOffset(
							15,
							15
						),
				},
				fastti
			)
		end)

		render(false)

		register(
			holder,
			name
		)

		return {
			Get = function()
				return low, high
			end,
			Set = function(_, newlow, newhigh, fire)
				local a = math.clamp(
					tonumber(newlow) or low,
					minimum,
					maximum
				)
				local b = math.clamp(
					tonumber(newhigh) or high,
					minimum,
					maximum
				)
				low = math.min(a, b)
				high = math.max(a, b)
				render(fire ~= false)
			end,
			Object = holder,
			TextObject = title,
		}
	end

	local function dropdownpopup(
		button,
		count
	)
		if activepopup
			and activepopup.anchor == button
		then
			closepopup()
			return nil, nil
		end

		local position =
			overlayposition(button)

		local size =
			button.AbsoluteSize

		local popupy =
			position.Y
			+ size.Y
			+ 6

		local wanted =
			count * 34
			+ 8

		local available =
			popuplayer.AbsoluteSize.Y
			- popupy
			- 8

		local height =
			math.max(
				34,
				math.min(
					wanted,
					available
				)
			)

		local panel, popup = createpopup(
			Vector2.new(
				position.X,
				popupy
			),
			size.X,
			height,
			510,
			"dropdown"
		)

		popup.anchor = button
		return panel, popup
	end


	local function binddropdownscrollbar(scroll, thickness)
		thickness = thickness or 2

		local function update()
			if not scroll or not scroll.Parent then
				return
			end

			local overflow = scroll.AbsoluteCanvasSize.Y - scroll.AbsoluteSize.Y
			local needs = overflow > 6
			scroll.ScrollBarThickness = needs and thickness or 0

			if not needs and scroll.CanvasPosition.Y ~= 0 then
				scroll.CanvasPosition = Vector2.new(0, 0)
			end
		end

		scroll:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(update)
		scroll:GetPropertyChangedSignal("AbsoluteSize"):Connect(update)
		update()
	end

	-- dropdown

	function section:AddDropdown(
		name,
		options,
		default,
		callback,
		target,
		config
	)
		local parentobject = target or body
		config = config or {}

		local dividerbefore = table.clone(config.dividers or {})
		local optioncolors = table.clone(config.colors or {})
		local optionicons = table.clone(config.icons or {})
		local searchable = config.searchable == true
		local normalized = {}
		local pendingdivider

		for _, entry in ipairs(options or {}) do
			if type(entry) == "table" then
				if entry.Divider == true or entry.divider == true then
					pendingdivider = entry.Text or entry.text or true
				else
					local value = entry.Value or entry.value or entry.Name or entry.name or entry.Text or entry.text
					if value ~= nil then
						normalized[#normalized + 1] = value
						local asset = entry.Icon or entry.icon
						local color = entry.Color or entry.color
						if asset then optionicons[value] = asset end
						if color then optioncolors[value] = color end
						if pendingdivider ~= nil then
							dividerbefore[value] = pendingdivider
							pendingdivider = nil
						end
					end
				end
			else
				normalized[#normalized + 1] = entry
				if pendingdivider ~= nil then
					dividerbefore[entry] = pendingdivider
					pendingdivider = nil
				end
			end
		end

		options = normalized

		local dividercount = 0
		for _, option in ipairs(options) do
			if dividerbefore[option] ~= nil then
				dividercount += 1
			end
		end

		local holder = new("Frame", {
			Parent = parentobject,
			Size = UDim2.new(1, 0, 0, 57),
			BackgroundTransparency = 1,
			ZIndex = 15,
		})

		local title = label(
			holder,
			name,
			UDim2.new(1, 0, 0, 18),
			font
		)
		title.TextSize = 17

		local button = new("TextButton", {
			Parent = holder,
			Position = UDim2.fromOffset(0, 25),
			Size = UDim2.new(1, 0, 0, 32),
			BackgroundColor3 = theme.input,
			BorderSizePixel = 0,
			Text = "",
			AutoButtonColor = false,
			ZIndex = 16,
		})

		corner(button, 7)

		local selected = default or options[1]
		local optionbindings = {}

		local previewicon

		local previewcolor = rawnew("Frame", {
			Parent = button,
			AnchorPoint = Vector2.new(0, .5),
			Position = UDim2.fromOffset(10, 16),
			Size = UDim2.fromOffset(10, 10),
			BackgroundColor3 = optioncolors[selected] or theme.text3,
			BorderSizePixel = 0,
			Visible = optioncolors[selected] ~= nil,
			ZIndex = 18,
		})
		corner(previewcolor, 3)
		stroke(previewcolor, .62, theme.border, .5)

		local valuetext = label(
			button,
			tostring(selected or "None"),
			UDim2.new(1, -38, 1, 0),
			font
		)
		valuetext.TextSize = 17
		valuetext.ZIndex = 17

		local function updatepreview()
			local asset = optionicons[selected]
			local color = optioncolors[selected]

			if asset then
				if not previewicon
					or not previewicon.Parent
				then
					previewicon = image(
						button,
						asset,
						18,
						theme.text2,
						18
					)

					previewicon.AnchorPoint =
						Vector2.new(0, .5)

					previewicon.ScaleType =
						Enum.ScaleType.Fit
				else
					previewicon.Image =
						tostring(asset)
				end
			elseif previewicon then
				previewicon:Destroy()
				previewicon = nil
			end

			previewcolor.Visible = color ~= nil

			if color then
				previewcolor.BackgroundColor3 = color
			end

			local offset = 10
			if previewicon then
				previewicon.Position = UDim2.fromOffset(offset, 16)
				offset += 22
			end
			if color then
				previewcolor.Position = UDim2.fromOffset(offset, 16)
				offset += 18
			end

			valuetext.Position = UDim2.fromOffset(offset, 0)
			valuetext.Size = UDim2.new(1, -(offset + 28), 1, 0)
			valuetext.Text = tostring(selected or "None")
		end

		updatepreview()

		local function setselected(option, fire)
			if not table.find(options, option) then
				return false
			end

			selected = option
			updatepreview()

			if fire ~= false
				and callback
			then
				callback(option)
			end

			for _, binding in pairs(optionbindings) do
				requesthotkeyrefresh(binding)
			end

			return true
		end

		local function optionbinding(option)
			local existing =
				optionbindings[option]

			if existing then
				return existing
			end

			local binding

			binding = {
				kind = "DropdownOption",
				name = name .. " / " .. tostring(option),
				category = section.page.primary or "Misc",
				categoryicon = section.page.icon,
				page = section.page,
				subpage = section.page.secondary,
				sectionname = section.name,
				key = nil,
				mode = "Toggle",
				held = false,
				suppressclick = false,
				previous = nil,

				get = function()
					return selected == option
				end,

				set = function(value, fire)
					if value == true then
						if selected ~= option then
							binding.previous = selected
						end

						setselected(
							option,
							fire
						)
					elseif selected == option
						and binding.previous
						and table.find(
							options,
							binding.previous
						)
					then
						setselected(
							binding.previous,
							fire
						)
					end
				end,
			}

			optionbindings[option] =
				binding

			registertogglebinding(binding)
			return binding
		end

		for _, option in ipairs(options) do
			optionbinding(option)
		end

		local arrow = image(button, icons.down, 14, theme.text3, 17)
		arrow.AnchorPoint = Vector2.new(1, .5)
		arrow.Position = UDim2.new(1, -10, .5, 0)

		button.MouseEnter:Connect(function()
			tween(valuetext, {TextColor3 = theme.text}, hoverti)
			tween(arrow, {ImageColor3 = theme.text2}, hoverti)
		end)
		button.MouseLeave:Connect(function()
			tween(valuetext, {TextColor3 = theme.text2}, hoverti)
			tween(arrow, {ImageColor3 = theme.text3}, hoverti)
		end)

		button.Activated:Connect(function()
			local usesearch = searchable and #options >= 6
			local panel, popup = dropdownpopup(
				button,
				#options + dividercount * .7 + (usesearch and 1.08 or 0)
			)

			if not panel or not popup then
				return
			end

			tween(arrow, { Rotation = 180 }, tabti)
			popup.onclose = function()
				tween(arrow, { Rotation = 0 }, tabti)
			end

			local searchbox
			local searchheight = usesearch and 36 or 0

			if usesearch then
				local searchframe = new("Frame", {
					Parent = panel,
					Position = UDim2.fromOffset(6, 6),
					Size = UDim2.new(1, -12, 0, 30),
					BackgroundColor3 = theme.input,
					BackgroundTransparency = .08,
					BorderSizePixel = 0,
					ClipsDescendants = true,
					ZIndex = 514,
				})
				corner(searchframe, 6)

				local searchicon = image(searchframe, icons.search, 17, theme.text3, 515)
				searchicon.AnchorPoint = Vector2.new(0, .5)
				searchicon.Position = UDim2.fromOffset(9, 15)

				searchbox = new("TextBox", {
					Parent = searchframe,
					Position = UDim2.fromOffset(33, 0),
					Size = UDim2.new(1, -41, 1, 0),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Text = "",
					PlaceholderText = "Search...",
					PlaceholderColor3 = theme.text3,
					TextColor3 = theme.text,
					Font = font,
					TextSize = 15,
					TextXAlignment = Enum.TextXAlignment.Left,
					ClearTextOnFocus = false,
					ZIndex = 515,
				})
			end

			local scroll = new("ScrollingFrame", {
				Parent = panel,
				Position = UDim2.fromOffset(6, 6 + searchheight),
				Size = UDim2.new(1, -12, 1, -12 - searchheight),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				CanvasSize = UDim2.new(),
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				ScrollBarThickness = 0,
				ScrollBarImageTransparency = .56,
				ScrollBarImageColor3 = theme.scroll,
				ZIndex = 512,
			})
			list(scroll, 2)
			binddropdownscrollbar(scroll, 2)

			local optionrows = {}
			local dividerrows = {}

			for _, option in ipairs(options) do
				local divider = dividerbefore[option]

				if divider ~= nil then
					local dividerrow = new("Frame", {
						Parent = scroll,
						Size = UDim2.new(1, 0, 0, (divider == true or divider == "") and 14 or 22),
						BackgroundTransparency = 1,
						BorderSizePixel = 0,
						ZIndex = 514,
					})

					if divider == true or divider == "" then
						local line = new("Frame", {
							Parent = dividerrow,
							AnchorPoint = Vector2.new(.5, .5),
							Position = UDim2.fromScale(.5, .5),
							Size = UDim2.new(1, -14, 0, 1),
							BackgroundColor3 = theme.border,
							BackgroundTransparency = .38,
							BorderSizePixel = 0,
							ZIndex = 515,
						})
						corner(line, 999)
					else
						local dividerlabel = label(
							dividerrow,
							plaintext(tostring(divider)),
							UDim2.fromOffset(90, 22),
							medium,
							theme.text3
						)
						dividerlabel.AnchorPoint = Vector2.new(.5, .5)
						dividerlabel.Position = UDim2.fromScale(.5, .5)
						dividerlabel.TextSize = 14
						dividerlabel.TextXAlignment = Enum.TextXAlignment.Center
						dividerlabel.ZIndex = 515

						local leftline = new("Frame", {
							Parent = dividerrow,
							AnchorPoint = Vector2.new(0, .5),
							Position = UDim2.new(0, 7, .5, 0),
							Size = UDim2.new(.5, -59, 0, 1),
							BackgroundColor3 = theme.border,
							BackgroundTransparency = .38,
							BorderSizePixel = 0,
							ZIndex = 515,
						})
						local rightline = new("Frame", {
							Parent = dividerrow,
							AnchorPoint = Vector2.new(1, .5),
							Position = UDim2.new(1, -7, .5, 0),
							Size = UDim2.new(.5, -59, 0, 1),
							BackgroundColor3 = theme.border,
							BackgroundTransparency = .38,
							BorderSizePixel = 0,
							ZIndex = 515,
						})
						corner(leftline, 999)
						corner(rightline, 999)
					end

					dividerrows[#dividerrows + 1] = dividerrow
				end

				local optionbutton = new("TextButton", {
					Parent = scroll,
					Size = UDim2.new(1, 0, 0, 32),
					BackgroundColor3 = theme.hover,
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Text = "",
					AutoButtonColor = false,
					ZIndex = 514,
				})
				corner(optionbutton, 6)

				local x = 9
				local asset = optionicons[option]
				local color = optioncolors[option]

				if asset then
					local optionicon = new("ImageLabel", {
						Parent = optionbutton,
						AnchorPoint = Vector2.new(0, .5),
						Position = UDim2.fromOffset(x, 16),
						Size = UDim2.fromOffset(18, 18),
						BackgroundTransparency = 1,
						BorderSizePixel = 0,
						Image = asset,
						ImageColor3 = theme.text2,
						ScaleType = Enum.ScaleType.Fit,
						ZIndex = 515,
					})
					x += 22
				end

				if color then
					local swatch = rawnew("Frame", {
						Parent = optionbutton,
						AnchorPoint = Vector2.new(0, .5),
						Position = UDim2.fromOffset(x, 16),
						Size = UDim2.fromOffset(10, 10),
						BackgroundColor3 = color,
						BorderSizePixel = 0,
						ZIndex = 515,
					})
					corner(swatch, 3)
					stroke(swatch, .62, theme.border, .5)
					x += 18
				end

				local binding =
					optionbinding(option)

				if not uis.TouchEnabled then
					attachtoggleconfig(
						optionbutton,
						binding
					)
				end

				local optionkey = label(
					optionbutton,
					"",
					UDim2.fromOffset(0, 25),
					medium,
					theme.text3
				)
				optionkey.AnchorPoint = Vector2.new(1, .5)
				optionkey.Position = UDim2.new(1, -7, .5, 0)
				optionkey.TextSize = 13
				optionkey.TextXAlignment = Enum.TextXAlignment.Center
				optionkey.Visible = false
				optionkey.ZIndex = 516

				local optionlabel = label(
					optionbutton,
					tostring(option),
					UDim2.new(1, -(x + 8), 1, 0),
					font,
					option == selected and theme.text or theme.text2
				)
				optionlabel.Position = UDim2.fromOffset(x, 0)
				optionlabel.TextSize = 16
				optionlabel.ZIndex = 515

				local function renderoptionkey()
					if not optionkey.Parent
						or not optionlabel.Parent
					then
						return
					end

					if not binding.key then
						optionkey.Visible = false
						optionlabel.Size =
							UDim2.new(
								1,
								-(x + 8),
								1,
								0
							)
						return
					end

					local keyname =
						togglekeyname(binding.key)

					local bounds =
						measuretext(
							keyname,
							13,
							medium,
							Vector2.new(120, 25)
						)

					local width =
						math.clamp(
							math.ceil(bounds.X) + 14,
							28,
							72
						)

					optionkey.Text = keyname
					optionkey.Size =
						UDim2.fromOffset(
							width,
							25
						)
					optionkey.Visible = true

					optionlabel.Size =
						UDim2.new(
							1,
							-(x + width + 13),
							1,
							0
						)
				end

				binding.refreshkey =
					renderoptionkey

				renderoptionkey()

				optionrows[#optionrows + 1] = {
					value = option,
					button = optionbutton,
				}

				optionbutton.MouseEnter:Connect(function()
					tween(optionlabel, {TextColor3 = theme.text}, hoverti)
				end)

				optionbutton.MouseLeave:Connect(function()
					tween(optionlabel, {
						TextColor3 = option == selected and theme.text or theme.text2,
					}, hoverti)
				end)

				optionbutton.Activated:Connect(function()
					if binding.suppressclick then
						binding.suppressclick = false
						return
					end

					setselected(
						option,
						true
					)

					closepopup()
				end)
			end

			if searchbox then
				searchbox:GetPropertyChangedSignal("Text"):Connect(function()
					local query = string.lower(plaintext(searchbox.Text))

					for _, data in ipairs(optionrows) do
						local value = string.lower(plaintext(tostring(data.value)))
						data.button.Visible = query == ""
							or string.find(value, query, 1, true) ~= nil
					end

					for _, dividerrow in ipairs(dividerrows) do
						dividerrow.Visible = query == ""
					end
				end)

					if not uis.TouchEnabled
					and searchbox
					and searchbox.Parent
				then
					searchbox:CaptureFocus()
				end
			end
		end)

		register(holder, name)

		return {
			Get = function()
				return selected
			end,

			Set = function(_, option, fire)
				setselected(
					option,
					fire
				)
			end,

			SetOptions = function(_, newoptions, preferred)
				options = newoptions or {}
				dividercount = 0

				for _, option in ipairs(options) do
					if dividerbefore[option] ~= nil then
						dividercount += 1
					end
				end

				if preferred and table.find(options, preferred) then
					selected = preferred
				elseif not table.find(options, selected) then
					selected = options[1] or "None"
				end

				for _, option in ipairs(options) do
					optionbinding(option)
				end

				updatepreview()

				for _, binding in pairs(optionbindings) do
					requesthotkeyrefresh(binding)
				end
			end,
			Object = holder,
			TextObject = title,
		}
	end

	-- player dropdown

	function section:AddPlayerDropdown(
		name,
		options,
		default,
		callback,
		target,
		config
	)
		if type(options) ~= "table" then
			config = target or {}
			target = callback
			callback = default
			default = options
			options = {}
		end

		config = config or {}
		options = options or {}

		local parentobject = target or body
		local searchable = config.searchable ~= false
		local playersdivider = config.playersDivider
		local multiselect = config.multiselect == true or config.multi == true
		local includeeveryone = config.everyone ~= false
		local everyonevalue = "Everyone"
		local optionicons = table.clone(config.icons or {})
		local optioncolors = table.clone(config.colors or {})
		local normalized = {}
		local optiondividers = {}
		local pendingdivider

		for _, entry in ipairs(options) do
			if type(entry) == "table" then
				if entry.Divider == true or entry.divider == true then
					pendingdivider = entry.Text or entry.text or true
				else
					local value = entry.Value or entry.value or entry.Name or entry.name or entry.Text or entry.text
					if value ~= nil then
						normalized[#normalized + 1] = value
						local asset = entry.Icon or entry.icon
						local color = entry.Color or entry.color
						if asset then optionicons[value] = asset end
						if color then optioncolors[value] = color end
						if pendingdivider ~= nil then
							optiondividers[value] = pendingdivider
							pendingdivider = nil
						end
					end
				end
			else
				normalized[#normalized + 1] = entry
				if pendingdivider ~= nil then
					optiondividers[entry] = pendingdivider
					pendingdivider = nil
				end
			end
		end
		options = normalized

		local selected = multiselect and {} or default
		if multiselect then
			for _, value in ipairs(type(default) == "table" and default or {}) do
				if value ~= player then
					selected[value] = true
				end
			end
		elseif selected == player then
			selected = nil
		end

		local holder = new("Frame", {
			Parent = parentobject,
			Size = UDim2.new(1, 0, 0, 57),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = 15,
		})

		local title = label(holder, name, UDim2.new(1, 0, 0, 18), font)
		title.TextSize = 17

		local button = new("TextButton", {
			Parent = holder,
			Position = UDim2.fromOffset(0, 25),
			Size = UDim2.new(1, 0, 0, 32),
			BackgroundColor3 = theme.input,
			BorderSizePixel = 0,
			Text = "",
			AutoButtonColor = false,
			ZIndex = 16,
		})
		corner(button, 7)

		local display = label(button, "Select player", UDim2.new(1, -38, 1, 0), font, theme.text2)
		display.Position = UDim2.fromOffset(10, 0)
		display.TextSize = 16
		display.TextTruncate = Enum.TextTruncate.AtEnd
		display.ZIndex = 17

		local arrow = image(button, icons.down, 14, theme.text3, 17)
		arrow.AnchorPoint = Vector2.new(1, .5)
		arrow.Position = UDim2.new(1, -10, .5, 0)

		local function selectedvalues()
			if not multiselect then
				return selected
			end

			local result = {}
			if includeeveryone and selected[everyonevalue] then
				result[#result + 1] = everyonevalue
			end
			for _, option in ipairs(options) do
				if selected[option] then
					result[#result + 1] = option
				end
			end
			for _, targetplayer in ipairs(players:GetPlayers()) do
				if targetplayer ~= player and selected[targetplayer] then
					result[#result + 1] = targetplayer
				end
			end
			return result
		end

		local function refreshdisplay()
			if multiselect then
				local values = selectedvalues()
				if #values == 0 then
					display.Text = "Select players"
					display.TextColor3 = theme.text2
					return
				end

				local names = {}
				for _, value in ipairs(values) do
					names[#names + 1] = typeof(value) == "Instance" and value:IsA("Player")
						and value.DisplayName
						or tostring(value)
				end
				display.Text = table.concat(names, ", ")
				display.TextColor3 = theme.text
				return
			end

			if typeof(selected) == "Instance" and selected:IsA("Player") then
				display.Text = selected.DisplayName
				display.TextColor3 = theme.text
			elseif selected ~= nil then
				display.Text = tostring(selected)
				display.TextColor3 = theme.text
			else
				display.Text = "Select player"
				display.TextColor3 = theme.text2
			end
		end

		local function fireselection()
			if callback then
				callback(selectedvalues())
			end
		end

		local function issel(value)
			return multiselect and selected[value] == true or selected == value
		end

		local function selectvalue(value, fire)
			if value == player then
				return
			end

			if multiselect then
				local nextstate = not selected[value]

				if value == everyonevalue and includeeveryone then
					if nextstate then
						for key in pairs(selected) do
							if typeof(key) == "Instance" and key:IsA("Player") then
								selected[key] = nil
							end
						end
						selected[value] = true
					else
						selected[value] = nil
					end
				elseif typeof(value) == "Instance" and value:IsA("Player") then
					selected[everyonevalue] = nil
					selected[value] = nextstate and true or nil
				else
					selected[value] = nextstate and true or nil
				end
			else
				selected = value
			end

			refreshdisplay()
			if fire ~= false then
				fireselection()
			end
		end

		refreshdisplay()

		button.MouseEnter:Connect(function()
			tween(display, {TextColor3 = theme.text}, hoverti)
			tween(arrow, {ImageColor3 = theme.text2}, hoverti)
		end)
		button.MouseLeave:Connect(function()
			refreshdisplay()
			tween(arrow, {ImageColor3 = theme.text3}, hoverti)
		end)

		button.Activated:Connect(function()
			if activepopup and activepopup.anchor == button then
				closepopup()
				return
			end

			local currentplayers = {}
			for _, targetplayer in ipairs(players:GetPlayers()) do
				if targetplayer ~= player then
					currentplayers[#currentplayers + 1] = targetplayer
				end
			end

			local totalitems = #options + #currentplayers + (includeeveryone and 1 or 0)
			local usesearch = searchable and totalitems >= 6
			local position = overlayposition(button)
			local size = button.AbsoluteSize
			local popupy = position.Y + size.Y + 6
			local dividerheight = ((#options > 0 or includeeveryone) and #currentplayers > 0) and 18 or 0
			local wanted = math.max(
				70,
				#options * 34
					+ #currentplayers * (uis.TouchEnabled and 64 or 56)
					+ (includeeveryone and (uis.TouchEnabled and 40 or 34) or 0)
					+ dividerheight
					+ (usesearch and 38 or 0)
					+ 8
			)
			local available = popuplayer.AbsoluteSize.Y - popupy - 8
			local height = math.max(70, math.min(wanted, math.min(330, available)))

			local panel, popup = createpopup(
				Vector2.new(position.X, popupy),
				size.X,
				height,
				510,
				"dropdown"
			)
			popup.anchor = button
			tween(arrow, {Rotation = 180}, tabti)
			popup.onclose = function()
				tween(arrow, {Rotation = 0}, tabti)
			end

			local searchheight = usesearch and 38 or 0
			local playersearch

			if usesearch then
				local searchframe = new("Frame", {
					Parent = panel,
					Position = UDim2.fromOffset(6, 6),
					Size = UDim2.new(1, -12, 0, 32),
					BackgroundColor3 = theme.input,
					BackgroundTransparency = .06,
					BorderSizePixel = 0,
					ClipsDescendants = true,
					ZIndex = 514,
				})
				corner(searchframe, 7)

				local searchicon = image(searchframe, icons.search, 17, theme.text3, 515)
				searchicon.AnchorPoint = Vector2.new(0, .5)
				searchicon.Position = UDim2.fromOffset(9, 16)

				playersearch = new("TextBox", {
					Parent = searchframe,
					Position = UDim2.fromOffset(33, 0),
					Size = UDim2.new(1, -41, 1, 0),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Text = "",
					PlaceholderText = "Search...",
					PlaceholderColor3 = theme.text3,
					TextColor3 = theme.text,
					Font = font,
					TextSize = 15,
					TextXAlignment = Enum.TextXAlignment.Left,
					ClearTextOnFocus = false,
					ZIndex = 515,
				})
			end

			local scroll = new("ScrollingFrame", {
				Parent = panel,
				Position = UDim2.fromOffset(6, 6 + searchheight),
				Size = UDim2.new(1, -12, 1, -12 - searchheight),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				CanvasSize = UDim2.new(),
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				ScrollBarThickness = 0,
				ScrollBarImageTransparency = .56,
				ScrollBarImageColor3 = theme.scroll,
				ZIndex = 512,
			})
			list(scroll, 2)
			binddropdownscrollbar(scroll, 2)

			local rows = {}

			local function makerow(value, textvalue, searchvalue, usernamevalue, playerrow)
				local rowheight = playerrow and (uis.TouchEnabled and 62 or 54) or (uis.TouchEnabled and 38 or 32)
				local row = new("TextButton", {
					Parent = scroll,
					Size = UDim2.new(1, 0, 0, rowheight),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Text = "",
					AutoButtonColor = false,
					ZIndex = 514,
				})

				local left = 9
				local playericon
				if playerrow and typeof(value) == "Instance" and value:IsA("Player") then
					playericon = rawnew("ImageLabel", {
						Parent = row,
						AnchorPoint = Vector2.new(0, .5),
						Position = UDim2.fromOffset(7, rowheight * .5),
						Size = UDim2.fromOffset(uis.TouchEnabled and 48 or 42, uis.TouchEnabled and 48 or 42),
						BackgroundTransparency = 1,
						BorderSizePixel = 0,
						Image = getplayerthumbnail(value),
						ScaleType = Enum.ScaleType.Crop,
						ZIndex = 515,
					})
					corner(playericon, 999)
					left = uis.TouchEnabled and 61 or 55
				end

				local rowlabel = label(
					row,
					textvalue,
					UDim2.new(1, -(left + 9), 0, playerrow and 20 or rowheight),
					playerrow and medium or font,
					issel(value) and theme.text or theme.text2
				)
				rowlabel.Position = UDim2.fromOffset(left, playerrow and (uis.TouchEnabled and 8 or 6) or 0)
				rowlabel.TextSize = playerrow and (uis.TouchEnabled and 17 or 16) or 16
				rowlabel.TextTruncate = Enum.TextTruncate.AtEnd
				rowlabel.ZIndex = 515

				local usernamelabel
				if playerrow then
					usernamelabel = label(
						row,
						"@" .. tostring(usernamevalue or ""),
						UDim2.new(1, -(left + 9), 0, 17),
						font,
						theme.text3
					)
					usernamelabel.Position = UDim2.fromOffset(left, uis.TouchEnabled and 34 or 29)
					usernamelabel.TextSize = uis.TouchEnabled and 14 or 13
					usernamelabel.TextTruncate = Enum.TextTruncate.AtEnd
					usernamelabel.ZIndex = 515
				end

				local data = {
					value = value,
					button = row,
					label = rowlabel,
					username = usernamelabel,
					icon = playericon,
					search = string.lower(searchvalue),
				}
				rows[#rows + 1] = data

				local function renderselected(animate)
					local selectednow = issel(value)
					local labelcolor = selectednow and theme.text or theme.text2
					if animate then
						tween(rowlabel, {TextColor3 = labelcolor}, hoverti)
					else
						rowlabel.TextColor3 = labelcolor
					end

				end

				row.MouseEnter:Connect(function()
					tween(rowlabel, {TextColor3 = theme.text}, hoverti)
					if usernamelabel then
						tween(usernamelabel, {TextColor3 = theme.text2}, hoverti)
					end
				end)

				row.MouseLeave:Connect(function()
					renderselected(true)
					if usernamelabel then
						tween(usernamelabel, {TextColor3 = theme.text3}, hoverti)
					end
				end)

				row.Activated:Connect(function()
					selectvalue(value, true)
					for _, rowdata in ipairs(rows) do
						local selectednow = issel(rowdata.value)
						tween(rowdata.label, {
							TextColor3 = selectednow and theme.text or theme.text2,
						}, hoverti)
					end
					if not multiselect then
						closepopup()
					end
				end)
			end

			if includeeveryone then
				makerow(
					everyonevalue,
					"Everyone",
					"everyone all players"
				)
			end

			for _, option in ipairs(options) do
				local divider = optiondividers[option]
				if divider ~= nil then
					local dividerrow = new("Frame", {
						Parent = scroll,
						Size = UDim2.new(1, 0, 0, (divider == true or divider == "") and 14 or 20),
						BackgroundTransparency = 1,
						BorderSizePixel = 0,
						ZIndex = 514,
					})
					if divider == true or divider == "" then
						local line = new("Frame", {
							Parent = dividerrow,
							AnchorPoint = Vector2.new(.5, .5),
							Position = UDim2.fromScale(.5, .5),
							Size = UDim2.new(1, -14, 0, 1),
							BackgroundColor3 = theme.border,
							BackgroundTransparency = .38,
							BorderSizePixel = 0,
							ZIndex = 515,
						})
						corner(line, 999)
					else
						local divlabel = label(dividerrow, plaintext(tostring(divider)), UDim2.new(1, -14, 1, 0), medium, theme.text3)
						divlabel.Position = UDim2.fromOffset(7, 0)
						divlabel.TextSize = 13
						divlabel.ZIndex = 515
					end
				end
				makerow(option, tostring(option), tostring(option))
			end

			local dividerrow
			if (#options > 0 or includeeveryone) and #currentplayers > 0 then
				dividerrow = new("Frame", {
					Parent = scroll,
					Size = UDim2.new(1, 0, 0, 24),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					ZIndex = 514,
				})

				if playersdivider and playersdivider ~= "" then
					local dividertext = plaintext(tostring(playersdivider))
					local bounds = measuretext(
						dividertext,
						15,
						medium,
						Vector2.new(240, 24)
					)
					local labelwidth = math.max(48, math.ceil(bounds.X) + 14)
					local halfgap = labelwidth * .5 + 8

					local leftline = new("Frame", {
						Parent = dividerrow,
						AnchorPoint = Vector2.new(0, .5),
						Position = UDim2.new(0, 7, .5, 0),
						Size = UDim2.new(.5, -(halfgap + 7), 0, 1),
						BackgroundColor3 = theme.border,
						BackgroundTransparency = .42,
						BorderSizePixel = 0,
						ZIndex = 515,
					})
					corner(leftline, 999)

					local rightline = new("Frame", {
						Parent = dividerrow,
						AnchorPoint = Vector2.new(1, .5),
						Position = UDim2.new(1, -7, .5, 0),
						Size = UDim2.new(.5, -(halfgap + 7), 0, 1),
						BackgroundColor3 = theme.border,
						BackgroundTransparency = .42,
						BorderSizePixel = 0,
						ZIndex = 515,
					})
					corner(rightline, 999)

					local divlabel = label(
						dividerrow,
						dividertext,
						UDim2.fromOffset(labelwidth, 24),
						medium,
						theme.text3
					)
					divlabel.AnchorPoint = Vector2.new(.5, .5)
					divlabel.Position = UDim2.fromScale(.5, .5)
					divlabel.TextSize = 15
					divlabel.TextXAlignment = Enum.TextXAlignment.Center
					divlabel.ZIndex = 516
				else
					local line = new("Frame", {
						Parent = dividerrow,
						AnchorPoint = Vector2.new(.5, .5),
						Position = UDim2.fromScale(.5, .5),
						Size = UDim2.new(1, -14, 0, 1),
						BackgroundColor3 = theme.border,
						BackgroundTransparency = .42,
						BorderSizePixel = 0,
						ZIndex = 515,
					})
					corner(line, 999)
				end
			end

			for _, targetplayer in ipairs(currentplayers) do
				makerow(
					targetplayer,
					targetplayer.DisplayName,
					targetplayer.DisplayName .. " " .. targetplayer.Name,
					targetplayer.Name,
					true
				)
			end

			if totalitems == 0 then
				local empty = label(scroll, "No players", UDim2.new(1, 0, 0, 38), font, theme.text3)
				empty.TextSize = 14
				empty.TextXAlignment = Enum.TextXAlignment.Center
			end

			if playersearch then
				playersearch:GetPropertyChangedSignal("Text"):Connect(function()
					local query = string.lower(plaintext(playersearch.Text))
					for _, data in ipairs(rows) do
						data.button.Visible = query == "" or string.find(data.search, query, 1, true) ~= nil
					end
					if dividerrow then
						dividerrow.Visible = query == ""
					end
				end)

				if not uis.TouchEnabled
					and playersearch
					and playersearch.Parent
				then
					playersearch:CaptureFocus()
				end
			end
		end)

		register(holder, name)

		return {
			Get = function()
				return selectedvalues()
			end,
			Set = function(_, value, fire)
				if multiselect then
					table.clear(selected)
					for _, entry in ipairs(type(value) == "table" and value or {}) do
						if entry ~= player then
							selected[entry] = true
						end
					end
				else
					selected = value == player and nil or value
				end
				refreshdisplay()
				if fire ~= false then
					fireselection()
				end
			end,
			SetOptions = function(_, newoptions)
				options = newoptions or {}
				refreshdisplay()
			end,
			Multi = multiselect,
			Object = holder,
			TextObject = title,
		}
	end

	function section:AddMultiPlayerDropdown(
		name,
		default,
		callback,
		target,
		config
	)
		config = table.clone(config or {})
		config.multiselect = true
		return self:AddPlayerDropdown(
			name,
			{},
			default or {},
			callback,
			target,
			config
		)
	end

	-- multiselect

	function section:AddMultiDropdown(
		name,
		options,
		default,
		callback,
		target
	)
		local parentobject =
			target or body

		local selected = {}

		for _, option in ipairs(
			default or {}
		) do
			selected[option] =
				true
		end

		local holder = new("Frame", {
			Parent = parentobject,

			Size =
				UDim2.new(
					1,
					0,
					0,
					57
				),

			BackgroundTransparency = 1,

			ZIndex = 15,
		})

		local title =
			label(
				holder,
				name,
				UDim2.new(
					1,
					0,
					0,
					18
				),
				font
			)

		title.TextSize = 17

		local button = new("TextButton", {
			Parent = holder,

			Position =
				UDim2.fromOffset(
					0,
					25
				),

			Size =
				UDim2.new(
					1,
					0,
					0,
					32
				),

			BackgroundColor3 =
				theme.input,

			BorderSizePixel = 0,

			Text = "",
			AutoButtonColor = false,

			ZIndex = 16,
		})

		corner(button, 7)

		local valuetext =
			label(
				button,
				"",
				UDim2.new(
					1,
					-38,
					1,
					0
				),
				font
			)

		valuetext.Position =
			UDim2.fromOffset(
				10,
				0
			)

		valuetext.TextSize = 17

		valuetext.TextTruncate =
			Enum.TextTruncate.AtEnd

		valuetext.ZIndex = 17

		local arrow =
			image(
				button,
				icons.down,
				14,
				theme.text3,
				17
			)

		arrow.AnchorPoint =
			Vector2.new(
				1,
				.5
			)

		arrow.Position =
			UDim2.new(
				1,
				-10,
				.5,
				0
			)


		button.MouseEnter:Connect(function()
			tween(valuetext, {TextColor3 = theme.text}, hoverti)
			tween(arrow, {ImageColor3 = theme.text2}, hoverti)
		end)
		button.MouseLeave:Connect(function()
			tween(valuetext, {TextColor3 = theme.text2}, hoverti)
			tween(arrow, {ImageColor3 = theme.text3}, hoverti)
		end)

		local function getselected()
			local result = {}

			for _, option in ipairs(
				options
			) do
				if selected[option] then
					table.insert(
						result,
						option
					)
				end
			end

			return result
		end

		local function refresh(fire)
			local values =
				getselected()

			valuetext.Text =
				#values > 0
				and table.concat(
					values,
					", "
				)
				or "None"

			if fire
				and callback
			then
				callback(values)
			end
		end

		button.Activated:Connect(function()
			local panel, popup =
				dropdownpopup(
					button,
					#options
				)

			if not panel or not popup then
				return
			end

			tween(
				arrow,
				{
					Rotation = 180,
				},
				tabti
			)

			popup.onclose =
				function()
					tween(
						arrow,
						{
							Rotation = 0,
						},
						tabti
					)
				end

			local scroll =
				new("ScrollingFrame", {
					Parent = panel,

					Position =
						UDim2.fromOffset(
							4,
							4
						),

					Size =
						UDim2.new(
							1,
							-8,
							1,
							-8
						),

					BackgroundTransparency =
						1,

					BorderSizePixel = 0,

					CanvasSize =
						UDim2.new(),

					AutomaticCanvasSize =
						Enum.AutomaticSize.Y,

					ScrollBarThickness = 0,

					ScrollBarImageTransparency =
						.56,

					ScrollBarImageColor3 =
						theme.scroll,

					ZIndex = 512,
				})

			list(
				scroll,
				2
			)
			binddropdownscrollbar(scroll, 2)

			for _, option in ipairs(
				options
			) do
				local row =
					new("TextButton", {
						Parent = scroll,

						Size =
							UDim2.new(
								1,
								0,
								0,
								32
							),

						BackgroundColor3 =
							theme.hover,

						BackgroundTransparency =
							1,

						BorderSizePixel =
							0,

						Text = "",

						AutoButtonColor =
							false,

						ZIndex = 514,
					})

				corner(
					row,
					6
				)

				local textobject =
					label(
						row,
						option,
						UDim2.new(
							1,
							-34,
							1,
							0
						),
						font,
						theme.text2
					)

				textobject.Position =
					UDim2.fromOffset(
						9,
						0
					)

				textobject.TextSize = 15
				textobject.ZIndex = 515

				local check =
					image(
						row,
						icons.check,
						13,
						theme.text2,
						516
					)

				check.AnchorPoint =
					Vector2.new(
						1,
						.5
					)

				check.Position =
					UDim2.new(
						1,
						-9,
						.5,
						0
					)

				check.ImageTransparency =
					selected[option]
					and 0
					or 1

				row.MouseEnter:Connect(function()
					tween(textobject, {TextColor3 = theme.text}, hoverti)
				end)

				row.MouseLeave:Connect(function()
					tween(textobject, {
						TextColor3 = selected[option] and theme.text or theme.text2,
					}, hoverti)
				end)

				row.Activated:Connect(function()
					if selected[option] then
						selected[option] = nil
					else
						selected[option] = true
					end

					tween(
						textobject,
						{TextColor3 = selected[option] and theme.text or theme.text2},
						fastti
					)

					tween(
						check,
						{
							ImageTransparency =
								selected[option]
								and 0
								or 1,
						},
						fastti
					)

					refresh(true)
				end)
			end
		end)

		refresh(false)

		register(
			holder,
			name
		)

		return {
			Get = function()
				return getselected()
			end,
			Set = function(_, values, fire)
				table.clear(selected)
				for _, option in ipairs(values or {}) do
					if table.find(options, option) then
						selected[option] = true
					end
				end
				refresh(fire ~= false)
			end,
			SetOptions = function(_, values)
				options = values or {}
				for option in pairs(selected) do
					if not table.find(options, option) then
						selected[option] = nil
					end
				end
				refresh(false)
			end,
			Object = holder,
			TextObject = title,
		}
	end

	-- input

	function section:AddInput(
		name,
		default,
		placeholder,
		callback,
		target
	)
		local parentobject = target or body

		local holder = new("Frame", {
			Parent = parentobject,
			Size = UDim2.new(1, 0, 0, 57),
			BackgroundTransparency = 1,
			ZIndex = 15,
		})

		local title = label(
			holder,
			name,
			UDim2.new(1, 0, 0, 18),
			font
		)
		title.TextSize = 17

		local field = new("ScrollingFrame", {
			Parent = holder,
			Position = UDim2.fromOffset(0, 25),
			Size = UDim2.new(1, 0, 0, 32),
			BackgroundColor3 = theme.input,
			BorderSizePixel = 0,
			CanvasSize = UDim2.fromOffset(0, 0),
			CanvasPosition = Vector2.zero,
			ScrollBarThickness = 0,
			ScrollingDirection = Enum.ScrollingDirection.X,
			ElasticBehavior = Enum.ElasticBehavior.Never,
			ClipsDescendants = true,
			ZIndex = 16,
		})
		corner(field, 7)

		local box = new("TextBox", {
			Parent = field,
			Position = UDim2.fromOffset(10, 0),
			Size = UDim2.new(1, -20, 1, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Text = tostring(default or ""),
			PlaceholderText = placeholder or "",
			PlaceholderColor3 = theme.text3,
			TextColor3 = theme.text2,
			Font = font,
			TextSize = 17,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
			TextWrapped = false,
			ClearTextOnFocus = false,
			MultiLine = false,
			ZIndex = 17,
		})

		local focused = false
		local updating = false

		local function settruncate(value)
			invoke(function()
				box.TextTruncate = value
			end)
		end

		local function measure(value)
			return measuretext(
				tostring(value or ""),
				box.TextSize,
				box.Font,
				Vector2.new(100000, 32)
			).X
		end

		local function updateinputviewport(keepcursor)
			if updating or not field.Parent or not box.Parent then
				return
			end
			updating = true

			local viewport = math.max(0, field.AbsoluteSize.X - 20)

			if focused then
				local fullwidth = math.max(viewport, math.ceil(measure(box.Text)) + 4)
				box.Size = UDim2.fromOffset(fullwidth, 32)
				field.CanvasSize = UDim2.fromOffset(fullwidth + 20, 0)

				if keepcursor ~= false then
					local cursor = box.CursorPosition
					if cursor < 1 then
						cursor = #box.Text + 1
					end

					local prefix = box.Text:sub(1, math.max(0, cursor - 1))
					local cursorx = measure(prefix)
					local current = field.CanvasPosition.X
					local left = current + 6
					local right = current + viewport - 12
					local target = current

					if cursorx > right then
						target = cursorx - viewport + 18
					elseif cursorx < left then
						target = math.max(0, cursorx - 8)
					end

					local maximum = math.max(0, fullwidth - viewport)
					field.CanvasPosition = Vector2.new(
						math.clamp(target, 0, maximum),
						0
					)
				end
			else
				box.Size = UDim2.new(1, -20, 1, 0)
				field.CanvasSize = UDim2.fromOffset(0, 0)
				field.CanvasPosition = Vector2.zero
			end

			updating = false
		end

		settruncate(Enum.TextTruncate.AtEnd)

		box.Focused:Connect(function()
			focused = true
			settruncate(Enum.TextTruncate.None)
			tween(box, { TextColor3 = theme.text }, hoverti)
			updateinputviewport(true)
		end)

		box:GetPropertyChangedSignal("Text"):Connect(function()
			if focused then
				updateinputviewport(true)
			end
		end)

		box:GetPropertyChangedSignal("CursorPosition"):Connect(function()
			if focused then
				updateinputviewport(true)
			end
		end)

		field:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			updateinputviewport(focused)
		end)

		field.MouseEnter:Connect(function()
			tween(box, { TextColor3 = theme.text }, hoverti)
		end)

		field.MouseLeave:Connect(function()
			if not focused then
				tween(box, { TextColor3 = theme.text2 }, hoverti)
			end
		end)

		box.FocusLost:Connect(function()
			focused = false
			settruncate(Enum.TextTruncate.AtEnd)
			updateinputviewport(false)
			tween(box, { TextColor3 = theme.text2 }, hoverti)

			if callback then
				callback(box.Text)
			end
		end)

		register(holder, name)
		return box
	end

	-- key picker

	function section:AddKeyPicker(
		name,
		defaultkey,
		callback,
		target
	)
		if uis.TouchEnabled then
			local selected = defaultkey or Enum.KeyCode.RightShift

			return {
				Get = function()
					return selected
				end,

				Set = function(_, key, fire)
					if typeof(key) == "string" then
						key = keyfromname(key)
					end

					if typeof(key) == "EnumItem" then
						selected = key
						if fire ~= false and callback then
							callback(selected)
						end
					end
				end,

				Object = nil,
			}
		end

		local parentobject =
			target or body

		local row = new("Frame", {
			Parent = parentobject,

			Size =
				UDim2.new(
					1,
					0,
					0,
					29
				),

			BackgroundTransparency = 1,
			ZIndex = 15,
		})

		local title =
			label(
				row,
				name,
				UDim2.new(
					1,
					-68,
					1,
					0
				),
				font
			)

		title.TextSize = 17

		local button = new("TextButton", {
			Parent = row,

			AnchorPoint =
				Vector2.new(
					1,
					.5
				),

			Position =
				UDim2.new(
					1,
					0,
					.5,
					0
				),

			Size =
				UDim2.fromOffset(
					56,
					25
				),

			BackgroundColor3 = theme.input,
			BackgroundTransparency = .08,
			BorderSizePixel = 0,

			Text = "",
			AutoButtonColor = false,
			ZIndex = 16,
		})

		corner(button, 6)
		local keystroke =
			stroke(
				button,
				.7,
				theme.border,
				.6
			)

		local keytext =
			label(
				button,
				"",
				UDim2.fromScale(1, 1),
				medium,
				theme.text2
			)

		keytext.TextSize = 14
		keytext.TextXAlignment =
			Enum.TextXAlignment.Center
		keytext.ZIndex = 17

		local selected =
			defaultkey or Enum.KeyCode.RightShift

		local listening = false

		local function keyname(key)
			return togglekeyname(key)
		end

		local function render()
			local value =
				listening
				and "..."
				or keyname(selected)

			keytext.Text = value

			local bounds =
				measuretext(
					value,
					14,
					medium,
					Vector2.new(
						200,
						25
					)
				)

			local singlecharacter =
				#plaintext(value) == 1

			local width =
				math.clamp(
					math.ceil(bounds.X)
						+ (singlecharacter and 14 or 20),
					singlecharacter and 30 or 42,
					112
				)

			tween(
				button,
				{
					Size =
						UDim2.fromOffset(
							width,
							25
						),
				},
				fastti
			)

			title.Size =
				UDim2.new(
					1,
					-width - 12,
					1,
					0
				)

			tween(
				keystroke,
				{
					Color = theme.border,
					Transparency =
						listening
						and .42
						or .7,
				},
				fastti
			)
		end

		local function setkey(key, fire)
			if key == nil then
				selected = nil
				render()
				if fire ~= false and callback then
					callback(nil)
				end
				return
			end

			if typeof(key) == "string" then
				key = keyfromname(key)
			end

			if typeof(key) ~= "EnumItem" then
				return
			end

			local valid =
				key.EnumType == Enum.KeyCode
				or (
					key.EnumType == Enum.UserInputType
					and validmousebind(key)
				)

			if not valid then
				return
			end

			selected = key
			render()

			if fire ~= false and callback then
				callback(key)
			end
		end

		button.MouseEnter:Connect(function()
			tween(keytext, {TextColor3 = theme.text}, hoverti)
		end)

		button.MouseLeave:Connect(function()
			tween(keytext, {TextColor3 = theme.text2}, hoverti)
		end)

		button.Activated:Connect(function()
			if listening then
				listening = false
				endkeycapture(row, nil)
				render()
				return
			end

			listening = true

			if not beginkeycapture(
				row,
				function()
					listening = false
					render()
				end,
				function(selectedkey)
					listening = false
					setkey(selectedkey, true)
				end,
				function(input)
					return input.UserInputType == Enum.UserInputType.MouseButton1
						and inside(button, point(input))
				end
			) then
				listening = false
			end

			render()
		end)

		connect(
			row.Destroying,
			function()
				if listening then
					listening = false
					endkeycapture(row, nil)
				end
			end
		)

		render()

		register(
			row,
			name
		)

		return {
			Get = function()
				return selected
			end,

			Set = function(_, key, fire)
				setkey(key, fire)
			end,
			Object = row,
			TextObject = title,
		}
	end

	-- standalone color

	function section:AddColorPicker(
		name,
		color,
		callback,
		target
	)
		local parentobject =
			target or body

		local row = new("Frame", {
			Parent = parentobject,

			Size =
				UDim2.new(
					1,
					0,
					0,
					27
				),

			BackgroundTransparency = 1,

			ZIndex = 15,
		})

		local title =
			label(
				row,
				name,
				UDim2.new(
					1,
					-38,
					1,
					0
				),
				font
			)

		title.TextSize = 17

		local button =
			new("TextButton", {
				Parent = row,

				AnchorPoint =
					Vector2.new(
						1,
						.5
					),

				Position =
					UDim2.new(
						1,
						0,
						.5,
						0
					),

				Size =
					UDim2.fromOffset(
						22,
						22
					),

				BackgroundTransparency =
					1,

				BorderSizePixel = 0,

				Text = "",

				AutoButtonColor =
					false,

				ZIndex = 16,
			})

		local swatch =
			new("Frame", {
				Parent = button,

				Size =
					UDim2.fromScale(
						1,
						1
					),

				BackgroundColor3 =
					color,

				BorderSizePixel = 0,

				ZIndex = 17,
			})

		corner(
			swatch,
			5
		)

		local swatchglow =
			addshadow(
				swatch,
				"ColorGlow",
				.62,
				7,
				1,
				-1,
				color,
				UDim2.fromOffset(0, 0),
				false
			)

		local state =
			createcolorstate(
				color,
				callback,
				swatch
			)

		state.swatchglow = swatchglow
		state:apply()

		button.Activated:Connect(function()
			opencolorpicker(
				button,
				state
			)
		end)

		register(
			row,
			name
		)

		state.Object = row
		state.TextObject = title
		return state
	end

	-- divider / separator

	function section:AddDivider(textvalue, target)
		local parentobject = target or body
		local hastext = textvalue ~= nil and tostring(textvalue) ~= ""
		local holder = new("Frame", {
			Parent = parentobject,
			Size = UDim2.new(1, 0, 0, hastext and 24 or 10),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = 15,
		})

		if hastext then
			local textobject = label(holder, tostring(textvalue), UDim2.fromOffset(110, 24), medium, theme.text3)
			textobject.AnchorPoint = Vector2.new(.5, .5)
			textobject.Position = UDim2.fromScale(.5, .5)
			textobject.TextSize = 14
			textobject.TextXAlignment = Enum.TextXAlignment.Center
			textobject.ZIndex = 16

			local leftline = new("Frame", {
				Parent = holder,
				AnchorPoint = Vector2.new(0, .5),
				Position = UDim2.new(0, 0, .5, 0),
				Size = UDim2.new(.5, -62, 0, 1),
				BackgroundColor3 = theme.border,
				BackgroundTransparency = .48,
				BorderSizePixel = 0,
				ZIndex = 15,
			})
			local rightline = new("Frame", {
				Parent = holder,
				AnchorPoint = Vector2.new(1, .5),
				Position = UDim2.new(1, 0, .5, 0),
				Size = UDim2.new(.5, -62, 0, 1),
				BackgroundColor3 = theme.border,
				BackgroundTransparency = .48,
				BorderSizePixel = 0,
				ZIndex = 15,
			})
			corner(leftline, 999)
			corner(rightline, 999)
		else
			local line = new("Frame", {
				Parent = holder,
				AnchorPoint = Vector2.new(.5, .5),
				Position = UDim2.fromScale(.5, .5),
				Size = UDim2.new(1, 0, 0, 1),
				BackgroundColor3 = theme.border,
				BackgroundTransparency = .48,
				BorderSizePixel = 0,
				ZIndex = 15,
			})
			corner(line, 999)
		end

		register(holder, textvalue or "separator")
		return holder
	end

	function section:AddSeparator(target)
		return self:AddDivider(nil, target)
	end

	-- progress bar

	function section:AddProgressBar(name, default, suffix, target)
		local parentobject = target or body
		local holder = new("Frame", {
			Parent = parentobject,
			Size = UDim2.new(1, 0, 0, 43),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = 15,
		})

		local titleobject = label(holder, name, UDim2.new(1, -80, 0, 19), font, theme.text2)
		titleobject.TextSize = 16
		local valueobject = label(holder, "", UDim2.fromOffset(76, 19), medium, theme.text3)
		valueobject.AnchorPoint = Vector2.new(1, 0)
		valueobject.Position = UDim2.new(1, 0, 0, 0)
		valueobject.TextXAlignment = Enum.TextXAlignment.Right
		valueobject.TextSize = 15

		local track = new("Frame", {
			Parent = holder,
			Position = UDim2.fromOffset(0, 30),
			Size = UDim2.new(1, 0, 0, 6),
			BackgroundColor3 = theme.track,
			BorderSizePixel = 0,
			ZIndex = 16,
		})
		corner(track, 999)

		local fill = new("Frame", {
			Parent = track,
			Size = UDim2.fromScale(0, 1),
			BackgroundColor3 = theme.white,
			BorderSizePixel = 0,
			ZIndex = 17,
		})
		corner(fill, 999)
		local glow = addglow(fill, "active")
		if glow then glow.Transparency = .7 end

		local value = 0
		local function set(number)
			value = math.clamp(tonumber(number) or 0, 0, 100)
			fill.Size = UDim2.fromScale(value / 100, 1)
			valueobject.Text = tostring(math.round(value)) .. (suffix or "%")
		end
		set(default or 0)
		register(holder, name)

		return {
			Get = function() return value end,
			Set = function(_, number) set(number) end,
			Object = holder,
			TextObject = titleobject,
		}
	end


	-- radio

	function section:AddRadio(name, options, default, callback, target)
		local parentobject = target or body
		local holder = new("Frame", {
			Parent = parentobject,
			Size = UDim2.new(1, 0, 0, 53),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = 15,
		})

		local titleobject = label(holder, name, UDim2.new(1, 0, 0, 18), font, theme.text2)
		titleobject.TextSize = 16

		local row = new("Frame", {
			Parent = holder,
			Position = UDim2.fromOffset(0, 24),
			Size = UDim2.new(1, 0, 0, 29),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = 16,
		})

		new("UIListLayout", {
			Parent = row,
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 8),
			SortOrder = Enum.SortOrder.LayoutOrder,
		})

		options = options or {}

		local buttons = {}
		local selected = default or options[1]

		local function render()
			for value, data in pairs(buttons) do
				local active = value == selected
				data.text.TextColor3 =
					active and theme.text or theme.text3

				tween(
					data.dot,
					{
						BackgroundTransparency = active and 0 or 1,
						Size = active
							and UDim2.fromOffset(8, 8)
							or UDim2.fromOffset(3, 3),
					},
					fastti
				)
			end
		end

		for index, option in ipairs(options or {}) do
			local button = new("TextButton", {
				Parent = row,
				LayoutOrder = index,
				Size = UDim2.new(1 / math.max(1, #options), -6, 1, 0),
				BackgroundColor3 = theme.hover,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Text = "",
				AutoButtonColor = false,
				ZIndex = 16,
			})
			corner(button, 6)

			local optiontext = tostring(option)
			local optionbounds = measuretext(
				plaintext(optiontext),
				14,
				font,
				Vector2.new(240, 29)
			)
			local contentwidth = 26 + math.ceil(optionbounds.X)

			local contentgroup = new("Frame", {
				Parent = button,
				AnchorPoint = Vector2.new(.5, .5),
				Position = UDim2.fromScale(.5, .5),
				Size = UDim2.fromOffset(contentwidth, 29),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ZIndex = 17,
			})

			local circle = new("Frame", {
				Parent = contentgroup,
				AnchorPoint = Vector2.new(0, .5),
				Position = UDim2.new(0, 0, .5, 0),
				Size = UDim2.fromOffset(16, 16),
				BackgroundColor3 = theme.input,
				BorderSizePixel = 0,
				ZIndex = 17,
			})
			corner(circle, 999)
			stroke(circle, .46, theme.border, .7)

			local dot = new("Frame", {
				Parent = circle,
				AnchorPoint = Vector2.new(.5, .5),
				Position = UDim2.fromScale(.5, .5),
				Size = UDim2.fromOffset(3, 3),
				BackgroundColor3 = theme.white,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ZIndex = 18,
			})
			corner(dot, 999)

			local textobject = label(
				contentgroup,
				optiontext,
				UDim2.fromOffset(math.ceil(optionbounds.X) + 2, 29),
				font,
				theme.text3
			)
			textobject.Position = UDim2.fromOffset(24, 0)
			textobject.TextSize = 14
			textobject.ZIndex = 17

			buttons[option] = {
				button = button,
				dot = dot,
				text = textobject,
			}

			button.MouseEnter:Connect(function()
				tween(textobject, {TextColor3 = theme.text}, hoverti)
			end)
			button.MouseLeave:Connect(function()
				tween(textobject, {
					TextColor3 = selected == option and theme.text or theme.text3,
				}, hoverti)
			end)
			button.Activated:Connect(function()
				selected = option
				render()
				if callback then
					callback(option)
				end
			end)
		end

		render()
		register(holder, name)

		return {
			Get = function()
				return selected
			end,
			Set = function(_, value, fire)
				if buttons[value] then
					selected = value
					render()
					if fire ~= false and callback then
						callback(value)
					end
				end
			end,
			Object = holder,
			TextObject = titleobject,
		}
	end

	-- badge / status

	function section:AddBadge(name, textvalue, color, target)
		local parentobject = target or body
		local statuscolor = color or theme.text2

		local holder = new("Frame", {
			Parent = parentobject,
			Size = UDim2.new(1, 0, 0, 31),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = 15,
		})

		local titleobject = label(
			holder,
			name,
			UDim2.new(1, -126, 1, 0),
			font,
			theme.text2
		)
		titleobject.TextSize = 16
		titleobject.TextTruncate = Enum.TextTruncate.AtEnd
		titleobject.ZIndex = 16

		local badge = new("Frame", {
			Parent = holder,
			AnchorPoint = Vector2.new(1, .5),
			Position = UDim2.new(1, 0, .5, 0),
			Size = UDim2.fromOffset(94, 25),
			BackgroundColor3 = theme.input,
			BackgroundTransparency = .06,
			BorderSizePixel = 0,
			ZIndex = 16,
		})

		bindtheme(
			badge,
			"BackgroundColor3",
			theme.input
		)

		corner(badge, 999)

		local badgestroke = stroke(
			badge,
			.76,
			statuscolor,
			.7
		)

		local dot = new("Frame", {
			Parent = badge,
			AnchorPoint = Vector2.new(0, .5),
			Position = UDim2.fromOffset(10, 12.5),
			Size = UDim2.fromOffset(6, 6),
			BackgroundColor3 = statuscolor,
			BackgroundTransparency = 0,
			BorderSizePixel = 0,
			ZIndex = 17,
		})
		corner(dot, 999)

		local dotglow = addshadow(
			dot,
			"StatusGlow",
			.68,
			6,
			0,
			-1,
			statuscolor,
			UDim2.fromOffset(0, 0),
			false
		)

		local textobject = label(
			badge,
			textvalue or "Ready",
			UDim2.new(1, -24, 1, 0),
			medium,
			theme.text
		)

		textobject.Position = UDim2.fromOffset(21, 0)
		textobject.TextXAlignment = Enum.TextXAlignment.Center
		textobject.TextSize = 15
		textobject.TextTruncate = Enum.TextTruncate.AtEnd
		textobject.ZIndex = 17

		local function resizebadge()
			local value = tostring(textobject.Text or "")
			local bounds = measuretext(
				value,
				15,
				medium,
				Vector2.new(220, 25)
			)

			local width = math.clamp(
				math.ceil(bounds.X) + 36,
				82,
				132
			)

			badge.Size = UDim2.fromOffset(
				width,
				25
			)

			titleobject.Size = UDim2.new(
				1,
				-width - 12,
				1,
				0
			)
		end

		resizebadge()

		register(
			holder,
			name .. " " .. tostring(textvalue or "")
		)

		return {
			SetText = function(_, value)
				textobject.Text = tostring(value)
				resizebadge()
			end,

			SetColor = function(_, value)
				statuscolor = value
				dot.BackgroundColor3 = value
				badgestroke.Color = value

				if dotglow then
					dotglow.Color = value
				end
			end,

			Object = holder,
			Badge = badge,
			TextObject = textobject,
			Dot = dot,
		}
	end

	-- image

	function section:AddImage(name, asset, height, target)
		local parentobject = target or body
		local hasname = name ~= nil and tostring(name) ~= ""
		local imageheight = tonumber(height) or 92
		local holder = new("Frame", {
			Parent = parentobject,
			Size = UDim2.new(1, 0, 0, imageheight + (hasname and 24 or 0)),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = 15,
		})
		if hasname then
			local titleobject = label(holder, tostring(name), UDim2.new(1, 0, 0, 18), font, theme.text2)
			titleobject.TextSize = 16
		end
		local imageobject = new("ImageLabel", {
			Parent = holder,
			Position = UDim2.fromOffset(0, hasname and 24 or 0),
			Size = UDim2.new(1, 0, 0, imageheight),
			BackgroundColor3 = theme.input,
			BackgroundTransparency = .1,
			BorderSizePixel = 0,
			Image = asset or "",
			ScaleType = Enum.ScaleType.Fit,
			ZIndex = 16,
		})
		corner(imageobject, 8)
		register(holder, name or "image")
		return imageobject
	end

	-- avatar

	function section:AddAvatar(name, source, target)
		local parentobject = target or body
		local sourceplayer = typeof(source) == "Instance" and source:IsA("Player") and source or nil
		local userid = sourceplayer and sourceplayer.UserId or tonumber(source) or player.UserId
		local display = sourceplayer and sourceplayer.DisplayName or tostring(name or "Avatar")
		local username = sourceplayer and ("@" .. sourceplayer.Name) or ("User " .. tostring(userid))
		local holder = new("Frame", {
			Parent = parentobject,
			Size = UDim2.new(1, 0, 0, 50),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = 15,
		})
		local avatar = rawnew("ImageLabel", {
			Parent = holder,
			AnchorPoint = Vector2.new(0, .5),
			Position = UDim2.new(0, 0, .5, 0),
			Size = UDim2.fromOffset(40, 40),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Image = string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150", userid),
			ZIndex = 16,
		})
		corner(avatar, 10)
		local nameobject = label(holder, display, UDim2.new(1, -50, 0, 20), medium, theme.text)
		nameobject.Position = UDim2.fromOffset(50, 4)
		nameobject.TextSize = 15
		nameobject.ZIndex = 16
		local userobject = label(holder, username, UDim2.new(1, -50, 0, 18), font, theme.text3)
		userobject.Position = UDim2.fromOffset(50, 25)
		userobject.TextSize = 14
		userobject.ZIndex = 16
		register(holder, name or display)
		return holder
	end


	-- loading spinner

	function section:AddLoadingSpinner(name, target)
		local parentobject = target or body
		local holder = new("Frame", {
			Parent = parentobject,
			Size = UDim2.new(1, 0, 0, 28),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = 15,
		})
		local titleobject = label(holder, name, UDim2.new(1, -30, 1, 0), font, theme.text2)
		titleobject.TextSize = 16
		local spinner = image(holder, icons.settings, 18, theme.text2, 16)
		spinner.AnchorPoint = Vector2.new(.5, .5)
		spinner.Position = UDim2.new(1, -10, .5, 0)
		registeranimatedui(spinner, "spinner")

		register(holder, name)
		return spinner
	end

	-- loading bar

	function section:AddLoadingBar(name, target)
		local parentobject = target or body
		local holder = new("Frame", {
			Parent = parentobject,
			Size = UDim2.new(1, 0, 0, 42),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = 15,
		})
		local titleobject = label(holder, name, UDim2.new(1, 0, 0, 18), font, theme.text2)
		titleobject.TextSize = 16
		local track = new("Frame", {
			Parent = holder,
			Position = UDim2.fromOffset(0, 29),
			Size = UDim2.new(1, 0, 0, 6),
			BackgroundColor3 = theme.track,
			BorderSizePixel = 0,
			ClipsDescendants = true,
			ZIndex = 16,
		})
		corner(track, 999)
		local bar = new("Frame", {
			Parent = track,
			Position = UDim2.new(-.28, 0, 0, 0),
			Size = UDim2.new(.28, 0, 1, 0),
			BackgroundColor3 = theme.white,
			BorderSizePixel = 0,
			ZIndex = 17,
		})
		corner(bar, 999)
		registeranimatedui(bar, "bar")

		register(holder, name)
		return bar
	end

	-- context / modal helpers

	function section:AddContextMenu(name, entries, target)
		local button = self:AddButton(name, nil, target)
		attachcontextmenu(button, entries)
		return button
	end

	function section:AddConfirmButton(name, titletext, bodytext, callback, target)
		return self:AddButton(name, function()
			confirmdialog(titletext, bodytext, callback)
		end, target)
	end

	function section:AddModalButton(name, titletext, bodytext, target)
		return self:AddButton(name, function()
			showmodal(titletext, bodytext, { { Text = "Close" } })
		end, target)
	end

	function section:AddButtonGroup(buttons, target)
		local row = self:AddRow(8, 32, target)
		for _, data in ipairs(buttons or {}) do
			if type(data) == "table" then
				row:AddButton(data.Text or data.Name or "Button", data.Callback)
			else
				row:AddButton(tostring(data))
			end
		end
		return row
	end

	-- section tabs

	function section:AddSubTabs(names)
		local barheight = 32
		local contentoffset = 39
		local sidepadding = 2
		local wheelstep = 75
		local scrollti = TweenInfo.new(
			.28,
			Enum.EasingStyle.Quart,
			Enum.EasingDirection.Out
		)
		local taborder = table.clone(names)
		local tabsclosed = false
		local tabscroll
		local tabdrag

		local host = new("Frame", {
			Parent = body,

			Size =
				UDim2.new(
					1,
					0,
					0,
					barheight
				),

			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ClipsDescendants = false,
			Active = true,

			ZIndex = 15,
		})

		local tabviewport = new("Frame", {
			Parent = host,

			Size =
				UDim2.new(
					1,
					0,
					0,
					barheight
				),

			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ClipsDescendants = true,
			Active = true,

			ZIndex = 16,
		})

		local tabcontent = new("Frame", {
			Parent = tabviewport,

			Position =
				UDim2.fromOffset(
					0,
					0
				),

			Size =
				UDim2.fromOffset(
					0,
					30
				),

			BackgroundTransparency = 1,
			BorderSizePixel = 0,

			ZIndex = 16,
		})

		padding(
			tabcontent,
			sidepadding,
			sidepadding
		)

		local tablayout = new("UIListLayout", {
			Parent = tabcontent,

			FillDirection =
				Enum.FillDirection.Horizontal,

			VerticalAlignment =
				Enum.VerticalAlignment.Center,

			HorizontalAlignment =
				Enum.HorizontalAlignment.Left,

			Padding =
				UDim.new(
					0,
					8
				),

			SortOrder =
				Enum.SortOrder.LayoutOrder,
		})

		local scrollbartrack = new("Frame", {
			Parent = host,

			AnchorPoint =
				Vector2.new(
					.5,
					0
				),

			Position =
				UDim2.new(
					.5,
					0,
					0,
					barheight - 4
				),

			Size =
				UDim2.new(
					1,
					-12,
					0,
					1
				),

			BackgroundColor3 =
				theme.scrollTrack,

			BackgroundTransparency = 1,
			BorderSizePixel = 0,

			ZIndex = 18,
		})

		corner(
			scrollbartrack,
			999
		)

		local scrollbarthumb = new("Frame", {
			Parent = scrollbartrack,

			Position =
				UDim2.fromOffset(
					0,
					0
				),

			Size =
				UDim2.fromOffset(
					20,
					1
				),

			BackgroundColor3 =
				theme.scroll,

			BackgroundTransparency = .32,
			BorderSizePixel = 0,
			Visible = false,

			ZIndex = 19,
		})

		corner(
			scrollbarthumb,
			999
		)

		local containers = {}
		local buttons = {}

		local selected
		local overflow = false
		local scrollx = 0
		local scrolltarget = 0
		local contentwidth = 0
		local scrollanimation

		local scrollvalue = new("NumberValue", {
			Parent = host,
			Value = 0,
		})

		local function resizehost(animate)
			local container = selected and containers[selected]

			if uis.TouchEnabled then
				local containerheight = container
					and container.Size.Y.Offset
					or 0

				local height = tabsclosed
					and barheight
					or contentoffset + containerheight + 10

				host.Size = UDim2.new(1, 0, 0, height)
				host.ClipsDescendants = tabsclosed

				if section.RefreshMobileLayout then
					section:RefreshMobileLayout()
				end

				return
			end

			local height = tabsclosed
				and barheight
				or contentoffset + (container and container.Size.Y.Offset or 0)

			host.ClipsDescendants = animate == true or tabsclosed

			if animate then
				local animation =
					tween(host, {
						Size = UDim2.new(1, 0, 0, height),
					}, tabti)

				if not tabsclosed
					and animation
				then
					local completed
					completed = animation.Completed:Connect(function()
						if completed then
							completed:Disconnect()
							completed = nil
						end

						if host.Parent
							and not tabsclosed
						then
							host.ClipsDescendants = false
						end
					end)
				elseif not tabsclosed then
					host.ClipsDescendants = false
				end
			else
				host.Size = UDim2.new(1, 0, 0, height)
				host.ClipsDescendants = tabsclosed
			end
		end

		local function applytaborder()
			for index, tabname in ipairs(taborder) do
				local data = buttons[tabname]
				if data then
					data.button.LayoutOrder = index
				end
			end
		end

		local function maxscroll()
			return math.max(
				0,
				contentwidth
					- tabviewport.AbsoluteSize.X
			)
		end

		local function updatescrollbar()
			local viewport =
				tabviewport.AbsoluteSize.X

			local trackwidth =
				scrollbartrack.AbsoluteSize.X

			if not overflow
				or viewport <= 0
				or trackwidth <= 0
				or contentwidth <= viewport
			then
				scrollbarthumb.Visible = false
				scrollbartrack.BackgroundTransparency = 1
				return
			end

			scrollbarthumb.Visible = true
			scrollbartrack.BackgroundTransparency = .72

			local width =
				math.clamp(
					viewport
						/ contentwidth
						* trackwidth,
					20,
					trackwidth
				)

			local maximum =
				math.max(
					1,
					maxscroll()
				)

			local ratio =
				math.clamp(
					scrollx / maximum,
					0,
					1
				)

			scrollbarthumb.Size =
				UDim2.fromOffset(
					width,
					1
				)

			scrollbarthumb.Position =
				UDim2.fromOffset(
					(
						trackwidth - width
					)
						* ratio,
					0
				)
		end

		local function renderscroll(value)
			scrollx =
				math.clamp(
					value,
					0,
					maxscroll()
				)

			tabcontent.Position =
				UDim2.fromOffset(
					-scrollx,
					0
				)

			updatescrollbar()
		end

		scrollvalue:GetPropertyChangedSignal(
			"Value"
		):Connect(function()
			renderscroll(
				scrollvalue.Value
			)
		end)

		local function setscroll(
			value,
			animate
		)
			local target =
				math.clamp(
					value,
					0,
					maxscroll()
				)

			scrolltarget = target

			if scrollanimation then
				scrollanimation:Cancel()
				scrollanimation = nil
			end

			if not animate then
				scrollvalue.Value = target
				renderscroll(target)
				return
			end

			scrollanimation =
				tween(
					scrollvalue,
					{
						Value = target,
					},
					scrollti
				)
		end

		local function updatelayout()
			local viewport =
				tabviewport.AbsoluteSize.X

			if viewport <= 0 then
				return
			end

			contentwidth =
				tablayout.AbsoluteContentSize.X
					+ sidepadding * 2

			overflow =
				contentwidth > viewport

			if overflow then
				tabcontent.Size =
					UDim2.fromOffset(
						contentwidth,
						30
					)

				tablayout.HorizontalAlignment =
					Enum.HorizontalAlignment.Left

				setscroll(
					scrolltarget,
					false
				)
			else
				contentwidth = viewport

				tabcontent.Size =
					UDim2.fromOffset(
						viewport,
						30
					)

				tablayout.HorizontalAlignment =
					Enum.HorizontalAlignment.Left

				setscroll(
					0,
					false
				)
			end
		end

		local function ensuretabvisible(
			button,
			animate
		)
			if not overflow then
				return
			end

			local left =
				button.AbsolutePosition.X

			local right =
				left + button.AbsoluteSize.X

			local viewportleft =
				tabviewport.AbsolutePosition.X
					+ sidepadding

			local viewportright =
				tabviewport.AbsolutePosition.X
					+ tabviewport.AbsoluteSize.X
					- sidepadding

			local target = scrolltarget

			if left < viewportleft then
				target -=
					viewportleft - left
			elseif right > viewportright then
				target +=
					right - viewportright
			end

			setscroll(
				target,
				animate
			)
		end

		local function wheel(direction)
			if not overflow then
				return
			end

			setscroll(
				scrolltarget
					+ direction * wheelstep,
				true
			)
		end

		host.MouseWheelForward:Connect(function()
			wheel(-1)
		end)

		host.MouseWheelBackward:Connect(function()
			wheel(1)
		end)

		tabviewport.InputBegan:Connect(function(input)
			if input.UserInputType ~= Enum.UserInputType.Touch then
				return
			end

			local position = point(input)

			tabscroll = {
				input = input,
				name = nil,
				start = position,
				last = position,
				started = false,
			}
		end)

		local function select(
			name,
			scrollintoview,
			animate
		)
			if selected == name then
				return
			end

			selected = name

			local shouldanimate =
				animate ~= false

			for tabname, container in pairs(
				containers
			) do
				container.Visible =
					tabname == name
			end

			for tabname, data in pairs(
				buttons
			) do
				local active =
					tabname == name

				local textcolor =
					active
					and theme.text
					or theme.text3

				local linesize =
					active
					and UDim2.fromOffset(
						data.linewidth,
						2
					)
					or UDim2.fromOffset(
						0,
						2
					)

				local linetransparency =
					active and 0 or 1

				if shouldanimate then
					tween(
						data.text,
						{
							TextColor3 = textcolor,
						},
						tabti
					)

					tween(
						data.line,
						{
							Size = linesize,
							BackgroundTransparency =
								linetransparency,
						},
						tabti
					)
				else
					data.text.TextColor3 =
						textcolor

					data.line.Size =
						linesize

					data.line.BackgroundTransparency =
						linetransparency
				end

				if data.glow then
					if shouldanimate then
						tween(
							data.glow,
							{
								Transparency =
									active
									and .74
									or 1,
							},
							tabti
						)
					else
						data.glow.Transparency =
							active
							and .74
							or 1
					end
				end
			end

			local data =
				buttons[name]

			if data
				and scrollintoview ~= false
			then
				ensuretabvisible(
					data.button,
					shouldanimate
				)
			end

			local container =
				containers[name]

			if not container then
				return
			end

			container.Visible = true

			container.Position =
				UDim2.fromOffset(
					0,
					contentoffset
				)

			resizehost(false)
		end

		for index, tabname in ipairs(
			taborder
		) do
			local measured =
				measuretext(
					plaintext(tabname),
					15,
					medium,
					Vector2.new(
						1000,
						30
					)
				)

			local buttonwidth =
				math.max(
					38,
					measured.X + 12
				)

			local button = new("TextButton", {
				Parent = tabcontent,

				LayoutOrder = index,

				Size =
					UDim2.fromOffset(
						buttonwidth,
						30
					),

				BackgroundColor3 = theme.hover,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Text = "",
				AutoButtonColor = false,

				ZIndex = 16,
			})

			corner(button, 6)


			local textobject =
				label(
					button,
					tabname,
					UDim2.fromScale(
						1,
						1
					),
					medium,
					theme.text3
				)

			textobject.TextXAlignment =
				Enum.TextXAlignment.Center

			textobject.Position =
				UDim2.fromOffset(
					0,
					0
				)

			textobject.TextSize = 16
			textobject.ZIndex = 17

			button.MouseEnter:Connect(function()
				tween(textobject, {TextColor3 = theme.text}, hoverti)
			end)
			button.MouseLeave:Connect(function()
				tween(textobject, {TextColor3 = selected == tabname and theme.text or theme.text3}, hoverti)
			end)

			local line = new("Frame", {
				Parent = button,

				AnchorPoint =
					Vector2.new(
						.5,
						1
					),

				Position =
					UDim2.new(
						.5,
						0,
						1,
						-1
					),

				Size =
					UDim2.fromOffset(
						0,
						2
					),

				BackgroundColor3 = theme.white,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,

				ZIndex = 17,
			})

			corner(
				line,
				999
			)

			buttons[tabname] = {
				button = button,
				text = textobject,
				line = line,
				glow = nil,
				linewidth = math.max(
					18,
					math.ceil(measured.X) + 2
				),
			}

			-- Important: this must stay a normal Frame. CanvasGroup clips its
			-- descendants to its render bounds, which was cutting checkbox glows.
			local container = new("Frame", {
				Parent = host,

				Position =
					UDim2.fromOffset(
						0,
						contentoffset
					),

				Size =
					UDim2.new(
						1,
						0,
						0,
						0
					),

				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Visible = false,
				ClipsDescendants = false,

				ZIndex = 15,
			})

			local containerlayout =
				list(
					container,
					9
				)

			containers[tabname] =
				container

			containerlayout:GetPropertyChangedSignal(
				"AbsoluteContentSize"
			):Connect(function()
				local height =
					containerlayout.AbsoluteContentSize.Y
					+ (uis.TouchEnabled and 12 or 4)

				container.Size =
					UDim2.new(
						1,
						0,
						0,
						height
					)

				if selected == tabname then
					resizehost(false)
				end

				if uis.TouchEnabled
					and section.RefreshMobileLayout
				then
					section:RefreshMobileLayout()
				end
			end)

			button.InputBegan:Connect(function(input)
				if uis.TouchEnabled then
					if input.UserInputType ~= Enum.UserInputType.Touch then
						return
					end

					local position = point(input)
					tabscroll = {
						input = input,
						name = tabname,
						start = position,
						last = position,
						started = false,
					}
					return
				end

				if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
					return
				end

				tabdrag = {
					input = input,
					name = tabname,
					button = button,
					start = point(input),
					started = false,
				}
			end)

			button.Activated:Connect(function()
				local data = buttons[tabname]
				if data and data.suppressactivate then
					data.suppressactivate = false
					return
				end

				select(
					tabname,
					true,
					true
				)
			end)
		end

		applytaborder()


		connect(uis.InputChanged, function(input)
			if uis.TouchEnabled then
				if not tabscroll or not overflow then
					return
				end

				if input.UserInputType ~= Enum.UserInputType.Touch
					or input ~= tabscroll.input
				then
					return
				end

				local current = point(input)
				local total = current - tabscroll.start

				if not tabscroll.started and math.abs(total.X) >= 5 then
					tabscroll.started = true

					local data = buttons[tabscroll.name]
					if data then
						data.suppressactivate = true
					end
				end

				if not tabscroll.started then
					tabscroll.last = current
					return
				end

				local delta = current.X - tabscroll.last.X
				tabscroll.last = current

				setscroll(scrolltarget - delta, false)
				return
			end

			if not tabdrag then
				return
			end

			if input.UserInputType ~= Enum.UserInputType.MouseMovement then
				return
			end

			local current = point(input)
			if not tabdrag.started
				and (current - tabdrag.start).Magnitude >= 6
			then
				tabdrag.started = true
				buttons[tabdrag.name].suppressactivate = true
				tabdrag.grab = current - tabdrag.button.AbsolutePosition
				tabdrag.ghost, tabdrag.ghostclone, tabdrag.ghostscale = makedragghost(tabdrag.button, 470)
				tabdrag.hidden = hideforghost(tabdrag.button)
			end

			if not tabdrag.started then
				return
			end

			if tabdrag.ghost and tabdrag.ghost.Parent then
				local root = draglayer.AbsolutePosition
				tabdrag.ghost.Position = UDim2.fromOffset(
					current.X - tabdrag.grab.X - root.X,
					current.Y - tabdrag.grab.Y - root.Y
				)
			end

			local filtered = {}
			for _, tabname in ipairs(taborder) do
				if tabname ~= tabdrag.name then
					table.insert(filtered, tabname)
				end
			end

			local targetindex = #filtered + 1
			for index, tabname in ipairs(filtered) do
				local data = buttons[tabname]
				local center = data.button.AbsolutePosition.X + data.button.AbsoluteSize.X * .5
				if current.X < center then
					targetindex = index
					break
				end
			end

			local currentindex = table.find(taborder, tabdrag.name)
			local wanted = targetindex
			if currentindex and currentindex ~= wanted then
				local oldpositions = {}

				for _, currentname in ipairs(taborder) do
					local currentdata = buttons[currentname]
					if currentdata and currentdata.button then
						oldpositions[currentdata.button] = currentdata.button.AbsolutePosition
					end
				end

				table.remove(taborder, currentindex)
				wanted = math.clamp(wanted, 1, #taborder + 1)
				table.insert(taborder, wanted, tabdrag.name)
				applytaborder()
				updatelayout()

				local orderedbuttons = {}
				for _, currentname in ipairs(taborder) do
					local currentdata = buttons[currentname]
					if currentdata and currentdata.button then
						orderedbuttons[#orderedbuttons + 1] = currentdata.button
					end
				end

				animatereorder(oldpositions, orderedbuttons, tabdrag.button)
			end
		end)

		connect(uis.InputEnded, function(input)
			if uis.TouchEnabled then
				if not tabscroll or input ~= tabscroll.input then
					return
				end

				local data = buttons[tabscroll.name]
				local dragged = tabscroll.started
				tabscroll = nil

				if data and not dragged then
					data.suppressactivate = false
				end
				return
			end

			if not tabdrag or input.UserInputType ~= Enum.UserInputType.MouseButton1 then
				return
			end

			local drag = tabdrag
			tabdrag = nil

			if drag.started then
				local target = drag.button.AbsolutePosition - draglayer.AbsolutePosition
				local finished = false
				local function finish()
					if finished then return end
					finished = true
					restorefromghost(drag.hidden)
					if drag.ghost and drag.ghost.Parent then drag.ghost:Destroy() end
					local data = buttons[drag.name]
					if data then
						data.suppressactivate = false
					end
				end

				if drag.ghost and drag.ghost.Parent then
					local animation = tween(
						drag.ghost,
						{Position = UDim2.fromOffset(target.X, target.Y)},
						TweenInfo.new(.24, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
					)
					if animation then
						animation.Completed:Connect(finish)
					else
						finish()
					end
				else
					finish()
				end
			end
		end)

		tablayout:GetPropertyChangedSignal(
			"AbsoluteContentSize"
		):Connect(
			updatelayout
		)

		tabviewport:GetPropertyChangedSignal(
			"AbsoluteSize"
		):Connect(
			updatelayout
		)

		scrollbartrack:GetPropertyChangedSignal(
			"AbsoluteSize"
		):Connect(
			updatescrollbar
		)

		register(
			host,
			table.concat(
				names,
				" "
			)
		)

		setscroll(
			0,
			false
		)

		updatelayout()
		setscroll(
			0,
			false
		)

		select(
			taborder[1],
			false,
			false
		)

		updatelayout()
		setscroll(
			0,
			false
		)

		return {
			Get = function(_, name)
				return containers[name]
			end,

			Select = function(_, name)
				select(
					name,
					true,
					true
				)
			end,

			SetCollapsed = function(_, value, animate)
				tabsclosed = value == true
				resizehost(animate ~= false)
			end,

			IsCollapsed = function()
				return tabsclosed
			end,
		}
	end

	return section
end

-- pages

home =
	createpage(
		"home",
		"Home",
		nil
	)

combatmain =
	createpage(
		"combat_main",
		"Combat",
		"Main"
	)

combatvisuals =
	createpage(
		"combat_visuals",
		"Combat",
		"Visuals"
	)

combatextras =
	createpage(
		"combat_extras",
		"Combat",
		"Extras"
	)

farming =
	createpage(
		"farming",
		"Farming",
		nil
	)

settings =
	createpage(
		"settings",
		"Settings",
		nil
	)

components =
	createpage(
		"components",
		"Components",
		nil
	)

home.icon = icons.home
combatmain.icon = icons.target
combatvisuals.icon = icons.visuals
combatextras.icon = icons.extras
farming.icon = icons.farming
settings.icon = icons.settings
components.icon = icons.sliders

-- library runtime

legacysettingspath = "blush_ui_settings.json"
storagefolder = "blush"
configfolder = storagefolder .. "/configs"
themefolder = storagefolder .. "/themes"
backgroundfolder = storagefolder .. "/backgrounds"
settingspath = storagefolder .. "/settings.json"
savedsettings = {}

function ensurefolder(path)
	if typeof(isfolder) == "function" then
		local ok, exists = invoke(isfolder, path)
		if ok and exists then
			return true
		end
	end

	if typeof(makefolder) == "function" then
		return invoke(makefolder, path)
	end

	return false
end

function ensurestorage()
	ensurefolder(storagefolder)
	ensurefolder(configfolder)
	ensurefolder(themefolder)
	ensurefolder(backgroundfolder)

	if typeof(readfile) == "function"
		and typeof(writefile) == "function"
		and typeof(isfile) == "function"
	then
		local oldok, oldexists = invoke(isfile, legacysettingspath)
		local newok, newexists = invoke(isfile, settingspath)

		if oldok and oldexists
			and newok and not newexists
		then
			invoke(function()
				writefile(
					settingspath,
					readfile(legacysettingspath)
				)
			end)
		end
	end
end

function sanitizefilename(value)
	value = tostring(value or "")
	value = value:gsub("^%s+", ""):gsub("%s+$", "")
	value = value:gsub("[\\/:*?\"<>|]", "")
	value = value:gsub("^%.*", "")
	value = value:sub(1, 48)
	return value
end

function readjsonfile(path)
	if typeof(readfile) ~= "function" then
		return nil
	end

	local ok, encoded = invoke(readfile, path)
	if not ok or not encoded or encoded == "" then
		return nil
	end

	local decodedok, decoded = invoke(function()
		return httpservice:JSONDecode(encoded)
	end)

	return decodedok and typeof(decoded) == "table" and decoded or nil
end

function writejsonfile(path, data)
	if typeof(writefile) ~= "function" then
		return false
	end

	return invoke(function()
		writefile(path, httpservice:JSONEncode(data))
	end)
end

function listjsonnames(folder)
	local result = {}

	if typeof(listfiles) ~= "function" then
		return result
	end

	local ok, files = invoke(listfiles, folder)
	if not ok or typeof(files) ~= "table" then
		return result
	end

	for _, path in ipairs(files) do
		local name = tostring(path):match("([^/\\]+)%.json$")
		if name then
			table.insert(result, name)
		end
	end

	table.sort(result, function(a, b)
		return string.lower(a) < string.lower(b)
	end)

	return result
end

ensurestorage()

backgroundimagesource = ""
backgroundimageopacity = 65
backgroundimageblur = 0
backgroundimageblurmax = 100
backgroundimagemode = "Crop"
env.__blush_background_token = 0

function trimbackgroundsource(value)
	value = tostring(value or "")
	value = value:gsub("^%s+", ""):gsub("%s+$", "")

	local markdownurl = value:match("^%[[^%]]-%]%((https?://.-)%)$")
	if markdownurl then
		value = markdownurl
	end

	if (#value >= 2)
		and ((value:sub(1, 1) == '"' and value:sub(-1) == '"')
			or (value:sub(1, 1) == "'" and value:sub(-1) == "'")
			or (value:sub(1, 1) == "<" and value:sub(-1) == ">"))
	then
		value = value:sub(2, -2)
	end

	value = value:gsub("&amp;", "&")
	return value:gsub("^%s+", ""):gsub("%s+$", "")
end

function backgroundhash(value)
	local hash = 5381
	for index = 1, #value do
		hash = (hash * 33 + string.byte(value, index)) % 4294967296
	end
	return string.format("%08x", hash)
end

function backgroundextension(source, headers)
	local contenttype
	if typeof(headers) == "table" then
		for key, value in pairs(headers) do
			if string.lower(tostring(key)) == "content-type" then
				contenttype = string.lower(tostring(value))
				break
			end
		end
	end

	local typemap = {
		["image/png"] = "png",
		["image/jpeg"] = "jpg",
		["image/jpg"] = "jpg",
		["image/webp"] = "webp",
		["image/avif"] = "avif",
		["image/bmp"] = "bmp",
		["image/gif"] = "gif",
		["image/tga"] = "tga",
	}

	if contenttype then
		for mime, extension in pairs(typemap) do
			if contenttype:find(mime, 1, true) then
				return extension
			end
		end
	end

	local clean = tostring(source):match("^[^?#]+") or tostring(source)
	local extension = clean:match("%.([%w]+)$")
	if extension then
		extension = string.lower(extension)
		if extension == "jpeg" then
			extension = "jpg"
		end
		if table.find({ "png", "jpg", "webp", "avif", "bmp", "gif", "tga" }, extension) then
			return extension
		end
	end

	return "png"
end

function backgroundcustomasset(path)
	local providers = {}

	if typeof(getcustomasset) == "function" then
		providers[#providers + 1] = getcustomasset
	end
	if typeof(getsynasset) == "function" then
		providers[#providers + 1] = getsynasset
	end
	if typeof(getasset) == "function" then
		providers[#providers + 1] = getasset
	end

	for _, provider in ipairs(providers) do
		local ok, asset = invoke(provider, path)
		if ok and type(asset) == "string" and asset ~= "" then
			return asset
		end
	end

	return nil, "custom asset API unavailable"
end

function backgroundrequest(url)
	local requesters = {}

	if typeof(request) == "function" then
		requesters[#requesters + 1] = request
	end
	if typeof(http_request) == "function" then
		requesters[#requesters + 1] = http_request
	end
	if syn and typeof(syn.request) == "function" then
		requesters[#requesters + 1] = syn.request
	end
	if http and typeof(http.request) == "function" then
		requesters[#requesters + 1] = http.request
	end
	if fluxus and typeof(fluxus.request) == "function" then
		requesters[#requesters + 1] = fluxus.request
	end

	for _, requester in ipairs(requesters) do
		local ok, response = invoke(requester, {
			Url = url,
			Method = "GET",
			Headers = {
				["User-Agent"] = "Mozilla/5.0",
				Accept = "image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8",
			},
		})

		if ok and typeof(response) == "table" then
			local status = tonumber(response.StatusCode or response.Status or response.status_code) or 200
			local body = response.Body or response.body

			if status >= 200 and status < 400 and type(body) == "string" and #body > 0 then
				return body, response.Headers or response.headers or {}, nil
			end
		end
	end

	local ok, body = invoke(function()
		return game:HttpGet(url)
	end)

	if ok and type(body) == "string" and #body > 0 then
		return body, {}, nil
	end

	return nil, nil, "download failed"
end

function backgroundbase64decode(data)
	if crypt and crypt.base64 and typeof(crypt.base64.decode) == "function" then
		local ok, decoded = invoke(crypt.base64.decode, data)
		if ok then return decoded end
	end

	if syn and syn.crypt and syn.crypt.base64 and typeof(syn.crypt.base64.decode) == "function" then
		local ok, decoded = invoke(syn.crypt.base64.decode, data)
		if ok then return decoded end
	end

	if typeof(base64_decode) == "function" then
		local ok, decoded = invoke(base64_decode, data)
		if ok then return decoded end
	end

	local alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
	data = tostring(data):gsub("[^" .. alphabet .. "=]", "")

	local bits = data:gsub(".", function(character)
		if character == "=" then
			return ""
		end

		local index = alphabet:find(character, 1, true)
		if not index then
			return ""
		end

		index -= 1
		local result = ""
		for bit = 6, 1, -1 do
			local set = index % 2 ^ bit - index % 2 ^ (bit - 1) > 0
			result ..= set and "1" or "0"
		end
		return result
	end)

	return bits:gsub("%d%d%d?%d?%d?%d?%d?%d?", function(chunk)
		if #chunk ~= 8 then
			return ""
		end

		local value = 0
		for index = 1, 8 do
			if chunk:sub(index, index) == "1" then
				value += 2 ^ (8 - index)
			end
		end
		return string.char(value)
	end)
end

function backgroundlocalpath(source)
	local lower = string.lower(source)

	if lower:sub(1, 8) == "file:///" then
		source = source:sub(9)
	elseif lower:sub(1, 7) == "file://" then
		source = source:sub(8)
	end

	source = source:gsub("%%20", " ")
	return source
end

function resolvebackgroundimage(source, force)
	source = trimbackgroundsource(source)
	if source == "" then
		return nil, "empty source"
	end

	if source:match("^%d+$") then
		return "rbxassetid://" .. source
	end

	local lower = string.lower(source)
	if lower:match("^rbxassetid://")
		or lower:match("^rbxthumb://")
		or lower:match("^rbxasset://")
	then
		return source
	end

	local robloxid = source:match("[?&]id=(%d+)")
		or source:match("/asset/(%d+)")
		or source:match("/library/(%d+)")
		or source:match("/store/asset/(%d+)")
	if robloxid and lower:find("roblox", 1, true) then
		return "rbxassetid://" .. robloxid
	end

	if lower:match("^data:image/") then
		if typeof(writefile) ~= "function" then
			return nil, "writefile unavailable"
		end

		local mime, encoded = source:match("^data:(image/[^;]+);base64,(.+)$")
		if not mime or not encoded then
			return nil, "invalid data URI"
		end

		local extension = backgroundextension("", { ["Content-Type"] = mime })
		local path = backgroundfolder .. "/data_" .. backgroundhash(source) .. "." .. extension

		if force or typeof(isfile) ~= "function" or not isfile(path) then
			local decoded = backgroundbase64decode(encoded)
			if type(decoded) ~= "string" or #decoded == 0 then
				return nil, "base64 decode failed"
			end

			local ok = invoke(writefile, path, decoded)
			if not ok then
				return nil, "could not write image"
			end
		end

		return backgroundcustomasset(path)
	end

	if lower:match("^https?://") then
		if typeof(writefile) ~= "function" then
			return nil, "writefile unavailable"
		end

		local cachedprefix = backgroundfolder .. "/url_" .. backgroundhash(source)
		local extensions = { "png", "jpg", "webp", "avif", "bmp", "gif", "tga" }

		if not force and typeof(isfile) == "function" then
			for _, extension in ipairs(extensions) do
				local path = cachedprefix .. "." .. extension
				local ok, exists = invoke(isfile, path)
				if ok and exists then
					local asset = backgroundcustomasset(path)
					if asset then
						return asset
					end
				end
			end
		end

		local body, headers, err = backgroundrequest(source)
		if not body then
			return nil, err or "download failed"
		end

		local extension = backgroundextension(source, headers)
		local path = cachedprefix .. "." .. extension
		local ok = invoke(writefile, path, body)
		if not ok then
			return nil, "could not cache image"
		end

		return backgroundcustomasset(path)
	end

	local path = backgroundlocalpath(source)
	if typeof(isfile) == "function" then
		local ok, exists = invoke(isfile, path)
		if ok and not exists then
			return nil, "file not found"
		end
	end

	return backgroundcustomasset(path)
end

function boxblurbackgroundbuffer(sourcebuffer, width, height, radius)
	radius = math.max(1, math.floor(radius))
	local bytes = width * height * 4
	local horizontal = buffer.create(bytes)
	local output = buffer.create(bytes)
	local diameter = radius * 2 + 1

	for y = 0, height - 1 do
		local sums = { 0, 0, 0, 0 }
		for sx = -radius, radius do
			local x = math.clamp(sx, 0, width - 1)
			local offset = (y * width + x) * 4
			for channel = 0, 3 do
				sums[channel + 1] += buffer.readu8(sourcebuffer, offset + channel)
			end
		end

		for x = 0, width - 1 do
			local offset = (y * width + x) * 4
			for channel = 0, 3 do
				buffer.writeu8(horizontal, offset + channel, math.floor(sums[channel + 1] / diameter + .5))
			end

			local removeX = math.clamp(x - radius, 0, width - 1)
			local addX = math.clamp(x + radius + 1, 0, width - 1)
			local removeOffset = (y * width + removeX) * 4
			local addOffset = (y * width + addX) * 4
			for channel = 0, 3 do
				sums[channel + 1] += buffer.readu8(sourcebuffer, addOffset + channel)
				sums[channel + 1] -= buffer.readu8(sourcebuffer, removeOffset + channel)
			end
		end
	end

	for x = 0, width - 1 do
		local sums = { 0, 0, 0, 0 }
		for sy = -radius, radius do
			local y = math.clamp(sy, 0, height - 1)
			local offset = (y * width + x) * 4
			for channel = 0, 3 do
				sums[channel + 1] += buffer.readu8(horizontal, offset + channel)
			end
		end

		for y = 0, height - 1 do
			local offset = (y * width + x) * 4
			for channel = 0, 3 do
				buffer.writeu8(output, offset + channel, math.floor(sums[channel + 1] / diameter + .5))
			end

			local removeY = math.clamp(y - radius, 0, height - 1)
			local addY = math.clamp(y + radius + 1, 0, height - 1)
			local removeOffset = (removeY * width + x) * 4
			local addOffset = (addY * width + x) * 4
			for channel = 0, 3 do
				sums[channel + 1] += buffer.readu8(horizontal, addOffset + channel)
				sums[channel + 1] -= buffer.readu8(horizontal, removeOffset + channel)
			end
		end
	end

	return output
end

function preparebackgroundblurbase(asset, token)
	if backgroundblurbaseasset == asset
		and backgroundblurbasepixels
		and backgroundblurbasewidth > 0
		and backgroundblurbaseheight > 0
	then
		return true
	end

	local source
	local ok = invoke(function()
		source = assetservice:CreateEditableImageAsync(Content.fromUri(asset))
	end)
	if not ok or not source or token ~= backgroundblurtoken then
		if source then invoke(function() source:Destroy() end) end
		return false
	end

	local sourceSize = source.Size
	if sourceSize.X < 1 or sourceSize.Y < 1 then
		invoke(function() source:Destroy() end)
		return false
	end

	local maxdimension = 112
	local scale = math.min(1, maxdimension / math.max(sourceSize.X, sourceSize.Y))
	local width = math.max(24, math.floor(sourceSize.X * scale + .5))
	local height = math.max(24, math.floor(sourceSize.Y * scale + .5))
	local base
	local pixels

	ok = invoke(function()
		base = assetservice:CreateEditableImage({ Size = Vector2.new(width, height) })
		if not base then error("editable image unavailable") end

		base:DrawImageTransformed(
			Vector2.zero,
			Vector2.new(width / sourceSize.X, height / sourceSize.Y),
			0,
			source,
			{
				CombineType = Enum.ImageCombineType.Overwrite,
				SamplingMode = Enum.ResamplerMode.Default,
				PivotPoint = Vector2.zero,
			}
		)

		pixels = base:ReadPixelsBuffer(Vector2.zero, Vector2.new(width, height))
	end)

	invoke(function() source:Destroy() end)
	if base then invoke(function() base:Destroy() end) end

	if not ok or not pixels or token ~= backgroundblurtoken then
		return false
	end

	backgroundblurbaseasset = asset
	backgroundblurbasepixels = pixels
	backgroundblurbasewidth = width
	backgroundblurbaseheight = height
	return true
end

function buildbackgroundblur(asset, blur, token)
	if not asset or asset == "" or blur <= 0 then
		return false
	end

	if not preparebackgroundblurbase(asset, token) then
		return false
	end
	if token ~= backgroundblurtoken then
		return false
	end

	local width = backgroundblurbasewidth
	local height = backgroundblurbaseheight
	local sourcepixels = backgroundblurbasepixels
	if not sourcepixels or width < 1 or height < 1 then
		return false
	end

	local strength = math.clamp(blur / backgroundimageblurmax, 0, 1)
	local radius = math.clamp(math.floor((strength ^ 1.35) * 8 + .5), 1, 8)
	local passes = blur >= 72 and 2 or 1
	local signature = tostring(backgroundblurbaseasset) .. ":" .. tostring(radius) .. ":" .. tostring(passes)
	if backgroundblureditable and backgroundblurlastsignature == signature then
		return true
	end

	local pixels = sourcepixels

	for _ = 1, passes do
		pixels = boxblurbackgroundbuffer(pixels, width, height, radius)
	end
	if token ~= backgroundblurtoken then
		return false
	end

	local blurred
	local ok = invoke(function()
		blurred = assetservice:CreateEditableImage({ Size = Vector2.new(width, height) })
		if not blurred then error("editable image unavailable") end
		blurred:WritePixelsBuffer(Vector2.zero, Vector2.new(width, height), pixels)
	end)

	if not ok or not blurred or token ~= backgroundblurtoken then
		if blurred then invoke(function() blurred:Destroy() end) end
		return false
	end

	if backgroundblureditable and backgroundblureditable ~= blurred then
		invoke(function() backgroundblureditable:Destroy() end)
	end
	backgroundblureditable = blurred
	backgroundblurlastsignature = signature

	local applied = invoke(function()
		backgroundblurdisplay.ImageContent = Content.fromObject(blurred)
	end)
	if not applied then
		invoke(function() blurred:Destroy() end)
		backgroundblureditable = nil
		backgroundblurlastsignature = nil
		return false
	end

	return true
end

function applybackgroundblurblend()
	local opacity = math.clamp(backgroundimageopacity / 100, 0, 1)
	local blur = math.clamp(backgroundimageblur, 0, backgroundimageblurmax)
	local visible = backgroundimagesource ~= "" and backgroundresolvedasset ~= nil

	if not visible then
		backgroundimage.Visible = false
		backgroundblurdisplay.Visible = false
		backgroundimage.ImageTransparency = 1
		backgroundblurdisplay.ImageTransparency = 1
		return
	end

	backgroundimage.Visible = true
	if blur <= 0 or not backgroundblureditable then
		backgroundimage.ImageTransparency = 1 - opacity
		backgroundblurdisplay.Visible = false
		backgroundblurdisplay.ImageTransparency = 1
		return
	end

	-- Non-linear blend keeps the first blur values extremely subtle.
	local strength = math.clamp(blur / backgroundimageblurmax, 0, 1)
	local blend = strength ^ 1.75
	local bluralpha = opacity * blend
	local basealpha = opacity
	if bluralpha < 1 then
		basealpha = math.clamp((opacity - bluralpha) / math.max(.001, 1 - bluralpha), 0, 1)
	end

	backgroundimage.ImageTransparency = 1 - basealpha
	backgroundblurdisplay.ImageTransparency = 1 - bluralpha
	backgroundblurdisplay.Visible = bluralpha > .001
end

function schedulebackgroundblur(animate)
	backgroundblurdebounce += 1
	local debounce = backgroundblurdebounce
	backgroundblurtoken += 1
	local token = backgroundblurtoken
	local blur = math.clamp(backgroundimageblur, 0, backgroundimageblurmax)
	local asset = backgroundresolvedasset

	if blur <= 0 or not asset or asset == "" then
		applybackgroundblurblend()
		return
	end

	-- Keep the previous blur visible while the new level is rebuilt.
	applybackgroundblurblend()

	if backgroundblurtask
		and coroutine.status(backgroundblurtask) == "suspended"
	then
		pcall(task.cancel, backgroundblurtask)
	end

	backgroundblurtask = task.delay(.008, function()
		if debounce ~= backgroundblurdebounce or token ~= backgroundblurtoken then
			return
		end

		backgroundblurtask = nil

		local success = buildbackgroundblur(asset, blur, token)
		if debounce ~= backgroundblurdebounce or token ~= backgroundblurtoken then
			return
		end

		if success then
			applybackgroundblurblend()
		else
			backgroundblurdisplay.Visible = false
			backgroundblurdisplay.ImageTransparency = 1
			backgroundimage.Image = backgroundresolvedasset or backgroundimage.Image
			backgroundimage.Visible = backgroundresolvedasset ~= nil
			backgroundimage.ImageTransparency = 1 - math.clamp(backgroundimageopacity / 100, 0, 1)
		end
	end)
end

function renderbackgroundimage(animate)
	local opacity = math.clamp(backgroundimageopacity / 100, 0, 1)
	local blur = math.clamp(backgroundimageblur, 0, backgroundimageblurmax)
	local visible = backgroundimagesource ~= "" and backgroundresolvedasset ~= nil
	local imageinfo = TweenInfo.new(.26, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

	env.__blush_background_visibility = visible and opacity or 0
	updatebackgroundbounds()
	updatebackgroundtone()
	if updatebackgroundsurfaces then
		updatebackgroundsurfaces()
	end

	backgroundimage.ScaleType = Enum.ScaleType.Crop
	backgroundimage.Size = UDim2.fromScale(1, 1)
	backgroundimage.Position = UDim2.fromScale(.5, .5)
	backgroundimage.ImageColor3 = Color3.new(1, 1, 1)
	backgroundblurdisplay.ScaleType = Enum.ScaleType.Crop
	backgroundblurdisplay.Size = UDim2.fromScale(1, 1)
	backgroundblurdisplay.Position = UDim2.fromScale(.5, .5)
	backgroundblurdisplay.ImageColor3 = Color3.new(1, 1, 1)

	if not visible then
		backgroundblurdebounce += 1
		backgroundblurtoken += 1
		backgroundimage.Visible = false
		backgroundblurdisplay.Visible = false
		backgroundimage.ImageTransparency = 1
		backgroundblurdisplay.ImageTransparency = 1
		return
	end

	if blur <= 0 then
		backgroundblurdebounce += 1
		backgroundblurtoken += 1
		backgroundblurdisplay.Visible = false
		backgroundblurdisplay.ImageTransparency = 1
		backgroundimage.Visible = true
		local target = 1 - opacity
		if animate and animationsenabled then
			tween(backgroundimage, { ImageTransparency = target }, imageinfo)
		else
			backgroundimage.ImageTransparency = target
		end
		return
	end

	backgroundimage.Visible = true
	applybackgroundblurblend()
	schedulebackgroundblur(animate)
end

function setbackgroundimageopacity(value, animate)
	backgroundimageopacity = math.clamp(tonumber(value) or 65, 0, 100)
	renderbackgroundimage(animate)
end

function setbackgroundimageblur(value, animate)
	backgroundimageblur = math.clamp(tonumber(value) or 0, 0, backgroundimageblurmax)
	renderbackgroundimage(animate)
end

function setbackgroundimagemode()
	backgroundimagemode = "Crop"
	for _, layer in ipairs(backgroundlayers) do
		layer.ScaleType = Enum.ScaleType.Crop
	end
end

function clearbackgroundimage(animate)
	env.__blush_background_token += 1
	backgroundimagesource = ""
	backgroundresolvedasset = nil
	backgroundpalette = nil
	env.__blush_background_visibility = 0
	destroybackgroundeditable()
	if updatebackgroundsurfaces then
		updatebackgroundsurfaces()
	end

	if autobackgroundcolors and backgroundautobase then
		restorebackgroundautobase(animate)
	end

	local function finish()
		if backgroundimagesource ~= "" then
			return
		end
		for _, layer in ipairs(backgroundlayers) do
			layer.Visible = false
			layer.Image = ""
			layer.ImageTransparency = 1
		end
	end

	if backgroundimage.Visible and animate and animationsenabled then
		local animation
		for index, layer in ipairs(backgroundlayers) do
			if layer.Visible then
				local current = tween(
					layer,
					{ ImageTransparency = 1 },
					TweenInfo.new(.26, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
				)
				if index == 1 then
					animation = current
				end
			end
		end
		if animation then
			animation.Completed:Connect(finish)
		else
			finish()
		end
	else
		finish()
	end
end

backgroundpalette = nil
backgroundautobase = nil

function selectedthemebase()
	local selected = themeselector and themeselector:Get() or "Default"
	local preset = themepresets and themepresets[selected]

	if preset then
		return preset
	end

	return {
		background = theme.window,
		accent = theme.white,
		font = theme.font,
	}
end

function buildbackgroundautocolors(average, sampledaccent)
	local base = selectedthemebase()
	local basebackground = base.background or theme.window
	local baseaccent = base.accent or theme.white

	local ah, as, av = average:ToHSV()
	local sh, ss, sv = sampledaccent:ToHSV()
	local _, bases, basev = basebackground:ToHSV()
	local _, baseas, baseav = baseaccent:ToHSV()

	local baseluminance = basebackground.R * .2126
		+ basebackground.G * .7152
		+ basebackground.B * .0722
	local lighttheme = baseluminance >= .58
	local hue = as >= .05 and ah or sh

	local background
	local accent

	if lighttheme then
		background = Color3.fromHSV(
			hue,
			math.clamp(as * .16 + bases * .18, .015, .14),
			math.clamp(math.max(basev, .90), .90, .975)
		)
		accent = Color3.fromHSV(
			sh,
			math.clamp(ss * .86 + baseas * .14, .42, .82),
			math.clamp(math.min(sv, .68) * .72 + baseav * .28, .38, .68)
		)
	else
		background = Color3.fromHSV(
			hue,
			math.clamp(as * .28 + bases * .32, .035, .24),
			math.clamp(basev * .72 + .025, .045, .13)
		)
		accent = Color3.fromHSV(
			sh,
			math.clamp(ss * .86 + baseas * .14, .48, .88),
			math.clamp(math.max(sv, .76) * .86 + baseav * .14, .72, .96)
		)
	end

	local luminance = background.R * .2126
		+ background.G * .7152
		+ background.B * .0722
	local fontcolor = luminance >= .55
		and Color3.fromRGB(30, 31, 35)
		or Color3.fromRGB(240, 241, 244)

	return background, accent, fontcolor
end

function applybackgroundautocolors(animate)
	if not autobackgroundcolors or not backgroundpalette then
		return false
	end

	if not backgroundautobase then
		backgroundautobase = {
			background = theme.window,
			accent = theme.white,
			font = theme.font,
			backgroundAlpha = theme.backgroundAlpha,
			accentAlpha = theme.accentAlpha,
			fontAlpha = theme.fontAlpha,
		}
	end

	local background, accent, fontcolor = buildbackgroundautocolors(
		backgroundpalette.average,
		backgroundpalette.accent
	)

	applytheme(background, accent, 1, 1, fontcolor, 1, animate == true)

	if accentpicker then
		accentpicker:Set(accent, 1, false)
	end
	if backgroundpicker then
		backgroundpicker:Set(background, 1, false)
	end
	if fontpicker then
		fontpicker:Set(fontcolor, 1, false)
	end

	return true
end

function restorebackgroundautobase(animate)
	local base = backgroundautobase or selectedthemebase()
	backgroundautobase = nil

	applytheme(
		base.background or theme.window,
		base.accent or theme.white,
		base.backgroundAlpha or 1,
		base.accentAlpha or 1,
		base.font or theme.font,
		base.fontAlpha or 1,
		animate == true
	)

	if accentpicker then
		accentpicker:Set(base.accent or theme.white, base.accentAlpha or 1, false)
	end
	if backgroundpicker then
		backgroundpicker:Set(base.background or theme.window, base.backgroundAlpha or 1, false)
	end
	if fontpicker then
		fontpicker:Set(base.font or theme.font, base.fontAlpha or 1, false)
	end
end

function samplebackgroundpalette(asset)
	if not autobackgroundcolors or not asset or asset == "" then
		return false
	end

	local editable
	local ok = invoke(function()
		editable = assetservice:CreateEditableImageAsync(Content.fromUri(asset))
	end)

	if not ok or not editable then
		return false
	end

	local success, average, accent = invoke(function()
		local size = editable.Size
		if size.X < 1 or size.Y < 1 then
			return nil, nil
		end

		local totalr, totalg, totalb, totalweight = 0, 0, 0, 0
		local bestcolor = Color3.new(1, 1, 1)
		local bestscore = -1
		local steps = 7

		for y = 0, steps - 1 do
			for x = 0, steps - 1 do
				local px = math.clamp(math.floor((x + .5) / steps * size.X), 0, math.max(0, size.X - 1))
				local py = math.clamp(math.floor((y + .5) / steps * size.Y), 0, math.max(0, size.Y - 1))
				local pixels = editable:ReadPixelsBuffer(Vector2.new(px, py), Vector2.new(1, 1))
				local r = buffer.readu8(pixels, 0) / 255
				local g = buffer.readu8(pixels, 1) / 255
				local b = buffer.readu8(pixels, 2) / 255
				local a = buffer.readu8(pixels, 3) / 255

				if a > .05 then
					local color = Color3.new(r, g, b)
					local h, s, v = color:ToHSV()
					local midvalue = 1 - math.abs(v - .62)
					local score = s * (.45 + math.max(0, midvalue)) * a

					totalr += r * a
					totalg += g * a
					totalb += b * a
					totalweight += a

					if score > bestscore then
						bestscore = score
						bestcolor = Color3.fromHSV(
							h,
							math.clamp(math.max(s, .36), .36, .92),
							math.clamp(v, .42, .94)
						)
					end
				end
			end
		end

		if totalweight <= 0 then
			return nil, nil
		end

		return Color3.new(
			totalr / totalweight,
			totalg / totalweight,
			totalb / totalweight
		), bestcolor
	end)

	invoke(function()
		editable:Destroy()
	end)

	if not success or not average or not accent then
		return false
	end

	backgroundpalette = {
		average = average,
		accent = accent,
	}

	return applybackgroundautocolors(true)
end

function loadbackgroundimage(source, force, silent)
	source = trimbackgroundsource(source)

	if source == "" then
		clearbackgroundimage(true)
		return true
	end

	env.__blush_background_token += 1
	local token = env.__blush_background_token
	local asset, err = resolvebackgroundimage(source, force == true)

	if token ~= env.__blush_background_token then
		return false, "cancelled"
	end

	if not asset then
		if not silent then
			notify(
				"Background unavailable",
				tostring(err or "Could not load image."),
				3,
				nil,
				nil,
				icons.wallpaper
			)
		end
		return false, err
	end

	backgroundimagesource = source
	if backgroundresolvedasset ~= asset then
		backgroundblurbaseasset = nil
		backgroundblurbasepixels = nil
		backgroundblurbasewidth = 0
		backgroundblurbaseheight = 0
		backgroundblurlastsignature = nil
		if backgroundblureditable then
			invoke(function() backgroundblureditable:Destroy() end)
			backgroundblureditable = nil
		end
	end
	backgroundresolvedasset = asset
	backgroundpalette = nil
	backgroundimagemode = "Crop"
	if updatebackgroundsurfaces then
		updatebackgroundsurfaces()
	end
	for _, layer in ipairs(backgroundlayers) do
		layer.Image = asset
		layer.ScaleType = Enum.ScaleType.Crop
		layer.ImageTransparency = 1
		layer.Visible = true
	end

	backgroundimage.Image = asset
	backgroundimage.Visible = true
	renderbackgroundimage(animationsenabled)

	if autobackgroundcolors then
		task.spawn(function()
			if samplebackgroundpalette(asset) then
				saveuisettings()
			end
		end)
	end

	if not silent then
		notify(
			"Background loaded",
			"Image applied to the interface.",
			2.2,
			nil,
			nil,
			icons.wallpaper
		)
	end

	return true
end

env.__blush_background = {
	Set = function(source, force)
		return loadbackgroundimage(source, force == true, true)
	end,
	Clear = function()
		clearbackgroundimage(true)
	end,
	SetOpacity = function(value)
		setbackgroundimageopacity(value, true)
	end,
	SetBlur = function(value)
		setbackgroundimageblur(value, true)
	end,
	SetScale = function()
		setbackgroundimagemode("Crop")
	end,
}

function decodecolor(value)
	if typeof(value) ~= "table" then
		return nil
	end

	local r = tonumber(value.r or value[1])
	local g = tonumber(value.g or value[2])
	local b = tonumber(value.b or value[3])

	if not r or not g or not b then
		return nil
	end

	return Color3.fromRGB(
		math.clamp(math.round(r), 0, 255),
		math.clamp(math.round(g), 0, 255),
		math.clamp(math.round(b), 0, 255)
	)
end

function encodecolor(color)
	return {
		r = math.round(color.R * 255),
		g = math.round(color.G * 255),
		b = math.round(color.B * 255),
	}
end

function keyfromname(name)
	if typeof(name) ~= "string" then
		return nil
	end

	for _, key in ipairs(Enum.KeyCode:GetEnumItems()) do
		if key.Name == name then
			return key
		end
	end

	for _, inputtype in ipairs(Enum.UserInputType:GetEnumItems()) do
		if inputtype.Name == name and validmousebind(inputtype) then
			return inputtype
		end
	end

	return nil
end

function readuisettingsfile()
	if typeof(readfile) ~= "function" then
		return {}
	end

	local ok, encoded = invoke(function()
		if typeof(isfile) == "function"
			and not isfile(settingspath)
		then
			return nil
		end

		return readfile(settingspath)
	end)

	if not ok or not encoded or encoded == "" then
		return {}
	end

	local decodedok, decoded = invoke(function()
		return httpservice:JSONDecode(encoded)
	end)

	if decodedok and typeof(decoded) == "table" then
		return decoded
	end

	return {}
end

savedsettings = readuisettingsfile()
rawsavedsettings = savedsettings
selectedconfig = sanitizefilename(rawsavedsettings.selectedConfig or "")
selectedthemesave = sanitizefilename(rawsavedsettings.selectedThemeSave or "")

animationsenabled =
	savedsettings.animations ~= false

searchenabled =
	savedsettings.searchCurrentPage ~= false

menukey =
	keyfromname(savedsettings.menuKey)
	or Enum.KeyCode.RightShift

setkeybindblacklist(
	type(savedsettings.keybindBlacklist) == "table"
		and savedsettings.keybindBlacklist
		or keybindblacklistdefaults
)

initialtransparency = math.clamp(
	tonumber(savedsettings.uiTransparency) or 0,
	0,
	90
)

initialuiscale = 100

notificationsenabled =
	savedsettings.notifications ~= false

defaultnotificationduration = 3.5
maxnotifications = 5

backgroundimagesource = type(savedsettings.backgroundImageSource) == "string"
	and savedsettings.backgroundImageSource
	or ""
backgroundimageopacity = math.clamp(tonumber(savedsettings.backgroundImageOpacity) or 65, 0, 100)
backgroundimageblur = math.clamp(tonumber(savedsettings.backgroundImageBlur) or 0, 0, backgroundimageblurmax)
backgroundimagemode = "Crop"
backgroundexcludesidebar = savedsettings.backgroundImageExcludeSidebar == true
autobackgroundcolors = false
topnavigationenabled = savedsettings.topNavigation == true

windowglowenabled = savedsettings.windowGlow ~= false
windowglowintensity = math.clamp(
	tonumber(savedsettings.windowGlowIntensity) or 16,
	0,
	100
)
windowglowsize = math.clamp(
	tonumber(savedsettings.windowGlowSize) or 10,
	0,
	24
)
windowglowcolor = theme.white
windowglowalpha = math.clamp(
	tonumber(savedsettings.windowGlowAlpha) or 1,
	0,
	1
)
windowglowrenderalpha = windowglowalpha

applywindowglow()

setbackgroundimagemode("Crop")
setbackgroundexcludesidebar(backgroundexcludesidebar)
setbackgroundimageopacity(backgroundimageopacity, false)
setbackgroundimageblur(backgroundimageblur, false)

applyuitransparency(initialtransparency)
applyuiscale(initialuiscale)

loadingsettings = true
watermarktoggle = nil
watermarkinfocontrol = nil
watermarkplayermodecontrol = nil
themeselector = nil
accentpicker = nil
backgroundpicker = nil
fontpicker = nil
animationtoggle = nil
searchtoggle = nil
menukeypicker = nil
keybindblacklistcontrol = nil
hotkeylisttoggle = nil
minimizebuttoncontrol = nil
uitransparencycontrol = nil
notificationtoggle = nil
configselector = nil
configinput = nil
autosaveconfigcontrol = nil
themfileselector = nil
themefileinput = nil
settingssection = nil
themessection = nil
backgroundimagesection = nil
backgroundimageinput = nil
backgroundimageopacitycontrol = nil
backgroundimageblurcontrol = nil
backgroundexcludecontrol = nil
backgroundautocolorcontrol = nil
topnavigationtoggle = nil
windowglowtoggle = nil
windowglowintensitycontrol = nil
windowglowsizecontrol = nil
windowglowcolorpicker = nil
savessection = nil

function currentuipayload()
	local accent =
		accentpicker
		and accentpicker:color()
		or theme.white

	local background =
		backgroundpicker
		and backgroundpicker:color()
		or theme.window

	local fontcolor =
		fontpicker
		and fontpicker:color()
		or theme.font

	local selectedmenukey =
		menukeypicker
		and menukeypicker:Get()
		or menukey

	return {
		watermark = watermarktoggle
			and watermarktoggle:Get()
			or watermarkshown,

		watermarkInfo = {
			Player = watermarkconfig.Player == true,
			FPS = watermarkconfig.FPS == true,
			Ping = watermarkconfig.Ping == true,
			Time = watermarkconfig.Time == true,
			PlayerMode = watermarkconfig.PlayerMode,
		},

		animations = animationtoggle
			and animationtoggle:Get()
			or animationsenabled,

		searchCurrentPage = searchtoggle
			and searchtoggle:Get()
			or searchenabled,

		notifications = notificationtoggle
			and notificationtoggle:Get()
			or notificationsenabled,

		hotkeyList = hotkeylisttoggle
			and hotkeylisttoggle:Get()
			or hotkeylist.Visible,

		minimizeButton = minimizebuttoncontrol
			and minimizebuttoncontrol:Get()
			or windowminimizebuttonenabled,

		backgroundImageSource = backgroundimagesource,

		backgroundImageOpacity = backgroundimageopacitycontrol
			and backgroundimageopacitycontrol:Get()
			or backgroundimageopacity,

		backgroundImageBlur = backgroundimageblurcontrol
			and backgroundimageblurcontrol:Get()
			or backgroundimageblur,

		backgroundImageMode = "Crop",
		backgroundImageExcludeSidebar = backgroundexcludecontrol
			and backgroundexcludecontrol:Get()
			or backgroundexcludesidebar,
		backgroundAutoColors = false,
		topNavigation = topnavigationtoggle
			and topnavigationtoggle:Get()
			or topnavigationenabled,

		windowGlow = windowglowtoggle
			and windowglowtoggle:Get()
			or windowglowenabled,

		windowGlowIntensity = windowglowintensitycontrol
			and windowglowintensitycontrol:Get()
			or windowglowintensity,

		windowGlowSize = windowglowsizecontrol
			and windowglowsizecontrol:Get()
			or windowglowsize,

		windowGlowColor = encodecolor(windowglowcolor),
		windowGlowAlpha = windowglowcolorpicker
			and windowglowcolorpicker.alpha
			or windowglowalpha,

		uiTransparency = uitransparencycontrol
			and uitransparencycontrol:Get()
			or math.floor(uitransparency * 100 + .5),

		selectedConfig = selectedconfig,
		selectedThemeSave = selectedthemesave,
		autoSaveConfig = autosaveconfigcontrol
			and autosaveconfigcontrol:Get()
			or rawsavedsettings.autoSaveConfig == true,

		menuKey = selectedmenukey
			and selectedmenukey.Name
			or Enum.KeyCode.RightShift.Name,

		keybindBlacklist = getkeybindblacklistnames(),

		theme = themeselector
			and themeselector:Get()
			or "Default",

		accent = encodecolor(accent),
		background = encodecolor(background),
		font = encodecolor(fontcolor),

		accentAlpha = accentpicker
			and accentpicker:currentalpha()
			or theme.accentAlpha,

		backgroundAlpha = backgroundpicker
			and backgroundpicker:currentalpha()
			or theme.backgroundAlpha,

		fontAlpha = fontpicker
			and fontpicker:currentalpha()
			or theme.fontAlpha,
	}
end

function currentthemepayload()
	local payload = currentuipayload()
	return {
		theme = payload.theme,
		accent = payload.accent,
		background = payload.background,
		font = payload.font,
		accentAlpha = payload.accentAlpha,
		backgroundAlpha = payload.backgroundAlpha,
		fontAlpha = payload.fontAlpha,
		backgroundImageSource = payload.backgroundImageSource,
		backgroundImageOpacity = payload.backgroundImageOpacity,
		backgroundImageBlur = payload.backgroundImageBlur,
		backgroundImageMode = "Crop",
		backgroundImageExcludeSidebar = payload.backgroundImageExcludeSidebar,
		backgroundAutoColors = payload.backgroundAutoColors,
	}
end

function saveuisettings(force)
	if loadingsettings
		or typeof(writefile) ~= "function"
	then
		return
	end

	env.__blush_save_serial =
		(env.__blush_save_serial or 0) + 1

	local serial =
		env.__blush_save_serial

	local function commit()
		if not force
			and serial ~= env.__blush_save_serial
		then
			return
		end

		local payload = currentuipayload()

		invoke(function()
			writefile(
				settingspath,
				httpservice:JSONEncode(payload)
			)
		end)
	end

	local pending = env.__blush_save_task
	if pending
		and coroutine.status(pending) == "suspended"
	then
		pcall(task.cancel, pending)
	end
	env.__blush_save_task = nil

	if force then
		commit()
	else
		env.__blush_save_task =
			task.delay(.18, function()
				if serial ~= env.__blush_save_serial then
					return
				end

				env.__blush_save_task = nil
				commit()
			end)
	end
end

env.__blush_configcontrols = env.__blush_configcontrols or {}
env.__blush_pending_controlvalues = env.__blush_pending_controlvalues or {}
env.__blush_autosave_serial = env.__blush_autosave_serial or 0
env.__blush_autosave_task = nil

function encodepersistentvalue(value)
	local kind = typeof(value)

	if kind == "Color3" then
		return {
			__blush_type = "Color3",
			r = value.R,
			g = value.G,
			b = value.B,
		}
	end

	if kind == "EnumItem" then
		return {
			__blush_type = "EnumItem",
			enum = tostring(value.EnumType),
			name = value.Name,
		}
	end

	if kind == "Instance" then
		if value:IsA("Player") then
			return {
				__blush_type = "Player",
				userId = value.UserId,
				name = value.Name,
			}
		end

		return tostring(value)
	end

	if type(value) == "table" then
		local result = {}

		for key, child in pairs(value) do
			result[tostring(key)] =
				encodepersistentvalue(child)
		end

		return result
	end

	if kind == "number"
		or kind == "string"
		or kind == "boolean"
		or kind == "nil"
	then
		return value
	end

	return tostring(value)
end

function decodepersistentvalue(value)
	if type(value) ~= "table" then
		return value
	end

	if value.__blush_type == "Color3" then
		return Color3.new(
			math.clamp(tonumber(value.r) or 1, 0, 1),
			math.clamp(tonumber(value.g) or 1, 0, 1),
			math.clamp(tonumber(value.b) or 1, 0, 1)
		)
	end

	if value.__blush_type == "EnumItem" then
		local enumname =
			tostring(value.enum or "")
				:gsub("^Enum%.", "")

		local enumtype = Enum[enumname]
		return enumtype
			and enumtype[value.name]
			or nil
	end

	if value.__blush_type == "Player" then
		local userid = tonumber(value.userId)

		if userid then
			for _, targetplayer in ipairs(players:GetPlayers()) do
				if targetplayer.UserId == userid then
					return targetplayer
				end
			end
		end

		return value.name
	end

	local result = {}

	for key, child in pairs(value) do
		result[key] =
			decodepersistentvalue(child)
	end

	return result
end

function persistentcontrolid(
	section,
	kind,
	name,
	config
)
	if type(config) == "table" then
		local explicit =
			config.Flag
			or config.SaveKey
			or config.Id
			or config.ID

		if explicit ~= nil
			and tostring(explicit) ~= ""
		then
			return tostring(explicit)
		end
	end

	local page = section and section.page
	return table.concat({
		page and tostring(page.name or page.primary or "") or "",
		section and tostring(section.name or "") or "",
		tostring(kind or "Control"),
		tostring(name or ""),
	}, "|")
end

function requestconfigautosave()
	if loadingsettings
		or not autosaveconfigcontrol
		or not autosaveconfigcontrol:Get()
		or selectedconfig == ""
		or selectedconfig == "None"
	then
		return
	end

	local pending = env.__blush_autosave_task
	if pending
		and coroutine.status(pending) == "suspended"
	then
		pcall(task.cancel, pending)
	end

	env.__blush_autosave_serial += 1
	local serial = env.__blush_autosave_serial

	env.__blush_autosave_task =
		task.delay(.22, function()
			if serial ~= env.__blush_autosave_serial then
				return
			end

			env.__blush_autosave_task = nil

			if loadingsettings
				or not autosaveconfigcontrol
				or not autosaveconfigcontrol:Get()
				or selectedconfig == ""
				or selectedconfig == "None"
			then
				return
			end

			saveconfigfile(
				selectedconfig,
				true
			)
		end)
end

function persistentcallback(callback)
	return function(...)
		if callback then
			callback(...)
		end

		requestconfigautosave()
	end
end

function registerpersistentcontrol(
	section,
	kind,
	name,
	control,
	config,
	inputcallback
)
	if not control then
		return control
	end

	local id =
		persistentcontrolid(
			section,
			kind,
			name,
			config
		)

	local anchor =
		typeof(control) == "Instance"
		and control
		or (
			control.Object
			or control.swatch
		)

	local entry = {
		id = id,
		kind = kind,
		control = control,
		anchor = anchor,
	}

	if kind == "Input"
		and control:IsA("TextBox")
	then
		entry.get = function()
			return control.Text
		end

		entry.set = function(value)
			control.Text =
				tostring(value or "")

			if inputcallback then
				inputcallback(control.Text)
			end
		end

	elseif kind == "ColorPicker"
		and type(control.color) == "function"
	then
		entry.get = function()
			return {
				color = encodepersistentvalue(
					control:color()
				),
				alpha = control.alpha,
			}
		end

		entry.set = function(value)
			if type(value) ~= "table" then
				return
			end

			local colorvalue =
				decodepersistentvalue(
					value.color
				)

			if typeof(colorvalue) ~= "Color3" then
				return
			end

			control:Set(
				colorvalue,
				math.clamp(
					tonumber(value.alpha) or 1,
					0,
					1
				),
				true
			)
		end

	elseif (
		kind == "ToggleColor"
		or kind == "ToggleColorKey"
	)
		and type(control.Get) == "function"
		and type(control.Set) == "function"
		and control.Color
		and type(control.Color.color) == "function"
	then
		entry.get = function()
			return {
				value = control:Get(),
				color = encodepersistentvalue(
					control.Color:color()
				),
				alpha = control.Color.alpha,
			}
		end

		entry.set = function(value)
			if type(value) ~= "table" then
				return
			end

			control:Set(
				value.value == true,
				true
			)

			local colorvalue =
				decodepersistentvalue(
					value.color
				)

			if typeof(colorvalue) == "Color3" then
				control.Color:Set(
					colorvalue,
					math.clamp(
						tonumber(value.alpha) or 1,
						0,
						1
					),
					true
				)
			end
		end

		control.Color.onpersist =
			requestconfigautosave

	elseif kind == "RangeSlider"
		and type(control.Get) == "function"
		and type(control.Set) == "function"
	then
		entry.get = function()
			local low, high = control:Get()

			return {
				low = low,
				high = high,
			}
		end

		entry.set = function(value)
			if type(value) == "table" then
				control:Set(
					value.low,
					value.high,
					true
				)
			end
		end

	elseif type(control.Get) == "function"
		and type(control.Set) == "function"
	then
		entry.get = function()
			return encodepersistentvalue(
				control:Get()
			)
		end

		entry.set = function(value)
			control:Set(
				decodepersistentvalue(value),
				true
			)
		end
	else
		return control
	end

	if kind == "ColorPicker" then
		control.onpersist =
			requestconfigautosave
	end

	env.__blush_configcontrols[id] = entry

	if anchor
		and anchor.Destroying
	then
		local destroying
		destroying =
			anchor.Destroying:Connect(function()
				if destroying then
					destroying:Disconnect()
					destroying = nil
				end

				if env.__blush_configcontrols[id]
					== entry
				then
					env.__blush_configcontrols[id] = nil
				end
			end)
	end

	local pending =
		env.__blush_pending_controlvalues[id]

	if pending ~= nil then
		local oldloading = loadingsettings
		loadingsettings = true

		invoke(
			entry.set,
			pending
		)

		loadingsettings = oldloading
	end

	return control
end

function currentcontrolpayload()
	local payload = {}

	for id, entry in pairs(
		env.__blush_configcontrols
	) do
		local alive =
			entry
			and entry.control
			and entry.get
			and (
				not entry.anchor
				or entry.anchor.Parent ~= nil
			)

		if alive then
			local ok, value =
				invoke(entry.get)

			if ok then
				payload[id] =
					encodepersistentvalue(value)
			end
		else
			env.__blush_configcontrols[id] = nil
		end
	end

	return payload
end

function applycontrolpayload(payload)
	env.__blush_pending_controlvalues =
		type(payload) == "table"
		and payload
		or {}

	if type(payload) ~= "table" then
		return
	end

	local oldloading = loadingsettings
	loadingsettings = true

	for id, value in pairs(payload) do
		local entry =
			env.__blush_configcontrols[id]

		if entry
			and entry.set
		then
			invoke(
				entry.set,
				decodepersistentvalue(value)
			)
		end
	end

	loadingsettings = oldloading
end

function refreshconfigfiles(preferred)
	if not configselector then
		return
	end

	local names = listjsonnames(configfolder)
	if #names == 0 then
		names = { "None" }
	end

	configselector:SetOptions(
		names,
		preferred or selectedconfig
	)
end

function refreshthemefiles(preferred)
	if not themfileselector then
		return
	end

	local names = listjsonnames(themefolder)
	if #names == 0 then
		names = { "None" }
	end

	themfileselector:SetOptions(
		names,
		preferred or selectedthemesave
	)
end

function saveconfigfile(name, autosave)
	name = sanitizefilename(name)
	if name == "" then
		return false
	end

	selectedconfig = name

	local payload =
		currentuipayload()

	payload.autoSaveConfig = nil
	payload.keybinds =
		currentkeybindpayload()
	payload.controls =
		currentcontrolpayload()

	local ok = writejsonfile(
		configfolder .. "/" .. name .. ".json",
		payload
	)

	if ok then
		if not autosave then
			if configinput then
				configinput.Text = name
			end

			refreshconfigfiles(name)
		end

		saveuisettings(true)
	end

	return ok
end

function loadconfigfile(name, silent)
	name = sanitizefilename(name)
	if name == "" or name == "None" then
		return false
	end

	local data = readjsonfile(
		configfolder .. "/" .. name .. ".json"
	)

	if not data then
		return false
	end

	selectedconfig = name
	if configinput then
		configinput.Text = name
	end
	refreshconfigfiles(name)

	local oldloading = loadingsettings
	loadingsettings = true

	applysaveduisettings(data, silent == true)
	applykeybindpayload(data.keybinds)
	applycontrolpayload(data.controls)

	loadingsettings = oldloading
	syncwindowglowcolor(false)
	saveuisettings(true)
	return true
end

function deleteconfigfile(name)
	name = sanitizefilename(name)
	if name == "" or name == "None"
		or typeof(delfile) ~= "function"
	then
		return false
	end

	local path = configfolder .. "/" .. name .. ".json"
	local ok = invoke(function()
		if typeof(isfile) ~= "function" or isfile(path) then
			delfile(path)
		end
	end)

	if ok then
		if selectedconfig == name then
			selectedconfig = ""
		end
		refreshconfigfiles()
		saveuisettings(true)
	end

	return ok
end

function applythemepayload(data)
	if typeof(data) ~= "table" then
		return false
	end

	local preset =
		type(data.theme) == "string"
		and data.theme
		or "Default"

	if not themepresets[preset] then
		preset = "Default"
	end

	local background = decodecolor(data.background) or theme.window
	local accent = decodecolor(data.accent) or theme.white
	local fontcolor = decodecolor(data.font) or theme.font
	local backgroundalpha = math.clamp(tonumber(data.backgroundAlpha) or 1, 0, 1)
	local accentalpha = math.clamp(tonumber(data.accentAlpha) or 1, 0, 1)
	local fontalpha = math.clamp(tonumber(data.fontAlpha) or 1, 0, 1)

	local oldloading = loadingsettings
	loadingsettings = true

	backgroundexcludesidebar = data.backgroundImageExcludeSidebar == true
	autobackgroundcolors = false
	setbackgroundexcludesidebar(backgroundexcludesidebar)

	if backgroundexcludecontrol then
		backgroundexcludecontrol:Set(backgroundexcludesidebar, false)
	end
	if backgroundautocolorcontrol then
		backgroundautocolorcontrol:Set(autobackgroundcolors, false)
	end

	themeselector:Set(preset, false)
	applytheme(
		background,
		accent,
		backgroundalpha,
		accentalpha,
		fontcolor,
		fontalpha,
		true
	)
	accentpicker:Set(accent, accentalpha, false)
	backgroundpicker:Set(background, backgroundalpha, false)
	fontpicker:Set(fontcolor, fontalpha, false)

	syncwindowglowcolor(false)

	local imagesource = type(data.backgroundImageSource) == "string"
		and data.backgroundImageSource
		or ""
	local imageopacity = math.clamp(tonumber(data.backgroundImageOpacity) or 65, 0, 100)
	local imageblur = math.clamp(tonumber(data.backgroundImageBlur) or 0, 0, backgroundimageblurmax)

	backgroundimagesource = imagesource
	setbackgroundimagemode("Crop")
	setbackgroundimageopacity(imageopacity, false)
	setbackgroundimageblur(imageblur, false)

	if backgroundimageinput then
		backgroundimageinput.Text = imagesource
	end
	if backgroundimageopacitycontrol then
		backgroundimageopacitycontrol:Set(imageopacity, false)
	end
	if backgroundimageblurcontrol then
		backgroundimageblurcontrol:Set(imageblur, false)
	end

	if imagesource ~= "" then
		task.spawn(function()
			loadbackgroundimage(imagesource, false, true)
		end)
	else
		clearbackgroundimage(false)
	end

	loadingsettings = oldloading
	return true
end

function savethemefile(name)
	name = sanitizefilename(name)
	if name == "" then
		return false
	end

	selectedthemesave = name
	local ok = writejsonfile(
		themefolder .. "/" .. name .. ".json",
		currentthemepayload()
	)

	if ok then
		if themefileinput then
			themefileinput.Text = name
		end
		refreshthemefiles(name)
		saveuisettings(true)
	end

	return ok
end

function loadthemefile(name)
	name = sanitizefilename(name)
	if name == "" or name == "None" then
		return false
	end

	local data = readjsonfile(
		themefolder .. "/" .. name .. ".json"
	)

	if not data or not applythemepayload(data) then
		return false
	end

	selectedthemesave = name
	if themefileinput then
		themefileinput.Text = name
	end
	refreshthemefiles(name)
	saveuisettings(true)
	return true
end

function deletethemefile(name)
	name = sanitizefilename(name)
	if name == "" or name == "None"
		or typeof(delfile) ~= "function"
	then
		return false
	end

	local path = themefolder .. "/" .. name .. ".json"
	local ok = invoke(function()
		if typeof(isfile) ~= "function" or isfile(path) then
			delfile(path)
		end
	end)

	if ok then
		if selectedthemesave == name then
			selectedthemesave = ""
		end
		refreshthemefiles()
		saveuisettings(true)
	end

	return ok
end

settingssection =
	createsection(
		settings,
		"left",
		"Interface",
		icons.settings
	)

interfaceflags = settingssection:AddRow(10, 24)

watermarktoggle = interfaceflags:AddToggle(
	"Watermark",
	savedsettings.watermark == true,
	function(value)
		setwatermarkvisible(value, true)
		saveuisettings()
	end
)

setwatermarkvisible(savedsettings.watermark == true, false)

if type(savedsettings.watermarkInfo) == "table" then
	watermarkconfig.Player =
		savedsettings.watermarkInfo.Player ~= false

	watermarkconfig.FPS =
		savedsettings.watermarkInfo.FPS ~= false

	watermarkconfig.Ping =
		savedsettings.watermarkInfo.Ping ~= false

	watermarkconfig.Time =
		savedsettings.watermarkInfo.Time ~= false

	watermarkconfig.PlayerMode =
		normalizewatermarkplayermode(
			savedsettings.watermarkInfo.PlayerMode
		)
end

watermarkinfodefault = {}

for _, item in ipairs({
	"Player",
	"Fps",
	"Ping",
	"Time",
}) do
	local enabled =
		item == "Fps"
			and watermarkconfig.FPS
			or watermarkconfig[item]

	if enabled then
		table.insert(
			watermarkinfodefault,
			item
		)
	end
end

watermarkinfocontrol =
	settingssection:AddMultiDropdown(
		"Watermark info",
		{
			"Player",
			"Fps",
			"Ping",
			"Time",
		},
		watermarkinfodefault,
		function(values)
			local selected = {}

			for _, value in ipairs(values) do
				selected[value] = true
			end

			watermarkconfig.Player =
				selected.Player == true

			watermarkconfig.FPS =
				selected.Fps == true

			watermarkconfig.Ping =
				selected.Ping == true

			watermarkconfig.Time =
				selected.Time == true

			updatewatermarklayout()
			saveuisettings()
		end
	)

watermarkplayermodecontrol =
	settingssection:AddRadio(
		"Player name",
		{
			"Display",
			"Username",
			"Both",
		},
		normalizewatermarkplayermode(
			watermarkconfig.PlayerMode
		),
		function(value)
			watermarkconfig.PlayerMode =
				normalizewatermarkplayermode(value)

			updatewatermarklayout()
			saveuisettings()
		end
	)

updatewatermarklayout()

animationtoggle = interfaceflags:AddToggle(
	"Animations",
	animationsenabled,
	function(value)
		animationsenabled = value == true

		if animationsenabled then
			if updatetopnavigationstate then
				updatetopnavigationstate(false)
			end
			if refreshhotkeylist then
				refreshhotkeylist()
			end
		end

		saveuisettings()
	end
)

interfaceflags2 = settingssection:AddRow(10, 24)

searchtoggle = interfaceflags2:AddToggle(
	"Search",
	searchenabled,
	function(value)
		setsearchvisible(value, true)

		if not searchenabled then
			search.Text = ""
		end

		saveuisettings()
	end
)

setsearchvisible(searchenabled, false)

notificationtoggle = interfaceflags2:AddToggle(
	"Notifications",
	notificationsenabled,
	function(value)
		notificationsenabled = value
		saveuisettings()
	end
)

interfaceflags3 = settingssection:AddRow(10, 24)

hotkeylisttoggle = interfaceflags3:AddToggle(
	"Keybinds",
	savedsettings.hotkeyList == true
		or savedsettings.checkboxList == true,
	function(value)
		sethotkeylistvisible(value)
		saveuisettings()
	end
)

sethotkeylistvisible(
	savedsettings.hotkeyList == true
		or savedsettings.checkboxList == true
)

topnavigationtoggle = interfaceflags3:AddToggle(
	"Top navigation",
	topnavigationenabled,
	function(value)
		topnavigationenabled = value == true
		if applytopnavigation then
			applytopnavigation(topnavigationenabled, true)
		end
		saveuisettings()
	end
)

minimizebuttoncontrol = settingssection:AddToggle(
	"Minimize button",
	savedsettings.minimizeButton ~= false,
	function(value)
		setminimizebuttonvisible(value, true)
		saveuisettings()
	end
)

setminimizebuttonvisible(savedsettings.minimizeButton ~= false, false)

menukeypicker = settingssection:AddKeyPicker(
	"Menu key",
	menukey,
	function(key)
		menukey = key
		refreshmenukeybinding()
		saveuisettings()
	end
)

keybindblacklistcontrol = settingssection:AddMultiDropdown(
	"Blacklisted keys",
	keybindblacklistoptions,
	getkeybindblacklistlabels(),
	function(values)
		setkeybindblacklist(values)
		saveuisettings()
	end
)

windowglowtoggle = settingssection:AddToggleColor(
	"Window glow",
	windowglowenabled,
	windowglowcolor,
	function(value)
		windowglowenabled = value == true
		applywindowglow()
		saveuisettings()
	end,
	function(color, alpha)
		windowglowcolor = color
		windowglowrenderalpha = math.clamp(
			tonumber(alpha) or 1,
			0,
			1
		)

		if not windowglowcolorpicker
			or (
				not windowglowcolorpicker.fading
				and not windowglowcolorpicker.rainbow
			)
		then
			windowglowalpha =
				windowglowcolorpicker
				and windowglowcolorpicker.alpha
				or windowglowrenderalpha

			saveuisettings()
		end

		applywindowglow()
	end
)

windowglowcolorpicker = windowglowtoggle.Color
windowglowcolorpicker:Set(
	windowglowcolor,
	windowglowalpha,
	false
)
windowglowrenderalpha =
	windowglowcolorpicker:currentalpha()
applywindowglow()

windowglowintensitycontrol = settingssection:AddSlider(
	"Glow intensity",
	0,
	100,
	windowglowintensity,
	"%",
	function(value)
		windowglowintensity = value
		applywindowglow()
		saveuisettings()
	end
)

windowglowsizecontrol = settingssection:AddSlider(
	"Glow size",
	0,
	24,
	windowglowsize,
	"px",
	function(value)
		windowglowsize = value
		applywindowglow()
		saveuisettings()
	end
)

uitransparencycontrol = settingssection:AddSlider(
	"Transparency",
	0,
	90,
	initialtransparency,
	"%",
	function(value)
		applyuitransparency(value)
		saveuisettings()
	end
)

applyuitransparency(initialtransparency)

themessection =
	createsection(
		settings,
		"right",
		"Themes",
		icons.palette
	)

themepresets = {
	Default = {
		background = Color3.fromRGB(13, 13, 15),
		accent = Color3.fromRGB(246, 246, 248),
		font = Color3.fromRGB(235, 235, 239),
	},

	Dark = {
		background = Color3.fromRGB(9, 10, 12),
		accent = Color3.fromRGB(190, 198, 210),
		font = Color3.fromRGB(226, 229, 234),
	},

	Violet = {
		background = Color3.fromRGB(14, 12, 19),
		accent = Color3.fromRGB(185, 157, 255),
		font = Color3.fromRGB(239, 235, 247),
	},

	Rose = {
		background = Color3.fromRGB(18, 11, 14),
		accent = Color3.fromRGB(247, 147, 177),
		font = Color3.fromRGB(245, 236, 240),
	},

	Mint = {
		background = Color3.fromRGB(10, 16, 14),
		accent = Color3.fromRGB(125, 222, 176),
		font = Color3.fromRGB(232, 242, 237),
	},

	Snow = {
		background = Color3.fromRGB(242, 243, 246),
		accent = Color3.fromRGB(47, 51, 59),
		font = Color3.fromRGB(28, 31, 36),
	},

	Pearl = {
		background = Color3.fromRGB(229, 231, 235),
		accent = Color3.fromRGB(67, 72, 82),
		font = Color3.fromRGB(34, 37, 43),
	},

	Ivory = {
		background = Color3.fromRGB(243, 238, 229),
		accent = Color3.fromRGB(101, 82, 66),
		font = Color3.fromRGB(52, 45, 40),
	},
}

themeoptions = {
	"Default",
	"Dark",
	"Violet",
	"Rose",
	"Mint",
	"Snow",
	"Pearl",
	"Ivory",
}

themecolors = {}

for name, preset in pairs(themepresets) do
	themecolors[name] = preset.accent
end

-- Neutral preview swatches keep Default and Dark visually distinct in the picker.
themecolors.Default = Color3.fromRGB(176, 178, 184)
themecolors.Dark = Color3.fromRGB(58, 60, 68)

themeselector = themessection:AddDropdown(
	"Theme",
	themeoptions,
	"Default",
	function(name)
		local preset = themepresets[name]

		if not preset then
			saveuisettings()
			return
		end

		applytheme(
			preset.background,
			preset.accent,
			1,
			1,
			preset.font,
			1,
			true
		)

		if accentpicker then
			accentpicker:Set(preset.accent, 1, false)
		end

		if backgroundpicker then
			backgroundpicker:Set(preset.background, 1, false)
		end

		if fontpicker then
			fontpicker:Set(preset.font, 1, false)
		end

		if autobackgroundcolors then
			backgroundautobase = {
				background = preset.background,
				accent = preset.accent,
				font = preset.font,
				backgroundAlpha = 1,
				accentAlpha = 1,
				fontAlpha = 1,
			}

			if backgroundpalette then
				applybackgroundautocolors(true)
			elseif backgroundimage and backgroundimage.Image ~= "" then
				task.spawn(function()
					samplebackgroundpalette(backgroundimage.Image)
				end)
			end
		end

		saveuisettings()
	end,
	nil,
	{
		dividers = {
			Snow = "Light themes",
		},
		colors = themecolors,
	}
)

accentpicker = themessection:AddColorPicker(
	"Accent",
	theme.white,
	function(color, alpha)
		if autobackgroundcolors and not loadingsettings then
			autobackgroundcolors = false
			backgroundautobase = nil
			if backgroundautocolorcontrol then
				backgroundautocolorcontrol:Set(false, false)
			end
		end
		applytheme(
			theme.window,
			color,
			theme.backgroundAlpha,
			alpha,
			theme.font,
			theme.fontAlpha
		)
		saveuisettings()
	end
)

backgroundpicker = themessection:AddColorPicker(
	"Background",
	theme.window,
	function(color, alpha)
		if autobackgroundcolors and not loadingsettings then
			autobackgroundcolors = false
			backgroundautobase = nil
			if backgroundautocolorcontrol then
				backgroundautocolorcontrol:Set(false, false)
			end
		end
		applytheme(
			color,
			theme.white,
			alpha,
			theme.accentAlpha,
			theme.font,
			theme.fontAlpha
		)
		saveuisettings()
	end
)

fontpicker = themessection:AddColorPicker(
	"Font color",
	theme.font,
	function(color, alpha)
		if autobackgroundcolors and not loadingsettings then
			autobackgroundcolors = false
			backgroundautobase = nil
			if backgroundautocolorcontrol then
				backgroundautocolorcontrol:Set(false, false)
			end
		end
		applytheme(
			theme.window,
			theme.white,
			theme.backgroundAlpha,
			theme.accentAlpha,
			color,
			alpha
		)
		saveuisettings()
	end
)

themefileinput = themessection:AddInput(
	"Theme name",
	selectedthemesave,
	"name",
	function(value)
		themefileinput.Text = sanitizefilename(value)
	end
)

themfileselector = themessection:AddDropdown(
	"Saved themes",
	{ "None" },
	"None",
	function(name)
		if name ~= "None" then
			selectedthemesave = sanitizefilename(name)
			themefileinput.Text = selectedthemesave
			saveuisettings(true)
		end
	end,
	nil,
	{ searchable = true }
)

refreshthemefiles(selectedthemesave)

themefileactions = themessection:AddRow(8, 32)

themefileactions:AddButton(
	"Load",
	function()
		local name = themfileselector:Get()
		local ok = loadthemefile(name)
		notify(
			ok and "Loaded" or "Unavailable",
			ok and "Theme loaded." or "Select a saved theme.",
			2.4,
			nil, nil, icons.palette
		)
	end
)

themefileactions:AddButton(
	"Save",
	function()
		local ok = savethemefile(themefileinput.Text)
		notify(
			ok and "Saved" or "Invalid name",
			ok and "Theme saved." or "Enter a valid theme name.",
			2.4,
			nil, nil, icons.palette
		)
	end
)

themessection:AddButton(
	"Delete",
	function()
		local name = themfileselector:Get()
		local ok = deletethemefile(name)
		notify(
			ok and "Deleted" or "Unavailable",
			ok and "Theme file deleted." or "Select a saved theme.",
			2.4,
			nil, nil, icons.wrench
		)
	end
)

backgroundimagesection =
	createsection(
		settings,
		"right",
		"Background Image",
		icons.wallpaper
	)

backgroundimageinput = backgroundimagesection:AddInput(
	"Source",
	backgroundimagesource,
	"URL, file path or asset id",
	function(value)
		backgroundimageinput.Text = trimbackgroundsource(value)
	end
)

backgroundimageopacitycontrol = backgroundimagesection:AddSlider(
	"Image opacity",
	0,
	100,
	backgroundimageopacity,
	"%",
	function(value)
		setbackgroundimageopacity(value, true)
		saveuisettings()
	end
)

backgroundimageblurcontrol = backgroundimagesection:AddSlider(
	"Image blur",
	0,
	backgroundimageblurmax,
	math.round(backgroundimageblur),
	" px",
	function(value)
		local rounded = math.round(value)
		if backgroundimageblurcontrol
			and math.abs(value - rounded) > .001
		then
			backgroundimageblurcontrol:Set(rounded, false)
		end
		setbackgroundimageblur(rounded, true)
		saveuisettings()
	end
)

backgroundimageoptions = backgroundimagesection:AddRow(8, 24)

backgroundexcludecontrol = backgroundimageoptions:AddToggle(
	"Exclude sidebar",
	backgroundexcludesidebar,
	function(value)
		setbackgroundexcludesidebar(value)
		saveuisettings()
	end
)

backgroundautocolorcontrol = nil

backgroundimageactions = backgroundimagesection:AddRow(8, 32)

backgroundapplytoken = 0

function applybackgroundsource()
	local source = trimbackgroundsource(backgroundimageinput.Text)
	backgroundimageinput.Text = source

	backgroundapplytoken += 1
	local token = backgroundapplytoken

	if source == "" then
		clearbackgroundimage(true)
		saveuisettings(true)
		return
	end

	task.spawn(function()
		local ok = loadbackgroundimage(source, true, false)
		if token ~= backgroundapplytoken then
			return
		end

		if ok then
			backgroundimageinput.Text = source
			saveuisettings(true)
		end
	end)
end

backgroundimageinput.FocusLost:Connect(function(enterpressed)
	if enterpressed then
		applybackgroundsource()
	end
end)

backgroundimageactions:AddButton(
	"Apply",
	applybackgroundsource
)

backgroundimageactions:AddButton(
	"Clear",
	function()
		backgroundimageinput.Text = ""
		clearbackgroundimage(true)
		saveuisettings(true)
	end
)

savessection =
	createsection(
		settings,
		"left",
		"Configs",
		icons.wrench
	)

configinput = savessection:AddInput(
	"Config name",
	selectedconfig,
	"name",
	function(value)
		configinput.Text = sanitizefilename(value)
	end
)

configselector = savessection:AddDropdown(
	"Saved configs",
	{ "None" },
	"None",
	function(name)
		if name ~= "None" then
			selectedconfig = sanitizefilename(name)
			configinput.Text = selectedconfig
			saveuisettings(true)
		end
	end,
	nil,
	{ searchable = true }
)

refreshconfigfiles(selectedconfig)

configactions = savessection:AddRow(8, 32)

configactions:AddButton(
	"Load",
	function()
		local name = configselector:Get()
		local ok = loadconfigfile(name, true)
		notify(
			ok and "Loaded" or "Unavailable",
			ok and "Configuration loaded." or "Select a saved config.",
			2.4,
			nil, nil, icons.settings
		)
	end
)

configactions:AddButton(
	"Save",
	function()
		local ok = saveconfigfile(configinput.Text)
		notify(
			ok and "Saved" or "Invalid name",
			ok and "Configuration saved." or "Enter a valid config name.",
			2.4,
			nil, nil, icons.settings
		)
	end
)

savessection:AddButton(
	"Delete",
	function()
		local name = configselector:Get()
		local ok = deleteconfigfile(name)
		notify(
			ok and "Deleted" or "Unavailable",
			ok and "Configuration file deleted." or "Select a saved config.",
			2.4,
			nil, nil, icons.wrench
		)
	end
)

new("Frame", {
	Parent = savessection.body,
	Size = UDim2.new(1, 0, 0, 6),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
})

autosaveconfigcontrol = savessection:AddToggle(
	"Auto save",
	rawsavedsettings.autoSaveConfig == true,
	function()
		saveuisettings(true)
	end
)

function applysaveduisettings(data, silent)
	if typeof(data) ~= "table" then
		return
	end

	local wasloading = loadingsettings
	loadingsettings = true

	local loadedtransparency = math.clamp(
		tonumber(data.uiTransparency) or 0,
		0,
		90
	)

	if uitransparencycontrol then
		uitransparencycontrol:Set(loadedtransparency, false)
	end

	applyuitransparency(loadedtransparency)

	if watermarktoggle then
		watermarktoggle:Set(data.watermark == true, true)
	end

	if type(data.watermarkInfo) == "table" then
		watermarkconfig.Player =
			data.watermarkInfo.Player ~= false

		watermarkconfig.FPS =
			data.watermarkInfo.FPS ~= false

		watermarkconfig.Ping =
			data.watermarkInfo.Ping ~= false

		watermarkconfig.Time =
			data.watermarkInfo.Time ~= false

		watermarkconfig.PlayerMode =
			normalizewatermarkplayermode(
				data.watermarkInfo.PlayerMode
				or watermarkconfig.PlayerMode
			)
	end

	if watermarkinfocontrol then
		local values = {}

		for _, item in ipairs({
			"Player",
			"Fps",
			"Ping",
			"Time",
		}) do
			local enabled =
				item == "Fps"
					and watermarkconfig.FPS
					or watermarkconfig[item]

			if enabled then
				table.insert(values, item)
			end
		end

		watermarkinfocontrol:Set(
			values,
			false
		)
	end

	if watermarkplayermodecontrol then
		watermarkplayermodecontrol:Set(
			normalizewatermarkplayermode(
				watermarkconfig.PlayerMode
			),
			false
		)
	end

	updatewatermarklayout()

	if animationtoggle then
		animationtoggle:Set(data.animations ~= false, true)
	end

	if searchtoggle then
		searchtoggle:Set(data.searchCurrentPage ~= false, true)
	end

	if notificationtoggle then
		notificationtoggle:Set(data.notifications ~= false, true)
	end

	if hotkeylisttoggle then
		local visible = data.hotkeyList == true
			or data.checkboxList == true

		hotkeylisttoggle:Set(visible, true)
		sethotkeylistvisible(visible)
	end

	if data.minimizeButton ~= nil then
		setminimizebuttonvisible(data.minimizeButton == true, true)

		if minimizebuttoncontrol then
			minimizebuttoncontrol:Set(
				windowminimizebuttonenabled,
				false
			)
		end
	end

	backgroundexcludesidebar = data.backgroundImageExcludeSidebar == true
	autobackgroundcolors = false
	topnavigationenabled = data.topNavigation == true

	if backgroundexcludecontrol then
		backgroundexcludecontrol:Set(backgroundexcludesidebar, false)
	end
	if backgroundautocolorcontrol then
		backgroundautocolorcontrol:Set(autobackgroundcolors, false)
	end
	if topnavigationtoggle then
		topnavigationtoggle:Set(topnavigationenabled, false)
	end

	windowglowenabled = data.windowGlow ~= false
	windowglowintensity = math.clamp(
		tonumber(data.windowGlowIntensity) or 16,
		0,
		100
	)
	windowglowsize = math.clamp(
		tonumber(data.windowGlowSize) or 10,
		0,
		24
	)
	windowglowcolor = theme.white
	windowglowalpha = math.clamp(
		tonumber(data.windowGlowAlpha) or windowglowalpha or 1,
		0,
		1
	)
	windowglowrenderalpha = windowglowalpha

	if windowglowtoggle then
		windowglowtoggle:Set(windowglowenabled, false)
	end
	if windowglowintensitycontrol then
		windowglowintensitycontrol:Set(windowglowintensity, false)
	end
	if windowglowsizecontrol then
		windowglowsizecontrol:Set(windowglowsize, false)
	end
	if windowglowcolorpicker then
		windowglowcolorpicker:Set(
			windowglowcolor,
			windowglowalpha,
			false
		)

		windowglowrenderalpha =
			windowglowcolorpicker:currentalpha()
	end

	applywindowglow()
	setbackgroundexcludesidebar(backgroundexcludesidebar)
	if applytopnavigation then
		applytopnavigation(topnavigationenabled, false)
	end

	local loadedimagesource = type(data.backgroundImageSource) == "string"
		and data.backgroundImageSource
		or ""
	local loadedimageopacity = math.clamp(tonumber(data.backgroundImageOpacity) or 65, 0, 100)
	local loadedimageblur = math.clamp(tonumber(data.backgroundImageBlur) or 0, 0, backgroundimageblurmax)

	backgroundimagesource = loadedimagesource
	setbackgroundimagemode("Crop")
	setbackgroundimageopacity(loadedimageopacity, false)
	setbackgroundimageblur(loadedimageblur, false)

	if backgroundimageinput then
		backgroundimageinput.Text = loadedimagesource
	end
	if backgroundimageopacitycontrol then
		backgroundimageopacitycontrol:Set(loadedimageopacity, false)
	end
	if backgroundimageblurcontrol then
		backgroundimageblurcontrol:Set(loadedimageblur, false)
	end

	setkeybindblacklist(
		type(data.keybindBlacklist) == "table"
			and data.keybindBlacklist
			or keybindblacklistdefaults
	)

	if keybindblacklistcontrol then
		keybindblacklistcontrol:Set(
			getkeybindblacklistlabels(),
			false
		)
	end

	if menukeypicker then
		menukeypicker:Set(
			keyfromname(data.menuKey)
				or Enum.KeyCode.RightShift,
			true
		)
	end

	local selectedtheme =
		type(data.theme) == "string"
		and data.theme
		or "Default"

	if selectedtheme == "Monochrome"
		or selectedtheme == "OLED"
		or selectedtheme == "Black"
	then
		selectedtheme = "Default"
	elseif selectedtheme == "Graphite" then
		selectedtheme = "Dark"
	end

	if themepresets[selectedtheme] then
		themeselector:Set(selectedtheme, true)
	else
		themeselector:Set("Default", true)
	end

	local loadedbackground = decodecolor(data.background) or theme.window
	local loadedaccent = decodecolor(data.accent) or theme.white
	local loadedfont = decodecolor(data.font) or theme.font
	local loadedbackgroundalpha = math.clamp(tonumber(data.backgroundAlpha) or 1, 0, 1)
	local loadedaccentalpha = math.clamp(tonumber(data.accentAlpha) or 1, 0, 1)
	local loadedfontalpha = math.clamp(tonumber(data.fontAlpha) or 1, 0, 1)

	applytheme(
		loadedbackground,
		loadedaccent,
		loadedbackgroundalpha,
		loadedaccentalpha,
		loadedfont,
		loadedfontalpha,
		true
	)

	accentpicker:Set(loadedaccent, loadedaccentalpha, false)
	backgroundpicker:Set(loadedbackground, loadedbackgroundalpha, false)
	fontpicker:Set(loadedfont, loadedfontalpha, false)

	syncwindowglowcolor(false)

	if windowglowcolorpicker then
		windowglowcolorpicker:Set(
			theme.white,
			windowglowalpha,
			false
		)

		windowglowrenderalpha =
			windowglowcolorpicker:currentalpha()
	end

	syncwindowglowcolor(false)

	backgroundpalette = nil
	if loadedimagesource ~= "" then
		task.spawn(function()
			loadbackgroundimage(loadedimagesource, false, true)
		end)
	else
		clearbackgroundimage(false)
	end

	loadingsettings = wasloading

	if not silent then
		notify(
			"Loaded",
			"Interface configuration loaded.",
			2.5,
			nil,
			nil,
			icons.settings
		)
	end
end

savedtheme = "Default"

themeselector:Set("Default", false)

do
	local preset = themepresets.Default

	applytheme(
		preset.background,
		preset.accent,
		1,
		1,
		preset.font,
		1,
		false
	)

	accentpicker:Set(preset.accent, 1, false)
	backgroundpicker:Set(preset.background, 1, false)
	fontpicker:Set(preset.font, 1, false)
end

if backgroundimagesource ~= "" then
	task.spawn(function()
		loadbackgroundimage(backgroundimagesource, false, true)
	end)
end

loadingsettings = false

env.__blush_visibility_busy = false
env.__blush_visibility_token = 0
env.__blush_windowvisible = true
env.__blush_fadeanimations = {}

function cancelreopenanimations()
	for _, animation in ipairs(env.__blush_reopenanimations or {}) do
		invoke(function()
			animation:Cancel()
		end)
	end

	env.__blush_reopenanimations = {}
end

function animatereopenbutton(show, token)
	cancelreopenanimations()
	env.__blush_reopen_fading = true
	reopenbutton.Active = false

	local normalbackground =
		effectivetransparency(.04, "window")
	local normaltext = effectivefontalpha(0)
	local normalstroke = .62
	local normalshadow = .58

	if show then
		reopengui.Enabled = true
		reopenbutton.BackgroundTransparency = 1
		reopenlabel.TextTransparency = 1
		reopenarrow.ImageTransparency = 1

		if reopenstroke then
			reopenstroke.Transparency = 1
		end

		if reopenshadow then
			reopenshadow.Transparency = 1
		end
	end

	local info = TweenInfo.new(
		.18,
		Enum.EasingStyle.Quint,
		Enum.EasingDirection.Out
	)

	local targets = {
		{reopenbutton, {BackgroundTransparency = show and normalbackground or 1}},
		{reopenlabel, {TextTransparency = show and normaltext or 1}},
	}

	if reopenstroke then
		targets[#targets + 1] = {
			reopenstroke,
			{Transparency = show and normalstroke or 1},
		}
	end

	if reopenshadow then
		targets[#targets + 1] = {
			reopenshadow,
			{Transparency = show and normalshadow or 1},
		}
	end

	if not animationsenabled then
		for _, entry in ipairs(targets) do
			if entry[1] and entry[1].Parent then
				for property, value in pairs(entry[2]) do
					entry[1][property] = value
				end
			end
		end

		env.__blush_reopen_fading = false
		if show then
			reopenbutton.Active = true
		else
			reopengui.Enabled = false
		end
		return
	end

	local primary
	for _, entry in ipairs(targets) do
		if entry[1] and entry[1].Parent then
			local animation = tweenservice:Create(
				entry[1],
				info,
				entry[2]
			)
			env.__blush_reopenanimations[#env.__blush_reopenanimations + 1] = animation
			primary = primary or animation
			animation:Play()
		end
	end

	if not primary then
		env.__blush_reopen_fading = false
		reopengui.Enabled = show
		reopenbutton.Active = show
		return
	end

	primary.Completed:Connect(function()
		if env.__blush_visibility_token ~= token then
			return
		end

		env.__blush_reopen_fading = false

		if show then
			reopenbutton.Active = true
		else
			reopengui.Enabled = false
		end
	end)
end

function cancelvisibilityanimations()
	for _, animation in ipairs(env.__blush_fadeanimations or {}) do
		invoke(function()
			animation:Cancel()
		end)
	end

	env.__blush_fadeanimations = {}
end

function setvisibilityrootsvisible(value)
	if shell and shell.Parent then
		shell.Visible = value
	end

	if popuplayer and popuplayer.Parent then
		popuplayer.Visible = value
	end

	if draglayer and draglayer.Parent then
		draglayer.Visible = value
	end
end

function playvisibilityfade(show, token)
	env.__blush_windowvisible = show

	if show then
		setvisibilityrootsvisible(true)
		forcecursorvisible()
		animatereopenbutton(false, token)
	else
		reopengui.Enabled = false
	end

	cancelvisibilityanimations()

	local info = TweenInfo.new(
		.18,
		Enum.EasingStyle.Quint,
		Enum.EasingDirection.Out
	)

	local roots = {
		{window, show and uitransparency or 1},
		{popuplayer, show and uitransparency or 1},
		{draglayer, show and 0 or 1},
	}

	local extras = {}

	if windowstroke and windowstroke.Parent then
		extras[#extras + 1] = {
			windowstroke,
			show and .76 or 1,
		}
	end

	if windowshadow and windowshadow.Parent then
		local base = windowshadowenabled
			and (windowshadow:GetAttribute("BlushBaseTransparency") or .40)
			or 1

		extras[#extras + 1] = {
			windowshadow,
			show and base or 1,
		}
	end

	if windowglow and windowglow.Parent then
		local base = windowglowenabled
			and (windowglow:GetAttribute("BlushBaseTransparency") or windowglow.Transparency)
			or 1

		extras[#extras + 1] = {
			windowglow,
			show and base or 1,
		}
	end

	if not animationsenabled then
		for _, entry in ipairs(roots) do
			local object = entry[1]
			if object and object.Parent then
				object.GroupTransparency = entry[2]
			end
		end

		for _, entry in ipairs(extras) do
			local object = entry[1]
			if object and object.Parent then
				object.Transparency = entry[2]
			end
		end

		if show then
			setvisibilityrootsvisible(true)
		else
			setvisibilityrootsvisible(false)
			restorecursorstate()
			animatereopenbutton(true, token)
		end

		env.__blush_visibility_busy = false
		return
	end

	local primary = nil

	for _, entry in ipairs(roots) do
		local object = entry[1]
		local target = entry[2]

		if object and object.Parent then
			local animation = tweenservice:Create(
				object,
				info,
				{GroupTransparency = target}
			)

			table.insert(env.__blush_fadeanimations, animation)
			primary = primary or animation
			animation:Play()
		end
	end

	for _, entry in ipairs(extras) do
		local object = entry[1]
		local target = entry[2]

		if object and object.Parent then
			local animation = tweenservice:Create(
				object,
				info,
				{Transparency = target}
			)

			table.insert(env.__blush_fadeanimations, animation)
			primary = primary or animation
			animation:Play()
		end
	end

	local function finish()
		if env.__blush_visibility_token ~= token then
			return
		end

		for _, entry in ipairs(roots) do
			local object = entry[1]
			if object and object.Parent then
				object.GroupTransparency = entry[2]
			end
		end

		for _, entry in ipairs(extras) do
			local object = entry[1]
			if object and object.Parent then
				object.Transparency = entry[2]
			end
		end

		if show then
			setvisibilityrootsvisible(true)
		else
			setvisibilityrootsvisible(false)
			restorecursorstate()
			animatereopenbutton(true, token)
		end

		env.__blush_visibility_busy = false
		env.__blush_fadeanimations = {}
	end

	if primary then
		primary.Completed:Connect(finish)
	else
		finish()
	end
end

function requestvisibilitytoggle(target)
	local show = target == nil
		and not env.__blush_windowvisible
		or target == true

	if show == env.__blush_windowvisible
		and not env.__blush_visibility_busy
	then
		return
	end

	env.__blush_visibility_busy = true
	env.__blush_visibility_token += 1

	local token = env.__blush_visibility_token
	closepopup()
	closemodal()
	playvisibilityfade(show, token)
end

function refreshmenukeybinding()
	contextactionservice:UnbindAction("__blush_menu_key")

	if menukey ~= Enum.KeyCode.Tab then
		return
	end

	contextactionservice:BindActionAtPriority(
		"__blush_menu_key",
		function(_, inputstate)
			if inputstate == Enum.UserInputState.Begin
				and not keypickercapturing
				and keypickersuppress ~= menukey
			then
				requestvisibilitytoggle()
			end

			return Enum.ContextActionResult.Sink
		end,
		false,
		Enum.ContextActionPriority.High.Value + 1000,
		Enum.KeyCode.Tab
	)
end

connect(
	uis.InputBegan,
	function(input)
		if menukey == Enum.KeyCode.Tab
			or keypickercapturing
			or bindingmatchesinput(keypickersuppress, input)
		then
			return
		end

		if bindingmatchesinput(menukey, input) then
			requestvisibilitytoggle()
		end
	end
)

refreshmenukeybinding()


-- mobile adaptive layout

mobilepanelopen = uis.TouchEnabled
mobilecolumn = "left"
mobileisnarrow = false
mobileuiscale = 1
mobilelogicalsize = Vector2.new(0, 0)

mobilemenubutton = new("ImageButton", {
	Parent = header,
	AnchorPoint = Vector2.new(0, .5),
	Position = UDim2.fromOffset(10, 31),
	Size = UDim2.fromOffset(38, 38),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Image = icons.menu,
	ImageColor3 = theme.text2,
	AutoButtonColor = false,
	Visible = uis.TouchEnabled,
	ZIndex = 18,
})

mobilecolumnbutton = new("ImageButton", {
	Parent = header,
	AnchorPoint = Vector2.new(1, .5),
	Position = UDim2.new(1, -174, .5, 0),
	Size = UDim2.fromOffset(36, 36),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Image = icons.columns2,
	ImageColor3 = theme.text3,
	AutoButtonColor = false,
	Visible = false,
	ZIndex = 18,
})

mobilesideclose = new("ImageButton", {
	Parent = sidebar,
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -13, 0, 17),
	Size = UDim2.fromOffset(42, 42),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Image = icons.right,
	ImageColor3 = theme.text2,
	Rotation = 180,
	AutoButtonColor = false,
	Visible = uis.TouchEnabled,
	ZIndex = 30,
})

function applymobiletextscale(scale)
	if not uis.TouchEnabled then
		return
	end

	mobilefontscale = math.clamp(scale or 1, .52, .68)

	for _, root in ipairs({gui, watermarkgui, reopengui}) do
		if root then
			for _, object in ipairs(root:GetDescendants()) do
				registermobiletext(object)
			end
		end
	end
end

function applymobilecolumns()
	if not uis.TouchEnabled then
		return
	end

	for _, targetpage in pairs(pages) do
		targetpage.frame.Size = UDim2.fromScale(1, 1)
		targetpage.mobilelayoutactive = true

		if not targetpage.mobilelayout
			or not targetpage.mobilelayout.Parent
		then
			targetpage.mobilelayout = new("UIListLayout", {
				Parent = targetpage.left,
				Padding = UDim.new(0, 10),
				SortOrder = Enum.SortOrder.LayoutOrder,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
			})
		end

		if not targetpage.mobilepadding
			or not targetpage.mobilepadding.Parent
		then
			targetpage.mobilepadding = new("UIPadding", {
				Parent = targetpage.left,
				PaddingBottom = UDim.new(0, 34),
			})
		end

		targetpage.left.AnchorPoint = Vector2.zero
		targetpage.left.Position = UDim2.fromOffset(0, 0)
		targetpage.left.Size = UDim2.fromScale(1, 1)
		targetpage.left.Visible = true
		targetpage.left.AutomaticCanvasSize = Enum.AutomaticSize.Y
		targetpage.left.CanvasSize = UDim2.fromOffset(0, 0)
		targetpage.left.ScrollingDirection = Enum.ScrollingDirection.Y
		targetpage.left.ScrollBarThickness = 0
		targetpage.left.ElasticBehavior = Enum.ElasticBehavior.Never

		targetpage.right.Visible = false
		targetpage.right.CanvasPosition = Vector2.new(0, 0)
		targetpage.right.AutomaticCanvasSize = Enum.AutomaticSize.None

		for _, section in ipairs(targetpage.sections) do
			section.originalcolumn = section.originalcolumn or section.column
			section.column = "left"
			section.frame.Parent = targetpage.left
			section.frame.LayoutOrder = section.order
			section.frame.Position = UDim2.fromOffset(0, 0)

			if section.RefreshMobileLayout then
				section:RefreshMobileLayout()
			end
		end

		targetpage:reflow("left", false)
	end

	mobilecolumnbutton.Visible = false

	for _, targetpage in pairs(pages) do
		for _, section in ipairs(targetpage.sections) do
			if section.RefreshMobileLayout then
				section:RefreshMobileLayout()
			end
		end

		targetpage:reflow("left", false)
	end
end

function setmobilepanel(open)
	if not uis.TouchEnabled then
		return
	end

	mobilepanelopen = open == true
	env.__blush_mobilepanelopen = mobilepanelopen

	sidebar.Visible = mobilepanelopen
	main.Visible = not mobilepanelopen

	mobilemenubutton.Visible = not mobilepanelopen
	mobilesideclose.Visible = mobilepanelopen
	mobilecolumnbutton.Visible = false

	updatebackgroundbounds()

	if not mobilepanelopen then
		applymobilecolumns()

		if topnavigationenabled
			and updatetopnavigationstate
		then
			updatetopnavigationstate(false)
		end
	end
end

function clampmobilewindow()
	if not uis.TouchEnabled
		or not shell
		or not shell.Parent
	then
		return
	end

	local rootsize = gui.AbsoluteSize
	local size = shell.AbsoluteSize

	if rootsize.X <= 0
		or rootsize.Y <= 0
		or size.X <= 0
		or size.Y <= 0
	then
		return
	end

	local margin = 6
	local anchor = shell.AnchorPoint

	local position = Vector2.new(
		shell.Position.X.Scale * rootsize.X
			+ shell.Position.X.Offset,
		shell.Position.Y.Scale * rootsize.Y
			+ shell.Position.Y.Offset
	)

	local minx =
		size.X * anchor.X + margin

	local maxx =
		rootsize.X
		- size.X * (1 - anchor.X)
		- margin

	local miny =
		size.Y * anchor.Y + margin

	local maxy =
		rootsize.Y
		- size.Y * (1 - anchor.Y)
		- margin

	position = Vector2.new(
		math.clamp(
			position.X,
			math.min(minx, maxx),
			math.max(minx, maxx)
		),
		math.clamp(
			position.Y,
			math.min(miny, maxy),
			math.max(miny, maxy)
		)
	)

	shell.Position = UDim2.fromOffset(
		math.floor(position.X + .5),
		math.floor(position.Y + .5)
	)
end

function fitmobilewindow()
	if not uis.TouchEnabled then
		return
	end

	gui.IgnoreGuiInset = false
	gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	watermarkgui.IgnoreGuiInset = false
	watermarkgui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets

	if reopengui then
		reopengui.IgnoreGuiInset = false
		reopengui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	end

	if env.__blush_shellscale
		and env.__blush_shellscale.Parent
	then
		env.__blush_shellscale.Scale = 1
	end

	mobileuiscale = 1
	mobileisnarrow = true

	local camera = workspace.CurrentCamera
	local viewport = camera
		and camera.ViewportSize
		or Vector2.new(800, 450)

	local safesize = gui.AbsoluteSize

	if safesize.X <= 0
		or safesize.Y <= 0
	then
		safesize = viewport
	end

	local shortedge = math.min(
		safesize.X,
		safesize.Y
	)

	local portrait =
		safesize.Y >= safesize.X

	local widthfactor =
		portrait and .72 or .74

	local heightfactor =
		portrait and .68 or .76

	local visualwidth = math.floor(
		math.clamp(
			safesize.X * widthfactor,
			220,
			math.max(220, safesize.X - 12)
		)
	)

	local visualheight = math.floor(
		math.clamp(
			safesize.Y * heightfactor,
			250,
			math.max(250, safesize.Y - 12)
		)
	)

	mobilelogicalsize = Vector2.new(
		visualwidth,
		visualheight
	)

	mobilefontscale = math.clamp(
		shortedge / 650,
		.52,
		.68
	)

	shell.AnchorPoint = Vector2.new(.5, .5)
	shell.Position = UDim2.fromScale(.5, .5)
	shell.Size = UDim2.fromOffset(
		visualwidth,
		visualheight
	)

	clampmobilewindow()

	resizehandle.Visible = false
	resizehandle.Active = false

	if not nav
		or not homebutton
		or not categoryarrow
		or not otherarrow
	then
		return
	end

	sidebar.Position = UDim2.fromOffset(0, 0)
	sidebar.Size = UDim2.fromScale(1, 1)

	main.Position = UDim2.fromOffset(0, 0)
	main.Size = UDim2.fromScale(1, 1)

	header.Size = UDim2.new(1, 0, 0, 54)

	content.Position = UDim2.fromOffset(10, 54)
	content.Size = UDim2.new(
		1,
		-20,
		1,
		-64
	)

	breadcrumb.Position = UDim2.fromOffset(48, 27)
	breadcrumb.Size = UDim2.new(1, -90, 0, 26)
	breadcrumb.ClipsDescendants = true

	arrowholder.Visible = false
	titlesecondary.Visible = false

	closebutton.Position = UDim2.new(1, -7, .5, 0)
	closebutton.Size = UDim2.fromOffset(34, 34)
	closebutton.Visible = true
	closebutton.Active = true

	searchholder.Visible = false
	mobilecolumnbutton.Visible = false

	mobilemenubutton.Position = UDim2.fromOffset(8, 27)
	mobilemenubutton.Size = UDim2.fromOffset(34, 34)

	mobilesideclose.Position = UDim2.new(1, -8, 0, 10)
	mobilesideclose.Size = UDim2.fromOffset(34, 34)

	maincategorycollapsed = false
	othercategorycollapsed = false
	categoryarrow.Rotation = 0
	otherarrow.Rotation = 0

	nav.Position = UDim2.fromOffset(12, 108)
	nav.Size = UDim2.new(1, -24, 1, -124)
	nav.CanvasSize = UDim2.fromOffset(0, 0)
	nav.AutomaticCanvasSize = Enum.AutomaticSize.Y
	nav.ScrollingDirection = Enum.ScrollingDirection.Y
	nav.ScrollBarThickness = 0
	nav.ElasticBehavior = Enum.ElasticBehavior.Never

	maingroup.ClipsDescendants = false
	othergroup.ClipsDescendants = false
	maincontent.Visible = true
	othercontent.Visible = true

	local subheight =
		math.max(
			0,
			sublistlayout.AbsoluteContentSize.Y + 8
		)

	sublist.Size = UDim2.new(
		1,
		-22,
		0,
		math.max(
			0,
			sublistlayout.AbsoluteContentSize.Y
		)
	)

	if topnavigationenabled
		or currentnav ~= combatbutton
	then
		subholder.Size = UDim2.new(1, 0, 0, 0)
	else
		subholder.Size = UDim2.new(1, 0, 0, subheight)
	end

	refreshsidegroups(false)

	for _, button in ipairs({
		homebutton,
		combatbutton,
		farmingbutton,
		componentsbutton,
		settingsbutton,
	}) do
		if button then
			button.Size = UDim2.new(1, 0, 0, 34)
		end
	end

	for _, button in ipairs({
		mainbutton,
		visualbutton,
		extrasbutton,
	}) do
		if button then
			button.Size = UDim2.new(1, 0, 0, 30)
		end
	end

	notificationholder.Position = UDim2.new(1, -8, 0, 8)
	notificationholder.Size = UDim2.fromOffset(
		math.min(
			280,
			math.max(190, visualwidth - 16)
		),
		math.max(
			140,
			visualheight - 16
		)
	)

	hotkeylistwidth = math.min(
		235,
		math.max(
			190,
			visualwidth - 16
		)
	)

	hotkeylist.Size = UDim2.fromOffset(
		hotkeylistwidth,
		hotkeylist.Size.Y.Offset
	)

	if watermark then
		local watermarkwidth = math.min(
			280,
			math.max(
				190,
				visualwidth - 16
			)
		)

		watermark.Size = UDim2.fromOffset(
			watermarkwidth,
			32
		)

		watermark.Position = UDim2.new(
			1,
			-8,
			0,
			8
		)
	end

	applymobiletextscale(mobilefontscale)
	refreshsidegroups(false)
	applymobilecolumns()
	setmobilepanel(mobilepanelopen)

	if currentpage then
		for _, section in ipairs(
			currentpage.sections
		) do
			if section.RefreshMobileLayout then
				section:RefreshMobileLayout()
			end
		end

		currentpage:reflow("left", false)
	end

	if topnavigationenabled
		and updatetopnavigationstate
	then
		task.defer(function()
			updatetopnavigationstate(false)
		end)
	end

	updatebackgroundbounds()
end

mobilemenubutton.Activated:Connect(function()
	setmobilepanel(true)
end)

mobilesideclose.Activated:Connect(function()
	setmobilepanel(false)
end)

mobilecolumnbutton.Activated:Connect(function()
	mobilecolumn = mobilecolumn == "left" and "right" or "left"
	applymobilecolumns()
end)

mobilemenubutton.MouseEnter:Connect(function()
	tween(mobilemenubutton, {ImageColor3 = theme.text}, hoverti)
end)
mobilemenubutton.MouseLeave:Connect(function()
	tween(mobilemenubutton, {ImageColor3 = theme.text2}, hoverti)
end)

for _, button in ipairs({
	homebutton,
	combatbutton,
	mainbutton,
	visualbutton,
	extrasbutton,
	farmingbutton,
	componentsbutton,
	settingsbutton,
}) do
	if button then
		button.Activated:Connect(function()
			if uis.TouchEnabled then
				task.defer(function()
					setmobilepanel(false)
					applymobilecolumns()
				end)
			end
		end)
	end
end

-- mobile uses the same top reopen control

if workspace.CurrentCamera then
	connect(
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"),
		function()
			if uis.TouchEnabled and not windowresize then
				fitmobilewindow()
			end
		end
	)
end

connect(
	workspace:GetPropertyChangedSignal("CurrentCamera"),
	function()
		if uis.TouchEnabled then
			task.defer(fitmobilewindow)
		end
	end
)

if uis.TouchEnabled then
	connect(guiservice:GetPropertyChangedSignal("ViewportDisplaySize"), function()
		task.defer(fitmobilewindow)
	end)
end


-- search

function applysearch()
	if not currentpage then
		return
	end

	local query =
		searchenabled
		and string.lower(
			search.Text
		)
		or ""

	for _, section in ipairs(
		currentpage.sections
	) do
		local sectionmatch =
			query == ""
			or string.find(
				string.lower(
					section.name
				),
				query,
				1,
				true
			)
				~= nil

		local any = false

		for _, control in ipairs(
			section.controls
		) do
			local visible =
				query == ""
				or sectionmatch
				or string.find(
					control.name,
					query,
					1,
					true
				)
					~= nil

			control.row.Visible =
				visible

			if visible then
				any = true
			end
		end

		section.frame.Visible =
			query == ""
			or sectionmatch
			or any
	end

	currentpage:reflowall(true)
end

search:GetPropertyChangedSignal(
	"Text"
):Connect(
	applysearch
)

-- navigation

env.__blush_reorderanimations = setmetatable({}, {
	__mode = "k",
})

function clearreorderanimation(button)
	local data = env.__blush_reorderanimations[button]
	if not data then
		return
	end

	env.__blush_reorderanimations[button] = nil

	if data.animation then
		invoke(function()
			data.animation:Cancel()
		end)
	end

	if data.hidden then
		restorefromghost(data.hidden)
	end

	if data.ghost and data.ghost.Parent then
		data.ghost:Destroy()
	end
end

function animatereorder(oldpositions, items, skipbutton)
	local function animatebutton(button)
		if button == skipbutton
			or not button
			or not button.Parent
			or not oldpositions[button]
		then
			return true
		end

		local oldposition = oldpositions[button]
		local newposition = button.AbsolutePosition

		if (newposition - oldposition).Magnitude <= 1 then
			return false
		end

		clearreorderanimation(button)

		local ghost =
			makedragghost(
				button,
				465
			)

		if not ghost then
			return true
		end

		ghost.Position =
			UDim2.fromOffset(
				oldposition.X
					- draglayer.AbsolutePosition.X,
				oldposition.Y
					- draglayer.AbsolutePosition.Y
			)

		local hidden =
			hideforghost(button)

		local animation =
			tween(
				ghost,
				{
					Position =
						UDim2.fromOffset(
							newposition.X
								- draglayer.AbsolutePosition.X,
							newposition.Y
								- draglayer.AbsolutePosition.Y
						),
				},
				TweenInfo.new(
					.24,
					Enum.EasingStyle.Quart,
					Enum.EasingDirection.Out
				)
			)

		env.__blush_reorderanimations[button] = {
			ghost = ghost,
			hidden = hidden,
			animation = animation,
		}

		local function finish()
			local current =
				env.__blush_reorderanimations[button]

			if not current
				or current.ghost ~= ghost
			then
				return
			end

			clearreorderanimation(button)
		end

		if animation then
			animation.Completed:Connect(finish)
		else
			finish()
		end

		return true
	end

	for _, button in ipairs(items or {}) do
		if not animatebutton(button)
			and button
			and button.Parent
		then
			local changed
			local destroying

			local function cleanup()
				if changed then
					changed:Disconnect()
					changed = nil
				end

				if destroying then
					destroying:Disconnect()
					destroying = nil
				end
			end

			changed =
				button:GetPropertyChangedSignal(
					"AbsolutePosition"
				):Connect(function()
					if animatebutton(button) then
						cleanup()
					end
				end)

			destroying =
				button.Destroying:Connect(
					cleanup
				)
		end
	end
end

function layoutnavcontent(
	button,
	textobject,
	iconobject,
	sub
)
	if iconobject
		and iconobject.Parent
	then
		iconobject.AnchorPoint =
			Vector2.new(
				0,
				.5
			)

		iconobject.Position =
			UDim2.new(
				0,
				sub and 11 or 14,
				.5,
				0
			)
	end

	local textx

	if iconobject
		and iconobject.Parent
	then
		textx = sub and 35 or 43
	else
		textx = sub and 11 or 14
	end

	textobject.Position =
		UDim2.fromOffset(
			textx,
			0
		)

	textobject.Size =
		UDim2.new(
			1,
			-textx - 8,
			1,
			0
		)
end

function navbutton(
	parentobject,
	name,
	asset,
	sub
)
	local height =
		sub and 30 or 40

	local button = new("TextButton", {
		Parent = parentobject,

		Size =
			UDim2.new(
				1,
				0,
				0,
				height
			),

		BackgroundColor3 =
			theme.hover,

		BackgroundTransparency = 1,
		BorderSizePixel = 0,

		Text = "",
		AutoButtonColor = false,

		ZIndex = 13,
	})

	corner(
		button,
		sub and 7 or 8
	)

	local indicator
	local indicatorglow

	if not sub then
		indicator = new("Frame", {
			Parent = button,

			AnchorPoint =
				Vector2.new(
					0,
					.5
				),

			Position =
				UDim2.new(
					0,
					4,
					.5,
					0
				),

			Size =
				UDim2.fromOffset(
					3,
					20
				),

			BackgroundColor3 =
				theme.white,

			BackgroundTransparency = 1,
			BorderSizePixel = 0,

			ZIndex = 14,
		})

		corner(
			indicator,
			999
		)

		indicatorglow = nil
	end

	local iconobject

	if asset ~= nil
		and tostring(asset) ~= ""
	then
		iconobject =
			image(
				button,
				asset,
				sub and 15 or 19,
				theme.text3,
				14
			)
	end

	local textobject =
		label(
			button,
			name,
			UDim2.new(
				1,
				0,
				1,
				0
			),
			font,
			theme.text3
		)

	textobject.TextSize =
		sub and 16 or 17

	textobject.ZIndex = 14

	layoutnavcontent(
		button,
		textobject,
		iconobject,
		sub
	)

	return button,
		textobject,
		indicator,
		iconobject,
		indicatorglow
end

function setnaventryicon(entry, asset)
	if not entry
		or not entry.button
		or not entry.button.Parent
	then
		return nil
	end

	if entry.icon
		and entry.icon.Parent
	then
		entry.icon:Destroy()
	end

	entry.icon = nil

	if asset ~= nil
		and tostring(asset) ~= ""
	then
		entry.icon =
			image(
				entry.button,
				asset,
				entry.sub and 15 or 19,
				currentnav == entry.button
					and theme.text
					or theme.text3,
				14
			)
	end

	layoutnavcontent(
		entry.button,
		entry.text,
		entry.icon,
		entry.sub
	)

	setsidebarentrycompact(
		entry,
		sidebarcompact,
		entry.sub
	)

	return entry.icon
end


homebutton,
	hometext,
	homeindicator,
	homeicon,
	homeglow =
	navbutton(
		maincontent,
		"Home",
		icons.home
	)

combatbutton,
	combattext,
	combatindicator,
	combaticon,
	combatglow =
	navbutton(
		maincontent,
		"Combat",
		icons.combat
	)

subholder =
	new("Frame", {
		Parent = maincontent,

		Size =
			UDim2.new(
				1,
				0,
				0,
				100
			),

		BackgroundTransparency = 1,
		ClipsDescendants = true,

		ZIndex = 13,
	})

sublist = new("Frame", {
	Parent = subholder,

	Position =
		UDim2.fromOffset(
			18,
			3
		),

	Size =
		UDim2.new(
			1,
			-22,
			1,
			-6
		),

	BackgroundTransparency = 1,
	BorderSizePixel = 0,

	ZIndex = 14,
})

sublistlayout = list(
	sublist,
	3
)

mainbutton,
	maintext,
	_,
	mainicon =
	navbutton(
		sublist,
		"Main",
		icons.target,
		true
	)

visualbutton,
	visualtext,
	_,
	visualicon =
	navbutton(
		sublist,
		"Visuals",
		icons.visuals,
		true
	)

extrasbutton,
	extrastext,
	_,
	extrasicon =
	navbutton(
		sublist,
		"Extras",
		icons.extras,
		true
	)

topnavigation = new("Frame", {
	Parent = header,
	Position = UDim2.fromOffset(0, 0),
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Visible = false,
	ZIndex = 18,
})

topprimarybutton = new("TextButton", {
	Parent = topnavigation,
	AnchorPoint = Vector2.new(0, .5),
	Position = UDim2.fromOffset(21, 31),
	Size = UDim2.fromOffset(150, 38),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Text = "Combat",
	TextColor3 = theme.text,
	Font = bold,
	TextSize = 19,
	TextXAlignment = Enum.TextXAlignment.Left,
	AutoButtonColor = false,
	Active = true,
	ZIndex = 19,
})

topsubholder = new("Frame", {
	Parent = topnavigation,
	AnchorPoint = Vector2.new(.5, .5),
	Position = UDim2.new(.5, -54, .5, 0),
	Size = UDim2.fromOffset(172, 40),
	BackgroundColor3 = theme.window,
	BackgroundTransparency = .03,
	BorderSizePixel = 0,
	Visible = true,
	ZIndex = 19,
})
corner(topsubholder, 999)
stroke(topsubholder, .58, theme.border, 1)
addshadow(
	topsubholder,
	"TopNavShadow",
	.976,
	10,
	0,
	-1,
	Color3.fromRGB(0, 0, 0),
	UDim2.fromOffset(0, 2),
	false
)

new("UIPadding", {
	Parent = topsubholder,
	PaddingLeft = UDim.new(0, 3),
	PaddingRight = UDim.new(0, 3),
	PaddingTop = UDim.new(0, 4),
	PaddingBottom = UDim.new(0, 4),
})

topnavdivider = new("Frame", {
	Parent = topnavigation,
	AnchorPoint = Vector2.new(.5, 1),
	Position = UDim2.new(.5, 0, 1, 0),
	Size = UDim2.new(1, -28, 0, 1),
	BackgroundColor3 = theme.border,
	BackgroundTransparency = .72,
	BorderSizePixel = 0,
	Visible = false,
	ZIndex = 19,
})

new("UIListLayout", {
	Parent = topsubholder,
	FillDirection = Enum.FillDirection.Horizontal,
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	VerticalAlignment = Enum.VerticalAlignment.Center,
	Padding = UDim.new(0, 1),
	SortOrder = Enum.SortOrder.LayoutOrder,
})

topsubentries = {}

function createtopsub(name, asset, order)
	local button = new("TextButton", {
		Parent = topsubholder,
		Size = UDim2.fromOffset(40, 32),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		LayoutOrder = order,
		ClipsDescendants = false,
		ZIndex = 20,
	})

	local activepill = new("Frame", {
		Parent = button,
		AnchorPoint = Vector2.new(.5, .5),
		Position = UDim2.fromScale(.5, .5),
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = theme.input,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 20,
	})
	corner(activepill, 999)

	local iconobject = image(button, asset, 17, theme.text3, 21)
	iconobject.AnchorPoint = Vector2.new(.5, .5)
	iconobject.Position = UDim2.new(.5, 0, .5, 0)

	local textobject = label(
		button,
		name,
		UDim2.new(1, -36, 1, 0),
		medium,
		theme.text
	)
	textobject.Position = UDim2.fromOffset(32, 0)
	textobject.TextSize = 15
	textobject.TextTransparency = 1
	setfontalphabase(textobject, "TextTransparency", 1)
	textobject.TextXAlignment = Enum.TextXAlignment.Left
	textobject.ZIndex = 21

	local data = {
		pill = activepill,
		icon = iconobject,
		text = textobject,
		name = name,
	}
	topsubentries[button] = data

	button.MouseEnter:Connect(function()
		if data.text and data.text.TextTransparency < .99 then
			return
		end

		tween(iconobject, { ImageColor3 = theme.text2 }, hoverti)
	end)

	button.MouseLeave:Connect(function()
		if updatetopnavigationstate then
			updatetopnavigationstate(true)
		end
	end)

	return button, iconobject, textobject
end

topmainbutton, topmainicon, topmaintext = createtopsub("Main", icons.target, 1)
topvisualbutton, topvisualicon, topvisualtext = createtopsub("Visuals", icons.visuals, 2)
topextrasbutton, topextrasicon, topextrastext = createtopsub("Extras", icons.extras, 3)

farmingbutton,
	farmingtext,
	farmingindicator,
	farmingicon,
	farmingglow =
	navbutton(
		maincontent,
		"Farming",
		icons.farming
	)

componentsbutton,
	componentstext,
	componentsindicator,
	componentsicon,
	componentsglow =
	navbutton(
		maincontent,
		"Components",
		icons.sliders
	)

function createsidebartabsectionobjects(name)
	local header = new("TextButton", {
		Parent = nav,
		Size = UDim2.new(1, 0, 0, 28),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 13,
	})

	local textobject = label(
		header,
		name,
		UDim2.new(1, -30, 1, 0),
		medium,
		theme.text3
	)
	textobject.Position = UDim2.fromOffset(8, 0)
	textobject.TextSize = 14
	textobject.ZIndex = 14

	local arrow = image(
		header,
		icons.down,
		11,
		theme.text3,
		14
	)
	arrow.AnchorPoint = Vector2.new(1, .5)
	arrow.Position = UDim2.new(1, -7, .5, 0)
	arrow.ImageTransparency = .18

	local group = new("Frame", {
		Parent = nav,
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = 12,
	})

	local content = new("Frame", {
		Parent = group,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 12,
	})

	local layout = list(content, 3)
	registergradienttarget(header, textobject)

	return header, textobject, arrow, group, content, layout
end

otherheader,
	othertext,
	otherarrow,
	othergroup,
	othercontent,
	othercontentlayout =
	createsidebartabsectionobjects("Other")

othercategorycollapsed = false
otherheader.Visible = false

librarycustomtabsections = {}
librarytabsectionlookup = {}
libraryactivetabsection = nil

settingsbutton,
	settingstext,
	settingsindicator,
	settingsicon,
	settingsglow =
	navbutton(
		othercontent,
		"Settings",
		icons.settings
	)

function refreshsidegroups(animate)
	if uis.TouchEnabled then
		maincategorycollapsed = false
		othercategorycollapsed = false

		local mainheight =
			maincontentlayout.AbsoluteContentSize.Y

		local otherheight =
			othercontentlayout.AbsoluteContentSize.Y

		maingroup.Size = UDim2.new(
			1,
			0,
			0,
			mainheight
		)

		othergroup.Size = UDim2.new(
			1,
			0,
			0,
			otherheight
		)

		maingroup.ClipsDescendants = false
		othergroup.ClipsDescendants = false

		for _, sectiontab in ipairs(librarycustomtabsections or {}) do
			local height = sectiontab.Layout.AbsoluteContentSize.Y
			sectiontab.Group.Size = UDim2.new(1, 0, 0, height)
			sectiontab.Group.ClipsDescendants = false
		end

		return
	end

	local mainheight = maincategorycollapsed and 0 or maincontentlayout.AbsoluteContentSize.Y
	local otherheight = othercategorycollapsed and 0 or othercontentlayout.AbsoluteContentSize.Y

	if animate then
		tween(maingroup, {Size = UDim2.new(1, 0, 0, mainheight)}, tabti)
		tween(othergroup, {Size = UDim2.new(1, 0, 0, otherheight)}, tabti)
	else
		maingroup.Size = UDim2.new(1, 0, 0, mainheight)
		othergroup.Size = UDim2.new(1, 0, 0, otherheight)
	end

	for _, sectiontab in ipairs(librarycustomtabsections or {}) do
		local height = sectiontab.Collapsed and 0 or sectiontab.Layout.AbsoluteContentSize.Y

		if animate then
			tween(sectiontab.Group, {Size = UDim2.new(1, 0, 0, height)}, tabti)
		else
			sectiontab.Group.Size = UDim2.new(1, 0, 0, height)
		end
	end
end

maincontentlayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	refreshsidegroups(false)
end)
othercontentlayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	refreshsidegroups(false)
end)

category.Activated:Connect(function()
	if uis.TouchEnabled then
		return
	end

	maincategorycollapsed = not maincategorycollapsed
	tween(categoryarrow, {Rotation = maincategorycollapsed and -90 or 0}, tabti)
	refreshsidegroups(true)
end)

otherheader.Activated:Connect(function()
	if uis.TouchEnabled then
		return
	end

	othercategorycollapsed = not othercategorycollapsed
	tween(otherarrow, {Rotation = othercategorycollapsed and -90 or 0}, tabti)
	refreshsidegroups(true)
end)

function refreshlibrarytabsectionorders()
	maingroup.LayoutOrder = 1

	for index, sectiontab in ipairs(librarycustomtabsections) do
		sectiontab.Header.LayoutOrder = index * 2
		sectiontab.Group.LayoutOrder = index * 2 + 1
	end

	local offset = #librarycustomtabsections * 2
	otherheader.LayoutOrder = offset + 2
	othergroup.LayoutOrder = offset + 3
end

function createlibrarytabsection(name)
	name = tostring(name or "Section")
	local key = string.lower(name)

	if key == "main" then
		return {
			Name = categorytext.Text,
			Content = maincontent,
			Group = maingroup,
			Header = category,
			Builtin = true,
		}
	end

	if key == "other" then
		return {
			Name = othertext.Text,
			Content = othercontent,
			Group = othergroup,
			Header = otherheader,
			Builtin = true,
		}
	end

	local existing = librarytabsectionlookup[key]
	if existing then
		return existing
	end

	local header, textobject, arrow, group, content, layout =
		createsidebartabsectionobjects(name)
	local sectiontab = {
		Name = name,
		Header = header,
		TextObject = textobject,
		Arrow = arrow,
		Group = group,
		Content = content,
		Layout = layout,
		Collapsed = false,
		Order = {},
	}

	function sectiontab:SetCollapsed(value, animate)
		if uis.TouchEnabled then
			value = false
		end

		self.Collapsed = value == true
		tween(self.Arrow, {Rotation = self.Collapsed and -90 or 0}, tabti)
		refreshsidegroups(animate ~= false)
	end

	function sectiontab:SetName(value)
		local oldkey = string.lower(self.Name)
		self.Name = tostring(value or self.Name)
		self.TextObject.Text = self.Name

		if librarytabsectionlookup[oldkey] == self then
			librarytabsectionlookup[oldkey] = nil
		end

		librarytabsectionlookup[string.lower(self.Name)] = self
	end

	function sectiontab:SetVisible(value)
		local visible = value ~= false
		self.Header.Visible = visible and not sidebarcompact
		self.Group.Visible = visible
		refreshsidegroups(false)
	end

	function sectiontab:SetGradient(value)
		return settextgradient(self.TextObject, value)
	end

	function sectiontab:SetRainbow(value)
		return settextrainbow(self.TextObject, value)
	end

	header.Activated:Connect(function()
		sectiontab:SetCollapsed(not sectiontab.Collapsed, true)
	end)

	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		refreshsidegroups(false)
	end)

	table.insert(librarycustomtabsections, sectiontab)
	librarytabsectionlookup[key] = sectiontab
	refreshlibrarytabsectionorders()
	refreshsidegroups(false)

	return sectiontab
end

refreshsidegroups(false)

naventries = {
	[homebutton] = {
		button = homebutton,
		sub = false,
		text = hometext,
		indicator = homeindicator,
		icon = homeicon,
		glow = homeglow,
	},

	[combatbutton] = {
		button = combatbutton,
		sub = false,
		text = combattext,
		indicator = combatindicator,
		icon = combaticon,
		glow = combatglow,
	},

	[farmingbutton] = {
		button = farmingbutton,
		sub = false,
		text = farmingtext,
		indicator = farmingindicator,
		icon = farmingicon,
		glow = farmingglow,
	},

	[componentsbutton] = {
		button = componentsbutton,
		sub = false,
		text = componentstext,
		indicator = componentsindicator,
		icon = componentsicon,
		glow = componentsglow,
	},

	[settingsbutton] = {
		button = settingsbutton,
		sub = false,
		text = settingstext,
		indicator = settingsindicator,
		icon = settingsicon,
		glow = settingsglow,
	},
}

subentries = {
	[mainbutton] = {
		button = mainbutton,
		sub = true,
		text = maintext,
		icon = mainicon,
	},

	[visualbutton] = {
		button = visualbutton,
		sub = true,
		text = visualtext,
		icon = visualicon,
	},

	[extrasbutton] = {
		button = extrasbutton,
		sub = true,
		text = extrastext,
		icon = extrasicon,
	},
}

function updatetopnavigationlayout()
	if not topnavigation or not topnavigation.Parent then
		return
	end

	local width = header.AbsoluteSize.X
	local mobile = uis.TouchEnabled
	local compact = mobile or (width > 0 and width < 560)

	if mobile then
		searchholder.Visible = false

		local left =
			mobilemenubutton.Visible
			and 46
			or 8

		local right =
			closebutton.Visible
			and 42
			or 8

		local available = math.max(
			96,
			width - left - right
		)

		if currentnav == combatbutton then
			topprimarybutton.Visible = false
			topsubholder.Visible = true
			topsubholder.Position = UDim2.fromOffset(
				math.floor(
					left + available * .5
				),
				27
			)
			topsubholder.Size = UDim2.fromOffset(
				math.min(166, available),
				36
			)
		else
			topsubholder.Visible = false
			topprimarybutton.Visible = true
			topprimarybutton.Active = true
			topprimarybutton.Position = UDim2.fromOffset(
				left,
				27
			)
			topprimarybutton.Size = UDim2.fromOffset(
				available,
				34
			)
			topprimarybutton.TextSize = 14
		end

		return
	end

	local searchvisible = searchenabled and not uis.TouchEnabled
	local searchwidth = searchvisible and (compact and 116 or 150) or 0
	local searchinset = windowminimizebuttonenabled
		and 52
		or (compact and 10 or 14)
	local leftbound = compact and 112 or 162
	local rightbound = math.max(
		leftbound + 190,
		width - searchinset - (searchvisible and searchwidth + 12 or 0)
	)
	local available = math.max(190, rightbound - leftbound)
	local holderwidth = math.min(compact and 168 or 172, available)
	local center = leftbound + available * .5

	searchholder.Size = UDim2.fromOffset(searchwidth, 38)
	searchholder.Position = UDim2.new(1, -searchinset, .5, 0)

	topprimarybutton.Position = UDim2.fromOffset(compact and 16 or 21, 31)
	topprimarybutton.Size = UDim2.fromOffset(compact and 90 or 150, 38)
	topprimarybutton.TextSize = compact and 18 or 19

	topsubholder.Position = UDim2.fromOffset(math.round(center), 31)
	topsubholder.Size = UDim2.fromOffset(math.round(holderwidth), 40)
end

connect(header:GetPropertyChangedSignal("AbsoluteSize"), function()
	if topnavigationenabled then
		updatetopnavigationlayout()
	end
end)

function updatetopnavigationstate(animate)
	if not topnavigation then
		return
	end

	local enabled =
		topnavigationenabled == true
		and currentnav ~= nil

	local legacycombat =
		currentnav == combatbutton
		and combatbutton.Visible

	topnavigation.Visible = enabled
	breadcrumb.Visible = not enabled
	topnavdivider.Visible = enabled
	topprimarybutton.Visible = enabled
	topsubholder.Visible = enabled and legacycombat

	if not enabled then
		updateheadercontrols()
		return
	end

	local entry = naventries[currentnav]

	topprimarybutton.Text =
		entry
		and entry.text
		and entry.text.Text
		or (
			currentpage
			and currentpage.primary
		)
		or "Navigation"

	updatetopnavigationlayout()

	if not legacycombat then
		return
	end

	local entries = {
		{button = topmainbutton, active = currentsub == mainbutton},
		{button = topvisualbutton, active = currentsub == visualbutton},
		{button = topextrasbutton, active = currentsub == extrasbutton},
	}

	for _, entry in ipairs(entries) do
		local data = topsubentries[entry.button]
		if data then
			local active = entry.active == true
			local width = uis.TouchEnabled
				and (active and 54 or 26)
				or (active and 82 or 38)
			local iconcolor = active and theme.text or theme.text3
			local textalpha = active and 0 or 1
			local pillalpha = active and .18 or 1
			local info = tabti

			data.icon.AnchorPoint = active and Vector2.new(0, .5) or Vector2.new(.5, .5)
			data.icon.Position = active
				and UDim2.fromOffset(uis.TouchEnabled and 9 or 12, 16)
				or UDim2.new(.5, 0, .5, 0)

			if animate ~= false and animationsenabled then
				tween(entry.button, { Size = UDim2.fromOffset(width, 32) }, info)
				tween(data.pill, {
					BackgroundColor3 = theme.input,
					BackgroundTransparency = pillalpha,
				}, info)
				tween(data.icon, { ImageColor3 = iconcolor }, info)
				tween(data.text, {
					TextColor3 = theme.text,
					TextTransparency = textalpha,
				}, info)
			else
				entry.button.Size = UDim2.fromOffset(width, 32)
				data.pill.BackgroundColor3 = theme.input
				data.pill.BackgroundTransparency = pillalpha
				data.icon.ImageColor3 = iconcolor
				syncbinding(data.text, "TextColor3", theme.text)
				syncbinding(data.text, "TextTransparency", textalpha)
				data.text.TextColor3 = theme.text
				setfontalphabase(data.text, "TextTransparency", textalpha)
				data.text.TextTransparency = effectivefontalpha(textalpha)
			end
		end
	end
end

function applytopnavigation(value, animate)
	topnavigationenabled = value == true

	if uis.TouchEnabled then
		if topnavigationenabled then
			subholder.Size = UDim2.new(1, 0, 0, 0)
		else
			expandsubtabs(
				currentnav == combatbutton
			)
		end

		updatebackgroundbounds()
		updatetopnavigationstate(animate ~= false)
		refreshsidegroups(false)
		return
	end

	-- Top navigation only replaces the Combat subtabs. Primary navigation stays in the sidebar.
	if not uis.TouchEnabled then
		sidebar.Visible = true
		sidebardivider.Visible = true
		local width = math.max(0, (sidebarwidth or 215) - 1)
		main.Position = UDim2.fromOffset(width, 0)
		main.Size = UDim2.new(1, -width, 1, 0)
	end

	if topnavigationenabled then
		subholder.Size = UDim2.new(1, 0, 0, 0)
	elseif currentnav == combatbutton then
		subholder.Size = UDim2.new(1, 0, 0, 100)
	end

	updatebackgroundbounds()
	updatetopnavigationstate(animate ~= false)
end

function opentopmainmenu()
	if topprimarypopup
		and activepopup == topprimarypopup
	then
		closepopup()
		topprimarypopup = nil
		return
	end

	local position =
		topprimarybutton.AbsolutePosition
		+ Vector2.new(
			0,
			topprimarybutton.AbsoluteSize.Y + 2
		)

	local actions = {}

	if librarytaborder
		and #librarytaborder > 0
	then
		for _, tab in ipairs(librarytaborder) do
			local currenttab = tab

			if currenttab.Button
				and currenttab.Button.Parent
				and currenttab.Button.Visible
			then
				local entry =
					naventries[currenttab.Button]

				table.insert(actions, {
					Text = currenttab.Name,
					Icon = entry
						and entry.icon
						and entry.icon.Image
						or nil,
					Callback = function()
						currenttab:Select()
					end,
				})
			end
		end

		if settingsbutton.Visible then
			table.insert(actions, {
				Text = settingstext.Text,
				Icon = settingsicon.Image,
				Callback = function()
					selectmain(settingsbutton)
					expandsubtabs(false)
					showpage("settings")
				end,
			})
		end
	else
		actions = {
			{
				Text = "Home",
				Icon = icons.home,
				Callback = function()
					selectmain(homebutton)
					expandsubtabs(false)
					showpage("home")
				end,
			},
			{
				Text = "Combat",
				Icon = icons.combat,
				Callback = function()
					selectmain(combatbutton)
					expandsubtabs(true)

					if not currentsub then
						selectsub(mainbutton)
					end

					if currentsub == visualbutton then
						showpage("combat_visuals")
					elseif currentsub == extrasbutton then
						showpage("combat_extras")
					else
						showpage("combat_main")
					end
				end,
			},
			{
				Text = "Farming",
				Icon = icons.farming,
				Callback = function()
					selectmain(farmingbutton)
					expandsubtabs(false)
					showpage("farming")
				end,
			},
			{
				Text = "Components",
				Icon = icons.sliders,
				Callback = function()
					selectmain(componentsbutton)
					expandsubtabs(false)
					showpage("components")
				end,
			},
			{
				Text = "Settings",
				Icon = icons.settings,
				Callback = function()
					selectmain(settingsbutton)
					expandsubtabs(false)
					showpage("settings")
				end,
			},
		}
	end

	local _, popup =
		opencontextmenu(
			position,
			actions
		)

	topprimarypopup = popup

	local previousclose =
		popup and popup.onclose

	if popup then
		popup.onclose = function()
			if previousclose then
				previousclose()
			end

			if topprimarypopup == popup then
				topprimarypopup = nil
			end
		end
	end
end

-- primary navigation remains in the sidebar; top navigation is subtabs only
topmainbutton.Activated:Connect(function()
	selectmain(combatbutton) selectsub(mainbutton) expandsubtabs(true) showpage("combat_main")
end)
topvisualbutton.Activated:Connect(function()
	selectmain(combatbutton) selectsub(visualbutton) expandsubtabs(true) showpage("combat_visuals")
end)
topextrasbutton.Activated:Connect(function()
	selectmain(combatbutton) selectsub(extrasbutton) expandsubtabs(true) showpage("combat_extras")
end)

function naventrytween(entry, key, object, goals)
	local previous = entry[key]
	if previous then
		invoke(function() previous:Cancel() end)
	end

	local animation = tween(object, goals, tabti)
	entry[key] = animation

	if animation then
		animation.Completed:Connect(function()
			if entry[key] == animation then
				entry[key] = nil
			end
		end)
	end
end

function rendernaventry(button, sub, hovered)
	local entry = sub and subentries[button] or naventries[button]
	if not entry then
		return
	end

	local active = sub and currentsub == button or (not sub and currentnav == button)
	local textcolor = (active or hovered) and theme.text or theme.text3
	local iconcolor = active
		and (sub and theme.text2 or theme.text)
		or (hovered and (sub and theme.text2 or theme.text) or theme.text3)

	naventrytween(entry, "textanimation", entry.text, {TextColor3 = textcolor})
	if entry.icon then
		naventrytween(entry, "iconanimation", entry.icon, {ImageColor3 = iconcolor})
	end

	if not sub and entry.indicator then
		naventrytween(
			entry,
			"indicatoranimation",
			entry.indicator,
			{BackgroundTransparency = active and 0 or 1}
		)

		if entry.glow then
			naventrytween(
				entry,
				"glowanimation",
				entry.glow,
				{Transparency = active and .68 or 1}
			)
		end
	end
end

function bindnavhover(button, sub)
	button.MouseEnter:Connect(function()
		rendernaventry(button, sub, true)
	end)

	button.MouseLeave:Connect(function()
		rendernaventry(button, sub, false)
	end)
end

bindnavhover(homebutton, false)
bindnavhover(combatbutton, false)
bindnavhover(farmingbutton, false)
bindnavhover(componentsbutton, false)
bindnavhover(settingsbutton, false)

bindnavhover(mainbutton, true)
bindnavhover(visualbutton, true)
bindnavhover(extrasbutton, true)

function selectmain(button)
	local previous = currentnav
	currentnav = button

	if previous and previous ~= button then
		rendernaventry(previous, false, false)
	end

	rendernaventry(button, false, false)

	if updatetopnavigationstate then
		updatetopnavigationstate(true)
	end
end

function selectsub(button)
	local previous = currentsub
	currentsub = button

	if previous and previous ~= button then
		rendernaventry(previous, true, false)
	end

	rendernaventry(button, true, false)

	if updatetopnavigationstate then
		updatetopnavigationstate(true)
	end
end

function expandsubtabs(value)
	if uis.TouchEnabled then
		local height = value
			and not topnavigationenabled
			and math.max(
				0,
				sublistlayout.AbsoluteContentSize.Y + 8
			)
			or 0

		sublist.Size = UDim2.new(
			1,
			-22,
			0,
			math.max(
				0,
				sublistlayout.AbsoluteContentSize.Y
			)
		)

		subholder.Size = UDim2.new(
			1,
			0,
			0,
			height
		)

		refreshsidegroups(false)

		if updatetopnavigationstate then
			updatetopnavigationstate(false)
		end

		return
	end

	local height = value and 100 or 0
	if topnavigationenabled then
		height = 0
	end

	tween(
		subholder,
		{Size = UDim2.new(1, 0, 0, height)},
		tabti
	)

	if updatetopnavigationstate then
		updatetopnavigationstate()
	end
end


mainnavorder = {
	homebutton,
	combatbutton,
	farmingbutton,
	componentsbutton,
}

subnavorder = {
	mainbutton,
	visualbutton,
	extrasbutton,
}

navtabdrag = nil

function applynavorder()
	for index, button in ipairs(mainnavorder) do
		button.LayoutOrder = index * 10
		if button == combatbutton then
			subholder.LayoutOrder = index * 10 + 1
		end
	end

	for index, button in ipairs(subnavorder) do
		button.LayoutOrder = index
	end

	refreshlibrarytabsectionorders()
	settingsbutton.LayoutOrder = 1
end

function bindnavdrag(button, ordertable, applyorder)
	button.InputBegan:Connect(function(input)
		if uis.TouchEnabled then
			return
		end

		if input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch
		then
			return
		end

		navtabdrag = {
			button = button,
			order = ordertable,
			apply = applyorder,
			input = input,
			start = point(input),
			started = false,
		}
	end)
end

bindnavdrag(homebutton, mainnavorder)
bindnavdrag(combatbutton, mainnavorder)
bindnavdrag(farmingbutton, mainnavorder)
bindnavdrag(componentsbutton, mainnavorder)

bindnavdrag(mainbutton, subnavorder)
bindnavdrag(visualbutton, subnavorder)
bindnavdrag(extrasbutton, subnavorder)

applynavorder()

connect(uis.InputChanged, function(input)
	if not navtabdrag then
		return
	end

	local ismouse = input.UserInputType == Enum.UserInputType.MouseMovement
	local istouch = input.UserInputType == Enum.UserInputType.Touch
		and input == navtabdrag.input

	if not ismouse and not istouch then
		return
	end

	local current = point(input)
	if not navtabdrag.started
		and (current - navtabdrag.start).Magnitude >= 7
	then
		navtabdrag.started = true
		nav.ScrollingEnabled = false
		navtabdrag.button:SetAttribute("BlushDragSuppress", true)
		navtabdrag.grab = current - navtabdrag.button.AbsolutePosition
		navtabdrag.ghost, navtabdrag.ghostclone, navtabdrag.ghostscale = makedragghost(navtabdrag.button, 470)
		navtabdrag.hidden = hideforghost(navtabdrag.button)
	end

	if not navtabdrag.started then
		return
	end

	if navtabdrag.ghost and navtabdrag.ghost.Parent then
		local root = draglayer.AbsolutePosition
		navtabdrag.ghost.Position = UDim2.fromOffset(
			current.X - navtabdrag.grab.X - root.X,
			current.Y - navtabdrag.grab.Y - root.Y
		)
	end

	local filtered = {}
	for _, button in ipairs(navtabdrag.order) do
		if button ~= navtabdrag.button then
			table.insert(filtered, button)
		end
	end

	local targetindex = #filtered + 1
	for index, other in ipairs(filtered) do
		local center = other.AbsolutePosition.Y + other.AbsoluteSize.Y * .5
		if current.Y < center then
			targetindex = index
			break
		end
	end

	local oldindex = table.find(navtabdrag.order, navtabdrag.button)
	if oldindex and oldindex ~= targetindex then
		local oldpositions = {}

		for _, other in ipairs(navtabdrag.order) do
			if other and other.Parent then
				oldpositions[other] = other.AbsolutePosition
			end
		end

		table.remove(navtabdrag.order, oldindex)
		targetindex = math.clamp(targetindex, 1, #navtabdrag.order + 1)
		table.insert(navtabdrag.order, targetindex, navtabdrag.button)

		if navtabdrag.apply then
			navtabdrag.apply()
		else
			applynavorder()
		end

		animatereorder(
			oldpositions,
			navtabdrag.order,
			navtabdrag.button
		)
	end
end)

connect(uis.InputEnded, function(input)
	if not navtabdrag then
		return
	end

	if input.UserInputType ~= Enum.UserInputType.MouseButton1
		and input ~= navtabdrag.input
	then
		return
	end

	local drag = navtabdrag
	navtabdrag = nil

	if not drag.started then
		return
	end

	local target = drag.button.AbsolutePosition - draglayer.AbsolutePosition
	local finished = false
	local function finish()
		if finished then return end
		finished = true
		nav.ScrollingEnabled = true
		restorefromghost(drag.hidden)
		if drag.ghost and drag.ghost.Parent then drag.ghost:Destroy() end
		if drag.button and drag.button.Parent then
			drag.button:SetAttribute("BlushDragSuppress", nil)
		end
	end

	if drag.ghost and drag.ghost.Parent then
		local animation = tween(
			drag.ghost,
			{Position = UDim2.fromOffset(target.X, target.Y)},
			TweenInfo.new(.24, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
		)
		if animation then
			animation.Completed:Connect(finish)
		else
			finish()
		end
	else
		finish()
	end
end)

homebutton.Activated:Connect(function()
	if homebutton:GetAttribute("BlushDragSuppress") then
		return
	end

	selectmain(
		homebutton
	)

	expandsubtabs(
		false
	)

	showpage(
		"home"
	)
end)

combatbutton.Activated:Connect(function()
	if combatbutton:GetAttribute("BlushDragSuppress") then
		return
	end

	selectmain(
		combatbutton
	)

	expandsubtabs(
		true
	)

	if not currentsub then
		selectsub(
			mainbutton
		)
	end

	if currentsub == visualbutton then
		showpage(
			"combat_visuals"
		)

	elseif currentsub == extrasbutton then
		showpage(
			"combat_extras"
		)

	else
		showpage(
			"combat_main"
		)
	end
end)

mainbutton.Activated:Connect(function()
	if mainbutton:GetAttribute("BlushDragSuppress") then
		return
	end

	selectmain(
		combatbutton
	)

	selectsub(
		mainbutton
	)

	showpage(
		"combat_main"
	)
end)

visualbutton.Activated:Connect(function()
	if visualbutton:GetAttribute("BlushDragSuppress") then
		return
	end

	selectmain(
		combatbutton
	)

	selectsub(
		visualbutton
	)

	showpage(
		"combat_visuals"
	)
end)

extrasbutton.Activated:Connect(function()
	if extrasbutton:GetAttribute("BlushDragSuppress") then
		return
	end

	selectmain(
		combatbutton
	)

	selectsub(
		extrasbutton
	)

	showpage(
		"combat_extras"
	)
end)

farmingbutton.Activated:Connect(function()
	if farmingbutton:GetAttribute("BlushDragSuppress") then
		return
	end

	selectmain(
		farmingbutton
	)

	expandsubtabs(
		false
	)

	showpage(
		"farming"
	)
end)

componentsbutton.Activated:Connect(function()
	if componentsbutton:GetAttribute("BlushDragSuppress") then
		return
	end

	selectmain(
		componentsbutton
	)

	expandsubtabs(
		false
	)

	showpage(
		"components"
	)
end)

settingsbutton.Activated:Connect(function()
	selectmain(
		settingsbutton
	)

	expandsubtabs(
		false
	)

	showpage(
		"settings"
	)
end)

applytopnavigation(topnavigationenabled, false)

if uis.TouchEnabled then
	for _, button in ipairs({
		homebutton,
		combatbutton,
		mainbutton,
		visualbutton,
		extrasbutton,
		farmingbutton,
		componentsbutton,
		settingsbutton,
	}) do
		if button then
			button.Activated:Connect(function()
				if mobileisnarrow then
					task.defer(function()
						setmobilepanel(false)
						applymobilecolumns()
					end)
				end
			end)
		end
	end

	task.defer(fitmobilewindow)
end


-- footer

rawnew("Frame", {
	Parent = sidebar,
	Position = UDim2.new(0, 0, 1, -72),
	Size = UDim2.new(1, 0, 0, 72),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ZIndex = 11,
})

footerdivider = new("Frame", {
	Parent = sidebar,

	Position =
		UDim2.new(
			0,
			14,
			1,
			-72
		),

	Size =
		UDim2.new(
			1,
			-28,
			0,
			1
		),

	BackgroundColor3 =
		theme.border,

	BackgroundTransparency =
		.45,

	BorderSizePixel = 0,

	ZIndex = 12,
})

footeravatar =
	new("ImageLabel", {
		Parent = sidebar,

		Position =
			UDim2.new(
				0,
				18,
				1,
				-58
			),

		Size =
			UDim2.fromOffset(
				38,
				38
			),

		BackgroundTransparency = 1,

		BorderSizePixel = 0,

		Image =
			thumbnail,

		ZIndex = 12,
	})

corner(
	footeravatar,
	999
)


footername =
	label(
		sidebar,
		player.DisplayName,
		UDim2.fromOffset(
			135,
			19
		),
		medium
	)

footername.Position =
	UDim2.new(
		0,
		66,
		1,
		-56
	)

footername.TextSize = 16
footername.ZIndex = 12

footername.TextTruncate =
	Enum.TextTruncate.AtEnd

footerusername =
	label(
		sidebar,
		"@" .. player.Name,
		UDim2.fromOffset(
			135,
			18
		),
		font,
		theme.text3
	)

footerusername.Position =
	UDim2.new(
		0,
		66,
		1,
		-35
	)

footerusername.TextSize = 15
footerusername.ZIndex = 12

footerusername.TextTruncate =
	Enum.TextTruncate.AtEnd

sidebarresizehandle = new("TextButton", {
	Parent = window,
	AnchorPoint = Vector2.new(.5, 0),
	Position = UDim2.fromOffset(sidebarwidth - 1, 0),
	Size = UDim2.new(0, 10, 1, 0),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Text = "",
	AutoButtonColor = false,
	Active = true,
	ZIndex = 90,
})

sidebarresizeaccent = new("Frame", {
	Parent = sidebarresizehandle,
	AnchorPoint = Vector2.new(.5, .5),
	Position = UDim2.fromScale(.5, .5),
	Size = UDim2.new(0, 1, 1, -24),
	BackgroundColor3 = theme.white,
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ZIndex = 91,
})
corner(sidebarresizeaccent, 999)
bindtheme(sidebarresizeaccent, "BackgroundColor3", theme.white)

function setsidebarentrycompact(entry, compact, sub)
	if not entry then
		return
	end

	if entry.text then
		entry.text.Visible = not compact
	end

	if entry.icon then
		entry.icon.AnchorPoint = compact
			and Vector2.new(.5, .5)
			or Vector2.new(0, .5)

		entry.icon.Position = compact
			and UDim2.fromScale(.5, .5)
			or UDim2.new(
				0,
				sub and 11 or 14,
				.5,
				0
			)
	end
end

function applysidebarlayout(width, animate)
	width = math.clamp(
		math.floor(tonumber(width) or sidebarwidth),
		sidebarminwidth,
		sidebarmaxwidth
	)

	sidebarwidth = width
	sidebarcompact = width <= sidebarcompactthreshold

	local mainoffset = width - 1
	local info = TweenInfo.new(
		.18,
		Enum.EasingStyle.Quart,
		Enum.EasingDirection.Out
	)

	if animate == true and animationsenabled then
		tween(sidebar, {
			Size = UDim2.new(0, width, 1, 0),
		}, info)

		tween(main, {
			Position = UDim2.fromOffset(mainoffset, 0),
			Size = UDim2.new(1, -mainoffset, 1, 0),
		}, info)

		tween(sidebardivider, {
			Position = UDim2.fromOffset(mainoffset, 0),
		}, info)

		tween(sidebarresizehandle, {
			Position = UDim2.fromOffset(mainoffset, 0),
		}, info)
	else
		sidebar.Size = UDim2.new(0, width, 1, 0)
		main.Position = UDim2.fromOffset(mainoffset, 0)
		main.Size = UDim2.new(1, -mainoffset, 1, 0)
		sidebardivider.Position = UDim2.fromOffset(mainoffset, 0)
		sidebarresizehandle.Position = UDim2.fromOffset(mainoffset, 0)
	end

	brand.Visible = not sidebarcompact
	version.Visible = not sidebarcompact
	versiondivider.Visible = not sidebarcompact
	username.Visible = not sidebarcompact

	category.Visible = false

	footername.Visible = not sidebarcompact
	footerusername.Visible = not sidebarcompact

	avat.Position = sidebarcompact
		and UDim2.fromOffset(math.floor(width * .5), 45)
		or UDim2.fromOffset(39, 45)

	footeravatar.AnchorPoint = sidebarcompact
		and Vector2.new(.5, 0)
		or Vector2.zero

	footeravatar.Position = sidebarcompact
		and UDim2.new(.5, 0, 1, -58)
		or UDim2.new(0, 18, 1, -58)

	footerdivider.Position = sidebarcompact
		and UDim2.new(0, 10, 1, -72)
		or UDim2.new(0, 14, 1, -72)

	footerdivider.Size = sidebarcompact
		and UDim2.new(1, -20, 0, 1)
		or UDim2.new(1, -28, 0, 1)

	nav.Position = sidebarcompact
		and UDim2.fromOffset(10, 82)
		or UDim2.fromOffset(14, 92)

	nav.Size = sidebarcompact
		and UDim2.new(1, -20, 1, -154)
		or UDim2.new(1, -28, 1, -164)

	sublist.Position = sidebarcompact
		and UDim2.fromOffset(0, 3)
		or UDim2.fromOffset(18, 3)

	sublist.Size = sidebarcompact
		and UDim2.new(1, 0, 1, -6)
		or UDim2.new(1, -22, 1, -6)

	for _, entry in pairs(naventries or {}) do
		setsidebarentrycompact(entry, sidebarcompact, false)
	end

	for _, entry in pairs(subentries or {}) do
		setsidebarentrycompact(entry, sidebarcompact, true)
	end

	local otheravailable = settingsbutton.Visible

	if not otheravailable then
		for _, child in ipairs(othercontent:GetChildren()) do
			if child:IsA("GuiObject")
				and child ~= settingsbutton
				and child.Visible
			then
				otheravailable = true
				break
			end
		end
	end

	otherheader.Visible = false

	for _, sectiontab in ipairs(librarycustomtabsections or {}) do
		sectiontab.Header.Visible = not sidebarcompact
	end

	updatebrandlayout()

	if backgroundexcludesidebar then
		updatebackgroundbounds()
	end

	if topnavigationenabled then
		updatetopnavigationlayout()
	end
end

sidebarresizehandle.MouseEnter:Connect(function()
	tween(sidebarresizeaccent, {
		BackgroundTransparency = .84,
	}, hoverti)
end)

sidebarresizehandle.MouseLeave:Connect(function()
	if not sidebarresize then
		tween(sidebarresizeaccent, {
			BackgroundTransparency = 1,
		}, hoverti)
	end
end)

sidebarresizehandle.InputBegan:Connect(function(input)
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
		return
	end

	local now = os.clock()

	if now - sidebarresizelasttap <= .30 then
		sidebarresizelasttap = 0
		sidebarresize = nil
		applysidebarlayout(215, true)
		return
	end

	sidebarresizelasttap = now

	if not acquireinteraction(
		"sidebarresize",
		input
	) then
		return
	end

	closepopup()

	sidebarresize = {
		input = input,
		start = point(input),
		width = sidebarwidth,
		current = point(input),
	}

	ensureinteractionrenderloop()
	sidebarresizeaccent.BackgroundTransparency = .68
end)

applysidebarlayout(sidebarwidth, false)

-- dragging

lasttap = 0

function beginwindowdrag(
	input,
	allowdouble,
	deferpopup
)
	if not windowdragenabled then
		return
	end

	if windowdrag then
		return
	end

	if not acquireinteraction(
		"windowdrag",
		input
	) then
		return
	end

	local start =
		point(input)

	if uis.TouchEnabled then
		for _, control in ipairs({
			mobilemenubutton,
			mobilecolumnbutton,
			mobilesideclose,
			closebutton,
		}) do
			if control
				and control.Parent
				and control.Visible
				and inside(control, start)
			then
				releaseinteraction(input)
				return
			end
		end
	end

	if closebutton
		and closebutton.Parent
		and windowminimizebuttonenabled
		and inside(closebutton, start)
	then
		releaseinteraction(input)
		return
	end

	if allowdouble
		and not uis.TouchEnabled
		and not (
			searchenabled
			and inside(searchholder, start)
		)
	then
		local now =
			os.clock()

		if now - lasttap <= .28 then
			lasttap = 0
					local targetposition = centeredwindowposition(
				Vector2.new(shell.Size.X.Offset, shell.Size.Y.Offset),
				(env.__blush_shellscale and env.__blush_shellscale.Scale) or 1
			)

			if animationsenabled then
				tween(
					shell,
					{ Position = targetposition },
					TweenInfo.new(
						.26,
						Enum.EasingStyle.Quart,
						Enum.EasingDirection.Out
					)
				)
			else
				shell.Position = targetposition
			end

			releaseinteraction(input)
			return
		end

		lasttap =
			now
	end

	if not deferpopup then
		closepopup()
	end

	windowdrag = {
		input = input,

		start = start,
		current = start,

		startposition =
			shell.Position,

		search =
			searchenabled
			and inside(searchholder, start),

		moved = false,
		deferpopup = deferpopup == true,
	}

	ensureinteractionrenderloop()
end

function bindwindowdrag(
	object,
	allowdouble,
	exclude
)
	object.InputBegan:Connect(function(input)
		if input.UserInputType
				~= Enum.UserInputType.MouseButton1
			and input.UserInputType
				~= Enum.UserInputType.Touch
		then
			return
		end

		if exclude
			and exclude.Parent
			and exclude.Visible
			and inside(exclude, point(input))
		then
			return
		end

		beginwindowdrag(
			input,
			allowdouble,
			false
		)
	end)
end

bindwindowdrag(
	header,
	true,
	topprimarybutton
)

bindwindowdrag(
	breadcrumb,
	true
)

bindwindowdrag(
	searchholder,
	false
)

bindwindowdrag(
	search,
	false
)

bindwindowdrag(
	sideheaderdrag,
	true
)

topprimarybutton.InputBegan:Connect(function(input)
	if not topnavigationenabled
		or (
			input.UserInputType
				~= Enum.UserInputType.MouseButton1
			and input.UserInputType
				~= Enum.UserInputType.Touch
		)
	then
		return
	end

	topprimarygesture = {
		input = input,
		start = point(input),
	}

	beginwindowdrag(
		input,
		false,
		true
	)

	if not windowdrag
		or windowdrag.input ~= input
	then
		topprimarygesture = nil
	end
end)

watermarkdragarea.InputBegan:Connect(function(input)
	if input.UserInputType
			~= Enum.UserInputType.MouseButton1
		and input.UserInputType
			~= Enum.UserInputType.Touch
	then
		return
	end

	if not acquireinteraction(
		"watermarkdrag",
		input
	) then
		return
	end

	closepopup()

	watermarkdrag = {
		input = input,

		start = point(input),
		current = point(input),

		startposition =
			watermark.Position,
	}

	ensureinteractionrenderloop()
end)

resizehandle.InputBegan:Connect(function(input)
	if not windowresizeenabled then
		return
	end

	if input.UserInputType ~= Enum.UserInputType.MouseButton1
		and input.UserInputType ~= Enum.UserInputType.Touch
	then
		return
	end

	local now = os.clock()
	if now - lastresizetap <= .3 then
		lastresizetap = 0
		windowresize = nil

		local animation = tween(
			shell,
			{
				Size = UDim2.fromOffset(
					originalwindowsize.X,
					originalwindowsize.Y
				),
			},
			TweenInfo.new(.24, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
		)

		local function finishreset()
			if shell and shell.Parent and currentpage then
				currentpage:reflowall(false)
			end
		end

		if animation then
			local completed
			completed = animation.Completed:Connect(function()
				if completed then
					completed:Disconnect()
					completed = nil
				end

				finishreset()
			end)
		else
			finishreset()
		end

		return
	end

	lastresizetap = now

	if not acquireinteraction(
		"windowresize",
		input
	) then
		return
	end

	closepopup()

	local scale =
		(env.__blush_shellscale and env.__blush_shellscale.Scale)
		or 1
	local startpoint = point(input)

	windowresize = {
		input = input,
		start = startpoint,
		current = startpoint,
		startsize = Vector2.new(
			shell.Size.X.Offset,
			shell.Size.Y.Offset
		),
		startabsolute = shell.AbsolutePosition,
		startposition = shell.Position,
		scale = math.max(.01, scale),
		lastwidth = shell.Size.X.Offset,
		lastheight = shell.Size.Y.Offset,
	}

	ensureinteractionrenderloop()
end)

function matches(
	drag,
	input
)
	if not drag then
		return false
	end

	if drag.input.UserInputType
		== Enum.UserInputType.MouseButton1
	then
		return input.UserInputType
			== Enum.UserInputType.MouseMovement
	end

	return input
		== drag.input
end

function snapresizeaxis(raw, startvalue, minvalue, maxvalue, step)
	step = step or 2

	local mink = math.ceil((minvalue - startvalue) / step)
	local maxk = math.floor((maxvalue - startvalue) / step)
	local k = math.clamp(
		math.round((raw - startvalue) / step),
		mink,
		maxk
	)

	return startvalue + k * step
end

function applywindowresize()
	local resize = windowresize
	if not resize or not resize.current then
		return
	end

	local camera = workspace.CurrentCamera
	local viewport =
		camera and camera.ViewportSize
		or gui.AbsoluteSize

	local scale = resize.scale
	local delta =
		(resize.current - resize.start) / scale

	local maxwidth = math.floor(math.max(
		320,
		(viewport.X - resize.startabsolute.X - 8) / scale
	))
	local maxheight = math.floor(math.max(
		260,
		(viewport.Y - resize.startabsolute.Y - 8) / scale
	))

	if typeof(windowmaxsize) == "Vector2" then
		maxwidth = math.min(maxwidth, math.max(320, math.floor(windowmaxsize.X)))
		maxheight = math.min(maxheight, math.max(260, math.floor(windowmaxsize.Y)))
	end

	local configuredmin = typeof(windowminsize) == "Vector2"
		and windowminsize
		or Vector2.new(620, 440)

	local minwidth = math.min(
		math.max(320, math.floor(configuredmin.X)),
		maxwidth
	)
	local minheight = math.min(
		math.max(260, math.floor(configuredmin.Y)),
		maxheight
	)

	local rawwidth = resize.startsize.X + delta.X
	local rawheight = resize.startsize.Y + delta.Y
	local width = snapresizeaxis(
		rawwidth,
		resize.startsize.X,
		minwidth,
		maxwidth,
		4
	)
	local height = snapresizeaxis(
		rawheight,
		resize.startsize.Y,
		minheight,
		maxheight,
		2
	)

	if width == resize.lastwidth
		and height == resize.lastheight
	then
		return
	end

	resize.lastwidth = width
	resize.lastheight = height
	shell.Size = UDim2.fromOffset(width, height)
end

function applywindowdrag()
	local drag = windowdrag
	if not drag
		or not drag.current
		or not drag.moved
	then
		return
	end

	local delta = drag.current - drag.start
	shell.Position = offsetposition(drag.startposition, delta)

	if uis.TouchEnabled
		and clampmobilewindow
	then
		clampmobilewindow()
	end
end

function applywatermarkdrag()
	local drag = watermarkdrag
	if not drag or not drag.current then
		return
	end

	watermark.Position = offsetposition(drag.startposition, drag.current - drag.start)
end

function stopinteractionrenderloop()
	local connection = interactionrenderconnection
	interactionrenderconnection = nil

	if connection and connection.Connected then
		connection:Disconnect()
	end
end

function ensureinteractionrenderloop()
	if interactionrenderconnection
		and interactionrenderconnection.Connected
	then
		return
	end

	interactionrenderconnection =
		runservice.PreRender:Connect(function()
			if windowresize then
				applywindowresize()
			end

			if sidebarresize and sidebarresize.current then
				local scale = math.max(
					.01,
					(env.__blush_shellscale and env.__blush_shellscale.Scale) or 1
				)

				local delta =
					(sidebarresize.current.X - sidebarresize.start.X)
					/ scale

				applysidebarlayout(
					sidebarresize.width + delta,
					false
				)
			end

			if windowdrag then
				applywindowdrag()
			end

			if watermarkdrag then
				applywatermarkdrag()
			end

			if not windowresize
				and not sidebarresize
				and not windowdrag
				and not watermarkdrag
			then
				stopinteractionrenderloop()
			end
		end)
end

connect(
	uis.InputChanged,
	function(input)
		local p =
			point(input)

		if windowresize
			and matches(windowresize, input)
		then
			windowresize.current = p
		end

		if sidebarresize
			and matches(
				sidebarresize,
				input
			)
		then
			sidebarresize.current = p
		end

		if windowdrag
			and matches(
				windowdrag,
				input
			)
		then
			windowdrag.current =
				p

			local delta =
				p
				- windowdrag.start

			if delta.Magnitude > 3 then
				if not windowdrag.moved then
					windowdrag.moved = true

					if windowdrag.deferpopup then
						windowdrag.deferpopup = false
						closepopup()
					end
				end

				if windowdrag.search then
					search:ReleaseFocus()
				end
			end
		end

		if watermarkdrag
			and matches(
				watermarkdrag,
				input
			)
		then
			watermarkdrag.current =
				p
		end

		if sliderdrag
			and matches(
				sliderdrag,
				input
			)
		then
			sliderdrag.update(
				p
			)
		end

		if pickerdrag
			and matches(
				pickerdrag,
				input
			)
		then
			pickerdrag.update(
				pickerdrag,
				p
			)
		end

		if notificationdrag
			and matches(
				notificationdrag,
				input
			)
		then
			local data = notificationdrag.data

			if data
				and not data.closing
				and data.card
				and data.card.Parent
			then
				notificationdrag.current = p

				local now = os.clock()
				local dt = math.max(
					.001,
					now - notificationdrag.lasttime
				)

				local instantaneous =
					(p.X - notificationdrag.last.X)
					/ dt

				notificationdrag.velocity =
					notificationdrag.velocity * .7
					+ instantaneous * .3

				notificationdrag.last = p
				notificationdrag.lasttime = now

				local delta =
					p.X - notificationdrag.start.X

				local x = math.max(0, delta)

				data.card.Position =
					UDim2.fromOffset(
						x,
						0
					)

				data.card.GroupTransparency =
					math.clamp(
						x / 360 * .45,
						0,
						.45
					)
			end
		end

		if sectiondrag
			and matches(
				sectiondrag,
				input
			)
		then
			sectiondrag.current =
				p

			local delta =
				p
				- sectiondrag.start

			if not sectiondrag.started
				and delta.Magnitude >= 5
			then
				sectiondrag.section.headerdragged = true

				beginsectiondrag(
					sectiondrag
				)
			end

			if sectiondrag.started then
				updatesectiondrag(
					sectiondrag
				)
			end
		end
	end
)

connect(
	uis.InputEnded,
	function(input)
		local mouseended =
			input.UserInputType
			== Enum.UserInputType.MouseButton1

		if windowresize
			and (
				mouseended
					or input == windowresize.input
			)
		then
			local resizeinput =
				windowresize.input

			applywindowresize()
			windowresize = nil
			releaseinteraction(
				resizeinput
			)

			if currentpage then
				currentpage:reflowall(false)
			end
		end

		if sidebarresize
			and (
				mouseended
					or input == sidebarresize.input
			)
		then
			local sidebarinput =
				sidebarresize.input

			sidebarresize = nil
			releaseinteraction(
				sidebarinput
			)

			tween(sidebarresizeaccent, {
				BackgroundTransparency = 1,
			}, hoverti)
		end

		if windowdrag
			and (
				mouseended
				or input == windowdrag.input
			)
		then
			local drag = windowdrag
			windowdrag = nil

			local titleclick =
				topprimarygesture
				and (
					mouseended
					or input
						== topprimarygesture.input
				)
				and not drag.moved

			if topprimarygesture
				and (
					mouseended
					or input
						== topprimarygesture.input
				)
			then
				topprimarygesture = nil
			end

			releaseinteraction(
				drag.input
			)

			if titleclick
				and topnavigationenabled
			then
				opentopmainmenu()
			end
		end

		if watermarkdrag
			and (
				mouseended
				or input == watermarkdrag.input
			)
		then
			local watermarkinput = watermarkdrag.input
			watermarkdrag = nil
			releaseinteraction(watermarkinput)
		end

		if sliderdrag
			and (
				mouseended
				or input == sliderdrag.input
			)
		then
			local sliderinput =
				sliderdrag.input

			for _, knob in ipairs(
				sliderdrag.knobs
				or {}
			) do
				tween(
					knob,
					{
						Size =
							UDim2.fromOffset(
								13,
								13
							),
					},
					fastti
				)
			end

			sliderdrag =
				nil

			releaseinteraction(
				sliderinput
			)
		end

		if pickerdrag
			and (
				mouseended
				or input == pickerdrag.input
			)
		then
			local pickerinput =
				pickerdrag.input

			local state =
				pickerdrag.state

			state.dragging =
				false

			pickerdrag =
				nil

			state:refresh()

			if state.onpersist then
				state.onpersist()
			end

			releaseinteraction(
				pickerinput
			)
		end

		if notificationdrag
			and (
				mouseended
				or input == notificationdrag.input
			)
		then
			local drag = notificationdrag
			notificationdrag = nil

			local data = drag.data

			if data
				and not data.closing
				and data.card
				and data.card.Parent
			then
				local distance =
					math.max(
						0,
						drag.current.X - drag.start.X
					)

				if distance >= 92
					or drag.velocity >= 720
				then
					dismissnotification(
						data,
						drag.velocity
					)
				else
					data.card.Position = UDim2.fromOffset(0, 0)
					tween(
						data.card,
						{GroupTransparency = 0},
						notificationreturn
					)
				end
			end
		end

		if sectiondrag
			and (
				mouseended
				or input == sectiondrag.input
			)
		then
			finishsectiondrag()
		end

		if topprimarygesture
			and (
				mouseended
				or input == topprimarygesture.input
			)
			and not windowdrag
		then
			topprimarygesture = nil
		end
	end
)


-- public library api

library = {
	Version = "1.9.0",
	Icons = icons,
}

librarywindow = nil
librarytabs = {}
librarytaborder = {}
librarytabserial = 0

function librarynormalizeicon(value)
	if value == nil then
		return nil
	end

	if icons[value] then
		return icons[value]
	end

	return tostring(value)
end

function libraryenhancerow(row, section)
	if not row or row.__blush_config_api then
		return row
	end

	row.__blush_config_api = true

	local addbutton = row.AddButton
	local addtoggle = row.AddToggle

	local function rowdefault(config)
		if config.Default ~= nil then
			return config.Default
		end

		return config.Value
	end

	row.AddButton = function(self, config, callback)
		if type(config) == "table" then
			return addbutton(
				self,
				tostring(config.Name or config.Text or "Button"),
				config.Callback
			)
		end

		return addbutton(self, config, callback)
	end

	row.AddToggle = function(self, config, default, callback, keybindable, badge)
		local sourceconfig =
			type(config) == "table"
			and config
			or nil

		local name =
			sourceconfig
			and tostring(sourceconfig.Name or sourceconfig.Text or "Toggle")
			or tostring(config or "Toggle")

		local control

		if sourceconfig then
			local copied = table.clone(sourceconfig)
			copied.Callback =
				persistentcallback(
					sourceconfig.Callback
				)

			control = addtoggle(
				self,
				name,
				rowdefault(copied),
				copied.Callback,
				copied.Keybindable == true or copied.Keybind == true,
				copied.Badge
			)
		else
			control = addtoggle(
				self,
				config,
				default,
				persistentcallback(callback),
				keybindable,
				badge
			)
		end

		if section then
			registerpersistentcontrol(
				section,
				"Toggle",
				name,
				control,
				sourceconfig
			)
		end

		return control
	end

	return row
end

function libraryenhancesection(section)
	if not section or section.__blush_config_api then
		return section
	end

	section.__blush_config_api = true

	local addlabel = section.AddLabel
	local addbutton = section.AddButton
	local addrow = section.AddRow
	local addtoggle = section.AddToggle
	local addtogglekey = section.AddToggleKey
	local addtogglecolor = section.AddToggleColor
	local addtogglecolorkey = section.AddToggleColorKey
	local addslider = section.AddSlider
	local addrangeslider = section.AddRangeSlider
	local adddropdown = section.AddDropdown
	local addplayerdropdown = section.AddPlayerDropdown
	local addmultiplayerdropdown = section.AddMultiPlayerDropdown
	local addmultidropdown = section.AddMultiDropdown
	local addinput = section.AddInput
	local addkeypicker = section.AddKeyPicker
	local addcolorpicker = section.AddColorPicker
	local adddivider = section.AddDivider
	local addseparator = section.AddSeparator
	local addprogressbar = section.AddProgressBar
	local addradio = section.AddRadio
	local addbadge = section.AddBadge
	local addimage = section.AddImage
	local addavatar = section.AddAvatar
	local addloadingspinner = section.AddLoadingSpinner
	local addloadingbar = section.AddLoadingBar
	local addcontextmenu = section.AddContextMenu
	local addconfirmbutton = section.AddConfirmButton
	local addmodalbutton = section.AddModalButton
	local addbuttongroup = section.AddButtonGroup
	local addsubtabs = section.AddSubTabs

	local function configdefault(config)
		if config.Default ~= nil then
			return config.Default
		end

		return config.Value
	end

	section.AddLabel = function(self, config, wrap, target)
		if type(config) == "table" then
			return addlabel(
				self,
				tostring(config.Text or config.Name or ""),
				config.Wrap,
				config.Target
			)
		end

		return addlabel(self, config, wrap, target)
	end

	section.AddButton = function(self, config, callback, target)
		if type(config) == "table" then
			return addbutton(
				self,
				tostring(config.Name or config.Text or "Button"),
				config.Callback,
				config.Target
			)
		end

		return addbutton(self, config, callback, target)
	end

	section.AddRow = function(self, config, height, target)
		local row

		if type(config) == "table" then
			row = addrow(
				self,
				config.Spacing,
				config.Height,
				config.Target
			)
		else
			row = addrow(self, config, height, target)
		end

		return libraryenhancerow(row, self)
	end

	section.AddToggle = function(self, config, default, callback, target, keybindable, badge)
		if type(config) == "table" then
			return addtoggle(
				self,
				tostring(config.Name or config.Text or "Toggle"),
				configdefault(config),
				config.Callback,
				config.Target,
				config.Keybindable == true or config.Keybind == true,
				config.Badge
			)
		end

		return addtoggle(
			self,
			config,
			default,
			callback,
			target,
			keybindable,
			badge
		)
	end

	section.AddToggleKey = function(self, config, default, defaultkey, callback, keycallback, target, badge)
		if type(config) == "table" then
			return addtogglekey(
				self,
				tostring(config.Name or config.Text or "Toggle"),
				configdefault(config),
				config.Key or config.DefaultKey or Enum.KeyCode.F,
				config.Callback,
				config.KeyCallback,
				config.Target,
				config.Badge
			)
		end

		return addtogglekey(
			self,
			config,
			default,
			defaultkey,
			callback,
			keycallback,
			target,
			badge
		)
	end

	section.AddToggleColor = function(self, config, default, color, togglecallback, colorcallback, target, keybindable)
		if type(config) == "table" then
			return addtogglecolor(
				self,
				tostring(config.Name or config.Text or "Toggle"),
				configdefault(config),
				config.Color or Color3.new(1, 1, 1),
				config.Callback or config.ToggleCallback,
				config.ColorCallback,
				config.Target,
				config.Keybindable == true or config.Keybind == true
			)
		end

		return addtogglecolor(
			self,
			config,
			default,
			color,
			togglecallback,
			colorcallback,
			target,
			keybindable
		)
	end

	section.AddToggleColorKey = function(self, config, default, color, defaultkey, togglecallback, colorcallback, keycallback, target)
		if type(config) == "table" then
			return addtogglecolorkey(
				self,
				tostring(config.Name or config.Text or "Toggle"),
				configdefault(config),
				config.Color or Color3.new(1, 1, 1),
				config.Key or config.DefaultKey or Enum.KeyCode.F,
				config.Callback or config.ToggleCallback,
				config.ColorCallback,
				config.KeyCallback,
				config.Target
			)
		end

		return addtogglecolorkey(
			self,
			config,
			default,
			color,
			defaultkey,
			togglecallback,
			colorcallback,
			keycallback,
			target
		)
	end

	section.AddSlider = function(self, config, minimum, maximum, default, suffix, callback, target)
		if type(config) == "table" then
			return addslider(
				self,
				tostring(config.Name or config.Text or "Slider"),
				tonumber(config.Min or config.Minimum) or 0,
				tonumber(config.Max or config.Maximum) or 100,
				tonumber(configdefault(config)) or 0,
				tostring(config.Suffix or ""),
				config.Callback,
				config.Target
			)
		end

		return addslider(
			self,
			config,
			minimum,
			maximum,
			default,
			suffix,
			callback,
			target
		)
	end

	section.AddRangeSlider = function(self, config, minimum, maximum, defaultmin, defaultmax, suffix, callback, target)
		if type(config) == "table" then
			return addrangeslider(
				self,
				tostring(config.Name or config.Text or "Range"),
				tonumber(config.Min or config.Minimum) or 0,
				tonumber(config.Max or config.Maximum) or 100,
				tonumber(config.DefaultMin or config.ValueMin or config.Low) or 0,
				tonumber(config.DefaultMax or config.ValueMax or config.High) or 100,
				tostring(config.Suffix or ""),
				config.Callback,
				config.Target
			)
		end

		return addrangeslider(
			self,
			config,
			minimum,
			maximum,
			defaultmin,
			defaultmax,
			suffix,
			callback,
			target
		)
	end

	section.AddDropdown = function(self, config, options, default, callback, target, dropdownconfig)
		if type(config) == "table" then
			local settings = table.clone(config.Config or {})

			if config.Searchable ~= nil then
				settings.searchable = config.Searchable == true
			end

			if config.Dividers ~= nil then
				settings.dividers = config.Dividers
			end

			if config.Icons ~= nil then
				settings.icons = config.Icons
			end

			if config.Colors ~= nil then
				settings.colors = config.Colors
			end

			return adddropdown(
				self,
				tostring(config.Name or config.Text or "Dropdown"),
				config.Options or config.Values or config.Items or {},
				configdefault(config),
				config.Callback,
				config.Target,
				settings
			)
		end

		return adddropdown(
			self,
			config,
			options,
			default,
			callback,
			target,
			dropdownconfig
		)
	end

	section.AddPlayerDropdown = function(self, config, options, default, callback, target, playerconfig)
		if type(config) == "table" then
			local settings = table.clone(config.Config or {})

			if config.Searchable ~= nil then
				settings.searchable = config.Searchable == true
			end

			if config.PlayersDivider ~= nil then
				settings.playersDivider = config.PlayersDivider
			end

			if config.MultiSelect ~= nil then
				settings.multiselect = config.MultiSelect == true
			end

			if config.Everyone ~= nil then
				settings.everyone = config.Everyone == true
			end

			if config.Icons ~= nil then
				settings.icons = config.Icons
			end

			if config.Colors ~= nil then
				settings.colors = config.Colors
			end

			return addplayerdropdown(
				self,
				tostring(config.Name or config.Text or "Player"),
				config.Options or config.Values or {},
				configdefault(config),
				config.Callback,
				config.Target,
				settings
			)
		end

		return addplayerdropdown(
			self,
			config,
			options,
			default,
			callback,
			target,
			playerconfig
		)
	end

	section.AddMultiPlayerDropdown = function(self, config, default, callback, target, playerconfig)
		if type(config) == "table" then
			local settings = table.clone(config.Config or {})

			if config.Searchable ~= nil then
				settings.searchable = config.Searchable == true
			end

			if config.PlayersDivider ~= nil then
				settings.playersDivider = config.PlayersDivider
			end

			if config.Everyone ~= nil then
				settings.everyone = config.Everyone == true
			end

			if config.Icons ~= nil then
				settings.icons = config.Icons
			end

			if config.Colors ~= nil then
				settings.colors = config.Colors
			end

			return addmultiplayerdropdown(
				self,
				tostring(config.Name or config.Text or "Players"),
				config.Default or config.Values or {},
				config.Callback,
				config.Target,
				settings
			)
		end

		return addmultiplayerdropdown(
			self,
			config,
			default,
			callback,
			target,
			playerconfig
		)
	end

	section.AddMultiDropdown = function(self, config, options, default, callback, target)
		if type(config) == "table" then
			return addmultidropdown(
				self,
				tostring(config.Name or config.Text or "Multi Dropdown"),
				config.Options or config.Values or config.Items or {},
				config.Default or config.Selected or {},
				config.Callback,
				config.Target
			)
		end

		return addmultidropdown(
			self,
			config,
			options,
			default,
			callback,
			target
		)
	end

	section.AddInput = function(self, config, default, placeholder, callback, target)
		if type(config) == "table" then
			return addinput(
				self,
				tostring(config.Name or config.Text or "Input"),
				tostring(configdefault(config) or ""),
				tostring(config.Placeholder or ""),
				config.Callback,
				config.Target
			)
		end

		return addinput(
			self,
			config,
			default,
			placeholder,
			callback,
			target
		)
	end

	section.AddKeyPicker = function(self, config, defaultkey, callback, target)
		if type(config) == "table" then
			return addkeypicker(
				self,
				tostring(config.Name or config.Text or "Key"),
				config.Default or config.Key or Enum.KeyCode.RightShift,
				config.Callback,
				config.Target
			)
		end

		return addkeypicker(
			self,
			config,
			defaultkey,
			callback,
			target
		)
	end

	section.AddColorPicker = function(self, config, color, callback, target)
		if type(config) == "table" then
			return addcolorpicker(
				self,
				tostring(config.Name or config.Text or "Color"),
				config.Color or config.Default or Color3.new(1, 1, 1),
				config.Callback,
				config.Target
			)
		end

		return addcolorpicker(
			self,
			config,
			color,
			callback,
			target
		)
	end

	section.AddDivider = function(self, config, target)
		if type(config) == "table" then
			return adddivider(
				self,
				config.Text or config.Name,
				config.Target
			)
		end

		return adddivider(self, config, target)
	end

	section.AddSeparator = function(self, config)
		if type(config) == "table" then
			return addseparator(self, config.Target)
		end

		return addseparator(self, config)
	end

	section.AddProgressBar = function(self, config, default, suffix, target)
		if type(config) == "table" then
			return addprogressbar(
				self,
				tostring(config.Name or config.Text or "Progress"),
				tonumber(configdefault(config)) or 0,
				tostring(config.Suffix or "%"),
				config.Target
			)
		end

		return addprogressbar(
			self,
			config,
			default,
			suffix,
			target
		)
	end

	section.AddRadio = function(self, config, options, default, callback, target)
		if type(config) == "table" then
			return addradio(
				self,
				tostring(config.Name or config.Text or "Radio"),
				config.Options or config.Values or config.Items or {},
				configdefault(config),
				config.Callback,
				config.Target
			)
		end

		return addradio(
			self,
			config,
			options,
			default,
			callback,
			target
		)
	end

	section.AddBadge = function(self, config, textvalue, color, target)
		if type(config) == "table" then
			return addbadge(
				self,
				tostring(config.Name or config.Title or "Status"),
				tostring(config.Text or config.Status or config.Value or "Ready"),
				config.Color,
				config.Target
			)
		end

		return addbadge(
			self,
			config,
			textvalue,
			color,
			target
		)
	end

	section.AddImage = function(self, config, asset, height, target)
		if type(config) == "table" then
			return addimage(
				self,
				config.Name or config.Title,
				config.Asset or config.Image or "",
				config.Height,
				config.Target
			)
		end

		return addimage(
			self,
			config,
			asset,
			height,
			target
		)
	end

	section.AddAvatar = function(self, config, source, target)
		if type(config) == "table" then
			return addavatar(
				self,
				config.Name or config.Title or "Player",
				config.Player or config.Source or config.UserId,
				config.Target
			)
		end

		return addavatar(
			self,
			config,
			source,
			target
		)
	end

	section.AddLoadingSpinner = function(self, config, target)
		if type(config) == "table" then
			return addloadingspinner(
				self,
				tostring(config.Name or config.Text or "Loading"),
				config.Target
			)
		end

		return addloadingspinner(self, config, target)
	end

	section.AddLoadingBar = function(self, config, target)
		if type(config) == "table" then
			return addloadingbar(
				self,
				tostring(config.Name or config.Text or "Loading"),
				config.Target
			)
		end

		return addloadingbar(self, config, target)
	end

	section.AddContextMenu = function(self, config, entries, target)
		if type(config) == "table" then
			return addcontextmenu(
				self,
				tostring(config.Name or config.Text or "Actions"),
				config.Entries or config.Items or {},
				config.Target
			)
		end

		return addcontextmenu(
			self,
			config,
			entries,
			target
		)
	end

	section.AddConfirmButton = function(self, config, titletext, bodytext, callback, target)
		if type(config) == "table" then
			return addconfirmbutton(
				self,
				tostring(config.Name or config.Text or "Confirm"),
				tostring(config.Title or "Confirm"),
				tostring(config.Body or config.Message or ""),
				config.Callback,
				config.Target
			)
		end

		return addconfirmbutton(
			self,
			config,
			titletext,
			bodytext,
			callback,
			target
		)
	end

	section.AddModalButton = function(self, config, titletext, bodytext, target)
		if type(config) == "table" then
			return addmodalbutton(
				self,
				tostring(config.Name or config.Text or "Open"),
				tostring(config.Title or "Information"),
				tostring(config.Body or config.Message or ""),
				config.Target
			)
		end

		return addmodalbutton(
			self,
			config,
			titletext,
			bodytext,
			target
		)
	end

	section.AddButtonGroup = function(self, config, target)
		if type(config) == "table" and config.Buttons then
			return addbuttongroup(
				self,
				config.Buttons,
				config.Target
			)
		end

		return addbuttongroup(self, config, target)
	end

	section.AddSubTabs = function(self, config)
		if type(config) == "table"
			and (
				config.Tabs
				or config.Names
				or config.Items
			)
		then
			return addsubtabs(
				self,
				config.Tabs or config.Names or config.Items
			)
		end

		return addsubtabs(self, config)
	end

	local function wrappersistentmethod(
		methodname,
		kind,
		positioncallbacks,
		configcallbacks,
		special
	)
		local original =
			section[methodname]

		section[methodname] = function(self, ...)
			local args =
				table.pack(...)

			local sourceconfig =
				type(args[1]) == "table"
				and args[1]
				or nil

			local name =
				sourceconfig
				and tostring(
					sourceconfig.Name
					or sourceconfig.Text
					or kind
				)
				or tostring(
					args[1]
					or kind
				)

			local inputcallback

			if sourceconfig then
				local copied =
					table.clone(
						sourceconfig
					)

				for _, field in ipairs(
					configcallbacks or {}
				) do
					if field == "ToggleCallback" then
						local callback =
							sourceconfig.Callback
							or sourceconfig.ToggleCallback

						copied.Callback =
							persistentcallback(
								callback
							)

						copied.ToggleCallback = nil
					else
						local colorcallback =
							special == "color"
							and (
								field == "ColorCallback"
								or (
									kind == "ColorPicker"
									and field == "Callback"
								)
							)

						if not colorcallback then
							copied[field] =
								persistentcallback(
									sourceconfig[field]
								)
						end
					end
				end

				if kind == "Input" then
					inputcallback =
						copied.Callback
				end

				args[1] = copied
			else
				for _, index in ipairs(
					positioncallbacks or {}
				) do
					local colorcallback =
						special == "color"
						and (
							(kind == "ColorPicker" and index == 3)
							or (
								kind == "ToggleColor"
								and index == 5
							)
							or (
								kind == "ToggleColorKey"
								and index == 6
							)
						)

					if not colorcallback then
						args[index] =
							persistentcallback(
								args[index]
							)
					end
				end

				if kind == "Input" then
					inputcallback =
						args[4]
				end
			end

			local control =
				original(
					self,
					table.unpack(
						args,
						1,
						args.n
					)
				)

			registerpersistentcontrol(
				self,
				kind,
				name,
				control,
				sourceconfig,
				inputcallback
			)

			return control
		end
	end

	wrappersistentmethod(
		"AddToggle",
		"Toggle",
		{3},
		{"Callback"}
	)

	wrappersistentmethod(
		"AddToggleKey",
		"ToggleKey",
		{4, 5},
		{"Callback", "KeyCallback"}
	)

	wrappersistentmethod(
		"AddToggleColor",
		"ToggleColor",
		{4, 5},
		{"ToggleCallback", "ColorCallback"},
		"color"
	)

	wrappersistentmethod(
		"AddToggleColorKey",
		"ToggleColorKey",
		{5, 6, 7},
		{"ToggleCallback", "ColorCallback", "KeyCallback"},
		"color"
	)

	wrappersistentmethod(
		"AddSlider",
		"Slider",
		{6},
		{"Callback"}
	)

	wrappersistentmethod(
		"AddRangeSlider",
		"RangeSlider",
		{7},
		{"Callback"}
	)

	wrappersistentmethod(
		"AddDropdown",
		"Dropdown",
		{4},
		{"Callback"}
	)

	wrappersistentmethod(
		"AddPlayerDropdown",
		"PlayerDropdown",
		{4},
		{"Callback"}
	)

	wrappersistentmethod(
		"AddMultiPlayerDropdown",
		"MultiPlayerDropdown",
		{3},
		{"Callback"}
	)

	wrappersistentmethod(
		"AddMultiDropdown",
		"MultiDropdown",
		{4},
		{"Callback"}
	)

	wrappersistentmethod(
		"AddInput",
		"Input",
		{4},
		{"Callback"}
	)

	wrappersistentmethod(
		"AddKeyPicker",
		"KeyPicker",
		{3},
		{"Callback"}
	)

	wrappersistentmethod(
		"AddColorPicker",
		"ColorPicker",
		{3},
		{"Callback"},
		"color"
	)

	wrappersistentmethod(
		"AddRadio",
		"Radio",
		{4},
		{"Callback"}
	)

	function section:SetGradient(value)
		return settextgradient(self.TextObject, value)
	end

	function section:SetRainbow(value)
		return settextrainbow(self.TextObject, value)
	end

	return section
end

function librarysetlogo(asset, color)
	local hidden = asset == false or tostring(asset or "") == ""
	local custom = asset ~= nil and not hidden

	if hidden then
		asset = ""
	elseif not custom then
		asset = thumbnail
	elseif icons[asset] then
		asset = icons[asset]
	end

	logocoloroverride = typeof(color) == "Color3" and color or nil
	avat.Visible = not hidden
	avat.Image = tostring(asset)
	avat.ImageColor3 = logocoloroverride
		or (custom and theme.text2 or Color3.new(1, 1, 1))
	updatebrandlayout()
end

function librarysetbrand(title, versiontext)
	title = tostring(title or "blush.")
	versiontext = tostring(versiontext or ("v" .. library.Version))

	brand.Text = title
	version.Text = versiontext
	reopenlabel.Text = title
	updatebrandlayout()

	if env.__blush_watermark_title then
		setwatermarktitle(title)
	end
end

function libraryrefreshothergroupvisibility()
	local visible = settingsbutton.Visible

	if not visible then
		for _, tab in ipairs(librarytaborder) do
			if tab.Group == "other"
				and tab.Button
				and tab.Button.Parent
				and tab.Button.Visible
			then
				visible = true
				break
			end
		end
	end

	otherheader.Visible = false
	othergroup.Visible = visible
	refreshsidegroups(false)
end

function librarysetsettingstab(config)
	if type(config) == "boolean" then
		config = {
			Enabled = config,
		}
	elseif type(config) ~= "table" then
		config = {}
	end

	local enabled = config.Enabled ~= false
	local name = tostring(config.Name or config.Title or "Settings")
	local icon = librarynormalizeicon(config.Icon or "settings")
	local groupname = tostring(config.GroupName or config.CategoryName or "Other")
	local sections = config.Sections

	settingsbutton.Visible = enabled
	settingstext.Text = name
	settingsicon.Image = icon
	othertext.Text = groupname

	if type(sections) == "table" then
		settingssection.frame.Visible = sections.Interface ~= false
		themessection.frame.Visible = sections.Themes ~= false
		backgroundimagesection.frame.Visible = sections.Background ~= false
		savessection.frame.Visible = sections.Configs ~= false
	else
		settingssection.frame.Visible = true
		themessection.frame.Visible = true
		backgroundimagesection.frame.Visible = true
		savessection.frame.Visible = true
	end

	settings:reflowall(false)
	libraryrefreshothergroupvisibility()
end

function librarygetsettingstab()
	if librarysettingstab then
		return librarysettingstab
	end

	librarysettingstab = {
		Name = settingstext.Text,
		Page = settings,
		Button = settingsbutton,
	}

	function librarysettingstab:AddSection(title, column, sectionicon)
		column = string.lower(tostring(column or "left"))

		if column ~= "right" then
			column = "left"
		end

		if type(title) == "table" then
			local config = title
			column = string.lower(tostring(config.Side or config.Column or "left"))

			if column ~= "right" then
				column = "left"
			end

			return libraryenhancesection(
				createsection(
					settings,
					column,
					tostring(config.Name or config.Title or "Section"),
					config.Icon and librarynormalizeicon(config.Icon) or nil
				)
			)
		end

		return libraryenhancesection(
			createsection(
				settings,
				column,
				tostring(title or "Section"),
				sectionicon and librarynormalizeicon(sectionicon) or nil
			)
		)
	end

	function librarysettingstab:AddLeftSection(title, sectionicon)
		if type(title) == "table" then
			title.Side = "left"
			return self:AddSection(title)
		end

		return self:AddSection(title, "left", sectionicon)
	end

	function librarysettingstab:AddRightSection(title, sectionicon)
		if type(title) == "table" then
			title.Side = "right"
			return self:AddSection(title)
		end

		return self:AddSection(title, "right", sectionicon)
	end

	function librarysettingstab:Select()
		if not settingsbutton.Visible then
			return false
		end

		selectmain(settingsbutton)
		expandsubtabs(false)
		showpage("settings")
		return true
	end

	function librarysettingstab:Configure(config)
		librarysetsettingstab(config)
		self.Name = settingstext.Text
	end

	function librarysettingstab:SetVisible(value)
		librarysetsettingstab({
			Enabled = value == true,
			Name = settingstext.Text,
			Icon = settingsicon.Image,
			GroupName = othertext.Text,
		})
	end

	return librarysettingstab
end

function libraryresetnavigation()
	for _, button in ipairs({
		homebutton,
		combatbutton,
		farmingbutton,
		componentsbutton,
	}) do
		button.Visible = false
	end

	subholder.Visible = false

	for _, page in pairs({
		home,
		combatmain,
		combatvisuals,
		combatextras,
		farming,
		components,
	}) do
		if page and page.frame then
			page.frame.Visible = false
		end
	end

	mainnavorder = {}
	subnavorder = {}
	libraryactivetabsection = nil
	currentnav = nil
	currentsub = nil
	currentpage = nil

	topnavigation.Visible = false
	breadcrumb.Visible = true

	if topnavigationtoggle and topnavigationtoggle.Object then
		topnavigationtoggle.Object.Visible = true
	end

	refreshsidegroups(false)
end

function librarycreatetab(windowapi, options, icon, group)
	if type(options) ~= "table" then
		options = {
			Name = options,
			Icon = icon,
			Group = group,
		}
	end

	librarytabserial += 1

	local name = tostring(options.Name or options.Title or ("Tab " .. librarytabserial))
	local asset = librarynormalizeicon(options.Icon or options.Asset)
	local requestedgroup = options.Group
		or options.Section
		or (libraryactivetabsection and libraryactivetabsection.Name)
		or "main"
	local destination = string.lower(tostring(requestedgroup))
	local sectiontab = librarytabsectionlookup[destination]
	local parentobject

	if destination == "other" then
		parentobject = othercontent
	elseif destination == "main" then
		parentobject = maincontent
	elseif sectiontab then
		parentobject = sectiontab.Content
	else
		destination = "main"
		parentobject = maincontent
	end

	local pageid = "__blush_library_tab_" .. tostring(librarytabserial)
	local page = createpage(pageid, name, nil)
	page.icon = asset

	local button
	local textobject
	local indicator
	local iconobject
	local glow

	button,
		textobject,
		indicator,
		iconobject,
		glow =
		navbutton(
			parentobject,
			name,
			asset,
			false
		)

	naventries[button] = {
		button = button,
		sub = false,
		text = textobject,
		indicator = indicator,
		icon = iconobject,
		glow = glow,
	}

	setsidebarentrycompact(
		naventries[button],
		sidebarcompact,
		false
	)

	bindnavhover(button, false)

	if destination == "main" then
		table.insert(mainnavorder, button)
		bindnavdrag(button, mainnavorder)
		applynavorder()
	elseif sectiontab then
		table.insert(sectiontab.Order, button)

		local function applysectionorder()
			for index, item in ipairs(sectiontab.Order) do
				item.LayoutOrder = index * 10
			end
		end

		applysectionorder()
		bindnavdrag(button, sectiontab.Order, applysectionorder)
	else
		button.LayoutOrder = #librarytaborder + 1
	end

	local tab = {
		Name = name,
		Page = page,
		Button = button,
		TextObject = textobject,
		Group = destination,
	}

	registergradienttarget(button, textobject)

	function tab:AddSection(title, column, sectionicon)
		if type(title) == "table" then
			local config = title
			column = string.lower(tostring(config.Side or config.Column or "left"))

			if column ~= "right" then
				column = "left"
			end

			return libraryenhancesection(
				createsection(
					page,
					column,
					tostring(config.Name or config.Title or "Section"),
					config.Icon and librarynormalizeicon(config.Icon) or nil
				)
			)
		end

		column = string.lower(tostring(column or "left"))

		if column ~= "right" then
			column = "left"
		end

		return libraryenhancesection(
			createsection(
				page,
				column,
				tostring(title or "Section"),
				sectionicon and librarynormalizeicon(sectionicon) or nil
			)
		)
	end

	function tab:AddLeftSection(title, sectionicon)
		if type(title) == "table" then
			title.Side = "left"
			return self:AddSection(title)
		end

		return self:AddSection(title, "left", sectionicon)
	end

	function tab:AddRightSection(title, sectionicon)
		if type(title) == "table" then
			title.Side = "right"
			return self:AddSection(title)
		end

		return self:AddSection(title, "right", sectionicon)
	end

	function tab:Select()
		selectmain(button)
		expandsubtabs(false)
		showpage(pageid)
	end

	function tab:SetName(value)
		local oldname = self.Name
		name = tostring(value or name)

		if librarytabs[oldname] == self then
			librarytabs[oldname] = nil
		end

		self.Name = name
		librarytabs[name] = self
		textobject.Text = name
		page.primary = name

		if currentpage == page then
			titleprimary.Text = name
		end
	end

	function tab:SetIcon(value)
		local assetvalue =
			value ~= nil
			and librarynormalizeicon(value)
			or nil

		page.icon = assetvalue
		iconobject =
			setnaventryicon(
				naventries[button],
				assetvalue
			)

		refreshhotkeylist()
	end

	function tab:SetGradient(value)
		return settextgradient(textobject, value)
	end

	function tab:SetRainbow(value)
		return settextrainbow(textobject, value)
	end

	function tab:SetVisible(value)
		button.Visible = value ~= false

		if self.Group == "other" then
			libraryrefreshothergroupvisibility()
		end

		refreshsidegroups(false)
	end

	function tab:GetPage()
		return page
	end

	button.Activated:Connect(function()
		if button:GetAttribute("BlushDragSuppress") then
			return
		end

		tab:Select()
	end)

	librarytabs[name] = tab
	table.insert(librarytaborder, tab)

	if destination == "other" then
		libraryrefreshothergroupvisibility()
	end

	if not windowapi._firsttab then
		windowapi._firsttab = tab
		tab:Select()

		if topnavigationenabled then
			applytopnavigation(true, false)
		end
	end

	refreshsidegroups(false)

	return tab
end

function library:CreateWindow(options)
	options = options or {}

	if librarywindow then
		return librarywindow
	end

	libraryresetnavigation()

	local title = options.Title or options.Name or "blush."
	local versiontext = options.Version or ("v" .. library.Version)
	local size = options.Size
	local position = options.Position
	local settingsconfig = options.SettingsTab

	if settingsconfig == nil then
		settingsconfig = {
			Enabled = options.Settings ~= false,
		}
	end

	librarysetbrand(title, versiontext)
	librarysetlogo(options.Logo, options.LogoColor)
	librarysetsettingstab(settingsconfig)

	windowresizeenabled = options.Resize ~= false
	windowdragenabled = options.Draggable ~= false

	if options.MinimizeButton ~= nil then
		windowminimizebuttonenabled =
			options.MinimizeButton == true
	end

	if options.SidebarResize ~= nil then
		sidebarresizehandle.Visible = options.SidebarResize == true
		sidebarresizehandle.Active = options.SidebarResize == true
	end

	if options.SidebarWidth ~= nil then
		applysidebarlayout(options.SidebarWidth, false)
	end

	windowminsize = typeof(options.MinSize) == "Vector2"
		and options.MinSize
		or Vector2.new(620, 440)

	windowmaxsize = typeof(options.MaxSize) == "Vector2"
		and options.MaxSize
		or nil

	resizehandle.Visible = windowresizeenabled
	resizehandle.Active = windowresizeenabled

	setminimizebuttonvisible(windowminimizebuttonenabled, false)

	if minimizebuttoncontrol then
		minimizebuttoncontrol:Set(
			windowminimizebuttonenabled,
			false
		)
	end


	if options.Roundness ~= nil then
		windowcorner.CornerRadius = UDim.new(
			0,
			math.max(0, tonumber(options.Roundness) or 12)
		)
	end

	if options.Stroke ~= nil then
		windowstroke.Enabled = options.Stroke == true
	end

	if options.Shadow ~= nil then
		windowshadowenabled = options.Shadow == true
		applywindowshadow()
	end

	if options.Glow ~= nil then
		windowglowenabled = options.Glow == true
	end

	if options.GlowIntensity ~= nil then
		windowglowintensity = math.clamp(
			tonumber(options.GlowIntensity) or windowglowintensity,
			0,
			100
		)
	end

	if options.GlowSize ~= nil then
		windowglowsize = math.clamp(
			tonumber(options.GlowSize) or windowglowsize,
			0,
			24
		)
	end

	if typeof(options.GlowColor) == "Color3" then
		windowglowcolor = options.GlowColor
	else
		windowglowcolor = theme.white
	end

	if options.GlowAlpha ~= nil then
		windowglowalpha = math.clamp(
			tonumber(options.GlowAlpha) or windowglowalpha,
			0,
			1
		)
	end

	windowglowrenderalpha =
		windowglowalpha

	applywindowglow()

	if windowglowtoggle then
		windowglowtoggle:Set(windowglowenabled, false)
	end
	if windowglowintensitycontrol then
		windowglowintensitycontrol:Set(windowglowintensity, false)
	end
	if windowglowsizecontrol then
		windowglowsizecontrol:Set(windowglowsize, false)
	end
	if windowglowcolorpicker then
		windowglowcolorpicker:Set(
			windowglowcolor,
			windowglowalpha,
			false
		)

		windowglowrenderalpha =
			windowglowcolorpicker:currentalpha()
	end

	if options.Transparency ~= nil then
		local value = math.clamp(
			tonumber(options.Transparency) or 0,
			0,
			90
		)

		if uitransparencycontrol then
			uitransparencycontrol:Set(value, false)
		end

		applyuitransparency(value)
	end

	if typeof(size) == "Vector2" then
		originalwindowsize = size
		shell.Size = UDim2.fromOffset(size.X, size.Y)

		if typeof(position) ~= "UDim2" then
			shell.Position = centeredwindowposition(size, env.__blush_shellscale.Scale)
		end
	end

	if typeof(position) == "UDim2" then
		shell.Position = position
	end

	if options.Scale ~= nil then
		applyuiscale(options.Scale)
	end

	if type(options.Theme) == "table" then
		applytheme(
			options.Theme.Background or options.Theme.Window or theme.window,
			options.Theme.Accent or theme.white,
			options.Theme.BackgroundAlpha or theme.backgroundAlpha,
			options.Theme.AccentAlpha or theme.accentAlpha,
			options.Theme.Font or options.Theme.Text or theme.font,
			options.Theme.FontAlpha or theme.fontAlpha,
			options.Theme.Animate ~= false
		)
	end

	if options.MenuKey ~= nil then
		local key = options.MenuKey

		if typeof(key) == "string" then
			key = keyfromname(key)
		end

		if typeof(key) == "EnumItem" then
			menukey = key
			refreshmenukeybinding()

			if menukeypicker then
				menukeypicker:Set(key, false)
			end
		end
	end

	if options.Animations ~= nil then
		animationsenabled = options.Animations == true

		if animationtoggle then
			animationtoggle:Set(animationsenabled, false)
		end
	end

	if options.Search ~= nil then
		setsearchvisible(options.Search == true, false)

		if searchtoggle then
			searchtoggle:Set(searchenabled, false)
		end
	end

	if options.Notifications ~= nil then
		notificationsenabled = options.Notifications == true

		if notificationtoggle then
			notificationtoggle:Set(notificationsenabled, false)
		end
	end

	if options.Watermark ~= nil then
		local visible = options.Watermark == true
		setwatermarkvisible(visible, false)

		if watermarktoggle then
			watermarktoggle:Set(visible, false)
		end
	end

	if type(options.WatermarkInfo) == "table" then
		for _, item in ipairs({
			"Player",
			"Ping",
			"Time",
		}) do
			if options.WatermarkInfo[item] ~= nil then
				watermarkconfig[item] =
					options.WatermarkInfo[item] == true
			end
		end

		if options.WatermarkInfo.FPS ~= nil then
			watermarkconfig.FPS =
				options.WatermarkInfo.FPS == true
		elseif options.WatermarkInfo.Fps ~= nil then
			watermarkconfig.FPS =
				options.WatermarkInfo.Fps == true
		end

		if options.WatermarkInfo.PlayerMode ~= nil then
			watermarkconfig.PlayerMode =
				normalizewatermarkplayermode(
					options.WatermarkInfo.PlayerMode
				)
		end

		if watermarkinfocontrol then
			local values = {}

			for _, item in ipairs({
				"Player",
				"Fps",
				"Ping",
				"Time",
			}) do
				local enabled =
					item == "Fps"
						and watermarkconfig.FPS
						or watermarkconfig[item]

				if enabled then
					table.insert(values, item)
				end
			end

			watermarkinfocontrol:Set(
				values,
				false
			)
		end

		if watermarkplayermodecontrol then
			watermarkplayermodecontrol:Set(
				watermarkconfig.PlayerMode,
				false
			)
		end

		updatewatermarklayout()
	end

	if options.HotkeyList ~= nil then
		local visible = options.HotkeyList == true
		sethotkeylistvisible(visible)

		if hotkeylisttoggle then
			hotkeylisttoggle:Set(visible, false)
		end
	end

	gui.Enabled = true
	watermarkgui.Enabled = true
	reopengui.Enabled = false

	modalguard.Modal = false
	modalguard.Active = false
	modalguard.Visible = false

	env.__blush_windowvisible = true
	setvisibilityrootsvisible(true)
	forcecursorvisible()

	librarywindow = {
		_tabs = librarytabs,
		_order = librarytaborder,
		_firsttab = nil,
		TextObject = brand,
	}

	librarywindow.Settings = librarygetsettingstab()

	function librarywindow:AddSectionTab(name)
		local sectiontab = createlibrarytabsection(name)
		libraryactivetabsection = sectiontab
		return sectiontab
	end

	function librarywindow:AddTab(...)
		return librarycreatetab(self, ...)
	end

	function librarywindow:GetTab(name)
		return librarytabs[tostring(name)]
	end

	function librarywindow:SelectTab(value)
		local tab = value

		if type(value) ~= "table" then
			tab = librarytabs[tostring(value)]
		end

		if tab and tab.Select then
			tab:Select()
			return true
		end

		return false
	end

	function librarywindow:Notify(titletext, bodytext, duration, callback, buttontext, iconasset)
		notify(
			titletext,
			bodytext,
			duration,
			callback,
			buttontext,
			iconasset
		)
	end

	function librarywindow:SetGradient(element, value)
		if value == nil
			and (
				typeof(element) == "ColorSequence"
				or type(element) == "table"
				or type(element) == "string"
			)
		then
			value = element
			element = self
		end

		return settextgradient(element, value)
	end

	function librarywindow:SetTitleGradient(value)
		return settextgradient(brand, value)
	end

	function librarywindow:SetRainbow(element, value)
		if type(element) == "boolean" and value == nil then
			value = element
			element = self
		end

		return settextrainbow(element, value)
	end

	function librarywindow:SetTitleRainbow(value)
		return settextrainbow(brand, value)
	end

	function librarywindow:SetVisible(value)
		requestvisibilitytoggle(value == true)
	end

	function librarywindow:Toggle()
		requestvisibilitytoggle()
	end

	function librarywindow:SetSidebarWidth(value, animate)
		applysidebarlayout(value, animate == true)
	end

	function librarywindow:GetSidebarWidth()
		return sidebarwidth
	end

	function librarywindow:SetSidebarResizeEnabled(value)
		local enabled = value == true
		sidebarresizehandle.Visible = enabled
		sidebarresizehandle.Active = enabled

		if not enabled then
			sidebarresize = nil
			sidebarresizeaccent.BackgroundTransparency = 1
		end
	end

	function librarywindow:SetResizeEnabled(value)
		windowresizeenabled = value == true
		resizehandle.Visible = windowresizeenabled
		resizehandle.Active = windowresizeenabled

		if not windowresizeenabled then
			windowresize = nil
		end
	end

	function librarywindow:SetDraggable(value)
		windowdragenabled = value == true

		if not windowdragenabled then
			windowdrag = nil
		end
	end

	function librarywindow:SetMinimizeButtonVisible(value)
		setminimizebuttonvisible(value, true)

		if minimizebuttoncontrol then
			minimizebuttoncontrol:Set(
				windowminimizebuttonenabled,
				false
			)
		end
	end

	function librarywindow:SetMinSize(value)
		if typeof(value) ~= "Vector2" then
			return false
		end

		windowminsize = value
		return true
	end

	function librarywindow:SetMaxSize(value)
		if value == nil then
			windowmaxsize = nil
			return true
		end

		if typeof(value) ~= "Vector2" then
			return false
		end

		windowmaxsize = value
		return true
	end

	function librarywindow:SetSize(value, recenter)
		if typeof(value) ~= "Vector2" then
			return false
		end

		originalwindowsize = value
		shell.Size = UDim2.fromOffset(value.X, value.Y)

		if recenter == true then
			shell.Position = centeredwindowposition(
				value,
				(env.__blush_shellscale and env.__blush_shellscale.Scale) or 1
			)
		end

		if currentpage then
			currentpage:reflowall(false)
		end

		return true
	end

	function librarywindow:GetSize()
		return Vector2.new(
			shell.Size.X.Offset,
			shell.Size.Y.Offset
		)
	end

	function librarywindow:SetPosition(value)
		if typeof(value) ~= "UDim2" then
			return false
		end

		shell.Position = value
		return true
	end

	function librarywindow:GetPosition()
		return shell.Position
	end

	function librarywindow:SetLogo(asset, color)
		librarysetlogo(asset, color)
	end

	function librarywindow:SetGlowEnabled(value)
		windowglowenabled = value == true
		applywindowglow()

		if windowglowtoggle then
			windowglowtoggle:Set(windowglowenabled, false)
		end
	end

	function librarywindow:SetGlowIntensity(value)
		windowglowintensity = math.clamp(
			tonumber(value) or windowglowintensity,
			0,
			100
		)

		applywindowglow()

		if windowglowintensitycontrol then
			windowglowintensitycontrol:Set(windowglowintensity, false)
		end
	end

	function librarywindow:SetGlowSize(value)
		windowglowsize = math.clamp(
			tonumber(value) or windowglowsize,
			0,
			24
		)

		applywindowglow()

		if windowglowsizecontrol then
			windowglowsizecontrol:Set(windowglowsize, false)
		end
	end

	function librarywindow:SetGlowAlpha(value)
		windowglowalpha = math.clamp(
			tonumber(value) or windowglowalpha,
			0,
			1
		)

		windowglowrenderalpha =
			windowglowalpha

		if windowglowcolorpicker then
			windowglowcolorpicker:Set(
				windowglowcolor,
				windowglowalpha,
				false
			)
		end

		applywindowglow()
	end

	function librarywindow:SetGlowColor(value)
		if typeof(value) ~= "Color3" then
			return false
		end

		windowglowcolor = value
		applywindowglow()

		if windowglowcolorpicker then
			windowglowcolorpicker:Set(
				value,
				windowglowalpha,
				false
			)

			windowglowrenderalpha =
				windowglowcolorpicker:currentalpha()
		end

		return true
	end

	function librarywindow:SetTransparency(value)
		value = math.clamp(
			tonumber(value) or 0,
			0,
			90
		)

		if uitransparencycontrol then
			uitransparencycontrol:Set(value, false)
		end

		applyuitransparency(value)
	end

	function librarywindow:SetRoundness(value)
		windowcorner.CornerRadius = UDim.new(
			0,
			math.max(0, tonumber(value) or 0)
		)
	end

	function librarywindow:SetStrokeVisible(value)
		windowstroke.Enabled = value == true
	end

	function librarywindow:SetShadowVisible(value)
		windowshadowenabled = value == true
		applywindowshadow()
	end

	function librarywindow:SetSettingsTab(config)
		librarysetsettingstab(config)
	end

	function librarywindow:GetSettingsTab()
		return librarygetsettingstab()
	end

	function librarywindow:SetMenuKey(key)
		if typeof(key) == "string" then
			key = keyfromname(key)
		end

		if typeof(key) ~= "EnumItem" then
			return false
		end

		menukey = key
		refreshmenukeybinding()

		if menukeypicker then
			menukeypicker:Set(key, false)
		end

		return true
	end

	function librarywindow:SetWatermark(value)
		local visible = value == true
		setwatermarkvisible(visible, true)

		if watermarktoggle then
			watermarktoggle:Set(visible, false)
		end
	end

	function librarywindow:SetWatermarkInfo(config)
		if type(config) ~= "table" then
			return false
		end

		for _, item in ipairs({
			"Player",
			"Ping",
			"Time",
		}) do
			if config[item] ~= nil then
				watermarkconfig[item] =
					config[item] == true
			end
		end

		if config.FPS ~= nil then
			watermarkconfig.FPS =
				config.FPS == true
		elseif config.Fps ~= nil then
			watermarkconfig.FPS =
				config.Fps == true
		end

		if config.PlayerMode ~= nil then
			watermarkconfig.PlayerMode =
				normalizewatermarkplayermode(
					config.PlayerMode
				)
		end

		if watermarkinfocontrol then
			local values = {}

			for _, item in ipairs({
				"Player",
				"Fps",
				"Ping",
				"Time",
			}) do
				local enabled =
					item == "Fps"
						and watermarkconfig.FPS
						or watermarkconfig[item]

				if enabled then
					table.insert(values, item)
				end
			end

			watermarkinfocontrol:Set(
				values,
				false
			)
		end

		if watermarkplayermodecontrol then
			watermarkplayermodecontrol:Set(
				watermarkconfig.PlayerMode,
				false
			)
		end

		updatewatermarklayout()
		return true
	end

	function librarywindow:SetHotkeyList(value)
		local visible = value == true
		sethotkeylistvisible(visible)

		if hotkeylisttoggle then
			hotkeylisttoggle:Set(visible, false)
		end
	end

	function librarywindow:SetAnimations(value)
		animationsenabled = value == true

		if animationtoggle then
			animationtoggle:Set(animationsenabled, false)
		end
	end

	function librarywindow:SetSearch(value)
		setsearchvisible(value, true)

		if not searchenabled then
			search.Text = ""
		end

		if searchtoggle then
			searchtoggle:Set(searchenabled, false)
		end
	end

	function librarywindow:SetNotifications(value)
		notificationsenabled = value == true

		if notificationtoggle then
			notificationtoggle:Set(notificationsenabled, false)
		end
	end

	function librarywindow:SetBackground(source, opacity, blur)
		if source == nil or tostring(source) == "" then
			clearbackgroundimage(true)
			return true
		end

		if opacity ~= nil then
			setbackgroundimageopacity(opacity, false)
		end

		if blur ~= nil then
			setbackgroundimageblur(blur, false)
		end

		return loadbackgroundimage(
			tostring(source),
			true,
			false
		)
	end

	function librarywindow:ClearBackground()
		clearbackgroundimage(true)
	end

	function librarywindow:SetBackgroundOpacity(value)
		setbackgroundimageopacity(value, true)
	end

	function librarywindow:SetBackgroundBlur(value)
		setbackgroundimageblur(value, true)
	end

	function librarywindow:SetBackgroundExcludeSidebar(value)
		setbackgroundexcludesidebar(value == true)
	end

	function librarywindow:SetAutoBackgroundColors()
		autobackgroundcolors = false
		backgroundautobase = nil
		return false
	end

	function librarywindow:SetScale(value)
		applyuiscale(value)
	end

	function librarywindow:SetTheme(config)
		config = config or {}

		applytheme(
			config.Background or config.Window or theme.window,
			config.Accent or theme.white,
			config.BackgroundAlpha or theme.backgroundAlpha,
			config.AccentAlpha or theme.accentAlpha,
			config.Font or config.Text or theme.font,
			config.FontAlpha or theme.fontAlpha,
			config.Animate ~= false
		)
	end

	function librarywindow:GetTheme()
		return {
			Background = theme.window,
			Accent = theme.white,
			Font = theme.font,
			BackgroundAlpha = theme.backgroundAlpha,
			AccentAlpha = theme.accentAlpha,
			FontAlpha = theme.fontAlpha,
		}
	end

	function librarywindow:SetSettingsVisible(value)
		settingsbutton.Visible = value ~= false
		libraryrefreshothergroupvisibility()
	end

	function librarywindow:SetTitle(value)
		librarysetbrand(value, version.Text)
	end

	function librarywindow:SetVersion(value)
		version.Text = tostring(value or "")
		updatebrandlayout()
	end

	function librarywindow:GetGui()
		return gui
	end

	function librarywindow:Destroy()
		env.__blush_cleanup()
		librarywindow = nil
	end

	if options.BackgroundExcludeSidebar ~= nil then
		librarywindow:SetBackgroundExcludeSidebar(
			options.BackgroundExcludeSidebar == true
		)
	end

	if options.AutoBackgroundColors ~= nil then
		librarywindow:SetAutoBackgroundColors(
			options.AutoBackgroundColors == true
		)
	end

	if options.Background ~= nil then
		task.defer(function()
			librarywindow:SetBackground(
				options.Background,
				options.BackgroundOpacity,
				options.BackgroundBlur
			)
		end)
	end

	if options.NotifyLoaded ~= false then
		notify(
			tostring(title),
			"Interface loaded",
			2.5
		)
	end

	return librarywindow
end

function library:GetSettingsTab()
	return librarygetsettingstab()
end

function library:Notify(...)
	notify(...)
end

function library:SetGradient(element, value)
	return settextgradient(element, value)
end

function library:SetRainbow(element, value)
	return settextrainbow(element, value)
end

function library:Destroy()
	env.__blush_cleanup()
	librarywindow = nil
end

gui.Enabled = false
watermarkgui.Enabled = false
reopengui.Enabled = false
modalguard.Modal = false
modalguard.Active = false
modalguard.Visible = false

return library
