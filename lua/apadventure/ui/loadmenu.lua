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

    local reloadfiles

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

    local filew, filer, del, filef, mkdir = file.Write, file.Read, file.Delete, file.Find, file.CreateDir
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
                reloadfiles()
            end)
    end

    local copytgtin = vgui.Create("DTextEntry",window)

    local copybtn = vgui.Create("DButton",window)
    copybtn:SetText("#apadventure.loadmenu.copycfg")
    copybtn:SetEnabled(false)

    local movebtn = vgui.Create("DButton",window)
    movebtn:SetText("#apadventure.loadmenu.movecfg")
    movebtn:SetEnabled(false)

    local copygrcheck = vgui.Create("DCheckBoxLabel",window)
    copygrcheck:SetText("#apadventure.loadmenu.copydatacheck")
    copygrcheck:SetDark(true)

    local fromJSON, toJSON = util.JSONToTable, util.TableToJSON
    local cltologic, svtologic = apAdventure.ClCfgToLogic, apAdventure.SvCfgToLogic
    function copycfg(newgr,move)
        local errorsnd
        local _,ln = grouplist:GetSelectedLine()
        if !ln then return end
        local gr = ln:GetValue(1)
        local path, newpath = "apadventure/cfg/"..gr.."/", "apadventure/cfg/"..newgr.."/"
        local logicpath, newlogicpath = "apadventure/logic/cfg/"..gr.."/", "apadventure/logic/cfg/"..newgr.."/"
        if file.IsDir("data_static/"..newpath,"GAME") and !GetConVar("apadventure_editor_allow_static_overwrite"):GetBool() then
            notification.AddLegacy("#apadventure.loadmenu.error.movetostatic",NOTIFY_ERROR,3)
            surface.PlaySound("buttons/button10.wav")
            return
        end
        if !file.IsDir(newpath,"DATA") then mkdir(newpath) end
        if !file.IsDir(newlogicpath,"DATA") then mkdir(newlogicpath) end
        for k,v in ipairs(maplist:GetSelected()) do
            local map = v:GetValue(1)
            local mappath, maplogicpath = path..map, logicpath..map
            local newmappath, newmaplogicpath = newpath..map, newlogicpath..map
            local clpath,svpath = mappath.."/cl.json", mappath.."/sv.json"
            local clfile = filer(clpath,"DATA")
            if !clfile then
                if move then
                    notification.AddLegacy("#apadventure.loadmenu.error.movestatic",NOTIFY_ERROR,3)
                    surface.PlaySound("buttons/button10.wav")
                    del(newpath) -- file.Delete can only remove empty directories so this should be safe
                    del(newlogicpath)
                    return
                end
                clfile = filer("data_static/"..clpath,"GAME")
            end
            local svfile = filer(svpath,"DATA")
            if !svfile then
                if move then
                    notification.AddLegacy("#apadventure.loadmenu.error.movestatic",NOTIFY_ERROR,3)
                    surface.PlaySound("buttons/button10.wav")
                    del(newpath) -- file.Delete can only remove empty directories so this should be safe
                    del(newlogicpath)
                    return
                end
                svfile = filer("data_static/"..svpath,"GAME")
            end

            local copied
            if clfile and svfile then
                cltbl, svtbl = fromJSON(clfile), fromJSON(svfile)
                if cltbl and svtbl then
                    cllogic, svlogic = cltologic(cltbl), svtologic(svtbl)
                    if cllogic and svlogic then
                        mkdir(newmappath)
                        mkdir(newmaplogicpath)
                        copied = filew(newmappath.."/cl.json",clfile) and
                            filew(newmappath.."/sv.json",svfile) and
                            filew(newmaplogicpath.."/cl.json",toJSON(cllogic)) and
                            filew(newmaplogicpath.."/sv.json",toJSON(svlogic))
                    elseif !cllogic then
                        notification.AddLegacy(string.Interpolate(language.GetPhrase("#apadventure.loadmenu.error.cantmakecllogic"),{m=map}),NOTIFY_ERROR,3)
                        errorsnd = true
                    elseif !svlogic then
                        notification.AddLegacy(string.Interpolate(language.GetPhrase("#apadventure.loadmenu.error.cantmakesvlogic"),{m=map}),NOTIFY_ERROR,3)
                        errorsnd = true
                    end
                elseif !cltbl then
                    notification.AddLegacy(string.Interpolate(language.GetPhrase("#apadventure.loadmenu.error.cantmakecllogic"),{m=map}),NOTIFY_ERROR,3)
                    errorsnd = true
                elseif !svtbl then
                    notification.AddLegacy(string.Interpolate(language.GetPhrase("#apadventure.loadmenu.error.cantmakesvlogic"),{m=map}),NOTIFY_ERROR,3)
                    errorsnd = true
                end
                
            end

            if move and copied then
                del(clpath); del(svpath); del(mappath);
                del(maplogicpath.."/cl.json")
                del(maplogicpath.."/sv.json")
                del(maplogicpath)
            elseif !copied then
                del(newmappath)
                del(newmaplogicpath)
            end
        end

        if copygrcheck:GetChecked() then
            local grpath = path.."group.json"
            local grfile = filer(grpath,"DATA")
            if !grfile then
                if move then
                    notification.AddLegacy("#apadventure.loadmenu.error.movestatic",NOTIFY_ERROR,3)
                    surface.PlaySound("buttons/button10.wav")
                    del(newpath) -- file.Delete can only remove empty directories so this should be safe
                    del(newlogicpath)
                    return
                end
                grfile = filer("data_static/"..grpath,"GAME")
            end
            if grfile then 
                filew(newgr,grfile)
            end
        end

        local function cleanupempty(path)
            local files, dirs = filef(path.."*","DATA")
            if dirs then
                if !dirs[1] then
                    for k,v in ipairs(files) do del(path..v) end
                    del(path)
                end
            end
        end

        cleanupempty(newpath)
        cleanupempty(newlogicpath)
        if move then
            cleanupempty(path)
            cleanupempty(logicpath)
        end

        if errorsound then surface.PlaySound("buttons/button10.wav") end
        reloadfiles()
    end

    function copybtn:DoClick()
        local newgr = copytgtin:GetText()
        if newgr == "" then return end
        if newgr[1] == " " then return end
        if newgr[#newgr] == " " then return end
        copycfg(newgr)
    end

    function movebtn:DoClick()
        local newgr = copytgtin:GetText()
        if newgr == "" then return end
        if newgr[1] == " " then return end
        if newgr[#newgr] == " " then return end
        copycfg(newgr,true)
    end

    local listtext = {
        [0] = "#apadventure.loadmenu.hasmap.onlylogic",
        [1] = "#apadventure.loadmenu.hasmap.static",
        [2] = "#apadventure.loadmenu.hasmap.data",
        [3] = "#apadventure.loadmenu.hasmap.both",
    }

    local map = game.GetMap()

    function grouplist:OnRowSelected(_,pnl)
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
        copybtn:SetEnabled(hasmap)
        movebtn:SetEnabled(hasmap)
    end

    function grouplist:OnRowRightClick(_,ln)
        local menu = DermaMenu()
        menu:AddOption("#apadventure.loadmenu.copygrnametocopyname", function()
            copytgtin:SetText(ln:GetValue(1))
        end)
        menu:AddOption("#apadventure.loadmenu.copygrname", function()
            SetClipboardText(ln:GetValue(1))
        end)
        menu:Open()
    end

    function maplist:OnRowSelected(_,pnl)
        loadbtn:SetEnabled(pnl:GetValue(1) == map)
        delbtn:SetEnabled(true)
        copybtn:SetEnabled(true)
        movebtn:SetEnabled(true)
    end

    function maplist:OnRowRightClick(_,ln)
        local menu = DermaMenu()
        menu:AddOption("#apadventure.loadmenu.copymapname", function()
            SetClipboardText(ln:GetValue(1))
        end)
        menu:Open()
    end

    reloadfiles = function()
        grouplist:FindFiles()
        loadbtn:SetEnabled(false)
        delbtn:SetEnabled(false)
        loadgrbtn:SetEnabled(false)
        copybtn:SetEnabled(false)
        movebtn:SetEnabled(false)
        for k,v in ipairs(maplist:GetLines()) do maplist:RemoveLine(v:GetID()) end
    end

    local oldlayout = window.PerformLayout
    function window:PerformLayout(w,h)
        oldlayout(self,w,h)

        local iw = w-40
        local iw2 = w-45

        div:SetSize(w-10,h-100)

        loadbtn:SetPos(15,h-60)
        loadbtn:SetSize(iw*.5,25)

        loadgrbtn:SetPos(20+iw*.5,h-60)
        loadgrbtn:SetSize(iw*.25,25)

        delbtn:SetPos(25+iw*.75,h-60)
        delbtn:SetSize(iw*.25,25)

        copytgtin:SetPos(15,h-30)
        copytgtin:SetSize(iw2*.4,25)

        copybtn:SetPos(20+iw*.4,h-30)
        copybtn:SetSize(iw2*.2,25)

        movebtn:SetPos(25+iw*.6,h-30)
        movebtn:SetSize(iw2*.2,25)

        copygrcheck:SetPos(30+iw*.8,h-30)
        copygrcheck:SetSize(iw2*.2,25)
    end
    return window
end