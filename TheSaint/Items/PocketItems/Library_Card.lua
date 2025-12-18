local enums = require("TheSaint.Enums")
local featureTarget = require("TheSaint.structures.FeatureTarget")

local game = Game()

--- "Library Card"
--- - teleports Isaac to the Library if one exists on the current floor
--- - random teleport otherwise
--- @class TheSaint.Items.PocketItems.Library_Card : TheSaint.classes.ModFeatureTargeted<Card>
local Library_Card = {
	IsInitialized = false,
	--- @type TheSaint.structures.FeatureTarget<Card>
	Target = featureTarget:new(enums.Card.CARD_LIBRARY),
}

--- @param card Card
--- @param player EntityPlayer
--- @param flags UseFlag
local function useCard(_, card, player, flags)
	local level = game:GetLevel()
	-- first get all available Library rooms on the current floor
	local libraries = {}
	local libraries_notVisited = {}
	for i = 0, #level:GetRooms() - 1 do
		local room = level:GetRooms():Get(i)
		if (room.Data.Type == RoomType.ROOM_LIBRARY) then
			table.insert(libraries, room.SafeGridIndex)
			if (room.VisitedCount == 0) then
				table.insert(libraries_notVisited, room.SafeGridIndex)
			end
		end
	end
	local rng = player:GetDropRNG()
	if (#libraries > 0) then
		-- current floor has at least 1 Library -> teleport to 1 of them (prioritize unvisited rooms)
		local randInt = rng:RandomInt(math.maxinteger)
		local tableLibraries = ((#libraries_notVisited > 0 and libraries_notVisited) or libraries)
		local idx = ((randInt % #tableLibraries) + 1)
		local libraryGridIdx = tableLibraries[idx]
		game:StartRoomTransition(libraryGridIdx, Direction.NO_DIRECTION, RoomTransitionAnim.TELEPORT, player)
	else
		-- current floor has no Library -> teleport to random room, except Error Room
		game:MoveToRandomRoom(false, rng:RandomInt(math.maxinteger), player)
	end
end

--- Initialize this item's functionality
--- @param mod ModUpgraded
function Library_Card:Init(mod)
	if (self.IsInitialized) then return end

	mod:AddCallback(ModCallbacks.MC_USE_CARD, useCard, self.Target.Type)
end

return Library_Card
