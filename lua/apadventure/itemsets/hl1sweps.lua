local oldmprulesent, oldmpruleswep

return {
	Name = "HL1 SWEPs",
	Requirements = {"hls_base_or_dm","wsid1360233031"},
	OnLoad = function(self)
		local function mprules() return false end
		local hl1enttbl = scripted_ents.GetStored("ent_hl1_base")
		if hl1enttbl then
			oldmprulesent = hl1enttbl.t.IsMultiplayerRules
			hl1enttbl.t.IsMultiplayerRules = mprules
		end
		local hl1weptbl = weapons.GetStored("weapon_hl1_base")
		if hl1weptbl then
			oldmpruleswep = hl1weptbl.IsMultiplayerRules
			hl1weptbl.IsMultiplayerRules = mprules
		end
	end,
	OnUnload = function(self)
		local hl1enttbl = scripted_ents.GetStored("ent_hl1_base")
		if hl1enttbl then
			hl1enttbl.t.IsMultiplayerRules = oldmprulesent
		end
		local hl1weptbl = weapons.GetStored("weapon_hl1_base")
		if hl1weptbl then
			hl1weptbl.IsMultiplayerRules = oldmpruleswep
		end
	end
}