# Dropdown

> Choose one option, or several. Filters as you type.

A dropdown picks one option from a list, or several with `multiSelect`. It filters the list as the player types.

```lua
tab:CreateDropdown({
    name = "Modules",
    multiSelect = true,
    options = { "Aimbot", "ESP", "Fly", "Noclip" },
    value = { "ESP" },
    callback = function(selected)
        print(selected)  -- { "ESP" }
    end,
})
```

## Properties

| Property | Type | Default | Description |
| --- | --- | --- | --- |
| `name` | string | | The label. |
| `description` | string | | Hint text under the label. Optional. |
| `icon` | string \| number | | An icon shown beside the label. Optional. |
| `options` | { string } | `{}` | The choices. |
| `value` | string \| { string } | | The initial selection. A string in single mode, a table in multi. |
| `multiSelect` | boolean | `false` | Allow more than one option at a time. |
| `placeholder` | string | | Shown when nothing is selected. |
| `flag` | string | `name` | The save key. Optional. |
| `forgetState` | boolean | `false` | Skip saving. |
| `callback` | function | | Runs with the selection. A string in single mode, a `{ string }` in multi. |

## Handle

| Member | Description |
| --- | --- |
| `.value` (string \| { string }) | The current selection. |
| `Set(value, skipCallback?)` | Set the selection. |
| `Refresh(options)` | Replace the whole option list. |
| `Add(option)` | Add one option. |
| `Remove(option)` | Remove one option. |
