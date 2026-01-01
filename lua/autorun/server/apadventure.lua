
include("apadventure/sv/mapiconmat.lua")

AddCSLuaFile("apadventure/cl/mapiconmat.lua")

local playingApAdv = engine.ActiveGamemode() == "apadventure"

local listenhost

function apAdventure.GetListenHost()
    if IsValid(listenhost) then return listenhost end
    for k,v in player.Iterator() do
        if v:IsListenServerHost() then
            listenhost = v
            return v
        end
    end
end

if engine.ActiveGamemode() == "sandbox" then
    AddCSLuaFile("apadventure/editmode_shared.lua")
    AddCSLuaFile("apadventure/cl/editmode.lua")
    AddCSLuaFile("apadventure/ui/cmenu.lua")
    apAdventure.EditMode = true
    include("apadventure/editmode_shared.lua")
    include("apadventure/sv/editmode.lua")
end

util.AddNetworkString("APAdvAreaPortalInfo")

apAdventure.AreaPortalInfo = apAdventure.AreaPortalInfo or {}
local areaportalinfo = apAdventure.AreaPortalInfo

local changelevelinfo = {}
local loadsavedinfo = {}

local kvloggers = {
    func_areaportal = function(ent,key,val)
        local cID = ent:MapCreationID()
        areaportalinfo[cID] = areaportalinfo[cID] or {}
        areaportalinfo[cID][key] = val
    end,
    trigger_changelevel = function(ent,key,val)
        changelevelinfo[ent] = changelevelinfo[ent] or {}
        changelevelinfo[ent][key] = val
    end,
    player_loadsaved = function(ent,key,val)
        loadsavedinfo[ent] = loadsavedinfo[ent] or {}
        loadsavedinfo[ent][key] = val
    end
}

hook.Add("EntityKeyValue","ApAdvKeyValLogger",function(ent,key,val)
    local logger = kvloggers[ent:GetClass()]
    if isfunction(logger) then
        logger(ent,key,val)
    end
end)

--[[ local capturekeyvals = {
    trigger_changelevel = true
} ]]

local captured = {}

--[[ hook.Add("EntityKeyValue","ApAdvKeyValCapture",function(ent,key,val) 
    if capturekeyvals[ent:GetClass()] then
        captured[ent] = captured[ent] or {}
        captured[ent][key] = val
    end
end) ]]

local patchchangelevelcvar = CreateConVar("apadventure_patch_changelevel",0,FCVAR_ARCHIVE,
    "Determines if apAdventure should replace trigger_changelevel entities with its own custom version outside of the actual gamemode. This may be useful to prevent you from accidentally triggering a level transition while editing.",
    0,1)
local patchloadsavedcvar = CreateConVar("apadventure_patch_loadsaved",0,FCVAR_ARCHIVE,
    "Determines if apAdventure should replace player_loadsaved entities with its own custom version outside of the actual gamemode. This may be useful to because the original entity may try to load an old save, causing you to lose unsaved changes to your config.",
    0,1)

local function UseCapturedKeyVals()
    if patchchangelevelcvar:GetBool() or playingApAdv then
        for k,v in pairs(changelevelinfo) do
            local oldpos = k:GetPos()
            local oldang = k:GetAngles() -- not sure if copying angles is actually necessary, but just in case
            k:Remove()
            local newtrig = ents.Create("trigger_changelevel_apadventure")
            newtrig:SetPos(oldpos)
            newtrig:SetAngles(oldang)

            newtrig:SetModel(v.model)
            newtrig.OldHammerID = v.hammerid
            newtrig.OldLandmark = v.landmark
            newtrig.OldMap = v.map
            newtrig:Spawn()
        end
    end
    
    changelevelinfo = {}

    if patchloadsavedcvar:GetBool() or playingApAdv then
        for k,v in pairs(loadsavedinfo) do
            local newent = ents.Create("player_loadsaved_apadventure")
            newent:SetPos(k:GetPos())
            newent:SetName(k:GetName())
            k:Remove()
            local col = string.Explode(" ",v.rendercolor)
            newent.FadeColor = Color(tonumber(col[1]),tonumber(col[2]),tonumber(col[3]),tonumber(v.renderamt))
            newent.FadeTime = tonumber(v.duration)
            newent.HoldTime = tonumber(v.holdtime)
            newent.LoadDelay = tonumber(v.loadtime)
            newent:Spawn()
        end
    end

    loadsavedinfo = {}

    local areaportaljson = util.TableToJSON(apAdventure.AreaPortalInfo)
    local sent = false
    local ply = apAdventure.GetListenHost()
    if !ply then return end
    repeat
        local msg = string.sub(areaportaljson,1,60000)
        areaportaljson = string.sub(areaportaljson,60001,-1)
        sent = #areaportaljson <= 0
        net.Start("APAdvAreaPortalInfo")
            net.WriteString(msg)
            net.WriteBool(sent)
        net.Send(ply)
    until sent

end

hook.Add("InitPostEntity","ApAdvUseCapturedKeyVals",UseCapturedKeyVals)
hook.Add("PostCleanupMap","ApAdvUseCapturedKeyVals",UseCapturedKeyVals)

if !file.IsDir("apadventure/itemdefs","DATA") then
    file.CreateDir("apadventure/itemdefs")
end