local mt = {
    __index = {
        items = {},
        costume = {},
        trinket = {},
        card = {},
        pill = {},
        charge = {},
        name = ""
    }
}
function mt.__index:AddItem(id, costume)
    costume = costume or false
    table.insert(self.items, {ID = id, Costume = costume})
end

local chars = {
    default = {},
    tainted = {}
}
setmetatable(chars.default, mt)
setmetatable(chars.tainted, mt)
local character = chars.default
local tainted = chars.tainted

character.items = {}
tainted.items = {}

chars.ModName = "The Saint"

-- Regular Character
character.name = "The Saint"
character.stats = {
    damage = 0.0,
    damageMult = 0.85,
    firedelay = -1.0,
    shotspeed = -0.2,
    range = 3.75,
    speed = 0.2,
    tearflags = TearFlags.TEAR_NORMAL,
    tearcolor = Color(1, 1, 1, 1, 0, 0, 0),
    flying = false,
    luck = 0
}
character.costume = "character_sainthair"
character.trinket = TrinketType.TRINKET_NULL
character.card = Card.CARD_NULL
character.pill = false
character.charge = -1

-- Tainted Character
tainted.name = "The Saint B"
tainted.stats = {
    damage = 0.0,
    damageMult = 1.2,
    firedelay = 0.0,
    shotspeed = -0.1,
    range = 3.0,
    speed = 0.2,
    tearflags = TearFlags.TEAR_NORMAL,
    tearcolor = Color(0.65, 0, 0, 1, 0, 0, 0),
    flying = false,
    luck = -1
}
tainted.costume = "character_sainthair_b"
tainted.trinket = TrinketType.TRINKET_NULL
tainted.card = Card.CARD_NULL
tainted.pill = false
tainted.charge = -1

return chars
