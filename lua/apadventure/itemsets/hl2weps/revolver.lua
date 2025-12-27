local ITEM = {}

ITEM.Name = ".357 Magnum"
ITEM.Weapon = true
ITEM.Groups = {
    "Magnum Pistol", -- not gonna put this in the regular pistol group since i feel like people are usually searching for something with more common ammo when they're asking for a pistol
    "Revolver"
}
ITEM.MinAmt = 1
ITEM.ConditionalCapabilities = {
    ["Ammo_357"] = {"StrongShortRange","StrongMidRange","BulletDamage"}
}

ITEM.Class = "weapon_357"

return ITEM