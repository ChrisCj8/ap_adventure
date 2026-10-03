local ITEM = {}

ITEM.Name = "Gluon Gun"
ITEM.Type = "Weapon"
ITEM.Groups = {
	"Super Weapon"
}
ITEM.MinAmt = 1
ITEM.ConditionalCapabilities = {
	["Ammo_Uranium"] = {"StrongShortRange","StrongMidRange","EnergyBeamDamage","AlwaysGibDamage"}
}

ITEM.Class = "weapon_hl1_egon"

return ITEM