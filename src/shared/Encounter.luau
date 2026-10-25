--!strict
local Encounter = {}
function Encounter.phase(health: number, maximum: number): number
    return if health <= maximum*0.5 then 2 else 1
end
function Encounter.pattern(sequence: number, phase: number): string
    if phase == 2 and sequence % 3 == 0 then return "barrage" end
    return if sequence % 2 == 0 then "cleave" else "shockwave"
end
function Encounter.contains(kind: string, x: number, z: number, radius: number, fx: number, fz: number): boolean
    local distance = math.sqrt(x*x+z*z)
    if kind == "shockwave" then return distance <= radius and distance >= 5 end
    if kind == "cleave" then
        local forward = x*fx+z*fz
        local lateral = math.abs(x*fz-z*fx)
        return forward >= 0 and forward <= radius and lateral <= 4.5
    end
    return distance <= radius
end
function Encounter.block(damage: number, stamina: number, age: number, facing: number)
    if facing < 0.2 or stamina < 10 then return damage, 0, false end
    if age >= 0 and age <= 0.28 then return 0, 6, true end
    return damage*0.3, 10, false
end
return table.freeze(Encounter)
