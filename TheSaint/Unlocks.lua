local isc = require("TheSaint.lib.isaacscript-common")
local enums = require("TheSaint.Enums")
local mcm = require("TheSaint.ModIntegration.MCM")

local game = Game()

--- @class TheSaint.UnlockManager : TheSaint_Feature
local UnlockManager = {
	IsInitialized = false,
	SaveDataKey = "UnlockManager",
}

--- Character Completion Marks.<br>
--- Each field represents a completion mark, with the value being the completion difficulty.<br>
--- `nil` for not completed, `false` for normal/greed mode and `true` for hard/greedier mode
--- @class CharacterCompletionMarks
--- @field ["BossRush"] boolean?
--- @field ["MomsHeart"] boolean?
--- @field ["Satan"] boolean?
--- @field ["Isaac"] boolean?
--- @field ["TheLamb"] boolean?
--- @field ["BlueBaby"] boolean?
--- @field ["MegaSatan"] boolean?
--- @field ["GreedMode"] boolean?
--- @field ["Hush"] boolean?
--- @field ["Delirium"] boolean?
--- @field ["Mother"] boolean?
--- @field ["TheBeast"] boolean?

--- @class BossCompletionMark
--- @field Mark string
--- @field Floor LevelStage?

local saint = enums.PlayerType.PLAYER_THE_SAINT
local tSaint = enums.PlayerType.PLAYER_THE_SAINT_B

--- mapping of isc.BossID to `CharacterCompletionMarks` field names + allowed Levels (to prevent awarding the mark on the "Void"-floor)
--- @type table<integer, BossCompletionMark>
local bossMarks = {
	[isc.BossID.MOMS_HEART] = {Mark = "MomsHeart", Floor = LevelStage.STAGE4_2},
	[isc.BossID.IT_LIVES] = {Mark = "MomsHeart", Floor = LevelStage.STAGE4_2},
	[isc.BossID.MAUSOLEUM_MOMS_HEART] = {Mark = "MomsHeart", Floor = LevelStage.STAGE3_2},
	[isc.BossID.SATAN] = {Mark = "Satan", Floor = LevelStage.STAGE5},
	[isc.BossID.ISAAC] = {Mark = "Isaac", Floor = LevelStage.STAGE5},
	[isc.BossID.LAMB] = {Mark = "TheLamb", Floor = LevelStage.STAGE6},
	[isc.BossID.BLUE_BABY] = {Mark = "BlueBaby", Floor = LevelStage.STAGE6},
	[isc.BossID.MEGA_SATAN] = {Mark = "MegaSatan", Floor = nil},
	[isc.BossID.ULTRA_GREED] = {Mark = "GreedMode", Floor = nil},
	[isc.BossID.ULTRA_GREEDIER] = {Mark = "GreedMode", Floor = nil},
	[isc.BossID.HUSH] = {Mark = "Hush", Floor = nil},
	[isc.BossID.DELIRIUM] = {Mark = "Delirium", Floor = nil},
	[isc.BossID.MOTHER] = {Mark = "Mother", Floor = nil},
	[isc.BossID.BEAST] = {Mark = "TheBeast", Floor = nil},
}

local v = {
	persistent = {
		--- @type table<string, CharacterCompletionMarks>
		characterMarks = {
			["Saint"] = {},
			["T_Saint"] = {},
		}
	}
}

--- @param targetMark string
--- @param difficulty Difficulty
local function awardCompletionMarks(targetMark, difficulty)
	--- @type string[]
	local targetPlayers = {}
	if (isc:anyPlayerIs(saint)) then table.insert(targetPlayers, "Saint") end
	if (isc:anyPlayerIs(tSaint)) then table.insert(targetPlayers, "T_Saint") end
	for _, char in ipairs(targetPlayers) do
		local state = nil
		if ((difficulty == Difficulty.DIFFICULTY_NORMAL) or (difficulty == Difficulty.DIFFICULTY_GREED)) then
			state = false
		elseif ((difficulty == Difficulty.DIFFICULTY_HARD) or (difficulty == Difficulty.DIFFICULTY_GREEDIER)) then
			state = true
		end
		local marks = v.persistent.characterMarks[char]
		if (marks and (
			((marks[targetMark] == nil) and (state ~= nil)) or
			((marks[targetMark] == false) and (state == true))
		)) then
			marks[targetMark] = state
		end
	end
end

--- Boss Rush
local function postAmbushFinished(_, ambush)
	awardCompletionMarks("BossRush", game.Difficulty)
end

--- All other Completion Marks
--- @param rng RNG
--- @param spawnPos Vector
local function preSpawnCleanAward(_, rng, spawnPos)
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

--#region Unlocks

--- @param pickup EntityPickup
--- @param type string
--- @param lockedSubType integer
local function rerollItem(pickup, type, lockedSubType)
	--- @type PickupVariant
	local variant = PickupVariant.PICKUP_NULL
	local newSubType = 0
	local pool = game:GetItemPool()
	if (type == "collectible") then
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
	elseif (type == "trinket") then
		variant = PickupVariant.PICKUP_TRINKET
		local isGold = (pickup.SubType > TrinketType.TRINKET_GOLDEN_FLAG)
		pool:RemoveTrinket(lockedSubType)
		newSubType = pool:GetTrinket(false)
		pool:RemoveTrinket(newSubType)
		if (isGold) then newSubType = newSubType + TrinketType.TRINKET_GOLDEN_FLAG end
	elseif ((type == "card") or (type == "rune")) then
		variant = PickupVariant.PICKUP_TAROTCARD
		local isRune = (type == "rune")
		repeat
			newSubType = pool:GetCard(pickup.InitSeed, false, isRune, isRune)
		until (newSubType ~= lockedSubType)
	end
	if (variant ~= PickupVariant.PICKUP_NULL) then
		pickup:Morph(EntityType.ENTITY_PICKUP, variant, newSubType, true)
	end
end

--- Automatically reroll any item/pickup that hasn't been unlocked yet
--- @param pickup EntityPickup
local function postPickupInitFirst(_, pickup)
	if (mcm:getSetting("UnlockAll")) then return end

	local marks_saint = v.persistent.characterMarks["Saint"]
	local marks_tSaint = v.persistent.characterMarks["T_Saint"]

	-- (Boss Rush with Saint)

	-- "Almanach" (Mom's Heart on Hard Mode with Saint)
	if ((pickup.Variant == PickupVariant.PICKUP_COLLECTIBLE)
	and (pickup.SubType == enums.CollectibleType.COLLECTIBLE_ALMANACH)) then
		if (not marks_saint["MomsHeart"]) then
			rerollItem(pickup, "collectible", enums.CollectibleType.COLLECTIBLE_ALMANACH)
			return
		end
	end
	-- (Satan with Saint)

	-- "Divine Bombs" (Isaac with Saint)
	if ((pickup.Variant == PickupVariant.PICKUP_COLLECTIBLE)
	and (pickup.SubType == enums.CollectibleType.COLLECTIBLE_DIVINE_BOMBS)) then
		if (marks_saint["Isaac"] == nil) then
			rerollItem(pickup, "collectible", enums.CollectibleType.COLLECTIBLE_DIVINE_BOMBS)
			return
		end
	end
	-- "Wooden Key" (The Lamb with Saint)
	if ((pickup.Variant == PickupVariant.PICKUP_COLLECTIBLE)
	and (pickup.SubType == enums.CollectibleType.COLLECTIBLE_WOODEN_KEY)) then
		if (marks_saint["TheLamb"] == nil) then
			rerollItem(pickup, "collectible", enums.CollectibleType.COLLECTIBLE_WOODEN_KEY)
			return
		end
	end
	-- "Holy Penny" (??? with Saint)
	if ((pickup.Variant == PickupVariant.PICKUP_TRINKET)
	and ((pickup.SubType % TrinketType.TRINKET_GOLDEN_FLAG) == enums.TrinketType.TRINKET_HOLY_PENNY)) then
		if (marks_saint["BlueBaby"] == nil) then
			rerollItem(pickup, "trinket", enums.TrinketType.TRINKET_HOLY_PENNY)
			return
		end
	end
	-- (Mega Satan with Saint)

	-- "Library Card" (Greed Mode with Saint)
	if ((pickup.Variant == PickupVariant.PICKUP_TAROTCARD)
	and (pickup.SubType == enums.Card.CARD_LIBRARY)) then
		if (marks_saint["GreedMode"] == nil) then
			rerollItem(pickup, "card", enums.Card.CARD_LIBRARY)
			return
		end
	end
	-- (Hush with Saint)

	-- (Greedier Mode with Saint)

	-- (Delirium with Saint)

	-- (Mother with Saint)

	-- "Holy Hand Grenade" (The Beast with Saint)
	if ((pickup.Variant == PickupVariant.PICKUP_COLLECTIBLE)
	and (pickup.SubType == enums.CollectibleType.COLLECTIBLE_HOLY_HAND_GRENADE)) then
		if (marks_saint["TheBeast"] == nil) then
			rerollItem(pickup, "collectible", enums.CollectibleType.COLLECTIBLE_HOLY_HAND_GRENADE)
			return
		end
	end
	-- "Soul of the Saint" (Boss Rush + Hush with T.Saint)
	if ((pickup.Variant == PickupVariant.PICKUP_TAROTCARD)
	and (pickup.SubType == enums.Card.CARD_SOUL_SAINT)) then
		if ((marks_tSaint["BossRush"] == nil) or (marks_tSaint["Hush"] == nil)) then
			rerollItem(pickup, "rune", enums.Card.CARD_SOUL_SAINT)
			return
		end
	end
	-- (Satan + Isaac + The Lamb + ??? with T.Saint)

	-- (Greedier Mode with T.Saint)

	-- "Mending Heart" (Delirium with T.Saint)
	if ((pickup.Variant == PickupVariant.PICKUP_COLLECTIBLE)
	and (pickup.SubType == enums.CollectibleType.COLLECTIBLE_MENDING_HEART)) then
		if (marks_tSaint["Delirium"] == nil) then
			rerollItem(pickup, "collectible", enums.CollectibleType.COLLECTIBLE_MENDING_HEART)
			return
		end
	end
	-- (Mother with T.Saint)

	-- (The Beast with T.Saint)

	-- (Mega Satan with T.Saint)

end

--#endregion

--#region Console Commands

--- if any argument is "?", displays all valid values + information
--- @param char? string
--- @param operation? string
--- @param mark? string
--- @param diff? string
local function showCommandHelp(char, operation, mark, diff)
	if (char == "?") then
		print("[The Saint] 1st argument (<character>)")
		print("[The Saint] allowed values:")
		print("[The Saint] - 'Saint' (The Saint)")
		print("[The Saint] - 'TSaint' (Tainted Saint)")
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

--- @param status? boolean
--- @return string
local function getStatusString(status)
	local retVal = "not completed"
	if (status == false) then
		retVal = "normal"
	elseif (status == true) then
		retVal = "hard"
	end
	return retVal
end

--- @param marks CharacterCompletionMarks
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

--- @param mark string
--- @return boolean
local function isValidMark(mark)
	local validMarks = {
		"BossRush", "MomsHeart", "Satan", "Isaac",
		"TheLamb", "BlueBaby", "MegaSatan", "GreedMode",
		"Hush", "Delirium", "Mother", "TheBeast", "all",
	}
	local retVal = isc:find(validMarks, function (value) return (value == mark) end) --- @cast retVal boolean
	if (retVal == false) then
		print("[The Saint] invalid argument <completion mark>")
	end
	return retVal
end

--- @param char? string
--- @param operation? string
--- @param mark? string
--- @param diff? string
local function executeCommand(char, operation, mark, diff)
	if (char) then
		-- set default values
		if (not operation) then operation = "show" end
		if (not mark) then mark = "all" end
		if (not diff) then diff = "normal" end

		local character = (((char == "saint") and "Saint") or "T_Saint")
		local charName = (((char == "saint") and "The Saint") or "Tainted Saint")
		local marks = v.persistent.characterMarks[character]

		if (operation == "show") then
			print("[The Saint] completion marks for '"..charName.."':")
			listMarks(marks)
		else
			if (isValidMark(mark)) then
				local status = nil
				if (operation == "set") then
					status = (diff == "hard")
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
	params = string.lower(params)
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

--- @param mod ModReference
function UnlockManager:Init(mod)
	if (self.IsInitialized) then return end

	mod:saveDataManager(self.SaveDataKey, v)
	-- awarding completion marks
	mod:AddCallbackCustom(isc.ModCallbackCustom.POST_AMBUSH_FINISHED, postAmbushFinished, isc.AmbushType.BOSS_RUSH)
    mod:AddCallback(ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD, preSpawnCleanAward)
	-- prevent getting things, that aren't unlocked yet
	mod:AddCallbackCustom(isc.ModCallbackCustom.POST_PICKUP_INIT_FIRST, postPickupInitFirst)
	-- console commands
	mod:addConsoleCommand("thesaint_marks", thesaint_marks)
end

return UnlockManager
