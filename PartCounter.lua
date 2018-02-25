local Parts = 0
local Total = 0

function Check(Item)
	Total = Total + 1
	if Item:IsA("BasePart") then
		Parts = Parts + 1
	end
	
	local Stuff = Item:GetChildren()
	for i=1,#Stuff do
		Check(Stuff[i])
	end
end

Check(game.Workspace)
--Check(game.ServerStorage.Maps["Underground Facility"])
--Check(game.ReplicatedStorage)

print("Parts: "..Parts)
print("Objects: "..Total)