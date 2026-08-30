util.AddNetworkString("APAdvDeathLinkMessage")

local band = bit.band
local bor = bit.bor

local function DLmsg(cause,source)
	net.Start("APAdvDeathLinkMessage")
		local hascause = isstring(cause)
		net.WriteBool(hascause)
		local str = hascause and cause or isstring(source) and source or "?"
		net.WriteString(str)
	net.Broadcast()
end

local function reghandler(folder)
	local out = {}
	local wepfiles = file.Find("gamemodes/apadventure/gamemode/dl/"..folder.."/*.lua","GAME")
	for k,v in ipairs(wepfiles) do
		local tbl = include("apadventure/gamemode/dl/"..folder.."/"..v)
		if istable(tbl) then
			for ik,iv in pairs(tbl) do out[ik] = iv end
		end
	end
	return out
end

local wephandle = reghandler("wep")
local attckrhandle = reghandler("attckr")
local inflhandle = reghandler("infl")

local suicidemsgs = {
	{t=DMG_BLAST+DMG_BLAST_SURFACE,m="{p} blew themselves up."},
	{t=DMG_SHOCK,m="{p} electrocuted themselves."},
	{t=DMG_DROWN,m="{p} asphixiated themselves."},
	{t=DMG_DISSOLVE,m="{p} vaporized themselves."},
	{t=DMG_POISON,m="{p} poisoned themselves."},
	{t=DMG_ACID,m="{p} dissolved themselves."},
	{t=DMG_BULLET+DMG_BUCKSHOT+DMG_SNIPER+DMG_AIRBOAT,m="{p} shot themselves to death."},
	{t=DMG_ENERGYBEAM,m="{p} zapped themselves to death."},
}

local wrldmsgs = {
	{t=DMG_DROWN,m="{p} drowned."},
}

local killermsgs = {
	{t=DMG_BURN+DMG_SLOWBURN,m="{p} burnt to death by {k}."},
	{t=DMG_BLAST+DMG_BLAST_SURFACE,m="{p} was blown up by {k}."},
	{t=DMG_SHOCK,m="{p} was electrocuted by {k}."},
	{t=DMG_SONIC,m="{p} had their eardrums annihilated by {k}."},
	{t=DMG_DROWN,m="{p} asphixiated by {k}."},
	{t=DMG_DISSOLVE,m="{p} was vaporized by {k}."},
	{t=DMG_POISON,m="{p} was poisoned by {k}."},
	{t=DMG_ACID,m="{p} was dissolved by {k}."},
	{t=DMG_RADIATION,m="{p} was mutated by {k}."},
	{t=DMG_BULLET+DMG_BUCKSHOT+DMG_SNIPER+DMG_AIRBOAT,m="{p} was shot to death by {k}."},
	{t=DMG_ENERGYBEAM,m="{p} was zapped to death by {k}."},
	{t=DMG_CLUB,m="{p} was pummeled to death by {k}."},
	{t=DMG_CRUSH,m="{p} was crushed to death by {k}."},
	{t=DMG_SLASH,m="{p} was slashed apart by {k}."}
}


local genericmsgs = {
	{t=DMG_BURN+DMG_SLOWBURN,m="{p} burnt to death."},
	{t=DMG_BLAST+DMG_BLAST_SURFACE,m="{p} blew up."},
	{t=DMG_SHOCK,m="{p} was electrocuted."},
	{t=DMG_SONIC,m="{p} had their eardrums annihilated."},
	{t=DMG_FALL,m="{p} fell to their death."},
	{t=DMG_DROWN,m="{p} asphixiated."},
	{t=DMG_DISSOLVE,m="{p} was vaporized."},
	{t=DMG_POISON,m="{p} was poisoned."},
	{t=DMG_ACID,m="{p} was dissolved."},
	{t=DMG_RADIATION,m="{p} mutated."},
	{t=DMG_BULLET+DMG_BUCKSHOT+DMG_SNIPER+DMG_AIRBOAT,m="{p} was shot to death."},
	{t=DMG_ENERGYBEAM,m="{p} was zapped to death."},
	{t=DMG_CLUB,m="{p} was pummeled to death."},
	{t=DMG_CRUSH,m="{p} was crushed to death."},
	{t=DMG_SLASH,m="{p} was slashed apart."}
}

for k,v in ipairs(genericmsgs) do
	local allflags = 0
end

local function evaldmgtbl(tbl,val,msgtbl)
	for k,v in ipairs(tbl) do
		if band(v.t,val) != 0 then return string.Interpolate(v.m,msgtbl) end
	end
end

local function isenv(ent)
	if ent == Entity(0) then return true end
	if ent:GetModel()[1] == "*" then return true end
end

local function namegetter(ent)
	if ent:IsPlayer() then return ent:Nick() end
	return ent:GetClass()
end

local lastDL = CurTime()
local disablesend

local function SendDL(msg,plyname)
	DLmsg(msg)
	APADV_SLOT:SendDeathLink(msg,plyname)
	lastDL = CurTime()
end

function APADV.DLDeathHandler(ply,attckr,dmg)
	if disablesend or CurTime() - lastDL < 1 then return end
	local inflctr = dmg:GetInflictor()
	local plyname = ply:GetName()
	local msg
	local dmgtype = dmg:GetDamageType()
	local wep = dmg:GetWeapon()
	local killername = namegetter(attckr)
	print("victim",ply,"attckr",attckr,"inflctr",inflctr,"dmgtype",dmgtype,
		"\nreportedposition",dmg:GetReportedPosition(),"dmgcustom",dmg:GetDamageCustom(),
		"\ndmg",dmg:GetDamage(),"basedmg",dmg:GetBaseDamage(),"dmgforce",dmg:GetDamageForce(),
		"\nammo",dmg:GetAmmoType(),"maxdmg",dmg:GetMaxDamage(),"wpn",wep)

	if !IsValid(attckr) then
		SendDL(evaldmgtbl(genericmsgs,dmgtype,{p=plyname}) or (plyname.." died."),plyname)
	end

	local func = attckr.APADV_GetAttackerDLMessage or attckrhandle[attckr:GetClass()]
	if isfunction(func) then
		local newname
		ProtectedCall(function() msg, newname = func(attckr,ply,dmg,plyname,killername) end)
		if isstring(msg) then
			SendDL(msg,plyname)
			return
		elseif isstring(newname) then
			killername = newname
		end
	end

	if isenv(attckr) then
		SendDL(evaldmgtbl(wrldmsgs,dmgtype,{p=plyname}) or
			evaldmgtbl(genericmsgs,dmgtype,{p=plyname}) or
			(plyname.." died."),
			plyname)
	end

	func = IsValid(inflctr) and (inflctr.APADV_GetInflictorDLMessage or inflhandle[inflctr:GetClass()])
	if isfunction(func) then
		ProtectedCall(function() msg = func(inflctr,ply,dmg,plyname,killername) end)
		if isstring(msg) then SendDL(msg,plyname) return end
	end

	func = IsValid(wep) and (wep.APADV_GetWeaponDLMessage or wephandle[wep:GetClass()])
	if isfunction(func) then
		ProtectedCall(function() msg = func(wep,ply,dmg,plyname,killername) end)
		if isstring(msg) then SendDL(msg,plyname) return end
	end

	if ply == attckr then
		SendDL(evaldmgtbl(suicidemsgs,dmgtype,{p=plyname}) or
			-- the Player:Kill() function also reports the player as the attacker for some reason
			-- so we don't display the suicide message if the damage flags equal to DMG_NEVERGIB
			-- since i couldn't find another way to detect that that function was used
			dmgtype != DMG_NEVERGIB and (plyname.." killed themselves.") or
			(plyname.." died."),
			plyname)
		return
	end

	SendDL(evaldmgtbl(killermsgs,dmgtype,{p=plyname,k=killername}) or
		(plyname.." was killed by "..killername.."."),
		plyname)
end

function APADV.DLPacketHandler(packet)
	local data = packet.data
	if !data or CurTime() - lastDL < 1 then return end
	disablesend = true
	for k,v in player.Iterator() do
		if v:GetObserverMode() == OBS_MODE_NONE then
			v:Kill()
		end
	end
	disablesend = false
	DLmsg(data.cause,data.source)
	lastDL = CurTime()
end