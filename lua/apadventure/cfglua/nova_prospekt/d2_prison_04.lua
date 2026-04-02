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

        if APADV_ENTRNAME == "Exit" then
            ents.FindByName("closet_door")[1]:Fire("Close")
            -- kinda gross to remove one of the doors outright but they're both
            -- attached to the same func_door so there's no better way if i only
            -- want one of them to open
            ents.GetMapCreatedEntity(1811):Remove()
        end
    end
}