local ITEM = {}

ITEM.Name = "Grenades"
ITEM.Type = "Weapon"
ITEM.Groups = {
	"Grenade"
}
ITEM.MinAmt = 1
ITEM.ConditionalCapabilities = {
	["Ammo_Grenade"] = {"MediumAOE","BlastDamage","ShortArcProjectile","SmallProjectile","StrongExplosion","MediumSizeExplosion"}
}
ITEM.StartGroup = { Grenade = 10 }

ITEM.Class = "weapon_hl1_handgrenade"

return ITEM