return {
	npc_manhack = function(ent,victim,dmg,victmn)
		return victmn.." was hacked apart by a Manhack."
	end,
	npc_combine_s = function(ent,victim,dmg,victmn)
		local mdl = ent:GetModel()
		if mdl == "models/combine_super_soldier.mdl" then return nil, "Combine Elite" end
		local skin = ent:GetSkin()
		return nil, mdl == "models/combine_soldier_prisonguard.mdl" and
			( skin == 1 and "Nova Prospekt Shotgunner" or "Nova Prospekt Guard" ) or
			( skin == 1 and "Combine Shotgunner" or "Combine Soldier" )
	end,
	npc_turret_floor = function(ent,victim,dmg,victmn)
		if ent:GetSkin() == 0 and bit.band(ent:GetSpawnFlags(),512) == 0 then return victmn.." was sterilized by a Combine Turret." end
		return nil, "Floor Turret"
	end,
	npc_portal_turret_floor = function()
		return nil, "Aperture Science Sentry Turret"
	end,
	npc_rocket_turret = function()
		return nil, "Aperture Science Rocket Turret"
	end
}