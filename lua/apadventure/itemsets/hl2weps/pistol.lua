local WEP = {}

WEP.Name = "9mm Pistol"
WEP.Weapon = true
WEP.Groups = {
    "Pistol"
}
WEP.MinAmt = 1
WEP.Ammo = {"Pistol"}
WEP.AmmoCapabilities = {
    ["Ammo_Pistol"] = {"DecentShortRange","WeakMidRange","WimpyLongRange","MidRangeSpray","BulletDamage","WeakDamage"}
}

WEP.Class = "weapon_pistol"

return WEP