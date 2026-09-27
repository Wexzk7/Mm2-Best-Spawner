local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui          = game:GetService("CoreGui")
local ReplicatedStorage= game:GetService("ReplicatedStorage")
local LP               = Players.LocalPlayer

-- ============================================================
-- ALLOWED WEAPONS LIST (WHITELIST)
-- ============================================================
local WeaponsToSpawn = {
    "TravelerGunChroma", "TreeGun2023Chroma", "TreeKnife2023Chroma", "BaubleChroma", 
    "ConstellationChroma", "VampireGunChroma", "Gingerscope", "UFOKnifeChroma", 
    "RaygunChroma", "TravelerAxe", "BlizzardChroma", "SunsetGunChroma", 
    "SnowcannonChroma", "SnowstormChroma", "SnowDaggerChroma", "TravelerGun", 
    "SunsetKnifeChroma", "TreeGun2023", "Constellation", "BaubleKnifeChroma", 
    "TreeKnife2023", "WatergunChroma", "Turkey2023", "Celestial", 
    "VampireGun", "Bauble", "Darkshot", "Darksword", "Blossom_G", 
    "Sakura_K", "Sorry", "VampireAxe", "UFOKnife", "Harvester", 
    "Raygun", "Icepiercer"
}

-- Quick helper to verify if a database item is allowed to spawn
local function isWeaponAllowed(weaponName)
    for _, allowedName in ipairs(WeaponsToSpawn) do
        if allowedName == weaponName then
            return true
        end
    end
    return false
end

-- ============================================================
-- HELPERS
-- ============================================================

local function H(s) return Color3.fromHex(s) end

local function new(class, props)
    local o = Instance.new(class)
    if props then
        local parent = props.Parent
        for k, v in pairs(props) do if k ~= "Parent" then o[k] = v end end
        if parent then o.Parent = parent end
    end
    return o
end

local function corner(p, r)  return new("UICorner", {CornerRadius=UDim.new(0,r or 8), Parent=p}) end
local function pad(p, all)   return new("UIPadding", {PaddingLeft=UDim.new(0,all), PaddingRight=UDim.new(0,all), PaddingTop=UDim.new(0,all), PaddingBottom=UDim.new(0,all), Parent=p}) end
local function listV(p, gap) return new("UIListLayout", {FillDirection=Enum.FillDirection.Vertical, Padding=UDim.new(0,gap or 6), SortOrder=Enum.SortOrder.LayoutOrder, Parent=p}) end
local function tween(o, t, props, st, dir)
    local tw = TweenService:Create(o, TweenInfo.new(t, st or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
    tw:Play(); return tw
end
local function gradSeq(colors)
    local kp = {}
    for i, c in ipairs(colors) do
        table.insert(kp, ColorSequenceKeypoint.new((i-1)/math.max(#colors-1,1), c))
    end
    return ColorSequence.new(kp)
end

-- ============================================================
-- PALETTE  (Spring 2026)
-- ============================================================

local C = {
    Bg      = H"#0f0c16",
    Panel   = H"#141228",
    Input   = H"#1c1a2e",
    BtnDark = H"#1e1c35",
    Drop    = H"#181630",

    Pink    = H"#f472b6",
    Mint    = H"#86efac",
    Gold    = H"#fde047",
    Rose    = H"#fb7185",
    Sky     = H"#7dd3fc",
    Cyan    = H"#00d4ff",
    Purple  = H"#b400ff",

    Text    = H"#e2e0ff",
    TextSub = H"#8888a8",
    Good    = H"#86efac",
    Bad     = H"#fb7185",
}

local BORDER_SEQ  = gradSeq({C.Pink, C.Mint, C.Sky, C.Purple, C.Pink})
local SPAWN_SEQ   = gradSeq({C.Pink, C.Cyan})
local DIVIDER_SEQ = gradSeq({Color3.new(1,1,1), C.Pink, C.Mint, Color3.new(1,1,1)})
local DIVIDER_TRANS = NumberSequence.new({
    NumberSequenceKeypoint.new(0,   1),
    NumberSequenceKeypoint.new(0.1, 0),
    NumberSequenceKeypoint.new(0.9, 0),
    NumberSequenceKeypoint.new(1,   1),
})

-- ============================================================
-- SCREEN GUI + ROOT FRAME
-- ============================================================

local sg = new("ScreenGui", {
    Name           = "TestolSpawnerRemastered",
    DisplayOrder   = 9998,
    ResetOnSpawn   = false,
    IgnoreGuiInset = true,
})
pcall(function() sg.Parent = CoreGui end)
if not sg.Parent then sg.Parent = LP:WaitForChild("PlayerGui") end

local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local VP       = workspace.CurrentCamera.ViewportSize
local FW       = isMobile and math.min(math.floor(VP.X - 24), 380) or 320
local FH       = isMobile and math.min(430, math.floor(VP.Y * 0.82)) or 430
local frame = new("Frame", {
    Size             = UDim2.fromOffset(FW, FH),
    Position         = UDim2.new(0.5, -FW/2, 0.5, -FH/2),
    BackgroundColor3 = C.Bg,
    BorderSizePixel  = 0,
    ClipsDescendants = false,
    Parent           = sg,
})
corner(frame, 14)

new("UIGradient", {
    Color    = gradSeq({H"#1a1535", C.Bg, C.Bg}),
    Rotation = 135,
    Parent   = frame,
})

local borderStroke = new("UIStroke", {
    Thickness       = 2,
    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    LineJoinMode    = Enum.LineJoinMode.Round,
    Parent          = frame,
})
local borderGrad = new("UIGradient", {Color=BORDER_SEQ, Parent=borderStroke})

task.spawn(function()
    while frame and frame.Parent do
        tween(borderGrad, 3, {Rotation=(borderGrad.Rotation or 0)+360}, Enum.EasingStyle.Linear)
        task.wait(3)
    end
end)

-- ============================================================
-- HEADER
-- ============================================================

local header = new("Frame", {
    Size             = UDim2.new(1, 0, 0, 54),
    BackgroundColor3 = C.Panel,
    BorderSizePixel  = 0,
    Parent           = frame,
})
new("UIGradient", {Color=gradSeq({H"#1e1a38", C.Panel}), Rotation=90, Parent=header})

local titleLbl = new("TextLabel", {
    Size                   = UDim2.new(1, -60, 0, 26),
    Position               = UDim2.fromOffset(16, 8),
    BackgroundTransparency = 1,
    Text                   = "Rhyzen Spawner",
    Font                   = Enum.Font.GothamBlack,
    TextSize               = 22,
    TextColor3             = Color3.new(1,1,1),
    TextXAlignment         = Enum.TextXAlignment.Left,
    TextStrokeColor3       = Color3.new(0,0,0),
    TextStrokeTransparency = 0.6,
    Parent                 = header,
})
new("UIGradient", {Color=gradSeq({C.Pink, C.Mint}), Parent=titleLbl})

new("TextLabel", {
    Size                   = UDim2.new(1, -60, 0, 16),
    Position               = UDim2.fromOffset(16, 32),
    BackgroundTransparency = 1,
    Text                   = "Remastered",
    Font                   = Enum.Font.GothamMedium,
    TextSize               = 12,
    TextColor3             = C.TextSub,
    TextXAlignment         = Enum.TextXAlignment.Left,
    Parent                 = header,
})

local closeBtn = new("TextButton", {
    Size             = UDim2.fromOffset(28, 28),
    Position         = UDim2.new(1, -38, 0.5, -14),
    BackgroundColor3 = H"#2a1830",
    BorderSizePixel  = 0,
    Text             = "x",
    TextColor3       = C.Rose,
    Font             = Enum.Font.GothamBold,
    TextSize         = 14,
    AutoButtonColor  = false,
    Parent           = header,
})
corner(closeBtn, 8)
new("UIStroke", {Thickness=1, Color=C.Rose, Transparency=0.6, Parent=closeBtn})
closeBtn.MouseEnter:Connect(function() tween(closeBtn, 0.12, {BackgroundColor3=H"#4a1030", TextColor3=Color3.new(1,1,1)}) end)
closeBtn.MouseLeave:Connect(function() tween(closeBtn, 0.12, {BackgroundColor3=H"#2a1830", TextColor3=C.Rose}) end)

closeBtn.MouseButton1Click:Connect(function()
    tween(frame, 0.2, {BackgroundTransparency=1, Size=UDim2.fromOffset(FW, 0)})
    task.wait(0.22)
    frame.Visible = false
    
    -- If on mobile, reset the floating pill text back to "Spawner"
    local tSG = CoreGui:FindFirstChild("TestolToggle") or LP:WaitForChild("PlayerGui"):FindFirstChild("TestolToggle")
    if tSG and tSG:FindFirstChild("TextButton") then
        tSG.TextButton.Text = "Spawner"
    end
end)
local divider = new("Frame", {
    Size             = UDim2.new(1, 0, 0, 1),
    Position         = UDim2.fromOffset(0, 54),
    BackgroundColor3 = Color3.new(1,1,1),
    BorderSizePixel  = 0,
    Parent           = frame,
})
new("UIGradient", {Color=DIVIDER_SEQ, Transparency=DIVIDER_TRANS, Parent=divider})

-- ============================================================
-- BODY
-- ============================================================

local body = new("ScrollingFrame", {
    Size                   = UDim2.new(1, 0, 1, -55),
    Position               = UDim2.fromOffset(0, 55),
    BackgroundTransparency = 1,
    BorderSizePixel        = 0,
    ScrollBarThickness     = isMobile and 3 or 0,
    ScrollBarImageColor3   = C.Pink,
    CanvasSize             = UDim2.fromScale(1, 0),
    AutomaticCanvasSize    = Enum.AutomaticSize.Y,
    ScrollingDirection     = Enum.ScrollingDirection.Y,
    ElasticBehavior        = Enum.ElasticBehavior.Always,
    Parent                 = frame,
})
pad(body, 16)
listV(body, 10)

-- ── helper: builds a stepper widget [ - | N | + ] inside a parent frame
local function makeStepperWidget(parent, defaultVal, maxVal)
    local pill = new("Frame", {
        Size             = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = C.Input,
        BorderSizePixel  = 0,
        Parent           = parent,
    })
    corner(pill, 8)
    new("UIStroke", {Thickness=1, Color=C.TextSub, Transparency=0.7, ApplyStrokeMode=Enum.ApplyStrokeMode.Border, Parent=pill})

    local minus = new("TextButton", {
        Size             = UDim2.new(0, 30, 1, 0),
        Position         = UDim2.fromOffset(0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel  = 0,
        Text             = "-",
        TextColor3       = C.Text,
        Font             = Enum.Font.GothamBold,
        TextSize         = 16,
        AutoButtonColor  = false,
        Parent           = pill,
    })
    local countLbl = new("TextLabel", {
        Size                   = UDim2.new(0, 44, 1, 0),
        Position               = UDim2.fromOffset(30, 0),
        BackgroundTransparency = 1,
        Text                   = tostring(defaultVal),
        Font                   = Enum.Font.GothamBold,
        TextSize               = 13,
        TextColor3             = C.Text,
        Parent                 = pill,
    })
    local plus = new("TextButton", {
        Size             = UDim2.new(0, 30, 1, 0),
        Position         = UDim2.fromOffset(74, 0),
        BackgroundTransparency = 1,
        BorderSizePixel  = 0,
        Text             = "+",
        TextColor3       = C.Text,
        Font             = Enum.Font.GothamBold,
        TextSize         = 16,
        AutoButtonColor  = false,
        Parent           = pill,
    })
    new("Frame", {Size=UDim2.fromOffset(1,20), Position=UDim2.new(0,30,0.5,-10), BackgroundColor3=C.TextSub, BackgroundTransparency=0.5, BorderSizePixel=0, Parent=pill})
    new("Frame", {Size=UDim2.fromOffset(1,20), Position=UDim2.new(0,74,0.5,-10), BackgroundColor3=C.TextSub, BackgroundTransparency=0.5, BorderSizePixel=0, Parent=pill})

    local val = defaultVal
    minus.MouseButton1Click:Connect(function()
        if val > 1 then val = val - 1; countLbl.Text = tostring(val) end
    end)
    plus.MouseButton1Click:Connect(function()
        if val < maxVal then val = val + 1; countLbl.Text = tostring(val) end
    end)
    return pill, function() return val end, countLbl
end

-- ── ITEM SELECTION ──────────────────────────────────────────────
new("TextLabel", {
    Size = UDim2.new(1,0,0,12), BackgroundTransparency=1,
    Text="FILTER", Font=Enum.Font.GothamBold, TextSize=10,
    TextColor3=C.TextSub, TextXAlignment=Enum.TextXAlignment.Left,
    LayoutOrder=1, Parent=body,
})

local filterBox = new("TextBox", {
    Size=UDim2.new(1,0,0,36), BackgroundColor3=C.Input, BorderSizePixel=0,
    PlaceholderText="Search items (knife, chroma, godly...)",
    Text="", PlaceholderColor3=C.TextSub, TextColor3=C.Text,
    Font=Enum.Font.Gotham, TextSize=13, ClearTextOnFocus=false,
    LayoutOrder=2, Parent=body,
})
corner(filterBox, 8); pad(filterBox, 10)
local filterStroke = new("UIStroke", {Thickness=1.5, Color=C.TextSub, Transparency=0.6, ApplyStrokeMode=Enum.ApplyStrokeMode.Border, Parent=filterBox})
filterBox.Focused:Connect(function()  tween(filterStroke, 0.15, {Transparency=0,   Color=C.Pink}) end)
filterBox.FocusLost:Connect(function() tween(filterStroke, 0.15, {Transparency=0.6, Color=C.TextSub}) end)

local selectedDisplay = new("TextButton", {
    Size=UDim2.new(1,0,0,36), BackgroundColor3=C.Input, BorderSizePixel=0,
    Text="None selected", TextColor3=C.TextSub,
    Font=Enum.Font.GothamMedium, TextSize=13,
    AutoButtonColor=false, TextXAlignment=Enum.TextXAlignment.Left,
    LayoutOrder=3, Parent=body,
})
corner(selectedDisplay, 8); pad(selectedDisplay, 10)
local selectedStroke = new("UIStroke", {Thickness=1.5, Color=C.Mint, Transparency=0.7, ApplyStrokeMode=Enum.ApplyStrokeMode.Border, Parent=selectedDisplay})
new("TextLabel", {
    Size=UDim2.fromOffset(20,36), Position=UDim2.new(1,-26,0,0),
    BackgroundTransparency=1, Text="›", Font=Enum.Font.GothamBold,
    TextSize=18, TextColor3=C.TextSub, Parent=selectedDisplay,
})

-- ── SPAWN SECTION ────────────────────────────────────────────────
local spawnRow = new("Frame", {
    Size=UDim2.new(1,0,0,44), BackgroundTransparency=1,
    LayoutOrder=4, Parent=body,
})

local spawnBtn = new("TextButton", {
    Size=UDim2.new(1,-112,0,44), BackgroundColor3=C.BtnDark, BorderSizePixel=0,
    Text="Spawn Item", TextColor3=Color3.new(1,1,1),
    Font=Enum.Font.GothamBold, TextSize=14,
    AutoButtonColor=false, Parent=spawnRow,
})
corner(spawnBtn, 10)
new("UIGradient", {Color=SPAWN_SEQ, Rotation=135, Parent=spawnBtn})
local spawnStroke = new("UIStroke", {Thickness=1.5, Transparency=0.6, ApplyStrokeMode=Enum.ApplyStrokeMode.Border, Parent=spawnBtn})
new("UIGradient", {Color=SPAWN_SEQ, Parent=spawnStroke})
spawnBtn.MouseEnter:Connect(function() tween(spawnStroke, 0.12, {Transparency=0}) end)
spawnBtn.MouseLeave:Connect(function() tween(spawnStroke, 0.12, {Transparency=0.6}) end)

local spawnStepper = new("Frame", {
    Size=UDim2.fromOffset(104,44), Position=UDim2.new(1,-104,0,0),
    BackgroundTransparency=1, Parent=spawnRow,
})
local _, getSpawnAmt = makeStepperWidget(spawnStepper, 1, 100)

local progContainer = new("Frame", {
    Size=UDim2.new(1,0,0,5), BackgroundColor3=C.Input,
    BorderSizePixel=0, LayoutOrder=5, Parent=body,
})
corner(progContainer, 3)
local progFill = new("Frame", {
    Size=UDim2.new(0,0,1,0), BackgroundColor3=C.Pink, BorderSizePixel=0, Parent=progContainer,
})
corner(progFill, 3)
new("UIGradient", {Color=SPAWN_SEQ, Parent=progFill})

local statusLbl = new("TextLabel", {
    Size=UDim2.new(1,0,0,18), BackgroundTransparency=1,
    Text="Ready", TextColor3=C.TextSub,
    Font=Enum.Font.GothamMedium, TextSize=11,
    LayoutOrder=6, Parent=body,
})
local function setStatus(txt, col) statusLbl.Text=txt; statusLbl.TextColor3=col or C.TextSub end

-- ── DUPE SECTION ─────────────────────────────────────────────────
local divFrame = new("Frame", {
    Size=UDim2.new(1,0,0,1), BackgroundColor3=Color3.new(1,1,1),
    BorderSizePixel=0, LayoutOrder=7, Parent=body,
})
new("UIGradient", {
    Color=gradSeq({Color3.new(1,1,1), C.Gold, C.Cyan, Color3.new(1,1,1)}),
    Transparency=NumberSequence.new({
        NumberSequenceKeypoint.new(0,1),
        NumberSequenceKeypoint.new(0.1,0),
        NumberSequenceKeypoint.new(0.9,0),
        NumberSequenceKeypoint.new(1,1),
    }),
    Parent=divFrame,
})

new("TextLabel", {
    Size=UDim2.new(1,0,0,12), BackgroundTransparency=1,
    Text="DUPE IN INVENTORY", Font=Enum.Font.GothamBold, TextSize=10,
    TextColor3=C.Gold, TextXAlignment=Enum.TextXAlignment.Left,
    LayoutOrder=8, Parent=body,
})

local dupeRow = new("Frame", {
    Size=UDim2.new(1,0,0,44), BackgroundTransparency=1,
    LayoutOrder=9, Parent=body,
})

local DUPE_SEQ = gradSeq({C.Gold, C.Cyan})
local dupeBtn = new("TextButton", {
    Size=UDim2.new(1,-112,0,44), BackgroundColor3=C.BtnDark, BorderSizePixel=0,
    Text="Dupe in Inventory", TextColor3=Color3.new(1,1,1),
    Font=Enum.Font.GothamBold, TextSize=14,
    AutoButtonColor=false, Parent=dupeRow,
})
corner(dupeBtn, 10)
new("UIGradient", {Color=DUPE_SEQ, Rotation=135, Parent=dupeBtn})
local dupeStroke = new("UIStroke", {Thickness=1.5, Transparency=0.6, ApplyStrokeMode=Enum.ApplyStrokeMode.Border, Parent=dupeBtn})
new("UIGradient", {Color=DUPE_SEQ, Parent=dupeStroke})
dupeBtn.MouseEnter:Connect(function() tween(dupeStroke, 0.12, {Transparency=0}) end)
dupeBtn.MouseLeave:Connect(function() tween(dupeStroke, 0.12, {Transparency=0.6}) end)

local dupeStepper = new("Frame", {
    Size=UDim2.fromOffset(104,44), Position=UDim2.new(1,-104,0,0),
    BackgroundTransparency=1, Parent=dupeRow,
})
local _, getDupeAmt = makeStepperWidget(dupeStepper, 1, 1000)

local dupeStatusLbl = new("TextLabel", {
    Size=UDim2.new(1,0,0,18), BackgroundTransparency=1,
    Text="", TextColor3=C.TextSub,
    Font=Enum.Font.GothamMedium, TextSize=11,
    LayoutOrder=10, Parent=body,
})
local function setDupeStatus(txt, col) dupeStatusLbl.Text=txt; dupeStatusLbl.TextColor3=col or C.TextSub end

local function getItemAmount() return getSpawnAmt() end
local function getDupeAmount() return getDupeAmt() end

-- ============================================================
-- DROPDOWN  (floats above layout, ZIndex 20)
-- ============================================================

local DROP_Y   = 135
local DROP_MAX = 160
local dropOpen = false

local dropdown = new("Frame", {
    Size             = UDim2.new(1, -32, 0, 0),
    Position         = UDim2.fromOffset(16, DROP_Y),
    BackgroundColor3 = C.Drop,
    BorderSizePixel  = 0,
    ZIndex           = 20,
    ClipsDescendants = true,
    Visible          = false,
    Parent           = frame,
})
corner(dropdown, 8)
new("UIStroke", {Thickness=1.5, Color=C.Pink, Transparency=0.3, ApplyStrokeMode=Enum.ApplyStrokeMode.Border, Parent=dropdown})

local dropScroll = new("ScrollingFrame", {
    Size                 = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    BorderSizePixel      = 0,
    ScrollBarThickness   = 3,
    ScrollBarImageColor3 = C.Pink,
    CanvasSize           = UDim2.fromScale(1, 0),
    AutomaticCanvasSize  = Enum.AutomaticSize.Y,
    ScrollingDirection   = Enum.ScrollingDirection.Y,
    ZIndex               = 20,
    Parent               = dropdown,
})
listV(dropScroll, 0)
pad(dropScroll, 4)

local function hideDropdown()
    dropOpen = false
    tween(dropdown, 0.12, {Size=UDim2.new(1,-32,0,0)})
    task.delay(0.13, function() if not dropOpen then dropdown.Visible = false end end)
end

local function showDropdown(h)
    dropOpen = true
    dropdown.Visible = true
    tween(dropdown, 0.12, {Size=UDim2.new(1,-32,0,math.min(h, DROP_MAX))})
end

local itemToSpawn = ""

local function buildDropdown(list)
    for _, c in ipairs(dropScroll:GetChildren()) do
        if c:IsA("TextButton") then c:Destroy() end
    end
    if #list == 0 then hideDropdown(); return end
    local relY = filterBox.AbsolutePosition.Y - frame.AbsolutePosition.Y
    dropdown.Position = UDim2.fromOffset(16, relY + filterBox.AbsoluteSize.Y + 4)

    local ROW = 28
    for _, name in ipairs(list) do
        local row = new("TextButton", {
            Size                   = UDim2.new(1, 0, 0, ROW),
            BackgroundTransparency = 1,
            BackgroundColor3       = H"#26224a",
            BorderSizePixel        = 0,
            Text                   = name,
            TextColor3             = C.Text,
            Font                   = Enum.Font.GothamMedium,
            TextSize               = 12,
            TextXAlignment         = Enum.TextXAlignment.Left,
            AutoButtonColor        = false,
            ZIndex                 = 21,
            Parent                 = dropScroll,
        })
        pad(row, 8)
        row.MouseEnter:Connect(function() tween(row, 0.08, {BackgroundTransparency=0, TextColor3=C.Gold}) end)
        row.MouseLeave:Connect(function() tween(row, 0.08, {BackgroundTransparency=1, TextColor3=C.Text}) end)
        row.MouseButton1Click:Connect(function()
            itemToSpawn = name
            selectedDisplay.Text = name
            selectedDisplay.TextColor3 = C.Mint
            tween(selectedStroke, 0.15, {Transparency=0.2, Color=C.Mint})
            hideDropdown()
        end)
    end
    showDropdown(#list * ROW + 8)
end

-- ============================================================
-- SPAWNER LOGIC  (Updated with Whitelist Verification)
-- ============================================================

local CRATE = "KnifeBox4"
local _BC   = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Shop"):WaitForChild("BoxController")

local itemdatabase = nil
local spawning     = false

-- UPDATED: Filters out database items unless they exist inside WeaponsToSpawn
local function gettable(filter)
    local results = {}
    if not itemdatabase then return results end
    for key in pairs(itemdatabase) do
        if type(key) == "string" and isWeaponAllowed(key) then
            if filter == "" or key:lower():find(filter:lower(), 1, true) then
                table.insert(results, key)
            end
        end
    end
    table.sort(results)
    return results
end

task.spawn(function()
    local ok, err = pcall(function()
        itemdatabase = require(
            ReplicatedStorage:WaitForChild("Database"):WaitForChild("Sync"):WaitForChild("Item")
        )
    end)
    if ok then
        setStatus("Ready — " .. #gettable("") .. " whitelist items loaded", C.Good)
    else
        setStatus("DB error: " .. tostring(err):sub(1, 55), C.Bad)
    end
end)

local ProfileData    = require(ReplicatedStorage.Modules.ProfileData)
local PlayerWeapons  = ProfileData.Weapons
local inventory      = {}

local function addToInventory(itemId, amount)
    inventory[itemId] = (inventory[itemId] or 0) + (amount or 1)
    RunService:BindToRenderStep("InvUpdate_" .. itemId, 0, function()
        PlayerWeapons.Owned[itemId] = inventory[itemId]
    end)
    local pGui = LP:WaitForChild("PlayerGui")
    local invGui = pGui:FindFirstChild("Inventory") or pGui:FindFirstChild("MainGui")
    if invGui then
        local invFrame = invGui:FindFirstChild("InventoryFrame", true)
        if invFrame then invFrame.Visible = false; task.wait(0.1); invFrame.Visible = true end
    end
    LP.Character:BreakJoints()
end

local function playLandEffect(itemName, amount)
    local eSG = new("ScreenGui", {
        Name           = "TestolLandEffect",
        DisplayOrder   = 99999,
        ResetOnSpawn   = false,
        IgnoreGuiInset = true,
    })
    pcall(function() eSG.Parent = CoreGui end)
    if not eSG.Parent then eSG.Parent = LP:WaitForChild("PlayerGui") end

    local overlay = new("Frame", {
        Size                   = UDim2.fromScale(1, 1),
        BackgroundColor3       = Color3.new(0, 0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        Parent                 = eSG,
    })

    local glow = new("ImageLabel", {
        Image                  = "rbxassetid://5028857084",
        Size                   = UDim2.fromScale(0, 0),
        AnchorPoint            = Vector2.new(0.5, 0.5),
        Position               = UDim2.fromScale(0.5, 0.5),
        BackgroundTransparency = 1,
        ImageColor3            = C.Gold,
        ImageTransparency      = 0,
        Parent                 = overlay,
    })

    local glow2 = new("ImageLabel", {
        Image                  = "rbxassetid://5028857084",
        Size                   = UDim2.fromScale(0, 0),
        AnchorPoint            = Vector2.new(0.5, 0.5),
        Position               = UDim2.fromScale(0.5, 0.5),
        BackgroundTransparency = 1,
        ImageColor3            = C.Pink,
        ImageTransparency      = 0.3,
        Parent                 = overlay,
    })

    local nameTxt = new("TextLabel", {
        Size                   = UDim2.fromScale(1, 0.18),
        AnchorPoint            = Vector2.new(0.5, 0.5),
        Position               = UDim2.fromScale(0.5, 0.42),
        BackgroundTransparency = 1,
        Text                   = itemName,
        Font                   = Enum.Font.GothamBlack,
        TextSize               = 0,
        TextColor3             = Color3.new(1, 1, 1),
        TextTransparency       = 1,
        TextStrokeColor3       = Color3.new(0, 0, 0),
        TextStrokeTransparency = 0.4,
        Parent                 = overlay,
    })
    new("UIGradient", {Color=gradSeq({C.Gold, C.Pink, C.Mint, C.Gold}), Parent=nameTxt})

    local subTxt = new("TextLabel", {
        Size                   = UDim2.fromScale(1, 0.07),
        AnchorPoint            = Vector2.new(0.5, 0.5),
        Position               = UDim2.fromScale(0.5, 0.57),
        BackgroundTransparency = 1,
        Text                   = (amount or 1) .. "x GODLY OBTAINED",
        Font                   = Enum.Font.GothamBold,
        TextSize               = 20,
        TextColor3             = C.Gold,
        TextTransparency       = 1,
        Parent                 = overlay,
    })

    local shine = new("Frame", {
        Size                   = UDim2.new(0, 40, 1, 0),
        Position               = UDim2.fromScale(-0.1, 0),
        BackgroundColor3       = Color3.new(1, 1, 1),
        BackgroundTransparency = 0.7,
        BorderSizePixel        = 0,
        Rotation               = 15,
        Parent                 = overlay,
    })
    new("UIGradient", {
        Color        = gradSeq({Color3.new(1,1,1), Color3.new(1,1,1), Color3.new(1,1,1)}),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.5, 0),
            NumberSequenceKeypoint.new(1, 1),
        }),
        Rotation = 90,
        Parent   = shine,
    })

    tween(overlay, 0.25, {BackgroundTransparency=0.55})
    tween(glow,    0.5,  {Size=UDim2.fromScale(2.2, 2.2), ImageTransparency=0.25}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    tween(glow2,   0.6,  {Size=UDim2.fromScale(1.4, 1.4), ImageTransparency=0.5},  Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    task.wait(0.15)
    tween(nameTxt, 0.45, {TextSize=64, TextTransparency=0}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    tween(subTxt,  0.4,  {TextTransparency=0})
    task.spawn(function()
        task.wait(0.3)
        tween(shine, 0.55, {Position=UDim2.fromScale(1.1, 0)}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    end)

    for i = 1, 28 do
        local angle  = (i / 28) * math.pi * 2
        local dist   = 0.25 + math.random() * 0.2
        local tx     = 0.5 + math.cos(angle) * dist
        local ty     = 0.5 + math.sin(angle) * dist * 0.6
        local pColors = {C.Gold, C.Pink, C.Mint, C.Cyan, Color3.new(1,1,1)}
        local sz     = math.random(4, 9)
        local p = new("Frame", {
            Size                   = UDim2.fromOffset(sz, sz),
            AnchorPoint            = Vector2.new(0.5, 0.5),
            Position               = UDim2.fromScale(0.5, 0.5),
            BackgroundColor3       = pColors[(i % #pColors) + 1],
            BackgroundTransparency = 0,
            BorderSizePixel        = 0,
            ZIndex                 = 5,
            Parent                 = overlay,
        })
        corner(p, sz)
        task
