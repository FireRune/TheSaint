--- @class TheSaint.structures.FeatureTarget.TargetEntity
--- @field Type EntityType
--- @field Variant integer
--- @field SubType integer?

--- @generic T: CollectibleType | TrinketType | Card | PillEffect | PlayerType | PickupVariant
--- @class TheSaint.structures.FeatureTarget<T>
--- @field Type T
--- @field Entity TheSaint.structures.FeatureTarget.TargetEntity? @ if that feature spawns an entity, specify the corresponding Type, Variant (and optionally SubType) here
--- @field Character PlayerType[]? @ specifies the player type(s), to which this feature should be applied innately
local FeatureTarget = {}

--- @param tvs string
--- @return TheSaint.structures.FeatureTarget.TargetEntity?
local function getTargetEntityFromTVS(tvs)
	local strTable = {}
	for str in tvs:gmatch("%d+") do
		table.insert(strTable, str)
	end

	-- couldn't extract a number
	if (#strTable == 0) then return end

	local t = tonumber(strTable[1])
	if (not t) then return end

	local v = ((strTable[2] and tonumber(strTable[2])) or 0)
	local s = (strTable[3] and tonumber(strTable[3]))

	--- @type TheSaint.structures.FeatureTarget.TargetEntity
	return {
		Type = t,
		Variant = v,
		SubType = s
	}
end

--- @generic T: CollectibleType | TrinketType | Card | PillEffect | PlayerType | PickupVariant
--- @param targetType T
--- @param entityTVS? string | integer[]
--- @param character? PlayerType | PlayerType[]
--- @return TheSaint.structures.FeatureTarget<T>
function FeatureTarget:new(targetType, entityTVS, character)
	--- @type PlayerType[]?
	local charTable = nil
	if (character and type(character) ~= "table") then
		charTable = {character}
	elseif (type(character) == "table") then
		charTable = character
	end

	local entity = nil
	if (entityTVS) then
		if (type(entityTVS) == "table") then
			entityTVS = table.concat(entityTVS, ".")
		end
		entity = getTargetEntityFromTVS(entityTVS)
	end

	return {
		Type = targetType,
		Entity = entity,
		Character = charTable,
	}
end

return FeatureTarget
