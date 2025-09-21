local includes = {}

local items = {
    include("Items/Almanach"),
    include("Items/Mending_Heart")
}

--- initialize all items of this mod
--- @param mod ModReference
function includes:Init(mod)
    for _, item in ipairs(items) do
        item:Init(mod)
    end
end

return includes
