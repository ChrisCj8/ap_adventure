APADV = APADV or {}

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
AddCSLuaFile("ui/connect.lua")

include("player.lua")
include("shared.lua")
include("cfgload.lua")
include("save.lua")
include("wephandler.lua")
include("ap.lua")

util.AddNetworkString("apAdvConnectionInfo")

ApAdv_LastMapTbl = ApAdv_LastMapTbl or {}
ApAdv_NextMapTbl = ApAdv_NextMapTbl or {}
ApAdv_Entrances = ApAdv_Entrances or {}
APADV_EXITENTS = APADV_EXITENTS or {}

function DoMapTransition(map,group,entrname)
    local curmap = game.GetMap()
    local slotdata
    if APADV_SLOT and APADV_SLOT.slotData then
        slotdata = APADV_SLOT.slotData
    end
    if map == curmap then
        if entrname then
            ApAdv_EntrName = entrname
            APADV_USESTART = nil
        else
            if slotdata then
                APADV_USESTART = slotdata.startregion
            end
            ApAdv_EntrName = nil
        end
        LoadCfg(group)
        return
    end
    local checknum = math.random(999999)
    ApAdv_NextMapTbl.checknum = checknum
    ApAdv_NextMapTbl.lastmap = game.GetMap()
    ApAdv_NextMapTbl.apslot = {
        addr = APADV_SLOT.address,
        name = APADV_SLOT.slotName,
        pw = APADV_SLOT.password, 
        sd = slotdata
    }
    ApAdv_NextMapTbl.loadcfg = {
        m = map,
        g = group,
        e = entrname
    }
    
    if entrname then
        APADV_SAVEDATA.visited = APADV_SAVEDATA.visited or {}
        APADV_SAVEDATA.visited[map] = APADV_SAVEDATA.visited[map] or {}
        APADV_SAVEDATA.visited[map][group] = APADV_SAVEDATA.visited[map][group] or {}
        APADV_SAVEDATA.visited[map][group][entrname] = true 
    elseif slotdata and slotdata.start == curmap then
        ApAdv_NextMapTbl.SentToStart = slotdata.startregion
    end

    game.SetGlobalCounter("ApAdvLevelTrans",checknum)
    file.Write("apadventure/leveltransdata.json",util.TableToJSON(ApAdv_NextMapTbl))
    RunConsoleCommand("changelevel",map)
end

if file.Exists("apadventure/leveltransdata.json","DATA") then
    local checknum = game.GetGlobalCounter("ApAdvLevelTrans")
    if checknum != 0 then
        local lastmaptbl = util.JSONToTable(file.Read("apadventure/leveltransdata.json","DATA"))
        if lastmaptbl.checknum == checknum then
            ApAdv_LastMapTbl = lastmaptbl

            if lastmaptbl.SentToStart then
                APADV_USESTART = lastmaptbl.SentToStart
            end

            ApAdv_EntrName = lastmaptbl.loadcfg.e

            local sltbl = lastmaptbl.apslot
            if sltbl then
                ApAdvCreateApSlot(sltbl.addr,sltbl.name,sltbl.pw,sltbl.sd)
            end

            hook.Add("InitPostEntity","ApAdvCfgLoader",function()
                LoadCfg(lastmaptbl.loadcfg.g)
            end)
        end
    end
    file.Delete("apadventure/leveltransdata.json")
end

