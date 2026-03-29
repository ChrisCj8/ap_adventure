local ITEM = {}

ITEM.Name = "Full Restore"
ITEM.Type = "OneUse"

ITEM.FillWeight = 10
ITEM.MinAmt = 0

function ITEM.Redeem()
    for k,v in player.Iterator() do
        v:SetHealth(v:GetMaxHealth())
        v:SetArmor(v:GetMaxArmor())
        v:SetSuitPower(100)
    end
end

return ITEM