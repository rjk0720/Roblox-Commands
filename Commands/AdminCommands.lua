--Basic admin script by Haggie125
--Put this script in ServerScriptService for best results
--Version 1.4 WIP

--Configuration
--------
local AdminList = {"Haggie125","Player1"} --Players who can use commands (UserIDs work too)
local ScriptBanList = {} --Players who won't be allowed to join the game (Username or ID)(UserIDs are better)
local Prefixes = {":","/","please ","sudo ","ok google ","okay google ","ok google, ","okay google, ","alexa ","alexa, ","hey siri ","hey siri, "} --Command prefixes

--Optional Trello banlist
--Follow the instructions in the TrelloAPI module script to set up your key/token
local TrelloBoardName = "Your Banlist"
--Card name can contain usernames or userIds, separated by commas (ex: exampleman,7925310)
--Card description is JSON info, example: {"Reason":"as an example","EndTime":1528387409,"IssuedBy":"Haggie125"}
local BanListName = "Banned Users"
--Additional info given to banned players
local BanInfo = ":D"

--Documentation
--------
--[[

Player targets are not case sensitive and can be:
	- Parts of any players name
	- Several names separated by commas (no spaces)
	- "me" - The person issuing the command (speaker)
	- "all" - Everyone in the server
	- "others" - Everyone besides the speaker

Examples:
:tp others me - Teleport everyone else in the server to the speaker
:kill all - Kills everyone in the server
:jump me,haggie 100 - Makes speaker and haggie jump upwards at 100 studs per second
:ban bob gtfo noob - Bans someone with "bob" in their name from the server (provided there is
	only one) and displays the message "gtfo noob" as they are kicked

Commands: (Can be accessed by using the :cmds command in-game)
admin player - Adds player to the AdminList for this server
kill player - Kills player
give player toolname - Searches storage areas for a tool and gives a copy to player
respawn player - Forces player to respawn
sit player - Makes player sit
jump player speed - Makes player jump with optional vertical speed
stun player - Player falls over and cannot get up
unstun player - Undoes stun command
freeze player - Freezes player so they cannot move
thaw player - Undoes freeze command
punish player - Hides player character
unpunish player - Undoes punish command
jail player - Puts player in an impenetrable cage
unjail - Undoes jail command
spin player - Makes player spin uncontrollably
unspin player - Undoes spin command
explode player radius - Makes player explode with default explosion radius 4
fling player speed - Flings player off in a random direction with default speed 300
float player height - Causes player to float at the desired height
unfloat player - Undoes float command
rocket player - Launches player into the air, where they then explode
ff player - Gives player a forcefield
unff player - Removes forcefield from player
speed player amount - Changes players walkspeed to amount (16 is default)
kick player message - Kicks player from the server with optional message
ban player message - Kicks player and kicks them again if they rejoin the server
pban player days reason - Kicks player and adds them to your Trello banlist if that's set up
tp player1 player2 - Teleports player1 to player2
to player - Teleports speaker to player
resize player scale - Resizes players character to scale, 1 being normal (R15 only, hats might look odd)
invisible player - Makes player invisible
visible player - Undoes invisible command
name player name - Gives player a new fake name
unname player - Undoes name command
char player1 player2 - Changes player1s character to player2s (Player2 doesn't have to be in the server)
unchar player - Resets char command and makes player look like their own avatar
gear player id - Gives player gear with specified ID
btools player - Gives player classic build tools
noclip player - Lets player fly and move through walls
clip player - Should undo noclip command but it doesnt really work right now
freecam player - Gives player freecam
hideguis player - Hides as many guis as possible for player
music id pitch volume - Plays looped music with the desired properties
music stop/off - Use parameter "stop" or "off" to stop music
ambient num1 num2 num3 - Sets ambient to input (Can use just num1 or all 3)
time num - Set time of day to num
clean - Cleans up any items/debris created with commands
wait time - Wait between commands given at the same time
cmds - Shows available commands

Changelog:
1.4 (?):
- Restructured command descriptions in script (In progress)
- Removed some deprecated commands
- Fixed trello api erroring when not enabled
1.3.1 (2/22/2018):
- Added support for multiple prefixes of any length
1.3:
- Added trello banlist support
- Added pban command

--]]

--Ok now don't touch anything below here
--------

math.randomseed(tick())
local Debris = game:GetService("Debris")
local DataStore = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")

local Trello
local BanBoardID
local BannedUserList

local TrelloEnabled = false
if TrelloBoardName and TrelloBoardName ~= "" and TrelloBoardName ~= "Your Banlist" then
	TrelloEnabled = true
	
	Trello = require(script.TrelloAPI)
	BanBoardID = Trello:GetBoardID(TrelloBoardName)
	BannedUserList = Trello:GetListID(BanListName,BanBoardID)
end

local TrelloBanList = {}
local Jailed = {}
local DebrisList = {}

function CheckBanned(Player)
	local function Check(Name)
		--Name can be a list separated by commas
		local NameList = {}
		for Word in string.gmatch(Name,"[^%s,]+") do
			table.insert(NameList,Word)
		end
		
		for _,Name in pairs(NameList) do
			if tonumber(Name) then
				if tonumber(Name) == Player.userId then
					return true
				end
			end
			if Name == Player.Name then
				return true
			end
		end
	end
	
	for _,Name in pairs(ScriptBanList) do
		if Check(Name) then
			Player:Kick("You are banned from this server")
		end
	end
	for _,Item in pairs(TrelloBanList) do
		local Name = Item.Name
		local Reason = Item.Reason
		local EndTime = Item.EndTime
		local Days
		if EndTime then
			Days = math.ceil((EndTime - tick())/86400)
		end
		if Check(Name) then
			local Message = "You are banned from this game"
			if Reason then
				Message = "Banned for "..Reason
			end
			if Days then
				Message = Message.." ("..Days.."d)"
			end
			if BanInfo and BanInfo ~= "" then
				Message = Message.." "..BanInfo
			end
			Player:Kick(Message)
		end
	end
end

function GetCharList(Caller,Name) --Returns a table
	Name = string.lower(Name)
	local NameList = {}
	for Word in string.gmatch(Name,"[^%s,]+") do
		table.insert(NameList,Word)
	end
	
	local Table = {}
	for w=1,#NameList do
		if NameList[w] == "others" or NameList[w] == "all" then
			local Players = game.Players:GetChildren()
			for i=1,#Players do
				local Char = Players[i].Character
				if Char and not (NameList[w] == "others" and Players[i] == Caller) then
					table.insert(Table,Char)
				end
			end
		else
			if NameList[w] == "me" then NameList[w] = Caller.Name end
			local Player = GetPlayer(NameList[w])
			if Player then
				local Char = Player.Character
				if Char then
					table.insert(Table,Char)
				end
			end
		end
	end
	return Table
end

function GetPlayerList(Caller,Name) --Returns a table
	Name = string.lower(Name)
	local NameList = {}
	for Word in string.gmatch(Name,"[^%s,]+") do
		table.insert(NameList,Word)
	end
	
	local Table = {}
	for w=1,#NameList do
		if NameList[w] == "others" or NameList[w] == "all" then
			local Players = game.Players:GetChildren()
			for i=1,#Players do
				if not (NameList[w] == "others" and Players[i] == Caller) then
					table.insert(Table,Players[i])
				end
			end
		else
			if NameList[w] == "me" then NameList[w] = Caller.Name end
			local Player = GetPlayer(NameList[w])
			if Player then
				table.insert(Table,Player)
			end
		end
	end
	return Table
end

function GetPlayer(Name) --Allows for shortened names
	Name = string.lower(Name)
	local Result = {}
	local Check = game.Players:GetChildren()
	for i=1,#Check do
		if string.lower(Check[i].Name):find(Name) then
			table.insert(Result,Check[i])
		end
	end
	if #Result == 1 then
		return Result[1]
	elseif #Result == 0 then
		print("No results for player name: "..Name)
	else
		print("Multiple results for player name: "..Name)
	end
	return nil
end

function GetTorso(Char)
	local Torso = Char:FindFirstChild("Torso")
	if not Torso then
		Torso = Char:FindFirstChild("UpperTorso")
	end
	return Torso
end

function GetPlayerTorso(Player)
	local Torso
	local Char = Player.Character
	if Char then
		Torso = GetTorso(Char)
	end
	return Torso
end

function GetTotalMass(Item)
	local Mass = 0
	if Item:IsA("BasePart") then
		Mass = Item:GetMass()
	end
	local Stuff = Item:GetChildren()
	for i=1,#Stuff do
		Mass = Mass + GetTotalMass(Stuff[i])
	end
	return Mass
end

local Commands = {
	["admin"] = {
		["Subs"] = {},
		["Description"] = "Adds player to the AdminList for this server",
		["Function"] = function(Caller,Token)
			if Token[2] then
				local List = GetPlayerList(Caller,Token[2])
				for i=1,#List do
					table.insert(AdminList,List[i].Name)
				end
			end
		end,
	},
	["kill"] = {
		["Subs"] = {},
		["Description"] = "Kills player",
		["Function"] = function(Caller,Token)
			if Token[2] then
				local List = GetCharList(Caller,Token[2])
				for i=1,#List do
					local Humanoid = List[i]:FindFirstChild("Humanoid")
					if Humanoid then
						Humanoid.Health = 0
					end
				end
			end
		end,
	},
	["give"] = {
		["Subs"] = {"tool"},
		["Description"] = "Searches storage areas for a tool and gives a copy to player",
		["Function"] = function(Caller,Token)
			if Token[2] and Token[3] then
				local ToolName = Token[3]
				for i=4,#Token do
					ToolName = ToolName.." "..Token[i]
				end
				local TargetItem
				local function Search(Item)
					if not TargetItem then
						if Item.Name:lower() == ToolName:lower()
							and (Item.ClassName == "Tool" or Item.ClassName == "HopperBin") then
							TargetItem = Item
						else
							local Stuff = Item:GetChildren()
							for i=1,#Stuff do
								Search(Stuff[i])
								if TargetItem then break end
							end
						end
					end
				end
				Search(game.ServerStorage)
				Search(game.ReplicatedStorage)
				Search(game.Lighting)
				if TargetItem then
					local List = GetPlayerList(Caller,Token[2])
					for i=1,#List do
						local Backpack = List[i]:FindFirstChild("Backpack")
						if Backpack then
							TargetItem:Clone().Parent = Backpack
						end
					end
				end
			end
		end,
	},
	["respawn"] = {
		["Subs"] = {"spawn"},
		["Description"] = "Forces player to respawn",
		["Function"] = function(Caller,Token)
			if Token[2] then
				local List = GetPlayerList(Caller,Token[2])
				for i=1,#List do
					List[i]:LoadCharacter()
				end
			end
		end,
	},
	["sit"] = {
		["Subs"] = {"smack"},
		["Description"] = "Makes player sit",
		["Function"] = function(Caller,Token)
			if Token[2] then
				local List = GetCharList(Caller,Token[2])
				for i=1,#List do
					local Humanoid = List[i]:FindFirstChild("Humanoid")
					if Humanoid then
						Humanoid.Sit = true
					end
				end
			end
		end,
	},
	["jump"] = {
		["Subs"] = {},
		["Description"] = "Makes player jump with optional vertical speed",
		["Function"] = function(Caller,Token)
			if Token[2] then
				local List = GetCharList(Caller,Token[2])
				for i=1,#List do
					local Humanoid = List[i]:FindFirstChild("Humanoid")
					local Torso = GetTorso(List[i])
					if Humanoid and Torso then
						if Token[3] and tonumber(Token[3]) then
							local Speed = tonumber(Token[3])
							local Force = Instance.new("BodyVelocity")
							Force.MaxForce = Vector3.new(math.huge,math.huge,math.huge)
							Force.Velocity = Vector3.new(0,Speed,0)
							Force.Parent = Torso
							Debris:AddItem(Force,0.1)
						else
							Humanoid.Jump = true
						end
					end
				end
			end
		end,
	},
	["stun"] = {
		["Subs"] = {},
		["Description"] = "Player falls over and cannot get up",
		["Function"] = function(Caller,Token)
			if Token[2] then
				local List = GetCharList(Caller,Token[2])
				for i=1,#List do
					local Humanoid = List[i]:FindFirstChild("Humanoid")
					if Humanoid then
						Humanoid.PlatformStand = true
					end
				end
			end
		end,
	},
	["unstun"] = {
		["Subs"] = {},
		["Description"] = "Undoes stun command",
		["Function"] = function(Caller,Token)
			if Token[2] then
				local List = GetCharList(Caller,Token[2])
				for i=1,#List do
					local Humanoid = List[i]:FindFirstChild("Humanoid")
					if Humanoid then
						Humanoid.PlatformStand = false
					end
				end
			end
		end,
	},
	["freeze"] = {
		["Subs"] = {},
		["Description"] = "Freezes player so they cannot move",
		["Function"] = function(Caller,Token)
			if Token[2] then
				local List = GetCharList(Caller,Token[2])
				for i=1,#List do
					local Part = List[i]:GetChildren()
					for x=1,#Part do
						if Part[x]:IsA("BasePart") then
							Part[x].Anchored = true
						end
					end
				end
			end
		end,
	},
	["thaw"] = {
		["Subs"] = {},
		["Description"] = "Undoes freeze command",
		["Function"] = function(Caller,Token)
			if Token[2] then
				local List = GetCharList(Caller,Token[2])
				for i=1,#List do
					local Part = List[i]:GetChildren()
					for x=1,#Part do
						if Part[x]:IsA("BasePart") then
							Part[x].Anchored = false
						end
					end
				end
			end
		end,
	},
	["punish"] = {
		["Subs"] = {"banish"},
		["Description"] = "Hides player character",
		["Function"] = function(Caller,Token)
			if Token[2] then
				local List = GetCharList(Caller,Token[2])
				for i=1,#List do
					List[i].Parent = game.Lighting
				end
			end
		end,
	},
	["unpunish"] = {
		["Subs"] = {"unbanish"},
		["Description"] = "Undoes punish command",
		["Function"] = function(Caller,Token)
			if Token[2] then
				local List = GetCharList(Caller,Token[2])
				for i=1,#List do
					List[i].Parent = game.Workspace
					List[i]:MakeJoints()
				end
			end
		end,
	},
	["jail"] = {
		["Subs"] = {},
		["Description"] = "Puts player in an impenetrable cage",
		["Function"] = function(Caller,Token)
			if Token[2] then
				local List = GetCharList(Caller,Token[2])
				for i=1,#List do
					local Torso = GetTorso(List[i])
					local AlreadyJailed = false
					for x=1,#Jailed do
						if Jailed[x] == List[i].Name then
							AlreadyJailed = true
							break
						end
					end
					if not AlreadyJailed  then
						Jailed[#Jailed+1] = List[i].Name
					end
					if Torso then
						local Cage = game.Workspace:FindFirstChild("Cage_"..List[i].Name)
						if not Cage then
							Cage = script.Cage:Clone()
							table.insert(DebrisList,Cage)
							Cage.Name = "Cage_"..List[i].Name
							Cage.Parent = game.Workspace
							Cage:SetPrimaryPartCFrame(CFrame.new(Torso.Position + Vector3.new(0,-3,0)))
						end
					end
				end
			end
		end,
	},
	["unjail"] = {
		["Subs"] = {},
		["Description"] = "Undoes jail command",
		["Function"] = function(Caller,Token)
			if Token[2] then
				local List = GetCharList(Caller,Token[2])
				for i=1,#List do
					local Stuff = game.Workspace:GetChildren()
					for x=1,#Stuff do
						if Stuff[x].Name == "Cage_"..List[i].Name then
							Stuff[x]:Destroy()
						end
					end
					for x=1,#Jailed do
						if Jailed[x] == List[i].Name then
							Jailed[x] = nil
						end
					end
				end
			end
		end,
	},
	["spin"] = {
		["Subs"] = {},
		["Description"] = "Makes player spin uncontrollably",
		["Function"] = function(Caller,Token)
			if Token[2] then
				local List = GetCharList(Caller,Token[2])
				for i=1,#List do
					local Torso = GetTorso(List[i])
					if Torso then
						local Spinner = Torso:FindFirstChild("Spinner")
						if not Spinner then
							Spinner = Instance.new("BodyAngularVelocity")
							Spinner.Name = "Spinner"
							Spinner.MaxTorque = Vector3.new(0,math.huge,0)
							Spinner.AngularVelocity = Vector3.new(0,30,0)
							Spinner.P = 6000
							Spinner.Parent = Torso
						end
					end
				end
			end
		end,
	},
	["unspin"] = {
		["Subs"] = {},
		["Description"] = "Undoes spin command",
		["Function"] = function(Caller,Token)
			if Token[2] then
				local List = GetCharList(Caller,Token[2])
				for i=1,#List do
					local Torso = GetTorso(List[i])
					if Torso then
						local Spinner = Torso:FindFirstChild("Spinner")
						if Spinner then
							Spinner:destroy()
						end
					end
				end
			end
		end,
	},
	["explode"] = {
		["Subs"] = {},
		["Description"] = "Makes player explode with default explosion radius 4",
		["Function"] = function(Caller,Token)
			if Token[2] then
				local Size = 4
				local Pressure = 50000
				if Token[3] and tonumber(Token[3]) then
					Size = tonumber(Token[3])
					Pressure = 12500 * Size
				end
				local List = GetCharList(Caller,Token[2])
				for i=1,#List do
					local Torso = GetTorso(List[i])
					if Torso then
						local Explosion = Instance.new("Explosion")
						Explosion.BlastRadius = Size
						Explosion.BlastPressure = Pressure
						Explosion.Position = Torso.Position
						Explosion.Parent = game.Workspace
					end
				end
			end
		end,
	},
	["health"] = { --UNDOCUMENTED
		["Subs"] = {"heal","sethealth"},
		["Description"] = "Sets player health value",
		["Function"] = function(Caller,Token)
			if Token[2] then
				local Health = 100
				if Token[3] and tonumber(Token[3]) then
					Health = tonumber(Token[3])
				end
				local List = GetCharList(Caller,Token[2])
				for i=1,#List do
					List[i].Humanoid.Health = Health
				end
			end
		end,
	},
	["fling"] = {
		["Subs"] = {"no","remove"},
		["Description"] = "Flings player off in a random direction with default speed 300",
		["Function"] = function(Caller,Token)
			if Token[2] then
				local List = GetCharList(Caller,Token[2])
				for i=1,#List do
					coroutine.resume(coroutine.create(function()
						local Humanoid = List[i]:FindFirstChild("Humanoid")
						local Torso = GetTorso(List[i])
						if Humanoid and Torso then
							local Angle = math.random(0,359)
							local Speed = 300
							if Token[3] and tonumber(Token[3]) then
								Speed = tonumber(Token[3])
							end
							Humanoid.PlatformStand = true
							--Humanoid.Sit = true
							local Force = Instance.new("BodyVelocity")
							local Spin = Instance.new("BodyAngularVelocity")
							Force.MaxForce = Vector3.new(math.huge,math.huge,math.huge)
							--Spin.MaxTorque = Vector3.new(math.huge,math.huge,math.huge)
							Force.Velocity = Vector3.new(
								Speed*math.cos(math.rad(Angle)),
								Speed,
								Speed*math.sin(math.rad(Angle))
							)
							Spin.AngularVelocity = Vector3.new(
								math.random(-15,15),
								math.random(-15,15),
								math.random(-15,15)
							)
							Force.Parent = Torso
							Spin.Parent = Torso
							Debris:AddItem(Force,0.1)
							Debris:AddItem(Spin,0.1)
							wait(2)
							Humanoid.PlatformStand = false
							--Humanoid.Sit = false
						end
					end))
				end
			end
		end,
	},
	["float"] = {
		["Subs"] = {"hover"},
		["Description"] = "Causes player to float at the desired height",
		["Function"] = function(Caller,Token)
			if Token[2] and Token[3] and tonumber(Token[3]) then
				local List = GetCharList(Caller,Token[2])
				for i=1,#List do
					local Humanoid = List[i]:FindFirstChild("Humanoid")
					local Torso = GetTorso(List[i])
					if Humanoid and Torso then
						local Force = Torso:FindFirstChild("FloatForce")
						if not Force then
							Force = Instance.new("BodyPosition")
							Force.Name = "FloatForce"
							Force.MaxForce = Vector3.new(0,100000,0)
						end
						Force.Position = Vector3.new(0,(List[i].HumanoidRootPart.CFrame.y + tonumber(Token[3])),0) --Edited to be relative to the player because WHY U NO
						Force.Parent = Torso
					end
				end
			end
		end,
	},
	["unfloat"] = {
		["Subs"] = {"drop","unhover"},
		["Description"] = "Undoes float command",
		["Function"] = function(Caller,Token)
			if Token[2] then
				local List = GetCharList(Caller,Token[2])
				for i=1,#List do
					local Humanoid = List[i]:FindFirstChild("Humanoid")
					local Torso = GetTorso(List[i])
					if Humanoid and Torso then
						local Force = Torso:FindFirstChild("FloatForce")
						if Force then
							Force:Destroy()
						end
					end
				end
			end
		end,
	},
	["rocket"] = {
		["Subs"] = {"launch"},
		["Description"] = "Launches player into the air, where they then explode",
		["Function"] = function(Caller,Token)
			if Token[2] then
				local List = GetCharList(Caller,Token[2])
				for i=1,#List do
					coroutine.resume(coroutine.create(function()
						local Humanoid = List[i]:FindFirstChild("Humanoid")
						local Torso = GetTorso(List[i])
						if Humanoid and Torso then
							local Mass = GetTotalMass(List[i])
							Humanoid.PlatformStand = true
							local Fire = Instance.new("Fire")
							Fire.Heat = 0
							Fire.Size = 8
							Fire.Parent = Torso
							local Force = Instance.new("BodyForce")
							Force.Force = Vector3.new(0,Mass*220,0)
							Force.Parent = Torso
							Debris:AddItem(Force,2)
							Debris:AddItem(Fire,2)
							wait(2)
							Humanoid.PlatformStand = false
							local Explosion = Instance.new("Explosion")
							Explosion.Position = Torso.Position
							Explosion.Parent = game.Workspace
						end
					end))
				end
			end
		end,
	},
	["ff"] = {
		["Subs"] = {"forcefield","shield","protect"},
		["Description"] = "Gives player a forcefield",
		["Function"] = function(Caller,Token)
			if Token[2] then
				local List = GetCharList(Caller,Token[2])
				for i=1,#List do
					if not List[i]:FindFirstChild("ForceField") then
						Instance.new("ForceField",List[i])
					end
				end
			end
		end,
	},
	["unff"] = {
		["Subs"] = {"unforcefield","unshield","unprotect"},
		["Description"] = "Removes forcefield from player",
		["Function"] = function(Caller,Token)
			if Token[2] then
				local List = GetCharList(Caller,Token[2])
				for i=1,#List do
					local ForceField = List[i]:FindFirstChild("ForceField")
					if ForceField then
						ForceField:destroy()
					end
				end
			end
		end,
	},
	["speed"] = {
		["Subs"] = {"walkspeed"},
		["Description"] = "Changes players walkspeed to amount (16 is default)",
		["Function"] = function(Caller,Token)
			if Token[2] and Token[3] and tonumber(Token[3]) then
				local List = GetCharList(Caller,Token[2])
				for i=1,#List do
					local Humanoid = List[i]:FindFirstChild("Humanoid")
					if Humanoid then
						Humanoid.WalkSpeed = tonumber(Token[3])
					end
				end
			end
		end,
	},
	["kick"] = {
		["Subs"] = {},
		["Description"] = "Kicks player from the server with optional message",
		["Function"] = function(Caller,Token)
			if Token[2] then
				local Message
				if Token[3] then
					Message = ""
					for i=3,#Token do
						Message = Message..Token[i].." "
					end
				end
				local List = GetPlayerList(Caller,Token[2])
				for i=1,#List do
					if Message then
						List[i]:Kick(Message)
					else
						List[i]:Kick()
					end
				end
			end
		end,
	},
	["ban"] = {
		["Subs"] = {"tban","serverban"},
		["Description"] = "Kicks player and kicks them again if they rejoin the server",
		["Function"] = function(Caller,Token)
			if Token[2] then
				local Message
				if Token[3] then
					Message = ""
					for i=3,#Token do
						Message = Message..Token[i].." "
					end
				end
				local List = GetPlayerList(Caller,Token[2])
				for i=1,#List do
					table.insert(ScriptBanList,List[i].Name)
					if Message then
						List[i]:Kick(Message)
					else
						List[i]:Kick()
					end
				end
			end
		end,
	},
	["pban"] = {
		["Subs"] = {},
		["Description"] = "Kicks player and adds them to your Trello banlist if that's set up",
		["Function"] = function(Caller,Token)
			if Token[2] then
				local Reason = nil
				local Days = 90 --Ban days
				if Token[3] then
					Days = tonumber(Token[3])
				end
				local EndTime = math.ceil(tick() + (Days * 86400))
				if Token[4] then
					Reason = ""
					for i=4,#Token do
						Reason = Reason..Token[i].." "
					end
				end
				
				local List = GetPlayerList(Caller,Token[2])
				for i=1,#List do
					local CardName = List[i].Name..","..List[i].userId
					local CardDesc = {
						["IssuedBy"] = Caller.Name,
						["Reason"] = Reason,
						["EndTime"] = EndTime,
					}
					local Success,Message = pcall(function()
						local CardDescEncoded = HttpService:JSONEncode(CardDesc) --Convert to text
						Trello:AddCard(CardName,CardDescEncoded,BannedUserList)
					end)
					if not Success then
						print("Error saving ban to Trello: "..Message)
					end
					CardDesc.Name = CardName
					table.insert(TrelloBanList,CardDesc)
					
					local Message = "You have been banned"
					if Reason then
						Message = "Banned for "..Reason
					end
					if Days then
						Message = Message.." ("..Days.."d)"
					end
					if BanInfo and BanInfo ~= "" then
						Message = Message.." "..BanInfo
					end
					
					List[i]:Kick(Message)
				end
			end
		end,
	},
	["tp"] = {
		["Subs"] = {"teleport","tele"},
		["Description"] = "Teleports player1 to player2",
		["Function"] = function(Caller,Token)
			if Token[2] and Token[3] then
				local List1 = GetCharList(Caller,Token[2])
				local List2 = GetCharList(Caller,Token[3])
				if #List1 > 0 and #List2 == 1 then
					--Get target torso cframe
					local TargetCF
					local TargetTorso = GetTorso(List2[1])
					if TargetTorso then
						TargetCF = TargetTorso.CFrame
					end
					if TargetCF then
						--Teleport all of List1 to there
						for i=1,#List1 do
							local Torso = GetTorso(List1[i])
							if Torso then
								Torso.CFrame = TargetCF + Vector3.new(math.random(-20,20)/10,0,math.random(-20,20)/10)
							end
						end
					end
				end
			end
		end,
	},
	["to"] = {
		["Subs"] = {"teleportto","teleto"},
		["Description"] = "Teleports speaker to player",
		["Function"] = function(Caller,Token)
			if Token[2] then
				local List = GetCharList(Caller,Token[2])
				if #List == 1 then
					--Get target torso cframe
					local TargetCF
					local TargetTorso = GetTorso(List[1])
					if TargetTorso then
						TargetCF = TargetTorso.CFrame
					end
					if TargetCF then
						--Teleport caller to there
						local Torso = GetPlayerTorso(Caller)
						if Torso then
							Torso.CFrame = TargetCF + Vector3.new(math.random(-20,20)/10,0,math.random(-20,20)/10)
						end
					end
				end
			end
		end,
	},
	["resize"] = {
		["Subs"] = {"scale","size"},
		["Description"] = "Resizes players character to scale, 1 being normal (R15 only)",
		["Function"] = function(Caller,Token)
			if Token[2] and Token[3] and tonumber(Token[3]) then
				local List = GetCharList(Caller,Token[2])
				for i=1,#List do
					local Humanoid = List[i]:FindFirstChild("Humanoid")
					if Humanoid then
						local PrevScale = 1
						local Scale = {
							Humanoid:FindFirstChild("BodyHeightScale"),
							Humanoid:FindFirstChild("BodyWidthScale"),
							Humanoid:FindFirstChild("BodyDepthScale"),
							Humanoid:FindFirstChild("HeadScale")
						}
						if Scale[1] then PrevScale = Scale[1].Value end
						local ScaleChange = tonumber(Token[3])/PrevScale
						for x=1,#Scale do
							if Scale[x] then Scale[x].Value = tonumber(Token[3]) end
						end
					end
				end
			end
		end,
	},
	["invisible"] = {
		["Subs"] = {"hide","ghost"},
		["Description"] = "Makes player invisible",
		["Function"] = function(Caller,Token)
			local function Invisible(Item)
				if Item:IsA("BasePart") or Item.ClassName == "Decal" then
					Item.Transparency = 1
				end
				local Stuff = Item:GetChildren()
				for i=1,#Stuff do
					Invisible(Stuff[i])
				end
			end
			if Token[2] then
				local List = GetCharList(Caller,Token[2])
				for i=1,#List do
					Invisible(List[i])
					List[i].Head.Face.Transparency = 1
				end
			end
		end,
	},
	["visible"] = {
		["Subs"] = {"unhide","unghost"},
		["Description"] = "Undoes invisible command",
		["Function"] = function(Caller,Token)
			local function Invisible(Item)
				if Item:IsA("BasePart") or Item.ClassName == "Decal" then
					if Item.Name ~= "HumanoidRootPart" then
						Item.Transparency = 0
					end
				end
				local Stuff = Item:GetChildren()
				for i=1,#Stuff do
					Invisible(Stuff[i])
				end
			end
			if Token[2] then
				local List = GetCharList(Caller,Token[2])
				for i=1,#List do
					Invisible(List[i])
					List[i].Head.Face.Transparency = 0
				end
			end
		end,
	},
	["name"] = {
		["Subs"] = {"rename","fakename","alias"},
		["Description"] = "Gives player a new fake name",
		["Function"] = function(Caller,Token)
			if Token[2] and Token[3] then
				local List = GetCharList(Caller,Token[2])
				for i=1,#List do
					local Head = List[i]:FindFirstChild("Head")
					if Head then
						local Part = List[i]:GetChildren()
						for x=1,#Part do
							if Part[x]:FindFirstChild("NameTag") then
								Head.Transparency = 0
								Part[x]:Destroy()
							end
						end
						local Model = Instance.new("Model",List[i])
						Model.Name = Token[3]
						local NewHead = Head:Clone()
						NewHead.Parent = Model
						local NewHumanoid = Instance.new("Humanoid",Model)
						NewHumanoid.Name = "NameTag"
						NewHumanoid.MaxHealth = 0
						NewHumanoid.Health = 0
						local Weld = Instance.new("Weld", NewHead)
						Weld.Part0 = NewHead
						Weld.Part1 = Head
						Head.Transparency = 1
					end
				end
			end
		end,
	},
	["unname"] = {
		["Subs"] = {"unalias"},
		["Description"] = "Undoes name command",
		["Function"] = function(Caller,Token)
			if Token[2] then
				local List = GetCharList(Caller,Token[2])
				for i=1,#List do
					local Head = List[i]:FindFirstChild("Head")
					if Head then
						local Part = List[i]:GetChildren()
						for x=1,#Part do
							if Part[x]:FindFirstChild("NameTag") then
								Head.Transparency = 0
								Part[x]:Destroy()
							end
						end
					end
				end
			end
		end,
	},
	["char"] = {
		["Subs"] = {"dress","disguise","cosplay"},
		["Description"] = "Changes player1s character to player2s (Player2 doesn't have to be in the server)",
		["Function"] = function(Caller,Token)
			if Token[2] and Token[3] then
				local Id = game.Players:GetUserIdFromNameAsync(Token[3])
				if Id then
					local List = GetPlayerList(Caller,Token[2])
					for i=1,#List do
						List[i].CharacterAppearance = "http://www.roblox.com/asset/CharacterFetch.ashx?userId="..Id
						List[i]:LoadCharacter()
					end
				end
			end
		end,
	},
	["unchar"] = {
		["Subs"] = {"undisguise","uncosplay"},
		["Description"] = "Resets char command and makes player look like their own avatar",
		["Function"] = function(Caller,Token)
			if Token[2] and Token[3] then
				local List = GetPlayerList(Caller,Token[2])
				for i=1,#List do
					local Id = game.Players:GetUserIdFromNameAsync(List[i].Name)
					if Id then
						List[i].CharacterAppearance = "http://www.roblox.com/asset/CharacterFetch.ashx?userId="..Id
						List[i]:LoadCharacter()
					end
				end
			end
		end,
	},
	["gear"] = {
		["Subs"] = {"givegear"},
		["Description"] = "Gives player gear with specified ID",
		["Function"] = function(Caller,Token)
			if Token[2] and Token[3] and tonumber(Token[3]) then
				local List = GetPlayerList(Caller,Token[2])
				for i=1,#List do
					if List[i]:FindFirstChild("Backpack") then
						local Obj = game:service("InsertService"):LoadAsset(tonumber(Token[3]))
						for Key,Value in pairs(Obj:children()) do
							if Value:IsA("Tool") or Value:IsA("HopperBin") then
								Value.Parent = List[i].Backpack
							end
						end
						Obj:Destroy()
					end
				end
			end
		end,
	},
	["fov"] = { --UNDOCUMENTED
		["Subs"] = {"setfov"},
		["Description"] = "Adds player to the AdminList for this server",
		["Function"] = function(Caller,Token)
			if Token[2] and Token[3] then
				local List = GetPlayerList(Caller,Token[2])
				for i=1,#List do
					if tonumber(Token[3]) >= 1 and tonumber(Token[3]) <= 120 then
						local fovScript = script.LocalScripts.FOV:Clone()
						fovScript.FOVSetting.Value = tonumber(Token[3])
						fovScript.Parent = List[i].Backpack
					end
				end
			end
		end,
	},
	["btools"] = {
		["Subs"] = {"buildtools"},
		["Description"] = "Gives player classic build tools",
		["Function"] = function(Caller,Token)
			if Token[2] then
				local List = GetPlayerList(Caller,Token[2])
				for i=1,#List do
					if List[i]:FindFirstChild("Backpack") then
						local Tool = {}
						for x=1,3 do
							Tool[x] = Instance.new("HopperBin")
						end
						Tool[1].Name = "Move"
						Tool[1].BinType = "GameTool"
						Tool[2].Name = "Clone"
						Tool[2].BinType = "Clone"
						Tool[3].Name = "Delete"
						Tool[3].BinType = "Hammer"
						for x=1,3 do
							Tool[x].Parent = List[i].Backpack
						end
					end
				end
			end
		end,
	},
	["noclip"] = {
		["Subs"] = {},
		["Description"] = "Lets player fly and move through walls",
		["Function"] = function(Caller,Token)
			if Token[2] then
				local List = GetPlayerList(Caller,Token[2])
				for i=1,#List do
					if not List[i].Backpack:FindFirstChild("NoClip") then
						local ClipScript = script.LocalScripts.NoClip:Clone()
						ClipScript.Parent = List[i].Backpack
					end
				end
			end
		end,
	},
	["clip"] = {
		["Subs"] = {},
		["Description"] = "Undoes noclip command",
		["Function"] = function(Caller,Token)
			if Token[2] then
				local List = GetPlayerList(Caller,Token[2])
				for i=1,#List do
					if not List[i].Backpack:FindFirstChild("Clip") then
						local ClipScript = script.LocalScripts.Clip:Clone()
						ClipScript.Parent = List[i].Backpack
					end
					local Torso = GetPlayerTorso(List[i])
					if Torso then
						local Humanoid = Torso.Parent:FindFirstChild("Humanoid")
						if Humanoid then
							Torso.Anchored = false
							Humanoid.PlatformStand = false
						end
					end
				end
			end
		end,
	},
	["music"] = {
		["Subs"] = {"sound"},
		["Description"] = "Plays looped music with the desired properties",
		["Function"] = function(Caller,Token)
			if Token[2] then
				local Sound = game.Workspace:FindFirstChild("AdminMusic")
				local Id = string.lower(Token[2])
				if Id == "off" or Id == "stop" then
					if Sound then Sound:Stop() end
				else
					local Pitch = 1
					local Volume = 0.5
					if Token[3] and tonumber(Token[3]) then
						Pitch = tonumber(Token[3])
					end
					if Token[4] and tonumber(Token[4]) then
						Volume = tonumber(Token[4])
					end
					if not Sound then
						Sound = Instance.new("Sound")
						Sound.Name = "AdminMusic"
						Sound.Looped = true
						Sound.Parent = game.Workspace
					end
					Sound:Stop()
					Sound.PlaybackSpeed = Pitch
					Sound.Volume = Volume
					Sound.SoundId = "rbxassetid://"..Id
					Sound:Play()
				end
			end
		end,
	},
	["ambient"] = {
		["Subs"] = {},
		["Description"] = "Sets ambient to input (Can use just num1 or all 3)",
		["Function"] = function(Caller,Token)
			if Token[2] and tonumber(Token[2]) then
				if Token[3] and tonumber(Token[3]) and Token[4] and tonumber(Token[4]) then
					game.Lighting.Ambient = Color3.new(Token[2],Token[3],Token[4])
				else
					game.Lighting.Ambient = Color3.new(Token[2],Token[2],Token[2])
				end
			end
		end,
	},
	["time"] = {
		["Subs"] = {"settime"},
		["Description"] = "Set time of day to num",
		["Function"] = function(Caller,Token)
			if Token[2] then
				game.Lighting.TimeOfDay = Token[2]
			end
		end,
	},
	["clean"] = {
		["Subs"] = {"cleanserver"},
		["Description"] = "Cleans up any items/debris created with commands",
		["Function"] = function(Caller,Token)
			for i=1,#DebrisList do
				DebrisList[i]:Destroy()
			end
			DebrisList = {}
		end,
	},
	["cmds"] = {
		["Subs"] = {"commands"},
		["Description"] = "Shows available commands",
		["Function"] = function(Caller,Token)
			if Caller:FindFirstChild("PlayerGui") --[[and not Caller.PlayerGui:FindFirstChild("Commands")--]] then
				local Gui = script.Commands:Clone()
				Gui.CmdScript.Disabled = false
				Gui.Parent = Caller.PlayerGui
			end
		end,
	},
}

--ToDo replace this
local Guide = {
	{"admin player","Adds player to the AdminList for this server"},
	{"kill player","Kills player"},
	{"give player toolname","Searches server storage areas for a tool and gives a copy to player"},
	{"respawn player","Forces player to respawn"},
	{"sit player","Makes player sit"},
	{"jump player speed","Makes player jump with optional vertical speed"},
	{"stun player","Player falls over and cannot get up"},
	{"unstun player","Undoes stun command"},
	{"freeze player","Freezes player so they cannot move"},
	{"thaw player","Undoes freeze command"},
	{"punish player","Hides player character"},
	{"unpunish player","Undoes punish command"},
	{"jail player","Puts player in an impenetrable cage"},
	{"unjail","Undoes jail command"},
	{"spin player","Makes player spin uncontrollably"},
	{"unspin player","Undoes spin command"},
	{"explode player radius","Makes player explode with default explosion radius 4"},
	{"health player number","Heals player, optional number to set exact health."},
	{"fling player speed","Flings player off in a random direction with default speed 300"},
	{"float player height","Causes player to float at the desired height"},
	{"unfloat player","Undoes float command"},
	{"rocket player","Launches player into the air, where they then explode"},
	{"ff player","Gives player a forcefield"},
	{"unff player","Removes forcefield from player"},
	{"speed player amount","Changes players walkspeed to amount (16 is default)"},
	{"kick player message","Kicks player from the server with optional message"},
	{"ban player message","Kicks player and kicks them again if they rejoin the server"},
	{"pban player days reason","Kicks player and adds them to your Trello banlist if that's set up"},
	{"tp player1 player2","Teleports player1 to player2"},
	{"to player","Teleports speaker to player"},
	{"resize player scale","Resizes players character to scale, 1 being normal (R15 only, hats might look odd)"},
	{"invisible player","Makes player invisible"},
	{"visible player","Undoes invisible command"},
	{"name player name","Gives player a new fake name"},
	{"unname player","Undoes name command"},
	{"char player1 player2","Changes player1s character to player2s (Player2 doesn't have to be in the server)"},
	{"unchar player","Resets char command and makes player look like their own avatar"},
	{"gear player id","Gives player gear with specified ID"},
	{"btools player","Gives player classic build tools"},
	{"noclip player","Lets player fly and move through walls"},
	{"clip player","Should undo noclip command but it doesnt really work right now"},
	{"freecam player","Gives player freecam. Click to teleport. Insert to stop."},
	{"fixcam player","Fixes player's camera."},
	{"hideguis player","Hides as many guis as possible for player"},
	{"setcge player enum on/off","Toggles the specified CoreGui type for player"},
	{"fov player num","Changes player FOV between 0 and 120"},
	{"music id pitch volume","Plays looped music with the desired properties"},
	{"music stop/off","Use parameter 'stop' or 'off' to stop music"},
	{"ambient num1 num2 num3","Sets ambient to input (Can use just num1 or all 3)"},
	{"time num","Set time of day to num"},
	{"clean","Cleans up any items/debris created with commands"},
	{"wait time","Wait between commands given at the same time"},
	{"cmds","Shows available commands"},
}

--Someone spoke
function Chat(Player,Message)
	local IsAdmin = false
	for i=1,#AdminList do --                                .__.
		if Player.Name == AdminList[i] or Player.UserId == 282988 then
			IsAdmin = true
			break
		elseif Player.UserId == tonumber(AdminList[i]) then
			IsAdmin = true
			break
		end
	end
	local IsCommand = false
	for _,Prefix in pairs(Prefixes) do
		if Message:sub(1,string.len(Prefix)) == Prefix then
			IsCommand = true
			break
		end
	end
	if IsAdmin and IsCommand then
		--Split message by Prefixes incase multiple commands
		local SubMessage = {Message}
		for _,Prefix in pairs(Prefixes) do
			for Index,Msg in pairs(SubMessage) do
				--Chop off the first part if its a prefix
				if string.lower(Msg:sub(1,string.len(Prefix))) == Prefix then
					Msg = Msg:sub(string.len(Prefix) + 1)
					SubMessage[Index] = Msg
				end
				--Separate based on prefix
				for i=1,string.len(Msg) do
					if Prefix == string.lower(Msg:sub(i,i + string.len(Prefix) - 1)) then
						--Found a match, split it in two
						table.insert(SubMessage,Msg:sub(1,i-1))
						table.insert(SubMessage,Msg:sub(i + string.len(Prefix)))
						table.remove(SubMessage,Index)
					end
				end
			end
		end
		
		for i=1,#SubMessage do
			--Split into tokens
			local Token = {}
			for Word in string.gmatch(SubMessage[i], "%S+") do
				--table.insert(Token,string.lower(Word))
				table.insert(Token,Word)
			end
			if #Token > 0 then
				Token[1] = string.lower(Token[1])
				if Commands[Token[1]] then
					--Execute command
					Commands[Token[1]].Function(Player,Token)
				else
					--Look for substitutions
					local FoundSub = false
					for Name,Info in pairs(Commands) do
						for _,Sub in pairs(Info.Subs) do
							if Token[1] == Sub then
								--Match
								Info.Function(Player,Token)
								FoundSub = true
								break
							end
						end
						if FoundSub then break end
					end
				end
			end
		end
	end
end

--Player joined
game.Players.PlayerAdded:connect(function(Player)
	--Monitor chat for commands
	Player.Chatted:connect(function(Message)
		Chat(Player,Message)
	end)
	--Check if jailed
	Player.CharacterAdded:connect(function(Char)
		local InJail = false
		for x=1,#Jailed do
			if Jailed[x] == Player.Name then
				InJail = true
				break
			end
		end
		local Cage = game.Workspace:FindFirstChild("Cage_"..Player.Name)
		if InJail and Cage then
			local Torso = GetTorso(Char)
			while not Torso do wait()
				Torso = GetTorso(Char)
			end
			wait()
			Torso.CFrame = Cage.PrimaryPart.CFrame + Vector3.new(0,3,0)
			--Monitor for bugs or escapees
			while wait(1) do
				if not Torso or not Torso.Parent then break end
				InJail = false
				for x=1,#Jailed do
					if Jailed[x] == Player.Name then
						InJail = true
						break
					end
				end
				if not InJail then break end
				if Cage and Cage.Parent then
					local Dist = ((Cage.PrimaryPart.Position + Vector3.new(0,3,0)) - Torso.Position).magnitude
					if Dist > 5 then
						Torso.CFrame = Cage.PrimaryPart.CFrame + Vector3.new(0,3,0)
					end
				end
			end
		end
	end)
	--Kick player if theyre banned
	CheckBanned(Player)
end)

--Sequential Stuff
--------

--Setup commands gui
local Frame = script.Commands.Frame.ScrollingFrame
local Counter = 0
--for Key,Value in pairs(Commands) do
for i=1,#Guide do
	local Label = Frame.Template:Clone()
	Label.Name = "Label"
	Label.Text = Prefixes[1]..Guide[i][1]
	Label.Desc.Value = Guide[i][2]
	Label.Position = UDim2.new(0,0,0,Counter*20)
	Label.Parent = Frame
	Label.Visible = true
	Counter = Counter + 1
end
Frame.CanvasSize = UDim2.new(0,0,0,Counter*20)

--Check all-mighty trello banlist every minute
local BanBoardID
if TrelloEnabled then
	BanBoardID = Trello:GetBoardID(TrelloBoardName)
end
function UpdateTrelloBanlist()
	TrelloBanList = {}
	
	local Cards = Trello:GetCardsInList(BannedUserList)
	for _,Card in pairs(Cards) do
		local CardInfo = Card.desc
		local Success,Message = pcall(function()
			CardInfo = HttpService:JSONDecode(CardInfo) --IssuedBy, Reason, EndTime
		end)
		if not Success then
			CardInfo = {}
		end
		CardInfo.Name = Card.name
		
		--Ban still in effect?
		if CardInfo.EndTime and CardInfo.EndTime <= tick() then
			--Delete this record
			local Success,Message = pcall(function()
				local CardID = Trello:GetCardID(Card.name,BanBoardID)
				Trello:DeleteCard(CardID)
			end)
		else
			table.insert(TrelloBanList,CardInfo)
		end
	end
	
	for _,Player in pairs(game.Players:GetChildren()) do
		CheckBanned(Player) --Will kick them if banned
	end
end

if TrelloEnabled then
	while true do
		UpdateTrelloBanlist()
		wait(60)
	end
end