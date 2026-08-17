local mkUI = vgui.Create
local locstr = language.GetPhrase
local textindefaultbg
local textinwarnbg = Color(255,0,0)

local function invalidbtnerror(msg)
	notification.AddLegacy(msg,NOTIFY_ERROR,5)
	surface.PlaySound("buttons/button10.wav")
end

local drawercvar = CreateClientConVar("apadv_bindmenu_drawer_state",1,true,false,"Used to save the state of the help drawer in the Bind UI.",0,1)

local tintedcol
local function gettintedcolor(pnl)
	if tintedcol then return tintedcol end
	local col = pnl:GetBackgroundColor() or color_white
	tintedcol = Color(col.r*.85,col.g*.85,col.b)
	return tintedcol
end

local bindpnllayout = function(self,w,h)
	self.typeslct:SetSize(w-83-21,20)
	self.delbtn:SetPos(w-21,5)
end

local delbtnfunc = function(self)
	local basepnl = self:GetParent()
	local tgttbl = !basepnl.isGL and APADV_RUNBINDS or APADV_GLBINDS
	tgttbl[basepnl.btnID] = nil
	APADV[!basepnl.isGL and "RunBindsChanged" or "GLBindsChanged"] = true
	basepnl:GetParent():LoadBinds()
end

local bindpnlbuilders, selectabletypes = {},{}

local pnlfiles = file.Find("gamemodes/apadventure/gamemode/ui/binds/*.lua","GAME")
for k,v in ipairs(pnlfiles) do
	local builder, slct = include("apadventure/gamemode/ui/binds/"..v)
	local name = string.sub(v,0,-5)
	bindpnlbuilders[name] = builder
	if slct then
		selectabletypes[name] = isfunction(slct) and slct or
			function() return {type=name} end
	end
end

local function bindpnl(pnl,id,tbl,parent,parenttbl)
	pnl:SetHeight(32)
	pnl.btnID = id
	
	local btnlbl = mkUI("DLabel",pnl)
	btnlbl:SetText(input.GetKeyName(id))
	btnlbl:SetDark(true)
	btnlbl:SetPos(5,3)
	btnlbl:SetSize(70,20)

	local curtype = tbl.type
	local typelocstr = "apadventure.bindui.type."
	local typeslct = mkUI("DComboBox",pnl)
	typeslct:SetPos(80,3)
	for k,v in pairs(selectabletypes) do
		typeslct:AddChoice(locstr(typelocstr..k),v,curtype == k)
	end
	if !typeslct:GetSelected() then
		typeslct:SetValue(curtype)
	end
	function typeslct:OnSelect(_,_,func)
		tbl = func()
		parenttbl[id] = tbl
		pnl:Clear()
		bindpnl(pnl,id,tbl,parent,parenttbl)
	end
	pnl.typeslct = typeslct

	local delbtn = mkUI("DImageButton",pnl)
	delbtn:SetImage("icon16/cross.png")
	delbtn:SetSize(16,16)
	delbtn.DoClick = delbtnfunc
	pnl.delbtn = delbtn

	local builder = bindpnlbuilders[tbl.type]
	if isfunction(builder) then
		pnl.BaseLayout = bindpnllayout
		builder(id,tbl,pnl)
	else
		pnl.PerformLayout = bindpnllayout
		pnl:SetTall(26)
	end

	return pnl
end

local function loadbinds(canvas)
	local bindlist, bindamt = {}, 1
	canvas.sortedbinds = bindlist

	for k,v in ipairs(canvas:GetChildren()) do v:Remove() end

	for k,v in pairs(APADV_GLBINDS) do
		local keypnl = mkUI("DPanel",canvas)
		bindpnl(keypnl,k,v,canvas,APADV_GLBINDS)
		keypnl.isGL = true
		bindlist[bindamt] = keypnl
		bindamt = bindamt + 1
	end

	for k,v in pairs(APADV_RUNBINDS) do
		local keypnl = mkUI("DPanel",canvas)
		bindpnl(keypnl,k,v,canvas,APADV_RUNBINDS)
		keypnl:SetBackgroundColor(gettintedcolor(keypnl))
		bindlist[bindamt] = keypnl
		bindamt = bindamt + 1
	end

	table.sort(bindlist,function(a,b)
		local btnA, btnB = a.btnID, b.btnID
		if btnA == btnB then return b.isGL end
		return btnA < btnB
	end)

	canvas:GetParent():InvalidateLayout()
end

local function savedatawindow()
	local pnl = mkUI("DFrame")
	pnl:MakePopup()
	pnl:SetTitle("#apadventure.bindui.rundatamng")
	pnl:SetPos(100,100)
	pnl:SetSize(500,400)
	pnl:SetSizable(true)

	local datalist = mkUI("DListView",pnl)
	datalist:AddColumn("#apadventure.bindui.rundatamng.slotn"):SetFixedWidth(130)
	datalist:AddColumn("#apadventure.bindui.rundatamng.seedn"):SetFixedWidth(130)
	datalist:AddColumn("#apadventure.bindui.rundatamng.runs")
	datalist:AddColumn("#apadventure.bindui.rundatamng.lastsave")
	datalist:SetPos(5,30)

	local function loadfiles()
		local files = file.Find("apadventure/runbinds/*.json","DATA")
		for k,v in ipairs(files) do
			local fn = string.sub(v,0,-6)
			if fn != APADV_RUNID then 
				local spl= string.Explode("_",fn)
				local ln = datalist:AddLine(
					file.Read("apadventure/runbinds/"..fn..".txt","DATA") or "?",
					spl[2],
					os.date("%c",tonumber(spl[1])),
					os.date("%c",file.Time("apadventure/runbinds/"..v,"DATA"))
				)
				ln.filename = fn
			end
		end
	end
	loadfiles()

	local delbtn = mkUI("DButton",pnl)
	delbtn:SetText("#apadventure.bindui.rundatamng.del")
	function delbtn:DoClick()
		for k,v in ipairs(datalist:GetSelected()) do
			local p = "apadventure/runbinds/"..v.filename
			file.Delete(p..".json")
			file.Delete(p..".txt")
		end
		for k,v in ipairs(datalist:GetLines()) do
			datalist:RemoveLine(v:GetID())
		end
		loadfiles()
	end

	local oldlayout = pnl.PerformLayout
	function pnl:PerformLayout(w,h)
		oldlayout(self,w,h)
		datalist:SetSize(w-10,h-62)
		delbtn:SetPos(5,h-27)
		delbtn:SetSize(w-10,22)
	end
end

local function BindWindow(icon,frame)
	frame:SetSizable(true)

	local binder = mkUI("DBinder",frame)
	binder:SetPos(5,30)
	binder:SetSize(70,22)
	local presetslct = mkUI("DComboBox",frame)
	presetslct:SetPos(80,30)
	local prefiles = file.Find("gamemodes/apadventure/gamemode/ui/bindpresets/*.lua","GAME")
	for k,v in ipairs(prefiles) do
		local presets = include("apadventure/gamemode/ui/bindpresets/"..v)
		local filen = string.sub(v,0,-5)
		for ik,iv in ipairs(presets) do
			local name = iv.n
			if name then
				iv.n = nil
				presetslct:AddChoice(name,iv)
			end
		end
	end

	local glbindbtn = mkUI("DButton",frame)
	glbindbtn:SetText("#apadventure.bindui.addglbind")
	glbindbtn:SetPos(5,57)

	local bindlist = mkUI("DScrollPanel",frame)
	bindlist:SetPos(5,82)
	bindlistcanvas = bindlist:GetCanvas()
	bindlist:SetPaintBackground(true)

	bindlistcanvas.LoadBinds = loadbinds
	loadbinds(bindlistcanvas)

	function glbindbtn:DoClick()
		local key = binder:GetValue()
		if key == 0 then return end
		local seln, seld = presetslct:GetSelected()
		APADV_GLBINDS[key] = table.Copy(seld)
		APADV.GLBindsChanged = true
		loadbinds(bindlistcanvas)
	end

	local runbindbtn = mkUI("DButton",frame)
	runbindbtn:SetText("#apadventure.bindui.addrunbind")
	function runbindbtn:DoClick()
		local key = binder:GetValue()
		if key == 0 then return end
		local seln, seld = presetslct:GetSelected()
		APADV_RUNBINDS[key] = table.Copy(seld)
		APADV.RunBindsChanged = true
		loadbinds(bindlistcanvas)
	end

	function bindlistcanvas:PerformLayout(w,h)
		local curh = 5
		for k,v in ipairs(self.sortedbinds) do
			v:SetWidth(w-10)
			v:SetPos(5,curh)
			curh = curh + v:GetTall() + 5
		end
	end

	local rundatamngbtn = mkUI("DButton",frame)
	function rundatamngbtn:DoClick() savedatawindow() end
	rundatamngbtn:SetText("#apadventure.bindui.rundatamng")

	local drawer = mkUI("DDrawer",frame)
	drawer:SetOpenSize(200)
	if drawercvar:GetBool() then
		drawer:SetOpenTime(0)
		drawer:Open()
	end
	drawer:SetOpenTime(.3)

	local oldopen, oldclose = drawer.Open, drawer.Close
	function drawer:Open()
		oldopen(self)
		drawercvar:SetBool(true)
	end
	function drawer:Close()
		oldclose(self)
		drawercvar:SetBool(false)
	end

	local guidehtml = mkUI("DHTML",drawer)
	guidehtml:DockMargin(5,0,5,3)
	guidehtml:Dock(FILL)
	guidehtml:OpenURL("asset://garrysmod/data_static/apadventure/guide/base.txt")
	local txt = file.Read("data_static/apadventure/guide/"..locstr("apadventure.guidefolder").."/bindmenu.txt","GAME") or
		file.Read("data_static/apadventure/guide/en/bindmenu.txt","GAME")
	txt = txt and string.JavascriptSafe(txt)
	guidehtml:QueueJavascript("loadcontent(\""..(txt or "").."\")")

	local oldlayout = frame.PerformLayout
	function frame:PerformLayout(w,h)
		oldlayout(self,w,h)
		local w2 = (w-15)/2
		local dh = drawer:GetTall()
		bindlist:SetSize(w-10,h-86-dh-27)
		presetslct:SetSize(w-85,22)
		glbindbtn:SetSize(w2,22)
		runbindbtn:SetSize(w2,22)
		runbindbtn:SetPos(w2+10,57)
		rundatamngbtn:SetPos(5,h-dh-27)
		rundatamngbtn:SetSize(w-10,22)
	end
end

list.Set("DesktopWindows","apAdventureBinds",{
	icon = "archipelago/ap64.png",
	title = "#apadventure.bindui.title",
	width = 400, height = 500,
	init = BindWindow
})