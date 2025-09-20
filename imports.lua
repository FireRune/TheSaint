local includes = {}

local items = {
    include("Items/Almanach"),
    include("Items/Mending_Heart")
}

function includes:Init(mod)
    for _, item in ipairs(items) do
        item:Init(mod)
    end
end

return includes
