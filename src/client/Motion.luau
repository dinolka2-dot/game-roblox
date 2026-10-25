-- One pose owner per character: spells and melee cannot accumulate C0 offsets.
local TweenService = game:GetService("TweenService")
local Motion = {}
local bases = setmetatable({}, {__mode="k"})
local active = setmetatable({}, {__mode="k"})
function Motion.stop(char)
    local state = active[char]
    if not state then return end
    active[char] = nil
    for motor, tween in state.tweens do
        tween:Cancel()
        if motor.Parent then motor.C0 = bases[motor] end
    end
end
function Motion.play(char, kind, duration, combo)
    Motion.stop(char)
    local state = {tweens={}}; active[char] = state
    local joints = {}
    for _, motor in char:GetDescendants() do
        if motor:IsA("Motor6D") and (motor.Name:find("Shoulder") or motor.Name:find("Hip") or motor.Name=="Waist" or motor.Name=="Neck") then
            bases[motor] = bases[motor] or motor.C0; table.insert(joints,motor)
        end
    end
    local function pose(release, time)
        if active[char] ~= state then return end
        for _, motor in joints do
            if not motor.Parent then continue end
            local name = motor.Name
            local rotation = CFrame.identity
            local side = if combo==2 then -1 else 1
            if kind=="spell" then
                if name:find("Shoulder") then rotation = CFrame.Angles(if release then -0.9 else -1.5,0,if name:find("Right") then 0.3 else -0.3)
                elseif name=="Waist" then rotation = CFrame.Angles(if release then -0.08 else 0.15,-0.2,0) end
            else
                if name:find("Right") and name:find("Shoulder") then rotation = CFrame.Angles(if release then -0.35 else -1.5,side*(if release then -0.9 else 0.6),if combo==3 then -0.3 else -0.65)
                elseif name:find("Left") and name:find("Shoulder") then rotation = CFrame.Angles(-0.4,0,0.35)
                elseif name=="Waist" then rotation = CFrame.Angles(if combo==3 then 0.2 else 0,side*(if release then -0.45 else 0.4),0)
                elseif name:find("Hip") then rotation = CFrame.Angles(if name:find("Right") then 0.12 else -0.12,0,0) end
            end
            if state.tweens[motor] then state.tweens[motor]:Cancel() end
            local tween = TweenService:Create(motor,TweenInfo.new(time,Enum.EasingStyle.Quad),{C0=bases[motor]*rotation})
            state.tweens[motor] = tween; tween:Play()
        end
    end
    pose(false,math.min(0.2,duration*0.4))
    task.delay(if kind=="spell" then duration*0.75 else 0.14,function() pose(true,0.12) end)
    task.delay(duration,function()
        if active[char] ~= state then return end
        for motor,tween in state.tweens do
            tween:Cancel()
            if motor.Parent then
                local restore = TweenService:Create(motor,TweenInfo.new(0.14),{C0=bases[motor]})
                state.tweens[motor] = restore; restore:Play()
            end
        end
        task.delay(0.16,function() if active[char]==state then Motion.stop(char) end end)
    end)
end
return Motion
