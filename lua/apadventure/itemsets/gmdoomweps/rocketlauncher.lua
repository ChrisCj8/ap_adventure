local ITEM = {}

ITEM.Name = "Rocket Launcher"
ITEM.Type = "Weapon"
ITEM.Groups = {"Rocket Launcher"}
ITEM.MinAmt = 1
ITEM.ConditionalCapabilities = {
    ["Ammo_RPG_Round"] = {"MediumAOE","BlastDamage","SlowProjectile","MediumSizeExplosion","MediumSizeProjectile","FlyingProjectile","MediumDamageExplosion"}
}

ITEM.Class = "doom_weapon_missile"

return ITEM