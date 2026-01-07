if !apAdventure.EditMode then return end

AddCSLuaFile()

ENT.PrintName = "#apadventure.entity.location"
ENT.Editable = true

DEFINE_BASECLASS("base_gmodentity")

function ENT:SetupDataTables()
    self:NetworkVar("String",0,"Region",{KeyName="region",Edit={type="String",waitforenter=true}})
    self:NetworkVar("String",1,"LctnName",{KeyName="lctnname",Edit={type="String",waitforenter=true}})
    self:NetworkVar("Bool",0,"IsDummy",{KeyName="isdummy",Edit={type="Boolean"}})
end

local bboxmins = Vector(-10,-10,0)
local bboxmaxs = Vector(10,10,20)

function ENT:Initialize()
    BaseClass.Initialize(self)
    self:SetModel("models/apapdventure/location_pickup.mdl")
    self:SetCollisionGroup( COLLISION_GROUP_WORLD )
    self:PhysicsInitBox( bboxmins,bboxmaxs )
    local phys = self:GetPhysicsObject()
    self.boundmins, self.boundmaxs = self:GetCollisionBounds()
    self.CopyRegionName = self.GetRegion
end

if CLIENT then

    function ENT:Draw(fl)
        local textfacing = apAdventure.TextFacing
        self:DrawModel(fl)
        local pos = self:GetPos()
        cam.Start3D2D(pos,textfacing,.5)
            draw.DrawText("Region: "..self:GetRegion().."\n Name: "..self:GetLctnName()..(self:GetIsDummy() and "\nDUMMY" or ""),"BudgetLabel",0,-100,color_white,TEXT_ALIGN_CENTER)
        cam.End3D2D()
        render.DrawWireframeBox(pos,angle_zero,self.boundmins,self.boundmaxs,color_white)
    end

    return
end