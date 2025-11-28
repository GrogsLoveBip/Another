-- IA Portable Hitmarker + Som (Só ativa com dano real) - 2025
-- Funciona em Arsenal, Phantom Forces, Energy Assault, Rush Point, etc.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- ====================== GUI & CURSOR ======================
local IAPortable = Instance.new("ScreenGui")
IAPortable.Name = "IA Portable"
IAPortable.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
IAPortable.ResetOnSpawn = false
IAPortable.Parent = CoreGui

local Cursor = Instance.new("ImageLabel")
Cursor.Name = "CustomCursor"
Cursor.Parent = IAPortable
Cursor.BackgroundTransparency = 1
Cursor.Size = UDim2.new(0, 256, 0, 256)
Cursor.Position = UDim2.new(0, Mouse.X, 0, Mouse.Y)
Cursor.AnchorPoint = Vector2.new(0.5, 0.5)
Cursor.Image = "rbxassetid://3355815697"  -- Seu cursor personalizado
Cursor.ScaleType = Enum.ScaleType.Fit
Cursor.ImageColor3 = Color3.fromRGB(255, 255, 255)

local Hitmarker = Instance.new("ImageLabel")
Hitmarker.Name = "HitmarkerTemplate"
Hitmarker.Parent = IAPortable
Hitmarker.BackgroundTransparency = 1
Hitmarker.Size = UDim2.new(0, 50, 0, 50)
Hitmarker.Position = UDim2.new(0.5, 0, 0.5, 0)
Hitmarker.AnchorPoint = Vector2.new(0.5, 0.5)
Hitmarker.Image = "rbxassetid://890801299"  -- Hitmarker clássico
Hitmarker.Visible = false  -- Só usado como template

-- ====================== SOM E HITMARKER ======================
local HIT_SOUND_NORMAL   = "rbxassetid://1347140027"   -- Hit normal
local HIT_SOUND_HEADSHOT = "rbxassetid://6241637507"   -- Headshot (opcional)

local function playHitSound(isHeadshot: boolean)
    local soundId = isHeadshot and HIT_SOUND_HEADSHOT or HIT_SOUND_NORMAL
    task.spawn(function()
        local sound = Instance.new("Sound")
        sound.SoundId = soundId
        sound.Volume = 1.3
        sound.Parent = SoundService
        SoundService:PlayLocalSound(sound)
        task.delay(3, function() sound:Destroy() end)
    end)
end

local function showHitmarker()
    local clone = Hitmarker:Clone()
    clone.Visible = true
    clone.Position = UDim2.new(0, Mouse.X, 0, Mouse.Y)
    clone.Rotation = math.random(-45, 45)
    clone.ImageTransparency = 0
    clone.Parent = IAPortable
    
    -- Fade out suave
    task.spawn(function()
        for i = 0, 1, 0.1 do
            clone.ImageTransparency = i
            task.wait(0.01)
        end
        clone:Destroy()
    end)
    
    Debris:AddItem(clone, 0.3)
end

-- ====================== HOOK DO TAKE DAMAGE (O QUE IMPORTA) ======================
local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall

setreadonly(mt, false)

mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local args = {...}

    if method == "TakeDamage" and self:IsA("Humanoid") then
        local damageAmount = args[1]
        
        if typeof(damageAmount) == "number" and damageAmount > 0 then
            local character = self.Parent
            local targetPlayer = Players:GetPlayerFromCharacter(character)
            
            if targetPlayer and targetPlayer ~= LocalPlayer and targetPlayer.Team ~= LocalPlayer.Team then
                -- Detectar headshot (muitos jogos passam a parte como 2º argumento)
                local hitPart = args[2]
                local isHeadshot = false
                
                if typeof(hitPart) == "Instance" then
                    isHeadshot = hitPart.Name == "Head" or hitPart:IsDescendantOf(character:FindFirstChild("Head"))
                end
                
                -- Ativa SOMENTE quando causa dano real no inimigo
                playHitSound(isHeadshot)
                showHitmarker()
            end
        end
    end

    return oldNamecall(self, ...)
end)

setreadonly(mt, true)

-- ====================== CURSOR CUSTOMIZADO + COR POR TIME ======================
RunService.RenderStepped:Connect(function()
    UserInputService.MouseIconEnabled = false
    Cursor.Position = UDim2.new(0, Mouse.X, 0, Mouse.Y)
    
    local target = Mouse.Target
    if target then
        local character = target:FindFirstAncestorWhichIsA("Model")
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local player = humanoid and Players:GetPlayerFromCharacter(character)
        
        if player and player ~= LocalPlayer then
            Cursor.ImageColor3 = (player.Team == LocalPlayer.Team) and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
        else
            Cursor.ImageColor3 = Color3.fromRGB(255, 255, 255)
        end
    else
        Cursor.ImageColor3 = Color3.fromRGB(255, 255, 255)
    end
end)

print("IA Portable Hitmarker carregado com sucesso! (Dano real detectado)")
