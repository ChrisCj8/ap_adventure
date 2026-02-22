local editcfg = apAdventure.EditCfg

local bool2yn = {
    [true] = "yes",
    [false] = "no"
}

local function LocStrExists(str)
    return language.GetPhrase(str) != str
end

local function BitFlipper(inval,flip,onoff)
    local biton = bit.band(inval,flip) != 0
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
    local btn = vgui.Create("DImageButton",parent)
    btn:SetImage(image)
    btn:SetSize(16,16)
    return btn
end

local function Label(parent,locstr)
    local lbl = vgui.Create("DLabel",parent)
    lbl:SetDark(true)
    lbl:SetText("#apadventure.editor."..locstr..".label")
    return lbl
end

local function LabelTextInput(parent,locstr)
    return Label(parent,locstr), vgui.Create("DTextEntry",parent)
end

local function LabelNumWang(parent,locstr)
    return Label(parent,locstr), vgui.Create("DNumberWang",parent)
end

local function LabelNumWangWithPreset(parent,locstr,presettbl)
    local label, numw = LabelNumWang(parent,locstr)
    local presetsel = vgui.Create("DComboBox",parent)
    for k,v in ipairs(presettbl) do
        presetsel:AddChoice(v.val.." - "..v.name,v.val,v.default,v.icon)
    end
    function presetsel:OnSelect(ind,val,data)
        numw:SetValue(data)
    end
    return label, numw, presetsel
end

local helpbubble

local helppnlclr = Color(255,255,205)

local function HelpPopup(helptext,w,creator)

    if !creator then return end

    local h = 10

    local pnl = vgui.Create("DPanel")
    pnl:SetBackgroundColor(helppnlclr)
    pnl.creator = creator
    function pnl:Think()
        local creator = self.creator
        if !IsValid(creator) or vgui.GetHoveredPanel() != creator then
            self:Remove()
        end
    end
    
    local text = vgui.Create("DLabel",pnl)
    text:SetPos(5,5)
    text:SetSize(w-10,10)
    text:SetWrap(true)
    text:SetAutoStretchVertical(true)
    text:SetTextColor(color_black) -- set the color to black here rather than using set dark in case derma skins set it to something weird
    text:SetText(helptext)
    
    local cursorx , cursory = gui.MousePos() 

    timer.Simple(0,function() 
        local _,texth = text:GetSize()
        pnl:SetSize(w,texth+10)
        pnl:SetPos(cursorx-w-30,cursory-(texth/2)-5)
    end)

    pnl:MakePopup()

    return pnl
end

local drawerconv = CreateClientConVar("apadventure_editor_help_drawer_state",1,true,false,"Used to save the state of the help drawer in the Editor UI.",0,1)

local mapsettings = apAdventure.CfgSettings

local mapsettingslookup = {}

for k,v in ipairs(mapsettings) do
    mapsettingslookup[v.name] = v
end

local numwdefaultcolor 
local checkboxdefaultcolor = color_black
local lightblue = Color(100,167,255)

return function(window)
    local mbar = vgui.Create("DMenuBar",window)
    mbar:DockMargin(-2,-5,-2,0)

    local configloaded = editcfg.Group != ""
    local filemenu = mbar:AddMenu("#apadventure.editor.menu.file")
    filemenu:AddOption("#apadventure.editor.menu.file.load",function() include("apadventure/ui/loadmenu.lua")() end)
    local reloadoption = filemenu:AddOption("#apadventure.editor.menu.file.reload",function() 
        RunConsoleCommand("apadventure_editor_loadcfg")
    end)
    --reloadoption:SetIcon("icon16/arrow_refresh.png")
    reloadoption:SetEnabled(configloaded)
    local saveoption = filemenu:AddOption("#apadventure.editor.menu.file.save",function() RunConsoleCommand("apadventure_editor_savecfg") end)
    saveoption:SetEnabled(configloaded)
    filemenu:AddOption("#apadventure.editor.menu.file.saveto",function() include("apadventure/ui/savemenu.lua")() end)

    local logicmenu = mbar:AddMenu("#apadventure.editor.menu.logic")
    logicmenu:AddOption("#apadventure.editor.menu.logic.updateallcfgs",function() RunConsoleCommand("apadventure_update_all_cfgs") end)
    logicmenu:AddOption("#apadventure.editor.menu.logic.processallitemdefs",function() RunConsoleCommand("apadventure_editor_processitemdefs") end)

    local miscmenu = mbar:AddMenu("#apadventure.editor.menu.misc")
    miscmenu:AddOption("#apadventure.editor.menu.misc.savemanage",function() RunConsoleCommand("apadventure_save_manager") end)

    local tabs = vgui.Create("DPropertySheet",window)
    tabs:SetPos(5,50)

    local grouptbl = editcfg.GroupInfo
    local infotbl = editcfg.Info

    local groupupdate = {}
    local groupupdatecount = 0
    local mapupdate = {}
    local mapupdatecount = 0

    local infoinputs = {}

    local groupcfgpnl = vgui.Create("DScrollPanel")
    groupcfgpnl:SetPaintBackground(true)
    local newtab = tabs:AddSheet("Group Settings",groupcfgpnl)
    newtab.Tab.guide = "grouptab"

        local grouprulesplacegroups = {}
        local groupruleselements = 0
        
        local grouppanelbuilders = {
            numwpreset = function(tbl)
                local valname = tbl.name
                local default = tbl.default
                local lbl, numw, pres = LabelNumWangWithPreset(groupcfgpnl,valname,tbl.presets)
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
                groupupdate[groupupdatecount] = {
                    p = numw,
                    n = valname
                }
                groupruleselements = groupruleselements + 1
                grouprulesplacegroups[groupruleselements] = {
                    pnls = {
                        { pnl = lbl, w = 100 },
                        { pnl = numw, w = 50 },
                        { pnl = pres }
                    },
                    h = 22
                }
            end,
            check = function(tbl)
                local valname = tbl.name
                local check = vgui.Create("DCheckBoxLabel",groupcfgpnl)
                check:SetText("#apadventure.editor."..valname..".label")
                check:SetDark(true)
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
                groupupdate[groupupdatecount] = {
                    p = check,
                    n = valname
                }
                groupruleselements = groupruleselements + 1
                grouprulesplacegroups[groupruleselements] = {
                    pnls = {
                        {pnl=check}
                    },
                    h = 22
                }
            end
        }

        for k,v in ipairs(mapsettings) do
            grouppanelbuilders[v.type](v)
            local helpstr = "apadventure.editor."..v.name..".help"
            if LocStrExists(helpstr) then
                local help = ImageButton(groupcfgpnl,"icon16/help.png")
                function help:DoClick()
                    cfgw = groupcfgpnl:GetSize()
                    HelpPopup("#"..helpstr,cfgw-100,self)
                end
                grouprulesplacegroups[groupruleselements].help = help
            end
        end

        local oldlayout = groupcfgpnl.PerformLayout
        function groupcfgpnl:PerformLayout(w,h)
            
            oldlayout(self,w,h)
            w = self:InnerWidth()
            local curh = 5
            for k,v in ipairs(grouprulesplacegroups) do
                local curw = 5
                for ik,iv in ipairs(v.pnls) do
                    local iw = iv.w or (w - 26 - curw) 
                    iv.pnl:SetPos(curw,curh)
                    iv.pnl:SetSize(iw,v.h)
                    curw = curw + iw + 5
                end

                if v.help then
                    v.help:SetPos(w-20,curh+2)
                end

                curh = curh + (v.h or 22) + 5
            end

        end

    local mapcfgpnl = vgui.Create("DScrollPanel")
    mapcfgpnl:SetPaintBackground(true)
    newtab = tabs:AddSheet("Map Settings",mapcfgpnl)
    newtab.Tab.guide = "maptab"

        local maprulesplacegroups = {}
        local mapruleselements = 0

        local mapnicenamelbl, mapnicenamein = LabelTextInput(mapcfgpnl,"nicename")
        mapnicenamein:SetValue(infotbl.nicename or "") 
        function mapnicenamein:OnChange()
            local val = self:GetValue()
            if val == "" then
                infotbl.nicename = nil
            else
                infotbl.nicename = val
            end
        end
        mapruleselements = mapruleselements + 1
        maprulesplacegroups[mapruleselements] = {
            pnls = {
                {pnl=mapnicenamelbl,w=100},
                {pnl=mapnicenamein}
            },
            h = 22
        }

        local rulespanelbuilders = {
            numwpreset = function(tbl)
                --InfoNumwPreset(tbl.name,tbl.presets,tbl.default,tbl.min,tbl.max)
                local valname = tbl.name
                local default = tbl.default
                local lbl, numw, pres = LabelNumWangWithPreset(mapcfgpnl,valname,tbl.presets)
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
                mapupdate[mapupdatecount] = {
                    p = numw,
                    n = valname
                }
                mapruleselements = mapruleselements + 1
                maprulesplacegroups[mapruleselements] = {
                    pnls = {
                        { pnl = lbl, w = 100 },
                        { pnl = numw, w = 50 },
                        { pnl = pres }
                    },
                    h = 22
                }
                infoinputs[valname] = numw
            end,
            check = function(tbl)
                local valname = tbl.name
                local check = vgui.Create("DCheckBoxLabel",mapcfgpnl)
                check:SetText("#apadventure.editor."..valname..".label")
                check:SetDark(true)
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
                mapupdate[mapupdatecount] = {
                    p = check,
                    n = valname
                }
                mapruleselements = mapruleselements + 1
                maprulesplacegroups[mapruleselements] = {
                    pnls = {
                        {pnl=check}
                    },
                    h = 22
                }
                infoinputs[valname] = check
            end
        }

        for k,v in ipairs(mapsettings) do
            rulespanelbuilders[v.type](v)
            local helpstr = "apadventure.editor."..v.name..".help"
            if LocStrExists(helpstr) then
                local help = ImageButton(mapcfgpnl,"icon16/help.png")
                function help:DoClick()
                    cfgw = mapcfgpnl:GetSize()
                    HelpPopup("#"..helpstr,cfgw-100,self)
                end
                maprulesplacegroups[mapruleselements].help = help
            end
        end

        local oldlayout = mapcfgpnl.PerformLayout
        function mapcfgpnl:PerformLayout(w,h)
            
            oldlayout(self,w,h)
            w = self:InnerWidth()
            local curh = 5
            --mapstartcandidatecheck:SetSize(w-10,22)
            for k,v in ipairs(maprulesplacegroups) do
                local curw = 5
                for ik,iv in ipairs(v.pnls) do
                    local iw = iv.w or (w - 26 - curw) 
                    iv.pnl:SetPos(curw,curh)
                    iv.pnl:SetSize(iw,v.h)
                    curw = curw + iw + 5
                end

                if v.help then
                    v.help:SetPos(w-20,curh+2)
                end

                curh = curh + (v.h or 22) + 5
            end
            
        end

    local regpnl = vgui.Create("DPanel")
    newtab = tabs:AddSheet("Regions",regpnl)
    newtab.Tab.guide = "regiontab"

        local regtbl

        local regnamein = vgui.Create("DTextEntry",regpnl)
        regnamein:SetPos(5,5)
        
        local reglist = vgui.Create("DListView",regpnl)
        reglist:SetPos(5,30)
        reglist:AddColumn("Region")

        local regaddbtn = ImageButton(regpnl,"icon16/add.png")
        local regdelbtn = ImageButton(regpnl,"icon16/delete.png")

        local regeditpnl = vgui.Create("DScrollPanel",regpnl)
        regeditpnl:SetPos(160,30)
        regeditpnl.ContentsVisible = true
        regeditpnl.ShowContents = ShowContents

            local regammopnl = vgui.Create("DCollapsibleCategory",regeditpnl) 
            regammopnl:SetPos(5,5)
            regammopnl:SetLabel("#apadventure.editor.regammo.label")

                local ammotypes = game.GetAmmoTypes()

                local curammolist = {}

                local ammochecks = {}
                local i = 1
                
                local ammoselect = vgui.Create("DComboBox",regammopnl)
                ammoselect:SetPos(5,25)

                for k,v in ipairs(ammotypes) do
                    ammoselect:AddChoice("Ammo_"..v)
                end

                local otherconds = {
                    "Props",
                    "Props_Sharp",
                    "Props_Explosive",
                    "Antlions_Controllable"
                }

                for k,v in ipairs(otherconds) do
                    ammoselect:AddChoice(v)
                end

                local ammoaddbtn = ImageButton(regammopnl,"icon16/add.png")
                local ammodelbtn = ImageButton(regammopnl,"icon16/delete.png")

                local ammolist = vgui.Create("DListView",regammopnl)
                ammolist:SetPos(5,52)
                ammolist:AddColumn("Type")

                function ammoaddbtn:DoClick()
                    local newcondtext, newconddata = ammoselect:GetSelected()
                    local newcond = newcondtext or newconddata
                    if newcond and !regeditpnl.curreg.ammo[newcond] then
                        ammolist:AddLine(newcond)
                        regeditpnl.curreg.ammo[newcond] = true
                    end
                end

                function ammodelbtn:DoClick()
                    for k,v in ipairs(ammolist:GetSelected()) do
                        local cond = v:GetValue(1)
                        ammolist:RemoveLine(v:GetID())
                        regeditpnl.curreg.ammo[cond] = nil
                    end
                end

                function ammolist:UpdateAmmo()
                    for k,v in pairs(self:GetLines()) do
                        self:RemoveLine(v:GetID())
                    end
                    local ammotbl = regeditpnl.curreg.ammo
                    for k,v in pairs(ammotbl) do
                        self:AddLine(k)
                    end
                end

                local oldlayout = regammopnl.PerformLayout
                function regammopnl:PerformLayout(w,h)
                    oldlayout(self,w,h)

                    ammoaddbtn:SetPos(w-26-18,28)
                    ammodelbtn:SetPos(w-26,28)
                    ammoselect:SetSize(w-52,22)
                    ammolist:SetSize(w-10,250)
                end

            regeditpnl:ShowContents(false)

            local oldlayout = regeditpnl.PerformLayout
            function regeditpnl:PerformLayout(w,h)
                oldlayout(self,w,h)
                regammopnl:SetWidth(w-30)
            end
        
        function regaddbtn:DoClick()
            local name = regnamein:GetValue()
            if name == "" then ErrorNotif("noregname") return end
            if name[1] == " " then ErrorNotif("regleadspace") return end
            if name[#name] == " " then ErrorNotif("regtrailspace") return end
            if !regtbl[name] then
                regtbl[name] = {
                    ammo = {},
                }
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
            ammolist:UpdateAmmo()
            regeditpnl:ShowContents(true)
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

    local connpnl = vgui.Create("DPanel")
    newtab = tabs:AddSheet("Connections",connpnl)
    newtab.Tab.guide = "connecttab"
    
        local conntbl

        local curcon = false
        local curconline = false

        local connlist = vgui.Create("DListView",connpnl)
        connlist:SetPos(5,30)
        connlist:AddColumn("From")
        connlist:AddColumn("To")
        connlist:AddColumn("Two-Way")

        local connfromin = vgui.Create("DTextEntry",connpnl)
        connfromin:SetPos(5,5)

        local conntoin = vgui.Create("DTextEntry",connpnl)
        conntoin:SetPos(5,5)

        local connaddbtn = ImageButton(connpnl,"icon16/add.png")
        local conndelbtn = ImageButton(connpnl,"icon16/delete.png")

        local coneditpnl = vgui.Create("DPanel",connpnl)
        coneditpnl.ContentsVisible = true
        coneditpnl.ShowContents = ShowContents
        
            local contwowaycheck = vgui.Create("DCheckBoxLabel",coneditpnl)
            contwowaycheck:SetText("Two-Way Connection")
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
            if from[#from] == " " then ErrorNotif("srctrailspace") return end
            if to == "" then ErrorNotif("notgtname") return end
            if to[1] == " " then ErrorNotif("tgtleadspace") return end
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
            local menu = vgui.Create("DMenu")
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
                    tbl.twoway = false
                    src.twoway = false
                    pnl:SetValue(3,"no")
                end
            end)
            menu:SetPos(input.GetCursorPos())
            menu:MakePopup()
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
            connfromin:SetSize((w-55)/2,22)

            conntoin:SetSize((w-55)/2,22)
            conntoin:SetPos((w-55)/2+10,5)

            connaddbtn:SetPos(w-42,8)

            conndelbtn:SetPos(w-22,8)

            connlist:SetSize(300,h-35)

            coneditpnl:SetPos(310,30)
            coneditpnl:SetSize(w-315,h-35)
        end
    
    local mapitempnl = vgui.Create("DPanel")
    newtab = tabs:AddSheet("Map Items",mapitempnl)
    newtab.Tab.guide = "mapitemtab"

        local mapitemtbl

        local mapitemnamein = vgui.Create("DTextEntry",mapitempnl)
        mapitemnamein:SetPos(5,5)

        local mapitemaddbtn = ImageButton(mapitempnl,"icon16/add.png")
        local mapitemcopybtn = ImageButton(mapitempnl,"icon16/page_copy.png")
        local mapitemdelbtn = ImageButton(mapitempnl,"icon16/delete.png")

        local mapitemlist = vgui.Create("DListView",mapitempnl)
        mapitemlist:SetPos(5,30)
        mapitemlist:AddColumn("Items")

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

        local mapitemeditpnl = vgui.Create("DPanel",mapitempnl)
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
                local check = vgui.Create("DCheckBoxLabel",mapitemeditpnl)
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
            mapitemprogressioncheck:SetValue(bit.band(tbl.fl,1) != 0)
            mapitemusefulcheck:SetValue(bit.band(tbl.fl,2) != 0)
            mapitemtrapcheck:SetValue(bit.band(tbl.fl,4) != 0)
            mapitemskipbalancecheck:SetValue(bit.band(tbl.fl,8) != 0)
            mapitemdepriocheck:SetValue(bit.band(tbl.fl,16) != 0)
            mapitemeditpnl:ShowContents(true)
        end

        function mapitemaddbtn:DoClick()
            local name = mapitemnamein:GetValue()
            if name == "" or mapitemtbl[name] != nil then return end
            mapitemtbl[name] = {
                amt = 1,
                fl = 0
            }
            local ln = mapitemlist:AddLine(name)
            ln.itemtbl = mapitemtbl[name]
        end

        function mapitemcopybtn:DoClick()
            local _,srcpnl = mapitemlist:GetSelectedLine()
            local src = srcpnl.itemtbl
            local name = mapitemnamein:GetValue()
            if name == "" or mapitemtbl[name] != nil then return end
            mapitemtbl[name] = {
                amt = src.amt,
                fl = src.fl
            }
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
            local name = v.n
            local ruleinfo = mapsettingslookup[name]
            v.p:SetValue(grouptbl[name] or ruleinfo.default)
        end

        infotbl = cfg.Info

        for k,v in ipairs(mapupdate) do
            local name = v.n
            local ruleinfo = mapsettingslookup[name]
            v.p:SetValue(infotbl[name] or grouptbl[name] or ruleinfo.default)
        end

        reglist:LoadInfo(cfg.Regions)
        connlist:LoadInfo(cfg.Connections)
        mapitemlist:LoadMapItems(cfg.MapItems)

        reloadoption:SetEnabled(true)
        saveoption:SetEnabled(true)

    end

    local helpdrawer = vgui.Create("DDrawer",window)
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
        local w,h = self:GetSize()
        return (w-x)+(h-y) > 30
    end
        
        local drawerpnl = vgui.Create("DHTML",helpdrawer)
        drawerpnl:DockMargin(5,0,5,3)
        drawerpnl:Dock(FILL)
        drawerpnl:OpenURL("asset://garrysmod/apadv_guide/base.html")

        local function loadguide(guide)
            local text = ""
            if guide then
                local path = "apadv_guide/"..language.GetPhrase("apadventure.guidefolder").."/"..guide..".html"
                local found
                if file.Exists(path,"GAME") then
                    found = true
                else
                    path = "apadv_guide/en/"..guide..".html"
                    if file.Exists(path,"GAME") then
                        found = true
                    end
                end

                if found then
                    text = string.JavascriptSafe(file.Read(path,"GAME"))
                end
            end
            drawerpnl:QueueJavascript("loadcontent(\""..text.."\")")
        end

        loadguide(tabs:GetActiveTab().guide)

    function tabs:OnActiveTabChanged(_,tab)
        local guide = tab.guide
        loadguide(guide)
    end

    window:SetSizable(true)
    local oldlayout = window.PerformLayout
    function window:PerformLayout(width,height)
        oldlayout(self,width,height)
        local _,drawerh = helpdrawer:GetSize()
        tabs:SetSize(width-10,height-55-drawerh)
    end
end