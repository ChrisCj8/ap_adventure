
include("apadventure/cl/mapiconmat.lua")

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
    icon = "icon32/folder.png",
    title = "apAdventure Editor",
    width = 800,
    height = 500,
    init = function(icon, window)
        include("apadventure/ui/cmenu.lua")(window)
    end
})

local editcfg = apAdventure.EditCfg

local apAdvHalos = {}

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
    apAdvHalos = {}
    local groupjson = file.Read("apadventure/cfgs/gm/"..gname.."/group.json","DATA")
    if groupjson then
        local tbl = util.JSONToTable(groupjson)
        if tbl then
            editcfg.GroupInfo = tbl.rules
        end
    end
    local json = file.Read("apadventure/cfgs/gm/"..gname.."/"..game.GetMap().."/sav_cl.json","DATA")
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
        reg = editcfg.Regions,
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
    dir = "apadventure/cfgs/ap/"..gname.."/"..map
    file.CreateDir(dir)
    file.Write(dir.."/sav_cl.json",util.TableToJSON(outtbl,prettyprint))
end)

timer.Create("APAdvProcessHalos",1,0,function() 
    apAdvHalos = {}
    local i=1
    for k,v in pairs(apAdventure.EditCfg.DelMark) do
        if IsValid(v) then
            apAdvHalos[i] = v
            i=i+1
        else
            local idcheck = ents.GetMapCreatedEntity(k)
            if idcheck then
                apAdventure.EditCfg.DelMark[k] = idcheck
                apAdvHalos[i] = idcheck
                i=i+1
            end 
        end
    end
    timer.Stop("APAdvProcessHalos")
end)

net.Receive("APAdvDelMark",function() 
    local id = net.ReadUInt(14)
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
    apAdventure.EditCfg.DelMark[id] = mark
    timer.Start("APAdvProcessHalos")
end)

apAdvDoHalos = true

local delmarkhalo = Color(200,10,10)

hook.Add("PreDrawHalos","apAdventure",function() 
    if !apAdvDoHalos then return end
    halo.Add(apAdvHalos,delmarkhalo,2,2,1,true,true)
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

