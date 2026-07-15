# Tags

> A small pill beside the window title.

A tag is a small pill next to the window title, good for a status or a label. `window:CreateTag(props)` needs at least an icon or some text.

```lua
local tag = window:CreateTag({
    text = "us-en",
    color = Color3.fromRGB(255, 175, 15),
})

tag:Set({ text = "live", color = Color3.fromRGB(80, 200, 120) })
```

## Properties

| Property | Type | Default | Description |
| --- | --- | --- | --- |
| text | string | | The text. `title` also works. |
| icon | string \| number | | An icon. |
| color | Color3 | orange | The background. The text auto-contrasts. |
| order | number | 0 | Sort order among the tags. |

## Handle

| Method | Description |
| --- | --- |
| SetColor(c) | |
| SetText(t) | |
| SetIcon(i) | |
| Set(props) | Update several properties at once. |
| Remove() | |
