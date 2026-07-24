AddCSLuaFile()

game.AddParticles("particles/archipelago/itemflags.pcf")
PrecacheParticleSystem("gmap_itemflag_progression")
PrecacheParticleSystem("gmap_itemflag_useful")
PrecacheParticleSystem("gmap_itemflag_trap")

ENT.PrintName = "apAdventure Location"
ENT.AutomaticFrameAdvance = true

DEFINE_BASECLASS("base_gmodentity")

APADV_LOCENTS = APADV_LOCENTS or {}

local bboxmins, bboxmaxs = Vector(-10,-10,0), Vector(10,10,20)

local band = bit.band

function ENT:SetupDataTables()

    self:NetworkVar("Int",0,"ItemFlags")

    if CLIENT then
        self:NetworkVarNotify("ItemFlags",function(self,_,old,new)
            if old == new then return end
            self:UpdateFlagParticles(new)
        end)
    end

end

function ENT:Initialize()
    BaseClass.Initialize(self)
    self:SetModel("models/apadventure/location_pickup.mdl")
    self:PhysicsInitStatic(SOLID_BBOX)
    self:SetCollisionBounds(bboxmins,bboxmaxs)
    self:SetSolidFlags(bit.bor(FSOLID_NOT_SOLID,FSOLID_TRIGGER))
    if CLIENT then
        self:UpdateFlagParticles()
        return
    end
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

    local flagparticles = {
        {v=1,p="gmap_itemflag_progression",n="ProgressionParticle"},
        {v=2,p="gmap_itemflag_useful",n="UsefulParticle"},
        {v=4,p="gmap_itemflag_trap",n="TrapParticle"}
    }

    function ENT:UpdateFlagParticles(val)
        local val = val or self:GetItemFlags()
        for k,v in ipairs(flagparticles) do
            local flag = band(v.v,val) != 0
            if flag and !self[v.n] then
                local part = self:CreateParticleEffect(v.p,0)
                self[v.n] = part
            elseif !flag and self[v.n] then
                local part = self[v.n]
                part:StopEmissionAndDestroyImmediately()
                self[v.n] = nil
            end
        end
    end

    return
end

local IsCollector = APADV.IsCollector

function ENT:UpdateInfo(info)
    if !info then return end
    self.LocationInfo = info
	local flag = info.flags
	if !APADV_TRAPVISION and bit.band(flag,4) == 4 then flag = flag - 4 end
    self:SetItemFlags(flag)
end

function ENT:StartTouch(ent)
    local collecttouch = IsCollector(ent)
    if !collecttouch then return end
    local sent = APADV.SendLocation(self.LocationName)
    if sent then self:Remove() end
end

function ENT:RemoveLocTblEntry()
    local oldloc = self.LocationName
    if !oldloc then return end
    local oldloctbl = APADV_LOCENTS[oldloc]
    if oldloctbl and oldloctbl[self] then
        oldloctbl[self] = nil
        if !next(oldloctbl) then
            APADV_LOCENTS[oldloc] = nil
        end
    end
end

function ENT:SetupLocation(lctnname)
    --removing old location entity table entries might be a little overkill since
    --there's not really any scenario in which they should exist but whatever
    self:RemoveLocTblEntry()
    self.LocationName = lctnname
    APADV_LOCENTS[lctnname] = APADV_LOCENTS[lctnname] or {}
    APADV_LOCENTS[lctnname][self] = true
    APADV.LocationInfoRequest(self,lctnname,function(info) self:UpdateInfo(info) end)
end

function ENT:OnRemove()
    self:RemoveLocTblEntry()
end