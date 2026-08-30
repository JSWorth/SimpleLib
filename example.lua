--[[
    SimpleLib · example
    Recreates the reference layout and shows every element type.
]]

local SimpleLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/JSWorth/SimpleLib/refs/heads/main/SimpleLib.lua"))()

local Window = SimpleLib:CreateWindow({
	Title = "Grow a Garden 2",
	Icon = "leaf",                          -- solar icon name (optional)
	Size = UDim2.fromOffset(560, 400),
	ToggleKey = Enum.KeyCode.RightShift,
	ConfigFolder = "SimpleLib/GrowAGarden",
})

--=============================================================================
-- Autofarms
--=============================================================================

local Autofarms = Window:CreateTab({ Title = "Autofarms", Icon = "home-smile" })

local Collect = Autofarms:CreateSection("Auto Collect")

Collect:Toggle({
	Title = "Auto Collect",
	Flag = "autoCollect",
	Default = false,
	Callback = function(state)
		print("Auto Collect:", state)
	end,
})

Collect:Dropdown({
	Title = "Allowed",
	Multi = true,
	Placeholder = "None",
	Values = { "Carrot", "Strawberry", "Blueberry", "Tomato", "Watermelon", "Pumpkin" },
	Default = {},
	Flag = "allowedCrops",
	Callback = function(values)
		print("Allowed:", table.concat(values, ", "))
	end,
})

Collect:Toggle({
	Title = "Collect Mutated",
	Flag = "collectMutated",
	Default = false,
	Callback = function(state)
		print("Collect Mutated:", state)
	end,
})

local Timing = Autofarms:CreateSection("Timing")

Timing:Slider({
	Title = "Collect delay",
	Min = 0,
	Max = 5,
	Increment = 0.1,
	Default = 0.5,
	Suffix = "s",
	Flag = "collectDelay",
	Callback = function(value)
		print("Delay:", value)
	end,
})

Timing:Button({
	Title = "Collect once",
	Icon = "hand-money",
	Callback = function()
		SimpleLib:Notify({
			Title = "Collected",
			Content = "Harvested every ready plot.",
			Icon = "check-circle",
		})
	end,
})

--=============================================================================
-- Misc
--=============================================================================

local Misc = Window:CreateTab({ Title = "Misc", Icon = "settings-minimalistic" })

Misc:Paragraph({
	Title = "About this example",
	Content = "Every element supports a Flag, which makes it save and load with the config buttons in the settings panel.",
})

Misc:Input({
	Title = "Webhook",
	Placeholder = "https://...",
	Flag = "webhook",
	Callback = function(text)
		print("Webhook set:", text)
	end,
})

Misc:Dropdown({
	Title = "Walk speed preset",
	Values = { "Default", "Fast", "Very fast" },
	Default = "Default",
	Flag = "speedPreset",
	Callback = function(value)
		print("Preset:", value)
	end,
})

Misc:Divider()

Misc:Toggle({
	Title = "Infinite jump",
	Icon = "arrow-up",
	Flag = "infiniteJump",
	Default = false,
	Callback = function(state)
		print("Infinite jump:", state)
	end,
})

Misc:Button({
	Title = "Unload",
	Icon = "logout-2",
	Callback = function()
		Window:Destroy()
	end,
})

--=============================================================================
-- Anything can be read back through flags
--=============================================================================

SimpleLib:Notify({
	Title = "SimpleLib",
	Content = "Loaded. Press Right Shift to hide the window.",
	Icon = "bolt",
	Duration = 5,
})

task.spawn(function()
	while task.wait(1) do
		if SimpleLib:GetFlag("autoCollect", false) then
			-- your farm loop here
		end
	end
end)
