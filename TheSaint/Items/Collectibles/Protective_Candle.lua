local isc = require("TheSaint.lib.isaacscript-common")
local enums = require("TheSaint.Enums")
local featureTarget = require("TheSaint.structures.FeatureTarget")

local game = Game()

--- Spawns a candle entity close to the player (like "Spear of Destiny")
--- - candle points where Isaac is shooting
--- - deals contact damage equal to Isaac's damage stat
--- - contact damage has a chance to inflict burn
--- - can be charged up to release a flame projectile
--- - having spectral tears allows the flame to go through grid entities
--- 
--- TODO:
--- - change sprite (with animated flame)
--- 
--- future extras:
--- - if player has a certain property, alter flame projectile accordingly
---   - homing: purple flame, flame homes in on nearby enemies
---   - "Continuum": flame goes through walls, loops around the screen
--- @class TheSaint.Items.Collectibles.Protective_Candle : TheSaint.classes.ModFeatureTargeted<CollectibleType>
local Protective_Candle = {
	IsInitialized = false,
	--- @type TheSaint.structures.FeatureTarget<CollectibleType>
	Target = featureTarget:new(enums.CollectibleType.COLLECTIBLE_PROTECTIVE_CANDLE, {EntityType.ENTITY_EFFECT, enums.EffectVariant.PROTECTIVE_CANDLE}, enums.PlayerType.PLAYER_THE_SAINT),
}

--#region typedef

--- @alias AnimNames
--- | "Charging"
--- | "StartCharged"
--- | "Charged"
--- | "Disappear"

--- @class CandleRef
--- @field Pointer EntityPtr		@ pointer to the candle entity
--- @field FlameDirection Vector	@ used for the flame projectile
--- @field TargetOffset Vector		@ used to set the candle entity's rotation and position
--- @field InitFlame boolean		@ flag to distinguish this item's flame projectile from those of "Red Candle"
--- @field CurrentCharge integer	@ current charge value (in frames)
--- @field ChargeBar ChargeBarData	@ data holder for chargebar-related data

--- @class ChargeBarData
--- @field RenderOffset Vector
--- @field State AnimNames?
--- @field CurrentFrame integer

--#endregion

--#region constants (vectors via functions, so initial value is constant with every call)

--- Chargetime:
--- - ~2.5 seconds (9 frames before showing charge bar + 142 frames charging), getting as closely to "Maw of the Void" as possible.
--- - (The Saint only) ~2 seconds (9 frames before showing charge bar + 112 frames charging)
local CANDLE_INIT_CHARGE = -9
--- @param player EntityPlayer
--- @return integer
local function CANDLE_MAX_CHARGE(player)
	local maxCharge = 142
	if (isc:isCharacter(player, table.unpack(Protective_Candle.Target.Character))) then
		return (maxCharge - 30)
	end
	return maxCharge
end

--- Vector(10, 45)
--- @return Vector
local function CANDLE_DEFAULT_OFFSET()
	return Vector(10, 45)
end

--- Vector(-11, -39)
--- @return Vector
local function CHARGEBAR_DEFAULT_OFFSET()
	return Vector(-11, -39)
end

local FRAME_COUNTS = {
	["Charging"] = 100,
	["StartCharged"] = 11,
	["Charged"] = 5,
	["Disappear"] = 8
}

--- damage radius of the candle entity
local DAMAGE_RADIUS = 13.0

--#endregion

--#region fields

--- @type table<string, CandleRef>
local playerCandles = {}

local barSprite = Sprite()
barSprite:Load("gfx/chargebar_protective_candle.anm2", true)

--#endregion

--- @param player EntityPlayer
--- @return boolean @ `true` if the player has "Protective Candle" or is "The Saint", otherwise `false`
local function hasProtectiveCandle(player)
	return (player:HasCollectible(Protective_Candle.Target.Type) or (isc:isCharacter(player, table.unpack(Protective_Candle.Target.Character))))
end

--- @param player EntityPlayer
--- @return EntityPtr
local function createCandle(player)
	local entTarget = Protective_Candle.Target.Entity --- @cast entTarget -?
	local entCandle = Isaac.Spawn(entTarget.Type, entTarget.Variant, 0, player.Position + CANDLE_DEFAULT_OFFSET(), Vector.Zero, player)

	-- same as "Spear of Destiny"
	entCandle.PositionOffset = Vector(0, -15)

	return EntityPtr(entCandle)
end

--- @param player EntityPlayer
--- @return CandleRef?
local function getCandleRef(player)
	local playerIndex = "PC_"..isc:getPlayerIndex(player)
	if (hasProtectiveCandle(player) == true) then
		if (not playerCandles[playerIndex]) then
			playerCandles[playerIndex] = {
				Pointer = createCandle(player),
				FlameDirection = Vector.Zero,
				TargetOffset = CANDLE_DEFAULT_OFFSET(),
				InitFlame = false,
				CurrentCharge = CANDLE_INIT_CHARGE,
				ChargeBar = {
					RenderOffset = CHARGEBAR_DEFAULT_OFFSET(),
					CurrentFrame = 0,
				},
			}
		elseif (not playerCandles[playerIndex].Pointer.Ref) then
			playerCandles[playerIndex].Pointer = createCandle(player)
		end
	else
		playerCandles[playerIndex] = nil
	end
	return playerCandles[playerIndex]
end

--- alternative to `player:GetShootingInput` which supports mouse controls
--- @param player EntityPlayer
--- @return Vector
local function getShootingVector(player)
	local sVector = Vector.Zero
	local mouse = (Input.IsMouseBtnPressed(Mouse.MOUSE_BUTTON_LEFT) and Input.GetMousePosition(true))
	if mouse then
		sVector = (mouse - player.Position)
	else
		sVector = player:GetShootingInput()
	end
	return sVector:Normalized()
end

--- @param vInput Vector
--- @return number
local function getAngleDegreesForSpriteRotation(vInput)
	local vInputBackup = Vector(vInput.X, vInput.Y)
	return vInputBackup:Rotated(-90):GetAngleDegrees()
end

--- @param a number
--- @param b number
--- @return number
local function angleDiff(a, b)
	local diff = (a - b)
	return (((diff + 180) % 360) - 180)
end
--- @param a number
--- @param b number
--- @param p number
--- @return number
local function lerpAngle(a, b, p)
	return (a + (angleDiff(b, a) * p))
end

--- handle candle entity movement + attack (charge & release)
--- @param player EntityPlayer
local function postPlayerUpdate(_, player)
	local candleRef = getCandleRef(player)
	if (candleRef) then
		local entCandle = candleRef.Pointer.Ref:ToEffect() --- @cast entCandle -?
		local shootingInput = getShootingVector(player)

		-- in case the player decides to press opposing shoot directions, maintain previous input
		if (player:AreOpposingShootDirectionsPressed()) then
			shootingInput = candleRef.FlameDirection
		end

		if (shootingInput:Length() > 0.01) then
			-- charging up the flame projectile
			candleRef.CurrentCharge = math.min(candleRef.CurrentCharge + 1, CANDLE_MAX_CHARGE(player))

			-- handle shooting direction and candle rotation
			candleRef.FlameDirection = shootingInput
			local shootAngle = getAngleDegreesForSpriteRotation(shootingInput)
			candleRef.TargetOffset = CANDLE_DEFAULT_OFFSET():Rotated(shootAngle)

			-- handle charge bar
			if ((not candleRef.ChargeBar.State) and (candleRef.CurrentCharge >= 0)) then
				candleRef.ChargeBar.State = "Charging"
				candleRef.ChargeBar.CurrentFrame = 0
			end
		else
			-- check whether or not to shoot flame projectile
			if (candleRef.CurrentCharge == CANDLE_MAX_CHARGE(player)) then
				candleRef.InitFlame = true
				player:ShootRedCandle(candleRef.FlameDirection)
			end
			candleRef.FlameDirection = Vector.Zero
			candleRef.CurrentCharge = CANDLE_INIT_CHARGE
			if ((candleRef.ChargeBar.State ~= nil) and (candleRef.ChargeBar.State ~= "Disappear")) then
				candleRef.ChargeBar.State = "Disappear"
				candleRef.ChargeBar.CurrentFrame = 0
			end
		end

		-- Position & Sprite rotation
		local angleCandle = (entCandle.Position - player.Position):GetAngleDegrees()
		local angleTarget = candleRef.TargetOffset:GetAngleDegrees()
		local angleNext = lerpAngle(angleCandle, angleTarget, 0.2)
		entCandle.SpriteRotation = (angleNext - CANDLE_DEFAULT_OFFSET():GetAngleDegrees())
		entCandle.Position = (player.Position + (Vector.FromAngle(angleNext) * CANDLE_DEFAULT_OFFSET():Length()))
	end
end

--- @param effect EntityEffect
--- @return EntityPlayer?
local function getPlayerFromEffect(effect)
	local player = nil
	local spawner = effect.SpawnerEntity
	if (spawner) then
		player = spawner:ToPlayer()
	end
	return player
end

--- Alter the flame projectile
--- @param entFlame EntityEffect
local function postEffectInit_RedCandleFlame(_, entFlame)
	local player = getPlayerFromEffect(entFlame)
	if (not player) then return end

	local candleRef = getCandleRef(player)
	if (candleRef and candleRef.InitFlame) then
		if (isc:hasSpectral(player)) then
			entFlame.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
		end

		-- initialization finished
		candleRef.InitFlame = false
	end
end

--- Returns whether the given entity should be damaged from "Protective Candle"
--- @param enemy Entity
--- @param includeTNT? boolean @ default: `true`
--- @return boolean
local function isValidEnemy(enemy, includeTNT)
	if (includeTNT == nil) then includeTNT = true end

	local isActiveEnemy = (enemy:IsActiveEnemy() == true)
	local isNotFriendly = (enemy:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) == false)
	local isTNT = (includeTNT and (enemy.Type == EntityType.ENTITY_MOVABLE_TNT))
	return ((isActiveEnemy and isNotFriendly) or isTNT)
end

--- check for collision with static TNT and handle effects of homing and "Continuum"
--- @param entFlame EntityEffect
local function postEffectUpdate_RedCandleFlame(_, entFlame)
	local player = getPlayerFromEffect(entFlame)
	if (not player) then return end

	local data = entFlame:GetData().TheSaint
	if (data) then
		local room = game:GetRoom()
		local sourceRef = EntityRef(entFlame)

		-- handle static TNT
		local gridEnt = room:GetGridEntityFromPos(entFlame.Position)
		-- TNT.State has a value from 0 to 4, with 4 being the destroyed TNT; therefore ignore that state
		if ((gridEnt) and (gridEnt:GetType() == GridEntityType.GRID_TNT) and (gridEnt.State < 4)) then
			if (REPENTANCE_PLUS) then
				--- @diagnostic disable-next-line: undefined-field
				gridEnt:DestroyWithSource(false, sourceRef)
			else
				gridEnt:Destroy(false)
			end
		end
	end
end

--- handle damaging enemies and grid entities
--- @param entCandle EntityEffect
local function postEffectUpdate_ProtectiveCandle(_, entCandle)
	local player = getPlayerFromEffect(entCandle)
	if (not player) then return end

	-- handle damaging enemies
	local enemies = Isaac.FindInRadius(entCandle.Position, DAMAGE_RADIUS, EntityPartition.ENEMY)
	local sourceRef = EntityRef(entCandle)
	local rng = player:GetCollectibleRNG(Protective_Candle.Target.Type)
	-- use math.max to prevent dividing by zero and mathmatical underflow at high luck
	local chance = (1 / math.max(1, (10 - math.floor(player.Luck * 0.7))))

	for _, enemy in ipairs(enemies) do
		if (isValidEnemy(enemy) == true) then
			enemy:TakeDamage(player.Damage, DamageFlag.DAMAGE_FIRE, sourceRef, 30)
			if (rng:RandomFloat() < chance) then
				enemy:AddBurn(sourceRef, 30, player.Damage)
			end
		end
	end

	-- handle damaging grid entity at candle position (poops and static tnt)
	local room = game:GetRoom()
	local gridEnt = room:GetGridEntityFromPos(entCandle.Position)
	if (gridEnt) then
		if (REPENTANCE_PLUS) then
			--- @diagnostic disable-next-line: undefined-field
			gridEnt:HurtWithSource(1, sourceRef)
		else
			gridEnt:Hurt(1)
		end
	end
end

--#region Charge Bar

--- @param candleRef CandleRef
--- @param frameCount integer
--- @param nextState AnimNames?
local function tryNextState(candleRef, frameCount, nextState)
	if (candleRef.ChargeBar.CurrentFrame == frameCount) then
		candleRef.ChargeBar.State = nextState
		candleRef.ChargeBar.CurrentFrame = 0
	end
end

--- @param player EntityPlayer
local function renderChargeBar(_, player)
	-- only show charge bar if enabled
	if (Options.ChargeBars == false) then return end

	-- don't render for reflected player in rooms with water
	if (game:GetRoom():GetRenderMode() == RenderMode.RENDER_WATER_REFLECT) then return end

	local candleRef = getCandleRef(player)
	if ((candleRef) and (candleRef.ChargeBar.State)) then
		if (not game:IsPaused()) then
			local frameCount = FRAME_COUNTS[candleRef.ChargeBar.State]

			-- set frame
			barSprite:SetFrame(candleRef.ChargeBar.State, candleRef.ChargeBar.CurrentFrame)

			-- calculate current charge
			if (candleRef.ChargeBar.State == "Charging") then
				candleRef.ChargeBar.CurrentFrame = math.floor(math.min((candleRef.CurrentCharge / CANDLE_MAX_CHARGE(player)) * frameCount, frameCount))
				tryNextState(candleRef, frameCount, "StartCharged")
			else
				candleRef.ChargeBar.CurrentFrame = math.min(candleRef.ChargeBar.CurrentFrame + 1, frameCount)
				if ((candleRef.ChargeBar.State == "StartCharged") or (candleRef.ChargeBar.State == "Charged")) then
					tryNextState(candleRef, frameCount, "Charged")
				elseif (candleRef.ChargeBar.State == "Disappear") then
					tryNextState(candleRef, frameCount, nil)
				end
			end
		end
		barSprite:Render(Isaac.WorldToScreen(player.Position) + candleRef.ChargeBar.RenderOffset)
	end
end

--#endregion

--- @param mod ModUpgraded
function Protective_Candle:Init(mod)
	if (self.IsInitialized) then return end

	mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, postPlayerUpdate, 0)
	mod:AddCallback(ModCallbacks.MC_POST_EFFECT_INIT, postEffectInit_RedCandleFlame, EffectVariant.RED_CANDLE_FLAME)
	mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, postEffectUpdate_RedCandleFlame, EffectVariant.RED_CANDLE_FLAME)
	mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, postEffectUpdate_ProtectiveCandle, Protective_Candle.Target.Entity.Variant)
	mod:AddCallback(ModCallbacks.MC_POST_PLAYER_RENDER, renderChargeBar, 0)

	mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, function ()
		-- reset data holders
		playerCandles = {}
	end)
end

return Protective_Candle
