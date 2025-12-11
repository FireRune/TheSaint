local isc = require("TheSaint.lib.isaacscript-common")

--#region typedef

--- structure for number of player pickups
--- @class PlayerPickups
--- @field Coins integer
--- @field Bombs integer @ doesn't include giga bombs; number of poop pickups for T. Blue Baby
--- @field Keys integer
--- @field GigaBombs integer
--- @field Charges integer @ soul/blood charges

--- @class PlayerLoadoutBase
--- @field Pickups PlayerPickups
--- @field Collectibles { Active: CollectibleType[], Passive: CollectibleType[] }
--- @field Trinkets TrinketType[]
--- @field Cards Card[]
--- @field Pills PillColor[]

--- serializable version of `PlayerLayout`
--- @class SerializablePlayerLoadout : PlayerLoadoutBase

--#endregion

--- Represents the entire inventory of a player
--- @class PlayerLoadout : PlayerLoadoutBase
local PlayerLoadout = {}

local isRegistered = false
--- @type ModUpgraded
local thisMod

local function checkIsRegistered()
	if (isRegistered == false) then
		error("[TheSaint] attempted to access a static member of class 'PlayerLoadout' without registering an object of type 'ModUpgraded' first. To do so, use the function 'PlayerLoadout.register'.")
	end
end

--#region static functions

--- Must call this function at least once before using this class.
--- @param mod ModUpgraded @ must be upgraded with the feature `ISCFeature.PLAYER_COLLECTIBLE_TRACKING`
function PlayerLoadout.register(mod)
	if (isRegistered == true) then return end
	thisMod = mod
	isRegistered = true
end

--- Creates a new `PlayerLoadout` instance
--- @return PlayerLoadout
function PlayerLoadout.constuctor()
	checkIsRegistered()

	--- @type PlayerLoadout
	local loadout = {
		Pickups = {
			Coins = 0,
			Bombs = 0,
			Keys = 0,
			GigaBombs = 0,
			Charges = 0,
		},
		Collectibles = {
			Active = {},
			Passive = {},
		},
		Trinkets = {},
		Cards = {},
		Pills = {},
	}

	local excludedFunctions = {
		"constructor",
		"createFromPlayer",
		"fromSerializable",
		"register"
	}
	for k, v in pairs(PlayerLoadout) do
		if (type(v) == "function") then
			if (isc:some(excludedFunctions, function (_, f)
				return (f == k)
			end) == false) then loadout[k] = v end
		end
	end

	return loadout
end

--- @param player EntityPlayer
--- @return PlayerLoadout
function PlayerLoadout.createFromPlayer(player)
	local loadout = PlayerLoadout.constuctor()

	loadout:setPickupsFromPlayer(player)
	loadout:setCollectiblesFromPlayer(player)
	loadout:setTrinketsFromPlayer(player)
	loadout:setCardsFromPlayer(player)
	loadout:setPillsFromPlayer(player)

	return loadout
end

--- @param serializableLoadout SerializablePlayerLoadout
--- @return PlayerLoadout
function PlayerLoadout.fromSerializable(serializableLoadout)
	local loadout = PlayerLoadout.constuctor()

	loadout:setPickups(serializableLoadout.Pickups)
	loadout:setActiveCollectibles(serializableLoadout.Collectibles.Active)
	loadout:setPassiveCollectibles(serializableLoadout.Collectibles.Passive)
	loadout:setTrinkets(serializableLoadout.Trinkets)
	loadout:setCards(serializableLoadout.Cards)
	loadout:setPills(serializableLoadout.Pills)

	return loadout
end

--#endregion

--#region instance functions

--- @return SerializablePlayerLoadout
function PlayerLoadout:serialize()
	--- @type SerializablePlayerLoadout
	local serializableLoadout = {
		Pickups = {
			Coins = 0,
			Bombs = 0,
			Keys = 0,
			GigaBombs = 0,
			Charges = 0,
		},
		Collectibles = {
			Active = {},
			Passive = {},
		},
		Trinkets = {},
		Cards = {},
		Pills = {},
	}

	for k, v in pairs(self.Pickups) do
		serializableLoadout.Pickups[k] = v
	end
	isc:forEach(self.Collectibles.Active, function (_, activeItem)
		table.insert(serializableLoadout.Collectibles.Active, activeItem)
	end)
	isc:forEach(self.Collectibles.Passive, function (_, passiveItem)
		table.insert(serializableLoadout.Collectibles.Passive, passiveItem)
	end)
	isc:forEach(self.Trinkets, function (_, trinket)
		table.insert(serializableLoadout.Trinkets, trinket)
	end)
	isc:forEach(self.Cards, function (_, card)
		table.insert(serializableLoadout.Cards, card)
	end)
	isc:forEach(self.Pills, function (_, pill)
		table.insert(serializableLoadout.Pills, pill)
	end)

	return serializableLoadout
end

--- @param coins integer
--- @param bombs integer
--- @param keys integer
--- @param gigaBombs? integer @ default: `0`
--- @param charges? integer @ default: `0`
--- @overload fun(self: PlayerLoadout, pickups: PlayerPickups)
function PlayerLoadout:setPickups(coins, bombs, keys, gigaBombs, charges)
	if (type(coins) == "table") then
		--- @type PlayerPickups
		local pickups = coins
		bombs = pickups.Bombs
		keys = pickups.Keys
		gigaBombs = pickups.GigaBombs
		charges = pickups.Charges
		coins = pickups.Coins
	end
	if (not gigaBombs) then gigaBombs = 0 end
	if (not charges) then charges = 0 end

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

--- @package
--- @param activePassive "Active" | "Passive"
--- @param collectibles CollectibleType | CollectibleType[]
function PlayerLoadout:setCollectibles(activePassive, collectibles)
	if (type(collectibles) ~= "table") then collectibles = {collectibles} end
	self.Collectibles[activePassive] = collectibles
end

--- @package
--- @param player EntityPlayer
function PlayerLoadout:setCollectiblesFromPlayer(player)
	self:setActiveCollectiblesFromPlayer(player)
	self:setPassiveCollectiblesFromPlayer(player)
end

--- @param collectibles CollectibleType | CollectibleType[]
function PlayerLoadout:setActiveCollectibles(collectibles)
	self:setCollectibles("Active", collectibles)
end

--- @param player EntityPlayer
function PlayerLoadout:setActiveCollectiblesFromPlayer(player)
	--- @type CollectibleType[]
	local actives = {}

	--- @type ActiveSlot[]
	local activeSlots = {
		ActiveSlot.SLOT_PRIMARY,
		ActiveSlot.SLOT_SECONDARY,
	}

	--- @param slot ActiveSlot
	isc:forEach(activeSlots, function (_, slot)
		local activeItem = player:GetActiveItem(slot)
		if (activeItem ~= CollectibleType.COLLECTIBLE_NULL) then
			table.insert(actives, activeItem)
		end
	end)

	self.Collectibles.Active = actives
end

--- @param collectibles CollectibleType | CollectibleType[]
function PlayerLoadout:setPassiveCollectibles(collectibles)
	self:setCollectibles("Passive", collectibles)
end

--- @param player EntityPlayer
function PlayerLoadout:setPassiveCollectiblesFromPlayer(player)
	self.Collectibles.Passive = thisMod:getPlayerCollectibleTypes(player, false)
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

--- @param pills PillColor | PillColor[]
function PlayerLoadout:setPills(pills)
	if (type(pills) ~= "table") then pills = {pills} end
	self.Pills = pills
end

--- @param player EntityPlayer
function PlayerLoadout:setPillsFromPlayer(player)
	--- @type PillColor[]
	local pills = {}

	for _, pocketItem in ipairs(isc:getPocketItems(player)) do
		if (pocketItem.type == isc.PocketItemType.PILL) then
			table.insert(pills, pocketItem.subType)
		end
	end

	self.Pills = pills
end

--#endregion

return PlayerLoadout
