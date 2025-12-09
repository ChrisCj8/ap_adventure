AddCSLuaFile()

ENT.PrintName = "apAdventure Exit"

DEFINE_BASECLASS("base_gmodentity")

function ENT:Initialize()
    BaseClass.Initialize(self)
    self:SetModel("models/apadventure/frame.mdl")
    self:PhysicsInitStatic(SOLID_VPHYSICS)
    if CLIENT then return end
    self:SetUseType(SIMPLE_USE)
end

function ENT:ResetIcon()
    self:SetSubMaterial(1,self:GetSubMaterial(1))
end

if CLIENT then return end

function ENT:Use(activator,caller,usetype,val)
    --print(self,"used by",activator,caller)
    if APADV_ENTRANCES and APADV_ENTRANCES[APADV_MAPGROUP] and APADV_ENTRANCES[APADV_MAPGROUP][APADV_MAP] and APADV_ENTRANCES[APADV_MAPGROUP][APADV_MAP][self.ExitName] then 
        local entrtbl = APADV_ENTRANCES[APADV_MAPGROUP][APADV_MAP][self.ExitName]
        --PrintTable(entrtbl)
        APADV.DoMapTransition(entrtbl.map,entrtbl.group,entrtbl.entr)
        return 
    elseif APADV_SLOT and APADV_SLOT.Connected then
        local slotdata = APADV_SLOT.slotData
        local start = slotdata.startmap
        local startgr = slotdata.startgroup
        APADV.DoMapTransition(start,startgr)
    end
end

function ENT:SetMapIcon(map)
    apAdventure.GetMapIconMat(map, function(mat) 
        self:SetSubMaterial(1,mat)
    end)
end