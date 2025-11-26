local editcfg = apAdventure.EditCfg

local bool2yn = {
    [true] = "yes",
    [false] = "no"
}

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

return function(window)
    local tabs = vgui.Create("DPropertySheet",window)
    tabs:SetPos(5,25)

    local mapcfgpnl = vgui.Create("DPanel")
    tabs:AddSheet("Map Settings",mapcfgpnl)

        local infotbl = editcfg.Info

        local maprulesplacegroups = {}
        local mapruleselements = 0

        local function InfoCheck(parent,valname)
            local check = vgui.Create("DCheckBoxLabel",parent)
            check:SetText("#apadventure.editor."..valname..".label")
            check:SetDark(true)
            function check:OnChange(val)
                if val then
                    infotbl[valname] = true
                else
                    infotbl[valname] = nil
                end
            end
            mapruleselements = mapruleselements + 1
            maprulesplacegroups[mapruleselements] = {
                pnls = {
                    {pnl=check}
                },
                h = 22
            }
            return check
        end

        local function InfoNumwPreset(valname,presettbl,default,min,max)
            local lbl, numw, pres = LabelNumWangWithPreset(mapcfgpnl,valname,presettbl)
            numw:SetMinMax(min,max)
            numw:SetValue(infotbl[valname] or default)
            function numw:OnValueChanged(val) 
                if val == default then
                    infotbl[valname] = nil
                else    
                    infotbl[valname] = val 
                end
            end
            mapruleselements = mapruleselements + 1
            maprulesplacegroups[mapruleselements] = {
                pnls = {
                    { pnl = lbl, w = 100 },
                    { pnl = numw, w = 50 },
                    { pnl = pres }
                },
                h = 22
            }
            return lbl, numw, pres
        end

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

        local speedpresets = {
            {val=44,name="TF2 Heavy (Spun Up with Brass Beast)"},
            {val=80,name="TF2 scoped Sniper, Soldier charging Mangler"},
            {val=100,name="gMod Sandbox Default Walk Speed"},
            {val=110,name="TF2 Heavy (Spun Up)"},
            {val=150,name="HL2 Walk Speed"},
            {val=160,name="TF2 Sniper with drawn Huntsman"},
            {val=190,name="HL2 Run Speed"},
            {val=200,name="gMod Sandbox Default Run Speed"},
            {val=230,name="TF2 Heavy"},
            {val=240,name="TF2 Soldier"},
            {val=270,name="TF2 Engineer hauling a building"},
            {val=280,name="TF2 Demoman"},
            {val=300,name="TF2 Pyro, Engineer, Sniper"},
            {val=308,name="TF2 Demoman with boots and shield"},
            {val=320,name="HL2 Sprint Speed, TF2 Medic and Spy"},
            {val=345,name="TF2 Pyro with Powerjack"},
            {val=360,name="TF2 Scout with Baby Face's Blaster at 0% boost"},
            {val=400,name="gMod Sandbox Default Sprint Speed, TF2 Scout "},
            {val=520,name="TF2 Scout with Baby Face's Blaster at max boost"},
        }

        
        local mapwalkspdlbl, mapwalkspdin, mapwalkspdpres = InfoNumwPreset("walkspd",speedpresets,100,10,nil)
        local maprunspdlbl, maprunspdin, maprunspdpres = InfoNumwPreset("runspd",speedpresets,200,10,nil)
        local mapsprintspdlbl, mapsprintspdin, mapsprintspdpres = InfoNumwPreset("sprintspd",speedpresets,400,10,nil)

        local jumppresets = {
            {val=200,name="gMod Default"},
            {val=math.sqrt(2*800*57),name="CS:S"}
        }

        local mapjumplbl, mapjumpin, mapjumppres = InfoNumwPreset("jump",jumppresets,200,10,nil)


        local gravpresets = {
            {val=600,name="gMod, HL2 Default"},
            {val=800,name="TF2, gMod, cs:go, CS:S Default"},
        }

        local mapgravlbl, mapgravin, mapgravpres = InfoNumwPreset("grav",gravpresets,600,10,nil)

        local frctnpresets = {
            {val=4,name="CS:S, HL2 Default"},
            {val=8,name="gMod Default"},
        }

        local mapfrctnlbl, mapfrctnin, mapfrctnpres = InfoNumwPreset("frctn",frctnpresets,8,1,nil)

        local accelpresets = {
            {val=5,name="Momentum Mod"},
            {val=10,name="gMod, CS:S, HL2DM Default"},
        }

        local mapaccellbl, mapaccelin, mapaccelpres = InfoNumwPreset("accel",accelpresets,10,1,nil)

        local airaccelpresets = {
            {val=10,name="gMod, CS:S, HL2DM Default"},
            {val=150,name="Commonly used for Surf maps"},
            {val=1000,name="Commonly used for BHop maps"},
        }

        local mapairaccellbl, mapairaccelin, mapairaccelpres = InfoNumwPreset("airaccel",airaccelpresets,10,10,nil)

        local stopspdpresets = {
            {val=10,name="gMod Default"},
            {val=100,name="CS:S, HL2DM Default"},
        }

        local mapstopspdlbl, mapstopspdin, mapstopspdpres = InfoNumwPreset("stopspd",stopspdpresets,10,10,nil)
        
        --[[ local mapstartcandidatecheck = InfoCheck(mapcfgpnl,"startcandidate")
        mapstartcandidatecheck:SetPos(15,30) ]]    

        local maphevtoggle = InfoCheck(mapcfgpnl,"hev")

        function mapcfgpnl:PerformLayout(w,h)
            
            local curh = 5
            --mapstartcandidatecheck:SetSize(w-10,22)
            for k,v in ipairs(maprulesplacegroups) do
                local curw = 5
                for ik,iv in ipairs(v.pnls) do
                    local iw = iv.w or (w - 10 - curw) 
                    iv.pnl:SetPos(curw,curh)
                    iv.pnl:SetSize(iw,v.h)
                    curw = curw + iw + 5
                end
                curh = curh + (v.h or 22) + 5
            end
            
        end

    local regpnl = vgui.Create("DPanel")
    tabs:AddSheet("Regions",regpnl)

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

            local regprioentrcheck = vgui.Create("DCheckBoxLabel",regeditpnl)
            regprioentrcheck:SetText("#apadventure.editor.prioentr.label")
            regprioentrcheck:SetDark(true)
            regprioentrcheck:SetPos(5,5)
            function regprioentrcheck:OnChange(val)
                if !regeditpnl.curreg then return end 
                if val then
                    regeditpnl.curreg.prioentr = true
                else
                    regeditpnl.curreg.prioentr = nil
                end
            end

            local regammopnl = vgui.Create("DCollapsibleCategory",regeditpnl) 
            regammopnl:SetPos(5,30)
            regammopnl:SetLabel("#apadventure.editor.regammo.label")

            local ammotypes = game.GetAmmoTypes()
            ammotypes[0] = "Props"            

            local curpos = 25

            local ammochecks = {}
            local i = 1

            for k,v in pairs(ammotypes) do
                local check = vgui.Create("DCheckBoxLabel",regammopnl)
                check.AmmoType = v

                check:SetPos(5,curpos)
                check:SetText(v)
                check:SetDark(true)
                
                --check:SetValue(regtbl.ammo[v])

                function check:OnChange(val)
                    if !regeditpnl.curreg then return end 
                    regeditpnl.curreg.ammo = regeditpnl.curreg.ammo or {}
                    if val then
                        regeditpnl.curreg.ammo[v] = true
                    else
                        regeditpnl.curreg.ammo[v] = nil
                    end
                end

                curpos = curpos + 25
                ammochecks[i] = check
                i = i + 1
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
            regprioentrcheck:SetChecked(newtbl.prioentr)
            for k,v in ipairs(ammochecks) do
                v:SetValue(newtbl.ammo[v.AmmoType])
            end
        end



        function regpnl:PerformLayout(w,h)
            regnamein:SetSize(w-50,22)
            regaddbtn:SetPos(w-42,8)
            regdelbtn:SetPos(w-22,8)
            reglist:SetSize(150,h-35)
            regeditpnl:SetSize(w-165,h-35)
        end

    local connpnl = vgui.Create("DPanel")
    tabs:AddSheet("Connections",connpnl)
    
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

            PrintTable(nodetypes)

            local conaccesstree = vgui.Create("DTree",coneditpnl)
            conaccesstree:SetPos(5,60)

            local conaccessnodeselect = vgui.Create("DComboBox",coneditpnl)
            conaccessnodeselect:SetPos(5,30)

            for k,v in pairs(nodetypes) do
                print("adding node type "..k)
                conaccessnodeselect:AddChoice(k,k)
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
                    if !rootnode then return else
                        local node = conaccesstree:AddNode(nodename,nodetypes[nodename].Icon or "icon16/bullet_black.png")
                        local tbl = nodetype.InitNode()
                        node.tbl = tbl
                        curcon.access = tbl
                    end
                elseif nodetypes[curnode.tbl.type].SubNodes then
                    local node = curnode:AddNode(nodename,nodetypes[nodename].Icon or "icon16/bullet_black.png")
                    local tbl = nodetype.InitNode()
                    curnode.tbl.nodes[#curnode.tbl.nodes+1] = tbl
                    node.tbl = tbl
                end
            end

            local conaccessdelbtn = ImageButton(coneditpnl,"icon16/delete.png")

            local addnodes

            function addnodes(base,tbl)
                print("adding nodes")
                PrintTable(tbl)
                for k,v in ipairs(tbl) do
                    local node = base:AddNode(v.type,nodetypes[v.type].Icon or "icon16/bullet_black.png")
                    node.tbl = v
                    if v.nodes then
                        addnodes(node,v.nodes)
                    end
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
    tabs:AddSheet("Map Items",mapitempnl)

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

    local eventpnl = vgui.Create("DPanel")
    tabs:AddSheet("Events",eventpnl)

        local eventtbl = editcfg.Events

        local eventselect = vgui.Create("DComboBox",eventpnl)
        eventselect:SetPos(5,5)

        local eventparamin = vgui.Create("DTextEntry",eventpnl)

        local eventaddbtn = ImageButton(eventpnl,"icon16/add.png")
        local eventdelbtn = ImageButton(eventpnl,"icon16/delete.png")

        function eventpnl:PerformLayout(w,h)

            local selwidth = (w-10)/2
            eventselect:SetSize(selwidth,22)

            eventparamin:SetPos(selwidth+10, 5)
            eventparamin:SetSize(w-selwidth-56,22)

            eventaddbtn:SetPos(w-41,7)
            eventdelbtn:SetPos(w-21,7)
        end

    window:SetSizable(true)
    local oldlayout = window.PerformLayout
    function window:PerformLayout(width,height)
        oldlayout(self,width,height)
        tabs:SetSize(width-10,height-30)
    end
end