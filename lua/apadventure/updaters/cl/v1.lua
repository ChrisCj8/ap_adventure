local doaccess
function doaccess(node)
    if !node or !next(node) then return node end
    if node.nodes then
        for k,v in ipairs(node.nodes) do 
            v = doaccess(v) 
        end
    elseif node.type == "capab" then
        node.capab = apAdventure.LookUpToList(node.capab)
    end
    return node
end

return function(cfg)
    cfg.ver = "v1_1"
    for k,v in pairs(cfg.connect) do
        for ik,iv in pairs(v) do
            iv.access = doaccess(iv.access)
        end
    end
    return cfg
end