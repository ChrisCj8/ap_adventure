local ITEM = {}

ITEM.Name = "SMG"
ITEM.Weapon = true
ITEM.Groups = {
    "Submachine Gun"
}
ITEM.MinAmt = 1
ITEM.AmmoCapabilities = {
    ["SMG1"] = {"DecentShortRange","DecentMidRange"},
    ["SMG1_Grenade"] = {"DecentAOE","ExplosiveDamage"}
}

ITEM.Class = "weapon_smg1"

return ITEM