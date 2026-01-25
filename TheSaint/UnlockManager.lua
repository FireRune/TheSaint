local isc = require("TheSaint.lib.isaacscript-common")
local enums = require("TheSaint.Enums")
local mcm = require("TheSaint.ModIntegration.MCM")

local game = Game()

--- @class TheSaint.UnlockManager : TheSaint.classes.ModFeature
local UnlockManager = {
	IsInitialized = false,
	SaveDataKey = "UnlockManager",
}

--#region typedef

--- @alias TheSaint.UnlockManager.UnlockPlayer
--- | "Saint"
--- | "T_Saint"

--- @alias TheSaint.UnlockManager.UnlockDifficulty
--- | "normal"	@ Unlocked from Normal/Greed mode
--- | "hard"	@ Unlocked from Hard/Greedier mode

--- @alias TheSaint.UnlockManager.CompletionState
--- | "none"	@ not completed
--- | "normal"	@ completed on normal/greed mode
--- | "hard"	@ completed on hard/greedier mode

--- Character Completion Marks.<br>
--- Each field represents a completion mark, with the value being the completion difficulty.<br>
--- `nil` for not completed, `false` for normal/greed mode and `true` for hard/greedier mode
--- @class TheSaint.UnlockManager.CharacterCompletionMarks
--- @field [TheSaint.Enums.CompletionMarks] TheSaint.UnlockManager.CompletionState

--- @class TheSaint.UnlockManager.BossCompletionMark
--- @field Mark TheSaint.Enums.CompletionMarks
--- @field Floor LevelStage?

--- @class TheSaint.UnlockManager.BossCompletionMark_Map
--- @field [integer] TheSaint.UnlockManager.BossCompletionMark

--- @class TheSaint.UnlockManager.CharacterCompletionMarks_Map
--- @field [TheSaint.UnlockManager.UnlockPlayer] TheSaint.UnlockManager.CharacterCompletionMarks

--- @alias TheSaint.UnlockManager.TypeOfPickup
--- | "collectible"
--- | "trinket"
--- | "card"
--- | "rune"

--- @class TheSaint.UnlockManager.Unlockable
--- @field Variant PickupVariant
--- @field SubType integer

--- @class TheSaint.UnlockManager.Unlock
--- @field Player TheSaint.UnlockManager.UnlockPlayer
--- @field Marks TheSaint.Enums.CompletionMarks[]
--- @field Difficulty TheSaint.UnlockManager.UnlockDifficulty
--- @field PickupType TheSaint.UnlockManager.TypeOfPickup
--- @field Unlockable TheSaint.UnlockManager.Unlockable

--- @alias TheSaint.UnlockManager.CmdOperation
--- | "show"
--- | "set"
--- | "clear"

--#endregion

--#region fields

local saint = enums.PlayerType.PLAYER_THE_SAINT
local tSaint = enums.PlayerType.PLAYER_THE_SAINT_B

--- mapping of isc.BossID to `CharacterCompletionMarks` field names + allowed Levels (to prevent awarding the mark on the "Void"-floor)
--- @type TheSaint.UnlockManager.BossCompletionMark_Map
local bossMarks = {
	[isc.BossID.MOMS_HEART] = {
		Mark = enums.CompletionMarks.MOMS_HEART,
		Floor = LevelStage.STAGE4_2,
	},
	[isc.BossID.IT_LIVES] = {
		Mark = enums.CompletionMarks.MOMS_HEART,
		Floor = LevelStage.STAGE4_2,
	},
	[isc.BossID.MAUSOLEUM_MOMS_HEART] = {
		Mark = enums.CompletionMarks.MOMS_HEART,
		Floor = LevelStage.STAGE3_2,
	},
	[isc.BossID.SATAN] = {
		Mark = enums.CompletionMarks.SATAN,
		Floor = LevelStage.STAGE5,
	},
	[isc.BossID.ISAAC] = {
		Mark = enums.CompletionMarks.ISAAC,
		Floor = LevelStage.STAGE5,
	},
	[isc.BossID.LAMB] = {
		Mark = enums.CompletionMarks.THE_LAMB,
		Floor = LevelStage.STAGE6,
	},
	[isc.BossID.BLUE_BABY] = {
		Mark = enums.CompletionMarks.BLUE_BABY,
		Floor = LevelStage.STAGE6,
	},
	[isc.BossID.MEGA_SATAN] = {
		Mark = enums.CompletionMarks.MEGA_SATAN,
	},
	[isc.BossID.ULTRA_GREED] = {
		Mark = enums.CompletionMarks.GREED_MODE,
	},
	[isc.BossID.ULTRA_GREEDIER] = {
		Mark = enums.CompletionMarks.GREED_MODE,
	},
	[isc.BossID.HUSH] = {
		Mark = enums.CompletionMarks.HUSH,
	},
	[isc.BossID.DELIRIUM] = {
		Mark = enums.CompletionMarks.DELIRIUM,
	},
	[isc.BossID.MOTHER] = {
		Mark = enums.CompletionMarks.MOTHER,
	},
	[isc.BossID.BEAST] = {
		Mark = enums.CompletionMarks.THE_BEAST,
	},
}
--#endregion

--#region Unlocks

--- @type TheSaint.UnlockManager.Unlock[]
local unlocksTable = {}

--- @type table<string, TheSaint.UnlockManager.Unlock>
local unlocksMap = {}

--- @param player TheSaint.UnlockManager.UnlockPlayer
--- @param marks TheSaint.Enums.CompletionMarks | TheSaint.Enums.CompletionMarks[]
--- @param difficulty TheSaint.UnlockManager.UnlockDifficulty
--- @param typeOfPickup TheSaint.UnlockManager.TypeOfPickup
--- @param unlockable integer
local function createUnlock(player, marks, difficulty, typeOfPickup, unlockable)
	if (type(marks) ~= "table") then marks = {marks} end

	--- @type PickupVariant
	local variant = PickupVariant.PICKUP_NULL
	if (typeOfPickup == "collectible") then
		variant = PickupVariant.PICKUP_COLLECTIBLE
	elseif (typeOfPickup == "trinket") then
		variant = PickupVariant.PICKUP_TRINKET
	elseif ((typeOfPickup == "card") or (typeOfPickup == "rune")) then
		variant = PickupVariant.PICKUP_TAROTCARD
	end

	--- @type TheSaint.UnlockManager.Unlock
	local unlock = {
		Player = player,
		Marks = marks,
		Difficulty = difficulty,
		PickupType = typeOfPickup,
		--- @type TheSaint.UnlockManager.Unlockable
		Unlockable = {
			Variant = variant,
			SubType = unlockable,
		},
	}

	table.insert(unlocksTable, unlock)

	local mapKey = variant.."_"..unlockable
	unlocksMap[mapKey] = unlock
end

local function fillUnlocksTableAndMap()
	-- (Boss Rush with Saint)
	-- "Almanach" (Mom's Heart on Hard Mode with Saint)
	createUnlock("Saint", enums.CompletionMarks.MOMS_HEART, "hard", "collectible", enums.CollectibleType.COLLECTIBLE_ALMANACH)
	-- "Scorched Baby" (Satan with Saint)
	createUnlock("Saint", enums.CompletionMarks.SATAN, "normal", "collectible", enums.CollectibleType.COLLECTIBLE_SCORCHED_BABY)
	-- "Divine Bombs" (Isaac with Saint)
	createUnlock("Saint", enums.CompletionMarks.ISAAC, "normal", "collectible", enums.CollectibleType.COLLECTIBLE_DIVINE_BOMBS)
	-- "Scattered Pages" (The Lamb with Saint)
	createUnlock("Saint", enums.CompletionMarks.THE_LAMB, "normal", "trinket", enums.TrinketType.TRINKET_SCATTERED_PAGES)
	-- "Protective Candle" (??? with Saint)
	createUnlock("Saint", enums.CompletionMarks.BLUE_BABY, "normal", "collectible", enums.CollectibleType.COLLECTIBLE_PROTECTIVE_CANDLE)
	-- (Mega Satan with Saint)
	-- "Library Card" (Greed Mode with Saint)
	createUnlock("Saint", enums.CompletionMarks.GREED_MODE, "normal", "card", enums.Card.CARD_LIBRARY)
	-- "Wooden Key" (Hush with Saint)
	createUnlock("Saint", enums.CompletionMarks.HUSH, "normal", "collectible", enums.CollectibleType.COLLECTIBLE_WOODEN_KEY)
	-- (Greedier Mode with Saint)
	-- (Delirium with Saint)
	-- (Mother with Saint)
	-- "Holy Hand Grenade" (The Beast with Saint)
	createUnlock("Saint", enums.CompletionMarks.THE_BEAST, "normal", "collectible", enums.CollectibleType.COLLECTIBLE_HOLY_HAND_GRENADE)
	-- "Soul of the Saint" (Boss Rush + Hush with T.Saint)
	createUnlock("T_Saint", {enums.CompletionMarks.BOSS_RUSH, enums.CompletionMarks.HUSH}, "normal", "rune", enums.Card.CARD_SOUL_SAINT)
	-- (Satan + Isaac + The Lamb + ??? with T.Saint)
	-- "Red Joker" (Greedier Mode with T.Saint)
	createUnlock("T_Saint", enums.CompletionMarks.GREED_MODE, "hard", "card", enums.Card.CARD_RED_JOKER)
	-- "Mending Heart" (Delirium with T.Saint)
	createUnlock("T_Saint", enums.CompletionMarks.DELIRIUM, "normal", "collectible", enums.CollectibleType.COLLECTIBLE_MENDING_HEART)
	-- "Holy Penny" (Mother with T.Saint)
	createUnlock("T_Saint", enums.CompletionMarks.MOTHER, "normal", "trinket", enums.TrinketType.TRINKET_HOLY_PENNY)
	-- "Rite of Rebirth" (The Beast with T.Saint)
	createUnlock("T_Saint", enums.CompletionMarks.THE_BEAST, "normal", "collectible", enums.CollectibleType.COLLECTIBLE_RITE_OF_REBIRTH)
	-- (Mega Satan with T.Saint)
end

--#endregion

local v = {
	persistent = {
		--- @type TheSaint.UnlockManager.CharacterCompletionMarks_Map
		characterMarks = {
			["Saint"] = {
				[enums.CompletionMarks.BOSS_RUSH] = "none",
				[enums.CompletionMarks.MOMS_HEART] = "none",
				[enums.CompletionMarks.SATAN] = "none",
				[enums.CompletionMarks.ISAAC] = "none",
				[enums.CompletionMarks.THE_LAMB] = "none",
				[enums.CompletionMarks.BLUE_BABY] = "none",
				[enums.CompletionMarks.MEGA_SATAN] = "none",
				[enums.CompletionMarks.GREED_MODE] = "none",
				[enums.CompletionMarks.HUSH] = "none",
				[enums.CompletionMarks.DELIRIUM] = "none",
				[enums.CompletionMarks.MOTHER] = "none",
				[enums.CompletionMarks.THE_BEAST] = "none",
			},
			["T_Saint"] = {
				[enums.CompletionMarks.BOSS_RUSH] = "none",
				[enums.CompletionMarks.MOMS_HEART] = "none",
				[enums.CompletionMarks.SATAN] = "none",
				[enums.CompletionMarks.ISAAC] = "none",
				[enums.CompletionMarks.THE_LAMB] = "none",
				[enums.CompletionMarks.BLUE_BABY] = "none",
				[enums.CompletionMarks.MEGA_SATAN] = "none",
				[enums.CompletionMarks.GREED_MODE] = "none",
				[enums.CompletionMarks.HUSH] = "none",
				[enums.CompletionMarks.DELIRIUM] = "none",
				[enums.CompletionMarks.MOTHER] = "none",
				[enums.CompletionMarks.THE_BEAST] = "none",
			},
		}
	}
}

--- @param targetMark TheSaint.Enums.CompletionMarks
--- @param difficulty Difficulty
local function awardCompletionMarks(targetMark, difficulty)
	--- @type string[]
	local targetPlayers = {}
	if (isc:anyPlayerIs(saint)) then table.insert(targetPlayers, "Saint") end
	if (isc:anyPlayerIs(tSaint)) then table.insert(targetPlayers, "T_Saint") end
	for _, char in ipairs(targetPlayers) do
		--- @type TheSaint.UnlockManager.CompletionState
		local state = "none"
		if ((difficulty == Difficulty.DIFFICULTY_NORMAL) or (difficulty == Difficulty.DIFFICULTY_GREED)) then
			state = "normal"
		elseif ((difficulty == Difficulty.DIFFICULTY_HARD) or (difficulty == Difficulty.DIFFICULTY_GREEDIER)) then
			state = "hard"
		end
		local marks = v.persistent.characterMarks[char]
		if (marks and (
			((marks[targetMark] == "none") and (state ~= "none")) or
			((marks[targetMark] == "normal") and (state == "hard"))
		)) then
			marks[targetMark] = state
		end
	end
end

--- Boss Rush
local function postAmbushFinished(_, ambush)
	if (UnlockManager.ThisMod:canRunUnlockAchievements()) then
		awardCompletionMarks(enums.CompletionMarks.BOSS_RUSH, game.Difficulty)
	end
end

--- All other Completion Marks
--- @param rng RNG
--- @param spawnPos Vector
local function preSpawnCleanAward(_, rng, spawnPos)
	if (UnlockManager.ThisMod:canRunUnlockAchievements()) then
		local bossId = isc:getBossID()
		if (bossId) then
			local mark = bossMarks[bossId]
			if (mark) then
				-- to obtain the Boss Mark, check wether the current floor is valid
				if (mark.Floor) then
					-- no floor-check for Greed(ier) Mode
					-- this shouldn't normally happen, but just to make sure
					if (game:IsGreedMode() or (game:GetLevel():GetAbsoluteStage() ~= mark.Floor)) then return end
				end
				awardCompletionMarks(mark.Mark, game.Difficulty)
			end
		end
	end
end

--#region Handling of locked stuff

--- @param pickup EntityPickup
--- @param variant PickupVariant
--- @param unlockableSubType integer
--- @return boolean
local function pickupCheck(pickup, variant, unlockableSubType)
	if (pickup.Variant == variant) then
		if (variant == PickupVariant.PICKUP_TRINKET) then
			return ((pickup.SubType % TrinketType.TRINKET_GOLDEN_FLAG) == unlockableSubType)
		else
			return (pickup.SubType == unlockableSubType)
		end
	end
	return false
end

--- @param states TheSaint.UnlockManager.CompletionState[] @ current completion status
--- @param unlockDifficulty TheSaint.UnlockManager.UnlockDifficulty @ required completion status
--- @return boolean
local function stateCheck(states, unlockDifficulty)
	local retVal = true

	--- @param state TheSaint.UnlockManager.CompletionState
	isc:forEach(states, function (_, state)
		-- no need to further check states once `retVal` is set to `false`
		if (retVal == false) then return end

		if ((state == "none")
		or ((state == "normal") and (unlockDifficulty == "hard"))) then
			retVal = false
		end
	end)

	return retVal
end

--- @param pickup EntityPickup
--- @param typeOfPickup TheSaint.UnlockManager.TypeOfPickup
--- @param lockedSubType integer
local function rerollItem(pickup, typeOfPickup, lockedSubType)
	local variant = PickupVariant.PICKUP_NULL
	local newSubType = 0
	local pool = game:GetItemPool()
	if (typeOfPickup == "collectible") then
		-- prevent collectible from appearing in the "Death Certificate" area
		if (isc:inDimension(isc.Dimension.DEATH_CERTIFICATE)) then
			pickup:Remove()
			return
		end
		-- if a collectible spawns that has already been removed from the pools (i.e. starting active items)
		-- then `RemoveCollectible` will return `false`, which can be used to prevent starting active items
		-- from being rerolled when picking up a different active item
		if (pool:RemoveCollectible(lockedSubType)) then
			variant = PickupVariant.PICKUP_COLLECTIBLE
			local room = game:GetRoom()
			local seed = game:GetSeeds():GetStartSeed()
			local itemPool = pool:GetPoolForRoom(room:GetType(), seed)
			newSubType = pool:GetCollectible(itemPool, true, pickup.InitSeed)
			pool:RemoveCollectible(newSubType)
		end
	elseif (typeOfPickup == "trinket") then
		variant = PickupVariant.PICKUP_TRINKET
		local isGold = (pickup.SubType > TrinketType.TRINKET_GOLDEN_FLAG)
		pool:RemoveTrinket(lockedSubType)
		newSubType = pool:GetTrinket(false)
		pool:RemoveTrinket(newSubType)
		if (isGold) then newSubType = newSubType + TrinketType.TRINKET_GOLDEN_FLAG end
	elseif ((typeOfPickup == "card") or (typeOfPickup == "rune")) then
		variant = PickupVariant.PICKUP_TAROTCARD
		local isRune = (typeOfPickup == "rune")
		repeat
			newSubType = pool:GetCard(pickup.InitSeed, false, isRune, isRune)
		until (newSubType ~= lockedSubType)
	end
	if (variant ~= PickupVariant.PICKUP_NULL) then
		pickup:Morph(EntityType.ENTITY_PICKUP, variant, newSubType, true)
	end
end

--- @param unlockPlayer TheSaint.UnlockManager.UnlockPlayer
--- @param compMarks TheSaint.Enums.CompletionMarks[]
--- @param unlockDifficulty TheSaint.UnlockManager.UnlockDifficulty
--- @return boolean
local function isUnlocked(unlockPlayer, compMarks, unlockDifficulty)
	if (mcm:getSetting(enums.Setting.UNLOCK_ALL) == true) then return true end

	--- @type TheSaint.UnlockManager.CharacterCompletionMarks
	local charMarks = v.persistent.characterMarks[unlockPlayer]

	--- @type TheSaint.UnlockManager.CompletionState[]
	local states = {}

	for _, mark in ipairs(compMarks) do
		local state = charMarks[mark]
		table.insert(states, state)
	end

	return stateCheck(states, unlockDifficulty)
end

--- Automatically reroll any item/pickup that hasn't been unlocked yet
--- @param pickup EntityPickup
local function postPickupInitFirst(_, pickup)
	-- pickup-check
	--- @param unlock TheSaint.UnlockManager.Unlock
	local unlockForPickup = isc:find(unlocksTable, function (_, unlock)
		return pickupCheck(pickup, unlock.Unlockable.Variant, unlock.Unlockable.SubType)
	end)
	--- @cast unlockForPickup TheSaint.UnlockManager.Unlock?

	if (unlockForPickup) then
		if (isUnlocked(unlockForPickup.Player, unlockForPickup.Marks, unlockForPickup.Difficulty) == false) then
			rerollItem(pickup, unlockForPickup.PickupType, unlockForPickup.Unlockable.SubType)
		end
	end

end

--- @param rng RNG
--- @param card Card
--- @param includePlaying boolean
--- @param includeRunes boolean
--- @param onlyRunes boolean
--- @return Card | nil
local function getCard(_, rng, card, includePlaying, includeRunes, onlyRunes)
	local pool = game:GetItemPool()

	local newCard = card
	while (UnlockManager:IsPickupUnlocked(PickupVariant.PICKUP_TAROTCARD, newCard) == false) do
		newCard = pool:GetCard(rng:Next(), includePlaying, includeRunes, onlyRunes)
	end
	return newCard
end

--#endregion

--#region Console Commands

--- if any argument is "?", displays all valid values + information
--- @param char? TheSaint.UnlockManager.UnlockPlayer | "?"
--- @param operation? TheSaint.UnlockManager.CmdOperation | "?"
--- @param mark? TheSaint.Enums.CompletionMarks | "all" | "?"
--- @param diff? TheSaint.UnlockManager.UnlockDifficulty | "?"
local function showCommandHelp(char, operation, mark, diff)
	if (char == "?") then
		print("[The Saint] 1st argument (<character>)")
		print("[The Saint] allowed values (case-sensitive):")
		print("[The Saint] - 'Saint' (The Saint)")
		print("[The Saint] - 'T_Saint' (Tainted Saint)")
	end
	if (operation == "?") then
		print("[The Saint] 2nd argument (show, set, clear)")
		print("[The Saint] - 'show': display a list of the specified character's completion marks and their progress")
		print("[The Saint] - 'set': sets the completion status of the specified mark to the specified value")
		print("[The Saint] - 'clear': clears the completion status of the specified mark")
		print("[The Saint] if the argument is not given defaults to 'show'")
	end
	if (mark == "?") then
		print("[The Saint] 3rd argument (<completion mark>)")
		print("[The Saint] allowed values for <completion mark> (case-sensitive):")
		print("[The Saint] - 'all'")
		print("[The Saint] - 'BossRush'")
		print("[The Saint] - 'MomsHeart'")
		print("[The Saint] - 'Satan'")
		print("[The Saint] - 'Isaac'")
		print("[The Saint] - 'TheLamb'")
		print("[The Saint] - 'BlueBaby'")
		print("[The Saint] - 'MegaSatan'")
		print("[The Saint] - 'GreedMode'")
		print("[The Saint] - 'Hush'")
		print("[The Saint] - 'Delirium'")
		print("[The Saint] - 'Mother'")
		print("[The Saint] - 'TheBeast'")
		print("[The Saint] if the argument is not given defaults to 'all'")
	end
	if (diff == "?") then
		print("[The Saint] 4th argument (normal, hard)")
		print("[The Saint] - 'normal': sets the mark for Normal/Greed Mode")
		print("[The Saint] - 'hard': sets the mark for Hard/Greedier Mode")
		print("[The Saint] this argument is ignored when 2nd argument is 'clear'")
		print("[The Saint] if the argument is not given defaults to 'normal'")
	end
end

--- @param status TheSaint.UnlockManager.CompletionState
--- @return string
local function getStatusString(status)
	if (status == "none") then
		return "not completed"
	else
		return status
	end
end

--- @param marks TheSaint.UnlockManager.CharacterCompletionMarks
local function listMarks(marks)
	print("[The Saint] Boss Rush: "..getStatusString(marks["BossRush"]))
	print("[The Saint] Mom's Heart: "..getStatusString(marks["MomsHeart"]))
	print("[The Saint] Satan: "..getStatusString(marks["Satan"]))
	print("[The Saint] Isaac: "..getStatusString(marks["Isaac"]))
	print("[The Saint] The Lamb: "..getStatusString(marks["TheLamb"]))
	print("[The Saint] ???: "..getStatusString(marks["BlueBaby"]))
	print("[The Saint] Mega Satan: "..getStatusString(marks["MegaSatan"]))
	print("[The Saint] Greed Mode: "..getStatusString(marks["GreedMode"]))
	print("[The Saint] Hush: "..getStatusString(marks["Hush"]))
	print("[The Saint] Delirium: "..getStatusString(marks["Delirium"]))
	print("[The Saint] Mother: "..getStatusString(marks["Mother"]))
	print("[The Saint] The Beast: "..getStatusString(marks["TheBeast"]))
end

--- @param mark TheSaint.Enums.CompletionMarks | "all"
--- @return boolean
local function isValidMark(mark)
	local validMarks = {
		"BossRush", "MomsHeart", "Satan", "Isaac",
		"TheLamb", "BlueBaby", "MegaSatan", "GreedMode",
		"Hush", "Delirium", "Mother", "TheBeast", "all",
	}

	--- @param value TheSaint.Enums.CompletionMarks | "all"
	local retVal = isc:find(validMarks, function (_, value)
		return (value == mark)
	end)
	--- @cast retVal boolean

	if (retVal == false) then
		print("[The Saint] invalid argument <completion mark>")
	end
	return retVal
end

--- @param char? string
--- @param operation? TheSaint.UnlockManager.CmdOperation
--- @param mark? TheSaint.Enums.CompletionMarks | "all"
--- @param diff? TheSaint.UnlockManager.UnlockDifficulty
local function executeCommand(char, operation, mark, diff)
	if (char and ((char == "saint") or (char == "tsaint"))) then
		-- set default values
		if (not operation) then operation = "show" end
		if (not mark) then mark = "all" end
		if (not diff) then diff = "normal" end

		--- @type TheSaint.UnlockManager.UnlockPlayer
		local character = (((char == "saint") and "Saint") or "T_Saint")
		local charName = (((char == "saint") and "The Saint") or "Tainted Saint")
		local marks = v.persistent.characterMarks[character]

		if (operation == "show") then
			print("[The Saint] completion marks for '"..charName.."':")
			listMarks(marks)
		else
			if (isValidMark(mark)) then
				--- @type TheSaint.UnlockManager.CompletionState
				local status = "none"
				if (operation == "set") then
					status = diff
				end
				local msg = {
					["set"] = "[The Saint] set @ for '"..charName.."' to '"..diff.."'",
					["clear"] = "[The Saint] cleared @ for '"..charName.."'",
				}
				if (mark == "all") then
					for field, _ in pairs(marks) do
						marks[field] = status
					end
					local output = msg[operation]:gsub("@", "all completion marks")
					print(output)
				else
					marks[mark] = status
					local output = msg[operation]:gsub("@", "completion mark '"..mark.."'")
					print(output)
				end
			end
		end
	else
		print("[The Saint] invalid argument <character>")
	end
end

--- @param params string
local function thesaint_marks(params)
	--- @type string[]
	local paramList = {}
	for param in params:gmatch("%g+") do
		param = param:gsub("'", "")
		table.insert(paramList, param)
	end
	if ((#paramList == 0)) then
		print("[The Saint] incomplete command, use the following syntax (without quotation marks):")
		print("[The Saint] 'thesaint_marks <character> [show|{set|clear} [<completion mark> [normal|hard]]]'")
		print("[The Saint] using '?' as any argument will show a list of all valid values")
	else
		local showHelp = false
		--- @type string, string?, string?, string?, string?
		local val, char, operation, mark, diff
		for i = 1, #paramList do
			-- currently only 4 arguments allowed at most
			if (i >= 5) then break end

			val = paramList[i]
			if (i ~= 3) then
				val = string.lower(val)
				if ((i == 1) and ((val == "?") or (val == "saint") or (val == "tsaint"))) then
					char = val
				elseif ((i == 2) and ((val == "?") or (val == "show") or (val == "set") or (val == "clear"))) then
					operation = val
				elseif ((i == 4) and ((val == "?") or (val == "normal") or (val == "hard"))) then
					diff = val
				end
			else
				mark = val
			end
			showHelp = (showHelp or (val == "?"))
		end
		if (showHelp) then
			showCommandHelp(char, operation, mark, diff)
		else
			executeCommand(char, operation, mark, diff)
		end
	end
end
--#endregion

--- @param mod ModUpgraded
function UnlockManager:Init(mod)
	if (self.IsInitialized) then return end

	self.ThisMod = mod

	mod:saveDataManager(self.SaveDataKey, v)
	fillUnlocksTableAndMap()
	-- awarding completion marks
	mod:AddCallbackCustom(isc.ModCallbackCustom.POST_AMBUSH_FINISHED, postAmbushFinished, isc.AmbushType.BOSS_RUSH)
	mod:AddCallback(ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD, preSpawnCleanAward)
	-- prevent getting things, that aren't unlocked yet
	mod:AddCallbackCustom(isc.ModCallbackCustom.POST_PICKUP_INIT_FIRST, postPickupInitFirst)
	-- prevent card pool pulling cards/runes that aren't unlocked yet
	mod:AddCallback(ModCallbacks.MC_GET_CARD, getCard)
	-- console commands
	mod:addConsoleCommand("thesaint_marks", thesaint_marks)
end

--- for use in other features to check whether something from this mod is unlocked
--- @param variant PickupVariant
--- @param subtype integer
--- @return boolean
function UnlockManager:IsPickupUnlocked(variant, subtype)
	if (self.IsInitialized) then
		local mapKey = variant.."_"..subtype
		local unlock = unlocksMap[mapKey]
		if (unlock) then
			return isUnlocked(unlock.Player, unlock.Marks, unlock.Difficulty)
		end
	end
	return true
end

return UnlockManager
