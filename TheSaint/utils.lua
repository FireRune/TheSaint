local utils = {}

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

return utils
