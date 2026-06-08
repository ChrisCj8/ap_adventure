local UImake = vgui.Create

local greenbg = Color(200,255,200)
local redbg = Color(255,200,200)

return function(pnl,dat)
    local intro = UImake("DLabel",pnl)
    intro:SetWrap(true)
    intro:SetAutoStretchVertical(true)
    intro:SetText("#apadventure.requiretag.wiree2.desc")
    intro:SetDark(true)
    intro:SetPos(5,5)

    local lines, missing = {}
    for k,v in pairs(dat) do
        local ln = UImake("DPanel",pnl)
        local name, state = UImake("DLabel",ln), UImake("DLabel",ln)
        ln.name, ln.state = name, state
        lines[#lines+1] = ln
        name:SetDark(true); state:SetDark(true)
        name:SetPos(5,2)
        name:SetText(k)
        state:SetText(v and "#apadventure.requiretag.wiree2.exton" or "#apadventure.requiretag.wiree2.extoff")
        ln:SetBackgroundColor(v and greenbg or redbg)
    end

    local howto = UImake("DLabel",pnl)
    howto:SetWrap(true)
    howto:SetAutoStretchVertical(true)
    howto:SetText("#apadventure.requiretag.wiree2.howto")
    howto:SetDark(true)

    function pnl:PerformLayout(w,h)
        local iw, lnw, nmw, stx = w-10, w-100, w-90, w-80
        intro:SetWidth(iw)
        local curh = intro:GetTall()+10
        for k,v in ipairs(lines) do
            v:SetPos(5,curh)
            v:SetSize(iw,26)
            v.name:SetSize(nmw,22)
            v.state:SetPos(stx,2)
            curh = curh+31
        end
        howto:SetPos(5,curh)
        howto:SetWidth(iw)
        self:SetHeight(curh+10+howto:GetTall())
    end
end