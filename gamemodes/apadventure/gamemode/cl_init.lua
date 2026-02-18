include("shared.lua")

net.Receive("apAdv_BHopUpdate", function() 
    APADV_BHOP = net.ReadBool()
end)

list.Set("DesktopWindows","apAdventureConnect",{
    icon = "apadventure/apicon64.png",
    title = "apAdventure Connection",
    width = 400,
    height = 500,
    init = function(icon, window)
        include("apadventure/gamemode/ui/connect.lua")(window)
    end
})

local warnred = Color(255,0,0)
local scrh, scrw = ScrH(), ScrW()

APADV_NOCONNECTWARN = APADV_NOCONNECTWARN or vgui.Create("DLabel")

APADV_NOCONNECTWARN:SetPos(100,100)
APADV_NOCONNECTWARN:SetText("This Game is currently not connected to an Archipelago Server.")
APADV_NOCONNECTWARN:SetSize(scrw-120,100)
APADV_NOCONNECTWARN:SetTextColor(warnred)
APADV_NOCONNECTWARN:SetFont("HudDefault")

APADV_NOCONNECTWARN2 = APADV_NOCONNECTWARN2 or vgui.Create("DLabel")

APADV_NOCONNECTWARN2:SetPos(100,140)
APADV_NOCONNECTWARN2:SetText("The Server Host/Admin can connect the game to a Server via the Connection Window in the Context Menu (press C).")
APADV_NOCONNECTWARN2:SetSize(scrw-120,100)
APADV_NOCONNECTWARN2:SetTextColor(warnred)
APADV_NOCONNECTWARN2:SetFont("Trebuchet18")

--[[ APADV_NOCONNECTWARN:SetVisible(false)
APADV_NOCONNECTWARN2:SetVisible(false) ]]

net.Receive("ApAdvConnectionState", function() 
    local connected = net.ReadBool()
    APADV_NOCONNECTWARN:SetVisible(!connected)
    APADV_NOCONNECTWARN2:SetVisible(!connected)
end)

local sv_cheats = GetConVar("sv_cheats")

function GM:SpawnMenuOpen()
    return sv_cheats:GetBool()
end