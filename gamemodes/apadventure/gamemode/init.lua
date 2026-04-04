APADV = APADV or {}
APADV.MapItemCounters = {}

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
AddCSLuaFile("ui/connect.lua")
AddCSLuaFile("ui/tracker.lua")

include("player.lua")
include("shared.lua")
include("cfgload.lua")
include("save.lua")
include("wephandler.lua")
include("ap.lua")
include("tracker.lua")

util.AddNetworkString("apAdvConnectionInfo")
util.AddNetworkString("ApAdvConnectionState")

APADV_LASTMAPTBL = APADV_LASTMAPTBL or {}
APADV_NEXTMAPTBL = APADV_NEXTMAPTBL or {}
APADV_ENTRANCES = APADV_ENTRANCES or {}
APADV_EXITENTS = APADV_EXITENTS or {}
APADV_MAPITEMCOUNTERS = APADV_MAPITEMCOUNTERS or {}

RunConsoleCommand("gmod_maxammo",0)
RunConsoleCommand("ai_disabled",0)

local BASEGM = baseclass.Get("gamemode_base")

function GM:PreCleanupMap()
    APADV.MapItemCounters = {}
end

function APADV.MarkEntrance(map,group,name)
    APADV_SAVEDATA._visited = APADV_SAVEDATA._visited or {}
    APADV_SAVEDATA._visited[map] = APADV_SAVEDATA._visited[map] or {}
    APADV_SAVEDATA._visited[map][group] = APADV_SAVEDATA._visited[map][group] or {}
    APADV_SAVEDATA._visited[map][group][name] = true
end

function APADV.DoMapTransition(map,group,entrname)
    local curmap = game.GetMap()
    local slotdata
    if APADV_SLOT and APADV_SLOT.slotData then
        slotdata = APADV_SLOT.slotData
    end
    if map == curmap then
        if entrname then
            APADV_ENTRNAME = entrname
            APADV_USESTART = nil
        else
            if slotdata then
                APADV_USESTART = slotdata.startregion
            end
            APADV_ENTRNAME = nil
        end
        APADV.LoadCfg(group)
        return
    end
    local checknum = math.random(999999)
    APADV_NEXTMAPTBL.checknum = checknum
    APADV_NEXTMAPTBL.lastmap = game.GetMap()
    APADV_NEXTMAPTBL.apslot = {
        addr = APADV_SLOT.address,
        name = APADV_SLOT.slotName,
        pw = APADV_SLOT.password, 
        sd = slotdata
    }
    APADV_NEXTMAPTBL.loadcfg = {
        m = map,
        g = group,
        e = entrname
    }
    
    if entrname then
        APADV.MarkEntrance(map,group,entrname)
    elseif slotdata and slotdata.start == curmap then
        APADV_NEXTMAPTBL.SentToStart = slotdata.startregion
    end

    game.SetGlobalCounter("ApAdvLevelTrans",checknum)
    file.Write("apadventure/leveltransdata.json",util.TableToJSON(APADV_NEXTMAPTBL))
    RunConsoleCommand("changelevel",map)
end

if file.Exists("apadventure/leveltransdata.json","DATA") then
    local checknum = game.GetGlobalCounter("ApAdvLevelTrans")
    if checknum != 0 then
        local lastmaptbl = util.JSONToTable(file.Read("apadventure/leveltransdata.json","DATA"))
        if lastmaptbl.checknum == checknum then
            APADV_LASTMAPTBL = lastmaptbl

            if lastmaptbl.SentToStart then
                APADV_USESTART = lastmaptbl.SentToStart
            end

            APADV_ENTRNAME = lastmaptbl.loadcfg.e

            local sltbl = lastmaptbl.apslot
            if sltbl then
                APADV.CreateApSlot(sltbl.addr,sltbl.name,sltbl.pw,sltbl.sd)
            end

            hook.Add("InitPostEntity","ApAdvCfgLoader",function()
                APADV.LoadCfg(lastmaptbl.loadcfg.g)
            end)
        end
    end
    file.Delete("apadventure/leveltransdata.json")
else
    local presetconv = GetConVar("apadv_connection_preset")
    local presetpath = "apadventure/connect/"..presetconv:GetString()..".json"
    if file.Exists(presetpath,"DATA") then
        local data = util.JSONToTable(file.Read(presetpath,"DATA"))
        if data.s then
            APADV.CreateApSlot(data.a,data.s,data.p)
        end
    end
end

local IsCollector

local function IsCollector(ent)
    if !IsValid(ent) then return false end
    if isbool(ent.ApAdvCollector) then return ent.ApAdvCollector end
    if ent:IsVehicle() then return IsCollector(ent:GetDriver()) end
    return false
end

-- doing it like this because i think making the recursive IsCollector call use a local reference is faster
APADV.IsCollector = IsCollector

function GM:SendDeathNotice(attacker,inflictor,victim,flags)
    if victim.ApAdvDoKillFeed then 
        return BASEGM:SendDeathNotice(attacker,inflictor,victim,flags)
    end
end

local strstart = string.StartsWith
local checksayperms

local sayperms = CreateConVar("apadv_apsay_perms",1,FCVAR_ARCHIVE,
    [[Determines who is allowed to use the \"/ap\" chat command and \"apadv_say\" console command to talk directly through the Archipelago slot.\n
    0 - anyone\n
    1 - Admins and Listen Server Host only\n
    2 - Super Admins and Listen Server Host only]],0,2)

local function updatesayperms()
    local funcs = {
        function() return true end,
        function(ply)
            if ply:IsListenServerHost() then return true end
            local group = ply:GetUserGroup()
            return group == "admin" or group == "superadmin"
        end,
        function(ply) return ply:IsListenServerHost() or ply:GetUserGroup() == "superadmin" end
    }
    checksayperms = funcs[sayperms:GetInt()+1]
end
updatesayperms()

cvars.AddChangeCallback("apadv_apsay_perms",updatesayperms)

function apsay(txt)
    if !APADV_SLOT or !APADV_SLOT.Connected then return end
    APADV_SLOT:SendChatMessage(txt)
end

function GM:PlayerSay(ply,txt)
    if strstart(txt,"/ap ") then
        if checksayperms(ply) then apsay(string.sub(txt,5,-1)) end
        return ""
    end
    return txt
end

concommand.Add("apadv_apsay",function(ply,_,_,txt)
    print(ply)
    if ply == NULL or checksayperms(ply) then apsay(txt) end
end)