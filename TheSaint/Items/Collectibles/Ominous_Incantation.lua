-- if REPENTOGON then

-- 	--#region Repentogon

-- 	local isc = require("TheSaint.lib.isaacscript-common")
-- 	local enums = require("TheSaint.Enums")
-- 	local PlayerLoadout = require("TheSaint.classes.PlayerLoadout")

-- 	--- (Repentogon version)
-- 	--- - Grants an extra life.
-- 	--- - Player will revive in the starting room of the current floor and lose the following:
-- 	---   - all passive and active items (except innate passives)
-- 	---   - all held trinkets
-- 	---   - all held pocket items (except pocket actives)
-- 	--- - Player will also be in Lost form (i.e. white fireplace in Downpour II/Dross II).
-- 	--- - Spawns a special enemy in the room the player had died.
-- 	---   - Killing it restores the player to their original form and gives back their items
-- 	--- - Works as a normal extra life when fighting "The Beast"
-- 	--- @class TheSaint.Items.Collectibles.Ominous_Incantation : TheSaint_Feature
-- 	local Ominous_Incantation = {
-- 		IsInitialized = false,
-- 		FeatureSubType = enums.CollectibleType.COLLECTIBLE_OMINOUS_INCANTATION,
-- 		SaveDataKey = "Ominous_Incantation",
-- 	}

-- 	--- @type ModUpgraded
-- 	local thisMod

-- 	local RevivalState = {
-- 		NONE = 0,
-- 		USE_GENESIS = 1,
-- 		USE_R_KEY = 2,
-- 	}

-- 	local currentRevivalState = RevivalState.NONE
-- 	--- @type EntityPlayer?
-- 	local currentRevivalPlayer = nil

-- 	local v = {
-- 		run = {
-- 			--- @type table<string, SerializablePlayerLoadout>
-- 			PlayerLoadouts = {},
-- 		}
-- 	}

-- 	--- Save the given player's current loadout
-- 	--- @param player EntityPlayer
-- 	local function saveLoadout(player)
-- 		local playerIndex = "OI_Loadout_"..isc:getPlayerIndex(player)

-- 		local loadout = PlayerLoadout.createFromPlayer(thisMod, player)

-- 		v.run.PlayerLoadouts[playerIndex] = loadout:serialize()
-- 	end

-- 	--- @param player EntityPlayer
-- 	--- @return SerializablePlayerLoadout
-- 	local function getLoadout(player)
-- 		local playerIndex = "OI_Loadout_"..isc:getPlayerIndex(player)
-- 		return v.run.PlayerLoadouts[playerIndex]
-- 	end

-- 	--- @param player EntityPlayer
-- 	local function preCustomRevive(_, player)
-- 		if (player:HasCollectible(Ominous_Incantation.FeatureSubType)) then
-- 			return Ominous_Incantation.FeatureSubType
-- 		end
-- 		return nil
-- 	end

-- 	--- @param player EntityPlayer
-- 	--- @param revivalType integer
-- 	local function postCustomRevive(_, player, revivalType)
-- 		player:RemoveCollectible(Ominous_Incantation.FeatureSubType)

-- 		-- during "The Beast" fight, functions as a simple extra life
-- 		if (isc:inBeastRoom()) then
-- 			player:AnimateCollectible(Ominous_Incantation.FeatureSubType)
-- 		else
-- 			saveLoadout(player)
-- 			currentRevivalPlayer = player
-- 			currentRevivalState = RevivalState.USE_GENESIS
-- 			isc:useActiveItemTemp(player, CollectibleType.COLLECTIBLE_GENESIS)
-- 		end
-- 	end

-- 	--- @param room RoomType
-- 	local function postNewRoomEarly(_, room)
-- 		if (currentRevivalState == RevivalState.USE_GENESIS) then
-- 			currentRevivalState = RevivalState.USE_R_KEY
-- 			isc:useActiveItemTemp(currentRevivalPlayer, CollectibleType.COLLECTIBLE_R_KEY)
-- 		end
-- 	end

-- 	--- @param stage LevelStage
-- 	--- @param stageType StageType
-- 	local function postNewLevelReordered(_, stage, stageType)
-- 		if (currentRevivalState == RevivalState.USE_R_KEY) then
-- 			currentRevivalState = RevivalState.NONE
-- 			if (currentRevivalPlayer) then
-- 				currentRevivalPlayer:AnimateCollectible(Ominous_Incantation.FeatureSubType)
-- 				currentRevivalPlayer = nil
-- 			end
-- 		end
-- 	end

-- 	--- @param mod ModUpgraded
-- 	function Ominous_Incantation:Init(mod)
-- 		if (self.IsInitialized) then return end

-- 		thisMod = mod

-- 		mod:saveDataManager(self.SaveDataKey, v)

-- 		-- want to run this callback pretty late, so using priority of 1000
-- 		mod:AddPriorityCallbackCustom(isc.ModCallbackCustom.PRE_CUSTOM_REVIVE, 1000, preCustomRevive, 0)
-- 		mod:AddCallbackCustom(isc.ModCallbackCustom.POST_CUSTOM_REVIVE, postCustomRevive, self.FeatureSubType)
-- 		mod:AddCallbackCustom(isc.ModCallbackCustom.POST_NEW_ROOM_EARLY, postNewRoomEarly)
-- 		mod:AddCallbackCustom(isc.ModCallbackCustom.POST_NEW_LEVEL_REORDERED, postNewLevelReordered)
-- 	end

-- 	return Ominous_Incantation

-- 	--#endregion

-- else

	--#region Vanilla

	local isc = require("TheSaint.lib.isaacscript-common")
	local enums = require("TheSaint.Enums")
	local PlayerLoadout = require("TheSaint.classes.PlayerLoadout")

	local game = Game()

	--- (Vanilla version)
	--- - Grants an extra life.
	--- - Upon revival, player loses the following:
	---   - all pickups (coins, bombs, keys, etc.)
	---   - all passive and active items (except innate passives)
	---   - all held trinkets
	---   - all held pocket items (except pocket actives)
	--- - Player will also be in Lost form (i.e. white fireplace in Downpour II/Dross II) while on the current floor.
	--- - Entering a new floor will revert the player back to their original form and gives back their lost items.
	---   - any collectible/trinket that cannot be added to the player will be spawned in instead.
	--- - Works as a normal extra life when fighting "The Beast".
	--- @class TheSaint.Items.Collectibles.Ominous_Incantation : TheSaint_Feature
	local Ominous_Incantation = {
		IsInitialized = false,
		FeatureSubType = enums.CollectibleType.COLLECTIBLE_OMINOUS_INCANTATION,
		SaveDataKey = "Ominous_Incantation",
	}

	local v = {
		run = {
			--- @type table<string, SerializablePlayerLoadout>
			PlayerLoadouts = {},
		}
	}

	--#region PlayerLoadout helper

	--- Clears the saved loadout of the given player
	--- @param player EntityPlayer
	local function clearLoadout(player)
		local playerIndex = "OI_Loadout_"..isc:getPlayerIndex(player)
		v.run.PlayerLoadouts[playerIndex] = nil
	end

	--- Gets the saved loadout for the given player, or `nil` if it doesn't exist
	--- @param player EntityPlayer
	--- @return SerializablePlayerLoadout?
	local function getLoadout(player)
		local playerIndex = "OI_Loadout_"..isc:getPlayerIndex(player)
		return v.run.PlayerLoadouts[playerIndex]
	end

	--- Save the given player's current loadout
	--- @param player EntityPlayer
	local function saveLoadout(player)
		local playerIndex = "OI_Loadout_"..isc:getPlayerIndex(player)

		local loadout = PlayerLoadout.createFromPlayer(player)
		loadout.Collectibles.Passive = isc:filter(loadout.Collectibles.Passive, function (_, passiveItem)
			return (passiveItem ~= Ominous_Incantation.FeatureSubType)
		end)

		v.run.PlayerLoadouts[playerIndex] = loadout:serialize()
	end

	--#endregion

	--- @param player EntityPlayer
	local function preCustomRevive(_, player)
		if (player:HasCollectible(Ominous_Incantation.FeatureSubType)) then
			return Ominous_Incantation.FeatureSubType
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
			--- @param activeItem CollectibleType
			isc:forEach(loadout.Collectibles.Active, function (_, activeItem)
				player:RemoveCollectible(activeItem)
			end)
			--- @param passiveItem CollectibleType
			isc:forEach(loadout.Collectibles.Passive, function (_, passiveItem)
				player:RemoveCollectible(passiveItem)
			end)

			-- Trinkets
			--- @param trinket TrinketType
			isc:forEach(loadout.Trinkets, function (_, trinket)
				player:TryRemoveTrinket(trinket)
			end)

			-- Cards/Pills
			player:SetCard(0, Card.CARD_NULL)
			player:SetCard(1, Card.CARD_NULL)
		end
	end

	--- @param player EntityPlayer
	--- @param revivalType integer
	local function postCustomRevive(_, player, revivalType)
		player:RemoveCollectible(Ominous_Incantation.FeatureSubType)

		-- during "The Beast" fight, functions as a simple extra life
		if (isc:inBeastRoom() == false) then
			saveLoadout(player)
			local effects = player:GetEffects()

			--- adding 3 makes this effect permanent, and it must be removed manually
			effects:AddNullEffect(NullItemID.ID_LOST_CURSE, true, 3)

			clearInventory(player)
		end
		player:AnimateCollectible(Ominous_Incantation.FeatureSubType)
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

		-- Collectibles
		local room = game:GetRoom()
		local pos = Vector.Zero

		-- passives must be granted first, in case of items that give additional active/trinket/pocket slots
		--- @param passiveItem CollectibleType
		isc:forEach(loadout.Collectibles.Passive, function (_, passiveItem)
			player:AddCollectible(passiveItem)
		end)

		-- next come actives
		--- @param activeItem CollectibleType
		isc:forEach(loadout.Collectibles.Active, function (_, activeItem)
			if (isc:hasOpenActiveItemSlot(player)) then
				player:AddCollectible(activeItem)
			else
				pos = room:FindFreePickupSpawnPosition(player.Position, 0, true)
				Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, activeItem, pos, Vector.Zero, player)
			end
		end)

		-- Trinkets
		--- @param trinket TrinketType
		isc:forEach(loadout.Collectibles, function (_, trinket)
			if (isc:hasOpenTrinketSlot(player)) then
				player:AddTrinket(trinket)
			else
				pos = room:FindFreePickupSpawnPosition(player.Position, 0, true)
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
				pos = room:FindFreePickupSpawnPosition(player.Position, 0, true)
				Isaac.Spawn(EntityType.ENTITY_PICKUP, variant, pocketItem.ID, pos, Vector.Zero, player)
			end
		end)
	end

	--- @param stage LevelStage
	--- @param stageType StageType
	local function postNewLevelReordered(_, stage, stageType)
		for i = 0, game:GetNumPlayers() - 1 do
			local player = Isaac.GetPlayer(i)
			local loadout = getLoadout(player)
			if (loadout) then
				player:GetEffects():RemoveNullEffect(NullItemID.ID_LOST_CURSE, -1)
				restoreInventory(player, loadout)
				clearLoadout(player)
			end
		end
	end

	--- @param mod ModUpgraded
	function Ominous_Incantation:Init(mod)
		if (self.IsInitialized) then return end

		self.ThisMod = mod

		mod:saveDataManager(self.SaveDataKey, v)

		-- want to run this callback pretty late, so using priority of 1000
		mod:AddPriorityCallbackCustom(isc.ModCallbackCustom.PRE_CUSTOM_REVIVE, 1000, preCustomRevive, 0)
		mod:AddCallbackCustom(isc.ModCallbackCustom.POST_CUSTOM_REVIVE, postCustomRevive, self.FeatureSubType)
		mod:AddCallbackCustom(isc.ModCallbackCustom.POST_NEW_LEVEL_REORDERED, postNewLevelReordered)
	end

	return Ominous_Incantation

	--#endregion

-- end
