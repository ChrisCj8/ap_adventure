return {
	DoCheck = function(info)
		local games = info.games
		local hl1, hl1mp = games.hl1, games.hl1mp
		local status = (game.IsDedicated() and 2) or
			(hl1 and hl1.mounted and 1) or
			(hl1mp and hl1mp.mounted and 1) or 3
		return {
			msg = "needhl",
			status = status or 2
		}
	end
}