local testing = 'dad'

function onExecutingAttack(character, currentAttack)
    if character == 'dad' then
        --debugPrint(getProperty('dad.currentAttack.damage'))
    elseif character == 'boyfriend' then
        -- setCurrentAttackParam('boyfriend', currentAttack, 'posture_damage', 200)
    end
end

function onStartingAttack(character, currentAttack)
    if character == 'boyfriend' then
        --setCurrentAttackByName('boyfriend', 'chain_attack')
    end
end

function onDeterminePlayerChain(input, nextAttack, currentChain)
    nextAttack = 'chain_attack'
end

function onCreatePost()
    luaDebugMode = true
    toggleEnemyOffense(true)
end

function onBeatHit()
    --toggleActiveCombat(true, true, true, true)
end

function onCharacterPostureBreak(character)

end