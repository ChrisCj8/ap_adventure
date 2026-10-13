
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
	worldspawn=true,
	apadventure_entrance_editor=true,
	apadventure_exit_editor=true,
	apadventure_location_editor=true,
	apadventure_start_editor=true,
}

function TOOL:FailSound()
	self:GetWeapon():EmitSound("weapons/pistol/pistol_empty.wav")
end

function TOOL:LeftClick(tr)
	local hitent = tr.Entity
	if !hitent or EntFilter[hitent:GetClass()] then self:FailSound() return end
	if !apAdventure.SaveMark(hitent,true) then self:FailSound() return end
	return apAdventure.SpoofToolShot(self,tr)
end

function TOOL:RightClick(tr)
	local hitent = tr.Entity
	if !hitent or EntFilter[hitent:GetClass()] then self:FailSound() return end
	if !apAdventure.SaveMark(hitent,false) then self:FailSound() return end
	return apAdventure.SpoofToolShot(self,tr)
end