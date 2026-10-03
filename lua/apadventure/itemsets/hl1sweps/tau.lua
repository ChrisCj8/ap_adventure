local ITEM = {}

ITEM.Name = "Tau Cannon"
ITEM.Type = "Weapon"
ITEM.Groups = {
	"Energy Weapon",
	"Railgun"
}
ITEM.MinAmt = 1
ITEM.ConditionalCapabilities = {
	["Ammo_Uranium"] = {"EnergyBeamDamage","StrongLongRange","StrongMidRange"}
}

ITEM.Class = "weapon_hl1_gauss"

return ITEM