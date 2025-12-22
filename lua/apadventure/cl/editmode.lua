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
    local map = game.GetMap()
    local json = file.Read("apadventure/cfgs/gm/"..gname.."/"..game.GetMap().."/sav_cl.json","DATA")
    print(json)
    if json then
        local tbl = util.JSONToTable(json)
        if tbl then 
            local loader = tbl.ver or "old"
            local loaderpath = "apadventure/loader/cl/"..loader..".lua"
            if file.Exists(loaderpath,"LUA") then
                include(loaderpath)(tbl)
            end
        end
    end
    local groupjson = file.Read("apadventure/cfgs/gm/"..gname.."/group.json","DATA")
    if groupjson then
        local tbl = util.JSONToTable(groupjson)
        if tbl then
            local loader = tbl.ver or "old"
            local loaderpath = "apadventure/loader/cl/"..loader..".lua"
            if file.Exists(loaderpath,"LUA") then
                include(loaderpath)(tbl)
            end
        end
    end
end)

net.Receive("APAdvSaveCfg",function() 
    local gname = net.ReadString()
    print("storing "..gname)
    local items = editcfg.MapItems
    if !next(items) then items = nil end
    local regtbl = editcfg.Regions
    if regtbl then
        for k,v in pairs(regtbl) do
            if v.ammo then
                local condtbl = {}
                local i = 0
                for k,v in pairs(v.ammo) do
                    i = i + 1
                    condtbl[i] = k
                end
                v.cond = condtbl
            end
        end
    end
    local outtbl = {
        reg = regtbl or {},
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
    local dir = "apadventure/cfgs/gm/"..gname
    file.CreateDir(dir.."/"..map)
    file.Write(dir.."/group.json",util.TableToJSON(groupout,prettyprint))
    file.Write(dir.."/"..map.."/sav_cl.json",util.TableToJSON(outtbl,prettyprint))
    if regtbl then
        for k,v in pairs(regtbl) do
            v.ammo = nil
        end
    end
    dir = "apadventure/cfgs/ap/"..gname.."/"..map
    file.CreateDir(dir)
    file.Write(dir.."/sav_cl.json",util.TableToJSON(outtbl,prettyprint))
end)


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

local cfgdatacb

function apAdventure.RequestCfgData(cb)
    if !LocalPlayer():IsListenServerHost() then return end
    cfgdatacb = cb
    net.Start("APAdvCfgDataSave")
    net.SendToServer()
end

local cfgdatastr = ""

net.Receive("APAdvCfgDataSave",function() 
    local str = net.ReadString()
    local done = net.ReadBool()
    cfgdatastr = cfgdatastr..str
    if done then 
        cfgdatacb(util.JSONToTable(cfgdatastr))
        cfgdatastr = ""
    end
end)

function apAdventure.LoadServerCfgTbl(tbl,loader)
    if !LocalPlayer():IsListenServerHost() then return end
    local json = util.TableToJSON(tbl)
    repeat
        net.Start("apadvloadsvtbl")
            local sendstr

            if #json > 60000 then
                sendstr = string.sub(json,0,60000)
                json = string.sub(json,60001,-1)
            else
                sendstr = json
                done = true
            end

            net.WriteString(sendstr)
            net.WriteBool(done)

            if done then
                net.WriteString(loader)
            end
        net.SendToServer()
    until done
end

function apAdventure.LoadCfg(gname)


end

function apAdventure.LoadOldCfg(gname)
    local map = game.GetMap()
    local clpath = "apadventure/cfgs/gm/"..gname.."/"..map.."/sav_cl.json"
    if file.Exists(clpath,"DATA") then
        include("apadventure/loader/cl/old.lua")(util.JSONToTable(file.Read(clpath,"DATA")))
    end
    local gpath = "apadventure/cfgs/gm/"..gname.."/group.json"
    if file.Exists(gpath,"DATA") then
        include("apadventure/loader/group/old.lua")(util.JSONToTable(file.Read(gpath,"DATA")))
    end
    local svpath = "apadventure/cfgs/gm/"..gname.."/"..map.."/sav.json"
    if file.Exists(svpath,"DATA") then
        apAdventure.LoadServerCfgTbl(util.JSONToTable(file.Read(svpath,"DATA")),"old")
    end
end

local newest_cl = "v1"
local newest_sv = "v1"
local newest_group = "v1"

function apAdventure.SaveToLogic(tbl)

end

function apAdventure.SaveCfg(gname)
    local editcfg = apAdventure.EditCfg
    local map = game.GetMap()
    local savtbl = {
        cl_ver = "v1",
        sv_ver = "v1",
        reg = editcfg.Regions,
        connect = editcfg.Connections,
        item = editcfg.MapItems,
        info = editcfg.Info,
    }
    local grouptbl = {
        ver = "v1",
        rules = editcfg.GroupInfo,
    }
    apAdventure.RequestCfgData(function(svtbl) 
        table.Merge(savtbl,svtbl)
        PrintTable(savtbl)
        PrintTable(grouptbl)
        local path = "apadventure/cfg/"..gname.."/"..map.."/"
        if !file.IsDir(path,"DATA") then
            file.CreateDir(path)
        end
        file.Write("apadventure/cfg/"..gname.."/group.json",util.TableToJSON(grouptbl,true))
        file.Write("apadventure/cfg/"..gname.."/map_"..map..".json",util.TableToJSON(savtbl,true))
    end)
end

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

end