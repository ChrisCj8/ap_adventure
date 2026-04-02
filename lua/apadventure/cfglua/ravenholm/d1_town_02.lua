return {
    PostCfgLoad = function(self)
        ents.FindByName("churchyard_portal")[1]:Fire("Open")

        hook.Add("PlayerCanPickupWeapon",self,function(self, ply,wep) 
            if wep:GetName() == "shotgun_throw_shotgun" then
                APADV.SendMapLocation("Gift from Grigori")
                hook.Remove("PlayerCanPickupWeapon",self)
            end
        end)
    end
}