
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

util.AddNetworkString("APAdvDelMark")
util.AddNetworkString("APAdvClearDelMark")
util.AddNetworkString("APAdvSaveMark")
util.AddNetworkString("APAdvClearSaveMark")
util.AddNetworkString("APAdvActiveCfgClear")
util.AddNetworkString("APAdvRegion")
util.AddNetworkString("APAdvSaveCfg")
util.AddNetworkString("APAdvCfgDataSave")
util.AddNetworkString("apadvloadsvtbl")

local editcfg = apAdventure.EditCfg

function apAdventure.SendDelMark(cID,ent,state)
    local class, name = "?","?"
    if IsValid(ent) then
        class = ent:GetClass()
        name = ent:GetName()
    end
    net.Start("APAdvDelMark")
        net.WriteUInt(cID,14)
        net.WriteString(class)
        net.WriteString(name)
        net.WriteBool(state)
    net.Broadcast()
end

function apAdventure.DelMark(ent,state)
    local cID
    if isnumber(ent) then
        cID = ent 
        ent = ents.GetMapCreatedEntity(cID)
    else
        cID = ent:MapCreationID()
    end
    if cID == -1 then return false end
    if state == false then 
        state = nil 
    else
        state = ent
    end
    
    local delmarktbl = apAdventure.EditCfg.DelMark
    if delmarktbl[cID] == state then return false end
    delmarktbl[cID] = state
    apAdventure.SendDelMark(cID,ent,state)
    return true
end

function apAdventure.UpdateDelMarks(ply)
    local send = net.send
    if !ply then
        send = net.Broadcast
    elseif !IsValid(ply) then
        return
    end
    net.Start("APAdvClearDelMark")
    send(ply)
    for k,v in pairs(apAdventure.EditCfg.DelMark) do
        apAdventure.SendDelMark(k,v,true)
    end
end

net.Receive("APAdvDelMark",function(len,ply)
    local id = net.ReadUInt(14)
    local state = net.ReadBool()
    apAdventure.DelMark(id,state)
end)

local function sendsavemark(ent,state)
    net.Start("APAdvSaveMark")
        net.WriteEntity(ent)
        net.WriteBool(state)
    net.Broadcast()
end

function apAdventure.SaveMark(ent,state)
    if ent:MapCreationID() != -1 then return end
    if state == false then 
        state = nil
    end
    local savtbl = apAdventure.EditCfg.Saved
    if savtbl[ent] == state then return false end
    savtbl[ent] = state
    sendsavemark(ent,state)
    return true
end

function apAdventure.UpdateSaveMarks(ply)
    local send = net.Send
    if !ply then
        send = net.Broadcast
    elseif !IsValid(ply) then
        return
    end
    net.Start("APAdvClearSaveMark")
    send(ply)
    for k,v in pairs(apAdventure.EditCfg.Saved) do
        sendsavemark(k,true)
    end
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

function apAdventure.LoadClientTbl(name)
    net.Start("APAdvActiveCfgClear")
        net.WriteString(name)
    net.Send(apAdventure.GetListenHost())
end

function apAdventure.CreateCfgTbl(groupoverride)
    local srctbl = apAdventure.EditCfg
    if isstring(groupoverride) and groupoverride != "" then srctbl.Group = groupoverride end
    --if srctbl.Group == "" or !isstring(srctbl.Group) then return end

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
    i=1
    for k,v in ipairs(ents.FindByClass("apadventure_exit_editor")) do
        local reg, name = v:GetRegion(), v:GetExitName()
        exit[i] = {
            pos = v:GetPos(),
            ang = v:GetAngles(),
            reg = reg,
            name = name
        }
        i=i+1
    end

    local entr = {}
    i=1
    for k,v in ipairs(ents.FindByClass("apadventure_entrance_editor")) do
        local reg, name = v:GetRegion(), v:GetEntrName()
        entr[i] = {
            pos = v:GetPos(),
            ang = v:GetAngles(),
            reg = reg,
            name = name
        }
        i=i+1
    end

    local start = {}
    i=1
    for k,v in ipairs(ents.FindByClass("apadventure_start_editor")) do
        local reg = v:GetRegion()
        start[i] = {
            pos = v:GetPos(),
            ang = v:GetAngles(),
            reg = reg
        }
        i=i+1
    end

    local lctn = {}
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
        i=i+1
    end

    return {
        sav = sav,
        del = del,
        delname = delname,
        exit = exit,
        entr = entr,
        start = start,
        lctn = lctn
    }
end

net.Receive("APAdvCfgDataSave",function(len,ply)
    if !ply:IsListenServerHost() then return end

    local cfgstr = util.TableToJSON(apAdventure.CreateCfgTbl())
    local done

    repeat
        net.Start("APAdvCfgDataSave")
            local sendstr

            if #cfgstr > 60000 then
                sendstr = string.sub(cfgstr,0,60000)
                cfgstr = string.sub(cfgstr,60001,-1)
            else
                sendstr = cfgstr
                done = true
            end
            net.WriteString(sendstr)
            net.WriteBool(done)
        net.Send(ply)
    until done
end)

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
    local start_list = {}
    if next(start_ap) != nil then 
        local i = 0
        for k,v in pairs(start_ap) do
            i=i+1
            start_list[i] = k
        end
    end
    if !next(start_list) then start_list = nil end
    if !next(entr_ap) then entr_ap = nil end
    if !next(exit_ap) then exit_ap = nil end
    if !next(lctn_ap) then lctn_ap = nil end
    local outap = {
        entr = entr_ap,
        exit = exit_ap,
        lctn = lctn_ap,
        start = start_list
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
    local loader = gtbl.ver or "old"
    local loaderpath = "apadventure/loader/sv/"..loader..".lua"
    if file.Exists(loaderpath,"lsv") then
        include(loaderpath)(gtbl,dodelete)
    else
        error("tried to use invalid config loader "..loader)
    end
    apAdventure.LoadClientTbl(gname)
    --[[ local cfgtab = {
        Saved = {},
        DelMark = {},
        DelName = {},
        Group = gname,
        Regions = {},
    }
    game.CleanUpMap()
    

    local newsav = cfgtab.Saved
    local presav = duplicator.Paste(nil,gtbl.sav.Entities or gtbl.sav ,gtbl.sav.Constraints or {})

    for k,v in pairs(presav) do
        newsav[v] = true
    end

    local newdel = cfgtab.DelMark
    for k,v in ipairs(gtbl.del) do
        local ent = ents.GetMapCreatedEntity(v)
        apAdventure.SendDelMark(v,ent,true)
        newdel[v] = ent
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

    for k,v in ipairs(gtbl.start) do
        local ent = ents.Create("apadventure_start_editor")
        ent:SetPos(v.pos)
        ent:SetAngles(v.ang)
        ent:SetRegion(v.reg)
        ent:Spawn()
    end

    apAdventure.SetCfgTbl(cfgtab)
    timer.Simple(.1,apAdventure.UpdateSaveMarks) ]]
end

local svtblstr = ""

net.Receive("apadvloadsvtbl",function(len,ply) 
    if !ply:IsListenServerHost() then return end

    local str = net.ReadString()
    local done = net.ReadBool()

    svtblstr = svtblstr..str

    if done then
        local loader = net.ReadString()
        local loaderpath = "apadventure/sv/loader/"..loader..".lua"
        if file.Exists(loaderpath,"lsv") then
            local tbl = util.JSONToTable(svtblstr)
            PrintTable(tbl)
            include("apadventure/loader/sv/"..loader..".lua")(tbl)
        else
            ErrorNoHalt("tried to use invalid config loader "..loader)
        end
        svtblstr = ""
    end
end)

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

if game.SinglePlayer() then
    function apAdventure.SpoofToolShot()
        return true
    end
else
    util.AddNetworkString("ApAdvToolShot")

    function apAdventure.SpoofToolShot(tool,tr)
        local wep = tool:GetWeapon()
        local ply = tool:GetOwner()
        wep:EmitSound(wep.ShootSound)
        net.Start("ApAdvToolShot")
            net.WritePlayer(ply)
            net.WriteVector(tr.HitPos)
        net.Broadcast()
        return true
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
    apAdventure.DelMark(arg,true)
end)

concommand.Add("apadventure_editor_remove_delete_mark_by_creationid",function(ply,_,args) 
    local arg = tonumber(args[1])
    if !ply:IsListenServerHost() or !arg then return end
    apAdventure.DelMark(arg,false)
end)