local enums = require("TheSaint.Enums")
local utils = include("TheSaint.utils")

local SEL = StatusEffectLibrary

--- Custom Status Effects
--- @class TheSaint.StatusEffects : TheSaint.classes.ModFeature
local StatusEffects = {
	IsInitialized = false,
}

local OFFSET = (40 / 255)

--#region Electrified

local SPARK_DISTANCE = 100.0

--- "Electrified"
--- - every 10 frames shocks the afflicted enemy dealing 25% of Isaac's damage
--- - spark will jump to nearby enemies
local function Status_Electrified()
	local identifier = enums.StatusEffect.ELECTRIFIED
	local icon = nil
	local color = Color(1.2, 1.2, 0.5, 1, OFFSET, OFFSET, OFFSET)
	SEL.RegisterStatusEffect(identifier, icon, color)
end

--- @param ent EntityPlayer | EntityNPC
--- @param effect StatusFlag
--- @param customData table
local function preAddEffect_Electrified(_, ent, effect, customData)
	local effectData = SEL:GetStatusEffectData(ent, effect)
	if (not effectData) then return end
	effectData.Countdown = (effectData.Countdown + customData.Countdown)
end

--- @param ent EntityPlayer | EntityNPC
--- @param effect StatusFlag
--- @param effectData StatusEffectData
local function postAddEffect_Electrified(_, ent, effect, effectData)
	if (effectData.Countdown > 150) then
		effectData.Countdown = 150
	end
end

--- @param entity EntityPlayer | EntityNPC
local function statusEffectUpdate_Electrified(_, entity)
	local data = SEL:GetStatusEffectData(entity, SEL.StatusFlag.SAINT_ELECTRIFIED)
	if (not data) then return end

	-- only spawn a spark every 10 frames
	if (data.Countdown % 10 ~= 0) then return end

	local player = data.Source.Entity:ToPlayer()
	if (not player) then return end

	--- @type Entity[]
	local targets = {}
	local entities = Isaac.FindInRadius(entity.Position, (entity.Size + SPARK_DISTANCE), EntityPartition.ENEMY)
	for _, ent in ipairs(entities) do
		if (utils:IsValidEnemy(ent, false) and (GetPtrHash(ent) ~= GetPtrHash(entity))) then
			table.insert(targets, ent)
		end
	end

	--- @type Vector, number
	local sparkDir, sparkLength

	local iMax = #targets
	local iStart = (((iMax > 0) and 1) or 0)
	for i = iStart, iMax do
		if (i == 0) then
			sparkDir = RandomVector()
			sparkLength = (entity.Size + (SPARK_DISTANCE / 2))
		else
			local enemy = targets[i]
			sparkDir = (enemy.Position - entity.Position)
			sparkLength = sparkDir:Length()
		end
		local spark = EntityLaser.ShootAngle(LaserVariant.ELECTRIC, entity.Position, sparkDir:GetAngleDegrees(), 1, Vector.Zero, player)
		spark:SetOneHit(true)
		spark:SetMaxDistance(sparkLength)
		spark.CollisionDamage = (player.Damage * 0.25)
	end
end

--#endregion

--- @param mod ModUpgraded
function StatusEffects:Init(mod)
	if (self.IsInitialized) then return end

	Status_Electrified()
	SEL.Callbacks.AddCallback(SEL.Callbacks.ID.PRE_ADD_ENTITY_STATUS_EFFECT, preAddEffect_Electrified, SEL.StatusFlag.SAINT_ELECTRIFIED)
	SEL.Callbacks.AddCallback(SEL.Callbacks.ID.POST_ADD_ENTITY_STATUS_EFFECT, postAddEffect_Electrified, SEL.StatusFlag.SAINT_ELECTRIFIED)
	SEL.Callbacks.AddCallback(SEL.Callbacks.ID.ENTITY_STATUS_EFFECT_UPDATE, statusEffectUpdate_Electrified, SEL.StatusFlag.SAINT_ELECTRIFIED)
end

--- @param target EntityPlayer | EntityNPC
--- @param status TheSaint.Enums.StatusEffect
--- @param duration integer	@ in frames (1 second = 30 frames)
--- @param source? Entity
--- @param color? Color
--- @param customData? table
function StatusEffects:ApplyStatus(target, status, duration, source, color, customData)
	local statusFlag = SEL.StatusFlag[status]
	local ref = EntityRef(source)
	if (customData) then
		customData.Countdown = duration
	else
		customData = {
			Countdown = duration,
		}
	end
	SEL:AddStatusEffect(target, statusFlag, duration, ref, color, customData)
end

return StatusEffects
