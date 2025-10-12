local utility = {}

--- checks wether the given player is able to pick up the specified item
--- @param player EntityPlayer
--- @param item EntityPickup
function utility:canPickUpItem(player, item)
    if (item.Type == EntityType.ENTITY_PICKUP)
    and (item.Variant == PickupVariant.PICKUP_COLLECTIBLE)
    and (item.SubType > 0) then
        if (player.ItemHoldCooldown > 0) then return false end
        if player:IsHoldingItem() then return false end
        if (item.Wait > 0) then return false end
        if ((item.Price > 0) and (player:GetNumCoins() < item.Price)) then return false end
        if ((item.Price == PickupPrice.PRICE_ONE_HEART) and (player:GetEffectiveMaxHearts() < 2)) then return false end
        if ((item.Price == PickupPrice.PRICE_TWO_HEARTS) and (player:GetEffectiveMaxHearts() < 2)) then return false end
        if ((item.Price == PickupPrice.PRICE_THREE_SOULHEARTS) and (player:GetSoulHearts() < 1)) then return false end
        if (((item.Price == PickupPrice.PRICE_ONE_HEART_AND_TWO_SOULHEARTS) or (item.Price == PickupPrice.PRICE_ONE_HEART_AND_ONE_SOUL_HEART)) and ((player:GetEffectiveMaxHearts() < 2) or (player:GetSoulHearts() < 1))) then return false end
        return true
    end
    return nil
end

--- checks wether the given player has the specified active item and returns the slot(s) it's in, otherwise returns nil
--- @param player EntityPlayer
--- @param collectible CollectibleType
function utility:getSlotsWithCollectible(player, collectible)
    local slots = {}
    if (player:GetActiveItem(ActiveSlot.SLOT_PRIMARY) == collectible) then
        table.insert(slots, ActiveSlot.SLOT_PRIMARY)
    end
    if (player:GetActiveItem(ActiveSlot.SLOT_SECONDARY) == collectible) then
        table.insert(slots, ActiveSlot.SLOT_SECONDARY)
    end
    if (player:GetActiveItem(ActiveSlot.SLOT_POCKET) == collectible) then
        table.insert(slots, ActiveSlot.SLOT_POCKET)
    end
    if (player:GetActiveItem(ActiveSlot.SLOT_POCKET2) == collectible) then
        table.insert(slots, ActiveSlot.SLOT_POCKET2)
    end
    if (#slots > 0) then return slots else return nil end
end

--- @param rng RNG
function utility:setSeedRNG(rng)
    local seed = Random()
    if (seed == 0) then seed = 1 end
    rng:SetSeed(seed, 35)
end

return utility
