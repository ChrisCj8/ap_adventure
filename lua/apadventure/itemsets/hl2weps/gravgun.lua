local WEP = {}

WEP.Name = "Gravity Gun"
WEP.Weapon = true
WEP.MinAmt = 1
WEP.Capabilities = {"WimpyShortRange"}
WEP.AmmoCapabilities = {
    ["Props"] = {"StrongShortRange","DecentMidRange"}
}

WEP.Class = "weapon_physcannon"

return WEP