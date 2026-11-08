AddCSLuaFile()

ENT.PrintName = "apAdventure Exit"

DEFINE_BASECLASS("base_gmodentity")

function ENT:Initialize()
	BaseClass.Initialize(self)
	self:SetModel("models/apadventure/frame.mdl")
	self:PhysicsInitStatic(SOLID_VPHYSICS)
	self:SetCustomCollisionCheck(true)
	if CLIENT then return end
	self:SetUseType(SIMPLE_USE)
end

function ENT:ResetIcon()
	self:SetSubMaterial(1,self:GetSubMaterial(1))
end

function ENT:ApAdvCustomCollision(ent)
	return ent:IsPlayer()
end

if CLIENT then return end

function ENT:Use(activator,caller,usetype,val)
	local exitn = self.ExitName
	if exitn then APADV.UseExit(exitn,true) end
end

function ENT:SetMapIcon(map)
	apAdventure.GetMapIconMat(map, function(mat)
		self:SetSubMaterial(1,mat)
	end)
end