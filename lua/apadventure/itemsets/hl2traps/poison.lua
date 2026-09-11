local ITEM = {}

ITEM.Name = "Headcrab Poison"
ITEM.Type = "OneUse"

ITEM.FillWeight = 5
ITEM.MinAmt = 0
ITEM.Trap = true
ITEM.RedeemCheck = true

local lastredeem = 0
function ITEM.Redeem()
	local sinceredeem = CurTime() - lastredeem
	if sinceredeem < 5 then return 5.5 - sinceredeem end
	local applied
	local dmg = DamageInfo()
	dmg:SetDamageType(DMG_POISON)
	dmg:SetAttacker(Entity(0)) -- for some reason the damage won't regen if there's no attacker
	for k,v in player.Iterator() do
		if v:Alive() and v:GetObserverMode() == OBS_MODE_NONE then
			dmg:SetDamage(v:Health()-1)
			v:TakeDamageInfo(dmg)
			applied = true
		end
	end
	return applied
end

return ITEM