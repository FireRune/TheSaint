local isc = require("TheSaint.lib.isaacscript-common")
local stats = include("TheSaint.stats")
local registry = include("TheSaint.ItemRegistry")

local Tainted_Saint = {}

local game = Game()
local taintedChar = Isaac.GetPlayerTypeByName(stats.tainted.name, true)

-- 'Tainted Saint'-mechanics BEGIN

--[[
    TODO: interactions with the following items:
    - 'Abbadon':
        on collecting, set health to 1 Heart Container with half a heart (MaxHearts = 2, Hearts = 1)
        also turn all lost Heart Containers to Broken Hearts
    - 'Esau Jr.':
        on first activation set health to 1 Heart container and 2 Broken Hearts (MaxHearts = 2, Hearts = 2, BrokenHearts = 2)
        also make sure to retain 'Mending Heart'
]]

local playersDamageTaken = {}

--- 'Tainted Saint' took damage that invokes penalties (i.e. decreasing Devil/Angel chance)
--- @param ent Entity
--- @param flag DamageFlag
local function onDmgTaken(_, ent, _, flag)
    local player = ent:ToPlayer()
	if player then
		local pType = player:GetPlayerType()
		if (pType == taintedChar) then
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

--- when taking damage that causes penalties, turn all empty containers into Broken Hearts.
--- also, remove any Soul Hearts.
--- @param player EntityPlayer
local function postPlayerUpdate_TSaint_Hearts(_, player)
    if (player:GetPlayerType() == taintedChar) then
        local playerIndex = "TSaint_DmgTaken_"..isc:getPlayerIndex(player)
		-- player took damage that causes penalties, then remove all empty Heart Containers, replace with Broken Hearts
		if (playersDamageTaken[playerIndex] == true) then
            local emptyContainers = getEmptyContainers(player)
            player:AddMaxHearts(emptyContainers * -2)
			player:AddBrokenHearts(emptyContainers)
			playersDamageTaken[playerIndex] = false
		end
        -- T.Saint can't utilize Soul/Black Hearts
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

--- chance to replace Soul/Black/Blended Hearts with an Eternal Heart while playing as 'Tainted Saint'
--- @param heart EntityPickup
local function postPickupInitFirst_TSaint_Hearts(_, heart)
    for i = 0, game:GetNumPlayers() - 1 do
        local player = Isaac.GetPlayer(i)
        if (player:GetPlayerType() == taintedChar) then
            if (heart.SubType == HeartSubType.HEART_SOUL)
            or (heart.SubType == HeartSubType.HEART_BLACK)
            or (heart.SubType == HeartSubType.HEART_HALF_SOUL)
            or (heart.SubType == HeartSubType.HEART_BLENDED) then
                local rng = player:GetDropRNG()
                if ((rng:RandomInt(20) + 1) == 20) then
                    heart:Morph(heart.Type, heart.Variant, HeartSubType.HEART_ETERNAL, true)
                end
            end
			return -- attempt to replace only once, in case more than 1 player is 'Tainted Saint'
        end
    end
end

--- prevent 'Tainted Saint' from picking up Soul/Black Hearts, as well as Blended Hearts while at full health
--- @param heart EntityPickup
--- @param collider Entity
local function prePickupCollision_TSaint_Hearts(_, heart, collider)
    local player = collider:ToPlayer()
    if player and (player:GetPlayerType() == taintedChar) then
        if (heart.SubType == HeartSubType.HEART_SOUL)
        or (heart.SubType == HeartSubType.HEART_BLACK)
        or (heart.SubType == HeartSubType.HEART_HALF_SOUL)
        or ((heart.SubType == HeartSubType.HEART_BLENDED) and (player:GetHearts() >= player:GetMaxHearts())) then
            return false
        end
    end
end

--- @param player EntityPlayer
local function postFirstEsauJr(_, player)
    if (player:GetPlayerType() == taintedChar) then
        player:AddMaxHearts(2)
        player:AddHearts(2)
        player:AddBrokenHearts(2)
        -- prevent 'Devout Prayer' from being removed
        player:SetPocketActiveItem(registry.COLLECTIBLE_DEVOUT_PRAYER, ActiveSlot.SLOT_POCKET, false)
    end
end

--- @param mod ModReference
function Tainted_Saint:Init(mod)
	mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, onDmgTaken, EntityType.ENTITY_PLAYER)
	mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, postPlayerUpdate_TSaint_Hearts, 0)
	mod:AddCallbackCustom(isc.ModCallbackCustom.PRE_GET_PEDESTAL, preGetPedestal_TSaint_BrokenHearts, 0, taintedChar)
	mod:AddCallbackCustom(isc.ModCallbackCustom.POST_PICKUP_INIT_FIRST, postPickupInitFirst_TSaint_Hearts, PickupVariant.PICKUP_HEART)
	mod:AddCallback(ModCallbacks.MC_PRE_PICKUP_COLLISION, prePickupCollision_TSaint_Hearts, PickupVariant.PICKUP_HEART)
	mod:AddCallbackCustom(isc.ModCallbackCustom.POST_FIRST_ESAU_JR, postFirstEsauJr)
end

-- 'Tainted Saint'-mechanics END

return Tainted_Saint