--- Base class for this mod's features
--- @class TheSaint_Feature
--- @field protected Init fun(self: TheSaint_Feature, mod: ModReference) @ this function should only run once, so include this line at the top of the function body:<br>```if (self.IsInitialized) then return end```
--- @field protected IsInitialized boolean @ must be set to false when class is instantiated
--- @field protected FeatureSubType integer? @ the SubType this feature is for
--- @field protected SaveDataKey string? @ key to use for the `saveDataManager`-function
--- @field private CurrentFeature TheSaint_Feature?
local TheSaint_Feature = {
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
--- @type TheSaint_Feature[]
local features = {
    require("TheSaint.DevilDealTracking"),

    include("TheSaint.Unlocks"),
    include("TheSaint.Characters.Characters"),
    include("TheSaint.Characters.The_Saint"),
    include("TheSaint.Characters.Tainted_Saint"),
    include("TheSaint.Items.Collectibles.Almanach"),
    include("TheSaint.Items.Collectibles.Mending_Heart"),
    include("TheSaint.Items.Collectibles.Devout_Prayer"),
    include("TheSaint.Items.Collectibles.Divine_Bombs"),
    include("TheSaint.Items.Collectibles.Wooden_Key"),
    include("TheSaint.Items.Collectibles.Holy_Hand_Grenade"),
    include("TheSaint.Items.Trinkets.Holy_Penny"),
    include("TheSaint.Items.PocketItems.Library_Card"),
    include("TheSaint.Items.PocketItems.Soul_Saint"),

    include("TheSaint.ModIntegration.EIDRegistry"),
}

--- @private
--- initialize all features of this mod
--- @param mod ModReference
function TheSaint_Feature:LoadFeatures(mod)
    if (self.IsInitialized) then return end

    for _, feature in ipairs(features) do
        self.CurrentFeature = feature
        self.CurrentFeature:Init(mod)
        if (self.CurrentFeature.IsInitialized == false) then
            self.CurrentFeature.IsInitialized = true
        end
    end
    self.CurrentFeature = nil
end

return TheSaint_Feature
