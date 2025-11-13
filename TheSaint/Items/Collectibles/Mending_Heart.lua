local isc = require("TheSaint.lib.isaacscript-common")
local enums = require("TheSaint.Enums")

local taintedChar = enums.PlayerType.PLAYER_THE_SAINT_B
local game = Game()

--[[
    "Mending Heart"<br>
    - At the start of each new floor, replaces 1 Broken Heart with an empty Heart Container<br>
    - When no damage was taken on the previous floor, will replace 2 instead
]]
local Mending_Heart = {}

--- animation state flag
local playMovie = -1

-- prevent accidental trigger when starting a new run as "Tainted Saint"
local blockNewRun = true

--- Prevents the item's effect when starting a new run
--- @param isContinue boolean
local function postGameStartedReordered(_, isContinue)
    blockNewRun = true
end

--- When entering a new floor, replace Broken Heart(s) with empty Heart Container(s), then set the animation flag
--- @param stage LevelStage
--- @param stageType StageType
local function postNewLevelReordered(_, stage, stageType)
    for i = 0, game:GetNumPlayers() - 1 do
        local player = Isaac.GetPlayer(i)
        if (player:HasCollectible(enums.CollectibleType.COLLECTIBLE_MENDING_HEART)
        or ((player:GetPlayerType() == taintedChar) and (blockNewRun == false))) then
            if (player:GetBrokenHearts() > 0) then
				local amount = 1
				if (game:GetStagesWithoutDamage() > 0) then amount = 2 end
                player:AddBrokenHearts(-amount)
				player:AddMaxHearts(2 * amount)
                playMovie = 0
            end
        else
            blockNewRun = false
        end
    end
end

--- giantbook animation
local mov = Sprite()
mov:Load("gfx/ui/giantbook/giantbook_mendingheart.anm2", true)

--- play the animation for 'mending' the Broken Heart(s)
local function postRender()
    if (playMovie == 0) then
        playMovie = 1
        mov:Play("Appear", true)
        mov:SetFrame("Appear", 0)
        mov:SetOverlayRenderPriority(true)
        mov:Render(Vector(240, 135), Vector.Zero, Vector.Zero)
    elseif (playMovie == 1) then
        if (mov:GetFrame() < 28 and game:GetFrameCount() % 2 == 0) then
            mov:SetFrame("Appear", mov:GetFrame() + 1)
        end
        mov:SetOverlayRenderPriority(true)
        mov:Render(Vector(240, 135), Vector.Zero, Vector.Zero)
        if (mov:GetFrame() == 28) then
            playMovie = -1
        end
    end
end

--- Initialize the item's functionality
--- @param mod ModReference
function Mending_Heart:Init(mod)
    mod:AddCallbackCustom(isc.ModCallbackCustom.POST_GAME_STARTED_REORDERED, postGameStartedReordered, false)
    mod:AddCallbackCustom(isc.ModCallbackCustom.POST_NEW_LEVEL_REORDERED, postNewLevelReordered)
    mod:AddCallback(ModCallbacks.MC_POST_RENDER, postRender)
end

return Mending_Heart
