apAdventure.EditCfg = apAdventure.EditCfg or {
    Saved = {},
    DelMark = {},
    DelName = {},
    Group = "",
    Regions = {},
    Connections = {},
    MapItems = {},
    Info = {},
    GroupInfo = {},
    Events = {},
}

local prettyprintcvar = CreateConVar("apadventure_prettyprintcfgs",0,FCVAR_ARCHIVE+FCVAR_REPLICATED,
    "When enabled, config .json files will generated with the prettyprint parameter enabled, which makes them more readable at the cost of taking slightly more storage space",
    0,1)

list.Set("DesktopWindows","apAdventureEditor",{
    icon = "apadventure/apicon64.png",
    title = "apAdventure Editor",
    width = 800,
    height = 500,
    init = function(icon, window)
        include("apadventure/ui/cmenu.lua")(window)
    end
})


local editcfg = apAdventure.EditCfg

local apAdvDelHalos = {}
local apAdvSaveHalos = {}

net.Receive("APAdvActiveCfgClear",function()
    local gname = net.ReadString()
    print("loading "..gname) 
    apAdventure.EditCfg = {
        Saved = {},
        DelMark = {},
        DelName = {},
        Group = "";
        Regions = {},
        Connections = {},
        MapItems = {},
        Info = {},
        GroupInfo = {},
        Events = {},
    }
    editcfg = apAdventure.EditCfg
    apAdvDelHalos = {}
    apAdvSaveHalos = {}
    local groupjson = file.Read("apadventure/cfg/"..gname.."/group.json","DATA")
    if groupjson then
        local tbl = util.JSONToTable(groupjson)
        if tbl then
            editcfg.GroupInfo = tbl.rules
        end
    end
    local json = file.Read("apadventure/cfg/"..gname.."/"..game.GetMap().."/cl.json","DATA")
    print(json)
    if json then
        local tbl = util.JSONToTable(json)
        PrintTable(tbl)
        if tbl then 
            editcfg.Regions = tbl.reg or {}
            editcfg.Connections = tbl.connect or {}
            editcfg.MapItems = tbl.item or {}
            editcfg.Info = tbl.info or {}
         end
    end
end)

net.Receive("APAdvSaveCfg",function() 
    local gname = net.ReadString()
    print("storing "..gname)
    local items = editcfg.MapItems
    if !next(items) then items = nil end
    local outtbl = {
        ver = "v1",
        reg = editcfg.Regions or {},
        connect = editcfg.Connections,
        item = items,
        info = editcfg.Info,
    }
    PrintTable(outtbl)
    local groupout = {
        rules = editcfg.GroupInfo
    }
    local prettyprint = prettyprintcvar:GetBool()
    local map = game.GetMap()
    local dir = "apadventure/cfg/"..gname
    file.CreateDir(dir.."/"..map)
    file.Write(dir.."/group.json",util.TableToJSON(groupout,prettyprint))
    file.Write(dir.."/"..map.."/cl.json",util.TableToJSON(outtbl,prettyprint))
    local cllogic = apAdventure.ClCfgToLogic(outtbl)
    if !cllogic then return end
    dir = "apadventure/logic/cfg/"..gname.."/"..map
    file.CreateDir(dir)
    file.Write(dir.."/cl.json",util.TableToJSON(cllogic,prettyprint))
end)

function apAdventure.UpdateGroup(gname)
    local gdir = "apadventure/cfg/"..gname.."/"
    local _, folders = file.Find(gdir.."*","DATA")
    if !next(folders) then return end
    for k,v in ipairs(folders) do
        local mappath = gdir..v.."/"
        local svfile = file.Read(mappath.."sv.json")
        local clfile = file.Read(mappath.."cl.json")
        if svfile and clfile then
            local svtbl = util.JSONToTable(svfile)
            local cltbl = util.JSONToTable(clfile)
            if svtbl and cltbl then
                --[[ local newpath = "apadventure/cfg/"..gname.."/"..v.."/"
                file.CreateDir(newpath) ]]
                file.Write(mappath.."sv.json",util.TableToJSON(apAdventure.UpdateConfig(svtbl,"sv")))
                file.Write(mappath.."cl.json",util.TableToJSON(apAdventure.UpdateConfig(cltbl,"cl")))
            elseif !svtbl and !cltbl then
                print("server and client cfgs for map "..v.." in group "..gname.."could not be processed into a table")
            elseif !svtbl then
                print("server cfg for map "..v.." in group "..gname.."could not be processed into a table")
            else
                print("client cfg for map "..v.." in group "..gname.."could not be processed into a table")
            end
        elseif !svfile and !clfile then
            print("server and client cfgs for map "..v.." in group "..gname.."could not be read")
        elseif !svfile then
            print("server cfg for map "..v.." in group "..gname.."could not be read")
        else
            print("client cfg for map "..v.." in group "..gname.."could not be read")
        end
    end
    if file.Exists(gdir.."group.json","DATA") then
        local groupfile = file.Read(gdir.."group.json")
        if groupfile then
            local grouptbl = util.JSONToTable(groupfile)
            if grouptbl then
                file.Write("apadventure/cfg/"..gname.."/group.json",util.TableToJSON(apAdventure.UpdateConfig(grouptbl,"gr")))
            else
                print("group file for group "..gname.."could not be processed into a table")
            end
        else 
            print("group file for group "..gname.."could not be read")
        end
        
    end
end

function apAdventure.UpdateAllCfgs()
    local dir = "apadventure/cfgs/gm/"
    local _, folders = file.Find(dir.."*","DATA")
    for k,v in ipairs(folders) do
        apAdventure.UpdateGroup(v)
    end
end

function apAdventure.ProcessGroupLogic(gname)
    local gdir = "apadventure/cfg/"..gname.."/"
    local _, folders = file.Find(gdir.."*","DATA")
    PrintTable(folders)
    if !next(folders) then return end
    for k,v in ipairs(folders) do
        local mappath = gdir..v.."/"
        local svfile = file.Read(mappath.."sv.json")
        local clfile = file.Read(mappath.."cl.json")
        if svfile and clfile then
            local svtbl = util.JSONToTable(svfile)
            local cltbl = util.JSONToTable(clfile)
            if svtbl and cltbl then
                local newpath = "apadventure/logic/cfg/"..gname.."/"..v.."/"
                local svlogic = apAdventure.SvCfgToLogic(svtbl)
                if svlogic then
                    local cllogic = apAdventure.ClCfgToLogic(cltbl)
                    if cllogic then
                        file.CreateDir(newpath)
                        file.Write(newpath.."sv.json",util.TableToJSON(svlogic,true))
                        file.Write(newpath.."cl.json",util.TableToJSON(cllogic,true))
                    else
                        print("client cfg for map "..v.." in group "..gname.."could not be processed into logic")
                    end
                else
                    print("server cfg for map "..v.." in group "..gname.."could not be processed into logic")
                end
            elseif !svtbl and !cltbl then
                print("server and client cfgs for map "..v.." in group "..gname.."could not be processed into a table")
            elseif !svtbl then
                print("server cfg for map "..v.." in group "..gname.."could not be processed into a table")
            else
                print("client cfg for map "..v.." in group "..gname.."could not be processed into a table")
            end
        elseif !svfile and !clfile then
            print("server and client cfgs for map "..v.." in group "..gname.."could not be read")
        elseif !svfile then
            print("server cfg for map "..v.." in group "..gname.."could not be read")
        else
            print("client cfg for map "..v.." in group "..gname.."could not be read")
        end
    end
end

function apAdventure.ProcessAllLogic()
    local dir = "apadventure/cfg/"
    local _, folders = file.Find(dir.."*","DATA")
    for k,v in ipairs(folders) do
        apAdventure.ProcessGroupLogic(v)
    end
end

timer.Create("APAdvProcessDelHalos",1,0,function() 
    apAdvDelHalos = {}
    local i=1
    for k,v in pairs(apAdventure.EditCfg.DelMark) do
        if IsValid(v.ent) then
            apAdvDelHalos[i] = v.ent
            i=i+1
        else
            local idcheck = ents.GetMapCreatedEntity(k)
            if idcheck then
                apAdventure.EditCfg.DelMark[k].ent = idcheck
                apAdvDelHalos[i] = idcheck
                i=i+1
            end 
        end
    end
    timer.Stop("APAdvProcessDelHalos")
end)

timer.Create("APAdvUpdateDelMark",1,0,function()
    if IsValid(apAdventure.DeleteByCIdList) then
        apAdventure.DeleteByCIdList:ProcessDelMark()
    end
    timer.Stop("APAdvUpdateDelMark")
end)
timer.Stop("APAdvUpdateDelMark")

net.Receive("APAdvClearDelMark", function()
    apAdventure.EditCfg.DelMark = {}
    timer.Start("APAdvProcessDelHalos")
    timer.Start("APAdvUpdateDelMark")
end)

net.Receive("APAdvDelMark",function() 
    local id = net.ReadUInt(14)
    local class = net.ReadString()
    local name = net.ReadString()
    local mark = net.ReadBool()
    if mark then 
        local ent = ents.GetMapCreatedEntity(id) 
        if !ent then 
            mark = NULL 
        else
            mark = ent
        end
    else 
        mark = nil 
    end
    local entry
    if mark then 
        entry = {
            ent = mark,
            class = class,
            name = name
        }
    end
    apAdventure.EditCfg.DelMark[id] = entry
    timer.Start("APAdvProcessDelHalos")
    timer.Start("APAdvUpdateDelMark")
end)

timer.Create("APAdvProcessSaveHalos",1,0,function() 
    apAdvSaveHalos = {}
    local i=1
    for k,v in pairs(apAdventure.EditCfg.Saved) do
        if IsValid(k) then
            apAdvSaveHalos[i] = k
            i=i+1
        end
    end
    timer.Stop("APAdvProcessSaveHalos")
end)

net.Receive("APAdvSaveMark",function()
    local ent = net.ReadEntity()
    local state = net.ReadBool()
    if state == false then state = nil end
    apAdventure.EditCfg.Saved[ent] = state
    timer.Start("APAdvProcessSaveHalos")
end)

net.Receive("APAdvClearSaveMark", function()
    apAdventure.EditCfg.Saved = {}
    timer.Start("APAdvProcessSaveHalos")
end)

local accesstbls = {
    [0] = "LocationAccessTbl",
    [1] = "EntrAccessTbl",
}

local accesspnlkeys = {
    [0] = "LctnAccessPnl",
    [1] = "EntrAccessPnl"
}

net.Receive("APAdvAccess",function()
    local type = net.ReadUInt(2)
    local acctbl = apAdventure[accesstbls[type]]
    local json = "[]"
    if acctbl then json = util.TableToJSON(acctbl) end
    local done

    repeat
        local msg = string.sub(json,1,60000)
        json = string.sub(json,60001,-1)
        done = #json <= 0
        net.Start("APAdvAccess")
            net.WriteString(msg)
            net.WriteBool(done)
            if done then net.WriteUInt(type,2) end
        net.SendToServer()
    until done
end)

local entrmsg = ""

net.Receive("APAdvAccessCopy",function()
    entrmsg = entrmsg..net.ReadString()

    if net.ReadBool() then
        local type = net.ReadUInt(2)
        local targetkey = accesstbls[type]
        local accesstbl = util.JSONToTable(entrmsg)
        if accesstbl then
            apAdventure[targetkey] = accesstbl
        else
            apAdventure[targetkey] = {}
            if entrmsg != "" then
                ErrorNoHalt("Received Invalid Access JSON Table from the Server when copying Settings from the Entrance/Exit Entity.\n")
            end
        end
        local accesspnl = apAdventure[accesspnlkeys[type]]
        if IsValid(accesspnl) then
            accesspnl:LoadTbl(apAdventure,targetkey)
        end
        entrmsg = ""
    end
end)

local delmarkhalo = Color(200,10,10)
local savmarkhalo = Color(10,200,10)

local addhalo = halo.Add

local delhaloconv = CreateClientConVar("apadventure_editor_show_delete_halos",1,true,false,
    "Determines if the game should render red halos around entities marked for deletion via the Delete Marker Tool.",0,1)

local doDelHalos = delhaloconv:GetBool()

cvars.AddChangeCallback("apadventure_editor_show_delete_halos",function(_,_,val) 
    doDelHalos = tobool(val)
end)

local savehaloconv = CreateClientConVar("apadventure_editor_show_save_halos",1,true,false,
    "Determines if the game should render green halos around entities marked to be saved via the Save Marker Tool.",0,1)

local doSaveHalos = savehaloconv:GetBool()

cvars.AddChangeCallback("apadventure_editor_show_save_halos",function(_,_,val) 
    doSaveHalos = tobool(val)
end)

hook.Add("PreDrawHalos","apAdventure",function() 
    if doDelHalos then
        addhalo(apAdvDelHalos,delmarkhalo,2,2,1,true,true)
    end
    if doSaveHalos then
        addhalo(apAdvSaveHalos,savmarkhalo,2,2,1,true,true)
    end
end)

apAdventure.TextFacing = Angle(0,0,90)

local textfacing = apAdventure.TextFacing

hook.Add("Think","ApAdvPlayerView",function() 
    textfacing = LocalPlayer():EyeAngles()
    textfacing.x = 0
    textfacing.y = textfacing.y - 90
    textfacing.z = 90
    apAdventure.TextFacing = textfacing
end)

local areaportalstr = ""

net.Receive("APAdvAreaPortalInfo",function()
    areaportalstr = areaportalstr..net.ReadString()
    if net.ReadBool() then
        apAdventure.AreaPortalInfo = util.JSONToTable(areaportalstr)
        areaportalstr = ""
    end
end)

concommand.Add("apadventure_update_all_cfgs",apAdventure.UpdateAllCfgs)
concommand.Add("apadventure_process_all_logic",apAdventure.ProcessAllLogic)

if !game.SinglePlayer() then

    net.Receive("ApAdvToolShot",function()
        local ply = net.ReadPlayer()
        local hitpos = net.ReadVector()
        if !ply then return end
        local wep = ply:GetActiveWeapon()
        if wep:GetClass() != "gmod_tool" then return end
        wep:EmitSound(wep.ShootSound)
        local effect = EffectData()
        effect:SetOrigin(hitpos)
        local at = wep
        if ply == LocalPlayer() then at = ply:GetViewModel() end
        effect:SetStart(at:GetAttachment(1).Pos)
        util.Effect("ToolTracer",effect)
    end)

    function apAdventure.CopyAccessTbl(name,copytype,targettype)
        targettype = targettype or copytype
        net.Start("APAdvAccessCopy")
            net.WriteString(name)
            net.WriteUInt(copytype,2)
            net.WriteUInt(targettype,2)
        net.SendToServer()
    end

end