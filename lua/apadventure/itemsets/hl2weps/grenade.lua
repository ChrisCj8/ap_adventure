local ITEM = {}

ITEM.Name = "Grenades"
ITEM.Weapon = true
ITEM.Groups = {
    "Grenade"
}
ITEM.MinAmt = 1
ITEM.AmmoCapabilities = {
    ["Grenade"] = {"DecentAOE","ExplosiveDamage"}
}

ITEM.Class = "weapon_frag"

return ITEM