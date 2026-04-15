
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
    local uifiles = file.Find("apadventure/ui/*.lua","lsv")
    for k,v in ipairs(uifiles) do
        AddCSLuaFile("apadventure/ui/"..v)
    end
    AddCSLuaFile("apadventure/cfgsettings.lua")
    apAdventure.EditMode = true
    include("apadventure/editmode_shared.lua")
    include("apadventure/sv/editmode.lua")
else
    AddCSLuaFile("apadventure/ui/savemanage.lua")
end

util.AddNetworkString("APAdvAreaPortalInfo")
util.AddNetworkString("APAdvSaveManageCmd")
util.AddNetworkString("APAdvSaveManageData")
util.AddNetworkString("APAdvNotif")

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

local function deldir(path) 
    local files, dirs = file.Find(path.."/*","DATA")
    for k,v in ipairs(files) do
        file.Delete(path.."/"..v)
    end
    for k,v in ipairs(dirs) do
        deldir(path.."/"..v)
    end
    file.Delete(path)
end

net.Receive("APAdvSaveManageCmd",function(_,ply)
    if !(ply:IsListenServerHost() or ply:IsUserGroup("superadmin")) then return end
    local cmd = {
        data = function()
            local _,saves = file.Find("apadventure/sav/*","DATA")
            for k,v in ipairs(saves) do
                net.Start("APAdvSaveManageData")
                    net.WriteString(v)
                net.Send(ply)
            end
        end,
        del = function()
            local name = net.ReadString()
            deldir("apadventure/sav/"..name)
        end
    }
    cmd[net.ReadString()]()
end)

function apAdventure.SendNotification(text,type,len,snd,ply)
    if !type then
        type = 0
    elseif type % 1 != 0 or type > 4 or type < 0 then 
        ErrorNoHalt("Invalid Notification Type "..type.." passed to SendNotification")
    end
    print(text,type,len,snd,ply)
    net.Start("ApAdvNotif")
        net.WriteUInt(type,3)
        net.WriteString(text)
        net.WriteFloat(len or 3)
        net.WriteString(snd or "")
    if !ply then
        net.Broadcast()
    elseif isentity(ply) and ply:IsPlayer() or isentity(ply[1]) and ply[1]:IsPlayer() or type(ply) == "CRecipientFilter" then
        net.Send(ply)
    else
        net.Broadcast()
    end
end

function apAdventure.ToolWarn(loc,ply)
    apAdventure.SendNotification("#apadventure.toolwarn."..loc,1,4,nil,ply)
end