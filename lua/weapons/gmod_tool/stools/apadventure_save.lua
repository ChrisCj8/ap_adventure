
if CLIENT then
    TOOL.Name = "#tool.apadventure_save.shortname"
    TOOL.Category = "apadventure.toolgroup"

    TOOL.Information = {
        {name="left"},
        {name="right"}
    }

    function TOOL.BuildCPanel(cPnl)
        cPnl:Help("#tool.apadventure_save.help1")
        cPnl:Help("#tool.apadventure_save.help_dupe")
        cPnl:Help("#tool.apadventure_save.help_constr")
        cPnl:CheckBox("#tool.apadventure_save.dohalos","apadventure_editor_show_save_halos")
    end

    return
end

local EntFilter = {
    worldspawn=true
}

function TOOL:LeftClick(tr)
    local hitent = tr.Entity
    if !hitent or EntFilter[hitent:GetClass()] then return end
    if !apAdventure.SaveMark(hitent,true) then return end
    return apAdventure.SpoofToolShot(self,tr)
end

function TOOL:RightClick(tr)
    local hitent = tr.Entity
    if !hitent or EntFilter[hitent:GetClass()] then return end
    if !apAdventure.SaveMark(hitent,false) then return end
    return apAdventure.SpoofToolShot(self,tr)
end