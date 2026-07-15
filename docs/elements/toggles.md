# Toggle

> Switch a boolean on and off.

A toggle flips a boolean. `CreateSwitch` is an alias for the same element.

![Toggle elements, one on and one off](../images/window.png)

```lua
local sprint = tab:CreateToggle({
    name = "Auto Sprint",
    flag = "AutoSprint",
    value = true,
    callback = function(value)
        print("Auto Sprint:", value)
    end,
})

sprint:Set(false)
```

## Properties

| Property | Type | Default | Description |
| --- | --- | --- | --- |
| `name` | string | | The label. |
| `description` | string | | Hint text under the label. Optional. |
| `icon` | string \| number | | An icon shown beside the label. Optional. |
| `value` | boolean | `false` | The initial state. |
| `flag` | string | `name` | The save key. Optional. |
| `forgetState` | boolean | `false` | Skip saving. |
| `callback` | function | | Runs with the new value on every change. |

## Handle

| Member | Description |
| --- | --- |
| `.value` | The current state. |
| `Set(value, skipCallback?)` | Set the state. Pass `true` as the second argument to skip the callback. |
