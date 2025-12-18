--- @diagnostic disable: undefined-doc-name
--- @generic T
--- @class TheSaint.structures.FeatureTarget<T>
--- @field Type T
--- @field Familiar FamiliarVariant? @ if that feature spawns a familiar, specify the corresponding `FamiliarVariant` here
--- @field Character PlayerType[]? @ specifies the player type(s), to which this feature should be applied innately
local FeatureTarget = {}
--- @diagnostic enable: undefined-doc-name

--- @generic T
--- @param targetType T
--- @param familiar FamiliarVariant?
--- @param character (PlayerType | PlayerType[])?
--- @return TheSaint.structures.FeatureTarget<T>
function FeatureTarget:new(targetType, familiar, character)
	--- @type PlayerType[]?
	local charTable = nil
	if (character and type(character) ~= "table") then
		charTable = {character}
	elseif (type(character) == "table") then
		charTable = character
	end

	return {
		Type = targetType,
		Familiar = familiar,
		Character = charTable,
	}
end

return FeatureTarget
