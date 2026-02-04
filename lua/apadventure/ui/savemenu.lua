return function() 
    local window = vgui.Create("DFrame")
    window:SetSize(300,450)
    window:Center()
    window:MakePopup()
    window:SetSizable(true)
    window:SetTitle("#apadventure.savemenu.title")

    local grouplist = include("apadventure/ui/grouplist.lua")(window)
    grouplist:SetPos(5,30)

    local namein = vgui.Create("DTextEntry",window)
    namein:SetSize(100,22)

    function grouplist:OnRowSelected(_,pnl)
        namein:SetValue(pnl:GetValue(1))
    end

    local savebtn = vgui.Create("DButton",window)
    savebtn:SetText("#apadventure.savemenu.savebtn")
    savebtn:SetSize(100,22)

    function savebtn:DoClick()
        local name = namein:GetValue()
        if apAdventure.TestFileSystemSafe(name) then
            RunConsoleCommand("apadventure_editor_savecfg",name)
        else
            notification.AddLegacy("#apadventure.savemenu.nofssafe",NOTIFY_ERROR,3)
            surface.PlaySound("buttons/button10.wav")
        end
    end

    local oldlayout = window.PerformLayout
    function window:PerformLayout(w,h)
        oldlayout(self,w,h)

        grouplist:SetSize(w-10,h-60)
        namein:SetPos(5,h-27)
        namein:SetWide(w-115)
        savebtn:SetPos(w-105,h-27)
    end
    return window
end