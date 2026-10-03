local ITEM = {}

ITEM.Name = "RPG Launcher"
ITEM.Type = "Weapon"
ITEM.Groups = {
	"Rocket Launcher"
}
ITEM.MinAmt = 1
ITEM.ConditionalCapabilities = {
	["Ammo_RPG_Round"] = {"DecentAOE","BlastDamage","AirboatDamage","Projectile","FlyingProjectile","HeliKiller"}
}

ITEM.Class = "weapon_hl1_rpg"

return ITEM