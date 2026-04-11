local NODE = {}

function NODE.Panel(parent)

    local itemlbl = vgui.Create("DLabel",parent)
    itemlbl:SetText("#apadventure.node.mapitem.name")
    itemlbl:SetPos(5,5)
    itemlbl:SetDark(true)
    local itemnamein = vgui.Create("DTextEntry",parent)
    itemnamein:SetValue(parent.nodetbl.item)
    itemnamein:SetPos(5,5)
    itemnamein:SetUpdateOnType(true)
    function itemnamein:OnValueChange(val)
        parent.nodetbl.item = val
    end

    local countlbl = vgui.Create("DLabel",parent)
    countlbl:SetText("#apadventure.node.mapitem.count")
    countlbl:SetPos(5,30)
    countlbl:SetDark(true)

    local countin = vgui.Create("DNumberWang",parent)
    countin:SetMin(1)
    countin:SetValue(parent.nodetbl.count or 1)
    countin:SetPos(5,30)
    countin:SetSize(50,22)
    function countin:OnValueChanged(val)
        parent.nodetbl.count = val
    end

    local helppnl = vgui.Create("DForm",parent)
    helppnl:SetLabel("#apadventure.node.mapitem.help")
    helppnl:Help("#apadventure.node.mapitem.helpbase")

    local floor = math.floor

    function parent:PerformLayout(w,h)
        local nw = floor((w-15)*.6)
        itemlbl:SetSize(w-nw-10,22)
        itemnamein:SetPos(w-nw-5,5)
        itemnamein:SetSize(nw,22)
        countlbl:SetSize(w-60,22)
        countin:SetPos(w-55,30)
        helppnl:SetPos(5,55)
        helppnl:SetWidth(w-10)
    end
end

function NODE.InitNode()
    return {
        item = "",
        count = 1,
        type = "mapitem"
    }
end

return NODE