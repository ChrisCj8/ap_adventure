local ITEM = {}

ITEM.Name = "Shotgun"
ITEM.Type = "Weapon"
ITEM.Groups = {
    "Shotgun"
}
ITEM.MinAmt = 1
ITEM.ConditionalCapabilities = {
    ["Ammo_Buckshot"] = {"StrongShortRange","BulletDamage","BuckshotDamage"}
}
ITEM.StartGroup = { Shotgun = 5 }

ITEM.Class = "weapon_shotgun"

return ITEM