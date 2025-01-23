-- Combat Lua Stuff

-- General Notes:

-- Remember that changing variables provided from the calls does not change the actual data
-- Functions described elsewhere (Mainly the wiki of this mod's github page) can alter the important things

-- These calls are usually placed before the expected important stuff happens, mainly to do with attacks
-- Thus changing a character's currentAttack should result in the impending attack being changed

-- Chain calls determine attack checks afterwards, thus changing attacks won't work
-- Changing info off the currentChain often will change the resulting attack, however

-- Shockingly enough, you can pull specific info from a variable like you can in hard code
-- To illustrate this:
-- A call like onStartingAttack has the currentAttack variable pulled, which contains a bunch of attack data
-- Typing currentAttack.name or currentAttack.damage gives the name string and damage integer, respectively
-- Try debugPrint on this


-- If an attack lacks a windup, only onExecutingAttack is used
function onStartingAttack(character, currentAttack)
	if character == 'boyfriend' then
		-- called when player initiates an attack windup
	elseif character == 'dad' then
		-- called when the enemy initiates an attack windup
	end

	-- currentAttack is the current attack data of the character performing the attack
end

function onExecutingAttack(character, currentAttack)
	if character == 'boyfriend' then
		-- called when player executes an attack
	elseif character == 'dad' then
		-- called when the enemy executes an attack
	end

	-- currentAttack is the current attack data of the character performing the attack
end

-- Called when the player initiates an attack windup
-- This functions identically to onStartingAttack with a character == 'boyfriend' check
--
-- This call serves a way to transfer the input used, as it is a local variable
function onStartingPlayerAttack(input, currentAttack)
	-- input is a string representing the two attack inputs
	-- input == 'attack'
	-- input == 'special'

	-- currentAttack is the current attack data of boyfriend
end

-- Called whenever a character defends from an attack
-- Specifically, it's only when attack lands successfully that this is not called
function onDefend(character, offenderAttack)
	if character == 'boyfriend' then
		-- called when player defends from an attack
	elseif character == 'dad' then
		-- called when the enemy defends from an attack
	end

	-- offenderAttack is the attack data of the character performing the attack
end

-- Called whenever an attack interacts with the character in any form
function onAttacked(character, offenderAttack)
	if character == 'boyfriend' then
		-- called when player is hit by an attack
	elseif character == 'dad' then
		-- called when the enemy is hit by an attack
	end

	-- offenderAttack is the attack data of the character performing the attack
end

-- Called only when an attack lands
function onHit(character, offenderAttack)
	if character == 'boyfriend' then
		-- called when player is hit
	elseif character == 'dad' then
		-- called when the enemy is hit
	end

	-- offenderAttack is the attack data of the character performing the attack
end

-- Called only when an attack is blocked
-- "Blocking" broadly refers to defending that is not a parry or dodge
function onBlock(character, offenderAttack)
	if character == 'boyfriend' then
		-- called when player blocks an attack
	elseif character == 'dad' then
		-- called when the enemy blocks an attack
	end

	-- offenderAttack is the attack data of the character performing the attack
end

-- Called only when an attack is parried
-- "Parrying" is a kind of block that comes with extra advantages
function onParry(character, offenderAttack)
	if character == 'boyfriend' then
		-- called when player parrys an attack
	elseif character == 'dad' then
		-- called when the enemy parrys an attack
	end

	-- offenderAttack is the attack data of the character performing the attack
end

-- Called only when an attack is dodged
-- "Dodging" is a kind of defense that works regardless of the opponent's attack direction
-- Thus dodging fits for special attacks, which are non-directional,
-- Or a non-directional defense attack/action that doesn't directly inflict some kind of hitstun or effect to either party
function onDodge(character, offenderAttack)
	if character == 'boyfriend' then
		-- called when player dodges an attack
	elseif character == 'dad' then
		-- called when the enemy dodges an attack
	end

	-- offenderAttack is the attack data of the character performing the attack
end

-- Called before determining the enemy's chain
-- Specially, this occurs immediately after the enemy's chain is already chosen but before setting up their first attack
--
-- This is the best time to change dad's currentChain
function onDetermineEnemyChain(currentChain)
	-- currentChain is the chain data of the chain that was determined

	-- placeInChain is an integer representing how far in the input chain the enemy is in
	-- Unlike the player, there is no input getting rolled over
	-- So dad's placeInChain is always 0 when this is called, as an attack hasn't ocurred yet
end

-- Called when the character's health reaches 0
--
-- Specifically, this is called each instance the character's combatHealth is reduced below 0 when originally above 0
-- So receiving damage when already at or under 0 does not make this call
function onCharacterDefeat(character)
	if character == 'boyfriend' then
		-- called when player receives damage that results in 0 or less health
	elseif character == 'dad' then
		-- called when the enemy receives damage that results in 0 or less health
	end
end

-- Called when the character's posture reaches their postureMax
--
-- Specifically, this is called each instance the character's posture is increased above their postureMax when originally below the max
-- So receiving posture damage while already at or above postureMax does not make this call
function onCharacterPostureBreak(character)
	if character == 'boyfriend' then
		-- called when player receives posture damage that results in greater posture than their postureMax
	elseif character == 'dad' then
		-- called when the enemy receives posture damage that results in greater posture than their postureMax
	end
end