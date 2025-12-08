
if CLIENT then
    TOOL.Name = "#tool.apadventure_save.shortname"
    TOOL.Category = "apadventure.toolgroup"

    TOOL.Information = {
        {name="left"},
        {name="right"}
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
    apAdventure.EditCfg.Saved[hitent] = true
    return true
end