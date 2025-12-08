
TOOL.ClientConVar = {
    region = "base",
    name = "default"
}

if CLIENT then
    TOOL.Name = "#tool.apadventure_exit.shortname"
    TOOL.Category = "apadventure.toolgroup"

    TOOL.Information = {
        {name="left"},
        {name="right"}
    }

    function TOOL.BuildCPanel(cPnl)
        cPnl:TextEntry("#apadventure.toolui.region","apadventure_exit_region")
        cPnl:Help("#tool.apadventure_exit.region_help")
        cPnl:TextEntry("#tool.apadventure_exit.name_ui","apadventure_exit_name")
        cPnl:Help("#tool.apadventure_exit.name_help")
        cPnl:Help("#tool.apadventure_exit.match_names_info")
        cPnl:Help("#apadventure.toolui.twoway")
    end
end

if CLIENT then return end

function TOOL:LeftClick(tr)
    if !tr.Hit then return end
    local ent = tr.Entity
    local region = self:GetClientInfo("region")
    local name = self:GetClientInfo("name")
    print(region,name)
    if ent:GetClass() == "apadventure_exit_editor" then
        ent:SetRegion(region)
        ent:SetExitName(name)
    else
        ent = ents.Create("apadventure_exit_editor")
        if !IsValid(ent) then return end
        ent:SetPos(tr.HitPos)
        local placementangle = tr.HitNormal:Angle()
        placementangle.x = placementangle.x + 90
        ent:SetAngles(placementangle)
        ent:Spawn()
        local curpos = ent:GetPos()
        ent:SetPos(tr.HitPos+curpos-ent:NearestPoint(curpos-(tr.HitNormal*512)))
        ent:SetRegion(region)
        ent:SetExitName(name)
        undo.Create("apadventure_exit_editor")
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
        owner:ConCommand("apadventure_exit_region \""..ent:CopyRegionName().."\"")
    end
    if isfunction(ent.CopyConnectionName) then
        owner:ConCommand("apadventure_exit_name \""..ent:CopyConnectionName().."\"")
    end
end