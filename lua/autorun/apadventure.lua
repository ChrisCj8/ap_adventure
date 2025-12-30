
apAdventure = apAdventure or {}

apAdventure.CfgVers = { 
    sv = "v1", 
    cl = "v1_1",
    gr = "old"
}

function apAdventure.ListToLookUp(list)
    local out = {}
    for k,v in ipairs(list) do
        out[v] = true
    end
    return out
end

function apAdventure.LookUpToList(tbl)
    local out = {}
    local i = 0
    for k,v in pairs(tbl) do
        i = i + 1
        out[i] = k
    end
    return out
end

if SERVER or file.Exists("apadventure/cfgsettings.lua","lcl") then
    include("apadventure/cfgsettings.lua")
end