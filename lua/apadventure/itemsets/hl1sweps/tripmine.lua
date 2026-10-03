local ITEM = {}

ITEM.Name = "Tripmine"
ITEM.Type = "Weapon"
ITEM.Groups = {}
ITEM.MinAmt = 1
ITEM.ConditionalCapabilities = {
	["Ammo_TripMine"] = {"BlastDamage","Trap","MediumDamageExplosion","MediumSizeExplosion"}
}

ITEM.Class = "weapon_hl1_tripmine"

return ITEM