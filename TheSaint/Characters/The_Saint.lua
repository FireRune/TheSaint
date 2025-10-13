local isc = require("TheSaint.lib.isaacscript-common")
local stats = include("TheSaint.stats")
local registry = include("TheSaint.ItemRegistry")

local The_Saint = {}

local char = Isaac.GetPlayerTypeByName(stats.default.name, false)

--- When using 'Esau Jr.' for the first time as 'The Saint' in a run, re-add 'Almanach'
--- @param player EntityPlayer
local function postFirstEsauJr(_, player)
    if (player:GetPlayerType() == char) then
        -- prevent 'Almanach' from being removed
        player:SetPocketActiveItem(registry.COLLECTIBLE_ALMANACH, ActiveSlot.SLOT_POCKET, false)
    end
end

--- @param mod ModReference
function The_Saint:Init(mod)
	mod:AddCallbackCustom(isc.ModCallbackCustom.POST_FIRST_ESAU_JR, postFirstEsauJr)
end

return The_Saint
