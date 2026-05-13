local ITEM = {}

ITEM.Name = "Chaingun"
ITEM.Type = "Weapon"
ITEM.Groups = {}
ITEM.MinAmt = 1
ITEM.ConditionalCapabilities = {
    ["Ammo_Pistol"] = {"HitScan","DecentShortRange","DecentMidRange","DecentLongRange","BulletDamage","NeverGibDamage"}
}

ITEM.Class = "doom_weapon_chaingun"

return ITEM