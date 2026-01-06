local ITEM = {}

ITEM.Name = "S.L.A.M."
ITEM.Type = "Weapon"
ITEM.Groups = {}
ITEM.MinAmt = 1
ITEM.ConditionalCapabilities = {
    ["Ammo_slam"] = {"BlastDamage"},
}

ITEM.Class = "weapon_slam"

return ITEM