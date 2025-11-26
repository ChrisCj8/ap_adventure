AddCSLuaFile()

ENT.PrintName = "AP Adventure Location"
ENT.Editable = true

DEFINE_BASECLASS("base_gmodentity")

function ENT:SetupDataTables()
    self:NetworkVar("String",0,"Region",{KeyName="region",Edit={type="String",waitforenter=true}})
    self:NetworkVar("String",1,"LctnName",{KeyName="lctnname",Edit={type="String",waitforenter=true}})
end

function ENT:Initialize()
    BaseClass.Initialize(self)
    self:SetModel("models/hunter/blocks/cube05x05x05.mdl")
    self:SetCollisionGroup( COLLISION_GROUP_WORLD )
    self:PhysicsInitStatic( SOLID_BBOX )
    local phys = self:GetPhysicsObject()
    self.boundmins, self.boundmaxs = self:GetCollisionBounds()
end

if CLIENT then

    

    function ENT:Draw(fl)
        local textfacing = apAdventure.TextFacing
        self:DrawModel(fl)
        local pos = self:GetPos()
        cam.Start3D2D(pos,textfacing,.5)
            draw.DrawText("Region: "..self:GetRegion().."\n Name: "..self:GetLctnName(),"BudgetLabel",0,-100,color_white,TEXT_ALIGN_CENTER)
        cam.End3D2D()
        render.DrawWireframeBox(pos,angle_zero,self.boundmins,self.boundmaxs,color_white)
    end

end