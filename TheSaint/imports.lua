local imports = {}

local features = {
    include("TheSaint/Characters/Tainted_Saint"),
    include("TheSaint/Items/Almanach"),
    include("TheSaint/Items/Mending_Heart"),
    include("TheSaint/Items/Devout_Prayer")
}

--- initialize all features of this mod
--- @param mod ModReference
function imports:Init(mod)
    for _, feature in ipairs(features) do
        feature:Init(mod)
    end
end

return imports
