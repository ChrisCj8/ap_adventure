local NODE = {}

function NODE.InitNode()
    return {
        type = "bhop"
    }
end

function NODE.Panel(parent)
    local help = vgui.Create("DForm",parent)
    help:SetLabel("#apadventure.node.bhop.help")
    help:Help("#apadventure.node.bhop.helpbase")
    help:Help("#apadventure.node.bhop.helppreprocess")
    help:SetPos(5,5)

    function parent:PerformLayout(w,h)
        help:SetWidth(w-10)
    end
end

return NODE