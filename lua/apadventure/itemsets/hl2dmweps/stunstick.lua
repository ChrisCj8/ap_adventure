local ITEM = {}

ITEM.Name = "Stunstick"
ITEM.Type = "Weapon"
ITEM.Groups = {
    "Melee Weapon"
}
ITEM.MinAmt = 1
ITEM.Capabilities = {"DecentMelee","ClubDamage"}
ITEM.StartGroup = { Melee = 10 }

ITEM.Class = "weapon_stunstick"

return ITEM