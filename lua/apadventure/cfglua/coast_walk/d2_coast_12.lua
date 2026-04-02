local inhook = {}
local entsbyname = ents.FindByName
local entbyid = ents.GetMapCreatedEntity

if APADV_ENTRNAME == "Sewer" then
    entsbyname("tunnel_zombie")[1]:Remove()

    --local trigger = entbyid()

    local trigger = entbyid(1460) --beach entrance trigger

    trigger = entbyid(1532) -- turret 1 -> 2 trigger
    
    trigger:Fire("AddOutput","OnTrigger patrol_1_assault1_relay:Trigger")

    trigger = entbyid(1547) -- turret 2 -> 3 trigger
    trigger:Fire("AddOutput","OnTrigger bunker_1_template_spawner:ForceSpawn")

    local bunkerhilltrigger = entbyid(1978)
    bunkerhilltrigger:SetName("bunker2trigger")

    local prebunkertrigger = entbyid(2266)

    local innerbunkertrigger = entbyid(1943)

    innerbunkertrigger:Fire("AddOutput","OnTrigger bunker2trigger:Disable")
    innerbunkertrigger:Fire("AddOutput","OnTrigger bunker_2_template:ForceSpawn")
    innerbunkertrigger:Fire("AddOutput","OnTrigger bunker_2_bugbait:Enable")
    innerbunkertrigger:Fire("AddOutput","OnTrigger bunker_2_force_off:Enable")

    local innerbunkertrigger = entbyid(1871)

    local innerbunkertrigger = entbyid(1933)

    local innerbunkertrigger = entbyid(1918)

    local innerbunkertrigger = entbyid(1955)

    local bunkerexittrigger_inner = entbyid(1956)

    local bunkerexittrigger_outer = entbyid(2041)

    local betweenturretstrigger = entbyid(2188)
    betweenturretstrigger:Fire("AddOutput","OnTrigger turret_6:Deactivate")
    betweenturretstrigger:Fire("AddOutput","OnTrigger turret_6_enemyfinder:TurnOff")
    betweenturretstrigger:Fire("AddOutput","OnTrigger turret_6_spotlight:LightOff")
    betweenturretstrigger:Fire("AddOutput","OnTrigger turret_7:Deactivate")
    betweenturretstrigger:Fire("AddOutput","OnTrigger turret_7_enemyfinder:TurnOff")
    betweenturretstrigger:Fire("AddOutput","OnTrigger turret_7_spotlight:LightOff")
    betweenturretstrigger:Fire("AddOutput","OnTrigger bunker_4_spawner:Spawn")
    betweenturretstrigger:Fire("AddOutput","OnTrigger bunker_3_spawner:Spawn")
    betweenturretstrigger:Fire("AddOutput","OnTrigger bigbunker_soldier_template_spawner:ForceSpawn")

    local battlefieldentrtrigger = entbyid(2180)

    local battlefieldscndtrigger = entbyid(2237)

    local battlefieldthrdtrigger = entbyid(2231)

    local crabtrigger = entbyid(2615)

    entsbyname("zombie_template")[1]:Fire("ForceSpawn")
    entsbyname("pipes_soldiers")[1]:Fire("ForceSpawn")
    entsbyname("assault_template_spawner")[1]:Fire("ForceSpawn")
    --[[ timer.Simple(.3,function() 
        for k,v in ipairs(entsbyname("field_spawner_1")) do
            v:Fire("Disable")
        end
    end) ]]
    entsbyname("assault_reinforcement_spawner")[1]:Remove()

    print("added outputs")

    --[[ inhook["crack_crabs"] = {
        input = "Spawn",
        func = function() 
            print("guh")
            entsbyname("zombie_template")[1]:Fire("ForceSpawn")
            entsbyname("pipes_soldiers")[1]:Fire("ForceSpawn")
            -- one of these next two lines crashed my entire fucking pc lol
            --entsbyname("dropship_template_spawner")[1]:Fire("ForceSpawn")
            entsbyname("assault_template_spawner")[1]:Fire("ForceSpawn")
            --entsbyname("assault_reinforcement_spawner")[1]:Fire("ForceSpawn")
        end
    }
    inhook["overwatch_4"] = {
        input = "PlaySound",
        func = function() 
            entsbyname("manhack2_template")[1]:Fire("ForceSpawn")
            --entsbyname("manhack_suprise_spawner")[1]:Fire("ForceSpawn")
        end
    }
    inhook["idk"] = {
        input = "PlaySound",
        func = function() 
            entsbyname("flare1")[1]:Fire("Launch")
            entsbyname("bigbunker_soldier_template_spawner")[1]:Fire("ForceSpawn")
        end
    }
    inhook["antspawn_nodes_10"] = {
        input = "EnableHint",
        func = function() 
            entsbyname("flare1")[1]:Fire("Launch")
            entsbyname("bunker_3_spawner")[1]:Fire("Spawn")
            for k,v in ipairs(entsbyname("bunker_4_spawner")) do v:Fire("Spawn") end
        end
    }
    inhook["antspawn_nodes_8"] = {
        input = "EnableHint",
        func = function() 
            --entsbyname("bigbunker_soldier_template_spawner")[1]:Fire("ForceSpawn")
        end
    } ]]
end

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

        --[[ hook.Add("AcceptInput",self,function(self,ent,input) 
            local entry = inhook[ent:GetName()]
            if entry and entry.input == input then
                entry.func()
                inhook[ent:GetName()] = nil
                if !next(inhook) then hook.Remove("AcceptInput",self) end
            end
        end) ]]

        
    end,
    OnFullConnect = function(self)
        if APADV.MapLocationStatus("Disable All Thumpers") then return end

        local thumpers = {
            thumper_1_button = true,
            thumper_2_button = true,
            thumper_3_button = true,
        }

        hook.Add("AcceptInput","APADV_ThumperCheck",function(ent,input)
            if input == "Use" and thumpers[ent:GetName()] then
                thumpers[ent:GetName()] = nil
                if !next(thumpers) then
                    APADV.SendMapLocation("Disable All Thumpers")
                    hook.Remove("AcceptInput","APADV_ThumperCheck")
                end
            end
        end)
    end,
    CfgUnload = function(self)
        hook.Remove("AcceptInput","APADV_ThumperCheck")
    end
}