local ITEM = {}

ITEM.Name = "RPG Launcher"
ITEM.Type = "Weapon"
ITEM.Groups = {
    "Rocket Launcher"
}
ITEM.MinAmt = 1
ITEM.ConditionalCapabilities = {
    ["Ammo_RPG_Round"] = {"DecentAOE","BlastDamage","FlyingProjectile","HeliKiller","MediumSizeProjectile","StrongExplosion"}
}

ITEM.Class = "weapon_rpg"

return ITEM