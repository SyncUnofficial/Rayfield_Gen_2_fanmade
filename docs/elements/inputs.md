# Input

> A text field that commits when the player is done.

An input is a text field. It commits when the player clicks away or presses enter, not on every keystroke.

![Input, keybind, and color picker elements](../images/fields.png)

```lua
tab:CreateInput({
    name = "Max players",
    numeric = true,
    value = "16",
    placeholder = "Enter a number",
    callback = function(text)
        print("Committed:", text)
    end,
})
```

> [!NOTE]
> Inputs are full-width and live at the tab level. Create them directly on the tab, not inside a group.

## Properties

| Property | Type | Default | Description |
| --- | --- | --- | --- |
| name | string | | The label. |
| description | string | | Hint text under the label. Optional. |
| icon | string \| number | | An icon shown beside the label. Optional. |
| value | string | | The initial text. |
| placeholder | string | | Ghost text shown while the field is empty. |
| numeric | boolean | false | Accept numbers only. Commits a clean number, and clears if the text is malformed. |
| clearOnFocus | boolean | false | Empty the field when it gains focus. |
| flag | string | name | The save key. Optional. |
| forgetState | boolean | false | Skip saving. |
| callback | function | | Runs with the text on commit. |

## Handle

| Member | Description |
| --- | --- |
| .value | The current text. |
| Set(value, skipCallback?) | Set the text. |
