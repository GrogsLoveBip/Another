-- A
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local IAPortable = Instance.new("ScreenGui")
IAPortable.Name = "IA Portable"
IAPortable.Parent = game:GetService("CoreGui")
IAPortable.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local Cursor = Instance.new("ImageLabel")
Cursor.Name = "Cursor"
Cursor.Parent = IAPortable
Cursor.AnchorPoint = Vector2.new(0.5, 0.5)
Cursor.BackgroundTransparency = 1
Cursor.Size = UDim2.new(0, 256,256)
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

local function playHitSound()
    local s = Instance.new("Sound")
    s.SoundId = "rbxassetid://1347140027"
    s.Volume = 1
    s.Parent = IAPortable
    s:Play()
    Debris:AddItem(s, 2)
end

local function spawnHitmarker()
    playHitSound()
    local mouseX, mouseY = UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y
    local clone = Hitmarker:Clone()
    clone.Visible = true
    clone.Position = UDim2.new(0, mouseX, 0, mouseY)
    clone.Rotation = math.random(-45, 45)
    clone.Parent = IAPortable
    clone:TweenSizeAndPosition(
        UDim2.new(0, 80, 0, 80),
        UDim2.new(0, mouseX, 0, mouseY),
        "Out", "Quad", 0.15, true
    )
    Debris:AddItem(clone, 0.3)
end

RunService.RenderStepped:Connect(function()
    pcall(function()
        UserInputService.MouseIconEnabled = false
        local mouseLoc = UserInputService:GetMouseLocation()
        Cursor.Position = UDim2.new(0, mouseLoc.X, 0, mouseLoc.Y)

        local target = Mouse.Target
        if target then
            local char = target:FindFirstAncestorWhichIsA("Model")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local plr = hum and Players:GetPlayerFromCharacter(char)
            if plr then
                Cursor.ImageColor3 = (plr.TeamColor == LocalPlayer.TeamColor) and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,0,0)
            else
                Cursor.ImageColor3 = Color3.new(1,1,1)
            end
        else
            Cursor.ImageColor3 = Color3.new(1,1,1)
        end
    end)
end)

local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
setreadonly(mt, false)

mt.__namecall = newcclosure(function(self, ...)
    local ok, res = pcall(function()
        local method = getnamecallmethod()
        local args = {...}
        if (method == "FireServer" or method == "InvokeServer") then
            local remoteName = tostring(self):lower()
            if remoteName:find("damage") or remoteName:find("hit") or remoteName:find("bullet") or remoteName:find("fire") or remoteName:find("shoot") or remoteName:find("hitreg") then
                for _, v in pairs(args) do
                    if typeof(v) == "Instance" then
                        local plr = Players:GetPlayerFromCharacter(v.Parent)
                        if plr and plr ~= LocalPlayer and plr.TeamColor ~= LocalPlayer.TeamColor then
                            spawnHitmarker()
                            break
                        end
                        if v:IsA("Humanoid") then
                            local hitPlr = Players:GetPlayerFromCharacter(v.Parent)
                            if hitPlr and hitPlr ~= LocalPlayer and hitPlr.TeamColor ~= LocalPlayer.TeamColor then
                                spawnHitmarker()
                                break
                            end
                        end
                    elseif typeof(v) == "string" then
                        local nameLower = v:lower()
                        for _, p in pairs(Players:GetPlayers()) do
                            if p.Name:lower():find(nameLower) or (p.DisplayName and p.DisplayName:lower():find(nameLower)) then
                                if p ~= LocalPlayer and p.TeamColor ~= LocalPlayer.TeamColor then
                                    spawnHitmarker()
                                    break
                                end
                            end
                        end
                    end
                end
            end
        end

        if method == "InvokeServer" and tostring(self):lower():find("shoot") then
            spawnHitmarker()
        end
    end)
    return oldNamecall(self, ...)
end)

setreadonly(mt, true)

spawn(function()
    for _, v in pairs(getgc(true)) do
        if typeof(v) == "function" then
            local success, cons = pcall(function() return getconstants(v) end)
            if success and (table.find(cons, "TakeDamage") or table.find(cons, "Health")) then
                local ok, upvalues = pcall(function() return getupvalues(v) end)
                if ok then
                    for _, upv in pairs(upvalues) do
                        if typeof(upv) == "Instance" and upv:IsA("Humanoid") then
                            local plr = Players:GetPlayerFromCharacter(upv.Parent)
                            if plr and plr ~= LocalPlayer and plr.TeamColor ~= LocalPlayer.TeamColor then
                                spawnHitmarker()
                            end
                        end
                    end
                end
            end
        end
    end
end)
