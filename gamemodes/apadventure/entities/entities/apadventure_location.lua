AddCSLuaFile()

ENT.PrintName = "apAdventure Location"

DEFINE_BASECLASS("base_gmodentity")

APADV_LOCENTS = APADV_LOCENTS or {}

function ENT:Initialize()
    BaseClass.Initialize(self)
    self:SetModel("models/hunter/blocks/cube05x05x05.mdl")
    --self:SetCollisionGroup( COLLISION_GROUP_WORLD )
    --[[ local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        self:PhysicsDestroy()
    end ]]
    self:PhysicsInit(SOLID_BBOX)
    self:SetSolidFlags(bit.bor(FSOLID_NOT_SOLID,FSOLID_TRIGGER))
    local phys = self:GetPhysicsObject()
    phys:EnableGravity(false)


    --[[ if CLIENT then return end
    self:SetTrigger(true) ]]
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