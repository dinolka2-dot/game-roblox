-- Audio files are supplied in assets/audio. Roblox requires their uploaded IDs.
local Shared=game:GetService("ReplicatedStorage"):WaitForChild("Eldoria")
local Config=require(Shared.Config)
local Book=require(Shared.Spellbook)
local Debris=game:GetService("Debris")
local function play(key,position)
    local id=Config.AudioIds[key]
    if type(id)~="number" or id<=0 then return end
    local camera=workspace.CurrentCamera
    if camera and position and (camera.CFrame.Position-position).Magnitude>90 then return end
    local anchor=Instance.new("Part"); anchor.Size=Vector3.one*0.1; anchor.Anchored=true
    anchor.Transparency=1; anchor.CanCollide=false; anchor.CanQuery=false; anchor.CanTouch=false
    anchor.Position=position or (camera and camera.CFrame.Position) or Vector3.zero; anchor.Parent=workspace
    local sound=Instance.new("Sound"); sound.SoundId="rbxassetid://"..id; sound.Volume=0.4
    sound.RollOffMinDistance=6; sound.RollOffMaxDistance=70; sound.Parent=anchor; sound:Play()
    Debris:AddItem(anchor,4)
end
Shared:WaitForChild("Remotes"):WaitForChild("Visual").OnClientEvent:Connect(function(kind,data)
    if kind=="hit" or kind=="spellHit" then play("hit",data.position)
    elseif kind=="spellRelease" then
        local spell=Book.Definitions[data.id]; if spell then play(spell.Rune,data.origin) end
    elseif kind=="death" then play("death",data.position)
    elseif kind=="ritual" then play("ritual",data.position)
    elseif kind=="meleePose" then
        local p=game:GetService("Players"):GetPlayerByUserId(data.user)
        local root=p and p.Character and p.Character:FindFirstChild("HumanoidRootPart")
        if root then play("sword",root.Position) end
    elseif kind=="parry" then play("parry",data.position) end
end)
