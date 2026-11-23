-- AETHER / BLADE BALL V4 • screenshot-inspired violet glass UI
-- RightShift toggles menu. Local visuals + frame-speed predictive practice parry.
-- Roblox does not render raw SVG in ImageLabel: icons below are vector primitives.
-- No anticheat bypass, spoofing, tampering with server remotes, or ban guarantees.

if not game:IsLoaded() then game.Loaded:Wait() end
local Players = game:GetService('Players')
local RunService = game:GetService('RunService')
local UIS = game:GetService('UserInputService')
local TS = game:GetService('TweenService')
local Lighting = game:GetService('Lighting')
local Workspace = game:GetService('Workspace')
local HttpService = game:GetService('HttpService')
local LP = Players.LocalPlayer
if not LP then return end
local ENV = (type(getgenv)=='function' and getgenv()) or _G
if ENV.AETHER_BLADE_BALL and type(ENV.AETHER_BLADE_BALL.Destroy)=='function' then
    pcall(ENV.AETHER_BLADE_BALL.Destroy)
end

local C = {
    black=Color3.fromRGB(9,9,16), main=Color3.fromRGB(15,14,23),
    raised=Color3.fromRGB(24,23,34), hover=Color3.fromRGB(31,29,44),
    stroke=Color3.fromRGB(57,53,78), muted=Color3.fromRGB(115,111,137),
    low=Color3.fromRGB(79,75,101), text=Color3.fromRGB(244,243,255),
    violet=Color3.fromRGB(121,87,255), lilac=Color3.fromRGB(177,155,255),
    green=Color3.fromRGB(103,228,164), red=Color3.fromRGB(255,104,130),
    off=Color3.fromRGB(49,48,67), white=Color3.fromRGB(251,249,255)
}
local cfg = {
    AutoParry=false, StrictTarget=true, TrajectoryAssist=true, FastReaction=true, MouseParry=false, ParryPulse=true, ParryHint=true,
    ParryRange=29, PingLead=55,
    BallGlow=true, BallTracer=false, Prediction=false, PlayerESP=false,
    Crosshair=true, Particles=false, FullBright=false, FovRing=false,
    HitColor=false, JumpCircles=false, BallInfo=true, ScopeOverlay=false,
    CameraTrail=false, RenderTweaks=false,
    SidePanels=true, Keybinds=true, FPS=true, DeathMarker=true,
    MenuAnimations=true, BlurOnOpen=true, CustomFov=false, Fov=80,
    UiScale=100, ThemeGlow=true
}
local cfgFile = 'Aether_BladeBall_V2.json' -- preserve V2 preferences, Auto Parry never auto-enables
if type(readfile)=='function' and type(isfile)=='function' then
    pcall(function()
        if isfile(cfgFile) then
            local loaded=HttpService:JSONDecode(readfile(cfgFile))
            if type(loaded)=='table' then
                for k,v in pairs(loaded) do
                    if cfg[k]~=nil and type(cfg[k])==type(v) then cfg[k]=v end
                end
            end
        end
    end)
end
-- Require an explicit click for automated action on every launch.
cfg.AutoParry=false
local function save()
    if type(writefile)=='function' then
        pcall(function() writefile(cfgFile,HttpService:JSONEncode(cfg)) end)
    end
end
local alive=true
local allConnections,tabConnections,objects={}, {}, {}
local function hook(signal,fn,bucket)
    local con=signal:Connect(fn)
    table.insert(bucket or allConnections,con)
    return con
end
local function disconnect(list)
    for _,con in ipairs(list) do pcall(function()con:Disconnect() end) end
    table.clear(list)
end
local function make(class,parent,properties)
    local obj=Instance.new(class)
    for key,value in pairs(properties or {}) do obj[key]=value end
    obj.Parent=parent
    return obj
end
local function corner(o,r)
    make('UICorner',o,{CornerRadius=UDim.new(0,r or 10)})
    return o
end
local function stroke(o,color,alpha,width)
    return make('UIStroke',o,{Color=color or C.stroke,Transparency=alpha or .45,Thickness=width or 1})
end
local function txt(parent,str,sz,color,bold,properties)
    local p={Text=str,TextSize=sz or 12,TextColor3=color or C.text,
        Font=bold and Enum.Font.GothamBold or Enum.Font.Gotham,
        BackgroundTransparency=1,TextXAlignment=Enum.TextXAlignment.Left,
        TextYAlignment=Enum.TextYAlignment.Center}
    for k,v in pairs(properties or {}) do p[k]=v end
    return make('TextLabel',parent,p)
end
local function animate(o,properties,dur,style)
    if not o or not o.Parent then return end
    if cfg.MenuAnimations then
        TS:Create(o,TweenInfo.new(dur or .2,style or Enum.EasingStyle.Quart,Enum.EasingDirection.Out),properties):Play()
    else
        for k,v in pairs(properties) do o[k]=v end
    end
end
local function getGuiParent()
    if type(gethui)=='function' then
        local ok,p=pcall(gethui)
        if ok and typeof(p)=='Instance' then return p end
    end
    local ok,p=pcall(function()return game:GetService('CoreGui')end)
    if ok and p then return p end
    return LP:WaitForChild('PlayerGui')
end
local guiParent=getGuiParent()
local old=guiParent:FindFirstChild('AETHER_BLADE_BALL_V2')
if old then pcall(function()old:Destroy() end) end
local gui=make('ScreenGui',guiParent,{
    Name='AETHER_BLADE_BALL_V2',ResetOnSpawn=false,IgnoreGuiInset=true,
    ZIndexBehavior=Enum.ZIndexBehavior.Sibling,DisplayOrder=133
})
local opening=true
local original={
    Brightness=Lighting.Brightness,Ambient=Lighting.Ambient,
    OutdoorAmbient=Lighting.OutdoorAmbient,GlobalShadows=Lighting.GlobalShadows,
    Fov=(Workspace.CurrentCamera and Workspace.CurrentCamera.FieldOfView) or 70
}
local blur=make('BlurEffect',Lighting,{Name='AetherMenuBlurV2',Size=0,Enabled=true})
local backdrop=make('Frame',gui,{
    Name='DimBackdrop',Size=UDim2.fromScale(1,1),BackgroundColor3=C.black,
    BackgroundTransparency=.98,BorderSizePixel=0,Visible=true
})

-- Vector icons rendered with real Roblox geometry; no external asset URLs.
local VPATH={
    pulse={{{2,12},{6,12},{9,5},{13,19},{16,12},{22,12}}},
    sliders={{{4,6},{20,6}},{{4,12},{20,12}},{{4,18},{20,18}}},
    eye={{{2,12},{6,8},{12,6},{18,8},{22,12},{18,16},{12,18},{6,16},{2,12}}},
    shield={{{12,2},{20,6},{19,15},{12,22},{5,15},{4,6},{12,2}},{{8,12},{11,15},{16,9}}},
    search={{{15.5,15.5},{21,21}}},
    gear={{{12,2},{12,5}},{{12,19},{12,22}},{{2,12},{5,12}},{{19,12},{22,12}},{{5,5},{7,7}},{{17,17},{19,19}},{{19,5},{17,7}},{{7,17},{5,19}}},
    keyboard={{{3,6},{21,6},{21,18},{3,18},{3,6}},{{6,10},{7,10}},{{10,10},{11,10}},{{14,10},{15,10}},{{18,10},{19,10}},{{7,15},{17,15}}},
    person={{{4,21},{4,18},{7,15},{17,15},{20,18},{20,21}}},
    users={{{2,20},{2,17},{5,14},{9,14}},{{15,14},{19,14},{22,17},{22,20}}},
    crosshair={{{12,2},{12,7}},{{12,17},{12,22}},{{2,12},{7,12}},{{17,12},{22,12}}},
    spark={{{12,2},{12,22}},{{2,12},{22,12}},{{5,5},{19,19}},{{19,5},{5,19}}},
    info={{{12,11},{12,17}},{{12,7},{12,7.1}}},
    close={{{5,5},{19,19}},{{19,5},{5,19}}},
    bolt={{{13,2},{5,13},{11,13},{9,22},{20,9},{13,9},{13,2}}},
    layers={{{2,9},{12,3},{22,9},{12,15},{2,9}},{{2,14},{12,20},{22,14}}},
    bars={{{4,20},{4,13}},{{9,20},{9,9}},{{14,20},{14,5}},{{19,20},{19,2}}},
    moon={{{16,3},{11,4},{8,8},{8,14},{12,18},{18,18},{21,16}}},
    target={{{12,2},{12,5}},{{12,19},{12,22}},{{2,12},{5,12}},{{19,12},{22,12}}},
    dots={{{5,12},{5,12.1}},{{12,12},{12,12.1}},{{19,12},{19,12.1}}},
    check={{{4,12},{10,18},{20,6}}},
    chevron={{{7,9},{12,14},{17,9}}},
    move={{{12,2},{12,22}},{{2,12},{22,12}},{{9,5},{12,2},{15,5}},{{9,19},{12,22},{15,19}}},
}
local function vector(parent,name,x,y,size,color)
    local holder=make('Frame',parent,{
        Name='Vector_'..name,BackgroundTransparency=1,
        Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(size,size)
    })
    local scalar=size/24
    local function segment(x1,y1,x2,y2)
        local dx,dy=x2-x1,y2-y1
        local length=math.sqrt(dx*dx+dy*dy)
        local f=corner(make('Frame',holder,{
            BackgroundColor3=color or C.lilac,BorderSizePixel=0,
            AnchorPoint=Vector2.new(.5,.5),
            Position=UDim2.fromOffset((x1+x2)/2*scalar,(y1+y2)/2*scalar),
            Size=UDim2.fromOffset(math.max(1,length*scalar),math.max(1.3,1.75*scalar)),
            Rotation=math.deg(math.atan2(dy,dx))
        }),5)
        return f
    end
    for _,path in ipairs(VPATH[name] or VPATH.spark) do
        for i=1,#path-1 do segment(path[i][1],path[i][2],path[i+1][1],path[i+1][2]) end
        if #path==1 then
            local a=path[1]
            corner(make('Frame',holder,{
                BackgroundColor3=color or C.lilac,BorderSizePixel=0,
                Position=UDim2.fromOffset(a[1]*scalar-1,a[2]*scalar-1),
                Size=UDim2.fromOffset(math.max(2,2*scalar),math.max(2,2*scalar))
            }),10)
        end
    end
    local function outlinedCircle(cx,cy,r)
        local o=make('Frame',holder,{
            BackgroundTransparency=1,Position=UDim2.fromOffset((cx-r)*scalar,(cy-r)*scalar),
            Size=UDim2.fromOffset(2*r*scalar,2*r*scalar)
        })
        corner(o,100)
        stroke(o,color or C.lilac,0,math.max(1,1.5*scalar))
    end
    if name=='search' then outlinedCircle(10,10,7) end
    if name=='gear' then outlinedCircle(12,12,5.6) end
    if name=='person' or name=='users' then outlinedCircle(12,7,4.2) end
    if name=='users' then outlinedCircle(5.5,9,2.7);outlinedCircle(18.5,9,2.7) end
    if name=='crosshair' or name=='target' then outlinedCircle(12,12,4) end
    if name=='info' then outlinedCircle(12,12,9.6) end
    if name=='dots' then for _,cx in ipairs({5,12,19}) do outlinedCircle(cx,12,.7) end end
    return holder
end
local function glass(parent,pos,size,fill,trans,r)
    local box=corner(make('Frame',parent,{
        Position=pos,Size=size,BackgroundColor3=fill or C.raised,
        BackgroundTransparency=trans or .14,BorderSizePixel=0
    }),r or 10)
    stroke(box,C.stroke,.65,1)
    return box
end

local window=glass(gui,UDim2.fromScale(.5,.5),UDim2.fromOffset(780,466),C.main,.07,12)
window.AnchorPoint=Vector2.new(.5,.5)
window.ClipsDescendants=true
window.Name='AETHERWindow'
local windowScale=make('UIScale',window,{Scale=1})
make('UIGradient',window,{
    Rotation=125,Color=ColorSequence.new({
        ColorSequenceKeypoint.new(0,Color3.fromRGB(23,21,36)),
        ColorSequenceKeypoint.new(.55,C.main),
        ColorSequenceKeypoint.new(1,Color3.fromRGB(21,18,31))
    })
})
local titleBar=make('Frame',window,{BackgroundTransparency=1,Size=UDim2.new(1,0,0,71),Active=true})
local accentBar=make('Frame',titleBar,{
    BackgroundColor3=C.violet,Size=UDim2.fromOffset(3,32),
    Position=UDim2.fromOffset(17,20),BorderSizePixel=0
})
corner(accentBar,5)
vector(titleBar,'pulse',27,24,23,C.violet)
local tabsArea=make('Frame',titleBar,{
    BackgroundTransparency=1,Position=UDim2.fromOffset(66,17),Size=UDim2.fromOffset(442,45)
})
local tabButtons={}
local currentTab='Visuals'
local lineBelow=make('Frame',window,{
    BorderSizePixel=0,BackgroundColor3=C.stroke,BackgroundTransparency=.76,
    Position=UDim2.fromOffset(16,70),Size=UDim2.new(1,-32,0,1)
})
local iconSearchButton=make('TextButton',titleBar,{
    Text='',AutoButtonColor=false,BackgroundTransparency=1,
    Position=UDim2.fromOffset(635,17),Size=UDim2.fromOffset(35,35)
})
vector(iconSearchButton,'search',7,7,20,C.muted)
local iconGearButton=make('TextButton',titleBar,{
    Text='',AutoButtonColor=false,BackgroundTransparency=1,
    Position=UDim2.fromOffset(676,17),Size=UDim2.fromOffset(35,35)
})
vector(iconGearButton,'gear',7,7,20,C.muted)
local portrait=make('ImageButton',titleBar,{
    AutoButtonColor=false,BackgroundColor3=C.raised,BackgroundTransparency=.15,
    Image='rbxthumb://type=AvatarHeadShot&id='..tostring(LP.UserId)..'&w=100&h=100',
    Position=UDim2.fromOffset(726,17),Size=UDim2.fromOffset(34,34)
})
corner(portrait,8)
local dot=corner(make('Frame',titleBar,{
    BorderSizePixel=0,BackgroundColor3=C.green,
    Position=UDim2.fromOffset(752,43),Size=UDim2.fromOffset(7,7)
}),20)
local searchInput=make('TextBox',titleBar,{
    BackgroundColor3=C.raised,BackgroundTransparency=.06,Text='',
    TextColor3=C.text,PlaceholderText='Search modules...',PlaceholderColor3=C.muted,
    Font=Enum.Font.Gotham,TextSize=12,ClearTextOnFocus=false,
    Position=UDim2.fromOffset(403,19),Size=UDim2.fromOffset(210,32),Visible=false
})
corner(searchInput,8);stroke(searchInput,C.violet,.65)
local scroll=make('ScrollingFrame',window,{
    BackgroundTransparency=1,BorderSizePixel=0,
    Position=UDim2.fromOffset(20,84),Size=UDim2.new(1,-40,0,322),
    CanvasSize=UDim2.fromOffset(0,0),ScrollingDirection=Enum.ScrollingDirection.Y,
    ScrollBarImageColor3=C.violet,ScrollBarThickness=3,
    AutomaticCanvasSize=Enum.AutomaticSize.None
})
local grid=make('UIGridLayout',scroll,{
    CellSize=UDim2.new(.5,-8,0,45),CellPadding=UDim2.fromOffset(14,7),
    SortOrder=Enum.SortOrder.LayoutOrder
})
local helpText=txt(window,'Right Shift  ·  Toggle menu',10,C.low,false,{
    Position=UDim2.fromOffset(22,413),Size=UDim2.fromOffset(530,22),TextTruncate=Enum.TextTruncate.AtEnd
})
local footerLine=make('Frame',window,{
    BackgroundColor3=C.stroke,BackgroundTransparency=.8,BorderSizePixel=0,
    Position=UDim2.fromOffset(20,438),Size=UDim2.new(1,-40,0,1)
})
local version=txt(window,'AETHER  /  BLADE BALL     v2.0',10,C.muted,true,{
    Position=UDim2.fromOffset(22,444),Size=UDim2.fromOffset(250,14)
})
local status=txt(window,'ACTIVE   •   waiting for game',10,C.lilac,false,{
    Position=UDim2.fromOffset(460,444),Size=UDim2.fromOffset(300,14),
    TextXAlignment=Enum.TextXAlignment.Right,TextTruncate=Enum.TextTruncate.AtEnd
})
local dock=glass(gui,UDim2.new(.5,0,.5,256),UDim2.fromOffset(231,53),C.raised,.08,9)
dock.AnchorPoint=Vector2.new(.5,.5)
local dockScale=make('UIScale',dock,{Scale=1})
local dockItems={}

-- Top-right mini performance bar, left-side shortcuts, and other reference HUD panels.
local perf=glass(gui,UDim2.new(1,-20,0,27),UDim2.fromOffset(258,40),C.raised,.12,20)
perf.AnchorPoint=Vector2.new(1,0)
vector(perf,'pulse',12,10,19,C.violet)
local fpsText=txt(perf,'-- FPS',11,C.text,true,{Position=UDim2.fromOffset(37,9),Size=UDim2.fromOffset(70,22)})
local pingText=txt(perf,'-- ms',11,C.muted,false,{Position=UDim2.fromOffset(108,9),Size=UDim2.fromOffset(70,22)})
local playerText=txt(perf,LP.DisplayName,11,C.text,true,{
    Position=UDim2.fromOffset(174,9),Size=UDim2.fromOffset(74,22),TextTruncate=Enum.TextTruncate.AtEnd
})
local keys=glass(gui,UDim2.fromOffset(29,72),UDim2.fromOffset(153,122),C.raised,.18,8)
vector(keys,'keyboard',10,10,18,C.violet)
txt(keys,'Keybinds',11,C.text,true,{Position=UDim2.fromOffset(36,7),Size=UDim2.fromOffset(105,23)})
local keyLines={{'AutoParry','Menu'},{'HUD','H'},{'Brightness','B'},{'Settings','Right Shift'}}
for i,item in ipairs(keyLines) do
    txt(keys,item[1],10,C.muted,false,{Position=UDim2.fromOffset(11,31+(i-1)*21),Size=UDim2.fromOffset(79,18)})
    txt(keys,item[2],10,C.lilac,true,{
        Position=UDim2.fromOffset(76,31+(i-1)*21),Size=UDim2.fromOffset(67,18),
        TextXAlignment=Enum.TextXAlignment.Right,TextTruncate=Enum.TextTruncate.AtEnd
    })
end
local detail=glass(gui,UDim2.new(1,-29,.63,0),UDim2.fromOffset(170,126),C.raised,.18,8)
detail.AnchorPoint=Vector2.new(1,.5)
vector(detail,'bolt',10,10,17,C.violet)
txt(detail,'Ball data',11,C.text,true,{Position=UDim2.fromOffset(33,7),Size=UDim2.fromOffset(120,20)})
local detailDistance=txt(detail,'Distance   -- studs',10,C.muted,false,{Position=UDim2.fromOffset(12,35),Size=UDim2.fromOffset(154,18)})
local detailSpeed=txt(detail,'Speed        --',10,C.muted,false,{Position=UDim2.fromOffset(12,57),Size=UDim2.fromOffset(154,18)})
local detailETA=txt(detail,'ETA           --',10,C.muted,false,{Position=UDim2.fromOffset(12,79),Size=UDim2.fromOffset(154,18)})
local detailTarget=txt(detail,'Target        --',10,C.muted,false,{Position=UDim2.fromOffset(12,101),Size=UDim2.fromOffset(154,18),TextTruncate=Enum.TextTruncate.AtEnd})
local playerCard=glass(gui,UDim2.fromOffset(34,329),UDim2.fromOffset(186,61),C.raised,.14,10)
local portrait2=make('ImageLabel',playerCard,{
    Position=UDim2.fromOffset(10,9),Size=UDim2.fromOffset(39,39),BackgroundTransparency=1,
    Image='rbxthumb://type=AvatarHeadShot&id='..tostring(LP.UserId)..'&w=100&h=100'
})
corner(portrait2,8)
txt(playerCard,LP.DisplayName,11,C.text,true,{Position=UDim2.fromOffset(56,9),Size=UDim2.fromOffset(121,22),TextTruncate=Enum.TextTruncate.AtEnd})
local statusCard=txt(playerCard,'PARRY  OFF',10,C.violet,true,{Position=UDim2.fromOffset(56,33),Size=UDim2.fromOffset(120,18)})
local marker=glass(gui,UDim2.new(.5,0,0,17),UDim2.fromOffset(160,35),C.raised,.14,9)
marker.AnchorPoint=Vector2.new(.5,0)
vector(marker,'target',10,9,18,C.violet)
local markerText=txt(marker,'Ball  •  waiting',10,C.text,true,{Position=UDim2.fromOffset(35,7),Size=UDim2.fromOffset(120,21),TextTruncate=Enum.TextTruncate.AtEnd})

local crosshair=make('Frame',gui,{
    AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),
    BackgroundTransparency=1,Size=UDim2.fromOffset(46,46)
})
vector(crosshair,'crosshair',0,0,46,C.lilac)
local fovRing=make('Frame',gui,{
    BackgroundTransparency=1,AnchorPoint=Vector2.new(.5,.5),
    Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(260,260)
})
corner(fovRing,999)
local fovStroke=stroke(fovRing,C.violet,.56,1.5)
local scope=make('Frame',gui,{
    AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),
    BackgroundTransparency=1,Size=UDim2.fromOffset(110,110),Visible=false
})
local function scopeLine(x,y,w,h)
    corner(make('Frame',scope,{
        BackgroundColor3=C.lilac,BackgroundTransparency=.12,BorderSizePixel=0,
        Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h)
    }),3)
end
for _,a in ipairs({{6,6,22,2},{6,6,2,22},{82,6,22,2},{102,6,2,22},
    {6,102,22,2},{6,82,2,22},{82,102,22,2},{102,82,2,22}}) do scopeLine(a[1],a[2],a[3],a[4]) end
local parryRing=make('Frame',gui,{
    BackgroundTransparency=1,AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),
    Size=UDim2.fromOffset(38,38),Visible=false
})
corner(parryRing,999)
local parryStroke=stroke(parryRing,C.violet,0,2.8)

-- A few animated cubic glints, visible only with the UI open.
local gems={}
for i,definition in ipairs({{.12,.34,26,20},{.75,.21,18,-23},{.81,.81,31,30}}) do
    local holder=make('Frame',backdrop,{
        BackgroundTransparency=1,AnchorPoint=Vector2.new(.5,.5),
        Position=UDim2.fromScale(definition[1],definition[2]),
        Size=UDim2.fromOffset(59,59),Rotation=definition[4],ZIndex=1
    })
    for step=1,4 do
        corner(make('Frame',holder,{
            BackgroundColor3=step%2==0 and C.lilac or C.violet,
            BackgroundTransparency=.28+step*.13,BorderSizePixel=0,
            Position=UDim2.fromOffset((step-1)*6,(4-step)*6),
            Size=UDim2.fromOffset(20+step*5,12+step*5),Rotation=45
        }),2)
    end
    table.insert(gems,holder)
end

local tabSpecs={
    Visuals={
        {'Crosshair','Center reticle','Crosshair'},
        {'Ball Tracer','Line from player to ball','BallTracer'},
        {'Full Bright','Improve local scene lighting','FullBright'},
        {'Ball Glow','Purple highlighted ball','BallGlow'},
        {'Hit Color','Color warning when targeted','HitColor'},
        {'Prediction Orb','Projected ball position','Prediction'},
        {'Particles','Local purple aura particles','Particles'},
        {'Jump Circles','Animated landing / jump rings','JumpCircles'},
        {'Scope Overlay','Corner markers near crosshair','ScopeOverlay'},
        {'Render Tweaks','Reduce shadow cost locally','RenderTweaks'},
        {'Player ESP','Outlined player silhouettes','PlayerESP'},
        {'Camera Trail','Local character trail','CameraTrail'},
        {'FOV Ring','Violet circle reticle','FovRing'},
        {'Ball Info','Small marker on ball','BallInfo'},
    },
    Combat={
        {'Auto Parry','Try parrying approaching ball','AutoParry'},
        {'Strict Target','Verify target before auto parry','StrictTarget'},
        {'Trajectory Assist','Use ball trajectory when target is unknown','TrajectoryAssist'},
        {'Fast Reaction','Check incoming ball every game frame','FastReaction'},
        {'Mouse Parry','Use left click instead of F input','MouseParry'},
        {'Parry Pulse','Animate circle on attempted parry','ParryPulse'},
        {'Parry Hints','Status updates on approach','ParryHint'},
        {'Parry Range','Maximum distance in studs','ParryRange',10,58,1},
        {'Ping Lead','Extra lead time in milliseconds','PingLead',0,180,5},
    },
    HUD={
        {'Side Panels','Show ball + profile widgets','SidePanels'},
        {'Keybinds','Floating shortcut list','Keybinds'},
        {'FPS Counter','Show FPS and ping','FPS'},
        {'Death Marker','Remember last death position','DeathMarker'},
        {'Ball Info','Ball marker details','BallInfo'},
        {'Crosshair','Show center crosshair','Crosshair'},
    },
    Utilities={
        {'Menu Animations','Animated pages and switches','MenuAnimations'},
        {'Soft Blur','Blur world behind the menu','BlurOnOpen'},
        {'Theme Glow','Purple decorations','ThemeGlow'},
        {'Custom FOV','Override camera field of view','CustomFov'},
        {'Camera FOV','Set field of view','Fov',60,110,1},
        {'UI Scale','Resize centered menu','UiScale',65,120,5},
    }
}
local tabs={'Visuals','Combat','HUD','Utilities'}
local tabIcon={Visuals='pulse',Combat='shield',HUD='bars',Utilities='sliders'}
local curTip='Right Shift  ·  Toggle menu'
local currentBall=nil
local visuals={}
local highlights={}
local aura=nil
local charTrail=nil
local deathPosition=nil
local lastFps=0
local parryAttempts=0
local lastParry=0
local parryFeedback=nil
local parryFeedbackUntil=0
local parryMethod='None'
local lastTargetName='Unknown'
local parryDiagnostic='Waiting for ball'
local attemptCooldown=.24 -- avoid repeated inputs every frame, which can trigger in-game cooldowns
local showMenu
local renderTab
local refresh

local function tooltip(message)
    curTip=message
    helpText.Text=message
end
local updateScale
local function setLighting()
    Lighting.GlobalShadows=(cfg.FullBright or cfg.RenderTweaks) and false or original.GlobalShadows
    Lighting.Brightness=cfg.FullBright and 3 or original.Brightness
    Lighting.Ambient=cfg.FullBright and Color3.fromRGB(196,190,229) or original.Ambient
    Lighting.OutdoorAmbient=cfg.FullBright and Color3.fromRGB(200,193,232) or original.OutdoorAmbient
end
refresh=function()
    setLighting()
    local cam=Workspace.CurrentCamera
    if cam then cam.FieldOfView=cfg.CustomFov and cfg.Fov or original.Fov end
    local viewport=cam and cam.ViewportSize or Vector2.new(1280,720)
    local canShow=viewport.X>=800
    keys.Visible=cfg.Keybinds and canShow
    detail.Visible=cfg.SidePanels and canShow
    playerCard.Visible=cfg.SidePanels and canShow
    perf.Visible=cfg.FPS
    marker.Visible=cfg.SidePanels
    crosshair.Visible=cfg.Crosshair
    fovRing.Visible=cfg.FovRing
    scope.Visible=cfg.ScopeOverlay
    statusCard.Text=cfg.AutoParry and 'PARRY  ON' or 'PARRY  OFF'
    statusCard.TextColor3=cfg.AutoParry and C.green or C.violet
    for _,g in ipairs(gems) do g.Visible=cfg.ThemeGlow and opening end
    if not cfg.BlurOnOpen or not opening then animate(blur,{Size=0},.16) end
    updateScale()
end
-- Scale updates are independent to avoid triggering Refresh recursively.
updateScale=function()
    local cam=Workspace.CurrentCamera
    local viewport=cam and cam.ViewportSize or Vector2.new(1280,720)
    local available=math.min(viewport.X/840,viewport.Y/590,1.08)
    local scale=math.clamp(available,.48,1.08)*cfg.UiScale/100
    windowScale.Scale=scale
    dockScale.Scale=scale
end

local function setToggle(key,value)
    cfg[key]=value
    if key=='AutoParry' then
        lastParry=0
        parryFeedbackUntil=0
        parryDiagnostic='WAITING FOR BALL'
        if value then tooltip('Auto Parry ON · Fast Reaction checks every frame; HUD shows input diagnostics') end
    end
    refresh()
    save()
end
local function addToggle(data,order)
    local label,description,key=data[1],data[2],data[3]
    local enabled=cfg[key]
    local card=glass(scroll,UDim2.new(),UDim2.new(),C.raised,enabled and .12 or .31,7)
    card.LayoutOrder=order
    local cardStroke=card:FindFirstChildOfClass('UIStroke')
    cardStroke.Transparency=enabled and .68 or .87
    local labelColor=enabled and C.text or C.muted
    local nameLabel=txt(card,label,12,labelColor,enabled,{
        Position=UDim2.fromOffset(20,3),Size=UDim2.new(1,-120,1,-6),TextTruncate=Enum.TextTruncate.AtEnd
    })
    local extra=make('TextButton',card,{
        Text='···',TextColor3=enabled and C.muted or C.low,TextSize=18,
        Font=Enum.Font.GothamBold,BackgroundTransparency=1,
        Position=UDim2.new(1,-89,0,10),Size=UDim2.fromOffset(30,24)
    })
    local switch=corner(make('TextButton',card,{
        AutoButtonColor=false,Text='',BackgroundColor3=enabled and C.violet or C.off,
        Position=UDim2.new(1,-49,.5,-10),Size=UDim2.fromOffset(33,20)
    }),99)
    local knob=corner(make('Frame',switch,{
        BackgroundColor3=C.white,BorderSizePixel=0,
        Position=enabled and UDim2.fromOffset(16,3) or UDim2.fromOffset(3,3),
        Size=UDim2.fromOffset(14,14)
    }),99)
    local touch=make('TextButton',card,{
        BackgroundTransparency=1,Text='',AutoButtonColor=false,
        Position=UDim2.fromOffset(0,0),Size=UDim2.new(1,-95,1,0)
    })
    local function press()
        local on=not cfg[key]
        setToggle(key,on)
        animate(switch,{BackgroundColor3=on and C.violet or C.off},.18)
        animate(knob,{Position=on and UDim2.fromOffset(16,3) or UDim2.fromOffset(3,3)},.18)
        animate(card,{BackgroundTransparency=on and .12 or .31},.18)
        animate(cardStroke,{Transparency=on and .68 or .87},.18)
        nameLabel.TextColor3=on and C.text or C.muted
        extra.TextColor3=on and C.muted or C.low
    end
    hook(switch.MouseButton1Click,press,tabConnections)
    hook(touch.MouseButton1Click,press,tabConnections)
    hook(extra.MouseButton1Click,function()
        tooltip(label..'  ·  '..description)
        animate(cardStroke,{Color=C.violet,Transparency=.27},.14)
        task.delay(.5,function()
            if alive and cardStroke.Parent then
                animate(cardStroke,{Color=C.stroke,Transparency=cfg[key] and .68 or .87},.3)
            end
        end)
    end,tabConnections)
end
local function addSlider(data,order)
    local label,description,key,min,max,step=data[1],data[2],data[3],data[4],data[5],data[6]
    local card=glass(scroll,UDim2.new(),UDim2.new(),C.raised,.18,7)
    card.LayoutOrder=order
    txt(card,label,11,C.text,true,{Position=UDim2.fromOffset(14,3),Size=UDim2.fromOffset(185,18)})
    local display=txt(card,tostring(cfg[key]),11,C.lilac,true,{
        Position=UDim2.new(1,-68,0,2),Size=UDim2.fromOffset(54,18),TextXAlignment=Enum.TextXAlignment.Right
    })
    local track=corner(make('Frame',card,{
        BackgroundColor3=C.off,BorderSizePixel=0,
        Position=UDim2.fromOffset(14,31),Size=UDim2.new(1,-28,0,4)
    }),5)
    local fill=corner(make('Frame',track,{
        BackgroundColor3=C.violet,BorderSizePixel=0,
        Size=UDim2.fromScale((cfg[key]-min)/(max-min),1)
    }),5)
    local touch=make('TextButton',track,{
        Text='',AutoButtonColor=false,BackgroundTransparency=1,
        Position=UDim2.fromOffset(0,-10),Size=UDim2.new(1,0,0,23)
    })
    local dragging=false
    local function update(x)
        if not track.Parent then return end
        local ratio=math.clamp((x-track.AbsolutePosition.X)/math.max(1,track.AbsoluteSize.X),0,1)
        local n=math.clamp(math.floor((min+ratio*(max-min))/step+.5)*step,min,max)
        cfg[key]=n;display.Text=tostring(n)
        fill.Size=UDim2.fromScale((n-min)/(max-min),1)
        if key=='UiScale' then updateScale() else refresh() end
    end
    hook(touch.InputBegan,function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
            dragging=true;update(input.Position.X)
        end
    end,tabConnections)
    hook(UIS.InputChanged,function(input)
        if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
            update(input.Position.X)
        end
    end,tabConnections)
    hook(UIS.InputEnded,function(input)
        if dragging and (input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch) then
            dragging=false;save()
        end
    end,tabConnections)
end
local function rebuild(query)
    disconnect(tabConnections)
    for _,child in ipairs(scroll:GetChildren()) do
        if child:IsA('Frame') then child:Destroy() end
    end
    local filtered={}
    local search=string.lower(query or '')
    for _,row in ipairs(tabSpecs[currentTab]) do
        if search=='' or string.find(string.lower(row[1]),search,1,true) or
            string.find(string.lower(row[2]),search,1,true) then
            table.insert(filtered,row)
        end
    end
    for i,item in ipairs(filtered) do
        if type(item[4])=='number' then addSlider(item,i) else addToggle(item,i) end
    end
    scroll.CanvasPosition=Vector2.zero
    scroll.CanvasSize=UDim2.fromOffset(0,math.ceil(#filtered/2)*52+4)
    if #filtered==0 then tooltip('No modules match your search') end
end
renderTab=function(name)
    currentTab=name
    for tab,button in pairs(tabButtons) do
        local isActive=tab==name
        animate(button,{TextColor3=isActive and C.white or C.low},.16)
    end
    for tab,btn in pairs(dockItems) do
        local on=tab==name
        animate(btn,{BackgroundTransparency=on and 0 or 1},.16)
    end
    tooltip(name..'  ·  '..tostring(#tabSpecs[name])..' modules')
    rebuild(searchInput.Visible and searchInput.Text or '')
    if cfg.MenuAnimations then
        scroll.Position=UDim2.fromOffset(20,94)
        animate(scroll,{Position=UDim2.fromOffset(20,84)},.25)
    end
end
for i,name in ipairs(tabs) do
    local x= (i-1)*90
    local button=make('TextButton',tabsArea,{
        Text=name,BackgroundTransparency=1,AutoButtonColor=false,
        TextColor3=name=='Visuals' and C.white or C.low,TextSize=12,
        Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Center,
        Position=UDim2.fromOffset(x,5),Size=UDim2.fromOffset(89,31)
    })
    tabButtons[name]=button
    if i~=4 then
        make('Frame',tabsArea,{
            BackgroundColor3=C.stroke,BackgroundTransparency=.7,BorderSizePixel=0,
            Position=UDim2.fromOffset(x+90,16),Size=UDim2.fromOffset(1,10)
        })
    end
    hook(button.MouseButton1Click,function()renderTab(name)end)
end
for i,name in ipairs({'Combat','Visuals','HUD','Utilities'}) do
    local button=corner(make('TextButton',dock,{
        Text='',AutoButtonColor=false,BackgroundColor3=C.violet,
        BackgroundTransparency=name=='Visuals' and 0 or 1,
        Position=UDim2.fromOffset(9+(i-1)*55,7),Size=UDim2.fromOffset(45,39)
    }),7)
    dockItems[name]=button
    vector(button,tabIcon[name],11,8,23,name=='Visuals' and C.white or C.lilac)
    hook(button.MouseButton1Click,function()renderTab(name)end)
end
hook(searchInput:GetPropertyChangedSignal('Text'),function()
    if searchInput.Visible then rebuild(searchInput.Text) end
end)
hook(iconSearchButton.MouseButton1Click,function()
    searchInput.Visible=not searchInput.Visible
    if searchInput.Visible then
        searchInput:CaptureFocus()
    else
        searchInput.Text=''
        rebuild('')
    end
end)
hook(iconGearButton.MouseButton1Click,function()renderTab('Utilities')end)
local profileOpen=false
local profileCard=glass(window,UDim2.fromOffset(560,57),UDim2.fromOffset(203,72),C.raised,.04,9)
profileCard.ZIndex=15
profileCard.Visible=false
local userText=txt(profileCard,LP.Name,11,C.text,true,{
    Position=UDim2.fromOffset(12,8),Size=UDim2.fromOffset(180,20),ZIndex=16,TextTruncate=Enum.TextTruncate.AtEnd
})
txt(profileCard,'AETHER  •  Session active',10,C.lilac,false,{
    Position=UDim2.fromOffset(12,30),Size=UDim2.fromOffset(184,15),ZIndex=16
})
txt(profileCard,'Right Shift to hide interface',9,C.muted,false,{
    Position=UDim2.fromOffset(12,49),Size=UDim2.fromOffset(184,14),ZIndex=16
})
hook(portrait.MouseButton1Click,function()
    profileOpen=not profileOpen
    profileCard.Visible=profileOpen
end)
local dragging=false
local dragInput,oldPosition
hook(titleBar.InputBegan,function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
        dragging=true;dragInput=input.Position;oldPosition=window.Position
    end
end)
hook(UIS.InputChanged,function(input)
    if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
        local delta=input.Position-dragInput
        window.Position=UDim2.new(oldPosition.X.Scale,oldPosition.X.Offset+delta.X/windowScale.Scale,
            oldPosition.Y.Scale,oldPosition.Y.Offset+delta.Y/windowScale.Scale)
    end
end)
hook(UIS.InputEnded,function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then dragging=false end
end)
showMenu=function(visible)
    opening=visible
    if visible then
        window.Visible=true;dock.Visible=true;backdrop.Visible=true
        backdrop.BackgroundTransparency=.99
        windowScale.Scale=windowScale.Scale*.96
        dockScale.Scale=dockScale.Scale*.95
        local target=math.clamp(math.min((Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize.X or 1280)/840,
            (Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize.Y or 720)/590,1.08),.48,1.08)*cfg.UiScale/100
        animate(windowScale,{Scale=target},.26)
        animate(dockScale,{Scale=target},.26)
        animate(backdrop,{BackgroundTransparency=.47},.24)
        animate(blur,{Size=cfg.BlurOnOpen and 6 or 0},.24)
    else
        animate(backdrop,{BackgroundTransparency=1},.18)
        animate(blur,{Size=0},.2)
        -- Close immediately enough to avoid leaving invisible UI hitboxes.
        window.Visible=false;dock.Visible=false;backdrop.Visible=false
    end
    for _,gem in ipairs(gems) do gem.Visible=visible and cfg.ThemeGlow end
end
hook(UIS.InputBegan,function(input,processed)
    if input.KeyCode==Enum.KeyCode.RightShift and not UIS:GetFocusedTextBox() then
        showMenu(not opening)
    elseif input.KeyCode==Enum.KeyCode.H and not processed then
        cfg.SidePanels=not cfg.SidePanels;refresh();save()
    elseif input.KeyCode==Enum.KeyCode.B and not processed then
        cfg.FullBright=not cfg.FullBright;refresh();save()
    end
end)

-- Local-only visual effects and lightweight player highlighting.
local function safelyDestroy(o)
    if o then pcall(function()o:Destroy()end) end
end
local function getRoot()
    local c=LP.Character
    return c and c:FindFirstChild('HumanoidRootPart'),c
end
local function getBall()
    local balls=Workspace:FindFirstChild('Balls')
    if not balls then return nil end
    local selected, score=nil, -math.huge
    for _,b in ipairs(balls:GetChildren()) do
        if b:IsA('BasePart') and b.Parent then
            -- Prefer the server-provided real ball; avoid decorative/fake balls.
            local real=b:GetAttribute('realBall')
            if real==true then return b end
            if real~=false then
                local s=0
                if b:GetAttribute('target')~=nil then s=s+4 end
                if string.find(string.lower(b.Name),'ball',1,true) then s=s+1 end
                local zoom=b:FindFirstChild('zoomies')
                if zoom and zoom:IsA('LinearVelocity') then s=s+2 end
                if s>score and s>0 then selected=b;score=s end
            end
        end
    end
    return selected
end
local function velocity(b)
    if not b then return Vector3.zero end
    local motion=b:FindFirstChild('zoomies')
    if motion and motion:IsA('LinearVelocity') and motion.VectorVelocity.Magnitude>3 then
        return motion.VectorVelocity
    end
    return b.AssemblyLinearVelocity
end
local function isTarget(b,char)
    if not b then return false,'No ball' end
    local target=b:GetAttribute('target')
    if target~=nil then
        if typeof(target)=='Instance' then
            local who=target
            local yes=(who==LP or who==char or who==LP.Character)
            local name=pcall(function()return who.Name end) and who.Name or tostring(who)
            return yes,yes and 'YOU' or tostring(name)
        end
        local name=tostring(target)
        local normalized=string.lower(name)
        local yes=normalized==string.lower(LP.Name) or
            normalized==string.lower(LP.DisplayName) or name==tostring(LP.UserId)
        return yes,yes and 'YOU' or name
    end
    if char then
        for _,c in ipairs(char:GetChildren()) do
            if c:IsA('Highlight') and c~=highlights[LP] and c.Enabled and
               c.FillColor.R>c.FillColor.G*1.4 then
                return true,'YOU'
            end
        end
    end
    return false,'Unknown'
end
local function simulateParry()
    -- Input-only attempts; does not call hidden remotes or modify game networking.
    -- A successful pcall proves ONLY that the call ran, not that a parry registered.
    if cfg.MouseParry then
        if type(mouse1click)=='function' then
            if pcall(mouse1click) then return true,'mouse1click' end
        end
        if type(mouse1press)=='function' and type(mouse1release)=='function' then
            local ok=pcall(mouse1press)
            if ok then
                task.delay(.065,function()pcall(mouse1release)end)
                return true,'mouse1press'
            end
        end
    else
        if type(keypress)=='function' and type(keyrelease)=='function' then
            local ok=pcall(keypress,0x46)
            if ok then
                -- Always release, including if script is closed between press/release.
                task.delay(.065,function()pcall(keyrelease,0x46)end)
                return true,'keypress F'
            end
        end
    end
    local ok,service=pcall(function()return game:GetService('VirtualInputManager')end)
    if ok and service then
        if cfg.MouseParry then
            local mouse=UIS:GetMouseLocation()
            local worked=pcall(function()
                service:SendMouseButtonEvent(mouse.X,mouse.Y,0,true,game,0)
                task.delay(.065,function()
                    pcall(function()service:SendMouseButtonEvent(mouse.X,mouse.Y,0,false,game,0)end)
                end)
            end)
            if worked then return true,'VirtualInput mouse' end
        else
            local worked=pcall(function()
                service:SendKeyEvent(true,Enum.KeyCode.F,false,game)
                task.delay(.065,function()
                    pcall(function()service:SendKeyEvent(false,Enum.KeyCode.F,false,game)end)
                end)
            end)
            if worked then return true,'VirtualInput F' end
        end
    end
    return false,'No supported input method'
end
local function pulseParry()
    if not cfg.ParryPulse then return end
    parryRing.Visible=true
    parryRing.Size=UDim2.fromOffset(35,35)
    parryStroke.Transparency=0
    animate(parryRing,{Size=UDim2.fromOffset(205,205)},.37)
    animate(parryStroke,{Transparency=1},.37)
    task.delay(.39,function()if alive then parryRing.Visible=false end end)
end
local function dropBallEffects()
    for k,obj in pairs(visuals) do safelyDestroy(obj);visuals[k]=nil end
end
local function ballMarker(b)
    local bb=make('BillboardGui',gui,{Adornee=b,AlwaysOnTop=true,
        Size=UDim2.fromOffset(135,37),StudsOffsetWorldSpace=Vector3.new(0,3.4,0)})
    local bg=glass(bb,UDim2.new(),UDim2.fromScale(1,1),C.main,.14,7)
    local value=txt(bg,'BALL  •  tracking',10,C.lilac,true,{
        Position=UDim2.fromOffset(10,4),Size=UDim2.fromOffset(120,28)
    })
    visuals.billboard=bb;visuals.billText=value
end
local function updateBallEffects(b,root,vel,distance,targeted)
    if currentBall~=b then
        dropBallEffects()
        currentBall=b
    end
    if not b then return end
    if cfg.BallGlow then
        if not visuals.glow then
            visuals.glow=make('Highlight',Workspace.CurrentCamera or Workspace,{
                Adornee=b,FillTransparency=.68,OutlineTransparency=.05,
                FillColor=C.violet,OutlineColor=C.lilac,
                DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
            })
        end
        visuals.glow.FillColor=(cfg.HitColor and targeted) and C.red or C.violet
    elseif visuals.glow then safelyDestroy(visuals.glow);visuals.glow=nil end
    if cfg.BallInfo then
        if not visuals.billboard then ballMarker(b) end
        if visuals.billText and visuals.billText.Parent then
            visuals.billText.Text=string.format('BALL  %.0f m  |  %.0f',distance/3.57,vel.Magnitude)
        end
    elseif visuals.billboard then
        safelyDestroy(visuals.billboard);visuals.billboard=nil;visuals.billText=nil
    end
    if cfg.BallTracer and root then
        if not visuals.beam or not visuals.rootAttachment or visuals.rootAttachment.Parent~=root then
            for _,k in ipairs({'beam','rootAttachment','ballAttachment'}) do
                safelyDestroy(visuals[k]);visuals[k]=nil
            end
            visuals.rootAttachment=make('Attachment',root,{Name='AetherTracerRoot'})
            visuals.ballAttachment=make('Attachment',b,{Name='AetherTracerBall'})
            visuals.beam=make('Beam',b,{
                Attachment0=visuals.ballAttachment,Attachment1=visuals.rootAttachment,
                FaceCamera=true,LightEmission=.9,Width0=.10,Width1=.03,
                Color=ColorSequence.new(C.lilac,C.violet),
                Transparency=NumberSequence.new(.22)
            })
        end
    elseif visuals.beam or visuals.rootAttachment or visuals.ballAttachment then
        for _,k in ipairs({'beam','rootAttachment','ballAttachment'}) do safelyDestroy(visuals[k]);visuals[k]=nil end
    end
    if cfg.Prediction then
        if not visuals.prediction then
            visuals.prediction=make('Part',Workspace.CurrentCamera or Workspace,{
                Name='AetherProjectedBall',Shape=Enum.PartType.Ball,Size=Vector3.new(1.3,1.3,1.3),
                Material=Enum.Material.Neon,Color=C.lilac,Transparency=.35,
                Anchored=true,CanCollide=false,CanQuery=false,CanTouch=false,CastShadow=false
            })
        end
        visuals.prediction.Position=b.Position+vel*.20
    elseif visuals.prediction then safelyDestroy(visuals.prediction);visuals.prediction=nil end
end
local function updateESP()
    if not cfg.PlayerESP then
        for p,h in pairs(highlights) do safelyDestroy(h);highlights[p]=nil end
        return
    end
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LP then
            local c=p.Character
            if c and c:FindFirstChildOfClass('Humanoid') then
                if not highlights[p] or highlights[p].Adornee~=c then
                    safelyDestroy(highlights[p])
                    highlights[p]=make('Highlight',Workspace.CurrentCamera or Workspace,{
                        Adornee=c,FillColor=C.violet,FillTransparency=.82,
                        OutlineColor=C.lilac,OutlineTransparency=.12,
                        DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
                    })
                end
            else safelyDestroy(highlights[p]);highlights[p]=nil end
        end
    end
    for p,h in pairs(highlights) do
        if p.Parent~=Players then safelyDestroy(h);highlights[p]=nil end
    end
end
local function updateAura(root)
    if not cfg.Particles or not root then
        safelyDestroy(aura);aura=nil
        return
    end
    if not aura or aura.Parent~=root then
        safelyDestroy(aura)
        aura=make('ParticleEmitter',root,{
            Name='AetherVioletSparks',Rate=10,Lifetime=NumberRange.new(.3,.8),
            Speed=NumberRange.new(.2,1.5),SpreadAngle=Vector2.new(70,70),
            LightEmission=.7,Color=ColorSequence.new(C.lilac,C.violet),
            Size=NumberSequence.new({NumberSequenceKeypoint.new(0,.17),NumberSequenceKeypoint.new(1,0)}),
            Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.15),NumberSequenceKeypoint.new(1,1)})
        })
    end
end
local function updateTrail(root)
    if not cfg.CameraTrail or not root then
        if charTrail then
            for _,o in ipairs(charTrail) do safelyDestroy(o) end
            charTrail=nil
        end
        return
    end
    if charTrail and charTrail[1].Parent==root then return end
    if charTrail then for _,o in ipairs(charTrail) do safelyDestroy(o) end end
    local a=make('Attachment',root,{Position=Vector3.new(0,1.8,0)})
    local b=make('Attachment',root,{Position=Vector3.new(0,-1.8,0)})
    local trail=make('Trail',root,{
        Attachment0=a,Attachment1=b,Lifetime=.25,MinLength=.1,
        Color=ColorSequence.new(C.lilac,C.violet),LightEmission=1,
        Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.52),NumberSequenceKeypoint.new(1,1)})
    })
    charTrail={a,b,trail}
end
local charConnection=nil
local charDeathConnection=nil
local function bindCharacter(c)
    if charConnection then charConnection:Disconnect();charConnection=nil end
    if charDeathConnection then charDeathConnection:Disconnect();charDeathConnection=nil end
    local humanoid=c:WaitForChild('Humanoid',5)
    if not humanoid then return end
    charConnection=humanoid.StateChanged:Connect(function(_,state)
        if not alive then return end
        if cfg.JumpCircles and state==Enum.HumanoidStateType.Jumping then
            local root=c:FindFirstChild('HumanoidRootPart')
            if root then
                local orb=make('Part',Workspace.CurrentCamera or Workspace,{
                    Anchored=true,CanCollide=false,CanTouch=false,CanQuery=false,
                    Size=Vector3.new(.15,.7,.7),Shape=Enum.PartType.Cylinder,
                    CFrame=CFrame.new(root.Position-Vector3.new(0,2.5,0))*CFrame.Angles(0,0,math.rad(90)),
                    Material=Enum.Material.Neon,Color=C.violet,Transparency=.6
                })
                TS:Create(orb,TweenInfo.new(.42),{
                    Size=Vector3.new(.15,9,9),Transparency=1
                }):Play()
                task.delay(.5,function()safelyDestroy(orb)end)
            end
        end
    end)
    charDeathConnection=humanoid.Died:Connect(function()
        local root=c:FindFirstChild('HumanoidRootPart')
        if root then deathPosition=root.Position end
    end)
end
hook(LP.CharacterAdded,bindCharacter)
if LP.Character then task.defer(bindCharacter,LP.Character) end

local function pingMs()
    local ok,value=pcall(function()return LP:GetNetworkPing()*1000 end)
    return ok and math.floor(value+.5) or 0
end
-- Combat logic is intentionally separate from the slower visual UI refresh.
-- Each Heartbeat is normally one rendered/physics frame; 1 ms cannot be guaranteed.
local function calculateApproach(ball,root,char,vel,latency)
    local offset=root.Position-ball.Position
    local distance=offset.Magnitude
    local speed=vel.Magnitude
    local closing=distance>0 and vel:Dot(offset.Unit) or 0
    local margin=math.clamp(ball.Size.Magnitude*.28+2,2,7)
    local eta=closing>2 and math.max(0,distance-margin)/closing or math.huge
    local target,targetName=isTarget(ball,char)
    -- If the server doesn't expose a target, estimate if the ball's current
    -- direction actually intersects the player's vicinity. Never override
    -- an explicit target for somebody else.
    local trajectoryTarget=false
    if cfg.TrajectoryAssist and targetName=='Unknown' and closing>5 and speed>5 then
        local secondsUntilClosest=math.clamp(offset:Dot(vel)/(speed*speed),0,.65)
        local closest=ball.Position+vel*secondsUntilClosest
        local miss=(closest-root.Position).Magnitude
        local tolerance=math.clamp(ball.Size.Magnitude*.8+root.Size.Magnitude*.65+6,8,17)
        trajectoryTarget=miss<=tolerance
    end
    local danger=closing>5 and closing>speed*.08
    -- Predict early enough to account for ping and frame time.
    local lead=math.clamp(.20+cfg.PingLead/1000+latency/1800,.20,.52)
    local reach=math.clamp(math.max(cfg.ParryRange,speed*lead+margin),cfg.ParryRange,110)
    local targetAllowed=(not cfg.StrictTarget) or target or trajectoryTarget
    local ready=danger and targetAllowed and eta<=lead and distance<=reach
    return {distance=distance,speed=speed,closing=closing,margin=margin,eta=eta,
        target=target,targetName=targetName,trajectoryTarget=trajectoryTarget,
        danger=danger,lead=lead,reach=reach,ready=ready}
end
local reactionElapsed=0
local latestApproach=nil
local function updateCombat(dt)
    if not cfg.AutoParry then latestApproach=nil;return end
    reactionElapsed=reactionElapsed+dt
    if not cfg.FastReaction and reactionElapsed<.032 then return end
    reactionElapsed=0
    local root,char=getRoot()
    local ball=getBall()
    if not root or not ball then
        latestApproach=nil
        parryDiagnostic='NO BALL / CHARACTER'
        return
    end
    local info=calculateApproach(ball,root,char,velocity(ball),pingMs())
    latestApproach=info
    if not info.ready then
        if cfg.StrictTarget and not info.target and not info.trajectoryTarget then
            parryDiagnostic='TARGET UNKNOWN / NOT YOU'
        elseif not info.danger then
            parryDiagnostic='BALL NOT APPROACHING'
        elseif info.eta>info.lead then
            parryDiagnostic='TRACKING • ETA '..string.format('%.2f s',info.eta)
        else
            parryDiagnostic='TRACKING'
        end
        return
    end
    parryDiagnostic='PARRY WINDOW READY'
    local now=os.clock()
    if now-lastParry<attemptCooldown then return end
    lastParry=now
    local sent,method=simulateParry()
    parryMethod=method
    if sent then
        parryAttempts=parryAttempts+1
        pulseParry()
        parryFeedback='INPUT SENT via '..method..' (not confirmed)'
    else
        parryFeedback='INPUT UNAVAILABLE • try Mouse Parry'
    end
    parryFeedbackUntil=now+.65
end

local elapsed,espElapsed,frames,seconds=0,0,0,0
hook(RunService.Heartbeat,function(dt)
    if not alive then return end
    -- Combat first: do not wait for the 32 ms visual-update throttle.
    updateCombat(dt)
    frames=frames+1;seconds=seconds+dt
    if seconds>=.6 then
        fpsText.Text=string.format('%d FPS',math.floor(frames/seconds+.5))
        pingText.Text=string.format('%d ms',pingMs())
        frames=0;seconds=0
    end
    espElapsed=espElapsed+dt
    if espElapsed>=.7 then espElapsed=0;updateESP() end
    elapsed=elapsed+dt
    if elapsed<.032 then return end
    elapsed=0
    local root,char=getRoot()
    local ball=getBall()
    local speed=velocity(ball)
    local distance=(root and ball) and (root.Position-ball.Position).Magnitude or math.huge
    local target,targetName=isTarget(ball,char)
    updateBallEffects(ball,root,speed,distance,target)
    updateAura(root)
    updateTrail(root)
    local cam=Workspace.CurrentCamera
    if cam and cfg.CustomFov then cam.FieldOfView=cfg.Fov end
    if not root or not ball then
        markerText.Text='Ball  •  waiting'
        detailDistance.Text='Distance   -- studs'
        detailSpeed.Text='Speed        --'
        detailETA.Text='ETA           --'
        detailTarget.Text='Target        --'
        status.Text=cfg.AutoParry and 'NO BALL / CHARACTER' or 'WAITING FOR BALL'
        return
    end
    local info=calculateApproach(ball,root,char,speed,pingMs())
    detailDistance.Text=string.format('Distance   %.0f studs',info.distance)
    detailSpeed.Text=string.format('Speed        %.0f',info.speed)
    detailETA.Text=info.eta==math.huge and 'ETA           --' or string.format('ETA           %.2f s',info.eta)
    detailTarget.Text='Target        '..(info.target and 'YOU' or (info.trajectoryTarget and 'PREDICTED YOU' or targetName))
    markerText.Text=string.format('Ball  •  %.0f studs',distance)
    local now=os.clock()
    if cfg.AutoParry and now<parryFeedbackUntil then
        status.Text=parryFeedback or 'INPUT REQUESTED'
    elseif cfg.AutoParry and cfg.ParryHint then
        status.Text=parryDiagnostic
    elseif cfg.ParryHint then
        status.Text=target and 'TARGETED • AUTO OFF' or ('TRACKING • '..tostring(targetName))
    else
        status.Text=cfg.AutoParry and 'AUTO PARRY ON' or 'AETHER ACTIVE'
    end
    if cfg.DeathMarker and deathPosition then
        -- Keep the marker module honest: position only, no invented timer.
        markerText.Text=string.format('Ball %.0f • Death %.0f',distance,(root.Position-deathPosition).Magnitude)
    end
end)

local function destroy()
    if not alive then return end
    alive=false
    disconnect(tabConnections)
    disconnect(allConnections)
    if charConnection then charConnection:Disconnect();charConnection=nil end
    if charDeathConnection then charDeathConnection:Disconnect();charDeathConnection=nil end
    dropBallEffects()
    for p,h in pairs(highlights) do safelyDestroy(h);highlights[p]=nil end
    safelyDestroy(aura)
    if charTrail then for _,o in ipairs(charTrail) do safelyDestroy(o) end end
    Lighting.Brightness=original.Brightness
    Lighting.Ambient=original.Ambient
    Lighting.OutdoorAmbient=original.OutdoorAmbient
    Lighting.GlobalShadows=original.GlobalShadows
    if Workspace.CurrentCamera then Workspace.CurrentCamera.FieldOfView=original.Fov end
    safelyDestroy(blur)
    safelyDestroy(gui)
    if ENV.AETHER_BLADE_BALL and ENV.AETHER_BLADE_BALL.Destroy==destroy then
        ENV.AETHER_BLADE_BALL=nil
    end
end
ENV.AETHER_BLADE_BALL={Destroy=destroy,Settings=cfg,ShowMenu=showMenu}
refresh()
renderTab('Visuals')
showMenu(true)
print('[AETHER Blade Ball V4] Loaded • RightShift menu • frame-speed reaction • predictive path check • Auto Parry OFF until enabled; no input guarantees.')
