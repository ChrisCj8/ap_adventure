if !apAdventure.EditMode then return end

AddCSLuaFile()

ENT.PrintName = "#apadventure.entity.location"
ENT.Editable = true
ENT.AutomaticFrameAdvance = true
ENT.APAdvAccessTableType = 0

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
    self:SetModel("models/apadventure/location_pickup.mdl")
    self:SetCollisionGroup(COLLISION_GROUP_WORLD)
    self:PhysicsInitBox(bboxmins,bboxmaxs)
    local phys = self:GetPhysicsObject()
    self.boundmins, self.boundmaxs = self:GetCollisionBounds()
    self.CopyRegionName = self.GetRegion
    if CLIENT then return end
    local spin = self:AddLayeredSequence(self:LookupSequence("rotate"),1)
    local bob = self:AddLayeredSequence(self:LookupSequence("bob"),2)
    self:SetLayerPlaybackRate(spin,math.Rand(.3,.7))
    self:SetLayerPlaybackRate(bob,math.Rand(.3,.7))
end

function ENT:Think()
    self:NextThink(CurTime())
    return true
end

if CLIENT then
    local start3d2d = cam.Start3D2D
    local end3d2d = cam.End3D2D
    local drawtext = draw.DrawText
    local drawwirebox = render.DrawWireframeBox

    function ENT:Draw(fl)
        local textfacing = apAdventure.TextFacing
        self:DrawModel(fl)
        local pos = self:GetPos()
        local dummy = self:GetIsDummy()
        start3d2d(pos,textfacing,.5)
            drawtext("Region: "..self:GetRegion().."\n Name: "..self:GetLctnName()..( dummy and "\nDUMMY" or ""),"BudgetLabel",0,-100,color_white,TEXT_ALIGN_CENTER)
        end3d2d()
        if dummy then return end
        drawwirebox(pos,angle_zero,self.boundmins,self.boundmaxs,color_white)
    end

    return
end