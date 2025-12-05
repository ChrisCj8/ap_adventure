
TOOL.ClientConVar = {
    region = "base",
    name = "default",
    isdummy = "0",
}

if CLIENT then
    TOOL.Name = "#tool.apadventure_location.shortname"
    TOOL.Category = "apadventure.toolgroup"

    TOOL.Information = {
        {name="left",icon="gui/lmb.png"},
        {name="right",icon="gui/rmb.png"}
    }

    function TOOL.BuildCPanel(cPnl)
        cPnl:TextEntry("#tool.apadventure_location.region","apadventure_location_region")
        cPnl:Help("#tool.apadventure_location.region_help")
        cPnl:TextEntry("#tool.apadventure_location.name_ui","apadventure_location_name")
        cPnl:Help("#tool.apadventure_location.name_help")
        cPnl:CheckBox("#tool.apadventure_location.isdummy","apadventure_location_isdummy")
        cPnl:Help("#tool.apadventure_location.isdummy_help")
    end

    return
end

function TOOL:LeftClick(tr)
    if !tr.Hit then return end
    local ent = tr.Entity
    local region = self:GetClientInfo("region")
    local name = self:GetClientInfo("name")
    local isdummy = self:GetClientInfo("isdummy")
    if ent:GetClass() == "apadventure_location_editor" then
        ent:SetRegion(region)
        ent:SetLctnName(name)
        ent:SetIsDummy(isdummy)
    else
        ent = ents.Create("apadventure_location_editor")
        if !IsValid(ent) then return end
        ent:SetPos(tr.HitPos)
        ent:Spawn()
        local curpos = ent:GetPos()
        ent:SetPos(tr.HitPos+curpos-ent:NearestPoint(curpos-(tr.HitNormal*512)))
        ent:SetRegion(region)
        ent:SetLctnName(name)
        ent:SetIsDummy(isdummy)
        undo.Create("apadventure_location_editor")
            undo.AddEntity(ent)
            undo.SetPlayer(self:GetOwner())
        undo.Finish()    
    end
end

function TOOL:RightClick(tr)
    if !tr.Hit then return end
    local ent = tr.Entity
    if !IsValid(ent) then return end
    local owner = self:GetOwner()
    if isfunction(ent.CopyRegionName) then
        owner:ConCommand("apadventure_location_region \""..ent:CopyRegionName().."\"")
    end
    if ent:GetClass() == "apadventure_location_editor" then
        owner:ConCommand("apadventure_location_name \""..ent:GetLctnName().."\"")
        owner:ConCommand("apadventure_location_isdummy \""..(ent:GetIsDummy() and 1 or 0).."\"")
    end
end