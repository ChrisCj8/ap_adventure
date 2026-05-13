local ITEM = {}

ITEM.Name = "BFG 9000"
ITEM.Type = "Weapon"
ITEM.Groups = {"Super Weapon"}
ITEM.MinAmt = 1
-- not sure how to handle the bfg, it takes a lot of ammo to use so giving it too many capabilities might
-- result in logic expecting people to use it when there's not enough ammo around so i'm playing it safe
ITEM.ConditionalCapabilities = {  
    ["Ammo_AR2"] = {"EnergyBeamDamage"}
}

ITEM.Class = "doom_weapon_bfg"

return ITEM