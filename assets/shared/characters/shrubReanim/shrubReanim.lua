local phase = 0
local hasDodgeAttacked = false

function onCharacterDefeat(character)
    if character == 'dad' then
        advancePhase(1)
    end
end

function onExecutingAttack(character, currentAttack)
    if character == 'dad' then
        --debugPrint(getProperty('dad.currentAttack.damage'))
        hasDodgeAttacked = false
    elseif character == 'boyfriend' then
        -- setCurrentAttackParam('boyfriend', currentAttack, 'posture_damage', 200)
        if phase > 0 and hasDodgeAttacked == false and getAttackParam(getCurrentAttack('dad'), 'name') ~= 'dodgeSwing' and math.random(6) == 1 then
            enemyDodge()
        end
    end
end

function onStartingAttack(character, currentAttack)
    if character == 'dad' then
        if phase > 1 and getProperty('dad.placeInChain') > 0 and math.random(15) == 1 then
            enemyFeint(1)
        end
    elseif character == 'boyfriend' then
        --setCurrentAttackByName('boyfriend', 'chain_attack')
    end
end

function onDodge(character, currentAttack)
    if character == 'dad' and hasDodgeAttacked == false then
        enemyAttack(getAttackByName('dad', 'dodgeSwing'))
        hasDodgeAttacked = true
    end
end

function onAttacked(character, currentAttack)
        if character == 'dad' then
            if getCurrentAction('dad') == 'feint' then
                enemyParry()
            end
        end
end

function onParry(character, currentAttack)
        if character == 'dad' then
                inflictHitstun('boyfriend', 0.6)
                playAnim('boyfriend', 'combatHit')
                enemyAttack(getAttackByName('dad', 'parryFollowup'))
        end
end

function onDeterminePlayerChain(input, nextAttack, currentChain)
    -- nextAttack = 'chain_attack'
end

function onCreatePost()
    luaDebugMode = true
    toggleEnemyOffense(true)
    setPostureMechanicMode('disabled', true)
    advancePhase(2)
end

function onBeatHit()
    --toggleActiveCombat(true, true, true, true)
end

function onCharacterPostureBreak(character)

end

function advancePhase(advanceValue)
    phase = phase + advanceValue
    switchCombatJson('dad', 'phase'..phase)
end