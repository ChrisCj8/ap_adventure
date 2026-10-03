local ITEM = {}

ITEM.Name = ".357 Magnum"
ITEM.Type = "Weapon"
ITEM.Groups = {
	"Magnum Pistol", -- not gonna put this in the regular pistol group since i feel like people are usually searching for something with more common ammo when they're asking for a pistol
	"Revolver"
}
ITEM.MinAmt = 1
ITEM.ConditionalCapabilities = {
	-- yes, it deals both nevergib and alwaysgib damage for some reason
	["Ammo_357"] = {"HitScan","StrongShortRange","StrongMidRange","DecentLongRange","BulletDamage","NeverGibDamage","AlwaysGibDamage"}
}
ITEM.StartGroup = { Magnum = 10 }

ITEM.Class = "weapon_hl1_357"

return ITEM