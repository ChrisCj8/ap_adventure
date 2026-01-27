
APADV_WEPS = APADV_WEPS or {}

ApAdvWeps = ApAdvWeps or {}

function GM:PlayerCanPickupWeapon(ply,wep)
    local canpick = APADV_WEPS[wep:GetClass()]
    if !canpick then
        local ammo = wep:GetPrimaryAmmoType()
        if ammo > 0 then
            ply:GiveAmmo(wep:Clip1(),ammo)
        end
        ammo = wep:GetSecondaryAmmoType()
        if ammo > 0 then
            ply:GiveAmmo(wep:Clip2(),ammo)
        end
        wep:Remove()
    end
    return canpick
end

ApAdvWeps.OnEquip = {}

function GM:WeaponEquip(wep,ply)
    local onequip = ApAdvWeps.OnEquip[wep:GetClass()]
    if onequip then
        onequip(wep,ply)
    end
end

function ApAdvWeps.SetAvailable(class,available)
    APADV_WEPS[class] = available
    for k,v in player.Iterator() do
        if available then
            v:Give(class)
        else
            v:StripWeapon(class)
        end
    end
end