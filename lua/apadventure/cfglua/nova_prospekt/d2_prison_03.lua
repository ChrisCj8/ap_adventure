local enabledspawners = {}

return {
    OnAntlionStatusUpdate = function(self,status)
        if status then
            hook.Remove("AcceptInput",self)
            for k,v in pairs(enabledspawners) do
                k:Fire("Enable")
            end
        end
    end,
    PostCfgLoad = function(self)
        
        hook.Add("AcceptInput",self,function(self,ent,input) 
            if input == "Enable" and ent:GetClass() == "npc_antlion_template_maker" then
                enabledspawners[ent] = true
                return true
            end
        end)

        self:OnAntlionStatusUpdate(APADV.AntlionFriendly)
    end,
    OnFullConnect = function(self)
        local guard = ents.FindByName("showers_guard")[1]

        if APADV.MapLocationStatus("Defeat Shower Guard") then
            guard:SetHealth(guard:Health()/2)
        else
            hook.Add("OnNPCKilled",self,function(self,npc)
                if npc == guard then
                    if APADV.SendMapLocation("Defeat Shower Guard") then
                        hook.Remove("OnNPCKilled",self)
                    end
                end
            end)
        end
    end
}