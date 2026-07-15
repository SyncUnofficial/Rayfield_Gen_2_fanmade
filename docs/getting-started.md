# Getting started

> Load Rayfield Gen2 and build your first window in a few lines.

## Load the library

Add one line at the top of your script to pull in Rayfield Gen2.

```lua
local Rayfield = loadstring(game:HttpGet("https://raw.githubusercontent.com/SyncUnofficial/Rayfield_Gen_2_fanmade/main/source.lua"))()
```

## Build a window

A window is the entry point. Create one, add a tab, and fill it with elements.

```lua
local window = Rayfield:CreateWindow({
    name = "Example Hub",
    subtitle = "Rayfield Gen2",
})

local tab = window:CreateTab({ name = "Home", icon = 93364949241311 })

tab:CreateButton({
    name = "Say hello",
    callback = function()
        window:Notify({ title = "Hello", content = "Your first element works." })
    end,
})

tab:CreateToggle({
    name = "Auto Sprint",
    callback = function(value)
        print("Auto Sprint:", value)
    end,
})
```

The first visible tab opens on its own, so there is nothing else to wire up.

## Turn on saving

Pass a `configuration` table and the window remembers every value between sessions. Nothing else is required, and each value restores as its original type.

```lua
local window = Rayfield:CreateWindow({
    name = "Example Hub",
    configuration = {
        autoSave = true,
        autoLoad = true,
        fileName = "ExampleHub",
    },
})
```

- **[How saving works](saving.md)** — Flags, multiple configurations, and reading values back out.

## Next steps

- **[Windows](windows.md)** — Titles, tags, themes, and every window method.
- **[Tabs and groups](tabs.md)** — Organise a tab into sections, columns, and grids.
- **[Elements](elements/overview.md)** — Every control you can drop into a tab.
- **[Secure mode](secure-mode.md)** — Ship a build with nothing to fingerprint.
