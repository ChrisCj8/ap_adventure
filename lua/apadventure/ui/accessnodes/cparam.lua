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

local acc = {"canacc","ool","cantacc"}
local locstr = language.GetPhrase

function NODE.Panel(parent)
	local nodetbl = parent.nodetbl

	local oplbl = vgui.Create("DLabel",parent)
	oplbl:SetText("#apadventure.node.cparam.op")
	oplbl:SetPos(5,5)
	oplbl:SetDark(true)

	local opselect = vgui.Create("DComboBox",parent)
	
	local curop = nodetbl.o
	for k,v in ipairs(ops) do
		opselect:AddChoice(v.op.." - "..locstr("apadventure.node.cparam.op."..v.n),v.op,v.op == curop)
	end
	function opselect:OnSelect(nr,val,data)
		parent.nodetbl.o = data
	end

	local namelbl = vgui.Create("DLabel",parent)
	namelbl:SetText("#apadventure.node.cparam.name")
	namelbl:SetPos(5,32)
	namelbl:SetDark(true)

	local namein = vgui.Create("DTextEntry",parent)
	namein:SetValue(parent.nodetbl.n)
	function namein:OnChange()
		parent.nodetbl.n = self:GetValue()
	end

	local vallbl = vgui.Create("DLabel",parent)
	vallbl:SetText("#apadventure.node.cparam.val")
	vallbl:SetPos(5,59)
	vallbl:SetDark(true)

	local valin = vgui.Create("DTextEntry",parent)
	valin:SetValue(parent.nodetbl.v)
	function valin:OnChange()
		local v = self:GetValue()
		parent.nodetbl.v = tonumber(v) or v
	end


	local misslbl = vgui.Create("DLabel",parent)
	misslbl:SetText("#apadventure.node.cparam.miss")
	misslbl:SetPos(5,86)
	misslbl:SetDark(true)
	local missselect = vgui.Create("DComboBox",parent)

	local invalidlbl = vgui.Create("DLabel",parent)
	invalidlbl:SetText("#apadventure.node.cparam.invalid")
	invalidlbl:SetPos(5,113)
	invalidlbl:SetDark(true)
	local invalidselect = vgui.Create("DComboBox",parent)

	local curmiss,curinvalid = nodetbl.m,nodetbl.i
	for k,v in ipairs(acc) do
		local n = locstr("apadventure.node.cparam."..v)
		missselect:AddChoice(n,k,k==curmiss)
		invalidselect:AddChoice(n,k,k==curinvalid)
	end

	function missselect:OnSelect(nr,val,data)
		parent.nodetbl.m = data
	end

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

		misslbl:SetSize(lblspace,22)
		missselect:SetPos(valpos,86)
		missselect:SetSize(valw,22)

		invalidlbl:SetSize(lblspace,22)
		invalidselect:SetPos(valpos,113)
		invalidselect:SetSize(valw,22)
	end
end

return NODE