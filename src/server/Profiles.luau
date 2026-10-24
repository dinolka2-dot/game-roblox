-- A failed load NEVER becomes a writable default profile.
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Eldoria")
local Rules = require(Shared.Rules)
local Settings = require(Shared.Config).Persistence
local store = DataStoreService:GetDataStore(Settings.Store)
local Profiles = {}
local sessions = {}
local token = game.JobId .. ":" .. HttpService:GenerateGUID(false)
-- Studio defaults to explicitly temporary profiles. Set the ModuleScript attribute
-- EnableStudioSaving=true only in a separately published test universe.
local temporary = RunService:IsStudio() and script:GetAttribute("EnableStudioSaving") ~= true
local function update(key, transform)
    local lastError
    for attempt = 1, Settings.Attempts do
        local ok, result = pcall(function() return store:UpdateAsync(key, transform) end)
        if ok then return true, result end
        lastError = result
        task.wait(attempt)
    end
    warn("ELDORIA DataStore request failed:", lastError)
    return false, nil
end
function Profiles.load(player)
    local key = "player_" .. player.UserId
    if temporary then
        sessions[player] = {data = Rules.new(), busy = false, closing = false}
        return sessions[player].data, true
    end
    local ok, record = update(key, function(old)
        if old ~= nil then
            if type(old) ~= "table" or not Rules.validate(old.data) then return nil end
            if old.owner ~= nil and old.owner ~= token and type(old.lease) == "number" and old.lease > os.time() then return nil end
        end
        return {data = if old then old.data else Rules.new(), owner = token, lease = os.time() + Settings.Lease}
    end)
    if not ok or not record or record.owner ~= token or not Rules.validate(record.data) then return nil, false end
    sessions[player] = {data = record.data, busy = false, closing = false, lastSave = os.clock()}
    return record.data, false
end
function Profiles.save(player, release)
    local session = sessions[player]
    if not session then return true end
    if release then session.closing = true end
    -- A leave waits for the in-flight autosave, then releases the latest profile.
    while session.busy do task.wait(0.05) end
    if sessions[player] ~= session then return true end
    session.busy = true
    if temporary then
        session.busy = false
        if release then sessions[player] = nil end
        return true
    end
    local snapshot = table.clone(session.data)
    local ok, record = update("player_" .. player.UserId, function(old)
        if type(old) ~= "table" or old.owner ~= token then return nil end
        return {data = snapshot, owner = if release then nil else token, lease = if release then 0 else os.time() + Settings.Lease}
    end)
    session.busy = false
    if ok and record and record.data and (release or record.owner == token) then
        session.lastSave = os.clock()
        if release then sessions[player] = nil end
        return true
    end
    -- Never continue playing past an uncertain lock lease.
    session.closing = true
    if player.Parent then player:Kick("Сохранение недоступно. Перезайдите через несколько минут.") end
    return false
end
function Profiles.isActive(player)
    local s = sessions[player]
    return s ~= nil and not s.closing
end
function Profiles.isTemporary() return temporary end
return Profiles
