local ITEM = {}

ITEM.Name = "9mm Pistol"
ITEM.Type = "Weapon"
ITEM.Groups = {
	"Pistol"
}
ITEM.MinAmt = 1
ITEM.ConditionalCapabilities = {
	["Ammo_9mmRound"] = {"HitScan","DecentShortRange","WeakMidRange","WimpyLongRange","BulletDamage","WeakDamage","NeverGibDamage"}
}
ITEM.StartGroup = { Pistol = 50 }

ITEM.Class = "weapon_hl1_glock"

return ITEM