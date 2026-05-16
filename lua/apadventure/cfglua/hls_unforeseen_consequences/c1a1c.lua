return {
    PostCfgLoad = function(self)
        for k,v in ipairs(ents.FindByName("startele1")) do
            v:Fire("Open")
            v:Fire("AddOutput","OnFullyOpen !activator:Lock")
        end
        if APADV_ENTRNAME != "Start" then
            ents.FindByName("squid_catwalk_start")[1]:Fire("Trigger")
        end
    end
}