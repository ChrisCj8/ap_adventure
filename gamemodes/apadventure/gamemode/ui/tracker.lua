APADV.TrackerData = APADV.TrackerData or {}
APADV.GroupLocCount = APADV.GroupLocCount or {}
APADV.HintData = APADV.HintData or {}
APADV.SlotLookUp = APADV.SlotLookUp or {}
APADV.Hintables = APADV.Hintables or {{},{}}

local netrstring = net.ReadString
local netruint = net.ReadUInt
local netrbool = net.ReadBool

local locstr = language.GetPhrase

local statustocolor = {
    [0] = Color(200,200,200),
    [1] = Color(200,255,200),
    [2] = Color(255,255,200),
    [3] = Color(255,200,200),
}

local plyint = 16

net.Receive("APAdvTrackerReset",function()
	APADV.CurGroup = netrstring()
	APADV.TrackerData = {}
	APADV.GroupLocCount = {}
	APADV.HintData = {}
	APADV.SlotLookUp = {}
	APADV.CurSlot, APADV.CurTeam = netruint(plyint),netruint(plyint)
	APADV.HintCost = netruint(16)
	APADV.Hintables = {{},{}}
	local trackwindow = APADV.TrackWindow
    if IsValid(trackwindow) then
        trackwindow:Remove()
    end
end)

net.Receive("APAdvTrackerMiscInfo",function()
	local funcs = {
		[0] = function()
			local id = netruint(plyint)
			local name = netrstring()
			APADV.SlotLookUp[id] = name
		end,
		[1] = function()
			local hp = netruint(16)
			APADV.HintPoints = hp
			local trackwindow = APADV.TrackWindow
			if IsValid(trackwindow) then
				local canhint = hp >= APADV.HintCost
				trackwindow.itemhntbtn:SetEnabled(canhint)
				trackwindow:UpdateHintPointLbl()
				if trackwindow.lochntbtns then
					for k,v in ipairs(trackwindow.lochntbtns) do
						if IsValid(v) then v:SetEnabled(canhint) end
					end
				end
			end
		end
	}
	funcs[netruint(2)]()
end)

local function setwindowtitle()
	local window = APADV.TrackWindow
	if !IsValid(window) then return end
	local count, goal = APADV.McGuffinCount, APADV.McGuffinGoal
	if !count or !goal then window:SetTitle("#apadventure.tracker.title") return end
	window:SetTitle(locstr("apadventure.tracker.title").." - "..
		string.Interpolate(locstr("apadventure.tracker.title.goalinfo"),{
			goal = goal,
			num = count
		}))
end

net.Receive("APAdvMcGuffinInfo",function()
	APADV.McGuffinCount = net.ReadFloat()
	APADV.McGuffinGoal = net.ReadFloat()
	if IsValid(APADV.TrackWindow) then setwindowtitle() end
end)

local iconstoupdate = {}

local function iconpick(loccount)
    if !loccount then return "archipelago/tracker/empty.png" end
    local state1 = loccount[1]
    if loccount[1] and loccount[1] > 0 then
        if loccount[2] and loccount[2] > 0 then
            if loccount[3] and loccount[3] > 0 then
                return "archipelago/tracker/greenyellowred.png"
            end
            return "archipelago/tracker/greenyellow.png"
        end
        if loccount[3] and loccount[3] > 0 then
            return "archipelago/tracker/greenred.png"
        end
        return "archipelago/tracker/green.png"
    end
    if loccount[2] and loccount[2] > 0 then
        if loccount[3] and loccount[3] > 0 then
            return "archipelago/tracker/yellowred.png"
        end
        return "archipelago/tracker/yellow.png"
    end
    if loccount[3] and loccount[3] > 0 then
        return "archipelago/tracker/red.png"
    end
    if loccount[0] and loccount[0] > 0 then
        return "archipelago/tracker/grey.png"
    end
    return "archipelago/tracker/empty.png"
end

timer.Create("APAdvTrackerUpdateMapIcons",.5,0,function()
	local trackwindow = APADV.TrackWindow
    if IsValid(trackwindow) then
        local grnodes = trackwindow.grnodelookup
        local mapnodes = trackwindow.nodelookup
		local grouploccount = APADV.GroupLocCount
        for k,v in pairs(iconstoupdate) do
            grnodes[k]:SetIcon(iconpick(grouploccount[k]))
            local grmapnodes = mapnodes[k]
            for ik,iv in pairs(v) do
                local node = grmapnodes[ik]
                node:SetIcon(iconpick(node.info.loccount))
            end
        end
    end
    timer.Stop("APAdvTrackerUpdateMapIcons")
    iconstoupdate = {}
end)
timer.Stop("APAdvTrackerUpdateMapIcons")

net.Receive("APAdvTrackerLocation",function()
    local group, map, loc, state = netrstring(), netrstring(), netrstring(), netruint(3)
	local trackerdata = APADV.TrackerData
    trackerdata[group] = trackerdata[group] or {}
    trackerdata[group][map] = trackerdata[group][map] or {
        lctn = {},
        entr = {},
        exit = {},
        loccount = {},
    }
    local maptbl = trackerdata[group][map]
    local loctbl = maptbl.lctn
    local oldloc = loctbl[loc]
    local loccount = maptbl.loccount
	local grouploccount = APADV.GroupLocCount
    local grloccount = grouploccount[group]
    if !grloccount then
        grloccount = {}
        grouploccount[group] = grloccount
    end
    if oldloc then
        local oldstate = oldloc.state
        if oldstate != state then
            loccount[oldstate] = loccount[oldstate] - 1
            if loccount[state] then
                loccount[state] = loccount[state] + 1
            else
                loccount[state] = 1
            end

            grloccount[oldstate] = grloccount[oldstate] - 1
            if grloccount[state] then
                grloccount[state] = grloccount[state] + 1
            else
                grloccount[state] = 1
            end
            oldloc.state = state
        end
    else
        loctbl[loc] = {
            state = state
        }
        local statecount = loccount[state]
        if statecount then
            loccount[state] = statecount + 1
        else
            loccount[state] = 1
        end
        local grstatecount = grloccount[state]
        if grstatecount then
            grloccount[state] = grstatecount + 1
        else
            grloccount[state] = 1
        end
    end
	local trackwindow = APADV.TrackWindow
    if IsValid(trackwindow) then
        if trackwindow.curgr == group and trackwindow.curmap == map then
            local locpnl = trackwindow.locpnls[loc]
            locpnl:SetBackgroundColor(statustocolor[state])
			local hntbtn = locpnl.hntbtn
			if state == 0 and hntbtn then
				hntbtn:Remove()
				locpnl.hntbtn = nil
			end
        end
        iconstoupdate[group] = iconstoupdate[group] or {}
        iconstoupdate[group][map] = true
        timer.Start("APAdvTrackerUpdateMapIcons")
    end
end)

net.Receive("APAdvTrackerExit",function()
    local group,map,name,tgtgr,tgtmap,tgtentr = netrstring(),netrstring(),netrstring(),netrstring(),netrstring(),netrstring()
	local trackerdata = APADV.TrackerData
    trackerdata[group] = trackerdata[group] or {}
    trackerdata[group][map] = trackerdata[group][map] or {
        lctn = {},
        entr = {},
        exit = {},
        loccount = {},
    }
    trackerdata[group][map].exit[name] = {
        g = tgtgr,
        m = tgtmap,
        e = tgtentr,
    }
    trackerdata[tgtgr] = trackerdata[tgtgr] or {}
    trackerdata[tgtgr][tgtmap] = trackerdata[tgtgr][tgtmap] or {
        lctn = {},
        entr = {},
        exit = {},
        loccount = {},
    }
    trackerdata[tgtgr][tgtmap].entr[tgtentr] = {
        g = group,
        m = map,
        e = name,
    }
end)

local uimake = vgui.Create

local function mklbl(parent,text)
	local l = uimake("DLabel",parent)
	l:SetDark(true)
	if text then l:SetText(text) end
	return l
end

local statusbtn

local statuslookup = {
	[0] = "#apadventure.tracker.hint.status.unspec",
	[10] = "#apadventure.tracker.hint.status.noprio",
	[20] = "#apadventure.tracker.hint.status.avoid",
	[30] = "#apadventure.tracker.hint.status.prio",
	[40] = "#apadventure.tracker.hint.status.fnd",
}

local statuschoicelookup = {
	[10] = "NoPrioChoice",
	[20] = "AvoidChoice",
	[30] = "PrioChoice"
}

local statusimglookup = {
	[10] = "icon16/information.png",
	[20] = "icon16/error.png",
	[30] = "icon16/star.png",
	[40] = "icon16/accept.png"
}

net.Receive("APAdvTrackerHintUpdate",function()
	local fndr, loc = netruint(plyint), netrstring()
	local hnt = {
		rcvr = netruint(plyint),
		fndr = fndr,
		loc = loc,
		itm = netrstring(),
		flag = netruint(3),
		stat = netruint(6),
		entr = netrbool() and netrstring() or nil
	}
	local fndr, loc = hnt.fndr, hnt.loc
	local trackwindow = APADV.TrackWindow
	local trackeropen = IsValid(trackwindow)
	if fndr == APADV.CurSlot and trackeropen then
		local locpnls = trackwindow.locpnls
		local pnl = locpnls and locpnls[loc]
		if pnl then
			local hntbtn = pnl.hntbtn 
			local rcvr = hnt.rcvr
			if hntbtn then
				if rcvr != APADV.CurSlot then
					hntbtn:Remove()
					pnl.hntbtn = nil
				elseif hntbtn.hnt then
					local status = hnt.stat
					hntbtn:SetImage(statusimglookup[status] or "icon16/help.png")
					hntbtn:SetEnabled(status != 40)
				else
					hntbtn:Remove()
					pnl.hntbtn = statusbtn(pnl,hnt)
				end
			end
			pnl.hntlbl:SetText(hnt.itm)
			pnl.rcvrlbl:SetText(APADV.SlotLookUp[rcvr])
			pnl:InvalidateLayout()
		end
	end
	local fndrtbl = APADV.HintData[fndr]
	if !fndrtbl then
		fndrtbl = {}
		APADV.HintData[fndr] = fndrtbl
	end
	local old = fndrtbl[loc]
	if !old then
		fndrtbl[loc] = hnt
		if trackeropen then
			local hintlist = trackwindow.hintlist
			if IsValid(hintlist) then
				hintlist.AddHint(hnt)
				hintlist:InvalidateLayout(true)
				hintlist:SizeToChildren(false,true)
			end
		end
		return
	end
	local status, oldstatus = hnt.stat, old.stat
	if status == oldstatus then return end
	old.stat = status
	local pnls = old.pnl
	if !pnls then return end
	pnls:UpdateStatus(status)
end)

net.Receive("APAdvTrackerHintable",function()
	local gr = netruint(2)
	local str = netrstring()
	local tbl = APADV.Hintables[gr]
	tbl[#tbl+1] = str
end)

local function sethintstatus(hnt,val)
	net.Start("APAdvTrackerHintStatus")
		net.WriteUInt(hnt.fndr,plyint)
		net.WriteString(hnt.loc)
		net.WriteUInt(val,6)
	net.SendToServer()
end

local function statusselectmenu(btn)
	local menu = DermaMenu()
	menu:AddOption("#apadventure.tracker.hint.status.noprio",function() sethintstatus(btn.hnt,10) end):SetImage("icon16/information.png")
	menu:AddOption("#apadventure.tracker.hint.status.avoid",function() sethintstatus(btn.hnt,20) end):SetImage("icon16/error.png")
	menu:AddOption("#apadventure.tracker.hint.status.prio",function() sethintstatus(btn.hnt,30) end):SetImage("icon16/star.png")
	menu:Open()
end

function statusbtn(parent,hnt)
	if hnt.rcvr != APADV.CurSlot then
		local btn = uimake("DImage",parent)
		btn:SetSize(16,16)
		btn:SetImage(statusimglookup[hnt.stat] or "icon16/help.png")
		return btn
	end
	local btn = uimake("DImageButton",parent)
	btn.DoClick = statusselectmenu
	btn.hnt = hnt
	local status = hnt.stat
	btn:SetImage(statusimglookup[status] or "icon16/help.png")
	btn:SetEnabled(status != 40)
	btn:SetSize(16,16)
	return btn
end

local function updatestatus(pnl,val)
	local btn = pnl.statusbtn
	btn:SetImage(statusimglookup[val] or "icon16/help.png")
	btn:SetEnabled(val != 40)
	local lbl = pnl.statuslbl
	lbl:SetText(statuslookup[val] or "#apadventure.tracker.hint.status.unknown")
end

local function hintpopup(cmd,tgt)
	local fr = uimake("DFrame")
	fr:SetSize(300,200)
	fr:Center()
	fr:MakePopup()
	fr:SetBackgroundBlur(true)
	fr:SetTitle("#apadventure.tracker.hintpopup.title")

	local txtpnl = uimake("DPanel",fr)
	txtpnl:SetPos(5,30)
	txtpnl:SetSize(290,138)
	txtpnl:DockPadding(5,5,5,5)
	local txt = mklbl(txtpnl,string.Interpolate(locstr("apadventure.tracker.hintpopup.txt"),{
		cost = APADV.HintCost or "?",
		pnts = APADV.HintPoints or "?",
		tgt = tgt
	}))
	txt:Dock(FILL)
	txt:SetWrap(true)

	local ybtn = uimake("DButton",fr)
	ybtn:SetPos(5,173)
	ybtn:SetSize(142,22)
	ybtn:SetText("#apadventure.tracker.hintpopup.yes")
	function ybtn:DoClick()
		RunConsoleCommand("apadv_apsay",cmd)
		fr:Close()
	end

	local nbtn = uimake("DButton",fr)
	nbtn:SetPos(152,173)
	nbtn:SetSize(142,22)
	nbtn:SetText("#apadventure.tracker.hintpopup.no")
	function nbtn:DoClick()
		fr:Close()
	end
end

local function mappanel(window)
	local mappnl = uimake("DHorizontalDivider")
	local tree = uimake("DTree",mappnl)
	mappnl:SetLeft(tree)
	mappnl:SetLeftWidth(150)

    local grnodelookup = {}
    window.grnodelookup = grnodelookup
    local nodelookup = {}
    window.nodelookup = nodelookup

    local map = game.GetMap()
    local curmapnode

    local function buildmaptree()
		local grouploccount = APADV.GroupLocCount
        for k,v in SortedPairs(APADV.TrackerData) do
            local groupnode = tree:AddNode(k,iconpick(grouploccount[k]))
            grnodelookup[k] = groupnode
            maplookup = {}
            for ik,iv in SortedPairs(v) do
                local mapnode = groupnode:AddNode(ik,iconpick(iv.loccount))
                mapnode.info = iv
                mapnode.map = ik
                mapnode.group = k
                if ik == map and k == APADV.CurGroup then
                    curmapnode = mapnode
                end
                maplookup[ik] = mapnode
            end
            nodelookup[k] = maplookup
        end
    end
    buildmaptree()

    local infolist = uimake("DCategoryList")
	mappnl:SetRight(infolist)

        local function emptylabel(parent,loc)
            local emptylbl = uimake("DLabel",parent)
            emptylbl:SetDark(true)
            emptylbl:SetText("#apadventure.tracker.empty."..loc)
            emptylbl:DockMargin(25,0,5,0)
            emptylbl:Dock(TOP)
        end

        local loccat = infolist:Add("#apadventure.tracker.lctns")
        loccat:DockPadding(0,0,0,10)

            local function locpnllayout(self,w,h)
				local iw = w-10-15
				local hntbtn = self.hntbtn
				if hntbtn then
					iw = iw-21
					hntbtn:SetPos(w-21,5)
				end
				if iw > 360 then
					iw = iw-120
					self.rcvrlbl:SetSize(120,22)
				else
					self.rcvrlbl:SetSize(iw*.33,22)
					iw = iw*.66
				end
				self.rcvrlbl:SetPos(iw+15,3)
				local lw = iw*.6
				self.lbl:SetSize(lw,22)
				self.hntlbl:SetSize(iw*.4,22)
				self.hntlbl:SetPos(10+lw,3)
            end

			local function lochintbtnfunc(btn)
				local locname = btn:GetParent().lbl:GetText()
				hintpopup("!hint_location "..locname,locname)
			end

        local entrcat = infolist:Add("#apadventure.tracker.entrs")
        entrcat:DockPadding(0,0,0,10)

            local function entrpnllayout(self,w,h)
                local wthrd = (w-35)/3
                self.srclbl:SetWidth(wthrd*2)
                self.tgtlbl:SetWidth(wthrd)
                self.tgtlbl:SetPos(wthrd*2+30,3)
            end

            local function entrsrcclick(self)
                local info = self:GetParent().info
                local srcnode = nodelookup[info.g][info.m]
                srcnode:GetParentNode():SetExpanded(true)
                tree:SetSelectedItem(srcnode)
            end

        local exitcat = infolist:Add("#apadventure.tracker.exits")
        exitcat:DockPadding(0,0,0,10)

            local function exitpnllayout(self,w,h)
                local wthrd = (w-35)/3
                self.srclbl:SetWidth(wthrd)
                self.tgticon:SetPos(wthrd+5,5)
                self.tgtlbl:SetWidth(wthrd*2)
                self.tgtlbl:SetPos(wthrd+25,3)
            end

            local function exittgtclick(self)
                local info = self:GetParent().info
                local srcnode = nodelookup[info.g][info.m]
                srcnode:GetParentNode():SetExpanded(true)
                tree:SetSelectedItem(srcnode)
            end

	local hints = APADV.CurSlot and APADV.HintData[APADV.CurSlot]
	local slotLU = APADV.SlotLookUp

    function tree:OnNodeSelected(node)
        local info = node.info
		local canhint = APADV.HintCost <= APADV.HintPoints
		local curslot = APADV.CurSlot
		if info then
            loccat:Clear()
            local locpnls = {}
			local hntbtns, hntbtncnt = {}, 0
            if !next(info.lctn) then
                emptylabel(loccat,"lctn")
            else
                for k,v in SortedPairs(info.lctn) do
                    local locpnl = uimake("DPanel",loccat)
                    locpnl:SetBackgroundColor(statustocolor[v.state])
                    locpnl:SetHeight(25)
                    locpnl:DockMargin(5,5,5,0)
                    locpnl:Dock(TOP)
                    local loclbl = mklbl(locpnl,k)
                    loclbl:SetPos(5,3)
					local hint = hints and hints[k]
					local hntlbl = mklbl(locpnl,hint and hint.itm or "???")
					local rcvrlbl = mklbl(locpnl,hint and slotLU[hint.rcvr] or "(???)")
					rcvrlbl:SetSize(120,22)
					local hntbtn
					if !hint then
						if v.state != 0 then
							hntbtn = uimake("DImageButton",locpnl)
							hntbtn:SetSize(16,16)
							hntbtn:SetImage("icon16/help.png")
							hntbtn:SetEnabled(canhint)
							hntbtn.DoClick = lochintbtnfunc
						end
					else
						hntbtn = statusbtn(locpnl,hint)
					end
					if hntbtn then
						locpnl.hntbtn = hntbtn
						hntbtncnt = hntbtncnt + 1
						hntbtns[hntbtncnt] = hntbtn
					end
                    locpnl.lbl = loclbl
					locpnl.hntlbl = hntlbl
					locpnl.rcvrlbl = rcvrlbl
                    locpnl.PerformLayout = locpnllayout
                    locpnls[k] = locpnl
                end
            end
			window.lochntbtns = hntbtns

            entrcat:Clear()
            if !next(info.entr) then
                emptylabel(entrcat,"entr")
            else
                for k,v in SortedPairs(info.entr) do
                    local entrpnl = uimake("DPanel",entrcat)
                    entrpnl:SetHeight(26)
                    entrpnl:DockMargin(5,5,5,0)
                    entrpnl:Dock(TOP)
                    local srcicon = uimake("DImageButton",entrpnl)
                    srcicon:SetImage("icon16/magnifier.png")
                    srcicon:SetSize(16,16)
                    srcicon:SetPos(5,5)
                    srcicon.DoClick = entrsrcclick
                    local entrsrclbl = uimake("DLabel",entrpnl)
                    entrsrclbl:SetPos(25,3)
                    entrsrclbl:SetDark(true)
                    entrsrclbl:SetText(v.g.." - "..v.m.." - "..v.e)
                    entrpnl.srclbl = entrsrclbl
                    local entrtgtlbl = uimake("DLabel",entrpnl)
                    entrtgtlbl:SetPos(100,3)
                    entrtgtlbl:SetDark(true)
                    entrtgtlbl:SetText(k)
                    entrpnl.info = v
                    entrpnl.tgtlbl = entrtgtlbl
                    entrpnl.PerformLayout = entrpnllayout
                end
            end

            exitcat:Clear()
            if !next(info.exit) then
                emptylabel(exitcat,"exit")
            else
                for k,v in SortedPairs(info.exit) do
                    local exitpnl = uimake("DPanel",exitcat)
                    exitpnl:SetHeight(26)
                    exitpnl:DockMargin(5,5,5,0)
                    exitpnl:Dock(TOP)
                    local tgticon = uimake("DImageButton",exitpnl)
                    tgticon:SetImage("icon16/magnifier.png")
                    tgticon:SetSize(16,16)
                    tgticon:SetPos(5,5)
                    tgticon.DoClick = exittgtclick
                    exitpnl.tgticon = tgticon
                    local srclbl = uimake("DLabel",exitpnl)
                    srclbl:SetPos(5,3)
                    srclbl:SetDark(true)
                    srclbl:SetText(k)
                    exitpnl.srclbl = srclbl
                    local tgtlbl = uimake("DLabel",exitpnl)
                    tgtlbl:SetPos(100,3)
                    tgtlbl:SetDark(true)
                    tgtlbl:SetText(v.g.." - "..v.m.." - "..v.e)
                    exitpnl.info = v
                    exitpnl.tgtlbl = tgtlbl
                    exitpnl.PerformLayout = exitpnllayout
                end
            end

            window.locpnls = locpnls
            window.curmap = node.map
            window.curgr = node.group
        end
    end

    if curmapnode then
        curmapnode:GetParentNode():SetExpanded(true)
        tree:SetSelectedItem(curmapnode)
    end

	return mappnl
end

local iconup = "icon16/bullet_arrow_up.png"
local iconntrl = "icon16/bullet_black.png"
local icondwn = "icon16/bullet_arrow_down.png"

local function resetsortbtns(btns,curbtn)
	for k,v in ipairs(btns) do
		if v != curbtn then
			v:SetImage(iconntrl)
		end
	end
end

local sort = table.sort

local function mksortbtn(prnt,tgt,mklookup,sortbtns,canvas)
	local btn = uimake("DImageButton",prnt)
	btn:SetImage(iconntrl)
	btn:SetSize(16,16)
	local function menufunc(self)
		local lookup = {}
		local oldpos = {}
		for k,v in ipairs(tgt) do
			lookup[v] = mklookup(v)
			oldpos[v] = k
		end
		self.sorter(tgt,lookup,oldpos)
		btn:SetImage(self.img)
		resetsortbtns(sortbtns,btn)
		canvas:InvalidateLayout()
	end
	function btn:DoClick()
		local menu = DermaMenu()
		local asc = menu:AddOption("#apadventure.tracker.hint.sortasc",menufunc)
		function asc.sorter(tgt,lookup,old)
			sort(tgt,function(a,b)
				local aL, bL = lookup[a], lookup[b]
				if aL == bL then return old[a] < old[b] end
				return aL < bL
			end)
		end
		asc:SetImage(iconup)
		asc.img = iconup
		local desc = menu:AddOption("#apadventure.tracker.hint.sortdesc",menufunc)
		function desc.sorter(tgt,lookup,old)
			sort(tgt,function(a,b)
				local aL, bL = lookup[a], lookup[b]
				if aL == bL then return old[a] < old[b] end
				return aL > bL
			end)
		end
		desc:SetImage(icondwn)
		desc.img = icondwn
		menu:Open()
	end
	btn.targettbl = tgt
	return btn
end

local function mkhntpnl(prnt,hnt)
	local slotlookup = APADV.SlotLookUp
	local pnl = {hnt=hnt}
	local fndr = hnt.fndr
	local rcvr = hnt.rcvr
	local rcvrlbl = mklbl(prnt,slotlookup[rcvr] or rcvr)
	local itmlbl = mklbl(prnt,hnt.itm)
	local fndrlbl = mklbl(prnt,slotlookup[fndr] or fndr)
	local loclbl = mklbl(prnt,hnt.loc)
	local entrlbl = mklbl(prnt,hnt.entr or "Vanilla")

	pnl.statusbtn = statusbtn(prnt,hnt)

	local statuslbl = mklbl(prnt,statuslookup[hnt.stat] or "#apadventure.tracker.hint.status.unknown")
	statuslbl:SetSize(75,22)

	pnl.UpdateStatus = updatestatus

	pnl.rcvrlbl = rcvrlbl
	pnl.itmlbl = itmlbl
	pnl.fndrlbl = fndrlbl
	pnl.loclbl = loclbl
	pnl.entrlbl = entrlbl
	pnl.statuslbl = statuslbl
	return pnl
end

local function hintpanel(window)
	local self = uimake("DPanel")

	local hntptlbl = mklbl(self)
	hntptlbl:SetPos(5,5)
	local function updatehntptcnt()
		hntptlbl:SetText(string.Interpolate(locstr("#apadventure.tracker.hint.ptlbl"),{
			pts = APADV.HintPoints,
			cost = APADV.HintCost
		}))
	end
	updatehntptcnt()
	window.UpdateHintPointLbl = updatehntptcnt

	local scroll = uimake("DScrollPanel",self)
	local canvas = scroll:GetCanvas()
	scroll:SetPos(0,60)

	local rcvrlbl = mklbl(self,"#apadventure.tracker.hint.rcvr")
	local itmlbl = mklbl(self,"#apadventure.tracker.hint.itm")
	local fndrlbl = mklbl(self,"#apadventure.tracker.hint.fndr")
	local loclbl = mklbl(self,"#apadventure.tracker.hint.loc")
	local entrlbl = mklbl(self,"#apadventure.tracker.hint.entr")
	local statuslbl = mklbl(self,"#apadventure.tracker.hint.status")

	local hnts, hntcnt = {}, 0
	local function addhint(hnt)
		hntcnt = hntcnt + 1
		local hntpnl = mkhntpnl(canvas,hnt)
		hnts[hntcnt] = hntpnl
		hnt.pnl = hntpnl
	end
	for k,v in pairs(APADV.HintData) do
		for ik,iv in pairs(v) do addhint(iv) end
	end
	canvas.AddHint = addhint
	window.hintlist = canvas

	local sortbtns = {}

	local rcvrbtn = mksortbtn(self,hnts,function(v) return v.rcvrlbl:GetText() end,sortbtns,canvas)
	sortbtns[1] = rcvrbtn

	local itmbtn = mksortbtn(self,hnts,function(v) return v.itmlbl:GetText() end,sortbtns,canvas)
	sortbtns[2] = itmbtn

	local fndrbtn = mksortbtn(self,hnts,function(v) return v.fndrlbl:GetText() end,sortbtns,canvas)
	sortbtns[3] = fndrbtn

	local locbtn = mksortbtn(self,hnts,function(v) return v.loclbl:GetText() end,sortbtns,canvas)
	sortbtns[4] = locbtn

	local entrbtn = mksortbtn(self,hnts,function(v) return v.entrlbl:GetText() end,sortbtns,canvas)
	sortbtns[5] = entrbtn

	local statusbtn = mksortbtn(self,hnts,function(v) return v.hnt.stat end,sortbtns,canvas)
	sortbtns[6] = statusbtn

	local itemhntslct = uimake("DComboBox",self)
	itemhntslct:SetSortItems(false)
	itemhntslct:AddChoice("McGuffin",nil,true)
	itemhntslct:AddChoice("Bunnyhop")
	itemhntslct:AddChoice("Trap Vision")
	for k,v in ipairs(APADV.Hintables) do
		itemhntslct:AddSpacer()
		for ik,iv in ipairs(v) do
			itemhntslct:AddChoice(iv)
		end
	end

	local itemhntbtn = uimake("DButton",self)
	itemhntbtn:SetText("#apadventure.tracker.hint.itmhnt")
	function itemhntbtn:DoClick()
		local item = itemhntslct:GetSelected()
		hintpopup("!hint "..item,item)
	end
	itemhntbtn:SetSize(100,22)
	itemhntbtn:SetEnabled(APADV.HintCost <= APADV.HintPoints)
	window.itemhntbtn = itemhntbtn

	function canvas:PerformLayout(w,h)
		local curh = 5
		local iw = w-10
		local hntiw = w-10-25-100
		local ws = hntiw/5
		local nw = 120
		if ws < nw then
			nw = ws
		else
			ws = (hntiw-nw*2)/3
		end

		local itmpos = 10+nw
		local fndrpos = 15+ws+nw
		local locpos = 20+ws+nw*2
		local entrpos = 25+ws*2+nw*2
		local statuspos = w-100
		local statuslblpos = w-80

		local headh = 60-27
		local btnh = headh+4
		rcvrlbl:SetPos(5,headh)
		rcvrlbl:SetSize(nw-20,22)
		rcvrbtn:SetPos(itmpos-21,btnh)
		itmlbl:SetPos(itmpos,headh)
		itmlbl:SetSize(ws-20,22)
		itmbtn:SetPos(fndrpos-21,btnh)
		fndrlbl:SetPos(fndrpos,headh)
		fndrlbl:SetSize(nw,22)
		fndrbtn:SetPos(locpos-21,btnh)
		loclbl:SetPos(locpos,headh)
		loclbl:SetSize(ws-20,22)
		locbtn:SetPos(entrpos-21,btnh)
		entrlbl:SetPos(entrpos,headh)
		entrlbl:SetSize(ws,22)
		entrbtn:SetPos(statuspos-21,btnh)
		statuslbl:SetPos(statuspos,headh)
		statuslbl:SetSize(74,22)
		statusbtn:SetPos(statuspos+78,btnh)

		for k,v in ipairs(hnts) do
			v.rcvrlbl:SetPos(5,curh)
			v.rcvrlbl:SetSize(nw,22)
			v.itmlbl:SetPos(itmpos,curh)
			v.itmlbl:SetSize(ws,22)
			v.fndrlbl:SetPos(fndrpos,curh)
			v.fndrlbl:SetSize(nw,22)
			v.loclbl:SetPos(locpos,curh)
			v.loclbl:SetSize(ws,22)
			v.entrlbl:SetPos(entrpos,curh)
			v.entrlbl:SetSize(ws,22)
			v.statusbtn:SetPos(statuspos,curh+3)
			v.statuslbl:SetPos(statuslblpos,curh)
			curh = curh + 27
		end
	end

	local drawcol = surface.SetDrawColor
	local drawln = surface.DrawLine
	local drawrect = surface.DrawRect
	function canvas:Paint(w,h)
		local lnend = w-6
		drawcol(0,0,0,20)
		for i=1,hntcnt,2 do
			
			local curh = i*27
			drawrect(0,curh,w,27)
		end
	end

	function self:PerformLayout(w,h)
		hntptlbl:SetSize(w,22)
		scroll:SetSize(w,h-60-32)
		itemhntslct:SetPos(5,h-27)
		itemhntslct:SetSize(w-115,22)
		itemhntbtn:SetPos(w-105,h-27)
	end

	return self
end

local function opentracker(window)

	APADV.TrackWindow  = window
	setwindowtitle()

	local tabs = uimake("DPropertySheet",window)
	tabs:Dock(FILL)

	local mappnl = mappanel(window)
	local maptab = tabs:AddSheet("#apadventure.tracker.tab.map",mappnl,"icon16/map.png")

	local hntpnl = hintpanel(window)
	local hnttab = tabs:AddSheet("#apadventure.tracker.tab.hint",hntpnl,"icon16/information.png")

    window:SetSizable(true)
end

list.Set("DesktopWindows","apAdventureTracker",{
    icon = "archipelago/ap64.png",
    title = "#apadventure.tracker.title",
    width = 900,
    height = 600,
    init = function(icon, window)
        opentracker(window)
    end
})