local ITEM = {}

ITEM.Name = "Manhack Trap"
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
local testpos = Vector()
local testout = {}
local tracetbl = {
	endpos = testpos,
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
		local plyeyes = v:EyePos()
		tracetbl.start = plyeyes
		for i=1,random(2,5) do
			local ent = ents.Create("npc_manhack")
			ent:Spawn()
			local attempts, placed = 0, false

			repeat
				attempts = attempts + 1
				testpos.x,testpos.y,testpos.z = plyeyes.x+random(-1000,1000),plyeyes.y+random(-1000,1000),plyeyes.z+random(-300,300)
				traceenthull(tracetbl,ent)
				local hit = testout.HitPos
				if band(pointcontent(hit),posfilter) == 0 and hit:DistToSqr(plyeyes) > 10000 then
					ent:SetPos(hit)
					placed = true
				end
			until attempts > 16 or placed
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