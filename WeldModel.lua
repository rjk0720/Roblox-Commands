--Welds all the top-level parts in a model to the primary part (not recursive)

function MakeWeld(P1,P2)
    local Weld = Instance.new("ManualWeld", P1)
	Weld.Name = "Weld_"..P2.Name
    Weld.Part0 = P1
    Weld.Part1 = P2
    Weld.C0 = P1.CFrame:inverse() * P2.CFrame
	print(tostring(Weld.C0))
    return Weld
end

function WeldModel(Model)
	for _,Part in pairs(Model:GetChildren()) do
		if Part:IsA("BasePart") and Part ~= Model.PrimaryPart then
			MakeWeld(Model.PrimaryPart,Part)
		end
	end
end

WeldModel(game.Selection:Get()[1])