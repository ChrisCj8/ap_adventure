local ITEM = {}

ITEM.Name = "Fist"
ITEM.Type = "Weapon"
ITEM.Groups = {"Melee Weapon"}
ITEM.MinAmt = 1
ITEM.Capabilities = {"WeakMelee","ClubDamage"}
ITEM.ConditionalCapabilities = {
    ["Doom_Berserk"] = {"StrongMelee"}
}
ITEM.StartGroup = { Melee = 100 }

ITEM.Class = "doom_weapon_fist"

return ITEM