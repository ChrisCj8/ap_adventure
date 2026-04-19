local ITEM = {}

ITEM.Name = "Grenades"
ITEM.Type = "Weapon"
ITEM.Groups = {
    "Grenade"
}
ITEM.MinAmt = 1
ITEM.ConditionalCapabilities = {
    ["Ammo_Grenade"] = {"DecentAOE","BlastDamage","MediumArcProjectile","PhysicsProjectile","SmallProjectile","MediumExplosion","MediumSizeExplosion"}
}
ITEM.StartGroup = { Grenade = 10 }

ITEM.Class = "weapon_frag"

return ITEM