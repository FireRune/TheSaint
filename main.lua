-- Imports

local isc = require("TheSaint.lib.isaacscript-common")
local stats = include("TheSaint.stats")

-- Init

local TheSaintVanilla = RegisterMod(stats.ModName, 1)
local features = {
    isc.ISCFeature.SAVE_DATA_MANAGER,
    isc.ISCFeature.EXTRA_CONSOLE_COMMANDS,
}
local TheSaint = isc:upgradeMod(TheSaintVanilla, features)

-- Global for exposing certain functions as external API calls
TheSaintAPI = {}

--- Custom commands
local function thesaint_help()
    print("[The Saint] list of commands (all commands and their parameters are case-insensitive, unless stated otherwise):")
    print("[The Saint] - 'thesaint_help': shows this list")
    print("[The Saint] - 'thesaint_reloadbooks': reloads the cache of 'book'-items for 'Almanach'")
    print("[The Saint] - 'thesaint_marks': check progress for this mod's characters' completion marks")
end
TheSaint:addConsoleCommand("thesaint_help", thesaint_help)

-- feature initialization
local imports = include("TheSaint.imports")
if (type(imports) == "table") then
    --- @diagnostic disable-next-line
    imports:LoadFeatures(TheSaint)
end

print("[The Saint] Type 'thesaint_help' for a list of commands")
