local ITEM = {}

ITEM.Name = "SMG"
ITEM.Type = "Weapon"
ITEM.Groups = {
	"Submachine Gun"
}
ITEM.MinAmt = 1
ITEM.ConditionalCapabilities = {
	["Ammo_9mmRound"] = {"HitScan","DecentShortRange","DecentMidRange","BulletDamage","GratePass"},
	["Ammo_MP5_Grenade"] = {"DecentAOE","BlastDamage"}
}

ITEM.Class = "weapon_hl1_mp5"

return ITEM