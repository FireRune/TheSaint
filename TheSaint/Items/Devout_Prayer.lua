local isc = require("TheSaint.lib.isaacscript-common")
local enums = require("TheSaint.Enums")

local game = Game()
local hud = game:GetHUD()

--[[
    "Devout Prayer"<br>
    - 12 charges, starts empty; only charges by killing enemies<br>
	- gains 1 charge for every 10th enemy killed and 1 charge for clearing a boss room<br>
	- charges faster while having an Eternal Heart<br>
    - can be used with 1+ charges (like 'Larnyx' or 'Everything Jar')<br>
    - Effect depends on the amount of charges spent (1, 3, 6 or 12; see functions below for effect details)<br>
	- using while having an Eternal Heart will consume it for extra effects
    
    (will not use more charges than needed, effect in brackets only applies when having an Eternal Heart)
    > 1+: Luck Up for the current floor (+0.1 * charges spent)
    [also grants Damage Up for the current floor (+0.25 * charges spent)]
    > 3+: spawns an Eternal Heart [and triggers the effect of 'Holy Card']
    > 6+: spawns an Eternal Chest [and +10% Angel chance]
    > 12: spawns an Item from current pool or ARP/DRP
    [spawns another Item from a random pool, only one can be taken]
]]
local Devout_Prayer = {}

--[[
    local variables with persistent data. for use with the save data manager.<br>
    -> increases to luck and damage are tracked in "level"<br>
    -> current kill count for the charge mechanic is stored in "run"
]]
local v = {
    run = {},
    level = {}
}

-- flag to check wether any Pocket Item other than 'Devout Prayer' was used
local otherPocketItemUsed = false

--- charge mechanic
--- @param pointValue integer
local function chargeDevoutPrayer(pointValue)
    for i = 0, game:GetNumPlayers() - 1 do
        local player = Isaac.GetPlayer(i)
        if player:HasCollectible(enums.CollectibleType.COLLECTIBLE_DEVOUT_PRAYER) then
            if (player:GetEternalHearts() == 1) then
                pointValue = pointValue * 2
            end
            local playerIndex = "DevoutPrayer_Kills_"..isc:getPlayerIndex(player)
            v.run[playerIndex] = (v.run[playerIndex] and (v.run[playerIndex] + pointValue)) or pointValue
            while (v.run[playerIndex] >= 10) do
                v.run[playerIndex] = v.run[playerIndex] - 10
                for _, slot in ipairs(isc:getActiveItemSlots(player, enums.CollectibleType.COLLECTIBLE_DEVOUT_PRAYER)) do
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

--- if any Pocket Item other than 'Devout Prayer' is used, set flag to prevent accidental activation.<br>
--- used both in MC_USE_CARD and MC_USE_PILL
local function useOtherPocketItem()
    otherPocketItemUsed = true
end

--- check wether 'Devout Prayer' should be used when corresponding action is triggered
--- @param player EntityPlayer
local function postPlayerUpdate(_, player)
    if ((player:GetActiveItem(ActiveSlot.SLOT_PRIMARY) == enums.CollectibleType.COLLECTIBLE_DEVOUT_PRAYER)
    and (Input.IsActionTriggered(ButtonAction.ACTION_ITEM, player.ControllerIndex))) then
        local charge = player:GetActiveCharge(ActiveSlot.SLOT_PRIMARY)
        if (charge > 0) and (charge < 12) then
            player:UseActiveItem(enums.CollectibleType.COLLECTIBLE_DEVOUT_PRAYER, UseFlag.USE_OWNED, ActiveSlot.SLOT_PRIMARY)
        end
    else
        if ((player:GetActiveItem(ActiveSlot.SLOT_POCKET) == enums.CollectibleType.COLLECTIBLE_DEVOUT_PRAYER)
        and (Input.IsActionTriggered(ButtonAction.ACTION_PILLCARD, player.ControllerIndex))) then
            if (not otherPocketItemUsed) then
                local charge = player:GetActiveCharge(ActiveSlot.SLOT_POCKET)
                if (charge > 0) and (charge < 12) then
                    player:UseActiveItem(enums.CollectibleType.COLLECTIBLE_DEVOUT_PRAYER, UseFlag.USE_OWNED, ActiveSlot.SLOT_POCKET)
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

--- re-evaluates the given players stats after using 'Devout Prayer'
--- @param player EntityPlayer
--- @param flag CacheFlag
local function evaluateStats(_, player, flag)
    if (not player:HasCollectible(enums.CollectibleType.COLLECTIBLE_DEVOUT_PRAYER)) then return end

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
        player:AddCacheFlags((CacheFlag.CACHE_DAMAGE | CacheFlag.CACHE_LUCK))
        player:EvaluateItems()
    end
end

--- Spawns an Eternal Heart.<br>
--- Extra effect: grants the effect of 'Holy Card'.
--- @param player EntityPlayer
--- @param extraEffect boolean
local function effectSpawnHeart(player, extraEffect)
    Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_HEART, HeartSubType.HEART_ETERNAL, game:GetRoom():FindFreePickupSpawnPosition(player.Position, 0, true), Vector.Zero, nil)
    if (extraEffect == true) then
        player:UseCard(Card.CARD_HOLY, (UseFlag.USE_NOANIM | UseFlag.USE_NOANNOUNCER | UseFlag.USE_NOHUD))
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
    for i, entity in ipairs(Isaac.GetRoomEntities()) do
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
    if (extraEffect == true) then
        optionIndex = 0
    end
    local pool = game:GetItemPool()
    local room = game:GetRoom()
    local collectibles = {
        [0] = CollectibleType.COLLECTIBLE_NULL,
        [1] = CollectibleType.COLLECTIBLE_NULL
    }

    collectibles[0] = pool:GetCollectible(pool:GetPoolForRoom(room:GetType(), rng:RandomInt(math.maxinteger)), false, rng:RandomInt(math.maxinteger))
    Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, collectibles[0], room:FindFreePickupSpawnPosition(player.Position, 0, true), Vector.Zero, nil):ToPickup().OptionsPickupIndex = optionIndex

    -- todo: spawn item from Devil Room pool if Devil Deal has been taken before (must be paid for)
    local poolAngelOrDevil = ItemPoolType.POOL_ANGEL
    if (game.Difficulty == Difficulty.DIFFICULTY_GREED or game.Difficulty == Difficulty.DIFFICULTY_GREEDIER) then
        poolAngelOrDevil = ItemPoolType.POOL_GREED_ANGEL
    end
    collectibles[1] = pool:GetCollectible(poolAngelOrDevil, false, rng:RandomInt(math.maxinteger))
    Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, collectibles[1], room:FindFreePickupSpawnPosition(player.Position, 0, true), Vector.Zero, nil):ToPickup().OptionsPickupIndex = optionIndex
end

--- @param collectible CollectibleType
--- @param rng RNG
--- @param player EntityPlayer
--- @param flags UseFlag
--- @param slot ActiveSlot
local function useItem(_, collectible, rng, player, flags, slot)
    -- 'Car Battery' has no effect
    if (flags & UseFlag.USE_CARBATTERY == UseFlag.USE_CARBATTERY) then return false end

    local extraEffect = false
    if (player:GetEternalHearts() == 1) then
        player:AddEternalHearts(-1)
        extraEffect = true
    end
    local charge = player:GetActiveCharge(slot) + player:GetBatteryCharge(slot)

    if (charge >= 1) then
        -- 1+ charge(s)
        local chargeSpent = 1
        -- effectLuck applies after these checks,
        -- as it depends on total charges spent.
        if (charge >= 3) then
            -- 3+ charges
            chargeSpent = 3
            effectSpawnHeart(player, extraEffect)
            if (charge >= 6) then
                -- 6+ charges
                chargeSpent = 6
                effectSpawnChest(player, extraEffect)
                if (charge >= 12) then
                    -- 12 charges
                    chargeSpent = 12
                    effectSpawnItem(rng, player, extraEffect)
                end
            end
        end
        effectAddLuck(chargeSpent, player, extraEffect)
        player:SetActiveCharge(charge - chargeSpent, slot)
        if (player:HasCollectible(CollectibleType.COLLECTIBLE_BOOK_OF_VIRTUES)) then
            local wispType = ((extraEffect and CollectibleType.COLLECTIBLE_BIBLE) or CollectibleType.COLLECTIBLE_NULL)
            player:AddWisp(wispType, player.Position, true)
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
    mod:saveDataManager("Devout_Prayer", v)
    mod:AddCallback(ModCallbacks.MC_POST_ENTITY_KILL, postEntityKill)
    mod:AddCallback(ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD, preSpawnCleanAward)
    mod:AddCallback(ModCallbacks.MC_USE_CARD, useOtherPocketItem)
    mod:AddCallback(ModCallbacks.MC_USE_PILL, useOtherPocketItem)
    mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, postPlayerUpdate, 0)
    mod:AddCallback(ModCallbacks.MC_USE_ITEM, useItem, enums.CollectibleType.COLLECTIBLE_DEVOUT_PRAYER)
    mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, postNewLevel_resetCounters)
    mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, evaluateStats, CacheFlag.CACHE_DAMAGE)
    mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, evaluateStats, CacheFlag.CACHE_LUCK)
end

return Devout_Prayer
