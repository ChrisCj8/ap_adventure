local ITEM = {}

ITEM.Name = "Pistol"
ITEM.Type = "Weapon"
ITEM.Groups = {"Pistol"}
ITEM.MinAmt = 1
ITEM.ConditionalCapabilities = {
    ["Ammo_Pistol"] = {"HitScan","WeakShortRange","WeakMidRange","WimpyLongRange","BulletDamage","NeverGibDamage"}
}
ITEM.StartGroup = { Pistol = 50 }

ITEM.Class = "doom_weapon_pistol"

return ITEM