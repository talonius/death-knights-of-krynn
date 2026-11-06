{ Initialized data: the game's typed constants in the data segment, in address order. A new section starts wherever the
  data needs a word boundary. }
unit GDConsts;

interface

uses Types;

{ The script commands' tables, the copy-protection words, the temple's heal menu, the combat AI's step directions,
  CombatSt's placement tables, and the character file layouts SaveLoad and CharGen read. }
const
  { the sound cue each EclVm SOUND operand plays }
  soundCueTable: array[1..6] of Byte = (
    12, 9, 4, 7, 10, 11);
  { by stock list: first index into shopStockItems }
  shopStockStart: array[1..8] of Byte = (
    1, 16, 23, 29, 31, 34, 37, 40);
  { by stock list: how many entries of shopStockItems it runs }
  shopStockCount: array[1..8] of Byte = (
    15, 7, 6, 2, 3, 3, 3, 30);
  { the item template ids EclVm's SHOP stocks, the stock lists end to end }
  shopStockItems: array[1..56] of Byte = (
    1, 4, 9, 14, 17, 22, 24, 26, 28, 31, 32, 34, 36, 38, 41, 1, 24, 26, 28, 31, 32, 34, 9,
    17, 36, 38, 44, 48, 3,
    29, 57, 58, 61, 54, 55, 64, 60, 63, 73, 3, 7, 13, 20, 21, 35, 52, 53, 54, 55, 56, 57, 58,
    59, 60, 61, 62);
  { The journal words CopyProtection asks for. Row zero is never selected -- the question picks one of rows 1..49 -- and
    its bytes run 63..75. }
  journalWords: array[0..49] of Types.TCodeRec = (
    (pageNum: 63; entryNum: 64; wordNum: 65; wordLen: 66;
     chars: (67, 68, 69, 70, 71, 72, 73, 74, 75, 0)),
    (pageNum: 33; entryNum: 1; wordNum: 3; wordLen: 5;
     chars: (22, 37, 34, 34, 30, 0, 0, 0, 0, 0)),
    (pageNum: 33; entryNum: 2; wordNum: 6; wordLen: 5;
     chars: (42, 20, 41, 24, 38, 0, 0, 0, 0, 0)),
    (pageNum: 33; entryNum: 3; wordNum: 2; wordLen: 9;
     chars: (20, 39, 31, 27, 30, 34, 24, 30, 29, 0)),
    (pageNum: 33; entryNum: 4; wordNum: 5; wordLen: 5;
     chars: (25, 31, 28, 24, 38, 0, 0, 0, 0, 0)),
    (pageNum: 33; entryNum: 5; wordNum: 10; wordLen: 7;
     chars: (28, 18, 29, 18, 30, 18, 31, 0, 0, 0)),
    (pageNum: 34; entryNum: 6; wordNum: 5; wordLen: 5;
     chars: (38, 30, 34, 32, 35, 0, 0, 0, 0, 0)),
    (pageNum: 34; entryNum: 7; wordNum: 7; wordLen: 6;
     chars: (26, 23, 36, 33, 27, 21, 0, 0, 0, 0)),
    (pageNum: 35; entryNum: 8; wordNum: 5; wordLen: 4;
     chars: (34, 21, 33, 25, 0, 0, 0, 0, 0, 0)),
    (pageNum: 35; entryNum: 9; wordNum: 8; wordLen: 7;
     chars: (36, 38, 21, 38, 29, 37, 32, 0, 0, 0)),
    (pageNum: 35; entryNum: 10; wordNum: 3; wordLen: 7;
     chars: (40, 22, 29, 20, 32, 30, 22, 0, 0, 0)),
    (pageNum: 36; entryNum: 11; wordNum: 1; wordLen: 4;
     chars: (33, 21, 45, 21, 0, 0, 0, 0, 0, 0)),
    (pageNum: 36; entryNum: 12; wordNum: 5; wordLen: 5;
     chars: (25, 28, 37, 38, 39, 0, 0, 0, 0, 0)),
    (pageNum: 36; entryNum: 14; wordNum: 4; wordLen: 6;
     chars: (37, 34, 36, 27, 38, 23, 0, 0, 0, 0)),
    (pageNum: 36; entryNum: 15; wordNum: 8; wordLen: 7;
     chars: (40, 22, 29, 20, 32, 30, 22, 0, 0, 0)),
    (pageNum: 37; entryNum: 16; wordNum: 5; wordLen: 6;
     chars: (37, 26, 19, 29, 23, 37, 0, 0, 0, 0)),
    (pageNum: 37; entryNum: 17; wordNum: 7; wordLen: 6;
     chars: (37, 21, 36, 23, 19, 31, 0, 0, 0, 0)),
    (pageNum: 37; entryNum: 18; wordNum: 1; wordLen: 4;
     chars: (39, 21, 27, 25, 0, 0, 0, 0, 0, 0)),
    (pageNum: 37; entryNum: 19; wordNum: 4; wordLen: 3;
     chars: (34, 22, 35, 0, 0, 0, 0, 0, 0, 0)),
    (pageNum: 38; entryNum: 20; wordNum: 2; wordLen: 5;
     chars: (23, 42, 20, 37, 25, 0, 0, 0, 0, 0)),
    (pageNum: 38; entryNum: 21; wordNum: 6; wordLen: 6;
     chars: (30, 23, 19, 22, 23, 36, 0, 0, 0, 0)),
    (pageNum: 38; entryNum: 22; wordNum: 7; wordLen: 8;
     chars: (19, 25, 36, 25, 42, 21, 30, 35, 0, 0)),
    (pageNum: 39; entryNum: 23; wordNum: 5; wordLen: 7;
     chars: (19, 22, 29, 26, 22, 39, 22, 0, 0, 0)),
    (pageNum: 39; entryNum: 24; wordNum: 6; wordLen: 4;
     chars: (26, 21, 39, 40, 0, 0, 0, 0, 0, 0)),
    (pageNum: 39; entryNum: 25; wordNum: 3; wordLen: 3;
     chars: (29, 26, 39, 0, 0, 0, 0, 0, 0, 0)),
    (pageNum: 39; entryNum: 26; wordNum: 4; wordLen: 3;
     chars: (36, 33, 25, 0, 0, 0, 0, 0, 0, 0)),
    (pageNum: 39; entryNum: 27; wordNum: 9; wordLen: 7;
     chars: (18, 31, 42, 30, 32, 35, 22, 0, 0, 0)),
    (pageNum: 40; entryNum: 28; wordNum: 3; wordLen: 6;
     chars: (37, 38, 36, 23, 23, 38, 0, 0, 0, 0)),
    (pageNum: 40; entryNum: 29; wordNum: 4; wordLen: 5;
     chars: (23, 37, 24, 20, 32, 0, 0, 0, 0, 0)),
    (pageNum: 40; entryNum: 30; wordNum: 8; wordLen: 4;
     chars: (23, 25, 32, 32, 0, 0, 0, 0, 0, 0)),
    (pageNum: 41; entryNum: 32; wordNum: 9; wordLen: 5;
     chars: (32, 24, 39, 20, 31, 0, 0, 0, 0, 0)),
    (pageNum: 41; entryNum: 33; wordNum: 3; wordLen: 5;
     chars: (38, 24, 20, 39, 38, 0, 0, 0, 0, 0)),
    (pageNum: 42; entryNum: 34; wordNum: 10; wordLen: 4;
     chars: (25, 45, 25, 39, 0, 0, 0, 0, 0, 0)),
    (pageNum: 42; entryNum: 35; wordNum: 1; wordLen: 7;
     chars: (35, 22, 18, 21, 26, 31, 24, 0, 0, 0)),
    (pageNum: 42; entryNum: 36; wordNum: 8; wordLen: 10;
     chars: (33, 35, 33, 30, 23, 17, 23, 29, 35, 33)),
    (pageNum: 43; entryNum: 39; wordNum: 3; wordLen: 5;
     chars: (41, 34, 28, 22, 24, 0, 0, 0, 0, 0)),
    (pageNum: 43; entryNum: 41; wordNum: 6; wordLen: 4;
     chars: (21, 38, 33, 45, 0, 0, 0, 0, 0, 0)),
    (pageNum: 44; entryNum: 42; wordNum: 4; wordLen: 6;
     chars: (20, 36, 39, 38, 23, 37, 0, 0, 0, 0)),
    (pageNum: 44; entryNum: 43; wordNum: 3; wordLen: 7;
     chars: (21, 22, 36, 33, 18, 26, 35, 0, 0, 0)),
    (pageNum: 45; entryNum: 45; wordNum: 9; wordLen: 6;
     chars: (38, 23, 31, 34, 30, 23, 0, 0, 0, 0)),
    (pageNum: 46; entryNum: 46; wordNum: 5; wordLen: 8;
     chars: (32, 17, 28, 17, 20, 25, 30, 21, 0, 0)),
    (pageNum: 46; entryNum: 50; wordNum: 5; wordLen: 6;
     chars: (38, 39, 32, 32, 23, 30, 0, 0, 0, 0)),
    (pageNum: 47; entryNum: 51; wordNum: 5; wordLen: 5;
     chars: (25, 34, 40, 33, 23, 0, 0, 0, 0, 0)),
    (pageNum: 47; entryNum: 53; wordNum: 6; wordLen: 4;
     chars: (31, 29, 34, 27, 0, 0, 0, 0, 0, 0)),
    (pageNum: 48; entryNum: 55; wordNum: 10; wordLen: 5;
     chars: (21, 34, 33, 24, 38, 0, 0, 0, 0, 0)),
    (pageNum: 49; entryNum: 58; wordNum: 6; wordLen: 5;
     chars: (37, 24, 20, 23, 38, 0, 0, 0, 0, 0)),
    (pageNum: 49; entryNum: 60; wordNum: 4; wordLen: 6;
     chars: (37, 32, 19, 29, 23, 37, 0, 0, 0, 0)),
    (pageNum: 50; entryNum: 61; wordNum: 9; wordLen: 7;
     chars: (36, 25, 18, 21, 32, 40, 36, 0, 0, 0)),
    (pageNum: 50; entryNum: 64; wordNum: 3; wordLen: 7;
     chars: (39, 26, 36, 26, 37, 32, 35, 0, 0, 0)),
    (pageNum: 51; entryNum: 66; wordNum: 4; wordLen: 4;
     chars: (24, 21, 38, 31, 0, 0, 0, 0, 0, 0)));
  { the spell each row of the temple's heal menu names }
  templeMenuSpells: array[1..11] of Byte = (
    37, 39, 3, 58, 71, 53, 67, 75, 43, 66, 17);
  { by stance and attempt, the direction offset CombatAi tries a step in }
  aiDirOffsets: array[1..6, 0..4] of Byte = (
    (0, 8, 7, 6, 1),
    (2, 8, 1, 2, 7),
    (6, 7, 1, 8, 6),
    (2, 1, 7, 8, 2),
    (6, 8, 7, 6, 5),
    (4, 8, 1, 2, 3));
  { never read }
  aiDirOffsetsTail: Byte = 4;
  { by half-facing: the direction FindPlacement tries per layer }
  placementDirections: array[0..3, 0..3] of Byte = (
    (8, 4, 6, 2), (8, 6, 4, 0), (8, 0, 6, 2), (8, 2, 0, 4));
  { by half-facing and layer, the direction FindPlacement approaches from }
  combatApproachDirections: array[0..3, 0..3] of Byte = (
    (0, 0, 2, 6), (2, 2, 0, 4), (4, 4, 2, 6), (6, 6, 4, 0));
  { a half-facing back to a direction }
  halfDirections: array[0..3] of Byte = (
    7, 2, 3, 6);
  { the column of the first cell FindPlacement tries, by layer>0 and direction }
  approachOffsetX: array[0..1, 0..3] of ShortInt = (
    (5, 4, 5, 6), (3, 8, 7, 2));
  { the row of that cell }
  approachOffsetY: array[0..1, 0..3] of ShortInt = (
    (3, 2, 2, 3), (0, 2, 5, 3));
  { free columns per row, by half-facing; PlaceAllCreatures fills combatOccupancy from it }
  occupancyRanges: array[0..4, 0..5, 0..1] of ShortInt = (
    ((1, 0), (1, 0), (1, 0), (2, 9), (3, 10), (4, 10)),
    ((0, 2), (0, 3), (1, 4), (2, 5), (3, 6), (4, 7)),
    ((0, 6), (0, 7), (1, 8), (1, 0), (1, 0), (1, 0)),
    ((3, 6), (4, 7), (5, 8), (6, 9), (7, 10), (8, 10)),
    ((0, 6), (0, 7), (1, 8), (2, 9), (3, 10), (4, 10)));
  { the column step to the neighbor DecorateCell looks at: N, E, S, W }
  cardinalX: array[1..4] of ShortInt = (
    0, 1, 0, -1);
  { the row step: N, E, S, W }
  cardinalY: array[1..4] of ShortInt = (
    -1, 0, 1, 0);
  { the terrain flags CurrentCombatTile reads, by activeCombatantIndex }
  combatantTiles: array[0..31] of Byte = (
    0, 24, 17, 21, 1, 1, 96, 20, 8, 1, 0, 33, 113, 9, 6, 4, 1, 9, 9, 8, 89, 0, 17,
    17,
    0, 0, 1, 17, 0, 0, 32, 32);
  { the rule-book words Camp's RuleBookCheck asks for, which Camp views as rows of TEncodedRow }
  copyProtectionData: array[0..409] of Byte = (
    12, 21, 26, 32, 30, 27, 16, 33, 15, 32, 21, 27, 26, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1,
    7,
    40, 22, 29, 20, 32, 30, 22, 0, 0, 0, 2, 2, 42, 37, 0, 0, 0, 0, 0, 0, 0, 0, 4,
    8,
    31, 22, 22, 25, 19, 25, 17, 28, 0, 0, 5, 8, 17, 20, 38, 17, 30, 19, 21, 20, 0, 0, 9,
    8,
    19, 31, 29, 32, 37, 36, 21, 34, 0, 0, 17, 9, 12, 14, 16, 21, 21, 16, 21, 14, 231, 27, 22,
    231,
    23, 19, 8, 32, 0, 0, 0, 2, 2, 4, 33, 41, 39, 40, 0, 0, 0, 0, 0, 0, 3, 4, 32,
    35,
    21, 24, 0, 0, 0, 0, 0, 0, 6, 4, 27, 21, 33, 25, 0, 0, 0, 0, 0, 0, 8, 8, 23,
    21,
    30, 21, 34, 17, 36, 21, 0, 0, 10, 3, 22, 35, 25, 0, 0, 0, 0, 0, 0, 0, 11, 14, 17,
    35,
    18, 27, 33, 34, 31, 22, 27, 20, 0, 0, 0, 0, 0, 0, 0, 0, 0, 6, 1, 5, 20, 25, 39,
    24,
    37, 0, 0, 0, 0, 0, 3, 2, 43, 38, 0, 0, 0, 0, 0, 0, 0, 0, 4, 4, 45, 35, 41,
    38,
    0, 0, 0, 0, 0, 0, 5, 5, 35, 20, 37, 39, 44, 0, 0, 0, 0, 0, 7, 7, 35, 22, 18,
    21,
    26, 31, 24, 0, 0, 0, 12, 15, 21, 34, 21, 24, 21, 38, 13, 32, 21, 27, 26, 0, 0, 0, 0,
    0,
    0, 0, 0, 9, 2, 8, 32, 34, 31, 38, 25, 20, 21, 35, 0, 0, 3, 4, 33, 21, 34, 45, 0,
    0,
    0, 0, 0, 0, 5, 8, 35, 21, 34, 38, 25, 19, 21, 35, 0, 0, 7, 5, 26, 34, 34, 23, 38,
    0,
    0, 0, 0, 0, 10, 5, 38, 27, 34, 35, 38, 0, 0, 0, 0, 0, 10, 19, 28, 17, 29, 35, 28,
    34,
    19, 32, 33, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 10, 1, 4, 43, 28, 25, 34, 0, 0, 0,
    0,
    0, 0, 5, 6, 19, 21, 36, 33, 37, 37, 0, 0, 0, 0, 6, 8, 29, 31, 30, 35, 36, 21, 34,
    35,
    0, 0, 8, 4, 34, 36, 23, 39, 0, 0, 0, 0, 0, 0, 11, 6, 33, 21, 21, 39, 36, 37, 0,
    0,
    0, 0);
  { fifteen spaces LoadCharlist pads a name with before comparing it }
  nameBlanks: String[15] = '               ';
  { by file format: where a character file keeps its name }
  nameOffsetByFormat: array[0..1] of Byte = ($00, $00);
  { by file format: where it keeps its npc byte }
  npcOffsetByFormat: array[0..1] of Word = ($00E7, $003E);
  { by file format: its size }
  fileSizeByFormat: array[0..1] of Word = (409, 216);
  { by TCharacter.iconSize: ends CHEAD and CBODY }
  iconSizeSuffix: array[1..2] of Char = ('S', 'T');
  { the alignment ids a class may be offered, by bit of its mask }
  alignmentChoices: array[0..5] of ShortInt = (
    0, 1, 3, 4, 6, 7);
  { the EnableChoices mode for each of CustomizeIcon's icon menus }
  iconMenuModes: array[1..5] of Byte = (
    4, 2, 7, 3, 3);

{ Character creation's and combat's fixed tables, the 3-D view's slice layout, Border's window frames, the script
  variable indices, the game's text and menus, and the BIOS and EGA register numbers. }
const
  { the item templates CreateStartingItems hands out, by class group: knight, warrior, mage, cleric, other }
  startingItems: array[1..5, 1..4] of Byte = (
    (83, 48, 10, 0), (44, 48, 10, 0), (85, 86, 91, 28), (44, 48, 84, 0), (82, 87, 0, 0));
  { stat floors to petition for Sword (2) or Rose (3) }
  knightRequirements: array[2..3, 0..5] of Byte = (
    (12, 9, 13, 9, 10, 3), (15, 10, 13, 12, 15, 3));
  { by undead kind, then level band: 99 never, 0 always, <0 destroys }
  turnUndeadTable: array[1..13, 0..10] of ShortInt = (
    (99, 10, 7, 4, 1, 1, 0, 0, -1, -1, -1), (99, 13, 10, 7, 1, 1, 0, 0, 0, -1, -1),
    (99, 16, 13, 10, 4, 1, 1, 0, 0, 0, -1), (99, 19, 16, 13, 7, 4, 1, 1, 0, 0, -1),
    (99, 20, 19, 16, 10, 7, 4, 1, 1, 0, 0), (99, 99, 20, 19, 13, 10, 7, 4, 1, 1, 0),
    (99, 99, 99, 20, 16, 13, 10, 7, 4, 1, 0),
    (99, 99, 99, 99, 20, 16, 13, 10, 7, 4, 1), (99, 99, 99, 99, 99, 20, 16, 13, 10, 7, 1),
    (99, 99, 99, 99, 99, 99, 20, 16, 13, 10, 4),
    (99, 99, 99, 99, 99, 99, 99, 20, 16, 13, 10), (99, 99, 99, 99, 99, 99, 99, 99, 19, 16, 10),
    (99, 99, 99, 99, 99, 99, 99, 99, 20, 19, 13));
  { by row offset, then radius, and [y,3] reads the next row }
  areaHalfWidths: array[-3..3, 0..2] of ShortInt = (
    (0, -3, -3), (1, -3, 1), (2, 1, 2), (3, 1, 2), (3, 1, 2), (3, -3, 1), (2, -3, -3));
  { never read }
  areaHalfWidthsTail: array[0..1] of Byte = (
    1, 0);
  { by class: dice rolled at first level }
  firstLevelHitDice: array[0..7] of Byte = (
    2, 1, 1, 1, 2, 1, 1, 2);
  { by class: the hit die's sides }
  hitDieSides: array[0..7] of Byte = (
    8, 8, 10, 10, 8, 4, 6, 10);
  { the spell list's level headings, by spell level; Magic reads them }
  levelHeadings: array[0..9] of String[40] = (
    'Special', '1st Level', '2nd Level', '3rd Level', '4th Level', '5th Level', '6th Level', '7th Level', '8th Level',
    '9th Level');
  { by direction: the column step to a cone's near cell, as CollectConeTargets widens it }
  directionNearX: array[0..7] of ShortInt = (
    -1, 0, 0, 1, 1, 0, 0, -1);
  { by direction: the row step to the near cell }
  directionNearY: array[0..7] of ShortInt = (
    0, -1, -1, 0, 0, 1, 1, 0);
  { by direction: the column step to the far cell }
  directionFarX: array[0..7] of ShortInt = (
    1, 1, 0, 0, -1, -1, 0, 0);
  { by direction: the row step to the far cell }
  directionFarY: array[0..7] of ShortInt = (
    0, 0, 1, 1, 0, 0, -1, -1);
  { the effect ids RemoveEffectsHp0 strips when hit points reach zero }
  hitPointEffectIds: array[1..16] of Byte = (
    3, 6, 11, 21, 23, 27, 30, 31, 35, 52, 53, 77, 106, 107, 111, 118);
  { a zone's sky index to the palette color DisplayMapView paints }
  skyColors: array[0..7] of Byte = (
    0, 15, 4, 11, 13, 2, 9, 14);
  { the first two entries of a second copy of skyColors; never read }
  unreadSkyHead: array[0..1] of Byte = (
    0, 15);
  { the rest of that copy; never read }
  unreadSkyTail: array[0..5] of Byte = (
    4, 11, 13, 2, 9, 14);
  { Portrait.LoadAnimation remaps a transparent sprite through these: light magenta (13) to black }
  animationRemapFrom: Types.TColorTab = (
    0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14,
    15);
  { the colors animationRemapFrom becomes }
  animationRemapTo: Types.TColorTab = (
    0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 0, 14, 15);
  { by slice slot, the first wall symbol DrawWallSlice draws }
  sliceSymbolStart: array[0..9] of Byte = (
    0, 2, 6, 10, 22, 38, 54, 110, 132, 154);
  { by slice slot, its width in symbols }
  sliceColumns: array[0..9] of Byte = (
    1, 1, 1, 3, 2, 2, 7, 2, 2, 1);
  { by slice slot, its height in symbols }
  sliceRows: array[0..9] of Byte = (
    2, 4, 4, 4, 8, 8, 8, 11, 11, 2);
  { the view column each slice slot is drawn at; View3D adds a signed offset }
  sliceX: array[0..9] of Integer = (
    5, 4, 6, 4, 2, 7, 2, 0, 9, 5);
  { the view row each slice slot is drawn at }
  sliceY: array[0..9] of Integer = (
    4, 3, 3, 3, 1, 1, 1, 0, 0, 4);
  { by column, the frame symbol of the window's top row }
  borderTopRow: array[0..39] of Byte = (
    0, 4, 4, 4, 4, 4, 4, 5, 4, 6, 4, 4, 4, 4, 4, 4, 4, 4, 5, 4, 6, 4, 4,
    4,
    4, 4, 4, 4, 4, 5, 4, 6, 4, 4, 4, 4, 4, 4, 4, 1);
  { by column, the frame symbol of the window's bottom row }
  borderBottomRow: array[0..39] of Byte = (
    2, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,
    4,
    4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 3);
  { by column, the frame symbol of a row divider }
  dividerRow: array[0..39] of Byte = (
    10, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,
    4,
    4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 11);
  { by row, the frame symbol of the view's inset column }
  insetColumn: array[0..39] of Byte = (
    8, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 9, 0, 7, 7, 7, 7, 7,
    7,
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 2);
  { by row, the frame symbol of the column between the combat screen's two panes }
  dualPaneColumn: array[0..22] of Byte = (
    8, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 9);
  { never read }
  unreadColumn: array[0..21] of Byte = (
    1, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7);
  { by row, the frame symbol of the character sheet's left column }
  combatLeftColumn: array[0..21] of Byte = (
    3, 7, 7, 7, 7, 7, 7, 7, 10, 7, 7, 7, 7, 7, 7, 7, 10, 7, 7, 7, 10, 7);
  { by row, the frame symbol of the character sheet's right column }
  combatRightColumn: array[0..22] of Byte = (
    7, 7, 7, 7, 7, 7, 7, 7, 11, 7, 7, 7, 7, 7, 7, 7, 11, 7, 7, 7, 11, 7, 7);
  { by row, the character sheet's middle column; Border draws it at rows 8..20 }
  combatMidColumn: array[8..21] of Byte = (
    8, 7, 7, 7, 7, 7, 7, 7, 12, 7, 7, 7, 9, 0);
  { by CGA color, the byte FillPicRect repeats to fill four pixels }
  cgaFillBytes: array[0..3] of Byte = (
    $00, $55, $AA, $FF);
  { by Tandy color, the byte that fills two pixels }
  tandyFillBytes: array[0..15] of Byte = (
    $00, $11, $22, $33, $44, $55, $66, $77, $88, $99, $AA, $BB, $CC, $DD, $EE, $FF);
  { where DisplayMessageWindow may break a line }
  breakChars: set of ' '..'?' = ['!', ',', '-', '.', ':', ';', '?'];
  { the characters SanitizeFileName strips from a save name }
  invalidFileChars: array[1..10] of Char = (' ', '.', '*', ',', '?', '/', '\', ':', ';', '|');
  { The script variable indices into zone 1, offset by the zone's base: the training hall's class mask, which CharGen
    views }
  trainMaskIndex: Word = $02A8;
  { the farthest a monster group may start }
  monsterMaxDistIndex: Word = $02C0;
  { how far away the monsters start }
  monsterDistIndex: Word = $02C1;
  { the monsters' base morale }
  moraleBaseIndex: Word = $02C6;
  { how the last fight ended, for the script }
  combatResultIndex: Word = $02C7;
  { the monsters killed in the last fight }
  monstersDefIndex: Word = $02C8;
  { the party may not move }
  moveLockedIndex: Word = $02C9;
  { the party is searching }
  searchFlagsIndex: Word = $02CA;
  { who is surprised as a fight starts }
  surpriseIndex: Word = $02CB;
  { while it is positive CampRest checks for an interruption }
  restPeriodIndex: Word = $02D2;
  { the chance a rest is interrupted }
  interruptPctIndex: Word = $02D3;
  { set when the party walks off the map }
  leaveMapIndex: Word = $02D5;
  { never read }
  leaveMapIndexTail: Word = $02D9;
  { 1 when EclCombat enters a temple instead of a fight }
  enterTempleIndex: Word = $02E2;
  { the fight leaves no items }
  noCombatItemsIndex: Word = $02E3;
  { the fallen party is revived after the fight }
  reviveFlagIndex: Word = $02E6;
  { a party member struck an ally }
  attackedAlliesIndex: Word = $0333;
  { the party's size, for the loot split }
  partySizeIndex: Word = $033E;
  { the remainder of the script's last division }
  divRemainderIndex: Word = $033F;
  { the shop's price level }
  priceLevelIndex: Word = $036D;
  { the script's adjustment to the monsters' THAC0 }
  modMonThac0Index: Word = $0370;
  { the script's adjustment to the party's THAC0 }
  modPartyThac0Index: Word = $0371;
  { the script's adjustment to the party's movement }
  modPartyMoveIndex: Word = $0372;
  { never read }
  modPartyMoveIndexTail: Word = $03F6;
  { never read }
  pressToContinueLead: Word = $0001;
  { The game's text, by the routines that show it. The pause line a message ends on in combat and the script }
  pressToContinue: String[33] = 'Press button or enter to continue';
  { the same line as a one-choice menu }
  pressToContinueMenu: String[34] = '~Press button or enter to continue';
  { by class id, for the character sheet and creation }
  classNames: array[0..17] of String[26] = (
    'Cleric', 'Druid', 'Fighter', 'Paladin', 'Ranger', 'Mage', 'Thief', 'Knight', 'Cleric/Fighter',
    'Cleric/Fighter/Mage',
    'Cleric/Ranger', 'Cleric/Mage', 'Cleric/Thief', 'Fighter/Mage', 'Fighter/Thief', 'Fighter/Mage/Thief', 'Mage/Thief',
    '0 Level');
  { by race id }
  raceNames: array[0..7] of String[15] = (
    'Silvanesti Elf', 'Qualinesti Elf', 'Half-elf', 'Mountain Dwarf', 'Hill Dwarf', 'Kender', 'Human', 'Monster');
  { by alignment id }
  alignmentNames: array[0..8] of String[16] = (
    'Lawful Good', 'Lawful Neutral', 'Lawful Evil', 'Neutral Good', 'True Neutral', 'Neutral Evil', 'Chaotic Good',
    'Chaotic Neutral', 'Chaotic Evil');
  { by deity id, 0 none }
  deityNames: array[0..7] of String[11] = (
    'None', 'Paladine', 'Majere', 'Kiri-Jolith', 'Mishakal', 'Sirrion', 'Reorx', 'Shinare');
  { by TCharacter.robeOrder, 0 no order }
  robeOrderNames: array[0..3] of String[6] = (
    '', 'White', 'Red', 'Black');
  { by gender }
  genderNames: array[0..1] of String[6] = (
    'Male', 'Female');
  { by coin kind; the last two are the gem and jewelry counts }
  moneyNames: array[0..6] of String[10] = (
    'Silver', 'Copper', 'Bronze', 'Platinum', 'Steel', 'Gems', 'Jewelry');
  { by TCharacter.status }
  statusNames: array[0..8] of String[12] = (
    'Okay', 'Animated', 'tempgone', 'Running', 'Unconscious', 'Dying', 'Dead', 'Stoned', 'Gone');
  { the party menu CharGen.MainMenu shows, with each line's starting enable }
  partyMenuItems: array[0..12] of Types.TMenuItem = (
    (caption: 'Create New Character'; enabled: 1), (caption: 'Drop Character'; enabled: 0),
    (caption: 'Modify Character'; enabled: 0), (caption: 'Train Character'; enabled: 0),
    (caption: 'Knight Change Order'; enabled: 0), (caption: 'View Character'; enabled: 0),
    (caption: 'Add Character to Party'; enabled: 1), (caption: 'Remove Character from Party'; enabled: 0),
    (caption: 'Load Saved Game'; enabled: 1), (caption: 'Save Current Game'; enabled: 0),
    (caption: 'Begin Adventuring'; enabled: 0), (caption: 'Initialize Mouse/Joystick'; enabled: 1),
    (caption: 'Exit to DOS'; enabled: 1));
  { Magic.CastSpell and ViewChar ask it before an item is used up }
  loseQuery: String[40] = 'Lose it? ';
  { Magic.CastSpell, for a spell the area forbids }
  cantCastHereText: String[40] = 'Can''t be cast here...';
  { Magic.CastSpell's subject for an item's spell }
  itemLabel: String[40] = 'That item';
  { Magic.CastSpell, for a combat-only item used outside combat }
  combatOnlyItemText: String[40] = 'Is a combat-only item...';
  { Magic.CastSpell, before an item's spell }
  useItemPrompt: String[40] = 'Use it? ';
  { Magic.CastSpell's verb in the casting line }
  castsText: String[40] = 'casts';
  { Magic.CastSpell's question once a spell is chosen }
  abortSpellPrompt: String[40] = 'Abort Spell';
  { Magic.CastSpell's answer when it is aborted }
  spellAbortedText: String[40] = 'Spell Aborted';
  { Money.TakeMoneyMenu's prompt for gems and jewelry, before the kind }
  howMany: String[40] = 'How many ';
  { the end of Money.TakeMoneyMenu's prompt }
  takePromptTail: String[40] = ' will you take? ';
  { the prompt for coins, before the kind }
  howMuch: String[40] = 'How much ';
  { Money.AppraiseMenu's count of gems }
  gemsCountLabel: String[40] = 'gems : ';
  { Money.AppraiseMenu's count of jewelry }
  jewelryCountLabel: String[40] = 'jewelry : ';
  { Money.AppraiseMenu's heading over the two counts }
  collectionMessage: String[40] = 'You have a fine collection of:';
  { Money.AppraiseMenu's valuation of one gem }
  gemValuePrefix: String[40] = 'The gem is valued at ';
  { Money.AppraiseMenu's valuation of one jewel }
  jewelValuePrefix: String[40] = 'The jewel is valued at ';
  { the coin menu's prompt when taking, dropping or trading money }
  selectCoinQuery: String[40] = 'select type of coin ';
  { ViewChar.TradeTreasureMenu's prompt for the receiving character }
  tradeToText: String[40] = 'trade to?';
  { the end of ViewChar.TradeTreasureMenu's amount prompt }
  tradeAmountText: String[40] = 'will you trade? ';
  { GameTime.CampRest's question when a rest is broken off }
  stopRestPrompt: String[40] = 'Stop resting? ';
  { ViewChar.CheckItemAvail, for a scroll a character is scribing from }
  scribeMessage: String[40] = ' was going to scribe from that scroll';
  { ViewChar.UseItemMenu's heading }
  itemsLabel: String[40] = 'Items';
  { ViewChar.UseItemMenu's heading while readying }
  readyItemLabel: String[40] = 'Ready Item';
  { the start of ViewChar.UseItemMenu's drop warning }
  dropYour: String[40] = 'Your ';
  { the end of the drop warning, which Camp shows too }
  goneForever: String[40] = 'will be gone forever';
  { ViewChar.UseItemMenu, for an item used before it is readied }
  mustBeReadied: String[40] = 'Must be readied';
  { the start of ViewChar.SellItem's offer }
  sellOfferPrefix: String[40] = 'I''ll give you ';
  { the middle of the offer }
  steelPiecesFor: String[40] = ' steel pieces for your ';
  { the end of a sale or identify offer }
  dealQuery: String[40] = 'is it a deal? ';
  { ViewChar.SellItem once a sale is made }
  soldText: String[40] = 'sold!';
  { a payment a character cannot carry goes to the pool }
  overloadPoolText: String[40] = 'overloaded. money will be put in pool.';
  { ViewChar.IdentifyItem's offer }
  identifyOfferText: String[40] = 'for 100 steel pieces i''ll identify your ';
  { ViewChar.IdentifyItem for an item already identified }
  identifyNoNewsText: String[40] = 'i cannot tell anything new about your ';
  { ViewChar.IdentifyItem's answer, before the kind }
  identifyKindText: String[40] = 'it looks like some sort of ';
  { the end of ViewChar.DropMoneyMenu's amount prompt when dropping }
  dropAmountText: String[40] = 'will you drop? ';
  { the end of the amount prompt when depositing }
  giveAmountText: String[40] = 'will you deposit? ';
  { the quit question in camp and on the party menu }
  quitToDosPrompt: String[40] = 'Quit to DOS ';
  { CharGen.MainMenu's quit question while the game is unsaved }
  quitUnsavedQuery: String[40] = 'game not saved. quit anyway? ';
  { CharGen.CreateCharacterMenu's race menu title }
  pickRaceMenu: String[40] = 'Pick Race';
  { the gender menu title }
  pickGenderMenu: String[40] = 'Pick Gender';
  { the class menu title }
  pickClassMenu: String[40] = 'Pick Class';
  { the deity menu title }
  pickDeityMenu: String[40] = 'Pick Diety';
  { the alignment menu title }
  pickAlignmentMenu: String[40] = 'Pick Alignment';
  { CharGen.CreateCharacterMenu's question over the rolled stats }
  rerollStatsQuery: String[40] = 'reroll stats? ';
  { its name prompt }
  characterNameQuery: String[40] = 'character name: ';
  { its last question }
  saveCharacterQuery: String[40] = 'save character? ';
  { the start of CharGen.DropCharacterMenu's question }
  dropPrefix: String[40] = 'drop ';
  { the middle of the question, after the name }
  foreverText: String[40] = ' forever ';
  { CharGen.DropCharacterMenu's confirmation }
  areYouSureQuery: String[40] = 'Are you sure? ';
  { one of CharGen.DropCharacterMenu's farewells, after the name }
  dumpedOutBackText: String[40] = ' is dumped out back.';
  { another farewell }
  bidsFarewellText: String[40] = ' bids you farewell.';
  { the party's farewell, after the rest of the party's names }
  sighOfReliefText: String[40] = ' breathe a sigh of relief.';
  { CharGen.ModifyCharacterMenu, for a character that cannot be modified }
  cantBeModifiedText: String[40] = ' can''t be modified.';
  { CharGen.AddCharacterMenu's question for the source game }
  addFromWhereQuery: String[40] = 'add from where? ';
  { its title over the character list }
  addCharacterQuery: String[40] = 'add a character: ';
  { CharGen.CustomizeIcon, which needs a color adapter }
  sorryNotInCgaText: String[40] = 'sorry not in CGA';
  { the heading over CustomizeIcon's two poses }
  readyActionHeading: String[40] = 'ready   action';
  { CustomizeIcon's label over the icon being made }
  newText: String[40] = 'new';
  { its label over the icon as it was }
  oldText: String[40] = 'old';
  { CustomizeIcon's last question }
  iconOkQuery: String[40] = 'is this icon ok? ';
  { CharGen.TrainingMenu, for a character short of the next level }
  notEnoughExperienceText: String[40] = 'not enough experience';
  { TrainingMenu's line after the name }
  willBecomeText: String[40] = ' will become:';
  { the start of each class line it lists }
  aLevelText: String[40] = '    a level ';
  { the start of each further class line }
  andALevelText: String[40] = 'and a level ';
  { TrainingMenu's question }
  wishToTrainQuery: String[40] = 'do you wish to train? ';
  { after training, and EclVm's experience award }
  congratulationsText: String[40] = 'congratulations...';
  { CharGen.KnightPromotionMenu's line after the name }
  petitioningText: String[40] = 'is petitioning to become a';
  { the order of the Sword }
  swordText: String[40] = 'sword';
  { the order of the Rose }
  roseText: String[40] = 'rose';
  { before the order }
  knightOfTheText: String[40] = 'knight of the ';
  { KnightPromotionMenu, for a knight below the order's level }
  tooInexperiencedText: String[40] = ' is too inexperienced';
  { KnightPromotionMenu, for a knight below the order's stat floors }
  doesNotQualifyText: String[40] = ' does not qualify.';
  { KnightPromotionMenu, for a knight who qualifies }
  mayBecomeText: String[40] = ' may become a';
  { SaveLoad.CheckSaveDir asks for the imported characters' save disk, before the drive letter }
  askChampionsDiskPrefix: String[40] = 'is your c.o.k. save disk in drive ';
  { CheckSaveDir asks for this game's save disk }
  askSaveDiskPrefix: String[40] = 'is your save disk in drive ';
  { after the drive letter }
  askDiskSuffix: String[40] = ':? ';
  { this game's save directory is missing }
  noSaveDirectoryMessage: String[40] = 'error, can''t locate DKK directory';
  { the imported characters' save directory is missing }
  noChampionsDirectoryMessage: String[40] = 'error, can''t locate champ directory';
  { SaveLoad, when a save does not fit }
  diskFullMessage: String[40] = 'can''t save.  disk is full.';
  { SaveLoad.SaveChar's question for a file that exists, before its name }
  overwritePrefix: String[40] = 'overwrite ';
  { after the name }
  overwriteSuffix: String[40] = '? ';
  { SaveChar's prompt for another name }
  newFileNamePrompt: String[40] = 'new file name : ';
  { Camp.PartyOrderMenu, after the picked name }
  hasBeenSelected: String[40] = 'has been selected';
  { Camp.CampSpeedMenu's line, before the speed }
  gameSpeedPrompt: String[40] = 'Game Speed (0=fastest 9=slowest) = ';
  { Camp.CampMainMenu's heading }
  partyMakesCamp: String[40] = 'the party makes camp...';
  { Explore.MapMainMenu, for a command the area does not allow }
  notHere: String[40] = 'not here';
  { CbtActs.CheckAttackAlly's question }
  attackAllyPrompt: String[40] = 'attack ally? ';
  { the aim menus' range readout }
  rangeLabel: String[40] = 'range = ';
  { the fight's magic switch turned on }
  magicOnMsg: String[40] = 'magic on';
  { turned off }
  magicOffMsg: String[40] = 'magic off';
  { Combat.MoveMenu, at the arena's edge }
  fleePrompt: String[40] = 'flee ? ';
  { Combat.MoveMenu, for a blocked cell }
  cantGoThere: String[40] = 'cant''t go there';
  { Shop.ShopBuyMenu, between the buyer and a counted item }
  buysText: String[40] = ' buys ';
  { between the buyer and a single item }
  buysAText: String[40] = ' buys a ';
  { a purchase or identify the character cannot pay for }
  notEnoughMoneyText: String[40] = 'not enough money.';
  { Shop and Temple, when the party leaves money in the pool }
  leftMoney1: String[80] = 'as you leave a man says, "excuse me but you have left some money here." ';
  { the question that follows }
  leftMoney2: String[80] = 'do you want to go back and get your money?';
  { PostCbt.PostCombatSummary, when the party fled }
  msgPartyFled: String[40] = 'the party has fled.';
  { when the party lost }
  msgLostFight: String[40] = 'you have lost the fight.';
  { when a duel was won }
  msgWonDuel: String[40] = 'you have won the duel.';
  { when the party won }
  msgPartyWon: String[40] = 'the party has won.';
  { never shown }
  withdrawalFeeText1: String[40] = 'the party makes a withdrawl. a small';
  { never shown }
  withdrawalFeeText2: String[40] = 'fee has been assessed by the bank.';
  { PostCombatSummary, when there is loot }
  msgPartyTreasure: String[40] = 'the party has found treasure';
  { when there is none }
  msgNoTreasure: String[40] = 'the party has found no treasure';
  { the experience line after a duel }
  duelistReceives: String[40] = 'the duelist receives ';
  { the experience line after a fight }
  eachReceives: String[40] = 'each character receives ';
  { the end of the experience line }
  experiencePoints: String[40] = 'experience points.';
  { PostCbt.LootMenu, when the party leaves loot behind }
  treasureLeft1: String[40] = 'there is still treasure left. ';
  { the question that follows }
  treasureLeft2: String[80] = 'do you want to go back and claim your treasure?';
  { Temple.ConfirmCureAnyway's question for a character who needs no cure }
  castAnywayPrompt: String[40] = 'cast cure anyway? ';
  { never shown }
  payForCureQuery: String[40] = 'pay for cure? ';
  { after the name, once a cure lands }
  isCuredText: String[40] = 'is cured.';
  { Temple.CureBlindness, for a character who can see }
  notBlindMessage: String[40] = 'is not blind.';
  { never shown }
  notDiseasedMessage: String[40] = 'is not diseased.';
  { Temple.RaiseDead, for one past raising }
  cannotRaiseMessage: String[40] = 'cannot be raised.';
  { Temple.RaiseDead, for one who is alive }
  notDeadMessage: String[40] = 'is not dead.';
  { Temple.NeutralizePoison, for one who is not poisoned }
  notPoisonedMessage: String[40] = 'is not poisoned.';
  { Temple.RemoveCurse, for one who is not cursed }
  notCursedMessage: String[40] = 'is not cursed.';
  { Temple.StoneToFlesh, for one who is not stone }
  notStonedMessage: String[40] = 'is not stoned.';
  { Temple.Restoration, for one who lost no levels }
  noLostLevelsMessage: String[40] = 'has no lost levels.';
  { Temple.HealMenu's greeting, after the name }
  howCanWeHelp: String[40] = ', how can we help you?';
  { the empty prompt a menu shows when it asks nothing }
  emptyQuery: String[40] = '';
  { the title menu's heading }
  gameTitle: String[40] = 'Death Knights Of Krynn 1.00 ';
  { Magic.SpellSelection's prompt }
  chooseSpellQuery: String[40] = 'Choose Spell:';
  { Magic.SpellFireShield's prompt }
  flameTypePrompt: String[40] = 'Flame type: ';
  { Money.AppraiseMenu's prompt }
  appraiseQuery: String[40] = 'Appraise : ';
  { ViewChar.PickCharacter's prompt }
  pickCharacterText: String[40] = 'Pick Character ';
  { CharGen.ModifyCharacterMenu's prompt }
  modifyQuery: String[40] = 'Modify : ';
  { CharGen.InitMouseJoystick's prompt }
  initInputQuery: String[40] = 'Init mouse/joystick: ';
  { SaveLoad.SaveChar's question when a save fails }
  loseCharacterPrompt: String[40] = 'lose character? ';
  { SaveLoad.LoadGame's question for the source game }
  loadFromWherePrompt: String[40] = 'load from where? ';
  { its prompt for the save letter }
  loadWhichGamePrompt: String[40] = 'load which game: ';
  { SaveLoad.SaveGame's prompt for the save letter }
  saveWhichGamePrompt: String[40] = 'save which game: ';
  { Magic.SpellSelection's confirmation }
  spellsOkQuery: String[40] = 'spells OK? ';
  { Camp.CampScribeMenu's confirmation }
  scribeConfirmPrompt: String[40] = 'scribe these spells? ';
  { Camp.PartyOrderMenu's prompt }
  orderQuery: String[40] = 'party order ';
  { the speed menus' prompt, before the speed }
  gameSpeedLabel: String[40] = 'game speed: ';
  { the aim menu's prompt }
  aimPrompt: String[40] = 'aim: ';
  { CbtActs.ManualAimCursor's hint }
  cursorPrompt: String[40] = '(use cursor keys) ';
  { Combat.EndOfRound's question once no enemy is in sight }
  continueBattle: String[40] = 'continue battle? ';
  { Combat.MoveMenu's prompt, before the moves left }
  moveQueryLabel: String[40] = 'move/attack, move left = ';
  { the item list's prompt in shop and loot }
  itemsQuery: String[40] = 'items : ';
  { PostCbt.LootTakeMenu's prompt }
  takeQuery: String[40] = 'take: ';
  { the empty choice string a menu shows when it offers nothing }
  emptyMenu: String[40] = '';
  { the title menu's choices }
  playDemoMenu: String[40] = 'Play Demo';
  { MenuCore.YesNoMenu's choices }
  yesNoOptions: String[40] = 'Yes No';
  { the one-word menu over a list to pick from }
  selectMenuText: String[40] = 'Select';
  { Magic.SpellSelection's word when casting }
  castMenu: String[40] = 'Cast';
  { when memorizing }
  memorizeMenu: String[40] = 'Memorize';
  { when keeping }
  keepMenu: String[40] = 'Keep';
  { when scribing }
  scribeMenu: String[40] = 'Scribe';
  { when learning }
  learnMenu: String[40] = 'Learn';
  { Magic.SpellFireShield's choices }
  flameTypeMenu: String[40] = 'Hot Cold';
  { Money.AppraiseMenu's choices }
  appraiseOptions: String[40] = 'Gems Jewelry Exit';
  { its choices over a valuation }
  sellMenu: String[40] = 'Sell Keep';
  { GameTime.CampRestMenu's choices }
  restMenu: String[40] = 'Rest Days Hours Mins Add Subtract Exit';
  { ViewChar.ViewCharMenu's choices }
  viewMenu: String[80] = 'Items Spells Trade Deposit Drop Heal Cure Exit';
  { ViewChar.UseItemMenu's choices }
  itemsMenu: String[80] = 'Ready Use Trade Deposit Drop Halve Join Sell Id Exit';
  { CharGen.ModifyCharacterMenu's choices }
  modifyMenu: String[40] = 'Add Subtract Keep Exit';
  { the source-game choices when adding or loading }
  sourceGameMenu: String[40] = 'Death Champions Exit';
  { CharGen.AddCharacterMenu's choice }
  addMenu: String[40] = 'Add';
  { CharGen.KnightPromotionMenu's choices }
  changeExitMenu: String[40] = 'Change Exit';
  { SaveLoad.SaveChar's choices when a save fails }
  tryAnotherDiskMenu: String[40] = 'Ok Try another disk';
  { the save letters SaveLoad offers }
  saveSlotMenu: String[40] = 'A B C D E F G H I J';
  { Camp.PartyOrderMenu's choices }
  orderMenu: String[40] = 'Select Place Exit';
  { the speed menus' choices }
  speedChoices: String[40] = 'Faster Slower Exit';
  { Explore.MapMainMenu's choices }
  dungeonMenu: String[40] = 'Move Area Cast View Encamp Search Look';
  { the extra choice MapMainMenu adds }
  exitMenu: String[40] = 'Exit';
  { Combat.CombatMenu's choices }
  commandChoices: String[80] = 'Move Aim Use Cast Turn Guard Quick@Delay Bandage Yell View Speed End';
  { Combat.MoveMenu's choice }
  moveChoices: String[40] = 'Done';
  { CbtActs.AimTargetMenu's choices }
  aimMenuOptions: String[40] = 'Next Prev Manual Target Center Exit';
  { CbtActs.ManualAimCursor's choices }
  cursorMenu: String[40] = 'Target Exit';
  { Shop.ShopBuyItemSelection's choice }
  buyMenu: String[40] = 'Buy';
  { Shop.ShopMainMenu's choices }
  shopMenu: String[40] = 'Buy View Take Pool Share Appraise Exit';
  { the blanks ShopBuyItemSelection clears a line with }
  spaces30: String[30] = '                              ';
  { PostCbt.LootTakeItemSelection's choice }
  takeMenu: String[40] = 'Take';
  { PostCbt.LootTakeMenu's choices }
  moneyItemsMenu: String[40] = 'Money Items Exit';
  { PostCbt.LootMenu's choices }
  treasureMenu: String[40] = 'View Take Pool Share Detect Exit';
  { Temple.HealMenu's choice }
  healOptions: String[40] = 'Heal';
  { Temple.TempleMainMenu's choices }
  templeMenu: String[40] = 'Heal View Take Pool Share Appraise Exit';
  { Vault.PoolVault's choices }
  vaultMenu: String[40] = 'View Take Pool Money Items Exit';
  { by menu state }
  iconMenus: array[1..5] of String[45] = (
    'Parts 1st-color 2nd-color Size Exit', 'Head Weapon Exit', 'Weapon Body Hair Face Shield Arm Leg Exit',
    'Small Large Keep Exit', 'Next Prev Keep Exit');
  { Camp.CampMainMenu's choices }
  campMenu: String[40] = 'Save View Magic Rest Alter Fix Exit';
  { Camp.CampMagicMenu's choices }
  magicMenu: String[40] = 'Cast Memorize Scribe Display Rest Exit';
  { Camp.CampAlterMenu's choices }
  alterMenu: String[40] = 'Order Drop Speed Icon Level Exit';
  { Camp.CampDifficultyMenu's choices }
  levelMenu: String[40] = 'Novice Squire Veteran Adept Champion';
  { MenuCore.MenuVertical's paging choices: next page }
  menuNextText: String[40] = ' Next';
  { previous page }
  menuPrevText: String[40] = ' Prev';
  { leave }
  menuExitText: String[40] = ' Exit';
  { by TItem.nameIds }
  itemNameParts: array[1..125] of String[20] = (
    'Battle Axe', 'Hand Axe', 'Club', 'Dagger', 'Dart', 'Hammer', 'Javelin', 'Mace', 'Morning Star', 'Military Pick',
    'Awl Pike',
    'Quarrel', 'Scimitar', 'Spear', 'Quarter Staff', 'Bastard Sword', 'Broad Sword', 'Long Sword', 'Short Sword',
    'Two-Handed Sword', 'Trident', 'Composite Long Bow', 'Composite Short Bow', 'Long Bow', 'Short Bow', 'Fine',
    'Light Crossbow', 'Sling', 'Staff', 'Arrow', 'Leather', 'Ring', 'Scale', 'Chain', 'Banded', 'Plate', 'Shield',
    'Cler', 'Scroll',
    'MU Scroll', 'Helm', 'Belt', 'Robe', 'Cloak', 'Boots', 'Ring', 'Mail', 'Armor', 'Of Prot', 'Bracers', 'Wand',
    'Amulet', 'Potion',
    'Holy Water', 'Ruby', 'Boulder', 'Dragon Breath', 'Displacement', 'Bag', 'Drow', 'Elven Chain', 'Ice Storm',
    'Saphire',
    'Emerald', 'Wizardry', 'Hornet''s Nest', 'Hoopak', 'Solamnic Plate', 'Dragonlance', 'Flail', 'Halberd', 'Gauntlets',
    'Periapt', 'Proof vs Poison', 'Elixir Of Youth', 'Eyes Of Charming', 'Disruption', 'Ogre Power', 'Girdle',
    'Giant Strength', 'Mirror', 'Necklace', 'Dragon', 'vs Reptiles', 'Frost Brand', 'Berserker', 'Diamond', 'Lightning',
    'Fireballs', 'of', 'Vulnerability', 'Speed', 'Silver', 'Extra', 'Healing', 'Olin''s', 'Fear', 'Magic Missiles',
    'Missiles',
    '1 Spell', '2 Spells', '3 Spell', 'Paralyzation', 'Invisibility', 'Footman''s', 'AC 10', 'AC 6', 'AC 4', 'AC 3',
    'AC 2', '+1',
    '+2', '+3', '+4', '+5', '-1', '-2', '-3', 'White', 'Red', 'Spiritual', 'Gem', 'Jewelry', 'Blank', 'Item');
  { The BIOS video service and its function numbers. The interrupt every video call goes through }
  videoInterrupt: Byte = $10;
  { set the video mode }
  biosSetVideoMode: Byte = $00;
  { place the cursor }
  biosSetCursor: Byte = $02;
  { select the display page }
  biosSetPage: Byte = $05;
  { write a character with its attribute }
  biosWriteChar: Byte = $09;
  { read the video mode }
  biosGetVideoMode: Byte = $0F;
  { the CGA 320x200 four-color mode }
  cgaVideoMode: Byte = $04;
  { the EGA 320x200 sixteen-color mode }
  egaVideoMode: Byte = $0D;
  { the Tandy 320x200 sixteen-color mode }
  tandyVideoMode: Byte = $09;
  { the input status port $03DA and its retrace bit $08 }
  unreadRetraceCheck: array[0..3] of Byte = (
    $00, $DA, $03, $08);
  { The EGA sequencer and graphics controller. The sequencer's index port }
  sequencerAddressPort: Word = $03C4;
  { its data port }
  sequencerDataPort: Word = $03C5;
  { the sequencer's plane write mask }
  mapMaskRegister: Byte = $02;
  { the graphics controller's index port }
  graphicsAddressPort: Word = $03CE;
  { its data port }
  graphicsDataPort: Word = $03CF;
  { the graphics controller's registers: set/reset }
  setResetRegister: Byte = $00;
  { enable set/reset }
  enableSetResetRegister: Byte = $01;
  { color compare }
  colorCompareRegister: Byte = $02;
  { data rotate and function select }
  dataRotateRegister: Byte = $03;
  { the plane a read comes from }
  readMapRegister: Byte = $04;
  { the read and write modes }
  graphicsModeRegister: Byte = $05;
  { color don't care }
  colorDontCareRegister: Byte = $07;
  { the bit mask }
  bitMaskRegister: Byte = $08;
  { the data-rotate functions: replace, AND, OR, XOR }
  unreadRotateFunctions: array[0..3] of Byte = (
    $00, $08, $10, $18);
  { the mode register's write mode 0, the CPU's data through the bit mask }
  writeMode0: Byte = $00;
  { write mode 1, the latches copied }
  writeMode1: Byte = $01;
  { write mode 2, a color to each plane }
  writeMode2: Byte = $02;
  { read mode 0, one plane read }
  readMode0: Byte = $00;
  { never read }
  readMode0Tail: array[0..1] of Byte = (
    11, 0);
  { CharHlp.PrintMiscInfo's compass label by facing, and Pathing's step by (dy, dx) }
  directionLegend: Types.TDirectionLegend = (
    names: ('N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW');
    matrix: ((7, 0, 1), (6, 8, 2), (5, 4, 3)));
  { never read }
  unreadPixelTable: array[0..15] of Byte = (
    $00, $A0, $00, $A2, $08, $04, $02, $01, $00, $00, $55, $55, $AA, $AA, $FF, $FF);
  { text attribute -> CGA color index, DaxIo's and TextRend's }
  cgaAttributeColors: array[0..15] of Byte = (
    0, 0, 0, 1, 2, 2, 2, 3, 0, 1, 1, 1, 2, 2, 3, 3);
  { the two bits of CGA pixel 0..7 within a word }
  cgaPixelMasks: array[0..7] of Word = (
    $C000, $3000, $0C00, $0300, $00C0, $0030, $000C, $0003);

{ Picture drawing: the EGA plane bits, the CGA pixel values, the drawing modes and header sizes Blit reads, the color
  maps, the sound cues, the disk prompts, the text renderer's settings, and the combat grid's fixed tables. }
const
  { the map mask bit of EGA plane 0..3 }
  egaPlaneBits: array[0..3] of Byte = (
    $01, $02, $04, $08);
  { CGA color 0..3 at pixel 0..3 of a byte }
  cgaPixelValues: array[0..3, 0..3] of Byte = (
    ($00, $00, $00, $00), ($40, $10, $04, $01), ($80, $20, $08, $02), ($C0, $30, $0C, $03));
  { never read }
  unreadMode0: Byte = 0;
  { never read }
  unreadMode1: Byte = 1;
  { the mode the drawing units pass to LoadPic and its kin: 0 opaque }
  pictureMode: Byte = 0;
  { the mode bit for a framed, transparent image }
  iconFrame: Byte = 1;
  { never read }
  unreadMode2: Byte = 2;
  { the mode bit that saves what an image covers }
  saveUnderBit: Byte = $04;
  { the size of a Blit image's header }
  imgHeaderSize: Byte = 23;
  { the size of a picture's header in a DAX archive }
  daxHeaderSize: Byte = 17;
  { the CGA color pairs a sixteen-color picture is mapped to }
  cgaColorMap: Types.TColorMap = (
    $00, $11, $22, $12, $01, $21, $30, $33);
  { the colors an icon is remapped from: all sixteen }
  iconRemapFrom: Types.TColorTab = (
    0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15);
  { the colors they become: dark gray (8) to black }
  iconRemapTo: Types.TColorTab = (
    0, 1, 2, 3, 4, 5, 6, 7, 0, 9, 10, 11, 12, 13, 14, 15);
  { The sound command numbers the game passes to SoundDrv.SoundCommand. Reset the driver }
  soundReset: Word = 255;
  { sound off }
  soundOff: Word = 0;
  { sound on }
  soundOn: Word = 1;
  { a spell cast }
  spellSound: Word = 2;
  { never played }
  soundCue3: Word = 3;
  { an effect lands }
  effectSound: Word = 4;
  { a combatant falls }
  downedSound: Word = 5;
  { a missile's second sound }
  missileSound2: Word = 6;
  { a hit }
  hitSound: Word = 7;
  { lightning }
  lightningSound: Word = 8;
  { damage }
  damageSound: Word = 9;
  { a step }
  stepSound: Word = 10;
  { a fireball }
  fireballSound: Word = 11;
  { a missile in flight }
  missileSound: Word = 12;
  { never played }
  soundCue13: Word = 13;
  { never played }
  soundCue14: Word = 14;
  { never played }
  soundCue15: Word = 15;
  { never played }
  soundCue400: Word = 1024;
  { the archive suffix the DaxIo.LoadDax callers pass }
  daxExtension: String[4] = '.dax';
  { the status line while a file loads }
  loadingMessage: String[21] = 'Loading...Please Wait';
  { while the game saves }
  savingMessage: String[20] = 'Saving...Please Wait';
  { indexed by DaxIo's diskNumber, 1..5 }
  insertDiskMessages: array[1..5] of String[29] = (
    'Insert disk 2 in drive ', 'Insert disk 3 in drive ', 'Insert disk 4 in drive ',
    { the last two both ask for disk 5 }
    'Insert disk 5 in drive ', 'Insert disk 5 in drive ');
  { never read }
  asciiFlagLead: Byte = 0;
  { the glyph-source selector TextRend and MenuCore pass the renderer }
  asciiFlag: Byte = 1;
  { never read }
  fontExtension: String[4] = '.fnt';
  { never read }
  unreadPair: array[0..1] of Byte = (
    0, 2);
  { the status line's row, which DisplayString and PrintSpaces callers pass with messageColumn }
  messageRow: Byte = 24;
  { the status line's column }
  messageColumn: Byte = 0;
  { a second status row beside messageRow; never read }
  altMessageRow: Byte = 24;
  { the last column of that geometry; never read }
  altLastColumn: Byte = 39;
  { 40 columns; TextRend's width for a whole line }
  screenWidth: Byte = 40;
  { never read }
  unreadQuad: array[0..3] of Byte = (
    3, 46, 36, 56);
  { the first and last symbol number of each 8x8 set, Sym8x8.Put8x8Sym }
  symbolSetFirst: array[0..4] of Word = (
    0, 46, 116, 186, 256);
  { the last symbol number of each set }
  symbolSetLast: array[0..4] of Word = (
    255, 115, 185, 255, 300);
  { never read }
  symbolSetLastTail: array[0..3] of Byte = (
    40, 64, 1, 0);
  { The combat grid's fixed tables: a direction 0..8 to a cell step, 8 the center; the cost, clearance, blocking class
    and code of each tile; the sub-tile offsets by icon size; and the direction passed to Pathing.BuildTargetList when a
    target may lie anywhere. }
  combatTables: Types.TCombatTables = (
    directionX: (0, 1, 1, 1, 0, -1, -1, -1, 0);
    directionY: (-1, -1, 0, 1, 1, 1, 0, -1, 0);
    terrain: (
      (cost: 255; clearance: 1; blocking: 2; code: 0), (cost: 255; clearance: 1; blocking: 2; code: 1),
      (cost: 255; clearance: 1; blocking: 2; code: 2), (cost: 255; clearance: 1; blocking: 2; code: 3),
      (cost: 1; clearance: 1; blocking: 0; code: 4), (cost: 255; clearance: 1; blocking: 2; code: 5),
      (cost: 255; clearance: 1; blocking: 2; code: 6), (cost: 255; clearance: 1; blocking: 2; code: 7),
      (cost: 1; clearance: 1; blocking: 0; code: 8), (cost: 255; clearance: 1; blocking: 2; code: 9),
      (cost: 1; clearance: 1; blocking: 0; code: 10), (cost: 255; clearance: 1; blocking: 2; code: 11),
      (cost: 1; clearance: 1; blocking: 0; code: 12), (cost: 255; clearance: 1; blocking: 2; code: 13),
      (cost: 1; clearance: 1; blocking: 0; code: 14), (cost: 255; clearance: 1; blocking: 2; code: 15),
      (cost: 1; clearance: 1; blocking: 0; code: 16), (cost: 255; clearance: 1; blocking: 2; code: 17),
      (cost: 255; clearance: 1; blocking: 2; code: 18), (cost: 255; clearance: 1; blocking: 2; code: 19),
      (cost: 255; clearance: 1; blocking: 2; code: 20), (cost: 255; clearance: 1; blocking: 2; code: 21),
      (cost: 1; clearance: 1; blocking: 0; code: 22), (cost: 1; clearance: 1; blocking: 0; code: 23),
      (cost: 255; clearance: 1; blocking: 2; code: 24), (cost: 2; clearance: 2; blocking: 0; code: 38),
      (cost: 1; clearance: 1; blocking: 0; code: 39), (cost: 1; clearance: 1; blocking: 0; code: 14),
      (cost: 1; clearance: 1; blocking: 0; code: 13), (cost: 1; clearance: 1; blocking: 0; code: 20),
      (cost: 1; clearance: 1; blocking: 0; code: 21), (cost: 255; clearance: 1; blocking: 2; code: 0),
      (cost: 255; clearance: 1; blocking: 2; code: 1), (cost: 255; clearance: 1; blocking: 2; code: 2),
      (cost: 255; clearance: 1; blocking: 2; code: 3), (cost: 255; clearance: 1; blocking: 2; code: 4),
      (cost: 1; clearance: 1; blocking: 0; code: 5), (cost: 1; clearance: 1; blocking: 0; code: 6),
      (cost: 1; clearance: 1; blocking: 0; code: 7), (cost: 1; clearance: 1; blocking: 0; code: 8),
      (cost: 1; clearance: 1; blocking: 0; code: 9), (cost: 255; clearance: 1; blocking: 2; code: 10),
      (cost: 255; clearance: 1; blocking: 2; code: 11), (cost: 2; clearance: 1; blocking: 0; code: 12),
      (cost: 1; clearance: 1; blocking: 0; code: 13), (cost: 1; clearance: 1; blocking: 0; code: 14),
      (cost: 1; clearance: 1; blocking: 0; code: 15), (cost: 1; clearance: 1; blocking: 0; code: 16),
      (cost: 1; clearance: 1; blocking: 0; code: 17), (cost: 2; clearance: 1; blocking: 0; code: 18),
      (cost: 2; clearance: 1; blocking: 0; code: 19), (cost: 1; clearance: 1; blocking: 0; code: 20),
      (cost: 1; clearance: 1; blocking: 0; code: 21), (cost: 1; clearance: 1; blocking: 0; code: 22),
      (cost: 255; clearance: 1; blocking: 0; code: 23), (cost: 255; clearance: 1; blocking: 0; code: 24),
      (cost: 255; clearance: 1; blocking: 0; code: 25), (cost: 1; clearance: 1; blocking: 0; code: 26),
      (cost: 1; clearance: 1; blocking: 0; code: 27), (cost: 1; clearance: 1; blocking: 0; code: 28),
      (cost: 1; clearance: 0; blocking: 0; code: 29), (cost: 1; clearance: 0; blocking: 0; code: 30),
      (cost: 255; clearance: 0; blocking: 0; code: 31), (cost: 255; clearance: 1; blocking: 0; code: 32),
      (cost: 2; clearance: 1; blocking: 0; code: 33), (cost: 1; clearance: 1; blocking: 0; code: 34),
      (cost: 255; clearance: 1; blocking: 0; code: 35), (cost: 1; clearance: 1; blocking: 0; code: 36),
      (cost: 1; clearance: 1; blocking: 0; code: 37));
    iconDelta: (
      ((dx: 0; dy: 0), (dx: -1; dy: -1), (dx: -1; dy: -1), (dx: -1; dy: -1)),
      ((dx: 0; dy: 0), (dx: 0; dy: 1), (dx: -1; dy: -1), (dx: -1; dy: -1)),
      ((dx: 0; dy: 0), (dx: 1; dy: 0), (dx: -1; dy: -1), (dx: -1; dy: -1)),
      ((dx: 0; dy: 0), (dx: 1; dy: 0), (dx: 0; dy: 1), (dx: 1; dy: 1)));
    anyDirection: 255);

{ The effect system's id lists and status text, the party files' extensions, the menu's answer codes and key maps, and
  the order an area effect paints its cells. }
const
  { effect ids that leave a character helpless; CharHlp checks them }
  helplessEffects: array[1..3] of Byte = (
    31, 52, 53);
  { effect ids that end with the fight }
  clearEffects: array[1..19] of Byte = (
    3, 6, 11, 13, 21, 23, 27, 30, 35, 40, 52, 53, 57, 31, 77, 107, 108, 111, 118);
  { the status lines EffHndlr and Magic build before an effect name }
  isText: String[3] = 'is ';
  { the negation Magic adds }
  notText: String[4] = 'not ';
  { never shown }
  healedText: String[6] = 'Healed';
  { EffHndlr's evil stench line }
  affectedText: String[8] = 'Affected';
  { never shown }
  unaffectedText: String[10] = 'Unaffected';
  { Magic.SpellFireShield's line }
  protectedText: String[9] = 'Protected';
  { never shown }
  gainsText: String[6] = 'gains ';
  { never shown }
  protectedFromText: String[15] = 'Protected from ';
  { by effect id }
  effectNames: array[1..120] of String[37] = (
    'Blessed', '', 'Harrassed by Snakes', 'Dispelling Evil', 'Detecting Magic', 'Entangled', '', 'Protected from Evil',
    'Wearing Macical Boots', 'Resistant to Cold', 'Charmed', 'Enlarged', 'Magically Highlighted', 'Friendly',
    'Slow Poison',
    'Reading Magic', 'Shielded', '', 'Able to Find Traps', 'Fire Resistant (spell)', 'Silenced', '',
    'Carries Spiritual Hammer', 'Sees Invisible', 'Invisible (spell)', '', 'Befuddled', 'Duplicated', 'Weakened',
    'Nauseated',
    'Helpless', '', 'Blind', '', 'Confused', 'Accursed', 'Blinking', 'Strengthened', 'Hastened', '',
    'Protected from Normal Missiles', 'Slowed', '', '', 'Protected from evil 10'' radius', '', '',
    'toughened from barkskin',
    'Praying', 'Fire Shield, Hot flames', '', 'Held', 'Asleep', 'Fire Shield, Cold flames', 'POISONED', '',
    'Forced To Dance',
    'Mind Blanked', 'Within Major Globe of Invulnerability', 'Armored', 'Mentally Enfeebled', '',
    'Within Minor Globe of Invulnerability', '', '', '', '', '', '', '', '', '', 'Immune to dragon breath',
    'Fire Touch', '', '', '',
    '', '', '', '', '', '', '', '', '', '', '', 'Wearing Magical Cloak', '', '', '', '', '', '', '', '', '', '', '',
    '', '', '', '', '', '',
    'Berserk', '', '', '', '', '', 'Frost Giant Strength', '', '', '', '', '', '', '');
  { never read }
  unreadNameSlot: array[0..38] of Byte = (
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
  { the extension of one character's file }
  characterExtension: String[4] = '.pc';
  { of the saved game }
  savedCharacterExtension: String[4] = '.gam';
  { of the roster of a save's characters; never read }
  whoExtension: String[4] = '.who';
  { of an imported party's saved game }
  championsSavedExtension: String[4] = '.sav';
  { the menu choice index a Yes/No prompt returns for Yes, not a scancode }
  yesKey: Byte = 0;
  { for No }
  noKey: Byte = 1;
  { '1'..'9' as the arrow scan codes, which MenuCore and CharGen turn into a direction }
  digitKeys: array[0..8] of Byte = (
    79, 80, 81, 75, 32, 77, 71, 72, 73);
  { the area map's cell, by row and column, to a direction key }
  directionKeys: array[3..13, 3..13] of Byte = (
    (72, 72, 72, 72, 72, 72, 72, 72, 72, 72, 72),
    (75, 72, 72, 72, 72, 72, 72, 72, 72, 72, 77),
    (75, 75, 72, 72, 72, 72, 72, 72, 72, 77, 77),
    (75, 75, 75, 72, 72, 72, 72, 72, 77, 77, 77),
    (75, 75, 75, 75, 72, 72, 72, 77, 77, 77, 77),
    (75, 75, 75, 75, 75, 72, 77, 77, 77, 77, 77),
    (75, 75, 75, 75, 80, 80, 80, 77, 77, 77, 77),
    (75, 75, 75, 80, 80, 80, 80, 80, 77, 77, 77),
    (75, 75, 80, 80, 80, 80, 80, 80, 80, 77, 77),
    (75, 80, 80, 80, 80, 80, 80, 80, 80, 80, 77),
    (80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80));
  { a cloud's cells: center, then clockwise from east }
  patchDir: array[1..9] of Byte = (
    8, 2, 3, 4, 5, 6, 7, 0, 1);

{ The spells, the calendar, the save set's other file names, the class, race, progression and saving throw tables, the
  aiming modes and the Tandy heap reserve. }
const
  { by spell id; some ids have no name }
  spellNames: array[1..114] of String[40] = (
    'Bless', 'Barkskin', 'Cure Light Wounds', 'Charm Person/Mammal', 'Detect Magic', 'Protection From Evil',
    'Ressurection',
    'Resist Cold', 'Burning Hands', 'Charm Person', 'Detect Magic', 'Enlarge', 'Reduce', 'Friends', 'Magic Missile',
    'Protection From Evil', 'Restoration', 'Read Magic', 'Shield', 'Shocking Grasp', 'Sleep', 'Find Traps',
    'Hold Person',
    'Resist Fire', 'Silence, 15'' Radius', 'Slow Poison', 'Snake Charm', 'Spiritual Hammer', 'Detect Invisibility',
    'Invisibility', 'Knock', 'Mirror Image', 'Ray of Enfeeblement', 'Stinking Cloud', 'Strength', '', 'Cure Blindness',
    'Cause Blindness', 'Cure Disease', 'Harm', 'Dispel Magic', 'Prayer', 'Remove Curse', 'Bestow Curse', 'Blink',
    'Dispel Magic', 'Fireball', 'Haste', 'Hold Person', 'Invisibility, 10'' Radius', 'Lightning Bolt',
    'Protection From Evil, 10'' Radius', 'Heal', 'Protection From Normal Missiles', 'Slow', 'Death Spell', '',
    'Cure Serious Wounds', '', 'Disentegrate', '', '', 'Globe Of Invulnerability', '', '', 'Stone to Flesh',
    'Neutralize Poison',
    'Poison', 'Protection Evil, 10'' Radius', 'Sticks to Snakes', 'Cure Critical Wounds', 'Flesh to Stone',
    'Dispel Evil',
    'Flame Strike', 'Raise Dead', 'Slay Living', 'Detect Magic', 'Entangle', 'Faerie Fire', 'Invisibility to Animals',
    'Charm Monsters', 'Confusion', 'Dimension Door', 'Fear', 'Fire Shield', 'Fumble', 'Ice Storm',
    'Minor Globe Of Invulnerability', 'Remove Curse', 'Iron Skin', 'Cloud Kill', 'Cone of Cold', 'Feeblemind',
    'Hold Monsters', '', '', '', 'Fire Touch', '', 'Bestow Curse', 'Protection From Evil 10'' Radius',
    'Silence 15'' radius',
    'Detect Magic', 'Remove Curse', 'Bless', 'Charm Person', 'Burning Hands', 'Delay Blast Fireball',
    'Mass Invisibility',
    'Power Word Stun', 'Mass Charm', 'Mind Blank', 'Otto''s Irresitable Dance', 'Power Word Blind');
  { by spell id: the caster class and level, range, duration, targeting, saving throw, the effect FxEngine installs,
    casting time and the AI's priority }
  spellTable: array[1..114] of Types.TSpell = (
    { 1 Bless }
    (castClass: 0; level: 1; range: 6; rangePerLevel: 0; duration: 6; durationPerLevel: 0; targeting: 10; campTarget: 3;
     saveEffect: 0; saveType: 4; effectId: 1; combatOk: 2; castingTime: 10; aiPriority: 1; hostile: 0; hostileTail: 0),
    { 2 Barkskin }
    (castClass: 1; level: 2; range: 0; rangePerLevel: 0; duration: 4; durationPerLevel: 1; targeting: 4; campTarget: 2;
     saveEffect: 0; saveType: 4; effectId: 48; combatOk: 2; castingTime: 3; aiPriority: 1; hostile: 0; hostileTail: 0),
    { 3 Cure Light Wounds }
    (castClass: 0; level: 1; range: 0; rangePerLevel: 0; duration: 0; durationPerLevel: 0; targeting: 4; campTarget: 2;
     saveEffect: 0; saveType: 4; effectId: 0; combatOk: 2; castingTime: 5; aiPriority: 1; hostile: 0; hostileTail: 0),
    { 4 Charm Person/Mammal }
    (castClass: 1; level: 2; range: 8; rangePerLevel: 0; duration: 60; durationPerLevel: 0; targeting: 4; campTarget: 0;
     saveEffect: 1; saveType: 4; effectId: 11; combatOk: 1; castingTime: 4; aiPriority: 2; hostile: 1; hostileTail: 0),
    { 5 Detect Magic }
    (castClass: 0; level: 1; range: 3; rangePerLevel: 0; duration: 10; durationPerLevel: 0; targeting: 0; campTarget: 1;
     saveEffect: 0; saveType: 4; effectId: 5; combatOk: 2; castingTime: 1; aiPriority: 0; hostile: 0; hostileTail: 0),
    { 6 Protection From Evil }
    (castClass: 0; level: 1; range: 0; rangePerLevel: 0; duration: 0; durationPerLevel: 3; targeting: 4; campTarget: 2;
     saveEffect: 0; saveType: 4; effectId: 8; combatOk: 2; castingTime: 4; aiPriority: 1; hostile: 0; hostileTail: 0),
    { 7 Ressurection }
    (castClass: 0; level: 7; range: 0; rangePerLevel: 0; duration: 0; durationPerLevel: 0; targeting: 0; campTarget: 2;
     saveEffect: 0; saveType: 4; effectId: 0; combatOk: 0; castingTime: 10; aiPriority: 0; hostile: 0; hostileTail: 0),
    { 8 Resist Cold }
    (castClass: 0; level: 1; range: 0; rangePerLevel: 0; duration: 0; durationPerLevel: 10; targeting: 4; campTarget: 2;
     saveEffect: 0; saveType: 4; effectId: 10; combatOk: 2; castingTime: 10; aiPriority: 0; hostile: 0; hostileTail: 0),
    { 9 Burning Hands }
    (castClass: 3; level: 1; range: 0; rangePerLevel: 0; duration: 0; durationPerLevel: 0; targeting: 4; campTarget: 0;
     saveEffect: 0; saveType: 4; effectId: 0; combatOk: 1; castingTime: 1; aiPriority: 1; hostile: 1; hostileTail: 0),
    { 10 Charm Person }
    (castClass: 3; level: 1; range: 12; rangePerLevel: 0; duration: 60; durationPerLevel: 60; targeting: 4;
     campTarget: 0;
     saveEffect: 1; saveType: 4; effectId: 11; combatOk: 1; castingTime: 1; aiPriority: 4; hostile: 1; hostileTail: 0),
    { 11 Detect Magic }
    (castClass: 3; level: 1; range: 0; rangePerLevel: 0; duration: 0; durationPerLevel: 2; targeting: 0; campTarget: 1;
     saveEffect: 0; saveType: 4; effectId: 5; combatOk: 2; castingTime: 1; aiPriority: 0; hostile: 0; hostileTail: 0),
    { 12 Enlarge }
    (castClass: 3; level: 1; range: 0; rangePerLevel: 2; duration: 0; durationPerLevel: 10; targeting: 4; campTarget: 2;
     saveEffect: 0; saveType: 4; effectId: 12; combatOk: 2; castingTime: 1; aiPriority: 0; hostile: 0; hostileTail: 0),
    { 13 Reduce }
    (castClass: 3; level: 1; range: 0; rangePerLevel: 2; duration: 0; durationPerLevel: 10; targeting: 4; campTarget: 2;
     saveEffect: 1; saveType: 4; effectId: 13; combatOk: 2; castingTime: 1; aiPriority: 0; hostile: 1; hostileTail: 0),
    { 14 Friends }
    (castClass: 3; level: 1; range: 0; rangePerLevel: 0; duration: 0; durationPerLevel: 1; targeting: 0; campTarget: 1;
     saveEffect: 0; saveType: 4; effectId: 14; combatOk: 0; castingTime: 1; aiPriority: 0; hostile: 0; hostileTail: 0),
    { 15 Magic Missile }
    (castClass: 3; level: 1; range: 6; rangePerLevel: 4; duration: 0; durationPerLevel: 0; targeting: 4; campTarget: 0;
     saveEffect: 0; saveType: 4; effectId: 0; combatOk: 1; castingTime: 1; aiPriority: 6; hostile: 1; hostileTail: 0),
    { 16 Protection From Evil }
    (castClass: 3; level: 1; range: 0; rangePerLevel: 0; duration: 0; durationPerLevel: 2; targeting: 4; campTarget: 2;
     saveEffect: 0; saveType: 4; effectId: 8; combatOk: 2; castingTime: 1; aiPriority: 1; hostile: 0; hostileTail: 0),
    { 17 Restoration }
    (castClass: 0; level: 7; range: 0; rangePerLevel: 0; duration: 0; durationPerLevel: 0; targeting: 0; campTarget: 2;
     saveEffect: 1; saveType: 4; effectId: 0; combatOk: 0; castingTime: 1; aiPriority: 0; hostile: 0; hostileTail: 0),
    { 18 Read Magic }
    (castClass: 3; level: 1; range: 0; rangePerLevel: 0; duration: 0; durationPerLevel: 2; targeting: 0; campTarget: 1;
     saveEffect: 0; saveType: 4; effectId: 16; combatOk: 0; castingTime: 10; aiPriority: 0; hostile: 0; hostileTail: 0),
    { 19 Shield }
    (castClass: 3; level: 1; range: 0; rangePerLevel: 0; duration: 0; durationPerLevel: 5; targeting: 0; campTarget: 1;
     saveEffect: 0; saveType: 4; effectId: 17; combatOk: 2; castingTime: 1; aiPriority: 1; hostile: 0; hostileTail: 0),
    { 20 Shocking Grasp }
    (castClass: 3; level: 1; range: 255; rangePerLevel: 0; duration: 0; durationPerLevel: 0; targeting: 4;
     campTarget: 0;
     saveEffect: 0; saveType: 4; effectId: 0; combatOk: 1; castingTime: 1; aiPriority: 1; hostile: 1; hostileTail: 0),
    { 21 Sleep }
    (castClass: 3; level: 1; range: 3; rangePerLevel: 4; duration: 0; durationPerLevel: 5; targeting: 9; campTarget: 0;
     saveEffect: 0; saveType: 4; effectId: 53; combatOk: 1; castingTime: 1; aiPriority: 3; hostile: 1; hostileTail: 1),
    { 22 Find Traps }
    (castClass: 0; level: 2; range: 0; rangePerLevel: 0; duration: 30; durationPerLevel: 0; targeting: 0; campTarget: 1;
     saveEffect: 0; saveType: 4; effectId: 19; combatOk: 0; castingTime: 5; aiPriority: 0; hostile: 0; hostileTail: 0),
    { 23 Hold Person }
    (castClass: 0; level: 2; range: 6; rangePerLevel: 0; duration: 4; durationPerLevel: 1; targeting: 6; campTarget: 0;
     saveEffect: 1; saveType: 4; effectId: 52; combatOk: 1; castingTime: 5; aiPriority: 5; hostile: 1; hostileTail: 0),
    { 24 Resist Fire }
    (castClass: 0; level: 2; range: 0; rangePerLevel: 0; duration: 0; durationPerLevel: 10; targeting: 4; campTarget: 2;
     saveEffect: 0; saveType: 4; effectId: 20; combatOk: 2; castingTime: 5; aiPriority: 0; hostile: 0; hostileTail: 0),
    { 25 Silence, 15' Radius }
    (castClass: 0; level: 2; range: 12; rangePerLevel: 0; duration: 0; durationPerLevel: 2; targeting: 31;
     campTarget: 0;
     saveEffect: 1; saveType: 4; effectId: 21; combatOk: 1; castingTime: 5; aiPriority: 1; hostile: 1; hostileTail: 1),
    { 26 Slow Poison }
    (castClass: 0; level: 2; range: 0; rangePerLevel: 0; duration: 0; durationPerLevel: 60; targeting: 4; campTarget: 2;
     saveEffect: 0; saveType: 4; effectId: 22; combatOk: 0; castingTime: 1; aiPriority: 0; hostile: 0; hostileTail: 0),
    { 27 Snake Charm }
    (castClass: 0; level: 2; range: 3; rangePerLevel: 0; duration: 0; durationPerLevel: 0; targeting: $F0;
     campTarget: 0;
     saveEffect: 0; saveType: 4; effectId: 51; combatOk: 1; castingTime: 5; aiPriority: 0; hostile: 1; hostileTail: 0),
    { 28 Spiritual Hammer }
    (castClass: 0; level: 2; range: 3; rangePerLevel: 0; duration: 0; durationPerLevel: 1; targeting: 0; campTarget: 1;
     saveEffect: 0; saveType: 4; effectId: 23; combatOk: 2; castingTime: 5; aiPriority: 1; hostile: 0; hostileTail: 0),
    { 29 Detect Invisibility }
    (castClass: 3; level: 2; range: 0; rangePerLevel: 4; duration: 0; durationPerLevel: 5; targeting: 0; campTarget: 1;
     saveEffect: 0; saveType: 4; effectId: 24; combatOk: 2; castingTime: 2; aiPriority: 0; hostile: 0; hostileTail: 0),
    { 30 Invisibility }
    (castClass: 3; level: 2; range: 0; rangePerLevel: 0; duration: 0; durationPerLevel: 0; targeting: 4; campTarget: 2;
     saveEffect: 0; saveType: 4; effectId: 25; combatOk: 2; castingTime: 2; aiPriority: 3; hostile: 0; hostileTail: 0),
    { 31 Knock }
    (castClass: 3; level: 2; range: 0; rangePerLevel: 0; duration: 0; durationPerLevel: 0; targeting: 0; campTarget: 0;
     saveEffect: 0; saveType: 4; effectId: 0; combatOk: 0; castingTime: 1; aiPriority: 0; hostile: 0; hostileTail: 0),
    { 32 Mirror Image }
    (castClass: 3; level: 2; range: 0; rangePerLevel: 0; duration: 0; durationPerLevel: 2; targeting: 0; campTarget: 1;
     saveEffect: 0; saveType: 4; effectId: 28; combatOk: 2; castingTime: 2; aiPriority: 2; hostile: 0; hostileTail: 0),
    { 33 Ray of Enfeeblement }
    (castClass: 3; level: 2; range: 1; rangePerLevel: 1; duration: 0; durationPerLevel: 1; targeting: 4; campTarget: 0;
     saveEffect: 1; saveType: 4; effectId: 29; combatOk: 1; castingTime: 2; aiPriority: 1; hostile: 1; hostileTail: 0),
    { 34 Stinking Cloud }
    (castClass: 3; level: 2; range: 3; rangePerLevel: 0; duration: 0; durationPerLevel: 1; targeting: 9; campTarget: 0;
     saveEffect: 3; saveType: 0; effectId: 30; combatOk: 1; castingTime: 2; aiPriority: 4; hostile: 1; hostileTail: 1),
    { 35 Strength }
    (castClass: 3; level: 2; range: 0; rangePerLevel: 0; duration: 0; durationPerLevel: 60; targeting: 0; campTarget: 2;
     saveEffect: 0; saveType: 4; effectId: 38; combatOk: 0; castingTime: 10; aiPriority: 0; hostile: 0; hostileTail: 0),
    { 36 (no name) }
    (castClass: 4; level: 7; range: 1; rangePerLevel: 0; duration: 0; durationPerLevel: 0; targeting: 8; campTarget: 3;
     saveEffect: 1; saveType: 4; effectId: 0; combatOk: 2; castingTime: 0; aiPriority: 5; hostile: 1; hostileTail: 0),
    { 37 Cure Blindness }
    (castClass: 0; level: 3; range: 0; rangePerLevel: 0; duration: 0; durationPerLevel: 0; targeting: 4; campTarget: 2;
     saveEffect: 0; saveType: 4; effectId: 0; combatOk: 2; castingTime: 10; aiPriority: 1; hostile: 0; hostileTail: 0),
    { 38 Cause Blindness }
    (castClass: 0; level: 3; range: 255; rangePerLevel: 0; duration: 0; durationPerLevel: 0; targeting: 4;
     campTarget: 0;
     saveEffect: 1; saveType: 4; effectId: 33; combatOk: 1; castingTime: 10; aiPriority: 2; hostile: 1; hostileTail: 0),
    { 39 Cure Disease }
    (castClass: 0; level: 3; range: 0; rangePerLevel: 0; duration: 0; durationPerLevel: 0; targeting: 0; campTarget: 2;
     saveEffect: 0; saveType: 4; effectId: 0; combatOk: 0; castingTime: 100; aiPriority: 0; hostile: 0; hostileTail: 0),
    { 40 Harm }
    (castClass: 0; level: 6; range: 0; rangePerLevel: 0; duration: 0; durationPerLevel: 0; targeting: 4; campTarget: 0;
     saveEffect: 0; saveType: 4; effectId: 0; combatOk: 1; castingTime: 10; aiPriority: 6; hostile: 1; hostileTail: 0),
    { 41 Dispel Magic }
    (castClass: 0; level: 3; range: 6; rangePerLevel: 0; duration: 0; durationPerLevel: 0; targeting: 9; campTarget: 2;
     saveEffect: 0; saveType: 4; effectId: 0; combatOk: 2; castingTime: 4; aiPriority: 0; hostile: 1; hostileTail: 1),
    { 42 Prayer }
    (castClass: 0; level: 3; range: 0; rangePerLevel: 0; duration: 0; durationPerLevel: 1; targeting: 0; campTarget: 3;
     saveEffect: 0; saveType: 4; effectId: 49; combatOk: 2; castingTime: 6; aiPriority: 3; hostile: 0; hostileTail: 0),
    { 43 Remove Curse }
    (castClass: 0; level: 3; range: 0; rangePerLevel: 0; duration: 0; durationPerLevel: 0; targeting: 4; campTarget: 2;
     saveEffect: 0; saveType: 4; effectId: 0; combatOk: 2; castingTime: 6; aiPriority: 0; hostile: 0; hostileTail: 0),
    { 44 Bestow Curse }
    (castClass: 0; level: 3; range: 255; rangePerLevel: 0; duration: 0; durationPerLevel: 10; targeting: 4;
     campTarget: 0;
     saveEffect: 1; saveType: 4; effectId: 36; combatOk: 1; castingTime: 6; aiPriority: 2; hostile: 1; hostileTail: 0),
    { 45 Blink }
    (castClass: 3; level: 3; range: 0; rangePerLevel: 0; duration: 0; durationPerLevel: 1; targeting: 0; campTarget: 1;
     saveEffect: 0; saveType: 4; effectId: 37; combatOk: 2; castingTime: 1; aiPriority: 3; hostile: 0; hostileTail: 0),
    { 46 Dispel Magic }
    (castClass: 3; level: 3; range: 12; rangePerLevel: 0; duration: 0; durationPerLevel: 1; targeting: 9; campTarget: 2;
     saveEffect: 0; saveType: 4; effectId: 0; combatOk: 2; castingTime: 3; aiPriority: 0; hostile: 1; hostileTail: 1),
    { 47 Fireball }
    (castClass: 3; level: 3; range: 10; rangePerLevel: 1; duration: 0; durationPerLevel: 0; targeting: 11;
     campTarget: 0;
     saveEffect: 2; saveType: 4; effectId: 0; combatOk: 1; castingTime: 3; aiPriority: 7; hostile: 1; hostileTail: 3),
    { 48 Haste }
    (castClass: 3; level: 3; range: 6; rangePerLevel: 0; duration: 3; durationPerLevel: 1; targeting: 10; campTarget: 3;
     saveEffect: 0; saveType: 4; effectId: 39; combatOk: 2; castingTime: 3; aiPriority: 5; hostile: 0; hostileTail: 0),
    { 49 Hold Person }
    (castClass: 3; level: 3; range: 12; rangePerLevel: 0; duration: 0; durationPerLevel: 2; targeting: 7; campTarget: 0;
     saveEffect: 1; saveType: 4; effectId: 52; combatOk: 1; castingTime: 3; aiPriority: 5; hostile: 1; hostileTail: 0),
    { 50 Invisibility, 10' Radius }
    (castClass: 3; level: 3; range: 0; rangePerLevel: 0; duration: 0; durationPerLevel: 0; targeting: 9; campTarget: 3;
     saveEffect: 0; saveType: 4; effectId: 25; combatOk: 2; castingTime: 3; aiPriority: 1; hostile: 0; hostileTail: 0),
    { 51 Lightning Bolt }
    (castClass: 3; level: 3; range: 4; rangePerLevel: 1; duration: 0; durationPerLevel: 0; targeting: 8; campTarget: 0;
     saveEffect: 2; saveType: 4; effectId: 0; combatOk: 1; castingTime: 3; aiPriority: 5; hostile: 1; hostileTail: 0),
    { 52 Protection From Evil, 10' Radius }
    (castClass: 3; level: 3; range: 0; rangePerLevel: 0; duration: 0; durationPerLevel: 2; targeting: 4; campTarget: 2;
     saveEffect: 0; saveType: 4; effectId: 45; combatOk: 2; castingTime: 3; aiPriority: 1; hostile: 0; hostileTail: 0),
    { 53 Heal }
    (castClass: 0; level: 6; range: 0; rangePerLevel: 0; duration: 0; durationPerLevel: 0; targeting: 4; campTarget: 2;
     saveEffect: 0; saveType: 4; effectId: 0; combatOk: 2; castingTime: 10; aiPriority: 1; hostile: 0; hostileTail: 0),
    { 54 Protection From Normal Missiles }
    (castClass: 3; level: 3; range: 0; rangePerLevel: 0; duration: 0; durationPerLevel: 10; targeting: 4; campTarget: 2;
     saveEffect: 0; saveType: 4; effectId: 41; combatOk: 2; castingTime: 3; aiPriority: 1; hostile: 0; hostileTail: 0),
    { 55 Slow }
    (castClass: 3; level: 3; range: 9; rangePerLevel: 1; duration: 3; durationPerLevel: 1; targeting: 10; campTarget: 0;
     saveEffect: 0; saveType: 4; effectId: 42; combatOk: 1; castingTime: 3; aiPriority: 3; hostile: 1; hostileTail: 0),
    { 56 Death Spell }
    (castClass: 3; level: 6; range: 0; rangePerLevel: 4; duration: 0; durationPerLevel: 0; targeting: 4; campTarget: 0;
     saveEffect: 0; saveType: 4; effectId: 0; combatOk: 1; castingTime: 5; aiPriority: 3; hostile: 1; hostileTail: 0),
    { 57 (no name) }
    (castClass: 4; level: 6; range: 0; rangePerLevel: 0; duration: 0; durationPerLevel: 0; targeting: 0; campTarget: 1;
     saveEffect: 0; saveType: 4; effectId: 39; combatOk: 2; castingTime: 0; aiPriority: 2; hostile: 0; hostileTail: 0),
    { 58 Cure Serious Wounds }
    (castClass: 0; level: 4; range: 0; rangePerLevel: 0; duration: 0; durationPerLevel: 0; targeting: 4; campTarget: 2;
     saveEffect: 0; saveType: 4; effectId: 0; combatOk: 2; castingTime: 7; aiPriority: 1; hostile: 0; hostileTail: 0),
    { 59 (no name) }
    (castClass: 4; level: 6; range: 0; rangePerLevel: 0; duration: 0; durationPerLevel: 0; targeting: 0; campTarget: 1;
     saveEffect: 0; saveType: 4; effectId: 38; combatOk: 2; castingTime: 0; aiPriority: 1; hostile: 0; hostileTail: 0),
    { 60 Disentegrate }
    (castClass: 3; level: 6; range: 0; rangePerLevel: 2; duration: 0; durationPerLevel: 0; targeting: 4; campTarget: 0;
     saveEffect: 1; saveType: 4; effectId: 0; combatOk: 1; castingTime: 6; aiPriority: 6; hostile: 1; hostileTail: 0),
    { 61 (no name) }
    (castClass: 4; level: 6; range: 6; rangePerLevel: 0; duration: 0; durationPerLevel: 0; targeting: 4; campTarget: 0;
     saveEffect: 1; saveType: 0; effectId: 52; combatOk: 1; castingTime: 0; aiPriority: 5; hostile: 1; hostileTail: 0),
    { 62 (no name) }
    (castClass: 4; level: 6; range: 0; rangePerLevel: 0; duration: 0; durationPerLevel: 0; targeting: 0; campTarget: 1;
     saveEffect: 0; saveType: 4; effectId: 39; combatOk: 2; castingTime: 0; aiPriority: 1; hostile: 0; hostileTail: 0),
    { 63 Globe Of Invulnerability }
    (castClass: 3; level: 6; range: 0; rangePerLevel: 0; duration: 0; durationPerLevel: 1; targeting: 0; campTarget: 1;
     saveEffect: 0; saveType: 4; effectId: 59; combatOk: 2; castingTime: 1; aiPriority: 4; hostile: 0; hostileTail: 0),
    { 64 (no name) }
    (castClass: 4; level: 6; range: 7; rangePerLevel: 0; duration: 0; durationPerLevel: 0; targeting: 11; campTarget: 0;
     saveEffect: 2; saveType: 4; effectId: 0; combatOk: 1; castingTime: 0; aiPriority: 6; hostile: 1; hostileTail: 3),
    { 65 (no name) }
    (castClass: 4; level: 6; range: 12; rangePerLevel: 0; duration: 0; durationPerLevel: 0; targeting: 4; campTarget: 0;
     saveEffect: 0; saveType: 4; effectId: 0; combatOk: 1; castingTime: 0; aiPriority: 5; hostile: 1; hostileTail: 0),
    { 66 Stone to Flesh }
    (castClass: 3; level: 6; range: 0; rangePerLevel: 4; duration: 0; durationPerLevel: 0; targeting: 4; campTarget: 2;
     saveEffect: 0; saveType: 4; effectId: 0; combatOk: 2; castingTime: 6; aiPriority: 1; hostile: 0; hostileTail: 0),
    { 67 Neutralize Poison }
    (castClass: 0; level: 4; range: 0; rangePerLevel: 0; duration: 0; durationPerLevel: 0; targeting: 0; campTarget: 2;
     saveEffect: 0; saveType: 4; effectId: 0; combatOk: 0; castingTime: 7; aiPriority: 0; hostile: 0; hostileTail: 0),
    { 68 Poison }
    (castClass: 0; level: 4; range: 0; rangePerLevel: 0; duration: 0; durationPerLevel: 0; targeting: 4; campTarget: 0;
     saveEffect: 1; saveType: 0; effectId: 0; combatOk: 1; castingTime: 7; aiPriority: 5; hostile: 1; hostileTail: 0),
    { 69 Protection Evil, 10' Radius }
    (castClass: 0; level: 4; range: 3; rangePerLevel: 0; duration: 0; durationPerLevel: 10; targeting: 4; campTarget: 2;
     saveEffect: 0; saveType: 4; effectId: 45; combatOk: 2; castingTime: 7; aiPriority: 1; hostile: 0; hostileTail: 0),
    { 70 Sticks to Snakes }
    (castClass: 0; level: 4; range: 3; rangePerLevel: 0; duration: 0; durationPerLevel: 2; targeting: 4; campTarget: 0;
     saveEffect: 0; saveType: 4; effectId: 3; combatOk: 1; castingTime: 7; aiPriority: 2; hostile: 1; hostileTail: 0),
    { 71 Cure Critical Wounds }
    (castClass: 0; level: 5; range: 0; rangePerLevel: 0; duration: 0; durationPerLevel: 0; targeting: 4; campTarget: 2;
     saveEffect: 0; saveType: 4; effectId: 0; combatOk: 2; castingTime: 8; aiPriority: 1; hostile: 0; hostileTail: 0),
    { 72 Flesh to Stone }
    (castClass: 3; level: 6; range: 0; rangePerLevel: 4; duration: 0; durationPerLevel: 0; targeting: 4; campTarget: 0;
     saveEffect: 1; saveType: 4; effectId: 0; combatOk: 1; castingTime: 6; aiPriority: 5; hostile: 1; hostileTail: 0),
    { 73 Dispel Evil }
    (castClass: 0; level: 5; range: 0; rangePerLevel: 0; duration: 0; durationPerLevel: 1; targeting: 0; campTarget: 0;
     saveEffect: 0; saveType: 4; effectId: 34; combatOk: 1; castingTime: 8; aiPriority: 0; hostile: 0; hostileTail: 0),
    { 74 Flame Strike }
    (castClass: 0; level: 5; range: 6; rangePerLevel: 0; duration: 0; durationPerLevel: 0; targeting: 4; campTarget: 0;
     saveEffect: 2; saveType: 4; effectId: 0; combatOk: 1; castingTime: 8; aiPriority: 5; hostile: 1; hostileTail: 0),
    { 75 Raise Dead }
    (castClass: 0; level: 5; range: 0; rangePerLevel: 0; duration: 0; durationPerLevel: 0; targeting: 0; campTarget: 2;
     saveEffect: 0; saveType: 4; effectId: 0; combatOk: 0; castingTime: 10; aiPriority: 0; hostile: 0; hostileTail: 0),
    { 76 Slay Living }
    (castClass: 0; level: 5; range: 3; rangePerLevel: 0; duration: 0; durationPerLevel: 0; targeting: 4; campTarget: 0;
     saveEffect: 1; saveType: 4; effectId: 0; combatOk: 1; castingTime: 10; aiPriority: 6; hostile: 1; hostileTail: 0),
    { 77 Detect Magic }
    (castClass: 1; level: 1; range: 3; rangePerLevel: 0; duration: 12; durationPerLevel: 0; targeting: 0; campTarget: 1;
     saveEffect: 0; saveType: 4; effectId: 5; combatOk: 2; castingTime: 3; aiPriority: 0; hostile: 0; hostileTail: 0),
    { 78 Entangle }
    (castClass: 1; level: 1; range: 8; rangePerLevel: 0; duration: 10; durationPerLevel: 0; targeting: 11;
     campTarget: 0;
     saveEffect: 1; saveType: 4; effectId: 0; combatOk: 1; castingTime: 3; aiPriority: 2; hostile: 1; hostileTail: 0),
    { 79 Faerie Fire }
    (castClass: 1; level: 1; range: 8; rangePerLevel: 0; duration: 0; durationPerLevel: 4; targeting: 5; campTarget: 0;
     saveEffect: 1; saveType: 4; effectId: 7; combatOk: 1; castingTime: 3; aiPriority: 1; hostile: 1; hostileTail: 0),
    { 80 Invisibility to Animals }
    (castClass: 1; level: 1; range: 255; rangePerLevel: 0; duration: 10; durationPerLevel: 1; targeting: 4;
     campTarget: 2;
     saveEffect: 0; saveType: 4; effectId: 69; combatOk: 2; castingTime: 4; aiPriority: 0; hostile: 1; hostileTail: 0),
    { 81 Charm Monsters }
    (castClass: 3; level: 4; range: 6; rangePerLevel: 0; duration: 0; durationPerLevel: 0; targeting: 5; campTarget: 0;
     saveEffect: 1; saveType: 4; effectId: 11; combatOk: 1; castingTime: 4; aiPriority: 6; hostile: 1; hostileTail: 0),
    { 82 Confusion }
    (castClass: 3; level: 4; range: 12; rangePerLevel: 0; duration: 2; durationPerLevel: 1; targeting: 11;
     campTarget: 0;
     saveEffect: 1; saveType: 4; effectId: 35; combatOk: 1; castingTime: 4; aiPriority: 5; hostile: 1; hostileTail: 0),
    { 83 Dimension Door }
    (castClass: 3; level: 4; range: 0; rangePerLevel: 3; duration: 0; durationPerLevel: 0; targeting: 8; campTarget: 0;
     saveEffect: 0; saveType: 4; effectId: 0; combatOk: 1; castingTime: 1; aiPriority: 0; hostile: 1; hostileTail: 0),
    { 84 Fear }
    (castClass: 3; level: 4; range: 6; rangePerLevel: 0; duration: 0; durationPerLevel: 1; targeting: 8; campTarget: 0;
     saveEffect: 1; saveType: 4; effectId: 111; combatOk: 1; castingTime: 4; aiPriority: 5; hostile: 1; hostileTail: 0),
    { 85 Fire Shield }
    (castClass: 3; level: 4; range: 0; rangePerLevel: 0; duration: 2; durationPerLevel: 1; targeting: 0; campTarget: 1;
     saveEffect: 0; saveType: 4; effectId: 0; combatOk: 2; castingTime: 4; aiPriority: 4; hostile: 0; hostileTail: 0),
    { 86 Fumble }
    (castClass: 3; level: 4; range: 0; rangePerLevel: 1; duration: 0; durationPerLevel: 1; targeting: 4; campTarget: 0;
     saveEffect: 1; saveType: 4; effectId: 27; combatOk: 1; castingTime: 4; aiPriority: 2; hostile: 1; hostileTail: 0),
    { 87 Ice Storm }
    (castClass: 3; level: 4; range: 0; rangePerLevel: 1; duration: 0; durationPerLevel: 0; targeting: 10; campTarget: 0;
     saveEffect: 0; saveType: 4; effectId: 0; combatOk: 1; castingTime: 4; aiPriority: 5; hostile: 1; hostileTail: 0),
    { 88 Minor Globe Of Invulnerability }
    (castClass: 3; level: 4; range: 0; rangePerLevel: 1; duration: 0; durationPerLevel: 1; targeting: 0; campTarget: 1;
     saveEffect: 0; saveType: 4; effectId: 63; combatOk: 2; castingTime: 4; aiPriority: 5; hostile: 0; hostileTail: 0),
    { 89 Remove Curse }
    (castClass: 3; level: 4; range: 0; rangePerLevel: 0; duration: 0; durationPerLevel: 0; targeting: 4; campTarget: 2;
     saveEffect: 0; saveType: 4; effectId: 0; combatOk: 2; castingTime: 4; aiPriority: 0; hostile: 0; hostileTail: 0),
    { 90 Iron Skin }
    (castClass: 3; level: 5; range: 0; rangePerLevel: 0; duration: 0; durationPerLevel: 1; targeting: 0; campTarget: 1;
     saveEffect: 0; saveType: 4; effectId: 60; combatOk: 2; castingTime: 5; aiPriority: 3; hostile: 0; hostileTail: 0),
    { 91 Cloud Kill }
    (castClass: 3; level: 5; range: 2; rangePerLevel: 0; duration: 0; durationPerLevel: 1; targeting: 9; campTarget: 0;
     saveEffect: 0; saveType: 4; effectId: 0; combatOk: 2; castingTime: 5; aiPriority: 1; hostile: 1; hostileTail: 0),
    { 92 Cone of Cold }
    (castClass: 3; level: 5; range: 6; rangePerLevel: 0; duration: 0; durationPerLevel: 0; targeting: 8; campTarget: 0;
     saveEffect: 2; saveType: 4; effectId: 0; combatOk: 1; castingTime: 5; aiPriority: 4; hostile: 1; hostileTail: 0),
    { 93 Feeblemind }
    (castClass: 3; level: 5; range: 16; rangePerLevel: 0; duration: 0; durationPerLevel: 0; targeting: 4; campTarget: 0;
     saveEffect: 1; saveType: 4; effectId: 68; combatOk: 1; castingTime: 5; aiPriority: 2; hostile: 1; hostileTail: 0),
    { 94 Hold Monsters }
    (castClass: 3; level: 5; range: 0; rangePerLevel: 1; duration: 0; durationPerLevel: 1; targeting: 7; campTarget: 0;
     saveEffect: 1; saveType: 4; effectId: 52; combatOk: 1; castingTime: 5; aiPriority: 6; hostile: 1; hostileTail: 0),
    { 95 (no name) }
    (castClass: 4; level: 6; range: 0; rangePerLevel: 0; duration: 0; durationPerLevel: 1; targeting: 0; campTarget: 1;
     saveEffect: 0; saveType: 4; effectId: 73; combatOk: 2; castingTime: 10; aiPriority: 0; hostile: 0; hostileTail: 0),
    { 96 (no name) }
    (castClass: 4; level: 6; range: 0; rangePerLevel: 0; duration: 0; durationPerLevel: 10; targeting: 0; campTarget: 1;
     saveEffect: 0; saveType: 4; effectId: 97; combatOk: 2; castingTime: 10; aiPriority: 0; hostile: 0; hostileTail: 0),
    { 97 (no name) }
    (castClass: 4; level: 6; range: 0; rangePerLevel: 0; duration: 6; durationPerLevel: 0; targeting: 0; campTarget: 1;
     saveEffect: 0; saveType: 4; effectId: 25; combatOk: 2; castingTime: 0; aiPriority: 0; hostile: 0; hostileTail: 0),
    { 98 Fire Touch }
    (castClass: 3; level: 5; range: 0; rangePerLevel: 0; duration: 0; durationPerLevel: 1; targeting: 4; campTarget: 2;
     saveEffect: 0; saveType: 4; effectId: 74; combatOk: 2; castingTime: 6; aiPriority: 4; hostile: 0; hostileTail: 0),
    { 99 (no name) }
    (castClass: 4; level: 6; range: 0; rangePerLevel: 0; duration: 0; durationPerLevel: 0; targeting: 0; campTarget: 1;
     saveEffect: 0; saveType: 4; effectId: 0; combatOk: 2; castingTime: 0; aiPriority: 0; hostile: 0; hostileTail: 0),
    { 100 Bestow Curse }
    (castClass: 3; level: 4; range: 0; rangePerLevel: 0; duration: 0; durationPerLevel: 10; targeting: 4; campTarget: 0;
     saveEffect: 1; saveType: 4; effectId: 0; combatOk: 1; castingTime: 4; aiPriority: 3; hostile: 1; hostileTail: 0),
    { 101 Protection From Evil 10' Radius }
    (castClass: 2; level: 0; range: 0; rangePerLevel: 0; duration: 0; durationPerLevel: 2; targeting: 4; campTarget: 2;
     saveEffect: 0; saveType: 4; effectId: 45; combatOk: 2; castingTime: 3; aiPriority: 1; hostile: 0; hostileTail: 0),
    { 102 Silence 15' radius }
    (castClass: 2; level: 0; range: 12; rangePerLevel: 0; duration: 0; durationPerLevel: 2; targeting: 31;
     campTarget: 0;
     saveEffect: 1; saveType: 4; effectId: 21; combatOk: 1; castingTime: 5; aiPriority: 1; hostile: 1; hostileTail: 1),
    { 103 Detect Magic }
    (castClass: 2; level: 0; range: 0; rangePerLevel: 0; duration: 10; durationPerLevel: 0; targeting: 0; campTarget: 1;
     saveEffect: 0; saveType: 4; effectId: 5; combatOk: 2; castingTime: 0; aiPriority: 0; hostile: 0; hostileTail: 0),
    { 104 Remove Curse }
    (castClass: 2; level: 0; range: 0; rangePerLevel: 0; duration: 0; durationPerLevel: 0; targeting: 4; campTarget: 2;
     saveEffect: 0; saveType: 4; effectId: 2; combatOk: 2; castingTime: 6; aiPriority: 0; hostile: 0; hostileTail: 0),
    { 105 Bless }
    (castClass: 2; level: 0; range: 6; rangePerLevel: 0; duration: 6; durationPerLevel: 0; targeting: 10; campTarget: 3;
     saveEffect: 0; saveType: 4; effectId: 1; combatOk: 2; castingTime: 10; aiPriority: 1; hostile: 0; hostileTail: 0),
    { 106 Charm Person }
    (castClass: 2; level: 0; range: 12; rangePerLevel: 0; duration: 0; durationPerLevel: 0; targeting: 4; campTarget: 0;
     saveEffect: 1; saveType: 4; effectId: 11; combatOk: 1; castingTime: 1; aiPriority: 5; hostile: 1; hostileTail: 0),
    { 107 Burning Hands }
    (castClass: 2; level: 0; range: 0; rangePerLevel: 0; duration: 0; durationPerLevel: 0; targeting: 4; campTarget: 0;
     saveEffect: 0; saveType: 4; effectId: 0; combatOk: 1; castingTime: 1; aiPriority: 1; hostile: 1; hostileTail: 0),
    { 108 Delay Blast Fireball }
    (castClass: 3; level: 7; range: 10; rangePerLevel: 4; duration: 0; durationPerLevel: 0; targeting: 11;
     campTarget: 0;
     saveEffect: 2; saveType: 4; effectId: 0; combatOk: 1; castingTime: 1; aiPriority: 9; hostile: 1; hostileTail: 0),
    { 109 Mass Invisibility }
    (castClass: 3; level: 7; range: 0; rangePerLevel: 4; duration: 0; durationPerLevel: 0; targeting: 10; campTarget: 3;
     saveEffect: 0; saveType: 4; effectId: 25; combatOk: 2; castingTime: 7; aiPriority: 3; hostile: 0; hostileTail: 0),
    { 110 Power Word Stun }
    (castClass: 3; level: 7; range: 0; rangePerLevel: 2; duration: 0; durationPerLevel: 0; targeting: 4; campTarget: 0;
     saveEffect: 0; saveType: 4; effectId: 6; combatOk: 1; castingTime: 1; aiPriority: 5; hostile: 1; hostileTail: 0),
    { 111 Mass Charm }
    (castClass: 3; level: 8; range: 0; rangePerLevel: 1; duration: 0; durationPerLevel: 0; targeting: 10; campTarget: 0;
     saveEffect: 1; saveType: 4; effectId: 10; combatOk: 1; castingTime: 8; aiPriority: 6; hostile: 1; hostileTail: 0),
    { 112 Mind Blank }
    (castClass: 3; level: 8; range: 3; rangePerLevel: 0; duration: 0; durationPerLevel: 0; targeting: 4; campTarget: 2;
     saveEffect: 0; saveType: 4; effectId: 58; combatOk: 2; castingTime: 1; aiPriority: 0; hostile: 0; hostileTail: 0),
    { 113 Otto's Irresitable Dance }
    (castClass: 3; level: 8; range: 255; rangePerLevel: 0; duration: 0; durationPerLevel: 0; targeting: 4;
     campTarget: 0;
     saveEffect: 0; saveType: 4; effectId: 57; combatOk: 1; castingTime: 5; aiPriority: 5; hostile: 1; hostileTail: 0),
    { 114 Power Word Blind }
    (castClass: 3; level: 8; range: 0; rangePerLevel: 1; duration: 0; durationPerLevel: 0; targeting: 10; campTarget: 0;
     saveEffect: 0; saveType: 4; effectId: 0; combatOk: 1; castingTime: 1; aiPriority: 3; hostile: 1; hostileTail: 0));
  { how many of unit i make one of unit i+1 }
  clockUnitScale: Types.TClock = (
    { round, minute, turn, hour, day, month, year }
    10, 10, 6, 24, 30, 12, 256);
  { the bit a zone square's search flags carry once the party has searched it; the second byte is never read }
  searchMask: array[0..1] of Byte = (
    $01, $00);
  { the extension of a character's memorized spells }
  spellsExtension: String[4] = '.wiz';
  { of its items }
  itemsExtension: String[4] = '.jnk';
  { of its running effects }
  effectsExtension: String[4] = '.eff';
  { of an imported character's items }
  championsItemsExtension: String[4] = '.stf';
  { of an imported character's effects }
  championsEffectsExtension: String[4] = '.sfx';
  { the name every save file is built on }
  saveGameStem: String[6] = 'savgam';
  { never shown }
  putSaveDiskPrefix: String[17] = 'Put save disk in ';
  { by class, then level 0..18 }
  thac0Table: array[0..7, 0..18] of Byte = (
    (40, 40, 40, 40, 42, 42, 42, 44, 44, 44, 46, 46, 46, 48, 48, 48, 50, 50, 50),
    (40, 40, 40, 40, 42, 42, 42, 44, 44, 44, 46, 46, 46, 48, 48, 48, 50, 50, 50),
    (39, 40, 40, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 56),
    (40, 40, 40, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 56),
    (40, 40, 40, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 56),
    (39, 39, 39, 39, 39, 39, 41, 41, 41, 41, 41, 43, 43, 43, 43, 43, 44, 44, 44),
    (40, 40, 40, 40, 40, 41, 41, 41, 41, 44, 44, 44, 44, 45, 45, 45, 45, 46, 46),
    (40, 40, 40, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 56));
  { by class: its bit in TCharacter.classMask }
  classMaskBits: array[0..7] of Byte = (
    $02, $20, $08, $40, $80, $01, $04, $10);
  { ends FixMain's main loop and CharGen's party menu }
  gameDone: Byte = 0;
  { by class: its bit in TZone1.trainMask }
  trainingClassBits: array[0..7] of Byte = (
    $02, $02, $08, $10, $20, $01, $04, $10);
  { never read }
  unreadClassBits: array[0..8] of Byte = (
    $10, $10, $10, $20, $20, $20, $40, $40, $40);
  { by class: the first level whose hit points are a fixed gain, not a die roll }
  firstFixedHpLevel: array[0..7] of Byte = (
    10, 15, 10, 10, 11, 12, 11, 10);
  { the last icon head CharGen steps to }
  maximumIconHead: Byte = 13;
  { the last icon body }
  maximumIconBody: Byte = 31;
  { palette entry each icon color repaints; +8 its bright pair }
  iconColorSlots: array[1..6] of Byte = (
    1, 2, 3, 4, 6, 7);
  { by thief level, then skill }
  thiefSkillBase: array[1..18, 1..8] of Byte = (
    (30, 25, 20, 15, 10, 10, 85, 0), (35, 29, 25, 21, 15, 10, 86, 0),
    (40, 33, 30, 27, 20, 15, 87, 0),
    (45, 37, 35, 33, 25, 15, 88, 20), (50, 42, 40, 40, 31, 20, 90, 25),
    (55, 47, 45, 47, 37, 20, 92, 30),
    (60, 52, 50, 55, 43, 25, 94, 35), (65, 57, 55, 62, 49, 25, 96, 40),
    (70, 62, 60, 70, 56, 30, 98, 45),
    (80, 67, 65, 78, 63, 30, 99, 50), (90, 72, 70, 86, 70, 35, 99, 60),
    (100, 77, 75, 94, 77, 35, 99, 65),
    (105, 82, 80, 99, 85, 40, 99, 70), (110, 87, 85, 99, 93, 40, 99, 75),
    (115, 92, 90, 99, 99, 50, 99, 80),
    (125, 97, 95, 99, 99, 50, 99, 80), (125, 99, 99, 99, 99, 55, 99, 80),
    (125, 99, 99, 99, 99, 55, 99, 80));
  { by race, then skill }
  thiefSkillRaceAdjust: array[0..6, 1..8] of ShortInt = (
    (0, 10, 15, 0, 0, 0, -10, -5), (5, -5, 0, 5, 10, 5, 0, 0), (0, 5, 10, 5, 5, 10, -15, 0),
    (10, 0, 0, 0, 5, 0, 0, 0), (5, 5, 5, 10, 15, 5, -15, -5),
    (-5, 5, 5, 0, 0, 5, 5, -10), (0, 0, 0, 0, 0, 0, 0, 0));
  { by dexterity, then skill }
  thiefSkillDexterityAdjust: array[9..19, 1..5] of ShortInt = (
    (-15, -10, -10, -20, -10), (-19, -5, -10, -15, -5), (-5, 0, -5, -10, 0), (0, 0, 0, -5, 0), (0, 0, 0, 0, 0),
    (0, 0, 0, 0, 0), (0, 0, 0, 0, 0),
    (0, -5, 0, 0, 0), (5, 10, 0, 5, 5), (10, 15, 5, 10, 10), (15, 20, 10, 12, 12));
  { by race; strength by gender, male 0 }
  raceStatLimits: array[0..6] of Types.TRaceStatLimits = (
    (strengthMinimum: (3, 3); strengthMaximum: (18, 16); exceptionalMaximum: (75, 0);
     range: ((minimum: 10; maximum: 18), (minimum: 6; maximum: 18), (minimum: 7; maximum: 19),
            (minimum: 6; maximum: 18), (minimum: 12; maximum: 18))),
    (strengthMinimum: (7, 7); strengthMaximum: (18, 16); exceptionalMaximum: (75, 0);
     range: ((minimum: 8; maximum: 18), (minimum: 6; maximum: 18), (minimum: 7; maximum: 19),
            (minimum: 7; maximum: 18), (minimum: 8; maximum: 18))),
    (strengthMinimum: (3, 3); strengthMaximum: (18, 17); exceptionalMaximum: (90, 0);
     range: ((minimum: 4; maximum: 18), (minimum: 3; maximum: 18), (minimum: 6; maximum: 18),
            (minimum: 6; maximum: 18), (minimum: 3; maximum: 18))),
    (strengthMinimum: (8, 8); strengthMaximum: (18, 17); exceptionalMaximum: (99, 0);
     range: ((minimum: 3; maximum: 18), (minimum: 3; maximum: 18), (minimum: 3; maximum: 17),
            (minimum: 12; maximum: 19), (minimum: 3; maximum: 16))),
    (strengthMinimum: (9, 9); strengthMaximum: (18, 17); exceptionalMaximum: (99, 0);
     range: ((minimum: 3; maximum: 18), (minimum: 3; maximum: 18), (minimum: 3; maximum: 17),
            (minimum: 14; maximum: 19), (minimum: 3; maximum: 12))),
    (strengthMinimum: (6, 6); strengthMaximum: (16, 16); exceptionalMaximum: (0, 0);
     range: ((minimum: 6; maximum: 18), (minimum: 3; maximum: 16), (minimum: 8; maximum: 19),
            (minimum: 10; maximum: 18), (minimum: 6; maximum: 18))),
    (strengthMinimum: (3, 3); strengthMaximum: (18, 18); exceptionalMaximum: (100, 50);
     range: ((minimum: 3; maximum: 18), (minimum: 3; maximum: 18), (minimum: 3; maximum: 18),
            (minimum: 3; maximum: 18), (minimum: 3; maximum: 18))));
  { by race: how many classes it may take, then their ids }
  raceClasses: array[0..6] of Types.TRaceClasses = (
    (count: 10; classId: (0, 2, 5, 4, 3, 8, 9, 10, 11, 13, 0, 0, 0, 0)),
    (count: 13; classId: (0, 2, 5, 6, 4, 8, 10, 9, 11, 13, 14, 15, 16, 0)),
    (count: 14; classId: (0, 2, 5, 6, 4, 7, 8, 10, 9, 11, 13, 14, 15, 16)),
    (count: 7; classId: (0, 2, 6, 3, 8, 12, 14, 0, 0, 0, 0, 0, 0, 0)),
    (count: 8; classId: (0, 2, 6, 4, 8, 10, 12, 14, 0, 0, 0, 0, 0, 0)),
    (count: 8; classId: (0, 2, 6, 4, 8, 10, 12, 14, 0, 0, 0, 0, 0, 0)),
    (count: 7; classId: (0, 2, 5, 6, 4, 7, 3, 0, 0, 0, 0, 0, 0, 0)));
  { by race, then class: base + dice d sides }
  startingAges: array[0..6, 0..7] of Types.TAgeRoll = (
    ((base: 250; dice: 10; sides: 10), (base: 0; dice: 0; sides: 0), (base: 150; dice: 5; sides: 6),
    (base: 150; dice: 5; sides: 6),
     (base: 150; dice: 5; sides: 6), (base: 250; dice: 10; sides: 10), (base: 150; dice: 5; sides: 4),
     (base: 130; dice: 5; sides: 6)),
    ((base: 250; dice: 10; sides: 10), (base: 0; dice: 0; sides: 0), (base: 150; dice: 5; sides: 6),
    (base: 150; dice: 5; sides: 6),
     (base: 150; dice: 5; sides: 6), (base: 250; dice: 10; sides: 10), (base: 150; dice: 5; sides: 4),
     (base: 130; dice: 5; sides: 6)),
    ((base: 40; dice: 3; sides: 6), (base: 0; dice: 0; sides: 0), (base: 22; dice: 3; sides: 4),
    (base: 22; dice: 3; sides: 4),
     (base: 22; dice: 3; sides: 4), (base: 40; dice: 3; sides: 6), (base: 22; dice: 3; sides: 8),
     (base: 22; dice: 3; sides: 4)),
    ((base: 60; dice: 3; sides: 10), (base: 0; dice: 0; sides: 0), (base: 60; dice: 3; sides: 6),
    (base: 60; dice: 3; sides: 6),
     (base: 60; dice: 3; sides: 6), (base: 60; dice: 3; sides: 10), (base: 22; dice: 3; sides: 4),
     (base: 22; dice: 3; sides: 6)),
    ((base: 60; dice: 3; sides: 10), (base: 0; dice: 0; sides: 0), (base: 60; dice: 3; sides: 6),
    (base: 60; dice: 3; sides: 6),
     (base: 60; dice: 3; sides: 6), (base: 60; dice: 3; sides: 10), (base: 22; dice: 3; sides: 4),
     (base: 22; dice: 3; sides: 6)),
    ((base: 33; dice: 3; sides: 6), (base: 0; dice: 0; sides: 0), (base: 22; dice: 3; sides: 4),
    (base: 22; dice: 3; sides: 4),
     (base: 22; dice: 3; sides: 6), (base: 33; dice: 3; sides: 6), (base: 20; dice: 2; sides: 4),
     (base: 22; dice: 1; sides: 4)),
    ((base: 18; dice: 1; sides: 4), (base: 18; dice: 1; sides: 4), (base: 15; dice: 1; sides: 4),
    (base: 17; dice: 1; sides: 4),
     (base: 20; dice: 1; sides: 4), (base: 24; dice: 2; sides: 4), (base: 18; dice: 1; sides: 4),
     (base: 20; dice: 1; sides: 4)));
  { by race: the ages the stat adjustments start at }
  ageThresholds: array[0..6, 0..4] of Word = (
    (250, 650, 1000, 1500, 2000),
    (250, 650, 1000, 1500, 2000),
    (40, 100, 175, 250, 325),
    (60, 175, 275, 400, 525),
    (50, 150, 250, 350, 450),
    (33, 68, 101, 144, 199),
    (20, 40, 60, 90, 120));
  { by class id: str int wis dex con cha }
  classStatMinimums: array[0..16, 0..5] of Byte = (
    (6, 6, 9, 0, 6, 6), (6, 6, 12, 0, 6, 15), (9, 0, 6, 6, 7, 6), (12, 9, 13, 6, 9, 17), (13, 13, 14, 6, 14, 6),
    (3, 9, 6, 6, 6, 6), (6, 6, 0, 9, 6, 6),
    (10, 7, 10, 8, 10, 6), (9, 6, 9, 6, 7, 6), (9, 9, 9, 6, 7, 6), (13, 13, 14, 6, 14, 6), (6, 9, 9, 6, 6, 6),
    (6, 6, 9, 9, 6, 6), (9, 9, 6, 6, 6, 6),
    (9, 6, 6, 9, 6, 6), (9, 9, 6, 9, 6, 6), (6, 9, 6, 9, 6, 6));
  { by class id: a bit per alignmentChoices entry }
  classAlignments: array[0..16] of Byte = (
    $3F, $3F, $3F, $01, $15, $3F, $2E, $01, $3F, $3F, $15, $3F, $2E, $3F, $2E, $2E, $2E);
  { hit points per level, by constitution }
  constitutionHitPointTable: array[3..25] of ShortInt = (
    -2, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2);
  { by class: experience per level from 2, and the slots it adds }
  classProgression: array[0..10] of Types.TClassProgression =
      (
    (experience: (
    4000, 7500, 15250, 25000, 40000, 90000, 160000, 250000, 500000, 750000, 1000000, 1250000, 1500000, -1, -1, -1, -1);
     spellSlots: (
    (1, 0, 0, 0, 0, 0, 0, 0), (0, 1, 0, 0, 0, 0, 0, 0), (0, 1, 0, 0, 0, 0, 0, 0), (1, 1, 1, 0, 0, 0, 0, 0),
    (0, 0, 1, 0, 0, 0, 0, 0), (0, 0, 0, 1, 0, 0, 0, 0),
    (0, 0, 1, 1, 0, 0, 0, 0), (1, 1, 0, 0, 1, 0, 0, 0), (0, 0, 0, 1, 1, 0, 0, 0), (1, 0, 1, 0, 0, 1, 0, 0),
    (1, 1, 1, 0, 0, 1, 0, 0), (0, 1, 1, 1, 0, 0, 0, 0),
    (0, 0, 0, 1, 1, 0, 0, 0), (1, 1, 1, 0, 1, 0, 0, 0), (0, 0, 0, 1, 1, 1, 1, 0), (1, 1, 1, 0, 0, 0, 0, 0),
    (0, 0, 0, 1, 1, 1, 1, 0))),
    (experience: (
    3000, 6000, 13000, 27500, 55000, 110000, 225000, 450000, 675000, 900000, 1125000, 1350000, 1575000, -1, -1, -1, -1);
     spellSlots: (
    (0, 1, 0, 0, 0, 0, 0, 0), (1, 1, 1, 0, 0, 0, 0, 0), (1, 0, 1, 0, 0, 0, 0, 0), (0, 1, 0, 0, 0, 0, 0, 0),
    (0, 0, 0, 1, 0, 0, 0, 0), (0, 1, 1, 0, 0, 0, 0, 0),
    (0, 0, 0, 1, 0, 0, 0, 0), (1, 0, 0, 0, 1, 0, 0, 0), (0, 0, 0, 1, 1, 0, 0, 0), (0, 1, 0, 0, 0, 1, 0, 0),
    (0, 0, 1, 1, 1, 1, 1, 0), (1, 0, 1, 0, 0, 0, 0, 0),
    (0, 1, 1, 1, 1, 0, 0, 0), (0, 0, 0, 0, 0, 1, 0, 0), (0, 0, 0, 0, 1, 1, 0, 0), (1, 0, 0, 0, 0, 0, 1, 0),
    (0, 0, 0, 0, 0, 0, 1, 0))),
    (experience: (
    2001, 4001, 8001, 18001, 35001, 70001, 125001, 250001, 500001, 750001, 1000001, 1250001, 1500001, -1, -1, -1, -1);
     spellSlots: (
    (0, 0, 0, 0, 0, 0, 0, 0), (0, 0, 0, 0, 0, 0, 0, 0), (0, 0, 0, 0, 0, 0, 0, 0), (0, 0, 0, 0, 0, 0, 0, 0),
    (0, 0, 0, 0, 0, 0, 0, 0), (0, 0, 0, 0, 0, 0, 0, 0),
    (0, 0, 0, 0, 0, 0, 0, 0), (0, 0, 0, 0, 0, 0, 0, 0), (0, 0, 0, 0, 0, 0, 0, 0), (0, 0, 0, 0, 0, 0, 0, 0),
    (0, 0, 0, 0, 0, 0, 0, 0), (0, 0, 0, 0, 0, 0, 0, 0),
    (0, 0, 0, 0, 0, 0, 0, 0), (0, 0, 0, 0, 0, 0, 0, 0), (0, 0, 0, 0, 0, 0, 0, 0), (0, 0, 0, 0, 0, 0, 0, 0),
    (0, 0, 0, 0, 0, 0, 0, 0))),
    (experience: (
    5000, 10000, 18500, 37000, 85000, 140000, 220000, 300000, 600000, 900000, 1200000, 1500000, 1800000, -1, -1, -1,
    -1);
     spellSlots: (
    (0, 0, 0, 0, 0, 0, 0, 0), (0, 0, 0, 0, 0, 0, 0, 0), (0, 0, 0, 0, 0, 0, 0, 0), (0, 0, 0, 0, 0, 0, 0, 0),
    (0, 0, 0, 0, 0, 0, 0, 0), (0, 0, 0, 0, 0, 0, 0, 0),
    (0, 0, 0, 0, 0, 0, 0, 0), (0, 0, 0, 0, 0, 0, 0, 0), (0, 0, 0, 0, 0, 0, 0, 0), (0, 0, 0, 0, 0, 0, 0, 0),
    (0, 0, 0, 0, 0, 0, 0, 0), (0, 0, 0, 0, 0, 0, 0, 0),
    (0, 0, 0, 0, 0, 0, 0, 0), (0, 0, 0, 0, 0, 0, 0, 0), (0, 0, 0, 0, 0, 0, 0, 0), (0, 0, 0, 0, 0, 0, 0, 0),
    (0, 0, 0, 0, 0, 0, 0, 0))),
    (experience: (
    5000, 12000, 24000, 45000, 95000, 175000, 350000, 700000, 1050000, 1400000, 1750000, 2100000, 2450000, -1, -1, -1,
    -1);
     spellSlots: (
    (0, 0, 0, 0, 0, 0, 0, 0), (0, 0, 0, 0, 0, 0, 0, 0), (0, 0, 0, 0, 0, 0, 0, 0), (0, 0, 0, 0, 0, 0, 0, 0),
    (1, 0, 0, 0, 0, 0, 0, 0), (1, 0, 0, 0, 0, 0, 0, 0),
    (0, 1, 0, 0, 0, 0, 0, 0), (1, 1, 0, 0, 0, 0, 0, 0), (1, 0, 0, 0, 0, 0, 0, 0), (0, 0, 1, 0, 0, 0, 0, 0),
    (1, 1, 0, 1, 0, 0, 0, 0), (0, 1, 0, 0, 1, 0, 0, 0),
    (1, 1, 1, 0, 0, 1, 0, 0), (0, 0, 0, 0, 0, 0, 0, 0), (0, 0, 0, 0, 0, 0, 0, 0), (0, 0, 0, 0, 0, 0, 0, 0),
    (0, 0, 0, 0, 0, 0, 0, 0))),
    (experience: (
    5000, 12000, 27000, 60000, 125000, 200000, 425000, 800000, 1500000, 2000000, 2500000, 3000000, 3500000, -1, -1, -1,
    -1);
     spellSlots: (
    (0, 0, 0, 0, 0, 0, 0, 0), (0, 0, 0, 0, 0, 0, 0, 0), (0, 0, 0, 0, 0, 0, 0, 0), (0, 0, 0, 0, 0, 0, 0, 0),
    (1, 0, 0, 0, 0, 0, 0, 0), (1, 0, 0, 0, 0, 0, 0, 0),
    (0, 1, 0, 0, 0, 0, 0, 0), (1, 1, 0, 0, 0, 0, 0, 0), (1, 0, 0, 0, 0, 0, 0, 0), (0, 0, 1, 0, 0, 0, 0, 0),
    (1, 1, 0, 1, 0, 0, 0, 0), (0, 1, 0, 0, 1, 0, 0, 0),
    (1, 1, 1, 0, 0, 1, 0, 0), (0, 0, 0, 0, 0, 0, 0, 0), (0, 0, 0, 0, 0, 0, 0, 0), (0, 0, 0, 0, 0, 0, 0, 0),
    (0, 0, 0, 0, 0, 0, 0, 0))),
    (experience: (
    2251, 4501, 10001, 20001, 40001, 90001, 150001, 225001, 325001, 650001, 975001, 1300001, 1625001, -1, -1, -1, -1);
     spellSlots: (
    (0, 0, 0, 0, 0, 0, 0, 0), (0, 0, 0, 0, 0, 0, 0, 0), (0, 0, 0, 0, 0, 0, 0, 0), (0, 0, 0, 0, 0, 0, 0, 0),
    (0, 0, 0, 0, 0, 0, 0, 0), (0, 0, 0, 0, 0, 0, 0, 0),
    (1, 0, 0, 0, 0, 0, 0, 0), (0, 0, 0, 0, 1, 0, 0, 0), (1, 0, 0, 0, 0, 0, 0, 0), (0, 0, 0, 0, 1, 0, 0, 0),
    (0, 1, 0, 0, 0, 0, 0, 0), (0, 0, 0, 0, 0, 1, 0, 0),
    (0, 1, 0, 0, 0, 0, 0, 0), (0, 0, 0, 0, 0, 0, 0, 0), (0, 0, 0, 0, 0, 0, 0, 0), (0, 0, 0, 0, 0, 0, 0, 0),
    (0, 0, 0, 0, 0, 0, 0, 0))),
    (experience: (
    5000, 10000, 20000, 38000, 55000, 100000, 200000, 400000, 600000, 800000, 1000000, 1250000, 1500000, -1, -1, -1,
    -1);
     spellSlots: (
    (1, 0, 0, 0, 0, 0, 0, 0), (0, 1, 0, 0, 0, 0, 0, 0), (1, 1, 0, 0, 0, 0, 0, 0), (1, 0, 1, 0, 0, 0, 0, 0),
    (0, 0, 1, 0, 0, 0, 0, 0), (0, 1, 0, 1, 0, 0, 0, 0),
    (0, 0, 1, 1, 0, 0, 0, 0), (0, 0, 0, 0, 1, 0, 0, 0), (0, 1, 0, 0, 1, 1, 0, 0), (0, 0, 1, 1, 1, 1, 1, 0),
    (0, 0, 0, 1, 1, 1, 1, 1), (1, 1, 1, 0, 0, 0, 0, 0),
    (0, 0, 0, 0, 0, 0, 0, 0), (0, 0, 0, 0, 0, 0, 0, 0), (0, 0, 0, 0, 0, 0, 0, 0), (0, 0, 0, 0, 0, 0, 0, 0),
    (0, 0, 0, 0, 0, 0, 0, 0))),
    (experience: (
    5000, 10000, 18000, 36000, 50000, 90000, 180000, 350000, 500000, 700000, 900000, 1100000, 1300000, -1, -1, -1, -1);
     spellSlots: (
    (1, 0, 0, 0, 0, 0, 0, 0), (0, 1, 0, 0, 0, 0, 0, 0), (1, 1, 0, 0, 0, 0, 0, 0), (1, 0, 1, 0, 0, 0, 0, 0),
    (0, 0, 1, 0, 0, 0, 0, 0), (0, 1, 0, 1, 0, 0, 0, 0),
    (0, 0, 1, 1, 0, 0, 0, 0), (0, 0, 0, 0, 1, 0, 0, 0), (0, 1, 0, 0, 1, 1, 0, 0), (0, 0, 1, 1, 1, 1, 1, 0),
    (0, 0, 0, 1, 1, 1, 1, 1), (1, 1, 1, 0, 0, 0, 0, 0),
    (0, 0, 0, 0, 0, 0, 0, 0), (0, 0, 0, 0, 0, 0, 0, 0), (0, 0, 0, 0, 0, 0, 0, 0), (0, 0, 0, 0, 0, 0, 0, 0),
    (0, 0, 0, 0, 0, 0, 0, 0))),
    (experience: (
    1251, 2501, 5001, 10001, 20001, 42501, 70001, 110001, 160001, 220001, 440001, 660001, 880001, 1100001, 1320001,
    1540001, 1760001);
     spellSlots: (
    (0, 0, 0, 0, 0, 0, 0, 0), (0, 0, 0, 0, 0, 0, 0, 0), (0, 0, 0, 0, 0, 0, 0, 0), (0, 0, 0, 0, 0, 0, 0, 0),
    (0, 0, 0, 0, 0, 0, 0, 0), (0, 0, 0, 0, 0, 0, 0, 0),
    (0, 0, 0, 0, 0, 0, 0, 0), (0, 0, 0, 0, 0, 0, 0, 0), (0, 0, 0, 0, 0, 0, 0, 0), (0, 0, 0, 0, 0, 0, 0, 0),
    (0, 0, 0, 0, 0, 0, 0, 0), (0, 0, 0, 0, 0, 0, 0, 0),
    (0, 0, 0, 0, 0, 0, 0, 0), (0, 0, 0, 0, 0, 0, 0, 0), (0, 0, 0, 0, 0, 0, 0, 0), (0, 0, 0, 0, 0, 0, 0, 0),
    (0, 0, 0, 0, 0, 0, 0, 0))),
    (experience: (
    2751, 5501, 12001, 24001, 45001, 95001, 175001, 350001, 700001, 1050001, 1400001, 1750001, 2100001, -1, -1, -1, -1);
     spellSlots: (
    (0, 0, 0, 0, 0, 0, 0, 0), (0, 0, 0, 0, 0, 0, 0, 0), (0, 0, 0, 0, 0, 0, 0, 0), (0, 0, 0, 0, 0, 0, 0, 0),
    (0, 0, 0, 0, 0, 0, 0, 0), (0, 0, 0, 0, 0, 0, 0, 0),
    (0, 0, 0, 0, 0, 0, 0, 0), (1, 0, 0, 0, 0, 0, 0, 0), (1, 0, 0, 0, 0, 0, 0, 0), (0, 1, 0, 0, 0, 0, 0, 0),
    (0, 1, 0, 0, 0, 0, 0, 0), (0, 0, 1, 0, 0, 0, 0, 0),
    (1, 0, 0, 0, 0, 0, 0, 0), (0, 0, 0, 0, 0, 0, 0, 0), (0, 0, 0, 0, 0, 0, 0, 0), (0, 0, 0, 0, 0, 0, 0, 0),
    (0, 0, 0, 0, 0, 0, 0, 0))));
  { unused }
  startingGoldDice: array[0..7, 0..1] of Byte = (
    (3, 6), (3, 6), (5, 4), (5, 4), (5, 4), (2, 4), (2, 6), (5, 4));
  { by class, level, then save }
  savingThrows: array[0..7, 1..18, 0..4] of Byte = (
    ((10, 13, 14, 16, 15), (10, 13, 14, 16, 15), (10, 13, 14, 16, 15), (9, 12, 13, 15, 14),
    (9, 12, 13, 15, 14),
    (9, 12, 13, 15, 14), (7, 10, 11, 13, 12), (7, 10, 11, 13, 12), (7, 10, 11, 13, 12),
    (6, 9, 10, 12, 11),
    (6, 9, 10, 12, 11), (6, 9, 10, 12, 11), (5, 8, 9, 11, 10), (5, 8, 9, 11, 10),
    (5, 8, 9, 11, 10),
    (4, 7, 8, 10, 9), (4, 7, 8, 10, 9), (4, 7, 8, 10, 9)), ((10, 13, 14, 16, 15),
    (10, 13, 14, 16, 15),
    (10, 13, 14, 16, 15), (9, 12, 13, 15, 14), (9, 12, 13, 15, 14), (9, 12, 13, 15, 14),
    (7, 10, 11, 13, 12),
    (7, 10, 11, 13, 12), (7, 10, 11, 13, 12), (6, 9, 10, 12, 11), (6, 9, 10, 12, 11),
    (6, 9, 10, 12, 11),
    (5, 8, 9, 11, 10), (5, 8, 9, 11, 10), (5, 8, 9, 11, 10), (4, 7, 8, 10, 9),
    (4, 7, 8, 10, 9),
    (4, 7, 8, 10, 9)), ((14, 15, 16, 17, 17), (14, 15, 16, 17, 17), (13, 14, 15, 16, 16),
    (13, 14, 15, 16, 16),
    (11, 12, 13, 13, 14), (11, 12, 13, 13, 14), (10, 11, 12, 12, 13), (10, 11, 12, 12, 13),
    (8, 9, 10, 9, 11),
    (8, 9, 10, 9, 11), (7, 8, 9, 8, 10), (7, 8, 9, 8, 10), (5, 6, 7, 5, 8),
    (5, 6, 7, 5, 8),
    (4, 5, 6, 4, 7), (4, 5, 6, 4, 7), (3, 4, 5, 4, 6), (3, 4, 5, 4, 6)),
    ((14, 15, 16, 17, 17),
    (14, 15, 16, 17, 17), (13, 14, 15, 16, 16), (13, 14, 15, 16, 16), (11, 12, 13, 13, 14),
    (11, 12, 13, 13, 14),
    (10, 11, 12, 12, 13), (10, 11, 12, 12, 13), (8, 9, 10, 9, 11), (8, 9, 10, 9, 11),
    (7, 8, 9, 8, 10),
    (7, 8, 9, 8, 10), (5, 6, 7, 5, 8), (5, 6, 7, 5, 8), (4, 5, 6, 4, 7),
    (4, 5, 6, 4, 7),
    (3, 4, 5, 4, 6), (3, 4, 5, 4, 6)), ((14, 15, 16, 17, 17), (14, 15, 16, 17, 17),
    (13, 14, 15, 16, 16),
    (13, 14, 15, 16, 16), (11, 12, 13, 13, 14), (11, 12, 13, 13, 14), (10, 11, 12, 12, 13),
    (10, 11, 12, 12, 13),
    (8, 9, 10, 9, 11), (8, 9, 10, 9, 11), (7, 8, 9, 8, 10), (7, 8, 9, 8, 10),
    (5, 6, 7, 5, 8),
    (5, 6, 7, 5, 8), (4, 5, 6, 4, 7), (4, 5, 6, 4, 7), (3, 4, 5, 4, 6),
    (3, 4, 5, 4, 6)),
    ((14, 13, 11, 15, 12), (14, 13, 11, 15, 12), (14, 13, 11, 15, 12), (14, 13, 11, 15, 12),
    (14, 13, 11, 15, 12),
    (13, 11, 9, 13, 10), (13, 11, 9, 13, 10), (13, 11, 9, 13, 10), (13, 11, 9, 13, 10),
    (13, 11, 9, 13, 10),
    (11, 9, 7, 11, 8), (11, 9, 7, 11, 8), (11, 9, 7, 11, 8), (11, 9, 7, 11, 8),
    (11, 9, 7, 11, 8),
    (10, 7, 5, 9, 6), (10, 7, 5, 9, 6), (10, 7, 5, 9, 6)), ((13, 12, 14, 16, 15),
    (13, 12, 14, 16, 15),
    (13, 12, 14, 16, 15), (13, 12, 14, 16, 15), (12, 11, 12, 15, 13), (12, 11, 12, 15, 13),
    (12, 11, 12, 15, 13),
    (12, 11, 12, 15, 13), (11, 10, 10, 14, 11), (11, 10, 10, 14, 11), (11, 10, 10, 14, 11),
    (11, 10, 10, 14, 11),
    (10, 9, 8, 13, 9), (10, 9, 8, 13, 9), (10, 9, 8, 13, 9), (10, 9, 8, 13, 9),
    (9, 8, 6, 12, 7),
    (9, 8, 6, 12, 7)), ((14, 15, 16, 17, 17), (14, 15, 16, 17, 17), (13, 14, 15, 16, 16),
    (13, 14, 15, 16, 16),
    (11, 12, 13, 13, 14), (11, 12, 13, 13, 14), (10, 11, 12, 12, 13), (10, 11, 12, 12, 13),
    (8, 9, 10, 9, 11),
    (8, 9, 10, 9, 11), (7, 8, 9, 8, 10), (7, 8, 9, 8, 10), (5, 6, 7, 5, 8),
    (5, 6, 7, 5, 8),
    (4, 5, 6, 4, 7), (4, 5, 6, 4, 7), (3, 4, 5, 4, 6), (3, 4, 5, 4, 6)));
  { cleric, white robe, red robe: by level, 0 ends a level }
  spellsByLevel: array[1..3, 1..8, 1..10] of Byte = (
    ((1, 3, 5, 6, 8, 0, 0, 0, 0, 0), (22, 23, 24, 25, 26, 27, 28, 0, 0, 0),
    (37, 39, 41, 42, 43, 0, 0, 0, 0, 0), (67, 70, 58, 69, 0, 0, 0, 0, 0, 0),
    (71, 73, 74, 75, 0, 0, 0, 0, 0, 0), (53, 0, 0, 0, 0, 0, 0, 0, 0, 0),
    (7, 17, 0, 0, 0, 0, 0, 0, 0, 0), (0, 0, 0, 0, 0, 0, 0, 0, 0, 0)),
    ((10, 11, 14, 15, 16, 18, 19, 21, 0, 0), (29, 34, 33, 0, 0, 0, 0, 0, 0, 0),
    (46, 47, 49, 51, 52, 54, 0, 0, 0, 0), (85, 87, 81, 82, 86, 88, 89, 100, 0, 0),
    (91, 92, 93, 94, 0, 0, 0, 0, 0, 0), (56, 63, 0, 0, 0, 0, 0, 0, 0, 0),
    (108, 110, 0, 0, 0, 0, 0, 0, 0, 0), (111, 112, 113, 114, 0, 0, 0, 0, 0, 0)),
    ((9, 11, 12, 15, 18, 19, 20, 0, 0, 0), (29, 30, 31, 32, 34, 35, 0, 0, 0, 0),
    (45, 47, 48, 50, 51, 55, 0, 0, 0, 0), (85, 87, 83, 84, 0, 0, 0, 0, 0, 0),
    (90, 98, 0, 0, 0, 0, 0, 0, 0, 0), (56, 60, 66, 72, 0, 0, 0, 0, 0, 0),
    (108, 109, 110, 0, 0, 0, 0, 0, 0, 0), (114, 0, 0, 0, 0, 0, 0, 0, 0, 0)));
  { by race, then class }
  racialLevelCaps: array[0..6, 0..7] of Byte = (
    (14, 0, 10, 12, 14, 14, 0, 0), (14, 0, 14, 0, 14, 14, 18, 0),
    (14, 0, 9, 0, 11, 10, 18, 10),
    (10, 0, 14, 8, 0, 0, 8, 0), (10, 0, 14, 0, 8, 0, 10, 0),
    (12, 0, 5, 0, 5, 0, 18, 0),
    (14, 0, 14, 14, 14, 14, 18, 14));
  { the mode CbtActs.CombatAimMenu takes when aiming a spell }
  spellAimMode: Byte = 0;
  { the mode Combat passes when aiming an attack }
  attackAimMode: Byte = 1;
  { the Tandy graphics reserve in paragraphs; GameBoot stores it shifted left 3 in the word after FreePtr }
  tandyHeapReserve: Byte = 10;

{ The copy-protection question's fragments and the input devices' tables. }
const
  { The copy-protection question's fragments, each with its own spaces. The question's start }
  promptWord: String[16] = ' what is word # ';
  { CopyProtection's journal form }
  promptEntry: String[20] = ' of journal entry # ';
  { never shown }
  promptTale: String[18] = ' of tavern tale # ';
  { Camp.RuleBookCheck's heading form }
  promptHeading: String[19] = ' after the heading ';
  { CopyProtection's page reference }
  promptPage: String[16] = ' (journal, page ';
  { RuleBookCheck's page reference }
  promptRuleBookPage: String[18] = ' (rule book, page ';
  { never shown }
  woofText: String[4] = 'Woof';
  { the single bits 0..4; never read }
  bitMasksLow: array[0..4] of Byte = (
    $01, $02, $04, $08, $10);
  { the BIOS keyboard flags' Num Lock bit, which GameInit sets }
  numLockBit: Byte = $20;
  { the single bits 6 and 7; never read }
  bitMasksHigh: array[0..1] of Byte = (
    $40, $80);
  { the mouse driver's interrupt }
  mouseInterrupt: Byte = $33;
  { the driver's function numbers Mouse indexes, zero-terminated }
  mouseFunctions: array[0..32] of Byte = (
    $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0A, $0B, $0C, $0D, $0E, $0F, $10, $13, $14, $15, $19, $1A, $1B,
    $1C,
    $1D, $1E, $1F, $20, $21, $22, $23, $24, $00);
  { the mouse cursor's AND and XOR masks on EGA }
  cursorMaskEga: array[0..63] of Byte = (
    $FF, $3F, $FF, $1F, $FF, $0F, $FF, $07, $FF, $03, $FF, $01, $FF, $00, $7F, $00, $3F, $00, $3F, $00, $FF, $01, $FF,
    $00,
    $FF, $10, $7F, $F8, $7F, $F8, $7F, $FC, $00, $00, $00, $40, $00, $60, $00, $70, $00, $78, $00, $7C, $00, $7E, $00,
    $7F,
    $80, $7F, $00, $7C, $00, $6C, $00, $46, $00, $06, $00, $03, $00, $03, $00, $00);
  { the mouse cursor's AND and XOR masks on CGA }
  cursorMaskCga: array[0..63] of Byte = (
    $FF, $0F, $FF, $03, $FF, $00, $3F, $00, $0F, $00, $03, $00, $00, $00, $03, $00, $03, $00, $03, $3F, $00, $FF, $00,
    $FF,
    $C3, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $00, $00, $00, $30, $00, $3C, $00, $3F, $C0, $3F, $F0, $3F, $FC, $3F, $C0,
    $3F,
    $F0, $3C, $F0, $00, $3C, $00, $3C, $00, $00, $00, $00, $00, $00, $00, $00, $00);
  { [stick, button]. ReadJoystick (joystick.asm) shifts the game-port button nibble down by 4, so the masks are
    $01/$02/$04/$08, not $10..$80. }
  joystickButtonMasks: array[1..2, 1..2] of Byte = (
    ($01, $02), ($04, $08));
  { [row, column], the axis threshold bands Joystick.JoyZone finds; 8 is the center, which JoyZone also returns when it
    gets no reading. }
  joystickZoneMap: array[0..5, 0..5] of Byte = (
    (7, 7, 0, 0, 1, 1), (7, 8, 8, 8, 8, 1), (6, 8, 8, 8, 8, 2),
    (6, 8, 8, 8, 8, 2), (5, 8, 8, 8, 8, 3), (5, 5, 4, 4, 3, 3));
  { numpad digit per zone; GameIo.ReadGameKey reads zones 0..7 }
  joystickZoneKeys: array[0..9] of Byte = (
    56, 57, 54, 51, 50, 49, 52, 55, 32, 0);

implementation

end.
