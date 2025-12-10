if APADV_ENTRNAME != "Entrance" then
    for k,v in ipairs(ents.FindByName("slaughterhouse_portal_1")) do 
        v:Fire("Open") 
    end
    ents.FindByName("start_music")[1]:Remove()
    ents.FindByName("cartrap_arena_clip")[1]:Remove()
    ents.FindByName("zombiepyre_1_trap_1_flamejet_wheel_1")[1]:Fire("Open")
    ents.FindByName("hallfire_1_trap_1_flamejet_wheel_1")[1]:Fire("Open")
    timer.Simple(.2,function() 
        ents.FindByName("zombiepyre_1_trap_1_ignition_button_1")[1]:Fire("Open")
        ents.FindByName("hallfire_1_trap_1_ignition_button_1")[1]:Fire("Open")
    end)
end