local isc = require("TheSaint.lib.isaacscript-common")
local enums = require("TheSaint.Enums")

local game = Game()

local UnlockManager = {}

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

--- mapping of isc.BossID to `CompletionMarks` field names + allowed Levels (to prevent awarding the mark on the "Void"-floor)
--- @type table<_, BossCompletionMark>
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
		--- @type table<PlayerType, CharacterCompletionMarks>
		characterMarks = {
			[saint] = {},
			[tSaint] = {},
		}
	}
}

--- @param targetMark string
--- @param difficulty Difficulty
local function awardCompletionMarks(targetMark, difficulty)
	--- @type PlayerType[]
	local targetPlayers = {}
	if (isc:anyPlayerIs(saint)) then table.insert(targetPlayers, saint) end
	if (isc:anyPlayerIs(tSaint)) then table.insert(targetPlayers, tSaint) end
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
				if (game:GetLevel():GetAbsoluteStage() ~= mark.Floor) then return end
			end
			awardCompletionMarks(mark.Mark, game.Difficulty)
		end
	end
end


--#region Console Commands

--- if any argument is "?", displays all valid values + information
--- @param char string?
--- @param operation string?
--- @param mark string?
--- @param diff string?
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

--- @param status boolean?
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

--- @param char string?
--- @param operation string?
--- @param mark string?
--- @param diff string?
local function executeCommand(char, operation, mark, diff)
	if (char) then
		local character = (((char == "saint") and saint) or tSaint)
		local charName = (((character == saint) and "The Saint") or "Tainted Saint")
		local marks = v.persistent.characterMarks[character]
		if (operation == "show") then
			print("[The Saint] completion marks for '"..charName.."':")
			listMarks(marks)
		elseif (operation == "set") then
			local status = false
			if (diff == "hard") then
				status = true
			else
				diff = "normal"
			end
			if (mark == "all") then
				for field, _ in pairs(marks) do
					marks[field] = status
				end
				print("[The Saint] set all completion marks for '"..charName.."' to '"..diff.."'")
			elseif ((mark == "BossRush") or (mark == "MomsHeart") or (mark == "Satan") or
					(mark == "Isaac") or (mark == "TheLamb") or (mark == "BlueBaby") or
					(mark == "MegaSatan") or (mark == "GreedMode") or (mark == "Hush") or
					(mark == "Delirium") or (mark == "Mother") or (mark == "TheBeast")
			) then
				marks[mark] = status
				print("[The Saint] set completion mark '"..mark.."' for '"..charName.."' to '"..diff.."'")
			else
				print("[The Saint] invalid argument #3")
			end
		elseif (operation == "clear") then
			if (mark == "all") then
				for field, _ in pairs(marks) do
					marks[field] = nil
				end
				print("[The Saint] cleared all completion marks for '"..charName.."'")
			elseif ((mark == "BossRush") or (mark == "MomsHeart") or (mark == "Satan") or
					(mark == "Isaac") or (mark == "TheLamb") or (mark == "BlueBaby") or
					(mark == "MegaSatan") or (mark == "GreedMode") or (mark == "Hush") or
					(mark == "Delirium") or (mark == "Mother") or (mark == "TheBeast")
			) then
				marks[mark] = nil
				print("[The Saint] cleared completion mark '"..mark.."' for '"..charName.."'")
			else
				print("[The Saint] invalid argument #3")
			end
		else
			print("[The Saint] invalid argument #2")
		end
	else
		print("[The Saint] invalid argument #1")
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
	mod:saveDataManager("UnlockManager", v)
	mod:AddCallbackCustom(isc.ModCallbackCustom.POST_AMBUSH_FINISHED, postAmbushFinished, isc.AmbushType.BOSS_RUSH)
    mod:AddCallback(ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD, preSpawnCleanAward)
	mod:addConsoleCommand("thesaint_marks", thesaint_marks)
end

return UnlockManager
