local IAPortable = Instance.new("ScreenGui")
local Cursor = Instance.new("ImageLabel")
local Hitmarker = Instance.new("ImageLabel")

IAPortable.Name = "IA Portable"
IAPortable.Parent = game:GetService("CoreGui")
IAPortable.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
IAPortable.ResetOnSpawn = false

Cursor.Name = "Cursor"
Cursor.Parent = IAPortable
Cursor.AnchorPoint = Vector2.new(0.5, 0.5)
Cursor.BackgroundTransparency = 1
Cursor.Size = UDim2.new(0, 256, 0, 256)
Cursor.Image = "rbxassetid://3355815697"
Cursor.ScaleType = Enum.ScaleType.Fit

Hitmarker.Name = "Hitmarker"
Hitmarker.AnchorPoint = Vector2.new(0.5, 0.5)
Hitmarker.BackgroundTransparency = 1
Hitmarker.Position = UDim2.new(0.5, 0, 0.5, 0)
Hitmarker.Size = UDim2.new(0, 45, 0, 45)
Hitmarker.Image = "rbxassetid://890801299"
Hitmarker.Parent = IAPortable -- só pra clonar depois
Hitmarker.Visible = false

-- Serviços
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- Configs
local hitCooldown = 0.12
local lastHitTime = 0

-- Som de hit
local function playHitSound()
    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://1347140027"
    sound.Volume = 1
    sound.Parent = SoundService
    SoundService:PlayLocalSound(sound)
    sound.Ended:Connect(function() sound:Destroy() end)
end

-- Hitmarker visual
local function showHitmarker()
    if tick() - lastHitTime < hitCooldown then return end
    lastHitTime = tick()

    local clone = Hitmarker:Clone()
    clone.Visible = true
    clone.Position = UDim2.new(0, Mouse.X, 0, Mouse.Y)
    clone.Rotation = math.random(-45, 45)
    clone.Parent = IAPortable
    Debris:AddItem(clone, 0.15)
    playHitSound()
end

-- === HOOK REAL DE HIT (mais confiável que raycast) ===
local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
setreadonly(mt, false)

mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local args = {...}

    if method == "TakeDamage" and self:IsA("Humanoid") then
        local character = self.Parent
        local player = Players:GetPlayerFromCharacter(character)

        -- Só ativa se for inimigo e não for você mesmo
        if player and player ~= LocalPlayer and player.TeamColor ~= LocalPlayer.TeamColor then
            -- Verifica se você está mirando nele (opcional, mas evita hits falsos)
            local head = character:FindFirstChild("Head")
            if head then
                local screenPos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(head.Position)
                if onScreen then
                    local distance = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(Mouse.X, Mouse.Y)).Magnitude
                    if distance <= 180 then -- ajuste o valor (tamanho da "hitbox" virtual)
                        spawn(showHitmarker) -- roda no próximo frame pra não travar
                    end
                end
            end
        end
    end

    return oldNamecall(self, ...)
end)

setreadonly(mt, true)

-- Cursor personalizado + cor por time
RunService.RenderStepped:Connect(function()
    UserInputService.MouseIconEnabled = false
    Cursor.Position = UDim2.new(0, Mouse.X, 0, Mouse.Y)

    local target = Mouse.Target
    if target then
        local char = target.Parent
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            local plr = Players:GetPlayerFromCharacter(char)
            if plr then
                Cursor.ImageColor3 = (plr.TeamColor == LocalPlayer.TeamColor) and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,0,0)
            else
                Cursor.ImageColor3 = Color3.fromRGB(255,255,255)
            end
        else
            Cursor.ImageColor3 = Color3.fromRGB(255,255,255)
        end
    else
        Cursor.ImageColor3 = Color3.fromRGB(255,255,255)
    end
end)
