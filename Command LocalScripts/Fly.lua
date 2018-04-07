local InputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Player = game.Players.LocalPlayer
local Cam = game.Workspace.CurrentCamera
local Char = Player.Character
if not Char or not Char.Parent then
    Char = Player.CharacterAdded:wait()
end
local Root = Char:WaitForChild("HumanoidRootPart")
local Humanoid = Char:WaitForChild("Humanoid")

local Resistance = 0.6 --Percentage of velocity lost per second
local Acceleration = 75 --sps^2
local Flying = true --X toggle disabled
local Coupled = true --Always try to go in the direction we're looking --ToDo
local LastTick = tick()

local Gyro = Root:FindFirstChild("FlyGyro")
local Vel = Root:FindFirstChild("FlyVel")

function FlyStart()
	Flying = true
	Humanoid.Sit = true
	LastTick = tick()
	
	if not Gyro then
		Gyro = Instance.new("BodyGyro")
		Gyro.Name = "FlyGyro"
		Gyro.maxTorque = Vector3.new(1000,1000,1000)
		Gyro.cframe = Root.CFrame
		Gyro.Parent = Root
	end
	if not Vel then
		Vel = Instance.new("BodyVelocity")
		Vel.Name = "FlyVel"
		Vel.velocity = Vector3.new(0,15,0) --Jump start
		Vel.maxForce = Vector3.new(9e9,9e9,9e9)
		Vel.Parent = Root
	end
end

function FlyEnd()
	Flying = false
	Humanoid.Sit = false
	
	if Gyro then Gyro:destroy() end
	if Vel then Vel:destroy() end
	Gyro = nil
	Vel = nil
end

local w = false
local s = false
local a = false
local d = false
local q = false
local e = false

InputService.InputBegan:connect(function(Key)
	if Key.KeyCode == Enum.KeyCode.W then
		w = true
	elseif Key.KeyCode == Enum.KeyCode.S then
		s = true
	elseif Key.KeyCode == Enum.KeyCode.A then
		a = true
	elseif Key.KeyCode == Enum.KeyCode.D then
		d = true
	elseif Key.KeyCode == Enum.KeyCode.Q then
		q = true
	elseif Key.KeyCode == Enum.KeyCode.E then
		e = true
	elseif Key.KeyCode == Enum.KeyCode.Z then
		Coupled = not Coupled
	elseif Key.KeyCode == Enum.KeyCode.X then
		--[[
		if Flying then
			FlyEnd()
		else
			FlyStart()
		end
		--]]
	end
end)

InputService.InputEnded:connect(function(Key)
	if Key.KeyCode == Enum.KeyCode.W then
		w = false
	elseif Key.KeyCode == Enum.KeyCode.S then
		s = false
	elseif Key.KeyCode == Enum.KeyCode.A then
		a = false
	elseif Key.KeyCode == Enum.KeyCode.D then
		d = false
	elseif Key.KeyCode == Enum.KeyCode.Q then
		q = false
	elseif Key.KeyCode == Enum.KeyCode.E then
		e = false
	end
end)

RunService.RenderStepped:connect(function()
	if Flying then
		Gyro.cframe = Cam.CoordinateFrame
	end
end)

FlyStart()

while wait() do
	if Flying then
		local TimeElapsed = tick() - LastTick
		
		local Forward = Cam.CFrame.lookVector
		local Right = Cam.CFrame.rightVector
		local Up = Cam.CFrame.upVector
		
		--Lock controls to the horizontal plane
		--local Forward = (Cam.CFrame.lookVector - Vector3.new(0,Cam.CFrame.lookVector.y,0)).unit
		--local Right = (Cam.CFrame.rightVector - Vector3.new(0,Cam.CFrame.lookVector.y,0)).unit
		--local Up = Vector3.new(0,1,0)
		
		if w and not s then
			Vel.velocity = Vel.velocity + (Forward * Acceleration * TimeElapsed)
		elseif s and not w then
			Vel.velocity = Vel.velocity - (Forward * Acceleration * TimeElapsed)
		end
		if d and not a then
			Vel.velocity = Vel.velocity + (Right * Acceleration * TimeElapsed)
		elseif a and not d then
			Vel.velocity = Vel.velocity - (Right * Acceleration * TimeElapsed)
		end
		if e and not q then
			Vel.velocity = Vel.velocity + (Up * Acceleration * TimeElapsed)
		elseif q and not e then
			Vel.velocity = Vel.velocity - (Up * Acceleration * TimeElapsed)
		end
		
		--Slow down automatically (Air resistance)
		Vel.velocity = Vel.velocity * (1 - (Resistance * TimeElapsed))
		if Vel.velocity.magnitude < 0.1 then
			Vel.velocity = Vector3.new(0,0,0)
		end
		LastTick = tick()
	end
end