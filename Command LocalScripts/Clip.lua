--Undoes NoClip command if active

local Player = game.Players.LocalPlayer
local NoClipScript = script.Parent:FindFirstChild("NoClip")
if NoClipScript then
	NoClipScript:destroy()
end

wait()
script:destroy()