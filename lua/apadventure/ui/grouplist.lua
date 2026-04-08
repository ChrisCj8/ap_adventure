local isdir = file.IsDir
local langphrase = language.GetPhrase

return function(window)
    local pnl = vgui.Create("DListView",window)
    pnl:AddColumn("#apadventure.loadmenu.groupname")
    local hasmapcol = pnl:AddColumn("#apadventure.loadmenu.hasmap")
    hasmapcol:SetMaxWidth(100)

    local map = game.GetMap()

    local _, datadir = file.Find("apadventure/cfg/*","DATA")
    local _, staticdir = file.Find("data_static/apadventure/cfg/*","GAME")
    local groups = {}

    local bor = bit.bor

    for k,v in ipairs(staticdir) do
        groups[v] = isdir("data_static/apadventure/cfg/"..v.."/"..map,"GAME") and 1 or 0
    end

    for k,v in ipairs(datadir) do
        groups[v] = bor((groups[v] or 0),isdir("apadventure/cfg/"..v.."/"..map,"DATA") and 2 or 0)
    end

    local hasstr = {
        [0] = "",
        [1] = langphrase("apadventure.loadmenu.hasmap.static"),
        [2] = langphrase("apadventure.loadmenu.hasmap.data"),
        [3] = langphrase("apadventure.loadmenu.hasmap.both"),
    }

    for k,v in pairs(groups) do
        local line = pnl:AddLine(k,hasstr[v])
        line:SetSortValue(2,v)
    end

    return pnl
end