local isc = require("TheSaint.lib.isaacscript-common")
local enums = require("TheSaint.Enums")
local ddTracking = require("TheSaint.DevilDealTracking")

--- @class TheSaint.ModIntegration.EIDRegistry : TheSaint_Feature
local EIDRegistry = {
	IsInitialized = false,
}

local function AddRegistry()

	--#region EID classes

	---@class EID_Icon
	---@field [1] string @Animation name
	---@field [2] integer @Animation frame
	---@field [3] integer @Width
	---@field [4] integer @Height
	---@field [5] integer? @Left offset
	---@field [6] integer? @Top offset
	---@field [7] Sprite @Sprite object

	---@class EID_DescObj
	---@field ObjType integer
	---@field ObjVariant integer
	---@field ObjSubType integer
	---@field fullItemString string @String in `Type.Variant.SubType` format
	---@field Name string
	---@field Description string
	---@field Transformation string
	---@field ModName string
	---@field Quality integer
	---@field Icon EID_Icon
	---@field Entity Entity?
	---@field ShowWhenUnidentified boolean?
	---@field PermanentTextEnglish string?
	---@field IgnoreBulletPointIconConfig boolean?
	---@field ItemType integer?
	---@field ChargeType integer?
	---@field Charges integer? @Max charges

	--#endregion

	--#region Helper functions

	--- Small helper function for adding 'bookOfVirtuesWisps'-condition entries
	--- @param collectible CollectibleType
	--- @param description string
	local function addVirtuesCondition(collectible, description)
		EID:addToGeneralCondition(collectible, "bookOfVirtuesWisps", description)
	end

	--- Helper function to add an EID.XMLWisps entry
	--- @param collectible CollectibleType
	--- @param hp integer
	--- @param layer -1 | 0 | 1 | 2
	--- @param damage integer
	--- @param stageDamage number
	--- @param damageMultiplier2 number
	--- @param shotSpeed number
	--- @param fireDelay integer
	--- @param procChance number
	--- @param canShoot boolean
	--- @param amount integer
	--- @param tearFlags integer[]
	--- @param tearFlags2 integer[]
	--- @param additionalDesc? string
	local function addWispData(collectible, hp, layer, damage, stageDamage, damageMultiplier2, shotSpeed, fireDelay, procChance, canShoot, amount, tearFlags, tearFlags2, additionalDesc)
		if (EID.XMLWisps and not EID.XMLWisps[collectible]) then
			EID.XMLWisps[collectible] = {hp, layer, damage, stageDamage, damageMultiplier2, shotSpeed, fireDelay, procChance, canShoot, amount, tearFlags, tearFlags2}
			if (additionalDesc) then
				addVirtuesCondition(collectible, additionalDesc)
			end
		end
	end

	--#endregion

	local desc = ""

	--#region Collectibles

	--#region Almanach

	local almanach = enums.CollectibleType.COLLECTIBLE_ALMANACH
	desc = "Invokes the effects of 2 random 'book'-items#Can also invoke Books that haven't been unlocked yet"
	EID:addCollectible(almanach, desc)

	desc = "Spawns the appropriate wisps of the triggered books"
	addVirtuesCondition(almanach, desc)

	desc = "Book effects doubled"
	EID:addCarBatteryCondition(almanach, desc)
	--#endregion

	--#region Mending Heart

	local mendingHeart = enums.CollectibleType.COLLECTIBLE_MENDING_HEART
	desc = "Entering a new floor will replace 1{{BrokenHeart}} Broken Heart with 1{{EmptyHeart}} empty Heart Container#Will replace 2 instead, if no damage was taken on the previous floor#↑ +0.25 Damage per heart restored"
	EID:addCollectible(mendingHeart, desc)

	desc = "Increases amount of Broken Hearts to replace"
	EID:addCondition(mendingHeart, {mendingHeart, CollectibleType.COLLECTIBLE_DIPLOPIA, CollectibleType.COLLECTIBLE_CROOKED_PENNY}, desc)
	--#endregion

	--#region Devout Prayer

	local devoutPrayer = enums.CollectibleType.COLLECTIBLE_DEVOUT_PRAYER
	desc = "Can be used with 1+ charge(s)#Charges by killing enemies#{{EternalHeart}} Better effects while having an Eternal Heart#↑ +0.1 Luck for the floor per charge spent#Grants an additional effect at 3+, 6+ or 12 charges"
	EID:addCollectible(devoutPrayer, desc)

	desc = "Spawns 1 - 4 wisp(s), depending on charges spent ({{EternalHeart}} spawns {{Collectible"..CollectibleType.COLLECTIBLE_BIBLE.."}} Bible wisp(s) instead)"
	addWispData(devoutPrayer, 2, 1, 3, 0.1, 1, 0.75, 42, 1, true, 0, {2}, {-1}, desc)

	desc = "No Effect"
	EID:addCarBatteryCondition(devoutPrayer, desc)

	--#region Devout Prayer - modifiers

	--#region getChargeBasedEffect

	local DevoutPrayer_currentCharge = 0

	--- @param descObj EID_DescObj
	--- @return boolean?
	local function DevoutPrayer_getChargeBasedEffectCondition(descObj)
		-- only apply to "Devout Prayer"
		if ((descObj.ObjType == 5) and (descObj.ObjVariant == 100) and (descObj.ObjSubType == devoutPrayer)) then
			local player = EID.ItemReminderPlayerEntity
			--- @cast player EntityPlayer?
			if (player) then
				local slot = ActiveSlot.SLOT_PRIMARY
				if (EID.ItemReminderSelectedCategory == 4) then
					-- Category 4 is "Actives"
					if (player:GetActiveItem(ActiveSlot.SLOT_PRIMARY) ~= devoutPrayer) then
						slot = ActiveSlot.SLOT_SECONDARY
					end
				elseif (EID.ItemReminderSelectedCategory == 5) then
					-- Category 5 is "Pockets"
					slot = ActiveSlot.SLOT_POCKET
				end
				DevoutPrayer_currentCharge = player:GetActiveCharge(slot)
				if (DevoutPrayer_currentCharge >= 3) then return true end
			end
		end
		DevoutPrayer_currentCharge = 0
	end
	--- @param descObj EID_DescObj
	--- @return EID_DescObj
	local function DevoutPrayer_getChargeBasedEffectCallback(descObj)
		local addDesc = nil

		-- descriptions added from this modifier aren't altered by the hasEternalHeart modifier, so it's done here instead
		local hasEternalHeart = false
		local player = EID.ItemReminderPlayerEntity
		--- @cast player EntityPlayer?
		if (player) then
			hasEternalHeart = (player:GetEternalHearts() == 1)
		end

		local currentCharge = DevoutPrayer_currentCharge
		if ((currentCharge >= 3) and (currentCharge < 6)) then
			if (not hasEternalHeart) then
				addDesc = "3+ charges: Spawns an {{EternalHeart}} Eternal Heart"
			else
				addDesc = "3+ charges: Spawns an {{EternalHeart}} Eternal Heart and grants a {{HolyMantleSmall}} Holy Mantle shield"
			end
		elseif ((currentCharge >= 6) and (currentCharge < 12)) then
			if (not hasEternalHeart) then
				addDesc = "6+ charges: Spawns an {{HolyChest}} Eternal Chest"
			else
				addDesc = "6+ charges: Spawns an {{HolyChest}} Eternal Chest and {{AngelChanceSmall}} +10% Angel Room chance"
			end
		elseif (currentCharge >= 12) then
			local ddTaken = ddTracking:HasDevilDealBeenTaken()

			if (ddTaken == false) then
				if (not hasEternalHeart) then
					addDesc = "12 charges: Spawns 2 items (1 from current pool, 1 from Angel pool). Only 1 can be taken"
				else
					addDesc = "12 charges: Spawns 2 items (1 from current pool, 1 from Angel pool)"
				end
			else
				if (not hasEternalHeart) then
					addDesc = "12 charges: Spawns 2 items (1 from current pool, 1 from Devil pool (50% chance to be nothing)). Only 1 can be taken"
				else
					addDesc = "12 charges: Spawns 2 items (1 from current pool, 1 from Devil pool). Only 1 can be taken"
				end
			end
		end
		if (addDesc) then
			EID:appendToDescription(descObj, "#"..addDesc)
		end
		return descObj
	end
	EID:addDescriptionModifier("TheSaint_DevoutPrayer_getChargeBasedEffect", DevoutPrayer_getChargeBasedEffectCondition, DevoutPrayer_getChargeBasedEffectCallback)
	--#endregion
	--#region hasEternalHeart

	--- @param descObj EID_DescObj
	--- @return boolean?
	local function DevoutPrayer_hasEternalHeartCondition(descObj)
		-- only apply to "Devout Prayer"
		if ((descObj.ObjType == 5) and (descObj.ObjVariant == 100) and (descObj.ObjSubType == devoutPrayer)) then
			local player = EID.ItemReminderPlayerEntity
			--- @cast player EntityPlayer?
			if (player) then
				if (player:GetEternalHearts() == 1) then return true end
			end
		end
	end
	--- @param descObj EID_DescObj
	--- @return EID_DescObj
	local function DevoutPrayer_hasEternalHeartCallback(descObj)
		-- effectAddLuck is always displayed
		descObj.Description = (descObj.Description):gsub("+0.1 Luck for the floor per charge spent", "+0.1 Luck and +0.25 Damage for the floor per charge spent", 1)

		return descObj
	end
	EID:addDescriptionModifier("TheSaint_DevoutPrayer_hasEternalHeart", DevoutPrayer_hasEternalHeartCondition, DevoutPrayer_hasEternalHeartCallback)
	--#endregion
	--#endregion
	--#endregion

	--#region Divine Bombs

	local divineBombs = enums.CollectibleType.COLLECTIBLE_DIVINE_BOMBS
	desc = "{{Bomb}} +5 Bombs#{{Collectible"..CollectibleType.COLLECTIBLE_HOLY_LIGHT.."}} Isaac's bombs release a beam of light that hits nearby enemies"
	EID:addCollectible(divineBombs, desc)
	--#endregion

	--#region Wooden Key

	local woodenKey = enums.CollectibleType.COLLECTIBLE_WOODEN_KEY
	desc = "Chooses a random door in the current room and opens it if it is closed#Can open locked doors#Can open {{SecretRoom}}{{SuperSecretRoom}} Secret Rooms/Super Secret Rooms#{{Collectible"..CollectibleType.COLLECTIBLE_RED_KEY.."}} Can also create Red Room Doors"
	EID:addCollectible(woodenKey, desc)

	desc = "On death, invokes the effect of {{Collectible"..woodenKey.."}} Wooden Key"
	addWispData(woodenKey, 2, 0, 0, 0, 0, 0, 0, 1, false, 1, {-1}, {-1}, desc)

	EID:addCarBatteryCondition(woodenKey, {"a random door", "opens it if it is", "2{{CR}} random doors", "opens them if they are"})
	--#endregion

	--#region Holy Hand Grenade

	local holyHandGrenade = enums.CollectibleType.COLLECTIBLE_HOLY_HAND_GRENADE
	desc = "Using the item and firing in a direction throws the grenade#The grenade explodes after some time and releases a shockwave that kills every enemy in the room"
	EID:addCollectible(holyHandGrenade, desc)

	desc = "No Effect"
	EID:addCarBatteryCondition(holyHandGrenade, desc)

	EID.SingleUseCollectibles[holyHandGrenade] = true
	EID:AddSynergyConditional(holyHandGrenade, CollectibleType.COLLECTIBLE_VOID, "Void Single Use")
	EID:AddSynergyConditional(holyHandGrenade, "5.300.48", "? Card Single Use")
	--#endregion

	--#region Rite of Rebirth

	local riteOfRebirth = enums.CollectibleType.COLLECTIBLE_RITE_OF_REBIRTH
	desc = "↑ +1 Life"
	EID:addCollectible(riteOfRebirth, desc)

	--- @param descObj EID_DescObj
	--- @return boolean?
	local function RiteOfRebirth_notInBeastFightCondition(descObj)
		-- only apply to "Rite of Rebirth"
		if ((descObj.ObjType == 5) and (descObj.ObjVariant == 100) and (descObj.ObjSubType == riteOfRebirth)) then
			return (isc:inBeastRoom() == false)
		end
	end
	--- @param descObj EID_DescObj
	--- @return EID_DescObj
	local function RiteOfRebirth_notInBeastFightCallback(descObj)
		EID:appendToDescription(descObj, "#Isaac loses all items and pickups on death and revives in Lost form#Entering the next floor gives back everything that was taken away")
		return descObj
	end
	EID:addDescriptionModifier("TheSaint_RiteOfRebirth_notInBeastFight", RiteOfRebirth_notInBeastFightCondition, RiteOfRebirth_notInBeastFightCallback)
	--#endregion

	--#region Scorched Baby

	local scorchedBaby = enums.CollectibleType.COLLECTIBLE_SCORCHED_BABY
	desc = "{{Burning}} Shoots fire tears that set enemies ablaze#Deals 3.5 damage per tear"
	EID:addCollectible(scorchedBaby, desc)

	EID:addBFFSCondition(scorchedBaby, nil, 3.5, 7)
	--#endregion
	--#endregion

	--#region Trinkets

	--#region Holy Penny

	local holyPenny = enums.TrinketType.TRINKET_HOLY_PENNY
	desc = "{{EternalHeart}} Picking up a coin has a 17% chance to spawn an Eternal Heart#Higher chance from nickels and dimes"
	EID:addTrinket(holyPenny, desc)
	EID:addGoldenTrinketMetadataAdditive(holyPenny, nil, 17, {8, 13})
	--#endregion

	--#endregion

	--#region PocketItems

	-- Pocket Item icons
	local pocketIcons = Sprite()
	pocketIcons:Load("gfx/EID/eid_cardspills.anm2")

	--#region Library Card

	local libraryCard = enums.Card.CARD_LIBRARY
	EID:addIcon("Card"..libraryCard, "librarycard", 0, 16, 24, 4, 7, pocketIcons)
	desc = "{{Library}} Teleports Isaac to the Library"
	EID:addCard(libraryCard, desc)
	--#endregion

	--#region Soul of the Saint

	local soulOfTheSaint = enums.Card.CARD_SOUL_SAINT
	EID:addIcon("Card"..soulOfTheSaint, "soulofthesaint", 0, 32, 32, 4, 7, pocketIcons)
	desc = "{{AngelDevilChance}} Teleports Isaac to the Devil or Angel Room#{{AngelRoom}} Guarantees an Angel Room if it hasn't been generated yet#{{AngelRoom}} If Isaac hasn't taken any Devil Deal, allows all items to be taken"
	EID:addCard(soulOfTheSaint, desc)
	--#endregion

	--#endregion

	--#region Characters

	-- Character Icons
	local charIcons = Sprite()
	charIcons:Load("gfx/EID/eid_player_icons.anm2", true)

	--#region The Saint

	local saint = enums.PlayerType.PLAYER_THE_SAINT
	EID:addIcon("Player"..saint, "Players", 0, 16, 16, 0, 0, charIcons)

	desc = "{{AngelRoom}} Entering an Angel Room for the first time each floor has the following effects:#↑{{IND}} Increases one of the following stats, whichever is lowest:#↑{{IND}}{{IND}} +1 Damage#↑{{IND}}{{IND}} +0.5 Fire Rate#↑{{IND}}{{IND}} +0.2 Speed#↑{{IND}}{{IND}} +2.5 Range#{{IND}} Spawns either 3 {{Coin}} coins, 1 {{Bomb}} bomb or 1 {{Key}} key depending on what you have the least of"
	EID:addBirthright(saint, desc)
	--#endregion

	--#region Tainted Saint

	local tSaint = enums.PlayerType.PLAYER_THE_SAINT_B
	EID:addIcon("Player"..tSaint, "Players", 1, 16, 16, 0, 0, charIcons)

	desc = "Can't use {{SoulHeart}} Soul Hearts#When you take damage, turns all {{EmptyHeart}} empty Heart Containers into {{BrokenHeart}} Broken Hearts (doesn't apply to self-damage)"
	desc = desc.."#{{Collectible"..mendingHeart.."}} Entering a new floor will replace 1{{BrokenHeart}} Broken Heart with 1{{EmptyHeart}} empty Heart Container#{{Collectible"..mendingHeart.."}} Will replace 2 instead, if no damage was taken on the previous floor#{{Collectible"..mendingHeart.."}} ↑ +0.25 Damage per heart restored"
	EID:addCharacterInfo(tSaint, desc)

	desc = "Taking damage that causes penalties will only turn 1{{EmptyHeart}} empty Heart Container into a {{BrokenHeart}} Broken Heart"
	EID:addBirthright(tSaint, desc)

	-- Abaddon interaction
	desc = "{1} is left with half a heart and turns all other Heart Containers into Broken Hearts"
	EID:addPlayerCondition(CollectibleType.COLLECTIBLE_ABADDON, tSaint, desc)
	--#endregion

	--#endregion

end

--- @param mod ModUpgraded
function EIDRegistry:Init(mod)
	if (self.IsInitialized) then return end

	-- make sure EIDRegistry occurs regardless of mod loading order
	if EID then
		AddRegistry()
	else
		mod:AddCallback("EID_POST_LOAD", AddRegistry)
	end
end

return EIDRegistry
