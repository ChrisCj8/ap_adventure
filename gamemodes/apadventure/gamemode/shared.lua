DeriveGamemode("sandbox")

GM.Name = "apAdventure"
GM.Author = "ChrisCj"
GM.Website = "N/A"
GM.Email = "N/A"

local BASEGM = baseclass.Get("gamemode_base")
local SBOX = baseclass.Get("gamemode_sandbox")

function GM:Initialize()
    APADV_BHOP = false
end

function GM:InitPostEntity()
    APADV_POSTENTINIT = true
end

local sv_cheats = GetConVar("sv_cheats")

function GM:PlayerNoClip(ply,state)
    if !state then return true end
    if sv_cheats:GetBool() then return true end
end

local permhooks = {
    "CanTool",
    "CanDrive",
    "CanArmDupe",
    "CanProperty"
}

for k,v in ipairs(permhooks) do
    local ogfunc = SBOX[v]
    GM[v] = function (self,ply,...)
        if !sv_cheats:GetBool() then return false end
        return ogfunc(self,ply,...)
    end
end

function GM:SetupMove(ply,mv,cmd)
    if BASEGM.SetupMove(self,ply,mv,cmd) then return true end

    if !APADV_BHOP then return end

    local held = mv:KeyDown(IN_JUMP)

    if ply.APAdvWasJumping and held and !ply:OnGround() and !(ply:WaterLevel() > 1) then
        mv:SetButtons(mv:GetButtons()-IN_JUMP)
    end

    ply.APAdvWasJumping = held

end

function GM:ShouldCollide(ent1,ent2)
	local ent1func, ent1prio, ent2func, ent2prio = ent1.ApAdvCustomCollision, ent1.ApAdvCustomCollisionPrio or 0, ent2.ApAdvCustomCollision, ent2.ApAdvCustomCollisionPrio or 0
	if isfunction(ent2func) and ent2prio > ent1prio then
		local out = ent2func(ent2,ent1)
		if isbool(out) then return out end
	end
	if isfunction(ent1func) then
		local out = ent1func(ent1,ent2)
		if isbool(out) then return out end
	end
	return true
end

include("player_class/player_apadv.lua")