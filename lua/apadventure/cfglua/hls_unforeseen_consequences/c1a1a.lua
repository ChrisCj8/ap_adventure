return {
    PostCfgLoad = function(self)
        for k,v in ipairs(ents.FindByName("lk1")) do
            v:Fire("Lock")
        end
    end
}