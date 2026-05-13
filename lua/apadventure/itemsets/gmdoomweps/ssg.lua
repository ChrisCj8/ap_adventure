local ITEM = {}

ITEM.Name = "Super Shotgun"
ITEM.Type = "Weapon"
ITEM.Groups = {"Shotgun"}
ITEM.MinAmt = 1
ITEM.ConditionalCapabilities = {
    ["Ammo_Buckshot"] = {"HitScan","StrongShortRange","BulletDamage","BuckshotDamage","NeverGibDamage"}
}

ITEM.Class = "doom_weapon_supershotgun"

return ITEM