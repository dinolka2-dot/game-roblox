"""Exercise the actual Profiles module against a deterministic DataStore adapter.
This validates locking/failure logic, not Roblox's network or DataStore service.
"""
from pathlib import Path
import subprocess

root = Path(__file__).resolve().parents[1]
prefix = r'''
local function clone(value)
    if type(value) ~= "table" then return value end
    local copy = {}; for k, v in value do copy[k] = clone(v) end; return copy
end
local shared = {Rules = "rules", Config = "config"}
local records, failures, calls = {}, false, 0
local studio = false
local acquisitions = 0
local store = {}
function store:UpdateAsync(key, transform)
    calls += 1
    if failures then error("simulated service failure") end
    local nextValue = transform(clone(records[key]))
    if nextValue == nil then return nil end
    records[key] = clone(nextValue); return clone(nextValue)
end
local services = {
    DataStoreService = {GetDataStore = function()
        acquisitions += 1
        if studio then error("unpublished Studio must not acquire DataStore") end
        return store
    end},
    HttpService = {GenerateGUID = function() return "test-session" end},
    RunService = {IsStudio = function() return studio end},
    ReplicatedStorage = {WaitForChild = function() return shared end},
}
local game = {JobId = "server-one", GetService = function(_, name) return services[name] end}
local script = {GetAttribute = function() return nil end}
local task = {wait = function() end}
local warn = function() end
local Rules = (function()
'''
suffix = r'''
local function player(id)
    return {UserId = id, Parent = true, Kick = function(self) self.kicked = true; self.Parent = false end}
end
local count = 0
local function test(name, fn)
    local ok, err = pcall(fn); assert(ok, name .. ": " .. tostring(err))
    count += 1; print("PASS " .. name)
end
local Profiles = loadModule()
test("new profile persists and releases lock", function()
    local p = player(1); local data = Profiles.load(p)
    assert(data and records.player_1.owner ~= nil)
    data.gold = 88; assert(records.player_1.data.gold == 0)
    assert(Profiles.save(p, false)); assert(records.player_1.data.gold == 88)
    assert(Profiles.save(p, true)); assert(records.player_1.owner == nil)
    assert(not Profiles.isActive(p))
    local nextPlayer = player(1); assert(Profiles.load(nextPlayer).gold == 88)
    Profiles.save(nextPlayer, true)
end)
test("chapter extension survives save and reload", function()
    local p = player(9); local data = Profiles.load(p)
    data.quest = "complete"
    data.chapter = {seals = 5, caches = 1, boss = false, finished = false}
    assert(Profiles.save(p, true))
    local nextPlayer = player(9); local loaded = Profiles.load(nextPlayer)
    assert(loaded.chapter.seals == 5 and loaded.chapter.caches == 1 and not loaded.chapter.boss)
    Profiles.save(nextPlayer, true)
end)
test("foreign active lease refuses loading", function()
    records.player_2 = {data = Rules.new(), owner = "foreign", lease = os.time() + 180}
    local p = player(2); assert(Profiles.load(p) == nil); assert(not Profiles.isActive(p))
    assert(records.player_2.owner == "foreign")
end)
test("expired lease is recoverable", function()
    records.player_3 = {data = Rules.new(), owner = "foreign", lease = os.time() - 1}
    local p = player(3); assert(Profiles.load(p)); assert(records.player_3.owner ~= "foreign")
end)
test("corrupt or unknown schema never gets a default write", function()
    records.player_4 = {data = {version = 9}, owner = nil, lease = 0}
    assert(Profiles.load(player(4)) == nil); assert(records.player_4.data.version == 9)
end)
test("failed load cannot overwrite old data", function()
    failures = true
    local p = player(5); assert(Profiles.load(p) == nil)
    assert(records.player_5 == nil and not Profiles.isActive(p)); failures = false
end)
test("lost session ownership refuses writing", function()
    local p = player(6); local data = Profiles.load(p); data.gold = 70
    records.player_6.owner = "replacement-server"
    assert(not Profiles.save(p, false)); assert(p.kicked and not Profiles.isActive(p))
    assert(records.player_6.data.gold == 0 and records.player_6.owner == "replacement-server")
end)
test("failed autosave stops unsafe further gameplay", function()
    local p = player(7); assert(Profiles.load(p)); failures = true
    assert(not Profiles.save(p, false)); assert(p.kicked and not Profiles.isActive(p)); failures = false
end)
test("Studio temporary mode makes zero store requests", function()
    studio = true; local beforeAcquire = acquisitions; local temporaryProfiles = loadModule(); local before = calls
    local p = player(8); local data, temporary = temporaryProfiles.load(p)
    assert(temporary and data); data.gold = 100
    assert(temporaryProfiles.save(p, true)); assert(calls == before and acquisitions == beforeAcquire)
end)
print(count .. " profile adapter tests passed")
'''
source = prefix + (root / "src/shared/Rules.luau").read_text() + "\nend)()\n"
source += '''local require = function(name)
    if name == "rules" then return Rules end
    return {Persistence = {Store = "test", Lease = 180, Attempts = 3}}
end
local function loadModule()
'''
source += (root / "src/server/Profiles.luau").read_text() + "\nend\n" + suffix
output = root / "build/Profiles.adapter.luau"
output.parent.mkdir(exist_ok=True)
output.write_text(source)
subprocess.run([str(root / "tools/luau/luau"), str(output)], check=True)
