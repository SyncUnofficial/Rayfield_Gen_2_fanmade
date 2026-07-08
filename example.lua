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
			Image = "messages-square",
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
