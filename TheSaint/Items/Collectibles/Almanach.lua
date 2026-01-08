local isc = require("TheSaint.lib.isaacscript-common")
local enums = require("TheSaint.Enums")
local featureTarget = require("TheSaint.structures.FeatureTarget")

local game = Game()
local config = Isaac.GetItemConfig()

--- "Almanach"
--- - 3 Room Charge
--- - When used, will activate the effect of 2 random<br>
---   items with the `book`-tag (modded items included)
--- - Can also activate books that have not been unlocked yet
--- - Cannot activate itself
--- @class TheSaint.Items.Collectibles.Almanach : TheSaint.classes.ModFeatureTargeted<CollectibleType>
local Almanach = {
	IsInitialized = false,
	--- @type TheSaint.structures.FeatureTarget<CollectibleType>
	Target = featureTarget:new(enums.CollectibleType.COLLECTIBLE_ALMANACH),
}

--- @class TheSaint.Items.Collectibles.Almanach.Book
--- @field ID integer
--- @field Name string

-- table containing all items with the `book`-tag, except those on the blacklist
--- @type TheSaint.Items.Collectibles.Almanach.Book[]
local books = {}

--- Blacklist of items with the `book`-tag.<br>
--- Key is the item's id (see `Isaac.GetItemIdByName()`), Value is the name of the mod that blacklisted it.
--- @type table<CollectibleType, string>
local books_blacklist = {}

-- flag to check wether the used item was "Lemegeton"
local almanachLemegeton = false
-- name of the item granted by the spawned "Lemegeton"-wisp(s)
--- @type string[]
local wispNames = {}

-- flag to check wether the item used was invoked from "Almanach"
local calledFromAlmanach = false

--- Adds the given items to the book-blacklist if not already set
--- @param modName string
--- @param items CollectibleType[]
local function addItemToBookBlacklist(modName, items)
	for _, item in ipairs(items) do
		if (not books_blacklist[item]) then
			books_blacklist[item] = modName
		end
	end
end
--- Exposed API version of `addItemToBookBlacklist`<br>
--- Adds the given item(s) to the book-blacklist if not already set
--- @param mod ModReference
--- @param item CollectibleType | CollectibleType[]
function TheSaintAPI:AddItemToBookBlacklist(mod, item)
	if (type(item) ~= "table") then item = {item} end
	addItemToBookBlacklist(mod.Name, item)
end

--- checks wether the given item is in the books-blacklist
--- @param item CollectibleType
local function isBlacklisted(item)
	for collectible, _ in pairs(books_blacklist) do
		if (item == collectible) then
			return true
		end
	end
	return false
end

--- caches all items with the `book`-tag
local function getBooks()
	if (#books > 0) then return end
	Isaac.DebugString("[The Saint] (INFO) <Almanach> generate list of items with 'book'-tag (except blacklisted items)")
	--- API says that `GetCollectibles()` returns `userdata`, but it's actually `ItemConfigList`
	--- @type ItemConfigList
	--- @diagnostic disable-next-line
	local collectibles = config:GetCollectibles()
	for i = 0, collectibles.Size - 1 do
		local collectible = config:GetCollectible(i)
		if collectible then
			if (collectible:HasTags(ItemConfig.TAG_BOOK)) then
				local id = collectible.ID
				local name = isc:getCollectibleName(id)
				if (isBlacklisted(id) == false) then
					table.insert(books, {ID = id, Name = name})
					Isaac.DebugString("[The Saint] (INFO) <Almanach> add ["..id.."] '"..name.."'")
				else
					local modName = books_blacklist[id]
					Isaac.DebugString("[The Saint] (INFO) <Almanach> skipped blacklisted item ["..id.."] '"..name.."' (blacklisted by the mod: '"..modName.."')")
				end
			end
		end
	end
end

--- (REP only) when invoking the effect of "Lemegeton" caches the name of the item granted by the spawned wisp
--- @param itemWisp EntityFamiliar
local function getWispName(_, itemWisp)
	if (almanachLemegeton == true) then
		table.insert(wispNames, isc:getCollectibleName(itemWisp.SubType))
	end
end

--- @param texts { Text1: string, Text2: string? }
local function showHUDText(texts)
	if (texts.Text2 ~= nil) then
		texts.Text1 = texts.Text1.."..."
		texts.Text2 = "... and "..texts.Text2
	end

	local hud = game:GetHUD()
	if REPENTANCE_PLUS then
		-- (REP+) stack up text in case of multiple activations, to see what effects were granted
		hud:ShowItemText(texts.Text1, texts.Text2, false, false)
	else
		hud:ShowItemText(texts.Text1, texts.Text2, false)
	end
end

--- on use, invoke the effects of 2 items from the books-table (can be the same item twice)
--- and displays the names of the chosen items ("Lemegeton" also shows which item it grants)
--- @param collectible CollectibleType
--- @param rng RNG
--- @param player EntityPlayer
--- @param flag UseFlag
--- @param slot ActiveSlot
--- @param varData integer
local function useItem(_, collectible, rng, player, flag, slot, varData)
	-- "Car Battery" should boost the triggered items instead of using "Almanach" twice
	if (flag & UseFlag.USE_CARBATTERY == UseFlag.USE_CARBATTERY) then return end
	local hasCarBattery = isc:hasCollectible(player, CollectibleType.COLLECTIBLE_CAR_BATTERY)
	local itemUses = ((hasCarBattery and 2) or 1)

	--- @type string[]
	local bookNames = {}
	--- @type CollectibleType[]
	local bookIDs = {}

	local texts = {
		Text1 = "",
		Text2 = nil,
	}

	local scatteredPagesActivation = (varData == enums.CustomVarData.Almanach.SCATTERED_PAGES)
	local limit = ((scatteredPagesActivation and 1) or 2)

	--- @type TheSaint.Items.Collectibles.Almanach.Book[]
	local bookExceptions = {}
	-- First get the items to activate
	for i = 1, limit do
		--- @type TheSaint.Items.Collectibles.Almanach.Book
		local book = isc:getRandomArrayElement(books, rng, bookExceptions)

		table.insert(bookIDs, i, book.ID)
		table.insert(bookNames, i, book.Name)
		texts["Text"..i] = book.Name

		table.insert(bookExceptions, book)
	end

	-- (REP+ only) show HUD text now, so that Lemegeton item wisp names are displayed below
	if REPENTANCE_PLUS then showHUDText(texts) end

	-- next, activate the items
	for i = 1, limit do
		if (bookNames[i] == "Lemegeton") then
			almanachLemegeton = true
		end
		for j = 1, itemUses do
			local newFlags = UseFlag.USE_NOANIM
			if (j > 1) then
				newFlags = (newFlags | UseFlag.USE_CARBATTERY)
			end
			--- @cast newFlags UseFlag

			if (bookNames[i] == "Book of Virtues") then
				player:AddWisp(0, player.Position, true)
			else
				calledFromAlmanach = true
				player:UseActiveItem(bookIDs[i], newFlags)
				calledFromAlmanach = false
			end
		end
		if (bookNames[i] == "Lemegeton") then
			-- not necessary with Rep+, due to the "stack up text"-feature
			if not REPENTANCE_PLUS then
				local wisps = ""
				for _, wispName in ipairs(wispNames) do
					wisps = wisps..((wisps ~= "" and " / "..wispName) or wispName)
				end
				bookNames[i] = bookNames[i].." ("..wisps..")"
				wispNames = {}
			end
			almanachLemegeton = false
		end
		texts["Text"..i] = bookNames[i]
	end

	-- (REP only) show HUD text now, so that it will be on top
	if not REPENTANCE_PLUS then showHUDText(texts) end

	return true
end

--- if player holds "Book of Virtues" spawns the respective wisps of the invoked items (except "Lemegeton")
--- @param book CollectibleType
--- @param rng RNG
--- @param player EntityPlayer
--- @param flag UseFlag
--- @param slot ActiveSlot
--- @param varData integer
local function spawnAlmanachBookWisp(_, book, rng, player, flag, slot, varData)
	if player:HasCollectible(CollectibleType.COLLECTIBLE_BOOK_OF_VIRTUES) then
		if ((calledFromAlmanach == true) and (almanachLemegeton == false)) then
			player:AddWisp(book, player.Position, true)
		end
	end
end

--- reload the books-table via the Debug Console
local function thesaint_reloadbooks()
	books = {}
	getBooks()
	print("[The Saint]: reloaded book-cache")
end

--- initialize the item's functionality
--- @param mod ModUpgraded
function Almanach:Init(mod)
	if (self.IsInitialized) then return end

	addItemToBookBlacklist(mod.Name, {CollectibleType.COLLECTIBLE_HOW_TO_JUMP, self.Target.Type})
	mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, getBooks)
	if not REPENTANCE_PLUS then
		-- not needed with Rep+
		mod:AddCallback(ModCallbacks.MC_FAMILIAR_INIT, getWispName, FamiliarVariant.ITEM_WISP)
	end
	mod:AddCallback(ModCallbacks.MC_USE_ITEM, useItem, self.Target.Type)
	mod:AddCallback(ModCallbacks.MC_USE_ITEM, spawnAlmanachBookWisp)
	mod:addConsoleCommand("thesaint_reloadbooks", thesaint_reloadbooks)
end

return Almanach
