local ITEM = {}

ITEM.Name = "SMG"
ITEM.Type = "Weapon"
ITEM.Groups = {
    "Submachine Gun"
}
ITEM.MinAmt = 1
ITEM.ConditionalCapabilities = {
    ["Ammo_SMG1"] = {"DecentShortRange","DecentMidRange","BulletDamage"},
    ["Ammo_SMG1_Grenade"] = {"DecentAOE","BlastDamage"}
}
ITEM.StartGroup = { SMG = 10 }

ITEM.Class = "weapon_smg1"

return ITEM