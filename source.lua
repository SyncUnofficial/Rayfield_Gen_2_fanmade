local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local TextService=game:GetService("TextService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer=Players.LocalPlayer

local TOUCH_UI = UserInputService.TouchEnabled

local useStudio = RunService:IsStudio()

local fsAvailable = writefile and readfile and isfile and isfolder and makefolder

local SECURE = false
pcall(function()
	SECURE = (getgenv and getgenv().RAYFIELD_SECURE == true) or false
end)

local function dwarn(...)
	if SECURE then return end
	warn(...)
end

local function readf(path)
	if not fsAvailable then return nil end
	local ok, result = pcall(function()
		if isfile(path) then return readfile(path) end
		return nil
	end)
	if ok then return result end
	return nil
end

local function writef(path, content)
	if not fsAvailable then return false end
	local ok = pcall(writefile, path, content)
	return ok
end

local function mkfolder(path)
	if not fsAvailable then return false end
	local ok = pcall(function()
		if not isfolder(path) then makefolder(path) end
	end)
	return ok
end

local function mkpath(path)
	local acc = nil
	for part in string.gmatch(path, "[^/]+") do
		acc = acc and (acc .. "/" .. part) or part
		mkfolder(acc)
	end
end

local BASE_FOLDER = "Rayfield Gen2"
mkfolder(BASE_FOLDER)

local function fetch(url)
	local ok, result = pcall(function()
		return game:HttpGet(url)
	end)
	if ok and type(result) == "string" and #result > 0 then
		return result
	end
	local ok2, result2 = pcall(function()
		local req = (syn and syn.request) or request or http_request
		if not req then return nil end
		local response = req({Url = url,Method = "GET"})
		return response and response.Body or nil
	end)
	if ok2 and type(result2) == "string" and #result2 > 0 then
		return result2
	end

	local ok3, result3 = pcall(function()
		return game:GetService("HttpService"):GetAsync(url)
	end)
	if ok3 and type(result3) == "string" and #result3 > 0 then
		return result3
	end
	return nil
end

local function guiParent()
	if useStudio then
		return LocalPlayer:WaitForChild("PlayerGui")
	end
	local ok, hui = pcall(function()
		return gethui and gethui() or nil
	end)
	if ok and hui then return hui end
	local ok2 = pcall(function()
		local probe = Instance.new("Folder")
		probe.Parent=CoreGui
		probe:Destroy()
	end)
	if ok2 then return CoreGui end
	return LocalPlayer:WaitForChild("PlayerGui")
end

local PROP_ALIASES = {
	name = "Name",
	title = "Title",
	subtitle = "Subtitle",
	content = "Content",
	description = "Description",
	icon = "Icon",
	image = "Image",
	text = "Text",
	flag = "Flag",
	callback = "Callback",
	forgetstate = "ForgetState",
	value = "__VALUE",
	currentvalue = "CurrentValue",
	currentoption = "CurrentOption",
	currentkeybind = "CurrentKeybind",
	range = "Range",
	increment = "Increment",
	suffix = "Suffix",
	prefix = "Prefix",
	minimal = "Minimal",
	options = "Options",
	multiselect = "MultipleOptions",
	multipleoptions = "MultipleOptions",
	placeholder = "PlaceholderText",
	placeholdertext = "PlaceholderText",
	numeric = "Numeric",
	clearonfocus = "ClearOnFocus",
	hold = "Hold",
	holdthreshold = "HoldThreshold",
	onchanged = "OnChanged",
	callonchange = "CallOnChange",
	color = "Color",
	alpha = "Alpha",
	display = "Display",
	compact = "Compact",
	changemode = "ChangeMode",
	changebaseline = "ChangeBaseline",
	numbereasing = "NumberEasing",
	delta = "Delta",
	duration = "Duration",
	avatar = "Avatar",
	minwidth = "MinWidth",
	subtitleabove = "SubtitleAbove",
	order = "Order",
	direction = "Direction",
	boxes = "Boxes",
	dismissable = "Dismissable",
	style = "Style",
	theme = "Theme",
	configuration = "Configuration",
	autosave = "AutoSave",
	autoload = "AutoLoad",
	filename = "FileName",
	customfolder = "CustomFolder",
	locale = "Locale",
	translations = "Translations",
	translator = "Translator",
	fallbackfont = "FallbackFont",
	loadingtitle = "LoadingTitle",
	loadingsubtitle = "LoadingSubtitle",
	configurationsaving = "ConfigurationSaving",
	toggleuikeybind = "ToggleUIKeybind",
	keysystem = "KeySystem",
	badge = "Badge",
	items = "Items",
	points = "Points",
	series = "Series",
	rows = "Rows",
	filled = "Filled",
	smooth = "Smooth",
}

local function normalizeProps(settings, valueKey)
	if type(settings) ~= "table" then return {} end
	local out = {}
	local official = false
	for k, v in pairs(settings) do
		if type(k) == "string" then
			local canon = PROP_ALIASES[string.lower(k)] or k
			if canon == "__VALUE" then canon = valueKey or "CurrentValue" end
			if canon ~= k then official = true end
			out[canon] = v
		else
			out[k] = v
		end
	end
	if official then out.__official = true end
	return out
end

local rgb = Color3.fromRGB

local Theme = {
	Background = rgb(20, 20, 20),
	Card = rgb(31,31, 31),
	CardHover = rgb(39, 39,39),
	CardSelected = rgb(48, 48,48),
	CardInset = rgb(24, 24,24),
	SearchBox = rgb(44, 44, 44),
	Stroke = rgb(255,255, 255),
	TextTitle = rgb(247, 247, 247),
	TextBody = rgb(233, 233, 233),
	TextSub = rgb(152, 152, 152),
	TextMuted = rgb(110,110, 110),
	AccentDark = rgb(54, 104, 80),
	Accent = rgb(70, 168, 120),
	AccentSoft = rgb(104, 210,156),
	Knob = rgb(255, 255, 255),
	KnobOff = rgb(66, 68, 70),
	ToggleTrack = rgb(18, 18, 18),
	BadgeBackground = rgb(240,166, 63),
	BadgeText = rgb(66, 45,15),
	NotifyBackground = rgb(16, 16,16),
}

local i18n = {locale = nil, translations = {}, translator = nil}
local trRegistry = {}

local function activeLocale()
	if i18n.locale and i18n.locale ~= "" then return string.lower(i18n.locale) end
	if LocalPlayer then
		local ok, loc = pcall(function() return LocalPlayer.LocaleId end)
		if ok and loc and loc ~= "" then return string.lower(loc) end
	end
	return "en-us"
end

local function tr(source)
	if type(source) ~= "string" or source == "" then return source end
	local loc = activeLocale()
	if i18n.translator then
		local ok, res = pcall(i18n.translator, source, loc)
		if ok and type(res) == "string" then return res end
	end
	local exact = i18n.translations[loc]
	if exact and exact[source] then return exact[source] end
	local bare = string.match(loc, "^([^-]+)")
	if bare and bare ~= loc then
		local base = i18n.translations[bare]
		if base and base[source] then return base[source] end
	end
	return source
end

local function registerTr(label, source, prop)
	prop = prop or "Text"
	table.insert(trRegistry, {label = label, source = source, prop = prop})
	label[prop] = tr(source)
	return label
end

local function retranslate()
	for _, entry in ipairs(trRegistry) do
		if entry.label and entry.label.Parent then
			pcall(function() entry.label[entry.prop] = tr(entry.source) end)
		end
	end
end

local function registerTranslations(t)
	if type(t) ~= "table" then return end
	for locale, pack in pairs(t) do
		local key = string.lower(tostring(locale))
		i18n.translations[key] = i18n.translations[key] or {}
		if type(pack) == "table" then
			for src, dst in pairs(pack) do
				i18n.translations[key][src] = dst
			end
		end
	end
end

local painted = {}

local function paint(inst, prop, key)
	inst[prop] = Theme[key]
	table.insert(painted, {inst,prop, key})
end

local function repaint()
	for _, entry in ipairs(painted) do
		local inst, prop,key = entry[1],entry[2], entry[3]
		if inst and inst.Parent and Theme[key] then
			pcall(function() inst[prop] = Theme[key] end)
		end
	end
end

local DEFAULT_THEME = {}
for k, v in pairs(Theme) do DEFAULT_THEME[k] = v end

local BUILTIN_THEMES = {
	default = {},
	cobalt = {
		Accent = rgb(36, 132, 246),
		AccentDark = rgb(24, 92, 180),
		AccentSoft = rgb(120, 184, 255),
		BadgeBackground = rgb(36, 132, 246),
		BadgeText = rgb(12, 30, 60),
	},
	ember = {
		Accent = rgb(240, 118, 58),
		AccentDark = rgb(160, 72, 34),
		AccentSoft = rgb(255, 166, 112),
		BadgeBackground = rgb(240, 118, 58),
		BadgeText = rgb(58, 24, 10),
	},
	amethyst = {
		Accent = rgb(168, 112, 240),
		AccentDark = rgb(102, 62, 156),
		AccentSoft = rgb(206, 164, 255),
		BadgeBackground = rgb(168, 112, 240),
		BadgeText = rgb(38, 20, 62),
	},
	frost = {
		Accent = rgb(86, 198, 228),
		AccentDark = rgb(46, 120, 148),
		AccentSoft = rgb(158, 226, 246),
		BadgeBackground = rgb(86, 198, 228),
		BadgeText = rgb(12, 42, 52),
	},
	rose = {
		Accent = rgb(240, 108, 160),
		AccentDark = rgb(158, 60, 98),
		AccentSoft = rgb(255, 162, 196),
		BadgeBackground = rgb(240, 108, 160),
		BadgeText = rgb(60, 16, 34),
	},
}

local OFFICIAL_THEME_KEYS = {
	WindowColor = "Background",
	ContentColor = "TextBody",
	TitlingColor = "TextTitle",
	ElementTextHoverColor = "TextTitle",
	AccentColor = "Accent",
	AccentStroke = "Accent",
	TabColor = "TextSub",
	ElementGradient = "Card",
	ElementStroke = "Stroke",
	SliderHandle = "Knob",
	ToggleTrack = "ToggleTrack",
	ToggleKnobOff = "KnobOff",
	StatBackground = "AccentDark",
}

local function coerceColor(v)
	if typeof(v) == "Color3" then return v end
	if typeof(v) == "ColorSequence" then
		local kp = v.Keypoints
		if kp and #kp > 0 then return kp[1].Value end
	end
	return nil
end

local function resolveTheme(spec)
	local out = {}
	for k, v in pairs(DEFAULT_THEME) do out[k] = v end
	if type(spec) == "string" then
		local preset = BUILTIN_THEMES[string.lower(spec)]
		if preset then
			for k, v in pairs(preset) do out[k] = v end
		end
	elseif type(spec) == "table" then
		for k, v in pairs(spec) do
			local internal = OFFICIAL_THEME_KEYS[k] or (DEFAULT_THEME[k] ~= nil and k) or nil
			if internal then
				local c = coerceColor(v)
				if c then out[internal] = c end
			end
		end
	end
	return out
end

local themeTweens = {}
local function applyTheme(spec, animate)
	local resolved = resolveTheme(spec)
	for k, v in pairs(resolved) do Theme[k] = v end
	for _, t in ipairs(themeTweens) do pcall(function() t:Cancel() end) end
	themeTweens = {}
	if not animate then
		repaint()
		return
	end
	local info = TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	for _, entry in ipairs(painted) do
		local inst, prop, key = entry[1], entry[2], entry[3]
		if inst and inst.Parent and Theme[key] then
			pcall(function()
				local tw = TweenService:Create(inst, info, {[prop] = Theme[key]})
				tw:Play()
				table.insert(themeTweens, tw)
			end)
		end
	end
end

local function create(class, props, children)
	local inst = Instance.new(class)

	if class == "TextButton" or class == "ImageButton" then
		inst.AutoButtonColor = false
	end
	local parent = nil
	if props then
		for k,v in pairs(props) do
			if k == "Parent" then
				parent = v
			else
				inst[k] = v
			end
		end
	end
	if children then
		for _, child in ipairs(children) do
			child.Parent = inst
		end
	end
	if parent then inst.Parent = parent end
	return inst
end

local function round(inst, r)
	return create("UICorner", {CornerRadius = UDim.new(0, r), Parent = inst})
end

local function roundFull(inst)
	return create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = inst})
end

local function padAll(inst, t, r, b, l)
	return create("UIPadding", {
		PaddingTop = UDim.new(0,t or 0),
		PaddingRight = UDim.new(0, r or 0),
		PaddingBottom = UDim.new(0, b or 0),
		PaddingLeft = UDim.new(0, l or 0),
		Parent = inst,
	})
end

local GLOW_IMAGE = 'rbxassetid://6014261993'

local function softGlow(parent, color, trans, spread,z)
	return create("ImageLabel", {
		Name = 'Glow',
		Image = GLOW_IMAGE,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5,0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, spread, 1, spread),
		ImageColor3 = color,
		ImageTransparency = trans,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(49,49, 450,450),
		ZIndex = z or 0,
		Parent = parent,
	})
end

local FONT_REGULAR = Enum.Font.BuilderSans
local FONT_MEDIUM = Enum.Font.BuilderSansMedium
local FONT_BOLD = Enum.Font.BuilderSansBold
do
	local ok = pcall(function() return Enum.Font.BuilderSansMedium end)
	if not ok then
		FONT_REGULAR = Enum.Font.Gotham
		FONT_MEDIUM = Enum.Font.GothamMedium
		FONT_BOLD = Enum.Font.GothamBold
	end
end

local TI_FAST=TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TI_MED = TweenInfo.new(0.26, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local TI_SMOOTH = TweenInfo.new(0.32,Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
local TI_MORPH = TweenInfo.new(0.42, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local TI_SLOW = TweenInfo.new(0.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)

local function tween(o, ti, props)
	local t = TweenService:Create(o, ti, props)
	t:Play()
	return t
end

local function measureText(text, size,font)
	local ok, result = pcall(function()
		return TextService:GetTextSize(text, size, font, Vector2.new(1000,100))
	end)
	if ok then return result end
	return Vector2.new(#text * size * 0.5, size)
end

local function measureWrapped(text,size, font, width)
	local ok, result = pcall(function()
		return TextService:GetTextSize(text, size, font, Vector2.new(width, 100000))
	end)
	if ok then return math.ceil(result.Y) end
	local perLine = math.max(1, math.floor(width / (size * 0.55)))
	return math.ceil(#text / perLine) * (size + 3)
end

local function parsenum(s)
	s = tostring(s)
	local i, j = s:find("%-?%d[%d,]*%.?%d*")
	if not i then return nil end
	local numStr = s:sub(i, j)
	return tonumber((numStr:gsub(",",""))), s:sub(1, i - 1), s:sub(j + 1),numStr
end

local function commafy(s)
	local sign = ""
	if s:sub(1,1) == "-" then sign = "-"; s = s:sub(2) end
	s = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	if s:sub(1, 1) == "," then s = s:sub(2) end
	return sign .. s
end

local function catmull(p0, p1, p2, p3, t)
	local t2, t3 = t * t, t * t * t
	return 0.5 * (2 * p1 + (p2 - p0) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2 + (3 * p1 - p0 - 3 * p2 + p3) * t3)
end

local function countingValue(label, initial)
	local token = 0
	local current = initial ~= nil and parsenum(initial) or nil
	return function(newValue)
		local targetN, prefix, suffix, targetNumStr = parsenum(newValue)
		if not targetN then
			label.Text = tostring(newValue)
			current = nil
			return
		end
		local decimals = 0
		local dot=targetNumStr:find("%.")
		if dot then decimals = #targetNumStr - dot end
		local hasComma = targetNumStr:find(",") ~= nil
		local startN = current or targetN
		token = token + 1
		local myToken = token
		local function fmt(n)
			local str = decimals > 0 and string.format("%." .. decimals .. "f", n) or tostring(math.floor(n + 0.5))
			if hasComma then str = commafy(str) end
			return prefix .. str .. suffix
		end
		if startN == targetN then
			label.Text = fmt(targetN)
			current=targetN
			return
		end
		local duration = math.clamp(math.abs(targetN - startN) * 0.02, 0.35, 0.9)
		task.spawn(function()
			local elapsed = 0
			while elapsed < duration do
				if myToken ~= token then return end
				local dt = task.wait()
				elapsed = math.min(elapsed + dt, duration)
				local a = 1 - (1 - elapsed / duration) ^ 3
				label.Text = fmt(startN + (targetN - startN) * a)
			end
			if myToken == token then
				label.Text = fmt(targetN)
				current=targetN
			end
		end)
	end
end

local function odometerValue(label, initial)
	label.TextTransparency = 1
	local font, size, color = label.Font, label.TextSize,label.TextColor3
	local cellH = TextService:GetTextSize("0", size, font, Vector2.new(2000,2000)).Y

	local digWidths, digitW = {}, 0
	for d = 0, 9 do
		local w = math.ceil(TextService:GetTextSize(tostring(d), size, font, Vector2.new(2000, 2000)).X)
		digWidths[d] = w
		digitW = math.max(digitW, w)
	end

	local row = create("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = label.AnchorPoint,
		Position = label.Position,
		Size = UDim2.new(0, 0, 0, cellH),
		AutomaticSize = Enum.AutomaticSize.X,
		ZIndex = label.ZIndex,
		Parent = label.Parent,
	})
	create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = row,
	})

	local token = 0
	local prevDigits = {}
	local function digitsOf(s)
		local t = {}
		for ch in s:gmatch("%d") do t[#t + 1] = ch end
		return t
	end

	local function setVal(newValue, animate)
		local targetN, prefix, suffix, targetNumStr = parsenum(newValue)
		if not targetN then
			row.Visible = false
			label.TextTransparency = 0
			label.Text = tostring(newValue)
			prevDigits = {}
			return
		end
		label.Text = ""
		row.Visible = true
		local decimals=0
		local dot = targetNumStr:find("%.")
		if dot then decimals = #targetNumStr - dot end
		local hasComma = targetNumStr:find(",") ~= nil
		local function fmt(n)
			local str = decimals > 0 and string.format("%." .. decimals .. "f",n) or tostring(math.floor(n + 0.5))
			if hasComma then str = commafy(str) end
			return prefix .. str .. suffix
		end
		local targetStr = fmt(targetN)
		token = token + 1

		local tDigits = digitsOf(targetStr)
		local nT, nP = #tDigits,#prevDigits
		for _, ch in ipairs(row:GetChildren()) do
			if ch:IsA("GuiObject") then ch:Destroy() end
		end

		local digitIndex, order=0, 0
		local strips = {}
		for i = 1, #targetStr do
			local chr = targetStr:sub(i, i)
			order = order + 1
			if chr:match("%d") then
				digitIndex = digitIndex + 1
				local posFromRight = nT - digitIndex
				local pIdx = nP - posFromRight
				local startD = (pIdx >= 1 and prevDigits[pIdx]) and tonumber(prevDigits[pIdx]) or 0
				local targetD = tonumber(chr)
				local cell = create("Frame",{
					BackgroundTransparency = 1,
					Size = UDim2.fromOffset(digWidths[targetD], cellH),
					ClipsDescendants = true,
					LayoutOrder = order,
					ZIndex = row.ZIndex,
					Parent = row,
				})
				local strip = create("Frame", {
					BackgroundTransparency = 1,
					AnchorPoint = Vector2.new(0.5,0),
					Size = UDim2.fromOffset(digitW,10 * cellH),
					Position=UDim2.new(0.5, 0, 0, -startD * cellH),
					ZIndex = row.ZIndex,
					Parent = cell,
				})
				for d = 0, 9 do
					create("TextLabel", {
						BackgroundTransparency = 1,
						Position = UDim2.fromOffset(0, d * cellH),
						Size = UDim2.fromOffset(digitW, cellH),
						Font = font,
						TextSize = size,
						TextColor3 = color,
						Text = tostring(d),
						TextXAlignment=Enum.TextXAlignment.Center,
						TextYAlignment = Enum.TextYAlignment.Center,
						ZIndex = row.ZIndex,
						Parent = strip,
					})
				end
				strips[#strips + 1] = { strip = strip, startD = startD, targetD = targetD, posFromRight = posFromRight }
			else
				local w = math.ceil(TextService:GetTextSize(chr, size, font, Vector2.new(2000,2000)).X)
				create("TextLabel", {
					BackgroundTransparency = 1,
					Size = UDim2.fromOffset(math.max(w, 3), cellH),
					Font = font,
					TextSize = size,
					TextColor3 = color,
					Text = chr,
					TextXAlignment = Enum.TextXAlignment.Center,
					TextYAlignment = Enum.TextYAlignment.Center,
					LayoutOrder = order,
					ZIndex = row.ZIndex,
					Parent = row,
				})
			end
		end

		prevDigits = tDigits
		local maxR = math.max(1, nT - 1)
		for _,s in ipairs(strips) do
			local dest = UDim2.new(0.5, 0,0, -s.targetD * cellH)
			if animate == false or s.startD == s.targetD then
				s.strip.Position = dest
			else
				local frac = s.posFromRight / maxR
				local duration = 0.26 + 0.22 * (1 - frac)
				tween(s.strip,TweenInfo.new(duration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Position = dest })
			end
		end
	end

	if initial ~= nil then setVal(initial, false) end
	return setVal
end

local Icons = nil
local pendingIcons = {}

local ICON_ALIASES = {
	["house"] = {"home"},
	["home"] = {"house"},
	["chart-no-axes-column"] = {"bar-chart-3", "bar-chart"},
	["chart-no-axes-column-increasing"] = {"bar-chart-3", "bar-chart"},
	["chart-column"] = {"bar-chart-2"},
	["chart-bar"] = {"bar-chart-horizontal"},
	["chart-line"] = {"line-chart"},
	["triangle-alert"] = {"alert-triangle"},
	["circle-alert"] = {"alert-circle"},
	["circle-check"] = {"check-circle", "check-circle-2"},
	["circle-x"] = {"x-circle"},
	["circle-help"] = {"help-circle"},
	["square-check"] = {"check-square"},
	["square-pen"] = {"pen-square", "edit"},
	["ellipsis"] = {"more-horizontal"},
	["ellipsis-vertical"] = {"more-vertical"},
	["wand-sparkles"] = {"wand-2"},
	["trash"] = {"trash-2"},
	["maximize"] = {"maximize-2"},
	["minimize"] = {"minimize-2"},
	["grip"] = {"grip-horizontal"},
	["user-round"] = {"user-circle-2", "user"},
	["users-round"] = {"users"},
	["loader-pinwheel"] = {"loader"},
	["loader-circle"] = {"loader-2"},
	["key"] = {"key-round"},
	["key-round"] = {"key"},
}

local warnedIcons = {}

local function getLucide(name)
	if not Icons then return nil end
	local sized = Icons["48px"]
	if not sized then return nil end
	name=string.lower(name)
	local entry = sized[name]
	if not entry then
		local aliases = ICON_ALIASES[name]
		if aliases then
			for _, alias in ipairs(aliases) do
				entry = sized[alias]
				if entry then break end
			end
		end
	end
	if not entry then return nil end
	if type(entry[1]) ~= "number" then return nil end
	return {
		id = entry[1],
		size = Vector2.new(entry[2][1], entry[2][2]),
		offset = Vector2.new(entry[3][1], entry[3][2]),
	}
end


local function loadIcons()

	local okMod, bundled = pcall(function()
		local RS = game:GetService("ReplicatedStorage")
		local iconMod = RS:FindFirstChild("RayfieldGen2Icons")
		if iconMod and iconMod:IsA("ModuleScript") then
			return require(iconMod)
		end
		return nil
	end)
	if okMod and type(bundled) == "table" and bundled["48px"] then
		Icons = bundled
		return
	end

	local cachePath = BASE_FOLDER .. "/icons_cache.lua"
	local source = readf(cachePath)
	local fresh = false
	if not source then
		source = fetch("https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/refs/heads/main/icons.lua")
		fresh = true
	end
	if not source then return end
	local ok, result = pcall(function()
		local chunk = loadstring(source)
		return chunk and chunk() or nil
	end)
	if ok and type(result) == "table" and result["48px"] then
		Icons = result
		if fresh then
			writef(cachePath, source)
		end
	elseif not fresh then

		source = fetch("https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/refs/heads/main/icons.lua")
		if source then
			local ok2,result2=pcall(function()
				local chunk = loadstring(source)
				return chunk and chunk() or nil
			end)
			if ok2 and type(result2) == "table" and result2["48px"] then
				Icons = result2
				writef(cachePath, source)
			end
		end
	end
end

loadIcons()

local function flushPendingIcons()
	if not Icons then return end
	for _, entry in ipairs(pendingIcons) do
		if entry.img and entry.img.Parent then
			local asset = nil
			for _, name in ipairs(entry.names) do
				asset = getLucide(name)
				if asset then break end
			end
			if asset then
				entry.img.Image = "rbxassetid://" .. tostring(asset.id)
				entry.img.ImageRectSize = asset.size
				entry.img.ImageRectOffset = asset.offset
				if entry.onApplied then entry.onApplied() end
			end
		end
	end
	pendingIcons = {}
end

if not Icons then
	task.spawn(function()
		for _=1, 12 do
			task.wait(2.5)
			loadIcons()
			if Icons then
				flushPendingIcons()
				return
			end
		end
	end)
end

local function applyLucide(img, names, onApplied)
	if type(names) == "string" then names = {names} end
	if Icons then
		for _,name in ipairs(names) do
			local asset = getLucide(name)
			if asset then
				img.Image = "rbxassetid://" .. tostring(asset.id)
				img.ImageRectSize = asset.size
				img.ImageRectOffset = asset.offset
				if onApplied then onApplied() end
				return true
			end
		end
		local wanted=names[1]
		if not warnedIcons[wanted] then
			warnedIcons[wanted] = true
			dwarn("Rayfield Gen2 | Unknown icon \"" .. tostring(wanted) .. "\"");
		end
		return false
	end
	table.insert(pendingIcons, {img = img, names = names, onApplied = onApplied})
	return false
end


local function makeIcon(parent, icon,size, color3, transparency)
	if icon == nil or icon == 0 or icon == "" then return nil end
	local img = create("ImageLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(size, size),
		ImageColor3 = color3 or Theme.TextTitle,
		ImageTransparency = transparency or 0,
		Parent = parent,
	})
	if type(icon) == "number" then
		if SECURE then return img end
		img.Image = "rbxassetid://" .. tostring(icon)
	elseif type(icon) == "string" then
		if string.find(icon, "rbxassetid") or string.find(icon, "rbxthumb") then
			if SECURE then return img end
			img.Image = icon
		elseif string.find(icon, "rbxasset") or string.find(icon, "://") then
			img.Image = icon
		else
			applyLucide(img, icon);
		end
	end
	return img
end

local RayfieldLibrary = {
	Flags = {},
	Theme = Theme,
}

local Connections = {}
local function connect(signal, fn)
	local c = signal:Connect(fn)
	table.insert(Connections, c)
	return c
end

local function safeCall(fn, ...)
	if type(fn) ~= "function" then return end
	local ok, err = pcall(fn, ...)
	if not ok then
		dwarn("Rayfield Gen2 | Callback error: " .. tostring(err))
	end
end

local VALUE_ELEMENT = {Toggle = true, Slider = true, Input = true, Dropdown = true, Keybind = true, ColorPicker = true}

local function pageUnits(page)
	local kids = {}
	for _, c in ipairs(page:GetChildren()) do
		if c:IsA("GuiObject") then table.insert(kids, c) end
	end
	table.sort(kids, function(a, b) return a.LayoutOrder < b.LayoutOrder end)
	local units = {}
	for _, c in ipairs(kids) do
		if c:GetAttribute("Attached") and #units > 0 then
			table.insert(units[#units], c)
		else
			table.insert(units, {c})
		end
	end
	return units
end

local function unitIndex(anchor)
	local page = anchor.Parent
	if not page then return 1, 1 end
	local units = pageUnits(page)
	for i, unit in ipairs(units) do
		if unit[1] == anchor then return i, #units end
	end
	return 1, #units
end

local function moveUnit(anchor, index)
	local page = anchor.Parent
	if not page then return end
	local units = pageUnits(page)
	local from = nil
	for i, unit in ipairs(units) do
		if unit[1] == anchor then
			from = i
			break
		end
	end
	if not from then return end
	local unit = table.remove(units, from)
	index = math.clamp(index, 1, #units + 1)
	table.insert(units, index, unit)
	local n = 0
	for _, u in ipairs(units) do
		for _, inst in ipairs(u) do
			n = n + 1
			inst.LayoutOrder = n
		end
	end
end

local function finalizeElement(element, settings, anchor, valueGetter)
	if anchor then
		element.MoveTo = function(_, index) moveUnit(anchor, index) end
		element.MoveToTop = function() moveUnit(anchor, 1) end
		element.MoveToBottom = function()
			local _, n = unitIndex(anchor)
			moveUnit(anchor, n)
		end
		element.MoveUp = function()
			local i = unitIndex(anchor)
			moveUnit(anchor, i - 1)
		end
		element.MoveDown = function()
			local i = unitIndex(anchor)
			moveUnit(anchor, i + 1)
		end
	end
	if VALUE_ELEMENT[element.Type or ""] and not settings.ForgetState then
		local key = settings.Flag or settings.Name
		if key and key ~= "" then
			element.Flag = key
			RayfieldLibrary.Flags[key] = element
		end
	end
	if valueGetter then
		setmetatable(element, {
			__index = function(t, k)
				if k == "value" then return valueGetter(t) end
				return nil
			end,
			__newindex = function(t, k, v)
				if k == "value" and type(rawget(t, "Set")) == "function" then
					t:Set(v)
					return
				end
				rawset(t, k, v)
			end,
		})
	end
	return element
end

local function getCurrentValue(t)
	return rawget(t, "CurrentValue")
end

local rootGui = nil
local notifyStack = nil
local toastStack = nil
local popupLayer = nil
local destroyed = false

local UI_DESIGN_W, UI_DESIGN_H = 554, 612
local autoUiScale = 1
local userUiScale = 1
local uiScaleObjects = {}
local uiScaleWatchers = {}

local function currentUiScale()
	return math.clamp(autoUiScale * userUiScale, 0.5, 1.5)
end

local function applyUiScale()
	local s = currentUiScale()
	for i = #uiScaleObjects, 1, -1 do
		local obj = uiScaleObjects[i]
		if obj.Parent then
			obj.Scale = s
		else
			table.remove(uiScaleObjects, i)
		end
	end
	for i = #uiScaleWatchers, 1, -1 do
		if not pcall(uiScaleWatchers[i], s) then
			table.remove(uiScaleWatchers, i)
		end
	end
end

local function attachUiScale(inst)
	local scaler = create("UIScale", {Scale = currentUiScale(), Parent = inst})
	table.insert(uiScaleObjects, scaler)
	return scaler
end

local function onUiScaleChanged(fn)
	table.insert(uiScaleWatchers, fn)
end

local function refreshAutoScale()
	if not rootGui then return end
	local vp = rootGui.AbsoluteSize
	if vp.X < 50 or vp.Y < 50 then return end
	local fit = math.min(vp.X / UI_DESIGN_W, vp.Y / UI_DESIGN_H, 1)
	local snapped = math.max(math.floor(fit * 100 + 0.5) / 100, 0.55)
	if snapped ~= autoUiScale then
		autoUiScale = snapped
		applyUiScale()
	end
end

local function setUserUiScale(factor)
	userUiScale = math.clamp(factor, 0.5, 1.5)
	applyUiScale()
end

local function ensureRoot()
	if rootGui and rootGui.Parent then return rootGui end
	rootGui = create("ScreenGui", {
		Name = "RayfieldGen2",
		DisplayOrder = 100000,
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	})
	pcall(function()
		if syn and syn.protect_gui then syn.protect_gui(rootGui) end
	end)
	rootGui.Parent = guiParent()

	notifyStack = create("Frame", {
		Name = "Notifications",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -20, 1, -20),
		Size = UDim2.fromOffset(300,900),
		Parent = rootGui,
	})
	create("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 8),
		Parent = notifyStack,
	})

	toastStack = create("Frame", {
		Name = "Toasts",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 16),
		Size = UDim2.fromOffset(400, 400),
		ZIndex = 40,
		Parent = rootGui,
	})
	create("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		VerticalAlignment = Enum.VerticalAlignment.Top,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 8),
		Parent = toastStack,
	})

	popupLayer = create("Frame", {
		Name = "Popups",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 60,
		Visible = false,
		Parent = rootGui,
	})
	attachUiScale(notifyStack)
	attachUiScale(toastStack)
	connect(rootGui:GetPropertyChangedSignal("AbsoluteSize"), refreshAutoScale)
	refreshAutoScale()
	return rootGui
end

local notifyOrder = 0

function RayfieldLibrary:Notify(data)
	data = normalizeProps(data)
	data.Image = data.Image or data.Icon
	ensureRoot();
	notifyOrder = notifyOrder + 1

	local hasIcon = data.Image ~= nil and data.Image ~= "" and data.Image ~= 0
	local NOTIFY_W, ICON_BOX=300, 32
	local textX = hasIcon and 70 or 18
	local textWidth = NOTIFY_W - textX - 14

	local titleText = data.Title or "Notification"
	local bodyText = data.Content or ""
	local titleH = measureWrapped(titleText, 16, FONT_BOLD, textWidth)
	local bodyH = bodyText ~= "" and measureWrapped(bodyText,15, FONT_MEDIUM, textWidth) or 0

	local fullH = math.max(15 + titleH + (bodyH > 0 and (2 + bodyH) or 0) + 14, 60)

	local holder = create("Frame", {
		Name = titleText,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -60, 0, 0),
		LayoutOrder = notifyOrder,
		Parent = notifyStack,
	})
	local glow = softGlow(holder, Color3.fromRGB(0, 0,0), 1, 18, 0)

	local card = create("CanvasGroup", {
		Size = UDim2.fromScale(1, 1),
		GroupTransparency = 1,
		BackgroundColor3=Theme.NotifyBackground,
		Parent = holder,
	})
	round(card, 20)

	local cardStroke = create("UIStroke", {Color = Color3.fromRGB(255, 255, 255), Transparency = 1, Parent = card})

	if hasIcon then
		local icon = makeIcon(card, data.Image, ICON_BOX, Theme.TextTitle)
		if icon then
			icon.AnchorPoint = Vector2.new(0, 0.5)
			icon.Position = UDim2.new(0, 20,0.5, 0)
		end
	end

	create("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(textX,15),
		Size = UDim2.new(0, textWidth, 0, titleH),
		Font=FONT_BOLD,
		TextSize = 16,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		Text = titleText,
		TextColor3 = Theme.TextTitle,
		Parent = card,
	})
	if bodyH > 0 then
		create("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(textX, 15 + titleH + 2),
			Size = UDim2.new(0, textWidth, 0,bodyH),
			Font = FONT_MEDIUM,
			TextSize = 15,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			Text = bodyText,
			TextColor3 = Theme.TextSub,
			Parent = card,
		})
	end

	local clicker = create("TextButton",{
		BackgroundTransparency = 1,
		Text = "",
		Size = UDim2.fromScale(1, 1),
		ZIndex = 5,
		Parent = card,
	})

	local paused = false
	local dismissed = false
	clicker.MouseEnter:Connect(function() paused = true end)
	clicker.MouseLeave:Connect(function() paused = false end)

	local GROW=TweenInfo.new(0.6, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
	local FADE=TweenInfo.new(0.4, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)

	local function dismiss()
		if dismissed then return end
		dismissed = true

		tween(card, FADE, {GroupTransparency = 1})
		tween(cardStroke, FADE, {Transparency = 1})
		tween(glow, FADE,{ImageTransparency = 1})
		task.wait(0.2)
		tween(holder, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Size = UDim2.new(1, -90, 0, 0)})
		task.wait(0.55)
		holder:Destroy()
	end

	clicker.MouseButton1Click:Connect(function()
		task.spawn(dismiss)
	end)

	task.defer(function()

		tween(holder, GROW, {Size = UDim2.new(1, 0, 0, fullH)})
		task.wait(0.15)
		tween(card, FADE, {GroupTransparency = 0})
		tween(cardStroke, FADE, {Transparency = 0.94})
		task.wait(0.05)
		tween(glow, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {ImageTransparency = 0.72});

		local duration = data.Duration or math.min(math.max(#bodyText * 0.1 + 2.5, 3), 10)
		local elapsed=0
		while elapsed < duration and not dismissed do
			local dt = task.wait(0.1)
			if not paused then elapsed = elapsed + dt end
		end
		dismiss()
	end)
end

function RayfieldLibrary:Toast(data)
	data = normalizeProps(data)
	ensureRoot()
	notifyOrder = notifyOrder + 1

	local titleText = data.Title or ""
	local subtitleText = data.Subtitle or ""
	local hasSub = subtitleText ~= ""
	local avatarId = data.Avatar
	local iconVal = data.Icon or data.Image
	local hasIcon = (avatarId ~= nil) or (iconVal ~= nil and iconVal ~= "" and iconVal ~= 0)

	local leftPad = hasIcon and 44 or 16
	local rightPad = 16
	local titleW = measureText(titleText, 15, FONT_BOLD).X
	local subW = hasSub and measureText(subtitleText, 13, FONT_MEDIUM).X or 0
	local textW = math.max(titleW, subW)
	local pillH = hasSub and 52 or 40
	local pillW = math.max(leftPad + math.ceil(textW) + rightPad, data.MinWidth or 0)
	pillW = math.max(pillW, hasIcon and 96 or 72)

	local holder = create("Frame", {
		Name = "Toast",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(pillW, 0),
		LayoutOrder = -notifyOrder,
		Parent = toastStack,
	})
	local glow = softGlow(holder, Color3.fromRGB(0, 0, 0), 1, 16, 0)
	local card = create("CanvasGroup", {
		Size = UDim2.fromScale(1, 1),
		GroupTransparency = 1,
		BackgroundColor3 = Theme.NotifyBackground,
		Parent = holder,
	})
	roundFull(card)
	local cardStroke = create("UIStroke", {Color = Color3.fromRGB(255, 255, 255), Transparency = 1, Parent = card})

	if hasIcon then
		if avatarId ~= nil then
			local av = create("ImageLabel", {
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 12, 0.5, 0),
				Size = UDim2.fromOffset(24, 24),
				Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(avatarId) .. "&w=48&h=48",
				Parent = card,
			})
			roundFull(av)
		else
			local ic = makeIcon(card, iconVal, 20, Theme.TextTitle)
			if ic then
				ic.AnchorPoint = Vector2.new(0, 0.5)
				ic.Position = UDim2.new(0, 12, 0.5, 0)
			end
		end
	end

	local subAbove = data.SubtitleAbove == true
	if hasSub then
		local textCol = create("Frame", {
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, leftPad, 0.5, 0),
			Size = UDim2.new(1, -leftPad - rightPad, 0, 36),
			Parent = card,
		})
		create("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 1),
			Parent = textCol,
		})
		local titleLbl = create("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 17),
			Font = FONT_BOLD,
			TextSize = 15,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Text = titleText,
			TextColor3 = Theme.TextTitle,
			LayoutOrder = subAbove and 2 or 1,
			Parent = textCol,
		})
		local subLbl = create("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 15),
			Font = FONT_MEDIUM,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Text = subtitleText,
			TextColor3 = Theme.TextSub,
			LayoutOrder = subAbove and 1 or 2,
			Parent = textCol,
		})
	else
		create("TextLabel", {
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, leftPad, 0.5, 0),
			Size = UDim2.new(1, -leftPad - rightPad, 1, 0),
			Font = FONT_BOLD,
			TextSize = 15,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Text = titleText,
			TextColor3 = Theme.TextTitle,
			Parent = card,
		})
	end

	local clicker = create("TextButton", {
		BackgroundTransparency = 1,
		Text = "",
		Size = UDim2.fromScale(1, 1),
		ZIndex = 5,
		Parent = card,
	})

	local dismissed = false
	local DROP = TweenInfo.new(0.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
	local FADE = TweenInfo.new(0.35, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)

	local function dismiss()
		if dismissed then return end
		dismissed = true
		tween(card, FADE, {GroupTransparency = 1})
		tween(cardStroke, FADE, {Transparency = 1})
		tween(glow, FADE, {ImageTransparency = 1})
		task.wait(0.18)
		tween(holder, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {Size = UDim2.fromOffset(pillW, 0)})
		task.wait(0.42)
		holder:Destroy()
	end

	clicker.MouseButton1Click:Connect(function() task.spawn(dismiss) end)

	task.defer(function()
		tween(holder, DROP, {Size = UDim2.fromOffset(pillW, pillH)})
		task.wait(0.12)
		tween(card, FADE, {GroupTransparency = 0})
		tween(cardStroke, FADE, {Transparency = 0.9})
		tween(glow, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {ImageTransparency = 0.78})
		local duration = data.Duration or 3
		task.wait(duration)
		dismiss()
	end)
end

function RayfieldLibrary:Popup(data)
	data = normalizeProps(data)
	ensureRoot()
	popupLayer.Visible = true

	local backdrop = create("TextButton", {
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		Size = UDim2.fromScale(1, 1),
		Parent = popupLayer,
	})

	local CARD_W = 420
	local titleText = data.Title or "Popup"
	local hasIcon = data.Icon ~= nil and data.Icon ~= "" and data.Icon ~= 0
	local contentText = data.Content or ""
	local boxes = type(data.Boxes) == "table" and data.Boxes or nil
	local options = type(data.Options) == "table" and data.Options or {{Text = "OK", Style = "primary"}}

	local textLeft = hasIcon and 58 or 24
	local headerH = 30
	local subH = data.Subtitle and 18 or 0
	local bodyW = CARD_W - 48

	local bodyH = 0
	if boxes then
		bodyH = #boxes * 64 + (#boxes - 1) * 8
	elseif contentText ~= "" then
		bodyH = math.min(measureWrapped(contentText, 15, FONT_MEDIUM, bodyW), 260)
	end
	local footerH = 60
	local topPad = 22
	local gap = 16
	local cardH = topPad + headerH + subH + (bodyH > 0 and (gap + bodyH) or 0) + gap + footerH

	local card = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.fromOffset(CARD_W, cardH),
		Parent = popupLayer,
	})
	attachUiScale(card)
	paint(card, "BackgroundColor3", "Background")
	round(card, 20)
	create("UIStroke", {Color = Color3.fromRGB(255, 255, 255), Transparency = 0.9, Parent = card})
	local cardGlow = softGlow(card, Color3.fromRGB(0, 0, 0), 1, 40, -1)

	local closeIcon = create("ImageLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(20, topPad + 2),
		Size = UDim2.fromOffset(18, 18),
		ImageColor3 = Theme.TextSub,
		Parent = card,
	})
	applyLucide(closeIcon, {"x"})

	if hasIcon then
		local ic = makeIcon(card, data.Icon, 22, Theme.TextTitle)
		if ic then ic.Position = UDim2.fromOffset(48, topPad) end
	end

	create("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(hasIcon and 82 or 48, topPad),
		Size = UDim2.new(1, -(hasIcon and 100 or 68), 0, 24),
		Font = FONT_BOLD,
		TextSize = 20,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = titleText,
		TextColor3 = Theme.TextTitle,
		Parent = card,
	})
	if data.Subtitle then
		create("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(hasIcon and 82 or 48, topPad + 24),
			Size = UDim2.new(1, -(hasIcon and 100 or 68), 0, 16),
			Font = FONT_MEDIUM,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = tostring(data.Subtitle),
			TextColor3 = Theme.TextSub,
			Parent = card,
		})
	end

	local bodyY = topPad + headerH + subH + gap
	if boxes then
		for i, box in ipairs(boxes) do
			local bp = normalizeProps(box)
			local row = create("Frame", {
				Position = UDim2.fromOffset(24, bodyY + (i - 1) * 72),
				Size = UDim2.fromOffset(CARD_W - 48, 64),
				Parent = card,
			})
			paint(row, "BackgroundColor3", "Card")
			round(row, 12)
			local bx = 16
			if bp.Icon then
				local ic = makeIcon(row, bp.Icon, 20, Theme.TextTitle)
				if ic then
					ic.AnchorPoint = Vector2.new(0, 0.5)
					ic.Position = UDim2.new(0, 16, 0.5, 0)
					bx = 48
				end
			end
			create("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(bx, 13),
				Size = UDim2.new(1, -bx - 16, 0, 18),
				Font = FONT_BOLD,
				TextSize = 15,
				TextXAlignment = Enum.TextXAlignment.Left,
				Text = bp.Title or "",
				TextColor3 = Theme.TextTitle,
				Parent = row,
			})
			if bp.Description then
				create("TextLabel", {
					BackgroundTransparency = 1,
					Position = UDim2.fromOffset(bx, 33),
					Size = UDim2.new(1, -bx - 16, 0, 16),
					Font = FONT_MEDIUM,
					TextSize = 13,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextTruncate = Enum.TextTruncate.AtEnd,
					Text = bp.Description,
					TextColor3 = Theme.TextSub,
					Parent = row,
				})
			end
		end
	elseif contentText ~= "" then
		local scroller = create("ScrollingFrame", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(24, bodyY),
			Size = UDim2.fromOffset(CARD_W - 48, bodyH),
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollBarThickness = 2,
			ScrollBarImageColor3 = Color3.fromRGB(90, 90, 90),
			BorderSizePixel = 0,
			Parent = card,
		})
		create("TextLabel", {
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.new(1, -4, 0, 0),
			Font = FONT_MEDIUM,
			TextSize = 15,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			Text = contentText,
			TextColor3 = Theme.TextSub,
			Parent = scroller,
		})
	end

	local footer = create("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 24, 1, -22),
		Size = UDim2.new(1, -48, 0, 44),
		Parent = card,
	})
	create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 10),
		Parent = footer,
	})

	local PopupHandle = {}
	local closed = false
	local function closePopup()
		if closed then return end
		closed = true
		tween(card, TI_FAST, {Size = UDim2.fromOffset(CARD_W - 24, cardH - 16)})
		tween(backdrop, TI_FAST, {BackgroundTransparency = 1})
		task.wait(0.14)
		card:Destroy()
		backdrop:Destroy()
		if #popupLayer:GetChildren() == 0 then popupLayer.Visible = false end
	end
	function PopupHandle:Close() task.spawn(closePopup) end

	local nOpts = #options
	for i = 1, nOpts do
		local opt = normalizeProps(options[i])
		local style = string.lower(tostring(opt.Style or "neutral"))
		local btn = create("TextButton", {
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.new(0, 0, 1, 0),
			Text = "",
			LayoutOrder = i,
			Parent = footer,
		})
		round(btn, 12)
		padAll(btn, 0, 22, 0, 22)
		local btnStroke = create("UIStroke", {Transparency = 1, Parent = btn})
		if style == "primary" then
			btn.BackgroundColor3 = Theme.Accent
		elseif style == "danger" then
			btn.BackgroundColor3 = Color3.fromRGB(200, 60, 55)
			local dGlow = softGlow(btn, Color3.fromRGB(200, 60, 55), 0.55, 26, -1)
		else
			btn.BackgroundColor3 = Theme.Card
			btnStroke.Color = Color3.fromRGB(255, 255, 255)
			btnStroke.Transparency = 0.88
		end
		local lbl = create("TextLabel", {
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.new(0, 0, 1, 0),
			Font = FONT_BOLD,
			TextSize = 15,
			Text = opt.Text or "OK",
			TextColor3 = (style == "primary" or style == "danger") and Color3.fromRGB(255, 255, 255) or Theme.TextTitle,
			Parent = btn,
		})
		local baseColor = btn.BackgroundColor3
		btn.MouseEnter:Connect(function()
			tween(btn, TI_FAST, {BackgroundColor3 = baseColor:Lerp(Color3.fromRGB(255, 255, 255), 0.12)})
		end)
		btn.MouseLeave:Connect(function()
			tween(btn, TI_FAST, {BackgroundColor3 = baseColor})
		end)
		btn.MouseButton1Click:Connect(function()
			safeCall(opt.Callback)
			closePopup()
		end)
	end

	local dismissable = data.Dismissable ~= false
	if dismissable then
		backdrop.MouseButton1Click:Connect(closePopup)
		connect(UserInputService.InputBegan, function(input, processed)
			if not closed and input.KeyCode == Enum.KeyCode.Escape then
				closePopup()
			end
		end)
	end

	card.Size = UDim2.fromOffset(CARD_W - 24, cardH - 16)
	tween(backdrop, TI_MED, {BackgroundTransparency = 0.45})
	tween(card, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.fromOffset(CARD_W, cardH)})
	return PopupHandle
end

local function showAccountToast()
	if not LocalPlayer then return end
	ensureRoot()
	notifyOrder = notifyOrder + 1

	local wrapper = create("Frame", {
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Size = UDim2.new(0,240,0,58),
		LayoutOrder = notifyOrder,
		Parent = notifyStack,
	})
	local pill = create("Frame", {
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.new(0, 0, 0,54),
		Position = UDim2.fromOffset(280, 0),
		BackgroundColor3 = Theme.NotifyBackground,
	})
	roundFull(pill)
	create("UIStroke", {Color = Color3.fromRGB(255, 255, 255), Transparency = 0.92, Parent = pill})
	create("UIGradient",{
		Rotation = 90,
		Color=ColorSequence.new(Color3.fromRGB(255,255, 255), Color3.fromRGB(170, 170, 170)),
		Parent = pill,
	})
	padAll(pill, 6, 20, 6, 6)
	create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment=Enum.VerticalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 10),
		Parent = pill,
	})

	local avatar = create("ImageLabel", {
		BackgroundColor3 = Theme.Card,
		Size = UDim2.fromOffset(42, 42),
		Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(LocalPlayer.UserId) .. "&w=48&h=48",
		LayoutOrder = 1,
		Parent = pill,
	})
	roundFull(avatar)

	local textCol=create("Frame",{
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.new(0, 0, 1, 0),
		LayoutOrder = 2,
		Parent = pill,
	})
	create("TextLabel", {
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.new(0, 0,0, 14),
		Position = UDim2.fromOffset(0, 9),
		Font = FONT_MEDIUM,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = "Signed in as",
		TextColor3 = Theme.TextSub,
		Parent = textCol,
	})
	create("TextLabel", {
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.new(0, 0,0, 16),
		Position = UDim2.fromOffset(0, 25),
		Font = FONT_BOLD,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = LocalPlayer.DisplayName or LocalPlayer.Name,
		TextColor3 = Theme.TextTitle,
		Parent = textCol,
	})

	pill.Parent = wrapper
	tween(pill,TI_MORPH, {Position = UDim2.fromOffset(0, 0)})
	task.delay(4, function()
		tween(pill, TI_SMOOTH, {Position = UDim2.fromOffset(280, 0)})
		task.wait(0.25)
		tween(wrapper, TI_MED, {Size = UDim2.new(0, 240, 0,0)})
		task.wait(0.26)
		wrapper:Destroy()
	end)
end

local function runKeySystem(Settings)
	local keySettings = Settings.KeySettings or {}
	local fileName = keySettings.FileName or "Key"
	local keyPath = BASE_FOLDER .. "/" .. fileName .. ".txt"

	local keys = {}
	local rawKey = keySettings.Key or {}
	if type(rawKey) == "string" then rawKey = {rawKey} end

	if keySettings.GrabKeyFromSite then
		for _, url in ipairs(rawKey) do
			local body = fetch(tostring(url))
			if body then
				body = string.gsub(body, "%s+$", "")
				body = string.gsub(body,"^%s+","")
				table.insert(keys, body)
			end
		end
	else
		for _, k in ipairs(rawKey) do
			table.insert(keys, tostring(k))
		end
	end

	local function isValid(candidate)
		candidate = string.gsub(tostring(candidate),"^%s+", "")
		candidate = string.gsub(candidate, "%s+$", "")
		for _, k in ipairs(keys) do
			if candidate == k then return true end
		end
		return false
	end

	if #keys == 0 then
		dwarn("Rayfield Gen2 | Key system enabled but no keys resolved, skipping")
		return true
	end

	if keySettings.SaveKey then
		local saved = readf(keyPath)
		if saved and isValid(saved) then
			return true
		end
	end

	ensureRoot()

	local overlay = create("Frame", {
		BackgroundColor3 = Color3.fromRGB(0, 0,0),
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1,1),
		ZIndex = 50,
		Parent = rootGui,
	})
	tween(overlay, TI_MED, {BackgroundTransparency = 0.45})

	local card = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5,0.52),
		Size = UDim2.fromOffset(360, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Theme.Background,
		ZIndex = 51,
		Parent = overlay,
	})
	attachUiScale(card)
	round(card, 20)
	create("UIStroke", {Color = Color3.fromRGB(255, 255, 255), Transparency = 0.92, Parent = card})
	create("UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new(Color3.fromRGB(255,255, 255), Color3.fromRGB(160, 160, 160)),
		Parent = card,
	})
	padAll(card, 24,22, 22,22)
	create("UIListLayout",{
		FillDirection = Enum.FillDirection.Vertical,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 10),
		Parent = card,
	})

	local well = create("Frame", {
		BackgroundColor3 = Theme.Card,
		Size = UDim2.fromOffset(52,52),
		LayoutOrder = 1,
		Parent = card,
	})
	roundFull(well)
	local keyIcon = makeIcon(well, "key-round", 26,Theme.TextTitle)
	if keyIcon then
		keyIcon.AnchorPoint = Vector2.new(0.5,0.5)
		keyIcon.Position = UDim2.fromScale(0.5, 0.5)
	end

	create("TextLabel", {
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1,0, 0, 0),
		Font = FONT_BOLD,
		TextSize = 20,
		TextWrapped = true,
		Text = keySettings.Title or Settings.Name or "Key System",
		TextColor3 = Theme.TextTitle,
		LayoutOrder = 2,
		Parent = card,
	})
	create("TextLabel", {
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0,0,0),
		Font = FONT_MEDIUM,
		TextSize = 14,
		TextWrapped = true,
		Text = keySettings.Subtitle or "Enter your key to continue",
		TextColor3 = Theme.TextSub,
		LayoutOrder = 3,
		Parent = card,
	})
	if keySettings.Note and keySettings.Note ~= "" then
		create("TextLabel", {
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.new(1, 0, 0, 0),
			Font = FONT_REGULAR,
			TextSize = 13,
			TextWrapped = true,
			Text = keySettings.Note,
			TextColor3 = Theme.TextMuted,
			LayoutOrder = 4,
			Parent = card,
		})
	end

	local boxHolder = create("Frame", {
		BackgroundColor3 = Theme.CardInset,
		Size = UDim2.new(1,0, 0, 44),
		LayoutOrder = 5,
		Parent = card,
	})
	round(boxHolder, 12)
	local boxStroke = create("UIStroke", {Color = Color3.fromRGB(255,255, 255), Transparency = 0.88, Parent = boxHolder})
	local box = create("TextBox",{
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(14,0),
		Size = UDim2.new(1, -28, 1, 0),
		Font = FONT_MEDIUM,
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Left,
		PlaceholderText = "Key",
		PlaceholderColor3 = Theme.TextMuted,
		Text = "",
		ClearTextOnFocus = false,
		TextColor3 = Theme.TextBody,
		Parent = boxHolder,
	})

	local submit = create("TextButton", {
		BackgroundColor3 = Theme.TextTitle,
		Size = UDim2.new(1,0, 0, 44),
		Font = FONT_BOLD,
		TextSize = 15,
		Text = "Unlock",
		TextColor3 = Color3.fromRGB(12, 12, 12),
		AutoButtonColor = false,
		LayoutOrder = 6,
		Parent = card,
	})
	round(submit,12)
	submit.MouseEnter:Connect(function()
		tween(submit, TI_FAST, {BackgroundColor3 = Color3.fromRGB(220, 220, 220)})
	end)
	submit.MouseLeave:Connect(function()
		tween(submit, TI_FAST, {BackgroundColor3 = Theme.TextTitle})
	end)

	card.Position = UDim2.fromScale(0.5, 0.56)
	tween(card, TI_MORPH, {Position = UDim2.fromScale(0.5, 0.5)})

	local passed=false

	local function shake()
		tween(boxStroke, TweenInfo.new(0.1),{Color = Color3.fromRGB(224,90,90),Transparency = 0.2})
		local base = card.Position
		local seq = {8, -7, 5, -3, 0}
		task.spawn(function()
			for _, dx in ipairs(seq) do
				tween(card, TweenInfo.new(0.05, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Position = UDim2.new(base.X.Scale, dx, base.Y.Scale, 0),
				})
				task.wait(0.05)
			end
			task.wait(0.4)
			tween(boxStroke, TweenInfo.new(0.3), {Color = Color3.fromRGB(255, 255, 255), Transparency = 0.88})
		end)
	end

	local function attempt()
		if isValid(box.Text) then
			passed = true
			if keySettings.SaveKey then
				writef(keyPath, box.Text)
			end
			tween(card, TI_MED, {Position = UDim2.fromScale(0.5, 0.54)})
			tween(overlay,TI_MED, {BackgroundTransparency = 1})
			task.wait(0.22)
			overlay:Destroy()
		else
			shake()
		end
	end

	submit.MouseButton1Click:Connect(function() task.spawn(attempt) end)
	box.FocusLost:Connect(function(enterPressed)
		if enterPressed then task.spawn(attempt) end
	end)

	repeat task.wait() until passed or destroyed or not overlay.Parent
	return passed
end

function RayfieldLibrary:CreateWindow(Settings)
	Settings = normalizeProps(Settings)
	ensureRoot()

	if Settings.Theme ~= nil then
		applyTheme(Settings.Theme, false)
	end

	if Settings.Locale ~= nil then i18n.locale = tostring(Settings.Locale) end
	if type(Settings.Translations) == "table" then registerTranslations(Settings.Translations) end
	if type(Settings.Translator) == "function" then i18n.translator = Settings.Translator end

	if Settings.KeySystem then
		local ok = runKeySystem(Settings)
		if not ok then
			dwarn("Rayfield Gen2 | Key system was not passed")
			return nil
		end
	end

	local officialConfig = nil
	if type(Settings.Configuration) == "table" then
		officialConfig = normalizeProps(Settings.Configuration)
	end

	local configEnabled = false
	local configFolder = BASE_FOLDER
	local configFile = "Config"
	local configExt = ".json"
	local autoSaveEnabled = true
	if officialConfig then
		configEnabled = fsAvailable
		configExt = ".rfld"
		configFolder = "Rayfield/Configurations"
		if officialConfig.CustomFolder and officialConfig.CustomFolder ~= "" then
			configFolder = configFolder .. "/" .. tostring(officialConfig.CustomFolder)
		end
		configFile = tostring(officialConfig.FileName or Settings.Name or "Config")
		autoSaveEnabled = officialConfig.AutoSave ~= false
	elseif type(Settings.ConfigurationSaving) == "table" and Settings.ConfigurationSaving.Enabled then
		configEnabled = fsAvailable
		configFolder = Settings.ConfigurationSaving.FolderName or configFolder
		configFile = Settings.ConfigurationSaving.FileName or configFile
	end
	if configEnabled then mkpath(configFolder) end

	local function writeConfiguration(fileName)
		if not configEnabled or destroyed then return false end
		local out = {}
		for flag, element in pairs(RayfieldLibrary.Flags) do
			if element.Type == "Toggle" or element.Type == "Slider" or element.Type == "Input" then
				out[flag] = element.CurrentValue
			elseif element.Type == "Dropdown" then
				out[flag] = element.CurrentOption
			elseif element.Type == "Keybind" then
				out[flag] = element.CurrentKeybind
			elseif element.Type == "ColorPicker" then
				local c = element.Color
				out[flag] = {R = math.floor(c.R * 255 + 0.5), G = math.floor(c.G * 255 + 0.5), B = math.floor(c.B * 255 + 0.5), A = rawget(element, "Alpha")}
			end
		end
		return writef(configFolder .. "/" .. (fileName or configFile) .. configExt, HttpService:JSONEncode(out))
	end

	local savePending = false
	local function saveConfiguration()
		if not configEnabled or destroyed or not autoSaveEnabled then return end
		if savePending then return end
		savePending = true
		task.delay(0.6, function()
			savePending = false
			if destroyed then return end
			writeConfiguration(nil)
		end)
	end

	local function applyConfiguration(fileName, silent)
		if not configEnabled then return false end
		local raw = readf(configFolder .. "/" .. (fileName or configFile) .. configExt)
		if not raw then return false end
		local ok, data = pcall(function() return HttpService:JSONDecode(raw) end)
		if not ok or type(data) ~= "table" then return false end
		for flag, value in pairs(data) do
			local element = RayfieldLibrary.Flags[flag]
			if element then
				pcall(function()
					if element.Type == "ColorPicker" and type(value) == "table" then
						element:Set(Color3.fromRGB(value.R or 255, value.G or 255, value.B or 255))
						if value.A and type(rawget(element, "SetAlpha")) == "function" then
							element:SetAlpha(value.A)
						end
					else
						element:Set(value)
					end
				end)
			end
		end
		if not silent then
			RayfieldLibrary:Notify({Title = "Configuration loaded", Content = "Your saved settings were applied.", Duration = 3, Image = "file-check"})
		end
		return true
	end

	task.spawn(function()
		if not fsAvailable or not LocalPlayer then return end
		local path = BASE_FOLDER .. "/lastuser.txt"
		local last = readf(path)
		local current = tostring(LocalPlayer.UserId)
		writef(path, current)
		if last ~= nil and last ~= current then
			task.wait(0.5)
			showAccountToast()
		end
	end)

	local WINDOW_W, WINDOW_H = 530, 550
	local HEADER_H = 76
	local PILL_H = 62

	local pillNameText = Settings.Name or "Rayfield"
	local pillTextW = math.max(
		measureText(pillNameText, 16, FONT_BOLD).X,
		measureText("Tap to show",13, FONT_MEDIUM).X
	)
	local PILL_W = math.clamp(12 + 44 + 12 + math.ceil(pillTextW) + 26, 180,340)

	local function shownPos()
		return UDim2.new(0.5, 0, 0.5, -math.floor((WINDOW_H + 18) * currentUiScale() / 2))
	end

	local root = create("Frame", {
		Name = "WindowRoot",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = shownPos(),
		Size = UDim2.fromOffset(WINDOW_W,WINDOW_H + 18),
		Parent = rootGui,
	})
	attachUiScale(root)
	refreshAutoScale()
	root.Position = shownPos()

	local shadow = create("ImageLabel", {
		Name = "Shadow",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0,-18),
		Size = UDim2.fromOffset(WINDOW_W + 36, WINDOW_H + 36),
		Image = GLOW_IMAGE,
		ImageColor3 = Color3.fromRGB(0, 0, 0),
		ImageTransparency = 0.6,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(49, 49, 450, 450),
		ZIndex = 0,
		Parent = root,
	})

	local window = create("Frame", {
		Name = "Window",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 0),
		Size = UDim2.fromOffset(WINDOW_W, WINDOW_H),
		ClipsDescendants = true,
		ZIndex = 1,
		Parent = root,
	})
	paint(window, "BackgroundColor3", "Background")
	local windowCorner = round(window, 24)

	local windowStroke=create("UIStroke",{Color = Color3.fromRGB(255, 255, 255), Transparency = 0.93, Thickness = 1, Parent = window})
	create("UIGradient", {
		Rotation = 90,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(1, 0.75),
		}),
		Parent = windowStroke,
	})
	create("UIGradient",{
		Rotation=90,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(148, 148, 148)),
		}),
		Parent = window,
	})

	local main = create("CanvasGroup", {
		Name = "Main",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(WINDOW_W, WINDOW_H),
		GroupTransparency = 1,
		Parent=window,
	})

	local handle = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, WINDOW_H + 12),
		Size = UDim2.fromOffset(130, 4),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		Parent = root,
	})
	roundFull(handle)

	connect(window:GetPropertyChangedSignal("Size"), function()
		local size=window.Size
		handle.Position=UDim2.new(0.5, 0, 0,size.Y.Offset + 12)
		shadow.Size = UDim2.fromOffset(size.X.Offset + 36,size.Y.Offset + 36)
	end)

	local pillContent = create("CanvasGroup", {
		Name = "PillContent",
		BackgroundTransparency = 1,
		Size=UDim2.fromOffset(PILL_W, PILL_H),
		GroupTransparency = 1,
		Visible = false,
		ZIndex = 10,
		Parent = window,
	})
	do

		local placedIcon = makeIcon(pillContent, "eye", 30, Theme.TextTitle)
		if placedIcon then
			placedIcon.AnchorPoint=Vector2.new(0.5,0.5)
			placedIcon.Position = UDim2.new(0, 31, 0.5, 0)
		else
			create("TextLabel",{
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(0.5,0.5),
				Position = UDim2.new(0, 31, 0.5,0),
				Size = UDim2.fromOffset(30, 30),
				Font = FONT_BOLD,
				TextSize = 20,
				Text = string.upper(string.sub(pillNameText, 1, 1)),
				TextColor3 = Theme.TextTitle,
				Parent = pillContent,
			})
		end

		local col = create("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 65, 0.5, -17),
			Size = UDim2.new(1,-91,0, 34),
			Parent = pillContent,
		})
		create("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 17),
			Font = FONT_BOLD,
			TextSize = 16,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Text = pillNameText,
			TextColor3=Theme.TextTitle,
			Parent = col,
		})
		create("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(0, 19),
			Size = UDim2.new(1, 0, 0,14),
			Font = FONT_MEDIUM,
			TextSize = 13,
			TextXAlignment=Enum.TextXAlignment.Left,
			Text = "Tap to show",
			TextColor3 = Theme.TextSub,
			Parent = col,
		})
	end

	local pillButton = create("TextButton", {
		BackgroundTransparency = 1,
		Text = "",
		Size = UDim2.fromScale(1, 1),
		Visible = false,
		ZIndex = 12,
		Parent=window,
	})

	local header = create("Frame",{
		Name = "Header",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, HEADER_H),
		Parent = main,
	})

	local titleRow = create("Frame", {
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.X,
		Position = UDim2.fromOffset(24, 13),
		Size=UDim2.new(0, 0,0, 27),
		Parent = header,
	})
	create("UIListLayout", {
		FillDirection=Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 11),
		Parent = titleRow,
	})

	local titleLabel = create("TextLabel", {
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.new(0, 0, 1, 0),
		Font = FONT_BOLD,
		TextSize = 21,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text=Settings.Name or "Rayfield",
		LayoutOrder = 1,
		Parent = titleRow,
	})
	paint(titleLabel, "TextColor3", "TextTitle")
	registerTr(titleLabel, Settings.Name or "Rayfield")

	if Settings.Badge then
		local badgeText = type(Settings.Badge) == "table" and (Settings.Badge.Text or "") or tostring(Settings.Badge)
		local badgeIcon = type(Settings.Badge) == "table" and Settings.Badge.Icon or nil
		local badge = create("Frame", {
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.new(0, 0,0, 26),
			LayoutOrder = 2,
			Parent = titleRow,
		})
		paint(badge, "BackgroundColor3", "BadgeBackground")
		roundFull(badge)
		padAll(badge, 0, 12,0, 11)
		create("UIListLayout",{
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0,6),
			Parent = badge,
		})
		if badgeIcon then
			local ic = makeIcon(badge, badgeIcon, 14, Theme.BadgeText)
			if ic then ic.LayoutOrder = 1 end
		end
		local bt = create("TextLabel", {
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.new(0,0, 1,0),
			Font = FONT_BOLD,
			TextSize = 13,
			Text = badgeText,
			LayoutOrder = 2,
			Parent = badge,
		})
		paint(bt,"TextColor3", "BadgeText")
	end

	local function contrastText(bg)
		local lum = 0.299 * bg.R + 0.587 * bg.G + 0.114 * bg.B
		return lum > 0.6 and Color3.fromRGB(28, 24, 12) or Color3.fromRGB(255, 255, 255)
	end

	local function createTag(tagSettings)
		tagSettings = normalizeProps(tagSettings)
		local tagColor = tagSettings.Color or Color3.fromRGB(255, 175, 15)
		local pill = create("Frame", {
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.new(0, 0, 0, 26),
			BackgroundColor3 = tagColor,
			LayoutOrder = 10 + (tonumber(tagSettings.Order) or 0),
			Parent = titleRow,
		})
		roundFull(pill)
		padAll(pill, 0, 12, 0, 11)
		create("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 6),
			Parent = pill,
		})
		local tagIcon = nil
		local function buildIcon(iconVal)
			if tagIcon then tagIcon:Destroy() tagIcon = nil end
			if iconVal and iconVal ~= "" and iconVal ~= 0 then
				tagIcon = makeIcon(pill, iconVal, 14, contrastText(tagColor))
				if tagIcon then tagIcon.LayoutOrder = 1 end
			end
		end
		buildIcon(tagSettings.Icon)
		local tagLabel = create("TextLabel", {
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.new(0, 0, 1, 0),
			Font = FONT_BOLD,
			TextSize = 13,
			Text = tagSettings.Text or tagSettings.Title or "",
			TextColor3 = contrastText(tagColor),
			LayoutOrder = 2,
			Parent = pill,
		})

		local Tag = {}
		function Tag:SetColor(c)
			if type(c) == "string" then return end
			tagColor = c
			pill.BackgroundColor3 = c
			tagLabel.TextColor3 = contrastText(c)
			if tagIcon then tagIcon.ImageColor3 = contrastText(c) end
		end
		function Tag:SetText(t)
			tagLabel.Text = tostring(t)
		end
		function Tag:SetIcon(i)
			buildIcon(i)
		end
		function Tag:Set(props)
			props = normalizeProps(props)
			if props.Color then Tag:SetColor(props.Color) end
			if props.Text or props.Title then Tag:SetText(props.Text or props.Title) end
			if props.Icon ~= nil then Tag:SetIcon(props.Icon) end
			if props.Order then pill.LayoutOrder = 10 + (tonumber(props.Order) or 0) end
		end
		function Tag:Remove()
			pill:Destroy()
		end
		return Tag
	end

	local subtitleLabel = create("TextLabel",{
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.X,
		Position = UDim2.fromOffset(24, 42),
		Size = UDim2.new(0,0,0, 15),
		Font=FONT_MEDIUM,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = Settings.Subtitle or "Rayfield Gen2",
		Parent = header,
	})
	paint(subtitleLabel, "TextColor3", "TextSub")
	registerTr(subtitleLabel, Settings.Subtitle or "Rayfield Gen2")

	local buttonRow = create("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1,0),
		Position = UDim2.new(1, -16, 0, 15),
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.new(0, 0, 0,30),
		Parent = header,
	})
	create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		SortOrder=Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 6),
		Parent = buttonRow,
	})

	local function headerButton(order,lucideNames)
		local btnSize = TOUCH_UI and 38 or 30
		local btn = create("TextButton", {
			BackgroundTransparency = 1,
			Text = "",
			Size = UDim2.fromOffset(btnSize, btnSize),
			LayoutOrder = order,
			Parent = buttonRow,
		})
		local icon = create("ImageLabel", {
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5,0.5),
			Size = UDim2.fromOffset(19,19),
			ImageColor3 = Theme.TextSub,
			Parent = btn,
		})
		applyLucide(icon, lucideNames)
		btn.MouseEnter:Connect(function()
			tween(icon, TI_FAST, {ImageColor3=Theme.TextTitle})
		end)
		btn.MouseLeave:Connect(function()
			tween(icon, TI_FAST,{ImageColor3 = Theme.TextSub})
		end)
		return btn, icon
	end

	local searchButton, searchButtonIcon = headerButton(1, {"text-search", "search"})
	local settingsButton, settingsButtonIcon = headerButton(2, {"settings"})
	local minimizeButton,minimizeIcon = headerButton(3, {"minus"})
	local closeButton = headerButton(4,{"x"})

	local body = create("Frame", {
		Name = "Body",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(14,HEADER_H),
		Size = UDim2.new(1,-28,1, -HEADER_H - 14),
		Parent = main,
	})

	local TABBAR_H = 48
	local tabBar = create("ScrollingFrame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1,0,0, TABBAR_H),
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.X,
		ScrollingDirection = Enum.ScrollingDirection.X,
		ScrollBarThickness = 0,
		BorderSizePixel = 0,
		Parent = body,
	})
	create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment=Enum.VerticalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 8),
		Parent = tabBar,
	})

	create("UIPadding", {
		PaddingLeft = UDim.new(0, 2),
		PaddingRight = UDim.new(0, 2),
		Parent = tabBar,
	})

	local searchHolder = create("Frame", {
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Position = UDim2.fromOffset(0, TABBAR_H + 8),
		Size=UDim2.new(1,0, 0, 0),
		Parent = body,
	})
	local searchCard = create("Frame", {
		Size = UDim2.new(1, 0, 0,40),
		BackgroundTransparency = 0.35,
	})
	paint(searchCard,"BackgroundColor3", "SearchBox")
	round(searchCard,12)
	searchCard.Parent = searchHolder
	local searchIconHolder = create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(40, 40),
		Parent = searchCard,
	})
	do
		local sIcon = makeIcon(searchIconHolder, "text-search", 18,Theme.TextSub)
		if sIcon then
			sIcon.AnchorPoint = Vector2.new(0.5, 0.5)
			sIcon.Position = UDim2.fromScale(0.5, 0.5)
		end
	end
	local searchBox = create("TextBox", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(42, 0),
		Size = UDim2.new(1, -50, 1, 0),
		Font = FONT_MEDIUM,
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Left,
		PlaceholderText = "Search",
		PlaceholderColor3 = Theme.TextMuted,
		Text = "",
		ClearTextOnFocus = false,
		Parent = searchCard,
	})
	paint(searchBox, "TextColor3", "TextBody")

	local pagesHolder = create("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, TABBAR_H + 10),
		Size = UDim2.new(1, 0, 1,-(TABBAR_H + 10)),
		Parent = body,
	})

	local Window = {}
	function Window:CreateTag(tagSettings)
		return createTag(tagSettings)
	end
	local tabs = {}
	local currentTab = nil
	local settingsOpen = false
	local settingsEntry = nil
	local hidden = false
	local minimized = false
	local searchOpen = false
	local morphing = false
	local storedPosition = nil
	local unlockCursor = false

	connect(RunService.RenderStepped,function()
		if unlockCursor and UserInputService.MouseEnabled and not hidden and not destroyed then
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default
			UserInputService.MouseIconEnabled = true
		end
	end)

	local function layoutSearch(open)
		searchOpen = open
		local sh = open and 48 or 0
		tween(searchHolder, TI_MED, {Size = UDim2.new(1, 0, 0, open and 40 or 0)})
		tween(pagesHolder, TI_MED, {
			Position = UDim2.fromOffset(0, TABBAR_H + 10 + sh),
			Size = UDim2.new(1, 0, 1, -(TABBAR_H + 10 + sh)),
		})
		tween(searchButtonIcon, TI_FAST, {ImageColor3 = open and Theme.TextTitle or Theme.TextSub})
		if open then
			task.delay(0.12, function() searchBox:CaptureFocus() end)
		else
			searchBox.Text = ""
			searchBox:ReleaseFocus()
		end
	end

	local function currentPage()
		if settingsOpen and settingsEntry then return settingsEntry.Page end
		return currentTab and currentTab.Page or nil
	end

	local function applySearchFilter(query)
		local page = currentPage()
		if not page then return end
		query = string.lower(query or "")
		for _, item in ipairs(page:GetChildren()) do
			if item:IsA("GuiObject") then
				local searchName = item:GetAttribute("SearchName")
				local structural = item:GetAttribute("Structural")
				local composite = item:GetAttribute("Composite")
				if query == "" then
					item.Visible = true
				elseif structural then
					item.Visible = false
				elseif composite then

					local matched = false
					for _, d in ipairs(item:GetDescendants()) do
						local sn = d:GetAttribute("SearchName")
						if sn and string.find(string.lower(sn), query,1, true) then
							matched=true
							break
						end
					end
					item.Visible=matched
				elseif searchName then
					item.Visible = string.find(string.lower(searchName), query, 1, true) ~= nil
				end
			end
		end
	end

	connect(searchBox:GetPropertyChangedSignal("Text"), function()
		applySearchFilter(searchBox.Text)
	end)

	searchButton.MouseButton1Click:Connect(function()
		layoutSearch(not searchOpen)
		if not searchOpen then applySearchFilter("") end
	end)

	local function buildPage()
		local pageWrapper = create("CanvasGroup", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			GroupTransparency = 0,
			Visible = false,
			Parent = pagesHolder,
		})

		local fadeGrad = create("UIGradient",{
			Rotation = 90,
			Parent = pageWrapper,
		})
		local page = create("ScrollingFrame", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			CanvasSize = UDim2.new(0, 0, 0,0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			ScrollBarThickness = 0,
			BorderSizePixel = 0,
			Parent = pageWrapper,
		})
		create("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 8),
			Parent = page,
		})
		padAll(page, 2,5, 16, 1)

		local EDGE = 0.05
		local function updateFade()
			local vh = page.AbsoluteWindowSize.Y
			if vh <= 0 then return end
			local pos = page.CanvasPosition.Y
			local maxScroll = math.max(0, page.AbsoluteCanvasSize.Y - vh)
			local topT = math.clamp(pos / 24, 0, 1)
			local botT = math.clamp((maxScroll - pos) / 24, 0, 1)
			if topT <= 0.001 and botT <= 0.001 then
				fadeGrad.Transparency = NumberSequence.new(0)
			else
				fadeGrad.Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, topT),
					NumberSequenceKeypoint.new(EDGE, 0),
					NumberSequenceKeypoint.new(1 - EDGE,0),
					NumberSequenceKeypoint.new(1, botT),
				})
			end
		end
		page:GetPropertyChangedSignal("CanvasPosition"):Connect(updateFade)
		page:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(updateFade);
		page:GetPropertyChangedSignal("AbsoluteWindowSize"):Connect(updateFade)
		task.defer(updateFade)
		return page,pageWrapper
	end

	local function showPage(entry)
		for _, other in ipairs(tabs) do
			if other ~= entry then other.Wrapper.Visible = false end
		end
		if settingsEntry and settingsEntry ~= entry then
			settingsEntry.Wrapper.Visible = false
		end
		local wrapper = entry.Wrapper
		wrapper.Visible = true
		wrapper.GroupTransparency = 1
		wrapper.Position = UDim2.fromOffset(0, 12)
		tween(wrapper,TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),{GroupTransparency = 0})
		tween(wrapper, TweenInfo.new(0.32,Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2.fromOffset(0, 0)})
	end

	local function styleTabPills()
		for _,other in ipairs(tabs) do
			local active = (not settingsOpen) and other == currentTab
			tween(other.Pill, TI_FAST,{BackgroundColor3 = active and Color3.fromRGB(46, 46, 46) or Theme.CardInset, BackgroundTransparency = active and 0 or 0.35})
			tween(other.PillLabel, TI_FAST, {TextColor3 = active and Theme.TextTitle or Theme.TextSub})
			if other.PillIcon then
				tween(other.PillIcon, TI_FAST, {ImageColor3 = active and Theme.TextTitle or Theme.TextSub})
			end
			tween(other.PillStroke,TI_FAST, {Transparency = active and 0.55 or 0.68})
		end
		tween(settingsButtonIcon, TI_FAST,{ImageColor3 = settingsOpen and Theme.TextTitle or Theme.TextSub, Rotation = settingsOpen and 90 or 0})
	end

	local function selectTab(tab)
		if currentTab == tab and not settingsOpen then return end
		settingsOpen = false
		currentTab = tab
		styleTabPills()
		showPage(tab)
		if searchOpen then
			searchBox.Text = ""
			applySearchFilter("")
		end
	end

	local elementOrder = 0
	local function nextOrder()
		elementOrder = elementOrder + 1
		return elementOrder
	end

	local function runCallback(callback, ...)
		if type(callback) ~= "function" then return end
		local ok, err = pcall(callback, ...)
		if not ok then
			if not SECURE then
				warn("Rayfield Gen2 | Callback error: " .. tostring(err))
				RayfieldLibrary:Notify({Title = "Callback Error", Content=tostring(err), Duration = 4, Image = "triangle-alert"})
			end
		end
	end

	local function cardBase(card)
		round(card, 14)
		create("UIGradient", {
			Rotation = 90,
			Color=ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(226, 226, 226)),
			Parent = card,
		})
	end

	local function makeCard(page, name, icon, height)
		local card = create("Frame", {
			Size = UDim2.new(1, 0, 0, height or 50),
			LayoutOrder = nextOrder(),
			Parent = page,
		})
		card:SetAttribute("SearchName", name or "")
		paint(card, "BackgroundColor3", "Card")
		cardBase(card)

		local textX = 17
		if icon then
			local ic = makeIcon(card, icon, 18, Theme.TextTitle, 0.04)
			if ic then
				ic.AnchorPoint = Vector2.new(0, 0.5)
				ic.Position = UDim2.new(0, 16,0.5, 0)
				textX = 44
			end
		end
		local label = create("TextLabel",{
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, textX, 0.5, 0),
			Size = UDim2.new(1,-textX - 16, 0, 18),
			Font = FONT_MEDIUM,
			TextSize = 16,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Text = name or "",
			Parent = card,
		})
		paint(label, "TextColor3", "TextBody")
		registerTr(label, name or "")
		return card, label, textX
	end

	local function makeDescription(page, card,text)
		if not text or text == "" then return nil end
		local desc = create("TextLabel", {
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.new(1, -30, 0, 0),
			Font = FONT_REGULAR,
			TextSize = 13,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = text,
			LayoutOrder = nextOrder(),
			Parent = page,
		})
		desc:SetAttribute("SearchName", (card:GetAttribute("SearchName") or "") .. " " .. text)
		desc:SetAttribute("Attached", true)
		padAll(desc, 0, 0, 5, 16)
		paint(desc, "TextColor3", "TextMuted");
		return desc
	end

	local function hoverable(card, base, hover)
		card.MouseEnter:Connect(function()
			tween(card, TI_FAST, {BackgroundColor3=hover or Theme.CardHover})
		end)
		card.MouseLeave:Connect(function()
			tween(card, TI_FAST, {BackgroundColor3 = base or Theme.Card})
		end)
	end

	local function buildTabAPI(page, compact)
		local Tab = {}
		Tab.Page=page

		local function descFor(card, text)
			if compact then return nil end
			return makeDescription(page, card, text)
		end

		function Tab:CreateSection(sectionName)
			local sectionIcon = nil
			if type(sectionName) == "table" then
				local p = normalizeProps(sectionName)
				sectionIcon = p.Icon
				sectionName = p.Name or p.Title
			end
			local holder = create("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1,0, 0, 30),
				LayoutOrder = nextOrder(),
				Parent = page,
			})
			holder:SetAttribute("Structural", true)
			local labelX = 10
			if sectionIcon then
				local ic = makeIcon(holder, sectionIcon, 14, Theme.TextSub)
				if ic then
					ic.AnchorPoint = Vector2.new(0, 1)
					ic.Position = UDim2.new(0, 10, 1, -4)
					labelX = 30
				end
			end
			local label = create("TextLabel", {
				BackgroundTransparency = 1,
				AnchorPoint=Vector2.new(0, 1),
				Position = UDim2.new(0,labelX, 1, -3),
				Size = UDim2.new(1, -labelX - 10, 0, 16),
				Font = FONT_MEDIUM,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
				Text = sectionName or "",
				Parent = holder,
			})
			paint(label, "TextColor3","TextSub")
			registerTr(label, sectionName or "")
			local SectionValue = {}
			function SectionValue:Set(newName)
				label.Text = newName
			end
			return SectionValue
		end

		function Tab:CreateDivider()
			local holder = create("Frame",{
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 8),
				LayoutOrder = nextOrder(),
				Parent = page,
			})
			holder:SetAttribute("Structural",true)
			create("Frame", {
				AnchorPoint = Vector2.new(0.5,0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.new(1, -12,0,1),
				BackgroundColor3 = Color3.fromRGB(255, 255,255),
				BackgroundTransparency = 0.9,
				BorderSizePixel = 0,
				Parent = holder,
			})
			local DividerValue = {}
			function DividerValue:Set(visible)
				holder.Visible = visible
			end
			return DividerValue
		end

		function Tab:CreateLabel(text, icon, color, _ignoreTheme)
			local card, label = makeCard(page, text, icon, 46)
			card.BackgroundTransparency = 0.5
			if color and typeof(color) == "Color3" then
				label.TextColor3 = color
			else
				label.TextColor3 = Theme.TextSub
			end
			local LabelValue = {}
			function LabelValue:Set(newText, _newIcon,newColor)
				label.Text = newText or label.Text
				if newColor and typeof(newColor) == "Color3" then
					label.TextColor3 = newColor
				end
				card:SetAttribute("SearchName", newText or "")
			end
			return LabelValue
		end

		function Tab:CreateParagraph(ParagraphSettings)
			ParagraphSettings = ParagraphSettings or {}
			local card = create("Frame",{
				AutomaticSize = Enum.AutomaticSize.Y,
				Size = UDim2.new(1,0, 0,0),
				LayoutOrder = nextOrder(),
				Parent=page,
			})
			card:SetAttribute("SearchName", (ParagraphSettings.Title or "") .. " " .. (ParagraphSettings.Content or ""))
			paint(card, "BackgroundColor3", "Card")
			cardBase(card)
			padAll(card, 14, 17, 14, 17)
			create("UIListLayout",{
				FillDirection=Enum.FillDirection.Vertical,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 4),
				Parent = card,
			})
			local title = create("TextLabel", {
				BackgroundTransparency = 1,
				AutomaticSize = Enum.AutomaticSize.Y,
				Size = UDim2.new(1, 0, 0, 0),
				Font = FONT_BOLD,
				TextSize = 16,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left,
				Text = ParagraphSettings.Title or "",
				LayoutOrder = 1,
				Parent = card,
			})
			paint(title, "TextColor3", "TextTitle")
			local content = create("TextLabel", {
				BackgroundTransparency = 1,
				AutomaticSize = Enum.AutomaticSize.Y,
				Size = UDim2.new(1, 0, 0, 0),
				Font = FONT_REGULAR,
				TextSize=14,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left,
				Text = ParagraphSettings.Content or "",
				LayoutOrder = 2,
				Parent = card,
			})
			paint(content,"TextColor3", "TextSub")
			local ParagraphValue = {}
			function ParagraphValue:Set(newSettings)
				newSettings = newSettings or {}
				title.Text = newSettings.Title or title.Text
				content.Text = newSettings.Content or content.Text
				card:SetAttribute("SearchName", title.Text .. " " .. content.Text)
			end
			return ParagraphValue
		end

		function Tab:CreateFAQ(FAQSettings)
			FAQSettings = FAQSettings or {}
			local FAQValue = {Items = {}}
			local closers = {}
			for _, item in ipairs(FAQSettings.Items or {}) do
				local question = item.Question or ""
				local answer = item.Answer or ""
				local card = create("Frame", {
					Size = UDim2.new(1, 0, 0, 54),
					LayoutOrder = nextOrder(),
					ClipsDescendants = true,
					Parent = page,
				})
				card:SetAttribute("SearchName", question .. " " .. answer)
				paint(card, "BackgroundColor3", "Card")
				cardBase(card)
				hoverable(card)
				local qLabel = create("TextLabel", {
					BackgroundTransparency = 1,
					Position = UDim2.fromOffset(17, 0),
					Size = UDim2.new(1, -60, 0, 54),
					Font = FONT_MEDIUM,
					TextSize = 15,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextTruncate = Enum.TextTruncate.AtEnd,
					Text = question,
					Parent = card,
				})
				paint(qLabel, "TextColor3", "TextTitle")
				local plus = makeIcon(card, "plus", 16, Theme.TextSub, 0.15)
				plus.AnchorPoint = Vector2.new(1, 0.5)
				plus.Position = UDim2.new(1, -16, 0, 27)
				local aLabel = create("TextLabel", {
					BackgroundTransparency = 1,
					Position = UDim2.fromOffset(17, 54),
					Size = UDim2.new(1, -34, 0, 0),
					Font = FONT_REGULAR,
					TextSize = 14,
					TextWrapped = true,
					TextTransparency = 1,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Top,
					Text = answer,
					Parent = card,
				})
				paint(aLabel, "TextColor3", "TextSub")
				local open = false
				local function setOpen(state)
					if open == state then return end
					open = state
					if open then
						local ah = measureWrapped(answer, 14, FONT_REGULAR, math.max(card.AbsoluteSize.X / currentUiScale() - 40, 50))
						aLabel.Size = UDim2.new(1, -34, 0, ah + 4)
						aLabel.Position = UDim2.fromOffset(17, 58)
						tween(card, TI_MORPH, {Size = UDim2.new(1, 0, 0, 54 + ah + 16)})
						tween(plus, TI_MORPH, {Rotation = 135, ImageColor3 = Theme.AccentSoft, ImageTransparency = 0})
						tween(aLabel, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0.1), {TextTransparency = 0.1, Position = UDim2.fromOffset(17, 50)})
					else
						tween(card, TI_MORPH, {Size = UDim2.new(1, 0, 0, 54)})
						tween(plus, TI_MORPH, {Rotation = 0, ImageColor3 = Theme.TextSub, ImageTransparency = 0.15})
						tween(aLabel, TI_FAST, {TextTransparency = 1})
					end
				end
				closers[#closers + 1] = function() setOpen(false) end
				local function openExclusive()
					for _, c in ipairs(closers) do c() end
					setOpen(true)
				end
				local clicker = create("TextButton", {
					BackgroundTransparency = 1,
					Text = "",
					Size = UDim2.fromScale(1, 1),
					Parent = card,
				})
				clicker.MouseButton1Click:Connect(function()
					if open then setOpen(false) else openExclusive() end
				end)
				FAQValue.Items[#FAQValue.Items + 1] = {
					Open = openExclusive,
					Close = function() setOpen(false) end,
				}
			end
			return FAQValue
		end

		function Tab:CreateStat(StatSettings)
			StatSettings = normalizeProps(StatSettings, "Value")
			if compact then
				local card = create("Frame", {
					Size = UDim2.new(1, 0, 0, 50),
					LayoutOrder = nextOrder(),
					Parent = page,
				})
				card:SetAttribute("SearchName", StatSettings.Name or "")
				card.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				round(card, 14)
				create("UIGradient", {
					Rotation = 165,
					Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0,Color3.fromRGB(88, 152,122)),
						ColorSequenceKeypoint.new(0.55,Color3.fromRGB(46,94, 75)),
						ColorSequenceKeypoint.new(1, Color3.fromRGB(24, 52, 42)),
					}),
					Parent = card,
				})
				local textX=16
				if StatSettings.Icon then
					local ic = makeIcon(card, StatSettings.Icon, 18, Color3.fromRGB(240, 252, 246))
					if ic then
						ic.AnchorPoint = Vector2.new(0, 0.5)
						ic.Position=UDim2.new(0, 15, 0.5,0)
						textX = 42
					end
				end
				local nameLabel = create("TextLabel",{
					BackgroundTransparency = 1,
					AnchorPoint = Vector2.new(0,0.5),
					Position=UDim2.new(0, textX, 0.5, 0),
					Size = UDim2.new(0.55, -textX, 0, 18),
					Font = FONT_BOLD,
					TextSize = 16,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextTruncate=Enum.TextTruncate.AtEnd,
					TextColor3 = Color3.fromRGB(244, 253,248),
					Text = StatSettings.Name or "",
					Parent = card,
				})
				local rightLabel=create("TextLabel", {
					BackgroundTransparency = 1,
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -16, 0.5, 0),
					Size = UDim2.new(0.4, -16, 0, 18),
					Font = FONT_BOLD,
					TextSize = 16,
					TextXAlignment = Enum.TextXAlignment.Right,
					TextTruncate = Enum.TextTruncate.AtEnd,
					TextColor3 = Color3.fromRGB(255, 255, 255),
					Text = tostring(StatSettings.Value or StatSettings.Delta or ""),
					Parent = card,
				})
				local StatValue = {}
				local lastValue = StatSettings.Value
				local lastDelta = StatSettings.Delta
				local rightSet = odometerValue(rightLabel,lastValue or lastDelta)
				function StatValue:Set(newSettings)
					if type(newSettings) ~= "table" then newSettings = {Value = newSettings} end
					if newSettings.Name then nameLabel.Text = newSettings.Name end
					if newSettings.Value ~= nil then lastValue = newSettings.Value end
					if newSettings.Delta ~= nil then lastDelta = newSettings.Delta end
					rightSet(lastValue or lastDelta or "")
				end
				return StatValue
			end

			local card = create("Frame", {
				Size = UDim2.new(1, 0, 0, 96),
				LayoutOrder = nextOrder(),
				Parent = page,
			})
			card:SetAttribute("SearchName", StatSettings.Name or "")
			card.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			round(card, 14)
			create("UIGradient",{
				Rotation = 165,
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0,Color3.fromRGB(88, 152,122)),
					ColorSequenceKeypoint.new(0.5,Color3.fromRGB(46, 94, 75)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(24, 52, 42)),
				}),
				Parent = card,
			})

			local topX = 17
			if StatSettings.Icon then
				local ic = makeIcon(card, StatSettings.Icon, 21,Color3.fromRGB(238, 252, 245))
				if ic then
					ic.Position = UDim2.fromOffset(16, 14)
					topX = 46
				end
			end
			local nameLabel = create("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(topX, 15),
				Size = UDim2.new(1, -topX - 16, 0,20),
				Font = FONT_BOLD,
				TextSize=17,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextColor3=Color3.fromRGB(242, 252, 247),
				Text = StatSettings.Name or "",
				Parent = card,
			})
			local valueLabel = create("TextLabel",{
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(0, 1),
				Position = UDim2.new(0,17,1, -12),
				Size = UDim2.new(0.6, 0, 0, 28),
				Font = FONT_BOLD,
				TextSize = 25,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				Text = tostring(StatSettings.Value or ""),
				Parent = card,
			})
			local deltaLabel = create("TextLabel", {
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(1, 1),
				Position = UDim2.new(1, -17, 1, -15),
				Size = UDim2.new(0.35, 0, 0, 18),
				Font = FONT_BOLD,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Right,
				TextColor3 = Color3.fromRGB(202,242, 221),
				Text = tostring(StatSettings.Delta or ""),
				Parent = card,
			})
			local setValue = odometerValue(valueLabel,StatSettings.Value)
			local StatValue = {}
			function StatValue:Set(newSettings)
				if type(newSettings) ~= "table" then newSettings = {Value = newSettings} end
				if newSettings.Name then nameLabel.Text = newSettings.Name end
				if newSettings.Value ~= nil then setValue(newSettings.Value) end
				if newSettings.Delta ~= nil then deltaLabel.Text = tostring(newSettings.Delta) end
			end
			return StatValue
		end

		local chartPalette = {rgb(150, 222, 186), rgb(70, 168, 120), rgb(44, 108, 80), rgb(26, 62, 47), rgb(214, 240, 226)}

		local function chartShell(settings, h)
			local card = create("Frame", {
				Size = UDim2.new(1, 0, 0, h),
				LayoutOrder = nextOrder(),
				ClipsDescendants = true,
				Parent = page,
			})
			card:SetAttribute("SearchName", settings.Name or "")
			paint(card, "BackgroundColor3", "Card")
			cardBase(card)
			local textX = 17
			if settings.Icon then
				local ic = makeIcon(card, settings.Icon, 18, Theme.TextTitle, 0.04)
				if ic then
					ic.Position = UDim2.fromOffset(16, 13)
					textX = 44
				end
			end
			local nameLabel = create("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(textX, 13),
				Size = UDim2.new(0.5, -textX, 0, 18),
				Font = FONT_BOLD,
				TextSize = 16,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Text = settings.Name or "",
				Parent = card,
			})
			paint(nameLabel, "TextColor3", "TextTitle")
			local valueLabel = create("TextLabel", {
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -17, 0, 11),
				Size = UDim2.new(0.4, 0, 0, 22),
				Font = FONT_BOLD,
				TextSize = 20,
				TextXAlignment = Enum.TextXAlignment.Right,
				Text = "",
				Parent = card,
			})
			paint(valueLabel, "TextColor3", "TextTitle")
			return card, nameLabel, valueLabel
		end

		local function replayOnVisible(card, entrance)
			local function chainVisible()
				local a = card
				while a and not a:IsA("ScreenGui") do
					if a:IsA("GuiObject") and not a.Visible then return false end
					a = a.Parent
				end
				return true
			end
			task.defer(function()
				local node = card.Parent
				while node and not node:IsA("ScreenGui") do
					if node:IsA("GuiObject") then
						local nn = node
						nn:GetPropertyChangedSignal("Visible"):Connect(function()
							if nn.Visible and chainVisible() then task.defer(entrance) end
						end)
					end
					node = node.Parent
				end
				if chainVisible() then entrance() end
			end)
		end

		local function lineSeg(parent, x1, y1, x2, y2, thick, z)
			local s = create("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BorderSizePixel = 0,
				ZIndex = z or 2,
				Parent = parent,
			})
			roundFull(s)
			local dx, dy = x2 - x1, y2 - y1
			s.Position = UDim2.fromOffset(x1 + dx / 2, y1 + dy / 2)
			s.Size = UDim2.fromOffset(math.ceil(math.sqrt(dx * dx + dy * dy)) + 1, thick)
			s.Rotation = math.deg(math.atan2(dy, dx))
			return s
		end

		function Tab:CreateChart(ChartSettings)
			ChartSettings = ChartSettings or {}
			local points = {}
			for _, v in ipairs(ChartSettings.Points or {}) do
				local n = tonumber(v)
				if n then points[#points + 1] = n end
			end
			if #points == 0 then points = {0, 0} end
			if #points == 1 then points = {points[1], points[1]} end
			local prefix = ChartSettings.Prefix or ""
			local suffix = ChartSettings.Suffix or ""
			local decimals = ChartSettings.Decimals or 0
			local filled = ChartSettings.Filled ~= false
			local smooth = ChartSettings.Smooth == true
			local showDots = ChartSettings.Dots == true or (ChartSettings.Dots == nil and not smooth)
			local maxPoints = ChartSettings.MaxPoints or math.max(#points, 12)

			local cardH = compact and 118 or 152
			local plotTop = compact and 38 or 44
			local card = create("Frame", {
				Size = UDim2.new(1, 0, 0, cardH),
				LayoutOrder = nextOrder(),
				ClipsDescendants = true,
				Parent = page,
			})
			card:SetAttribute("SearchName", ChartSettings.Name or "")
			paint(card, "BackgroundColor3", "Card")
			cardBase(card)

			local textX = 17
			if ChartSettings.Icon then
				local ic = makeIcon(card, ChartSettings.Icon, 18, Theme.TextTitle, 0.04)
				if ic then
					ic.Position = UDim2.fromOffset(16, compact and 11 or 13)
					textX = 44
				end
			end
			local nameLabel = create("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(textX, compact and 11 or 13),
				Size = UDim2.new(0.5, -textX, 0, 18),
				Font = FONT_BOLD,
				TextSize = 16,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Text = ChartSettings.Name or "",
				Parent = card,
			})
			paint(nameLabel, "TextColor3", "TextTitle")
			local valueLabel = create("TextLabel", {
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -17, 0, compact and 9 or 11),
				Size = UDim2.new(0.4, 0, 0, 22),
				Font = FONT_BOLD,
				TextSize = compact and 17 or 20,
				TextXAlignment = Enum.TextXAlignment.Right,
				Text = "",
				Parent = card,
			})
			paint(valueLabel, "TextColor3", "TextTitle")

			local plot = create("Frame", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(17, plotTop),
				Size = UDim2.new(1, -34, 1, -plotTop - 14),
				Parent = card,
			})
			create("Frame", {
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 0.93,
				BorderSizePixel = 0,
				Position = UDim2.new(0, 0, 0.5, 0),
				Size = UDim2.new(1, 0, 0, 1),
				Parent = plot,
			})
			create("Frame", {
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 0.93,
				BorderSizePixel = 0,
				Position = UDim2.new(0, 0, 1, -1),
				Size = UDim2.new(1, 0, 0, 1),
				Parent = plot,
			})
			local hairline = create("Frame", {
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 0.82,
				BorderSizePixel = 0,
				AnchorPoint = Vector2.new(0.5, 0),
				Size = UDim2.new(0, 1, 1, 0),
				Visible = false,
				ZIndex = 2,
				Parent = plot,
			})

			local fillHolder = create("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				Parent = plot,
			})
			local segHolder = create("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				ZIndex = 3,
				Parent = plot,
			})
			local segCanvas = create("Frame", {
				BackgroundTransparency = 1,
				Parent = segHolder,
			})
			local dotHolder = create("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				ZIndex = 4,
				Parent = plot,
			})

			local dots, segs, cols, colTargets = {}, {}, {}, {}
			local xsCache, ysCache = {}, {}
			local hoverIdx = nil

			local function fmt(n)
				local str = decimals > 0 and string.format("%." .. decimals .. "f", n) or tostring(math.floor(n + 0.5))
				return prefix .. commafy(str) .. suffix
			end
			local setValue = odometerValue(valueLabel, fmt(points[#points]))

			local function redraw(animate)
				local w, h = plot.AbsoluteSize.X / currentUiScale(), plot.AbsoluteSize.Y / currentUiScale()
				if w < 24 or h < 24 then return end
				segCanvas.Size = UDim2.fromOffset(w, h)
				local n = #points
				local lo, hi = points[1], points[1]
				for _, v in ipairs(points) do
					if v < lo then lo = v end
					if v > hi then hi = v end
				end
				local range = hi - lo
				if range == 0 then range = math.max(math.abs(hi), 1) end
				local edgePad = (smooth and 3 or 4) / 2 + 1.5
				for i = 1, n do
					xsCache[i] = edgePad + (i - 1) / (n - 1) * (w - edgePad * 2)
					ysCache[i] = math.floor(10 + (1 - (points[i] - lo) / range) * (h - 22) + 0.5)
				end
				for i = #xsCache, n + 1, -1 do
					xsCache[i] = nil
					ysCache[i] = nil
				end

				local rxs, rys = xsCache, ysCache
				if smooth and n >= 3 then
					rxs, rys = {}, {}
					for i = 1, n - 1 do
						local x0 = xsCache[i > 1 and i - 1 or 1]
						local y0 = ysCache[i > 1 and i - 1 or 1]
						local x1, y1 = xsCache[i], ysCache[i]
						local x2, y2 = xsCache[i + 1], ysCache[i + 1]
						local x3 = xsCache[i + 2] or x2
						local y3 = ysCache[i + 2] or y2
						local sub = math.clamp(math.ceil((x2 - x1) / 3), 8, 36)
						for tstep = 0, sub - 1 do
							local a = tstep / sub
							rxs[#rxs + 1] = catmull(x0, x1, x2, x3, a)
							rys[#rys + 1] = math.clamp(catmull(y0, y1, y2, y3, a), 2, h - 2)
						end
					end
					rxs[#rxs + 1] = xsCache[n]
					rys[#rys + 1] = ysCache[n]
				end
				local rn = #rxs

				for i = #dots, n + 1, -1 do
					dots[i]:Destroy()
					dots[i] = nil
				end
				for i = #segs, rn, -1 do
					segs[i]:Destroy()
					segs[i] = nil
				end

				for i = 1, n do
					local d = dots[i]
					local fresh = not d
					if fresh then
						d = create("Frame", {
							AnchorPoint = Vector2.new(0.5, 0.5),
							Size = UDim2.fromOffset(10, 10),
							ZIndex = 4,
							Parent = dotHolder,
						})
						paint(d, "BackgroundColor3", "Knob")
						roundFull(d)
						d.Visible = showDots
						dots[i] = d
					end
					local target = UDim2.fromOffset(xsCache[i], ysCache[i])
					if fresh then
						d.Position = target
						if animate then
							d.Size = UDim2.fromOffset(0, 0)
							task.delay(0.12, function()
								tween(d, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.fromOffset(10, 10)})
							end)
						end
					elseif animate then
						tween(d, TI_MORPH, {Position = target})
					else
						d.Position = target
					end
				end

				for i = 1, rn - 1 do
					local s = segs[i]
					local fresh = not s
					if fresh then
						s = create("Frame", {
							AnchorPoint = Vector2.new(0.5, 0.5),
							BorderSizePixel = 0,
							ZIndex = 3,
							Parent = segCanvas,
						})
						paint(s, "BackgroundColor3", "AccentSoft")
						roundFull(s)
						segs[i] = s
					end
					local dx = rxs[i + 1] - rxs[i]
					local dy = rys[i + 1] - rys[i]
					local len = math.max(math.sqrt(dx * dx + dy * dy), 0.001)
					local ov = smooth and 3 or 4
					local cxx, cyy = rxs[i] + dx / 2, rys[i] + dy / 2
					if rn == 2 then
						ov = 0
					elseif i == 1 or i == rn - 1 then
						local push = (i == 1 and ov or -ov) / 4
						cxx = cxx + dx / len * push
						cyy = cyy + dy / len * push
						ov = ov / 2
					end
					local props = {
						Position = UDim2.fromScale(cxx / w, cyy / h),
						Size = UDim2.fromOffset(math.ceil(len + ov), 3),
						Rotation = math.deg(math.atan2(dy, dx)),
					}
					if animate and not fresh then
						tween(s, TI_MORPH, props)
					else
						s.Position = props.Position
						s.Size = props.Size
						s.Rotation = props.Rotation
					end
				end

				if filled then
					local colW = 3
					local fillX = rxs[1]
					local count = math.max(math.ceil((rxs[rn] - fillX) / colW), 1)
					for i = #cols, count + 1, -1 do
						cols[i]:Destroy()
						cols[i] = nil
					end
					local seg = 1
					for c = 1, count do
						local f = cols[c]
						local fresh = not f
						if fresh then
							f = create("Frame", {
								AnchorPoint = Vector2.new(0, 1),
								BorderSizePixel = 0,
								BackgroundTransparency = 0.12,
								Parent = fillHolder,
							})
							paint(f, "BackgroundColor3", "AccentDark")
							create("UIGradient", {
								Rotation = 90,
								Transparency = NumberSequence.new(0, 0.78),
								Parent = f,
							})
							cols[c] = f
						end
						local left = fillX + (c - 1) * colW
						local cw = math.min(colW, rxs[rn] - left)
						local cx = left + cw / 2
						while seg < rn - 1 and rxs[seg + 1] < cx do seg = seg + 1 end
						local x1, x2 = rxs[seg], rxs[seg + 1]
						local a = math.clamp((cx - x1) / math.max(x2 - x1, 1), 0, 1)
						local y = rys[seg] + (rys[seg + 1] - rys[seg]) * a
						local props = {
							Position = UDim2.fromOffset(left, h - 1),
							Size = UDim2.fromOffset(math.max(cw, 1), math.max(h - 1 - y, 0)),
						}
						colTargets[c] = props.Size
						if animate and not fresh then
							tween(f, TI_MORPH, props)
						else
							f.Position = props.Position
							f.Size = props.Size
						end
					end
				end
			end

			local function applyHover(i)
				if hoverIdx == i then return end
				if hoverIdx and dots[hoverIdx] then
					dots[hoverIdx].Size = UDim2.fromOffset(10, 10)
					dots[hoverIdx].BackgroundColor3 = Theme.Knob
					dots[hoverIdx].Visible = showDots
				end
				hoverIdx = i
				local d = i and dots[i]
				if d then
					d.Size = UDim2.fromOffset(14, 14)
					d.BackgroundColor3 = Theme.AccentSoft
					d.Visible = true
					hairline.Position = UDim2.fromOffset(xsCache[i], 0)
					hairline.Visible = true
					setValue(fmt(points[i]))
				else
					hairline.Visible = false
					setValue(fmt(points[#points]))
				end
			end

			local function scrub(input)
				if #xsCache < 2 then return end
				local rx = (input.Position.X - plot.AbsolutePosition.X) / currentUiScale()
				local best, bestDist = nil, math.huge
				for i = 1, #points do
					local dist = math.abs((xsCache[i] or 0) - rx)
					if dist < bestDist then
						best, bestDist = i, dist
					end
				end
				applyHover(best)
			end
			card.InputChanged:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
					scrub(input)
				end
			end)
			card.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.Touch then scrub(input) end
			end)
			card.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.Touch then applyHover(nil) end
			end)
			card.MouseLeave:Connect(function()
				applyHover(nil)
			end)

			local animToken = 0
			local function entrance()
				if #dots == 0 then return end
				animToken = animToken + 1
				local my = animToken
				local w = plot.AbsoluteSize.X / currentUiScale()
				if w < 24 then return end
				local D = 0.75
				segHolder.ClipsDescendants = true
				segHolder.Size = UDim2.new(0, 0, 1, 0)
				tween(segHolder, TweenInfo.new(D, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 1, 0)})
				task.delay(D + 0.1, function()
					if my == animToken then
						segHolder.ClipsDescendants = false
						segHolder.Size = UDim2.fromScale(1, 1)
					end
				end)
				for i, d in ipairs(dots) do
					if not showDots then break end
					d.Size = UDim2.fromOffset(0, 0)
					local at = math.clamp((xsCache[i] or 0) / w, 0, 1)
					task.delay(at * D * 0.62, function()
						if my ~= animToken then return end
						tween(d, TweenInfo.new(0.42, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.fromOffset(10, 10)})
					end)
				end
				for c, f in ipairs(cols) do
					local target = colTargets[c] or f.Size
					f.Size = UDim2.fromOffset(target.X.Offset, 0)
					local at = math.clamp(((c - 0.5) * 3) / w, 0, 1)
					task.delay(at * D * 0.62 + 0.05, function()
						if my ~= animToken then return end
						tween(f, TweenInfo.new(0.55, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = target})
					end)
				end
			end

			local function chainVisible()
				local a = card
				while a and not a:IsA("ScreenGui") do
					if a:IsA("GuiObject") and not a.Visible then return false end
					a = a.Parent
				end
				return true
			end

			plot:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
				redraw(false)
			end)
			task.defer(function()
				redraw(false)
				local node = card.Parent
				while node and not node:IsA("ScreenGui") do
					if node:IsA("GuiObject") then
						local n = node
						n:GetPropertyChangedSignal("Visible"):Connect(function()
							if n.Visible and chainVisible() then
								task.defer(entrance)
							end
						end)
					end
					node = node.Parent
				end
				if chainVisible() then entrance() end
			end)

			local Chart = {}
			function Chart:Set(newSettings)
				newSettings = newSettings or {}
				if newSettings.Name then
					nameLabel.Text = newSettings.Name
					card:SetAttribute("SearchName", newSettings.Name)
				end
				if newSettings.Points then
					local fresh = {}
					for _, v in ipairs(newSettings.Points) do
						local nv = tonumber(v)
						if nv then fresh[#fresh + 1] = nv end
					end
					if #fresh == 0 then fresh = {0, 0} end
					if #fresh == 1 then fresh = {fresh[1], fresh[1]} end
					while #fresh > maxPoints do table.remove(fresh, 1) end
					if hoverIdx then applyHover(nil) end
					points = fresh
					setValue(fmt(points[#points]))
					redraw(true)
				end
			end
			local function ripple(i)
				local x, y = xsCache[i], ysCache[i]
				if not x or not y then return end
				local r = create("Frame", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromOffset(x, y),
					Size = UDim2.fromOffset(12, 12),
					BackgroundColor3 = Theme.AccentSoft,
					BackgroundTransparency = 0.55,
					ZIndex = 3,
					Parent = dotHolder,
				})
				roundFull(r)
				tween(r, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.fromOffset(56, 56), BackgroundTransparency = 1})
				task.delay(0.65, function() r:Destroy() end)
			end

			function Chart:Push(v)
				local nv = tonumber(v)
				if not nv then return end
				if hoverIdx then applyHover(nil) end
				points[#points + 1] = nv
				while #points > maxPoints do table.remove(points, 1) end
				setValue(fmt(points[#points]))
				redraw(true)
				task.delay(0.16, function() ripple(#points) end)
			end
			function Chart:Replay()
				if hoverIdx then applyHover(nil) end
				entrance()
			end
			return Chart
		end

		function Tab:CreateBarChart(ChartSettings)
			ChartSettings = ChartSettings or {}
			local function parsePoints(list)
				local v, l = {}, {}
				for _, item in ipairs(list or {}) do
					if type(item) == "table" then
						local nv = tonumber(item.Value)
						if nv then
							v[#v + 1] = nv
							l[#v] = item.Label
						end
					else
						local nv = tonumber(item)
						if nv then v[#v + 1] = nv end
					end
				end
				if #v == 0 then v = {0} end
				return v, l
			end
			local vals, labs = parsePoints(ChartSettings.Points)
			local prefix = ChartSettings.Prefix or ""
			local suffix = ChartSettings.Suffix or ""
			local decimals = ChartSettings.Decimals or 0
			local maxPoints = ChartSettings.MaxPoints or math.max(#vals, 12)
			local hasLabels = next(labs) ~= nil

			local card, nameLabel, valueLabel = chartShell(ChartSettings, hasLabels and 168 or 152)
			local plot = create("Frame", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(17, 44),
				Size = UDim2.new(1, -34, 1, hasLabels and -74 or -58),
				Parent = card,
			})
			create("Frame", {
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 0.93,
				BorderSizePixel = 0,
				Position = UDim2.new(0, 0, 0.5, 0),
				Size = UDim2.new(1, 0, 0, 1),
				Parent = plot,
			})
			create("Frame", {
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 0.93,
				BorderSizePixel = 0,
				Position = UDim2.new(0, 0, 1, -1),
				Size = UDim2.new(1, 0, 0, 1),
				Parent = plot,
			})
			local barHolder = create("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				ZIndex = 2,
				Parent = plot,
			})

			local bars, barTargets, labelInsts = {}, {}, {}
			local hoverIdx = nil
			local function fmt(n)
				local str = decimals > 0 and string.format("%." .. decimals .. "f", n) or tostring(math.floor(n + 0.5))
				return prefix .. commafy(str) .. suffix
			end
			local setValue = odometerValue(valueLabel, fmt(vals[#vals]))

			local function redraw(animate)
				local w, h = plot.AbsoluteSize.X / currentUiScale(), plot.AbsoluteSize.Y / currentUiScale()
				if w < 24 or h < 24 then return end
				local n = #vals
				local hi = 0
				for _, v in ipairs(vals) do hi = math.max(hi, v) end
				if hi <= 0 then hi = 1 end
				for i = #bars, n + 1, -1 do
					bars[i]:Destroy()
					bars[i] = nil
					barTargets[i] = nil
				end
				for i = #labelInsts, n + 1, -1 do
					labelInsts[i]:Destroy()
					labelInsts[i] = nil
				end
				local slot = w / n
				local barW = math.max(6, math.min(46, math.floor(slot * 0.72)))
				for i = 1, n do
					local b = bars[i]
					local fresh = not b
					if fresh then
						b = create("Frame", {
							AnchorPoint = Vector2.new(0.5, 1),
							BorderSizePixel = 0,
							ZIndex = 2,
							Parent = barHolder,
						})
						paint(b, "BackgroundColor3", "Accent")
						round(b, 6)
						create("UIGradient", {
							Rotation = 90,
							Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(178, 178, 178)),
							Parent = b,
						})
						bars[i] = b
					end
					local bh = math.max(3, math.floor(math.max(vals[i], 0) / hi * (h - 12)))
					local props = {
						Position = UDim2.fromOffset(math.floor(slot * (i - 0.5) + 0.5), h - 1),
						Size = UDim2.fromOffset(barW, bh),
					}
					barTargets[i] = props.Size
					if fresh then
						b.Position = props.Position
						if animate then
							b.Size = UDim2.fromOffset(barW, 0)
							tween(b, TI_MORPH, {Size = props.Size})
						else
							b.Size = props.Size
						end
					elseif animate then
						tween(b, TI_MORPH, props)
					else
						b.Position = props.Position
						b.Size = props.Size
					end
					if hasLabels then
						local lab = labelInsts[i]
						if not lab then
							lab = create("TextLabel", {
								BackgroundTransparency = 1,
								AnchorPoint = Vector2.new(0.5, 0),
								Size = UDim2.fromOffset(math.floor(slot), 12),
								Font = FONT_MEDIUM,
								TextSize = 11,
								TextTruncate = Enum.TextTruncate.AtEnd,
								Parent = plot,
							})
							paint(lab, "TextColor3", "TextMuted")
							labelInsts[i] = lab
						end
						lab.Position = UDim2.new(0, math.floor(slot * (i - 0.5) + 0.5), 1, 3)
						lab.Text = labs[i] or ""
					end
				end
			end

			local function applyHover(i)
				if hoverIdx == i then return end
				if hoverIdx and bars[hoverIdx] then
					bars[hoverIdx].BackgroundColor3 = Theme.Accent
				end
				hoverIdx = i
				if i and bars[i] then
					bars[i].BackgroundColor3 = Theme.AccentSoft
					setValue(fmt(vals[i]))
				else
					setValue(fmt(vals[#vals]))
				end
			end

			local function scrub(input)
				local w = plot.AbsoluteSize.X
				if w < 24 or #vals == 0 then return end
				local rx = input.Position.X - plot.AbsolutePosition.X
				local i = math.clamp(math.floor(rx / (w / #vals)) + 1, 1, #vals)
				applyHover(i)
			end
			card.InputChanged:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
					scrub(input)
				end
			end)
			card.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.Touch then scrub(input) end
			end)
			card.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.Touch then applyHover(nil) end
			end)
			card.MouseLeave:Connect(function()
				applyHover(nil)
			end)

			local animToken = 0
			local function entrance()
				if #bars == 0 then return end
				animToken = animToken + 1
				local my = animToken
				for i, b in ipairs(bars) do
					local target = barTargets[i] or b.Size
					b.Size = UDim2.fromOffset(target.X.Offset, 0)
					task.delay(0.04 + (i - 1) * 0.05, function()
						if my ~= animToken then return end
						tween(b, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = target})
					end)
				end
			end

			plot:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
				redraw(false)
			end)
			task.defer(function() redraw(false) end)
			replayOnVisible(card, entrance)

			local Chart = {}
			function Chart:Set(newSettings)
				newSettings = newSettings or {}
				if newSettings.Name then
					nameLabel.Text = newSettings.Name
					card:SetAttribute("SearchName", newSettings.Name)
				end
				if newSettings.Points then
					if hoverIdx then applyHover(nil) end
					vals, labs = parsePoints(newSettings.Points)
					while #vals > maxPoints do
						table.remove(vals, 1)
						table.remove(labs, 1)
					end
					setValue(fmt(vals[#vals]))
					redraw(true)
				end
			end
			function Chart:Push(v, label)
				local nv = tonumber(v)
				if not nv then return end
				if hoverIdx then applyHover(nil) end
				vals[#vals + 1] = nv
				labs[#vals] = label
				while #vals > maxPoints do
					table.remove(vals, 1)
					table.remove(labs, 1)
				end
				setValue(fmt(vals[#vals]))
				redraw(true)
			end
			function Chart:Replay()
				if hoverIdx then applyHover(nil) end
				entrance()
			end
			return Chart
		end

		function Tab:CreateStackedChart(ChartSettings)
			ChartSettings = ChartSettings or {}
			local series = {}
			for _, s in ipairs(ChartSettings.Series or {}) do
				series[#series + 1] = tostring(s)
			end
			local colors = {}
			for i = 1, math.max(#series, 1) do
				colors[i] = (ChartSettings.Colors and ChartSettings.Colors[i]) or chartPalette[(i - 1) % #chartPalette + 1]
			end
			local function parseRows(list)
				local out = {}
				for _, r in ipairs(list or {}) do
					local vals = {}
					for _, v in ipairs(r.Values or {}) do
						vals[#vals + 1] = math.max(tonumber(v) or 0, 0)
					end
					out[#out + 1] = {name = r.Name or "", values = vals}
				end
				if #out == 0 then out = {{name = "", values = {1}}} end
				return out
			end
			local rowsData = parseRows(ChartSettings.Rows)
			local prefix = ChartSettings.Prefix or ""
			local suffix = ChartSettings.Suffix or ""

			local cardH = 78 + #rowsData * 34
			local card, nameLabel, valueLabel = chartShell(ChartSettings, cardH)
			local legend = create("Frame", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(17, 40),
				Size = UDim2.new(1, -34, 0, 18),
				Parent = card,
			})
			create("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 14),
				Parent = legend,
			})
			for i, s in ipairs(series) do
				local item = create("Frame", {
					BackgroundTransparency = 1,
					AutomaticSize = Enum.AutomaticSize.X,
					Size = UDim2.new(0, 0, 1, 0),
					LayoutOrder = i,
					Parent = legend,
				})
				local chip = create("Frame", {
					AnchorPoint = Vector2.new(0, 0.5),
					Position = UDim2.new(0, 0, 0.5, 0),
					Size = UDim2.fromOffset(10, 10),
					BackgroundColor3 = colors[i],
					BorderSizePixel = 0,
					Parent = item,
				})
				roundFull(chip)
				local nm = create("TextLabel", {
					BackgroundTransparency = 1,
					AutomaticSize = Enum.AutomaticSize.X,
					AnchorPoint = Vector2.new(0, 0.5),
					Position = UDim2.new(0, 16, 0.5, 0),
					Size = UDim2.new(0, 0, 0, 14),
					Font = FONT_MEDIUM,
					TextSize = 13,
					TextXAlignment = Enum.TextXAlignment.Left,
					Text = s,
					Parent = item,
				})
				paint(nm, "TextColor3", "TextSub")
			end
			local rowsHolder = create("Frame", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(17, 66),
				Size = UDim2.new(1, -34, 1, -80),
				Parent = card,
			})

			local rowInsts = {}
			local segMap = {}
			local hoverKey = nil
			local function fmt(n)
				return prefix .. commafy(tostring(math.floor(n + 0.5))) .. suffix
			end

			local function rebuildRows()
				for _, inst in ipairs(rowInsts) do inst:Destroy() end
				rowInsts = {}
				segMap = {}
				for i, r in ipairs(rowsData) do
					local rf = create("Frame", {
						BackgroundTransparency = 1,
						Position = UDim2.fromOffset(0, (i - 1) * 34),
						Size = UDim2.new(1, 0, 0, 28),
						Parent = rowsHolder,
					})
					local nm = create("TextLabel", {
						BackgroundTransparency = 1,
						AnchorPoint = Vector2.new(0, 0.5),
						Position = UDim2.new(0, 0, 0.5, 0),
						Size = UDim2.fromOffset(76, 14),
						Font = FONT_MEDIUM,
						TextSize = 13,
						TextXAlignment = Enum.TextXAlignment.Left,
						TextTruncate = Enum.TextTruncate.AtEnd,
						Text = r.name,
						Parent = rf,
					})
					paint(nm, "TextColor3", "TextBody")
					local track = create("Frame", {
						BackgroundTransparency = 1,
						AnchorPoint = Vector2.new(0, 0.5),
						Position = UDim2.new(0, 84, 0.5, 0),
						Size = UDim2.new(1, -84, 0, 22),
						Parent = rf,
					})
					local barc = create("Frame", {
						BackgroundTransparency = 1,
						ClipsDescendants = true,
						Size = UDim2.new(0, 0, 1, 0),
						Parent = track,
					})
					round(barc, 6)
					rowInsts[i] = rf
					segMap[i] = {track = track, container = barc, segs = {}}
				end
			end

			local function redraw(animate)
				local hi = 0
				for _, r in ipairs(rowsData) do
					local t = 0
					for _, v in ipairs(r.values) do t = t + v end
					r.total = t
					hi = math.max(hi, t)
				end
				if hi <= 0 then hi = 1 end
				for i, r in ipairs(rowsData) do
					local m = segMap[i]
					if m then
						local trackW = m.track.AbsoluteSize.X / currentUiScale()
						if trackW < 10 then trackW = 300 end
						local contW = math.floor(trackW * r.total / hi + 0.5)
						local props = {Size = UDim2.new(0, contW, 1, 0)}
						if animate then
							tween(m.container, TI_MORPH, props)
						else
							m.container.Size = props.Size
						end
						for _, sg in ipairs(m.segs) do sg:Destroy() end
						m.segs = {}
						local x = 0
						for k, v in ipairs(r.values) do
							local segW = math.floor(v / math.max(r.total, 0.0001) * contW + 0.5)
							if k == #r.values then segW = contW - x end
							local sg = create("Frame", {
								Position = UDim2.fromOffset(x, 0),
								Size = UDim2.new(0, segW, 1, 0),
								BackgroundColor3 = colors[k] or chartPalette[1],
								BorderSizePixel = 0,
								Parent = m.container,
							})
							m.segs[k] = sg
							x = x + segW
						end
					end
				end
			end

			local function applyHover(key)
				if hoverKey and (not key or key[1] ~= hoverKey[1] or key[2] ~= hoverKey[2]) then
					local m = segMap[hoverKey[1]]
					local sg = m and m.segs[hoverKey[2]]
					if sg then sg.BackgroundColor3 = colors[hoverKey[2]] or chartPalette[1] end
					hoverKey = nil
					valueLabel.Text = ""
				end
				if key then
					local m = segMap[key[1]]
					local sg = m and m.segs[key[2]]
					local v = rowsData[key[1]] and rowsData[key[1]].values[key[2]]
					if sg and v then
						hoverKey = key
						sg.BackgroundColor3 = (colors[key[2]] or chartPalette[1]):Lerp(Color3.fromRGB(255, 255, 255), 0.22)
						valueLabel.Text = fmt(v)
					end
				end
			end

			local function scrub(input)
				local ry = (input.Position.Y - rowsHolder.AbsolutePosition.Y) / currentUiScale()
				local i = math.floor(ry / 34) + 1
				local m = segMap[i]
				if not m then
					applyHover(nil)
					return
				end
				local rx = input.Position.X - m.container.AbsolutePosition.X
				if rx < 0 or rx > m.container.AbsoluteSize.X then
					applyHover(nil)
					return
				end
				local x = 0
				for k, sg in ipairs(m.segs) do
					x = x + sg.AbsoluteSize.X
					if rx <= x then
						applyHover({i, k})
						return
					end
				end
				applyHover(nil)
			end
			card.InputChanged:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
					scrub(input)
				end
			end)
			card.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.Touch then scrub(input) end
			end)
			card.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.Touch then applyHover(nil) end
			end)
			card.MouseLeave:Connect(function()
				applyHover(nil)
			end)

			local animToken = 0
			local function entrance()
				animToken = animToken + 1
				local my = animToken
				for i, m in ipairs(segMap) do
					local target = m.container.Size
					m.container.Size = UDim2.new(0, 0, 1, 0)
					task.delay(0.05 + (i - 1) * 0.09, function()
						if my ~= animToken then return end
						tween(m.container, TweenInfo.new(0.55, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = target})
					end)
				end
			end

			rowsHolder:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
				redraw(false)
			end)
			rebuildRows()
			task.defer(function() redraw(false) end)
			replayOnVisible(card, entrance)

			local Chart = {}
			function Chart:Set(newSettings)
				newSettings = newSettings or {}
				if newSettings.Name then
					nameLabel.Text = newSettings.Name
					card:SetAttribute("SearchName", newSettings.Name)
				end
				if newSettings.Rows then
					applyHover(nil)
					rowsData = parseRows(newSettings.Rows)
					rebuildRows()
					redraw(true)
				end
			end
			function Chart:Replay()
				applyHover(nil)
				entrance()
			end
			return Chart
		end

		function Tab:CreateButton(ButtonSettings)
			ButtonSettings = normalizeProps(ButtonSettings)
			local card, label
			if compact then

				card = create("Frame", {
					Size = UDim2.new(1, 0, 0, 50),
					LayoutOrder = nextOrder(),
					Parent = page,
				})
				card:SetAttribute("SearchName", ButtonSettings.Name or "")
				paint(card, "BackgroundColor3", "Card")
				cardBase(card)
				local center = create("Frame", {
					BackgroundTransparency = 1,
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5),
					AutomaticSize = Enum.AutomaticSize.X,
					Size = UDim2.new(0, 0, 1,0),
					Parent = card,
				})
				create("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					VerticalAlignment = Enum.VerticalAlignment.Center,
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0,9),
					Parent = center,
				})
				if ButtonSettings.Icon then
					local ic = makeIcon(center, ButtonSettings.Icon, 18, Theme.TextTitle, 0.04)
					if ic then ic.LayoutOrder = 1 end
				end
				label = create("TextLabel", {
					BackgroundTransparency = 1,
					AutomaticSize=Enum.AutomaticSize.X,
					Size = UDim2.new(0, 0, 1, 0),
					Font = FONT_MEDIUM,
					TextSize = 16,
					Text = ButtonSettings.Name or "",
					LayoutOrder = 2,
					Parent = center,
				})
				paint(label, "TextColor3", "TextBody")
				registerTr(label, ButtonSettings.Name or "")
			else
				card, label = makeCard(page,ButtonSettings.Name,ButtonSettings.Icon, 50)
				descFor(card, ButtonSettings.Description)
			end
			hoverable(card)
			local clicker = create("TextButton", {
				BackgroundTransparency = 1,
				Text = "",
				Size = UDim2.fromScale(1, 1),
				Parent = card,
			})
			clicker.MouseButton1Click:Connect(function()
				tween(card, TweenInfo.new(0.07,Enum.EasingStyle.Quad), {BackgroundColor3 = Theme.CardSelected})
				task.delay(0.09,function()
					tween(card, TI_MED, {BackgroundColor3 = Theme.Card})
				end)
				runCallback(ButtonSettings.Callback)
			end)
			local ButtonValue = {}
			function ButtonValue:Set(newName)
				label.Text = newName
				card:SetAttribute("SearchName", newName or "")
			end
			finalizeElement(ButtonValue, ButtonSettings, card, nil)
			return ButtonValue
		end

		function Tab:CreateToggle(ToggleSettings)
			ToggleSettings = normalizeProps(ToggleSettings, "CurrentValue")
			local card = makeCard(page,ToggleSettings.Name, ToggleSettings.Icon, 50)
			descFor(card, ToggleSettings.Description)
			hoverable(card)

			local track = create("Frame", {
				AnchorPoint=Vector2.new(1, 0.5),
				Position = UDim2.new(1, -15, 0.5, 0),
				Size = UDim2.fromOffset(58, 26),
			})
			paint(track, "BackgroundColor3", "ToggleTrack")
			roundFull(track)
			local trackStroke = create("UIStroke", {
				Color = Color3.fromRGB(255, 255, 255),
				Transparency = 0.84,
				Parent = track,
			})
			track.Parent = card

			local knob = create("Frame", {
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 3, 0.5, 0),
				Size = UDim2.fromOffset(28, 20),
				BackgroundColor3 = Theme.KnobOff,
			})
			roundFull(knob)
			create("UIGradient", {
				Rotation = 90,
				Color = ColorSequence.new(Color3.fromRGB(255, 255,255), Color3.fromRGB(196, 196, 196)),
				Parent = knob,
			})
			knob.Parent = track

			local Toggle = {
				Type = "Toggle",
				CurrentValue = ToggleSettings.CurrentValue == true,
			}

			local function render(animate)
				local on = Toggle.CurrentValue
				local info = animate and TweenInfo.new(0.3, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out) or TweenInfo.new(0)
				tween(knob, info, {
					Position = on and UDim2.new(1, -31, 0.5, 0) or UDim2.new(0, 3,0.5, 0),
					BackgroundColor3 = on and Theme.Accent or Theme.KnobOff,
				})
			end
			render(false)

			local clicker = create("TextButton",{
				BackgroundTransparency = 1,
				Text = "",
				Size = UDim2.fromScale(1,1),
				Parent = card,
			})
			clicker.MouseButton1Click:Connect(function()
				Toggle.CurrentValue = not Toggle.CurrentValue
				render(true)
				runCallback(ToggleSettings.Callback, Toggle.CurrentValue)
				saveConfiguration()
			end)

			function Toggle:Set(value, skipCallback)
				Toggle.CurrentValue = value == true
				render(true)
				if not skipCallback then
					runCallback(ToggleSettings.Callback, Toggle.CurrentValue)
				end
				saveConfiguration()
			end

			finalizeElement(Toggle, ToggleSettings, card, getCurrentValue)
			return Toggle
		end

		function Tab:CreateSlider(SliderSettings)
			SliderSettings = normalizeProps(SliderSettings, "CurrentValue")
			local range = SliderSettings.Range or {0, 100}
			local increment = SliderSettings.Increment or 1
			local suffix = SliderSettings.Suffix or ""

			local card = create("Frame",{
				Size = UDim2.new(1, 0, 0,compact and 78 or 60),
				LayoutOrder = nextOrder(),
				Parent=page,
			})
			card:SetAttribute("SearchName",SliderSettings.Name or "")
			paint(card, "BackgroundColor3", "Card")
			cardBase(card)
			descFor(card,SliderSettings.Description)

			local textX = 17
			if SliderSettings.Icon then
				local ic = makeIcon(card, SliderSettings.Icon, 18,Theme.TextTitle,0.04)
				if ic then
					ic.Position = UDim2.fromOffset(16,13)
					textX = 44
				end
			end
			local nameLabel = create("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(textX, compact and 13 or 11),
				Size = UDim2.new(compact and 0.56 or 0.48,-textX, 0,18),
				Font = FONT_MEDIUM,
				TextSize = 16,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Text = SliderSettings.Name or "",
				Parent = card,
			})
			paint(nameLabel, "TextColor3","TextBody")
			registerTr(nameLabel, SliderSettings.Name or "")
			local valueLabel = create("TextLabel", {
				BackgroundTransparency = 1,
				AnchorPoint = compact and Vector2.new(1, 0) or Vector2.new(0, 0),
				Position = compact and UDim2.new(1, -16, 0, 15) or UDim2.fromOffset(textX, 32),
				Size = UDim2.new(compact and 0.4 or 0.48, compact and -16 or -textX,0, 16),
				Font = FONT_REGULAR,
				TextSize = 13,
				TextXAlignment = compact and Enum.TextXAlignment.Right or Enum.TextXAlignment.Left,
				Text = "",
				Parent = card,
			})
			paint(valueLabel, "TextColor3", "TextSub")

			local track
			if compact then
				track = create("Frame", {
					Position = UDim2.fromOffset(15, 46),
					Size = UDim2.new(1,-30, 0, 16),
					BackgroundColor3 = Color3.fromRGB(47, 47, 47),
				})
			else
				track = create("Frame",{
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -17, 0.5, 0),
					Size = UDim2.new(0.46,0,0, 16),
					BackgroundColor3 = Color3.fromRGB(47, 47, 47),
				})
			end
			roundFull(track)
			track.Parent = card

			local fill = create("Frame", {
				Size = UDim2.new(0.5, 0, 1, 0),
				BackgroundColor3 = Color3.fromRGB(255, 255,255),
				Parent = track,
			})
			roundFull(fill)

			create("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(42, 88, 66)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(74, 178, 124)),
				}),
				Parent = fill,
			})

			local knob = create("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5,0,0.5, 0),
				Size = UDim2.fromOffset(48, 26),
				ZIndex = 3,
			})
			paint(knob, "BackgroundColor3", "Knob")
			roundFull(knob)
			knob.Parent = track

			local Slider = {
				Type = "Slider",
				CurrentValue = SliderSettings.CurrentValue or range[1],
			}

			local function fmt(v)
				local text
				if increment % 1 == 0 then
					text = tostring(math.floor(v + 0.5))
				else
					text = string.format("%.2f", v)
					text = string.gsub(text, "%.?0+$", "")
				end
				if suffix ~= "" then
					return text .. " " .. suffix
				end
				return text
			end

			local function render(animate)
				local alpha = 0
				if range[2] ~= range[1] then
					alpha = (Slider.CurrentValue - range[1]) / (range[2] - range[1])
				end
				alpha = math.clamp(alpha,0, 1)
				local inset = 0.11
				local shown = inset + alpha * (1 - 2 * inset)
				local info = animate and TI_SMOOTH or TweenInfo.new(0)
				tween(fill, info,{Size = UDim2.new(shown,0, 1, 0)})
				tween(knob,info, {Position = UDim2.new(shown, 0, 0.5, 0)})
				valueLabel.Text = fmt(Slider.CurrentValue)
			end

			local function setFromAlpha(alpha)
				local raw = range[1] + alpha * (range[2] - range[1])
				local snapped = range[1] + math.floor((raw - range[1]) / increment + 0.5) * increment
				snapped = math.clamp(snapped, range[1], range[2])
				if math.abs(snapped - Slider.CurrentValue) > 1e-9 then
					Slider.CurrentValue = snapped
					render(true)
					runCallback(SliderSettings.Callback,snapped)
					saveConfiguration()
				end
			end

			local hit = track
			if TOUCH_UI then
				hit = create("Frame", {
					BackgroundTransparency = 1,
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5),
					Size = UDim2.new(1, 14, 0, 38),
					Parent = track,
				})
			end

			local dragging = false
			hit.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					dragging = true
					local alpha = (input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X
					setFromAlpha(math.clamp(alpha, 0, 1))
				end
			end)
			hit.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					dragging = false
				end
			end)
			connect(UserInputService.InputChanged,function(input)
				if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
					local alpha = (input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X
					setFromAlpha(math.clamp(alpha, 0,1))
				end
			end)
			connect(UserInputService.InputEnded, function(input)
				if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
					dragging = false
				end
			end)

			render(false)

			function Slider:Set(value, skipCallback)
				Slider.CurrentValue = math.clamp(value, range[1], range[2])
				render(true)
				if not skipCallback then
					runCallback(SliderSettings.Callback,Slider.CurrentValue)
				end
				saveConfiguration()
			end

			finalizeElement(Slider, SliderSettings, card, getCurrentValue)
			return Slider
		end

		function Tab:CreateInput(InputSettings)
			InputSettings = normalizeProps(InputSettings, "CurrentValue")
			local card = makeCard(page,InputSettings.Name,InputSettings.Icon, 50)
			descFor(card, InputSettings.Description)
			hoverable(card)

			local boxHolder = create("Frame", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1,-13, 0.5, 0),
				Size = UDim2.fromOffset(172, 32),
				Parent = card,
			})
			paint(boxHolder, "BackgroundColor3", "CardHover")
			round(boxHolder, 10)
			local boxStroke = create("UIStroke", {Color = Color3.fromRGB(255, 255, 255), Transparency = 0.88, Parent = boxHolder})

			local box = create("TextBox", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, -20, 1, 0),
				Position = UDim2.fromOffset(10, 0),
				Font = FONT_MEDIUM,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
				PlaceholderText = InputSettings.PlaceholderText or "Input",
				PlaceholderColor3 = Theme.TextMuted,
				Text = InputSettings.CurrentValue or "",
				ClearTextOnFocus = false,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Parent = boxHolder,
			})
			paint(box, "TextColor3", "TextBody")

			local Input = {
				Type = "Input",
				CurrentValue = InputSettings.CurrentValue or "",
			}

			box.Focused:Connect(function()
				tween(boxStroke, TI_FAST,{Transparency = 0.5})
			end)
			box.FocusLost:Connect(function()
				tween(boxStroke, TI_FAST,{Transparency = 0.88})
				Input.CurrentValue = box.Text
				runCallback(InputSettings.Callback,box.Text)
				if InputSettings.RemoveTextAfterFocusLost then
					box.Text = ""
				end
				saveConfiguration()
			end)

			function Input:Set(text, skipCallback)
				box.Text = text or ""
				Input.CurrentValue = box.Text
				if not skipCallback then
					runCallback(InputSettings.Callback, box.Text)
				end
				saveConfiguration()
			end

			finalizeElement(Input, InputSettings, card, getCurrentValue)
			return Input
		end

		function Tab:CreateDropdown(DropdownSettings)
			DropdownSettings = normalizeProps(DropdownSettings, "CurrentOption")
			local officialAPI = DropdownSettings.__official == true
			local options = DropdownSettings.Options or {}
			local multiple = DropdownSettings.MultipleOptions == true

			local current = DropdownSettings.CurrentOption
			if type(current) == "string" then current = {current} end
			if type(current) ~= "table" then current = {} end
			if not multiple and #current > 1 then
				current = {current[1]}
			end

			local wrapper = create("Frame", {
				BackgroundTransparency = 1,
				AutomaticSize = Enum.AutomaticSize.Y,
				Size = UDim2.new(1,0, 0, 50),
				LayoutOrder = nextOrder(),
				Parent = page,
			})
			wrapper:SetAttribute("SearchName", DropdownSettings.Name or "")

			local card = create("Frame",{
				Size = UDim2.new(1,0, 0, 50),
				Parent = wrapper,
			})
			paint(card, "BackgroundColor3", "Card");
			cardBase(card)
			hoverable(card)

			local textX = 17
			if DropdownSettings.Icon then
				local ic = makeIcon(card,DropdownSettings.Icon, 18,Theme.TextTitle, 0.04)
				if ic then
					ic.AnchorPoint = Vector2.new(0, 0.5)
					ic.Position = UDim2.new(0, 16,0.5, 0)
					textX = 44
				end
			end
			local label = create("TextLabel", {
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(0, 0.5),
				Position=UDim2.new(0,textX, 0.5, 0),
				Size = UDim2.new(0.5, -textX, 0,18),
				Font = FONT_MEDIUM,
				TextSize=16,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Text = DropdownSettings.Name or "",
				Parent = card,
			})
			paint(label, "TextColor3","TextBody")
			registerTr(label, DropdownSettings.Name or "")

			local chevron = create("ImageLabel", {
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(1,0.5),
				Position = UDim2.new(1, -15, 0.5, 0),
				Size = UDim2.fromOffset(16, 16),
				ImageColor3 = Theme.TextSub,
				Parent = card,
			})
			applyLucide(chevron, {"chevron-down"})

			local currentLabel = create("TextLabel", {
				BackgroundTransparency = 1,
				AnchorPoint=Vector2.new(1, 0.5),
				Position=UDim2.new(1, -39, 0.5, 0),
				Size = UDim2.new(0.4, -39, 0, 16),
				Font=FONT_MEDIUM,
				TextSize=14,
				TextXAlignment = Enum.TextXAlignment.Right,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Text = "",
				Parent = card,
			})
			paint(currentLabel, "TextColor3", "TextSub")

			local OPTION_H = 42
			local SEARCH_H = 40
			local GAP = 6
			local MAX_LIST = 240

			local listHolder = create("ScrollingFrame", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(0, 56),
				Size = UDim2.new(1,0, 0, 0),
				CanvasSize=UDim2.new(0, 0, 0,0),
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				ScrollingDirection = Enum.ScrollingDirection.Y,
				ScrollBarThickness = 2,
				ScrollBarImageColor3 = Color3.fromRGB(90, 90, 90),
				BorderSizePixel = 0,
				ClipsDescendants = true,
				Visible = false,
				Parent = wrapper,
			})
			create("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, GAP),
				Parent = listHolder,
			})

			local searchRow = create("Frame", {
				Size = UDim2.new(1, 0, 0, SEARCH_H),
				BackgroundTransparency = 0.35,
				LayoutOrder = 1,
				Parent = listHolder,
			})
			paint(searchRow, "BackgroundColor3","SearchBox")
			round(searchRow,12)
			do
				local sIcon = makeIcon(searchRow, "text-search",16, Theme.TextSub)
				if sIcon then
					sIcon.AnchorPoint = Vector2.new(0,0.5)
					sIcon.Position = UDim2.new(0, 13, 0.5, 0)
				end
			end
			local optionSearch = create("TextBox",{
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(38, 0),
				Size=UDim2.new(1, -46,1, 0),
				Font = FONT_MEDIUM,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
				PlaceholderText = "Search " .. (DropdownSettings.Name or "Dropdown"),
				PlaceholderColor3 = Theme.TextMuted,
				Text = "",
				ClearTextOnFocus = false,
				Parent = searchRow,
			})
			paint(optionSearch, "TextColor3", "TextBody")

			local Dropdown = {
				Type = "Dropdown",
				CurrentOption = current,
			}

			local function callbackValue()
				if officialAPI and not multiple then
					return Dropdown.CurrentOption[1]
				end
				return Dropdown.CurrentOption
			end

			local open = false
			local optionRows = {}

			local function isSelected(option)
				for _, v in ipairs(Dropdown.CurrentOption) do
					if v == option then return true end
				end
				return false
			end

			local function refreshCurrentLabel()
				local n = #Dropdown.CurrentOption
				if n == 0 then
					currentLabel.Text = "None"
				elseif n == 1 then
					currentLabel.Text = tostring(Dropdown.CurrentOption[1])
				else
					currentLabel.Text = tostring(n) .. " selected"
				end
			end

			local function visibleListHeight()
				local count = 0
				for _, row in ipairs(optionRows) do
					if row.frame.Visible then count = count + 1 end
				end
				local h = SEARCH_H + GAP + count * (OPTION_H + GAP)
				return math.min(h, MAX_LIST)
			end

			local function setOpen(value)
				open = value
				tween(chevron,TI_MED, {Rotation = open and 180 or 0})
				if open then
					listHolder.Visible = true
					tween(listHolder, TI_MED, {Size = UDim2.new(1, 0, 0, visibleListHeight())})
				else
					local t = tween(listHolder, TI_MED, {Size = UDim2.new(1, 0, 0, 0)})
					t.Completed:Connect(function()
						if not open then listHolder.Visible = false end
					end)
					optionSearch.Text = ""
				end
			end

			local function renderRows()
				for _, row in ipairs(optionRows) do
					local selected = isSelected(row.option)
					row.frame.BackgroundColor3 = selected and Theme.CardSelected or Theme.CardInset
					row.check.Visible = selected
					row.label.Position = UDim2.new(0, selected and 44 or 17, 0.5, 0)
					row.label.TextColor3 = selected and Theme.TextTitle or Theme.TextSub
				end
			end

			local function choose(option)
				if multiple then
					if isSelected(option) then
						for i, v in ipairs(Dropdown.CurrentOption) do
							if v == option then
								table.remove(Dropdown.CurrentOption, i)
								break
							end
						end
					else
						table.insert(Dropdown.CurrentOption, option)
					end
				else
					Dropdown.CurrentOption = {option}
				end
				renderRows();
				refreshCurrentLabel()
				runCallback(DropdownSettings.Callback, callbackValue());
				saveConfiguration()
				if not multiple then
					task.delay(0.12,function() setOpen(false) end)
				end
			end

			local function buildRows()
				for _, row in ipairs(optionRows) do
					row.frame:Destroy()
				end
				optionRows = {}
				for i, option in ipairs(options) do
					local row = create("Frame", {
						Size = UDim2.new(1, 0, 0, OPTION_H),
						LayoutOrder = i + 1,
						Parent = listHolder,
					})
					round(row, 12)
					local check = create("ImageLabel", {
						BackgroundTransparency = 1,
						AnchorPoint = Vector2.new(0, 0.5),
						Position = UDim2.new(0, 15, 0.5, 0),
						Size = UDim2.fromOffset(18, 18),
						ImageColor3 = Theme.TextTitle,
						Visible = false,
						Parent = row,
					})
					applyLucide(check, {"square-check", "check-square", "check"});
					local optionLabel = create("TextLabel",{
						BackgroundTransparency = 1,
						AnchorPoint = Vector2.new(0, 0.5),
						Position = UDim2.new(0,17, 0.5, 0),
						Size = UDim2.new(1, -62, 0,16),
						Font = FONT_MEDIUM,
						TextSize = 15,
						TextXAlignment = Enum.TextXAlignment.Left,
						TextTruncate = Enum.TextTruncate.AtEnd,
						Text = tostring(option),
						Parent = row,
					})
					local rowButton = create("TextButton", {
						BackgroundTransparency = 1,
						Text = "",
						Size = UDim2.fromScale(1, 1),
						Parent = row,
					})
					local entry = {frame = row, label = optionLabel, check = check, option = option}
					rowButton.MouseEnter:Connect(function()
						if not isSelected(option) then
							tween(row, TI_FAST,{BackgroundColor3 = Theme.CardHover})
						end
					end)
					rowButton.MouseLeave:Connect(function()
						tween(row, TI_FAST, {BackgroundColor3 = isSelected(option) and Theme.CardSelected or Theme.CardInset})
					end)
					rowButton.MouseButton1Click:Connect(function()
						choose(option)
					end)
					table.insert(optionRows,entry)
				end
				renderRows()
			end

			connect(optionSearch:GetPropertyChangedSignal("Text"), function()
				local q = string.lower(optionSearch.Text)
				for _, row in ipairs(optionRows) do
					row.frame.Visible = q == "" or string.find(string.lower(tostring(row.option)), q,1, true) ~= nil
				end
				if open then
					tween(listHolder,TI_FAST, {Size = UDim2.new(1, 0, 0, visibleListHeight())})
				end
			end)

			local clicker = create("TextButton",{
				BackgroundTransparency = 1,
				Text = "",
				Size = UDim2.fromScale(1, 1),
				Parent = card,
			})
			clicker.MouseButton1Click:Connect(function()
				setOpen(not open)
			end)

			buildRows()
			refreshCurrentLabel()

			function Dropdown:Set(newOption, skipCallback)
				if type(newOption) == "string" then newOption = {newOption} end
				if type(newOption) ~= "table" then newOption = {} end
				if not multiple and #newOption > 1 then newOption = {newOption[1]} end
				Dropdown.CurrentOption = newOption
				renderRows()
				refreshCurrentLabel()
				if not skipCallback then
					runCallback(DropdownSettings.Callback, callbackValue())
				end
				saveConfiguration()
			end

			function Dropdown:Refresh(newOptions)
				options = newOptions or {}
				local kept = {}
				for _, v in ipairs(Dropdown.CurrentOption) do
					for _,o in ipairs(options) do
						if o == v then
							table.insert(kept, v)
							break
						end
					end
				end
				Dropdown.CurrentOption = kept
				buildRows()
				refreshCurrentLabel()
				if open then
					tween(listHolder,TI_FAST,{Size = UDim2.new(1, 0, 0, visibleListHeight())})
				end
			end

			function Dropdown:Add(option)
				table.insert(options, option)
				Dropdown:Refresh(options)
			end

			function Dropdown:Remove(option)
				for i, o in ipairs(options) do
					if o == option then
						table.remove(options, i)
						break
					end
				end
				Dropdown:Refresh(options)
			end

			finalizeElement(Dropdown, DropdownSettings, wrapper, function(t)
				local co = rawget(t, "CurrentOption") or {}
				if multiple then return co end
				return co[1]
			end)
			return Dropdown
		end

		function Tab:CreateKeybind(KeybindSettings)
			KeybindSettings = normalizeProps(KeybindSettings, "CurrentKeybind")
			if typeof(KeybindSettings.CurrentKeybind) == "EnumItem" then
				KeybindSettings.CurrentKeybind = KeybindSettings.CurrentKeybind.Name
			end
			if KeybindSettings.Hold == true then
				KeybindSettings.HoldToInteract = true
			end
			local card = makeCard(page, KeybindSettings.Name, KeybindSettings.Icon, 50)
			descFor(card, KeybindSettings.Description)
			hoverable(card)

			local keyHolder = create("Frame", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1,-13, 0.5, 0),
				AutomaticSize = Enum.AutomaticSize.X,
				Size = UDim2.fromOffset(34, 30),
			})
			paint(keyHolder, "BackgroundColor3", "CardHover")
			round(keyHolder, 10)
			local keyStroke = create("UIStroke", {Color = Color3.fromRGB(255, 255,255),Transparency = 0.88, Parent = keyHolder})
			keyHolder.Parent = card
			local keyLabel = create("TextLabel", {
				BackgroundTransparency = 1,
				AutomaticSize = Enum.AutomaticSize.X,
				Size = UDim2.new(0, 18, 1, 0),
				Font = FONT_MEDIUM,
				TextSize = 14,
				Text = KeybindSettings.CurrentKeybind or "Key",
				Parent = keyHolder,
			})
			paint(keyLabel, "TextColor3","TextBody")
			padAll(keyHolder, 0, 9, 0, 9)

			local Keybind = {
				Type = "Keybind",
				CurrentKeybind = KeybindSettings.CurrentKeybind or "Key",
			}

			local listening = false
			local holdActive = false

			local clicker = create("TextButton", {
				BackgroundTransparency = 1,
				Text = "",
				Size = UDim2.fromScale(1, 1),
				Parent = card,
			})
			clicker.MouseButton1Click:Connect(function()
				listening = true
				keyLabel.Text = "..."
				tween(keyStroke, TI_FAST, {Transparency = 0.4})
			end)

			connect(UserInputService.InputBegan,function(input, processed)
				if listening then
					if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode ~= Enum.KeyCode.Unknown then
						listening = false
						tween(keyStroke, TI_FAST,{Transparency = 0.88})
						if input.KeyCode == Enum.KeyCode.Escape then
							keyLabel.Text = Keybind.CurrentKeybind
							return
						end
						Keybind.CurrentKeybind = input.KeyCode.Name
						keyLabel.Text = input.KeyCode.Name
						if KeybindSettings.CallOnChange then
							runCallback(KeybindSettings.Callback, input.KeyCode.Name)
						end
						runCallback(KeybindSettings.OnChanged, input.KeyCode)
						saveConfiguration()
					end
					return
				end
				if processed then return end
				if KeybindSettings.CallOnChange then return end
				if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode.Name == Keybind.CurrentKeybind then
					if KeybindSettings.HoldToInteract then
						holdActive = true
						runCallback(KeybindSettings.Callback, true)
					else
						runCallback(KeybindSettings.Callback)
					end
				end
			end)
			connect(UserInputService.InputEnded, function(input)
				if holdActive and input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode.Name == Keybind.CurrentKeybind then
					holdActive = false
					runCallback(KeybindSettings.Callback, false)
				end
			end)

			function Keybind:Set(newKeybind, skipChanged)
				if typeof(newKeybind) == "EnumItem" then newKeybind = newKeybind.Name end
				Keybind.CurrentKeybind = newKeybind
				keyLabel.Text = newKeybind or "Key"
				if not skipChanged then
					if KeybindSettings.CallOnChange then
						runCallback(KeybindSettings.Callback, newKeybind)
					end
					runCallback(KeybindSettings.OnChanged, newKeybind)
				end
				saveConfiguration()
			end

			finalizeElement(Keybind, KeybindSettings, card, function(t)
				local name = rawget(t, "CurrentKeybind")
				local ok, key = pcall(function() return Enum.KeyCode[name] end)
				if ok and key then return key end
				return name
			end)
			return Keybind
		end

		function Tab:CreateColorPicker(ColorPickerSettings)
			ColorPickerSettings = normalizeProps(ColorPickerSettings, "Color")
			local color = ColorPickerSettings.Color or Color3.fromRGB(255, 255, 255)
			if type(color) == "string" then
				local hex = string.gsub(color, "#", "")
				local rr, gg, bb = string.match(hex, "^(%x%x)(%x%x)(%x%x)$")
				if rr then
					color = Color3.fromRGB(tonumber(rr, 16), tonumber(gg, 16), tonumber(bb, 16))
				else
					color = Color3.fromRGB(255, 255, 255)
				end
			end

			local COLLAPSED_H = 50
			local EXPANDED_H = 238
			local SV_W, SV_H, SV_CY = 180, 110, 116
			local HUE_CY = 180
			local ALPHA_CY = 202
			local EXPO = TweenInfo.new(0.6, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
			local EXPO_FAST = TweenInfo.new(0.45, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)

			local card = create("Frame", {
				Size = UDim2.new(1, 0, 0, COLLAPSED_H),
				ClipsDescendants = true,
				LayoutOrder = nextOrder(),
				Parent = page,
			})
			card:SetAttribute("SearchName", ColorPickerSettings.Name or "")
			paint(card, "BackgroundColor3", "Card")
			cardBase(card)
			hoverable(card)

			local textX = 17
			if ColorPickerSettings.Icon then
				local ic = makeIcon(card, ColorPickerSettings.Icon, 18, Theme.TextTitle, 0.04)
				if ic then
					ic.AnchorPoint = Vector2.new(0, 0.5)
					ic.Position = UDim2.new(0, 16, 0, 25)
					textX = 44
				end
			end
			local label = create("TextLabel",{
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, textX, 0, 25),
				Size = UDim2.new(0.5, -textX, 0, 18),
				Font=FONT_MEDIUM,
				TextSize = 16,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Text = ColorPickerSettings.Name or "",
				Parent = card,
			})
			paint(label, "TextColor3", "TextBody")
			registerTr(label, ColorPickerSettings.Name or "")

			local alpha = math.clamp(tonumber(ColorPickerSettings.Alpha) or 1, 0, 1)

			local ColorPicker = {
				Type = "ColorPicker",
				Color = color,
				Alpha = alpha,
				alpha = alpha,
			}

			local h, s, v = color:ToHSV()
			local open = false
			local push, refresh

			local sv = create("Frame", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -16, 0, 25),
				Size = UDim2.fromOffset(42, 26),
				BackgroundColor3 = Color3.fromHSV(h, 1, 1),
				Parent = card,
			})
			round(sv, 9)
			create("UIStroke", {Color = Theme.Stroke, Transparency = 0.85, Parent = sv})
			local svGlow = softGlow(sv, color, 0.85, 34, 0)

			local satOverlay = create("Frame", {
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				Size = UDim2.fromScale(1, 1),
				Parent = sv,
			})
			round(satOverlay, 9)
			create("UIGradient", {
				Color = ColorSequence.new(Color3.fromRGB(255, 255, 255)),
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0),
					NumberSequenceKeypoint.new(1, 1),
				}),
				Parent = satOverlay,
			})
			local valOverlay = create("Frame", {
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				Size = UDim2.fromScale(1, 1),
				Parent = sv,
			})
			round(valOverlay, 9)
			create("UIGradient", {
				Rotation = 90,
				Color = ColorSequence.new(Color3.fromRGB(0, 0, 0)),
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 1),
					NumberSequenceKeypoint.new(1, 0),
				}),
				Parent = valOverlay,
			})
			local svPoint = create("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Size = UDim2.fromOffset(16, 16),
				BackgroundColor3 = color,
				Visible = false,
				Parent = sv,
			})
			roundFull(svPoint)
			create("UIStroke", {Color = Color3.fromRGB(255, 255, 255), Thickness = 2, Parent = svPoint})

			local display = create("Frame", {
				BackgroundColor3 = color,
				Size = UDim2.fromScale(1, 1),
				Parent = sv,
			})
			round(display, 9)

			local svHit = create("TextButton", {
				BackgroundTransparency = 1,
				Text = "",
				Size = UDim2.fromScale(1, 1),
				Parent = sv,
			})

			local hueBar = create("Frame", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -16, 0, 25),
				Size = UDim2.fromOffset(0, 0),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				Parent = card,
			})
			roundFull(hueBar)
			create("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)),
					ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
					ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
					ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 255, 255)),
					ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
					ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
					ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 0)),
				}),
				Parent = hueBar,
			})
			local huePoint = create("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0, 0, 0.5, 0),
				Size = UDim2.fromOffset(18, 18),
				BackgroundColor3 = Color3.fromHSV(h, 1, 1),
				Visible = false,
				Parent = hueBar,
			})
			roundFull(huePoint)
			create("UIStroke", {Color = Color3.fromRGB(255, 255, 255), Thickness = 2, Parent = huePoint})
			local hueHit = create("TextButton", {
				BackgroundTransparency = 1,
				Text = "",
				Size = UDim2.fromScale(1, 1),
				Parent = hueBar,
			})

			local alphaBar = create("Frame", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -16, 0, 25),
				Size = UDim2.fromOffset(0, 0),
				BackgroundColor3 = Color3.fromRGB(150, 150, 150),
				BackgroundTransparency = 1,
				Parent = card,
			})
			roundFull(alphaBar)
			local alphaFill = create("Frame", {
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = color,
				BackgroundTransparency = 1,
				Parent = alphaBar,
			})
			roundFull(alphaFill)
			local alphaGrad = create("UIGradient", {
				Color = ColorSequence.new(color),
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 1),
					NumberSequenceKeypoint.new(1, 0),
				}),
				Parent = alphaFill,
			})
			local alphaPoint = create("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(1, 0, 0.5, 0),
				Size = UDim2.fromOffset(18, 18),
				BackgroundColor3 = color,
				Visible = false,
				Parent = alphaBar,
			})
			roundFull(alphaPoint)
			create("UIStroke", {Color = Color3.fromRGB(255, 255, 255), Thickness = 2, Parent = alphaPoint})
			local alphaHit = create("TextButton", {
				BackgroundTransparency = 1,
				Text = "",
				Size = UDim2.fromScale(1, 1),
				Parent = alphaBar,
			})

			local revealers = {}
			local function addReveal(inst, prop, shown)
				table.insert(revealers, {inst = inst, prop = prop, shown = shown})
				inst[prop] = 1
			end
			local sliders = {}
			local function addSlide(inst, x, openY, closedY)
				table.insert(sliders, {inst = inst, x = x, openY = openY, closedY = closedY})
				inst.Position = UDim2.new(0, x, 0, closedY)
			end

			local function makeField(letter, boxX, y, boxW, initial)
				local box = create("Frame", {
					AnchorPoint = Vector2.new(0, 0.5),
					Size = UDim2.fromOffset(boxW, 30),
					BackgroundTransparency = 1,
					Parent = card,
				})
				paint(box, "BackgroundColor3", "CardInset")
				round(box, 8)
				local st = create("UIStroke", {Color = Theme.Stroke, Transparency = 1, Parent = box})
				local inset = 10
				if letter then
					local lab = create("TextLabel", {
						BackgroundTransparency = 1,
						Position = UDim2.fromOffset(10, 0),
						Size = UDim2.new(0, 12, 1, 0),
						Font = FONT_MEDIUM,
						TextSize = 12,
						Text = letter,
						TextTransparency = 1,
						Parent = box,
					})
					paint(lab, "TextColor3", "TextMuted")
					addReveal(lab, "TextTransparency", 0)
					inset = 26
				end
				local tb = create("TextBox", {
					BackgroundTransparency = 1,
					Position = UDim2.new(0, inset, 0, 0),
					Size = UDim2.new(1, -inset - 6, 1, 0),
					Font = FONT_MEDIUM,
					TextSize = 14,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextTruncate = Enum.TextTruncate.AtEnd,
					ClearTextOnFocus = false,
					Text = initial,
					TextTransparency = 1,
					Parent = box,
				})
				paint(tb, "TextColor3", "TextBody")
				addReveal(box, "BackgroundTransparency", 0)
				addReveal(st, "Transparency", 0.85)
				addReveal(tb, "TextTransparency", 0)
				addSlide(box, boxX, y, y + 16)
				tb.Focused:Connect(function()
					tween(st, TI_FAST, {Color = Theme.Accent, Transparency = 0.25})
				end)
				tb.FocusLost:Connect(function()
					tween(st, TI_FAST, {Color = Theme.Stroke, Transparency = 0.85})
				end)
				return tb
			end

			local hexTb = makeField(nil, 16, 70, 168, "#FFFFFF")
			local rTb = makeField("R", 16, 112, 52, "255")
			local gTb = makeField("G", 74, 112, 52, "255")
			local bTb = makeField("B", 132, 112, 52, "255")

			local preview = create("Frame", {
				AnchorPoint = Vector2.new(0, 0.5),
				Size = UDim2.fromOffset(168, 32),
				BackgroundColor3 = color,
				BackgroundTransparency = 1,
				Parent = card,
			})
			round(preview, 10)
			local previewStroke = create("UIStroke", {Color = Theme.Stroke, Transparency = 1, Parent = preview})
			addReveal(preview, "BackgroundTransparency", 0)
			addReveal(previewStroke, "Transparency", 0.85)
			addSlide(preview, 16, 155, 171)

			local presetColors = {
				Color3.fromRGB(255, 255, 255),
				Color3.fromRGB(255, 59, 48),
				Color3.fromRGB(255, 159, 10),
				Color3.fromRGB(255, 214, 10),
				Color3.fromRGB(52, 199, 89),
				Color3.fromRGB(10, 132, 255),
				Color3.fromRGB(191, 90, 242),
			}
			for idx, presetColor in ipairs(presetColors) do
				local dot = create("TextButton", {
					Text = "",
					AnchorPoint = Vector2.new(0.5, 0.5),
					Size = UDim2.fromOffset(18, 18),
					BackgroundColor3 = presetColor,
					BackgroundTransparency = 1,
					Parent = card,
				})
				roundFull(dot)
				local dotStroke = create("UIStroke", {Color = Theme.Stroke, Transparency = 1, Parent = dot})
				addReveal(dot, "BackgroundTransparency", 0)
				addReveal(dotStroke, "Transparency", 0.8)
				addSlide(dot, 25 + (idx - 1) * 25, 188, 204)
				dot.MouseEnter:Connect(function()
					if open then tween(dot, TI_FAST, {Size = UDim2.fromOffset(22, 22)}) end
				end)
				dot.MouseLeave:Connect(function()
					tween(dot, TI_FAST, {Size = UDim2.fromOffset(18, 18)})
				end)
				dot.MouseButton1Click:Connect(function()
					if not open then return end
					h, s, v = presetColor:ToHSV()
					refresh()
					push(true)
				end)
			end

			local clicker = create("TextButton", {
				BackgroundTransparency = 1,
				Text = "",
				Size = UDim2.fromScale(1, 1),
				Parent = card,
			})

			push = function(fire)
				local c = Color3.fromHSV(h, s, v)
				ColorPicker.Color = c
				ColorPicker.Alpha = alpha
				ColorPicker.alpha = alpha
				if fire then
					runCallback(ColorPickerSettings.Callback, c, alpha)
					saveConfiguration()
				end
			end

			refresh = function()
				local hueColor = Color3.fromHSV(h, 1, 1)
				sv.BackgroundColor3 = hueColor
				local c = Color3.fromHSV(h, s, v)
				display.BackgroundColor3 = c
				svPoint.BackgroundColor3 = c
				svPoint.Position = UDim2.new(s, 0, 1 - v, 0)
				huePoint.BackgroundColor3 = hueColor
				huePoint.Position = UDim2.new(h, 0, 0.5, 0)
				alphaFill.BackgroundColor3 = c
				alphaGrad.Color = ColorSequence.new(c)
				alphaPoint.BackgroundColor3 = c
				alphaPoint.Position = UDim2.new(alpha, 0, 0.5, 0)
				preview.BackgroundColor3 = c
				svGlow.ImageColor3 = c
				ColorPicker.Color = c
				ColorPicker.Alpha = alpha
				ColorPicker.alpha = alpha
				local r = math.floor(c.R * 255 + 0.5)
				local g = math.floor(c.G * 255 + 0.5)
				local b = math.floor(c.B * 255 + 0.5)
				if not rTb:IsFocused() then rTb.Text = tostring(r) end
				if not gTb:IsFocused() then gTb.Text = tostring(g) end
				if not bTb:IsFocused() then bTb.Text = tostring(b) end
				if not hexTb:IsFocused() then hexTb.Text = string.format("#%02X%02X%02X", r, g, b) end
			end

			local function setOpen(state)
				if state == open then return end
				open = state
				if open then
					tween(card, EXPO, {Size = UDim2.new(1, 0, 0, EXPANDED_H)})
					tween(clicker, EXPO, {Size = UDim2.new(1, 0, 0, COLLAPSED_H)})
					tween(sv, EXPO_FAST, {Size = UDim2.fromOffset(18, 15)})
					task.delay(0.09, function()
						if open then
							tween(sv, EXPO, {Position = UDim2.new(1, -16, 0, SV_CY), Size = UDim2.fromOffset(SV_W, SV_H)})
						end
					end)
					tween(display, EXPO, {BackgroundTransparency = 1})
					svPoint.Visible = true
					huePoint.Visible = true
					alphaPoint.Visible = true
					tween(hueBar, EXPO, {Position = UDim2.new(1, -16, 0, HUE_CY), Size = UDim2.fromOffset(SV_W, 14), BackgroundTransparency = 0})
					tween(alphaBar, EXPO, {Position = UDim2.new(1, -16, 0, ALPHA_CY), Size = UDim2.fromOffset(SV_W, 14), BackgroundTransparency = 0})
					tween(alphaFill, EXPO, {BackgroundTransparency = 0})
					for _, r in ipairs(revealers) do tween(r.inst, EXPO, {[r.prop] = r.shown}) end
					for _, sl in ipairs(sliders) do tween(sl.inst, EXPO, {Position = UDim2.new(0, sl.x, 0, sl.openY)}) end
				else
					tween(card, EXPO, {Size = UDim2.new(1, 0, 0, COLLAPSED_H)})
					tween(clicker, EXPO, {Size = UDim2.fromScale(1, 1)})
					tween(sv, EXPO, {Position = UDim2.new(1, -16, 0, 25), Size = UDim2.fromOffset(42, 26)})
					tween(display, EXPO, {BackgroundTransparency = 0})
					svPoint.Visible = false
					huePoint.Visible = false
					alphaPoint.Visible = false
					tween(hueBar, EXPO, {Position = UDim2.new(1, -16, 0, 25), Size = UDim2.fromOffset(0, 0), BackgroundTransparency = 1})
					tween(alphaBar, EXPO, {Position = UDim2.new(1, -16, 0, 25), Size = UDim2.fromOffset(0, 0), BackgroundTransparency = 1})
					tween(alphaFill, EXPO, {BackgroundTransparency = 1})
					for _, r in ipairs(revealers) do tween(r.inst, EXPO, {[r.prop] = 1}) end
					for _, sl in ipairs(sliders) do tween(sl.inst, EXPO, {Position = UDim2.new(0, sl.x, 0, sl.closedY)}) end
				end
			end
			clicker.MouseButton1Click:Connect(function()
				setOpen(not open)
			end)

			local svDragging = false
			local function svFromInput(px, py)
				local ax = math.clamp((px - sv.AbsolutePosition.X) / math.max(sv.AbsoluteSize.X, 1), 0, 1)
				local ay = math.clamp((py - sv.AbsolutePosition.Y) / math.max(sv.AbsoluteSize.Y, 1), 0, 1)
				s = ax
				v = 1 - ay
				refresh()
				push(true)
			end
			svHit.InputBegan:Connect(function(input)
				if not open then return end
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					svDragging = true
					svFromInput(input.Position.X, input.Position.Y)
				end
			end)

			local hueDragging = false
			local function hueFromInput(px)
				h = math.clamp((px - hueBar.AbsolutePosition.X) / math.max(hueBar.AbsoluteSize.X, 1), 0, 1)
				refresh()
				push(true)
			end
			hueHit.InputBegan:Connect(function(input)
				if not open then return end
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					hueDragging = true
					hueFromInput(input.Position.X)
				end
			end)

			local alphaDragging = false
			local function alphaFromInput(px)
				alpha = math.clamp((px - alphaBar.AbsolutePosition.X) / math.max(alphaBar.AbsoluteSize.X, 1), 0, 1)
				refresh()
				push(true)
			end
			alphaHit.InputBegan:Connect(function(input)
				if not open then return end
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					alphaDragging = true
					alphaFromInput(input.Position.X)
				end
			end)

			connect(UserInputService.InputChanged, function(input)
				if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
					if svDragging then svFromInput(input.Position.X, input.Position.Y) end
					if hueDragging then hueFromInput(input.Position.X) end
					if alphaDragging then alphaFromInput(input.Position.X) end
				end
			end)
			connect(UserInputService.InputEnded, function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					svDragging = false
					hueDragging = false
					alphaDragging = false
				end
			end)

			hexTb.FocusLost:Connect(function()
				local txt = string.gsub(hexTb.Text, "#", "")
				local rr, gg, bb = string.match(txt, "^(%x%x)(%x%x)(%x%x)$")
				if rr then
					h, s, v = Color3.fromRGB(tonumber(rr, 16), tonumber(gg, 16), tonumber(bb, 16)):ToHSV()
					refresh()
					push(true)
				else
					refresh()
				end
			end)
			local function commitRGB()
				local base = Color3.fromHSV(h, s, v)
				local rr = math.clamp(math.floor(tonumber(rTb.Text) or (base.R * 255 + 0.5)), 0, 255)
				local gg = math.clamp(math.floor(tonumber(gTb.Text) or (base.G * 255 + 0.5)), 0, 255)
				local bb = math.clamp(math.floor(tonumber(bTb.Text) or (base.B * 255 + 0.5)), 0, 255)
				h, s, v = Color3.fromRGB(rr, gg, bb):ToHSV()
				refresh()
				push(true)
			end
			rTb.FocusLost:Connect(commitRGB)
			gTb.FocusLost:Connect(commitRGB)
			bTb.FocusLost:Connect(commitRGB)

			function ColorPicker:Set(newColor, skipCallback)
				if type(newColor) == "string" then
					local hex = string.gsub(newColor, "#", "")
					local rr, gg, bb = string.match(hex, "^(%x%x)(%x%x)(%x%x)$")
					if not rr then return end
					newColor = Color3.fromRGB(tonumber(rr, 16), tonumber(gg, 16), tonumber(bb, 16))
				end
				h, s, v = newColor:ToHSV()
				refresh()
				push(not skipCallback)
			end

			function ColorPicker:SetAlpha(newAlpha, skipCallback)
				alpha = math.clamp(tonumber(newAlpha) or alpha, 0, 1)
				refresh()
				push(not skipCallback)
			end

			finalizeElement(ColorPicker, ColorPickerSettings, card, function(t)
				return rawget(t, "Color")
			end)

			refresh()
			return ColorPicker
		end

		function Tab:CreateRow()
			local rowFrame = create("Frame",{
				BackgroundTransparency = 1,
				AutomaticSize = Enum.AutomaticSize.Y,
				Size = UDim2.new(1,0, 0, 50),
				LayoutOrder = nextOrder(),
				Parent = page,
			})
			rowFrame:SetAttribute("Composite", true)
			create("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				VerticalAlignment=Enum.VerticalAlignment.Top,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 8),
				Parent = rowFrame,
			})
			local function recompute()
				local kids = {}
				for _, c in ipairs(rowFrame:GetChildren()) do
					if c:IsA("GuiObject") then table.insert(kids, c) end
				end
				local n = #kids
				if n == 0 then return end
				local adj = math.floor(8 * (n - 1) / n + 0.5)
				for _, c in ipairs(kids) do
					c.Size=UDim2.new(1 / n, -adj, 0, c.Size.Y.Offset)
				end
			end
			rowFrame.ChildAdded:Connect(function()
				task.defer(recompute);
			end)
			return buildTabAPI(rowFrame, true)
		end

		function Tab:CreateColumns(count)
			count = math.clamp(count or 2, 1, 4)
			local container = create("Frame", {
				BackgroundTransparency = 1,
				AutomaticSize = Enum.AutomaticSize.Y,
				Size = UDim2.new(1, 0, 0, 0),
				LayoutOrder = nextOrder(),
				Parent = page,
			})
			container:SetAttribute("Composite", true)
			create("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				VerticalAlignment = Enum.VerticalAlignment.Top,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0,10),
				Parent = container,
			})
			local apis = {}
			local adj = math.floor(10 * (count - 1) / count + 0.5)
			for i = 1, count do
				local column = create("Frame", {
					BackgroundTransparency = 1,
					AutomaticSize = Enum.AutomaticSize.Y,
					Size = UDim2.new(1 / count, -adj,0, 0),
					LayoutOrder = i,
					Parent = container,
				})
				create("UIListLayout", {
					FillDirection = Enum.FillDirection.Vertical,
					SortOrder=Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0,8),
					Parent = column,
				})
				table.insert(apis, buildTabAPI(column, true))
			end
			return table.unpack(apis)
		end

		function Tab:CreateGroup(groupSettings)
			groupSettings = normalizeProps(groupSettings)
			local direction = string.lower(tostring(groupSettings.Direction or "row"))
			if direction == "column" then
				local column = create("Frame", {
					BackgroundTransparency = 1,
					AutomaticSize = Enum.AutomaticSize.Y,
					Size = UDim2.new(1, 0, 0, 0),
					LayoutOrder = nextOrder(),
					Parent = page,
				})
				column:SetAttribute("Composite", true)
				create("UIListLayout", {
					FillDirection = Enum.FillDirection.Vertical,
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 8),
					Parent = column,
				})
				return buildTabAPI(column, true)
			end
			return Tab:CreateRow()
		end

		Tab.CreateSwitch = Tab.CreateToggle

		return Tab
	end

	function Window:CreateTab(tabName, tabImage, _ext)
		if type(tabName) == "table" then
			local p = normalizeProps(tabName)
			tabName = p.Name or p.Title
			tabImage = p.Icon
		end
		local page, pageWrapper = buildPage()
		local Tab = buildTabAPI(page)

		local pill = create("TextButton", {
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.new(0, 0, 0, 44),
			Text = "",
			BackgroundTransparency = 0.35,
			LayoutOrder = #tabs + 1,
			Parent = tabBar,
		})
		pill.BackgroundColor3 = Theme.CardInset
		roundFull(pill)

		create("UIGradient", {
			Rotation = 90,
			Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(200, 200,200)),
			Parent = pill,
		})

		local pillStroke = create("UIStroke", {Color = Color3.fromRGB(255, 255, 255), Transparency = 0.62,Thickness = 1,ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = pill})
		create("UIGradient", {
			Rotation = 90,
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(1, 0.75),
			}),
			Parent = pillStroke,
		})
		padAll(pill, 0, 22, 0, 22)
		create("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 8),
			Parent = pill,
		})
		local pillIcon = nil
		if tabImage and tabImage ~= 0 and tabImage ~= "" then
			pillIcon = makeIcon(pill, tabImage, 18, Theme.TextSub)
			if pillIcon then pillIcon.LayoutOrder = 1 end
		end
		local pillLabel = create("TextLabel",{
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.new(0, 0, 1, 0),
			Font = FONT_MEDIUM,
			TextSize = 16,
			Text = tabName or "Tab",
			TextColor3 = Theme.TextSub,
			LayoutOrder=2,
			Parent = pill,
		})
		registerTr(pillLabel, tabName or "Tab")

		local tabEntry = {
			Name = tabName,
			Page = page,
			Wrapper = pageWrapper,
			Pill = pill,
			PillLabel = pillLabel,
			PillIcon = pillIcon,
			PillStroke = pillStroke,
			API = Tab,
		}
		table.insert(tabs, tabEntry)

		pill.MouseButton1Click:Connect(function()
			selectTab(tabEntry)
		end)

		if #tabs == 1 then
			currentTab = tabEntry
			settingsOpen=false
			styleTabPills()
			pageWrapper.Visible = true
		end

		function Tab:Select()
			selectTab(tabEntry)
		end

		function Tab:Deselect()
			if currentTab ~= tabEntry then return end
			for _, other in ipairs(tabs) do
				if other ~= tabEntry then
					selectTab(other)
					return
				end
			end
		end

		function Tab:Remove()
			for i, other in ipairs(tabs) do
				if other == tabEntry then
					table.remove(tabs, i)
					break
				end
			end
			pill:Destroy()
			pageWrapper:Destroy()
			if currentTab == tabEntry then
				currentTab = nil
				if tabs[1] then selectTab(tabs[1]) end
			end
		end

		return Tab
	end

	local toggleKeyName = "K"
	if Settings.ToggleUIKeybind then
		if typeof(Settings.ToggleUIKeybind) == "EnumItem" then
			toggleKeyName = Settings.ToggleUIKeybind.Name
		else
			toggleKeyName = tostring(Settings.ToggleUIKeybind)
		end
	end

	local function buildSettingsPage()
		local page, pageWrapper = buildPage()
		settingsEntry = {Page = page, Wrapper = pageWrapper}
		local SettingsTab = buildTabAPI(page)
		SettingsTab:CreateSection("Interface")
		SettingsTab:CreateKeybind({
			Name = "Toggle UI",
			Icon = "eye",
			CurrentKeybind = toggleKeyName,
			CallOnChange = true,
			Callback = function(newKey)
				toggleKeyName = newKey
			end,
		})
		SettingsTab:CreateSlider({
			Name = "UI scale",
			Icon = "maximize-2",
			Description = "Scales the whole interface. It also adjusts automatically to fit small screens like phones.",
			Range = {60, 130},
			Increment = 5,
			Suffix = "%",
			CurrentValue = math.floor(userUiScale * 100 + 0.5),
			Callback = function(value)
				setUserUiScale(value / 100)
			end,
		})
		SettingsTab:CreateToggle({
			Name = "Unlock cursor while open",
			Icon = "mouse-pointer-2",
			CurrentValue=false,
			Description = "Unlocks the cursor while the menu is open so you can configure in FPS games that lock it.",
			Callback = function(value)
				unlockCursor=value
			end,
		})
		SettingsTab:CreateSection("Configuration")
		SettingsTab:CreateLabel(configEnabled and ("Saving to " .. configFolder .. "/" .. configFile .. configExt) or "Configuration saving is off", "folder")
		SettingsTab:CreateSection("About")
		SettingsTab:CreateParagraph({
			Title = "Rayfield Gen 2 [fanmade]",
			Content = "Unofficial rebuild of the Rayfield Interface Suite. Original Rayfield by Sirius.",
		})
		SettingsTab:CreateButton({
			Name = "Unload interface",
			Icon = "trash-2",
			Callback = function()
				RayfieldLibrary:Destroy()
			end,
		})
	end

	settingsButton.MouseButton1Click:Connect(function()
		if not settingsEntry then buildSettingsPage() end
		settingsOpen = not settingsOpen
		styleTabPills()
		if settingsOpen then
			showPage(settingsEntry)
		elseif currentTab then
			showPage(currentTab)
		end
	end)

	local userMoved = false

	local function clampPos(pos)
		local vp = rootGui.AbsoluteSize
		if vp.X < 50 or vp.Y < 50 then return pos end
		local s = currentUiScale()
		local halfW = WINDOW_W * s / 2
		local ax = vp.X * pos.X.Scale + pos.X.Offset
		local ay = vp.Y * pos.Y.Scale + pos.Y.Offset
		local minX, maxX = halfW + 6, vp.X - halfW - 6
		if minX > maxX then
			minX, maxX = vp.X / 2, vp.X / 2
		end
		local nx = math.clamp(ax, minX, maxX)
		local ny = math.clamp(ay, 6, math.max(6, vp.Y - HEADER_H * s - 6))
		if math.abs(nx - ax) < 0.5 and math.abs(ny - ay) < 0.5 then return pos end
		return UDim2.fromOffset(math.floor(nx + 0.5), math.floor(ny + 0.5))
	end

	local function clampRoot(animated, fromPos)
		if hidden or destroyed then return end
		local target = clampPos(fromPos or root.Position)
		if target == (fromPos or root.Position) then return end
		if animated then
			tween(root, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = target})
		else
			root.Position = target
		end
	end

	local function makeDraggable(zone)
		local dragging = false
		local dragStart = nil
		local startPos=nil
		local lastTarget = nil
		zone.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				if morphing or hidden then return end
				dragging = true
				dragStart = input.Position
				startPos = root.Position
				lastTarget = nil
			end
		end)
		zone.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = false
				if lastTarget then
					userMoved = true
					clampRoot(true, lastTarget)
					lastTarget = nil
				end
			end
		end)
		connect(UserInputService.InputChanged, function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				local delta = input.Position - dragStart
				lastTarget = UDim2.new(
					startPos.X.Scale, startPos.X.Offset + delta.X,
					startPos.Y.Scale, startPos.Y.Offset + delta.Y
				)
				tween(root, TweenInfo.new(0.3, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {
					Position = lastTarget,
				})
			end
		end)
	end
	makeDraggable(header)
	makeDraggable(handle)

	local function refitRoot()
		if destroyed or hidden or morphing then return end
		if userMoved then
			clampRoot(false)
		else
			root.Position = shownPos()
		end
	end
	connect(rootGui:GetPropertyChangedSignal("AbsoluteSize"), refitRoot)
	onUiScaleChanged(refitRoot)

	local function setMinimizeIcon(restore)
		applyLucide(minimizeIcon, restore and {"maximize-2", "expand"} or {"minus"})
	end

	local function setMinimized(value)
		if morphing or hidden then return end
		minimized = value
		setMinimizeIcon(minimized)
		tween(window, TI_MORPH, {Size=UDim2.fromOffset(WINDOW_W, minimized and HEADER_H or WINDOW_H)})
	end

	minimizeButton.MouseButton1Click:Connect(function()
		setMinimized(not minimized)
	end)

	local function hideWindow()
		if morphing or hidden then return end
		morphing = true
		hidden = true
		storedPosition = root.Position
		tween(handle, TI_FAST,{BackgroundTransparency = 1})
		tween(main, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),{GroupTransparency = 1})
		task.wait(0.17)
		main.Visible = false
		tween(windowCorner, TI_MORPH, {CornerRadius = UDim.new(0, math.floor(PILL_H / 2))})
		tween(window, TI_MORPH, {Size = UDim2.fromOffset(PILL_W, PILL_H)})

		tween(window, TI_MORPH, {BackgroundColor3 = Color3.fromRGB(46,46, 46)})
		tween(windowStroke, TI_MORPH, {Transparency = 0.45});
		tween(shadow, TI_MORPH, {ImageTransparency = 0.55})
		tween(root, TI_MORPH, {Position = UDim2.new(0.5, 0, 0, 16)})
		task.wait(0.34)
		pillContent.Visible = true
		pillButton.Visible = true
		tween(pillContent, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {GroupTransparency = 0})
		morphing = false
	end

	local function showWindow()
		if morphing or not hidden then return end
		morphing = true
		hidden = false
		tween(pillContent, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {GroupTransparency = 1})
		task.wait(0.14)
		pillContent.Visible = false
		pillButton.Visible = false
		tween(windowCorner, TI_MORPH, {CornerRadius = UDim.new(0,24)})
		tween(window, TI_MORPH, {Size = UDim2.fromOffset(WINDOW_W, minimized and HEADER_H or WINDOW_H)})
		tween(window, TI_MORPH,{BackgroundColor3 = Theme.Background})
		tween(windowStroke, TI_MORPH, {Transparency = 0.93})
		tween(shadow,TI_MORPH, {ImageTransparency = 0.42})
		tween(root, TI_MORPH, {Position = clampPos(storedPosition or shownPos())})
		task.wait(0.36)
		main.Visible = true
		tween(main, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {GroupTransparency = 0})
		tween(handle, TI_MED, {BackgroundTransparency = 0.35})
		morphing = false
	end

	closeButton.MouseButton1Click:Connect(function()
		task.spawn(hideWindow)
	end)
	pillButton.MouseButton1Click:Connect(function()
		task.spawn(showWindow)
	end)

	connect(UserInputService.InputBegan, function(input, processed)
		if processed then return end
		if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode.Name == toggleKeyName then
			if hidden then
				task.spawn(showWindow)
			else
				task.spawn(hideWindow)
			end
		end
	end)

	RayfieldLibrary._hideWindow = hideWindow
	RayfieldLibrary._showWindow = showWindow
	RayfieldLibrary._isHidden = function() return hidden end

	function Window:Show()
		if hidden then task.spawn(showWindow) end
	end

	function Window:Hide()
		if not hidden then task.spawn(hideWindow) end
	end

	function Window:ToggleHide()
		if hidden then
			task.spawn(showWindow)
		else
			task.spawn(hideWindow)
		end
	end

	function Window:ToggleMinimise()
		setMinimized(not minimized)
	end
	Window.ToggleMinimize = Window.ToggleMinimise

	function Window:SetUIScale(factor)
		setUserUiScale(tonumber(factor) or 1)
	end

	function Window:GetUIScale()
		return currentUiScale()
	end

	function Window:SetLocale(id)
		i18n.locale = id and tostring(id) or nil
		retranslate()
	end

	function Window:SetTranslator(fn)
		i18n.translator = type(fn) == "function" and fn or nil
		retranslate()
	end

	function Window:RegisterTranslations(t)
		registerTranslations(t)
		retranslate()
	end

	function Window:Navigate(target)
		for _, entry in ipairs(tabs) do
			if entry.API == target or entry.Name == target then
				selectTab(entry)
				return true
			end
		end
		return false
	end

	function Window:Unload()
		RayfieldLibrary:Destroy()
	end

	function Window:Notify(data)
		return RayfieldLibrary:Notify(data)
	end

	function Window:Toast(data)
		return RayfieldLibrary:Toast(data)
	end

	function Window:Popup(data)
		return RayfieldLibrary:Popup(data)
	end

	function Window:Get(flag)
		local element = RayfieldLibrary.Flags[flag]
		if element then return element.value end
		return nil
	end

	function Window:Set(flag, newValue)
		local element = RayfieldLibrary.Flags[flag]
		if not element or type(rawget(element, "Set")) ~= "function" then return false end
		element:Set(newValue)
		return true
	end

	Window.Flags = setmetatable({}, {
		__index = function(_, flag)
			return Window:Get(flag)
		end,
		__newindex = function(_, flag, newValue)
			Window:Set(flag, newValue)
		end,
		__iter = function()
			local snapshot = {}
			for flag, element in pairs(RayfieldLibrary.Flags) do
				snapshot[flag] = element.value
			end
			return next, snapshot
		end,
	})

	local function cleanConfigName(name)
		if name == nil then return nil end
		return string.gsub(tostring(name), "[/\\]", "")
	end

	function Window:Save(name)
		return writeConfiguration(cleanConfigName(name))
	end

	function Window:Load(name)
		return applyConfiguration(cleanConfigName(name))
	end

	function Window.ModifyTheme(newTheme)
		if type(newTheme) == "table" then
			for k, v in pairs(newTheme) do
				if Theme[k] ~= nil and typeof(v) == "Color3" then
					Theme[k] = v
				end
			end
			repaint()
		end
	end

	function Window:ChangeTheme(newTheme)
		applyTheme(newTheme, true)
	end

	function Window:SetTitle(newTitle)
		titleLabel.Text = newTitle or titleLabel.Text
	end

	function Window:SetSubtitle(newSubtitle)
		subtitleLabel.Text = newSubtitle or subtitleLabel.Text
	end

	local hasLoading = (Settings.LoadingTitle and Settings.LoadingTitle ~= "") or (Settings.LoadingSubtitle and Settings.LoadingSubtitle ~= "")

	if hasLoading then

		morphing = true
		local LOAD_W, LOAD_H = 320, 140
		window.Size = UDim2.fromOffset(LOAD_W, LOAD_H)
		root.Position = UDim2.new(0.5, 0, 0.5, -math.floor(LOAD_H / 2) - 9)

		local loading = create("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(LOAD_W, LOAD_H),
			ZIndex=5,
			Parent = window,
		})
		local spinner = create("ImageLabel", {
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5,0),
			Position = UDim2.new(0.5, 0, 0, 26),
			Size = UDim2.fromOffset(24, 24),
			ImageColor3 = Theme.TextTitle,
			ImageTransparency = 0,
			Parent = loading,
		})
		applyLucide(spinner,{"loader"})
		tween(spinner, TweenInfo.new(1.1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1), {Rotation = 360})
		create("TextLabel", {
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, 62),
			Size = UDim2.new(1, -40, 0, 22),
			Font = FONT_BOLD,
			TextSize = 18,
			Text = Settings.LoadingTitle or Settings.Name or "Rayfield",
			TextColor3 = Theme.TextTitle,
			Parent = loading,
		})
		create("TextLabel", {
			BackgroundTransparency=1,
			AnchorPoint = Vector2.new(0.5,0),
			Position = UDim2.new(0.5,0, 0, 88),
			Size = UDim2.new(1, -40, 0, 18),
			Font = FONT_MEDIUM,
			TextSize = 14,
			Text = Settings.LoadingSubtitle or "Rayfield Gen2",
			TextColor3 = Theme.TextSub,
			Parent = loading,
		})

		task.spawn(function()
			task.wait(1.15)
			if destroyed or not window.Parent then
				morphing = false
				return
			end
			tween(loading, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),{BackgroundTransparency = 1});
			for _, child in ipairs(loading:GetChildren()) do
				if child:IsA("TextLabel") then
					tween(child, TweenInfo.new(0.16), {TextTransparency = 1})
				elseif child:IsA("ImageLabel") then
					tween(child, TweenInfo.new(0.16), {ImageTransparency = 1})
				end
			end
			task.wait(0.16)
			loading:Destroy()
			tween(window, TI_SLOW, {Size = UDim2.fromOffset(WINDOW_W, WINDOW_H)})
			tween(root, TI_SLOW, {Position = shownPos()})
			task.wait(0.18)
			tween(main, TweenInfo.new(0.32, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {GroupTransparency = 0})
			tween(handle, TI_SLOW, {BackgroundTransparency = 0.35})
			task.wait(0.34)
			morphing = false
		end)
	else
		window.Size = UDim2.fromOffset(WINDOW_W - 48, WINDOW_H - 56)
		shadow.ImageTransparency = 1
		tween(window, TI_SLOW, {Size = UDim2.fromOffset(WINDOW_W, WINDOW_H)});
		tween(shadow, TI_SLOW,{ImageTransparency = 0.42})
		tween(main,TweenInfo.new(0.45,Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {GroupTransparency = 0})
		tween(handle, TI_SLOW, {BackgroundTransparency = 0.35})
	end

	function RayfieldLibrary:LoadConfiguration()
		applyConfiguration(nil)
	end

	if officialConfig and officialConfig.AutoLoad and configEnabled then
		task.delay(1.2, function()
			if not destroyed then
				applyConfiguration(nil, true)
			end
		end)
	end

	return Window
end

function RayfieldLibrary:IsVisible()
	if RayfieldLibrary._isHidden then
		return not RayfieldLibrary._isHidden()
	end
	return rootGui ~= nil
end


function RayfieldLibrary:SetUIScale(factor)
	setUserUiScale(tonumber(factor) or 1)
end

function RayfieldLibrary:GetUIScale()
	return currentUiScale()
end

function RayfieldLibrary:SetVisibility(visible)
	if visible and RayfieldLibrary._showWindow then
		task.spawn(RayfieldLibrary._showWindow);
	elseif not visible and RayfieldLibrary._hideWindow then
		task.spawn(RayfieldLibrary._hideWindow)
	end
end

function RayfieldLibrary:Destroy()
	destroyed = true
	for _, c in ipairs(Connections) do
		pcall(function() c:Disconnect() end)
	end
	Connections = {}
	if rootGui then
		rootGui:Destroy()
		rootGui = nil
	end
end

return RayfieldLibrary
