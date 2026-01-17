
TOOL.ClientConVar = {
    region = "base",
    name = "default",
    isdummy = "0",
}

if CLIENT then
    TOOL.Name = "#tool.apadventure_location.shortname"
    TOOL.Category = "apadventure.toolgroup"

    TOOL.Information = {
        {name="left"},
        {name="right"}
    }
    
    apAdventure.LocationAccessTbl = apAdventure.LocationAccessTbl or {}

    function TOOL.BuildCPanel(cPnl)
        cPnl:TextEntry("#apadventure.toolui.region","apadventure_location_region")
        cPnl:ControlHelp("#tool.apadventure_location.region_help")
        cPnl:TextEntry("#tool.apadventure_location.name_ui","apadventure_location_name")
        cPnl:ControlHelp("#tool.apadventure_location.name_help")
        cPnl:CheckBox("#tool.apadventure_location.isdummy","apadventure_location_isdummy")
        cPnl:ControlHelp("#tool.apadventure_location.isdummy_help")
        local accesspnl = include("apadventure/ui/access.lua")(cPnl,400)
        accesspnl:LoadTbl(apAdventure,"LocationAccessTbl")
        accesspnl:DockMargin(5,5,5,5)
        accesspnl:Dock(TOP)
        apAdventure.LctnAccessPnl = accesspnl
    end

    return
end

function TOOL:LeftClick(tr)
    if !tr.Hit then return end
    local ent = tr.Entity
    local region = self:GetClientInfo("region")
    local name = self:GetClientInfo("name")
    local isdummy = self:GetClientBool("isdummy")
    if ent:GetClass() == "apadventure_location_editor" then
        ent:SetRegion(region)
        ent:SetLctnName(name)
        ent:SetIsDummy(isdummy)
    else
        ent = ents.Create("apadventure_location_editor")
        if !IsValid(ent) then return end
        ent:SetPos(tr.HitPos)
        ent:Spawn()
        local curpos = ent:GetPos()
        ent:SetPos(tr.HitPos+curpos-ent:NearestPoint(curpos-(tr.HitNormal*512)))
        ent:SetRegion(region)
        ent:SetLctnName(name)
        ent:SetIsDummy(isdummy)
        undo.Create("apadventure_location_editor")
            undo.AddEntity(ent)
            undo.SetPlayer(self:GetOwner())
        undo.Finish()    
    end
    -- kinda sucks that were sending an entire json table every time the user wants to place or update a location
    -- but in theory i don't think people will be editing their configs in multiplayer much so this *should* be fine
    apAdventure.RequestAccessTbl(self:GetOwner(),name,0)
    return apAdventure.SpoofToolShot(self,tr)
end

function TOOL:RightClick(tr)
    if !tr.Hit then return end
    local ent = tr.Entity
    if !IsValid(ent) then return end
    local owner = self:GetOwner()
    local ray = false
    if isfunction(ent.CopyRegionName) then
        owner:ConCommand("apadventure_location_region \""..ent:CopyRegionName().."\"")
        ray = true
    end
    if ent:GetClass() == "apadventure_location_editor" then
        local name = ent:GetLctnName()
        owner:ConCommand("apadventure_location_name \""..name.."\"")
        owner:ConCommand("apadventure_location_isdummy \""..(ent:GetIsDummy() and 1 or 0).."\"")
        ray = true
        if ent.APAdvAccessTableType then
            apAdventure.CopyAccessTbl(owner,name,ent.APAdvAccessTableType,0)
        end
    end
    return ray and apAdventure.SpoofToolShot(self,tr)
end