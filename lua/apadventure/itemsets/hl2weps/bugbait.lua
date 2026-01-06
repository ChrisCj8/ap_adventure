local ITEM = {}

ITEM.Name = "Bugbait"
ITEM.Type = "Weapon"
ITEM.MinAmt = 1
ITEM.Capability = {"AntlionFriendly"}
ITEM.ConditionalCapabilities = {
    ["Antlions_Controllable"] = {}
}
ITEM.RequireCondition = true

ITEM.Class = "weapon_bugbait"

return ITEM