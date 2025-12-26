DEFINE_BASECLASS("base_point")

function ENT:Initialize()

end

local inputs = {
        SendMapLocation = function(_,_,param)
            APADV.SendMapLocation(param)
        end,
        SendChat = function(_,_,param)
            APADV_SLOT:SendChatMessage(param)
        end
    }

function ENT:AcceptInput(inName,activator,caller,param)
    if !APADV_SLOT or !APADV_SLOT.Connected then return end
    local infunc = inputs[inName]
    if infunc then infunc(activator,caller,param) end
end