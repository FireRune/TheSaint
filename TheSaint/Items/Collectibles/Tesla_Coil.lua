local isc = require("TheSaint.lib.isaacscript-common")
local enums = require("TheSaint.Enums")
local featureTarget = require("TheSaint.structures.FeatureTarget")
local statusEffects = require("TheSaint.StatusEffects")
local utils = include("TheSaint.utils")

local game = Game()

--- "Tesla Coil"
--- - 4 Room Charge
--- - on use, spawns an entity like "Sprinkler"
--- - entity repeatedly generates sparks around it
--- - sparks deal 50% of Isaac's damage and inflict "Electrified"
--- @class TheSaint.Items.Collectibles.Tesla_Coil : TheSaint.classes.ModFeatureTargeted<CollectibleType>
local Tesla_Coil = {
	IsInitialized = false,
	--- @type TheSaint.structures.FeatureTarget<CollectibleType>
	Target = featureTarget:new(enums.CollectibleType.COLLECTIBLE_TESLA_COIL, {EntityType.ENTITY_FAMILIAR, enums.FamiliarVariant.TESLA_COIL}),
}

local RANDOM_SPARK_RADIUS = 50
local TARGETED_SPARK_RADIUS = 100

--- @param collectible CollectibleType
--- @param rng RNG
--- @param player EntityPlayer
--- @param flags UseFlag
--- @param slot ActiveSlot
--- @param varData integer
--- @return { Discharge: boolean, Remove: boolean, ShowAnim: boolean }?
local function useItem(_, collectible, rng, player, flags, slot, varData)
	local room = game:GetRoom()
	local gridIdx = room:GetGridIndex(player.Position)
	local gridPos = room:GetGridPosition(gridIdx)

	Isaac.Spawn(EntityType.ENTITY_FAMILIAR, Tesla_Coil.Target.Entity.Variant, 0, gridPos, Vector.Zero, player)

	return {
		Discharge = true,
		Remove = false,
		ShowAnim = (flags & UseFlag.USE_NOANIM ~= UseFlag.USE_NOANIM),
	}
end

--- @param familiar EntityFamiliar
local function familiarInit_TeslaCoil(_, familiar)
	familiar.FireCooldown = 14
end

--- @param angle number
--- @param distance number
--- @param familiar EntityFamiliar
--- @param player EntityPlayer
--- @return EntityLaser
local function spawnSpark(angle, distance, familiar, player)
	local spark = EntityLaser.ShootAngle(LaserVariant.ELECTRIC, familiar.Position, angle, 1, Vector(0, -30), familiar)
	spark:SetMaxDistance(distance)
	spark.DepthOffset = 10
	spark.CollisionDamage = (player.Damage * 0.5)
	return spark
end

--- @param familiar EntityFamiliar
--- @param player EntityPlayer
--- @return EntityLaser
local function randomSpark(familiar, player)
	local angle = RandomVector():GetAngleDegrees()
	local spark = spawnSpark(angle, RANDOM_SPARK_RADIUS, familiar, player)
	return spark
end

-- flag to prevent a spark from spawning when continuing a run
local sparkPreventer = true

--- @param familiar EntityFamiliar
local function familiarUpdate_TeslaCoil(_, familiar)
	local room = game:GetRoom()
	local gridIdx = room:GetGridIndex(familiar.Position)
	room:SetGridPath(gridIdx, 700)

	if (sparkPreventer) then return end

	local player = familiar.Player
	if (not player) then return end

	if (familiar.FireCooldown % 5 == 0) then
		randomSpark(familiar, player)
	end
	if (familiar.FireCooldown <= 0) then
		-- shoot targeted spark
		local enemies = Isaac.FindInRadius(familiar.Position, TARGETED_SPARK_RADIUS, EntityPartition.ENEMY)
		--- @type Entity?
		local clostEnemy = isc:getClosestEntityTo(familiar, enemies, function (_, ent)
			local enemy = ((utils:IsValidEnemy(ent, false) and ent:ToNPC()) or nil)
			return (enemy ~= nil)
		end)
		if (clostEnemy) then
			local sparkVector = (clostEnemy.Position - familiar.Position)
			local angle = sparkVector:GetAngleDegrees()
			local distance = sparkVector:Length()
			spawnSpark(angle, distance, familiar, player)
		end

		familiar.FireCooldown = 15
	end
	familiar.FireCooldown = familiar.FireCooldown - 1
end

--- @param wisp EntityFamiliar
local function familiarUpdate_Wisp(_, wisp)
	local wispData = wisp:GetData().TheSaint
	if (wispData) then
		wispData.CollisionDetected = false
	else
		wispData = {
			CollisionDetected = false,
		}
	end
	wisp:GetData().TheSaint = wispData
end

--- @param wisp EntityFamiliar
--- @param collider Entity
--- @param low boolean
local function preFamiliarCollision_TeslaCoilWisp(_, wisp, collider, low)
	local enemy = ((utils:IsValidEnemy(collider, false) and collider:ToNPC()) or nil)
	if (not enemy) then return end

	local wispData = wisp:GetData().TheSaint
	if (wispData) then
		wispData.CollisionDetected = true
	else
		wispData = {
			CollisionDetected = true,
		}
	end
	wisp:GetData().TheSaint = wispData
end

--- Apply "Electrified" status when damaged from "Tesla Coil" entity OR contact damage from "Tesla Coil" wisp
--- @param ent Entity
--- @param amount number	@ value is an integer when `ent` is `EntityPlayer`, otherwise it's a float
--- @param flags DamageFlag
--- @param source EntityRef
--- @param countdown integer
local function entityTakeDamage(_, ent, amount, flags, source, countdown)
	local enemy = ent:ToNPC()
	if (not enemy) then return end

	local familiar = source.Entity:ToFamiliar()
	if (not familiar) then return end

	local famCheck = false
	if (familiar.Variant == Tesla_Coil.Target.Entity.Variant) then
		famCheck = true
	elseif ((familiar.Variant == FamiliarVariant.WISP) and (familiar.SubType == Tesla_Coil.Target.Type)) then
		local wispData = familiar:GetData().TheSaint
		if (wispData) and (wispData.CollisionDetected) then
			famCheck = true
		end
	end
	if (not famCheck) then return end

	local player = (familiar.SpawnerEntity and familiar.SpawnerEntity:ToPlayer())
	if (not player) then return end

	statusEffects:ApplyStatus(enemy, enums.StatusEffect.ELECTRIFIED, 90, player)
end

--- @param mod ModUpgraded
function Tesla_Coil:Init(mod)
	if (self.IsInitialized) then return end

	mod:AddCallback(ModCallbacks.MC_USE_ITEM, useItem, self.Target.Type)
	mod:AddCallback(ModCallbacks.MC_FAMILIAR_INIT, familiarInit_TeslaCoil, self.Target.Entity.Variant)
	mod:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, familiarUpdate_TeslaCoil, self.Target.Entity.Variant)
	mod:AddCallbackCustom(isc.ModCallbackCustom.POST_FAMILIAR_UPDATE_FILTER, familiarUpdate_Wisp, FamiliarVariant.WISP, self.Target.Type)
	mod:AddPriorityCallbackCustom(isc.ModCallbackCustom.PRE_FAMILIAR_COLLISION_FILTER, utils.CallbackPriority_VERY_LATE, preFamiliarCollision_TeslaCoilWisp, FamiliarVariant.WISP, self.Target.Type)
	mod:AddPriorityCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, utils.CallbackPriority_VERY_LATE, entityTakeDamage)

	--- remove "Tesla Coil" entities on entering a new room / run continue
	local removalFn = function ()
		for _, ent in ipairs(Isaac.GetRoomEntities()) do
			if ((ent.Type == EntityType.ENTITY_FAMILIAR) and (ent.Variant == self.Target.Entity.Variant)) then
				ent:Remove()
			end
		end
	end
	mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, removalFn)
	mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, removalFn)
	mod:AddCallbackCustom(isc.ModCallbackCustom.POST_GAME_STARTED_REORDERED_LAST, function ()
		sparkPreventer = false
	end)
	mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, function (_, shouldSave)
		if (not shouldSave) then return end
		sparkPreventer = true
	end)
end

return Tesla_Coil
