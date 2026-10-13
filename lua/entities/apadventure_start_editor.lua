if !apAdventure.EditMode then return end

AddCSLuaFile()

ENT.PrintName = "#apadventure.entity.start"
ENT.Editable = true

DEFINE_BASECLASS("base_gmodentity")

function ENT:SetupDataTables()
	self:NetworkVar("String",0,"Region",{KeyName="region",Edit={type="String",waitforenter=true}})
end

function ENT:Initialize()
	BaseClass.Initialize(self)
	self:SetModel("models/apadventure/spawnpoint.mdl")
	self:SetSkin(1)
	self:SetCollisionGroup( COLLISION_GROUP_WORLD )
	self:PhysicsInitStatic( SOLID_VPHYSICS )
	self.CopyRegionName = self.GetRegion
end

if CLIENT then

	local start3d2d = cam.Start3D2D
	local end3d2d = cam.End3D2D
	local drawtext = draw.DrawText
	local drawbox = render.DrawWireframeBox
	local mins, maxs = Vector(-16,-16,0), Vector(16,16,72)
	local col = Color(50,255,50)
	local texfilt = TEXFILTER.POINT
	local pushminfilter = render.PushFilterMin
	local pushmagfilter = render.PushFilterMag
	local popminfilter = render.PopFilterMin
	local popmagfilter = render.PopFilterMag

	function ENT:Draw(fl)
		self:DrawModel(fl)
		local pos = self:GetPos()
		drawbox(pos,angle_zero,mins,maxs,col)
		start3d2d(pos,apAdventure.TextFacing,.5)
			pushminfilter(texfilt)
			pushmagfilter(texfilt)
			drawtext("Region: "..self:GetRegion(),"BudgetLabel",0,-100,color_white,TEXT_ALIGN_CENTER)
			popminfilter()
			popmagfilter()
		end3d2d()
	end

	return
end