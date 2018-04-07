local TweenService = game:GetService("TweenService")

local Player = game.Players.LocalPlayer
local Gui = script.Parent
local Events = Gui:WaitForChild("Events")
local Frame = Gui:WaitForChild("Frame")
local Template = Frame:WaitForChild("Template")

local Info = TweenInfo.new(0.5)
local Notifications = {}

function Notification(Message,Color,Time)
	if not Color then Color = Color3.new(1,1,1) endlocal TweenService = game:GetService("TweenService")

local Player = game.Players.LocalPlayer
local Gui = script.Parent
local Events = Gui:WaitForChild("Events")
local Frame = Gui:WaitForChild("Frame")
local Template = Frame:WaitForChild("Template")

local Info = TweenInfo.new(0.5)
local Notifications = {}

function Notification(Message,Color,Time)
	if not Color then Color = Color3.new(1,1,1) end
	if not Time then Time = 5 end
	local Label = Template:Clone()
	Label.Name = "Label"
	Label.Text = Message
	Label.TextColor3 = Color
	Label.Parent = Frame
	Label.Position = UDim2.new(0,0,1,-26 * (#Notifications))
	Label.TextTransparency = 1
	Label.TextStrokeTransparency = 1
	Label.Visible = true
	local Item = {
		["Label"] = Label,
		["Time"] = Time,
	}
	table.insert(Notifications,Item)
	AdjustPositions()
end

function AdjustPositions()
	--Remove labels that arent being tracked
	for _,Label in pairs(Frame:GetChildren()) do
		local Allowed = false
		for _,Item in pairs(Notifications) do
			if Item.Label == Label then
				Allowed = true
				break
			end
		end
		if not Allowed and Label.Name == "Label" then
			if Label.TextTransparency == 1 then
				Label:destroy()
			elseif Label.TextTransparency == 0 then
				local Goal = {
					["TextTransparency"] = 1,
					["TextStrokeTransparency"] = 1,
				}
				TweenService:Create(Label,Info,Goal):Play()
			end
		end
	end
	--Adjust positions of other labels
	for Num,Item in pairs(Notifications) do
		local Goal = {
			["Position"] = UDim2.new(0,0,1,-26 * (Num-1)),
			["TextTransparency"] = 0,
			["TextStrokeTransparency"] = 0,
		}
		TweenService:Create(Item.Label,Info,Goal):Play()
	end
	--Frame size (can change based on leaderboard items)
	local LeaderboardItems = 0
	if Player:FindFirstChild("leaderstats") then
		LeaderboardItems = #Player.leaderstats:GetChildren()
	end
	local LeaderboardOffset = LeaderboardItems * 77
	
	Frame.Position = UDim2.new(1,-172-LeaderboardOffset,0,0)
	local Goal = {["Size"] = UDim2.new(-0.7,174+LeaderboardOffset,0,#Notifications * 26)}
	TweenService:Create(Frame,Info,Goal):Play()
end

--Server sent a message
Events.Notification.OnClientEvent:connect(function(Message,Color,Time)
	Notification(Message,Color,Time)
end)

--Notification("THIS IS A TEST MESSAGE",Color3.new(1,0,0),7)

while wait(0.1) do
	local Changes = false
	for Num,Item in ipairs(Notifications) do
		Item.Time = Item.Time - 0.1
		if Item.Time <= 0 then
			table.remove(Notifications,Num)
			Changes = true
		end
	end
	if Changes then
		AdjustPositions()
	end
end
	if not Time then Time = 5 end
	local Label = Template:Clone()
	Label.Name = "Label"
	Label.Text = Message
	Label.TextColor3 = Color
	Label.Parent = Frame
	Label.Position = UDim2.new(0,0,1,-26 * (#Notifications))
	Label.TextTransparency = 1
	Label.TextStrokeTransparency = 1
	Label.Visible = true
	local Item = {
		["Label"] = Label,
		["Time"] = Time,
	}
	table.insert(Notifications,Item)
	AdjustPositions()
end

function AdjustPositions()
	--Remove labels that arent being tracked
	for _,Label in pairs(Frame:GetChildren()) do
		local Allowed = false
		for _,Item in pairs(Notifications) do
			if Item.Label == Label then
				Allowed = true
				break
			end
		end
		if not Allowed and Label.Name == "Label" then
			if Label.TextTransparency == 1 then
				Label:destroy()
			elseif Label.TextTransparency == 0 then
				local Goal = {
					["TextTransparency"] = 1,
					["TextStrokeTransparency"] = 1,
				}
				TweenService:Create(Label,Info,Goal):Play()
			end
		end
	end
	--Adjust positions of other labels
	for Num,Item in pairs(Notifications) do
		local Goal = {
			["Position"] = UDim2.new(0,0,1,-26 * (Num-1)),
			["TextTransparency"] = 0,
			["TextStrokeTransparency"] = 0,
		}
		TweenService:Create(Item.Label,Info,Goal):Play()
	end
	--Frame size
	local Goal = {["Size"] = UDim2.new(-0.7,174,0,#Notifications * 26)}
	TweenService:Create(Frame,Info,Goal):Play()
end

--Server sent a message
Events.Notification.OnClientEvent:connect(function(Message,Color,Time)
	Notification(Message,Color,Time)
end)

--Notification("THIS IS A TEST MESSAGE",Color3.new(1,0,0),7)

while wait(0.1) do
	local Changes = false
	for Num,Item in ipairs(Notifications) do
		Item.Time = Item.Time - 0.1
		if Item.Time <= 0 then
			table.remove(Notifications,Num)
			Changes = true
		end
	end
	if Changes then
		AdjustPositions()
	end
end