package states.editors;

import flixel.graphics.FlxGraphic;
import flixel.system.debug.interaction.tools.Pointer.GraphicCursorCross;
import flixel.util.FlxDestroyUtil;
import forfriday.CharacterExtra;
import haxe.Json;
import objects.Bar;
import objects.Character;
import objects.HealthIcon;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.geom.Matrix;
import openfl.net.FileReference;
import openfl.utils.Assets;
import states.editors.content.Prompt;
import states.editors.content.PsychJsonPrinter;

class CharacterEditorState extends MusicBeatState implements PsychUIEventHandler.PsychUIEvent
{
	// Combat changes
	var characterGroup:FlxSpriteGroup = new FlxSpriteGroup();
	var ghostGroup:FlxSpriteGroup = new FlxSpriteGroup();

	var curEffect:Null<CharacterExtra>;
	var curAttack:Null<AttackData>;
	var curChain:Null<ChainData>;

	var attacks:Array<AttackData> = [];
	var chains:Array<ChainData> = [];
	var chainProgress:Int = 0;
	var curChainNum:Int = 0;
	var tempDirectionArray:Array<String> = ['NONE'];

	var currentEditMode:String = 'character';
	var previousUICharacterBoxTab:String = '';

	var textPages:Array<String>;
	var curPage:Int = 0;

	var labelMap:Map<Int, String> = new Map<Int, String>();
	var labelTabMap:Map<Int, String> = new Map<Int, String>();
	var labelledTextGroup:FlxTypedGroup<FlxText> = new FlxTypedGroup<FlxText>();

	var hoverElapsed:Float = 0;

	var labelBackground:FlxSprite;
	var labelText:FlxText;
	// End of changes
	var character:Character;

	var ghost:FlxSprite;
	var animateGhost:FlxAnimate;
	var animateGhostImage:String;
	var cameraFollowPointer:FlxSprite;
	var isAnimateSprite:Bool = false;

	var silhouettes:FlxSpriteGroup;
	var dadPosition = FlxPoint.weak();
	var bfPosition = FlxPoint.weak();

	var helpBg:FlxSprite;
	var helpTexts:FlxSpriteGroup;
	var cameraZoomText:FlxText;
	var frameAdvanceText:FlxText;

	var healthBar:Bar;
	var healthIcon:HealthIcon;

	var copiedOffset:Array<Float> = [0, 0];
	var _char:String = null;
	var _goToPlayState:Bool = true;

	// Combat change
	// var anims = null;
	var anims:Array<Dynamic> = null;
	// End of change
	var animsTxt:FlxText;
	var curAnim = 0;

	private var camEditor:FlxCamera;
	private var camHUD:FlxCamera;

	var UI_box:PsychUIBox;
	var UI_characterbox:PsychUIBox;

	var unsavedProgress:Bool = false;

	var selectedFormat:FlxTextFormat = new FlxTextFormat(FlxColor.LIME);

	public function new(char:String = null, goToPlayState:Bool = true)
	{
		this._char = char;
		this._goToPlayState = goToPlayState;
		if (this._char == null)
			this._char = Character.DEFAULT_CHARACTER;

		super();
	}

	override function create()
	{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		FlxG.sound.music.stop();
		camEditor = initPsychCamera();

		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		FlxG.cameras.add(camHUD, false);

		loadBG();

		silhouettes = new FlxSpriteGroup();
		add(silhouettes);

		var dad:FlxSprite = new FlxSprite(dadPosition.x, dadPosition.y).loadGraphic(Paths.image('editors/silhouetteDad'));
		dad.antialiasing = ClientPrefs.data.antialiasing;
		dad.active = false;
		dad.offset.set(-4, 1);
		silhouettes.add(dad);

		var boyfriend:FlxSprite = new FlxSprite(bfPosition.x, bfPosition.y + 350).loadGraphic(Paths.image('editors/silhouetteBF'));
		boyfriend.antialiasing = ClientPrefs.data.antialiasing;
		boyfriend.active = false;
		boyfriend.offset.set(-6, 2);
		silhouettes.add(boyfriend);

		silhouettes.alpha = 0.25;

		ghost = new FlxSprite();
		ghost.visible = false;
		ghost.alpha = ghostAlpha;
		add(ghost);

		animsTxt = new FlxText(10, 32, 400, '');
		animsTxt.setFormat(null, 16, FlxColor.WHITE, LEFT, OUTLINE_FAST, FlxColor.BLACK);
		animsTxt.scrollFactor.set();
		animsTxt.borderSize = 1;
		animsTxt.cameras = [camHUD];

		addCharacter();

		cameraFollowPointer = new FlxSprite().loadGraphic(FlxGraphic.fromClass(GraphicCursorCross));
		cameraFollowPointer.setGraphicSize(40, 40);
		cameraFollowPointer.updateHitbox();

		healthBar = new Bar(30, FlxG.height - 75);
		healthBar.scrollFactor.set();
		healthBar.cameras = [camHUD];

		healthIcon = new HealthIcon(character.healthIcon, false, false);
		healthIcon.y = FlxG.height - 150;
		healthIcon.cameras = [camHUD];

		add(cameraFollowPointer);
		add(healthBar);
		add(healthIcon);
		add(animsTxt);

		var tipText:FlxText = new FlxText(FlxG.width - 300, FlxG.height - 24, 300, "Press F1 for Help", 20);
		tipText.cameras = [camHUD];
		tipText.setFormat(null, 16, FlxColor.WHITE, RIGHT, OUTLINE_FAST, FlxColor.BLACK);
		tipText.borderColor = FlxColor.BLACK;
		tipText.scrollFactor.set();
		tipText.borderSize = 1;
		tipText.active = false;
		add(tipText);

		cameraZoomText = new FlxText(0, 50, 200, 'Zoom: 1x');
		cameraZoomText.setFormat(null, 16, FlxColor.WHITE, CENTER, OUTLINE_FAST, FlxColor.BLACK);
		cameraZoomText.scrollFactor.set();
		cameraZoomText.borderSize = 1;
		cameraZoomText.screenCenter(X);
		cameraZoomText.cameras = [camHUD];
		add(cameraZoomText);

		frameAdvanceText = new FlxText(0, 75, 350, '');
		frameAdvanceText.setFormat(null, 16, FlxColor.WHITE, CENTER, OUTLINE_FAST, FlxColor.BLACK);
		frameAdvanceText.scrollFactor.set();
		frameAdvanceText.borderSize = 1;
		frameAdvanceText.screenCenter(X);
		frameAdvanceText.cameras = [camHUD];
		add(frameAdvanceText);

		addHelpScreen();
		FlxG.mouse.visible = true;
		FlxG.camera.zoom = 1;

		makeUIMenu();

		updatePointerPos();
		updateHealthBar();
		character.finishAnimation();

		if (ClientPrefs.data.cacheOnGPU)
			Paths.clearUnusedMemory();

		// Combat change
		setupLabelSystem();
		// End of change

		super.create();
	}

	function addHelpScreen()
	{
		var str:Array<String> = [
			"CAMERA",
			"E/Q - Camera Zoom In/Out",
			"J/K/L/I - Move Camera",
			"R - Reset Camera Zoom",
			"",
			"CHARACTER",
			"Ctrl + R - Reset Current Offset",
			"Ctrl + C - Copy Current Offset",
			"Ctrl + V - Paste Copied Offset on Current Animation",
			"Ctrl + Z - Undo Last Paste or Reset",
			"W/S - Previous/Next Animation",
			"Space - Replay Animation",
			"Arrow Keys/Mouse & Right Click - Move Offset",
			"A/D - Frame Advance (Back/Forward)",
			"",
			"OTHER",
			"F12 - Toggle Silhouettes",
			// Combat change
			// "Hold Shift - Move Offsets 10x faster and Camera 4x faster",
			// "Hold Control - Move camera 4x slower"
			"Hold Shift - Move Offsets 10x faster and Camera, Anims, and Attacks 4x faster",
			"Hold Control - Move camera 4x slower and Flip Anims/Attacks by page" // End of change
		];

		helpBg = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		helpBg.scale.set(FlxG.width, FlxG.height);
		helpBg.updateHitbox();
		helpBg.alpha = 0.6;
		helpBg.cameras = [camHUD];
		helpBg.active = helpBg.visible = false;
		add(helpBg);

		helpTexts = new FlxSpriteGroup();
		helpTexts.cameras = [camHUD];
		for (i => txt in str)
		{
			if (txt.length < 1)
				continue;

			// Combat change
			// var helpText:FlxText = new FlxText(0, 0, 600, txt, 16);
			var helpText:FlxText = new FlxText(0, 0, 1500, txt, 16);
			// End of change
			helpText.setFormat(null, 16, FlxColor.WHITE, CENTER, OUTLINE_FAST, FlxColor.BLACK);
			helpText.borderColor = FlxColor.BLACK;
			helpText.scrollFactor.set();
			helpText.borderSize = 1;
			helpText.screenCenter();
			add(helpText);
			helpText.y += ((i - str.length / 2) * 32) + 16;
			helpText.active = false;
			helpTexts.add(helpText);
		}
		helpTexts.active = helpTexts.visible = false;
		add(helpTexts);
	}

	function addCharacter(reload:Bool = false)
	{
		var pos:Int = -1;
		if (character != null)
		{
			pos = members.indexOf(character);
			// Combat change
			// remove(character);
			remove(characterGroup);
			// End of change
			character.destroy();
		}

		var isPlayer = (reload ? character.isPlayer : !predictCharacterIsNotPlayer(_char));
		character = new Character(0, 0, _char, isPlayer);
		if (!reload && character.editorIsPlayer != null && isPlayer != character.editorIsPlayer)
		{
			character.isPlayer = !character.isPlayer;
			character.flipX = (character.originalFlipX != character.isPlayer);
			if (check_player != null)
				check_player.checked = character.isPlayer;
		}
		character.debugMode = true;
		character.missingCharacter = false;

		// Combat change
		/*
			if (pos > -1)
				insert(pos, character);
			else
				add(character);
		 */
		if (pos > -1)
			insert(pos, characterGroup);
		else
			add(characterGroup);

		addCharacterExtras();
		fillCombatData();
		// End of change
		updateCharacterPositions();
		reloadAnimList();
		if (healthBar != null && healthIcon != null)
			updateHealthBar();
	}

	function makeUIMenu()
	{
		// Combat change
		// UI_box = new PsychUIBox(FlxG.width - 275, 25, 250, 120, ['Ghost', 'Settings']);
		UI_box = new PsychUIBox(FlxG.width - 275, 25, 250, 120, ['Ghost', 'Settings']);
		// End of change
		UI_box.scrollFactor.set();
		UI_box.cameras = [camHUD];

		// Combat change
		// UI_characterbox = new PsychUIBox(UI_box.x - 100, UI_box.y + UI_box.height + 10, 350, 280, ['Animations', 'Character']);
		UI_characterbox = new PsychUIBox(UI_box.x - 100, UI_box.y + UI_box.height + 10, 350, 280,
			['Animations', 'Character', 'Effect Anim', 'Effect', 'Attacks']);
		UI_characterbox.scrollFactor.set();
		UI_characterbox.cameras = [camHUD];
		add(UI_characterbox);
		add(UI_box);

		addGhostUI();
		addSettingsUI();
		addAnimationsUI();
		addCharacterUI();
		// Combat change
		addEffectAnimUI();
		addEffectUI();
		addAttackUI();
		// End of change

		UI_box.selectedName = 'Settings';
		UI_characterbox.selectedName = 'Character';
	}

	var ghostAlpha:Float = 0.6;

	function addGhostUI()
	{
		var tab_group = UI_box.getTab('Ghost').menu;

		// var hideGhostButton:PsychUIButton = null;
		var makeGhostButton:PsychUIButton = new PsychUIButton(25, 15, "Make Ghost", function()
		{
			// Combat change
			anims = character.animationsArray;
			// End of change

			var anim = anims[curAnim];
			if (!character.isAnimationNull())
			{
				var myAnim = anims[curAnim];
				if (!character.isAnimateAtlas)
				{
					// Combat change
					/*
						ghost.loadGraphic(character.graphic);
						ghost.frames.frames = character.frames.frames;
						ghost.animation.copyFrom(character.animation);
						ghost.animation.play(character.animation.curAnim.name, true, false, character.animation.curAnim.curFrame);
						ghost.animation.pause();
					 */
					var characterExtraIsVisible = false;
					for (member in characterGroup)
					{
						if (member.visible && Std.isOfType(member, CharacterExtra))
						{
							characterExtraIsVisible = true;
							break;
						}
					}

					if (characterExtraIsVisible)
					{
						var farthestLeftPoint:Int = 0;
						var farthestRightPoint:Int = 0;
						var farthestTopPoint:Int = 0;
						var farthestBottomPoint:Int = 0;

						characterGroup.sort(PlayState.sortByZ);

						for (member in characterGroup)
						{
							if (!member.visible)
								continue;

							if (member.x < farthestLeftPoint || farthestLeftPoint == 0)
								farthestLeftPoint = Std.int(member.x);
							if (member.x + member.frameWidth > farthestRightPoint || farthestRightPoint == 0)
								farthestRightPoint = Std.int(member.x + member.frameWidth);
							if (member.y < farthestTopPoint || farthestTopPoint == 0)
								farthestTopPoint = Std.int(member.y);
							if (member.y + member.frameHeight > farthestBottomPoint || farthestBottomPoint == 0)
								farthestBottomPoint = Std.int(member.y + member.frameHeight);
						}

						var newWidth:Int = farthestRightPoint - farthestLeftPoint;
						var newHeight:Int = farthestBottomPoint - farthestTopPoint;

						// loadGraphic doesn't let you change the width/height of the original image
						// So the bitmap needs to get created and sorted out first
						var ghostBitmap:BitmapData = new BitmapData(newWidth, newHeight, true, 0);

						for (member in characterGroup)
						{
							if (!member.visible)
								continue;

							member.drawFrame();
							ghostBitmap.draw(member.framePixels);
						}

						ghost.loadGraphic(ghostBitmap, false, 0, 0, true);

						var offset = character.animOffsets.get(character.animation.curAnim.name);
						ghost.x += offset[0];
						ghost.y += offset[1];
					}
					else
					{
						character.drawFrame();
						ghost.loadGraphic(character.framePixels);
					}
					// End of change
				}
				else
					if (myAnim != null) // This is VERY unoptimized and bad, I hope to find a better replacement that loads only a specific frame as bitmap in the future.
				{
					if (animateGhost == null) // If I created the animateGhost on create() and you didn't load an atlas, it would crash the game on destroy, so we create it here
					{
						animateGhost = new FlxAnimate(ghost.x, ghost.y);
						animateGhost.showPivot = false;
						insert(members.indexOf(ghost), animateGhost);
						animateGhost.active = false;
					}

					if (animateGhost == null || animateGhostImage != character.imageFile)
						Paths.loadAnimateAtlas(animateGhost, character.imageFile);

					if (myAnim.indices != null && myAnim.indices.length > 0)
						animateGhost.anim.addBySymbolIndices('anim', myAnim.name, myAnim.indices, 0, false);
					else
						animateGhost.anim.addBySymbol('anim', myAnim.name, 0, false);

					animateGhost.anim.play('anim', true, false, character.atlas.anim.curFrame);
					animateGhost.anim.pause();

					animateGhostImage = character.imageFile;
				}

				var spr:FlxSprite = !character.isAnimateAtlas ? ghost : animateGhost;
				if (spr != null)
				{
					spr.setPosition(character.x, character.y);
					spr.antialiasing = character.antialiasing;
					spr.flipX = character.flipX;
					spr.alpha = ghostAlpha;

					spr.scale.set(character.scale.x, character.scale.y);
					spr.updateHitbox();

					spr.offset.set(character.offset.x, character.offset.y);
					spr.visible = true;

					var otherSpr:FlxSprite = (spr == animateGhost) ? ghost : animateGhost;
					if (otherSpr != null)
						otherSpr.visible = false;
				}
				/*hideGhostButton.active = true;
					hideGhostButton.alpha = 1; */
				trace('created ghost image');
			}

			// Combat change
			currentEditMode = determineCurrentEditMode();
			reloadAnimList();
			// End of change
		});

		/*hideGhostButton = new PsychUIButton(20 + makeGhostButton.width, makeGhostButton.y, "Hide Ghost", function() {
				ghost.visible = false;
				hideGhostButton.active = false;
				hideGhostButton.alpha = 0.6;
			});
			hideGhostButton.active = false;
			hideGhostButton.alpha = 0.6; */

		var highlightGhost:PsychUICheckBox = new PsychUICheckBox(20 + makeGhostButton.x + makeGhostButton.width, makeGhostButton.y, "Highlight Ghost", 100);
		highlightGhost.onClick = function()
		{
			var value = highlightGhost.checked ? 125 : 0;
			ghost.colorTransform.redOffset = value;
			ghost.colorTransform.greenOffset = value;
			ghost.colorTransform.blueOffset = value;
			if (animateGhost != null)
			{
				animateGhost.colorTransform.redOffset = value;
				animateGhost.colorTransform.greenOffset = value;
				animateGhost.colorTransform.blueOffset = value;
			}
		};

		var ghostAlphaSlider:PsychUISlider = new PsychUISlider(15, makeGhostButton.y + 25, function(v:Float)
		{
			ghostAlpha = v;
			ghost.alpha = ghostAlpha;
			if (animateGhost != null)
				animateGhost.alpha = ghostAlpha;
		}, ghostAlpha, 0, 1);
		ghostAlphaSlider.label = 'Opacity:';

		tab_group.add(makeGhostButton);
		// tab_group.add(hideGhostButton);
		tab_group.add(highlightGhost);
		tab_group.add(ghostAlphaSlider);
	}

	var check_player:PsychUICheckBox;
	var charDropDown:PsychUIDropDownMenu;

	function addSettingsUI()
	{
		var tab_group = UI_box.getTab('Settings').menu;

		check_player = new PsychUICheckBox(10, 60, "Playable Character", 100);
		check_player.checked = character.isPlayer;
		check_player.onClick = function()
		{
			character.isPlayer = !character.isPlayer;
			character.flipX = !character.flipX;
			updateCharacterPositions();
			updatePointerPos(false);
		};

		var reloadCharacter:PsychUIButton = new PsychUIButton(140, 20, "Reload Char", function()
		{
			addCharacter(true);
			updatePointerPos();
			reloadCharacterOptions();
			reloadCharacterDropDown();
			if (currentEditMode == 'attack')
			{
				curAnim = 0;
				assignAttackData(curAttack, attacks[0]);
				fillTempDirectionArray();
				animateAttack(true);
				updateAttackText();
				updateAttackOptions();
			}
		});

		var templateCharacter:PsychUIButton = new PsychUIButton(140, 50, "Load Template", function()
		{
			final _template:CharacterFile = {
				animations: [
					newAnim('idle', 'BF idle dance'),
					newAnim('singLEFT', 'BF NOTE LEFT0'),
					newAnim('singDOWN', 'BF NOTE DOWN0'),
					newAnim('singUP', 'BF NOTE UP0'),
					newAnim('singRIGHT', 'BF NOTE RIGHT0')
				],
				no_antialiasing: false,
				flip_x: false,
				healthicon: 'face',
				image: 'characters/BOYFRIEND',
				sing_duration: 4,
				scale: 1,
				healthbar_colors: [161, 161, 161],
				camera_position: [0, 0],
				position: [0, 0],
				vocals_file: null,
				// Combat change
				combat_data: null
				// End of change
			};

			character.loadCharacterFile(_template);
			character.missingCharacter = false;
			character.color = FlxColor.WHITE;
			character.alpha = 1;
			reloadAnimList();
			reloadCharacterOptions();
			updateCharacterPositions();
			updatePointerPos();
			reloadCharacterDropDown();
			updateHealthBar();
		});
		templateCharacter.normalStyle.bgColor = FlxColor.RED;
		templateCharacter.normalStyle.textColor = FlxColor.WHITE;

		charDropDown = new PsychUIDropDownMenu(10, 30, [''], function(index:Int, intended:String)
		{
			if (intended == null || intended.length < 1)
				return;

			var characterPath:String = 'characters/$intended.json';
			var path:String = Paths.getPath(characterPath, TEXT, null, true);
			#if MODS_ALLOWED
			if (FileSystem.exists(path))
			#else
			if (Assets.exists(path))
			#end
			{
				_char = intended;
				check_player.checked = character.isPlayer;
				addCharacter();
				reloadCharacterOptions();
				reloadCharacterDropDown();
				updatePointerPos();

				// Combat change
				reloadEffectDropDown();

				if (currentEditMode == 'attack')
				{
					curAnim = 0;
					assignAttackData(curAttack, attacks[0]);
					fillTempDirectionArray();
					animateAttack(true);
					updateAttackText();
					updateAttackOptions();
				}
				// End of change
			}
		else
		{
			reloadCharacterDropDown();
			FlxG.sound.play(Paths.sound('cancelMenu'));
		}
		});
		reloadCharacterDropDown();
		charDropDown.selectedLabel = _char;

		tab_group.add(new FlxText(charDropDown.x, charDropDown.y - 18, 80, 'Character:'));
		tab_group.add(check_player);
		tab_group.add(reloadCharacter);
		tab_group.add(templateCharacter);
		tab_group.add(charDropDown);
	}

	var animationDropDown:PsychUIDropDownMenu;
	var animationInputText:PsychUIInputText;
	var animationNameInputText:PsychUIInputText;
	var animationIndicesInputText:PsychUIInputText;
	var animationFramerate:PsychUINumericStepper;
	var animationLoopCheckBox:PsychUICheckBox;

	function addAnimationsUI()
	{
		var tab_group = UI_characterbox.getTab('Animations').menu;

		animationInputText = new PsychUIInputText(15, 85, 80, '', 8);
		animationNameInputText = new PsychUIInputText(animationInputText.x, animationInputText.y + 35, 150, '', 8);
		animationIndicesInputText = new PsychUIInputText(animationNameInputText.x, animationNameInputText.y + 40, 250, '', 8);
		animationFramerate = new PsychUINumericStepper(animationInputText.x + 170, animationInputText.y, 1, 24, 0, 240, 0);
		// Combat change
		// animationLoopCheckBox = new PsychUICheckBox(animationNameInputText.x + 170, animationNameInputText.y - 1, "Should it Loop?", 100);
		animationLoopCheckBox = new PsychUICheckBox(animationNameInputText.x + 170, animationNameInputText.y - 1, "Should it Loop?", 100, function()
		{
			character.animation.curAnim.looped = animationLoopCheckBox.checked;
		});
		// End of change

		animationDropDown = new PsychUIDropDownMenu(15, animationInputText.y - 55, [''], function(selectedAnimation:Int, pressed:String)
		{
			var anim:AnimArray = character.animationsArray[selectedAnimation];
			animationInputText.text = anim.anim;
			animationNameInputText.text = anim.name;
			animationLoopCheckBox.checked = anim.loop;
			animationFramerate.value = anim.fps;

			var indicesStr:String = anim.indices.toString();
			animationIndicesInputText.text = indicesStr.substr(1, indicesStr.length - 2);

			// Combat change
			updateCurAnim(selectedAnimation);
			// End of change
		});

		var addUpdateButton:PsychUIButton = new PsychUIButton(70, animationIndicesInputText.y + 60, "Add/Update", function()
		{
			var indicesText:String = animationIndicesInputText.text.trim();
			var indices:Array<Int> = [];
			if (indicesText.length > 0)
			{
				var indicesStr:Array<String> = animationIndicesInputText.text.trim().split(',');
				if (indicesStr.length > 0)
				{
					for (ind in indicesStr)
					{
						if (ind.contains('-'))
						{
							var splitIndices:Array<String> = ind.split('-');
							var indexStart:Int = Std.parseInt(splitIndices[0]);
							if (Math.isNaN(indexStart) || indexStart < 0)
								indexStart = 0;

							var indexEnd:Int = Std.parseInt(splitIndices[1]);
							if (Math.isNaN(indexEnd) || indexEnd < indexStart)
								indexEnd = indexStart;

							for (index in indexStart...indexEnd + 1)
								indices.push(index);
						}
						else
						{
							var index:Int = Std.parseInt(ind);
							if (!Math.isNaN(index) && index > -1)
								indices.push(index);
						}
					}
				}
			}

			var lastAnim:String = (character.animationsArray[curAnim] != null) ? character.animationsArray[curAnim].anim : '';
			var lastOffsets:Array<Int> = [0, 0];
			for (anim in character.animationsArray)
				if (animationInputText.text == anim.anim)
				{
					lastOffsets = anim.offsets;
					if (character.hasAnimation(animationInputText.text))
					{
						if (!character.isAnimateAtlas)
							character.animation.remove(animationInputText.text);
						else
							@:privateAccess character.atlas.anim.animsMap.remove(animationInputText.text);
					}
					character.animationsArray.remove(anim);
				}

			var addedAnim:AnimArray = newAnim(animationInputText.text, animationNameInputText.text);
			addedAnim.fps = Math.round(animationFramerate.value);
			addedAnim.loop = animationLoopCheckBox.checked;
			addedAnim.indices = indices;
			addedAnim.offsets = lastOffsets;
			addAnimation(addedAnim.anim, addedAnim.name, addedAnim.fps, addedAnim.loop, addedAnim.indices);
			character.animationsArray.push(addedAnim);

			reloadAnimList();
			@:arrayAccess curAnim = Std.int(Math.max(0, character.animationsArray.indexOf(addedAnim)));
			character.playAnim(addedAnim.anim, true);
			trace('Added/Updated animation: ' + animationInputText.text);
		});

		var removeButton:PsychUIButton = new PsychUIButton(180, animationIndicesInputText.y + 60, "Remove", function()
		{
			for (anim in character.animationsArray)
				if (animationInputText.text == anim.anim)
				{
					var resetAnim:Bool = false;
					if (anim.anim == character.getAnimationName())
						resetAnim = true;
					if (character.hasAnimation(anim.anim))
					{
						if (!character.isAnimateAtlas)
							character.animation.remove(anim.anim);
						else
							@:privateAccess character.atlas.anim.animsMap.remove(anim.anim);
						character.animOffsets.remove(anim.anim);
						character.animationsArray.remove(anim);
					}

					if (resetAnim && character.animationsArray.length > 0)
					{
						curAnim = FlxMath.wrap(curAnim, 0, anims.length - 1);
						character.playAnim(anims[curAnim].anim, true);
					}
					reloadAnimList();
					trace('Removed animation: ' + animationInputText.text);
					break;
				}
		});
		reloadAnimList();
		animationDropDown.selectedLabel = anims[0] != null ? anims[0].anim : '';

		tab_group.add(new FlxText(animationDropDown.x, animationDropDown.y - 18, 100, 'Animations:'));
		tab_group.add(new FlxText(animationInputText.x, animationInputText.y - 18, 100, 'Animation name:'));
		tab_group.add(new FlxText(animationFramerate.x, animationFramerate.y - 18, 100, 'Framerate:'));
		tab_group.add(new FlxText(animationNameInputText.x, animationNameInputText.y - 18, 150, 'Animation Symbol Name/Tag:'));
		tab_group.add(new FlxText(animationIndicesInputText.x, animationIndicesInputText.y - 18, 170, 'ADVANCED - Animation Indices:'));

		tab_group.add(animationInputText);
		tab_group.add(animationNameInputText);
		tab_group.add(animationIndicesInputText);
		tab_group.add(animationFramerate);
		tab_group.add(animationLoopCheckBox);
		tab_group.add(addUpdateButton);
		tab_group.add(removeButton);
		tab_group.add(animationDropDown);
	}

	var imageInputText:PsychUIInputText;
	var healthIconInputText:PsychUIInputText;
	var vocalsInputText:PsychUIInputText;

	var singDurationStepper:PsychUINumericStepper;
	var scaleStepper:PsychUINumericStepper;
	var positionXStepper:PsychUINumericStepper;
	var positionYStepper:PsychUINumericStepper;
	var positionCameraXStepper:PsychUINumericStepper;
	var positionCameraYStepper:PsychUINumericStepper;

	var flipXCheckBox:PsychUICheckBox;
	var noAntialiasingCheckBox:PsychUICheckBox;

	var healthColorStepperR:PsychUINumericStepper;
	var healthColorStepperG:PsychUINumericStepper;
	var healthColorStepperB:PsychUINumericStepper;

	function addCharacterUI()
	{
		var tab_group = UI_characterbox.getTab('Character').menu;

		imageInputText = new PsychUIInputText(15, 30, 200, character.imageFile, 8);
		var reloadImage:PsychUIButton = new PsychUIButton(imageInputText.x + 210, imageInputText.y - 3, "Reload Image", function()
		{
			var lastAnim = character.getAnimationName();
			character.imageFile = imageInputText.text;
			reloadCharacterImage();
			if (!character.isAnimationNull())
			{
				character.playAnim(lastAnim, true);
			}
		});

		var decideIconColor:PsychUIButton = new PsychUIButton(reloadImage.x, reloadImage.y + 30, "Get Icon Color", function()
		{
			var coolColor:FlxColor = FlxColor.fromInt(CoolUtil.dominantColor(healthIcon));
			character.healthColorArray[0] = coolColor.red;
			character.healthColorArray[1] = coolColor.green;
			character.healthColorArray[2] = coolColor.blue;
			updateHealthBar();
		});

		healthIconInputText = new PsychUIInputText(15, imageInputText.y + 35, 75, healthIcon.getCharacter(), 8);

		vocalsInputText = new PsychUIInputText(15, healthIconInputText.y + 35, 75, character.vocalsFile != null ? character.vocalsFile : '', 8);

		singDurationStepper = new PsychUINumericStepper(15, vocalsInputText.y + 45, 0.1, 4, 0, 999, 1);

		scaleStepper = new PsychUINumericStepper(15, singDurationStepper.y + 40, 0.1, 1, 0.05, 10, 2);

		flipXCheckBox = new PsychUICheckBox(singDurationStepper.x + 80, singDurationStepper.y, "Flip X", 50);
		flipXCheckBox.checked = character.flipX;
		if (character.isPlayer)
			flipXCheckBox.checked = !flipXCheckBox.checked;
		flipXCheckBox.onClick = function()
		{
			character.originalFlipX = !character.originalFlipX;
			character.flipX = (character.originalFlipX != character.isPlayer);
		};

		noAntialiasingCheckBox = new PsychUICheckBox(flipXCheckBox.x, flipXCheckBox.y + 40, "No Antialiasing", 80);
		noAntialiasingCheckBox.checked = character.noAntialiasing;
		noAntialiasingCheckBox.onClick = function()
		{
			character.antialiasing = false;
			if (!noAntialiasingCheckBox.checked && ClientPrefs.data.antialiasing)
			{
				character.antialiasing = true;
			}
			character.noAntialiasing = noAntialiasingCheckBox.checked;
		};

		positionXStepper = new PsychUINumericStepper(flipXCheckBox.x + 110, flipXCheckBox.y, 10, character.positionArray[0], -9000, 9000, 0);
		positionYStepper = new PsychUINumericStepper(positionXStepper.x + 70, positionXStepper.y, 10, character.positionArray[1], -9000, 9000, 0);

		positionCameraXStepper = new PsychUINumericStepper(positionXStepper.x, positionXStepper.y + 40, 10, character.cameraPosition[0], -9000, 9000, 0);
		positionCameraYStepper = new PsychUINumericStepper(positionYStepper.x, positionYStepper.y + 40, 10, character.cameraPosition[1], -9000, 9000, 0);

		var saveCharacterButton:PsychUIButton = new PsychUIButton(reloadImage.x, noAntialiasingCheckBox.y + 40, "Save Character", function()
		{
			saveCharacter();
		});

		healthColorStepperR = new PsychUINumericStepper(singDurationStepper.x, saveCharacterButton.y, 20, character.healthColorArray[0], 0, 255, 0);
		healthColorStepperG = new PsychUINumericStepper(singDurationStepper.x + 65, saveCharacterButton.y, 20, character.healthColorArray[1], 0, 255, 0);
		healthColorStepperB = new PsychUINumericStepper(singDurationStepper.x + 130, saveCharacterButton.y, 20, character.healthColorArray[2], 0, 255, 0);

		tab_group.add(new FlxText(15, imageInputText.y - 18, 100, 'Image file name:'));
		tab_group.add(new FlxText(15, healthIconInputText.y - 18, 100, 'Health icon name:'));
		tab_group.add(new FlxText(15, vocalsInputText.y - 18, 100, 'Vocals File Postfix:'));
		tab_group.add(new FlxText(15, singDurationStepper.y - 18, 120, 'Sing Animation length:'));
		tab_group.add(new FlxText(15, scaleStepper.y - 18, 100, 'Scale:'));
		tab_group.add(new FlxText(positionXStepper.x, positionXStepper.y - 18, 100, 'Character X/Y:'));
		tab_group.add(new FlxText(positionCameraXStepper.x, positionCameraXStepper.y - 18, 100, 'Camera X/Y:'));
		tab_group.add(new FlxText(healthColorStepperR.x, healthColorStepperR.y - 18, 100, 'Health Bar R/G/B:'));

		// Combat change
		var tabName:String = 'Character';

		tab_group.add(createHoverLabel(new FlxText(saveCharacterButton.x, saveCharacterButton.y - 15, 0, 'v*'),
			"Saving a character json also saves their combat information\n
			Parameters that cannot be edited here (Raw combat stats and such) are still preserved on saving\nif they previously existed", tabName));
		// End of change

		tab_group.add(imageInputText);
		tab_group.add(reloadImage);
		tab_group.add(decideIconColor);
		tab_group.add(healthIconInputText);
		tab_group.add(vocalsInputText);
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
	}

	public function UIEvent(id:String, sender:Dynamic)
	{
		// trace(id, sender);
		if (id == PsychUICheckBox.CLICK_EVENT)
			unsavedProgress = true;

		if (id == PsychUIInputText.CHANGE_EVENT)
		{
			if (sender == healthIconInputText)
			{
				var lastIcon = healthIcon.getCharacter();
				healthIcon.changeIcon(healthIconInputText.text, false);
				character.healthIcon = healthIconInputText.text;
				if (lastIcon != healthIcon.getCharacter())
					updatePresence();
				unsavedProgress = true;
			}
			else if (sender == vocalsInputText)
			{
				character.vocalsFile = vocalsInputText.text;
				unsavedProgress = true;
			}
			else if (sender == imageInputText)
			{
				character.imageFile = imageInputText.text;
				unsavedProgress = true;
			}
		}
		else if (id == PsychUINumericStepper.CHANGE_EVENT)
		{
			if (sender == scaleStepper)
			{
				reloadCharacterImage();
				character.jsonScale = sender.value;
				character.scale.set(character.jsonScale, character.jsonScale);
				character.updateHitbox();
				updatePointerPos(false);
				unsavedProgress = true;
			}
			else if (sender == positionXStepper)
			{
				character.positionArray[0] = positionXStepper.value;
				updateCharacterPositions();
				unsavedProgress = true;
			}
			else if (sender == positionYStepper)
			{
				character.positionArray[1] = positionYStepper.value;
				updateCharacterPositions();
				unsavedProgress = true;
			}
			else if (sender == singDurationStepper)
			{
				character.singDuration = singDurationStepper.value;
				unsavedProgress = true;
			}
			else if (sender == positionCameraXStepper)
			{
				character.cameraPosition[0] = positionCameraXStepper.value;
				updatePointerPos();
				unsavedProgress = true;
			}
			else if (sender == positionCameraYStepper)
			{
				character.cameraPosition[1] = positionCameraYStepper.value;
				updatePointerPos();
				unsavedProgress = true;
			}
			else if (sender == healthColorStepperR)
			{
				character.healthColorArray[0] = Math.round(healthColorStepperR.value);
				updateHealthBar();
				unsavedProgress = true;
			}
			else if (sender == healthColorStepperG)
			{
				character.healthColorArray[1] = Math.round(healthColorStepperG.value);
				updateHealthBar();
				unsavedProgress = true;
			}
			else if (sender == healthColorStepperB)
			{
				character.healthColorArray[2] = Math.round(healthColorStepperB.value);
				updateHealthBar();
				unsavedProgress = true;
			}
			// Combat change
			else if (sender == effectScaleStepper)
			{
				if (curEffect != null)
				{
					reloadEffectImage();
					curEffect.jsonScale = sender.value;
					curEffect.scale.set(curEffect.jsonScale, curEffect.jsonScale);
					curEffect.updateHitbox();
					updateEffectPositions();
					updatePointerPos(false);
					unsavedProgress = true;
				}
			}
			else if (sender == effectPositionXStepper)
			{
				if (curEffect != null)
				{
					curEffect.generalOffset[0] = effectPositionXStepper.value;
					updateEffectPositions();
					unsavedProgress = true;
				}
			}
			else if (sender == effectPositionYStepper)
			{
				if (curEffect != null)
				{
					curEffect.generalOffset[1] = effectPositionYStepper.value;
					updateEffectPositions();
					unsavedProgress = true;
				}
			}
			else if (sender == effectLayerStepper)
			{
				if (curEffect != null)
				{
					curEffect.layer = sender.value;
					curEffect.zDepth = curEffect.layer;
					characterGroup.sort(PlayState.sortByZ);
				}
			}
			else if (sender == effectAnimationAngle)
			{
				if (curEffect != null)
					curEffect.angle = sender.value;
			}
			else if (sender == attackStartDurationStepper)
			{
				curAttack.duration = attackStartDurationStepper.value;
			}
			else if (sender == attackEndDurationStepper)
			{
				curAttack.recovery = attackEndDurationStepper.value;
			}
			// End of change
		}
	}

	function reloadCharacterImage()
	{
		var lastAnim:String = character.getAnimationName();
		var anims:Array<AnimArray> = character.animationsArray.copy();

		character.atlas = FlxDestroyUtil.destroy(character.atlas);
		character.isAnimateAtlas = false;
		character.color = FlxColor.WHITE;
		character.alpha = 1;

		if (Paths.fileExists('images/' + character.imageFile + '/Animation.json', TEXT))
		{
			character.atlas = new FlxAnimate();
			character.atlas.showPivot = false;
			try
			{
				Paths.loadAnimateAtlas(character.atlas, character.imageFile);
			}
			catch (e:Dynamic)
			{
				FlxG.log.warn('Could not load atlas ${character.imageFile}: $e');
			}
			character.isAnimateAtlas = true;
		}
		else
		{
			character.frames = Paths.getMultiAtlas(character.imageFile.split(','));
		}

		for (anim in anims)
		{
			var animAnim:String = '' + anim.anim;
			var animName:String = '' + anim.name;
			var animFps:Int = anim.fps;
			var animLoop:Bool = !!anim.loop; // Bruh
			var animIndices:Array<Int> = anim.indices;
			addAnimation(animAnim, animName, animFps, animLoop, animIndices);
		}

		if (anims.length > 0)
		{
			if (lastAnim != '')
				character.playAnim(lastAnim, true);
			else
				character.dance();
		}
	}

	function reloadCharacterOptions()
	{
		if (UI_characterbox == null)
			return;

		check_player.checked = character.isPlayer;
		imageInputText.text = character.imageFile;
		healthIconInputText.text = character.healthIcon;
		vocalsInputText.text = character.vocalsFile != null ? character.vocalsFile : '';
		singDurationStepper.value = character.singDuration;
		scaleStepper.value = character.jsonScale;
		flipXCheckBox.checked = character.originalFlipX;
		noAntialiasingCheckBox.checked = character.noAntialiasing;
		positionXStepper.value = character.positionArray[0];
		positionYStepper.value = character.positionArray[1];
		positionCameraXStepper.value = character.cameraPosition[0];
		positionCameraYStepper.value = character.cameraPosition[1];
		reloadAnimationDropDown();
		updateHealthBar();
		// Combat change
		reloadEffectOptions();
		// End of change
	}

	var holdingArrowsTime:Float = 0;
	var holdingArrowsElapsed:Float = 0;
	var holdingFrameTime:Float = 0;
	var holdingFrameElapsed:Float = 0;
	var undoOffsets:Array<Float> = null;

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (PsychUIInputText.focusOn != null)
		{
			ClientPrefs.toggleVolumeKeys(false);
			return;
		}
		ClientPrefs.toggleVolumeKeys(true);

		var shiftMult:Float = 1;
		var ctrlMult:Float = 1;
		var shiftMultBig:Float = 1;
		if (FlxG.keys.pressed.SHIFT)
		{
			shiftMult = 4;
			shiftMultBig = 10;
		}
		if (FlxG.keys.pressed.CONTROL)
			ctrlMult = 0.25;

		// CAMERA CONTROLS
		if (FlxG.keys.pressed.J)
			FlxG.camera.scroll.x -= elapsed * 500 * shiftMult * ctrlMult;
		if (FlxG.keys.pressed.K)
			FlxG.camera.scroll.y += elapsed * 500 * shiftMult * ctrlMult;
		if (FlxG.keys.pressed.L)
			FlxG.camera.scroll.x += elapsed * 500 * shiftMult * ctrlMult;
		if (FlxG.keys.pressed.I)
			FlxG.camera.scroll.y -= elapsed * 500 * shiftMult * ctrlMult;

		var lastZoom = FlxG.camera.zoom;
		if (FlxG.keys.justPressed.R && !FlxG.keys.pressed.CONTROL)
			FlxG.camera.zoom = 1;
		else if (FlxG.keys.pressed.E && FlxG.camera.zoom < 3)
		{
			FlxG.camera.zoom += elapsed * FlxG.camera.zoom * shiftMult * ctrlMult;
			if (FlxG.camera.zoom > 3)
				FlxG.camera.zoom = 3;
		}
		else if (FlxG.keys.pressed.Q && FlxG.camera.zoom > 0.1)
		{
			FlxG.camera.zoom -= elapsed * FlxG.camera.zoom * shiftMult * ctrlMult;
			if (FlxG.camera.zoom < 0.1)
				FlxG.camera.zoom = 0.1;
		}

		if (lastZoom != FlxG.camera.zoom)
			cameraZoomText.text = 'Zoom: ' + FlxMath.roundDecimal(FlxG.camera.zoom, 2) + 'x';

		// Combat change
		/*
					// CHARACTER CONTROLS
			var changedAnim:Bool = false;
			if (anims.length > 1)
			{
				if (FlxG.keys.justPressed.W && (changedAnim = true))
					curAnim--;
				else if (FlxG.keys.justPressed.S && (changedAnim = true))
					curAnim++;

				if (changedAnim)
				{
					undoOffsets = null;
					curAnim = FlxMath.wrap(curAnim, 0, anims.length - 1);
					character.playAnim(anims[curAnim].anim, true);
					updateText();
				}
			}

			var changedOffset = false;
			var moveKeysP = [
				FlxG.keys.justPressed.LEFT,
				FlxG.keys.justPressed.RIGHT,
				FlxG.keys.justPressed.UP,
				FlxG.keys.justPressed.DOWN
			];
			var moveKeys = [
				FlxG.keys.pressed.LEFT,
				FlxG.keys.pressed.RIGHT,
				FlxG.keys.pressed.UP,
				FlxG.keys.pressed.DOWN
			];

			if (moveKeysP.contains(true))
			{
				character.offset.x += ((moveKeysP[0] ? 1 : 0) - (moveKeysP[1] ? 1 : 0)) * shiftMultBig;
				character.offset.y += ((moveKeysP[2] ? 1 : 0) - (moveKeysP[3] ? 1 : 0)) * shiftMultBig;
				changedOffset = true;
			}

			if (moveKeys.contains(true))
			{
				holdingArrowsTime += elapsed;
				if (holdingArrowsTime > 0.6)
				{
					holdingArrowsElapsed += elapsed;
					while (holdingArrowsElapsed > (1 / 60))
					{
						character.offset.x += ((moveKeys[0] ? 1 : 0) - (moveKeys[1] ? 1 : 0)) * shiftMultBig;
						character.offset.y += ((moveKeys[2] ? 1 : 0) - (moveKeys[3] ? 1 : 0)) * shiftMultBig;
						holdingArrowsElapsed -= (1 / 60);
						changedOffset = true;
					}
				}
			}
			else
				holdingArrowsTime = 0;

			if (FlxG.mouse.pressedRight && (FlxG.mouse.deltaScreenX != 0 || FlxG.mouse.deltaScreenY != 0))
			{
				character.offset.x -= FlxG.mouse.deltaScreenX;
				character.offset.y -= FlxG.mouse.deltaScreenY;
				changedOffset = true;
			}

				if (FlxG.keys.pressed.CONTROL)
				{
					if (FlxG.keys.justPressed.C)
					{
						copiedOffset[0] = character.offset.x;
						copiedOffset[1] = character.offset.y;
						changedOffset = true;
					}
					else if (FlxG.keys.justPressed.V)
					{
						undoOffsets = [character.offset.x, character.offset.y];
						character.offset.x = copiedOffset[0];
						character.offset.y = copiedOffset[1];
						changedOffset = true;
					}
					else if (FlxG.keys.justPressed.R)
					{
						undoOffsets = [character.offset.x, character.offset.y];
						character.offset.set(0, 0);
						changedOffset = true;
					}
					else if (FlxG.keys.justPressed.Z && undoOffsets != null)
					{
						character.offset.x = undoOffsets[0];
						character.offset.y = undoOffsets[1];
						changedOffset = true;
					}
				}

				var anim = anims[curAnim];
				if (changedOffset && anim != null && anim.offsets != null)
				{
					anim.offsets[0] = Std.int(character.offset.x);
					anim.offsets[1] = Std.int(character.offset.y);

					character.addOffset(anim.anim, character.offset.x, character.offset.y);
					updateText();
				}

							var txt = 'ERROR: No Animation Found';
			var clr = FlxColor.RED;
			if (!character.isAnimationNull())
			{
				if (FlxG.keys.pressed.A || FlxG.keys.pressed.D)
				{
					holdingFrameTime += elapsed;
					if (holdingFrameTime > 0.5)
						holdingFrameElapsed += elapsed;
				}
				else
					holdingFrameTime = 0;

				if (FlxG.keys.justPressed.SPACE)
					character.playAnim(character.getAnimationName(), true);

				var frames:Int = -1;
				var length:Int = -1;
				if (!character.isAnimateAtlas && character.animation.curAnim != null)
				{
					frames = character.animation.curAnim.curFrame;
					length = character.animation.curAnim.numFrames;
				}
				else if (character.isAnimateAtlas && character.atlas.anim != null)
				{
					frames = character.atlas.anim.curFrame;
					length = character.atlas.anim.length;
				}

				if (length >= 0)
				{
					if (FlxG.keys.justPressed.A || FlxG.keys.justPressed.D || holdingFrameTime > 0.5)
					{
						var isLeft = false;
						if ((holdingFrameTime > 0.5 && FlxG.keys.pressed.A) || FlxG.keys.justPressed.A)
							isLeft = true;
						character.animPaused = true;

						if (holdingFrameTime <= 0.5 || holdingFrameElapsed > 0.1)
						{
							frames = FlxMath.wrap(frames + Std.int(isLeft ? -shiftMult : shiftMult), 0, length - 1);
							if (!character.isAnimateAtlas)
								character.animation.curAnim.curFrame = frames;
							else
								character.atlas.anim.curFrame = frames;
							holdingFrameElapsed -= 0.1;
						}
					}

					txt = 'Frames: ( $frames / ${length - 1} )';
					// if(character.animation.curAnim.paused) txt += ' - PAUSED';
					clr = FlxColor.WHITE;
				}
			}

			if (txt != frameAdvanceText.text)
			frameAdvanceText.text = txt;
			frameAdvanceText.color = clr;
		 */

		if (FlxG.mouse.overlaps(labelledTextGroup, camHUD))
		{
			labelledTextGroup.forEach(function(txt:FlxText)
			{
				if (FlxG.mouse.overlaps(txt, camHUD))
				{
					if (UI_characterbox.selectedTab != null && labelTabMap.get(txt.ID) == UI_characterbox.selectedTab.name)
					{
						// A bit of breathing room that moving the cursor doesn't immediately trip the label
						// Buuut I want the label to come up fairly accidentally so it naturally gets taught
						// Very easy for this feature to get glossed over if we had to rely on a short blurb somewhere
						hoverElapsed += elapsed;
						if (hoverElapsed >= 0.07)
						{
							updateLabel(labelMap.get(txt.ID));
							hoverElapsed = 0.07;
						}
					}
					return;
				}
			});
		}
		else
		{
			labelBackground.active = labelBackground.visible = false;
			labelText.active = labelText.visible = false;
			hoverElapsed = 0;
		}

		if (UI_characterbox.selectedTab != null
			&& previousUICharacterBoxTab != UI_characterbox.selectedTab.name
			&& determineCurrentEditMode() != currentEditMode)
		{
			previousUICharacterBoxTab = UI_characterbox.selectedTab.name;
			currentEditMode = determineCurrentEditMode();

			if (currentEditMode == 'attack')
			{
				curAnim = 0;
				assignAttackData(curAttack, attacks[0]);
				fillTempDirectionArray();
				animateAttack(true);
				updateAttackText();
				updateAttackOptions();
			}
			else
			{
				curChain = null;
				reloadAnimList();
			}
		}

		if (currentEditMode == 'attack')
		{
			var changedAnim:Bool = false;
			if (attacks.length > 1 || chains.length > 1)
			{
				if (FlxG.keys.justPressed.W && (changedAnim = true))
					curAnim--;
				else if (FlxG.keys.justPressed.S && (changedAnim = true))
					curAnim++;

				if (FlxG.keys.pressed.CONTROL)
				{
					if (FlxG.keys.justPressed.W || FlxG.keys.justPressed.S)
					{
						changedAnim = true;

						if (curAnim == 1 || curAnim % 20 != 1)
						{
							if (FlxG.keys.justPressed.W)
							{
								curAnim -= 20;
							}
							if (FlxG.keys.justPressed.S)
							{
								if (curAnim == 1)
									++curAnim;
								curAnim += 20;
							}

							curAnim -= curAnim % 20;
							++curAnim;
						}

						if (curAnim == 1)
							--curAnim;
					}
				}
				else if (FlxG.keys.pressed.SHIFT)
				{
					if (FlxG.keys.justPressed.W)
						curAnim -= 3;
					if (FlxG.keys.justPressed.S)
						curAnim += 3;
				}

				if (changedAnim)
				{
					var changedChain = false;
					if (curChain != null)
					{
						if (curAnim > curChain.attack_chain.length - 1)
						{
							curAnim = 0;
							++curChainNum;
							changedChain = true;
						}
						else if (curAnim < 0)
						{
							curAnim = 0;
							--curChainNum;
							changedChain = true;
						}

						if (curChainNum > chains.length - 1 || curChainNum < 0)
							curChain = null;
						else if (changedChain)
							assignChainData(chains[curChainNum], curChain);

						if (curChainNum < 0)
							curAnim = attacks.length - 1;
					}
					else
					{
						if (curAnim > attacks.length - 1)
						{
							curAnim = 0;
							curChainNum = 0;
							assignChainData(chains[curChainNum], curChain);
						}
						else if (curAnim < 0)
						{
							curAnim = 0;
							curChainNum = chains.length - 1;
							assignChainData(chains[curChainNum], curChain);
						}
					}

					if (curChain != null)
					{
						for (attack in attacks)
						{
							if (attack.name == curChain.attack_chain[curAnim])
							{
								assignAttackData(curAttack, attack);
								break;
							}
						}
					}
					else
					{
						assignAttackData(curAttack, attacks[curAnim]);
						fillTempDirectionArray();
					}

					if (curChain == null)
						animateAttack(true);

					updateAttackText();
					updateAttackOptions();
				}
			}

			if (!FlxG.keys.pressed.CONTROL
				&& ((curAttack.append_direction_to_anim_name || curAttack.direction == 'ANY')
					&& (FlxG.keys.justPressed.A || FlxG.keys.justPressed.D)))
			{
				var tempAnim:Int = directionDropDown.list.indexOf(tempDirectionArray[0]);
				if (curChain != null)
					tempAnim = directionDropDown.list.indexOf(tempDirectionArray[curAnim]);

				var arrayShift:Int = -1;
				if (FlxG.keys.justPressed.D)
					arrayShift = 1;

				tempAnim += arrayShift;

				if (tempAnim > directionDropDown.list.length - 1)
					tempAnim = 2;
				else if (tempAnim < 2)
					tempAnim = directionDropDown.list.length - 1;

				if (curChain != null)
					tempDirectionArray[curAnim] = directionDropDown.list[tempAnim];
				else
					tempDirectionArray[0] = directionDropDown.list[tempAnim];
			}

			var txt:String = 'Anim Direction Override: ';

			if (curChain != null)
				txt += tempDirectionArray[curAnim];
			else
				txt += tempDirectionArray[0];

			frameAdvanceText.text = txt;

			if (FlxG.keys.justPressed.SPACE)
				animateAttack(true);
		}
		else
			evaluateCharacterControls(elapsed, shiftMult, ctrlMult, shiftMultBig);
		// End of change

		// OTHER CONTROLS
		if (FlxG.keys.justPressed.F12)
			silhouettes.visible = !silhouettes.visible;

		if (FlxG.keys.justPressed.F1 || (helpBg.visible && FlxG.keys.justPressed.ESCAPE))
		{
			helpBg.visible = !helpBg.visible;
			helpTexts.visible = helpBg.visible;
		}
		else if (FlxG.keys.justPressed.ESCAPE)
		{
			if (!_goToPlayState)
			{
				if (!unsavedProgress)
				{
					MusicBeatState.switchState(new states.editors.MasterEditorMenu());
					FlxG.sound.playMusic(Paths.music('freakyMenu'));
				}
				else
					openSubState(new ExitConfirmationPrompt());
			}
			else
			{
				FlxG.mouse.visible = false;
				MusicBeatState.switchState(new PlayState());
			}
			return;
		}
	}

	final assetFolder = 'week1'; // load from assets/week1/

	inline function loadBG()
	{
		var lastLoaded = Paths.currentLevel;
		Paths.currentLevel = assetFolder;

		/////////////
		// bg data //
		/////////////
		#if !BASE_GAME_FILES
		camEditor.bgColor = 0xFF666666;
		#else
		var bg:BGSprite = new BGSprite('stageback', -600, -200, 0.9, 0.9);
		add(bg);

		var stageFront:BGSprite = new BGSprite('stagefront', -650, 600, 0.9, 0.9);
		stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
		stageFront.updateHitbox();
		add(stageFront);
		#end

		dadPosition.set(100, 100);
		bfPosition.set(770, 100);
		/////////////

		Paths.currentLevel = lastLoaded;
	}

	inline function updatePointerPos(?snap:Bool = true)
	{
		if (character == null || cameraFollowPointer == null)
			return;

		var offX:Float = 0;
		var offY:Float = 0;
		if (!character.isPlayer)
		{
			offX = character.getMidpoint().x + 150 + character.cameraPosition[0];
			offY = character.getMidpoint().y - 100 + character.cameraPosition[1];
		}
		else
		{
			offX = character.getMidpoint().x - 100 - character.cameraPosition[0];
			offY = character.getMidpoint().y - 100 + character.cameraPosition[1];
		}
		cameraFollowPointer.setPosition(offX, offY);

		if (snap)
		{
			FlxG.camera.scroll.x = cameraFollowPointer.getMidpoint().x - FlxG.width / 2;
			FlxG.camera.scroll.y = cameraFollowPointer.getMidpoint().y - FlxG.height / 2;
		}
	}

	inline function updateHealthBar()
	{
		healthColorStepperR.value = character.healthColorArray[0];
		healthColorStepperG.value = character.healthColorArray[1];
		healthColorStepperB.value = character.healthColorArray[2];
		healthBar.leftBar.color = healthBar.rightBar.color = FlxColor.fromRGB(character.healthColorArray[0], character.healthColorArray[1],
			character.healthColorArray[2]);
		healthIcon.changeIcon(character.healthIcon, false);
		updatePresence();
	}

	inline function updatePresence()
	{
		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("Character Editor", "Character: " + _char, healthIcon.getCharacter());
		#end
	}

	// Combat change

	/*
		inline function reloadAnimList()
		{
			anims = character.animationsArray;
			if (anims.length > 0)
				character.playAnim(anims[0].anim, true);
			curAnim = 0;

			updateText();
			if (animationDropDown != null)
				reloadAnimationDropDown();
	}*/
	inline function reloadAnimList()
	{
		if (currentEditMode == 'effect' && curEffect != null)
		{
			anims = curEffect.animationsArray;
			if (anims.length > 0 && character.animation.getByName(anims[0].anim) != null)
				character.playAnim(anims[0].anim, true);
			else
				character.playAnim(character.animationsArray[0].anim, true);
			curAnim = 0;

			updateText();
			if (effectAnimationDropDown != null)
				reloadEffectAnimationDropDown();
		}
		else
		{
			anims = character.animationsArray;
			if (anims.length > 0)
				character.playAnim(anims[0].anim, true);
			curAnim = 0;

			updateText();
			if (animationDropDown != null)
				reloadAnimationDropDown();
		}
		// End of change
	}

	inline function updateText()
	{
		animsTxt.removeFormat(selectedFormat);

		var intendText:String = '';
		// Combat change
		var formatStart:Int = 0;
		var formatEnd:Int = 0;
		textPages = [];
		// End of change
		for (num => anim in anims)
		{
			// Combat change
			// if (num > 0)
			if (intendText != '')
				intendText += '\n';

			if (num == curAnim)
			{
				// Combat change
				// var n:Int = intendText.length;
				// intendText += anim.anim + ": " + anim.offsets;
				// animsTxt.addFormat(selectedFormat, n, intendText.length);
				formatStart = intendText.length;
				intendText += anim.anim + ": " + anim.offsets;
				formatEnd = intendText.length;

				curPage = textPages.length;
				// End of change
			}
			else
				intendText += anim.anim + ": " + anim.offsets;

			// Combat change
			if (num != 0 && num % 20 == 0)
			{
				textPages.push(intendText);
				intendText = '';
			}
			// End of change
		}
		// Combat change
		// animsTxt.text = intendText;
		if (intendText != '')
			textPages.push(intendText);
		intendText = 'Current Page: ${curPage + 1}/${textPages.length}\n\n';
		formatStart += intendText.length;
		formatEnd += intendText.length;

		animsTxt.text = intendText + textPages[curPage];
		animsTxt.addFormat(selectedFormat, formatStart, formatEnd);
		// End of change
	}

	inline function updateCharacterPositions()
	{
		if ((character != null && !character.isPlayer) || (character == null && predictCharacterIsNotPlayer(_char)))
			character.setPosition(dadPosition.x, dadPosition.y);
		else
			character.setPosition(bfPosition.x, bfPosition.y);

		character.x += character.positionArray[0];
		character.y += character.positionArray[1];
		updatePointerPos(false);
	}

	inline function predictCharacterIsNotPlayer(name:String)
	{
		return (name != 'bf' && !name.startsWith('bf-') && !name.endsWith('-player') && !name.endsWith('-playable') && !name.endsWith('-dead'))
			|| name.endsWith('-opponent')
			|| name.startsWith('gf-')
			|| name.endsWith('-gf')
			|| name == 'gf';
	}

	function addAnimation(anim:String, name:String, fps:Float, loop:Bool, indices:Array<Int>)
	{
		if (!character.isAnimateAtlas)
		{
			if (indices != null && indices.length > 0)
				character.animation.addByIndices(anim, name, indices, "", fps, loop);
			else
				character.animation.addByPrefix(anim, name, fps, loop);
		}
		else
		{
			if (indices != null && indices.length > 0)
				character.atlas.anim.addBySymbolIndices(anim, name, indices, fps, loop);
			else
				character.atlas.anim.addBySymbol(anim, name, fps, loop);
		}

		if (!character.hasAnimation(anim))
			character.addOffset(anim, 0, 0);
	}

	inline function newAnim(anim:String, name:String):AnimArray
	{
		return {
			offsets: [0, 0],
			loop: false,
			fps: 24,
			anim: anim,
			indices: [],
			name: name
		};
	}

	var characterList:Array<String> = [];

	function reloadCharacterDropDown()
	{
		characterList = Mods.mergeAllTextsNamed('data/characterList.txt');
		var foldersToCheck:Array<String> = Mods.directoriesWithFile(Paths.getSharedPath(), 'characters/');
		for (folder in foldersToCheck)
			for (file in FileSystem.readDirectory(folder))
				if (file.toLowerCase().endsWith('.json'))
				{
					var charToCheck:String = file.substr(0, file.length - 5);
					if (!characterList.contains(charToCheck))
						characterList.push(charToCheck);
				}

		if (characterList.length < 1)
			characterList.push('');
		charDropDown.list = characterList;
		charDropDown.selectedLabel = _char;
	}

	function reloadAnimationDropDown()
	{
		var animList:Array<String> = [];
		for (anim in anims)
			animList.push(anim.anim);
		if (animList.length < 1)
			animList.push('NO ANIMATIONS'); // Prevents crash

		animationDropDown.list = animList;
	}

	// save
	var _file:FileReference;

	function onSaveComplete(_):Void
	{
		if (_file == null)
			return;
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
		if (_file == null)
			return;
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
		if (_file == null)
			return;
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.error("Problem saving file");
	}

	function saveCharacter()
	{
		if (_file != null)
			return;

		var json:Dynamic = {
			"animations": character.animationsArray,
			"image": character.imageFile,
			"scale": character.jsonScale,
			"sing_duration": character.singDuration,
			"healthicon": character.healthIcon,

			"position": character.positionArray,
			"camera_position": character.cameraPosition,

			"flip_x": character.originalFlipX,
			"no_antialiasing": character.noAntialiasing,
			"healthbar_colors": character.healthColorArray,
			"vocals_file": character.vocalsFile,
			"_editor_isPlayer": character.isPlayer,

			// Combat change
			"combat_data": generateCombatFile() // End of change
		};

		var data:String = PsychJsonPrinter.print(json, ['offsets', 'position', 'healthbar_colors', 'camera_position', 'indices']);

		if (data.length > 0)
		{
			_file = new FileReference();
			_file.addEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data, '$_char.json');
		}
	}

	// Combat changes
	var effectAnimationDropDown:PsychUIDropDownMenu;

	var effectAnimationInputText:PsychUIInputText;
	var effectAnimationNameInputText:PsychUIInputText;
	var effectAnimationIndicesInputText:PsychUIInputText;

	var effectAnimationFramerate:PsychUINumericStepper;
	var effectAnimationLoopCheckBox:PsychUICheckBox;
	var effectAnimationAngle:PsychUINumericStepper;

	function addEffectAnimUI()
	{
		var tab_group = UI_characterbox.getTab('Effect Anim').menu;

		effectAnimationInputText = new PsychUIInputText(15, 85, 80, '', 8);
		effectAnimationNameInputText = new PsychUIInputText(effectAnimationInputText.x, effectAnimationInputText.y + 35, 150, '', 8);
		effectAnimationIndicesInputText = new PsychUIInputText(effectAnimationNameInputText.x, effectAnimationNameInputText.y + 40, 250, '', 8);
		effectAnimationFramerate = new PsychUINumericStepper(effectAnimationInputText.x + 170, effectAnimationInputText.y, 1, 24, 0, 240, 0);
		effectAnimationAngle = new PsychUINumericStepper(effectAnimationFramerate.x + 70, effectAnimationFramerate.y, 1, 0, -360, 360, 3);

		effectAnimationLoopCheckBox = new PsychUICheckBox(effectAnimationNameInputText.x + 170, effectAnimationNameInputText.y - 1, "Should it Loop?", 100,
			function()
			{
				if (curEffect != null)
					curEffect.animation.curAnim.looped = effectAnimationLoopCheckBox.checked;
			});

		effectAnimationDropDown = new PsychUIDropDownMenu(15, effectAnimationInputText.y - 55, [''], function(selectedAnimation:Int, pressed:String)
		{
			if (curEffect == null)
				return;
			var anim:SpriteAnimArray = curEffect.animationsArray[selectedAnimation];
			effectAnimationInputText.text = anim.anim;
			effectAnimationNameInputText.text = anim.name;
			effectAnimationLoopCheckBox.checked = anim.loop;
			effectAnimationFramerate.value = anim.fps;
			effectAnimationAngle.value = anim.angle;

			if (curEffect.animAngle.get(anim.anim) != null)
				effectAnimationAngle.value = curEffect.animAngle.get(anim.anim);
			else
				effectAnimationAngle.value = 0;

			var indicesStr:String = anim.indices.toString();
			effectAnimationIndicesInputText.text = indicesStr.substr(1, indicesStr.length - 2);

			updateCurAnim(selectedAnimation);
		});

		var addUpdateButton:PsychUIButton = new PsychUIButton(70, effectAnimationIndicesInputText.y + 60, "Add/Update", function()
		{
			if (curEffect == null)
				return;

			var indicesText:String = effectAnimationIndicesInputText.text.trim();
			var indices:Array<Int> = [];
			if (indicesText.length > 0)
			{
				var indicesStr:Array<String> = effectAnimationIndicesInputText.text.trim().split(',');
				if (indicesStr.length > 0)
				{
					for (ind in indicesStr)
					{
						if (ind.contains('-'))
						{
							var splitIndices:Array<String> = ind.split('-');
							var indexStart:Int = Std.parseInt(splitIndices[0]);
							if (Math.isNaN(indexStart) || indexStart < 0)
								indexStart = 0;

							var indexEnd:Int = Std.parseInt(splitIndices[1]);
							if (Math.isNaN(indexEnd) || indexEnd < indexStart)
								indexEnd = indexStart;

							for (index in indexStart...indexEnd + 1)
								indices.push(index);
						}
						else
						{
							var index:Int = Std.parseInt(ind);
							if (!Math.isNaN(index) && index > -1)
								indices.push(index);
						}
					}
				}
			}

			var lastAnim:String = (curEffect.animationsArray[curAnim] != null) ? curEffect.animationsArray[curAnim].anim : '';
			var lastOffsets:Array<Int> = [0, 0];
			for (anim in curEffect.animationsArray)
				if (effectAnimationInputText.text == anim.anim)
				{
					lastOffsets = anim.offsets;
					if (curEffect.hasAnimation(effectAnimationInputText.text))
						curEffect.animation.remove(effectAnimationInputText.text);
					curEffect.animationsArray.remove(anim);
				}

			var addedAnim:SpriteAnimArray = newEffectAnim(effectAnimationInputText.text, effectAnimationNameInputText.text);
			addedAnim.fps = Math.round(effectAnimationFramerate.value);
			addedAnim.loop = effectAnimationLoopCheckBox.checked;
			addedAnim.indices = indices;
			addedAnim.offsets = lastOffsets;
			addedAnim.angle = effectAnimationAngle.value;
			addEffectAnimation(addedAnim.anim, addedAnim.name, addedAnim.fps, addedAnim.loop, addedAnim.indices, addedAnim.angle);
			curEffect.animationsArray.push(addedAnim);

			reloadAnimList();
			@:arrayAccess curAnim = Std.int(Math.max(0, curEffect.animationsArray.indexOf(addedAnim)));
			character.playAnim(addedAnim.anim, true);
			trace('Added/Updated animation: ' + effectAnimationInputText.text);
		});

		var removeButton:PsychUIButton = new PsychUIButton(180, effectAnimationIndicesInputText.y + 60, "Remove", function()
		{
			for (anim in curEffect.animationsArray)
				if (effectAnimationInputText.text == anim.anim)
				{
					var resetAnim:Bool = false;
					if (anim.anim == curEffect.getAnimationName())
						resetAnim = true;
					if (curEffect.hasAnimation(anim.anim))
					{
						curEffect.animation.remove(anim.anim);
						curEffect.animOffsets.remove(anim.anim);
						curEffect.animationsArray.remove(anim);
					}

					if (resetAnim && curEffect.animationsArray.length > 0)
					{
						curAnim = FlxMath.wrap(curAnim, 0, anims.length - 1);
						curEffect.playAnim(anims[curAnim].anim, true);
					}
					reloadAnimList();
					trace('Removed animation: ' + effectAnimationInputText.text);
					break;
				}
		});
		reloadAnimList();
		effectAnimationDropDown.selectedLabel = anims[0] != null ? anims[0].anim : '';

		tab_group.add(new FlxText(effectAnimationDropDown.x, effectAnimationDropDown.y - 18, 100, 'Animations:'));
		tab_group.add(new FlxText(effectAnimationFramerate.x, effectAnimationFramerate.y - 18, 100, 'Framerate:'));
		tab_group.add(new FlxText(effectAnimationNameInputText.x, effectAnimationNameInputText.y - 18, 150, 'Animation Symbol Name/Tag:'));
		tab_group.add(new FlxText(effectAnimationIndicesInputText.x, effectAnimationIndicesInputText.y - 18, 170, 'ADVANCED - Animation Indices:'));
		tab_group.add(new FlxText(effectAnimationAngle.x, effectAnimationAngle.y - 18, 0, 'Rotation Angle:'));

		tab_group.add(createHoverLabel(new FlxText(effectAnimationInputText.x, effectAnimationInputText.y - 18, 0, 'Animation name*:'),
			"An effect plays its animation according to its parent character\nSo when boyfriend plays an animation like 'idle',\nthe effect would play animation 'idle'\n
		Effects are made invisible when not playing an animation",
			'Effect Anim'));

		tab_group.add(effectAnimationInputText);
		tab_group.add(effectAnimationNameInputText);
		tab_group.add(effectAnimationIndicesInputText);
		tab_group.add(effectAnimationFramerate);
		tab_group.add(effectAnimationAngle);
		tab_group.add(effectAnimationLoopCheckBox);
		tab_group.add(addUpdateButton);
		tab_group.add(removeButton);
		tab_group.add(effectAnimationDropDown);
	}

	var effectImageInputText:PsychUIInputText;
	var effectNameInputText:PsychUIInputText;
	var effectDropDown:PsychUIDropDownMenu;

	var effectScaleStepper:PsychUINumericStepper;
	var effectPositionXStepper:PsychUINumericStepper;
	var effectPositionYStepper:PsychUINumericStepper;

	var effectLayerStepper:PsychUINumericStepper;
	var effectFlipXCheckBox:PsychUICheckBox;
	var effectNoAntialiasingCheckBox:PsychUICheckBox;

	function addEffectUI()
	{
		var tab_group = UI_characterbox.getTab('Effect').menu;

		effectImageInputText = new PsychUIInputText(15, 30, 200, curEffect != null ? curEffect.imageFile : '', 8);

		effectNameInputText = new PsychUIInputText(15, effectImageInputText.y + 40, 75, '', 8);

		var reloadImage:PsychUIButton = new PsychUIButton(effectImageInputText.x + 210, effectImageInputText.y - 3, "Reload Image", function()
		{
			if (curEffect == null)
				return;
			var lastAnim = curEffect.getAnimationName();
			curEffect.imageFile = effectImageInputText.text;
			reloadEffectImage();
			if (!character.isAnimationNull())
				character.playAnim(lastAnim, true);
		});

		effectDropDown = new PsychUIDropDownMenu(reloadImage.x, effectNameInputText.y + 5, [''], function(index:Int, intended:String)
		{
			if (intended == null || intended.length < 1)
				return;

			for (member in character.characterSprites)
			{
				if (member.thisSprite == intended)
				{
					curEffect = member;
					break;
				}
			}

			reloadAnimList();
			reloadEffectOptions();
			reloadEffectDropDown();
			updatePointerPos();
		});
		reloadEffectDropDown();

		effectScaleStepper = new PsychUINumericStepper(15, 185, 0.1, 1, 0.05, 10, 2);

		effectLayerStepper = new PsychUINumericStepper(15, 145, 1, 1);

		effectFlipXCheckBox = new PsychUICheckBox(95, 145, "Flip X", 50);
		if (curEffect != null)
			effectFlipXCheckBox.checked = curEffect.flipX;
		if (character.isPlayer)
			flipXCheckBox.checked = !flipXCheckBox.checked;
		effectFlipXCheckBox.onClick = function()
		{
			if (curEffect == null)
				return;
			curEffect.originalFlipX = !curEffect.originalFlipX;
			curEffect.flipX = (curEffect.originalFlipX != character.isPlayer);
		};

		effectNoAntialiasingCheckBox = new PsychUICheckBox(effectFlipXCheckBox.x, effectFlipXCheckBox.y + 40, "No Antialiasing", 80);
		if (curEffect != null)
			effectNoAntialiasingCheckBox.checked = curEffect.noAntialiasing;
		effectNoAntialiasingCheckBox.onClick = function()
		{
			if (curEffect == null)
				return;
			curEffect.antialiasing = false;
			if (!effectNoAntialiasingCheckBox.checked && ClientPrefs.data.antialiasing)
				curEffect.antialiasing = true;
			curEffect.noAntialiasing = effectNoAntialiasingCheckBox.checked;
		};

		effectPositionXStepper = new PsychUINumericStepper(effectFlipXCheckBox.x + 110, effectFlipXCheckBox.y, 10,
			curEffect != null ? curEffect.generalOffset[0] : 0, -9000, 9000, 0);
		effectPositionYStepper = new PsychUINumericStepper(effectPositionXStepper.x + 70, effectPositionXStepper.y, 10,
			curEffect != null ? curEffect.generalOffset[1] : 0, -9000, 9000, 0);

		var deleteCurrentExtra:PsychUIButton = new PsychUIButton(15, effectScaleStepper.y + 40, "Delete Effect", function()
		{
			if (curEffect == null)
				return;
			characterGroup.remove(curEffect, true);
			character.characterExtraArray.remove(curEffect.thisSprite);
			character.characterSprites.remove(curEffect, true);
			curEffect.destroy();
			curEffect = character.characterSprites.members[0];
			reloadEffectDropDown();
			reloadAnimList();
			reloadEffectOptions();
			updateEffectPositions();
			updatePointerPos();
		});
		deleteCurrentExtra.normalStyle.bgColor = FlxColor.RED;
		deleteCurrentExtra.normalStyle.textColor = FlxColor.WHITE;

		var createEffectButton:PsychUIButton = new PsychUIButton(effectNoAntialiasingCheckBox.x + 25, deleteCurrentExtra.y, "Load/Create", function()
		{
			if (!character.characterExtraArray.contains(effectNameInputText.text))
			{
				if (effectNameInputText.text != '')
					curEffect = new CharacterExtra(character.x, character.y, character, effectNameInputText.text);
				else
					curEffect = new CharacterExtra(character.x, character.y, character, 'attackTypeShine');

				characterGroup.add(curEffect);
				character.characterExtraArray.push(curEffect.thisSprite);
			}
			else
				return;

			reloadEffectDropDown();
			reloadAnimList();
			reloadEffectOptions();
			updateEffectPositions();
			updatePointerPos();
		});

		var saveEffectButton:PsychUIButton = new PsychUIButton(reloadImage.x, createEffectButton.y, "Save Effect As", function()
		{
			if (curEffect == null)
				return;
			saveEffect();
		});

		tab_group.add(new FlxText(15, effectNameInputText.y - 18, 100, 'Effect Name:'));
		tab_group.add(new FlxText(effectLayerStepper.x, effectLayerStepper.y - 18, 0, 'Layer:'));
		tab_group.add(new FlxText(15, effectImageInputText.y - 18, 100, 'Image file name:'));
		tab_group.add(new FlxText(15, effectScaleStepper.y - 18, 100, 'Scale:'));
		tab_group.add(new FlxText(effectDropDown.x, effectDropDown.y - 18, 100, 'Current Effect:'));

		var tabName:String = 'Effect';

		tab_group.add(createHoverLabel(new FlxText(createEffectButton.x, createEffectButton.y - 15, 0, 'v*'),
			"Loads a json to add an effect, searching with the name in the Effect Name field\n
			First the character's file is searched,\nThen the characterExtra folder,\nThen the characters folder itself\n
			This means multiple jsons with the same name will take precedence in this order", tabName));
		tab_group.add(createHoverLabel(new FlxText(effectPositionXStepper.x, effectPositionXStepper.y - 18, 0, 'General Offset*:'),
			"The postion of an effect (Their x, y) is always locked to the position of the character\nThe general offset instead fills this purpose,\nand acts the same as an animation offset applied to all animations",
			tabName));

		tab_group.add(deleteCurrentExtra);
		tab_group.add(effectNameInputText);
		tab_group.add(effectImageInputText);
		tab_group.add(reloadImage);
		tab_group.add(effectScaleStepper);
		tab_group.add(effectFlipXCheckBox);
		tab_group.add(effectLayerStepper);
		tab_group.add(effectNoAntialiasingCheckBox);
		tab_group.add(effectPositionXStepper);
		tab_group.add(effectPositionYStepper);
		tab_group.add(saveEffectButton);
		tab_group.add(createEffectButton);
		tab_group.add(effectDropDown);
	}

	var attackDropDown:PsychUIDropDownMenu;
	var attackNameInputText:PsychUIInputText;
	var attackStartAnimInputText:PsychUIInputText;
	var attackEndAnimInputText:PsychUIInputText;
	var attackStartDurationStepper:PsychUINumericStepper;
	var attackEndDurationStepper:PsychUINumericStepper;
	var directionDropDown:PsychUIDropDownMenu;
	var appendDirectionCheckBox:PsychUICheckBox;
	var chainDropDown:PsychUIDropDownMenu;
	var chainNameInputText:PsychUIInputText;

	function addAttackUI()
	{
		var tab_group = UI_characterbox.getTab('Attacks').menu;

		attackNameInputText = new PsychUIInputText(15, 72, 80, '', 8);

		attackStartAnimInputText = new PsychUIInputText(15, attackNameInputText.y + 35, 80, '', 8);
		attackEndAnimInputText = new PsychUIInputText(attackStartAnimInputText.x + 100, attackStartAnimInputText.y, 85, '', 8);
		attackStartDurationStepper = new PsychUINumericStepper(attackStartAnimInputText.x, attackStartAnimInputText.y + 35, 0.042, 0, 0, 999, 3, 70);
		attackEndDurationStepper = new PsychUINumericStepper(attackEndAnimInputText.x, attackStartDurationStepper.y, 0.042, 0, 0, 999, 3, 70);

		attackDropDown = new PsychUIDropDownMenu(15, 30, [''], function(selectedAttack:Int, pressed:String)
		{
			if (attacks[selectedAttack] == null)
				return;
			var getAttack = attacks[selectedAttack];
			attackStartAnimInputText.text = getAttack.startup_animation_name;
			attackEndAnimInputText.text = getAttack.attack_animation_name;
			attackStartDurationStepper.value = getAttack.duration;
			attackEndDurationStepper.value = getAttack.recovery;
			directionDropDown.selectedLabel = getAttack.direction;

			assignAttackData(curAttack, getAttack);
			fillTempDirectionArray();
			updateAttackOptions();
			updateAttackAnim(selectedAttack);
		});

		var addAttack:PsychUIButton = new PsychUIButton(attackStartDurationStepper.x, attackStartDurationStepper.y + 27, "Add/Update Atk", function()
		{
			var attackExists = false;
			for (attack in attacks)
			{
				if (attack.name == attackNameInputText.text || attackNameInputText.text == '' && attack.name == curAttack.name)
				{
					curAttack.startup_animation_name = attackStartAnimInputText.text;
					curAttack.attack_animation_name = attackEndAnimInputText.text;
					assignAttackData(attack, curAttack);

					attackExists = true;
					break;
				}
			}
			if (!attackExists)
			{
				if (attackNameInputText.text == '')
					return;

				var newAttack:AttackData = Character.generateAttack();
				assignAttackData(newAttack, curAttack);
				newAttack.name = attackNameInputText.text;
				newAttack.startup_animation_name = attackStartAnimInputText.text;
				newAttack.attack_animation_name = attackEndAnimInputText.text;
				attacks.push(newAttack);

				curAttack.name = newAttack.name;
				curAttack.startup_animation_name = newAttack.startup_animation_name;
				curAttack.attack_animation_name = newAttack.attack_animation_name;

				curChain = null;
				curAnim = attacks.length - 1;
			}

			updateAttackOptions();
			if (curChain == null)
			{
				fillTempDirectionArray();
				updateAttackAnim(curAnim);
			}
		});
		var deleteAttack:PsychUIButton = new PsychUIButton(attackStartDurationStepper.x, addAttack.y + 30, "Delete Attack", function()
		{
			if (curAttack == null)
				return;

			for (chain in chains)
			{
				while (chain.attack_chain.contains(curAttack.name))
					chain.attack_chain.remove(curAttack.name);

				if (chain.attack_chain.length == 0)
					chain.attack_chain.push('NO ATTACKS');
			}
			curChain = null;

			for (attack in attacks)
			{
				if (attack.name == curAttack.name)
				{
					curAnim = attacks.indexOf(attack);
					attacks.remove(attack);
					if (attacks.length == 0)
					{
						attacks.push(Character.generateAttack());
						attacks[0].name = 'NO ATTACK';
						curAnim = 0;
					}

					FlxMath.wrap(curAnim, 0, attacks.length - 1);
				}
			}

			assignAttackData(curAttack, attacks[curAnim]);
			fillTempDirectionArray();
			updateAttackOptions();
		});
		deleteAttack.normalStyle.bgColor = FlxColor.RED;
		deleteAttack.normalStyle.textColor = FlxColor.WHITE;

		directionDropDown = new PsychUIDropDownMenu(attackEndAnimInputText.x, addAttack.y + 13, [''], function(selectedDirection:Int, pressed:String)
		{
			curAttack.direction = pressed;
			if (curAttack.direction == 'NONE')
				curAttack.append_direction_to_anim_name = false;
			else if (curAttack.direction == 'ANY')
				curAttack.append_direction_to_anim_name = true;
			appendDirectionCheckBox.checked = curAttack.append_direction_to_anim_name;

			if (curChain != null)
				evaluateCurrentTempDirection(curAnim);
			else
				fillTempDirectionArray();
		}, 80);
		directionDropDown.list = ['NONE', 'ANY', 'LEFT', 'SPECIAL', 'UP', 'RIGHT'];

		appendDirectionCheckBox = new PsychUICheckBox(directionDropDown.x, directionDropDown.y + 30, "Append Direction* To Anims", 100);
		appendDirectionCheckBox.onClick = function()
		{
			if (curAttack.direction == 'ANY')
				appendDirectionCheckBox.checked = true;
			if (curAttack.direction == 'NONE')
				appendDirectionCheckBox.checked = false;
			if (curAttack.direction == 'ANY' || curAttack.direction == 'NONE')
				return;

			curAttack.append_direction_to_anim_name = appendDirectionCheckBox.checked;

			if (curChain != null)
				evaluateCurrentTempDirection(curAnim);
			else
				fillTempDirectionArray();
		};

		chainDropDown = new PsychUIDropDownMenu(UI_characterbox.width - 15, attackDropDown.y, [''], function(selectedChain:Int, pressed:String)
		{
			if (chains[selectedChain] == null)
				return;

			var getChain = chains[selectedChain];
			assignChainData(getChain, curChain);

			for (attack in attacks)
			{
				if (attack.name == curChain.attack_chain[0])
				{
					assignAttackData(curAttack, attack);
					break;
				}
			}

			fillTempDirectionArray(true);
			updateAttackOptions();
			updateAttackAnim();
		});
		chainDropDown.x -= chainDropDown.width;

		var varX = chainDropDown.x + 20;

		chainNameInputText = new PsychUIInputText(varX, attackNameInputText.y, 80, '', 8);

		var addChain:PsychUIButton = new PsychUIButton(varX, attackEndAnimInputText.y - 3, "Add/Up Chain", function()
		{
			if (curChain == null)
				curChain = Character.generateChain();

			var chainExists = false;
			for (chain in chains)
			{
				if (chain.name == chainNameInputText.text || chainNameInputText.text == '' && chain.name == curChain.name)
				{
					chainExists = true;
					chain.attack_chain = curChain.attack_chain;
					break;
				}
			}
			if (!chainExists)
			{
				if (chainNameInputText.text == '')
					return;

				var newChain:ChainData = Character.generateChain();
				newChain.name = chainNameInputText.text;
				newChain.attack_chain = ['NO ATTACKS'];
				chains.push(newChain);
				curChain.name = newChain.name;
			}

			curAnim = 0;
			for (attack in attacks)
			{
				if (attack.name == curChain.attack_chain[0])
				{
					assignAttackData(attack, curAttack);
					break;
				}
			}
			fillTempDirectionArray(true);
			updateAttackOptions();
			updateAttackAnim();
		});

		var deleteChain:PsychUIButton = new PsychUIButton(varX, attackEndDurationStepper.y - 3, "Delete Chain", function()
		{
			if (curChain == null)
				return;

			var chainInt:Int = 0;
			for (chain in chains)
			{
				if (chain.name == curChain.name)
				{
					chains.remove(chain);
					break;
				}
				++chainInt;
			}

			chainInt -= 1;
			if (chainInt > 0 && chainInt < chains.length - 1)
				assignChainData(chains[chainInt - 1], curChain);
			else
				curChain = null;

			fillTempDirectionArray(curChain != null);
			updateAttackOptions();
			updateAttackAnim();
		});
		deleteChain.normalStyle.bgColor = FlxColor.RED;
		deleteChain.normalStyle.textColor = FlxColor.WHITE;

		var linkAttack:PsychUIButton = new PsychUIButton(varX, addAttack.y, "Link Attack", function()
		{
			if (curChain == null)
				return;

			if (curChain.attack_chain[curAnim] == 'NO ATTACKS')
			{
				curChain.attack_chain.remove(curChain.attack_chain[curAnim]);
				curChain.attack_chain.insert(curAnim, attackNameInputText.text);
			}
			else
				curChain.attack_chain.insert(curAnim + 1, attackNameInputText.text);

			evaluateCurrentTempDirection(curChain.attack_chain.indexOf(attackNameInputText.text));
			updateAttackOptions();
		});
		var unlinkAttack:PsychUIButton = new PsychUIButton(varX, deleteAttack.y, "Unlink Attack", function()
		{
			if (curChain == null)
				return;

			curChain.attack_chain.remove(curChain.attack_chain[curAnim]);
			if (curChain.attack_chain.length == 0)
				curChain.attack_chain.push('NO ATTACKS');

			if (tempDirectionArray.length > curChain.attack_chain.length)
				tempDirectionArray.remove(tempDirectionArray[curAnim]);

			updateAttackOptions();
		});

		var loadCombatJson:PsychUIButton = new PsychUIButton(deleteAttack.x, deleteAttack.y + 30, "Load Com. Json", function()
		{
			loadCombatFile();
		});

		var saveCombatJson:PsychUIButton = new PsychUIButton(unlinkAttack.x, unlinkAttack.y + 30, "Save Com. Json", function()
		{
			openSubState(new Prompt('Warning:\nThis saves a combat data json.\nDo not overwrite a character file!', saveCombatFile));
		});

		tab_group.add(new FlxText(attackNameInputText.x, attackNameInputText.y - 18, 100, 'Attack Name:'));
		tab_group.add(new FlxText(attackStartAnimInputText.x, attackStartAnimInputText.y - 18, 100, 'Startup Animation:'));
		tab_group.add(new FlxText(attackEndAnimInputText.x, attackEndAnimInputText.y - 18, 100, 'Finish Animation:'));
		tab_group.add(new FlxText(attackDropDown.x, attackDropDown.y - 18, 100, 'Attacks:'));
		tab_group.add(new FlxText(directionDropDown.x, directionDropDown.y - 18, 100, 'Direction:'));
		tab_group.add(new FlxText(chainNameInputText.x, chainNameInputText.y - 18, 100, 'Chain Name:'));

		var tabName = 'Attacks';
		createHoverLabel(appendDirectionCheckBox.text, "Direction \"ANY\" ignores this and appends regardless.\n
		Direction \"NONE\" implies *no* direction and never appends.", tabName);
		tab_group.add(createHoverLabel(new FlxText(deleteAttack.x + deleteAttack.width + 2, deleteAttack.y, 0, '<*'),
			"Deleting an attack will also remove it from every existing chain\n
			Previously existing attacks also maintain information that cannot be edited in this editor\n
			So deleting and remaking an attack can lead to losing prior information\nBe sure to backup your files accordingly", tabName));
		tab_group.add(createHoverLabel(new FlxText(attackStartDurationStepper.x, attackStartDurationStepper.y - 18, 0, 'Windup*:'),
			'Length of frame in current attack startup anim: ${attackStartDurationStepper.step} Seconds', tabName));
		tab_group.add(createHoverLabel(new FlxText(attackEndDurationStepper.x, attackEndDurationStepper.y - 18, 0, 'Recovery*:'),
			'Length of frame in current attack execution anim: ${attackEndDurationStepper.step} Seconds', tabName));
		tab_group.add(createHoverLabel(new FlxText(chainDropDown.x, chainDropDown.y - 18, 100, 'Chains*:'),
			'Chains reference attacks by name,\nthus they pull from the attack list instead of the fluid curAttack object.\n
			This means editing attacks in chains need to be Add/Updated for changes to apply', tabName));
		tab_group.add(createHoverLabel(new FlxText(saveCombatJson.x - 15, saveCombatJson.y, 0, '*>'),
			"This saves a json of just the current combat information\n
			Saving a character in the character tab automatically saves this combat information.\n
			So use this to switch combat information on a broad scale,\nLike for fight phases or as player/as enemy stat differences", tabName));

		tab_group.add(attackNameInputText);
		tab_group.add(saveCombatJson);
		tab_group.add(loadCombatJson);
		tab_group.add(attackStartAnimInputText);
		tab_group.add(attackEndAnimInputText);
		tab_group.add(attackStartDurationStepper);
		tab_group.add(attackEndDurationStepper);
		tab_group.add(addAttack);
		tab_group.add(deleteAttack);
		tab_group.add(appendDirectionCheckBox);
		tab_group.add(chainNameInputText);
		tab_group.add(addChain);
		tab_group.add(deleteChain);
		tab_group.add(linkAttack);
		tab_group.add(unlinkAttack);
		tab_group.add(directionDropDown);
		tab_group.add(chainDropDown);
		tab_group.add(attackDropDown);
	}

	function addCharacterExtras()
	{
		characterGroup.clear();
		curEffect = null;

		character.generateCharacterExtras();

		if (character.characterSprites.members.length > 0)
		{
			character.characterSprites.forEach(function(extra:CharacterExtra)
			{
				if (curEffect == null)
					curEffect = extra;
				characterGroup.add(extra);
				extra.x = character.x;
				extra.y = character.y;
			});
		}

		characterGroup.add(character);
		characterGroup.sort(PlayState.sortByZ);
	}

	function updateEffectPositions()
	{
		for (member in character.characterSprites.members)
		{
			member.x = character.x;
			member.y = character.y;

			var animOffset:Array<Float> = [0, 0];

			if (member.animation.curAnim != null)
				animOffset = member.animOffsets.get(member.animation.curAnim.name);

			member.offset.x = member.generalOffset[0] + animOffset[0];
			member.offset.y = member.generalOffset[1] + animOffset[1];
		}
		updatePointerPos(false);
	}

	function reloadEffectDropDown()
	{
		effectDropDown.list = character.characterExtraArray;
		if (curEffect != null)
			effectDropDown.selectedLabel = curEffect.thisSprite;
	}

	function reloadEffectAnimationDropDown()
	{
		var animList:Array<String> = [];
		if (curEffect != null)
		{
			for (anim in anims)
				animList.push(anim.anim);
			if (animList.length < 1)
				animList.push('NO ANIMATIONS'); // Prevents crash
		}
		else
			animList.push('NO ANIMATIONS');

		effectAnimationDropDown.list = animList;
	}

	function reloadEffectOptions()
	{
		if (UI_characterbox == null)
			return;

		if (curEffect == null)
		{
			effectImageInputText.text = '';
			effectNameInputText.text = '';
			effectScaleStepper.value = 1;
			effectPositionXStepper.value = 0;
			effectPositionYStepper.value = 0;
			effectFlipXCheckBox.checked = false;
			effectLayerStepper.value = 0;
			effectNoAntialiasingCheckBox.checked = false;
			reloadEffectAnimationDropDown();
		}
		else
		{
			effectImageInputText.text = curEffect.imageFile;
			effectNameInputText.text = '';
			effectScaleStepper.value = curEffect.jsonScale;
			effectPositionXStepper.value = curEffect.generalOffset[0];
			effectPositionYStepper.value = curEffect.generalOffset[1];
			effectFlipXCheckBox.checked = curEffect.flipX;
			effectLayerStepper.value = curEffect.layer;
			effectNoAntialiasingCheckBox.checked = !curEffect.antialiasing;
			reloadEffectAnimationDropDown();
		}
	}

	function reloadEffectImage()
	{
		if (curEffect == null)
			return;
		var lastAnim:String = curEffect.getAnimationName();
		var anims:Array<SpriteAnimArray> = curEffect.animationsArray.copy();

		curEffect.color = FlxColor.WHITE;
		curEffect.alpha = 1;

		curEffect.frames = Paths.getMultiAtlas(curEffect.imageFile.split(','));

		for (anim in anims)
		{
			var animAnim:String = '' + anim.anim;
			var animName:String = '' + anim.name;
			var animFps:Int = anim.fps;
			var animLoop:Bool = !!anim.loop; // Bruh
			var animIndices:Array<Int> = anim.indices;
			var angle:Float = anim.angle;
			addEffectAnimation(animAnim, animName, animFps, animLoop, animIndices, angle);
		}

		if (anims.length > 0)
		{
			if (lastAnim != '')
				character.playAnim(lastAnim, true);
			else
				character.dance();
		}
	}

	inline function newEffectAnim(anim:String, name:String):SpriteAnimArray
	{
		return {
			offsets: [0, 0],
			loop: false,
			fps: 24,
			anim: anim,
			indices: [],
			angle: 0,
			finishCallback: '',
			name: name
		};
	}

	function addEffectAnimation(anim:String, name:String, fps:Float, loop:Bool, indices:Array<Int>, angle:Float = 0)
	{
		if (curEffect == null)
			return;
		if (indices != null && indices.length > 0)
			curEffect.animation.addByIndices(anim, name, indices, "", fps, loop);
		else
			curEffect.animation.addByPrefix(anim, name, fps, loop);

		if (!curEffect.hasAnimation(anim))
			curEffect.addOffset(anim, 0, 0);

		curEffect.addAngle(anim, angle);
	}

	function determineCurrentEditMode():String
	{
		var mode:String = 'character';

		switch (UI_characterbox.selectedTab.name)
		{
			case 'Effect Anim' | 'Effect':
				mode = 'effect';
			case 'Attacks':
				mode = 'attack';
		}

		return mode;
	}

	function updateCurAnim(newInt:Int)
	{
		curAnim = newInt;
		undoOffsets = null;
		curAnim = FlxMath.wrap(curAnim, 0, anims.length - 1);
		character.playAnim(anims[curAnim].anim, true);
		updateText();
	}

	// save
	function saveEffect()
	{
		if (_file != null)
			return;

		var json:SpriteFile = {
			"animations": curEffect.animationsArray,
			"image": curEffect.imageFile,
			"scale": curEffect.jsonScale,
			"global_offset": curEffect.generalOffset,
			"layer": curEffect.layer,

			"flip_x": curEffect.originalFlipX,
			"no_antialiasing": curEffect.noAntialiasing,
		};

		var data:String = PsychJsonPrinter.print(json, ['offsets', 'position', 'indices']);

		if (data.length > 0)
		{
			_file = new FileReference();
			_file.addEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data, '${curEffect.thisSprite}.json');
		}
	}

	function saveCombatFile()
	{
		if (_file != null)
			return;

		var json:Dynamic = {
			"combat_data": generateCombatFile(true)
		};

		var data:String = PsychJsonPrinter.print(json);

		if (data.length > 0)
		{
			_file = new FileReference();
			_file.addEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data, '${_char}CombatFile.json');
		}
	}

	function generateCombatFile(minimizeInfo:Bool = false):CombatFile
	{
		var attackEffectArray:Array<AttackEffectData> = [];
		for (effect in character.attackEffectMap)
			attackEffectArray.push(clearStructureNulls(effect));

		var defendEffectArray:Array<DefendEffectData> = [];
		for (effect in character.defendEffectMap)
			defendEffectArray.push(clearStructureNulls(effect));

		var soundArray:Array<SoundData> = [];
		for (sound in character.soundMap)
			soundArray.push(clearStructureNulls(sound));

		for (attack in attacks)
		{
			clearStructureNulls(attack);
			clearStructureDefaults(attack, Character.generateAttack());
		}
		for (chain in chains)
		{
			clearStructureNulls(chain);
			clearStructureDefaults(chain, Character.generateChain());
		}

		var combatFile:Dynamic =
			{
				{
					"death_soundName": null,
					"death_characterName": null,
					"idle_defaultFrame": character.idleDefaultFrame,
					"has_reflexGuard": character.hasReflexGuard,
					"death_by_stamina": character.deathByStamina,
					"default_guard_position": character.guardPosition,
					"posture_max": character.postureMax,
					"posture_recoveryCoefficient": character.postureRecoveryCoefficient,
					"combat_healthMax": character.combatHealthMax,
					"alternatingIdle": character.alternatingIdle,
					"characterExtras": character.characterExtraArray,
					"combatSoundEffects": null,
					"soundsToPickFromRandom": null,
					"soundsToVaryVolume": null,

					"attacks": attacks,
					"chains": chains,
					"attack_effects": attackEffectArray,
					"defense_effects": defendEffectArray,
					"sounds": soundArray,
					"character_sounds": character.characterSounds
				}
			}

		if (minimizeInfo)
		{
			Reflect.deleteField(combatFile, "idle_defaultFrame");
			Reflect.deleteField(combatFile, "has_reflexGuard");
			Reflect.deleteField(combatFile, "death_by_stamina");
			Reflect.deleteField(combatFile, "default_guard_position");
			Reflect.deleteField(combatFile, "posture_max");
			Reflect.deleteField(combatFile, "posture_recoveryCoefficient");
			Reflect.deleteField(combatFile, "combat_healthMax");
			Reflect.deleteField(combatFile, "alternatingIdle");
			Reflect.deleteField(combatFile, "sounds");
			Reflect.deleteField(combatFile, "character_sounds");
		}

		return clearStructureNulls(combatFile);
	}

	function loadCombatFile()
	{
		if (_file != null)
			return;

		_file = new FileReference();
		_file.addEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onCombatFileBrowseComplete);
		_file.addEventListener(Event.CANCEL, onLoadCancel);
		_file.addEventListener(IOErrorEvent.IO_ERROR, onLoadError);
		_file.browse();

		return;
	}

	function onCombatFileBrowseComplete(_):Void
	{
		if (_file == null)
			return;
		_file.removeEventListener(Event.COMPLETE, onCombatFileBrowseComplete);
		_file.addEventListener(Event.COMPLETE, onCombatFileLoadComplete);

		_file.load();
	}

	function onCombatFileLoadComplete(_):Void
	{
		if (_file == null)
			return;
		_file.removeEventListener(Event.COMPLETE, onCombatFileLoadComplete);
		_file.removeEventListener(Event.CANCEL, onLoadCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);

		var combatFile:CharacterFile = Json.parse(_file.data.toString());

		if (Type.typeof(combatFile) == TObject)
		{
			character.switchCombatJson(combatFile.combat_data);
			fillCombatData();
			updateAttackText();
			addCharacterExtras();
			FlxG.log.notice("Successfully loaded file.");
		}

		_file = null;
	}

	/**
	 * Called when the save file dialog is cancelled.
	 */
	function onLoadCancel(_):Void
	{
		if (_file == null)
			return;
		_file.removeEventListener(Event.COMPLETE, onCombatFileBrowseComplete);
		_file.removeEventListener(Event.CANCEL, onLoadCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);
		_file = null;
	}

	/**
	 * Called if there is an error while saving the gameplay recording.
	 */
	function onLoadError(_):Void
	{
		if (_file == null)
			return;
		_file.removeEventListener(Event.COMPLETE, onCombatFileBrowseComplete);
		_file.removeEventListener(Event.CANCEL, onLoadCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);
		_file = null;
		FlxG.log.error("Problem loading file");
	}

	public static function clearStructureNulls(structure:Dynamic):Dynamic
	{
		structure = Reflect.copy(structure);

		for (field in Reflect.fields(structure))
		{
			if (Reflect.getProperty(structure, field) == null)
				Reflect.deleteField(structure, field);
		}

		return structure;
	}

	public static function clearStructureDefaults(structure:Dynamic, defaultStructure:Dynamic):Dynamic
	{
		structure = Reflect.copy(structure);

		for (field in Reflect.fields(structure))
			if (Reflect.getProperty(structure, field) == Reflect.getProperty(defaultStructure, field))
				Reflect.deleteField(structure, field);

		return structure;
	}

	function fillCombatData()
	{
		curAttack = null;
		curChain = null;
		attacks = [];
		chains = [];

		for (attack in character.attackMap)
			attacks.push(attack);
		if (attacks.length == 0)
		{
			attacks.push(Character.generateAttack());
			attacks[0].name = 'NO ATTACKS';
		}

		for (chain in character.chainMap)
			chains.push(chain);

		curAttack = Character.generateAttack();
		assignAttackData(curAttack, attacks[0]);
	}

	function updateAttackOptions()
	{
		fillDropDownList('attack');
		attackNameInputText.text = '';
		attackDropDown.selectedLabel = curAttack.name;
		attackStartAnimInputText.text = curAttack.startup_animation_name;
		attackEndAnimInputText.text = curAttack.attack_animation_name;
		attackStartDurationStepper.value = curAttack.duration;
		attackEndDurationStepper.value = curAttack.recovery;
		directionDropDown.selectedLabel = curAttack.direction;
		appendDirectionCheckBox.checked = curAttack.append_direction_to_anim_name;
		fillDropDownList('chain');
		chainNameInputText.text = '';
		chainDropDown.selectedLabel = curAttack.name;

		updateAttackText();
	}

	function fillDropDownList(list:String)
	{
		var dropList:Array<String> = [];

		switch (list)
		{
			case 'attack':
				for (attack in attacks)
					dropList.push(attack.name);
				attackDropDown.list = dropList;
			case 'chain':
				for (chain in chains)
					dropList.push(chain.name);
				chainDropDown.list = dropList;
		}
	}

	function fillTempDirectionArray(isChain:Bool = false)
	{
		if (isChain)
		{
			tempDirectionArray = [];
			for (attackName in curChain.attack_chain)
			{
				if (attackName == curAttack.name)
				{
					if (curAttack.direction == 'ANY')
						tempDirectionArray.push('LEFT');
					else if (curAttack.append_direction_to_anim_name)
						tempDirectionArray.push(curAttack.direction);
					else
						tempDirectionArray.push('N/A');
				}
				else
					for (attack in attacks)
					{
						if (attack.name == attackName)
						{
							if (attack.direction == 'ANY')
								tempDirectionArray.push('LEFT');
							else if (attack.append_direction_to_anim_name)
								tempDirectionArray.push(attack.direction);
							else
								tempDirectionArray.push('N/A');
							break;
						}
					}
			}
		}
		else
		{
			if (curAttack.direction == 'ANY')
				tempDirectionArray = ['LEFT'];
			else if (curAttack.append_direction_to_anim_name)
				tempDirectionArray = [curAttack.direction];
			else
				tempDirectionArray = ['N/A'];
		}
	}

	function evaluateCurrentTempDirection(index:Int)
	{
		if (curAttack.append_direction_to_anim_name && curAttack.direction != 'NONE')
		{
			if (curAttack.direction == 'ANY')
				tempDirectionArray[index] = 'LEFT';
			else
				tempDirectionArray[index] = curAttack.direction;
		}
		else
			tempDirectionArray[index] = 'N/A';
	}

	function updateAttackAnim(newInt:Int = 0)
	{
		curAnim = newInt;
		curAnim = FlxMath.wrap(curAnim, 0, attacks.length - 1);
		chainProgress = 0;
		animateAttack(true);
		updateAttackText();
	}

	function assignAttackData(attack:AttackData, attackData:AttackData)
	{
		if (attackData == null)
			return;
		if (attack == null)
			attack = Character.generateAttack();

		attack.name = attackData.name;
		attack.startup_animation_name = attackData.startup_animation_name;
		attack.attack_animation_name = attackData.attack_animation_name;
		attack.duration = attackData.duration;
		attack.recovery = attackData.recovery;
		attack.step_based_timing = attackData.step_based_timing;
		attack.direction = attackData.direction;
		if (attackData.direction == 'NONE')
			attack.append_direction_to_anim_name = false;
		else if (attackData.direction == 'ANY')
			attack.append_direction_to_anim_name = true;
		else
			attack.append_direction_to_anim_name = attackData.append_direction_to_anim_name;
	}

	function assignChainData(chainData:ChainData, chain:ChainData)
	{
		if (chainData == null)
			return;
		if (chain == null && chain == curChain)
		{
			curChain = Character.generateChain();
			chain = curChain;
		}

		chain.name = chainData.name;
		chain.attack_chain = chainData.attack_chain;

		if (chain == curChain)
		{
			for (attack in attacks)
			{
				if (attack.name == curChain.attack_chain[curAnim])
				{
					assignAttackData(curAttack, attack);
					break;
				}
			}
			fillTempDirectionArray(true);
			animateAttack(true);
		}
	}

	function animateAttack(resetChainProgress:Bool = false)
	{
		if (resetChainProgress)
			chainProgress = 0;

		var animAttack:AttackData = Character.generateAttack();

		if (curChain != null)
			for (attack in attacks)
			{
				if (attack.name == curChain.attack_chain[chainProgress])
				{
					assignAttackData(animAttack, attack);
					break;
				}
			}
		else
		{
			assignAttackData(animAttack, curAttack);

			if (character.animation.getByName(curAttack.startup_animation_name) != null)
				attackStartDurationStepper.step = FlxMath.roundDecimal(1 / character.animation.getByName(curAttack.startup_animation_name).frameRate, 3);
			else
				attackStartDurationStepper.step = 0.042;

			if (character.animation.getByName(curAttack.attack_animation_name) != null)
				attackEndDurationStepper.step = FlxMath.roundDecimal(1 / character.animation.getByName(curAttack.attack_animation_name).frameRate, 3);
			else
				attackStartDurationStepper.step = 0.042;
		}

		var attackAnim:String = animAttack.startup_animation_name;
		if (animAttack.append_direction_to_anim_name || animAttack.direction == 'ANY')
		{
			if (curChain != null)
			{
				attackAnim += tempDirectionArray[chainProgress];
			}
			else
				attackAnim += tempDirectionArray[0];
		}

		if (animAttack.step_based_timing)
		{
			var simulatedBPM = 90;
			var stepTimerCrochet:Float = (60 / simulatedBPM) * 1000 / 4 / 1000;
			animAttack.duration = animAttack.duration * stepTimerCrochet;
			animAttack.recovery = animAttack.recovery * stepTimerCrochet;
		}

		var onActionFinish = function(tmr:FlxTimer)
		{
			var attackAnim:String = animAttack.attack_animation_name;
			if (animAttack.append_direction_to_anim_name || animAttack.direction == 'ANY')
			{
				if (curChain != null)
				{
					attackAnim += tempDirectionArray[chainProgress];
				}
				else
					attackAnim += tempDirectionArray[0];
			}

			character.playAnim(attackAnim, true);
			character.actionTimer.start(animAttack.recovery, function(tmr:FlxTimer)
			{
				if (curChain != null && chainProgress < curChain.attack_chain.length - 1)
				{
					++chainProgress;
					animateAttack();
				}
				else
					chainProgress = 0;
			});
		}

		if (animAttack.duration <= 0)
			onActionFinish(character.actionTimer);
		else
		{
			character.playAnim(attackAnim, true);
			character.actionTimer.start(animAttack.duration, onActionFinish);
		}
	}

	function updateAttackText()
	{
		animsTxt.removeFormat(selectedFormat);

		var intendText:String = '';
		var formatStart:Int = 0;
		var formatEnd:Int = 0;
		textPages = [];

		for (num => attack in attacks)
		{
			if (intendText != '')
				intendText += '\n';

			if (num == curAnim)
			{
				formatStart = intendText.length;
				intendText += attack.name;
				formatEnd = intendText.length;

				curPage = textPages.length;
			}
			else
				intendText += attack.name;

			if (num != 0 && num % 20 == 0)
			{
				textPages.push(intendText);
				intendText = '';
			}
		}
		if (intendText != '')
			textPages.push(intendText);
		intendText = '';
		for (chain in chains)
		{
			for (num => atk in chain.attack_chain)
			{
				if (intendText != '')
					intendText += '\n';

				if (curChain != null && chain.name == curChain.name && num == curAnim)
				{
					formatStart = intendText.length;
					intendText += atk;
					formatEnd = intendText.length;

					curPage = textPages.length;
				}
				else
					intendText += atk;

				if (num != 0 && num % 20 == 0)
				{
					textPages.push(intendText);
					intendText = '';
				}
			}
			textPages.push(intendText);
			intendText = '';
		}

		intendText = 'Current Page: ${curPage + 1}/${textPages.length}}\n';
		intendText += 'Current List: ${curChain != null ? 'Chain ' + curChain.name : 'Full Attack List'}\n';
		formatStart += intendText.length;
		formatEnd += intendText.length;

		animsTxt.text = intendText + textPages[curPage];
		animsTxt.addFormat(selectedFormat, formatStart, formatEnd);
	}

	function createHoverLabel(txt:FlxText, info:String, tab:String):FlxText
	{
		txt.addFormat(new FlxTextFormat(FlxColor.YELLOW), txt.text.indexOf('*'), txt.text.indexOf('*') + 1);

		labelledTextGroup.add(txt);
		labelMap.set(txt.ID, info);
		labelTabMap.set(txt.ID, tab);
		return txt;
	}

	function setupLabelSystem()
	{
		labelBackground = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		labelBackground.alpha = 0.8;
		labelBackground.cameras = [camHUD];
		labelBackground.active = labelBackground.visible = false;
		add(labelBackground);

		labelText = new FlxText(0, 0, 0, 'This is a placeholder. If you\'re seeing this, something went wrong.', 8);
		labelText.cameras = [camHUD];
		labelText.active = labelText.visible = false;
		add(labelText);
	}

	function updateLabel(newText:String)
	{
		labelBackground.active = labelBackground.visible = true;
		labelText.active = labelText.visible = true;

		labelText.text = newText;
		labelText.updateHitbox();

		var mousePoint:FlxPoint = FlxG.mouse.getScreenPosition(camHUD);

		labelText.x = mousePoint.x + 5;
		labelText.y = mousePoint.y + 20;

		if (labelText.x + labelText.width > camHUD.width)
			labelText.x -= labelText.width + 5;

		if (labelText.y + labelText.height > camHUD.height)
			labelText.y = mousePoint.y - labelText.height - 10;

		labelBackground.scale.set(labelText.width + 4, labelText.height + 4);
		labelBackground.updateHitbox();
		labelBackground.x = labelText.x - 2;
		labelBackground.y = labelText.y - 2;
	}

	function evaluateCharacterControls(elapsed:Float, shiftMult:Float, ctrlMult:Float, shiftMultBig:Float)
	{
		// CHARACTER CONTROLS
		var changedAnim:Bool = false;
		if (anims.length > 1)
		{
			if (FlxG.keys.justPressed.W && (changedAnim = true))
				curAnim--;
			else if (FlxG.keys.justPressed.S && (changedAnim = true))
				curAnim++;

			if (FlxG.keys.pressed.CONTROL)
			{
				if (FlxG.keys.justPressed.W || FlxG.keys.justPressed.S)
				{
					changedAnim = true;

					if (curAnim == 1 || curAnim % 20 != 1)
					{
						if (FlxG.keys.justPressed.W)
						{
							curAnim -= 20;
						}
						if (FlxG.keys.justPressed.S)
						{
							if (curAnim == 1)
								++curAnim;
							curAnim += 20;
						}

						if (curAnim < 0)
							curAnim = anims.length - 1;

						curAnim -= curAnim % 20;
						++curAnim;

						if (curAnim > anims.length - 1)
							curAnim = 0;
					}

					if (curAnim == 1)
						--curAnim;
				}
			}
			else if (FlxG.keys.pressed.SHIFT)
			{
				if (FlxG.keys.justPressed.W)
					curAnim -= 3;
				if (FlxG.keys.justPressed.S)
					curAnim += 3;
			}

			if (changedAnim)
			{
				undoOffsets = null;
				curAnim = FlxMath.wrap(curAnim, 0, anims.length - 1);
				character.playAnim(anims[curAnim].anim, true);
				updateText();
			}
		}

		var changedOffset = false;
		var moveKeysP = [
			FlxG.keys.justPressed.LEFT,
			FlxG.keys.justPressed.RIGHT,
			FlxG.keys.justPressed.UP,
			FlxG.keys.justPressed.DOWN
		];
		var moveKeys = [
			FlxG.keys.pressed.LEFT,
			FlxG.keys.pressed.RIGHT,
			FlxG.keys.pressed.UP,
			FlxG.keys.pressed.DOWN
		];

		var curObject:Dynamic = character;

		// Trying to simplify this by adjusting the CharacterExtra's x, y instead of using it as an offset
		// Resulted in some super weird behavior
		// So I'm just accepting that offsets probably work in some weird way and doing this more complicated solution
		var generalOffsetModifier:Array<Float> = [0, 0];

		if (currentEditMode == 'effect' && curEffect != null)
		{
			curObject = curEffect;
			generalOffsetModifier[0] = curEffect.generalOffset[0];
			generalOffsetModifier[1] = curEffect.generalOffset[1];
		}

		if (moveKeysP.contains(true))
		{
			curObject.offset.x += ((moveKeysP[0] ? 1 : 0) - (moveKeysP[1] ? 1 : 0)) * shiftMultBig;
			curObject.offset.y += ((moveKeysP[2] ? 1 : 0) - (moveKeysP[3] ? 1 : 0)) * shiftMultBig;
			changedOffset = true;
		}

		if (moveKeys.contains(true))
		{
			holdingArrowsTime += elapsed;
			if (holdingArrowsTime > 0.6)
			{
				holdingArrowsElapsed += elapsed;
				while (holdingArrowsElapsed > (1 / 60))
				{
					curObject.offset.x += ((moveKeys[0] ? 1 : 0) - (moveKeys[1] ? 1 : 0)) * shiftMultBig;
					curObject.offset.y += ((moveKeys[2] ? 1 : 0) - (moveKeys[3] ? 1 : 0)) * shiftMultBig;
					holdingArrowsElapsed -= (1 / 60);
					changedOffset = true;
				}
			}
		}
		else
			holdingArrowsTime = 0;

		if (FlxG.mouse.pressedRight && (FlxG.mouse.deltaScreenX != 0 || FlxG.mouse.deltaScreenY != 0))
		{
			curObject.offset.x -= FlxG.mouse.deltaScreenX;
			curObject.offset.y -= FlxG.mouse.deltaScreenY;
			changedOffset = true;
		}

		if (FlxG.keys.pressed.CONTROL)
		{
			if (FlxG.keys.justPressed.C)
			{
				copiedOffset[0] = curObject.offset.x - generalOffsetModifier[0];
				copiedOffset[1] = curObject.offset.y - generalOffsetModifier[1];
				changedOffset = true;
			}
			else if (FlxG.keys.justPressed.V)
			{
				undoOffsets = [
					curObject.offset.x - generalOffsetModifier[0],
					curObject.offset.y - generalOffsetModifier[1]
				];
				curObject.offset.x = copiedOffset[0] + generalOffsetModifier[0];
				curObject.offset.y = copiedOffset[1] + generalOffsetModifier[1];
				changedOffset = true;
			}
			else if (FlxG.keys.justPressed.R)
			{
				undoOffsets = [
					curObject.offset.x - generalOffsetModifier[0],
					curObject.offset.y - generalOffsetModifier[1]
				];
				curObject.offset.set(generalOffsetModifier[0], generalOffsetModifier[1]);
				changedOffset = true;
			}
			else if (FlxG.keys.justPressed.Z && undoOffsets != null)
			{
				curObject.offset.x = undoOffsets[0] + generalOffsetModifier[0];
				curObject.offset.y = undoOffsets[1] + generalOffsetModifier[1];
				changedOffset = true;
			}
		}

		var anim = anims[curAnim];
		if (changedOffset && anim != null && anim.offsets != null)
		{
			anim.offsets[0] = Std.int(curObject.offset.x) - generalOffsetModifier[0];
			anim.offsets[1] = Std.int(curObject.offset.y) - generalOffsetModifier[1];

			curObject.addOffset(anim.anim, curObject.offset.x - generalOffsetModifier[0], curObject.offset.y - generalOffsetModifier[1]);
			updateText();
		}

		var txt = 'ERROR: No Animation Found';
		var clr = FlxColor.RED;
		if (!character.isAnimationNull())
		{
			if (FlxG.keys.pressed.A || FlxG.keys.pressed.D)
			{
				holdingFrameTime += elapsed;
				if (holdingFrameTime > 0.5)
					holdingFrameElapsed += elapsed;
			}
			else
				holdingFrameTime = 0;

			if (FlxG.keys.justPressed.SPACE)
				character.playAnim(character.getAnimationName(), true);

			var frames:Int = -1;
			var length:Int = -1;

			if (!character.isAnimateAtlas && character.animation.curAnim != null)
			{
				frames = character.animation.curAnim.curFrame;
				length = character.animation.curAnim.numFrames;
			}
			else if (character.isAnimateAtlas && character.atlas.anim != null)
			{
				frames = character.atlas.anim.curFrame;
				length = character.atlas.anim.length;
			}

			if (currentEditMode == 'effect'
				&& curEffect != null
				&& curEffect.animation.curAnim != null
				&& curEffect.animation.curAnim.numFrames > length)
			{
				length = curEffect.animation.curAnim.numFrames;
				frames = curEffect.animation.curAnim.curFrame;
			}

			if (length >= 0)
			{
				if (!FlxG.keys.pressed.CONTROL && (FlxG.keys.justPressed.A || FlxG.keys.justPressed.D || holdingFrameTime > 0.5))
				{
					var isLeft = false;
					if ((holdingFrameTime > 0.5 && FlxG.keys.pressed.A) || FlxG.keys.justPressed.A)
						isLeft = true;

					character.animPaused = true;
					for (member in character.characterSprites.members)
					{
						member.animation.paused = true;
						member.animation.finishCallback = null;
					}

					if (holdingFrameTime <= 0.5 || holdingFrameElapsed > 0.1)
					{
						frames = FlxMath.wrap(frames + Std.int(isLeft ? -shiftMult : shiftMult), 0, length - 1);

						if (!character.isAnimateAtlas && frames <= character.animation.curAnim.numFrames)
							character.animation.curAnim.curFrame = frames;
						else if (frames <= character.atlas.anim.length)
							character.atlas.anim.curFrame = frames;

						for (member in character.characterSprites.members)
						{
							if (member.animation.curAnim != null)
							{
								var memberAnim = member.animation.curAnim;

								if (frames <= character.animation.curAnim.numFrames)
									memberAnim.curFrame = frames;
								else
									memberAnim.curFrame = memberAnim.numFrames;

								if (memberAnim.name == character.animation.curAnim.name)
									member.visible = true;
								switch (member.animCallbacks.get(memberAnim.name))
								{
									case 'finish':
										if (frames > memberAnim.curFrame)
											member.visible = false;
									case 'toLoopAnim':
										// So fun fact:
										// Using modulo with a modulus/divisor higher than the dividend returns the dividend
										// In other words this perfectly loops the frames if it creeps higher than the sprite's max frame count
										memberAnim.curFrame = frames % memberAnim.curFrame;
									case 'fade':
										// This is a placeholder for when effect finishes are softcoded better
										member.alpha = 1 - (FlxEase.quadIn((frames / memberAnim.frameRate)) / 0.05);
										// FlxTween.tween(member, {alpha: 0}, 0.05, {ease: FlxEase.quadIn});
								}
							}
						}

						holdingFrameElapsed -= 0.1;
					}
				}

				txt = 'Frames: ( $frames / ${length - 1} )';
				// if(character.animation.curAnim.paused) txt += ' - PAUSED';
				clr = FlxColor.WHITE;
			}
		}

		if (txt != frameAdvanceText.text)
			frameAdvanceText.text = txt;
		frameAdvanceText.color = clr;
	}

	// End of changes
}
