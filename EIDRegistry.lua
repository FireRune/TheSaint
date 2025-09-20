local registry = include("ItemRegistry")

if EID then
	local desc = ""

	desc = "Invokes the effects of 2 'book'-items.#Can also invoke Books that haven't been unlocked yet."
	EID:addCollectible(registry.COLLECTIBLE_ALMANACH, desc)

	desc = "Entering a new floor will replace 1{{BrokenHeart}} Broken Heart with 1{{EmptyHeart}} empty Heart Container.#Will replace 2 instead, if no damage was taken on the previous floor."
	EID:addCollectible(registry.COLLECTIBLE_MENDING_HEART, desc)
end
