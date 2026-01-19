
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

local fssafe = {
    ["a"]=true,
    ["b"]=true,
    ["c"]=true,
    ["d"]=true,
    ["e"]=true,
    ["f"]=true,
    ["g"]=true,
    ["h"]=true,
    ["i"]=true,
    ["j"]=true,
    ["k"]=true,
    ["l"]=true,
    ["m"]=true,
    ["o"]=true,
    ["n"]=true,
    ["p"]=true,
    ["q"]=true,
    ["r"]=true,
    ["s"]=true,
    ["t"]=true,
    ["u"]=true,
    ["v"]=true,
    ["w"]=true,
    ["x"]=true,
    ["y"]=true,
    ["z"]=true,
    ["0"]=true,
    ["1"]=true,
    ["2"]=true,
    ["3"]=true,
    ["4"]=true,
    ["5"]=true,
    ["6"]=true,
    ["7"]=true,
    ["8"]=true,
    ["9"]=true,
    ["_"]=true,
    ["-"]=true,
}

function apAdventure.TestFileSystemSafe(text)
    for i = 1, #text do
        if !fssafe[text[i]] then return false end
    end
    return true
end

if SERVER or file.Exists("apadventure/cfgsettings.lua","lcl") then
    include("apadventure/cfgsettings.lua")
end