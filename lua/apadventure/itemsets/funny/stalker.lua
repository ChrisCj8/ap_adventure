local ITEM = {}

ITEM.Name = "Stalker Scream"
ITEM.Type = "OneUse"

ITEM.FillWeight = 2
ITEM.MinAmt = 0
ITEM.Trap = true
ITEM.RedeemCheck = true

local lastredeem = 0
function ITEM.Redeem()
	local sinceredeem = CurTime() - lastredeem
	if sinceredeem < 5 then return 5.5 - sinceredeem end
	lastredeem = CurTime()
	EmitSound("npc/stalker/go_alert2a.wav",vector_origin,0,CHAN_STATIC,1,0)
	return true
end

return ITEM