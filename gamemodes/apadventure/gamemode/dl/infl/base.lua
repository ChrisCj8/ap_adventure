return {
	npc_satchel = function(infl,ply,dmg,plyname,killrn)
		if ply == dmg:GetAttacker() then return plyname.." blew themselves up with their own S.L.A.M. charge." end
	end,
	npc_tripmine = function(infl,ply,dmg,plyname,killrn)
		if ply == dmg:GetAttacker() then return plyname.." was blown up by their own S.L.A.M. tripmine." end
	end,
}