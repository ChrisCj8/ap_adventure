local NODE = {
    Icon = "icon16/gun.png"
}

local capabs = {
    "WimpyMelee",
    "WeakMelee",
    "DecentMelee",
    "StrongMelee",
    "WimpyShortRange",
    "WeakShortRange",
    "DecentShortRange",
    "StrongShortRange",
    "WimpyMidRange",
    "WeakMidRange",
    "DecentMidRange",
    "StrongMidRange",
    "WeakAOE",
    "MidAOE",
    "StrongAOE",
    "WeakSpam",
    "MidSpam",
    "StrongSpam",
    "HeliKiller",
    "Waterproof"
}

function NODE.Panel(parent)

    
    local capselect = vgui.Create("DComboBox",parent)
    capselect:SetPos(5,5)
    local first = true
    for k,v in ipairs(capabs) do
        capselect:AddChoice(v,v,first)
        first = false
    end

    local capaddbtn = vgui.Create("DImageButton",parent)
    capaddbtn:SetSize(16,16)
    capaddbtn:SetImage("icon16/add.png")

    local capdelbtn = vgui.Create("DImageButton",parent)
    capdelbtn:SetSize(16,16)
    capdelbtn:SetImage("icon16/delete.png")

    local caplist = vgui.Create("DListView",parent)
    caplist:SetPos(5,30)
    caplist:AddColumn("Capability")

    for k,v in pairs(parent.nodetbl.capab) do
        caplist:AddLine(k)
    end

    function capaddbtn:DoClick()
        local _, data = capselect:GetSelected()
        if !parent.nodetbl.capab[data] then
            parent.nodetbl.capab[data] = true
            caplist:AddLine(data)
        end
    end

    function capdelbtn:DoClick()
        for k,v in ipairs(caplist:GetSelected()) do
            parent.nodetbl.capab[v:GetValue(1)] = nil
            v:Remove()
        end
    end

    --[[ local itemnamein = vgui.Create("DTextEntry",parent)
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
    end ]]

    function parent:PerformLayout(w,h)
        --itemnamein:SetSize(w-10,22)
        capselect:SetSize(w-50,22)
        caplist:SetSize(w-10,h-35)
        capaddbtn:SetPos(w-5-16-20,7)
        capdelbtn:SetPos(w-5-16,7)
    end
end

function NODE.InitNode()
    return {
        capab = {},
        type = "weapon"
    }
end

return NODE