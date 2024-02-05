# The For Friday Combat Foundation
"For Friday" is a combat system designed to set a foundation to support a full system of combat for the game Friday Night Funkin'
## Installation:
To put it shortly, this current engine uses the 0.6.3 Psych Engine, so installation instructions are identical to that version's requirements.
The main reason this is version 0.6.3 instead of a more recent 0.7 version is because the later versions are much more difficult to get to compile, and are generally less stable for source modding.
Even the main dev has admitted this, though I'm unsure if this has change as of recent.

Either way, it's just a lot less of a headache getting the libraries right for this version. If you can compile 0.6.3 Psych, you're good to go on this one.

## Credits:
* A Guy Named Guy - Artist, Programmer, and Composer
* Psych Engine Team + Everyone Else - I did NOT make the engine, all credits are maintained within the mod itself and *should be kept there at all times*
_____________________________________

# Features

## An In-Depth, Versatile Combat System
* The core draw of this system: A nuanced series of mechanics that supports a one-on-one duel with the opponent
* Various attack and defense actions that structures a strategy for both approaching the opponent as well as utilizing the player's current toolset
* It's much easier to see all this by playing or watching a video, it gets complicated really fast

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
