
TOOL.ClientConVar = {
    region = "base",
    name = "default"
}

if CLIENT then
    TOOL.Name = "#tool.apadventure_entrance.shortname"
    TOOL.Category = "apadventure.toolgroup"

    TOOL.Information = {
        {name="left",icon="gui/lmb.png"},
        {name="right",icon="gui/rmb.png"},
        {name="reload",icon="gui/r.png"}
    }

    function TOOL.BuildCPanel(cPnl)
        cPnl:TextEntry("#apadventure.toolui.region","apadventure_entrance_region")
        cPnl:Help("#tool.apadventure_entrance.region_help")
        cPnl:TextEntry("#tool.apadventure_entrance.name_ui","apadventure_entrance_name")
        cPnl:Help("#tool.apadventure_entrance.name_help")
        cPnl:Help("#tool.apadventure_entrance.match_names_info")
    end

    return
end

function TOOL:LeftClick(tr)
    if !tr.Hit then return end
    local ent = tr.Entity
    local region = self:GetClientInfo("region")
    local name = self:GetClientInfo("name")
    if ent:GetClass() == "apadventure_entrance_editor" then
        ent:SetRegion(region)
        ent:SetEntrName(name)
    else
        ent = ents.Create("apadventure_entrance_editor")
        if !IsValid(ent) then return end
        ent:SetPos(tr.HitPos)
        ent:Spawn()
        local curpos = ent:GetPos()
        ent:SetPos(tr.HitPos+curpos-ent:NearestPoint(curpos-(tr.HitNormal*512)))
        ent:SetRegion(region)
        ent:SetEntrName(name)
        undo.Create("apadventure_entrance_editor")
            undo.AddEntity(ent)
            undo.SetPlayer(self:GetOwner())
        undo.Finish()    
    end
end

function TOOL:Reload()
    local ent = ents.Create("apadventure_entrance_editor")
    local region = self:GetClientInfo("region")
    local name = self:GetClientInfo("name")
    if !IsValid(ent) then return end
    local user = self:GetOwner()
    ent:SetPos(user:GetPos())
    local facing = user:GetAngles()
    facing.x, facing.z = 0, 0
    ent:SetAngles(facing)
    ent:Spawn()
    ent:SetRegion(region)
    ent:SetEntrName(name)
    undo.Create("apadventure_entrance_editor")
        undo.AddEntity(ent)
        undo.SetPlayer(user)
    undo.Finish()    
end

function TOOL:RightClick(tr)
    if !tr.Hit then return end
    local ent = tr.Entity
    if !IsValid(ent) then return end
    local owner = self:GetOwner()
    if isfunction(ent.CopyRegionName) then
        owner:ConCommand("apadventure_entrance_region \""..ent:CopyRegionName().."\"")
    end
    if isfunction(ent.CopyConnectionName) then
        owner:ConCommand("apadventure_entrance_name \""..ent:CopyConnectionName().."\"")
    end
end