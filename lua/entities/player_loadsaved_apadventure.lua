
AddCSLuaFile()

DEFINE_BASECLASS("base_point")

function ENT:AcceptInput(inName,activator,caller,params)
    if inName == "Reload" then
        for k,v in player.Iterator() do
            v:ScreenFade(SCREENFADE.OUT,self.FadeColor,self.FadeTime,self.HoldTime)
            timer.Simple(self.LoadDelay,function() v:ScreenFade(SCREENFADE.PURGE,color_white,0,0) end)
        end
        if APADV_MAPGROUP then
            timer.Simple(self.LoadDelay,function() APADV.LoadCfg(APADV_MAPGROUP) end)
        end
    end
end