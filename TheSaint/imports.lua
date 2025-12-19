--#region typedef

--- @diagnostic disable: undefined-doc-name

--- Base class for this mod's features
--- @class TheSaint.classes.ModFeature
--- @field protected Init fun(self: TheSaint.classes.ModFeature, mod: ModUpgraded) @ this function should only run once, so include this line at the top of the function body:<br>```if (self.IsInitialized) then return end```
--- @field protected IsInitialized boolean @ must be set to false when class is instantiated
--- @field protected SaveDataKey string? @ key to use for the `saveDataManager`-function
--- @field protected ThisMod ModUpgraded? @ Must be set in the `Init` function! Reference to this mod, because the 1st parameter in callbacks is of type `ModReference`

--- @generic T: CollectibleType | TrinketType | Card | PillEffect | PlayerType
--- @class TheSaint.classes.ModFeatureTargeted<T> : TheSaint.classes.ModFeature
--- @field protected Target TheSaint.structures.FeatureTarget<T>

--- @diagnostic enable: undefined-doc-name
--#endregion

--- @class TheSaint.imports : TheSaint.classes.ModFeature
local imports = {
	IsInitialized = false,
}

--[[
`TheSaint_Feature` and import functions (`include` vs. `require`):

If a feature should only be loaded once, import it with `include`.

If a feature will be imported/used in multiple files, use `require`.

Feature load order:
- `require` features
- `require` mod integration
- `include` features
- `include` mod integration
]]
--- @type TheSaint.classes.ModFeature[]
local features = {
	require("TheSaint.DevilDealTracking"),

	require("TheSaint.ModIntegration.MCM"),

	include("TheSaint.UnlockManager"),
	include("TheSaint.Characters.Characters"),
	include("TheSaint.Characters.The_Saint"),
	include("TheSaint.Characters.Tainted_Saint"),
	include("TheSaint.Items.Collectibles.Almanach"),
	include("TheSaint.Items.Collectibles.Mending_Heart"),
	include("TheSaint.Items.Collectibles.Devout_Prayer"),
	include("TheSaint.Items.Collectibles.Divine_Bombs"),
	include("TheSaint.Items.Collectibles.Wooden_Key"),
	include("TheSaint.Items.Collectibles.Holy_Hand_Grenade"),
	include("TheSaint.Items.Collectibles.Rite_of_Rebirth"),
	include("TheSaint.Items.Collectibles.Scorched_Baby"),
	include("TheSaint.Items.Trinkets.Holy_Penny"),
	include("TheSaint.Items.PocketItems.Library_Card"),
	include("TheSaint.Items.PocketItems.Soul_Saint"),

	include("TheSaint.ModIntegration.EIDRegistry"),
}

--- initialize all features of this mod
--- @param mod ModUpgraded
function imports:LoadFeatures(mod)
	if (self.IsInitialized) then return end

	for _, feature in ipairs(features) do
		feature:Init(mod)
		feature.IsInitialized = true
	end

	self.IsInitialized = true
end

return imports
