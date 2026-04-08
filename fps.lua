local workspace = game:GetService("Workspace")
local Lighting  = game:GetService("Lighting")
local Players   = game:GetService("Players")

local lp = Players.LocalPlayer

if not game:IsLoaded() then
    repeat
        task.wait()
    until game:IsLoaded()
end

coroutine.wrap(pcall)(function()
    local terrain = workspace:FindFirstChildOfClass("Terrain")
    if not terrain then
        repeat
            task.wait()
        until workspace:FindFirstChildOfClass("Terrain")
        terrain = workspace:FindFirstChildOfClass("Terrain")
    end
    if sethiddenproperty then
        sethiddenproperty(terrain, "Decoration", false)
    else
        warn("Your exploit does not support sethiddenproperty, please use a different exploit.")
    end
    if _G.ConsoleLogs then
        warn("Decorations Disabled")
    end
end)


local function isPlayer(obj)
    if not obj then return false end
    if lp and (obj.Name == lp.Name or obj:IsDescendantOf(lp.Character or workspace)) then
        if obj:IsDescendantOf(workspace) and obj:FindFirstAncestor(lp.Name) then return true end
    end

    for _, player in ipairs(Players:GetPlayers()) do
        local character = player.Character
        if character and (obj == character or obj:IsDescendantOf(character)) then
            return true
        end
    end

    if obj:IsA("Model") and (obj:FindFirstChildOfClass("Humanoid") or obj:FindFirstChild("Head")) then
        return true
    end
    local lobby = workspace:FindFirstChild("Lobby")
    local elevator = lobby and lobby:FindFirstChild("Elevator")
    if elevator and (obj == elevator or obj:IsDescendantOf(elevator)) then
        return true
    end
    return false
end

local function getPath(root, path)
    local current = root
    for _, key in ipairs(path) do
        if current == nil then return nil end
        current = current:FindFirstChild(key)
    end
    return current
end

local function removeList(paths)
    for _, path in ipairs(paths) do
        local obj = getPath(workspace, path)
        if obj and not isPlayer(obj) then obj:Destroy() end
    end
end

local function removeChildrenByName(parent, name)
    if not parent then return end
    for _, child in ipairs(parent:GetChildren()) do
        if child.Name == name and not isPlayer(child) then child:Destroy() end
    end
end

local function removeDescendantsByName(root, name)
    if not root then return end
    for _, obj in ipairs(root:GetDescendants()) do
        if obj.Name == name and not isPlayer(obj) then obj:Destroy() end
    end
end

local function removeChildrenExcept(parent, exceptions)
    if not parent then return end
    for _, child in ipairs(parent:GetChildren()) do
        local keep = false
        for _, name in ipairs(exceptions) do
            if child.Name == name then keep = true; break end
        end
        if isPlayer(child) then keep = true end
        if not keep then child:Destroy() end
    end
end

local function stripTextures(obj)
    if isPlayer(obj) then return end
    
    local function deepClean(target)
        if target:IsA("SurfaceAppearance") or target:IsA("Texture") or target:IsA("Decal") then
            target:Destroy()
        end
    end

    deepClean(obj)
    for _, desc in ipairs(obj:GetDescendants()) do
        deepClean(desc)
    end
end

local function optimizePart(obj)
    if isPlayer(obj) then return end
    
    if obj:IsA("MeshPart") then
        obj.RenderFidelity = Enum.RenderFidelity.Automatic
    end
    if obj:IsA("BasePart") then
        obj.CastShadow = false
        obj.Material   = Enum.Material.SmoothPlastic
    end
    if obj:IsA("ParticleEmitter") or obj:IsA("Beam") or obj:IsA("Trail") then
        obj.Enabled = false
    end
    if obj:IsA("BillboardGui") or obj:IsA("SurfaceGui") then
        obj.Enabled = false
    end
end

local function nukeAllLights(root)
    for _, obj in ipairs(root:GetDescendants()) do
        if not isPlayer(obj) and (obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight")) then
            obj:Destroy()
        end
    end
end


local function isInsideBarrierOrBoundary(obj, stopAt)
    local lobby = workspace:FindFirstChild("Lobby")
    if lobby and obj:IsDescendantOf(lobby) then return false end

    local current = obj.Parent
    while current and current ~= stopAt and current ~= workspace do
        if current.Name == "BARRIER" or current.Name == "BOUNDARY" then
            return true
        end
        current = current.Parent
    end
    return false
end

local function applyBarrierStyle(obj)
    if isPlayer(obj) then return end
    stripTextures(obj)
    if obj:IsA("BasePart") then
        obj.Color        = Color3.fromRGB(0, 0, 0)
        obj.Transparency = 0.8
        obj.CastShadow   = false
        obj.Material     = Enum.Material.SmoothPlastic
    end
end


local function optimizeContainer(root)
    for _, obj in ipairs(root:GetDescendants()) do
        if obj.Name == "BARRIER" or obj.Name == "BOUNDARY" then
            applyBarrierStyle(obj)
        end
    end

    local snapshot = root:GetDescendants()
    for _, obj in ipairs(snapshot) do
        if not obj.Parent or isPlayer(obj) then continue end

        if obj.Name == "BARRIER" or obj.Name == "BOUNDARY" then continue end

        if isInsideBarrierOrBoundary(obj, root) then
            obj:Destroy()
            continue
        end

        if obj:IsA("BasePart") then
            if obj.Name == "Wall" or obj.Name == "Floor" then
                stripTextures(obj)
                continue
            end

            if obj.CanCollide == false or obj.Material == Enum.Material.Neon or obj.Material == Enum.Material.Glass then
                obj:Destroy()
            else
                optimizePart(obj)
                stripTextures(obj)
            end
        elseif obj:IsA("Model") or obj:IsA("Folder") then
            stripTextures(obj)
        end
    end
end

local function watchForLateTextures(container)
    container.DescendantAdded:Connect(function(desc)
        if isPlayer(desc) then return end
        if desc:IsA("SurfaceAppearance") or desc:IsA("Texture") or desc:IsA("Decal") then
            task.defer(function()
                if desc.Parent then desc:Destroy() end
            end)
        end
    end)
end

Lighting.GlobalShadows            = false
Lighting.FogEnd                   = 100000
Lighting.FogStart                 = 100000
Lighting.Brightness               = 1
Lighting.ClockTime                = 14
Lighting.Ambient                  = Color3.fromRGB(255, 255, 255)
Lighting.OutdoorAmbient           = Color3.fromRGB(255, 255, 255)

for _, child in ipairs(Lighting:GetChildren()) do
    if child:IsA("PostProcessEffect") or child:IsA("Atmosphere") or child:IsA("Sky") then
        child:Destroy()
    end
end

local terrain = workspace:FindFirstChildOfClass("Terrain")
if terrain then
    terrain.CastShadow = false
    terrain.WaterWaveSize = 0
    terrain.WaterWaveSpeed = 0
end


local function optimizeLobby()
    local lobby = workspace:FindFirstChild("Lobby")
    if not lobby then return end

    removeList({
        {"Lobby", "Union"}, {"Lobby", "CEILING"}, {"Lobby", "Token Packages"},
        {"Lobby", "Shelving"}, {"Lobby", "Pizza B0ss"}, {"Lobby", "Paper Family DECO"},
        {"Lobby", "Truss"}, {"Lobby", "Fog"}, {"Lobby", "headss"},
        {"Lobby", "Balloon"}, {"Lobby", "Present"},
        {"Lobby", "Box of DEATH"}, {"Lobby", "FullWinFolder", "1 Point"},
        {"Lobby", "LOBBY LIGHTS"}, {"Lobby", "FullWinFolder"},
        {"Lobby", "Fans"}, {"Lobby", "VFX"},
        {"Lobby", "LOBBY STRUCTURE", "TRUSS LOBBY"},
        {"Lobby", "LOBBY STRUCTURE", "Fan"},
        {"Lobby", "LOBBY STRUCTURE", "Carpet"},
        {"Lobby", "LOBBY STRUCTURE", "Walls"},
        {"Lobby", "LOBBY STRUCTURE", "Wall DIVIDER"},
        {"Lobby", "LOBBY STRUCTURE", "Pillars GROUPED"},
        {"Lobby", "LOBBY STRUCTURE", "LOBBY PIPES"}
    })

    local arcades = lobby:FindFirstChild("Arcades")
    if arcades then stripTextures(arcades) end

    for _, desc in ipairs(lobby:GetDescendants()) do
        if not isPlayer(desc) and desc:IsA("BasePart") then
            optimizePart(desc)
            stripTextures(desc)
        end
    end
end


local mapConfigs = {
    warehouse = {
        {"MAPS", "GAME MAP", "Cameras"},
        {"MAPS", "GAME MAP", "Other", "Base Screws"},
        {"MAPS", "GAME MAP", "Other", "Alarms"},
        {"MAPS", "GAME MAP", "Other", "BAY"},
        {"MAPS", "GAME MAP", "Other", "Acoustic Paneling Struct"},
        {"MAPS", "GAME MAP", "Other", "Divider"},
        {"MAPS", "GAME MAP", "Other", "Decals"},
        {"MAPS", "GAME MAP", "Other", "DataLink"},
        {"MAPS", "GAME MAP", "Other", "Corner Pillar"},
        {"MAPS", "GAME MAP", "Other", "Conveyor Variant B"},
        {"MAPS", "GAME MAP", "Other", "Conveyor Major Base"},
        {"MAPS", "GAME MAP", "Other", "Landmark"},
    },
    pizzeria = {
        {"MAPS", "GAME MAP", "Other", "FENCES"},
        {"MAPS", "GAME MAP", "Other", "BOUNDARIES"},
        {"MAPS", "GAME MAP", "Other", "DECORATION"},
        {"MAPS", "GAME MAP", "Other", "STRUCTURE", "LIGHTS"},
        {"MAPS", "GAME MAP", "Other", "STRUCTURE", "PILLAR"},
        {"MAPS", "GAME MAP", "Other", "STRUCTURE", "PIPES"},
        {"MAPS", "GAME MAP", "Other", "STRUCTURE", "SKIRTBOARD"},
        {"MAPS", "GAME MAP", "Other", "STRUCTURE", "SPOTLIGHTS"},
        {"MAPS", "GAME MAP", "Other", "STRUCTURE", "TILES CERAMIC"},
        {"MAPS", "GAME MAP", "Other", "STRUCTURE", "TRUSS"},
        {"MAPS", "GAME MAP", "Other", "STRUCTURE", "VENTS"},
        {"MAPS", "GAME MAP", "Other", "STRUCTURE", "WINDOWS"},
    },
    forest = {
        {"MAPS", "GAME MAP", "Thunder"},
        {"MAPS", "GAME MAP", "Other", "AFTON HOUSE"},
        {"MAPS", "GAME MAP", "Other", "Barbed Wires"},
        {"MAPS", "GAME MAP", "Other", "Campfire"},
        {"MAPS", "GAME MAP", "Other", "Tarpulins"},
        {"MAPS", "GAME MAP", "Other", "Tents"},
        {"MAPS", "GAME MAP", "Other", "MicellaneousS"},
        {"MAPS", "GAME MAP", "Other", "Light Trailers"},
        {"MAPS", "GAME MAP", "Other", "IBC Containers"},
        {"MAPS", "GAME MAP", "Other", "FloodLights"},
        {"MAPS", "GAME MAP", "Other", "Fencing"},
        {"MAPS", "GAME MAP", "Other", "Dirt Piles"},
        {"MAPS", "GAME MAP", "Other", "Tires"},
        {"MAPS", "GAME MAP", "Other", "Tables Wood"},
    },
}


local function optimizeGameMap(gameMap)
    for _, paths in pairs(mapConfigs) do
        for _, path in ipairs(paths) do
            local obj = getPath(workspace, path)
            if obj and not isPlayer(obj) then obj:Destroy() end
        end
    end

    local wallsWooden = getPath(workspace, {"MAPS", "GAME MAP", "Other", "WallsWooden"})
    if wallsWooden then
        removeChildrenByName(wallsWooden, "WallWooden")
    end

    local assets = getPath(workspace, {"MAPS", "GAME MAP", "Other", "ASSETS"})
    removeChildrenExcept(assets, {"Security Doors", "Stage Floor Stairs [STANDALONE]"})

    optimizeContainer(gameMap)
    nukeAllLights(gameMap)
    watchForLateTextures(gameMap)
end

local function setupIgnoreFolder(ignoreFolder)
    for _, child in ipairs(ignoreFolder:GetChildren()) do
        if not isPlayer(child) then
            if child.Name == "BARRIER" or child.Name == "BOUNDARY" then
                applyBarrierStyle(child)
                for _, sub in ipairs(child:GetDescendants()) do
                    if not isPlayer(sub) then sub:Destroy() end
                end
            else
                optimizeContainer(child)
            end
        end
    end
    ignoreFolder.ChildAdded:Connect(function(child)
        task.wait(1)
        if not isPlayer(child) then optimizeContainer(child) end
    end)
end

optimizeLobby()

local ignoreFolder = workspace:FindFirstChild("IGNORE")
if ignoreFolder then setupIgnoreFolder(ignoreFolder) end

workspace.ChildAdded:Connect(function(child)
    if child.Name == "IGNORE" then
        task.wait(1)
        setupIgnoreFolder(child)
    end
end)

local MAPS = workspace:FindFirstChild("MAPS")
if MAPS then
    local existingMap = MAPS:FindFirstChild("GAME MAP")
    if existingMap then optimizeGameMap(existingMap) end
    MAPS.ChildAdded:Connect(function(child)
        if child.Name == "GAME MAP" then
            task.wait(5)
            optimizeGameMap(child)
        end
    end)
end
