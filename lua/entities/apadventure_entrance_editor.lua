
AddCSLuaFile()

ENT.PrintName = "AP Adventure Entrance"
ENT.Editable = true

DEFINE_BASECLASS("base_gmodentity")

function ENT:SetupDataTables()
    self:NetworkVar("String",0,"Region",{KeyName="region",Edit={type="String",waitforenter=true}})
    self:NetworkVar("String",1,"EntrName",{KeyName="entrname",Edit={type="String",waitforenter=true}})
end

function ENT:Initialize()
    BaseClass.Initialize(self)
    self:SetModel("models/props_lab/huladoll.mdl")
    self:SetCollisionGroup( COLLISION_GROUP_WORLD )
    self:PhysicsInitStatic( SOLID_VPHYSICS )
    self.boundmins, self.boundmaxs = self:GetCollisionBounds()
    self.CopyRegionName = self.GetRegion
    self.CopyConnectionName = self.GetEntrName
end

if CLIENT then

    function ENT:Draw(fl)
        self:DrawModel(fl)
        --render.DepthRange(0,0)
        --render.OverrideDepthEnable(true,true)
        local textfacing = apAdventure.TextFacing
        local pos = self:GetPos()
        cam.Start3D2D(pos,textfacing,.5)
            draw.DrawText("Region: "..self:GetRegion().."\n Name: "..self:GetEntrName(),"BudgetLabel",0,-100,color_white,TEXT_ALIGN_CENTER)
        cam.End3D2D()
        --render.DrawWireframeBox(pos,angle_zero,self.boundmins,self.boundmaxs,color_white)
        --render.OverrideDepthEnable(false,false)
        --render.DepthRange(0,1)
    end

    return
end