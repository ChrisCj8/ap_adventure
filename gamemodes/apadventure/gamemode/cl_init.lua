include("shared.lua")

net.Receive("apAdv_BHopUpdate", function() 
    APADV_BHOP = net.ReadBool()
end)

list.Set("DesktopWindows","apAdventureConnect",{
    icon = "icon16/connect.png",
    title = "apAdventure Connection",
    width = 800,
    height = 500,
    init = function(icon, window)
        include("apadventure/gamemode/ui/connect.lua")(window)
    end
})