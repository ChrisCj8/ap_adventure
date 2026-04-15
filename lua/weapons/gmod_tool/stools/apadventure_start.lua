
TOOL.ClientConVar = {
    region = "base",
    name = "default"
}

if CLIENT then
    TOOL.Name = "#tool.apadventure_start.shortname"
    TOOL.Category = "apadventure.toolgroup"

    TOOL.Information = {
        {name="left"},
        {name="right"},
        {name="reload"}
    }

    function TOOL.BuildCPanel(cPnl)
        cPnl:TextEntry("#apadventure.toolui.region","apadventure_start_region")
        cPnl:Help("#tool.apadventure_start.help1")
        cPnl:Help("#tool.apadventure_start.help2")
    end
    return
end

function TOOL:LeftClick(tr)
    if !tr.Hit then return end
    local region = self:GetClientInfo("region")
    if region == "" then apAdventure.ToolWarn("noreg",self:GetOwner()) return end
    if region[1] == " " then apAdventure.ToolWarn("reglead",self:GetOwner()) return end
    if region[#region] == " " then apAdventure.ToolWarn("regtrail",self:GetOwner()) return end
    local ent = tr.Entity
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
        undo.Create("apadventure.entity.start")
            undo.AddEntity(ent)
            undo.SetPlayer(self:GetOwner())
        undo.Finish()
    end
    return apAdventure.SpoofToolShot(self,tr)
end

function TOOL:RightClick(tr)
    if !tr.Hit then return end
    local ent = tr.Entity
    if !IsValid(ent) then return end
    local owner = self:GetOwner()
    if isfunction(ent.CopyRegionName) then
        owner:ConCommand("apadventure_start_region \""..ent:CopyRegionName().."\"")
    end
end

function TOOL:Reload()
    local region = self:GetClientInfo("region")
    if region == "" then apAdventure.ToolWarn("noreg",self:GetOwner()) return end
    if region[1] == " " then apAdventure.ToolWarn("reglead",self:GetOwner()) return end
    if region[#region] == " " then apAdventure.ToolWarn("regtrail",self:GetOwner()) return end
    local ent = ents.Create("apadventure_start_editor")
    if !IsValid(ent) then return end
    local user = self:GetOwner()
    ent:SetPos(user:GetPos())
    local facing = user:GetAngles()
    facing.x, facing.z = 0, 0
    ent:SetAngles(facing)
    ent:Spawn()
    ent:SetRegion(region)
    undo.Create("apadventure.entity.start")
        undo.AddEntity(ent)
        undo.SetPlayer(user)
    undo.Finish()
end