return {
    PostCfgLoad = function(self)
        local alyx = ents.FindByName("alyx")[1]

        hook.Add("EntityTakeDamage",alyx,function(self,ent,dmg)
            if self == ent then
                dmg:ScaleDamage(.5)
            end
        end)
    end
}