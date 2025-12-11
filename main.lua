-- Imports

local isc = require("TheSaint.lib.isaacscript-common")
local stats = include("TheSaint.stats")

--- Obtained by using the `upgradeMod` function
--- @class ModUpgraded : ModReference
--- @field AddCallbackCustom function
--- @field AddPriorityCallbackCustom function
--- @field RemoveCallbackCustom function
--- @field logUsedFeatures function
--- @field registerCharacterHealthConversion function @ must upgrade mod with `ISCFeature.CHARACTER_HEALTH_CONVERSION`
--- @field registerCharacterStats function @ must upgrade mod with `ISCFeature.CHARACTER_STATS`
--- @field getCollectibleItemPoolType function @ must upgrade mod with `ISCFeature.COLLECTIBLE_ITEM_POOL_TYPE`
--- @field setConditionalHotkey function @ must upgrade mod with `ISCFeature.CUSTOM_HOTKEYS`
--- @field setHotkey function @ must upgrade mod with `ISCFeature.CUSTOM_HOTKEYS`
--- @field unsetConditionalHotkey function @ must upgrade mod with `ISCFeature.CUSTOM_HOTKEYS`
--- @field unsetHotkey function @ must upgrade mod with `ISCFeature.CUSTOM_HOTKEYS`
--- @field registerCustomItemPool function @ must upgrade mod with `ISCFeature.CUSTOM_ITEM_POOLS`
--- @field getCustomItemPoolCollectible function @ must upgrade mod with `ISCFeature.CUSTOM_ITEM_POOLS`
--- @field registerCustomPickup function @ must upgrade mod with `ISCFeature.CUSTOM_PICKUPS`
--- @field setCustomStage function @ must upgrade mod with `ISCFeature.CUSTOM_STAGES`
--- @field disableCustomStage function @ must upgrade mod with `ISCFeature.CUSTOM_STAGES`
--- @field registerCustomTrapdoorDestination function @ must upgrade mod with `ISCFeature.CUSTOM_TRAPDOORS`
--- @field spawnCustomTrapdoor function @ must upgrade mod with `ISCFeature.CUSTOM_TRAPDOORS`
--- @field setPlayerDisplay function @ must upgrade mod with `ISCFeature.DEBUG_DISPLAY`
--- @field setTearDisplay function @ must upgrade mod with `ISCFeature.DEBUG_DISPLAY`
--- @field setFamiliarDisplay function @ must upgrade mod with `ISCFeature.DEBUG_DISPLAY`
--- @field setBombDisplay function @ must upgrade mod with `ISCFeature.DEBUG_DISPLAY`
--- @field setPickupDisplay function @ must upgrade mod with `ISCFeature.DEBUG_DISPLAY`
--- @field setSlotDisplay function @ must upgrade mod with `ISCFeature.DEBUG_DISPLAY`
--- @field setLaserDisplay function @ must upgrade mod with `ISCFeature.DEBUG_DISPLAY`
--- @field setKnifeDisplay function @ must upgrade mod with `ISCFeature.DEBUG_DISPLAY`
--- @field setProjectileDisplay function @ must upgrade mod with `ISCFeature.DEBUG_DISPLAY`
--- @field setEffectDisplay function @ must upgrade mod with `ISCFeature.DEBUG_DISPLAY`
--- @field setNPCDisplay function @ must upgrade mod with `ISCFeature.DEBUG_DISPLAY`
--- @field setRockDisplay function @ must upgrade mod with `ISCFeature.DEBUG_DISPLAY`
--- @field setPitDisplay function @ must upgrade mod with `ISCFeature.DEBUG_DISPLAY`
--- @field setSpikesDisplay function @ must upgrade mod with `ISCFeature.DEBUG_DISPLAY`
--- @field setTNTDisplay function @ must upgrade mod with `ISCFeature.DEBUG_DISPLAY`
--- @field setPoopDisplay function @ must upgrade mod with `ISCFeature.DEBUG_DISPLAY`
--- @field setDoorDisplay function @ must upgrade mod with `ISCFeature.DEBUG_DISPLAY`
--- @field setPressurePlateDisplay function @ must upgrade mod with `ISCFeature.DEBUG_DISPLAY`
--- @field togglePlayerDisplay function @ must upgrade mod with `ISCFeature.DEBUG_DISPLAY`
--- @field toggleTearDisplay function @ must upgrade mod with `ISCFeature.DEBUG_DISPLAY`
--- @field toggleFamiliarDisplay function @ must upgrade mod with `ISCFeature.DEBUG_DISPLAY`
--- @field toggleBombDisplay function @ must upgrade mod with `ISCFeature.DEBUG_DISPLAY`
--- @field togglePickupDisplay function @ must upgrade mod with `ISCFeature.DEBUG_DISPLAY`
--- @field toggleSlotDisplay function @ must upgrade mod with `ISCFeature.DEBUG_DISPLAY`
--- @field toggleLaserDisplay function @ must upgrade mod with `ISCFeature.DEBUG_DISPLAY`
--- @field toggleKnifeDisplay function @ must upgrade mod with `ISCFeature.DEBUG_DISPLAY`
--- @field toggleProjectileDisplay function @ must upgrade mod with `ISCFeature.DEBUG_DISPLAY`
--- @field toggleEffectDisplay function @ must upgrade mod with `ISCFeature.DEBUG_DISPLAY`
--- @field toggleNPCDisplay function @ must upgrade mod with `ISCFeature.DEBUG_DISPLAY`
--- @field toggleRockDisplay function @ must upgrade mod with `ISCFeature.DEBUG_DISPLAY`
--- @field togglePitDisplay function @ must upgrade mod with `ISCFeature.DEBUG_DISPLAY`
--- @field toggleSpikesDisplay function @ must upgrade mod with `ISCFeature.DEBUG_DISPLAY`
--- @field toggleTNTDisplay function @ must upgrade mod with `ISCFeature.DEBUG_DISPLAY`
--- @field togglePoopDisplay function @ must upgrade mod with `ISCFeature.DEBUG_DISPLAY`
--- @field toggleDoorDisplay function @ must upgrade mod with `ISCFeature.DEBUG_DISPLAY`
--- @field togglePressurePlateDisplay function @ must upgrade mod with `ISCFeature.DEBUG_DISPLAY`
--- @field deployJSONRoom function @ must upgrade mod with `ISCFeature.DEPLOY_JSON_ROOM`
--- @field enableAllSound function @ must upgrade mod with `ISCFeature.DISABLE_ALL_SOUND`
--- @field disableAllSound function @ must upgrade mod with `ISCFeature.DISABLE_ALL_SOUND`
--- @field areInputsEnabled function @ must upgrade mod with `ISCFeature.DISABLE_INPUTS`
--- @field enableAllInputs function @ must upgrade mod with `ISCFeature.DISABLE_INPUTS`
--- @field disableInputs function @ must upgrade mod with `ISCFeature.DISABLE_INPUTS`
--- @field disableAllInputs function @ must upgrade mod with `ISCFeature.DISABLE_INPUTS`
--- @field enableAllInputsExceptFor function @ must upgrade mod with `ISCFeature.DISABLE_INPUTS`
--- @field disableAllInputsExceptFor function @ must upgrade mod with `ISCFeature.DISABLE_INPUTS`
--- @field disableMovementInputs function @ must upgrade mod with `ISCFeature.DISABLE_INPUTS`
--- @field disableShootingInputs function @ must upgrade mod with `ISCFeature.DISABLE_INPUTS`
--- @field getEdenStartingActiveCollectible function @ must upgrade mod with `ISCFeature.EDEN_STARTING_STATS`
--- @field getEdenStartingCollectibles function @ must upgrade mod with `ISCFeature.EDEN_STARTING_STATS`
--- @field getEdenStartingHealth function @ must upgrade mod with `ISCFeature.EDEN_STARTING_STATS`
--- @field getEdenStartingPassiveCollectible function @ must upgrade mod with `ISCFeature.EDEN_STARTING_STATS`
--- @field getEdenStartingStat function @ must upgrade mod with `ISCFeature.EDEN_STARTING_STATS`
--- @field getEdenStartingStats function @ must upgrade mod with `ISCFeature.EDEN_STARTING_STATS`
--- @field addConsoleCommand function @ must upgrade mod with `ISCFeature.EXTRA_CONSOLE_COMMANDS`
--- @field removeConsoleCommand function @ must upgrade mod with `ISCFeature.EXTRA_CONSOLE_COMMANDS`
--- @field removeAllConsoleCommands function @ must upgrade mod with `ISCFeature.EXTRA_CONSOLE_COMMANDS`
--- @field removeFadeIn function @ must upgrade mod with `ISCFeature.FADE_IN_REMOVER`
--- @field restoreFadeIn function @ must upgrade mod with `ISCFeature.FADE_IN_REMOVER`
--- @field enableFastReset function @ must upgrade mod with `ISCFeature.FAST_RESET`
--- @field disableFastReset function @ must upgrade mod with `ISCFeature.FAST_RESET`
--- @field hasFlyingTemporaryEffect function @ must upgrade mod with `ISCFeature.FLYING_DETECTION`
--- @field forgottenSwitch function @ must upgrade mod with `ISCFeature.FORGOTTEN_SWITCH`
--- @field getCollectiblesInItemPool function @ must upgrade mod with `ISCFeature.ITEM_POOL_DETECTION`
--- @field isCollectibleInItemPool function @ must upgrade mod with `ISCFeature.ITEM_POOL_DETECTION`
--- @field isCollectibleUnlocked function @ must upgrade mod with `ISCFeature.ITEM_POOL_DETECTION`
--- @field getFirstModdedCollectibleType function @ must upgrade mod with `ISCFeature.MODDED_ELEMENT_DETECTION`
--- @field getLastCollectibleType function @ must upgrade mod with `ISCFeature.MODDED_ELEMENT_DETECTION`
--- @field getNumCollectibleTypes function @ must upgrade mod with `ISCFeature.MODDED_ELEMENT_DETECTION`
--- @field getNumModdedCollectibleTypes function @ must upgrade mod with `ISCFeature.MODDED_ELEMENT_DETECTION`
--- @field getFirstModdedTrinketType function @ must upgrade mod with `ISCFeature.MODDED_ELEMENT_DETECTION`
--- @field getLastTrinketType function @ must upgrade mod with `ISCFeature.MODDED_ELEMENT_DETECTION`
--- @field getNumTrinketTypes function @ must upgrade mod with `ISCFeature.MODDED_ELEMENT_DETECTION`
--- @field getNumModdedTrinketTypes function @ must upgrade mod with `ISCFeature.MODDED_ELEMENT_DETECTION`
--- @field getFirstModdedCardType function @ must upgrade mod with `ISCFeature.MODDED_ELEMENT_DETECTION`
--- @field getLastCardType function @ must upgrade mod with `ISCFeature.MODDED_ELEMENT_DETECTION`
--- @field getNumCardTypes function @ must upgrade mod with `ISCFeature.MODDED_ELEMENT_DETECTION`
--- @field getNumModdedCardTypes function @ must upgrade mod with `ISCFeature.MODDED_ELEMENT_DETECTION`
--- @field getFirstModdedPillEffect function @ must upgrade mod with `ISCFeature.MODDED_ELEMENT_DETECTION`
--- @field getLastPillEffect function @ must upgrade mod with `ISCFeature.MODDED_ELEMENT_DETECTION`
--- @field getNumPillEffects function @ must upgrade mod with `ISCFeature.MODDED_ELEMENT_DETECTION`
--- @field getNumModdedPillEffects function @ must upgrade mod with `ISCFeature.MODDED_ELEMENT_DETECTION`
--- @field getCollectibleTypes function @ must upgrade mod with `ISCFeature.MODDED_ELEMENT_SETS`
--- @field getCollectibleTypeSet function @ must upgrade mod with `ISCFeature.MODDED_ELEMENT_SETS`
--- @field getModdedCollectibleTypes function @ must upgrade mod with `ISCFeature.MODDED_ELEMENT_SETS`
--- @field getModdedCollectibleTypesSet function @ must upgrade mod with `ISCFeature.MODDED_ELEMENT_SETS`
--- @field getPlayerCollectibleMap function @ must upgrade mod with `ISCFeature.MODDED_ELEMENT_SETS`
--- @field getTrinketTypes function @ must upgrade mod with `ISCFeature.MODDED_ELEMENT_SETS`
--- @field getTrinketTypesSet function @ must upgrade mod with `ISCFeature.MODDED_ELEMENT_SETS`
--- @field getModdedTrinketTypes function @ must upgrade mod with `ISCFeature.MODDED_ELEMENT_SETS`
--- @field getModdedTrinketTypesSet function @ must upgrade mod with `ISCFeature.MODDED_ELEMENT_SETS`
--- @field getCardTypes function @ must upgrade mod with `ISCFeature.MODDED_ELEMENT_SETS`
--- @field getCardTypesSet function @ must upgrade mod with `ISCFeature.MODDED_ELEMENT_SETS`
--- @field getModdedCardTypes function @ must upgrade mod with `ISCFeature.MODDED_ELEMENT_SETS`
--- @field getModdedCardTypesSet function @ must upgrade mod with `ISCFeature.MODDED_ELEMENT_SETS`
--- @field getPillEffects function @ must upgrade mod with `ISCFeature.MODDED_ELEMENT_SETS`
--- @field getPillEffectsSet function @ must upgrade mod with `ISCFeature.MODDED_ELEMENT_SETS`
--- @field getModdedPillEffects function @ must upgrade mod with `ISCFeature.MODDED_ELEMENT_SETS`
--- @field getModdedPillEffectsSet function @ must upgrade mod with `ISCFeature.MODDED_ELEMENT_SETS`
--- @field getCollectibleTypesWithCacheFlag function @ must upgrade mod with `ISCFeature.MODDED_ELEMENT_SETS`
--- @field getTrinketsTypesWithCacheFlag function @ must upgrade mod with `ISCFeature.MODDED_ELEMENT_SETS`
--- @field getPlayerCollectiblesWithCacheFlag function @ must upgrade mod with `ISCFeature.MODDED_ELEMENT_SETS`
--- @field getPlayerTrinketsWithCacheFlag function @ must upgrade mod with `ISCFeature.MODDED_ELEMENT_SETS`
--- @field getFlyingCollectibleTypes function @ must upgrade mod with `ISCFeature.MODDED_ELEMENT_SETS`
--- @field getFlyingTrinketTypes function @ must upgrade mod with `ISCFeature.MODDED_ELEMENT_SETS`
--- @field getCollectibleTypesWithTag function @ must upgrade mod with `ISCFeature.MODDED_ELEMENT_SETS`
--- @field getPlayerCollectiblesWithTag function @ must upgrade mod with `ISCFeature.MODDED_ELEMENT_SETS`
--- @field getCollectibleTypesFortransformation function @ must upgrade mod with `ISCFeature.MODDED_ELEMENT_SETS`
--- @field getPlayerCollectiblesForTransformation function @ must upgrade mod with `ISCFeature.MODDED_ELEMENT_SETS`
--- @field getEdenActiveCollectibleTypes function @ must upgrade mod with `ISCFeature.MODDED_ELEMENT_SETS`
--- @field getEdenPassiveCollectibleTypes function @ must upgrade mod with `ISCFeature.MODDED_ELEMENT_SETS`
--- @field getRandomEdenActiveCollectibleType function @ must upgrade mod with `ISCFeature.MODDED_ELEMENT_SETS`
--- @field getRandomEdenPassiveCollectibleType function @ must upgrade mod with `ISCFeature.MODDED_ELEMENT_SETS`
--- @field getCollectibleTypesOfQuality function @ must upgrade mod with `ISCFeature.MODDED_ELEMENT_SETS`
--- @field getPlayerCollectiblesOfQuality function @ must upgrade mod with `ISCFeature.MODDED_ELEMENT_SETS`
--- @field getCardTypesOfType function @ must upgrade mod with `ISCFeature.MODDED_ELEMENT_SETS`
--- @field getRandomCardTypeOfType function @ must upgrade mod with `ISCFeature.MODDED_ELEMENT_SETS`
--- @field getRandomCard function @ must upgrade mod with `ISCFeature.MODDED_ELEMENT_SETS`
--- @field getRandomRune function @ must upgrade mod with `ISCFeature.MODDED_ELEMENT_SETS`
--- @field setFamiliarNoSirenSteal function @ must upgrade mod with `ISCFeature.NO_SIREN_STEAL`
--- @field isPaused function @ must upgrade mod with `ISCFeature.PAUSE`
--- @field pause function @ must upgrade mod with `ISCFeature.PAUSE`
--- @field unpause function @ must upgrade mod with `ISCFeature.PAUSE`
--- @field removePersistentEntity function @ must upgrade mod with `ISCFeature.PERSISTENT_ENTITIES`
--- @field spawnPersistentEntity function @ must upgrade mod with `ISCFeature.PERSISTENT_ENTITIES`
--- @field getPickupIndex function @ must upgrade mod with `ISCFeature.PICKUP_INDEX_CREATION`
--- @field getPlayerCollectibleTypes function @ must upgrade mod with `ISCFeature.PLAYER_COLLECTIBLE_TRACKING`
--- @field getPlayerLastPassiveCollectibleType function @ must upgrade mod with `ISCFeature.PLAYER_COLLECTIBLE_TRACKING`
--- @field isPlayerUsingPony function @ must upgrade mod with `ISCFeature.PONY_DETECTION`
--- @field anyPlayerUsingPony function @ must upgrade mod with `ISCFeature.PONY_DETECTION`
--- @field pressInput function @ must upgrade mod with `ISCFeature.PRESS_INPUT`
--- @field preventChildEntities function @ must upgrade mod with `ISCFeature.PREVENT_CHILD_ENTITIES`
--- @field preventGridEntityRespawn function @ must upgrade mod with `ISCFeature.PREVENT_GRID_ENTITY_RESPAWN`
--- @field onRerun function @ must upgrade mod with `ISCFeature.RERUN_DETECTION`
--- @field getRoomClearGameFrame function @ must upgrade mod with `ISCFeature.ROOM_CLEAR_FRAME`
--- @field getRoomClearRenderFrame function @ must upgrade mod with `ISCFeature.ROOM_CLEAR_FRAME`
--- @field getRoomClearRoomFrame function @ must upgrade mod with `ISCFeature.ROOM_CLEAR_FRAME`
--- @field deleteLastRoomDescription function @ must upgrade mod with `ISCFeature.ROOM_HISTORY`
--- @field getNumRoomsEntered function @ must upgrade mod with `ISCFeature.ROOM_HISTORY`
--- @field getRoomHistory function @ must upgrade mod with `ISCFeature.ROOM_HISTORY`
--- @field getPreviousRoomDescription function @ must upgrade mod with `ISCFeature.ROOM_HISTORY`
--- @field getLatestRoomDescription function @ must upgrade mod with `ISCFeature.ROOM_HISTORY`
--- @field inFirstRoom function @ must upgrade mod with `ISCFeature.ROOM_HISTORY`
--- @field isLeavingRoom function @ must upgrade mod with `ISCFeature.ROOM_HISTORY`
--- @field restartNextRenderFrame function @ must upgrade mod with `ISCFeature.RUN_IN_N_FRAMES`
--- @field runInNGameFrames function @ must upgrade mod with `ISCFeature.RUN_IN_N_FRAMES`
--- @field runInNRenderFrames function @ must upgrade mod with `ISCFeature.RUN_IN_N_FRAMES`
--- @field runNextGameFrame function @ must upgrade mod with `ISCFeature.RUN_IN_N_FRAMES`
--- @field runNextRenderFrame function @ must upgrade mod with `ISCFeature.RUN_IN_N_FRAMES`
--- @field setIntervalGameFrames function @ must upgrade mod with `ISCFeature.RUN_IN_N_FRAMES`
--- @field setIntervalRenderFrames function @ must upgrade mod with `ISCFeature.RUN_IN_N_FRAMES`
--- @field runNextRoom function @ must upgrade mod with `ISCFeature.RUN_NEXT_ROOM`
--- @field runNextRun function @ must upgrade mod with `ISCFeature.RUN_NEXT_RUN`
--- @field saveDataManager function @ must upgrade mod with `ISCFeature.SAVE_DATA_MANAGER`
--- @field saveDataManagerLoad function @ must upgrade mod with `ISCFeature.SAVE_DATA_MANAGER`
--- @field saveDataManagerSave function @ must upgrade mod with `ISCFeature.SAVE_DATA_MANAGER`
--- @field saveDataManagerSetGlobal function @ must upgrade mod with `ISCFeature.SAVE_DATA_MANAGER`
--- @field saveDataManagerRegisterClass function @ must upgrade mod with `ISCFeature.SAVE_DATA_MANAGER`
--- @field saveDataManagerRemove function @ must upgrade mod with `ISCFeature.SAVE_DATA_MANAGER`
--- @field saveDataManagerReset function @ must upgrade mod with `ISCFeature.SAVE_DATA_MANAGER`
--- @field saveDataManagerInMenu function @ must upgrade mod with `ISCFeature.SAVE_DATA_MANAGER`
--- @field saveDataManagerLogSubscribers function @ must upgrade mod with `ISCFeature.SAVE_DATA_MANAGER`
--- @field spawnRockAltReward function @ must upgrade mod with `ISCFeature.SPAWN_ALT_ROCK_REWARDS`
--- @field spawnRockAltRewardUrn function @ must upgrade mod with `ISCFeature.SPAWN_ALT_ROCK_REWARDS`
--- @field spawnRockAltRewardMushroom function @ must upgrade mod with `ISCFeature.SPAWN_ALT_ROCK_REWARDS`
--- @field spawnRockAltRewardSkull function @ must upgrade mod with `ISCFeature.SPAWN_ALT_ROCK_REWARDS`
--- @field spawnRockAltRewardPolyp function @ must upgrade mod with `ISCFeature.SPAWN_ALT_ROCK_REWARDS`
--- @field spawnRockAltRewardBucketDownpour function @ must upgrade mod with `ISCFeature.SPAWN_ALT_ROCK_REWARDS`
--- @field spawnRockAltRewardBucketDross function @ must upgrade mod with `ISCFeature.SPAWN_ALT_ROCK_REWARDS`
--- @field getNextStageTypeWithHistory function @ must upgrade mod with `ISCFeature.STAGE_HISTORY`
--- @field getNextStageWithHistory function @ must upgrade mod with `ISCFeature.STAGE_HISTORY`
--- @field getStageHistory function @ must upgrade mod with `ISCFeature.STAGE_HISTORY`
--- @field hasVisitedStage function @ must upgrade mod with `ISCFeature.STAGE_HISTORY`
--- @field startAmbush function @ must upgrade mod with `ISCFeature.START_AMBUSH`
--- @field getTaintedLazarusSubPlayer function @ must upgrade mod with `ISCFeature.TAINTED_LAZARUS_PLAYERS`
--- @field canRunUnlockAchievements function @ must upgrade mod with `ISCFeature.UNLOCK_ACHIEVEMENTS_DETECTION`

-- Init

--- @type ModReference
local TheSaintVanilla = RegisterMod(stats.ModName, 1)
local features = {
    isc.ISCFeature.SAVE_DATA_MANAGER,
    isc.ISCFeature.EXTRA_CONSOLE_COMMANDS,
    isc.ISCFeature.UNLOCK_ACHIEVEMENTS_DETECTION,
    isc.ISCFeature.PLAYER_COLLECTIBLE_TRACKING,
}
--- @type ModUpgraded
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

-- class registration
require("TheSaint.classes.PlayerLoadout").register(TheSaint)

-- feature initialization
local imports = include("TheSaint.imports")
if (type(imports) == "table") then
    --- @diagnostic disable-next-line
    imports:LoadFeatures(TheSaint)
end

print("[The Saint] Type 'thesaint_help' for a list of commands")
