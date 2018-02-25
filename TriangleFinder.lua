--Finds how many triangles there are with perimeter p
--I forget what I made this for but it looks important

local Max = 20
local Triangles = {}

function Valid(x,y,z)
	if x + y > z and y + z > x and z + x > y then
		return true
	else
		return false
	end
end

function IsEqual(t1,t2)
	--Sort lists
	local function Sort(list)
		for i=1,#list-1 do
			if list[i] > list[#list] then
				local temp = list[i]
				list[i] = list[#list]
				list[#list] = temp
			end
		end
		return list
	end
	t1 = Sort(t1)
	t2 = Sort(t2)
	--Compare
	local Equal = true
	for i=1,#t1 do
		if t1[i] ~= t2[i] then
			Equal = false
			break
		end
	end
	return Equal
end

for p=1,Max do
	local Matches = {}
	for x=1,p do
		for y=1,p do
			for z=1,p do
				local Total = x + y + z
				if Total == p and Valid(x,y,z) then
					--Is this a duplicate?
					local Dup = false
					for i=1,#Matches do
						if IsEqual({x,y,z},Matches[i]) then
							Dup = true
							break
						end
					end
					if not Dup then
						table.insert(Matches,{x,y,z})
					end
				end
			end
		end
	end
	Triangles[p] = #Matches
end

for i=1,#Triangles do
	print(i..": "..Triangles[i])
end