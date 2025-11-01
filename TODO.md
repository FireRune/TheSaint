# Content

- [x] Soul of the Saint
- teleports Isaac to a special Angel Room that contains 2 Items (both can be taken)
- if a Devil Deal has been taken, acts like Joker but guarantees an Angel Room if the current floor's Devil/Angel Room hasn't been generated yet.

# Code

## General

- [ ] Handling of unlocks for both characters' completion marks
- The Saint:
	- Boss Rush
	- Mom's Heart (Hard Mode)
	- Satan
	- Isaac
	- The Lamb
	- ???
	- Mega Satan (maybe co-op baby?)
	- Hush
	- Greed Mode
	- Greedier Mode
	- Delirium
	- Mother
	- The Beast
- Tainted Saint:
	- Boss Rush + Hush (Soul of the Saint)
	- Satan + Isaac + The Lamb + ??? (Trinket)
	- Greedier Mode (Card)
	- Delirium (Item akin to character mechanic)
	- Mother (Trinket)
	- The Beast (Item)
	- Mega Satan (Pickup or Object)

- [ ] actual Book of Virtues wisps for the following active items:
- Devout Prayer (2 variations)
- Wooden Key

## Almanach.lua

- [x] allow adding entries to the blacklist as an API call

## Devout_Prayer.lua

- [x] function `effectSpawnItem`: change the 2nd spawned item
	- if a devil deal has been taken during the run:
		- spawn an empty item pedestal (50% chance)
		- spawn an item from the devil pool (50% chance)

# Assets

add character sprites for:
- [ ] The Saint:
	- [ ] vs. screen / stage transition
	- [ ] player select screen
	- [ ] co-op menu icon
	- [ ] EID character icon
- [ ] Tainted Saint:
	- [ ] vs. screen / stage transition
	- [ ] player select screen
	- [ ] co-op menu icon
	- [ ] EID character icon

add item sprites for:
- [ ] Devout Prayer
- [ ] Wooden Key

add collection page sprites for:
- [ ] Almanach
- [ ] Devout Prayer
- [ ] Mending Heart
- [ ] Divine Bombs
- [ ] Wooden Key

add front/back sprites + anims for:
- [ ] Library Card
- [ ] Soul of the Saint
