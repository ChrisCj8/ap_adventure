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
    end
}