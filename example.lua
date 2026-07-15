local Rayfield = loadstring(game:HttpGet("https://raw.githubusercontent.com/SyncUnofficial/Rayfield_Gen_2_fanmade/main/source.lua"))()

local Window = Rayfield:CreateWindow({
	name = "Example",
	subtitle = "Rayfield Gen2",
	icon = "shell",
	theme = "default",
	configuration = {
		autoSave = true,
		autoLoad = true,
		fileName = "ExampleHub",
	},
	translations = {
		fr = { ["Auto Sprint"] = "Sprint auto", ["Home"] = "Accueil" },
	},
})

Window:CreateTag({ text = "us-en", color = Color3.fromRGB(255, 175, 15) })

local Home = Window:CreateTab({ name = "Home", icon = "house" })
local Fields = Window:CreateTab({ name = "Fields", icon = "text-cursor-input" })
local Numbers = Window:CreateTab({ name = "Numbers", icon = "chart-no-axes-column" })
local Layout = Window:CreateTab({ name = "Layout", icon = "layout-grid" })

Home:CreateSection({ name = "Gameplay", icon = "gamepad-2" })

Home:CreateToggle({
	name = "Auto Sprint",
	icon = "fast-forward",
	value = true,
	flag = "AutoSprint",
	callback = function(value)
		print("Auto Sprint:", value)
	end,
})

Home:CreateToggle({
	name = "Reduced Motion",
	value = false,
	flag = "ReducedMotion",
	description = "Disables screen shake and camera effects for a smoother experience.",
	callback = function(value)
		print("Reduced Motion:", value)
	end,
})

Home:CreateSlider({
	name = "Field of View",
	range = { 70, 120 },
	increment = 1,
	suffix = "°",
	value = 104,
	flag = "FieldOfView",
	callback = function(value)
		workspace.CurrentCamera.FieldOfView = value
	end,
})

Home:CreateSection({ name = "Messages", icon = "bell" })

Home:CreateButton({
	name = "Send Notification",
	icon = "bell",
	callback = function()
		Window:Notify({
			title = "Heads up",
			content = "This is a notification. Hover to pause it, or click to dismiss early.",
			duration = 5,
			icon = "house",
		})
	end,
})

Home:CreateButton({
	name = "Drop a Toast",
	icon = "check",
	callback = function()
		Window:Toast({ title = "Saved", icon = "check" })
	end,
})

Home:CreateButton({
	name = "Open Popup",
	icon = "message-square",
	callback = function()
		Window:Popup({
			title = "Reset everything?",
			content = "This clears every saved value. You can't undo it.",
			options = {
				{ text = "Cancel" },
				{ text = "Reset", style = "danger", callback = function() print("reset") end },
			},
		})
	end,
})

Home:CreateSection({ name = "Appearance", icon = "palette" })

Home:CreateDropdown({
	name = "Theme",
	options = { "default", "cobalt", "ember", "amethyst", "frost", "rose" },
	value = "default",
	flag = "Theme",
	callback = function(choice)
		Window:ChangeTheme(choice)
	end,
})

Home:CreateFAQ({
	Items = {
		{
			Question = "Why was this fanmade Gen 2 created?",
			Answer = "So people can experience a Gen 2 style Rayfield right now instead of waiting for the official release. It is a fan project built from zero, not a replacement for the real thing.",
		},
		{
			Question = "Will my existing Rayfield scripts work?",
			Answer = "Yes. Both the original PascalCase API and the new Gen2 API are accepted, so most scripts load without any changes.",
		},
		{
			Question = "Is this affiliated with Sirius?",
			Answer = "No. This is an unofficial fan remake and has no connection to Sirius or the actual Rayfield developers. The real Rayfield lives at docs.sirius.menu.",
		},
	},
})

Fields:CreateSection({ name = "Setup" })

Fields:CreateInput({
	name = "Player Name",
	placeholder = "Enter a name",
	value = "",
	flag = "PlayerName",
	callback = function(text)
		print("Name:", text)
	end,
})

Fields:CreateInput({
	name = "Max Players",
	numeric = true,
	value = "16",
	placeholder = "Enter a number",
	description = "Numeric only, commits when you click away or press enter.",
	flag = "MaxPlayers",
	callback = function(text)
		print("Max players:", text)
	end,
})

Fields:CreateKeybind({
	name = "Sprint",
	value = Enum.KeyCode.LeftShift,
	flag = "SprintKey",
	callback = function(key)
		print("Pressed", key)
	end,
})

Fields:CreateColorPicker({
	name = "Highlight",
	color = Color3.fromRGB(96, 205, 255),
	alpha = 1,
	flag = "Highlight",
	callback = function(color, alpha)
		print("Color:", color, "Alpha:", alpha)
	end,
})

Numbers:CreateSection({ name = "Main" })

local Stat = Numbers:CreateStat({
	name = "Currency",
	icon = "coins",
	prefix = "$",
	value = 21,
})

Numbers:CreateButton({
	name = "Roll",
	icon = "sparkles",
	callback = function()
		Stat:Set(math.random(10, 99))
	end,
})

Numbers:CreateSection({ name = "Charts" })

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
	name = "Push Data",
	icon = "trending-up",
	callback = function()
		Revenue:Push(12400 + math.random(-1500, 2500))
		Players:Push(540 + math.random(-120, 160))
	end,
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
	},
})

Numbers:CreateDropdown({
	name = "Modules",
	multiSelect = true,
	options = { "Aimbot", "ESP", "Fly", "Noclip" },
	value = { "ESP" },
	flag = "Modules",
	callback = function(selected)
		print("Selected:", table.concat(selected, ", "))
	end,
})

Layout:CreateSection({ name = "Two columns" })

local grid = Layout:CreateGroup()

local left = grid:CreateGroup({ direction = "column" })
left:CreateToggle({ name = "Aimbot", flag = "Aimbot", callback = function(v) print("Aimbot:", v) end })
left:CreateToggle({ name = "Triggerbot", flag = "Triggerbot", callback = function(v) print("Triggerbot:", v) end })

local right = grid:CreateGroup({ direction = "column" })
right:CreateToggle({ name = "ESP", value = true, flag = "ESP", callback = function(v) print("ESP:", v) end })
right:CreateToggle({ name = "Tracers", flag = "Tracers", callback = function(v) print("Tracers:", v) end })

Window:Notify({
	title = "Welcome back",
	content = "Rayfield Gen2 loaded. Hover to pause, click to dismiss.",
	duration = 6,
	icon = "house",
})
