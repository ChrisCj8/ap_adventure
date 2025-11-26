
TOOL.ClientConVar = {
    region = "base",
    name = "default"
}

if CLIENT then
    TOOL.Name = "#tool.apadventure_start.name"
    TOOL.Category = "apadventure.toolgroup"

    TOOL.Information = {
        {name="left",icon="gui/lmb.png"},
        {name="reload",icon="gui/r.png"}
    }

    function TOOL.BuildCPanel(cPnl)
        cPnl:TextEntry("Region","apadventure_start_region")
    end
    return
end

function TOOL:LeftClick(tr)
    if !tr.Hit then return end
    local ent = tr.Entity
    local region = self:GetClientInfo("region")
    if ent:GetClass() == "apadventure_start_editor" then
        ent:SetRegion(region)
    else
        ent = ents.Create("apadventure_start_editor")
        if !IsValid(ent) then return end
        ent:SetPos(tr.HitPos)
        ent:Spawn()
        local curpos = ent:GetPos()
        ent:SetPos(tr.HitPos+curpos-ent:NearestPoint(curpos-(tr.HitNormal*512)))
        ent:SetRegion(region)
        undo.Create("apadventure_start_editor")
            undo.AddEntity(ent)
            undo.SetPlayer(self:GetOwner())
        undo.Finish()    
    end
end

function TOOL:Reload()
    local ent = ents.Create("apadventure_start_editor")
    local region = self:GetClientInfo("region")
    if !IsValid(ent) then return end
    local user = self:GetOwner()
    ent:SetPos(user:GetPos())
    local facing = user:GetAngles()
    facing.x, facing.z = 0, 0
    ent:SetAngles(facing)
    ent:Spawn()
    ent:SetRegion(region)
    undo.Create("apadventure_start_editor")
        undo.AddEntity(ent)
        undo.SetPlayer(user)
    undo.Finish()    
end