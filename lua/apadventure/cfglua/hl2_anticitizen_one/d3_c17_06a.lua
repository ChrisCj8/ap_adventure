return {
	PostCfgLoad = function(self)
		if APADV_ENTRNAME == "Exit" then
			ents.FindByName("exit_hall_portal")[1]:Fire("Open")
		end
	end
}