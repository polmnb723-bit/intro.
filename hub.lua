local BASE = "https://raw.githubusercontent.com/polmnb723-bit/intro/main/"
local MAIN_URL = BASE .. "hub.lua"
local PLAT_FILE, SKIP_FILE = "ld_platform.txt", "ld_skipintro.txt"
local MENU_SIDE = "center" -- "center" وسط الشاشة، أو "right" يمين
local OVERLAY = 0.75 -- تعتيم الصورة داخل القائمة: 0 غامق مرة، 1 بدون تعتيم
local VERSION = "v4"
local SHEETS, TOTAL, FPS = 13, 100, 10
local COLS, FW, FH = 2, 448, 252
local PER_SHEET = 8
local FADE_IN, VFADE, FADE_OUT = 1.2, 0.8, 1.5
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local UIS = game:GetService("UserInputService")
local holder = (gethui and gethui()) or game:GetService("CoreGui")
for _, n in ipairs({"LDMenu", "LDIntro"}) do
local o = holder:FindFirstChild(n)
if o then o:Destroy() end
end
local STUB = [==[
if MODE == "Mobile" then return end
if not (hookmetamethod and newcclosure and checkcaller and getnamecallmethod) then return end
local UIS = game:GetService("UserInputService")
local GS = game:GetService("GuiService")
local PRESETS = {
PC = {plat = "Windows", touch = false, kb = true, mouse = true, pad = false, ten = false, last = "Keyboard"},
Console = {plat = "PS4", touch = false, kb = false, mouse = false, pad = true, ten = true, last = "Gamepad1"},
}
local p = PRESETS[MODE]
if not p then return end
local plat = Enum.Platform[p.plat]
local lastType = Enum.UserInputType[p.last]
local props = {
TouchEnabled = p.touch,
KeyboardEnabled = p.kb,
MouseEnabled = p.mouse,
GamepadEnabled = p.pad,
AccelerometerEnabled = false,
GyroscopeEnabled = false,
}
local oldIndex
oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, key)
if self == UIS and not checkcaller() then
local v = props[key]
if v ~= nil then return v end
end
return oldIndex(self, key)
end))
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
local m = getnamecallmethod()
if not checkcaller() then
if self == UIS then
if m == "GetPlatform" then return plat end
if m == "GetLastInputType" then return lastType end
elseif self == GS and m == "IsTenFootInterface" then
return p.ten
end
end
return oldNamecall(self, ...)
end))
]==]
local function buildQueued(mode)
return table.concat({
"local MODE = " .. string.format("%q", mode),
"pcall(function()",
STUB,
"end)",
"if not game:IsLoaded() then game.Loaded:Wait() end",
"task.wait(1)",
'loadstring(game:HttpGet("' .. MAIN_URL .. '"))()',
}, "\n")
end
local function readMode()
local m = "Mobile"
pcall(function()
if isfile(PLAT_FILE) then m = readfile(PLAT_FILE) end
end)
if m ~= "PC" and m ~= "Console" then m = "Mobile" end
return m
end
local function switchPlatform(mode)
local q = queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)
if not q then
return false, "الإكسكيوتر ما يدعم queue_on_teleport"
end
pcall(function()
if mode == "Mobile" then
if isfile(PLAT_FILE) then delfile(PLAT_FILE) end
else
writefile(PLAT_FILE, mode)
end
writefile(SKIP_FILE, "1")
end)
local okq, eq = pcall(q, buildQueued(mode))
if not okq then
return false, "فشل: " .. tostring(eq)
end
task.wait(0.5)
local lp = Players.LocalPlayer
TeleportService.TeleportInitFailed:Connect(function()
pcall(function() TeleportService:Teleport(game.PlaceId, lp) end)
end)
local okTp = pcall(function()
TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, lp)
end)
if not okTp then
pcall(function() TeleportService:Teleport(game.PlaceId, lp) end)
end
return true
end
local ORIG = {}
local function snapOne(o)
local t = {}
if o:IsA("GuiObject") then t.BackgroundTransparency = o.BackgroundTransparency end
if o:IsA("TextLabel") or o:IsA("TextButton") then t.TextTransparency = o.TextTransparency end
if o:IsA("ImageLabel") then t.ImageTransparency = o.ImageTransparency end
if o:IsA("UIStroke") then t.Transparency = o.Transparency end
if next(t) then ORIG[o] = t end
end
local function snap(root)
snapOne(root)
for _, o in ipairs(root:GetDescendants()) do snapOne(o) end
end
local function inTree(o, root, withDesc)
if o == root then return true end
return withDesc and o:IsDescendantOf(root)
end
local function setHidden(root, withDesc)
for o, t in pairs(ORIG) do
if inTree(o, root, withDesc) then
for k in pairs(t) do o[k] = 1 end
end
end
end
local function showObj(root, d, delay, withDesc)
local info = TweenInfo.new(d, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, delay or 0)
for o, t in pairs(ORIG) do
if inTree(o, root, withDesc) then
TweenService:Create(o, info, t):Play()
end
end
end
local function hideObj(root, d, withDesc)
local info = TweenInfo.new(d)
for o, t in pairs(ORIG) do
if inTree(o, root, withDesc) then
local g = {}
for k in pairs(t) do g[k] = 1 end
TweenService:Create(o, info, g):Play()
end
end
end
local function get(file, minSize)
local path = "ld_" .. file
if isfile(path) and #readfile(path) < minSize then
delfile(path)
end
if not isfile(path) then
local data = game:HttpGet(BASE .. file)
if #data < minSize then
error("الملف غير موجود بالمستودع: " .. file)
end
writefile(path, data)
end
return getcustomasset(path)
end
local menuErr = nil
local function getFresh(file, minSize)
local okd, data = pcall(function() return game:HttpGet(BASE .. file) end)
if okd and type(data) == "string" and #data >= minSize then
local path = "ld_" .. #data .. "_" .. file
if not isfile(path) then writefile(path, data) end
return getcustomasset(path)
end
menuErr = okd and "small" or string.sub(tostring(data), 1, 14)
return get(file, minSize)
end
local assets = {}
local GOLD = Color3.fromRGB(255, 214, 102)
local DEVICES = {
{mode = "PC", name = "PC", sub = "كمبيوتر"},
{mode = "Console", name = "Console", sub = "كونسول"},
{mode = "Mobile", name = "Mobile", sub = "جوال"},
}
local function buildMenu()
local current = readMode()
local mg = Instance.new("ScreenGui")
mg.Name = "LDMenu"
mg.IgnoreGuiInset = true
mg.DisplayOrder = 998
mg.ResetOnSpawn = false
mg.Parent = holder
local panel = Instance.new("Frame")
local RIGHT = (MENU_SIDE == "right")
local FINAL = RIGHT and UDim2.new(1, -24, 0.5, 0) or UDim2.new(0.5, 0, 0.5, 0)
local START = RIGHT and UDim2.new(1.5, 0, 0.5, 0) or UDim2.new(0.5, 0, 0.58, 0)
panel.AnchorPoint = RIGHT and Vector2.new(1, 0.5) or Vector2.new(0.5, 0.5)
panel.Position = FINAL
panel.Size = RIGHT and UDim2.new(0.54, 0, 0.84, 0) or UDim2.new(0.62, 0, 0.8, 0)
panel.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
panel.BorderSizePixel = 0
panel.ClipsDescendants = true
panel.Visible = false
panel.Parent = mg
Instance.new("UIAspectRatioConstraint", panel).AspectRatio = 1.6
local pcorner = Instance.new("UICorner")
pcorner.CornerRadius = UDim.new(0, 18)
pcorner.Parent = panel
local pstroke = Instance.new("UIStroke")
pstroke.Color = GOLD
pstroke.Transparency = 0.35
pstroke.Thickness = 2
pstroke.Parent = panel
local scale = Instance.new("UIScale")
scale.Scale = 1
scale.Parent = panel
local img
if assets.menu then
img = Instance.new("ImageLabel")
img.Size = UDim2.new(1, 0, 1, 0)
img.BackgroundTransparency = 1
img.Image = assets.menu
img.ScaleType = Enum.ScaleType.Crop
img.ZIndex = 1
img.Parent = panel
end
local overlay = Instance.new("Frame")
overlay.Size = UDim2.new(1, 0, 1, 0)
overlay.BackgroundColor3 = Color3.new(0, 0, 0)
overlay.BackgroundTransparency = OVERLAY
overlay.BorderSizePixel = 0
overlay.ZIndex = 2
overlay.Parent = panel
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0.3, 0)
header.BackgroundTransparency = 1
header.Active = true
header.ZIndex = 2
header.Parent = panel
local title = Instance.new("TextLabel")
title.Size = UDim2.new(0.9, 0, 0.13, 0)
title.Position = UDim2.new(0.05, 0, 0.05, 0)
title.BackgroundTransparency = 1
title.Text = "LD hub | TD"
title.Font = Enum.Font.GothamBold
title.TextScaled = true
title.TextColor3 = Color3.fromRGB(200, 235, 255)
title.ZIndex = 3
title.Parent = panel
local by = Instance.new("TextLabel")
by.Size = UDim2.new(0.5, 0, 0.06, 0)
by.Position = UDim2.new(0.25, 0, 0.19, 0)
by.BackgroundTransparency = 1
by.Text = "b y   d e v"
by.Font = Enum.Font.GothamBold
by.TextScaled = true
by.TextColor3 = GOLD
by.ZIndex = 3
by.Parent = panel
local line = Instance.new("Frame")
line.AnchorPoint = Vector2.new(0.5, 0)
line.Position = UDim2.new(0.5, 0, 0.27, 0)
line.Size = UDim2.new(0.5, 0, 0, 2)
line.BackgroundColor3 = GOLD
line.BorderSizePixel = 0
line.ZIndex = 3
line.Parent = panel
local status = Instance.new("TextLabel")
status.Size = UDim2.new(0.6, 0, 0.07, 0)
status.Position = UDim2.new(0.2, 0, 0.30, 0)
status.BackgroundTransparency = 1
status.Text = "الجهاز الحالي: " .. current
status.Font = Enum.Font.GothamBold
status.TextScaled = true
status.TextColor3 = Color3.fromRGB(230, 230, 230)
status.ZIndex = 3
status.Parent = panel
local row = Instance.new("Frame")
row.Position = UDim2.new(0.08, 0, 0.42, 0)
row.Size = UDim2.new(0.84, 0, 0.3, 0)
row.BackgroundTransparency = 1
row.ZIndex = 3
row.Parent = panel
local rl = Instance.new("UIListLayout")
rl.FillDirection = Enum.FillDirection.Horizontal
rl.Padding = UDim.new(0.05, 0)
rl.HorizontalAlignment = Enum.HorizontalAlignment.Center
rl.SortOrder = Enum.SortOrder.LayoutOrder
rl.Parent = row
local DEFHINT = "اضغط على الجهاز مرتين للتأكيد وإعادة الدخول"
local hint = Instance.new("TextLabel")
hint.Size = UDim2.new(0.9, 0, 0.06, 0)
hint.Position = UDim2.new(0.05, 0, 0.75, 0)
hint.BackgroundTransparency = 1
hint.Text = DEFHINT
hint.Font = Enum.Font.Gotham
hint.TextScaled = true
hint.TextColor3 = Color3.fromRGB(210, 210, 210)
hint.ZIndex = 3
hint.Parent = panel
local close = Instance.new("TextButton")
close.AnchorPoint = Vector2.new(0.5, 0.5)
close.Position = UDim2.new(0.5, 0, 0.91, 0)
close.Size = UDim2.new(0.3, 0, 0.09, 0)
close.BackgroundColor3 = Color3.fromRGB(120, 25, 25)
close.BackgroundTransparency = 0.2
close.TextColor3 = Color3.new(1, 1, 1)
close.Font = Enum.Font.GothamBold
close.TextScaled = true
close.Text = "إغلاق"
close.ZIndex = 4
close.Parent = panel
local ccorner = Instance.new("UICorner")
ccorner.CornerRadius = UDim.new(0, 10)
ccorner.Parent = close
local cpad = Instance.new("UIPadding")
cpad.PaddingTop = UDim.new(0, 6)
cpad.PaddingBottom = UDim.new(0, 6)
cpad.Parent = close
local ver = Instance.new("TextLabel")
ver.Size = UDim2.new(0.3, 0, 0.05, 0)
ver.Position = UDim2.new(0.03, 0, 0.94, 0)
ver.BackgroundTransparency = 1
ver.Text = VERSION .. " | bg: " .. (assets.menu and "ok" or (menuErr or "no"))
ver.Font = Enum.Font.Gotham
ver.TextScaled = true
ver.TextXAlignment = Enum.TextXAlignment.Left
ver.TextColor3 = Color3.fromRGB(170, 170, 170)
ver.ZIndex = 3
ver.Parent = panel
local cards = {}
local armed, armToken, busy = nil, 0, false
local function resetCard(c)
c.btn.BackgroundColor3 = Color3.new(0, 0, 0)
c.btn.BackgroundTransparency = 0.35
c.sub.Text = (c.mode == current) and "الحالي" or c.subText
end
for i, d in ipairs(DEVICES) do
local wrap = Instance.new("Frame")
wrap.LayoutOrder = i
wrap.Size = UDim2.new(0.3, 0, 1, 0)
wrap.BackgroundTransparency = 1
wrap.ZIndex = 3
wrap.Parent = row
local btn = Instance.new("TextButton")
btn.Size = UDim2.new(1, 0, 1, 0)
btn.BackgroundColor3 = Color3.new(0, 0, 0)
btn.BackgroundTransparency = 0.35
btn.Text = ""
btn.AutoButtonColor = true
btn.ZIndex = 4
btn.Parent = wrap
local bcorner = Instance.new("UICorner")
bcorner.CornerRadius = UDim.new(0, 12)
bcorner.Parent = btn
local bstroke = Instance.new("UIStroke")
bstroke.Thickness = 2
if d.mode == current then
bstroke.Color = GOLD
bstroke.Transparency = 0.1
else
bstroke.Color = Color3.new(1, 1, 1)
bstroke.Transparency = 0.65
end
bstroke.Parent = btn
local nameL = Instance.new("TextLabel")
nameL.Size = UDim2.new(0.86, 0, 0.32, 0)
nameL.Position = UDim2.new(0.07, 0, 0.2, 0)
nameL.BackgroundTransparency = 1
nameL.Text = d.name
nameL.Font = Enum.Font.GothamBold
nameL.TextScaled = true
nameL.TextColor3 = Color3.new(1, 1, 1)
nameL.ZIndex = 5
nameL.Parent = btn
local subL = Instance.new("TextLabel")
subL.Size = UDim2.new(0.86, 0, 0.2, 0)
subL.Position = UDim2.new(0.07, 0, 0.58, 0)
subL.BackgroundTransparency = 1
subL.Text = (d.mode == current) and "الحالي" or d.sub
subL.Font = Enum.Font.Gotham
subL.TextScaled = true
subL.TextColor3 = GOLD
subL.ZIndex = 5
subL.Parent = btn
local card = {mode = d.mode, name = d.name, subText = d.sub, wrap = wrap, btn = btn, sub = subL}
cards[i] = card
btn.MouseButton1Click:Connect(function()
if busy then return end
if armed == card then
busy = true
armed = nil
subL.Text = "جاري إعادة الدخول..."
hint.Text = "جاري إعادة الدخول..."
task.spawn(function()
local ok, msg = switchPlatform(card.mode)
if not ok then
busy = false
resetCard(card)
hint.Text = msg or "صار خطأ"
end
end)
else
if armed then resetCard(armed) end
armed = card
armToken = armToken + 1
local my = armToken
subL.Text = "متأكد؟"
btn.BackgroundColor3 = Color3.fromRGB(150, 90, 0)
btn.BackgroundTransparency = 0.15
hint.Text = "اضغط على " .. card.name .. " مرة ثانية للتأكيد"
task.delay(4, function()
if armed == card and armToken == my then
resetCard(card)
armed = nil
hint.Text = DEFHINT
end
end)
end
end)
end
local tgl = Instance.new("TextButton")
tgl.AnchorPoint = Vector2.new(0, 0.5)
tgl.Position = UDim2.new(0, 12, 0.5, 0)
tgl.Size = UDim2.new(0, 54, 0, 54)
tgl.BackgroundColor3 = Color3.new(0, 0, 0)
tgl.BackgroundTransparency = 0.3
tgl.TextColor3 = GOLD
tgl.Font = Enum.Font.GothamBold
tgl.TextScaled = true
tgl.Text = "LD"
tgl.Visible = false
tgl.ZIndex = 30
tgl.Parent = mg
local tcorner = Instance.new("UICorner")
tcorner.CornerRadius = UDim.new(1, 0)
tcorner.Parent = tgl
local tstroke = Instance.new("UIStroke")
tstroke.Color = GOLD
tstroke.Transparency = 0.2
tstroke.Thickness = 2
tstroke.Parent = tgl
local tpad = Instance.new("UIPadding")
tpad.PaddingTop = UDim.new(0, 14)
tpad.PaddingBottom = UDim.new(0, 14)
tpad.Parent = tgl
snap(panel)
snap(tgl)
local dragging, dStart, pStart = false, nil, nil
header.InputBegan:Connect(function(inp)
if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
dragging = true
dStart = inp.Position
pStart = panel.Position
inp.Changed:Connect(function()
if inp.UserInputState == Enum.UserInputState.End then dragging = false end
end)
end
end)
UIS.InputChanged:Connect(function(inp)
if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
local dlt = inp.Position - dStart
panel.Position = UDim2.new(pStart.X.Scale, pStart.X.Offset + dlt.X, pStart.Y.Scale, pStart.Y.Offset + dlt.Y)
end
end)
local open = false
local ctl = {}
function ctl.show()
if open then return end
open = true
dragging = false
panel.Visible = true
setHidden(panel, true)
scale.Scale = 0.9
panel.Position = START
TweenService:Create(scale, TweenInfo.new(0.75, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
TweenService:Create(panel, TweenInfo.new(0.75, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = FINAL}):Play()
showObj(panel, 0.5, 0, false)
showObj(pstroke, 0.5, 0, false)
showObj(overlay, 0.5, 0, false)
if img then showObj(img, 0.6, 0, false) end
showObj(title, 0.5, 0.25, true)
showObj(by, 0.5, 0.35, true)
line.Size = UDim2.new(0, 0, 0, 2)
TweenService:Create(line, TweenInfo.new(0.7, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, 0, false, 0.4), {Size = UDim2.new(0.5, 0, 0, 2)}):Play()
showObj(line, 0.3, 0.4, true)
showObj(status, 0.5, 0.55, true)
for i, c in ipairs(cards) do
local dl = 0.65 + (i - 1) * 0.13
c.btn.Position = UDim2.new(0, 0, 0.3, 0)
TweenService:Create(c.btn, TweenInfo.new(0.55, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, false, dl), {Position = UDim2.new(0, 0, 0, 0)}):Play()
showObj(c.btn, 0.45, dl, true)
end
showObj(hint, 0.5, 1.05, true)
showObj(close, 0.5, 1.15, true)
hideObj(tgl, 0.25, true)
task.delay(0.3, function()
if open then tgl.Visible = false end
end)
end
function ctl.hide()
if not open then return end
open = false
dragging = false
if armed then resetCard(armed) armed = nil end
hint.Text = DEFHINT
hideObj(panel, 0.4, true)
TweenService:Create(panel, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position = START}):Play()
TweenService:Create(scale, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Scale = 0.88}):Play()
tgl.Visible = true
setHidden(tgl, true)
showObj(tgl, 0.4, 0.2, true)
task.delay(0.5, function()
if not open then
panel.Visible = false
end
end)
end
close.MouseButton1Click:Connect(ctl.hide)
tgl.MouseButton1Click:Connect(ctl.show)
return ctl
end
local skipIntro = false
pcall(function()
if isfile(SKIP_FILE) then
skipIntro = true
delfile(SKIP_FILE)
end
end)
local menu
local ok, err = pcall(function()
pcall(function() assets.menu = getFresh("menu_bg.jpg", 3000) end)
if skipIntro then
if assets.menu then
local warm = Instance.new("ScreenGui")
warm.IgnoreGuiInset = true
warm.DisplayOrder = 1000
warm.Parent = holder
local w = Instance.new("ImageLabel")
w.Size = UDim2.new(0, 2, 0, 2)
w.BackgroundTransparency = 1
w.Image = assets.menu
w.Parent = warm
task.wait(1)
warm:Destroy()
end
menu = buildMenu()
menu.show()
return
end
for i = 1, SHEETS do
assets[i] = get(string.format("sheet_%02d.jpg", i), 5000)
end
pcall(function() assets.audio = get("audio.mp3", 5000) end)
local warm = Instance.new("ScreenGui")
warm.IgnoreGuiInset = true
warm.DisplayOrder = 1000
warm.Parent = holder
for i = 1, SHEETS do
local w = Instance.new("ImageLabel")
w.Size = UDim2.new(0, 2, 0, 2)
w.BackgroundTransparency = 1
w.Image = assets[i]
w.Parent = warm
end
if assets.menu then
local w = Instance.new("ImageLabel")
w.Size = UDim2.new(0, 2, 0, 2)
w.BackgroundTransparency = 1
w.Image = assets.menu
w.Parent = warm
end
task.wait(2.5)
warm:Destroy()
menu = buildMenu()
local gui = Instance.new("ScreenGui")
gui.Name = "LDIntro"
gui.IgnoreGuiInset = true
gui.DisplayOrder = 999
gui.Parent = holder
local bg = Instance.new("Frame")
bg.Size = UDim2.new(1, 0, 1, 0)
bg.BackgroundColor3 = Color3.new(0, 0, 0)
bg.BackgroundTransparency = 1
bg.BorderSizePixel = 0
bg.Parent = gui
local screen = Instance.new("Frame")
screen.AnchorPoint = Vector2.new(0.5, 0.5)
screen.Position = UDim2.new(0.5, 0, 0.5, 0)
screen.Size = UDim2.new(1, 0, 1, 0)
screen.BackgroundTransparency = 1
screen.ClipsDescendants = true
screen.Parent = bg
Instance.new("UIAspectRatioConstraint", screen).AspectRatio = 736 / 414
local labels = {}
for i = 1, SHEETS do
local l = Instance.new("ImageLabel")
l.Size = UDim2.new(1, 0, 1, 0)
l.BackgroundTransparency = 1
l.Image = assets[i]
l.ImageRectSize = Vector2.new(FW, FH)
l.ImageTransparency = 1
l.Parent = screen
labels[i] = l
end
local sound
if assets.audio then
sound = Instance.new("Sound")
sound.SoundId = assets.audio
sound.Volume = 0
sound.Parent = gui
end
local skip = Instance.new("TextButton")
skip.AnchorPoint = Vector2.new(1, 1)
skip.Position = UDim2.new(1, -20, 1, -20)
skip.Size = UDim2.new(0, 110, 0, 42)
skip.BackgroundColor3 = Color3.new(0, 0, 0)
skip.BackgroundTransparency = 1
skip.TextColor3 = Color3.new(1, 1, 1)
skip.TextTransparency = 1
skip.Font = Enum.Font.GothamBold
skip.TextScaled = true
skip.Text = "تخطي"
skip.ZIndex = 20
skip.Parent = bg
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = skip
local stroke = Instance.new("UIStroke")
stroke.Color = Color3.new(1, 1, 1)
stroke.Transparency = 1
stroke.Thickness = 1.5
stroke.Parent = skip
local pad = Instance.new("UIPadding")
pad.PaddingTop = UDim.new(0, 8)
pad.PaddingBottom = UDim.new(0, 8)
pad.Parent = skip
local skipped = false
local cur, sorry
local function fadeAll(d)
local info = TweenInfo.new(d)
TweenService:Create(bg, info, {BackgroundTransparency = 1}):Play()
if cur then TweenService:Create(cur, info, {ImageTransparency = 1}):Play() end
TweenService:Create(skip, info, {BackgroundTransparency = 1, TextTransparency = 1}):Play()
TweenService:Create(stroke, info, {Transparency = 1}):Play()
if sorry then TweenService:Create(sorry, info, {TextTransparency = 1}):Play() end
if sound then TweenService:Create(sound, info, {Volume = 0}):Play() end
end
skip.MouseButton1Click:Connect(function()
if skipped then return end
skipped = true
fadeAll(FADE_OUT)
task.delay(FADE_OUT + 0.1, function()
gui:Destroy()
menu.show()
end)
end)
local info = TweenInfo.new(FADE_IN)
TweenService:Create(bg, info, {BackgroundTransparency = 0}):Play()
TweenService:Create(skip, info, {BackgroundTransparency = 0.45, TextTransparency = 0}):Play()
TweenService:Create(stroke, info, {Transparency = 0.5}):Play()
task.wait(FADE_IN)
if skipped then return end
if sound then
sound:Play()
TweenService:Create(sound, TweenInfo.new(VFADE), {Volume = 1}):Play()
end
local t0 = os.clock()
local lastF = -1
while not skipped do
local el = os.clock() - t0
local f = math.floor(el * FPS)
if f >= TOTAL then break end
local alpha = math.clamp(1 - el / VFADE, 0, 1)
if f ~= lastF then
lastF = f
local s = math.floor(f / PER_SHEET) + 1
local idx = f % PER_SHEET
if cur ~= labels[s] then
if cur then cur.ImageTransparency = 1 end
cur = labels[s]
cur.ImageTransparency = alpha
end
cur.ImageRectOffset = Vector2.new((idx % COLS) * FW, math.floor(idx / COLS) * FH)
end
if cur and el <= VFADE + 0.05 then
cur.ImageTransparency = alpha
end
RunService.RenderStepped:Wait()
end
if skipped then return end
if sound then sound:Stop() end
for _, l in ipairs(labels) do l.ImageTransparency = 1 end
cur = nil
sorry = Instance.new("TextLabel")
sorry.AnchorPoint = Vector2.new(0.5, 0.5)
sorry.Position = UDim2.new(0.5, 0, 0.5, 0)
sorry.Size = UDim2.new(0.8, 0, 0, 50)
sorry.BackgroundTransparency = 1
sorry.Text = "اسف على الجودة الضعيفة"
sorry.Font = Enum.Font.GothamBold
sorry.TextScaled = true
sorry.TextColor3 = Color3.new(1, 1, 1)
sorry.TextTransparency = 1
sorry.ZIndex = 15
sorry.Parent = bg
TweenService:Create(sorry, TweenInfo.new(0.8), {TextTransparency = 0}):Play()
task.wait(3.8)
if skipped then return end
skipped = true
fadeAll(FADE_OUT)
task.wait(FADE_OUT + 0.1)
gui:Destroy()
menu.show()
end)
if not ok then
warn("خطأ: " .. tostring(err))
if not menu then
pcall(function()
menu = buildMenu()
menu.show()
end)
end
end
