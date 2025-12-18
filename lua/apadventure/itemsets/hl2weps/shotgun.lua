local WEP = {}

WEP.Name = "Shotgun"
WEP.Weapon = true
WEP.Groups = {
    "Shotgun"
}
WEP.MinAmt = 1
WEP.AmmoCapabilities = {
    ["Ammo_Buckshot"] = {"StrongShortRange","BulletDamage","BuckshotDamage"}
}

WEP.Class = "weapon_shotgun"

return WEP