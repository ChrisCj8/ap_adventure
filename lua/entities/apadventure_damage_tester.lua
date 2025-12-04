AddCSLuaFile()

DEFINE_BASECLASS("base_gmodentity")

ENT.PrintName = "#apadventure.entity.damagetest"
ENT.Category = "#apadventure.category"
ENT.Spawnable = true

function ENT:Initialize()
    self:SetModel("models/hunter/blocks/cube05x05x05.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
end

local dmg2str = {
    [DMG_GENERIC] = "Generic",
    [DMG_CRUSH] = "Crush",
    [DMG_BULLET] = "Bullet",
    [DMG_SLASH] = "Slash",
    [DMG_BURN] = "Burn",
    [DMG_VEHICLE] = "Vehicle",
    [DMG_FALL] = "Fall",
    [DMG_BLAST] = "Blast",
    [DMG_CLUB] = "Club",
    [DMG_SHOCK] = "Shock",
    [DMG_SONIC] = "Sonic",
    [DMG_ENERGYBEAM] = "Energy Beam",
    [DMG_PREVENT_PHYSICS_FORCE] = "Prevent Physics Force",
    [DMG_NEVERGIB] = "NeverGib",
    [DMG_ALWAYSGIB] = "AlwaysGib",
    [DMG_DROWN] = "Drown",
    [DMG_PARALYZE] = "Paralyze",
    [DMG_NERVEGAS] = "Nerve Gas",
    [DMG_POISON] = "Poison",
    [DMG_RADIATION] = "Radiation",
    [DMG_PLASMA] = "Plasma",
    [DMG_AIRBOAT] = "Airboat",
    [DMG_DISSOLVE] = "Dissolve",
    [DMG_BLAST_SURFACE] = "Blast Surface",
    [DMG_DIRECT] = "Direct",
    [DMG_BUCKSHOT] = "Buckshot",
    [DMG_SNIPER] = "Sniper",
    [DMG_MISSILEDEFENSE] = "Missile Defense"
}

function ENT:OnTakeDamage(dmginfo)
    local dmgtypes = {}
    local typeamt = 0
    for i=0,31 do
        local type = 2^i
        if dmginfo:IsDamageType(type) then
            --print(dmg2str[type])
            typeamt = typeamt + 1
            dmgtypes[typeamt] = dmg2str[type]
        end
    end
    local typestr
    if !dmgtypes[1] then
        typestr = "Generic"
    else
        for k,v in ipairs(dmgtypes) do
            if !typestr then
                typestr = v
            else
                typestr = typestr.." "..v
            end
        end
    end
    print(dmginfo:GetDamage(),dmginfo:GetBaseDamage(),dmginfo:GetMaxDamage(),typestr)
    return 0
end