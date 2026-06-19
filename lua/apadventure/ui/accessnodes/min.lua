local NODE = {}

NODE.SubNodes = true

function NODE:InitNode()
    return {
        type = "min",
        nodes = {},
        amt = 2
    }
end

function NODE.Panel(parent)

    local minlbl = vgui.Create("DLabel",parent)
    minlbl:SetPos(5,5)
    minlbl:SetDark(true)
    minlbl:SetText("#apadventure.node.min.amtlbl")

    local minin = vgui.Create("DNumberWang",parent)
    minin:SetDecimals(0)
    minin:SetMin(2)
    minin:SetSize(70,22)

    local helppnl = vgui.Create("DForm",parent)
    helppnl:SetLabel("#apadventure.node.shared.help")
    helppnl:Help("#apadventure.node.min.helpbase")
    helppnl:SetPos(5,30)

    function minin:OnValueChanged(val)
        val = val < 2 and 2 or math.floor(val)
        parent.nodetbl.amt = val
    end

    function parent:PerformLayout(w,h)
        minlbl:SetSize(w-85,22)
        minin:SetPos(w-75,5)

        helppnl:SetWidth(w-10)
    end
end

return NODE