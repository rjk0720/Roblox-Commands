--Miniaturizes a model (or it could make it bigger I guess)

local Scale = 0.1

local Part = {}

-----

function Log(Obj)
	if Obj:IsA("BasePart") then
		Part[#Part + 1] = Obj
	elseif Obj.ClassName == "Model" then
		local Stuff = Obj:GetChildren()
		for i=1,#Stuff do
			Log(Stuff[i])
		end
	end
end

function Mini(Obj)
	Log(Obj)
	local Model = Instance.new("Model",game.Workspace)
	Model.Name = "Mini"..Obj.Name
	
	local Origin = Vector3.new(0,0,0)
	for i=1,#Part do
		Origin = Origin + Part[i].Position
	end
	Origin = Origin / #Part + Vector3.new(0,8,0)
	
	for i=1,#Part do
		local New = Part[i]:Clone()
		New.Parent = Model
		local Offset = (Part[i].Position - Origin) * Scale
		New.Size = Vector3.new(
			Part[i].Size.x * Scale,
			Part[i].Size.y * Scale,
			Part[i].Size.z * Scale
		)
		New.CFrame = (Part[i].CFrame - Part[i].CFrame.p) + Origin + Offset
	end
end

-----

Mini(game.Workspace.Model)