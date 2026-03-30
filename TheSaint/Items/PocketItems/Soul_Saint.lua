local isc = require("TheSaint.lib.isaacscript-common")
local enums = require("TheSaint.Enums")
local ddTracking = require("TheSaint.DevilDealTracking")
local featureTarget = require("TheSaint.structures.FeatureTarget")

local game = Game()

--- "Soul of The Saint"
--- - teleports Isaac to a special Angel Room with 2 items both can be taken
--- - if a Devil Deal has been taken during the run:
---   - acts like "Joker"
---   - forces an Angel Room if the Devil/Angel Room hasn't been generated yet
--- @class TheSaint.Items.PocketItems.Soul_Saint : TheSaint.classes.ModFeatureTargeted<Card>
local Soul_Saint = {
	IsInitialized = false,
	--- @type TheSaint.structures.FeatureTarget<Card>
	Target = featureTarget:new(enums.Card.CARD_SOUL_SAINT),
	SaveDataKey = "Soul_Saint",
}

local v = {
	level = {
		SpecialAngelRoom = {
			Generated = false,
			FirstVisit = true,
		},
	},
}

local SPECIAL_ANGEL_VARIANT = 101

--- @param card Card
--- @param player EntityPlayer
--- @param flags UseFlag
local function useCard(_, card, player, flags)
	local level = game:GetLevel()

	-- check wether Devil/Angel room has already been generated
	if (level:GetRoomByIdx(GridRooms.ROOM_DEVIL_IDX).Data == nil) then
		level:InitializeDevilAngelRoom(true, false)

		-- if no Devil deal has been taken, change Angel Room to special variant
		if (not ddTracking:HasDevilDealBeenTaken()) then
			v.level.SpecialAngelRoom.Generated = true
			local roomData = isc:getRoomDataForTypeVariant(RoomType.ROOM_ANGEL, SPECIAL_ANGEL_VARIANT)
			isc:setRoomData(GridRooms.ROOM_DEVIL_IDX, roomData)
		end
	end

	local useFlag = (UseFlag.USE_NOANIM | UseFlag.USE_NOANNOUNCER | UseFlag.USE_NOHUD)
	--- @cast useFlag UseFlag
	player:UseCard(Card.CARD_JOKER, useFlag)
end

--- when entering the special Angel Room for the first time, change all item pedestals' OptionsPickupIndex to 0
--- @param room RoomType
local function postNewRoomReordered(_, room)
	local level = game:GetLevel()

	if (level:GetCurrentRoomIndex() ~= GridRooms.ROOM_DEVIL_IDX) then return end
	if (not (v.level.SpecialAngelRoom.Generated and v.level.SpecialAngelRoom.FirstVisit)) then return end

	for _, ent in ipairs(Isaac.GetRoomEntities()) do
		local entItem = ent:ToPickup()
		if ((entItem) and (entItem.Variant == 100)) then
			entItem.OptionsPickupIndex = 0
		end
	end
	v.level.SpecialAngelRoom.FirstVisit = false
end

--- Initialize this item's functionality
--- @param mod ModUpgraded
function Soul_Saint:Init(mod)
	if (self.IsInitialized) then return end

	mod:saveDataManager(self.SaveDataKey, v)
	mod:AddCallback(ModCallbacks.MC_USE_CARD, useCard, self.Target.Type)
	mod:AddCallbackCustom(isc.ModCallbackCustom.POST_NEW_ROOM_REORDERED, postNewRoomReordered, RoomType.ROOM_ANGEL)
end

return Soul_Saint
