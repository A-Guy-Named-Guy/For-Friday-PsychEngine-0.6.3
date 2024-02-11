# The For Friday Combat Foundation
"For Friday" is a combat system designed to set a foundation to support a full system of combat for the game Friday Night Funkin'
## Installation:
NOTE:

If you're here to play the game itself, NOT source mod the thing,
go to this link to download the actual mod.

For Friday: https://gamebanana.com/mods/edit/494017

This is just the source code for that mod, which is open for anyone to use, but does not innately contain the compiled game.

To put it shortly, this current engine uses the 0.6.3 Psych Engine, so installation instructions are identical to that version's requirements.
The main reason this is version 0.6.3 instead of a more recent 0.7 version is because the later versions are much more difficult to get to compile, and are generally less stable for source modding.
Even the main dev has admitted this, though I'm unsure if this has change as of recent.

Either way, it's just a lot less of a headache getting the libraries right for this version. If you can compile 0.6.3 Psych, you're good to go on this one.

## Credits:
* A Guy Named Guy - Artist, Programmer, and Composer
* Psych Engine Team + Everyone Else - I did NOT make the engine, all credits are maintained within the mod itself and *should be kept there at all times*
_____________________________________

# Features

## Mod Support
* In addition to the default mod support, support for extra features are also included for modding
* However, source modding is still the no. 1 recommended method since Lua hasn't been thoroughly supported for combat features
* Most features like tutorials, character effects, character selection, etc. have been softcoded for general development convenience
* Basically you can mod using existing mechanics, it's just that trying to make something new may be a challenge without source modding
* This is subject to change! But most likely will come with an official release of some original content using this system far in the future

## Effects System
![](https://github.com/A-Guy-Named-Guy/For-Friday-PsychEngine-0.6.3/blob/master/docs/img/characterMenuEffects.png)
* You can now add extra sprites, which performs the same animation as the parent character
* (It's not very obvious but the face is a separate sprite in this example)
* The character editor has been adapted to support altering effects, including some extra features like altering the sprite's angle

## Soft-Coded Tutorials
![](https://github.com/A-Guy-Named-Guy/For-Friday-PsychEngine-0.6.3/blob/master/docs/img/tutorial.png)
* Tutorials use jsons that can have the text and images set as you wish
* The important thing is to keep in mind the "tutorialList.json" file is a core one that stores the info of what's displayed on this screen, among other things

## Character Stats
![](https://github.com/A-Guy-Named-Guy/For-Friday-PsychEngine-0.6.3/blob/master/docs/img/characterStats.PNG)
* Character attributes are soft-coded, allowing for new or existing characters to be tweaked
* On top of number-stats, a few attributes like having unblockables on note attacks or which special is used are also determined here
* Sounds, too, are established here, and can be modified to have variable volume and use multiple alterations of the same sound
* (For example, the "whiff" sound file has 1-4 alternate "whiff" files, like "whiff1.ogg" and "whiff2.ogg")
_____________________________________

# Development Tips
Although I developed this system for my own projects, a big focus is the usability of this system for others.

You have full permission to use this system to try to make something, and to help with that, I want to give some wisdom that may help shape your game in a good direction.
So, here's the outline of the following tips:

Main points: Code's meant to be readable but is expected to be navigable on its own, as is the general expectation in most of programming. This is the gamiest game,
so use your gamer brain to think careful about how you're doing everything from what numbers you put on health and damage to where you put attacks on charts to what kind of "Specials" and actions
you give the player.

## Codebase Notes
All changes made to engine files are marked by a "// Combat change" comment, as well as some extra context if the change or method of doing something might seem strange at first.
Comments are generally pretty light, as variables and functions were named to be self-explanatory.

Keeping stuff to separate files was prioritized. Engine changes are minimal outside of cases where the opportunities were too good to pass.
The amount of stuff in the Character class is a big example, as storing all the character-related info is just a lot more intuitive and requires fewer workarounds to make work.
A LOT of engine stuff is still changed though.

It's not really feasible to make a detailed guide of every change, so if you're not used to navigating codebases freehand without external help (Specifically in-depth guides, Flx documentation and such is different),
it's a downright necessary skill to develop to be able to program something new effectively.
It takes some growing pains, but you can get there. I came into this project knowing nothing, and this project makes a much wider use of features, so hopefully you can learn a thing or two more developing for this one.

# Combat Design Tips
The combat system by default gameplay-wise features a balance of using vanilla health with actions, two of which come packaged as attacks and a unique "Special".

Actions are designed to be synced up to rhythm notes, in the sense that throwing an attack before a note occurs and outside the grace-window after hitting a note
(In the code this is the "noteAttack" variable that lasts for about half a step) will wait until the next note hit to be thrown.

The combat system meshes best with the rhythm gameplay by trying to sync it up with the action in some way. Acting according to notes takes care of a lot of this, and the logic for maintaining this cleanly is extensive.

## Song Speed
Since the expectation is to be hitting separate buttons along with notes, enemy attacks are executed instantly and cannot really use a grace window post the attack ending (Not to mention sound effects in general),
as well as the need to actually think out your resources and situation, this system meshes best with slower songs. Defending against attacks is very preemptive, and gets incredibly tight if attacks are too clustered.
Similar problem for the player attacking and acting in general, especially when they need to act often.

Really, one of the biggest strengths of this system is that slow songs can be made far more interesting and engaging than vanilla. Ever played the songs in-game on Easy, with combat disabled? It really shows!

If you DO use faster songs though, that's when I recommend using attack notes on the player chart. It's much more interesting to have the player need to make the attack choices themselves whenever possible!
But there are definitely some cinematic cases or otherwise that it fits, so, just think carefully on what your reasoning is to add those notes to the player chart.

That all aside, you can also just tune the attack-density in the opponent's chart to be infrequent enough that blocking is feasible. Otherwise parrying and hitting player-notes, as well as using bashes, are at
the player's disposal to counter very dense attack sections.
Lowering the opponent's total health or upping player damage also helps to alleviate the need to be super aggressive in faster songs, as needing to attack alot gets straining when you have to keep up.

I suppose the big thing I'm getting at here is to just think hard and careful about your balancing. The speed of the song greatly influences how the attack chart should be structured,
and a character's kit should ideally be useful in both a slow and fast song.

# Character Design
Alternate character playstyles are probably the bread-and-butter of what you can do to spin a mod into something interesting.
Your character determines what the player can choose to do, and thus is the most interesting part since that's when the player's able to push buttons.
Friday Night Funkin' is already a game about pushing buttons at the right time.
It's letting the player figure out when that right time actually is is what elevate the game outside the bounds of its rhythm-game core.

## Number Tweaks
Even simple little tweaks to existing characters are enough to make something entirely new.

Take Boyfriend, who's pretty simple. Largely designed to not require a hard deviation from normal gameplay. Just attack to notes.

His "Special", being a recovery move that trades health for stamina, is a simple, optional, but effective little tool for supporting his stamina consumption.
It's very useful! But it's usually not needed to actually succeed. In fact, it being so optional makes it a neat little tech to learn both for making
general gameplay easier along with making the various awards achievable (Like the "stay under half health" or "deal three times the opponent's health in damage" achievements)

But hey, you could easily tweak the numbers on Boyfriend's character and you get something entirely new. Maybe beef up his stamina drain to attack ratio tenfold, where you need a downright full stamina bar to throw an attack, but you
only need to do it so many times. Maybe five times in a song? The exact number's up to gameplay testing, but it's much fewer times than normal.

This character now has a far different resource-management philosophy to Boyfriend. Where Boyfriend's attack-to-damage ratio encourages frequent, steady attacks, with some pauses to refill your bar, this new character now revolves
entirely around the extremes of this risk. The focus shifts from balancing between tilting the stamina too low to die, to focusing on filling that bar to the next breakpoint, perhaps with some risk-assessment for whether the moment you
choose to let it loose lets you build up some safety-health.

That, and getting hit becomes far more punishing. As Boyfriend you tilt a bit closer to death, sure, but the pressure's only on making too many mistakes.
With this extreme character? Getting hit could cost you an attack for a while, and if you're not careful enough with where you place that attack you could easily choke straight into a death.

I literally just thought this up real-time with writing this, so I don't know how fun this actually turns out to be. (Given how parries reuse the attack action this may be a little much for how accidentally throwing an attack is its own punishment)
The main point is that even tweaking some basic numbers is enough to make something feel pretty new.

## Mechanic Repurpose (And Designing Around a New Mechanic)
One mechanic with some potential is something that I didn't make a character directly for, which is this little vulnerability window after the opponent performs a note.

You could for sure make a character that uses this as their main offense instead. I will stress that some extra mechanical finesse is gonna be needed to make this work though, as there's a reason I did not make a character for this.

The problem is spam. You can keep pressing attack in a single direction while the opponent is singing to hit them a bunch of times. Whether or not you're blocked, unless your stamina is very weak and/or you don't deal a lot of damage,
this makes the fight way too easy, and too brainless even if the numbers are right. This is why stamina costs are so high and offense are independent mechanics that work by driving up the damage numbers situationally.

But, I have some ideas.

Ideas that MAY or may not work. Don't take this as gospel, this is spitballing some concepts, and the extent to which this needs changes to make work also qualifies this all as making a whole new mechanic.

* Rhythm
  
First off, biggest concern should be rhythm. Ideally in this game you want to act according to the beat, so however way this should work should encourage acting on time with the music.
The important thing, discussed later on, is that attacking whenever with no regard for anything else is a major design issue that needs to be worked around.
For now though, given opponent's guard direction is made to only matter when they sing, designing something around attacking when they hit a note is a good start.

Like I said, you can mitigate the spam issue by making the non-contextually correct attack do far less damage. So making a case where hitting when the opponent immediately just switched or is about to switch guards
drive the attack's damage up to a reasonable level is a good next step.

This could probably make for a decent character! Essentially you're doing the same thing that Boyfriend does for attacking to singing notes, but the other way around. You're almost trying to hit the enemy's note.
The tri-directional guard adds some wrinkles that makes this difficult to really perform in a faster song though. The opponent blocks if the note's in the same direction, thus the attack needs to be in a different one.
But unless you impose some kind of special case, the opponent's guard lingers from their last note hit, so what's really being aimed for is the note that 1. Is not coming up, and 2. Did not get played last.

So this isn't a good character. Not yet. Because basically, what was created is an offense that's super precise, and without any counter measures, easy to abuse.

* Exploitation
  
Accounting all this direction-context is really hard, and becomes near worthless in a song fast enough where just doing the same direction over and over and inevitably hitting at one point or another is a far easier strat.

Thus, you'll need to balance one way or another to mitigate the mono-direction issue. Players are gonna take the path of least resistance if available.

You could take a common anti-spam approach used in songs and add a mines-element, where if you flub hitting the opponent's guard something bad happens. Boyfriend's attack stamina cost gets cut when note-attacking, so
that idea too could be used to drive the stamina cost down when the attack lands. If it doesn't, the player's stamina gets sapped a lot more and the attacks can't be done as often. And given the timed nature of each
song, flubbing this consistently could make a combat victory impossible, and being accurate with the attacks ends up being rewarded.

That said, there's still the mono-direction problem yet. Sure, you can't just slam the attack key like an orangutang, but there's nothing that stops you from also just focusing on a single direction's opening.

Maybe this is actually fine? The player at least can pick a direction they like, and a chart could naturally encourage one direction just by how its layed out. But hey, maybe you wanna take a step further in
encouraging switching the directions up.

The posture system could be retooled a bit in this case. You could expand it for this case to build posture up for a more lethal final blow, or having it be filled makes damage stronger. Maybe attacks in
one direction get "stale" and fill less posture as the player keeps hacking at it. You could maybe make hitting the opponent's guard right on the switch fill up posture more, to add that extra context
for picking which direction that's a little further than "not the last one", which can encourage just kind of rotating the guard, not really thinking too hard about which direction to use.

Again though, remember the Orangutang. Adding that posture-on-block could bring the spamming issue back if you make it a legit tactic.
Maybe making the guard match still stamina intensive but sharp on the posture gain is an infrequent but effective addition to the offense rotation.
This way spamming is penalized, but choosing to do it intentionally when needed is the best path forward.

Sharpening the importance of when you choose to attack can also mitigate the fast-song issue. Attacking as often as Boyfriend with a context this specific just isn't feasible, nor all that fun.
But, if you only need to make a couple attacks here and there, the player can just choose a good moment where they have a chance rather than needing to spam due to sheer input/information difficulty.

Alright, that probably expands this idea enough.

You can see how actually using this mechanic proper gets complicated fast, yeah? Thus why I didn't make a character around it.
Maybe this all works! Maybe it falls apart! You only know when you try it!

Whether or not this works is not the point though. This is what I mean when I say to think carefully about your decisions! It's easy to accidentally make something where just pushing buttons a lot is
too rewarding, which gets boring. Hopefully, this little example serves as a good demonstration of how to evaluate what your mechanics end up encouraging.

## Conclusion
Kudos if you decided to read this far.

There's a lot of potential that lies in this combat system, and I personally am excited to try and expand on it. I hope you can come up with something cool with this too!

Thanks for reading, and good luck!
