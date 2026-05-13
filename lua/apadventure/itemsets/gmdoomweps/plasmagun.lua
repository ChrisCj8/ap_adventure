local ITEM = {}

ITEM.Name = "Plasma Gun"
ITEM.Type = "Weapon"
ITEM.Groups = {"Energy Weapon"}
ITEM.MinAmt = 1
ITEM.ConditionalCapabilities = {
    ["Ammo_AR2"] = {"EnergyBeamDamage","MediumSpeedProjectile","FlyingProjectile","MediumSizeProjectile","StrongMidRange","StrongShortRange"}
}

ITEM.Class = "doom_weapon_plasma"

return ITEM