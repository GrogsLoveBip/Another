--// FIXED VERSION WITH DEBUGGER + UNIVERSAL HOOKS + CLIENT HIT DETECTION
--// Paste this, it will PRINT exactly what remotes are firing so you can see why it's not triggering
--// Hitmarkers will now show on EVERY shot + real hits

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

--// GUI
local IAPortable = Instance.new("ScreenGui")
IAPortable.Name = "IA Portable"
IAPortable.Parent = game:GetService("CoreGui")
IAPortable.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local Cursor = Instance.new("ImageLabel")
Cursor.Name = "Cursor"
Cursor.Parent = IAPortable
Cursor.AnchorPoint = Vector2.new(0.5, 0.5)
Cursor.BackgroundTransparency = 1
Cursor.Size = UDim2.new(0, 256, 0, 256)
Cursor.Image = "rbxassetid://3355815697"
Cursor.ScaleType = Enum.ScaleType.Fit

local Hitmarker = Instance.new("ImageLabel")
Hitmarker.Name = "HitmarkerTemplate"
Hitmarker.AnchorPoint = Vector2.new(0.5, 0.5)
Hitmarker.BackgroundTransparency = 1
Hitmarker.Size = UDim2.new(0, 45, 0, 45)
Hitmarker.Image = "rbxassetid://890801299"
Hitmarker.Visible = false
Hitmarker.Parent = IAPortable

--// HITMARKER FUNCTION (FIXED SOUND)
local hitCooldown = 0
local function spawnHitmarker()
    if tick() - hitCooldown < 0.1 then return end
    hitCooldown = tick()
    
    -- FIXED SOUND (direct parent to workspace + immediate play)
    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://1347140027"
    sound.Volume = 0.8
    sound.Parent = Workspace
    sound:Play()
    sound.Ended:Connect(function() sound:Destroy() end)
    
    -- HITMARKER VISUAL
    local clone = Hitmarker:Clone()
    clone.Visible = true
    clone.Position = UDim2.new(0, Mouse.X, 0, Mouse.Y)
    clone.Rotation = math.random(-90, 90)
    clone.Parent = IAPortable
    
    -- SMOOTH FADE + SCALE
    clone:TweenSizeAndPosition(
        UDim2.new(0, 70, 0, 70),
        UDim2.new(0, Mouse.X, 0, Mouse.Y),
        "Out", "Quad", 0.2, true
    )
    clone.ImageTransparency = 0
    clone:TweenService = game:GetService("TweenService"):Create(clone, TweenInfo.new(0.3), {ImageTransparency = 1})
    clone.TweenService:Play()
    Debris:AddItem(clone, 0.4)
    
    print("🟢 HITMARKER + SOUND PLAYED!") -- DEBUG
end

--// CURSOR UPDATE (unchanged)
RunService.RenderStepped:Connect(function()
    UserInputService.MouseIconEnabled = false
    Cursor.Position = UDim2.new(0, Mouse.X, 0, Mouse.Y)

    local target = Mouse.Target
    if target then
        local char = target:FindFirstAncestorOfClass("Model")
        local hum = char:FindFirstChildOfClass("Humanoid")
        local plr = Players:GetPlayerFromCharacter(char)
        if plr and plr ~= LocalPlayer then
            Cursor.ImageColor3 = (plr.Team and plr.Team == LocalPlayer.Team) and Color3.new(0,1,0) or Color3.new(1,0,0)
        else
            Cursor.ImageColor3 = Color3.new(1,1,1)
        end
    else
        Cursor.ImageColor3 = Color3.new(1,1,1)
    end
end)

--// UNIVERSAL METATABLE HOOK (IMPROVED + DEBUG PRINTS)
local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
setreadonly(mt, false)

mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    
    if method == "FireServer" or method == "InvokeServer" then
        local remoteName = tostring(self):lower()
        print("📡 REMOTE FIRED:", tostring(self), "| Args:", #args) -- DEBUG: See ALL remotes
        
        -- EXPANDED KEYWORDS (more matches)
        if remoteName:find("damage") or remoteName:find("hit") or remoteName:find("bullet") or 
           remoteName:find("fire") or remoteName:find("shoot") or remoteName:find("shot") or
           remoteName:find("replicate") or remoteName:find("kill") or remoteName:find("hurt") or
           remoteName:find("ray") or remoteName:find("projectile") then
            
            print("🔥 DAMAGE REMOTE DETECTED:", tostring(self)) -- DEBUG
            
            -- Check args for enemy player/humanoid/part
            for i, v in pairs(args) do
                print("Arg", i, typeof(v), tostring(v)) -- DEBUG ARGS
                
                if typeof(v) == "Instance" then
                    if v:IsA("BasePart") or v:IsA("Model") then
                        local char = v.Parent or v
                        local hum = char:FindFirstChildOfClass("Humanoid")
                        local plr = Players:GetPlayerFromCharacter(char)
                        if plr and plr ~= LocalPlayer then
                            local isEnemy = not plr.Team or plr.Team ~= LocalPlayer.Team
                            if isEnemy then
                                spawnHitmarker()
                                print("✅ ENEMY HIT DETECTED!")
                                return oldNamecall(self, ...)
                            end
                        end
                    elseif v:IsA("Humanoid") then
                        local plr = Players:GetPlayerFromCharacter(v.Parent)
                        if plr and plr ~= LocalPlayer and (not plr.Team or plr.Team ~= LocalPlayer.Team) then
                            spawnHitmarker()
                            print("✅ HUMANOID HIT!")
                        end
                    end
                end
            end
        end
    end
    
    return oldNamecall(self, ...)
end)
setreadonly(mt, true)

--// EXTRA: TOOL ACTIVATION HOOK (for local firing)
local oldActivate = nil
oldActivate = hookmetamethod(game, "__namecall", function(self, ...)
    if getnamecallmethod() == "Activate" and self:IsA("Tool") then
        spawn(function()
            wait(0.05) -- tiny delay for server confirm
            spawnHitmarker() -- show on every shot as fallback
            print("🔫 TOOL ACTIVATED (shot fired)")
        end)
    end
    return oldActivate(self, ...)
end)

--// EXTRA: MOUSE CLICK HITMARKER (your original radius style as fallback)
local clickCooldown = 0
UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 and tick() - clickCooldown > 0.15 then
        clickCooldown = tick()
        local ray = workspace:Raycast(Camera.CFrame.Position, (Mouse.Hit.Position - Camera.CFrame.Position).Unit * 5000)
        if ray and ray.Instance then
            local char = ray.Instance:FindFirstAncestorOfClass("Model")
            if char then
                local plr = Players:GetPlayerFromCharacter(char)
                if plr and plr ~= LocalPlayer and (not plr.Team or plr.Team ~= LocalPlayer.Team) then
                    spawnHitmarker()
                end
            end
        end
    end
end)

print("🚀 FIXED HITMARKER LOADED! Watch console for DEBUG prints (F9) - remotes will show there!")
print("📡 Fire your gun and check console - if no 'DAMAGE REMOTE DETECTED' then game uses different system")

--// TEST BUTTON (press T to test hitmarker + sound instantly)
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.T then
        spawnHitmarker()
    end
end)
