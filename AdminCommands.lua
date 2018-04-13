--Basic admin script by Haggie125
--Put this script in ServerScriptService for best results
local Version = "1.6 WIP"

--Configuration
--------

--Players who can use commands (UserIDs work too)
local AdminList = {
	--Level 1 admins (All commands)
	[1] = {"Haggie125","Player1"},
	--Level 2 admins (All non-global commands)
	[2] = {},
	--Level 3 admins (Only fun commands)
	[3] = {},
	
	--Commands with level 4+ can be used by anyone --ToDo
}
--Players who won't be allowed to join the game (Username or ID)(UserIDs are better)
local ScriptBanList = {}
--What you can start commands with
local Prefixes = {":","/","please ","sudo ","ok google ","okay google ","ok google, ","okay google, ","alexa ","alexa, ","hey siri ","hey siri, "}

--Apply chat filter to broadcasts made with :m etc
local FilterNotifications = false --ToDo

--Commands gui is open by default?
local ShowGuiAtStart = false

--Optional Trello banlist and adminlist
--Follow the instructions in the TrelloAPI module script to set up your key/token
--Card names can contain usernames or userIds, separated by commas
--Card description contains additional JSON info

--Example Banlist Card:
--	Name: exampleman,7925310
--	Description: {"Reason":"as an example","EndTime":1528387409,"IssuedBy":"Haggie125"}

--Example Adminlist Card:
--	Name: exampleman,7925310
--  Description: {"Level":"1"}

local TrelloEnabled = false
local TrelloBoardName = "Your Banlist"
local AdminListName = "Administrators"
local BanListName = "Banned Users"
--Additional info given to banned players
local BanInfo = ":D"

--Documentation
--------
--[[
	
Say :cmds or hit [Ctrl-Shift-Z] to bring up the commands gui in-game
The commands gui will display everything you need to know about every available command

Commands can be executed from the gui or spoken in chat. Examples:

:tp others me - Teleport everyone else in the server to the speaker
:kill all - Kills everyone in the server
:jump me,haggie 100 - Makes speaker and haggie jump upwards at 100 studs per second
:ban joe nobody likes you - Bans someone with "joe" in their name from the server (provided there is
	only one) and displays the message "nobody likes you" as they are kicked

Player targets are not case sensitive and can be:
	- Parts of any players name
	- Several names separated by commas (no spaces)
	- "me" - The person issuing the command (speaker)
	- "all" - Everyone in the server
	- "others" - Everyone besides the speaker

Changelog:
1.6 (?)
- Added trello adminlist
- Made trello banlist cooldown less awful (ToDo)
- Notification gui size accounts for leaderstats
- Changed jump command to have configurable height
- Added maxhealth command
- Added removetools command
- Added shutdown command
1.5.1 (4/7/2018):
- Adjusted fly command
- Removed warnings for single-letter unknown commands
1.5 (4/6/2018):
- Added commands gui
- Added permission levels
- Added preloaded music list
- Added built-in notifications
- Added shout command
- Added fly command
- Added light command
1.4 (3/2/2018):
- Restructured command descriptions in script
- Added abshover and trip commands
- Removed some deprecated commands
- Fixed trello api erroring when not enabled
1.3.1 (2/22/2018):
- Added support for multiple prefixes of any length
1.3:
- Added trello banlist support
- Added pban command

ToDo:
- Trello admin list
- Move jail model to script (and fix it)
- Simplify Trello token/keys
- Increase trello ban accuracy
- Add admin/nonadmin/random/etc as player targets
- Custom command hotkey?
- Add gui shortcuts for undo-commands
- Print gui commands on server
- Filter player-entered notifications
- Keybind commands
ToDo Commands:
- Disco command
- More ambient commands
- Teleport to mouse command
- Repeat last command command
- Join player in another server command
- Mute player command
- Expand fly command
- Bunch more commands

--]]

--Ok now don't touch anything below here
--------

math.randomseed(tick())
local Debris = game:GetService("Debris")
local DataStore = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")

local Trello
local TrelloBoardID
local BannedUserList
local AdminUserList

if TrelloEnabled then
	Trello = require(script.TrelloAPI)
	TrelloBoardID = Trello:GetBoardID(TrelloBoardName)
	BannedUserList = Trello:GetListID(BanListName,TrelloBoardID)
	AdminUserList = Trello:GetListID(AdminListName,TrelloBoardID)
end

local CommandGui = script:WaitForChild("BasicCommands")
CommandGui.Main.Info.Text = "Commands ["..Version.."]"
if not ShowGuiAtStart then
	CommandGui.Main.Position = UDim2.new(0.5,-400,1.2,0)
end
local TrelloBanList = {}
local TrelloAdminList = {}
local Jailed = {}
local DebrisList = {}

--Mainly from Kohls commands
local MusicList = {
	["caramell"] = 511342351,
	["rick"] = 578934892,
	["halo"] = 1034065,
	["pokemon"] = 1372261,
	["cursed"] = 1372257,
	["extreme"] = 11420933,
	["awaken"] = 27697277,
	["alone"] = 27697392,
	["mario"] = 1280470,
	["choir"] = 1372258,
	["chrono"] = 1280463,
	["dotr"] = 11420922,
	["entertain"] = 27697267,
	["fantasy"] = 1280473,
	["final"] = 1280414,
	["emblem"] = 1372259,
	["flight"] = 27697719,
	["banjo"] = 27697298,
	["gothic"] = 27697743,
	["hiphop"] = 27697735,
	["intro"] = 27697707,
	["mule"] = 1077604,
	["film"] = 27697713,
	["nezz"] = 8610025,
	["angel"] = 1372260,
	["resist"] = 27697234,
	["schala"] = 5985787,
	["organ"] = 11231513,
	["tunnel"] = 9650822,
	["spanish"] = 5982975,
	["starfox"] = 1372262,
	["wind"] = 1015394,
	["guitar"] = 5986151,
}

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
			Days = math.ceil((EndTime - os.time())/86400)
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

--Tell command guis about player list changes
function UpdatePlayerLists()
	local List = {}
	for _,Player in pairs(game.Players:GetChildren()) do
		table.insert(List,Player.Name)
	end
	--Send event to gui owners (admins)
	for _,Player in pairs(game.Players:GetChildren()) do
		if Player:FindFirstChild("PlayerGui") then
			if Player.PlayerGui:FindFirstChild("BasicCommands") then
				Player.PlayerGui.BasicCommands.Events.NewPlayerList:FireClient(Player,List)
			end
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
			local Player = GetPlayer(Caller,NameList[w])
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
			local Player = GetPlayer(Caller,NameList[w])
			if Player then
				table.insert(Table,Player)
			end
		end
	end
	return Table
end

function GetPlayer(Caller,Name) --Allows for shortened names
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
		if Caller then
			Notify(Caller,"No results for player name: "..Name,Color3.fromRGB(255,170,0))
		end
	else
		print("Multiple results for player name: "..Name)
		if Caller then
			Notify(Caller,"Multiple results for player name: "..Name,Color3.fromRGB(255,170,0))
		end
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

function GetHumanoid(Char)
	return Char:FindFirstChild("Humanoid")
end

function GetPlayerHumanoid(Player)
	local Humanoid
	local Char = Player.Character
	if Char then
		Humanoid = Char:FindFirstChild("Humanoid")
	end
	return Humanoid
end

function AdminLevel(Player)
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
	
	local Level = nil
	for Lvl,List in pairs(AdminList) do
		for _,Entry in pairs(List) do
			if Entry == Player.Name or tonumber(Entry) == Player.UserId then
				Level = Lvl
				break
			end
		end
		if Level then break end
	end
	for Lvl,List in pairs(TrelloAdminList) do
		for _,Entry in pairs(List) do
			if Check(Entry.Name) then
				Level = tonumber(Entry.Level)
				break
			end
		end
		if Level then break end
	end
	return Level
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

--From lua-users.org
function CopyTable(orig)
	local orig_type = type(orig)
	local copy
	if orig_type == 'table' then
		copy = {}
		for orig_key, orig_value in next, orig, nil do
			copy[CopyTable(orig_key)] = CopyTable(orig_value)
		end
		setmetatable(copy, CopyTable(getmetatable(orig)))
	else --number, string, boolean, etc
		copy = orig
	end
	return copy
end

function Notify(Player,Message,Color,Time)
	if Player and Player:FindFirstChild("PlayerGui") then
		local Gui = Player.PlayerGui:FindFirstChild("CommandNotifications")
		if Gui and Gui:FindFirstChild("Events") then
			local Event = Gui.Events:FindFirstChild("Notification")
			if Event then
				Event:FireClient(Player,Message,Color,Time)
			end
		end
	end
end

local Commands = {
	{
		["Name"] = "Temp Admin",
		["Commands"] = {"admin","tadmin","tempadmin"},
		["Level"] = "Variable",
		["Args"] = {
			{
				["Name"] = "Target",
				["Type"] = "target",
				["Default"] = nil,
			},
			{
				["Name"] = "Level",
				["Type"] = "number",
				["Default"] = 3,
			},
		},
		["Description"] = "Sets a players admin level for this server. Can only assign and edit levels less than or equal to your own",
		["Function"] = function(Caller,Token)
			if Token[2] then
				local CallerLevel = AdminLevel(Caller)
				local ArgLevel = 3
				if Token[3] and tonumber(Token[3]) then
					ArgLevel = tonumber(Token[3])
				end
				local PlayerList = GetPlayerList(Caller,Token[2])
				for _,Player in pairs(PlayerList) do
					local TargetLevel = AdminLevel(Player)
					--Allowed?
					--Caller can set to this level
					if CallerLevel >= ArgLevel then
						--Target doesnt outrank caller
						if not TargetLevel or CallerLevel >= TargetLevel then
							local IsNewAdmin = true --Needs gui and other setup?
							if TargetLevel then IsNewAdmin = false end
							
							--Remove from any current lists
							for Rank,List in pairs(AdminList) do
								for Num,Name in pairs(List) do
									if Name == Player.Name then
										table.remove(List,Num)
									end
								end
							end
							--Add to new one
							table.insert(AdminList[ArgLevel],Player.Name)
							--Setup
							if IsNewAdmin then
								NewAdmin(Player)
							end
						else
							Notify(Caller,"Insufficient permissions",Color3.fromRGB(255,170,0))
						end
					else
						Notify(Caller,"Insufficient permissions",Color3.fromRGB(255,170,0))
					end
				end
			end
		end,
	},
	{
		["Name"] = "Kill",
		["Commands"] = {"kill"},
		["Level"] = 3,
		["Args"] = {
			{
				["Name"] = "Target",
				["Type"] = "target",
				["Default"] = nil,
			},
		},
		["Description"] = "Kills player",
		["Function"] = function(Caller,Token)
			if Token[2] then
				local CharList = GetCharList(Caller,Token[2])
				for _,Char in pairs(CharList) do
					local Humanoid = GetHumanoid(Char)
					if Humanoid then
						Humanoid.Health = 0
					end
				end
			end
		end,
	},
	{
		["Name"] = "Give Tool",
		["Commands"] = {"give","tool","givetool"},
		["Level"] = 3,
		["Args"] = {
			{
				["Name"] = "Target",
				["Type"] = "target",
				["Default"] = nil,
			},
			{
				["Name"] = "Tool Name",
				["Type"] = "string",
				["Default"] = nil,
			},
		},
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
					local PlayerList = GetPlayerList(Caller,Token[2])
					for _,Player in pairs(PlayerList) do
						local Backpack = Player:FindFirstChild("Backpack")
						if Backpack then
							TargetItem:Clone().Parent = Backpack
						end
					end
				else
					Notify(Caller,"No tools found: "..ToolName,Color3.fromRGB(255,170,0))
				end
			end
		end,
	},
	{
		["Name"] = "Remove Tools",
		["Commands"] = {"rmtools","removetools"},
		["Level"] = 3,
		["Args"] = {
			{
				["Name"] = "Target",
				["Type"] = "target",
				["Default"] = nil,
			},
		},
		["Description"] = "Removes all tools in players backpack",
		["Function"] = function(Caller,Token)
			if Token[2] then
				local PlayerList = GetPlayerList(Caller,Token[2])
				for _,Player in pairs(PlayerList) do
					local Backpack = Player:FindFirstChild("Backpack")
					if Backpack then
						for _,Item in pairs(Backpack:GetChildren()) do
							if Item.ClassName == "Tool" or Item.ClassName == "Hopperbin" then
								Item:destroy()
							end
						end
					end
					local Char = Player.Character
					if Char then
						for _,Item in pairs(Char:GetChildren()) do
							if Item.ClassName == "Tool" or Item.ClassName == "Hopperbin" then
								Item:destroy()
							end
						end
					end
				end
			end
		end,
	},
	{
		["Name"] = "Respawn",
		["Commands"] = {"respawn","spawn"},
		["Level"] = 3,
		["Args"] = {
			{
				["Name"] = "Target",
				["Type"] = "target",
				["Default"] = nil,
			},
		},
		["Description"] = "Forces player to respawn",
		["Function"] = function(Caller,Token)
			if Token[2] then
				local PlayerList = GetPlayerList(Caller,Token[2])
				for _,Player in pairs(PlayerList) do
					Player:LoadCharacter()
				end
			end
		end,
	},
	{
		["Name"] = "Sit",
		["Commands"] = {"sit"},
		["Level"] = 3,
		["Args"] = {
			{
				["Name"] = "Target",
				["Type"] = "target",
				["Default"] = nil,
			},
		},
		["Description"] = "Makes player sit",
		["Function"] = function(Caller,Token)
			if Token[2] then
				local CharList = GetCharList(Caller,Token[2])
				for _,Char in pairs(CharList) do
					local Humanoid = GetHumanoid(Char)
					if Humanoid then
						Humanoid.Sit = true
					end
				end
			end
		end,
	},
	{
		["Name"] = "Trip",
		["Commands"] = {"trip","smack"},
		["Level"] = 3,
		["Args"] = {
			{
				["Name"] = "Target",
				["Type"] = "target",
				["Default"] = nil,
			},
		},
		["Description"] = "Flips player upside down",
		["Function"] = function(Caller,Token)
			if Token[2] then
				local CharList = GetCharList(Caller,Token[2])
				for _,Char in pairs(CharList) do
					local Torso = GetTorso(Char)
					if Torso then
						Torso.CFrame = Torso.CFrame * CFrame.Angles(math.rad(math.random(170,190)),0,0)
					end
				end
			end
		end,
	},
	{
		["Name"] = "Jump",
		["Commands"] = {"jump"},
		["Level"] = 3,
		["Args"] = {
			{
				["Name"] = "Target",
				["Type"] = "target",
				["Default"] = nil,
			},
			{
				["Name"] = "Height",
				["Type"] = "number",
				["Default"] = 6.37,
			},
		},
		["Description"] = "Makes player jump with optional max height",
		["Function"] = function(Caller,Token)
			if Token[2] then
				local CharList = GetCharList(Caller,Token[2])
				for _,Char in pairs(CharList) do
					coroutine.resume(coroutine.create(function()
						local Humanoid = GetHumanoid(Char)
						local Torso = GetTorso(Char)
						if Humanoid and Torso then
							if Token[3] and tonumber(Token[3]) then
								--Determine starting velocity based on desired height
								local Height = tonumber(Token[3])
								local Gravity = 196.2
								--Equation by RegularTetragon
								Humanoid.JumpPower = math.sqrt(2 * Gravity * Height)
							end
							
							Humanoid.Jump = true
							wait()
							Humanoid.JumpPower = 50 --Reset to default
						end
					end))
				end
			end
		end,
	},
	{
		["Name"] = "Stun",
		["Commands"] = {"stun"},
		["Level"] = 3,
		["Args"] = {
			{
				["Name"] = "Target",
				["Type"] = "target",
				["Default"] = nil,
			},
		},
		["Description"] = "Player falls over and cannot get up",
		["Function"] = function(Caller,Token)
			if Token[2] then
				local CharList = GetCharList(Caller,Token[2])
				for _,Char in pairs(CharList) do
					local Humanoid = GetHumanoid(Char)
					if Humanoid then
						Humanoid.PlatformStand = true
					end
				end
			end
		end,
	},
	{
		["Name"] = "Unstun",
		["Commands"] = {"unstun"},
		["Level"] = 3,
		["Args"] = {
			{
				["Name"] = "Target",
				["Type"] = "target",
				["Default"] = nil,
			},
		},
		["Description"] = "Undoes stun command",
		["Function"] = function(Caller,Token)
			if Token[2] then
				local CharList = GetCharList(Caller,Token[2])
				for _,Char in pairs(CharList) do
					local Humanoid = GetHumanoid(Char)
					if Humanoid then
						Humanoid.PlatformStand = false
					end
				end
			end
		end,
	},
	{
		["Name"] = "Freeze",
		["Commands"] = {"freeze","anchor"},
		["Level"] = 3,
		["Args"] = {
			{
				["Name"] = "Target",
				["Type"] = "target",
				["Default"] = nil,
			},
		},
		["Description"] = "Freezes player so they cannot move",
		["Function"] = function(Caller,Token)
			if Token[2] then
				local CharList = GetCharList(Caller,Token[2])
				for _,Char in pairs(CharList) do
					local Part = Char:GetChildren()
					for x=1,#Part do
						if Part[x]:IsA("BasePart") then
							Part[x].Anchored = true
						end
					end
				end
			end
		end,
	},
	{
		["Name"] = "Thaw",
		["Commands"] = {"thaw","unfreeze","unanchor"},
		["Level"] = 3,
		["Args"] = {
			{
				["Name"] = "Target",
				["Type"] = "target",
				["Default"] = nil,
			},
		},
		["Description"] = "Undoes freeze command",
		["Function"] = function(Caller,Token)
			if Token[2] then
				local CharList = GetCharList(Caller,Token[2])
				for _,Char in pairs(CharList) do
					local Part = Char:GetChildren()
					for x=1,#Part do
						if Part[x]:IsA("BasePart") then
							Part[x].Anchored = false
						end
					end
				end
			end
		end,
	},
	{
		["Name"] = "Banish",
		["Commands"] = {"banish","punish"},
		["Level"] = 3,
		["Args"] = {
			{
				["Name"] = "Target",
				["Type"] = "target",
				["Default"] = nil,
			},
		},
		["Description"] = "Hides player character",
		["Function"] = function(Caller,Token)
			if Token[2] then
				local CharList = GetCharList(Caller,Token[2])
				for _,Char in pairs(CharList) do
					Char.Parent = game.Lighting
				end
			end
		end,
	},
	{
		["Name"] = "Unbanish",
		["Commands"] = {"unbanish","unpunish"},
		["Level"] = 3,
		["Args"] = {
			{
				["Name"] = "Target",
				["Type"] = "target",
				["Default"] = nil,
			},
		},
		["Description"] = "Undoes punish command",
		["Function"] = function(Caller,Token)
			if Token[2] then
				local CharList = GetCharList(Caller,Token[2])
				for _,Char in pairs(CharList) do
					Char.Parent = game.Workspace
					Char:MakeJoints()
				end
			end
		end,
	},
	{
		["Name"] = "Jail",
		["Commands"] = {"jail"},
		["Level"] = 3,
		["Args"] = {
			{
				["Name"] = "Target",
				["Type"] = "target",
				["Default"] = nil,
			},
		},
		["Description"] = "Puts player in an impenetrable cage",
		["Function"] = function(Caller,Token)
			if Token[2] then
				local CharList = GetCharList(Caller,Token[2])
				for _,Char in pairs(CharList) do
					local Torso = GetTorso(Char)
					local AlreadyJailed = false
					for x=1,#Jailed do
						if Jailed[x] == Char.Name then
							AlreadyJailed = true
							break
						end
					end
					if not AlreadyJailed  then
						Jailed[#Jailed+1] = Char.Name
					end
					if Torso then
						local Cage = game.Workspace:FindFirstChild("Cage_"..Char.Name)
						if not Cage then
							Cage = script.Cage:Clone()
							table.insert(DebrisList,Cage)
							Cage.Name = "Cage_"..Char.Name
							Cage.Parent = game.Workspace
							Cage:SetPrimaryPartCFrame(CFrame.new(Torso.Position + Vector3.new(0,-3,0)))
						end
					end
				end
			end
		end,
	},
	{
		["Name"] = "Unjail",
		["Commands"] = {"unjail","free"},
		["Level"] = 3,
		["Args"] = {
			{
				["Name"] = "Target",
				["Type"] = "target",
				["Default"] = nil,
			},
		},
		["Description"] = "Undoes jail command",
		["Function"] = function(Caller,Token)
			if Token[2] then
				local CharList = GetCharList(Caller,Token[2])
				for _,Char in pairs(CharList) do
					local Stuff = game.Workspace:GetChildren()
					for x=1,#Stuff do
						if Stuff[x].Name == "Cage_"..Char.Name then
							Stuff[x]:Destroy()
						end
					end
					for x=1,#Jailed do
						if Jailed[x] == Char.Name then
							Jailed[x] = nil
						end
					end
				end
			end
		end,
	},
	{
		["Name"] = "Spin",
		["Commands"] = {"spin"},
		["Level"] = 3,
		["Args"] = {
			{
				["Name"] = "Target",
				["Type"] = "target",
				["Default"] = nil,
			},
			{
				["Name"] = "Speed",
				["Type"] = "number",
				["Default"] = 30,
			},
		},
		["Description"] = "Makes player spin uncontrollably at default speed 30rad/s",
		["Function"] = function(Caller,Token)
			if Token[2] then
				local Speed = 30
				if Token[3] and tonumber(Token[3]) then
					Speed = tonumber(Token[3])
				end
				local CharList = GetCharList(Caller,Token[2])
				for _,Char in pairs(CharList) do
					local Torso = GetTorso(Char)
					if Torso then
						local Spinner = Torso:FindFirstChild("Spinner")
						if not Spinner then
							Spinner = Instance.new("BodyAngularVelocity")
							Spinner.Name = "Spinner"
						end
						Spinner.MaxTorque = Vector3.new(0,math.huge,0)
						Spinner.AngularVelocity = Vector3.new(0,Speed,0)
						Spinner.P = 6000
						Spinner.Parent = Torso
					end
				end
			end
		end,
	},
	{
		["Name"] = "Unspin",
		["Commands"] = {"unspin"},
		["Level"] = 3,
		["Args"] = {
			{
				["Name"] = "Target",
				["Type"] = "target",
				["Default"] = nil,
			},
		},
		["Description"] = "Undoes spin command",
		["Function"] = function(Caller,Token)
			if Token[2] then
				local CharList = GetCharList(Caller,Token[2])
				for _,Char in pairs(CharList) do
					local Torso = GetTorso(Char)
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
	{
		["Name"] = "Explode",
		["Commands"] = {"explode"},
		["Level"] = 3,
		["Args"] = {
			{
				["Name"] = "Target",
				["Type"] = "target",
				["Default"] = nil,
			},
			{
				["Name"] = "Radius",
				["Type"] = "number",
				["Default"] = 4,
			},
		},
		["Description"] = "Makes player explode with default explosion radius 4",
		["Function"] = function(Caller,Token)
			if Token[2] then
				local Size = 4
				local Pressure = 50000
				if Token[3] and tonumber(Token[3]) then
					Size = tonumber(Token[3])
					Pressure = 12500 * Size
				end
				local CharList = GetCharList(Caller,Token[2])
				for _,Char in pairs(CharList) do
					local Torso = GetTorso(Char)
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
	{
		["Name"] = "Set Health",
		["Commands"] = {"health","heal","sethealth"},
		["Level"] = 3,
		["Args"] = {
			{
				["Name"] = "Target",
				["Type"] = "target",
				["Default"] = nil,
			},
			{
				["Name"] = "Health",
				["Type"] = "number",
				["Default"] = 100,
			},
		},
		["Description"] = "Sets player health value. Increases max health if desired value is too high",
		["Function"] = function(Caller,Token)
			if Token[2] then
				local Health
				if Token[3] and tonumber(Token[3]) then
					Health = tonumber(Token[3])
				end
				local CharList = GetCharList(Caller,Token[2])
				for _,Char in pairs(CharList) do
					local Humanoid = GetHumanoid(Char)
					if Humanoid then
						if Health and Health > Humanoid.MaxHealth then
							Humanoid.MaxHealth = Health
						end
						Humanoid.Health = Health or Humanoid.MaxHealth
					end
				end
			end
		end,
	},
	{
		["Name"] = "Set Max Health",
		["Commands"] = {"maxhealth","setmaxhealth"},
		["Level"] = 3,
		["Args"] = {
			{
				["Name"] = "Target",
				["Type"] = "target",
				["Default"] = nil,
			},
			{
				["Name"] = "Max Health",
				["Type"] = "number",
				["Default"] = 100,
			},
		},
		["Description"] = "Sets player max health value",
		["Function"] = function(Caller,Token)
			if Token[2] then
				local MaxHealth = 100
				if Token[3] and tonumber(Token[3]) then
					MaxHealth = tonumber(Token[3])
				end
				local CharList = GetCharList(Caller,Token[2])
				for _,Char in pairs(CharList) do
					local Humanoid = GetHumanoid(Char)
					if Humanoid then
						Humanoid.MaxHealth = MaxHealth
					end
				end
			end
		end,
	},
	{
		["Name"] = "Damage",
		["Commands"] = {"damage","hurt"},
		["Level"] = 3,
		["Args"] = {
			{
				["Name"] = "Target",
				["Type"] = "target",
				["Default"] = nil,
			},
			{
				["Name"] = "Damage",
				["Type"] = "number",
				["Default"] = 10,
			},
		},
		["Description"] = "Removes health from player",
		["Function"] = function(Caller,Token)
			if Token[2] then
				local Damage = 10
				if Token[3] and tonumber(Token[3]) then
					Damage = tonumber(Token[3])
				end
				local CharList = GetCharList(Caller,Token[2])
				for _,Char in pairs(CharList) do
					local Humanoid = GetHumanoid(Char)
					if Humanoid then
						Humanoid.Health = Humanoid.Health - Damage
					end
				end
			end
		end,
	},
	{
		["Name"] = "Fling",
		["Commands"] = {"fling"},
		["Level"] = 3,
		["Args"] = {
			{
				["Name"] = "Target",
				["Type"] = "target",
				["Default"] = nil,
			},
			{
				["Name"] = "Speed",
				["Type"] = "number",
				["Default"] = 300,
			},
		},
		["Description"] = "Flings player off in a random direction with default speed 300",
		["Function"] = function(Caller,Token)
			if Token[2] then
				local CharList = GetCharList(Caller,Token[2])
				for _,Char in pairs(CharList) do
					coroutine.resume(coroutine.create(function()
						local Humanoid = GetHumanoid(Char)
						local Torso = GetTorso(Char)
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
	{
		["Name"] = "Float Relative",
		["Commands"] = {"float","relfloat","hover","relhover"},
		["Level"] = 3,
		["Args"] = {
			{
				["Name"] = "Target",
				["Type"] = "target",
				["Default"] = nil,
			},
			{
				["Name"] = "Height",
				["Type"] = "number",
				["Default"] = 5,
			},
		},
		["Description"] = "Causes player to float at the desired height above their current height",
		["Function"] = function(Caller,Token)
			if Token[2] then
				local Height = 5
				if Token[3] and tonumber(Token[3]) then
					Height = tonumber(Token[3])
				end
				local CharList = GetCharList(Caller,Token[2])
				for _,Char in pairs(CharList) do
					local Humanoid = GetHumanoid(Char)
					local Torso = GetTorso(Char)
					if Humanoid and Torso then
						local Force = Torso:FindFirstChild("FloatForce")
						if not Force then
							Force = Instance.new("BodyPosition")
							Force.Name = "FloatForce"
							Force.MaxForce = Vector3.new(0,100000,0)
						end
						Force.Position = Vector3.new(0,(Torso.Position.y + Height),0)
						Force.Parent = Torso
					end
				end
			end
		end,
	},
	{
		["Name"] = "Float Absolute",
		["Commands"] = {"absfloat","abshover"},
		["Level"] = 3,
		["Args"] = {
			{
				["Name"] = "Target",
				["Type"] = "target",
				["Default"] = nil,
			},
			{
				["Name"] = "Height",
				["Type"] = "number",
				["Default"] = 100,
			},
		},
		["Description"] = "Causes player to float at the desired workspace height",
		["Function"] = function(Caller,Token)
			if Token[2] then
				local Height = 100
				if Token[3] and tonumber(Token[3]) then
					Height = tonumber(Token[3])
				end
				local CharList = GetCharList(Caller,Token[2])
				for _,Char in pairs(CharList) do
					local Humanoid = GetHumanoid(Char)
					local Torso = GetTorso(Char)
					if Humanoid and Torso then
						local Force = Torso:FindFirstChild("FloatForce")
						if not Force then
							Force = Instance.new("BodyPosition")
							Force.Name = "FloatForce"
							Force.MaxForce = Vector3.new(0,100000,0)
						end
						Force.Position = Vector3.new(0,Height,0)
						Force.Parent = Torso
					end
				end
			end
		end,
	},
	{
		["Name"] = "Unfloat",
		["Commands"] = {"unfloat","unhover","drop"},
		["Level"] = 3,
		["Args"] = {
			{
				["Name"] = "Target",
				["Type"] = "target",
				["Default"] = nil,
			},
		},
		["Description"] = "Undoes float command",
		["Function"] = function(Caller,Token)
			if Token[2] then
				local CharList = GetCharList(Caller,Token[2])
				for _,Char in pairs(CharList) do
					local Humanoid = GetHumanoid(Char)
					local Torso = GetTorso(Char)
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
	{
		["Name"] = "Rocket",
		["Commands"] = {"rocket","launch"},
		["Level"] = 3,
		["Args"] = {
			{
				["Name"] = "Target",
				["Type"] = "target",
				["Default"] = nil,
			},
		},
		["Description"] = "Launches player into the air, where they then explode",
		["Function"] = function(Caller,Token)
			if Token[2] then
				local CharList = GetCharList(Caller,Token[2])
				for _,Char in pairs(CharList) do
					coroutine.resume(coroutine.create(function()
						local Humanoid = GetHumanoid(Char)
						local Torso = GetTorso(Char)
						if Humanoid and Torso then
							local Mass = GetTotalMass(Char)
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
	{
		["Name"] = "Forcefield",
		["Commands"] = {"ff","forcefield","shield","protect"},
		["Level"] = 3,
		["Args"] = {
			{
				["Name"] = "Target",
				["Type"] = "target",
				["Default"] = nil,
			},
		},
		["Description"] = "Gives player a forcefield",
		["Function"] = function(Caller,Token)
			if Token[2] then
				local CharList = GetCharList(Caller,Token[2])
				for _,Char in pairs(CharList) do
					if not Char:FindFirstChild("ForceField") then
						Instance.new("ForceField",Char)
					end
				end
			end
		end,
	},
	{
		["Name"] = "Remove Forcefield",
		["Commands"] = {"unff","unforcefield","unshield","unprotect"},
		["Level"] = 3,
		["Args"] = {
			{
				["Name"] = "Target",
				["Type"] = "target",
				["Default"] = nil,
			},
		},
		["Description"] = "Removes forcefield from player",
		["Function"] = function(Caller,Token)
			if Token[2] then
				local CharList = GetCharList(Caller,Token[2])
				for _,Char in pairs(CharList) do
					local ForceField = Char:FindFirstChild("ForceField")
					if ForceField then
						ForceField:destroy()
					end
				end
			end
		end,
	},
	{
		["Name"] = "Walkspeed",
		["Commands"] = {"speed","walkspeed","resetspeed"},
		["Level"] = 3,
		["Args"] = {
			{
				["Name"] = "Target",
				["Type"] = "target",
				["Default"] = nil,
			},
			{
				["Name"] = "Speed",
				["Type"] = "number",
				["Default"] = 16,
			},
		},
		["Description"] = "Changes players walkspeed in studs per second",
		["Function"] = function(Caller,Token)
			if Token[2] then
				local Speed = 16
				if Token[3] and tonumber(Token[3]) then
					Speed = tonumber(Token[3])
				end
				local CharList = GetCharList(Caller,Token[2])
				for _,Char in pairs(CharList) do
					local Humanoid = GetHumanoid(Char)
					if Humanoid then
						Humanoid.WalkSpeed = tonumber(Token[3])
					end
				end
			end
		end,
	},
	{
		["Name"] = "Kick",
		["Commands"] = {"kick"},
		["Level"] = 2,
		["Args"] = {
			{
				["Name"] = "Target",
				["Type"] = "target",
				["Default"] = nil,
			},
			{
				["Name"] = "Message",
				["Type"] = "string",
				["Default"] = nil,
			},
		},
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
				local PlayerList = GetPlayerList(Caller,Token[2])
				for _,Player in pairs(PlayerList) do
					if Message then
						Player:Kick(Message)
					else
						Player:Kick()
					end
				end
			end
		end,
	},
	{
		["Name"] = "Server Ban",
		["Commands"] = {"ban","tban","serverban"},
		["Level"] = 2,
		["Args"] = {
			{
				["Name"] = "Target",
				["Type"] = "target",
				["Default"] = nil,
			},
			{
				["Name"] = "Message",
				["Type"] = "string",
				["Default"] = nil,
			},
		},
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
				local PlayerList = GetPlayerList(Caller,Token[2])
				for _,Player in pairs(PlayerList) do
					table.insert(ScriptBanList,Player.Name)
					if Message then
						Player:Kick(Message)
					else
						Player:Kick()
					end
				end
			end
		end,
	},
	{
		["Name"] = "Global Ban",
		["Commands"] = {"pban","globalban"},
		["Level"] = 1,
		["Args"] = {
			{
				["Name"] = "Target",
				["Type"] = "target",
				["Default"] = nil,
			},
			{
				["Name"] = "Days",
				["Type"] = "number",
				["Default"] = 30,
			},
			{
				["Name"] = "Reason",
				["Type"] = "string",
				["Default"] = nil,
			}
		},
		["Description"] = "Kicks player and adds them to your Trello banlist if that's set up",
		["Function"] = function(Caller,Token)
			if Token[2] then
				local Reason = nil
				local Days = 30 --Ban days
				if Token[3] then
					Days = tonumber(Token[3])
				end
				local EndTime = math.ceil(os.time() + (Days * 86400))
				if Token[4] then
					Reason = ""
					for i=4,#Token do
						Reason = Reason..Token[i].." "
					end
				end
				
				local PlayerList = GetPlayerList(Caller,Token[2])
				for _,Player in pairs(PlayerList) do
					local CardName = Player.Name..","..Player.userId
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
					
					Player:Kick(Message)
				end
			end
		end,
	},
	{
		["Name"] = "Teleport",
		["Commands"] = {"tp","tele","teleport"},
		["Level"] = 3,
		["Args"] = {
			{
				["Name"] = "Target",
				["Type"] = "target",
				["Default"] = nil,
			},
			{
				["Name"] = "Player",
				["Type"] = "string",
				["Default"] = nil,
			},
		},
		["Description"] = "Teleports player1 to player2",
		["Function"] = function(Caller,Token)
			if Token[2] and Token[3] then
				local CharList1 = GetCharList(Caller,Token[2])
				local CharList2 = GetCharList(Caller,Token[3])
				if #CharList1 > 0 and #CharList2 == 1 then
					--Get target torso cframe
					local TargetCF
					local TargetTorso = GetTorso(CharList2[1])
					if TargetTorso then
						TargetCF = TargetTorso.CFrame
					end
					if TargetCF then
						--Teleport all of List1 to there
						for _,Char in pairs(CharList1) do
							local Torso = GetTorso(Char)
							if Torso then
								Torso.CFrame = TargetCF + Vector3.new(math.random(-20,20)/10,0,math.random(-20,20)/10)
							end
						end
					end
				end
			end
		end,
	},
	{
		["Name"] = "Teleport To",
		["Commands"] = {"to","teleto","teleportto"},
		["Level"] = 3,
		["Args"] = {
			{
				["Name"] = "Target",
				["Type"] = "target",
				["Default"] = nil,
			},
		},
		["Description"] = "Teleports speaker to player",
		["Function"] = function(Caller,Token)
			if Token[2] then
				local CharList = GetCharList(Caller,Token[2])
				for _,Char in pairs(CharList) do
					--Get target torso cframe
					local TargetCF
					local TargetTorso = GetTorso(Char)
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
	{
		["Name"] = "Scale Character",
		["Commands"] = {"resize","size","scale"},
		["Level"] = 3,
		["Args"] = {
			{
				["Name"] = "Target",
				["Type"] = "target",
				["Default"] = nil,
			},
			{
				["Name"] = "Scale",
				["Type"] = "number",
				["Default"] = 1,
			},
		},
		["Description"] = "Resizes players character to scale, 1 being normal (R15 only)",
		["Function"] = function(Caller,Token)
			if Token[2] and Token[3] and tonumber(Token[3]) then
				local CharList = GetCharList(Caller,Token[2])
				for _,Char in pairs(CharList) do
					local Humanoid = GetHumanoid(Char)
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
	{
		["Name"] = "Light",
		["Commands"] = {"light","brighten"},
		["Level"] = 3,
		["Args"] = {
			{
				["Name"] = "Target",
				["Type"] = "target",
				["Default"] = nil,
			},
			{
				["Name"] = "Range",
				["Type"] = "number",
				["Default"] = 8,
			},
			{
				["Name"] = "Brightness",
				["Type"] = "number",
				["Default"] = 1,
			},
		},
		["Description"] = "Adds a pointlight to players character",
		["Function"] = function(Caller,Token)
			if Token[2] then
				local Range = 8
				local Brightness = 1
				if Token[3] and tonumber(Token[3]) then
					Range = tonumber(Token[3])
				end
				if Token[4] and tonumber(Token[4]) then
					Brightness = tonumber(Token[4])
				end
				if Range < 0 then
					Notify(Caller,"Using minimum range of 0",Color3.fromRGB(255,170,0))
					Range = 0
				elseif Range > 60 then
					Notify(Caller,"Using maximum range of 60",Color3.fromRGB(255,170,0))
					Range = 60
				end
				if Brightness < 0 then
					Notify(Caller,"Using minimum brightness of 0",Color3.fromRGB(255,170,0))
					Brightness = 0
				end
				local CharList = GetCharList(Caller,Token[2])
				for _,Char in pairs(CharList) do
					local Torso = GetTorso(Char)
					if Torso then
						local Light = Torso:FindFirstChild("CommandLight")
						if not Light then
							Light = Instance.new("PointLight",Torso)
							Light.Name = "CommandLight"
						end
						Light.Range = Range
						Light.Brightness = Brightness
					end
				end
			end
		end,
	},
	{
		["Name"] = "Unlight",
		["Commands"] = {"unlight","darken","unbrighten"},
		["Level"] = 3,
		["Args"] = {
			{
				["Name"] = "Target",
				["Type"] = "target",
				["Default"] = nil,
			},
		},
		["Description"] = "Undoes light command",
		["Function"] = function(Caller,Token)
			if Token[2] then
				local CharList = GetCharList(Caller,Token[2])
				for _,Char in pairs(CharList) do
					local Torso = GetTorso(Char)
					if Torso then
						local Light = Torso:FindFirstChild("CommandLight")
						if Light then
							Light:destroy()
						end
					end
				end
			end
		end,
	},
	{
		["Name"] = "Invisible",
		["Commands"] = {"invisible","hide","ghost"},
		["Level"] = 3,
		["Args"] = {
			{
				["Name"] = "Target",
				["Type"] = "target",
				["Default"] = nil,
			},
		},
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
				local CharList = GetCharList(Caller,Token[2])
				for _,Char in pairs(CharList) do
					Invisible(Char)
					Char.Head.Face.Transparency = 1
				end
			end
		end,
	},
	{
		["Name"] = "Visible",
		["Commands"] = {"visible","unhide","unghost"},
		["Level"] = 3,
		["Args"] = {
			{
				["Name"] = "Target",
				["Type"] = "target",
				["Default"] = nil,
			},
		},
		["Description"] = "Undoes invisible command",
		["Function"] = function(Caller,Token)
			local function Visible(Item)
				if Item:IsA("BasePart") or Item.ClassName == "Decal" then
					if Item.Name ~= "HumanoidRootPart" then
						Item.Transparency = 0
					end
				end
				local Stuff = Item:GetChildren()
				for i=1,#Stuff do
					Visible(Stuff[i])
				end
			end
			if Token[2] then
				local CharList = GetCharList(Caller,Token[2])
				for _,Char in pairs(CharList) do
					Visible(Char)
					Char.Head.Face.Transparency = 0
				end
			end
		end,
	},
	{
		["Name"] = "Fake Name",
		["Commands"] = {"name","rename","fakename","alias"},
		["Level"] = 3,
		["Args"] = {
			{
				["Name"] = "Target",
				["Type"] = "target",
				["Default"] = nil,
			},
			{
				["Name"] = "Name",
				["Type"] = "string",
				["Default"] = nil,
			},
		},
		["Description"] = "Gives player a new fake name",
		["Function"] = function(Caller,Token)
			if Token[2] and Token[3] then
				local CharList = GetCharList(Caller,Token[2])
				for _,Char in pairs(CharList) do
					local Head = Char:FindFirstChild("Head")
					if Head then
						local Part = Char:GetChildren()
						for x=1,#Part do
							if Part[x]:FindFirstChild("NameTag") then
								Head.Transparency = 0
								Part[x]:Destroy()
							end
						end
						local Model = Instance.new("Model",Char)
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
	{
		["Name"] = "Unname",
		["Commands"] = {"unname","unalias"},
		["Level"] = 3,
		["Args"] = {
			{
				["Name"] = "Target",
				["Type"] = "target",
				["Default"] = nil,
			},
		},
		["Description"] = "Undoes fake name command",
		["Function"] = function(Caller,Token)
			if Token[2] then
				local CharList = GetCharList(Caller,Token[2])
				for _,Char in pairs(CharList) do
					local Head = Char:FindFirstChild("Head")
					if Head then
						local Part = Char:GetChildren()
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
	{
		["Name"] = "Disguise", --Broken
		["Commands"] = {"char","dress","disguise","cosplay"},
		["Level"] = 3,
		["Args"] = {
			{
				["Name"] = "Target",
				["Type"] = "target",
				["Default"] = nil,
			},
			{
				["Name"] = "Name",
				["Type"] = "string",
				["Default"] = nil,
			},
		},
		["Description"] = "Changes player1s character to player2s (Player2 doesn't have to be in the server)",
		["Function"] = function(Caller,Token)
			if Token[2] and Token[3] then
				local Id = game.Players:GetUserIdFromNameAsync(Token[3])
				if Id then
					local PlayerList = GetPlayerList(Caller,Token[2])
					for _,Player in pairs(PlayerList) do
						Player.CharacterAppearance = "http://www.roblox.com/asset/CharacterFetch.ashx?userId="..Id
						Player:LoadCharacter()
					end
				end
			end
		end,
	},
	{
		["Name"] = "Undisguise",
		["Commands"] = {"unchar","undiguise","uncosplay"},
		["Level"] = 3,
		["Args"] = {
			{
				["Name"] = "Target",
				["Type"] = "target",
				["Default"] = nil,
			},
		},
		["Description"] = "Resets char command and makes player look like their own avatar",
		["Function"] = function(Caller,Token)
			if Token[2] and Token[3] then
				local PlayerList = GetPlayerList(Caller,Token[2])
				for _,Player in pairs(PlayerList) do
					local Id = game.Players:GetUserIdFromNameAsync(Player.Name)
					if Id then
						Player.CharacterAppearance = "http://www.roblox.com/asset/CharacterFetch.ashx?userId="..Id
						Player:LoadCharacter()
					end
				end
			end
		end,
	},
	{
		["Name"] = "Gear",
		["Commands"] = {"gear","givegear"},
		["Level"] = 3,
		["Args"] = {
			{
				["Name"] = "Target",
				["Type"] = "target",
				["Default"] = nil,
			},
			{
				["Name"] = "ID",
				["Type"] = "string", --Primarily number, but string has a longer textfield
				["Default"] = nil,
			},
		},
		["Description"] = "Gives player gear with specified ID",
		["Function"] = function(Caller,Token)
			if Token[2] and Token[3] and tonumber(Token[3]) then
				local PlayerList = GetPlayerList(Caller,Token[2])
				for _,Player in pairs(PlayerList) do
					if Player:FindFirstChild("Backpack") then
						local Obj = game:service("InsertService"):LoadAsset(tonumber(Token[3]))
						for Key,Value in pairs(Obj:children()) do
							if Value:IsA("Tool") or Value:IsA("HopperBin") then
								Value.Parent = Player.Backpack
							end
						end
						Obj:Destroy()
					end
				end
			end
		end,
	},
	{
		["Name"] = "FOV",
		["Commands"] = {"fov","setfov","resetfov"},
		["Level"] = 3,
		["Args"] = {
			{
				["Name"] = "Target",
				["Type"] = "target",
				["Default"] = nil,
			},
			{
				["Name"] = "Angle",
				["Type"] = "number",
				["Default"] = 70,
			},
		},
		["Description"] = "Changes the field of view angle for player",
		["Function"] = function(Caller,Token)
			if Token[2] then
				local Angle = 70
				if Token[3] and tonumber(Token[3]) then
					Angle = tonumber(Token[3])
					if Angle < 1 then
						Notify(Caller,"Using minimum FOV of 1",Color3.fromRGB(255,170,0))
						Angle = 1
					elseif Angle > 120 then
						Notify(Caller,"Using maximum FOV of 120",Color3.fromRGB(255,170,0))
						Angle = 120
					end
				end
				local PlayerList = GetPlayerList(Caller,Token[2])
				for _,Player in pairs(PlayerList) do
					if Angle >= 1 and Angle <= 120 then
						local fovScript = script.LocalScripts.FOV:Clone()
						fovScript.FOVSetting.Value = Angle
						fovScript.Parent = Player.Backpack
					end
				end
			end
		end,
	},
	{
		["Name"] = "Build Tools",
		["Commands"] = {"btools","buildtools"},
		["Level"] = 3,
		["Args"] = {
			{
				["Name"] = "Target",
				["Type"] = "target",
				["Default"] = nil,
			},
		},
		["Description"] = "Gives player classic build tools",
		["Function"] = function(Caller,Token)
			if Token[2] then
				local PlayerList = GetPlayerList(Caller,Token[2])
				for _,Player in pairs(PlayerList) do
					if Player:FindFirstChild("Backpack") then
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
							Tool[x].Parent = Player.Backpack
						end
					end
				end
			end
		end,
	},
	{
		["Name"] = "Fly",
		["Commands"] = {"fly"},
		["Level"] = 3,
		["Args"] = {
			{
				["Name"] = "Target",
				["Type"] = "target",
				["Default"] = nil,
			},
		},
		["Description"] = "Lets player fly around in the air",
		["Function"] = function(Caller,Token)
			if Token[2] then
				local PlayerList = GetPlayerList(Caller,Token[2])
				for _,Player in pairs(PlayerList) do
					if not Player.Backpack:FindFirstChild("Fly") then
						--Notify(Player,"Press [X] to toggle flight")
						local FlyScript = script.LocalScripts.Fly:Clone()
						FlyScript.Parent = Player.Backpack
					end
				end
			end
		end,
	},
	{
		["Name"] = "Land",
		["Commands"] = {"land","unfly"},
		["Level"] = 3,
		["Args"] = {
			{
				["Name"] = "Target",
				["Type"] = "target",
				["Default"] = nil,
			},
		},
		["Description"] = "Undoes fly command",
		["Function"] = function(Caller,Token)
			if Token[2] then
				local PlayerList = GetPlayerList(Caller,Token[2])
				for _,Player in pairs(PlayerList) do
					if Player.Backpack:FindFirstChild("Fly") then
						Player.Backpack.Fly:destroy()
					end
					--local Torso = GetPlayerTorso(Player)
					local Char = Player.Character
					if Char and Char:FindFirstChild("HumanoidRootPart") then
						if Char.HumanoidRootPart:FindFirstChild("FlyGyro") then
							Char.HumanoidRootPart.FlyGyro:destroy()
						end
						if Char.HumanoidRootPart:FindFirstChild("FlyVel") then
							Char.HumanoidRootPart.FlyVel:destroy()
						end
					end
				end
			end
		end,
	},
	{
		["Name"] = "Noclip",
		["Commands"] = {"noclip"},
		["Level"] = 3,
		["Args"] = {
			{
				["Name"] = "Target",
				["Type"] = "target",
				["Default"] = nil,
			},
		},
		["Description"] = "Lets player fly and move through walls",
		["Function"] = function(Caller,Token)
			if Token[2] then
				local PlayerList = GetPlayerList(Caller,Token[2])
				for _,Player in pairs(PlayerList) do
					if not Player.Backpack:FindFirstChild("NoClip") then
						local ClipScript = script.LocalScripts.NoClip:Clone()
						ClipScript.Parent = Player.Backpack
					end
				end
			end
		end,
	},
	{
		["Name"] = "Clip", --Broken, player has to respawn
		["Commands"] = {"clip"},
		["Level"] = 3,
		["Args"] = {
			{
				["Name"] = "Target",
				["Type"] = "target",
				["Default"] = nil,
			},
		},
		["Description"] = "Undoes noclip command",
		["Function"] = function(Caller,Token)
			if Token[2] then
				local PlayerList = GetPlayerList(Caller,Token[2])
				for _,Player in pairs(PlayerList) do
					if not Player.Backpack:FindFirstChild("Clip") then
						local ClipScript = script.LocalScripts.Clip:Clone()
						ClipScript.Parent = Player.Backpack
					end
					local Torso = GetPlayerTorso(Player)
					if Torso then
						local Humanoid = GetPlayerHumanoid(Player)
						if Humanoid then
							Torso.Anchored = false
							Humanoid.PlatformStand = false
						end
					end
				end
			end
		end,
	},
	{
		["Name"] = "Message",
		["Commands"] = {"m","msg","message","shout"},
		["Level"] = 3,
		["Args"] = {
			{
				["Name"] = "Message",
				["Type"] = "string",
				["Default"] = nil,
			},
		},
		["Description"] = "Displays a message to all players in the server",
		["Function"] = function(Caller,Token)
			if Token[2] then
				local Message = Token[2]
				for i=3,#Token do
					Message = Message.." "..Token[i]
				end
				local List = GetPlayerList(Caller,"all")
				for _,Player in pairs(List) do
					Notify(Player,Message)
				end
			end
		end,
	},
	{
		["Name"] = "Music",
		["Commands"] = {"music","sound","tunes"},
		["Level"] = 3,
		["Args"] = {
			{
				["Name"] = "ID",
				["Type"] = "string", --Primarily number, but string has a longer textfield
				["Default"] = nil,
			},
			{
				["Name"] = "Pitch",
				["Type"] = "number",
				["Default"] = 1,
			},
			{
				["Name"] = "Volume",
				["Type"] = "number",
				["Default"] = 0.5,
			}
		},
		["Description"] = "Plays looped music with the desired properties. You can play an ID, off/stop, or one of these: ", --Expanded from table later on
		["Function"] = function(Caller,Token)
			if Token[2] then
				local Sound = game.Workspace:FindFirstChild("AdminMusic")
				local Id = string.lower(Token[2])
				if Id == "off" or Id == "stop" then
					if Sound then Sound:Stop() end
				else
					--Check MusicList for named Ids
					for Name,ListId in pairs(MusicList) do
						if Id:find(Name) then
							Id = ListId
							break
						end
					end
					
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
	{
		["Name"] = "Ambient",
		["Commands"] = {"ambient"},
		["Level"] = 3,
		["Args"] = {
			{
				["Name"] = "Red",
				["Type"] = "number",
				["Default"] = "0.0",
			},
			{
				["Name"] = "Green",
				["Type"] = "number",
				["Default"] = "0.0",
			},
			{
				["Name"] = "Blue",
				["Type"] = "number",
				["Default"] = "0.0",
			}
		},
		["Description"] = "Sets lighting ambient to input 0-1",
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
	{
		["Name"] = "Time",
		["Commands"] = {"time","settime","timeofday"},
		["Level"] = 3,
		["Args"] = {
			{
				["Name"] = "Time",
				["Type"] = "number",
				["Default"] = 12,
			},
		},
		["Description"] = "Set time of day to num",
		["Function"] = function(Caller,Token)
			if Token[2] then
				game.Lighting.TimeOfDay = Token[2]
			end
		end,
	},
	{
		["Name"] = "Set CoreGui Enabled",
		["Commands"] = {"setcge","cge","setguis"},
		["Level"] = 3,
		["Args"] = {
			{
				["Name"] = "Target",
				["Type"] = "target",
				["Default"] = nil,
			},
			{
				["Name"] = "Enum",
				["Type"] = "string",
				["Default"] = "All",
			},
			{
				["Name"] = "Enabled",
				["Type"] = "boolean",
				["Default"] = "false",
			}
		},
		["Description"] = "Toggles the specified CoreGui type for player. Options: PlayerList Health Backpack Chat All",
		["Function"] = function(Caller,Token)
			--By microk
			local enumTypes = Enum.CoreGuiType:GetEnumItems()
			local commandScript = script.LocalScripts.SetCGE
			if Token[2] and Token[3] and Token[4] then
				local isEnum = false
				local enumType
				local boolValue
				if string.lower(Token[4]) == "true" or string.lower(Token[4]) == "false" or Token[4] == "0" or Token[4] == "1" or string.lower(Token[4]) == "on" or string.lower(Token[4]) == "off" or string.lower(Token[4]) == "hide" or string.lower(Token[4]) == "show" then
					if string.lower(Token[4]) == "true" or Token[4] == "1" or string.lower(Token[4]) == "on" or string.lower(Token[4]) == "show" then
						boolValue = true
					else
						boolValue = false
					end
				else
					return
				end
				for i=1,#enumTypes do
					if string.lower(Token[3]) == string.lower(enumTypes[i].Name) or tonumber(Token[3]) == enumTypes[i].Value then
						isEnum = true
						enumType = enumTypes[i]
					end
				end
				if isEnum == true then
					local PlayerList = GetPlayerList(Caller,Token[2])
					for _,Player in pairs(PlayerList) do
						local scriptClone = commandScript:Clone()
						scriptClone.EnumValue.Value = enumType.Value
						scriptClone.BoolValue.Value = boolValue
						scriptClone.Disabled = false
						scriptClone.Parent = Player.Backpack
					end
				end
			end
		end,
	},
	{
		["Name"] = "Freecam",
		["Commands"] = {"freecam"},
		["Level"] = 3,
		["Args"] = {
			{
				["Name"] = "Target",
				["Type"] = "target",
				["Default"] = nil,
			},
		},
		["Description"] = "Gives player freecam. Click to teleport. Insert to stop.",
		["Function"] = function(Caller,Token)
			if Token[2] then
				local PlayerList = GetPlayerList(Caller,Token[2])
				for _,Player in pairs(PlayerList) do
					local CamScript = script.LocalScripts.Freecam:Clone()
					CamScript.Parent = Player.Backpack
					CamScript.Disabled = false
				end
			end
		end,
	},
	{
		["Name"] = "Fix Camera",
		["Commands"] = {"fixcam","resetcam"},
		["Level"] = 3,
		["Args"] = {
			{
				["Name"] = "Target",
				["Type"] = "target",
				["Default"] = nil,
			},
		},
		["Description"] = "Resets anything done to players camera",
		["Function"] = function(Caller,Token)
			if Token[2] then
				local PlayerList = GetPlayerList(Caller,Token[2])
				for _,Player in pairs(PlayerList) do
					local resetScript = script.LocalScripts.Resetcam:Clone()
					resetScript.Parent = Player.Backpack
					resetScript.Disabled = false
				end
			end
		end,
	},
	{
		["Name"] = "Hide Guis",
		["Commands"] = {"hidegui","hideguis"},
		["Level"] = 3,
		["Args"] = {
			{
				["Name"] = "Target",
				["Type"] = "target",
				["Default"] = nil,
			},
		},
		["Description"] = "Hides as many guis as possible for player",
		["Function"] = function(Caller,Token)
			if Token[2] then
				local PlayerList = GetPlayerList(Caller,Token[2])
				for _,Player in pairs(PlayerList) do
					local GuiScript = script.LocalScripts.HideGuis:Clone()
					GuiScript.Parent = Player.Backpack
				end
			end
		end,
	},
	{
		["Name"] = "Clean Server",
		["Commands"] = {"clean","clear","cleanserver"},
		["Level"] = 3,
		["Args"] = {},
		["Description"] = "Cleans up any items/debris created with commands",
		["Function"] = function(Caller,Token)
			for i=1,#DebrisList do
				DebrisList[i]:Destroy()
			end
			DebrisList = {}
		end,
	},
	{
		["Name"] = "Shutdown Server",
		["Commands"] = {"shutdown","killserver"},
		["Level"] = 2,
		["Args"] = {
			{
				["Name"] = "Message",
				["Type"] = "string",
				["Default"] = nil,
			},
		},
		["Description"] = "Shuts down the current server with optional message",
		["Function"] = function(Caller,Token)
			--Just kick everyone forever until the server shuts down
			local Message = Token[2]
			if not Message then
				Message = "Server shut down via in-game command"
			end
			for _,Player in pairs(game.Players:GetChildren()) do
				Player:Kick(Message)
			end
			game.Players.PlayerAdded:connect(function(Player)
				Player:Kick(Message)
			end)
		end,
	},
	{
		["Name"] = "Wait",
		["Commands"] = {"wait"},
		["Level"] = 3,
		["Args"] = {
			{
				["Name"] = "Time",
				["Type"] = "number",
				["Default"] = nil,
			},
		},
		["Description"] = "Wait some time in seconds between multiple commands on the same line",
		["Function"] = function(Caller,Token)
			wait(tonumber(Token[2]))
		end,
	},
	{
		["Name"] = "Commands Gui",
		["Commands"] = {"cmds","commands"},
		["Level"] = 3,
		["Args"] = {},
		["Description"] = "Bring up commands gui",
		["Function"] = function(Caller,Token)
			if Caller:FindFirstChild("PlayerGui") then
				local Gui = Caller.PlayerGui:FindFirstChild("BasicCommands")
				if Gui then
					Gui.Events.Minimize:FireClient(Caller)
				end
			end
		end,
	},
}

--Add MusicList to :music description
--Find the music command
local MusicCommand
for _,Command in pairs(Commands) do
	if Command.Name == "Music" then
		MusicCommand = Command
		MusicCommand.Description = MusicCommand.Description.."\n"
		break
	end
end
--Make alphebetical list of choices
local MusicNames = {}
for Name,Id in pairs(MusicList) do
	table.insert(MusicNames,Name)
end
table.sort(MusicNames,function(a,b) return a < b end)
for _,Name in ipairs(MusicNames) do
	MusicCommand.Description = MusicCommand.Description.."\n"..Prefixes[1].."music "..Name
end

--Give gui and listen for commands
function NewAdmin(Player)
	while not Player:FindFirstChild("PlayerGui") do wait() end
	local Gui = CommandGui:Clone()
	Gui.Parent = Player.PlayerGui
	
	--Send gui command list without function code
	local CommandList = CopyTable(Commands)
	for _,Info in pairs(CommandList) do
		Info.Function = nil
	end
	Gui.Events.NewCommandList:FireClient(Player,Prefixes,CommandList)
	
	--Listen for commands
	Gui.Events.ExecuteCommand.OnServerEvent:connect(function(Player,Command,Token)
		GuiCommand(Player,Command,Token)
	end)
end

--Someone spoke
function Chat(Player,Message)
	local Level = AdminLevel(Player)
	local IsCommand = false
	for _,Prefix in pairs(Prefixes) do
		if Message:sub(1,string.len(Prefix)) == Prefix then
			IsCommand = true
			break
		end
	end
	if Level and IsCommand then
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
				--Find this command in the list
				local Found = false
				for _,Info in pairs(Commands) do
					for _,CommandName in pairs(Info.Commands) do
						if CommandName == Token[1] then
							--Execute command if theres permission
							if Level <= Info.Level then
								Info.Function(Player,Token)
							end
							Found = true
							break
						end
					end
					if Found then break end
				end
				if not Found then
					if Token[1]:len() > 1 then --Ignore stuff like :D
						Notify(Player,"Unknown command: "..Token[1],Color3.fromRGB(255,170,0))
					end
				end
			end
		end
	end
end

function GuiCommand(Player,Command,Token)
	local Level = AdminLevel(Player)
	for _,Info in pairs(Commands) do
		if Info.Name == Command then
			--Permission for this command?
			if Level and Level <= Info.Level then
				Info.Function(Player,Token) --Execute function
			end
			break
		end
	end
end

--Player joined
game.Players.PlayerAdded:connect(function(Player)
	--Monitor chat for commands
	Player.Chatted:connect(function(Message)
		Chat(Player,Message)
	end)
	--Check if admin (and give gui)
	local Level = AdminLevel(Player)
	if Level then
		NewAdmin(Player)
	end
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
	--Update guis about new player list
	UpdatePlayerLists()
	--Give notification gui
	while not Player:FindFirstChild("PlayerGui") do wait() end
	script.CommandNotifications:Clone().Parent = Player.PlayerGui
	if Level then
		Notify(Player,"You are a level "..Level.." admin!",Color3.new(0,1,0))
	end
end)

game.Players.PlayerRemoving:connect(function()
	--Update guis about new player list
	UpdatePlayerLists()
end)

--Sequential Stuff
--------

UpdatePlayerLists()

--Check trello banlist/adminlist every minute
local BanBoardID
if TrelloEnabled then
	BanBoardID = Trello:GetBoardID(TrelloBoardName)
end
function UpdateTrello()
	TrelloBanList = {}
	TrelloAdminList = {}
	
	local BanCards = Trello:GetCardsInList(BannedUserList)
	for _,Card in pairs(BanCards) do
		local CardInfo = Card.desc
		local Success,Message = pcall(function()
			CardInfo = HttpService:JSONDecode(CardInfo) --Reason, IssuedBy, Days, EndTime
		end)
		if not Success then
			CardInfo = {}
		end
		CardInfo.Name = Card.name
		
		--Convert Days to EndTime if needed
		if not CardInfo.EndTime and CardInfo.Days then
			local EndTime = math.ceil(os.time() + (tonumber(CardInfo.Days) * 86400))
			local Success,Message = pcall(function()
				local NewCardInfo = HttpService:JSONEncode(CopyTable(Card.desc))
				local CardId = Trello:GetCardID(CardInfo.name,TrelloBoardID)
				Trello:EditCard(CardId,Card.name,NewCardInfo,BannedUserList)
			end)
			if not Success then
				print("Error editing card: "..Message)
			end
		end
		--Ban still in effect?
		if CardInfo.EndTime and CardInfo.EndTime <= os.time() then
			--Delete this record
			local Success,Message = pcall(function()
				local CardID = Trello:GetCardID(Card.name,BanBoardID)
				Trello:DeleteCard(CardID)
			end)
		else
			table.insert(TrelloBanList,CardInfo)
		end
	end
	
	local AdminCards = Trello:GetCardsInList(AdminUserList)
	for _,Card in pairs(AdminCards) do
		local CardInfo = Card.desc
		local Success,Message = pcall(function()
			CardInfo = HttpService:JSONDecode(CardInfo) --Level
		end)
		if not Success then
			CardInfo = {}
		end
		CardInfo.Name = Card.name
		
		table.insert(TrelloAdminList,CardInfo)
	end
	
	for _,Player in pairs(game.Players:GetChildren()) do
		CheckBanned(Player) --Will kick them if banned
	end
end

if TrelloEnabled then
	while true do
		UpdateTrello()
		wait(60)
	end
end