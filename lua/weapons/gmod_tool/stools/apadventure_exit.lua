
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

    apAdventure.ExitAccessTbl = apAdventure.ExitAccessTbl or {}

    function TOOL.BuildCPanel(cPnl)
        apAdventure.exitregnamepnl = cPnl:TextEntry("#apadventure.toolui.region","apadventure_exit_region")
        cPnl:ControlHelp("#tool.apadventure_exit.region_help")
        apAdventure.exitnamepnl = cPnl:TextEntry("#tool.apadventure_exit.name_ui","apadventure_exit_name")
        cPnl:ControlHelp("#tool.apadventure_exit.name_help")
        cPnl:Help("#tool.apadventure_exit.match_names_info")
        cPnl:Help("#apadventure.toolui.twoway")
        local accesspnl = include("apadventure/ui/access.lua")(cPnl,400)
        accesspnl:LoadTbl(apAdventure,"ExitAccessTbl")
        accesspnl:DockMargin(5,5,5,5)
        accesspnl:Dock(TOP)
        apAdventure.ExitAccessPnl = accesspnl
    end

    cvars.AddChangeCallback("apadventure_exit_region",function(cvar,old,new) 
        if IsValid(apAdventure.exitregnamepnl) then
            apAdventure.exitregnamepnl:SetText(new)
        end
    end,"apadventure_exit_tool_region")

    cvars.AddChangeCallback("apadventure_exit_name",function(cvar,old,new) 
        if IsValid(apAdventure.exitnamepnl) then
            apAdventure.exitnamepnl:SetText(new)
        end
    end,"apadventure_exit_tool_name")

    if game.SinglePlayer() then return end

    function TOOL:LeftClick()
        return true
    end

    function TOOL:RightClick(tr)
        if !tr.Hit then return end
        local ent = tr.Entity
        if !IsValid(ent) then return end
        local owner = self:GetOwner()
        local ray
        if isfunction(ent.CopyRegionName) then
            local name = ent:CopyRegionName()
            GetConVar("apadventure_exit_region"):SetString(name)
            ray = true
        end
        if isfunction(ent.CopyConnectionName) then
            local name = ent:CopyConnectionName()
            GetConVar("apadventure_exit_name"):SetString(name)
            ray = true
            if ent.APAdvAccessTableType then
                apAdventure.CopyAccessTbl(name,ent.APAdvAccessTableType,2)
            end
        end
        return ray
    end

    return
end

function TOOL:LeftClick(tr)
    if !tr.Hit then return end
    local ent = tr.Entity
    local region = self:GetClientInfo("region")
    local name = self:GetClientInfo("name")
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
        undo.Create("apadventure.entity.exit")
            undo.AddEntity(ent)
            undo.SetPlayer(self:GetOwner())
        undo.Finish()
    end
    apAdventure.RequestAccessTbl(self:GetOwner(),name,2)
    return true
end

if !game.SinglePlayer() then return end

function TOOL:RightClick(tr)
    if !tr.Hit then return end
    local ent = tr.Entity
    if !IsValid(ent) then return end
    local owner = self:GetOwner()
    local ray
    if isfunction(ent.CopyRegionName) then
        owner:ConCommand("apadventure_exit_region \""..ent:CopyRegionName().."\"")
        ray = true
    end
    if isfunction(ent.CopyConnectionName) then
        local name = ent:CopyConnectionName()
        owner:ConCommand("apadventure_exit_name \""..name.."\"")
        ray = true
        if ent.APAdvAccessTableType then
            apAdventure.CopyAccessTbl(owner,name,ent.APAdvAccessTableType,2)
        end
    end
    return ray
end