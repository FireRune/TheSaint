local includes = {}

local items = {
    include("TheSaint/Items/Almanach"),
    include("TheSaint/Items/Mending_Heart"),
    include("TheSaint/Items/Devout_Prayer")
}

--- initialize all items of this mod
--- @param mod ModReference
function includes:Init(mod)
    for _, item in ipairs(items) do
        item:Init(mod)
    end
end

return includes
