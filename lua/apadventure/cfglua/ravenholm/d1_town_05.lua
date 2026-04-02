local entsbyname = ents.FindByName

return {
    PostCfgLoad = function(self)
        if APADV_ENTRNAME == "Rebel Base" then
            local door = entsbyname("citizen_warehouse_door_1")[1]
            door:Fire("Unlock")
            door:Fire("Open")
            entsbyname("trigger_close_door")[1]:Remove()
            for k,v in ipairs(entsbyname("warehouse_gunfire")) do v:Remove() end
            
            if player.GetCount() > 0 then
                entsbyname("warehouse_standoff_template")[1]:Fire("ForceSpawn")
            else
                hook.Add("PlayerSpawn",self,function()
                    entsbyname("warehouse_standoff_template")[1]:Fire("ForceSpawn")
                    hook.Remove("PlayerSpawn",self)
                end)
            end
        end
    end
}


