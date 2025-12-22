return function(tbl,gtbl)
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
        
    if tbl then 
        editcfg.Regions = tbl.reg or {}
        editcfg.Connections = tbl.connect or {}
        editcfg.MapItems = tbl.item or {}
        editcfg.Info = tbl.info or {}
    end
end