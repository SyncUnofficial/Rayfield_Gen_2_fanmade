# Slider

> Pick a number in a range by dragging.

A slider picks a number between a minimum and a maximum. The callback fires as it moves.

![A slider set within its range](../images/window.png)

```lua
tab:CreateSlider({
    name = "Field of view",
    range = { 70, 120 },
    increment = 1,
    value = 90,
    suffix = "°",
    callback = function(value)
        workspace.CurrentCamera.FieldOfView = value
    end,
})
```

## Properties

| Property | Type | Default | Description |
| --- | --- | --- | --- |
| `name` | string | | The label. |
| `description` | string | | Hint text under the label. Optional. |
| `icon` | string \| number | | An icon shown beside the label. Optional. |
| `range` | { number } | | The bounds, as `{ min, max }`. |
| `increment` | number | | The step the slider snaps to. |
| `value` | number | min | The initial value. |
| `suffix` | string | | A unit shown after the number. |
| `minimal` | boolean | false | Show the track only, with no label. For dense rows. |
| `flag` | string | name | The save key. Optional. |
| `forgetState` | boolean | false | Skip saving. |
| `callback` | function | | Runs with the new value as the slider moves. |

## Handle

| Member | Description |
| --- | --- |
| `.value` | The current value. |
| `Set(value, skipCallback?)` | Set the value. Pass `true` as the second argument to skip the callback. |
