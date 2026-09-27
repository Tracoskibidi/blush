local S = {}

function S.nextscope(adapter, key, values)
	values = table.pack(adapter.iterator(adapter.invariant, key))
	if values[1] == nil then return nil end
	values[adapter.count + 1] = {}
	return table.unpack(values, 1, adapter.count + 1)
end

function S.scopediterator(count, iterator, invariant, control)
	return S.nextscope, { count = count, iterator = iterator, invariant = invariant }, control
end

S.constructing = true

function S.invoke(callback, ...) return true, callback(...) end

S.players = game:GetService("Players")
S.uis = game:GetService("UserInputService")
S.tweenservice = game:GetService("TweenService")
S.runservice = game:GetService("RunService")
S.stats = game:GetService("Stats")
S.textservice = game:GetService("TextService")
S.httpservice = game:GetService("HttpService")
S.guiservice = game:GetService("GuiService")
S.contextactionservice = game:GetService("ContextActionService")
S.assetservice = game:GetService("AssetService")
S.lighting = game:GetService("Lighting")

S.player = S.players.LocalPlayer
S.parent = gethui and gethui() or S.player:WaitForChild("PlayerGui")

S.runtimebridge = S.parent:FindFirstChild("blush_runtime")
if S.runtimebridge and S.runtimebridge:IsA("BindableEvent") then
	S.runtimebridge:Fire()
	S.runtimebridge:Destroy()
end

if S.uis.TouchEnabled then
	task.defer(
		function()
			game:GetService("StarterGui"):SetCore("SendNotification", {
				Title = "blush UI",
				Text = "Mobile is not supported.",
				Duration = 5,
			})
		end
	)

	return
end

S.runtimebridge = Instance.new("BindableEvent")
S.runtimebridge.Name = "blush_runtime"
S.runtimebridge.Parent = S.parent

S.gui = nil
S.watermarkgui = nil
S.connections = {}

function S.connect(signal, callback, connection)
	if #S.connections >= 64 and #S.connections % 32 == 0 then
		for index = #S.connections, 1, -1 do
			if not S.connections[index].Connected then table.remove(S.connections, index) end
		end
	end

	connection = signal:Connect(callback)
	table.insert(S.connections, connection)
	return connection
end

S.__blush_cleanup = function(autosavetask, settingstask)
	if S.pagelayoutconnection then
		S.pagelayoutconnection:Disconnect()
		S.pagelayoutconnection = nil
	end
	if S.pendingpagelayouts then table.clear(S.pendingpagelayouts) end
	S.contextactionservice:UnbindAction("__blush_menu_key")
	if S.interactionrenderconnection and S.interactionrenderconnection.Connected then
		S.interactionrenderconnection:Disconnect()
		S.interactionrenderconnection = nil
	end

	if S.pickeranimationconnection and S.pickeranimationconnection.Connected then
		S.pickeranimationconnection:Disconnect()
		S.pickeranimationconnection = nil
	end

	if S.animateduiconnection and S.animateduiconnection.Connected then
		S.animateduiconnection:Disconnect()
		S.animateduiconnection = nil
	end

	if S.rainbowtextconnection and S.rainbowtextconnection.Connected then
		S.rainbowtextconnection:Disconnect()
		S.rainbowtextconnection = nil
	end

	if S.watermarkstatsconnection and S.watermarkstatsconnection.Connected then
		S.watermarkstatsconnection:Disconnect()
		S.watermarkstatsconnection = nil
	end

	autosavetask = S.__blush_autosave_task
	if autosavetask and coroutine.status(autosavetask) == "suspended" then
		pcall(task.cancel, autosavetask)
	end
	S.__blush_autosave_task = nil

	settingstask = S.__blush_save_task
	if settingstask and coroutine.status(settingstask) == "suspended" then
		pcall(task.cancel, settingstask)
	end
	S.__blush_save_task = nil


	if S.destroybackgroundeditable then S.destroybackgroundeditable() end

	if S.closemodal then S.closemodal(true) end

	for _, connection in ipairs(S.connections) do
		if connection.Connected then connection:Disconnect() end
	end

	table.clear(S.connections)

	if S.gui and S.gui.Parent then S.gui:Destroy() end


	if S.reopengui and S.reopengui.Parent then S.reopengui:Destroy() end

	if S.watermarkgui and S.watermarkgui.Parent then S.watermarkgui:Destroy() end

	if S.runtimebridge and S.runtimebridge.Parent then S.runtimebridge:Destroy() end

	S.__blush_notify = nil
	S.__blush_background = nil
end

table.insert(S.connections, S.runtimebridge.Event:Connect(S.__blush_cleanup))

S.old = S.parent:FindFirstChild("blush")

if S.old then S.old:Destroy() end


S.oldreopen = S.parent:FindFirstChild("blush_reopen")
if S.oldreopen then S.oldreopen:Destroy() end

S.oldwatermark = S.parent:FindFirstChild("blush_watermark")
if S.oldwatermark then S.oldwatermark:Destroy() end

function S.playerthumb(targetplayer, userid)
	userid = targetplayer and targetplayer.UserId or S.player.UserId
	return string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150", userid)
end

S.thumbnail = S.playerthumb(S.player)

function S.getplayerthumbnail(targetplayer) return S.playerthumb(targetplayer) end

S.gui = Instance.new("ScreenGui")
S.gui.Name = "blush"
S.gui.IgnoreGuiInset = true
S.gui.ResetOnSpawn = false
S.gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

S.gui.Enabled = false
S.gui.Parent = S.parent

S.watermarkgui = Instance.new("ScreenGui")
S.watermarkgui.Name = "blush_watermark"
S.watermarkgui.IgnoreGuiInset = true
S.watermarkgui.ResetOnSpawn = false
S.watermarkgui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
S.watermarkgui.DisplayOrder = 1000

S.watermarkgui.Enabled = false
S.watermarkgui.Parent = S.parent

S.theme = {
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

	-- Main drives interactive/control surfaces; lighter roles are derived from it.
	main = Color3.fromRGB(19, 19, 21),
	highlight = Color3.fromRGB(246, 246, 248),
	white = Color3.fromRGB(246, 246, 248),
	black = Color3.fromRGB(14, 14, 15),
	font = Color3.fromRGB(235, 235, 239),

	mainAlpha = 1,
	highlightAlpha = 1,
	accentAlpha = 1,
	backgroundAlpha = 1,
	fontAlpha = 1,
}

S.icons = {
	["a-arrow-down"] = "rbxassetid://92867583610071",
	["a-arrow-up"] = "rbxassetid://132318504999733",
	["a-large-small"] = "rbxassetid://111491496660216",
	["accessibility"] = "rbxassetid://114029945302017",
	["activity"] = "rbxassetid://94212016861936",
	["air-vent"] = "rbxassetid://81517226012329",
	["airplay"] = "rbxassetid://115020759309179",
	["alarm-clock-check"] = "rbxassetid://76437352099157",
	["alarm-clock-minus"] = "rbxassetid://77364179863205",
	["alarm-clock-off"] = "rbxassetid://97904885874823",
	["alarm-clock-plus"] = "rbxassetid://80468822979214",
	["alarm-clock"] = "rbxassetid://126259032907535",
	["alarm-smoke"] = "rbxassetid://96965448419685",
	["album"] = "rbxassetid://127358331163602",
	["align-center-horizontal"] = "rbxassetid://81570549209434",
	["align-center-vertical"] = "rbxassetid://118470463752466",
	["align-end-horizontal"] = "rbxassetid://139502909745427",
	["align-end-vertical"] = "rbxassetid://96528869059554",
	["align-horizontal-distribute-center"] = "rbxassetid://97220086126656",
	["align-horizontal-distribute-end"] = "rbxassetid://106128590702022",
	["align-horizontal-distribute-start"] = "rbxassetid://76074660002997",
	["align-horizontal-justify-center"] = "rbxassetid://75732302772427",
	["align-horizontal-justify-end"] = "rbxassetid://129167626402283",
	["align-horizontal-justify-start"] = "rbxassetid://130161830325281",
	["align-horizontal-space-around"] = "rbxassetid://91646106782950",
	["align-horizontal-space-between"] = "rbxassetid://103886093046990",
	["align-start-horizontal"] = "rbxassetid://125674804697729",
	["align-start-vertical"] = "rbxassetid://105020230154823",
	["align-vertical-distribute-center"] = "rbxassetid://93791183635525",
	["align-vertical-distribute-end"] = "rbxassetid://139354223511433",
	["align-vertical-distribute-start"] = "rbxassetid://74961997822126",
	["align-vertical-justify-center"] = "rbxassetid://134754696166569",
	["align-vertical-justify-end"] = "rbxassetid://92569381441969",
	["align-vertical-justify-start"] = "rbxassetid://99692844572718",
	["align-vertical-space-around"] = "rbxassetid://96206012459190",
	["align-vertical-space-between"] = "rbxassetid://124998077349706",
	["ambulance"] = "rbxassetid://78599995190651",
	["ampersand"] = "rbxassetid://75272915739209",
	["ampersands"] = "rbxassetid://126947193455996",
	["amphora"] = "rbxassetid://137370389604364",
	["anchor"] = "rbxassetid://92181172123618",
	["angry"] = "rbxassetid://74237056000103",
	["annoyed"] = "rbxassetid://80064369052011",
	["antenna"] = "rbxassetid://99628923540956",
	["anvil"] = "rbxassetid://100203029845919",
	["aperture"] = "rbxassetid://83396154449972",
	["app-window-mac"] = "rbxassetid://79587216113811",
	["app-window"] = "rbxassetid://93142176757189",
	["apple"] = "rbxassetid://104349242902442",
	["archive-restore"] = "rbxassetid://78956681942188",
	["archive-x"] = "rbxassetid://75830115088395",
	["archive"] = "rbxassetid://122180020814574",
	["armchair"] = "rbxassetid://105384358373973",
	["arrow-big-down-dash"] = "rbxassetid://137987229582002",
	["arrow-big-down"] = "rbxassetid://81081164158885",
	["arrow-big-left-dash"] = "rbxassetid://97827621354677",
	["arrow-big-left"] = "rbxassetid://85973092492641",
	["arrow-big-right-dash"] = "rbxassetid://117825834972403",
	["arrow-big-right"] = "rbxassetid://82960676755590",
	["arrow-big-up-dash"] = "rbxassetid://99260194327483",
	["arrow-big-up"] = "rbxassetid://93136954756149",
	["arrow-down-0-1"] = "rbxassetid://120961896217875",
	["arrow-down-1-0"] = "rbxassetid://93474255891850",
	["arrow-down-a-z"] = "rbxassetid://99554596207900",
	["arrow-down-from-line"] = "rbxassetid://132045845807798",
	["arrow-down-left"] = "rbxassetid://102899325237364",
	["arrow-down-narrow-wide"] = "rbxassetid://129105261655061",
	["arrow-down-right"] = "rbxassetid://123109928624974",
	["arrow-down-to-dot"] = "rbxassetid://101675355931221",
	["arrow-down-to-line"] = "rbxassetid://87050478931254",
	["arrow-down-up"] = "rbxassetid://85780258549577",
	["arrow-down-wide-narrow"] = "rbxassetid://88461733425991",
	["arrow-down-z-a"] = "rbxassetid://76115279362232",
	["arrow-down"] = "rbxassetid://98764963621439",
	["arrow-left-from-line"] = "rbxassetid://87857914437603",
	["arrow-left-right"] = "rbxassetid://131324733048447",
	["arrow-left-to-line"] = "rbxassetid://118645136026970",
	["arrow-left"] = "rbxassetid://102531941843733",
	["arrow-right-from-line"] = "rbxassetid://74073639809355",
	["arrow-right-left"] = "rbxassetid://77015754304300",
	["arrow-right-to-line"] = "rbxassetid://78632510329852",
	["arrow-right"] = "rbxassetid://113692007244654",
	["arrow-up-0-1"] = "rbxassetid://105257823943016",
	["arrow-up-1-0"] = "rbxassetid://134175521693798",
	["arrow-up-a-z"] = "rbxassetid://77763416595160",
	["arrow-up-down"] = "rbxassetid://81019887641527",
	["arrow-up-from-dot"] = "rbxassetid://124408496673275",
	["arrow-up-from-line"] = "rbxassetid://95777664626453",
	["arrow-up-left"] = "rbxassetid://123490598231261",
	["arrow-up-narrow-wide"] = "rbxassetid://73006024672636",
	["arrow-up-right"] = "rbxassetid://129280608535523",
	["arrow-up-to-line"] = "rbxassetid://108818207813537",
	["arrow-up-wide-narrow"] = "rbxassetid://87437426951568",
	["arrow-up-z-a"] = "rbxassetid://107546173611884",
	["arrow-up"] = "rbxassetid://89282378235317",
	["arrows-up-from-line"] = "rbxassetid://133710016938621",
	["asterisk"] = "rbxassetid://88552752106723",
	["at-sign"] = "rbxassetid://79059152889146",
	["atom"] = "rbxassetid://73167696981648",
	["audio-lines"] = "rbxassetid://70930641819242",
	["audio-waveform"] = "rbxassetid://86462036665209",
	["award"] = "rbxassetid://132740088158419",
	["axe"] = "rbxassetid://132405197863294",
	["axis-3d"] = "rbxassetid://122438676546804",
	["baby"] = "rbxassetid://93472926933440",
	["backpack"] = "rbxassetid://140420225386018",
	["badge-alert"] = "rbxassetid://101829200081951",
	["badge-cent"] = "rbxassetid://133345018873154",
	["badge-check"] = "rbxassetid://76078495178149",
	["badge-dollar-sign"] = "rbxassetid://127139803581141",
	["badge-euro"] = "rbxassetid://120016477674659",
	["badge-indian-rupee"] = "rbxassetid://75659682309981",
	["badge-info"] = "rbxassetid://131995373201472",
	["badge-japanese-yen"] = "rbxassetid://99081574588615",
	["badge-minus"] = "rbxassetid://140321561183881",
	["badge-percent"] = "rbxassetid://121359224294885",
	["badge-plus"] = "rbxassetid://100325578561866",
	["badge-pound-sterling"] = "rbxassetid://119688217279444",
	["badge-question-mark"] = "rbxassetid://121464963737502",
	["badge-russian-ruble"] = "rbxassetid://108839463659864",
	["badge-swiss-franc"] = "rbxassetid://91447608372740",
	["badge-turkish-lira"] = "rbxassetid://137839965873529",
	["badge-x"] = "rbxassetid://122931434733842",
	["badge"] = "rbxassetid://116620312917084",
	["baggage-claim"] = "rbxassetid://86922213051957",
	["ban"] = "rbxassetid://90767043015246",
	["banana"] = "rbxassetid://140713420056179",
	["bandage"] = "rbxassetid://129660129590770",
	["banknote-arrow-down"] = "rbxassetid://139366449345199",
	["banknote-arrow-up"] = "rbxassetid://133758343082529",
	["banknote-x"] = "rbxassetid://95348701438065",
	["banknote"] = "rbxassetid://104840231536668",
	["barcode"] = "rbxassetid://118473018143689",
	["barrel"] = "rbxassetid://130647115622774",
	["baseline"] = "rbxassetid://124677132511270",
	["bath"] = "rbxassetid://76031400297942",
	["battery-charging"] = "rbxassetid://80139357470047",
	["battery-full"] = "rbxassetid://70906718268972",
	["battery-low"] = "rbxassetid://139659256984314",
	["battery-medium"] = "rbxassetid://105934079398915",
	["battery-plus"] = "rbxassetid://91931341486966",
	["battery-warning"] = "rbxassetid://115230083817257",
	["battery"] = "rbxassetid://70765800346189",
	["beaker"] = "rbxassetid://80902539995520",
	["bean-off"] = "rbxassetid://98164436608714",
	["bean"] = "rbxassetid://89491967076869",
	["bed-double"] = "rbxassetid://73820193212911",
	["bed-single"] = "rbxassetid://113423940880634",
	["bed"] = "rbxassetid://97726529032925",
	["beef"] = "rbxassetid://105850162318915",
	["beer-off"] = "rbxassetid://120333134736361",
	["beer"] = "rbxassetid://116404978807744",
	["bell-dot"] = "rbxassetid://93161277118810",
	["bell-electric"] = "rbxassetid://100277767266983",
	["bell-minus"] = "rbxassetid://126334890449727",
	["bell-off"] = "rbxassetid://78560046118930",
	["bell-plus"] = "rbxassetid://77014333795836",
	["bell-ring"] = "rbxassetid://94612128913941",
	["bell"] = "rbxassetid://97392696311902",
	["between-horizontal-end"] = "rbxassetid://81602774794322",
	["between-horizontal-start"] = "rbxassetid://76112384929846",
	["between-vertical-end"] = "rbxassetid://72817612571631",
	["between-vertical-start"] = "rbxassetid://85278312190301",
	["biceps-flexed"] = "rbxassetid://82004462003936",
	["bike"] = "rbxassetid://102930322246035",
	["binary"] = "rbxassetid://91751953950088",
	["binoculars"] = "rbxassetid://101460003267896",
	["biohazard"] = "rbxassetid://95956532900432",
	["bird"] = "rbxassetid://132284145117371",
	["birdhouse"] = "rbxassetid://83999157401433",
	["bitcoin"] = "rbxassetid://95459240442938",
	["blend"] = "rbxassetid://111679612185257",
	["blinds"] = "rbxassetid://71164165283925",
	["blocks"] = "rbxassetid://72212693357737",
	["bluetooth-connected"] = "rbxassetid://96315134002985",
	["bluetooth-off"] = "rbxassetid://80600044218117",
	["bluetooth-searching"] = "rbxassetid://100673019606426",
	["bluetooth"] = "rbxassetid://90506573139443",
	["bold"] = "rbxassetid://116141470019166",
	["bolt"] = "rbxassetid://102881251417484",
	["bomb"] = "rbxassetid://139223800924636",
	["bone"] = "rbxassetid://111242153474115",
	["book-a"] = "rbxassetid://104067275658465",
	["book-alert"] = "rbxassetid://124159928044853",
	["book-audio"] = "rbxassetid://109208148317037",
	["book-check"] = "rbxassetid://115999656081696",
	["book-copy"] = "rbxassetid://108543407492005",
	["book-dashed"] = "rbxassetid://127430784795958",
	["book-down"] = "rbxassetid://101011730128222",
	["book-headphones"] = "rbxassetid://108670200799574",
	["book-heart"] = "rbxassetid://112788845135284",
	["book-image"] = "rbxassetid://80808285757226",
	["book-key"] = "rbxassetid://116024426170705",
	["book-lock"] = "rbxassetid://118765061220571",
	["book-marked"] = "rbxassetid://73211024251780",
	["book-minus"] = "rbxassetid://112724962046282",
	["book-open-check"] = "rbxassetid://130848362492667",
	["book-open-text"] = "rbxassetid://100629528672195",
	["book-open"] = "rbxassetid://129845326810392",
	["book-plus"] = "rbxassetid://140267785051233",
	["book-text"] = "rbxassetid://94011772484232",
	["book-type"] = "rbxassetid://97817304725443",
	["book-up-2"] = "rbxassetid://130161620853665",
	["book-up"] = "rbxassetid://98640174079190",
	["book-user"] = "rbxassetid://128489189240523",
	["book-x"] = "rbxassetid://118754548186537",
	["book"] = "rbxassetid://125383279695672",
	["bookmark-check"] = "rbxassetid://93940443347986",
	["bookmark-minus"] = "rbxassetid://96807096039910",
	["bookmark-plus"] = "rbxassetid://121469724491615",
	["bookmark-x"] = "rbxassetid://112272342584706",
	["bookmark"] = "rbxassetid://121093149326239",
	["boom-box"] = "rbxassetid://99901322535868",
	["bot-message-square"] = "rbxassetid://96145330292478",
	["bot-off"] = "rbxassetid://140417690560013",
	["bot"] = "rbxassetid://80451686744860",
	["bottle-wine"] = "rbxassetid://131675403196921",
	["bow-arrow"] = "rbxassetid://124089655150375",
	["box"] = "rbxassetid://101768155599700",
	["boxes"] = "rbxassetid://136372617578355",
	["braces"] = "rbxassetid://117761094704041",
	["brackets"] = "rbxassetid://74368995728099",
	["brain-circuit"] = "rbxassetid://70547962410202",
	["brain-cog"] = "rbxassetid://132039205501538",
	["brain"] = "rbxassetid://92424107303177",
	["brick-wall-fire"] = "rbxassetid://92980588705520",
	["brick-wall-shield"] = "rbxassetid://75954432775071",
	["brick-wall"] = "rbxassetid://112878522258821",
	["briefcase-business"] = "rbxassetid://129135125207283",
	["briefcase-conveyor-belt"] = "rbxassetid://108665725653714",
	["briefcase-medical"] = "rbxassetid://119917756334087",
	["briefcase"] = "rbxassetid://96754188164225",
	["bring-to-front"] = "rbxassetid://132975903553748",
	["brush-cleaning"] = "rbxassetid://71728977448805",
	["brush"] = "rbxassetid://127035535799640",
	["bubbles"] = "rbxassetid://106183424168227",
	["bug-off"] = "rbxassetid://88020025049245",
	["bug-play"] = "rbxassetid://80107955888092",
	["bug"] = "rbxassetid://83626408925438",
	["building-2"] = "rbxassetid://77873775611951",
	["building"] = "rbxassetid://110616258983082",
	["bus-front"] = "rbxassetid://89863432456045",
	["bus"] = "rbxassetid://133798469717463",
	["cable-car"] = "rbxassetid://128643682205596",
	["cable"] = "rbxassetid://128449944504901",
	["cake-slice"] = "rbxassetid://136769828413242",
	["cake"] = "rbxassetid://103131590503275",
	["calculator"] = "rbxassetid://74915716529646",
	["calendar-1"] = "rbxassetid://98458364171044",
	["calendar-arrow-down"] = "rbxassetid://108415736543437",
	["calendar-arrow-up"] = "rbxassetid://70574654109118",
	["calendar-check-2"] = "rbxassetid://120231170248276",
	["calendar-check"] = "rbxassetid://71551019465748",
	["calendar-clock"] = "rbxassetid://119132152594595",
	["calendar-cog"] = "rbxassetid://122402172360287",
	["calendar-days"] = "rbxassetid://99072017568595",
	["calendar-fold"] = "rbxassetid://117368871270394",
	["calendar-heart"] = "rbxassetid://88839008103676",
	["calendar-minus-2"] = "rbxassetid://98846170279891",
	["calendar-minus"] = "rbxassetid://137354318924383",
	["calendar-off"] = "rbxassetid://109726151749217",
	["calendar-plus-2"] = "rbxassetid://112264562093883",
	["calendar-plus"] = "rbxassetid://125266115249843",
	["calendar-range"] = "rbxassetid://103641849247576",
	["calendar-search"] = "rbxassetid://92010083223634",
	["calendar-sync"] = "rbxassetid://78082218499697",
	["calendar-x-2"] = "rbxassetid://107518051061147",
	["calendar-x"] = "rbxassetid://106703374806500",
	["calendar"] = "rbxassetid://114792700814035",
	["camera-off"] = "rbxassetid://81057636835256",
	["camera"] = "rbxassetid://79950339943067",
	["candy-cane"] = "rbxassetid://71689468772492",
	["candy-off"] = "rbxassetid://110232752314832",
	["candy"] = "rbxassetid://107812129154678",
	["cannabis"] = "rbxassetid://98792006538601",
	["captions-off"] = "rbxassetid://105223545364193",
	["captions"] = "rbxassetid://104960225031445",
	["car-front"] = "rbxassetid://87380942739063",
	["car-taxi-front"] = "rbxassetid://122455403384057",
	["car"] = "rbxassetid://121065933462582",
	["caravan"] = "rbxassetid://120070979471783",
	["card-sim"] = "rbxassetid://134490550095771",
	["carrot"] = "rbxassetid://119118221444304",
	["case-lower"] = "rbxassetid://129303130603241",
	["case-sensitive"] = "rbxassetid://125410273293056",
	["case-upper"] = "rbxassetid://111633433531325",
	["cassette-tape"] = "rbxassetid://137065788934157",
	["cast"] = "rbxassetid://98202245922071",
	["castle"] = "rbxassetid://119275077187784",
	["cat"] = "rbxassetid://124252153404931",
	["cctv"] = "rbxassetid://99979894766624",
	["chart-area"] = "rbxassetid://123446436762366",
	["chart-bar-big"] = "rbxassetid://72336824986044",
	["chart-bar-decreasing"] = "rbxassetid://107217459044963",
	["chart-bar-increasing"] = "rbxassetid://88268905998571",
	["chart-bar-stacked"] = "rbxassetid://98478751113024",
	["chart-bar"] = "rbxassetid://105389816384108",
	["chart-candlestick"] = "rbxassetid://125676898615697",
	["chart-column-big"] = "rbxassetid://98598733210787",
	["chart-column-decreasing"] = "rbxassetid://73586137373563",
	["chart-column-increasing"] = "rbxassetid://120421615068601",
	["chart-column-stacked"] = "rbxassetid://86031449675105",
	["chart-column"] = "rbxassetid://97915995538580",
	["chart-gantt"] = "rbxassetid://88811660555940",
	["chart-line"] = "rbxassetid://101833156055618",
	["chart-network"] = "rbxassetid://104027882693561",
	["chart-no-axes-column-decreasing"] = "rbxassetid://123371717192542",
	["chart-no-axes-column-increasing"] = "rbxassetid://140383830943049",
	["chart-no-axes-column"] = "rbxassetid://94078751170351",
	["chart-no-axes-combined"] = "rbxassetid://121424233161912",
	["chart-no-axes-gantt"] = "rbxassetid://131936541106368",
	["chart-pie"] = "rbxassetid://113412261630136",
	["chart-scatter"] = "rbxassetid://108217585014571",
	["chart-spline"] = "rbxassetid://90307460742494",
	["check-check"] = "rbxassetid://95183312173858",
	["check-line"] = "rbxassetid://115122343485290",
	["check"] = "rbxassetid://93898873302694",
	["chef-hat"] = "rbxassetid://121744015002573",
	["cherry"] = "rbxassetid://139519182403183",
	["chess-bishop"] = "rbxassetid://121701705580238",
	["chess-king"] = "rbxassetid://90885687223462",
	["chess-knight"] = "rbxassetid://96467707042169",
	["chess-pawn"] = "rbxassetid://111318574652751",
	["chess-queen"] = "rbxassetid://98304702099749",
	["chess-rook"] = "rbxassetid://76223925830262",
	["chevron-down"] = "rbxassetid://134243273101015",
	["chevron-first"] = "rbxassetid://105243363790238",
	["chevron-last"] = "rbxassetid://89268452603731",
	["chevron-left"] = "rbxassetid://73780377692148",
	["chevron-right"] = "rbxassetid://92473583511724",
	["chevron-up"] = "rbxassetid://122444883127455",
	["chevrons-down-up"] = "rbxassetid://139404716013205",
	["chevrons-down"] = "rbxassetid://100524612205956",
	["chevrons-left-right-ellipsis"] = "rbxassetid://125035817741526",
	["chevrons-left-right"] = "rbxassetid://87910685945204",
	["chevrons-left"] = "rbxassetid://82617201744347",
	["chevrons-right-left"] = "rbxassetid://87149546686569",
	["chevrons-right"] = "rbxassetid://139121276490483",
	["chevrons-up-down"] = "rbxassetid://131833120209646",
	["chevrons-up"] = "rbxassetid://100467452364672",
	["chromium"] = "rbxassetid://128165143739006",
	["church"] = "rbxassetid://113714744350666",
	["cigarette-off"] = "rbxassetid://77797883078452",
	["circle-alert"] = "rbxassetid://83898160590116",
	["circle-arrow-down"] = "rbxassetid://95901860261344",
	["circle-arrow-left"] = "rbxassetid://102148876968988",
	["circle-arrow-out-down-left"] = "rbxassetid://140598097856694",
	["circle-arrow-out-down-right"] = "rbxassetid://119952801379305",
	["circle-arrow-out-up-left"] = "rbxassetid://132858212688303",
	["circle-arrow-out-up-right"] = "rbxassetid://81783743753173",
	["circle-arrow-right"] = "rbxassetid://70786767999559",
	["circle-arrow-up"] = "rbxassetid://84395128546494",
	["circle-check-big"] = "rbxassetid://93202927221730",
	["circle-check"] = "rbxassetid://85262178816537",
	["circle-chevron-down"] = "rbxassetid://137069490345718",
	["circle-chevron-left"] = "rbxassetid://130250009740827",
	["circle-chevron-right"] = "rbxassetid://125943696958495",
	["circle-chevron-up"] = "rbxassetid://111223574026321",
	["circle-dashed"] = "rbxassetid://126799443883746",
	["circle-divide"] = "rbxassetid://106398997754208",
	["circle-dollar-sign"] = "rbxassetid://91106238890387",
	["circle-dot-dashed"] = "rbxassetid://111451232827180",
	["circle-dot"] = "rbxassetid://82947033619201",
	["circle-ellipsis"] = "rbxassetid://91687150884779",
	["circle-equal"] = "rbxassetid://95133963751438",
	["circle-fading-arrow-up"] = "rbxassetid://104648212910336",
	["circle-fading-plus"] = "rbxassetid://91847890443490",
	["circle-gauge"] = "rbxassetid://108157549473765",
	["circle-minus"] = "rbxassetid://133556159576809",
	["circle-off"] = "rbxassetid://97923456918886",
	["circle-parking-off"] = "rbxassetid://128369410981252",
	["circle-parking"] = "rbxassetid://124034962915196",
	["circle-pause"] = "rbxassetid://139337739700879",
	["circle-percent"] = "rbxassetid://133311912860256",
	["circle-play"] = "rbxassetid://120408917249739",
	["circle-plus"] = "rbxassetid://113157136350384",
	["circle-pound-sterling"] = "rbxassetid://105476153083828",
	["circle-power"] = "rbxassetid://140676030155098",
	["circle-question-mark"] = "rbxassetid://97516698664325",
	["circle-slash-2"] = "rbxassetid://136766902186549",
	["circle-slash"] = "rbxassetid://125206439913049",
	["circle-small"] = "rbxassetid://73685402843600",
	["circle-star"] = "rbxassetid://120318414957104",
	["circle-stop"] = "rbxassetid://87400503942659",
	["circle-user-round"] = "rbxassetid://95489465399880",
	["circle-user"] = "rbxassetid://136220511671311",
	["circle-x"] = "rbxassetid://76821953846248",
	["circle"] = "rbxassetid://130359823580534",
	["circuit-board"] = "rbxassetid://107695264369312",
	["citrus"] = "rbxassetid://139018222976433",
	["clapperboard"] = "rbxassetid://132660667070200",
	["clipboard-check"] = "rbxassetid://92649798577170",
	["clipboard-clock"] = "rbxassetid://123957515687745",
	["clipboard-copy"] = "rbxassetid://125851897718493",
	["clipboard-list"] = "rbxassetid://96460215958908",
	["clipboard-minus"] = "rbxassetid://107968008485671",
	["clipboard-paste"] = "rbxassetid://74382068849983",
	["clipboard-pen-line"] = "rbxassetid://77711589791615",
	["clipboard-pen"] = "rbxassetid://75290966822953",
	["clipboard-plus"] = "rbxassetid://134285318675662",
	["clipboard-type"] = "rbxassetid://89949374318028",
	["clipboard-x"] = "rbxassetid://102222456890103",
	["clipboard"] = "rbxassetid://89601995828423",
	["clock-1"] = "rbxassetid://129363225422045",
	["clock-10"] = "rbxassetid://104332695855541",
	["clock-11"] = "rbxassetid://119023205186105",
	["clock-12"] = "rbxassetid://117789618723068",
	["clock-2"] = "rbxassetid://134710777209413",
	["clock-3"] = "rbxassetid://136385631189327",
	["clock-4"] = "rbxassetid://121808839832144",
	["clock-5"] = "rbxassetid://85082019959457",
	["clock-6"] = "rbxassetid://71009733505593",
	["clock-7"] = "rbxassetid://103111188546225",
	["clock-8"] = "rbxassetid://110059272125337",
	["clock-9"] = "rbxassetid://77610027126437",
	["clock-alert"] = "rbxassetid://97157344465162",
	["clock-arrow-down"] = "rbxassetid://92349314416042",
	["clock-arrow-up"] = "rbxassetid://111484286332629",
	["clock-check"] = "rbxassetid://85231630218857",
	["clock-fading"] = "rbxassetid://93205297285245",
	["clock-plus"] = "rbxassetid://93367709263150",
	["clock"] = "rbxassetid://121808839832144",
	["closed-caption"] = "rbxassetid://99832644030788",
	["cloud-alert"] = "rbxassetid://91967273658626",
	["cloud-check"] = "rbxassetid://97318598202432",
	["cloud-cog"] = "rbxassetid://96497764065749",
	["cloud-download"] = "rbxassetid://121435581993566",
	["cloud-drizzle"] = "rbxassetid://139525315752605",
	["cloud-fog"] = "rbxassetid://76650233148776",
	["cloud-hail"] = "rbxassetid://72320462748242",
	["cloud-lightning"] = "rbxassetid://133517088924849",
	["cloud-moon-rain"] = "rbxassetid://127667837827018",
	["cloud-moon"] = "rbxassetid://71938114737914",
	["cloud-off"] = "rbxassetid://131907154501444",
	["cloud-rain-wind"] = "rbxassetid://107414583736721",
	["cloud-rain"] = "rbxassetid://105547081967408",
	["cloud-snow"] = "rbxassetid://72307126270226",
	["cloud-sun-rain"] = "rbxassetid://99041604425705",
	["cloud-sun"] = "rbxassetid://86114208148727",
	["cloud-upload"] = "rbxassetid://93307473217005",
	["cloud"] = "rbxassetid://121226497050352",
	["cloudy"] = "rbxassetid://105360479023346",
	["clover"] = "rbxassetid://74925550436750",
	["club"] = "rbxassetid://108490365816628",
	["code-xml"] = "rbxassetid://130150477351734",
	["code"] = "rbxassetid://107380207681249",
	["codepen"] = "rbxassetid://135643965971885",
	["codesandbox"] = "rbxassetid://106911852964823",
	["coffee"] = "rbxassetid://106864403231093",
	["cog"] = "rbxassetid://116544501716299",
	["coins"] = "rbxassetid://116510979641930",
	["columns-2"] = "rbxassetid://113004100221850",
	["columns-3-cog"] = "rbxassetid://121589691981064",
	["columns-3"] = "rbxassetid://115223357399375",
	["columns-4"] = "rbxassetid://130807991968419",
	["combine"] = "rbxassetid://79908476334048",
	["command"] = "rbxassetid://93648221906330",
	["compass"] = "rbxassetid://115123411028382",
	["component"] = "rbxassetid://110027788875080",
	["computer"] = "rbxassetid://77480056459407",
	["concierge-bell"] = "rbxassetid://140384259310436",
	["cone"] = "rbxassetid://97759550688437",
	["construction"] = "rbxassetid://106539489968173",
	["contact-round"] = "rbxassetid://71907624112229",
	["contact"] = "rbxassetid://75868297719012",
	["container"] = "rbxassetid://91507237573499",
	["contrast"] = "rbxassetid://112796643981497",
	["cookie"] = "rbxassetid://73159504540002",
	["cooking-pot"] = "rbxassetid://94959783129799",
	["copy-check"] = "rbxassetid://91177247988892",
	["copy-minus"] = "rbxassetid://109524509933035",
	["copy-plus"] = "rbxassetid://113618379616952",
	["copy-slash"] = "rbxassetid://93805787810390",
	["copy-x"] = "rbxassetid://106557557978061",
	["copy"] = "rbxassetid://78979572434545",
	["copyleft"] = "rbxassetid://78559055698593",
	["copyright"] = "rbxassetid://129433635747111",
	["corner-down-left"] = "rbxassetid://90473561177832",
	["corner-down-right"] = "rbxassetid://86512767702085",
	["corner-left-down"] = "rbxassetid://139876989150630",
	["corner-left-up"] = "rbxassetid://126228268096099",
	["corner-right-down"] = "rbxassetid://89237035551302",
	["corner-right-up"] = "rbxassetid://112851237026705",
	["corner-up-left"] = "rbxassetid://84669279763024",
	["corner-up-right"] = "rbxassetid://115099889693145",
	["cpu"] = "rbxassetid://77549309870247",
	["creative-commons"] = "rbxassetid://90408210735312",
	["credit-card"] = "rbxassetid://99163352872346",
	["croissant"] = "rbxassetid://130710485559420",
	["crop"] = "rbxassetid://116344601101413",
	["cross"] = "rbxassetid://101833377863588",
	["crosshair"] = "rbxassetid://134242818164054",
	["crown"] = "rbxassetid://127843403295538",
	["cuboid"] = "rbxassetid://75618807946111",
	["cup-soda"] = "rbxassetid://121098640829562",
	["currency"] = "rbxassetid://90551250119972",
	["cylinder"] = "rbxassetid://90569677179169",
	["dam"] = "rbxassetid://76874486231393",
	["database-backup"] = "rbxassetid://103403210984699",
	["database-zap"] = "rbxassetid://131199921258418",
	["database"] = "rbxassetid://126791525623846",
	["decimals-arrow-left"] = "rbxassetid://120198500638749",
	["decimals-arrow-right"] = "rbxassetid://118263047146797",
	["delete"] = "rbxassetid://126279426372342",
	["dessert"] = "rbxassetid://71508133278830",
	["diameter"] = "rbxassetid://97429051503783",
	["diamond-minus"] = "rbxassetid://128989071438290",
	["diamond-percent"] = "rbxassetid://107717860105959",
	["diamond-plus"] = "rbxassetid://134701163723675",
	["diamond"] = "rbxassetid://105846996304890",
	["dice-1"] = "rbxassetid://112650149591038",
	["dice-2"] = "rbxassetid://112278274566793",
	["dice-3"] = "rbxassetid://118526270626312",
	["dice-4"] = "rbxassetid://113365650364004",
	["dice-5"] = "rbxassetid://72768312430593",
	["dice-6"] = "rbxassetid://85376239182543",
	["dices"] = "rbxassetid://81268120302865",
	["diff"] = "rbxassetid://135052708609715",
	["disc-2"] = "rbxassetid://91419420404185",
	["disc-3"] = "rbxassetid://135470554736048",
	["disc-album"] = "rbxassetid://74693460404344",
	["disc"] = "rbxassetid://101908120120777",
	["divide"] = "rbxassetid://136678191878278",
	["dna-off"] = "rbxassetid://89612426361540",
	["dna"] = "rbxassetid://74007982981741",
	["dock"] = "rbxassetid://121997427160252",
	["dog"] = "rbxassetid://71920105558570",
	["dollar-sign"] = "rbxassetid://127320961224019",
	["donut"] = "rbxassetid://72204922742657",
	["door-closed-locked"] = "rbxassetid://74027613267551",
	["door-closed"] = "rbxassetid://136249099949073",
	["door-open"] = "rbxassetid://91306356501736",
	["dot"] = "rbxassetid://137321056643916",
	["download"] = "rbxassetid://134814648082393",
	["drafting-compass"] = "rbxassetid://99701976182841",
	["drama"] = "rbxassetid://110297795801577",
	["dribbble"] = "rbxassetid://80231809663849",
	["drill"] = "rbxassetid://108644821412796",
	["drone"] = "rbxassetid://117299095794783",
	["droplet-off"] = "rbxassetid://119365002225172",
	["droplet"] = "rbxassetid://100597455015098",
	["droplets"] = "rbxassetid://140111846025180",
	["drum"] = "rbxassetid://136979060344890",
	["drumstick"] = "rbxassetid://104662462521709",
	["dumbbell"] = "rbxassetid://80277236776212",
	["ear-off"] = "rbxassetid://87421916192807",
	["ear"] = "rbxassetid://121894949934209",
	["earth-lock"] = "rbxassetid://88814147073745",
	["earth"] = "rbxassetid://76231597751076",
	["eclipse"] = "rbxassetid://114829622118222",
	["egg-fried"] = "rbxassetid://90622538210545",
	["egg-off"] = "rbxassetid://92288321309285",
	["egg"] = "rbxassetid://117851493400222",
	["ellipsis-vertical"] = "rbxassetid://117978708573781",
	["ellipsis"] = "rbxassetid://140019550645825",
	["equal-approximately"] = "rbxassetid://105382689698323",
	["equal-not"] = "rbxassetid://76864449458032",
	["equal"] = "rbxassetid://123467780715624",
	["eraser"] = "rbxassetid://133957773112410",
	["ethernet-port"] = "rbxassetid://75391715149314",
	["euro"] = "rbxassetid://72229646524456",
	["ev-charger"] = "rbxassetid://97906158859623",
	["expand"] = "rbxassetid://137492887754537",
	["external-link"] = "rbxassetid://129331830773832",
	["eye-closed"] = "rbxassetid://111063268625789",
	["eye-off"] = "rbxassetid://135928786788378",
	["eye"] = "rbxassetid://100033680381365",
	["facebook"] = "rbxassetid://72098528632192",
	["factory"] = "rbxassetid://102170024318039",
	["fan"] = "rbxassetid://78391400440696",
	["fast-forward"] = "rbxassetid://121615540167909",
	["feather"] = "rbxassetid://91872927606406",
	["fence"] = "rbxassetid://123451565578029",
	["ferris-wheel"] = "rbxassetid://79729205796176",
	["figma"] = "rbxassetid://134182122852301",
	["file-archive"] = "rbxassetid://77018106869967",
	["file-axis-3d"] = "rbxassetid://133912328009885",
	["file-badge"] = "rbxassetid://74564895394477",
	["file-box"] = "rbxassetid://119264004071690",
	["file-braces-corner"] = "rbxassetid://77253337986109",
	["file-braces"] = "rbxassetid://95314128621234",
	["file-chart-column-increasing"] = "rbxassetid://134449481172067",
	["file-chart-column"] = "rbxassetid://82048481252560",
	["file-chart-line"] = "rbxassetid://71954360551345",
	["file-chart-pie"] = "rbxassetid://81072193564497",
	["file-check-corner"] = "rbxassetid://76295552859171",
	["file-check"] = "rbxassetid://82604001452455",
	["file-clock"] = "rbxassetid://102325208830990",
	["file-code-corner"] = "rbxassetid://78293841184371",
	["file-code"] = "rbxassetid://130978036895504",
	["file-cog"] = "rbxassetid://101385347151368",
	["file-diff"] = "rbxassetid://96147216772241",
	["file-digit"] = "rbxassetid://89220220354580",
	["file-down"] = "rbxassetid://120650154178290",
	["file-exclamation-point"] = "rbxassetid://102821865889635",
	["file-headphone"] = "rbxassetid://100533735901986",
	["file-heart"] = "rbxassetid://132214916401696",
	["file-image"] = "rbxassetid://123334057511782",
	["file-input"] = "rbxassetid://124728604166044",
	["file-key"] = "rbxassetid://118790255921100",
	["file-lock"] = "rbxassetid://72170228691242",
	["file-minus-corner"] = "rbxassetid://119263271735124",
	["file-minus"] = "rbxassetid://111014798459222",
	["file-music"] = "rbxassetid://134948051536671",
	["file-output"] = "rbxassetid://92146832572911",
	["file-pen-line"] = "rbxassetid://104622936345006",
	["file-pen"] = "rbxassetid://79556179730240",
	["file-play"] = "rbxassetid://89006821567838",
	["file-plus-corner"] = "rbxassetid://76544604043974",
	["file-plus"] = "rbxassetid://78881710800060",
	["file-question-mark"] = "rbxassetid://127617422859576",
	["file-scan"] = "rbxassetid://129480105228213",
	["file-search-corner"] = "rbxassetid://90974165234008",
	["file-search"] = "rbxassetid://97780235974933",
	["file-signal"] = "rbxassetid://122070252538165",
	["file-sliders"] = "rbxassetid://85787771732439",
	["file-spreadsheet"] = "rbxassetid://134501869359270",
	["file-stack"] = "rbxassetid://138929929862605",
	["file-symlink"] = "rbxassetid://91865722036510",
	["file-terminal"] = "rbxassetid://116757454755476",
	["file-text"] = "rbxassetid://90496405707281",
	["file-type-corner"] = "rbxassetid://124902230275209",
	["file-type"] = "rbxassetid://115272552799361",
	["file-up"] = "rbxassetid://131173039312748",
	["file-user"] = "rbxassetid://99552018455009",
	["file-video-camera"] = "rbxassetid://81719056173960",
	["file-volume"] = "rbxassetid://111264764438958",
	["file-x-corner"] = "rbxassetid://87554136773609",
	["file-x"] = "rbxassetid://107333775515154",
	["file"] = "rbxassetid://74748492079329",
	["files"] = "rbxassetid://102806336233202",
	["film"] = "rbxassetid://120978945609706",
	["fingerprint"] = "rbxassetid://112173305232811",
	["fire-extinguisher"] = "rbxassetid://111643493006960",
	["fish-off"] = "rbxassetid://89756724887508",
	["fish-symbol"] = "rbxassetid://118475177681618",
	["fish"] = "rbxassetid://124360663785796",
	["flag-off"] = "rbxassetid://112944528856799",
	["flag-triangle-left"] = "rbxassetid://88045221285272",
	["flag-triangle-right"] = "rbxassetid://108292480304566",
	["flag"] = "rbxassetid://78183383236196",
	["flame-kindling"] = "rbxassetid://139728976917928",
	["flame"] = "rbxassetid://98218034436456",
	["flashlight-off"] = "rbxassetid://79780362871740",
	["flashlight"] = "rbxassetid://100286985600444",
	["flask-conical-off"] = "rbxassetid://112597970025298",
	["flask-conical"] = "rbxassetid://128406680901165",
	["flask-round"] = "rbxassetid://127508287324940",
	["flip-horizontal-2"] = "rbxassetid://103726993598186",
	["flip-horizontal"] = "rbxassetid://122937530107837",
	["flip-vertical-2"] = "rbxassetid://103836358956328",
	["flip-vertical"] = "rbxassetid://108003917346888",
	["flower-2"] = "rbxassetid://72934574245145",
	["flower"] = "rbxassetid://86129438272762",
	["focus"] = "rbxassetid://87493973153317",
	["fold-horizontal"] = "rbxassetid://92835712442240",
	["fold-vertical"] = "rbxassetid://108873727253656",
	["folder-archive"] = "rbxassetid://97312009460206",
	["folder-check"] = "rbxassetid://128492920904557",
	["folder-clock"] = "rbxassetid://111964836738545",
	["folder-closed"] = "rbxassetid://118286209350843",
	["folder-code"] = "rbxassetid://70624096349370",
	["folder-cog"] = "rbxassetid://85299519462846",
	["folder-dot"] = "rbxassetid://138687772725278",
	["folder-down"] = "rbxassetid://118044108459225",
	["folder-git-2"] = "rbxassetid://101394054141166",
	["folder-git"] = "rbxassetid://121885778095158",
	["folder-heart"] = "rbxassetid://79104747211105",
	["folder-input"] = "rbxassetid://90699920697871",
	["folder-kanban"] = "rbxassetid://78313285104072",
	["folder-key"] = "rbxassetid://85270407596791",
	["folder-lock"] = "rbxassetid://119201572260567",
	["folder-minus"] = "rbxassetid://85648718999010",
	["folder-open-dot"] = "rbxassetid://74741494767354",
	["folder-open"] = "rbxassetid://76018996254888",
	["folder-output"] = "rbxassetid://101532447937612",
	["folder-pen"] = "rbxassetid://112770491173911",
	["folder-plus"] = "rbxassetid://91865663406119",
	["folder-root"] = "rbxassetid://103333751154693",
	["folder-search-2"] = "rbxassetid://71276453442655",
	["folder-search"] = "rbxassetid://110568075123861",
	["folder-symlink"] = "rbxassetid://127485747227189",
	["folder-sync"] = "rbxassetid://91544602659796",
	["folder-tree"] = "rbxassetid://85577554337861",
	["folder-up"] = "rbxassetid://72008269765857",
	["folder-x"] = "rbxassetid://91699618247635",
	["folder"] = "rbxassetid://80846616596607",
	["folders"] = "rbxassetid://110351216219061",
	["footprints"] = "rbxassetid://139192589041315",
	["forklift"] = "rbxassetid://72030930983101",
	["forward"] = "rbxassetid://97545944739523",
	["frame"] = "rbxassetid://109080612832751",
	["framer"] = "rbxassetid://108384807262391",
	["frown"] = "rbxassetid://124407301067982",
	["fuel"] = "rbxassetid://106447647274511",
	["fullscreen"] = "rbxassetid://77793665526178",
	["funnel-plus"] = "rbxassetid://100780233821928",
	["funnel-x"] = "rbxassetid://70984385812555",
	["funnel"] = "rbxassetid://108829540827529",
	["gallery-horizontal-end"] = "rbxassetid://74672430161161",
	["gallery-horizontal"] = "rbxassetid://80004001442122",
	["gallery-thumbnails"] = "rbxassetid://136219289862706",
	["gallery-vertical-end"] = "rbxassetid://106461402088317",
	["gallery-vertical"] = "rbxassetid://119299431466725",
	["gamepad-2"] = "rbxassetid://92483947987410",
	["gamepad-directional"] = "rbxassetid://84342305212226",
	["gamepad"] = "rbxassetid://121607283959010",
	["gauge"] = "rbxassetid://110273524101447",
	["gavel"] = "rbxassetid://78952298198456",
	["gem"] = "rbxassetid://112904952151156",
	["georgian-lari"] = "rbxassetid://98084432591687",
	["ghost"] = "rbxassetid://113822048130017",
	["gift"] = "rbxassetid://109855212076373",
	["git-branch-minus"] = "rbxassetid://97385010649411",
	["git-branch-plus"] = "rbxassetid://125944221134316",
	["git-branch"] = "rbxassetid://90490195516649",
	["git-commit-horizontal"] = "rbxassetid://133646041800147",
	["git-commit-vertical"] = "rbxassetid://122098032990350",
	["git-compare-arrows"] = "rbxassetid://84874426520216",
	["git-compare"] = "rbxassetid://91945124438792",
	["git-fork"] = "rbxassetid://89954992404765",
	["git-graph"] = "rbxassetid://86166832019304",
	["git-merge"] = "rbxassetid://131833355158059",
	["git-pull-request-arrow"] = "rbxassetid://94507974577439",
	["git-pull-request-closed"] = "rbxassetid://78070600389091",
	["git-pull-request-create-arrow"] = "rbxassetid://127422677061091",
	["git-pull-request-create"] = "rbxassetid://105929577383926",
	["git-pull-request-draft"] = "rbxassetid://76173459869943",
	["git-pull-request"] = "rbxassetid://138463010991471",
	["github"] = "rbxassetid://120349554354380",
	["gitlab"] = "rbxassetid://114054627192933",
	["glass-water"] = "rbxassetid://115526102400988",
	["glasses"] = "rbxassetid://87936407455373",
	["globe-lock"] = "rbxassetid://134065526704402",
	["globe"] = "rbxassetid://114238209622913",
	["goal"] = "rbxassetid://120517954878160",
	["gpu"] = "rbxassetid://95577823614219",
	["graduation-cap"] = "rbxassetid://93771896340220",
	["grape"] = "rbxassetid://134760640415561",
	["grid-2x2-check"] = "rbxassetid://138468840220821",
	["grid-2x2-plus"] = "rbxassetid://91811610580247",
	["grid-2x2-x"] = "rbxassetid://72407303981388",
	["grid-2x2"] = "rbxassetid://99050491897640",
	["grid-3x2"] = "rbxassetid://95528684210010",
	["grid-3x3"] = "rbxassetid://70419024781206",
	["grip-horizontal"] = "rbxassetid://136255899715930",
	["grip-vertical"] = "rbxassetid://137183678565296",
	["grip"] = "rbxassetid://109058783556768",
	["group"] = "rbxassetid://107643418926671",
	["guitar"] = "rbxassetid://75915531867926",
	["ham"] = "rbxassetid://74465607934635",
	["hamburger"] = "rbxassetid://93086916815495",
	["hammer"] = "rbxassetid://83545120140895",
	["hand-coins"] = "rbxassetid://126990543175462",
	["hand-fist"] = "rbxassetid://83341608917591",
	["hand-grab"] = "rbxassetid://88867162163985",
	["hand-heart"] = "rbxassetid://117507367668412",
	["hand-helping"] = "rbxassetid://89897738419446",
	["hand-metal"] = "rbxassetid://113619498548713",
	["hand-platter"] = "rbxassetid://88594727743168",
	["hand"] = "rbxassetid://130703864968637",
	["handbag"] = "rbxassetid://135675846264061",
	["handshake"] = "rbxassetid://78442115255814",
	["hard-drive-download"] = "rbxassetid://73913801230614",
	["hard-drive-upload"] = "rbxassetid://85762133615118",
	["hard-drive"] = "rbxassetid://88183305858463",
	["hard-hat"] = "rbxassetid://128050846767382",
	["hash"] = "rbxassetid://82890331678520",
	["hat-glasses"] = "rbxassetid://101165538224815",
	["haze"] = "rbxassetid://108857561768901",
	["hdmi-port"] = "rbxassetid://103693661037020",
	["heading-1"] = "rbxassetid://118129315662110",
	["heading-2"] = "rbxassetid://110209069670094",
	["heading-3"] = "rbxassetid://90267885237062",
	["heading-4"] = "rbxassetid://129625620307602",
	["heading-5"] = "rbxassetid://120386663181267",
	["heading-6"] = "rbxassetid://90959079775093",
	["heading"] = "rbxassetid://129254312067735",
	["headphone-off"] = "rbxassetid://85038251615641",
	["headphones"] = "rbxassetid://118833729589183",
	["headset"] = "rbxassetid://129269236787694",
	["heart-crack"] = "rbxassetid://110987638564119",
	["heart-handshake"] = "rbxassetid://111483078692002",
	["heart-minus"] = "rbxassetid://96827380163326",
	["heart-off"] = "rbxassetid://89748414415617",
	["heart-plus"] = "rbxassetid://94877796283249",
	["heart-pulse"] = "rbxassetid://129352925579546",
	["heart"] = "rbxassetid://116559368303288",
	["heater"] = "rbxassetid://140478466880916",
	["helicopter"] = "rbxassetid://111557171735930",
	["hexagon"] = "rbxassetid://127592089339199",
	["highlighter"] = "rbxassetid://77411555641113",
	["history"] = "rbxassetid://123980022019922",
	["hop-off"] = "rbxassetid://103386036934034",
	["hop"] = "rbxassetid://82778923997672",
	["hospital"] = "rbxassetid://105868763850707",
	["hotel"] = "rbxassetid://132283390859718",
	["hourglass"] = "rbxassetid://86160434939203",
	["house-heart"] = "rbxassetid://136054771868597",
	["house-plug"] = "rbxassetid://71438263712075",
	["house-plus"] = "rbxassetid://118495165208309",
	["house-wifi"] = "rbxassetid://126495519725698",
	["house"] = "rbxassetid://98755624629571",
	["ice-cream-bowl"] = "rbxassetid://124867218454386",
	["ice-cream-cone"] = "rbxassetid://90751397288639",
	["id-card-lanyard"] = "rbxassetid://90761480469224",
	["id-card"] = "rbxassetid://75354294622640",
	["image-down"] = "rbxassetid://78972295741235",
	["image-minus"] = "rbxassetid://101066016918565",
	["image-off"] = "rbxassetid://81934811700938",
	["image-play"] = "rbxassetid://129501806784210",
	["image-plus"] = "rbxassetid://70391970623917",
	["image-up"] = "rbxassetid://126610009605241",
	["image-upscale"] = "rbxassetid://106963545024679",
	["images"] = "rbxassetid://79350649395557",
	["import"] = "rbxassetid://116545008906029",
	["inbox"] = "rbxassetid://112591360302868",
	["indian-rupee"] = "rbxassetid://113038778381805",
	["infinity"] = "rbxassetid://98083086936965",
	["info"] = "rbxassetid://124560466474914",
	["inspection-panel"] = "rbxassetid://70905313146088",
	["instagram"] = "rbxassetid://119864798614855",
	["italic"] = "rbxassetid://96220378864282",
	["iteration-ccw"] = "rbxassetid://140221832794083",
	["iteration-cw"] = "rbxassetid://95534489554662",
	["japanese-yen"] = "rbxassetid://106362863465813",
	["joystick"] = "rbxassetid://99416790224739",
	["kanban"] = "rbxassetid://125934100055431",
	["kayak"] = "rbxassetid://136107544609389",
	["key-round"] = "rbxassetid://83619031955390",
	["key-square"] = "rbxassetid://94621420033649",
	["key"] = "rbxassetid://96510194465420",
	["keyboard-music"] = "rbxassetid://121058541758636",
	["keyboard-off"] = "rbxassetid://92466375369772",
	["keyboard"] = "rbxassetid://121474456068237",
	["lamp-ceiling"] = "rbxassetid://80032758469141",
	["lamp-desk"] = "rbxassetid://85290686983238",
	["lamp-floor"] = "rbxassetid://104585881375892",
	["lamp-wall-down"] = "rbxassetid://91271394132073",
	["lamp-wall-up"] = "rbxassetid://132141464337445",
	["lamp"] = "rbxassetid://110730830653382",
	["land-plot"] = "rbxassetid://96449039620294",
	["landmark"] = "rbxassetid://76885079756393",
	["languages"] = "rbxassetid://90816903776498",
	["laptop-minimal-check"] = "rbxassetid://114352019833865",
	["laptop-minimal"] = "rbxassetid://136705765566068",
	["laptop"] = "rbxassetid://111387063244975",
	["lasso-select"] = "rbxassetid://105609719912753",
	["lasso"] = "rbxassetid://121072936884007",
	["laugh"] = "rbxassetid://104491311361166",
	["layers-2"] = "rbxassetid://70536710516357",
	["layers"] = "rbxassetid://81973586053257",
	["layout-dashboard"] = "rbxassetid://139929981863901",
	["layout-grid"] = "rbxassetid://81344910161871",
	["layout-list"] = "rbxassetid://87462136296578",
	["layout-panel-left"] = "rbxassetid://125092469751491",
	["layout-panel-top"] = "rbxassetid://91943941515944",
	["layout-template"] = "rbxassetid://115564446417985",
	["leaf"] = "rbxassetid://119951075637174",
	["leafy-green"] = "rbxassetid://105146290493154",
	["lectern"] = "rbxassetid://106166425183862",
	["library-big"] = "rbxassetid://106794530191412",
	["library"] = "rbxassetid://114334671982047",
	["life-buoy"] = "rbxassetid://81168450671956",
	["ligature"] = "rbxassetid://111397873269411",
	["lightbulb-off"] = "rbxassetid://83795722296178",
	["lightbulb"] = "rbxassetid://103871245626488",
	["line-squiggle"] = "rbxassetid://109555164424447",
	["link-2-off"] = "rbxassetid://76885956296867",
	["link-2"] = "rbxassetid://86072351557466",
	["link"] = "rbxassetid://131607023382430",
	["linkedin"] = "rbxassetid://132842789255788",
	["list-check"] = "rbxassetid://72374358471156",
	["list-checks"] = "rbxassetid://99809353635593",
	["list-chevrons-down-up"] = "rbxassetid://137409641500711",
	["list-chevrons-up-down"] = "rbxassetid://81825351389084",
	["list-collapse"] = "rbxassetid://124505247702401",
	["list-end"] = "rbxassetid://77650610048119",
	["list-filter-plus"] = "rbxassetid://96385120752336",
	["list-filter"] = "rbxassetid://103321376129527",
	["list-indent-decrease"] = "rbxassetid://137879979228193",
	["list-indent-increase"] = "rbxassetid://79051053161201",
	["list-minus"] = "rbxassetid://138507965142671",
	["list-music"] = "rbxassetid://126380635781840",
	["list-ordered"] = "rbxassetid://83212528113913",
	["list-plus"] = "rbxassetid://112384738137814",
	["list-restart"] = "rbxassetid://91703153577421",
	["list-start"] = "rbxassetid://84828348299727",
	["list-todo"] = "rbxassetid://132980603752108",
	["list-tree"] = "rbxassetid://97685396239010",
	["list-video"] = "rbxassetid://93648525452489",
	["list-x"] = "rbxassetid://113025303988861",
	["list"] = "rbxassetid://113179976918783",
	["loader-circle"] = "rbxassetid://116535712789945",
	["loader-pinwheel"] = "rbxassetid://108513357940900",
	["loader"] = "rbxassetid://78408734580845",
	["locate-fixed"] = "rbxassetid://137367361548433",
	["locate-off"] = "rbxassetid://73729216338137",
	["locate"] = "rbxassetid://84467676590391",
	["lock-keyhole-open"] = "rbxassetid://110863509313073",
	["lock-keyhole"] = "rbxassetid://78672912777756",
	["lock-open"] = "rbxassetid://93597915325122",
	["lock"] = "rbxassetid://134724289526879",
	["log-in"] = "rbxassetid://103768533135201",
	["log-out"] = "rbxassetid://84895399304975",
	["logs"] = "rbxassetid://89772091251787",
	["lollipop"] = "rbxassetid://84681611583044",
	["luggage"] = "rbxassetid://76619236486400",
	["magnet"] = "rbxassetid://135162361226972",
	["mail-check"] = "rbxassetid://86921536259917",
	["mail-minus"] = "rbxassetid://81989813236553",
	["mail-open"] = "rbxassetid://122785416858638",
	["mail-plus"] = "rbxassetid://104886401588341",
	["mail-question-mark"] = "rbxassetid://126540170949819",
	["mail-search"] = "rbxassetid://135616173775287",
	["mail-warning"] = "rbxassetid://81495303676089",
	["mail-x"] = "rbxassetid://74607841705644",
	["mail"] = "rbxassetid://103945161245599",
	["mailbox"] = "rbxassetid://82765503320335",
	["mails"] = "rbxassetid://90673453450080",
	["map-minus"] = "rbxassetid://129525760577747",
	["map-pin-check-inside"] = "rbxassetid://107130529843809",
	["map-pin-check"] = "rbxassetid://118110914690154",
	["map-pin-house"] = "rbxassetid://80546885029816",
	["map-pin-minus-inside"] = "rbxassetid://79005529692964",
	["map-pin-minus"] = "rbxassetid://74518762643623",
	["map-pin-off"] = "rbxassetid://82474689391020",
	["map-pin-pen"] = "rbxassetid://113515395277504",
	["map-pin-plus-inside"] = "rbxassetid://134639656514430",
	["map-pin-plus"] = "rbxassetid://91875228967029",
	["map-pin-x-inside"] = "rbxassetid://126235934252379",
	["map-pin-x"] = "rbxassetid://101085273547316",
	["map-pin"] = "rbxassetid://84279202219901",
	["map-pinned"] = "rbxassetid://103963788475034",
	["map-plus"] = "rbxassetid://129388826743495",
	["map"] = "rbxassetid://95107167260947",
	["mars-stroke"] = "rbxassetid://131973193186828",
	["mars"] = "rbxassetid://111287112372511",
	["martini"] = "rbxassetid://82977695401058",
	["maximize-2"] = "rbxassetid://73085922906397",
	["maximize"] = "rbxassetid://76045941763188",
	["medal"] = "rbxassetid://79016002264450",
	["megaphone-off"] = "rbxassetid://124280774193935",
	["megaphone"] = "rbxassetid://118759541854879",
	["meh"] = "rbxassetid://132197867028557",
	["memory-stick"] = "rbxassetid://93212591343119",
	["menu"] = "rbxassetid://77021539815611",
	["merge"] = "rbxassetid://126201866476775",
	["message-circle-code"] = "rbxassetid://112865244991651",
	["message-circle-dashed"] = "rbxassetid://81525157881897",
	["message-circle-heart"] = "rbxassetid://101990756073677",
	["message-circle-more"] = "rbxassetid://92856823884663",
	["message-circle-off"] = "rbxassetid://134955643890328",
	["message-circle-plus"] = "rbxassetid://106562979649273",
	["message-circle-question-mark"] = "rbxassetid://107700302759934",
	["message-circle-reply"] = "rbxassetid://137071749508334",
	["message-circle-warning"] = "rbxassetid://119020096067894",
	["message-circle-x"] = "rbxassetid://126843387725536",
	["message-circle"] = "rbxassetid://127255077587058",
	["message-square-code"] = "rbxassetid://110968863152123",
	["message-square-dashed"] = "rbxassetid://107653455516238",
	["message-square-diff"] = "rbxassetid://75472190472625",
	["message-square-dot"] = "rbxassetid://127806382463916",
	["message-square-heart"] = "rbxassetid://75612811742074",
	["message-square-lock"] = "rbxassetid://81268215619563",
	["message-square-more"] = "rbxassetid://120139782405970",
	["message-square-off"] = "rbxassetid://99961019005789",
	["message-square-plus"] = "rbxassetid://76934450256199",
	["message-square-quote"] = "rbxassetid://116670768629340",
	["message-square-reply"] = "rbxassetid://130985622754637",
	["message-square-share"] = "rbxassetid://131017005324026",
	["message-square-text"] = "rbxassetid://94899503194205",
	["message-square-warning"] = "rbxassetid://138432903962261",
	["message-square-x"] = "rbxassetid://137285463279462",
	["message-square"] = "rbxassetid://83881670383280",
	["messages-square"] = "rbxassetid://97532166733358",
	["mic-off"] = "rbxassetid://82123034444822",
	["mic-vocal"] = "rbxassetid://99082286164362",
	["mic"] = "rbxassetid://89640799126523",
	["microchip"] = "rbxassetid://73937907669903",
	["microscope"] = "rbxassetid://116875530102782",
	["microwave"] = "rbxassetid://108411735353008",
	["milestone"] = "rbxassetid://101618292325920",
	["milk-off"] = "rbxassetid://72388480962742",
	["milk"] = "rbxassetid://96221903896918",
	["minimize-2"] = "rbxassetid://116269596042539",
	["minimize"] = "rbxassetid://121304296213645",
	["minus"] = "rbxassetid://118026365011536",
	["monitor-check"] = "rbxassetid://86651948439229",
	["monitor-cloud"] = "rbxassetid://85931096038318",
	["monitor-cog"] = "rbxassetid://94345128715799",
	["monitor-dot"] = "rbxassetid://130394010063680",
	["monitor-down"] = "rbxassetid://97466933743423",
	["monitor-off"] = "rbxassetid://74395526657953",
	["monitor-pause"] = "rbxassetid://76002184067562",
	["monitor-play"] = "rbxassetid://133018824306217",
	["monitor-smartphone"] = "rbxassetid://84335680433378",
	["monitor-speaker"] = "rbxassetid://81744810060380",
	["monitor-stop"] = "rbxassetid://98708958984757",
	["monitor-up"] = "rbxassetid://96035360858377",
	["monitor-x"] = "rbxassetid://126265210441423",
	["monitor"] = "rbxassetid://72664649203050",
	["moon-star"] = "rbxassetid://82782200506348",
	["moon"] = "rbxassetid://83380517901735",
	["motorbike"] = "rbxassetid://94580787368233",
	["mountain-snow"] = "rbxassetid://105315495740588",
	["mountain"] = "rbxassetid://73269957566415",
	["mouse-off"] = "rbxassetid://75267871697595",
	["mouse-pointer-2-off"] = "rbxassetid://104701076865632",
	["mouse-pointer-2"] = "rbxassetid://117093892862228",
	["mouse-pointer-ban"] = "rbxassetid://106849413057133",
	["mouse-pointer-click"] = "rbxassetid://107150227368485",
	["mouse-pointer"] = "rbxassetid://72322454962935",
	["mouse"] = "rbxassetid://73096068864710",
	["move-3d"] = "rbxassetid://103365982054003",
	["move-diagonal-2"] = "rbxassetid://117298577948096",
	["move-diagonal"] = "rbxassetid://101433481954184",
	["move-down-left"] = "rbxassetid://102819433534567",
	["move-down-right"] = "rbxassetid://101479760041877",
	["move-down"] = "rbxassetid://70510115135583",
	["move-horizontal"] = "rbxassetid://88513523439149",
	["move-left"] = "rbxassetid://137614740247980",
	["move-right"] = "rbxassetid://132455779472989",
	["move-up-left"] = "rbxassetid://139079815540148",
	["move-up-right"] = "rbxassetid://105885140592646",
	["move-up"] = "rbxassetid://84505444262658",
	["move-vertical"] = "rbxassetid://86234730730899",
	["move"] = "rbxassetid://116138709011735",
	["music-2"] = "rbxassetid://134397426600888",
	["music-3"] = "rbxassetid://94466120066498",
	["music-4"] = "rbxassetid://132459323665838",
	["music"] = "rbxassetid://113343203848535",
	["navigation-2-off"] = "rbxassetid://116569611780763",
	["navigation-2"] = "rbxassetid://81889066747907",
	["navigation-off"] = "rbxassetid://87003270290777",
	["navigation"] = "rbxassetid://79308213542922",
	["network"] = "rbxassetid://127410729922644",
	["newspaper"] = "rbxassetid://123479530460544",
	["nfc"] = "rbxassetid://76822396542242",
	["non-binary"] = "rbxassetid://78442360386235",
	["notebook-pen"] = "rbxassetid://140380614761023",
	["notebook-tabs"] = "rbxassetid://127371085570083",
	["notebook-text"] = "rbxassetid://93061585217270",
	["notebook"] = "rbxassetid://136132108664987",
	["notepad-text-dashed"] = "rbxassetid://135793446376219",
	["notepad-text"] = "rbxassetid://93404682958966",
	["nut-off"] = "rbxassetid://78795397311573",
	["nut"] = "rbxassetid://127146410705656",
	["octagon-alert"] = "rbxassetid://140438367956051",
	["octagon-minus"] = "rbxassetid://74720436795421",
	["octagon-pause"] = "rbxassetid://103161463909039",
	["octagon-x"] = "rbxassetid://90498161006311",
	["octagon"] = "rbxassetid://120803515514852",
	["omega"] = "rbxassetid://70414080018786",
	["option"] = "rbxassetid://100776883894054",
	["orbit"] = "rbxassetid://108926136860562",
	["origami"] = "rbxassetid://136020626667101",
	["package-2"] = "rbxassetid://70394974762575",
	["package-check"] = "rbxassetid://102374216055130",
	["package-minus"] = "rbxassetid://114492858789692",
	["package-open"] = "rbxassetid://132890233237818",
	["package-plus"] = "rbxassetid://129261988138366",
	["package-search"] = "rbxassetid://95465120894145",
	["package-x"] = "rbxassetid://70818501607442",
	["package"] = "rbxassetid://97261141732706",
	["paint-bucket"] = "rbxassetid://124275586663284",
	["paint-roller"] = "rbxassetid://115248074358348",
	["paintbrush-vertical"] = "rbxassetid://105151296591292",
	["paintbrush"] = "rbxassetid://125572663700289",
	["palette"] = "rbxassetid://86350350950064",
	["panda"] = "rbxassetid://132509022802512",
	["panel-bottom-close"] = "rbxassetid://74287004071159",
	["panel-bottom-dashed"] = "rbxassetid://131084651621603",
	["panel-bottom-open"] = "rbxassetid://107768659586540",
	["panel-bottom"] = "rbxassetid://132127145048511",
	["panel-left-close"] = "rbxassetid://126579818823552",
	["panel-left-dashed"] = "rbxassetid://75536606374585",
	["panel-left-open"] = "rbxassetid://111075816195767",
	["panel-left-right-dashed"] = "rbxassetid://110100707973959",
	["panel-left"] = "rbxassetid://97419752870313",
	["panel-right-close"] = "rbxassetid://139528655524132",
	["panel-right-dashed"] = "rbxassetid://94959793877311",
	["panel-right-open"] = "rbxassetid://118114419142794",
	["panel-right"] = "rbxassetid://116365035443156",
	["panel-top-bottom-dashed"] = "rbxassetid://134737235653344",
	["panel-top-close"] = "rbxassetid://83578325777808",
	["panel-top-dashed"] = "rbxassetid://70522913169237",
	["panel-top-open"] = "rbxassetid://137959875507454",
	["panel-top"] = "rbxassetid://75838479462875",
	["panels-left-bottom"] = "rbxassetid://72996856149149",
	["panels-right-bottom"] = "rbxassetid://90659068960726",
	["panels-top-left"] = "rbxassetid://79858853850600",
	["paperclip"] = "rbxassetid://92088291163453",
	["parentheses"] = "rbxassetid://78950955173096",
	["parking-meter"] = "rbxassetid://84652733960568",
	["party-popper"] = "rbxassetid://111626795712193",
	["pause"] = "rbxassetid://74873705394436",
	["paw-print"] = "rbxassetid://112218825427601",
	["pc-case"] = "rbxassetid://122978648019101",
	["pen-line"] = "rbxassetid://109108135755303",
	["pen-off"] = "rbxassetid://84807123119438",
	["pen-tool"] = "rbxassetid://106145404953445",
	["pen"] = "rbxassetid://72037878096321",
	["pencil-line"] = "rbxassetid://88392917053533",
	["pencil-off"] = "rbxassetid://103330927652832",
	["pencil-ruler"] = "rbxassetid://110120288284597",
	["pencil"] = "rbxassetid://137986121120732",
	["pentagon"] = "rbxassetid://79184802179890",
	["percent"] = "rbxassetid://130155041032013",
	["person-standing"] = "rbxassetid://125020872044147",
	["philippine-peso"] = "rbxassetid://91173798254675",
	["phone-call"] = "rbxassetid://70555587592860",
	["phone-forwarded"] = "rbxassetid://113269614319737",
	["phone-incoming"] = "rbxassetid://82863576359288",
	["phone-missed"] = "rbxassetid://130156165198376",
	["phone-off"] = "rbxassetid://133318623553383",
	["phone-outgoing"] = "rbxassetid://104576478735825",
	["phone"] = "rbxassetid://128804946640049",
	["pi"] = "rbxassetid://74936036243146",
	["piano"] = "rbxassetid://85008880789520",
	["pickaxe"] = "rbxassetid://105888023317688",
	["picture-in-picture-2"] = "rbxassetid://112803319544468",
	["picture-in-picture"] = "rbxassetid://80579597835123",
	["piggy-bank"] = "rbxassetid://79498575790721",
	["pilcrow-left"] = "rbxassetid://103803000849583",
	["pilcrow-right"] = "rbxassetid://104881733911870",
	["pilcrow"] = "rbxassetid://139512780392871",
	["pill-bottle"] = "rbxassetid://118394692404597",
	["pill"] = "rbxassetid://73280534813448",
	["pin-off"] = "rbxassetid://127696372451750",
	["pin"] = "rbxassetid://120978111007514",
	["pipette"] = "rbxassetid://133167932934404",
	["pizza"] = "rbxassetid://126964453193501",
	["plane-landing"] = "rbxassetid://122555692211889",
	["plane-takeoff"] = "rbxassetid://117179478829575",
	["plane"] = "rbxassetid://126985561580989",
	["play"] = "rbxassetid://135609604299893",
	["plug-2"] = "rbxassetid://97912386476366",
	["plug-zap"] = "rbxassetid://74506269884055",
	["plug"] = "rbxassetid://99782373064495",
	["plus"] = "rbxassetid://111774323017047",
	["pocket-knife"] = "rbxassetid://134075428063965",
	["pocket"] = "rbxassetid://136686762542964",
	["podcast"] = "rbxassetid://109577075549215",
	["pointer-off"] = "rbxassetid://95488389312794",
	["pointer"] = "rbxassetid://92615117311099",
	["popcorn"] = "rbxassetid://139446511232750",
	["popsicle"] = "rbxassetid://112696318077073",
	["pound-sterling"] = "rbxassetid://127482649469130",
	["power-off"] = "rbxassetid://118768311012214",
	["power"] = "rbxassetid://96479131758775",
	["presentation"] = "rbxassetid://106134583757890",
	["printer-check"] = "rbxassetid://130273549443689",
	["printer"] = "rbxassetid://76080649734247",
	["projector"] = "rbxassetid://103281856385283",
	["proportions"] = "rbxassetid://130046855997237",
	["puzzle"] = "rbxassetid://136837798892463",
	["pyramid"] = "rbxassetid://107811442374127",
	["qr-code"] = "rbxassetid://105329945723350",
	["quote"] = "rbxassetid://103271711590001",
	["rabbit"] = "rbxassetid://98580518804206",
	["radar"] = "rbxassetid://138528222906635",
	["radiation"] = "rbxassetid://104499586848433",
	["radical"] = "rbxassetid://132758286926047",
	["radio-receiver"] = "rbxassetid://129598303378835",
	["radio-tower"] = "rbxassetid://93958663130054",
	["radio"] = "rbxassetid://85611589536956",
	["radius"] = "rbxassetid://89814505307129",
	["rail-symbol"] = "rbxassetid://134295386306962",
	["rainbow"] = "rbxassetid://132488862841895",
	["rat"] = "rbxassetid://127400975953159",
	["ratio"] = "rbxassetid://126369423897295",
	["receipt-cent"] = "rbxassetid://91557573925201",
	["receipt-euro"] = "rbxassetid://94015722210295",
	["receipt-indian-rupee"] = "rbxassetid://89718170439990",
	["receipt-japanese-yen"] = "rbxassetid://132472560758851",
	["receipt-pound-sterling"] = "rbxassetid://73934967569625",
	["receipt-russian-ruble"] = "rbxassetid://105164576936853",
	["receipt-swiss-franc"] = "rbxassetid://72503668620116",
	["receipt-text"] = "rbxassetid://138483536013737",
	["receipt-turkish-lira"] = "rbxassetid://91950765836342",
	["receipt"] = "rbxassetid://77877895901792",
	["rectangle-circle"] = "rbxassetid://100642423153903",
	["rectangle-ellipsis"] = "rbxassetid://112919953980965",
	["rectangle-goggles"] = "rbxassetid://98605436666727",
	["rectangle-horizontal"] = "rbxassetid://90224199814966",
	["rectangle-vertical"] = "rbxassetid://117277050590967",
	["recycle"] = "rbxassetid://140417023381961",
	["redo-2"] = "rbxassetid://70451039017914",
	["redo-dot"] = "rbxassetid://94252981719732",
	["redo"] = "rbxassetid://116150342119054",
	["refresh-ccw-dot"] = "rbxassetid://106702246753270",
	["refresh-ccw"] = "rbxassetid://117913330389477",
	["refresh-cw-off"] = "rbxassetid://140179498843054",
	["refresh-cw"] = "rbxassetid://138133190015277",
	["refrigerator"] = "rbxassetid://102614042652753",
	["regex"] = "rbxassetid://100727200791841",
	["remove-formatting"] = "rbxassetid://112833162022628",
	["repeat-1"] = "rbxassetid://130144534857095",
	["repeat-2"] = "rbxassetid://85927537182704",
	["repeat"] = "rbxassetid://121886242955173",
	["replace-all"] = "rbxassetid://127862728198635",
	["replace"] = "rbxassetid://128404082279430",
	["reply-all"] = "rbxassetid://71723137343562",
	["reply"] = "rbxassetid://109788633497028",
	["rewind"] = "rbxassetid://95205297521988",
	["ribbon"] = "rbxassetid://94265331526851",
	["rocket"] = "rbxassetid://87412317685854",
	["rocking-chair"] = "rbxassetid://110420269495360",
	["roller-coaster"] = "rbxassetid://112426178972099",
	["rose"] = "rbxassetid://126336840238769",
	["rotate-3d"] = "rbxassetid://76300551576392",
	["rotate-ccw-key"] = "rbxassetid://74976035240976",
	["rotate-ccw-square"] = "rbxassetid://90515853170424",
	["rotate-ccw"] = "rbxassetid://110116685948665",
	["rotate-cw-square"] = "rbxassetid://77095448159303",
	["rotate-cw"] = "rbxassetid://84183336178654",
	["route-off"] = "rbxassetid://106350402024079",
	["route"] = "rbxassetid://89968303228953",
	["router"] = "rbxassetid://102130331994471",
	["rows-2"] = "rbxassetid://112556185960101",
	["rows-3"] = "rbxassetid://117215586961375",
	["rows-4"] = "rbxassetid://125646021959055",
	["rss"] = "rbxassetid://131789058984793",
	["ruler-dimension-line"] = "rbxassetid://70673861371412",
	["ruler"] = "rbxassetid://81432445547423",
	["russian-ruble"] = "rbxassetid://126357936542156",
	["sailboat"] = "rbxassetid://87110567187540",
	["salad"] = "rbxassetid://128864507821603",
	["sandwich"] = "rbxassetid://104573187458917",
	["satellite-dish"] = "rbxassetid://136742443888305",
	["satellite"] = "rbxassetid://134967053164645",
	["saudi-riyal"] = "rbxassetid://102282769104635",
	["save-all"] = "rbxassetid://116946975799440",
	["save-off"] = "rbxassetid://87085435778560",
	["save"] = "rbxassetid://126116963775616",
	["scale-3d"] = "rbxassetid://72414199620352",
	["scale"] = "rbxassetid://108203682317477",
	["scaling"] = "rbxassetid://122360365318466",
	["scan-barcode"] = "rbxassetid://96889457154761",
	["scan-eye"] = "rbxassetid://99244790601968",
	["scan-face"] = "rbxassetid://109959345069668",
	["scan-heart"] = "rbxassetid://106280819776142",
	["scan-line"] = "rbxassetid://126544908146540",
	["scan-qr-code"] = "rbxassetid://105409149549927",
	["scan-search"] = "rbxassetid://80009010551347",
	["scan-text"] = "rbxassetid://73702396787766",
	["scan"] = "rbxassetid://123104789658180",
	["school"] = "rbxassetid://76351530290068",
	["scissors-line-dashed"] = "rbxassetid://122237447974173",
	["scissors"] = "rbxassetid://118665510911274",
	["screen-share-off"] = "rbxassetid://107677572669805",
	["screen-share"] = "rbxassetid://85137895705653",
	["scroll-text"] = "rbxassetid://97321022666868",
	["scroll"] = "rbxassetid://74072101474951",
	["search-check"] = "rbxassetid://75442076191356",
	["search-code"] = "rbxassetid://117114794592802",
	["search-slash"] = "rbxassetid://96483932261041",
	["search-x"] = "rbxassetid://137319957522951",
	["search"] = "rbxassetid://121018724060431",
	["section"] = "rbxassetid://91732188298948",
	["send-horizontal"] = "rbxassetid://111734392411664",
	["send-to-back"] = "rbxassetid://75340312862253",
	["send"] = "rbxassetid://127751956873796",
	["separator-horizontal"] = "rbxassetid://84864453699927",
	["separator-vertical"] = "rbxassetid://84031801478581",
	["server-cog"] = "rbxassetid://138470287250966",
	["server-crash"] = "rbxassetid://132810618000212",
	["server-off"] = "rbxassetid://114048751507723",
	["server"] = "rbxassetid://92188766517878",
	["settings-2"] = "rbxassetid://135684703553372",
	["settings"] = "rbxassetid://80758916183665",
	["shapes"] = "rbxassetid://129989433311409",
	["share-2"] = "rbxassetid://71210767962065",
	["share"] = "rbxassetid://87340985053299",
	["sheet"] = "rbxassetid://134902122480171",
	["shell"] = "rbxassetid://140212943563599",
	["shield-alert"] = "rbxassetid://114995877719925",
	["shield-ban"] = "rbxassetid://108765041044649",
	["shield-check"] = "rbxassetid://87354736164608",
	["shield-ellipsis"] = "rbxassetid://114794739892123",
	["shield-half"] = "rbxassetid://117842634172647",
	["shield-minus"] = "rbxassetid://89965059528921",
	["shield-off"] = "rbxassetid://133426959132690",
	["shield-plus"] = "rbxassetid://100664857995498",
	["shield-question-mark"] = "rbxassetid://135722075265150",
	["shield-user"] = "rbxassetid://124832775645347",
	["shield-x"] = "rbxassetid://73370117343811",
	["shield"] = "rbxassetid://110987169760162",
	["ship-wheel"] = "rbxassetid://130797795829448",
	["ship"] = "rbxassetid://83995100553930",
	["shirt"] = "rbxassetid://106579555405966",
	["shopping-bag"] = "rbxassetid://71885477293226",
	["shopping-basket"] = "rbxassetid://138646411956433",
	["shopping-cart"] = "rbxassetid://128420521375441",
	["shovel"] = "rbxassetid://102465000512056",
	["shower-head"] = "rbxassetid://75884944024117",
	["shredder"] = "rbxassetid://122125164414463",
	["shrimp"] = "rbxassetid://102625900815307",
	["shrink"] = "rbxassetid://90953687918880",
	["shrub"] = "rbxassetid://127326280714343",
	["shuffle"] = "rbxassetid://132382786975101",
	["sigma"] = "rbxassetid://126884244870899",
	["signal-high"] = "rbxassetid://130436670012270",
	["signal-low"] = "rbxassetid://73674683500458",
	["signal-medium"] = "rbxassetid://125003021367019",
	["signal-zero"] = "rbxassetid://130045332414754",
	["signal"] = "rbxassetid://78424889355261",
	["signature"] = "rbxassetid://114402748013000",
	["signpost-big"] = "rbxassetid://115780185675001",
	["signpost"] = "rbxassetid://106584743791433",
	["siren"] = "rbxassetid://134210267818039",
	["skip-back"] = "rbxassetid://70466132711334",
	["skip-forward"] = "rbxassetid://124844823753990",
	["skull"] = "rbxassetid://137726256442333",
	["slack"] = "rbxassetid://96089719516736",
	["slash"] = "rbxassetid://117792185664263",
	["slice"] = "rbxassetid://95810504278179",
	["sliders-horizontal"] = "rbxassetid://85538382643347",
	["sliders-vertical"] = "rbxassetid://101190569086853",
	["smartphone-charging"] = "rbxassetid://102837532613995",
	["smartphone-nfc"] = "rbxassetid://82326425754446",
	["smartphone"] = "rbxassetid://96623008834511",
	["smile-plus"] = "rbxassetid://131981881472144",
	["smile"] = "rbxassetid://105880397565283",
	["snail"] = "rbxassetid://70904536548363",
	["snowflake"] = "rbxassetid://101235206534566",
	["soap-dispenser-droplet"] = "rbxassetid://77258480479465",
	["sofa"] = "rbxassetid://114427687218324",
	["solar-panel"] = "rbxassetid://132448188047921",
	["soup"] = "rbxassetid://115092551871618",
	["space"] = "rbxassetid://87072088914178",
	["spade"] = "rbxassetid://131444449466462",
	["sparkle"] = "rbxassetid://111044800239623",
	["sparkles"] = "rbxassetid://138635884129147",
	["speaker"] = "rbxassetid://96227183003618",
	["speech"] = "rbxassetid://87013139446349",
	["spell-check-2"] = "rbxassetid://81556731785534",
	["spell-check"] = "rbxassetid://91913483031334",
	["spline-pointer"] = "rbxassetid://84842840956804",
	["spline"] = "rbxassetid://129406685807412",
	["split"] = "rbxassetid://105112438805988",
	["spool"] = "rbxassetid://124541981347743",
	["spotlight"] = "rbxassetid://77571742539344",
	["spray-can"] = "rbxassetid://128372039366326",
	["sprout"] = "rbxassetid://100091687832508",
	["square-activity"] = "rbxassetid://89496630185293",
	["square-arrow-down-left"] = "rbxassetid://108194680296901",
	["square-arrow-down-right"] = "rbxassetid://99403846801050",
	["square-arrow-down"] = "rbxassetid://135962519626588",
	["square-arrow-left"] = "rbxassetid://111671474549238",
	["square-arrow-out-down-left"] = "rbxassetid://125714881756353",
	["square-arrow-out-down-right"] = "rbxassetid://89971003001390",
	["square-arrow-out-up-left"] = "rbxassetid://103759986579087",
	["square-arrow-out-up-right"] = "rbxassetid://91221896066807",
	["square-arrow-right"] = "rbxassetid://113920471701361",
	["square-arrow-up-left"] = "rbxassetid://112424670290693",
	["square-arrow-up-right"] = "rbxassetid://76602291406940",
	["square-arrow-up"] = "rbxassetid://106998604646718",
	["square-asterisk"] = "rbxassetid://89186832353625",
	["square-bottom-dashed-scissors"] = "rbxassetid://79076980104803",
	["square-chart-gantt"] = "rbxassetid://104034017316411",
	["square-check-big"] = "rbxassetid://115320390907184",
	["square-check"] = "rbxassetid://134682053539509",
	["square-chevron-down"] = "rbxassetid://91032307924592",
	["square-chevron-left"] = "rbxassetid://73143404829510",
	["square-chevron-right"] = "rbxassetid://90612077729930",
	["square-chevron-up"] = "rbxassetid://85565910197337",
	["square-code"] = "rbxassetid://81604576616881",
	["square-dashed-bottom-code"] = "rbxassetid://100354801563230",
	["square-dashed-bottom"] = "rbxassetid://101102319625624",
	["square-dashed-kanban"] = "rbxassetid://90388067649847",
	["square-dashed-mouse-pointer"] = "rbxassetid://121016142178467",
	["square-dashed-top-solid"] = "rbxassetid://117157577548540",
	["square-dashed"] = "rbxassetid://136905537847606",
	["square-divide"] = "rbxassetid://99894657101970",
	["square-dot"] = "rbxassetid://116613421354866",
	["square-equal"] = "rbxassetid://110283363706707",
	["square-function"] = "rbxassetid://86075219551088",
	["square-kanban"] = "rbxassetid://114537101260131",
	["square-library"] = "rbxassetid://73810931222081",
	["square-m"] = "rbxassetid://117662700410577",
	["square-menu"] = "rbxassetid://104067089444415",
	["square-minus"] = "rbxassetid://116764432015770",
	["square-mouse-pointer"] = "rbxassetid://76141850603920",
	["square-parking-off"] = "rbxassetid://100857293535141",
	["square-parking"] = "rbxassetid://133116656122387",
	["square-pause"] = "rbxassetid://86608552787615",
	["square-pen"] = "rbxassetid://120239476110475",
	["square-percent"] = "rbxassetid://87111930314567",
	["square-pi"] = "rbxassetid://75383328781618",
	["square-pilcrow"] = "rbxassetid://131854284699367",
	["square-play"] = "rbxassetid://108186325238481",
	["square-plus"] = "rbxassetid://114713264461873",
	["square-power"] = "rbxassetid://129240437805187",
	["square-radical"] = "rbxassetid://132645931868292",
	["square-round-corner"] = "rbxassetid://104592745113567",
	["square-scissors"] = "rbxassetid://110601255612411",
	["square-sigma"] = "rbxassetid://113231244246816",
	["square-slash"] = "rbxassetid://105477013908757",
	["square-split-horizontal"] = "rbxassetid://76095370148660",
	["square-split-vertical"] = "rbxassetid://88589192032058",
	["square-square"] = "rbxassetid://136555087357875",
	["square-stack"] = "rbxassetid://100463396619394",
	["square-star"] = "rbxassetid://94506958703720",
	["square-stop"] = "rbxassetid://80018708472943",
	["square-terminal"] = "rbxassetid://83969264476798",
	["square-user-round"] = "rbxassetid://86484997229302",
	["square-user"] = "rbxassetid://70771214183445",
	["square-x"] = "rbxassetid://125136183850190",
	["square"] = "rbxassetid://86304921356806",
	["squares-exclude"] = "rbxassetid://102345385822324",
	["squares-intersect"] = "rbxassetid://120869602570119",
	["squares-subtract"] = "rbxassetid://131484650948795",
	["squares-unite"] = "rbxassetid://96673080107843",
	["squircle-dashed"] = "rbxassetid://129936702532522",
	["squircle"] = "rbxassetid://82426632573807",
	["squirrel"] = "rbxassetid://112864252085343",
	["stamp"] = "rbxassetid://92370779813368",
	["star-half"] = "rbxassetid://117449275562979",
	["star-off"] = "rbxassetid://75742832732503",
	["star"] = "rbxassetid://136141469398409",
	["step-back"] = "rbxassetid://108672750005121",
	["step-forward"] = "rbxassetid://126131872136145",
	["stethoscope"] = "rbxassetid://122331031702148",
	["sticker"] = "rbxassetid://79938203791608",
	["sticky-note"] = "rbxassetid://111894074643919",
	["store"] = "rbxassetid://90338129673705",
	["stretch-horizontal"] = "rbxassetid://87665042192343",
	["stretch-vertical"] = "rbxassetid://95265463417122",
	["strikethrough"] = "rbxassetid://103417324549613",
	["subscript"] = "rbxassetid://74553514785183",
	["sun-dim"] = "rbxassetid://129141645592715",
	["sun-medium"] = "rbxassetid://130278807964710",
	["sun-moon"] = "rbxassetid://75752898854559",
	["sun-snow"] = "rbxassetid://112791898014579",
	["sun"] = "rbxassetid://110150589884127",
	["sunrise"] = "rbxassetid://134705665494098",
	["sunset"] = "rbxassetid://75904872203588",
	["superscript"] = "rbxassetid://96887696590118",
	["swatch-book"] = "rbxassetid://126786244872453",
	["swiss-franc"] = "rbxassetid://113497920041625",
	["switch-camera"] = "rbxassetid://76841154349737",
	["sword"] = "rbxassetid://124448418211665",
	["swords"] = "rbxassetid://81872698913435",
	["syringe"] = "rbxassetid://123891270479254",
	["table-2"] = "rbxassetid://95751552281545",
	["table-cells-merge"] = "rbxassetid://95363715175258",
	["table-cells-split"] = "rbxassetid://114799086088649",
	["table-columns-split"] = "rbxassetid://111011625447949",
	["table-of-contents"] = "rbxassetid://135044763275414",
	["table-properties"] = "rbxassetid://125062886015372",
	["table-rows-split"] = "rbxassetid://96443733673997",
	["table"] = "rbxassetid://109109148250737",
	["tablet-smartphone"] = "rbxassetid://133680859813404",
	["tablet"] = "rbxassetid://128403991264386",
	["tablets"] = "rbxassetid://80835787970735",
	["tag"] = "rbxassetid://129104970103940",
	["tags"] = "rbxassetid://107179263080798",
	["tally-1"] = "rbxassetid://115301298241643",
	["tally-2"] = "rbxassetid://110363186864027",
	["tally-3"] = "rbxassetid://97655344572540",
	["tally-4"] = "rbxassetid://102633494371890",
	["tally-5"] = "rbxassetid://88031817475886",
	["tangent"] = "rbxassetid://123263132981724",
	["target"] = "rbxassetid://87563802520297",
	["telescope"] = "rbxassetid://91755049143647",
	["tent-tree"] = "rbxassetid://76698322463977",
	["tent"] = "rbxassetid://109779587826330",
	["terminal"] = "rbxassetid://106783148545356",
	["test-tube-diagonal"] = "rbxassetid://75662704378840",
	["test-tube"] = "rbxassetid://98801015650164",
	["test-tubes"] = "rbxassetid://92555361447433",
	["text-align-center"] = "rbxassetid://84051028246390",
	["text-align-end"] = "rbxassetid://130041738343555",
	["text-align-justify"] = "rbxassetid://80279880143030",
	["text-align-start"] = "rbxassetid://134489585487649",
	["text-cursor-input"] = "rbxassetid://107551944047171",
	["text-cursor"] = "rbxassetid://115984654447300",
	["text-initial"] = "rbxassetid://129458097472087",
	["text-quote"] = "rbxassetid://139278366448736",
	["text-search"] = "rbxassetid://92345384671606",
	["text-select"] = "rbxassetid://117087320884956",
	["text-wrap"] = "rbxassetid://114804318314018",
	["theater"] = "rbxassetid://108558145549163",
	["thermometer-snowflake"] = "rbxassetid://121876188028425",
	["thermometer-sun"] = "rbxassetid://106693240074310",
	["thermometer"] = "rbxassetid://106546011492311",
	["thumbs-down"] = "rbxassetid://87794009914015",
	["thumbs-up"] = "rbxassetid://111137070767020",
	["ticket-check"] = "rbxassetid://105428777212507",
	["ticket-minus"] = "rbxassetid://78966299769328",
	["ticket-percent"] = "rbxassetid://80834774406405",
	["ticket-plus"] = "rbxassetid://110086734392189",
	["ticket-slash"] = "rbxassetid://89045681172265",
	["ticket-x"] = "rbxassetid://88674114109926",
	["ticket"] = "rbxassetid://126527071492145",
	["tickets-plane"] = "rbxassetid://100367018248695",
	["tickets"] = "rbxassetid://135268612687833",
	["timer-off"] = "rbxassetid://110916370767271",
	["timer-reset"] = "rbxassetid://110052125369932",
	["timer"] = "rbxassetid://85473888890506",
	["toggle-left"] = "rbxassetid://85887872573050",
	["toggle-right"] = "rbxassetid://90411952142550",
	["toilet"] = "rbxassetid://80930782432931",
	["tool-case"] = "rbxassetid://87533537832522",
	["tornado"] = "rbxassetid://88358291515768",
	["torus"] = "rbxassetid://70855707283051",
	["touchpad-off"] = "rbxassetid://78784008075456",
	["touchpad"] = "rbxassetid://74882354908014",
	["tower-control"] = "rbxassetid://95937619060532",
	["toy-brick"] = "rbxassetid://86293483924633",
	["tractor"] = "rbxassetid://103376704722051",
	["traffic-cone"] = "rbxassetid://74110220470369",
	["train-front-tunnel"] = "rbxassetid://105194827005114",
	["train-front"] = "rbxassetid://125237934215370",
	["train-track"] = "rbxassetid://77451032453723",
	["tram-front"] = "rbxassetid://93315182364998",
	["transgender"] = "rbxassetid://135530817673639",
	["trash-2"] = "rbxassetid://109843431391323",
	["trash"] = "rbxassetid://106723740584310",
	["tree-deciduous"] = "rbxassetid://123124389219004",
	["tree-palm"] = "rbxassetid://103846705893963",
	["tree-pine"] = "rbxassetid://124662547202594",
	["trees"] = "rbxassetid://121203841375919",
	["trello"] = "rbxassetid://130987241149527",
	["trending-down"] = "rbxassetid://139309232226438",
	["trending-up-down"] = "rbxassetid://85083293981691",
	["trending-up"] = "rbxassetid://81819858538839",
	["triangle-alert"] = "rbxassetid://125920361880643",
	["triangle-dashed"] = "rbxassetid://124324079103935",
	["triangle-right"] = "rbxassetid://116930791412791",
	["triangle"] = "rbxassetid://126330486745540",
	["trophy"] = "rbxassetid://131545003268773",
	["truck-electric"] = "rbxassetid://111873446387359",
	["truck"] = "rbxassetid://86662707764771",
	["turkish-lira"] = "rbxassetid://114589876174070",
	["turntable"] = "rbxassetid://129870346487856",
	["turtle"] = "rbxassetid://118295081560334",
	["tv-minimal-play"] = "rbxassetid://99201833426972",
	["tv-minimal"] = "rbxassetid://100382201729427",
	["tv"] = "rbxassetid://135687724791776",
	["twitch"] = "rbxassetid://71383308134888",
	["twitter"] = "rbxassetid://88791703276842",
	["type-outline"] = "rbxassetid://80108627791690",
	["type"] = "rbxassetid://133543553793564",
	["umbrella-off"] = "rbxassetid://72395143739955",
	["umbrella"] = "rbxassetid://127502210274589",
	["underline"] = "rbxassetid://123709229216544",
	["undo-2"] = "rbxassetid://113885292059932",
	["undo-dot"] = "rbxassetid://132055277744844",
	["undo"] = "rbxassetid://111258459077271",
	["unfold-horizontal"] = "rbxassetid://117128358526398",
	["unfold-vertical"] = "rbxassetid://116593025265499",
	["ungroup"] = "rbxassetid://106674800451003",
	["university"] = "rbxassetid://84652528263642",
	["unlink-2"] = "rbxassetid://128131898892572",
	["unlink"] = "rbxassetid://139835795227752",
	["unplug"] = "rbxassetid://90171381619874",
	["upload"] = "rbxassetid://138212042425501",
	["usb"] = "rbxassetid://117230058949613",
	["user-check"] = "rbxassetid://81775205032725",
	["user-cog"] = "rbxassetid://92795491530865",
	["user-lock"] = "rbxassetid://78892639693821",
	["user-minus"] = "rbxassetid://126976941957511",
	["user-pen"] = "rbxassetid://87445472574836",
	["user-plus"] = "rbxassetid://118514469915884",
	["user-round-check"] = "rbxassetid://118794737621941",
	["user-round-cog"] = "rbxassetid://78239503290053",
	["user-round-minus"] = "rbxassetid://98944176636447",
	["user-round-pen"] = "rbxassetid://108155244324878",
	["user-round-plus"] = "rbxassetid://113301899567470",
	["user-round-search"] = "rbxassetid://71565774381870",
	["user-round-x"] = "rbxassetid://122367980560930",
	["user-round"] = "rbxassetid://136485052187963",
	["user-search"] = "rbxassetid://101335649828115",
	["user-star"] = "rbxassetid://98777846316000",
	["user-x"] = "rbxassetid://139748155894754",
	["user"] = "rbxassetid://81589895647169",
	["users-round"] = "rbxassetid://103005444008339",
	["users"] = "rbxassetid://115398113982385",
	["utensils-crossed"] = "rbxassetid://109520762270383",
	["utensils"] = "rbxassetid://139952569804235",
	["utility-pole"] = "rbxassetid://101965541238242",
	["variable"] = "rbxassetid://104743088438151",
	["vault"] = "rbxassetid://108049164599845",
	["vector-square"] = "rbxassetid://86713728565344",
	["vegan"] = "rbxassetid://119489190688082",
	["venetian-mask"] = "rbxassetid://102636443033920",
	["venus-and-mars"] = "rbxassetid://120227752103771",
	["venus"] = "rbxassetid://82891342220859",
	["vibrate-off"] = "rbxassetid://113446447326246",
	["vibrate"] = "rbxassetid://108330910738733",
	["video-off"] = "rbxassetid://132239189859305",
	["video"] = "rbxassetid://107587444636945",
	["videotape"] = "rbxassetid://114816894323398",
	["view"] = "rbxassetid://118717253976805",
	["voicemail"] = "rbxassetid://134313454010227",
	["volleyball"] = "rbxassetid://83889351124153",
	["volume-1"] = "rbxassetid://98514588731639",
	["volume-2"] = "rbxassetid://89344380902620",
	["volume-off"] = "rbxassetid://103047478058767",
	["volume-x"] = "rbxassetid://139252359189540",
	["volume"] = "rbxassetid://103236289817396",
	["vote"] = "rbxassetid://89409762851246",
	["wallet-cards"] = "rbxassetid://129728715308337",
	["wallet-minimal"] = "rbxassetid://137800448816116",
	["wallet"] = "rbxassetid://132331555762628",
	["wallpaper"] = "rbxassetid://74682121235494",
	["wand-sparkles"] = "rbxassetid://82546429942392",
	["wand"] = "rbxassetid://114580617777835",
	["warehouse"] = "rbxassetid://78388887451080",
	["washing-machine"] = "rbxassetid://104194127573858",
	["watch"] = "rbxassetid://130544621618405",
	["waves-ladder"] = "rbxassetid://101808619355514",
	["waves"] = "rbxassetid://96340135183647",
	["waypoints"] = "rbxassetid://102450133666017",
	["webcam"] = "rbxassetid://104148487911129",
	["webhook-off"] = "rbxassetid://96370548093471",
	["webhook"] = "rbxassetid://112812457747322",
	["weight"] = "rbxassetid://103860559844854",
	["wheat-off"] = "rbxassetid://133294844612307",
	["wheat"] = "rbxassetid://85261952080359",
	["whole-word"] = "rbxassetid://90111083954485",
	["wifi-cog"] = "rbxassetid://110500263326209",
	["wifi-high"] = "rbxassetid://81954601342139",
	["wifi-low"] = "rbxassetid://138217335635913",
	["wifi-off"] = "rbxassetid://74113634330106",
	["wifi-pen"] = "rbxassetid://91290205064712",
	["wifi-sync"] = "rbxassetid://84043971055177",
	["wifi-zero"] = "rbxassetid://124286465246123",
	["wifi"] = "rbxassetid://104669375183960",
	["wind-arrow-down"] = "rbxassetid://127753987414870",
	["wind"] = "rbxassetid://114551690399915",
	["wine-off"] = "rbxassetid://108294164302317",
	["wine"] = "rbxassetid://115743721332829",
	["workflow"] = "rbxassetid://99186544029189",
	["worm"] = "rbxassetid://115752311548091",
	["wrench"] = "rbxassetid://112148279212860",
	["x"] = "rbxassetid://110786993356448",
	["youtube"] = "rbxassetid://123663668456341",
	["zap-off"] = "rbxassetid://81385483183652",
	["zap"] = "rbxassetid://130551565616516",
	["zoom-in"] = "rbxassetid://127956924984803",
	["zoom-out"] = "rbxassetid://108334162607319",
	["balloon"] = "rbxassetid://97489111621526",
	["beef-off"] = "rbxassetid://99869959725200",
	["book-search"] = "rbxassetid://132585409504950",
	["calendars"] = "rbxassetid://130944763042289",
	["cannabis-off"] = "rbxassetid://101938500363812",
	["cctv-off"] = "rbxassetid://75925370187295",
	["cigarette"] = "rbxassetid://137149549886852",
	["circle-pile"] = "rbxassetid://116353155251541",
	["cloud-backup"] = "rbxassetid://111649579696132",
	["cloud-sync"] = "rbxassetid://79393911188593",
	["database-search"] = "rbxassetid://92017137080138",
	["ellipse"] = "rbxassetid://71559658267482",
	["fingerprint-pattern"] = "rbxassetid://80934710831288",
	["fishing-hook"] = "rbxassetid://121038780855899",
	["fishing-rod"] = "rbxassetid://71754848048049",
	["form"] = "rbxassetid://72999643971000",
	["git-merge-conflict"] = "rbxassetid://85677801675703",
	["globe-off"] = "rbxassetid://77775243585824",
	["globe-x"] = "rbxassetid://109268097029296",
	["hd"] = "rbxassetid://71682790698278",
	["image"] = "rbxassetid://112751259236831",
	["layers-plus"] = "rbxassetid://77587765623057",
	["lens-concave"] = "rbxassetid://94819631937027",
	["lens-convex"] = "rbxassetid://74736504195474",
	["line-dot-right-horizontal"] = "rbxassetid://104718593155221",
	["line-style"] = "rbxassetid://90176717785772",
	["map-pin-search"] = "rbxassetid://89065012915078",
	["message-circle-check"] = "rbxassetid://132772297689418",
	["message-square-check"] = "rbxassetid://125789987055668",
	["metronome"] = "rbxassetid://101991829345965",
	["mirror-rectangular"] = "rbxassetid://109046769760336",
	["mirror-round"] = "rbxassetid://121534049429097",
	["mouse-left"] = "rbxassetid://99144293708743",
	["mouse-right"] = "rbxassetid://88331710212594",
	["printer-x"] = "rbxassetid://103002721801548",
	["radio-off"] = "rbxassetid://80359258046586",
	["road"] = "rbxassetid://120251329173530",
	["scooter"] = "rbxassetid://100035452787934",
	["search-alert"] = "rbxassetid://127597984617505",
	["shelving-unit"] = "rbxassetid://80116568514793",
	["shield-cog-corner"] = "rbxassetid://111694066132698",
	["shield-cog"] = "rbxassetid://129235695057857",
	["sport-shoe"] = "rbxassetid://120495992692630",
	["square-arrow-right-enter"] = "rbxassetid://138867831495334",
	["square-arrow-right-exit"] = "rbxassetid://133688575845430",
	["square-centerline-dashed-horizontal"] = "rbxassetid://77780104374341",
	["square-centerline-dashed-vertical"] = "rbxassetid://107878435803525",
	["stone"] = "rbxassetid://135161057497830",
	["toolbox"] = "rbxassetid://85341033903792",
	["towel-rack"] = "rbxassetid://125223915620991",
	["user-key"] = "rbxassetid://105403041782190",
	["user-round-key"] = "rbxassetid://124547549008939",
	["van"] = "rbxassetid://122066377022942",
	["waves-arrow-down"] = "rbxassetid://129215220911792",
	["waves-arrow-up"] = "rbxassetid://102314705716217",
	["weight-tilde"] = "rbxassetid://112081212176951",
	["x-line-top"] = "rbxassetid://140592656289509",
	["zodiac-aquarius"] = "rbxassetid://74560047770362",
	["zodiac-aries"] = "rbxassetid://73255859670234",
	["zodiac-cancer"] = "rbxassetid://131985162532947",
	["zodiac-capricorn"] = "rbxassetid://97859568140652",
	["zodiac-gemini"] = "rbxassetid://80997588122992",
	["zodiac-leo"] = "rbxassetid://75509406718106",
	["zodiac-libra"] = "rbxassetid://113222735060218",
	["zodiac-ophiuchus"] = "rbxassetid://129180108892480",
	["zodiac-pisces"] = "rbxassetid://95845819440327",
	["zodiac-sagittarius"] = "rbxassetid://82651026742181",
	["zodiac-scorpio"] = "rbxassetid://113640924054631",
	["zodiac-taurus"] = "rbxassetid://123053219704400",
	["zodiac-virgo"] = "rbxassetid://99462994613661",
}
S.icons.home = S.icons["house"]
S.icons.combat = S.icons["swords"]
S.icons.visuals = S.icons["eye"]
S.icons.extras = S.icons["puzzle"]
S.icons.farming = S.icons["sprout"]
S.icons.target = S.icons["crosshair"]
S.icons.filter = S.icons["list-filter"]
S.icons.sliders = S.icons["sliders-horizontal"]
S.icons.down = S.icons["chevron-down"]
S.icons.right = S.icons["chevron-right"]
S.icons.resize = S.icons["maximize"]
S.icons.userround = S.icons["user-round"]
S.icons.usersround = S.icons["users-round"]
S.icons.columns2 = S.icons["columns-2"]

function S.librarynormalizeicon(value)
	if value == nil or value == false then return nil end
	value = tostring(value)
	if S.icons[value] then return S.icons[value] end
	if value:match("^%d+$") then return "rbxassetid://" .. value end
	if value:match("^rbxassetid://%d+$") or value:match("^rbxthumb://") or value:match("^rbxasset://") then return value end
	return nil
end

S.font = Enum.Font.BuilderSans
S.medium = Enum.Font.BuilderSansMedium
S.bold = Enum.Font.BuilderSansBold

S.animationsenabled = true
S.searchenabled = true
S.uitransparency = 0
S.menukey = Enum.KeyCode.RightShift
S.keypickercapturing = false
S.keypickersuppress = nil

S.defaultnotificationduration = 3.5
S.maxnotifications = 5

S.ti = TweenInfo.new(0.20, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
S.fastti = TweenInfo.new(0.16, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
S.hoverti = TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
S.checkti = S.fastti
S.tabti = S.ti
S.sectionti = TweenInfo.new(0.24, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
S.sectionattachti = TweenInfo.new(0.10, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
S.dropti = TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
S.quart20 = TweenInfo.new(0.20, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
S.quart24 = TweenInfo.new(0.24, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
S.quart26 = TweenInfo.new(0.26, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
S.quart28 = TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

S.themekeys = {
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
	"main",
	"highlight",
}

S.themebindings = {}
S.objectbindings = setmetatable({}, { __mode = "k" })
S.themecolorroles = {}

function S.indexthemecolors()
	table.clear(S.themecolorroles)
	for _, role in ipairs(S.themekeys) do
		if S.themecolorroles[S.theme[role]] == nil then S.themecolorroles[S.theme[role]] = role end
	end
end

S.indexthemecolors()

function S.themerole(color)
	if typeof(color) ~= "Color3" then return nil end

	return S.themecolorroles[color]
end

S.panelowners = setmetatable({}, { __mode = "k" })
S.panelthemes = {}

function S.panelcolor(object, role, fallback, panel)
	panel = S.panelowners[object]
	return panel and panel.overrides[role] or fallback
end

function S.registerpanel(root, name, panel)
	panel = { root = root, name = name, overrides = {}, bindings = {}, opacity = 1 }
	S.panelthemes[name] = panel
	S.panelowners[root] = panel
	for property, role in pairs(S.objectbindings[root] or {}) do
		panel.bindings[role] = setmetatable({ [root] = { [property] = true } }, { __mode = "k" })
	end
end

function S.setpanelcolor(panel, role, color)
	panel.overrides[role] = typeof(color) == "Color3" and color or nil
	if panel.bindings[role] then S.applythemerole(role, false, panel.bindings[role]) end
end

function S.bindtheme(
	object,
	property,
	value,
	explicitrole,
	role,
	bindings,
	previous,
	alphafield,
	entries,
	entries2,
	entries3,
	entries4,
	panel
)
	role = explicitrole or S.themerole(value)

	if not role then return end

	bindings = S.objectbindings[object]
	if not bindings then
		bindings = {}
		S.objectbindings[object] = bindings
	end
	previous = bindings[property]
	panel = S.panelowners[object] or S.panelowners[object.Parent]
	if panel then
		S.panelowners[object] = panel
		if previous and panel.bindings[previous] and panel.bindings[previous][object] then panel.bindings[previous][object][property] = nil end
		panel.bindings[role] = panel.bindings[role] or setmetatable({}, { __mode = "k" })
		panel.bindings[role][object] = panel.bindings[role][object] or {}
		panel.bindings[role][object][property] = true
	end
	if previous == role then return end
	if previous and S.themebindings[previous][object] then
		S.themebindings[previous][object][property] = nil
		if next(S.themebindings[previous][object]) == nil then
			S.themebindings[previous][object] = nil
		end
	end
	bindings[property] = role
	S.themebindings[role] = S.themebindings[role] or setmetatable({}, { __mode = "k" })
	S.themebindings[role][object] = S.themebindings[role][object] or {}
	S.themebindings[role][object][property] = true

	if role == "main" and S.__blush_accent_alpha then S.__blush_accent_alpha[object] = nil end

	alphafield = S.alphaproperty(object, property)

	if alphafield then
		entries = S.__blush_accent_alpha and S.__blush_accent_alpha[object]
		if entries and role ~= "white" and role ~= "black" then
			entries[alphafield] = nil
			if next(entries) == nil then S.__blush_accent_alpha[object] = nil end
		end

		entries2 = S.__blush_font_alpha and S.__blush_font_alpha[object]
		if entries2 and role ~= "text" and role ~= "text2" and role ~= "text3" then
			entries2[alphafield] = nil
			if next(entries2) == nil then S.__blush_font_alpha[object] = nil end
		end

		entries3 = S.__blush_highlight_alpha and S.__blush_highlight_alpha[object]
		if entries3 and role ~= "highlight" then
			entries3[alphafield] = nil
			if next(entries3) == nil then S.__blush_highlight_alpha[object] = nil end
		end

		entries4 = S.__blush_main_alpha and S.__blush_main_alpha[object]
		if entries4 and (not S.mainroles or not S.mainroles[role]) then
			entries4[alphafield] = nil
			if next(entries4) == nil then S.__blush_main_alpha[object] = nil end
		end
	end

	S.registeraccentalpha(object, property, role)
	S.registerfontalpha(object, property, role)
	S.registermainalpha(object, property, role)
	S.registerhighlightalpha(object, property, role)

	if alphafield then
		if role == "white" or role == "black" then
			entries = S.__blush_accent_alpha[object]

			if entries and entries[alphafield] ~= nil then
				object[alphafield] = S.effectiveaccentalpha(entries[alphafield])
			end
		elseif role == "text" or role == "text2" or role == "text3" then
			entries2 = S.__blush_font_alpha[object]

			if entries2 and entries2[alphafield] ~= nil then
				object[alphafield] = S.effectivefontalpha(entries2[alphafield])
			end
		elseif role == "highlight" then
			entries3 = S.__blush_highlight_alpha[object]

			if entries3 and entries3[alphafield] ~= nil then
				object[alphafield] = S.effectivehighlightalpha(entries3[alphafield])
			end
		elseif S.mainroles and S.mainroles[role] then
			entries4 = S.__blush_main_alpha[object]

			if entries4 and entries4[alphafield] ~= nil then
				object[alphafield] = S.effectivemainalpha(entries4[alphafield])
			end
		end
	end
end

function S.syncbinding(object, property, value, role) S.bindtheme(object, property, value, role) end

S.themetweens = setmetatable({}, { __mode = "k" })

function S.applythemerole(role, animate, bindings, target, objecttweens, value)
	bindings = bindings or S.themebindings[role]
	if not bindings then return end
	target = S.theme[role]
	for object, properties in pairs(bindings) do
		if not object.Parent then
			bindings[object] = nil
			S.objectbindings[object] = nil
		else
			target = S.panelcolor(object, role, S.theme[role])
			for property in pairs(properties) do
				objecttweens = S.themetweens[object]
				if objecttweens and objecttweens[property] then
					objecttweens[property]:Cancel()
					objecttweens[property] = nil
				end
				value = property == "TextColor3"
						and S.__blush_gradientstates[object]
						and Color3.new(1, 1, 1)
					or target
				if object[property] ~= value then
					if animate == true and S.animationsenabled and not S.constructing then
						objecttweens = objecttweens or {}
						S.themetweens[object] = objecttweens
						objecttweens[property] =
							S.tweenservice:Create(object, S.fastti, { [property] = value })
						objecttweens[property]:Play()
					else
						object[property] = value
					end
				end
			end
		end
	end
end

S.__blush_accent_alpha = setmetatable({}, {
	__mode = "k",
})

function S.alphaproperty(object, colorproperty)
	if colorproperty == "BackgroundColor3" and object:IsA("GuiObject") then
		return "BackgroundTransparency"
	end

	if
		colorproperty == "TextColor3"
		and (object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox"))
	then
		return "TextTransparency"
	end

	if
		colorproperty == "ImageColor3" and (object:IsA("ImageLabel") or object:IsA("ImageButton"))
	then
		return "ImageTransparency"
	end

	if colorproperty == "ScrollBarImageColor3" and object:IsA("ScrollingFrame") then
		return "ScrollBarImageTransparency"
	end

	if colorproperty == "Color" and (object:IsA("UIStroke") or object:IsA("UIShadow")) then
		return "Transparency"
	end

	return nil
end

function S.registeraccentalpha(object, colorproperty, role, property, entries, ok, value)
	if role ~= "white" and role ~= "black" then return end

	property = S.alphaproperty(object, colorproperty)

	if not property then return end

	entries = S.__blush_accent_alpha[object]

	if not entries then
		entries = {}
		S.__blush_accent_alpha[object] = entries
	end

	if entries[property] == nil then
		ok, value = S.invoke(function() return object[property] end)

		if ok then entries[property] = value end
	end
end

function S.setaccentalphabase(object, property, value, entries)
	entries = S.__blush_accent_alpha[object]

	if entries and entries[property] ~= nil then
		entries[property] = value
		return true
	end

	return false
end

function S.effectiveaccentalpha(value)
	return 1 - (1 - value) * math.clamp(S.theme.accentAlpha or 1, 0, 1)
end

function S.applyaccentalpha(value)
	S.theme.accentAlpha = math.clamp(value or 1, 0, 1)

	for object, entries in pairs(S.__blush_accent_alpha) do
		if not object.Parent then
			S.__blush_accent_alpha[object] = nil
		else
			for property, base in pairs(entries) do
				object[property] = S.effectiveaccentalpha(base)
			end
		end
	end
end

S.__blush_font_alpha = setmetatable({}, {
	__mode = "k",
})

function S.registerfontalpha(object, colorproperty, role, property, entries, ok, value)
	if role ~= "text" and role ~= "text2" and role ~= "text3" then return end

	property = S.alphaproperty(object, colorproperty)

	if not property then return end

	entries = S.__blush_font_alpha[object]

	if not entries then
		entries = {}
		S.__blush_font_alpha[object] = entries
	end

	if entries[property] == nil then
		ok, value = S.invoke(function() return object[property] end)

		if ok then entries[property] = value end
	end
end

function S.setfontalphabase(object, property, value, entries)
	entries = S.__blush_font_alpha[object]

	if entries and entries[property] ~= nil then
		entries[property] = value
		return true
	end

	return false
end

function S.effectivefontalpha(value)
	return 1 - (1 - value) * math.clamp(S.theme.fontAlpha or 1, 0, 1)
end

function S.applyfontalpha(value)
	S.theme.fontAlpha = math.clamp(value or 1, 0, 1)

	for object, entries in pairs(S.__blush_font_alpha) do
		if not object.Parent then
			S.__blush_font_alpha[object] = nil
		else
			for property, base in pairs(entries) do
				object[property] = S.effectivefontalpha(base)
			end
		end
	end
end

S.__blush_main_alpha = setmetatable({}, {
	__mode = "k",
})

function S.registermainalpha(object, colorproperty, role, property, entries, ok, value)
	if not S.mainroles or not S.mainroles[role] or role == "section" then return end

	property = S.alphaproperty(object, colorproperty)
	if not property then return end

	if colorproperty == "BackgroundColor3" and S.transparencyroles and S.transparencyroles[role] then
		return
	end

	entries = S.__blush_main_alpha[object]
	if not entries then
		entries = {}
		S.__blush_main_alpha[object] = entries
	end

	if entries[property] == nil then
		ok, value = S.invoke(function() return object[property] end)
		if ok then entries[property] = value end
	end
end

function S.setmainalphabase(object, property, value, entries)
	entries = S.__blush_main_alpha[object]
	if entries and entries[property] ~= nil then
		entries[property] = value
		return true
	end
	return false
end

function S.effectivemainalpha(value)
	return 1 - (1 - value) * math.clamp(S.theme.mainAlpha or 1, 0, 1)
end

function S.applymainalpha(value)
	S.theme.mainAlpha = math.clamp(value or 1, 0, 1)
	for object, entries in pairs(S.__blush_main_alpha) do
		if not object.Parent then
			S.__blush_main_alpha[object] = nil
		else
			for property, base in pairs(entries) do
				object[property] = S.effectivemainalpha(base)
			end
		end
	end
	if S.applyuitransparency then S.applyuitransparency(S.uitransparency * 100) end
end

S.__blush_highlight_alpha = setmetatable({}, {
	__mode = "k",
})

function S.registerhighlightalpha(object, colorproperty, role, property, entries, ok, value)
	if role ~= "highlight" then return end
	property = S.alphaproperty(object, colorproperty)
	if not property then return end
	entries = S.__blush_highlight_alpha[object]
	if not entries then
		entries = {}
		S.__blush_highlight_alpha[object] = entries
	end
	if entries[property] == nil then
		ok, value = S.invoke(function() return object[property] end)
		if ok then entries[property] = value end
	end
end

function S.sethighlightalphabase(object, property, value, entries)
	entries = S.__blush_highlight_alpha[object]
	if entries and entries[property] ~= nil then
		entries[property] = value
		return true
	end
	return false
end

function S.effectivehighlightalpha(value)
	return 1 - (1 - value) * math.clamp(S.theme.highlightAlpha or 1, 0, 1)
end

function S.applyhighlightalpha(value)
	S.theme.highlightAlpha = math.clamp(value or 1, 0, 1)
	for object, entries in pairs(S.__blush_highlight_alpha) do
		if not object.Parent then
			S.__blush_highlight_alpha[object] = nil
		else
			for property, base in pairs(entries) do
				object[property] = S.effectivehighlightalpha(base)
			end
		end
	end
end

function S.applyhighlight(color, alpha, animate)
	if typeof(color) == "Color3" and S.theme.highlight ~= color then
		S.theme.highlight = color
		S.applythemerole("highlight", animate == true)
		S.indexthemecolors()
	end
	if alpha ~= nil then S.applyhighlightalpha(alpha) end
	if S.highlightpicker and not S.highlightpicker.dragging and not S.highlightpicker.rainbow and not S.highlightpicker.fading then
		S.highlightpicker:Set(S.theme.highlight, S.theme.highlightAlpha, false)
	end
end

S.transparencyroles = {
	main = true,
	section = true,
	window = true,
	sidebar = true,
	input = true,
	hover = true,
	popup = true,
	notification = true,
}

S.transparencybase = setmetatable({}, {
	__mode = "k",
})

S.__blush_background_visibility = S.__blush_background_visibility or 0

function S.effectivetransparency(value, role, object, basealpha, themealpha, globalalpha, mainalpha, panel)
	basealpha = 1 - math.clamp(value or 0, 0, 1)
	panel = object and S.panelowners[object]
	if panel then return 1 - basealpha * (object == panel.root and panel.opacity or 1) end
	themealpha = math.clamp(S.theme.backgroundAlpha or 1, 0, 1)
	globalalpha = 1 - math.clamp(S.uitransparency or 0, 0, 0.90)
	mainalpha = S.mainroles and S.mainroles[role]
			and math.clamp(S.theme.mainAlpha or 1, 0, 1)
		or 1
	return 1 - basealpha * themealpha * globalalpha * mainalpha
end

function S.applyuitransparency(value)
	S.uitransparency = math.clamp((tonumber(value) or 0) / 100, 0, 0.90)

	for object, data in pairs(S.transparencybase) do
		if object and object.Parent then
			object.BackgroundTransparency = S.effectivetransparency(data.base, data.role, object)
		end
	end

	-- Global transparency is already folded into every themed surface above.
	-- Keep root CanvasGroups neutral so nested content is not faded a second time.
	if S.window and S.window.Parent then S.window.GroupTransparency = 0 end

	if S.draglayer and S.draglayer.Parent then S.draglayer.GroupTransparency = 0 end
end

function S.rawnew(class, properties, object2)
	object2 = Instance.new(class)

	for property, value in pairs(properties or {}) do
		if property ~= "Parent" then object2[property] = value end
	end

	S.panelowners[object2] = properties and S.panelowners[properties.Parent]
	object2.Parent = properties and properties.Parent
	return object2
end

function S.new(class, properties, roles, object3, backgroundrole, base)
	object3 = Instance.new(class)
	S.panelowners[object3] = properties and S.panelowners[properties.Parent]

	for property, value in pairs(properties or {}) do
		if property ~= "Parent" then object3[property] = value end
	end

	if
		(class == "TextLabel" or class == "TextButton")
		and (not properties or properties.RichText == nil)
	then
		object3.RichText = true
	end

	for property, value in pairs(properties or {}) do
		if
			property == "BackgroundColor3"
			or property == "TextColor3"
			or property == "ImageColor3"
			or property == "ScrollBarImageColor3"
			or (class == "UIStroke" and property == "Color")
		then
			S.bindtheme(object3, property, value, roles and roles[property])
			object3[property] = S.panelcolor(object3, S.objectbindings[object3] and S.objectbindings[object3][property], value)
		end
	end

	backgroundrole = properties
		and properties.BackgroundColor3
		and ((roles and roles.BackgroundColor3) or S.themerole(properties.BackgroundColor3))

	if backgroundrole and S.transparencyroles[backgroundrole] and object3:IsA("GuiObject") then
		base = properties.BackgroundTransparency

		if base == nil then base = 0 end

		S.transparencybase[object3] = {
			base = base,
			role = backgroundrole,
		}
		object3.BackgroundTransparency = S.effectivetransparency(base, backgroundrole, object3)
	end

	object3.Parent = properties and properties.Parent
	return object3
end

function S.tween(
	object,
	properties,
	info,
	raw,
	roles,
	goals,
	groupshadows,
	grouptarget,
	base,
	tweeninfo,
	animation,
	shadowanimation
)
	if not object or not object.Parent then return end

	goals = {}

	for property, value in pairs(properties) do
		if raw then
			goals[property] = value
		else
			if
				property == "BackgroundColor3"
				or property == "TextColor3"
				or property == "ImageColor3"
				or property == "ScrollBarImageColor3"
				or (object:IsA("UIStroke") and property == "Color")
			then
				S.syncbinding(object, property, value, roles and roles[property])
				value = S.panelcolor(object, S.objectbindings[object] and S.objectbindings[object][property], value)
			end

			if property == "BackgroundTransparency" and S.transparencybase[object] ~= nil then
				S.transparencybase[object].base = value
				goals[property] = S.effectivetransparency(value, S.transparencybase[object].role, object)
			elseif S.setaccentalphabase(object, property, value) then
				goals[property] = S.effectiveaccentalpha(value)
			elseif S.sethighlightalphabase(object, property, value) then
				goals[property] = S.effectivehighlightalpha(value)
			elseif S.setmainalphabase(object, property, value) then
				goals[property] = S.effectivemainalpha(value)
			elseif S.setfontalphabase(object, property, value) then
				goals[property] = S.effectivefontalpha(value)
			else
				goals[property] = value
			end
		end
	end

	groupshadows = nil

	if object:IsA("CanvasGroup") and goals.GroupTransparency ~= nil then
		grouptarget = math.clamp(goals.GroupTransparency, 0, 1)
		groupshadows = {}

		for child in pairs(S.shadowchildren[object] or {}) do
			if child.Parent then
				base = child:GetAttribute("BlushBaseTransparency")

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

	if not S.animationsenabled or S.constructing then
		for property, value in pairs(goals) do
			object[property] = value
		end

		for _, shadow in ipairs(groupshadows or {}) do
			shadow.object.Transparency = shadow.target
		end

		return nil
	end

	tweeninfo = info or S.ti
	animation = S.tweenservice:Create(object, tweeninfo, goals)

	for _, shadow in ipairs(groupshadows or {}) do
		shadowanimation =
			S.tweenservice:Create(shadow.object, tweeninfo, { Transparency = shadow.target })
		shadowanimation:Play()
	end

	animation:Play()
	return animation
end

function S.buildtheme(
	background,
	accent,
	fontcolor,
	maincolor,
	h,
	s,
	v,
	direction,
	surface,
	baseinput,
	mh,
	ms,
	mv,
	maindirection,
	mainsurface,
	luminance,
	light,
	primarytext,
	accentluminance
)
	h, s, v = background:ToHSV()
	direction = v > 0.56 and -1 or 1

	surface = function(offset, saturation)
		return Color3.fromHSV(
			h,
			math.clamp(s * (saturation or 0.72), 0, 1),
			math.clamp(v + direction * offset, 0, 1)
		)
	end

	baseinput = maincolor or surface(0.032, 0.76)
	mh, ms, mv = baseinput:ToHSV()
	maindirection = mv > 0.56 and -1 or 1

	mainsurface = function(offset, saturation)
		return Color3.fromHSV(
			mh,
			math.clamp(ms * (saturation or 0.9), 0, 1),
			math.clamp(mv + maindirection * offset, 0, 1)
		)
	end

	luminance = background.R * 0.2126 + background.G * 0.7152 + background.B * 0.0722

	light = luminance <= 0.52

	primarytext = fontcolor
		or (light and Color3.fromRGB(240, 240, 242) or Color3.fromRGB(28, 28, 31))

	accentluminance = accent.R * 0.2126 + accent.G * 0.7152 + accent.B * 0.0722

	return {
		window = background,
		sidebar = surface(-0.016, 0.72),

		-- Main color is the base for the actual interactive/UI surfaces.
		main = baseinput,
		section = mainsurface(0.020, 0.92),
		input = baseinput,
		hover = mainsurface(0.050, 0.86),
		track = mainsurface(0.105, 0.72),
		border = mainsurface(0.082, 0.68),
		scroll = mainsurface(0.090, 0.64),
		scrollTrack = mainsurface(0.030, 0.82),
		popup = mainsurface(-0.010, 0.96),
		notification = mainsurface(0.024, 0.90),

		text = primarytext,
		text2 = background:Lerp(primarytext, 0.72),
		text3 = background:Lerp(primarytext, 0.45),
		white = accent,
		black = accentluminance > 0.55 and Color3.fromRGB(14, 14, 15)
			or Color3.fromRGB(245, 245, 247),
		font = primarytext,
	}
end

function S.applytheme(
	background,
	accent,
	backgroundalpha,
	accentalpha,
	fontcolor,
	fontalpha,
	animate,
	oldbackground,
	oldaccent,
	oldfont,
	oldbackgroundalpha,
	oldaccentalpha,
	oldfontalpha,
	nexttheme,
	changedroles,
	backgroundalphachanged,
	accentalphachanged,
	fontalphachanged,
	backgroundchanged,
	accentchanged,
	fontchanged
)
	oldbackground = S.theme.window
	oldaccent = S.theme.white
	oldfont = S.theme.font
	oldbackgroundalpha = S.theme.backgroundAlpha
	oldaccentalpha = S.theme.accentAlpha
	oldfontalpha = S.theme.fontAlpha

	nexttheme = S.buildtheme(background, accent, fontcolor or S.theme.font, S.theme.main)

	changedroles = {}
	for key, value in pairs(nexttheme) do
		if S.theme[key] ~= value then
			changedroles[key] = true
			S.theme[key] = value
		end
	end

	if backgroundalpha ~= nil then S.theme.backgroundAlpha = math.clamp(backgroundalpha, 0, 1) end

	if accentalpha ~= nil then S.theme.accentAlpha = math.clamp(accentalpha, 0, 1) end

	if fontalpha ~= nil then S.theme.fontAlpha = math.clamp(fontalpha, 0, 1) end

	backgroundalphachanged = oldbackgroundalpha ~= S.theme.backgroundAlpha
	accentalphachanged = oldaccentalpha ~= S.theme.accentAlpha
	fontalphachanged = oldfontalpha ~= S.theme.fontAlpha
	backgroundchanged = oldbackground ~= S.theme.window
	accentchanged = oldaccent ~= S.theme.white
	fontchanged = oldfont ~= S.theme.font

	S.indexthemecolors()
	for role in pairs(changedroles) do
		S.applythemerole(role, animate)
	end

	if backgroundalphachanged then S.applyuitransparency(S.uitransparency * 100) end

	if accentalphachanged then S.applyaccentalpha(S.theme.accentAlpha) end

	if fontalphachanged then S.applyfontalpha(S.theme.fontAlpha) end

	if
		S.refreshcheckboxcolors
		and (
			accentchanged
			or changedroles.border
			or changedroles.input
			or changedroles.black
			or accentalphachanged
		)
	then
		S.refreshcheckboxcolors(animate == true)
	end

	if backgroundchanged and S.updatebackgroundtone then S.updatebackgroundtone() end

	if accentchanged and S.syncwindowglowcolor then S.syncwindowglowcolor(animate == true) end

	if
		S.accentpicker
		and not S.accentpicker.dragging
		and not S.accentpicker.fading
		and not S.accentpicker.rainbow
		and (accentchanged or accentalphachanged)
	then
		S.accentpicker:Set(S.theme.white, S.theme.accentAlpha, false)
	end

	if
		S.backgroundpicker
		and not S.backgroundpicker.dragging
		and not S.backgroundpicker.fading
		and not S.backgroundpicker.rainbow
		and (backgroundchanged or backgroundalphachanged)
	then
		S.backgroundpicker:Set(S.theme.window, S.theme.backgroundAlpha, false)
	end

	if
		S.fontpicker
		and not S.fontpicker.dragging
		and not S.fontpicker.fading
		and not S.fontpicker.rainbow
		and (fontchanged or fontalphachanged)
	then
		S.fontpicker:Set(S.theme.font, S.theme.fontAlpha, false)
	end
end

S.mainroles = {
	main = { 0, 1 },
	input = { 0, 1 },
	section = { 0.020, 0.92 },
	hover = { 0.050, 0.86 },
	track = { 0.105, 0.72 },
	border = { 0.082, 0.68 },
	scroll = { 0.090, 0.64 },
	scrollTrack = { 0.030, 0.82 },
	popup = { -0.010, 0.96 },
	notification = { 0.024, 0.90 },
}

function S.applymaincolor(color, animate, h, saturation, value, direction, target)
	if typeof(color) ~= "Color3" or S.theme.main == color then return end
	h, saturation, value = color:ToHSV()
	direction = value > 0.56 and -1 or 1
	for role, offset in pairs(S.mainroles) do
		target = (role == "main" or role == "input") and color
			or Color3.fromHSV(
				h,
				math.clamp(saturation * offset[2], 0, 1),
				math.clamp(value + direction * offset[1], 0, 1)
			)
		if S.theme[role] ~= target then
			S.theme[role] = target
			S.applythemerole(role, animate)
		end
	end
	S.indexthemecolors()
	if
		S.maincolorpicker
		and not S.maincolorpicker.dragging
		and not S.maincolorpicker.rainbow
		and not S.maincolorpicker.fading
	then
		S.maincolorpicker:Set(color, S.theme.mainAlpha or 1, false)
	end
end

function S.setmaincoloralpha(value)
	S.applymainalpha(value)
	if S.maincolorpicker and not S.maincolorpicker.dragging and not S.maincolorpicker.rainbow and not S.maincolorpicker.fading then
		S.maincolorpicker:Set(S.theme.main, S.theme.mainAlpha, false)
	end
end

function S.corner(object, radius)
	return S.new("UICorner", {
		Parent = object,
		CornerRadius = UDim.new(0, radius),
	})
end

function S.stroke(object, transparency, color, thickness)
	return S.new("UIStroke", {
		Parent = object,

		Color = color or S.theme.border,
		Transparency = transparency or 0,
		Thickness = thickness or 1,
	})
end

function S.padding(object, left, right, top, bottom)
	return S.new("UIPadding", {
		Parent = object,

		PaddingLeft = UDim.new(0, left or 0),
		PaddingRight = UDim.new(0, right or 0),
		PaddingTop = UDim.new(0, top or 0),
		PaddingBottom = UDim.new(0, bottom or 0),
	})
end

function S.list(object, spacing)
	return S.new("UIListLayout", {
		Parent = object,

		Padding = UDim.new(0, spacing or 0),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
end

function S.plaintext(value)
	value = tostring(value or "")
	value = string.gsub(value, "<[bB][rR]%s*/?>", "\n")
	value = string.gsub(value, "<[^>]->", "")
	value = string.gsub(value, "&nbsp;", " ")
	value = string.gsub(value, "&quot;", '"')
	value = string.gsub(value, "&#39;", "'")
	value = string.gsub(value, "&lt;", "<")
	value = string.gsub(value, "&gt;", ">")
	value = string.gsub(value, "&amp;", "&")
	value = string.gsub(value, "&#(%d+);", function(code, number)
		number = tonumber(code)

		if not number or number < 0 or number > 255 then return "" end

		return string.char(number)
	end)

	return value
end

S.textmeasurecache = {}
S.textmeasurecount = 0

function S.measuretext(value, size, face, bounds, bytext, result)
	value = S.plaintext(value)
	bytext = S.textmeasurecache[value]
	if bytext and bytext.size == size and bytext.face == face and bytext.bounds == bounds then
		return bytext.result
	end
	result = S.textservice:GetTextSize(value, size, face, bounds)
	if S.textmeasurecount >= 256 then
		table.clear(S.textmeasurecache)
		S.textmeasurecount = 0
	end
	if not bytext then
		S.textmeasurecount += 1
	end
	S.textmeasurecache[value] = { size = size, face = face, bounds = bounds, result = result }
	return result
end

function S.richrgb(textvalue, r, g, b)
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

S.__blush_rgb = S.richrgb

S.__blush_gradienttargets = setmetatable({}, { __mode = "k" })
S.__blush_gradientstates = setmetatable({}, { __mode = "k" })
S.__blush_rainbowgradients = setmetatable({}, { __mode = "k" })
S.rainbowtextconnection = nil
S.rainbowtextphase = 0
S.rainbowtextpoints = table.create(13)
S.rainbowtextsequence = ColorSequence.new({
	ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)),
	ColorSequenceKeypoint.new(0.14, Color3.fromRGB(255, 128, 0)),
	ColorSequenceKeypoint.new(0.28, Color3.fromRGB(255, 255, 0)),
	ColorSequenceKeypoint.new(0.42, Color3.fromRGB(0, 255, 0)),
	ColorSequenceKeypoint.new(0.57, Color3.fromRGB(0, 255, 255)),
	ColorSequenceKeypoint.new(0.71, Color3.fromRGB(0, 96, 255)),
	ColorSequenceKeypoint.new(0.86, Color3.fromRGB(170, 0, 255)),
	ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 0)),
})

function S.registergradienttarget(target, textobject)
	if target and textobject then S.__blush_gradienttargets[target] = textobject end

	return target
end

function S.resolvegradienttarget(target, mapped)
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

	if typeof(target) ~= "Instance" then return nil end

	if target:IsA("TextLabel") or target:IsA("TextButton") or target:IsA("TextBox") then
		return target
	end

	mapped = S.__blush_gradienttargets[target]
	if
		mapped
		and mapped.Parent
		and (mapped:IsA("TextLabel") or mapped:IsA("TextButton") or mapped:IsA("TextBox"))
	then
		return mapped
	end

	return nil
end

function S.normalizetextgradient(value, keypoints)
	if value == nil or value == false then return nil, false end

	if type(value) == "string" and string.lower(value) == "rainbow" then
		return S.rainbowtextsequence, true
	end

	if typeof(value) == "ColorSequence" then return value, false end

	if type(value) == "table" then
		if value.Rainbow == true or value.rainbow == true then
			return S.rainbowtextsequence, true
		end

		keypoints = value.Keypoints or value.keypoints or value
		if #keypoints >= 2 then return ColorSequence.new(keypoints), false end
	end

	return nil, false
end

function S.textgradientrole(textobject)
	return S.objectbindings[textobject] and S.objectbindings[textobject].TextColor3
end

function S.stoprainbowtextloop()
	if S.rainbowtextconnection and S.rainbowtextconnection.Connected then
		S.rainbowtextconnection:Disconnect()
	end
	S.rainbowtextconnection = nil
end

function S.ensurerainbowtextloop()
	if S.rainbowtextconnection and S.rainbowtextconnection.Connected then return end

	S.rainbowtextconnection = S.runservice.PreRender:Connect(
		function(dt, colors, points, position, hue, sequence)
			if next(S.__blush_rainbowgradients) == nil then
				S.stoprainbowtextloop()
				return
			end

			S.rainbowtextphase = (S.rainbowtextphase + dt * 0.30) % 1
			colors = S.rainbowtextpoints
			points = 12

			for index = 0, points do
				position = index / points
				hue = (position + S.rainbowtextphase) % 1
				colors[index + 1] = ColorSequenceKeypoint.new(position, Color3.fromHSV(hue, 1, 1))
			end

			sequence = ColorSequence.new(colors)
			for textobject, gradient in pairs(S.__blush_rainbowgradients) do
				if not textobject.Parent or not gradient.Parent then
					S.__blush_rainbowgradients[textobject] = nil
				else
					gradient.Offset = Vector2.zero
					gradient.Rotation = 0
					gradient.Color = sequence
				end
			end
		end
	)
end

function S.settextgradient(
	target,
	value,
	textobject,
	previous,
	role,
	basecolor,
	sequence,
	rainbow,
	gradient,
	state
)
	textobject = S.resolvegradienttarget(target)
	if not textobject then return false end
	if textobject == S.brand then
		S.titlegradient = value
		if S.__blush_watermark_title then S.settextgradient(S.__blush_watermark_title, value) end
	end

	previous = S.__blush_gradientstates[textobject]
	role = previous and previous.role or S.textgradientrole(textobject)
	basecolor = previous and previous.basecolor or textobject.TextColor3

	if previous then
		S.__blush_rainbowgradients[textobject] = nil
		if previous.gradient and previous.gradient.Parent then previous.gradient:Destroy() end
		S.__blush_gradientstates[textobject] = nil
	end

	sequence, rainbow = S.normalizetextgradient(value)
	if not sequence then
		if textobject.Parent then textobject.TextColor3 = role and S.theme[role] or basecolor end
		if next(S.__blush_rainbowgradients) == nil then S.stoprainbowtextloop() end
		return value == nil or value == false
	end

	gradient = S.rawnew("UIGradient", {
		Name = "BlushGradient",
		Parent = textobject,
		Color = sequence,
		Offset = Vector2.zero,
	})

	if rainbow then
		gradient.Rotation = 0
		gradient.Offset = Vector2.zero
	end

	state = {
		gradient = gradient,
		role = role,
		basecolor = basecolor,
		rainbow = rainbow,
	}

	S.__blush_gradientstates[textobject] = state
	textobject.TextColor3 = Color3.new(1, 1, 1)

	if rainbow then
		S.__blush_rainbowgradients[textobject] = gradient
		S.ensurerainbowtextloop()
	end

	return true
end

function S.settextrainbow(target, enabled)
	return S.settextgradient(target, enabled == true and "Rainbow" or nil)
end

function S.label(parentobject, value, size, face, color, object4)
	object4 = S.new("TextLabel", {
		Parent = parentobject,
		Size = size,

		BackgroundTransparency = 1,
		BorderSizePixel = 0,

		Text = value,
		TextColor3 = color or S.theme.text,

		Font = face or S.font,
		TextSize = 17,

		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
	})

	S.registergradienttarget(object4, object4)
	return object4
end

function S.image(parentobject, asset, size, color, zindex)
	return S.new("ImageLabel", {
		Parent = parentobject,

		Size = UDim2.fromOffset(size, size),

		BackgroundTransparency = 1,
		BorderSizePixel = 0,

		Image = S.librarynormalizeicon(asset) or "",
		ImageColor3 = color or S.theme.text2,

		ScaleType = Enum.ScaleType.Fit,

		ZIndex = zindex or 1,
	})
end

S.shadowchildren = setmetatable({}, { __mode = "k" })

function S.addshadow(
	parentobject,
	name,
	transparency,
	blur,
	spread,
	zindex,
	color,
	offset,
	bindcolor,
	success,
	shadow
)
	success, shadow = S.invoke(function(object5, parentgroupalpha)
		object5 = Instance.new("UIShadow")

		object5.Name = name
		object5.Color = color or S.theme.white
		object5:SetAttribute("BlushBaseTransparency", transparency)

		parentgroupalpha = 0
		if parentobject:IsA("CanvasGroup") then
			parentgroupalpha = parentobject.GroupTransparency
		end

		object5.Transparency = 1 - (1 - transparency) * (1 - parentgroupalpha)
		object5.BlurRadius = UDim.new(0, blur)
		object5.Spread = UDim2.fromOffset(spread, spread)
		object5.Offset = offset or UDim2.fromOffset(0, 0)
		object5.ZIndex = zindex or -1
		object5.Parent = parentobject
		S.shadowchildren[parentobject] = S.shadowchildren[parentobject]
			or setmetatable({}, { __mode = "k" })
		S.shadowchildren[parentobject][object5] = true

		if bindcolor ~= false and object5.Color == S.theme.white then
			S.bindtheme(object5, "Color", S.theme.white, "white")
		end

		return object5
	end)

	return success and shadow or nil
end

function S.addglow(object, preset, shadow)
	if preset ~= "active" then return nil end
	shadow = S.addshadow(object, "ActiveGlow", 0.76, 9, 1, -1, S.theme.highlight, UDim2.fromOffset(0, 0), false)
	if shadow then S.bindtheme(shadow, "Color", S.theme.highlight, "highlight") end
	return shadow
end

function S.adddepthshadow(object, preset)
	if preset == "window" then
		return S.addshadow(
			object,
			"DepthShadow",
			0.48,
			28,
			4,
			-3,
			Color3.fromRGB(0, 0, 0),
			UDim2.fromOffset(0, 8)
		)
	end

	if preset == "floating" then
		return S.addshadow(
			object,
			"DepthShadow",
			0.58,
			16,
			2,
			-2,
			Color3.fromRGB(0, 0, 0),
			UDim2.fromOffset(0, 5)
		)
	end

	if preset == "popup" then
		return S.addshadow(
			object,
			"DepthShadow",
			0.62,
			14,
			2,
			-2,
			Color3.fromRGB(0, 0, 0),
			UDim2.fromOffset(0, 4)
		)
	end

	return nil
end

function S.point(input) return Vector2.new(input.Position.X, input.Position.Y) end

function S.offsetposition(position, delta)
	return UDim2.new(
		position.X.Scale,
		position.X.Offset + delta.X,
		position.Y.Scale,
		position.Y.Offset + delta.Y
	)
end

function S.inside(object, position, p, s)
	p = object.AbsolutePosition
	s = object.AbsoluteSize

	return position.X >= p.X
		and position.Y >= p.Y
		and position.X <= p.X + s.X
		and position.Y <= p.Y + s.Y
end

function S.guivisible(object, current)
	current = object

	while current and current ~= S.gui do
		if current:IsA("GuiObject") and not current.Visible then return false end

		current = current.Parent
	end

	return current == S.gui
end

S.originalposition = UDim2.fromScale(0.5, 0.52)
S.originalwindowsize = Vector2.new(926, 676)

function S.centeredwindowposition(size, camera, viewport)
	size = size or S.originalwindowsize

	camera = workspace.CurrentCamera
	viewport = camera and camera.ViewportSize or S.gui.AbsoluteSize

	return UDim2.fromOffset(
		math.round(viewport.X * S.originalposition.X.Scale - size.X * 0.5),
		math.round(viewport.Y * S.originalposition.Y.Scale - size.Y * 0.5)
	)
end

-- window

S.shell = S.new("Frame", {
	Parent = S.gui,

	AnchorPoint = Vector2.zero,
	Position = S.centeredwindowposition(S.originalwindowsize),

	Size = UDim2.fromOffset(S.originalwindowsize.X, S.originalwindowsize.Y),

	BackgroundTransparency = 1,
	BorderSizePixel = 0,

	ZIndex = 10,
})

S.modalguard = S.new("TextButton", {
	Parent = S.gui,
	Position = UDim2.fromOffset(-100, -100),
	Size = UDim2.fromOffset(1, 1),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Text = "",
	TextTransparency = 1,
	AutoButtonColor = false,
	Active = false,
	Selectable = false,
	Modal = true,
	Visible = false,
	ZIndex = 1,
})



S.window = S.new("CanvasGroup", {
	Parent = S.shell,

	Size = UDim2.fromScale(1, 1),

	BackgroundColor3 = S.theme.window,
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ClipsDescendants = true,
	GroupTransparency = 0,

	ZIndex = 10,
}, { BackgroundColor3 = "window" })

S.windowcorner = S.corner(S.window, 12)
S.windowstroke = S.stroke(S.window, 1, S.theme.border, 1)
S.windowstroke.Enabled = false
S.windowshadow = S.adddepthshadow(S.window, "window")
S.windowglow =
	S.addshadow(S.window, "WindowGlow", 0.88, 18, 2, -2, S.theme.white, UDim2.fromOffset(0, 0))

-- Clip window effects to exterior bands so they cannot tint translucent image pixels.
S.windoweffectsbands = {}
for index = 1, 4 do
	S.windoweffectsbands[index] = S.rawnew("Frame", {
		Parent = S.shell, BackgroundTransparency = 1, BorderSizePixel = 0,
		ClipsDescendants = true, ZIndex = 9,
	})
end
function S.exteriorwindowshadow(shadow, carrier, copies, sync)
	if not shadow then return end
	carrier = S.rawnew("Frame", { Parent = S.shell, Visible = false, BackgroundTransparency = 1 })
	shadow.Parent = carrier
	copies = {}
	for index, band in ipairs(S.windoweffectsbands) do
		copies[index] = S.rawnew("Frame", { Parent = band, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 9 })
		S.corner(copies[index], S.windowcorner.CornerRadius.Offset)
		shadow:Clone().Parent = copies[index]
	end
	sync = function(property)
		for _, surface in ipairs(copies) do
			surface:FindFirstChildOfClass("UIShadow")[property] = shadow[property]
		end
	end
	for _, property in ipairs({ "Color", "Transparency", "BlurRadius", "Spread", "Offset", "Enabled" }) do
		shadow:GetPropertyChangedSignal(property):Connect(function() sync(property) end)
	end
	return copies
end
S.windowshadowcopies = S.exteriorwindowshadow(S.windowshadow)
S.windowglowcopies = S.exteriorwindowshadow(S.windowglow)
function S.layoutwindoweffects(width, height, regions, region, surface)
	width, height = S.shell.AbsoluteSize.X, S.shell.AbsoluteSize.Y
	regions = {
		{ -128, -128, width + 256, 128 }, { -128, height, width + 256, 128 },
		{ -128, 0, 128, height }, { width, 0, 128, height },
	}
	for index, band in ipairs(S.windoweffectsbands) do
		region = regions[index]
		band.Position = UDim2.fromOffset(region[1], region[2])
		band.Size = UDim2.fromOffset(region[3], region[4])
		for _, copies in ipairs({ S.windowshadowcopies or {}, S.windowglowcopies or {} }) do
			surface = copies[index]
			if surface then
				surface.Position = UDim2.fromOffset(-region[1], -region[2])
				surface.Size = UDim2.fromOffset(width, height)
				surface:FindFirstChildOfClass("UICorner").CornerRadius = S.windowcorner.CornerRadius
			end
		end
	end
end
S.shell:GetPropertyChangedSignal("AbsoluteSize"):Connect(S.layoutwindoweffects)
S.windowcorner:GetPropertyChangedSignal("CornerRadius"):Connect(S.layoutwindoweffects)
S.layoutwindoweffects()

S.windowresizeenabled = true
S.windowdragenabled = true
S.windowminimizebuttonenabled = true
S.windowminsize = Vector2.new(620, 440)
S.windowmaxsize = nil

S.windowshadowenabled = true
S.windowglowenabled = true
S.windowglowintensitymax = 300
S.windowglowsizemax = 64
S.windowglowintensity = 16
S.windowglowsize = 10
S.windowglowcolor = S.theme.white
S.windowglowalpha = 1
S.windowglowrenderalpha = 1
S.windowglowcolorpicker = nil

function S.applywindowshadow(base)
	if not S.windowshadow then return end

	base = S.windowshadowenabled and 0.40 or 1

	S.windowshadow:SetAttribute("BlushBaseTransparency", base)

	S.windowshadow.Transparency = base
end

function S.applywindowglow(strength, size, alpha, opacity, transparency)
	if not S.windowglow then return end

	strength = math.clamp(tonumber(S.windowglowintensity) or 16, 0, S.windowglowintensitymax)

	size = math.clamp(tonumber(S.windowglowsize) or 10, 0, S.windowglowsizemax)

	alpha = math.clamp(tonumber(S.windowglowrenderalpha) or S.windowglowalpha or 1, 0, 1)

	opacity = (strength / 100) * 0.58 * alpha

	transparency = 1 - math.clamp(opacity, 0, 1)

	S.windowglow:SetAttribute("BlushBaseTransparency", transparency)

	S.windowglow.Color = S.windowglowcolor

	S.windowglow.Transparency = S.windowglowenabled and transparency or 1

	S.windowglow.BlurRadius = UDim.new(0, size)

	S.windowglow.Spread = UDim2.fromOffset(size >= 14 and 1 or 0, size >= 14 and 1 or 0)
end

function S.syncwindowglowcolor(animate)
	S.windowglowcolor = S.theme.white

	if S.windowglowcolorpicker then
		S.windowglowcolorpicker:Set(S.windowglowcolor, S.windowglowalpha, false)

		S.windowglowrenderalpha = S.windowglowcolorpicker:currentalpha()
	else
		S.windowglowrenderalpha = S.windowglowalpha
	end

	if S.windowglow and S.windowglow.Parent then
		if animate == true and S.animationsenabled then
			S.tween(S.windowglow, { Color = S.windowglowcolor }, S.quart24)
		else
			S.windowglow.Color = S.windowglowcolor
		end
	end

	S.applywindowglow()
end

S.applywindowshadow()
S.applywindowglow()

S.backgroundholder = S.rawnew("Frame", {
	Parent = S.window,
	Position = UDim2.fromOffset(0, 0),
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ClipsDescendants = true,
	Active = false,
	ZIndex = 9,
})

S.backgroundimage = S.rawnew("ImageLabel", {
	Parent = S.backgroundholder,
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
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

S.backgroundlayers = { S.backgroundimage }
S.backgroundresolvedasset = nil
S.backgroundeditable = nil
S.backgroundblureditable = nil
S.backgroundblurbaseasset = nil
S.backgroundblurbasepixels = nil
S.backgroundblurbasewidth = 0
S.backgroundblurbaseheight = 0
S.backgroundblurlastsignature = nil
S.backgroundblurtoken = 0
S.backgroundblurdebounce = 0
S.backgroundblurtask = nil
S.backgroundsectionframes = setmetatable({}, { __mode = "k" })

S.backgroundblurdisplay = S.rawnew("ImageLabel", {
	Parent = S.backgroundholder,
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
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

function S.destroybackgroundeditable()
	S.backgroundblurtoken += 1
	S.backgroundsourcegeneration = (S.backgroundsourcegeneration or 0) + 1
	S.backgroundblurloading = nil
	if S.stopbackgroundblurjob then S.stopbackgroundblurjob() end

	if S.backgroundblurtask and coroutine.status(S.backgroundblurtask) == "suspended" then
		pcall(task.cancel, S.backgroundblurtask)
	end
	S.backgroundblurtask = nil

	if S.backgroundeditable then
		S.backgroundeditable:Destroy()
		S.backgroundeditable = nil
	end

	S.backgroundblurbaseasset = nil
	S.backgroundblurbasepixels = nil
	S.backgroundblurbasewidth = 0
	S.backgroundblurbaseheight = 0
	S.backgroundblurlastsignature = nil

	if S.backgroundblureditable then
		S.backgroundblureditable:Destroy()
		S.backgroundblureditable = nil
	end

	if S.backgroundblurdisplay and S.backgroundblurdisplay.Parent then
		S.backgroundblurdisplay.Visible = false
		S.backgroundblurdisplay.ImageTransparency = 1
		S.backgroundblurdisplay.ImageContent = Content.none
	end
end

S.backgroundtoneoverlay = S.rawnew("Frame", {
	Parent = S.backgroundholder,
	Position = UDim2.fromOffset(0, 0),
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.new(1, 1, 1),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Visible = false,
	Active = false,
	ZIndex = 9,
})

S.rawnew("UIGradient", {
	Parent = S.backgroundtoneoverlay,
	Rotation = 90,
	Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.06),
		NumberSequenceKeypoint.new(0.55, 0.22),
		NumberSequenceKeypoint.new(1, 0.08),
	}),
})

S.backgroundexcludesidebar = false
S.autobackgroundcolors = false
S.topnavigationenabled = false

function S.updatebackgroundbounds(width)
	if not S.backgroundholder or not S.backgroundholder.Parent then return end
	width = S.backgroundexcludesidebar and math.max(0, (S.sidebarwidth or 215) - 1) or 0
	S.backgroundholder.Position = UDim2.fromOffset(width, 0)
	S.backgroundholder.Size = UDim2.new(1, -width, 1, 0)
end

function S.updatebackgroundtone(visible, luminance, lighttheme)
	if not S.backgroundtoneoverlay or not S.backgroundtoneoverlay.Parent then return end

	visible = S.backgroundimagesource ~= nil
		and S.backgroundimagesource ~= ""
		and S.backgroundresolvedasset ~= nil

	if not visible then
		S.backgroundtoneoverlay.Visible = false
		S.backgroundtoneoverlay.BackgroundTransparency = 1
		return
	end

	luminance = S.theme.window.R * 0.2126 + S.theme.window.G * 0.7152 + S.theme.window.B * 0.0722
	lighttheme = luminance >= 0.62

	-- Do not add contrast on top of the configured image opacity.
	S.backgroundtoneoverlay.Visible = false
	S.backgroundtoneoverlay.BackgroundTransparency = 1

	if S.updatebackgroundsurfaces then S.updatebackgroundsurfaces() end
end

function S.setbackgroundexcludesidebar(value)
	S.backgroundexcludesidebar = value == true
	S.updatebackgroundbounds()
	if S.updatebackgroundsurfaces then S.updatebackgroundsurfaces() end
end

S.reopengui = Instance.new("ScreenGui")
S.reopengui.Name = "blush_reopen"
S.reopengui.IgnoreGuiInset = true
S.reopengui.ResetOnSpawn = false
S.reopengui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
S.reopengui.DisplayOrder = 1001
S.reopengui.Enabled = false
S.reopengui.Parent = S.parent

S.reopenbutton = S.new("TextButton", {
	Parent = S.reopengui,
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 12),
	Size = UDim2.fromOffset(112, 34),
	BackgroundColor3 = S.theme.window,
	BackgroundTransparency = 0.04,
	BorderSizePixel = 0,
	Text = "",
	AutoButtonColor = false,
	ZIndex = 10,
}, { BackgroundColor3 = "window" })
S.corner(S.reopenbutton, 9)
S.reopenstroke = S.stroke(S.reopenbutton, 0.62, S.theme.border, 0.6)
S.reopenshadow = S.adddepthshadow(S.reopenbutton, "floating")
S.__blush_reopenanimations = {}
S.__blush_reopen_fading = false

S.reopenlabel = S.label(S.reopenbutton, "blush.", UDim2.new(1, -24, 1, 0), S.medium, S.theme.text)
S.reopenlabel.Position = UDim2.fromOffset(12, 0)
S.reopenlabel.TextSize = 15
S.reopenlabel.TextXAlignment = Enum.TextXAlignment.Center
S.reopenlabel.ZIndex = 11

function S.updatereopenlayout(bounds, width, height)
	if not S.reopenbutton or not S.reopenbutton.Parent then return end

	bounds = S.measuretext(
		S.reopenlabel.Text,
		S.reopenlabel.TextSize,
		S.reopenlabel.Font,
		Vector2.new(100000, 34)
	)
	width = math.max(44, math.ceil(bounds.X) + 24)
	height = 34

	S.reopenbutton.Size = UDim2.fromOffset(width, height)
	S.reopenlabel.Position = UDim2.fromOffset(12, 0)
	S.reopenlabel.Size = UDim2.new(1, -24, 1, 0)
end

S.connect(S.reopenlabel:GetPropertyChangedSignal("Text"), S.updatereopenlayout)
S.connect(S.reopenlabel:GetPropertyChangedSignal("TextSize"), S.updatereopenlayout)
S.connect(S.reopenlabel:GetPropertyChangedSignal("Font"), S.updatereopenlayout)
S.updatereopenlayout()

S.reopenarrow = S.image(S.reopenbutton, S.icons.down, 13, S.theme.text3, 11)
S.reopenarrow.AnchorPoint = Vector2.new(1, 0.5)
S.reopenarrow.Position = UDim2.new(1, -10, 0.5, 0)
S.reopenarrow.Rotation = 180
S.reopenarrow.Visible = false

S.reopenbutton.MouseEnter:Connect(function()
	if S.__blush_reopen_fading then return end

	S.tween(S.reopenlabel, { TextColor3 = S.theme.white }, S.hoverti, nil, { TextColor3 = "white" })
end)

S.reopenbutton.MouseLeave:Connect(function()
	if S.__blush_reopen_fading then return end

	S.tween(S.reopenlabel, { TextColor3 = S.theme.text }, S.hoverti, nil, { TextColor3 = "text" })
end)

S.reopenbutton.Activated:Connect(function() S.requestvisibilitytoggle() end)

S.sidebarwidth = 215
S.sidebarcompactthreshold = 118
S.sidebarminwidth = 68
S.sidebarmaxwidth = 300
S.sidebarresize = nil
S.sidebarresizelasttap = 0
S.sidebarcompact = false
S.__blush_nextwindowresize = 0
S.__blush_nextsidebarresize = 0

S.sidebar = S.new("Frame", {
	Parent = S.window,

	Size = UDim2.new(0, S.sidebarwidth, 1, 0),

	BackgroundColor3 = S.theme.sidebar,
	BorderSizePixel = 0,

	ZIndex = 10,
}, { BackgroundColor3 = "sidebar" })

S.main = S.new("Frame", {
	Parent = S.window,

	Position = UDim2.fromOffset(S.sidebarwidth - 1, 0),
	Size = UDim2.new(1, -(S.sidebarwidth - 1), 1, 0),

	BackgroundColor3 = S.theme.window,
	BorderSizePixel = 0,

	ZIndex = 10,
}, { BackgroundColor3 = "window" })

function S.updatebackgroundsurfaces(
	visible,
	luminance,
	lighttheme,
	wallpaperbase,
	mainbase,
	sidebarbase,
	sectionbase,
	maindata,
	sidebardata,
	base,
	data
)
	if not S.main or not S.main.Parent or not S.sidebar or not S.sidebar.Parent then return end

	visible = S.backgroundimagesource ~= nil
		and S.backgroundimagesource ~= ""
		and S.backgroundresolvedasset ~= nil

	luminance = S.theme.window.R * 0.2126 + S.theme.window.G * 0.7152 + S.theme.window.B * 0.0722
	lighttheme = luminance >= 0.62

	-- Surface transparency follows the actual image visibility/opacity.
	wallpaperbase = visible
			and (lighttheme and 0.68 or 0.74) * math.clamp(S.__blush_background_visibility or 0, 0, 1)
		or 0
	mainbase = wallpaperbase
	sidebarbase = visible and not S.backgroundexcludesidebar and wallpaperbase or 0
	sectionbase = 0

	maindata = S.transparencybase[S.main]
	if maindata then
		maindata.base = mainbase
		S.main.BackgroundTransparency = S.effectivetransparency(mainbase, maindata.role, S.main)
	else
		S.main.BackgroundTransparency = mainbase
	end

	sidebardata = S.transparencybase[S.sidebar]
	if sidebardata then
		sidebardata.base = sidebarbase
		S.sidebar.BackgroundTransparency = S.effectivetransparency(sidebarbase, sidebardata.role, S.sidebar)
	else
		S.sidebar.BackgroundTransparency = sidebarbase
	end

	for frame in pairs(S.backgroundsectionframes) do
		if frame and frame.Parent then
			data = S.transparencybase[frame]
			if data then frame.BackgroundTransparency = S.effectivetransparency(data.base, data.role, frame) end
		else
			S.backgroundsectionframes[frame] = nil
		end
	end
end

S.sidebardivider = S.new("Frame", {
	Parent = S.window,

	Position = UDim2.fromOffset(S.sidebarwidth - 1, 0),
	Size = UDim2.new(0, 1, 1, 0),

	BackgroundColor3 = S.theme.border,
	BackgroundTransparency = 0.36,

	BorderSizePixel = 0,

	ZIndex = 12,
}, { BackgroundColor3 = "border" })

-- resize

S.resizehandlesize = 28
S.windowresize = nil
S.lastresizetap = 0

S.resizehandle = S.new("TextButton", {
	Parent = S.window,
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, 0, 1, -1),
	Size = UDim2.fromOffset(S.resizehandlesize, S.resizehandlesize),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Text = "",
	AutoButtonColor = false,
	Active = true,
	ZIndex = 80,
})

S.resizeicon = S.image(S.resizehandle, S.icons.resize, 14, S.theme.text3, 81)
S.resizeicon.AnchorPoint = Vector2.new(0.5, 0.5)
S.resizeicon.Position = UDim2.fromScale(0.62, 0.62)
S.resizeicon.Rotation = -45
S.resizeicon.ImageTransparency = 0.42
S.addshadow(
	S.resizeicon,
	"ResizeGlow",
	0.982,
	9,
	0,
	-1,
	S.theme.white,
	UDim2.fromOffset(0, 0),
	true
)

S.resizehandle.MouseEnter:Connect(
	function()
		S.tween(S.resizeicon, {
			ImageColor3 = S.theme.text,
			ImageTransparency = 0.05,
		}, S.hoverti, nil, { ImageColor3 = "text" })
	end
)

S.resizehandle.MouseLeave:Connect(
	function()
		S.tween(S.resizeicon, {
			ImageColor3 = S.theme.text3,
			ImageTransparency = 0.42,
		}, S.hoverti, nil, { ImageColor3 = "text3" })
	end
)

-- watermark

S.watermark = S.new("Frame", {
	Parent = S.watermarkgui,

	AnchorPoint = Vector2.new(1, 0),

	Position = UDim2.new(1, -18, 0, 18),

	Size = UDim2.fromOffset(140, 38),

	BackgroundColor3 = S.theme.popup,

	BorderSizePixel = 0,

	Active = true,
	Visible = true,

	ZIndex = 100,
}, { BackgroundColor3 = "popup" })

S.registerpanel(S.watermark, "Watermark")
S.watermarkshown = true
S.watermarkfadetoken = 0
S.watermarkfadeanimations = {}
S.watermarkstatsconnection = nil

S.corner(S.watermark, 8)
S.watermarkshadow = S.adddepthshadow(S.watermark, "floating")
S.watermarkfadeparts = {
	{ S.watermark, "BackgroundTransparency", 0, "background" },
}

if S.watermarkshadow then
	S.watermarkfadeparts[#S.watermarkfadeparts + 1] = {
		S.watermarkshadow,
		"Transparency",
		S.watermarkshadow:GetAttribute("BlushBaseTransparency") or S.watermarkshadow.Transparency,
		"direct",
	}
end

S.watermarkcontent = S.new("Frame", {
	Parent = S.watermark,

	Position = UDim2.fromOffset(10, 0),

	Size = UDim2.new(1, -20, 1, 0),

	BackgroundTransparency = 1,

	ZIndex = 101,
})

S.watermarklayout = S.new("UIListLayout", {
	Parent = S.watermarkcontent,

	FillDirection = Enum.FillDirection.Horizontal,

	HorizontalAlignment = Enum.HorizontalAlignment.Center,

	VerticalAlignment = Enum.VerticalAlignment.Center,

	Padding = UDim.new(0, 8),

	SortOrder = Enum.SortOrder.LayoutOrder,
})

S.watermarkorder = 0

function S.setwatermarkvisible(
	value,
	animate,
	changed,
	token,
	targetalpha,
	primary,
	object6,
	animation2,
	finish
)
	value = value == true
	changed = S.watermarkshown ~= value
	S.watermarkshown = value
	S.watermark.Active = value

	if S.setwatermarkstatsactive then S.setwatermarkstatsactive(value) end

	S.watermarkfadetoken += 1
	token = S.watermarkfadetoken

	for _, animation in ipairs(S.watermarkfadeanimations) do
		animation:Cancel()
	end
	table.clear(S.watermarkfadeanimations)

	if value then S.watermark.Visible = true end

	targetalpha = function(part)
		if not value then return 1 end

		if part[4] == "background" then
			return S.effectivetransparency(part[3], "popup", part[1])
		elseif part[4] == "font" then
			return S.effectivefontalpha(part[3])
		end

		return part[3]
	end

	if not animate or not S.animationsenabled or not changed then
		for _, part in ipairs(S.watermarkfadeparts) do
			if part[1] and part[1].Parent then part[1][part[2]] = targetalpha(part) end
		end
		S.watermark.Visible = value
		return
	end

	primary = nil
	for _, part in ipairs(S.watermarkfadeparts) do
		object6 = part[1]
		if object6 and object6.Parent then
			animation2 = S.tween(object6, { [part[2]] = targetalpha(part) }, S.hoverti, true)
			if animation2 then
				S.watermarkfadeanimations[#S.watermarkfadeanimations + 1] = animation2
				primary = primary or animation2
			end
		end
	end

	finish = function()
		if token ~= S.watermarkfadetoken then return end
		table.clear(S.watermarkfadeanimations)
		if not S.watermarkshown then S.watermark.Visible = false end
	end

	if primary then
		primary.Completed:Connect(finish)
	else
		finish()
	end
end

function S.watermarktext(value, strong, width, object7)
	S.watermarkorder += 1

	object7 = S.label(
		S.watermarkcontent,
		value,
		UDim2.fromOffset(width, 38),
		strong and S.bold or S.font,
		strong and S.theme.text or S.theme.text3
	)

	object7.LayoutOrder = S.watermarkorder

	object7.TextSize = strong and 16 or 15

	object7.TextXAlignment = Enum.TextXAlignment.Center

	object7.TextTruncate = Enum.TextTruncate.AtEnd

	object7.ZIndex = 102
	S.watermarkfadeparts[#S.watermarkfadeparts + 1] = {
		object7,
		"TextTransparency",
		0,
		"font",
	}

	return object7
end

function S.watermarkdivider(object8)
	S.watermarkorder += 1

	object8 = S.new("Frame", {
		Parent = S.watermarkcontent,

		LayoutOrder = S.watermarkorder,

		Size = UDim2.fromOffset(1, 15),

		BackgroundColor3 = S.theme.border,

		BackgroundTransparency = 0.16,

		BorderSizePixel = 0,

		ZIndex = 102,
	}, { BackgroundColor3 = "border" })

	S.watermarkfadeparts[#S.watermarkfadeparts + 1] = {
		object8,
		"BackgroundTransparency",
		0.16,
		"direct",
	}

	return object8
end

S.watermarkconfig = {
	Player = true,
	FPS = true,
	Ping = true,
	Time = true,
	PlayerMode = "Display",
}

S.__blush_watermark_title = S.watermarktext("blush.", true, 48)

S.__blush_watermark_divider_player = S.watermarkdivider()
S.__blush_watermark_player = S.watermarktext(S.player.DisplayName, false, 64)

S.__blush_watermark_divider_fps = S.watermarkdivider()
S.__blush_watermark_fps = S.watermarktext("0 fps", false, 48)

S.__blush_watermark_divider_ping = S.watermarkdivider()
S.__blush_watermark_ping = S.watermarktext("0 ms", false, 48)

S.__blush_watermark_divider_time = S.watermarkdivider()
S.__blush_watermark_time = S.watermarktext(os.date("%H:%M"), false, 42)
S.watermarkgamename = game.Name ~= "" and game.Name or "Game"
S.__blush_watermark_divider_game = S.watermarkdivider()
S.__blush_watermark_game = S.watermarktext(S.watermarkgamename, false, 100)

function S.watermarkplayertext()
	if S.watermarkconfig.PlayerMode == "Username" then
		return S.player.Name
	elseif S.watermarkconfig.PlayerMode == "Both" then
		return S.player.DisplayName .. " @" .. S.player.Name
	end

	return S.player.DisplayName
end

function S.normalizewatermarkplayermode(value)
	value = tostring(value or "Display")

	if value == "DisplayName" or value == "Display name" then value = "Display" end

	if value ~= "Display" and value ~= "Username" and value ~= "Both" then value = "Display" end

	return value
end

function S.resizewatermarktext(object, value, strong, size, fontface, bounds)
	if not object or not object.Parent then return end

	value = tostring(value or "")

	size = strong and 16 or 15
	fontface = strong and S.bold or S.font

	bounds = S.measuretext(value, size, fontface, Vector2.new(4096, 38))

	object.Text = value
	object.TextTruncate = Enum.TextTruncate.None
	object.Size = UDim2.fromOffset(math.max(strong and 48 or 36, math.ceil(bounds.X) + 2), 38)
end

function S.updatewatermarksize(width)
	if not S.watermark or not S.watermark.Parent or not S.watermarklayout then return end

	width = math.ceil(S.watermarklayout.AbsoluteContentSize.X) + 20

	S.watermark.Size = UDim2.fromOffset(math.max(84, width), 38)
end

S.connect(S.watermarklayout:GetPropertyChangedSignal("AbsoluteContentSize"), S.updatewatermarksize)

function S.updatewatermarklayout(playerenabled, fpsenabled, pingenabled, timeenabled)
	playerenabled = S.watermarkconfig.Player == true

	fpsenabled = S.watermarkconfig.FPS == true

	pingenabled = S.watermarkconfig.Ping == true

	timeenabled = S.watermarkconfig.Time == true

	S.__blush_watermark_player.Visible = playerenabled

	S.__blush_watermark_fps.Visible = fpsenabled

	S.__blush_watermark_ping.Visible = pingenabled

	S.__blush_watermark_time.Visible = timeenabled
	S.__blush_watermark_game.Visible = S.watermarkconfig.Game == true
	S.__blush_watermark_divider_game.Visible = S.watermarkconfig.Game == true
	S.resizewatermarktext(S.__blush_watermark_game, S.watermarkgamename, false)

	S.__blush_watermark_divider_player.Visible = playerenabled

	S.__blush_watermark_divider_fps.Visible = fpsenabled

	S.__blush_watermark_divider_ping.Visible = pingenabled

	S.__blush_watermark_divider_time.Visible = timeenabled

	S.resizewatermarktext(S.__blush_watermark_player, S.watermarkplayertext(), false)

	S.updatewatermarksize()
end

function S.setwatermarktitle(value)
	value = tostring(value or "blush.")

	S.resizewatermarktext(S.__blush_watermark_title, value, true)

	S.updatewatermarksize()
end

S.updatewatermarklayout()

task.spawn(function(ok, info)
	ok, info = pcall(function() return game:GetService("MarketplaceService"):GetProductInfoAsync(game.PlaceId) end)
	if ok and info and info.Name then
		S.watermarkgamename = tostring(info.Name)
		if S.__blush_watermark_game.Parent then S.updatewatermarklayout() end
	end
end)

S.__blush_watermark_frames = 0
S.__blush_watermark_elapsed = 0
S.__blush_last_ping = 0

function S.calculatewatermarkping(ok, value)
	ok, value = S.invoke(function(network, serverstats, dataping, measured)
		network = S.stats:FindFirstChild("Network")
		serverstats = network and network:FindFirstChild("ServerStatsItem")
		dataping = serverstats and serverstats:FindFirstChild("Data Ping")

		if dataping then
			measured = dataping:GetValue()
			if type(measured) == "number" and measured >= 0 then return measured end
		end

		return S.player:GetNetworkPing() * 1000
	end)

	if not ok or type(value) ~= "number" then return S.__blush_last_ping or 0 end

	value = math.max(0, value)
	S.__blush_last_ping = value
	return value
end

function S.updatewatermarkstats(dt, elapsed, frames, fps, ping)
	S.__blush_watermark_frames += 1
	S.__blush_watermark_elapsed += dt

	if S.__blush_watermark_elapsed < 1 then return end

	elapsed = math.max(S.__blush_watermark_elapsed, 0.001)
	frames = math.max(S.__blush_watermark_frames, 1)
	fps = math.floor(frames / elapsed + 0.5)
	ping = math.floor(S.calculatewatermarkping() + 0.5)

	if S.__blush_watermark_fps and S.__blush_watermark_fps.Parent then
		S.resizewatermarktext(S.__blush_watermark_fps, tostring(fps) .. " fps", false)
	end

	if S.__blush_watermark_ping and S.__blush_watermark_ping.Parent then
		S.resizewatermarktext(S.__blush_watermark_ping, tostring(ping) .. " ms", false)
	end

	if S.__blush_watermark_time and S.__blush_watermark_time.Parent then
		S.resizewatermarktext(S.__blush_watermark_time, os.date("%H:%M"), false)
	end

	if S.__blush_watermark_player and S.__blush_watermark_player.Parent then
		S.resizewatermarktext(S.__blush_watermark_player, S.watermarkplayertext(), false)
	end

	S.updatewatermarksize()
	S.__blush_watermark_frames = 0
	S.__blush_watermark_elapsed = 0
end

function S.setwatermarkstatsactive(value)
	if value then
		if not S.watermarkstatsconnection or not S.watermarkstatsconnection.Connected then
			S.watermarkstatsconnection = S.runservice.PreRender:Connect(S.updatewatermarkstats)
		end
		return
	end

	if S.watermarkstatsconnection and S.watermarkstatsconnection.Connected then
		S.watermarkstatsconnection:Disconnect()
	end

	S.watermarkstatsconnection = nil
	S.__blush_watermark_frames = 0
	S.__blush_watermark_elapsed = 0
end

S.setwatermarkstatsactive(S.watermarkshown)
S.calculatewatermarkping()

S.watermarkdragarea = S.new("TextButton", {
	Parent = S.watermark,

	Size = UDim2.fromScale(1, 1),

	BackgroundTransparency = 1,
	BorderSizePixel = 0,

	Text = "",
	AutoButtonColor = false,

	ZIndex = 110,
})

-- sidebar

S.avat = S.new("ImageLabel", {
	Parent = S.sidebar,

	AnchorPoint = Vector2.new(0.5, 0.5),

	Position = UDim2.fromOffset(39, 45),

	Size = UDim2.fromOffset(30, 30),

	BackgroundTransparency = 1,
	BorderSizePixel = 0,

	Image = S.icons.sliders,
	ImageColor3 = S.theme.text2,
	ScaleType = Enum.ScaleType.Fit,

	ZIndex = 14,
}, { ImageColor3 = "text2" })

S.logocoloroverride = nil

S.brand = S.label(S.sidebar, "blush.", UDim2.fromOffset(125, 23), S.bold)

S.brand.Position = UDim2.fromOffset(72, 23)

S.brand.TextSize = 21
S.brand.ZIndex = 14

S.subtitle = S.label(S.sidebar, "v1.0.0", UDim2.fromOffset(48, 18), S.font, S.theme.text3)

S.subtitle.Position = UDim2.fromOffset(72, 48)

S.subtitle.TextSize = 15
S.subtitle.ZIndex = 14

S.subtitledivider = S.new("Frame", {
	Parent = S.sidebar,

	Position = UDim2.fromOffset(124, 51),

	Size = UDim2.fromOffset(1, 12),

	BackgroundColor3 = S.theme.border,

	BackgroundTransparency = 0.18,

	BorderSizePixel = 0,
	ZIndex = 14,
}, { BackgroundColor3 = "border" })

S.username = S.label(S.sidebar, S.player.Name, UDim2.fromOffset(72, 18), S.font, S.theme.text3)

S.username.Position = UDim2.fromOffset(132, 48)

S.username.TextSize = 15
S.username.TextTruncate = Enum.TextTruncate.AtEnd
S.username.ZIndex = 14

function S.updatebrandlayout(
	width,
	hasicon,
	iconwidth,
	icongap,
	maxtextwidth,
	brandwidth,
	versionwidth,
	usernamewidth,
	hasversion,
	hasusername,
	dividerwidth,
	metadatawidth,
	textblockwidth,
	groupwidth,
	startx,
	textleft,
	brandx,
	metadatax,
	usernamex
)
	if not S.sidebar or not S.sidebar.Parent then return end

	width = math.max(1, S.sidebar.AbsoluteSize.X)
	if S.sidebarcompact then
		if S.avat.Visible and S.avat.Image ~= "" then
			S.avat.Position = UDim2.fromOffset(math.floor(width * 0.5) + 1, 45)
		end
		return
	end
	hasicon = S.avat.Visible and S.avat.Image ~= ""
	iconwidth = hasicon and math.max(28, S.avat.Size.X.Offset) or 0
	icongap = hasicon and 10 or 0
	maxtextwidth = math.max(40, width - iconwidth - icongap - 20)

	brandwidth = S.brand.Visible
			and math.min(
				math.ceil(
					S.measuretext(
						S.brand.Text,
						S.brand.TextSize,
						S.brand.Font,
						Vector2.new(100000, 23)
					).X
				),
				maxtextwidth
			)
		or 0
	versionwidth = S.subtitle.Visible
			and S.subtitle.Text ~= ""
			and math.ceil(
				S.measuretext(
					S.subtitle.Text,
					S.subtitle.TextSize,
					S.subtitle.Font,
					Vector2.new(100000, 18)
				).X
			)
		or 0
	usernamewidth = S.username.Visible
			and S.username.Text ~= ""
			and math.ceil(
				S.measuretext(
					S.username.Text,
					S.username.TextSize,
					S.username.Font,
					Vector2.new(100000, 18)
				).X
			)
		or 0

	hasversion = versionwidth > 0
	hasusername = usernamewidth > 0
	dividerwidth = hasversion and hasusername and 17 or 0
	metadatawidth = math.min(versionwidth + dividerwidth + usernamewidth, maxtextwidth)
	textblockwidth = math.max(brandwidth, metadatawidth)
	groupwidth = iconwidth + icongap + textblockwidth
	startx = math.max(6, math.floor((width - groupwidth) * 0.5 + 0.5))
	textleft = startx + iconwidth + icongap

	if hasicon then
		S.avat.Position = UDim2.fromOffset(startx + iconwidth * 0.5, (23 + 48 + 18) * 0.5)
	end

	-- Left-align title and subtitle block to the widest rendered line.
	brandx = textleft
	S.brand.Position = UDim2.fromOffset(brandx, 23)
	S.brand.Size = UDim2.fromOffset(math.max(1, brandwidth), 23)

	metadatax = textleft
	S.subtitle.Position = UDim2.fromOffset(metadatax, 48)
	S.subtitle.Size = UDim2.fromOffset(math.min(versionwidth, maxtextwidth), 18)

	usernamex = metadatax + math.min(versionwidth, maxtextwidth)
	S.subtitledivider.Visible = hasversion and hasusername
	if S.subtitledivider.Visible then
		S.subtitledivider.Position = UDim2.fromOffset(usernamex + 8, 51)
		usernamex += 17
	end

	S.username.Position = UDim2.fromOffset(usernamex, 48)
	S.username.Size = UDim2.fromOffset(
		math.max(0, math.min(usernamewidth, textleft + textblockwidth - usernamex)),
		18
	)
end

for _, object in ipairs({ S.brand, S.subtitle, S.username }) do
	S.connect(object:GetPropertyChangedSignal("Text"), S.updatebrandlayout)
	S.connect(object:GetPropertyChangedSignal("TextSize"), S.updatebrandlayout)
	S.connect(object:GetPropertyChangedSignal("Font"), S.updatebrandlayout)
	S.connect(object:GetPropertyChangedSignal("Visible"), S.updatebrandlayout)
end
S.connect(S.sidebar:GetPropertyChangedSignal("AbsoluteSize"), S.updatebrandlayout)
S.connect(S.avat:GetPropertyChangedSignal("Image"), S.updatebrandlayout)
S.connect(S.avat:GetPropertyChangedSignal("Visible"), S.updatebrandlayout)
S.updatebrandlayout()

S.sideheaderdrag = S.new("TextButton", {
	Parent = S.sidebar,

	Position = UDim2.fromOffset(0, 0),

	Size = UDim2.new(1, 0, 0, 75),

	BackgroundTransparency = 1,
	BorderSizePixel = 0,

	Text = "",
	AutoButtonColor = false,

	ZIndex = 13,
})

S.category = S.new("TextButton", {
	Parent = S.sidebar,
	Position = UDim2.fromOffset(14, 92),
	Size = UDim2.new(1, -28, 0, 28),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Text = "",
	AutoButtonColor = false,
	Visible = false,
	ZIndex = 13,
})

S.categorytext = S.label(S.category, "Main", UDim2.new(1, -30, 1, 0), S.medium, S.theme.text3)
S.categorytext.Position = UDim2.fromOffset(8, 0)
S.categorytext.TextSize = 14
S.categorytext.ZIndex = 14

S.categoryarrow = S.image(S.category, S.icons.down, 11, S.theme.text3, 14)
S.categoryarrow.AnchorPoint = Vector2.new(1, 0.5)
S.categoryarrow.Position = UDim2.new(1, -7, 0.5, 0)
S.categoryarrow.ImageTransparency = 0.18

S.nav = S.new("ScrollingFrame", {
	Parent = S.sidebar,
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

S.list(S.nav, 3)
S.new("UIPadding", {
	Parent = S.nav,
	PaddingBottom = UDim.new(0, 10),
})

S.maingroup = S.new("Frame", {
	Parent = S.nav,
	Size = UDim2.new(1, 0, 0, 0),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ClipsDescendants = true,
	LayoutOrder = 1,
	ZIndex = 12,
})

S.maincontent = S.new("Frame", {
	Parent = S.maingroup,
	Size = UDim2.new(1, 0, 0, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ZIndex = 12,
})

S.maincontentlayout = S.list(S.maincontent, 3)
S.maincategorycollapsed = false

-- main header

S.header = S.new("Frame", {
	Parent = S.main,

	Size = UDim2.new(1, 0, 0, 62),

	BackgroundTransparency = 1,

	Active = true,

	ZIndex = 12,
})

S.breadcrumb = S.new("Frame", {
	Parent = S.header,

	AnchorPoint = Vector2.new(0, 0.5),

	Position = UDim2.fromOffset(21, 31),

	Size = UDim2.new(1, -187, 0, 28),

	BackgroundTransparency = 1,

	ZIndex = 14,
})

S.new("UIListLayout", {
	Parent = S.breadcrumb,

	FillDirection = Enum.FillDirection.Horizontal,

	VerticalAlignment = Enum.VerticalAlignment.Center,

	Padding = UDim.new(0, 5),

	SortOrder = Enum.SortOrder.LayoutOrder,
})

S.titleprimary = S.label(S.breadcrumb, "Combat", UDim2.fromOffset(0, 28), S.bold)

S.titleprimary.LayoutOrder = 1

S.titleprimary.TextSize = 20
S.titleprimary.ZIndex = 14

S.arrowholder = S.new("Frame", {
	Parent = S.breadcrumb,

	Size = UDim2.fromOffset(14, 28),

	BackgroundTransparency = 1,
	BorderSizePixel = 0,

	LayoutOrder = 2,
	ZIndex = 14,
})

S.breadcrumbarrow = S.image(S.arrowholder, S.icons.right, 14, S.theme.text3, 14)

S.breadcrumbarrow.AnchorPoint = Vector2.new(0.5, 0.5)

S.breadcrumbarrow.Position = UDim2.new(0.5, 0, 0.5, 1)

S.titlesecondary = S.label(S.breadcrumb, "Main", UDim2.fromOffset(0, 28), S.medium, S.theme.text3)

S.titlesecondary.LayoutOrder = 3

S.titlesecondary.TextSize = 18
S.titlesecondary.ZIndex = 14

S.closebutton = S.new("TextButton", {
	Parent = S.header,
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -14, 0.5, 0),
	Size = UDim2.fromOffset(34, 34),
	BackgroundColor3 = S.theme.hover,
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Text = "",
	AutoButtonColor = false,
	Active = false,
	Visible = false,
	ZIndex = 16,
}, { BackgroundColor3 = "hover" })
S.corner(S.closebutton, 7)

S.closeline1 = S.new("Frame", {
	Parent = S.closebutton,
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(21, 2),
	Rotation = 45,
	BackgroundColor3 = S.theme.text3,
	BackgroundTransparency = 0.08,
	BorderSizePixel = 0,
	ZIndex = 17,
}, { BackgroundColor3 = "text3" })
S.corner(S.closeline1, 999)

S.closeline2 = S.new("Frame", {
	Parent = S.closebutton,
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(21, 2),
	Rotation = -45,
	BackgroundColor3 = S.theme.text3,
	BackgroundTransparency = 0.08,
	BorderSizePixel = 0,
	ZIndex = 17,
}, { BackgroundColor3 = "text3" })
S.corner(S.closeline2, 999)

S.closebutton.MouseEnter:Connect(function()
	if not S.windowminimizebuttonenabled then return end

	S.closeline1.BackgroundTransparency = 0
	S.closeline2.BackgroundTransparency = 0
	S.tween(
		S.closeline1,
		{ BackgroundColor3 = S.theme.text },
		S.hoverti,
		nil,
		{ BackgroundColor3 = "text" }
	)
	S.tween(
		S.closeline2,
		{ BackgroundColor3 = S.theme.text },
		S.hoverti,
		nil,
		{ BackgroundColor3 = "text" }
	)
end)

S.closebutton.MouseLeave:Connect(function()
	if not S.windowminimizebuttonenabled then return end

	S.closeline1.BackgroundTransparency = 0.08
	S.closeline2.BackgroundTransparency = 0.08
	S.tween(
		S.closeline1,
		{ BackgroundColor3 = S.theme.text3 },
		S.hoverti,
		nil,
		{ BackgroundColor3 = "text3" }
	)
	S.tween(
		S.closeline2,
		{ BackgroundColor3 = S.theme.text3 },
		S.hoverti,
		nil,
		{ BackgroundColor3 = "text3" }
	)
end)

S.closebutton.Activated:Connect(function() S.requestvisibilitytoggle() end)

S.searchholder = S.new("Frame", {
	Parent = S.header,

	AnchorPoint = Vector2.new(1, 0.5),

	Position = UDim2.new(1, -52, 0.5, 0),

	Size = UDim2.fromOffset(150, 38),

	BackgroundColor3 = S.theme.input,

	BorderSizePixel = 0,

	Active = true,

	ZIndex = 14,
}, { BackgroundColor3 = "input" })

S.searchfadetoken = 0
S.searchfadeanimations = {}
S.minimizelineanimation1 = nil
S.minimizelineanimation2 = nil

S.corner(S.searchholder, 9)
S.searchshadow = S.addshadow(
	S.searchholder,
	"SearchShadow",
	0.94,
	8,
	1,
	-1,
	Color3.fromRGB(0, 0, 0),
	UDim2.fromOffset(0, 2),
	false
)

function S.updatebreadcrumblayout(
	width,
	closevisible,
	rightinset,
	searchvisible,
	searchwidth,
	left,
	right,
	available,
	primarywidth,
	hassubtitle,
	secondarywidth,
	textspace,
	primarymax,
	contentwidth
)
	if not S.header or not S.header.Parent then return end

	width = math.max(1, S.header.AbsoluteSize.X)
	closevisible = S.windowminimizebuttonenabled == true
	rightinset = closevisible and 56 or 14
	searchvisible = S.searchenabled and true
	searchwidth = searchvisible and S.searchholder.AbsoluteSize.X or 0
	left = 14
	right = searchvisible and width - rightinset - searchwidth - 12 or width - rightinset
	available = math.max(40, right - left)

	primarywidth = math.ceil(
		S.measuretext(
			S.titleprimary.Text,
			S.titleprimary.TextSize,
			S.titleprimary.Font,
			Vector2.new(100000, 28)
		).X
	)
	hassubtitle = S.titlesecondary.Visible and S.titlesecondary.Text ~= ""
	secondarywidth = hassubtitle
			and math.ceil(
				S.measuretext(
					S.titlesecondary.Text,
					S.titlesecondary.TextSize,
					S.titlesecondary.Font,
					Vector2.new(100000, 28)
				).X
			)
		or 0

	if hassubtitle then
		textspace = math.max(0, available - 24)
		if primarywidth + secondarywidth > textspace then
			primarymax = math.max(32, math.floor(textspace * 0.6))
			primarywidth = math.min(primarywidth, primarymax)
			secondarywidth = math.min(secondarywidth, math.max(0, textspace - primarywidth))
		end
	else
		primarywidth = math.min(primarywidth, available)
	end

	S.titleprimary.Size = UDim2.fromOffset(math.max(1, primarywidth), 28)
	S.titleprimary.TextTruncate = Enum.TextTruncate.AtEnd
	S.titlesecondary.Size = UDim2.fromOffset(math.max(0, secondarywidth), 28)
	S.titlesecondary.TextTruncate = Enum.TextTruncate.AtEnd

	contentwidth = primarywidth + (hassubtitle and (secondarywidth + 24) or 0)
	contentwidth = math.min(contentwidth, available)
	S.breadcrumb.AnchorPoint = Vector2.new(0, 0.5)
	S.breadcrumb.Position = UDim2.fromOffset(left, 31)
	S.breadcrumb.Size = UDim2.fromOffset(math.max(1, contentwidth), 28)
end

function S.updateheadercontrols(width, closevisible, rightinset, searchwidth)
	if not S.header or not S.header.Parent then return end

	width = math.max(0, S.header.AbsoluteSize.X)
	closevisible = S.windowminimizebuttonenabled == true
	rightinset = closevisible and 56 or 14
	searchwidth = math.clamp(width - 190, 96, 150)

	S.searchholder.Size = UDim2.fromOffset(searchwidth, 38)
	S.searchholder.Position = UDim2.new(1, -rightinset, 0.5, 0)
	S.closebutton.Size = UDim2.fromOffset(34, 34)
	S.closebutton.Position = UDim2.new(1, -14, 0.5, 0)
	S.updatebreadcrumblayout()
end

S.connect(S.header:GetPropertyChangedSignal("AbsoluteSize"), S.updateheadercontrols)

S.updateheadercontrols()

for _, object in ipairs({ S.titleprimary, S.titlesecondary }) do
	S.connect(object:GetPropertyChangedSignal("Text"), S.updatebreadcrumblayout)
	S.connect(object:GetPropertyChangedSignal("TextSize"), S.updatebreadcrumblayout)
	S.connect(object:GetPropertyChangedSignal("Font"), S.updatebreadcrumblayout)
	S.connect(object:GetPropertyChangedSignal("Visible"), S.updatebreadcrumblayout)
end

function S.setminimizebuttonvisible(value, animate, changed, target, info, animation3)
	value = value == true
	changed = S.windowminimizebuttonenabled ~= value
	S.windowminimizebuttonenabled = value

	for _, animation in ipairs({ S.minimizelineanimation1, S.minimizelineanimation2 }) do
		if animation then animation:Cancel() end
	end

	S.minimizelineanimation1 = nil
	S.minimizelineanimation2 = nil
	S.closebutton.Active = value

	if value then S.closebutton.Visible = true end

	S.updateheadercontrols()
	if S.topnavigationenabled and S.updatetopnavigationlayout then S.updatetopnavigationlayout() end

	if not animate or not S.animationsenabled or not changed then
		S.closebutton.Visible = value
		S.closeline1.BackgroundTransparency = value and 0.08 or 1
		S.closeline2.BackgroundTransparency = value and 0.08 or 1
		return
	end

	target = value and 0.08 or 1
	if value then
		S.closeline1.BackgroundTransparency = 1
		S.closeline2.BackgroundTransparency = 1
	end

	info = S.hoverti
	S.minimizelineanimation1 = S.tween(S.closeline1, { BackgroundTransparency = target }, info)
	S.minimizelineanimation2 = S.tween(S.closeline2, { BackgroundTransparency = target }, info)

	animation3 = S.minimizelineanimation2 or S.minimizelineanimation1
	if animation3 then
		animation3.Completed:Connect(function()
			if
				S.minimizelineanimation2 ~= animation3
				and S.minimizelineanimation1 ~= animation3
			then
				return
			end

			S.minimizelineanimation1 = nil
			S.minimizelineanimation2 = nil
			if not S.windowminimizebuttonenabled then S.closebutton.Visible = false end
		end)
	end
end

function S.setsearchvisible(
	value,
	animate,
	changed,
	token,
	parts,
	base,
	primary,
	animation4,
	finish
)
	value = value == true and true
	changed = S.searchenabled ~= value
	S.searchenabled = value
	S.searchfadetoken += 1
	token = S.searchfadetoken
	S.searchholder.Active = value

	if S.search then
		S.search.Active = value
		S.search.TextEditable = value
	end

	for _, animation in ipairs(S.searchfadeanimations) do
		animation:Cancel()
	end
	table.clear(S.searchfadeanimations)

	if value then S.searchholder.Visible = true end

	S.updateheadercontrols()
	if S.topnavigationenabled and S.updatetopnavigationlayout then S.updatetopnavigationlayout() end

	parts = {
		{
			S.searchholder,
			"BackgroundTransparency",
			value and S.effectivetransparency(0, "input") or 1,
		},
	}

	if S.searchicon and S.searchicon.Parent then
		parts[#parts + 1] =
			{ S.searchicon, "ImageTransparency", value and S.effectivefontalpha(0) or 1 }
	end

	if S.search and S.search.Parent then
		parts[#parts + 1] = { S.search, "TextTransparency", value and S.effectivefontalpha(0) or 1 }
	end

	if S.searchshadow and S.searchshadow.Parent then
		base = S.searchshadow:GetAttribute("BlushBaseTransparency") or 0.94
		parts[#parts + 1] = { S.searchshadow, "Transparency", value and base or 1 }
	end

	if not animate or not S.animationsenabled or not changed then
		for _, part in ipairs(parts) do
			part[1][part[2]] = part[3]
		end
		S.searchholder.Visible = value
		return
	end

	primary = nil
	for _, part in ipairs(parts) do
		animation4 = S.tween(part[1], { [part[2]] = part[3] }, S.hoverti, true)
		if animation4 then
			S.searchfadeanimations[#S.searchfadeanimations + 1] = animation4
			primary = primary or animation4
		end
	end

	finish = function()
		if token ~= S.searchfadetoken then return end
		table.clear(S.searchfadeanimations)
		if not S.searchenabled then S.searchholder.Visible = false end
	end

	if primary then
		primary.Completed:Connect(finish)
	else
		finish()
	end
end

S.searchicon = S.image(S.searchholder, S.icons.search, 20, S.theme.text3, 15)

S.searchicon.AnchorPoint = Vector2.new(0, 0.5)

S.searchicon.Position = UDim2.fromOffset(10, 19)

S.search = S.new("TextBox", {
	Parent = S.searchholder,

	Position = UDim2.fromOffset(38, -1),

	Size = UDim2.new(1, -46, 1, 0),

	BackgroundTransparency = 1,
	BorderSizePixel = 0,

	Text = "",
	PlaceholderText = "search...",

	PlaceholderColor3 = S.theme.text3,

	TextColor3 = S.theme.text,

	Font = S.font,
	TextSize = 18,

	TextXAlignment = Enum.TextXAlignment.Left,

	ClearTextOnFocus = false,

	ZIndex = 15,
}, { PlaceholderColor3 = "text3", TextColor3 = "text" })

S.content = S.new("Frame", {
	Parent = S.main,

	Position = UDim2.fromOffset(14, 62),

	Size = UDim2.new(1, -28, 1, -76),

	BackgroundTransparency = 1,

	ZIndex = 12,
})

S.popuplayer = S.new("Frame", {
	Parent = S.gui,

	Size = UDim2.fromScale(1, 1),

	BackgroundTransparency = 1,
	BorderSizePixel = 0,

	ClipsDescendants = false,

	ZIndex = 500,
})

S.draglayer = S.new("CanvasGroup", {
	Parent = S.gui,

	Size = UDim2.fromScale(1, 1),

	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	GroupTransparency = 0,

	ClipsDescendants = false,

	ZIndex = 400,
})

function S.makedragghost(source, zindex, absolute, size, holder, clone)
	absolute = source.AbsolutePosition - S.draglayer.AbsolutePosition
	size = source.AbsoluteSize
	holder = S.rawnew("Frame", {
		Parent = S.draglayer,
		Position = UDim2.fromOffset(absolute.X, absolute.Y),
		Size = UDim2.fromOffset(size.X, size.Y),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ClipsDescendants = false,
		ZIndex = zindex or 460,
	})

	clone = source:Clone()
	clone.Parent = holder
	clone.AnchorPoint = Vector2.zero
	clone.Position = UDim2.fromOffset(0, 0)
	clone.Size = UDim2.fromScale(1, 1)
	clone.LayoutOrder = 0

	for _, object in ipairs(clone:GetDescendants()) do
		if object:IsA("GuiObject") then
			object.ZIndex += (zindex or 460)
			if object.Name == "TabActiveIndicator" then object.BackgroundTransparency = 1 end
		end
	end
	clone.ZIndex += (zindex or 460)

	return holder, clone
end

function S.hideforghost(source, state, objects, props)
	state = {}
	objects = { source }
	for _, object in ipairs(source:GetDescendants()) do
		objects[#objects + 1] = object
	end

	for _, object in ipairs(objects) do
		if object:IsA("GuiObject") then
			if object.Name == "TabActiveIndicator" then continue end

			props = {}
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
			if next(props) then state[#state + 1] = { object = object, props = props } end
		elseif object:IsA("UIStroke") or object:IsA("UIShadow") then
			state[#state + 1] = { object = object, props = { Transparency = object.Transparency } }
			object.Transparency = 1
		end
	end

	return state
end

function S.restorefromghost(state, object9)
	for _, entry in ipairs(state or {}) do
		object9 = entry.object
		if object9 and object9.Parent then
			for property, value in pairs(entry.props) do
				object9[property] = value
			end
		end
	end
end

-- notifications

S.notificationdrag = nil

S.notificationholder = S.new("Frame", {
	Parent = S.gui,

	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -18, 0, 18),
	Size = UDim2.fromOffset(336, 560),

	BackgroundTransparency = 1,
	BorderSizePixel = 0,

	ClipsDescendants = false,
	ZIndex = 700,
})

S.new("UIListLayout", {
	Parent = S.notificationholder,

	FillDirection = Enum.FillDirection.Vertical,
	HorizontalAlignment = Enum.HorizontalAlignment.Right,
	VerticalAlignment = Enum.VerticalAlignment.Top,

	Padding = UDim.new(0, 8),
	SortOrder = Enum.SortOrder.LayoutOrder,
})

S.notifications = {}
S.notificationorder = 0

S.notificationin = S.sectionti

S.notificationout = S.ti

S.notificationreturn = S.sectionti

function S.notificationasset(value, result)
	if value == nil then return nil end

	if type(value) == "number" then return "rbxassetid://" .. tostring(value) end

	result = tostring(value)

	if string.match(result, "^%d+$") then return "rbxassetid://" .. result end

	return result ~= "" and result or nil
end

function S.removenotification(data)
	for i = #S.notifications, 1, -1 do
		if S.notifications[i] == data then
			table.remove(S.notifications, i)
			break
		end
	end
end

function S.dismissnotification(data, velocity, wrapper, card, animation, destroy)
	if not data or data.closing then return end

	data.closing = true
	S.removenotification(data)

	if S.notificationdrag and S.notificationdrag.data == data then S.notificationdrag = nil end

	wrapper = data.wrapper
	card = data.card

	if not wrapper or not wrapper.Parent then return end

	animation = nil

	if card and card.Parent then
		animation = S.tween(card, { GroupTransparency = 1 }, S.notificationout)
	end

	destroy = function()
		if wrapper and wrapper.Parent then wrapper:Destroy() end
	end

	if animation then
		animation.Completed:Connect(destroy)
	else
		destroy()
	end
end

function S.notify(
	titletext,
	bodytext,
	duration,
	actiontext,
	actioncallback,
	iconasset,
	options,
	titlevalue,
	bodyvalue,
	lifetime,
	actionvalue,
	iconvalue,
	hasaction,
	hasicon,
	viewportwidth,
	cardwidth,
	leftpadding,
	rightpadding,
	textwidth,
	bodysize,
	contentheight,
	height,
	wrapper,
	card,
	dragarea,
	iconobject,
	title,
	bodytextobject,
	actionbutton,
	data
)
	if S.notificationsenabled == false then return end

	options = nil

	if type(actiontext) == "table" then
		options = actiontext

		actiontext = options.action or options.button or options.actiontext

		actioncallback = options.callback or options.actioncallback

		iconasset = options.icon
	end

	S.notificationorder += 1

	titlevalue = tostring(titletext or "blush.")
	bodyvalue = tostring(bodytext or "")
	lifetime = math.max(1, tonumber(duration) or S.defaultnotificationduration)
	actionvalue = actiontext and tostring(actiontext) or nil
	iconvalue = S.notificationasset(iconasset)

	hasaction = actionvalue ~= nil and actionvalue ~= ""

	hasicon = iconvalue ~= nil and iconvalue ~= ""

	viewportwidth = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.X or 360
	cardwidth = 316
	leftpadding = hasicon and 48 or 14
	rightpadding = 14
	textwidth = cardwidth - leftpadding - rightpadding

	bodysize = S.measuretext(S.plaintext(bodyvalue), 15, S.font, Vector2.new(textwidth, 1000))

	contentheight = math.max(18, bodysize.Y)

	height = math.max(hasaction and 88 or 60, 36 + contentheight + (hasaction and 34 or 7))

	wrapper = S.new("Frame", {
		Parent = S.notificationholder,

		LayoutOrder = S.notificationorder,
		Size = UDim2.fromOffset(cardwidth, height),

		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ClipsDescendants = false,

		ZIndex = 701,
	})

	card = S.new("CanvasGroup", {
		Parent = wrapper,

		Position = UDim2.fromOffset(0, 0),
		Size = UDim2.fromOffset(cardwidth, height),

		BackgroundColor3 = S.theme.popup,
		BackgroundTransparency = 0,
		BorderSizePixel = 0,

		GroupTransparency = 1,
		ClipsDescendants = false,
		Active = true,

		ZIndex = 701,
	}, { BackgroundColor3 = "popup" })

	S.corner(card, 9)
	S.adddepthshadow(card, "floating")
	S.stroke(card, 0.5, S.theme.border, 0.6)

	dragarea = S.new("TextButton", {
		Parent = card,
		Size = UDim2.fromScale(1, 1),

		BackgroundColor3 = S.theme.hover,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,

		Text = "",
		AutoButtonColor = false,

		ZIndex = 702,
	}, { BackgroundColor3 = "hover" })

	S.corner(dragarea, 9)

	iconobject = nil

	if hasicon then
		iconobject = S.image(card, iconvalue, 23, S.theme.text2, 704)

		iconobject.Position = UDim2.fromOffset(14, 10)
	end

	title = S.label(
		card,
		titlevalue,
		UDim2.new(1, -leftpadding - rightpadding, 0, 21),
		S.bold,
		S.theme.text
	)

	title.Position = UDim2.fromOffset(leftpadding, 7)
	title.TextSize = 16
	title.TextTruncate = Enum.TextTruncate.AtEnd
	title.ZIndex = 704

	bodytextobject = S.label(
		card,
		bodyvalue,
		UDim2.new(1, -leftpadding - rightpadding, 0, contentheight + 2),
		S.font,
		S.theme.text3
	)

	bodytextobject.Position = UDim2.fromOffset(leftpadding, 29)
	bodytextobject.TextSize = 15
	bodytextobject.TextWrapped = true
	bodytextobject.TextYAlignment = Enum.TextYAlignment.Top
	bodytextobject.ZIndex = 704

	actionbutton = nil

	if hasaction then
		actionbutton = S.new("TextButton", {
			Parent = card,

			AnchorPoint = Vector2.new(1, 1),
			Position = UDim2.new(1, -11, 1, -10),
			Size = UDim2.fromOffset(
				math.clamp(
					S.measuretext(S.plaintext(actionvalue), 14, S.medium, Vector2.new(180, 22)).X
						+ 22,
					58,
					160
				),
				27
			),

			BackgroundColor3 = S.theme.white,
			BackgroundTransparency = 0,
			BorderSizePixel = 0,

			Text = actionvalue,
			TextColor3 = S.theme.black,
			TextSize = 14,
			Font = S.medium,
			AutoButtonColor = false,

			ZIndex = 706,
		}, { BackgroundColor3 = "white", TextColor3 = "black" })

		S.corner(actionbutton, 6)
	end

	data = {
		wrapper = wrapper,
		card = card,
		dragarea = dragarea,
		closing = false,
	}

	table.insert(S.notifications, data)

	while #S.notifications > S.maxnotifications do
		S.dismissnotification(S.notifications[1])
	end

	dragarea.InputBegan:Connect(function(input, start)
		if data.closing then return end

		if
			input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch
		then
			return
		end

		start = S.point(input)

		S.notificationdrag = {
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
		actionbutton.MouseEnter:Connect(
			function() S.tween(actionbutton, { TextTransparency = 0.14 }, S.hoverti) end
		)

		actionbutton.MouseLeave:Connect(
			function() S.tween(actionbutton, { TextTransparency = 0 }, S.hoverti) end
		)

		actionbutton.Activated:Connect(function()
			if data.closing then return end

			if actioncallback then task.spawn(function() S.invoke(actioncallback) end) end

			S.dismissnotification(data)
		end)
	end

	S.tween(card, { GroupTransparency = 0 }, S.notificationin)

	task.delay(lifetime, function()
		if data and not data.closing and data.card and data.card.Parent then
			S.dismissnotification(data)
		end
	end)

	return data
end

S.__blush_notify = S.notify

S.pages = {}

S.currentpage = nil
S.currentnav = nil
S.currentsub = nil

S.activepopup = nil
S.topprimarypopup = nil
S.interactionowner = nil
S.topprimarygesture = nil

S.windowdrag = nil
S.watermarkdrag = nil
S.sliderdrag = nil
S.pickerdrag = nil
S.sectiondrag = nil

S.animatedpickers = {}
S.pickeranimationconnection = nil
S.interactionrenderconnection = nil
S.animateduielements = setmetatable({}, { __mode = "k" })
S.animateduiconnection = nil

function S.stopanimateduiloop(connection)
	connection = S.animateduiconnection
	S.animateduiconnection = nil

	if connection and connection.Connected then connection:Disconnect() end
end

function S.ensureanimateduiloop()
	if S.animateduiconnection and S.animateduiconnection.Connected then return end

	S.animateduiconnection = S.runservice.RenderStepped:Connect(function(dt)
		if next(S.animateduielements) == nil then
			S.stopanimateduiloop()
			return
		end

		for object, data in pairs(S.animateduielements) do
			if not object.Parent then
				S.animateduielements[object] = nil
			elseif data.kind == "spinner" then
				if S.animationsenabled then
					data.value = (data.value + dt * 180) % 360
					object.Rotation = data.value
				end
			elseif data.kind == "bar" then
				if S.animationsenabled then
					data.value = (data.value + dt * 0.7) % 1
					object.Position = UDim2.new(-0.28 + data.value * 1.28, 0, 0, 0)
				else
					object.Position = UDim2.new(0.36, 0, 0, 0)
				end
			end
		end
	end)
end

function S.registeranimatedui(object, kind)
	S.animateduielements[object] = { kind = kind, value = 0 }
	S.ensureanimateduiloop()

	object.Destroying:Connect(function()
		S.animateduielements[object] = nil
		if next(S.animateduielements) == nil then S.stopanimateduiloop() end
	end)
end

function S.stoppickeranimationloop(connection)
	connection = S.pickeranimationconnection
	S.pickeranimationconnection = nil

	if connection and connection.Connected then connection:Disconnect() end
end

function S.ensurepickeranimationloop()
	if S.pickeranimationconnection and S.pickeranimationconnection.Connected then return end

	S.pickeranimationconnection = S.runservice.RenderStepped:Connect(function(dt)
		if next(S.animatedpickers) == nil then
			S.stoppickeranimationloop()
			return
		end

		for pickerstate in pairs(S.animatedpickers) do
			pickerstate:update(dt)
		end
	end)
end

function S.acquireinteraction(kind, owner)
	if S.interactionowner and S.interactionowner.owner ~= owner then return false end

	S.interactionowner = {
		kind = kind,
		owner = owner,
	}

	return true
end

function S.releaseinteraction(owner)
	if S.interactionowner and (owner == nil or S.interactionowner.owner == owner) then
		S.interactionowner = nil
		if S.pendingsettingssave then S.saveuisettings() end
		if S.pendingconfigsave then S.requestconfigautosave() end
	end
end

-- popup

function S.fadepopup(popup, target, objects, properties2, primary, goals, animation)
	if target == 1 and not popup.panel.Visible then return nil end
	if popup.panel:IsA("CanvasGroup") then
		return S.tween(popup.panel, { GroupTransparency = target }, S.dropti)
	end
	if not popup.fadeentries then
		popup.fadeentries = {}
		objects = popup.panel:GetDescendants()
		objects[#objects + 1] = popup.panel
		for _, object in ipairs(objects) do
			properties2 = {}
			if object:IsA("GuiObject") then
				properties2.BackgroundTransparency = object.BackgroundTransparency
			end
			if object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox") then
				properties2.TextTransparency = object.TextTransparency
				properties2.TextStrokeTransparency = object.TextStrokeTransparency
			elseif object:IsA("ImageLabel") or object:IsA("ImageButton") then
				properties2.ImageTransparency = object.ImageTransparency
			elseif object:IsA("UIStroke") or object:IsA("UIShadow") then
				properties2.Transparency = object.Transparency
			end
			if next(properties2) then popup.fadeentries[object] = properties2 end
		end
	end
	primary = nil
	for object, properties in pairs(popup.fadeentries) do
		if object.Parent then
			goals = {}
			for property, base in pairs(properties) do
				if target == 0 then object[property] = 1 end
				goals[property] = 1 - (1 - base) * (1 - target)
			end
			animation = S.tween(object, goals, S.dropti, true)
			primary = primary or animation
		end
	end
	popup.panel.Visible = true
	return primary
end

function S.closepopup(popup, animation, destroy, completed)
	if not S.activepopup then return end

	popup = S.activepopup
	S.activepopup = nil

	if popup.onclose then popup.onclose() end

	if popup.blocker and popup.blocker.Parent then popup.blocker:Destroy() end

	if not popup.panel or not popup.panel.Parent then return end

	animation = S.fadepopup(popup, 1)

	destroy = function()
		if popup.panel and popup.panel.Parent then popup.panel:Destroy() end
	end

	if animation then
		completed = nil
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

function S.createpopup(
	position,
	width,
	height,
	zindex,
	kind,
	rootsize,
	x,
	y,
	blocker,
	panel,
	animationobject,
	margin,
	group,
	popupshadow,
	popupshadow2,
	popup
)
	S.closepopup()

	rootsize = S.popuplayer.AbsoluteSize

	x = math.clamp(position.X, 8, math.max(8, rootsize.X - width - 8))

	y = position.Y

	blocker = nil

	panel = nil
	animationobject = nil

	if kind == "color" then
		margin = 12

		group = S.new("CanvasGroup", {
			Parent = S.popuplayer,

			Position = UDim2.fromOffset(x - margin, y - margin),

			Size = UDim2.fromOffset(width + margin * 2, height + margin * 2),

			BackgroundTransparency = 1,
			BorderSizePixel = 0,

			GroupTransparency = 1,
			ClipsDescendants = true,
			Active = true,

			ZIndex = zindex + 1,
		})

		panel = S.new("Frame", {
			Parent = group,

			Position = UDim2.fromOffset(margin, margin),

			Size = UDim2.fromOffset(width, height),

			BackgroundColor3 = S.theme.popup,

			BorderSizePixel = 0,
			ClipsDescendants = false,
			Active = true,

			ZIndex = zindex + 1,
		}, { BackgroundColor3 = "popup" })

		S.corner(panel, 9)
		popupshadow = S.adddepthshadow(panel, "popup")
		if popupshadow then popupshadow:SetAttribute("BlushBaseTransparency", 0.62) end
		animationobject = group
	else
		panel = S.new("Frame", {
			Parent = S.popuplayer,

			Position = UDim2.fromOffset(math.round(x), math.round(y)),

			Size = UDim2.fromOffset(width, height),

			BackgroundColor3 = S.theme.popup,

			BorderSizePixel = 0,
			Visible = false,
			ClipsDescendants = true,
			Active = true,

			ZIndex = zindex + 1,
		}, { BackgroundColor3 = "popup" })

		S.corner(panel, 9)
		popupshadow2 = S.adddepthshadow(panel, "popup")
		if popupshadow2 then popupshadow2:SetAttribute("BlushBaseTransparency", 0.62) end
		animationobject = panel
	end

	popup = {
		panel = animationobject,
		content = panel,
		blocker = blocker,

		width = width,
		height = height,

		kind = kind,
	}

	S.activepopup = popup

	task.defer(function()
		if S.activepopup == popup and popup.panel.Parent then S.fadepopup(popup, 0) end
	end)

	

	return panel, popup
end

S.connect(S.uis.InputBegan, function(input, kind, inputpoint, content)
	if not S.activepopup then return end

	kind = input.UserInputType
	if
		kind ~= Enum.UserInputType.MouseButton1
		and kind ~= Enum.UserInputType.MouseButton2
		and kind ~= Enum.UserInputType.Touch
	then
		return
	end

	inputpoint = S.point(input)

	if
		S.topprimarypopup
		and S.activepopup == S.topprimarypopup
		and S.topprimarybutton
		and S.topprimarybutton.Parent
		and S.inside(S.topprimarybutton, inputpoint)
	then
		return
	end

	if
		kind == Enum.UserInputType.MouseButton1
		and S.activepopup.anchor
		and S.activepopup.anchor.Parent
		and S.inside(S.activepopup.anchor, inputpoint)
	then
		return
	end

	if
		kind == Enum.UserInputType.MouseButton1
		and S.activepopup.toggleconfig
		and S.activepopup.binding
		and S.activepopup.binding.configbutton
		and S.activepopup.binding.configbutton.Parent
		and S.inside(S.activepopup.binding.configbutton, inputpoint)
	then
		return
	end

	content = S.activepopup.content
	if content and content.Parent and S.inside(content, inputpoint) then return end

	S.closepopup()
end)

function S.overlayposition(object) return object.AbsolutePosition - S.popuplayer.AbsolutePosition end

function S.opencontextmenu(
	position,
	entries,
	width,
	height,
	rootpos,
	localpos,
	panel,
	popup,
	content
)
	width = 190
	height = 8

	for _, entry in ipairs(entries or {}) do
		height += entry.Divider and 14 or 30
	end

	rootpos = S.popuplayer.AbsolutePosition
	localpos = position - rootpos
	panel, popup =
		S.createpopup(Vector2.new(localpos.X + 4, localpos.Y + 4), width, height, 560, "dropdown")

	content = S.new("Frame", {
		Parent = panel,
		Position = UDim2.fromOffset(4, 4),
		Size = UDim2.new(1, -8, 1, -8),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 562,
	})
	S.list(content, 2)

	for _, entry, iteration1 in S.scopediterator(2, ipairs(entries or {})) do
		if entry.Divider then
			iteration1.holder = S.new("Frame", {
				Parent = content,
				Size = UDim2.new(1, 0, 0, 12),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ZIndex = 563,
			})
			iteration1.line = S.new("Frame", {
				Parent = iteration1.holder,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.new(1, -10, 0, 1),
				BackgroundColor3 = S.theme.border,
				BackgroundTransparency = 0.48,
				BorderSizePixel = 0,
				ZIndex = 564,
			}, { BackgroundColor3 = "border" })
			S.corner(iteration1.line, 999)
		else
			iteration1.button = S.new("TextButton", {
				Parent = content,
				Size = UDim2.new(1, 0, 0, 28),
				BackgroundColor3 = S.theme.hover,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Text = "",
				AutoButtonColor = false,
				ZIndex = 563,
			}, { BackgroundColor3 = "hover" })
			S.corner(iteration1.button, 6)

			iteration1.x = 9
			if entry.Icon then
				iteration1.iconobject =
					S.image(iteration1.button, entry.Icon, 16, S.theme.text2, 564)
				iteration1.iconobject.AnchorPoint = Vector2.new(0, 0.5)
				iteration1.iconobject.Position = UDim2.fromOffset(9, 14)
				iteration1.x = 32
			end

			iteration1.textobject = S.label(
				iteration1.button,
				entry.Text or entry.Name or "Option",
				UDim2.new(1, -(iteration1.x + 8), 1, 0),
				S.font,
				S.theme.text2
			)
			iteration1.textobject.Position = UDim2.fromOffset(iteration1.x, 0)
			iteration1.textobject.TextSize = 15
			iteration1.textobject.ZIndex = 564

			iteration1.button.MouseEnter:Connect(
				function()
					S.tween(
						iteration1.textobject,
						{ TextColor3 = S.theme.text },
						S.hoverti,
						nil,
						{ TextColor3 = "text" }
					)
				end
			)
			iteration1.button.MouseLeave:Connect(
				function()
					S.tween(
						iteration1.textobject,
						{ TextColor3 = S.theme.text2 },
						S.hoverti,
						nil,
						{ TextColor3 = "text2" }
					)
				end
			)
			iteration1.button.Activated:Connect(function()
				S.closepopup()
				if entry.Callback then entry.Callback() end
			end)
		end
	end

	return panel, popup
end

function S.attachcontextmenu(object, entries)
	object.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			S.opencontextmenu(S.point(input), entries)
		end
	end)


	return object
end

function S.closemodal(instant, modal, finish, animation)
	modal = S.__blush_modal or S.__blush_closingmodal
	if not modal then return end
	S.__blush_modal = nil
	S.__blush_closingmodal = modal
	if modal.cardtween then modal.cardtween:Cancel() end
	finish = function()
		if S.__blush_closingmodal == modal then S.__blush_closingmodal = nil end
		if modal.root.Parent then modal.root:Destroy() end
	end
	if instant == true or not modal.root.Parent then finish() return end
	S.tween(modal.blocker, {BackgroundTransparency = 1}, S.quart20, true)
	animation = S.tween(modal.card, {Position = UDim2.new(.5, 0, .5, 10)}, S.quart20)
	modal.cardtween = animation
	if animation then animation.Completed:Once(finish) else finish() end
end

function S.showmodal(
	titletext,
	bodytext,
	actions,
	root,
	blocker,
	modalviewport,
	modalwidth,
	modalheight,
	card,
	titleobject,
	bodyobject,
	divider,
	actionrow,
	modalinfo
)
	S.closepopup()
	S.closemodal(true)


	root = S.new("Frame", {
		Parent = S.popuplayer,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 700,
	})

	blocker = S.new("TextButton", {
		Parent = root,
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 700,
	})

	modalviewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize
		or Vector2.new(800, 450)
	modalwidth = math.min(400, math.max(260, modalviewport.X - 32))

	modalheight = 188
	card = S.new("Frame", {
		Parent = root,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(.5, 0, .5, 10),
		Size = UDim2.fromOffset(modalwidth, modalheight),
		BackgroundColor3 = S.theme.popup,
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		ZIndex = 701,
	}, { BackgroundColor3 = "popup" })
	S.corner(card, 10)
	S.transparencybase[card] = nil
	card.BackgroundTransparency = 0
	S.addshadow(
		card,
		"ModalShadow",
		0.76,
		20,
		3,
		-1,
		Color3.fromRGB(0, 0, 0),
		UDim2.fromOffset(0, 5),
		false
	)

	titleobject =
		S.label(card, titletext or "Dialog", UDim2.new(1, -32, 0, 28), S.bold, S.theme.text)
	titleobject.Position = UDim2.fromOffset(16, 13)
	titleobject.TextSize = 19
	titleobject.ZIndex = 702

	bodyobject = S.label(card, bodytext or "", UDim2.new(1, -32, 0, 64), S.font, S.theme.text2)
	bodyobject.Position = UDim2.fromOffset(16, 46)
	bodyobject.TextSize = 15
	bodyobject.TextWrapped = true
	bodyobject.TextYAlignment = Enum.TextYAlignment.Top
	bodyobject.ZIndex = 702

	divider = S.new("Frame", {
		Parent = card,
		Position = UDim2.new(0, 16, 1, -55),
		Size = UDim2.new(1, -32, 0, 1),
		BackgroundColor3 = S.theme.border,
		BackgroundTransparency = 0.52,
		BorderSizePixel = 0,
		ZIndex = 702,
	}, { BackgroundColor3 = "border" })
	S.corner(divider, 999)

	actionrow = S.new("Frame", {
		Parent = card,
		Position = UDim2.new(0, 16, 1, -45),
		Size = UDim2.new(1, -32, 0, 32),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 702,
	})
	S.new("UIListLayout", {
		Parent = actionrow,
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 7),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	for index, action, iteration2 in S.scopediterator(2, ipairs(actions or { { Text = "Close" } })) do
		iteration2.primary = action.Primary == true
		iteration2.button = S.new("TextButton", {
			Parent = actionrow,
			LayoutOrder = index,
			Size = UDim2.fromOffset(94, 30),
			BackgroundColor3 = iteration2.primary and S.theme.white or S.theme.input,
			BackgroundTransparency = iteration2.primary and 0.02 or 0.04,
			BorderSizePixel = 0,
			Text = action.Text or "Action",
			TextColor3 = iteration2.primary and S.theme.black or S.theme.text2,
			Font = S.medium,
			TextSize = 15,
			AutoButtonColor = false,
			ZIndex = 703,
		})
		S.corner(iteration2.button, 7)
		S.stroke(
			iteration2.button,
			iteration2.primary and 0.78 or 0.62,
			iteration2.primary and S.theme.white or S.theme.border,
			0.55
		)

		iteration2.button.MouseEnter:Connect(
			function()
				S.tween(iteration2.button, {
					TextColor3 = iteration2.primary and S.theme.black or S.theme.text,
					TextTransparency = 0,
				}, S.hoverti)
			end
		)
		iteration2.button.MouseLeave:Connect(
			function()
				S.tween(iteration2.button, {
					TextColor3 = iteration2.primary and S.theme.black or S.theme.text2,
					TextTransparency = 0,
				}, S.hoverti)
			end
		)
		iteration2.button.Activated:Connect(function()
			S.closemodal()
			if action.Callback then action.Callback() end
		end)
	end

	blocker.Activated:Connect(S.closemodal)
	S.__blush_modal = {
		root = root,
		blocker = blocker,
		card = card,
	}

	modalinfo = S.quart20

	S.tween(blocker, { BackgroundTransparency = 0.72 }, modalinfo, true)
	S.__blush_modal.cardtween = S.tween(card, { Position = UDim2.fromScale(.5, .5) }, modalinfo)

	return root
end

function S.confirmdialog(titletext, bodytext, callback)
	return S.showmodal(titletext or "Confirm", bodytext or "Are you sure?", {
		{ Text = "Cancel", Cancel = true },
		{ Text = "Confirm", Primary = true, Callback = callback },
	})
end

S.__blush_togglebindings = {}
S.__blush_pending_keybinds = {}

S.hotkeyfontsize = 14
S.hotkeylistwidth = 288
S.hotkeyminimized = false

S.hotkeylist = S.new("CanvasGroup", {
	Parent = S.gui,
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -18, 0.5, -27),
	Size = UDim2.fromOffset(S.hotkeylistwidth, 54),
	BackgroundColor3 = S.theme.popup,
	BackgroundTransparency = 0,
	BorderSizePixel = 0,
	Visible = false,
	GroupTransparency = 0,
	ZIndex = 320,
}, { BackgroundColor3 = "popup" })
S.registerpanel(S.hotkeylist, "Keybinds")
S.corner(S.hotkeylist, 8)
S.stroke(S.hotkeylist, 0.62, S.theme.border, 0.55)
S.adddepthshadow(S.hotkeylist, "floating")
S.addshadow(
	S.hotkeylist,
	"HotkeyPanelGlow",
	0.965,
	12,
	0,
	-2,
	S.theme.white,
	UDim2.fromOffset(0, 0),
	true
)

S.hotkeyheadericon = S.image(S.hotkeylist, S.icons.keyboard, 15, S.theme.text3, 323)
S.hotkeyheadericon.AnchorPoint = Vector2.new(0, 0.5)
S.hotkeyheadericon.Position = UDim2.fromOffset(12, 16)
S.hotkeyheadericon.ImageTransparency = 0.08

S.hotkeytitle = S.label(S.hotkeylist, "Keybinds", UDim2.new(1, -72, 0, 30), S.medium, S.theme.text)
S.hotkeytitle.Position = UDim2.fromOffset(34, 1)
S.hotkeytitle.TextXAlignment = Enum.TextXAlignment.Left
S.hotkeytitle.TextSize = 16
S.hotkeytitle.ZIndex = 321

S.hotkeycollapse = S.new("ImageButton", {
	Parent = S.hotkeylist,
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -8, 0, 16),
	Size = UDim2.fromOffset(20, 20),
	BackgroundColor3 = S.theme.hover,
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Image = S.icons.down,
	ImageColor3 = S.theme.text3,
	ImageTransparency = 0.12,
	AutoButtonColor = false,
	ZIndex = 325,
}, { BackgroundColor3 = "hover", ImageColor3 = "text3" })
S.corner(S.hotkeycollapse, 6)

S.hotkeydragarea = S.rawnew("TextButton", {
	Parent = S.hotkeylist,
	Position = UDim2.fromOffset(0, 0),
	Size = UDim2.new(1, -36, 0, 31),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Text = "",
	AutoButtonColor = false,
	Active = true,
	ZIndex = 324,
})

S.hotkeycontent = S.new("CanvasGroup", {
	Parent = S.hotkeylist,
	Position = UDim2.fromOffset(8, 32),
	Size = UDim2.new(1, -16, 1, -39),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ClipsDescendants = true,
	GroupTransparency = 0,
	ZIndex = 321,
})

S.hotkeyscroll = S.new("ScrollingFrame", {
	Parent = S.hotkeycontent,
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	CanvasSize = UDim2.fromOffset(0, 0),
	ScrollBarThickness = 0,
	ScrollingDirection = Enum.ScrollingDirection.Y,
	ElasticBehavior = Enum.ElasticBehavior.Never,
	ZIndex = 322,
})
S.list(S.hotkeyscroll, 1)
S.hotkeyshown = false
S.hotkeytargetposition = S.hotkeylist.Position
S.hotkeydrag = nil
S.hotkeymoveanimation = nil
S.hotkeycontentanimation = nil
S.hotkeycollapseanimation = nil
S.hotkeysizeanimation = nil
S.hotkeyvisibilitytoken = 0
S.hotkeyminimizetoken = 0
S.hotkeyminimizeanimating = false
S.hotkeyanimti = S.hoverti
S.hotkeyfullheight = 54
S.hotkeyrows = setmetatable({}, { __mode = "k" })
S.hotkeygroups = {}
S.hotkeyempty = nil
S.hotkeydirty = false

function S.requesthotkeyrefresh(binding, data, active, ok, value)
	if not S.hotkeylist.Visible then
		S.hotkeydirty = true
		return
	end

	if binding then
		data = S.hotkeyrows[binding]
		if data and data.row and data.row.Parent then
			active = false
			ok, value = S.invoke(binding.get)
			if ok then active = value == true end

			S.updatehotkeyrow(data, binding, active, data.row.LayoutOrder, true)
			S.hotkeydirty = false
			return
		end
	end

	S.refreshhotkeylist()
end

function S.sethotkeyheight(targetheight)
	targetheight = math.max(32, math.round(targetheight))
	S.hotkeylist.Size = UDim2.fromOffset(S.hotkeylistwidth, targetheight)
end

function S.synchotkeyminimizedstate()
	if S.hotkeyminimizeanimating then return end

	if S.hotkeycontentanimation then
		S.hotkeycontentanimation:Cancel()
		S.hotkeycontentanimation = nil
	end

	if S.hotkeyminimized then
		S.sethotkeyheight(32)
		S.hotkeycontent.GroupTransparency = 1
		S.hotkeycontent.Visible = false
		S.hotkeycollapse.Rotation = -90
	else
		S.sethotkeyheight(S.hotkeyfullheight)
		S.hotkeycontent.Visible = true
		S.hotkeycontent.GroupTransparency = 0
		S.hotkeycollapse.Rotation = 0
	end
end

function S.sethotkeyminimized(value, animate, changed, token, targetheight, rotation)
	value = value == true
	changed = S.hotkeyminimized ~= value
	S.hotkeyminimized = value
	S.hotkeyminimizetoken += 1
	token = S.hotkeyminimizetoken

	if S.hotkeycontentanimation then
		S.hotkeycontentanimation:Cancel()
		S.hotkeycontentanimation = nil
	end

	if S.hotkeycollapseanimation then
		S.hotkeycollapseanimation:Cancel()
		S.hotkeycollapseanimation = nil
	end

	if S.hotkeysizeanimation then
		S.hotkeysizeanimation:Cancel()
		S.hotkeysizeanimation = nil
	end

	targetheight = value and 32 or S.hotkeyfullheight
	rotation = value and -90 or 0

	if not animate or not changed then
		S.hotkeyminimizeanimating = false
		S.sethotkeyheight(targetheight)
		S.hotkeycontent.Visible = not value
		S.hotkeycontent.GroupTransparency = value and 1 or 0
		S.hotkeycollapse.Rotation = rotation
		return
	end

	-- Keep the top-left position completely fixed. Only height/transparency/rotation animate.
	S.hotkeyminimizeanimating = true
	S.hotkeycontent.Visible = true

	S.hotkeysizeanimation = S.tween(
		S.hotkeylist,
		{ Size = UDim2.fromOffset(S.hotkeylistwidth, targetheight) },
		S.hoverti
	)

	S.hotkeycollapseanimation = S.tween(S.hotkeycollapse, { Rotation = rotation }, S.hoverti)

	S.hotkeycontentanimation =
		S.tween(S.hotkeycontent, { GroupTransparency = value and 1 or 0 }, S.hoverti)

	if S.hotkeysizeanimation then
		S.hotkeysizeanimation.Completed:Connect(function()
			if token ~= S.hotkeyminimizetoken then return end

			S.hotkeyminimizeanimating = false

			if value then
				S.hotkeycontent.Visible = false
				S.hotkeycontent.GroupTransparency = 1
			else
				S.hotkeycontent.Visible = true
				S.hotkeycontent.GroupTransparency = 0
			end
		end)
	end
end

S.hotkeycollapse.MouseEnter:Connect(
	function()
		S.tween(S.hotkeycollapse, {
			ImageColor3 = S.theme.text2,
			ImageTransparency = 0,
		}, S.hoverti, nil, { ImageColor3 = "text2" })
	end
)
S.hotkeycollapse.MouseLeave:Connect(
	function()
		S.tween(S.hotkeycollapse, {
			ImageColor3 = S.theme.text3,
			ImageTransparency = 0.12,
		}, S.hoverti, nil, { ImageColor3 = "text3" })
	end
)
S.hotkeycollapse.Activated:Connect(function() S.sethotkeyminimized(not S.hotkeyminimized, true) end)

S.hotkeydragarea.InputBegan:Connect(function(input)
	if
		input.UserInputType ~= Enum.UserInputType.MouseButton1
		and input.UserInputType ~= Enum.UserInputType.Touch
	then
		return
	end

	S.hotkeydrag = {
		input = input,
		start = S.point(input),
		position = S.hotkeytargetposition,
	}
end)

S.connect(S.uis.InputChanged, function(input, ismouse, istouch, delta, target, size, root, x, y)
	if not S.hotkeydrag then return end
	ismouse = input.UserInputType == Enum.UserInputType.MouseMovement
	istouch = input.UserInputType == Enum.UserInputType.Touch and input == S.hotkeydrag.input
	if not ismouse and not istouch then return end

	delta = S.point(input) - S.hotkeydrag.start
	target = S.offsetposition(S.hotkeydrag.position, delta)
	size = S.hotkeylist.AbsoluteSize
	root = S.popuplayer.AbsoluteSize
	x = math.clamp(target.X.Offset, -root.X + size.X + 8, -8)
	y = math.clamp(target.Y.Offset, -root.Y * 0.5 + 8, root.Y * 0.5 - size.Y - 8)
	S.hotkeytargetposition = UDim2.new(1, x, 0.5, y)
	S.hotkeylist.Position = S.hotkeytargetposition
end)

S.connect(S.uis.InputEnded, function(input)
	if not S.hotkeydrag then return end
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input ~= S.hotkeydrag.input then
		return
	end
	S.hotkeydrag = nil
end)

function S.sethotkeylistvisible(value, token, finish)
	value = value == true
	if value == S.hotkeyshown and S.hotkeylist.Visible == value then
		if value then S.refreshhotkeylist() end
		return
	end

	S.hotkeyshown = value
	S.hotkeyvisibilitytoken += 1
	token = S.hotkeyvisibilitytoken

	if S.hotkeymoveanimation then
		S.hotkeymoveanimation:Cancel()
		S.hotkeymoveanimation = nil
	end

	if value then
		S.hotkeylist.Visible = true
		S.hotkeylist.GroupTransparency = 1
		S.refreshhotkeylist()
		S.synchotkeyminimizedstate()
		S.hotkeymoveanimation = S.tween(S.hotkeylist, { GroupTransparency = 0 }, S.hotkeyanimti)
	else
		if not S.hotkeylist.Visible then return end

		S.hotkeymoveanimation = S.tween(S.hotkeylist, { GroupTransparency = 1 }, S.hotkeyanimti)

		finish = function()
			if token ~= S.hotkeyvisibilitytoken or S.hotkeyshown then return end

			S.hotkeylist.Visible = false
			S.hotkeylist.GroupTransparency = 0
		end

		if S.hotkeymoveanimation then
			S.hotkeymoveanimation.Completed:Connect(finish)
		else
			finish()
		end
	end
end

function S.hotkeycategoryicon(binding)
	if not binding then return nil end

	if binding.page and binding.page.icon ~= nil then return binding.page.icon end

	return binding.categoryicon
end

function S.updatehotkeygroup(data, category, binding, asset, textx)
	asset = S.hotkeycategoryicon(binding)
	data.category = category

	if data.asset ~= asset then
		data.asset = asset

		if data.icon and data.icon.Parent then data.icon:Destroy() end

		data.icon = nil

		if asset ~= nil and tostring(asset) ~= "" then
			data.icon = S.image(data.holder, asset, 13, S.theme.text3, 323)
			data.icon.AnchorPoint = Vector2.new(0, 0.5)
			data.icon.Position = UDim2.fromOffset(4, 15)
			data.icon.ImageTransparency = 0.08
		end
	end

	textx = data.icon and 23 or 4
	data.text.Text = tostring(category)
	data.text.Position = UDim2.fromOffset(textx, 3)
	data.text.Size = UDim2.new(1, -textx - 4, 0, 24)
end

function S.createhotkeygroup(key, category, binding, holder, textobject, data)
	holder = S.new("Frame", {
		Parent = S.hotkeyscroll,
		Size = UDim2.new(1, 0, 0, 31),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 322,
	})

	textobject =
		S.label(holder, tostring(category), UDim2.new(1, -8, 0, 24), S.medium, S.theme.text2)
	textobject.Position = UDim2.fromOffset(4, 3)
	textobject.TextSize = 13
	textobject.TextXAlignment = Enum.TextXAlignment.Left
	textobject.ZIndex = 323

	data = {
		holder = holder,
		icon = nil,
		text = textobject,
		category = category,
		asset = nil,
		key = key,
	}

	S.updatehotkeygroup(data, category, binding)
	S.hotkeygroups[key] = data
	return data
end

function S.createhotkeyrow(
	binding,
	row,
	checkbox,
	rendercheckbox,
	nametext,
	keyholder,
	keytext,
	data
)
	row = S.new("TextButton", {
		Parent = S.hotkeyscroll,
		Size = UDim2.new(1, 0, 0, 25),
		BackgroundColor3 = S.theme.hover,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 322,
	}, { BackgroundColor3 = "hover" })
	S.corner(row, 6)

	checkbox, rendercheckbox = S.makecheckbox(row, 15, false)
	checkbox.AnchorPoint = Vector2.new(0, 0.5)
	checkbox.Position = UDim2.new(0, 12, 0.5, 0)

	nametext = S.label(
		row,
		tostring(binding.name or "Toggle"),
		UDim2.new(1, -82, 1, 0),
		S.font,
		S.theme.text3
	)
	nametext.Position = UDim2.fromOffset(36, 0)
	nametext.TextSize = 13
	nametext.TextXAlignment = Enum.TextXAlignment.Left
	nametext.TextTruncate = Enum.TextTruncate.AtEnd
	nametext.ZIndex = 323

	keyholder = S.new("TextButton", {
		Parent = row,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -4, 0.5, 0),
		Size = UDim2.fromOffset(34, 22),
		BackgroundColor3 = S.theme.input,
		BackgroundTransparency = 0.34,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 323,
	}, { BackgroundColor3 = "input" })
	S.corner(keyholder, 6)
	S.stroke(keyholder, 0.7, S.theme.border, 0.6)

	keytext = S.label(keyholder, "", UDim2.fromScale(1, 1), S.medium, S.theme.text3)
	keytext.TextSize = 13
	keytext.TextXAlignment = Enum.TextXAlignment.Center
	keytext.ZIndex = 324

	S.keyeditbuttons[keyholder] = true

	data = {
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
		listening = false,
	}

	row.MouseEnter:Connect(function()
		if row.Parent then
			S.tween(
				nametext,
				{ TextColor3 = S.theme.text },
				S.hoverti,
				nil,
				{ TextColor3 = "text" }
			)
			S.tween(
				keytext,
				{ TextColor3 = S.theme.text2 },
				S.hoverti,
				nil,
				{ TextColor3 = "text2" }
			)
		end
	end)

	row.MouseLeave:Connect(function(color)
		if row.Parent then
			color = data.active and S.theme.text2 or S.theme.text3
			S.tween(nametext, { TextColor3 = color }, S.hoverti)
			S.tween(keytext, { TextColor3 = color }, S.hoverti)
		end
	end)

	keyholder.Activated:Connect(function()
		if binding.locked == true then return end
		if data.listening then
			data.listening = false
			S.endkeycapture(keyholder, nil)
			S.requesthotkeyrefresh(binding)
			return
		end
		data.listening = true
		data.keytext.Text = "..."
		if
			not S.beginkeycapture(
				keyholder,
				function()
					data.listening = false
					S.requesthotkeyrefresh(binding)
				end,
				function(selectedkey)
					data.listening = false
					S.setbindingkey(binding, selectedkey, true)
					S.requesthotkeyrefresh(binding)
				end,
				function(input)
					return input.UserInputType == Enum.UserInputType.MouseButton1
						and S.inside(keyholder, S.point(input))
				end
			)
		then
			data.listening = false
			S.requesthotkeyrefresh(binding)
		end
	end)

	row.Activated:Connect(function(ok, current)
		if S.inside(keyholder, S.uis:GetMouseLocation()) then return end
		if binding.locked == true then return end

		ok, current = S.invoke(binding.get)
		if ok and binding.set then binding.set(not (current == true), true) end
	end)

	S.hotkeyrows[binding] = data
	return data
end

function S.updatehotkeyrow(
	data,
	binding,
	active,
	layoutorder,
	animate,
	name2,
	keyname,
	keybounds,
	singlecharacter,
	keywidth,
	changed,
	color
)
	name2 = tostring(binding.name or "Toggle")
	keyname = data.listening and "..." or S.togglekeyname(binding.key)
	data.row.LayoutOrder = layoutorder

	if data.name ~= name2 then
		data.name = name2
		data.nametext.Text = name2
	end

	if data.keyname ~= keyname then
		data.keyname = keyname
		data.keytext.Text = keyname
	end

	keybounds = S.measuretext(keyname, 13, S.medium, Vector2.new(200, 22))
	singlecharacter = #S.plaintext(keyname) == 1
	keywidth = math.clamp(
		math.ceil(keybounds.X) + (singlecharacter and 14 or 18),
		singlecharacter and 28 or 38,
		88
	)

	data.keyholder.Size = UDim2.fromOffset(keywidth, 22)
	data.nametext.Size = UDim2.new(1, -keywidth - 56, 1, 0)

	changed = data.active ~= active
	if data.rendercheckbox then data.rendercheckbox(active) end
	data.active = active
	color = active and S.theme.text2 or S.theme.text3

	if changed and animate then
		S.tween(data.nametext, { TextColor3 = color }, S.hotkeyanimti)
		S.tween(data.keytext, { TextColor3 = color }, S.hotkeyanimti)
		S.tween(
			data.keyholder,
			{ BackgroundTransparency = active and 0.18 or 0.34 },
			S.hotkeyanimti
		)
	else
		data.nametext.TextColor3 = color
		data.keytext.TextColor3 = color
		data.keyholder.BackgroundTransparency = active and 0.18 or 0.34
	end
end

function S.refreshhotkeylist(
	seen,
	seengroups,
	groups,
	groupmap,
	count,
	category,
	groupkey2,
	group2,
	layoutorder,
	contentheight,
	itemcount,
	groupdata,
	active,
	ok,
	value,
	data2,
	created,
	maxcontent
)
	if not S.hotkeylist.Visible then
		S.hotkeydirty = true
		return
	end

	S.hotkeydirty = false

	seen = {}
	seengroups = {}
	groups = {}
	groupmap = {}
	count = 0

	for _, binding in ipairs(S.__blush_togglebindings or {}) do
		if binding.key ~= nil and (not binding.anchor or binding.anchor.Parent) then
			category = tostring(binding.subpage or binding.category or "Misc")

			groupkey2 = table.concat({
				tostring(binding.page or ""),
				category,
			}, "|")
			group2 = groupmap[groupkey2]

			if not group2 then
				group2 = {
					key = groupkey2,
					name = category,
					bindings = {},
					first = binding,
				}

				groupmap[groupkey2] = group2
				groups[#groups + 1] = group2
			end

			group2.bindings[#group2.bindings + 1] = binding
			count += 1
		end
	end

	layoutorder = 0
	contentheight = 0
	itemcount = 0

	for _, group in ipairs(groups) do
		groupdata = S.hotkeygroups[group.key]

		if not groupdata or not groupdata.holder or not groupdata.holder.Parent then
			groupdata = S.createhotkeygroup(group.key, group.name, group.first)
		else
			S.updatehotkeygroup(groupdata, group.name, group.first)
		end

		seengroups[group.key] = true
		layoutorder += 1
		groupdata.holder.LayoutOrder = layoutorder
		contentheight += 31
		itemcount += 1

		for _, binding in ipairs(group.bindings) do
			seen[binding] = true
			active = false
			ok, value = S.invoke(binding.get)

			if ok then active = value == true end

			data2 = S.hotkeyrows[binding]
			created = false

			if not data2 or not data2.row or not data2.row.Parent then
				data2 = S.createhotkeyrow(binding)
				created = true
			end

			layoutorder += 1
			S.updatehotkeyrow(data2, binding, active, layoutorder, not created)
			contentheight += 25
			itemcount += 1
		end
	end

	for binding, data in pairs(S.hotkeyrows) do
		if not seen[binding] then
			if data.row and data.row.Parent then data.row:Destroy() end

			S.hotkeyrows[binding] = nil
		end
	end

	for groupkey, data in pairs(S.hotkeygroups) do
		if not seengroups[groupkey] then
			if data.holder and data.holder.Parent then data.holder:Destroy() end

			S.hotkeygroups[groupkey] = nil
		end
	end

	if count == 0 then
		if not S.hotkeyempty or not S.hotkeyempty.Parent then
			S.hotkeyempty = S.label(
				S.hotkeyscroll,
				"No keybinds",
				UDim2.new(1, 0, 0, 26),
				S.font,
				S.theme.text3
			)
			S.hotkeyempty.TextSize = S.hotkeyfontsize
			S.hotkeyempty.ZIndex = 322
		end

		contentheight = 26
		itemcount = 1
	else
		if S.hotkeyempty and S.hotkeyempty.Parent then S.hotkeyempty:Destroy() end

		S.hotkeyempty = nil
	end

	if itemcount > 1 then
		contentheight += itemcount - 1
	end

	S.hotkeyscroll.CanvasSize = UDim2.fromOffset(0, math.max(26, contentheight))

	maxcontent = 340

	S.hotkeyfullheight = 39 + math.min(math.max(26, contentheight), maxcontent)

	S.synchotkeyminimizedstate()
end

function S.togglekeyname(key, aliases)
	if not key then return "None" end

	aliases = {
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

	return aliases[key.Name] or key.Name
end

function S.validmousebind(inputtype)
	return inputtype == Enum.UserInputType.MouseButton1
		or inputtype == Enum.UserInputType.MouseButton2
		or inputtype == Enum.UserInputType.MouseButton3
end

S.keyeditbuttons = setmetatable({}, { __mode = "k" })

function S.iskeyeditclick(input, position)
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return false end

	position = S.point(input)
	for button in pairs(S.keyeditbuttons) do
		if
			button.Parent
			and button.Visible
			and S.guivisible(button)
			and S.inside(button, position)
		then
			return true
		end
	end

	return false
end

function S.bindingmatchesinput(key, input)
	if not key then return false end

	if key.EnumType == Enum.KeyCode then
		return input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == key
	end

	if key.EnumType == Enum.UserInputType then
		return S.validmousebind(key) and input.UserInputType == key
	end

	return false
end

S.keybindblacklistdefaults = {
	"MouseButton1",
	"W",
	"A",
	"S",
	"D",
	"Space",
}

S.keybindblacklist = {}

S.keybindblacklistlabelmap = {
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

S.keybindblacklistreverse = {}
for name, labelvalue in pairs(S.keybindblacklistlabelmap) do
	S.keybindblacklistreverse[labelvalue] = name
end

S.keybindblacklistoptions = {
	"M1",
	"W",
	"A",
	"S",
	"D",
	"Space",
}

function S.keybindblacklistcanonical(value)
	value = tostring(value or "")
	return S.keybindblacklistreverse[value] or value
end

function S.keybindblacklistlabel(value)
	value = tostring(value or "")
	return S.keybindblacklistlabelmap[value] or value
end

function S.ensurekeybindblacklistoption(value, name3, labelvalue2)
	name3 = S.keybindblacklistcanonical(value)
	labelvalue2 = S.keybindblacklistlabel(name3)

	if name3 ~= "" and not table.find(S.keybindblacklistoptions, labelvalue2) then
		table.insert(S.keybindblacklistoptions, labelvalue2)
	end

	return name3, labelvalue2
end

function S.setkeybindblacklist(values, name4)
	table.clear(S.keybindblacklist)
	for _, defaultkey in ipairs(S.keybindblacklistdefaults) do
		S.keybindblacklist[S.keybindblacklistcanonical(defaultkey)] = true
	end

	for _, value in ipairs(type(values) == "table" and values or S.keybindblacklistdefaults) do
		name4 = S.ensurekeybindblacklistoption(value)
		if name4 ~= "" then S.keybindblacklist[name4] = true end
	end
end

function S.getkeybindblacklistlabels(result)
	result = {}

	for _, labelvalue in ipairs(S.keybindblacklistoptions) do
		if S.keybindblacklist[S.keybindblacklistcanonical(labelvalue)] then
			result[#result + 1] = labelvalue
		end
	end

	return result
end

function S.getkeybindblacklistnames(result, name5)
	result = {}

	for _, labelvalue in ipairs(S.keybindblacklistoptions) do
		name5 = S.keybindblacklistcanonical(labelvalue)

		if S.keybindblacklist[name5] then result[#result + 1] = name5 end
	end

	return result
end

function S.iskeybindblacklisted(key) return key ~= nil and S.keybindblacklist[key.Name] == true end

S.setkeybindblacklist(S.keybindblacklistdefaults)

S.keycaptureowner = nil

function S.capturephysicalkey(input)
	if input.UserInputType == Enum.UserInputType.Keyboard then return input.KeyCode end

	if S.validmousebind(input.UserInputType) then return input.UserInputType end

	return nil
end

function S.beginkeycapture(
	owner,
	cancelcallback,
	selectcallback,
	ignorecallback,
	captureoptions,
	previous
)
	if S.keycaptureowner and S.keycaptureowner.owner ~= owner then
		previous = S.keycaptureowner
		S.keycaptureowner = nil

		if previous.cancel then previous.cancel() end

		S.releaseinteraction(previous.owner)
	end

	if not S.acquireinteraction("keycapture", owner) then return false end

	S.keycaptureowner = {
		owner = owner,
		cancel = cancelcallback,
		select = selectcallback,
		ignore = ignorecallback,
		options = captureoptions or {},
	}
	S.keypickercapturing = true
	return true
end

function S.endkeycapture(owner, suppresskey)
	if S.keycaptureowner and S.keycaptureowner.owner ~= owner then return false end

	S.keycaptureowner = nil
	S.keypickercapturing = false
	S.releaseinteraction(owner)

	if suppresskey then S.keypickersuppress = suppresskey end

	return true
end

function S.dispatchtogglebinding(key, began, anchor)
	if S.keypickercapturing or S.keypickersuppress == key then return end

	for _, binding in ipairs(S.__blush_togglebindings or {}) do
		anchor = binding.anchor

		if binding.key == key and binding.locked ~= true and (not anchor or anchor.Parent) then
			if began then
				if not binding.held then
					binding.held = true

					if binding.mode == "Toggle" then
						binding.set(not binding.get(), true)
					elseif binding.mode == "Hold" or binding.mode == "Always On" then
						binding.set(true, true)
					end
				end
			else
				binding.held = false

				if binding.mode == "Hold" then binding.set(false, true) end
			end
		end
	end
end

function S.setbindingkey(binding, key, persist, previous)
	if not binding then return end

	previous = binding.key

	if previous == key then
		binding.held = false

		if binding.refreshkey then binding.refreshkey() end

		S.requesthotkeyrefresh(binding)
		return
	end

	binding.key = key
	binding.held = false

	if binding.refreshkey then binding.refreshkey() end
	S.requesthotkeyrefresh(binding)

	if persist ~= false then S.requestconfigautosave() end
end

function S.unregistertogglebinding(binding, previous, row)
	if not binding then return end

	previous = binding.key

	for index = #S.__blush_togglebindings, 1, -1 do
		if S.__blush_togglebindings[index] == binding then
			table.remove(S.__blush_togglebindings, index)
			break
		end
	end

	row = S.hotkeyrows[binding]
	if row and row.row and row.row.Parent then row.row:Destroy() end
	S.hotkeyrows[binding] = nil
	S.requesthotkeyrefresh()
end

function S.opentoggleconfig(
	anchor,
	binding,
	clickposition,
	togglesame,
	previous,
	anchorpos,
	anchorsize,
	width,
	hasinlinekey,
	collapsedheight,
	expandedheight,
	popuporigin,
	x,
	y,
	panel,
	popup,
	title,
	keylabel,
	keybutton,
	keybuttonstroke,
	keytext,
	modelabel,
	modebutton,
	modetext,
	modearrow,
	options,
	listening,
	modeopen,
	modeentries,
	rendermode,
	renderkey,
	setmodeopen
)
	if S.activepopup and S.activepopup.toggleconfig then
		if S.activepopup.binding == binding then
			if togglesame == true then S.closepopup() end
			return
		end

		previous = S.activepopup
		S.activepopup = nil

		if previous.onclose then previous.onclose() end

		if previous.blocker and previous.blocker.Parent then previous.blocker:Destroy() end

		if previous.panel and previous.panel.Parent then previous.panel:Destroy() end
	end

	anchorpos = S.overlayposition(anchor)

	anchorsize = anchor.AbsoluteSize

	width = 228
	hasinlinekey = false
	collapsedheight = hasinlinekey and 72 or 103
	expandedheight = hasinlinekey and 166 or 197

	popuporigin = nil

	if typeof(clickposition) == "Vector2" then
		popuporigin = clickposition - S.popuplayer.AbsolutePosition
	else
		popuporigin =
			Vector2.new(anchorpos.X + math.min(28, anchorsize.X * 0.18), anchorpos.Y + anchorsize.Y)
	end

	x = popuporigin.X + 7
	y = popuporigin.Y + 7

	x = math.clamp(x, 8, math.max(8, S.popuplayer.AbsoluteSize.X - width - 8))

	y = math.clamp(y, 8, math.max(8, S.popuplayer.AbsoluteSize.Y - expandedheight - 8))

	panel, popup = S.createpopup(Vector2.new(x, y), width, collapsedheight, 540, "dropdown")

	popup.toggleconfig = true
	popup.binding = binding

	if popup.blocker and popup.blocker.Parent then
		popup.blocker:Destroy()
		popup.blocker = nil
	end

	S.stroke(panel, 0.44, S.theme.border, 0.65)

	title = S.label(panel, binding.name, UDim2.new(1, -20, 0, 28), S.bold, S.theme.text)

	title.Position = UDim2.fromOffset(10, 5)

	title.TextSize = 16
	title.ZIndex = 544

	keylabel = S.label(panel, "Key", UDim2.fromOffset(90, 28), S.font, S.theme.text2)

	keylabel.Position = UDim2.fromOffset(10, 37)
	keylabel.Visible = not hasinlinekey

	keylabel.TextSize = 15
	keylabel.ZIndex = 544

	keybutton = S.new("TextButton", {
		Parent = panel,
		Visible = not hasinlinekey,

		AnchorPoint = Vector2.new(1, 0),

		Position = UDim2.new(1, -10, 0, 37),

		Size = UDim2.fromOffset(54, 27),

		BackgroundColor3 = S.theme.input,
		BackgroundTransparency = 0.04,
		BorderSizePixel = 0,

		Text = "",
		AutoButtonColor = false,
		ZIndex = 545,
	}, { BackgroundColor3 = "input" })

	S.corner(keybutton, 6)
	S.keyeditbuttons[keybutton] = true

	keybuttonstroke = S.stroke(keybutton, 0.66, S.theme.border, 0.6)

	keytext = S.label(keybutton, "", UDim2.fromScale(1, 1), S.medium, S.theme.text2)

	keytext.TextSize = 14
	keytext.TextXAlignment = Enum.TextXAlignment.Center
	keytext.ZIndex = 546

	modelabel = S.label(panel, "Mode", UDim2.fromOffset(90, 28), S.font, S.theme.text2)

	modelabel.Position = UDim2.fromOffset(10, hasinlinekey and 37 or 68)

	modelabel.TextSize = 15
	modelabel.ZIndex = 544

	modebutton = S.new("TextButton", {
		Parent = panel,

		AnchorPoint = Vector2.new(1, 0),

		Position = UDim2.new(1, -10, 0, hasinlinekey and 37 or 68),

		Size = UDim2.fromOffset(108, 27),

		BackgroundColor3 = S.theme.input,
		BackgroundTransparency = 0.04,
		BorderSizePixel = 0,

		Text = "",
		AutoButtonColor = false,
		ZIndex = 545,
	}, { BackgroundColor3 = "input" })

	S.corner(modebutton, 6)
	S.stroke(modebutton, 0.66, S.theme.border, 0.6)

	modetext = S.label(modebutton, binding.mode, UDim2.new(1, -28, 1, 0), S.font, S.theme.text2)

	modetext.Position = UDim2.fromOffset(9, 0)

	modetext.TextSize = 14
	modetext.ZIndex = 546

	modearrow = S.image(modebutton, S.icons.down, 12, S.theme.text3, 546)

	modearrow.AnchorPoint = Vector2.new(1, 0.5)

	modearrow.Position = UDim2.new(1, -8, 0.5, 0)

	options = S.new("Frame", {
		Parent = panel,

		Position = UDim2.fromOffset(10, hasinlinekey and 73 or 104),

		Size = UDim2.new(1, -20, 0, 88),

		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 545,
	})

	S.list(options, 2)

	listening = false
	modeopen = false
	modeentries = {}

	rendermode = function()
		modetext.Text = binding.mode

		for mode, button in pairs(modeentries) do
			button.TextColor3 = mode == binding.mode and S.theme.text or S.theme.text2
		end
	end

	renderkey = function(value, bounds, widthvalue)
		value = listening and "..." or S.togglekeyname(binding.key)

		keytext.Text = value

		bounds = S.measuretext(value, 14, S.medium, Vector2.new(200, 27))

		widthvalue = math.clamp(math.ceil(bounds.X) + 20, 42, 112)

		S.tween(keybutton, {
			Size = UDim2.fromOffset(widthvalue, 27),
		}, S.fastti)

		S.tween(keybuttonstroke, {
			Color = S.theme.border,
			Transparency = listening and 0.38 or 0.66,
		}, S.fastti, nil, { Color = "border" })

		if binding.refreshkey then binding.refreshkey() end
	end

	setmodeopen = function(value)
		modeopen = value == true
		options.Visible = modeopen

		S.tween(modearrow, {
			Rotation = modeopen and 180 or 0,
		}, S.tabti)

		popup.height = modeopen and expandedheight or collapsedheight

		S.tween(panel, {
			Size = UDim2.fromOffset(width, popup.height),
		}, S.dropti)
	end

	for _, mode, iteration3 in
		S.scopediterator(
			2,
			ipairs({
				"Toggle",
				"Hold",
				"Always On",
			})
		)
	do
		iteration3.option = S.new("TextButton", {
			Parent = options,
			Size = UDim2.new(1, 0, 0, 28),
			BackgroundColor3 = S.theme.hover,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Text = mode,
			TextColor3 = mode == binding.mode and S.theme.text or S.theme.text2,
			Font = S.font,
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left,
			AutoButtonColor = false,
			ZIndex = 546,
		}, { BackgroundColor3 = "hover" })

		S.corner(iteration3.option, 6)
		S.padding(iteration3.option, 9, 9)
		modeentries[mode] = iteration3.option

		iteration3.option.MouseEnter:Connect(
			function()
				S.tween(
					iteration3.option,
					{ TextColor3 = S.theme.text },
					S.hoverti,
					nil,
					{ TextColor3 = "text" }
				)
			end
		)

		iteration3.option.MouseLeave:Connect(
			function()
				S.tween(iteration3.option, {
					TextColor3 = mode == binding.mode and S.theme.text or S.theme.text2,
				}, S.hoverti)
			end
		)

		iteration3.option.Activated:Connect(function()
			binding.mode = mode
			rendermode()
			S.requesthotkeyrefresh(binding)
			S.requestconfigautosave()

			if mode == "Always On" then
				binding.set(true, true)
			elseif mode == "Hold" then
				binding.held = false
				binding.set(false, true)
			end

			setmodeopen(false)
		end)
	end

	keybutton.MouseEnter:Connect(
		function()
			S.tween(keytext, { TextColor3 = S.theme.text }, S.hoverti, nil, { TextColor3 = "text" })
		end
	)

	keybutton.MouseLeave:Connect(
		function()
			S.tween(
				keytext,
				{ TextColor3 = S.theme.text2 },
				S.hoverti,
				nil,
				{ TextColor3 = "text2" }
			)
		end
	)

	modebutton.MouseEnter:Connect(
		function()
			S.tween(
				modetext,
				{ TextColor3 = S.theme.text },
				S.hoverti,
				nil,
				{ TextColor3 = "text" }
			)
		end
	)

	modebutton.MouseLeave:Connect(
		function()
			S.tween(
				modetext,
				{ TextColor3 = S.theme.text2 },
				S.hoverti,
				nil,
				{ TextColor3 = "text2" }
			)
		end
	)

	modebutton.Activated:Connect(function() setmodeopen(not modeopen) end)

	if not hasinlinekey then
		keybutton.Activated:Connect(function()
			if listening then
				listening = false
				S.endkeycapture(popup, nil)
				renderkey()
				return
			end

			listening = true

			if
				not S.beginkeycapture(
					popup,
					function()
						listening = false
						renderkey()
					end,
					function(selectedkey)
						listening = false
						S.setbindingkey(binding, selectedkey)
						renderkey()
					end,
					function(input)
						return input.UserInputType == Enum.UserInputType.MouseButton1
							and S.inside(keybutton, S.point(input))
					end
				)
			then
				listening = false
			end

			renderkey()
		end)
	end

	popup.onclose = function()
		listening = false
		S.endkeycapture(popup, false)
	end

	rendermode()
	renderkey()
end

function S.hotkeybindingid(binding)
	return table.concat({
		tostring(binding.kind or "Toggle"),
		tostring(binding.category or ""),
		tostring(binding.subpage or ""),
		tostring(binding.sectionname or ""),
		tostring(binding.name or ""),
	}, "|")
end

function S.applysavedkeybind(binding, data, key, mode)
	if not binding or type(data) ~= "table" then return end

	key = data.key and S.keyfromname(data.key) or nil

	if key ~= nil then
		S.setbindingkey(binding, key, false)
	elseif data.key == false or data.key == "None" then
		S.setbindingkey(binding, nil, false)
	end

	mode = tostring(data.mode or binding.mode or "Toggle")

	if mode ~= "Toggle" and mode ~= "Hold" and mode ~= "Always On" then mode = "Toggle" end

	binding.mode = mode
	binding.held = false

	if binding.refreshkey then binding.refreshkey() end

	if mode == "Always On" and binding.set then binding.set(true, false) end
	S.requesthotkeyrefresh(binding)
end

function S.currentkeybindpayload(payload, id)
	payload = {}

	for _, binding in ipairs(S.__blush_togglebindings or {}) do
		id = binding.id or S.hotkeybindingid(binding)

		binding.id = id

		payload[id] = {
			key = binding.key and binding.key.Name or false,

			mode = binding.mode or "Toggle",
		}
	end

	return payload
end

function S.applykeybindpayload(payload, id, data)
	S.__blush_pending_keybinds = type(payload) == "table" and payload or {}

	for _, binding in ipairs(S.__blush_togglebindings or {}) do
		id = binding.id or S.hotkeybindingid(binding)

		binding.id = id

		data = S.__blush_pending_keybinds[id]

		if data then S.applysavedkeybind(binding, data) end
	end

	S.refreshhotkeylist()
end

function S.registertogglebinding(binding, pending)
	if not binding then return end

	for _, current in ipairs(S.__blush_togglebindings) do
		if current == binding then return end
	end

	binding.id = binding.id or S.hotkeybindingid(binding)

	table.insert(S.__blush_togglebindings, binding)

	pending = S.__blush_pending_keybinds and S.__blush_pending_keybinds[binding.id]

	if pending then S.applysavedkeybind(binding, pending) end
	S.requesthotkeyrefresh(binding)
end

function S.attachtoggleconfig(anchor, binding, destroying)
	if binding.configattached and binding.anchor and binding.anchor.Parent then return end

	binding.configattached = true
	binding.anchor = anchor

	S.registertogglebinding(binding)

	destroying = nil
	destroying = anchor.Destroying:Connect(function()
		if destroying then
			destroying:Disconnect()
			destroying = nil
		end

		S.unregistertogglebinding(binding)
	end)

	anchor.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			binding.suppressclick = true
			S.opentoggleconfig(anchor, binding, S.point(input), false)
			binding.suppressclick = false
		end
	end)


end

function S.addtoggleconfigicon(
	anchor,
	binding,
	iconparent,
	rightinset,
	parentobject,
	button2,
	iconobject,
	clickposition
)
	parentobject = iconparent or anchor

	button2 = S.new("TextButton", {
		Parent = parentobject,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -(rightinset or 0), 0.5, 0),
		Size = UDim2.fromOffset(20, 18),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 20,
	})

	S.keyeditbuttons[button2] = true

	iconobject = S.image(button2, S.icons.keyboard, 16, S.theme.text3, 21)
	iconobject.AnchorPoint = Vector2.new(0.5, 0.5)
	iconobject.Position = UDim2.fromScale(0.5, 0.5)
	iconobject.ImageTransparency = 0.14

	binding.configbutton = button2

	button2.MouseEnter:Connect(
		function()
			S.tween(iconobject, {
				ImageColor3 = S.theme.text2,
				ImageTransparency = 0,
			}, S.hoverti, nil, { ImageColor3 = "text2" })
		end
	)

	button2.MouseLeave:Connect(
		function()
			S.tween(iconobject, {
				ImageColor3 = S.theme.text3,
				ImageTransparency = 0.14,
			}, S.hoverti, nil, { ImageColor3 = "text3" })
		end
	)

	clickposition = nil

	button2.InputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			clickposition = S.point(input)
		end
	end)

	button2.Activated:Connect(function()
		binding.suppressclick = true

		S.opentoggleconfig(anchor, binding, clickposition or S.uis:GetMouseLocation(), true)

		clickposition = nil
		binding.suppressclick = false
	end)

	return button2
end

S.connect(
	S.uis.InputBegan,
	function(input, capture, physical, captureoptions, cancel, selected, selectcallback, physical2)
		

		capture = S.keycaptureowner
		if capture then
			if capture.ignore and capture.ignore(input) then return end

			physical = S.capturephysicalkey(input)
			if not physical or physical == Enum.KeyCode.Unknown then return end

			captureoptions = capture.options or {}

			if physical == Enum.KeyCode.Escape and captureoptions.AllowEscape ~= true then
				cancel = capture.cancel
				S.endkeycapture(capture.owner, physical)
				if cancel then cancel() end
				return
			end

			selected = physical
			if
				(physical == Enum.KeyCode.Backspace or physical == Enum.KeyCode.Delete)
				and captureoptions.KeepDelete ~= true
			then
				selected = nil
			elseif S.iskeybindblacklisted(physical) and captureoptions.AllowBlacklisted ~= true then
				return
			end

			selectcallback = capture.select
			S.endkeycapture(capture.owner, physical)
			if selectcallback then selectcallback(selected, input) end
			return
		end

		if S.bindingmatchesinput(S.keypickersuppress, input) or S.iskeyeditclick(input) then
			return
		end

		physical2 = S.capturephysicalkey(input)
		if physical2 and physical2 ~= Enum.KeyCode.Unknown then
			S.dispatchtogglebinding(physical2, true)
		end
	end
)

S.connect(S.uis.InputEnded, function(input, physical)
	if S.bindingmatchesinput(S.keypickersuppress, input) then
		S.keypickersuppress = nil
		return
	end

	

	physical = S.capturephysicalkey(input)
	if physical and physical ~= Enum.KeyCode.Unknown then
		S.dispatchtogglebinding(physical, false)
	end
end)

S.inlinekeycapture = nil

function S.stopinlinekeycapture(suppresskey, state)
	state = S.inlinekeycapture
	if not state then return end

	S.inlinekeycapture = nil
	state.listening = false
	S.endkeycapture(state, suppresskey)

	if state.render then state.render() end
end

function S.attachinlinekeypicker(
	row,
	binding,
	textobject,
	defaultkey,
	keycallback,
	configbutton,
	keybutton,
	keytext,
	state,
	renderkey
)
	S.setbindingkey(binding, defaultkey or binding.key or Enum.KeyCode.F, false)
	binding.inlinekey = true

	configbutton = binding.configbutton

	keybutton = S.new("TextButton", {
		Parent = row,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, configbutton and -27 or 0, 0.5, 0),
		Size = UDim2.fromOffset(48, 20),
		BackgroundColor3 = S.theme.input,
		BackgroundTransparency = 0.08,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		Active = true,
		ZIndex = 19,
	}, { BackgroundColor3 = "input" })
	S.corner(keybutton, 6)
	S.keyeditbuttons[keybutton] = true
	S.stroke(keybutton, 0.72, S.theme.border, 0.6)

	keytext = S.label(keybutton, "", UDim2.fromScale(1, 1), S.medium, S.theme.text2)
	keytext.TextSize = 13
	keytext.TextXAlignment = Enum.TextXAlignment.Center
	keytext.ZIndex = 20

	state = {
		button = keybutton,
		binding = binding,
		listening = false,
		callback = keycallback,
	}

	renderkey = function(value, bounds, width)
		value = state.listening and "..." or S.togglekeyname(binding.key)
		keytext.Text = value

		bounds = S.measuretext(value, 13, S.medium, Vector2.new(120, 20))

		width = math.clamp(math.ceil(bounds.X) + 18, 36, 72)
		keybutton.Size = UDim2.fromOffset(width, 20)

		if textobject and textobject.Parent then
			textobject.Size = UDim2.new(1, -(width + 41 + (configbutton and 27 or 0)), 1, 0)
		end
		if binding.layoutaddons then binding.layoutaddons() end
	end

	state.render = renderkey
	binding.refreshkey = renderkey

	keybutton.InputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			binding.suppressclick = true
		end
	end)

	keybutton.Activated:Connect(function()
		if S.inlinekeycapture == state then
			S.stopinlinekeycapture(nil)
			binding.suppressclick = false
			return
		end

		if S.inlinekeycapture then S.stopinlinekeycapture(nil) end

		S.inlinekeycapture = state
		state.listening = true

		if
			not S.beginkeycapture(
				state,
				function()
					if S.inlinekeycapture == state then S.inlinekeycapture = nil end
					state.listening = false
					renderkey()
				end,
				function(selectedkey)
					S.inlinekeycapture = nil
					state.listening = false
					S.setbindingkey(binding, selectedkey)
					renderkey()

					if state.callback then state.callback(binding.key) end
				end,
				nil
			)
		then
			S.inlinekeycapture = nil
			state.listening = false
		end

		renderkey()
		binding.suppressclick = false
	end)

	keybutton.MouseEnter:Connect(
		function()
			S.tween(keytext, { TextColor3 = S.theme.text }, S.hoverti, nil, { TextColor3 = "text" })
		end
	)

	keybutton.MouseLeave:Connect(
		function()
			S.tween(
				keytext,
				{ TextColor3 = S.theme.text2 },
				S.hoverti,
				nil,
				{ TextColor3 = "text2" }
			)
		end
	)

	renderkey()
	S.refreshhotkeylist()

	return keybutton, configbutton
end

-- page scrollbar

function S.createscrollbar(page, scroll, side, track, thumb, update)
	track = S.new("Frame", {
		Parent = page,

		AnchorPoint = Vector2.new(1, 0),

		Position = side == "left" and UDim2.new(0.5, -8, 0, 5) or UDim2.new(1, -2, 0, 5),

		Size = UDim2.new(0, 2, 1, -10),

		BackgroundColor3 = S.theme.scrollTrack,

		BackgroundTransparency = 0.86,

		BorderSizePixel = 0,

		ZIndex = 40,
	}, { BackgroundColor3 = "scrollTrack" })

	S.corner(track, 999)

	thumb = S.new("Frame", {
		Parent = track,

		Position = UDim2.fromOffset(0, 0),

		Size = UDim2.fromOffset(2, 24),

		BackgroundColor3 = S.theme.scroll,

		BackgroundTransparency = 0.38,

		BorderSizePixel = 0,

		Visible = false,

		ZIndex = 41,
	}, { BackgroundColor3 = "scroll" })

	S.corner(thumb, 999)

	update = function(viewport, total, trackheight, height, maxcanvas, ratio, travel)
		viewport = scroll.AbsoluteSize.Y

		total = scroll.CanvasSize.Y.Offset

		trackheight = track.AbsoluteSize.Y

		if viewport <= 0 or total <= viewport + 1 or trackheight <= 0 then
			thumb.Visible = false
			track.BackgroundTransparency = 1
			return
		end

		thumb.Visible = true
		track.BackgroundTransparency = 0.86

		height = math.clamp(viewport / total * trackheight, 22, trackheight)

		maxcanvas = math.max(1, total - viewport)

		ratio = math.clamp(scroll.CanvasPosition.Y / maxcanvas, 0, 1)

		travel = trackheight - height

		thumb.Size = UDim2.fromOffset(2, height)

		thumb.Position = UDim2.fromOffset(0, travel * ratio)
	end

	scroll:GetPropertyChangedSignal("CanvasPosition"):Connect(update)

	scroll:GetPropertyChangedSignal("AbsoluteSize"):Connect(update)

	scroll:GetPropertyChangedSignal("CanvasSize"):Connect(update)

	track:GetPropertyChangedSignal("AbsoluteSize"):Connect(update)

	return update
end

-- pages

S.pendingpagelayouts = {}
S.pagelayoutconnection = nil

function S.flushpagelayouts()
	if S.pagelayoutconnection then
		S.pagelayoutconnection:Disconnect()
		S.pagelayoutconnection = nil
	end
	for page, columns in pairs(S.pendingpagelayouts) do
		S.pendingpagelayouts[page] = nil
		if page.frame.Parent then
			for column, animate in pairs(columns) do
				page:reflow(column, animate, true)
			end
		end
	end
end

function S.queuepagelayout(page, column, animate)
	if not S.gui or not S.gui.Parent then return end
	S.pendingpagelayouts[page] = S.pendingpagelayouts[page] or {}
	S.pendingpagelayouts[page][column] = S.pendingpagelayouts[page][column] == true or animate == true
	if not S.constructing and not S.pagelayoutconnection then
		S.pagelayoutconnection = S.runservice.PreRender:Connect(S.flushpagelayouts)
	end
end

function S.sectionorderless(a, b) return a.order < b.order end

function S.createpage(name, primary, secondary, pageframe, left, right, page, sectionvisible)
	pageframe = S.new("CanvasGroup", {
		Parent = S.content,

		Size = UDim2.fromScale(1, 1),

		BackgroundTransparency = 1,
		GroupTransparency = 1,

		Visible = false,

		ZIndex = 12,
	})

	left = S.new("ScrollingFrame", {
		Parent = pageframe,

		Size = UDim2.new(0.5, -6, 1, 0),

		BackgroundTransparency = 1,
		BorderSizePixel = 0,

		CanvasSize = UDim2.fromOffset(0, 0),

		ScrollBarThickness = 0,

		ScrollingDirection = Enum.ScrollingDirection.Y,

		ZIndex = 12,
	})

	right = S.new("ScrollingFrame", {
		Parent = pageframe,

		AnchorPoint = Vector2.new(1, 0),

		Position = UDim2.fromScale(1, 0),

		Size = UDim2.new(0.5, -6, 1, 0),

		BackgroundTransparency = 1,
		BorderSizePixel = 0,

		CanvasSize = UDim2.fromOffset(0, 0),

		ScrollBarThickness = 0,

		ScrollingDirection = Enum.ScrollingDirection.Y,

		ZIndex = 12,
	})

	page = {
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

	page.scrollupdates.left = S.createscrollbar(pageframe, left, "left")

	page.scrollupdates.right = S.createscrollbar(pageframe, right, "right")

	sectionvisible = function(section)
		return not section.floating and (section.dragging or section.frame.Visible)
	end

	function page:invalidateorder() self.ordercache = nil end

	function page:sorted(column, excluded, result, filtered)
		if not self.ordercache then self.ordercache = {} end
		result = self.ordercache[column]
		if not result then
			result = {}
			for _, section in ipairs(self.sections) do
				if section.column == column and section.frame.Parent then
					result[#result + 1] = section
				end
			end
			table.sort(result, S.sectionorderless)
			self.ordercache[column] = result
		end
		if not excluded then return result end
		filtered = {}
		for _, section in ipairs(result) do
			if section ~= excluded then filtered[#filtered + 1] = section end
		end
		return filtered
	end

	function page:normalize(column, index)
		self:invalidateorder()
		index = 0

		for _, section in ipairs(self:sorted(column)) do
			index += 1
			section.order = index
		end
	end

	S.__blush_section_reflow_tweens = S.__blush_section_reflow_tweens
		or setmetatable({}, { __mode = "k" })

	function page:reflow(column, animate, immediate, y, scroll, bottompadding, target, previous, animation)
		if not immediate then
			S.queuepagelayout(self, column, animate)
			return
		end
		if S.pendingpagelayouts[self] then S.pendingpagelayouts[self][column] = nil end
		animate = animate and not S.windowresize and not S.sidebarresize and not S.constructing
		

		y = 0

		for _, section in ipairs(self:sorted(column)) do
			if sectionvisible(section) then
				section.targety = y

				target = UDim2.fromOffset(0, y)

				previous = S.__blush_section_reflow_tweens[section]
				if previous then
					previous:Cancel()
					S.__blush_section_reflow_tweens[section] = nil
				end

				if
					animate
					and section.frame.Position ~= target
					and not section.dragging
					and section.frame.Visible
				then
					animation =
						S.tween(section.frame, { Position = target }, S.sectionti)
					S.__blush_section_reflow_tweens[section] = animation
				else
					if section.frame.Position ~= target then section.frame.Position = target end
				end

				y += (section.targetheight or section.frame.Size.Y.Offset) + 10
			end
		end

		if y > 0 then
			y -= 10
		end

		scroll = self[column]

		bottompadding = 0

		if animate then
			scroll.CanvasSize = UDim2.fromOffset(
				0,
				math.max(scroll.CanvasSize.Y.Offset, y + bottompadding, scroll.AbsoluteSize.Y)
			)
		else
			scroll.CanvasSize = UDim2.fromOffset(0, math.max(y + bottompadding, scroll.AbsoluteSize.Y))
		end

		-- CanvasSize and AbsoluteSize signals own scrollbar refreshes.
	end

	function page:reflowall(animate, immediate)
		self:reflow("left", animate, immediate)
		self:reflow("right", animate, immediate)
	end

	left:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		if left.Parent and true and not S.windowresize and not S.sidebarresize then
page:reflow("left", false)
end
	end)

	right:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		if right.Parent and true and not S.windowresize and not S.sidebarresize then
page:reflow("right", false)
end
	end)

	S.pages[name] = page

	return page
end

function S.fadepage(page, transparency, callback, previous, animation)
	previous = page.fadeanimation
	page.fadeanimation = nil

	if previous then previous:Cancel() end

	animation = S.tween(page.frame, { GroupTransparency = transparency }, S.hoverti)

	page.fadeanimation = animation

	if not animation then
		if callback then callback() end
		return
	end

	animation.Completed:Connect(function()
		if page.fadeanimation ~= animation then return end

		page.fadeanimation = nil
		if callback then callback() end
	end)
end

function S.showpage(name, page, previous, hassubtitle, wasvisible)
	page = S.pages[name]

	if not page or page == S.currentpage then return end

	S.closepopup()

	previous = S.currentpage
	S.currentpage = page

	S.titleprimary.Text = page.primary

	hassubtitle = page.secondary ~= nil and page.secondary ~= ""
	S.arrowholder.Visible = hassubtitle
	S.titlesecondary.Visible = hassubtitle
	S.titlesecondary.Text = page.secondary or ""

	if S.updatetopnavigationstate then S.updatetopnavigationstate() end

	if previous then
		S.fadepage(previous, 1, function()
			if previous ~= S.currentpage then previous.frame.Visible = false end
		end)
	end

	wasvisible = page.frame.Visible
	page.frame.Visible = true
	page.frame.Position = UDim2.fromOffset(0, 0)
	if not wasvisible then page.frame.GroupTransparency = 1 end
	page:reflowall(false)
	S.fadepage(page, 0)

	S.search.Text = ""
end

-- checkbox

S.__blush_checkboxstates = S.__blush_checkboxstates or setmetatable({}, { __mode = "k" })

function S.refreshcheckboxcolors(
	animate,
	info,
	checked,
	strokecolor,
	strokebase,
	fillbase,
	checkbase,
	glowbase
)
	info = animate == true and S.animationsenabled and S.checkti or nil

	for box, data in pairs(S.__blush_checkboxstates) do
		if not box.Parent then
			S.__blush_checkboxstates[box] = nil
		else
			checked = data.checked == true
			strokecolor = checked and S.theme.white or S.theme.border
			strokebase = checked and 0.26 or 0.4
			fillbase = checked and 0 or 1
			checkbase = checked and 0.02 or 1
			glowbase = checked and 0.64 or 1

			if data.stroke and data.stroke.Parent then
				S.syncbinding(data.stroke, "Color", strokecolor)

				if checked then
					S.registeraccentalpha(data.stroke, "Color", "white")
					S.setaccentalphabase(data.stroke, "Transparency", strokebase)
				else
					S.__blush_accent_alpha[data.stroke] = nil
				end

				if info then
					S.tween(data.stroke, {
						Color = strokecolor,
						Transparency = checked and S.effectiveaccentalpha(strokebase) or strokebase,
					}, info, true)
				else
					data.stroke.Color = strokecolor
					data.stroke.Transparency = checked and S.effectiveaccentalpha(strokebase)
						or strokebase
				end
			end

			if data.fill and data.fill.Parent then
				S.syncbinding(data.fill, "BackgroundColor3", S.theme.white, "white")
				S.registeraccentalpha(data.fill, "BackgroundColor3", "white")
				S.setaccentalphabase(data.fill, "BackgroundTransparency", fillbase)

				if info then
					S.tween(data.fill, {
						BackgroundColor3 = S.theme.white,
						BackgroundTransparency = S.effectiveaccentalpha(fillbase),
					}, info, true, { BackgroundColor3 = "white" })
				else
					data.fill.BackgroundColor3 = S.theme.white
					data.fill.BackgroundTransparency = S.effectiveaccentalpha(fillbase)
				end
			end

			if data.glow and data.glow.Parent then
				if info then
					S.tween(data.glow, {
						Color = S.theme.white,
						Transparency = glowbase,
					}, info, true, { Color = "white" })
				else
					data.glow.Color = S.theme.white
					data.glow.Transparency = glowbase
				end
			end

			if data.check and data.check.Parent then
				S.syncbinding(data.check, "ImageColor3", S.theme.black, "black")
				S.registeraccentalpha(data.check, "ImageColor3", "black")
				S.setaccentalphabase(data.check, "ImageTransparency", checkbase)

				if info then
					S.tween(data.check, {
						ImageColor3 = S.theme.black,
						ImageTransparency = S.effectiveaccentalpha(checkbase),
					}, info, true, { ImageColor3 = "black" })
				else
					data.check.ImageColor3 = S.theme.black
					data.check.ImageTransparency = S.effectiveaccentalpha(checkbase)
				end
			end
		end
	end
end

function S.makecheckbox(
	parentobject,
	size,
	default,
	checked,
	stroketween,
	glowtween,
	filltween,
	checktween,
	box,
	boxstroke,
	fill,
	checkedglow,
	check,
	checkboxstate,
	render
)
	checked = default == true
	stroketween = nil
	glowtween = nil
	filltween = nil
	checktween = nil

	box = S.new("Frame", {
		Parent = parentobject,
		Size = UDim2.fromOffset(size, size),
		BackgroundColor3 = S.theme.input,
		BorderSizePixel = 0,
		ZIndex = 16,
	}, { BackgroundColor3 = "input" })
	S.corner(box, 5)

	boxstroke =
		S.stroke(box, checked and 0.26 or 0.4, checked and S.theme.white or S.theme.border, 0.7)

	fill = S.new("Frame", {
		Parent = box,
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = S.theme.white,
		BackgroundTransparency = checked and 0 or 1,
		BorderSizePixel = 0,
		ZIndex = 17,
	}, { BackgroundColor3 = "white" })
	S.corner(fill, 5)

	checkedglow = S.addshadow(fill, "CheckedGlow", checked and 0.64 or 1, 7, 1, -1)

	check = S.new("ImageLabel", {
		Parent = box,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, -0.5, 0.5, 0.333),
		Size = UDim2.fromOffset(math.max(size - 4, 12), math.max(size - 4, 12)),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Image = S.icons.check,
		ImageColor3 = S.theme.black,
		ImageTransparency = checked and 0.02 or 1,
		ScaleType = Enum.ScaleType.Fit,
		ZIndex = 18,
	}, { ImageColor3 = "black" })

	checkboxstate = {
		checked = checked,
		stroke = boxstroke,
		fill = fill,
		glow = checkedglow,
		check = check,
	}

	S.__blush_checkboxstates[box] = checkboxstate

	render = function(
		value,
		nextchecked,
		changed,
		strokecolor,
		strokebase,
		glowbase,
		fillbase,
		checkbase,
		stroketarget,
		filltarget,
		checktarget,
		currentstroke,
		currentglow,
		currentfill,
		currentcheck
	)
		nextchecked = value == true
		changed = nextchecked ~= checked
		checked = nextchecked
		checkboxstate.checked = checked

		for _, active in ipairs({ stroketween, glowtween, filltween, checktween }) do
			if active then active:Cancel() end
		end
		stroketween, glowtween, filltween, checktween = nil, nil, nil, nil

		strokecolor = checked and S.theme.white or S.theme.border
		strokebase = checked and 0.26 or 0.4
		glowbase = checked and 0.64 or 1
		fillbase = checked and 0 or 1
		checkbase = checked and 0.02 or 1

		if boxstroke then
			S.syncbinding(boxstroke, "Color", strokecolor)
			if checked then
				S.registeraccentalpha(boxstroke, "Color", "white")
				S.setaccentalphabase(boxstroke, "Transparency", strokebase)
			else
				S.__blush_accent_alpha[boxstroke] = nil
			end
		end

		S.registeraccentalpha(fill, "BackgroundColor3", "white")
		S.setaccentalphabase(fill, "BackgroundTransparency", fillbase)
		S.registeraccentalpha(check, "ImageColor3", "black")
		S.setaccentalphabase(check, "ImageTransparency", checkbase)

		stroketarget = checked and S.effectiveaccentalpha(strokebase) or strokebase
		filltarget = S.effectiveaccentalpha(fillbase)
		checktarget = S.effectiveaccentalpha(checkbase)

		if not changed or not S.animationsenabled then
			if boxstroke then
				boxstroke.Color = strokecolor
				boxstroke.Transparency = stroketarget
			end
			if checkedglow then
				checkedglow.Color = S.theme.white
				checkedglow.Transparency = glowbase
			end
			fill.BackgroundColor3 = S.theme.white
			fill.BackgroundTransparency = filltarget
			check.ImageColor3 = S.theme.black
			check.ImageTransparency = checktarget
			return
		end

		if boxstroke then
			stroketween = S.tween(boxstroke, {
				Color = strokecolor,
				Transparency = stroketarget,
			}, S.checkti, true)
		end

		if checkedglow then
			glowtween = S.tween(checkedglow, {
				Color = S.theme.white,
				Transparency = glowbase,
			}, S.checkti, true, { Color = "white" })
		end

		filltween = S.tween(fill, {
			BackgroundColor3 = S.theme.white,
			BackgroundTransparency = filltarget,
		}, S.checkti, true, { BackgroundColor3 = "white" })

		checktween = S.tween(check, {
			ImageColor3 = S.theme.black,
			ImageTransparency = checktarget,
		}, S.checkti, true, { ImageColor3 = "black" })

		currentstroke = stroketween
		if currentstroke then
			currentstroke.Completed:Connect(function()
				if stroketween == currentstroke then stroketween = nil end
			end)
		end

		currentglow = glowtween
		if currentglow then
			currentglow.Completed:Connect(function()
				if glowtween == currentglow then glowtween = nil end
			end)
		end

		currentfill = filltween
		if currentfill then
			currentfill.Completed:Connect(function()
				if filltween == currentfill then filltween = nil end
			end)
		end

		currentcheck = checktween
		if currentcheck then
			currentcheck.Completed:Connect(function()
				if checktween == currentcheck then checktween = nil end
			end)
		end
	end

	return box, render
end

function S.colorbyte(value) return math.clamp(math.floor(value * 255 + 0.5), 0, 255) end

function S.parsergba(value, r, g, b, a)
	r, g, b, a = tostring(value or ""):match(
		"^%s*([%+%-]?%d+)%s*,%s*([%+%-]?%d+)%s*,%s*([%+%-]?%d+)%s*,%s*([%+%-]?%d+)%s*$"
	)

	if not r then return nil end

	r = math.clamp(tonumber(r) or 0, 0, 255)
	g = math.clamp(tonumber(g) or 0, 0, 255)
	b = math.clamp(tonumber(b) or 0, 0, 255)
	a = math.clamp(tonumber(a) or 0, 0, 255)

	return Color3.fromRGB(r, g, b), a / 255
end

function S.parsehexalpha(value, hex, r, g, b, a)
	hex = tostring(value or ""):gsub("%s+", ""):gsub("^#", "")

	if #hex ~= 8 or not hex:match("^%x%x%x%x%x%x%x%x$") then return nil end

	r = tonumber(hex:sub(1, 2), 16)
	g = tonumber(hex:sub(3, 4), 16)
	b = tonumber(hex:sub(5, 6), 16)
	a = tonumber(hex:sub(7, 8), 16)

	if not r or not g or not b or not a then return nil end

	return Color3.fromRGB(r, g, b), a / 255
end

-- colorpicker state

function S.createcolorstate(color, callback, swatch, h, s, v, state)
	h, s, v = color:ToHSV()

	state = {
		h = h,
		s = s,
		v = v,

		alpha = 1,

		fadevalue = 1,
		fadedirection = -1,

		fading = false,
		rainbow = false,

		dragging = false,
		dragtype = nil,

		callback = callback,
		swatch = swatch,
		swatchglow = nil,

		popup = nil,
	}

	function state:color()
		if self.cachedh ~= self.h or self.cacheds ~= self.s or self.cachedv ~= self.v then
			self.cachedh, self.cacheds, self.cachedv = self.h, self.s, self.v
			self.cachedcolor = Color3.fromHSV(self.h, self.s, self.v)
		end
		return self.cachedcolor
	end

	function state:currentalpha()
		if self.fading then return self.fadevalue end

		return self.alpha
	end

	function state:syncinputs(force, popup, colorvalue, alphavalue, r, g, b, a)
		popup = self.popup

		if not popup or not popup.panel or not popup.panel.Parent or popup.inputupdating then
			return
		end

		colorvalue = self:color()
		alphavalue = self:currentalpha()
		r, g, b, a =
			S.colorbyte(colorvalue.R),
			S.colorbyte(colorvalue.G),
			S.colorbyte(colorvalue.B),
			S.colorbyte(alphavalue)
		if self.inputr ~= r or self.inputg ~= g or self.inputb ~= b or self.inputa ~= a then
			self.inputr, self.inputg, self.inputb, self.inputa = r, g, b, a
			self.cachedrgba = string.format("%d, %d, %d, %d", r, g, b, a)
			self.cachedhex = string.format("#%02X%02X%02X%02X", r, g, b, a)
		end
		popup.inputupdating = true
		if (force or not popup.rgba:IsFocused()) and popup.rgba.Text ~= self.cachedrgba then
			popup.rgba.Text = self.cachedrgba
		end
		if (force or not popup.hex:IsFocused()) and popup.hex.Text ~= self.cachedhex then
			popup.hex.Text = self.cachedhex
		end

		popup.inputupdating = false
	end

	function state:emit(force, color2, alpha, continuous, now, previous, ok, message)
		color2, alpha = self:color(), self:currentalpha()
		if self.emittedcolor == color2 and self.emittedalpha == alpha then return end
		continuous = self.dragging or self.rainbow or self.fading
		now = os.clock()
		if continuous and not force and self.lastemit and now - self.lastemit < 1 / 60 then
			return
		end
		self.lastemit, self.emittedcolor, self.emittedalpha = now, color2, alpha
		if self.callback and not S.constructing then
			previous = S.continuouscolorupdate
			S.continuouscolorupdate = continuous and not force
			ok, message = pcall(self.callback, color2, alpha)
			S.continuouscolorupdate = previous
			if not ok then error(message, 0) end
		end
	end

	function state:apply(
		force,
		colorvalue,
		alphavalue,
		changed,
		initialized,
		previous,
		ok,
		message,
		popup
	)
		colorvalue = self:color()

		alphavalue = self:currentalpha()

		changed = self.lastcolor ~= colorvalue or self.lastalpha ~= alphavalue
		initialized = self.lastcolor ~= nil
		self.lastcolor, self.lastalpha = colorvalue, alphavalue
		if initialized then
			if changed and self.propagate then
				previous = S.continuouscolorupdate
				S.continuouscolorupdate = self.dragging or self.rainbow or self.fading
				ok, message = pcall(self.propagate, colorvalue, alphavalue)
				S.continuouscolorupdate = previous
				if not ok then error(message, 0) end
			end
			self:emit(force)
		else
			self.emittedcolor, self.emittedalpha = colorvalue, alphavalue
		end

		if changed and self.swatch then
			self.swatch.BackgroundColor3 = colorvalue

			self.swatch.BackgroundTransparency = math.clamp(1 - alphavalue, 0, 1)

			if self.swatchglow then
				self.swatchglow.Color = colorvalue
				self.swatchglow.Transparency = math.clamp(0.58 + (1 - alphavalue) * 0.26, 0.58, 0.9)
			end
		end

		if changed and self.hotkeybinding then S.requesthotkeyrefresh(self.hotkeybinding) end

		popup = self.popup

		if not popup or not popup.panel or not popup.panel.Parent then return end

		if
			not changed
			and popup.lasth == self.h
			and popup.lasts == self.s
			and popup.lastv == self.v
		then
			return
		end
		popup.lasth, popup.lasts, popup.lastv = self.h, self.s, self.v

		popup.sv.BackgroundColor3 = Color3.fromHSV(self.h, 1, 1)

		popup.svcursor.Position = UDim2.fromScale(self.s, 1 - self.v)

		popup.huecursor.Position = UDim2.fromScale(self.h, 0.5)

		popup.alphafield.BackgroundColor3 = colorvalue

		popup.alphacursor.Position = UDim2.fromScale(alphavalue, 0.5)

		if popup.svglow then popup.svglow.Color = colorvalue end

		if popup.hueglow then popup.hueglow.Color = Color3.fromHSV(self.h, 1, 1) end

		if popup.alphaglow then popup.alphaglow.Color = colorvalue end

		self:syncinputs(false)
	end

	function state:refresh()
		if self.fading or self.rainbow then
			S.animatedpickers[self] = true
			S.ensurepickeranimationloop()
		else
			S.animatedpickers[self] = nil

			self.fadevalue = self.alpha
		end

		self:apply()
	end

	function state:Set(colorvalue, alphavalue, fire, callback2, propagate)
		self.h, self.s, self.v = colorvalue:ToHSV()

		if alphavalue ~= nil then
			self.alpha = math.clamp(alphavalue, 0, 1)
			self.fadevalue = self.alpha
			if not self.fading then self.fadedirection = -1 end
		end

		if fire == false then
			callback2, propagate = self.callback, self.propagate
			self.callback, self.propagate = nil, nil
			self:apply(true)
			self.callback, self.propagate = callback2, propagate
		else
			self:apply(true)
			if self.onpersist then self.onpersist() end
		end
	end

	function state:update(dt, active, step, nextvalue)
		if not self.swatch or not self.swatch.Parent then
			S.animatedpickers[self] = nil
			return
		end

		active = false

		-- Manual SV movement must not pause either automatic mode.
		-- Hue pauses only Rainbow; alpha pauses only Fading.
		if self.rainbow then
			if self.dragtype ~= "hue" then self.h = (self.h + dt * 0.27) % 1 end
			active = true
		end

		if self.fading then
			if self.dragtype ~= "alpha" then
				step = dt * 0.52
				nextvalue = self.fadevalue + step * self.fadedirection

				if self.fadedirection < 0 and nextvalue <= 0 then
					self.fadevalue = 0
					self.fadedirection = 1
				elseif self.fadedirection > 0 and nextvalue >= 1 then
					self.fadevalue = 1
					self.fadedirection = -1
				else
					self.fadevalue = math.clamp(nextvalue, 0, 1)
				end
			end
			active = true
		end

		if not active then
			S.animatedpickers[self] = nil
			return
		end

		self:apply()
	end

	if swatch then
		swatch.Destroying:Connect(function(input)
			S.animatedpickers[state] = nil
			state.fading = false
			state.rainbow = false
			state.dragging = false
			state.dragtype = nil

			if S.pickerdrag and S.pickerdrag.state == state then
				input = S.pickerdrag.input
				S.pickerdrag = nil
				S.releaseinteraction(input)
			end

			if state.popup and S.activepopup == state.popup then S.closepopup() end

			state.popup = nil
			state.swatch = nil
			state.swatchglow = nil
			state.callback = nil
			state.propagate = nil
			state.onpersist = nil

			if next(S.animatedpickers) == nil then S.stoppickeranimationloop() end
		end)
	end

	return state
end

function S.opencolorpicker(
	anchor,
	state,
	anchorpos,
	anchorsize,
	width,
	height,
	x,
	y,
	panel,
	popup,
	svholder,
	sv,
	white,
	black,
	svcursor,
	svglow,
	svhit,
	colorslider,
	rainbowsequence,
	hueholder,
	_2,
	huecursor,
	huehit,
	hueglow,
	alphaholder,
	alphafield,
	alphacursor,
	alphahit,
	alphaglow,
	inputrow,
	colorinput,
	rgba,
	hex,
	options,
	optiontoggle,
	commitcolorinput,
	updatepicker,
	beginpicker
)
	anchorpos = S.overlayposition(anchor)

	anchorsize = anchor.AbsoluteSize

	width = 244
	height = 266

	x = anchorpos.X + anchorsize.X - width

	y = anchorpos.Y + anchorsize.Y + 6

	x = math.clamp(x, 8, math.max(8, S.popuplayer.AbsoluteSize.X - width - 8))

	y = math.clamp(y, 8, math.max(8, S.popuplayer.AbsoluteSize.Y - height - 8))

	panel, popup = S.createpopup(Vector2.new(x, y), width, height, 520, "color")

	svholder = S.new("Frame", {
		Parent = panel,

		Position = UDim2.fromOffset(10, 10),

		Size = UDim2.new(1, -20, 0, 126),

		BackgroundTransparency = 1,
		BorderSizePixel = 0,

		ClipsDescendants = false,

		ZIndex = 524,
	})

	sv = S.rawnew("CanvasGroup", {
		Parent = svholder,

		Size = UDim2.fromScale(1, 1),

		BackgroundColor3 = Color3.fromHSV(state.h, 1, 1),

		GroupTransparency = 0,
		BorderSizePixel = 0,

		ClipsDescendants = true,

		ZIndex = 524,
	})

	S.corner(sv, 7)

	white = S.rawnew("Frame", {
		Parent = sv,

		Size = UDim2.fromScale(1, 1),

		BackgroundColor3 = Color3.new(1, 1, 1),

		BorderSizePixel = 0,

		ZIndex = 525,
	})

	black = S.rawnew("Frame", {
		Parent = sv,

		Size = UDim2.fromScale(1, 1),

		BackgroundColor3 = Color3.new(0, 0, 0),

		BorderSizePixel = 0,

		ZIndex = 526,
	})

	S.new("UIGradient", {
		Parent = white,

		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),

			NumberSequenceKeypoint.new(1, 1),
		}),
	})

	S.new("UIGradient", {
		Parent = black,

		Rotation = 90,

		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),

			NumberSequenceKeypoint.new(1, 0),
		}),
	})

	svcursor = S.rawnew("Frame", {
		Parent = svholder,

		AnchorPoint = Vector2.new(0.5, 0.5),

		Position = UDim2.fromScale(state.s, 1 - state.v),

		Size = UDim2.fromOffset(9, 9),

		BackgroundColor3 = Color3.fromRGB(248, 248, 250),

		BorderSizePixel = 0,

		ZIndex = 530,
	})

	S.corner(svcursor, 999)
	S.rawnew("UIStroke", {
		Parent = svcursor,
		Color = Color3.fromRGB(14, 14, 15),
		Transparency = 0.2,
		Thickness = 1,
	})
	svglow = S.addshadow(
		svcursor,
		"PickerGlow",
		0.68,
		6,
		1,
		-1,
		Color3.fromRGB(248, 248, 250),
		UDim2.fromOffset(0, 0),
		false
	)

	svhit = S.new("TextButton", {
		Parent = svholder,

		Size = UDim2.fromScale(1, 1),

		BackgroundTransparency = 1,
		BorderSizePixel = 0,

		Text = "",
		AutoButtonColor = false,

		ZIndex = 531,
	})

	colorslider = function(
		yposition,
		colorsequence,
		transparencysequence,
		value,
		backgroundcolor,
		holder,
		field,
		gradient,
		cursor,
		cursorglow,
		hit
	)
		holder = S.new("Frame", {
			Parent = panel,

			Position = UDim2.fromOffset(10, yposition),

			Size = UDim2.new(1, -20, 0, 14),

			BackgroundTransparency = 1,
			BorderSizePixel = 0,

			ZIndex = 524,
		})

		field = S.rawnew("Frame", {
			Parent = holder,

			Size = UDim2.fromScale(1, 1),

			BackgroundColor3 = backgroundcolor or Color3.fromRGB(248, 248, 250),

			BorderSizePixel = 0,

			ClipsDescendants = true,

			ZIndex = 524,
		})

		S.corner(field, 4)

		gradient = S.new("UIGradient", {
			Parent = field,

			Transparency = transparencysequence or NumberSequence.new(0),
		})

		if colorsequence then gradient.Color = colorsequence end

		cursor = S.rawnew("Frame", {
			Parent = holder,

			AnchorPoint = Vector2.new(0.5, 0.5),

			Position = UDim2.fromScale(value, 0.5),

			Size = UDim2.fromOffset(4, 18),

			BackgroundColor3 = Color3.fromRGB(248, 248, 250),

			BorderSizePixel = 0,

			ZIndex = 530,
		})

		S.corner(cursor, 2)
		cursorglow = S.addshadow(
			cursor,
			"PickerGlow",
			0.72,
			5,
			1,
			-1,
			Color3.fromRGB(248, 248, 250),
			UDim2.fromOffset(0, 0),
			false
		)

		hit = S.new("TextButton", {
			Parent = holder,

			Size = UDim2.fromScale(1, 1),

			BackgroundTransparency = 1,
			BorderSizePixel = 0,

			Text = "",
			AutoButtonColor = false,

			ZIndex = 531,
		})

		return holder, field, cursor, hit, cursorglow
	end

	rainbowsequence = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 1, 1)),

		ColorSequenceKeypoint.new(1 / 6, Color3.fromHSV(1 / 6, 1, 1)),

		ColorSequenceKeypoint.new(2 / 6, Color3.fromHSV(2 / 6, 1, 1)),

		ColorSequenceKeypoint.new(3 / 6, Color3.fromHSV(3 / 6, 1, 1)),

		ColorSequenceKeypoint.new(4 / 6, Color3.fromHSV(4 / 6, 1, 1)),

		ColorSequenceKeypoint.new(5 / 6, Color3.fromHSV(5 / 6, 1, 1)),

		ColorSequenceKeypoint.new(1, Color3.fromHSV(1, 1, 1)),
	})

	hueholder, _2, huecursor, huehit, hueglow = colorslider(147, rainbowsequence, nil, state.h)

	alphaholder, alphafield, alphacursor, alphahit, alphaglow = colorslider(
		176,
		nil,
		NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),

			NumberSequenceKeypoint.new(1, 0),
		}),
		state:currentalpha(),
		state:color()
	)

	inputrow = S.new("Frame", {
		Parent = panel,
		Position = UDim2.fromOffset(10, 198),
		Size = UDim2.new(1, -20, 0, 27),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 524,
	})

	colorinput = function(position, size, placeholder, box)
		box = S.new("TextBox", {
			Parent = inputrow,
			Position = position,
			Size = size,
			BackgroundColor3 = S.theme.input,
			BackgroundTransparency = 0.04,
			BorderSizePixel = 0,
			Text = "",
			PlaceholderText = placeholder,
			PlaceholderColor3 = S.theme.text3,
			TextColor3 = S.theme.text2,
			Font = S.font,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
			ClearTextOnFocus = false,
			MultiLine = false,
			ZIndex = 525,
		}, { BackgroundColor3 = "input", PlaceholderColor3 = "text3", TextColor3 = "text2" })

		S.corner(box, 6)
		S.stroke(box, 0.72, S.theme.border, 0.55)

		S.new("UIPadding", {
			Parent = box,
			PaddingLeft = UDim.new(0, 8),
			PaddingRight = UDim.new(0, 8),
		})

		return box
	end

	rgba = colorinput(UDim2.fromOffset(0, 0), UDim2.new(0.5, -3, 1, 0), "RGBA")

	hex = colorinput(UDim2.new(0.5, 3, 0, 0), UDim2.new(0.5, -3, 1, 0), "HEX")

	options = S.new("Frame", {
		Parent = panel,

		Position = UDim2.fromOffset(10, 231),

		Size = UDim2.new(1, -20, 0, 27),

		BackgroundTransparency = 1,

		ZIndex = 524,
	})

	optiontoggle = function(name, position, getter, setter, button3, box, render, textobject)
		button3 = S.new("TextButton", {
			Parent = options,

			Position = position,

			Size = UDim2.new(0.5, -6, 1, 0),

			BackgroundTransparency = 1,
			BorderSizePixel = 0,

			Text = "",
			AutoButtonColor = false,

			ZIndex = 525,
		})

		box, render = S.makecheckbox(button3, 17, getter())

		box.AnchorPoint = Vector2.new(0, 0.5)

		box.Position = UDim2.new(0, 0, 0.5, 0)

		textobject = S.label(button3, name, UDim2.new(1, -30, 1, 0), S.font, S.theme.text2)

		textobject.Position = UDim2.fromOffset(30, 0)

		textobject.TextSize = 15
		textobject.ZIndex = 526

		button3.Activated:Connect(function(value)
			value = not getter()

			setter(value)
			render(value)

			state:refresh()
			state:emit(true)
			S.saveuisettings()

			if state.onpersist then state.onpersist() end
		end)
	end

	optiontoggle(
		"Fading",
		UDim2.fromOffset(0, 0),
		function() return state.fading end,
		function(value)
			if value then
				state.fadevalue = state.alpha
				state.fadedirection = -1
				state.fading = true
			else
				state.alpha = math.clamp(state.fadevalue, 0, 1)
				state.fading = false
			end
		end
	)

	optiontoggle(
		"Rainbow",
		UDim2.new(0.5, 6, 0, 0),
		function() return state.rainbow end,
		function(value) state.rainbow = value end
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

	commitcolorinput = function(box, parser, normalize, colorvalue, alphavalue)
		if state.popup == nil or state.popup.inputupdating then return false end

		colorvalue, alphavalue = parser(box.Text)

		if not colorvalue then
			if normalize then state:syncinputs(true) end
			return false
		end

		state:Set(colorvalue, alphavalue, true)

		if normalize then state:syncinputs(true) end

		return true
	end

	rgba:GetPropertyChangedSignal("Text"):Connect(function()
		if rgba:IsFocused() and state.popup and not state.popup.inputupdating then
			commitcolorinput(rgba, S.parsergba, false)
		end
	end)

	hex:GetPropertyChangedSignal("Text"):Connect(function()
		if hex:IsFocused() and state.popup and not state.popup.inputupdating then
			commitcolorinput(hex, S.parsehexalpha, false)
		end
	end)

	rgba.FocusLost:Connect(function() commitcolorinput(rgba, S.parsergba, true) end)

	hex.FocusLost:Connect(function() commitcolorinput(hex, S.parsehexalpha, true) end)

	updatepicker = function(drag, position, localposition, value)
		localposition = position - drag.holder.AbsolutePosition

		if drag.type == "sv" then
			state.s = math.clamp(localposition.X / drag.holder.AbsoluteSize.X, 0, 1)

			state.v = 1 - math.clamp(localposition.Y / drag.holder.AbsoluteSize.Y, 0, 1)
		elseif drag.type == "hue" then
			state.h = math.clamp(localposition.X / drag.holder.AbsoluteSize.X, 0, 1)
		elseif drag.type == "alpha" then
			value = math.clamp(localposition.X / drag.holder.AbsoluteSize.X, 0, 1)

			state.alpha = value
			state.fadevalue = value
		end

		state:apply()
	end

	beginpicker = function(input, typename, holder, cursor)
		if not S.acquireinteraction("colorpicker", input) then return end

		state.dragging = true
		state.dragtype = typename
		state:refresh()

		S.pickerdrag = {
			input = input,

			type = typename,

			holder = holder,
			cursor = cursor,

			state = state,

			update = updatepicker,
		}

		updatepicker(S.pickerdrag, S.point(input))
	end

	svhit.InputBegan:Connect(function(input)
		if
			input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch
		then
			return
		end

		beginpicker(input, "sv", svholder, svcursor)
	end)

	huehit.InputBegan:Connect(function(input)
		if
			input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch
		then
			return
		end

		beginpicker(input, "hue", hueholder, huecursor)
	end)

	alphahit.InputBegan:Connect(function(input)
		if
			input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch
		then
			return
		end

		beginpicker(input, "alpha", alphaholder, alphacursor)
	end)

	popup.onclose = function(draginput)
		draginput = S.pickerdrag and S.pickerdrag.state == state and S.pickerdrag.input or nil

		state.dragging = false
		state.dragtype = nil
		state:emit(true)
		S.saveuisettings()
		if state.onpersist then state.onpersist() end
		state.popup = nil

		if S.pickerdrag and S.pickerdrag.state == state then S.pickerdrag = nil end

		if draginput then S.releaseinteraction(draginput) end
	end

	state:refresh()
end

-- section movement

function S.sectiontargetindex(page, column, excluded, y, items, visible, scroll, index, center)
	items = page:sorted(column, excluded)

	visible = {}

	for _, section in ipairs(items) do
		if section.frame.Visible then table.insert(visible, section) end
	end

	scroll = page[column]

	index = #visible + 1

	for i, section in ipairs(visible) do
		center = scroll.AbsolutePosition.Y
			+ (section.targety or section.frame.Position.Y.Offset)
			- scroll.CanvasPosition.Y
			+ (section.targetheight or section.frame.Size.Y.Offset) / 2

		if y < center then
			index = i
			break
		end
	end

	return index, visible
end

function S.movesection(section, column, index, page, oldcolumn, targetitems, visible, orderlist)
	page = section.page

	oldcolumn = section.column

	targetitems = page:sorted(column, section)

	visible = {}

	for _, object in ipairs(targetitems) do
		if object.frame.Visible then table.insert(visible, object) end
	end

	index = math.clamp(index, 1, #visible + 1)

	section.column = column
	page:invalidateorder()

	if section.frame.Parent ~= page[column] then section.frame.Parent = page[column] end

	orderlist = {}

	for _, object in ipairs(page:sorted(column, section)) do
		if object.frame.Visible then table.insert(orderlist, object) end
	end

	table.insert(orderlist, index, section)

	for i, object in ipairs(orderlist) do
		object.order = i
	end

	page:normalize(column)

	if oldcolumn ~= column then
		page:normalize(oldcolumn)

		page:reflow(oldcolumn, true)
	end

	page:reflow(column, true)
end

function S.transfersectionpage(section, targetpage, oldpage)
	oldpage = section.page

	if not targetpage or oldpage == targetpage then return end

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
	targetpage:invalidateorder()
end

function S.beginsectiondrag(
	drag,
	section,
	absolute,
	originalsize,
	ghost,
	clone,
	clonedcollapse,
	cloneddivider,
	clonedclip
)
	if S.draglayer and S.draglayer.Parent then S.draglayer.GroupTransparency = 0 end

	section = drag.section

	drag.wascollapsed = section.collapsed

	drag.wasfloating = section.floating == true

	drag.reopen = not section.collapsed and not drag.wasfloating

	absolute = section.frame.AbsolutePosition - S.draglayer.AbsolutePosition

	originalsize = section.frame.AbsoluteSize

	drag.width = originalsize.X
	drag.expandedheight = math.max(43, section.targetheight or originalsize.Y, originalsize.Y)

	drag.grab = drag.current - section.frame.AbsolutePosition

	ghost = S.new("Frame", {
		Parent = S.draglayer,

		Position = UDim2.fromOffset(absolute.X, absolute.Y),

		Size = UDim2.fromOffset(originalsize.X, originalsize.Y),

		BackgroundTransparency = 1,
		BorderSizePixel = 0,

		ClipsDescendants = false,

		ZIndex = 410,
	})

	S.corner(ghost, 10)

	clone = section.frame:Clone()

	clone.Parent = ghost

	clone.Position = UDim2.fromOffset(0, 0)

	clone.Size = UDim2.fromOffset(originalsize.X, originalsize.Y)

	for _, object in ipairs(clone:GetDescendants()) do
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

	drag.previewcolumn = section.column

	drag.previewindex = -1

	if drag.reopen then
		section:SetCollapsed(true, false, true)

		clonedcollapse = clone:FindFirstChild("SectionCollapse", true)

		cloneddivider = clone:FindFirstChild("SectionDivider")

		clonedclip = clone:FindFirstChild("SectionClip")

		if clonedcollapse then
			drag.cloneanimations[#drag.cloneanimations + 1] = S.tween(clonedcollapse, {
				Rotation = -90,
			}, S.tabti)
		end

		if cloneddivider then
			drag.cloneanimations[#drag.cloneanimations + 1] = S.tween(cloneddivider, {
				BackgroundTransparency = 1,
			}, S.tabti)
		end

		if clonedclip then
			clonedclip.ClipsDescendants = true
			drag.cloneanimations[#drag.cloneanimations + 1] = S.tween(clonedclip, {
				Size = UDim2.new(1, 0, 0, 0),
			}, S.tabti)
		end

		drag.cloneanimations[#drag.cloneanimations + 1] = S.tween(clone, {
			Size = UDim2.fromOffset(originalsize.X, 43),
		}, S.tabti)

		drag.ghostsizeanimation =
			S.tween(ghost, { Size = UDim2.fromOffset(originalsize.X, 43) }, S.sectionti)
	end

	section.page:reflow(section.column, true)
end

function S.updatesectiondrag(
	drag,
	section,
	position,
	canattach,
	page,
	centerx,
	centery,
	split,
	column,
	index
)
	section = drag.section

	position = drag.current - drag.grab - S.draglayer.AbsolutePosition

	drag.ghost.Position = UDim2.fromOffset(position.X, position.Y)

	canattach = S.currentpage ~= nil and S.inside(S.window, drag.current)

	drag.outside = not canattach

	if drag.outside then
		if not section.floating then
			section.floating = true

			if section.frame.Parent ~= S.draglayer then section.frame.Parent = S.draglayer end

			section.page:reflow(section.column, true)
		end

		return
	end

	if S.currentpage ~= section.page then S.transfersectionpage(section, S.currentpage) end

	page = section.page

	if section.floating then
		section.floating = false
		section.frame:SetAttribute("BlushDetachedSection", false)
		section.floatingwidth = nil

		if section.shadow then section.shadow.Enabled = false end
	end

	centerx = drag.current.X
	centery = drag.current.Y

	split = (
		page.left.AbsolutePosition.X
		+ page.left.AbsoluteSize.X
		+ page.right.AbsolutePosition.X
	) / 2

	column = centerx < split and "left" or "right"

	index = S.sectiontargetindex(page, column, section, centery)

	if
		column ~= drag.previewcolumn
		or index ~= drag.previewindex
		or section.frame.Parent ~= page[column]
	then
		drag.previewcolumn = column
		drag.previewindex = index

		S.movesection(section, column, index)
	end
end

function S.attachsectiontransition(
	drag,
	section,
	ghost,
	targetparent,
	preservedheight,
	target,
	targetheight,
	targetsize,
	clone,
	clonedcollapse,
	cloneddivider,
	clonedclip,
	visibleheight,
	finished,
	finish,
	animation5
)
	section = drag.section
	ghost = drag.ghost

	if drag.ghostsizeanimation then
		drag.ghostsizeanimation:Cancel()
		drag.ghostsizeanimation = nil
	end

	for _, animation in ipairs(drag.cloneanimations or {}) do
		if animation then animation:Cancel() end
	end
	drag.cloneanimations = nil

	section.floating = false
	section.floatingwidth = nil
	section.frame:SetAttribute("BlushDetachedSection", false)
	section.dragging = true
	section.frame.Visible = false

	if section.shadow then section.shadow.Enabled = false end

	targetparent = section.page[section.column]
	if section.frame.Parent ~= targetparent then section.frame.Parent = targetparent end

	section:SetCollapsed(drag.wascollapsed, false, false)
	if section.RefreshLayout then section:RefreshLayout(false, false) end

	preservedheight = drag.wascollapsed and 43
		or math.max(43, section.targetheight or 43, drag.expandedheight or 43)

	section.targetheight = preservedheight
	section.frame.Size = UDim2.new(1, -7, 0, preservedheight)
	section.clip.Size =
		UDim2.new(1, 0, 0, drag.wascollapsed and 0 or math.max(0, preservedheight - 43))
	section.clip.ClipsDescendants = true
	section.page:reflow(section.column, false, true)
	S.applyuitransparency(S.uitransparency * 100)

	target = section.frame.AbsolutePosition - S.draglayer.AbsolutePosition
	targetheight = preservedheight
	targetsize = UDim2.fromOffset(section.frame.AbsoluteSize.X, targetheight)
	clone = drag.clone

	if clone and clone.Parent then
		clonedcollapse = clone:FindFirstChild("SectionCollapse", true)
		cloneddivider = clone:FindFirstChild("SectionDivider")
		clonedclip = clone:FindFirstChild("SectionClip")
		visibleheight = drag.wascollapsed and 0 or math.max(0, targetheight - 43)

		S.tween(clone, { Size = targetsize }, S.sectionattachti)
		if clonedclip then
			clonedclip.ClipsDescendants = true
			S.tween(clonedclip, { Size = UDim2.new(1, 0, 0, visibleheight) }, S.sectionattachti)
		end
		if clonedcollapse then
			S.tween(clonedcollapse, { Rotation = drag.wascollapsed and -90 or 0 }, S.sectionattachti)
		end
		if cloneddivider then
			S.tween(
				cloneddivider,
				{ BackgroundTransparency = drag.wascollapsed and 1 or 0.52 },
				S.sectionattachti
			)
		end
	end

	finished = false
	finish = function()
		if finished then return end

		finished = true
		section.dragging = false
		section.frame.Visible = true

		if section.RefreshLayout then section:RefreshLayout(false, false) end

		section.clip.ClipsDescendants = section.collapsed
		section.page:reflow(section.column, false)
		S.applyuitransparency(S.uitransparency * 100)

		if ghost and ghost.Parent then ghost:Destroy() end

	end

	if not ghost or not ghost.Parent then
		finish()
		return
	end

	animation5 = S.tween(ghost, {
		Position = UDim2.fromOffset(target.X, target.Y),
		Size = targetsize,
	}, S.sectionattachti)

	if animation5 then
		animation5.Completed:Connect(finish)
	else
		finish()
	end
end

function S.finishsectiondrag(drag, section, floatingposition, viewport, detachedheight, keepheight)
	if S.draglayer and S.draglayer.Parent then S.draglayer.GroupTransparency = 0 end

	drag = S.sectiondrag

	S.sectiondrag = nil

	if drag then S.releaseinteraction(drag.input) end

	if not drag or not drag.started then return end

	section = drag.section

	section.lastdragend = os.clock()
	section.headerdragged = false

	if drag.outside then
		floatingposition = drag.ghost.AbsolutePosition - S.draglayer.AbsolutePosition

		viewport = S.draglayer.AbsoluteSize

		detachedheight = math.max(43, drag.ghost.AbsoluteSize.Y)

		floatingposition = Vector2.new(
			math.clamp(floatingposition.X, 6, math.max(6, viewport.X - drag.width - 6)),
			math.clamp(floatingposition.Y, 6, math.max(6, viewport.Y - detachedheight - 6))
		)

		section.floating = true
		section.frame:SetAttribute("BlushDetachedSection", true)
		section.frame.BackgroundTransparency = S.effectivetransparency(0, "section")
		section.floatingwidth = drag.width

		section.frame.Parent = S.draglayer

		section.frame.Position = UDim2.fromOffset(floatingposition.X, floatingposition.Y)

		keepheight = drag.wasfloating
				and (drag.wascollapsed and 43 or math.max(43, drag.expandedheight or detachedheight))
			or 43

		section.frame.Size = UDim2.fromOffset(drag.width, keepheight)

		section.dragging = false
		section.frame.Visible = true

		if section.shadow then section.shadow.Enabled = true end

		S.applyuitransparency(S.uitransparency * 100)

		if drag.ghost and drag.ghost.Parent then drag.ghost:Destroy() end

		section.page:reflow(section.column, true)

		if drag.wasfloating then
			section:SetCollapsed(drag.wascollapsed, false, false)
			if section.RefreshLayout then section:RefreshLayout(false, false) end
		else
			section:SetCollapsed(drag.wascollapsed, true, false)
		end

		return
	end

	S.attachsectiontransition(drag)
end

-- section

function S.sliderbounds(minimum, maximum, round, factor)
	factor = 10 ^ round
	minimum, maximum = math.min(minimum, maximum), math.max(minimum, maximum)
	if math.ceil(minimum * factor) > math.floor(maximum * factor) then
		minimum = math.round(minimum * factor) / factor
		return minimum, minimum
	end
	return math.ceil(minimum * factor) / factor, math.floor(maximum * factor) / factor
end

function S.roundslider(value, minimum, maximum, round, factor)
	factor = 10 ^ round
	return math.clamp(math.round((tonumber(value) or minimum) * factor) / factor, minimum, maximum)
end

function S.createsection(
	page,
	column,
	titletext,
	sectionicon,
	frame,
	floatingshadow,
	headerobject,
	titleoffset,
	sectionimage,
	titleobject,
	draghandle,
	collapse,
	divider,
	clip,
	body,
	bodylayout,
	section,
	sectiontransition,
	resize,
	register,
	dropdownpopup,
	binddropdownscrollbar
)
	page.order += 1

	frame = S.new("Frame", {
		Parent = page[column],

		Position = UDim2.fromOffset(0, 0),

		Size = UDim2.new(1, -7, 0, 43),

		BackgroundColor3 = S.theme.section,

		BackgroundTransparency = 0,

		BorderSizePixel = 0,

		ZIndex = 13,
	}, { BackgroundColor3 = "section" })

	S.corner(frame, 10)
	S.backgroundsectionframes[frame] = 0
	if S.updatebackgroundsurfaces then S.updatebackgroundsurfaces() end

	floatingshadow = S.adddepthshadow(frame, "floating")

	if floatingshadow then floatingshadow.Enabled = false end

	headerobject = S.new("Frame", {
		Parent = frame,

		Size = UDim2.new(1, 0, 0, 42),

		BackgroundTransparency = 1,

		ZIndex = 14,
	})

	titleoffset = 14
	sectionimage = nil

	if sectionicon then
		sectionimage = S.image(headerobject, sectionicon, 18, S.theme.text2, 15)

		sectionimage.AnchorPoint = Vector2.new(0, 0.5)

		sectionimage.Position = UDim2.fromOffset(14, 21)

		titleoffset = 41
	end

	titleobject = S.label(headerobject, titletext, UDim2.new(1, -titleoffset - 42, 1, 0), S.bold)

	titleobject.Position = UDim2.fromOffset(titleoffset, 0)

	titleobject.TextSize = 17
	titleobject.ZIndex = 15

	draghandle = S.new("TextButton", {
		Parent = headerobject,

		Size = UDim2.new(1, 0, 1, 0),

		BackgroundTransparency = 1,
		BorderSizePixel = 0,

		Text = "",
		AutoButtonColor = false,

		ZIndex = 18,
	})

	collapse = S.new("ImageLabel", {
		Name = "SectionCollapse",
		Parent = headerobject,

		AnchorPoint = Vector2.new(1, 0.5),

		Position = UDim2.new(1, -13, 0.5, 0),

		Size = UDim2.fromOffset(16, 16),

		BackgroundTransparency = 1,
		BorderSizePixel = 0,

		Image = S.icons.down,
		ImageColor3 = S.theme.text3,

		ZIndex = 17,
	}, { ImageColor3 = "text3" })

	divider = S.new("Frame", {
		Name = "SectionDivider",
		Parent = frame,

		Position = UDim2.fromOffset(12, 42),

		Size = UDim2.new(1, -24, 0, 1),

		BackgroundColor3 = S.theme.border,

		BackgroundTransparency = 0.52,

		BorderSizePixel = 0,

		ZIndex = 14,
	}, { BackgroundColor3 = "border" })

	clip = S.new("Frame", {
		Name = "SectionClip",
		Parent = frame,

		Position = UDim2.fromOffset(0, 43),

		Size = UDim2.new(1, 0, 0, 0),

		BackgroundTransparency = 1,
		BorderSizePixel = 0,

		ClipsDescendants = true,

		ZIndex = 14,
	})

	body = S.new("Frame", {
		Parent = clip,

		Size = UDim2.new(1, 0, 0, 0),

		BackgroundTransparency = 1,
		BorderSizePixel = 0,

		ZIndex = 14,
	})

	S.padding(body, 14, 14, 10, 11)

	bodylayout = S.list(body, 9)

	section = {
		page = page,
		column = column,

		order = page.order,

		frame = frame,
		header = headerobject,
		body = body,
		clip = clip,
		collapse = collapse,
		divider = divider,
		shadow = floatingshadow,
		TextObject = titleobject,
		IconObject = sectionimage,

		name = titletext,

		controls = {},
		transitions = {},

		collapsed = false,
		dragging = false,
		floating = false,
		floatingwidth = nil,

		headerheight = 43,
		targetheight = 43,
		targety = 0,

		ready = false,
		headerdragged = false,
		lastdragend = 0,
	}

	sectiontransition = function(key, object, properties, animate, previous, animation)
		previous = section.transitions[key]
		section.transitions[key] = nil

		if previous then previous:Cancel() end

		if not animate or not S.animationsenabled then
			for property, value in pairs(properties) do
				object[property] = value
			end
			return nil
		end

		animation = S.tween(object, properties, S.tabti)
		section.transitions[key] = animation

		if animation then
			animation.Completed:Connect(function()
				if section.transitions[key] == animation then section.transitions[key] = nil end
			end)
		end

		return animation
	end

	table.insert(page.sections, section)
	page:invalidateorder()
	frame.Destroying:Connect(function(owner)
		owner = section.page
		for index, item in ipairs(owner.sections) do
			if item == section then
				table.remove(owner.sections, index)
				break
			end
		end
		owner:invalidateorder()
		owner:reflow(section.column, false)
	end)

	resize = function(
		animate,
		layoutanimate,
		bodyheight,
		visibleheight,
		collapsedheader,
		bodyheight2,
		visibleheight2,
		collapsedheader2,
		framesize,
		clipsize,
		clipanimation
	)
		

		bodyheight2 = bodylayout.AbsoluteContentSize.Y + 21

		body.Size = UDim2.new(1, 0, 0, bodyheight2)

		visibleheight2 = section.collapsed and 0 or bodyheight2
		collapsedheader2 = section.subtabheaderhidden and 32 or section.headerheight

		section.targetheight = section.collapsed and collapsedheader2
			or (section.headerheight + visibleheight2)

		framesize = nil

		if section.floating then
			framesize = UDim2.fromOffset(
				section.floatingwidth or math.max(1, frame.AbsoluteSize.X),
				section.targetheight
			)
		else
			framesize = UDim2.new(1, -7, 0, section.targetheight)
		end

		clipsize = UDim2.new(1, 0, 0, visibleheight2)

		sectiontransition("frame", frame, { Size = framesize }, animate)

		clipanimation = nil
		if animate and S.animationsenabled then
			clip.ClipsDescendants = true
			clipanimation = sectiontransition("clip", clip, { Size = clipsize }, true)
		else
			clip.ClipsDescendants = section.collapsed
			sectiontransition("clip", clip, { Size = clipsize }, false)
		end

		if clipanimation then
			clipanimation.Completed:Connect(function()
				if not section.collapsed and clip.Parent then clip.ClipsDescendants = false end
				if not section.floating and page and page.frame and page.frame.Parent then page:reflow(section.column, false) end
			end)
		end

		if not section.floating then page:reflow(section.column, layoutanimate == true) end
	end

	function section:RefreshLayout(animate, layoutanimate)
		resize(animate == true, layoutanimate == true)
	end

	function section:SetTitleVisible(value, animate, visible)
		visible = value == true
		self.subtabheaderhidden = not visible
		self.headerheight = visible and 43 or 0

		titleobject.Visible = visible
		if sectionimage then sectionimage.Visible = visible end
		divider.Visible = visible
		clip.Position = UDim2.fromOffset(0, self.headerheight)

		if visible then
			headerobject.Visible = true
			draghandle.Parent = headerobject
			draghandle.Position = UDim2.fromOffset(0, 0)
			draghandle.Size = UDim2.fromScale(1, 1)
			collapse.Parent = headerobject
			collapse.AnchorPoint = Vector2.new(1, 0.5)
			collapse.Position = UDim2.new(1, -13, 0.5, 0)
			collapse.ZIndex = 17
			collapse.Visible = true
			divider.BackgroundTransparency = self.collapsed and 1 or 0.52
		else
			headerobject.Visible = false
			-- Keep the existing drag/minimize control usable without reserving a title row.
			draghandle.Parent = frame
			draghandle.AnchorPoint = Vector2.new(1, 0)
			draghandle.Position = UDim2.new(1, 0, 0, 0)
			draghandle.Size = UDim2.fromOffset(34, 32)
			draghandle.ZIndex = 20
			collapse.Parent = frame
			collapse.AnchorPoint = Vector2.new(1, 0.5)
			collapse.Position = UDim2.new(1, -9, 0, 16)
			collapse.ZIndex = 21
			collapse.Visible = true
		end

		if self.subtabviewport and self.subtabviewport.Parent then
			self.subtabviewport.Size = visible and UDim2.new(1, 0, 0, 32)
				or UDim2.new(1, -38, 0, 32)
		end

		resize(animate == true, animate == true)
	end

	function section:SetCollapsed(value, animate, layoutanimate)
		self.collapsed = value == true

		

		-- The body clip handles the collapse. Keep the outer section unclipped so
		-- shadows/glows do not change appearance during the animation.
		frame.ClipsDescendants = false

		sectiontransition("collapse", collapse, { Rotation = self.collapsed and -90 or 0 }, animate)

		sectiontransition("divider", divider, {
			BackgroundTransparency = self.subtabheaderhidden and 1
				or (self.collapsed and 1 or 0.52),
		}, animate)

		resize(animate, layoutanimate)
	end



	bodylayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		resize(section.ready and true, section.ready and true)

		
	end)

	section.ready = true
	resize(false, false)

	page:reflow(column, false)

	draghandle.Activated:Connect(function()
		if
			(S.sectiondrag and S.sectiondrag.section == section and S.sectiondrag.started)
			or os.clock() - (section.lastdragend or 0) < 0.12
		then
			return
		end

		section:SetCollapsed(not section.collapsed, true, true)
	end)

	draghandle.InputBegan:Connect(function(input)
		

		if
			input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch
		then
			return
		end

		if not S.acquireinteraction("sectiondrag", input) then return end

		S.closepopup()

		section.headerdragged = false

		S.sectiondrag = {
			input = input,

			section = section,

			start = S.point(input),
			current = S.point(input),

			started = false,
		}
	end)

	register = function(row, name, expected, fallback, visible)
		table.insert(section.controls, {
			row = row,
			name = string.lower(S.plaintext(name)),
		})

		if row:IsA("TextLabel") or row:IsA("TextButton") or row:IsA("TextBox") then
			S.registergradienttarget(row, row)
			return
		end

		expected = string.lower(S.plaintext(name))
		fallback = nil

		for _, object in ipairs(row:GetDescendants()) do
			if object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox") then
				visible = string.lower(S.plaintext(object.Text))

				if visible ~= "" and not fallback then fallback = object end

				if visible == expected then
					S.registergradienttarget(row, object)
					return
				end
			end
		end

		if fallback then S.registergradienttarget(row, fallback) end
	end

	-- label

	function section:AddLabel(text, wrap, target, parentobject, object10, resize)
		parentobject = target or body

		object10 = S.label(parentobject, text, UDim2.new(1, 0, 0, 20), S.font, S.theme.text2)

		object10.TextSize = 16
		object10.TextWrapped = wrap ~= false
		object10.TextTruncate = Enum.TextTruncate.None
		object10.TextYAlignment = wrap ~= false and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center
		object10.AutomaticSize = Enum.AutomaticSize.None

		if wrap ~= false then
			resize = function(bounds, width, height)
				width = object10.AbsoluteSize.X
				if width <= 1 then return end
				bounds = S.measuretext(
					S.plaintext(object10.Text),
					object10.TextSize,
					object10.Font,
					Vector2.new(width, 10000)
				)
				height = math.max(20, math.ceil(bounds.Y) + 2)
				if object10.Size.Y.Offset ~= height then
					object10.Size = UDim2.new(1, 0, 0, height)
				end
			end
			S.connect(object10:GetPropertyChangedSignal("AbsoluteSize"), resize)
			S.connect(object10:GetPropertyChangedSignal("Text"), resize)
			resize()
		end

		register(object10, text)

		return object10
	end

	-- button

	function section:AddButton(name, callback, target, parentobject, button4)
		parentobject = target or body

		button4 = S.new("TextButton", {
			Parent = parentobject,

			Size = UDim2.new(1, 0, 0, 32),

			BackgroundColor3 = S.theme.input,
			BackgroundTransparency = 0.08,
			BorderSizePixel = 0,

			Text = name,
			TextColor3 = S.theme.text2,
			TextSize = 16,
			Font = S.medium,
			TextXAlignment = Enum.TextXAlignment.Center,

			AutoButtonColor = false,
			ZIndex = 15,
		}, { BackgroundColor3 = "input", TextColor3 = "text2" })

		S.corner(button4, 7)
		S.stroke(button4, 0.68, S.theme.border, 0.6)

		button4.MouseEnter:Connect(
			function()
				S.tween(
					button4,
					{ TextColor3 = S.theme.text },
					S.hoverti,
					nil,
					{ TextColor3 = "text" }
				)
			end
		)

		button4.MouseLeave:Connect(
			function()
				S.tween(
					button4,
					{ TextColor3 = S.theme.text2 },
					S.hoverti,
					nil,
					{ TextColor3 = "text2" }
				)
			end
		)

		button4.MouseButton1Down:Connect(function()
			S.tween(button4, { TextTransparency = 0.22 }, S.fastti)
		end)
		button4.MouseButton1Up:Connect(function()
			S.tween(button4, { TextTransparency = 0 }, S.fastti)
		end)
		button4.MouseLeave:Connect(function()
			S.tween(button4, { TextTransparency = 0 }, S.fastti)
		end)
		button4.Activated:Connect(function()
			S.tween(button4, { TextTransparency = 0 }, S.fastti)
			if callback then callback() end
		end)

		register(button4, name)

		return button4
	end

	-- row

	function section:AddRow(
		spacing,
		height,
		target,
		gap,
		rowheight,
		parentobject,
		holder,
		rowlayout,
		row
	)
		gap = tonumber(spacing) or 8
		rowheight = tonumber(height) or 32
		parentobject = target or body

		holder = S.new("Frame", {
			Parent = parentobject,
			Size = UDim2.new(1, 0, 0, rowheight),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = 15,
		})

		rowlayout = S.new("UIListLayout", {
			Parent = holder,
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Top,
			Padding = UDim.new(0, gap),
			SortOrder = Enum.SortOrder.LayoutOrder,
		})

		row = {
			Frame = holder,
			Layout = rowlayout,
			Items = {},
		}

		function row:Refresh(count, offset, maxheight, totalheight, itemheight)
			count = #self.Items

			if count == 0 then return end

			maxheight = rowheight
			totalheight = 0
			for _, item in ipairs(self.Items) do
				itemheight = tonumber(item:GetAttribute("BlushRowHeight")) or math.max(rowheight, item.Size.Y.Offset)
				maxheight = math.max(maxheight, itemheight)
				totalheight += itemheight
			end

			

			self.Frame.Size = UDim2.new(1, 0, 0, maxheight)
			offset = -gap * (count - 1) / count

			for index, item in ipairs(self.Items) do
				itemheight = tonumber(item:GetAttribute("BlushRowHeight")) or rowheight
				item.LayoutOrder = index
				item.Size = UDim2.new(1 / count, offset, 0, itemheight)
			end
		end

		function row:AddButton(name, callback, button5)
			button5 = section:AddButton(name, callback, holder)
			button5:SetAttribute("BlushRowHeight", button5.Size.Y.Offset)

			table.insert(self.Items, button5)
			self:Refresh()

			return button5
		end

		function row:AddToggle(name, default, callback, keybindable, badge, control)
			control = section:AddToggle(name, default, callback, holder, keybindable, badge)
			control.Object:SetAttribute("BlushRowHeight", control.Object.Size.Y.Offset)

			table.insert(self.Items, control.Object)
			self:Refresh()

			return control
		end

		function row:AddKeyPicker(name, defaultkey, callback, captureoptions, control)
			control = section:AddKeyPicker(name, defaultkey, callback, holder, captureoptions)
			if control.Object then
				control.Object:SetAttribute("BlushRowHeight", control.Object.Size.Y.Offset)
				table.insert(self.Items, control.Object)
				self:Refresh()
			end
			return control
		end

		function row:AddDropdown(name, options, default, callback, config, control)
			control = section:AddDropdown(name, options, default, callback, holder, config)
			control.Object:SetAttribute("BlushRowHeight", control.Object.Size.Y.Offset)
			table.insert(self.Items, control.Object)
			self:Refresh()
			return control
		end

		function row:AddMultiDropdown(name, options, default, callback, config, control)
			control = section:AddMultiDropdown(name, options, default, callback, holder, config)
			control.Object:SetAttribute("BlushRowHeight", control.Object.Size.Y.Offset)
			table.insert(self.Items, control.Object)
			self:Refresh()
			return control
		end

		function row:AddColorPicker(name, color, callback, control)
			control = section:AddColorPicker(name, color, callback, holder)
			if control.Object then
				control.Object:SetAttribute("BlushRowHeight", control.Object.Size.Y.Offset)
				table.insert(self.Items, control.Object)
			end
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
		badge,
		parentobject,
		hasbinding,
		row,
		box,
		render,
		textobject,
		badgetext,
		textbounds,
		badgebounds,
		badgeobject,
		enabled,
		binding,
		setenabled,
		keyobject
	)
		parentobject = target or body

		hasbinding = keybindable == true and true

		row = S.new("TextButton", {
			Parent = parentobject,

			Position = UDim2.fromOffset(0, 0),

			Size = UDim2.new(1, 0, 0, 24),

			BackgroundColor3 = S.theme.hover,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,

			Text = "",
			AutoButtonColor = false,

			ZIndex = 15,
		}, { BackgroundColor3 = "hover" })

		S.corner(row, 6)

		box, render = S.makecheckbox(row, 19, default)

		box.AnchorPoint = Vector2.new(0, 0.5)

		box.Position = UDim2.new(0, 0, 0.5, 0)

		textobject = S.label(row, name, UDim2.new(1, hasbinding and -58 or -30, 1, 0), S.font)

		textobject.Position = UDim2.fromOffset(29, 0)

		textobject.TextSize = 17
		textobject.TextTruncate = Enum.TextTruncate.AtEnd
		textobject.ZIndex = 16

		textobject.TextColor3 = S.theme.text2
		row.MouseEnter:Connect(
			function()
				S.tween(
					textobject,
					{ TextColor3 = S.theme.text },
					S.hoverti,
					nil,
					{ TextColor3 = "text" }
				)
			end
		)
		row.MouseLeave:Connect(
			function()
				S.tween(
					textobject,
					{ TextColor3 = S.theme.text2 },
					S.hoverti,
					nil,
					{ TextColor3 = "text2" }
				)
			end
		)

		if badge then
			badgetext = type(badge) == "table" and (badge.Text or badge.text or "NEW")
				or tostring(badge)

			textbounds = S.measuretext(S.plaintext(name), 17, S.font, Vector2.new(260, 24))

			badgebounds = S.measuretext(badgetext, 11, S.bold, Vector2.new(100, 16))

			badgeobject = S.new("TextLabel", {
				Parent = row,
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.fromOffset(29 + math.ceil(textbounds.X) + 7, 12),
				Size = UDim2.fromOffset(math.ceil(badgebounds.X) + 10, 17),
				BackgroundColor3 = type(badge) == "table" and (badge.Color or badge.color)
					or S.theme.text,
				BackgroundTransparency = 0.04,
				BorderSizePixel = 0,
				Text = badgetext,
				TextColor3 = type(badge) == "table" and (badge.TextColor or badge.textcolor)
					or S.theme.window,
				Font = S.bold,
				TextSize = 11,
				ZIndex = 18,
			})

			S.corner(badgeobject, 4)
		end

		enabled = default == true

		binding = nil

		setenabled = function(value, fire)
			enabled = value == true
			render(enabled)
			S.requesthotkeyrefresh(binding)

			if fire ~= false and callback then callback(enabled) end
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
			get = function() return enabled end,
			set = setenabled,
		}

		S.registertogglebinding(binding)

		if hasbinding then S.attachtoggleconfig(row, binding) end
		row.Destroying:Connect(function() S.unregistertogglebinding(binding) end)

		keyobject = nil
		if hasbinding then keyobject = S.addtoggleconfigicon(row, binding, row, 0) end

		row.Activated:Connect(function()
			if binding.suppressclick then
				binding.suppressclick = false
				return
			end

			if binding.mode == "Always On" then
				setenabled(true, true)
				return
			end

			setenabled(not enabled, true)
		end)

		register(row, name)

		return {
			Get = function() return enabled end,

			Set = function(_, value, fire) setenabled(value, fire) end,

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
		badge,
		control,
		keybutton
	)
		control = self:AddToggle(name, default, callback, target, false, badge)

		

		keybutton = S.attachinlinekeypicker(
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
		keybindable,
		parentobject,
		hasbinding,
		row,
		togglebutton,
		box,
		render,
		textobject,
		pickerbutton,
		swatch,
		swatchglow,
		colorstate,
		enabled,
		binding,
		setenabled
	)
		parentobject = target or body

		hasbinding = keybindable == true and true

		row = S.new("Frame", {
			Parent = parentobject,

			Size = UDim2.new(1, 0, 0, 24),

			BackgroundTransparency = 1,

			ZIndex = 15,
		})

		togglebutton = S.new("TextButton", {
			Parent = row,

			Position = UDim2.fromOffset(0, 0),

			Size = UDim2.new(1, -33, 1, 0),

			BackgroundColor3 = S.theme.hover,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,

			Text = "",
			AutoButtonColor = false,

			ZIndex = 16,
		}, { BackgroundColor3 = "hover" })

		S.corner(togglebutton, 6)

		box, render = S.makecheckbox(togglebutton, 19, default)

		box.AnchorPoint = Vector2.new(0, 0.5)

		box.Position = UDim2.new(0, 0, 0.5, 0)

		textobject =
			S.label(togglebutton, name, UDim2.new(1, hasbinding and -48 or -29, 1, 0), S.font)

		textobject.Position = UDim2.fromOffset(29, 0)

		textobject.TextSize = 17
		textobject.TextTruncate = Enum.TextTruncate.AtEnd
		textobject.ZIndex = 17

		textobject.TextColor3 = S.theme.text2
		togglebutton.MouseEnter:Connect(
			function()
				S.tween(
					textobject,
					{ TextColor3 = S.theme.text },
					S.hoverti,
					nil,
					{ TextColor3 = "text" }
				)
			end
		)
		togglebutton.MouseLeave:Connect(
			function()
				S.tween(
					textobject,
					{ TextColor3 = S.theme.text2 },
					S.hoverti,
					nil,
					{ TextColor3 = "text2" }
				)
			end
		)

		pickerbutton = S.new("TextButton", {
			Parent = row,

			AnchorPoint = Vector2.new(1, 0.5),

			Position = UDim2.new(1, 0, 0.5, 0),

			Size = UDim2.fromOffset(22, 22),

			BackgroundTransparency = 1,
			BorderSizePixel = 0,

			Text = "",
			AutoButtonColor = false,

			ZIndex = 16,
		})

		swatch = S.new("Frame", {
			Parent = pickerbutton,

			Size = UDim2.fromScale(1, 1),

			BackgroundColor3 = color,

			BorderSizePixel = 0,

			ZIndex = 17,
		})

		S.corner(swatch, 5)

		swatchglow =
			S.addshadow(swatch, "ColorGlow", 0.62, 7, 1, -1, color, UDim2.fromOffset(0, 0), false)

		colorstate = S.createcolorstate(color, colorcallback, swatch)

		colorstate.swatchglow = swatchglow
		colorstate:apply()

		enabled = default == true

		binding = nil

		setenabled = function(value, fire)
			enabled = value == true
			render(enabled)
			S.requesthotkeyrefresh(binding)

			if fire ~= false and togglecallback then togglecallback(enabled) end
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
			get = function() return enabled end,
			set = setenabled,
			hotkeycolor = function() return colorstate:color() end,
		}
		colorstate.hotkeybinding = binding
		S.registertogglebinding(binding)

		S.attachtoggleconfig(togglebutton, binding)

		if hasbinding then
			S.addtoggleconfigicon(togglebutton, binding, row, 0)
			pickerbutton.Position = UDim2.new(1, -26, 0.5, 0)
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

			setenabled(not enabled, true)
		end)

		pickerbutton.Activated:Connect(function() S.opencolorpicker(pickerbutton, colorstate) end)

		register(row, name)

		return {
			Get = function() return enabled end,

			Set = function(_, value, fire) setenabled(value, fire) end,

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
		target,
		control,
		row,
		togglebutton,
		pickerbutton,
		binding,
		keybutton,
		keytext,
		configbutton,
		listening,
		renderkey
	)
		control =
			self:AddToggleColor(name, default, color, togglecallback, colorcallback, target, false)

		

		row = control.Object
		togglebutton = control.ToggleObject
		pickerbutton = control.PickerObject
		binding = control.Binding

		S.setbindingkey(binding, defaultkey or Enum.KeyCode.F, false)
		binding.inlinekey = true

		togglebutton.Size = UDim2.new(1, -106, 1, 0)
		control.TextObject.Size = UDim2.new(1, -38, 1, 0)

		keybutton = S.new("TextButton", {
			Parent = row,
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -29, 0.5, 0),
			Size = UDim2.fromOffset(54, 22),
			BackgroundColor3 = S.theme.input,
			BackgroundTransparency = 0.08,
			BorderSizePixel = 0,
			Text = "",
			AutoButtonColor = false,
			ZIndex = 18,
		}, { BackgroundColor3 = "input" })
		S.corner(keybutton, 6)
		S.keyeditbuttons[keybutton] = true
		S.stroke(keybutton, 0.72, S.theme.border, 0.6)

		keytext = S.label(keybutton, "", UDim2.fromScale(1, 1), S.medium, S.theme.text2)
		keytext.TextSize = 13
		keytext.TextXAlignment = Enum.TextXAlignment.Center
		keytext.ZIndex = 19

		configbutton = S.addtoggleconfigicon(row, binding, row, 0)
		pickerbutton.Position = UDim2.new(1, -26, 0.5, 0)

		listening = false

		renderkey = function(value, bounds, width)
			value = listening and "..." or S.togglekeyname(binding.key)
			keytext.Text = value

			bounds = S.measuretext(value, 13, S.medium, Vector2.new(120, 22))

			width = math.clamp(math.ceil(bounds.X) + 18, 38, 76)
			keybutton.Size = UDim2.fromOffset(width, 22)
			keybutton.Position = UDim2.new(1, -54, 0.5, 0)
			configbutton.Position = UDim2.new(1, 0, 0.5, 0)
			pickerbutton.Position = UDim2.new(1, -26, 0.5, 0)
			togglebutton.Size = UDim2.new(1, -(width + 78), 1, 0)
			control.TextObject.Size = UDim2.new(1, -40, 1, 0)
		end

		binding.refreshkey = renderkey

		keybutton.InputBegan:Connect(function(input)
			if
				input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch
			then
				binding.suppressclick = true
			end
		end)

		keybutton.Activated:Connect(function()
			if listening then
				listening = false
				S.endkeycapture(row, nil)
				binding.suppressclick = false
				renderkey()
				return
			end

			listening = true

			if
				not S.beginkeycapture(
					row,
					function()
						listening = false
						renderkey()
					end,
					function(selectedkey)
						listening = false
						S.setbindingkey(binding, selectedkey)
						renderkey()

						if keycallback then keycallback(binding.key) end
					end,
					function(input)
						return input.UserInputType == Enum.UserInputType.MouseButton1
							and S.inside(keybutton, S.point(input))
					end
				)
			then
				listening = false
			end

			binding.suppressclick = false
			renderkey()
		end)

		S.connect(row.Destroying, function()
			if listening then
				listening = false
				S.endkeycapture(row, nil)
			end
		end)

		keybutton.MouseEnter:Connect(
			function()
				S.tween(
					keytext,
					{ TextColor3 = S.theme.text },
					S.hoverti,
					nil,
					{ TextColor3 = "text" }
				)
			end
		)

		keybutton.MouseLeave:Connect(
			function()
				S.tween(
					keytext,
					{ TextColor3 = S.theme.text2 },
					S.hoverti,
					nil,
					{ TextColor3 = "text2" }
				)
			end
		)

		renderkey()
		S.refreshhotkeylist()

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
		target,
		round,
		parentobject,
		holder,
		title,
		valueobject,
		track,
		fill,
		fillglow,
		knob,
		sliderhit,
		value,
		format,
		set,
		update
	)
		round = math.clamp(math.floor(tonumber(round) or 0), 0, 6)
		minimum, maximum = S.sliderbounds(minimum, maximum, round)
		parentobject = target or body

		holder = S.new("Frame", {
			Parent = parentobject,

			Size = UDim2.new(1, 0, 0, 43),

			BackgroundColor3 = S.theme.hover,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Active = true,

			ZIndex = 15,
		}, { BackgroundColor3 = "hover" })

		S.corner(holder, 6)

		title = S.label(holder, name, UDim2.new(1, -80, 0, 19), S.font)

		title.TextSize = 17

		valueobject = S.label(holder, "", UDim2.fromOffset(80, 19), S.medium, S.theme.text3)

		valueobject.AnchorPoint = Vector2.new(1, 0)

		valueobject.Position = UDim2.new(1, 0, 0, 0)

		valueobject.TextXAlignment = Enum.TextXAlignment.Right

		valueobject.TextSize = 16

		holder.MouseEnter:Connect(function()
			S.tween(title, { TextColor3 = S.theme.text }, S.hoverti, nil, { TextColor3 = "text" })
			S.tween(
				valueobject,
				{ TextColor3 = S.theme.text2 },
				S.hoverti,
				nil,
				{ TextColor3 = "text2" }
			)
		end)
		holder.MouseLeave:Connect(function()
			S.tween(title, { TextColor3 = S.theme.text }, S.hoverti, nil, { TextColor3 = "text" })
			S.tween(
				valueobject,
				{ TextColor3 = S.theme.text3 },
				S.hoverti,
				nil,
				{ TextColor3 = "text3" }
			)
		end)

		track = S.new("TextButton", {
			Parent = holder,

			Position = UDim2.fromOffset(0, 32),

			Size = UDim2.new(1, 0, 0, 5),

			BackgroundColor3 = S.theme.track,

			BorderSizePixel = 0,

			Text = "",
			AutoButtonColor = false,

			ZIndex = 16,
		}, { BackgroundColor3 = "track" })

		S.corner(track, 999)

		fill = S.new("Frame", {
			Parent = track,

			Size = UDim2.fromScale(0, 1),

			BackgroundColor3 = S.theme.highlight,

			BorderSizePixel = 0,

			ZIndex = 17,
		}, { BackgroundColor3 = "highlight" })

		S.corner(fill, 999)
		fillglow = S.addglow(fill, "active")

		if fillglow then fillglow.Transparency = 0.66 end

		knob = S.new("Frame", {
			Parent = track,

			AnchorPoint = Vector2.new(0.5, 0.5),

			Position = UDim2.fromScale(0, 0.5),

			Size = UDim2.fromOffset(13, 13),

			BackgroundColor3 = S.theme.highlight,

			BorderSizePixel = 0,

			ZIndex = 18,
		}, { BackgroundColor3 = "highlight" })

		S.corner(knob, 999)

		sliderhit = S.new("TextButton", {
			Parent = holder,

			Position = UDim2.fromOffset(0, 27),

			Size = UDim2.new(1, 0, 0, 16),

			BackgroundTransparency = 1,
			BorderSizePixel = 0,

			Text = "",
			AutoButtonColor = false,

			ZIndex = 19,
		})

		value = nil

		format = function(number) return string.format("%." .. round .. "f", number) end

		set = function(number, fire, alpha)
			number = S.roundslider(number, minimum, maximum, round)
			if fire and number == value then return end

			alpha = maximum == minimum and 0 or (number - minimum) / (maximum - minimum)

			value = number

			fill.Size = UDim2.fromScale(alpha, 1)

			knob.Position = UDim2.fromScale(alpha, 0.5)

			valueobject.Text = format(number) .. (suffix or "")

			if fire and callback then callback(number) end
		end

		update = function(position, alpha)
			alpha = math.clamp((position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)

			set(minimum + (maximum - minimum) * alpha, true)
		end

		sliderhit.InputBegan:Connect(function(input)
			if
				input.UserInputType ~= Enum.UserInputType.MouseButton1
				and input.UserInputType ~= Enum.UserInputType.Touch
			then
				return
			end

			if not S.acquireinteraction("slider", input) then return end

			S.sliderdrag = {
				input = input,
				update = update,

				knobs = {
					knob,
				},
			}

			update(S.point(input))

			S.tween(knob, {
				Size = UDim2.fromOffset(15, 15),
			}, S.fastti)
		end)

		set(default, false)

		register(holder, name)

		return {
			Get = function() return value end,

			Set = function(_, number, fire) set(number, fire ~= false) end,

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
		target,
		mindistance,
		round,
		parentobject,
		holder,
		title,
		valueobject,
		track,
		rangefill,
		rangeglow,
		lowknob,
		highknob,
		rangehit,
		low,
		high,
		minimumdistance,
		enforcegap,
		active,
		format,
		render,
		update
	)
		round = math.clamp(math.floor(tonumber(round) or 0), 0, 6)
		minimum, maximum = S.sliderbounds(minimum, maximum, round)
		parentobject = target or body

		holder = S.new("Frame", {
			Parent = parentobject,

			Size = UDim2.new(1, 0, 0, 43),

			BackgroundColor3 = S.theme.hover,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Active = true,

			ZIndex = 15,
		}, { BackgroundColor3 = "hover" })

		S.corner(holder, 6)

		title = S.label(holder, name, UDim2.new(1, -130, 0, 19), S.font)

		title.TextSize = 17

		valueobject = S.label(holder, "", UDim2.fromOffset(130, 19), S.medium, S.theme.text3)

		valueobject.AnchorPoint = Vector2.new(1, 0)

		valueobject.Position = UDim2.new(1, 0, 0, 0)

		valueobject.TextXAlignment = Enum.TextXAlignment.Right

		valueobject.TextSize = 16

		holder.MouseEnter:Connect(function()
			S.tween(title, { TextColor3 = S.theme.text }, S.hoverti, nil, { TextColor3 = "text" })
			S.tween(
				valueobject,
				{ TextColor3 = S.theme.text2 },
				S.hoverti,
				nil,
				{ TextColor3 = "text2" }
			)
		end)
		holder.MouseLeave:Connect(function()
			S.tween(title, { TextColor3 = S.theme.text }, S.hoverti, nil, { TextColor3 = "text" })
			S.tween(
				valueobject,
				{ TextColor3 = S.theme.text3 },
				S.hoverti,
				nil,
				{ TextColor3 = "text3" }
			)
		end)

		track = S.new("TextButton", {
			Parent = holder,

			Position = UDim2.fromOffset(0, 32),

			Size = UDim2.new(1, 0, 0, 5),

			BackgroundColor3 = S.theme.track,

			BorderSizePixel = 0,

			Text = "",
			AutoButtonColor = false,

			ZIndex = 16,
		}, { BackgroundColor3 = "track" })

		S.corner(track, 999)

		rangefill = S.new("Frame", {
			Parent = track,

			BackgroundColor3 = S.theme.highlight,

			BorderSizePixel = 0,

			ZIndex = 17,
		}, { BackgroundColor3 = "highlight" })

		S.corner(rangefill, 999)
		rangeglow = S.addglow(rangefill, "active")

		if rangeglow then rangeglow.Transparency = 0.66 end

		lowknob = S.new("Frame", {
			Parent = track,

			AnchorPoint = Vector2.new(0.5, 0.5),

			Size = UDim2.fromOffset(13, 13),

			BackgroundColor3 = S.theme.highlight,

			BorderSizePixel = 0,

			ZIndex = 18,
		}, { BackgroundColor3 = "highlight" })

		S.corner(lowknob, 999)

		highknob = S.new("Frame", {
			Parent = track,

			AnchorPoint = Vector2.new(0.5, 0.5),

			Size = UDim2.fromOffset(13, 13),

			BackgroundColor3 = S.theme.highlight,

			BorderSizePixel = 0,

			ZIndex = 18,
		}, { BackgroundColor3 = "highlight" })

		S.corner(highknob, 999)

		rangehit = S.new("TextButton", {
			Parent = holder,

			Position = UDim2.fromOffset(0, 27),

			Size = UDim2.new(1, 0, 0, 16),

			BackgroundTransparency = 1,
			BorderSizePixel = 0,

			Text = "",
			AutoButtonColor = false,

			ZIndex = 19,
		})

		low = S.roundslider(math.min(defaultmin, defaultmax), minimum, maximum, round)

		high = S.roundslider(math.max(defaultmin, defaultmax), minimum, maximum, round)

		minimumdistance = math.clamp(math.ceil((tonumber(mindistance) or 0) * 10 ^ round) / 10 ^ round, 0, maximum - minimum)

		enforcegap = function(preferred)
			if high - low >= minimumdistance then return end

			if preferred == "low" then
				low = math.clamp(high - minimumdistance, minimum, maximum)
			elseif preferred == "high" then
				high = math.clamp(low + minimumdistance, minimum, maximum)
			else
				high = math.min(maximum, low + minimumdistance)
				if high - low < minimumdistance then
					low = math.max(minimum, high - minimumdistance)
				end
			end
		end

		enforcegap()

		active = "low"

		format = function(value) return string.format("%." .. round .. "f", value) end

		render = function(fire, denominator, lowalpha, highalpha)
			denominator = math.max(0.0001, maximum - minimum)

			lowalpha = (low - minimum) / denominator

			highalpha = (high - minimum) / denominator

			lowknob.Position = UDim2.fromScale(lowalpha, 0.5)

			highknob.Position = UDim2.fromScale(highalpha, 0.5)

			rangefill.Position = UDim2.fromScale(lowalpha, 0)

			rangefill.Size = UDim2.new(highalpha - lowalpha, 0, 1, 0)

			valueobject.Text = format(low)
				.. (suffix or "")
				.. " - "
				.. format(high)
				.. (suffix or "")

			if fire and callback then callback(low, high) end
		end

		update = function(position, alpha, value)
			alpha = math.clamp((position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)

			value = S.roundslider(minimum + (maximum - minimum) * alpha, minimum, maximum, round)

			if active == "low" then
				low = math.clamp(value, minimum, math.max(minimum, high - minimumdistance))
			else
				high = math.clamp(value, math.min(maximum, low + minimumdistance), maximum)
			end

			render(true)
		end

		rangehit.InputBegan:Connect(function(input, p, lowx, highx, knob)
			if
				input.UserInputType ~= Enum.UserInputType.MouseButton1
				and input.UserInputType ~= Enum.UserInputType.Touch
			then
				return
			end

			p = S.point(input)

			lowx = lowknob.AbsolutePosition.X + lowknob.AbsoluteSize.X / 2

			highx = highknob.AbsolutePosition.X + highknob.AbsoluteSize.X / 2

			active = math.abs(p.X - lowx) <= math.abs(p.X - highx) and "low" or "high"

			knob = active == "low" and lowknob or highknob

			if not S.acquireinteraction("slider", input) then return end

			S.sliderdrag = {
				input = input,
				update = update,

				knobs = {
					knob,
				},
			}

			update(p)

			S.tween(knob, {
				Size = UDim2.fromOffset(15, 15),
			}, S.fastti)
		end)

		render(false)

		register(holder, name)

		return {
			Get = function() return low, high end,
			Set = function(_, newlow, newhigh, fire, a, b)
				a = S.roundslider(tonumber(newlow) or low, minimum, maximum, round)
				b = S.roundslider(tonumber(newhigh) or high, minimum, maximum, round)
				low = math.min(a, b)
				high = math.max(a, b)
				enforcegap()
				render(fire ~= false)
			end,
			SetMinimumDistance = function(_, value, fire)
				minimumdistance =
					math.clamp(math.ceil((tonumber(value) or 0) * 10 ^ round) / 10 ^ round, 0, maximum - minimum)
				enforcegap()
				render(fire ~= false)
			end,
			GetMinimumDistance = function() return minimumdistance end,
			Object = holder,
			TextObject = title,
		}
	end

	dropdownpopup = function(
		button,
		count,
		position,
		size,
		popupy,
		wanted,
		available,
		height,
		panel,
		popup
	)
		if S.activepopup and S.activepopup.anchor == button then
			S.closepopup()
			return nil, nil
		end

		position = S.overlayposition(button)

		size = button.AbsoluteSize

		popupy = position.Y + size.Y + 6

		wanted = count * 34 + 8

		available = S.popuplayer.AbsoluteSize.Y - popupy - 8

		height = math.max(34, math.min(wanted, available))

		panel, popup =
			S.createpopup(Vector2.new(position.X, popupy), size.X, height, 510, "dropdown")

		popup.anchor = button
		return panel, popup
	end

	binddropdownscrollbar = function(scroll, thickness, update)
		thickness = thickness or 2

		update = function(overflow, needs)
			if not scroll or not scroll.Parent then return end

			overflow = scroll.AbsoluteCanvasSize.Y - scroll.AbsoluteSize.Y
			needs = overflow > 6
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
		config,
		parentobject,
		dividerbefore,
		optioncolors,
		optionicons,
		searchable,
		normalized,
		pendingdivider,
		value,
		asset,
		color,
		dividercount,
		holder,
		title,
		button6,
		selected,
		optionbindings,
		previewicon,
		previewcolor,
		valuetext,
		updatepreview,
		setselected,
		optionbinding,
		arrow
	)
		parentobject = target or body
		config = config or {}

		dividerbefore = table.clone(config.dividers or {})
		optioncolors = table.clone(config.colors or {})
		optionicons = table.clone(config.icons or {})
		searchable = config.searchable == true
		normalized = {}
		pendingdivider = nil

		for _, entry in ipairs(options or {}) do
			if type(entry) == "table" then
				if entry.Divider == true or entry.divider == true then
					pendingdivider = entry.Text or entry.text or true
				else
					value = entry.Value
						or entry.value
						or entry.Name
						or entry.name
						or entry.Text
						or entry.text
					if value ~= nil then
						normalized[#normalized + 1] = value
						asset = entry.Icon or entry.icon
						color = entry.Color or entry.color
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

		dividercount = 0
		for _, option in ipairs(options) do
			if dividerbefore[option] ~= nil then
				dividercount += 1
			end
		end

		holder = S.new("Frame", {
			Parent = parentobject,
			Size = UDim2.new(1, 0, 0, 57),
			BackgroundTransparency = 1,
			ZIndex = 15,
		})

		title = S.label(holder, name, UDim2.new(1, 0, 0, 18), S.font)
		title.TextSize = 17

		button6 = S.new("TextButton", {
			Parent = holder,
			Position = UDim2.fromOffset(0, 25),
			Size = UDim2.new(1, 0, 0, 32),
			BackgroundColor3 = S.theme.input,
			BorderSizePixel = 0,
			Text = "",
			AutoButtonColor = false,
			ZIndex = 16,
		}, { BackgroundColor3 = "input" })

		S.corner(button6, 7)

		selected = default or options[1]
		optionbindings = {}

		previewicon = nil

		previewcolor = S.rawnew("Frame", {
			Parent = button6,
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.fromOffset(10, 16),
			Size = UDim2.fromOffset(10, 10),
			BackgroundColor3 = optioncolors[selected] or S.theme.text3,
			BorderSizePixel = 0,
			Visible = optioncolors[selected] ~= nil,
			ZIndex = 18,
		})
		S.corner(previewcolor, 3)
		S.stroke(previewcolor, 0.62, S.theme.border, 0.5)

		valuetext = S.label(button6, tostring(selected or "None"), UDim2.new(1, -38, 1, 0), S.font)
		valuetext.TextSize = 17
		valuetext.ZIndex = 17

		updatepreview = function(asset2, color3, offset)
			asset2 = optionicons[selected]
			color3 = optioncolors[selected]

			if asset2 then
				if not previewicon or not previewicon.Parent then
					previewicon = S.image(button6, asset2, 18, S.theme.text2, 18)

					previewicon.AnchorPoint = Vector2.new(0, 0.5)

					previewicon.ScaleType = Enum.ScaleType.Fit
				else
					previewicon.Image = tostring(asset2)
				end
			elseif previewicon then
				previewicon:Destroy()
				previewicon = nil
			end

			previewcolor.Visible = color3 ~= nil

			if color3 then previewcolor.BackgroundColor3 = color3 end

			offset = 10
			if previewicon then
				previewicon.Position = UDim2.fromOffset(offset, 16)
				offset += 22
			end
			if color3 then
				previewcolor.Position = UDim2.fromOffset(offset, 16)
				offset += 18
			end

			valuetext.Position = UDim2.fromOffset(offset, 0)
			valuetext.Size = UDim2.new(1, -(offset + 28), 1, 0)
			valuetext.Text = tostring(selected or "None")
		end

		updatepreview()

		setselected = function(option, fire)
			if not table.find(options, option) then return false end

			selected = option
			updatepreview()

			if fire ~= false and callback then callback(option) end

			for _, binding in pairs(optionbindings) do
				S.requesthotkeyrefresh(binding)
			end

			return true
		end

		optionbinding = function(option, existing, binding)
			existing = optionbindings[option]

			if existing then return existing end

			binding = nil

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

				get = function() return selected == option end,

				set = function(value, fire)
					if value == true then
						if selected ~= option then binding.previous = selected end

						setselected(option, fire)
					elseif
						selected == option
						and binding.previous
						and table.find(options, binding.previous)
					then
						setselected(binding.previous, fire)
					end
				end,
			}

			optionbindings[option] = binding

			S.registertogglebinding(binding)
			return binding
		end

		for _, option in ipairs(options) do
			optionbinding(option)
		end

		arrow = S.image(button6, S.icons.down, 14, S.theme.text3, 17)
		arrow.AnchorPoint = Vector2.new(1, 0.5)
		arrow.Position = UDim2.new(1, -10, 0.5, 0)

		button6.MouseEnter:Connect(function()
			S.tween(
				valuetext,
				{ TextColor3 = S.theme.text },
				S.hoverti,
				nil,
				{ TextColor3 = "text" }
			)
			S.tween(
				arrow,
				{ ImageColor3 = S.theme.text2 },
				S.hoverti,
				nil,
				{ ImageColor3 = "text2" }
			)
		end)
		button6.MouseLeave:Connect(function()
			S.tween(
				valuetext,
				{ TextColor3 = S.theme.text2 },
				S.hoverti,
				nil,
				{ TextColor3 = "text2" }
			)
			S.tween(
				arrow,
				{ ImageColor3 = S.theme.text3 },
				S.hoverti,
				nil,
				{ ImageColor3 = "text3" }
			)
		end)

		button6.Activated:Connect(
			function(
				usesearch,
				panel,
				popup,
				searchbox,
				searchheight,
				searchframe,
				searchicon,
				scroll,
				optionrows,
				dividerrows
			)
				usesearch = searchable and #options >= 6
				panel, popup = dropdownpopup(
					button6,
					#options + dividercount * 0.7 + (usesearch and 1.08 or 0)
				)

				if not panel or not popup then return end

				S.tween(arrow, { Rotation = 180 }, S.tabti)
				popup.onclose = function() S.tween(arrow, { Rotation = 0 }, S.tabti) end

				searchbox = nil
				searchheight = usesearch and 36 or 0

				if usesearch then
					searchframe = S.new("Frame", {
						Parent = panel,
						Position = UDim2.fromOffset(6, 6),
						Size = UDim2.new(1, -12, 0, 30),
						BackgroundColor3 = S.theme.input,
						BackgroundTransparency = 0.08,
						BorderSizePixel = 0,
						ClipsDescendants = true,
						ZIndex = 514,
					}, { BackgroundColor3 = "input" })
					S.corner(searchframe, 6)

					searchicon = S.image(searchframe, S.icons.search, 17, S.theme.text3, 515)
					searchicon.AnchorPoint = Vector2.new(0, 0.5)
					searchicon.Position = UDim2.fromOffset(9, 15)

					searchbox = S.new("TextBox", {
						Parent = searchframe,
						Position = UDim2.fromOffset(33, 0),
						Size = UDim2.new(1, -41, 1, 0),
						BackgroundTransparency = 1,
						BorderSizePixel = 0,
						Text = "",
						PlaceholderText = "Search...",
						PlaceholderColor3 = S.theme.text3,
						TextColor3 = S.theme.text,
						Font = S.font,
						TextSize = 15,
						TextXAlignment = Enum.TextXAlignment.Left,
						ClearTextOnFocus = false,
						ZIndex = 515,
					}, { PlaceholderColor3 = "text3", TextColor3 = "text" })
				end

				scroll = S.new("ScrollingFrame", {
					Parent = panel,
					Position = UDim2.fromOffset(6, 6 + searchheight),
					Size = UDim2.new(1, -12, 1, -12 - searchheight),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					CanvasSize = UDim2.new(),
					AutomaticCanvasSize = Enum.AutomaticSize.Y,
					ScrollBarThickness = 0,
					ScrollBarImageTransparency = 0.56,
					ScrollBarImageColor3 = S.theme.scroll,
					ZIndex = 512,
				}, { ScrollBarImageColor3 = "scroll" })
				S.list(scroll, 2)
				binddropdownscrollbar(scroll, 2)

				optionrows = {}
				dividerrows = {}

				for _, option, iteration5 in S.scopediterator(2, ipairs(options)) do
					iteration5.divider = dividerbefore[option]

					if iteration5.divider ~= nil then
						iteration5.dividerrow = S.new("Frame", {
							Parent = scroll,
							Size = UDim2.new(
								1,
								0,
								0,
								(iteration5.divider == true or iteration5.divider == "") and 14
									or 22
							),
							BackgroundTransparency = 1,
							BorderSizePixel = 0,
							ZIndex = 514,
						})

						if iteration5.divider == true or iteration5.divider == "" then
							iteration5.line = S.new("Frame", {
								Parent = iteration5.dividerrow,
								AnchorPoint = Vector2.new(0.5, 0.5),
								Position = UDim2.fromScale(0.5, 0.5),
								Size = UDim2.new(1, -14, 0, 1),
								BackgroundColor3 = S.theme.border,
								BackgroundTransparency = 0.38,
								BorderSizePixel = 0,
								ZIndex = 515,
							}, { BackgroundColor3 = "border" })
							S.corner(iteration5.line, 999)
						else
							iteration5.dividerlabel = S.label(
								iteration5.dividerrow,
								S.plaintext(tostring(iteration5.divider)),
								UDim2.fromOffset(90, 22),
								S.medium,
								S.theme.text3
							)
							iteration5.dividerlabel.AnchorPoint = Vector2.new(0.5, 0.5)
							iteration5.dividerlabel.Position = UDim2.fromScale(0.5, 0.5)
							iteration5.dividerlabel.TextSize = 14
							iteration5.dividerlabel.TextXAlignment = Enum.TextXAlignment.Center
							iteration5.dividerlabel.ZIndex = 515

							iteration5.leftline = S.new("Frame", {
								Parent = iteration5.dividerrow,
								AnchorPoint = Vector2.new(0, 0.5),
								Position = UDim2.new(0, 7, 0.5, 0),
								Size = UDim2.new(0.5, -59, 0, 1),
								BackgroundColor3 = S.theme.border,
								BackgroundTransparency = 0.38,
								BorderSizePixel = 0,
								ZIndex = 515,
							}, { BackgroundColor3 = "border" })
							iteration5.rightline = S.new("Frame", {
								Parent = iteration5.dividerrow,
								AnchorPoint = Vector2.new(1, 0.5),
								Position = UDim2.new(1, -7, 0.5, 0),
								Size = UDim2.new(0.5, -59, 0, 1),
								BackgroundColor3 = S.theme.border,
								BackgroundTransparency = 0.38,
								BorderSizePixel = 0,
								ZIndex = 515,
							}, { BackgroundColor3 = "border" })
							S.corner(iteration5.leftline, 999)
							S.corner(iteration5.rightline, 999)
						end

						dividerrows[#dividerrows + 1] = iteration5.dividerrow
					end

					iteration5.optionbutton = S.new("TextButton", {
						Parent = scroll,
						Size = UDim2.new(1, 0, 0, 32),
						BackgroundColor3 = S.theme.hover,
						BackgroundTransparency = 1,
						BorderSizePixel = 0,
						Text = "",
						AutoButtonColor = false,
						ZIndex = 514,
					}, { BackgroundColor3 = "hover" })
					S.corner(iteration5.optionbutton, 6)

					iteration5.x = 9
					iteration5.asset = optionicons[option]
					iteration5.color = optioncolors[option]

					if iteration5.asset then
						iteration5.optionicon = S.new("ImageLabel", {
							Parent = iteration5.optionbutton,
							AnchorPoint = Vector2.new(0, 0.5),
							Position = UDim2.fromOffset(iteration5.x, 16),
							Size = UDim2.fromOffset(18, 18),
							BackgroundTransparency = 1,
							BorderSizePixel = 0,
							Image = iteration5.asset,
							ImageColor3 = S.theme.text2,
							ScaleType = Enum.ScaleType.Fit,
							ZIndex = 515,
						}, { ImageColor3 = "text2" })
						iteration5.x += 22
					end

					if iteration5.color then
						iteration5.swatch = S.rawnew("Frame", {
							Parent = iteration5.optionbutton,
							AnchorPoint = Vector2.new(0, 0.5),
							Position = UDim2.fromOffset(iteration5.x, 16),
							Size = UDim2.fromOffset(10, 10),
							BackgroundColor3 = iteration5.color,
							BorderSizePixel = 0,
							ZIndex = 515,
						})
						S.corner(iteration5.swatch, 3)
						S.stroke(iteration5.swatch, 0.62, S.theme.border, 0.5)
						iteration5.x += 18
					end

					iteration5.binding = optionbinding(option)

					S.attachtoggleconfig(iteration5.optionbutton, iteration5.binding)

					iteration5.optionkey = S.label(
						iteration5.optionbutton,
						"",
						UDim2.fromOffset(0, 25),
						S.medium,
						S.theme.text3
					)
					iteration5.optionkey.AnchorPoint = Vector2.new(1, 0.5)
					iteration5.optionkey.Position = UDim2.new(1, -7, 0.5, 0)
					iteration5.optionkey.TextSize = 13
					iteration5.optionkey.TextXAlignment = Enum.TextXAlignment.Center
					iteration5.optionkey.Visible = false
					iteration5.optionkey.ZIndex = 516

					iteration5.optionlabel = S.label(
						iteration5.optionbutton,
						tostring(option),
						UDim2.new(1, -(iteration5.x + 8), 1, 0),
						S.font,
						option == selected and S.theme.text or S.theme.text2
					)
					iteration5.optionlabel.Position = UDim2.fromOffset(iteration5.x, 0)
					iteration5.optionlabel.TextSize = 16
					iteration5.optionlabel.ZIndex = 515

					iteration5.renderoptionkey = function(keyname, bounds, width)
						if not iteration5.optionkey.Parent or not iteration5.optionlabel.Parent then
							return
						end

						if not iteration5.binding.key then
							iteration5.optionkey.Visible = false
							iteration5.optionlabel.Size = UDim2.new(1, -(iteration5.x + 8), 1, 0)
							return
						end

						keyname = S.togglekeyname(iteration5.binding.key)

						bounds = S.measuretext(keyname, 13, S.medium, Vector2.new(120, 25))

						width = math.clamp(math.ceil(bounds.X) + 14, 28, 72)

						iteration5.optionkey.Text = keyname
						iteration5.optionkey.Size = UDim2.fromOffset(width, 25)
						iteration5.optionkey.Visible = true

						iteration5.optionlabel.Size =
							UDim2.new(1, -(iteration5.x + width + 13), 1, 0)
					end

					iteration5.binding.refreshkey = iteration5.renderoptionkey

					iteration5.renderoptionkey()

					optionrows[#optionrows + 1] = {
						value = option,
						button = iteration5.optionbutton,
					}

					iteration5.optionbutton.MouseEnter:Connect(
						function()
							S.tween(
								iteration5.optionlabel,
								{ TextColor3 = S.theme.text },
								S.hoverti,
								nil,
								{ TextColor3 = "text" }
							)
						end
					)

					iteration5.optionbutton.MouseLeave:Connect(
						function()
							S.tween(iteration5.optionlabel, {
								TextColor3 = option == selected and S.theme.text or S.theme.text2,
							}, S.hoverti)
						end
					)

					iteration5.optionbutton.Activated:Connect(function()
						if iteration5.binding.suppressclick then
							iteration5.binding.suppressclick = false
							return
						end

						setselected(option, true)

						S.closepopup()
					end)
				end

				if searchbox then
searchbox:GetPropertyChangedSignal("Text"):Connect(function(query, value2)
						query = string.lower(S.plaintext(searchbox.Text))

						for _, data in ipairs(optionrows) do
							value2 = string.lower(S.plaintext(tostring(data.value)))
							data.button.Visible = query == ""
								or string.find(value2, query, 1, true) ~= nil
						end

						for _, dividerrow in ipairs(dividerrows) do
							dividerrow.Visible = query == ""
						end
					end)

					if searchbox and searchbox.Parent then
searchbox:CaptureFocus()
end
end
			end
		)

		register(holder, name)

		return {
			Get = function() return selected end,

			Set = function(_, option, fire) setselected(option, fire) end,

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
					S.requesthotkeyrefresh(binding)
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
		config,
		parentobject,
		searchable,
		playersdivider,
		multiselect,
		includeeveryone,
		everyonevalue,
		optionicons,
		optioncolors,
		normalized,
		optiondividers,
		pendingdivider,
		value3,
		asset,
		color,
		selected,
		holder,
		title,
		button7,
		display,
		arrow,
		selectedvalues,
		refreshdisplay,
		layoutpreview,
		fireselection,
		issel,
		selectvalue
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

		parentobject = target or body
		searchable = config.searchable ~= false
		playersdivider = config.playersDivider
		multiselect = config.multiselect == true or config.multi == true
		includeeveryone = config.everyone ~= false
		everyonevalue = "Everyone"
		optionicons = table.clone(config.icons or {})
		optioncolors = table.clone(config.colors or {})
		normalized = {}
		optiondividers = {}
		pendingdivider = nil

		for _, entry in ipairs(options) do
			if type(entry) == "table" then
				if entry.Divider == true or entry.divider == true then
					pendingdivider = entry.Text or entry.text or true
				else
					value3 = entry.Value
						or entry.value
						or entry.Name
						or entry.name
						or entry.Text
						or entry.text
					if value3 ~= nil then
						normalized[#normalized + 1] = value3
						asset = entry.Icon or entry.icon
						color = entry.Color or entry.color
						if asset then optionicons[value3] = asset end
						if color then optioncolors[value3] = color end
						if pendingdivider ~= nil then
							optiondividers[value3] = pendingdivider
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

		selected = multiselect and {} or default
		if multiselect then
			for _, value in ipairs(type(default) == "table" and default or {}) do
				if value ~= S.player then selected[value] = true end
			end
		elseif selected == S.player then
			selected = nil
		end

		holder = S.new("Frame", {
			Parent = parentobject,
			Size = UDim2.new(1, 0, 0, 57),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = 15,
		})

		title = S.label(holder, name, UDim2.new(1, 0, 0, 18), S.font)
		title.TextSize = 17

		button7 = S.new("TextButton", {
			Parent = holder,
			Position = UDim2.fromOffset(0, 25),
			Size = UDim2.new(1, 0, 0, 32),
			BackgroundColor3 = S.theme.input,
			BorderSizePixel = 0,
			Text = "",
			AutoButtonColor = false,
			ZIndex = 16,
		}, { BackgroundColor3 = "input" })
		S.corner(button7, 7)

		display = S.label(button7, "Select player", UDim2.new(1, -38, 1, 0), S.font, S.theme.text2)
		display.Position = UDim2.fromOffset(10, 0)
		display.TextSize = 16
		display.TextTruncate = Enum.TextTruncate.None
		display.TextWrapped = multiselect
		display.ZIndex = 17

		arrow = S.image(button7, S.icons.down, 14, S.theme.text3, 17)
		arrow.AnchorPoint = Vector2.new(1, 0.5)
		arrow.Position = UDim2.new(1, -10, 0.5, 0)

		selectedvalues = function(result)
			if not multiselect then return selected end

			result = {}
			if includeeveryone and selected[everyonevalue] then
				result[#result + 1] = everyonevalue
			end
			for _, option in ipairs(options) do
				if selected[option] then result[#result + 1] = option end
			end
			for _, targetplayer in ipairs(S.players:GetPlayers()) do
				if targetplayer ~= S.player and selected[targetplayer] then
					result[#result + 1] = targetplayer
				end
			end
			return result
		end

		layoutpreview = function(width, measured, height)
			width = math.max(1, display.AbsoluteSize.X)
			measured = S.measuretext(display.Text, display.TextSize, display.Font, Vector2.new(width, 10000))
			height = math.max(32, math.ceil(measured.Y) + 12)
			button7.Size = UDim2.new(1, 0, 0, height)
			holder.Size = UDim2.new(1, 0, 0, 25 + height)
		end
		display:GetPropertyChangedSignal("Text"):Connect(layoutpreview)
		display:GetPropertyChangedSignal("AbsoluteSize"):Connect(layoutpreview)
		display:GetPropertyChangedSignal("TextSize"):Connect(layoutpreview)
		display:GetPropertyChangedSignal("Font"):Connect(layoutpreview)

		refreshdisplay = function(values, names)
			if multiselect then
				values = selectedvalues()
				if #values == 0 then
					display.Text = "Select players"
					S.bindtheme(display, "TextColor3", S.theme.text2, "text2")
				display.TextColor3 = S.theme.text2
					return
				end

				names = {}
				for _, value in ipairs(values) do
					names[#names + 1] = typeof(value) == "Instance"
							and value:IsA("Player")
							and value.DisplayName
						or tostring(value)
				end
				display.Text = table.concat(names, ", ")
				S.bindtheme(display, "TextColor3", S.theme.text, "text")
				display.TextColor3 = S.theme.text
				return
			end

			if typeof(selected) == "Instance" and selected:IsA("Player") then
				display.Text = selected.DisplayName
				S.bindtheme(display, "TextColor3", S.theme.text, "text")
				display.TextColor3 = S.theme.text
			elseif selected ~= nil then
				display.Text = tostring(selected)
				S.bindtheme(display, "TextColor3", S.theme.text, "text")
				display.TextColor3 = S.theme.text
			else
				display.Text = "Select player"
				S.bindtheme(display, "TextColor3", S.theme.text2, "text2")
				display.TextColor3 = S.theme.text2
			end
		end

		fireselection = function()
			if callback then callback(selectedvalues()) end
		end

		issel = function(value) return multiselect and selected[value] == true or selected == value end

		selectvalue = function(value, fire, nextstate)
			if value == S.player then return end

			if multiselect then
				nextstate = not selected[value]

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
			if fire ~= false then fireselection() end
		end

		refreshdisplay()

		button7.MouseEnter:Connect(function()
			S.tween(display, { TextColor3 = S.theme.text }, S.hoverti, nil, { TextColor3 = "text" })
			S.tween(
				arrow,
				{ ImageColor3 = S.theme.text2 },
				S.hoverti,
				nil,
				{ ImageColor3 = "text2" }
			)
		end)
		button7.MouseLeave:Connect(function()
			refreshdisplay()
			S.tween(
				arrow,
				{ ImageColor3 = S.theme.text3 },
				S.hoverti,
				nil,
				{ ImageColor3 = "text3" }
			)
		end)

		button7.Activated:Connect(
			function(
				currentplayers,
				totalitems,
				usesearch,
				position,
				size,
				popupy,
				dividerheight,
				wanted,
				available,
				height,
				panel,
				popup,
				searchheight,
				playersearch,
				searchframe,
				searchicon,
				scroll,
				rows,
				makerow,
				divider2,
				dividerrow,
				line,
				divlabel,
				dividerrow2,
				dividertext,
				bounds,
				labelwidth,
				halfgap,
				leftline,
				rightline,
				divlabel2,
				line2,
				empty
			)
				if S.activepopup and S.activepopup.anchor == button7 then
					S.closepopup()
					return
				end

				currentplayers = {}
				for _, targetplayer in ipairs(S.players:GetPlayers()) do
					if targetplayer ~= S.player then
						currentplayers[#currentplayers + 1] = targetplayer
					end
				end

				totalitems = #options + #currentplayers + (includeeveryone and 1 or 0)
				usesearch = searchable and totalitems >= 6
				position = S.overlayposition(button7)
				size = button7.AbsoluteSize
				popupy = position.Y + size.Y + 6
				dividerheight = ((#options > 0 or includeeveryone) and #currentplayers > 0)
						and ((playersdivider and playersdivider ~= "") and 18 or 10)
					or 0
				wanted = math.max(
					70,
					#options * 34
						+ #currentplayers * (44)
						+ (includeeveryone and (38) or 0)
						+ dividerheight
						+ (usesearch and 38 or 0)
						+ 8
				)
				available = S.popuplayer.AbsoluteSize.Y - popupy - 8
				height = math.max(70, math.min(wanted, math.min(330, available)))

				panel, popup =
					S.createpopup(Vector2.new(position.X, popupy), size.X, height, 510, "dropdown")
				popup.anchor = button7
				S.tween(arrow, { Rotation = 180 }, S.tabti)
				popup.onclose = function() S.tween(arrow, { Rotation = 0 }, S.tabti) end

				searchheight = usesearch and 38 or 0
				playersearch = nil

				if usesearch then
					searchframe = S.new("Frame", {
						Parent = panel,
						Position = UDim2.fromOffset(6, 6),
						Size = UDim2.new(1, -12, 0, 32),
						BackgroundColor3 = S.theme.input,
						BackgroundTransparency = 0.06,
						BorderSizePixel = 0,
						ClipsDescendants = true,
						ZIndex = 514,
					}, { BackgroundColor3 = "input" })
					S.corner(searchframe, 7)

					searchicon = S.image(searchframe, S.icons.search, 17, S.theme.text3, 515)
					searchicon.AnchorPoint = Vector2.new(0, 0.5)
					searchicon.Position = UDim2.fromOffset(9, 16)

					playersearch = S.new("TextBox", {
						Parent = searchframe,
						Position = UDim2.fromOffset(33, 0),
						Size = UDim2.new(1, -41, 1, 0),
						BackgroundTransparency = 1,
						BorderSizePixel = 0,
						Text = "",
						PlaceholderText = "Search...",
						PlaceholderColor3 = S.theme.text3,
						TextColor3 = S.theme.text,
						Font = S.font,
						TextSize = 15,
						TextXAlignment = Enum.TextXAlignment.Left,
						ClearTextOnFocus = false,
						ZIndex = 515,
					}, { PlaceholderColor3 = "text3", TextColor3 = "text" })
				end

				scroll = S.new("ScrollingFrame", {
					Parent = panel,
					Position = UDim2.fromOffset(6, 6 + searchheight),
					Size = UDim2.new(1, -12, 1, -12 - searchheight),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					CanvasSize = UDim2.new(),
					AutomaticCanvasSize = Enum.AutomaticSize.Y,
					ScrollBarThickness = 0,
					ScrollBarImageTransparency = 0.56,
					ScrollBarImageColor3 = S.theme.scroll,
					ZIndex = 512,
				}, { ScrollBarImageColor3 = "scroll" })
				S.list(scroll, 2)
				binddropdownscrollbar(scroll, 2)

				rows = {}

				makerow = function(
					value,
					textvalue,
					searchvalue,
					usernamevalue,
					playerrow,
					rowicon,
					iseveryone,
					rowheight,
					row,
					left,
					playericon,
					rowlabel,
					usernamelabel,
					selectedicon,
					data,
					renderselected
				)
					iseveryone = value == everyonevalue
					rowheight = playerrow and (42)
						or (
							iseveryone and (36)
							or (32)
						)
					row = S.new("TextButton", {
						Parent = scroll,
						Size = UDim2.new(1, 0, 0, rowheight),
						BackgroundTransparency = 1,
						BorderSizePixel = 0,
						Text = "",
						AutoButtonColor = false,
						ZIndex = 514,
					})

					left = 9
					playericon = nil
					if playerrow and typeof(value) == "Instance" and value:IsA("Player") then
playericon = S.rawnew("ImageLabel", {
							Parent = row,
							AnchorPoint = Vector2.new(0, 0.5),
							Position = UDim2.fromOffset(7, rowheight * 0.5),
							Size = UDim2.fromOffset(
								30,
								30
							),
							BackgroundTransparency = 1,
							BorderSizePixel = 0,
							Image = S.getplayerthumbnail(value),
							ScaleType = Enum.ScaleType.Crop,
							ZIndex = 515,
						})
						S.corner(playericon, 999)
						left = 43
elseif rowicon then
playericon = S.image(row, rowicon, 15, S.theme.text3, 515)
						playericon.AnchorPoint = Vector2.new(0, 0.5)
						playericon.Position = UDim2.fromOffset(8, rowheight * 0.5)
						playericon.ImageTransparency = 0.08
						left = 31
end

					rowlabel = S.label(
						row,
						textvalue,
						UDim2.new(1, -(left + 31), 0, playerrow and 20 or rowheight),
						playerrow and S.medium or S.font,
						issel(value) and S.theme.text or S.theme.text2
					)
					rowlabel.Position =
						UDim2.fromOffset(left, playerrow and (4) or 0)
					rowlabel.TextSize = playerrow and (14)
						or (iseveryone and 16 or 16)
					rowlabel.TextTruncate = Enum.TextTruncate.AtEnd
					rowlabel.ZIndex = 515

					usernamelabel = nil
					if playerrow then
usernamelabel = S.label(
							row,
							"@" .. tostring(usernamevalue or ""),
							UDim2.new(1, -(left + 31), 0, 17),
							S.font,
							S.theme.text3
						)
						usernamelabel.Position =
							UDim2.fromOffset(left, 21)
						usernamelabel.TextSize = 11
						usernamelabel.TextTruncate = Enum.TextTruncate.AtEnd
						usernamelabel.ZIndex = 515
end

					selectedicon = S.image(row, S.icons.check, 14, S.theme.highlight, 516)
					selectedicon.Size = UDim2.fromOffset(13, 14)
					selectedicon.AnchorPoint = Vector2.new(1, 0.5)
					selectedicon.Position = UDim2.new(1, -8, 0.5, 0)
					selectedicon.ImageTransparency = issel(value) and 0 or 1
					S.bindtheme(selectedicon, "ImageColor3", S.theme.highlight, "highlight")
					S.sethighlightalphabase(selectedicon, "ImageTransparency", issel(value) and 0 or 1)
					selectedicon.ImageTransparency = S.effectivehighlightalpha(issel(value) and 0 or 1)

					data = {
						value = value,
						button = row,
						label = rowlabel,
						username = usernamelabel,
						icon = playericon,
						selectedicon = selectedicon,
						search = string.lower(searchvalue),
					}
					rows[#rows + 1] = data

					renderselected = function(animate, selectednow, labelcolor)
						selectednow = issel(value)
						labelcolor = selectednow and S.theme.text or S.theme.text2
						if animate then
							S.tween(rowlabel, { TextColor3 = labelcolor }, S.hoverti)
							S.tween(selectedicon, { ImageTransparency = selectednow and 0 or 1 }, S.hoverti)
						else
							rowlabel.TextColor3 = labelcolor
							S.sethighlightalphabase(selectedicon, "ImageTransparency", selectednow and 0 or 1)
							selectedicon.ImageTransparency = S.effectivehighlightalpha(selectednow and 0 or 1)
						end
					end

					row.MouseEnter:Connect(function()
						S.tween(
							rowlabel,
							{ TextColor3 = S.theme.text },
							S.hoverti,
							nil,
							{ TextColor3 = "text" }
						)
						if usernamelabel then
							S.tween(
								usernamelabel,
								{ TextColor3 = S.theme.text2 },
								S.hoverti,
								nil,
								{ TextColor3 = "text2" }
							)
						end
					end)

					row.MouseLeave:Connect(function()
						renderselected(true)
						if usernamelabel then
							S.tween(
								usernamelabel,
								{ TextColor3 = S.theme.text3 },
								S.hoverti,
								nil,
								{ TextColor3 = "text3" }
							)
						end
					end)

					row.Activated:Connect(function(selectednow)
						selectvalue(value, true)
						for _, rowdata in ipairs(rows) do
							selectednow = issel(rowdata.value)
							S.tween(rowdata.label, {
								TextColor3 = selectednow and S.theme.text or S.theme.text2,
							}, S.hoverti)
							if rowdata.selectedicon then
								S.tween(rowdata.selectedicon, { ImageTransparency = selectednow and 0 or 1 }, S.hoverti)
							end
						end
						if not multiselect then S.closepopup() end
					end)
				end

				if includeeveryone then
					makerow(
						everyonevalue,
						"Everyone",
						"everyone all players",
						nil,
						false,
						S.icons.usersround
					)
				end

				for _, option in ipairs(options) do
					divider2 = optiondividers[option]
					if divider2 ~= nil then
						dividerrow = S.new("Frame", {
							Parent = scroll,
							Size = UDim2.new(
								1,
								0,
								0,
								(divider2 == true or divider2 == "") and 14 or 20
							),
							BackgroundTransparency = 1,
							BorderSizePixel = 0,
							ZIndex = 514,
						})
						if divider2 == true or divider2 == "" then
							line = S.new("Frame", {
								Parent = dividerrow,
								AnchorPoint = Vector2.new(0.5, 0.5),
								Position = UDim2.fromScale(0.5, 0.5),
								Size = UDim2.new(1, -14, 0, 1),
								BackgroundColor3 = S.theme.border,
								BackgroundTransparency = 0.38,
								BorderSizePixel = 0,
								ZIndex = 515,
							}, { BackgroundColor3 = "border" })
							S.corner(line, 999)
						else
							divlabel = S.label(
								dividerrow,
								S.plaintext(tostring(divider2)),
								UDim2.new(1, -14, 1, 0),
								S.medium,
								S.theme.text3
							)
							divlabel.Position = UDim2.fromOffset(7, 0)
							divlabel.TextSize = 13
							divlabel.ZIndex = 515
						end
					end
					makerow(option, tostring(option), tostring(option))
				end

				dividerrow2 = nil
				if (#options > 0 or includeeveryone) and #currentplayers > 0 then
					dividerrow2 = S.new("Frame", {
						Parent = scroll,
						Size = UDim2.new(
							1,
							0,
							0,
							(playersdivider and playersdivider ~= "") and 18 or 10
						),
						BackgroundTransparency = 1,
						BorderSizePixel = 0,
						ZIndex = 514,
					})

					if playersdivider and playersdivider ~= "" then
						dividertext = S.plaintext(tostring(playersdivider))
						bounds = S.measuretext(dividertext, 15, S.medium, Vector2.new(240, 24))
						labelwidth = math.max(48, math.ceil(bounds.X) + 14)
						halfgap = labelwidth * 0.5 + 8

						leftline = S.new("Frame", {
							Parent = dividerrow2,
							AnchorPoint = Vector2.new(0, 0.5),
							Position = UDim2.new(0, 7, 0.5, 0),
							Size = UDim2.new(0.5, -(halfgap + 7), 0, 1),
							BackgroundColor3 = S.theme.border,
							BackgroundTransparency = 0.42,
							BorderSizePixel = 0,
							ZIndex = 515,
						}, { BackgroundColor3 = "border" })
						S.corner(leftline, 999)

						rightline = S.new("Frame", {
							Parent = dividerrow2,
							AnchorPoint = Vector2.new(1, 0.5),
							Position = UDim2.new(1, -7, 0.5, 0),
							Size = UDim2.new(0.5, -(halfgap + 7), 0, 1),
							BackgroundColor3 = S.theme.border,
							BackgroundTransparency = 0.42,
							BorderSizePixel = 0,
							ZIndex = 515,
						}, { BackgroundColor3 = "border" })
						S.corner(rightline, 999)

						divlabel2 = S.label(
							dividerrow2,
							dividertext,
							UDim2.fromOffset(labelwidth, 24),
							S.medium,
							S.theme.text3
						)
						divlabel2.AnchorPoint = Vector2.new(0.5, 0.5)
						divlabel2.Position = UDim2.fromScale(0.5, 0.5)
						divlabel2.TextSize = 15
						divlabel2.TextXAlignment = Enum.TextXAlignment.Center
						divlabel2.ZIndex = 516
					else
						line2 = S.new("Frame", {
							Parent = dividerrow2,
							AnchorPoint = Vector2.new(0.5, 0.5),
							Position = UDim2.fromScale(0.5, 0.5),
							Size = UDim2.new(1, -14, 0, 1),
							BackgroundColor3 = S.theme.border,
							BackgroundTransparency = 0.42,
							BorderSizePixel = 0,
							ZIndex = 515,
						}, { BackgroundColor3 = "border" })
						S.corner(line2, 999)
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
					empty =
						S.label(scroll, "No players", UDim2.new(1, 0, 0, 38), S.font, S.theme.text3)
					empty.TextSize = 14
					empty.TextXAlignment = Enum.TextXAlignment.Center
				end

				if playersearch then
playersearch:GetPropertyChangedSignal("Text"):Connect(function(query)
						query = string.lower(S.plaintext(playersearch.Text))
						for _, data in ipairs(rows) do
							data.button.Visible = query == ""
								or string.find(data.search, query, 1, true) ~= nil
						end
						if dividerrow2 then dividerrow2.Visible = query == "" end
					end)

					if playersearch and playersearch.Parent then
playersearch:CaptureFocus()
end
end
			end
		)

		register(holder, name)

		return {
			Get = function() return selectedvalues() end,
			Set = function(_, value, fire)
				if multiselect then
					table.clear(selected)
					for _, entry in ipairs(type(value) == "table" and value or {}) do
						if entry ~= S.player then selected[entry] = true end
					end
				else
					selected = value == S.player and nil or value
				end
				refreshdisplay()
				if fire ~= false then fireselection() end
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

	function section:AddMultiPlayerDropdown(name, default, callback, target, config)
		config = table.clone(config or {})
		config.multiselect = true
		return self:AddPlayerDropdown(name, {}, default or {}, callback, target, config)
	end

	-- multiselect

	function section:AddMultiDropdown(
		name,
		options,
		default,
		callback,
		target,
		config,
		parentobject,
		keypickerenabled,
		keypickerlabel,
		keyformatter,
		selected,
		holder,
		title,
		button8,
		valuetext,
		arrow,
		getselected,
		refresh
	)
		parentobject = target or body

		config = config or {}
		keypickerenabled = config.keypicker == true or config.KeyPicker == true
		keypickerlabel = tostring(config.keypickerlabel or config.KeyPickerLabel or "Add key")
		keyformatter = config.keyformatter or config.KeyFormatter

		selected = {}

		for _, option in ipairs(default or {}) do
			selected[option] = true
		end

		holder = S.new("Frame", {
			Parent = parentobject,

			Size = UDim2.new(1, 0, 0, 57),

			BackgroundTransparency = 1,

			ZIndex = 15,
		})

		title = S.label(holder, name, UDim2.new(1, 0, 0, 18), S.font)

		title.TextSize = 17

		button8 = S.new("TextButton", {
			Parent = holder,

			Position = UDim2.fromOffset(0, 25),

			Size = UDim2.new(1, 0, 0, 32),

			BackgroundColor3 = S.theme.input,

			BorderSizePixel = 0,

			Text = "",
			AutoButtonColor = false,

			ZIndex = 16,
		}, { BackgroundColor3 = "input" })

		S.corner(button8, 7)

		valuetext = S.label(button8, "", UDim2.new(1, -38, 1, 0), S.font)

		valuetext.Position = UDim2.fromOffset(10, 0)

		valuetext.TextSize = 17

		valuetext.TextTruncate = Enum.TextTruncate.AtEnd

		valuetext.ZIndex = 17

		arrow = S.image(button8, S.icons.down, 14, S.theme.text3, 17)

		arrow.AnchorPoint = Vector2.new(1, 0.5)

		arrow.Position = UDim2.new(1, -10, 0.5, 0)

		button8.MouseEnter:Connect(function()
			S.tween(
				valuetext,
				{ TextColor3 = S.theme.text },
				S.hoverti,
				nil,
				{ TextColor3 = "text" }
			)
			S.tween(
				arrow,
				{ ImageColor3 = S.theme.text2 },
				S.hoverti,
				nil,
				{ ImageColor3 = "text2" }
			)
		end)
		button8.MouseLeave:Connect(function()
			S.tween(
				valuetext,
				{ TextColor3 = S.theme.text2 },
				S.hoverti,
				nil,
				{ TextColor3 = "text2" }
			)
			S.tween(
				arrow,
				{ ImageColor3 = S.theme.text3 },
				S.hoverti,
				nil,
				{ ImageColor3 = "text3" }
			)
		end)

		getselected = function(result)
			result = {}

			for _, option in ipairs(options) do
				if selected[option] then table.insert(result, option) end
			end

			return result
		end

		refresh = function(fire, values)
			values = getselected()

			valuetext.Text = #values > 0 and table.concat(values, ", ") or "None"

			if fire and callback then callback(values) end
		end

		button8.Activated:Connect(
			function(
				panel,
				popup,
				keypickerowner,
				keypickerlistening,
				scroll,
				pickerrow,
				pickerlabel,
				pickerkey
			)
				panel, popup = dropdownpopup(button8, #options + (keypickerenabled and 1 or 0))

				if not panel or not popup then return end

				S.tween(arrow, {
					Rotation = 180,
				}, S.tabti)

				keypickerowner = nil
				keypickerlistening = false

				popup.onclose = function()
					if keypickerlistening and keypickerowner then
						keypickerlistening = false
						S.endkeycapture(keypickerowner, nil)
					end

					S.tween(arrow, {
						Rotation = 0,
					}, S.tabti)
				end

				scroll = S.new("ScrollingFrame", {
					Parent = panel,

					Position = UDim2.fromOffset(4, 4),

					Size = UDim2.new(1, -8, 1, -8),

					BackgroundTransparency = 1,

					BorderSizePixel = 0,

					CanvasSize = UDim2.new(),

					AutomaticCanvasSize = Enum.AutomaticSize.Y,

					ScrollBarThickness = 0,

					ScrollBarImageTransparency = 0.56,

					ScrollBarImageColor3 = S.theme.scroll,

					ZIndex = 512,
				}, { ScrollBarImageColor3 = "scroll" })

				S.list(scroll, 2)
				binddropdownscrollbar(scroll, 2)

				if keypickerenabled then
					pickerrow = S.new("TextButton", {
						Parent = scroll,
						Size = UDim2.new(1, 0, 0, 32),
						BackgroundColor3 = S.theme.hover,
						BackgroundTransparency = 1,
						BorderSizePixel = 0,
						Text = "",
						AutoButtonColor = false,
						ZIndex = 514,
					}, { BackgroundColor3 = "hover" })
					S.corner(pickerrow, 6)
					S.keyeditbuttons[pickerrow] = true

					pickerlabel = S.label(
						pickerrow,
						keypickerlabel,
						UDim2.new(1, -70, 1, 0),
						S.font,
						S.theme.text2
					)
					pickerlabel.Position = UDim2.fromOffset(9, 0)
					pickerlabel.TextSize = 15
					pickerlabel.ZIndex = 515

					pickerkey = S.label(
						pickerrow,
						"Press",
						UDim2.fromOffset(58, 32),
						S.medium,
						S.theme.text3
					)
					pickerkey.AnchorPoint = Vector2.new(1, 0)
					pickerkey.Position = UDim2.new(1, -9, 0, 0)
					pickerkey.TextSize = 13
					pickerkey.TextXAlignment = Enum.TextXAlignment.Right
					pickerkey.ZIndex = 515

					keypickerowner = pickerrow

					pickerrow.MouseEnter:Connect(
						function()
							S.tween(
								pickerlabel,
								{ TextColor3 = S.theme.text },
								S.hoverti,
								nil,
								{ TextColor3 = "text" }
							)
						end
					)

					pickerrow.MouseLeave:Connect(
						function()
							S.tween(
								pickerlabel,
								{ TextColor3 = S.theme.text2 },
								S.hoverti,
								nil,
								{ TextColor3 = "text2" }
							)
						end
					)

					pickerrow.Activated:Connect(function()
						if keypickerlistening then
							keypickerlistening = false
							S.endkeycapture(pickerrow, nil)
							pickerkey.Text = "Press"
							return
						end

						keypickerlistening = true
						pickerkey.Text = "..."

						if
							not S.beginkeycapture(
								pickerrow,
								function()
									keypickerlistening = false
									pickerkey.Text = "Press"
								end,
								function(key, option2)
									keypickerlistening = false
									option2 = keyformatter and keyformatter(key)
										or S.togglekeyname(key)

									option2 = tostring(option2 or "")
									if option2 == "" then
										pickerkey.Text = "Press"
										return
									end

									if not table.find(options, option2) then
										table.insert(options, option2)
									end

									selected[option2] = true
									pickerkey.Text = option2
									refresh(true)
									S.closepopup()
								end,
								nil,
								{
									AllowBlacklisted = true,
									AllowEscape = true,
									KeepDelete = true,
								}
							)
						then
							keypickerlistening = false
							pickerkey.Text = "Press"
						end
					end)
				end

				for _, option, iteration6 in S.scopediterator(2, ipairs(options)) do
					iteration6.row = S.new("TextButton", {
						Parent = scroll,

						Size = UDim2.new(1, 0, 0, 32),

						BackgroundColor3 = S.theme.hover,

						BackgroundTransparency = 1,

						BorderSizePixel = 0,

						Text = "",

						AutoButtonColor = false,

						ZIndex = 514,
					}, { BackgroundColor3 = "hover" })

					S.corner(iteration6.row, 6)

					iteration6.textobject = S.label(
						iteration6.row,
						option,
						UDim2.new(1, -34, 1, 0),
						S.font,
						S.theme.text2
					)

					iteration6.textobject.Position = UDim2.fromOffset(9, 0)

					iteration6.textobject.TextSize = 15
					iteration6.textobject.ZIndex = 515

					iteration6.check =
						S.image(iteration6.row, S.icons.check, 13, S.theme.text2, 516)

					iteration6.check.AnchorPoint = Vector2.new(1, 0.5)

					iteration6.check.Position = UDim2.new(1, -9, 0.5, 0)

					iteration6.check.ImageTransparency = selected[option] and 0 or 1

					iteration6.row.MouseEnter:Connect(
						function()
							S.tween(
								iteration6.textobject,
								{ TextColor3 = S.theme.text },
								S.hoverti,
								nil,
								{ TextColor3 = "text" }
							)
						end
					)

					iteration6.row.MouseLeave:Connect(
						function()
							S.tween(iteration6.textobject, {
								TextColor3 = selected[option] and S.theme.text or S.theme.text2,
							}, S.hoverti)
						end
					)

					iteration6.row.Activated:Connect(function()
						if selected[option] then
							selected[option] = nil
						else
							selected[option] = true
						end

						S.tween(
							iteration6.textobject,
							{ TextColor3 = selected[option] and S.theme.text or S.theme.text2 },
							S.fastti
						)

						S.tween(iteration6.check, {
							ImageTransparency = selected[option] and 0 or 1,
						}, S.fastti)

						refresh(true)
					end)
				end
			end
		)

		refresh(false)

		register(holder, name)

		return {
			Get = function() return getselected() end,
			Set = function(_, values, fire)
				table.clear(selected)
				for _, option in ipairs(values or {}) do
					if table.find(options, option) then selected[option] = true end
				end
				refresh(fire ~= false)
			end,
			SetOptions = function(_, values)
				options = values or {}
				for option in pairs(selected) do
					if not table.find(options, option) then selected[option] = nil end
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
		target,
		parentobject,
		holder,
		title,
		field,
		box,
		focused,
		updating,
		settruncate,
		measure,
		updateinputviewport
	)
		parentobject = target or body

		holder = S.new("Frame", {
			Parent = parentobject,
			Size = UDim2.new(1, 0, 0, 57),
			BackgroundTransparency = 1,
			ZIndex = 15,
		})

		title = S.label(holder, name, UDim2.new(1, 0, 0, 18), S.font)
		title.TextSize = 17

		field = S.new("ScrollingFrame", {
			Parent = holder,
			Position = UDim2.fromOffset(0, 25),
			Size = UDim2.new(1, 0, 0, 32),
			BackgroundColor3 = S.theme.input,
			BorderSizePixel = 0,
			CanvasSize = UDim2.fromOffset(0, 0),
			CanvasPosition = Vector2.zero,
			ScrollBarThickness = 0,
			ScrollingDirection = Enum.ScrollingDirection.X,
			ElasticBehavior = Enum.ElasticBehavior.Never,
			ClipsDescendants = true,
			ZIndex = 16,
		}, { BackgroundColor3 = "input" })
		S.corner(field, 7)

		box = S.new("TextBox", {
			Parent = field,
			Position = UDim2.fromOffset(10, 0),
			Size = UDim2.new(1, -20, 1, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Text = tostring(default or ""),
			PlaceholderText = placeholder or "",
			PlaceholderColor3 = S.theme.text3,
			TextColor3 = S.theme.text2,
			Font = S.font,
			TextSize = 17,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
			TextWrapped = false,
			ClearTextOnFocus = false,
			MultiLine = false,
			ZIndex = 17,
		}, { PlaceholderColor3 = "text3", TextColor3 = "text2" })

		focused = false
		updating = false

		settruncate = function(value) box.TextTruncate = value end

		measure = function(value)
			return S.measuretext(
				tostring(value or ""),
				box.TextSize,
				box.Font,
				Vector2.new(100000, 32)
			).X
		end

		updateinputviewport = function(
			keepcursor,
			viewport,
			fullwidth,
			cursor,
			prefix,
			cursorx,
			current,
			left,
			right,
			target2,
			maximum
		)
			if updating or not field.Parent or not box.Parent then return end
			updating = true

			viewport = math.max(0, field.AbsoluteSize.X - 20)

			if focused then
				fullwidth = math.max(viewport, math.ceil(measure(box.Text)) + 4)
				box.Size = UDim2.fromOffset(fullwidth, 32)
				field.CanvasSize = UDim2.fromOffset(fullwidth + 20, 0)

				if keepcursor ~= false then
					cursor = box.CursorPosition
					if cursor < 1 then cursor = #box.Text + 1 end

					prefix = box.Text:sub(1, math.max(0, cursor - 1))
					cursorx = measure(prefix)
					current = field.CanvasPosition.X
					left = current + 6
					right = current + viewport - 12
					target2 = current

					if cursorx > right then
						target2 = cursorx - viewport + 18
					elseif cursorx < left then
						target2 = math.max(0, cursorx - 8)
					end

					maximum = math.max(0, fullwidth - viewport)
					field.CanvasPosition = Vector2.new(math.clamp(target2, 0, maximum), 0)
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
			S.tween(box, { TextColor3 = S.theme.text }, S.hoverti, nil, { TextColor3 = "text" })
			updateinputviewport(true)
		end)

		box:GetPropertyChangedSignal("Text"):Connect(function()
			if focused then updateinputviewport(true) end
		end)

		box:GetPropertyChangedSignal("CursorPosition"):Connect(function()
			if focused then updateinputviewport(true) end
		end)

		field
			:GetPropertyChangedSignal("AbsoluteSize")
			:Connect(function() updateinputviewport(focused) end)

		field.MouseEnter:Connect(
			function()
				S.tween(box, { TextColor3 = S.theme.text }, S.hoverti, nil, { TextColor3 = "text" })
			end
		)

		field.MouseLeave:Connect(function()
			if not focused then
				S.tween(
					box,
					{ TextColor3 = S.theme.text2 },
					S.hoverti,
					nil,
					{ TextColor3 = "text2" }
				)
			end
		end)

		box.FocusLost:Connect(function()
			focused = false
			settruncate(Enum.TextTruncate.AtEnd)
			updateinputviewport(false)
			S.tween(box, { TextColor3 = S.theme.text2 }, S.hoverti, nil, { TextColor3 = "text2" })

			if callback then callback(box.Text) end
		end)

		register(holder, name)
		return box
	end

	-- key picker

	function section:AddKeyPicker(
		name,
		defaultkey,
		callback,
		target,
		captureoptions,
		selected,
		parentobject,
		compactpicker,
		hidelabel,
		fullwidth,
		row,
		title,
		button9,
		keystroke,
		keytext,
		selected2,
		listening,
		keyname,
		render,
		setkey
	)
		

		parentobject = target or body

		captureoptions = type(captureoptions) == "table" and captureoptions or {}
		compactpicker = captureoptions.Compact == true or captureoptions.compact == true
		hidelabel = captureoptions.HideLabel == true or captureoptions.hideLabel == true
		fullwidth = captureoptions.FullWidth == true or captureoptions.fullWidth == true

		row = S.new("Frame", {
			Parent = parentobject,

			Size = UDim2.new(1, 0, 0, 29),

			BackgroundTransparency = 1,
			ZIndex = 15,
		})

		title = S.label(row, name, UDim2.new(1, -68, 1, 0), S.font)

		title.TextSize = 17
		title.Visible = not hidelabel

		button9 = S.new("TextButton", {
			Parent = row,

			AnchorPoint = Vector2.new(1, 0.5),

			Position = UDim2.new(1, 0, 0.5, 0),

			Size = fullwidth and UDim2.new(1, 0, 0, 25) or UDim2.fromOffset(56, 25),

			BackgroundColor3 = S.theme.input,
			BackgroundTransparency = 0.08,
			BorderSizePixel = 0,

			Text = "",
			AutoButtonColor = false,
			ZIndex = 16,
		}, { BackgroundColor3 = "input" })

		S.corner(button9, 6)
		keystroke = S.stroke(button9, 0.7, S.theme.border, 0.6)

		keytext = S.label(button9, "", UDim2.fromScale(1, 1), S.medium, S.theme.text2)

		keytext.TextSize = 14
		keytext.TextXAlignment = Enum.TextXAlignment.Center
		keytext.ZIndex = 17

		selected2 = nil
		if defaultkey ~= false then selected2 = defaultkey or Enum.KeyCode.RightShift end

		listening = false

		keyname = function(key) return S.togglekeyname(key) end

		render = function(value, bounds, singlecharacter, width)
			value = listening and "..." or keyname(selected2)

			keytext.Text = value

			bounds = S.measuretext(value, 14, S.medium, Vector2.new(200, 25))

			singlecharacter = #S.plaintext(value) == 1

			width = compactpicker
					and math.clamp(math.ceil(bounds.X) + (singlecharacter and 12 or 14), 28, 40)
				or math.clamp(
					math.ceil(bounds.X) + (singlecharacter and 14 or 20),
					singlecharacter and 30 or 42,
					112
				)

			S.tween(button9, {
				Size = fullwidth and UDim2.new(1, 0, 0, 25) or UDim2.fromOffset(width, 25),
			}, S.fastti)

			if hidelabel or fullwidth then
				title.Size = UDim2.fromOffset(0, 0)
			else
				title.Size = UDim2.new(1, -width - 12, 1, 0)
			end

			S.tween(keystroke, {
				Color = S.theme.border,
				Transparency = listening and 0.42 or 0.7,
			}, S.fastti, nil, { Color = "border" })
		end

		setkey = function(key, fire, valid)
			if key == nil then
				selected2 = nil
				render()
				if fire ~= false and callback then callback(nil) end
				return
			end

			if typeof(key) == "string" then key = S.keyfromname(key) end

			if typeof(key) ~= "EnumItem" then return end

			valid = key.EnumType == Enum.KeyCode
				or (key.EnumType == Enum.UserInputType and S.validmousebind(key))

			if not valid then return end

			selected2 = key
			render()

			if fire ~= false and callback then callback(key) end
		end

		button9.MouseEnter:Connect(
			function()
				S.tween(
					keytext,
					{ TextColor3 = S.theme.text },
					S.hoverti,
					nil,
					{ TextColor3 = "text" }
				)
			end
		)

		button9.MouseLeave:Connect(
			function()
				S.tween(
					keytext,
					{ TextColor3 = S.theme.text2 },
					S.hoverti,
					nil,
					{ TextColor3 = "text2" }
				)
			end
		)

		button9.Activated:Connect(function()
			if listening then
				listening = false
				S.endkeycapture(row, nil)
				render()
				return
			end

			listening = true

			if
				not S.beginkeycapture(
					row,
					function()
						listening = false
						render()
					end,
					function(selectedkey)
						listening = false
						setkey(selectedkey, true)
					end,
					nil,
					captureoptions
				)
			then
				listening = false
			end

			render()
		end)

		S.connect(row.Destroying, function()
			if listening then
				listening = false
				S.endkeycapture(row, nil)
			end
		end)

		render()

		register(row, name)

		return {
			Get = function() return selected2 end,

			Set = function(_, key, fire) setkey(key, fire) end,
			Object = row,
			TextObject = title,
		}
	end

	-- standalone color

	function section:AddColorPicker(
		name,
		color,
		callback,
		target,
		parentobject,
		row,
		title,
		button10,
		swatch,
		swatchglow,
		state
	)
		parentobject = target or body

		row = S.new("Frame", {
			Parent = parentobject,

			Size = UDim2.new(1, 0, 0, 27),

			BackgroundTransparency = 1,

			ZIndex = 15,
		})

		title = S.label(row, name, UDim2.new(1, -38, 1, 0), S.font)

		title.TextSize = 17

		button10 = S.new("TextButton", {
			Parent = row,

			AnchorPoint = Vector2.new(1, 0.5),

			Position = UDim2.new(1, 0, 0.5, 0),

			Size = UDim2.fromOffset(22, 22),

			BackgroundTransparency = 1,

			BorderSizePixel = 0,

			Text = "",

			AutoButtonColor = false,

			ZIndex = 16,
		})

		swatch = S.new("Frame", {
			Parent = button10,

			Size = UDim2.fromScale(1, 1),

			BackgroundColor3 = color,

			BorderSizePixel = 0,

			ZIndex = 17,
		})

		S.corner(swatch, 5)

		swatchglow =
			S.addshadow(swatch, "ColorGlow", 0.62, 7, 1, -1, color, UDim2.fromOffset(0, 0), false)

		state = S.createcolorstate(color, callback, swatch)

		state.swatchglow = swatchglow
		state:apply()

		button10.Activated:Connect(function() S.opencolorpicker(button10, state) end)

		register(row, name)

		state.Object = row
		state.TextObject = title
		return state
	end

	-- divider / separator

	function section:AddDivider(
		textvalue,
		target,
		parentobject,
		hastext,
		holder,
		textobject,
		leftline,
		rightline,
		line
	)
		parentobject = target or body
		hastext = textvalue ~= nil and tostring(textvalue) ~= ""
		holder = S.new("Frame", {
			Parent = parentobject,
			Size = UDim2.new(1, 0, 0, hastext and 24 or 10),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = 15,
		})

		if hastext then
			textobject = S.label(
				holder,
				tostring(textvalue),
				UDim2.fromOffset(110, 24),
				S.medium,
				S.theme.text3
			)
			textobject.AnchorPoint = Vector2.new(0.5, 0.5)
			textobject.Position = UDim2.fromScale(0.5, 0.5)
			textobject.TextSize = 14
			textobject.TextXAlignment = Enum.TextXAlignment.Center
			textobject.ZIndex = 16

			leftline = S.new("Frame", {
				Parent = holder,
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 0, 0.5, 0),
				Size = UDim2.new(0.5, -62, 0, 1),
				BackgroundColor3 = S.theme.border,
				BackgroundTransparency = 0.48,
				BorderSizePixel = 0,
				ZIndex = 15,
			}, { BackgroundColor3 = "border" })
			rightline = S.new("Frame", {
				Parent = holder,
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, 0, 0.5, 0),
				Size = UDim2.new(0.5, -62, 0, 1),
				BackgroundColor3 = S.theme.border,
				BackgroundTransparency = 0.48,
				BorderSizePixel = 0,
				ZIndex = 15,
			}, { BackgroundColor3 = "border" })
			S.corner(leftline, 999)
			S.corner(rightline, 999)
		else
			line = S.new("Frame", {
				Parent = holder,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.new(1, 0, 0, 1),
				BackgroundColor3 = S.theme.border,
				BackgroundTransparency = 0.48,
				BorderSizePixel = 0,
				ZIndex = 15,
			}, { BackgroundColor3 = "border" })
			S.corner(line, 999)
		end

		register(holder, textvalue or "separator")
		return holder
	end

	function section:AddSeparator(target) return self:AddDivider(nil, target) end

	-- progress bar

	function section:AddProgressBar(
		name,
		default,
		suffix,
		target,
		parentobject,
		holder,
		titleobject2,
		valueobject,
		track,
		fill,
		glow,
		value,
		set
	)
		parentobject = target or body
		holder = S.new("Frame", {
			Parent = parentobject,
			Size = UDim2.new(1, 0, 0, 43),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = 15,
		})

		titleobject2 = S.label(holder, name, UDim2.new(1, -80, 0, 19), S.font, S.theme.text2)
		titleobject2.TextSize = 16
		valueobject = S.label(holder, "", UDim2.fromOffset(76, 19), S.medium, S.theme.text3)
		valueobject.AnchorPoint = Vector2.new(1, 0)
		valueobject.Position = UDim2.new(1, 0, 0, 0)
		valueobject.TextXAlignment = Enum.TextXAlignment.Right
		valueobject.TextSize = 15

		track = S.new("Frame", {
			Parent = holder,
			Position = UDim2.fromOffset(0, 30),
			Size = UDim2.new(1, 0, 0, 6),
			BackgroundColor3 = S.theme.track,
			BorderSizePixel = 0,
			ZIndex = 16,
		}, { BackgroundColor3 = "track" })
		S.corner(track, 999)

		fill = S.new("Frame", {
			Parent = track,
			Size = UDim2.fromScale(0, 1),
			BackgroundColor3 = S.theme.highlight,
			BorderSizePixel = 0,
			ZIndex = 17,
		}, { BackgroundColor3 = "highlight" })
		S.corner(fill, 999)
		glow = S.addglow(fill, "active")
		if glow then glow.Transparency = 0.7 end

		value = 0
		set = function(number)
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
			TextObject = titleobject2,
		}
	end

	-- radio

	function section:AddRadio(
		name,
		options,
		default,
		callback,
		target,
		multiselect,
		holder,
		titleobject3,
		row,
		grid,
		buttons,
		minwidth,
		selected,
		isactive,
		values,
		render,
		layout,
		cellwidth
	)
		options = table.clone(options or {})
		while #options > 6 do table.remove(options) end
		multiselect = multiselect == true
		holder = S.new("Frame", {
			Parent = target or body,
			Size = UDim2.new(1, 0, 0, 50),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = 15,
		})
		titleobject3 = S.label(holder, name, UDim2.new(1, 0, 0, 18), S.font, S.theme.text2)
		titleobject3.TextSize = 16
		row = S.new("Frame", {
			Parent = holder,
			Position = UDim2.fromOffset(0, 22),
			Size = UDim2.new(1, 0, 0, 28),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = 16,
		})
		grid = S.new("UIGridLayout", {
			Parent = row,
			CellPadding = UDim2.fromOffset(8, 6),
			CellSize = UDim2.fromOffset(120, 28),
			FillDirection = Enum.FillDirection.Horizontal,
			FillDirectionMaxCells = 1,
			HorizontalAlignment = Enum.HorizontalAlignment.Left,
			SortOrder = Enum.SortOrder.LayoutOrder,
		})
		buttons = {}
		minwidth = 80
		selected = multiselect and {} or (default or options[1])
		if multiselect then
			if type(default) == "table" then
				for _, value in ipairs(default) do
					selected[value] = true
				end
			elseif default ~= nil then
				selected[default] = true
			end
		end

		isactive = function(value)
			return multiselect and selected[value] == true or selected == value
		end

		values = function(result)
			if not multiselect then return selected end
			result = {}
			for _, option in ipairs(options) do
				if selected[option] then result[#result + 1] = option end
			end
			return result
		end

		render = function(active)
			for value, data in pairs(buttons) do
				active = isactive(value)
				if active ~= data.active then
					data.active = active
					S.tween(
						data.text,
						{ TextColor3 = active and S.theme.text or S.theme.text3 },
						S.fastti
					)
					S.tween(
						data.ring,
						{ Color = active and S.theme.highlight or S.theme.border },
						S.fastti,
						nil,
						{ Color = active and "highlight" or "border" }
					)
					S.tween(data.dot, { BackgroundTransparency = active and 0 or 1 }, S.fastti)
				end
			end
		end

		layout = function(width, columns, rows, height, available)
			width = math.max(1, holder.AbsoluteSize.X)
			columns = math.max(
				1,
				math.min(#options, math.floor((width + 8) / (minwidth + 8)))
			)
			if #options >= 5 then columns = 2 end
			rows = math.ceil(#options / columns)
			height = math.max(0, rows * 34 - 6)
			available = math.max(1, width - 8 * (columns - 1))
			cellwidth = math.max(1, math.floor(available / columns) - 1)
			grid.FillDirectionMaxCells = columns
			grid.CellSize = UDim2.fromOffset(cellwidth, 28)
			row.Size = UDim2.new(1, 0, 0, height)
			holder.Size = UDim2.new(1, 0, 0, 22 + height)
		end

		for index, option, iteration7 in S.scopediterator(2, ipairs(options)) do
			iteration7.active = isactive(option)
			iteration7.text = tostring(option)
			minwidth = math.max(
				minwidth,
				math.min(
					180,
					math.ceil(S.measuretext(iteration7.text, 14, S.font, Vector2.new(1000, 28)).X)
						+ 36
				)
			)
			iteration7.button = S.new("TextButton", {
				Parent = row,
				LayoutOrder = index,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Text = "",
				AutoButtonColor = false,
				ZIndex = 16,
			})
			iteration7.circle = S.new("Frame", {
				Parent = iteration7.button,
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 4, 0.5, 0),
				Size = UDim2.fromOffset(16, 16),
				BackgroundColor3 = S.theme.input,
				BorderSizePixel = 0,
				ZIndex = 17,
			}, { BackgroundColor3 = "input" })
			S.corner(iteration7.circle, 999)
			iteration7.ring = S.stroke(
				iteration7.circle,
				0.3,
				iteration7.active and S.theme.highlight or S.theme.border,
				1
			)
			S.bindtheme(iteration7.ring, "Color", iteration7.active and S.theme.highlight or S.theme.border, iteration7.active and "highlight" or "border")
			iteration7.dot = S.new("Frame", {
				Parent = iteration7.circle,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromOffset(8, 8),
				BackgroundColor3 = S.theme.highlight,
				BackgroundTransparency = iteration7.active and 0 or 1,
				BorderSizePixel = 0,
				ZIndex = 18,
			}, { BackgroundColor3 = "highlight" })
			S.corner(iteration7.dot, 999)
			iteration7.textobject = S.label(
				iteration7.button,
				iteration7.text,
				UDim2.new(1, -30, 1, 0),
				S.font,
				iteration7.active and S.theme.text or S.theme.text3
			)
			iteration7.textobject.Position = UDim2.fromOffset(28, 0)
			iteration7.textobject.TextSize = 14
			iteration7.textobject.TextTruncate = Enum.TextTruncate.AtEnd
			iteration7.textobject.ZIndex = 17
			buttons[option] = {
				button = iteration7.button,
				dot = iteration7.dot,
				ring = iteration7.ring,
				text = iteration7.textobject,
				active = iteration7.active,
			}
			iteration7.button.MouseEnter:Connect(
				function()
					S.tween(
						iteration7.textobject,
						{ TextColor3 = S.theme.text },
						S.hoverti,
						nil,
						{ TextColor3 = "text" }
					)
				end
			)
			iteration7.button.MouseLeave:Connect(
				function()
					S.tween(
						iteration7.textobject,
						{ TextColor3 = isactive(option) and S.theme.text or S.theme.text3 },
						S.hoverti
					)
				end
			)
			iteration7.button.Activated:Connect(function()
				if multiselect then
					selected[option] = not selected[option] or nil
				elseif selected == option then
					return
				else
					selected = option
				end
				render()
				if callback then callback(values()) end
			end)
		end
		S.connect(holder:GetPropertyChangedSignal("AbsoluteSize"), layout)
		layout()
		register(holder, name)
		return {
			Get = function() return values() end,
			Set = function(_, value, fire)
				if multiselect then
					table.clear(selected)
					if type(value) == "table" then
						for _, item in ipairs(value) do
							if buttons[item] then selected[item] = true end
						end
					elseif buttons[value] then
						selected[value] = true
					end
				elseif buttons[value] then
					selected = value
				else
					return
				end
				render()
				if fire ~= false and callback then callback(values()) end
			end,
			Object = holder,
			TextObject = titleobject3,
			Multi = multiselect,
		}
	end

	-- badge / status

	function section:AddBadge(
		name,
		textvalue,
		color,
		target,
		parentobject,
		holder,
		titleobject4,
		customcolor,
		badge,
		textobject,
		resizebadge
	)
		parentobject = target or body
		holder = S.new("Frame", {
			Parent = parentobject,
			Size = UDim2.new(1, 0, 0, 30),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = 15,
		})

		titleobject4 = S.label(holder, name, UDim2.new(1, -88, 1, 0), S.font, S.theme.text2)
		titleobject4.TextSize = 16
		titleobject4.TextTruncate = Enum.TextTruncate.AtEnd
		titleobject4.ZIndex = 16

		customcolor = typeof(color) == "Color3"
		badge = S.new("Frame", {
			Parent = holder,
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, 0, 0.5, 0),
			Size = UDim2.fromOffset(52, 24),
			BackgroundColor3 = customcolor and color or S.theme.input,
			BackgroundTransparency = 0.02,
			BorderSizePixel = 0,
			ZIndex = 16,
		})
		if not customcolor then S.bindtheme(badge, "BackgroundColor3", S.theme.input, "input") end
		S.corner(badge, 7)

		textobject =
			S.label(badge, textvalue or "Ready", UDim2.new(1, -20, 1, 0), S.medium, S.theme.text2)
		textobject.Position = UDim2.fromOffset(10, 0)
		textobject.TextXAlignment = Enum.TextXAlignment.Center
		textobject.TextYAlignment = Enum.TextYAlignment.Center
		textobject.TextSize = 13
		textobject.TextTruncate = Enum.TextTruncate.AtEnd
		textobject.ZIndex = 17

		resizebadge = function(bounds, width)
			bounds = S.measuretext(
				S.plaintext(textobject.Text or ""),
				textobject.TextSize,
				S.medium,
				Vector2.new(300, 24)
			)
			width = math.clamp(math.ceil(bounds.X) + 20, 34, 180)
			badge.Size = UDim2.fromOffset(width, 24)
			titleobject4.Size = UDim2.new(1, -width - 12, 1, 0)
		end

		S.connect(textobject:GetPropertyChangedSignal("Text"), resizebadge)
		resizebadge()
		register(holder, name .. " " .. tostring(textvalue or ""))

		return {
			SetText = function(_, value) textobject.Text = tostring(value) end,
			SetColor = function(_, value)
				if typeof(value) == "Color3" then badge.BackgroundColor3 = value end
			end,
			Object = holder,
			Badge = badge,
			TextObject = textobject,
		}
	end

	-- image

	function section:AddImage(
		name,
		asset,
		height,
		target,
		parentobject,
		hasname,
		imageheight,
		holder,
		titleobject5,
		imageobject
	)
		parentobject = target or body
		hasname = name ~= nil and tostring(name) ~= ""
		imageheight = tonumber(height) or 92
		holder = S.new("Frame", {
			Parent = parentobject,
			Size = UDim2.new(1, 0, 0, imageheight + (hasname and 24 or 0)),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = 15,
		})
		if hasname then
			titleobject5 =
				S.label(holder, tostring(name), UDim2.new(1, 0, 0, 18), S.font, S.theme.text2)
			titleobject5.TextSize = 16
		end
		imageobject = S.new("ImageLabel", {
			Parent = holder,
			Position = UDim2.fromOffset(0, hasname and 24 or 0),
			Size = UDim2.new(1, 0, 0, imageheight),
			BackgroundColor3 = S.theme.input,
			BackgroundTransparency = 0.1,
			BorderSizePixel = 0,
			Image = asset or "",
			ScaleType = Enum.ScaleType.Fit,
			ZIndex = 16,
		}, { BackgroundColor3 = "input" })
		S.corner(imageobject, 8)
		register(holder, name or "image")
		return imageobject
	end

	-- avatar

	function section:AddAvatar(
		name,
		source,
		target,
		parentobject,
		sourceplayer,
		userid,
		display,
		username,
		holder,
		avatar,
		nameobject,
		userobject
	)
		parentobject = target or body
		sourceplayer = typeof(source) == "Instance" and source:IsA("Player") and source or nil
		userid = sourceplayer and sourceplayer.UserId or tonumber(source) or S.player.UserId
		display = sourceplayer and sourceplayer.DisplayName or tostring(name or "Avatar")
		username = sourceplayer and ("@" .. sourceplayer.Name) or ("User " .. tostring(userid))
		holder = S.new("Frame", {
			Parent = parentobject,
			Size = UDim2.new(1, 0, 0, 50),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = 15,
		})
		avatar = S.rawnew("ImageLabel", {
			Parent = holder,
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 0, 0.5, 0),
			Size = UDim2.fromOffset(40, 40),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Image = string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150", userid),
			ZIndex = 16,
		})
		S.corner(avatar, 10)
		nameobject = S.label(holder, display, UDim2.new(1, -50, 0, 20), S.medium, S.theme.text)
		nameobject.Position = UDim2.fromOffset(50, 4)
		nameobject.TextSize = 15
		nameobject.ZIndex = 16
		userobject = S.label(holder, username, UDim2.new(1, -50, 0, 18), S.font, S.theme.text3)
		userobject.Position = UDim2.fromOffset(50, 25)
		userobject.TextSize = 14
		userobject.ZIndex = 16
		register(holder, name or display)
		return holder
	end

	-- loading spinner

	function section:AddLoadingSpinner(name, target, parentobject, holder, titleobject6, spinner)
		parentobject = target or body
		holder = S.new("Frame", {
			Parent = parentobject,
			Size = UDim2.new(1, 0, 0, 28),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = 15,
		})
		titleobject6 = S.label(holder, name, UDim2.new(1, -30, 1, 0), S.font, S.theme.text2)
		titleobject6.TextSize = 16
		spinner = S.image(holder, S.icons.settings, 18, S.theme.text2, 16)
		spinner.AnchorPoint = Vector2.new(0.5, 0.5)
		spinner.Position = UDim2.new(1, -10, 0.5, 0)
		S.registeranimatedui(spinner, "spinner")

		register(holder, name)
		return spinner
	end

	-- loading bar

	function section:AddLoadingBar(name, target, parentobject, holder, titleobject7, track, bar)
		parentobject = target or body
		holder = S.new("Frame", {
			Parent = parentobject,
			Size = UDim2.new(1, 0, 0, 42),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = 15,
		})
		titleobject7 = S.label(holder, name, UDim2.new(1, 0, 0, 18), S.font, S.theme.text2)
		titleobject7.TextSize = 16
		track = S.new("Frame", {
			Parent = holder,
			Position = UDim2.fromOffset(0, 29),
			Size = UDim2.new(1, 0, 0, 6),
			BackgroundColor3 = S.theme.track,
			BorderSizePixel = 0,
			ClipsDescendants = true,
			ZIndex = 16,
		}, { BackgroundColor3 = "track" })
		S.corner(track, 999)
		bar = S.new("Frame", {
			Parent = track,
			Position = UDim2.new(-0.28, 0, 0, 0),
			Size = UDim2.new(0.28, 0, 1, 0),
			BackgroundColor3 = S.theme.highlight,
			BorderSizePixel = 0,
			ZIndex = 17,
		}, { BackgroundColor3 = "highlight" })
		S.corner(bar, 999)
		S.registeranimatedui(bar, "bar")

		register(holder, name)
		return bar
	end

	-- context / modal helpers

	function section:AddContextMenu(name, entries, target, button11)
		button11 = self:AddButton(name, nil, target)
		S.attachcontextmenu(button11, entries)
		return button11
	end

	function section:AddConfirmButton(name, titletext, bodytext, callback, target)
		return self:AddButton(
			name,
			function() S.confirmdialog(titletext, bodytext, callback) end,
			target
		)
	end

	function section:AddModalButton(name, titletext, bodytext, target)
		return self:AddButton(
			name,
			function() S.showmodal(titletext, bodytext, { { Text = "Close" } }) end,
			target
		)
	end

	function section:AddButtonGroup(buttons, target, row)
		row = self:AddRow(8, 32, target)
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

	function section:AddSubTabs(
		names,
		config,
		barheight,
		contentoffset,
		sidepadding,
		wheelstep,
		scrollti,
		taborder,
		tabsclosed,
		tabscroll,
		tabdrag,
		host,
		tabviewport,
		tabcontent,
		tablayout,
		scrollbartrack,
		scrollbarthumb,
		containers,
		buttons,
		selected,
		overflow,
		scrollx,
		scrolltarget,
		contentwidth,
		scrollanimation,
		scrollvalue,
		resizehost,
		applytaborder,
		maxscroll,
		updatescrollbar,
		renderscroll,
		setscroll,
		updatelayout,
		ensuretabvisible,
		wheel,
		select
	)
		config = type(config) == "table" and config or { ShowTitle = config == true }

		barheight = 32
		contentoffset = 39
		sidepadding = 2
		wheelstep = 75
		scrollti = S.quart28
		taborder = table.clone(names)
		tabsclosed = false
		tabscroll = nil
		tabdrag = nil

		host = S.new("Frame", {
			Parent = body,

			Size = UDim2.new(1, 0, 0, barheight),

			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ClipsDescendants = false,
			Active = true,

			ZIndex = 15,
		})

		tabviewport = S.new("Frame", {
			Parent = host,

			Size = UDim2.new(1, 0, 0, barheight),

			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ClipsDescendants = true,
			Active = true,

			ZIndex = 16,
		})

		section.subtabhost = host
		section.subtabviewport = tabviewport
		section:SetTitleVisible(config.ShowTitle == true, false)

		tabcontent = S.new("Frame", {
			Parent = tabviewport,

			Position = UDim2.fromOffset(0, 0),

			Size = UDim2.fromOffset(0, 30),

			BackgroundTransparency = 1,
			BorderSizePixel = 0,

			ZIndex = 16,
		})

		S.padding(tabcontent, sidepadding, sidepadding)

		tablayout = S.new("UIListLayout", {
			Parent = tabcontent,

			FillDirection = Enum.FillDirection.Horizontal,

			VerticalAlignment = Enum.VerticalAlignment.Center,

			HorizontalAlignment = Enum.HorizontalAlignment.Left,

			Padding = UDim.new(0, 8),

			SortOrder = Enum.SortOrder.LayoutOrder,
		})

		scrollbartrack = S.new("Frame", {
			Parent = host,

			AnchorPoint = Vector2.new(0.5, 0),

			Position = UDim2.new(0.5, 0, 0, barheight - 4),

			Size = UDim2.new(1, -12, 0, 1),

			BackgroundColor3 = S.theme.scrollTrack,

			BackgroundTransparency = 1,
			BorderSizePixel = 0,

			ZIndex = 18,
		}, { BackgroundColor3 = "scrollTrack" })

		S.corner(scrollbartrack, 999)

		scrollbarthumb = S.new("Frame", {
			Parent = scrollbartrack,

			Position = UDim2.fromOffset(0, 0),

			Size = UDim2.fromOffset(20, 1),

			BackgroundColor3 = S.theme.scroll,

			BackgroundTransparency = 0.32,
			BorderSizePixel = 0,
			Visible = false,

			ZIndex = 19,
		}, { BackgroundColor3 = "scroll" })

		S.corner(scrollbarthumb, 999)

		containers = {}
		buttons = {}

		selected = nil
		overflow = false
		scrollx = 0
		scrolltarget = 0
		contentwidth = 0
		scrollanimation = nil

		scrollvalue = S.new("NumberValue", {
			Parent = host,
			Value = 0,
		})

		resizehost = function(
			animate,
			container,
			containerheight,
			height,
			height2,
			animation,
			completed
		)
			container = selected and containers[selected]

			

			height2 = tabsclosed and barheight
				or contentoffset + (container and container.Size.Y.Offset or 0)

			host.ClipsDescendants = animate == true or tabsclosed

			if animate then
				animation = S.tween(host, {
					Size = UDim2.new(1, 0, 0, height2),
				}, S.tabti)

				if not tabsclosed and animation then
					completed = nil
					completed = animation.Completed:Connect(function()
						if completed then
							completed:Disconnect()
							completed = nil
						end

						if host.Parent and not tabsclosed then host.ClipsDescendants = false end
					end)
				elseif not tabsclosed then
					host.ClipsDescendants = false
				end
			else
				host.Size = UDim2.new(1, 0, 0, height2)
				host.ClipsDescendants = tabsclosed
			end
		end

		applytaborder = function(data)
			for index, tabname in ipairs(taborder) do
				data = buttons[tabname]
				if data then data.button.LayoutOrder = index end
			end
		end

		maxscroll = function() return math.max(0, contentwidth - tabviewport.AbsoluteSize.X) end

		updatescrollbar = function(viewport, trackwidth, width, maximum, ratio)
			viewport = tabviewport.AbsoluteSize.X

			trackwidth = scrollbartrack.AbsoluteSize.X

			if not overflow or viewport <= 0 or trackwidth <= 0 or contentwidth <= viewport then
				scrollbarthumb.Visible = false
				scrollbartrack.BackgroundTransparency = 1
				return
			end

			scrollbarthumb.Visible = true
			scrollbartrack.BackgroundTransparency = 0.72

			width = math.clamp(viewport / contentwidth * trackwidth, 20, trackwidth)

			maximum = math.max(1, maxscroll())

			ratio = math.clamp(scrollx / maximum, 0, 1)

			scrollbarthumb.Size = UDim2.fromOffset(width, 1)

			scrollbarthumb.Position = UDim2.fromOffset((trackwidth - width) * ratio, 0)
		end

		renderscroll = function(value)
			scrollx = math.clamp(value, 0, maxscroll())

			tabcontent.Position = UDim2.fromOffset(-scrollx, 0)

			updatescrollbar()
		end

		scrollvalue
			:GetPropertyChangedSignal("Value")
			:Connect(function() renderscroll(scrollvalue.Value) end)

		setscroll = function(value, animate, target)
			target = math.clamp(value, 0, maxscroll())

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

			scrollanimation = S.tween(scrollvalue, {
				Value = target,
			}, scrollti)
		end

		updatelayout = function(viewport)
			viewport = tabviewport.AbsoluteSize.X

			if viewport <= 0 then return end

			contentwidth = tablayout.AbsoluteContentSize.X + sidepadding * 2

			overflow = contentwidth > viewport

			if overflow then
				tabcontent.Size = UDim2.fromOffset(contentwidth, 30)

				tablayout.HorizontalAlignment = Enum.HorizontalAlignment.Left

				setscroll(scrolltarget, false)
			else
				contentwidth = viewport

				tabcontent.Size = UDim2.fromOffset(viewport, 30)

				tablayout.HorizontalAlignment = Enum.HorizontalAlignment.Left

				setscroll(0, false)
			end
		end

		ensuretabvisible = function(
			button,
			animate,
			left,
			right,
			viewportleft,
			viewportright,
			target
		)
			if not overflow then return end

			left = button.AbsolutePosition.X

			right = left + button.AbsoluteSize.X

			viewportleft = tabviewport.AbsolutePosition.X + sidepadding

			viewportright = tabviewport.AbsolutePosition.X
				+ tabviewport.AbsoluteSize.X
				- sidepadding

			target = scrolltarget

			if left < viewportleft then
				target -= viewportleft - left
			elseif right > viewportright then
				target += right - viewportright
			end

			setscroll(target, animate)
		end

		wheel = function(direction)
			if not overflow then return end

			setscroll(scrolltarget + direction * wheelstep, true)
		end

		host.MouseWheelForward:Connect(function() wheel(-1) end)

		host.MouseWheelBackward:Connect(function() wheel(1) end)

		tabviewport.InputBegan:Connect(function(input, position)
			if input.UserInputType ~= Enum.UserInputType.Touch then return end

			position = S.point(input)

			tabscroll = {
				input = input,
				name = nil,
				start = position,
				last = position,
				started = false,
			}
		end)

		select = function(
			name,
			scrollintoview,
			animate,
			shouldanimate,
			active,
			textcolor,
			linesize,
			linetransparency,
			data3,
			container2
		)
			if selected == name then return end

			selected = name

			shouldanimate = animate ~= false

			for tabname, container in pairs(containers) do
				container.Visible = tabname == name
			end

			for tabname, data in pairs(buttons) do
				active = tabname == name

				textcolor = active and S.theme.text or S.theme.text3

				linesize = active and UDim2.fromOffset(data.linewidth, 2) or UDim2.fromOffset(0, 2)

				linetransparency = active and 0 or 1

				if shouldanimate then
					S.tween(data.text, {
						TextColor3 = textcolor,
					}, S.tabti)

					S.tween(data.line, {
						Size = linesize,
						BackgroundTransparency = linetransparency,
					}, S.tabti)
				else
					data.text.TextColor3 = textcolor

					data.line.Size = linesize

					data.line.BackgroundTransparency = linetransparency
				end

				if data.glow then
					if shouldanimate then
						S.tween(data.glow, {
							Transparency = active and 0.74 or 1,
						}, S.tabti)
					else
						data.glow.Transparency = active and 0.74 or 1
					end
				end
			end

			data3 = buttons[name]

			if data3 and scrollintoview ~= false then
				ensuretabvisible(data3.button, shouldanimate)
			end

			container2 = containers[name]

			if not container2 then return end

			container2.Visible = true

			container2.Position = UDim2.fromOffset(0, contentoffset)

			resizehost(false)
		end

		for index, tabname, iteration8 in S.scopediterator(2, ipairs(taborder)) do
			iteration8.measured =
				S.measuretext(S.plaintext(tabname), 15, S.medium, Vector2.new(1000, 30))

			iteration8.buttonwidth = math.max(38, iteration8.measured.X + 12)

			iteration8.button = S.new("TextButton", {
				Parent = tabcontent,

				LayoutOrder = index,

				Size = UDim2.fromOffset(iteration8.buttonwidth, 30),

				BackgroundColor3 = S.theme.hover,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Text = "",
				AutoButtonColor = false,

				ZIndex = 16,
			}, { BackgroundColor3 = "hover" })

			S.corner(iteration8.button, 6)

			iteration8.textobject =
				S.label(iteration8.button, tabname, UDim2.fromScale(1, 1), S.medium, S.theme.text3)

			iteration8.textobject.TextXAlignment = Enum.TextXAlignment.Center

			iteration8.textobject.Position = UDim2.fromOffset(0, 0)

			iteration8.textobject.TextSize = 16
			iteration8.textobject.ZIndex = 17

			iteration8.button.MouseEnter:Connect(
				function()
					S.tween(
						iteration8.textobject,
						{ TextColor3 = S.theme.text },
						S.hoverti,
						nil,
						{ TextColor3 = "text" }
					)
				end
			)
			iteration8.button.MouseLeave:Connect(
				function()
					S.tween(
						iteration8.textobject,
						{ TextColor3 = selected == tabname and S.theme.text or S.theme.text3 },
						S.hoverti
					)
				end
			)

			iteration8.line = S.new("Frame", {
				Parent = iteration8.button,

				AnchorPoint = Vector2.new(0.5, 1),

				Position = UDim2.new(0.5, 0, 1, -1),

				Size = UDim2.fromOffset(0, 2),

				BackgroundColor3 = S.theme.highlight,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,

				ZIndex = 17,
			}, { BackgroundColor3 = "highlight" })

			S.corner(iteration8.line, 999)
			S.bindtheme(iteration8.line, "BackgroundColor3", S.theme.highlight, "highlight")
			iteration8.line.BackgroundColor3 = S.theme.highlight

			buttons[tabname] = {
				button = iteration8.button,
				text = iteration8.textobject,
				line = iteration8.line,
				glow = nil,
				linewidth = math.max(18, math.ceil(iteration8.measured.X) + 2),
			}

			-- Important: this must stay a normal Frame. CanvasGroup clips its
			-- descendants to its render bounds, which was cutting checkbox glows.
			iteration8.container = S.new("Frame", {
				Parent = host,

				Position = UDim2.fromOffset(0, contentoffset),

				Size = UDim2.new(1, 0, 0, 0),

				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Visible = false,
				ClipsDescendants = false,

				ZIndex = 15,
			})

			iteration8.containerlayout = S.list(iteration8.container, 9)

			containers[tabname] = iteration8.container

			iteration8.containerlayout
				:GetPropertyChangedSignal("AbsoluteContentSize")
				:Connect(function(height)
					height = iteration8.containerlayout.AbsoluteContentSize.Y
						+ (4)

					iteration8.container.Size = UDim2.new(1, 0, 0, height)

					if selected == tabname then resizehost(false) end

					
				end)

			iteration8.button.InputBegan:Connect(function(input, position)
				

				if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end

				tabdrag = {
					input = input,
					name = tabname,
					button = iteration8.button,
					start = S.point(input),
					started = false,
				}
			end)

			iteration8.button.Activated:Connect(function(data)
				data = buttons[tabname]
				if data and data.suppressactivate then
					data.suppressactivate = false
					return
				end

				select(tabname, true, true)
			end)
		end

		applytaborder()

		S.connect(
			S.uis.InputChanged,
			function(
				input,
				current,
				total,
				data,
				delta,
				current2,
				root,
				filtered,
				targetindex,
				data4,
				center,
				currentindex,
				wanted,
				oldpositions,
				currentdata,
				orderedbuttons,
				currentdata2
			)
				

				if not tabdrag then return end

				if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end

				current2 = S.point(input)
				if not tabdrag.started and (current2 - tabdrag.start).Magnitude >= 6 then
					tabdrag.started = true
					buttons[tabdrag.name].suppressactivate = true
					tabdrag.grab = current2 - tabdrag.button.AbsolutePosition
					tabdrag.ghost, tabdrag.ghostclone, tabdrag.ghostscale =
						S.makedragghost(tabdrag.button, 470)
					tabdrag.hidden = S.hideforghost(tabdrag.button)
				end

				if not tabdrag.started then return end

				if tabdrag.ghost and tabdrag.ghost.Parent then
					root = S.draglayer.AbsolutePosition
					tabdrag.ghost.Position = UDim2.fromOffset(
						current2.X - tabdrag.grab.X - root.X,
						current2.Y - tabdrag.grab.Y - root.Y
					)
				end

				filtered = {}
				for _, tabname in ipairs(taborder) do
					if tabname ~= tabdrag.name then table.insert(filtered, tabname) end
				end

				targetindex = #filtered + 1
				for index, tabname in ipairs(filtered) do
					data4 = buttons[tabname]
					center = data4.button.AbsolutePosition.X + data4.button.AbsoluteSize.X * 0.5
					if current2.X < center then
						targetindex = index
						break
					end
				end

				currentindex = table.find(taborder, tabdrag.name)
				wanted = targetindex
				if currentindex and currentindex ~= wanted then
					oldpositions = {}

					for _, currentname in ipairs(taborder) do
						currentdata = buttons[currentname]
						if currentdata and currentdata.button then
							oldpositions[currentdata.button] = currentdata.button.AbsolutePosition
						end
					end

					table.remove(taborder, currentindex)
					wanted = math.clamp(wanted, 1, #taborder + 1)
					table.insert(taborder, wanted, tabdrag.name)
					applytaborder()
					updatelayout()

					orderedbuttons = {}
					for _, currentname in ipairs(taborder) do
						currentdata2 = buttons[currentname]
						if currentdata2 and currentdata2.button then
							orderedbuttons[#orderedbuttons + 1] = currentdata2.button
						end
					end

					S.animatereorder(oldpositions, orderedbuttons, tabdrag.button)
				end
			end
		)

		S.connect(
			S.uis.InputEnded,
			function(input, data, dragged, drag, target, finished, finish, animation)
				

				if not tabdrag or input.UserInputType ~= Enum.UserInputType.MouseButton1 then
					return
				end

				drag = tabdrag
				tabdrag = nil

				if drag.started then
					target = drag.button.AbsolutePosition - S.draglayer.AbsolutePosition
					finished = false
					finish = function(data5)
						if finished then return end
						finished = true
						S.restorefromghost(drag.hidden)
						if drag.ghost and drag.ghost.Parent then drag.ghost:Destroy() end
						data5 = buttons[drag.name]
						if data5 then data5.suppressactivate = false end
					end

					if drag.ghost and drag.ghost.Parent then
						animation = S.tween(
							drag.ghost,
							{ Position = UDim2.fromOffset(target.X, target.Y) },
							S.quart24
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
			end
		)

		tablayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updatelayout)

		tabviewport:GetPropertyChangedSignal("AbsoluteSize"):Connect(updatelayout)

		scrollbartrack:GetPropertyChangedSignal("AbsoluteSize"):Connect(updatescrollbar)

		register(host, table.concat(names, " "))

		setscroll(0, false)

		updatelayout()
		setscroll(0, false)

		select(taborder[1], false, false)

		updatelayout()
		setscroll(0, false)

		return {
			Get = function(_, name) return containers[name] end,

			Select = function(_, name) select(name, true, true) end,

			SetCollapsed = function(_, value, animate)
				tabsclosed = value == true
				resizehost(animate ~= false)
			end,

			IsCollapsed = function() return tabsclosed end,
		}
	end

	return section
end

-- pages

S.home = S.createpage("home", "Home", nil)

S.combatmain = S.createpage("combat_main", "Combat", "Main")

S.combatvisuals = S.createpage("combat_visuals", "Combat", "Visuals")

S.combatextras = S.createpage("combat_extras", "Combat", "Extras")

S.farming = S.createpage("farming", "Farming", nil)

S.settings = S.createpage("settings", "Settings", nil)

S.components = S.createpage("components", "Components", nil)

S.home.icon = S.icons.home
S.combatmain.icon = S.icons.target
S.combatvisuals.icon = S.icons.visuals
S.combatextras.icon = S.icons.extras
S.farming.icon = S.icons.farming
S.settings.icon = S.icons.settings
S.components.icon = S.icons.sliders

-- library runtime

S.legacysettingspath = "blush_ui_settings.json"
S.storagefolder = "blush"
S.configfolder = S.storagefolder .. "/configs"
S.themefolder = S.storagefolder .. "/themes"
S.backgroundfolder = S.storagefolder .. "/backgrounds"
S.settingspath = S.storagefolder .. "/settings.json"
S.savedsettings = {}

function S.configurestoragefolders(options, folders, root, subpath, settingsfile)
	options = type(options) == "table" and options or {}
	folders = type(options.Folders) == "table" and options.Folders or {}
	root = options.StorageFolder or options.Folder or folders.Root or folders.Storage
	if type(root) == "string" and root ~= "" then S.storagefolder = root:gsub("[\\/]+$", "") end

	subpath = function(value, fallback)
		if type(value) ~= "string" or value == "" then return S.storagefolder .. "/" .. fallback end
		value = value:gsub("^[\\/]+", ""):gsub("[\\/]+$", "")
		if value:find("[\\/]") then return value end
		return S.storagefolder .. "/" .. value
	end

	S.configfolder = subpath(options.ConfigFolder or folders.Configs or folders.Config, "configs")
	S.themefolder = subpath(options.ThemeFolder or folders.Themes or folders.Theme, "themes")
	S.backgroundfolder = subpath(
		options.BackgroundFolder or folders.Backgrounds or folders.Background,
		"backgrounds"
	)

	settingsfile = options.SettingsFile or folders.Settings
	if type(settingsfile) == "string" and settingsfile ~= "" then
		settingsfile = settingsfile:gsub("^[\\/]+", "")
		S.settingspath = settingsfile:find("[\\/]") and settingsfile
			or (S.storagefolder .. "/" .. settingsfile)
	else
		S.settingspath = S.storagefolder .. "/settings.json"
	end
end

function S.ensurefolder(path, ok, exists)
	if typeof(isfolder) == "function" then
		ok, exists = S.invoke(isfolder, path)
		if ok and exists then return true end
	end

	if typeof(makefolder) == "function" then return S.invoke(makefolder, path) end

	return false
end

function S.ensurestorage(oldok, oldexists, newok, newexists)
	S.ensurefolder(S.storagefolder)
	S.ensurefolder(S.configfolder)
	S.ensurefolder(S.themefolder)
	S.ensurefolder(S.backgroundfolder)

	if
		typeof(readfile) == "function"
		and typeof(writefile) == "function"
		and typeof(isfile) == "function"
	then
		oldok, oldexists = S.invoke(isfile, S.legacysettingspath)
		newok, newexists = S.invoke(isfile, S.settingspath)

		if oldok and oldexists and newok and not newexists then
			writefile(S.settingspath, readfile(S.legacysettingspath))
		end
	end
end

function S.sanitizefilename(value)
	value = tostring(value or "")
	value = value:gsub("^%s+", ""):gsub("%s+$", "")
	value = value:gsub('[\\/:*?"<>|]', "")
	value = value:gsub("^%.*", "")
	value = value:sub(1, 48)
	return value
end

function S.readjsonfile(path, ok, encoded, decodedok, decoded)
	if typeof(readfile) ~= "function" then return nil end

	ok, encoded = S.invoke(readfile, path)
	if not ok or not encoded or encoded == "" then return nil end

	decodedok, decoded = S.invoke(function() return S.httpservice:JSONDecode(encoded) end)

	return decodedok and typeof(decoded) == "table" and decoded or nil
end

function S.writejsonfile(path, data)
	if typeof(writefile) ~= "function" then return false end

	return S.invoke(function() writefile(path, S.httpservice:JSONEncode(data)) end)
end

function S.listjsonnames(folder, result, ok, files, name6)
	result = {}

	if typeof(listfiles) ~= "function" then return result end

	ok, files = S.invoke(listfiles, folder)
	if not ok or typeof(files) ~= "table" then return result end

	for _, path in ipairs(files) do
		name6 = tostring(path):match("([^/\\]+)%.json$")
		if name6 then table.insert(result, name6) end
	end

	table.sort(result, function(a, b) return string.lower(a) < string.lower(b) end)

	return result
end

S.ensurestorage()

S.backgroundimagesource = ""
S.backgroundimageopacity = 65
S.backgroundimageblur = 0
S.backgroundimageblurmax = 100
S.backgroundimagemode = "Crop"
S.__blush_background_token = 0

function S.trimbackgroundsource(value, markdownurl)
	value = tostring(value or "")
	value = value:gsub("^%s+", ""):gsub("%s+$", "")

	markdownurl = value:match("^%[[^%]]-%]%((https?://.-)%)$")
	if markdownurl then value = markdownurl end

	if
		(#value >= 2)
		and (
			(value:sub(1, 1) == '"' and value:sub(-1) == '"')
			or (value:sub(1, 1) == "'" and value:sub(-1) == "'")
			or (value:sub(1, 1) == "<" and value:sub(-1) == ">")
		)
	then
		value = value:sub(2, -2)
	end

	value = value:gsub("&amp;", "&")
	return value:gsub("^%s+", ""):gsub("%s+$", "")
end

function S.backgroundhash(value, hash)
	hash = 5381
	for index = 1, #value do
		hash = (hash * 33 + string.byte(value, index)) % 4294967296
	end
	return string.format("%08x", hash)
end

function S.backgroundextension(source, headers, contenttype, typemap, clean, extension2)
	contenttype = nil
	if typeof(headers) == "table" then
		for key, value in pairs(headers) do
			if string.lower(tostring(key)) == "content-type" then
				contenttype = string.lower(tostring(value))
				break
			end
		end
	end

	typemap = {
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
			if contenttype:find(mime, 1, true) then return extension end
		end
	end

	clean = tostring(source):match("^[^?#]+") or tostring(source)
	extension2 = clean:match("%.([%w]+)$")
	if extension2 then
		extension2 = string.lower(extension2)
		if extension2 == "jpeg" then extension2 = "jpg" end
		if table.find({ "png", "jpg", "webp", "avif", "bmp", "gif", "tga" }, extension2) then
			return extension2
		end
	end

	return "png"
end

function S.backgroundcustomasset(path, providers, ok, asset)
	providers = {}

	if typeof(getcustomasset) == "function" then providers[#providers + 1] = getcustomasset end
	if typeof(getsynasset) == "function" then providers[#providers + 1] = getsynasset end
	if typeof(getasset) == "function" then providers[#providers + 1] = getasset end

	for _, provider in ipairs(providers) do
		ok, asset = S.invoke(provider, path)
		if ok and type(asset) == "string" and asset ~= "" then return asset end
	end

	return nil, "custom asset API unavailable"
end

function S.backgroundrequest(url, requesters, ok, response, status, body, ok2, body2)
	requesters = {}

	if typeof(request) == "function" then requesters[#requesters + 1] = request end
	if typeof(http_request) == "function" then requesters[#requesters + 1] = http_request end
	if syn and typeof(syn.request) == "function" then requesters[#requesters + 1] = syn.request end
	if http and typeof(http.request) == "function" then
		requesters[#requesters + 1] = http.request
	end
	if fluxus and typeof(fluxus.request) == "function" then
		requesters[#requesters + 1] = fluxus.request
	end

	for _, requester in ipairs(requesters) do
		ok, response = S.invoke(requester, {
			Url = url,
			Method = "GET",
			Headers = {
				["User-Agent"] = "Mozilla/5.0",
				Accept = "image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8",
			},
		})

		if ok and typeof(response) == "table" then
			status = tonumber(response.StatusCode or response.Status or response.status_code) or 200
			body = response.Body or response.body

			if status >= 200 and status < 400 and type(body) == "string" and #body > 0 then
				return body, response.Headers or response.headers or {}, nil
			end
		end
	end

	ok2, body2 = S.invoke(function() return game:HttpGet(url) end)

	if ok2 and type(body2) == "string" and #body2 > 0 then return body2, {}, nil end

	return nil, nil, "download failed"
end

function S.backgroundbase64decode(data, ok, decoded, ok3, decoded2, ok4, decoded3, alphabet, bits)
	if crypt and crypt.base64 and typeof(crypt.base64.decode) == "function" then
		ok, decoded = S.invoke(crypt.base64.decode, data)
		if ok then return decoded end
	end

	if syn and syn.crypt and syn.crypt.base64 and typeof(syn.crypt.base64.decode) == "function" then
		ok3, decoded2 = S.invoke(syn.crypt.base64.decode, data)
		if ok3 then return decoded2 end
	end

	if typeof(base64_decode) == "function" then
		ok4, decoded3 = S.invoke(base64_decode, data)
		if ok4 then return decoded3 end
	end

	alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
	data = tostring(data):gsub("[^" .. alphabet .. "=]", "")

	bits = data:gsub(".", function(character, index, result, set)
		if character == "=" then return "" end

		index = alphabet:find(character, 1, true)
		if not index then return "" end

		index -= 1
		result = ""
		for bit = 6, 1, -1 do
			set = index % 2 ^ bit - index % 2 ^ (bit - 1) > 0
			result ..= set and "1" or "0"
		end
		return result
	end)

	return bits:gsub("%d%d%d?%d?%d?%d?%d?%d?", function(chunk, value)
		if #chunk ~= 8 then return "" end

		value = 0
		for index = 1, 8 do
			if chunk:sub(index, index) == "1" then
				value += 2 ^ (8 - index)
			end
		end
		return string.char(value)
	end)
end

function S.backgroundlocalpath(source, lower)
	lower = string.lower(source)

	if lower:sub(1, 8) == "file:///" then
		source = source:sub(9)
	elseif lower:sub(1, 7) == "file://" then
		source = source:sub(8)
	end

	source = source:gsub("%%20", " ")
	return source
end

function S.resolvebackgroundimage(
	source,
	force,
	lower,
	robloxid,
	mime,
	encoded,
	extension3,
	path,
	decoded,
	ok,
	cachedprefix,
	extensions,
	path2,
	ok5,
	exists,
	asset,
	body,
	headers,
	err,
	extension4,
	path3,
	ok6,
	path4,
	ok7,
	exists2
)
	source = S.trimbackgroundsource(source)
	if source == "" then return nil, "empty source" end

	if source:match("^%d+$") then return "rbxassetid://" .. source end

	lower = string.lower(source)
	if
		lower:match("^rbxassetid://")
		or lower:match("^rbxthumb://")
		or lower:match("^rbxasset://")
	then
		return source
	end

	robloxid = source:match("[?&]id=(%d+)")
		or source:match("/asset/(%d+)")
		or source:match("/library/(%d+)")
		or source:match("/store/asset/(%d+)")
	if robloxid and lower:find("roblox", 1, true) then return "rbxassetid://" .. robloxid end

	if lower:match("^data:image/") then
		if typeof(writefile) ~= "function" then return nil, "writefile unavailable" end

		mime, encoded = source:match("^data:(image/[^;]+);base64,(.+)$")
		if not mime or not encoded then return nil, "invalid data URI" end

		extension3 = S.backgroundextension("", { ["Content-Type"] = mime })
		path = S.backgroundfolder .. "/data_" .. S.backgroundhash(source) .. "." .. extension3

		if force or typeof(isfile) ~= "function" or not isfile(path) then
			decoded = S.backgroundbase64decode(encoded)
			if type(decoded) ~= "string" or #decoded == 0 then
				return nil, "base64 decode failed"
			end

			ok = S.invoke(writefile, path, decoded)
			if not ok then return nil, "could not write image" end
		end

		return S.backgroundcustomasset(path)
	end

	if lower:match("^https?://") then
		if typeof(writefile) ~= "function" then return nil, "writefile unavailable" end

		cachedprefix = S.backgroundfolder .. "/url_" .. S.backgroundhash(source)
		extensions = { "png", "jpg", "webp", "avif", "bmp", "gif", "tga" }

		if not force and typeof(isfile) == "function" then
			for _, extension in ipairs(extensions) do
				path2 = cachedprefix .. "." .. extension
				ok5, exists = S.invoke(isfile, path2)
				if ok5 and exists then
					asset = S.backgroundcustomasset(path2)
					if asset then return asset end
				end
			end
		end

		body, headers, err = S.backgroundrequest(source)
		if not body then return nil, err or "download failed" end

		extension4 = S.backgroundextension(source, headers)
		path3 = cachedprefix .. "." .. extension4
		ok6 = S.invoke(writefile, path3, body)
		if not ok6 then return nil, "could not cache image" end

		return S.backgroundcustomasset(path3)
	end

	path4 = S.backgroundlocalpath(source)
	if typeof(isfile) == "function" then
		ok7, exists2 = S.invoke(isfile, path4)
		if ok7 and not exists2 then return nil, "file not found" end
	end

	return S.backgroundcustomasset(path4)
end

function S.boxblurbackgroundbuffer(source, width, height, radius, token, horizontal, output, sum, offset, remove, add, deadline, count)
	radius = math.max(0, math.floor(radius))
	if radius == 0 then return source end
	horizontal = buffer.create(width * height * 16)
	output = buffer.create(width * height * 4)
	count = (2 * radius + 1) ^ 2
	deadline = os.clock() + 0.002
	-- Keep integer sums until the final pass; clamped edges match the reference kernel.
	for y = 0, height - 1 do
		for channel = 0, 3 do
			sum = 0
			for dx = -radius, radius do
				sum += buffer.readu8(source, (y * width + math.clamp(dx, 0, width - 1)) * 4 + channel)
			end
			for x = 0, width - 1 do
				buffer.writeu32(horizontal, (y * width + x) * 16 + channel * 4, sum)
				remove = (y * width + math.clamp(x - radius, 0, width - 1)) * 4 + channel
				add = (y * width + math.clamp(x + radius + 1, 0, width - 1)) * 4 + channel
				sum += buffer.readu8(source, add) - buffer.readu8(source, remove)
			end
		end
		if token and os.clock() >= deadline then
			coroutine.yield()
			if token ~= S.backgroundblurtoken then return nil end
			deadline = os.clock() + 0.002
		end
	end
	for x = 0, width - 1 do
		for channel = 0, 3 do
			sum = 0
			for dy = -radius, radius do
				sum += buffer.readu32(horizontal, (math.clamp(dy, 0, height - 1) * width + x) * 16 + channel * 4)
			end
			for y = 0, height - 1 do
				buffer.writeu8(output, (y * width + x) * 4 + channel, math.floor(sum / count))
				remove = (math.clamp(y - radius, 0, height - 1) * width + x) * 16 + channel * 4
				add = (math.clamp(y + radius + 1, 0, height - 1) * width + x) * 16 + channel * 4
				sum += buffer.readu32(horizontal, add) - buffer.readu32(horizontal, remove)
			end
		end
		if token and os.clock() >= deadline then
			coroutine.yield()
			if token ~= S.backgroundblurtoken then return nil end
			deadline = os.clock() + 0.002
		end
	end
	return output
end

function S.preparebackgroundblurbase(
	asset,
	token,
	candidates,
	ok,
	content2,
	ok8,
	content3,
	ok9,
	content4,
	editable,
	ok10,
	result,
	ok11,
	size,
	pixels,
	applied,
	imageuri,
	ok12,
	content5
)
	if S.backgroundblurbaseasset == asset and S.backgroundblurbasepixels and S.backgroundblurbasewidth > 0 and S.backgroundblurbaseheight > 0 and S.backgroundblureditable then
		return true
	end
	if S.backgroundblureditable then
		pcall(function() S.backgroundblureditable:Destroy() end)
		S.backgroundblureditable = nil
	end
	candidates = {}
	if S.backgroundimage and S.backgroundimage.Parent then
		ok, content2 = pcall(function() return S.backgroundimage.ImageContent end)
		if ok and content2 and content2 ~= Content.none then candidates[#candidates + 1] = content2 end
		imageuri = S.backgroundimage.Image
		if imageuri and imageuri ~= "" then
			ok12, content5 = pcall(Content.fromUri, imageuri)
			if ok12 and content5 and content5 ~= Content.none then candidates[#candidates + 1] = content5 end
		end
	end
	if asset and asset ~= "" then
		ok8, content3 = pcall(Content.fromUri, asset)
		if ok8 and content3 and content3 ~= Content.none then candidates[#candidates + 1] = content3 end
	end
	if S.backgroundimagesource and S.backgroundimagesource ~= "" then
		ok9, content4 = pcall(Content.fromUri, S.backgroundimagesource)
		if ok9 and content4 and content4 ~= Content.none then candidates[#candidates + 1] = content4 end
	end
	editable = nil
	size = nil
	pixels = nil
	for _, content in ipairs(candidates) do
		result = nil
		ok10, result = pcall(function() return S.assetservice:CreateEditableImageAsync(content) end)
		if ok10 and result and token == S.backgroundsourcegeneration then
			ok11, size, pixels = pcall(function(imagesize)
				imagesize = result.Size
				return imagesize, result:ReadPixelsBuffer(Vector2.zero, imagesize)
			end)
			if ok11 and size and pixels and size.X > 0 and size.Y > 0 then
				editable = result
				break
			end
		end
		if result then pcall(function() result:Destroy() end) end
		result = nil
		size = nil
		pixels = nil
		if token ~= S.backgroundsourcegeneration then return false end
	end
	if not editable or not size or not pixels or token ~= S.backgroundsourcegeneration then return false end
	S.backgroundblurbaseasset = asset
	S.backgroundblurbasepixels = pixels
	S.backgroundblurbasewidth = size.X
	S.backgroundblurbaseheight = size.Y
	S.backgroundblureditable = editable
	S.backgroundblurlastsignature = nil
	applied = pcall(function()
		S.backgroundblurdisplay.Image = ""
		S.backgroundblurdisplay.ImageContent = Content.fromObject(editable)
	end)
	if not applied then
		pcall(function() editable:Destroy() end)
		S.backgroundblureditable = nil
		S.backgroundblurbasepixels = nil
		S.backgroundblurbasewidth = 0
		S.backgroundblurbaseheight = 0
		return false
	end
	return true
end

function S.buildbackgroundblur(
	asset,
	blur,
	token,
	width,
	height,
	sourcepixels,
	editable,
	radius,
	signature,
	output,
	ok
)
	if not asset or asset == "" or blur <= 0 then return false end

	if S.backgroundblurbaseasset ~= asset then return false end
	if token ~= S.backgroundblurtoken then return false end

	width = S.backgroundblurbasewidth
	height = S.backgroundblurbaseheight
	sourcepixels = S.backgroundblurbasepixels
	editable = S.backgroundblureditable
	if not editable or not sourcepixels or width < 1 or height < 1 then return false end

	radius = math.clamp(math.round(blur), 1, S.backgroundimageblurmax)
	signature = tostring(S.backgroundblurbaseasset) .. ":" .. tostring(radius)
	if S.backgroundblurlastsignature == signature then return true end

	output = S.boxblurbackgroundbuffer(sourcepixels, width, height, radius, token)
	if not output or token ~= S.backgroundblurtoken then return false end

	ok = pcall(
		function() editable:WritePixelsBuffer(Vector2.zero, Vector2.new(width, height), output) end
	)

	if not ok or token ~= S.backgroundblurtoken then return false end

	S.backgroundblurlastsignature = signature
	S.backgroundblurdisplay.ImageContent = Content.fromObject(editable)
	return true
end

function S.applybackgroundblurblend(opacity, blur, visible)
	opacity = math.clamp(S.backgroundimageopacity / 100, 0, 1)
	blur = math.clamp(S.backgroundimageblur, 0, S.backgroundimageblurmax)
	visible = S.backgroundimagesource ~= "" and S.backgroundresolvedasset ~= nil

	if not visible then
		S.backgroundimage.Visible = false
		S.backgroundblurdisplay.Visible = false
		S.backgroundimage.ImageTransparency = 1
		S.backgroundblurdisplay.ImageTransparency = 1
		return
	end

	if blur <= 0 or not S.backgroundblureditable or not S.backgroundblurlastsignature then
		S.backgroundimage.Visible = true
		S.backgroundimage.ImageTransparency = 1 - opacity
		S.backgroundblurdisplay.Visible = false
		S.backgroundblurdisplay.ImageTransparency = 1
		return
	end

	S.backgroundimage.Visible = false
	S.backgroundimage.ImageTransparency = 1
	S.backgroundblurdisplay.Visible = true
	S.backgroundblurdisplay.ImageTransparency = 1 - opacity
end

function S.stopbackgroundblurjob()
	if S.backgroundblurconnection then S.backgroundblurconnection:Disconnect() end
	S.backgroundblurconnection = nil
	S.backgroundblurjob = nil
	S.backgroundblurrequest = nil
end

function S.schedulebackgroundblur(animate, requested, blur, asset, generation, job)
	blur = math.clamp(math.round(S.backgroundimageblur), 0, S.backgroundimageblurmax)
	asset = S.backgroundresolvedasset
	if blur <= 0 or not asset or asset == "" then
		S.backgroundblurtoken += 1
		S.stopbackgroundblurjob()
		S.applybackgroundblurblend()
		return
	end
	requested = asset .. ":" .. tostring(blur)
	if S.backgroundblurrequest == requested or S.backgroundblurlastsignature == requested then
		S.applybackgroundblurblend()
		return
	end
	S.backgroundblurtoken += 1
	S.stopbackgroundblurjob()
	if S.backgroundblurbaseasset ~= asset then
		if S.backgroundblurloading == asset then return end
		S.backgroundblurloading = asset
		generation = S.backgroundsourcegeneration or 0
		S.backgroundsourcegeneration = generation
		S.backgroundblurtask = task.spawn(function(success)
			success = S.preparebackgroundblurbase(asset, generation)
			if generation ~= S.backgroundsourcegeneration then return end
			S.backgroundblurloading = nil
			S.backgroundblurtask = nil
			if success then S.schedulebackgroundblur(false) end
		end)
		return
	end
	S.backgroundblurrequest = requested
	job = { token = S.backgroundblurtoken }
	job.thread = coroutine.create(function()
		if S.buildbackgroundblur(asset, blur, job.token) then S.applybackgroundblurblend() end
	end)
	S.backgroundblurjob = job
	S.backgroundblurconnection = S.runservice.PreRender:Connect(function(ok, message)
		if job.token ~= S.backgroundblurtoken then S.stopbackgroundblurjob() return end
		ok, message = coroutine.resume(job.thread)
		if not ok or coroutine.status(job.thread) == "dead" then
			S.stopbackgroundblurjob()
			if not ok then warn("blush image blur: " .. tostring(message)) end
		end
	end)
end

function S.renderbackgroundimage(animate, opacity, blur, visible, imageinfo, target)
	opacity = math.clamp(S.backgroundimageopacity / 100, 0, 1)
	blur = math.clamp(S.backgroundimageblur, 0, S.backgroundimageblurmax)
	visible = S.backgroundimagesource ~= "" and S.backgroundresolvedasset ~= nil
	imageinfo = S.quart26

	S.__blush_background_visibility = visible and opacity or 0
	S.updatebackgroundbounds()
	S.updatebackgroundtone()
	if S.updatebackgroundsurfaces then S.updatebackgroundsurfaces() end

	S.backgroundimage.ScaleType = Enum.ScaleType.Crop
	S.backgroundimage.Size = UDim2.fromScale(1, 1)
	S.backgroundimage.Position = UDim2.fromScale(0.5, 0.5)
	S.backgroundimage.ImageColor3 = Color3.new(1, 1, 1)
	S.backgroundblurdisplay.ScaleType = Enum.ScaleType.Crop
	S.backgroundblurdisplay.Size = UDim2.fromScale(1, 1)
	S.backgroundblurdisplay.Position = UDim2.fromScale(0.5, 0.5)
	S.backgroundblurdisplay.ImageColor3 = Color3.new(1, 1, 1)

	if not visible then
		S.backgroundblurdebounce += 1
		S.backgroundblurtoken += 1
		S.backgroundimage.Visible = false
		S.backgroundblurdisplay.Visible = false
		S.backgroundimage.ImageTransparency = 1
		S.backgroundblurdisplay.ImageTransparency = 1
		return
	end

	if blur <= 0 then
		S.backgroundblurdebounce += 1
		S.backgroundblurtoken += 1
		S.backgroundblurdisplay.Visible = false
		S.backgroundblurdisplay.ImageTransparency = 1
		S.backgroundimage.Visible = true
		target = 1 - opacity
		if animate and S.animationsenabled then
			S.tween(S.backgroundimage, { ImageTransparency = target }, imageinfo)
		else
			S.backgroundimage.ImageTransparency = target
		end
		return
	end

	S.backgroundimage.Visible = true
	S.applybackgroundblurblend()
	S.schedulebackgroundblur(animate)
end

function S.setbackgroundimageopacity(value, animate)
	S.backgroundimageopacity = math.clamp(tonumber(value) or 65, 0, 100)
	S.renderbackgroundimage(animate)
end

function S.setbackgroundimageblur(value, animate)
	S.backgroundimageblur = math.clamp(tonumber(value) or 0, 0, S.backgroundimageblurmax)
	S.renderbackgroundimage(animate)
end

function S.setbackgroundimagemode()
	S.backgroundimagemode = "Crop"
	for _, layer in ipairs(S.backgroundlayers) do
		layer.ScaleType = Enum.ScaleType.Crop
	end
end

function S.clearbackgroundimage(animate, finish, animation, current)
	S.__blush_background_token += 1
	S.backgroundimagesource = ""
	S.backgroundresolvedasset = nil
	S.backgroundpalette = nil
	S.__blush_background_visibility = 0
	S.destroybackgroundeditable()
	if S.updatebackgroundsurfaces then S.updatebackgroundsurfaces() end

	if S.autobackgroundcolors and S.backgroundautobase then S.restorebackgroundautobase(animate) end

	finish = function()
		if S.backgroundimagesource ~= "" then return end
		for _, layer in ipairs(S.backgroundlayers) do
			layer.Visible = false
			layer.Image = ""
			layer.ImageTransparency = 1
		end
	end

	if S.backgroundimage.Visible and animate and S.animationsenabled then
		animation = nil
		for index, layer in ipairs(S.backgroundlayers) do
			if layer.Visible then
				current = S.tween(layer, { ImageTransparency = 1 }, S.quart26)
				if index == 1 then animation = current end
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

S.backgroundpalette = nil
S.backgroundautobase = nil

function S.selectedthemebase(selected, preset2)
	selected = S.themeselector and S.themeselector:Get() or "Default"
	preset2 = S.themepresets and S.themepresets[selected]

	if preset2 then return preset2 end

	return {
		background = S.theme.window,
		accent = S.theme.white,
		font = S.theme.font,
	}
end

function S.buildbackgroundautocolors(
	average,
	sampledaccent,
	base,
	basebackground,
	baseaccent,
	ah,
	as,
	av,
	sh,
	ss,
	sv,
	_3,
	bases,
	basev,
	_4,
	baseas,
	baseav,
	baseluminance,
	lighttheme,
	hue,
	background,
	accent,
	luminance,
	fontcolor
)
	base = S.selectedthemebase()
	basebackground = base.background or S.theme.window
	baseaccent = base.accent or S.theme.white

	ah, as, av = average:ToHSV()
	sh, ss, sv = sampledaccent:ToHSV()
	_3, bases, basev = basebackground:ToHSV()
	_4, baseas, baseav = baseaccent:ToHSV()

	baseluminance = basebackground.R * 0.2126
		+ basebackground.G * 0.7152
		+ basebackground.B * 0.0722
	lighttheme = baseluminance >= 0.58
	hue = as >= 0.05 and ah or sh

	background = nil
	accent = nil

	if lighttheme then
		background = Color3.fromHSV(
			hue,
			math.clamp(as * 0.16 + bases * 0.18, 0.015, 0.14),
			math.clamp(math.max(basev, 0.90), 0.90, 0.975)
		)
		accent = Color3.fromHSV(
			sh,
			math.clamp(ss * 0.86 + baseas * 0.14, 0.42, 0.82),
			math.clamp(math.min(sv, 0.68) * 0.72 + baseav * 0.28, 0.38, 0.68)
		)
	else
		background = Color3.fromHSV(
			hue,
			math.clamp(as * 0.28 + bases * 0.32, 0.035, 0.24),
			math.clamp(basev * 0.72 + 0.025, 0.045, 0.13)
		)
		accent = Color3.fromHSV(
			sh,
			math.clamp(ss * 0.86 + baseas * 0.14, 0.48, 0.88),
			math.clamp(math.max(sv, 0.76) * 0.86 + baseav * 0.14, 0.72, 0.96)
		)
	end

	luminance = background.R * 0.2126 + background.G * 0.7152 + background.B * 0.0722
	fontcolor = luminance >= 0.55 and Color3.fromRGB(30, 31, 35) or Color3.fromRGB(240, 241, 244)

	return background, accent, fontcolor
end

function S.applybackgroundautocolors(animate, background, accent, fontcolor)
	if not S.autobackgroundcolors or not S.backgroundpalette then return false end

	if not S.backgroundautobase then
		S.backgroundautobase = {
			background = S.theme.window,
			accent = S.theme.white,
			font = S.theme.font,
			backgroundAlpha = S.theme.backgroundAlpha,
			accentAlpha = S.theme.accentAlpha,
			fontAlpha = S.theme.fontAlpha,
		}
	end

	background, accent, fontcolor =
		S.buildbackgroundautocolors(S.backgroundpalette.average, S.backgroundpalette.accent)

	S.applytheme(background, accent, 1, 1, fontcolor, 1, animate == true)

	if S.accentpicker then S.accentpicker:Set(accent, 1, false) end
	if S.backgroundpicker then S.backgroundpicker:Set(background, 1, false) end
	if S.fontpicker then S.fontpicker:Set(fontcolor, 1, false) end

	return true
end

function S.restorebackgroundautobase(animate, base)
	base = S.backgroundautobase or S.selectedthemebase()
	S.backgroundautobase = nil

	S.applytheme(
		base.background or S.theme.window,
		base.accent or S.theme.white,
		base.backgroundAlpha or 1,
		base.accentAlpha or 1,
		base.font or S.theme.font,
		base.fontAlpha or 1,
		animate == true
	)

	if S.accentpicker then
		S.accentpicker:Set(base.accent or S.theme.white, base.accentAlpha or 1, false)
	end
	if S.backgroundpicker then
		S.backgroundpicker:Set(base.background or S.theme.window, base.backgroundAlpha or 1, false)
	end
	if S.fontpicker then S.fontpicker:Set(base.font or S.theme.font, base.fontAlpha or 1, false) end
end

function S.samplebackgroundpalette(asset, editable, ok, success, average, accent)
	if not S.autobackgroundcolors or not asset or asset == "" then return false end

	editable = nil
	ok = S.invoke(
		function() editable = S.assetservice:CreateEditableImageAsync(Content.fromUri(asset)) end
	)

	if not ok or not editable then return false end

	success, average, accent = S.invoke(
		function(
			size,
			totalr,
			totalg,
			totalb,
			totalweight,
			bestcolor,
			bestscore,
			steps,
			px,
			py,
			pixels,
			r,
			g,
			b,
			a,
			color,
			h,
			s,
			v,
			midvalue,
			score
		)
			size = editable.Size
			if size.X < 1 or size.Y < 1 then return nil, nil end

			totalr, totalg, totalb, totalweight = 0, 0, 0, 0
			bestcolor = Color3.new(1, 1, 1)
			bestscore = -1
			steps = 7

			for y = 0, steps - 1 do
				for x = 0, steps - 1 do
					px = math.clamp(
						math.floor((x + 0.5) / steps * size.X),
						0,
						math.max(0, size.X - 1)
					)
					py = math.clamp(
						math.floor((y + 0.5) / steps * size.Y),
						0,
						math.max(0, size.Y - 1)
					)
					pixels = editable:ReadPixelsBuffer(Vector2.new(px, py), Vector2.new(1, 1))
					r = buffer.readu8(pixels, 0) / 255
					g = buffer.readu8(pixels, 1) / 255
					b = buffer.readu8(pixels, 2) / 255
					a = buffer.readu8(pixels, 3) / 255

					if a > 0.05 then
						color = Color3.new(r, g, b)
						h, s, v = color:ToHSV()
						midvalue = 1 - math.abs(v - 0.62)
						score = s * (0.45 + math.max(0, midvalue)) * a

						totalr += r * a
						totalg += g * a
						totalb += b * a
						totalweight += a

						if score > bestscore then
							bestscore = score
							bestcolor = Color3.fromHSV(
								h,
								math.clamp(math.max(s, 0.36), 0.36, 0.92),
								math.clamp(v, 0.42, 0.94)
							)
						end
					end
				end
			end

			if totalweight <= 0 then return nil, nil end

			return Color3.new(totalr / totalweight, totalg / totalweight, totalb / totalweight),
				bestcolor
		end
	)

	editable:Destroy()

	if not success or not average or not accent then return false end

	S.backgroundpalette = {
		average = average,
		accent = accent,
	}

	return S.applybackgroundautocolors(true)
end

function S.loadbackgroundimage(source, force, silent, token, asset, err)
	source = S.trimbackgroundsource(source)

	if source == "" then
		S.clearbackgroundimage(true)
		return true
	end

	S.__blush_background_token += 1
	token = S.__blush_background_token
	asset, err = S.resolvebackgroundimage(source, force == true)

	if token ~= S.__blush_background_token then return false, "cancelled" end

	if not asset then
		if not silent then
			S.notify(
				"Background unavailable",
				tostring(err or "Could not load image."),
				3,
				nil,
				nil,
				S.icons.wallpaper
			)
		end
		return false, err
	end

	S.backgroundimagesource = source
	if S.backgroundresolvedasset ~= asset then
		S.backgroundblurbaseasset = nil
		S.backgroundblurbasepixels = nil
		S.backgroundblurbasewidth = 0
		S.backgroundblurbaseheight = 0
		S.backgroundblurlastsignature = nil
		if S.backgroundblureditable then
			S.backgroundblureditable:Destroy()
			S.backgroundblureditable = nil
		end
	end
	S.backgroundresolvedasset = asset
	S.backgroundpalette = nil
	S.backgroundimagemode = "Crop"
	if S.updatebackgroundsurfaces then S.updatebackgroundsurfaces() end
	for _, layer in ipairs(S.backgroundlayers) do
		layer.Image = asset
		layer.ScaleType = Enum.ScaleType.Crop
		layer.ImageTransparency = 1
		layer.Visible = true
	end

	S.backgroundimage.Image = asset
	S.backgroundimage.Visible = true
	S.renderbackgroundimage(S.animationsenabled)

	if S.autobackgroundcolors then
		task.spawn(function()
			if S.samplebackgroundpalette(asset) then S.saveuisettings() end
		end)
	end

	if not silent then
		S.notify(
			"Background loaded",
			"Image applied to the interface.",
			2.2,
			nil,
			nil,
			S.icons.wallpaper
		)
	end

	return true
end

S.__blush_background = {
	Set = function(source, force) return S.loadbackgroundimage(source, force == true, true) end,
	Clear = function() S.clearbackgroundimage(true) end,
	SetOpacity = function(value) S.setbackgroundimageopacity(value, true) end,
	SetBlur = function(value) S.setbackgroundimageblur(value, true) end,
	SetScale = function() S.setbackgroundimagemode("Crop") end,
}

function S.decodecolor(value, r, g, b)
	if typeof(value) ~= "table" then return nil end

	r = tonumber(value.r or value[1])
	g = tonumber(value.g or value[2])
	b = tonumber(value.b or value[3])

	if not r or not g or not b then return nil end

	return Color3.fromRGB(
		math.clamp(math.round(r), 0, 255),
		math.clamp(math.round(g), 0, 255),
		math.clamp(math.round(b), 0, 255)
	)
end

function S.encodecolor(color)
	return {
		r = math.round(color.R * 255),
		g = math.round(color.G * 255),
		b = math.round(color.B * 255),
	}
end

function S.keyfromname(name)
	if typeof(name) ~= "string" then return nil end

	for _, key in ipairs(Enum.KeyCode:GetEnumItems()) do
		if key.Name == name then return key end
	end

	for _, inputtype in ipairs(Enum.UserInputType:GetEnumItems()) do
		if inputtype.Name == name and S.validmousebind(inputtype) then return inputtype end
	end

	return nil
end

function S.readuisettingsfile(ok, encoded, decodedok, decoded)
	if typeof(readfile) ~= "function" then return {} end

	ok, encoded = S.invoke(function()
		if typeof(isfile) == "function" and not isfile(S.settingspath) then return nil end

		return readfile(S.settingspath)
	end)

	if not ok or not encoded or encoded == "" then return {} end

	decodedok, decoded = S.invoke(function() return S.httpservice:JSONDecode(encoded) end)

	if decodedok and typeof(decoded) == "table" then return decoded end

	return {}
end

S.savedsettings = S.readuisettingsfile()
S.rawsavedsettings = S.savedsettings
S.selectedconfig = S.sanitizefilename(S.rawsavedsettings.selectedConfig or "")
S.selectedthemesave = S.sanitizefilename(S.rawsavedsettings.selectedThemeSave or "")

S.animationsenabled = S.savedsettings.animations ~= false

S.searchenabled = S.savedsettings.searchCurrentPage ~= false

S.menukey = S.keyfromname(S.savedsettings.menuKey) or Enum.KeyCode.RightShift

S.setkeybindblacklist(
	type(S.savedsettings.keybindBlacklist) == "table" and S.savedsettings.keybindBlacklist
		or S.keybindblacklistdefaults
)

S.initialtransparency = math.clamp(tonumber(S.savedsettings.uiTransparency) or 0, 0, 90)


S.notificationsenabled = S.savedsettings.notifications ~= false

S.defaultnotificationduration = 3.5
S.maxnotifications = 5

S.backgroundimagesource = type(S.savedsettings.backgroundImageSource) == "string"
		and S.savedsettings.backgroundImageSource
	or ""
S.backgroundimageopacity =
	math.clamp(tonumber(S.savedsettings.backgroundImageOpacity) or 65, 0, 100)
S.backgroundimageblur =
	math.clamp(tonumber(S.savedsettings.backgroundImageBlur) or 0, 0, S.backgroundimageblurmax)
S.backgroundimagemode = "Crop"
S.backgroundexcludesidebar = S.savedsettings.backgroundImageExcludeSidebar == true
S.autobackgroundcolors = false
S.topnavigationenabled = S.savedsettings.topNavigation == true

S.windowglowenabled = S.savedsettings.windowGlow ~= false
S.windowglowintensity =
	math.clamp(tonumber(S.savedsettings.windowGlowIntensity) or 16, 0, S.windowglowintensitymax)
S.windowglowsize =
	math.clamp(tonumber(S.savedsettings.windowGlowSize) or 10, 0, S.windowglowsizemax)
S.windowglowcolor = S.theme.white
S.windowglowalpha = math.clamp(tonumber(S.savedsettings.windowGlowAlpha) or 1, 0, 1)
S.windowglowrenderalpha = S.windowglowalpha

S.applywindowglow()

S.setbackgroundimagemode("Crop")
S.setbackgroundexcludesidebar(S.backgroundexcludesidebar)
S.setbackgroundimageopacity(S.backgroundimageopacity, false)
S.setbackgroundimageblur(S.backgroundimageblur, false)

S.applyuitransparency(S.initialtransparency)


S.loadingsettings = true
S.watermarktoggle = nil
S.watermarkinfocontrol = nil
S.watermarkplayermodecontrol = nil
S.themeselector = nil
S.accentpicker = nil
S.backgroundpicker = nil
S.fontpicker = nil
S.maincolorpicker = nil
S.animationtoggle = nil
S.searchtoggle = nil
S.menukeypicker = nil
S.keybindblacklistcontrol = nil
S.hotkeylisttoggle = nil
S.minimizebuttoncontrol = nil
S.uitransparencycontrol = nil
S.notificationtoggle = nil
S.configselector = nil
S.configinput = nil
S.autosaveconfigcontrol = nil
S.themfileselector = nil
S.themefileinput = nil
S.settingssection = nil
S.themessection = nil
S.backgroundimagesection = nil
S.backgroundimageinput = nil
S.backgroundimageopacitycontrol = nil
S.backgroundimageblurcontrol = nil
S.backgroundexcludecontrol = nil
S.backgroundautocolorcontrol = nil
S.topnavigationtoggle = nil
S.windowglowtoggle = nil
S.windowglowintensitycontrol = nil
S.windowglowsizecontrol = nil
S.windowglowcolorpicker = nil
S.highlightpicker = nil
S.keybindssection = nil
S.windowsection = nil
S.savessection = nil

function S.panelthemepayload(result, colors)
	result = {}
	for name, panel in pairs(S.panelthemes) do
		colors = {}
		for role, color in pairs(panel.overrides) do colors[role] = { color.R, color.G, color.B } end
		result[name] = { colors = colors, opacity = panel.opacity, glow = panel.glow }
	end
	return result
end

function S.loadpanelthemes(payload, panel)
	for name, data in pairs(type(payload) == "table" and payload or {}) do
		panel = S.panelthemes[name]
		if panel and type(data) == "table" then
			for role in pairs(panel.overrides) do S.setpanelcolor(panel, role, nil) end
			for role, rgb in pairs(data.colors or {}) do
				if S.theme[role] and type(rgb) == "table" and #rgb == 3 then S.setpanelcolor(panel, role, Color3.new(rgb[1], rgb[2], rgb[3])) end
			end
			panel.opacity = math.clamp(tonumber(data.opacity) or 1, 0, 1)
			panel.root.BackgroundTransparency = S.effectivetransparency(0, "popup", panel.root)
			if panel.pickers then
				for role, picker in pairs(panel.pickers) do picker:Set(panel.overrides[role] or S.theme[role], 1, false) end
			end
			if panel.opacitycontrol then panel.opacitycontrol:Set(panel.opacity * 100, false) end
			if panel.glowcontrol and data.glow ~= nil then panel.glowcontrol:Set(data.glow) end
		end
	end
end

function S.addpanelsettings(section, panel, roles, shadow)
	panel.pickers = {}
	for _, definition in ipairs(roles) do
		panel.pickers[definition[2]] = section:AddColorPicker(definition[1], panel.overrides[definition[2]] or S.theme[definition[2]], function(color)
			S.setpanelcolor(panel, definition[2], color)
			S.saveuisettings()
		end)
	end
	panel.opacitycontrol = section:AddSlider("Opacity", 0, 100, panel.opacity * 100, "%", function(value)
		panel.opacity = value / 100
		panel.root.BackgroundTransparency = S.effectivetransparency(0, "popup", panel.root)
		S.saveuisettings()
	end)
	section:AddButton("Reset colors", function()
		for role, picker in pairs(panel.pickers) do
			S.setpanelcolor(panel, role, nil)
			picker:Set(S.theme[role], 1, false)
		end
		S.saveuisettings()
	end)
	if shadow then
		panel.glowcontrol = section:AddSlider("Glow", 0, 100, 0, "%", function(value)
			panel.glow = value
			shadow.Transparency = 1 - value / 100 * 0.35
			shadow:SetAttribute("BlushBaseTransparency", shadow.Transparency)
			S.saveuisettings()
		end)
	end
end

function S.currentuipayload(accent, background, maincolor, highlightcolor, fontcolor, selectedmenukey)
	accent = S.accentpicker and S.accentpicker:color() or S.theme.white

	background = S.backgroundpicker and S.backgroundpicker:color() or S.theme.window

	maincolor = S.maincolorpicker and S.maincolorpicker:color() or S.theme.main

	highlightcolor = S.highlightpicker and S.highlightpicker:color() or S.theme.highlight

	fontcolor = S.fontpicker and S.fontpicker:color() or S.theme.font

	selectedmenukey = S.menukeypicker and S.menukeypicker:Get() or S.menukey

	return {
		panelThemes = S.panelthemepayload(),
		watermark = S.watermarktoggle and S.watermarktoggle:Get() or S.watermarkshown,

		watermarkInfo = {
			Player = S.watermarkconfig.Player == true,
			FPS = S.watermarkconfig.FPS == true,
			Ping = S.watermarkconfig.Ping == true,
			Time = S.watermarkconfig.Time == true,
			Game = S.watermarkconfig.Game == true,
			PlayerMode = S.watermarkconfig.PlayerMode,
		},

		animations = S.animationtoggle and S.animationtoggle:Get() or S.animationsenabled,

		searchCurrentPage = S.searchtoggle and S.searchtoggle:Get() or S.searchenabled,

		notifications = S.notificationtoggle and S.notificationtoggle:Get()
			or S.notificationsenabled,

		hotkeyList = S.hotkeylisttoggle and S.hotkeylisttoggle:Get() or S.hotkeylist.Visible,

		minimizeButton = S.minimizebuttoncontrol and S.minimizebuttoncontrol:Get()
			or S.windowminimizebuttonenabled,

		backgroundImageSource = S.backgroundimagesource,

		backgroundImageOpacity = S.backgroundimageopacitycontrol
				and S.backgroundimageopacitycontrol:Get()
			or S.backgroundimageopacity,

		backgroundImageBlur = S.backgroundimageblurcontrol and S.backgroundimageblurcontrol:Get()
			or S.backgroundimageblur,

		backgroundImageMode = "Crop",
		backgroundImageExcludeSidebar = S.backgroundexcludecontrol
				and S.backgroundexcludecontrol:Get()
			or S.backgroundexcludesidebar,
		backgroundAutoColors = false,
		topNavigation = S.topnavigationtoggle and S.topnavigationtoggle:Get()
			or S.topnavigationenabled,

		windowGlow = S.windowglowtoggle and S.windowglowtoggle:Get() or S.windowglowenabled,

		windowGlowIntensity = S.windowglowintensitycontrol and S.windowglowintensitycontrol:Get()
			or S.windowglowintensity,

		windowGlowSize = S.windowglowsizecontrol and S.windowglowsizecontrol:Get()
			or S.windowglowsize,

		windowGlowColor = S.encodecolor(S.windowglowcolor),
		windowGlowAlpha = S.windowglowcolorpicker and S.windowglowcolorpicker.alpha
			or S.windowglowalpha,

		uiTransparency = S.uitransparencycontrol and S.uitransparencycontrol:Get()
			or math.floor(S.uitransparency * 100 + 0.5),

		selectedConfig = S.selectedconfig,
		selectedThemeSave = S.selectedthemesave,
		autoSaveConfig = S.autosaveconfigcontrol and S.autosaveconfigcontrol:Get()
			or S.rawsavedsettings.autoSaveConfig == true,

		menuKey = selectedmenukey and selectedmenukey.Name or Enum.KeyCode.RightShift.Name,

		keybindBlacklist = S.getkeybindblacklistnames(),

		theme = S.themeselector and S.themeselector:Get() or "Default",

		main = S.encodecolor(maincolor),
		highlight = S.encodecolor(highlightcolor),
		accent = S.encodecolor(accent),
		background = S.encodecolor(background),
		font = S.encodecolor(fontcolor),

		mainAlpha = S.maincolorpicker and S.maincolorpicker:currentalpha() or S.theme.mainAlpha,
		highlightAlpha = S.highlightpicker and S.highlightpicker:currentalpha() or S.theme.highlightAlpha,
		accentAlpha = S.accentpicker and S.accentpicker:currentalpha() or S.theme.accentAlpha,

		backgroundAlpha = S.backgroundpicker and S.backgroundpicker:currentalpha()
			or S.theme.backgroundAlpha,

		fontAlpha = S.fontpicker and S.fontpicker:currentalpha() or S.theme.fontAlpha,
	}
end

function S.currentthemepayload(payload)
	payload = S.currentuipayload()
	return {
		theme = payload.theme,
		main = payload.main,
		highlight = payload.highlight,
		accent = payload.accent,
		background = payload.background,
		font = payload.font,
		mainAlpha = payload.mainAlpha,
		highlightAlpha = payload.highlightAlpha,
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

function S.autosaveenabled()
	return S.autosaveconfigcontrol and S.autosaveconfigcontrol:Get() == true
end

function S.commitsavedsettings()
	S.__blush_save_task = nil
	if
		not S.pendingsettingssave
		or S.loadingsettings
		or S.constructing
		or not S.autosaveenabled()
	then
		return
	end
	if S.interactionowner then return end
	S.pendingsettingssave = false
	writefile(S.settingspath, S.httpservice:JSONEncode(S.currentuipayload()))
end

function S.saveuisettings(force)
	if S.loadingsettings or S.constructing or typeof(writefile) ~= "function" then return end
	if force then
		S.pendingsettingssave = false
		writefile(S.settingspath, S.httpservice:JSONEncode(S.currentuipayload()))
		return
	end
	if S.continuouscolorupdate or not S.autosaveenabled() then return end
	S.pendingsettingssave = true
	if not S.interactionowner and not S.__blush_save_task then
		S.__blush_save_task = task.defer(S.commitsavedsettings)
	end
end

S.__blush_configcontrols = S.__blush_configcontrols or {}
S.__blush_pending_controlvalues = S.__blush_pending_controlvalues or {}
S.__blush_autosave_serial = S.__blush_autosave_serial or 0
S.__blush_autosave_task = nil

function S.encodepersistentvalue(value, kind, result)
	kind = typeof(value)

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
		result = {}

		for key, child in pairs(value) do
			result[tostring(key)] = S.encodepersistentvalue(child)
		end

		return result
	end

	if kind == "number" or kind == "string" or kind == "boolean" or kind == "nil" then
		return value
	end

	return tostring(value)
end

function S.decodepersistentvalue(value, enumname, enumtype, userid, result)
	if type(value) ~= "table" then return value end

	if value.__blush_type == "Color3" then
		return Color3.new(
			math.clamp(tonumber(value.r) or 1, 0, 1),
			math.clamp(tonumber(value.g) or 1, 0, 1),
			math.clamp(tonumber(value.b) or 1, 0, 1)
		)
	end

	if value.__blush_type == "EnumItem" then
		enumname = tostring(value.enum or ""):gsub("^Enum%.", "")

		enumtype = Enum[enumname]
		return enumtype and enumtype[value.name] or nil
	end

	if value.__blush_type == "Player" then
		userid = tonumber(value.userId)

		if userid then
			for _, targetplayer in ipairs(S.players:GetPlayers()) do
				if targetplayer.UserId == userid then return targetplayer end
			end
		end

		return value.name
	end

	result = {}

	for key, child in pairs(value) do
		result[key] = S.decodepersistentvalue(child)
	end

	return result
end

function S.persistentcontrolid(section, kind, name, config, explicit, page)
	if type(config) == "table" then
		explicit = config.Flag or config.SaveKey or config.Id or config.ID

		if explicit ~= nil and tostring(explicit) ~= "" then return tostring(explicit) end
	end

	page = section and section.page
	return table.concat({
		page and tostring(page.name or page.primary or "") or "",
		section and tostring(section.name or "") or "",
		tostring(kind or "Control"),
		tostring(name or ""),
	}, "|")
end

function S.commitconfigautosave()
	S.__blush_autosave_task = nil
	if
		not S.pendingconfigsave
		or S.constructing
		or S.loadingsettings
		or not S.autosaveenabled()
	then
		return
	end
	if S.interactionowner then return end
	S.pendingconfigsave = false
	if S.selectedconfig ~= "" and S.selectedconfig ~= "None" then
		S.saveconfigfile(S.selectedconfig, true)
	end
end

function S.requestconfigautosave()
	if
		S.constructing
		or S.loadingsettings
		or S.continuouscolorupdate
		or not S.autosaveenabled()
	then
		return
	end
	S.pendingconfigsave = true
	if not S.interactionowner and not S.__blush_autosave_task then
		S.__blush_autosave_task = task.defer(S.commitconfigautosave)
	end
end

function S.persistentcallback(callback)
	return function(...)
		if S.constructing then return end
		if callback then callback(...) end

		S.requestconfigautosave()
	end
end

function S.registerpersistentcontrol(
	section,
	kind,
	name,
	control,
	config,
	inputcallback,
	id,
	anchor,
	entry,
	destroying,
	pending,
	oldloading
)
	if not control then return control end

	id = S.persistentcontrolid(section, kind, name, config)

	anchor = typeof(control) == "Instance" and control or (control.Object or control.swatch)

	entry = {
		id = id,
		kind = kind,
		control = control,
		anchor = anchor,
	}

	if kind == "Input" and control:IsA("TextBox") then
		entry.get = function() return control.Text end

		entry.set = function(value)
			control.Text = tostring(value or "")

			if inputcallback then inputcallback(control.Text) end
		end
	elseif kind == "ColorPicker" and type(control.color) == "function" then
		entry.get = function()
			return {
				color = S.encodepersistentvalue(control:color()),
				alpha = control.alpha,
			}
		end

		entry.set = function(value, colorvalue)
			if type(value) ~= "table" then return end

			colorvalue = S.decodepersistentvalue(value.color)

			if typeof(colorvalue) ~= "Color3" then return end

			control:Set(colorvalue, math.clamp(tonumber(value.alpha) or 1, 0, 1), true)
		end
	elseif
		(kind == "ToggleColor" or kind == "ToggleColorKey")
		and type(control.Get) == "function"
		and type(control.Set) == "function"
		and control.Color
		and type(control.Color.color) == "function"
	then
		entry.get = function()
			return {
				value = control:Get(),
				color = S.encodepersistentvalue(control.Color:color()),
				alpha = control.Color.alpha,
			}
		end

		entry.set = function(value, colorvalue)
			if type(value) ~= "table" then return end

			control:Set(value.value == true, true)

			colorvalue = S.decodepersistentvalue(value.color)

			if typeof(colorvalue) == "Color3" then
				control.Color:Set(colorvalue, math.clamp(tonumber(value.alpha) or 1, 0, 1), true)
			end
		end

		control.Color.onpersist = S.requestconfigautosave
	elseif
		kind == "RangeSlider"
		and type(control.Get) == "function"
		and type(control.Set) == "function"
	then
		entry.get = function(low, high)
			low, high = control:Get()

			return {
				low = low,
				high = high,
			}
		end

		entry.set = function(value)
			if type(value) == "table" then control:Set(value.low, value.high, true) end
		end
	elseif type(control.Get) == "function" and type(control.Set) == "function" then
		entry.get = function() return S.encodepersistentvalue(control:Get()) end

		entry.set = function(value) control:Set(S.decodepersistentvalue(value), true) end
	else
		return control
	end

	if kind == "ColorPicker" then control.onpersist = S.requestconfigautosave end

	S.__blush_configcontrols[id] = entry

	if anchor and anchor.Destroying then
		destroying = nil
		destroying = anchor.Destroying:Connect(function()
			if destroying then
				destroying:Disconnect()
				destroying = nil
			end

			if S.__blush_configcontrols[id] == entry then S.__blush_configcontrols[id] = nil end
		end)
	end

	pending = S.__blush_pending_controlvalues[id]

	if pending ~= nil then
		oldloading = S.loadingsettings
		S.loadingsettings = true

		S.invoke(entry.set, pending)

		S.loadingsettings = oldloading
	end

	return control
end

function S.currentcontrolpayload(payload, alive, ok, value)
	payload = {}

	for id, entry in pairs(S.__blush_configcontrols) do
		alive = entry
			and entry.control
			and entry.get
			and (not entry.anchor or entry.anchor.Parent ~= nil)

		if alive then
			ok, value = S.invoke(entry.get)

			if ok then payload[id] = S.encodepersistentvalue(value) end
		else
			S.__blush_configcontrols[id] = nil
		end
	end

	return payload
end

function S.applycontrolpayload(payload, oldloading, entry)
	S.__blush_pending_controlvalues = type(payload) == "table" and payload or {}

	if type(payload) ~= "table" then return end

	oldloading = S.loadingsettings
	S.loadingsettings = true

	for id, value in pairs(payload) do
		entry = S.__blush_configcontrols[id]

		if entry and entry.set then S.invoke(entry.set, S.decodepersistentvalue(value)) end
	end

	S.loadingsettings = oldloading
end

function S.refreshconfigfiles(preferred, names)
	if not S.configselector then return end

	names = S.listjsonnames(S.configfolder)
	if #names == 0 then names = { "None" } end

	S.configselector:SetOptions(names, preferred or S.selectedconfig)
end

function S.refreshthemefiles(preferred, names)
	if not S.themfileselector then return end

	names = S.listjsonnames(S.themefolder)
	if #names == 0 then names = { "None" } end

	S.themfileselector:SetOptions(names, preferred or S.selectedthemesave)
end

function S.saveconfigfile(name, autosave, payload, ok)
	name = S.sanitizefilename(name)
	if name == "" then return false end

	S.selectedconfig = name

	payload = S.currentuipayload()

	payload.autoSaveConfig = nil
	payload.keybinds = S.currentkeybindpayload()
	payload.controls = S.currentcontrolpayload()

	ok = S.writejsonfile(S.configfolder .. "/" .. name .. ".json", payload)

	if ok then
		if not autosave then
			if S.configinput then S.configinput.Text = name end

			S.refreshconfigfiles(name)
		end

		S.saveuisettings(true)
	end

	return ok
end

function S.loadconfigfile(name, silent, data, oldloading)
	name = S.sanitizefilename(name)
	if name == "" or name == "None" then return false end

	data = S.readjsonfile(S.configfolder .. "/" .. name .. ".json")

	if not data then return false end

	S.selectedconfig = name
	if S.configinput then S.configinput.Text = name end
	S.refreshconfigfiles(name)

	oldloading = S.loadingsettings
	S.loadingsettings = true

	S.applysaveduisettings(data, silent == true)
	S.applykeybindpayload(data.keybinds)
	S.applycontrolpayload(data.controls)

	S.loadingsettings = oldloading
	S.syncwindowglowcolor(false)
	S.saveuisettings(true)
	return true
end

function S.deleteconfigfile(name, path, ok)
	name = S.sanitizefilename(name)
	if name == "" or name == "None" or typeof(delfile) ~= "function" then return false end

	path = S.configfolder .. "/" .. name .. ".json"
	ok = S.invoke(function()
		if typeof(isfile) ~= "function" or isfile(path) then delfile(path) end
	end)

	if ok then
		if S.selectedconfig == name then S.selectedconfig = "" end
		S.refreshconfigfiles()
		S.saveuisettings(true)
	end

	return ok
end

function S.applythemepayload(
	data,
	preset3,
	background,
	accent,
	maincolor,
	highlightcolor,
	fontcolor,
	mainalpha,
	highlightalpha,
	backgroundalpha,
	accentalpha,
	fontalpha,
	oldloading,
	imagesource,
	imageopacity,
	imageblur
)
	if typeof(data) ~= "table" then return false end

	preset3 = type(data.theme) == "string" and data.theme or "Default"

	if not S.themepresets[preset3] then preset3 = "Default" end

	background = S.decodecolor(data.background) or S.theme.window
	accent = S.decodecolor(data.accent) or S.theme.white
	maincolor = S.decodecolor(data.main) or accent
	highlightcolor = S.decodecolor(data.highlight) or accent
	fontcolor = S.decodecolor(data.font) or S.theme.font
	mainalpha = math.clamp(tonumber(data.mainAlpha) or 1, 0, 1)
	highlightalpha = math.clamp(tonumber(data.highlightAlpha) or 1, 0, 1)
	backgroundalpha = math.clamp(tonumber(data.backgroundAlpha) or 1, 0, 1)
	accentalpha = math.clamp(tonumber(data.accentAlpha) or 1, 0, 1)
	fontalpha = math.clamp(tonumber(data.fontAlpha) or 1, 0, 1)

	oldloading = S.loadingsettings
	S.loadingsettings = true

	S.backgroundexcludesidebar = data.backgroundImageExcludeSidebar == true
	S.autobackgroundcolors = false
	S.setbackgroundexcludesidebar(S.backgroundexcludesidebar)

	if S.backgroundexcludecontrol then
		S.backgroundexcludecontrol:Set(S.backgroundexcludesidebar, false)
	end
	if S.backgroundautocolorcontrol then
		S.backgroundautocolorcontrol:Set(S.autobackgroundcolors, false)
	end

	S.themeselector:Set(preset3, false)
	S.applytheme(background, accent, backgroundalpha, accentalpha, fontcolor, fontalpha, false)
	S.applymaincolor(maincolor, false)
	S.applymainalpha(mainalpha)
	S.applyhighlight(highlightcolor, highlightalpha, false)
	if S.maincolorpicker then S.maincolorpicker:Set(maincolor, mainalpha, false) end
	if S.highlightpicker then S.highlightpicker:Set(highlightcolor, highlightalpha, false) end
	S.accentpicker:Set(accent, accentalpha, false)
	S.backgroundpicker:Set(background, backgroundalpha, false)
	S.fontpicker:Set(fontcolor, fontalpha, false)

	S.syncwindowglowcolor(false)

	imagesource = type(data.backgroundImageSource) == "string" and data.backgroundImageSource or ""
	imageopacity = math.clamp(tonumber(data.backgroundImageOpacity) or 65, 0, 100)
	imageblur = math.clamp(tonumber(data.backgroundImageBlur) or 0, 0, S.backgroundimageblurmax)

	S.backgroundimagesource = imagesource
	S.setbackgroundimagemode("Crop")
	S.setbackgroundimageopacity(imageopacity, false)
	S.setbackgroundimageblur(imageblur, false)

	if S.backgroundimageinput then S.backgroundimageinput.Text = imagesource end
	if S.backgroundimageopacitycontrol then
		S.backgroundimageopacitycontrol:Set(imageopacity, false)
	end
	if S.backgroundimageblurcontrol then S.backgroundimageblurcontrol:Set(imageblur, false) end

	if imagesource ~= "" then
		task.spawn(function() S.loadbackgroundimage(imagesource, false, true) end)
	else
		S.clearbackgroundimage(false)
	end

	S.loadingsettings = oldloading
	return true
end

function S.savethemefile(name, ok)
	name = S.sanitizefilename(name)
	if name == "" then return false end

	S.selectedthemesave = name
	ok = S.writejsonfile(S.themefolder .. "/" .. name .. ".json", S.currentthemepayload())

	if ok then
		if S.themefileinput then S.themefileinput.Text = name end
		S.refreshthemefiles(name)
		S.saveuisettings(true)
	end

	return ok
end

function S.loadthemefile(name, data)
	name = S.sanitizefilename(name)
	if name == "" or name == "None" then return false end

	data = S.readjsonfile(S.themefolder .. "/" .. name .. ".json")

	if not data or not S.applythemepayload(data) then return false end

	S.selectedthemesave = name
	if S.themefileinput then S.themefileinput.Text = name end
	S.refreshthemefiles(name)
	S.saveuisettings(true)
	return true
end

function S.deletethemefile(name, path, ok)
	name = S.sanitizefilename(name)
	if name == "" or name == "None" or typeof(delfile) ~= "function" then return false end

	path = S.themefolder .. "/" .. name .. ".json"
	ok = S.invoke(function()
		if typeof(isfile) ~= "function" or isfile(path) then delfile(path) end
	end)

	if ok then
		if S.selectedthemesave == name then S.selectedthemesave = "" end
		S.refreshthemefiles()
		S.saveuisettings(true)
	end

	return ok
end

S.settingssection = S.createsection(S.settings, "left", "Interface", S.icons.settings)

S.interfaceflags = S.settingssection:AddRow(10, 24)

S.watermarktoggle = S.interfaceflags:AddToggle(
	"Watermark",
	S.savedsettings.watermark == true,
	function(value)
		S.setwatermarkvisible(value, true)
		S.saveuisettings()
	end
)

S.setwatermarkvisible(S.savedsettings.watermark == true, false)

if type(S.savedsettings.watermarkInfo) == "table" then
	S.watermarkconfig.Player = S.savedsettings.watermarkInfo.Player ~= false

	S.watermarkconfig.FPS = S.savedsettings.watermarkInfo.FPS ~= false

	S.watermarkconfig.Ping = S.savedsettings.watermarkInfo.Ping ~= false

	S.watermarkconfig.Time = S.savedsettings.watermarkInfo.Time ~= false
	S.watermarkconfig.Game = S.savedsettings.watermarkInfo.Game == true

	S.watermarkconfig.PlayerMode =
		S.normalizewatermarkplayermode(S.savedsettings.watermarkInfo.PlayerMode)
end

S.watermarkinfodefault = {}

for _, item in ipairs({ "Player", "Fps", "Ping", "Time", "Game" }) do
	S.enabled = item == "Fps" and S.watermarkconfig.FPS or S.watermarkconfig[item]

	if S.enabled then table.insert(S.watermarkinfodefault, item) end
end

S.watermarksettingssection = S.createsection(S.settings, "right", "Watermark", S.icons.tag)
S.watermarkinfocontrol = S.watermarksettingssection:AddMultiDropdown(
	"Watermark info",
	{
		"Player",
		"Fps",
		"Ping",
		"Time", "Game",
	},
	S.watermarkinfodefault,
	function(values, selected)
		selected = {}

		for _, value in ipairs(values) do
			selected[value] = true
		end

		S.watermarkconfig.Player = selected.Player == true

		S.watermarkconfig.FPS = selected.Fps == true

		S.watermarkconfig.Ping = selected.Ping == true

		S.watermarkconfig.Time = selected.Time == true
		S.watermarkconfig.Game = selected.Game == true

		S.updatewatermarklayout()
		S.saveuisettings()
	end
)

S.playermodedefault = {}
S.normalizedplayermode = S.normalizewatermarkplayermode(S.watermarkconfig.PlayerMode)
if S.normalizedplayermode == "Display" or S.normalizedplayermode == "Both" then
	S.playermodedefault[#S.playermodedefault + 1] = "Display"
end
if S.normalizedplayermode == "Username" or S.normalizedplayermode == "Both" then
	S.playermodedefault[#S.playermodedefault + 1] = "Username"
end

S.watermarkplayermodecontrol = S.watermarksettingssection:AddRadio(
	"Player name",
	{ "Display", "Username" },
	S.playermodedefault,
	function(values, selected)
		selected = {}
		for _, value in ipairs(values or {}) do
			selected[value] = true
		end
		if selected.Display and selected.Username then
			S.watermarkconfig.PlayerMode = "Both"
		elseif selected.Username then
			S.watermarkconfig.PlayerMode = "Username"
		else
			S.watermarkconfig.PlayerMode = "Display"
		end
		S.updatewatermarklayout()
		S.saveuisettings()
	end,
	nil,
	true
)

S.updatewatermarklayout()

S.animationtoggle = S.interfaceflags:AddToggle("Animations", S.animationsenabled, function(value)
	S.animationsenabled = value == true

	if S.animationsenabled then
		if S.updatetopnavigationstate then S.updatetopnavigationstate(false) end
		if S.refreshhotkeylist then S.refreshhotkeylist() end
	end

	S.saveuisettings()
end)

S.interfaceflags2 = S.settingssection:AddRow(10, 24)

S.searchtoggle = S.interfaceflags2:AddToggle("Search", S.searchenabled, function(value)
	S.setsearchvisible(value, true)

	if not S.searchenabled then S.search.Text = "" end

	S.saveuisettings()
end)

S.setsearchvisible(S.searchenabled, false)

S.notificationtoggle = S.interfaceflags2:AddToggle(
	"Notifications",
	S.notificationsenabled,
	function(value)
		S.notificationsenabled = value
		S.saveuisettings()
	end
)

S.interfaceflags3 = S.settingssection:AddRow(10, 24)

S.hotkeylisttoggle = S.interfaceflags3:AddToggle(
	"Keybinds",
	S.savedsettings.hotkeyList == true or S.savedsettings.checkboxList == true,
	function(value)
		S.sethotkeylistvisible(value)
		S.saveuisettings()
	end
)

S.sethotkeylistvisible(S.savedsettings.hotkeyList == true or S.savedsettings.checkboxList == true)

S.topnavigationtoggle = S.interfaceflags3:AddToggle(
	"Top navigation",
	S.topnavigationenabled,
	function(value)
		S.topnavigationenabled = value == true
		if S.applytopnavigation then S.applytopnavigation(S.topnavigationenabled, true) end
		S.saveuisettings()
	end
)

S.interfaceflags4 = S.settingssection:AddRow(10, 29)

S.minimizebuttoncontrol = S.interfaceflags4:AddToggle(
	"Minimize button",
	S.savedsettings.minimizeButton ~= false,
	function(value)
		S.setminimizebuttonvisible(value, true)
		S.saveuisettings()
	end
)
S.setminimizebuttonvisible(S.savedsettings.minimizeButton ~= false, false)

S.keybindssection = S.createsection(S.settings, "left", "Keybinds", S.icons.keyboard)
S.keybindsrow = S.keybindssection:AddRow(10, 29)

S.menukeypicker = S.keybindsrow:AddKeyPicker("Window Open/Close", S.menukey, function(key)
	S.menukey = key
	S.refreshmenukeybinding()
	S.saveuisettings()
end)

S.keybindblacklistcontrol = S.keybindssection:AddMultiDropdown(
	"Blacklisted Keys",
	S.keybindblacklistoptions,
	S.getkeybindblacklistlabels(),
	function(values)
		S.setkeybindblacklist(values)
		if S.keybindblacklistcontrol then S.keybindblacklistcontrol:Set(S.getkeybindblacklistlabels(), false) end
		S.saveuisettings()
	end
)

S.keybindblacklistpicker = S.keybindssection:AddKeyPicker(
	"Add keybind",
	false,
	function(key, _5, labelvalue3, values)
		if not key then return end
		_5, labelvalue3 = S.ensurekeybindblacklistoption(key.Name)
		values = S.getkeybindblacklistlabels()
		if not table.find(values, labelvalue3) then values[#values + 1] = labelvalue3 end
		S.keybindblacklistcontrol:SetOptions(table.clone(S.keybindblacklistoptions))
		S.keybindblacklistcontrol:Set(values, true)
	end,
	nil,
	{
		AllowBlacklisted = true,
		AllowEscape = true,
		KeepDelete = true,
		HideLabel = false,
		FullWidth = false,
	}
)

S.windowsection = S.createsection(S.settings, "left", "Window", S.icons.sliders)

S.windowglowtoggle = S.windowsection:AddToggleColor(
	"Window glow",
	S.windowglowenabled,
	S.windowglowcolor,
	function(value)
		S.windowglowenabled = value == true
		S.applywindowglow()
		S.saveuisettings()
	end,
	function(color, alpha)
		S.windowglowcolor = color
		S.windowglowrenderalpha = math.clamp(tonumber(alpha) or 1, 0, 1)

		if
			not S.windowglowcolorpicker
			or (not S.windowglowcolorpicker.fading and not S.windowglowcolorpicker.rainbow)
		then
			S.windowglowalpha = S.windowglowcolorpicker and S.windowglowcolorpicker.alpha
				or S.windowglowrenderalpha

			S.saveuisettings()
		end

		S.applywindowglow()
	end
)

S.windowglowcolorpicker = S.windowglowtoggle.Color
S.windowglowcolorpicker:Set(S.windowglowcolor, S.windowglowalpha, false)
S.windowglowrenderalpha = S.windowglowcolorpicker:currentalpha()
S.applywindowglow()

S.windowglowintensitycontrol = S.windowsection:AddSlider(
	"Glow intensity",
	0,
	S.windowglowintensitymax,
	S.windowglowintensity,
	"%",
	function(value)
		S.windowglowintensity = value
		S.applywindowglow()
		S.saveuisettings()
	end
)

S.uitransparencycontrol = S.windowsection:AddSlider(
	"Transparency",
	0,
	90,
	S.initialtransparency,
	"%",
	function(value)
		S.applyuitransparency(value)
		S.saveuisettings()
	end
)

S.windowsection:AddSeparator()

S.windowglowsizecontrol = S.windowsection:AddSlider(
	"Glow Size",
	0,
	S.windowglowsizemax,
	S.windowglowsize,
	"px",
	function(value)
		S.windowglowsize = value
		S.applywindowglow()
		S.saveuisettings()
	end
)

S.applyuitransparency(S.initialtransparency)
S.watermarkglow = S.addshadow(S.watermark, "WatermarkGlow", 1, 12, 0, -2, S.theme.highlight, UDim2.fromOffset(0, 0), false)
if S.watermarkglow then S.bindtheme(S.watermarkglow, "Color", S.theme.highlight, "highlight") end
S.addpanelsettings(S.watermarksettingssection, S.panelthemes.Watermark, {
	{ "Background", "popup" }, { "Title", "text" }, { "Secondary text", "text3" },
	{ "Separator", "border" }, { "Accent", "highlight" },
}, S.watermarkglow)
S.addpanelsettings(S.keybindssection, S.panelthemes.Keybinds, {
	{ "Background", "popup" }, { "Main", "input" }, { "Highlight", "highlight" },
	{ "Accent", "white" }, { "Text", "text" }, { "Secondary text", "text3" },
	{ "Border", "border" }, { "Active indicator", "text2" },
})
S.loadpanelthemes(S.savedsettings.panelThemes)

S.themessection = S.createsection(S.settings, "right", "Appearance", S.icons.palette)

S.themepresets = {
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

S.themeoptions = {
	"Default",
	"Dark",
	"Violet",
	"Rose",
	"Mint",
	"Snow",
	"Pearl",
	"Ivory",
}

S.themecolors = {}

for name, preset in pairs(S.themepresets) do
	S.themecolors[name] = preset.accent
end

-- Neutral preview swatches keep Default and Dark visually distinct in the picker.
S.themecolors.Default = Color3.fromRGB(176, 178, 184)
S.themecolors.Dark = Color3.fromRGB(58, 60, 68)

S.themeselector = S.themessection:AddDropdown(
	"Theme",
	S.themeoptions,
	"Default",
	function(name, preset4, presetmain)
		preset4 = S.themepresets[name]

		if not preset4 then
			S.saveuisettings()
			return
		end

		S.applytheme(preset4.background, preset4.accent, 1, 1, preset4.font, 1, false)
		presetmain = preset4.main
			or S.buildtheme(preset4.background, preset4.accent, preset4.font, nil).main

		S.applymaincolor(presetmain, false)
		S.applymainalpha(1)
		S.applyhighlight(preset4.highlight or preset4.accent, 1, false)

		if S.maincolorpicker then S.maincolorpicker:Set(presetmain, 1, false) end
		if S.highlightpicker then S.highlightpicker:Set(preset4.highlight or preset4.accent, 1, false) end
		if S.accentpicker then S.accentpicker:Set(preset4.accent, 1, false) end

		if S.backgroundpicker then S.backgroundpicker:Set(preset4.background, 1, false) end

		if S.fontpicker then S.fontpicker:Set(preset4.font, 1, false) end

		if S.autobackgroundcolors then
			S.backgroundautobase = {
				background = preset4.background,
				accent = preset4.accent,
				font = preset4.font,
				backgroundAlpha = 1,
				accentAlpha = 1,
				fontAlpha = 1,
			}

			if S.backgroundpalette then
				S.applybackgroundautocolors(true)
			elseif S.backgroundimage and S.backgroundimage.Image ~= "" then
				task.spawn(function() S.samplebackgroundpalette(S.backgroundimage.Image) end)
			end
		end

		S.saveuisettings()
	end,
	nil,
	{
		dividers = {
			Snow = "Light themes",
		},
		colors = S.themecolors,
	}
)

S.maincolorpicker = S.themessection:AddColorPicker("Main color", S.theme.main, function(color, alpha)
	S.applymaincolor(color, false)
	S.applymainalpha(alpha)
	S.saveuisettings()
end)

S.maincolorpicker.propagate = S.maincolorpicker.callback
S.maincolorpicker.callback = nil
S.maincolorpicker.onpersist = S.saveuisettings
S.maincolorpicker:Set(S.theme.main, S.theme.mainAlpha, false)

S.highlightpicker = S.themessection:AddColorPicker("Highlight", S.theme.highlight, function(color, alpha)
	S.applyhighlight(color, alpha, false)
	S.saveuisettings()
end)
S.highlightpicker.propagate = S.highlightpicker.callback
S.highlightpicker.callback = nil
S.highlightpicker.onpersist = S.saveuisettings
S.highlightpicker:Set(S.theme.highlight, S.theme.highlightAlpha, false)

S.accentpicker = S.themessection:AddColorPicker("Accent", S.theme.white, function(color, alpha)
	if S.autobackgroundcolors and not S.loadingsettings then
		S.autobackgroundcolors = false
		S.backgroundautobase = nil
		if S.backgroundautocolorcontrol then S.backgroundautocolorcontrol:Set(false, false) end
	end
	S.applytheme(
		S.theme.window,
		color,
		S.theme.backgroundAlpha,
		alpha,
		S.theme.font,
		S.theme.fontAlpha
	)
	S.saveuisettings()
end)

S.accentpicker.propagate = S.accentpicker.callback
S.accentpicker.callback = nil
S.accentpicker.onpersist = S.saveuisettings

S.backgroundpicker = S.themessection:AddColorPicker(
	"Background",
	S.theme.window,
	function(color, alpha)
		if S.autobackgroundcolors and not S.loadingsettings then
			S.autobackgroundcolors = false
			S.backgroundautobase = nil
			if S.backgroundautocolorcontrol then S.backgroundautocolorcontrol:Set(false, false) end
		end
		S.applytheme(
			color,
			S.theme.white,
			alpha,
			S.theme.accentAlpha,
			S.theme.font,
			S.theme.fontAlpha
		)
		S.saveuisettings()
	end
)

S.backgroundpicker.propagate = S.backgroundpicker.callback
S.backgroundpicker.callback = nil
S.backgroundpicker.onpersist = S.saveuisettings

S.fontpicker = S.themessection:AddColorPicker("Font color", S.theme.font, function(color, alpha)
	if S.autobackgroundcolors and not S.loadingsettings then
		S.autobackgroundcolors = false
		S.backgroundautobase = nil
		if S.backgroundautocolorcontrol then S.backgroundautocolorcontrol:Set(false, false) end
	end
	S.applytheme(
		S.theme.window,
		S.theme.white,
		S.theme.backgroundAlpha,
		S.theme.accentAlpha,
		color,
		alpha
	)
	S.saveuisettings()
end)

S.fontpicker.propagate = S.fontpicker.callback
S.fontpicker.callback = nil
S.fontpicker.onpersist = S.saveuisettings

S.themefileinput = S.themessection:AddInput(
	"Theme name",
	S.selectedthemesave,
	"name",
	function(value) S.themefileinput.Text = S.sanitizefilename(value) end
)

S.themfileselector = S.themessection:AddDropdown("Saved themes", { "None" }, "None", function(name)
	if name ~= "None" then
		S.selectedthemesave = S.sanitizefilename(name)
		S.themefileinput.Text = S.selectedthemesave
		S.saveuisettings(true)
	end
end, nil, { searchable = true })

S.refreshthemefiles(S.selectedthemesave)

S.themefileactions = S.themessection:AddRow(8, 32)

S.themefileactions:AddButton("Load", function(name7, ok)
	name7 = S.themfileselector:Get()
	ok = S.loadthemefile(name7)
	S.notify(
		ok and "Loaded" or "Unavailable",
		ok and "Theme loaded." or "Select a saved theme.",
		2.4,
		nil,
		nil,
		S.icons.palette
	)
end)

S.themefileactions:AddButton("Save", function(ok)
	ok = S.savethemefile(S.themefileinput.Text)
	S.notify(
		ok and "Saved" or "Invalid name",
		ok and "Theme saved." or "Enter a valid theme name.",
		2.4,
		nil,
		nil,
		S.icons.palette
	)
end)

S.themessection:AddButton("Delete", function(name8, ok)
	name8 = S.themfileselector:Get()
	ok = S.deletethemefile(name8)
	S.notify(
		ok and "Deleted" or "Unavailable",
		ok and "Theme file deleted." or "Select a saved theme.",
		2.4,
		nil,
		nil,
		S.icons.wrench
	)
end)

S.backgroundimagesection =
	S.createsection(S.settings, "right", "Background Image", S.icons.wallpaper)

S.backgroundimageinput = S.backgroundimagesection:AddInput(
	"Source",
	S.backgroundimagesource,
	"URL, file path or asset id",
	function(value) S.backgroundimageinput.Text = S.trimbackgroundsource(value) end
)

S.backgroundimageopacitycontrol = S.backgroundimagesection:AddSlider(
	"Image opacity",
	0,
	100,
	S.backgroundimageopacity,
	"%",
	function(value)
		S.setbackgroundimageopacity(value, true)
		S.saveuisettings()
	end
)

S.backgroundimageblurcontrol = S.backgroundimagesection:AddSlider(
	"Image blur",
	0,
	S.backgroundimageblurmax,
	math.round(S.backgroundimageblur),
	" px",
	function(value, rounded)
		rounded = math.round(value)
		if S.backgroundimageblurcontrol and math.abs(value - rounded) > 0.001 then
			S.backgroundimageblurcontrol:Set(rounded, false)
		end
		S.setbackgroundimageblur(rounded, true)
		S.saveuisettings()
	end
)

S.backgroundimageoptions = S.backgroundimagesection:AddRow(8, 24)

S.backgroundexcludecontrol = S.backgroundimageoptions:AddToggle(
	"Exclude sidebar",
	S.backgroundexcludesidebar,
	function(value)
		S.setbackgroundexcludesidebar(value)
		S.saveuisettings()
	end
)

S.backgroundautocolorcontrol = nil

S.backgroundimageactions = S.backgroundimagesection:AddRow(8, 32)

S.backgroundapplytoken = 0

function S.applybackgroundsource(source, token)
	source = S.trimbackgroundsource(S.backgroundimageinput.Text)
	S.backgroundimageinput.Text = source

	S.backgroundapplytoken += 1
	token = S.backgroundapplytoken

	if source == "" then
		S.clearbackgroundimage(true)
		S.saveuisettings(true)
		return
	end

	task.spawn(function(ok)
		ok = S.loadbackgroundimage(source, true, false)
		if token ~= S.backgroundapplytoken then return end

		if ok then
			S.backgroundimageinput.Text = source
			S.saveuisettings(true)
		end
	end)
end

S.backgroundimageinput.FocusLost:Connect(function(enterpressed)
	if enterpressed then S.applybackgroundsource() end
end)

S.backgroundimageactions:AddButton("Apply", S.applybackgroundsource)

S.backgroundimageactions:AddButton("Clear", function()
	S.backgroundimageinput.Text = ""
	S.clearbackgroundimage(true)
	S.saveuisettings(true)
end)

S.savessection = S.createsection(S.settings, "right", "Configs", S.icons.wrench)

S.configinput = S.savessection:AddInput(
	"Config name",
	S.selectedconfig,
	"name",
	function(value) S.configinput.Text = S.sanitizefilename(value) end
)

S.configselector = S.savessection:AddDropdown("Saved configs", { "None" }, "None", function(name)
	if name ~= "None" then
		S.selectedconfig = S.sanitizefilename(name)
		S.configinput.Text = S.selectedconfig
		S.saveuisettings(true)
	end
end, nil, { searchable = true })

S.refreshconfigfiles(S.selectedconfig)

S.configactions = S.savessection:AddRow(8, 32)

S.configactions:AddButton("Load", function(name9, ok)
	name9 = S.configselector:Get()
	ok = S.loadconfigfile(name9, true)
	S.notify(
		ok and "Loaded" or "Unavailable",
		ok and "Configuration loaded." or "Select a saved config.",
		2.4,
		nil,
		nil,
		S.icons.settings
	)
end)

S.configactions:AddButton("Save", function(ok)
	ok = S.saveconfigfile(S.configinput.Text)
	S.notify(
		ok and "Saved" or "Invalid name",
		ok and "Configuration saved." or "Enter a valid config name.",
		2.4,
		nil,
		nil,
		S.icons.settings
	)
end)

S.savessection:AddButton("Delete", function(name10, ok)
	name10 = S.configselector:Get()
	ok = S.deleteconfigfile(name10)
	S.notify(
		ok and "Deleted" or "Unavailable",
		ok and "Configuration file deleted." or "Select a saved config.",
		2.4,
		nil,
		nil,
		S.icons.wrench
	)
end)

S.new("Frame", {
	Parent = S.savessection.body,
	Size = UDim2.new(1, 0, 0, 6),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
})

S.autosaveconfigcontrol = S.savessection:AddToggle(
	"Auto save",
	S.rawsavedsettings.autoSaveConfig == true,
	function(value, pending)
		if value ~= true then
			S.__blush_autosave_serial += 1
			pending = S.__blush_autosave_task
			if pending and coroutine.status(pending) == "suspended" then
				pcall(task.cancel, pending)
			end
			S.__blush_autosave_task = nil
		end
		S.saveuisettings(true)
	end
)

function S.applysaveduisettings(
	data,
	silent,
	wasloading,
	loadedtransparency,
	values,
	enabled,
	mode,
	values2,
	visible,
	loadedimagesource,
	loadedimageopacity,
	loadedimageblur,
	selectedtheme,
	loadedbackground,
	loadedaccent,
	loadedfont,
	loadedmain,
	loadedhighlight,
	loadedmainalpha,
	loadedhighlightalpha,
	loadedbackgroundalpha,
	loadedaccentalpha,
	loadedfontalpha
)
	if typeof(data) ~= "table" then return end

	wasloading = S.loadingsettings
	S.loadingsettings = true
	S.loadpanelthemes(data.panelThemes)

	loadedtransparency = math.clamp(tonumber(data.uiTransparency) or 0, 0, 90)

	if S.uitransparencycontrol then S.uitransparencycontrol:Set(loadedtransparency, false) end

	S.applyuitransparency(loadedtransparency)

	if S.watermarktoggle then S.watermarktoggle:Set(data.watermark == true, true) end

	if type(data.watermarkInfo) == "table" then
		S.watermarkconfig.Player = data.watermarkInfo.Player ~= false

		S.watermarkconfig.FPS = data.watermarkInfo.FPS ~= false

		S.watermarkconfig.Ping = data.watermarkInfo.Ping ~= false

		S.watermarkconfig.Time = data.watermarkInfo.Time ~= false
	S.watermarkconfig.Game = data.watermarkInfo.Game == true

		S.watermarkconfig.PlayerMode = S.normalizewatermarkplayermode(
			data.watermarkInfo.PlayerMode or S.watermarkconfig.PlayerMode
		)
	end

	if S.watermarkinfocontrol then
		values = {}

		for _, item in ipairs({ "Player", "Fps", "Ping", "Time", "Game" }) do
			enabled = item == "Fps" and S.watermarkconfig.FPS or S.watermarkconfig[item]

			if enabled then table.insert(values, item) end
		end

		S.watermarkinfocontrol:Set(values, false)
	end

	if S.watermarkplayermodecontrol then
		mode = S.normalizewatermarkplayermode(S.watermarkconfig.PlayerMode)
		values2 = {}
		if mode == "Display" or mode == "Both" then values2[#values2 + 1] = "Display" end
		if mode == "Username" or mode == "Both" then values2[#values2 + 1] = "Username" end
		S.watermarkplayermodecontrol:Set(values2, false)
	end

	S.updatewatermarklayout()

	if S.animationtoggle then S.animationtoggle:Set(data.animations ~= false, true) end

	if S.searchtoggle then S.searchtoggle:Set(data.searchCurrentPage ~= false, true) end

	if S.notificationtoggle then S.notificationtoggle:Set(data.notifications ~= false, true) end

	if S.hotkeylisttoggle then
		visible = data.hotkeyList == true or data.checkboxList == true

		S.hotkeylisttoggle:Set(visible, true)
		S.sethotkeylistvisible(visible)
	end

	if S.autosaveconfigcontrol and data.autoSaveConfig ~= nil then
		S.autosaveconfigcontrol:Set(data.autoSaveConfig == true, false)
	end

	if data.minimizeButton ~= nil then
		S.setminimizebuttonvisible(data.minimizeButton == true, true)

		if S.minimizebuttoncontrol then
			S.minimizebuttoncontrol:Set(S.windowminimizebuttonenabled, false)
		end
	end

	S.backgroundexcludesidebar = data.backgroundImageExcludeSidebar == true
	S.autobackgroundcolors = false
	S.topnavigationenabled = data.topNavigation == true

	if S.backgroundexcludecontrol then
		S.backgroundexcludecontrol:Set(S.backgroundexcludesidebar, false)
	end
	if S.backgroundautocolorcontrol then
		S.backgroundautocolorcontrol:Set(S.autobackgroundcolors, false)
	end
	if S.topnavigationtoggle then S.topnavigationtoggle:Set(S.topnavigationenabled, false) end

	S.windowglowenabled = data.windowGlow ~= false
	S.windowglowintensity =
		math.clamp(tonumber(data.windowGlowIntensity) or 16, 0, S.windowglowintensitymax)
	S.windowglowsize = math.clamp(tonumber(data.windowGlowSize) or 10, 0, S.windowglowsizemax)
	S.windowglowcolor = S.theme.white
	S.windowglowalpha = math.clamp(tonumber(data.windowGlowAlpha) or S.windowglowalpha or 1, 0, 1)
	S.windowglowrenderalpha = S.windowglowalpha

	if S.windowglowtoggle then S.windowglowtoggle:Set(S.windowglowenabled, false) end
	if S.windowglowintensitycontrol then
		S.windowglowintensitycontrol:Set(S.windowglowintensity, false)
	end
	if S.windowglowsizecontrol then S.windowglowsizecontrol:Set(S.windowglowsize, false) end
	if S.windowglowcolorpicker then
		S.windowglowcolorpicker:Set(S.windowglowcolor, S.windowglowalpha, false)

		S.windowglowrenderalpha = S.windowglowcolorpicker:currentalpha()
	end

	S.applywindowglow()
	S.setbackgroundexcludesidebar(S.backgroundexcludesidebar)
	if S.applytopnavigation then S.applytopnavigation(S.topnavigationenabled, false) end

	loadedimagesource = type(data.backgroundImageSource) == "string" and data.backgroundImageSource
		or ""
	loadedimageopacity = math.clamp(tonumber(data.backgroundImageOpacity) or 65, 0, 100)
	loadedimageblur =
		math.clamp(tonumber(data.backgroundImageBlur) or 0, 0, S.backgroundimageblurmax)

	S.backgroundimagesource = loadedimagesource
	S.setbackgroundimagemode("Crop")
	S.setbackgroundimageopacity(loadedimageopacity, false)
	S.setbackgroundimageblur(loadedimageblur, false)

	if S.backgroundimageinput then S.backgroundimageinput.Text = loadedimagesource end
	if S.backgroundimageopacitycontrol then
		S.backgroundimageopacitycontrol:Set(loadedimageopacity, false)
	end
	if S.backgroundimageblurcontrol then
		S.backgroundimageblurcontrol:Set(loadedimageblur, false)
	end

	S.setkeybindblacklist(
		type(data.keybindBlacklist) == "table" and data.keybindBlacklist
			or S.keybindblacklistdefaults
	)

	if S.keybindblacklistcontrol then
		S.keybindblacklistcontrol:Set(S.getkeybindblacklistlabels(), false)
	end

	if S.menukeypicker then
		S.menukeypicker:Set(S.keyfromname(data.menuKey) or Enum.KeyCode.RightShift, true)
	end

	selectedtheme = type(data.theme) == "string" and data.theme or "Default"

	if selectedtheme == "Monochrome" or selectedtheme == "OLED" or selectedtheme == "Black" then
		selectedtheme = "Default"
	elseif selectedtheme == "Graphite" then
		selectedtheme = "Dark"
	end

	if S.themepresets[selectedtheme] then
		S.themeselector:Set(selectedtheme, true)
	else
		S.themeselector:Set("Default", true)
	end

	loadedbackground = S.decodecolor(data.background) or S.theme.window
	loadedaccent = S.decodecolor(data.accent) or S.theme.white
	loadedfont = S.decodecolor(data.font) or S.theme.font
	loadedmain = S.decodecolor(data.main)
		or S.buildtheme(loadedbackground, loadedaccent, loadedfont, nil).main
	loadedhighlight = S.decodecolor(data.highlight) or loadedaccent
	loadedmainalpha = math.clamp(tonumber(data.mainAlpha) or 1, 0, 1)
	loadedhighlightalpha = math.clamp(tonumber(data.highlightAlpha) or 1, 0, 1)
	loadedbackgroundalpha = math.clamp(tonumber(data.backgroundAlpha) or 1, 0, 1)
	loadedaccentalpha = math.clamp(tonumber(data.accentAlpha) or 1, 0, 1)
	loadedfontalpha = math.clamp(tonumber(data.fontAlpha) or 1, 0, 1)

	S.applytheme(
		loadedbackground,
		loadedaccent,
		loadedbackgroundalpha,
		loadedaccentalpha,
		loadedfont,
		loadedfontalpha,
		false
	)

	S.applymaincolor(loadedmain, false)
	S.applymainalpha(loadedmainalpha)
	S.applyhighlight(loadedhighlight, loadedhighlightalpha, false)
	S.accentpicker:Set(loadedaccent, loadedaccentalpha, false)
	S.backgroundpicker:Set(loadedbackground, loadedbackgroundalpha, false)
	if S.maincolorpicker then S.maincolorpicker:Set(loadedmain, loadedmainalpha, false) end
	if S.highlightpicker then S.highlightpicker:Set(loadedhighlight, loadedhighlightalpha, false) end
	S.fontpicker:Set(loadedfont, loadedfontalpha, false)

	S.syncwindowglowcolor(false)

	if S.windowglowcolorpicker then
		S.windowglowcolorpicker:Set(S.theme.white, S.windowglowalpha, false)

		S.windowglowrenderalpha = S.windowglowcolorpicker:currentalpha()
	end

	S.syncwindowglowcolor(false)

	S.backgroundpalette = nil
	if loadedimagesource ~= "" then
		task.spawn(function() S.loadbackgroundimage(loadedimagesource, false, true) end)
	else
		S.clearbackgroundimage(false)
	end

	S.loadingsettings = wasloading

	if not silent then
		S.notify("Loaded", "Interface configuration loaded.", 2.5, nil, nil, S.icons.settings)
	end
end

S.savedtheme = "Default"

S.themeselector:Set("Default", false)

do
	S.preset = S.themepresets.Default

	S.applytheme(S.preset.background, S.preset.accent, 1, 1, S.preset.font, 1, false)
	S.applymaincolor(S.preset.main or S.buildtheme(S.preset.background, S.preset.accent, S.preset.font, nil).main, false)
	S.applymainalpha(1)
	S.applyhighlight(S.preset.highlight or S.preset.accent, 1, false)
	if S.maincolorpicker then S.maincolorpicker:Set(S.theme.main, 1, false) end
	if S.highlightpicker then S.highlightpicker:Set(S.theme.highlight, 1, false) end

	S.accentpicker:Set(S.preset.accent, 1, false)
	S.backgroundpicker:Set(S.preset.background, 1, false)
	S.fontpicker:Set(S.preset.font, 1, false)
end

if S.backgroundimagesource ~= "" then
	task.spawn(function() S.loadbackgroundimage(S.backgroundimagesource, false, true) end)
end

S.loadingsettings = false

S.__blush_visibility_busy = false
S.__blush_visibility_token = 0
S.__blush_windowvisible = true
S.__blush_fadeanimations = {}

function S.cancelreopenanimations()
	for _, animation in ipairs(S.__blush_reopenanimations or {}) do
		animation:Cancel()
	end

	S.__blush_reopenanimations = {}
end

function S.animatereopenbutton(
	show,
	token,
	normalbackground,
	normaltext,
	normalstroke,
	normalshadow,
	info,
	targets,
	primary,
	animation
)
	S.cancelreopenanimations()
	S.__blush_reopen_fading = true
	S.reopenbutton.Active = false

	normalbackground = S.effectivetransparency(0.04, "window")
	normaltext = S.effectivefontalpha(0)
	normalstroke = 0.62
	normalshadow = 0.58

	if show then
		S.reopengui.Enabled = true
		S.reopenbutton.BackgroundTransparency = 1
		S.reopenlabel.TextTransparency = 1
		S.reopenarrow.ImageTransparency = 1

		if S.reopenstroke then S.reopenstroke.Transparency = 1 end

		if S.reopenshadow then S.reopenshadow.Transparency = 1 end
	end

	info = S.dropti

	targets = {
		{ S.reopenbutton, { BackgroundTransparency = show and normalbackground or 1 } },
		{ S.reopenlabel, { TextTransparency = show and normaltext or 1 } },
	}

	if S.reopenstroke then
		targets[#targets + 1] = {
			S.reopenstroke,
			{ Transparency = show and normalstroke or 1 },
		}
	end

	if S.reopenshadow then
		targets[#targets + 1] = {
			S.reopenshadow,
			{ Transparency = show and normalshadow or 1 },
		}
	end

	if not S.animationsenabled then
		for _, entry in ipairs(targets) do
			if entry[1] and entry[1].Parent then
				for property, value in pairs(entry[2]) do
					entry[1][property] = value
				end
			end
		end

		S.__blush_reopen_fading = false
		if show then
			S.reopenbutton.Active = true
		else
			S.reopengui.Enabled = false
		end
		return
	end

	primary = nil
	for _, entry in ipairs(targets) do
		if entry[1] and entry[1].Parent then
			animation = S.tweenservice:Create(entry[1], info, entry[2])
			S.__blush_reopenanimations[#S.__blush_reopenanimations + 1] = animation
			primary = primary or animation
			animation:Play()
		end
	end

	if not primary then
		S.__blush_reopen_fading = false
		S.reopengui.Enabled = show
		S.reopenbutton.Active = show
		return
	end

	primary.Completed:Connect(function()
		if S.__blush_visibility_token ~= token then return end

		S.__blush_reopen_fading = false

		if show then
			S.reopenbutton.Active = true
		else
			S.reopengui.Enabled = false
		end
	end)
end

function S.cancelvisibilityanimations()
	for _, animation in ipairs(S.__blush_fadeanimations or {}) do
		animation:Cancel()
	end

	S.__blush_fadeanimations = {}
end

function S.setvisibilityrootsvisible(value)
	if S.shell and S.shell.Parent then S.shell.Visible = value end

	-- Popups opened from floating sections remain usable while the window is closed.

	-- Floating sections remain independently visible.
end

function S.playvisibilityfade(
	show,
	token,
	info,
	roots,
	extras,
	base,
	base2,
	object11,
	object12,
	primary,
	object13,
	target,
	animation,
	object14,
	target3,
	animation6,
	finish
)
	S.__blush_windowvisible = show

	if S.modalguard and S.modalguard.Parent then S.modalguard.Visible = show end

	if show then
		S.setvisibilityrootsvisible(true)
		S.animatereopenbutton(false, token)
	else
		S.reopengui.Enabled = false
	end

	S.cancelvisibilityanimations()

	info = S.dropti

	roots = {
		{ S.window, show and 0 or 1 },
	}

	extras = {}

	if S.windowstroke and S.windowstroke.Parent then
		extras[#extras + 1] = {
			S.windowstroke,
			show and 0.76 or 1,
		}
	end

	if S.windowshadow and S.windowshadow.Parent then
		base = S.windowshadowenabled
				and (S.windowshadow:GetAttribute("BlushBaseTransparency") or 0.40)
			or 1

		extras[#extras + 1] = {
			S.windowshadow,
			show and base or 1,
		}
	end

	if S.windowglow and S.windowglow.Parent then
		base2 = S.windowglowenabled
				and (S.windowglow:GetAttribute("BlushBaseTransparency") or S.windowglow.Transparency)
			or 1

		extras[#extras + 1] = {
			S.windowglow,
			show and base2 or 1,
		}
	end

	if not S.animationsenabled then
		for _, entry in ipairs(roots) do
			object11 = entry[1]
			if object11 and object11.Parent then object11.GroupTransparency = entry[2] end
		end

		for _, entry in ipairs(extras) do
			object12 = entry[1]
			if object12 and object12.Parent then object12.Transparency = entry[2] end
		end

		if show then
			S.setvisibilityrootsvisible(true)
		else
			S.setvisibilityrootsvisible(false)
			S.animatereopenbutton(true, token)
		end

		S.__blush_visibility_busy = false
		return
	end

	primary = nil

	for _, entry in ipairs(roots) do
		object13 = entry[1]
		target = entry[2]

		if object13 and object13.Parent then
			animation = S.tweenservice:Create(object13, info, { GroupTransparency = target })

			table.insert(S.__blush_fadeanimations, animation)
			primary = primary or animation
			animation:Play()
		end
	end

	for _, entry in ipairs(extras) do
		object14 = entry[1]
		target3 = entry[2]

		if object14 and object14.Parent then
			animation6 = S.tweenservice:Create(object14, info, { Transparency = target3 })

			table.insert(S.__blush_fadeanimations, animation6)
			primary = primary or animation6
			animation6:Play()
		end
	end

	finish = function(object15, object16)
		if S.__blush_visibility_token ~= token then return end

		for _, entry in ipairs(roots) do
			object15 = entry[1]
			if object15 and object15.Parent then object15.GroupTransparency = entry[2] end
		end

		for _, entry in ipairs(extras) do
			object16 = entry[1]
			if object16 and object16.Parent then object16.Transparency = entry[2] end
		end

		if show then
			S.setvisibilityrootsvisible(true)
		else
			S.setvisibilityrootsvisible(false)
			S.animatereopenbutton(true, token)
		end

		S.__blush_visibility_busy = false
		S.__blush_fadeanimations = {}
	end

	if primary then
		primary.Completed:Connect(finish)
	else
		finish()
	end
end

function S.requestvisibilitytoggle(target, show, token)
	show = target == nil and not S.__blush_windowvisible or target == true

	if show == S.__blush_windowvisible and not S.__blush_visibility_busy then return end

	S.__blush_visibility_busy = true
	S.__blush_visibility_token += 1

	token = S.__blush_visibility_token
	S.closepopup()
	S.closemodal()
	S.playvisibilityfade(show, token)
end

function S.refreshmenukeybinding()
	S.contextactionservice:UnbindAction("__blush_menu_key")

	if S.menukey ~= Enum.KeyCode.Tab then return end

	S.contextactionservice:BindActionAtPriority("__blush_menu_key", function(_, inputstate)
		if
			inputstate == Enum.UserInputState.Begin
			and not S.keypickercapturing
			and S.keypickersuppress ~= S.menukey
		then
			S.requestvisibilitytoggle()
		end

		return Enum.ContextActionResult.Sink
	end, false, Enum.ContextActionPriority.High.Value + 1000, Enum.KeyCode.Tab)
end

S.connect(S.uis.InputBegan, function(input)
	if
		S.menukey == Enum.KeyCode.Tab
		or S.keypickercapturing
		or S.bindingmatchesinput(S.keypickersuppress, input)
	then
		return
	end

	if S.bindingmatchesinput(S.menukey, input) then S.requestvisibilitytoggle() end
end)

S.refreshmenukeybinding()

-- search

function S.applysearch(query, sectionmatch, any, visible)
	if not S.currentpage then return end

	query = S.searchenabled and string.lower(S.search.Text) or ""

	for _, section in ipairs(S.currentpage.sections) do
		sectionmatch = query == "" or string.find(string.lower(section.name), query, 1, true) ~= nil

		any = false

		for _, control in ipairs(section.controls) do
			visible = query == ""
				or sectionmatch
				or string.find(control.name, query, 1, true) ~= nil

			control.row.Visible = visible

			if visible then any = true end
		end

		section.frame.Visible = query == "" or sectionmatch or any
	end

	S.currentpage:reflowall(true)
end

S.search:GetPropertyChangedSignal("Text"):Connect(S.applysearch)

-- navigation

S.__blush_reorderanimations = setmetatable({}, {
	__mode = "k",
})

function S.clearreorderanimation(button, data)
	data = S.__blush_reorderanimations[button]
	if not data then return end

	S.__blush_reorderanimations[button] = nil

	if data.animation then data.animation:Cancel() end

	if data.hidden then S.restorefromghost(data.hidden) end

	if data.ghost and data.ghost.Parent then data.ghost:Destroy() end
end

function S.animatereorder(oldpositions, items, skipbutton, animatebutton)
	animatebutton = function(button, oldposition, newposition, ghost, hidden, animation, finish)
		if button == skipbutton or not button or not button.Parent or not oldpositions[button] then
			return true
		end

		oldposition = oldpositions[button]
		newposition = button.AbsolutePosition

		if (newposition - oldposition).Magnitude <= 1 then return false end

		S.clearreorderanimation(button)

		ghost = S.makedragghost(button, 465)

		if not ghost then return true end

		ghost.Position = UDim2.fromOffset(
			oldposition.X - S.draglayer.AbsolutePosition.X,
			oldposition.Y - S.draglayer.AbsolutePosition.Y
		)

		hidden = S.hideforghost(button)

		animation = S.tween(ghost, {
			Position = UDim2.fromOffset(
				newposition.X - S.draglayer.AbsolutePosition.X,
				newposition.Y - S.draglayer.AbsolutePosition.Y
			),
		}, S.quart24)

		S.__blush_reorderanimations[button] = {
			ghost = ghost,
			hidden = hidden,
			animation = animation,
		}

		finish = function(current)
			current = S.__blush_reorderanimations[button]

			if not current or current.ghost ~= ghost then return end

			S.clearreorderanimation(button)
		end

		if animation then
			animation.Completed:Connect(finish)
		else
			finish()
		end

		return true
	end

	for _, button, iteration9 in S.scopediterator(2, ipairs(items or {})) do
		if not animatebutton(button) and button and button.Parent then
			iteration9.changed = nil
			iteration9.destroying = nil

			iteration9.cleanup = function()
				if iteration9.changed then
					iteration9.changed:Disconnect()
					iteration9.changed = nil
				end

				if iteration9.destroying then
					iteration9.destroying:Disconnect()
					iteration9.destroying = nil
				end
			end

			iteration9.changed = button
				:GetPropertyChangedSignal("AbsolutePosition")
				:Connect(function()
					if animatebutton(button) then iteration9.cleanup() end
				end)

			iteration9.destroying = button.Destroying:Connect(iteration9.cleanup)
		end
	end
end

function S.layoutnavcontent(button, textobject, iconobject, sub, textx)
	if iconobject and iconobject.Parent then
		iconobject.AnchorPoint = Vector2.new(0, 0.5)

		iconobject.Position = UDim2.new(0, sub and 11 or 14, 0.5, 0)
	end

	textx = nil

	if iconobject and iconobject.Parent then
		textx = sub and 35 or 43
	else
		textx = sub and 11 or 14
	end

	textobject.Position = UDim2.fromOffset(textx, 0)

	textobject.Size = UDim2.new(1, -textx - 8, 1, 0)
end

function S.navbutton(
	parentobject,
	name,
	asset,
	sub,
	height,
	button12,
	indicator,
	indicatorglow,
	iconobject,
	textobject
)
	height = sub and 30 or 40

	button12 = S.new("TextButton", {
		Parent = parentobject,

		Size = UDim2.new(1, 0, 0, height),

		BackgroundColor3 = S.theme.hover,

		BackgroundTransparency = 1,
		BorderSizePixel = 0,

		Text = "",
		AutoButtonColor = false,

		ZIndex = 13,
	}, { BackgroundColor3 = "hover" })

	S.corner(button12, sub and 7 or 8)

	indicator = nil
	indicatorglow = nil

	if not sub then
		indicator = S.new("Frame", {
			Name = "TabActiveIndicator",
			Parent = button12,

			AnchorPoint = Vector2.new(0, 0.5),

			Position = UDim2.new(0, 4, 0.5, 0),

			Size = UDim2.fromOffset(3, 20),

			BackgroundColor3 = S.theme.highlight,

			BackgroundTransparency = 1,
			BorderSizePixel = 0,

			ZIndex = 14,
		}, { BackgroundColor3 = "highlight" })

		S.corner(indicator, 999)
		S.bindtheme(indicator, "BackgroundColor3", S.theme.highlight, "highlight")
		indicator.BackgroundColor3 = S.theme.highlight

		indicatorglow = nil
	end

	iconobject = nil

	if asset ~= nil and tostring(asset) ~= "" then
		iconobject = S.image(button12, asset, sub and 15 or 19, S.theme.text3, 14)
	end

	textobject = S.label(button12, name, UDim2.new(1, 0, 1, 0), S.font, S.theme.text3)

	textobject.TextSize = sub and 16 or 17

	textobject.ZIndex = 14

	S.layoutnavcontent(button12, textobject, iconobject, sub)

	return button12, textobject, indicator, iconobject, indicatorglow
end

function S.setnaventryicon(entry, asset)
	if not entry or not entry.button or not entry.button.Parent then return nil end

	if entry.icon and entry.icon.Parent then entry.icon:Destroy() end

	entry.icon = nil

	if asset ~= nil and tostring(asset) ~= "" then
		entry.icon = S.image(
			entry.button,
			asset,
			entry.sub and 15 or 19,
			S.currentnav == entry.button and S.theme.text or S.theme.text3,
			14
		)
	end

	S.layoutnavcontent(entry.button, entry.text, entry.icon, entry.sub)

	S.setsidebarentrycompact(entry, S.sidebarcompact, entry.sub)

	return entry.icon
end

S.homebutton, S.hometext, S.homeindicator, S.homeicon, S.homeglow =
	S.navbutton(S.maincontent, "Home", S.icons.home)

S.combatbutton, S.combattext, S.combatindicator, S.combaticon, S.combatglow =
	S.navbutton(S.maincontent, "Combat", S.icons.combat)

S.subholder = S.new("Frame", {
	Parent = S.maincontent,

	Size = UDim2.new(1, 0, 0, 100),

	BackgroundTransparency = 1,
	ClipsDescendants = true,

	ZIndex = 13,
})

S.sublist = S.new("Frame", {
	Parent = S.subholder,

	Position = UDim2.fromOffset(18, 3),

	Size = UDim2.new(1, -22, 1, -6),

	BackgroundTransparency = 1,
	BorderSizePixel = 0,

	ZIndex = 14,
})

S.sublistlayout = S.list(S.sublist, 3)

S.mainbutton, S.maintext, S._, S.mainicon = S.navbutton(S.sublist, "Main", S.icons.target, true)

S.visualbutton, S.visualtext, S._, S.visualicon =
	S.navbutton(S.sublist, "Visuals", S.icons.visuals, true)

S.extrasbutton, S.extrastext, S._, S.extrasicon =
	S.navbutton(S.sublist, "Extras", S.icons.extras, true)

S.topnavigation = S.new("Frame", {
	Parent = S.header,
	Position = UDim2.fromOffset(0, 0),
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Visible = false,
	ZIndex = 18,
})

S.topprimarybutton = S.new("TextButton", {
	Parent = S.topnavigation,
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.fromOffset(21, 31),
	Size = UDim2.fromOffset(150, 38),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Text = "Combat",
	TextColor3 = S.theme.text,
	Font = S.bold,
	TextSize = 19,
	TextXAlignment = Enum.TextXAlignment.Left,
	AutoButtonColor = false,
	Active = true,
	ZIndex = 19,
}, { TextColor3 = "text" })

S.topsubholder = S.new("ScrollingFrame", {
	CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.X,
	ScrollingDirection = Enum.ScrollingDirection.X,
	ScrollBarThickness = 0,
	Parent = S.topnavigation,
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(0.5, -54, 0.5, 0),
	Size = UDim2.fromOffset(172, 40),
	BackgroundColor3 = S.theme.window,
	BackgroundTransparency = 0.03,
	BorderSizePixel = 0,
	Visible = true,
	ZIndex = 19,
}, { BackgroundColor3 = "window" })
S.corner(S.topsubholder, 999)
S.stroke(S.topsubholder, 0.58, S.theme.border, 1)
S.addshadow(
	S.topsubholder,
	"TopNavShadow",
	0.976,
	10,
	0,
	-1,
	Color3.fromRGB(0, 0, 0),
	UDim2.fromOffset(0, 2),
	false
)

S.new("UIPadding", {
	Parent = S.topsubholder,
	PaddingLeft = UDim.new(0, 3),
	PaddingRight = UDim.new(0, 3),
	PaddingTop = UDim.new(0, 4),
	PaddingBottom = UDim.new(0, 4),
})

S.topnavdivider = S.new("Frame", {
	Parent = S.topnavigation,
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, 0),
	Size = UDim2.new(1, -28, 0, 1),
	BackgroundColor3 = S.theme.border,
	BackgroundTransparency = 0.72,
	BorderSizePixel = 0,
	Visible = false,
	ZIndex = 19,
}, { BackgroundColor3 = "border" })

S.new("UIListLayout", {
	Parent = S.topsubholder,
	FillDirection = Enum.FillDirection.Horizontal,
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	VerticalAlignment = Enum.VerticalAlignment.Center,
	Padding = UDim.new(0, 1),
	SortOrder = Enum.SortOrder.LayoutOrder,
})

S.topsubentries = {}

function S.createtopsub(name, asset, order, button13, activepill, iconobject, textobject, data)
	button13 = S.new("TextButton", {
		Parent = S.topsubholder,
		Size = UDim2.fromOffset(40, 32),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		LayoutOrder = order,
		ClipsDescendants = false,
		ZIndex = 20,
	})

	activepill = S.new("Frame", {
		Parent = button13,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = S.theme.input,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 20,
	}, { BackgroundColor3 = "input" })
	S.corner(activepill, 999)

	iconobject = S.image(button13, asset, 17, S.theme.text3, 21)
	iconobject.AnchorPoint = Vector2.new(0.5, 0.5)
	iconobject.Position = UDim2.new(0.5, 0, 0.5, 0)

	textobject = S.label(button13, name, UDim2.new(1, -36, 1, 0), S.medium, S.theme.text)
	textobject.Position = UDim2.fromOffset(32, 0)
	textobject.TextSize = 15
	textobject.TextTransparency = 1
	S.setfontalphabase(textobject, "TextTransparency", 1)
	textobject.TextXAlignment = Enum.TextXAlignment.Left
	textobject.ZIndex = 21

	data = {
		pill = activepill,
		icon = iconobject,
		text = textobject,
		name = name,
	}
	S.topsubentries[button13] = data

	button13.MouseEnter:Connect(function()
		if data.text and data.text.TextTransparency < 0.99 then return end

		S.tween(
			iconobject,
			{ ImageColor3 = S.theme.text2 },
			S.hoverti,
			nil,
			{ ImageColor3 = "text2" }
		)
	end)

	button13.MouseLeave:Connect(function()
		if S.updatetopnavigationstate then S.updatetopnavigationstate(true) end
	end)

	return button13, iconobject, textobject
end

S.topmainbutton, S.topmainicon, S.topmaintext = S.createtopsub("Main", S.icons.target, 1)
S.topvisualbutton, S.topvisualicon, S.topvisualtext = S.createtopsub("Visuals", S.icons.visuals, 2)
S.topextrasbutton, S.topextrasicon, S.topextrastext = S.createtopsub("Extras", S.icons.extras, 3)

S.farmingbutton, S.farmingtext, S.farmingindicator, S.farmingicon, S.farmingglow =
	S.navbutton(S.maincontent, "Farming", S.icons.farming)

S.componentsbutton, S.componentstext, S.componentsindicator, S.componentsicon, S.componentsglow =
	S.navbutton(S.maincontent, "Components", S.icons.sliders)

function S.createsidebartabsectionobjects(name, header, textobject, arrow, group, content, layout)
	header = S.new("TextButton", {
		Parent = S.nav,
		Size = UDim2.new(1, 0, 0, 28),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 13,
	})

	textobject = S.label(header, name, UDim2.new(1, -30, 1, 0), S.medium, S.theme.text3)
	textobject.Position = UDim2.fromOffset(8, 0)
	textobject.TextSize = 14
	textobject.ZIndex = 14

	arrow = S.image(header, S.icons.down, 11, S.theme.text3, 14)
	arrow.AnchorPoint = Vector2.new(1, 0.5)
	arrow.Position = UDim2.new(1, -7, 0.5, 0)
	arrow.ImageTransparency = 0.18

	group = S.new("Frame", {
		Parent = S.nav,
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = 12,
	})

	content = S.new("Frame", {
		Parent = group,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 12,
	})

	layout = S.list(content, 3)
	S.registergradienttarget(header, textobject)

	return header, textobject, arrow, group, content, layout
end

S.otherheader, S.othertext, S.otherarrow, S.othergroup, S.othercontent, S.othercontentlayout =
	S.createsidebartabsectionobjects("Other")

S.othercategorycollapsed = false
S.otherheader.Visible = false

S.librarycustomtabsections = {}
S.librarytabsectionlookup = {}
S.libraryactivetabsection = nil

S.settingsbutton, S.settingstext, S.settingsindicator, S.settingsicon, S.settingsglow =
	S.navbutton(S.othercontent, "Settings", S.icons.settings)

function S.refreshsidegroups(
	animate,
	mainheight,
	otherheight,
	height,
	mainheight2,
	otherheight2,
	height3
)
	

	mainheight2 = S.maincategorycollapsed and 0 or S.maincontentlayout.AbsoluteContentSize.Y
	otherheight2 = S.othercategorycollapsed and 0 or S.othercontentlayout.AbsoluteContentSize.Y

	if animate then
		S.tween(S.maingroup, { Size = UDim2.new(1, 0, 0, mainheight2) }, S.tabti)
		S.tween(S.othergroup, { Size = UDim2.new(1, 0, 0, otherheight2) }, S.tabti)
	else
		S.maingroup.Size = UDim2.new(1, 0, 0, mainheight2)
		S.othergroup.Size = UDim2.new(1, 0, 0, otherheight2)
	end

	for _, sectiontab in ipairs(S.librarycustomtabsections or {}) do
		height3 = sectiontab.Collapsed and 0 or sectiontab.Layout.AbsoluteContentSize.Y

		if animate then
			S.tween(sectiontab.Group, { Size = UDim2.new(1, 0, 0, height3) }, S.tabti)
		else
			sectiontab.Group.Size = UDim2.new(1, 0, 0, height3)
		end
	end
end

S.maincontentlayout
	:GetPropertyChangedSignal("AbsoluteContentSize")
	:Connect(function() S.refreshsidegroups(false) end)
S.othercontentlayout
	:GetPropertyChangedSignal("AbsoluteContentSize")
	:Connect(function() S.refreshsidegroups(false) end)

S.category.Activated:Connect(function()
	

	S.maincategorycollapsed = not S.maincategorycollapsed
	S.tween(S.categoryarrow, { Rotation = S.maincategorycollapsed and -90 or 0 }, S.tabti)
	S.refreshsidegroups(true)
end)

S.otherheader.Activated:Connect(function()
	

	S.othercategorycollapsed = not S.othercategorycollapsed
	S.tween(S.otherarrow, { Rotation = S.othercategorycollapsed and -90 or 0 }, S.tabti)
	S.refreshsidegroups(true)
end)

function S.refreshlibrarytabsectionorders(offset)
	S.maingroup.LayoutOrder = 1

	for index, sectiontab in ipairs(S.librarycustomtabsections) do
		sectiontab.Header.LayoutOrder = index * 2
		sectiontab.Group.LayoutOrder = index * 2 + 1
	end

	offset = #S.librarycustomtabsections * 2
	S.otherheader.LayoutOrder = offset + 2
	S.othergroup.LayoutOrder = offset + 3
end

function S.createlibrarytabsection(
	name,
	key,
	existing,
	header,
	textobject,
	arrow,
	group,
	content,
	layout,
	sectiontab
)
	name = tostring(name or "Section")
	key = string.lower(name)

	if key == "main" then
		return {
			Name = S.categorytext.Text,
			Content = S.maincontent,
			Group = S.maingroup,
			Header = S.category,
			Builtin = true,
		}
	end

	if key == "other" then
		return {
			Name = S.othertext.Text,
			Content = S.othercontent,
			Group = S.othergroup,
			Header = S.otherheader,
			Builtin = true,
		}
	end

	existing = S.librarytabsectionlookup[key]
	if existing then return existing end

	header, textobject, arrow, group, content, layout = S.createsidebartabsectionobjects(name)
	sectiontab = {
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
		

		self.Collapsed = value == true
		S.tween(self.Arrow, { Rotation = self.Collapsed and -90 or 0 }, S.tabti)
		S.refreshsidegroups(animate ~= false)
	end

	function sectiontab:SetName(value, oldkey)
		oldkey = string.lower(self.Name)
		self.Name = tostring(value or self.Name)
		self.TextObject.Text = self.Name

		if S.librarytabsectionlookup[oldkey] == self then
			S.librarytabsectionlookup[oldkey] = nil
		end

		S.librarytabsectionlookup[string.lower(self.Name)] = self
	end

	function sectiontab:SetVisible(value, visible)
		visible = value ~= false
		self.Header.Visible = visible and not S.sidebarcompact
		self.Group.Visible = visible
		S.refreshsidegroups(false)
	end

	function sectiontab:SetGradient(value) return S.settextgradient(self.TextObject, value) end

	function sectiontab:SetRainbow(value) return S.settextrainbow(self.TextObject, value) end

	header.Activated:Connect(function() sectiontab:SetCollapsed(not sectiontab.Collapsed, true) end)

	layout
		:GetPropertyChangedSignal("AbsoluteContentSize")
		:Connect(function() S.refreshsidegroups(false) end)

	table.insert(S.librarycustomtabsections, sectiontab)
	S.librarytabsectionlookup[key] = sectiontab
	S.refreshlibrarytabsectionorders()
	S.refreshsidegroups(false)

	return sectiontab
end

S.refreshsidegroups(false)

S.naventries = {
	[S.homebutton] = {
		button = S.homebutton,
		sub = false,
		text = S.hometext,
		indicator = S.homeindicator,
		icon = S.homeicon,
		glow = S.homeglow,
	},

	[S.combatbutton] = {
		button = S.combatbutton,
		sub = false,
		text = S.combattext,
		indicator = S.combatindicator,
		icon = S.combaticon,
		glow = S.combatglow,
	},

	[S.farmingbutton] = {
		button = S.farmingbutton,
		sub = false,
		text = S.farmingtext,
		indicator = S.farmingindicator,
		icon = S.farmingicon,
		glow = S.farmingglow,
	},

	[S.componentsbutton] = {
		button = S.componentsbutton,
		sub = false,
		text = S.componentstext,
		indicator = S.componentsindicator,
		icon = S.componentsicon,
		glow = S.componentsglow,
	},

	[S.settingsbutton] = {
		button = S.settingsbutton,
		sub = false,
		text = S.settingstext,
		indicator = S.settingsindicator,
		icon = S.settingsicon,
		glow = S.settingsglow,
	},
}

S.subentries = {
	[S.mainbutton] = {
		button = S.mainbutton,
		sub = true,
		text = S.maintext,
		icon = S.mainicon,
	},

	[S.visualbutton] = {
		button = S.visualbutton,
		sub = true,
		text = S.visualtext,
		icon = S.visualicon,
	},

	[S.extrasbutton] = {
		button = S.extrasbutton,
		sub = true,
		text = S.extrastext,
		icon = S.extrasicon,
	},
}

function S.updatetopnavigationlayout(
	width,
	compact,
	left,
	right,
	available,
	searchvisible,
	searchwidth,
	searchinset,
	leftbound,
	rightbound,
	available2,
	holderwidth,
	center
)
	if not S.topnavigation or not S.topnavigation.Parent then return end

	width = S.header.AbsoluteSize.X
	compact = width > 0 and width < 560

	searchvisible = S.searchenabled and true
	searchwidth = searchvisible and (compact and 116 or 150) or 0
	searchinset = S.windowminimizebuttonenabled and 52 or (compact and 10 or 14)
	leftbound = compact and 112 or 162
	rightbound =
		math.max(leftbound + 190, width - searchinset - (searchvisible and searchwidth + 12 or 0))
	available2 = math.max(190, rightbound - leftbound)
	holderwidth = math.min(compact and 168 or 172, available2)
	center = leftbound + available2 * 0.5

	S.searchholder.Size = UDim2.fromOffset(searchwidth, 38)
	S.searchholder.Position = UDim2.new(1, -searchinset, 0.5, 0)

	S.topprimarybutton.Position = UDim2.fromOffset(compact and 12 or 14, 31)
	S.topprimarybutton.Size = UDim2.fromOffset(compact and 90 or 150, 38)
	S.topprimarybutton.TextSize = compact and 18 or 19

	S.topsubholder.Position = UDim2.fromOffset(math.round(center), 31)
	S.topsubholder.Size = UDim2.fromOffset(math.round(holderwidth), 40)
end

S.connect(S.header:GetPropertyChangedSignal("AbsoluteSize"), function()
	if S.topnavigationenabled then S.updatetopnavigationlayout() end
end)

function S.updatetopnavigationstate(
	animate,
	enabled,
	legacycombat,
	entry2,
	entries,
	data,
	active,
	width,
	iconcolor,
	textalpha,
	pillalpha,
	info,
	roottab,
	haschildren
)
	if not S.topnavigation then return end

	entry2 = S.naventries[S.currentnav]
	roottab = entry2 and entry2.tab
	haschildren = roottab and #roottab.SubTabs > 0
	enabled = (S.topnavigationenabled == true or haschildren) and S.currentnav ~= nil

	legacycombat = S.currentnav == S.combatbutton and S.combatbutton.Visible

	S.topnavigation.Visible = enabled
	S.breadcrumb.Visible = not enabled
	S.topnavdivider.Visible = enabled
	S.topprimarybutton.Visible = enabled
	S.topsubholder.Visible = enabled and (legacycombat or haschildren)
	for button, data in pairs(S.topsubentries) do
		button.Visible = data.tab and data.tab.ParentTab == roottab and not data.tab.Hidden or not data.tab and legacycombat
	end

	if not enabled then
		S.updateheadercontrols()
		return
	end

	entry2 = S.naventries[S.currentnav]

	S.topprimarybutton.Text = entry2 and entry2.text and entry2.text.Text
		or (S.currentpage and S.currentpage.primary)
		or "Navigation"

	S.updatetopnavigationlayout()

	if not legacycombat and not haschildren then return end

	entries = {
		{ button = S.topmainbutton, active = S.currentsub == S.mainbutton },
		{ button = S.topvisualbutton, active = S.currentsub == S.visualbutton },
		{ button = S.topextrasbutton, active = S.currentsub == S.extrasbutton },
	}

	if haschildren then
		entries = {}
		for _, child in ipairs(roottab.SubTabs) do
			if not child.Hidden then entries[#entries + 1] = { button = child.Button, active = S.currentpage == child.Page } end
		end
	end
	for _, entry in ipairs(entries) do
		data = S.topsubentries[entry.button]
		if data then
active = entry.active == true
			width = active and math.min(190, 44 + S.measuretext(data.text.Text, 15, S.medium, Vector2.new(500, 32)).X) or 38
			iconcolor = active and S.theme.text or S.theme.text3
			textalpha = active and 0 or 1
			pillalpha = active and 0.18 or 1
			info = S.tabti

			data.icon.AnchorPoint = active and Vector2.new(0, 0.5) or Vector2.new(0.5, 0.5)
			data.icon.Position = active and UDim2.fromOffset(12, 16)
				or UDim2.new(0.5, 0, 0.5, 0)

			if animate ~= false and S.animationsenabled then
				S.tween(entry.button, { Size = UDim2.fromOffset(width, 32) }, info)
				S.tween(data.pill, {
					BackgroundColor3 = S.theme.input,
					BackgroundTransparency = pillalpha,
				}, info, nil, { BackgroundColor3 = "input" })
				S.tween(data.icon, { ImageColor3 = iconcolor }, info)
				S.tween(data.text, {
					TextColor3 = S.theme.text,
					TextTransparency = textalpha,
				}, info, nil, { TextColor3 = "text" })
			else
				entry.button.Size = UDim2.fromOffset(width, 32)
				data.pill.BackgroundColor3 = S.theme.input
				data.pill.BackgroundTransparency = pillalpha
				data.icon.ImageColor3 = iconcolor
				S.syncbinding(data.text, "TextColor3", S.theme.text, "text")
				S.syncbinding(data.text, "TextTransparency", textalpha)
				data.text.TextColor3 = S.theme.text
				S.setfontalphabase(data.text, "TextTransparency", textalpha)
				data.text.TextTransparency = S.effectivefontalpha(textalpha)
			end
end
	end
end

function S.applytopnavigation(value, animate, width)
	S.topnavigationenabled = value == true

	

	-- Top navigation only replaces the Combat subtabs. Primary navigation stays in the sidebar.
	S.sidebar.Visible = true
		S.sidebardivider.Visible = true
		width = math.max(0, (S.sidebarwidth or 215) - 1)
		S.main.Position = UDim2.fromOffset(width, 0)
		S.main.Size = UDim2.new(1, -width, 1, 0)

	if S.topnavigationenabled then
		S.subholder.Size = UDim2.new(1, 0, 0, 0)
	elseif S.currentnav == S.combatbutton then
		S.subholder.Size = UDim2.new(1, 0, 0, 100)
	end

	S.updatebackgroundbounds()
	S.updatetopnavigationstate(animate ~= false)
end

function S.opentopmainmenu(position, actions, _6, popup, previousclose)
	if S.topprimarypopup and S.activepopup == S.topprimarypopup then
		S.closepopup()
		S.topprimarypopup = nil
		return
	end

	position = S.topprimarybutton.AbsolutePosition
		+ Vector2.new(0, S.topprimarybutton.AbsoluteSize.Y + 2)

	actions = {}

	if S.librarytaborder and #S.librarytaborder > 0 then
		for _, tab, iteration10 in S.scopediterator(2, ipairs(S.librarytaborder)) do
			iteration10.currenttab = tab

			if
				iteration10.currenttab.Button
				and iteration10.currenttab.Button.Parent
				and iteration10.currenttab.Button.Visible
			then
				iteration10.entry = S.naventries[iteration10.currenttab.Button]

				table.insert(actions, {
					Text = iteration10.currenttab.Name,
					Icon = iteration10.entry
							and iteration10.entry.icon
							and iteration10.entry.icon.Image
						or nil,
					Callback = function() iteration10.currenttab:Select() end,
				})
			end
		end

		if S.settingsbutton.Visible then
			table.insert(actions, {
				Text = S.settingstext.Text,
				Icon = S.settingsicon.Image,
				Callback = function()
					S.selectmain(S.settingsbutton)
					S.expandsubtabs(false)
					S.showpage("settings")
				end,
			})
		end
	else
		actions = {
			{
				Text = "Home",
				Icon = S.icons.home,
				Callback = function()
					S.selectmain(S.homebutton)
					S.expandsubtabs(false)
					S.showpage("home")
				end,
			},
			{
				Text = "Combat",
				Icon = S.icons.combat,
				Callback = function()
					S.selectmain(S.combatbutton)
					S.expandsubtabs(true)

					if not S.currentsub then S.selectsub(S.mainbutton) end

					if S.currentsub == S.visualbutton then
						S.showpage("combat_visuals")
					elseif S.currentsub == S.extrasbutton then
						S.showpage("combat_extras")
					else
						S.showpage("combat_main")
					end
				end,
			},
			{
				Text = "Farming",
				Icon = S.icons.farming,
				Callback = function()
					S.selectmain(S.farmingbutton)
					S.expandsubtabs(false)
					S.showpage("farming")
				end,
			},
			{
				Text = "Components",
				Icon = S.icons.sliders,
				Callback = function()
					S.selectmain(S.componentsbutton)
					S.expandsubtabs(false)
					S.showpage("components")
				end,
			},
			{
				Text = "Settings",
				Icon = S.icons.settings,
				Callback = function()
					S.selectmain(S.settingsbutton)
					S.expandsubtabs(false)
					S.showpage("settings")
				end,
			},
		}
	end

	_6, popup = S.opencontextmenu(position, actions)

	S.topprimarypopup = popup

	previousclose = popup and popup.onclose

	if popup then
		popup.onclose = function()
			if previousclose then previousclose() end

			if S.topprimarypopup == popup then S.topprimarypopup = nil end
		end
	end
end

-- primary navigation remains in the sidebar; top navigation is subtabs only
S.topmainbutton.Activated:Connect(function()
	S.selectmain(S.combatbutton)
	S.selectsub(S.mainbutton)
	S.expandsubtabs(true)
	S.showpage("combat_main")
end)
S.topvisualbutton.Activated:Connect(function()
	S.selectmain(S.combatbutton)
	S.selectsub(S.visualbutton)
	S.expandsubtabs(true)
	S.showpage("combat_visuals")
end)
S.topextrasbutton.Activated:Connect(function()
	S.selectmain(S.combatbutton)
	S.selectsub(S.extrasbutton)
	S.expandsubtabs(true)
	S.showpage("combat_extras")
end)

function S.naventrytween(entry, key, object, goals, previous, animation)
	previous = entry[key]
	if previous then previous:Cancel() end

	animation = S.tween(object, goals, S.tabti)
	entry[key] = animation

	if animation then
		animation.Completed:Connect(function()
			if entry[key] == animation then entry[key] = nil end
		end)
	end
end

function S.rendernaventry(button, sub, hovered, entry, active, textcolor, iconcolor)
	entry = sub and S.subentries[button] or S.naventries[button]
	if not entry then return end

	active = sub and S.currentsub == button or (not sub and S.currentnav == button)

	if active and not sub then
		for otherbutton, otherentry, iteration11 in S.scopediterator(2, pairs(S.naventries or {})) do
			if otherbutton ~= button and otherentry.indicator and otherentry.indicator.Parent then
				iteration11.previous = otherentry.indicatoranimation
				if iteration11.previous then
					iteration11.previous:Cancel()
					otherentry.indicatoranimation = nil
				end
				otherentry.indicator.BackgroundTransparency = 1
			end
		end
	end

	textcolor = (active or hovered) and S.theme.text or S.theme.text3
	iconcolor = active and (sub and S.theme.text2 or S.theme.text)
		or (hovered and (sub and S.theme.text2 or S.theme.text) or S.theme.text3)

	S.naventrytween(entry, "textanimation", entry.text, { TextColor3 = textcolor })
	if entry.icon then
		S.naventrytween(entry, "iconanimation", entry.icon, { ImageColor3 = iconcolor })
	end

	if not sub and entry.indicator then
		S.naventrytween(
			entry,
			"indicatoranimation",
			entry.indicator,
			{ BackgroundTransparency = active and 0 or 1 }
		)

		if entry.glow then
			S.naventrytween(
				entry,
				"glowanimation",
				entry.glow,
				{ Transparency = active and 0.68 or 1 }
			)
		end
	end
end

function S.bindnavhover(button, sub)
	button.MouseEnter:Connect(function() S.rendernaventry(button, sub, true) end)

	button.MouseLeave:Connect(function() S.rendernaventry(button, sub, false) end)
end

S.bindnavhover(S.homebutton, false)
S.bindnavhover(S.combatbutton, false)
S.bindnavhover(S.farmingbutton, false)
S.bindnavhover(S.componentsbutton, false)
S.bindnavhover(S.settingsbutton, false)

S.bindnavhover(S.mainbutton, true)
S.bindnavhover(S.visualbutton, true)
S.bindnavhover(S.extrasbutton, true)

function S.selectmain(button, previous)
	previous = S.currentnav
	S.currentnav = button

	if previous and previous ~= button then S.rendernaventry(previous, false, false) end

	S.rendernaventry(button, false, false)

	if S.updatetopnavigationstate then S.updatetopnavigationstate(true) end
end

function S.selectsub(button, previous)
	previous = S.currentsub
	S.currentsub = button

	if previous and previous ~= button then S.rendernaventry(previous, true, false) end

	S.rendernaventry(button, true, false)

	if S.updatetopnavigationstate then S.updatetopnavigationstate(true) end
end

function S.expandsubtabs(value, height, height4)
	

	height4 = value and 100 or 0
	if S.topnavigationenabled then height4 = 0 end

	S.tween(S.subholder, { Size = UDim2.new(1, 0, 0, height4) }, S.tabti)

	if S.updatetopnavigationstate then S.updatetopnavigationstate() end
end

S.mainnavorder = {
	S.homebutton,
	S.combatbutton,
	S.farmingbutton,
	S.componentsbutton,
}

S.subnavorder = {
	S.mainbutton,
	S.visualbutton,
	S.extrasbutton,
}

S.navtabdrag = nil

function S.applynavorder()
	for index, button in ipairs(S.mainnavorder) do
		button.LayoutOrder = index * 10
		if button == S.combatbutton then S.subholder.LayoutOrder = index * 10 + 1 end
	end

	for index, button in ipairs(S.subnavorder) do
		button.LayoutOrder = index
	end

	S.refreshlibrarytabsectionorders()
	S.settingsbutton.LayoutOrder = 1
end

function S.bindnavdrag(button, ordertable, applyorder)
	button.InputBegan:Connect(function(input)
		

		if
			input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch
		then
			return
		end

		S.navtabdrag = {
			button = button,
			order = ordertable,
			apply = applyorder,
			input = input,
			start = S.point(input),
			started = false,
		}
	end)
end

S.bindnavdrag(S.homebutton, S.mainnavorder)
S.bindnavdrag(S.combatbutton, S.mainnavorder)
S.bindnavdrag(S.farmingbutton, S.mainnavorder)
S.bindnavdrag(S.componentsbutton, S.mainnavorder)

S.bindnavdrag(S.mainbutton, S.subnavorder)
S.bindnavdrag(S.visualbutton, S.subnavorder)
S.bindnavdrag(S.extrasbutton, S.subnavorder)

S.applynavorder()

S.connect(
	S.uis.InputChanged,
	function(
		input,
		ismouse,
		istouch,
		current,
		root,
		filtered,
		targetindex,
		center,
		oldindex,
		oldpositions
	)
		if not S.navtabdrag then return end

		ismouse = input.UserInputType == Enum.UserInputType.MouseMovement
		istouch = input.UserInputType == Enum.UserInputType.Touch and input == S.navtabdrag.input

		if not ismouse and not istouch then return end

		current = S.point(input)
		if not S.navtabdrag.started and (current - S.navtabdrag.start).Magnitude >= 7 then
			S.navtabdrag.started = true
			S.nav.ScrollingEnabled = false
			S.navtabdrag.button:SetAttribute("BlushDragSuppress", true)
			S.navtabdrag.grab = current - S.navtabdrag.button.AbsolutePosition
			S.navtabdrag.ghost, S.navtabdrag.ghostclone, S.navtabdrag.ghostscale =
				S.makedragghost(S.navtabdrag.button, 470)
			S.navtabdrag.hidden = S.hideforghost(S.navtabdrag.button)
		end

		if not S.navtabdrag.started then return end

		if S.navtabdrag.ghost and S.navtabdrag.ghost.Parent then
			root = S.draglayer.AbsolutePosition
			S.navtabdrag.ghost.Position = UDim2.fromOffset(
				current.X - S.navtabdrag.grab.X - root.X,
				current.Y - S.navtabdrag.grab.Y - root.Y
			)
		end

		filtered = {}
		for _, button in ipairs(S.navtabdrag.order) do
			if button ~= S.navtabdrag.button then table.insert(filtered, button) end
		end

		targetindex = #filtered + 1
		for index, other in ipairs(filtered) do
			center = other.AbsolutePosition.Y + other.AbsoluteSize.Y * 0.5
			if current.Y < center then
				targetindex = index
				break
			end
		end

		oldindex = table.find(S.navtabdrag.order, S.navtabdrag.button)
		if oldindex and oldindex ~= targetindex then
			oldpositions = {}

			for _, other in ipairs(S.navtabdrag.order) do
				if other and other.Parent then oldpositions[other] = other.AbsolutePosition end
			end

			table.remove(S.navtabdrag.order, oldindex)
			targetindex = math.clamp(targetindex, 1, #S.navtabdrag.order + 1)
			table.insert(S.navtabdrag.order, targetindex, S.navtabdrag.button)

			if S.navtabdrag.apply then
				S.navtabdrag.apply()
			else
				S.applynavorder()
			end

			S.animatereorder(oldpositions, S.navtabdrag.order, S.navtabdrag.button)
		end
	end
)

S.connect(S.uis.InputEnded, function(input, drag, target, finished, finish, animation)
	if not S.navtabdrag then return end

	if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input ~= S.navtabdrag.input then
		return
	end

	drag = S.navtabdrag
	S.navtabdrag = nil

	if not drag.started then return end

	target = drag.button.AbsolutePosition - S.draglayer.AbsolutePosition
	finished = false
	finish = function()
		if finished then return end
		finished = true
		S.nav.ScrollingEnabled = true
		S.restorefromghost(drag.hidden)
		if drag.ghost and drag.ghost.Parent then drag.ghost:Destroy() end
		if drag.button and drag.button.Parent then
			drag.button:SetAttribute("BlushDragSuppress", nil)
		end
	end

	if drag.ghost and drag.ghost.Parent then
		animation =
			S.tween(drag.ghost, { Position = UDim2.fromOffset(target.X, target.Y) }, S.quart24)
		if animation then
			animation.Completed:Connect(finish)
		else
			finish()
		end
	else
		finish()
	end
end)

S.homebutton.Activated:Connect(function()
	if S.homebutton:GetAttribute("BlushDragSuppress") then return end

	S.selectmain(S.homebutton)

	S.expandsubtabs(false)

	S.showpage("home")
end)

S.combatbutton.Activated:Connect(function()
	if S.combatbutton:GetAttribute("BlushDragSuppress") then return end

	S.selectmain(S.combatbutton)

	S.expandsubtabs(true)

	if not S.currentsub then S.selectsub(S.mainbutton) end

	if S.currentsub == S.visualbutton then
		S.showpage("combat_visuals")
	elseif S.currentsub == S.extrasbutton then
		S.showpage("combat_extras")
	else
		S.showpage("combat_main")
	end
end)

S.mainbutton.Activated:Connect(function()
	if S.mainbutton:GetAttribute("BlushDragSuppress") then return end

	S.selectmain(S.combatbutton)

	S.selectsub(S.mainbutton)

	S.showpage("combat_main")
end)

S.visualbutton.Activated:Connect(function()
	if S.visualbutton:GetAttribute("BlushDragSuppress") then return end

	S.selectmain(S.combatbutton)

	S.selectsub(S.visualbutton)

	S.showpage("combat_visuals")
end)

S.extrasbutton.Activated:Connect(function()
	if S.extrasbutton:GetAttribute("BlushDragSuppress") then return end

	S.selectmain(S.combatbutton)

	S.selectsub(S.extrasbutton)

	S.showpage("combat_extras")
end)

S.farmingbutton.Activated:Connect(function()
	if S.farmingbutton:GetAttribute("BlushDragSuppress") then return end

	S.selectmain(S.farmingbutton)

	S.expandsubtabs(false)

	S.showpage("farming")
end)

S.componentsbutton.Activated:Connect(function()
	if S.componentsbutton:GetAttribute("BlushDragSuppress") then return end

	S.selectmain(S.componentsbutton)

	S.expandsubtabs(false)

	S.showpage("components")
end)

S.settingsbutton.Activated:Connect(function()
	S.selectmain(S.settingsbutton)

	S.expandsubtabs(false)

	S.showpage("settings")
end)

S.applytopnavigation(S.topnavigationenabled, false)



-- footer

S.rawnew("Frame", {
	Parent = S.sidebar,
	Position = UDim2.new(0, 0, 1, -72),
	Size = UDim2.new(1, 0, 0, 72),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ZIndex = 11,
})

S.footerdivider = S.new("Frame", {
	Parent = S.sidebar,

	Position = UDim2.new(0, 14, 1, -72),

	Size = UDim2.new(1, -28, 0, 1),

	BackgroundColor3 = S.theme.border,

	BackgroundTransparency = 0.45,

	BorderSizePixel = 0,

	ZIndex = 12,
}, { BackgroundColor3 = "border" })

S.footeravatar = S.new("ImageLabel", {
	Parent = S.sidebar,

	Position = UDim2.new(0, 18, 1, -58),

	Size = UDim2.fromOffset(38, 38),

	BackgroundTransparency = 1,

	BorderSizePixel = 0,

	Image = S.thumbnail,

	ZIndex = 12,
})

S.corner(S.footeravatar, 999)

S.footername = S.label(S.sidebar, S.player.DisplayName, UDim2.fromOffset(135, 19), S.medium)

S.footername.Position = UDim2.new(0, 66, 1, -56)

S.footername.TextSize = 16
S.footername.ZIndex = 12

S.footername.TextTruncate = Enum.TextTruncate.AtEnd

S.footerusername =
	S.label(S.sidebar, "@" .. S.player.Name, UDim2.fromOffset(135, 18), S.font, S.theme.text3)

S.footerusername.Position = UDim2.new(0, 66, 1, -35)

S.footerusername.TextSize = 15
S.footerusername.ZIndex = 12

S.footerusername.TextTruncate = Enum.TextTruncate.AtEnd

S.sidebarresizehandle = S.new("TextButton", {
	Parent = S.window,
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.fromOffset(S.sidebarwidth - 1, 0),
	Size = UDim2.new(0, 10, 1, 0),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Text = "",
	AutoButtonColor = false,
	Active = true,
	ZIndex = 90,
})

S.sidebarresizeaccent = S.new("Frame", {
	Parent = S.sidebarresizehandle,
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.new(0, 1, 1, -24),
	BackgroundColor3 = S.theme.white,
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ZIndex = 91,
}, { BackgroundColor3 = "white" })
S.corner(S.sidebarresizeaccent, 999)
S.bindtheme(S.sidebarresizeaccent, "BackgroundColor3", S.theme.white, "white")

function S.setsidebarentrycompact(entry, compact, sub)
	if not entry then return end

	if entry.text then entry.text.Visible = not compact end

	if entry.icon then
		entry.icon.AnchorPoint = compact and Vector2.new(0.5, 0.5) or Vector2.new(0, 0.5)
		entry.icon.Size = UDim2.fromOffset(
			compact and (sub and 19 or 23) or (sub and 15 or 19),
			compact and (sub and 19 or 23) or (sub and 15 or 19)
		)
		entry.icon.Position = compact and UDim2.new(0.5, 1, 0.5, 0)
			or UDim2.new(0, sub and 11 or 14, 0.5, 0)
	end
end

function S.applysidebarlayout(width, animate, mainoffset, info, otheravailable, previouscompact, liveresize)
	previouscompact = S.sidebarcompact
	width = math.clamp(
		math.floor(tonumber(width) or S.sidebarwidth),
		S.sidebarminwidth,
		S.sidebarmaxwidth
	)

	S.sidebarwidth = width
	S.sidebarcompact = width <= S.sidebarcompactthreshold
	liveresize = S.sidebarresize ~= nil and animate ~= true

	mainoffset = width - 1
	info = S.hoverti

	if animate == true and S.animationsenabled then
		S.tween(S.sidebar, {
			Size = UDim2.new(0, width, 1, 0),
		}, info)

		S.tween(S.main, {
			Position = UDim2.fromOffset(mainoffset, 0),
			Size = UDim2.new(1, -mainoffset, 1, 0),
		}, info)

		S.tween(S.sidebardivider, {
			Position = UDim2.fromOffset(mainoffset, 0),
		}, info)

		S.tween(S.sidebarresizehandle, {
			Position = UDim2.fromOffset(mainoffset, 0),
		}, info)
	else
		S.sidebar.Size = UDim2.new(0, width, 1, 0)
		S.main.Position = UDim2.fromOffset(mainoffset, 0)
		S.main.Size = UDim2.new(1, -mainoffset, 1, 0)
		S.sidebardivider.Position = UDim2.fromOffset(mainoffset, 0)
		S.sidebarresizehandle.Position = UDim2.fromOffset(mainoffset, 0)
	end

	if liveresize and previouscompact == S.sidebarcompact then
		if S.sidebarcompact and S.avat.Visible and S.avat.Image ~= "" then
			S.avat.Position = UDim2.fromOffset(math.floor(width * 0.5) + 1, 45)
		end
		if S.backgroundexcludesidebar then S.updatebackgroundbounds() end
		return
	end

	S.brand.Visible = not S.sidebarcompact
	S.subtitle.Visible = not S.sidebarcompact
	S.subtitledivider.Visible = not S.sidebarcompact
	S.username.Visible = not S.sidebarcompact

	S.category.Visible = false

	S.footername.Visible = not S.sidebarcompact
	S.footerusername.Visible = not S.sidebarcompact

	S.avat.Position = S.sidebarcompact and UDim2.fromOffset(math.floor(width * 0.5) + 1, 45)
		or S.avat.Position

	S.footeravatar.AnchorPoint = S.sidebarcompact and Vector2.new(0.5, 0) or Vector2.zero

	S.footeravatar.Position = S.sidebarcompact and UDim2.new(0.5, 0, 1, -58)
		or UDim2.new(0, 18, 1, -58)

	S.footerdivider.Position = S.sidebarcompact and UDim2.new(0, 10, 1, -72)
		or UDim2.new(0, 14, 1, -72)

	S.footerdivider.Size = S.sidebarcompact and UDim2.new(1, -20, 0, 1) or UDim2.new(1, -28, 0, 1)

	S.nav.Position = S.sidebarcompact and UDim2.fromOffset(10, 82) or UDim2.fromOffset(14, 92)

	S.nav.Size = S.sidebarcompact and UDim2.new(1, -20, 1, -154) or UDim2.new(1, -28, 1, -164)

	S.sublist.Position = S.sidebarcompact and UDim2.fromOffset(0, 3) or UDim2.fromOffset(18, 3)

	S.sublist.Size = S.sidebarcompact and UDim2.new(1, 0, 1, -6) or UDim2.new(1, -22, 1, -6)

	for _, entry in pairs(S.naventries or {}) do
		S.setsidebarentrycompact(entry, S.sidebarcompact, false)
	end

	for _, entry in pairs(S.subentries or {}) do
		S.setsidebarentrycompact(entry, S.sidebarcompact, true)
	end

	otheravailable = S.settingsbutton.Visible

	if not otheravailable then
		for _, child in ipairs(S.othercontent:GetChildren()) do
			if child:IsA("GuiObject") and child ~= S.settingsbutton and child.Visible then
				otheravailable = true
				break
			end
		end
	end

	S.otherheader.Visible = false

	for _, sectiontab in ipairs(S.librarycustomtabsections or {}) do
		sectiontab.Header.Visible = not S.sidebarcompact
	end

	S.updatebrandlayout()

	if S.backgroundexcludesidebar then S.updatebackgroundbounds() end

	if S.topnavigationenabled then S.updatetopnavigationlayout() end
end

S.sidebarresizehandle.MouseEnter:Connect(
	function()
		S.tween(S.sidebarresizeaccent, {
			BackgroundTransparency = 0.84,
		}, S.hoverti)
	end
)

S.sidebarresizehandle.MouseLeave:Connect(function()
	if not S.sidebarresize then
		S.tween(S.sidebarresizeaccent, {
			BackgroundTransparency = 1,
		}, S.hoverti)
	end
end)

S.sidebarresizehandle.InputBegan:Connect(function(input, now)
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end

	now = os.clock()

	if now - S.sidebarresizelasttap <= 0.30 then
		S.sidebarresizelasttap = 0
		S.sidebarresize = nil
		S.applysidebarlayout(215, true)
		return
	end

	S.sidebarresizelasttap = now

	if not S.acquireinteraction("sidebarresize", input) then return end

	S.closepopup()

	S.__blush_nextsidebarresize = 0
	S.sidebarresize = {
		input = input,
		start = S.point(input),
		width = S.sidebarwidth,
		current = S.point(input),
	}

	S.ensureinteractionrenderloop()
	S.sidebarresizeaccent.BackgroundTransparency = 0.68
end)

S.applysidebarlayout(S.sidebarwidth, false)

-- dragging

S.lasttap = 0

function S.beginwindowdrag(input, allowdouble, deferpopup, start, now, targetposition)
	if not S.windowdragenabled then return end

	if S.windowdrag then return end

	if not S.acquireinteraction("windowdrag", input) then return end

	start = S.point(input)

	

	if
		S.closebutton
		and S.closebutton.Parent
		and S.windowminimizebuttonenabled
		and S.inside(S.closebutton, start)
	then
		S.releaseinteraction(input)
		return
	end

	if allowdouble
		and true
		and not (S.searchenabled and S.inside(S.searchholder, start)) then
now = os.clock()

		if now - S.lasttap <= 0.28 then
			S.lasttap = 0
			targetposition = S.centeredwindowposition(
				Vector2.new(S.shell.Size.X.Offset, S.shell.Size.Y.Offset)
			)

			if S.animationsenabled then
				S.tween(S.shell, { Position = targetposition }, S.quart26)
			else
				S.shell.Position = targetposition
			end

			S.releaseinteraction(input)
			return
		end

		S.lasttap = now
end

	if not deferpopup then S.closepopup() end

	S.windowdrag = {
		input = input,

		start = start,
		current = start,

		startposition = S.shell.Position,

		search = S.searchenabled and S.inside(S.searchholder, start),

		moved = false,
		deferpopup = deferpopup == true,
	}

	S.ensureinteractionrenderloop()
end

function S.bindwindowdrag(object, allowdouble, exclude)
	object.InputBegan:Connect(function(input)
		if
			input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch
		then
			return
		end

		if exclude and exclude.Parent and exclude.Visible and S.inside(exclude, S.point(input)) then
			return
		end

		S.beginwindowdrag(input, allowdouble, false)
	end)
end

S.bindwindowdrag(S.header, true, S.topprimarybutton)

S.bindwindowdrag(S.breadcrumb, true)

S.bindwindowdrag(S.searchholder, false)

S.bindwindowdrag(S.search, false)

S.bindwindowdrag(S.sideheaderdrag, true)

S.topprimarybutton.InputBegan:Connect(function(input)
	if
		not S.topnavigationenabled
		or (
			input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch
		)
	then
		return
	end

	S.topprimarygesture = {
		input = input,
		start = S.point(input),
	}

	S.beginwindowdrag(input, false, true)

	if not S.windowdrag or S.windowdrag.input ~= input then S.topprimarygesture = nil end
end)

S.watermarkdragarea.InputBegan:Connect(function(input)
	if
		input.UserInputType ~= Enum.UserInputType.MouseButton1
		and input.UserInputType ~= Enum.UserInputType.Touch
	then
		return
	end

	if not S.acquireinteraction("watermarkdrag", input) then return end

	S.closepopup()

	S.watermarkdrag = {
		input = input,

		start = S.point(input),
		current = S.point(input),

		startposition = S.watermark.Position,
	}

	S.ensureinteractionrenderloop()
end)

S.resizehandle.InputBegan:Connect(
	function(input, now, animation, finishreset, completed, scale, startpoint)
		if not S.windowresizeenabled then return end

		if
			input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch
		then
			return
		end

		now = os.clock()
		if now - S.lastresizetap <= 0.3 then
			S.lastresizetap = 0
			S.windowresize = nil

			animation = S.tween(S.shell, {
				Size = UDim2.fromOffset(S.originalwindowsize.X, S.originalwindowsize.Y),
			}, S.quart24)

			finishreset = function()
				if S.shell and S.shell.Parent and S.currentpage then
					S.currentpage:reflowall(false)
				end
			end

			if animation then
				completed = nil
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

		S.lastresizetap = now

		if not S.acquireinteraction("windowresize", input) then return end

		S.closepopup()

		startpoint = S.point(input)

		S.__blush_nextwindowresize = 0
		S.windowresize = {
			input = input,
			start = startpoint,
			current = startpoint,
			startsize = Vector2.new(S.shell.Size.X.Offset, S.shell.Size.Y.Offset),
			startabsolute = S.shell.AbsolutePosition,
			startposition = S.shell.Position,
			lastwidth = S.shell.Size.X.Offset,
			lastheight = S.shell.Size.Y.Offset,
		}

		S.ensureinteractionrenderloop()
	end
)

function S.matches(drag, input)
	if not drag then return false end

	if drag.input.UserInputType == Enum.UserInputType.MouseButton1 then
		return input.UserInputType == Enum.UserInputType.MouseMovement
	end

	return input == drag.input
end

function S.snapresizeaxis(raw, startvalue, minvalue, maxvalue, step, mink, maxk, k)
	step = step or 2

	mink = math.ceil((minvalue - startvalue) / step)
	maxk = math.floor((maxvalue - startvalue) / step)
	k = math.clamp(math.round((raw - startvalue) / step), mink, maxk)

	return startvalue + k * step
end

function S.applywindowresize(
	resize,
	camera,
	viewport,
	scale,
	delta,
	maxwidth,
	maxheight,
	configuredmin,
	minwidth,
	minheight,
	rawwidth,
	rawheight,
	width,
	height
)
	resize = S.windowresize
	if not resize or not resize.current then return end

	camera = workspace.CurrentCamera
	viewport = camera and camera.ViewportSize or S.gui.AbsoluteSize

	delta = resize.current - resize.start

	maxwidth = math.floor(math.max(320, viewport.X - resize.startabsolute.X - 8))
	maxheight = math.floor(math.max(260, viewport.Y - resize.startabsolute.Y - 8))

	if typeof(S.windowmaxsize) == "Vector2" then
		maxwidth = math.min(maxwidth, math.max(320, math.floor(S.windowmaxsize.X)))
		maxheight = math.min(maxheight, math.max(260, math.floor(S.windowmaxsize.Y)))
	end

	configuredmin = typeof(S.windowminsize) == "Vector2" and S.windowminsize
		or Vector2.new(620, 440)

	minwidth = math.min(math.max(320, math.floor(configuredmin.X)), maxwidth)
	minheight = math.min(math.max(260, math.floor(configuredmin.Y)), maxheight)

	rawwidth = resize.startsize.X + delta.X
	rawheight = resize.startsize.Y + delta.Y
	width = S.snapresizeaxis(rawwidth, resize.startsize.X, minwidth, maxwidth, 4)
	height = S.snapresizeaxis(rawheight, resize.startsize.Y, minheight, maxheight, 2)

	if width == resize.lastwidth and height == resize.lastheight then return end

	resize.lastwidth = width
	resize.lastheight = height
	S.shell.Size = UDim2.fromOffset(width, height)
end

function S.applywindowdrag(drag, delta)
	drag = S.windowdrag
	if not drag or not drag.current or not drag.moved then return end

	delta = drag.current - drag.start
	S.shell.Position = S.offsetposition(drag.startposition, delta)

	
end

function S.applywatermarkdrag(drag)
	drag = S.watermarkdrag
	if not drag or not drag.current then return end

	S.watermark.Position = S.offsetposition(drag.startposition, drag.current - drag.start)
end

function S.stopinteractionrenderloop(connection)
	connection = S.interactionrenderconnection
	S.interactionrenderconnection = nil

	if connection and connection.Connected then connection:Disconnect() end
end

function S.ensureinteractionrenderloop()
	if S.interactionrenderconnection and S.interactionrenderconnection.Connected then return end

	S.interactionrenderconnection = S.runservice.PreRender:Connect(function(scale, delta, now)
		now = os.clock()
		if S.windowresize and now >= S.__blush_nextwindowresize then
			S.__blush_nextwindowresize = now + 1 / 45
			S.applywindowresize()
		end

		if S.sidebarresize and S.sidebarresize.current and now >= S.__blush_nextsidebarresize then
			S.__blush_nextsidebarresize = now + 1 / 45
			delta = S.sidebarresize.current.X - S.sidebarresize.start.X
			S.applysidebarlayout(S.sidebarresize.width + delta, false)
		end

		if S.windowdrag then S.applywindowdrag() end

		if S.watermarkdrag then S.applywatermarkdrag() end
		if S.pickerdrag and S.pickerdrag.current then
			S.pickerdrag.update(S.pickerdrag, S.pickerdrag.current)
			S.pickerdrag.current = nil
		end

		if
			not S.windowresize
			and not S.sidebarresize
			and not S.windowdrag
			and not S.watermarkdrag
			and not S.pickerdrag
		then
			S.stopinteractionrenderloop()
		end
	end)
end

S.connect(
	S.uis.InputChanged,
	function(input, p, delta, data, now, dt, instantaneous, delta2, x, delta3)
		p = S.point(input)

		if S.windowresize and S.matches(S.windowresize, input) then S.windowresize.current = p end

		if S.sidebarresize and S.matches(S.sidebarresize, input) then
			S.sidebarresize.current = p
		end

		if S.windowdrag and S.matches(S.windowdrag, input) then
			S.windowdrag.current = p

			delta = p - S.windowdrag.start

			if delta.Magnitude > 3 then
				if not S.windowdrag.moved then
					S.windowdrag.moved = true

					if S.windowdrag.deferpopup then
						S.windowdrag.deferpopup = false
						S.closepopup()
					end
				end

				if S.windowdrag.search then S.search:ReleaseFocus() end
			end
		end

		if S.watermarkdrag and S.matches(S.watermarkdrag, input) then
			S.watermarkdrag.current = p
		end

		if S.sliderdrag and S.matches(S.sliderdrag, input) then S.sliderdrag.update(p) end

		if S.pickerdrag and S.matches(S.pickerdrag, input) then
			S.pickerdrag.current = p
			S.ensureinteractionrenderloop()
		end

		if S.notificationdrag and S.matches(S.notificationdrag, input) then
			data = S.notificationdrag.data

			if data and not data.closing and data.card and data.card.Parent then
				S.notificationdrag.current = p

				now = os.clock()
				dt = math.max(0.001, now - S.notificationdrag.lasttime)

				instantaneous = (p.X - S.notificationdrag.last.X) / dt

				S.notificationdrag.velocity = S.notificationdrag.velocity * 0.7
					+ instantaneous * 0.3

				S.notificationdrag.last = p
				S.notificationdrag.lasttime = now

				delta2 = p.X - S.notificationdrag.start.X

				x = math.max(0, delta2)

				data.card.Position = UDim2.fromOffset(x, 0)

				data.card.GroupTransparency = math.clamp(x / 360 * 0.45, 0, 0.45)
			end
		end

		if S.sectiondrag and S.matches(S.sectiondrag, input) then
			S.sectiondrag.current = p

			delta3 = p - S.sectiondrag.start

			if not S.sectiondrag.started and delta3.Magnitude >= 5 then
				S.sectiondrag.section.headerdragged = true

				S.beginsectiondrag(S.sectiondrag)
			end

			if S.sectiondrag.started then S.updatesectiondrag(S.sectiondrag) end
		end
	end
)

S.connect(
	S.uis.InputEnded,
	function(
		input,
		mouseended,
		resizeinput,
		sidebarinput,
		drag,
		titleclick,
		watermarkinput,
		sliderinput,
		pickerinput,
		state,
		drag2,
		data,
		distance
	)
		mouseended = input.UserInputType == Enum.UserInputType.MouseButton1

		if S.windowresize and (mouseended or input == S.windowresize.input) then
			resizeinput = S.windowresize.input

			S.applywindowresize()
			S.windowresize = nil
			S.releaseinteraction(resizeinput)

			if S.currentpage then S.currentpage:reflowall(false, true) end
		end

		if S.sidebarresize and (mouseended or input == S.sidebarresize.input) then
			sidebarinput = S.sidebarresize.input

			S.sidebarresize = nil
			S.releaseinteraction(sidebarinput)
			S.applysidebarlayout(S.sidebarwidth, false)

			S.tween(S.sidebarresizeaccent, {
				BackgroundTransparency = 1,
			}, S.hoverti)
		end

		if S.windowdrag and (mouseended or input == S.windowdrag.input) then
			drag = S.windowdrag
			S.windowdrag = nil

			titleclick = S.topprimarygesture
				and (mouseended or input == S.topprimarygesture.input)
				and not drag.moved

			if S.topprimarygesture and (mouseended or input == S.topprimarygesture.input) then
				S.topprimarygesture = nil
			end

			S.releaseinteraction(drag.input)

			if titleclick and S.topnavigationenabled then S.opentopmainmenu() end
		end

		if S.watermarkdrag and (mouseended or input == S.watermarkdrag.input) then
			watermarkinput = S.watermarkdrag.input
			S.watermarkdrag = nil
			S.releaseinteraction(watermarkinput)
		end

		if S.sliderdrag and (mouseended or input == S.sliderdrag.input) then
			sliderinput = S.sliderdrag.input

			for _, knob in ipairs(S.sliderdrag.knobs or {}) do
				S.tween(knob, {
					Size = UDim2.fromOffset(13, 13),
				}, S.fastti)
			end

			S.sliderdrag = nil

			S.releaseinteraction(sliderinput)
			S.requestconfigautosave()
			S.saveuisettings()
		end

		if S.pickerdrag and (mouseended or input == S.pickerdrag.input) then
			pickerinput = S.pickerdrag.input
			if S.pickerdrag.current then S.pickerdrag.update(S.pickerdrag, S.pickerdrag.current) end

			state = S.pickerdrag.state

			state.dragging = false
			state.dragtype = nil

			S.pickerdrag = nil

			state:refresh()
			state:emit(true)
			S.saveuisettings()

			if state.onpersist then state.onpersist() end

			S.releaseinteraction(pickerinput)
		end

		if S.notificationdrag and (mouseended or input == S.notificationdrag.input) then
			drag2 = S.notificationdrag
			S.notificationdrag = nil

			data = drag2.data

			if data and not data.closing and data.card and data.card.Parent then
				distance = math.max(0, drag2.current.X - drag2.start.X)

				if distance >= 92 or drag2.velocity >= 720 then
					S.dismissnotification(data, drag2.velocity)
				else
					data.card.Position = UDim2.fromOffset(0, 0)
					S.tween(data.card, { GroupTransparency = 0 }, S.notificationreturn)
				end
			end
		end

		if S.sectiondrag and (mouseended or input == S.sectiondrag.input) then
			S.finishsectiondrag()
		end

		if
			S.topprimarygesture
			and (mouseended or input == S.topprimarygesture.input)
			and not S.windowdrag
		then
			S.topprimarygesture = nil
		end
	end
)

-- public library api

S.library = {
	Version = "1.9.0",
	Icons = S.icons,
}

S.librarywindow = nil
S.librarytabs = {}
S.librarytaborder = {}
S.librarytabserial = 0


S.lockedcontrols = setmetatable({}, { __mode = "k" })

function S.resolvecontrolroot(control, parentobject, holder, object17)
	if typeof(control) == "Instance" then
		if control:IsA("TextBox") then
			parentobject = control.Parent
			holder = parentobject and parentobject.Parent
			if holder and holder:IsA("GuiObject") then return holder end
			if parentobject and parentobject:IsA("GuiObject") then return parentobject end
		end
		return control:IsA("GuiObject") and control or nil
	end

	if type(control) == "table" then
		object17 = control.Object or control.Button or control.Frame or control.ToggleObject
		if typeof(object17) == "Instance" and object17:IsA("GuiObject") then return object17 end
	end

	return nil
end

function S.applylockedoption(control, value, root, state, overlay)
	root = S.resolvecontrolroot(control)
	if not root then return false end

	state = S.lockedcontrols[control] or S.lockedcontrols[root]
	if not state then
		overlay = S.new("TextButton", {
			Name = "BlushLocked",
			Parent = root,
			Position = UDim2.fromOffset(0, 0),
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = S.theme.window,
			BackgroundTransparency = 0.72,
			BorderSizePixel = 0,
			Text = "",
			AutoButtonColor = false,
			Active = true,
			Selectable = false,
			Visible = false,
			ZIndex = 1000,
		})
		S.corner(overlay, 6)
		S.bindtheme(overlay, "BackgroundColor3", S.theme.window, "window")
		S.transparencybase[overlay] = nil
		S.image(overlay, "lock-keyhole", 13, S.theme.text3, 1001).Position = UDim2.new(1, -18, .5, -6)

		state = {
			root = root,
			overlay = overlay,
			locked = false,
		}
		S.lockedcontrols[control] = state
		S.lockedcontrols[root] = state
	end

	state.locked = value == true
	state.overlay.Visible = state.locked
	state.overlay.Active = state.locked
	root:SetAttribute("BlushLocked", state.locked)

	if state.locked then
		if root:IsA("TextBox") then root:ReleaseFocus(false) end
		for _, descendant in ipairs(root:GetDescendants()) do
			if descendant:IsA("TextBox") and descendant:IsFocused() then
				descendant:ReleaseFocus(false)
			end
		end
	end

	if type(control) == "table" then
		if control.Binding then
			control.Binding.locked = state.locked
			if state.locked and control.Binding.held then
				control.Binding.held = false
				if control.Binding.mode == "Hold" and control.Binding.set then
					control.Binding.set(false, true)
				end
			end
		end

		control.SetLocked = function(_, enabled)
			return S.applylockedoption(control, enabled)
		end
		control.IsLocked = function(current)
			current = S.lockedcontrols[control]
			return current and current.locked == true or false
		end
	end

	return true
end

function S.libraryenhancerow(
	row,
	section,
	addbutton,
	addtoggle,
	addkeypicker,
	adddropdown,
	addmultidropdown,
	addcolorpicker,
	rowdefault
)
	if not row or row.__blush_config_api then return row end

	row.__blush_config_api = true

	addbutton = row.AddButton
	addtoggle = row.AddToggle
	addkeypicker = row.AddKeyPicker
	adddropdown = row.AddDropdown
	addmultidropdown = row.AddMultiDropdown
	addcolorpicker = row.AddColorPicker

	rowdefault = function(config)
		if config.Default ~= nil then return config.Default end

		return config.Value
	end

	row.AddButton = function(self, config, callback, control)
		if type(config) == "table" then
			control =
				addbutton(self, tostring(config.Name or config.Text or "Button"), config.Callback)
			if config.Locked ~= nil then
				S.applylockedoption(control, config.Locked)
			end
			return control
		end

		return addbutton(self, config, callback)
	end

	row.AddKeyPicker = function(self, config, defaultkey, callback, captureoptions, key, control)
		if type(config) == "table" then
			key = config.Default
			if key == nil then key = config.Key end
			if key == nil then key = Enum.KeyCode.RightShift end
			control = addkeypicker(
				self,
				tostring(config.Name or config.Text or "Key"),
				key,
				config.Callback,
				config.CaptureOptions
					or {
						AllowBlacklisted = config.AllowBlacklisted == true,
						AllowEscape = config.AllowEscape == true,
						KeepDelete = config.KeepDelete == true,
					}
			)
			if config.Locked ~= nil then
				S.applylockedoption(control, config.Locked)
			end
			return control
		end

		return addkeypicker(self, config, defaultkey, callback, captureoptions)
	end

	row.AddDropdown = function(self, config, options, default, callback, settings, control)
		if type(config) == "table" then
			control = adddropdown(
				self,
				tostring(config.Name or config.Text or "Dropdown"),
				config.Options or config.Values or config.Items or {},
				config.Default or config.Selected,
				config.Callback,
				config
			)
			if config.Locked ~= nil then
				S.applylockedoption(control, config.Locked)
			end
			return control
		end

		return adddropdown(self, config, options, default, callback, settings)
	end

	row.AddMultiDropdown = function(self, config, options, default, callback, settings, control)
		if type(config) == "table" then
			control = addmultidropdown(
				self,
				tostring(config.Name or config.Text or "Multi Dropdown"),
				config.Options or config.Values or config.Items or {},
				config.Default or config.Selected or {},
				config.Callback,
				config
			)
			if config.Locked ~= nil then
				S.applylockedoption(control, config.Locked)
			end
			return control
		end

		return addmultidropdown(self, config, options, default, callback, settings)
	end

	row.AddColorPicker = function(self, config, color, callback, control)
		if type(config) == "table" then
			control = addcolorpicker(
				self,
				tostring(config.Name or config.Text or "Color"),
				config.Color or config.Default or Color3.new(1, 1, 1),
				config.Callback
			)
			if config.Locked ~= nil then
				S.applylockedoption(control, config.Locked)
			end
			return control
		end

		return addcolorpicker(self, config, color, callback)
	end

	row.AddToggle = function(
		self,
		config,
		default,
		callback,
		keybindable,
		badge,
		sourceconfig,
		name11,
		control,
		copied
	)
		sourceconfig = type(config) == "table" and config or nil

		name11 = sourceconfig and tostring(sourceconfig.Name or sourceconfig.Text or "Toggle")
			or tostring(config or "Toggle")

		control = nil

		if sourceconfig then
			copied = table.clone(sourceconfig)
			copied.Callback = S.persistentcallback(sourceconfig.Callback)

			control = addtoggle(
				self,
				name11,
				rowdefault(copied),
				copied.Callback,
				copied.Keybindable == true,
				copied.Badge
			)
		else
			control =
				addtoggle(self, config, default, S.persistentcallback(callback), keybindable, badge)
		end

		if section then
			S.registerpersistentcontrol(section, "Toggle", name11, control, sourceconfig)
		end

		if sourceconfig and sourceconfig.Locked ~= nil then
			S.applylockedoption(control, sourceconfig.Locked)
		end

		return control
	end

	return row
end

function S.layouttoggleaddons(section, control, config, specifications, header, outer, stack, layout, inline, childconfig, child, kind, keyconfig, refresh, offset)
	specifications = {}
	for _, name in ipairs({ "ColorPicker", "KeyPicker", "Slider", "Dropdown" }) do
		if config[name] ~= nil and config[name] ~= false then
			childconfig = type(config[name]) == "table" and table.clone(config[name]) or {}
			childconfig.Type = name
			table.insert(specifications, childconfig)
		end
	end
	if config.InlineKeyPicker and not config.KeyPicker then table.insert(specifications, { Type = "KeyPicker" }) end
	for name, addon in pairs(config.Addons or {}) do
		childconfig = type(addon) == "table" and table.clone(addon) or {}
		childconfig.Type = childconfig.Type or childconfig.Kind or (type(name) == "string" and name) or addon
		if childconfig.Type == "Keybindable" then
			if not control.Binding.configbutton then
				S.attachtoggleconfig(control.Object, control.Binding)
				S.addtoggleconfigicon(control.Object, control.Binding, control.Object, 0)
			end
		else
			table.insert(specifications, childconfig)
		end
	end
	header = control.Object
	inline = {}
	control.Addons = {}
	refresh = function(right, height)
		right = 0
		if control.Binding.configbutton then
			control.Binding.configbutton.Position = UDim2.new(1, 0, 0.5, 0)
			right = 27
		end
		for index = #inline, 1, -1 do
			inline[index].Position = UDim2.new(1, -right, 0.5, 0)
			right += inline[index].Size.X.Offset + 7
		end
		control.TextObject.Size = UDim2.new(1, -29 - right, 1, 0)
		if outer then
			height = 24 + (layout.AbsoluteContentSize.Y > 0 and 5 + layout.AbsoluteContentSize.Y or 0)
			outer.Size = UDim2.new(1, 0, 0, height)
		end
	end
	table.sort(specifications, function(a, b)
		return (a.Type == "ColorPicker" and 1 or a.Type == "KeyPicker" and 2 or 3)
			< (b.Type == "ColorPicker" and 1 or b.Type == "KeyPicker" and 2 or 3)
	end)
	for _, spec in ipairs(specifications) do
		kind = spec.Type
		if kind == "KeyPicker" then
			child = S.attachinlinekeypicker(header, control.Binding, control.TextObject,
				spec.Key or spec.Default or config.Key or config.DefaultKey, spec.Callback or config.KeyCallback)
			control.KeyObject = child
			table.insert(inline, child)
			child:GetPropertyChangedSignal("Size"):Connect(refresh)
		elseif type(section["Add" .. tostring(kind)]) == "function" then
			childconfig = table.clone(spec)
			if kind == "ColorPicker" then
				childconfig.Target = header
				childconfig.Name = ""
				childconfig.Color = childconfig.Color or config.Color or Color3.new(1, 1, 1)
				childconfig.Callback = childconfig.Callback or config.ColorCallback
				child = section:AddColorPicker(childconfig)
				child.TextObject.Visible = false
				child.Object.Size = UDim2.fromOffset(22, 24)
				child.Object.AnchorPoint = Vector2.new(1, 0.5)
				table.insert(inline, child.Object)
				control.Color = child
			else
				if not outer then
					outer = S.new("Frame", { Parent = header.Parent, Size = header.Size, LayoutOrder = header.LayoutOrder, BackgroundTransparency = 1 })
					header.Parent = outer
					header.Size = UDim2.new(1, 0, 0, 24)
					stack = S.new("Frame", { Parent = outer, Position = UDim2.fromOffset(0, 29), Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1 })
					layout = S.list(stack, 5)
					layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(refresh)
					for _, entry in ipairs(section.controls) do if entry.row == header then entry.row = outer end end
					control.Object = outer
				end
				childconfig.Target = stack
				childconfig.Name = childconfig.Name or kind
				child = section["Add" .. kind](section, childconfig)
			end
			control.Addons[kind] = child
		end
	end
	control.Binding.layoutaddons = refresh
	refresh()
	return control
end

function S.libraryenhancesection(
	section,
	addlabel,
	addbutton,
	addrow,
	addtoggle,
	addtogglekey,
	addtogglecolor,
	addtogglecolorkey,
	addslider,
	addrangeslider,
	adddropdown,
	addplayerdropdown,
	addmultiplayerdropdown,
	addmultidropdown,
	addinput,
	addkeypicker,
	addcolorpicker,
	adddivider,
	addseparator,
	addprogressbar,
	addradio,
	addbadge,
	addimage,
	addavatar,
	addloadingspinner,
	addloadingbar,
	addcontextmenu,
	addconfirmbutton,
	addmodalbutton,
	addbuttongroup,
	addsubtabs,
	configdefault,
	wrappersistentmethod
)
	if not section or section.__blush_config_api then return section end

	section.__blush_config_api = true

	addlabel = section.AddLabel
	addbutton = section.AddButton
	addrow = section.AddRow
	addtoggle = section.AddToggle
	addtogglekey = section.AddToggleKey
	addtogglecolor = section.AddToggleColor
	addtogglecolorkey = section.AddToggleColorKey
	addslider = section.AddSlider
	addrangeslider = section.AddRangeSlider
	adddropdown = section.AddDropdown
	addplayerdropdown = section.AddPlayerDropdown
	addmultiplayerdropdown = section.AddMultiPlayerDropdown
	addmultidropdown = section.AddMultiDropdown
	addinput = section.AddInput
	addkeypicker = section.AddKeyPicker
	addcolorpicker = section.AddColorPicker
	adddivider = section.AddDivider
	addseparator = section.AddSeparator
	addprogressbar = section.AddProgressBar
	addradio = section.AddRadio
	addbadge = section.AddBadge
	addimage = section.AddImage
	addavatar = section.AddAvatar
	addloadingspinner = section.AddLoadingSpinner
	addloadingbar = section.AddLoadingBar
	addcontextmenu = section.AddContextMenu
	addconfirmbutton = section.AddConfirmButton
	addmodalbutton = section.AddModalButton
	addbuttongroup = section.AddButtonGroup
	addsubtabs = section.AddSubTabs

	configdefault = function(config)
		if config.Default ~= nil then return config.Default end

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

	section.AddButton = function(self, config, callback, target, control)
		if type(config) == "table" then
			control = addbutton(
				self,
				tostring(config.Name or config.Text or "Button"),
				config.Callback,
				config.Target
			)
			if config.Locked ~= nil then
				S.applylockedoption(control, config.Locked)
			end
			return control
		end

		return addbutton(self, config, callback, target)
	end

	section.AddRow = function(self, config, height, target, row)
		row = nil

		if type(config) == "table" then
			row = addrow(self, config.Spacing, config.Height, config.Target)
		else
			row = addrow(self, config, height, target)
		end

		return S.libraryenhancerow(row, self)
	end

	section.AddToggle = function(self, config, default, callback, target, keybindable, badge, control)
		if type(config) == "table" then
			control = addtoggle(self, tostring(config.Name or config.Text or "Toggle"), configdefault(config),
				config.Callback, config.Target, config.Keybindable == true, config.Badge)
			return S.layouttoggleaddons(self, control, config)
		end
		return addtoggle(self, config, default, callback, target, keybindable, badge)
	end

	section.AddToggleKey = function(
		self,
		config,
		default,
		defaultkey,
		callback,
		keycallback,
		target,
		badge
	)
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

		return addtogglekey(self, config, default, defaultkey, callback, keycallback, target, badge)
	end

	section.AddToggleColor = function(
		self,
		config,
		default,
		color,
		togglecallback,
		colorcallback,
		target,
		keybindable
	)
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

	section.AddToggleColorKey = function(
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
				config.Target,
				config.Round
			)
		end

		return addslider(self, config, minimum, maximum, default, suffix, callback, target)
	end

	section.AddRangeSlider = function(
		self,
		config,
		minimum,
		maximum,
		defaultmin,
		defaultmax,
		suffix,
		callback,
		target,
		mindistance
	)
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
				config.Target,
				tonumber(config.MinimumDistance or config.MinDistance or config.MinGap) or 0,
				config.Round
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
			target,
			mindistance
		)
	end

	section.AddDropdown = function(
		self,
		config,
		options,
		default,
		callback,
		target,
		dropdownconfig,
		settings
	)
		if type(config) == "table" then
			settings = table.clone(config.Config or {})

			if config.Searchable ~= nil then settings.searchable = config.Searchable == true end

			if config.Dividers ~= nil then settings.dividers = config.Dividers end

			if config.Icons ~= nil then settings.icons = config.Icons end

			if config.Colors ~= nil then settings.colors = config.Colors end

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

		return adddropdown(self, config, options, default, callback, target, dropdownconfig)
	end

	section.AddPlayerDropdown = function(
		self,
		config,
		options,
		default,
		callback,
		target,
		playerconfig,
		settings
	)
		if type(config) == "table" then
			settings = table.clone(config.Config or {})

			if config.Searchable ~= nil then settings.searchable = config.Searchable == true end

			if config.PlayersDivider ~= nil then settings.playersDivider = config.PlayersDivider end

			if config.MultiSelect ~= nil then settings.multiselect = config.MultiSelect == true end

			if config.Everyone ~= nil then settings.everyone = config.Everyone == true end

			if config.Icons ~= nil then settings.icons = config.Icons end

			if config.Colors ~= nil then settings.colors = config.Colors end

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

		return addplayerdropdown(self, config, options, default, callback, target, playerconfig)
	end

	section.AddMultiPlayerDropdown = function(
		self,
		config,
		default,
		callback,
		target,
		playerconfig,
		settings
	)
		if type(config) == "table" then
			settings = table.clone(config.Config or {})

			if config.Searchable ~= nil then settings.searchable = config.Searchable == true end

			if config.PlayersDivider ~= nil then settings.playersDivider = config.PlayersDivider end

			if config.Everyone ~= nil then settings.everyone = config.Everyone == true end

			if config.Icons ~= nil then settings.icons = config.Icons end

			if config.Colors ~= nil then settings.colors = config.Colors end

			return addmultiplayerdropdown(
				self,
				tostring(config.Name or config.Text or "Players"),
				config.Default or config.Values or {},
				config.Callback,
				config.Target,
				settings
			)
		end

		return addmultiplayerdropdown(self, config, default, callback, target, playerconfig)
	end

	section.AddMultiDropdown = function(
		self,
		config,
		options,
		default,
		callback,
		target,
		dropdownconfig,
		settings
	)
		if type(config) == "table" then
			settings = table.clone(config.Config or {})
			if config.KeyPicker ~= nil then settings.KeyPicker = config.KeyPicker == true end
			if config.KeyPickerLabel ~= nil then settings.KeyPickerLabel = config.KeyPickerLabel end
			if config.KeyFormatter ~= nil then settings.KeyFormatter = config.KeyFormatter end

			return addmultidropdown(
				self,
				tostring(config.Name or config.Text or "Multi Dropdown"),
				config.Options or config.Values or config.Items or {},
				config.Default or config.Selected or {},
				config.Callback,
				config.Target,
				settings
			)
		end

		return addmultidropdown(self, config, options, default, callback, target, dropdownconfig)
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

		return addinput(self, config, default, placeholder, callback, target)
	end

	section.AddKeyPicker = function(self, config, defaultkey, callback, target, captureoptions, key)
		if type(config) == "table" then
			key = config.Default
			if key == nil then key = config.Key end
			if key == nil then key = Enum.KeyCode.RightShift end
			return addkeypicker(
				self,
				tostring(config.Name or config.Text or "Key"),
				key,
				config.Callback,
				config.Target,
				config.CaptureOptions
					or {
						AllowBlacklisted = config.AllowBlacklisted == true,
						AllowEscape = config.AllowEscape == true,
						KeepDelete = config.KeepDelete == true,
					}
			)
		end

		return addkeypicker(self, config, defaultkey, callback, target, captureoptions)
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

		return addcolorpicker(self, config, color, callback, target)
	end

	section.AddDivider = function(self, config, target)
		if type(config) == "table" then
			return adddivider(self, config.Text or config.Name, config.Target)
		end

		return adddivider(self, config, target)
	end

	section.AddSeparator = function(self, config)
		if type(config) == "table" then return addseparator(self, config.Target) end

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

		return addprogressbar(self, config, default, suffix, target)
	end

	section.AddRadio = function(self, config, options, default, callback, target, multiselect)
		if type(config) == "table" then
			return addradio(
				self,
				tostring(config.Name or config.Text or "Radio"),
				config.Options or config.Values or config.Items or {},
				configdefault(config),
				config.Callback,
				config.Target,
				config.Multi == true or config.MultiSelect == true
			)
		end

		return addradio(self, config, options, default, callback, target, multiselect)
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

		return addbadge(self, config, textvalue, color, target)
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

		return addimage(self, config, asset, height, target)
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

		return addavatar(self, config, source, target)
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

	section.AddContextMenu = function(self, config, entries, target, control)
		if type(config) == "table" then
			control = addcontextmenu(
				self,
				tostring(config.Name or config.Text or "Actions"),
				config.Entries or config.Items or {},
				config.Target
			)
			if config.Locked ~= nil then
				S.applylockedoption(control, config.Locked)
			end
			return control
		end

		return addcontextmenu(self, config, entries, target)
	end

	section.AddConfirmButton = function(
		self,
		config,
		titletext,
		bodytext,
		callback,
		target,
		control
	)
		if type(config) == "table" then
			control = addconfirmbutton(
				self,
				tostring(config.Name or config.Text or "Confirm"),
				tostring(config.Title or "Confirm"),
				tostring(config.Body or config.Message or ""),
				config.Callback,
				config.Target
			)
			if config.Locked ~= nil then
				S.applylockedoption(control, config.Locked)
			end
			return control
		end

		return addconfirmbutton(self, config, titletext, bodytext, callback, target)
	end

	section.AddModalButton = function(self, config, titletext, bodytext, target, control)
		if type(config) == "table" then
			control = addmodalbutton(
				self,
				tostring(config.Name or config.Text or "Open"),
				tostring(config.Title or "Information"),
				tostring(config.Body or config.Message or ""),
				config.Target
			)
			if config.Locked ~= nil then
				S.applylockedoption(control, config.Locked)
			end
			return control
		end

		return addmodalbutton(self, config, titletext, bodytext, target)
	end

	section.AddButtonGroup = function(self, config, target, row)
		if type(config) == "table" and config.Buttons then
			row = self:AddRow({
				Spacing = config.Spacing or 8,
				Height = config.Height or 32,
				Target = config.Target,
			})

			for _, data in ipairs(config.Buttons) do
				if type(data) == "table" then
					row:AddButton(data)
				else
					row:AddButton(tostring(data))
				end
			end

			return row
		end

		return addbuttongroup(self, config, target)
	end

	section.AddSubTabs = function(self, config, options)
		if type(config) == "table" and (config.Tabs or config.Names or config.Items) then
			return addsubtabs(self, config.Tabs or config.Names or config.Items, config)
		end

		return addsubtabs(self, config, options)
	end

	wrappersistentmethod = function(
		methodname,
		kind,
		positioncallbacks,
		configcallbacks,
		special,
		original
	)
		original = section[methodname]

		section[methodname] = function(self, ...)
			return (function(
				args,
				sourceconfig,
				name12,
				inputcallback,
				copied,
				callback,
				colorcallback,
				colorcallback2,
				control,
				...
			)
				args = table.pack(...)

				sourceconfig = type(args[1]) == "table" and args[1] or nil

				name12 = sourceconfig and tostring(sourceconfig.Name or sourceconfig.Text or kind)
					or tostring(args[1] or kind)

				inputcallback = nil

				if sourceconfig then
					copied = table.clone(sourceconfig)

					for _, field in ipairs(configcallbacks or {}) do
						if field == "ToggleCallback" then
							callback = sourceconfig.Callback or sourceconfig.ToggleCallback

							copied.Callback = S.persistentcallback(callback)

							copied.ToggleCallback = nil
						else
							colorcallback = special == "color"
								and (
									field == "ColorCallback"
									or (kind == "ColorPicker" and field == "Callback")
								)

							if not colorcallback then
								copied[field] = S.persistentcallback(sourceconfig[field])
							end
						end
					end

					if kind == "Input" then inputcallback = copied.Callback end

					args[1] = copied
				else
					for _, index in ipairs(positioncallbacks or {}) do
						colorcallback2 = special == "color"
							and (
								(kind == "ColorPicker" and index == 3)
								or (kind == "ToggleColor" and index == 5)
								or (kind == "ToggleColorKey" and index == 6)
							)

						if not colorcallback2 then
							args[index] = S.persistentcallback(args[index])
						end
					end

					if kind == "Input" then inputcallback = args[4] end
				end

				control = original(self, table.unpack(args, 1, args.n))

				S.registerpersistentcontrol(
					self,
					kind,
					name12,
					control,
					sourceconfig,
					inputcallback
				)

				if sourceconfig and sourceconfig.Locked ~= nil then
					S.applylockedoption(control, sourceconfig.Locked)
				end

				return control
			end)(nil, nil, nil, nil, nil, nil, nil, nil, nil, ...)
		end
	end

	wrappersistentmethod("AddToggle", "Toggle", { 3 }, { "Callback" })

	wrappersistentmethod("AddToggleKey", "ToggleKey", { 4, 5 }, { "Callback", "KeyCallback" })

	wrappersistentmethod(
		"AddToggleColor",
		"ToggleColor",
		{ 4, 5 },
		{ "ToggleCallback", "ColorCallback" },
		"color"
	)

	wrappersistentmethod(
		"AddToggleColorKey",
		"ToggleColorKey",
		{ 5, 6, 7 },
		{ "ToggleCallback", "ColorCallback", "KeyCallback" },
		"color"
	)

	wrappersistentmethod("AddSlider", "Slider", { 6 }, { "Callback" })

	wrappersistentmethod("AddRangeSlider", "RangeSlider", { 7 }, { "Callback" })

	wrappersistentmethod("AddDropdown", "Dropdown", { 4 }, { "Callback" })

	wrappersistentmethod("AddPlayerDropdown", "PlayerDropdown", { 4 }, { "Callback" })

	wrappersistentmethod("AddMultiPlayerDropdown", "MultiPlayerDropdown", { 3 }, { "Callback" })

	wrappersistentmethod("AddMultiDropdown", "MultiDropdown", { 4 }, { "Callback" })

	wrappersistentmethod("AddInput", "Input", { 4 }, { "Callback" })

	wrappersistentmethod("AddKeyPicker", "KeyPicker", { 3 }, { "Callback" })

	wrappersistentmethod("AddColorPicker", "ColorPicker", { 3 }, { "Callback" }, "color")

	wrappersistentmethod("AddRadio", "Radio", { 4 }, { "Callback" })

	function section:SetGradient(value) return S.settextgradient(self.TextObject, value) end

	function section:SetRainbow(value) return S.settextrainbow(self.TextObject, value) end

	return section
end

function S.librarysetlogo(asset, color, hidden, custom)
	hidden = asset == false or tostring(asset or "") == ""
	custom = asset ~= nil and not hidden

	if hidden then
		asset = ""
	elseif not custom then
		asset = S.thumbnail
	elseif S.icons[asset] then
		asset = S.icons[asset]
	end

	S.logocoloroverride = typeof(color) == "Color3" and color or nil
	S.avat.Visible = not hidden
	S.avat.Image = tostring(asset)
	S.avat.ImageColor3 = S.logocoloroverride or (custom and S.theme.text2 or Color3.new(1, 1, 1))
	S.updatebrandlayout()
end

function S.librarysetbrand(title, subtitletext)
	title = tostring(title or "blush.")
	subtitletext = tostring(subtitletext or ("v" .. S.library.Version))

	S.brand.Text = title
	S.subtitle.Text = subtitletext
	S.reopenlabel.Text = title
	S.updatebrandlayout()
	S.updatereopenlayout()

	if S.__blush_watermark_title then
		S.setwatermarktitle(title)
		S.settextgradient(S.__blush_watermark_title, S.titlegradient)
	end
end

function S.libraryrefreshothergroupvisibility(visible)
	visible = S.settingsbutton.Visible

	if not visible then
		for _, tab in ipairs(S.librarytaborder) do
			if tab.Group == "other" and tab.Button and tab.Button.Parent and tab.Button.Visible then
				visible = true
				break
			end
		end
	end

	S.otherheader.Visible = false
	S.othergroup.Visible = visible
	S.refreshsidegroups(false)
end

function S.librarysetsettingstab(config, enabled, name13, icon, groupname, sections)
	if type(config) == "boolean" then
		config = {
			Enabled = config,
		}
	elseif type(config) ~= "table" then
		config = {}
	end

	enabled = config.Enabled ~= false
	name13 = tostring(config.Name or config.Title or "Settings")
	icon = S.librarynormalizeicon(config.Icon or "settings")
	groupname = tostring(config.GroupName or config.CategoryName or "Other")
	sections = config.Sections

	S.settingsbutton.Visible = enabled
	S.settingstext.Text = name13
	S.settingsicon.Image = icon
	S.othertext.Text = groupname

	if type(sections) == "table" then
		S.settingssection.frame.Visible = sections.Interface ~= false
		S.watermarksettingssection.frame.Visible = sections.Watermark ~= false
		S.keybindssection.frame.Visible = sections.Keybinds ~= false
		S.windowsection.frame.Visible = sections.Window ~= false
		S.themessection.frame.Visible = sections.Themes ~= false and sections.Appearance ~= false
		S.backgroundimagesection.frame.Visible = sections.Background ~= false
		S.savessection.frame.Visible = sections.Configs ~= false
	else
		S.settingssection.frame.Visible = true
		S.watermarksettingssection.frame.Visible = true
		S.keybindssection.frame.Visible = true
		S.windowsection.frame.Visible = true
		S.themessection.frame.Visible = true
		S.backgroundimagesection.frame.Visible = true
		S.savessection.frame.Visible = true
	end

	S.settings:reflowall(false)
	S.libraryrefreshothergroupvisibility()
end

function S.librarygetsettingstab()
	if S.librarysettingstab then return S.librarysettingstab end

	S.librarysettingstab = {
		Name = S.settingstext.Text,
		Page = S.settings,
		Button = S.settingsbutton,
	}

	function S.librarysettingstab:AddSection(title, column, sectionicon, config)
		column = string.lower(tostring(column or "left"))

		if column ~= "right" then column = "left" end

		if type(title) == "table" then
			config = title
			column = string.lower(tostring(config.Side or config.Column or "left"))

			if column ~= "right" then column = "left" end

			return S.libraryenhancesection(
				S.createsection(
					S.settings,
					column,
					tostring(config.Name or config.Title or "Section"),
					config.Icon and S.librarynormalizeicon(config.Icon) or nil
				)
			)
		end

		return S.libraryenhancesection(
			S.createsection(
				S.settings,
				column,
				tostring(title or "Section"),
				sectionicon and S.librarynormalizeicon(sectionicon) or nil
			)
		)
	end

	function S.librarysettingstab:AddLeftSection(title, sectionicon)
		if type(title) == "table" then
			title.Side = "left"
			return self:AddSection(title)
		end

		return self:AddSection(title, "left", sectionicon)
	end

	function S.librarysettingstab:AddRightSection(title, sectionicon)
		if type(title) == "table" then
			title.Side = "right"
			return self:AddSection(title)
		end

		return self:AddSection(title, "right", sectionicon)
	end

	function S.librarysettingstab:Select()
		if not S.settingsbutton.Visible then return false end

		S.selectmain(S.settingsbutton)
		S.expandsubtabs(false)
		S.showpage("settings")
		return true
	end

	function S.librarysettingstab:Configure(config)
		S.librarysetsettingstab(config)
		self.Name = S.settingstext.Text
	end

	function S.librarysettingstab:SetVisible(value)
		S.librarysetsettingstab({
			Enabled = value == true,
			Name = S.settingstext.Text,
			Icon = S.settingsicon.Image,
			GroupName = S.othertext.Text,
		})
	end

	return S.librarysettingstab
end

function S.libraryresetnavigation()
	for _, button in ipairs({
		S.homebutton,
		S.combatbutton,
		S.farmingbutton,
		S.componentsbutton,
	}) do
		button.Visible = false
	end

	S.subholder.Visible = false

	for _, page in pairs({
		S.home,
		S.combatmain,
		S.combatvisuals,
		S.combatextras,
		S.farming,
		S.components,
	}) do
		if page and page.frame then page.frame.Visible = false end
	end

	S.mainnavorder = {}
	S.subnavorder = {}
	S.libraryactivetabsection = nil
	S.currentnav = nil
	S.currentsub = nil
	S.currentpage = nil

	S.topnavigation.Visible = false
	S.breadcrumb.Visible = true

	if S.topnavigationtoggle and S.topnavigationtoggle.Object then
		S.topnavigationtoggle.Object.Visible = true
	end

	S.refreshsidegroups(false)
end

function S.librarycreatetab(
	windowapi,
	options,
	icon,
	group,
	name14,
	asset,
	requestedgroup,
	destination,
	sectiontab,
	parentobject,
	pageid,
	page,
	button14,
	textobject,
	indicator,
	iconobject,
	glow,
	applysectionorder,
	tab,
	parenttab
)
	if type(options) ~= "table" then
		options = {
			Name = options,
			Icon = icon,
			Group = group,
		}
	end

	parenttab = options.ParentTab
	S.librarytabserial += 1

	name14 = tostring(options.Name or options.Title or ("Tab " .. S.librarytabserial))
	asset = S.librarynormalizeicon(options.Icon or options.Asset)
	requestedgroup = options.Group
		or options.Section
		or (S.libraryactivetabsection and S.libraryactivetabsection.Name)
		or "main"
	destination = string.lower(tostring(requestedgroup))
	sectiontab = S.librarytabsectionlookup[destination]
	parentobject = nil

	if destination == "other" then
		parentobject = S.othercontent
	elseif destination == "main" then
		parentobject = S.maincontent
	elseif sectiontab then
		parentobject = sectiontab.Content
	else
		destination = "main"
		parentobject = S.maincontent
	end

	pageid = "__blush_library_tab_" .. tostring(S.librarytabserial)
	page = S.createpage(pageid, parenttab and parenttab.Name or name14, parenttab and name14 or nil)
	page.icon = asset

	button14 = nil
	textobject = nil
	indicator = nil
	iconobject = nil
	glow = nil

	if parenttab then
		button14, iconobject, textobject = S.createtopsub(name14, asset or S.icons["layout-grid"], #parenttab.SubTabs + 1)
		button14.Visible = false
	else
	button14, textobject, indicator, iconobject, glow =
		S.navbutton(parentobject, name14, asset, false)

	S.naventries[button14] = {
		button = button14,
		sub = false,
		text = textobject,
		indicator = indicator,
		icon = iconobject,
		glow = glow,
	}

	S.setsidebarentrycompact(S.naventries[button14], S.sidebarcompact, false)

	S.bindnavhover(button14, false)

	if destination == "main" then
		table.insert(S.mainnavorder, button14)
		S.bindnavdrag(button14, S.mainnavorder)
		S.applynavorder()
	elseif sectiontab then
		table.insert(sectiontab.Order, button14)

		applysectionorder = function()
			for index, item in ipairs(sectiontab.Order) do
				item.LayoutOrder = index * 10
			end
		end

		applysectionorder()
		S.bindnavdrag(button14, sectiontab.Order, applysectionorder)
	else
		button14.LayoutOrder = #S.librarytaborder + 1
	end

	end

	tab = {
		Name = name14,
		ParentTab = parenttab,
		SubTabs = {},
		Id = pageid,
		Page = page,
		Button = button14,
		TextObject = textobject,
		Group = destination,
	}

	page.tab = tab
	if parenttab then
		table.insert(parenttab.SubTabs, tab)
		S.topsubentries[button14].tab = tab
	else
		S.naventries[button14].tab = tab
	end
	S.registergradienttarget(button14, textobject)

	function tab:AddSection(title, column, sectionicon, config)
		if type(title) == "table" then
			config = title
			column = string.lower(tostring(config.Side or config.Column or "left"))

			if column ~= "right" then column = "left" end

			return S.libraryenhancesection(
				S.createsection(
					page,
					column,
					tostring(config.Name or config.Title or "Section"),
					config.Icon and S.librarynormalizeicon(config.Icon) or nil
				)
			)
		end

		column = string.lower(tostring(column or "left"))

		if column ~= "right" then column = "left" end

		return S.libraryenhancesection(
			S.createsection(
				page,
				column,
				tostring(title or "Section"),
				sectionicon and S.librarynormalizeicon(sectionicon) or nil
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

	function tab:AddSubTab(config, subicon)
		if self.ParentTab then return self.ParentTab:AddSubTab(config, subicon) end
		config = type(config) == "table" and table.clone(config) or { Name = config, Icon = subicon }
		config.ParentTab = self
		return S.librarycreatetab(windowapi, config)
	end

	function tab:Select()
		if parenttab then
			parenttab.SelectedSubTab = self
			S.selectmain(parenttab.Button)
		elseif self.SelectedSubTab then
			return self.SelectedSubTab:Select()
		elseif #self.SubTabs > 0 then
			return self.SubTabs[1]:Select()
		else
			S.selectmain(button14)
		end
		S.expandsubtabs(false)
		S.showpage(pageid)
		S.updatetopnavigationstate(false)
	end

	function tab:SetName(value, oldname)
		oldname = self.Name
		name14 = tostring(value or name14)

		if S.librarytabs[oldname] == self then S.librarytabs[oldname] = nil end

		self.Name = name14
		S.librarytabs[name14] = self
		textobject.Text = name14
		if parenttab then page.secondary = name14 else
			page.primary = name14
			for _, child in ipairs(self.SubTabs) do child.Page.primary = name14 end
		end

		if S.currentpage == page then S.titleprimary.Text = name14 end
	end

	function tab:SetIcon(value, assetvalue)
		assetvalue = value ~= nil and S.librarynormalizeicon(value) or nil

		page.icon = assetvalue
		if parenttab then iconobject.Image = assetvalue or "" else
			iconobject = S.setnaventryicon(S.naventries[button14], assetvalue)
		end

		S.refreshhotkeylist()
	end

	function tab:SetGradient(value) return S.settextgradient(textobject, value) end

	function tab:SetRainbow(value) return S.settextrainbow(textobject, value) end

	function tab:SetVisible(value)
		self.Hidden = value == false
		button14.Visible = value ~= false
		if parenttab then S.updatetopnavigationstate(false) end

		if self.Group == "other" then S.libraryrefreshothergroupvisibility() end

		S.refreshsidegroups(false)
	end

	function tab:GetPage() return page end

	button14.Activated:Connect(function()
		if button14:GetAttribute("BlushDragSuppress") then return end

		tab:Select()
	end)

	if not parenttab then
		S.librarytabs[name14] = tab
		table.insert(S.librarytaborder, tab)
	end

	if destination == "other" then S.libraryrefreshothergroupvisibility() end

	if not parenttab and not windowapi._firsttab then
		windowapi._firsttab = tab
		tab:Select()

		if S.topnavigationenabled then S.applytopnavigation(true, false) end
	end

	S.refreshsidegroups(false)
	if parenttab and S.currentnav == parenttab.Button then
		if not parenttab.SelectedSubTab then tab:Select() else S.updatetopnavigationstate(false) end
	end
	return tab
end

function S.library:CreateWindow(
	options,
	customfolders,
	foldersettings,
	title,
	subtitletext,
	size,
	position,
	settingsconfig,
	value,
	key,
	visible,
	values,
	enabled,
	mode,
	values3,
	visible2
)
	options = options or {}

	customfolders = options.StorageFolder ~= nil
		or options.Folder ~= nil
		or options.ConfigFolder ~= nil
		or options.ThemeFolder ~= nil
		or options.BackgroundFolder ~= nil
		or options.SettingsFile ~= nil
		or type(options.Folders) == "table"

	if customfolders then
		S.configurestoragefolders(options)
		S.ensurestorage()
		foldersettings = S.readuisettingsfile()
		if next(foldersettings) ~= nil then S.applysaveduisettings(foldersettings, true) end
	end

	if S.librarywindow then return S.librarywindow end

	S.libraryresetnavigation()

	title = options.Title or options.Name or "blush."
	subtitletext = options.Subtitle or options.Version or ("v" .. S.library.Version)
	size = options.Size
	position = options.Position
	settingsconfig = options.SettingsTab

	if settingsconfig == nil then settingsconfig = {
		Enabled = options.Settings ~= false,
	} end

	S.librarysetbrand(title, subtitletext)
	S.username.Text = options.Username == false and ""
		or tostring(options.Username ~= nil and options.Username or S.player.Name)
	S.updatebrandlayout()
	S.librarysetlogo(options.Logo, options.LogoColor)
	S.librarysetsettingstab(settingsconfig)

	S.windowresizeenabled = options.Resize ~= false
	S.windowdragenabled = options.Draggable ~= false

	if options.MinimizeButton ~= nil then
		S.windowminimizebuttonenabled = options.MinimizeButton == true
	end

	if options.SidebarResize ~= nil then
		S.sidebarresizehandle.Visible = options.SidebarResize == true
		S.sidebarresizehandle.Active = options.SidebarResize == true
	end

	if options.SidebarWidth ~= nil then S.applysidebarlayout(options.SidebarWidth, false) end

	S.windowminsize = typeof(options.MinSize) == "Vector2" and options.MinSize
		or Vector2.new(620, 440)

	S.windowmaxsize = typeof(options.MaxSize) == "Vector2" and options.MaxSize or nil

	S.resizehandle.Visible = S.windowresizeenabled
	S.resizehandle.Active = S.windowresizeenabled

	S.setminimizebuttonvisible(S.windowminimizebuttonenabled, false)

	if S.minimizebuttoncontrol then
		S.minimizebuttoncontrol:Set(S.windowminimizebuttonenabled, false)
	end

	if options.Roundness ~= nil then
		S.windowcorner.CornerRadius = UDim.new(0, math.max(0, tonumber(options.Roundness) or 12))
	end

	S.windowstroke.Enabled = false

	if options.Shadow ~= nil then
		S.windowshadowenabled = options.Shadow == true
		S.applywindowshadow()
	end

	if options.Glow ~= nil then S.windowglowenabled = options.Glow == true end

	if options.GlowIntensity ~= nil then
		S.windowglowintensity = math.clamp(
			tonumber(options.GlowIntensity) or S.windowglowintensity,
			0,
			S.windowglowintensitymax
		)
	end

	if options.GlowSize ~= nil then
		S.windowglowsize =
			math.clamp(tonumber(options.GlowSize) or S.windowglowsize, 0, S.windowglowsizemax)
	end

	if typeof(options.GlowColor) == "Color3" then
		S.windowglowcolor = options.GlowColor
	else
		S.windowglowcolor = S.theme.white
	end

	if options.GlowAlpha ~= nil then
		S.windowglowalpha = math.clamp(tonumber(options.GlowAlpha) or S.windowglowalpha, 0, 1)
	end

	S.windowglowrenderalpha = S.windowglowalpha

	S.applywindowglow()

	if S.windowglowtoggle then S.windowglowtoggle:Set(S.windowglowenabled, false) end
	if S.windowglowintensitycontrol then
		S.windowglowintensitycontrol:Set(S.windowglowintensity, false)
	end
	if S.windowglowsizecontrol then S.windowglowsizecontrol:Set(S.windowglowsize, false) end
	if S.windowglowcolorpicker then
		S.windowglowcolorpicker:Set(S.windowglowcolor, S.windowglowalpha, false)

		S.windowglowrenderalpha = S.windowglowcolorpicker:currentalpha()
	end

	if options.Transparency ~= nil then
		value = math.clamp(tonumber(options.Transparency) or 0, 0, 90)

		if S.uitransparencycontrol then S.uitransparencycontrol:Set(value, false) end

		S.applyuitransparency(value)
	end

	if typeof(size) == "Vector2" then
		S.originalwindowsize = size
		S.shell.Size = UDim2.fromOffset(size.X, size.Y)

		if typeof(position) ~= "UDim2" then
			S.shell.Position = S.centeredwindowposition(size)
		end
	end

	if typeof(position) == "UDim2" then S.shell.Position = position end


	if type(options.Theme) == "table" then
		S.applytheme(
			options.Theme.Background or options.Theme.Window or S.theme.window,
			options.Theme.Accent or S.theme.white,
			options.Theme.BackgroundAlpha or S.theme.backgroundAlpha,
			options.Theme.AccentAlpha or S.theme.accentAlpha,
			options.Theme.Font or options.Theme.Text or S.theme.font,
			options.Theme.FontAlpha or S.theme.fontAlpha,
			options.Theme.Animate ~= false
		)
		if typeof(options.Theme.Main) == "Color3" then
			S.applymaincolor(options.Theme.Main, options.Theme.Animate ~= false)
		end
		if options.Theme.MainAlpha ~= nil then S.applymainalpha(options.Theme.MainAlpha) end
		if typeof(options.Theme.Highlight) == "Color3" or options.Theme.HighlightAlpha ~= nil then
			S.applyhighlight(
				typeof(options.Theme.Highlight) == "Color3" and options.Theme.Highlight or S.theme.highlight,
				options.Theme.HighlightAlpha ~= nil and options.Theme.HighlightAlpha or S.theme.highlightAlpha,
				options.Theme.Animate ~= false
			)
		end
	end

	if options.MenuKey ~= nil then
		key = options.MenuKey

		if typeof(key) == "string" then key = S.keyfromname(key) end

		if typeof(key) == "EnumItem" then
			S.menukey = key
			S.refreshmenukeybinding()

			if S.menukeypicker then S.menukeypicker:Set(key, false) end
		end
	end

	if options.Animations ~= nil then
		S.animationsenabled = options.Animations == true

		if S.animationtoggle then S.animationtoggle:Set(S.animationsenabled, false) end
	end

	if options.Search ~= nil then
		S.setsearchvisible(options.Search == true, false)

		if S.searchtoggle then S.searchtoggle:Set(S.searchenabled, false) end
	end

	if options.Notifications ~= nil then
		S.notificationsenabled = options.Notifications == true

		if S.notificationtoggle then S.notificationtoggle:Set(S.notificationsenabled, false) end
	end

	if options.Watermark ~= nil then
		visible = options.Watermark == true
		S.setwatermarkvisible(visible, false)

		if S.watermarktoggle then S.watermarktoggle:Set(visible, false) end
	end

	if type(options.WatermarkInfo) == "table" then
		for _, item in ipairs({ "Player", "Ping", "Time", "Game" }) do
			if options.WatermarkInfo[item] ~= nil then
				S.watermarkconfig[item] = options.WatermarkInfo[item] == true
			end
		end

		if options.WatermarkInfo.FPS ~= nil then
			S.watermarkconfig.FPS = options.WatermarkInfo.FPS == true
		elseif options.WatermarkInfo.Fps ~= nil then
			S.watermarkconfig.FPS = options.WatermarkInfo.Fps == true
		end

		if options.WatermarkInfo.PlayerMode ~= nil then
			S.watermarkconfig.PlayerMode =
				S.normalizewatermarkplayermode(options.WatermarkInfo.PlayerMode)
		end

		if S.watermarkinfocontrol then
			values = {}

			for _, item in ipairs({ "Player", "Fps", "Ping", "Time", "Game" }) do
				enabled = item == "Fps" and S.watermarkconfig.FPS or S.watermarkconfig[item]

				if enabled then table.insert(values, item) end
			end

			S.watermarkinfocontrol:Set(values, false)
		end

		if S.watermarkplayermodecontrol then
			mode = S.normalizewatermarkplayermode(S.watermarkconfig.PlayerMode)
			values3 = {}
			if mode == "Display" or mode == "Both" then values3[#values3 + 1] = "Display" end
			if mode == "Username" or mode == "Both" then values3[#values3 + 1] = "Username" end
			S.watermarkplayermodecontrol:Set(values3, false)
		end

		S.updatewatermarklayout()
	end

	if options.HotkeyList ~= nil then
		visible2 = options.HotkeyList == true
		S.sethotkeylistvisible(visible2)

		if S.hotkeylisttoggle then S.hotkeylisttoggle:Set(visible2, false) end
	end

	S.constructing = false
	S.flushpagelayouts()
	S.gui.Enabled = true
	S.watermarkgui.Enabled = true
	S.reopengui.Enabled = false

	S.modalguard.Modal = true
	S.modalguard.Active = false
	S.modalguard.Visible = true

	S.__blush_windowvisible = true
	S.setvisibilityrootsvisible(true)

	S.librarywindow = {
		_tabs = S.librarytabs,
		_order = S.librarytaborder,
		_firsttab = nil,
		TextObject = S.brand,
	}

	S.librarywindow.Settings = S.librarygetsettingstab()

	function S.librarywindow:AddSectionTab(name, sectiontab)
		sectiontab = S.createlibrarytabsection(name)
		S.libraryactivetabsection = sectiontab
		return sectiontab
	end

	function S.librarywindow:AddTab(...) return S.librarycreatetab(self, ...) end

	function S.librarywindow:GetTab(name) return S.librarytabs[tostring(name)] end

	function S.librarywindow:SelectTab(value, tab)
		tab = value

		if type(value) ~= "table" then tab = S.librarytabs[tostring(value)] end

		if tab and tab.Select then
			tab:Select()
			return true
		end

		return false
	end

	function S.librarywindow:Notify(
		titletext,
		bodytext,
		duration,
		callback,
		buttontext,
		iconasset
	)
		S.notify(titletext, bodytext, duration, callback, buttontext, iconasset)
	end

	function S.librarywindow:SetGradient(element, value)
		if
			value == nil
			and (
				typeof(element) == "ColorSequence"
				or type(element) == "table"
				or type(element) == "string"
			)
		then
			value = element
			element = self
		end

		return S.settextgradient(element, value)
	end

	function S.librarywindow:SetTitleGradient(value) return S.settextgradient(S.brand, value) end

	function S.librarywindow:SetRainbow(element, value)
		if type(element) == "boolean" and value == nil then
			value = element
			element = self
		end

		return S.settextrainbow(element, value)
	end

	function S.librarywindow:SetTitleRainbow(value) return S.settextrainbow(S.brand, value) end

	function S.librarywindow:SetVisible(value) S.requestvisibilitytoggle(value == true) end

	function S.librarywindow:Toggle() S.requestvisibilitytoggle() end

	function S.librarywindow:SetSidebarWidth(value, animate)
		S.applysidebarlayout(value, animate == true)
	end

	function S.librarywindow:GetSidebarWidth() return S.sidebarwidth end

	function S.librarywindow:SetSidebarResizeEnabled(value, enabled2)
		enabled2 = value == true
		S.sidebarresizehandle.Visible = enabled2
		S.sidebarresizehandle.Active = enabled2

		if not enabled2 then
			S.sidebarresize = nil
			S.sidebarresizeaccent.BackgroundTransparency = 1
		end
	end

	function S.librarywindow:SetResizeEnabled(value)
		S.windowresizeenabled = value == true
		S.resizehandle.Visible = S.windowresizeenabled
		S.resizehandle.Active = S.windowresizeenabled

		if not S.windowresizeenabled then S.windowresize = nil end
	end

	function S.librarywindow:SetDraggable(value)
		S.windowdragenabled = value == true

		if not S.windowdragenabled then S.windowdrag = nil end
	end

	function S.librarywindow:SetMinimizeButtonVisible(value)
		S.setminimizebuttonvisible(value, true)

		if S.minimizebuttoncontrol then
			S.minimizebuttoncontrol:Set(S.windowminimizebuttonenabled, false)
		end
	end

	function S.librarywindow:SetMinSize(value)
		if typeof(value) ~= "Vector2" then return false end

		S.windowminsize = value
		return true
	end

	function S.librarywindow:SetMaxSize(value)
		if value == nil then
			S.windowmaxsize = nil
			return true
		end

		if typeof(value) ~= "Vector2" then return false end

		S.windowmaxsize = value
		return true
	end

	function S.librarywindow:SetSize(value, recenter)
		if typeof(value) ~= "Vector2" then return false end

		S.originalwindowsize = value
		S.shell.Size = UDim2.fromOffset(value.X, value.Y)

		if recenter == true then
			S.shell.Position = S.centeredwindowposition(
				value
			)
		end

		if S.currentpage then S.currentpage:reflowall(false) end

		return true
	end

	function S.librarywindow:GetSize()
		return Vector2.new(S.shell.Size.X.Offset, S.shell.Size.Y.Offset)
	end

	function S.librarywindow:SetPosition(value)
		if typeof(value) ~= "UDim2" then return false end

		S.shell.Position = value
		return true
	end

	function S.librarywindow:GetPosition() return S.shell.Position end

	function S.librarywindow:SetLogo(asset, color) S.librarysetlogo(asset, color) end

	function S.librarywindow:SetGlowEnabled(value)
		S.windowglowenabled = value == true
		S.applywindowglow()

		if S.windowglowtoggle then S.windowglowtoggle:Set(S.windowglowenabled, false) end
	end

	function S.librarywindow:SetGlowIntensity(value)
		S.windowglowintensity =
			math.clamp(tonumber(value) or S.windowglowintensity, 0, S.windowglowintensitymax)

		S.applywindowglow()

		if S.windowglowintensitycontrol then
			S.windowglowintensitycontrol:Set(S.windowglowintensity, false)
		end
	end

	function S.librarywindow:SetGlowSize(value)
		S.windowglowsize = math.clamp(tonumber(value) or S.windowglowsize, 0, S.windowglowsizemax)

		S.applywindowglow()

		if S.windowglowsizecontrol then S.windowglowsizecontrol:Set(S.windowglowsize, false) end
	end

	function S.librarywindow:SetGlowAlpha(value)
		S.windowglowalpha = math.clamp(tonumber(value) or S.windowglowalpha, 0, 1)

		S.windowglowrenderalpha = S.windowglowalpha

		if S.windowglowcolorpicker then
			S.windowglowcolorpicker:Set(S.windowglowcolor, S.windowglowalpha, false)
		end

		S.applywindowglow()
	end

	function S.librarywindow:SetGlowColor(value)
		if typeof(value) ~= "Color3" then return false end

		S.windowglowcolor = value
		S.applywindowglow()

		if S.windowglowcolorpicker then
			S.windowglowcolorpicker:Set(value, S.windowglowalpha, false)

			S.windowglowrenderalpha = S.windowglowcolorpicker:currentalpha()
		end

		return true
	end

	function S.librarywindow:SetTransparency(value)
		value = math.clamp(tonumber(value) or 0, 0, 90)

		if S.uitransparencycontrol then S.uitransparencycontrol:Set(value, false) end

		S.applyuitransparency(value)
	end

	function S.librarywindow:SetRoundness(value)
		S.windowcorner.CornerRadius = UDim.new(0, math.max(0, tonumber(value) or 0))
	end

	function S.librarywindow:SetStrokeVisible(value) S.windowstroke.Enabled = false end

	function S.librarywindow:SetShadowVisible(value)
		S.windowshadowenabled = value == true
		S.applywindowshadow()
	end

	function S.librarywindow:SetSettingsTab(config) S.librarysetsettingstab(config) end

	function S.librarywindow:GetSettingsTab() return S.librarygetsettingstab() end

	function S.librarywindow:SetMenuKey(key)
		if typeof(key) == "string" then key = S.keyfromname(key) end

		if typeof(key) ~= "EnumItem" then return false end

		S.menukey = key
		S.refreshmenukeybinding()

		if S.menukeypicker then S.menukeypicker:Set(key, false) end

		return true
	end

	function S.librarywindow:SetWatermark(value, visible3)
		visible3 = value == true
		S.setwatermarkvisible(visible3, true)

		if S.watermarktoggle then S.watermarktoggle:Set(visible3, false) end
	end

	function S.librarywindow:SetWatermarkInfo(config, values4, enabled3, mode2, values5)
		if type(config) ~= "table" then return false end

		for _, item in ipairs({ "Player", "Ping", "Time", "Game" }) do
			if config[item] ~= nil then S.watermarkconfig[item] = config[item] == true end
		end

		if config.FPS ~= nil then
			S.watermarkconfig.FPS = config.FPS == true
		elseif config.Fps ~= nil then
			S.watermarkconfig.FPS = config.Fps == true
		end

		if config.PlayerMode ~= nil then
			S.watermarkconfig.PlayerMode = S.normalizewatermarkplayermode(config.PlayerMode)
		end

		if S.watermarkinfocontrol then
			values4 = {}

			for _, item in ipairs({ "Player", "Fps", "Ping", "Time", "Game" }) do
				enabled3 = item == "Fps" and S.watermarkconfig.FPS or S.watermarkconfig[item]

				if enabled3 then table.insert(values4, item) end
			end

			S.watermarkinfocontrol:Set(values4, false)
		end

		if S.watermarkplayermodecontrol then
			mode2 = S.normalizewatermarkplayermode(S.watermarkconfig.PlayerMode)
			values5 = {}
			if mode2 == "Display" or mode2 == "Both" then values5[#values5 + 1] = "Display" end
			if mode2 == "Username" or mode2 == "Both" then values5[#values5 + 1] = "Username" end
			S.watermarkplayermodecontrol:Set(values5, false)
		end

		S.updatewatermarklayout()
		return true
	end

	function S.librarywindow:SetHotkeyList(value, visible4)
		visible4 = value == true
		S.sethotkeylistvisible(visible4)

		if S.hotkeylisttoggle then S.hotkeylisttoggle:Set(visible4, false) end
	end

	function S.librarywindow:SetAnimations(value)
		S.animationsenabled = value == true

		if S.animationtoggle then S.animationtoggle:Set(S.animationsenabled, false) end
	end

	function S.librarywindow:SetSearch(value)
		S.setsearchvisible(value, true)

		if not S.searchenabled then S.search.Text = "" end

		if S.searchtoggle then S.searchtoggle:Set(S.searchenabled, false) end
	end

	function S.librarywindow:SetNotifications(value)
		S.notificationsenabled = value == true

		if S.notificationtoggle then S.notificationtoggle:Set(S.notificationsenabled, false) end
	end

	function S.librarywindow:SetBackground(source, opacity, blur)
		if source == nil or tostring(source) == "" then
			S.clearbackgroundimage(true)
			return true
		end

		if opacity ~= nil then S.setbackgroundimageopacity(opacity, false) end

		if blur ~= nil then S.setbackgroundimageblur(blur, false) end

		return S.loadbackgroundimage(tostring(source), true, false)
	end

	function S.librarywindow:ClearBackground() S.clearbackgroundimage(true) end

	function S.librarywindow:SetBackgroundOpacity(value) S.setbackgroundimageopacity(value, true) end

	function S.librarywindow:SetBackgroundBlur(value) S.setbackgroundimageblur(value, true) end

	function S.librarywindow:SetBackgroundExcludeSidebar(value)
		S.setbackgroundexcludesidebar(value == true)
	end

	function S.librarywindow:SetAutoBackgroundColors()
		S.autobackgroundcolors = false
		S.backgroundautobase = nil
		return false
	end


	function S.librarywindow:SetTheme(config)
		config = config or {}

		S.applytheme(
			config.Background or config.Window or S.theme.window,
			config.Accent or S.theme.white,
			config.BackgroundAlpha or S.theme.backgroundAlpha,
			config.AccentAlpha or S.theme.accentAlpha,
			config.Font or config.Text or S.theme.font,
			config.FontAlpha or S.theme.fontAlpha,
			config.Animate ~= false
		)

		if typeof(config.Main) == "Color3" then S.applymaincolor(config.Main, config.Animate ~= false) end
		if config.MainAlpha ~= nil then S.applymainalpha(config.MainAlpha) end
		if typeof(config.Highlight) == "Color3" or config.HighlightAlpha ~= nil then
			S.applyhighlight(
				typeof(config.Highlight) == "Color3" and config.Highlight or S.theme.highlight,
				config.HighlightAlpha ~= nil and config.HighlightAlpha or S.theme.highlightAlpha,
				config.Animate ~= false
			)
		end
	end

	function S.librarywindow:GetTheme()
		return {
			Background = S.theme.window,
			Main = S.theme.main,
			Highlight = S.theme.highlight,
			Accent = S.theme.white,
			Font = S.theme.font,
			BackgroundAlpha = S.theme.backgroundAlpha,
			MainAlpha = S.theme.mainAlpha,
			HighlightAlpha = S.theme.highlightAlpha,
			AccentAlpha = S.theme.accentAlpha,
			FontAlpha = S.theme.fontAlpha,
		}
	end

	function S.librarywindow:SetSettingsVisible(value)
		S.settingsbutton.Visible = value ~= false
		S.libraryrefreshothergroupvisibility()
	end

	function S.librarywindow:SetTitle(value) S.librarysetbrand(value, S.subtitle.Text) end

	function S.librarywindow:SetSubtitle(value)
		S.subtitle.Text = tostring(value or "")
		S.updatebrandlayout()
	end

	function S.librarywindow:SetUsername(value)
		S.username.Text = value == false and "" or tostring(value ~= nil and value or S.player.Name)
		S.updatebrandlayout()
	end

	function S.librarywindow:GetUsername() return S.username.Text end

	function S.librarywindow:GetGui() return S.gui end

	function S.librarywindow:Destroy()
		S.__blush_cleanup()
		S.librarywindow = nil
	end

	if options.BackgroundExcludeSidebar ~= nil then
		S.librarywindow:SetBackgroundExcludeSidebar(options.BackgroundExcludeSidebar == true)
	end

	if options.AutoBackgroundColors ~= nil then
		S.librarywindow:SetAutoBackgroundColors(options.AutoBackgroundColors == true)
	end

	if options.Background ~= nil then
		task.defer(
			function()
				S.librarywindow:SetBackground(
					options.Background,
					options.BackgroundOpacity,
					options.BackgroundBlur
				)
			end
		)
	end

	return S.librarywindow
end

function S.library:GetSettingsTab() return S.librarygetsettingstab() end

function S.library:Notify(...) S.notify(...) end

function S.library:SetLocked(element, value)
	return S.applylockedoption(element, value)
end

function S.library:IsLocked(element, root, state)
	root = S.resolvecontrolroot(element)
	state = S.lockedcontrols[element] or (root and S.lockedcontrols[root])
	return state and state.locked == true or false
end

function S.library:SetGradient(element, value) return S.settextgradient(element, value) end

function S.library:SetRainbow(element, value) return S.settextrainbow(element, value) end

function S.library:Destroy()
	S.__blush_cleanup()
	S.librarywindow = nil
end

S.gui.Enabled = false
S.watermarkgui.Enabled = false
S.reopengui.Enabled = false
S.modalguard.Modal = true
S.modalguard.Active = false
S.modalguard.Visible = false

return S.library
