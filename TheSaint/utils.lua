local isc = require("TheSaint.lib.isaacscript-common")

local utils = {}

--#region extra and unnamed vanilla enum members

local CallbackPriority_LATER = 199		--- @cast CallbackPriority_LATER CallbackPriority
local CallbackPriority_VERY_LATE = 200	--- @cast CallbackPriority_VERY_LATE CallbackPriority

--- 199
utils.CallbackPriority_LATER = CallbackPriority_LATER
--- 200
utils.CallbackPriority_VERY_LATE = CallbackPriority_VERY_LATE

local ChestSubType_CHEST_CLOSED_ETERNAL = 2	--- @cast ChestSubType_CHEST_CLOSED_ETERNAL ChestSubType
--- SubType of a fresh, unopened Eternal Chest is 2. After it closes itself again it's SubType changes to 1 (CHEST_CLOSED)
utils.ChestSubType_CHEST_CLOSED_ETERNAL = ChestSubType_CHEST_CLOSED_ETERNAL

--#endregion

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
--- @param callbackId ModCallbacks | string
--- @param callbackFn function
--- @param targets any[]
function utils:AddTargetedCallback(mod, callbackId, callbackFn, targets)
	for _, target in ipairs(targets) do
		mod:AddCallback(callbackId, callbackFn, target)
	end
end

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
--- @param callbackId ModCallbacks | string
--- @param callbackPrio CallbackPriority
--- @param callbackFn function
--- @param targets any[]
function utils:AddTargetedPriorityCallback(mod, callbackId, callbackPrio, callbackFn, targets)
	for _, target in ipairs(targets) do
		mod:AddPriorityCallback(callbackId, callbackPrio, callbackFn, target)
	end
end

--- Debug utility for identifying entities in the form of "Type.Variant.SubType"
--- @param entity Entity
--- @return string
function utils:GetTVSString(entity)
	return tostring(entity.Type or 0).."."..tostring(entity.Variant or 0).."."..tostring(entity.SubType or 0)
end

--- @param seed integer
--- @return integer
local function fixSeed(seed)
	if (seed <= 0) then
		seed = 2853650767
	end
	return seed
end

--- @param shiftIdx? integer
--- @return integer
local function fixShiftIdx(shiftIdx)
	if ((not shiftIdx) or (shiftIdx < 0) or (shiftIdx > 80)) then
		shiftIdx = RECOMMENDED_SHIFT_IDX
	end
	return shiftIdx
end

--- like `RNG:SetSeed`, but shiftIdx is optional
--- @param rng RNG
--- @param initSeed integer
--- @param shiftIdx? integer	@ value must be between 0 and 80 (both inclusive), default: `35`
function utils:RNGSetSeed(rng, initSeed, shiftIdx)
	local seed = fixSeed(initSeed)
	rng:SetSeed(seed, fixShiftIdx(shiftIdx))
end

--- @param initSeed integer
--- @param shiftIdx? integer	@ value must be between 0 and 80 (both inclusive), default: `35`
--- @return RNG
function utils:CreateNewRNG(initSeed, shiftIdx)
	local rng = RNG()
	self:RNGSetSeed(rng, initSeed, shiftIdx)
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

--- like tostring(), but encloses string values in single quotation marks
--- @param val any
--- @return string
function utils:Stringify(val)
	local str
	if (type(val) == "string") then
		str = "'"..val.."'"
	else
		str = tostring(val)
	end
	return str
end

--- Same as `print`, but automatically uses the string "[The Saint]" as its first argument.
--- @param ... any
function utils:PrintWithHeader(...)
	print("[The Saint]", ...)
end

--- Same as `Isaac.DebugString`, but automatically prepends `str` with "[The Saint] ".
--- @param str string
function utils:DebugStringWithHeader(str)
	Isaac.DebugString("[The Saint] "..str)
end

--- Prints the string `str` both to the Debug Console and to the Log file.
--- @param str string
function utils:PrintAndLog(str)
	print(str)
	Isaac.DebugString(str)
end

--- Prints the string `str` both to the Debug Console and to the Log file. Automatically prepends `str` with "[The Saint] ".
--- @param str string
function utils:PrintAndLogWithHeader(str)
	local msg = "[The Saint] "..str
	print(msg)
	Isaac.DebugString(msg)
end

--- Returns whether the given entity should be damaged from "Protective Candle"<br>
--- Also used for the "Electrified" status to determine valid targets for the sparks
--- @param enemy Entity
--- @param includeTNT? boolean @ default: `true`
--- @return boolean
function utils:IsValidEnemy(enemy, includeTNT)
	if (includeTNT == nil) then includeTNT = true end

	local isActiveEnemy = (enemy:IsActiveEnemy() == true)
	local isNotFriendly = (enemy:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) == false)
	local isTNT = (includeTNT and (enemy.Type == EntityType.ENTITY_MOVABLE_TNT))
	return ((isActiveEnemy and isNotFriendly) or isTNT)
end

--- Helper for manipulating the Range stat
--- @param rangeStat number	@ value as it is displayed in the extra HUD
--- @return number			@ actual value to use in `MC_EVALUATE_CACHE`
function utils:RangeStatToValue(rangeStat)
	return (rangeStat * 40)
end

return utils
