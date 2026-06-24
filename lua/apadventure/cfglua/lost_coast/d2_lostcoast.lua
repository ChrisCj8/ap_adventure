return {
    CfgUnload = function(self)
        hook.Remove("AcceptInput","APADV_lostcoast_gunshiplctn")
        hook.Remove("AcceptInput","APADV_lostcoast_mortarlctn")
    end,
    OnFullConnect = function(self)
        if APADV.MapLocationStatus("Heli Destroyed") == false then
            hook.Add("AcceptInput","APADV_lostcoast_gunshiplctn",function(_,_,_,caller)
                if !IsValid(caller) or caller:GetName() != "crashtarget" then return end
                APADV.SendMapLocation("Heli Destroyed")
                hook.Remove("AcceptInput","APADV_lostcoast_gunshiplctn")
            end)
        end
        if APADV.MapLocationStatus("Jam the Mortar") == false then
            hook.Add("AcceptInput","APADV_lostcoast_mortarlctn",function(ent)
                if ent:GetName() != "relay_gunbolt_broken" then return end
                APADV.SendMapLocation("Jam the Mortar")
                hook.Remove("AcceptInput","APADV_lostcoast_mortarlctn")
            end)
        end
    end
}