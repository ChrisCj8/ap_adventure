DeriveGamemode("sandbox")

GM.Name = "apAdventure"
GM.Author = "ChrisCj"
GM.Website = "N/A"
GM.Email = "N/A"

function GM:Initialize()
    APADV_BHOP = false
end

function GM:InitPostEntity()
    ApAdvPostEntInit = true
end

include("player_class/player_apadv.lua")