include("shared.lua")
include("apadventure/gamemode/ui/tracker.lua")

net.Receive("apAdv_BHopUpdate", function()
    APADV_BHOP = net.ReadBool()
end)

list.Set("DesktopWindows","apAdventureConnect",{
    icon = "archipelago/ap64.png",
    title = "#apadventure.connect.title",
    width = 400,
    height = 500,
    init = function(icon, window)
        include("apadventure/gamemode/ui/connect.lua")(window)
    end
})

local json = ""
net.Receive("ApAdvRequirements",function()
    json = json..net.ReadString()
    if net.ReadBool() then
        local reqs = util.JSONToTable(json,false,true)
        json = ""
        local ui = APADV_REQUIREMENTS and APADV_REQUIREMENTS.ui
        APADV_REQUIREMENTS = reqs
        APADV_REQUIREMENTS.ui = ui
        if ispanel(ui) and IsValid(ui) then
            ui:OnRequirementsUpdate()
        end
    end
end)

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

local locstr = language.GetPhrase
local seentickmsg = {}
local green = Color(40,255,40)
local function tickmsg(gr,val)
    seentickmsg[gr] = true
    chat.AddText(color_white, locstr("apadventure.ticknotif.a"),
    green, gr,
    color_white, locstr("apadventure.ticknotif.b"),
    green, val,
    color_white, locstr("apadventure.ticknotif.c"), "\n", string.Interpolate(locstr("apadventure.ticknotif.help"),{t=val}))
end

net.Receive("ApAdvTickrateNotif", function()
    local gr = net.ReadString()
    local val = net.ReadFloat()
    if APADV_POSTENTINIT then
        if seentickmsg[gr] then return end
        tickmsg(gr,val)
    else
        hook.Add("InitPostEntity","ApAdv_TickRateNotif",function() timer.Simple(3,function() tickmsg(gr,val) end) end)
    end
end)

local sv_cheats = GetConVar("sv_cheats")

function GM:SpawnMenuOpen()
    return sv_cheats:GetBool()
end