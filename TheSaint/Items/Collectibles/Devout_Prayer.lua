local isc = require("TheSaint.lib.isaacscript-common")
local enums = require("TheSaint.Enums")
local ddTracking = require("TheSaint.DevilDealTracking")

local game = Game()
local hud = game:GetHUD()

--- "Devout Prayer"
--- - 12 charges, starts empty; only charges by killing enemies
--- - gains 1 charge for every 10th enemy killed and 1 charge for clearing a boss room
--- - charges faster while having an Eternal Heart
--- - can be used with 1+ charges (like "Larnyx" or "Everything Jar")
--- - Effect depends on the amount of charges spent (1, 3, 6 or 12; see functions below for effect details)
--- - using while having an Eternal Heart will consume it for extra effects
--- @class TheSaint.Items.Collectibles.Devout_Prayer : TheSaint_Feature
local Devout_Prayer = {
    FeatureSubType = enums.CollectibleType.COLLECTIBLE_DEVOUT_PRAYER,
    SaveDataKey = "Devout_Prayer",
}

--[[
    local variables with persistent data. for use with the save data manager.<br>
    -> increases to luck and damage are tracked in "level"<br>
    -> current kill count for the charge mechanic is stored in "run"
]]
local v = {
    run = {},
    level = {}
}

-- flag to check wether any Pocket Item other than "Devout Prayer" was used
local otherPocketItemUsed = false

--- charge mechanic
--- @param pointValue integer
local function chargeDevoutPrayer(pointValue)
    for i = 0, game:GetNumPlayers() - 1 do
        local player = Isaac.GetPlayer(i)
        if player:HasCollectible(Devout_Prayer.FeatureSubType) then
            if (player:GetEternalHearts() == 1) then
                pointValue = pointValue * 2
            end
            local playerIndex = "DevoutPrayer_Kills_"..isc:getPlayerIndex(player)
            v.run[playerIndex] = (v.run[playerIndex] and (v.run[playerIndex] + pointValue)) or pointValue
            while (v.run[playerIndex] >= 10) do
                v.run[playerIndex] = v.run[playerIndex] - 10
                for _, slot in ipairs(isc:getActiveItemSlots(player, Devout_Prayer.FeatureSubType)) do
                    local currentCharge = player:GetActiveCharge(slot) + player:GetBatteryCharge(slot)
                    if (player:HasCollectible(CollectibleType.COLLECTIBLE_BATTERY) and (currentCharge < 24))
                    or (currentCharge < 12) then
                        player:SetActiveCharge(currentCharge + 1, slot)
                        hud:FlashChargeBar(player, slot)
                        isc:playChargeSoundEffect(player, slot)
                    end
                end
            end
        end
    end
end

--- increase charge counter by 1 per killed enemy
--- @param entity Entity
local function postEntityKill(_, entity)
    if (entity:IsActiveEnemy(true)) then
        chargeDevoutPrayer(1)
    end
end

--- increase charge counter by 10 per cleared Boss Room
--- @param rng RNG
--- @param spawnPos Vector
local function preSpawnCleanAward(_, rng, spawnPos)
    if (game:GetRoom():GetType() == RoomType.ROOM_BOSS) then
        chargeDevoutPrayer(10)
    end
end

--- if any Pocket Item other than "Devout Prayer" is used, set flag to prevent accidental activation.<br>
--- used both in MC_USE_CARD and MC_USE_PILL
local function useOtherPocketItem()
    otherPocketItemUsed = true
end

--- check wether "Devout Prayer" should be used when corresponding action is triggered
--- @param player EntityPlayer
local function postPlayerUpdate(_, player)
    if ((player:GetActiveItem(ActiveSlot.SLOT_PRIMARY) == Devout_Prayer.FeatureSubType)
    and (Input.IsActionTriggered(ButtonAction.ACTION_ITEM, player.ControllerIndex))) then
        local charge = player:GetActiveCharge(ActiveSlot.SLOT_PRIMARY)
        if (charge > 0) and (charge < 12) then
            player:UseActiveItem(Devout_Prayer.FeatureSubType, UseFlag.USE_OWNED, ActiveSlot.SLOT_PRIMARY)
        end
    else
        if ((player:GetActiveItem(ActiveSlot.SLOT_POCKET) == Devout_Prayer.FeatureSubType)
        and (Input.IsActionTriggered(ButtonAction.ACTION_PILLCARD, player.ControllerIndex))) then
            if (not otherPocketItemUsed) then
                local charge = player:GetActiveCharge(ActiveSlot.SLOT_POCKET)
                if (charge > 0) and (charge < 12) then
                    player:UseActiveItem(Devout_Prayer.FeatureSubType, UseFlag.USE_OWNED, ActiveSlot.SLOT_POCKET)
                end
            else
                otherPocketItemUsed = false
            end
        end
    end
end

--- @param player EntityPlayer
local function getPlayerCounters(player)
    local playerIndex = "DevoutPrayer_Counters_"..isc:getPlayerIndex(player)
    if (not v.level[playerIndex]) then
        v.level[playerIndex] = {
            damage = 0,
            luck = 0
        }
    end
    return v.level[playerIndex]
end

--- Increases the given players Luck by 0.1 per charge spent.<br>
--- Extra effect: also increases Damage by 0.25 per charge spent.
--- @param chargeValue integer
--- @param player EntityPlayer
--- @param extraEffect boolean
local function effectAddLuck(chargeValue, player, extraEffect)
    local counters = getPlayerCounters(player)
    counters.luck = counters.luck + chargeValue
    if (extraEffect == true) then
        counters.damage = counters.damage + chargeValue
    end
    player:EvaluateItems()
end

--- re-evaluates the given players stats after using "Devout Prayer"
--- @param player EntityPlayer
--- @param flag CacheFlag
local function evaluateStats(_, player, flag)
    local counters = getPlayerCounters(player)

    if (flag & CacheFlag.CACHE_DAMAGE == CacheFlag.CACHE_DAMAGE) then
        player.Damage = player.Damage + (0.25 * counters.damage)
    end

    if (flag & CacheFlag.CACHE_LUCK == CacheFlag.CACHE_LUCK) then
        player.Luck = player.Luck + (0.1 * counters.luck)
    end
end

--- reset counters at the start of a new level
local function postNewLevel_resetCounters()
    for i = 0, game:GetNumPlayers() - 1 do
        local player = Isaac.GetPlayer(i)
        local flags = (CacheFlag.CACHE_DAMAGE | CacheFlag.CACHE_LUCK)
        --- @cast flags CacheFlag
        player:AddCacheFlags(flags)
        player:EvaluateItems()
    end
end

--- Spawns an Eternal Heart.<br>
--- Extra effect: grants the effect of "Holy Card".
--- @param player EntityPlayer
--- @param extraEffect boolean
local function effectSpawnHeart(player, extraEffect)
    Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_HEART, HeartSubType.HEART_ETERNAL, game:GetRoom():FindFreePickupSpawnPosition(player.Position, 0, true), Vector.Zero, nil)
    if (extraEffect == true) then
        local flags = (UseFlag.USE_NOANIM | UseFlag.USE_NOANNOUNCER | UseFlag.USE_NOHUD)
        --- @cast flags UseFlag
        player:UseCard(Card.CARD_HOLY, flags)
    end
end

--- Spawns an Eternal Chest.<br>
--- Extra effect: increase Angel Room chance for current floor.
--- @param player EntityPlayer
--- @param extraEffect boolean
local function effectSpawnChest(player, extraEffect)
    Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_ETERNALCHEST, ChestSubType.CHEST_CLOSED, game:GetRoom():FindFreePickupSpawnPosition(player.Position, 0, true), Vector.Zero, nil)
    if (extraEffect == true) then
        game:GetLevel():AddAngelRoomChance(0.1)
        hud:ShowFortuneText("You feel blessed!")
    end
end

--- Checks all item pedestals in the room and returns the highest value of OptionsPickupIndex.
--- @return integer
local function getOptionIndex()
    local optionIndex = 2
    for _, entity in ipairs(Isaac.GetRoomEntities()) do
        if (entity.Type == EntityType.ENTITY_PICKUP and entity.Variant == PickupVariant.PICKUP_COLLECTIBLE) then
            local entCollectible = entity:ToPickup()
            if (entCollectible) then
                optionIndex = math.max(optionIndex, entCollectible.OptionsPickupIndex)
            end
        end
    end
    return (optionIndex + 1)
end

--- Spawns two items, only one can be taken.<br>
--- (1 from the current room's pool and 1 from the Angel or Devil pool)<br>
--- Extra effect: both items can be taken.
--- @param rng RNG
--- @param player EntityPlayer
--- @param extraEffect boolean
local function effectSpawnItem(rng, player, extraEffect)
    local optionIndex = getOptionIndex()
    local ddTaken = ddTracking:HasDevilDealBeenTaken()
    if ((extraEffect == true) and (ddTaken == false)) then
        optionIndex = 0
    end
    local pool = game:GetItemPool()
    local room = game:GetRoom()
    local collectibles = {
        [0] = CollectibleType.COLLECTIBLE_NULL,
        [1] = CollectibleType.COLLECTIBLE_NULL
    }

    -- 1st item from current pool
    collectibles[0] = pool:GetCollectible(pool:GetPoolForRoom(room:GetType(), rng:RandomInt(math.maxinteger)), false, rng:RandomInt(math.maxinteger))
    Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, collectibles[0], room:FindFreePickupSpawnPosition(player.Position, 0, true), Vector.Zero, nil):ToPickup().OptionsPickupIndex = optionIndex

    -- 2nd item from Angel pool
    -- if a Devil Deal has been taken before, spawn either from Devil pool (w/o an Eternal Heart has a 50% chance to be an empty pedestal instead)
    local poolAngelOrDevil = ((ddTaken and ItemPoolType.POOL_DEVIL) or ItemPoolType.POOL_ANGEL)
    if (game:IsGreedMode()) then
        poolAngelOrDevil = ((ddTaken and ItemPoolType.POOL_GREED_DEVIL) or ItemPoolType.POOL_GREED_ANGEL)
    end
    collectibles[1] = pool:GetCollectible(poolAngelOrDevil, false, rng:RandomInt(math.maxinteger))
    local pos = room:FindFreePickupSpawnPosition(player.Position, 0, true)
    if ((ddTaken == true) and (extraEffect == false) and (rng:RandomInt(math.maxinteger) % 2) == 1) then
        isc:spawnEmptyCollectible(pos, rng)
    else
        Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, collectibles[1], pos, Vector.Zero, nil):ToPickup().OptionsPickupIndex = optionIndex
    end
end

--- @param collectible CollectibleType
--- @param rng RNG
--- @param player EntityPlayer
--- @param flags UseFlag
--- @param slot ActiveSlot
local function useItem(_, collectible, rng, player, flags, slot)
    -- "Car Battery" has no effect
    if (flags & UseFlag.USE_CARBATTERY == UseFlag.USE_CARBATTERY) then return false end

    -- "Void" only invokes the luck up effect
    local isVoid = (flags & UseFlag.USE_VOID == UseFlag.USE_VOID)

    local extraEffect = false
    if (player:GetEternalHearts() == 1) then
        --player:AddEternalHearts(-1)
        extraEffect = true
    end
    local charge = ((isVoid and 1) or (player:GetActiveCharge(slot) + player:GetBatteryCharge(slot)))

    if (charge >= 1) then
        -- only remove up to 12 charges
        local chargeSpent = (((charge > 12) and 12) or charge)

        -- 1+ charge(s)
        local numWisps = 1
        effectAddLuck(chargeSpent, player, extraEffect)
        if ((charge >= 3) and (charge < 6)) then
            -- 3-5 charges
            numWisps = 2
            effectSpawnHeart(player, extraEffect)
        elseif ((charge >= 6) and (charge < 12)) then
            -- 6-11 charges
            numWisps = 3
            effectSpawnChest(player, extraEffect)
        elseif (charge >= 12) then
            -- 12 charges
            numWisps = 4
            effectSpawnItem(rng, player, extraEffect)
        end

        -- manually remove charges, except when used through "Void"
        if (not isVoid) then player:SetActiveCharge(charge - chargeSpent, slot) end

        -- if holding "Book of Virtues", spawn wisps
        if (player:HasCollectible(CollectibleType.COLLECTIBLE_BOOK_OF_VIRTUES)) then
            local wispType = ((extraEffect and CollectibleType.COLLECTIBLE_BIBLE) or Devout_Prayer.FeatureSubType)
            for _ = 1, numWisps do
                player:AddWisp(wispType, player.Position, true)
            end
        end

        return {
            Discharge = false,
            Remove = false,
            ShowAnim = true
        }
    end
end

--- Initialize the item's functionality.
--- @param mod ModReference
function Devout_Prayer:Init(mod)
    mod:saveDataManager(self.SaveDataKey, v)
    mod:AddCallback(ModCallbacks.MC_POST_ENTITY_KILL, postEntityKill)
    mod:AddCallback(ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD, preSpawnCleanAward)
    mod:AddCallback(ModCallbacks.MC_USE_CARD, useOtherPocketItem)
    mod:AddCallback(ModCallbacks.MC_USE_PILL, useOtherPocketItem)
    mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, postPlayerUpdate, 0)
    mod:AddCallback(ModCallbacks.MC_USE_ITEM, useItem, self.FeatureSubType)
    mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, postNewLevel_resetCounters)
    mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, evaluateStats, CacheFlag.CACHE_DAMAGE)
    mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, evaluateStats, CacheFlag.CACHE_LUCK)
end

return Devout_Prayer
