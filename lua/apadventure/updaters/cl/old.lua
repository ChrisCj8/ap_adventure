return function(cfg)
    cfg.ver = "v1"
    for k,v in pairs(cfg.reg) do
        v.con_int, v.con_ext = nil
        if !next(v) then
            v.cond = {}
        end
    end
    return cfg
end