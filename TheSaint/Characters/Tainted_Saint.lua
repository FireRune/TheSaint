local isc = require("TheSaint.lib.isaacscript-common")
local enums = require("TheSaint.Enums")

local game = Game()

--- @class TheSaint.Characters.Tainted_Saint : TheSaint_Feature
local Tainted_Saint = {
    IsInitialized = false,
    FeatureSubType = enums.PlayerType.PLAYER_THE_SAINT_B,
}

local playersDamageTaken = {}

--- "Tainted Saint" took damage that invokes penalties (i.e. decreasing Devil/Angel chance)
--- @param ent Entity
--- @param flag DamageFlag
local function onDmgTaken(_, ent, _, flag)
    local player = ent:ToPlayer()
	if player then
		local pType = player:GetPlayerType()
		if (pType == Tainted_Saint.FeatureSubType) then
			if (flag & DamageFlag.DAMAGE_RED_HEARTS ~= DamageFlag.DAMAGE_RED_HEARTS)
			and (flag & DamageFlag.DAMAGE_NO_PENALTIES ~= DamageFlag.DAMAGE_NO_PENALTIES) then
                local playerIndex = "TSaint_DmgTaken_"..isc:getPlayerIndex(player)
                playersDamageTaken[playerIndex] = true
			end
		end
	end
end

--- return the number of fully depleted heart containers
--- @param player EntityPlayer
--- @return integer
local function getEmptyContainers(player)
    local emptyContainers = ((player:GetMaxHearts() - player:GetHearts()) // 2)
    return emptyContainers
end

--- When taking damage that causes penalties, turn all empty containers into Broken Hearts.<br>
--- (with "Birthright" only 1 Heart Container will turn into a Broken Heart instead.)<br>
--- Remove any Soul Hearts, that may be applied through items.
--- @param player EntityPlayer
local function postPlayerUpdate_TSaint_Hearts(_, player)
    if (player:GetPlayerType() == Tainted_Saint.FeatureSubType) then
        local playerIndex = "TSaint_DmgTaken_"..isc:getPlayerIndex(player)
		-- player took damage that causes penalties, then remove all empty Heart Containers, replace with Broken Hearts
		if (playersDamageTaken[playerIndex] == true) then
            local emptyContainers = getEmptyContainers(player)
            if (emptyContainers > 0) then
                if (player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT)) then
                    emptyContainers = 1
                end
                player:AddMaxHearts(emptyContainers * -2)
                player:AddBrokenHearts(emptyContainers)
            end
			playersDamageTaken[playerIndex] = false
		end
        -- "Tainted Saint" can't utilize Soul/Black Hearts
        local soulHearts = player:GetSoulHearts()
        if (soulHearts > 0) then
            player:AddSoulHearts(-soulHearts)
        end
    end
end

--- Heart Containers removed as payment will be replaced with Broken Hearts
--- @param player EntityPlayer
--- @param item EntityPickup
local function preGetPedestal_TSaint_BrokenHearts(_, player, item)
    if (item.Price == PickupPrice.PRICE_ONE_HEART)
    or (item.Price == PickupPrice.PRICE_ONE_HEART_AND_TWO_SOULHEARTS)
    or (item.Price == PickupPrice.PRICE_ONE_HEART_AND_ONE_SOUL_HEART) then
        player:AddBrokenHearts(1)
    elseif (item.Price == PickupPrice.PRICE_TWO_HEARTS) then
        player:AddBrokenHearts(2)
    end
end

--- chance to replace Soul/Black/Blended Hearts with an Eternal Heart while playing as "Tainted Saint"
--- @param heart EntityPickup
local function postPickupInitFirst_TSaint_Hearts(_, heart)
    for i = 0, game:GetNumPlayers() - 1 do
        local player = Isaac.GetPlayer(i)
        if (player:GetPlayerType() == Tainted_Saint.FeatureSubType) then
            if (heart.SubType == HeartSubType.HEART_SOUL)
            or (heart.SubType == HeartSubType.HEART_BLACK)
            or (heart.SubType == HeartSubType.HEART_HALF_SOUL)
            or (heart.SubType == HeartSubType.HEART_BLENDED) then
                local rng = player:GetDropRNG()
                if ((rng:RandomInt(20) + 1) == 20) then
                    heart:Morph(heart.Type, heart.Variant, HeartSubType.HEART_ETERNAL, true)
                end
            end
			return -- attempt to replace only once, in case more than 1 player is "Tainted Saint"
        end
    end
end

--- prevent "Tainted Saint" from picking up Soul/Black Hearts, as well as Blended Hearts while at full health
--- @param heart EntityPickup
--- @param collider Entity
local function prePickupCollision_TSaint_Hearts(_, heart, collider)
    local player = collider:ToPlayer()
    if player and (player:GetPlayerType() == Tainted_Saint.FeatureSubType) then
        if (heart.SubType == HeartSubType.HEART_SOUL)
        or (heart.SubType == HeartSubType.HEART_BLACK)
        or (heart.SubType == HeartSubType.HEART_HALF_SOUL)
        or ((heart.SubType == HeartSubType.HEART_BLENDED) and (player:GetHearts() >= player:GetMaxHearts())) then
            return false
        end
    end
end

--- When using "Esau Jr." for the first time as "Tainted Saint" in a run,<br>
--- sets health to 1 full Heart Container + 2 Broken Hearts and re-add "Devout Prayer"
--- @param player EntityPlayer
local function postFirstEsauJr(_, player)
    if (player:GetPlayerType() == Tainted_Saint.FeatureSubType) then
        player:AddMaxHearts(2)
        player:AddHearts(2)
        player:AddBrokenHearts(2)
        -- prevent "Devout Prayer" from being removed
        player:SetPocketActiveItem(enums.CollectibleType.COLLECTIBLE_DEVOUT_PRAYER, ActiveSlot.SLOT_POCKET, false)
    end
end

-- Used to store the current amount of Heart Containers when picking up "Abaddon".
local abaddonHeartsRemoved = 0

--- Store the current amount of Heart Containers when picking up "Abaddon".
--- @param player EntityPlayer
local function preItemPickup_Abaddon(_, player, _)
	if (player:GetPlayerType() == Tainted_Saint.FeatureSubType) then
		abaddonHeartsRemoved = math.max(0, (player:GetMaxHearts() // 2) - 1)
	end
end

--- Picking up "Abaddon" would turn all Heart Containers into Black Hearts.<br>
--- For "Tainted Saint" instead sets health to 1 Heart Containter with half a heart<br>
--- and replace all other Heart Containers with Broken Hearts.
--- @param player EntityPlayer
local function postItemPickup_Abaddon(_, player, _)
	if (player:GetPlayerType() == Tainted_Saint.FeatureSubType) then
		player:AddMaxHearts(2)
		player:AddHearts(1)
		if (abaddonHeartsRemoved > 0) then
			player:AddBrokenHearts(abaddonHeartsRemoved)
			abaddonHeartsRemoved = 0
		end
	end
end

--- @param mod ModReference
function Tainted_Saint:Init(mod)
    if (self.IsInitialized) then return end

	mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, onDmgTaken, EntityType.ENTITY_PLAYER)
	mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, postPlayerUpdate_TSaint_Hearts, 0)
	mod:AddCallbackCustom(isc.ModCallbackCustom.PRE_GET_PEDESTAL, preGetPedestal_TSaint_BrokenHearts, 0, self.FeatureSubType)
	mod:AddCallbackCustom(isc.ModCallbackCustom.POST_PICKUP_INIT_FIRST, postPickupInitFirst_TSaint_Hearts, PickupVariant.PICKUP_HEART)
	mod:AddCallback(ModCallbacks.MC_PRE_PICKUP_COLLISION, prePickupCollision_TSaint_Hearts, PickupVariant.PICKUP_HEART)
	mod:AddCallbackCustom(isc.ModCallbackCustom.POST_FIRST_ESAU_JR, postFirstEsauJr)
	mod:AddCallbackCustom(isc.ModCallbackCustom.PRE_ITEM_PICKUP, preItemPickup_Abaddon, ItemType.ITEM_PASSIVE, CollectibleType.COLLECTIBLE_ABADDON)
	mod:AddCallbackCustom(isc.ModCallbackCustom.POST_ITEM_PICKUP, postItemPickup_Abaddon, ItemType.ITEM_PASSIVE, CollectibleType.COLLECTIBLE_ABADDON)
end

return Tainted_Saint
