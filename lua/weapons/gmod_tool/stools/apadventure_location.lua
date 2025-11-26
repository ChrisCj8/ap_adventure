
TOOL.ClientConVar = {
    region = "base",
    name = "default"
}

if CLIENT then
    TOOL.Name = "#tool.apadventure_location.name"
    TOOL.Category = "apadventure.toolgroup"

    TOOL.Information = {
        {name="left",icon="gui/lmb.png"},
        {name="right",icon="gui/rmb.png"}
    }

    function TOOL.BuildCPanel(cPnl)
        cPnl:TextEntry("Region","apadventure_location_region")
        cPnl:TextEntry("Name","apadventure_location_name")
    end
end

function TOOL:LeftClick(tr)
    if !tr.Hit then return end
    if CLIENT then return end
    local ent = tr.Entity
    local region = self:GetClientInfo("region")
    local name = self:GetClientInfo("name")
    if ent:GetClass() == "apadventure_location_editor" then
        ent:SetRegion(region)
        ent:SetLctnName(name)
    else
        ent = ents.Create("apadventure_location_editor")
        if !IsValid(ent) then return end
        ent:SetPos(tr.HitPos)
        ent:Spawn()
        local curpos = ent:GetPos()
        ent:SetPos(tr.HitPos+curpos-ent:NearestPoint(curpos-(tr.HitNormal*512)))
        ent:SetRegion(region)
        ent:SetLctnName(name)
        undo.Create("apadventure_location_editor")
            undo.AddEntity(ent)
            undo.SetPlayer(self:GetOwner())
        undo.Finish()    
    end
end

apAdventure = apAdventure or {}
apAdventure.RegionCopying = apAdventure.RegionCopying or {}

apAdventure.RegionCopying.apadventure_location_editor = true

function TOOL:RightClick(tr)
    if !tr.Hit then return end
    if CLIENT then return end
    local ent = tr.Entity
    local class = ent:GetClass()
    if apAdventure.RegionCopying[class] then
        self:GetOwner():ConCommand("apadventure_location_region \""..ent:GetRegion().."\"")
    end
    if class == "apadventure_location_editor" then
        self:GetOwner():ConCommand("apadventure_location_name \""..ent:GetLctnName().."\"")
    end
end