local ITEM = {}

ITEM.Name = "Crossbow"
ITEM.Type = "Weapon"
ITEM.Groups = {
    "Crossbow"
}
ITEM.MinAmt = 1
ITEM.ConditionalCapabilities = {
    ["Ammo_XBowBolt"] = {"StrongLongRange","BulletDamage","NeverGibDamage","VeryFastProjectile","TinyProjectile"}
}

ITEM.Class = "weapon_crossbow"

return ITEM