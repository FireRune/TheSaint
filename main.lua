local imports = include("imports")
include("EIDRegistry")

-- Init
local modSaint = RegisterMod("The Saint", 1)

if (type(imports) == "table") then
    imports:Init(modSaint)
end
