local ITEM = {}

ITEM.Name = "Satchel Charge"
ITEM.Type = "Weapon"
ITEM.Groups = {}
ITEM.MinAmt = 1
ITEM.ConditionalCapabilities = {
	["Ammo_Satchel"] = {"BlastDamage","RemoteBomb","MediumDamageExplosion","MediumSizeExplosion"}
}

ITEM.Class = "weapon_hl1_satchel"

return ITEM