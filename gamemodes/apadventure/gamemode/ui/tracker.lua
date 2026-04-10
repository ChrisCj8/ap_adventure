local trackerdata = {}
local grouploccount = {}

local netrstring = net.ReadString
local netruint = net.ReadUInt

local locstr = language.GetPhrase

local statustocolor = {
    [0] = Color(200,200,200),
    [1] = Color(200,255,200),
    [2] = Color(255,255,200),
    [3] = Color(255,200,200),
}

local trackwindow

local curgroup

net.Receive("APAdvTrackerReset",function()
    curgroup = netrstring()
    trackerdata = {}
    grouploccount = {}
    if IsValid(trackwindow) then
        trackwindow:Remove()
    end
end)

local mcguffincount
local mcguffingoal

local function setwindowtitle()
    trackwindow:SetTitle(locstr("apadventure.tracker.title").." - "..string.Interpolate(locstr("apadventure.tracker.title.goalinfo"),{goal=mcguffingoal,num=mcguffincount}))
end

net.Receive("APAdvMcGuffinInfo",function()
    mcguffincount =  net.ReadFloat()
    mcguffingoal = net.ReadFloat()
    if IsValid(trackwindow) then
        setwindowtitle()
    end
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
    if IsValid(trackwindow) then
        local grnodes = trackwindow.grnodelookup
        local mapnodes = trackwindow.nodelookup
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
    if IsValid(trackwindow) then
        if trackwindow.curgr == group and trackwindow.curmap == map then
            local locpnl = trackwindow.locpnls[loc]
            locpnl:SetBackgroundColor(statustocolor[state])
        end
        iconstoupdate[group] = iconstoupdate[group] or {}
        iconstoupdate[group][map] = true
        timer.Start("APAdvTrackerUpdateMapIcons")
    end
end)

net.Receive("APAdvTrackerExit",function()
    local group,map,name,tgtgr,tgtmap,tgtentr = netrstring(),netrstring(),netrstring(),netrstring(),netrstring(),netrstring()
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

local function opentracker(window)

    trackwindow = window

    if mcguffingoal then
        setwindowtitle()
    end

    local tree = uimake("DTree",window)

    local grnodelookup = {}
    window.grnodelookup = grnodelookup
    local nodelookup = {}
    window.nodelookup = nodelookup

    local map = game.GetMap()
    local curmapnode

    local function buildmaptree()
        for k,v in SortedPairs(trackerdata) do
            local groupnode = tree:AddNode(k,iconpick(grouploccount[k]))
            grnodelookup[k] = groupnode
            maplookup = {}
            for ik,iv in SortedPairs(v) do
                local mapnode = groupnode:AddNode(ik,iconpick(iv.loccount))
                mapnode.info = iv
                mapnode.map = ik
                mapnode.group = k
                if ik == map and k == curgroup then
                    curmapnode = mapnode
                end
                maplookup[ik] = mapnode
            end
            nodelookup[k] = maplookup
        end
    end
    buildmaptree()

    --[[ local infopnl = uimake("DScrollPanel",window)
    infopnl:SetPaintBackground(true)

        local oldlayout = infopnl.PerformLayout
        function infopnl:PerformLayout(w,h)
            oldlayout(self,w,h)


        end ]]

    local infolist = uimake("DCategoryList",window)

        local function emptylabel(parent,loc)
            local emptylbl = uimake("DLabel",parent)
            emptylbl:SetDark(true)
            emptylbl:SetText("#apadventure.tracker.empty."..loc)
            emptylbl:DockMargin(25,0,5,0)
            emptylbl:Dock(TOP)
        end

        local loccat = infolist:Add("#apadventure.tracker.lctns")
        loccat:DockPadding(0,0,0,10)
        --local l,t,r,b = loccat:GetDockPadding()
        --loccat:DockPadding(l,t,r,b+5)

            local function locpnllayout(self,w,h)
                self.lbl:SetWidth(w-45)
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

    function tree:OnNodeSelected(node)
        local info = node.info
        if info then
            loccat:Clear()
            local locpnls = {}
            if !next(info.lctn) then
                emptylabel(loccat,"lctn")
            else
                for k,v in SortedPairs(info.lctn) do
                    local locpnl = uimake("DPanel",loccat)
                    locpnl:SetBackgroundColor(statustocolor[v.state])
                    locpnl:SetHeight(25)
                    locpnl:DockMargin(5,5,5,0)
                    locpnl:Dock(TOP)
                    local loclbl = uimake("DLabel",locpnl)
                    loclbl:SetPos(35,3)
                    loclbl:SetDark(true)
                    loclbl:SetText(k)
                    locpnl.lbl = loclbl
                    locpnl.PerformLayout = locpnllayout
                    locpnls[k] = locpnl
                end
            end

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


    local oldlayout = window.PerformLayout
    function window:PerformLayout(w,h)
        oldlayout(self,w,h)
        
        tree:SetPos(5,30)
        tree:SetSize(150,h-35)

        --infopnl:SetPos(160,30)
        --infopnl:SetSize(w-165,h-35)

        infolist:SetPos(160,30)
        infolist:SetSize(w-165,h-35)
    end

    window:SetSizable(true)

    if curmapnode then
        curmapnode:GetParentNode():SetExpanded(true)
        tree:SetSelectedItem(curmapnode)
    end
end

list.Set("DesktopWindows","apAdventureTracker",{
    icon = "archipelago/ap64.png",
    title = "#apadventure.tracker.title",
    width = 700,
    height = 500,
    init = function(icon, window)
        opentracker(window)
    end
})