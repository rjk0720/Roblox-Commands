local InputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Player = game.Players.LocalPlayer
local Cam = game.Workspace.CurrentCamera
local Mouse = Player:GetMouse()
local Char = Player.Character
if not Char or not Char.Parent then
    Char = Player.CharacterAdded:wait()
end
local Root = Char:WaitForChild("HumanoidRootPart")
local Humanoid = Char:WaitForChild("Humanoid")

local Resistance = 0.6 --Percentage of velocity lost per second
local Acceleration = 75 --sps^2
local Flying = true --X toggle disabled
local Coupled = false --Always try to go in the direction we're looking
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
local Brake = false

InputService.InputBegan:connect(function(Key,gameProcessedEvent)
	if not gameProcessedEvent then --Not chatting or something
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
			Brake = true
		elseif Key.KeyCode == Enum.KeyCode.Space then
			Brake = true
		end
	end
end)

InputService.InputEnded:connect(function(Key,gameProcessedEvent)
	if not gameProcessedEvent then --Not chatting or something
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
		elseif Key.KeyCode == Enum.KeyCode.X then
			Brake = false
		elseif Key.KeyCode == Enum.KeyCode.Space then
			Brake = false
		end
	end
end)

RunService.RenderStepped:connect(function()
	if Flying then
		if Coupled then
			--Face where we're looking/going
			Gyro.cframe = Cam.CoordinateFrame
		else
			--Face the mouse I guess
			Gyro.cframe = CFrame.new(Root.Position,Mouse.Hit.p)
		end
	end
end)

FlyStart()

while wait() do
	if Flying then
		local TimeElapsed = tick() - LastTick
		
		--Lock controls to the horizontal plane
		--local Forward = (Cam.CFrame.lookVector - Vector3.new(0,Cam.CFrame.lookVector.y,0)).unit
		--local Right = (Cam.CFrame.rightVector - Vector3.new(0,Cam.CFrame.lookVector.y,0)).unit
		--local Up = Vector3.new(0,1,0)
		
		local Forward = Cam.CFrame.lookVector
		local Right = Cam.CFrame.rightVector
		local Up = Cam.CFrame.upVector
		
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
		
		if Coupled then
			--Fly like a plane, go where we're pointing
			Vel.velocity = Root.CFrame.lookVector * Vel.velocity.magnitude
		else
			--More of a hovering style
			
		end
		
		--Slow down automatically (Air resistance) or with brake
		if Brake then
			Vel.velocity = Vel.velocity * (1 - (Resistance * TimeElapsed * 10))
		else
			Vel.velocity = Vel.velocity * (1 - (Resistance * TimeElapsed))
		end
		if Vel.velocity.magnitude < 0.1 then
			Vel.velocity = Vector3.new(0,0,0)
		end
		LastTick = tick()
	end
end