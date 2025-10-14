local registry = include("TheSaint.ItemRegistry")
local stats = include("TheSaint.stats")

if EID then
	local desc = ""
	local extraTable = {}

	desc = "Invokes the effects of 2 'book'-items#Can also invoke Books that haven't been unlocked yet"
	EID:addCollectible(registry.COLLECTIBLE_ALMANACH, desc)

	desc = "Spawns the appropriate wisps of the triggered books"
	extraTable = {bulletpoint = "VirtuesCollectible"..registry.COLLECTIBLE_ALMANACH}
	EID:addCondition(registry.COLLECTIBLE_ALMANACH, CollectibleType.COLLECTIBLE_BOOK_OF_VIRTUES, desc, nil, nil, extraTable)
	EID:addCondition(CollectibleType.COLLECTIBLE_BOOK_OF_VIRTUES, registry.COLLECTIBLE_ALMANACH, desc, nil, nil, extraTable)

	desc = "Entering a new floor will replace 1{{BrokenHeart}} Broken Heart with 1{{EmptyHeart}} empty Heart Container#Will replace 2 instead, if no damage was taken on the previous floor"
	EID:addCollectible(registry.COLLECTIBLE_MENDING_HEART, desc)

	local taintedChar = Isaac.GetPlayerTypeByName(stats.tainted.name, true)
	desc = "Can't use {{SoulHeart}} Soul Hearts#When you take damage, turns all {{EmptyHeart}} empty Heart Containers into {{BrokenHeart}} Broken Hearts (doesn't apply to self-damage)#{{Collectible"..registry.COLLECTIBLE_MENDING_HEART.."}} Entering a new floor will replace 1{{BrokenHeart}} Broken Heart with 1{{EmptyHeart}} empty Heart Container#{{Collectible"..registry.COLLECTIBLE_MENDING_HEART.."}} Will replace 2 instead, if no damage was taken on the previous floor"
	EID:addCharacterInfo(taintedChar, desc, "The Saint")

	desc = "Taking damage that causes penalties will only turn 1{{EmptyHeart}} empty Heart Container into a {{BrokenHeart}} Broken Heart"
	EID:addBirthright(taintedChar, desc, "The Saint")
end
