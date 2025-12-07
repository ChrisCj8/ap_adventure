
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
        apAdventure.entrregnamepnl = cPnl:TextEntry("#apadventure.toolui.region","apadventure_entrance_region")
        cPnl:Help("#tool.apadventure_entrance.region_help")
        apAdventure.entrnamepnl = cPnl:TextEntry("#tool.apadventure_entrance.name_ui","apadventure_entrance_name")
        cPnl:Help("#tool.apadventure_entrance.name_help")
        cPnl:Help("#tool.apadventure_entrance.match_names_info")
        cPnl:Help("#apadventure.toolui.twoway")
    end

    cvars.AddChangeCallback("apadventure_entrance_region",function(cvar,old,new) 
        if IsValid(apAdventure.entrregnamepnl) then
            apAdventure.entrregnamepnl:SetText(new)
        end
    end,"apadventure_entrance_tool_region")

    cvars.AddChangeCallback("apadventure_entrance_name",function(cvar,old,new) 
        if IsValid(apAdventure.entrnamepnl) then
            apAdventure.entrnamepnl:SetText(new)
        end
    end,"apadventure_entrance_tool_name")

    if game.SinglePlayer() then return end

    function TOOL:LeftClick(tr)
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
            GetConVar("apadventure_entrance_region"):SetString(name)
            ray = true
        end
        if isfunction(ent.CopyConnectionName) then
            GetConVar("apadventure_entrance_name"):SetString(ent:CopyConnectionName())
            ray = true
        end
        return ray
    end

    function TOOL:Reload()
        local toolgun = self:GetWeapon()
        toolgun:EmitSound(toolgun.ShootSound)
        toolgun:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
        self:GetOwner():SetAnimation(PLAYER_ATTACK1)
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
    return true
end

function TOOL:Reload()
    local ent = ents.Create("apadventure_entrance_editor")
    local region = self:GetClientInfo("region")
    local name = self:GetClientInfo("name")
    if !IsValid(ent) then return end
    local user = self:GetOwner()
    local userfeet = user:GetPos()
    ent:SetPos(userfeet)
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
    local toolgun = self:GetWeapon()
    toolgun:EmitSound(toolgun.ShootSound)
    toolgun:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
    self:GetOwner():SetAnimation(PLAYER_ATTACK1)
end

if !game.SinglePlayer() then return end

function TOOL:RightClick(tr)
    if !tr.Hit then return end
    local ent = tr.Entity
    if !IsValid(ent) then return end
    local owner = self:GetOwner()
    local ray
    if isfunction(ent.CopyRegionName) then
        owner:ConCommand("apadventure_entrance_region \""..ent:CopyRegionName().."\"")
        ray = true
    end
    if isfunction(ent.CopyConnectionName) then
        owner:ConCommand("apadventure_entrance_name \""..ent:CopyConnectionName().."\"")
        ray = true
    end
    return ray
end