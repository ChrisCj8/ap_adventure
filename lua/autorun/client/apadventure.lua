
include("apadventure/cl/mapiconmat.lua")

if engine.ActiveGamemode() == "sandbox" then 
    apAdventure.EditMode = true
    include("apadventure/editmode_shared.lua")
    include("apadventure/cl/editmode.lua")
end