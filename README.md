# SimpleLib

A small, clean UI library for Roblox — dark, rounded, quietly animated, with [Solar icons](https://solar-icons.vercel.app) resolved at runtime.

```lua
local SimpleLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/USER/SimpleLib/main/SimpleLib.lua"))()
```

> Replace `USER` with your GitHub username after you upload `SimpleLib.lua`.

---

## Quick start

```lua
local SimpleLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/USER/SimpleLib/main/SimpleLib.lua"))()

local Window = SimpleLib:CreateWindow({
    Title = "Grow a Garden 2",
    Icon = "leaf",
    Size = UDim2.fromOffset(560, 400),
    ToggleKey = Enum.KeyCode.RightShift,
    ConfigFolder = "SimpleLib/GrowAGarden",
})

local Tab = Window:CreateTab({ Title = "Autofarms", Icon = "home-smile" })
local Section = Tab:CreateSection("Auto Collect")

Section:Toggle({
    Title = "Auto Collect",
    Flag = "autoCollect",
    Default = false,
    Callback = function(state) print(state) end,
})
```

A complete script is in [`example.lua`](example.lua).

---

## Window

```lua
local Window = SimpleLib:CreateWindow({
    Title        = "SimpleLib",              -- title bar text
    Icon         = "leaf",                   -- optional solar icon
    Size         = UDim2.fromOffset(560, 400),
    Accent       = Color3.fromRGB(240, 240, 240),
    ToggleKey    = Enum.KeyCode.RightShift,  -- show/hide the interface
    ConfigFolder = "SimpleLib/configs",      -- where configs are written
    IconStyle    = "linear",                 -- default icon variant
    GuiName      = "SimpleLib",              -- ScreenGui name
})
```

| Method | Does |
| --- | --- |
| `Window:CreateTab({ Title, Icon })` | Adds a sidebar tab |
| `Window:Toggle(force?)` | Show / hide with the fade + scale animation |
| `Window:Minimize(force?)` | Collapse to the title bar |
| `Window:ToggleSettings(force?)` | Open the built-in settings panel |
| `Window:SaveConfig(name)` / `Window:LoadConfig(name)` | Write / read flags as JSON |
| `Window:Destroy()` | Animate out and unload everything |

The three title-bar buttons are **settings**, **minimize** and **close**. The settings panel is built in: accent color, toggle key rebinding, background blur, and config save/load.

---

## Tabs and sections

```lua
local Tab = Window:CreateTab({ Title = "Main", Icon = "widget" })
local Section = Tab:CreateSection("Auto Collect")   -- grey header, like the screenshot
```

Elements can be created on a section, or straight on a tab (they land in an implicit section):

```lua
Tab:Toggle({ Title = "No clip" })
```

---

## Elements

Every element takes a table and returns a small handle with `:Set(value)`, `:Get()` and `:Destroy()`.
Any element given a `Flag` is registered in `SimpleLib.Flags` and included in configs.

### Toggle
```lua
Section:Toggle({
    Title = "Auto Collect",
    Icon = "leaf",            -- optional
    Default = false,
    Flag = "autoCollect",
    Callback = function(state) end,
})
```

### Button
```lua
Section:Button({ Title = "Collect once", Icon = "hand-money", Callback = function() end })
```

### Slider
```lua
Section:Slider({
    Title = "Collect delay",
    Min = 0, Max = 5, Increment = 0.1, Default = 0.5,
    Suffix = "s",
    Flag = "collectDelay",
    Callback = function(value) end,
})
```

### Dropdown
```lua
Section:Dropdown({
    Title = "Allowed",
    Values = { "Carrot", "Tomato" },
    Multi = true,               -- omit for single select
    Placeholder = "None",
    Default = {},               -- string when Multi is false
    Flag = "allowed",
    Callback = function(value) end,
})
```
`dropdown:Refresh(newValues)` rebuilds the option list in place.

### Input
```lua
Section:Input({
    Title = "Webhook",
    Placeholder = "https://...",
    Default = "",
    Flag = "webhook",
    Callback = function(text) end,
})
```

### Label, Paragraph, Divider
```lua
Section:Label("Status: idle")
Section:Paragraph({ Title = "Heads up", Content = "Longer wrapped text." })
Section:Divider()
```

### Notifications
```lua
SimpleLib:Notify({
    Title = "Collected",
    Content = "Harvested every ready plot.",
    Icon = "check-circle",
    Duration = 4,
})
```

---

## Icons

Icon names come from [solar-icons.vercel.app](https://solar-icons.vercel.app). Roblox cannot draw SVG, so an icon is downloaded once as a white PNG, cached to `SimpleLib/icons/` and loaded with `getcustomasset`. It is tinted in-engine, so one cached file works with every accent color.

```lua
Icon = "home-smile"          -- resolves to solar:home-smile-linear
Icon = "home-smile-bold"     -- explicit variant
Icon = "rbxassetid://123456" -- asset ids pass straight through
```

Variants: `linear` (default), `bold`, `outline`, `broken`, `bold-duotone`, `line-duotone`.

```lua
SimpleLib:SetIconStyle("bold")             -- change the default variant
SimpleLib.Icons.Map["leaf"] = 123456789    -- pin your own uploaded asset ids
```

If the executor has no file functions, or the download fails, the icon slot is simply hidden and the layout stays intact — the title bar falls back to text glyphs.

---

## Configs

```lua
Window:SaveConfig("default")
Window:LoadConfig("default")

SimpleLib.Flags.autoCollect      -- live value of any flagged element
SimpleLib:GetFlag("autoCollect", false)
```

Configs are JSON written to the window's `ConfigFolder`. Loading a config calls each element's `:Set()`, so callbacks fire and the UI animates to the saved state.

---

## Compatibility

Needs an executor with `game:HttpGet`. Icons and configs additionally need `writefile` / `isfile` / `getcustomasset`; without them everything else still works. The GUI is parented through `gethui()` when available, then `CoreGui`, then `PlayerGui`.

---

## Credits

Icons by [Solar](https://solar-icons.vercel.app). Library written for anyone who wants a small UI without a framework attached.

MIT licensed — see [LICENSE](LICENSE).
