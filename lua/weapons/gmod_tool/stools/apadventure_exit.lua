
TOOL.ClientConVar = {
	region = "base",
	name = "default",
	isdummy = "0",
	removeunconnected = "0"
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
		local regname = cPnl:TextEntry("#apadventure.toolui.region","apadventure_exit_region")
		cPnl:ControlHelp("#tool.apadventure_exit.region_help")
		local name = cPnl:TextEntry("#tool.apadventure_exit.name_ui","apadventure_exit_name")
		cPnl:ControlHelp("#tool.apadventure_exit.name_help")
		local isdummy = cPnl:CheckBox("#tool.apadventure_exit.isdummy","apadventure_exit_isdummy")
		cPnl:ControlHelp("#tool.apadventure_exit.isdummy.help")
		local removeunconnected = cPnl:CheckBox("#tool.apadventure_exit.removeunconnected","apadventure_exit_removeunconnected")
		cPnl:ControlHelp("#tool.apadventure_exit.removeunconnected.help")
		cPnl:Help("#tool.apadventure_exit.match_names_info")
		cPnl:Help("#apadventure.toolui.twoway")
		local accesspnl = include("apadventure/ui/access.lua")(cPnl,400)
		accesspnl:LoadTbl(apAdventure,"ExitAccessTbl")
		accesspnl:DockMargin(5,5,5,5)
		accesspnl:Dock(TOP)
		apAdventure.ExitAccessPnl = accesspnl

		if game.SinglePlayer() then
			apAdventure.exitregnamepnl = regname
			apAdventure.exitnamepnl = name
			apAdventure.exitisdummypnl = isdummy
			apAdventure.exitremoveunconnectedpnl = removeunconnected
		end
	end

	if game.SinglePlayer() then return end

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

	cvars.AddChangeCallback("apadventure_exit_region",function(cvar,old,new)
		if IsValid(apAdventure.exitisdummypnl) then
			apAdventure.exitisdummypnl:SetChecked(new)
		end
	end,"apadventure_exit_tool_region")

	cvars.AddChangeCallback("apadventure_exit_region",function(cvar,old,new)
		if IsValid(apAdventure.exitremoveunconnectedpnl) then
			apAdventure.exitremoveunconnectedpnl:SetChecked(new)
		end
	end,"apadventure_exit_tool_region")

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
		if ent:GetClass() == "apadventure_exit_editor" then
			GetConVar("apadventure_exit_isdummy"):SetBool(ent:GetIsDummy())
			GetConVar("apadventure_exit_removeunconnected"):SetBool(ent:GetRemoveUnconnected())
		end
		return ray
	end

	return
end

function TOOL:LeftClick(tr)
	if !tr.Hit then return end
	local region = self:GetClientInfo("region")
	if region == "" then apAdventure.ToolWarn("noreg",self:GetOwner()) return end
	if region[1] == " " then apAdventure.ToolWarn("reglead",self:GetOwner()) return end
	if region[#region] == " " then apAdventure.ToolWarn("regtrail",self:GetOwner()) return end
	local name = self:GetClientInfo("name")
	if name == "" then apAdventure.ToolWarn("noexit",self:GetOwner()) return end
	if name[1] == " " then apAdventure.ToolWarn("exitlead",self:GetOwner()) return end
	if name[#name] == " " then apAdventure.ToolWarn("exittrail",self:GetOwner()) return end
	local ent = tr.Entity
	if ent:GetClass() != "apadventure_exit_editor" then
		ent = ents.Create("apadventure_exit_editor")
		if !IsValid(ent) then return end
		ent:SetPos(tr.HitPos)
		local placementangle = tr.HitNormal:Angle()
		placementangle.x = placementangle.x + 90
		ent:SetAngles(placementangle)
		ent:Spawn()
		local curpos = ent:GetPos()
		ent:SetPos(tr.HitPos+curpos-ent:NearestPoint(curpos-(tr.HitNormal*512)))
		undo.Create("apadventure.entity.exit")
			undo.AddEntity(ent)
			undo.SetPlayer(self:GetOwner())
		undo.Finish()
	end
	ent:SetRegion(region)
	ent:SetExitName(name)
	ent:SetIsDummy(tobool(self:GetClientInfo("isdummy")))
	ent:SetRemoveUnconnected(tobool(self:GetClientInfo("removeunconnected")))
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
	if ent:GetClass() == "apadventure_exit_editor" then
		owner:ConCommand("apadventure_exit_isdummy \""..(ent:GetIsDummy() and 1 or 0).."\"")
		owner:ConCommand("apadventure_exit_removeunconnected \""..(ent:GetRemoveUnconnected() and 1 or 0).."\"")
	end
	return ray
end