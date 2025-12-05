AddCSLuaFile()

ENT.PrintName = "#apadventure.entity.exit"
ENT.Editable = true

DEFINE_BASECLASS("base_gmodentity")

function ENT:SetupDataTables()
    self:NetworkVar("String",0,"Region",{KeyName="region",Edit={type="String",waitforenter=true}})
    self:NetworkVar("String",1,"ExitName",{KeyName="exitname",Edit={type="String",waitforenter=true}})
end

function ENT:Initialize()
    BaseClass.Initialize(self)
    self:SetModel("models/apadventure/frame.mdl")
    self:SetCollisionGroup( COLLISION_GROUP_WORLD )
    self:PhysicsInit(SOLID_VPHYSICS)
    self.CopyRegionName = self.GetRegion
    self.CopyConnectionName = self.GetExitName
end