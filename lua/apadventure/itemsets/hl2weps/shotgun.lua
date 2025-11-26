local WEP = {}

WEP.Name = "Shotgun"
WEP.Weapon = true
WEP.Groups = {
    "Shotgun"
}
WEP.MinAmt = 1
WEP.AmmoCapabilities = {
    ["Buckshot"] = {"StrongShortRange"}
}

WEP.Class = "weapon_shotgun"

return WEP