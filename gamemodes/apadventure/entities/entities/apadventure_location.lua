AddCSLuaFile()

ENT.PrintName = "apAdventure Location"
ENT.AutomaticFrameAdvance = true

DEFINE_BASECLASS("base_gmodentity")

APADV_LOCENTS = APADV_LOCENTS or {}

local bboxmins = Vector(-10,-10,0)
local bboxmaxs = Vector(10,10,20)

function ENT:Initialize()
    BaseClass.Initialize(self)
    self:SetModel("models/apapdventure/location_pickup.mdl")
    self:PhysicsInitBox( bboxmins,bboxmaxs )
    self:SetSolidFlags(bit.bor(FSOLID_NOT_SOLID,FSOLID_TRIGGER))
    local phys = self:GetPhysicsObject()
    phys:EnableGravity(false)
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

local IsCollector

local function IsCollector(ent)
    if !IsValid(ent) then return false end
    if ent.ApAdvCollector != nil then return ent.ApAdvCollector end
    if ent:IsPlayer() then return true end
    if ent:IsVehicle() then return IsCollector(ent:GetDriver()) end
    return false
end

function ENT:StartTouch(ent)
    local collecttouch = IsCollector(ent)
    if !collecttouch then return end
    local sent = APADV.SendLocation(self.LocationName)
    if sent then self:Remove() end
end

--removing old location entity table entries might be a little overkill since
--there's not really any scenario in which they should exist but whatever
function ENT:SetupLocation(lctnname)
    local oldloc = self.LocationName
    local oldloctbl = APADV_LOCENTS[oldloc] 
    if oldloctbl and oldloctbl[self] then
        oldloctbl[self] = nil
        if !next(oldloctbl) then
            APADV_LOCENTS[oldloc] = nil
        end
    end

    self.LocationName = lctnname
    APADV_LOCENTS[lctnname] = APADV_LOCENTS[lctnname] or {}
    APADV_LOCENTS[lctnname][self] = true
end

--[[ function ENT:EndTouch(ent)
    print(ent,"stopped touching",self,self.LocationName)
end ]]

--[[ function ENT:Touch(ent)
    print(ent,"touching",self,self.LocationName)
end ]]