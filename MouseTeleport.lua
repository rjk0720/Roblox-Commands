local Player = game.Players.LocalPlayer
local Mouse = Player:GetMouse()

local Char = Player.Character
if not Char or not Char.Parent then
    Char = Player.CharacterAdded:wait()
end
local Root = Char:WaitForChild("HumanoidRootPart")

local Pos = Mouse.Hit.p + Vector3.new(0,3,0)
local StartCF = Root.CFrame
local NewCF = StartCF - StartCF.p + Pos
Root.CFrame = NewCF

script:destroy()