local out = {
	{n="flashl",push="impulse 100"},
	{n="npccmd",push="impulse 50"},
	{n="cmenu",push="+menu_context",rel="-menu_context"},
	{n="zoom",push="+zoom",rel="-zoom"}
}

for k,v in ipairs(out) do
	local name = language.GetPhrase("apadventure.bindui.ccmdpre."..v.n)
	if v.push and v.rel then
		v.n = name.." ( "..v.push.." / "..v.rel.." )"
	else
		v.n = name.." ( "..(v.push or v.rel).." )"
	end
	v.type = "ccmd"
end

out[#out+1] = {n=language.GetPhrase("apadventure.bindui.ccmdpre.ccmdempty"),type="ccmd"}

return out