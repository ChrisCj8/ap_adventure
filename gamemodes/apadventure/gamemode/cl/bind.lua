if !APADV_GLBINDS then
	local json = file.Read("apadventure/gamemodebinds.json")
	APADV_GLBINDS = json and util.JSONToTable(json) or {}
end
if !APADV_RUNBINDS then APADV_RUNBINDS = {} end

local bindhandle = {
	ccmd = function(tbl,ply,press,btn)
		local newcmd = tbl[press and "push" or "rel"]
		if newcmd then ply:ConCommand(newcmd) end
	end,
	wep = function(tbl,ply,press,btn)
		if !press then return end
		local wep = ply:GetWeapon(tbl.wep)
		if IsValid(wep) then input.SelectWeapon(wep) end
	end
}

function GM:PlayerBindPress(ply,cmd,press,btn)
	local bind = APADV_RUNBINDS[btn] or APADV_GLBINDS[btn]
	if !bind or !bind.type then return end
	local func = bindhandle[bind.type]
	if !func then return end
	return func(bind,ply,press,btn) or true
end

if !file.IsDir("apadventure/runbinds/","DATA") then
	file.CreateDir("apadventure/runbinds/")
end
function APADV.SaveRunBinds()
	if APADV.RunBindsChanged then
		local path = "apadventure/runbinds/"..APADV_RUNID
		if next(APADV_RUNBINDS) then
			file.Write(path..".json",util.TableToJSON(APADV_RUNBINDS))
			local namepath = path..".txt"
			if !file.Exists(namepath,"DATA") then
				file.Write(namepath,APADV.slotName)
			end
		elseif file.Exists(path..".json","DATA") then
			file.Delete(path..".json")
			file.Delete(path..".txt")
		end
	end
end

concommand.Add("apadv_resetglobalbinds",function(ply)
	APADV_GLBINDS = {}
	APADV.GLBindsChanged = true
end)

concommand.Add("apadv_resetrunbinds",function(ply)
	APADV_RUNBINDS = {}
	APADV.RunBindsChanged = true
end)