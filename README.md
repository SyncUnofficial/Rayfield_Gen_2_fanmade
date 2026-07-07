# Rayfield Gen 2 [fanmade]

A fan made reimagining of the Rayfield UI library for Roblox Luau. Gen 2 rebuilds the
interface from scratch with a cleaner look, smoother animations, and a friendlier feel,
while keeping the original Rayfield API so most existing scripts drop in with little or
no change.

> This is an unofficial community project. It is not affiliated with or endorsed by
> Sirius or the original Rayfield authors. Original Rayfield lives at
> [docs.sirius.menu/rayfield](https://docs.sirius.menu/rayfield).

## Loading

```lua
local Rayfield = loadstring(game:HttpGet(
	"https://raw.githubusercontent.com/SyncOfficialSpec/Rayfield_Gen_2_fanmade/main/source.lua"
))()
```

See `example.lua` for a full demo covering every element.

## What Gen 2 adds

* New visual language: dark gradient window with a soft drop shadow, pill tabs
  with icons, dark track toggles with a glowing pill knob, gradient sliders with
  a glowing white knob
* Hide animation that morphs the window into a small "Tap to show" pill at the top
  of the screen, plus minimize to a title bar
* Smooth tween follow dragging, animated tab transitions, and a loading screen
  that expands into the window
* Built in search that filters the elements of the current tab
* Notifications that auto size, wrap, pause on hover, and dismiss on click
* Sign in toast that appears when you play on a different account than last time
* Stat cards with a green gradient for showing values like currency
* Header badge pill, for things like a language or region tag
* Key system with saved keys and keys fetched from a site

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

Every element accepts an optional `Icon` (lucide name or Roblox asset id) and an
optional `Description` shown as muted text under the element.

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

### Stat cards (new in Gen 2)

```lua
local Stat = Tab:CreateStat({
	Name = "Currency",
	Icon = "coins",
	Value = "$21",
	Delta = "+19%",
})
Stat:Set({Value = "$40", Delta = "+90%"})
```

### Rows and columns (new in Gen 2)

Rows place elements side by side with equal widths. Columns split the page into
vertical stacks. Both return the same element API as a tab, in a compact style:
buttons center their content, sliders stack the track under the labels, stat
cards become small pills, and descriptions are skipped.

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

Every element returns an object with a `Set` method, same as original Rayfield:

```lua
local Toggle = Tab:CreateToggle({...})
Toggle:Set(true)

local Dropdown = Tab:CreateDropdown({...})
Dropdown:Set({"Bow"})
Dropdown:Refresh({"Sword", "Bow", "Staff", "Axe"})
```

## Configuration saving

Set a `Flag` on any element and enable `ConfigurationSaving` in the window settings.
Values save automatically when they change. Call this at the end of your script to
restore them:

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

The gear icon in the header opens a built in settings page where the user can rebind
the toggle key, unlock the cursor for FPS games that lock it, or unload the
interface. The dash minimizes to a bar, the X hides to the pill, and the search icon
filters the current tab.

## Icons

Icons use the lucide icon set through the same public icon index the original Rayfield
uses, so lucide names work ("house", "coins", "settings"). The index ships an older
lucide release, so common renamed icons are aliased automatically (for example
"house" resolves to "home" and "chart-no-axes-column" to "bar-chart-3"). Plain Roblox
asset ids work too. The index is cached to your executor's workspace folder after the
first run, so icons keep working offline. If it cannot be fetched at all, the UI
simply renders without icons.

## Known gaps

* Themes beyond color overrides through `Window.ModifyTheme` are not implemented

## License

MIT, see LICENSE.
