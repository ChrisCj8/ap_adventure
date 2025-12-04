
function LoadCfg(group)
    APADV_MAPGROUP = group
    local map = game.GetMap()
    APADV_MAP = map
    local path = "apadventure/cfgs/gm/"..group.."/"..map.."/sav.json"
    local json = assert(file.Read(path,"DATA"),"couldn't find config")
    local cfg = util.JSONToTable(json)
    path = "apadventure/cfgs/gm/"..group.."/"..map.."/sav_cl.json"
    json = assert(file.Read(path,"DATA"),"couldn't find config")
    local clcfg = util.JSONToTable(json)
    game.CleanUpMap()

    local infotbl = clcfg.info

    RunConsoleCommand("sv_gravity",infotbl.grav or 600)
    RunConsoleCommand("sv_accelerate",infotbl.accel or 10 )
    RunConsoleCommand("sv_airaccelerate",infotbl.airaccel or 10 )
    RunConsoleCommand("sv_friction",infotbl.frctn or 8)
    RunConsoleCommand("sv_stopspeed",infotbl.stopspd or 10)
    RunConsoleCommand("gmod_suit",infotbl.hev and 1 or 0)
    ApAdvPly.SetWalkSpeed(infotbl.walkspd or 100)
    ApAdvPly.SetRunSpeed(infotbl.runspd or 200)
    ApAdvPly.SetSprintSpeed(infotbl.sprintspd or 400)
    ApAdvPly.SetJumpPower(infotbl.jump or 200)

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
        for k,v in ipairs(cfg.entr) do
            local i = 1
            if ApAdv_EntrName == v.name then
                APADV_SPAWNS[i] = {
                    pos = v.pos,
                    ang = v.ang
                }
                i = i+1
            end
            --[[ ApAdv_Entrances[v.name] = ApAdv_Entrances[v.name] or {}
            ApAdv_Entrances[v.name][#ApAdv_Entrances[v.name]+1] = {
                pos = v.pos,
                ang = v.ang,
            } ]]
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
    if APADV_DATAPACK_LOCAL and APADV_SLOT.Connected and loclist then 
        locnametoid = APADV_DATAPACK_LOCAL.location_name_to_id
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

    for k,v in ipairs(player.GetAll()) do
        --v:KillSilent()
        v:Spawn()
    end

    local scriptpath = "apadventure/cfglua/"..group.."/"..map..".lua"
    if file.Exists(scriptpath,"lsv") then
        local scripts = include(scriptpath)
    end
end