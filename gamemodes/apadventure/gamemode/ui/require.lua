APADV_REQUIREMENTS = APADV_REQUIREMENTS or {}
local locstr = language.GetPhrase
local UImake = vgui.Create

return function()
local window = UImake("DFrame")
window:SetTitle("#apadventure.require.title")
window:SetPos(100,100)
window:SetSize(450,600)
window:MakePopup()
window:SetSizable(true)

local userblfile = file.Read("apadventure/presetaddonblacklist.json","DATA")
local userblacklist = userblfile and util.JSONToTable(userblfile,false,true) or {}

function window:OnRemove()
    file.Write("apadventure/presetaddonblacklist.json",util.TableToJSON(userblacklist))
end

local refreshbtn = UImake("DButton",window)
refreshbtn:SetText("#apadventure.require.refresh")
function refreshbtn:DoClick()
    net.Start("ApAdvRequirements")
        net.WriteString(APADV_REQUIREMENTS.lastcheck or "")
    net.SendToServer()
end

local min = math.min
local max = math.max

local catlist = UImake("DCategoryList",window)
catlist:SetPos(5,25)

local gamecat = catlist:Add("#apadventure.require.game")
local a,b,c,d = gamecat:GetDockPadding()
gamecat:DockPadding(a,b,c,d+5)

local function gamepnllayout(self,w,h)
    local pnlw = (w-40)/3
    self.nametxt:SetPos(25,0)
    self.nametxt:SetSize(pnlw,22)
    self.cltxt:SetPos(pnlw+30,0)
    self.cltxt:SetSize(pnlw,22)
    self.svtxt:SetPos(2*pnlw+35,0)
    self.svtxt:SetSize(pnlw,22)
end

local head = UImake("DPanel",gamecat)
gamecat.head = head
head:Dock(TOP)
head:DockMargin(5,5,5,5)
head.PerformLayout = gamepnllayout

local nametxt = UImake("DLabel",head)
local cltxt = UImake("DLabel",head)
local svtxt = UImake("DLabel",head)
head.nametxt = nametxt
head.cltxt = cltxt
head.svtxt = svtxt
nametxt:SetDark(true)
cltxt:SetDark(true)
svtxt:SetDark(true)
nametxt:SetText("#apadventure.require.game.name")
cltxt:SetText("#apadventure.require.game.cl")
svtxt:SetText("#apadventure.require.game.sv")

local addoncat = catlist:Add("#apadventure.require.addon")
addoncat:DockPadding(a,b,c,d+5)

local function addonpnllayout(self,w,h)
    local space = w-15
    local idspace = min((w-40)/2,90)
    self.nametxt:SetPos(5,0)
    self.nametxt:SetSize(space-idspace-40,22)
    self.idtxt:SetPos(w-idspace-25,0)
    self.idtxt:SetSize(idspace,22)
    if self.wsbtn then 
        self.wsbtn:SetPos(w-41,3)
        self.excludebtn:SetPos(w-21,3)
    end
end

local head = UImake("DPanel",addoncat)
addoncat.head = head
head:Dock(TOP)
head:DockMargin(5,5,5,5)
head.PerformLayout = addonpnllayout

local tail = UImake("DPanel",addoncat)
addoncat.tail = tail
tail:Dock(TOP)
tail:DockMargin(5,5,5,5)
tail:SetPaintBackground(false)

    local makepresetbtn = UImake("DButton",tail)
    makepresetbtn:SetText("#apadventure.require.makepreset")
    makepresetbtn:SetPos(5,0)
    makepresetbtn:SetEnabled(APADV_REQUIREMENTS.lastcheck != nil)
    function makepresetbtn:DoClick()
        if !APADV_REQUIREMENTS.addons then return end
        local enabled = {}
        local i = 1
        for k,v in pairs(APADV_REQUIREMENTS.addons) do
            if !userblacklist[k] then
                enabled[i] = k
                i = i + 1
            end
        end
        SetClipboardText(util.TableToJSON({
            enabled = enabled,
        }))
    end

    local function wsbtnfunc(self)
        steamworks.ViewFile(self:GetParent().idtxt:GetText())
    end

    local function excludebtnfunc(self)
        local id = self:GetParent().idtxt:GetText()
        local newstatus = !userblacklist[id] or nil
        userblacklist[id] = newstatus
        self:SetIcon(newstatus and "icon16/cross.png" or "icon16/tick.png")
    end

    function tail:PerformLayout(w,h)
        makepresetbtn:SetSize(w-10,h)
    end

local nametxt = UImake("DLabel",head)
local idtxt = UImake("DLabel",head)
head.nametxt = nametxt
head.idtxt = idtxt

nametxt:SetDark(true)
idtxt:SetDark(true)
nametxt:SetText("#apadventure.require.addon.name")
idtxt:SetText("#apadventure.require.addon.id")

local othercat = catlist:Add("#apadventure.require.other")
othercat:DockPadding(a,b,c,d+5)

local function otherpnllayout(self,w,h)
    local txt = self.txt
    txt:SetWidth(w-10)
    self:SetHeight(txt:GetTall()+10)
end

local helpcat = catlist:Add("#apadventure.require.help")

local a,b,c,d = helpcat:GetDockPadding()
helpcat:DockPadding(a,b,c,5)
for k,v in ipairs({"intro","games","addon","addon.select","addon.preset","addon.usepreset","addon.presetload","other"}) do
    local txt = UImake("DLabel",helpcat)
    txt:SetText("#apadventure.require.help."..v)
    txt:DockMargin(5,5,5,5)
    --first = 0
    txt:Dock(TOP)
    txt:SetWrap(true)
    txt:SetDark(true)
    txt:SetAutoStretchVertical(true)
end

APADV_REQUIREMENTS.ui = window

local green = Color(200,255,200)
local yellow = Color(255,255,200)
local red = Color(255,200,200)

local statustocolor = {green, yellow, red}

local function BuildLists()

    local addons = {}

    for k,v in ipairs(engine.GetAddons()) do
        addons[v.wsid] = v
    end

    local games = {}

    for k,v in ipairs(engine.GetGames()) do
        games[v.folder] = v
    end

    local head = addoncat.head
    local tail = addoncat.tail
    head:SetParent()
    tail:SetParent()
    addoncat:Clear()
    head:SetParent(addoncat)

    for k,v in pairs(APADV_REQUIREMENTS.addons) do
        local pnl = UImake("DPanel",addoncat)
        pnl:Dock(TOP)
        pnl:DockMargin(5,0,5,5)
        local nametxt = UImake("DLabel",pnl)
        local idtxt = UImake("DLabel",pnl)
        local wsbtn = UImake("DImageButton",pnl)
        local excludebtn = UImake("DImageButton",pnl)
        wsbtn:SetIcon("icon16/package_link.png")
        wsbtn:SetSize(16,16)
        excludebtn:SetIcon(userblacklist[k] and "icon16/cross.png" or "icon16/tick.png")
        excludebtn:SetSize(16,16)
        wsbtn.DoClick = wsbtnfunc
        excludebtn.DoClick = excludebtnfunc
        pnl.nametxt = nametxt
        pnl.idtxt = idtxt
        pnl.wsbtn = wsbtn
        pnl.excludebtn = excludebtn
        pnl.PerformLayout = addonpnllayout
        idtxt:SetText(k)
        idtxt:SetDark(true)
        nametxt:SetDark(true)
        local addoninfo = addons[k]
        if addoninfo then
            pnl:SetBackgroundColor(addoninfo.mounted and green or addoninfo.downloaded and yellow or red)
            nametxt:SetText(addoninfo.title)
        else
            pnl:SetBackgroundColor(red)
            nametxt:SetText("#apadventure.require.addon.unknown")
            steamworks.FileInfo(k,function(val) 
                if val then
                    nametxt:SetText(val.title)
                end
            end)
        end
    end

    tail:SetParent(addoncat)
    local head = gamecat.head

    head:SetParent()
    gamecat:Clear()
    head:SetParent(gamecat)
    local pnl
    for k,v in pairs(APADV_REQUIREMENTS.games) do
        pnl = UImake("DPanel",gamecat)
        pnl:Dock(TOP)
        pnl:DockMargin(5,0,5,5)
        local iconpath = "games/16/"..k..".png"
        if file.Exists("materials/"..iconpath,"GAME") then
            local icon = UImake("DImage",pnl)
            icon:SetSize(16,16)
            icon:SetPos(4,4)
            icon:SetImage(iconpath)
        end
        local nametxt = UImake("DLabel",pnl)
        local cltxt = UImake("DLabel",pnl)
        local svtxt = UImake("DLabel",pnl)
        pnl.nametxt = nametxt
        pnl.cltxt = cltxt
        pnl.svtxt = svtxt
        nametxt:SetDark(true)
        cltxt:SetDark(true)
        svtxt:SetDark(true)
        pnl.PerformLayout = gamepnllayout
        local gameinfo = games[k]
        if gameinfo then
            local mount = gameinfo.mounted
            pnl:SetBackgroundColor(v and mount and green or (mount or v) and yellow or red)
            nametxt:SetText(gameinfo.title)
            cltxt:SetText("#apadventure.require.game."..(mount and "mount" or gameinfo.installed and "installed" or gameinfo.owned and "owned" or "unowned"))
            svtxt:SetText("#apadventure.require.game."..(v and "mount" or "nomount"))
        else
            pnl:SetBackgroundColor(v and yellow or red)
            nametxt:SetText(k)
            cltxt:SetText("#apadventure.require.game.unknown")
            svtxt:SetText("#apadventure.require.game."..(v and "mount" or "nomount"))
        end
    end

    othercat:Clear()
    local first = 5
    for k,v in ipairs(APADV_REQUIREMENTS.misc) do
        local tag, msg = v.tag, v.msg
        if tag and msg and next(msg) then
            pnl = UImake("DPanel",othercat)
            pnl.PerformLayout = otherpnllayout
            pnl:Dock(TOP)
            pnl:DockMargin(5,first,5,5)
            first = 0
            local txt = UImake("DLabel",pnl)
            pnl.txt = txt
            txt:SetWrap(true)
            txt:SetAutoStretchVertical(true)
            txt:SetPos(5,5)
            txt:SetDark(true)
            local text
            for ik,iv in ipairs(v.msg) do
                local loc = locstr("apadventure.requiremsg."..v.tag.."."..iv)
                text = !text and loc or text.."\n"..loc
            end
            txt:SetText(text)
            if v.status then pnl:SetBackgroundColor(statustocolor[v.status] or yellow) end
        end
    end
end
if APADV_REQUIREMENTS.lastcheck then BuildLists() end

function window:OnRequirementsUpdate()
    makepresetbtn:SetEnabled(true)
    BuildLists()
end

local oldlayout = window.PerformLayout
function window:PerformLayout(w,h)
    oldlayout(self,w,h)
    catlist:SetSize(w-10,h-30)
    local btnspace = max((w-100)/2,min(w - 200,250))
    refreshbtn:SetPos(w-btnspace-100,3)
    refreshbtn:SetSize(btnspace,18)
end

return window
end