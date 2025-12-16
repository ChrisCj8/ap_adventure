DEFINE_BASECLASS("base_point")

function ENT:Initialize()
    if self.ItemName and self.Outputs then
        local iname = self.ItemName
        APADV.MapItemCounters[iname] = APADV.MapItemCounters[iname] or {}
        local i = #APADV.MapItemCounters[iname]
        for k,v in ipairs(self.Outputs) do
            i = i+1
            APADV.MapItemCounters[iname][i] = {
                target = v[1],
                input = v[2],
                param = v[3],
                delay = v[4],
                refire = v[5]
            }
        end
    end
    self:Remove()
end

local keyignore = {
    hammerid = true,
    classname = true,
    origin = true,
}

function ENT:KeyValue(key,value)
    if keyignore[key] then return end
    if key == "item" then 
        self.ItemName = value
    elseif key == "ItemCount" then
        self.OutputAmt = (self.OutputAmt or 0) + 1
        self.Outputs = self.Outputs or {}
        self.Outputs[self.OutputAmt] = string.explode("\x1B",value)
    end
end