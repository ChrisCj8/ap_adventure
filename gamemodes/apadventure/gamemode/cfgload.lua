
function APADV.LoadCfg(group)
    if group then
        APADV_MAPGROUP = group
    else
        group = APADV_MAPGROUP
    end
    assert(group,"Cfg Loader was not passed a Group Name and could not find a previously used Map Group")
    APADV.DeadPlys = {}
    local map = game.GetMap()
    APADV_MAP = map
    local path = "apadventure/cfg/"..group.."/group.json"
    local json = file.Read(path,"DATA")
    if json then groupcfg = util.JSONToTable(json) end
    local path = "apadventure/cfg/"..group.."/"..map.."/sv.json"
    local json = assert(file.Read(path,"DATA"),"couldn't find config")
    local cfg = util.JSONToTable(json)
    path = "apadventure/cfg/"..group.."/"..map.."/cl.json"
    json = assert(file.Read(path,"DATA"),"couldn't find config")
    local clcfg = util.JSONToTable(json)
    game.CleanUpMap()

    local infotbl = clcfg.info
    local grouprules = {} 
    if groupcfg then
        grouprules = groupcfg.rules
    end

    local settingstbl = apAdventure.CfgSettings

    function cfginfo(valname)
        local val = infotbl[valname]
        if val != nil then return val end
        val = grouprules[valname]
        if val != nil then return val end
        local settinginfo = settingstbl[valname]
        if settinginfo then
            return settinginfo.default
        end
    end

    RunConsoleCommand("sv_gravity",cfginfo("grav"))
    RunConsoleCommand("sv_accelerate",cfginfo("accel"))
    RunConsoleCommand("sv_airaccelerate",cfginfo("airaccel"))
    RunConsoleCommand("sv_friction",cfginfo("frctn"))
    RunConsoleCommand("sv_stopspeed",cfginfo("stopspd"))
    RunConsoleCommand("gmod_suit",cfginfo("hev") and 1 or 0)
    ApAdvPly.SetWalkSpeed(cfginfo("walkspd"))
    ApAdvPly.SetRunSpeed(cfginfo("runspd"))
    ApAdvPly.SetSprintSpeed(cfginfo("sprintspd"))
    ApAdvPly.SetJumpPower(cfginfo("jump"))
    APADV.PermaDeath = !cfginfo("respawn")

    if next(cfg.sav) then
        duplicator.Paste(nil,cfg.sav.Entities,cfg.sav.Constraints)
    end
    
    for k,v in ipairs(cfg.del) do
        ents.GetMapCreatedEntity(v):Remove()
    end

    APADV_SPAWNS = {}

    if APADV_USESTART then
        if cfg.start then
            local i = 1
            for k,v in ipairs(cfg.start) do
                if v.reg == APADV_USESTART then
                    APADV_SPAWNS[i] = v
                    APADV_SPAWNS[i].reg = nil
                    i = i+1
                end
            end
        end
    else
        local i = 1
        for k,v in ipairs(cfg.entr) do
            if APADV_ENTRNAME == v.name then
                APADV_SPAWNS[i] = {
                    pos = v.pos,
                    ang = v.ang
                }
                i = i+1
            end
        end
    end

    APADV_EXITENTS = {}

    for k,v in pairs(cfg.exit) do
        local exit = ents.Create("apadventure_exit")
        exit:SetPos(v.pos)
        exit:SetAngles(v.ang)
        exit.ExitName = v.name
        exit:Spawn()
        APADV_EXITENTS[exit] = v.name
        if APADV_ENTRANCES and APADV_ENTRANCES[APADV_MAPGROUP] and APADV_ENTRANCES[APADV_MAPGROUP][APADV_MAP] and APADV_ENTRANCES[APADV_MAPGROUP][APADV_MAP][v.name] then 
            timer.Simple(2,function() exit:SetMapIcon(APADV_ENTRANCES[APADV_MAPGROUP][APADV_MAP][v.name].map) end) 
        end
    end

    local loclist = APADV_SLOT.Locations
    local locnametoid
    if APADV_DATAPACK_LOCAL and APADV_SLOT.Connected then
        if loclist then 
            locnametoid = APADV_DATAPACK_LOCAL.location_name_to_id
        end
        APADV.RegisterMapItems(clcfg.item)
    else
        APADV.MapItemTbl = clcfg.item
    end

    for k,v in pairs(cfg.lctn) do
        if !v.dummy then
            local locname = group .. " - " .. map .. " - " .. v.name
            -- prevents already checked locations from being placed, but this only works if we're connected when the config is loaded
            -- so this doesn't work all the time since the gamemode doesn't wait for the slot to reconnect when doing a map transition
            if !locnametoid or !loclist[locnametoid[locname]] then 
                local loc = ents.Create("apadventure_location")
                loc:SetPos(v.pos)
                loc:SetAngles(v.ang)
                loc:SetupLocation(locname)
                loc:Spawn()
            end
        end
    end

    for k,v in player.Iterator() do
        --v:KillSilent()
        v:Spawn()
    end

    local scriptpath = "apadventure/cfglua/"..group.."/"..map..".lua"
    if file.Exists(scriptpath,"lsv") then
        local scripts = include(scriptpath)
    end
end