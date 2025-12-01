local isc = require("TheSaint.lib.isaacscript-common")

--- @class TheSaint.ModIntegration.MCM : TheSaint_Feature
local MCM = {
	IsInitialized = false,
	SaveDataKey = "MCM",
}

local v = {
	persistent = {
		UnlockAll = false,
	},
}

local MOD_NAME = "The Saint"
local MOD_VERSION = "dev-1.0"
local MOD_CREATOR = "FireRune"

local isLoaded = false
local function modConfigMenu_Init()
	if ((not ModConfigMenu) or (isLoaded)) then return end

	ModConfigMenu.AddSpace(MOD_NAME, "Info")
	ModConfigMenu.AddText(MOD_NAME, "Info", function() return MOD_NAME end)
	ModConfigMenu.AddSpace(MOD_NAME, "Info")
	ModConfigMenu.AddText(MOD_NAME, "Info", function() return "Version " .. MOD_VERSION end)
	ModConfigMenu.AddSpace(MOD_NAME, "Info")
	ModConfigMenu.AddText(MOD_NAME, "Info", function() return "by " .. MOD_CREATOR end)

	local everythingUnlockedSetting = {
		Type = ModConfigMenu.OptionType.BOOLEAN,
		Attribute = "UnlockAll",
		Display = function ()
			local settingValue = ((v.persistent.UnlockAll and "True") or "False")
			return "Grant all unlocks: "..settingValue
		end,
		Default = false,
		CurrentSetting = function ()
			return v.persistent.UnlockAll
		end,
		--- @param currentValue boolean
		OnChange = function (currentValue)
			v.persistent.UnlockAll = currentValue
		end,
	}
	ModConfigMenu.AddSetting(MOD_NAME, "Settings", everythingUnlockedSetting)

	isLoaded = true
end

--- @param mod ModUpgraded
function MCM:Init(mod)
	if (self.IsInitialized) then return end

	mod:saveDataManager(self.SaveDataKey, v)
	mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function ()
		modConfigMenu_Init()
	end)
end

function MCM:getSetting(setting)
	return v.persistent[setting]
end

return MCM
