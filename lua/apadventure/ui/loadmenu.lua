return function() 
    local window = vgui.Create("DFrame")
    window:SetSize(300,450)
    window:Center()
    window:MakePopup()
    window:SetSizable(true)
    window:SetTitle("#apadventure.loadmenu.title")

    local grouplist = include("apadventure/ui/grouplist.lua")(window)
    grouplist:SetPos(5,30)

    function grouplist:DoDoubleClick(id,pnl)
        RunConsoleCommand("apadventure_editor_loadcfg",pnl:GetValue(1))
        window:Remove()
    end

    local oldlayout = window.PerformLayout
    function window:PerformLayout(w,h)
        oldlayout(self,w,h)

        grouplist:SetSize(w-10,h-35)
    end
    return window
end