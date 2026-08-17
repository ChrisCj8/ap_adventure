local function layout(p,w,h)
	p:BaseLayout(w,h)
	if p.pushcmd then p.pushcmd:SetSize(w-95,20) end
	if p.relcmd then p.relcmd:SetSize(w-95,20) end
end

local textindefaultbg
local textinwarnbg = Color(255,0,0)

return function(id,tbl,pnl)
	local push, rel = tbl.push, tbl.rel

	local pushlbl = vgui.Create("DLabel",pnl)
	pushlbl:SetText("#apadventure.bindui.ccmd.onpush")
	pushlbl:SetPos(5,25)
	pushlbl:SetSize(80,20)
	pushlbl:SetDark(true)

	local pushcmd = vgui.Create("DTextEntry",pnl)
	if !textindefaultbg then textindefaultbg = pushcmd:GetTextColor() end
	pushcmd:SetText(push or "")
	pushcmd:SetPos(90,25)
	function pushcmd:OnChange()
		local txt = self:GetText()
		local valid = !IsConCommandBlocked(txt)
		self:SetTextColor(valid and textindefaultbg or textinwarnbg)
		tbl.push = valid and txt != "" and txt or nil
		APADV[pnl.isGL and "GLBindsChanged" or "RunBindsChanged"] = true
	end
	pnl.pushcmd = pushcmd

	local rellbl = vgui.Create("DLabel",pnl)
	rellbl:SetText("#apadventure.bindui.ccmd.onrel")
	rellbl:SetPos(5,48)
	rellbl:SetSize(80,20)
	rellbl:SetDark(true)

	local relcmd = vgui.Create("DTextEntry",pnl)
	relcmd:SetText(rel or "")
	relcmd:SetPos(90,48)
	function relcmd:OnChange()
		local txt = self:GetText()
		local valid = !IsConCommandBlocked(txt)
		self:SetTextColor(valid and textindefaultbg or textinwarnbg)
		tbl.push = valid and txt != "" and txt or nil
		APADV[pnl.isGL and "GLBindsChanged" or "RunBindsChanged"] = true
	end
	pnl.relcmd = relcmd

	pnl:SetTall(71)
	pnl.PerformLayout = layout
end, true