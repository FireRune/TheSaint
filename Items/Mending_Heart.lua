local registry = include("ItemRegistry")
local game = Game()
local item = {}

--[[
    At the start of each new floor, replaces 1 Broken Heart with an empty Heart Container.
    When no damage was taken on the previous floor, will replace 2 instead.
]]

local playMovie = -1

local function postNewLevel()
    for i = 0, game:GetNumPlayers() - 1 do
        local player = Isaac.GetPlayer(i)
        if player:HasCollectible(registry.COLLECTIBLE_MENDING_HEART) then
            if (player:GetBrokenHearts() > 0) then
				local amount = 1
				if (game:GetStagesWithoutDamage() > 0) then amount = 2 end
                player:AddBrokenHearts(-amount)
				player:AddMaxHearts(2 * amount)
                playMovie = 0
            end
        end
    end
end

local mov = Sprite()
mov:Load("gfx/ui/giantbook/giantbook_mendingheart.anm2", true)
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

function item:Init(mod)
    mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, postNewLevel)
    mod:AddCallback(ModCallbacks.MC_POST_RENDER, postRender)
end

return item
