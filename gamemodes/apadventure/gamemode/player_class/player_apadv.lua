AddCSLuaFile()
DEFINE_BASECLASS("player_sandbox")

local PLY = {}

function PLY:Loadout()
	
end

local JUMPING

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

	-- Only apply the jump boost in FinishMove if the player has jumped during this frame
	-- Using a global variable is safe here because nothing else happens between SetupMove and FinishMove
	if bit.band( move:GetButtons(), IN_JUMP ) ~= 0 and bit.band( move:GetOldButtons(), IN_JUMP ) == 0 and self.Player:OnGround() then
		JUMPING = true
	end

end

function PLY:FinishMove( move )

    if APADV_BHOP then return end

	-- If the player has jumped this frame
	if ( JUMPING ) then
		-- Get their orientation
		local forward = move:GetAngles()
		forward.p = 0
		forward = forward:Forward()

		-- Compute the speed boost

		-- HL2 normally provides a much weaker jump boost when sprinting
		-- For some reason this never applied to GMod, so we won't perform
		-- this check here to preserve the "authentic" feeling
		local speedBoostPerc = ( ( not self.Player:Crouching() ) and 0.5 ) or 0.1

		local speedAddition = math.abs( move:GetForwardSpeed() * speedBoostPerc )
		local maxSpeed = move:GetMaxSpeed() * ( 1 + speedBoostPerc )
		local newSpeed = speedAddition + move:GetVelocity():Length2D()

		-- Clamp it to make sure they can't bunnyhop to ludicrous speed
		if newSpeed > maxSpeed then
			speedAddition = speedAddition - ( newSpeed - maxSpeed )
		end

		-- Reverse it if the player is running backwards
		if move:GetVelocity():Dot( forward ) < 0 then
			speedAddition = -speedAddition
		end

		-- Apply the speed boost
		move:SetVelocity( forward * speedAddition + move:GetVelocity() )
	end

	JUMPING = nil

end

player_manager.RegisterClass("player_apadv",PLY,"player_sandbox")

print("updated player")