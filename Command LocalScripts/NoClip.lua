--Credit to Kohltastrophe for most of this

local Player = game.Players.LocalPlayer
local Char = Player.Character
while not Char do wait()
	Char = Player.Character
end
local Humanoid = Char:WaitForChild("Humanoid")
local Root = Char:FindFirstChild("HumanoidRootPart")
while not Root do wait()
	Root = Char:FindFirstChild("HumanoidRootPart")
end
local Mouse = Player:GetMouse()
local Cam = game.Workspace.CurrentCamera

local dir = {w = 0, s = 0, a = 0, d = 0}
local spd = 2
Mouse.KeyDown:connect(function(key)
	if key:lower() == "w" then
		dir.w = 1
	elseif key:lower() == "s" then
		dir.s = 1
	elseif key:lower() == "a" then
		dir.a = 1
	elseif key:lower() == "d" then
		dir.d = 1
	elseif key:lower() == "q" then
		spd = spd + 1
	elseif key:lower() == "e" then
		spd = spd - 1
	end
end)
Mouse.KeyUp:connect(function(key)
	if key:lower() == "w" then
		dir.w = 0
	elseif key:lower() == "s" then
		dir.s = 0
	elseif key:lower() == "a" then
		dir.a = 0
	elseif key:lower() == "d" then
		dir.d = 0
	end
end)
Root.Anchored = true
Humanoid.PlatformStand = true
Humanoid.Changed:connect(function()
	Humanoid.PlatformStand = true
end)
repeat
	wait(1/44)
	Root.CFrame = CFrame.new(Root.Position, Cam.CoordinateFrame.p) 
		* CFrame.Angles(0,math.rad(180),0)
		* CFrame.new((dir.d-dir.a)*spd,0,(dir.s-dir.w)*spd)
until nil