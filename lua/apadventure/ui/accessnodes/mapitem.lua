local NODE = {}

function NODE.Panel(parent)

    local itemnamein = vgui.Create("DTextEntry",parent)
    itemnamein:SetValue(parent.nodetbl.item)
    itemnamein:SetPos(5,5)
    function itemnamein:OnValueChange(val)
        parent.nodetbl.item = val
    end

    local countin = vgui.Create("DNumberWang",parent)
    countin:SetMin(1)
    countin:SetValue(parent.nodetbl.count or 1)
    countin:SetPos(5,30)
    function countin:OnValueChanged(val)
        parent.nodetbl.count = val
    end

    function parent:PerformLayout(w,h)
        itemnamein:SetSize(w-10,22)


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