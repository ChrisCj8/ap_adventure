return {
    PostCfgLoad = function(self)
        if APADV_ENTRNAME == "End" then
            ents.FindByName("attacking_zombie")[1]:Remove()
            ents.FindByName("dethvmm")[1]:Fire("Trigger")
        end
    end
}