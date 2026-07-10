# Rayfield Gen 2 [fanmade]

Fan remake of the Rayfield UI library for Roblox executors. Same API as the original, so scripts written for Rayfield mostly just work. The interface itself is rebuilt from zero. Darker, rounder, better animations.

> Not affiliated with Sirius or the actual Rayfield devs. The real Rayfield lives at [docs.sirius.menu/rayfield](https://docs.sirius.menu/rayfield).

## Loading

```lua
local Rayfield = loadstring(game:HttpGet(
	"https://raw.githubusercontent.com/SyncUnofficial/Rayfield_Gen_2_fanmade/main/source.lua"
))()
```

There's a full demo in `example.lua` with every element in it.

## Creating a window

```lua
local Window = Rayfield:CreateWindow({
	Name = "Example",
	Subtitle = "Rayfield Gen2",          -- optional, shown under the title
	Icon = "shell",                      -- optional, lucide name or asset id, used by the hide pill
	Badge = {Text = "us-en", Icon = "messages-square"},  -- optional header pill
	LoadingTitle = "Example",            -- optional loading screen
	LoadingSubtitle = "by Rayfield Gen2",
	ToggleUIKeybind = "K",
	ConfigurationSaving = {
		Enabled = true,
		FolderName = "MyScript",
		FileName = "Config",
	},
	KeySystem = false,                   -- optional key gate, same fields as original Rayfield
	KeySettings = {
		Title = "Example Key",
		Subtitle = "Enter your key to continue",
		Note = "Get a key from the Discord",
		FileName = "ExampleKey",
		SaveKey = true,
		GrabKeyFromSite = false,
		Key = {"Hello"},
	},
})
```

## Tabs and sections

```lua
local Tab = Window:CreateTab("Home", "house")  -- name, lucide icon or asset id
Tab:CreateSection("Gameplay")
Tab:CreateDivider()
```

## Elements

Every element takes an optional `Icon` (lucide name or Roblox asset id) and an optional `Description` that shows as muted text under it.

```lua
Tab:CreateButton({
	Name = "Do Something",
	Callback = function() end,
})

Tab:CreateToggle({
	Name = "Auto Sprint",
	CurrentValue = false,
	Flag = "AutoSprint",
	Callback = function(value) end,
})

Tab:CreateSlider({
	Name = "Field of View",
	Range = {70, 120},
	Increment = 1,
	Suffix = "°",
	CurrentValue = 104,
	Flag = "FOV",
	Callback = function(value) end,
})

Tab:CreateInput({
	Name = "Target Player",
	PlaceholderText = "Username",
	CurrentValue = "",
	RemoveTextAfterFocusLost = false,
	Flag = "Target",
	Callback = function(text) end,
})

Tab:CreateDropdown({
	Name = "Weapon",
	Options = {"Sword", "Bow", "Staff"},
	CurrentOption = {"Sword"},
	MultipleOptions = false,
	Flag = "Weapon",
	Callback = function(options) end,  -- receives a table of selected options
})

Tab:CreateKeybind({
	Name = "Toggle Automation",
	CurrentKeybind = "Q",
	HoldToInteract = false,
	Flag = "AutoKey",
	Callback = function() end,
})

Tab:CreateLabel("Just some text", "info")
Tab:CreateParagraph({Title = "Notes", Content = "Longer text that wraps."})

Tab:CreateColorPicker({
	Name = "ESP Color",
	Color = Color3.fromRGB(255, 100, 100),
	Flag = "ESPColor",
	Callback = function(color) end,
})
```

### Stat cards

```lua
local Stat = Tab:CreateStat({
	Name = "Currency",
	Icon = "coins",
	Value = "$21",
	Delta = "+19%",
})
Stat:Set({Value = "$40", Delta = "+90%"})
```

### Charts

Line charts with hover. Move the mouse over the card and a crosshair snaps to the nearest point, the value up top rolls to that point. `Filled` draws the area under the line, leave it off for a plain line. `Push` appends a point and drops the oldest once you hit `MaxPoints`.

```lua
local Revenue = Tab:CreateChart({
	Name = "Revenue",
	Icon = "coins",
	Prefix = "$",
	Points = {8200, 8600, 8400, 9300, 9100, 9900, 11400, 12400},
})
Revenue:Push(13100)
Revenue:Replay()

Tab:CreateChart({
	Name = "Players Online",
	Suffix = " ccu",
	Filled = false,
	Points = {120, 180, 160, 260, 310, 290, 380, 430, 410, 540},
	MaxPoints = 20,
})
```

`Smooth = true` bends the line through the points instead of connecting them straight.

More chart types, same idea (hover for values, `Set` to update, `Replay` to rerun the build in animation):

```lua
Tab:CreateBarChart({
	Name = "Kills per Match",
	Points = {{Label = "M1", Value = 2}, {Label = "M2", Value = 5}, 6, 4},
})

Tab:CreatePieChart({
	Name = "Key Sources",
	Slices = {
		{Name = "Via Internet", Value = 62.5},
		{Name = "Agencies", Value = 25},
		{Name = "Both", Value = 12.5},
	},
})

Tab:CreateStackedChart({
	Name = "Spending",
	Series = {"Housing", "Food", "Transport"},
	Rows = {
		{Name = "Anna", Values = {8, 8, 4}},
		{Name = "Ben", Values = {12, 10, 8}},
	},
})

Tab:CreateRadarChart({
	Name = "Team Skills",
	Axes = {"Innovation", "Customer", "Efficiency", "Teamwork", "Revenue"},
	Max = 10,
	Sets = {
		{Name = "This Year", Values = {9, 10, 7, 7, 3}},
		{Name = "Last Year", Values = {5, 6, 9, 8, 9}},
	},
})
```

Bar charts take plain numbers or `{Label, Value}` pairs and support `Push`. Pie slices and stacked series pick theme colors automatically, pass `Color` per slice or `Colors` on the chart to override. Radar is outline style since Roblox can't fill arbitrary polygons.

### Rows and columns

Rows put elements next to each other with equal widths. Columns split the page into vertical stacks. Both give you the same element API a tab does, just compact: buttons center their content, sliders stack the track under the labels, stat cards shrink into pills, descriptions get skipped.

```lua
local Row = Tab:CreateRow()
Row:CreateToggle({Name = "ESP", CurrentValue = true, Callback = function(v) end})
Row:CreateButton({Name = "Save", Icon = "save", Callback = function() end})
Row:CreateStat({Name = "Kills", Icon = "chart-no-axes-column", Value = "128"})

local Left, Right = Tab:CreateColumns(2)
Left:CreateToggle({Name = "Aimbot", CurrentValue = false, Callback = function(v) end})
Left:CreateSlider({Name = "Smoothing", Range = {0, 100}, CurrentValue = 40, Suffix = "%", Callback = function(v) end})
Right:CreateDropdown({Name = "ESP Color", Options = {"Green", "Red"}, CurrentOption = {"Green"}, Callback = function(o) end})
```

## Notifications

```lua
Rayfield:Notify({
	Title = "Welcome back",
	Content = "Rayfield Gen2 loaded. Hover to pause, click to dismiss.",
	Duration = 6,
	Image = "house",  -- optional
})
```

## Updating elements from code

Elements return an object with `Set`, same as original Rayfield:

```lua
local Toggle = Tab:CreateToggle({...})
Toggle:Set(true)

local Dropdown = Tab:CreateDropdown({...})
Dropdown:Set({"Bow"})
Dropdown:Refresh({"Sword", "Bow", "Staff", "Axe"})
```

## Configuration saving

Give an element a `Flag` and turn on `ConfigurationSaving` in the window settings. Values save on change. Call this at the end of your script to load them back:

```lua
Rayfield:LoadConfiguration()
```

## Visibility and cleanup

```lua
Rayfield:IsVisible()
Rayfield:SetVisibility(false)  -- morphs into the pill
Rayfield:SetVisibility(true)
Rayfield:Destroy()
```

The gear in the header opens a settings page where you can rebind the toggle key, unlock the cursor for games that lock it, or unload the whole thing.

## Icons

Lucide names work ("house", "coins", "settings"). The icon index Rayfield uses is an older lucide release, so renamed icons get aliased automatically, "house" resolves to "home" and so on. Plain asset ids work too. The index gets cached in your executor's workspace folder after the first run so icons keep working offline. If it can't be fetched at all the UI just renders without icons.

## Known gaps

* themes beyond color overrides through `Window.ModifyTheme` aren't done yet

## License

MIT, see LICENSE.
