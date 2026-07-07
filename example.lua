-- Rayfield Gen 2 [fanmade] example
-- loads the library and builds a demo window with every element

local Rayfield = loadstring(game:HttpGet("https://raw.githubusercontent.com/SyncOfficialSpec/Rayfield_Gen_2_fanmade/main/source.lua"))()

local Window = Rayfield:CreateWindow({
	Name = "Example",
	Subtitle = "Rayfield Gen2",
	Icon = "shell",
	Badge = {Text = "us-en", Icon = "messages-square"},
	LoadingTitle = "Example",
	LoadingSubtitle = "by Rayfield Gen2",
	ToggleUIKeybind = "K",
	ConfigurationSaving = {
		Enabled = true,
		FolderName = "RayfieldGen2Example",
		FileName = "Example",
	},
})

local Home = Window:CreateTab("Home", "house")
local Numbers = Window:CreateTab("Numbers", "chart-no-axes-column")

Home:CreateSection("Gameplay")

Home:CreateToggle({
	Name = "Auto Sprint",
	Icon = "fast-forward",
	CurrentValue = true,
	Flag = "AutoSprint",
	Callback = function(value)
		print("Auto Sprint:", value)
	end,
})

Home:CreateToggle({
	Name = "Reduced Motion",
	CurrentValue = false,
	Flag = "ReducedMotion",
	Description = "Disables screen shake and camera effects for a smoother experience.",
	Callback = function(value)
		print("Reduced Motion:", value)
	end,
})

Home:CreateSlider({
	Name = "Field of View",
	Range = {70, 120},
	Increment = 1,
	Suffix = "°",
	CurrentValue = 104,
	Flag = "FieldOfView",
	Callback = function(value)
		workspace.CurrentCamera.FieldOfView = value
	end,
})

Home:CreateSection("Interface")

Home:CreateToggle({
	Name = "Show FPS Counter",
	CurrentValue = false,
	Flag = "ShowFPS",
	Callback = function(value)
		print("FPS Counter:", value)
	end,
})

Home:CreateToggle({
	Name = "Compact HUD",
	CurrentValue = false,
	Flag = "CompactHUD",
	Callback = function(value)
		print("Compact HUD:", value)
	end,
})

Numbers:CreateSection("Main")

local Stat = Numbers:CreateStat({
	Name = "Currency",
	Icon = "coins",
	Value = "$21",
	Delta = "+19%",
})

Numbers:CreateButton({
	Name = "Button",
	Icon = "sparkles",
	Callback = function()
		Stat:Set({Value = "$" .. tostring(math.random(10, 99)), Delta = "+" .. tostring(math.random(1, 30)) .. "%"})
	end,
})

Numbers:CreateToggle({
	Name = "Automatic Trade Negotiation",
	Icon = "message-square",
	CurrentValue = false,
	Flag = "AutoTrade",
	Description = "This feature will enable trades to be completed automatically using AI tone and conversation engines.",
	Callback = function(value)
		print("Auto trade:", value)
	end,
})

Numbers:CreateSlider({
	Name = "Trades",
	Icon = "layout-panel-left",
	Range = {0, 60},
	Increment = 1,
	Suffix = "a minute",
	CurrentValue = 22,
	Flag = "TradesPerMinute",
	Callback = function(value)
		print("Trades per minute:", value)
	end,
})

Numbers:CreateKeybind({
	Name = "Toggle Automation",
	Icon = "settings-2",
	CurrentKeybind = "Q",
	Flag = "AutomationKey",
	Callback = function()
		print("Automation toggled")
	end,
})

Numbers:CreateInput({
	Name = "Target Player",
	PlaceholderText = "Dynamic Input",
	CurrentValue = "",
	Flag = "TargetPlayer",
	Callback = function(text)
		print("Target:", text)
	end,
})

Numbers:CreateDropdown({
	Name = "Dropdown",
	Options = {"Option 1", "Option 2", "Option 3", "Option 4"},
	CurrentOption = {"Option 1"},
	Flag = "DemoDropdown",
	Callback = function(selection)
		print("Selected:", table.concat(selection, ", "))
	end,
})

Rayfield:Notify({
	Title = "Welcome back",
	Content = "Rayfield Gen2 loaded. Hover to pause, click to dismiss.",
	Duration = 6,
	Image = "house",
})

Rayfield:LoadConfiguration()
