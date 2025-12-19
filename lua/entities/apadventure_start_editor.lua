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
    self:SetModel("models/props_lab/huladoll.mdl")
    self:SetCollisionGroup( COLLISION_GROUP_WORLD )
    self:PhysicsInitStatic( SOLID_VPHYSICS )
    self.CopyRegionName = self.GetRegion
end

if CLIENT then

    local start3d2d = cam.Start3D2D
    local end3d2d = cam.End3D2D
    local drawtext = draw.DrawText

    function ENT:Draw(fl)
        self:DrawModel(fl)
        --render.DepthRange(0,0)
        --render.OverrideDepthEnable(true,true)
        local textfacing = apAdventure.TextFacing
        local pos = self:GetPos()
        start3d2d(pos,textfacing,.5)
            drawtext("Region: "..self:GetRegion(),"BudgetLabel",0,-100,color_white,TEXT_ALIGN_CENTER)
        end3d2d()
        --render.DrawWireframeBox(pos,angle_zero,self.boundmins,self.boundmaxs,color_white)
        --render.OverrideDepthEnable(false,false)
        --render.DepthRange(0,1)
    end

    return
end