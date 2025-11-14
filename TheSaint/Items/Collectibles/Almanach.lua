local isc = require("TheSaint.lib.isaacscript-common")
local enums = require("TheSaint.Enums")

local game = Game()
local config = Isaac.GetItemConfig()

--[[
    "Almanach"<br>
    - 3 Room Charge<br>
    - When used, will activate the effect of 2 random<br>
      items with the `book`-tag (modded items included)<br>
    - Can also activate books that have not been unlocked yet<br>
    - Cannot activate itself
]]
local Almanach = {}

-- table containing all items with the `book`-tag, except those on the blacklist
local books = {}

--- Blacklist of items with the `book`-tag.<br>
--- Key is the item's id (see `Isaac.GetItemIdByName()`), Value is the name of the mod that blacklisted it.
--- @type table<CollectibleType, string>
local books_blacklist = {}

-- flag to check wether the used item was "Lemegeton"
local almanachLemegeton = false
-- name of the item granted by the spawned "Lemegeton"-wisp(s)
local wispNames = {}

-- flag to check wether the item used was invoked from "Almanach"
local calledFromAlmanach = false
-- table containing the names of the invoked items
local itemNames = {
    [0] = "",
    [1] = ""
}

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
    local counter = 0
    Isaac.DebugString("[The Saint] (INFO) <Almanach> generate list of items with 'book'-tag (except blacklisted items)")
    for i = 0, config:GetCollectibles().Size - 1 do
        local collectible = config:GetCollectible(i)
        if collectible then
            if (collectible:HasTags(ItemConfig.TAG_BOOK)) then
                local id = collectible.ID
                local name = isc:getCollectibleName(id)
                if (isBlacklisted(id) == false) then
                    counter = counter + 1
                    table.insert(books, counter, {ID = id, Name = name})
                    Isaac.DebugString("[The Saint] (INFO) <Almanach> add ["..id.."] '"..name.."'")
                else
                    local modName = books_blacklist[id]
                    Isaac.DebugString("[The Saint] (INFO) <Almanach> skipped blacklisted item ["..id.."] '"..name.."' (blacklisted by the mod: '"..modName.."')")
                end
            end
        end
    end
end

--- when invoking the effect of "Lemegeton" caches the name of the item granted by the spawned wisp
--- @param itemWisp EntityFamiliar
local function getWispName(_, itemWisp)
    if almanachLemegeton then
        table.insert(wispNames, isc:getCollectibleName(itemWisp.SubType))
    end
end

--- on use, invoke the effects of 2 items from the books-table (can be the same item twice)
--- and displays the names of the chosen items ("Lemegeton" also shows which item it grants)
--- @param rng RNG
--- @param player EntityPlayer
--- @param flag UseFlag
local function useItem(_, _, rng, player, flag)
    -- "Car Battery" should boost the triggered items instead of using "Almanach" twice
    if (flag & UseFlag.USE_CARBATTERY == UseFlag.USE_CARBATTERY) then return false end
    local hasCarBattery = isc:hasCollectible(player, CollectibleType.COLLECTIBLE_CAR_BATTERY)

    for i = 0, 1 do
        local randInt = rng:RandomInt(#books) + 1
        itemNames[i] = books[randInt].Name
        if (books[randInt].Name == "Book of Virtues") then
            player:AddWisp(0, player.Position, true)
            if (hasCarBattery) then
                player:AddWisp(0, player.Position, true)
            end
        else
            if (itemNames[i] == "Lemegeton") then
                almanachLemegeton = true
            end
            calledFromAlmanach = true
            player:UseActiveItem(books[randInt].ID, UseFlag.USE_NOANIM)
            if (hasCarBattery) then
                player:UseActiveItem(books[randInt].ID, UseFlag.USE_NOANIM)
            end
            calledFromAlmanach = false
        end
        if (itemNames[i] == "Lemegeton") then
            local wisps = ""
            for _, wispName in pairs(wispNames) do
                wisps = wisps..((wisps ~= "" and " / "..wispName) or wispName)
            end
            itemNames[i] = itemNames[i].." ("..wisps..")"
            almanachLemegeton = false
            wispNames = {}
        end
    end
    if REPENTANCE_PLUS then
        -- stack up text in case of multiple activations, to see what effects were granted
        game:GetHUD():ShowItemText(itemNames[0].."...", "... and "..itemNames[1], false, false)
    else
        game:GetHUD():ShowItemText(itemNames[0].."...", "... and "..itemNames[1], false)
    end
    return true
end

--- if player holds "Book of Virtues" spawns the respective wisps of the invoked items (except "Lemegeton")
--- @param book CollectibleType
--- @param player EntityPlayer
local function spawnAlmanachBookWisp(_, book, _, player)
    if player:HasCollectible(CollectibleType.COLLECTIBLE_BOOK_OF_VIRTUES) then
        if calledFromAlmanach then
            if not almanachLemegeton then
                player:AddWisp(book, player.Position, true)
            end
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
--- @param mod ModReference
function Almanach:Init(mod)
    addItemToBookBlacklist(mod.Name, {CollectibleType.COLLECTIBLE_HOW_TO_JUMP, enums.CollectibleType.COLLECTIBLE_ALMANACH})
    mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, getBooks)
    mod:AddCallback(ModCallbacks.MC_FAMILIAR_INIT, getWispName, FamiliarVariant.ITEM_WISP)
    mod:AddCallback(ModCallbacks.MC_USE_ITEM, useItem, enums.CollectibleType.COLLECTIBLE_ALMANACH)
    mod:AddCallback(ModCallbacks.MC_USE_ITEM, spawnAlmanachBookWisp)
    mod:addConsoleCommand("thesaint_reloadbooks", thesaint_reloadbooks)
end

return Almanach
