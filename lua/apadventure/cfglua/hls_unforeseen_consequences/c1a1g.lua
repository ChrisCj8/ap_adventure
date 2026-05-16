return {
    PostCfgLoad = function(self)
        local secdoor = ents.FindByName("doors2")[1]
        secdoor:Fire("AddOutput","OnFullyOpen doors2:Lock")
        hook.Add("GetFallDamage",self,function(_, ply) 
            if ply:GetPos().z < -1000 then
                return ply:Health()*2
            end
        end)
    end
}