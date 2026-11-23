-- AETHER / BLADE BALL V1
-- Client-side visual & auto-parry overlay. RightShift = menu.
-- One standalone Luau file; no third-party loadstrings or network downloads.
-- The auto-parry routine uses input simulation; support varies by client/executor/game update.

if not game:IsLoaded() then game.Loaded:Wait() end
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")
local LP = Players.LocalPlayer
if not LP then return end

local ENV = (type(getgenv) == "function" and getgenv()) or _G
if ENV.AETHER_BLADE_BALL and type(ENV.AETHER_BLADE_BALL.Destroy) == "function" then
    pcall(ENV.AETHER_BLADE_BALL.Destroy)
end

local COLORS = {
    bg = Color3.fromRGB(13, 13, 21),
    panel = Color3.fromRGB(23, 23, 34),
    surface = Color3.fromRGB(30, 30, 43),
    border = Color3.fromRGB(62, 60, 82),
    text = Color3.fromRGB(245, 244, 255),
    muted = Color3.fromRGB(139, 136, 159),
    accent = Color3.fromRGB(115, 85, 255),
    bright = Color3.fromRGB(175, 150, 255),
    red = Color3.fromRGB(255, 91, 120),
    green = Color3.fromRGB(93, 235, 174),
}
local settings = {
    AutoParry = false,
    StrictTarget = true,
    ParryPulse = true,
    ParryHint = true,
    BallGlow = true,
    BallTracer = false,
    Prediction = false,
    PlayerESP = false,
    Crosshair = true,
    Particles = false,
    FovRing = false,
    SidePanels = true,
    BallInfo = true,
    FPS = true,
    Keybinds = true,
    MenuAnimations = true,
    CustomFov = false,
    Performance = false,
    ParryRange = 28,
    PingLead = 55,
    Fov = 80,
}

local configFile = "aether_blade_ball_v1.json"
if type(readfile) == "function" and type(isfile) == "function" then
    pcall(function()
        if isfile(configFile) then
            local tbl = HttpService:JSONDecode(readfile(configFile))
            if type(tbl) == "table" then
                for k, value in pairs(tbl) do
                    if settings[k] ~= nil and type(settings[k]) == type(value) then
                        settings[k] = value
                    end
                end
            end
        end
    end)
end
local function save()
    if type(writefile) == "function" then
        pcall(function() writefile(configFile, HttpService:JSONEncode(settings)) end)
    end
end
local function make(class, parent, properties)
    local o = Instance.new(class)
    for k, value in pairs(properties or {}) do o[k] = value end
    o.Parent = parent
    return o
end
local function round(o, radius)
    return make("UICorner", o, {CornerRadius = UDim.new(0, radius or 12)})
end
local function border(o, color, alpha, thick)
    return make("UIStroke", o, {Color=color or COLORS.border, Transparency=alpha or 0.65, Thickness=thick or 1})
end
local function text(parent, string, size, color, bold, props)
    local o = make("TextLabel", parent, {
        BackgroundTransparency=1, Text=string, TextColor3=color or COLORS.text,
        TextSize=size or 13, Font=bold and Enum.Font.GothamBold or Enum.Font.Gotham,
        TextXAlignment=Enum.TextXAlignment.Left, TextYAlignment=Enum.TextYAlignment.Center,
    })
    for k,v in pairs(props or {}) do o[k] = v end
    return o
end
local function tween(obj, props, duration)
    if not obj or not obj.Parent then return end
    if settings.MenuAnimations then
        TweenService:Create(obj, TweenInfo.new(duration or .18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
    else
        for k,v in pairs(props) do obj[k] = v end
    end
end
local function getGuiParent()
    if type(gethui) == "function" then
        local success, gui = pcall(gethui)
        if success and typeof(gui) == "Instance" then return gui end
    end
    local success, gui = pcall(function() return game:GetService("CoreGui") end)
    if success and gui then return gui end
    return LP:WaitForChild("PlayerGui")
end

local allConnections = {}
local function connect(signal, callback)
    local c = signal:Connect(callback)
    table.insert(allConnections, c)
    return c
end
local alive = true
local originalShadows = Lighting.GlobalShadows
local originalFov = (Workspace.CurrentCamera and Workspace.CurrentCamera.FieldOfView) or 70
local gui = make("ScreenGui", getGuiParent(), {
    Name="AETHER_BLADE_BALL_V1", ResetOnSpawn=false, IgnoreGuiInset=true,
    DisplayOrder=109, ZIndexBehavior=Enum.ZIndexBehavior.Sibling,
})

-- Soft atmospheric glows, comparable to the purple translucent reference.
local shadow = make("Frame", gui, {
    Name="Backdrop", BackgroundColor3=Color3.fromRGB(7, 5, 16),
    BackgroundTransparency=.62, Size=UDim2.fromScale(1,1), Visible=true,
})
local window = make("Frame", gui, {
    Name="Window", BackgroundColor3=COLORS.bg, BackgroundTransparency=.07,
    AnchorPoint=Vector2.new(.5,.5), Position=UDim2.fromScale(.5,.5),
    Size=UDim2.fromOffset(780,474), ClipsDescendants=true,
})
round(window, 15)
border(window, Color3.fromRGB(98,82,150), .65)
make("UIGradient", window, {Rotation=110, Color=ColorSequence.new({
    ColorSequenceKeypoint.new(0,Color3.fromRGB(26,23,40)),
    ColorSequenceKeypoint.new(.55,Color3.fromRGB(14,14,22)),
    ColorSequenceKeypoint.new(1,Color3.fromRGB(23,19,38)),
})})
local top = make("Frame", window, {BackgroundTransparency=1, Active=true, Size=UDim2.new(1,0,0,70)})
text(top, "⌁", 28, COLORS.accent, true, {Position=UDim2.fromOffset(18,15), Size=UDim2.fromOffset(29,36)})
text(top, "AETHER", 18, COLORS.text, true, {Position=UDim2.fromOffset(52,13), Size=UDim2.fromOffset(150,27)})
text(top, "BLADE BALL  /  V1", 10, COLORS.muted, false, {Position=UDim2.fromOffset(53,35), Size=UDim2.fromOffset(175,18)})
local signalDot = make("Frame", top, {BackgroundColor3=COLORS.green, Position=UDim2.new(1,-175,0,30), Size=UDim2.fromOffset(7,7)})
round(signalDot, 99)
local onlineLabel = text(top, "CLIENT ACTIVE", 10, COLORS.muted, true, {Position=UDim2.new(1,-162,0,22), Size=UDim2.fromOffset(115,24)})
local exitButton = make("TextButton", top, {Text="×", TextSize=25, Font=Enum.Font.Gotham, TextColor3=COLORS.muted, BackgroundTransparency=1, Position=UDim2.new(1,-40,0,17), Size=UDim2.fromOffset(29,33)})
local separator = make("Frame", window, {BackgroundColor3=COLORS.border, BackgroundTransparency=.6, Position=UDim2.fromOffset(16,68), Size=UDim2.new(1,-32,0,1)})
local tabsFrame = make("Frame", window, {BackgroundTransparency=1, Position=UDim2.fromOffset(21,76), Size=UDim2.new(1,-42,0,42)})
local gridScroll = make("ScrollingFrame", window, {
    BackgroundTransparency=1, BorderSizePixel=0,
    Position=UDim2.fromOffset(20,125), Size=UDim2.new(1,-40,0,289),
    CanvasSize=UDim2.fromOffset(0,0), ScrollBarThickness=3,
    ScrollBarImageColor3=COLORS.accent, ScrollingDirection=Enum.ScrollingDirection.Y,
})
local listGrid = make("UIGridLayout", gridScroll, {
    CellSize=UDim2.new(.5,-9,0,60), CellPadding=UDim2.fromOffset(12,9),
    SortOrder=Enum.SortOrder.LayoutOrder,
})
local bottom = make("Frame", window, {BackgroundColor3=COLORS.panel, BackgroundTransparency=.45, Position=UDim2.new(0,0,1,-49), Size=UDim2.new(1,0,0,49)})
local statusText = text(bottom,"READY  ·  waiting for active ball",12,COLORS.muted,false,{Position=UDim2.fromOffset(23,0),Size=UDim2.new(1,-195,1,0)})
local hotkeyText = text(bottom,"RIGHT SHIFT   •   MENU",11,COLORS.bright,true,{Position=UDim2.new(1,-190,0,0),Size=UDim2.fromOffset(178,49),TextXAlignment=Enum.TextXAlignment.Right})

-- Overlay HUD cards: independent of the main menu, also visible with the menu closed.
local hudLeft = make("Frame", gui, {BackgroundColor3=COLORS.panel, BackgroundTransparency=.19, Position=UDim2.fromOffset(26,105), Size=UDim2.fromOffset(175,105)})
round(hudLeft,12); border(hudLeft)
local leftHeading = text(hudLeft,"✦   AETHER STATUS",11,COLORS.bright,true,{Position=UDim2.fromOffset(12,10),Size=UDim2.fromOffset(155,18)})
local leftMode = text(hudLeft,"AUTO PARRY  OFF",13,COLORS.muted,true,{Position=UDim2.fromOffset(12,36),Size=UDim2.fromOffset(158,20)})
local leftDistance = text(hudLeft,"BALL  -- studs",11,COLORS.text,false,{Position=UDim2.fromOffset(12,60),Size=UDim2.fromOffset(156,18)})
local leftTarget = text(hudLeft,"TARGET  --",10,COLORS.muted,false,{Position=UDim2.fromOffset(12,81),Size=UDim2.fromOffset(156,15)})
local hudRight = make("Frame", gui, {BackgroundColor3=COLORS.panel, BackgroundTransparency=.19, AnchorPoint=Vector2.new(1,0), Position=UDim2.new(1,-24,0,104), Size=UDim2.fromOffset(165,87)})
round(hudRight,12); border(hudRight)
text(hudRight,"◇   PERFORMANCE",11,COLORS.bright,true,{Position=UDim2.fromOffset(12,10),Size=UDim2.fromOffset(150,20)})
local fpsLabel = text(hudRight,"FPS   --",11,COLORS.text,true,{Position=UDim2.fromOffset(12,38),Size=UDim2.fromOffset(145,18)})
local pingLabel = text(hudRight,"PING  -- ms",11,COLORS.text,true,{Position=UDim2.fromOffset(12,59),Size=UDim2.fromOffset(145,18)})
local keyCard = make("Frame", gui, {BackgroundColor3=COLORS.panel, BackgroundTransparency=.15, AnchorPoint=Vector2.new(1,1), Position=UDim2.new(1,-24,1,-31), Size=UDim2.fromOffset(165,72)})
round(keyCard,12); border(keyCard)
text(keyCard,"⌨   KEYBINDS",11,COLORS.bright,true,{Position=UDim2.fromOffset(12,8),Size=UDim2.fromOffset(140,20)})
text(keyCard,"Menu",11,COLORS.muted,false,{Position=UDim2.fromOffset(12,33),Size=UDim2.fromOffset(70,16)})
text(keyCard,"RSHIFT",10,COLORS.text,true,{Position=UDim2.fromOffset(102,33),Size=UDim2.fromOffset(55,16)})
text(keyCard,"Parry",11,COLORS.muted,false,{Position=UDim2.fromOffset(12,52),Size=UDim2.fromOffset(70,16)})
text(keyCard,"F / CLICK",10,COLORS.text,true,{Position=UDim2.fromOffset(91,52),Size=UDim2.fromOffset(67,16)})

local crosshair = make("Frame",gui,{BackgroundTransparency=1,AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(50,50)})
local crossParts = {
    {UDim2.fromOffset(23,2), UDim2.fromOffset(2,16)},
    {UDim2.fromOffset(23,33), UDim2.fromOffset(2,16)},
    {UDim2.fromOffset(2,23), UDim2.fromOffset(16,2)},
    {UDim2.fromOffset(33,23), UDim2.fromOffset(16,2)},
}
for _, item in ipairs(crossParts) do
    local f=make("Frame",crosshair,{BackgroundColor3=COLORS.bright,BorderSizePixel=0,Position=item[1],Size=item[2]})
    round(f,3)
end
local ring = make("Frame",gui,{BackgroundTransparency=1,AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(310,310)})
round(ring,999); border(ring,COLORS.bright,.4,2)
local pulse = make("Frame",gui,{BackgroundTransparency=1,AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(50,50),Visible=false})
round(pulse,999)
local pulseStroke=border(pulse,COLORS.accent,0,3)

local currentBall, ballHighlight, ballBillboard, ballLine, rootAttach, ballAttach, predictionOrb, playerOutlines, aura = nil,nil,nil,nil,nil,nil,nil,{},nil
local lastParryClock, lastParriedBall, attempts, lastStatus, totalFrames, frameSum = 0,nil,0,"",0,0
local menuVisible = true
local function clearVisuals()
    for _,obj in ipairs({ballHighlight,ballBillboard,ballLine,rootAttach,ballAttach,predictionOrb,aura}) do
        if obj then pcall(function() obj:Destroy() end) end
    end
    ballHighlight,ballBillboard,ballLine,rootAttach,ballAttach,predictionOrb,aura=nil,nil,nil,nil,nil,nil,nil
    for _,v in pairs(playerOutlines) do pcall(function() v:Destroy() end) end
    playerOutlines={}
end
local function getRoot()
    local c=LP.Character
    return c and c:FindFirstChild("HumanoidRootPart"),c
end
local function getBall()
    local folder=Workspace:FindFirstChild("Balls")
    if not folder then return nil end
    local fallback=nil
    for _, b in ipairs(folder:GetChildren()) do
        if b:IsA("BasePart") then
            if b:GetAttribute("realBall") == true then return b end
            if not fallback and b:GetAttribute("realBall") ~= false and (b.Name:lower():find("ball") or b:GetAttribute("target") ~= nil) then fallback=b end
        end
    end
    return fallback
end
local function getVelocity(ball)
    if not ball then return Vector3.zero end
    local zoomies=ball:FindFirstChild("zoomies")
    if zoomies and zoomies:IsA("LinearVelocity") then
        local v=zoomies.VectorVelocity
        if v.Magnitude > 3 then return v end
    end
    return ball.AssemblyLinearVelocity
end
local function targeted(ball, character)
    if not ball then return false,"No ball" end
    local t=ball:GetAttribute("target")
    if t ~= nil then
        if typeof(t)=="Instance" then return t==LP, tostring(t) end
        local str=tostring(t)
        local mine=(str==LP.Name or str==LP.DisplayName or str==tostring(LP.UserId))
        return mine,str
    end
    -- Several versions indicate the victim with a red character highlight.
    if character then
        for _,h in ipairs(character:GetChildren()) do
            if h:IsA("Highlight") and h ~= playerOutlines[LP] then
                local color=h.FillColor
                if color.R > color.G * 1.4 and color.R > color.B * 1.2 then
                    return true,"Highlight"
                end
            end
        end
    end
    return false,"Unknown"
end
local function simulateParry()
    -- F is the game's ordinary parry control. No undocumented server remotes.
    if type(keypress)=="function" and type(keyrelease)=="function" then
        local ok=pcall(function()
            keypress(0x46)
            task.delay(.045,function() pcall(keyrelease,0x46) end)
        end)
        if ok then return true end
    end
    local ok, service=pcall(function() return game:GetService("VirtualInputManager") end)
    if ok and service then
        local worked=pcall(function()
            service:SendKeyEvent(true,Enum.KeyCode.F,false,game)
            task.delay(.045,function() pcall(function() service:SendKeyEvent(false,Enum.KeyCode.F,false,game) end) end)
        end)
        if worked then return true end
    end
    if type(mouse1click)=="function" then return pcall(mouse1click) end
    return false
end
local function showPulse()
    if not settings.ParryPulse then return end
    pulse.Visible=true
    pulse.Size=UDim2.fromOffset(38,38)
    pulseStroke.Transparency=.1
    tween(pulse,{Size=UDim2.fromOffset(190,190)},.34)
    tween(pulseStroke,{Transparency=1},.34)
    task.delay(.38,function() if pulse and pulse.Parent then pulse.Visible=false end end)
end
local function newBillboard(ball)
    ballBillboard=make("BillboardGui",gui.Parent,{Adornee=ball,AlwaysOnTop=true,Size=UDim2.fromOffset(155,48),StudsOffsetWorldSpace=Vector3.new(0,4,0)})
    local bg=make("Frame",ballBillboard,{Size=UDim2.fromScale(1,1),BackgroundColor3=COLORS.bg,BackgroundTransparency=.24})
    round(bg,9);border(bg)
    text(bg,"◈   ACTIVE BALL",11,COLORS.bright,true,{Position=UDim2.fromOffset(10,4),Size=UDim2.fromOffset(139,19)})
    local value=text(bg,"-- studs   /   -- speed",10,COLORS.text,false,{Position=UDim2.fromOffset(10,25),Size=UDim2.fromOffset(137,16)})
    return value
end
local ballDataText=nil
local function updateBallVisuals(ball,root,vel,dist)
    if ball~=currentBall then
        for _, obj in ipairs({ballHighlight,ballBillboard,ballLine,rootAttach,ballAttach,predictionOrb}) do
            if obj then pcall(function() obj:Destroy() end) end
        end
        currentBall=ball
        ballHighlight,ballBillboard,ballLine,rootAttach,ballAttach,predictionOrb=nil,nil,nil,nil,nil,nil
        ballDataText=nil
        lastParriedBall=nil
    end
    if not ball then return end
    if settings.BallGlow then
        if not ballHighlight then
            ballHighlight=make("Highlight",Workspace.CurrentCamera or Workspace,{Adornee=ball,FillColor=COLORS.accent,OutlineColor=COLORS.bright,FillTransparency=.55,OutlineTransparency=0,DepthMode=Enum.HighlightDepthMode.AlwaysOnTop})
        end
    elseif ballHighlight then ballHighlight:Destroy();ballHighlight=nil end
    if settings.BallInfo then
        if not ballBillboard then ballDataText=newBillboard(ball) end
        if ballDataText then ballDataText.Text=string.format("%.0f studs   /   %.0f speed",dist or 0,vel.Magnitude) end
    elseif ballBillboard then ballBillboard:Destroy();ballBillboard=nil;ballDataText=nil end
    if settings.BallTracer and root then
        if not ballLine or not rootAttach or rootAttach.Parent~=root then
            for _,obj in ipairs({ballLine,ballAttach,rootAttach}) do if obj then obj:Destroy() end end
            ballAttach=make("Attachment",ball,{Name="AetherBallTrail"})
            rootAttach=make("Attachment",root,{Name="AetherRootTrail"})
            ballLine=make("Beam",ball,{
                Attachment0=ballAttach,Attachment1=rootAttach,FaceCamera=true,
                Width0=.13,Width1=.04,LightEmission=1,
                Color=ColorSequence.new(COLORS.bright,COLORS.accent),
                Transparency=NumberSequence.new(.13),
            })
        end
    elseif ballLine then
        ballLine:Destroy();ballLine=nil
        if ballAttach then ballAttach:Destroy();ballAttach=nil end
        if rootAttach then rootAttach:Destroy();rootAttach=nil end
    end
    if settings.Prediction then
        if not predictionOrb then
            predictionOrb=make("Part",Workspace.CurrentCamera or Workspace,{
                Name="AetherPrediction",Shape=Enum.PartType.Ball,Size=Vector3.new(1.7,1.7,1.7),
                Material=Enum.Material.Neon,Color=COLORS.accent,Transparency=.3,
                CanCollide=false,CanTouch=false,CanQuery=false,Anchored=true,CastShadow=false,
            })
        end
        predictionOrb.Position=ball.Position+vel*.22
    elseif predictionOrb then predictionOrb:Destroy();predictionOrb=nil end
end
local function updatePlayers()
    if not settings.PlayerESP then
        for _,h in pairs(playerOutlines) do pcall(function() h:Destroy() end) end
        playerOutlines={}
        return
    end
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LP then
            local c=p.Character
            local existing=playerOutlines[p]
            if c and c:FindFirstChildOfClass("Humanoid") then
                if not existing or existing.Adornee~=c then
                    if existing then existing:Destroy() end
                    playerOutlines[p]=make("Highlight",Workspace.CurrentCamera or Workspace,{Adornee=c,FillColor=COLORS.accent,FillTransparency=.77,OutlineColor=COLORS.bright,OutlineTransparency=.06,DepthMode=Enum.HighlightDepthMode.AlwaysOnTop})
                end
            elseif existing then existing:Destroy();playerOutlines[p]=nil end
        end
    end
    for p,h in pairs(playerOutlines) do
        if p.Parent~=Players then h:Destroy();playerOutlines[p]=nil end
    end
end
local function updateAura(root)
    if not settings.Particles or not root then
        if aura then aura:Destroy();aura=nil end
        return
    end
    if not aura or aura.Parent~=root then
        if aura then aura:Destroy() end
        aura=make("ParticleEmitter",root,{
            Name="AetherParticleAura",Rate=18,EmissionDirection=Enum.NormalId.Top,
            Lifetime=NumberRange.new(.4,.85),Speed=NumberRange.new(.2,1.4),
            SpreadAngle=Vector2.new(75,75),LightEmission=.8,
            Size=NumberSequence.new({NumberSequenceKeypoint.new(0,.16),NumberSequenceKeypoint.new(1,0)}),
            Color=ColorSequence.new(COLORS.bright,COLORS.accent),
            Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.25),NumberSequenceKeypoint.new(1,1)})
        })
    end
end
local function refreshHud()
    hudLeft.Visible=settings.SidePanels
    hudRight.Visible=settings.FPS
    keyCard.Visible=settings.Keybinds
    crosshair.Visible=settings.Crosshair
    ring.Visible=settings.FovRing
    leftMode.Text=settings.AutoParry and "AUTO PARRY  ON" or "AUTO PARRY  OFF"
    leftMode.TextColor3=settings.AutoParry and COLORS.green or COLORS.muted
    Lighting.GlobalShadows=settings.Performance and false or originalShadows
    local cam=Workspace.CurrentCamera
    if cam then cam.FieldOfView=settings.CustomFov and settings.Fov or originalFov end
end

local tabs={"Combat","Visuals","HUD","Utilities"}
local tabButtons={}
local currentTab="Combat"
local tabItems={
    Combat={
        {"Auto Parry","Predictive F-key timing", "AutoParry"},
        {"Strict Target","Only defend when you're targeted", "StrictTarget"},
        {"Parry Pulse","Purple circle after a parry", "ParryPulse"},
        {"Parry Hint","Show targeting status", "ParryHint"},
        {"Parry Range","Distance cap · studs", "ParryRange", 12,55,1},
        {"Ping Compensation","Reaction lead · milliseconds", "PingLead",0,180,5},
    },
    Visuals={
        {"Ball Glow","Violet ball highlight", "BallGlow"},
        {"Ball Tracer","Beam from you to the ball", "BallTracer"},
        {"Prediction Orb","Projected ball position", "Prediction"},
        {"Player Outline","Local player highlights", "PlayerESP"},
        {"Crosshair","Minimal center reticle", "Crosshair"},
        {"Particles","Purple floating particles", "Particles"},
        {"FOV Ring","Centered outline overlay", "FovRing"},
        {"Camera FOV","Use custom camera FOV", "CustomFov"},
    },
    HUD={
        {"Status Panel","Ball / parry data on the left", "SidePanels"},
        {"Ball Info","Speed and distance over ball", "BallInfo"},
        {"FPS + Ping","Performance panel", "FPS"},
        {"Keybinds","Hotkey reference panel", "Keybinds"},
    },
    Utilities={
        {"Performance Mode","Disable world shadows locally", "Performance"},
        {"Menu Animations","Smooth interface transitions", "MenuAnimations"},
        {"Camera FOV","Custom field of view", "CustomFov"},
        {"FOV Amount","Field of view in degrees", "Fov",60,110,1},
    },
}

local function toggleClick(key)
    settings[key]=not settings[key]
    save()
    refreshHud()
end
local function addToggle(data, order)
    local title,description,key=data[1],data[2],data[3]
    local box=make("Frame",gridScroll,{BackgroundColor3=COLORS.surface,BackgroundTransparency=.17,LayoutOrder=order})
    round(box,9)
    local boxBorder=border(box,COLORS.border,.72)
    text(box,title,12,COLORS.text,true,{Position=UDim2.fromOffset(14,8),Size=UDim2.new(1,-90,0,23)})
    text(box,description,10,COLORS.muted,false,{Position=UDim2.fromOffset(14,30),Size=UDim2.new(1,-80,0,20),TextTruncate=Enum.TextTruncate.AtEnd})
    local button=make("TextButton",box,{Text="",BackgroundColor3=settings[key] and COLORS.accent or Color3.fromRGB(63,63,82),Position=UDim2.new(1,-54,0,18),Size=UDim2.fromOffset(40,23),AutoButtonColor=false})
    round(button,99)
    local knob=make("Frame",button,{BackgroundColor3=Color3.fromRGB(247,244,255),Position=settings[key] and UDim2.fromOffset(21,3) or UDim2.fromOffset(3,3),Size=UDim2.fromOffset(17,17)})
    round(knob,99)
    connect(button.MouseButton1Click,function()
        toggleClick(key)
        tween(button,{BackgroundColor3=settings[key] and COLORS.accent or Color3.fromRGB(63,63,82)})
        tween(knob,{Position=settings[key] and UDim2.fromOffset(21,3) or UDim2.fromOffset(3,3)})
        tween(boxBorder,{Color=settings[key] and COLORS.accent or COLORS.border,Transparency=settings[key] and .45 or .72})
    end)
    if settings[key] then boxBorder.Color=COLORS.accent;boxBorder.Transparency=.45 end
end
local function addSlider(data, order)
    local title,description,key,lo,hi,step=data[1],data[2],data[3],data[4],data[5],data[6]
    local box=make("Frame",gridScroll,{BackgroundColor3=COLORS.surface,BackgroundTransparency=.17,LayoutOrder=order})
    round(box,9);border(box)
    text(box,title,12,COLORS.text,true,{Position=UDim2.fromOffset(14,6),Size=UDim2.new(1,-85,0,18)})
    local valueText=text(box,tostring(settings[key]),11,COLORS.bright,true,{Position=UDim2.new(1,-66,0,6),Size=UDim2.fromOffset(50,18),TextXAlignment=Enum.TextXAlignment.Right})
    local track=make("Frame",box,{BackgroundColor3=Color3.fromRGB(64,62,85),Position=UDim2.fromOffset(14,42),Size=UDim2.new(1,-28,0,5)})
    round(track,9)
    local fill=make("Frame",track,{BackgroundColor3=COLORS.accent,Size=UDim2.fromScale((settings[key]-lo)/(hi-lo),1)})
    round(fill,9)
    local drag=make("TextButton",track,{Text="",AutoButtonColor=false,BackgroundTransparency=1,Size=UDim2.new(1,0,0,24),Position=UDim2.fromOffset(0,-9)})
    local dragging=false
    local function update(x)
        local ratio=math.clamp((x-track.AbsolutePosition.X)/math.max(1,track.AbsoluteSize.X),0,1)
        local value=math.clamp(math.floor((lo+ratio*(hi-lo))/step+.5)*step,lo,hi)
        settings[key]=value
        fill.Size=UDim2.fromScale((value-lo)/(hi-lo),1)
        valueText.Text=tostring(value)
        refreshHud()
    end
    connect(drag.InputBegan,function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
            dragging=true;update(input.Position.X)
        end
    end)
    connect(UIS.InputChanged,function(input)
        if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then update(input.Position.X) end
    end)
    connect(UIS.InputEnded,function(input)
        if dragging and (input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch) then dragging=false;save() end
    end)
end
local function renderTab(name)
    currentTab=name
    for _,child in ipairs(gridScroll:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    for tab,button in pairs(tabButtons) do
        tween(button,{TextColor3=tab==name and COLORS.text or COLORS.muted,BackgroundColor3=tab==name and COLORS.surface or COLORS.bg})
    end
    local entries=tabItems[name]
    for order,entry in ipairs(entries) do
        if type(entry[4])=="number" then addSlider(entry,order) else addToggle(entry,order) end
    end
    gridScroll.CanvasSize=UDim2.fromOffset(0,math.ceil(#entries/2)*69+8)
    gridScroll.CanvasPosition=Vector2.zero
end
for i,name in ipairs(tabs) do
    local button=make("TextButton",tabsFrame,{
        Text=name,TextColor3=COLORS.muted,TextSize=12,Font=Enum.Font.GothamBold,
        BackgroundColor3=COLORS.bg,BackgroundTransparency=.33,
        Position=UDim2.fromOffset((i-1)*116,1),Size=UDim2.fromOffset(105,36),AutoButtonColor=false,
    })
    round(button,8)
    tabButtons[name]=button
    connect(button.MouseButton1Click,function() renderTab(name) end)
end
renderTab("Combat")

-- Drag from the title bar, not from switches or sliders.
local draggingWindow=false
local dragMouse,dragPosition
connect(top.InputBegan,function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
        draggingWindow=true;dragMouse=input.Position;dragPosition=window.Position
    end
end)
connect(UIS.InputChanged,function(input)
    if draggingWindow and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
        local offset=input.Position-dragMouse
        window.Position=UDim2.new(dragPosition.X.Scale,dragPosition.X.Offset+offset.X,dragPosition.Y.Scale,dragPosition.Y.Offset+offset.Y)
    end
end)
connect(UIS.InputEnded,function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then draggingWindow=false end
end)
local function setMenu(value)
    menuVisible=value
    window.Visible=value;shadow.Visible=value
end
connect(exitButton.MouseButton1Click,function() setMenu(false) end)
connect(UIS.InputBegan,function(input)
    if input.KeyCode==Enum.KeyCode.RightShift and not UIS:GetFocusedTextBox() then
        setMenu(not menuVisible)
    end
end)

local function getPingMs()
    local ok,value=pcall(function() return LP:GetNetworkPing()*1000 end)
    if ok and type(value)=="number" then return math.floor(value+.5) end
    return 0
end
local tickGap=0
local espGap=0
local fpsGap=0
connect(RunService.Heartbeat,function(dt)
    if not alive then return end
    totalFrames=totalFrames+1;frameSum=frameSum+dt;fpsGap=fpsGap+dt
    if fpsGap>.55 then
        fpsLabel.Text=string.format("FPS   %d",math.floor(totalFrames/math.max(.01,frameSum)+.5))
        pingLabel.Text=string.format("PING  %d ms",getPingMs())
        totalFrames=0;frameSum=0;fpsGap=0
    end
    tickGap=tickGap+dt
    espGap=espGap+dt
    if espGap>.65 then espGap=0;updatePlayers() end
    if tickGap<.045 then return end
    tickGap=0
    local root,character=getRoot()
    local ball=getBall()
    local vel=getVelocity(ball)
    local distance=(root and ball) and (root.Position-ball.Position).Magnitude or 0
    updateBallVisuals(ball,root,vel,distance)
    updateAura(root)
    crosshair.Visible=settings.Crosshair
    ring.Visible=settings.FovRing
    local cam=Workspace.CurrentCamera
    if settings.CustomFov and cam then cam.FieldOfView=settings.Fov end
    if not ball or not root then
        statusText.Text="WAITING  ·  no active ball / character"
        leftDistance.Text="BALL  -- studs"
        leftTarget.Text="TARGET  --"
        return
    end
    local isTarget,targetName=targeted(ball,character)
    local diff=root.Position-ball.Position
    local closingSpeed=distance>0 and vel:Dot(diff.Unit) or 0
    local tti=closingSpeed>1 and distance/closingSpeed or math.huge
    local ping=getPingMs()
    local lead=math.clamp(.15 + settings.PingLead/1000 + ping/1800,.13,.45)
    local effectiveRange=math.min(settings.ParryRange,math.max(10,vel.Magnitude*lead+3))
    local approach=closingSpeed>8 and closingSpeed>vel.Magnitude*.16
    local eligible=(isTarget or not settings.StrictTarget) and approach
    local doIt=settings.AutoParry and eligible and tti<=lead and distance<=effectiveRange
    local now=os.clock()
    if doIt and (now-lastParryClock)>.72 then
        if simulateParry() then
            lastParryClock=now;lastParriedBall=ball;attempts=attempts+1
            showPulse()
        else
            statusText.Text="INPUT NOT AVAILABLE  ·  executor must support keypress"
        end
    end
    leftDistance.Text=string.format("BALL  %.0f studs",distance)
    leftTarget.Text="TARGET  "..(isTarget and "YOU" or targetName)
    if settings.ParryHint then
        if isTarget then
            statusText.Text=string.format("TARGETED  ·  ball %.0f studs   ·   ETA %.2f s   ·   attempts %d",distance,math.min(tti,99),attempts)
        else
            statusText.Text=string.format("TRACKING  ·  ball %.0f studs   ·   target %s",distance,tostring(targetName))
        end
    else
        statusText.Text="ACTIVE   ·   AETHER visual modules running"
    end
end)

local function destroy()
    if not alive then return end
    alive=false
    for _,connection in ipairs(allConnections) do pcall(function() connection:Disconnect() end) end
    clearVisuals()
    Lighting.GlobalShadows=originalShadows
    if Workspace.CurrentCamera then Workspace.CurrentCamera.FieldOfView=originalFov end
    pcall(function() gui:Destroy() end)
    if ENV.AETHER_BLADE_BALL and ENV.AETHER_BLADE_BALL.Destroy==destroy then
        ENV.AETHER_BLADE_BALL=nil
    end
end
ENV.AETHER_BLADE_BALL={Destroy=destroy,Settings=settings}
refreshHud()
print("[AETHER BLADE BALL] Loaded. RightShift = open / close. Auto Parry is OFF until enabled.")
