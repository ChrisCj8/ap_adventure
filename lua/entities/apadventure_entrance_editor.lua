if !apAdventure.EditMode then return end

AddCSLuaFile()

ENT.PrintName = "#apadventure.entity.entrance"
ENT.Editable = true
ENT.APAdvAccessTableType = 1

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
    self.CopyRegionName = self.GetRegion
    self.CopyConnectionName = self.GetEntrName
end

if CLIENT then

    local start3d2d = cam.Start3D2D
    local end3d2d = cam.End3D2D
    local drawtext = draw.DrawText
    local drawbox = render.DrawWireframeBox
    local mins, maxs = Vector(-16,-16,0), Vector(16,16,72)

    function ENT:Draw(fl)
        self:DrawModel(fl)
        local pos = self:GetPos()
        drawbox(pos,angle_zero,mins,maxs,color_white)
        start3d2d(pos,apAdventure.TextFacing,.5)
            drawtext("Region: "..self:GetRegion().."\n Name: "..self:GetEntrName(),"BudgetLabel",0,-100,color_white,TEXT_ALIGN_CENTER)
        end3d2d()
    end

    return
end