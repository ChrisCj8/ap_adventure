return {
    OnFullConnect = function(self)
        if APADV.MapLocationStatus("Rappelling Metrocop") then return end

        hook.Add("OnNPCKilled",self,function(self, ent) 
            if ent:GetName() == "smg_rappeller_cop_2" then
                if APADV.SendMapLocation("Rappelling Metrocop") then
                    hook.Remove("OnNPCKilled",self)
                end
            end
        end)
    end
}