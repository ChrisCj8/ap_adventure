return function(window)
    window:SetSizable(true)

    local adrin = vgui.Create("DTextEntry",window)
    adrin:SetSize(300,22)

    local namein = vgui.Create("DTextEntry",window)
    namein:SetSize(300,22)

    local pwin = vgui.Create("DTextEntry",window)
    pwin:SetSize(300,22)

    local sendbtn = vgui.Create("DButton",window)
    sendbtn:SetSize(300,22)
    function sendbtn:DoClick()
        net.Start("apAdvConnectionInfo")
            net.WriteString(adrin:GetValue())
            net.WriteString(namein:GetValue())
            net.WriteString(pwin:GetValue())
        net.SendToServer()
    end


    local oldlayout = window.PerformLayout

    function window:PerformLayout(w,h)
        oldlayout(self,w,h)
        adrin:SetPos(w/2-150,30)
        namein:SetPos(w/2-150,60)
        pwin:SetPos(w/2-150,90)
        sendbtn:SetPos(w/2-150,120)
    end
end