local ITEM = {}

ITEM.Name = "Pulse Rifle"
ITEM.Type = "Weapon"
ITEM.Groups = {
    "Assault Rifle"
}
ITEM.MinAmt = 1
ITEM.ConditionalCapabilities = {
    ["Ammo_AR2"] = {"DecentShortRange","DecentMidRange","BulletDamage"},
    ["Ammo_AR2AltFire"] = {"DissolveDamage"}
}

ITEM.Class = "weapon_ar2"

return ITEM