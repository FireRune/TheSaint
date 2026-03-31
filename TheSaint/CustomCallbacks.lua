local isc = require("TheSaint.lib.isaacscript-common")
local enums = require("TheSaint.Enums")
local utils = include("TheSaint.utils")

--- @class TheSaint.CustomCallbacks : TheSaint.classes.ModFeature
local CustomCallbacks = {
	IsInitialized = false,
}

--- @param ent Entity
--- @param amount number	@ value is an integer when `ent` is `EntityPlayer`, otherwise it's a float
--- @param flags DamageFlag
--- @param source EntityRef
--- @param countdown integer
local function entityTakeDamage(_, ent, amount, flags, source, countdown)
	--- @type (EntityPlayer | EntityNPC)?
	local playerOrEnemy = ent:ToPlayer()
	if (not playerOrEnemy) then
		playerOrEnemy = ((utils:IsValidEnemy(ent, false) and ent:ToNPC()) or nil)
	end
	if (not playerOrEnemy) then return end

	local data = playerOrEnemy:GetData().TheSaint
	if (data) then
		data.DmgFrame = true
	else
		data = {
			DmgFrame = true,
		}
	end
	playerOrEnemy:GetData().TheSaint = data
end

--- @param entity Entity
--- @param laser EntityLaser
--- @return boolean
local function isCollidingWithLaser(entity, laser)
	local samples = laser:GetSamples()
	--- @type Vector?
	local sample

	for i = 0, (#samples - 1) do
		local nextSample = samples:Get(i)
		if (sample) then
			local topLeft = Vector(math.min(sample.X, nextSample.X) - laser.Size, math.min(sample.Y, nextSample.Y) - laser.Size)
			local bottomRight = Vector(math.max(sample.X, nextSample.X) + laser.Size, math.max(sample.Y, nextSample.Y) + laser.Size)
			if (isc:isCircleIntersectingRectangle(entity.Position, entity.Size, topLeft, bottomRight)) then
				return true
			end
		end
		sample = nextSample
	end

	return false
end

--- @param laser EntityLaser
local function postLaserUpdate(_, laser)
	local allEntities = Isaac.GetRoomEntities()
	--- @type Entity[]
	local collisions = {}

	for _, ent in ipairs(allEntities) do
		if (GetPtrHash(ent) ~= GetPtrHash(laser)) then
			--- @type (EntityPlayer | EntityNPC)?
			local collider = ent:ToPlayer()
			if (not collider) then
				collider = ent:ToNPC()
			end
			if ((collider) and (isCollidingWithLaser(ent, laser))) then
				-- for LASER_COLLISION and LASER_DAMAGE
				table.insert(collisions, ent)
			end
		end
	end

	-- run callbacks
	local callbacks_LASER_COLLISION = Isaac.GetCallbacks(enums.Callbacks.LASER_COLLISION)
	local callbacks_LASER_DAMAGE = Isaac.GetCallbacks(enums.Callbacks.LASER_DAMAGE)
	for _, collider in ipairs(collisions) do
		for _, callback in ipairs(callbacks_LASER_COLLISION) do
			if ((callback.Param == nil) or (callback.Param == -1) or (callback.Param == laser.Variant)) then
				callback.Function(callback.Mod, laser, collider)
			end
		end
		local entData = collider:GetData().TheSaint
		if ((entData) and (entData.DmgFrame)) then
			for _, callback in ipairs(callbacks_LASER_DAMAGE) do
				if ((callback.Param == nil) or (callback.Param == -1) or (callback.Param == laser.Variant)) then
					callback.Function(callback.Mod, laser, collider)
				end
			end
			entData.DmgFrame = false
		end
		collider:GetData().TheSaint = entData
	end
end

--- @param mod ModUpgraded
function CustomCallbacks:Init(mod)
	if (self.IsInitialized) then return end

	mod:AddPriorityCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, utils.CallbackPriority_LATER, entityTakeDamage)
	mod:AddPriorityCallback(ModCallbacks.MC_POST_LASER_UPDATE, CallbackPriority.IMPORTANT, postLaserUpdate)
end

return CustomCallbacks
