local ITEM = {}

ITEM.Name = "Grenades"
ITEM.Weapon = true
ITEM.Groups = {
    "Grenade"
}
ITEM.MinAmt = 1
ITEM.AmmoCapabilities = {
    ["Ammo_Grenade"] = {"DecentAOE","BlastDamage","MidThrow"}
}

ITEM.Class = "weapon_frag"

return ITEM