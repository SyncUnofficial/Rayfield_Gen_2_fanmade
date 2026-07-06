--[[
	Rayfield Gen 2 [fanmade]

	Unofficial rebuild of the Rayfield Interface Suite with a new look.
	Keeps the original Rayfield API so most existing scripts drop in:
	CreateWindow, CreateTab, CreateSection, CreateButton, CreateToggle,
	CreateSlider, CreateInput, CreateDropdown, CreateKeybind, CreateLabel,
	CreateParagraph, CreateColorPicker, Notify, Flags, config saving.

	Gen 2 additions: header badge, search that filters elements, stat cards,
	hide-to-pill animation, minimize to bar, sign in toast.

	Original Rayfield by Sirius (sirius.menu). This project is not
	affiliated with or endorsed by them.
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

-- executor environment shims
local useStudio = game:GetService("RunService"):IsStudio()

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

-- theme -----------------------------------------------------------------

local Theme = {
	Background       = Color3.fromRGB(16, 16, 16),
	BackgroundEnd    = Color3.fromRGB(11, 11, 11),
	Card             = Color3.fromRGB(29, 29, 29),
	CardHover        = Color3.fromRGB(38, 38, 38),
	CardSelected     = Color3.fromRGB(46, 46, 46),
	CardInset        = Color3.fromRGB(24, 24, 24),
	SearchBox        = Color3.fromRGB(43, 43, 43),
	Stroke           = Color3.fromRGB(44, 44, 44),
	TextTitle        = Color3.fromRGB(245, 245, 245),
	TextBody         = Color3.fromRGB(232, 232, 232),
	TextSub          = Color3.fromRGB(154, 154, 154),
	TextMuted        = Color3.fromRGB(117, 117, 117),
	AccentDark       = Color3.fromRGB(30, 88, 61),
	Accent           = Color3.fromRGB(62, 156, 111),
	AccentSoft       = Color3.fromRGB(95, 191, 143),
	AccentText       = Color3.fromRGB(169, 232, 200),
	Knob             = Color3.fromRGB(245, 245, 245),
	KnobOff          = Color3.fromRGB(84, 84, 84),
	ToggleOff        = Color3.fromRGB(46, 46, 46),
	BadgeBackground  = Color3.fromRGB(240, 166, 63),
	BadgeText        = Color3.fromRGB(66, 45, 15),
	NotifyBackground = Color3.fromRGB(18, 18, 18),
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

-- instance helpers ------------------------------------------------------

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

local function strokeOn(inst, colorKey, transparency, thickness)
	local s = create("UIStroke", {
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Transparency = transparency or 0.5,
		Thickness = thickness or 1,
		Parent = inst,
	})
	paint(s, "Color", colorKey or "Stroke")
	return s
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

local TI_FAST = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TI_MED = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TI_MORPH = TweenInfo.new(0.38, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local TI_SLOW = TweenInfo.new(0.45, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)

local function tween(inst, info, props)
	local t = TweenService:Create(inst, info, props)
	t:Play()
	return t
end

-- icons ------------------------------------------------------------------

local Icons = nil
task.spawn(function()
	local ok, result = pcall(function()
		return loadstring(game:HttpGet("https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/refs/heads/main/icons.lua"))()
	end)
	if ok and type(result) == "table" then
		Icons = result
	end
end)

local function getLucide(name)
	if not Icons then return nil end
	local sized = Icons["48px"]
	if not sized then return nil end
	local entry = sized[string.lower(name)]
	if not entry then return nil end
	if type(entry[1]) ~= "number" then return nil end
	return {
		id = entry[1],
		size = Vector2.new(entry[2][1], entry[2][2]),
		offset = Vector2.new(entry[3][1], entry[3][2]),
	}
end

local function firstLucide(names)
	for _, name in ipairs(names) do
		local found = getLucide(name)
		if found then return found end
	end
	return nil
end

-- makes an ImageLabel for an icon which may be a lucide name or asset id.
-- lucide icons may still be downloading when UI builds, so string icons
-- retry for a short while before giving up.
local function makeIcon(parent, icon, size, color3, transparency)
	if icon == nil or icon == 0 or icon == "" then return nil end
	local img = create("ImageLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(size, size),
		ImageColor3 = color3 or Theme.TextTitle,
		ImageTransparency = transparency or 0,
		Parent = parent,
	})
	local function apply(name)
		local asset = getLucide(name)
		if asset then
			img.Image = "rbxassetid://" .. tostring(asset.id)
			img.ImageRectSize = asset.size
			img.ImageRectOffset = asset.offset
			return true
		end
		return false
	end
	if type(icon) == "number" then
		img.Image = "rbxassetid://" .. tostring(icon)
	elseif type(icon) == "string" then
		if not apply(icon) then
			task.spawn(function()
				for _ = 1, 40 do
					task.wait(0.25)
					if not img.Parent then return end
					if apply(icon) then return end
				end
			end)
		end
	end
	return img
end

-- library ----------------------------------------------------------------

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
		AnchorPoint = Vector2.new(0, 0),
		Position = UDim2.fromOffset(24, 24),
		Size = UDim2.fromOffset(330, 800),
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
		Position = UDim2.fromOffset(-360, 0),
		BackgroundTransparency = 0.02,
		BackgroundColor3 = Theme.NotifyBackground,
	})
	round(card, 16)
	create("UIStroke", {Color = Theme.Stroke, Transparency = 0.65, Parent = card})
	create("UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(196, 196, 196)),
		Parent = card,
	})
	padAll(card, 14, 16, 14, 16)

	local hasIcon = data.Image ~= nil and data.Image ~= ""
	local iconHolder = nil
	if hasIcon then
		iconHolder = create("Frame", {
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 0, 0.5, 0),
			Size = UDim2.fromOffset(36, 36),
			Parent = card,
		})
		local icon = makeIcon(iconHolder, data.Image, 26, Theme.TextTitle)
		if icon then
			icon.AnchorPoint = Vector2.new(0.5, 0.5)
			icon.Position = UDim2.fromScale(0.5, 0.5)
		end
	end

	local textCol = create("Frame", {
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
		Position = UDim2.fromOffset(hasIcon and 48 or 0, 0),
		Size = UDim2.new(1, hasIcon and -48 or 0, 0, 0),
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
		TextSize = 16,
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
		TextSize = 14,
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
		tween(card, TI_MED, {Position = UDim2.fromOffset(-360, 0)})
		task.wait(0.18)
		tween(wrapper, TI_MED, {Size = UDim2.new(1, 0, 0, 0)})
		task.wait(0.24)
		wrapper:Destroy()
	end

	clicker.MouseButton1Click:Connect(function()
		task.spawn(dismiss)
	end)

	task.defer(function()
		task.wait()
		local height = card.AbsoluteSize.Y
		wrapper.Size = UDim2.new(1, 0, 0, height)
		card.Position = UDim2.fromOffset(-360, 0)
		tween(card, TI_MORPH, {Position = UDim2.fromOffset(0, 0)})

		local duration = data.Duration or 5
		local elapsed = 0
		while elapsed < duration and not dismissed do
			local dt = task.wait(0.1)
			if not paused then elapsed = elapsed + dt end
		end
		dismiss()
	end)
end

-- sign in toast ----------------------------------------------------------

local function showAccountToast()
	if not LocalPlayer then return end
	ensureRoot()
	notifyOrder = notifyOrder + 1

	local wrapper = create("Frame", {
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Size = UDim2.new(0, 220, 0, 56),
		LayoutOrder = notifyOrder,
		Parent = notifyStack,
	})
	local pill = create("Frame", {
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.new(0, 0, 0, 52),
		Position = UDim2.fromOffset(-260, 0),
		BackgroundColor3 = Theme.NotifyBackground,
	})
	roundFull(pill)
	create("UIStroke", {Color = Theme.Stroke, Transparency = 0.65, Parent = pill})
	padAll(pill, 6, 18, 6, 6)
	create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 10),
		Parent = pill,
	})

	local avatar = create("ImageLabel", {
		BackgroundColor3 = Theme.Card,
		Size = UDim2.fromOffset(40, 40),
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
		Position = UDim2.fromOffset(0, 8),
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
		Position = UDim2.fromOffset(0, 24),
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
		tween(pill, TI_MED, {Position = UDim2.fromOffset(-260, 0)})
		task.wait(0.25)
		tween(wrapper, TI_MED, {Size = UDim2.new(0, 220, 0, 0)})
		task.wait(0.24)
		wrapper:Destroy()
	end)
end

-- window -----------------------------------------------------------------

function RayfieldLibrary:CreateWindow(Settings)
	Settings = Settings or {}
	ensureRoot()

	if Settings.KeySystem then
		warn("Rayfield Gen2: KeySystem is not supported yet, continuing without it")
	end

	-- configuration saving setup
	local configEnabled = false
	local configFolder = "Rayfield Gen2"
	local configFile = "Config"
	if type(Settings.ConfigurationSaving) == "table" and Settings.ConfigurationSaving.Enabled then
		configEnabled = fsAvailable
		configFolder = Settings.ConfigurationSaving.FolderName or configFolder
		configFile = Settings.ConfigurationSaving.FileName or configFile
	end
	local baseFolder = "Rayfield Gen2"
	ensureFolder(baseFolder)
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
				if element.Type == "Toggle" then
					out[flag] = element.CurrentValue
				elseif element.Type == "Slider" then
					out[flag] = element.CurrentValue
				elseif element.Type == "Input" then
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
		local path = baseFolder .. "/lastuser.txt"
		local last = safeReadFile(path)
		local current = tostring(LocalPlayer.UserId)
		safeWriteFile(path, current)
		if last ~= nil and last ~= current then
			task.wait(0.4)
			showAccountToast()
		end
	end)

	local WINDOW_W, WINDOW_H = 460, 545
	local HEADER_H = 74
	local PILL_W, PILL_H = 210, 52

	local shownPosition = UDim2.new(0.5, 0, 0.5, -math.floor((WINDOW_H + 18) / 2))

	local root = create("Frame", {
		Name = "WindowRoot",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = shownPosition,
		Size = UDim2.fromOffset(WINDOW_W, WINDOW_H + 18),
		Parent = rootGui,
	})

	local window = create("Frame", {
		Name = "Window",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 0),
		Size = UDim2.fromOffset(WINDOW_W, WINDOW_H),
		ClipsDescendants = true,
		Parent = root,
	})
	paint(window, "BackgroundColor3", "Background")
	local windowCorner = round(window, 18)
	create("UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(178, 178, 178)),
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
		BackgroundTransparency = 0.35,
		Parent = root,
	})
	roundFull(handle)

	connect(window:GetPropertyChangedSignal("Size"), function()
		handle.Position = UDim2.new(0.5, 0, 0, window.Size.Y.Offset + 12)
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
		local row = create("Frame", {
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.new(0, 0, 1, 0),
			Parent = pillContent,
		})
		create("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 10),
			Parent = row,
		})
		if Settings.Icon and Settings.Icon ~= 0 then
			local ic = makeIcon(row, Settings.Icon, 24, Theme.TextTitle)
			if ic then ic.LayoutOrder = 1 end
		end
		local col = create("Frame", {
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.new(0, 0, 0, 34),
			LayoutOrder = 2,
			Parent = row,
		})
		local pillName = create("TextLabel", {
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.new(0, 0, 0, 16),
			Font = FONT_BOLD,
			TextSize = 15,
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = Settings.Name or "Rayfield",
			Parent = col,
		})
		paint(pillName, "TextColor3", "TextTitle")
		local pillSub = create("TextLabel", {
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.new(0, 0, 0, 13),
			Position = UDim2.fromOffset(0, 18),
			Font = FONT_MEDIUM,
			TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = "Tap to show",
			Parent = col,
		})
		paint(pillSub, "TextColor3", "TextSub")
	end

	local pillButton = create("TextButton", {
		BackgroundTransparency = 1,
		Text = "",
		Size = UDim2.fromScale(1, 1),
		Visible = false,
		ZIndex = 12,
		Parent = window,
	})

	-- header ---------------------------------------------------------

	local header = create("Frame", {
		Name = "Header",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, HEADER_H),
		Parent = main,
	})

	local titleRow = create("Frame", {
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.X,
		Position = UDim2.fromOffset(22, 14),
		Size = UDim2.new(0, 0, 0, 28),
		Parent = header,
	})
	create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 12),
		Parent = titleRow,
	})

	local titleLabel = create("TextLabel", {
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.new(0, 0, 1, 0),
		Font = FONT_BOLD,
		TextSize = 22,
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
			Size = UDim2.new(0, 0, 0, 28),
			LayoutOrder = 2,
			Parent = titleRow,
		})
		paint(badge, "BackgroundColor3", "BadgeBackground")
		roundFull(badge)
		padAll(badge, 0, 12, 0, 12)
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
			TextSize = 14,
			Text = badgeText,
			LayoutOrder = 2,
			Parent = badge,
		})
		paint(bt, "TextColor3", "BadgeText")
	end

	local subtitleLabel = create("TextLabel", {
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.X,
		Position = UDim2.fromOffset(22, 44),
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
		Position = UDim2.new(1, -18, 0, 20),
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.new(0, 0, 0, 30),
		Parent = header,
	})
	create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 4),
		Parent = buttonRow,
	})

	local function headerButton(order, lucideNames, fallbackText)
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
			Size = UDim2.fromOffset(18, 18),
			ImageColor3 = Theme.TextSub,
			Parent = btn,
		})
		local fallback = nil
		local function applyIcon(names)
			local asset = firstLucide(names)
			if asset then
				icon.Image = "rbxassetid://" .. tostring(asset.id)
				icon.ImageRectSize = asset.size
				icon.ImageRectOffset = asset.offset
				icon.Visible = true
				if fallback then fallback.Visible = false end
				return true
			end
			return false
		end
		if not applyIcon(lucideNames) then
			fallback = create("TextLabel", {
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromOffset(20, 20),
				Font = FONT_BOLD,
				TextSize = 16,
				Text = fallbackText or "",
				TextColor3 = Theme.TextSub,
				Parent = btn,
			})
			icon.Visible = false
			task.spawn(function()
				for _ = 1, 40 do
					task.wait(0.25)
					if not btn.Parent then return end
					if applyIcon(lucideNames) then return end
				end
			end)
		end
		btn.MouseEnter:Connect(function()
			tween(icon, TI_FAST, {ImageColor3 = Theme.TextTitle})
			if fallback then tween(fallback, TI_FAST, {TextColor3 = Theme.TextTitle}) end
		end)
		btn.MouseLeave:Connect(function()
			tween(icon, TI_FAST, {ImageColor3 = Theme.TextSub})
			if fallback then tween(fallback, TI_FAST, {TextColor3 = Theme.TextSub}) end
		end)
		return btn, icon
	end

	local searchButton = headerButton(1, {"text-search", "search"}, "")
	local settingsButton = headerButton(2, {"settings"}, "")
	local minimizeButton, minimizeIcon = headerButton(3, {"minus"}, "-")
	local closeButton = headerButton(4, {"x"}, "x")

	-- body -----------------------------------------------------------

	local body = create("Frame", {
		Name = "Body",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(18, HEADER_H),
		Size = UDim2.new(1, -36, 1, -HEADER_H - 12),
		Parent = main,
	})

	local TABBAR_H = 42
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

	-- search row sits between the tab bar and the pages
	local searchHolder = create("Frame", {
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Position = UDim2.fromOffset(0, TABBAR_H + 6),
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
		Position = UDim2.fromOffset(0, TABBAR_H + 8),
		Size = UDim2.new(1, 0, 1, -(TABBAR_H + 8)),
		Parent = body,
	})

	-- window state ----------------------------------------------------

	local Window = {}
	local tabs = {}
	local currentTab = nil
	local settingsOpen = false
	local settingsPage = nil
	local hidden = false
	local minimized = false
	local searchOpen = false
	local morphing = false
	local storedPosition = nil

	local function layoutSearch(open)
		searchOpen = open
		local sh = open and 46 or 0
		tween(searchHolder, TI_MED, {Size = UDim2.new(1, 0, 0, open and 40 or 0)})
		tween(pagesHolder, TI_MED, {
			Position = UDim2.fromOffset(0, TABBAR_H + 8 + sh),
			Size = UDim2.new(1, 0, 1, -(TABBAR_H + 8 + sh)),
		})
		if open then
			task.delay(0.1, function() searchBox:CaptureFocus() end)
		else
			searchBox.Text = ""
			searchBox:ReleaseFocus()
		end
	end

	local function applySearchFilter(query)
		local page = settingsOpen and settingsPage or (currentTab and currentTab.Page)
		if not page then return end
		query = string.lower(query or "")
		for _, item in ipairs(page:GetChildren()) do
			if item:IsA("GuiObject") then
				local searchName = item:GetAttribute("SearchName")
				local structural = item:GetAttribute("Structural")
				if query == "" then
					item.Visible = true
				elseif structural then
					item.Visible = false
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

	-- tab switching
	local function selectTab(tab)
		if settingsOpen then
			settingsOpen = false
			if settingsPage then settingsPage.Visible = false end
		end
		currentTab = tab
		for _, other in ipairs(tabs) do
			local active = other == tab
			other.Page.Visible = active
			tween(other.Pill, TI_FAST, {BackgroundColor3 = active and Theme.CardHover or Theme.CardInset})
			tween(other.PillLabel, TI_FAST, {TextColor3 = active and Theme.TextTitle or Theme.TextSub})
			if other.PillIcon then
				tween(other.PillIcon, TI_FAST, {ImageColor3 = active and Theme.TextTitle or Theme.TextSub})
			end
			other.PillStroke.Transparency = active and 0.55 or 0.75
		end
		if searchOpen then
			searchBox.Text = ""
			applySearchFilter("")
		end
	end

	-- pages -----------------------------------------------------------

	local function buildPage()
		local page = create("ScrollingFrame", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = Color3.fromRGB(70, 70, 70),
			BorderSizePixel = 0,
			Visible = false,
			Parent = pagesHolder,
		})
		create("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 8),
			Parent = page,
		})
		padAll(page, 2, 4, 14, 0)
		return page
	end

	-- element construction ---------------------------------------------

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

	local function makeCard(page, name, icon, height)
		local card = create("Frame", {
			Size = UDim2.new(1, 0, 0, height or 48),
			LayoutOrder = nextOrder(),
			Parent = page,
		})
		card:SetAttribute("SearchName", name or "")
		paint(card, "BackgroundColor3", "Card")
		round(card, 14)
		strokeOn(card, "Stroke", 0.75)

		local textX = 16
		if icon then
			local ic = makeIcon(card, icon, 18, Theme.TextTitle, 0.05)
			if ic then
				ic.AnchorPoint = Vector2.new(0, 0.5)
				ic.Position = UDim2.new(0, 15, 0.5, 0)
				textX = 42
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
			Size = UDim2.new(1, -28, 0, 0),
			Font = FONT_REGULAR,
			TextSize = 13,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = text,
			LayoutOrder = nextOrder(),
			Parent = page,
		})
		desc:SetAttribute("SearchName", (card:GetAttribute("SearchName") or "") .. " " .. text)
		padAll(desc, 0, 0, 4, 14)
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

	-- Tab -------------------------------------------------------------

	local function buildTabAPI(page)
		local Tab = {}
		Tab.Page = page

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
				Position = UDim2.new(0, 8, 1, -2),
				Size = UDim2.new(1, -16, 0, 16),
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
				Size = UDim2.new(1, 0, 0, 6),
				LayoutOrder = nextOrder(),
				Parent = page,
			})
			holder:SetAttribute("Structural", true)
			local line = create("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.new(1, -8, 0, 1),
				BorderSizePixel = 0,
				Parent = holder,
			})
			paint(line, "BackgroundColor3", "Stroke")
			local DividerValue = {}
			function DividerValue:Set(visible)
				holder.Visible = visible
			end
			return DividerValue
		end

		function Tab:CreateLabel(text, icon, color, ignoreTheme)
			local card, label = makeCard(page, text, icon, 44)
			card.BackgroundTransparency = 0.45
			if color and typeof(color) == "Color3" then
				label.TextColor3 = color
			else
				label.TextColor3 = Theme.TextSub
			end
			local LabelValue = {}
			function LabelValue:Set(newText, newIcon, newColor)
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
			round(card, 14)
			strokeOn(card, "Stroke", 0.75)
			padAll(card, 14, 16, 14, 16)
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

		-- Gen2 stat card, the green gradient one
		function Tab:CreateStat(StatSettings)
			StatSettings = StatSettings or {}
			local card = create("Frame", {
				Size = UDim2.new(1, 0, 0, 96),
				LayoutOrder = nextOrder(),
				Parent = page,
			})
			card:SetAttribute("SearchName", StatSettings.Name or "")
			card.BackgroundColor3 = Theme.Accent
			round(card, 14)
			create("UIGradient", {
				Rotation = 115,
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
					ColorSequenceKeypoint.new(0.55, Color3.fromRGB(120, 120, 120)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(70, 70, 70)),
				}),
				Parent = card,
			})

			local topX = 16
			if StatSettings.Icon then
				local ic = makeIcon(card, StatSettings.Icon, 20, Color3.fromRGB(235, 250, 242))
				if ic then
					ic.Position = UDim2.fromOffset(15, 14)
					topX = 44
				end
			end
			local nameLabel = create("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(topX, 14),
				Size = UDim2.new(1, -topX - 16, 0, 20),
				Font = FONT_BOLD,
				TextSize = 17,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextColor3 = Color3.fromRGB(240, 252, 246),
				Text = StatSettings.Name or "",
				Parent = card,
			})
			local valueLabel = create("TextLabel", {
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(0, 1),
				Position = UDim2.new(0, 16, 1, -12),
				Size = UDim2.new(0.6, 0, 0, 28),
				Font = FONT_BOLD,
				TextSize = 24,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				Text = tostring(StatSettings.Value or ""),
				Parent = card,
			})
			local deltaLabel = create("TextLabel", {
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(1, 1),
				Position = UDim2.new(1, -16, 1, -14),
				Size = UDim2.new(0.35, 0, 0, 18),
				Font = FONT_BOLD,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Right,
				TextColor3 = Color3.fromRGB(196, 240, 217),
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
			local card, label = makeCard(page, ButtonSettings.Name, ButtonSettings.Icon, 48)
			makeDescription(page, card, ButtonSettings.Description)
			hoverable(card)
			local clicker = create("TextButton", {
				BackgroundTransparency = 1,
				Text = "",
				Size = UDim2.fromScale(1, 1),
				Parent = card,
			})
			clicker.MouseButton1Click:Connect(function()
				tween(card, TweenInfo.new(0.08, Enum.EasingStyle.Quad), {BackgroundColor3 = Theme.CardSelected})
				task.delay(0.1, function()
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
			local card = makeCard(page, ToggleSettings.Name, ToggleSettings.Icon, 48)
			makeDescription(page, card, ToggleSettings.Description)
			hoverable(card)

			local track = create("Frame", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -14, 0.5, 0),
				Size = UDim2.fromOffset(46, 26),
				Parent = card,
			})
			roundFull(track)
			create("UIGradient", {
				Rotation = 0,
				Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(210, 210, 210)),
				Parent = track,
			})
			local knob = create("Frame", {
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 3, 0.5, 0),
				Size = UDim2.fromOffset(20, 20),
				Parent = track,
			})
			roundFull(knob)

			local Toggle = {
				Type = "Toggle",
				CurrentValue = ToggleSettings.CurrentValue == true,
			}

			local function render(animate)
				local on = Toggle.CurrentValue
				local info = animate and TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out) or TweenInfo.new(0)
				tween(track, info, {BackgroundColor3 = on and Theme.Accent or Theme.ToggleOff})
				tween(knob, info, {
					Position = on and UDim2.new(1, -23, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
					BackgroundColor3 = on and Color3.fromRGB(228, 246, 236) or Theme.KnobOff,
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

			local card = create("Frame", {
				Size = UDim2.new(1, 0, 0, 58),
				LayoutOrder = nextOrder(),
				Parent = page,
			})
			card:SetAttribute("SearchName", SliderSettings.Name or "")
			paint(card, "BackgroundColor3", "Card")
			round(card, 14)
			strokeOn(card, "Stroke", 0.75)
			makeDescription(page, card, SliderSettings.Description)

			local textX = 16
			if SliderSettings.Icon then
				local ic = makeIcon(card, SliderSettings.Icon, 18, Theme.TextTitle, 0.05)
				if ic then
					ic.Position = UDim2.fromOffset(15, 12)
					textX = 42
				end
			end
			local nameLabel = create("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(textX, 10),
				Size = UDim2.new(0.5, -textX, 0, 18),
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
				Position = UDim2.fromOffset(textX, 31),
				Size = UDim2.new(0.5, -textX, 0, 16),
				Font = FONT_REGULAR,
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left,
				Text = "",
				Parent = card,
			})
			paint(valueLabel, "TextColor3", "TextSub")

			local track = create("Frame", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -16, 0.5, 0),
				Size = UDim2.new(0.42, 0, 0, 18),
				BackgroundColor3 = Color3.fromRGB(52, 52, 52),
				BackgroundTransparency = 0.25,
			})
			roundFull(track)
			track.Parent = card

			local fill = create("Frame", {
				Size = UDim2.new(0.5, 0, 1, 0),
				Parent = track,
			})
			paint(fill, "BackgroundColor3", "Accent")
			roundFull(fill)
			create("UIGradient", {
				Rotation = 0,
				Color = ColorSequence.new(Color3.fromRGB(160, 160, 160), Color3.fromRGB(255, 255, 255)),
				Parent = fill,
			})

			local knob = create("Frame", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				Size = UDim2.fromOffset(34, 26),
				ZIndex = 3,
			})
			paint(knob, "BackgroundColor3", "Knob")
			roundFull(knob)
			create("UIStroke", {
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				Color = Color3.fromRGB(255, 255, 255),
				Transparency = 0.75,
				Thickness = 4,
				Parent = knob,
			})
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
				alpha = math.clamp(alpha, 0, 1)
				local minAlpha = 0.2
				local shown = minAlpha + alpha * (1 - minAlpha)
				local info = animate and TI_FAST or TweenInfo.new(0)
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
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
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
			local card = makeCard(page, InputSettings.Name, InputSettings.Icon, 48)
			makeDescription(page, card, InputSettings.Description)
			hoverable(card)

			local boxHolder = create("Frame", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -12, 0.5, 0),
				Size = UDim2.fromOffset(170, 32),
				Parent = card,
			})
			paint(boxHolder, "BackgroundColor3", "CardHover")
			round(boxHolder, 10)
			local boxStroke = strokeOn(boxHolder, "Stroke", 0.6)

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
				tween(boxStroke, TI_FAST, {Transparency = 0.2})
			end)
			box.FocusLost:Connect(function()
				tween(boxStroke, TI_FAST, {Transparency = 0.6})
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
				Size = UDim2.new(1, 0, 0, 48),
				LayoutOrder = nextOrder(),
				Parent = page,
			})
			wrapper:SetAttribute("SearchName", DropdownSettings.Name or "")

			local card = create("Frame", {
				Size = UDim2.new(1, 0, 0, 48),
				Parent = wrapper,
			})
			paint(card, "BackgroundColor3", "Card")
			round(card, 14)
			strokeOn(card, "Stroke", 0.75)
			hoverable(card)

			local textX = 16
			if DropdownSettings.Icon then
				local ic = makeIcon(card, DropdownSettings.Icon, 18, Theme.TextTitle, 0.05)
				if ic then
					ic.AnchorPoint = Vector2.new(0, 0.5)
					ic.Position = UDim2.new(0, 15, 0.5, 0)
					textX = 42
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
				Position = UDim2.new(1, -14, 0.5, 0),
				Size = UDim2.fromOffset(16, 16),
				ImageColor3 = Theme.TextSub,
				Parent = card,
			})
			task.spawn(function()
				for _ = 1, 40 do
					local asset = getLucide("chevron-down")
					if asset then
						chevron.Image = "rbxassetid://" .. tostring(asset.id)
						chevron.ImageRectSize = asset.size
						chevron.ImageRectOffset = asset.offset
						return
					end
					task.wait(0.25)
					if not chevron.Parent then return end
				end
			end)

			local currentLabel = create("TextLabel", {
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -38, 0.5, 0),
				Size = UDim2.new(0.4, -38, 0, 16),
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
			local MAX_LIST = 236

			local listHolder = create("ScrollingFrame", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(0, 54),
				Size = UDim2.new(1, 0, 0, 0),
				CanvasSize = UDim2.new(0, 0, 0, 0),
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				ScrollingDirection = Enum.ScrollingDirection.Y,
				ScrollBarThickness = 2,
				ScrollBarImageColor3 = Color3.fromRGB(70, 70, 70),
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
					sIcon.Position = UDim2.new(0, 12, 0.5, 0)
				end
			end
			local optionSearch = create("TextBox", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(36, 0),
				Size = UDim2.new(1, -44, 1, 0),
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
					row.label.Position = UDim2.new(0, selected and 42 or 16, 0.5, 0)
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
					task.delay(0.1, function() setOpen(false) end)
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
						Position = UDim2.new(0, 14, 0.5, 0),
						Size = UDim2.fromOffset(18, 18),
						ImageColor3 = Theme.TextTitle,
						Visible = false,
						Parent = row,
					})
					task.spawn(function()
						for _ = 1, 40 do
							local asset = firstLucide({"square-check", "check-square", "check"})
							if asset then
								check.Image = "rbxassetid://" .. tostring(asset.id)
								check.ImageRectSize = asset.size
								check.ImageRectOffset = asset.offset
								return
							end
							task.wait(0.25)
							if not check.Parent then return end
						end
					end)
					local optionLabel = create("TextLabel", {
						BackgroundTransparency = 1,
						AnchorPoint = Vector2.new(0, 0.5),
						Position = UDim2.new(0, 16, 0.5, 0),
						Size = UDim2.new(1, -60, 0, 16),
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
			local card = makeCard(page, KeybindSettings.Name, KeybindSettings.Icon, 48)
			makeDescription(page, card, KeybindSettings.Description)
			hoverable(card)

			local keyHolder = create("Frame", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -12, 0.5, 0),
				AutomaticSize = Enum.AutomaticSize.X,
				Size = UDim2.fromOffset(34, 30),
			})
			paint(keyHolder, "BackgroundColor3", "CardHover")
			round(keyHolder, 10)
			local keyStroke = strokeOn(keyHolder, "Stroke", 0.6)
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
			padAll(keyHolder, 0, 8, 0, 8)

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
				tween(keyStroke, TI_FAST, {Transparency = 0.15})
			end)

			connect(UserInputService.InputBegan, function(input, processed)
				if listening then
					if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode ~= Enum.KeyCode.Unknown then
						listening = false
						tween(keyStroke, TI_FAST, {Transparency = 0.6})
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
				Size = UDim2.new(1, 0, 0, 48),
				LayoutOrder = nextOrder(),
				Parent = page,
			})
			wrapper:SetAttribute("SearchName", ColorPickerSettings.Name or "")

			local card = create("Frame", {
				Size = UDim2.new(1, 0, 0, 48),
				Parent = wrapper,
			})
			paint(card, "BackgroundColor3", "Card")
			round(card, 14)
			strokeOn(card, "Stroke", 0.75)
			hoverable(card)

			local textX = 16
			if ColorPickerSettings.Icon then
				local ic = makeIcon(card, ColorPickerSettings.Icon, 18, Theme.TextTitle, 0.05)
				if ic then
					ic.AnchorPoint = Vector2.new(0, 0.5)
					ic.Position = UDim2.new(0, 15, 0.5, 0)
					textX = 42
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
				Position = UDim2.new(1, -14, 0.5, 0),
				Size = UDim2.fromOffset(40, 26),
				BackgroundColor3 = color,
				Parent = card,
			})
			round(swatch, 8)
			strokeOn(swatch, "Stroke", 0.4)

			local panel = create("Frame", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(0, 54),
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
				local rowY = (i - 1) * 34
				local row = create("Frame", {
					BackgroundTransparency = 1,
					Position = UDim2.fromOffset(0, rowY),
					Size = UDim2.new(1, 0, 0, 28),
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
					Size = UDim2.new(1, -86, 0, 12),
					BackgroundColor3 = Color3.fromRGB(52, 52, 52),
					Parent = row,
				})
				roundFull(track)
				local fill = create("Frame", {
					Size = UDim2.new(0.5, 0, 1, 0),
					Parent = track,
				})
				paint(fill, "BackgroundColor3", "Accent")
				roundFull(fill)
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
					fill.Size = UDim2.new(channel.value / 255, 0, 1, 0)
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
				tween(panel, TI_MED, {Size = UDim2.new(1, 0, 0, open and 3 * 34 or 0)})
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

		return Tab
	end

	-- Window:CreateTab --------------------------------------------------

	function Window:CreateTab(tabName, tabImage, ext)
		local page = buildPage()
		local Tab = buildTabAPI(page)

		local pill = create("TextButton", {
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.new(0, 0, 0, 38),
			Text = "",
			LayoutOrder = #tabs + 1,
			Parent = tabBar,
		})
		pill.BackgroundColor3 = Theme.CardInset
		roundFull(pill)
		local pillStroke = strokeOn(pill, "Stroke", 0.75)
		padAll(pill, 0, 16, 0, 16)
		create("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 8),
			Parent = pill,
		})
		local pillIcon = nil
		if tabImage then
			pillIcon = makeIcon(pill, tabImage, 16, Theme.TextSub)
			if pillIcon then pillIcon.LayoutOrder = 1 end
		end
		local pillLabel = create("TextLabel", {
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.new(0, 0, 1, 0),
			Font = FONT_MEDIUM,
			TextSize = 15,
			Text = tabName or "Tab",
			TextColor3 = Theme.TextSub,
			LayoutOrder = 2,
			Parent = pill,
		})

		local tabEntry = {
			Name = tabName,
			Page = page,
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
			selectTab(tabEntry)
		end

		return Tab
	end

	-- settings page ------------------------------------------------------

	local toggleKeyName = "K"
	if Settings.ToggleUIKeybind then
		if typeof(Settings.ToggleUIKeybind) == "EnumItem" then
			toggleKeyName = Settings.ToggleUIKeybind.Name
		else
			toggleKeyName = tostring(Settings.ToggleUIKeybind)
		end
	end

	local function buildSettingsPage()
		settingsPage = buildPage()
		local SettingsTab = buildTabAPI(settingsPage)
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
		if not settingsPage then buildSettingsPage() end
		settingsOpen = not settingsOpen
		if settingsOpen then
			for _, other in ipairs(tabs) do
				other.Page.Visible = false
			end
			settingsPage.Visible = true
		else
			settingsPage.Visible = false
			if currentTab then currentTab.Page.Visible = true end
		end
	end)

	-- dragging -----------------------------------------------------------

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
				root.Position = UDim2.new(
					startPos.X.Scale, startPos.X.Offset + delta.X,
					startPos.Y.Scale, startPos.Y.Offset + delta.Y
				)
			end
		end)
	end
	makeDraggable(header)
	makeDraggable(handle)

	-- minimize and hide ----------------------------------------------------

	local function setMinimizeIcon(restore)
		local names = restore and {"maximize-2", "expand"} or {"minus"}
		local asset = firstLucide(names)
		if asset then
			minimizeIcon.Image = "rbxassetid://" .. tostring(asset.id)
			minimizeIcon.ImageRectSize = asset.size
			minimizeIcon.ImageRectOffset = asset.offset
		end
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

	local function hideWindow()
		if morphing or hidden then return end
		morphing = true
		hidden = true
		storedPosition = root.Position
		handle.Visible = false
		tween(main, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {GroupTransparency = 1})
		task.wait(0.15)
		main.Visible = false
		tween(windowCorner, TI_MORPH, {CornerRadius = UDim.new(0, 26)})
		tween(window, TI_MORPH, {Size = UDim2.fromOffset(PILL_W, PILL_H)})
		tween(root, TI_MORPH, {Position = UDim2.new(0.5, 0, 0, 18)})
		task.wait(0.3)
		pillContent.Visible = true
		pillButton.Visible = true
		tween(pillContent, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {GroupTransparency = 0})
		morphing = false
	end

	local function showWindow()
		if morphing or not hidden then return end
		morphing = true
		hidden = false
		tween(pillContent, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {GroupTransparency = 1})
		task.wait(0.13)
		pillContent.Visible = false
		pillButton.Visible = false
		tween(windowCorner, TI_MORPH, {CornerRadius = UDim.new(0, 18)})
		tween(window, TI_MORPH, {Size = UDim2.fromOffset(WINDOW_W, minimized and HEADER_H or WINDOW_H)})
		tween(root, TI_MORPH, {Position = storedPosition or shownPosition})
		task.wait(0.32)
		main.Visible = true
		tween(main, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {GroupTransparency = 0})
		handle.Visible = true
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

	-- library level window controls
	RayfieldLibrary._hideWindow = hideWindow
	RayfieldLibrary._showWindow = showWindow
	RayfieldLibrary._isHidden = function() return hidden end

	-- Window API -----------------------------------------------------------

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

	-- entrance animation
	window.Size = UDim2.fromOffset(WINDOW_W - 40, WINDOW_H - 48)
	handle.BackgroundTransparency = 1
	tween(window, TI_SLOW, {Size = UDim2.fromOffset(WINDOW_W, WINDOW_H)})
	tween(main, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {GroupTransparency = 0})
	tween(handle, TI_SLOW, {BackgroundTransparency = 0.35})

	-- config load ----------------------------------------------------------

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

-- visibility and teardown --------------------------------------------------

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
