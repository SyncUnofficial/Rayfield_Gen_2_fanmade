local Rayfield = loadstring(game:HttpGet("https://raw.githubusercontent.com/SyncUnofficial/Rayfield_Gen_2_fanmade/main/source.lua"))()

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
local Layout = Window:CreateTab("Layout", "layout-grid")

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

Home:CreateSection("Notifications")

Home:CreateButton({
	Name = "Send Notification",
	Icon = "bell",
	Callback = function()
		Rayfield:Notify({
			Title = "Heads up",
			Content = "This is a notification. Hover to pause it, or click to dismiss early.",
			Duration = 5,
			Image = "house",
		})
	end,
})

Home:CreateButton({
	Name = "Send Long Notification",
	Icon = "bell",
	Callback = function()
		Rayfield:Notify({
			Title = "Longer notification",
			Content = "This one has a lot more text so you can check that the card grows to fit the content, wraps every line properly, and still slides in and out from the right side smoothly.",
			Duration = 8,
			Image = "chart-no-axes-column",
		})
	end,
})

Home:CreateButton({
	Name = "Send Without Icon",
	Icon = "bell",
	Callback = function()
		Rayfield:Notify({
			Title = "No icon here",
			Content = "Notifications work fine without an icon too, and the text column stretches to fill the width.",
			Duration = 6,
		})
	end,
})

Home:CreateButton({
	Name = "Send 3 Stacked",
	Icon = "bell",
	Callback = function()
		for i = 1, 3 do
			Rayfield:Notify({
				Title = "Heads up",
				Content = "This is a notification. Hover to pause it, or click to dismiss early.",
				Duration = 4 + i,
				Image = "house",
			})
			task.wait(0.45)
		end
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

Numbers:CreateSection("Charts")

local Revenue = Numbers:CreateChart({
	Name = "Revenue",
	Icon = "coins",
	Prefix = "$",
	Points = {8200, 8600, 8400, 9300, 9100, 9900, 11400, 12400},
})

local Players = Numbers:CreateChart({
	Name = "Players Online",
	Suffix = " ccu",
	Filled = false,
	Points = {120, 180, 160, 260, 310, 290, 380, 430, 410, 540},
})

Numbers:CreateButton({
	Name = "Push Data",
	Icon = "trending-up",
	Callback = function()
		Revenue:Push(12400 + math.random(-1500, 2500))
		Players:Push(540 + math.random(-120, 160))
	end,
})

local Session = Numbers:CreateChart({
	Name = "Session Time",
	Icon = "activity",
	Suffix = " min",
	Smooth = true,
	Points = {6, 12, 9, 21, 11, 22, 13, 15, 7, 19, 12, 24},
})

local Kills = Numbers:CreateBarChart({
	Name = "Kills per Match",
	Icon = "crosshair",
	Points = {
		{Label = "M1", Value = 2},
		{Label = "M2", Value = 3},
		{Label = "M3", Value = 5},
		{Label = "M4", Value = 6},
		{Label = "M5", Value = 4},
		{Label = "M6", Value = 3},
		{Label = "M7", Value = 2},
	},
})

Numbers:CreatePieChart({
	Name = "Key Sources",
	Icon = "pie-chart",
	Slices = {
		{Name = "Via Internet", Value = 62.5},
		{Name = "Agencies", Value = 25},
		{Name = "Both", Value = 12.5},
	},
})

Numbers:CreateStackedChart({
	Name = "Spending",
	Icon = "wallet",
	Series = {"Housing", "Food", "Transport"},
	Rows = {
		{Name = "Anna", Values = {8, 8, 4}},
		{Name = "Ben", Values = {12, 10, 8}},
		{Name = "Clara", Values = {16, 10, 10}},
		{Name = "David", Values = {20, 24, 6}},
	},
})

Numbers:CreateRadarChart({
	Name = "Team Skills",
	Icon = "radar",
	Axes = {"Innovation", "Customer", "Efficiency", "Teamwork", "Revenue"},
	Max = 10,
	Sets = {
		{Name = "This Year", Values = {9, 10, 7, 7, 3}},
		{Name = "Last Year", Values = {5, 6, 9, 8, 9}},
	},
})

Numbers:CreateButton({
	Name = "Show Graph Animation",
	Icon = "play",
	Callback = function()
		Revenue:Replay()
		Players:Replay()
		Session:Replay()
		Kills:Replay()
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

Layout:CreateSection("Main")

local TopRow = Layout:CreateRow()
TopRow:CreateToggle({
	Name = "Switch",
	Icon = "messages-square",
	CurrentValue = false,
	Flag = "RowSwitch",
	Callback = function(value)
		print("Row switch:", value)
	end,
})
TopRow:CreateButton({
	Name = "Button",
	Icon = "sparkles",
	Callback = function()
		print("Row button pressed")
	end,
})

local StatRow = Layout:CreateRow()
local Money = StatRow:CreateStat({
	Name = "Money",
	Icon = "messages-square",
	Delta = "+19%",
})
StatRow:CreateButton({
	Name = "Play",
	Icon = "sparkles",
	Callback = function()
		Money:Set({Delta = "+" .. tostring(math.random(1, 40)) .. "%"})
	end,
})

Layout:CreateSection("Row")

local TripleRow = Layout:CreateRow()
TripleRow:CreateButton({
	Name = "Save",
	Icon = "layout-panel-left",
	Callback = function()
		print("Saved")
	end,
})
TripleRow:CreateToggle({
	Name = "ESP",
	CurrentValue = true,
	Flag = "RowESP",
	Callback = function(value)
		print("ESP:", value)
	end,
})
local Kills = TripleRow:CreateStat({
	Name = "Kills",
	Icon = "chart-no-axes-column",
	Value = "128",
})

Layout:CreateSection("Two columns")

local Left, Right = Layout:CreateColumns(2)
Left:CreateToggle({
	Name = "Aimbot",
	CurrentValue = false,
	Flag = "Aimbot",
	Callback = function(value)
		print("Aimbot:", value)
	end,
})
Left:CreateToggle({
	Name = "Triggerbot",
	CurrentValue = false,
	Flag = "Triggerbot",
	Callback = function(value)
		print("Triggerbot:", value)
	end,
})
Left:CreateSlider({
	Name = "Smoothing",
	Range = {0, 100},
	Increment = 1,
	Suffix = "%",
	CurrentValue = 40,
	Flag = "Smoothing",
	Callback = function(value)
		print("Smoothing:", value)
	end,
})
Right:CreateToggle({
	Name = "ESP Boxes",
	CurrentValue = true,
	Flag = "ESPBoxes",
	Callback = function(value)
		print("ESP Boxes:", value)
	end,
})
Right:CreateToggle({
	Name = "ESP Names",
	CurrentValue = false,
	Flag = "ESPNames",
	Callback = function(value)
		print("ESP Names:", value)
	end,
})
Right:CreateDropdown({
	Name = "ESP Color",
	Options = {"Green", "Red", "Blue", "White"},
	CurrentOption = {"Green"},
	Flag = "ESPColor",
	Callback = function(selection)
		print("ESP Color:", table.concat(selection, ", "))
	end,
})

Rayfield:Notify({
	Title = "Welcome back",
	Content = "Rayfield Gen2 loaded. Hover to pause, click to dismiss.",
	Duration = 6,
	Image = "house",
})

Rayfield:LoadConfiguration()
