local phase = 0
local hasDodgeAttacked = false

function onCharacterDefeat(character)
    if character == 'dad' then
        phase = phase + 1
        switchCombatJson('dad', 'phase2')
    end
end

function onExecutingAttack(character, currentAttack)
    if character == 'dad' then
        --debugPrint(getProperty('dad.currentAttack.damage'))
        hasDodgeAttacked = false
    elseif character == 'boyfriend' then
        -- setCurrentAttackParam('boyfriend', currentAttack, 'posture_damage', 200)
        if phase > 0 and hasDodgeAttacked == false and math.random(4) < 2 then
            enemyDodge()
            hasDodgeAttacked = true
        end
    end
end

function onStartingAttack(character, currentAttack)
    if character == 'boyfriend' then
        --setCurrentAttackByName('boyfriend', 'chain_attack')
    end
end

function onDodge(character, currentAttack)
    if character == 'dad' then
        enemyAttack(getAttackByName('dad', 'dodgeSwing'))
    end
end

function onDeterminePlayerChain(input, nextAttack, currentChain)
    -- nextAttack = 'chain_attack'
end

function onCreatePost()
    luaDebugMode = true
    toggleEnemyOffense(false)
    setPostureMechanicMode('enemy', true)
end

function onBeatHit()
    --toggleActiveCombat(true, true, true, true)
end

function onCharacterPostureBreak(character)

end