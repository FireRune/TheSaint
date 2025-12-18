local isc = require("TheSaint.lib.isaacscript-common")
local enums = require("TheSaint.Enums")
local PlayerLoadout = require("TheSaint.classes.PlayerLoadout")
local featureTarget = require("TheSaint.structures.FeatureTarget")

--#region Repentogon
-- if REPENTOGON then

-- 	--- (Repentogon version)
-- 	--- - Grants an extra life.
-- 	--- - Upon revival:
-- 	---   - Resets the player (like "Genesis").
-- 	---   - Player will be in Lost form (i.e. white fireplace in "Downpour/Dross II").
-- 	---   - Brings them to the starting room of the 1st floor.
-- 	---   - If applicable, enforces the same route taken during the run, depending on where the player died:
-- 	---     - "Cathedral" or "Chest" -> "Polaroid" path, doors to alt. path won't appear
-- 	---     - "Sheol" or "Dark Room" -> "Negative" path, doors to alt. path won't appear
-- 	---     - "Mausoleum/Gehenna II" (alt. path), "Corpse I/II" -> doors to alt. path unlock automatically, regular path unavailable
-- 	---     - "Mausoleum/Gehenna II" (Ascent) -> door to "Mausoleum/Gehenna I" won't appear, "A Strange Door" will be open; no trapdoor after beating "Mom", but the room can be exited normally
-- 	---   - In the starting room of the floor the player died in, spawns a portal to a special room:
-- 	---     - Contains a special enemy.
-- 	---     - Killing it restores the corresponding player to their normal form and grants everything they've lost.
-- 	--- - Works as a normal extra life during the "Ascent".
-- 	--- @class TheSaint.Items.Collectibles.Rite_of_Rebirth : TheSaint.classes.ModFeatureTargeted<CollectibleType>
-- 	local Rite_of_Rebirth = {
-- 		IsInitialized = false,
--		Target = featureTarget:new(enums.CollectibleType.COLLECTIBLE_RITE_OF_REBIRTH),
-- 		SaveDataKey = "Rite_of_Rebirth",
-- 	}

-- 	return Rite_of_Rebirth

-- else
-- end
--#endregion

--#region Vanilla

local game = Game()

--- (Vanilla version)
--- - Grants an extra life.
--- - Upon revival, player loses the following:
---   - all pickups (coins, bombs, keys, etc.)
---   - all passive and active items (except innate passives)
---   - all held trinkets
---   - all held pocket items (except pocket actives)
--- - Player will also be in Lost form (i.e. white fireplace in "Downpour/Dross II") while on the current floor.
--- - Entering a new floor will revert the player back to their original form and gives back their lost items.
---   - any collectible/trinket that cannot be added to the player will be spawned in instead.
--- - Works as a normal extra life when fighting "The Beast".
--- @class TheSaint.Items.Collectibles.Rite_of_Rebirth : TheSaint.classes.ModFeatureTargeted<CollectibleType>
local Rite_of_Rebirth = {
	IsInitialized = false,
	--- @type TheSaint.structures.FeatureTarget<CollectibleType>
	Target = featureTarget:new(enums.CollectibleType.COLLECTIBLE_RITE_OF_REBIRTH),
	SaveDataKey = "Rite_of_Rebirth",
}

local v = {
	run = {
		--- @type table<string, SerializablePlayerLoadout>
		PlayerLoadouts = {},
	},
	level = {
		NextPickupPosition_Index = 1,
	}
}

--#region PlayerLoadout helper

--- Clears the saved loadout of the given player
--- @param player EntityPlayer
local function clearLoadout(player)
	local playerIndex = "RoR_Loadout_"..isc:getPlayerIndex(player)
	v.run.PlayerLoadouts[playerIndex] = nil
end

--- Gets the saved loadout for the given player, or `nil` if it doesn't exist
--- @param player EntityPlayer
--- @return SerializablePlayerLoadout?
local function getLoadout(player)
	local playerIndex = "RoR_Loadout_"..isc:getPlayerIndex(player)
	return v.run.PlayerLoadouts[playerIndex]
end

--- Save the given player's current loadout
--- @param player EntityPlayer
local function saveLoadout(player)
	local playerIndex = "RoR_Loadout_"..isc:getPlayerIndex(player)

	local loadout = PlayerLoadout.createFromPlayer(player)
	loadout.Collectibles.Passive = isc:filter(loadout.Collectibles.Passive, function (_, passiveItem)
		return (passiveItem ~= Rite_of_Rebirth.Target.Type)
	end)

	v.run.PlayerLoadouts[playerIndex] = loadout:serialize()
end

--#endregion

--- @param player EntityPlayer
local function preCustomRevive(_, player)
	if (player:HasCollectible(Rite_of_Rebirth.Target.Type)) then
		return Rite_of_Rebirth.Target.Type
	end
	return nil
end

--- @param player EntityPlayer
local function clearInventory(player)
	local loadout = getLoadout(player)
	if (loadout) then
		-- Pickups
		local pickups = loadout.Pickups
		local playerType = player:GetPlayerType()

		player:AddCoins(-pickups.Coins)
		if (playerType == PlayerType.PLAYER_BLUEBABY_B) then
			player:AddPoopMana(-pickups.Bombs)
		else
			player:AddGigaBombs(-pickups.GigaBombs)
			player:AddBombs(-pickups.Bombs)
		end
		player:AddKeys(-pickups.Keys)
		if (playerType == PlayerType.PLAYER_BETHANY) then
			player:SetSoulCharge(0)
		elseif (playerType == PlayerType.PLAYER_BETHANY_B) then
			player:SetBloodCharge(0)
		end

		-- Collectibles
		--- @param activeItem PlayerActiveItem
		isc:forEach(loadout.Collectibles.Active, function (_, activeItem)
			player:RemoveCollectible(activeItem.ID, nil, nil, false)
		end)
		--- @param passiveItem CollectibleType
		isc:forEach(loadout.Collectibles.Passive, function (_, passiveItem)
			player:RemoveCollectible(passiveItem, nil, nil, false)
		end)

		-- Trinkets
		--- @param trinket TrinketType
		isc:forEach(loadout.Trinkets, function (_, trinket)
			player:TryRemoveTrinket(trinket)
		end)

		-- Cards/Pills
		--- @param pocketItem { slot: integer, type: integer, subType: integer }
		isc:forEach(isc:getPocketItems(player), function (_, pocketItem)
			if (pocketItem.type ~= isc.PocketItemType.ACTIVE_ITEM) then
				player:SetCard(pocketItem.slot, Card.CARD_NULL)
			end
		end)
	end
end

--- @param player EntityPlayer
--- @param revivalType integer
local function postCustomRevive(_, player, revivalType)
	player:RemoveCollectible(Rite_of_Rebirth.Target.Type)

	-- during "The Beast" fight, functions as a simple extra life
	if (isc:inBeastRoom() == false) then
		saveLoadout(player)
		local effects = player:GetEffects()

		--- adding 3 makes this effect permanent, and it must be removed manually
		effects:AddNullEffect(NullItemID.ID_LOST_CURSE, true, 3)

		clearInventory(player)
	end
	player:AnimateCollectible(Rite_of_Rebirth.Target.Type)
end

--[[
starting from grid idx 17, goes clockwise
### ### ### ### ### ### ### ### ### ### ### ### ### ### ###
### ---  17  18  19  20  21 ---  23  24  25  26  27 --- ###
###  31 --- --- --- --- --- --- --- --- --- --- ---  43 ###
###  46 ---  48  49  50  51 ---  53  54  55  56 ---  58 ###
### --- --- ---  64  65 --- --- ---  69  70 --- --- --- ###
###  76 ---  78  79  80  81 ---  83  84  85  86 ---  88 ###
###  91 --- --- --- --- --- --- --- --- --- --- --- 103 ###
### --- 107 108 109 110 111 --- 113 114 115 116 117 --- ###
### ### ### ### ### ### ### ### ### ### ### ### ### ### ###
]]
local pickupPositionGridIndexes = {
	17, 18, 19, 20, 21, 23, 24, 25, 26, 27, 43, 58,
	88, 103, 117, 116, 115, 114, 113, 111, 110, 109, 108, 107,
	91, 76, 46, 31, 48, 49, 50, 51, 53, 54, 55, 56,
	86, 85, 84, 83, 81, 80, 79, 78, 64, 65, 69, 70
}
--- @return Vector
local function getNextPickupPosition()
	local index = v.level.NextPickupPosition_Index
	local room = game:GetRoom()

	if ((index < 1) or (index > #pickupPositionGridIndexes)) then
		return room:FindFreePickupSpawnPosition(room:GetCenterPos(), nil, true)
	end

	local gridIndex = pickupPositionGridIndexes[index]
	v.level.NextPickupPosition_Index = (index + 1)
	return room:GetGridPosition(gridIndex)
end

--- @param player EntityPlayer
--- @param loadout SerializablePlayerLoadout
local function restoreInventory(player, loadout)
	-- Pickups
	local pickups = loadout.Pickups
	local playerType = player:GetPlayerType()

	player:AddCoins(pickups.Coins)
	if (playerType == PlayerType.PLAYER_BLUEBABY_B) then
		player:AddPoopMana(pickups.Bombs)
	else
		player:AddBombs(pickups.Bombs)
		player:AddGigaBombs(pickups.GigaBombs)
	end
	player:AddKeys(pickups.Keys)
	if (playerType == PlayerType.PLAYER_BETHANY) then
		player:AddSoulCharge(pickups.Charges)
	elseif (playerType == PlayerType.PLAYER_BETHANY_B) then
		player:AddBloodCharge(pickups.Charges)
	end

	local pos = Vector.Zero

	-- Collectibles
	-- passives must be granted first, in case of items that give additional active/trinket/pocket slots
	local passives = loadout.Collectibles.Passive

	--- @type EntityPickup?
	local entCollectible = nil

	-- special handling for Tainted Isaac's passive limit of 8 slots (or 12 with "Birthright")
	local isTaintedIsaac = (player:GetPlayerType() == PlayerType.PLAYER_ISAAC_B)
	local hasBirthright = player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT)

	if (isTaintedIsaac) then
		local numCurrentPassives = #(Rite_of_Rebirth.ThisMod:getPlayerCollectibleTypes(player, false))
		if (hasBirthright == true) then
			numCurrentPassives = (numCurrentPassives - 1)
		end

		--- @param collectible CollectibleType
		if (isc:find(passives, function (_, collectible) return (collectible == CollectibleType.COLLECTIBLE_BIRTHRIGHT) end) == true) then
			if (hasBirthright == false) then
				player:AddCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT, nil, false)
				hasBirthright = true
			end
			passives = isc:filter(passives, function (_, collectible)
				return (collectible ~= CollectibleType.COLLECTIBLE_BIRTHRIGHT)
			end)
		end

		local maxPassives = ((hasBirthright and 12) or 8)
		--- @param passiveItem CollectibleType
		isc:forEach(passives, function (_, passiveItem)
			if (numCurrentPassives < maxPassives) then
				player:AddCollectible(passiveItem, nil, false)
				numCurrentPassives = (numCurrentPassives + 1)
			else
				pos = getNextPickupPosition()
				entCollectible = Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, passiveItem, pos, Vector.Zero, player):ToPickup()
				if (entCollectible) then
					isc:preventCollectibleRotation(entCollectible)
				end
			end
		end)
	else
		--- @param passiveItem CollectibleType
		isc:forEach(passives, function (_, passiveItem)
			player:AddCollectible(passiveItem, nil, false)
		end)
	end

	-- next come actives
	--- @param activeItem PlayerActiveItem
	isc:forEach(loadout.Collectibles.Active, function (_, activeItem)
		if (isc:hasOpenActiveItemSlot(player)) then
			player:AddCollectible(activeItem.ID, activeItem.Charge, false)
		else
			pos = getNextPickupPosition()
			entCollectible = Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, activeItem.ID, pos, Vector.Zero, player):ToPickup()
			if (entCollectible) then
				isc:preventCollectibleRotation(entCollectible)
			end
		end
	end)

	-- Trinkets
	--- @param trinket TrinketType
	isc:forEach(loadout.Collectibles, function (_, trinket)
		if (isc:hasOpenTrinketSlot(player)) then
			player:AddTrinket(trinket, false)
		else
			pos = getNextPickupPosition()
			Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TRINKET, trinket, pos, Vector.Zero, player)
		end
	end)

	-- Cards/Pills
	--- @type { IsCard: boolean, ID: Card | PillColor }[]
	local pocketItems = {}
	--- @param card Card
	isc:forEach(loadout.Cards, function (_, card)
		table.insert(pocketItems, {IsCard = true, ID = card})
	end)
	--- @param pill PillColor
	isc:forEach(loadout.Pills, function (_, pill)
		table.insert(pocketItems, {IsCard = false, ID = pill})
	end)

	--- @param pocketItem { IsCard: boolean, ID: Card | PillColor }
	isc:forEach(pocketItems, function (_, pocketItem)
		if (isc:hasOpenPocketItemSlot(player)) then
			if (pocketItem.IsCard) then
				player:AddCard(pocketItem.ID)
			else
				player:AddPill(pocketItem.ID)
			end
		else
			local variant = ((pocketItem.IsCard and PickupVariant.PICKUP_TAROTCARD) or PickupVariant.PICKUP_PILL)
			pos = getNextPickupPosition()
			Isaac.Spawn(EntityType.ENTITY_PICKUP, variant, pocketItem.ID, pos, Vector.Zero, player)
		end
	end)
end

--- @param stage LevelStage
--- @param stageType StageType
local function postNewLevelReordered(_, stage, stageType)
	--- @type EntityPlayer[]
	local players = {}
	for i = 0, game:GetNumPlayers() - 1 do
		local player = Isaac.GetPlayer(i)
		table.insert(players, player)
		local pType = player:GetPlayerType()
		-- Tainted Lazarus' inactive form must be handled as well
		if ((pType == PlayerType.PLAYER_LAZARUS_B) or (pType == PlayerType.PLAYER_LAZARUS2_B)) then
			local player2 = Rite_of_Rebirth.ThisMod:getTaintedLazarusSubPlayer(player)
			table.insert(players, player2)
		end
	end

	--- @param player EntityPlayer
	isc:forEach(players, function (_, player)
		local loadout = getLoadout(player)
		if (loadout) then
			player:GetEffects():RemoveNullEffect(NullItemID.ID_LOST_CURSE, -1)
			restoreInventory(player, loadout)
			clearLoadout(player)
		end
	end)
end

--- @param mod ModUpgraded
function Rite_of_Rebirth:Init(mod)
	if (self.IsInitialized) then return end

	self.ThisMod = mod

	mod:saveDataManager(self.SaveDataKey, v)

	-- want to run this callback pretty late, so using priority of 1000
	mod:AddPriorityCallbackCustom(isc.ModCallbackCustom.PRE_CUSTOM_REVIVE, 1000, preCustomRevive, 0)
	mod:AddCallbackCustom(isc.ModCallbackCustom.POST_CUSTOM_REVIVE, postCustomRevive, self.Target.Type)
	mod:AddCallbackCustom(isc.ModCallbackCustom.POST_NEW_LEVEL_REORDERED, postNewLevelReordered)
end

return Rite_of_Rebirth

--#endregion
