
AddCSLuaFile()

DEFINE_BASECLASS("base_brush")

function ENT:Initialize()
    self:SetNoDraw(engine.ActiveGamemode() != "sandbox")
end

