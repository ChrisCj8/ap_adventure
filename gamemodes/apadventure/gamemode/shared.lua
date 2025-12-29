DeriveGamemode("sandbox")

GM.Name = "apAdventure"
GM.Author = "ChrisCj"
GM.Website = "N/A"
GM.Email = "N/A"

local BASEGM = baseclass.Get("gamemode_base")

function GM:Initialize()
    APADV_BHOP = false
end

function GM:InitPostEntity()
    ApAdvPostEntInit = true
end

function GM:SetupMove(ply,mv,cmd)
    if BASEGM.SetupMove(self,ply,mv,cmd) then return true end

    if APADV_BHOP and mv:KeyDown(IN_JUMP) and !ply:OnGround() and !(ply:WaterLevel() > 1) then
        mv:SetButtons(mv:GetButtons()-IN_JUMP)
    end
end

include("player_class/player_apadv.lua")