local editcfg = apAdventure.EditCfg

local bool2yn = {
    [true] = "yes",
    [false] = "no"
}

local function LocStrExists(str)
    return language.GetPhrase(str) != str
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

local numwdefaultcolor 
local checkboxdefaultcolor = color_black
local lightblue = Color(100,167,255)

return function(window)
    local tabs = vgui.Create("DPropertySheet",window)
    tabs:SetPos(5,25)

    local grouptbl = editcfg.GroupInfo
    local infotbl = editcfg.Info

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

        local regtbl = editcfg.Regions

        local regnamein = vgui.Create("DTextEntry",regpnl)
        regnamein:SetPos(5,5)
        
        local reglist = vgui.Create("DListView",regpnl)
        reglist:SetPos(5,30)
        reglist:AddColumn("Region")

        local regaddbtn = ImageButton(regpnl,"icon16/add.png")
        function regaddbtn:DoClick()
            local name = regnamein:GetValue()

            if name == "" then return end

            if !regtbl[name] then
                regtbl[name] = {
                    ammo = {},
                }
                local ln = reglist:AddLine(name)
            end
        end

        local regdelbtn = ImageButton(regpnl,"icon16/delete.png")
        function regdelbtn:DoClick()
            for k,v in ipairs(reglist:GetSelected()) do
                local name = v:GetValue(1)
                regtbl[name] = nil 
                reglist:RemoveLine(v:GetID())
            end
        end

        for k,v in pairs(regtbl) do
            local ln = reglist:AddLine(k)
        end

        local regeditpnl = vgui.Create("DScrollPanel",regpnl)
        regeditpnl:SetPos(160,30)

            local regammopnl = vgui.Create("DCollapsibleCategory",regeditpnl) 
            regammopnl:SetPos(5,30)
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
                    "Props"
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
                    for k,v in ipairs(self:GetLines()) do
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
                    ammolist:SetSize(w-10,400)
                end

            local oldlayout = regeditpnl.PerformLayout
            function regeditpnl:PerformLayout(w,h)
                oldlayout(self,w,h)
                regammopnl:SetWidth(w-30)
            end


        function reglist:OnRowSelected(index,pnl)
            local newtbl = regtbl[pnl:GetValue(1)]
            newtbl.ammo = newtbl.ammo or {}
            regeditpnl.curreg = newtbl
            ammolist:UpdateAmmo()
        end



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
    
        local conntbl = editcfg.Connections

        local curcon = false
        local curconline = false

        local connlist = vgui.Create("DListView",connpnl)
        connlist:SetPos(5,30)
        connlist:AddColumn("From")
        connlist:AddColumn("To")
        connlist:AddColumn("Two-Way")

        for k,v in pairs(conntbl) do
            for ik, iv in pairs(v) do
                connlist:AddLine(k,ik,bool2yn[iv.twoway])
            end
        end

        local connfromin = vgui.Create("DTextEntry",connpnl)
        connfromin:SetPos(5,5)

        local conntoin = vgui.Create("DTextEntry",connpnl)
        conntoin:SetPos(5,5)

        local connaddbtn = ImageButton(connpnl,"icon16/add.png")
        function connaddbtn:DoClick()
            local from = connfromin:GetValue()
            local to = conntoin:GetValue()

            conntbl[from] = conntbl[from] or {}

            conntbl[from][to] = {
                twoway = false,
            }

            connlist:AddLine(from,to,bool2yn[false])
        end

        local conndelbtn = ImageButton(connpnl,"icon16/delete.png")
        function conndelbtn:DoClick()
            for k,v in ipairs(connlist:GetSelected()) do
                local from = v:GetValue(1)
                local to = v:GetValue(2)
                conntbl[from][to] = nil 

                if !next(conntbl[from]) then
                    conntbl[from] = nil
                end
                connlist:RemoveLine(v:GetID())
            end
        end

        local coneditpnl = vgui.Create("DPanel",connpnl)
        
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

            local nodetypes = {}

            for k,v in ipairs(file.Find("apadventure/ui/accessnodes/*.lua","lcl")) do
                local name = string.sub(v,0,-5)
                nodetypes[name] = include("apadventure/ui/accessnodes/"..v)
            end

            local conaccesstree = vgui.Create("DTree",coneditpnl)
            conaccesstree:SetPos(5,60)

            local conaccessnodeselect = vgui.Create("DComboBox",coneditpnl)
            conaccessnodeselect:SetPos(5,30)

            for k,v in pairs(nodetypes) do
                conaccessnodeselect:AddChoice(k,k)
            end

            local addnodes

            function addnodes(base,tbl)
                for k,v in ipairs(tbl) do
                    local node = base:AddNode(v.type,nodetypes[v.type].Icon or "icon16/bullet_black.png")
                    node.tbl = v
                    node.tblkey = k
                    if v.nodes then
                        addnodes(node,v.nodes)
                    end
                end
            end

            local conaccessaddbtn = ImageButton(coneditpnl,"icon16/add.png")
            function conaccessaddbtn:DoClick()
                local curnode = conaccesstree:GetSelectedItem()
                local nodename, nodedata = conaccessnodeselect:GetSelected()
                if !nodedata then return end
                local nodetype = nodetypes[nodedata]
                print(curnode,nodename,nodedata,nodetype)
                if !IsValid(curnode) then
                    local rootnode = conaccesstree:Root()
                    if !rootnode or rootnode:GetChildNodeCount() > 0 then return else
                        local node = conaccesstree:AddNode(nodename,nodetypes[nodename].Icon or "icon16/bullet_black.png")
                        local tbl = nodetype.InitNode()
                        node.tbl = tbl
                        curcon.access = tbl
                    end
                elseif nodetypes[curnode.tbl.type].SubNodes then
                    local node = curnode:AddNode(nodename,nodetypes[nodename].Icon or "icon16/bullet_black.png")
                    local tbl = nodetype.InitNode()
                    local newkey =  #curnode.tbl.nodes+1
                    curnode.tbl.nodes[newkey] = tbl
                    node.tbl = tbl
                    node.tblkey = newkey
                    curnode:ExpandRecurse(true)
                end
            end

            local conaccessdelbtn = ImageButton(coneditpnl,"icon16/delete.png")
            function conaccessdelbtn:DoClick()
                local curnode = conaccesstree:GetSelectedItem()
                if !IsValid(curnode) then return end
                local parentnode = curnode:GetParentNode()
                --print("trying to delete node"..tostring(curnode),parentnode:IsRootNode())
                --PrintTable(curnode.tbl)
                if parentnode:IsRootNode() then
                    curnode:Remove()
                    curcon.access = nil
                else
                    --PrintTable(parentnode:GetChildNodes())
                    local parenttbl = parentnode.tbl
                    local newtbl = {}
                    local curnodekey = curnode.tblkey
                    i = 1
                    for k,v in ipairs(parenttbl.nodes) do
                        if k != curnodekey then
                            newtbl[i] = v 
                            i = i + 1
                        end
                    end
                    parentnode.tbl.nodes = newtbl
                    for k,v in ipairs(parentnode:GetChildNodes()) do
                        v:Remove()
                    end
                    addnodes(parentnode,newtbl)
                    parentnode:ExpandRecurse(true)
                end
            end

            local conaccessnodepnl = vgui.Create("DPanel",coneditpnl)
            conaccessnodepnl:SetPos(210,60)

            function conaccesstree:OnNodeSelected(node)
                conaccessnodepnl.PerformLayout = nil
                conaccessnodepnl:Clear()
                conaccessnodepnl.nodetbl = node.tbl
                PrintTable(node.tbl)
                local pnlfunc = nodetypes[node.tbl.type].Panel

                if isfunction(pnlfunc) then
                    pnlfunc(conaccessnodepnl)
                end
            end

            function coneditpnl:PerformLayout(w,h)
                conaccessnodeselect:SetSize(w-50,25)

                conaccessaddbtn:SetPos(w-42,33)

                conaccessdelbtn:SetPos(w-22,33)

                conaccesstree:SetSize(200,h-60)

                conaccessnodepnl:SetSize(w-210,h-60)
            end

        function connlist:OnRowSelected(index,pnl)
            local from = pnl:GetValue(1)
            local to = pnl:GetValue(2)

            curcon = conntbl[from][to]
            curconline = pnl

            contwowaycheck:SetChecked(curcon.twoway)

            conaccesstree:Clear()

            local access = curcon.access
            if access then
                local basenode = conaccesstree:AddNode(access.type,nodetypes[access.type].Icon or "icon16/bullet_black.png")
                basenode.tbl = access
                if access.nodes then
                    addnodes(basenode,access.nodes)
                    basenode:ExpandRecurse(true)
                end
            end
        end

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

        local mapitemtbl = editcfg.MapItems

        local mapitemnamein = vgui.Create("DTextEntry",mapitempnl)
        mapitemnamein:SetPos(5,5)

        local mapitemaddbtn = ImageButton(mapitempnl,"icon16/add.png")
        local mapitemdelbtn = ImageButton(mapitempnl,"icon16/delete.png")

        local mapitemlist = vgui.Create("DListView",mapitempnl)
        mapitemlist:SetPos(5,30)
        mapitemlist:AddColumn("Items")

        for k,v in pairs(mapitemtbl) do
            local ln = mapitemlist:AddLine(k)
            ln.itemtbl = v
        end

        function mapitemaddbtn:DoClick()
            local name = mapitemnamein:GetValue()
            if name == "" or mapitemtbl[name] != nil then return end
            mapitemtbl[name] = {
                amt = 1,
                fl = 0
            }
            local ln = mapitemlist:AddLine(name)
            ln.itembtl = mapitemtbl[name]
        end

        function mapitemdelbtn:DoClick()
            local lines = mapitemlist:GetSelected()
            for k,v in ipairs(lines) do
                local name = v:GetValue(1)
                mapitemtbl[name] = nil
                v:Remove()
            end
        end

        local mapitemeditpnl = vgui.Create("DPanel",mapitempnl)
        mapitemeditpnl:SetPos(110,30)

            local mapitemamtin = vgui.Create("DNumberWang",mapitemeditpnl)
            mapitemamtin:SetMin(1)
            mapitemamtin:SetPos(5,5)
            function mapitemamtin:OnValueChanged(val)
                mapitemeditpnl.itemtbl.amt = math.floor(val)
            end

            function mapitemeditpnl:PerformLayout(w,h)
                mapitemamtin:SetSize(40,22)
            end

        function mapitemlist:OnRowSelected(index,pnl)
            mapitemeditpnl.itemtbl = pnl.itemtbl
            mapitemamtin:SetValue(pnl.itemtbl.amt)
        end

        function mapitempnl:PerformLayout(w,h)
            mapitemnamein:SetSize(w-50,22)

            mapitemaddbtn:SetPos(w-42,8)
            mapitemdelbtn:SetPos(w-22,8)

            mapitemlist:SetSize(100,h-35)

            mapitemeditpnl:SetSize(w-115,h-35)
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
        tabs:SetSize(width-10,height-30-drawerh)
    end
end