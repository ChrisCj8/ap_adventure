
AddCSLuaFile()

DEFINE_BASECLASS("base_point")

function ENT:AcceptInput(inName,activator,caller,params)
    if inName == "Reload" then
        for k,v in ipairs(player.GetAll()) do
            v:ScreenFade(SCREENFADE.OUT,self.FadeColor,self.FadeTime,self.HoldTime)
        end
        if APADV_MAPGROUP then
            timer.Simple(self.LoadDelay,function() LoadCfg(APADV_MAPGROUP) end)
        end
    end
end