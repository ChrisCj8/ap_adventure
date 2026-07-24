local ITEM = {}

ITEM.Name = "Barnacle Trap"
ITEM.Type = "OneUse"

ITEM.FillWeight = 5
ITEM.MinAmt = 0
ITEM.Trap = true
ITEM.RedeemCheck = true

local hulltr = util.TraceHull
local trace = util.TraceLine

local pos2 = Vector()
local trout = {}
local trtbl = {
	mins = Vector(-20,-20,0),
	maxs = Vector(20,20,0),
	filter = {"player"},
	endpos = pos2,
	mask = MASK_SOLID,
	output = trout,
}

local lastredeem = 0
function ITEM.Redeem()
	local sinceredeem = CurTime() - lastredeem
	if sinceredeem < 10 then return 10.5 - sinceredeem end
	local victims, cnt  = {}, 0
	for k,v in player.Iterator() do
		if v:Alive() and v:GetObserverMode() == OBS_MODE_NONE then
			cnt = cnt + 1
			victims[cnt] = v
		end
	end

	if !next(victims) then return 10 end
	local placed

	for k,v in ipairs(victims) do
		local pos = v:GetPos()
		trtbl.start = pos
		pos2.x,pos2.y,pos2.z = pos.x,pos.y,pos.z+800
		hulltr(trtbl)
		if trout.HitWorld and !trout.HitSky and trout.HitNormal.z < -.99 and trout.Fraction > .16 then
			local hit = trout.HitPos
			hit.z = hit.z - 1.2
			pos2.x,pos2.y,pos2.z = hit.x,hit.y,hit.z+8
			trtbl.start = hit
			trace(trtbl)
			if trout.HitWorld and trout.Fraction < .52 then
				local ent = ents.Create("npc_barnacle")
				ent:SetPos(hit)
				ent:Spawn()
				ent:Fire("DropTongue")
				placed = true
			end
		end
	end
	return placed or 10
end

return ITEM