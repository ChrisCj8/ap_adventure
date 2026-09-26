return {
	PostCfgLoad = function(self)
		local nag = ents.FindByName("command_send_nag_1")[1]
		hook.Add("AcceptInput",self,function(self,ent)
			if ent != nag then return end
			apAdventure.SendNotification("#apadventure.mapcfg.hl2.d3_c17_03.bindhint1",3,10)
			timer.Simple(1,function() apAdventure.SendNotification("#apadventure.mapcfg.hl2.d3_c17_03.bindhint2",3,10) end)
			hook.Remove("AcceptInput",self)
		end)
	end
}