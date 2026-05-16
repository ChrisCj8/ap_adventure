return {
    PostCfgLoad = function(self)
        local secdoor = ents.FindByName("doors")[1]
        secdoor:Fire("AddOutput","OnFullyOpen doors:Lock")
    end
}