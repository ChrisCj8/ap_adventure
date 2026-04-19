local ITEM = {}

ITEM.Name = "9mm Pistol"
ITEM.Type = "Weapon"
ITEM.Groups = {
    "Pistol"
}
ITEM.MinAmt = 1
ITEM.ConditionalCapabilities = {
    ["Ammo_Pistol"] = {"DecentShortRange","WeakMidRange","WimpyLongRange","MidRangeSpray","BulletDamage","WeakDamage"}
}
ITEM.StartGroup = { Pistol = 50 }

ITEM.Class = "weapon_pistol"

return ITEM