AddCSLuaFile()
DEFINE_BASECLASS("player_sandbox")

local PLY = {}

function PLY:Loadout()
	
end

APADV_PLYSTATS = APADV_PLYSTATS or {}

function PLY:Spawn()

	BaseClass.Spawn(self)

	self.Player:SetSlowWalkSpeed(APADV_PLYSTATS.SlowWalkSpeed or 100)
	self.Player:SetWalkSpeed(APADV_PLYSTATS.WalkSpeed or 200)
	self.Player:SetRunSpeed(APADV_PLYSTATS.RunSpeed or 400)
	self.Player:SetJumpPower(APADV_PLYSTATS.JumpPower or 200)
end

function PLY:StartMove( move )

    if APADV_BHOP then return end

	BaseClass.StartMove(self,move)

end

function PLY:FinishMove( move )

    if APADV_BHOP then return end

	BaseClass.FinishMove(self,move)

end

player_manager.RegisterClass("player_apadv",PLY,"player_sandbox")

print("updated player")