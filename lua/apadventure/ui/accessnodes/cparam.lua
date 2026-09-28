local NODE = {}

function NODE.InitNode()
	return {
		type = "cparam",
		o = "==",
		v = "",
		t = false,
		n = "",
		m = 3,
		i = 3,
	}
end

local ops = {
	{n="equals",op="=="},
	{n="greater",op=">"},
	{n="lesser",op="<"},
	{n="greatereq",op=">="},
	{n="lessereq",op="<="}
}

local string2val = {
	["true"] = true,
	["false"] = false,
	["True"] = true,
	["False"] = false,
}

local acc = {"canacc","ool","cantacc"}
local locstr = language.GetPhrase
local mkUI = vgui.Create

function NODE.Panel(parent)
	local nodetbl = parent.nodetbl

	local oplbl = mkUI("DLabel",parent)
	oplbl:SetText("#apadventure.node.cparam.op")
	oplbl:SetPos(5,5)
	oplbl:SetDark(true)

	local opselect = mkUI("DComboBox",parent)
	
	local curop = nodetbl.o
	for k,v in ipairs(ops) do
		opselect:AddChoice(v.op.." - "..locstr("apadventure.node.cparam.op."..v.n),v.op,v.op == curop)
	end
	function opselect:OnSelect(nr,val,data)
		parent.nodetbl.o = data
	end

	local namelbl = mkUI("DLabel",parent)
	namelbl:SetText("#apadventure.node.cparam.name")
	namelbl:SetPos(5,32)
	namelbl:SetDark(true)

	local namein = mkUI("DTextEntry",parent)
	namein:SetValue(parent.nodetbl.n)
	function namein:OnChange()
		parent.nodetbl.n = self:GetValue()
	end

	local vallbl = mkUI("DLabel",parent)
	vallbl:SetText("#apadventure.node.cparam.val")
	vallbl:SetPos(5,59)
	vallbl:SetDark(true)

	local valin = mkUI("DTextEntry",parent)
	local savedval = parent.nodetbl.v
	valin:SetValue(isstring(savedval) and savedval or tostring(savedval))

	local typelbl = mkUI("DLabel",parent)
	typelbl:SetText(locstr("apadventure.node.cparam.type."..type(savedval)))
	typelbl:SetPos(5,86)
	typelbl:SetDark(true)

	function valin:OnChange()
		local v = self:GetValue()
		local lead, trail = v[1] == " ", v[#v] == " "
		if lead or trail then
			typelbl:SetText(lead and (trail and "#apadventure.node.cparam.leadtrailwarn" or "#apadventure.node.cparam.leadwarn") or
				trail and "#apadventure.node.cparam.trailwarn")
		else
			local convertstring = string2val[v]
			if convertstring != nil then
				v = convertstring
			else
				v = tonumber(v) or v
			end
			typelbl:SetText(locstr("apadventure.node.cparam.type."..type(v)))
		end
		parent.nodetbl.v = v
	end

	local misslbl = mkUI("DLabel",parent)
	misslbl:SetText("#apadventure.node.cparam.miss")
	misslbl:SetPos(5,113)
	misslbl:SetDark(true)
	local missselect = mkUI("DComboBox",parent)

	local invalidlbl = mkUI("DLabel",parent)
	invalidlbl:SetText("#apadventure.node.cparam.invalid")
	invalidlbl:SetPos(5,140)
	invalidlbl:SetDark(true)
	local invalidselect = mkUI("DComboBox",parent)

	local curmiss,curinvalid = nodetbl.m,nodetbl.i
	for k,v in ipairs(acc) do
		local n = locstr("apadventure.node.cparam."..v)
		missselect:AddChoice(n,k,k==curmiss)
		invalidselect:AddChoice(n,k,k==curinvalid)
	end

	function missselect:OnSelect(nr,val,data)
		parent.nodetbl.m = data
	end

	function invalidselect:OnSelect(nr,val,data)
		parent.nodetbl.i = data
	end

	local helppnl = mkUI("DForm",parent)
	helppnl:SetPos(5,167)
	helppnl:SetLabel("#apadventure.node.shared.help")
	helppnl:Help("#apadventure.node.cparam.helpbase")
	helppnl:Help("#apadventure.node.cparam.helppreprocess")
	helppnl:Help("#apadventure.node.cparam.helpmiss")

	function parent:PerformLayout(w,h)
		local lblspace = w > 200 and 100 or w-100
		local valpos = lblspace + 10
		local valw = w-valpos-5
		oplbl:SetSize(lblspace,22)
		opselect:SetPos(valpos,5)
		opselect:SetSize(valw,22)

		namelbl:SetSize(lblspace,22)
		namein:SetPos(valpos,32)
		namein:SetSize(valw,22)

		vallbl:SetSize(lblspace,22)
		valin:SetPos(valpos,59)
		valin:SetSize(valw,22)

		typelbl:SetSize(w-10,22)

		misslbl:SetSize(lblspace,22)
		missselect:SetPos(valpos,113)
		missselect:SetSize(valw,22)

		invalidlbl:SetSize(lblspace,22)
		invalidselect:SetPos(valpos,140)
		invalidselect:SetSize(valw,22)

		helppnl:SetWide(w-10)
	end
end

return NODE