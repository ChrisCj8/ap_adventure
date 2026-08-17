return function(id,tbl,pnl)
	local wepin = vgui.Create("DTextEntry",pnl)
	function wepin:OnChange()
		tbl.wep = self:GetText()
		APADV[pnl.isGL and "GLBindsChanged" or "RunBindsChanged"] = true
	end
	wepin:SetText(tbl.wep or "")
	wepin:SetPos(3,28)
	pnl:SetTall(55)

	local heldbtn = vgui.Create("DImageButton",pnl)
	heldbtn:SetImage("icon16/gun.png")
	heldbtn:SetSize(16,16)
	function heldbtn:DoClick()
		local wep = LocalPlayer():GetActiveWeapon()
		if !IsValid(wep) then return end
		local name = wep:GetClass()
		wepin:SetText(name)
		tbl.wep = name
		APADV[pnl.isGL and "GLBindsChanged" or "RunBindsChanged"] = true
	end

	function pnl:PerformLayout(w,h)
		self:BaseLayout(w,h)
		wepin:SetSize(w-6-20,22)
		heldbtn:SetPos(w-19,28+3)
	end
end, function() return {type="wep",wep=""} end