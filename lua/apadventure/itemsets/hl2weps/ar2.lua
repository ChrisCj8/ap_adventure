local ITEM = {}

ITEM.Name = "Pulse Rifle"
ITEM.Type = "Weapon"
ITEM.Groups = {
    "Assault Rifle"
}
ITEM.MinAmt = 1
ITEM.ConditionalCapabilities = {
    ["Ammo_AR2"] = {"DecentShortRange","DecentMidRange","BulletDamage","HitScan"},
    ["Ammo_AR2AltFire"] = {"DissolveDamage","MediumSizeProjectile","FastProjectile","StrongMidRange"}
}

ITEM.Class = "weapon_ar2"

return ITEM