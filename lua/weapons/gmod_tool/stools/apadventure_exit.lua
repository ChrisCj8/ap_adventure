
TOOL.ClientConVar = {
    region = "base",
    name = "default"
}

if CLIENT then
    TOOL.Name = "#tool.apadventure_exit.name"
    TOOL.Category = "apadventure.toolgroup"

    TOOL.Information = {
        {name="left",icon="gui/lmb.png"},
        {name="right",icon="gui/rmb.png"}
    }

    function TOOL.BuildCPanel(cPnl)
        cPnl:TextEntry("Region","apadventure_exit_region")
        cPnl:TextEntry("Name","apadventure_exit_name")
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

apAdventure = apAdventure or {}
apAdventure.RegionCopying = apAdventure.RegionCopying or {}

apAdventure.RegionCopying.apadventure_exit_editor = true

local cancopyname = {
    apadventure_exit_editor = true,
}

function TOOL:RightClick(tr)
    if !tr.Hit then return end
    local ent = tr.Entity
    if !IsValid(ent) then return end
    local class = ent:GetClass()
    if apAdventure.RegionCopying[class] then
        self:GetOwner():ConCommand("apadventure_exit_region \""..ent:GetRegion().."\"")
    end
    if cancopyname[class] then
        self:GetOwner():ConCommand("apadventure_exit_name \""..ent:GetExitName().."\"")
    end
end