local enums = require("TheSaint.Enums")

--- @class TheSaint.ModIntegration.MCM : TheSaint.classes.ModFeature
local MCM = {
	IsInitialized = false,
	SaveDataKey = "MCM",
}

local v = {
	persistent = {
		[enums.Setting.UNLOCK_ALL] = false,
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

	local settingName = ""

	-- setting "UnlockAll"
	settingName = enums.Setting.UNLOCK_ALL
	local everythingUnlockedSetting = {
		Type = ModConfigMenu.OptionType.BOOLEAN,
		Attribute = settingName,
		Display = function ()
			local settingValue = ((v.persistent[settingName] and "True") or "False")
			return "Grant all unlocks: "..settingValue
		end,
		Default = false,
		CurrentSetting = function ()
			return v.persistent[settingName]
		end,
		--- @param currentValue boolean
		OnChange = function (currentValue)
			v.persistent[settingName] = currentValue
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

--- @param setting TheSaint.Enums.Setting
--- @return any
function MCM:getSetting(setting)
	return v.persistent[setting]
end

return MCM
