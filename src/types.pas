{ Types -- the types the units share. First the string lengths several units pass. The combat types: the direction
  legend and combat tables behind GDConsts.directionLegend and GDConsts.combatTables (TIconDelta and TTerrain are its
  parts), the arena records (TArenaLoc, TDownedRec, TTargetEntry and the TArena its arena points at), TCombat, each
  creature's per-fight block behind TCharacter.combat, and TCloudNode, the spell clouds on GDVars.cloudList. Then the
  character record, TCharacter: every party member and every combat creature. GDVars.partyHead is the first one and next
  links the rest; CharGen allocates and frees it. With it are TEffect, the active effects TCharacter.effects links, the
  item and spell records, and the shapes of tables elsewhere: the race limits, ages and race classes, the class
  progression and the party menu. The item records are TItem, the carried item that the item slot pool, the treasure and
  vault lists and characters' inventories link through next; TBaseItem, the per-kind record of GDVars.baseItems; and
  TItemTemplate, the record of GDVars.itemTemplates, which is TItem from itemType on. The spell records are TSpell, one
  row of GDConsts.spellTable per spell id, and TSpellBlock, the spells TCharacter.spells points at, which SaveLoad
  allocates for a loaded character and saves whole as the character's .wiz file. A spell id stored in a character or
  scroll carries bit 7 while the spell is still to be memorized or scribed, so readers mask with $7F before indexing.
  Last come the script zones, TZone0 through TZone3, and TWallSet, one entry of GDVars.loadedWallSets; then the picture
  buffer Blit loads, draws and frees (TImgBuf, with its color map); the portrait animation, TAnimRec; and TMonFlags, the
  monster flags. TAimResult is where an aim landed. After them come the types of the units' shared state: Blit's color
  table, the mouse cursor mask, Pathing's line walk (TPathReq), MenuCore's menu rows (TMenuRow), the game clock
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
  TDirectionLegend = record
    names: array[0..7] of String[2];
    matrix: array[0..2, 0..2] of Byte
  end;
  TCombatTables = record
    directionX: array[0..8] of ShortInt;
    directionY: array[0..8] of ShortInt;
    terrain: array[1..69] of TTerrain;
    { sub-tile offsets by icon size }
    iconDelta: array[1..4, 0..3] of TIconDelta;
    anyDirection: Byte
  end;
  TArenaLoc = record x: ShortInt; y: ShortInt; aux: Byte; size: Byte end;
  TDownedRec = record cr: Pointer; x: ShortInt; y: ShortInt; terrain: Byte end;
  { what Pathing.BuildTargetList leaves in GDVars.targetList, nearest first }
  TTargetEntry = record
    { the combat slot, GDVars.creatures[] }
    characterIndex: Byte;
    { in half cells: Pathing.WalkLine's count }
    distance: Byte;
    { the direction it lies in, 0..7 }
    direction: Byte
  end;
  PCombat = ^TCombat;
  { one per creature for the fight; TCharacter.combat }
  TCombat = record
    { spell id being cast, 0 none }
    spellCast: Byte;
    { damage, silence and nausea clear them }
    canCast: Byte;
    canUseItem: Byte;
    { 1d6 plus missile dexterity, highest acts first; 20 re-runs the turn }
    initiative: ShortInt;
    { which of the two attack counts is in use, 1 or 2 }
    attackForm: Byte;
    { adjacent foes a sweep may take }
    sweepTargets: Byte;
    movement: Byte;
    guarding: Byte;
    { 1 once it has attacked this round }
    attacked: Byte;
    direction: Byte;
    { the PCharacter it is after }
    target: Pointer;
    { overkill when it fell, plus one per round dying; past 9 it dies }
    dyingTurns: Byte;
    { attacks received since it last moved or began a turn }
    attacksTaken: Byte;
    { a fear effect set it; it flees and cannot guard }
    panicked: Byte;
    { turn-undead tries this fight }
    turnAttempts: Byte;
    { facing-to-attacker angles of those attacks, summed mod 8 }
    attackAngles: Byte;
    { 1 for a monster; its items come from the heap }
    notPcNpc: Byte;
    fleeing: Byte;
    aiStance: Byte
  end;
  PCloudNode = ^TCloudNode;
  { a spell cloud on the arena; GDVars.cloudList links them }
  TCloudNode = record
    caster: Pointer;
    next: PCloudNode;
    { the terrain each cell had, cells by GDConsts.patchDir }
    under: array[1..9] of Byte;
    { 1 where the cloud reached that cell }
    covered: array[1..9] of Byte;
    x: ShortInt;
    y: ShortInt;
    { rounds left; -1 clears it at once }
    countdown: ShortInt;
    casterLevel: Byte;
    { the arena code the cloud draws as, 28 or 29 }
    terrain: Byte
  end;
  PArena = ^TArena;
  { the combat map GDVars.arena points at }
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
    cells: array[0..24, 0..49] of Byte
  end;
  TStatPair = record base: Byte; current: Byte end;
  TStatRange = record minimum: Byte; maximum: Byte end;
  { GDConsts.raceStatLimits, by race }
  TRaceStatLimits = record
    { by gender }
    strengthMinimum: array[0..1] of Byte;
    strengthMaximum: array[0..1] of Byte;
    exceptionalMaximum: array[0..1] of Byte;
    { int wis dex con cha, by stat index }
    range: array[1..5] of TStatRange
  end;
  { GDConsts.startingAges: base + dice d sides }
  TAgeRoll = record base: Word; dice: Byte; sides: Byte end;
  { GDConsts.classProgression, by class: what each level past 1 brings }
  TClassProgression = record
    experience: array[2..18] of LongInt;
    spellSlots: array[2..18, 1..8] of Byte
  end;
  { GDConsts.partyMenuItems }
  TMenuItem = record caption: String[40]; enabled: Byte end;
  { GDConsts.raceClasses: the class ids a race may take }
  TRaceClasses = record
    count: Byte;
    classId: array[1..14] of ShortInt
  end;
  PItem = ^TItem;
  { a carried item; lists link through next }
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
  TBaseItem = record
    slot: Byte;
    hands: Byte;
    { a weapon's damage against a large defender }
    damageRollsLarge: Byte;
    damageDiceLarge: Byte;
    damageModifierLarge: Byte;
    { a missile weapon's attacks per round, doubled }
    rateOfFire: Byte;
    { bit 7 set when it counts toward armor class, low bits the points }
    armorBonus: Byte;
    { 0 slashing, 1 piercing, $80 bashing; effect 93 halves 0 and 1 }
    wpnClass: Byte;
    { loaded from ITEMS, never read }
    wpnClassTail: Byte;
    damageRolls: Byte;
    damageDice: Byte;
    damageModifier: Byte;
    range: Byte;
    classMask: Byte;
    flags: Byte;
    { loaded from ITEMS, never read }
    flagsTail: Byte
  end;
  { TItem from itemType on: EclVm and CharGen copy one over a new item }
  TItemTemplate = record
    itemType: Byte;
    nameIds: array[1..3] of Byte;
    plus: ShortInt;
    saveBonus: ShortInt;
    equipped: Byte;
    unidMask: Byte;
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
    { minutes left; 0 never runs out (GameTime.AdvanceTime) }
    duration: Word;
    { what the handler keeps: a strength code, charges, a marker }
    strength: Byte;
    { 1 runs the handler again when the effect is removed }
    onRemove: Byte;
    next: PEffect
  end;
  TIconColors = array[1..6] of Byte;
  PCharacter = ^TCharacter;
  TCharacter = record
    name: String[15];
    { str int wis dex con cha }
    stats: array[0..5] of TStatPair;
    exceptionalStrength: Byte;
    exceptionalStrengthBase: Byte;
    { rest ticks left before spells are memorized }
    spellPrep: ShortInt;
    thac0Base: Byte;
    race: ShortInt;
    characterClass: ShortInt;
    { 1 Crown, 2 Sword, 3 Rose }
    knightOrder: Byte;
    deity: ShortInt;
    { mage's moon, 1 Solinari 2 Lunitari 3 Nuitari }
    robeOrder: Byte;
    { paladin cure-disease uses left }
    cureAbility: Byte;
    age: Word;
    maxHitPoints: Byte;
    { combat icon size in the low 7 bits }
    iconDimensions: Byte;
    { the five saving-throw targets }
    saves: array[0..4] of Byte;
    baseMovement: Byte;
    { hit dice for a monster }
    levelHighest: ShortInt;
    { 0 living, else the row of CbtActs' turn-undead table; nonzero marks the undead the mace of disruption kills, the
      turn limit counts (EclVm) and the clouds spare (FxEngine) }
    levelUndead: Byte;
    thiefSkills: array[1..8] of Byte;
    effects: PEffect;
    { 0 party member, >=$80 NPC, $B3 animated }
    npc: Byte;
    { steel, gems, jewelry }
    coins: array[4..6] of Word;
    { cleric druid fighter paladin ranger mage thief knight }
    classLevels: array[0..7] of ShortInt;
    { levels before a drain }
    oldLevels: array[0..7] of ShortInt;
    gender: ShortInt;
    alignment: ShortInt;
    { attacks per round, doubled; the first attack form's }
    attackRate: Byte;
    { the second form's (TCombat.attackForm picks) }
    attackRate2: Byte;
    unarmedRolls: array[1..2] of Byte;
    unarmedDice: array[1..2] of Byte;
    unarmedModifiers: array[1..2] of ShortInt;
    baseArmorClass: Byte;
    strengthBonusEnabled: Byte;
    { CPIC icon id }
    identity: Byte;
    experience: LongInt;
    { before a level drain; Magic restores it }
    oldExperience: LongInt;
    { likewise }
    oldMaxHitPoints: Byte;
    { ANDed with TBaseItem.classMask }
    classMask: Byte;
    { XP per hit point on a monster (PostCbt) }
    baseMaxHitPoints: Byte;
    xpAward: Word;
    hpRolled: Byte;
    iconHead: Byte;
    iconBody: Byte;
    orderNumber: Byte;
    iconSize: Byte;
    iconColors: TIconColors;
    { by the effect handlers and the spells that test each bit: $01 Dispel Evil kills it, Dispelling Evil hits it worse
      (effects 4, 34); $02 a person: Charm Person, Sleep, Hold Person, Mass Charm (Magic); $04 the dwarf's -4 AC applies
      to it (47); $08 the ranger's damage bonus (105); $10 a mammal, for Charm Person or Mammal; $20 effect 115 adds 3
      damage; $40 effect 32 hides it from attackers without effect 24; $80 the dwarf's +1 attack applies to it (26) }
    typeFlags: Byte;
    { bit $01: effect 114 deals the attacker's hit points to it; $08 proof against poison and death magic (poison touch,
      Death Spell, Slay Living), and no 'is Dying' or 'is killed' line when it goes down }
    immunityFlags: Byte;
    numberOfItems: Byte;
    items: PItem;
    { by TBaseItem.slot; 11 ammunition, 12 launcher }
    equipped: array[0..12] of PItem;
    handsEquipped: Byte;
    saveBonus: ShortInt;
    encumbrance: Word;
    next: PCharacter;
    { TCombat, held for the fight }
    combat: PCombat;
    spellResistance: Byte;
    spells: PSpellBlock;
    levelUpReady: Byte;
    status: Byte;
    { 0 once status leaves 0..1 }
    enabled: Byte;
    { 0 party, 1 monsters }
    side: ShortInt;
    quickFight: Byte;
    thac0Adjusted: Byte;
    armorClass: Byte;
    rearArmorClass: Byte;
    { attacks left this round, by TCombat.attackForm }
    attacksLeft: array[1..2] of Byte;
    currentRolls: array[1..2] of Byte;
    currentDice: array[1..2] of Byte;
    currentModifiers: array[1..2] of ShortInt;
    hitPoints: Byte;
    currentMovement: Byte
  end;
  { The script zones. Zone 0 is the heap block GDVars.zone0 points at, ECL addresses $4B00..$4EFF (EclMenu.GbvmZone);
    SaveLoad writes it to a saved game right after the leading disk-number byte, then zone 1, then zone 2. Its arrays
    are indexed by ECL address because their readers walk them by one, so the low bound is the address of the field's
    first byte. Zone 1 is the block GDVars.zone1 points at, ECL addresses $7C00..$7FFF, saved whole after zone 0; its
    readers reach a cell through a typed constant holding the cell's offset, added to $7C00 at the site, so each such
    cell is a one-element array whose bound is its ECL address. Zones 2 and 3 are the block GDVars.zone2 points at, ECL
    addresses $7A00..$7BFF, saved whole after zone 1, and the block GDVars.zone3 points at, ECL addresses $8000..$9DFF,
    where EclMenu loads the running script. }
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
  { one of GDVars.loadedWallSets: the WALLDEF block View3D.LoadWallSet put in }
  TWallSet = record
    { an 8x8 symbol set slot; $FFFF, $FFFF while the slot is empty }
    blockId: Word;
    slot: Word
  end;
  PZone2 = ^TZone2;
  TZone2 = array[$7A00..$7BFF] of Byte;
  PZone3 = ^TZone3;
  TZone3 = array[$8000..$9DFF] of Byte;
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
  { [0] the monster's sprite is shown, [1] its picture }
  TMonFlags = array[0..1] of Boolean;
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
    { 1: a title row, drawn in menuLabelColor and skipped by the cursor }
    heading: Byte;
    next: PMenuRow
  end;
  { where an aim landed: the creature, if any, and the cell }
  TAimResult = record
    target: Pointer;
    x: Byte;
    y: Byte;
    yTail: Byte
  end;
  TClock = array[0..6] of Word;
  { the display adapter the game drives }
  TVideoMode = (Cga, Ega, Tandy);
  PEclStack = ^TEclStack;
  { EclGosub pushes the return address; RETURN pops it }
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
  { the heap block tandyFreeBlock copies aside }
  TFreeBlk = array[0..7] of Byte;
  PFreeBlk = ^TFreeBlk;
  { the ECL script's five entry points, loaded from the script header; EclMenu fills them by number, EclVm and Explore
    call them by name }
  TEclEntryPoints = record
    case Byte of
      0: (entries: array[1..5] of Word);
      1: (entryBeforeMove: Word; entryAfterMove: Word; entryBeforeCamp: Word; entryAfterCamp: Word; entryMain: Word);
  end;
  PFontArr = ^TFontArr;
  TFontArr = array[0..255] of array[0..7] of Byte;
  TEffectHandler = procedure(var character: PCharacter; state: Pointer; removed: Boolean);
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
    handlers: TSpellHandlers
  end;
  TSpellTargetList = array[1..72] of PCharacter;
  TSpellTargetState = record
    count: Byte;
    targets: TSpellTargetList;
    noncombatTarget: Pointer
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
