return {
    PostCfgLoad = function(self)
        hook.Add("GetFallDamage",self,function(_, ply) 
            if ply:GetPos().z < -1000 then
                return ply:Health()*2
            end
        end)
    end
}