if !WireLib or !GMAP then return end

if SERVER and engine.ActiveGamemode() == "apadventure" then
    APADV_MAPTRACKERS = APADV_MAPTRACKERS or {}
end

AddCSLuaFile()

DEFINE_BASECLASS("base_wire_entity")

function ENT:Initialize()
    self:SetModel("models/wire_ap/tracker.mdl")

    --self.TrackedItems
end