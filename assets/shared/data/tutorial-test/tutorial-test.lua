local phase = 'directions'

local tweenOutDirection = 'left'
local tweenInDirection = 'right'
local textBoxArrived = true

local guardMap =
{
    LEFT = 0,
    DOWN = 0,
    UP = 0,
    RIGHT = 0
}

local leftChainDefended = false
local upChainDefended = false
local rightChainDefended = false

local offenseHits = 0

local hasParried = false

    -- switch statement doesn't exist in lua
    -- I'm assuming something to do with lua being a first-pass compile language or something
    -- Anyway we gotta cook up some sauce to achieve the effect
local tutorialTextCase =
{
    directions = function()
        setTextString('tutorialText', 'Guard Directions:\n\nThe tri-arrow widget to the right of the screen represents your guard.\n\nUse the same keys you would use to hit notes to change your guard.\n\nTo proceed, guard in each direction three times:\n\n'..directionsGuardText())
    end,

    defense = function()
        setTextString('tutorialText', 'Defense:\n\nMatch your guard to the enemy\'s attack direction to defend.\n\nBoyfriend has the "Reflex Guard" guard type, only lasting a short duration or on blocking an attack.\n\nYour opponent, the Shrub, has a permanent guard that remains indefinitely.\n\nThe Shrub will start attacking once you match their guard. Block their three chains to proceed.'..enemyChainText())
    end,

    offense = function()
        setTextString('tutorialText', 'Offense:\n\nYour opponent\'s guard is strong. They will block any attack whether or not they are attacking.\nYou will need to force their guard open.\n\nAiming an attack at where the opponent\'s guard currently is will throw their guard in one of the three directions.\nWhen this happens, they cannot block for a short time.\n\n\n\nLand three attacks to proceed:\n\nAim for their current guard position,\nWatch where their guard moves,\nThen attack where they\'re open\n\n'..offenseHitsText())
    end,

    parrying = function()
        setTextString('tutorialText', 'Parrying:\n\nParrying is an enhanced block that restores much more health and stamina, and can defend against orange-indicated unblockable attacks.\n\nTo parry, match the direction of the enemy\'s attack and press the attack input at least half a second before it is thrown.\n\nAttempting to parry down direction/special attacks or attacks that are feinted will result in throwing an attack instead.\n\nTo proceed, parry at least one attack in each attack chain and do not get hit\n\n'..parryText())
    end,

    prefight = function()
        setTextString('tutorialText', 'This concludes the tutorial.\n\nUse the [ or ] bracket keys to navigate back and forth through the tutorials thus far.\n\nPress the SPACE button to finish the tutorial and start the fight.')
    end,

    default = function()
        setTextString('tutorialText', 'no valid tutorial off this name!')
    end,
}
local tutorialList =
{
    'directions',
    'defense',
    'offense',
    'parrying',
    'prefight'
}
-- This is for debugging purposes, so some behavior is a little weird
local tutorialCase =
{
    directions = function()
        toggleEnemyOffense(false)
        togglePlayerCanAttack(false)
        guardMap['LEFT'] = 0
        guardMap['DOWN'] = 0
        guardMap['UP'] = 0
        guardMap['RIGHT'] = 0
    end,

    defense = function()
        toggleEnemyOffense(false)
        togglePlayerCanAttack(false)
        setEnemyChainByName('Lchain')
        leftChainDefended = false
        upChainDefended = false
        rightChainDefended = false
        setCombatHealth('boyfriend', getCombatHealthMax('boyfriend'))
        setCombatHealth('dad', getCombatHealthMax('dad'))
        setHealth(2)
    end,

    offense = function()
        toggleEnemyOffense(false)
        togglePlayerCanAttack(true)
        setCombatHealth('boyfriend', getCombatHealthMax('boyfriend'))
        setCombatHealth('dad', getCombatHealthMax('dad'))
        setHealth(2)
        offenseHits = 0
    end,

    parrying = function()
        toggleEnemyOffense(false)
        setEnemyChainByName('Lchain')
        togglePlayerCanAttack(true)
        leftChainDefended = false
        upChainDefended = false
        rightChainDefended = false
        setCombatHealth('boyfriend', getCombatHealthMax('boyfriend'))
        setCombatHealth('dad', getCombatHealthMax('dad'))
        setHealth(2)
        hasParried = false
    end,

    fight = function()
        toggleEnemyOffense(true)
        togglePlayerCanAttack(true)
        setCombatHealth('boyfriend', getCombatHealthMax('boyfriend'))
        setCombatHealth('dad', getCombatHealthMax('dad'))
        setHealth(2)
    end,

    default = function()
        toggleEnemyOffense(false)
        togglePlayerCanAttack(true)
        setCombatHealth('boyfriend', getCombatHealthMax('boyfriend'))
        setCombatHealth('dad', getCombatHealthMax('dad'))
        setHealth(2)
    end
}
local textBackPositionCase =
{
    directions = function()
        setProperty('textBack.x', 5)
        screenCenter('textBack', 'y')
        tweenOutDirection = 'left'
        tweenInDirection = 'right'
    end,

    default = function()
        setProperty('textBack.x', getPropertyFromClass('flixel.FlxG', 'width') - getProperty('textBack.width') - 5)
        screenCenter('textBack', 'y')
        tweenOutDirection = 'right'
        tweenInDirection = 'left'
    end
}
local tweenDirectionCase =
{
    up = function()
        doTweenX('tutorialTextTwn', 'tutorialText', getProperty('tutorialText.y') - 15, 0.5, 'quadOut')
        doTweenX('tutorialTextBoxTwn', 'textBack', getProperty('textBack.y') - 15, 0.5, 'quadOut')
    end,

    down = function()
        doTweenX('tutorialTextTwn', 'tutorialText', getProperty('tutorialText.y') + 15, 0.5, 'quadOut')
        doTweenX('tutorialTextBoxTwn', 'textBack', getProperty('textBack.y') + 15, 0.5, 'quadOut')
    end,

    left = function()
        doTweenX('tutorialTextTwn', 'tutorialText', getProperty('tutorialText.x') - 15, 0.5, 'quadOut')
        doTweenX('tutorialTextBoxTwn', 'textBack', getProperty('textBack.x') - 15, 0.5, 'quadOut')
    end,

    default = function()
        doTweenX('tutorialTextTwn', 'tutorialText', getProperty('tutorialText.x') + 15, 0.5, 'quadOut')
        doTweenX('tutorialTextBoxTwn', 'textBack', getProperty('textBack.x') + 15, 0.5, 'quadOut')
    end,
}

function onCreatePost()
    luaDebugMode = true
    debugPrint(getKeyboardInputKeys('guard_left'))

    setPostureMechanicMode('disabled', true)
    togglePlayerCanAttack(false)

    makeLuaSprite('textBack')
    makeGraphic('textBack', 350, 650, 'black')
    addLuaSprite('textBack', true)
    setObjectCamera('textBack', 'hud')
    setProperty('textBack.alpha', 0.3)

    makeLuaText('tutorialText', 'placeholder', 340)
    addLuaText('tutorialText')
    setObjectCamera('tutorialText', 'hud')
    --setTextAlignment('tutorialText', 'left')

    startChangeTutorial('directions')
end

function onUpdate(elapsed)
    if phase == 'fight' then
        return
    end

    for i, v in pairs (tutorialList) do
        if (v == phase) then
            if getCombatHealth('boyfriend') < 20 then
                setCombatHealth('boyfriend', 20)
            end
            if getCombatHealth('dad') < 20 then
                setCombatHealth('dad', 20)
            end
            if getHealth() < 1 then
                setHealth(1)
            end
            break
        end
    end

    if keyboardJustPressed('LBRACKET') and luaDebugMode then
        for i, v in ipairs(tutorialList) do
            if (v == phase) then
                if i - 1 < 1 then
                    startChangeTutorial(tutorialList[#tutorialList])
                else
                    startChangeTutorial(tutorialList[i - 1])
                end
                break
            end
        end
    elseif keyboardJustPressed('RBRACKET') and luaDebugMode then
        for i, v in ipairs(tutorialList) do
            if (v == phase) then
                if i + 1 > #tutorialList then
                    startChangeTutorial(tutorialList[1])
                else
                    startChangeTutorial(tutorialList[i + 1])
                end
                break
            end
        end
    end

    if keyboardJustPressed('SPACE') then
        startChangeTutorial('fight')
    end
end

function onGuardUpdate(character, direction)
    if phase == 'fight' then
        return
    end

    if character == 'boyfriend' then
        if phase == 'directions' then
            if guardMap[direction] then
                
                guardMap[direction] = guardMap[direction] + 1
                if guardMap[direction] > 3 then
                    guardMap[direction] = 3
                end

                updateTutorialText()
            end

            local shouldChangePhase = true

            -- This is a lazy solution but any better one takes way too much effort
            if guardMap['LEFT'] < 3 then
                shouldChangePhase = false
            elseif guardMap['DOWN'] < 3 then
                shouldChangePhase = false
            elseif guardMap['UP'] < 3 then
                shouldChangePhase = false
            elseif guardMap['RIGHT'] < 3 then
                shouldChangePhase = false
            end

            if shouldChangePhase then
                startChangeTutorial('defense')
            end
        elseif phase == 'defense' or phase == 'parrying' then
            if direction == 'LEFT' and textBoxArrived and getProperty('tutorialText.alpha') == 1 then
                toggleEnemyOffense(true)
                updateTutorialText()
            end
        end
    end
end

function onDetermineEnemyChain(currentChain, placeInChain)
    if phase == 'fight' then
        return
    end
    
    if phase == 'defense' or phase == 'parrying' then
            if upChainDefended == true then
                setEnemyChainByName('Rchain')
            elseif leftChainDefended == true then
                setEnemyChainByName('Uchain')
            else
                setEnemyChainByName('Lchain')
            end

            hasParried = false
            updateTutorialText()
    end
end

function onStartingAttack (character, attack)
    if phase == 'fight' then
        return
    end
    
    if character == 'dad' then
        if getAttackParam(attack, 'name') == 'Uchain2U' then
            setCurrentAttackParam('dad', 'is_unblockable', true)
        elseif getAttackParam(attack, 'name') == 'Rchain3L' then
            enemyFeint(1)
        end
    end
end

function onHit(character, offenderAttack)
    if phase == 'fight' then
        return
    end
    
    if character == 'boyfriend' then
        if phase == 'defense' or phase == 'parrying' and getAttackParam(offenderAttack, 'name') ~= 'parryFollowup' then
            setEnemyChain(getCurrentChain('dad'))
            setCurrentAttackParam('dad', 'recovery', 0.75)
            if phase == 'parrying' then
                hasParried = false
                updateTutorialText()
            end
        end
    end
    if character == 'dad' then
        if phase == 'offense' then
            offenseHits = offenseHits + 1
            if offenseHits > 3 then
                offenseHits = 3
            end
            if offenseHits == 3 then
                startChangeTutorial('parrying')
            end
        end
    end
end

function onDefend(character, offenderAttack)
    if phase == 'fight' then
        return
    end
    
    if character == 'boyfriend' then
        if phase == 'defense' or phase == 'parrying' and getProperty('boyfriend.currentAction') == 'hasParried' then
            if getProperty('dad.currentChain.attack_chain.length') == getPlaceInChain('dad') + 1 then
                if upChainDefended == true then
                    rightChainDefended = true
                    toggleEnemyOffense(false)
                    togglePlayerCanAttack(true)
                    setCombatHealth('boyfriend', getCombatHealthMax('boyfriend'))
                    setHealth(2)
                    if phase == 'defense' then
                        startChangeTutorial('offense')
                    elseif phase == 'parrying' then
                        startChangeTutorial('prefight')
                    end
                elseif leftChainDefended == true then
                    upChainDefended = true
                else
                    leftChainDefended = true
                end

                hasParried = false

                updateTutorialText()
            end
        end
    end
end

function onParry(character, offenderAttack)
    if phase == 'fight' then
        return
    end
    
    if character == 'boyfriend' then
        hasParried = true
        updateTutorialText()
    end
    if character == 'dad' then
        inflictHitstun('boyfriend', 0.6)
        playAnim('boyfriend', 'combatHit')
        enemyAttack(getAttackByName('dad', 'parryFollowup'))
    end
end

function directionsGuardText()
    return 'LEFT '..getKeyboardInputKeys('guard_left')..': '..guardMap['LEFT']..'/3\nUP '..getKeyboardInputKeys('guard_up')..': '..guardMap['UP']..'/3\nRIGHT '..getKeyboardInputKeys('guard_right')..': '..guardMap['RIGHT']..'/3\nDODGE'..getKeyboardInputKeys('guard_down')..': '..guardMap['DOWN']..'/3'
end

function enemyChainText()
    return '\n\nGuarded LEFT\n(Starts enemy attacking): '..displayFlagAsText(getProperty('COMBAT.enemyOnOffense'))..'\n\nDefended LEFT Chain: '..displayFlagAsText(leftChainDefended)..'\nDefended UP Chain: '..displayFlagAsText(upChainDefended)..'\nDefended RIGHT Chain: '..displayFlagAsText(rightChainDefended)..''
end

function offenseHitsText()
    return 'Attacks landed: '..offenseHits..'/3\n\nAttack key(s): '..getKeyboardInputKeys('attack')..'\n\n\n\nNote: You have a three hit attack chain. The third attack deals greater damage, but consumes more stamina and has a long recovery.\n\nWait a moment after throwing the second attack if you wish to avoid the lengthy recovery of the third.'
end

function parryText()
    return 'Guarded LEFT\n(Starts enemy attacking): '..displayFlagAsText(getProperty('COMBAT.enemyOnOffense'))..'\n\nDefended LEFT Chain: '..displayFlagAsText(leftChainDefended)..'\nDefended UP Chain: '..displayFlagAsText(upChainDefended)..'\nDefended RIGHT Chain: '..displayFlagAsText(rightChainDefended)..'\n\nParried an attack: '..displayFlagAsText(hasParried)..'\n\n\n\nNote: If the enemy "feints", or does not throw their attack, they may be baiting a parry to counterattack.\n\nAfter they counter, look carefully at their guard. They may leave themselves open for a counter hit of your own.'
end

function displayFlagAsText(value)
    if (value) then
        return '[X]'
    else
        return '[_]'
    end
end

function tweenTutorialStuff(inOrOut)
    local direction = 'left'

    if inOrOut == 'in' then
        setProperty('tutorialText.alpha', 0)
        setProperty('textBack.alpha', 0)
        doTweenAlpha('tutorialTextAlphaTwn', 'tutorialText', 1, 0.2, 'quadIn')
        doTweenAlpha('tutorialTextBoxAlphaTwn', 'textBack', 0.3, 0.2, 'quadIn')
        direction = tweenInDirection
    else
        setProperty('tutorialText.alpha', 1)
        setProperty('textBack.alpha', 0.3)
        doTweenAlpha('tutorialTextAlphaTwn', 'tutorialText', 0, 0.2, 'quadIn')
        doTweenAlpha('tutorialTextBoxAlphaTwn', 'textBack', 0, 0.2, 'quadIn')
        direction = tweenOutDirection
    end

    if tweenDirectionCase[direction] then
        tweenDirectionCase[direction]() 
    else
        tweenDirectionCase['default']()
    end
end

function onTweenCompleted(tag, vars)
    if tag == 'tutorialTextTwn' and textBoxArrived == false and phase ~= 'fight' then
        finishChangeTutorial()
        textBoxArrived = true
    end
end

function startChangeTutorial(name)
    phase = name
    textBoxArrived = false
    tweenTutorialStuff('out')
    if tutorialCase[name] then
        tutorialCase[name]()
    else
        tutorialCase['default']()
    end
end

function finishChangeTutorial()
    if textBackPositionCase[phase] then
        textBackPositionCase[phase]() 
    else
        textBackPositionCase['default']()
    end

    updateTutorialText()
    tweenTutorialStuff('in')
end

function updateTutorialText()
    if tutorialTextCase[phase] then
        tutorialTextCase[phase]() 
    else
        tutorialTextCase['default']()
    end

    setProperty('tutorialText.x', getProperty('textBack.x') + 5)
    setProperty('tutorialText.y', getProperty('textBack.y') + 5)
end
