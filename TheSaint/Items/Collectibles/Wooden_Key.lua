local enums = require("TheSaint.Enums")

local game = Game()

--- "Wooden Key"
--- - 3 Room Charge
--- - When used, opens a random door of the room (if possible)
--- - Can also create "Red Room"-doors
--- @class TheSaint.Items.Collectibles.Wooden_Key : TheSaint_Feature
local Wooden_Key = {
	IsInitialized = false,
	FeatureSubType = enums.CollectibleType.COLLECTIBLE_WOODEN_KEY,
	SaveDataKey = "Wooden_Key",
}

local v = {
	room = {
		checkedDoorSlots = {}
	}
}

--- Returns a table containing all possible DoorSlots for the given RoomShape
--- @param shape RoomShape
--- @return DoorSlot[]?
local function getPossibleRoomDoors(shape)
	local doors = nil

	if (shape == RoomShape.ROOMSHAPE_1x1) then
		doors = {DoorSlot.LEFT0, DoorSlot.UP0, DoorSlot.RIGHT0, DoorSlot.DOWN0}
	elseif ((shape == RoomShape.ROOMSHAPE_IH) or (shape == RoomShape.ROOMSHAPE_IIH)) then
		doors = {DoorSlot.LEFT0, DoorSlot.RIGHT0}
	elseif ((shape == RoomShape.ROOMSHAPE_IV) or (shape == RoomShape.ROOMSHAPE_IIV)) then
		doors = {DoorSlot.UP0, DoorSlot.DOWN0}
	elseif (shape == RoomShape.ROOMSHAPE_1x2) then
		doors = {DoorSlot.LEFT0, DoorSlot.UP0, DoorSlot.RIGHT0, DoorSlot.DOWN0, DoorSlot.LEFT1, DoorSlot.RIGHT1}
	elseif (shape == RoomShape.ROOMSHAPE_2x1) then
		doors = {DoorSlot.LEFT0, DoorSlot.UP0, DoorSlot.RIGHT0, DoorSlot.DOWN0, DoorSlot.UP1, DoorSlot.DOWN1}
	elseif ((shape == RoomShape.ROOMSHAPE_2x2)
	or (shape == RoomShape.ROOMSHAPE_LTL)
	or (shape == RoomShape.ROOMSHAPE_LTR)
	or (shape == RoomShape.ROOMSHAPE_LBL)
	or (shape == RoomShape.ROOMSHAPE_LBR)) then
		doors = {DoorSlot.LEFT0, DoorSlot.UP0, DoorSlot.RIGHT0, DoorSlot.DOWN0, DoorSlot.LEFT1, DoorSlot.UP1, DoorSlot.RIGHT1, DoorSlot.DOWN1}
	end

	return doors
end

--- Get number of entries in v.room.checkedDoorSlots, because the length operator `#` always returns 0
--- @return integer
local function getNumCheckedDoorSlots()
	local counter = 0
	for _, _ in pairs(v.room.checkedDoorSlots) do
		counter = (counter + 1)
	end
	return counter
end

--- open a random door in the current room
--- @param rng RNG
--- @param source Entity
local function openDoors(rng, source)
	local room = game:GetRoom()
	local doors = getPossibleRoomDoors(room:GetRoomShape())
	if (doors) then
		-- only check doors if not all have been checked
		if (#doors > getNumCheckedDoorSlots()) then
			local door = nil
			repeat
				local randInt = rng:RandomInt(#doors) + 1
				door = doors[randInt]
			until (not v.room.checkedDoorSlots[door])
			v.room.checkedDoorSlots[door] = true
			if (room:IsDoorSlotAllowed(door)) then
				local gridEntDoor = room:GetDoor(door)
				local isClosed = false
				if (gridEntDoor) then
					isClosed = (not gridEntDoor:IsOpen())
					if (gridEntDoor:IsRoomType(RoomType.ROOM_SECRET)
					or gridEntDoor:IsRoomType(RoomType.ROOM_SUPERSECRET)) then
						gridEntDoor:TryBlowOpen(false, source)
						gridEntDoor:Close(true)
					else
						if (gridEntDoor:IsLocked()) then
							gridEntDoor:SetLocked(false)
						end
					end
					gridEntDoor:Open()
				else
					local level = game:GetLevel()
					local currentRoomIdx = level:GetCurrentRoomIndex()
					level:MakeRedRoomDoor(currentRoomIdx, door)
				end
				if (isClosed) then SFXManager():Play(SoundEffect.SOUND_UNLOCK00) end
			end
		end
	end
end

--- @param collectible CollectibleType
--- @param rng RNG
--- @param player EntityPlayer
--- @param flags UseFlag
local function useItem(_, collectible, rng, player, flags)
	openDoors(rng, player)
	return true
end

--- @param wisp EntityFamiliar
local function wispFamiliarUpdate(_, wisp)
	-- only apply to this item's wisp
	if (wisp.SubType ~= Wooden_Key.FeatureSubType) then return end

	-- on wisp death, trigger "Wooden Key" effect
	if (wisp:HasMortalDamage()) then
		openDoors(wisp:GetDropRNG(), wisp.Parent)
	end
end

--- Initialize the item's functionality
--- @param mod ModReference
function Wooden_Key:Init(mod)
	if (self.IsInitialized) then return end

	mod:saveDataManager(self.SaveDataKey, v)
	mod:AddCallback(ModCallbacks.MC_USE_ITEM, useItem, self.FeatureSubType)
	mod:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, wispFamiliarUpdate, FamiliarVariant.WISP)
end

return Wooden_Key
