return {
    OnFullConnect = function(self)
        if APADV.MapLocationStatus("Stopped Police Brutality") then return end

        hook.Add("AcceptInput",self,function(self, ent,input) 
            if ent:GetName() == "arrest_police_assault" and input == "Deactivate" then
                if APADV.SendMapLocation("Stopped Police Brutality") then
                    hook.Remove("AcceptInput",self)
                end
            end
        end)
    end
}