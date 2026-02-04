return function(window)
    local pnl = vgui.Create("DListView",window)
    pnl:AddColumn("#apadventure.loadmenu.groupname")
    local hasmapcol = pnl:AddColumn("#apadventure.loadmenu.hasmap")
    hasmapcol:SetMaxWidth(100)

    local _, groups = file.Find("apadventure/cfg/*","DATA")

    local map = game.GetMap()
    local isdir = file.IsDir
    local hasstr = language.GetPhrase("apadventure.loadmenu.hasmap.yes")

    for k,v in ipairs(groups) do
        pnl:AddLine(v,isdir("apadventure/cfg/"..v.."/"..map,"DATA") and hasstr or "")
    end

    return pnl
end