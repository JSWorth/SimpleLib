--[[

    SimpleLib  ·  v1.0.0
    A small, clean Roblox UI library with Solar icons and smooth animations.

    local SimpleLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/USER/SimpleLib/main/SimpleLib.lua"))()

    Docs: https://github.com/USER/SimpleLib

]]

local SimpleLib = {}
SimpleLib.__index = SimpleLib
SimpleLib.Version = "1.0.0"
SimpleLib.Flags = {}
SimpleLib.Windows = {}

--=============================================================================
-- Services
--=============================================================================

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

--=============================================================================
-- Theme
--=============================================================================

local Theme = {
	Background   = Color3.fromRGB(16, 16, 16),
	Topbar       = Color3.fromRGB(20, 20, 20),
	Sidebar      = Color3.fromRGB(18, 18, 18),
	Element      = Color3.fromRGB(27, 27, 27),
	ElementHover = Color3.fromRGB(34, 34, 34),
	Stroke       = Color3.fromRGB(42, 42, 42),
	Text         = Color3.fromRGB(238, 238, 238),
	SubText      = Color3.fromRGB(138, 138, 138),
	Accent       = Color3.fromRGB(240, 240, 240),
	Track        = Color3.fromRGB(52, 52, 52),
	Knob         = Color3.fromRGB(250, 250, 250),
}

local FONT = Enum.Font.GothamMedium
local FONT_BOLD = Enum.Font.GothamBold

-- Elements register here so a live accent change repaints them.
local AccentListeners = {}

local function OnAccentChanged(callback)
	table.insert(AccentListeners, callback)
	return callback
end

local ACCENT_PRESETS = {
	{ Name = "White",  Color = Color3.fromRGB(240, 240, 240) },
	{ Name = "Blue",   Color = Color3.fromRGB(86, 148, 255) },
	{ Name = "Green",  Color = Color3.fromRGB(96, 210, 140) },
	{ Name = "Purple", Color = Color3.fromRGB(168, 130, 255) },
	{ Name = "Red",    Color = Color3.fromRGB(255, 106, 106) },
}

--=============================================================================
-- Small helpers
--=============================================================================

local function Create(class, props, children)
	local inst = Instance.new(class)
	for key, value in pairs(props or {}) do
		if key ~= "Parent" then
			inst[key] = value
		end
	end
	for _, child in ipairs(children or {}) do
		child.Parent = inst
	end
	if props and props.Parent then
		inst.Parent = props.Parent
	end
	return inst
end

local function Tween(inst, props, duration, style, direction)
	local info = TweenInfo.new(
		duration or 0.18,
		style or Enum.EasingStyle.Quart,
		direction or Enum.EasingDirection.Out
	)
	local tween = TweenService:Create(inst, info, props)
	tween:Play()
	return tween
end

local function Corner(radius, parent)
	return Create("UICorner", { CornerRadius = UDim.new(0, radius or 8), Parent = parent })
end

local function Stroke(parent, color, transparency, thickness)
	return Create("UIStroke", {
		Color = color or Theme.Stroke,
		Transparency = transparency or 0,
		Thickness = thickness or 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = parent,
	})
end

local function Padding(parent, top, bottom, left, right)
	return Create("UIPadding", {
		PaddingTop = UDim.new(0, top or 0),
		PaddingBottom = UDim.new(0, bottom or 0),
		PaddingLeft = UDim.new(0, left or 0),
		PaddingRight = UDim.new(0, right or 0),
		Parent = parent,
	})
end

local function Luminance(color)
	return (color.R * 0.299) + (color.G * 0.587) + (color.B * 0.114)
end

local function ContrastOn(color)
	if Luminance(color) > 0.6 then
		return Color3.fromRGB(18, 18, 18)
	end
	return Color3.fromRGB(250, 250, 250)
end

local function Round(value, increment)
	if not increment or increment <= 0 then
		return value
	end
	return math.floor((value / increment) + 0.5) * increment
end

--=============================================================================
-- Executor compatibility
--=============================================================================

local Env = {}

Env.HttpGet = function(url)
	local ok, body = pcall(function()
		return game:HttpGet(url, true)
	end)
	if ok and type(body) == "string" and #body > 0 then
		return body
	end
	return nil
end

Env.WriteFile = (typeof(writefile) == "function") and writefile or nil
Env.ReadFile = (typeof(readfile) == "function") and readfile or nil
Env.IsFile = (typeof(isfile) == "function") and isfile or nil
Env.IsFolder = (typeof(isfolder) == "function") and isfolder or nil
Env.MakeFolder = (typeof(makefolder) == "function") and makefolder or nil
Env.ListFiles = (typeof(listfiles) == "function") and listfiles or nil
Env.CustomAsset = (typeof(getcustomasset) == "function") and getcustomasset
	or ((typeof(getsynasset) == "function") and getsynasset)
	or nil

Env.HasFiles = (Env.WriteFile ~= nil) and (Env.IsFile ~= nil) and (Env.CustomAsset ~= nil)

function Env.EnsureFolder(path)
	if not Env.MakeFolder or not Env.IsFolder then
		return false
	end
	local parts = string.split(path, "/")
	local built = ""
	for index, part in ipairs(parts) do
		if part ~= "" then
			if index == 1 then
				built = part
			else
				built = built .. "/" .. part
			end
			local ok, exists = pcall(Env.IsFolder, built)
			if ok and not exists then
				pcall(Env.MakeFolder, built)
			end
		end
	end
	return true
end

function Env.GuiParent()
	local ok, hidden = pcall(function()
		return gethui()
	end)
	if ok and typeof(hidden) == "Instance" then
		return hidden
	end
	local ok2, core = pcall(function()
		return game:GetService("CoreGui")
	end)
	if ok2 and core and not RunService:IsStudio() then
		return core
	end
	return LocalPlayer:WaitForChild("PlayerGui")
end

function Env.Protect(gui)
	pcall(function()
		if syn and syn.protect_gui then
			syn.protect_gui(gui)
		elseif protectgui then
			protectgui(gui)
		end
	end)
end

--=============================================================================
-- Solar icons  (https://solar-icons.vercel.app)
--
-- Roblox cannot render SVG, so an icon is fetched once as a white PNG,
-- written to disk and loaded through getcustomasset. Every icon is tinted
-- afterwards with ImageColor3, so one cached file serves every theme.
--=============================================================================

local Icons = {}
Icons.Style = "linear" -- linear | bold | outline | broken | bold-duotone | line-duotone
Icons.Folder = "SimpleLib/icons"
Icons.Cache = {}
Icons.Failed = {}
Icons.Map = {} -- optional: ["home-smile"] = "rbxassetid://123456789"

Icons.Styles = {
	["linear"] = true,
	["bold"] = true,
	["outline"] = true,
	["broken"] = true,
	["bold-duotone"] = true,
	["line-duotone"] = true,
	["duotone"] = true,
}

Icons.Endpoints = {
	"https://images.weserv.nl/?url=%s&w=160&h=160&output=png",
	"https://wsrv.nl/?url=%s&w=160&h=160&output=png",
}

local function UrlEncode(str)
	str = string.gsub(str, "([^%w%-%_%.%~])", function(char)
		return string.format("%%%02X", string.byte(char))
	end)
	return str
end

-- "HomeSmile", "home smile", "home_smile" -> "home-smile"
function Icons.Normalize(name)
	name = tostring(name)
	name = string.gsub(name, "^solar[:/]", "")
	name = string.gsub(name, "(%l)(%u)", "%1-%2")
	name = string.gsub(name, "[%s_]+", "-")
	name = string.lower(name)
	name = string.gsub(name, "%-+", "-")
	name = string.gsub(name, "^%-", "")
	name = string.gsub(name, "%-$", "")

	local hasStyle = false
	for style in pairs(Icons.Styles) do
		if string.sub(name, -(#style + 1)) == ("-" .. style) then
			hasStyle = true
			break
		end
	end
	if not hasStyle then
		name = name .. "-" .. Icons.Style
	end
	return name
end

local function IsPng(data)
	return type(data) == "string" and #data > 8 and string.byte(data, 1) == 137 and string.sub(data, 2, 4) == "PNG"
end

function Icons.Download(name)
	if not Env.HasFiles then
		return nil
	end

	Env.EnsureFolder(Icons.Folder)
	local path = Icons.Folder .. "/" .. name .. ".png"

	local exists = false
	pcall(function()
		exists = Env.IsFile(path)
	end)

	if not exists then
		local svg = "api.iconify.design/solar/" .. name .. ".svg?color=%23ffffff&width=160&height=160"
		local data
		for _, endpoint in ipairs(Icons.Endpoints) do
			local url = string.format(endpoint, UrlEncode(svg))
			local body = Env.HttpGet(url)
			if IsPng(body) then
				data = body
				break
			end
		end
		if not data then
			return nil
		end
		local ok = pcall(Env.WriteFile, path, data)
		if not ok then
			return nil
		end
	end

	local ok, asset = pcall(Env.CustomAsset, path)
	if ok and type(asset) == "string" then
		return asset
	end
	return nil
end

-- Returns an image id string, or nil when the icon cannot be resolved.
function Icons.Get(name)
	if name == nil or name == "" then
		return nil
	end
	if type(name) == "number" then
		return "rbxassetid://" .. tostring(name)
	end
	if string.match(name, "^rbxassetid://") or string.match(name, "^rbxasset://") or string.match(name, "^http") then
		return name
	end

	local key = Icons.Normalize(name)
	if Icons.Cache[key] then
		return Icons.Cache[key]
	end
	if Icons.Failed[key] then
		return nil
	end

	local mapped = Icons.Map[key] or Icons.Map[name]
	if mapped then
		if type(mapped) == "number" then
			mapped = "rbxassetid://" .. tostring(mapped)
		end
		Icons.Cache[key] = mapped
		return mapped
	end

	local asset = Icons.Download(key)
	if asset then
		Icons.Cache[key] = asset
		return asset
	end

	Icons.Failed[key] = true
	return nil
end

-- Fills an ImageLabel asynchronously so the UI never blocks on a download.
-- `fallback` is an optional TextLabel shown when the icon cannot be resolved.
local function ApplyIcon(image, name, color, fallback)
	local function showFallback()
		image.Visible = false
		if fallback then
			fallback.Visible = true
			fallback.TextTransparency = 1
			Tween(fallback, { TextTransparency = 0 }, 0.2)
		end
	end

	if not name or name == "" then
		showFallback()
		return
	end

	image.ImageTransparency = 1
	image.Visible = true
	if fallback then
		fallback.Visible = false
	end

	task.spawn(function()
		local asset = Icons.Get(name)
		if not asset then
			showFallback()
			return
		end
		image.Image = asset
		image.ImageColor3 = color or Theme.Text
		Tween(image, { ImageTransparency = 0 }, 0.25)
	end)
end

SimpleLib.Icons = Icons

--=============================================================================
-- Notifications
--=============================================================================

local Notifications = {}

function Notifications.Init()
	if Notifications.Gui and Notifications.Gui.Parent then
		return
	end

	local gui = Create("ScreenGui", {
		Name = "SimpleLibNotifications",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 1000,
	})
	Env.Protect(gui)
	gui.Parent = Env.GuiParent()

	local holder = Create("Frame", {
		Name = "Holder",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -18, 1, -18),
		Size = UDim2.new(0, 290, 1, -36),
		BackgroundTransparency = 1,
		Parent = gui,
	}, {
		Create("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Bottom,
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
			Padding = UDim.new(0, 8),
		}),
	})

	Notifications.Gui = gui
	Notifications.Holder = holder
end

function Notifications.Push(options)
	options = options or {}
	Notifications.Init()

	local title = tostring(options.Title or "Notification")
	local content = tostring(options.Content or options.Text or "")
	local duration = tonumber(options.Duration) or 4
	local accent = options.Color or Theme.Accent

	-- The slot is laid out by the list layout; the card inside it is animated.
	local slot = Create("Frame", {
		Name = "Slot",
		Size = UDim2.new(1, 0, 0, content ~= "" and 68 or 46),
		BackgroundTransparency = 1,
		Parent = Notifications.Holder,
	})

	local card = Create("CanvasGroup", {
		Name = "Toast",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Theme.Element,
		BorderSizePixel = 0,
		GroupTransparency = 1,
		Position = UDim2.new(1, 40, 0, 0),
		Parent = slot,
	})
	Corner(10, card)
	Stroke(card, Theme.Stroke, 0.25)

	local icon = Create("ImageLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 14, 0, 15),
		Size = UDim2.fromOffset(16, 16),
		ScaleType = Enum.ScaleType.Fit,
		Image = "",
		Parent = card,
	})
	ApplyIcon(icon, options.Icon or "bell", accent)

	Create("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 40, 0, 12),
		Size = UDim2.new(1, -54, 0, 18),
		Font = FONT_BOLD,
		Text = title,
		TextSize = 13,
		TextColor3 = Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = card,
	})

	if content ~= "" then
		Create("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 40, 0, 30),
			Size = UDim2.new(1, -54, 0, 30),
			Font = FONT,
			Text = content,
			TextSize = 12,
			TextColor3 = Theme.SubText,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			TextWrapped = true,
			Parent = card,
		})
	end

	local bar = Create("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, 0),
		Size = UDim2.new(1, 0, 0, 2),
		BackgroundColor3 = accent,
		BorderSizePixel = 0,
		Parent = card,
	})

	Tween(card, { Position = UDim2.new(0, 0, 0, 0), GroupTransparency = 0 }, 0.32, Enum.EasingStyle.Quint)
	Tween(bar, { Size = UDim2.new(0, 0, 0, 2) }, duration, Enum.EasingStyle.Linear)

	task.delay(duration, function()
		if not slot.Parent then
			return
		end
		Tween(card, { Position = UDim2.new(1, 40, 0, 0), GroupTransparency = 1 }, 0.28, Enum.EasingStyle.Quint)
		Tween(slot, { Size = UDim2.new(1, 0, 0, 0) }, 0.32, Enum.EasingStyle.Quint)
		task.wait(0.34)
		slot:Destroy()
	end)
end

function SimpleLib:Notify(options)
	Notifications.Push(options)
end

--=============================================================================
-- Element primitives
--=============================================================================

local Element = {}

-- Base card every element is built on top of.
function Element.Card(parent, height, interactive)
	local card = Create("Frame", {
		Name = "Element",
		Size = UDim2.new(1, 0, 0, height or 44),
		BackgroundColor3 = Theme.Element,
		BorderSizePixel = 0,
		ClipsDescendants = false,
		Parent = parent,
	})
	Corner(8, card)
	local stroke = Stroke(card, Theme.Stroke, 0.35)

	if interactive then
		card.MouseEnter:Connect(function()
			Tween(card, { BackgroundColor3 = Theme.ElementHover }, 0.15)
			Tween(stroke, { Transparency = 0.1 }, 0.15)
		end)
		card.MouseLeave:Connect(function()
			Tween(card, { BackgroundColor3 = Theme.Element }, 0.2)
			Tween(stroke, { Transparency = 0.35 }, 0.2)
		end)
	end

	return card, stroke
end

function Element.Title(card, text, hasIcon)
	return Create("TextLabel", {
		Name = "Title",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, hasIcon and 40 or 14, 0, 0),
		Size = UDim2.new(1, hasIcon and -110 or -84, 1, 0),
		Font = FONT,
		Text = text,
		TextSize = 13,
		TextColor3 = Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = card,
	})
end

function Element.LeftIcon(card, icon)
	if not icon then
		return nil
	end
	local image = Create("ImageLabel", {
		Name = "Icon",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 14, 0.5, 0),
		Size = UDim2.fromOffset(16, 16),
		ScaleType = Enum.ScaleType.Fit,
		Image = "",
		Parent = card,
	})
	ApplyIcon(image, icon, Theme.SubText)
	return image
end

-- Invisible button covering a card, with a soft press animation.
function Element.Hitbox(card, onClick)
	local button = Create("TextButton", {
		Name = "Hitbox",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Text = "",
		AutoButtonColor = false,
		Parent = card,
	})
	button.MouseButton1Click:Connect(function()
		local scale = card:FindFirstChildOfClass("UIScale") or Create("UIScale", { Parent = card })
		scale.Scale = 0.985
		Tween(scale, { Scale = 1 }, 0.25, Enum.EasingStyle.Back)
		if onClick then
			task.spawn(onClick)
		end
	end)
	return button
end

--=============================================================================
-- Section  (holds elements, exposes the element constructors)
--=============================================================================

local Section = {}
Section.__index = Section

local function NewSection(window, page, title)
	local self = setmetatable({}, Section)
	self.Window = window
	self.Page = page

	self.Holder = Create("Frame", {
		Name = "Section",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = page.List,
	}, {
		Create("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 6),
		}),
	})

	if title and title ~= "" then
		self.TitleLabel = Create("TextLabel", {
			Name = "SectionTitle",
			Size = UDim2.new(1, 0, 0, 22),
			BackgroundTransparency = 1,
			Font = FONT,
			Text = title,
			TextSize = 12,
			TextColor3 = Theme.SubText,
			TextXAlignment = Enum.TextXAlignment.Left,
			LayoutOrder = -1,
			Parent = self.Holder,
		}, {
			Create("UIPadding", { PaddingLeft = UDim.new(0, 2) }),
		})
	end

	return self
end

function Section:SetTitle(text)
	if self.TitleLabel then
		self.TitleLabel.Text = text
	end
end

function Section:Destroy()
	self.Holder:Destroy()
end

--------------------------------------------------------------------- Label ---

function Section:Label(text)
	local card = Element.Card(self.Holder, 34, false)
	local label = Create("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 14, 0, 0),
		Size = UDim2.new(1, -28, 1, 0),
		Font = FONT,
		Text = tostring(text),
		TextSize = 13,
		TextColor3 = Theme.SubText,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = card,
	})

	local api = {}
	function api:Set(value)
		label.Text = tostring(value)
	end
	function api:Destroy()
		card:Destroy()
	end
	return api
end

----------------------------------------------------------------- Paragraph ---

function Section:Paragraph(options)
	options = options or {}
	local card = Element.Card(self.Holder, 0, false)
	card.AutomaticSize = Enum.AutomaticSize.Y
	Padding(card, 12, 12, 14, 14)
	Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4), Parent = card })

	local title = Create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 16),
		Font = FONT_BOLD,
		Text = tostring(options.Title or "Paragraph"),
		TextSize = 13,
		TextColor3 = Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = card,
	})

	local body = Create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Font = FONT,
		Text = tostring(options.Content or ""),
		TextSize = 12,
		TextColor3 = Theme.SubText,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		Parent = card,
	})

	local api = {}
	function api:Set(newTitle, newContent)
		if newTitle then title.Text = tostring(newTitle) end
		if newContent then body.Text = tostring(newContent) end
	end
	function api:Destroy()
		card:Destroy()
	end
	return api
end

-------------------------------------------------------------------- Button ---

function Section:Button(options)
	options = options or {}
	local card = Element.Card(self.Holder, 44, true)
	local icon = Element.LeftIcon(card, options.Icon)
	local title = Element.Title(card, tostring(options.Title or "Button"), icon ~= nil)

	local arrow = Create("ImageLabel", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0.5, 0),
		Size = UDim2.fromOffset(14, 14),
		ScaleType = Enum.ScaleType.Fit,
		Image = "",
		Parent = card,
	})
	ApplyIcon(arrow, "alt-arrow-right-linear", Theme.SubText)

	Element.Hitbox(card, function()
		if options.Callback then
			local ok, err = pcall(options.Callback)
			if not ok then
				warn("[SimpleLib] Button callback error:", err)
			end
		end
	end)

	local api = {}
	function api:SetTitle(text)
		title.Text = tostring(text)
	end
	function api:Destroy()
		card:Destroy()
	end
	return api
end

-------------------------------------------------------------------- Toggle ---

function Section:Toggle(options)
	options = options or {}
	local card = Element.Card(self.Holder, 44, true)
	local icon = Element.LeftIcon(card, options.Icon)
	local title = Element.Title(card, tostring(options.Title or "Toggle"), icon ~= nil)

	local state = options.Default == true

	local track = Create("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0.5, 0),
		Size = UDim2.fromOffset(40, 22),
		BackgroundColor3 = Theme.Track,
		BorderSizePixel = 0,
		Parent = card,
	})
	Corner(11, track)

	local knob = Create("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 3, 0.5, 0),
		Size = UDim2.fromOffset(16, 16),
		BackgroundColor3 = Theme.Knob,
		BorderSizePixel = 0,
		Parent = track,
	})
	Corner(8, knob)

	local api = {}

	local function render(animate)
		local duration = animate and 0.22 or 0
		local trackColor = state and Theme.Accent or Theme.Track
		local knobColor = state and ContrastOn(Theme.Accent) or Theme.Knob
		Tween(track, { BackgroundColor3 = trackColor }, duration)
		Tween(knob, {
			Position = UDim2.new(0, state and 21 or 3, 0.5, 0),
			BackgroundColor3 = knobColor,
		}, duration, Enum.EasingStyle.Quint)
	end

	function api:Set(value, silent)
		state = value == true
		render(true)
		if options.Flag then
			SimpleLib.Flags[options.Flag] = state
		end
		if not silent and options.Callback then
			local ok, err = pcall(options.Callback, state)
			if not ok then
				warn("[SimpleLib] Toggle callback error:", err)
			end
		end
	end

	function api:Get()
		return state
	end

	function api:SetTitle(text)
		title.Text = tostring(text)
	end

	function api:Destroy()
		card:Destroy()
	end

	Element.Hitbox(card, function()
		api:Set(not state)
	end)

	OnAccentChanged(function()
		if card.Parent and state then
			render(true)
		end
	end)

	render(false)
	if options.Flag then
		SimpleLib.Flags[options.Flag] = state
		self.Window.Registry[options.Flag] = api
	end
	if state and options.Callback then
		task.spawn(options.Callback, state)
	end

	return api
end

-------------------------------------------------------------------- Slider ---

function Section:Slider(options)
	options = options or {}
	local min = tonumber(options.Min) or 0
	local max = tonumber(options.Max) or 100
	local increment = tonumber(options.Increment) or 1
	local suffix = options.Suffix or ""
	local value = math.clamp(tonumber(options.Default) or min, min, max)

	local card = Element.Card(self.Holder, 58, true)
	local title = Create("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 14, 0, 10),
		Size = UDim2.new(1, -100, 0, 16),
		Font = FONT,
		Text = tostring(options.Title or "Slider"),
		TextSize = 13,
		TextColor3 = Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = card,
	})

	local valueLabel = Create("TextLabel", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -14, 0, 10),
		Size = UDim2.new(0, 80, 0, 16),
		Font = FONT,
		Text = tostring(value) .. suffix,
		TextSize = 12,
		TextColor3 = Theme.SubText,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = card,
	})

	local track = Create("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 14, 1, -16),
		Size = UDim2.new(1, -28, 0, 4),
		BackgroundColor3 = Theme.Track,
		BorderSizePixel = 0,
		Parent = card,
	})
	Corner(2, track)

	local fill = Create("Frame", {
		Size = UDim2.fromScale((value - min) / math.max(max - min, 1), 1),
		BackgroundColor3 = Theme.Accent,
		BorderSizePixel = 0,
		Parent = track,
	})
	Corner(2, fill)

	local knob = Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new((value - min) / math.max(max - min, 1), 0, 0.5, 0),
		Size = UDim2.fromOffset(12, 12),
		BackgroundColor3 = Theme.Knob,
		BorderSizePixel = 0,
		ZIndex = 3,
		Parent = track,
	})
	Corner(6, knob)

	local api = {}
	local dragging = false

	local function render(animate)
		local alpha = (value - min) / math.max(max - min, 1)
		local duration = animate and 0.12 or 0
		Tween(fill, { Size = UDim2.fromScale(alpha, 1) }, duration)
		Tween(knob, { Position = UDim2.new(alpha, 0, 0.5, 0) }, duration)
		valueLabel.Text = tostring(value) .. suffix
	end

	function api:Set(newValue, silent)
		local rounded = math.clamp(Round(tonumber(newValue) or min, increment), min, max)
		rounded = tonumber(string.format("%.4f", rounded))
		value = rounded
		render(true)
		if options.Flag then
			SimpleLib.Flags[options.Flag] = value
		end
		if not silent and options.Callback then
			local ok, err = pcall(options.Callback, value)
			if not ok then
				warn("[SimpleLib] Slider callback error:", err)
			end
		end
	end

	function api:Get()
		return value
	end

	function api:Destroy()
		card:Destroy()
	end

	local function updateFromInput(input)
		local alpha = math.clamp((input.Position.X - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
		api:Set(min + (max - min) * alpha)
	end

	local hitbox = Create("TextButton", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, -10),
		Size = UDim2.new(1, 0, 0, 24),
		Text = "",
		AutoButtonColor = false,
		Parent = track,
	})

	hitbox.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			Tween(knob, { Size = UDim2.fromOffset(16, 16) }, 0.15, Enum.EasingStyle.Back)
			updateFromInput(input)
		end
	end)

	-- Service-level connections need explicit cleanup when the card goes away.
	local moved = UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			updateFromInput(input)
		end
	end)

	local released = UserInputService.InputEnded:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
			dragging = false
			Tween(knob, { Size = UDim2.fromOffset(12, 12) }, 0.2)
		end
	end)

	card.AncestryChanged:Connect(function(_, parent)
		if not parent then
			moved:Disconnect()
			released:Disconnect()
		end
	end)

	if self.Window and self.Window.Connections then
		table.insert(self.Window.Connections, moved)
		table.insert(self.Window.Connections, released)
	end

	OnAccentChanged(function(color)
		if card.Parent then
			Tween(fill, { BackgroundColor3 = color }, 0.2)
		end
	end)

	render(false)
	if options.Flag then
		SimpleLib.Flags[options.Flag] = value
		self.Window.Registry[options.Flag] = api
	end

	return api
end

--------------------------------------------------------------------- Input ---

function Section:Input(options)
	options = options or {}
	local card = Element.Card(self.Holder, 44, true)
	local icon = Element.LeftIcon(card, options.Icon)
	local title = Element.Title(card, tostring(options.Title or "Input"), icon ~= nil)
	title.Size = UDim2.new(1, icon and -200 or -180, 1, 0)

	local box = Create("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.fromOffset(options.Width or 140, 28),
		BackgroundColor3 = Theme.Background,
		BorderSizePixel = 0,
		Parent = card,
	})
	Corner(6, box)
	local boxStroke = Stroke(box, Theme.Stroke, 0.3)

	local input = Create("TextBox", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -16, 1, 0),
		Position = UDim2.new(0, 8, 0, 0),
		Font = FONT,
		Text = tostring(options.Default or ""),
		PlaceholderText = tostring(options.Placeholder or "..."),
		PlaceholderColor3 = Theme.SubText,
		TextSize = 12,
		TextColor3 = Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
		Parent = box,
	})

	input.Focused:Connect(function()
		Tween(boxStroke, { Color = Theme.Accent, Transparency = 0 }, 0.15)
	end)

	input.FocusLost:Connect(function(enter)
		Tween(boxStroke, { Color = Theme.Stroke, Transparency = 0.3 }, 0.2)
		if options.Flag then
			SimpleLib.Flags[options.Flag] = input.Text
		end
		if options.Callback and (enter or not options.OnEnter) then
			local ok, err = pcall(options.Callback, input.Text)
			if not ok then
				warn("[SimpleLib] Input callback error:", err)
			end
		end
	end)

	local api = {}
	function api:Set(text, silent)
		input.Text = tostring(text)
		if options.Flag then
			SimpleLib.Flags[options.Flag] = input.Text
		end
		if not silent and options.Callback then
			pcall(options.Callback, input.Text)
		end
	end
	function api:Get()
		return input.Text
	end
	function api:Destroy()
		card:Destroy()
	end

	if options.Flag then
		SimpleLib.Flags[options.Flag] = input.Text
		self.Window.Registry[options.Flag] = api
	end

	return api
end

------------------------------------------------------------------ Dropdown ---

function Section:Dropdown(options)
	options = options or {}
	local values = options.Values or options.Options or {}
	local multi = options.Multi == true
	local placeholder = tostring(options.Placeholder or "None")

	local selected = {}
	if multi then
		for _, item in ipairs(options.Default or {}) do
			selected[tostring(item)] = true
		end
	elseif options.Default ~= nil and options.Default ~= "" then
		selected[tostring(options.Default)] = true
	end

	local holder = Create("Frame", {
		Name = "Dropdown",
		Size = UDim2.new(1, 0, 0, 44),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Parent = self.Holder,
	})

	local card = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 44),
		BackgroundColor3 = Theme.Element,
		BorderSizePixel = 0,
		Parent = holder,
	})
	Corner(8, card)
	local cardStroke = Stroke(card, Theme.Stroke, 0.35)

	card.MouseEnter:Connect(function()
		Tween(card, { BackgroundColor3 = Theme.ElementHover }, 0.15)
	end)
	card.MouseLeave:Connect(function()
		Tween(card, { BackgroundColor3 = Theme.Element }, 0.2)
	end)

	local icon = Element.LeftIcon(card, options.Icon)
	local title = Element.Title(card, tostring(options.Title or "Dropdown"), icon ~= nil)
	title.Size = UDim2.new(0.5, 0, 1, 0)

	local valueLabel = Create("TextLabel", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -34, 0.5, 0),
		Size = UDim2.new(0.5, -40, 1, 0),
		Font = FONT,
		Text = placeholder,
		TextSize = 12,
		TextColor3 = Theme.SubText,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = card,
	})

	local chevron = Create("ImageLabel", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0.5, 0),
		Size = UDim2.fromOffset(14, 14),
		ScaleType = Enum.ScaleType.Fit,
		Image = "",
		Parent = card,
	})
	ApplyIcon(chevron, "alt-arrow-down-linear", Theme.SubText)

	local list = Create("ScrollingFrame", {
		Position = UDim2.new(0, 0, 0, 50),
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundColor3 = Theme.Element,
		BorderSizePixel = 0,
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = Theme.Stroke,
		CanvasSize = UDim2.new(),
		Parent = holder,
	})
	Corner(8, list)
	Stroke(list, Theme.Stroke, 0.35)
	Padding(list, 6, 6, 6, 6)

	local layout = Create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 4),
		Parent = list,
	})

	local open = false
	local rows = {}
	local api = {}

	local function summary()
		local picked = {}
		for _, item in ipairs(values) do
			if selected[tostring(item)] then
				table.insert(picked, tostring(item))
			end
		end
		if #picked == 0 then
			return placeholder
		end
		if multi and #picked > 2 then
			return picked[1] .. ", +" .. tostring(#picked - 1)
		end
		return table.concat(picked, ", ")
	end

	local function refresh()
		valueLabel.Text = summary()
		for value, row in pairs(rows) do
			local isOn = selected[value] == true
			Tween(row.Frame, { BackgroundTransparency = isOn and 0 or 1 }, 0.15)
			Tween(row.Label, { TextColor3 = isOn and Theme.Text or Theme.SubText }, 0.15)
			Tween(row.Check, { ImageTransparency = isOn and 0 or 1 }, 0.15)
		end
	end

	local function listHeight()
		return math.min(layout.AbsoluteContentSize.Y + 12, 156)
	end

	local function setOpen(shouldOpen)
		open = shouldOpen
		local height = listHeight()
		list.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 12)
		Tween(holder, { Size = UDim2.new(1, 0, 0, open and (50 + height) or 44) }, 0.28, Enum.EasingStyle.Quint)
		Tween(list, { Size = UDim2.new(1, 0, 0, open and height or 0) }, 0.28, Enum.EasingStyle.Quint)
		Tween(chevron, { Rotation = open and 180 or 0 }, 0.28, Enum.EasingStyle.Quint)
		Tween(cardStroke, { Transparency = open and 0.1 or 0.35 }, 0.2)
	end

	function api:Refresh(newValues)
		values = newValues or values
		for _, row in pairs(rows) do
			row.Frame:Destroy()
		end
		rows = {}

		for index, item in ipairs(values) do
			local value = tostring(item)
			local row = Create("TextButton", {
				Size = UDim2.new(1, 0, 0, 30),
				BackgroundColor3 = Theme.ElementHover,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				AutoButtonColor = false,
				Text = "",
				LayoutOrder = index,
				Parent = list,
			})
			Corner(6, row)

			local label = Create("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 10, 0, 0),
				Size = UDim2.new(1, -40, 1, 0),
				Font = FONT,
				Text = value,
				TextSize = 12,
				TextColor3 = Theme.SubText,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Parent = row,
			})

			local check = Create("ImageLabel", {
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -10, 0.5, 0),
				Size = UDim2.fromOffset(13, 13),
				ScaleType = Enum.ScaleType.Fit,
				ImageTransparency = 1,
				Image = "",
				Parent = row,
			})
			ApplyIcon(check, "check-circle-linear", Theme.Accent)

			row.MouseEnter:Connect(function()
				if not selected[value] then
					Tween(row, { BackgroundTransparency = 0.6 }, 0.12)
				end
			end)
			row.MouseLeave:Connect(function()
				if not selected[value] then
					Tween(row, { BackgroundTransparency = 1 }, 0.15)
				end
			end)

			row.MouseButton1Click:Connect(function()
				if multi then
					selected[value] = not selected[value] or nil
				else
					selected = {}
					selected[value] = true
					setOpen(false)
				end
				refresh()
				api:_fire()
			end)

			rows[value] = { Frame = row, Label = label, Check = check }
		end

		refresh()
		if open then
			setOpen(true)
		end
	end

	function api:Get()
		if multi then
			local picked = {}
			for _, item in ipairs(values) do
				if selected[tostring(item)] then
					table.insert(picked, tostring(item))
				end
			end
			return picked
		end
		for value in pairs(selected) do
			return value
		end
		return nil
	end

	function api:_fire(silent)
		local value = api:Get()
		if options.Flag then
			SimpleLib.Flags[options.Flag] = value
		end
		if not silent and options.Callback then
			local ok, err = pcall(options.Callback, value)
			if not ok then
				warn("[SimpleLib] Dropdown callback error:", err)
			end
		end
	end

	function api:Set(value, silent)
		selected = {}
		if multi and type(value) == "table" then
			for _, item in ipairs(value) do
				selected[tostring(item)] = true
			end
		elseif value ~= nil then
			selected[tostring(value)] = true
		end
		refresh()
		api:_fire(silent)
	end

	function api:Destroy()
		holder:Destroy()
	end

	Element.Hitbox(card, function()
		setOpen(not open)
	end)

	api:Refresh(values)
	if options.Flag then
		SimpleLib.Flags[options.Flag] = api:Get()
		self.Window.Registry[options.Flag] = api
	end

	return api
end

-------------------------------------------------------------------- Keybind --

function Section:Divider()
	local line = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = Theme.Stroke,
		BackgroundTransparency = 0.4,
		BorderSizePixel = 0,
		Parent = self.Holder,
	})
	local api = {}
	function api:Destroy()
		line:Destroy()
	end
	return api
end

--=============================================================================
-- Tab
--=============================================================================

local Tab = {}
Tab.__index = Tab

function Tab:CreateSection(title)
	return NewSection(self.Window, self.Page, title)
end

Tab.Section = Tab.CreateSection

-- Elements called straight on a tab land in an implicit section.
local function ForwardToDefaultSection(methodName)
	Tab[methodName] = function(self, ...)
		if not self.Default then
			self.Default = NewSection(self.Window, self.Page, nil)
		end
		return Section[methodName](self.Default, ...)
	end
end

for _, methodName in ipairs({ "Label", "Paragraph", "Button", "Toggle", "Slider", "Input", "Dropdown", "Divider" }) do
	ForwardToDefaultSection(methodName)
end

function Tab:Select()
	self.Window:SelectTab(self)
end

function Tab:Destroy()
	local window = self.Window
	self.Node:Destroy()
	self.Page.Frame:Destroy()

	for index, tab in ipairs(window.Tabs) do
		if tab == self then
			table.remove(window.Tabs, index)
			break
		end
	end

	-- Keep the remaining rows numbered so the sliding highlight stays aligned.
	for index, tab in ipairs(window.Tabs) do
		tab.Index = index
		tab.Node.LayoutOrder = index
	end

	if window.ActiveTab == self then
		window.ActiveTab = nil
		if window.Tabs[1] then
			window:SelectTab(window.Tabs[1])
		else
			window.Highlight.Visible = false
		end
	elseif window.ActiveTab then
		window.Highlight.Position = UDim2.new(0, 10, 0, 12 + ((window.ActiveTab.Index - 1) * 38))
	end
end

--=============================================================================
-- Window
--=============================================================================

local Window = {}
Window.__index = Window

function Window:SelectTab(tab)
	if self.ActiveTab == tab then
		return
	end

	local previous = self.ActiveTab
	self.ActiveTab = tab

	for _, other in ipairs(self.Tabs) do
		local isActive = other == tab
		Tween(other.TitleLabel, { TextColor3 = isActive and Theme.Text or Theme.SubText }, 0.2)
		Tween(other.Icon, { ImageColor3 = isActive and Theme.Accent or Theme.SubText }, 0.2)
	end

	-- Tab rows are a fixed 34px tall with 4px spacing, so the sliding
	-- highlight can be placed without waiting on AbsolutePosition.
	local targetY = 12 + ((tab.Index - 1) * 38)
	if not self.Highlight.Visible then
		self.Highlight.Position = UDim2.new(0, 10, 0, targetY)
		self.Highlight.Visible = true
		self.Highlight.BackgroundTransparency = 1
		Tween(self.Highlight, { BackgroundTransparency = 0 }, 0.25)
	else
		Tween(self.Highlight, { Position = UDim2.new(0, 10, 0, targetY) }, 0.32, Enum.EasingStyle.Quint)
	end

	if previous then
		local old = previous.Page.Frame
		Tween(old, { GroupTransparency = 1, Position = UDim2.new(0, 0, 0, -8) }, 0.14)
		task.delay(0.15, function()
			if self.ActiveTab ~= previous then
				old.Visible = false
			end
		end)
	end

	local page = tab.Page.Frame
	page.Visible = true
	page.GroupTransparency = 1
	page.Position = UDim2.new(0, 0, 0, 10)
	Tween(page, { GroupTransparency = 0, Position = UDim2.new(0, 0, 0, 0) }, 0.3, Enum.EasingStyle.Quint)
end

function Window:CreateTab(options)
	if type(options) == "string" then
		options = { Title = options }
	end
	options = options or {}

	local tab = setmetatable({}, Tab)
	tab.Window = self
	tab.Name = tostring(options.Title or ("Tab " .. tostring(#self.Tabs + 1)))

	tab.Index = #self.Tabs + 1

	tab.Node = Create("TextButton", {
		Name = tab.Name,
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundTransparency = 1,
		BackgroundColor3 = Theme.ElementHover,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
		LayoutOrder = tab.Index,
		Parent = self.TabList,
	})
	Corner(7, tab.Node)

	tab.Icon = Create("ImageLabel", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 10, 0.5, 0),
		Size = UDim2.fromOffset(16, 16),
		ScaleType = Enum.ScaleType.Fit,
		ImageColor3 = Theme.SubText,
		Image = "",
		Parent = tab.Node,
	})
	ApplyIcon(tab.Icon, options.Icon or "widget-linear", Theme.SubText)

	tab.TitleLabel = Create("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 34, 0, 0),
		Size = UDim2.new(1, -42, 1, 0),
		Font = FONT,
		Text = tab.Name,
		TextSize = 13,
		TextColor3 = Theme.SubText,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = tab.Node,
	})

	local pageFrame = Create("CanvasGroup", {
		Name = tab.Name .. "Page",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		GroupTransparency = 1,
		Visible = false,
		Parent = self.Content,
	})

	local list = Create("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = Theme.Stroke,
		ScrollBarImageTransparency = 0.4,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Parent = pageFrame,
	})
	Padding(list, 14, 14, 16, 16)
	Create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 10),
		Parent = list,
	})

	tab.Page = { Frame = pageFrame, List = list }

	tab.Node.MouseEnter:Connect(function()
		if self.ActiveTab ~= tab then
			Tween(tab.TitleLabel, { TextColor3 = Theme.Text }, 0.15)
		end
	end)
	tab.Node.MouseLeave:Connect(function()
		if self.ActiveTab ~= tab then
			Tween(tab.TitleLabel, { TextColor3 = Theme.SubText }, 0.2)
		end
	end)
	tab.Node.MouseButton1Click:Connect(function()
		self:SelectTab(tab)
	end)

	table.insert(self.Tabs, tab)

	if #self.Tabs == 1 then
		task.defer(function()
			self:SelectTab(tab)
		end)
	end

	return tab
end

Window.Tab = Window.CreateTab

function Window:Toggle(force)
	local visible = force
	if visible == nil then
		visible = not self.Visible
	end
	self.Visible = visible

	if visible then
		self.Main.Visible = true
		self.Main.GroupTransparency = 1
		self.Scale.Scale = 0.96
		Tween(self.Main, { GroupTransparency = 0 }, 0.22)
		Tween(self.Scale, { Scale = 1 }, 0.3, Enum.EasingStyle.Quint)
	else
		Tween(self.Main, { GroupTransparency = 1 }, 0.18)
		Tween(self.Scale, { Scale = 0.96 }, 0.22, Enum.EasingStyle.Quint)
		task.delay(0.24, function()
			if not self.Visible then
				self.Main.Visible = false
			end
		end)
	end
end

function Window:Minimize(force)
	local minimized = force
	if minimized == nil then
		minimized = not self.Minimized
	end
	self.Minimized = minimized

	if minimized then
		if self.SettingsOpen then
			self:ToggleSettings(false)
		end
		Tween(self.Body, { GroupTransparency = 1 }, 0.14)
		Tween(self.Main, { Size = UDim2.fromOffset(self.Size.X, 42) }, 0.3, Enum.EasingStyle.Quint)
		task.delay(0.2, function()
			if self.Minimized then
				self.Body.Visible = false
			end
		end)
	else
		self.Body.Visible = true
		Tween(self.Main, { Size = UDim2.fromOffset(self.Size.X, self.Size.Y) }, 0.3, Enum.EasingStyle.Quint)
		task.delay(0.1, function()
			Tween(self.Body, { GroupTransparency = 0 }, 0.2)
		end)
	end
end

function Window:Destroy()
	for _, connection in ipairs(self.Connections) do
		pcall(function()
			connection:Disconnect()
		end)
	end
	Tween(self.Main, { GroupTransparency = 1 }, 0.18)
	Tween(self.Scale, { Scale = 0.94 }, 0.2)
	task.delay(0.24, function()
		self.Gui:Destroy()
	end)
end

Window.Close = Window.Destroy

--------------------------------------------------------------------- Config --

function Window:ConfigPath(name)
	local folder = self.ConfigFolder or "SimpleLib/configs"
	return folder .. "/" .. tostring(name or "default") .. ".json"
end

function Window:SaveConfig(name)
	if not Env.HasFiles then
		SimpleLib:Notify({ Title = "Config", Content = "File access is unavailable in this executor.", Icon = "danger-triangle" })
		return false
	end
	Env.EnsureFolder(self.ConfigFolder or "SimpleLib/configs")

	local data = {}
	for flag, value in pairs(SimpleLib.Flags) do
		data[flag] = value
	end

	local ok, encoded = pcall(function()
		return HttpService:JSONEncode(data)
	end)
	if not ok then
		return false
	end

	local written = pcall(Env.WriteFile, self:ConfigPath(name), encoded)
	if written then
		SimpleLib:Notify({ Title = "Config saved", Content = tostring(name or "default"), Icon = "diskette" })
	end
	return written
end

function Window:LoadConfig(name)
	if not Env.HasFiles then
		return false
	end
	local path = self:ConfigPath(name)
	local exists = false
	pcall(function()
		exists = Env.IsFile(path)
	end)
	if not exists then
		SimpleLib:Notify({ Title = "Config", Content = "No config named " .. tostring(name or "default"), Icon = "danger-triangle" })
		return false
	end

	local ok, decoded = pcall(function()
		return HttpService:JSONDecode(Env.ReadFile(path))
	end)
	if not ok or type(decoded) ~= "table" then
		return false
	end

	for flag, value in pairs(decoded) do
		local element = self.Registry[flag]
		if element and element.Set then
			pcall(element.Set, element, value)
		else
			SimpleLib.Flags[flag] = value
		end
	end

	SimpleLib:Notify({ Title = "Config loaded", Content = tostring(name or "default"), Icon = "folder-open" })
	return true
end

--=============================================================================
-- Settings panel  (the gear in the title bar)
--=============================================================================

local function BuildSettings(window)
	local overlay = Create("CanvasGroup", {
		Name = "Settings",
		Position = UDim2.new(0, 0, 0, 42),
		Size = UDim2.new(1, 0, 1, -42),
		BackgroundColor3 = Theme.Background,
		BorderSizePixel = 0,
		GroupTransparency = 1,
		Visible = false,
		ZIndex = 5,
		Parent = window.Main,
	})

	local list = Create("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = Theme.Stroke,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Parent = overlay,
	})
	Padding(list, 14, 14, 16, 16)
	Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 10), Parent = list })

	local page = { Frame = overlay, List = list }

	-- Interface -------------------------------------------------------------
	local interface = NewSection(window, page, "Interface")

	local accentNames = {}
	local accentByName = {}
	for _, preset in ipairs(ACCENT_PRESETS) do
		table.insert(accentNames, preset.Name)
		accentByName[preset.Name] = preset.Color
	end

	interface:Dropdown({
		Title = "Accent color",
		Icon = "palette-linear",
		Values = accentNames,
		Default = accentNames[1],
		Callback = function(value)
			local color = accentByName[value]
			if color then
				SimpleLib:SetAccent(color)
			end
		end,
	})

	local keyRow = interface:Button({
		Title = "Toggle key  ·  " .. window.ToggleKey.Name,
		Icon = "keyboard-linear",
		Callback = function()
			window.ListeningForKey = true
			SimpleLib:Notify({ Title = "Toggle key", Content = "Press any key...", Icon = "keyboard-linear", Duration = 3 })
		end,
	})
	window.KeyRow = keyRow

	interface:Toggle({
		Title = "Blur behind window",
		Default = false,
		Callback = function(state)
			window:SetBlur(state)
		end,
	})

	-- Configuration ---------------------------------------------------------
	local config = NewSection(window, page, "Configuration")

	local nameBox = config:Input({
		Title = "Config name",
		Icon = "file-text-linear",
		Default = "default",
		Placeholder = "default",
	})

	config:Button({
		Title = "Save config",
		Icon = "diskette-linear",
		Callback = function()
			window:SaveConfig(nameBox:Get())
		end,
	})

	config:Button({
		Title = "Load config",
		Icon = "download-linear",
		Callback = function()
			window:LoadConfig(nameBox:Get())
		end,
	})

	-- About -----------------------------------------------------------------
	local about = NewSection(window, page, "About")
	about:Paragraph({
		Title = "SimpleLib v" .. SimpleLib.Version,
		Content = "Simple, animated UI library for Roblox. Icons by Solar (solar-icons.vercel.app).",
	})

	about:Button({
		Title = "Unload interface",
		Icon = "logout-2-linear",
		Callback = function()
			window:Destroy()
		end,
	})

	window.SettingsOverlay = overlay
	return overlay
end

function Window:ToggleSettings(force)
	local shown = force
	if shown == nil then
		shown = not self.SettingsOpen
	end
	self.SettingsOpen = shown

	if shown then
		self.SettingsOverlay.Visible = true
		self.SettingsOverlay.GroupTransparency = 1
		self.SettingsOverlay.Position = UDim2.new(0, 0, 0, 52)
		Tween(self.SettingsOverlay, { GroupTransparency = 0, Position = UDim2.new(0, 0, 0, 42) }, 0.3, Enum.EasingStyle.Quint)
		Tween(self.Body, { GroupTransparency = 0.9 }, 0.2)
		Tween(self.SettingsIcon, { Rotation = 90, ImageColor3 = Theme.Accent }, 0.3, Enum.EasingStyle.Quint)
	else
		Tween(self.SettingsOverlay, { GroupTransparency = 1, Position = UDim2.new(0, 0, 0, 52) }, 0.22, Enum.EasingStyle.Quint)
		Tween(self.Body, { GroupTransparency = 0 }, 0.25)
		Tween(self.SettingsIcon, { Rotation = 0, ImageColor3 = Theme.SubText }, 0.3, Enum.EasingStyle.Quint)
		task.delay(0.26, function()
			if not self.SettingsOpen then
				self.SettingsOverlay.Visible = false
			end
		end)
	end
end

function Window:SetBlur(state)
	if state then
		if not self.Blur then
			self.Blur = Create("BlurEffect", { Size = 0, Parent = game:GetService("Lighting") })
		end
		Tween(self.Blur, { Size = 12 }, 0.3)
	elseif self.Blur then
		Tween(self.Blur, { Size = 0 }, 0.25)
	end
end

--=============================================================================
-- Title bar buttons
--=============================================================================

local function TitleButton(parent, iconName, glyph, order, onClick)
	local button = Create("TextButton", {
		Name = iconName,
		Size = UDim2.fromOffset(26, 26),
		BackgroundColor3 = Theme.ElementHover,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
		LayoutOrder = order,
		Parent = parent,
	})
	Corner(6, button)

	local icon = Create("ImageLabel", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(15, 15),
		ScaleType = Enum.ScaleType.Fit,
		ImageColor3 = Theme.SubText,
		Image = "",
		Parent = button,
	})

	-- If the icon cannot be downloaded the button still needs a face.
	local glyphLabel = Create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Font = FONT,
		Text = glyph or "",
		TextSize = 15,
		TextColor3 = Theme.SubText,
		Visible = false,
		Parent = button,
	})

	ApplyIcon(icon, iconName, Theme.SubText, glyphLabel)

	button.MouseEnter:Connect(function()
		Tween(button, { BackgroundTransparency = 0.4 }, 0.15)
		Tween(icon, { ImageColor3 = Theme.Text }, 0.15)
		Tween(glyphLabel, { TextColor3 = Theme.Text }, 0.15)
	end)
	button.MouseLeave:Connect(function()
		Tween(button, { BackgroundTransparency = 1 }, 0.2)
		Tween(icon, { ImageColor3 = Theme.SubText }, 0.2)
		Tween(glyphLabel, { TextColor3 = Theme.SubText }, 0.2)
	end)
	button.MouseButton1Click:Connect(function()
		if onClick then
			task.spawn(onClick)
		end
	end)

	return button, icon
end

--=============================================================================
-- SimpleLib:CreateWindow
--=============================================================================

function SimpleLib:CreateWindow(options)
	options = options or {}

	local self = setmetatable({}, Window)
	self.Tabs = {}
	self.Registry = {}
	self.Connections = {}
	self.Visible = true
	self.Minimized = false
	self.SettingsOpen = false
	self.ConfigFolder = options.ConfigFolder or "SimpleLib/configs"
	self.ToggleKey = options.ToggleKey or Enum.KeyCode.RightShift

	if options.Accent then
		Theme.Accent = options.Accent
	end
	if options.IconStyle then
		Icons.Style = options.IconStyle
	end

	local size = options.Size or UDim2.fromOffset(560, 400)
	self.Size = Vector2.new(size.X.Offset, size.Y.Offset)

	self.Gui = Create("ScreenGui", {
		Name = options.GuiName or "SimpleLib",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 999,
	})
	Env.Protect(self.Gui)
	self.Gui.Parent = Env.GuiParent()

	self.Main = Create("CanvasGroup", {
		Name = "Window",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(self.Size.X, self.Size.Y),
		BackgroundColor3 = Theme.Background,
		BorderSizePixel = 0,
		GroupTransparency = 1,
		ClipsDescendants = true,
		Parent = self.Gui,
	})
	Corner(12, self.Main)
	Stroke(self.Main, Theme.Stroke, 0.2)
	self.Scale = Create("UIScale", { Scale = 0.94, Parent = self.Main })

	----------------------------------------------------------------- topbar --
	local topbar = Create("Frame", {
		Name = "Topbar",
		Size = UDim2.new(1, 0, 0, 42),
		BackgroundColor3 = Theme.Topbar,
		BorderSizePixel = 0,
		ZIndex = 6,
		Parent = self.Main,
	})

	Create("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, 0),
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = Theme.Stroke,
		BackgroundTransparency = 0.4,
		BorderSizePixel = 0,
		ZIndex = 6,
		Parent = topbar,
	})

	local titleX = 16
	if options.Icon then
		local windowIcon = Create("ImageLabel", {
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 14, 0.5, 0),
			Size = UDim2.fromOffset(16, 16),
			ScaleType = Enum.ScaleType.Fit,
			Image = "",
			ZIndex = 7,
			Parent = topbar,
		})
		ApplyIcon(windowIcon, options.Icon, Theme.Text)
		titleX = 38
	end

	Create("TextLabel", {
		Name = "Title",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, titleX, 0, 0),
		Size = UDim2.new(1, -titleX - 110, 1, 0),
		Font = FONT,
		Text = tostring(options.Title or "SimpleLib"),
		TextSize = 14,
		TextColor3 = Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 7,
		Parent = topbar,
	})

	local buttons = Create("Frame", {
		Name = "Buttons",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.new(0, 100, 0, 26),
		BackgroundTransparency = 1,
		ZIndex = 7,
		Parent = topbar,
	}, {
		Create("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 2),
		}),
	})

	local _, settingsIcon = TitleButton(buttons, "settings-linear", "\226\154\153", 1, function()
		self:ToggleSettings()
	end)
	self.SettingsIcon = settingsIcon

	TitleButton(buttons, "minus-circle-linear", "\226\128\147", 2, function()
		self:Minimize()
	end)

	TitleButton(buttons, "close-circle-linear", "\195\151", 3, function()
		self:Destroy()
	end)

	------------------------------------------------------------------- body --
	self.Body = Create("CanvasGroup", {
		Name = "Body",
		Position = UDim2.new(0, 0, 0, 42),
		Size = UDim2.new(1, 0, 1, -42),
		BackgroundTransparency = 1,
		Parent = self.Main,
	})

	local sidebar = Create("Frame", {
		Name = "Sidebar",
		Size = UDim2.new(0, 142, 1, 0),
		BackgroundColor3 = Theme.Sidebar,
		BorderSizePixel = 0,
		Parent = self.Body,
	})

	Create("Frame", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 0),
		Size = UDim2.new(0, 1, 1, 0),
		BackgroundColor3 = Theme.Stroke,
		BackgroundTransparency = 0.4,
		BorderSizePixel = 0,
		Parent = sidebar,
	})

	self.TabList = Create("Frame", {
		Name = "Tabs",
		Position = UDim2.new(0, 10, 0, 12),
		Size = UDim2.new(1, -20, 1, -24),
		BackgroundTransparency = 1,
		Parent = sidebar,
	}, {
		Create("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 4),
		}),
	})

	-- Sits behind the tab buttons and slides to the active one.
	self.Highlight = Create("Frame", {
		Name = "Highlight",
		Position = UDim2.new(0, 10, 0, 12),
		Size = UDim2.new(1, -20, 0, 34),
		BackgroundColor3 = Theme.Element,
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 0,
		Parent = sidebar,
	})
	Corner(7, self.Highlight)

	self.Content = Create("Frame", {
		Name = "Content",
		Position = UDim2.new(0, 143, 0, 0),
		Size = UDim2.new(1, -143, 1, 0),
		BackgroundTransparency = 1,
		Parent = self.Body,
	})

	---------------------------------------------------------------- dragging --
	do
		local dragging, dragStart, startPos = false, nil, nil

		topbar.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				dragStart = input.Position
				startPos = self.Main.Position
			end
		end)

		topbar.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			end
		end)

		table.insert(self.Connections, UserInputService.InputChanged:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				local delta = input.Position - dragStart
				self.Main.Position = UDim2.new(
					startPos.X.Scale,
					startPos.X.Offset + delta.X,
					startPos.Y.Scale,
					startPos.Y.Offset + delta.Y
				)
			end
		end))
	end

	----------------------------------------------------------------- keybind --
	table.insert(self.Connections, UserInputService.InputBegan:Connect(function(input, processed)
		if processed or input.UserInputType ~= Enum.UserInputType.Keyboard then
			return
		end
		if self.ListeningForKey then
			self.ListeningForKey = false
			self.ToggleKey = input.KeyCode
			if self.KeyRow then
				self.KeyRow:SetTitle("Toggle key  ·  " .. input.KeyCode.Name)
			end
			SimpleLib:Notify({ Title = "Toggle key", Content = "Set to " .. input.KeyCode.Name, Icon = "check-circle-linear" })
			return
		end
		if input.KeyCode == self.ToggleKey then
			self:Toggle()
		end
	end))

	BuildSettings(self)

	------------------------------------------------------------------- intro --
	task.defer(function()
		Tween(self.Main, { GroupTransparency = 0 }, 0.25)
		Tween(self.Scale, { Scale = 1 }, 0.45, Enum.EasingStyle.Quint)
	end)

	table.insert(SimpleLib.Windows, self)
	return self
end

--=============================================================================
-- Global helpers
--=============================================================================

function SimpleLib:SetAccent(color)
	Theme.Accent = color
	for _, window in ipairs(SimpleLib.Windows) do
		if window.ActiveTab then
			Tween(window.ActiveTab.Icon, { ImageColor3 = color }, 0.2)
		end
	end
	for _, listener in ipairs(AccentListeners) do
		pcall(listener, color)
	end
end

function SimpleLib:SetIconStyle(style)
	if Icons.Styles[style] then
		Icons.Style = style
	end
end

function SimpleLib:GetFlag(flag, fallback)
	local value = SimpleLib.Flags[flag]
	if value == nil then
		return fallback
	end
	return value
end

function SimpleLib:Destroy()
	for _, window in ipairs(SimpleLib.Windows) do
		pcall(function()
			window:Destroy()
		end)
	end
	SimpleLib.Windows = {}
end

return SimpleLib
