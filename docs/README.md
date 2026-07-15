# Rayfield Gen2

> A full rebuild of the Rayfield Interface Suite for Roblox. Faster, more stable, and built to last.

![Rayfield Gen2](images/teaser.png)

*Fanmade build of Rayfield Gen2 — not affiliated with Sirius. Original docs at docs.sirius.menu/rayfield-gen2.*

Rayfield Gen2 is a ground-up rebuild of the Rayfield Interface Suite. It builds its entire interface in code, so there is no model to load and nothing to trace. State saves to disk on its own, the whole interface can be themed and translated at runtime, and every element is designed to feel the same on a phone as it does on a desktop.

Create a window, add tabs, and fill them with elements. That is the whole model.

```lua
local Rayfield = loadstring(game:HttpGet("https://raw.githubusercontent.com/SyncUnofficial/Rayfield_Gen_2_fanmade/main/source.lua"))()

local window = Rayfield:CreateWindow({
    name = "Example",
    subtitle = "Rayfield Gen2",
})

local tab = window:CreateTab({ name = "Home", icon = 93364949241311 })

tab:CreateToggle({
    name = "Auto Sprint",
    callback = function(value) print(value) end,
})
```

## Highlights

- **Undetectable by design** — Built entirely in code with no marketplace model. [Secure mode](secure-mode.md) leaves nothing an anti-cheat can fingerprint.
- **Saves itself** — Value elements persist automatically and restore as their original type. No boilerplate. See [Saving](saving.md).
- **Themed at runtime** — Six built-in themes, or bring your own. Swap it live and every colour tweens across. See [Themes](themes.md).
- **Speaks every language** — Translate every label at runtime from a table or your own resolver. See [Localization](localization.md).

## Start here

- **[Getting started](getting-started.md)** — Load the library and build your first window.
- **[Windows](windows.md)** — Every window property and method.
- **[Elements](elements/overview.md)** — Buttons, toggles, sliders, and the rest.
- **[Themes](themes.md)** — Restyle everything to match your script.

## Conventions

Every property is optional unless marked required. Properties are camelCase, and PascalCase spellings work too, so `name` and `Name` both land.

**Icons.** Anywhere an `icon` is accepted, pass an asset id number or an `rbxassetid://`, `rbxthumb://`, or `rbxasset://` string. Pass `nil`, `0`, or `""` for none.

**Flags.** Value elements save on their own under a key derived from their name. Pass an explicit `flag` when you want a stable key of your own. See [Saving](saving.md).

**Reordering.** Every element handle can be moved within its tab with `MoveTo(index)`, `MoveToTop()`, `MoveToBottom()`, `MoveUp()`, and `MoveDown()`.
