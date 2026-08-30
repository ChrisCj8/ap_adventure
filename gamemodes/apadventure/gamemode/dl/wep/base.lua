return {
	weapon_stunstick = function(wep,ply,dmg,plyname,killrn)
		if killrn then return plyname.." was beaten to death by "..killrn.."." end
		return plyname.." was beaten to death."
	end
}