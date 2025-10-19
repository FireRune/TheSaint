local enums = require("TheSaint.Enums")

local game = Game()

--[[
    "Holy Penny"
    - picking up coins has a chance to spawn an Eternal Heart
]]
local Holy_Penny = {}

--- @param pickup EntityPickup
--- @param collider Entity
local function onPickup(_, pickup, collider)
    if (collider.Type == EntityType.ENTITY_PLAYER and pickup.Type == EntityType.ENTITY_PICKUP) then
        if (pickup.Variant == PickupVariant.PICKUP_COIN) then
            local player = collider:ToPlayer()
            if (player and player:HasTrinket(enums.TrinketType.TRINKET_HOLY_PENNY)) then
                local rng = player:GetTrinketRNG(enums.TrinketType.TRINKET_HOLY_PENNY)
                if (rng:RandomFloat() < (1 - (0.8334 ^ pickup:GetCoinValue()))) then
                    Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_HEART, HeartSubType.HEART_ETERNAL, game:GetRoom():FindFreePickupSpawnPosition(player.Position, 0, true), Vector.Zero, nil)
                end
            end
        end
    end
end

--- Initialize this item's functionality
--- @param mod ModReference
function Holy_Penny:Init(mod)
    mod:AddCallback(ModCallbacks.MC_PRE_PICKUP_COLLISION, onPickup)
end

return Holy_Penny
