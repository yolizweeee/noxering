--[[
 NOXERING AETHER / MM2 • V2.0
 Created by Noxering Team
 Client UI and visual utilities for Roblox Studio and supported client environments.
 IMPORTANT: real MM2 server authority cannot be overridden by a client GUI.
 No HTTP requests, no remote code loading and no Roblox credential collection.
 Place this file as a LocalScript in StarterPlayer > StarterPlayerScripts for Studio.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local player = Players.LocalPlayer
if not player then return end
local playerGui = player:WaitForChild("PlayerGui")
local camera = Workspace.CurrentCamera

-- Shut down the previous copy cleanly when the script is run a second time.
local global = (type(getgenv) == "function" and getgenv()) or _G
if type(global.NOXERING_AETHER_SHUTDOWN) == "function" then
    pcall(global.NOXERING_AETHER_SHUTDOWN)
end

local alive, connections = true, {}
local overlays = {}
local selfHitbox = nil
local toggles = {
    innocent = false, murderer = false, sheriff = false, gun = false,
    showNames = true, particles = true, hitbox = false,
    potato = false, speed = false, fov = false, aimAssist = false, autoThrow = false,
}
local settings = { blur = 15, transparency = 0.12, pulse = 1.0, outline = 0.055,
    speed = 20, fov = 85, aimSmooth = 5, aimRadius = 170,
    hitboxSize = 5, potatoBlur = 3, throwDelay = 0.85 }
local DEFAULT_WALK_SPEED = 16
local cameraStartFov = camera and camera.FieldOfView or 70
local originalHumanoidSpeeds = setmetatable({}, {__mode = "k"})
local originalVisualProps = {}
local potatoToken = 0
local potatoBlurEffect = nil
local practiceRemote = nil
local setPotato = nil
local lastThrow = 0
local lastToolNotice = -100
local binds = { menu = Enum.KeyCode.RightControl, sheriff = Enum.KeyCode.F,
    silent = Enum.KeyCode.R, throw = Enum.KeyCode.T }
local bindButtons = {}
local listeningForBind = nil
local activeTab = "Main"

local function connect(signal, fn)
    local c = signal:Connect(fn)
    table.insert(connections, c)
    return c
end
local function make(class, attributes, parent)
    local instance = Instance.new(class)
    for key, value in pairs(attributes or {}) do instance[key] = value end
    instance.Parent = parent
    return instance
end
local function corners(instance, r)
    make("UICorner", {CornerRadius = UDim.new(0, r)}, instance)
    return instance
end
local function stroke(instance, rgb, thick, trans)
    return make("UIStroke", {Color = rgb, Thickness = thick or 1,
        Transparency = trans or 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, instance)
end
local function gradient(instance, colors, rotation)
    make("UIGradient", {Color = ColorSequence.new(colors), Rotation = rotation or 0}, instance)
end
local function animate(obj, properties, duration, style)
    local t = TweenService:Create(obj, TweenInfo.new(duration or 0.24,
        style or Enum.EasingStyle.Quint, Enum.EasingDirection.Out), properties)
    t:Play()
    return t
end
local P = {
    bg = Color3.fromRGB(9, 10, 15), pane = Color3.fromRGB(17, 18, 25),
    panel = Color3.fromRGB(24, 25, 35), tile = Color3.fromRGB(31, 33, 44),
    text = Color3.fromRGB(247, 248, 255), muted = Color3.fromRGB(145, 148, 167),
    purple = Color3.fromRGB(147, 110, 255), blue = Color3.fromRGB(95, 147, 255),
    green = Color3.fromRGB(76, 235, 151), red = Color3.fromRGB(255, 82, 111),
    cyan = Color3.fromRGB(66, 215, 236), border = Color3.fromRGB(71, 72, 93),
}
local function txt(parent, content, size, color, font, pos, dim, align)
    return make("TextLabel", {
        BackgroundTransparency = 1, Text = content, Font = font or Enum.Font.Gotham,
        TextSize = size or 14, TextColor3 = color or P.text,
        TextXAlignment = align or Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextWrapped = true, Position = pos or UDim2.new(),
        Size = dim or UDim2.new(1, 0, 0, 22),
    }, parent)
end
local function button(parent, text, width, accent)
    local b = make("TextButton", {Text = text, AutoButtonColor = false,
        Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = P.text,
        BackgroundColor3 = accent or P.tile,
        Size = UDim2.new(0, width or 138, 0, 36), BorderSizePixel = 0}, parent)
    corners(b, 11)
    stroke(b, accent and accent:Lerp(Color3.new(1,1,1),0.27) or P.border, 1, 0.54)
    connect(b.MouseEnter, function() animate(b, {BackgroundColor3 = (accent or P.tile):Lerp(P.text, 0.08)}, 0.16) end)
    connect(b.MouseLeave, function() animate(b, {BackgroundColor3 = accent or P.tile}, 0.16) end)
    return b
end

local old = playerGui:FindFirstChild("NOXERING_AETHER")
if old then old:Destroy() end
local gui = make("ScreenGui", {Name = "NOXERING_AETHER", IgnoreGuiInset = true,
    ResetOnSpawn = false, DisplayOrder = 1000, ZIndexBehavior = Enum.ZIndexBehavior.Sibling}, playerGui)

local screenShade = make("Frame", {Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = Color3.new(0,0,0), BackgroundTransparency = 0.35,
    BorderSizePixel = 0, Active = true}, gui)
local root = make("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromScale(0.965, 0.94), BackgroundColor3 = P.bg,
    BackgroundTransparency = 0.055, BorderSizePixel = 0, ClipsDescendants = true,
}, screenShade)
corners(root, 24)
local outerBorder = stroke(root, Color3.fromRGB(125, 104, 196), 1.4, 0.32)
gradient(root, {ColorSequenceKeypoint.new(0, P.bg),
    ColorSequenceKeypoint.new(0.6, Color3.fromRGB(15, 13, 24)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(19, 15, 33))}, 35)

local blur = make("BlurEffect", {Name = "NOXERING_BLUR", Size = settings.blur}, Lighting)
local headerLine = make("Frame", {BackgroundColor3 = P.purple, BackgroundTransparency = 0.28,
    Size = UDim2.new(1,0,0,1), Position = UDim2.new(0,0,0,72), BorderSizePixel = 0}, root)
gradient(headerLine, {ColorSequenceKeypoint.new(0, P.purple),
    ColorSequenceKeypoint.new(0.58, P.blue), ColorSequenceKeypoint.new(1, P.bg)}, 0)

local brandMark = make("Frame", {BackgroundColor3 = P.purple, BorderSizePixel = 0,
    Position = UDim2.fromOffset(26,18), Size = UDim2.fromOffset(36,36)}, root)
corners(brandMark, 11)
gradient(brandMark, {ColorSequenceKeypoint.new(0,P.purple),ColorSequenceKeypoint.new(1,P.blue)}, 45)
txt(brandMark, "N", 23, P.text, Enum.Font.GothamBlack, UDim2.new(), UDim2.fromScale(1,1), Enum.TextXAlignment.Center)
txt(root, "NOXERING", 21, P.text, Enum.Font.GothamBlack,
    UDim2.fromOffset(75, 13), UDim2.fromOffset(220, 29))
txt(root, "AETHER  •  MM2 V2", 10, P.muted, Enum.Font.GothamMedium,
    UDim2.fromOffset(76, 41), UDim2.fromOffset(190, 17))
local badge = make("Frame", {BackgroundColor3 = Color3.fromRGB(35, 32, 53),
    Position = UDim2.new(1,-205,0,22), Size = UDim2.fromOffset(109,28), BorderSizePixel = 0}, root)
corners(badge, 14)
stroke(badge, P.purple, 1, 0.55)
txt(badge, "●  LIVE UI", 11, P.green, Enum.Font.GothamBold,
    UDim2.new(), UDim2.fromScale(1,1), Enum.TextXAlignment.Center)
local closeBtn = button(root, "×", 40)
closeBtn.Position = UDim2.new(1,-61,0,17)
closeBtn.Size = UDim2.fromOffset(40,38)
closeBtn.TextSize = 23

local sidebar = make("Frame", {BackgroundColor3 = Color3.fromRGB(16,17,25),
    BackgroundTransparency = 0.22, Position = UDim2.fromOffset(0,73),
    Size = UDim2.new(0,218,1,-73), BorderSizePixel = 0}, root)
local sideRule = make("Frame", {BackgroundColor3 = P.border, BackgroundTransparency = 0.6,
    Size = UDim2.new(0,1,1,0), Position = UDim2.new(1,-1,0,0), BorderSizePixel=0}, sidebar)
local sideList = make("Frame", {BackgroundTransparency = 1,
    Size = UDim2.new(1,-22,0,430), Position = UDim2.fromOffset(11,24)}, sidebar)
make("UIListLayout", {FillDirection = Enum.FillDirection.Vertical, Padding = UDim.new(0,9)}, sideList)

-- Vector icons drawn from Roblox lines/circles; not dependent on external SVG hosting.
local function vectorIcon(parent, kind, tint)
    local area = make("Frame", {BackgroundTransparency=1, Size=UDim2.fromOffset(24,24)},parent)
    local function line(x,y,w,h,rot)
        local f=make("Frame",{BackgroundColor3=tint,BorderSizePixel=0,
            Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h),Rotation=rot or 0},area)
        corners(f, 2)
        return f
    end
    local function ring(x,y,w,h)
        local f=make("Frame",{BackgroundTransparency=1,Position=UDim2.fromOffset(x,y),
            Size=UDim2.fromOffset(w,h)},area)
        corners(f, 40); stroke(f,tint,2,0)
        return f
    end
    if kind=="Main" then
        line(4,10,13,2,-39); line(12,10,13,2,39)
        line(6,13,2,8);line(17,13,2,8);line(6,20,13,2)
    elseif kind=="ESP" then
        ring(3,7,18,10);ring(10,9,5,5)
    elseif kind=="Murderer" then
        line(11,3,3,17,38); line(5,18,12,3,-40)
        line(8,21,6,2,-40)
    elseif kind=="Sheriff" then
        ring(5,5,14,14);ring(10,10,4,4)
        line(11,1,2,5);line(11,19,2,5);line(1,11,5,2);line(19,11,5,2)
    elseif kind=="Other" then
        line(4,6,16,2);line(4,12,16,2);line(4,18,16,2)
        ring(8,3,6,6);ring(14,9,6,6);ring(6,15,6,6)
    else
        ring(5,5,14,14);ring(10,10,4,4)
        for i=0,3 do line(11,0,2,5,i*90) end
    end
    return area
end

local tabButtons = {}
local pages = {}
local content = make("Frame", {BackgroundTransparency=1,
    Position=UDim2.fromOffset(218,73),Size=UDim2.new(1,-218,1,-73)}, root)
local tabs = {"Main","ESP","Murderer","Sheriff","Other","Settings"}
for _, name in ipairs(tabs) do
    local tab = make("TextButton", {Text="",BackgroundColor3=P.pane,
        BackgroundTransparency=1,Size=UDim2.new(1,0,0,54),AutoButtonColor=false,
        BorderSizePixel=0},sideList)
    corners(tab,12)
    local strip = make("Frame",{BackgroundColor3=P.purple,BackgroundTransparency=1,
        Position=UDim2.fromOffset(0,11),Size=UDim2.fromOffset(3,31),BorderSizePixel=0},tab)
    corners(strip,3)
    local ico = vectorIcon(tab,name,P.text)
    ico.Position=UDim2.fromOffset(19,15)
    local nameLabel = txt(tab,name,14,P.text,Enum.Font.GothamBold,
        UDim2.fromOffset(55,14),UDim2.new(1,-66,0,25))
    tabButtons[name]={button=tab, strip=strip, label=nameLabel}
    connect(tab.MouseEnter,function()
        if activeTab~=name then animate(tab,{BackgroundTransparency=0.45},0.17) end
    end)
    connect(tab.MouseLeave,function()
        if activeTab~=name then animate(tab,{BackgroundTransparency=1},0.17) end
    end)
end
local sideFooter=txt(sidebar,"NOXERING TEAM\nAETHER 2.0  •  LOCAL",10,P.muted,
    Enum.Font.GothamMedium,UDim2.new(0,18,1,-77),UDim2.new(1,-25,0,54))

local function createPage(name,subtitle)
    local pg=make("ScrollingFrame", {Name=name,BackgroundTransparency=1,
        ScrollBarThickness=3,ScrollBarImageColor3=P.purple,
        Position=UDim2.fromOffset(0,0),Size=UDim2.fromScale(1,1),
        CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,
        Visible=false,BorderSizePixel=0}, content)
    make("UIPadding",{PaddingTop=UDim.new(0,27),PaddingBottom=UDim.new(0,36),
        PaddingLeft=UDim.new(0,32),PaddingRight=UDim.new(0,32)},pg)
    make("UIListLayout",{Padding=UDim.new(0,16),SortOrder=Enum.SortOrder.LayoutOrder},pg)
    local head=make("Frame",{Size=UDim2.new(1,0,0,75),BackgroundTransparency=1,
        LayoutOrder=1},pg)
    txt(head,name,30,P.text,Enum.Font.GothamBlack,UDim2.fromOffset(0,0),UDim2.new(1,0,0,40))
    txt(head,subtitle,12,P.muted,Enum.Font.Gotham,UDim2.fromOffset(1,43),UDim2.new(1,0,0,24))
    pages[name]={page=pg,order=2}
    return pg
end
local function nextOrder(pg)
    local p=pages[pg.Name]; local result=p.order;p.order=result+1;return result
end
local function card(pg,height)
    local f=make("Frame",{BackgroundColor3=P.panel,BackgroundTransparency=settings.transparency,
        Size=UDim2.new(1,0,0,height),LayoutOrder=nextOrder(pg),BorderSizePixel=0},pg)
    corners(f,16);stroke(f,P.border,1,0.56)
    f:SetAttribute("GlassCard", true)
    return f
end
local toastHolder=make("Frame",{AnchorPoint=Vector2.new(0.5,1),
    Position=UDim2.fromScale(0.5,0.985),Size=UDim2.fromOffset(420,54),
    BackgroundTransparency=1,ZIndex=30},gui)
local toast = make("TextLabel",{BackgroundColor3=P.tile,BackgroundTransparency=0.05,
    Text="",TextColor3=P.text,TextSize=13,Font=Enum.Font.GothamMedium,
    Visible=false,Size=UDim2.fromScale(1,1),TextWrapped=true,ZIndex=31},toastHolder)
corners(toast,14);stroke(toast,P.purple,1.2,0.28)
local toastToken=0
local function notify(message)
    toastToken=toastToken+1;local serial=toastToken
    toast.Text=message;toast.Visible=true;toast.TextTransparency=0
    task.delay(3.2,function()
        if not alive or serial~=toastToken then return end
        animate(toast,{TextTransparency=1,BackgroundTransparency=1},0.24)
        task.delay(0.26,function() if serial==toastToken then toast.Visible=false;
            toast.BackgroundTransparency=0.05 end end)
    end)
end

local function makeToggle(pg,title,description,key,tint,handler,locked)
    local c=card(pg,79)
    txt(c,title,15,P.text,Enum.Font.GothamBold,UDim2.fromOffset(19,11),UDim2.new(1,-115,0,27))
    txt(c,description,11,P.muted,Enum.Font.Gotham,UDim2.fromOffset(20,41),UDim2.new(1,-119,0,22))
    local track=make("TextButton",{Text="",AutoButtonColor=false,BackgroundColor3=P.border,
        Size=UDim2.fromOffset(51,30),Position=UDim2.new(1,-72,0,24),BorderSizePixel=0},c)
    corners(track,20)
    local dot=make("Frame",{BackgroundColor3=P.text,
        Size=UDim2.fromOffset(24,24),Position=UDim2.fromOffset(3,3),BorderSizePixel=0},track)
    corners(dot,24)
    local function sync()
        animate(track,{BackgroundColor3=toggles[key] and (tint or P.purple) or P.border},0.2)
        animate(dot,{Position=UDim2.fromOffset(toggles[key] and 24 or 3,3)},0.25,
            Enum.EasingStyle.Back)
    end
    connect(track.MouseButton1Click,function()
        if locked then notify("Эта функция требует управления сервером собственной игры Roblox Studio") return end
        toggles[key]=not toggles[key];sync()
        if handler then handler(toggles[key]) end
    end)
    sync()
    return c
end
local function action(pg,title,description,label,handler,tint)
    local c=card(pg,88)
    txt(c,title,15,P.text,Enum.Font.GothamBold,UDim2.fromOffset(19,11),UDim2.new(1,-175,0,28))
    txt(c,description,11,P.muted,Enum.Font.Gotham,UDim2.fromOffset(20,42),UDim2.new(1,-170,0,34))
    local b=button(c,label,129,tint)
    b.AnchorPoint=Vector2.new(1,0.5);b.Position=UDim2.new(1,-18,0.5,0)
    connect(b.MouseButton1Click,handler)
    return c
end
local function slider(pg,title,description,low,high,initial,callback)
    local c=card(pg,105)
    txt(c,title,14,P.text,Enum.Font.GothamBold,UDim2.fromOffset(19,8),UDim2.new(1,-30,0,25))
    txt(c,description,11,P.muted,Enum.Font.Gotham,UDim2.fromOffset(20,34),UDim2.new(1,-30,0,21))
    local bar=make("Frame",{BackgroundColor3=P.tile,Size=UDim2.new(1,-105,0,8),
        Position=UDim2.fromOffset(19,77),BorderSizePixel=0},c)
    corners(bar,6)
    local fill=make("Frame",{BackgroundColor3=P.purple,Size=UDim2.new(0,0,1,0),BorderSizePixel=0},bar)
    corners(fill,6)
    local value=txt(c,"",12,P.text,Enum.Font.GothamBold,UDim2.new(1,-75,0,67),UDim2.fromOffset(60,24),Enum.TextXAlignment.Center)
    local hit=make("TextButton",{Text="",BackgroundTransparency=1,
        Size=UDim2.new(1,0,0,27),Position=UDim2.fromOffset(0,-10)},bar)
    local function set(v)
        v=math.clamp(v,low,high)
        fill.Size=UDim2.new((v-low)/(high-low),0,1,0)
        value.Text=string.format("%.1f",v)
        callback(v)
    end
    local dragging=false
    local function seek(px)
        set(low+(high-low)*math.clamp((px-bar.AbsolutePosition.X)/math.max(1,bar.AbsoluteSize.X),0,1))
    end
    connect(hit.InputBegan,function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            dragging=true;seek(i.Position.X)
        end
    end)
    connect(UserInputService.InputChanged,function(i)
        if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
            seek(i.Position.X)
        end
    end)
    connect(UserInputService.InputEnded,function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=false end
    end)
    set(initial)
    return c
end

-- Main page
local main=createPage("Main","Premium control hub  •  developed by Noxering Team")
local hero=card(main,196)
gradient(hero,{ColorSequenceKeypoint.new(0,Color3.fromRGB(41,29,73)),
    ColorSequenceKeypoint.new(0.65,Color3.fromRGB(33,26,60)),
    ColorSequenceKeypoint.new(1,Color3.fromRGB(16,22,44))}, 10)
local heroGlow=make("Frame",{BackgroundColor3=P.purple,BackgroundTransparency=0.92,
    Size=UDim2.fromOffset(172,172),Position=UDim2.new(1,-131,0,-24),BorderSizePixel=0},hero)
corners(heroGlow,90)
txt(hero,"NOXERING",37,P.text,Enum.Font.GothamBlack,
    UDim2.fromOffset(23,24),UDim2.new(1,-38,0,54))
txt(hero,"BUILT BY NOXERING TEAM",12,P.purple,Enum.Font.GothamBold,
    UDim2.fromOffset(25,80),UDim2.new(1,-50,0,24))
txt(hero,"AETHER — a polished interface for your MM2 experience.\nSmooth visuals. Working client-side controls.",
    13,Color3.fromRGB(209,208,233),Enum.Font.Gotham,
    UDim2.fromOffset(25,111),UDim2.new(1,-48,0,61))
local stats=card(main,112)
txt(stats,"PROJECT / OVERVIEW",11,P.purple,Enum.Font.GothamBold,
    UDim2.fromOffset(20,9),UDim2.new(1,-30,0,25))
txt(stats,"GAME\nMurder Mystery 2",13,P.text,Enum.Font.GothamBold,
    UDim2.fromOffset(21,38),UDim2.new(0.33,-15,0,65))
txt(stats,"VERSION\nAETHER 2.0",13,P.text,Enum.Font.GothamBold,
    UDim2.new(0.34,0,0,38),UDim2.new(0.31,0,0,65))
txt(stats,"STATUS\nUI Active",13,P.green,Enum.Font.GothamBold,
    UDim2.new(0.68,0,0,38),UDim2.new(0.29,0,0,65))
local tips=card(main,87)
txt(tips,"GOOD TO KNOW",12,P.purple,Enum.Font.GothamBold,
    UDim2.fromOffset(19,10),UDim2.new(1,-25,0,20))
txt(tips,"Role outlines are shown when verified by visible tools or server attributes. Combat demo requires a Studio practice server.",
    12,P.muted,Enum.Font.Gotham,UDim2.fromOffset(19,32),UDim2.new(1,-35,0,47))

-- ESP page
local esp=createPage("ESP","Role colors, animated outlines and dropped-item highlighting")
makeToggle(esp,"ESP • Innocent","Green shimmering outlines · inferred when role is not exposed", "innocent",P.green)
makeToggle(esp,"ESP • Murderer","Red outlines · role attribute or visible knife", "murderer",P.red)
makeToggle(esp,"ESP • Sheriff","Blue outlines · role attribute or visible gun", "sheriff",P.blue)
makeToggle(esp,"ESP • Gun Drop","Dropped weapons in Workspace · glowing green highlight", "gun",P.green)
makeToggle(esp,"Player Names","Show player names above supported role boxes", "showNames",P.purple)
slider(esp,"Outline Pulse","Adjust the intensity of animated color blending",0.1,2.5,1.0,function(v)settings.pulse=v end)
slider(esp,"Outline Thickness","Thickness of the 3D SelectionBox",0.02,0.12,0.055,function(v)settings.outline=v end)

-- Combat integration: genuine Roblox Tool actions on the client, or optional
-- Noxering practice-server RemoteEvent in YOUR OWN Roblox Studio place.
local function refreshPracticeRemote()
    local rs = game:GetService("ReplicatedStorage")
    local ev = rs:FindFirstChild("NoxeringPracticeCombat")
    practiceRemote = (ev and ev:IsA("RemoteEvent")) and ev or nil
end
refreshPracticeRemote()
local function practice(actionName, value)
    refreshPracticeRemote()
    if practiceRemote then
        practiceRemote:FireServer(actionName, value)
        return true
    end
    return false
end
local function localRole()
    local r = nil
    for _, key in ipairs({"MM2Role","Role","RoleType"}) do
        local val=player:GetAttribute(key)
        if typeof(val)=="string" then r=string.lower(val);break end
    end
    if r then
        if string.find(r,"murder") then return "murderer" end
        if string.find(r,"sheriff") or string.find(r,"hero") then return "sheriff" end
        if string.find(r,"innocent") then return "innocent" end
    end
    return nil
end
local function findTool(hint)
    local char=player.Character
    local backpack=player:FindFirstChildOfClass("Backpack")
    for _,bag in ipairs({char, backpack}) do
        if bag then
            for _,it in ipairs(bag:GetChildren()) do
                if it:IsA("Tool") then
                    local n=string.lower(it.Name)
                    if (hint=="knife" and (string.find(n,"knife") or string.find(n,"blade")))
                        or (hint=="gun" and (string.find(n,"gun") or string.find(n,"revolver"))) then
                        return it
                    end
                end
            end
        end
    end
    return nil
end
local function equipTool(hint)
    local char=player.Character
    local hum=char and char:FindFirstChildOfClass("Humanoid")
    local tool=findTool(hint)
    if not tool or not hum or hum.Health<=0 then return nil end
    if tool.Parent~=char then hum:EquipTool(tool) end
    return tool
end
local function targetFromCrosshair(role, radius)
    local cam=Workspace.CurrentCamera
    if not cam then return nil end
    local center=cam.ViewportSize*0.5
    local chosen, best=nil, radius or settings.aimRadius
    for _, p in ipairs(Players:GetPlayers()) do
        if p~=player and p.Character then
            local hum=p.Character:FindFirstChildOfClass("Humanoid")
            local root=p.Character:FindFirstChild("HumanoidRootPart")
            if hum and hum.Health>0 and root then
                local valid=(not role)
                if role then
                    local r=p:GetAttribute("MM2Role") or p:GetAttribute("Role") or p:GetAttribute("RoleType")
                    valid=type(r)=="string" and string.find(string.lower(r),role)~=nil
                    if not valid then
                        for _,t in ipairs(p.Character:GetChildren()) do
                            if t:IsA("Tool") and role=="murderer" and string.find(string.lower(t.Name),"knife") then
                                valid=true; break
                            end
                        end
                    end
                end
                if valid then
                    local screenPos, visible=cam:WorldToViewportPoint(root.Position)
                    if visible and screenPos.Z>0 then
                        local dist=(Vector2.new(screenPos.X,screenPos.Y)-center).Magnitude
                        if dist<best then chosen=p; best=dist end
                    end
                end
            end
        end
    end
    return chosen
end
local function lookAtPlayer(p, alpha)
    local cam=Workspace.CurrentCamera
    local root=p and p.Character and p.Character:FindFirstChild("HumanoidRootPart")
    if not cam or not root then return false end
    local eye=cam.CFrame.Position
    local target=root.Position+Vector3.new(0,1.1,0)
    local cf=CFrame.lookAt(eye,target)
    cam.CFrame=cam.CFrame:Lerp(cf,math.clamp(alpha or 1,0,1))
    return true
end
local function sheriffShot(silent)
    local target=targetFromCrosshair("murderer",silent and 1000 or settings.aimRadius)
    if not target then notify("Нет подтверждённого Murderer в зоне поиска");return end
    local tool=equipTool("gun")
    if not tool then notify("Сначала получи Sheriff Gun");return end
    if silent then
        if not practice("SilentShot",target.UserId) then
            notify("Silent Aim требует сервер NOXERING Practice; в публичном MM2 не работает")
        end
        return
    end
    -- Legitimate client tool activation. Actual hit confirmation belongs to the game server.
    lookAtPlayer(target,1)
    if practice("QuickShot",target.UserId) then return end
    task.delay(0.08,function()
        if alive and tool.Parent then pcall(function()tool:Activate()end) end
    end)
end
local function throwAtCrosshair()
    if os.clock()-lastThrow<settings.throwDelay then return end
    lastThrow=os.clock()
    local target=targetFromCrosshair(nil,settings.aimRadius)
    if not target then return end
    local tool=equipTool("knife")
    if not tool then
        if os.clock()-lastToolNotice>7 then
            lastToolNotice=os.clock()
            notify("Auto Throw: нож не найден в инвентаре")
        end
        return
    end
    if practice("Throw",target.UserId) then return end
    -- In live MM2 the game's own Knife tool decides whether Activate is a throw or swing.
    lookAtPlayer(target,0.45)
    pcall(function()tool:Activate()end)
end

local murd=createPage("Murderer","Knife utilities and optional private Studio combat")
action(murd,"Kill All","Works only with NOXERING Practice server in your own Studio game.","ACTIVATE",function()
    if not practice("KillAll") then notify("Kill All недоступен: нужен серверный модуль собственной игры") end
end,P.red)
makeToggle(murd,"Auto Throwing","Auto-activate held Knife toward a centered target; server may reject", "autoThrow",P.red)
makeToggle(murd,"Hitbox Preview","Show enlarged role boxes locally; not server hit detection", "hitbox",P.purple)
slider(murd,"Hitbox Preview Size","Visual box size; practice server can use this target radius",3,12,5,function(v)
    settings.hitboxSize=v
    if practiceRemote then practice("Hitbox",v) end
end)

local sheriff=createPage("Sheriff","Smooth camera tracking and legitimate tool activation")
makeToggle(sheriff,"Aimbot / Camera Assist","Smoothly track a visible, identified Murderer", "aimAssist",P.blue)
action(sheriff,"Murderer Quick Shot","Equip your gun, aim and activate it; hit is server-validated.","SHOOT",function()
    sheriffShot(false)
end,P.blue)
action(sheriff,"Silent Aim • R","Available on your own NOXERING practice server only.","TEST",function()
    sheriffShot(true)
end,P.purple)
slider(sheriff,"Camera Smoothing","Lower is slower; affects camera tracking",1,18,5,function(v)
    settings.aimSmooth=v
end)
slider(sheriff,"Target Radius","Maximum distance from the screen crosshair (px)",70,550,170,function(v)
    settings.aimRadius=v
end)
local function bindRow(pg,title,id)
    local c=card(pg,70)
    txt(c,title,14,P.text,Enum.Font.GothamBold,
        UDim2.fromOffset(18,12),UDim2.new(1,-140,0,43))
    local b=button(c,binds[id].Name,114)
    b.Position=UDim2.new(1,-131,0,17)
    bindButtons[id]=b
    connect(b.MouseButton1Click,function()
        listeningForBind=id;b.Text="PRESS KEY...";notify("Нажми новую клавишу для "..title)
    end)
end
bindRow(sheriff,"Sheriff quick-shot", "sheriff")
bindRow(sheriff,"Silent Aim (Studio only)", "silent")
bindRow(sheriff,"Auto Throw key", "throw")



-- Lightweight, reversible graphics: only map objects, not players or inventory.
local function inCharacterOrTool(inst)
    local node=inst
    while node and node~=Workspace do
        if node:IsA("Tool") then return true end
        if node:IsA("Model") and Players:GetPlayerFromCharacter(node) then return true end
        node=node.Parent
    end
    return false
end
local function underPlayerCharacter(inst)
    local node=inst
    while node and node~=Workspace do
        if node:IsA("Model") and Players:GetPlayerFromCharacter(node) then return true end
        node=node.Parent
    end
    return false
end
local function rememberSet(inst,prop,newValue)
    if not inst or not inst.Parent then return end
    local ok,oldValue=pcall(function()return inst[prop]end)
    if not ok or oldValue==newValue then return end
    local record=originalVisualProps[inst]
    if not record then record={};originalVisualProps[inst]=record end
    if record[prop]==nil then record[prop]={value=oldValue} end
    pcall(function()inst[prop]=newValue end)
end
local function potatoOne(inst)
    if not toggles.potato or inCharacterOrTool(inst) then return end
    if inst:IsA("Texture") or inst:IsA("Decal") then
        rememberSet(inst,"Transparency",1)
    elseif inst:IsA("BasePart") then
        rememberSet(inst,"Material",Enum.Material.SmoothPlastic)
        rememberSet(inst,"CastShadow",false)
        rememberSet(inst,"Reflectance",0)
        pcall(function()rememberSet(inst,"MaterialVariant","")end)
        if inst:IsA("MeshPart") then
            pcall(function()rememberSet(inst,"TextureID","")end)
        end
    elseif inst:IsA("SpecialMesh") then
        pcall(function()rememberSet(inst,"TextureId","")end)
    elseif inst:IsA("ParticleEmitter") or inst:IsA("Trail") or inst:IsA("Beam") then
        rememberSet(inst,"Enabled",false)
    elseif inst:IsA("SurfaceAppearance") then
        rememberSet(inst,"Parent",nil)
    end
end
local function restorePotato()
    potatoToken=potatoToken+1
    for inst, props in pairs(originalVisualProps) do
        -- Restore parent first so detached SurfaceAppearance reappears.
        if props.Parent then pcall(function()inst.Parent=props.Parent.value end)end
        for k,original in pairs(props) do
            if k~="Parent" then pcall(function()inst[k]=original.value end)end
        end
        originalVisualProps[inst]=nil
    end
    if potatoBlurEffect then potatoBlurEffect.Size=0 end
end
setPotato = function(on)
    if not on then restorePotato();return end
    potatoToken=potatoToken+1
    local myToken=potatoToken
    if not potatoBlurEffect or not potatoBlurEffect.Parent then
        potatoBlurEffect=make("BlurEffect",{Name="NOXERING_POTATO_SOFT_BLUR",Size=0},Lighting)
    end
    potatoBlurEffect.Size=settings.potatoBlur
    -- Batch changes across frames to avoid long freezes on large maps.
    task.spawn(function()
        local descendants=Workspace:GetDescendants()
        for i,inst in ipairs(descendants) do
            if not alive or not toggles.potato or potatoToken~=myToken then return end
            potatoOne(inst)
            if i%130==0 then task.wait() end
        end
    end)
end
connect(Workspace.DescendantAdded,function(inst)
    if toggles.potato then task.defer(function()
        if alive and toggles.potato and inst.Parent then potatoOne(inst)end
    end)end
end)

-- OTHER: smooth controls that are real client-side properties.
local other=createPage("Other","Smooth speed, field of view, and reversible potato graphics")
makeToggle(other,"WalkSpeed","Smoothly change your Humanoid speed, including after Respawn", "speed",P.cyan)
slider(other,"WalkSpeed Value","Client requests a speed; the game server may reset it",8,45,20,function(v)
    settings.speed=v
end)
makeToggle(other,"Camera FOV","Smoothly widen or narrow the camera field of view", "fov",P.purple)
slider(other,"Field of View","70° is common default; your initial FOV is restored on shutdown",60,115,85,function(v)
    settings.fov=v
end)
makeToggle(other,"Potato Mode","Simplify map materials, hide decals and disable effects", "potato",P.green,
    function(state) if setPotato then setPotato(state) end end)
slider(other,"Potato Soft Blur","Extra world blur while Potato Mode is enabled",0,10,3,function(v)
    settings.potatoBlur=v
    if potatoBlurEffect then potatoBlurEffect.Size=toggles.potato and v or 0 end
end)
local potatoInfo=card(other,98)
txt(potatoInfo,"PERFORMANCE / TEXTURE NOTES",12,P.green,Enum.Font.GothamBold,
    UDim2.fromOffset(19,10),UDim2.new(1,-30,0,22))
txt(potatoInfo,"Potato Mode is reversible: flat SmoothPlastic map surfaces and hidden textures. The extra Blur is optional and may reduce FPS.",
    11,P.muted,Enum.Font.Gotham,UDim2.fromOffset(19,34),UDim2.new(1,-35,0,57))

local options=createPage("Settings","Customize the interface and keep performance smooth")
slider(options,"Blur strength","World background blur (not a native glass shader)",0,30,15,function(v)
    settings.blur=v;blur.Size=v
end)
slider(options,"Card transparency","How transparent the glass-like cards appear",0,0.6,0.12,function(v)
    settings.transparency=v
    for _,pg in pairs(pages) do
        for _,item in ipairs(pg.page:GetChildren()) do
            if item:IsA("Frame") and item:GetAttribute("GlassCard") then
                item.BackgroundTransparency=v
            end
        end
    end
end)
makeToggle(options,"Particles / Atmosphere","Enable the subtle animated accent glow","particles",P.purple,
    function(v)heroGlow.Visible=v end)
bindRow(options,"Open / close menu", "menu")
action(options,"Reset to defaults","Restore current interface settings and blur values", "RESET",function()
    blur.Size=15;settings.blur=15;settings.pulse=1;settings.outline=0.055
    notify("Основные настройки сброшены")
end,P.purple)
local about=card(options,104)
txt(about,"NOXERING AETHER 2.0",15,P.text,Enum.Font.GothamBold,
    UDim2.fromOffset(18,13),UDim2.new(1,-25,0,28))
txt(about,"Designed by Noxering Team • One local Lua file • No external loaders or data collection",
    12,P.muted,Enum.Font.Gotham,UDim2.fromOffset(18,41),UDim2.new(1,-36,0,50))

for name, data in pairs(tabButtons) do
    connect(data.button.MouseButton1Click,function()
        activeTab=name
        for t,p in pairs(pages) do p.page.Visible=(t==name) end
        for t,d in pairs(tabButtons) do
            local active=t==name
            animate(d.button,{BackgroundTransparency=active and 0 or 1,
                BackgroundColor3=active and Color3.fromRGB(49,39,76) or P.pane},0.20)
            animate(d.strip,{BackgroundTransparency=active and 0 or 1},0.2)
            d.label.TextColor3=active and Color3.fromRGB(222,211,255) or P.text
        end
    end)
end
local function setTab(name)
    if tabButtons[name] then
        local d=tabButtons[name]
        activeTab=name
        for t,p in pairs(pages) do p.page.Visible=(t==name) end
        for t,item in pairs(tabButtons) do
            local a=t==name
            item.button.BackgroundTransparency=a and 0 or 1
            item.button.BackgroundColor3=a and Color3.fromRGB(49,39,76) or P.pane
            item.strip.BackgroundTransparency=a and 0 or 1
            item.label.TextColor3=a and Color3.fromRGB(222,211,255) or P.text
        end
    end
end
setTab("Main")

local mini=make("TextButton",{Text="N",Font=Enum.Font.GothamBlack,TextSize=23,
    TextColor3=P.text,BackgroundColor3=P.purple,AutoButtonColor=false,
    Size=UDim2.fromOffset(56,56),Position=UDim2.new(1,-76,0.5,-28),Visible=false,
    BorderSizePixel=0},gui)
corners(mini,18);stroke(mini,P.text,1,0.55)
local function setVisible(visible)
    screenShade.Visible=visible;mini.Visible=not visible
    blur.Size=visible and settings.blur or 0
end
connect(closeBtn.MouseButton1Click,function()setVisible(false)end)
connect(mini.MouseButton1Click,function()setVisible(true)end)

-- Make the layout responsive without shrinking text until unreadable.
local function resize()
    local size=Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize or Vector2.new(1280,720)
    local small=size.X<760
    root.Size=small and UDim2.fromScale(1,1) or UDim2.fromScale(0.965,0.94)
    root.Position=UDim2.fromScale(0.5,0.5)
    sidebar.Size=UDim2.new(0,small and 66 or 218,1,-73)
    content.Position=UDim2.fromOffset(small and 66 or 218,73)
    content.Size=UDim2.new(1,small and -66 or -218,1,-73)
    for _,data in pairs(tabButtons) do
        data.label.Visible=not small
        data.button.Size=UDim2.new(1,0,0,54)
        local ico=data.button:FindFirstChildOfClass("Frame")
        -- the first frame is the active strip; icon has its own position already
    end
    brandMark.Position=UDim2.fromOffset(small and 13 or 26,18)
    local labelBrand=root:FindFirstChild("__unused")
    badge.Visible=not small
    sideFooter.Visible=not small
    for _,pg in pairs(pages) do
        local pad=pg.page:FindFirstChildOfClass("UIPadding")
        if pad then pad.PaddingLeft=UDim.new(0,small and 13 or 32)
            pad.PaddingRight=UDim.new(0,small and 13 or 32) end
    end
    toastHolder.Size=UDim2.new(small and 0.9 or 0, small and 0 or 420,0,54)
end
resize()
if camera then connect(camera:GetPropertyChangedSignal("ViewportSize"),resize) end

-- Role detection is authoritative only if your own game sets MM2Role / Role attributes.
-- Tool-based inference is a visual hint, not a reliable remote-player role API.
local function roleFor(p)
    for _, key in ipairs({"MM2Role","Role","RoleType"}) do
        local s=p:GetAttribute(key)
        if typeof(s)=="string" then
            s=s:lower()
            if s:find("murder") then return "murderer" end
            if s:find("sheriff") or s:find("hero") then return "sheriff" end
            if s:find("innocent") then return "innocent" end
        end
    end
    local ch=p.Character
    if ch then
        for _,tool in ipairs(ch:GetChildren()) do
            if tool:IsA("Tool") then
                local n=tool.Name:lower()
                if n:find("knife") then return "murderer" end
                if n:find("gun") or n:find("revolver") then return "sheriff" end
            end
        end
    end
    -- Do not label unknown players innocent: nothing here confirms their role.
    return nil
end
local function clearOverlay(obj)
    local e=overlays[obj]
    if e then for _,part in ipairs(e.parts) do part:Destroy() end;overlays[obj]=nil end
end
local function addOverlay(ch,color,label)
    local s=make("SelectionBox",{Adornee=ch,Color3=color,
        LineThickness=settings.outline,SurfaceTransparency=1},camera or Workspace)
    local h=make("Highlight",{Adornee=ch,FillColor=color,
        OutlineColor=color,FillTransparency=0.85,OutlineTransparency=0.13,
        DepthMode=Enum.HighlightDepthMode.AlwaysOnTop},camera or Workspace)
    local parts={s,h}
    if toggles.showNames then
        local head=ch:FindFirstChild("Head")
        if head then
            local bb=make("BillboardGui",{Adornee=head,AlwaysOnTop=true,
                Size=UDim2.fromOffset(150,27),StudsOffset=Vector3.new(0,2.65,0)},camera or Workspace)
            txt(bb,label,12,color,Enum.Font.GothamBold,UDim2.new(),UDim2.fromScale(1,1),Enum.TextXAlignment.Center)
            table.insert(parts,bb)
        end
    end
    overlays[ch]={color=color,parts=parts}
end
local function scanEsp()
    if not alive then return end
    local seen={}
    for _,p in ipairs(Players:GetPlayers()) do
        local ch=p.Character
        if p~=player and ch and ch.Parent and ch:FindFirstChildOfClass("Humanoid") then
            local role=roleFor(p)
            local enabled=role and toggles[role]
            if enabled then
                seen[ch]=true
                local color=(role=="murderer" and P.red) or (role=="sheriff" and P.blue) or P.green
                local found=overlays[ch]
                if not found or found.color~=color or found.withNames~=toggles.showNames then
                    clearOverlay(ch);addOverlay(ch,color,p.DisplayName)
                    overlays[ch].withNames=toggles.showNames
                end
            end
        end
    end
    for ch,v in pairs(overlays) do if not v.isGun and not seen[ch] then clearOverlay(ch) end end
    -- Live-client hitbox preview: displays a box, never claims enlarged hit detection.
    local target=targetFromCrosshair(nil,settings.aimRadius)
    local targetRoot=target and target.Character and target.Character:FindFirstChild("HumanoidRootPart")
    if toggles.hitbox and targetRoot then
        if not selfHitbox or selfHitbox.Adornee~=targetRoot then
            if selfHitbox then selfHitbox:Destroy() end
            selfHitbox=make("BoxHandleAdornment",{Adornee=targetRoot,AlwaysOnTop=true,
                Color3=P.purple,Transparency=0.77,ZIndex=1},camera or Workspace)
        end
        local n=settings.hitboxSize or 5
        selfHitbox.Size=Vector3.new(n,n*1.35,n)
    elseif selfHitbox then
        selfHitbox:Destroy();selfHitbox=nil
    end
    -- Drop scanner: identifies unheld gun objects by name/Tool in Workspace.
    if toggles.gun then
        local checked=0
        for _,inst in ipairs(Workspace:GetDescendants()) do
            checked=checked+1
            if checked>9000 then break end
            local n=string.lower(inst.Name)
            local isGun=(n=="gundrop" or n=="droppedgun" or n=="gun_drop" or n=="dropped gun"
                or (inst:IsA("Tool") and (n=="gun" or n=="revolver") and not underPlayerCharacter(inst)))
            if isGun and not underPlayerCharacter(inst) then
                local adornee=inst:IsA("Tool") and (inst:FindFirstChild("Handle") or inst:FindFirstChildWhichIsA("BasePart")) or inst
                if adornee and (adornee:IsA("BasePart") or adornee:IsA("Model")) then
                    seen[inst]=true
                    if not overlays[inst] then
                        addOverlay(adornee,P.green,"DROPPED GUN")
                        if inst~=adornee then
                            overlays[inst]=overlays[adornee]
                            overlays[adornee]=nil
                        end
                        if overlays[inst] then overlays[inst].isGun=true end
                    end
                end
            end
        end
    end
    for inst,v in pairs(overlays) do
        if v.isGun and not seen[inst] then clearOverlay(inst) end
    end
end
local elapsed, pulseTime=0,0
connect(RunService.Heartbeat,function(dt)
    elapsed=elapsed+dt;pulseTime=pulseTime+dt
    if elapsed>1.1 then elapsed=0;scanEsp() end
    -- Smooth and reapply after character respawns; server anti-cheat can override.
    local hum=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health>0 then
        if originalHumanoidSpeeds[hum]==nil then originalHumanoidSpeeds[hum]=hum.WalkSpeed end
        local goalSpeed=toggles.speed and settings.speed or originalHumanoidSpeeds[hum]
        if math.abs(hum.WalkSpeed-goalSpeed)>0.06 then
            hum.WalkSpeed=hum.WalkSpeed+(goalSpeed-hum.WalkSpeed)*math.clamp(dt*7,0,1)
        end
    end
    local cam=Workspace.CurrentCamera
    if cam then
        local goalFov=toggles.fov and settings.fov or cameraStartFov
        if math.abs(cam.FieldOfView-goalFov)>0.08 then
            cam.FieldOfView=cam.FieldOfView+(goalFov-cam.FieldOfView)*math.clamp(dt*7,0,1)
        end
    end
    if toggles.aimAssist and cam then
        local t=targetFromCrosshair("murderer",settings.aimRadius)
        if t then lookAtPlayer(t,math.clamp(settings.aimSmooth*dt,0,0.3)) end
    end
    if toggles.autoThrow and os.clock()-lastThrow>=settings.throwDelay then
        if localRole()=="murderer" or findTool("knife") then throwAtCrosshair() end
    end
    local wave=0.5+0.5*math.sin(pulseTime*2.6*settings.pulse)
    for _,v in pairs(overlays) do
        local sel=v.parts[1];local hl=v.parts[2]
        sel.Color3=v.color:Lerp(P.text,0.22*wave)
        sel.LineThickness=settings.outline+(0.02*wave)
        hl.OutlineColor=v.color:Lerp(P.text,0.2*wave)
        hl.FillTransparency=0.83+0.12*wave
    end

end)

connect(UserInputService.InputBegan,function(input,processed)
    if listeningForBind and input.UserInputType==Enum.UserInputType.Keyboard then
        if input.KeyCode~=Enum.KeyCode.Unknown then
            local collision=false
            for id,code in pairs(binds) do
                if id~=listeningForBind and code==input.KeyCode then collision=true end
            end
            if collision then notify("Эта клавиша уже назначена")
            else binds[listeningForBind]=input.KeyCode
                bindButtons[listeningForBind].Text=input.KeyCode.Name
                notify("Бинд изменён: "..input.KeyCode.Name)
                listeningForBind=nil end
        end
        return
    end
    if processed then return end
    if input.UserInputType~=Enum.UserInputType.Keyboard then return end
    if input.KeyCode==binds.menu then setVisible(not screenShade.Visible);return end
    if UserInputService:GetFocusedTextBox() then return end
    if input.KeyCode==binds.sheriff then sheriffShot(false)
    elseif input.KeyCode==binds.silent then sheriffShot(true)
    elseif input.KeyCode==binds.throw then throwAtCrosshair() end
end)


-- Optional session cleanup; called automatically if a new copy is launched.
local function shutdown()
    if not alive then return end
    alive=false
    for _,c in ipairs(connections) do pcall(function()c:Disconnect()end) end
    for ch in pairs(overlays) do clearOverlay(ch) end
    if selfHitbox then selfHitbox:Destroy();selfHitbox=nil end
    restorePotato()
    if potatoBlurEffect then potatoBlurEffect:Destroy() end
    for hum, original in pairs(originalHumanoidSpeeds) do
        pcall(function()if hum.Parent then hum.WalkSpeed=original end end)
    end
    pcall(function()if Workspace.CurrentCamera then Workspace.CurrentCamera.FieldOfView=cameraStartFov end end)
    blur:Destroy();gui:Destroy()
end
global.NOXERING_AETHER_SHUTDOWN=shutdown
notify("NOXERING AETHER loaded  •  Right Ctrl: menu")
