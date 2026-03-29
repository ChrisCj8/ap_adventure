local ITEM = {}

ITEM.Name = "Full Ammo"
ITEM.Type = "OneUse"

ITEM.FillWeight = 10
ITEM.MinAmt = 0

local ammotbl = {}

-- this way of handling ammo info may become a problem if i want to add a way to change the players ammo capacity in the future but this is fine for now
for k,v in ipairs(game.GetAmmoTypes()) do
    ammotbl[k] = game.GetAmmoMax(k)
end

function ITEM.Redeem()
    for k,v in player.Iterator() do
        for ik,iv in ipairs(ammotbl) do
            v:SetAmmo(iv,ik)
        end
    end
end

return ITEM