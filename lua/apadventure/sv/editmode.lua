
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
    LocationAccess = {},
    EntrAccess = {},
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
util.AddNetworkString("APAdvAccess")
util.AddNetworkString("APAdvAccessCopy")

local editcfg = apAdventure.EditCfg

local function senddelmark(cID,ent,state)
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
    senddelmark(cID,ent,state)
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
        senddelmark(k,v,true)
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

function apAdventure.StoreCfg(groupoverride)
    local srctbl = apAdventure.EditCfg
    if isstring(groupoverride) and groupoverride != "" then srctbl.Group = groupoverride end
    if srctbl.Group == "" or !isstring(srctbl.Group) then return end
    local listenhost = player.GetByID(1)
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
    local entrnames = {}
    i=1
    for k,v in ipairs(ents.FindByClass("apadventure_entrance_editor")) do
        local reg, name = v:GetRegion(), v:GetEntrName()
        entr[i] = {
            pos = v:GetPos(),
            ang = v:GetAngles(),
            reg = reg,
            name = name
        }
        entrnames[name] = true
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
    local lctnnames = {}
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
        lctnnames[name] = true
        i=i+1
    end
    local lctnaccess = srctbl.LocationAccess or {}
    for k,v in pairs(lctnaccess) do
        if !lctnnames[k] then
            lctnaccess[k] = nil
        end
    end
    local entraccess = srctbl.EntrAccess or {}
    for k,v in pairs(entraccess) do
        if !entrnames[k] then
            entraccess[k] = nil
        end
    end
    local outtbl = {
        ver = "v1",
        sav = sav,
        del = del,
        delname = delname,
        exit = exit,
        entr = entr,
        start = start,
        lctn = lctn,
        lctnaccess = lctnaccess,
        entraccess = entraccess,
    }

    local prettyprint = prettyprintcvar:GetBool()
    local dir = "apadventure/cfg/"..srctbl.Group.."/"..game.GetMap()
    file.CreateDir(dir)
    file.Write(dir.."/sv.json",util.TableToJSON(outtbl,prettyprint))
    local apdir = "apadventure/logic/cfg/"..srctbl.Group.."/"..game.GetMap()
    file.CreateDir(apdir)
    file.Write(apdir.."/sv.json",util.TableToJSON(apAdventure.SvCfgToLogic(outtbl),prettyprint))
end

function apAdventure.LoadCfg(gname,dodelete)
    assert(!(gname == "" or !isstring(gname)),"Invalid Group Name")
    local path = "apadventure/cfg/"..gname.."/"..game.GetMap().."/sv.json"
    local json = file.Read(path,"DATA")

    game.CleanUpMap()
    apAdventure.LoadClientTbl(gname)

    if !json then return end
    local gtbl = util.JSONToTable(json)

    if (gtbl.ver or "old") != apAdventure.CfgVers.sv then
        gtbl = apAdventure.UpdateConfig(gtbl)
    end

    local cfgtab = {
        Saved = {},
        DelMark = {},
        DelName = {},
        Group = gname,
        Regions = {},
        LocationAccess = gtbl.lctnaccess,
        EntrAccess = gtbl.entraccess or {},
    }

    local newsav = cfgtab.Saved
    local presav = duplicator.Paste(nil,gtbl.sav.Entities or gtbl.sav ,gtbl.sav.Constraints or {})

    for k,v in pairs(presav) do
        newsav[v] = true
    end

    local newdel = cfgtab.DelMark
    for k,v in ipairs(gtbl.del) do
        local ent = ents.GetMapCreatedEntity(v)
        senddelmark(v,ent,true)
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

    local lctnaccess = cfgtab.LocationAccess
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
    timer.Simple(.1,apAdventure.UpdateSaveMarks)
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
            local curitem = {
                wgt = deftbl.FillWeight,
                min = deftbl.MinAmt,
                oneuse = deftbl.OneUse,
                group = deftbl.Groups,
                condcapab = deftbl.ConditionalCapabilities,
                capab = deftbl.Capabilities,
                file = string.sub(v,0,-5)
            }
            if deftbl.RequireCondition then
                curitem.req_cond = true
            end
            itemtbl[deftbl.Name] = curitem
        else
            print(grouppath.."/"..v.." did not return a table")
        end 
    end

    file.Write("apadventure/logic/item/"..groupname..".json",util.TableToJSON(out,prettyprintcvar:GetBool()))
end

if !file.IsDir("apadventure/logic/item/","DATA") then
    file.CreateDir("apadventure/logic/item/")
end 

local jsonmsg = ""
local reqname

local accesstbls = {
    [0] = "LocationAccess",
    [1] = "EntrAccess",
}

net.Receive("APAdvAccess",function() 
    jsonmsg = jsonmsg..net.ReadString()
    if net.ReadBool() then
        if reqname then
            local targetkey = accesstbls[net.ReadUInt(2)]
            local accesstbl = util.JSONToTable(jsonmsg)
            if accesstbl then
                if next(accesstbl) then
                    apAdventure.EditCfg[targetkey][reqname] = accesstbl
                else
                    apAdventure.EditCfg[targetkey][reqname] = nil
                end
            else
                ErrorNoHalt("Received Access Table for "..reqname.." was not a valid JSON Table.\n")
                print(jsonmsg)
            end
            jsonmsg = ""
        else
            jsonmsg = ""
            ErrorNoHalt("Received an Access Table despite not making a request for it.\n")
        end
        reqname = nil
    end
end)

function apAdventure.RequestAccessTbl(ply,name,type)
    reqname = name
    net.Start("APAdvAccess")
        net.WriteUInt(type,2)
    net.Send(ply)
end

function apAdventure.CopyAccessTbl(requester,name,copytype,targettype)

    targettype = targettype or copytype
    local accesstbl = apAdventure.EditCfg[accesstbls[copytype]][name]
    local json = util.TableToJSON(accesstbl or {})
    local done

    repeat
        local msg = string.sub(json,1,60000)
        json = string.sub(json,60001,-1)
        done = #json <= 0
        net.Start("APAdvAccessCopy")
            net.WriteString(msg)
            net.WriteBool(done)
            if done then net.WriteUInt(targettype,2) end
        net.Send(requester)
    until done
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

    net.Receive("APAdvAccessCopy",function(len,ply)
        apAdventure.CopyAccessTbl(ply,net.ReadString(),net.ReadUInt(2),net.ReadUInt(2))
    end)
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