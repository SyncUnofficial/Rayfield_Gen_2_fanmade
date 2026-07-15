# Elements overview

> What every element shares, and how their handles behave.

Elements are the controls inside a tab. Create one from a tab or group, and it returns a handle you can read from and drive later.

![Rayfield Gen2 elements in a window](../images/window.png)

```lua
local toggle = tab:CreateToggle({ name = "Auto Sprint" })
print(toggle.value)  -- read
toggle:Set(true)     -- write
```

## Shared properties

Every element accepts these on top of its own.

| Property | Type | Description |
| --- | --- | --- |
| `name` | string | The label. |
| `description` | string | Hint text under the label. |
| `icon` | string \| number | An icon shown beside the label. |

## Value handles

Every value element (toggle, slider, dropdown, input, keybind, color picker) follows the same shape.

* Read the current value from `.value`.
* Write it with `Set(value)`. This fires the callback, so the change actually takes effect.
* Pass `Set(value, true)` to skip the callback when you only want to move the UI.

```lua
local fov = tab:CreateSlider({ name = "FOV", range = { 70, 120 }, value = 90 })
fov:Set(100)        -- moves the slider and fires the callback
fov:Set(90, true)   -- moves it silently
```

## Flags

Value elements save on their own under a key derived from their name. Pass an explicit `flag` when the name is localized, might be renamed, or could collide with another element. Set `forgetState = true` to skip saving entirely.

```lua
tab:CreateToggle({ name = "Auto Sprint", flag = "AutoSprint" })
```

Read or write any flag through `window.Flags`, `window:Get`, and `window:Set`. See [Saving](../saving.md).

## Reordering

Every element handle can move within its tab.

| Method | Description |
| --- | --- |
| `MoveTo(index)` | |
| `MoveToTop()` | |
| `MoveToBottom()` | |
| `MoveUp()` | |
| `MoveDown()` | |

## The elements

- **[Button](buttons.md)** — Run a function on click.
- **[Toggle](toggles.md)** — Switch a boolean on and off.
- **[Slider](sliders.md)** — Pick a number in a range.
- **[Dropdown](dropdowns.md)** — Choose one option or several.
- **[Input](inputs.md)** — A text field.
- **[Keybind](keybinds.md)** — A rebindable key.
- **[Color picker](color-pickers.md)** — Pick a colour and alpha.
- **[Stat](stats.md)** — A read-only number that rolls on change.
