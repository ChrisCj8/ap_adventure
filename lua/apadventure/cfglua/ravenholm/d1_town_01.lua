local entsbyname = ents.FindByName

return {
    PostCfgLoad = function(self)
        if APADV_ENTRNAME != "Entrance" then
            for k,v in ipairs(entsbyname("slaughterhouse_portal_1")) do 
                v:Fire("Open") 
            end
            entsbyname("start_music")[1]:Remove()
            entsbyname("cartrap_arena_clip")[1]:Remove()
            entsbyname("zombiepyre_1_trap_1_flamejet_wheel_1")[1]:Fire("Open")
            entsbyname("hallfire_1_trap_1_flamejet_wheel_1")[1]:Fire("Open")
            timer.Simple(.2,function() 
                entsbyname("zombiepyre_1_trap_1_ignition_button_1")[1]:Fire("Open")
                entsbyname("hallfire_1_trap_1_ignition_button_1")[1]:Fire("Open")
            end)
        end
    end
}

