local NODE = {}

function NODE.InitNode()
    return {
        type = "surf"
    }
end

function NODE.Panel(parent)

    local skilllbl = vgui.Create("DLabel",parent)
    skilllbl:SetText("#apadventure.node.schmove.skill")
    skilllbl:SetDark(true)
    skilllbl:SetPos(5,5)

    local skillin = vgui.Create("DNumberWang",parent)
    skillin:SetMinMax(0,10)
    skillin:SetValue(parent.nodetbl.skill or 0)
    function skillin:OnValueChanged(val)
        parent.nodetbl.skill = val > 0 and val or nil
    end

    local help = vgui.Create("DForm",parent)
    help:SetLabel("#apadventure.node.shared.help")
    help:Help("#apadventure.node.surf.helpbase")
    help:Help("#apadventure.node.schmove.helpskill")
    help:Help("#apadventure.node.surf.helppreprocess")
    help:Help("#apadventure.node.surf.helptracker")
    help:Help("#apadventure.node.schmove.helpzero")
    help:SetPos(5,30)

    function parent:PerformLayout(w,h)
        local spc = w - 10
        local hidelbl = spc < 80
        skilllbl:SetSize(hidelbl and 0 or w-90,22)
        skillin:SetPos(w-85,5)
        skillin:SetSize(hidelbl and spc or 80,22)

        help:SetWidth(spc)
    end
end

return NODE