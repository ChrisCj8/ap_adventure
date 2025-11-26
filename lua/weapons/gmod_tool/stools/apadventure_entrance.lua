
TOOL.ClientConVar = {
    region = "base",
    name = "default"
}

if CLIENT then
    TOOL.Name = "#tool.apadventure_entrance.name"
    TOOL.Category = "apadventure.toolgroup"

    TOOL.Information = {
        {name="left",icon="gui/lmb.png"},
        {name="reload",icon="gui/r.png"}
    }

    function TOOL.BuildCPanel(cPnl)
        cPnl:TextEntry("Region","apadventure_entrance_region")
        cPnl:TextEntry("Name","apadventure_entrance_name")
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

apAdventure = apAdventure or {}
apAdventure.RegionCopying = apAdventure.RegionCopying or {}

apAdventure.RegionCopying.apadventure_entrance_editor = true

local cancopyname = {
    apadventure_entrance_editor = true,
}

function TOOL:RightClick(tr)
    if !tr.Hit then return end
    local ent = tr.Entity
    if !IsValid(ent) then return end
    local class = ent:GetClass()
    if apAdventure.RegionCopying[class] then
        self:GetOwner():ConCommand("apadventure_entrance_region \""..ent:GetRegion().."\"")
    end
    if cancopyname[class] then
        self:GetOwner():ConCommand("apadventure_entrance_name \""..ent:GetEntrName().."\"")
    end
end