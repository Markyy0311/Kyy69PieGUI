local LIB_URL = "https://raw.githubusercontent.com/Kyypie69/Library.UI/refs/heads/main/KyypieUI.lua"
local ok, Library = pcall(function()
    local source = game:HttpGet(LIB_URL)
    if not source or source == "" then
        error("Empty response from server")
    end
    return loadstring(source)()
end)

if not ok then
    warn("Failed to load UI library: " .. tostring(Library))
    local success, result = pcall(function()
        local httpService = game:GetService("HttpService")
        local response = httpService:GetAsync(LIB_URL)
        return loadstring(response)()
    end)
    if success then
        Library = result
        ok = true
    else
        error("Failed to load UI library with fallback: " .. tostring(result))
    end
end

if not ok or not Library then
    error("Critical: Could not load UI library. Please check your internet connection.")
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local Stats = game:GetService("Stats")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer
local userId = player.UserId
local thumbType = Enum.ThumbnailType.HeadShot
local thumbSize = Enum.ThumbnailSize.Size420x420
local content, isReady = Players:GetUserThumbnailAsync(userId, thumbType, thumbSize)

-- Performance Settings
_G.PerformanceSettings = {
    fpsCap = 120,
    pingStabilizer = false,
    connectionEnhancer = false,
    antiLag = false,
    stableMemory = false
}

-- Network Stats Tracking
local networkStats = {
    currentPing = 0,
    avgPing = 0,
    pingHistory = {},
    lastOptimization = 0,
    isThrottled = false,
    baseCooldowns = {},
    originalFpsCap = 120,
    memoryCleanupInterval = 30,
    lastMemoryCleanup = 0
}

-- Performance Connections Storage
local performanceConnections = {}

-- Remote Events Cache
local remoteEvents = {}
local remoteFunctions = {}

-- Auto-detect Remote Events
function scanRemoteEvents()
    local events = {}
    local functions = {}
    
    -- Scan ReplicatedStorage
    for _, obj in pairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") then
            events[obj.Name] = obj
        elseif obj:IsA("RemoteFunction") then
            functions[obj.Name] = obj
        end
    end
    
    -- Scan common locations
    local commonPaths = {
        ReplicatedStorage:FindFirstChild("Events"),
        ReplicatedStorage:FindFirstChild("Remotes"),
        ReplicatedStorage:FindFirstChild("RemoteEvents"),
        game:GetService("Workspace"):FindFirstChild("Events")
    }
    
    for _, path in pairs(commonPaths) do
        if path then
            for _, obj in pairs(path:GetDescendants()) do
                if obj:IsA("RemoteEvent") then
                    events[obj.Name] = obj
                elseif obj:IsA("RemoteFunction") then
                    functions[obj.Name] = obj
                end
            end
        end
    end
    
    return events, functions
end

-- Cache remotes
remoteEvents, remoteFunctions = scanRemoteEvents()

game:GetService("StarterGui"):SetCore("SendNotification",{  
    Title = "KYYY HUB",     
    Text = "Welcome!",
    Icon = "",
    Duration = 3,
})

wait(3)

game:GetService("StarterGui"):SetCore("SendNotification",{  
    Title = "Hello ✨",     
    Text = player.Name,
    Icon = content,
    Duration = 2,
})

local Window = Library:CreateWindow({
    Title = "KYYY - Roll The Dice | Spin A Baddie",
    SubTitle = "Made | by Markyy",
    Size = UDim2.fromOffset(480, 340),
    TabWidth = 130,
    Theme = "Veinyx",
    Acrylic = false,
})

-- TABS
local HomeTab       = Window:AddTab({ Title = "Main",          Icon = "home" })
local AutoTab       = Window:AddTab({ Title = "Auto Farm",     Icon = "zap" })
local RollingTab    = Window:AddTab({ Title = "Rolling",       Icon = "dice" })
local MerchantTab   = Window:AddTab({ Title = "Merchant",      Icon = "shopping" })
local QuestsTab     = Window:AddTab({ Title = "Quests",        Icon = "check" })
local MiscTab       = Window:AddTab({ Title = "Misc",          Icon = "menu" })
local DebugTab      = Window:AddTab({ Title = "Debug",         Icon = "bug" })

-- ==================== PERFORMANCE FUNCTIONS ====================

function updatePingStats()
    local success, ping = pcall(function()
        return Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
    end)
    
    if success and ping then
        -- Ensure ping is a number
        ping = tonumber(ping) or 0
        networkStats.currentPing = ping
        table.insert(networkStats.pingHistory, ping)
        
        if #networkStats.pingHistory > 10 then
            table.remove(networkStats.pingHistory, 1)
        end
        
        local total = 0
        for _, p in ipairs(networkStats.pingHistory) do
            total = total + tonumber(p) or 0
        end
        networkStats.avgPing = total / #networkStats.pingHistory
        
        return ping
    end
    return 0
end

function setFpsCap(cap)
    -- Ensure cap is a number
    cap = tonumber(cap) or 120
    pcall(function()
        if setfpscap then
            setfpscap(cap)
        end
    end)
end

function cleanupMemory()
    pcall(function()
        -- Clean up nil parented objects
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") and obj.Parent == nil then
                obj:Destroy()
            end
        end
        
        -- Clean up unused sounds
        for _, sound in pairs(workspace:GetDescendants()) do
            if sound:IsA("Sound") and not sound.Playing then
                sound:Destroy()
            end
        end
        
        -- Force garbage collection
        for i = 1, 3 do
            collectgarbage("collect")
            wait(0.1)
        end
    end)
end

function stabilizeConnection()
    if not _G.PerformanceSettings.connectionEnhancer then return end
    
    pcall(function()
        settings().Network.IncomingReplicationLag = 0
        settings().Network.OutgoingReplicationLag = 0
        
        if networkStats.avgPing > 200 then
            settings().Network.IncomingReplicationLag = math.min(networkStats.avgPing / 1000, 0.5)
        end
    end)
end

function applyPingStabilizer()
    if not _G.PerformanceSettings.pingStabilizer then return end
    
    local currentPing = updatePingStats()
    
    if currentPing > 300 and not networkStats.isThrottled then
        networkStats.isThrottled = true
        setFpsCap(60)
        
        pcall(function()
            for _, remote in pairs(ReplicatedStorage:GetDescendants()) do
                if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
                    if not networkStats.baseCooldowns[remote] then
                        networkStats.baseCooldowns[remote] = remote:GetAttribute("Cooldown") or 0
                    end
                    remote:SetAttribute("Cooldown", networkStats.baseCooldowns[remote] + 0.1)
                end
            end
        end)
        
    elseif currentPing < 150 and networkStats.isThrottled then
        networkStats.isThrottled = false
        setFpsCap(_G.PerformanceSettings.fpsCap)
        
        pcall(function()
            for remote, baseCooldown in pairs(networkStats.baseCooldowns) do
                if remote and remote.Parent then
                    remote:SetAttribute("Cooldown", baseCooldown)
                end
            end
        end)
    end
end

function applyAntiLag()
    if not _G.PerformanceSettings.antiLag then return end
    
    pcall(function()
        -- Optimize other players
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= Players.LocalPlayer and plr.Character then
                for _, part in pairs(plr.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CastShadow = false
                    elseif part:IsA("ParticleEmitter") or part:IsA("Trail") then
                        part.Enabled = false
                    end
                end
            end
        end
        
        -- Reduce particle rates
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("ParticleEmitter") then
                obj.Rate = math.max(obj.Rate * 0.5, 1)
            elseif obj:IsA("Trail") then
                obj.Lifetime = obj.Lifetime * 0.5
            end
        end
    end)
end

function startPerformanceLoop()
    -- Stop existing connections
    for _, conn in pairs(performanceConnections) do
        if conn then conn:Disconnect() end
    end
    performanceConnections = {}
    
    -- Main performance loop
    table.insert(performanceConnections, RunService.Heartbeat:Connect(function()
        local currentTime = tick()
        
        -- Stable Memory
        if _G.PerformanceSettings.stableMemory then
            if currentTime - networkStats.lastMemoryCleanup >= networkStats.memoryCleanupInterval then
                cleanupMemory()
                networkStats.lastMemoryCleanup = currentTime
            end
        end
        
        -- Ping Stabilizer
        if _G.PerformanceSettings.pingStabilizer then
            if currentTime - networkStats.lastOptimization >= 2 then
                applyPingStabilizer()
                networkStats.lastOptimization = currentTime
            end
        end
        
        -- Connection Enhancer
        if _G.PerformanceSettings.connectionEnhancer then
            stabilizeConnection()
        end
        
        -- Anti Lag
        if _G.PerformanceSettings.antiLag then
            if currentTime % 5 < 0.1 then
                applyAntiLag()
            end
        end
    end))
    
    -- Player added handler for anti-lag
    if _G.PerformanceSettings.antiLag then
        table.insert(performanceConnections, Players.PlayerAdded:Connect(function(plr)
            plr.CharacterAdded:Connect(function(char)
                if _G.PerformanceSettings.antiLag then
                    wait(1)
                    applyAntiLag()
                end
            end)
        end))
    end
end

-- ==================== HOME TAB ====================
local mainSection = HomeTab:AddSection("Main Features")

mainSection:AddButton({
    Title = "Restock Shop",
    Description = "Restock all shop items",
    Callback = function()
        if remoteFunctions.restock then
            remoteFunctions.restock:InvokeServer()
        else
            ReplicatedStorage:WaitForChild("Events"):WaitForChild("restock"):InvokeServer()
        end
    end
})

mainSection:AddButton({
    Title = "Claim All Rewards",
    Description = "Claim all available rewards",
    Callback = function()
        if remoteFunctions.claimAll then
            remoteFunctions.claimAll:InvokeServer()
        else
            ReplicatedStorage:WaitForChild("Events"):WaitForChild("claimAll"):InvokeServer()
        end
    end
})

_G.AutoPlaceBaddies = false
mainSection:AddToggle("AutoPlaceBaddiesToggle", {
    Title = "Auto Place Best Baddies",
    Description = "Automatically place best units",
    Default = false,
    Callback = function(Value)
        _G.AutoPlaceBaddies = Value
        task.spawn(function()
            while _G.AutoPlaceBaddies do
                pcall(function()
                    if remoteFunctions.PlaceBestBaddies then
                        remoteFunctions.PlaceBestBaddies:InvokeServer()
                    else
                        ReplicatedStorage:WaitForChild("Events"):WaitForChild("PlaceBestBaddies"):InvokeServer()
                    end
                end)
                wait(5)
            end
        end)
    end
})

-- ==================== AUTO FARM TAB (COMBINED) ====================
-- DICE SECTION
local diceSection = AutoTab:AddSection("Auto Buy Dice (MAX)")

_G.SelectedDice = {}

local diceOptions = {
    "Kraken Dice",
    "Seraphic Dice",
    "Galactic Dice", 
    "Eldritch Dice",
    "Emperor Dice",
    "Annihilation Dice",
    "Disaster Dice",
    "Limbo Dice",
    "Chronos Dice",
    "Yinyang Dice",
    "Impossible Dice"
}

local diceConfig = {
    ["Kraken Dice"] = { name = "Kraken Dice", amount = 4, type = "dice" },
    ["Seraphic Dice"] = { name = "Seraphic Dice", amount = 4, type = "dice" },
    ["Galactic Dice"] = { name = "Galactic Dice", amount = 4, type = "dice" },
    ["Eldritch Dice"] = { name = "Eldritch Dice", amount = 4, type = "dice" },
    ["Emperor Dice"] = { name = "Emperor Dice", amount = 4, type = "dice" },
    ["Annihilation Dice"] = { name = "Annihilation Dice", amount = 4, type = "dice" },
    ["Disaster Dice"] = { name = "Disaster Dice", amount = 4, type = "dice" },
    ["Limbo Dice"] = { name = "Limbo Dice", amount = 4, type = "dice" },
    ["Chronos Dice"] = { name = "Chronos Dice", amount = 4, type = "dice" },
    ["Yinyang Dice"] = { name = "Yinyang Dice", amount = 4, type = "dice" },
    ["Impossible Dice"] = { name = "Impossible Dice", amount = 4, type = "dice" }
}

diceSection:AddDropdown("SelectedDiceDropdown", {
    Title = "Select Dice to Auto Buy",
    Description = "Select multiple dice (MAX: 12)",
    Values = diceOptions,
    Multi = true,
    Default = {},
    Callback = function(Value)
        _G.SelectedDice = Value
    end
})

_G.AutoBuyDice = false
diceSection:AddToggle("AutoBuyDiceToggle", {
    Title = "Auto Buy Selected Dice",
    Description = "Automatically buy selected dice (12)",
    Default = false,
    Callback = function(Value)
        _G.AutoBuyDice = Value
        task.spawn(function()
            while _G.AutoBuyDice do
                for diceName, isSelected in pairs(_G.SelectedDice) do
                    if isSelected and diceConfig[diceName] then
                        local config = diceConfig[diceName]
                        local args
                        
                        if config.special == "update" then
                            args = { config.name }
                            if remoteEvents.updateRollingDice then
                                remoteEvents.updateRollingDice:FireServer(unpack(args))
                            else
                                ReplicatedStorage:WaitForChild("Events"):WaitForChild("updateRollingDice"):FireServer(unpack(args))
                            end
                        else
                            args = { config.name, config.amount, config.type }
                            if remoteFunctions.buy then
                                remoteFunctions.buy:InvokeServer(unpack(args))
                            else
                                ReplicatedStorage:WaitForChild("Events"):WaitForChild("buy"):InvokeServer(unpack(args))
                            end
                        end
                        wait(0.5)
                    end
                end
                wait(2)
            end
        end)
    end
})

-- POTIONS SECTION
local potionsSection = AutoTab:AddSection("Auto Buy Potions (12)")

_G.SelectedPotions = {}

local potionOptions = {
    "Luck Potion 3",
    "No Consume Dice Potion 1",
    "Mutation Chance Potion 1",
    "Money Potion 3"
}

local potionConfig = {
    ["Luck Potion 3"] = { name = "Luck Potion 3", amount = 2, type = "potion", action = "buy" },
    ["No Consume Dice Potion 1"] = { name = "No Consume Dice Potion 1", amount = 2, type = "potion", action = "buy" },
    ["Mutation Chance Potion 1"] = { name = "Mutation Chance Potion 1", amount = 2, type = "potion", action = "buy" },
    ["Money Potion 3"] = { name = "Money Potion 3", amount = 2, type = "potion", action = "buy" }
}

potionsSection:AddDropdown("SelectedPotionsDropdown", {
    Title = "Select Potions",
    Description = "Select multiple potions (MAX: 12)",
    Values = potionOptions,
    Multi = true,
    Default = {},
    Callback = function(Value)
        _G.SelectedPotions = Value
    end
})

_G.AutoBuyPotions = false
potionsSection:AddToggle("AutoBuyPotionsToggle", {
    Title = "Auto Buy Selected",
    Description = "Automatically buy selected potions (MAX)",
    Default = false,
    Callback = function(Value)
        _G.AutoBuyPotions = Value
        task.spawn(function()
            while _G.AutoBuyPotions do
                for potionName, isSelected in pairs(_G.SelectedPotions) do
                    if isSelected and potionConfig[potionName] then
                        local config = potionConfig[potionName]
                        local args
                        
                        if config.action == "unequip" then
                            args = { config.name, config.amount }
                            if remoteFunctions.unequip then
                                remoteFunctions.unequip:InvokeServer(unpack(args))
                            else
                                ReplicatedStorage:WaitForChild("Events"):WaitForChild("unequip"):InvokeServer(unpack(args))
                            end
                        else
                            args = { config.name, config.amount, config.type }
                            if remoteFunctions.buy then
                                remoteFunctions.buy:InvokeServer(unpack(args))
                            else
                                ReplicatedStorage:WaitForChild("Events"):WaitForChild("buy"):InvokeServer(unpack(args))
                            end
                        end
                        wait(0.5)
                    end
                end
                wait(2)
            end
        end)
    end
})

-- REBIRTH SECTION
local rebirthSection = AutoTab:AddSection("Auto Rebirth")

_G.AutoRebirth = false
rebirthSection:AddToggle("AutoRebirthToggle", {
    Title = "Auto Rebirth",
    Description = "Automatically rebirth",
    Default = false,
    Callback = function(Value)
        _G.AutoRebirth = Value
        task.spawn(function()
            while _G.AutoRebirth do
                pcall(function()
                    if remoteFunctions.rebirth then
                        remoteFunctions.rebirth:InvokeServer()
                    else
                        ReplicatedStorage:WaitForChild("Events"):WaitForChild("rebirth"):InvokeServer()
                    end
                end)
                wait(3)
            end
        end)
    end
})

rebirthSection:AddButton({
    Title = "Rebirth Once",
    Description = "Perform rebirth manually",
    Callback = function()
        if remoteFunctions.rebirth then
            remoteFunctions.rebirth:InvokeServer()
        else
            ReplicatedStorage:WaitForChild("Events"):WaitForChild("rebirth"):InvokeServer()
        end
    end
})

-- EGG SECTION
local eggSection = AutoTab:AddSection("Auto Buy Eggs")

_G.SelectedEgg = "AngelEgg"

eggSection:AddDropdown("SelectedEggDropdown", {
    Title = "Select Egg Type",
    Description = "Choose which egg to buy",
    Values = {"AngelEgg", "MechEgg"},
    Multi = false,
    Default = "AngelEgg",
    Callback = function(Value)
        _G.SelectedEgg = Value
    end
})

_G.AutoBuyEgg = false
eggSection:AddToggle("AutoBuyEggToggle", {
    Title = "Auto Buy Selected Egg",
    Description = "Automatically buy selected egg",
    Default = false,
    Callback = function(Value)
        _G.AutoBuyEgg = Value
        task.spawn(function()
            while _G.AutoBuyEgg do
                pcall(function()
                    local args = { _G.SelectedEgg, 1 }
                    if remoteFunctions.RegularPet then
                        remoteFunctions.RegularPet:InvokeServer(unpack(args))
                    else
                        ReplicatedStorage:WaitForChild("Events"):WaitForChild("RegularPet"):InvokeServer(unpack(args))
                    end
                end)
                wait(1)
            end
        end)
    end
})

eggSection:AddButton({
    Title = "Buy Egg Once",
    Description = "Buy selected egg manually",
    Callback = function()
        local args = { _G.SelectedEgg, 1 }
        if remoteFunctions.RegularPet then
            remoteFunctions.RegularPet:InvokeServer(unpack(args))
        else
            ReplicatedStorage:WaitForChild("Events"):WaitForChild("RegularPet"):InvokeServer(unpack(args))
        end
    end
})

-- ==================== ROLLING TAB ====================
local rollingSection = RollingTab:AddSection("Rolling Features")

rollingSection:AddButton({
    Title = "Roll Dice",
    Description = "Roll your current dice",
    Callback = function()
        pcall(function()
            player:WaitForChild("PlayerGui"):WaitForChild("Main"):WaitForChild("Dice"):WaitForChild("RollState"):InvokeServer()
        end)
    end
})

rollingSection:AddButton({
    Title = "Spin Wheel",
    Description = "Request spin",
    Callback = function()
        if remoteFunctions.spinrequest then
            remoteFunctions.spinrequest:InvokeServer()
        else
            ReplicatedStorage:WaitForChild("Events"):WaitForChild("spinrequest"):InvokeServer()
        end
    end
})

_G.AutoRoll = false
rollingSection:AddToggle("AutoRollToggle", {
    Title = "Auto Roll",
    Description = "Automatically roll dice",
    Default = false,
    Callback = function(Value)
        _G.AutoRoll = Value
        task.spawn(function()
            while _G.AutoRoll do
                pcall(function()
                    player:WaitForChild("PlayerGui"):WaitForChild("Main"):WaitForChild("Dice"):WaitForChild("RollState"):InvokeServer()
                end)
                wait(1.5)
            end
        end)
    end
})

_G.AutoSpin = false
rollingSection:AddToggle("AutoSpinToggle", {
    Title = "Auto Spin",
    Description = "Automatically request spins",
    Default = false,
    Callback = function(Value)
        _G.AutoSpin = Value
        task.spawn(function()
            while _G.AutoSpin do
                pcall(function()
                    if remoteFunctions.spinrequest then
                        remoteFunctions.spinrequest:InvokeServer()
                    else
                        ReplicatedStorage:WaitForChild("Events"):WaitForChild("spinrequest"):InvokeServer()
                    end
                end)
                wait(5)
            end
        end)
    end
})

-- ==================== MERCHANT TAB ====================
local merchantSection = MerchantTab:AddSection("Merchant Auto Buy")

_G.AutoBuyMerchant = false
merchantSection:AddToggle("AutoBuyMerchantToggle", {
    Title = "Auto Buy All Merchant Items",
    Description = "Automatically buy all merchant slots",
    Default = false,
    Callback = function(Value)
        _G.AutoBuyMerchant = Value
        task.spawn(function()
            while _G.AutoBuyMerchant do
                for i = 1, 6 do
                    local args = { i }
                    if remoteFunctions.MerchantBuy then
                        remoteFunctions.MerchantBuy:InvokeServer(unpack(args))
                    else
                        ReplicatedStorage:WaitForChild("Events"):WaitForChild("MerchantBuy"):InvokeServer(unpack(args))
                    end
                    wait(0.5)
                end
                wait(3)
            end
        end)
    end
})

merchantSection:AddButton({
    Title = "Buy All Merchant Items",
    Description = "Buy all merchant slots once",
    Callback = function()
        for i = 1, 6 do
            local args = { i }
            if remoteFunctions.MerchantBuy then
                remoteFunctions.MerchantBuy:InvokeServer(unpack(args))
            else
                ReplicatedStorage:WaitForChild("Events"):WaitForChild("MerchantBuy"):InvokeServer(unpack(args))
            end
            wait(0.5)
        end
    end
})

-- ==================== QUESTS TAB ====================
local questsSection = QuestsTab:AddSection("Quests Auto Claim")

_G.AutoClaimQuests = false
questsSection:AddToggle("AutoClaimQuestsToggle", {
    Title = "Auto Claim All Quest Rewards",
    Description = "Automatically claim all quest reward slots",
    Default = false,
    Callback = function(Value)
        _G.AutoClaimQuests = Value
        task.spawn(function()
            while _G.AutoClaimQuests do
                for i = 1, 6 do
                    local args = { "ClaimReward", i }
                    if remoteFunctions.QuestRemote then
                        remoteFunctions.QuestRemote:InvokeServer(unpack(args))
                    else
                        ReplicatedStorage:WaitForChild("Events"):WaitForChild("QuestRemote"):InvokeServer(unpack(args))
                    end
                    wait(0.5)
                end
                wait(5)
            end
        end)
    end
})

questsSection:AddButton({
    Title = "Claim All Quest Rewards",
    Description = "Claim all 6 quest reward slots once",
    Callback = function()
        for i = 1, 6 do
            local args = { "ClaimReward", i }
            if remoteFunctions.QuestRemote then
                remoteFunctions.QuestRemote:InvokeServer(unpack(args))
            else
                ReplicatedStorage:WaitForChild("Events"):WaitForChild("QuestRemote"):InvokeServer(unpack(args))
            end
            wait(0.5)
        end
    end
})

-- ==================== MISC TAB ====================
local autoSection = MiscTab:AddSection("Auto Features")

_G.AutoClaim = false
autoSection:AddToggle("AutoClaimToggle", {
    Title = "Auto Claim All",
    Description = "Automatically claim all rewards",
    Default = false,
    Callback = function(Value)
        _G.AutoClaim = Value
        task.spawn(function()
            while _G.AutoClaim do
                pcall(function()
                    if remoteFunctions.claimAll then
                        remoteFunctions.claimAll:InvokeServer()
                    else
                        ReplicatedStorage:WaitForChild("Events"):WaitForChild("claimAll"):InvokeServer()
                    end
                end)
                wait(10)
            end
        end)
    end
})

-- PERFORMANCE SECTION
local performanceSection = MiscTab:AddSection("Performance Optimization")

-- FPS Cap Input (FIXED - using Input instead of Slider to avoid string/number comparison)
performanceSection:AddInput("FpsCapInput", {
    Title = "FPS Cap",
    Description = "Set maximum FPS (30-240, 0 = unlimited)",
    Default = "120",
    Placeholder = "Enter FPS cap...",
    Numeric = true,
    Finished = true,
    Callback = function(Value)
        -- Ensure Value is treated as a number
        local numValue = tonumber(Value)
        if numValue then
            if numValue == 0 then
                _G.PerformanceSettings.fpsCap = 9999
                setFpsCap(9999)
            else
                -- Clamp between 30 and 240
                numValue = math.clamp(numValue, 30, 240)
                _G.PerformanceSettings.fpsCap = numValue
                setFpsCap(numValue)
            end
            
            game:GetService("StarterGui"):SetCore("SendNotification",{
                Title = "FPS Cap",
                Text = "FPS cap set to: " .. tostring(numValue == 0 and "Unlimited" or numValue),
                Duration = 3
            })
        end
    end
})

-- Stable Memory Toggle (FIXED - improved cleanup)
performanceSection:AddToggle("StableMemoryToggle", {
    Title = "Stable Memory",
    Description = "Auto cleanup memory every 30 seconds",
    Default = false,
    Callback = function(Value)
        _G.PerformanceSettings.stableMemory = Value
        if Value then
            networkStats.lastMemoryCleanup = tick()
            cleanupMemory() -- Run immediately on enable
            game:GetService("StarterGui"):SetCore("SendNotification",{
                Title = "Performance",
                Text = "Stable Memory enabled! Initial cleanup complete.",
                Duration = 3
            })
        end
        startPerformanceLoop()
    end
})

-- Ping Stabilizer Toggle
performanceSection:AddToggle("PingStabilizerToggle", {
    Title = "Ping Stabilizer",
    Description = "Auto-adjust settings based on ping",
    Default = false,
    Callback = function(Value)
        _G.PerformanceSettings.pingStabilizer = Value
        if Value then
            networkStats.lastOptimization = tick()
            updatePingStats() -- Initial ping check
            game:GetService("StarterGui"):SetCore("SendNotification",{
                Title = "Performance",
                Text = "Ping Stabilizer enabled! Current: " .. math.floor(networkStats.currentPing) .. "ms",
                Duration = 3
            })
        else
            -- Reset throttling if disabled
            if networkStats.isThrottled then
                networkStats.isThrottled = false
                setFpsCap(_G.PerformanceSettings.fpsCap)
            end
        end
        startPerformanceLoop()
    end
})

-- Connection Enhancer Toggle
performanceSection:AddToggle("ConnectionEnhancerToggle", {
    Title = "Connection Enhancer",
    Description = "Optimize network replication settings",
    Default = false,
    Callback = function(Value)
        _G.PerformanceSettings.connectionEnhancer = Value
        if Value then
            stabilizeConnection()
            game:GetService("StarterGui"):SetCore("SendNotification",{
                Title = "Performance",
                Text = "Connection Enhancer enabled!",
                Duration = 3
            })
        else
            -- Reset network settings
            pcall(function()
                settings().Network.IncomingReplicationLag = 0
                settings().Network.OutgoingReplicationLag = 0
            end)
        end
        startPerformanceLoop()
    end
})

-- Anti-Lag Toggle (FIXED - better implementation)
performanceSection:AddToggle("AntiLagToggle", {
    Title = "Anti-Lag",
    Description = "Reduce visual effects and shadows",
    Default = false,
    Callback = function(Value)
        _G.PerformanceSettings.antiLag = Value
        if Value then
            -- Apply immediately
            applyAntiLag()
            
            -- Optimize lighting
            pcall(function()
                Lighting.GlobalShadows = false
                Lighting.FogEnd = 9e9
                for _, effect in pairs(Lighting:GetChildren()) do
                    if effect:IsA("BlurEffect") or effect:IsA("SunRaysEffect") or effect:IsA("BloomEffect") then
                        effect.Enabled = false
                    end
                end
            end)
            
            game:GetService("StarterGui"):SetCore("SendNotification",{
                Title = "Performance",
                Text = "Anti-Lag enabled! Effects reduced.",
                Duration = 3
            })
        else
            -- Restore lighting
            pcall(function()
                Lighting.GlobalShadows = true
                for _, effect in pairs(Lighting:GetChildren()) do
                    if effect:IsA("BlurEffect") or effect:IsA("SunRaysEffect") or effect:IsA("BloomEffect") then
                        effect.Enabled = true
                    end
                end
            end)
            
            -- Restore player effects
            pcall(function()
                for _, plr in pairs(Players:GetPlayers()) do
                    if plr ~= Players.LocalPlayer and plr.Character then
                        for _, part in pairs(plr.Character:GetDescendants()) do
                            if part:IsA("BasePart") then
                                part.CastShadow = true
                            elseif part:IsA("ParticleEmitter") or part:IsA("Trail") then
                                part.Enabled = true
                            end
                        end
                    end
                end
            end)
        end
        startPerformanceLoop()
    end
})

-- Network Stats Display
performanceSection:AddButton({
    Title = "Show Network Stats",
    Description = "Display current ping and performance metrics",
    Callback = function()
        local ping = updatePingStats()
        local memory = collectgarbage("count")
        
        game:GetService("StarterGui"):SetCore("SendNotification",{
            Title = "Network Stats",
            Text = string.format("Ping: %dms | Avg: %dms | Memory: %.1f MB", 
                math.floor(networkStats.currentPing), 
                math.floor(networkStats.avgPing),
                memory / 1024),
            Duration = 5
        })
    end
})

-- FPS BOOST / LOW GRAPHICS SECTION
local fpsSection = MiscTab:AddSection("FPS Boost & Performance")

_G.FPSBoostEnabled = false
fpsSection:AddToggle("FPSBoostToggle", {
    Title = "FPS Boost / Low Graphics",
    Description = "Disable effects for better performance",
    Default = false,
    Callback = function(Value)
        _G.FPSBoostEnabled = Value
        if Value then
            Lighting.GlobalShadows = false
            Lighting.FogEnd = 9e9
            
            for _, v in pairs(Lighting:GetChildren()) do
                if v:IsA("BlurEffect") or v:IsA("SunRaysEffect") or v:IsA("ColorCorrectionEffect") or v:IsA("BloomEffect") then
                    v.Enabled = false
                end
            end
            
            settings().Rendering.QualityLevel = 1
            
            for _, v in pairs(Workspace:GetDescendants()) do
                if v:IsA("BasePart") then
                    v.Material = Enum.Material.Plastic
                    v.CastShadow = false
                elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
                    v.Enabled = false
                elseif v:IsA("Decal") or v:IsA("Texture") then
                    v:Destroy()
                end
            end
            
            game:GetService("StarterGui"):SetCore("SendNotification",{
                Title = "FPS Boost",
                Text = "Low graphics mode enabled!",
                Duration = 3
            })
        else
            Lighting.GlobalShadows = true
            settings().Rendering.QualityLevel = 7
            
            game:GetService("StarterGui"):SetCore("SendNotification",{
                Title = "FPS Boost",
                Text = "Graphics restored!",
                Duration = 3
            })
        end
    end
})

-- ANTI-AFK SECTION
local antiAfkSection = MiscTab:AddSection("Anti-AFK")

_G.AntiAfkEnabled = false
antiAfkSection:AddToggle("AntiAfkToggle", {
    Title = "Anti-AFK",
    Description = "Prevent getting kicked for being idle",
    Default = false,
    Callback = function(Value)
        _G.AntiAfkEnabled = Value
        if Value then
            task.spawn(function()
                while _G.AntiAfkEnabled do
                    local vu = game:GetService("VirtualUser")
                    vu:Button2Down(Vector2.new(0,0), Workspace.CurrentCamera.CFrame)
                    wait(1)
                    vu:Button2Up(Vector2.new(0,0), Workspace.CurrentCamera.CFrame)
                    wait(60)
                end
            end)
            
            local bb = game:service("VirtualUser")
            game:service("Players").LocalPlayer.Idled:Connect(function()
                if _G.AntiAfkEnabled then
                    bb:CaptureController()
                    bb:ClickButton2(Vector2.new())
                end
            end)
            
            game:GetService("StarterGui"):SetCore("SendNotification",{
                Title = "Anti-AFK",
                Text = "Anti-AFK enabled!",
                Duration = 3
            })
        end
    end
})

-- ==================== DEBUG TAB ====================
local debugSection = DebugTab:AddSection("Remote Event Scanner")

debugSection:AddButton({
    Title = "Scan Remote Events",
    Description = "Find all RemoteEvents and RemoteFunctions",
    Callback = function()
        remoteEvents, remoteFunctions = scanRemoteEvents()
        
        local eventCount = 0
        local functionCount = 0
        
        for _ in pairs(remoteEvents) do eventCount = eventCount + 1 end
        for _ in pairs(remoteFunctions) do functionCount = functionCount + 1 end
        
        game:GetService("StarterGui"):SetCore("SendNotification",{
            Title = "Remote Scanner",
            Text = "Found " .. eventCount .. " RemoteEvents, " .. functionCount .. " RemoteFunctions",
            Duration = 5
        })
        
        -- Print to console
        print("=== REMOTE EVENTS ===")
        for name, obj in pairs(remoteEvents) do
            print("RemoteEvent: " .. name .. " | Parent: " .. obj.Parent.Name)
        end
        
        print("=== REMOTE FUNCTIONS ===")
        for name, obj in pairs(remoteFunctions) do
            print("RemoteFunction: " .. name .. " | Parent: " .. obj.Parent.Name)
        end
    end
})

debugSection:AddButton({
    Title = "Test Buy Remote",
    Description = "Test the buy remote with minimal args",
    Callback = function()
        pcall(function()
            if remoteFunctions.buy then
                remoteFunctions.buy:InvokeServer("Luck Potion 3", 1, "potion")
                print("Buy remote test fired successfully")
            else
                print("Buy remote not found")
            end
        end)
    end
})

debugSection:AddButton({
    Title = "Test Rebirth Remote",
    Description = "Test rebirth function",
    Callback = function()
        pcall(function()
            if remoteFunctions.rebirth then
                remoteFunctions.rebirth:InvokeServer()
                print("Rebirth remote test fired successfully")
            else
                print("Rebirth remote not found")
            end
        end)
    end
})

debugSection:AddButton({
    Title = "Print Game Structure",
    Description = "Print ReplicatedStorage structure to console",
    Callback = function()
        print("=== REPLICATED STORAGE STRUCTURE ===")
        for _, obj in pairs(ReplicatedStorage:GetChildren()) do
            print(obj.Name .. " (" .. obj.ClassName .. ")")
            if obj:FindFirstChild("Events") or obj:FindFirstChild("Remotes") then
                for _, child in pairs(obj:GetChildren()) do
                    print("  -> " .. child.Name .. " (" .. child.ClassName .. ")")
                end
            end
        end
    end
})

-- Initialize performance loop
startPerformanceLoop()

-- Auto-scan on load
task.spawn(function()
    wait(2)
    remoteEvents, remoteFunctions = scanRemoteEvents()
end)
