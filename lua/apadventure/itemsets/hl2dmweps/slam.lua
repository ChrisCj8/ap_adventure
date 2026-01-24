local ITEM = {}

ITEM.Name = "S.L.A.M."
ITEM.Type = "Weapon"
ITEM.Groups = {}
ITEM.MinAmt = 1
ITEM.ConditionalCapabilities = {
    ["Ammo_slam"] = {"BlastDamage","Trap","RemoteBomb","MediumExplosion","MediumSizeExplosion"}
}

ITEM.Class = "weapon_slam"

return ITEM