local entsbyname = ents.FindByName

return {
    OnFullConnect = function(self)

        entsbyname("gate_mover_blocker")[1]:Remove()
        entsbyname("gate_linear")[1]:Fire("open")

        --if APADV.MapLocationStatus("Inside Antlion Guard") then return end
        local vortgoal = entsbyname("leadgoal_vortigaunt")[1]

        hook.Add("AcceptInput",self,function(self,ent,input) 
            --doubt there's anything else with an input called ExtractBugbait so just checking the input name should be fine
            if ent == vortgoal and input == "Activate" then
                --kinda sucks to have to do this through a timer but i couldn't find a better event to attach it to
                APADV.SendMapLocation("Inside Antlion Guard")
                timer.Simple(4,function()
                    vortgoal:Fire("SetSuccess")
                    entsbyname("camp_setup")[1]:Fire("Trigger")
                    entsbyname("antlion_cage_door")[1]:Fire("Open")
                end)
                hook.Remove("AcceptInput",self)
            end
        end)
    end
}