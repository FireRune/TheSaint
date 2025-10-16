local isc = require("TheSaint.lib.isaacscript-common")
local registry = include("TheSaint.ItemRegistry")
local game = Game()
local config = Isaac.GetItemConfig()
local item = {}

--[[
    - 3 Room Charge
    - When used, will activate the effect of 2 random
      items with the 'book'-tag. (modded items included)
    - Can also activate books that have not been
      unlocked yet.
    - Cannot activate itself
]]

-- table containing all items with the 'book'-tag, except 'Almanach' 
local books = {}

-- flag to check wether the used item was 'Lemegeton'
local almanachLemegeton = false
-- name of the item granted by the spawned Lemegeton-wisp
local wispName = ""

-- flag to check wether the item used was invoked from 'Almanach'
local calledFromAlmanach = false
-- table containing the names of the invoked items
local itemNames = {
    [0] = "",
    [1] = ""
}

--- caches all items with the 'book'-tag
local function getBooks()
    if (#books > 0) then return end
    local counter = 0
    for i = 0, config:GetCollectibles().Size - 1 do
        local collectible = config:GetCollectible(i)
        if collectible then
            if collectible:HasTags(ItemConfig.TAG_BOOK)
            and (collectible.ID ~= registry.COLLECTIBLE_ALMANACH) then
                counter = counter + 1
                table.insert(books, counter, {ID = collectible.ID, Name = isc:getCollectibleName(collectible.ID)})
            end
        end
    end
end

--- when invoking the effect of 'Lemegeton' caches the name of the item granted by the spawned wisp
--- @param itemWisp EntityFamiliar
local function getWispName(_, itemWisp)
    if almanachLemegeton then
        wispName = isc:getCollectibleName(itemWisp.SubType)
    end
end

--- on use, invoke the effects of 2 items from the books-table (can be the same item twice)
--- and displays the names of the chosen items ('Lemegeton' also shows which item it grants)
--- @param rng RNG
--- @param player EntityPlayer
local function useItem(_, _, rng, player)
    for i = 0, 1 do
        local randInt = rng:RandomInt(#books) + 1
        itemNames[i] = books[randInt].Name
        if (books[randInt].Name == "Book of Virtues") then
            player:AddWisp(0, player.Position, true)
        else
            if (itemNames[i] == "Lemegeton") then
                almanachLemegeton = true
            end
            calledFromAlmanach = true
            player:UseActiveItem(books[randInt].ID, UseFlag.USE_NOANIM)
        end
        if (itemNames[i] == "Lemegeton") then
            itemNames[i] = itemNames[i].." ("..wispName..")"
            almanachLemegeton = false
            wispName = ""
        end
    end
    game:GetHUD():ShowItemText(itemNames[0].."...", "... and "..itemNames[1])
    return true
end

--- if player holds 'Book of Virtues' spawns the respective wisps of the invoked items (except 'Lemegeton')
--- @param book CollectibleType
--- @param player EntityPlayer
local function spawnAlmanachBookWisp(_, book, _, player)
    if player:HasCollectible(CollectibleType.COLLECTIBLE_BOOK_OF_VIRTUES) then
        if calledFromAlmanach then
            if not almanachLemegeton then
                player:AddWisp(book, player.Position, true)
            end
            calledFromAlmanach = false
        end
    end
end

--- reload the books-table via the Debug Console
--- @param cmd string
local function enterCmd(_, cmd)
    if (string.lower(cmd) == "saint_reloadbooks") then
        books = {}
        getBooks()
    end
end

--- initialize the item's functionality
--- @param mod ModReference
function item:Init(mod)
    mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, getBooks)
    mod:AddCallback(ModCallbacks.MC_FAMILIAR_INIT, getWispName, FamiliarVariant.ITEM_WISP)
    mod:AddCallback(ModCallbacks.MC_USE_ITEM, useItem, registry.COLLECTIBLE_ALMANACH)
    mod:AddCallback(ModCallbacks.MC_USE_ITEM, spawnAlmanachBookWisp)
    mod:AddCallback(ModCallbacks.MC_EXECUTE_CMD, enterCmd)
end

return item
