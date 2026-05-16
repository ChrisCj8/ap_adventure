return {
    PostCfgLoad = function(self)
        ents.FindByName("lk1")[1]:Fire("Lock")
    end
}