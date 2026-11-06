{ Global variables: the game's variables in the data segment, in address order. A new section starts wherever the data
  needs a word boundary. }
unit GDVars;

interface

uses Types;

{ Start-up and the script interpreter's run state: the title menu's answer, the copy-protection check's loop, and what
  CallEclScript carries between commands. }
var
  { the title menu's answer; 1 starts the demo }
  menuResult: Byte;
  { FixMain's loop over the four copy-protection marks }
  checkIdx: Byte;
  { EXIT and NEWECL end CallEclScript's loop }
  eclStop: Byte;
  { NEWECL loaded a script, run its entries afresh }
  newEclFlag: Byte;
  { LOAD CHARACTER moved currentCharacter }
  restoreCharacter: Byte;
  { LOAD FILES or LOAD PIECES ran this script }
  filesLoaded: Byte;
  { LOAD PIECES ran; with mapLoaded, the overland map is redrawn when the script ends }
  piecesLoaded: Byte;
  { a map was loaded this script }
  mapLoaded: Byte;
  { LOAD MONSTER stops at 63 creatures }
  loadedMonsterCount: Byte;
  { what restoreCharacter puts back }
  savedCharacter: Types.PCharacter;

{ Post-combat resolution: the flags PostCbt carries between its own steps, and the shop menu's redraw flag. }
var
  { set when the fight ended with the monsters dead }
  monstersKilled: Byte;
  { the party ran from the fight }
  partyFled: Boolean;
  { the treasure left holds coins }
  treasureHasMoney: Boolean;
  { the treasure left holds items }
  treasureHasItems: Boolean;
  { ShopBuyMenu sets it to 1 after drawing its frame and passes it to MenuCore.MenuVertical by reference }
  menuFlag: Byte;

{ The combat AI's per-turn step state in AiMoveAttack. }
var
  { the direction the last step took }
  lastMoveDirection: Byte;
  { how many times a step has been refused }
  stuckCount: Byte;
  { cleared each turn and never read }
  aiInitByte: Byte;

{ The arena generator's working state: the free-cell map and the per-side anchors FindPlacement walks, the 3-D cell
  BuildDungeonArena is laying out and its four classified edges. }
var
  { free cells by side, group, row, column }
  combatOccupancy: array[0..1, 0..3, 0..5, 0..10] of Byte;
  { placement anchor by side, its column }
  combatXByPlane: array[0..1] of ShortInt;
  { and its row }
  combatYByPlane: array[0..1] of ShortInt;
  { by side, the placement tries before the search gives up; sized from teamCount }
  placementAttemptLimits: array[0..1] of ShortInt;
  { facing div 2 by side }
  combatHalfDirections: array[0..1] of ShortInt;
  { the 3-D cell being laid out, -6..6 }
  combatOriginX: ShortInt;
  { -2..2 }
  combatOriginY: ShortInt;
  { the cell's first edge as BuildDungeonArena classifies it; 1 is open }
  edgeA: Byte;
  { the second edge, classified the same way }
  edgeB: Byte;
  { the third edge }
  edgeC: Byte;
  { the fourth edge }
  edgeD: Byte;
  { the side being placed }
  combatPlane: ShortInt;

{ The arena's features: what the dungeon cell allows and the combat tile drawn for the active combatant. }
var
  { into combatantTiles; 15 by default }
  activeCombatantIndex: Byte;
  { the $40 bit of the cell's map event }
  featureSource: Byte;
  { whether the cell's edges let features be placed }
  allowFeatures: Byte;
  { never read or written }
  allowFeaturesTail: array[0..3] of Byte;

{ InitializeGame's own working storage: its loop index, the mouse sample it takes to decide whether the driver scales,
  and the ITEMS file it reads baseItems from. }
var
  { InitializeGame's loop index }
  initIndex: Byte;
  { never read or written }
  initIndexTail: array[0..2] of Byte;
  { whether OpenWithRetry found ITEMS }
  itemsOk: Boolean;
  { never read or written }
  itemsOkTail: array[0..42] of Byte;
  { the buttons of the mouse sample GetMouse returns }
  mouseButtons: Integer;
  { the sample's x }
  mouseSampleX: Integer;
  { the sample's y }
  mouseSampleY: Integer;
  { ITEMS, read once into baseItems }
  itemsFile: file;
  { never read or written }
  itemsFileTail: Byte;

{ The character sheet and the spell menu: the character DisplayChar shows, the effect timers by party slot, and the
  spell menu's rows and the two counters the damage and duration services carry between their steps. }
var
  { DisplayChar takes it from currentCharacter before it draws the sheet; every sub-menu reads it back }
  viewedCharacter: Types.PCharacter;
  { by party slot, whether that character still has an effect with time left; in camp TimeOutEffects skips the clear
    ones }
  effectsRunning: array[1..72] of Byte;
  { the spell menu's rows }
  spellListHead: Types.PMenuRow;
  { per row, memorized copies }
  entryCopies: array[0..73] of Byte;
  { per row, the spell id }
  entrySpellIds: array[0..73] of Byte;
  { per row, the scroll it came from }
  entryScrolls: array[0..48] of Types.PItem;
  { how many rows came from scrolls }
  entryScrollCount: Byte;
  { hit dice left, or strength, or odds }
  spellBudget: Byte;
  { the target's hit dice, or level }
  spellCost: Byte;

{ The configurator: what GameBoot keeps while it asks for the adapter, sound and save paths and writes DKK.CFG, and the
  two directories OpenWithRetry swaps between. }
var
  { what the character's carried items weigh: RecalcStats clears it and sums the chain into it, and never reads it
    back }
  equippedWeight: Word;
  { the Tandy reserve's ceiling, which becomes HeapEnd }
  tandyFreeBlock: Pointer;
  { the digit key last read }
  configKey: Char;
  { the menu answer ReadMenuChoice returns }
  menuChoice: Byte;
  { DKK.CFG }
  configFile: Text;
  { never read or written }
  configFileTail: array[0..127] of Byte;
  { IOResult after opening DKK.CFG }
  configIoError: Byte;
  { the configurator's loop index }
  configIndex: Byte;
  { the save path as typed }
  enteredPath: String[80];
  { the program name, as FSplit returns it }
  exeName: String[8];
  { the program's extension, as FSplit returns it }
  exeExt: String[4];
  { the save path offered when nothing is typed }
  defaultPath: String[79];
  { 1 once the Tandy adapter is chosen }
  tandySelected: Byte;
  { the directory the EXE runs from; OpenWithRetry swaps it with masterPath when a file is missing }
  dataPath: String[67];
  { the other directory, or the other floppy drive }
  masterPath: String[67];
  { the drive letter the retry prompt names }
  masterDrive: Char;

{ The resident music driver's entry, the play session's options and flags, the video adapter, the deferred-render span
  list and row tables Blit draws through, and the sound and music state. }
var
  { the driver's entry as StartDriver computes it }
  driverDispatch: Types.TDrvProc;
  { the offset of the parameter block DriverCall passes }
  driverParamsOfs: Word;
  { its segment }
  driverParamsSeg: Word;
  { the last DriverCall's result }
  driverStatus: Word;
  { the offset of the argument the next DriverCall passes }
  driverArgOfs: Word;
  { its segment }
  driverArgSeg: Word;
  { DriverData's operand word inside SOUNDDRV.OBJ, so SoundCommand(15) can write the loop count }
  driverDataPtr: Pointer;
  { set once the game loop owns the screen; HeapErr saves before it exits while it is set }
  gameUp: Byte;
  { the first of the four script memory zones GameInit allocates: the area's state }
  zone0: Types.PZone0;
  { the zone the script variable indices address }
  zone1: Types.PZone1;
  { the third zone, which EclMenu, GameInit and SaveLoad use }
  zone2: Types.PZone2;
  { the fourth zone, which EclMenu, EclVm and GameInit use }
  zone3: Types.PZone3;
  { the game speed, 0..9 }
  textDelay: Byte;
  { the five script entry points }
  eclEntryPoints: Types.TEclEntryPoints;
  { where the script runs now }
  eclIp: Word;
  { never read or written }
  eclIpTail: array[0..3] of Byte;
  { 3 the overland map, 4 the 3-D view, 5 combat }
  interfaceState: Byte;
  { the state before the last change }
  previousInterfaceState: Byte;
  { the title menu chose the demo }
  demoMode: Byte;

{ The play options and flags the main loop, SaveLoad, CharGen and EclVm read between turns. }
var
  { saved with the game as bit 1 of zone0^.savedOptions }
  picturesEnabled: Byte;
  { a big picture fills the view }
  bigPictureShown: Byte;
  { saved with the game as bit 0 of zone0^.savedOptions }
  animationsEnabled: Byte;
  { whether an encounter shows the monster's picture }
  monsterPictures: Byte;
  { the developer trace, toggled from the keyboard }
  traceActive: Byte;
  { a saved game was just loaded }
  loadedSave: Byte;
  { counted by GameTime while the party rests }
  restTicks: Word;
  { set when no party member can act }
  partyDefeated: Byte;
  { ends the script loop so the game restarts }
  restartLoop: Byte;
  { trains without asking which character }
  autoTraining: Byte;
  { the slow text-speed switch }
  slowText: Byte;
  { the register block every BIOS video and mouse call goes through }
  videoRegs: Types.TRegisters;
  { the segment of the display page being drawn; TextRend flips it with otherPageSegment }
  currentPageSegment: Word;
  { the segment of the page on screen }
  otherPageSegment: Word;
  { the EGA page on screen, which GameBoot sets up }
  otherEgaPage: Byte;
  { the EGA page being drawn }
  currentEgaPage: Byte;
  { the mode the adapter was in at start-up }
  savedVideoMode: Byte;
  { the mode it is in now }
  currentVideoMode: Byte;
  { as DKK.CFG chose it; GameBoot sets it }
  displayMode: Types.TVideoMode;

{ The drawing buffers: the composite, the save-under, the span list and the per-adapter row tables. }
var
  { the off-screen image Blit and the drawing units compose into }
  compositeBuffer: Types.PImgBuf;
  { the copy Blit and CharHlp keep under a menu }
  saveUnder: Types.PImgBuf;
  { never read or written }
  saveUnderTail: array[0..15] of Byte;
  { by span of the deferred-render list, whether it is live; BLIT.OBJ declares the four span arrays EXTRN, Blit fills
    and drains them, GameInit and MapCurs clear them }
  spanActive: array[0..167] of Byte;
  { by span, its scan line }
  spanY: array[0..167] of Word;
  { by span, its first column }
  spanX0: array[0..167] of Word;
  { by span, its last column }
  spanX1: array[0..167] of Word;
  { never read or written }
  spanX1Tail: array[0..671] of Byte;
  { by scan line, the CGA bank segment; GameInit computes it once }
  cgaRowSeg: array[0..199] of Word;
  { by scan line, the offset in the frame buffer }
  fbRowOfs: array[0..199] of Word;
  { by scan line, the Tandy bank segment }
  tandyRowSeg: array[0..199] of Word;
  { GameInit sets it to 1; never read }
  soundInitByte: Byte;

{ Sound and music: the sound mode DKK.CFG chose, the music driver and data Music loads, and which driver is installed. }
var
  { 0 C/MS, 2 Adlib, 3 Tandy, 4 PC, 5 silent }
  soundMode: Byte;
  { soundMode as SoundDrv found it }
  savedSoundMode: Byte;
  { GameIo's music toggle }
  musicOn: Byte;
  { never read or written }
  musicOnTail: array[0..7] of Byte;
  { the resident driver's image as a far address }
  musicDriverImage: LongInt;
  { its size in bytes }
  musicDriverSize: Word;
  { the music data Music loaded }
  musicData: Pointer;
  { its size in bytes }
  musicDataSize: Word;
  { soundActive as DaxIo saves it around a disk read }
  savedSoundActive: Byte;
  { 0 none, 1 SoundDrv's, 2 MusDrv's music driver }
  soundActive: Byte;
  { the music driver is in memory }
  musicDriverLoaded: Byte;
  { the heap buffer the driver lives in }
  musicDriverBuf: Types.PBytes;
  { the heap buffer the music data lives in }
  musicDataBuf: Types.PBytes;
  { the disk whose music is playing }
  currentMusic: Byte;

{ The disks and saves, the base items and templates, the party's live pointers, the text renderer's font and cursor, the
  symbol and icon images, and the combat arena's records. }
var
  { the disk the game last asked for }
  diskNumber: Byte;
  { the one before it; DaxIo swaps the two and save files carry them }
  previousDisk: Byte;
  { DKK.CFG's directory for this game's saves }
  savePath: String;
  { DKK.CFG's directory for imported characters }
  championsSavePath: String;
  { DaxIo hands it to OpenWithRetry as its noPrompt }
  suppressDisk: Byte;
  { set after a save; HeapErr's save loop ends on it and CharGen's quit asks to save while it is clear }
  recentlySaved: Byte;
  { by item kind, filled from ITEMS with one BlockRead }
  baseItems: array[0..128] of Types.TBaseItem;
  { the member a click in the party panel picked }
  mouseCharacter: Types.PCharacter;
  { the party-list line CharHlp draws bright }
  highlightedCharacter: Types.PCharacter;
  { the member on the other side of a Trade }
  tradeCharacter: Pointer;
  { the one every command acts on }
  currentCharacter: Types.PCharacter;
  { the first party member; next links the rest }
  partyHead: Types.PCharacter;
  { by item kind, loaded from ITEM0.DAX; a slot whose itemType is 255 is empty }
  itemTemplates: array[1..254] of Types.TItemTemplate;
  { the last thrown-weapon copy appended }
  prevTreasure: Types.PItem;
  { DaxIo's delete and rename go through it; nothing is read or written }
  scratchFile: file;
  { the count BlockRead returns for ITEMS, never inspected }
  itemsRead: Word;
  { the font TextRend loads }
  gameFont: Types.PFontArr;
  { the rows of the glyph being drawn; TEXTREND.OBJ declares it EXTRN }
  currentGlyph: array[0..7] of Byte;
  { the message window's cursor column }
  currentColumn: Byte;
  { its row; TextRend advances it }
  currentRow: Byte;
  { never read or written }
  currentRowTail: array[0..19] of Byte;
  { the five 8x8 symbol sets Sym8x8 loads }
  symbolSets: array[0..4] of Types.PImgBuf;
  { the one-cell image Put8x8Sym copies a symbol into }
  symbolScratch: Types.PImgBuf;
  { what the overland party marker covers }
  viewCapture: Types.PImgBuf;
  { that cell with the marker drawn over it }
  viewComposite: Types.PImgBuf;
  { the combat tile sheet, a Blit image }
  tileSheet: Types.PImgBuf;
  { by icon slot and frame, Blit images }
  iconAnimations: array[0..34, 0..1] of Types.PImgBuf;
  { the tile sheet holds the dungeon tile set }
  dungeonCombatLoaded: Byte;
  { the tile sheet holds the wilderness tile set }
  wildernessCombatLoaded: Byte;
  { combatants in the fight }
  creatureCount: Byte;
  { by combat slot }
  arenaLoc: array[1..72] of Types.TArenaLoc;
  { by combat slot, arenaLoc.x less the view origin }
  gridX: array[1..72] of ShortInt;
  { by combat slot, arenaLoc.y less the view origin }
  gridY: array[1..72] of ShortInt;
  { creature slot per cell, 0 empty }
  arenaIndex: array[0..24, 0..49] of Byte;
  { by combat slot }
  creatures: array[1..72] of Types.PCharacter;
  { the fallen, in the order they fell }
  downed: array[1..8] of Types.TDownedRec;
  { how many entries of downed are filled }
  downedCount: Byte;
  { the arena CombatSt builds }
  arena: Types.PArena;
  { how many entries Pathing.BuildTargetList left }
  targetCount: Byte;
  { the targets it found, nearest first; CharHlp and FxEngine save and restore the list whole }
  targetList: array[1..72] of Types.TTargetEntry;

{ The treasure pool, the effect engine's working state, the 3-D view's images and map, and the picture box. }
var
  { steel, gems, jewelry in the pool }
  pooledMoney: array[4..6] of LongInt;
  { the list the party is taking from }
  treasureItems: Types.PItem;
  { by side, as character.side indexes it }
  teamCount: array[0..1] of Byte;
  { the saving throw's roll }
  currentSaveRoll: Byte;
  { the effect being applied }
  currentEffectId: Byte;
  { the damage being dealt }
  currentDamage: Byte;
  { the elements the attack carries }
  elementMask: Byte;
  { the attack rate CbtActs adjusts }
  adjustedAttackRate: Byte;
  { CharHlp's recomputed rate, doubled }
  movementRate: Byte;
  { into spellTable }
  currentSpellIndex: Byte;
  { the dice the damage rolls }
  currentDiceCount: Byte;
  { never read or written }
  currentDiceCountTail: Byte;
  { CbtActs zeroes it; never read }
  attackInitByte: Byte;
  { the target refused the effect }
  targetRefused: Byte;
  { 1 while removing an effect keeps EffHndlr from adding one }
  effectLock: Byte;
  { an area spell is being resolved }
  areaSpellActive: Byte;
  { Magic raises it, ViewChar clears it }
  redrawInventory: Byte;
  { the d20, 100 on a natural 20 }
  currentAttackRoll: ShortInt;
  { hits made by each attack form }
  hitsMade: array[1..2] of Byte;
  { the morale CombatAi weighs }
  moraleValue: Byte;
  { the record a handler acts on }
  effectTarget: Types.PCharacter;
  { the saving throw's type }
  currentSaveType: Byte;
  { whether it was made }
  currentSaveResult: Boolean;
  { a handler per effect id plus the item handler }
  effectServices: Types.TEffectServices;
  { the wall slice and WALLDEF images }
  wallTileBuf: Pointer;
  { the geometry View3D reads walls from }
  dungeonMap: Types.PGeoMap;
  { the sky's palette entry, which MapView sets and FixMain reads }
  paletteSky: Byte;
  { the ceiling's palette entry }
  paletteCeil: Byte;
  { the floor's palette entry }
  paletteFloor: Byte;
  { the walls' palette entry }
  paletteWall: Byte;
  { the automap is on }
  automapOn: Byte;
  { the party's map position and facing }
  mapState: Types.TMapState;
  { the slots LoadWallSet fills }
  loadedWallSets: array[0..3] of Types.TWallSet;
  { the 3-D view's backdrop, which GameInit allocates }
  backdrop: Types.PImgBuf;
  { the daytime sky and ground }
  skyGround: Types.PImgBuf;
  { the evening sky }
  eveningSky: Types.PImgBuf;
  { the picture box's frames }
  portraitAnimation: Types.TAnimRec;
  { PIC, SPRIT or CPIC }
  pictureArchiveName: String[8];
  { Camp reloads this animation after camp }
  savedPictureName: String[8];
  { what Portrait.LoadAnimation holds }
  pictureArchiveId: Byte;
  { the picture Camp reloads }
  savedPictureId: Byte;
  { the loaded BIGPIC image }
  bigPic: Types.PImgBuf;
  { its number }
  bigId: Byte;

{ The menu state MenuCore keeps between a menu going up and a choice coming back. }
var
  { the party-panel pick CharHlp.SelectChar waits on }
  selectionMode: Byte;
  { the one a mouse click picked }
  selectionCharacter: Types.PCharacter;
  { the vertical menu's first row }
  menuVerticalTop: Integer;
  { the menu's answer }
  selectedChoice: Byte;
  { the answer came from an extended key }
  menuExtendedKey: Byte;
  { the mouse moved the choice }
  menuClickChanged: Byte;
  { ticks before a horizontal menu answers itself }
  menuTimeout: LongInt;
  { the key it answers with }
  menuTimeoutKey: Byte;
  { the screen row of each vertical-menu line, 255 past the end }
  menuHotRows: array[1..25] of Byte;
  { the vertical menu's left column; 127 when none is up }
  verticalMenuLeft: ShortInt;
  { its right column; -128 when none is up }
  verticalMenuRight: ShortInt;
  { the party list's left edge, which CharHlp sets as it draws; a click inside the box picks a character }
  partyPanelLeft: Byte;
  { its right edge }
  partyPanelRight: Byte;
  { its top row }
  partyPanelTop: Byte;
  { its bottom row }
  partyPanelBottom: Byte;
  { CharGen's modify-screen click row }
  modifyMouseRow: Byte;
  { Camp and CbtActs store 255 before a horizontal menu }
  menuResetByte: Byte;
  { in menu order; 255 fills the unused slots }
  enabledChoices: array[0..19] of Types.TEnabledChoice;
  { the menu words' color, which GameInit sets }
  menuItemColor: Byte;
  { the prompt's color }
  menuLabelColor: Byte;
  { the hotkey letters' color }
  menuHighlightColor: Byte;

{ The spell system's state, what Magic keeps between a spell being chosen and its effect landing. }
var
  { the scroll whose spells Magic lists }
  scroll: Types.PItem;
  { the selector and 114 handlers }
  spellServices: Types.TSpellServices;
  { how many targets, the targets and the one picked outside combat }
  spellTargetState: Types.TSpellTargetState;
  { the column of the cell a spell or attack is aimed at }
  targetX: Byte;
  { its row }
  targetY: Byte;
  { the spell clouds on the arena }
  cloudList: Types.PCloudNode;
  { set while a spell is cast from an item }
  usingItem: Byte;
  { the treasure pool still holds money }
  treasureActive: Byte;

{ The rest clock and the redraw flags. }
var
  { seven units, each carrying into the next }
  restTime: Types.TClock;
  { by party slot, ticks until the next spell }
  spellPrepTimers: array[1..8] of Byte;
  { counted to 288 before a resting party heals a point }
  healTicks: Word;
  { the message window starts one row lower }
  noBorder: Byte;
  { a character aged; the party list is redrawn }
  agePassFlag: Byte;
  { MapView redraws the overland picture }
  forceMapRedraw: Byte;

{ The effect handler override. }
var
  { FxEngine.CallEffectHandler calls the item handler instead of the effect's own }
  handlerOverrideActive: Byte;

{ The camp and party commands' modes, which sub-command the player is in the middle of. }
var
  { 1 this game's files in savePath, 0 imported ones in championsSavePath }
  fileFormat: ShortInt;
  { ends CharGen's training loop }
  trainingDone: Byte;
  { lets everyone train }
  testTrainMode: Byte;
  { the modify-character screen is up }
  modifyActive: Byte;
  { a clerical spell list is being memorized; Magic reads it as its redraw }
  specialSpellSelection: Byte;

{ The camp's spell slots and rest, the combat round and turn, the dungeon color selectors, and the ECL interpreter's
  registers and operands. }
var
  { the extra mage slots Camp allows }
  bonusSpellSlots: Byte;
  { Camp sets it around a rest for GameTime }
  campRestActive: Boolean;
  { a party member struck one of its own }
  attackedAlly: Byte;
  { where the fight is }
  roundNumber: Byte;
  { 15 past the last attack's round; the fight ends there }
  roundLimit: Byte;
  { CharHlp.CountTargets' combat slots }
  targetIndices: array[1..72] of Byte;
  { by attack form }
  attacksMade: array[1..2] of Byte;
  { the monsters' hit points left, in fives }
  hostileHpPercent: Byte;
  { the fight's magic switch }
  magicOn: Byte;
  { the attack is over }
  attackDone: Byte;
  { never read or written }
  attackDoneTail: array[0..3] of Byte;
  { the animated combatant's icon facings }
  movingIcon: Types.PImgBuf;
  { never read or written }
  movingIconTail: Byte;
  { the aim cursor's column }
  cursorX: ShortInt;
  { its row }
  cursorY: ShortInt;
  { the aim cursor is up }
  cursorActive: Byte;
  { which edges a placed party may face, from the script }
  combatDirectionFlags: Byte;
  { the move menu is up }
  inMoveMenu: Byte;
  { the creature a Yell is aimed at }
  yellTarget: Pointer;
  { the move menu's choice }
  movementOption: Byte;
  { the combat panel needs a redraw }
  combatInfoDirty: Byte;
  { the active combatant is drawn }
  showTurn: Byte;
  { the round's initiative order, Combat.OrderCreatures }
  combatOrder: array[1..72] of Types.PCharacter;
  { where the round is in combatOrder }
  turnIndex: Byte;
  { the wall color selector }
  wallColorSet: Byte;
  { the ceiling and floor color selector }
  ceilingFloorColorSet: Byte;
  { never read or written }
  ceilingFloorColorSetTail: array[0..5] of Byte;
  { the newer of the two return pointers a script call pushes }
  eclStack: Types.PEclStack;
  { the older }
  eclStackPrev: Types.PEclStack;
  { = <> < > <= >= of the last comparison }
  cmpFlags: array[0..5] of Boolean;
  { the opcode before curOpcode }
  previousOpcode: Byte;
  { the opcode being run }
  curOpcode: Byte;
  { never read or written }
  curOpcodeTail: Byte;
  { the sprite of the monster a script has in hand }
  monsterSpriteId: Byte;
  { its picture }
  monsterPictureId: Byte;
  { the icon it animates }
  iconAnimation: Byte;
  { never read or written }
  iconAnimationTail: array[0..128] of Byte;
  { operand n's kind: 0 a byte, 2 a word, 1 and 3 a byte or word at an address, $80 a packed string, $81 a string at an
    address }
  varTypes: array[0..63] of Byte;
  { operand n's high byte }
  varHi: array[0..63] of Byte;
  { operand n's low byte }
  varLo: array[0..63] of Byte;

{ The ECL command's string operands, and what a script leaves for the engine and a fight leaves for the script. }
var
  { the breath-weapon aim Magic's target selector returns }
  breathAim: Byte;
  { the global for-loop counter; EclVm stores 1 to it }
  loopIndex: ShortInt;
  { the current command's string operands }
  gbStrings: array[1..10] of String;
  { never read or written }
  gbStringsTail: array[0..2559] of Byte;
  { [0] sprite shown, [1] picture shown }
  monsterFlags: Types.TMonFlags;
  { never read or written }
  monsterFlagsTail: Word;
  { what the sound CALL switches on; never written }
  callSoundMode: Word;
  { never read or written }
  callSoundModeTail: array[0..3] of Byte;
  { the party-panel status cell is filled }
  statusCellWritten: Byte;
  { the party-panel name cell is filled }
  nameCellWritten: Byte;
  { Vault, Shop and Temple set it so CharHlp draws the inset picture }
  noncombatPrepared: Byte;

{ What PostCbt counts as a fight ends. }
var
  { the mirror duel a script arranged }
  duelFlag: Byte;
  { combatants drawn without animation }
  nonAnimCount: Byte;
  { each survivor's share of the experience }
  expShare: LongInt;
  { the party won }
  combatWon: Boolean;

{ The ECL interpreter's flags between commands, and the overlay reader start-up sets aside. }
var
  { the script running; View3D reads it too }
  currentScriptId: Byte;
  { the search flag before the script changed it }
  savedSearchFlag: Byte;
  { the 3-D box was cleared this command }
  boxCleared: Byte;
  { the newline PRINT RETURN owes }
  printReturnFlag: Byte;
  { a script may draw }
  eclGraphics: Byte;
  { the copy-protection picture is up }
  protectionShown: Byte;
  { a sprite is up }
  spriteShown: Byte;
  { the bottom-message handshake with Explore }
  bottomClear: Byte;
  { an EclMenu variable write changed the wall colors; MapView redraws }
  wallColorsChanged: Byte;
  { an EclMenu variable write moved the party }
  partyMoved: Boolean;
  { monsters were loaded this script }
  monstersLoaded: Byte;
  { the sky changed }
  skyChanged: Boolean;
  { the encounter menu is up }
  inEncounterMenu: Byte;
  { LOAD CHARACTER found no match }
  characterNotFound: Byte;
  { CharHlp sets it too }
  noncombatRedrawState: Byte;
  { GameInit clears it; never read }
  eclInitByte: Byte;
  { the extended-key mode CharHlp, CombatSt, MenuCore and Explore share }
  extendedMode: Byte;
  { undead among the loaded monsters; the cap on turn-undead tries }
  undeadCount: Byte;
  { never read or written }
  joystickZoneKeysTail: array[0..4] of Byte;
  { the overlay manager's own reader, which GameIo.OverlayReadWithBeep retries }
  savedOvrRead: Types.TOverlayReadFunc;

{ The overland party marker. }
var
  { GameInit clears it; never read }
  markerInitByte: Byte;
  { the 8x8d1 cell MapCurs draws over the captured map cell }
  cursorImage: Types.PImgBuf;

{ The debug password and the copy-protection stage marks. }
var
  { copied from the game's text; Explore and CbtActs compare it with ParamStr(2) }
  debugPassword: String[20];
  { Indexed by CopyProt's stage constants, 1 to 4; FixMain aborts unless all four are set. }
  protectionMarks: array[1..4] of Byte;

{ The mouse. }
var
  { while it is clear Mouse halves the driver's x for a 320-column mode }
  mouseScaled: Boolean;
  { MenuCore tests it; CharHlp and ViewChar save it around a prompt }
  mouseMode: Byte;
  { from DKK.CFG; CharGen toggles it }
  mousePresent: Byte;
  { the click GameIo stores }
  mouseClick: Byte;
  { the driver's button count }
  mouseButtonCount: Byte;
  { the driver's pixel x }
  mouseRawX: Integer;
  { the driver's pixel y }
  mouseRawY: Integer;
  { the x GameInit writes; CharGen saves the four words together }
  mouseCurrentX: Integer;
  { the y GameInit writes }
  mouseCurrentY: Integer;
  { the CGA or EGA cursor mask handed to Mouse.SetMouseCursor }
  activeCursorMask: Pointer;

{ The joystick. }
var
  { both sticks; only stick 1 is ever calibrated }
  joyCalib: array[1..2] of Types.TJoyCal;
  { the joystick is in use }
  joystickActive: Byte;
  { the center's x, 160 at start }
  joystickCenterX: Integer;
  { the center's y, 100 at start }
  joystickCenterY: Integer;

{ The item slot pool and the vault. }
var
  { GameIo.AllocSlot hands these out; a slot whose itemType is clear is free }
  itemPool: array[1..128] of Types.TItem;
  { the vault's contents are in tmpvault.dat alone }
  vaultPending: Byte;
  { the save letter whose vault<letter>.dat is the vault }
  vaultLetter: Char;
  { SaveLoad and ViewChar walk and append the vault's items with it }
  vaultCursor: Types.PItem;

implementation

end.
