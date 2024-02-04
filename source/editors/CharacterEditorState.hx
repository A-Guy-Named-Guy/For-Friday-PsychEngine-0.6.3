package editors;

#if desktop
import Discord.DiscordClient;
#end
import Character;
import animateatlas.AtlasFrameMaker;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.ui.FlxInputText;
import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.addons.ui.FlxUITabMenu;
import flixel.addons.ui.FlxUITooltip.FlxUITooltipStyle;
import flixel.animation.FlxAnimation;
import flixel.graphics.FlxGraphic;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.input.keyboard.FlxKey;
import flixel.system.debug.interaction.tools.Pointer.GraphicCursorCross;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.ui.FlxSpriteButton;
import flixel.util.FlxColor;
import forfriday.CharacterExtra;
import haxe.Json;
import lime.system.Clipboard;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.net.FileReference;

using StringTools;

// Combat changes
// imports
// FlxSpriteGroup
// End of changes
#if MODS_ALLOWED
import sys.FileSystem;
#end

/**
	*DEBUG MODE
 */
class CharacterEditorState extends MusicBeatState
{
	var char:Character;
	var ghostChar:Character;
	var textAnim:FlxText;
	var bgLayer:FlxTypedGroup<FlxSprite>;
	// Combat change
	// Effects are added to these layer groups, so they work a lot better as sprite groups instead
	// var charLayer:FlxTypedGroup<Character>;
	var charLayer:FlxSpriteGroup;
	// End of changes
	var dumbTexts:FlxTypedGroup<FlxText>;
	// var animList:Array<String> = [];
	var curAnim:Int = 0;
	var daAnim:String = 'spooky';
	var goToPlayState:Bool = true;
	var camFollow:FlxObject;

	// Combat changes
	var effect:CharacterExtra;
	var daEffect:String = '';
	var daEffectCallback:String = '';

	var ghostEffect:CharacterExtra;
	var ghostLayer:FlxSpriteGroup;

	var UI_effectbox:FlxUITabMenu;
	var textPages:FlxTypedGroup<FlxTypedGroup<FlxText>>;
	var curPage:Int = 0;
	var effectPages:Array<Int> = [];
	var selectedEffectAnimID:Int = 0;

	// End of changes

	public function new(daAnim:String = 'spooky', goToPlayState:Bool = true)
	{
		super();
		this.daAnim = daAnim;
		this.goToPlayState = goToPlayState;
	}

	var UI_box:FlxUITabMenu;
	var UI_characterbox:FlxUITabMenu;

	private var camEditor:FlxCamera;
	private var camHUD:FlxCamera;
	private var camMenu:FlxCamera;

	var changeBGbutton:FlxButton;
	var leHealthIcon:HealthIcon;
	var characterList:Array<String> = [];

	var cameraFollowPointer:FlxSprite;
	var healthBarBG:FlxSprite;

	override function create()
	{
		// FlxG.sound.playMusic(Paths.music('breakfast'), 0.5);

		camEditor = new FlxCamera();
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		camMenu = new FlxCamera();
		camMenu.bgColor.alpha = 0;

		FlxG.cameras.reset(camEditor);
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camMenu, false);
		FlxG.cameras.setDefaultDrawTarget(camEditor, true);

		bgLayer = new FlxTypedGroup<FlxSprite>();
		add(bgLayer);
		// Combat change
		ghostLayer = new FlxSpriteGroup();
		add(ghostLayer);
		// End of changes
		charLayer = new FlxSpriteGroup();
		add(charLayer);

		var pointer:FlxGraphic = FlxGraphic.fromClass(GraphicCursorCross);
		cameraFollowPointer = new FlxSprite().loadGraphic(pointer);
		cameraFollowPointer.setGraphicSize(40, 40);
		cameraFollowPointer.updateHitbox();
		cameraFollowPointer.color = FlxColor.WHITE;
		add(cameraFollowPointer);

		changeBGbutton = new FlxButton(FlxG.width - 360, 25, "", function()
		{
			onPixelBG = !onPixelBG;
			reloadBGs();
		});
		changeBGbutton.cameras = [camMenu];

		loadChar(!daAnim.startsWith('bf'), false);

		// Combat change
		loadEffect();

		healthBarBG = new FlxSprite(30, FlxG.height - 75).loadGraphic(Paths.image('healthBar'));
		healthBarBG.scrollFactor.set();
		add(healthBarBG);
		healthBarBG.cameras = [camHUD];

		leHealthIcon = new HealthIcon(char.healthIcon, false);
		leHealthIcon.y = FlxG.height - 150;
		add(leHealthIcon);
		leHealthIcon.cameras = [camHUD];

		dumbTexts = new FlxTypedGroup<FlxText>();
		// Combat change
		// This text displays when it shouldn't with the new page system
		// add(dumbTexts);
		dumbTexts.cameras = [camHUD];
		// Combat change
		textPages = new FlxTypedGroup<FlxTypedGroup<FlxText>>();
		add(textPages);

		textAnim = new FlxText(300, 16);
		textAnim.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		textAnim.borderSize = 1;
		textAnim.size = 32;
		textAnim.scrollFactor.set();
		textAnim.cameras = [camHUD];
		add(textAnim);

		genBoyOffsets();

		camFollow = new FlxObject(0, 0, 2, 2);
		camFollow.screenCenter();
		add(camFollow);

		// Combat change
		// Add the \nA/D - Previous/Next Animation List
		var tipTextArray:Array<String> = "E/Q - Camera Zoom In/Out
		\nR - Reset Camera Zoom
		\nJKLI - Move Camera
		\nW/S - Previous/Next Animation
		\nA/D - Previous/Next Animation List
		\nSpace - Play Animation
		\nArrow Keys - Move Character Offset
		\nT - Reset Current Offset
		\nHold Shift to Move 10x faster\n".split('\n');

		for (i in 0...tipTextArray.length - 1)
		{
			var tipText:FlxText = new FlxText(FlxG.width - 320, FlxG.height - 15 - 16 * (tipTextArray.length - i), 300, tipTextArray[i], 12);
			tipText.cameras = [camHUD];
			tipText.setFormat(null, 12, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE_FAST, FlxColor.BLACK);
			tipText.scrollFactor.set();
			tipText.borderSize = 1;
			add(tipText);
		}

		FlxG.camera.follow(camFollow);

		var tabs = [
			// {name: 'Offsets', label: 'Offsets'},
			{name: 'Settings', label: 'Settings'},
			// Combat Change
			// For some dumbass reason the tabs are forced to be sorted in alphabetical order according to the name
			{name: 'T Effect Settings', label: 'Effect Settings'},
		];

		UI_box = new FlxUITabMenu(null, tabs, true);
		UI_box.cameras = [camMenu];

		UI_box.resize(250, 120);
		UI_box.x = FlxG.width - 275;
		UI_box.y = 25;
		UI_box.scrollFactor.set();

		var tabs = [
			{name: 'Character', label: 'Character'},
			{name: 'Animations', label: 'Animations'},
			// Combat changes
			{name: 'Effect', label: 'Effect'},
			// For some dumbass reason the tabs are forced to be sorted in alphabetical order according to the name
			{name: 'D Anim Effect', label: 'Effect Anim'},
		];
		UI_characterbox = new FlxUITabMenu(null, tabs, true);
		UI_characterbox.cameras = [camMenu];

		UI_characterbox.resize(350, 250);
		UI_characterbox.x = UI_box.x - 100;
		UI_characterbox.y = UI_box.y + UI_box.height;
		UI_characterbox.scrollFactor.set();
		add(UI_characterbox);
		add(UI_box);
		add(changeBGbutton);

		// addOffsetsUI();
		addSettingsUI();
		// Combat change
		addEffectSettingsUI();

		addCharacterUI();
		addAnimationsUI();
		// Combat change
		addEffectAnimUI();
		addEffectUI();
		// End of changes
		UI_characterbox.selected_tab_id = 'Character';

		FlxG.mouse.visible = true;
		reloadCharacterOptions();
		// Combat change
		reloadEffectOptions();

		super.create();
	}

	var onPixelBG:Bool = false;
	var OFFSET_X:Float = 300;

	function reloadBGs()
	{
		var i:Int = bgLayer.members.length - 1;
		while (i >= 0)
		{
			var memb:FlxSprite = bgLayer.members[i];
			if (memb != null)
			{
				memb.kill();
				bgLayer.remove(memb);
				memb.destroy();
			}
			--i;
		}
		bgLayer.clear();
		var playerXDifference = 0;
		if (char.isPlayer)
			playerXDifference = 670;

		if (onPixelBG)
		{
			var playerYDifference:Float = 0;
			if (char.isPlayer)
			{
				playerXDifference += 200;
				playerYDifference = 220;
			}

			var bgSky:BGSprite = new BGSprite('weeb/weebSky', OFFSET_X - (playerXDifference / 2) - 300, 0 - playerYDifference, 0.1, 0.1);
			bgLayer.add(bgSky);
			bgSky.antialiasing = false;

			var repositionShit = -200 + OFFSET_X - playerXDifference;

			var bgSchool:BGSprite = new BGSprite('weeb/weebSchool', repositionShit, -playerYDifference + 6, 0.6, 0.90);
			bgLayer.add(bgSchool);
			bgSchool.antialiasing = false;

			var bgStreet:BGSprite = new BGSprite('weeb/weebStreet', repositionShit, -playerYDifference, 0.95, 0.95);
			bgLayer.add(bgStreet);
			bgStreet.antialiasing = false;

			var widShit = Std.int(bgSky.width * 6);
			var bgTrees:FlxSprite = new FlxSprite(repositionShit - 380, -800 - playerYDifference);
			bgTrees.frames = Paths.getPackerAtlas('weeb/weebTrees');
			bgTrees.animation.add('treeLoop', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18], 12);
			bgTrees.animation.play('treeLoop');
			bgTrees.scrollFactor.set(0.85, 0.85);
			bgLayer.add(bgTrees);
			bgTrees.antialiasing = false;

			bgSky.setGraphicSize(widShit);
			bgSchool.setGraphicSize(widShit);
			bgStreet.setGraphicSize(widShit);
			bgTrees.setGraphicSize(Std.int(widShit * 1.4));

			bgSky.updateHitbox();
			bgSchool.updateHitbox();
			bgStreet.updateHitbox();
			bgTrees.updateHitbox();
			changeBGbutton.text = "Regular BG";
		}
		else
		{
			var bg:BGSprite = new BGSprite('stageback', -600 + OFFSET_X - playerXDifference, -300, 0.9, 0.9);
			bgLayer.add(bg);

			var stageFront:BGSprite = new BGSprite('stagefront', -650 + OFFSET_X - playerXDifference, 500, 0.9, 0.9);
			stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
			stageFront.updateHitbox();
			bgLayer.add(stageFront);
			changeBGbutton.text = "Pixel BG";
		}
	}

	/*var animationInputText:FlxUIInputText;
		function addOffsetsUI() {
			var tab_group = new FlxUI(null, UI_box);
			tab_group.name = "Offsets";

			animationInputText = new FlxUIInputText(15, 30, 100, 'idle', 8);

			var addButton:FlxButton = new FlxButton(animationInputText.x + animationInputText.width + 23, animationInputText.y - 2, "Add", function()
			{
				var theText:String = animationInputText.text;
				if(theText != '') {
					var alreadyExists:Bool = false;
					for (i in 0...animList.length) {
						if(animList[i] == theText) {
							alreadyExists = true;
							break;
						}
					}

					if(!alreadyExists) {
						char.animOffsets.set(theText, [0, 0]);
						animList.push(theText);
					}
				}
			});

			var removeButton:FlxButton = new FlxButton(animationInputText.x + animationInputText.width + 23, animationInputText.y + 20, "Remove", function()
			{
				var theText:String = animationInputText.text;
				if(theText != '') {
					for (i in 0...animList.length) {
						if(animList[i] == theText) {
							if(char.animOffsets.exists(theText)) {
								char.animOffsets.remove(theText);
							}

							animList.remove(theText);
							if(char.animation.curAnim.name == theText && animList.length > 0) {
								char.playAnim(animList[0], true);
							}
							break;
						}
					}
				}
			});

			var saveButton:FlxButton = new FlxButton(animationInputText.x, animationInputText.y + 35, "Save Offsets", function()
			{
				saveOffsets();
			});

			tab_group.add(new FlxText(10, animationInputText.y - 18, 0, 'Add/Remove Animation:'));
			tab_group.add(addButton);
			tab_group.add(removeButton);
			tab_group.add(saveButton);
			tab_group.add(animationInputText);
			UI_box.addGroup(tab_group);
	}*/
	var TemplateCharacter:String = '{
			"animations": [
				{
					"loop": false,
					"offsets": [
						0,
						0
					],
					"fps": 24,
					"anim": "idle",
					"indices": [],
					"name": "Dad idle dance"
				},
				{
					"offsets": [
						0,
						0
					],
					"indices": [],
					"fps": 24,
					"anim": "singLEFT",
					"loop": false,
					"name": "Dad Sing Note LEFT"
				},
				{
					"offsets": [
						0,
						0
					],
					"indices": [],
					"fps": 24,
					"anim": "singDOWN",
					"loop": false,
					"name": "Dad Sing Note DOWN"
				},
				{
					"offsets": [
						0,
						0
					],
					"indices": [],
					"fps": 24,
					"anim": "singUP",
					"loop": false,
					"name": "Dad Sing Note UP"
				},
				{
					"offsets": [
						0,
						0
					],
					"indices": [],
					"fps": 24,
					"anim": "singRIGHT",
					"loop": false,
					"name": "Dad Sing Note RIGHT"
				}
			],
			"no_antialiasing": false,
			"image": "characters/DADDY_DEAREST",
			"position": [
				0,
				0
			],
			"healthicon": "face",
			"flip_x": false,
			"healthbar_colors": [
				161,
				161,
				161
			],
			"camera_position": [
				0,
				0
			],
			"sing_duration": 6.1,
			"scale": 1
		}';

	var charDropDown:FlxUIDropDownMenuCustom;

	function addSettingsUI()
	{
		var tab_group = new FlxUI(null, UI_box);
		tab_group.name = "Settings";

		var check_player = new FlxUICheckBox(10, 60, null, null, "Playable Character", 100);
		check_player.checked = daAnim.startsWith('bf');
		check_player.callback = function()
		{
			char.isPlayer = !char.isPlayer;
			char.flipX = !char.flipX;
			updatePointerPos();
			reloadBGs();
			ghostChar.flipX = char.flipX;
		};

		charDropDown = new FlxUIDropDownMenuCustom(10, 30, FlxUIDropDownMenuCustom.makeStrIdLabelArray([''], true), function(character:String)
		{
			daAnim = characterList[Std.parseInt(character)];
			check_player.checked = daAnim.startsWith('bf');

			// Combat changes
			daEffect = '';
			effectAnimationInputText.text = '';
			effectAnimationNameInputText.text = '';
			// These otherwise didn't clear on switching characters, so, engine-fix here too
			animationInputText.text = '';
			animationNameInputText.text = '';
			// End of changes

			loadChar(!check_player.checked);
			updatePresence();
			reloadCharacterDropDown();
		});
		charDropDown.selectedLabel = daAnim;
		reloadCharacterDropDown();

		var reloadCharacter:FlxButton = new FlxButton(140, 20, "Reload Char", function()
		{
			loadChar(!check_player.checked);
			reloadCharacterDropDown();
		});

		var templateCharacter:FlxButton = new FlxButton(140, 50, "Load Template", function()
		{
			var parsedJson:CharacterFile = cast Json.parse(TemplateCharacter);
			var characters:Array<Character> = [char, ghostChar];
			for (character in characters)
			{
				character.animOffsets.clear();
				character.animationsArray = parsedJson.animations;
				for (anim in character.animationsArray)
				{
					character.addOffset(anim.anim, anim.offsets[0], anim.offsets[1]);
				}
				if (character.animationsArray[0] != null)
				{
					character.playAnim(character.animationsArray[0].anim, true);
				}

				character.singDuration = parsedJson.sing_duration;
				character.positionArray = parsedJson.position;
				character.cameraPosition = parsedJson.camera_position;

				character.imageFile = parsedJson.image;
				character.jsonScale = parsedJson.scale;
				character.noAntialiasing = parsedJson.no_antialiasing;
				character.originalFlipX = parsedJson.flip_x;
				character.healthIcon = parsedJson.healthicon;
				character.healthColorArray = parsedJson.healthbar_colors;
				character.setPosition(character.positionArray[0] + OFFSET_X + 100, character.positionArray[1]);
			}

			reloadCharacterImage();
			reloadCharacterDropDown();
			reloadCharacterOptions();
			resetHealthBarColor();
			updatePointerPos();
			genBoyOffsets();
		});
		templateCharacter.color = FlxColor.RED;
		templateCharacter.label.color = FlxColor.WHITE;

		tab_group.add(new FlxText(charDropDown.x, charDropDown.y - 18, 0, 'Character:'));
		tab_group.add(check_player);
		tab_group.add(reloadCharacter);
		tab_group.add(charDropDown);
		tab_group.add(reloadCharacter);
		tab_group.add(templateCharacter);
		UI_box.addGroup(tab_group);
	}

	// Combat changes
	// A lot's added here so look out for the end of changes line much later on
	var selectedEffectDropDown:FlxUIDropDownMenuCustom;
	var effectOffsetToggle:FlxUICheckBox;

	function addEffectSettingsUI()
	{
		var tab_group = new FlxUI(null, UI_box);
		tab_group.name = 'T Effect Settings';

		selectedEffectDropDown = new FlxUIDropDownMenuCustom(10, 30, FlxUIDropDownMenuCustom.makeStrIdLabelArray([''], true), function(pressed:String)
		{
			var selectedEffect:Int = Std.parseInt(pressed);
			effect = char.characterSprites.members[selectedEffect];
			if (effect != null)
			{
				daEffect = effect.thisSprite;
				loadEffect();
				var anim:SpriteAnimArray = effect.animationsArray[selectedEffect];
				effectAnimationInputText.text = anim.anim;
				effectAnimationNameInputText.text = anim.name;
				var indicesStr:String = anim.indices.toString();
				effectAnimationIndicesInputText.text = indicesStr.substr(1, indicesStr.length - 2);
				effectAnimationLoopCheckBox.checked = anim.loop;
				effectLayerStepper.value = effect.layer;
				effectScaleStepper.value = effect.jsonScale;
				if (anim.finishCallback != null)
					daEffectCallback = anim.finishCallback;
				else
					daEffectCallback = '';
				effectFlipXCheckBox.checked = effect.flipX;
				effectNoAntialiasingCheckBox.checked = effect.noAntialiasing;
				effectAnimationNameFramerate.value = anim.fps;
				if (effect.animAngle.get(anim.anim) != null)
					effectAnimationAngle.value = effect.animAngle.get(anim.anim);
				else
					effectAnimationAngle.value = 0;

				var curAnimInt:Int = 0;
				for (charAnim in char.animationsArray)
				{
					if (charAnim.anim == anim.anim)
					{
						curAnim = curAnimInt;
						break;
					}
					++curAnimInt;
				}

				char.playAnim(char.animationsArray[curAnim].anim, true);
			}
			reloadEffectDropDown();
			reloadCallbackDropDown();
			reloadEffectOptions();
			reloadEffectAnimationDropDown();
			genBoyOffsets();
		});

		reloadEffectDropDown();

		effectOffsetToggle = new FlxUICheckBox(10, 60, null, null, "Offset current\neffect anim?", 100);

		tab_group.add(new FlxText(selectedEffectDropDown.x, selectedEffectDropDown.y - 18, 0, 'Effect:'));
		tab_group.add(effectOffsetToggle);
		tab_group.add(selectedEffectDropDown);
		UI_box.addGroup(tab_group);
	}

	var effectImageInputText:FlxUIInputText;
	var effectReloadImage:FlxButton;
	var effectLayerStepper:FlxUINumericStepper;
	var effectScaleStepper:FlxUINumericStepper;
	var effectFlipXCheckBox:FlxUICheckBox;
	var effectNoAntialiasingCheckBox:FlxUICheckBox;
	var effectGeneralOffsetX:FlxUINumericStepper;
	var effectGeneralOffsetY:FlxUINumericStepper;

	function addEffectUI()
	{
		var tab_group = new FlxUI(null, UI_box);
		tab_group.name = "Effect";

		effectImageInputText = new FlxUIInputText(15, 30, 200, 'effects/bfFace', 8);
		var effectReloadImage:FlxButton = new FlxButton(effectImageInputText.x + 210, effectImageInputText.y - 3, "Reload Image", function()
		{
			if (effect != null)
			{
				effect.imageFile = effectImageInputText.text;
				reloadEffectImage();
			}
		});

		// y 65
		effectLayerStepper = new FlxUINumericStepper(15, 110, 1, 1);
		effectScaleStepper = new FlxUINumericStepper(15, 150, 0.1, 1, 0.05, 10, 1);

		effectFlipXCheckBox = new FlxUICheckBox(effectLayerStepper.x + 80, effectLayerStepper.y, null, null, "Flip X", 50);
		if (effect != null)
		{
			effectFlipXCheckBox.checked = effect.flipX;
			if (effect.isPlayer)
				effectFlipXCheckBox.checked = !effectFlipXCheckBox.checked;
		}
		else
			effectFlipXCheckBox.checked = false;
		effectFlipXCheckBox.callback = function()
		{
			if (effect != null)
			{
				effect.originalFlipX = !effect.originalFlipX;
				effect.flipX = effect.originalFlipX;
				if (effect.isPlayer)
					effect.flipX = !effect.flipX;

				ghostEffect.flipX = effect.flipX;
			}
		};

		effectNoAntialiasingCheckBox = new FlxUICheckBox(effectScaleStepper.x + 80, effectScaleStepper.y, null, null, "No Antialiasing", 80);
		if (effect != null)
			effectNoAntialiasingCheckBox.checked = effect.noAntialiasing;
		else
			effectNoAntialiasingCheckBox.checked = false;
		effectNoAntialiasingCheckBox.callback = function()
		{
			if (effect != null)
			{
				effect.antialiasing = false;
				if (!effectNoAntialiasingCheckBox.checked && ClientPrefs.globalAntialiasing)
				{
					effect.antialiasing = true;
				}
				effect.noAntialiasing = effectNoAntialiasingCheckBox.checked;
				ghostEffect.antialiasing = effect.antialiasing;
			}
		};

		if (effect != null)
		{
			effectGeneralOffsetX = new FlxUINumericStepper(effectFlipXCheckBox.x + 110, effectFlipXCheckBox.y, 10, effect.generalOffset[0], -9000, 9000, 0);
			effectGeneralOffsetY = new FlxUINumericStepper(effectGeneralOffsetX.x + 60, effectGeneralOffsetX.y, 10, effect.generalOffset[1], -9000, 9000, 0);
		}
		else
		{
			effectGeneralOffsetX = new FlxUINumericStepper(effectFlipXCheckBox.x + 110, effectFlipXCheckBox.y, 10, 0, -9000, 9000, 0);
			effectGeneralOffsetY = new FlxUINumericStepper(effectGeneralOffsetX.x + 60, effectGeneralOffsetX.y, 10, 0, -9000, 9000, 0);
		}

		var saveEffectButton:FlxButton = new FlxButton(235, 190, "Save Effect", function()
		{
			if (effect != null)
				saveEffect();
		});

		tab_group.add(new FlxText(effectLayerStepper.x, effectLayerStepper.y - 18, 0, 'Layer:'));
		tab_group.add(new FlxText(effectScaleStepper.x, effectScaleStepper.y - 18, 0, 'Scale:'));
		tab_group.add(new FlxText(15, effectImageInputText.y - 18, 0, 'Image file name:'));
		tab_group.add(new FlxText(effectGeneralOffsetX.x, effectGeneralOffsetX.y - 18, 0, 'General Offset:'));
		tab_group.add(effectImageInputText);
		tab_group.add(effectReloadImage);
		tab_group.add(effectLayerStepper);
		tab_group.add(effectScaleStepper);
		tab_group.add(effectFlipXCheckBox);
		tab_group.add(effectNoAntialiasingCheckBox);
		tab_group.add(effectGeneralOffsetX);
		tab_group.add(effectGeneralOffsetY);
		tab_group.add(saveEffectButton);
		UI_characterbox.addGroup(tab_group);
	}

	var effectAnimationDropDown:FlxUIDropDownMenuCustom;
	var finishCallbackDropDown:FlxUIDropDownMenuCustom;
	var effectAnimationInputText:FlxUIInputText;
	var effectAnimationNameInputText:FlxUIInputText;
	var effectAnimationIndicesInputText:FlxUIInputText;
	var effectAnimationNameFramerate:FlxUINumericStepper;
	var effectAnimationLoopCheckBox:FlxUICheckBox;
	var effectAnimationAngle:FlxUINumericStepper;

	function addEffectAnimUI()
	{
		var tab_group = new FlxUI(null, UI_box);
		tab_group.name = 'D Anim Effect';

		effectAnimationDropDown = new FlxUIDropDownMenuCustom(15, 30, FlxUIDropDownMenuCustom.makeStrIdLabelArray([''], true), function(pressed:String)
		{
			var selectedAnimation:Int = Std.parseInt(pressed);
			if (effect != null)
			{
				var anim:SpriteAnimArray = effect.animationsArray[selectedAnimation];
				effectAnimationInputText.text = anim.anim;
				effectAnimationNameInputText.text = anim.name;
				effectAnimationLoopCheckBox.checked = anim.loop;
				effectAnimationNameFramerate.value = anim.fps;
				effectAnimationAngle.value = anim.angle;
				var indicesStr:String = anim.indices.toString();
				effectAnimationIndicesInputText.text = indicesStr.substr(1, indicesStr.length - 2);
				daEffectCallback = anim.finishCallback;
				selectedEffectAnimID = selectedAnimation;
				if (effect.animAngle.get(anim.anim) != null)
					effectAnimationAngle.value = effect.animAngle.get(anim.anim);
				else
					effectAnimationAngle.value = 0;

				var curAnimInt:Int = 0;
				for (charAnim in char.animationsArray)
				{
					if (charAnim.anim == anim.anim)
					{
						curAnim = curAnimInt;
						break;
					}
					++curAnimInt;
				}

				char.playAnim(char.animationsArray[curAnim].anim, true);
			}
			reloadCallbackDropDown();
		});

		finishCallbackDropDown = new FlxUIDropDownMenuCustom(165, 30, FlxUIDropDownMenuCustom.makeStrIdLabelArray([''], true), function(pressed:String)
		{
			var selectedCallback:Int = Std.parseInt(pressed);
			daEffectCallback = CharacterExtra.validCallbacks[selectedCallback];
			reloadCallbackDropDown();
			reloadEffectOptions();
		});
		reloadCallbackDropDown();

		effectAnimationInputText = new FlxUIInputText(15, 85, 200, '', 8);
		effectAnimationNameInputText = new FlxUIInputText(effectAnimationInputText.x, effectAnimationInputText.y + 35, 200, '', 8);
		effectAnimationIndicesInputText = new FlxUIInputText(effectAnimationInputText.x, effectAnimationNameInputText.y + 40, 200, '', 8);

		effectAnimationNameFramerate = new FlxUINumericStepper(230, effectAnimationInputText.y, 1, 24, 0, 240, 0);
		effectAnimationLoopCheckBox = new FlxUICheckBox(230, effectAnimationNameInputText.y - 5, null, null, "Should it loop?", 100);
		effectAnimationAngle = new FlxUINumericStepper(230, effectAnimationIndicesInputText.y, 1, 0, 0, 360, 3);

		var effectUpdateButton:FlxButton = new FlxButton(70, 190, "Add/Update", function()
		{
			if (effect != null)
			{
				var indices:Array<Int> = [];
				var indicesStr:Array<String> = animationIndicesInputText.text.trim().split(',');
				if (indicesStr.length > 1)
				{
					for (i in 0...indicesStr.length)
					{
						var index:Int = Std.parseInt(indicesStr[i]);
						if (indicesStr[i] != null && indicesStr[i] != '' && !Math.isNaN(index) && index > -1)
						{
							indices.push(index);
						}
					}
				}

				var lastEffectAnimation:SpriteAnimArray = null;
				for (anim in effect.animationsArray)
				{
					if (anim.anim == char.animationsArray[curAnim].anim)
						lastEffectAnimation = anim;
				}

				var lastAnim:String = '';
				if (lastEffectAnimation != null)
				{
					lastAnim = lastEffectAnimation.anim;
				}

				var lastOffsets:Array<Int> = [0, 0];
				for (anim in effect.animationsArray)
				{
					if (effectAnimationInputText.text == anim.anim)
					{
						lastOffsets = anim.offsets;
						if (effect.animation.getByName(effectAnimationInputText.text) != null)
						{
							effect.animation.remove(effectAnimationInputText.text);
						}
						effect.animationsArray.remove(anim);
					}
				}

				var newAnim:SpriteAnimArray = {
					anim: effectAnimationInputText.text,
					name: effectAnimationNameInputText.text,
					fps: Math.round(effectAnimationNameFramerate.value),
					loop: effectAnimationLoopCheckBox.checked,
					indices: indices,
					offsets: lastOffsets,
					finishCallback: daEffectCallback,
					angle: effectAnimationAngle.value
				};

				effect.animation.addByPrefix(newAnim.anim, newAnim.name, newAnim.fps, newAnim.loop);

				if (!effect.animOffsets.exists(newAnim.anim))
				{
					effect.addOffset(newAnim.anim, 0, 0);
				}
				effect.animationsArray.push(newAnim);

				if (lastAnim == effectAnimationInputText.text)
				{
					var leAnim:FlxAnimation = char.animation.getByName(lastAnim);
					if (leAnim != null && leAnim.frames.length > 0)
					{
						char.playAnim(lastAnim, true);
					}
					else
					{
						for (i in 0...effect.animationsArray.length)
						{
							if (effect.animationsArray[i] != null)
							{
								leAnim = effect.animation.getByName(effect.animationsArray[i].anim);
								if (leAnim != null && leAnim.frames.length > 0)
								{
									char.playAnim(effect.animationsArray[i].anim, true);
									break;
								}
							}
						}
					}
				}
			}

			reloadEffectAnimationDropDown();
			genBoyOffsets();
		});

		var effectRemoveButton:FlxButton = new FlxButton(180, 190, "Remove", function()
		{
			if (effect != null)
			{
				for (anim in effect.animationsArray)
				{
					if (effectAnimationInputText.text == anim.anim)
					{
						var resetAnim:Bool = false;
						if (effect.animation.curAnim != null && anim.anim == effect.animation.curAnim.name)
							resetAnim = true;

						if (effect.animation.getByName(anim.anim) != null)
						{
							effect.animation.remove(anim.anim);
						}
						if (effect.animOffsets.exists(anim.anim))
						{
							effect.animOffsets.remove(anim.anim);
						}
						effect.animationsArray.remove(anim);

						if (resetAnim && effect.animationsArray.length > 0)
						{
							effect.playAnim(effect.animationsArray[0].anim, true);
						}
						reloadEffectAnimationDropDown();
						genBoyOffsets();
						break;
					}
				}
			}
		});

		tab_group.add(new FlxText(15, effectAnimationNameInputText.y - 18, 0, 'Animation on .XML/.TXT file:'));
		tab_group.add(new FlxText(effectAnimationIndicesInputText.x, effectAnimationIndicesInputText.y - 18, 0, 'ADVANCED - Animation Indices:'));
		tab_group.add(new FlxText(effectAnimationInputText.x, effectAnimationInputText.y - 18, 0, 'Animation name:'));
		tab_group.add(new FlxText(effectAnimationNameFramerate.x, effectAnimationNameFramerate.y - 18, 0, 'Framerate:'));
		tab_group.add(new FlxText(effectAnimationAngle.x, effectAnimationAngle.y - 18, 0, 'Rotation Angle:'));

		tab_group.add(effectAnimationInputText);
		tab_group.add(effectAnimationNameInputText);
		tab_group.add(effectAnimationIndicesInputText);
		tab_group.add(effectAnimationNameFramerate);
		tab_group.add(effectAnimationLoopCheckBox);
		tab_group.add(effectAnimationAngle);
		tab_group.add(effectUpdateButton);
		tab_group.add(effectRemoveButton);
		tab_group.add(new FlxText(effectAnimationDropDown.x, effectAnimationDropDown.y - 18, 0, 'Animations:'));
		tab_group.add(effectAnimationDropDown);
		tab_group.add(new FlxText(finishCallbackDropDown.x, finishCallbackDropDown.y - 15, 0, 'On Anim Finish:'));
		tab_group.add(finishCallbackDropDown);
		UI_characterbox.addGroup(tab_group);
	}

	// End of changes
	var imageInputText:FlxUIInputText;
	var healthIconInputText:FlxUIInputText;

	var singDurationStepper:FlxUINumericStepper;
	var scaleStepper:FlxUINumericStepper;
	var positionXStepper:FlxUINumericStepper;
	var positionYStepper:FlxUINumericStepper;
	var positionCameraXStepper:FlxUINumericStepper;
	var positionCameraYStepper:FlxUINumericStepper;

	var flipXCheckBox:FlxUICheckBox;
	var noAntialiasingCheckBox:FlxUICheckBox;

	var healthColorStepperR:FlxUINumericStepper;
	var healthColorStepperG:FlxUINumericStepper;
	var healthColorStepperB:FlxUINumericStepper;

	function addCharacterUI()
	{
		var tab_group = new FlxUI(null, UI_box);
		tab_group.name = "Character";

		imageInputText = new FlxUIInputText(15, 30, 200, 'characters/BOYFRIEND', 8);
		var reloadImage:FlxButton = new FlxButton(imageInputText.x + 210, imageInputText.y - 3, "Reload Image", function()
		{
			char.imageFile = imageInputText.text;
			reloadCharacterImage();
			if (char.animation.curAnim != null)
			{
				char.playAnim(char.animation.curAnim.name, true);
			}
		});

		var decideIconColor:FlxButton = new FlxButton(reloadImage.x, reloadImage.y + 30, "Get Icon Color", function()
		{
			var coolColor = FlxColor.fromInt(CoolUtil.dominantColor(leHealthIcon));
			healthColorStepperR.value = coolColor.red;
			healthColorStepperG.value = coolColor.green;
			healthColorStepperB.value = coolColor.blue;
			getEvent(FlxUINumericStepper.CHANGE_EVENT, healthColorStepperR, null);
			getEvent(FlxUINumericStepper.CHANGE_EVENT, healthColorStepperG, null);
			getEvent(FlxUINumericStepper.CHANGE_EVENT, healthColorStepperB, null);
		});

		healthIconInputText = new FlxUIInputText(15, imageInputText.y + 35, 75, leHealthIcon.getCharacter(), 8);

		singDurationStepper = new FlxUINumericStepper(15, healthIconInputText.y + 45, 0.1, 4, 0, 999, 1);

		scaleStepper = new FlxUINumericStepper(15, singDurationStepper.y + 40, 0.1, 1, 0.05, 10, 1);

		flipXCheckBox = new FlxUICheckBox(singDurationStepper.x + 80, singDurationStepper.y, null, null, "Flip X", 50);
		flipXCheckBox.checked = char.flipX;
		if (char.isPlayer)
			flipXCheckBox.checked = !flipXCheckBox.checked;
		flipXCheckBox.callback = function()
		{
			char.originalFlipX = !char.originalFlipX;
			char.flipX = char.originalFlipX;
			if (char.isPlayer)
				char.flipX = !char.flipX;

			ghostChar.flipX = char.flipX;
		};

		noAntialiasingCheckBox = new FlxUICheckBox(flipXCheckBox.x, flipXCheckBox.y + 40, null, null, "No Antialiasing", 80);
		noAntialiasingCheckBox.checked = char.noAntialiasing;
		noAntialiasingCheckBox.callback = function()
		{
			char.antialiasing = false;
			if (!noAntialiasingCheckBox.checked && ClientPrefs.globalAntialiasing)
			{
				char.antialiasing = true;
			}
			char.noAntialiasing = noAntialiasingCheckBox.checked;
			ghostChar.antialiasing = char.antialiasing;
		};

		positionXStepper = new FlxUINumericStepper(flipXCheckBox.x + 110, flipXCheckBox.y, 10, char.positionArray[0], -9000, 9000, 0);
		positionYStepper = new FlxUINumericStepper(positionXStepper.x + 60, positionXStepper.y, 10, char.positionArray[1], -9000, 9000, 0);

		positionCameraXStepper = new FlxUINumericStepper(positionXStepper.x, positionXStepper.y + 40, 10, char.cameraPosition[0], -9000, 9000, 0);
		positionCameraYStepper = new FlxUINumericStepper(positionYStepper.x, positionYStepper.y + 40, 10, char.cameraPosition[1], -9000, 9000, 0);

		var saveCharacterButton:FlxButton = new FlxButton(reloadImage.x, noAntialiasingCheckBox.y + 40, "Save Character", function()
		{
			saveCharacter();
		});

		healthColorStepperR = new FlxUINumericStepper(singDurationStepper.x, saveCharacterButton.y, 20, char.healthColorArray[0], 0, 255, 0);
		healthColorStepperG = new FlxUINumericStepper(singDurationStepper.x + 65, saveCharacterButton.y, 20, char.healthColorArray[1], 0, 255, 0);
		healthColorStepperB = new FlxUINumericStepper(singDurationStepper.x + 130, saveCharacterButton.y, 20, char.healthColorArray[2], 0, 255, 0);

		tab_group.add(new FlxText(15, imageInputText.y - 18, 0, 'Image file name:'));
		tab_group.add(new FlxText(15, healthIconInputText.y - 18, 0, 'Health icon name:'));
		tab_group.add(new FlxText(15, singDurationStepper.y - 18, 0, 'Sing Animation length:'));
		tab_group.add(new FlxText(15, scaleStepper.y - 18, 0, 'Scale:'));
		tab_group.add(new FlxText(positionXStepper.x, positionXStepper.y - 18, 0, 'Character X/Y:'));
		tab_group.add(new FlxText(positionCameraXStepper.x, positionCameraXStepper.y - 18, 0, 'Camera X/Y:'));
		tab_group.add(new FlxText(healthColorStepperR.x, healthColorStepperR.y - 18, 0, 'Health bar R/G/B:'));
		tab_group.add(imageInputText);
		tab_group.add(reloadImage);
		tab_group.add(decideIconColor);
		tab_group.add(healthIconInputText);
		tab_group.add(singDurationStepper);
		tab_group.add(scaleStepper);
		tab_group.add(flipXCheckBox);
		tab_group.add(noAntialiasingCheckBox);
		tab_group.add(positionXStepper);
		tab_group.add(positionYStepper);
		tab_group.add(positionCameraXStepper);
		tab_group.add(positionCameraYStepper);
		tab_group.add(healthColorStepperR);
		tab_group.add(healthColorStepperG);
		tab_group.add(healthColorStepperB);
		tab_group.add(saveCharacterButton);
		UI_characterbox.addGroup(tab_group);
	}

	var ghostDropDown:FlxUIDropDownMenuCustom;
	var animationDropDown:FlxUIDropDownMenuCustom;
	var animationInputText:FlxUIInputText;
	var animationNameInputText:FlxUIInputText;
	var animationIndicesInputText:FlxUIInputText;
	var animationNameFramerate:FlxUINumericStepper;
	var animationLoopCheckBox:FlxUICheckBox;

	function addAnimationsUI()
	{
		var tab_group = new FlxUI(null, UI_box);
		tab_group.name = "Animations";

		// Combat change
		// Extending this box since animations need the text-space
		// animationInputText = new FlxUIInputText(15, 85, 80, '', 8);
		animationInputText = new FlxUIInputText(15, 85, 150, '', 8);
		animationNameInputText = new FlxUIInputText(animationInputText.x, animationInputText.y + 35, 150, '', 8);
		animationIndicesInputText = new FlxUIInputText(animationNameInputText.x, animationNameInputText.y + 40, 250, '', 8);
		animationNameFramerate = new FlxUINumericStepper(animationInputText.x + 170, animationInputText.y, 1, 24, 0, 240, 0);
		animationLoopCheckBox = new FlxUICheckBox(animationNameInputText.x + 170, animationNameInputText.y - 1, null, null, "Should it Loop?", 100);

		animationDropDown = new FlxUIDropDownMenuCustom(15, animationInputText.y - 55, FlxUIDropDownMenuCustom.makeStrIdLabelArray([''], true),
			function(pressed:String)
			{
				var selectedAnimation:Int = Std.parseInt(pressed);
				var anim:AnimArray = char.animationsArray[selectedAnimation];
				animationInputText.text = anim.anim;
				animationNameInputText.text = anim.name;
				animationLoopCheckBox.checked = anim.loop;
				animationNameFramerate.value = anim.fps;

				var indicesStr:String = anim.indices.toString();
				animationIndicesInputText.text = indicesStr.substr(1, indicesStr.length - 2);
			});

		ghostDropDown = new FlxUIDropDownMenuCustom(animationDropDown.x + 150, animationDropDown.y, FlxUIDropDownMenuCustom.makeStrIdLabelArray([''], true),
			function(pressed:String)
			{
				var selectedAnimation:Int = Std.parseInt(pressed);
				// Combat changes
				// Switching chars to layers to affect both the character and their effects when applicable
				// ghostChar.visible = false;
				ghostLayer.visible = false;
				// char.alpha = 1;
				charLayer.alpha = 1;
				if (selectedAnimation > 0)
				{
					// ghostChar.visible = true;
					ghostLayer.visible = true;
					ghostChar.playAnim(ghostChar.animationsArray[selectedAnimation - 1].anim, true);
					// char.alpha = 0.85;
					charLayer.alpha = 0.85;
				}
				// End of changes
			});

		var addUpdateButton:FlxButton = new FlxButton(70, animationIndicesInputText.y + 30, "Add/Update", function()
		{
			var indices:Array<Int> = [];
			var indicesStr:Array<String> = animationIndicesInputText.text.trim().split(',');
			if (indicesStr.length > 1)
			{
				for (i in 0...indicesStr.length)
				{
					var index:Int = Std.parseInt(indicesStr[i]);
					if (indicesStr[i] != null && indicesStr[i] != '' && !Math.isNaN(index) && index > -1)
					{
						indices.push(index);
					}
				}
			}

			var lastAnim:String = '';
			if (char.animationsArray[curAnim] != null)
			{
				lastAnim = char.animationsArray[curAnim].anim;
			}

			var lastOffsets:Array<Int> = [0, 0];
			for (anim in char.animationsArray)
			{
				if (animationInputText.text == anim.anim)
				{
					lastOffsets = anim.offsets;
					if (char.animation.getByName(animationInputText.text) != null)
					{
						char.animation.remove(animationInputText.text);
					}
					char.animationsArray.remove(anim);
				}
			}

			var newAnim:AnimArray = {
				anim: animationInputText.text,
				name: animationNameInputText.text,
				fps: Math.round(animationNameFramerate.value),
				loop: animationLoopCheckBox.checked,
				indices: indices,
				offsets: lastOffsets
			};
			if (indices != null && indices.length > 0)
			{
				char.animation.addByIndices(newAnim.anim, newAnim.name, newAnim.indices, "", newAnim.fps, newAnim.loop);
			}
			else
			{
				char.animation.addByPrefix(newAnim.anim, newAnim.name, newAnim.fps, newAnim.loop);
			}

			if (!char.animOffsets.exists(newAnim.anim))
			{
				char.addOffset(newAnim.anim, 0, 0);
			}
			char.animationsArray.push(newAnim);

			if (lastAnim == animationInputText.text)
			{
				var leAnim:FlxAnimation = char.animation.getByName(lastAnim);
				if (leAnim != null && leAnim.frames.length > 0)
				{
					char.playAnim(lastAnim, true);
				}
				else
				{
					for (i in 0...char.animationsArray.length)
					{
						if (char.animationsArray[i] != null)
						{
							leAnim = char.animation.getByName(char.animationsArray[i].anim);
							if (leAnim != null && leAnim.frames.length > 0)
							{
								char.playAnim(char.animationsArray[i].anim, true);
								curAnim = i;
								break;
							}
						}
					}
				}
			}

			reloadAnimationDropDown();
			genBoyOffsets();
			trace('Added/Updated animation: ' + animationInputText.text);
		});

		var removeButton:FlxButton = new FlxButton(180, animationIndicesInputText.y + 30, "Remove", function()
		{
			for (anim in char.animationsArray)
			{
				if (animationInputText.text == anim.anim)
				{
					var resetAnim:Bool = false;
					if (char.animation.curAnim != null && anim.anim == char.animation.curAnim.name)
						resetAnim = true;

					if (char.animation.getByName(anim.anim) != null)
					{
						char.animation.remove(anim.anim);
					}
					if (char.animOffsets.exists(anim.anim))
					{
						char.animOffsets.remove(anim.anim);
					}
					char.animationsArray.remove(anim);

					if (resetAnim && char.animationsArray.length > 0)
					{
						char.playAnim(char.animationsArray[0].anim, true);
					}

					reloadAnimationDropDown();
					genBoyOffsets();
					trace('Removed animation: ' + animationInputText.text);
					break;
				}
			}
		});

		tab_group.add(new FlxText(animationDropDown.x, animationDropDown.y - 18, 0, 'Animations:'));
		tab_group.add(new FlxText(ghostDropDown.x, ghostDropDown.y - 18, 0, 'Animation Ghost:'));
		tab_group.add(new FlxText(animationInputText.x, animationInputText.y - 18, 0, 'Animation name:'));
		tab_group.add(new FlxText(animationNameFramerate.x, animationNameFramerate.y - 18, 0, 'Framerate:'));
		tab_group.add(new FlxText(animationNameInputText.x, animationNameInputText.y - 18, 0, 'Animation on .XML/.TXT file:'));
		tab_group.add(new FlxText(animationIndicesInputText.x, animationIndicesInputText.y - 18, 0, 'ADVANCED - Animation Indices:'));

		tab_group.add(animationInputText);
		tab_group.add(animationNameInputText);
		tab_group.add(animationIndicesInputText);
		tab_group.add(animationNameFramerate);
		tab_group.add(animationLoopCheckBox);
		tab_group.add(addUpdateButton);
		tab_group.add(removeButton);
		tab_group.add(ghostDropDown);
		tab_group.add(animationDropDown);
		UI_characterbox.addGroup(tab_group);
	}

	override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>)
	{
		if (id == FlxUIInputText.CHANGE_EVENT && (sender is FlxUIInputText))
		{
			if (sender == healthIconInputText)
			{
				leHealthIcon.changeIcon(healthIconInputText.text);
				char.healthIcon = healthIconInputText.text;
				updatePresence();
			}
			else if (sender == imageInputText)
			{
				char.imageFile = imageInputText.text;
			}
			// Combat change
			else if (sender == effectImageInputText)
			{
				if (effect != null)
				{
					effect.imageFile = effectImageInputText.text;
				}
			}
		}
		else if (id == FlxUINumericStepper.CHANGE_EVENT && (sender is FlxUINumericStepper))
		{
			if (sender == scaleStepper)
			{
				reloadCharacterImage();
				char.jsonScale = sender.value;
				char.setGraphicSize(Std.int(char.width * char.jsonScale));
				char.updateHitbox();
				ghostChar.setGraphicSize(Std.int(ghostChar.width * char.jsonScale));
				ghostChar.updateHitbox();
				reloadGhost();
				updatePointerPos();

				if (char.animation.curAnim != null)
				{
					char.playAnim(char.animation.curAnim.name, true);
				}
			}
			else if (sender == positionXStepper)
			{
				char.positionArray[0] = positionXStepper.value;
				char.x = char.positionArray[0] + OFFSET_X + 100;
				updatePointerPos();
			}
			else if (sender == singDurationStepper)
			{
				char.singDuration = singDurationStepper.value; // ermm you forgot this??
			}
			else if (sender == positionYStepper)
			{
				char.positionArray[1] = positionYStepper.value;
				char.y = char.positionArray[1];
				updatePointerPos();
			}
			else if (sender == positionCameraXStepper)
			{
				char.cameraPosition[0] = positionCameraXStepper.value;
				updatePointerPos();
			}
			else if (sender == positionCameraYStepper)
			{
				char.cameraPosition[1] = positionCameraYStepper.value;
				updatePointerPos();
			}
			else if (sender == healthColorStepperR)
			{
				char.healthColorArray[0] = Math.round(healthColorStepperR.value);
				healthBarBG.color = FlxColor.fromRGB(char.healthColorArray[0], char.healthColorArray[1], char.healthColorArray[2]);
			}
			else if (sender == healthColorStepperG)
			{
				char.healthColorArray[1] = Math.round(healthColorStepperG.value);
				healthBarBG.color = FlxColor.fromRGB(char.healthColorArray[0], char.healthColorArray[1], char.healthColorArray[2]);
			}
			else if (sender == healthColorStepperB)
			{
				char.healthColorArray[2] = Math.round(healthColorStepperB.value);
				healthBarBG.color = FlxColor.fromRGB(char.healthColorArray[0], char.healthColorArray[1], char.healthColorArray[2]);
			}
			// Combat changes
			else if (sender == effectScaleStepper)
			{
				if (effect != null)
				{
					reloadEffectImage();
					effect.jsonScale = sender.value;
					effect.setGraphicSize(Std.int(effect.width * effect.jsonScale));
					effect.updateHitbox();
					ghostEffect.setGraphicSize(Std.int(ghostEffect.width * effect.jsonScale));
					ghostEffect.updateHitbox();
					reloadGhost();

					if (char.animation.curAnim != null)
					{
						char.playAnim(char.animation.curAnim.name, true);
					}
				}
			}
			else if (sender == effectLayerStepper)
			{
				if (effect != null)
				{
					effect.layer = sender.value;
					effect.zDepth = effect.layer;
					charLayer.sort(PlayState.sortByZ);

					if (char.animation.curAnim != null)
					{
						char.playAnim(char.animation.curAnim.name, true);
					}
				}
			}
			else if (sender == effectGeneralOffsetX && effect != null)
			{
				if (effect != null)
				{
					effect.generalOffset[0] = effectGeneralOffsetX.value;
					char.playAnim(char.animationsArray[curAnim].anim, false);
					updatePointerPos();
				}
			}
			else if (sender == effectGeneralOffsetY && effect != null)
			{
				if (effect != null)
				{
					effect.generalOffset[1] = effectGeneralOffsetY.value;
					char.playAnim(char.animationsArray[curAnim].anim, false);
					updatePointerPos();
				}
			}
			else if (sender == effectAnimationAngle && effect != null)
			{
				if (effect != null)
				{
					var checkEffectAnim:SpriteAnimArray = effect.animationsArray[selectedEffectAnimID];
					for (anim in effect.animationsArray)
					{
						if (anim.anim == char.animationsArray[curAnim].anim)
							checkEffectAnim = anim;
					}

					effect.addAngle(checkEffectAnim.anim, effectAnimationAngle.value);
					ghostEffect.addAngle(checkEffectAnim.anim, effectAnimationAngle.value);

					var curAnimInt:Int = 0;
					for (charAnim in char.animationsArray)
					{
						if (charAnim.anim == checkEffectAnim.anim)
						{
							curAnim = curAnimInt;
							break;
						}
						++curAnimInt;
					}

					char.playAnim(char.animationsArray[curAnim].anim, false);

					if (ghostChar.animation.curAnim != null
						&& char.animation.curAnim != null
						&& char.animation.curAnim.name == ghostChar.animation.curAnim.name)
					{
						ghostChar.playAnim(char.animation.curAnim.name, false);
					}
					updatePointerPos();
				}
			}
			// End of changes
		}
	}

	// Combat change
	function reloadEffectImage()
	{
		if (effect != null)
		{
			var lastAnim:String = '';
			if (effect.animation.curAnim != null)
			{
				lastAnim = effect.animation.curAnim.name;
			}
			var anims:Array<AnimArray> = effect.animationsArray.copy();
			if (Paths.fileExists('images/' + effect.imageFile + '/Animation.json', TEXT))
			{
				effect.frames = AtlasFrameMaker.construct(effect.imageFile);
			}
			else if (Paths.fileExists('images/' + effect.imageFile + '.txt', TEXT))
			{
				effect.frames = Paths.getPackerAtlas(effect.imageFile);
			}
			else
			{
				effect.frames = Paths.getSparrowAtlas(effect.imageFile);
			}

			if (effect.animationsArray != null && effect.animationsArray.length > 0)
			{
				for (anim in effect.animationsArray)
				{
					var animAnim:String = '' + anim.anim;
					var animName:String = '' + anim.name;
					var animFps:Int = anim.fps;
					var animLoop:Bool = !!anim.loop; // Bruh
					var animIndices:Array<Int> = anim.indices;
					if (animIndices != null && animIndices.length > 0)
					{
						effect.animation.addByIndices(animAnim, animName, animIndices, "", animFps, animLoop);
					}
					else
					{
						effect.animation.addByPrefix(animAnim, animName, animFps, animLoop);
					}
				}
			}
			else
			{
				effect.quickAnimAdd('idle', 'BF idle dance');
			}

			if (lastAnim != '')
			{
				effect.playAnim(lastAnim, true);
			}
			else
			{
				effect.playAnim('idle');
			}
		}
	}

	function reloadCharacterImage()
	{
		var lastAnim:String = '';
		if (char.animation.curAnim != null)
		{
			lastAnim = char.animation.curAnim.name;
		}
		var anims:Array<AnimArray> = char.animationsArray.copy();
		if (Paths.fileExists('images/' + char.imageFile + '/Animation.json', TEXT))
		{
			char.frames = AtlasFrameMaker.construct(char.imageFile);
		}
		else if (Paths.fileExists('images/' + char.imageFile + '.txt', TEXT))
		{
			char.frames = Paths.getPackerAtlas(char.imageFile);
		}
		else
		{
			char.frames = Paths.getSparrowAtlas(char.imageFile);
		}

		if (char.animationsArray != null && char.animationsArray.length > 0)
		{
			for (anim in char.animationsArray)
			{
				var animAnim:String = '' + anim.anim;
				var animName:String = '' + anim.name;
				var animFps:Int = anim.fps;
				var animLoop:Bool = !!anim.loop; // Bruh
				var animIndices:Array<Int> = anim.indices;
				if (animIndices != null && animIndices.length > 0)
				{
					char.animation.addByIndices(animAnim, animName, animIndices, "", animFps, animLoop);
				}
				else
				{
					char.animation.addByPrefix(animAnim, animName, animFps, animLoop);
				}
			}
		}
		else
		{
			char.quickAnimAdd('idle', 'BF idle dance');
		}

		if (lastAnim != '')
		{
			char.playAnim(lastAnim, true);
		}
		else
		{
			char.dance();
		}
		ghostDropDown.selectedLabel = '';
		reloadGhost();
	}

	function genBoyOffsets():Void
	{
		var daLoop:Int = 0;

		var i:Int = dumbTexts.members.length - 1;
		while (i >= 0)
		{
			var memb:FlxText = dumbTexts.members[i];
			if (memb != null)
			{
				memb.kill();
				dumbTexts.remove(memb);
				memb.destroy();
			}
			--i;
		}
		dumbTexts.clear();

		// Combat changes
		var i:Int = textPages.members.length - 1;
		while (i >= 0)
		{
			var memb:FlxTypedGroup<FlxText> = textPages.members[i];
			if (memb != null)
			{
				memb.kill();
				textPages.remove(memb);
				memb.destroy();
			}
			--i;
		}
		textPages.clear();

		var pageNo:Int = 0;
		var newTextPage = new FlxTypedGroup<FlxText>();
		textPages.add(newTextPage);
		// End of changes

		for (anim => offsets in char.animOffsets)
		{
			// Combat changes
			if (daLoop == 0)
			{
				var textTitle:FlxText = new FlxText(10, 30, 0, "Page " + (pageNo + 1) + " (Character)", 15);
				textTitle.setFormat(null, 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				textTitle.scrollFactor.set();
				textTitle.borderSize = 1;
				dumbTexts.add(textTitle);
				textTitle.cameras = [camHUD];
				textPages.members[pageNo].add(textTitle);
			}
			// End of changes
			var text:FlxText = new FlxText(10, 70 + (18 * daLoop), 0, anim + ": " + offsets, 15);
			text.setFormat(null, 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			text.scrollFactor.set();
			text.borderSize = 1;
			dumbTexts.add(text);
			text.cameras = [camHUD];

			// Combat changes
			textPages.members[pageNo].add(text);
			if (daLoop != 0 && daLoop % 25 == 0)
			{
				pageNo++;
				var newTextPage = new FlxTypedGroup<FlxText>();
				textPages.add(newTextPage);
				daLoop = 0;
			}
			else
				daLoop++;
			// This daLoop comment may look redundant, but remember that this is showing that you're replacing the statement-less version
			// daLoop++;
			// End of changes
		}

		// Combat change
		effectPages = [];
		if (effect != null)
		{
			pageNo++;
			var newTextPage = new FlxTypedGroup<FlxText>();
			textPages.add(newTextPage);
			daLoop = 0;
			effectPages.push(pageNo);

			for (anim => offsets in effect.animOffsets)
			{
				// Combat changes
				if (daLoop == 0)
				{
					var textTitle:FlxText = new FlxText(10, 30, 0, "Page " + (pageNo + 1) + " (Effects)", 15);
					textTitle.setFormat(null, 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
					textTitle.scrollFactor.set();
					textTitle.borderSize = 1;
					dumbTexts.add(textTitle);
					textTitle.cameras = [camHUD];
					textPages.members[pageNo].add(textTitle);
				}
				// End of changes
				var text:FlxText = new FlxText(10, 70 + (18 * daLoop), 0, anim + ": " + offsets, 15);
				text.setFormat(null, 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				text.scrollFactor.set();
				text.borderSize = 1;
				dumbTexts.add(text);
				text.cameras = [camHUD];

				textPages.members[pageNo].add(text);
				if (daLoop != 0 && daLoop % 25 == 0)
				{
					pageNo++;
					var newTextPage = new FlxTypedGroup<FlxText>();
					textPages.add(newTextPage);
					daLoop = 0;
					effectPages.push(pageNo);
				}
				else
					daLoop++;
			}
		}

		// This resets the curPage back to a valid value if switching to a character with a different number of pages
		if (curPage < 0)
			curPage = textPages.members.length - 1;

		if (curPage >= textPages.members.length)
			curPage = 0;

		changePage();
		// End of changes

		textAnim.visible = true;
		if (dumbTexts.length < 1)
		{
			var text:FlxText = new FlxText(10, 38, 0, "ERROR! No animations found.", 15);
			text.scrollFactor.set();
			text.borderSize = 1;
			dumbTexts.add(text);
			textAnim.visible = false;
		}
	}

	// Combat change
	function changePage()
	{
		if (textPages.members.length > 0)
		{
			textPages.forEach(function(grp:FlxTypedGroup<FlxText>)
			{
				if (grp == textPages.members[curPage])
					grp.visible = true;
				else
					grp.visible = false;
			});
		}
	}

	// Combat change
	function loadEffect()
	{
		effect = null;
		ghostEffect = null;

		if (char != null && char.characterSprites.length > 0)
		{
			char.characterSprites.forEach(function(spr:CharacterExtra)
			{
				charLayer.add(spr);
				if (daEffect == null || daEffect == '' || spr.thisSprite == daEffect)
					effect = spr;
			});

			ghostChar.characterSprites.forEach(function(spr:CharacterExtra)
			{
				ghostLayer.add(spr);
				if (daEffect == null || daEffect == '' || spr.thisSprite == daEffect)
					ghostEffect = spr;
			});

			ghostLayer.sort(PlayState.sortByZ);
		}

		reloadEffectImage();
		reloadEffectOptions();
		charLayer.sort(PlayState.sortByZ);
		ghostLayer.sort(PlayState.sortByZ);

		reloadBGs();
		updatePointerPos();
	}

	function loadChar(isDad:Bool, blahBlahBlah:Bool = true)
	{
		var i:Int = charLayer.members.length - 1;
		while (i >= 0)
		{
			var memb:Dynamic = charLayer.members[i];
			if (memb != null)
			{
				memb.kill();
				charLayer.remove(memb);
				memb.destroy();
			}
			--i;
		}
		charLayer.clear();
		// Combat change
		var i:Int = ghostLayer.members.length - 1;
		while (i >= 0)
		{
			var memb:Dynamic = ghostLayer.members[i];
			if (memb != null)
			{
				memb.kill();
				ghostLayer.remove(memb);
				memb.destroy();
			}
			--i;
		}
		ghostLayer.clear();
		// End of changes
		ghostChar = new Character(0, 0, daAnim, !isDad);
		ghostChar.debugMode = true;
		// Combat change
		ghostLayer.alpha = 0.6;

		char = new Character(0, 0, daAnim, !isDad);
		// Combat change
		// Placed here since, effects in general being deeply tied to the character playing their animation,
		// Just a lot simpler to load the effect ASAP before the char plays an animation
		loadEffect();
		// End of change
		if (char.animationsArray[0] != null)
		{
			char.playAnim(char.animationsArray[0].anim, true);
		}
		char.debugMode = true;

		// Combat change
		// charLayer.add(ghostChar);
		ghostLayer.add(ghostChar);
		charLayer.add(char);

		// Combat change
		// char.setPosition(char.positionArray[0] + OFFSET_X + 100, char.positionArray[1]);
		charLayer.setPosition(char.positionArray[0] + OFFSET_X + 100, char.positionArray[1]);

		/* THIS FUNCTION WAS USED TO PUT THE .TXT OFFSETS INTO THE .JSON

			for (anim => offset in char.animOffsets) {
				var leAnim:AnimArray = findAnimationByName(anim);
				if(leAnim != null) {
					leAnim.offsets = [offset[0], offset[1]];
				}
		}*/

		if (blahBlahBlah)
		{
			genBoyOffsets();
		}
		reloadCharacterOptions();
		reloadBGs();
		updatePointerPos();
	}

	function updatePointerPos()
	{
		var x:Float = char.getMidpoint().x;
		var y:Float = char.getMidpoint().y;
		if (!char.isPlayer)
		{
			x += 150 + char.cameraPosition[0];
		}
		else
		{
			x -= 100 + char.cameraPosition[0];
		}
		y -= 100 - char.cameraPosition[1];

		x -= cameraFollowPointer.width / 2;
		y -= cameraFollowPointer.height / 2;
		cameraFollowPointer.setPosition(x, y);
	}

	function findAnimationByName(name:String):AnimArray
	{
		for (anim in char.animationsArray)
		{
			if (anim.anim == name)
			{
				return anim;
			}
		}
		return null;
	}

	function reloadCharacterOptions()
	{
		if (UI_characterbox != null)
		{
			imageInputText.text = char.imageFile;
			healthIconInputText.text = char.healthIcon;
			singDurationStepper.value = char.singDuration;
			scaleStepper.value = char.jsonScale;
			flipXCheckBox.checked = char.originalFlipX;
			noAntialiasingCheckBox.checked = char.noAntialiasing;
			resetHealthBarColor();
			leHealthIcon.changeIcon(healthIconInputText.text);
			positionXStepper.value = char.positionArray[0];
			positionYStepper.value = char.positionArray[1];
			positionCameraXStepper.value = char.cameraPosition[0];
			positionCameraYStepper.value = char.cameraPosition[1];
			reloadAnimationDropDown();
			updatePresence();
		}
	}

	// Combat change
	function reloadEffectOptions()
	{
		if (UI_characterbox != null)
		{
			if (effect != null)
			{
				effectImageInputText.text = effect.imageFile;
				effectScaleStepper.value = effect.jsonScale;
				effectFlipXCheckBox.checked = effect.originalFlipX;
				effectNoAntialiasingCheckBox.checked = effect.noAntialiasing;
				daEffect = effect.thisSprite;
				effectGeneralOffsetX.value = effect.generalOffset[0];
				effectGeneralOffsetY.value = effect.generalOffset[1];
			}
			else
			{
				effectImageInputText.text = '';
				effectScaleStepper.value = 1;
				effectFlipXCheckBox.checked = false;
				effectNoAntialiasingCheckBox.checked = false;
				daEffect = '';
				effectGeneralOffsetX.value = 0;
				effectGeneralOffsetY.value = 0;
			}
			reloadCallbackDropDown();
			reloadEffectDropDown();
			reloadEffectAnimationDropDown();
		}
	}

	// Combat change
	function reloadCallbackDropDown()
	{
		finishCallbackDropDown.setData(FlxUIDropDownMenuCustom.makeStrIdLabelArray(CharacterExtra.validCallbacks, true));
		finishCallbackDropDown.selectedLabel = daEffectCallback;
	}

	// Combat change
	function reloadEffectDropDown()
	{
		var sprites:Array<String> = [];
		if (effect != null)
			for (spr in char.characterSprites.members)
			{
				sprites.push(spr.thisSprite);
			}
		if (sprites.length < 1)
			sprites.push('NO EFFECTS'); // Prevents crash

		selectedEffectDropDown.setData(FlxUIDropDownMenuCustom.makeStrIdLabelArray(sprites, true));
		selectedEffectDropDown.selectedLabel = daEffect;
	}

	// Combat change
	function reloadEffectAnimationDropDown()
	{
		var anims:Array<String> = [];
		if (effect != null)
			for (anim in effect.animationsArray)
			{
				anims.push(anim.anim);
			}
		if (anims.length < 1)
			anims.push('NO ANIMATIONS'); // Prevents crash

		effectAnimationDropDown.setData(FlxUIDropDownMenuCustom.makeStrIdLabelArray(anims, true));
		if (effect != null && effect.animation.curAnim != null)
			effectAnimationDropDown.selectedLabel = effect.animation.curAnim.name;
	}

	function reloadAnimationDropDown()
	{
		var anims:Array<String> = [];
		var ghostAnims:Array<String> = [''];
		for (anim in char.animationsArray)
		{
			anims.push(anim.anim);
			ghostAnims.push(anim.anim);
		}
		if (anims.length < 1)
			anims.push('NO ANIMATIONS'); // Prevents crash

		animationDropDown.setData(FlxUIDropDownMenuCustom.makeStrIdLabelArray(anims, true));
		ghostDropDown.setData(FlxUIDropDownMenuCustom.makeStrIdLabelArray(ghostAnims, true));
		reloadGhost();
	}

	function reloadGhost()
	{
		ghostChar.frames = char.frames;
		for (anim in char.animationsArray)
		{
			var animAnim:String = '' + anim.anim;
			var animName:String = '' + anim.name;
			var animFps:Int = anim.fps;
			var animLoop:Bool = !!anim.loop; // Bruh
			var animIndices:Array<Int> = anim.indices;
			if (animIndices != null && animIndices.length > 0)
			{
				ghostChar.animation.addByIndices(animAnim, animName, animIndices, "", animFps, animLoop);
			}
			else
			{
				ghostChar.animation.addByPrefix(animAnim, animName, animFps, animLoop);
			}

			if (anim.offsets != null && anim.offsets.length > 1)
			{
				ghostChar.addOffset(anim.anim, anim.offsets[0], anim.offsets[1]);
			}
		}

		// Combat changes
		// char.alpha = 0.85;
		// ghostChar.visible = true;
		charLayer.alpha = 0.85;
		ghostLayer.visible = true;
		if (ghostDropDown.selectedLabel == '')
		{
			// ghostChar.visible = false;
			// char.alpha = 1;
			ghostLayer.visible = false;
			charLayer.alpha = 1;
		}
		// ghostChar.color = 0xFF666688;
		// End of changes
		ghostChar.antialiasing = char.antialiasing;
	}

	function reloadCharacterDropDown()
	{
		var charsLoaded:Map<String, Bool> = new Map();

		#if MODS_ALLOWED
		characterList = [];
		var directories:Array<String> = [
			Paths.mods('characters/'),
			Paths.mods(Paths.currentModDirectory + '/characters/'),
			Paths.getPreloadPath('characters/')
		];
		for (mod in Paths.getGlobalMods())
			directories.push(Paths.mods(mod + '/characters/'));
		for (i in 0...directories.length)
		{
			var directory:String = directories[i];
			if (FileSystem.exists(directory))
			{
				for (file in FileSystem.readDirectory(directory))
				{
					var path = haxe.io.Path.join([directory, file]);
					if (!sys.FileSystem.isDirectory(path) && file.endsWith('.json'))
					{
						var charToCheck:String = file.substr(0, file.length - 5);
						if (!charsLoaded.exists(charToCheck))
						{
							characterList.push(charToCheck);
							charsLoaded.set(charToCheck, true);
						}
					}
				}
			}
		}
		#else
		characterList = CoolUtil.coolTextFile(Paths.txt('characterList'));
		#end

		charDropDown.setData(FlxUIDropDownMenuCustom.makeStrIdLabelArray(characterList, true));
		charDropDown.selectedLabel = daAnim;
	}

	function resetHealthBarColor()
	{
		healthColorStepperR.value = char.healthColorArray[0];
		healthColorStepperG.value = char.healthColorArray[1];
		healthColorStepperB.value = char.healthColorArray[2];
		healthBarBG.color = FlxColor.fromRGB(char.healthColorArray[0], char.healthColorArray[1], char.healthColorArray[2]);
	}

	function updatePresence()
	{
		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("Character Editor", "Character: " + daAnim, leHealthIcon.getCharacter());
		#end
	}

	override function update(elapsed:Float)
	{
		MusicBeatState.camBeat = FlxG.camera;
		if (char.animationsArray[curAnim] != null)
		{
			textAnim.text = char.animationsArray[curAnim].anim;

			var curAnim:FlxAnimation = char.animation.getByName(char.animationsArray[curAnim].anim);
			if (curAnim == null || curAnim.frames.length < 1)
			{
				textAnim.text += ' (ERROR!)';
			}
		}
		else
		{
			textAnim.text = '';
		}

		var inputTexts:Array<FlxUIInputText> = [
			animationInputText,
			imageInputText,
			healthIconInputText,
			animationNameInputText,
			animationIndicesInputText,
			// Combat changes
			effectImageInputText,
			effectAnimationInputText,
			effectAnimationNameInputText,
			effectAnimationIndicesInputText
		];
		for (i in 0...inputTexts.length)
		{
			if (inputTexts[i].hasFocus)
			{
				FlxG.sound.muteKeys = [];
				FlxG.sound.volumeDownKeys = [];
				FlxG.sound.volumeUpKeys = [];
				super.update(elapsed);
				return;
			}
		}
		FlxG.sound.muteKeys = TitleState.muteKeys;
		FlxG.sound.volumeDownKeys = TitleState.volumeDownKeys;
		FlxG.sound.volumeUpKeys = TitleState.volumeUpKeys;

		if (!charDropDown.dropPanel.visible)
		{
			if (FlxG.keys.justPressed.ESCAPE)
			{
				if (goToPlayState)
				{
					MusicBeatState.switchState(new PlayState());
				}
				else
				{
					MusicBeatState.switchState(new editors.MasterEditorMenu());
					FlxG.sound.playMusic(Paths.music('freakyMenu'));
				}
				FlxG.mouse.visible = false;
				return;
			}

			if (FlxG.keys.justPressed.R)
			{
				FlxG.camera.zoom = 1;
			}

			if (FlxG.keys.pressed.E && FlxG.camera.zoom < 3)
			{
				FlxG.camera.zoom += elapsed * FlxG.camera.zoom;
				if (FlxG.camera.zoom > 3)
					FlxG.camera.zoom = 3;
			}
			if (FlxG.keys.pressed.Q && FlxG.camera.zoom > 0.1)
			{
				FlxG.camera.zoom -= elapsed * FlxG.camera.zoom;
				if (FlxG.camera.zoom < 0.1)
					FlxG.camera.zoom = 0.1;
			}

			if (FlxG.keys.pressed.I || FlxG.keys.pressed.J || FlxG.keys.pressed.K || FlxG.keys.pressed.L)
			{
				var addToCam:Float = 500 * elapsed;
				if (FlxG.keys.pressed.SHIFT)
					addToCam *= 4;

				if (FlxG.keys.pressed.I)
					camFollow.y -= addToCam;
				else if (FlxG.keys.pressed.K)
					camFollow.y += addToCam;

				if (FlxG.keys.pressed.J)
					camFollow.x -= addToCam;
				else if (FlxG.keys.pressed.L)
					camFollow.x += addToCam;
			}

			if (char.animationsArray.length > 0)
			{
				if (FlxG.keys.justPressed.W)
				{
					curAnim -= 1;
				}

				if (FlxG.keys.justPressed.S)
				{
					curAnim += 1;
				}

				// Combat change
				if (FlxG.keys.justPressed.A)
				{
					curPage -= 1;
				}

				if (FlxG.keys.justPressed.D)
				{
					curPage += 1;
				}

				if (curPage < 0)
					curPage = textPages.members.length - 1;

				if (curPage >= textPages.members.length)
					curPage = 0;

				if (FlxG.keys.justPressed.A || FlxG.keys.justPressed.D)
				{
					genBoyOffsets();
					changePage();
				}

				if (selectedEffectAnimID < 0)
					selectedEffectAnimID = effect.animationsArray.length - 1;

				if (effect == null || curAnim >= effect.animationsArray.length)
					selectedEffectAnimID = 0;
				// End of changes

				if (curAnim < 0)
					curAnim = char.animationsArray.length - 1;

				if (curAnim >= char.animationsArray.length)
					curAnim = 0;

				if (FlxG.keys.justPressed.S || FlxG.keys.justPressed.W || FlxG.keys.justPressed.SPACE)
				{
					char.playAnim(char.animationsArray[curAnim].anim, true);
					// Combat change
					charLayer.sort(PlayState.sortByZ);
					ghostLayer.sort(PlayState.sortByZ);
					// End of changes
					genBoyOffsets();
				}
				if (FlxG.keys.justPressed.T)
				{
					char.animationsArray[curAnim].offsets = [0, 0];

					char.addOffset(char.animationsArray[curAnim].anim, char.animationsArray[curAnim].offsets[0], char.animationsArray[curAnim].offsets[1]);
					ghostChar.addOffset(char.animationsArray[curAnim].anim, char.animationsArray[curAnim].offsets[0], char.animationsArray[curAnim].offsets[1]);
					genBoyOffsets();
				}

				var controlArray:Array<Bool> = [
					FlxG.keys.justPressed.LEFT,
					FlxG.keys.justPressed.RIGHT,
					FlxG.keys.justPressed.UP,
					FlxG.keys.justPressed.DOWN
				];

				for (i in 0...controlArray.length)
				{
					if (controlArray[i])
					{
						var holdShift = FlxG.keys.pressed.SHIFT;
						var multiplier = 1;
						if (holdShift)
							multiplier = 10;

						var arrayVal = 0;
						if (i > 1)
							arrayVal = 1;

						var negaMult:Int = 1;
						if (i % 2 == 1)
							negaMult = -1;

						// Combat changes
						// Wrap these in the effectOffsetToggle and null checks, and add the page-switch check
						var checkEffectAnim:SpriteAnimArray = null;
						if (effect != null)
						{
							checkEffectAnim = effect.animationsArray[selectedEffectAnimID];
							for (anim in effect.animationsArray)
							{
								if (anim.anim == char.animationsArray[curAnim].anim)
									checkEffectAnim = anim;
							}
						}

						if (!effectOffsetToggle.checked || checkEffectAnim == null)
						{
							// Combat changes
							var pageCount:Int = 0;
							var canReturn:Bool = false;

							textPages.forEach(function(page:FlxTypedGroup<FlxText>)
							{
								page.forEach(function(txt:FlxText)
								{
									if (txt.text.startsWith(char.animationsArray[curAnim].anim))
									{
										curPage = pageCount;
										canReturn = true;
										return;
									}
								});

								if (canReturn)
									return;

								pageCount++;
							});
							// End of changes

							// If you're looking at the combat-change notations and this all looks confusing,
							// Remember that this whole char chunk was vanilla Psych
							char.animationsArray[curAnim].offsets[arrayVal] += negaMult * multiplier;

							char.addOffset(char.animationsArray[curAnim].anim, char.animationsArray[curAnim].offsets[0],
								char.animationsArray[curAnim].offsets[1]);
							ghostChar.addOffset(char.animationsArray[curAnim].anim, char.animationsArray[curAnim].offsets[0],
								char.animationsArray[curAnim].offsets[1]);

							char.playAnim(char.animationsArray[curAnim].anim, false);
							if (ghostChar.animation.curAnim != null
								&& char.animation.curAnim != null
								&& char.animation.curAnim.name == ghostChar.animation.curAnim.name)
							{
								ghostChar.playAnim(char.animation.curAnim.name, false);
							}
						}
							// Combat change
						// Just clarifying this page-switch bit to add
						else
						{
							var canBreak:Bool = false;
							for (i in effectPages)
							{
								textPages.members[i].forEach(function(txt:FlxText)
								{
									if (txt.text.startsWith(checkEffectAnim.anim))
									{
										curPage = i;
										canBreak = true;
										return;
									}
								});

								if (canBreak)
									break;
							}

							checkEffectAnim.offsets[arrayVal] += negaMult * multiplier;

							effect.addOffset(checkEffectAnim.anim, checkEffectAnim.offsets[0], checkEffectAnim.offsets[1]);
							ghostEffect.addOffset(checkEffectAnim.anim, checkEffectAnim.offsets[0], checkEffectAnim.offsets[1]);

							var curAnimInt:Int = 0;
							for (charAnim in char.animationsArray)
							{
								if (charAnim.anim == checkEffectAnim.anim)
								{
									curAnim = curAnimInt;
									break;
								}
								++curAnimInt;
							}

							char.playAnim(char.animationsArray[curAnim].anim, true);

							if (ghostEffect.animation.curAnim != null
								&& effect.animation.curAnim != null
								&& effect.animation.curAnim.name == ghostEffect.animation.curAnim.name)
							{
								ghostChar.playAnim(effect.animation.curAnim.name, false);
							}
						}
						// End of changes
						genBoyOffsets();
					}
				}
			}
		}
		// camMenu.zoom = FlxG.camera.zoom;
		// Combat change
		// ghostChar.setPosition(char.x, char.y);
		ghostLayer.setPosition(char.x, char.y);
		super.update(elapsed);
	}

	var _file:FileReference;

	/*private function saveOffsets()
		{
			var data:String = '';
			for (anim => offsets in char.animOffsets) {
				data += anim + ' ' + offsets[0] + ' ' + offsets[1] + '\n';
			}

			if (data.length > 0)
			{
				_file = new FileReference();
				_file.addEventListener(Event.COMPLETE, onSaveComplete);
				_file.addEventListener(Event.CANCEL, onSaveCancel);
				_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
				_file.save(data, daAnim + "Offsets.txt");
			}
	}*/
	function onSaveComplete(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.notice("Successfully saved file.");
	}

	/**
	 * Called when the save file dialog is cancelled.
	 */
	function onSaveCancel(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
	}

	/**
	 * Called if there is an error while saving the gameplay recording.
	 */
	function onSaveError(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.error("Problem saving file");
	}

	// Combat change
	function saveEffect()
	{
		var json = {
			"animations": effect.animationsArray,
			"image": effect.imageFile,
			"scale": effect.jsonScale,
			"global_offset": effect.generalOffset,

			"flip_x": effect.originalFlipX,
			"no_antialiasing": effect.noAntialiasing,
			"layer": effect.layer
		};

		var data:String = Json.stringify(json, "\t");

		if (data.length > 0)
		{
			_file = new FileReference();
			_file.addEventListener(Event.COMPLETE, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data, daEffect + ".json");
		}
	}

	function saveCharacter()
	{
		var json = {
			"animations": char.animationsArray,
			"image": char.imageFile,
			"scale": char.jsonScale,
			"sing_duration": char.singDuration,
			"healthicon": char.healthIcon,

			"position": char.positionArray,
			"camera_position": char.cameraPosition,

			"flip_x": char.originalFlipX,
			"no_antialiasing": char.noAntialiasing,
			"healthbar_colors": char.healthColorArray
		};

		var data:String = Json.stringify(json, "\t");

		if (data.length > 0)
		{
			_file = new FileReference();
			_file.addEventListener(Event.COMPLETE, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data, daAnim + ".json");
		}
	}

	function ClipboardAdd(prefix:String = ''):String
	{
		if (prefix.toLowerCase().endsWith('v')) // probably copy paste attempt
		{
			prefix = prefix.substring(0, prefix.length - 1);
		}

		var text:String = prefix + Clipboard.text.replace('\n', '');
		return text;
	}
}
