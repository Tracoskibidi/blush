	function S.librarywindow:SetBackgroundExcludeSidebar(value)
		S.setbackgroundexcludesidebar(value == true)
	end

	function S.librarywindow:SetAutoBackgroundColors()
		S.autobackgroundcolors = false
		S.backgroundautobase = nil
		return false
	end

	function S.librarywindow:SetScale(value) S.applyuiscale(value) end

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

	function S.librarywindow:SetTitle(value) S.librarysetbrand(value, S.version.Text) end

	function S.librarywindow:SetVersion(value)
		S.version.Text = tostring(value or "")
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

function S.library:SetLocked(element, value, textvalue)
	return S.applylockedoption(element, value, textvalue)
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
S.modalguard.Modal = false
S.modalguard.Active = false
