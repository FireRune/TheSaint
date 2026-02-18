local isc = require("TheSaint.lib.isaacscript-common")

local utils = {}

local RECOMMENDED_SHIFT_IDX = 35

--- Helper function to add a callback for multiple targets (i.e. the 3rd argument of `ModReference:AddCallback`)<br>
--- Example:
--- ```
--- local function evaluateStats(_, player, flag)
--- end
--- 
--- -- this
--- utils:AddTargetedCallback(mod, ModCallbacks.MC_EVALUATE_CACHE, evaluateStats, {CacheFlag.CACHE_DAMAGE, CacheFlag.CACHE_FIREDELAY})
--- -- boils down to this
--- mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, evaluateStats, CacheFlag.CACHE_DAMAGE)
--- mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, evaluateStats, CacheFlag.CACHE_FIREDELAY)
--- ```
--- @param mod ModReference
--- @param callbackId ModCallbacks
--- @param callbackFn function
--- @param targets any[]
function utils:AddTargetedCallback(mod, callbackId, callbackFn, targets)
	for _, target in ipairs(targets) do
		mod:AddCallback(callbackId, callbackFn, target)
	end
end

--- Debug utility for identifying entities in the form of "Type.Variant.SubType"
--- @param entity Entity
--- @return string
function utils:GetTVSString(entity)
	return tostring(entity.Type or 0).."."..tostring(entity.Variant or 0).."."..tostring(entity.SubType or 0)
end

--- @param initSeed integer
--- @return RNG
function utils:CreateNewRNG(initSeed)
	if (initSeed <= 0) then
		initSeed = 2853650767
	end
	local rng = RNG()
	rng:SetSeed(initSeed, RECOMMENDED_SHIFT_IDX)
	return rng
end

--- If `player` has "Alabaster Box" and it's not fully charged, return `true`; otherwise `false`
--- @param player EntityPlayer
--- @return boolean
function utils:AlabasterBoxNeedsCharge(player)
	local slots = isc:getActiveItemSlots(player, CollectibleType.COLLECTIBLE_ALABASTER_BOX)
	if (#slots > 0) then
		local isFull = true
		for _, slot in ipairs(slots) do
			if (player:GetActiveCharge(slot) < 12) then
				isFull = false
			end
		end
		if (not isFull) then
			return true
		end
	end
	return false
end

return utils
