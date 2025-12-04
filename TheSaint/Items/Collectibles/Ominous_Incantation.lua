local isc = require("TheSaint.lib.isaacscript-common")
local enums = require("TheSaint.Enums")

--- @class TheSaint.Items.Collectibles.Ominous_Incantation : TheSaint_Feature
local Ominous_Incantation = {
	IsInitialized = false,
	FeatureSubType = enums.CollectibleType.COLLECTIBLE_OMINOUS_INCANTATION,
	SaveDataKey = "Ominous_Incantation",
}

--#region Player Loadout

--- Represents the entire inventory of a player
--- @class PlayerLoadout
--- @field Pickups PlayerPickups
--- @field Collectibles CollectibleType[]
--- @field Trinkets TrinketType[]
--- @field Cards Card[]
--- @field Pills PillEffect[]
local PlayerLoadout = {}

--- Creates a new `PlayerLoadout` instance
--- @return PlayerLoadout
function PlayerLoadout.constuctor()
	--- @type PlayerLoadout
	local loadout = {
		Pickups = {
			Coins = 0,
			Bombs = 0,
			Keys = 0,
		},
		Collectibles = {},
		Trinkets = {},
		Cards = {},
		Pills = {},
	}
	return loadout
end

--- structure for number of player pickups
--- @class PlayerPickups
--- @field Coins integer
--- @field Bombs integer @ doesn't include giga bombs; number of poop pickups for T. Blue Baby
--- @field Keys integer
--- @field GigaBombs? integer
--- @field Charges? integer @ soul/blood charges

--- serializable version of `PlayerLayout`
--- @class SerializablePlayerLoadout
--- @field Pickups PlayerPickups
--- @field Collectibles CollectibleType[]
--- @field Trinkets TrinketType[]
--- @field Cards Card[]
--- @field Pills PillEffect[]

--- @param serializableLoadout SerializablePlayerLoadout
--- @return PlayerLoadout
function PlayerLoadout.fromSerializable(serializableLoadout)
	local loadout = PlayerLoadout.constuctor()

	loadout.Pickups = serializableLoadout.Pickups
	loadout.Collectibles = serializableLoadout.Collectibles
	loadout.Trinkets = serializableLoadout.Trinkets
	loadout.Cards = serializableLoadout.Cards
	loadout.Pills = serializableLoadout.Pills

	return loadout
end

--- @return SerializablePlayerLoadout
function PlayerLoadout:serialize()
	--- @type SerializablePlayerLoadout
	local serializableLoadout = {
		Pickups = self.Pickups,
		Collectibles = self.Collectibles,
		Trinkets = self.Trinkets,
		Cards = self.Cards,
		Pills = self.Pills,
	}
	return serializableLoadout
end

--- @param coins integer
--- @param bombs integer
--- @param keys integer
--- @param gigaBombs? integer
--- @param charges? integer
function PlayerLoadout:setPickups(coins, bombs, keys, gigaBombs, charges)
	self.Pickups.Coins = coins
	self.Pickups.Bombs = bombs
	self.Pickups.Keys = keys
	self.Pickups.GigaBombs = gigaBombs
	self.Pickups.Charges = charges
end

--- @param player EntityPlayer
function PlayerLoadout:setPickupsFromPlayer(player)
	local playerType = player:GetPlayerType()

	local bombs = 0
	local gigaBombs = nil
	local charges = nil

	if (playerType == PlayerType.PLAYER_BLUEBABY_B) then
		bombs = player:GetPoopMana()
	else
		gigaBombs = player:GetNumGigaBombs()
		bombs = (player:GetNumBombs() - gigaBombs)
		if (playerType == PlayerType.PLAYER_BETHANY) then
			charges = player:GetSoulCharge()
		elseif (playerType == PlayerType.PLAYER_BETHANY_B) then
			charges = player:GetBloodCharge()
		end
	end

	self:setPickups(player:GetNumCoins(), bombs, player:GetNumKeys(), gigaBombs, charges)
end

--- @param collectibles CollectibleType | CollectibleType[]
function PlayerLoadout:setCollectibles(collectibles)
	if (type(collectibles) ~= "table") then collectibles = {collectibles} end
	self.Collectibles = collectibles
end

--- @param mod ModUpgraded
--- @param player EntityPlayer
function PlayerLoadout:setCollectiblesFromPlayer(mod, player)
	self.Collectibles = mod:getPlayerCollectibleTypes(player)
end

--- @param trinkets TrinketType | TrinketType[]
function PlayerLoadout:setTrinkets(trinkets)
	if (type(trinkets) ~= "table") then trinkets = {trinkets} end
	self.Trinkets = trinkets
end

--- @param player EntityPlayer
function PlayerLoadout:setTrinketsFromPlayer(player)
	--- @type TrinketType[]
	local trinkets = {}

	for i = 0, 1 do
		local trinket = player:GetTrinket(i)
		if (trinket ~= TrinketType.TRINKET_NULL) then
			table.insert(trinkets, trinket)
		end
	end

	self.Trinkets = trinkets
end

--- @param cards Card | Card[]
function PlayerLoadout:setCards(cards)
	if (type(cards) ~= "table") then cards = {cards} end
	self.Cards = cards
end

--- @param player EntityPlayer
function PlayerLoadout:setCardsFromPlayer(player)
	--- @type Card[]
	local cards = {}

	for _, pocketItem in ipairs(isc:getPocketItems(player)) do
		if (pocketItem.type == isc.PocketItemType.CARD) then
			table.insert(cards, pocketItem.subType)
		end
	end

	self.Cards = cards
end

--- @param pills PillEffect | PillEffect[]
function PlayerLoadout:setPills(pills)
	if (type(pills) ~= "table") then pills = {pills} end
	self.Pills = pills
end

--- @param player EntityPlayer
function PlayerLoadout:setPillsFromPlayer(player)
	--- @type PillEffect[]
	local pills = {}

	for _, pocketItem in ipairs(isc:getPocketItems(player)) do
		if (pocketItem.type == isc.PocketItemType.PILL) then
			table.insert(pills, pocketItem.subType)
		end
	end

	self.Pills = pills
end

--- @param mod ModUpgraded
--- @param player EntityPlayer
--- @return PlayerLoadout
function PlayerLoadout.createFromPlayer(mod, player)
	local loadout = PlayerLoadout.constuctor()

	loadout:setPickupsFromPlayer(player)
	loadout:setCollectiblesFromPlayer(mod, player)
	loadout:setTrinketsFromPlayer(player)
	loadout:setCardsFromPlayer(player)
	loadout:setPillsFromPlayer(player)

	return loadout
end

--#endregion

local v = {
	run = {
		--- @type table<string, SerializablePlayerLoadout>
		Default_PlayerLoadouts = {},
		--- @type table<string, SerializablePlayerLoadout>
		PlayerLoadouts = {},
	}
}

--- Save the given player's current loadout
--- @param mod ModUpgraded
--- @param player EntityPlayer
--- @param isStartingLoadout? boolean @ default: `false`
local function saveLoadout(mod, player, isStartingLoadout)
	local playerIndex = "OI_Loadout_"..isc:getPlayerIndex(player)

	local loadout = PlayerLoadout.constuctor()
	loadout:setPickupsFromPlayer(player)
	loadout:setCollectiblesFromPlayer(mod, player)

	--- @type table<string, SerializablePlayerLoadout>
	local loadoutTable
	if (isStartingLoadout) then
		loadoutTable = v.run.Default_PlayerLoadouts
	else
		loadoutTable = v.run.PlayerLoadouts
	end
	loadoutTable[playerIndex] = loadout:serialize()
end

--- @param mod ModUpgraded
--- @param player EntityPlayer
local function postPlayerInit(mod, player)
	--saveLoadout(mod, player, true)
end

--- @param player EntityPlayer
local function preCustomRevive(_, player)
	if (player:HasCollectible(Ominous_Incantation.FeatureSubType)) then
		return Ominous_Incantation.FeatureSubType
	end
	return nil
end

--- @param mod ModUpgraded
--- @param player EntityPlayer
--- @param revivalType integer
local function postCustomRevive(mod, player, revivalType)
	player:RemoveCollectible(Ominous_Incantation.FeatureSubType)
	--saveLoadout(mod, player)
	isc:useActiveItemTemp(player, CollectibleType.COLLECTIBLE_R_KEY)
end

--- @param mod ModUpgraded
function Ominous_Incantation:Init(mod)
	--mod:saveDataManager(self.SaveDataKey, v)

	-- want to run some callbacks pretty late, so using priority of 1000
	local priorityVeryLate = 1000

	--- @diagnostic disable-next-line
	mod:AddPriorityCallback(ModCallbacks.MC_POST_PLAYER_INIT, priorityVeryLate, postPlayerInit, 0)
	mod:AddPriorityCallbackCustom(isc.ModCallbackCustom.PRE_CUSTOM_REVIVE, priorityVeryLate, preCustomRevive, 0)
	mod:AddCallbackCustom(isc.ModCallbackCustom.POST_CUSTOM_REVIVE, postCustomRevive, self.FeatureSubType)
end

return Ominous_Incantation
