local ITEM = {}

ITEM.Name = "Shotgun"
ITEM.Type = "Weapon"
ITEM.Groups = {"Shotgun"}
ITEM.MinAmt = 1
ITEM.ConditionalCapabilities = {
    ["Ammo_Buckshot"] = {"HitScan","DecentShortRange","BulletDamage","BuckshotDamage","NeverGibDamage"}
}

ITEM.Class = "doom_weapon_shotgun"

return ITEM