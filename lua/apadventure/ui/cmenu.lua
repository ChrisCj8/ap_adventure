local editcfg = apAdventure.EditCfg
local UImake = vgui.Create
local band = bit.band

local bool2yn = { [true] = "yes", [false] = "no" }

local function LocStrExists(str)
    return language.GetPhrase(str) != str
end

local function BitFlipper(inval,flip,onoff)
    local biton = band(inval,flip) != 0
    if biton and !onoff then
        return inval - flip
    elseif !biton and onoff then
        return inval + flip
    end
    return inval
end

local function ErrorNotif(text,time)
    notification.AddLegacy("#apadventure.editor.error."..text,NOTIFY_ERROR,time or 3)
    surface.PlaySound("buttons/button10.wav")
end

local function ShowContents(self,show)
    if show == self.ContentsVisible then return end
    for k,v in ipairs(self:GetChildren()) do
        v:SetVisible(show)
    end
    self.ContentsVisible = show
end

local function ImageButton(parent,image) 
    local btn = UImake("DImageButton",parent)
    btn:SetImage(image)
    btn:SetSize(16,16)
    return btn
end

local function Label(parent,locstr)
    local lbl = UImake("DLabel",parent)
    lbl:SetDark(true)
    lbl:SetText("#apadventure.editor."..locstr..".label")
    return lbl
end

local function LabelTextInput(parent,locstr)
    return Label(parent,locstr), UImake("DTextEntry",parent)
end

local function LabelNumWang(parent,locstr)
    return Label(parent,locstr), UImake("DNumberWang",parent)
end

local function LabelNumWangWithPreset(parent,locstr,presettbl)
    local base = UImake("DPanel",parent)
    base:SetPaintBackground(false)
    base:SetSize(100,22)
    local label, numw = LabelNumWang(base,locstr)
    local presetsel = UImake("DComboBox",base)
    for k,v in ipairs(presettbl) do
        presetsel:AddChoice(v.val.." - "..v.name,v.val,v.default,v.icon)
    end
    function presetsel:OnSelect(ind,val,data)
        numw:SetValue(data)
    end
    return base, label, numw, presetsel
end

local helpbubble

local helppnlclr = Color(255,255,205)

local function HelpPopup(helptext,w,creator)

    if !creator then return end

    local pnl = UImake("DPanel")
    pnl:SetBackgroundColor(helppnlclr)
    pnl.creator = creator
    function pnl:Think()
        local creator = self.creator
        if !IsValid(creator) or vgui.GetHoveredPanel() != creator then
            self:Remove()
        end
    end

    local text = UImake("DLabel",pnl)
    text:SetPos(5,5)
    text:SetSize(w-10,10)
    text:SetWrap(true)
    text:SetAutoStretchVertical(true)
    text:SetTextColor(color_black) -- set the color to black here rather than using set dark in case derma skins set it to something weird
    text:SetText(helptext)

    local cursorx, cursory = gui.MousePos()

    timer.Simple(0,function()
        local _,texth = text:GetSize()
        pnl:SetSize(w,texth+10)
        pnl:SetPos(cursorx-w-30,cursory-(texth/2)-5)
    end)

    pnl:MakePopup()

    return pnl
end

local drawerconv = CreateClientConVar("apadventure_editor_help_drawer_state",1,true,false,"Used to save the state of the help drawer in the Editor UI.",0,1)

local mapsettings = apAdventure.CfgSettingsOrdered
local mapsettingslookup = apAdventure.CfgSettings

local numwdefaultcolor
local checkboxdefaultcolor = color_black
local lightblue = Color(100,167,255)

local reqpnl = include("apadventure/ui/require.lua")

return function(window)
    local mbar = UImake("DMenuBar",window)
    mbar:DockMargin(-2,-5,-2,0)

    local configloaded = editcfg.Group != ""
    local filemenu = mbar:AddMenu("#apadventure.editor.menu.file")
    filemenu:AddOption("#apadventure.editor.menu.file.manage",function() include("apadventure/ui/loadmenu.lua")() end)
    local reloadoption = filemenu:AddOption("#apadventure.editor.menu.file.reload",function()
        RunConsoleCommand("apadventure_editor_loadcfg")
    end)
    --reloadoption:SetIcon("icon16/arrow_refresh.png")
    reloadoption:SetEnabled(configloaded)
    local saveoption = filemenu:AddOption("#apadventure.editor.menu.file.save",function() RunConsoleCommand("apadventure_editor_savecfg") end)
    saveoption:SetEnabled(configloaded)
    filemenu:AddOption("#apadventure.editor.menu.file.saveto",function() include("apadventure/ui/savemenu.lua")() end)
    window.SaveOption, window.ReloadOption = saveoption, reloadoption

    local logicmenu = mbar:AddMenu("#apadventure.editor.menu.logic")
    logicmenu:AddOption("#apadventure.editor.menu.logic.updateallcfgs",function() RunConsoleCommand("apadventure_update_all_cfgs") end)

    local miscmenu = mbar:AddMenu("#apadventure.editor.menu.misc")
    miscmenu:AddOption("#apadventure.editor.menu.misc.savemanage",function() RunConsoleCommand("apadventure_save_manager") end)

    local tabs = UImake("DPropertySheet",window)
    tabs:SetPos(5,50)

    local grouptbl, infotbl = editcfg.GroupInfo, editcfg.Info
    local groupupdate, groupupdatecount, mapupdate, mapupdatecount, infoinputs  = {},0,{},0,{}

    local groupcfgpnl = UImake("DScrollPanel")
    local groupcfgcanvas = groupcfgpnl:GetCanvas()
    groupcfgpnl:SetPaintBackground(true)
    groupcfgcanvas:DockPadding(5,5,5,5)
    local newtab = tabs:AddSheet("#apadventure.editor.tab.group",groupcfgpnl)
    newtab.Tab.guide = "grouptab"

        local grouppnlbuild = {
            numwpreset = function(tbl,valname)
                local default = tbl.default
                local base, lbl, numw, pres = LabelNumWangWithPreset(groupcfgcanvas,valname,tbl.presets)
                lbl:SetPos(0,0)
                lbl:SetSize(100,22)
                numw:SetPos(105,0)
                numw:SetSize(50,22)
                pres:SetPos(160,0)
                function base:PerformLayout(w,h)
                    pres:SetSize(w-160,22)
                end
                numwdefaultcolor = numwdefaultcolor or numw:GetTextColor()
                numw:SetMinMax(tbl.min,tbl.max)
                local laststate
                local oldvalue = grouptbl[valname] or default
                function numw:OnValueChanged(val)
                    if val == default then
                        grouptbl[valname] = nil
                        if !laststate then
                            laststate = true
                            numw:SetTextColor(lightblue)
                        end
                    else
                        grouptbl[valname] = val
                        if laststate then
                            laststate = false
                            numw:SetTextColor(numwdefaultcolor)
                        end
                    end
                    local maprulein = infoinputs[valname]
                    if IsValid(maprulein) and maprulein:GetValue() == oldvalue then
                        maprulein:SetValue(val)
                    end
                    oldvalue = val
                end
                numw:SetValue(grouptbl[valname] or default)
                groupupdatecount = groupupdatecount + 1
                groupupdate[groupupdatecount] = { p = numw, n = valname }
                return base
            end,
            check = function(tbl,valname)
                local check = UImake("DCheckBoxLabel",groupcfgcanvas)
                check:SetText("#apadventure.editor."..valname..".label")
                check:SetDark(true)
                check.helppos = check:GetTall()/2-8
                checkboxdefaultcolor = checkboxdefaultcolor or check.Label:GetTextColor()
                local oldval = default
                function check:OnChange(val)
                    grouptbl[valname] = val
                    local maprulein = infoinputs[valname]
                    if IsValid(maprulein) and tobool(oldval) == maprulein:GetChecked() then
                        maprulein:SetChecked(val)
                    end
                    oldval = val
                end
                check:SetValue(grouptbl[valname] or default)
                groupupdatecount = groupupdatecount + 1
                groupupdate[groupupdatecount] = { p = check, n = valname }
                return check, 2
            end,
            requi = function(tbl,valname)
                local reqpnl = reqpnl(groupcfgpnl)
                grouptbl[valname] = grouptbl[valname] or {}
                reqpnl:SetTargetTbl(grouptbl[valname])
                groupupdatecount = groupupdatecount + 1
                groupupdate[groupupdatecount] = {
                    p = function(val)
                        reqpnl:SetTargetTbl(val)
                        grouptbl[valname] = val
                    end,
                    n = valname
                }
                return reqpnl
            end
        }

        local helppnls = {}
        for k,v in ipairs(mapsettings) do
            local settingname = v.name
            local pnl, dockbonus = grouppnlbuild[v.type](v,settingname)
            local helpstr = "apadventure.editor."..settingname..".help"
            groupcfgcanvas:Add(pnl)
            pnl:Dock(TOP)
            pnl:DockMargin(5,dockbonus or 0,25,5+(dockbonus or 0))

            if LocStrExists(helpstr) then
                local help = ImageButton(groupcfgcanvas,"icon16/help.png")
                function help:DoClick()
                    local cfgw = groupcfgpnl:GetSize()
                    HelpPopup("#"..helpstr,cfgw-100,self)
                end
                pnl.help = help
                helppnls[#helppnls+1] = pnl
            end
        end

        function groupcfgcanvas:PerformLayout(w,h)
            for k,v in ipairs(helppnls) do
                local x,y = v:GetPos()
                v.help:SetPos(w-25,y+(v.helppos or 2))
            end
            groupcfgpnl:InvalidateLayout()
        end

    local mapcfgpnl = UImake("DScrollPanel")
    local mapcfgcanvas = mapcfgpnl:GetCanvas()
    mapcfgpnl:SetPaintBackground(true)
    mapcfgcanvas:DockPadding(5,5,5,5)
    newtab = tabs:AddSheet("#apadventure.editor.tab.map",mapcfgpnl)
    newtab.Tab.guide = "maptab"

        local base = UImake("DPanel",parent)
        base:SetPaintBackground(false)
        base:SetSize(100,22)
        local mapnicenamelbl, mapnicenamein = LabelTextInput(base,"nicename")
        mapnicenamein:SetPos(105,0)
        mapnicenamein:SetValue(infotbl.nicename or "")
        function mapnicenamein:OnChange()
            local val = self:GetValue()
            infotbl.nicename = val != "" and val or nil
        end
        function base:PerformLayout(w,h)
            mapnicenamein:SetSize(w-105,22)
        end
        mapcfgcanvas:Add(base)
        base:Dock(TOP)
        base:DockMargin(5,2,25,7)

        local rulespanelbuilders = {
            numwpreset = function(tbl,valname)
                --InfoNumwPreset(tbl.name,tbl.presets,tbl.default,tbl.min,tbl.max)
                local default = tbl.default
                local base, lbl, numw, pres = LabelNumWangWithPreset(mapcfgcanvas,valname,tbl.presets)
                lbl:SetPos(0,0)
                lbl:SetSize(100,22)
                numw:SetPos(105,0)
                numw:SetSize(50,22)
                pres:SetPos(160,0)
                function base:PerformLayout(w,h)
                    pres:SetSize(w-160,22)
                end
                numw:SetMinMax(tbl.min,tbl.max)
                numwdefaultcolor = numwdefaultcolor or numw:GetTextColor()
                local laststate
                function numw:OnValueChanged(val) 
                    local groupval = grouptbl[valname]
                    if val == groupval or (groupval == nil and val == default ) then
                        infotbl[valname] = nil
                        if !laststate then
                            laststate = true
                            numw:SetTextColor(lightblue)
                        end
                    else
                        infotbl[valname] = val
                        if laststate then
                            laststate = false
                            numw:SetTextColor(numwdefaultcolor)
                        end
                    end
                end
                numw:SetValue(infotbl[valname] or grouptbl[valname] or default)
                mapupdatecount = mapupdatecount + 1
                mapupdate[mapupdatecount] = { p = numw, n = valname }
                infoinputs[valname] = numw
                return base
            end,
            check = function(tbl,valname)
                local check = UImake("DCheckBoxLabel",mapcfgcanvas)
                check:SetText("#apadventure.editor."..valname..".label")
                check:SetDark(true)
                check.helppos = check:GetTall()/2-8
                checkboxdefaultcolor = checkboxdefaultcolor or check.Label:GetTextColor()
                function check:OnChange(val)
                    if val == grouptbl[valname] then
                        infotbl[valname] = nil
                        self:SetTextColor(lightblue)
                    else
                        infotbl[valname] = val
                        self:SetTextColor(checkboxdefaultcolor)
                    end
                end
                check:SetValue(infotbl[valname] or grouptbl[valname] or default)
                mapupdatecount = mapupdatecount + 1
                mapupdate[mapupdatecount] = { p = check, n = valname }
                infoinputs[valname] = check
                return check, 2
            end,
            requi = function(tbl,valname)
                local reqpnl = reqpnl(mapcfgpnl)
                infotbl[valname] = infotbl[valname] or {}
                reqpnl:SetTargetTbl(infotbl[valname])
                mapupdatecount = mapupdatecount + 1
                mapupdate[mapupdatecount] = {
                    p = function(val)
                        reqpnl:SetTargetTbl(val)
                        infotbl[valname] = val
                    end,
                    n = valname
                }
                return reqpnl
            end
        }

        local helppnls = {}
        for k,v in ipairs(mapsettings) do
            local pnl, dockbonus = rulespanelbuilders[v.type](v,v.name)
            local helpstr = "apadventure.editor."..v.name..".help"
            mapcfgcanvas:Add(pnl)
            pnl:Dock(TOP)
            pnl:DockMargin(5,dockbonus or 0,25,5+(dockbonus or 0))

            if LocStrExists(helpstr) then
                local help = ImageButton(mapcfgcanvas,"icon16/help.png")
                function help:DoClick()
                    local cfgw = mapcfgpnl:GetSize()
                    HelpPopup("#"..helpstr,cfgw-100,self)
                end
                pnl.help = help
                helppnls[#helppnls+1] = pnl
            end
        end

        function mapcfgcanvas:PerformLayout(w,h)
            for k,v in ipairs(helppnls) do
                local x,y = v:GetPos()
                v.help:SetPos(w-25,y+(v.helppos or 2))
            end
            mapcfgpnl:InvalidateLayout()
        end

    local regpnl = UImake("DPanel")
    newtab = tabs:AddSheet("#apadventure.editor.tab.reg",regpnl)
    newtab.Tab.guide = "regiontab"

        local regtbl

        local regnamein = UImake("DTextEntry",regpnl)
        regnamein:SetPos(5,5)

        local reglist = UImake("DListView",regpnl)
        reglist:SetPos(5,30)
        reglist:AddColumn("#apadventure.editor.reg.regcol")

        local regaddbtn = ImageButton(regpnl,"icon16/add.png")
        local regdelbtn = ImageButton(regpnl,"icon16/delete.png")

        local regeditpnl = UImake("DScrollPanel",regpnl)
        regeditpnl:SetPos(160,30)
        regeditpnl.ContentsVisible = true
        regeditpnl.ShowContents = ShowContents

            local regcondpnl = include("apadventure/ui/condpnl.lua")(regeditpnl)
            regcondpnl:SetLabel("#apadventure.editor.reg.condpnl")
            regeditpnl:ShowContents(false)

            local oldlayout = regeditpnl.PerformLayout
            function regeditpnl:PerformLayout(w,h)
                oldlayout(self,w,h)
                regcondpnl:SetWidth(w-30)
            end

        function regaddbtn:DoClick()
            local name = regnamein:GetValue()
            if name == "" then ErrorNotif("noregname") return end
            if name[1] == " " then ErrorNotif("regleadspace") return end
            if name[#name] == " " then ErrorNotif("regtrailspace") return end
            if !regtbl[name] then
                regtbl[name] = { ammo = {} }
                local ln = reglist:AddLine(name)
                regeditpnl:ShowContents(true)
            end
        end

        function regdelbtn:DoClick()
            local didstuff
            for k,v in ipairs(reglist:GetSelected()) do
                local name = v:GetValue(1)
                regtbl[name] = nil
                reglist:RemoveLine(v:GetID())
                didstuff = true
            end
            if didstuff then regeditpnl:ShowContents(false) end
        end

        function reglist:OnRowSelected(index,pnl)
            local newtbl = regtbl[pnl:GetValue(1)]
            newtbl.ammo = newtbl.ammo or {}
            regeditpnl.curreg = newtbl
            regcondpnl:SetTargetTbl(newtbl.ammo)
            regeditpnl:ShowContents(true)
        end

        function reglist:OnRowRightClick(id,pnl)
            local menu = DermaMenu()
            menu:AddOption("#apadventure.editor.reg.rclick.copyname",function()
                SetClipboardText(pnl:GetValue(1))
            end)
            menu:Open()
        end

        function reglist:LoadInfo(tbl)
            regtbl = tbl
            for k,v in pairs(self:GetLines()) do
                self:RemoveLine(v:GetID())
            end
            for k,v in pairs(tbl) do
                self:AddLine(k)
            end
            regeditpnl:ShowContents(false)
        end
        reglist:LoadInfo(editcfg.Regions)

        function regpnl:PerformLayout(w,h)
            regnamein:SetSize(w-50,22)
            regaddbtn:SetPos(w-42,8)
            regdelbtn:SetPos(w-22,8)
            reglist:SetSize(150,h-35)
            regeditpnl:SetSize(w-165,h-35)
        end

    local connpnl = UImake("DPanel")
    newtab = tabs:AddSheet("#apadventure.editor.tab.conn",connpnl)
    newtab.Tab.guide = "connecttab"

        local conntbl

        local curcon, curconline = false, false

        local connlist = UImake("DListView",connpnl)
        connlist:SetPos(5,30)
        connlist:AddColumn("#apadventure.editor.conn.fromcol")
        connlist:AddColumn("#apadventure.editor.conn.tocol")
        connlist:AddColumn("#apadventure.editor.conn.twcol")

        local connfromin = UImake("DTextEntry",connpnl)
        connfromin:SetPos(5,5)

        local conntoin = UImake("DTextEntry",connpnl)
        conntoin:SetPos(5,5)

        local connaddbtn = ImageButton(connpnl,"icon16/add.png")
        local conndelbtn = ImageButton(connpnl,"icon16/delete.png")

        local coneditpnl = UImake("DPanel",connpnl)
        coneditpnl.ContentsVisible = true
        coneditpnl.ShowContents = ShowContents

            local contwowaycheck = UImake("DCheckBoxLabel",coneditpnl)
            contwowaycheck:SetText("#apadventure.editor.conn.twowaycheck")
            contwowaycheck:SetDark(true)
            contwowaycheck:SetPos(5,5)
            function contwowaycheck:OnChange(val)
                if curcon then
                    curcon.twoway = val
                    curconline:SetValue(3,bool2yn[val])
                end
            end

            local conaccessedit = include("apadventure/ui/access.lua")(coneditpnl)
            conaccessedit:SetPos(5,30)

            coneditpnl:ShowContents(false)

            function coneditpnl:PerformLayout(w,h)
                conaccessedit:SetSize(w-10,300)
            end

        local function newconn(from,to)
            conntbl[from] = conntbl[from] or {}
            if conntbl[from][to] then return end
            local tbl = {twoway = false}
            conntbl[from][to] = tbl
            connlist:AddLine(from,to,bool2yn[false])
            coneditpnl:ShowContents(true)
            return tbl
        end

        function connaddbtn:DoClick()
            local from = connfromin:GetValue()
            local to = conntoin:GetValue()
            if from == "" then ErrorNotif("nosrcname") return end
            if from[1] == " " then ErrorNotif("srcleadspace") return end
            if to == "" then ErrorNotif("notgtname") return end
            if to[1] == " " then ErrorNotif("tgtleadspace") return end
            if from[#from] == " " then ErrorNotif("srctrailspace") return end
            if to[#to] == " " then ErrorNotif("tgttrailspace") return end
            newconn(from,to)
        end

        function conndelbtn:DoClick()
            local didstuff
            for k,v in ipairs(connlist:GetSelected()) do
                local from = v:GetValue(1)
                local to = v:GetValue(2)
                conntbl[from][to] = nil 

                if !next(conntbl[from]) then
                    conntbl[from] = nil
                end
                connlist:RemoveLine(v:GetID())
                didstuff = true
            end
            if didstuff then coneditpnl:ShowContents(false) end
        end

        function connlist:OnRowSelected(index,pnl)
            local from = pnl:GetValue(1)
            local to = pnl:GetValue(2)

            curcon = conntbl[from][to]
            curconline = pnl

            conaccessedit:LoadTbl(curcon)
            contwowaycheck:SetChecked(curcon.twoway)

            coneditpnl:ShowContents(true)
        end

        function connlist:OnRowRightClick(id,pnl)
            local menu = DermaMenu()
            menu:AddOption("#apadventure.editor.conn.rclick.copyfrom",function()
                SetClipboardText(pnl:GetValue(1))
            end)
            menu:AddOption("#apadventure.editor.conn.rclick.copyto",function()
                SetClipboardText(pnl:GetValue(2))
            end)
            menu:AddSpacer()
            menu:AddOption("#apadventure.editor.conn.rclick.invertdupe",function()
                local from = pnl:GetValue(2)
                local to = pnl:GetValue(1)
                local tbl = newconn(from,to)
                if tbl then
                    local src = conntbl[to][from]
                    tbl.access = table.Copy(src.access)
                    tbl.twoway, src.twoway = false, false
                    pnl:SetValue(3,"no")
                end
            end)
            menu:Open()
        end

        function connlist:LoadInfo(tbl)
            conntbl = tbl
            for k,v in pairs(self:GetLines()) do
                self:RemoveLine(v:GetID())
            end
            for k,v in pairs(tbl) do
                for ik, iv in pairs(v) do
                    self:AddLine(k,ik,bool2yn[iv.twoway])
                end
            end
            coneditpnl:ShowContents(false)
        end
        connlist:LoadInfo(editcfg.Connections)

        function connpnl:PerformLayout(w,h)
            local w1 = (w-55)/2
            connfromin:SetSize(w1,22)
            conntoin:SetSize(w1,22)
            conntoin:SetPos(w1+10,5)

            connaddbtn:SetPos(w-42,8)

            conndelbtn:SetPos(w-22,8)

            connlist:SetSize(300,h-35)

            coneditpnl:SetPos(310,30)
            coneditpnl:SetSize(w-315,h-35)
        end

    local mapitempnl = UImake("DPanel")
    newtab = tabs:AddSheet("#apadventure.editor.tab.mapitem",mapitempnl)
    newtab.Tab.guide = "mapitemtab"

        local mapitemtbl

        local mapitemnamein = UImake("DTextEntry",mapitempnl)
        mapitemnamein:SetPos(5,5)

        local mapitemaddbtn = ImageButton(mapitempnl,"icon16/add.png")
        local mapitemcopybtn = ImageButton(mapitempnl,"icon16/page_copy.png")
        local mapitemdelbtn = ImageButton(mapitempnl,"icon16/delete.png")

        local mapitemlist = UImake("DListView",mapitempnl)
        mapitemlist:SetPos(5,30)
        mapitemlist:AddColumn("#apadventure.editor.mapitem.itemcol")

        function mapitemlist:LoadMapItems(tbl)
            mapitemtbl = tbl
            for k,v in pairs(self:GetLines()) do 
                self:RemoveLine(v:GetID())
            end
            for k,v in pairs(tbl) do
                local ln = self:AddLine(k)
                ln.itemtbl = v
            end
        end
        mapitemlist:LoadMapItems(editcfg.MapItems)

        local mapitemeditpnl = UImake("DPanel",mapitempnl)
        mapitemeditpnl:SetPos(160,30)
        mapitemeditpnl.ContentsVisible = true
        mapitemeditpnl.ShowContents = ShowContents

            local mapitemamtlbl, mapitemamtin = LabelNumWang(mapitemeditpnl,"mapitem.amount")
            mapitemamtlbl:SetPos(5,5)

            mapitemamtin:SetMin(1)
            mapitemamtin:SetSize(40,22)
            function mapitemamtin:OnValueChanged(val)
                mapitemeditpnl.itemtbl.amt = math.floor(val)
            end

            local function FlagCheck(locstr,flag)
                local check = UImake("DCheckBoxLabel",mapitemeditpnl)
                check:SetDark(true)
                check:SetText("#apadventure.editor.mapitem."..locstr..".label")
                function check:OnChange(val)
                    mapitemeditpnl.itemtbl.fl = BitFlipper(mapitemeditpnl.itemtbl.fl,flag,val)
                end
                return check
            end

            mapitemprogressioncheck = FlagCheck("progression",1)
            mapitemprogressioncheck:SetPos(5,30)
            mapitemusefulcheck = FlagCheck("useful",2)
            mapitemusefulcheck:SetPos(5,55)
            mapitemtrapcheck = FlagCheck("trap",4)
            mapitemtrapcheck:SetPos(5,80)
            mapitemskipbalancecheck = FlagCheck("skipbalance",8)
            mapitemskipbalancecheck:SetPos(5,105)
            mapitemdepriocheck = FlagCheck("deprio",16)
            mapitemdepriocheck:SetPos(5,130)

            function mapitemprogressioncheck:OnChange(val)
                mapitemeditpnl.itemtbl.fl = BitFlipper(mapitemeditpnl.itemtbl.fl,1,val)
                if !val then
                    mapitemskipbalancecheck:SetValue(false)
                    mapitemdepriocheck:SetValue(false)
                end
                mapitemskipbalancecheck:SetEnabled(val)
                mapitemdepriocheck:SetEnabled(val)
            end

            mapitemeditpnl:ShowContents(false)

            function mapitemeditpnl:PerformLayout(w,h)
                mapitemamtlbl:SetSize(w-50,22)
                mapitemamtin:SetPos(w-45,5)

                mapitemprogressioncheck:SetSize(w-10,22)
                mapitemusefulcheck:SetSize(w-10,22)
                mapitemtrapcheck:SetSize(w-10,22)
                mapitemskipbalancecheck:SetSize(w-10,22)
                mapitemdepriocheck:SetSize(w-10,22)
            end

        function mapitemlist:OnRowSelected(index,pnl)
            local tbl = pnl.itemtbl
            mapitemeditpnl.itemtbl = tbl
            mapitemamtin:SetValue(tbl.amt)
            mapitemprogressioncheck:SetValue(band(tbl.fl,1) != 0)
            mapitemusefulcheck:SetValue(band(tbl.fl,2) != 0)
            mapitemtrapcheck:SetValue(band(tbl.fl,4) != 0)
            mapitemskipbalancecheck:SetValue(band(tbl.fl,8) != 0)
            mapitemdepriocheck:SetValue(band(tbl.fl,16) != 0)
            mapitemeditpnl:ShowContents(true)
        end

        function mapitemaddbtn:DoClick()
            local name = mapitemnamein:GetValue()
            if name == "" or mapitemtbl[name] != nil then return end
            mapitemtbl[name] = {amt = 1, fl = 0 }
            local ln = mapitemlist:AddLine(name)
            ln.itemtbl = mapitemtbl[name]
        end

        function mapitemcopybtn:DoClick()
            local _,srcpnl = mapitemlist:GetSelectedLine()
            local src = srcpnl.itemtbl
            local name = mapitemnamein:GetValue()
            if name == "" or mapitemtbl[name] != nil then return end
            mapitemtbl[name] = { amt = src.amt, fl = src.fl }
            local ln = mapitemlist:AddLine(name)
            ln.itemtbl = mapitemtbl[name]
        end

        function mapitemdelbtn:DoClick()
            mapitemeditpnl:ShowContents(false)
            local lines = mapitemlist:GetSelected()
            for k,v in ipairs(lines) do
                local name = v:GetValue(1)
                mapitemtbl[name] = nil
                mapitemlist:RemoveLine(v:GetID())
            end
        end

        function mapitempnl:PerformLayout(w,h)
            mapitemnamein:SetSize(w-70,22)
            mapitemaddbtn:SetPos(w-62,8)
            mapitemcopybtn:SetPos(w-42,8)
            mapitemdelbtn:SetPos(w-22,8)
            mapitemlist:SetSize(150,h-35)
            mapitemeditpnl:SetSize(w-165,h-35)
        end

    function window:UpdateInfo(cfg)
        editcfg = cfg
        grouptbl = cfg.GroupInfo

        for k,v in ipairs(groupupdate) do
            local name, p = v.n, v.p
            local ruleinfo = mapsettingslookup[name]
            local val = grouptbl[name] or istable(ruleinfo.default) and table.Copy(ruleinfo.default) or ruleinfo.default
            if isfunction(p) then p(val) else p:SetValue(val) end
        end

        infotbl = cfg.Info

        for k,v in ipairs(mapupdate) do
            local name, p = v.n, v.p
            local ruleinfo = mapsettingslookup[name]
            local val = infotbl[name] or !ruleinfo.noinherit and grouptbl[name] or istable(ruleinfo.default) and table.Copy(ruleinfo.default) or ruleinfo.default
            if isfunction(p) then p(val) else p:SetValue(val) end
        end

        reglist:LoadInfo(cfg.Regions)
        connlist:LoadInfo(cfg.Connections)
        mapitemlist:LoadMapItems(cfg.MapItems)
        reloadoption:SetEnabled(true)
        saveoption:SetEnabled(true)
    end

    local helpdrawer = UImake("DDrawer",window)
    helpdrawer:SetOpenSize(200)
    if drawerconv:GetBool() then
        helpdrawer:SetOpenTime(0)
        helpdrawer:Open()
    end
    helpdrawer:SetOpenTime(.3)

    local oldopen,oldclose = helpdrawer.Open,helpdrawer.Close
    function helpdrawer:Open()
        oldopen(self)
        drawerconv:SetBool(true)
    end
    function helpdrawer:Close()
        oldclose(self)
        drawerconv:SetBool(false)
    end

    function helpdrawer:TestHover(scrx,scry)
        local x, y = self:ScreenToLocal(scrx,scry)
        if y < 0 then return end
        local w, h = self:GetSize()
        return (w-x)+(h-y) > 30
    end

        local drawerpnl = UImake("DHTML",helpdrawer)
        drawerpnl:DockMargin(5,0,5,3)
        drawerpnl:Dock(FILL)
        drawerpnl:OpenURL("asset://garrysmod/data_static/apadventure/guide/base.txt")

        local function loadguide(guide)
            local txt
            if guide then
                txt = file.Read("data_static/apadventure/guide/"..language.GetPhrase("apadventure.guidefolder").."/"..guide..".txt","GAME") or
                    file.Read("data_static/apadventure/guide/en/"..guide..".txt","GAME")
                txt = txt and string.JavascriptSafe(txt)
            end
            drawerpnl:QueueJavascript("loadcontent(\""..(txt or "").."\")")
        end
        loadguide(tabs:GetActiveTab().guide)

    function tabs:OnActiveTabChanged(_,tab) loadguide(tab.guide) end

    window:SetSizable(true)
    local oldlayout = window.PerformLayout
    function window:PerformLayout(w,h)
        oldlayout(self,w,h)
        tabs:SetSize(w-10,h-55-helpdrawer:GetTall())
    end
end