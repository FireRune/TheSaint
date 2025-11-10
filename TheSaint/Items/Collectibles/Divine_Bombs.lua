local enums = require("TheSaint.Enums")

--[[
    "Divine Bombs"<br>
    - +5 bombs<br>
    - Bombs spawn 'Holy Light' beams upon exploding
]]
local Divine_Bombs = {}

local targetFlag = TearFlags.TEAR_LIGHT_FROM_HEAVEN

local v = {
	room = {}
}

--- Spawn a 'Holy Light'-beam
--- @param pos Vector
--- @param spawner? Entity default: `nil`
local function spawnHolyLight(pos, spawner)
    Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CRACK_THE_SKY, 0, pos, Vector.Zero, spawner)
end

--- Spawns 'Holy Light'-beams at the given position, as well as at the position of all surrounding enemies
--- @param pos Vector
--- @param spawner? Entity default: `nil`
local function triggerHolyLight(pos, spawner)
    spawnHolyLight(pos, spawner)
    local entities = Isaac.GetRoomEntities()
    for i = 1, #entities do
        local enemy = entities[i]
        if enemy:IsVulnerableEnemy() then
            if ((enemy.Position - pos):Length() <= 150) then
                spawnHolyLight(enemy.Position, spawner)
            end
        end
    end
end

--- Add effect only to bombs spawned by the player
--- @param bomb EntityBomb
local function postBombInit(_, bomb)
    if (bomb.Variant == BombVariant.BOMB_GIGA) then return end
    if bomb.SpawnerEntity then
        local player = bomb.SpawnerEntity:ToPlayer()
        if player then
			local ptr = GetPtrHash(bomb)
            v.room[ptr] = {["firstFrame"] = true}
        end
    end
end

--- Add 'Holy Light'-effect to bombs
--- @param bomb EntityBomb
local function postBombUpdate(_, bomb)
    if (bomb.Variant == BombVariant.BOMB_GIGA) then return end
    if bomb.SpawnerEntity then
        local player = bomb.SpawnerEntity:ToPlayer()
        if player then
			local ptr = GetPtrHash(bomb)
            local data = v.room[ptr]
            if (data and data["firstFrame"] == true) then
                if player:HasCollectible(enums.CollectibleType.COLLECTIBLE_DIVINE_BOMBS) then
                    bomb:AddTearFlags(targetFlag)
                end
                data["firstFrame"] = nil
                if bomb.IsFetus then
                    local rng = player:GetCollectibleRNG(CollectibleType.COLLECTIBLE_DR_FETUS)
                    local chance = (30 + (5 * player.Luck))
                    if ((rng:RandomInt(100) + 1) > chance) then
                        bomb:ClearTearFlags(targetFlag)
                    end
                end
            end
			if bomb:HasTearFlags(targetFlag) then
				if bomb:GetSprite():IsPlaying("Explode") then
					triggerHolyLight(bomb.Position, player)
				end
			end
        end
    end
end

--- Add bomb effect to 'Epic Fetus'-rockets
--- @param effect EntityEffect
local function postEffectInit(_, effect)
    if effect.SpawnerEntity then
        local parentEffect = effect.SpawnerEntity:ToEffect()
        if parentEffect and (parentEffect.Variant == EffectVariant.ROCKET) then
            if parentEffect.SpawnerEntity then
                local player = parentEffect.SpawnerEntity:ToPlayer()
                if player then
					local ptr = GetPtrHash(effect)
                    v.room[ptr] = {
                        ["firstFrame"] = true,
                        ["spawnerPlayer"] = player
                    }
                end
            end
        end
    end
end

--- Synergy 'Epic Fetus' + 'Divine Bombs' or 'Holy Light' (due to TearFlags.LIGHT_FROM_HEAVEN)
--- @param effect EntityEffect
local function postEffectUpdate(_, effect)
	if (effect.SpawnerEntity) then
		local parentEffect = effect.SpawnerEntity:ToEffect()
		if (parentEffect and (parentEffect.Variant == EffectVariant.ROCKET)) then
			local ptr = GetPtrHash(effect)
			local data = v.room[ptr]
			if (data and data["firstFrame"] == true) then
				local player = data["spawnerPlayer"]
				if player:HasCollectible(CollectibleType.COLLECTIBLE_HOLY_LIGHT)
				or player:HasCollectible(enums.CollectibleType.COLLECTIBLE_DIVINE_BOMBS) then
					local rng = player:GetCollectibleRNG(CollectibleType.COLLECTIBLE_EPIC_FETUS)
					local chance = (30 + (5 * player.Luck))
					if ((rng:RandomInt(100) + 1) <= chance) then
						triggerHolyLight(effect.Position, player)
					end
				end
				data["firstFrame"] = nil
				data["spawnerPlayer"] = nil
			end
		end
	end
end

--- Initialize the item's functionality.
--- @param mod ModReference
function Divine_Bombs:Init(mod)
	mod:saveDataManager("Divine_Bombs", v)
    mod:AddCallback(ModCallbacks.MC_POST_BOMB_INIT, postBombInit)
    mod:AddCallback(ModCallbacks.MC_POST_BOMB_UPDATE, postBombUpdate)
    mod:AddCallback(ModCallbacks.MC_POST_EFFECT_INIT, postEffectInit, EffectVariant.BOMB_EXPLOSION)
    mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, postEffectUpdate, EffectVariant.BOMB_EXPLOSION)
end

return Divine_Bombs
