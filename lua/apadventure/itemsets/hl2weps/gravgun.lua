local ITEM = {}

ITEM.Name = "Gravity Gun"
ITEM.Type = "Weapon"
ITEM.MinAmt = 1
ITEM.Capabilities = {"WimpyShortRange"}
ITEM.ConditionalCapabilities = {
    ["Props"] = {"StrongShortRange","DecentMidRange"}
}

ITEM.Class = "weapon_physcannon"

return ITEM