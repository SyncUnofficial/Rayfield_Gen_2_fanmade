--[[
	Rayfield Gen 2 [fanmade]

	Unofficial rebuild of the Rayfield Interface Suite with a new look.
	Keeps the original Rayfield API so most existing scripts drop in:
	CreateWindow, CreateTab, CreateSection, CreateButton, CreateToggle,
	CreateSlider, CreateInput, CreateDropdown, CreateKeybind, CreateLabel,
	CreateParagraph, CreateColorPicker, Notify, Flags, config saving,
	key system, loading screen.

	Gen 2 additions: header badge, search that filters elements, stat cards,
	hide to pill animation, minimize to bar, sign in toast.

	Original Rayfield by Sirius (sirius.menu). This project is not
	affiliated with or endorsed by them.
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local TextService = game:GetService("TextService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

-- executor environment shims

local useStudio = RunService:IsStudio()

local fsAvailable = (writefile and readfile and isfile and isfolder and makefolder) and true or false

local function safeReadFile(path)
	if not fsAvailable then return nil end
	local ok, result = pcall(function()
		if isfile(path) then return readfile(path) end
		return nil
	end)
	if ok then return result end
	return nil
end

local function safeWriteFile(path, content)
	if not fsAvailable then return false end
	local ok = pcall(writefile, path, content)
	return ok
end

local function ensureFolder(path)
	if not fsAvailable then return false end
	local ok = pcall(function()
		if not isfolder(path) then makefolder(path) end
	end)
	return ok
end

local BASE_FOLDER = "Rayfield Gen2"
ensureFolder(BASE_FOLDER)

local function httpGet(url)
	local ok, result = pcall(function()
		return game:HttpGet(url)
	end)
	if ok and type(result) == "string" and #result > 0 then
		return result
	end
	local ok2, result2 = pcall(function()
		local req = (syn and syn.request) or request or http_request
		if not req then return nil end
		local response = req({Url = url, Method = "GET"})
		return response and response.Body or nil
	end)
	if ok2 and type(result2) == "string" and #result2 > 0 then
		return result2
	end
	return nil
end

local function getGuiParent()
	if useStudio then
		return LocalPlayer:WaitForChild("PlayerGui")
	end
	local ok, hui = pcall(function()
		return gethui and gethui() or nil
	end)
	if ok and hui then return hui end
	local ok2 = pcall(function()
		local probe = Instance.new("Folder")
		probe.Parent = CoreGui
		probe:Destroy()
	end)
	if ok2 then return CoreGui end
	return LocalPlayer:WaitForChild("PlayerGui")
end

-- theme

local Theme = {
	Background       = Color3.fromRGB(20, 20, 20),
	Card             = Color3.fromRGB(31, 31, 31),
	CardHover        = Color3.fromRGB(39, 39, 39),
	CardSelected     = Color3.fromRGB(48, 48, 48),
	CardInset        = Color3.fromRGB(24, 24, 24),
	SearchBox        = Color3.fromRGB(44, 44, 44),
	Stroke           = Color3.fromRGB(255, 255, 255),
	TextTitle        = Color3.fromRGB(247, 247, 247),
	TextBody         = Color3.fromRGB(233, 233, 233),
	TextSub          = Color3.fromRGB(152, 152, 152),
	TextMuted        = Color3.fromRGB(110, 110, 110),
	AccentDark       = Color3.fromRGB(54, 104, 80),
	Accent           = Color3.fromRGB(70, 168, 120),
	AccentSoft       = Color3.fromRGB(104, 210, 156),
	Knob             = Color3.fromRGB(255, 255, 255),
	KnobOff          = Color3.fromRGB(66, 68, 70),
	ToggleTrack      = Color3.fromRGB(18, 18, 18),
	BadgeBackground  = Color3.fromRGB(240, 166, 63),
	BadgeText        = Color3.fromRGB(66, 45, 15),
	NotifyBackground = Color3.fromRGB(16, 16, 16),
}

local painted = {}

local function paint(inst, prop, key)
	inst[prop] = Theme[key]
	table.insert(painted, {inst, prop, key})
end

local function repaint()
	for _, entry in ipairs(painted) do
		local inst, prop, key = entry[1], entry[2], entry[3]
		if inst and inst.Parent and Theme[key] then
			pcall(function() inst[prop] = Theme[key] end)
		end
	end
end

-- instance helpers

local function create(class, props, children)
	local inst = Instance.new(class)
	local parent = nil
	if props then
		for k, v in pairs(props) do
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

local function round(inst, radius)
	return create("UICorner", {CornerRadius = UDim.new(0, radius), Parent = inst})
end

local function roundFull(inst)
	return create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = inst})
end

local function padAll(inst, top, right, bottom, left)
	return create("UIPadding", {
		PaddingTop = UDim.new(0, top or 0),
		PaddingRight = UDim.new(0, right or 0),
		PaddingBottom = UDim.new(0, bottom or 0),
		PaddingLeft = UDim.new(0, left or 0),
		Parent = inst,
	})
end

-- soft blurred glow or shadow behind an element, 9 slice
local GLOW_IMAGE = "rbxassetid://6014261993"

local function softGlow(parent, color, transparency, spread, zindex)
	return create("ImageLabel", {
		Name = "Glow",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, spread, 1, spread),
		Image = GLOW_IMAGE,
		ImageColor3 = color,
		ImageTransparency = transparency,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(49, 49, 450, 450),
		ZIndex = zindex or 0,
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

local TI_FAST = TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TI_MED = TweenInfo.new(0.26, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local TI_SMOOTH = TweenInfo.new(0.32, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
local TI_MORPH = TweenInfo.new(0.42, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local TI_SLOW = TweenInfo.new(0.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)

local function tween(inst, info, props)
	local t = TweenService:Create(inst, info, props)
	t:Play()
	return t
end

local function measureText(text, size, font)
	local ok, result = pcall(function()
		return TextService:GetTextSize(text, size, font, Vector2.new(1000, 100))
	end)
	if ok then return result end
	return Vector2.new(#text * size * 0.5, size)
end

-- icons
-- lucide icons through the same generated index original Rayfield uses.
-- the index is an older lucide set, so newer names are mapped back through
-- aliases. the index is cached to disk so icons work offline after one run.

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
	name = string.lower(name)
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
	local cachePath = BASE_FOLDER .. "/icons_cache.lua"
	local source = safeReadFile(cachePath)
	local fresh = false
	if not source then
		source = httpGet("https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/refs/heads/main/icons.lua")
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
			safeWriteFile(cachePath, source)
		end
	elseif not fresh then
		-- stale or corrupted cache, refetch once
		source = httpGet("https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/refs/heads/main/icons.lua")
		if source then
			local ok2, result2 = pcall(function()
				local chunk = loadstring(source)
				return chunk and chunk() or nil
			end)
			if ok2 and type(result2) == "table" and result2["48px"] then
				Icons = result2
				safeWriteFile(cachePath, source)
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
		for _ = 1, 12 do
			task.wait(2.5)
			loadIcons()
			if Icons then
				flushPendingIcons()
				return
			end
		end
	end)
end

-- applies a lucide icon (accepts a list of candidate names) to an ImageLabel,
-- deferring until the index is available if needed
local function applyLucide(img, names, onApplied)
	if type(names) == "string" then names = {names} end
	if Icons then
		for _, name in ipairs(names) do
			local asset = getLucide(name)
			if asset then
				img.Image = "rbxassetid://" .. tostring(asset.id)
				img.ImageRectSize = asset.size
				img.ImageRectOffset = asset.offset
				if onApplied then onApplied() end
				return true
			end
		end
		local wanted = names[1]
		if not warnedIcons[wanted] then
			warnedIcons[wanted] = true
			warn("Rayfield Gen2 | Unknown icon \"" .. tostring(wanted) .. "\"")
		end
		return false
	end
	table.insert(pendingIcons, {img = img, names = names, onApplied = onApplied})
	return false
end

-- makes an ImageLabel for an icon which may be a lucide name, an asset id
-- number, or a full rbxassetid string
local function makeIcon(parent, icon, size, color3, transparency)
	if icon == nil or icon == 0 or icon == "" then return nil end
	local img = create("ImageLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(size, size),
		ImageColor3 = color3 or Theme.TextTitle,
		ImageTransparency = transparency or 0,
		Parent = parent,
	})
	if type(icon) == "number" then
		img.Image = "rbxassetid://" .. tostring(icon)
	elseif type(icon) == "string" then
		if string.find(icon, "rbxasset") or string.find(icon, "://") then
			img.Image = icon
		else
			applyLucide(img, icon)
		end
	end
	return img
end

-- library

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

local rootGui = nil
local notifyStack = nil
local destroyed = false

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
	rootGui.Parent = getGuiParent()

	notifyStack = create("Frame", {
		Name = "Notifications",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(24, 24),
		Size = UDim2.fromOffset(330, 900),
		Parent = rootGui,
	})
	create("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 10),
		Parent = notifyStack,
	})
	return rootGui
end

-- notifications

local notifyOrder = 0

function RayfieldLibrary:Notify(data)
	data = data or {}
	ensureRoot()
	notifyOrder = notifyOrder + 1

	local wrapper = create("Frame", {
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Size = UDim2.new(1, 0, 0, 0),
		LayoutOrder = notifyOrder,
		Parent = notifyStack,
	})

	local card = create("Frame", {
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		Position = UDim2.fromOffset(-370, 0),
		BackgroundColor3 = Theme.NotifyBackground,
	})
	round(card, 18)
	create("UIStroke", {Color = Color3.fromRGB(255, 255, 255), Transparency = 0.92, Parent = card})
	create("UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(170, 170, 170)),
		Parent = card,
	})
	softGlow(card, Color3.fromRGB(0, 0, 0), 0.6, 38)
	padAll(card, 15, 18, 15, 16)

	local hasIcon = data.Image ~= nil and data.Image ~= "" and data.Image ~= 0
	if hasIcon then
		local iconHolder = create("Frame", {
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 0, 0.5, 0),
			Size = UDim2.fromOffset(38, 38),
			Parent = card,
		})
		local icon = makeIcon(iconHolder, data.Image, 27, Theme.TextTitle)
		if icon then
			icon.AnchorPoint = Vector2.new(0.5, 0.5)
			icon.Position = UDim2.fromScale(0.5, 0.5)
		end
	end

	local textCol = create("Frame", {
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
		Position = UDim2.fromOffset(hasIcon and 52 or 2, 0),
		Size = UDim2.new(1, hasIcon and -52 or -2, 0, 0),
		Parent = card,
	})
	create("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 3),
		Parent = textCol,
	})
	create("TextLabel", {
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		Font = FONT_BOLD,
		TextSize = 17,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = data.Title or "Notification",
		TextColor3 = Theme.TextTitle,
		LayoutOrder = 1,
		Parent = textCol,
	})
	create("TextLabel", {
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		Font = FONT_MEDIUM,
		TextSize = 15,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = data.Content or "",
		TextColor3 = Theme.TextSub,
		LayoutOrder = 2,
		Parent = textCol,
	})

	local clicker = create("TextButton", {
		BackgroundTransparency = 1,
		Text = "",
		Size = UDim2.fromScale(1, 1),
		ZIndex = 5,
		Parent = card,
	})

	card.Parent = wrapper

	local paused = false
	local dismissed = false
	clicker.MouseEnter:Connect(function() paused = true end)
	clicker.MouseLeave:Connect(function() paused = false end)

	local function dismiss()
		if dismissed then return end
		dismissed = true
		wrapper.ClipsDescendants = true
		tween(card, TI_SMOOTH, {Position = UDim2.fromOffset(-370, 0)})
		task.wait(0.2)
		tween(wrapper, TI_MED, {Size = UDim2.new(1, 0, 0, 0)})
		task.wait(0.28)
		wrapper:Destroy()
	end

	clicker.MouseButton1Click:Connect(function()
		task.spawn(dismiss)
	end)

	task.defer(function()
		task.wait()
		local height = card.AbsoluteSize.Y
		wrapper.Size = UDim2.new(1, 0, 0, height)
		card.Position = UDim2.fromOffset(-370, 0)
		tween(card, TI_MORPH, {Position = UDim2.fromOffset(0, 0)})
		-- unclip once in place so the soft shadow can bleed past the card
		task.delay(0.3, function()
			if not dismissed and wrapper.Parent then
				wrapper.ClipsDescendants = false
			end
		end)

		local duration = data.Duration or 5
		local elapsed = 0
		while elapsed < duration and not dismissed do
			local dt = task.wait(0.1)
			if not paused then elapsed = elapsed + dt end
		end
		dismiss()
	end)
end

-- sign in toast

local function showAccountToast()
	if not LocalPlayer then return end
	ensureRoot()
	notifyOrder = notifyOrder + 1

	local wrapper = create("Frame", {
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Size = UDim2.new(0, 240, 0, 58),
		LayoutOrder = notifyOrder,
		Parent = notifyStack,
	})
	local pill = create("Frame", {
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.new(0, 0, 0, 54),
		Position = UDim2.fromOffset(-280, 0),
		BackgroundColor3 = Theme.NotifyBackground,
	})
	roundFull(pill)
	create("UIStroke", {Color = Color3.fromRGB(255, 255, 255), Transparency = 0.92, Parent = pill})
	create("UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(170, 170, 170)),
		Parent = pill,
	})
	padAll(pill, 6, 20, 6, 6)
	create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
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

	local textCol = create("Frame", {
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.new(0, 0, 1, 0),
		LayoutOrder = 2,
		Parent = pill,
	})
	create("TextLabel", {
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.new(0, 0, 0, 14),
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
		Size = UDim2.new(0, 0, 0, 16),
		Position = UDim2.fromOffset(0, 25),
		Font = FONT_BOLD,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = LocalPlayer.DisplayName or LocalPlayer.Name,
		TextColor3 = Theme.TextTitle,
		Parent = textCol,
	})

	pill.Parent = wrapper
	tween(pill, TI_MORPH, {Position = UDim2.fromOffset(0, 0)})
	task.delay(4, function()
		tween(pill, TI_SMOOTH, {Position = UDim2.fromOffset(-280, 0)})
		task.wait(0.25)
		tween(wrapper, TI_MED, {Size = UDim2.new(0, 240, 0, 0)})
		task.wait(0.26)
		wrapper:Destroy()
	end)
end

-- key system

local function runKeySystem(Settings)
	local keySettings = Settings.KeySettings or {}
	local fileName = keySettings.FileName or "Key"
	local keyPath = BASE_FOLDER .. "/" .. fileName .. ".txt"

	local keys = {}
	local rawKey = keySettings.Key or {}
	if type(rawKey) == "string" then rawKey = {rawKey} end

	if keySettings.GrabKeyFromSite then
		for _, url in ipairs(rawKey) do
			local body = httpGet(tostring(url))
			if body then
				body = string.gsub(body, "%s+$", "")
				body = string.gsub(body, "^%s+", "")
				table.insert(keys, body)
			end
		end
	else
		for _, k in ipairs(rawKey) do
			table.insert(keys, tostring(k))
		end
	end

	local function isValid(candidate)
		candidate = string.gsub(tostring(candidate), "^%s+", "")
		candidate = string.gsub(candidate, "%s+$", "")
		for _, k in ipairs(keys) do
			if candidate == k then return true end
		end
		return false
	end

	if #keys == 0 then
		warn("Rayfield Gen2 | Key system enabled but no keys resolved, skipping")
		return true
	end

	if keySettings.SaveKey then
		local saved = safeReadFile(keyPath)
		if saved and isValid(saved) then
			return true
		end
	end

	ensureRoot()

	local overlay = create("Frame", {
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 50,
		Parent = rootGui,
	})
	tween(overlay, TI_MED, {BackgroundTransparency = 0.45})

	local card = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.52),
		Size = UDim2.fromOffset(360, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Theme.Background,
		ZIndex = 51,
		Parent = overlay,
	})
	round(card, 20)
	create("UIStroke", {Color = Color3.fromRGB(255, 255, 255), Transparency = 0.92, Parent = card})
	create("UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(160, 160, 160)),
		Parent = card,
	})
	padAll(card, 24, 22, 22, 22)
	create("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 10),
		Parent = card,
	})

	local well = create("Frame", {
		BackgroundColor3 = Theme.Card,
		Size = UDim2.fromOffset(52, 52),
		LayoutOrder = 1,
		Parent = card,
	})
	roundFull(well)
	local keyIcon = makeIcon(well, "key-round", 26, Theme.TextTitle)
	if keyIcon then
		keyIcon.AnchorPoint = Vector2.new(0.5, 0.5)
		keyIcon.Position = UDim2.fromScale(0.5, 0.5)
	end

	create("TextLabel", {
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
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
		Size = UDim2.new(1, 0, 0, 0),
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
		Size = UDim2.new(1, 0, 0, 44),
		LayoutOrder = 5,
		Parent = card,
	})
	round(boxHolder, 12)
	local boxStroke = create("UIStroke", {Color = Color3.fromRGB(255, 255, 255), Transparency = 0.88, Parent = boxHolder})
	local box = create("TextBox", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(14, 0),
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
		Size = UDim2.new(1, 0, 0, 44),
		Font = FONT_BOLD,
		TextSize = 15,
		Text = "Unlock",
		TextColor3 = Color3.fromRGB(12, 12, 12),
		AutoButtonColor = false,
		LayoutOrder = 6,
		Parent = card,
	})
	round(submit, 12)
	submit.MouseEnter:Connect(function()
		tween(submit, TI_FAST, {BackgroundColor3 = Color3.fromRGB(220, 220, 220)})
	end)
	submit.MouseLeave:Connect(function()
		tween(submit, TI_FAST, {BackgroundColor3 = Theme.TextTitle})
	end)

	card.Position = UDim2.fromScale(0.5, 0.56)
	tween(card, TI_MORPH, {Position = UDim2.fromScale(0.5, 0.5)})

	local passed = false

	local function shake()
		tween(boxStroke, TweenInfo.new(0.1), {Color = Color3.fromRGB(224, 90, 90), Transparency = 0.2})
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
				safeWriteFile(keyPath, box.Text)
			end
			tween(card, TI_MED, {Position = UDim2.fromScale(0.5, 0.54)})
			tween(overlay, TI_MED, {BackgroundTransparency = 1})
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

-- window

function RayfieldLibrary:CreateWindow(Settings)
	Settings = Settings or {}
	ensureRoot()

	if Settings.KeySystem then
		local ok = runKeySystem(Settings)
		if not ok then
			warn("Rayfield Gen2 | Key system was not passed")
			return nil
		end
	end

	-- configuration saving setup
	local configEnabled = false
	local configFolder = BASE_FOLDER
	local configFile = "Config"
	if type(Settings.ConfigurationSaving) == "table" and Settings.ConfigurationSaving.Enabled then
		configEnabled = fsAvailable
		configFolder = Settings.ConfigurationSaving.FolderName or configFolder
		configFile = Settings.ConfigurationSaving.FileName or configFile
	end
	if configEnabled then ensureFolder(configFolder) end

	local savePending = false
	local function saveConfiguration()
		if not configEnabled or destroyed then return end
		if savePending then return end
		savePending = true
		task.delay(0.6, function()
			savePending = false
			if destroyed then return end
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
					out[flag] = {R = math.floor(c.R * 255 + 0.5), G = math.floor(c.G * 255 + 0.5), B = math.floor(c.B * 255 + 0.5)}
				end
			end
			safeWriteFile(configFolder .. "/" .. configFile .. ".json", HttpService:JSONEncode(out))
		end)
	end

	-- sign in toast when the account changed since last run
	task.spawn(function()
		if not fsAvailable or not LocalPlayer then return end
		local path = BASE_FOLDER .. "/lastuser.txt"
		local last = safeReadFile(path)
		local current = tostring(LocalPlayer.UserId)
		safeWriteFile(path, current)
		if last ~= nil and last ~= current then
			task.wait(0.5)
			showAccountToast()
		end
	end)

	local WINDOW_W, WINDOW_H = 530, 550
	local HEADER_H = 76
	local PILL_H = 62

	-- pill width from the window name so long names fit
	local pillNameText = Settings.Name or "Rayfield"
	local pillTextW = math.max(
		measureText(pillNameText, 16, FONT_BOLD).X,
		measureText("Tap to show", 13, FONT_MEDIUM).X
	)
	local PILL_W = math.clamp(12 + 44 + 12 + math.ceil(pillTextW) + 26, 180, 340)

	local shownPosition = UDim2.new(0.5, 0, 0.5, -math.floor((WINDOW_H + 18) / 2))

	local root = create("Frame", {
		Name = "WindowRoot",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = shownPosition,
		Size = UDim2.fromOffset(WINDOW_W, WINDOW_H + 18),
		Parent = rootGui,
	})

	-- soft drop shadow that follows the window through every morph
	local shadow = create("ImageLabel", {
		Name = "Shadow",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, -18),
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
	local windowCorner = round(window, 18)
	create("UIStroke", {Color = Color3.fromRGB(255, 255, 255), Transparency = 0.93, Parent = window})
	create("UIGradient", {
		Rotation = 90,
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
		Parent = window,
	})

	-- drag handle line under the window
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
		local size = window.Size
		handle.Position = UDim2.new(0.5, 0, 0, size.Y.Offset + 12)
		shadow.Size = UDim2.fromOffset(size.X.Offset + 36, size.Y.Offset + 36)
	end)

	-- pill contents for the hidden state
	local pillContent = create("CanvasGroup", {
		Name = "PillContent",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(PILL_W, PILL_H),
		GroupTransparency = 1,
		Visible = false,
		ZIndex = 10,
		Parent = window,
	})
	do
		local well = create("Frame", {
			BackgroundColor3 = Theme.Card,
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 9, 0.5, 0),
			Size = UDim2.fromOffset(44, 44),
			Parent = pillContent,
		})
		roundFull(well)
		create("UIGradient", {
			Rotation = 90,
			Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(190, 190, 190)),
			Parent = well,
		})
		local placedIcon = nil
		if Settings.Icon and Settings.Icon ~= 0 and Settings.Icon ~= "" then
			placedIcon = makeIcon(well, Settings.Icon, 24, Theme.TextTitle)
		end
		if placedIcon then
			placedIcon.AnchorPoint = Vector2.new(0.5, 0.5)
			placedIcon.Position = UDim2.fromScale(0.5, 0.5)
		else
			create("TextLabel", {
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromOffset(30, 30),
				Font = FONT_BOLD,
				TextSize = 20,
				Text = string.upper(string.sub(pillNameText, 1, 1)),
				TextColor3 = Theme.TextTitle,
				Parent = well,
			})
		end

		local col = create("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 65, 0.5, -17),
			Size = UDim2.new(1, -91, 0, 34),
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
			TextColor3 = Theme.TextTitle,
			Parent = col,
		})
		create("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(0, 19),
			Size = UDim2.new(1, 0, 0, 14),
			Font = FONT_MEDIUM,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
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
		Parent = window,
	})

	-- header

	local header = create("Frame", {
		Name = "Header",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, HEADER_H),
		Parent = main,
	})

	local titleRow = create("Frame", {
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.X,
		Position = UDim2.fromOffset(24, 13),
		Size = UDim2.new(0, 0, 0, 27),
		Parent = header,
	})
	create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
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
		Text = Settings.Name or "Rayfield",
		LayoutOrder = 1,
		Parent = titleRow,
	})
	paint(titleLabel, "TextColor3", "TextTitle")

	if Settings.Badge then
		local badgeText = type(Settings.Badge) == "table" and (Settings.Badge.Text or "") or tostring(Settings.Badge)
		local badgeIcon = type(Settings.Badge) == "table" and Settings.Badge.Icon or nil
		local badge = create("Frame", {
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.new(0, 0, 0, 26),
			LayoutOrder = 2,
			Parent = titleRow,
		})
		paint(badge, "BackgroundColor3", "BadgeBackground")
		roundFull(badge)
		padAll(badge, 0, 12, 0, 11)
		create("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 6),
			Parent = badge,
		})
		if badgeIcon then
			local ic = makeIcon(badge, badgeIcon, 14, Theme.BadgeText)
			if ic then ic.LayoutOrder = 1 end
		end
		local bt = create("TextLabel", {
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.new(0, 0, 1, 0),
			Font = FONT_BOLD,
			TextSize = 13,
			Text = badgeText,
			LayoutOrder = 2,
			Parent = badge,
		})
		paint(bt, "TextColor3", "BadgeText")
	end

	local subtitleLabel = create("TextLabel", {
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.X,
		Position = UDim2.fromOffset(24, 42),
		Size = UDim2.new(0, 0, 0, 15),
		Font = FONT_MEDIUM,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = Settings.Subtitle or "Rayfield Gen2",
		Parent = header,
	})
	paint(subtitleLabel, "TextColor3", "TextSub")

	-- header buttons
	local buttonRow = create("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -16, 0, 15),
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.new(0, 0, 0, 30),
		Parent = header,
	})
	create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 6),
		Parent = buttonRow,
	})

	local function headerButton(order, lucideNames)
		local btn = create("TextButton", {
			BackgroundTransparency = 1,
			Text = "",
			Size = UDim2.fromOffset(30, 30),
			LayoutOrder = order,
			Parent = buttonRow,
		})
		local icon = create("ImageLabel", {
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(19, 19),
			ImageColor3 = Theme.TextSub,
			Parent = btn,
		})
		applyLucide(icon, lucideNames)
		btn.MouseEnter:Connect(function()
			tween(icon, TI_FAST, {ImageColor3 = Theme.TextTitle})
		end)
		btn.MouseLeave:Connect(function()
			tween(icon, TI_FAST, {ImageColor3 = Theme.TextSub})
		end)
		return btn, icon
	end

	local searchButton, searchButtonIcon = headerButton(1, {"text-search", "search"})
	local settingsButton, settingsButtonIcon = headerButton(2, {"settings"})
	local minimizeButton, minimizeIcon = headerButton(3, {"minus"})
	local closeButton = headerButton(4, {"x"})

	-- body

	local body = create("Frame", {
		Name = "Body",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(14, HEADER_H),
		Size = UDim2.new(1, -28, 1, -HEADER_H - 14),
		Parent = main,
	})

	local TABBAR_H = 48
	local tabBar = create("ScrollingFrame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, TABBAR_H),
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.X,
		ScrollingDirection = Enum.ScrollingDirection.X,
		ScrollBarThickness = 0,
		BorderSizePixel = 0,
		Parent = body,
	})
	create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 8),
		Parent = tabBar,
	})

	-- search row between the tab bar and the pages
	local searchHolder = create("Frame", {
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Position = UDim2.fromOffset(0, TABBAR_H + 8),
		Size = UDim2.new(1, 0, 0, 0),
		Parent = body,
	})
	local searchCard = create("Frame", {
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundTransparency = 0.35,
	})
	paint(searchCard, "BackgroundColor3", "SearchBox")
	round(searchCard, 12)
	searchCard.Parent = searchHolder
	local searchIconHolder = create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(40, 40),
		Parent = searchCard,
	})
	do
		local sIcon = makeIcon(searchIconHolder, "text-search", 18, Theme.TextSub)
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
		Size = UDim2.new(1, 0, 1, -(TABBAR_H + 10)),
		Parent = body,
	})

	-- window state

	local Window = {}
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

	-- keeps the mouse usable in games that lock it to the camera
	connect(RunService.RenderStepped, function()
		if unlockCursor and not hidden and not destroyed then
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
					-- rows and columns match when any element inside matches
					local matched = false
					for _, d in ipairs(item:GetDescendants()) do
						local sn = d:GetAttribute("SearchName")
						if sn and string.find(string.lower(sn), query, 1, true) then
							matched = true
							break
						end
					end
					item.Visible = matched
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

	-- pages, each wrapped in a CanvasGroup so tab switches can fade

	local function buildPage()
		local pageWrapper = create("CanvasGroup", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			GroupTransparency = 0,
			Visible = false,
			Parent = pagesHolder,
		})
		local page = create("ScrollingFrame", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			CanvasSize = UDim2.new(0, 0, 0, 0),
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
		padAll(page, 2, 5, 16, 1)
		return page, pageWrapper
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
		tween(wrapper, TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {GroupTransparency = 0})
		tween(wrapper, TweenInfo.new(0.32, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2.fromOffset(0, 0)})
	end

	local function styleTabPills()
		for _, other in ipairs(tabs) do
			local active = (not settingsOpen) and other == currentTab
			tween(other.Pill, TI_FAST, {BackgroundColor3 = active and Color3.fromRGB(46, 46, 46) or Theme.CardInset, BackgroundTransparency = active and 0 or 0.35})
			tween(other.PillLabel, TI_FAST, {TextColor3 = active and Theme.TextTitle or Theme.TextSub})
			if other.PillIcon then
				tween(other.PillIcon, TI_FAST, {ImageColor3 = active and Theme.TextTitle or Theme.TextSub})
			end
			tween(other.PillStroke, TI_FAST, {Transparency = active and 0.5 or 0.58})
		end
		tween(settingsButtonIcon, TI_FAST, {ImageColor3 = settingsOpen and Theme.TextTitle or Theme.TextSub, Rotation = settingsOpen and 90 or 0})
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

	-- element construction

	local elementOrder = 0
	local function nextOrder()
		elementOrder = elementOrder + 1
		return elementOrder
	end

	local function runCallback(callback, ...)
		if type(callback) ~= "function" then return end
		local ok, err = pcall(callback, ...)
		if not ok then
			warn("Rayfield Gen2 | Callback error: " .. tostring(err))
			RayfieldLibrary:Notify({Title = "Callback Error", Content = tostring(err), Duration = 4, Image = "triangle-alert"})
		end
	end

	local function cardBase(card)
		round(card, 14)
		create("UIGradient", {
			Rotation = 90,
			Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(226, 226, 226)),
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
				ic.Position = UDim2.new(0, 16, 0.5, 0)
				textX = 44
			end
		end
		local label = create("TextLabel", {
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, textX, 0.5, 0),
			Size = UDim2.new(1, -textX - 16, 0, 18),
			Font = FONT_MEDIUM,
			TextSize = 16,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Text = name or "",
			Parent = card,
		})
		paint(label, "TextColor3", "TextBody")
		return card, label, textX
	end

	local function makeDescription(page, card, text)
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
		padAll(desc, 0, 0, 5, 16)
		paint(desc, "TextColor3", "TextMuted")
		return desc
	end

	local function hoverable(card, base, hover)
		card.MouseEnter:Connect(function()
			tween(card, TI_FAST, {BackgroundColor3 = hover or Theme.CardHover})
		end)
		card.MouseLeave:Connect(function()
			tween(card, TI_FAST, {BackgroundColor3 = base or Theme.Card})
		end)
	end

	-- Tab API
	-- compact mode is used inside rows and columns: descriptions are
	-- skipped, buttons center their content, sliders stack vertically and
	-- stat cards use the small pill layout

	local function buildTabAPI(page, compact)
		local Tab = {}
		Tab.Page = page

		local function descFor(card, text)
			if compact then return nil end
			return makeDescription(page, card, text)
		end

		function Tab:CreateSection(sectionName)
			local holder = create("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 30),
				LayoutOrder = nextOrder(),
				Parent = page,
			})
			holder:SetAttribute("Structural", true)
			local label = create("TextLabel", {
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(0, 1),
				Position = UDim2.new(0, 10, 1, -3),
				Size = UDim2.new(1, -20, 0, 16),
				Font = FONT_MEDIUM,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
				Text = sectionName or "",
				Parent = holder,
			})
			paint(label, "TextColor3", "TextSub")
			local SectionValue = {}
			function SectionValue:Set(newName)
				label.Text = newName
			end
			return SectionValue
		end

		function Tab:CreateDivider()
			local holder = create("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 8),
				LayoutOrder = nextOrder(),
				Parent = page,
			})
			holder:SetAttribute("Structural", true)
			create("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.new(1, -12, 0, 1),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
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
			function LabelValue:Set(newText, _newIcon, newColor)
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
			local card = create("Frame", {
				AutomaticSize = Enum.AutomaticSize.Y,
				Size = UDim2.new(1, 0, 0, 0),
				LayoutOrder = nextOrder(),
				Parent = page,
			})
			card:SetAttribute("SearchName", (ParagraphSettings.Title or "") .. " " .. (ParagraphSettings.Content or ""))
			paint(card, "BackgroundColor3", "Card")
			cardBase(card)
			padAll(card, 14, 17, 14, 17)
			create("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
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
				TextSize = 14,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left,
				Text = ParagraphSettings.Content or "",
				LayoutOrder = 2,
				Parent = card,
			})
			paint(content, "TextColor3", "TextSub")
			local ParagraphValue = {}
			function ParagraphValue:Set(newSettings)
				newSettings = newSettings or {}
				title.Text = newSettings.Title or title.Text
				content.Text = newSettings.Content or content.Text
				card:SetAttribute("SearchName", title.Text .. " " .. content.Text)
			end
			return ParagraphValue
		end

		-- Gen2 stat card, the green gradient one. full width shows a big
		-- value line, inside rows and columns it becomes a small pill with
		-- the value on the right
		function Tab:CreateStat(StatSettings)
			StatSettings = StatSettings or {}
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
					Rotation = 112,
					Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Theme.AccentSoft),
						ColorSequenceKeypoint.new(0.55, Theme.Accent),
						ColorSequenceKeypoint.new(1, Theme.AccentDark),
					}),
					Parent = card,
				})
				local textX = 16
				if StatSettings.Icon then
					local ic = makeIcon(card, StatSettings.Icon, 18, Color3.fromRGB(240, 252, 246))
					if ic then
						ic.AnchorPoint = Vector2.new(0, 0.5)
						ic.Position = UDim2.new(0, 15, 0.5, 0)
						textX = 42
					end
				end
				local nameLabel = create("TextLabel", {
					BackgroundTransparency = 1,
					AnchorPoint = Vector2.new(0, 0.5),
					Position = UDim2.new(0, textX, 0.5, 0),
					Size = UDim2.new(0.55, -textX, 0, 18),
					Font = FONT_BOLD,
					TextSize = 16,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextTruncate = Enum.TextTruncate.AtEnd,
					TextColor3 = Color3.fromRGB(244, 253, 248),
					Text = StatSettings.Name or "",
					Parent = card,
				})
				local rightLabel = create("TextLabel", {
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
				function StatValue:Set(newSettings)
					newSettings = newSettings or {}
					if newSettings.Name then nameLabel.Text = newSettings.Name end
					if newSettings.Value ~= nil then lastValue = newSettings.Value end
					if newSettings.Delta ~= nil then lastDelta = newSettings.Delta end
					rightLabel.Text = tostring(lastValue or lastDelta or "")
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
			create("UIGradient", {
				Rotation = 112,
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Theme.AccentSoft),
					ColorSequenceKeypoint.new(0.45, Theme.Accent),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(24, 42, 33)),
				}),
				Parent = card,
			})

			local topX = 17
			if StatSettings.Icon then
				local ic = makeIcon(card, StatSettings.Icon, 21, Color3.fromRGB(238, 252, 245))
				if ic then
					ic.Position = UDim2.fromOffset(16, 14)
					topX = 46
				end
			end
			local nameLabel = create("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(topX, 15),
				Size = UDim2.new(1, -topX - 16, 0, 20),
				Font = FONT_BOLD,
				TextSize = 17,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextColor3 = Color3.fromRGB(242, 252, 247),
				Text = StatSettings.Name or "",
				Parent = card,
			})
			local valueLabel = create("TextLabel", {
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(0, 1),
				Position = UDim2.new(0, 17, 1, -12),
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
				TextColor3 = Color3.fromRGB(202, 242, 221),
				Text = tostring(StatSettings.Delta or ""),
				Parent = card,
			})
			local StatValue = {}
			function StatValue:Set(newSettings)
				newSettings = newSettings or {}
				if newSettings.Name then nameLabel.Text = newSettings.Name end
				if newSettings.Value ~= nil then valueLabel.Text = tostring(newSettings.Value) end
				if newSettings.Delta ~= nil then deltaLabel.Text = tostring(newSettings.Delta) end
			end
			return StatValue
		end

		function Tab:CreateButton(ButtonSettings)
			ButtonSettings = ButtonSettings or {}
			local card, label
			if compact then
				-- centered icon and label for row and column cells
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
					Size = UDim2.new(0, 0, 1, 0),
					Parent = card,
				})
				create("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					VerticalAlignment = Enum.VerticalAlignment.Center,
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 9),
					Parent = center,
				})
				if ButtonSettings.Icon then
					local ic = makeIcon(center, ButtonSettings.Icon, 18, Theme.TextTitle, 0.04)
					if ic then ic.LayoutOrder = 1 end
				end
				label = create("TextLabel", {
					BackgroundTransparency = 1,
					AutomaticSize = Enum.AutomaticSize.X,
					Size = UDim2.new(0, 0, 1, 0),
					Font = FONT_MEDIUM,
					TextSize = 16,
					Text = ButtonSettings.Name or "",
					LayoutOrder = 2,
					Parent = center,
				})
				paint(label, "TextColor3", "TextBody")
			else
				card, label = makeCard(page, ButtonSettings.Name, ButtonSettings.Icon, 50)
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
				tween(card, TweenInfo.new(0.07, Enum.EasingStyle.Quad), {BackgroundColor3 = Theme.CardSelected})
				task.delay(0.09, function()
					tween(card, TI_MED, {BackgroundColor3 = Theme.Card})
				end)
				runCallback(ButtonSettings.Callback)
			end)
			local ButtonValue = {}
			function ButtonValue:Set(newName)
				label.Text = newName
				card:SetAttribute("SearchName", newName or "")
			end
			return ButtonValue
		end

		function Tab:CreateToggle(ToggleSettings)
			ToggleSettings = ToggleSettings or {}
			local card = makeCard(page, ToggleSettings.Name, ToggleSettings.Icon, 50)
			descFor(card, ToggleSettings.Description)
			hoverable(card)

			-- wide flat track with a neutral ring. the track and ring never
			-- change, only the knob turns green when on
			local track = create("Frame", {
				AnchorPoint = Vector2.new(1, 0.5),
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
				Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(196, 196, 196)),
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
					Position = on and UDim2.new(1, -31, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
					BackgroundColor3 = on and Theme.Accent or Theme.KnobOff,
				})
			end
			render(false)

			local clicker = create("TextButton", {
				BackgroundTransparency = 1,
				Text = "",
				Size = UDim2.fromScale(1, 1),
				Parent = card,
			})
			clicker.MouseButton1Click:Connect(function()
				Toggle.CurrentValue = not Toggle.CurrentValue
				render(true)
				runCallback(ToggleSettings.Callback, Toggle.CurrentValue)
				saveConfiguration()
			end)

			function Toggle:Set(value)
				Toggle.CurrentValue = value == true
				render(true)
				runCallback(ToggleSettings.Callback, Toggle.CurrentValue)
				saveConfiguration()
			end

			if ToggleSettings.Flag then
				Toggle.Flag = ToggleSettings.Flag
				RayfieldLibrary.Flags[ToggleSettings.Flag] = Toggle
			end
			return Toggle
		end

		function Tab:CreateSlider(SliderSettings)
			SliderSettings = SliderSettings or {}
			local range = SliderSettings.Range or {0, 100}
			local increment = SliderSettings.Increment or 1
			local suffix = SliderSettings.Suffix or ""

			-- full width cards put the track beside the labels, compact
			-- cells stack the track under them like the two column mockup
			local card = create("Frame", {
				Size = UDim2.new(1, 0, 0, compact and 78 or 60),
				LayoutOrder = nextOrder(),
				Parent = page,
			})
			card:SetAttribute("SearchName", SliderSettings.Name or "")
			paint(card, "BackgroundColor3", "Card")
			cardBase(card)
			descFor(card, SliderSettings.Description)

			local textX = 17
			if SliderSettings.Icon then
				local ic = makeIcon(card, SliderSettings.Icon, 18, Theme.TextTitle, 0.04)
				if ic then
					ic.Position = UDim2.fromOffset(16, 13)
					textX = 44
				end
			end
			local nameLabel = create("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(textX, compact and 13 or 11),
				Size = UDim2.new(compact and 0.56 or 0.48, -textX, 0, 18),
				Font = FONT_MEDIUM,
				TextSize = 16,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Text = SliderSettings.Name or "",
				Parent = card,
			})
			paint(nameLabel, "TextColor3", "TextBody")
			local valueLabel = create("TextLabel", {
				BackgroundTransparency = 1,
				AnchorPoint = compact and Vector2.new(1, 0) or Vector2.new(0, 0),
				Position = compact and UDim2.new(1, -16, 0, 15) or UDim2.fromOffset(textX, 32),
				Size = UDim2.new(compact and 0.4 or 0.48, compact and -16 or -textX, 0, 16),
				Font = FONT_REGULAR,
				TextSize = 13,
				TextXAlignment = compact and Enum.TextXAlignment.Right or Enum.TextXAlignment.Left,
				Text = "",
				Parent = card,
			})
			paint(valueLabel, "TextColor3", "TextSub")

			-- slim dark track, the knob stands taller than it
			local track
			if compact then
				track = create("Frame", {
					Position = UDim2.fromOffset(15, 46),
					Size = UDim2.new(1, -30, 0, 16),
					BackgroundColor3 = Color3.fromRGB(47, 47, 47),
				})
			else
				track = create("Frame", {
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -17, 0.5, 0),
					Size = UDim2.new(0.46, 0, 0, 16),
					BackgroundColor3 = Color3.fromRGB(47, 47, 47),
				})
			end
			roundFull(track)
			track.Parent = card

			local fill = create("Frame", {
				Size = UDim2.new(0.5, 0, 1, 0),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				Parent = track,
			})
			roundFull(fill)
			-- dark green fading into vivid green right at the knob, flat
			-- with no bloom, crisp glowless white knob like the mock
			create("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(42, 88, 66)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(74, 178, 124)),
				}),
				Parent = fill,
			})

			local knob = create("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0.5, 0),
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

			-- the knob is centered on the end of the fill, so the bright
			-- tip of the gradient tucks underneath it like the mockup.
			-- the travel is inset so the knob never leaves the track
			local function render(animate)
				local alpha = 0
				if range[2] ~= range[1] then
					alpha = (Slider.CurrentValue - range[1]) / (range[2] - range[1])
				end
				alpha = math.clamp(alpha, 0, 1)
				local inset = 0.11
				local shown = inset + alpha * (1 - 2 * inset)
				local info = animate and TI_SMOOTH or TweenInfo.new(0)
				tween(fill, info, {Size = UDim2.new(shown, 0, 1, 0)})
				tween(knob, info, {Position = UDim2.new(shown, 0, 0.5, 0)})
				valueLabel.Text = fmt(Slider.CurrentValue)
			end

			local function setFromAlpha(alpha)
				local raw = range[1] + alpha * (range[2] - range[1])
				local snapped = range[1] + math.floor((raw - range[1]) / increment + 0.5) * increment
				snapped = math.clamp(snapped, range[1], range[2])
				if math.abs(snapped - Slider.CurrentValue) > 1e-9 then
					Slider.CurrentValue = snapped
					render(true)
					runCallback(SliderSettings.Callback, snapped)
					saveConfiguration()
				end
			end

			local dragging = false
			track.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					dragging = true
					local alpha = (input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X
					setFromAlpha(math.clamp(alpha, 0, 1))
				end
			end)
			track.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					dragging = false
				end
			end)
			connect(UserInputService.InputChanged, function(input)
				if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
					local alpha = (input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X
					setFromAlpha(math.clamp(alpha, 0, 1))
				end
			end)
			connect(UserInputService.InputEnded, function(input)
				if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
					dragging = false
				end
			end)

			render(false)

			function Slider:Set(value)
				Slider.CurrentValue = math.clamp(value, range[1], range[2])
				render(true)
				runCallback(SliderSettings.Callback, Slider.CurrentValue)
				saveConfiguration()
			end

			if SliderSettings.Flag then
				Slider.Flag = SliderSettings.Flag
				RayfieldLibrary.Flags[SliderSettings.Flag] = Slider
			end
			return Slider
		end

		function Tab:CreateInput(InputSettings)
			InputSettings = InputSettings or {}
			local card = makeCard(page, InputSettings.Name, InputSettings.Icon, 50)
			descFor(card, InputSettings.Description)
			hoverable(card)

			local boxHolder = create("Frame", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -13, 0.5, 0),
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
				tween(boxStroke, TI_FAST, {Transparency = 0.5})
			end)
			box.FocusLost:Connect(function()
				tween(boxStroke, TI_FAST, {Transparency = 0.88})
				Input.CurrentValue = box.Text
				runCallback(InputSettings.Callback, box.Text)
				if InputSettings.RemoveTextAfterFocusLost then
					box.Text = ""
				end
				saveConfiguration()
			end)

			function Input:Set(text)
				box.Text = text or ""
				Input.CurrentValue = box.Text
				runCallback(InputSettings.Callback, box.Text)
				saveConfiguration()
			end

			if InputSettings.Flag then
				Input.Flag = InputSettings.Flag
				RayfieldLibrary.Flags[InputSettings.Flag] = Input
			end
			return Input
		end

		function Tab:CreateDropdown(DropdownSettings)
			DropdownSettings = DropdownSettings or {}
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
				Size = UDim2.new(1, 0, 0, 50),
				LayoutOrder = nextOrder(),
				Parent = page,
			})
			wrapper:SetAttribute("SearchName", DropdownSettings.Name or "")

			local card = create("Frame", {
				Size = UDim2.new(1, 0, 0, 50),
				Parent = wrapper,
			})
			paint(card, "BackgroundColor3", "Card")
			cardBase(card)
			hoverable(card)

			local textX = 17
			if DropdownSettings.Icon then
				local ic = makeIcon(card, DropdownSettings.Icon, 18, Theme.TextTitle, 0.04)
				if ic then
					ic.AnchorPoint = Vector2.new(0, 0.5)
					ic.Position = UDim2.new(0, 16, 0.5, 0)
					textX = 44
				end
			end
			local label = create("TextLabel", {
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, textX, 0.5, 0),
				Size = UDim2.new(0.5, -textX, 0, 18),
				Font = FONT_MEDIUM,
				TextSize = 16,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Text = DropdownSettings.Name or "",
				Parent = card,
			})
			paint(label, "TextColor3", "TextBody")

			local chevron = create("ImageLabel", {
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -15, 0.5, 0),
				Size = UDim2.fromOffset(16, 16),
				ImageColor3 = Theme.TextSub,
				Parent = card,
			})
			applyLucide(chevron, {"chevron-down"})

			local currentLabel = create("TextLabel", {
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -39, 0.5, 0),
				Size = UDim2.new(0.4, -39, 0, 16),
				Font = FONT_MEDIUM,
				TextSize = 14,
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
				Size = UDim2.new(1, 0, 0, 0),
				CanvasSize = UDim2.new(0, 0, 0, 0),
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
			paint(searchRow, "BackgroundColor3", "SearchBox")
			round(searchRow, 12)
			do
				local sIcon = makeIcon(searchRow, "text-search", 16, Theme.TextSub)
				if sIcon then
					sIcon.AnchorPoint = Vector2.new(0, 0.5)
					sIcon.Position = UDim2.new(0, 13, 0.5, 0)
				end
			end
			local optionSearch = create("TextBox", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(38, 0),
				Size = UDim2.new(1, -46, 1, 0),
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
				tween(chevron, TI_MED, {Rotation = open and 180 or 0})
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
				renderRows()
				refreshCurrentLabel()
				runCallback(DropdownSettings.Callback, Dropdown.CurrentOption)
				saveConfiguration()
				if not multiple then
					task.delay(0.12, function() setOpen(false) end)
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
					applyLucide(check, {"square-check", "check-square", "check"})
					local optionLabel = create("TextLabel", {
						BackgroundTransparency = 1,
						AnchorPoint = Vector2.new(0, 0.5),
						Position = UDim2.new(0, 17, 0.5, 0),
						Size = UDim2.new(1, -62, 0, 16),
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
							tween(row, TI_FAST, {BackgroundColor3 = Theme.CardHover})
						end
					end)
					rowButton.MouseLeave:Connect(function()
						tween(row, TI_FAST, {BackgroundColor3 = isSelected(option) and Theme.CardSelected or Theme.CardInset})
					end)
					rowButton.MouseButton1Click:Connect(function()
						choose(option)
					end)
					table.insert(optionRows, entry)
				end
				renderRows()
			end

			connect(optionSearch:GetPropertyChangedSignal("Text"), function()
				local q = string.lower(optionSearch.Text)
				for _, row in ipairs(optionRows) do
					row.frame.Visible = q == "" or string.find(string.lower(tostring(row.option)), q, 1, true) ~= nil
				end
				if open then
					tween(listHolder, TI_FAST, {Size = UDim2.new(1, 0, 0, visibleListHeight())})
				end
			end)

			local clicker = create("TextButton", {
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

			function Dropdown:Set(newOption)
				if type(newOption) == "string" then newOption = {newOption} end
				if type(newOption) ~= "table" then newOption = {} end
				if not multiple and #newOption > 1 then newOption = {newOption[1]} end
				Dropdown.CurrentOption = newOption
				renderRows()
				refreshCurrentLabel()
				runCallback(DropdownSettings.Callback, Dropdown.CurrentOption)
				saveConfiguration()
			end

			function Dropdown:Refresh(newOptions)
				options = newOptions or {}
				local kept = {}
				for _, v in ipairs(Dropdown.CurrentOption) do
					for _, o in ipairs(options) do
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
					tween(listHolder, TI_FAST, {Size = UDim2.new(1, 0, 0, visibleListHeight())})
				end
			end

			if DropdownSettings.Flag then
				Dropdown.Flag = DropdownSettings.Flag
				RayfieldLibrary.Flags[DropdownSettings.Flag] = Dropdown
			end
			return Dropdown
		end

		function Tab:CreateKeybind(KeybindSettings)
			KeybindSettings = KeybindSettings or {}
			local card = makeCard(page, KeybindSettings.Name, KeybindSettings.Icon, 50)
			descFor(card, KeybindSettings.Description)
			hoverable(card)

			local keyHolder = create("Frame", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -13, 0.5, 0),
				AutomaticSize = Enum.AutomaticSize.X,
				Size = UDim2.fromOffset(34, 30),
			})
			paint(keyHolder, "BackgroundColor3", "CardHover")
			round(keyHolder, 10)
			local keyStroke = create("UIStroke", {Color = Color3.fromRGB(255, 255, 255), Transparency = 0.88, Parent = keyHolder})
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
			paint(keyLabel, "TextColor3", "TextBody")
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

			connect(UserInputService.InputBegan, function(input, processed)
				if listening then
					if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode ~= Enum.KeyCode.Unknown then
						listening = false
						tween(keyStroke, TI_FAST, {Transparency = 0.88})
						if input.KeyCode == Enum.KeyCode.Escape then
							keyLabel.Text = Keybind.CurrentKeybind
							return
						end
						Keybind.CurrentKeybind = input.KeyCode.Name
						keyLabel.Text = input.KeyCode.Name
						if KeybindSettings.CallOnChange then
							runCallback(KeybindSettings.Callback, input.KeyCode.Name)
						end
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

			function Keybind:Set(newKeybind)
				Keybind.CurrentKeybind = newKeybind
				keyLabel.Text = newKeybind or "Key"
				if KeybindSettings.CallOnChange then
					runCallback(KeybindSettings.Callback, newKeybind)
				end
				saveConfiguration()
			end

			if KeybindSettings.Flag then
				Keybind.Flag = KeybindSettings.Flag
				RayfieldLibrary.Flags[KeybindSettings.Flag] = Keybind
			end
			return Keybind
		end

		function Tab:CreateColorPicker(ColorPickerSettings)
			ColorPickerSettings = ColorPickerSettings or {}
			local color = ColorPickerSettings.Color or Color3.fromRGB(255, 255, 255)

			local wrapper = create("Frame", {
				BackgroundTransparency = 1,
				AutomaticSize = Enum.AutomaticSize.Y,
				Size = UDim2.new(1, 0, 0, 50),
				LayoutOrder = nextOrder(),
				Parent = page,
			})
			wrapper:SetAttribute("SearchName", ColorPickerSettings.Name or "")

			local card = create("Frame", {
				Size = UDim2.new(1, 0, 0, 50),
				Parent = wrapper,
			})
			paint(card, "BackgroundColor3", "Card")
			cardBase(card)
			hoverable(card)

			local textX = 17
			if ColorPickerSettings.Icon then
				local ic = makeIcon(card, ColorPickerSettings.Icon, 18, Theme.TextTitle, 0.04)
				if ic then
					ic.AnchorPoint = Vector2.new(0, 0.5)
					ic.Position = UDim2.new(0, 16, 0.5, 0)
					textX = 44
				end
			end
			local label = create("TextLabel", {
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, textX, 0.5, 0),
				Size = UDim2.new(0.6, -textX, 0, 18),
				Font = FONT_MEDIUM,
				TextSize = 16,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Text = ColorPickerSettings.Name or "",
				Parent = card,
			})
			paint(label, "TextColor3", "TextBody")

			local swatch = create("Frame", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -15, 0.5, 0),
				Size = UDim2.fromOffset(42, 26),
				BackgroundColor3 = color,
				Parent = card,
			})
			round(swatch, 9)
			create("UIStroke", {Color = Color3.fromRGB(255, 255, 255), Transparency = 0.8, Parent = swatch})

			local panel = create("Frame", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(0, 56),
				Size = UDim2.new(1, 0, 0, 0),
				ClipsDescendants = true,
				Parent = wrapper,
			})

			local ColorPicker = {
				Type = "ColorPicker",
				Color = color,
			}

			local channels = {}
			local channelDefs = {
				{name = "R", get = function(c) return c.R end},
				{name = "G", get = function(c) return c.G end},
				{name = "B", get = function(c) return c.B end},
			}

			local function currentColor()
				return Color3.fromRGB(channels[1].value, channels[2].value, channels[3].value)
			end

			local function pushColor(fire)
				ColorPicker.Color = currentColor()
				swatch.BackgroundColor3 = ColorPicker.Color
				if fire then
					runCallback(ColorPickerSettings.Callback, ColorPicker.Color)
					saveConfiguration()
				end
			end

			for i, def in ipairs(channelDefs) do
				local rowY = (i - 1) * 34 + 4
				local row = create("Frame", {
					BackgroundTransparency = 1,
					Position = UDim2.fromOffset(4, rowY),
					Size = UDim2.new(1, -8, 0, 28),
					Parent = panel,
				})
				local tag = create("TextLabel", {
					BackgroundTransparency = 1,
					Size = UDim2.fromOffset(20, 28),
					Font = FONT_MEDIUM,
					TextSize = 14,
					Text = def.name,
					Parent = row,
				})
				paint(tag, "TextColor3", "TextSub")
				local track = create("Frame", {
					AnchorPoint = Vector2.new(0, 0.5),
					Position = UDim2.new(0, 30, 0.5, 0),
					Size = UDim2.new(1, -86, 0, 14),
					BackgroundColor3 = Color3.fromRGB(45, 45, 45),
					BackgroundTransparency = 0.25,
					Parent = row,
				})
				roundFull(track)
				local fill = create("Frame", {
					Size = UDim2.new(0.5, 0, 1, 0),
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					Parent = track,
				})
				roundFull(fill)
				create("UIGradient", {
					Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Theme.AccentDark),
						ColorSequenceKeypoint.new(1, Theme.AccentSoft),
					}),
					Parent = fill,
				})
				local valueLabel = create("TextLabel", {
					BackgroundTransparency = 1,
					AnchorPoint = Vector2.new(1, 0),
					Position = UDim2.new(1, 0, 0, 0),
					Size = UDim2.fromOffset(40, 28),
					Font = FONT_MEDIUM,
					TextSize = 13,
					TextXAlignment = Enum.TextXAlignment.Right,
					Text = "255",
					Parent = row,
				})
				paint(valueLabel, "TextColor3", "TextSub")

				local channel = {value = math.floor(def.get(color) * 255 + 0.5)}
				channels[i] = channel

				local function render()
					fill.Size = UDim2.new(math.max(channel.value / 255, 0.02), 0, 1, 0)
					valueLabel.Text = tostring(channel.value)
				end
				channel.render = render
				render()

				local dragging = false
				local function setFromX(x)
					local alpha = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
					channel.value = math.floor(alpha * 255 + 0.5)
					render()
					pushColor(true)
				end
				track.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						dragging = true
						setFromX(input.Position.X)
					end
				end)
				connect(UserInputService.InputChanged, function(input)
					if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
						setFromX(input.Position.X)
					end
				end)
				connect(UserInputService.InputEnded, function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						dragging = false
					end
				end)
			end

			local open = false
			local clicker = create("TextButton", {
				BackgroundTransparency = 1,
				Text = "",
				Size = UDim2.fromScale(1, 1),
				Parent = card,
			})
			clicker.MouseButton1Click:Connect(function()
				open = not open
				tween(panel, TI_MED, {Size = UDim2.new(1, 0, 0, open and (3 * 34 + 8) or 0)})
			end)

			function ColorPicker:Set(newColor)
				channels[1].value = math.floor(newColor.R * 255 + 0.5)
				channels[2].value = math.floor(newColor.G * 255 + 0.5)
				channels[3].value = math.floor(newColor.B * 255 + 0.5)
				for _, channel in ipairs(channels) do
					channel.render()
				end
				pushColor(true)
			end

			if ColorPickerSettings.Flag then
				ColorPicker.Flag = ColorPickerSettings.Flag
				RayfieldLibrary.Flags[ColorPickerSettings.Flag] = ColorPicker
			end
			return ColorPicker
		end

		-- a horizontal strip of elements sharing the width equally.
		-- returns a Tab style API in compact mode, so
		-- local Row = Tab:CreateRow() then Row:CreateToggle({...})
		function Tab:CreateRow()
			local rowFrame = create("Frame", {
				BackgroundTransparency = 1,
				AutomaticSize = Enum.AutomaticSize.Y,
				Size = UDim2.new(1, 0, 0, 50),
				LayoutOrder = nextOrder(),
				Parent = page,
			})
			rowFrame:SetAttribute("Composite", true)
			create("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				VerticalAlignment = Enum.VerticalAlignment.Top,
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
					c.Size = UDim2.new(1 / n, -adj, 0, c.Size.Y.Offset)
				end
			end
			rowFrame.ChildAdded:Connect(function()
				task.defer(recompute)
			end)
			return buildTabAPI(rowFrame, true)
		end

		-- splits the page into vertical columns, each with the full element
		-- API in compact mode:
		-- local Left, Right = Tab:CreateColumns(2)
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
				Padding = UDim.new(0, 10),
				Parent = container,
			})
			local apis = {}
			local adj = math.floor(10 * (count - 1) / count + 0.5)
			for i = 1, count do
				local column = create("Frame", {
					BackgroundTransparency = 1,
					AutomaticSize = Enum.AutomaticSize.Y,
					Size = UDim2.new(1 / count, -adj, 0, 0),
					LayoutOrder = i,
					Parent = container,
				})
				create("UIListLayout", {
					FillDirection = Enum.FillDirection.Vertical,
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 8),
					Parent = column,
				})
				table.insert(apis, buildTabAPI(column, true))
			end
			return table.unpack(apis)
		end

		return Tab
	end

	-- Window:CreateTab

	function Window:CreateTab(tabName, tabImage, _ext)
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
		-- soft top light on the fill, the ring defines the shape in both states
		create("UIGradient", {
			Rotation = 90,
			Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(200, 200, 200)),
			Parent = pill,
		})
		local pillStroke = create("UIStroke", {Color = Color3.fromRGB(255, 255, 255), Transparency = 0.58, Thickness = 1.6, Parent = pill})
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
		local pillLabel = create("TextLabel", {
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.new(0, 0, 1, 0),
			Font = FONT_MEDIUM,
			TextSize = 16,
			Text = tabName or "Tab",
			TextColor3 = Theme.TextSub,
			LayoutOrder = 2,
			Parent = pill,
		})

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

		pill.MouseEnter:Connect(function()
			if currentTab ~= tabEntry or settingsOpen then
				tween(pill, TI_FAST, {BackgroundTransparency = 0.2})
			end
		end)
		pill.MouseLeave:Connect(function()
			if currentTab ~= tabEntry or settingsOpen then
				tween(pill, TI_FAST, {BackgroundTransparency = 0.35})
			end
		end)
		pill.MouseButton1Click:Connect(function()
			selectTab(tabEntry)
		end)

		if #tabs == 1 then
			currentTab = tabEntry
			settingsOpen = false
			styleTabPills()
			pageWrapper.Visible = true
		end

		return Tab
	end

	-- settings page

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
		SettingsTab:CreateToggle({
			Name = "Unlock cursor while open",
			Icon = "mouse-pointer-2",
			CurrentValue = false,
			Description = "Unlocks the cursor while the menu is open so you can configure in FPS games that lock it.",
			Callback = function(value)
				unlockCursor = value
			end,
		})
		SettingsTab:CreateSection("Configuration")
		SettingsTab:CreateLabel(configEnabled and ("Saving to " .. configFolder .. "/" .. configFile .. ".json") or "Configuration saving is off", "folder")
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

	-- dragging with a smooth tween follow, like original Rayfield

	local function makeDraggable(zone)
		local dragging = false
		local dragStart = nil
		local startPos = nil
		zone.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				if morphing or hidden then return end
				dragging = true
				dragStart = input.Position
				startPos = root.Position
			end
		end)
		zone.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			end
		end)
		connect(UserInputService.InputChanged, function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				local delta = input.Position - dragStart
				tween(root, TweenInfo.new(0.3, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {
					Position = UDim2.new(
						startPos.X.Scale, startPos.X.Offset + delta.X,
						startPos.Y.Scale, startPos.Y.Offset + delta.Y
					),
				})
			end
		end)
	end
	makeDraggable(header)
	makeDraggable(handle)

	-- minimize and hide

	local function setMinimizeIcon(restore)
		applyLucide(minimizeIcon, restore and {"maximize-2", "expand"} or {"minus"})
	end

	local function setMinimized(value)
		if morphing or hidden then return end
		minimized = value
		setMinimizeIcon(minimized)
		tween(window, TI_MORPH, {Size = UDim2.fromOffset(WINDOW_W, minimized and HEADER_H or WINDOW_H)})
	end

	minimizeButton.MouseButton1Click:Connect(function()
		setMinimized(not minimized)
	end)

	-- hide and show, matching the Gen2 morph animation:
	-- content fades, the frame flies to the top center while shrinking into
	-- a pill, then the pill content fades in. showing reverses it.

	local function hideWindow()
		if morphing or hidden then return end
		morphing = true
		hidden = true
		storedPosition = root.Position
		tween(handle, TI_FAST, {BackgroundTransparency = 1})
		tween(main, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {GroupTransparency = 1})
		task.wait(0.17)
		main.Visible = false
		tween(windowCorner, TI_MORPH, {CornerRadius = UDim.new(0, math.floor(PILL_H / 2))})
		tween(window, TI_MORPH, {Size = UDim2.fromOffset(PILL_W, PILL_H)})
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
		tween(windowCorner, TI_MORPH, {CornerRadius = UDim.new(0, 18)})
		tween(window, TI_MORPH, {Size = UDim2.fromOffset(WINDOW_W, minimized and HEADER_H or WINDOW_H)})
		tween(shadow, TI_MORPH, {ImageTransparency = 0.42})
		tween(root, TI_MORPH, {Position = storedPosition or shownPosition})
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
	pillButton.MouseEnter:Connect(function()
		if hidden and not morphing then
			tween(window, TI_FAST, {BackgroundColor3 = Color3.fromRGB(30, 30, 30)})
		end
	end)
	pillButton.MouseLeave:Connect(function()
		tween(window, TI_FAST, {BackgroundColor3 = Theme.Background})
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

	-- Window API

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

	function Window:SetTitle(newTitle)
		titleLabel.Text = newTitle or titleLabel.Text
	end

	function Window:SetSubtitle(newSubtitle)
		subtitleLabel.Text = newSubtitle or subtitleLabel.Text
	end

	-- entrance, with an optional loading card that expands into the window

	local hasLoading = (Settings.LoadingTitle and Settings.LoadingTitle ~= "") or (Settings.LoadingSubtitle and Settings.LoadingSubtitle ~= "")

	if hasLoading then
		-- block hide and minimize until the loading card has expanded,
		-- otherwise the delayed expansion would fight the pill morph
		morphing = true
		local LOAD_W, LOAD_H = 320, 140
		window.Size = UDim2.fromOffset(LOAD_W, LOAD_H)
		root.Position = UDim2.new(0.5, 0, 0.5, -math.floor(LOAD_H / 2) - 9)

		local loading = create("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(LOAD_W, LOAD_H),
			ZIndex = 5,
			Parent = window,
		})
		local spinner = create("ImageLabel", {
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, 26),
			Size = UDim2.fromOffset(24, 24),
			ImageColor3 = Theme.TextTitle,
			ImageTransparency = 0,
			Parent = loading,
		})
		applyLucide(spinner, {"loader"})
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
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, 88),
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
			tween(loading, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1})
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
			tween(root, TI_SLOW, {Position = shownPosition})
			task.wait(0.18)
			tween(main, TweenInfo.new(0.32, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {GroupTransparency = 0})
			tween(handle, TI_SLOW, {BackgroundTransparency = 0.35})
			task.wait(0.34)
			morphing = false
		end)
	else
		window.Size = UDim2.fromOffset(WINDOW_W - 48, WINDOW_H - 56)
		shadow.ImageTransparency = 1
		tween(window, TI_SLOW, {Size = UDim2.fromOffset(WINDOW_W, WINDOW_H)})
		tween(shadow, TI_SLOW, {ImageTransparency = 0.42})
		tween(main, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {GroupTransparency = 0})
		tween(handle, TI_SLOW, {BackgroundTransparency = 0.35})
	end

	-- config load

	function RayfieldLibrary:LoadConfiguration()
		if not configEnabled then return end
		local raw = safeReadFile(configFolder .. "/" .. configFile .. ".json")
		if not raw then return end
		local ok, data = pcall(function() return HttpService:JSONDecode(raw) end)
		if not ok or type(data) ~= "table" then return end
		for flag, value in pairs(data) do
			local element = RayfieldLibrary.Flags[flag]
			if element then
				pcall(function()
					if element.Type == "ColorPicker" and type(value) == "table" then
						element:Set(Color3.fromRGB(value.R or 255, value.G or 255, value.B or 255))
					else
						element:Set(value)
					end
				end)
			end
		end
		RayfieldLibrary:Notify({Title = "Configuration loaded", Content = "Your saved settings were applied.", Duration = 3, Image = "file-check"})
	end

	return Window
end

-- visibility and teardown

function RayfieldLibrary:IsVisible()
	if RayfieldLibrary._isHidden then
		return not RayfieldLibrary._isHidden()
	end
	return rootGui ~= nil
end

function RayfieldLibrary:SetVisibility(visible)
	if visible and RayfieldLibrary._showWindow then
		task.spawn(RayfieldLibrary._showWindow)
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
