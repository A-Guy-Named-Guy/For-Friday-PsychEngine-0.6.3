-- Combat Lua Stuff

-- General Notes:
-- Since the functions these lua calls occur in get a lot more complicated than vanilla events,
-- Be mindful of what is and isn't done before and after a lua call occurs

-- Generally, the lua call is put before json information is used
-- In other words they're placed before things like boyfriend's currentAttack is used to determine whatever comes up next, like taking health away or applying hitstun
-- Otherwise the call is put after "constant" effects,
-- like matching the enemy's guard position to the player's attack position or changing a character's current action string

-- Overall I strongly recommend knowing how to look into the hard code to see what gets changed when to achieve the result you're looking for
-- And be careful that while some results require certain property changes, changing some things can easily break behavior
-- For example, changing the enemy's "currentAction" can break timer chains that rely on using it if used improperly

-- If an attack lacks a windup, only onExecutingAttack is used
function onStartingAttack(character)
	if character == 'boyfriend' then
		-- called when player initiates an attack windup
	elseif character == 'dad' then
		-- called when the enemy initiates an attack windup
	end
end

function onExecutingAttack(character)
	if character == 'boyfriend' then
		-- called when player executes an attack
	elseif character == 'dad' then
		-- called when the enemy executes an attack
	end
end

-- Called whenever a character defends from an attack
-- Specifically, it's only when attack lands successfully that this is not called
function onDefend(character)
	if character == 'boyfriend' then
		-- called when player defends from an attack
	elseif character == 'dad' then
		-- called when the enemy defends from an attack
	end
end

-- Called whenever an attack interacts with the character in any form
function onAttacked(character)
	if character == 'boyfriend' then
		-- called when player is hit by an attack
	elseif character == 'dad' then
		-- called when the enemy is hit by an attack
	end
end

-- Called only when an attack lands
function onHit(character)
	if character == 'boyfriend' then
		-- called when player is hit
	elseif character == 'dad' then
		-- called when the enemy is hit
	end
end

-- Called only when an attack is blocked
-- "Blocking" broadly refers to defending that is not a parry or dodge
function onBlock(character)
	if character == 'boyfriend' then
		-- called when player blocks an attack
	elseif character == 'dad' then
		-- called when the enemy blocks an attack
	end
end

-- Called only when an attack is parried
-- "Parrying" is a kind of block that comes with extra advantages
function onParry(character)
	if character == 'boyfriend' then
		-- called when player parrys an attack
	elseif character == 'dad' then
		-- called when the enemy parrys an attack
	end
end

-- Called only when an attack is dodged
-- "Dodging" is a kind of defense that works regardless of the opponent's attack direction
-- Thus dodging fits for special attacks, which are non-directional,
-- Or a non-directional defense attack/action that doesn't directly inflict some kind of hitstun or effect to either party
function onDodge(character)
	if character == 'boyfriend' then
		-- called when player dodges an attack
	elseif character == 'dad' then
		-- called when the enemy dodges an attack
	end
end