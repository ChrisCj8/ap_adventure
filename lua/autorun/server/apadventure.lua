
include("apadventure/sv/mapiconmat.lua")

AddCSLuaFile("apadventure/ui/cmenu.lua")
AddCSLuaFile("apadventure/cl/mapiconmat.lua")

function apAdventure.UpdateAccessNodeInfo()
    local accessnodefiles = file.Find("apadventure/ui/accessnodes/*.lua","LUA")
    for k,v in ipairs(accessnodefiles) do
        AddCSLuaFile("apadventure/ui/accessnodes/"..v)
    end
end

apAdventure.UpdateAccessNodeInfo()

function apAdventure.UpdatePresetInfo()
    local presetfiles = file.Find("apadventure/ui/settingpreset/*.lua","LUA")
    for k,v in ipairs(presetfiles) do
        AddCSLuaFile("apadventure/ui/settingpreset/"..v)
    end
end

apAdventure.UpdatePresetInfo()

apAdventure.EditCfg = apAdventure.EditCfg or {
    Saved = {},
    DelMark = {},
    DelName = {},
    Group = "",
    Regions = {},
    ConnectionsInt = {},
    ConnectionsExt = {},
}

local prettyprintcvar = CreateConVar("apadventure_prettyprintcfgs",0,FCVAR_ARCHIVE+FCVAR_REPLICATED,
    "When enabled, config .json files will be generated with the prettyprint parameter enabled, which makes them more readable at the cost of taking slightly more storage space",
    0,1)

//if file.IsDir("apAdventure/")
util.AddNetworkString("APAdvDelMark")
util.AddNetworkString("APAdvActiveCfgClear")
util.AddNetworkString("APAdvRegion")
util.AddNetworkString("APAdvSaveCfg")
util.AddNetworkString("APAdvAreaPortalInfo")

local editcfg = apAdventure.EditCfg

local playingApAdv = engine.ActiveGamemode() == "apadventure"

function apAdventure.DelMark(ent,state)
    local cID = ent:MapCreationID()
    if cID == -1 then return false end
    if state == false then state = nil end
    apAdventure.EditCfg.DelMark[cID] = state
    net.Start("APAdvDelMark")
        net.WriteUInt(cID,14)
        net.WriteBool(state)
    net.Broadcast()
    return true
end

--[[ function apAdventure.SendRegion(name)
    local region = editcfg.Regions[name]
    if !region then return end
    net.Start("APAdvRegion", function() 
        net.WriteString(name)
    end)
end

function apAdventure.CreateRegion(name)
    if editcfg.Regions[name] != nil then return end
    editcfg.Regions[name] = {
        Locations = {},
        EntracesInt = {},
        ExitsInt = {},
        EntrancesExt = {},
        ExitsInt = {},
    }
end ]]

function apAdventure.SetCfgTbl(tbl)
    apAdventure.EditCfg = tbl  
end

local listenhost

function apAdventure.GetListenHost()
    if IsValid(listenhost) then return listenhost end
    for k,v in ipairs(player.GetAll()) do
        if v:IsListenServerHost() then
            listenhost = v
            return v
        end
    end
end

function apAdventure.LoadClientTbl(name)
    net.Start("APAdvActiveCfgClear")
        net.WriteString(name)
    net.Send(apAdventure.GetListenHost())
end

function apAdventure.StoreCfg(groupoverride)
    local srctbl = apAdventure.EditCfg
    if isstring(groupoverride) and groupoverride != "" then srctbl.Group = groupoverride end
    if srctbl.Group == "" or !isstring(srctbl.Group) then return end
    local listenhost = player.GetByID(1)
    print(listenhost,srctbl.Group)
    net.Start("APAdvSaveCfg")
        net.WriteString(srctbl.Group)
    net.Send(listenhost) --hope that this is always the listen server host
    local savpre = {}
    local i = 1
    for k,v in pairs(srctbl.Saved) do
        if IsValid(k) then
            savpre[i] = k
            i = i+1
        else
            srctbl.Saved[k] = nil
        end
    end
    PrintTable(savpre)
    local sav = duplicator.CopyEnts(savpre)
    local del = {}
    local i=1
    for k,v in pairs(srctbl.DelMark) do
        del[i] = k
        i=i+1
    end
    local delname = {}
    i=1
    for k,v in pairs(srctbl.DelName) do
        delname[i] = k
        i=i+1
    end
    local exit = {}
    local exit_ap = {}
    i=1
    for k,v in ipairs(ents.FindByClass("apadventure_exit_editor")) do
        local reg, name = v:GetRegion(), v:GetExitName()
        exit[i] = {
            pos = v:GetPos(),
            ang = v:GetAngles(),
            reg = reg,
            name = name
        }
        exit_ap[name] = reg
        i=i+1
    end
    local entr = {}
    local entr_ap = {}
    i=1
    for k,v in ipairs(ents.FindByClass("apadventure_entrance_editor")) do
        local reg, name = v:GetRegion(), v:GetEntrName()
        entr[i] = {
            pos = v:GetPos(),
            ang = v:GetAngles(),
            reg = reg,
            name = name
        }
        entr_ap[name] = reg
        i=i+1
    end
    local start = {}
    local start_ap = {}
    i=1
    for k,v in ipairs(ents.FindByClass("apadventure_start_editor")) do
        local reg = v:GetRegion()
        start[i] = {
            pos = v:GetPos(),
            ang = v:GetAngles(),
            reg = reg
        }
        start_ap[reg] = true 
        i=i+1
    end
    local lctn = {}
    local lctn_ap = {}
    i=1
    for k,v in ipairs(ents.FindByClass("apadventure_location_editor")) do
        local reg, name = v:GetRegion(), v:GetLctnName()
        lctn[i] = {
            pos = v:GetPos(),
            ang = v:GetAngles(),
            reg = reg,
            name = name,
            dummy = v:GetIsDummy() or nil
        }
        lctn_ap[reg] = lctn_ap[reg] or {}
        lctn_ap[reg][name] = {
            access = {}
        }
        i=i+1
    end
    local outtbl = {
        sav = sav,
        del = del,
        delname = delname,
        exit = exit,
        entr = entr,
        start = start,
        lctn = lctn
    }
    if next(start_ap) == nil then start_ap = nil end
    local outap = {
        entr = entr_ap,
        exit = exit_ap,
        lctn = lctn_ap,
        start = start_ap
    }

    PrintTable(outtbl)
    PrintTable(outap)
    local prettyprint = prettyprintcvar:GetBool()
    local dir = "apadventure/cfgs/gm/"..srctbl.Group.."/"..game.GetMap()
    file.CreateDir(dir)
    file.Write(dir.."/sav.json",util.TableToJSON(outtbl,prettyprint))
    local apdir = "apadventure/cfgs/ap/"..srctbl.Group.."/"..game.GetMap()
    file.CreateDir(apdir)
    file.Write(apdir.."/sav.json",util.TableToJSON(outap,prettyprint))
end

function apAdventure.LoadCfg(gname,dodelete)
    assert(!(gname == "" or !isstring(gname)),"Invalid Group Name")
    local path = "apadventure/cfgs/gm/"..gname.."/"..game.GetMap().."/sav.json"
    local json = assert(file.Read(path,"DATA"),"couldn't find config")
    local gtbl = util.JSONToTable(json)
    local cfgtab = {
        Saved = {},
        DelMark = {},
        DelName = {},
        Group = gname,
        Regions = {},
    }
    game.CleanUpMap()
    apAdventure.LoadClientTbl(gname)

    local newsav = cfgtab.Saved
    local presav = duplicator.Paste(nil,gtbl.sav.Entities or gtbl.sav ,gtbl.sav.Constraints or {})

    for k,v in pairs(presav) do
        newsav[v] = true
    end

    local newdel = cfgtab.DelMark
    for k,v in ipairs(gtbl.del) do
        net.Start("APAdvDelMark")
            net.WriteUInt(v,14)
            net.WriteBool(true)
        net.Broadcast()
        newdel[v] = ents.GetMapCreatedEntity(v)
        if dodelete then
            newdel[v]:Remove()
        end
    end

    local newdelname = cfgtab.DelName
    for k,v in ipairs(gtbl.delname) do
        newdelname[v] = true
        if dodelete then
            timer.Simple(.2,function() 
                for ik,iv in ipairs(ents.FindByName(v)) do
                    iv:Remove()
                end
            end)
        end
    end

    for k,v in ipairs(gtbl.exit) do
        local ent = ents.Create("apadventure_exit_editor")
        ent:SetPos(v.pos)
        ent:SetAngles(v.ang)
        ent:SetRegion(v.reg)
        ent:SetExitName(v.name)
        ent:Spawn()
    end

    for k,v in ipairs(gtbl.entr) do
        local ent = ents.Create("apadventure_entrance_editor")
        ent:SetPos(v.pos)
        ent:SetAngles(v.ang)
        ent:SetRegion(v.reg)
        ent:SetEntrName(v.name)
        ent:Spawn()
    end

    for k,v in ipairs(gtbl.lctn) do
        local ent = ents.Create("apadventure_location_editor")
        ent:SetPos(v.pos)
        --ent:SetAngles(v.ang)
        ent:SetRegion(v.reg)
        ent:SetLctnName(v.name)
        ent:SetIsDummy(v.dummy)
        ent:Spawn()
    end

    apAdventure.SetCfgTbl(cfgtab)
end

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
    --PrintTable(changelevelinfo)
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
            local col = string.explode(" ",v.rendercolor)
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

local function ProcessItemGroup(groupname)
    local grouppath = "apadventure/itemsets/"..groupname
    local groupdef = include(grouppath..".lua")
    --PrintTable(groupdef)
    local out = {
        name = groupdef.Name,
        items = {},
    }
    local itemtbl = out.items
    if !file.IsDir(grouppath,"LUA") then return end
    local itemdefs = file.Find(grouppath.."/*.lua","LUA")
    for k,v in ipairs(itemdefs) do
        local deftbl = include(grouppath.."/"..v)
        if istable(deftbl) then
            PrintTable(deftbl)
            itemtbl[deftbl.Name] = {
                wgt = deftbl.FillWeight,
                min = deftbl.MinAmt,
                oneuse = deftbl.OneUse,
                group = deftbl.Groups,
                ammocapab = deftbl.AmmoCapabilities,
                capab = deftbl.Capabilities,
            }
        else
            print(grouppath.."/"..v.." did not return a table")
        end 
    end

    file.Write("apadventure/itemdefs/"..groupname..".json",util.TableToJSON(out,prettyprintcvar:GetBool()))
end

function apAdventure.ProcessItemdefs(groupname)
    if isstring(groupname) and groupname != "" then
        ProcessItemGroup(groupname)
    else
        local defgroups = file.Find("apadventure/itemsets/*.lua","LUA")
        for k,v in ipairs(defgroups) do
            ProcessItemGroup(string.sub(v,0,-5))
        end
    end
end

concommand.Add("apadventure_editor_loadcfg",function(ply,_,args) 
    local arg = args[1]
    if !ply:IsListenServerHost() or !arg or arg == "" then return end
    apAdventure.LoadCfg(arg)
end)

concommand.Add("apadventure_editor_savecfg",function(ply,_,args) 
    local arg = args[1]
    if !ply:IsListenServerHost() or !arg or arg == "" then return end
    apAdventure.StoreCfg(arg)
end)

concommand.Add("apadventure_editor_processitemdefs",function(ply,_,args) 
    local arg = args[1]
    if !ply:IsListenServerHost() or arg == "" then return end
    apAdventure.ProcessItemdefs(arg)
end)

concommand.Add("apadventure_editor_delete_mark_by_creationid",function(ply,_,args) 
    local arg = tonumber(args[1])
    if !ply:IsListenServerHost() or !arg then return end
    apAdventure.EditCfg.DelMark[arg] = true
    net.Start("APAdvDelMark")
        net.WriteUInt(arg,14)
        net.WriteBool(true)
    net.Broadcast()
end)

concommand.Add("apadventure_editor_remove_delete_mark_by_creationid",function(ply,_,args) 
    local arg = tonumber(args[1])
    if !ply:IsListenServerHost() or !arg then return end
    apAdventure.EditCfg.DelMark[arg] = nil
    net.Start("APAdvDelMark")
        net.WriteUInt(arg,14)
        net.WriteBool(false)
    net.Broadcast()
end)