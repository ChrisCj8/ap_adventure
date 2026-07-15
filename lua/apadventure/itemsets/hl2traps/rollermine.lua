local ITEM = {}

ITEM.Name = "Rollermine Trap"
ITEM.Type = "OneUse"

ITEM.FillWeight = 5
ITEM.MinAmt = 0
ITEM.Trap = true
ITEM.RedeemCheck = true

local random = math.random
local traceenthull = util.TraceEntityHull
local band = bit.band
local pointcontent = util.PointContents

local posfilter = CONTENTS_WATER + CONTENTS_SLIME
local pos,pos2 = Vector(),Vector()
local testout = {}
local tracetbl = {
	output = testout,
	mask = MASK_SOLID_BRUSHONLY
}

function ITEM:Redeem()
	local victims, cnt  = {}, 0
	for k,v in player.Iterator() do
		if v:Alive() and v:GetObserverMode() == OBS_MODE_NONE then
			cnt = cnt + 1
			victims[cnt] = v
		end
	end

	if !next(victims) then return 10 end

	local placedany
	for k,v in ipairs(victims) do
		local eye = v:EyePos()

		for i=1,random(1,3) do
			local ent = ents.Create("npc_rollermine")
			ent:Spawn()
			local attempts, placed = 0, false
			repeat
				attempts = attempts + 1
				pos.x,pos.y,pos.z = eye.x+random(-1000,1000),eye.y+random(-1000,1000),eye.z+random(-300,300)
				tracetbl.start = eye
				tracetbl.endpos = pos
				traceenthull(tracetbl,ent)
				local out = testout.HitPos
				pos2.x,pos2.y,pos2.z = out.x,out.y,out.z-4000
				tracetbl.start = out
				tracetbl.endpos = pos2
				traceenthull(tracetbl,ent)
				local curpos = testout.HitPos
				if testout.Hit and band(pointcontent(curpos),posfilter) == 0 and curpos:DistToSqr(eye) > 10000 then
					ent:SetPos(curpos)
					placed = true
				end
			until attempts > 100 or placed
			if placed then
				placedany = true
			else
				ent:Remove()
			end
		end
	end
	return placedany or 10
end

return ITEM