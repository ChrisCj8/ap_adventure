ents.FindByName("churchyard_portal")[1]:Fire("Open")

hook.Add("PlayerCanPickupWeapon","ApAdv_Detect_Grigori_Shotgun",function(ply,wep) 
    if wep:GetName() == "shotgun_throw_shotgun" then
        print(tostring(ply).." just picked up grigoris shotgun")
        APADV.SendMapLocation("Gift from Grigori")
        hook.Remove("PlayerCanPickupWeapon","ApAdv_Detect_Grigori_Shotgun")
    end
end)