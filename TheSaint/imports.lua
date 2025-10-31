local imports = {}

local features = {
    include("TheSaint.Characters.Characters"),
    include("TheSaint.Characters.The_Saint"),
    include("TheSaint.Characters.Tainted_Saint"),
    include("TheSaint.Items.Collectibles.Almanach"),
    include("TheSaint.Items.Collectibles.Mending_Heart"),
    include("TheSaint.Items.Collectibles.Devout_Prayer"),
    include("TheSaint.Items.Collectibles.Divine_Bombs"),
    include("TheSaint.Items.Trinkets.Holy_Penny"),
    include("TheSaint.Items.Collectibles.Wooden_Key"),
    include("TheSaint.Items.PocketItems.Library_Card"),
    include("TheSaint.Items.PocketItems.Soul_Saint"),
}

--- initialize all features of this mod
--- @param mod ModReference
function imports:Init(mod)
    for _, feature in ipairs(features) do
        feature:Init(mod)
    end
end

return imports
