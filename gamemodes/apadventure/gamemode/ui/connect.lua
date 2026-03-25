local UImake = vgui.Create 

local function Label(parent,text)
    local lbl = UImake("DLabel",parent)
    lbl:SetText(text)
    lbl:SetDark(true)
    return lbl
end

-- could be moved down to cl_init so this isn't done every time the window is opened,
-- but doing it here means only people who open this window will have the folder created
-- so players just joining in multiplayer wont have a useless folder created
if !file.IsDir("apadventure/connect/","DATA") then
    file.CreateDir("apadventure/connect/")
end

return function(window)
    window:SetSizable(true)
    
    local background = UImake("DPanel",window)
    background:Dock(FILL)

    local presetlbl = Label(background,"#apadventure.connect.presets")
    presetlbl:SetPos(5,5)
    local presetselect = UImake("DComboBox",background)
    presetselect:SetPos(90,5)
    local presetdel = UImake("DImageButton",background)
    presetdel:SetImage("icon16/bin.png")
    presetdel:SetSize(16,16)
    presetlbl.HoverHint,presetselect.HoverHint = "preset","preset"

    function presetselect:LoadPresets()
        self:Clear()
        local presetfiles = file.Find("apadventure/connect/*.json","DATA")
        for k,v in ipairs(presetfiles) do
            self:AddChoice(string.sub(v,0,-6))
        end
    end

    presetselect:LoadPresets()

    function presetdel:DoClick()
        local name = presetselect:GetSelected()
        if !name then return end
        local path = "apadventure/connect/"..name..".json"
        if file.Exists(path,"DATA") then
            file.Delete(path)
            presetselect:LoadPresets()
        end
    end

    local adrlbl = Label(background,"#apadventure.connect.address")
    adrlbl:SetPos(5,35)
    local adrin = UImake("DTextEntry",background)
    adrin:SetPos(90,35)
    adrin:SetPlaceholderText("ws://localhost:38281")
    adrlbl.HoverHint,adrin.HoverHint = "adress","address"

    local namelbl = Label(background,"#apadventure.connect.slotname")
    namelbl:SetPos(5,65)
    local namein = UImake("DTextEntry",background)
    namein:SetPos(90,65)
    namelbl.HoverHint,namein.HoverHint = "slotname","slotname"

    local pwlbl = Label(background,"#apadventure.connect.password")
    pwlbl:SetPos(5,95)
    local pwin = UImake("DTextEntry",background)
    pwin:SetPos(90,95)
    pwin:SetTextHidden(true)
    pwlbl.HoverHint,pwin.HoverHint = "password","password"

    local sendbtn = UImake("DButton",background)
    sendbtn:SetPos(5,125)
    sendbtn:SetText("#apadventure.connect.send")
    sendbtn.HoverHint = "send"
    function sendbtn:DoClick()
        net.Start("apAdvConnectionInfo")
            net.WriteString(adrin:GetValue())
            net.WriteString(namein:GetValue())
            net.WriteString(pwin:GetValue())
        net.SendToServer()
    end

    local connectbtn = UImake("DButton",background)
    connectbtn:SetPos(5,155)
    connectbtn:SetText("#apadventure.connect.connect")
    function connectbtn:DoClick()
        RunConsoleCommand("apadv_slot_connect")
    end

    local dcbtn = UImake("DButton",background)
    dcbtn:SetPos(50,155)
    dcbtn:SetText("#apadventure.connect.disconnect")
    function dcbtn:DoClick()
        RunConsoleCommand("apadv_slot_disconnect")
    end

    connectbtn.HoverHint,dcbtn.Hoverhint = "connect","connect"

    function presetselect:OnSelect(_,val)
        local data = util.JSONToTable(file.Read("apadventure/connect/"..val..".json","DATA"))
        adrin:SetText(data.a or "")
        namein:SetText(data.s or "")
        pwin:SetText(data.p or "")
    end

    local presetnamein = UImake("DTextEntry",background)
    presetnamein:SetPos(5,185)

    local presetsavebtn = UImake("DButton",background)
    presetsavebtn:SetText("#apadventure.connect.presetsave")
    presetsavebtn:SetPos(100,185)
    presetsavebtn:SetSize(90,22)

    presetnamein.HoverHint,presetsavebtn.HoverHint = "presetsave","presetsave"

    function presetsavebtn:DoClick()
        local name = presetnamein:GetText()
        if name == "" then
            notification.AddLegacy("#apadventure.connect.presetnoname",NOTIFY_ERROR,5)
            surface.PlaySound("buttons/button10.wav")
            return
        elseif !apAdventure.TestFileSystemSafe(name) then
            notification.AddLegacy("#apadventure.connect.presetnotfssafe",NOTIFY_ERROR,5)
            surface.PlaySound("buttons/button10.wav")
            return
        end

        local presdata = {
            a = adrin:GetValue(),
            s = namein:GetValue(),
            p = pwin:GetValue(),
        }

        if presdata.a == "" then presdata.a = nil end
        if presdata.p == "" then presdata.p = nil end

        file.Write("apadventure/connect/"..name..".json", util.TableToJSON(presdata))
        presetselect:LoadPresets()
    end

    local hintlbl = Label(background,"#apadventure.connect.hint.initial")
    hintlbl:SetPos(5,215)
    hintlbl:SetWrap(true)
    hintlbl:SetAutoStretchVertical(true)

    local function showhint(self)
        hintlbl:SetText("#apadventure.connect.hint."..self.HoverHint)
    end

    for k,v in ipairs(background:GetChildren()) do
        if v.HoverHint then
            v.OnCursorEntered = showhint
        end
    end

    function background:PerformLayout(w,h)
        presetselect:SetSize(w-95-20,22)
        presetdel:SetPos(w-5-18,7)
        adrin:SetSize(w-95,22)
        namein:SetSize(w-95,22)
        pwin:SetSize(w-95,22)
        sendbtn:SetSize(w-10,22)
        local hw = (w-15)/2
        connectbtn:SetSize(hw,22)
        dcbtn:SetSize(hw,22)
        dcbtn:SetPos(10+hw,155)

        presetnamein:SetSize(w-10-95,22)
        presetsavebtn:SetPos(w-95,185)

        hintlbl:SetWide(w-10)
    end
end