# Must be finished for initial release

## Content

- [x] Soul of the Saint
- teleports Isaac to a special Angel Room that contains 2 Items (both can be taken)
- if a Devil Deal has been taken, acts like Joker but guarantees an Angel Room if the current floor's Devil/Angel Room hasn't been generated yet.

## Code

### General

- [x] Handling of unlocks for both characters' completion marks

- [x] actual Book of Virtues wisps for the following active items:
- Devout Prayer (2 variations)
- Wooden Key

### Unlocks.lua
- The Saint:
	- [ ] Boss Rush
	- [x] Mom's Heart on Hard Mode (Almanach)
	- [x] Satan (Scorched Baby)
	- [x] Isaac (Divine Bombs)
	- [x] The Lamb (Scattered Pages)
	- [x] ??? (Protective Candle)
	- [ ] Mega Satan (maybe co-op baby?)
	- [x] Hush (Wooden Key)
	- [x] Greed Mode (Library Card)
	- [ ] Greedier Mode
	- [ ] Delirium
	- [ ] Mother
	- [x] The Beast (Holy Hand Grenade)
- Tainted Saint:
	- [x] Boss Rush + Hush (Soul of the Saint)
	- [ ] Satan + Isaac + The Lamb + ??? (Trinket)
	- [x] Greedier Mode (Red Joker)
	- [x] Delirium (Mending Heart)
	- [x] Mother (Holy Penny)
	- [x] The Beast (Rite of Rebirth)
	- [ ] Mega Satan (Pickup or Object)

### Almanach.lua

- [x] allow adding entries to the blacklist as an API call

### Devout_Prayer.lua

- [x] function `effectSpawnItem`: change the 2nd spawned item
	- if a devil deal has been taken during the run:
		- spawn an empty item pedestal (50% chance)
		- spawn an item from the devil pool (50% chance)

## Assets

add character sprites for:
- [ ] The Saint:
	- [ ] vs. screen / stage transition
	- [ ] player select screen
	- [ ] starting room controls
	- [x] co-op menu icon
	- [x] EID character icon
- [ ] Tainted Saint:
	- [ ] vs. screen / stage transition
	- [ ] player select screen
	- [ ] starting room controls
	- [x] co-op menu icon
	- [x] EID character icon

add item sprites for:
- items:
	- [ ] Devout Prayer
	- [x] Wooden Key
	- [ ] Holy Hand Grenade
	- [ ] Rite of Rebirth
	- [x] Protective Candle
- trinkets:
	- [x] Scattered Pages

add collection page sprites for:
- [ ] Almanach
- [ ] Devout Prayer
- [ ] Mending Heart
- [ ] Divine Bombs
- [ ] Wooden Key
- [ ] Holy Hand Grenade
- [ ] Rite of Rebirth
- [ ] Scorched Baby
- [ ] Protective Candle

add character costumes/entity sprites for:
- [ ] Holy Hand Grenade (entity)
- [ ] Rite of Rebirth (costume)
- [x] Protective Candle (entity)

add front/back sprites + anims for:
- [x] Library Card
- [x] Soul of the Saint
- [x] Red Joker

# future features
## Holy_Hand_Grenade.lua

- [ ] change how throwing the grenade is handled, to be more akin to the source material
	- after pressing a shooting input: store the direction, hold the grenade entity above the player and show an animated speech bubble (counting to 3)
	- on reaching the number 3, throws the grenade entity in the stored direction (allows the player to reposition)
	- grenade entity can bounce once when colliding with the ground, a wall or a grid entity and explode on the second collision
		- if first collision is with an enemy, will explode immedeately instead

## Protective_Candle.lua
additional behaviour of flame projectile if player has following effects
- [ ] homing: purple flame, flame homes in on nearby enemies
- [ ] "Continuum": flame goes through walls, loops around the screen

## Mod integration

- [ ] Repentogon support
	- [ ] Devout_Prayer.lua
		- correctly interact with "? Card" via MC_PRE_USE_CARD
		- show item as usable even if not fully charged
	- [ ] Rite_of_Rebirth.lua
		- rework entirely
