//func_room5_field_gate_3
//func_room5_field_gate_4
//door_room5_gate_3
//door_room5_gate_4

local entsbyname = ents.FindByName
local entbyid = ents.GetMapCreatedEntity

local croomgate 

// don't forget to make this local again
function croomfieldstate(state)
    local brush = state and "Enable" or "Disable"
    local skin = state and 0 or 1
    for k,v in ipairs(entsbyname("shield_model_1")) do v:SetSkin(skin) end
    entsbyname("func_croom2_field_clip")[1]:Fire(brush)
    entsbyname("func_croom2_field")[1]:Fire(brush)
    entsbyname("shield_sound_trigger1")[1]:Fire(brush)
    entsbyname("forcefield1_sound_far")[1]:Fire("Volume",state and 100 or 0)
    entsbyname("forcefield1_sound_close")[1]:Fire(state and "StartSound" or "StopSound")
end

function cellsfieldstate(state)
    local brush = state and "Enable" or "Disable"
    local sndfar = state and 100 or 0
    local snd = state and "StartSound" or "StopSound"
    local skin = state and 0 or 1
    for k,v in ipairs(entsbyname("shield_model_2")) do
        if v:GetPos().y > -4000 then
            v:SetSkin(skin)
        end
    end
    for k,v in ipairs(entsbyname("func_room5_field_gate_4")) do v:Fire(brush) end
    for k,v in ipairs(entsbyname("func_room5_field_gate_3")) do v:Fire(brush) end
    for k,v in ipairs(entsbyname("forcefield_sound_close_3")) do v:Fire(snd) end
    for k,v in ipairs(entsbyname("forcefield_sound_close_2")) do v:Fire(snd) end
    for k,v in ipairs(entsbyname("forcefield_sound_far_3")) do v:Fire("Volume",sndfar) end
    for k,v in ipairs(entsbyname("forcefield_sound_far_2")) do v:Fire("Volume",sndfar) end
    -- these will always be opened since the forcefields will already be blocking the player so it doesn't matter what state they're in after that point
    for k,v in ipairs(entsbyname("door_room5_gate_3")) do v:Fire("Open") end
    for k,v in ipairs(entsbyname("door_room5_gate_4")) do v:Fire("Open") end
end

return {
    PostCfgLoad = function(self)
        for k,v in ipairs(entsbyname("turret_buddy")) do
            v:AddSpawnFlags(512)
        end

        --[[ hook.Add("EntityTakeDamage",self,function(self,ent,dmg)
            if ent:GetClass() == "npc_combine_s" then
                dmg:ScaleDamage(5)
            end
        end) ]]

        entbyid(1890):Remove() -- the trigger that closes the bars that would normally stop players from returning to the entrance

        croomgate = entsbyname("door_croom2_gate")[1]

        local croomfinished_logic = entsbyname("logic_croom2_finished")[1]

        hook.Add("AcceptInput",croomfinished_logic,function(self,ent,input) 
            if ent == self and input == "Trigger" then
                APADV.SendMapLocation("Defended Control Room")
                croomgate:Fire("Open")
                croomfieldstate(false)
                hook.Remove("AcceptInput",self)
            end
        end)

        local cellsstartlogic = entsbyname("logic_room5_begin_assault")[1]

        hook.Add("AcceptInput",cellsstartlogic,function(self,ent,input)
            if self == ent and input == "Trigger" then
                cellsfieldstate(true)
            end
        end)

        local cellsfinished_logic = entsbyname("logic_room5_assault_finished")[1]
        local manhackmaker = entsbyname("maker_manhack_room5_1")[1]
        local manhackson

        hook.Add("AcceptInput",cellsfinished_logic,function(self,ent,input) 
            if !manhackson then
                if ent == manhackmaker and input == "Enable" then
                    manhackson = true
                end
                return
            end
            
            if ent == self and input == "Trigger" then
                APADV.SendMapLocation("Defended Cell Block")
                cellsfieldstate(false) 
                hook.Remove("AcceptInput",self)
            end
        end)

        local croomstartlogic = entsbyname("logic_croom2_begin_assault")[1]

        hook.Add("AcceptInput",croomstartlogic,function(self,ent,input)
            if self == ent and input == "Trigger" then
                croomfieldstate(true)
            end
        end)
    end,
    OnFullConnect = function(self)

        local reverse = APADV_ENTRNAME == "Exit"
        local croomclear = APADV.MapLocationStatus("Defended Control Room")
        local cellsclear = APADV.MapLocationStatus("Defended Cell Block")

        local exitgate = entsbyname("door_exit_gate_1")[1]

        if reverse then
            exitgate:Fire("Open")
            entsbyname("door_stairwell2_exit")[1]:Fire("AddOutput","OnOpen template_zombie_stairwell:Spawn")
            croomgate:Fire("Close")
            croomfieldstate(false)
            entsbyname("lcs_message_croom2_entry")[1]:Remove()
        end

        if croomclear then 
            croomgate:Fire("Open")
            croomfieldstate(false)
        end

        if cellsclear then 
            cellsfieldstate(false)
            exitgate:Fire("Open")
        end

        if cellsclear or croomclear then
            hook.Add("AcceptInput",self,function(self,ent,input)
                if input == "Start" then
                    local name = ent:GetName()
                    if name == "lcs_message_room5_entry" or name == "lcs_message_croom2_search" then
                        apAdventure.SendNotification("You have already cleared this wave and can skip it by not touching the turrets.",3,10)
                        timer.Simple(1,function() apAdventure.SendNotification("The force fields are down and won't turn on unless you decide to start the wave again.",3,10) end)
                        hook.Remove("AcceptInput",self)
                    end
                end
            end)
        end

    end
}