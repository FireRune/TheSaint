local isc = require("TheSaint.lib.isaacscript-common")
local enums = require("TheSaint.Enums")
local featureTarget = require("TheSaint.structures.FeatureTarget")

--- Using an active item has a 33/66/100% chance to trigger the effect of a random `book`-item
--- @class TheSaint.Items.Trinkets.Scattered_Pages : TheSaint.classes.ModFeatureTargeted<TrinketType>
local Scattered_Pages = {
	IsInitialized = false,
	--- @type TheSaint.structures.FeatureTarget<TrinketType>
	Target = featureTarget:new(enums.TrinketType.TRINKET_SCATTERED_PAGES),
	SaveDataKey = "Scattered_Pages",
}

local v = {
	room = {
		-- trigger effect only once per room
		EffectTriggered = false,
	},
}

-- needed to stop the infinite loop caused by using `EntityPlayer:UseActiveItem` in a `MC_USE_ITEM` callback without any restrictions
local effectIsRunning = false

--- @param collectible CollectibleType
--- @param rng RNG
--- @param player EntityPlayer
--- @param flags UseFlag
local function useItem(_, collectible, rng, player, flags)
	-- possible values: 0, 1, 2, 3
	local trinketMult = math.min(3, player:GetTrinketMultiplier(Scattered_Pages.Target.Type))
	if ((v.room.EffectTriggered == false) and (effectIsRunning == false) and (trinketMult > 0)) then
		effectIsRunning = true

		-- at this point `trinketMult` can only have 1, 2 or 3 as its value
		local chance = (trinketMult / 3)

		local effectTriggers = (rng:RandomFloat() < chance)
		if (effectTriggers == true) then
			v.room.EffectTriggered = true
			local useFromCarBattery = false
			if (flags & UseFlag.USE_CARBATTERY == UseFlag.USE_CARBATTERY) then
				useFromCarBattery = true
			end

			local newFlags = (UseFlag.USE_NOANIM | UseFlag.USE_CUSTOMVARDATA)
			if (useFromCarBattery == true) then
				newFlags = (newFlags | UseFlag.USE_CARBATTERY)
			end
			--- @cast newFlags UseFlag

			--- necessary until the `Binding of Isaac Lua API` VSCode extension adds the `customVarData` parameter to this function
			--- @diagnostic disable-next-line: param-type-mismatch
			player:UseActiveItem(enums.CollectibleType.COLLECTIBLE_ALMANACH, newFlags, -1, enums.CustomVarData.Almanach.SCATTERED_PAGES)
		end

		effectIsRunning = false
	end
end

--- @param mod ModUpgraded
function Scattered_Pages:Init(mod)
	if (self.IsInitialized) then return end

	mod:saveDataManager(self.SaveDataKey, v)
	mod:AddPriorityCallback(ModCallbacks.MC_USE_ITEM, CallbackPriority.EARLY, useItem)
end

return Scattered_Pages
