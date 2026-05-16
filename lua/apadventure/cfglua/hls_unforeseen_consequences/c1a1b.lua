return {
    PostCfgLoad = function(self)
        if APADV_ENTRNAME == "End" then
            local entsbyname = ents.FindByName
            entsbyname("vent_zombie")[1]:Remove()
            entsbyname("zombie_floor_grate")[1]:Fire("Start")
            entsbyname("bustmm")[1]:Fire("Trigger")
            entsbyname("watch")[1]:Fire("BeginSequence")
        end
    end
}