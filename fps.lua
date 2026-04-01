local workspace = game:GetService("Workspace")
local Lighting  = game:GetService("Lighting")

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
        if obj then obj:Destroy() end
    end
end

local function removeChildrenByName(parent, name)
    if not parent then return end
    for _, child in ipairs(parent:GetChildren()) do
        if child.Name == name then child:Destroy() end
    end
end

local function removeDescendantsByName(root, name)
    if not root then return end
    for _, obj in ipairs(root:GetDescendants()) do
        if obj.Name == name then obj:Destroy() end
    end
end

local function removeChildrenExcept(parent, exceptions)
    if not parent then return end
    for _, child in ipairs(parent:GetChildren()) do
        local keep = false
        for _, name in ipairs(exceptions) do
            if child.Name == name then keep = true break end
        end
        if not keep then child:Destroy() end
    end
end

local function optimizeMeshes(root)
    for _, obj in ipairs(root:GetDescendants()) do
        if obj:IsA("MeshPart") then
            obj.RenderFidelity = Enum.RenderFidelity.Automatic
        end
        if obj:IsA("BasePart") then
            obj.CastShadow = false
        end
        if obj:IsA("SurfaceAppearance") then
            obj:Destroy()
        end
        if obj:IsA("ParticleEmitter") or obj:IsA("Beam") or obj:IsA("Trail") then
            obj.Enabled = false
        end
        if obj:IsA("BillboardGui") or obj:IsA("SurfaceGui") then
            obj.Enabled = false
        end
    end
end

local function nukeAllLights(root)
    for _, obj in ipairs(root:GetDescendants()) do
        if obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight") then
            obj:Destroy()
        end
    end
    Lighting.Ambient        = Color3.fromRGB(255, 255, 255)
    Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
    Lighting.Brightness     = 2
end

Lighting.GlobalShadows            = false
Lighting.FogEnd                   = 100000
Lighting.FogStart                 = 100000
Lighting.Brightness               = 5
Lighting.ClockTime                = 14
Lighting.GeographicLatitude       = 0
Lighting.ExposureCompensation     = 1
Lighting.EnvironmentDiffuseScale  = 0
Lighting.EnvironmentSpecularScale = 0
Lighting.Ambient                  = Color3.fromRGB(255, 255, 255)
Lighting.OutdoorAmbient           = Color3.fromRGB(255, 255, 255)

for _, child in ipairs(Lighting:GetChildren()) do
    if  child:IsA("BloomEffect")
     or child:IsA("BlurEffect")
     or child:IsA("ColorCorrectionEffect")
     or child:IsA("DepthOfFieldEffect")
     or child:IsA("SunRaysEffect")
     or child:IsA("Atmosphere")
     or child:IsA("Sky")
    then
        child:Destroy()
    end
end

removeList({
    {"Lobby", "FullWinFolder", "1 Point"},
    {"Lobby", "LOBBY LIGHTS"},
    {"Lobby", "FullWinFolder"},
    {"Lobby", "Fans"},
    {"Lobby", "VFX"},
})

local lobby = workspace:FindFirstChild("Lobby")
if lobby then
    removeDescendantsByName(lobby, "PILLAR")
    removeDescendantsByName(lobby, "Paper Family DECO")
    removeDescendantsByName(lobby, "WALL GRUNGE")
    optimizeMeshes(lobby)
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
        {"MAPS", "GAME MAP", "Other", "BOUNDARIES"},
        {"MAPS", "GAME MAP", "Other", "FENCES"},
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
        {"MAPS", "GAME MAP", "Cameras"},
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
        {"MAPS", "GAME MAP", "Other", "Fences"},
        {"MAPS", "GAME MAP", "Other", "Dirt Piles"},
        {"MAPS", "GAME MAP", "Other", "Supply Crates"},
        {"MAPS", "GAME MAP", "Other", "Tires"},
        {"MAPS", "GAME MAP", "Other", "Tables Wood"},
    },
}


local ignoreRemoveAlways = {
    "VFX", "Map Ambience/Light", "LIGHT SOURCE", "LIGHTING"
}

local ignoreRemoveByMap = {
    forest    = {"Twigs [CASTSGADOW]", "Plant", "Naked Branches", "Canned Food [CASTSHADOW]", "Branches Filler", "BOUGHS", "Rocks2 [CASTSHADOW]"},
    warehouse = {"Conveyor Variant B", "Evidence Mockup", "HOLSTER WALL FILLERS", "LIGHTING", "Junction Electricity", "MESH WALL", "Perforated Chain Metal Link", "Vent Lighting", "WStrip", "Wiring Screw", "YStrip", "YStriped Square"},
    pizzeria  = {"Antislip Mat", "Arcade Actual Light", "Arcade Rod Ends", "Balloon", "Bench Leather", "DECALS NORMALS", "Door Handle", "LIGHT", "Middle-Pipe", "Monitor", "Monitor Screen", "Pipe", "SkirtBoard", "Spotlight"},
}

local function applyBarrier(obj)
    local parts = obj:IsA("BasePart") and {obj} or {}
    for _, desc in ipairs(obj:GetDescendants()) do
        if desc:IsA("BasePart") then table.insert(parts, desc) end
    end
    for _, part in ipairs(parts) do
        part.Color        = Color3.fromRGB(0, 0, 0)
        part.Transparency = 0.5
    end
end

local function applyWallNonMesh(obj)
    local parts = obj:IsA("BasePart") and {obj} or {}
    for _, desc in ipairs(obj:GetDescendants()) do
        if desc:IsA("BasePart") then table.insert(parts, desc) end
    end
    for _, part in ipairs(parts) do
        if math.abs(part.Transparency - 0.95) < 0.01 then
            part.Color        = Color3.fromRGB(0, 0, 0)
            part.Transparency = 0.5
        end
    end
end

local function optimizeIgnoreChild(obj)
    if obj.Name == "elevator" then return end

    if obj.Name == "BARRIER" then
        applyBarrier(obj)
    elseif obj.Name == "BOUNDARY" then
        applyWallNonMesh(obj)
    end

    for _, desc in ipairs(obj:GetDescendants()) do
        if desc:IsA("SurfaceAppearance") then desc:Destroy() end
    end

    for _, name in ipairs(ignoreRemoveAlways) do
        removeDescendantsByName(obj, name)
    end

    for _, names in pairs(ignoreRemoveByMap) do
        for _, name in ipairs(names) do
            removeDescendantsByName(obj, name)
        end
    end
end

local function setupIgnoreFolder(ignoreFolder)
    for _, child in ipairs(ignoreFolder:GetChildren()) do
        optimizeIgnoreChild(child)
    end
    ignoreFolder.ChildAdded:Connect(function(child)
        task.wait(1)
        optimizeIgnoreChild(child)
    end)
end

local ignoreFolder = workspace:FindFirstChild("IGNORE")
if ignoreFolder then
    setupIgnoreFolder(ignoreFolder)
end

workspace.ChildAdded:Connect(function(child)
    if child.Name == "IGNORE" then
        task.wait(2)
        setupIgnoreFolder(child)
    end
end)

local function optimizeGameMap(gameMap)
    for _, paths in pairs(mapConfigs) do
        for _, path in ipairs(paths) do
            local obj = getPath(workspace, path)
            if obj then obj:Destroy() end
        end
    end

    local wallsWooden = getPath(workspace, {"MAPS", "GAME MAP", "Other", "WallsWooden"})
    if wallsWooden then
        removeChildrenByName(wallsWooden, "WallWooden")
    end

    local assets = getPath(workspace, {"MAPS", "GAME MAP", "Other", "ASSETS"})
    removeChildrenExcept(assets, {"Security Doors", "Stage Floor Stairs [STANDALONE]"})

    optimizeMeshes(gameMap)
    nukeAllLights(gameMap)
end

local MAPS = workspace:FindFirstChild("MAPS")
if not MAPS then return end

local existingMap = MAPS:FindFirstChild("GAME MAP")
if existingMap then optimizeGameMap(existingMap) end

MAPS.ChildAdded:Connect(function(child)
    if child.Name == "GAME MAP" then
        task.wait(5)
        optimizeGameMap(child)
    end
end)
