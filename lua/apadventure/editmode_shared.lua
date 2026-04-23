
local maxupdates = {}

for k,v in pairs(apAdventure.CfgVers) do
    local files = file.Find("apadventure/updaters/"..k.."/*.lua","LUA")
    maxupdates[k] = #files + 2
end

function apAdventure.UpdateConfig(cfg,type)
    local pathbase = "apadventure/updaters/"..type.."/"
    local updates = 0
    local maxupdate = maxupdates[type]
    local targetver = apAdventure.CfgVers[type]
    local ver = cfg.ver or "old"

    while ver != targetver do
        local updaterpath = pathbase..ver..".lua"
        if file.Exists(updaterpath,"LUA") then
            cfg = include(updaterpath)(cfg)
        else
            error("attempted to load config with version "..ver.." and could not find a way to update it")
        end
        updates = updates + 1
        if updates > maxupdate then
            error("tried to update the config file too many times, aborting to prevent the game from crashing")
        end
        ver = cfg.ver or "invalid"
    end

    return cfg
end

function apAdventure.ClCfgToLogic(cfg)

    if !next(cfg.reg) then return end
    
    local reg = {}

    for k,v in pairs(cfg.reg) do
        local condtbl = {}
        if v.ammo then
            local i = 0
            for k,v in pairs(v.ammo) do
                i = i + 1
                condtbl[i] = k
            end
        end
        reg[k] = {
            cond = condtbl
        }
    end

    local info = {}
    local settinginfo = apAdventure.CfgSettings

    for k,v in pairs(cfg.info) do
        local cursetinfo = settinginfo[k]
        if cursetinfo and cursetinfo.togen and !(istable(v) and !next(v)) then
            info[k] = v
        end
    end

    return {
        item = cfg.item,
        reg = reg,
        connect = cfg.connect,
        info = next(info) and info or nil
    }
end

function apAdventure.SvCfgToLogic(cfg)

    local exit = {}
    local exitaccess = cfg.exitaccess or {}
    for k,v in ipairs(cfg.exit) do
        exit[v.name] = {
            reg = v.reg,
            access = exitaccess[v.name]
        }
    end

    if !next(exit) then exit = nil end

    local entr = {}
    local entraccess = cfg.entraccess or {}
    for k,v in ipairs(cfg.entr) do
        entr[v.name] = {
            reg = v.reg,
            access = entraccess[v.name],
        }
    end

    if !next(entr) then entr = nil end

    local lctn = {}
    local lctnaccess = cfg.lctnaccess or {}
    for k,v in ipairs(cfg.lctn) do
        lctn[v.reg] = lctn[v.reg] or {}
        lctn[v.reg][v.name] = {access=lctnaccess[v.name]}
    end

    if !next(lctn) then lctn = nil end

    local start = {}
    local i = 0
    local logged = {}

    for k,v in ipairs(cfg.start) do
        if !logged[v.reg] then
            i = i+1
            start[i] = v.reg
            logged[v.reg] = true
        end
    end

    if !next(start) then start = nil end

    return {
        exit = exit,
        entr = entr,
        lctn = lctn,
        start = start,
    }
end

function apAdventure.GrCfgToLogic(cfg)
    local info = {}
    local settinginfo = apAdventure.CfgSettings

    for k,v in pairs(cfg.rules) do
        local cursetinfo = settinginfo[k]
        if cursetinfo and cursetinfo.togen and !(istable(v) and !next(v)) then
            info[k] = v
        end
    end

    return {
        info = next(info) and info or nil
    }
end