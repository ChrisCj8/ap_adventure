local function Label(parent,text)
    local lbl = vgui.Create("DLabel",parent)
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
    
    local background = vgui.Create("DPanel",window)
    background:Dock(FILL)

    local presetlbl = Label(background,"#apadventure.connect.presets")
    presetlbl:SetPos(5,5)
    local presetselect = vgui.Create("DComboBox",background)
    presetselect:SetPos(90,5)
    local presetdel = vgui.Create("DImageButton",background)
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
    local adrin = vgui.Create("DTextEntry",background)
    adrin:SetPos(90,35)
    adrin:SetPlaceholderText("ws://localhost:38281")
    adrlbl.HoverHint,adrin.HoverHint = "adress","address"

    local namelbl = Label(background,"#apadventure.connect.slotname")
    namelbl:SetPos(5,65)
    local namein = vgui.Create("DTextEntry",background)
    namein:SetPos(90,65)
    namelbl.HoverHint,namein.HoverHint = "slotname","slotname"

    local pwlbl = Label(background,"#apadventure.connect.password")
    pwlbl:SetPos(5,95)
    local pwin = vgui.Create("DTextEntry",background)
    pwin:SetPos(90,95)
    pwin:SetTextHidden(true)
    pwlbl.HoverHint,pwin.HoverHint = "password","password"

    local sendbtn = vgui.Create("DButton",background)
    sendbtn:SetPos(5,125)
    sendbtn:SetText("#apadventure.connect.connect")
    function sendbtn:DoClick()
        net.Start("apAdvConnectionInfo")
            net.WriteString(adrin:GetValue())
            net.WriteString(namein:GetValue())
            net.WriteString(pwin:GetValue())
        net.SendToServer()
    end

    function presetselect:OnSelect(_,val)
        local data = util.JSONToTable(file.Read("apadventure/connect/"..val..".json","DATA"))
        adrin:SetText(data.a or "")
        namein:SetText(data.s or "")
        pwin:SetText(data.p or "")
    end

    local presetnamein = vgui.Create("DTextEntry",background)
    presetnamein:SetPos(5,160)

    local presetsavebtn = vgui.Create("DButton",background)
    presetsavebtn:SetText("#apadventure.connect.presetsave")
    presetsavebtn:SetPos(100,160)
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
    hintlbl:SetPos(5,190)
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

        presetnamein:SetSize(w-10-95,22)
        presetsavebtn:SetPos(w-95,160)

        hintlbl:SetWide(w-10)
    end
end