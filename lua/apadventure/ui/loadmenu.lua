return function() 
    local window = vgui.Create("DFrame")
    window:SetSize(650,600)
    window:Center()
    window:MakePopup()
    window:SetSizable(true)
    window:SetTitle("#apadventure.loadmenu.title")

    local grouplist = include("apadventure/ui/grouplist.lua")(window)
    grouplist:SetMultiSelect(false)

    local maplist = vgui.Create("DListView",window)
    maplist:AddColumn("#apadventure.loadmenu.mapname")
    maplist:AddColumn("#apadventure.loadmenu.location"):SetMaxWidth(100)

    local div = vgui.Create("DHorizontalDivider",window)
    div:SetPos(5,30)
    div:SetLeft(grouplist)
    div:SetRight(maplist)
    div:SetLeftWidth(250)

    local loadbtn = vgui.Create("DButton",window)
    loadbtn:SetText("#apadventure.loadmenu.loadcfg")
    loadbtn:SetEnabled(false)
    function loadbtn:DoClick()
        local _,ln = grouplist:GetSelectedLine()
        if !ln then return end
        RunConsoleCommand("apadventure_editor_loadcfg",ln:GetValue(1))
        window:Close()
    end

    local function confirmwindow(msg,func)
        local window = vgui.Create("DFrame")
        window:Center()
        window:MakePopup()
        window:SetSize(250,150)
        window:SetBackgroundBlur(true)
        window:SetTitle("#apadventure.loadmenu.confirm.title")

        local question = vgui.Create("DLabel",window)
        question:SetText(msg)
        question:SetPos(5,35)
        question:SetWrap(true)
        question:SetAutoStretchVertical(true)

        local yesbtn = vgui.Create("DButton",window)
        yesbtn:SetText("#apadventure.loadmenu.confirm.yes")
        function yesbtn:DoClick()
            window:Close()
            func()
        end

        local nobtn = vgui.Create("DButton",window)
        nobtn:SetText("#apadventure.loadmenu.confirm.no")
        function nobtn:DoClick() window:Close() end

        function window:OnFocusChanged(val)
            if !val then window:Close() end
        end

        local oldlayout = window.PerformLayout
        function window:PerformLayout(w,h)
            oldlayout(self,w,h)

            local w2 = (w-15)/2

            question:SetWidth(w-10)
            self:SetHeight(question:GetTall()+75)
            yesbtn:SetPos(5,h-30)
            yesbtn:SetSize(w2,22)
            nobtn:SetPos(10+w2,h-30)
            nobtn:SetSize(w2,22)
        end
    end

    local loadgrbtn = vgui.Create("DButton",window)
    loadgrbtn:SetText("#apadventure.loadmenu.loadgr")
    loadgrbtn:SetEnabled(false)
    function loadgrbtn:DoClick()
        local _,ln = grouplist:GetSelectedLine()
        if !ln then return end
        local gr = ln:GetValue(1)
        local path = "apadventure/cfg/"..gr.."/group.json"
        local grfile = file.Read(path,"DATA") or file.Read("data_static/"..path,"GAME")
        if !grfile then return end
        local tbl = util.JSONToTable(grfile)
        if !tbl then return end
        local editcfg = apAdventure.EditCfg
        editcfg.GroupInfo = tbl.rules
        if IsValid(apAdventure.EditWindow) then
            apAdventure.EditWindow:UpdateInfo(editcfg)
            window:Close()
        end
    end

    local del, filef = file.Delete, file.Find
    local delbtn = vgui.Create("DButton",window)
    delbtn:SetText("#apadventure.loadmenu.delcfg")
    delbtn:SetEnabled(false)
    function delbtn:DoClick()
        local _,ln = grouplist:GetSelectedLine()
        if !ln then return end
        local mapsel = maplist:GetSelected()
        if !next(mapsel) then return end
        local cfgstring = ""
        for k,v in ipairs(mapsel) do cfgstring = cfgstring.."\n\t"..v:GetValue(1) end
        confirmwindow(string.Interpolate(language.GetPhrase("apadventure.loadmenu.confirm.delcfg"),{g=ln:GetValue(1),m=cfgstring}),
            function()
                local gr = ln:GetValue(1)
                local cfgpath = "apadventure/cfg/"..gr.."/"
                local logicpath = "apadventure/logic/cfg/"..gr.."/"
                for k,v in ipairs(mapsel) do
                    local name = v:GetValue(1)
                    local cfg,logic = cfgpath..name.."/", logicpath..name.."/"
                    del(cfg.."cl.json")
                    del(cfg.."sv.json")
                    del(logic.."cl.json")
                    del(logic.."sv.json")
                    del(cfg)
                    del(logic)
                end
                local _,remaining = filef(cfgpath.."*","DATA")
                if !next(remaining) then
                    del(cfgpath.."group.json")
                    del(cfgpath)
                end
                local _,remaining = filef(logicpath.."*","DATA")
                if !next(remaining) then
                    del(logicpath.."group.json")
                    del(logicpath)
                end

                grouplist:FindFiles()
                loadbtn:SetEnabled(false)
                delbtn:SetEnabled(false)
                loadgrbtn:SetEnabled(false)
                for k,v in ipairs(maplist:GetLines()) do maplist:RemoveLine(v:GetID()) end
            end)
    end

    local listtext = {
        [0] = "#apadventure.loadmenu.hasmap.onlylogic",
        [1] = "#apadventure.loadmenu.hasmap.static",
        [2] = "#apadventure.loadmenu.hasmap.data",
        [3] = "#apadventure.loadmenu.hasmap.both",
    }

    local map = game.GetMap()

    function grouplist:OnRowSelected(id,pnl)
        for k,v in ipairs(maplist:GetLines()) do
            maplist:RemoveLine(v:GetID())
        end
        local gr = pnl:GetValue(1)
        local newentries = {}
        local _,cfgs = filef("data_static/apadventure/cfg/"..gr.."/*","GAME")
        for k,v in ipairs(cfgs) do
            newentries[v] = 1
        end
        _,cfgs = filef("apadventure/cfg/"..gr.."/*","DATA")
        for k,v in ipairs(cfgs) do
            newentries[v] = newentries[v] or 0 + 2
        end
        _,cfgs = filef("apadventure/logic/cfg/"..gr.."/*","DATA")
        for k,v in ipairs(cfgs) do
            if !newentries[v] then newentries[v] = 0 end
        end

        local hasmap
        for k,v in pairs(newentries) do
            local ln = maplist:AddLine(k,listtext[v] or "?")
            if k == map then
                maplist:SelectItem(ln)
                hasmap = true
            end
        end
        loadbtn:SetEnabled(hasmap)
        delbtn:SetEnabled(hasmap)
        loadgrbtn:SetEnabled(true)
    end

    function maplist:OnRowSelected(id,pnl)
        loadbtn:SetEnabled(pnl:GetValue(1) == map)
        delbtn:SetEnabled(true)
    end

    local oldlayout = window.PerformLayout
    function window:PerformLayout(w,h)
        oldlayout(self,w,h)

        local iw = w-40

        div:SetSize(w-10,h-70)

        loadbtn:SetPos(15,h-30)
        loadbtn:SetSize(iw*.5,25)

        loadgrbtn:SetPos(20+iw*.5,h-30)
        loadgrbtn:SetSize(iw*.25,25)

        delbtn:SetPos(25+iw*.75,h-30)
        delbtn:SetSize(iw*.25,25)
    end
    return window
end