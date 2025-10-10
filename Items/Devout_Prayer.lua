local utility = include("utility")
local registry = include("ItemRegistry")
local game = Game()
local hud = game:GetHUD()
local sfx = SFXManager()
local config = Isaac.GetItemConfig()

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

-- flag to check wether any Pocket Item other than 'Devout Prayer' was used
local otherPocketItemUsed = false

--- charge mechanic
--- @param pointValue integer
local function chargeDevoutPrayer(pointValue)
    for i = 0, game:GetNumPlayers() - 1 do
        local player = Isaac.GetPlayer(i)
        if player:HasCollectible(registry.COLLECTIBLE_DEVOUT_PRAYER) then
            local dat = utility:getData(player)
            local counter = pointValue
            if (dat["TSaint_EternalHeart"] and (dat["TSaint_EternalHeart"] == true)) then
                counter = counter * 2
            end
            dat["TSaint_Kills"] = (dat["TSaint_Kills"] and dat["TSaint_Kills"] + counter) or counter
            while (dat["TSaint_Kills"] >= 10) do
                dat["TSaint_Kills"] = dat["TSaint_Kills"] - 10
                for _, slot in ipairs(utility:getSlotsWithCollectible(player, registry.COLLECTIBLE_DEVOUT_PRAYER)) do
                    local currentCharge = player:GetActiveCharge(slot) + player:GetBatteryCharge(slot)
                    if (player:HasCollectible(CollectibleType.COLLECTIBLE_BATTERY) and (currentCharge < 24))
                    or (currentCharge < 12) then
                        player:SetActiveCharge(currentCharge + 1, slot)
                        -- game:GetHUD():FlashChargeBar(player, slot)
                        hud:FlashChargeBar(player, slot)
                        if (currentCharge == 11) or (currentCharge == 23) then
                            sfx:Play(SoundEffect.SOUND_ITEMRECHARGE)
                        else
                            sfx:Play(SoundEffect.SOUND_BEEP)
                        end
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
local function postUpdate()
    for i = 0, game:GetNumPlayers() - 1 do
        local player = Isaac.GetPlayer(i)
        if ((player:GetActiveItem(ActiveSlot.SLOT_PRIMARY) == registry.COLLECTIBLE_DEVOUT_PRAYER)
        and (Input.IsActionTriggered(ButtonAction.ACTION_ITEM, player.ControllerIndex))) then
            local charge = player:GetActiveCharge(ActiveSlot.SLOT_PRIMARY)
            if (charge > 0) and (charge < 12) then
                print("[The Saint] Test 'Devout Prayer' (SLOT_PRIMARY)")
                player:UseActiveItem(registry.COLLECTIBLE_DEVOUT_PRAYER, UseFlag.USE_OWNED, ActiveSlot.SLOT_PRIMARY)
            end
        else
            if ((player:GetActiveItem(ActiveSlot.SLOT_POCKET) == registry.COLLECTIBLE_DEVOUT_PRAYER)
            and (Input.IsActionTriggered(ButtonAction.ACTION_PILLCARD, player.ControllerIndex))) then
                if (not otherPocketItemUsed) then
                    local charge = player:GetActiveCharge(ActiveSlot.SLOT_POCKET)
                    if (charge > 0) and (charge < 12) then
                        print("[The Saint] Test 'Devout Prayer' (SLOT_POCKET)")
                        player:UseActiveItem(registry.COLLECTIBLE_DEVOUT_PRAYER, UseFlag.USE_OWNED, ActiveSlot.SLOT_POCKET)
                    end
                else
                    otherPocketItemUsed = false
                end
            end
        end
    end
end

-- todo: save counters per player
local counters = {
    luck = 0,
    damage = 0,
    reset = function() end
}
local function resetCounters()
    counters.damage = 0
    counters.luck = 0
end
counters.reset = resetCounters

--- Increases the given players Luck by 0.1 per charge spent.<br>
--- Extra effect: also increases Damage by 0.25 per charge spent.
--- @param chargeValue integer
--- @param player EntityPlayer
--- @param extraEffect boolean
local function effectAddLuck(chargeValue, player, extraEffect)
    local cacheFlags = CacheFlag.CACHE_LUCK
    counters.luck = counters.luck + chargeValue
    if (extraEffect == true) then
        cacheFlags = (cacheFlags | CacheFlag.CACHE_DAMAGE)
        counters.damage = counters.damage + chargeValue
    end
    player:AddCacheFlags(cacheFlags)
    player:EvaluateItems()
end

--- re-evaluates the given players stats after using 'Devout Prayer'
--- @param player EntityPlayer
--- @param flag CacheFlag
local function evaluateStats(_, player, flag)
    if (not player:HasCollectible(registry.COLLECTIBLE_DEVOUT_PRAYER)) then return end

    if (flag & CacheFlag.CACHE_DAMAGE == CacheFlag.CACHE_DAMAGE) then
        player.Damage = player.Damage + (0.25 * counters.damage)
    end

    if (flag & CacheFlag.CACHE_LUCK == CacheFlag.CACHE_LUCK) then
        player.Luck = player.Luck + (0.1 * counters.luck)
    end
end

--- reset counters at the start of a new level
local function postNewLevel_resetCounters()
    counters:reset()
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

--- @param rng RNG
--- @param player EntityPlayer
--- @param extraEffect boolean
local function effectSpawnItem(rng, player, extraEffect)
    local optionIndex = 3 -- todo: adjust index, so that it doesn't interfere with other items in the room
    if (extraEffect == true) then
        optionIndex = 0
    end
    local pool = game:GetItemPool()
    local room = game:GetRoom()
    local c1 = pool:GetCollectible(pool:GetPoolForRoom(room:GetType(), rng:Next()), false, rng:Next())

    -- todo: spawn item from Devil Room pool if Devil Deal has been taken before (must be paid for)
    local poolAngelOrDevil = ItemPoolType.POOL_ANGEL
    local c2 = pool:GetCollectible(poolAngelOrDevil, false, rng:Next())

    Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, c1, room:FindFreePickupSpawnPosition(player.Position, 0, true), Vector.Zero, nil):ToPickup().OptionsPickupIndex = optionIndex
    Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, c2, room:FindFreePickupSpawnPosition(player.Position, 0, true), Vector.Zero, nil):ToPickup().OptionsPickupIndex = optionIndex
end

--- @param collectible CollectibleType
--- @param rng RNG
--- @param player EntityPlayer
--- @param flags UseFlag
--- @param slot ActiveSlot
local function useItem(_, collectible, rng, player, flags, slot)
    print("used 'Devout Prayer'")
    local extraEffect = false
    local dat = utility:getData(player)
    if (dat["TSaint_EternalHeart"] and dat["TSaint_EternalHeart"] == true) then
        player:AddEternalHearts(-1)
        extraEffect = true
    end
    local charge = player:GetActiveCharge(slot) + player:GetBatteryCharge(slot)
    print("[The Saint] current charge: "..charge)

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
                    effectSpawnItem(player, extraEffect)
                end
            end
        end
        effectAddLuck(chargeSpent, player, extraEffect)
        print("[The Saint] charge spent: "..chargeSpent)
        player:SetActiveCharge(charge - chargeSpent, slot)
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
    mod:AddCallback(ModCallbacks.MC_POST_ENTITY_KILL, postEntityKill)
    mod:AddCallback(ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD, preSpawnCleanAward)
    mod:AddCallback(ModCallbacks.MC_USE_CARD, useOtherPocketItem)
    mod:AddCallback(ModCallbacks.MC_USE_PILL, useOtherPocketItem)
    mod:AddCallback(ModCallbacks.MC_POST_UPDATE, postUpdate)
    mod:AddCallback(ModCallbacks.MC_USE_ITEM, useItem, registry.COLLECTIBLE_DEVOUT_PRAYER)
    mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, postNewLevel_resetCounters)
    mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, evaluateStats, CacheFlag.CACHE_DAMAGE)
    mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, evaluateStats, CacheFlag.CACHE_LUCK)
end

return Devout_Prayer
