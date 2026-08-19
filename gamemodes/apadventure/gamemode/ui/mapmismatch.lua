net.Receive("ApAdvMapMismatch",function()
	local cfgrev, currev, delid, forced = net.ReadFloat(), net.ReadFloat(), net.ReadBool(), net.ReadBool()

	local frame = vgui.Create("DFrame")
	frame:SetPos(100,100)
	frame:SetSize(300,200)
	frame:MakePopup()
	frame:SetTitle("#apadventure.mapmismatch")

	local warnlbl = vgui.Create("DLabel",frame)
	warnlbl:SetPos(5,30)
	warnlbl:SetSize(290,165)
	warnlbl:SetWrap(true)

	local warntext = string.Interpolate(language.GetPhrase("apadventure.mapmismatch.basewarning"),{
		cfg = cfgrev,
		cur = currev
	})
	if delid then
		warntext = warntext.."\n\n"..language.GetPhrase("apadventure.mapmismatch.delid")
	end
	if forced then
		warntext = warntext.."\n\n"..language.GetPhrase("apadventure.mapmismatch."..(delid and "alsoforce" or "force"))
	end
	warnlbl:SetText(warntext)
end)