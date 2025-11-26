
if CLIENT then
    TOOL.Name = "#tool.apadventure_delete.name"
    TOOL.Category = "apadventure.toolgroup"

    TOOL.Information = {
        {name="left",icon="gui/lmb.png"},
        {name="right",icon="gui/rmb.png"},
        {name="creationmode",op=0},
        {name="namemode",op=1},
    }

    function TOOL:LeftClick(tr,forceray)
        if forceray then return true end
    end
end

local EntFilter = {
    worldspawn=true
}

function TOOL:LeftClick(tr)
    local hitent = tr.Entity
    if !hitent or EntFilter[hitent:GetClass()] then return end
    local op = self:GetOperation()
    if op == 0 then
        return apAdventure.DelMark(hitent,true)
    else
        local name = hitent:GetName()
        if name == "" then return end
        apAdventure.EditCfg.DelName[name] = true
    end
    return true
end

function TOOL:RightClick(tr)
    local hitent = tr.Entity
    if !hitent or EntFilter[hitent:GetClass()] or hitent:MapCreationID() == -1 then return end
    local op = self:GetOperation()
    if op == 0 then
        return apAdventure.DelMark(hitent,false)
    else
        local name = hitent:GetName()
        if name == "" then return end
        apAdventure.EditCfg.DelName[name] = nil
    end
    return true
end

function TOOL:Reload()
    local curop = self:GetOperation()
    if curop == 1 then
        self:SetOperation(0)
    else
        self:SetOperation(curop+1)
    end
end