-- ============================================
-- ROBLOX RIVALS - PAINEL COMPLETO DELTA
-- Delta Executor (Mobile/PC)
-- ============================================

repeat wait() until game:IsLoaded() and game:GetService("Players").LocalPlayer

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local platform = isMobile and "MOBILE" or "PC"

-- ============================================
-- CONFIGURAÇÕES DO JOGO RIVALS
-- ============================================
local GameConfig = {
    RedTeam = {"Red", "Vermelho", "RedTeam", "Team1", "red", "vermelho"},
    BlueTeam = {"Blue", "Azul", "BlueTeam", "Team2", "blue", "azul"},
    Weapons = {"Gun", "Rifle", "Pistol", "Shotgun", "Sniper", "SMG", "AK47", "M4", "Arma", "Espingarda", "Metralhadora", "Fuzil", "Pistola", "Revolver", "Knife", "Faca", "Sword", "Espada", "Bomb", "Granada", "Grenade", "weapon", "arma", "gun", "rifle"},
    Ammo = {"Ammo", "Munição", "Municao", "Bullet", "Bala", "Clip", "Cartucho", "ammo", "munição"},
    Health = {"Health", "Vida", "Medkit", "Bandage", "Bandagem", "HP", "Heal", "Cura", "health", "vida", "medkit"},
    Armor = {"Armor", "Armadura", "Shield", "Escudo", "Vest", "Colete", "armor", "armadura", "shield"},
    Flags = {"Flag", "Bandeira", "Capture", "flag", "bandeira"},
    Bombs = {"Bomb", "Bomba", "C4", "Explosive", "bomb", "bomba", "explosive"},
    Enemies = {"Enemy", "Inimigo", "Bot", "NPC", "Soldier", "Soldado", "enemy", "inimigo", "bot", "npc"},
    Spawns = {"Spawn", "Base", "Respawn", "spawn", "base"},
    Objectives = {"Point", "Ponto", "Objective", "Objetivo", "Site", "Area", "point", "ponto", "objective"},
    PowerUps = {"PowerUp", "Power", "Buff", "Speed", "Damage", "Invisible", "Invisivel", "power", "buff"}
}

-- ============================================
-- VARIÁVEIS
-- ============================================
local ESP = { players = false, enemies = false, weapons = false, ammo = false, health = false, flags = false, bombs = false, armor = false, powerups = false }
local Aimbot = false
local AimbotFOV = 100
local AimbotTarget = "Head"
local AimbotSmooth = 3
local TriggerBot = false
local TriggerBotDelay = 0.1
local SilentAim = false
local SilentAimFOV = 100
local Fly, Noclip, InfiniteJump, GodMode = false, false, false, false
local WalkSpeed, JumpPower, FlySpeed = 70, 140, 80
local RapidFire = false
local RapidFireDelay = 0.05
local NoRecoil = false
local NoSpread = false
local InfiniteAmmo = false
local AutoReload = false
local ESPCache = {}
local lastESP, lastAimbot, lastTrigger = 0, 0, 0
local FlyBV = nil
local panelOpen = true
local currentTab = "aim"

-- ============================================
-- ANTI-BAN
-- ============================================
pcall(function()
    local old = hookmetamethod(game, "__namecall", function(self, ...)
        local m = getnamecallmethod()
        local a = {...}
        if (m == "FireServer" or m == "InvokeServer") and a[1] then
            local rn = typeof(a[1]) == "string" and a[1] or ""
            local blocked = {"Ban", "Kick", "Report", "Detect", "AntiCheat", "Flag", "AC_", "Cheat"}
            for _, p in ipairs(blocked) do if rn:find(p) then return nil end end
        end
        if m == "Kick" then return nil end
        return old(self, ...)
    end)
end)
pcall(function() setfpscap(144) end)

-- ============================================
-- FUNÇÕES AUXILIARES
-- ============================================
local function GetChar() return player.Character end
local function GetRoot() local c = GetChar() return c and c:FindFirstChild("HumanoidRootPart") end
local function GetHum() local c = GetChar() return c and c:FindFirstChild("Humanoid") end
local function GetCamPos() return camera.CFrame.Position end
local function IsInTable(str, list)
    local lower = str:lower()
    for _, p in ipairs(list) do if lower:find(p:lower()) then return true end end
    return false
end
local function GetCurrentWeapon()
    local char = GetChar()
    if not char then return nil end
    return char:FindFirstChildOfClass("Tool")
end

-- ============================================
-- ESP
-- ============================================
local function ClearESP()
    for _, h in pairs(ESPCache) do if h and h.Parent then h:Destroy() end end
    table.clear(ESPCache)
end

local function UpdateESP()
    if not (ESP.players or ESP.enemies or ESP.weapons or ESP.ammo or ESP.health or ESP.flags or ESP.bombs or ESP.armor or ESP.powerups) then
        ClearESP()
        return
    end
    
    local toRemove = {}
    for obj, hl in pairs(ESPCache) do
        if not obj or not obj.Parent then
            table.insert(toRemove, obj)
            if hl and hl.Parent then hl:Destroy() end
        end
    end
    for _, obj in ipairs(toRemove) do ESPCache[obj] = nil end
    
    local function highlight(obj, color, trans)
        if obj and not ESPCache[obj] and obj:IsA("BasePart") then
            local hl = Instance.new("Highlight")
            hl.FillColor = color
            hl.FillTransparency = trans or 0.5
            hl.OutlineTransparency = 0.7
            hl.Parent = obj
            ESPCache[obj] = hl
        end
    end
    
    if ESP.players then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= player and plr.Character then
                local teamColor = Color3.fromRGB(0, 255, 0)
                if plr.Team and player.Team then
                    if plr.Team ~= player.Team then
                        teamColor = Color3.fromRGB(255, 50, 50)
                    else
                        teamColor = Color3.fromRGB(0, 200, 255)
                    end
                end
                local head = plr.Character:FindFirstChild("Head")
                if head then highlight(head, teamColor, 0.4) end
                local root = plr.Character:FindFirstChild("HumanoidRootPart")
                if root then highlight(root, teamColor, 0.4) end
            end
        end
    end
    
    if ESP.enemies then
        for _, obj in ipairs(workspace:GetDescendants()) do
            if IsInTable(obj.Name, GameConfig.Enemies) then
                local hum = obj:FindFirstChild("Humanoid")
                if hum and hum.Health > 0 then
                    local head = obj:FindFirstChild("Head")
                    if head then highlight(head, Color3.fromRGB(255, 50, 50), 0.3) end
                    local root = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Torso")
                    if root then highlight(root, Color3.fromRGB(255, 50, 50), 0.3) end
                end
            end
        end
    end
    
    if ESP.weapons then
        for _, obj in ipairs(workspace:GetDescendants()) do
            if IsInTable(obj.Name, GameConfig.Weapons) and obj:IsA("BasePart") then
                highlight(obj, Color3.fromRGB(255, 150, 0), 0.5)
            end
        end
    end
    
    if ESP.ammo then
        for _, obj in ipairs(workspace:GetDescendants()) do
            if IsInTable(obj.Name, GameConfig.Ammo) and obj:IsA("BasePart") then
                highlight(obj, Color3.fromRGB(255, 255, 100), 0.5)
            end
        end
    end
    
    if ESP.health then
        for _, obj in ipairs(workspace:GetDescendants()) do
            if IsInTable(obj.Name, GameConfig.Health) and obj:IsA("BasePart") then
                highlight(obj, Color3.fromRGB(255, 100, 100), 0.5)
            end
        end
    end
    
    if ESP.armor then
        for _, obj in ipairs(workspace:GetDescendants()) do
            if IsInTable(obj.Name, GameConfig.Armor) and obj:IsA("BasePart") then
                highlight(obj, Color3.fromRGB(100, 100, 255), 0.5)
            end
        end
    end
    
    if ESP.flags then
        for _, obj in ipairs(workspace:GetDescendants()) do
            if IsInTable(obj.Name, GameConfig.Flags) and (obj:IsA("BasePart") or obj:IsA("Model")) then
                local part = obj:FindFirstChildWhichIsA("BasePart") or (obj:IsA("BasePart") and obj)
                if part then highlight(part, Color3.fromRGB(255, 255, 0), 0.3) end
            end
        end
    end
    
    if ESP.bombs then
        for _, obj in ipairs(workspace:GetDescendants()) do
            if IsInTable(obj.Name, GameConfig.Bombs) and (obj:IsA("BasePart") or obj:IsA("Model")) then
                local part = obj:FindFirstChildWhichIsA("BasePart") or (obj:IsA("BasePart") and obj)
                if part then highlight(part, Color3.fromRGB(255, 0, 0), 0.3) end
            end
        end
    end
    
    if ESP.powerups then
        for _, obj in ipairs(workspace:GetDescendants()) do
            if IsInTable(obj.Name, GameConfig.PowerUps) and obj:IsA("BasePart") then
                highlight(obj, Color3.fromRGB(255, 0, 255), 0.4)
            end
        end
    end
end

-- ============================================
-- AIMBOT
-- ============================================
local function GetClosestTarget(fov)
    local camPos = GetCamPos()
    local closest = nil
    local closestDist = fov or AimbotFOV
    local screenCenter = Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y/2)
    
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character then
            if not (plr.Team and player.Team and plr.Team == player.Team) then
                local head = plr.Character:FindFirstChild("Head")
                local chest = plr.Character:FindFirstChild("UpperTorso") or plr.Character:FindFirstChild("HumanoidRootPart")
                local hum = plr.Character:FindFirstChild("Humanoid")
                if hum and hum.Health > 0 then
                    local targetPart = nil
                    if AimbotTarget == "Head" and head then targetPart = head
                    elseif AimbotTarget == "Chest" and chest then targetPart = chest
                    else targetPart = head or chest end
                    if targetPart then
                        local screenPos, onScreen = camera:WorldToViewportPoint(targetPart.Position)
                        if onScreen then
                            local dist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                            if dist < closestDist then
                                closestDist = dist
                                closest = targetPart
                            end
                        end
                    end
                end
            end
        end
    end
    
    if not closest then
        for _, obj in ipairs(workspace:GetDescendants()) do
            if IsInTable(obj.Name, GameConfig.Enemies) then
                local hum = obj:FindFirstChild("Humanoid")
                if hum and hum.Health > 0 then
                    local head = obj:FindFirstChild("Head")
                    local chest = obj:FindFirstChild("UpperTorso") or obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Torso")
                    local targetPart = (AimbotTarget == "Head" and head) or chest or head
                    if targetPart then
                        local screenPos, onScreen = camera:WorldToViewportPoint(targetPart.Position)
                        if onScreen then
                            local dist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                            if dist < closestDist then
                                closestDist = dist
                                closest = targetPart
                            end
                        end
                    end
                end
            end
        end
    end
    
    return closest
end

local function UpdateAimbot()
    if not Aimbot and not SilentAim then return end
    local target = GetClosestTarget(Aimbot and AimbotFOV or SilentAimFOV)
    if not target then return end
    
    if Aimbot and not SilentAim then
        local camPos = GetCamPos()
        local targetPos = target.Position
        local lookDir = (targetPos - camPos).Unit
        local currentLook = camera.CFrame.LookVector
        local smoothFactor = 1 / AimbotSmooth
        local smoothedDir = currentLook:Lerp(lookDir, smoothFactor)
        camera.CFrame = CFrame.new(camPos, camPos + smoothedDir)
    end
end

-- ============================================
-- TRIGGER BOT
-- ============================================
local function UpdateTriggerBot()
    if not TriggerBot then return end
    local now = tick()
    if now - lastTrigger < TriggerBotDelay then return end
    lastTrigger = now
    
    local target = GetClosestTarget(50)
    if target then
        local tool = GetCurrentWeapon()
        if tool then tool:Activate() end
        pcall(function()
            if VirtualInputManager then
                VirtualInputManager:SendMouseButtonEvent(camera.ViewportSize.X/2, camera.ViewportSize.Y/2, 0, true, game, 0)
                wait(0.01)
                VirtualInputManager:SendMouseButtonEvent(camera.ViewportSize.X/2, camera.ViewportSize.Y/2, 0, false, game, 0)
            end
        end)
    end
end

-- ============================================
-- WEAPON MODS
-- ============================================
local function ApplyWeaponMods()
    if RapidFire then
        pcall(function()
            local tool = GetCurrentWeapon()
            if tool then
                tool:Activate()
                local settings = tool:FindFirstChild("Settings") or tool:FindFirstChild("Config")
                if settings then
                    local fireRate = settings:FindFirstChild("FireRate") or settings:FindFirstChild("Cooldown")
                    if fireRate and fireRate:IsA("NumberValue") then fireRate.Value = RapidFireDelay end
                end
            end
        end)
    end
    if NoRecoil then
        pcall(function()
            local tool = GetCurrentWeapon()
            if tool then
                local recoil = tool:FindFirstChild("Recoil") or tool:FindFirstChild("Kickback") or tool:FindFirstChild("Recuo")
                if recoil then
                    if recoil:IsA("NumberValue") then recoil.Value = 0 end
                    if recoil:IsA("Vector3Value") then recoil.Value = Vector3.zero end
                end
            end
        end)
    end
    if NoSpread then
        pcall(function()
            local tool = GetCurrentWeapon()
            if tool then
                local spread = tool:FindFirstChild("Spread") or tool:FindFirstChild("Accuracy") or tool:FindFirstChild("Dispersao")
                if spread and spread:IsA("NumberValue") then spread.Value = 0 end
            end
        end)
    end
    if InfiniteAmmo then
        pcall(function()
            local tool = GetCurrentWeapon()
            if tool then
                local ammo = tool:FindFirstChild("Ammo") or tool:FindFirstChild("Munição") or tool:FindFirstChild("Ammunition")
                if ammo and ammo:IsA("NumberValue") then ammo.Value = 999 end
                local mag = tool:FindFirstChild("Mag") or tool:FindFirstChild("Clip") or tool:FindFirstChild("Magazine")
                if mag and mag:IsA("NumberValue") then mag.Value = 999 end
            end
        end)
    end
    if AutoReload then
        pcall(function()
            local tool = GetCurrentWeapon()
            if tool then
                local mag = tool:FindFirstChild("Mag") or tool:FindFirstChild("Clip") or tool:FindFirstChild("Magazine")
                if mag and mag:IsA("NumberValue") and mag.Value <= 2 then mag.Value = 30 end
            end
        end)
    end
end

-- ============================================
-- FLY / NOCLIP / GOD MODE
-- ============================================
local function UpdateFly()
    local root = GetRoot()
    if not root then return end
    if Fly then
        if not FlyBV then
            FlyBV = Instance.new("BodyVelocity")
            FlyBV.MaxForce = Vector3.new(1e5, 1e5, 1e5)
            FlyBV.Velocity = Vector3.zero
            FlyBV.Parent = root
        end
        local move = Vector3.zero
        if not isMobile then
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then move -= camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then move -= camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.yAxis end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then move -= Vector3.yAxis end
        else
            local mv = UserInputService:GetMovementVector()
            if mv.Magnitude > 0 then move = camera.CFrame.LookVector * mv.Z + camera.CFrame.RightVector * mv.X end
            if UserInputService:IsKeyDown(Enum.KeyCode.ButtonR2) then move += Vector3.yAxis end
            if UserInputService:IsKeyDown(Enum.KeyCode.ButtonL2) then move -= Vector3.yAxis end
        end
        FlyBV.Velocity = move.Magnitude > 0 and move.Unit * FlySpeed or Vector3.new(0, FlyBV.Velocity.Y * 0.1, 0)
    elseif FlyBV then
        FlyBV:Destroy()
        FlyBV = nil
    end
end

local function UpdateNoclip()
    local char = GetChar()
    if Noclip and char then
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end
end

local function UpdateGodMode()
    if not GodMode then return end
    local hum = GetHum()
    if hum then
        pcall(function() hum.MaxHealth = math.huge; hum.Health = math.huge end)
    end
end

-- ============================================
-- UI
-- ============================================
local sg = Instance.new("ScreenGui")
sg.Name = "Rivals_Panel"
sg.ResetOnSpawn = false
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
if isMobile then sg.IgnoreGuiInset = true end
pcall(function() syn.protect_gui(sg) end)
sg.Parent = player:WaitForChild("PlayerGui")

local btnH = isMobile and 48 or 36
local fontSize = isMobile and 14 or 12
local pad = 5
local sidebarW = 120

local main = Instance.new("Frame", sg)
main.Size = isMobile and UDim2.new(0.95,0,0.82,0) or UDim2.new(0,400,0,520)
main.Position = isMobile and UDim2.new(0.025,0,0.1,0) or UDim2.new(0.5,-200,0.5,-260)
main.BackgroundColor3 = Color3.fromRGB(8,8,13)
main.BorderSizePixel = 0
main.ClipsDescendants = true
Instance.new("UICorner", main).CornerRadius = UDim.new(0,8)

local titleBar = Instance.new("Frame", main)
titleBar.Size = UDim2.new(1,0,0,30)
titleBar.BackgroundColor3 = Color3.fromRGB(20,20,25)
titleBar.BorderSizePixel = 0

local titleLabel = Instance.new("TextLabel", titleBar)
titleLabel.Size = UDim2.new(0.7,0,1,0)
titleLabel.Position = UDim2.new(0.05,0,0,0)
titleLabel.Text = "RIVALS PANEL"
titleLabel.TextColor3 = Color3.fromRGB(1,0.3,0.3)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextScaled = true
titleLabel.BackgroundTransparency = 1
titleLabel.TextXAlignment = Enum.TextXAlignment.Left

local closeBtn = Instance.new("TextButton", titleBar)
closeBtn.Size = UDim2.new(0,28,0,28)
closeBtn.Position = UDim2.new(1,-33,0,1)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.new(1,1,1)
closeBtn.BackgroundColor3 = Color3.fromRGB(200,40,40)
closeBtn.BorderSizePixel = 0
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0,4)

local sidebar = Instance.new("Frame", main)
sidebar.Size = UDim2.new(0,sidebarW,1,-30)
sidebar.Position = UDim2.new(0,0,0,30)
sidebar
