local addonlist = engine.GetAddons()
local gamelist = engine.GetGames()
local locstr = language.GetPhrase
local substr = string.sub
local wsidtoaddon = {}
local taglist = {}
local UImake = vgui.Create

local function LoadTags()
    local files = file.Find("apadventure/require/*.lua","LUA")
    local tags = {}
    local addonproxies = {}
    for k,v in ipairs(files) do
        local tbl = include("apadventure/require/"..v)
        local name = substr(v,0,-5)
        tbl.Tag = name
        local proxies = tbl.AddonProxies
        if proxies then
            local function prproxy(id)
                if !isstring(id) then
                    ErrorNoHalt("Tag "..name.." had an addon proxy defined as a non-string type. WSIDs need to be passed as strings.")
                end
                addonproxies[id] = tbl
            end
            if istable(proxies) then
                for k,v in ipairs(proxies) do prproxy(v) end
            else
                prproxy(proxies)
            end
        end
        tags[name] = tbl
    end
    apAdventure.RequireTags = tags
    apAdventure.WSIDProxies = addonproxies
end

local function ErrorNotif(text,time)
    notification.AddLegacy("#apadventure.editor.error."..text,NOTIFY_ERROR,time or 3)
    surface.PlaySound("buttons/button10.wav")
end

concommand.Add("apadventure_editor_reload_requirement_tags", function() LoadTags() end)

if !apAdventure.RequireTags then
    LoadTags()
end

for k,v in pairs(apAdventure.RequireTags) do
    taglist[k] = {
        n = k,
        t = locstr("apadventure.requiretag."..k..".name")
    }
end

for k,v in ipairs(addonlist) do
    wsidtoaddon[v.wsid] = v
end

local gametagtitle = locstr("#apadventure.editor.require.gametagdesc")

for k,v in ipairs(gamelist) do
    local name = "game"..v.folder
    taglist[name] = {
        n = name,
        t = gametagtitle..v.title,
    }
end

return function(parent)
local basepnl = UImake("DCollapsibleCategory",parent)
basepnl:SetLabel("#apadventure.editor.require.title")
basepnl:SetExpanded(false)
local targettbl = {}
local tagtopos = {}
local itemcount = 0

local mode = false
local modeswitch = UImake("DImageButton",basepnl)
modeswitch:SetSize(16,16)
modeswitch:SetImage("icon16/pencil.png")
modeswitch:SetPos(5,28)

local tagselect = UImake("DComboBox",basepnl)
tagselect:SetPos(25,25)

local taginput = UImake("DTextEntry",basepnl)
taginput:SetPos(25,25)
taginput:SetVisible(false)

function modeswitch:DoClick()
    mode = !mode
    if mode then
        self:SetImage("icon16/text_list_bullets.png")
        tagselect:SetVisible(false)
        taginput:SetVisible(true)
        local _,tagd = tagselect:GetSelected()
        if tagd then taginput:SetText(tagd) end
    else
        self:SetImage("icon16/pencil.png")
        tagselect:SetVisible(true)
        taginput:SetVisible(false)
    end
end

local tagaddbtn = UImake("DImageButton",basepnl)
tagaddbtn:SetSize(16,16)
tagaddbtn:SetImage("icon16/add.png")

local tagdelbtn = UImake("DImageButton",basepnl)
tagdelbtn:SetSize(16,16)
tagdelbtn:SetImage("icon16/delete.png")

for k,v in pairs(taglist) do
    tagselect:AddChoice(v.t,v.n)
end

local wsaddbtn = UImake("DButton",basepnl)
wsaddbtn:SetText("#apadventure.editor.require.wsaddbtn")
wsaddbtn:SetSize(150,22)

local list = UImake("DListView",basepnl)
list:SetPos(5,50)
local tagcol = list:AddColumn("#apadventure.editor.require.listtag")
tagcol:SetMaxWidth(180)
list:AddColumn("#apadventure.editor.require.listdesc")

local function addwsoptn(menu,id)
    local wsinfo = wsidtoaddon[id]
    local wsname = wsinfo and wsinfo.title
    local optn = menu:AddOption(string.Interpolate(locstr("#apadventure.editor.require.gotoworkshopname"),{n=wsname or id}),function()
        steamworks.ViewFile(id)
    end)
    if !wsname then
        steamworks.FileInfo(id,function(data)
            if data then
                optn:SetText(string.Interpolate(locstr("#apadventure.editor.require.gotoworkshopname"),{n=data.title}))
            end
        end)
    end
end

function list:OnRowRightClick(ln,pnl)
    local tag = pnl:GetValue(1)
    local menu = UImake("DMenu")
    menu:AddOption("#apadventure.editor.require.copytag")
    local taginfo = apAdventure.RequireTags[tag]
    if taginfo then
        if taginfo.WSPages then
            local pages = taginfo.WSPages
            menu:AddSpacer()
            if isstring(pages) then
                addwsoptn(menu,pages)
            elseif istable(pages) then
                for k,v in ipairs(pages) do
                    addwsoptn(menu,v)
                end
            end
        end
    elseif substr(tag,0,4) == "wsid" then
        local wsid = substr(tag,5,-1)
        menu:AddSpacer()
        menu:AddOption("#apadventure.editor.require.gotoworkshop",function()
            steamworks.ViewFile(wsid)
        end)
        menu:AddOption("#apadventure.editor.require.copywsid",function()
            SetClipboardText(wsid)
        end)
    end
    menu:SetPos(input.GetCursorPos())
    menu:MakePopup()
end

local function addtag(tag,new)
    if tagtopos[tag] then return end

    local desc = "#apadventure.editor.require.unknowntagdesc"
    local tagstart = substr(tag,0,4)

    local starthandle = {
        wsid = function(tagend)
            local wsinfo = wsidtoaddon[tagend]
            desc = locstr("#apadventure.editor.require.wsidtagdesc")..( wsinfo and wsinfo.title or tagend )
        end,
        game = function(tagend)
            local gameinfo = taglist[tag]
            desc = gameinfo and gameinfo.t or gametagtitle..tagend
        end
    }

    local taginfo = apAdventure.RequireTags[tag]
    if taginfo then
        local loc = "apadventure.requiretag."..tag..".desc"
        local localized = locstr(loc)
        if loc != localized then desc = localized end
    elseif starthandle[tagstart] then
        starthandle[tagstart](substr(tag,5,-1))
    end

    list:AddLine(tag,desc)
    if new then
        targettbl[itemcount] = tag
        tagtopos[tag] = itemcount
    end
end

function basepnl:SetTargetTbl(tbl)
    targettbl = tbl
    for k,v in ipairs(list:GetLines()) do
        list:RemoveLine(v:GetID())
    end
    for k,v in ipairs(tbl) do
        addtag(v)
    end
end

function tagaddbtn:DoClick()
    local _, tagd
    if mode then
        tagd = taginput:GetText()
        if tagd == "" then ErrorNotif("reqnotxt") return end
        if tagd[1] == " " then ErrorNotif("reqleadspace") return end
        if tagd[#tagd] == " " then ErrorNotif("reqtrailspace") return end
    else
        _, tagd = tagselect:GetSelected()
    end
    if tagd then
        addtag(tagd,true)
    end
end

function tagdelbtn:DoClick()
    local delnames = {}
    for k,v in ipairs(list:GetSelected()) do
        delnames[v:GetValue(1)] = true
        list:RemoveLine(v:GetID())
    end
    local i = 0
    for k,v in ipairs(targettbl) do
        i = delnames[v] and 2 or 1 + i
        targettbl[k] = targettbl[i]
    end
end

function wsaddbtn:DoClick()
    local wsaddwindow = UImake("DFrame")
    wsaddwindow:SetTitle("#apadventure.editor.require.wsui.title")
    wsaddwindow:SetPos(100,100)
    wsaddwindow:SetSize(300,500)
    wsaddwindow:MakePopup()
    wsaddwindow:SetSizable(true)

    local wsaddlist = UImake("DListView",wsaddwindow)
    wsaddlist:SetPos(5,25)
    wsaddlist:AddColumn("#apadventure.editor.require.wsui.list.addon")
    local idcol = wsaddlist:AddColumn("#apadventure.editor.require.wsui.list.wsid")
    idcol:SetFixedWidth(90)

    local idproxies = apAdventure.WSIDProxies

    for k,v in ipairs(addonlist) do
        if v.mounted then
            local idnum = tonumber(v.wsid)
            local ln = wsaddlist:AddLine(v.title,v.wsid)
            if idnum then ln:SetSortValue(idnum) end
        end
    end

    local addbtn = UImake("DButton",wsaddwindow)
    addbtn:SetText("#apadventure.editor.require.wsui.addbtn")
    function addbtn:DoClick()
        for k,v in ipairs(wsaddlist:GetSelected()) do
            local id = v:GetValue(2)
            local proxy = idproxies[id]
            if proxy then
                addtag(proxy.Tag,true)
            else
                addtag("wsid"..id,true)
            end
        end
    end

    local oldlayout = wsaddwindow.PerformLayout
    function wsaddwindow:PerformLayout(w,h)
        oldlayout(self,w,h)

        wsaddlist:SetSize(w-10,h-60)
        addbtn:SetPos(15,h-30)
        addbtn:SetSize(w-30,25)
    end
end

local oldlayout = basepnl.PerformLayout
function basepnl:PerformLayout(w,h)
    oldlayout(self,w,h)

    wsaddbtn:SetPos(w-155,25)
    tagdelbtn:SetPos(w-176,28)
    tagaddbtn:SetPos(w-196,28)
    tagselect:SetSize(w-226,22)
    taginput:SetSize(w-226,22)

    list:SetSize(w-10,150)
end

return basepnl
end