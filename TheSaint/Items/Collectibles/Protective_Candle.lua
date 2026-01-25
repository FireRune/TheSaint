local isc = require("TheSaint.lib.isaacscript-common")
local enums = require("TheSaint.Enums")
local featureTarget = require("TheSaint.structures.FeatureTarget")

local game = Game()

--- Spawns a candle entity close to the player (like "Spear of Destiny")
--- - candle points where Isaac is shooting
--- - deals contact damage equal to Isaac's damage stat
--- - contact damage has a chance to inflict burn
--- - can be charged up to release a flame projectile
--- 
--- TODO:
--- - change sprite (with animated flame)
--- 
--- potential extras:
--- - smooth animation for rotation (see "Spear of Destiny")
--- - lower charge time for "The Saint"
--- - a way to deal with static tnt from a distance, to avoid forced damage (especially for "The Saint")
--- - maybe change properties of flame projectile
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
--- @field Pointer EntityPtr
--- @field Rotation number
--- @field FlameDirection Vector
--- @field InitFlame boolean
--- @field CurrentCharge integer
--- @field ChargeBar ChargeBarData

--- @class ChargeBarData
--- @field RenderOffset Vector
--- @field State AnimNames?
--- @field CurrentFrame integer

--#endregion

--#region constants (vectors via functions, so initial value is constant with every call)

--- Chargetime: ~2.5 seconds (9 frames before showing charge bar + 142 frames charging), getting as closely to "Maw of the Void" as possible
local CANDLE_INIT_CHARGE = -9
local CANDLE_MAX_CHARGE = 142

--- @return Vector
local function CANDLE_DEFAULT_OFFSET()
	return Vector(10, 45)
end

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
	return EntityPtr(Isaac.Spawn(entTarget.Type, entTarget.Variant, 0, player.Position, Vector.Zero, player))
end

--- @param player EntityPlayer
--- @return CandleRef?
local function getCandleRef(player)
	local playerIndex = "PC_"..isc:getPlayerIndex(player)
	if (hasProtectiveCandle(player) == true) then
		if (not playerCandles[playerIndex]) then
			playerCandles[playerIndex] = {
				Pointer = createCandle(player),
				Rotation = 0,
				FlameDirection = Vector.Zero,
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
	local mouse = Input.IsMouseBtnPressed(0) and Input.GetMousePosition(true)
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

--- @param player EntityPlayer
local function postPlayerUpdate(_, player)
	local candleRef = getCandleRef(player)
	if (candleRef) then
		local entCandle = candleRef.Pointer.Ref:ToEffect() --- @cast entCandle -?
		local shootingInput = getShootingVector(player)
		if (shootingInput:Length() >= 0.9) then
			-- charging up the flame projectile
			candleRef.CurrentCharge = math.min(candleRef.CurrentCharge + 1, CANDLE_MAX_CHARGE)

			-- handle shooting direction and candle rotation
			local shootAngle = getAngleDegreesForSpriteRotation(shootingInput)
			candleRef.Rotation = shootAngle
			candleRef.FlameDirection = shootingInput

			-- handle charge bar
			if ((not candleRef.ChargeBar.State) and (candleRef.CurrentCharge >= 0)) then
				candleRef.ChargeBar.State = "Charging"
				candleRef.ChargeBar.CurrentFrame = 0
			end
		else
			-- check whether or not to shoot flame projectile
			if (candleRef.CurrentCharge == CANDLE_MAX_CHARGE) then
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
		entCandle.SpriteRotation = candleRef.Rotation
		entCandle.Position = (player.Position + (CANDLE_DEFAULT_OFFSET():Rotated(entCandle.SpriteRotation)))
	end
end

--- Alter the flame projectile
--- @param effect EntityEffect
local function postEffectInit_RedCandleFlame(_, effect)
	print(effect.GridCollisionClass)
	effect.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_BULLET
end

--- @param entCandle EntityEffect
--- @return EntityPlayer?
local function getPlayerFromCandle(entCandle)
	local player = nil
	local spawner = entCandle.SpawnerEntity
	if (spawner) then
		player = spawner:ToPlayer()
	end
	return player
end

--- Returns whether the given entity should be damaged from "Protective Candle"
--- @param enemy Entity
--- @return boolean
local function isValidEnemy(enemy)
	local isActiveEnemy = (enemy:IsActiveEnemy() == true)
	local isNotFriendly = (enemy:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) == false)
	local isTNT = (enemy.Type == EntityType.ENTITY_MOVABLE_TNT)
	return ((isActiveEnemy and isNotFriendly) or isTNT)
end

--- @param effect EntityEffect
local function postEffectUpdate(_, effect)
	local player = getPlayerFromCandle(effect)
	if (not player) then return end

	-- handle damaging enemies
	local enemies = Isaac.FindInRadius(effect.Position, DAMAGE_RADIUS, EntityPartition.ENEMY)
	local sourceRef = EntityRef(effect)
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
	local gridEnt = room:GetGridEntityFromPos(effect.Position)
	if (gridEnt) then
		--- @diagnostic disable-next-line: undefined-field
		gridEnt:HurtWithSource(1, sourceRef)
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
				candleRef.ChargeBar.CurrentFrame = math.floor(math.min((candleRef.CurrentCharge / CANDLE_MAX_CHARGE) * frameCount, frameCount))
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
	mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, postEffectUpdate, Protective_Candle.Target.Entity.Variant)
	mod:AddCallback(ModCallbacks.MC_POST_PLAYER_RENDER, renderChargeBar, 0)
end

return Protective_Candle
