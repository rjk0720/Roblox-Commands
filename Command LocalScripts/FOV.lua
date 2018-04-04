--Sets field of view in degrees

local Cam = game.Workspace.CurrentCamera
Cam.FieldOfView = script:WaitForChild("FOVSetting").Value

wait(0.1)
script:destroy()