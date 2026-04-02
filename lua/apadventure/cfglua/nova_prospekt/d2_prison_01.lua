return {
    OnAntlionStatusUpdate = function(self,status)
        if status == false then
            for k,v in ipairs(ents.FindByClass("npc_antlion_template_maker")) do
                v:Fire("Disable")
            end
        else
            for k,v in ipairs(ents.FindByClass("npc_antlion_template_maker")) do
                v:Fire("Enable")
            end
        end
    end,
    PostCfgLoad = function(self)
        self:OnAntlionStatusUpdate(APADV.AntlionFriendly)
    end
}