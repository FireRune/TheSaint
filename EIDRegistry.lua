local registry = include("ItemRegistry")

if EID then
    local desc = ""

	desc = "Invokes the effects of 2 'book'-items.#Can also invoke Books that haven't been unlocked yet."
	EID:addCollectible(registry.COLLECTIBLE_ALMANACH, desc)
end
