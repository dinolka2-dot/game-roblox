--!strict
return table.freeze({
    Version = "0.5.0",
    AudioIds = {}, -- Populate with IDs after uploading assets/audio to the test experience owner.
    SafeRadius = 48,
    Attack = {Damage = 18, Range = 10, Cooldown = 0.5, Stamina = 10},
    Dodge = {Cost = 24, Cooldown = 1.6, Duration = 0.35},
    Spells = {
        fire = {Name = "Огонь", Damage = 32, Cost = 22, Cooldown = 2, Range = 65, Color = Color3.fromRGB(255, 120, 50)},
        frost = {Name = "Лёд", Damage = 20, Cost = 18, Cooldown = 2.5, Range = 55, Color = Color3.fromRGB(100, 220, 255)},
        storm = {Name = "Буря", Damage = 24, Cost = 28, Cooldown = 3, Range = 45, Color = Color3.fromRGB(200, 150, 255)},
    },
    Enemies = {
        shade = {Name = "Пепельный заклинатель", Health = 65, Damage = 15, Speed = 7, XP = 45, Gold = 16, Shards = 1, Respawn = 22, Aggro = 55},
        sentinel = {Name = "Осколочный страж", Health = 80, Damage = 12, Speed = 10, XP = 35, Gold = 12, Shards = 1, Respawn = 18, Aggro = 45},
        warden = {Name = "Хранитель разлома", Health = 400, Damage = 24, Speed = 8, XP = 200, Gold = 80, Shards = 5, Respawn = 60, Aggro = 55},
    },
    Persistence = {Store = "Eldoria_v1", Lease = 180, Autosave = 50, Attempts = 3},
})
