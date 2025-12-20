local isc = require("TheSaint.lib.isaacscript-common")
local enums = require("TheSaint.Enums")
local featureTarget = require("TheSaint.structures.FeatureTarget")

--- Using an active item has a 15/25/33% chance to trigger the effect of "Almanach"
--- @class TheSaint.Items.Trinkets.Scattered_Pages : TheSaint.classes.ModFeatureTargeted
local Scattered_Pages = {
	IsInitialized = false,
	Target = featureTarget:new(enums.TrinketType.TRINKET_SCATTERED_PAGES),
}

local loopPreventer = true

--- @param collectible CollectibleType
--- @param rng RNG
--- @param player EntityPlayer
--- @param flags UseFlag
local function useItem(_, collectible, rng, player, flags)
	local trinketMult = math.min(3, player:GetTrinketMultiplier(Scattered_Pages.Target.Type))
	if ((loopPreventer == true) and (trinketMult > 0)) then
		loopPreventer = false

		-- at this point `trinketMult` can only have 1, 2 or 3 as its value
		local chance = (((trinketMult == 3) and 33) or ((trinketMult == 2) and 25) or 15)

		local effectTriggers = (rng:RandomInt(100) < chance)
		if (effectTriggers == true) then
			local useFromCarBattery = false
			if (flags & UseFlag.USE_CARBATTERY == UseFlag.USE_CARBATTERY) then
				useFromCarBattery = true
			end

			local newFlags = (UseFlag.USE_NOANIM | UseFlag.USE_CUSTOMVARDATA)
			if (useFromCarBattery == true) then
				newFlags = (newFlags | UseFlag.USE_CARBATTERY)
			end
			--- @cast newFlags UseFlag
			--- @diagnostic disable-next-line: param-type-mismatch
			player:UseActiveItem(enums.CollectibleType.COLLECTIBLE_ALMANACH, newFlags, -1, enums.CustomVarData_Almanach.SCATTERED_PAGES)
		end

		loopPreventer = true
	end
end

--- @param mod ModUpgraded
function Scattered_Pages:Init(mod)
	if (self.IsInitialized) then return end

	mod:AddCallback(ModCallbacks.MC_USE_ITEM, useItem)
end

return Scattered_Pages
