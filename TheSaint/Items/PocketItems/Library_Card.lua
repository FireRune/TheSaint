local enums = require("TheSaint.Enums")

local game = Game()

--[[
	"Library Card"<br>
	- teleports Isaac to the Library if one exists on the current floor<br>
	- random teleport otherwise
]]
local Library_Card = {}

--- @param card Card
--- @param player EntityPlayer
--- @param flags UseFlag
local function useCard(_, card, player, flags)
	local level = game:GetLevel()
end

--- Initialize this item's functionality
--- @param mod ModReference
function Library_Card:Init(mod)
	mod:AddCallback(ModCallbacks.MC_USE_CARD, useCard, enums.Card.CARD_LIBRARY)
end

return Library_Card
