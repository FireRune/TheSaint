-- Imports

local isc = require("TheSaint.lib.isaacscript-common")
local stats = include("TheSaint.stats")
include("TheSaint.EIDRegistry")

-- Init

local TheSaintVanilla = RegisterMod(stats.ModName, 1)
local features = {
    isc.ISCFeature.SAVE_DATA_MANAGER
}
local TheSaint = isc:upgradeMod(TheSaintVanilla, features)

--- Custom commands
--- @param cmd string
function TheSaint:executeCmd(cmd)
    cmd = string.lower(cmd)
    if cmd == "saint_help" then
        print("'The Saint' commands:")
        print("'saint_help': shows this list")
        print("'saint_reloadbooks': reloads the cache of 'book'-items for 'Almanach'")
        print("'saint_marks': check progress for The Saint's completion marks")
        print("'saint_marksb': check progress for Tainted Saint's completion marks")
    end
end
TheSaint:AddCallback(ModCallbacks.MC_EXECUTE_CMD, TheSaint.executeCmd)

-- feature initialization
local imports = include("TheSaint.imports")
if (type(imports) == "table") then
    imports:Init(TheSaint)
end

print("[The Saint] Type 'saint_help' for a list of commands")
