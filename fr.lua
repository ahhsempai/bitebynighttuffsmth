



















































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local AnimationClipProvider = game:GetService("AnimationClipProvider")
local GuiService = game:GetService("GuiService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local ScannedTools = {}
local AnimConfigs = {}

local SelectedAnim = nil
local PreviewTrack = nil
local PreviewOverlayTrack = nil

local ActiveOverlayTracks = {}

local rightMinimized = false
local leftMinimized = false

local function getNumericId(idStr)
    if not idStr then return nil end
    return tostring(idStr):match("%d+")
end

local function getConfig(animId)
    local numId = getNumericId(animId)
    if not numId then return nil end
    if not AnimConfigs[numId] then
        AnimConfigs[numId] = {
            startPos = 0,
            stopPos = 0,
            speed = 1.0,
            holds = {},
            skips = {},
            speeds = {},
            overlayId = nil,
            overlayName = nil,
            overlaySpeed = 1.0
        }
    end
    return AnimConfigs[numId]
end

local function getAnimLength(animId)
    local numId = getNumericId(animId)
    if not numId then return 0 end
    local fullAsset = "rbxassetid://" .. numId
    
    local ok, clip = pcall(function()
        return AnimationClipProvider:GetAnimationClipAsync(fullAsset)
    end)
    if ok and clip then
        local len = clip.Length
        clip:Destroy()
        return len
    end
    return 0
end

local CUSTOM_MELEE_MAPPINGS = {
    ["Hell's Excalibur V2"] = "Crucible",
    ["Sea Beast"] = "Samehada"
}

local function scanAndCacheTool(tool)
    if not tool or not tool:IsA("Tool") then return end
    local toolName = tool.Name

    if not ScannedTools[toolName] then
        ScannedTools[toolName] = {
            name = toolName,
            expanded = true,
            anims = {}
        }
    end

    local toolRecord = ScannedTools[toolName]
    local foundIds = {}

    local shared = ReplicatedStorage:FindFirstChild("Shared")
    local assets = shared and shared:FindFirstChild("Assets")
    local meleeFolder = assets and assets:FindFirstChild("Melee")

    if meleeFolder then
        local targetFolderName = CUSTOM_MELEE_MAPPINGS[toolName] or toolName
        local folder = meleeFolder:FindFirstChild(targetFolderName)
        
        if not folder then
            local cleanName = toolName:lower():gsub("%s+", "")
            for _, f in ipairs(meleeFolder:GetChildren()) do
                if f.Name:lower():gsub("%s+", "") == cleanName then
                    folder = f
                    break
                end
            end
        end

        if folder and folder:FindFirstChild("Animations") then
            for _, child in ipairs(folder.Animations:GetChildren()) do
                if child.Name:lower():find("slash") or child:IsA("Animation") then
                    local id = child:IsA("Animation") and child.AnimationId or (child:FindFirstChildOfClass("Animation") and child:FindFirstChildOfClass("Animation").AnimationId)
                    local numId = getNumericId(id)
                    if numId and not foundIds[numId] then
                        foundIds[numId] = true
                        toolRecord.anims[numId] = {
                            id = numId,
                            name = child.Name,
                            length = getAnimLength(numId)
                        }
                    end
                end
            end
        end
    end

    for _, desc in ipairs(tool:GetDescendants()) do
        if desc:IsA("Animation") then
            local numId = getNumericId(desc.AnimationId)
            if numId and not foundIds[numId] then
                foundIds[numId] = true
                toolRecord.anims[numId] = {
                    id = numId,
                    name = desc.Name,
                    length = getAnimLength(numId)
                }
            end
        end
    end
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CustomizerExplorerGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = PlayerGui

local rightFrame = Instance.new("Frame")
rightFrame.Name = "RightExplorer"
rightFrame.Size = UDim2.new(0, 340, 0, 520)
rightFrame.Position = UDim2.new(1, -360, 0.5, -260)
rightFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
rightFrame.BorderSizePixel = 0
rightFrame.Parent = screenGui
Instance.new("UICorner", rightFrame).CornerRadius = UDim.new(0, 10)

local rightStroke = Instance.new("UIStroke")
rightStroke.Color = Color3.fromRGB(60, 60, 70)
rightStroke.Thickness = 1
rightStroke.Parent = rightFrame

local rightTitleBar = Instance.new("Frame")
rightTitleBar.Size = UDim2.new(1, 0, 0, 40)
rightTitleBar.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
rightTitleBar.BorderSizePixel = 0
rightTitleBar.Parent = rightFrame
Instance.new("UICorner", rightTitleBar).CornerRadius = UDim.new(0, 10)

local rightTitle = Instance.new("TextLabel")
rightTitle.Size = UDim2.new(1, -50, 1, 0)
rightTitle.Position = UDim2.new(0, 12, 0, 0)
rightTitle.BackgroundTransparency = 1
rightTitle.Text = "Weapon Anim Cache"
rightTitle.Font = Enum.Font.GothamBold
rightTitle.TextSize = 14
rightTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
rightTitle.TextXAlignment = Enum.TextXAlignment.Left
rightTitle.Parent = rightTitleBar

local rightMinBtn = Instance.new("TextButton")
rightMinBtn.Size = UDim2.new(0, 26, 0, 26)
rightMinBtn.Position = UDim2.new(1, -32, 0, 7)
rightMinBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
rightMinBtn.Text = "-"
rightMinBtn.Font = Enum.Font.GothamBold
rightMinBtn.TextSize = 14
rightMinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
rightMinBtn.Parent = rightTitleBar
Instance.new("UICorner", rightMinBtn).CornerRadius = UDim.new(0, 6)

local treeScroll = Instance.new("ScrollingFrame")
treeScroll.Size = UDim2.new(1, -16, 1, -50)
treeScroll.Position = UDim2.new(0, 8, 0, 44)
treeScroll.BackgroundTransparency = 1
treeScroll.ScrollBarThickness = 5
treeScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
treeScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
treeScroll.Parent = rightFrame

local treeLayout = Instance.new("UIListLayout")
treeLayout.SortOrder = Enum.SortOrder.LayoutOrder
treeLayout.Padding = UDim.new(0, 3)
treeLayout.Parent = treeScroll

rightMinBtn.MouseButton1Click:Connect(function()
    rightMinimized = not rightMinimized
    if rightMinimized then
        rightFrame.Size = UDim2.new(0, 340, 0, 40)
        treeScroll.Visible = false
        rightMinBtn.Text = "+"
    else
        rightFrame.Size = UDim2.new(0, 340, 0, 520)
        treeScroll.Visible = true
        rightMinBtn.Text = "-"
    end
end)

local leftFrame = Instance.new("Frame")
leftFrame.Name = "LeftModifier"
leftFrame.Size = UDim2.new(0, 380, 0, 580)
leftFrame.Position = UDim2.new(0, 20, 0.5, -290)
leftFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
leftFrame.BorderSizePixel = 0
leftFrame.Visible = false
leftFrame.Parent = screenGui
Instance.new("UICorner", leftFrame).CornerRadius = UDim.new(0, 10)

local leftStroke = Instance.new("UIStroke")
leftStroke.Color = Color3.fromRGB(60, 60, 70)
leftStroke.Thickness = 1
leftStroke.Parent = leftFrame

local leftTitleBar = Instance.new("Frame")
leftTitleBar.Size = UDim2.new(1, 0, 0, 40)
leftTitleBar.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
leftTitleBar.BorderSizePixel = 0
leftTitleBar.Parent = leftFrame
Instance.new("UICorner", leftTitleBar).CornerRadius = UDim.new(0, 10)

local leftTitle = Instance.new("TextLabel")
leftTitle.Size = UDim2.new(1, -50, 1, 0)
leftTitle.Position = UDim2.new(0, 12, 0, 0)
leftTitle.BackgroundTransparency = 1
leftTitle.Text = "Customizer lol"
leftTitle.Font = Enum.Font.GothamBold
leftTitle.TextSize = 14
leftTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
leftTitle.TextXAlignment = Enum.TextXAlignment.Left
leftTitle.Parent = leftTitleBar

local leftMinBtn = Instance.new("TextButton")
leftMinBtn.Size = UDim2.new(0, 26, 0, 26)
leftMinBtn.Position = UDim2.new(1, -32, 0, 7)
leftMinBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
leftMinBtn.Text = "-"
leftMinBtn.Font = Enum.Font.GothamBold
leftMinBtn.TextSize = 14
leftMinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
leftMinBtn.Parent = leftTitleBar
Instance.new("UICorner", leftMinBtn).CornerRadius = UDim.new(0, 6)

local animInfoLabel = Instance.new("TextLabel")
animInfoLabel.Size = UDim2.new(1, -20, 0, 32)
animInfoLabel.Position = UDim2.new(0, 10, 0, 44)
animInfoLabel.BackgroundTransparency = 1
animInfoLabel.Text = "No Animation Selected"
animInfoLabel.Font = Enum.Font.GothamMedium
animInfoLabel.TextSize = 11
animInfoLabel.TextColor3 = Color3.fromRGB(180, 210, 255)
animInfoLabel.TextXAlignment = Enum.TextXAlignment.Left
animInfoLabel.Parent = leftFrame

local previewFrame = Instance.new("Frame")
previewFrame.Size = UDim2.new(1, -20, 0, 46)
previewFrame.Position = UDim2.new(0, 10, 0, 78)
previewFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
previewFrame.BorderSizePixel = 0
previewFrame.Parent = leftFrame
Instance.new("UICorner", previewFrame).CornerRadius = UDim.new(0, 6)

local btnPreviewPlay = Instance.new("TextButton")
btnPreviewPlay.Size = UDim2.new(0, 75, 0, 30)
btnPreviewPlay.Position = UDim2.new(0, 8, 0.5, -15)
btnPreviewPlay.BackgroundColor3 = Color3.fromRGB(45, 140, 80)
btnPreviewPlay.Text = "Test Anim"
btnPreviewPlay.Font = Enum.Font.GothamBold
btnPreviewPlay.TextSize = 11
btnPreviewPlay.TextColor3 = Color3.fromRGB(255, 255, 255)
btnPreviewPlay.Parent = previewFrame
Instance.new("UICorner", btnPreviewPlay).CornerRadius = UDim.new(0, 6)

local previewTimeLabel = Instance.new("TextLabel")
previewTimeLabel.Size = UDim2.new(1, -95, 0, 14)
previewTimeLabel.Position = UDim2.new(0, 90, 0, 6)
previewTimeLabel.BackgroundTransparency = 1
previewTimeLabel.Text = "0.00s / 0.00s"
previewTimeLabel.Font = Enum.Font.Code
previewTimeLabel.TextSize = 10
previewTimeLabel.TextColor3 = Color3.fromRGB(200, 200, 210)
previewTimeLabel.TextXAlignment = Enum.TextXAlignment.Left
previewTimeLabel.Parent = previewFrame

local sliderBar = Instance.new("Frame")
sliderBar.Size = UDim2.new(1, -100, 0, 4)
sliderBar.Position = UDim2.new(0, 90, 0, 26)
sliderBar.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
sliderBar.BorderSizePixel = 0
sliderBar.Parent = previewFrame
Instance.new("UICorner", sliderBar).CornerRadius = UDim.new(1, 0)

local sliderFill = Instance.new("Frame")
sliderFill.Size = UDim2.new(0, 0, 1, 0)
sliderFill.BackgroundColor3 = Color3.fromRGB(80, 140, 220)
sliderFill.BorderSizePixel = 0
sliderFill.Parent = sliderBar
Instance.new("UICorner", sliderFill).CornerRadius = UDim.new(1, 0)

local sliderKnob = Instance.new("Frame")
sliderKnob.Size = UDim2.new(0, 10, 0, 10)
sliderKnob.AnchorPoint = Vector2.new(0.5, 0.5)
sliderKnob.Position = UDim2.new(0, 0, 0.5, 0)
sliderKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
sliderKnob.BorderSizePixel = 0
sliderKnob.Parent = sliderBar
Instance.new("UICorner", sliderKnob).CornerRadius = UDim.new(1, 0)

local modScroll = Instance.new("ScrollingFrame")
modScroll.Size = UDim2.new(1, -20, 1, -135)
modScroll.Position = UDim2.new(0, 10, 0, 130)
modScroll.BackgroundTransparency = 1
modScroll.ScrollBarThickness = 5
modScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
modScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
modScroll.Parent = leftFrame

local modLayout = Instance.new("UIListLayout")
modLayout.SortOrder = Enum.SortOrder.LayoutOrder
modLayout.Padding = UDim.new(0, 8)
modLayout.Parent = modScroll

leftMinBtn.MouseButton1Click:Connect(function()
    leftMinimized = not leftMinimized
    if leftMinimized then
        leftFrame.Size = UDim2.new(0, 380, 0, 40)
        animInfoLabel.Visible = false
        previewFrame.Visible = false
        modScroll.Visible = false
        leftMinBtn.Text = "+"
    else
        leftFrame.Size = UDim2.new(0, 380, 0, 580)
        animInfoLabel.Visible = true
        previewFrame.Visible = true
        modScroll.Visible = true
        leftMinBtn.Text = "-"
    end
end)

local overlayPickerFrame = Instance.new("Frame")
overlayPickerFrame.Name = "OverlayPickerWindow"
overlayPickerFrame.Size = UDim2.new(0, 360, 0, 480)
overlayPickerFrame.Position = UDim2.new(0.5, -180, 0.5, -240)
overlayPickerFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
overlayPickerFrame.BorderSizePixel = 0
overlayPickerFrame.Visible = false
overlayPickerFrame.ZIndex = 30
overlayPickerFrame.Parent = screenGui
Instance.new("UICorner", overlayPickerFrame).CornerRadius = UDim.new(0, 10)

local pickerStroke = Instance.new("UIStroke")
pickerStroke.Color = Color3.fromRGB(80, 80, 95)
pickerStroke.Thickness = 1
pickerStroke.Parent = overlayPickerFrame

local pickerTitleBar = Instance.new("Frame")
pickerTitleBar.Size = UDim2.new(1, 0, 0, 40)
pickerTitleBar.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
pickerTitleBar.BorderSizePixel = 0
pickerTitleBar.ZIndex = 31
pickerTitleBar.Parent = overlayPickerFrame
Instance.new("UICorner", pickerTitleBar).CornerRadius = UDim.new(0, 10)

local pickerTitle = Instance.new("TextLabel")
pickerTitle.Size = UDim2.new(1, -40, 1, 0)
pickerTitle.Position = UDim2.new(0, 12, 0, 0)
pickerTitle.BackgroundTransparency = 1
pickerTitle.Text = "Select Overlay Animation (Shared)"
pickerTitle.Font = Enum.Font.GothamBold
pickerTitle.TextSize = 13
pickerTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
pickerTitle.TextXAlignment = Enum.TextXAlignment.Left
pickerTitle.ZIndex = 32
pickerTitle.Parent = pickerTitleBar

local pickerClose = Instance.new("TextButton")
pickerClose.Size = UDim2.new(0, 26, 0, 26)
pickerClose.Position = UDim2.new(1, -32, 0, 7)
pickerClose.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
pickerClose.Text = "X"
pickerClose.Font = Enum.Font.GothamBold
pickerClose.TextSize = 12
pickerClose.TextColor3 = Color3.fromRGB(255, 255, 255)
pickerClose.ZIndex = 32
pickerClose.Parent = pickerTitleBar
Instance.new("UICorner", pickerClose).CornerRadius = UDim.new(0, 6)

local pickerSearchBox = Instance.new("TextBox")
pickerSearchBox.Size = UDim2.new(1, -16, 0, 26)
pickerSearchBox.Position = UDim2.new(0, 8, 0, 46)
pickerSearchBox.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
pickerSearchBox.BorderSizePixel = 0
pickerSearchBox.Text = ""
pickerSearchBox.PlaceholderText = "Search animation by name..."
pickerSearchBox.PlaceholderColor3 = Color3.fromRGB(130, 130, 140)
pickerSearchBox.Font = Enum.Font.Gotham
pickerSearchBox.TextSize = 11
pickerSearchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
pickerSearchBox.TextXAlignment = Enum.TextXAlignment.Left
pickerSearchBox.ZIndex = 31
pickerSearchBox.Parent = overlayPickerFrame
Instance.new("UICorner", pickerSearchBox).CornerRadius = UDim.new(0, 6)
local pickerSearchPad = Instance.new("UIPadding")
pickerSearchPad.PaddingLeft = UDim.new(0, 8)
pickerSearchPad.Parent = pickerSearchBox

local pickerScroll = Instance.new("ScrollingFrame")
pickerScroll.Size = UDim2.new(1, -16, 1, -84)
pickerScroll.Position = UDim2.new(0, 8, 0, 78)
pickerScroll.BackgroundTransparency = 1
pickerScroll.ScrollBarThickness = 5
pickerScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
pickerScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
pickerScroll.ZIndex = 31
pickerScroll.Parent = overlayPickerFrame

local pickerLayout = Instance.new("UIListLayout")
pickerLayout.SortOrder = Enum.SortOrder.LayoutOrder
pickerLayout.Padding = UDim.new(0, 2)
pickerLayout.Parent = pickerScroll

local function applyCustomizations(track, cfg)
    if not track or not cfg then return end

    local connection = nil
    local stopConnection = nil
    local triggeredHolds = {}
    local activeNegativeSegments = {}
    local finishedNegativeSegments = {}
    local lastTime = 0
    local isHolding = false
    local holdEndTime = 0

    if cfg.startPos and cfg.startPos > 0 then
        track.TimePosition = cfg.startPos
    end

    local baseSpeed = (cfg.speed and cfg.speed ~= 0) and cfg.speed or 1
    track:AdjustSpeed(baseSpeed)

    local function cleanup()
        if connection then
            connection:Disconnect()
            connection = nil
        end
        if stopConnection then
            stopConnection:Disconnect()
            stopConnection = nil
        end
    end

    stopConnection = track.Stopped:Connect(function()
        cleanup()
    end)

    connection = RunService.Heartbeat:Connect(function()
        if not track or not track.IsPlaying then
            cleanup()
            return
        end

        local curTime = track.TimePosition

        if curTime < lastTime - 0.2 and baseSpeed > 0 and not next(activeNegativeSegments) then
            triggeredHolds = {}
            activeNegativeSegments = {}
            finishedNegativeSegments = {}
        end
        lastTime = curTime

        if cfg.stopPos and cfg.stopPos > 0 and curTime >= cfg.stopPos and track.Speed > 0 then
            track:Stop(0.05)
            cleanup()
            return
        end

        for _, skip in ipairs(cfg.skips) do
            if skip.from and skip.to and curTime >= skip.from and curTime < skip.to then
                track.TimePosition = skip.to
                curTime = skip.to
            end
        end

        local now = os.clock()
        if isHolding then
            if now < holdEndTime then
                return
            else
                isHolding = false
            end
        end

        for idx, hold in ipairs(cfg.holds) do
            if hold.atTime and hold.duration and hold.duration > 0 then
                if curTime >= hold.atTime and not triggeredHolds[idx] then
                    triggeredHolds[idx] = true
                    isHolding = true
                    holdEndTime = now + hold.duration
                    track:AdjustSpeed(0)
                    return
                end
            end
        end

        local activeSpeed = baseSpeed
        for idx, spdSeg in ipairs(cfg.speeds) do
            if spdSeg.from and spdSeg.to and spdSeg.speed then
                local s = spdSeg.speed
                local p1 = spdSeg.from
                local p2 = spdSeg.to

                if s < 0 then
                    local startPoint = math.max(p1, p2)
                    local endPoint = math.min(p1, p2)

                    if activeNegativeSegments[idx] then
                        if curTime <= endPoint then
                            activeNegativeSegments[idx] = false
                            finishedNegativeSegments[idx] = true
                        else
                            activeSpeed = s
                            break
                        end
                    else
                        if not finishedNegativeSegments[idx] then
                            if curTime >= startPoint then
                                activeNegativeSegments[idx] = true
                                activeSpeed = s
                                break
                            end
                        end
                    end
                else
                    local minP = math.min(p1, p2)
                    local maxP = math.max(p1, p2)
                    if curTime >= minP and curTime <= maxP then
                        activeSpeed = s
                        break
                    end
                end
            end
        end

        if track.IsPlaying and track.Speed ~= activeSpeed then
            track:AdjustSpeed(activeSpeed)
        end
    end)
end

local renderTreeUI, renderModifierUI, renderOverlayPickerTree

local function createInputRow(parent, labelText, defaultVal, onChange)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 26)
    row.BackgroundTransparency = 1
    row.Parent = parent

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.65, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 11
    lbl.TextColor3 = Color3.fromRGB(200, 200, 210)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0.35, 0, 1, 0)
    box.Position = UDim2.new(0.65, 0, 0, 0)
    box.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    box.BorderSizePixel = 0
    box.Text = tostring(defaultVal)
    box.Font = Enum.Font.Code
    box.TextSize = 11
    box.TextColor3 = Color3.fromRGB(255, 255, 255)
    box.Parent = row
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 4)

    box.FocusLost:Connect(function()
        local val = tonumber(box.Text)
        if val then
            onChange(val)
        else
            box.Text = tostring(defaultVal)
        end
    end)

    return row
end

renderModifierUI = function()
    for _, child in ipairs(modScroll:GetChildren()) do
        if not child:IsA("UIListLayout") then
            child:Destroy()
        end
    end

    if not SelectedAnim then
        leftFrame.Visible = false
        return
    end

    leftFrame.Visible = true
    animInfoLabel.Visible = not leftMinimized
    previewFrame.Visible = not leftMinimized
    modScroll.Visible = not leftMinimized
    leftFrame.Size = leftMinimized and UDim2.new(0, 380, 0, 40) or UDim2.new(0, 380, 0, 580)

    local cfg = getConfig(SelectedAnim.id)

    animInfoLabel.Text = string.format("Name: %s\nWeapon: %s | ID: %s | Length: %.2fs", 
        SelectedAnim.name, SelectedAnim.toolName, SelectedAnim.id, SelectedAnim.length)

    local baseSection = Instance.new("Frame")
    baseSection.Size = UDim2.new(1, 0, 0, 96)
    baseSection.BackgroundColor3 = Color3.fromRGB(32, 32, 40)
    baseSection.Parent = modScroll
    Instance.new("UICorner", baseSection).CornerRadius = UDim.new(0, 6)
    
    local baseLayout = Instance.new("UIListLayout")
    baseLayout.Padding = UDim.new(0, 4)
    baseLayout.Parent = baseSection
    
    local basePad = Instance.new("UIPadding")
    basePad.PaddingLeft = UDim.new(0, 8)
    basePad.PaddingRight = UDim.new(0, 8)
    basePad.PaddingTop = UDim.new(0, 6)
    basePad.Parent = baseSection

    createInputRow(baseSection, "Start TimePosition:", cfg.startPos, function(v) cfg.startPos = v end)
    createInputRow(baseSection, "Stop TimePosition:", cfg.stopPos, function(v) cfg.stopPos = v end)
    createInputRow(baseSection, "Base Speed:", cfg.speed, function(v) cfg.speed = v end)

    local overlayHeader = Instance.new("TextLabel")
    overlayHeader.Size = UDim2.new(1, 0, 0, 18)
    overlayHeader.BackgroundTransparency = 1
    overlayHeader.Text = "Overlay Animation"
    overlayHeader.Font = Enum.Font.GothamBold
    overlayHeader.TextSize = 11
    overlayHeader.TextColor3 = Color3.fromRGB(220, 220, 230)
    overlayHeader.TextXAlignment = Enum.TextXAlignment.Left
    overlayHeader.Parent = modScroll

    local overlaySection = Instance.new("Frame")
    overlaySection.Size = UDim2.new(1, 0, 0, cfg.overlayId and 90 or 60)
    overlaySection.BackgroundColor3 = Color3.fromRGB(32, 32, 40)
    overlaySection.Parent = modScroll
    Instance.new("UICorner", overlaySection).CornerRadius = UDim.new(0, 6)

    local ovText = Instance.new("TextLabel")
    ovText.Size = UDim2.new(1, -16, 0, 22)
    ovText.Position = UDim2.new(0, 8, 0, 4)
    ovText.BackgroundTransparency = 1
    ovText.Text = cfg.overlayId and string.format("Active Overlay: %s (%s)", cfg.overlayName or "Anim", cfg.overlayId) or "No Overlay Assigned"
    ovText.Font = Enum.Font.Gotham
    ovText.TextSize = 10
    ovText.TextColor3 = cfg.overlayId and Color3.fromRGB(130, 220, 160) or Color3.fromRGB(170, 170, 180)
    ovText.TextXAlignment = Enum.TextXAlignment.Left
    ovText.TextTruncate = Enum.TextTruncate.AtEnd
    ovText.Parent = overlaySection

    local btnPickOverlay = Instance.new("TextButton")
    btnPickOverlay.Size = UDim2.new(0.48, -4, 0, 24)
    btnPickOverlay.Position = UDim2.new(0, 8, 0, 28)
    btnPickOverlay.BackgroundColor3 = Color3.fromRGB(45, 90, 165)
    btnPickOverlay.Text = "Choose Overlay..."
    btnPickOverlay.Font = Enum.Font.GothamBold
    btnPickOverlay.TextSize = 10
    btnPickOverlay.TextColor3 = Color3.fromRGB(255, 255, 255)
    btnPickOverlay.Parent = overlaySection
    Instance.new("UICorner", btnPickOverlay).CornerRadius = UDim.new(0, 4)

    btnPickOverlay.MouseButton1Click:Connect(function()
        overlayPickerFrame.Visible = true
        renderOverlayPickerTree()
    end)

    local btnRemoveOverlay = Instance.new("TextButton")
    btnRemoveOverlay.Size = UDim2.new(0.48, -4, 0, 24)
    btnRemoveOverlay.Position = UDim2.new(0.5, 4, 0, 28)
    btnRemoveOverlay.BackgroundColor3 = Color3.fromRGB(140, 45, 45)
    btnRemoveOverlay.Text = "Remove Overlay"
    btnRemoveOverlay.Font = Enum.Font.GothamBold
    btnRemoveOverlay.TextSize = 10
    btnRemoveOverlay.TextColor3 = Color3.fromRGB(255, 255, 255)
    btnRemoveOverlay.Parent = overlaySection
    Instance.new("UICorner", btnRemoveOverlay).CornerRadius = UDim.new(0, 4)

    btnRemoveOverlay.MouseButton1Click:Connect(function()
        cfg.overlayId = nil
        cfg.overlayName = nil
        renderModifierUI()
    end)

    if cfg.overlayId then
        local ovSpeedRow = createInputRow(overlaySection, "Overlay Speed:", cfg.overlaySpeed or 1.0, function(v) cfg.overlaySpeed = v end)
        ovSpeedRow.Position = UDim2.new(0, 8, 0, 58)
        ovSpeedRow.Size = UDim2.new(1, -16, 0, 24)
    end

    local holdsHeader = Instance.new("TextLabel")
    holdsHeader.Size = UDim2.new(1, 0, 0, 18)
    holdsHeader.BackgroundTransparency = 1
    holdsHeader.Text = "Delays"
    holdsHeader.Font = Enum.Font.GothamBold
    holdsHeader.TextSize = 11
    holdsHeader.TextColor3 = Color3.fromRGB(220, 220, 230)
    holdsHeader.TextXAlignment = Enum.TextXAlignment.Left
    holdsHeader.Parent = modScroll

    for idx, hold in ipairs(cfg.holds) do
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 28)
        row.BackgroundColor3 = Color3.fromRGB(32, 32, 40)
        row.Parent = modScroll
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 4)

        local boxAt = Instance.new("TextBox")
        boxAt.Size = UDim2.new(0.38, -5, 0, 20)
        boxAt.Position = UDim2.new(0, 5, 0, 4)
        boxAt.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
        boxAt.Text = "At: " .. tostring(hold.atTime) .. "s"
        boxAt.Font = Enum.Font.Code
        boxAt.TextSize = 10
        boxAt.TextColor3 = Color3.fromRGB(255, 255, 255)
        boxAt.Parent = row
        Instance.new("UICorner", boxAt).CornerRadius = UDim.new(0, 3)

        local boxDur = Instance.new("TextBox")
        boxDur.Size = UDim2.new(0.42, -5, 0, 20)
        boxDur.Position = UDim2.new(0.38, 5, 0, 4)
        boxDur.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
        boxDur.Text = "Pause: " .. tostring(hold.duration) .. "s"
        boxDur.Font = Enum.Font.Code
        boxDur.TextSize = 10
        boxDur.TextColor3 = Color3.fromRGB(255, 255, 255)
        boxDur.Parent = row
        Instance.new("UICorner", boxDur).CornerRadius = UDim.new(0, 3)

        boxAt.FocusLost:Connect(function()
            local v = tonumber(boxAt.Text:match("[%d%.%-]+"))
            if v then hold.atTime = v end
            boxAt.Text = "At: " .. tostring(hold.atTime) .. "s"
        end)

        boxDur.FocusLost:Connect(function()
            local v = tonumber(boxDur.Text:match("[%d%.%-]+"))
            if v then hold.duration = v end
            boxDur.Text = "Pause: " .. tostring(hold.duration) .. "s"
        end)

        local btnDel = Instance.new("TextButton")
        btnDel.Size = UDim2.new(0, 20, 0, 20)
        btnDel.Position = UDim2.new(1, -24, 0, 4)
        btnDel.BackgroundColor3 = Color3.fromRGB(140, 45, 45)
        btnDel.Text = "X"
        btnDel.Font = Enum.Font.GothamBold
        btnDel.TextSize = 10
        btnDel.TextColor3 = Color3.fromRGB(255, 255, 255)
        btnDel.Parent = row
        Instance.new("UICorner", btnDel).CornerRadius = UDim.new(0, 3)

        btnDel.MouseButton1Click:Connect(function()
            table.remove(cfg.holds, idx)
            renderModifierUI()
        end)
    end

    local btnAddHold = Instance.new("TextButton")
    btnAddHold.Size = UDim2.new(1, 0, 0, 22)
    btnAddHold.BackgroundColor3 = Color3.fromRGB(40, 50, 65)
    btnAddHold.Text = "Add Delay"
    btnAddHold.Font = Enum.Font.Gotham
    btnAddHold.TextSize = 10
    btnAddHold.TextColor3 = Color3.fromRGB(200, 220, 255)
    btnAddHold.Parent = modScroll
    Instance.new("UICorner", btnAddHold).CornerRadius = UDim.new(0, 4)

    btnAddHold.MouseButton1Click:Connect(function()
        table.insert(cfg.holds, { atTime = 0.0, duration = 0.2 })
        renderModifierUI()
    end)

    local skipsHeader = Instance.new("TextLabel")
    skipsHeader.Size = UDim2.new(1, 0, 0, 18)
    skipsHeader.BackgroundTransparency = 1
    skipsHeader.Text = "Skips"
    skipsHeader.Font = Enum.Font.GothamBold
    skipsHeader.TextSize = 11
    skipsHeader.TextColor3 = Color3.fromRGB(220, 220, 230)
    skipsHeader.TextXAlignment = Enum.TextXAlignment.Left
    skipsHeader.Parent = modScroll

    for idx, skip in ipairs(cfg.skips) do
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 28)
        row.BackgroundColor3 = Color3.fromRGB(32, 32, 40)
        row.Parent = modScroll
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 4)

        local boxFrom = Instance.new("TextBox")
        boxFrom.Size = UDim2.new(0.38, -5, 0, 20)
        boxFrom.Position = UDim2.new(0, 5, 0, 4)
        boxFrom.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
        boxFrom.Text = "From: " .. tostring(skip.from) .. "s"
        boxFrom.Font = Enum.Font.Code
        boxFrom.TextSize = 10
        boxFrom.TextColor3 = Color3.fromRGB(255, 255, 255)
        boxFrom.Parent = row
        Instance.new("UICorner", boxFrom).CornerRadius = UDim.new(0, 3)

        local boxTo = Instance.new("TextBox")
        boxTo.Size = UDim2.new(0.42, -5, 0, 20)
        boxTo.Position = UDim2.new(0.38, 5, 0, 4)
        boxTo.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
        boxTo.Text = "To: " .. tostring(skip.to) .. "s"
        boxTo.Font = Enum.Font.Code
        boxTo.TextSize = 10
        boxTo.TextColor3 = Color3.fromRGB(255, 255, 255)
        boxTo.Parent = row
        Instance.new("UICorner", boxTo).CornerRadius = UDim.new(0, 3)

        boxFrom.FocusLost:Connect(function()
            local v = tonumber(boxFrom.Text:match("[%d%.%-]+"))
            if v then skip.from = v end
            boxFrom.Text = "From: " .. tostring(skip.from) .. "s"
        end)

        boxTo.FocusLost:Connect(function()
            local v = tonumber(boxTo.Text:match("[%d%.%-]+"))
            if v then skip.to = v end
            boxTo.Text = "To: " .. tostring(skip.to) .. "s"
        end)

        local btnDel = Instance.new("TextButton")
        btnDel.Size = UDim2.new(0, 20, 0, 20)
        btnDel.Position = UDim2.new(1, -24, 0, 4)
        btnDel.BackgroundColor3 = Color3.fromRGB(140, 45, 45)
        btnDel.Text = "X"
        btnDel.Font = Enum.Font.GothamBold
        btnDel.TextSize = 10
        btnDel.TextColor3 = Color3.fromRGB(255, 255, 255)
        btnDel.Parent = row
        Instance.new("UICorner", btnDel).CornerRadius = UDim.new(0, 3)

        btnDel.MouseButton1Click:Connect(function()
            table.remove(cfg.skips, idx)
            renderModifierUI()
        end)
    end

    local btnAddSkip = Instance.new("TextButton")
    btnAddSkip.Size = UDim2.new(1, 0, 0, 22)
    btnAddSkip.BackgroundColor3 = Color3.fromRGB(40, 50, 65)
    btnAddSkip.Text = "Add Skip"
    btnAddSkip.Font = Enum.Font.Gotham
    btnAddSkip.TextSize = 10
    btnAddSkip.TextColor3 = Color3.fromRGB(200, 220, 255)
    btnAddSkip.Parent = modScroll
    Instance.new("UICorner", btnAddSkip).CornerRadius = UDim.new(0, 4)

    btnAddSkip.MouseButton1Click:Connect(function()
        table.insert(cfg.skips, { from = 0.5, to = 0.7 })
        renderModifierUI()
    end)

    local speedsHeader = Instance.new("TextLabel")
    speedsHeader.Size = UDim2.new(1, 0, 0, 18)
    speedsHeader.BackgroundTransparency = 1
    speedsHeader.Text = "Speed Intervals"
    speedsHeader.Font = Enum.Font.GothamBold
    speedsHeader.TextSize = 11
    speedsHeader.TextColor3 = Color3.fromRGB(220, 220, 230)
    speedsHeader.TextXAlignment = Enum.TextXAlignment.Left
    speedsHeader.Parent = modScroll

    for idx, spdSeg in ipairs(cfg.speeds) do
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 28)
        row.BackgroundColor3 = Color3.fromRGB(32, 32, 40)
        row.Parent = modScroll
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 4)

        local boxFrom = Instance.new("TextBox")
        boxFrom.Size = UDim2.new(0.26, -3, 0, 20)
        boxFrom.Position = UDim2.new(0, 4, 0, 4)
        boxFrom.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
        boxFrom.Text = "F: " .. tostring(spdSeg.from)
        boxFrom.Font = Enum.Font.Code
        boxFrom.TextSize = 10
        boxFrom.TextColor3 = Color3.fromRGB(255, 255, 255)
        boxFrom.Parent = row
        Instance.new("UICorner", boxFrom).CornerRadius = UDim.new(0, 3)

        local boxTo = Instance.new("TextBox")
        boxTo.Size = UDim2.new(0.26, -3, 0, 20)
        boxTo.Position = UDim2.new(0.26, 4, 0, 4)
        boxTo.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
        boxTo.Text = "T: " .. tostring(spdSeg.to)
        boxTo.Font = Enum.Font.Code
        boxTo.TextSize = 10
        boxTo.TextColor3 = Color3.fromRGB(255, 255, 255)
        boxTo.Parent = row
        Instance.new("UICorner", boxTo).CornerRadius = UDim.new(0, 3)

        local boxSpd = Instance.new("TextBox")
        boxSpd.Size = UDim2.new(0.28, -3, 0, 20)
        boxSpd.Position = UDim2.new(0.52, 4, 0, 4)
        boxSpd.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
        boxSpd.Text = "S: " .. tostring(spdSeg.speed)
        boxSpd.Font = Enum.Font.Code
        boxSpd.TextSize = 10
        boxSpd.TextColor3 = Color3.fromRGB(255, 255, 255)
        boxSpd.Parent = row
        Instance.new("UICorner", boxSpd).CornerRadius = UDim.new(0, 3)

        boxFrom.FocusLost:Connect(function()
            local v = tonumber(boxFrom.Text:match("[%d%.%-]+"))
            if v then spdSeg.from = v end
            boxFrom.Text = "F: " .. tostring(spdSeg.from)
        end)

        boxTo.FocusLost:Connect(function()
            local v = tonumber(boxTo.Text:match("[%d%.%-]+"))
            if v then spdSeg.to = v end
            boxTo.Text = "T: " .. tostring(spdSeg.to)
        end)

        boxSpd.FocusLost:Connect(function()
            local v = tonumber(boxSpd.Text:match("[%d%.%-]+"))
            if v then spdSeg.speed = v end
            boxSpd.Text = "S: " .. tostring(spdSeg.speed)
        end)

        local btnDel = Instance.new("TextButton")
        btnDel.Size = UDim2.new(0, 20, 0, 20)
        btnDel.Position = UDim2.new(1, -24, 0, 4)
        btnDel.BackgroundColor3 = Color3.fromRGB(140, 45, 45)
        btnDel.Text = "X"
        btnDel.Font = Enum.Font.GothamBold
        btnDel.TextSize = 10
        btnDel.TextColor3 = Color3.fromRGB(255, 255, 255)
        btnDel.Parent = row
        Instance.new("UICorner", btnDel).CornerRadius = UDim.new(0, 3)

        btnDel.MouseButton1Click:Connect(function()
            table.remove(cfg.speeds, idx)
            renderModifierUI()
        end)
    end

    local btnAddSpeed = Instance.new("TextButton")
    btnAddSpeed.Size = UDim2.new(1, 0, 0, 22)
    btnAddSpeed.BackgroundColor3 = Color3.fromRGB(40, 50, 65)
    btnAddSpeed.Text = "Add Speed Interval"
    btnAddSpeed.Font = Enum.Font.Gotham
    btnAddSpeed.TextSize = 10
    btnAddSpeed.TextColor3 = Color3.fromRGB(200, 220, 255)
    btnAddSpeed.Parent = modScroll
    Instance.new("UICorner", btnAddSpeed).CornerRadius = UDim.new(0, 4)

    btnAddSpeed.MouseButton1Click:Connect(function()
        table.insert(cfg.speeds, { from = 0.2, to = 0.5, speed = 2.0 })
        renderModifierUI()
    end)
end

renderTreeUI = function()
    for _, child in ipairs(treeScroll:GetChildren()) do
        if not child:IsA("UIListLayout") then
            child:Destroy()
        end
    end

    local toolCount = 0
    for toolName, toolRecord in pairs(ScannedTools) do
        toolCount = toolCount + 1

        local folderBtn = Instance.new("TextButton")
        folderBtn.Size = UDim2.new(1, 0, 0, 28)
        folderBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
        folderBtn.Text = string.format("  %s %s", toolRecord.expanded and "▼" or "▶", toolName)
        folderBtn.Font = Enum.Font.GothamBold
        folderBtn.TextSize = 11
        folderBtn.TextColor3 = Color3.fromRGB(235, 190, 100)
        folderBtn.TextXAlignment = Enum.TextXAlignment.Left
        folderBtn.Parent = treeScroll
        Instance.new("UICorner", folderBtn).CornerRadius = UDim.new(0, 4)

        folderBtn.MouseButton1Click:Connect(function()
            toolRecord.expanded = not toolRecord.expanded
            renderTreeUI()
        end)

        if toolRecord.expanded then
            for animId, animData in pairs(toolRecord.anims) do
                local animBtn = Instance.new("TextButton")
                animBtn.Size = UDim2.new(1, -16, 0, 24)
                animBtn.Position = UDim2.new(0, 16, 0, 0)
                
                local isSelected = SelectedAnim and SelectedAnim.id == animId
                animBtn.BackgroundColor3 = isSelected and Color3.fromRGB(45, 90, 165) or Color3.fromRGB(30, 30, 36)
                animBtn.Text = string.format("    %s (%.2fs)", animData.name, animData.length)
                animBtn.Font = Enum.Font.Gotham
                animBtn.TextSize = 11
                animBtn.TextColor3 = Color3.fromRGB(220, 220, 230)
                animBtn.TextXAlignment = Enum.TextXAlignment.Left
                animBtn.Parent = treeScroll
                Instance.new("UICorner", animBtn).CornerRadius = UDim.new(0, 4)

                animBtn.MouseButton1Click:Connect(function()
                    SelectedAnim = {
                        id = animId,
                        name = animData.name,
                        length = animData.length,
                        toolName = toolName
                    }
                    renderTreeUI()
                    renderModifierUI()
                end)
            end
        end
    end

    if toolCount == 0 then
        local emptyLbl = Instance.new("TextLabel")
        emptyLbl.Size = UDim2.new(1, 0, 0, 28)
        emptyLbl.BackgroundTransparency = 1
        emptyLbl.Text = "Equip a weapon to scan animations"
        emptyLbl.Font = Enum.Font.Gotham
        emptyLbl.TextSize = 11
        emptyLbl.TextColor3 = Color3.fromRGB(130, 130, 140)
        emptyLbl.Parent = treeScroll
    end
end

local pickerExpandedFolders = {}

local function scanSharedTree(container)
    local function traverse(inst)
        local children = {}
        local hasAnim = false

        for _, child in ipairs(inst:GetChildren()) do
            if child:IsA("Folder") or child:IsA("Model") or child:IsA("Configuration") then
                local subNode, subHasAnim = traverse(child)
                if subHasAnim then
                    table.insert(children, subNode)
                    hasAnim = true
                end
            elseif child:IsA("Animation") then
                local numId = getNumericId(child.AnimationId)
                if numId then
                    table.insert(children, {
                        name = child.Name,
                        instance = child,
                        isFolder = false,
                        id = numId,
                        animationId = child.AnimationId
                    })
                    hasAnim = true
                end
            end
        end

        local node = {
            name = inst.Name,
            instance = inst,
            isFolder = true,
            children = children
        }
        return node, hasAnim
    end

    local rootNode, rootHasAnim = traverse(container)
    return rootNode
end

renderOverlayPickerTree = function()
    for _, child in ipairs(pickerScroll:GetChildren()) do
        if not child:IsA("UIListLayout") then
            child:Destroy()
        end
    end

    local sharedContainer = ReplicatedStorage:FindFirstChild("Shared")
    if not sharedContainer then
        local noShared = Instance.new("TextLabel")
        noShared.Size = UDim2.new(1, 0, 0, 30)
        noShared.BackgroundTransparency = 1
        noShared.Text = "ReplicatedStorage.Shared not found!"
        noShared.Font = Enum.Font.Gotham
        noShared.TextSize = 11
        noShared.TextColor3 = Color3.fromRGB(255, 100, 100)
        noShared.Parent = pickerScroll
        return
    end

    local sharedTree = scanSharedTree(sharedContainer)
    local filterText = string.lower(pickerSearchBox.Text)

    local function renderNode(node, depth)
        local fullName = node.instance:GetFullName()
        
        if node.isFolder then
            if #node.children == 0 then return end

            local isExpanded = pickerExpandedFolders[fullName]
            if isExpanded == nil then
                isExpanded = false
                pickerExpandedFolders[fullName] = isExpanded
            end

            if filterText ~= "" then
                isExpanded = true
            end

            local folderFrame = Instance.new("Frame")
            folderFrame.Size = UDim2.new(1, 0, 0, 24)
            folderFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
            folderFrame.BorderSizePixel = 0
            folderFrame.Parent = pickerScroll
            Instance.new("UICorner", folderFrame).CornerRadius = UDim.new(0, 4)

            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 1, 0)
            btn.BackgroundTransparency = 1
            btn.Text = string.rep("  ", depth) .. (isExpanded and "▼ " or "▶ ") .. node.name
            btn.Font = Enum.Font.GothamBold
            btn.TextSize = 11
            btn.TextColor3 = Color3.fromRGB(235, 190, 100)
            btn.TextXAlignment = Enum.TextXAlignment.Left
            btn.Parent = folderFrame

            btn.MouseButton1Click:Connect(function()
                pickerExpandedFolders[fullName] = not pickerExpandedFolders[fullName]
                renderOverlayPickerTree()
            end)

            if isExpanded then
                for _, child in ipairs(node.children) do
                    renderNode(child, depth + 1)
                end
            end
        else
            if filterText ~= "" and not string.find(string.lower(node.name), filterText, 1, true) then
                return
            end

            local leafFrame = Instance.new("Frame")
            leafFrame.Size = UDim2.new(1, 0, 0, 22)
            leafFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
            leafFrame.BorderSizePixel = 0
            leafFrame.Parent = pickerScroll
            Instance.new("UICorner", leafFrame).CornerRadius = UDim.new(0, 4)

            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 1, 0)
            btn.BackgroundTransparency = 1
            btn.Text = string.rep("  ", depth + 1) .. "• " .. node.name .. " [" .. node.id .. "]"
            btn.Font = Enum.Font.Gotham
            btn.TextSize = 10
            btn.TextColor3 = Color3.fromRGB(120, 180, 255)
            btn.TextXAlignment = Enum.TextXAlignment.Left
            btn.Parent = leafFrame

            btn.MouseButton1Click:Connect(function()
                if SelectedAnim then
                    local cfg = getConfig(SelectedAnim.id)
                    cfg.overlayId = node.id
                    cfg.overlayName = node.name
                    overlayPickerFrame.Visible = false
                    renderModifierUI()
                end
            end)
        end
    end

    for _, child in ipairs(sharedTree.children) do
        renderNode(child, 0)
    end
end

pickerSearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    renderOverlayPickerTree()
end)

pickerClose.MouseButton1Click:Connect(function()
    overlayPickerFrame.Visible = false
end)

btnPreviewPlay.MouseButton1Click:Connect(function()
    if not SelectedAnim then return end

    local character = LocalPlayer.Character
    if not character then return end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
    if not animator then return end

    if PreviewTrack then
        PreviewTrack:Stop(0.1)
        PreviewTrack = nil
    end

    if PreviewOverlayTrack then
        PreviewOverlayTrack:Stop(0.1)
        PreviewOverlayTrack = nil
    end

    local cfg = getConfig(SelectedAnim.id)

    local animInst = Instance.new("Animation")
    animInst.AnimationId = "rbxassetid://" .. SelectedAnim.id

    local ok, track = pcall(function() return animator:LoadAnimation(animInst) end)
    if ok and track then
        PreviewTrack = track
        
        if cfg.overlayId then
            track.Priority = Enum.AnimationPriority.Core
        else
            track.Priority = Enum.AnimationPriority.Action4
        end
        
        track:Play(0.1)
        applyCustomizations(track, cfg)
    end

    if cfg.overlayId then
        local ovInst = Instance.new("Animation")
        ovInst.AnimationId = "rbxassetid://" .. cfg.overlayId
        local okOv, ovTrack = pcall(function() return animator:LoadAnimation(ovInst) end)
        if okOv and ovTrack then
            PreviewOverlayTrack = ovTrack
            ovTrack.Priority = Enum.AnimationPriority.Action4
            ovTrack:AdjustSpeed(cfg.overlaySpeed or 1.0)
            ovTrack:Play(0.1)
        end
    end
end)

RunService.Heartbeat:Connect(function()
    if PreviewTrack and SelectedAnim then
        local len = math.max(SelectedAnim.length, 0.01)
        local cur = PreviewTrack.TimePosition
        local frac = math.clamp(cur / len, 0, 1)

        sliderFill.Size = UDim2.new(frac, 0, 1, 0)
        sliderKnob.Position = UDim2.new(frac, 0, 0.5, 0)
        previewTimeLabel.Text = string.format("%.2fs / %.2fs", cur, len)

        if not PreviewTrack.IsPlaying then
            PreviewTrack = nil
            if PreviewOverlayTrack then
                PreviewOverlayTrack:Stop(0.1)
                PreviewOverlayTrack = nil
            end
        end
    elseif SelectedAnim then
        previewTimeLabel.Text = string.format("0.00s / %.2fs", SelectedAnim.length)
    end
end)

local characterConnections = {}

local function setupCharacter(character)
    for _, c in ipairs(characterConnections) do c:Disconnect() end
    characterConnections = {}

    local humanoid = character:WaitForChild("Humanoid")
    local animator = humanoid:WaitForChild("Animator", 10)
    if not animator then return end

    table.insert(characterConnections, animator.AnimationPlayed:Connect(function(track)
        local rawId = track.Animation and track.Animation.AnimationId or ""
        local numId = getNumericId(rawId)

        if numId and AnimConfigs[numId] then
            local cfg = AnimConfigs[numId]
            
            if cfg.overlayId then
                pcall(function()
                    track.Priority = Enum.AnimationPriority.Core
                end)

                for activeId, activeTrack in pairs(ActiveOverlayTracks) do
                    if activeTrack and activeTrack.IsPlaying then
                        activeTrack:Stop(0)
                    end
                end
                table.clear(ActiveOverlayTracks)

                local ovInst = Instance.new("Animation")
                ovInst.AnimationId = "rbxassetid://" .. cfg.overlayId
                local okOv, ovTrack = pcall(function() return animator:LoadAnimation(ovInst) end)
                if okOv and ovTrack then
                    ovTrack.Priority = Enum.AnimationPriority.Action4
                    ovTrack.Looped = false
                    ovTrack:Play(0)
                    if cfg.overlaySpeed then
                        ovTrack:AdjustSpeed(cfg.overlaySpeed)
                    end
                    ActiveOverlayTracks[numId] = ovTrack
                end
            end

            applyCustomizations(track, cfg)
        end
    end))

    table.insert(characterConnections, character.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            task.wait(0.05)
            scanAndCacheTool(child)
            renderTreeUI()
        end
    end))

    local currentTool = character:FindFirstChildOfClass("Tool")
    if currentTool then
        scanAndCacheTool(currentTool)
        renderTreeUI()
    end
end

if LocalPlayer.Character then
    task.spawn(setupCharacter, LocalPlayer.Character)
end

LocalPlayer.CharacterAdded:Connect(function(char)
    task.spawn(setupCharacter, char)
end)

renderTreeUI()


