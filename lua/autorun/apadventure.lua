
apAdventure = apAdventure or {}

apAdventure.CfgVers = { 
    sv = "v1", 
    cl = "v1",
    gr = "old"
}

if SERVER or file.Exists("apadventure/cfgsettings.lua","lcl") then
    include("apadventure/cfgsettings.lua")
end