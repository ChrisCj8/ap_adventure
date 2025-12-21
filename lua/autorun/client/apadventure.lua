
include("apadventure/cl/mapiconmat.lua")

if engine.ActiveGamemode() == "sandbox" then 
    apAdventure.EditMode = true
    include("apadventure/cl/editmode.lua")
end