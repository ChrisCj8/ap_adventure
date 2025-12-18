local ITEM = {}

ITEM.Name = "SMG"
ITEM.Weapon = true
ITEM.Groups = {
    "Submachine Gun"
}
ITEM.MinAmt = 1
ITEM.AmmoCapabilities = {
    ["Ammo_SMG1"] = {"DecentShortRange","DecentMidRange","BulletDamage"},
    ["Ammo_SMG1_Grenade"] = {"DecentAOE","BlastDamage"}
}

ITEM.Class = "weapon_smg1"

return ITEM