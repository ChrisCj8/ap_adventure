local isdir, map, bor, langphrase = file.IsDir, game.GetMap(), bit.bor, language.GetPhrase

return function(window)
    local pnl = vgui.Create("DListView",window)
    pnl:AddColumn("#apadventure.loadmenu.groupname")
    local hasmapcol = pnl:AddColumn("#apadventure.loadmenu.hasmap")
    hasmapcol:SetMaxWidth(100)

    local hasstr = {
        [0] = "",
        [1] = "#apadventure.loadmenu.hasmap.static",
        [2] = "#apadventure.loadmenu.hasmap.data",
        [3] = "#apadventure.loadmenu.hasmap.both",
    }

    function pnl:FindFiles()
        for k,v in ipairs(self:GetLines()) do self:RemoveLine(v:GetID()) end
        local groups = {}
        local _, dir = file.Find("data_static/apadventure/cfg/*","GAME")
        for k,v in ipairs(dir) do
            groups[v] = isdir("data_static/apadventure/cfg/"..v.."/"..map,"GAME") and 1 or 0
        end

        _, dir = file.Find("apadventure/cfg/*","DATA")
        for k,v in ipairs(dir) do
            groups[v] = bor((groups[v] or 0),isdir("apadventure/cfg/"..v.."/"..map,"DATA") and 2 or 0)
        end

        for k,v in pairs(groups) do pnl:AddLine(k,hasstr[v]):SetSortValue(2,v) end
    end
    pnl:FindFiles()

    return pnl
end