local isc = require("TheSaint.lib.isaacscript-common")
local enums = require("TheSaint.Enums")
local ddTracking = require("TheSaint.DevilDealTracking")

local game = Game()

--- "Soul of The Saint"
--- - teleports Isaac to a special Angel Room with 2 items both can be taken
--- - if a Devil Deal has been taken during the run:
---   - acts like "Joker"
---   - forces an Angel Room if the Devil/Angel Room hasn't been generated yet
--- @class TheSaint.Items.PocketItems.Soul_Saint : TheSaint_Feature
local Soul_Saint = {
	IsInitialized = false,
	FeatureSubType = enums.Card.CARD_SOUL_SAINT,
	SaveDataKey = "Soul_Saint",
}

local v = {
	level = {
		specialAngelRoom = {
			generated = false,
			firstVisit = true
		}
	}
}

--- @param card Card
--- @param player EntityPlayer
--- @param flags UseFlag
local function useCard(_, card, player, flags)
	local level = game:GetLevel()
	-- check wether Devil/Angel room has already been generated
	if (level:GetRoomByIdx(GridRooms.ROOM_DEVIL_IDX).Data == nil) then
		level:InitializeDevilAngelRoom(true, false)
		-- if no Devil deal has been taken, change Angel Room to special variant
		if (ddTracking:HasDevilDealBeenTaken() == false) then
			v.level.specialAngelRoom.generated = true
			local roomData = isc:getRoomDataForTypeVariant(RoomType.ROOM_ANGEL, 101)
			isc:setRoomData(GridRooms.ROOM_DEVIL_IDX, roomData)
		end
	end
	local useFlag = (UseFlag.USE_NOANIM | UseFlag.USE_NOANNOUNCER | UseFlag.USE_NOHUD)
	--- @cast useFlag UseFlag
	player:UseCard(Card.CARD_JOKER, useFlag)
end

--- when entering the special Angel Room for the first time, change all item pedestals' OptionsPickupIndex to 0
local function postNewRoom()
	local level = game:GetLevel()
	if (level:GetCurrentRoomIndex() == GridRooms.ROOM_DEVIL_IDX) then
		if (v.level.specialAngelRoom.generated and v.level.specialAngelRoom.firstVisit) then
			for _, ent in ipairs(Isaac.GetRoomEntities()) do
				local entItem = ent:ToPickup()
				if (entItem and entItem.Variant == 100) then
					entItem.OptionsPickupIndex = 0
				end
			end
			v.level.specialAngelRoom.firstVisit = false
		end
	end
end

--- Initialize this item's functionality
--- @param mod ModReference
function Soul_Saint:Init(mod)
	if (self.IsInitialized) then return end

	mod:saveDataManager(self.SaveDataKey, v)
	mod:AddCallback(ModCallbacks.MC_USE_CARD, useCard, self.FeatureSubType)
	mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, postNewRoom)
end

return Soul_Saint
