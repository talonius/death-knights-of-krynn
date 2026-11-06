{ Types -- the types the units share. First the string lengths several units pass. The combat types: TIconDelta and
  TTerrain, the parts of GDConsts' direction, terrain and icon tables; the arena records (TArenaLoc, TDownedRec,
  TTargetEntry and the TArena its arena points at); TCombat, each creature's per-fight block behind TCharacter.combat;
  and TCloudNode, the spell clouds on GDVars.cloudList. Then the character record, TCharacter: every party member and
  every combat creature. GDVars.partyHead is the first one and next links the rest; CharGen allocates and frees it. With
  it are TEffect, the active effects TCharacter.effects links, the item and spell records, and the shapes of tables
  elsewhere: the race limits, ages and race classes, the class progression and the party menu. The item records are
  TItem, the carried item that the item slot pool, the treasure and vault lists and characters' inventories link through
  next; TBaseItem, the per-kind record of GDVars.baseItems; and TItemTemplate, the record of GDVars.itemTemplates, which
  is TItem from itemType on. The spell records are TSpell, one row of GDConsts.spellTable per spell id, and TSpellBlock,
  the spells TCharacter.spells points at. Last come the script zones, TZone0 through TZone3; TWallSet, one entry of
  GDVars.loadedWallSets; the picture buffer Blit loads, draws and frees (TImgBuf, with its color map); the portrait
  animation, TAnimRec; and TMonFlags, the monster flags. After them come the types of the units' shared state: Blit's
  color table, the mouse cursor mask, Pathing's line walk (TPathReq), MenuCore's menu rows (TMenuRow), the game clock
  (TClock), the display adapter (TVideoMode), the script's return stack (TEclStack), the party's map position
  (TMapState) and the GEO block View3D draws from (TGeoMap). }
{$F+,A-}
unit Types;
interface
type
  { the string lengths the units share }
  TString2 = String[2];
  TString8 = String[8];
  TString40 = String[40];
  TString80 = String[80];
  TIconDelta = record dx: ShortInt; dy: ShortInt end;
  TTerrain = record cost: Byte; clearance: Byte; blocking: Byte; code: Byte end;
  { where a combatant stands; size 0 = off the field }
  TArenaLoc = record
    x: ShortInt;
    y: ShortInt;
    aux: Byte;
    size: Byte;
  end;
  { a fallen party member's body }
  TDownedRec = record cr: Pointer; x: ShortInt; y: ShortInt; terrain: Byte end;
  { what Pathing.BuildTargetList leaves in targetList }
  TTargetEntry = record
    { the combat slot, creatures[] }
    characterIndex: Byte;
    { in half cells }
    distance: Byte;
    { 0..7 }
    direction: Byte;
  end;
  PArena = ^TArena;
  { the combat map arena points at }
  TArena = record
    oxLead: array[0..1] of Byte;
    { the view's origin cell }
    ox: ShortInt;
    oy: ShortInt;
    { the icon overlay the target cursor draws }
    cursorOn: Byte;
    cursorSize: Byte;
    { 1: Pathing.WalkLine ignores terrain blocking }
    distMode: Byte;
    { terrain index per cell }
    cells: array[0..24, 0..49] of Byte;
  end;
  PCombat = ^TCombat;
  { one per creature for the fight; TCharacter.combat }
  TCombat = record
    spellCast: Byte;
    canCast: Byte;
    canUseItem: Byte;
    initiative: ShortInt;
    { which attack count is in use; foes a sweep may take }
    attackForm: Byte;
    sweepTargets: Byte;
    movement: Byte;
    guarding: Byte;
    attacked: Byte;
    direction: Byte;
    { the PCharacter it is after }
    target: Pointer;
    dyingTurns: Byte;
    attacksTaken: Byte;
    panicked: Byte;
    turnAttempts: Byte;
    attackAngles: Byte;
    { 1 for a monster }
    notPcNpc: Byte;
    fleeing: Byte;
    aiStance: Byte
  end;
  PItem = ^TItem;
  TItem = record
    name: String[40];
    inUse: Byte;
    next: PItem;
    itemType: Byte;
    nameIds: array[1..3] of Byte;
    plus: ShortInt;
    saveBonus: ShortInt;
    equipped: Byte;
    unidentifiedMask: Byte;
    cursed: Byte;
    weight: Word;
    quantity: Byte;
    value: Word;
    case Byte of
      0: (charges: Byte; effect: Byte; special: Byte);
      { a scroll's spell ids; bit 7 set while it is being scribed }
      1: (scrollSpells: array[1..3] of Byte)
  end;
  { The character record, for every party member and combat creature, with its effect list. The combat block is TCombat,
    above; the spell block is an untyped pointer. }
  TStatPair = record base: Byte; current: Byte end;
  PSpellBlock = ^TSpellBlock;
  TSpellBlock = record
    { spell ids, bit 7 set until a rest memorizes it }
    memorized: array[0..73] of Byte;
    { 1 once the spell is in the book }
    known: array[1..114] of Byte;
    { by TSpell.castClass and level }
    slots: array[0..3, 1..8] of Byte
  end;
  PEffect = ^TEffect;
  { an active effect; TCharacter.effects links them }
  TEffect = record
    effectId: Byte;
    { minutes left; 0 never runs out }
    duration: Word;
    strength: Byte;
    { 1 runs the handler again when the effect is removed }
    onRemove: Byte;
    next: PEffect
  end;
  PCharacter = ^TCharacter;
  TIconColors = array[1..6] of Byte;
  TCharacter = record
    name: String[15];
    { str int wis dex con cha }
    stats: array[0..5] of TStatPair;
    exceptionalStrength: Byte;
    exceptionalStrengthBase: Byte;
    spellPrep: ShortInt;
    thac0Base: Byte;
    race: ShortInt;
    characterClass: ShortInt;
    knightOrder: Byte;
    deity: ShortInt;
    robeOrder: Byte;
    cureAbility: Byte;
    age: Word;
    maxHitPoints: Byte;
    iconDimensions: Byte;
    saves: array[0..4] of Byte;
    baseMovement: Byte;
    levelHighest: ShortInt;
    levelUndead: Byte;
    thiefSkills: array[1..8] of Byte;
    effects: PEffect;
    npc: Byte;
    { steel, gems, jewelry }
    coins: array[4..6] of Word;
    classLevels: array[0..7] of ShortInt;
    { before a drain }
    oldLevels: array[0..7] of ShortInt;
    gender: ShortInt;
    alignment: ShortInt;
    attackRate: Byte;
    attackRate2: Byte;
    unarmedRolls: array[1..2] of Byte;
    unarmedDice: array[1..2] of Byte;
    unarmedModifiers: array[1..2] of ShortInt;
    baseArmorClass: Byte;
    strengthBonusEnabled: Byte;
    identity: Byte;
    experience: LongInt;
    oldExperience: LongInt;
    oldMaxHitPoints: Byte;
    classMask: Byte;
    { also a monster's XP per hit point }
    baseMaxHitPoints: Byte;
    xpAward: Word;
    hpRolled: Byte;
    iconHead: Byte;
    iconBody: Byte;
    orderNumber: Byte;
    iconSize: Byte;
    iconColors: TIconColors;
    typeFlags: Byte;
    immunityFlags: Byte;
    numberOfItems: Byte;
    items: PItem;
    equipped: array[0..12] of PItem;
    handsEquipped: Byte;
    saveBonus: ShortInt;
    encumbrance: Word;
    next: PCharacter;
    combat: PCombat;
    spellResistance: Byte;
    spells: PSpellBlock;
    levelUpReady: Byte;
    status: Byte;
    enabled: Byte;
    side: ShortInt;
    quickFight: Byte;
    thac0Adjusted: Byte;
    armorClass: Byte;
    rearArmorClass: Byte;
    attacksLeft: array[1..2] of Byte;
    currentRolls: array[1..2] of Byte;
    currentDice: array[1..2] of Byte;
    currentModifiers: array[1..2] of ShortInt;
    hitPoints: Byte;
    currentMovement: Byte
  end;
  PCloudNode = ^TCloudNode;
  { a spell cloud on the arena; cloudList links them }
  TCloudNode = record
    caster: Pointer;
    next: PCloudNode;
    { the terrain each cell had, cells by patchDir }
    under: array[1..9] of Byte;
    { 1 where the cloud reached that cell }
    covered: array[1..9] of Byte;
    x: ShortInt;
    y: ShortInt;
    { rounds left; -1 clears it at once }
    countdown: ShortInt;
    casterLevel: Byte;
    { the arena code the cloud draws as, 28 or 29 }
    terrain: Byte;
  end;
  TStatRange = record minimum: Byte; maximum: Byte end;
  { raceStatLimits, by race }
  TRaceStatLimits = record
    { by gender }
    strengthMinimum: array[0..1] of Byte;
    strengthMaximum: array[0..1] of Byte;
    exceptionalMaximum: array[0..1] of Byte;
    { int wis dex con cha, by stat index }
    range: array[1..5] of TStatRange
  end;
  { startingAges: base + dice d sides }
  TAgeRoll = record base: Word; dice: Byte; sides: Byte end;
  { raceClasses: the class ids a race may take }
  TRaceClasses = record
    count: Byte;
    classId: array[1..14] of ShortInt
  end;
  { classProgression, by class: what each level past 1 brings }
  TClassProgression = record
    experience: array[2..18] of LongInt;
    spellSlots: array[2..18, 1..8] of Byte
  end;
  { a party menu entry }
  TMenuItem = record
    caption: String[40];
    enabled: Byte
  end;
  TBaseItem = record
    slot: Byte;
    hands: Byte;
    { a weapon's damage against a large target }
    damageRollsLarge: Byte;
    damageDiceLarge: Byte;
    damageModifierLarge: Byte;
    { a missile weapon's attacks per round }
    rateOfFire: Byte;
    { bit 7 set when it counts toward armor class }
    armorBonus: Byte;
    { 0 slashing, 1 piercing, $80 bashing }
    wpnClass: Byte;
    { loaded from ITEMS }
    wpnClassTail: Byte;
    damageRolls: Byte;
    damageDice: Byte;
    damageModifier: Byte;
    range: Byte;
    classMask: Byte;
    flags: Byte;
    { loaded from ITEMS }
    flagsTail: Byte
  end;
  { TItem from itemType on }
  TItemTemplate = record
    itemType: Byte;
    nameIds: array[1..3] of Byte;
    plus: ShortInt;
    saveBonus: ShortInt;
    equipped: Byte;
    unidentifiedMask: Byte;
    cursed: Byte;
    weight: Word;
    quantity: Byte;
    value: Word;
    charges: Byte;
    effect: Byte;
    special: Byte
  end;
  TSpell = record
    { the slots row -- 0 cleric, 1 druid, 2 deity gift, 3 mage }
    castClass: ShortInt;
    level: ShortInt;
    { plus rangePerLevel per caster level (Magic.CalcSpellRange); 255 touch }
    range: Byte;
    rangePerLevel: Byte;
    { minutes, plus durationPerLevel per caster level (Magic.CalcSpellDuration) }
    duration: Byte;
    durationPerLevel: Byte;
    { CbtActs.SelectCombatTargets's case selector }
    targeting: Byte;
    { 0 combat only, 1 the caster, 2 one character, 3 the party }
    campTarget: Byte;
    { 0 no save; else FxEngine's saveNegates and damage reduction code }
    saveEffect: Byte;
    { FxEngine.RollSavingThrow }
    saveType: Byte;
    effectId: Byte;
    { 0 is a camp-only spell }
    combatOk: Byte;
    { segments; div 3 is the rounds before it fires }
    castingTime: Byte;
    { CombatAi ranks its castable spells by it }
    aiPriority: Byte;
    { 0 aims at the caster's own team }
    hostile: Byte;
    hostileTail: Byte
  end;
  { the four script memory zones, each indexed by the script address it starts at }
  PZone0 = ^TZone0;
  TZone0 = record
    case Byte of
    0: (wildXLead: array[$000..$0C2] of Byte;
       { party marker on the overland map }
       wildX: Byte;
       wildY: Byte;
       { GEO block View3D.Load3DMap holds }
       geoMap: Byte;
       { tenths,minutes,tens,hours,days,months,years }
       clock: array[$4BC6..$4BCC] of Byte;
       clockTail: array[$0CD..$0E4] of Byte;
       { no casting, no item use }
       antiMagic: Byte;
       { 3-D view; 0 is the overland map }
       inDungeon: Byte;
       targetGateA: Byte;
       targetGateB: Byte;
       targetGateBTail: array[$0E9..$0EF] of Byte;
       prevX: Byte;
       prevY: Byte;
       { ECL script the area runs }
       scriptId: Byte;
       combatDecor: Byte;
       combatDecorTail: array[$0F4..$0FA] of Byte;
       automapLock: Byte;
       { GDVars.textDelay, in the save file }
       savedTextDelay: Byte;
       { sky color index, event bit 7 set / clear }
       skyA: Byte;
       skyB: Byte;
       { GDVars.picturesEnabled*2+GDVars.animationsEnabled, in the save file }
       savedOptions: Byte;
       savedOptionsTail: array[$100..$132] of Byte;
       { a Word, filled a byte at a time }
       vaultFunds: array[0..1] of Byte;
       vaultFundsTail: array[$135..$1F3] of Byte;
       { 1..5, set from the camp Alter menu }
       difficulty: Byte;
       mirrorDuel: Byte;
       quitCounter: Byte;
       { overland travel is live }
       wildOn: Byte;
       firstMonsterDown: Byte;
       { 0..3, one moon per robe order }
       moonPhase: array[$4CF9..$4CFB] of Byte;
       { days into the phase; GameTime.ClockDisplay rolls them }
       moonTimer: array[$4CFC..$4CFE] of Byte;
       columnOffset: Byte;
       enterVault: Byte);
    1: (ecl: array[$4B00..$4EFF] of Byte)
  end;
  PZone1 = ^TZone1;
  TZone1 = record
    case Byte of
    0: (trainMaskLead: array[$000..$2A7] of Byte;
       { one bit per class the hall trains }
       trainMask: array[$7EA8..$7EA8] of Byte;
       trainMaskTail: array[$2A9..$2BF] of Byte;
       { distance the script asks for }
       monsterMaxDist: array[$7EC0..$7EC0] of Byte;
       { distance shown, capped by the walls }
       monsterDist: array[$7EC1..$7EC1] of Byte;
       monsterDistTail: array[$2C2..$2C5] of Byte;
       { CombatSt stores it in npc, bit 7 set }
       moraleBase: array[$7EC6..$7EC6] of Byte;
       { 0 won, 1 a monster got away, $80 lost, $81 fled }
       combatResult: array[$7EC7..$7EC7] of Byte;
       { monsters down when the fight ends }
       monstersDef: array[$7EC8..$7EC8] of Byte;
       { holds the party in place at 255 }
       moveLocked: array[$7EC9..$7EC9] of Byte;
       { bit 0 searching; bit 1 one searched step }
       searchFlags: array[$7ECA..$7ECA] of Byte;
       { bit 0 the party, bit 1 the monsters: a surprised side's initiative is 6 lower }
       surprise: array[$7ECB..$7ECB] of Byte;
       surpriseTail: array[$2CC..$2D1] of Byte;
       { rest ticks between interruption rolls }
       restPeriod: array[$7ED2..$7ED2] of Byte;
       { chance per roll, percent }
       interruptPct: array[$7ED3..$7ED3] of Byte;
       interruptPctTail: Byte;
       { the party stepped off the map edge }
       leaveMap: array[$7ED5..$7ED5] of Byte;
       leaveMapTail: array[$2D6..$2E1] of Byte;
       enterTemple: array[$7EE2..$7EE2] of Byte;
       { 1: the fallen drop nothing }
       noCombatItems: array[$7EE3..$7EE3] of Byte;
       noCombatItemsTail: array[$2E4..$2E5] of Byte;
       { the dying stand up at 1 hp afterwards }
       reviveFlag: array[$7EE6..$7EE6] of Byte;
       reviveFlagTail: array[$2E7..$311] of Byte;
       { GDVars.diskNumber in the save file; an ECL write swaps disk }
       savedDisk: Byte;
       savedDiskTail: array[$313..$332] of Byte;
       attackedAllies: array[$7F33..$7F33] of Byte;
       attackedAlliesTail: array[$334..$33D] of Byte;
       partySize: array[$7F3E..$7F3E] of Byte;
       { ECL DIVIDE leaves the remainder here }
       divRemainder: array[$7F3F..$7F3F] of Byte;
       divRemainderTail: array[$340..$36B] of Byte;
       enterShop: Byte;
       { 1,2,4,8 cheaper; $20,$40,$80 dearer }
       priceLevel: array[$7F6D..$7F6D] of Byte;
       priceLevelTail: array[$36E..$36F] of Byte;
       modMonThac0: array[$7F70..$7F70] of ShortInt;
       modPartyThac0: array[$7F71..$7F71] of ShortInt;
       modPartyMove: array[$7F72..$7F72] of Byte;
       modPartyMoveTail: array[$373..$378] of Byte;
       { EclMenu.EclInit zeroes them for a new game; never read }
       newGameBytes: array[$7F79..$7F82] of Byte;
       newGameBytesTail: array[$383..$3FF] of Byte);
    1: (ecl: array[$7C00..$7FFF] of Byte)
  end;
  PZone2 = ^TZone2;
  TZone2 = array[$7A00..$7BFF] of Byte;
  PZone3 = ^TZone3;
  TZone3 = array[$8000..$9DFF] of Byte;
  { one of loadedWallSets: the WALLDEF block View3D.LoadWallSet put in an 8x8 symbol set slot; $FFFF, $FFFF while the
    slot is empty }
  TWallSet = record
    blockId: Word;
    slot: Word
  end;
  TColorMap = array[0..7] of Byte;
  PBytes = ^TBytes;
  TBytes = array[0..65000] of Byte;
  PImgBuf = ^TImgBuf;
  TImgBuf = record
    height: Word;
    width: Word;
    { the DAX header's placement, Portrait.Show3DSprite's blit origin }
    originX: Word;
    originY: Word;
    count: Byte;
    map: TColorMap;
    imgSize: Word;
    transp: PBytes;
    data: array[0..32000] of Byte;
  end;
  TAnimFrame = record
    { ticks the frame stays up }
    duration: LongInt;
    pic: PImgBuf;
  end;
  TAnimRec = record
    count: Byte;
    currentFrame: Byte;
    frames: array[1..8] of TAnimFrame;
  end;
  TMonFlags = array[0..1] of Boolean;
  { a color remap table: by color, the color it becomes }
  TColorTab = array[0..15] of Byte;
  PCursorMask = ^TCursorMask;
  TCursorMask = array[0..63] of Byte;
  { one line walk: start, end, the Bresenham error and absolute deltas, the current cell, the step signs, the length so
    far in half cells, and the direction of the last step }
  TPathReq = record
    sx: Integer;
    sy: Integer;
    ex: Integer;
    ey: Integer;
    err: Integer;
    adx: Integer;
    ady: Integer;
    cx: Integer;
    cy: Integer;
    stepX: Integer;
    stepY: Integer;
    dist: Byte;
    step: Byte;
  end;
  PMenuRow = ^TMenuRow;
  TMenuRow = record
    name: String[40];
    heading: Byte;
    next: PMenuRow
  end;
  TClock = array[0..6] of Word;
  { the display adapter the game drives }
  TVideoMode = (Cga, Ega, Tandy);
  PEclStack = ^TEclStack;
  TEclStack = record
    addr: Word;
    next: PEclStack
  end;
  { the party's map position, facing, the wall ahead and the event at the cell, cleared and saved as one block }
  TMapState = record
    x: ShortInt;
    y: ShortInt;
    facing: Byte;
    wallAhead: Byte;
    event: Byte
  end;
  { [row, column] }
  TGeoPlane = array[0..15, 0..15] of Byte;
  { a GEO block, less its two-byte prefix }
  TGeoMap = record
    { high nibble the north wall's type, low nibble the east }
    wallsNorthEast: TGeoPlane;
    { south, west }
    wallsSouthWest: TGeoPlane;
    { GDVars.mapState.event }
    events: TGeoPlane;
    { two bits per side, west down to north: 0 solid, 1 open }
    barriers: TGeoPlane;
  end;
  PGeoMap = ^TGeoMap;
type
  TCodeRec = record
    pageNum: Byte;
    entryNum: Byte;
    wordNum: Byte;
    wordLen: Byte;
    { encoded letters; slots past wordLen keep their stored bytes }
    chars: array[1..10] of Byte;
  end;
  { the ECL script's five entry points, loaded from the script header; EclMenu fills them by number, EclVm and Explore
    call them by name }
  TEclEntryPoints = record
    case Byte of
      0: (entries: array[1..5] of Word);
      1: (entryBeforeMove: Word; entryAfterMove: Word; entryBeforeCamp: Word; entryAfterCamp: Word; entryMain: Word);
  end;
  PFontArr = ^TFontArr;
  TFontArr = array[0..255] of array[0..7] of Byte;
  TEffectHandler = procedure(var character; effect: Pointer; removed: Boolean);
  TEffectHandlers = array[1..120] of TEffectHandler;
  TEffectServices = record
    handlers: TEffectHandlers;
    itemHandler: TEffectHandler
  end;
  { one enabled menu word: its ordinal in the menu string, and the hotkey }
  TEnabledChoice = record
    ordinal: Byte;
    key: Char
  end;
  TSpellSelector = procedure(kind, mode: Byte; var result: Byte);
  TSpellHandler = procedure;
  TSpellHandlers = array[1..114] of TSpellHandler;
  TSpellServices = record
    selectTargets: TSpellSelector;
    handlers: TSpellHandlers;
  end;
  TSpellTargetList = array[1..72] of PCharacter;
  TSpellTargetState = record
    count: Byte;
    targets: TSpellTargetList;
    noncombatTarget: Pointer;
  end;
  { one calibrated axis: the low end, five thresholds and the high end; CharGen and GameBoot index the seven words,
    Joystick names them }
  TJoyAxis = record
    case Byte of
      0: (words: array[0..6] of Word);
      1: (lo: Word; thr: array[1..5] of Word; hi: Word);
  end;
  TJoyCal = record
    x: TJoyAxis;
    y: TJoyAxis;
  end;
  TDrvProc = function(argSeg, argOfs, code: Word): Word;
  { An overlay read routine, the shape of OvrReadBuf: GDVars.savedOvrRead keeps the overlay manager's original, which
    GameIo.OverlayReadWithBeep retries. }
  TOverlayReadFunc = function(ovrSeg: Word): Integer;
  { The register block for software interrupts, laid out as Dos.Registers so storage can hold one without using Dos;
    callers pass it to Intr as a Registers. }
  TRegisters = record
    case Integer of
      0: (ax: Word;
          bx: Word;
          cx: Word;
          dx: Word;
          bp: Word;
          si: Word;
          di: Word;
          ds: Word;
          es: Word;
          flags: Word);
      1: (al: Byte;
          ah: Byte;
          bl: Byte;
          bh: Byte;
          cl: Byte;
          ch: Byte;
          dl: Byte;
          dh: Byte);
  end;

implementation
end.
