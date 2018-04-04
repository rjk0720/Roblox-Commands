local TweenService = game:GetService("TweenService")
local InputService = game:GetService("UserInputService")

local LocalPlayer = game.Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Gui = script.Parent
local Main = Gui:WaitForChild("Main")
local Events = Gui:WaitForChild("Events")

local MinSizeX = 500
local MinSizeY = 300

local CurrentCommand
local Commands = {}
local Prefixes = {}
local Players = {}
local Minimized = false
local ScreenPos = UDim2.new(0.5,0,0.5,0)
local Shift = false
local Ctrl = false
local Resizing = false
local SizeStartX
local SizeStartY
local MouseStartX
local MouseStartY

local TweenConfig = TweenInfo.new(
	0.5, --Time
	Enum.EasingStyle.Quad,
	Enum.EasingDirection.InOut
)

--Functions
--------

function ToggleMinimized(Value)
	if Value then
		Minimized = Value
	else
		Minimized = not Minimized
	end
	
	if Minimized then
		--Move off screen
		--ToDo: Move to top or bottom, whichever is closer
		ScreenPos = Main.Position
		local NewPos = UDim2.new(
			ScreenPos.X.Scale,
			ScreenPos.X.Offset,
			1.2 + (Main.Size.Y.Scale / 2), --Barely offscreen
			0
		)
		TweenService:Create(Main,TweenConfig,{["Position"] = NewPos}):Play()
	else
		--Move onto screen
		TweenService:Create(Main,TweenConfig,{["Position"] = ScreenPos}):Play()
	end
end

function SelectCommand(TargetEntry)
	if TargetEntry then
		CurrentCommand = TargetEntry.Name
	else
		CurrentCommand = nil
	end
	UpdateArguments()
	
	--Highlight entry, unhighlight others
	for _,Entry in pairs(Main.CommandList.ScrollingFrame:GetChildren()) do
		if Entry.ClassName == "Frame" then
			if Entry == TargetEntry then
				Entry.BackgroundTransparency = 0.5
			else
				Entry.BackgroundTransparency = 1
			end
		end
	end
	
	local Container = Main.Description.ScrollingFrame
	if TargetEntry then
		--Find command in Commands
		for _,Info in pairs(Commands) do
			if Info.Name == TargetEntry.Name then
				--Update description area
				local CommandText = ""
				for _,Command in pairs(Info.Commands) do
					CommandText = CommandText..Prefixes[1]..Command.." "
				end
				Container.Level.Text = Info.Level
				Container.LevelLabel.Visible = true
				Container.Level.Visible = true
				Container.Commands.Text = CommandText
				Container.Description.Text = Info.Description
			end
		end
	else
		--Nothing selected
		Container.LevelLabel.Visible = false
		Container.Level.Visible = false
		Container.Commands.Text = "Select a command"
		Container.Description.Text = ""
	end
	
	Container.CanvasSize = UDim2.new(0,0,0,
		Container.Description.Position.Y.Offset + Container.Description.TextBounds.Y
	)
end

function UpdatePlayerList()
	local Container = Main.PlayerList.ScrollingFrame
	
	--Remove players not on the list
	for _,Entry in pairs(Container:GetChildren()) do
		if Entry.ClassName == "Frame" and Entry.Name ~= "Template" then
			local Allowed = false
			for Player,Selected in pairs(Players) do
				if Player == Entry.Name then
					Allowed = true
				end
			end
			if not Allowed then
				Entry:destroy()
			end
		end
	end
	
	--Playerlist CanvasSize
	local Counter = 0
	for Player,Selected in pairs(Players) do
		Counter = Counter + 1
	end
	Container.CanvasSize = UDim2.new(0,0,0,Counter * Container.Template.Size.Y.Offset)
	
	--Check/uncheck boxes
	for Player,Selected in pairs(Players) do
		local Entry = Container:FindFirstChild(Player)
		--Create entry if there isnt one
		if not Entry then
			Entry = Container.Template:Clone()
			Entry.Name = Player
			Entry.Label.Text = Player
			Entry.Parent = Container
			Entry.Visible = true
			
			--Box clicked
			Entry.CheckBox.MouseButton1Click:connect(function()
				local NewSelected = not Players[Player]
				Players[Player] = NewSelected
				if NewSelected then
					Entry.CheckBox.Text = "X"
				else
					Entry.CheckBox.Text = ""
				end
			end)
		end
		
		if Selected then
			Entry.CheckBox.Text = "X"
		else
			Entry.CheckBox.Text = ""
		end
	end
end

function UpdateArguments()
	local Container = Main.Arguments.ScrollingFrame
	--Remove all current entries
	for _,Entry in pairs(Container:GetChildren()) do
		if Entry.ClassName == "Frame" and Entry.Name ~= "Template" then
			Entry:destroy()
		end
	end
	--Add new ones
	local Counter = 0
	--Find the right command info
	for _,Info in pairs(Commands) do
		if Info.Name == CurrentCommand then
			for _,Arg in ipairs(Info.Args) do
				if Arg.Type ~= "target" then
					local Entry = Container.Template:Clone()
					Entry.Name = Arg.Name
					Entry.Label.Text = Arg.Name
					if Arg.Default then
						Entry.TextBox.Text = Arg.Default
					end
					Entry.LayoutOrder = Counter
					if Arg.Type == "string" then
						--Stretch textbox
						Entry.TextBox.Size = UDim2.new(0.5,0,1,-4)
						Entry.Label.Position = UDim2.new(0.5,5,0,0)
					end
					Entry.Parent = Container
					Entry.Visible = true
					Counter = Counter + 1
				end
			end
			break
		end
	end
	if Counter > 0 then
		Container.NoArgs.Visible = false
	else
		Container.NoArgs.Visible = true
	end
	Container.CanvasSize = UDim2.new(0,0,0,Counter * Container.Template.Size.Y.Offset)
end

function UpdateFilter(Input)
	if Input then Input = string.lower(Input) end
	
	local Container = Main.CommandList.ScrollingFrame
	local Counter = 0
	for _,Info in pairs(Commands) do
		local Entry = Container:FindFirstChild(Info.Name)
		if Entry then
			local Allowed = false
			if not Input or Input == "" or Input == "search" then
				Allowed = true --Default, show everything
			else
				--Search command info for input
				if Info.Name:find(Input) then
					Allowed = true
				else
					for _,Command in pairs(Info.Commands) do
						if Command:find(Input) then
							Allowed = true
							break
						end
					end
				end
			end
			
			if Allowed then
				Entry.Visible = true
				Counter = Counter + 1
			else
				Entry.Visible = false
			end
		end
	end
	Container.CanvasSize = UDim2.new(0,0,0,Counter * 28)
end

function ExecuteCommand()
	if CurrentCommand then
		--Find the right command
		for _,Info in pairs(Commands) do
			if Info.Name == CurrentCommand then
				--This is the one
				--Assemble arguments
				local Token = {Info.Commands[1]} --Build a command string
				for _,Arg in ipairs(Info.Args) do
					if Arg.Type == "target" then
						--Players this is directed at
						local Str = ""
						for Player,Selected in pairs(Players) do
							if Selected then
								Str = Str..Player..","
							end
						end
						Str = Str:sub(1,string.len(Str)-1) --Remove last comma
						table.insert(Token,Str)
					else
						--Find TextBox for this one
						local Entry = Main.Arguments.ScrollingFrame:FindFirstChild(Arg.Name)
						if Entry then
							table.insert(Token,Entry.TextBox.Text)
						else
							--Gui error?
						end
					end
				end
				
				local TestStr = "Sending command:"
				for i=1,#Token do
					TestStr = TestStr.." "..tostring(Token[i])
				end
				print(TestStr)
				
				Events.ExecuteCommand:FireServer(CurrentCommand,Token)
				
				break
			end
		end
	end
end

--Events
--------

--Server sent a list of commands we can use
Events.NewCommandList.OnClientEvent:connect(function(PrefixList,CommandList)
	Prefixes = PrefixList
	Commands = CommandList
	
	--Only happens once so dont need to clear the container
	local Container = Main.CommandList.ScrollingFrame
	local Counter = 0
	for _,Info in pairs(Commands) do
		local Entry = Container.Template:Clone()
		Entry.Name = Info.Name
		Entry.Label.Text = Info.Name
		Entry.Command.Text = Prefixes[1]..Info.Commands[1]
		Entry.Parent = Container
		Entry.Command.Position = UDim2.new(0,Entry.Label.TextBounds.x + 10,0,0)
		Entry.Visible = true
		Counter = Counter + 1
		
		--Entry clicked
		Entry.Button.MouseButton1Click:connect(function()
			if Entry.BackgroundTransparency == 1 then
				SelectCommand(Entry)
			else
				SelectCommand() --Deselect
			end
		end)
	end
	Container.CanvasSize = UDim2.new(0,0,0,Counter * 28)
end)

--Server sent a new list of players in this server
Events.NewPlayerList.OnClientEvent:connect(function(PlayerList)
	local Temp = {} --PlayerName:Selected
	for _,PlayerName in pairs(PlayerList) do
		if Players[PlayerName] then
			Temp[PlayerName] = Players[PlayerName]
		else
			Temp[PlayerName] = false
		end
	end
	Players = Temp
	UpdatePlayerList()
end)

--Server says to toggle gui minimized
Events.Minimize.OnClientEvent:connect(function(Value)
	ToggleMinimized(Value)
end)

--Gui minimize button
Main.Close.MouseButton1Click:connect(function()
	ToggleMinimized()
end)

--Player quick selection buttons
Main.PlayerList.All.MouseButton1Click:connect(function()
	for Player,Selected in pairs(Players) do
		Players[Player] = true
	end
	UpdatePlayerList()
end)
Main.PlayerList.None.MouseButton1Click:connect(function()
	for Player,Selected in pairs(Players) do
		Players[Player] = false
	end
	UpdatePlayerList()
end)
Main.PlayerList.Others.MouseButton1Click:connect(function()
	for Player,Selected in pairs(Players) do
		if Player == LocalPlayer.Name then
			Players[Player] = false
		else
			Players[Player] = true
		end
	end
	UpdatePlayerList()
end)
Main.PlayerList.Me.MouseButton1Click:connect(function()
	for Player,Selected in pairs(Players) do
		if Player == LocalPlayer.Name then
			Players[Player] = true
		else
			Players[Player] = false
		end
	end
	UpdatePlayerList()
end)

--Search box changed
Main.Search.TextBox.Changed:connect(function(Property)
	if Property == "Text" then
		UpdateFilter(Main.Search.TextBox.Text)
	end
end)
Main.Search.TextBox.FocusLost:connect(function(EnterPressed)
	if Main.Search.TextBox.Text == "" then
		Main.Search.TextBox.Text = "Search"
	end
end)
Main.Search.Reset.MouseButton1Click:connect(function()
	Main.Search.TextBox.Text = "Search"
	UpdateFilter()
end)

--Execute button
Main.Button.Execute.MouseButton1Click:connect(function()
	ExecuteCommand()
end)

--Resize dragger
Main.Resize.MouseButton1Down:connect(function()
	SizeStartX = Main.Size.X.Offset
	SizeStartY = Main.Size.Y.Offset
	MouseStartX = Mouse.X
	MouseStartY = Mouse.Y
	Resizing = true
end)
Main.Resize.MouseButton1Up:connect(function()
	--Wont work if mouse is no longer over the button
	Resizing = false
end)
--[[
Main.InputEnded:connect(function()
	--Bad workaround for above event
	if Main.Size.X.Offset <= MinSizeX and Main.Size.Y.Offset <= MinSizeY then
		Resizing = false
	end
end)
--]]
Mouse.Move:connect(function()
	if Resizing then
		local MouseChangeX = Mouse.X - MouseStartX
		local MouseChangeY = Mouse.Y - MouseStartY
		--local SizeX = math.clamp((SizeStartX + MouseChangeX),MinSizeX,MinSizeX*10)
		--local SizeY = math.clamp((SizeStartY + MouseChangeY),MinSizeY,MinSizeY*10)
		local SizeX = SizeStartX + MouseChangeX
		local SizeY = SizeStartY + MouseChangeY
		Main.Size = UDim2.new(0,SizeX,0,SizeY)
	end
end)

--Keyboard input
InputService.InputBegan:connect(function(Input,GameProcessedEvent)
	if Input.KeyCode == Enum.KeyCode.LeftShift or Input.KeyCode == Enum.KeyCode.RightShift then
		Shift = true
	elseif Input.KeyCode == Enum.KeyCode.LeftControl or Input.KeyCode == Enum.KeyCode.RightControl then
		Ctrl = true
	elseif Input.KeyCode == Enum.KeyCode.Z then
		if Shift and Ctrl then
			ToggleMinimized()
		end
	end
end)

InputService.InputEnded:connect(function(Input,GameProcessedEvent)
	if Input.KeyCode == Enum.KeyCode.LeftShift or Input.KeyCode == Enum.KeyCode.RightShift then
		Shift = false
	elseif Input.KeyCode == Enum.KeyCode.LeftControl or Input.KeyCode == Enum.KeyCode.RightControl then
		Ctrl = false
	end
end)