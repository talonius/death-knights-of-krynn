{ EclMenu -- the ECL machine's support: loading a script and its operands, reading and writing GBVM addresses (the four
  script zones, zone 1's cells that are the current character's fields, and the hand-mapped cells of zone 4 -- map
  position, facing, view colors), script strings, comparisons, GOSUB, menus, monsters in the view, robbery and damage. }
{$O+,F+}
unit EclMenu;
interface
uses C_Class, C_Dir, C_Ifc, C_Keys, C_Side, C_Status, Crt, GDConsts, GDVars, Types, TextRend, MapView,
  FxEngine, View3D, MenuCore, DaxIo, Portrait, CharHlp, ViewChar, SaveLoad;

{ Returns the value of an operand: a literal byte (type 0), the GBVM value at its address (1, 3, $80), or its two bytes
  as a word (2, $81).
  @param(idx Operand number, from 1.)
  @returns(The operand's value.) }
function GetEclVar(idx: ShortInt): Word;

{ Decodes the arguments of the current script command: each has a type byte and a low byte, and types 1..3 add a high
  byte. Type $80 is an inline packed string of that length and $81 the address of a string; both go to the next script
  string. Leaves the instruction pointer on the next command.
  @param(count The number of arguments.) }
procedure LoadEclVars(count: Byte);

{ Starts the script in zone 3: resets the ECL state and colors, reads its five entry addresses (before move, after move,
  before camp, camp interrupted, main), and for a new game clears 32 bytes of zone 0 from $4C00 and ten of zone 1 from
  $7F79. }
procedure EclInit;

{ Loads ECL script scriptId from the current disk's ECL archive (ECL1.DAX on disk 5) into zone 3, retrying until it
  reads.
  @param(scriptId Script to load.) }
procedure LoadEclScript(scriptId: Byte);

{ Allocates a creature and loads monster id into it, returning its item, effect and spell lists.
  @param(id Monster number.)
  @param(cr Receives the creature.)
  @param(inventory Receives its items.)
  @param(effects Receives its effects.)
  @param(spells Receives its spell block.) }
procedure InitCreature(id: Byte; var cr: Types.PCharacter; var inventory: Types.PItem; var effects: Types.PEffect;
                       var spells: Types.PSpellBlock);

{ Works out how far ahead a monster can appear. Outside the 3D view it is 2, also stored as the zone's monster distance;
  in it, the number of open cells (at most 2) walking from the position in the facing before a wall.
  @param(x The starting column.)
  @param(y The starting row.)
  @param(facing The direction, 0, 2, 4 or 6.)
  @returns(The distance in cells, 0..2.) }
function MaxMonsterDist(x, y, facing: Byte): Byte;

{ Shows a monster at distance dist: its SPRIT sprite in the 3-D view (once per encounter, leaving the automap), and its
  PIC picture up close or when there is no sprite, while the encounter menu allows pictures.
  @param(spriteId SPRIT picture of the monster.)
  @param(pictureId PIC picture of the monster.)
  @param(dist Distance, 0..2.)
  @param(flags The encounter's picture flags.) }
procedure DisplayMonster(spriteId, pictureId, dist: Byte; var flags: Types.TMonFlags);

{ Joins two bytes into a word.
  @param(lower The low byte.)
  @param(upper The high byte.)
  @returns(The high byte times 256 plus the low byte.) }
function CombineBytesToWord(lower, upper: Byte): Word;

{ Turns a 6-bit game character into ASCII: codes below 32 gain 64, and higher codes stay as they are.
  @param(c The game character.)
  @returns(The ASCII character.) }
function DecodeGameCharacter(c: Byte): Char;

{ Finds the GBVM bank holding an address.
  @param(vmAddr The GBVM address.)
  @returns(0 for $4B00..$4EFF, 1 for $7C00..$7FFF, 2 for $7A00..$7BFF, 3 (the script) for $8000..$9DFF, and 4 for
    anything else.) }
function GbvmZone(vmAddr: Word): Byte;

{ Returns a creature's 0-based position in the party.
  @param(cr The creature.)
  @returns(Its position.) }
function PartyIndexOf(cr: Types.PCharacter): Byte;

{ Reads the current character's field behind a zone-1 address. Name bytes copy iconDimensions bytes into a Word.
  @param(vmAddr Zone-1 GBVM address.)
  @param(found Set False when the address is not one of them.)
  @returns(The field's value.) }
function SpecialReadZ1(vmAddr: Word; var found: Boolean): Word;

{ Writes the current character's field behind zone-1 address vmAddr: memorized spells, npc, coins, back in play, side
  and quick-fight, hit points, and $7F12, which swaps to that disk.
  @param(vmAddr Zone-1 GBVM address.)
  @param(value Value to write.) }
procedure SpecialWriteZ1(vmAddr, value: Word);

{ Writes a byte (kind 0, 1) or word to GBVM address vmAddr. Zone 0 notes sky changes and switches the interface on the
  dungeon flag; zone 1 also writes the character field; zone 4 sets map x, y and facing (0..3, taken mod 4) or the wall
  and ceiling colors.
  @param(vmAddr GBVM address.)
  @param(value Value to write.)
  @param(kind 0 or 1 for a byte, otherwise a word.) }
procedure WriteGbvm(vmAddr, value: Word; kind: Byte);

{ Reads a byte or word from a GBVM address: facing at $4BEA and $033D, 1 at $4CF8, the character fields in zone 1, and
  map x, y, facing (0..3 in the 3-D view), wall ahead and cell event at $C04B..$C04F.
  @param(vmAddr GBVM address.)
  @param(kind 0 or 1 for a byte, otherwise a word.)
  @returns(The value.) }
function ReadGbvm(vmAddr: Word; kind: Byte): Word;

{ Writes a string, zero-terminated, at a GBVM address in any zone; the zone-1 base address sets the current character's
  name instead. Addresses outside the zones are ignored.
  @param(vmAddr The GBVM address.)
  @param(s The string.) }
procedure WriteGbvmString(vmAddr: Word; s: String);

{ Decodes packed 6-bit game characters at the script's instruction pointer into a script string, four characters to
  three bytes; zero characters are dropped. The instruction pointer ends on the last byte read.
  @param(len The number of packed bytes.)
  @param(strIdx The script string to fill.) }
procedure ConvGbString(len, strIdx: Byte);

{ Copies the zero-terminated string at a GBVM address into a script string. The zone-1 base address gives the current
  character's name; addresses outside the zones give an empty string.
  @param(strIdx The script string filled.)
  @param(vmAddr The GBVM address.) }
procedure DerefGbString(strIdx: Byte; vmAddr: Word);

{ A script's horizontal menu; an extended key outside the overland map with overland travel on selects the adjacent
  character.
  @param(query Question shown first.)
  @param(menu The menu's choices.)
  @param(qCol Unused.)
  @param(mCol Unused.)
  @param(hlCol Unused.)
  @param(enterOk True to accept Enter, and Escape as 0.)
  @param(animate True to keep the picture box animating.)
  @returns(The chosen index.) }
function MenuHorizontalCharacterSelect(query: Types.TString40; menu: String; qCol, mCol, hlCol: Byte; enterOk,
                                       animate: Boolean): Byte;

{ A script's vertical menu over list; it shows selectMenuText whatever menu says.
  @param(query Question shown first.)
  @param(menu Menu text; its shortcuts are worked out and not used.)
  @param(qCol Unused.)
  @param(mCol Unused.)
  @param(hlCol Unused.)
  @param(ulCol Left column.)
  @param(ulRow Top row.)
  @param(lrCol Right column.)
  @param(lrRow Bottom row.)
  @param(list The rows.)
  @param(addExit Whether to offer Exit.)
  @param(redraw Redraw flag, kept between calls.)
  @param(idx The menu's position, kept between calls.)
  @param(selected Receives the row chosen.) }
procedure EclVerticalMenu(query: Types.TString40; menu: String; qCol, mCol, hlCol: Byte; ulCol, ulRow, lrCol,
                          lrRow: ShortInt; list: Types.PItem; addExit: Byte; var redraw: Byte; var idx: Integer;
                          var selected: Types.PItem);

{ Sets the six comparison flags from two strings: equal, not equal, less, greater, less or equal, greater or equal.
  @param(leftOperand The left side.)
  @param(rightOperand The right side.) }
procedure EclCompareStr(leftOperand, rightOperand: String);

{ Sets the six comparison flags from two numbers: equal, not equal, less, greater, less or equal, greater or equal.
  @param(leftOperand The left side.)
  @param(rightOperand The right side.) }
procedure EclCompareInt(leftOperand, rightOperand: Word);

{ Pushes the instruction pointer on the script return stack and jumps to the address in a loaded argument.
  @param(varIdx The argument holding the address.) }
procedure EclGosub(varIdx: Byte);

{ Moves the party one cell the way it faces, wrapping on the 16x16 map, refreshes the cell event and the wall ahead, and
  marks the party moved. }
procedure EclMoveForward;

{ Leaves cr fraction of each of its coins.
  @param(fraction Fraction of each coin type left.)
  @param(cr Creature robbed.) }
procedure RobMoney(fraction: Real; cr: Types.PCharacter);

{ Takes each of a character's items with a chance in percent, unreadying it first. An item heavier than 255 lowers the
  chance by 90 and one heavier than 24 by 50, to no less than 0. Note: the lowered chance carries over to the items
  after it.
  @param(chance The chance in percent.)
  @param(cr The character robbed.) }
procedure RobItems(chance: Byte; cr: Types.PCharacter);

{ Steps over the command at eclIp by fetching its operands; $2C appears in two lists and takes one. }
procedure SkipEclCmd;

{ Empty routine with no callers. }
procedure NoopEclMenu;

{ Deals script damage to a creature with a message, then redraws the party panel; a dead creature is skipped. The
  creature dies when the damage is more than 10 above its hit points; otherwise the message gives the damage, at most
  three digits. When the message window is full it waits for a key first.
  @param(dmg The damage.)
  @param(cr The creature.) }
procedure EclInflictDamage(dmg: Word; cr: Types.PCharacter);

{ Refreshes the event byte and, when a picture, sprite, color, move or sky change is pending, redraws the view and the
  status line and refreshes the wall-ahead byte. }
procedure UpdateEclDisplay;

{ Prepares a script menu string: capitals are lower-cased, and each '~' is removed and the letter after it upper-cased
  as that option's hotkey. Note: digits are shifted along with the capitals, which turns them into letters.
  @param(menu The menu string, prepared in place.)
  @param(options Receives the hotkeys in order.)
  @param(shortcutCount Receives their count.) }
procedure MenuToOptions(var menu: String; var options: Types.TString40; var shortcutCount: Byte);
implementation

procedure LoadEclVars(count: Byte);
var
  i: Byte;
  strIdx: Byte;
  value: Word;
  len: Word;
begin
  strIdx := 0;
  for i := 1 to count do begin
    GDVars.varTypes[i] := GDVars.zone3^[GDVars.eclIp + 1];
    GDVars.varLo[i] := GDVars.zone3^[GDVars.eclIp + 2];
    GDVars.eclIp := GDVars.eclIp + 2;
    case GDVars.varTypes[i] of
      1, 2, 3: begin
        Inc(GDVars.eclIp);
        GDVars.varHi[i] := GDVars.zone3^[GDVars.eclIp]
      end;
      $80: begin
        Inc(strIdx);
        len := GDVars.varLo[i];
        if len > 0 then EclMenu.ConvGbString(len, strIdx)
        else GDVars.gbStrings[strIdx] := ''
      end;
      $81: begin
        Inc(strIdx);
        Inc(GDVars.eclIp);
        GDVars.varHi[i] := GDVars.zone3^[GDVars.eclIp];
        value := EclMenu.CombineBytesToWord(GDVars.varLo[i], GDVars.varHi[i]);
        EclMenu.DerefGbString(strIdx, value)
      end
    end
  end;
  Inc(GDVars.eclIp)
end;

function GetEclVar(idx: ShortInt): Word;
var
  { Unused in this version; see the other implementations of this routine. }
  address: Word;
  { Unused in this version; see the other implementations of this routine. }
  value: Word;
  { Unused in this version; see the other implementations of this routine. }
  kind: Word;
  lowByte: Byte;
  highByte: Byte;
begin
  lowByte := GDVars.varLo[idx];
  highByte := GDVars.varHi[idx];
  case GDVars.varTypes[idx] of
    0: GetEclVar := lowByte;
    1, 3, $80: GetEclVar := EclMenu.ReadGbvm(highByte * 256 + lowByte, GDVars.varTypes[idx]);
    2, $81: GetEclVar := EclMenu.CombineBytesToWord(lowByte, highByte)
  end
end;

procedure EclInit;
var
  { Unused in this version; see the other implementations of this routine. }
  scriptId: Byte;
  i: Word;
begin
  GDVars.eclGraphics := 0;
  GDVars.protectionShown := 0;
  GDVars.statusCellWritten := 0;
  GDVars.nameCellWritten := 0;
  GDVars.wallColorSet := $41;
  GDVars.ceilingFloorColorSet := 9;
  GDVars.wallColorsChanged := 1;
  FillChar(GDVars.monsterFlags, SizeOf(GDVars.monsterFlags), 0);
  { the party holds CPIC slots 0..7 }
  GDVars.iconAnimation := 8;
  { the script's first byte }
  GDVars.eclIp := $8000;
  GDVars.breathAim := 0;
  GDVars.eclStack := nil;
  GDVars.eclStackPrev := nil;
  FillChar(GDVars.cmpFlags, SizeOf(GDVars.cmpFlags), 0);
  GDVars.zone1^.restPeriod[GDConsts.restPeriodIndex + $7C00] := 0;
  GDVars.zone1^.interruptPct[GDConsts.interruptPctIndex + $7C00] := 0;
  { the script begins with its five entry addresses }
  EclMenu.LoadEclVars(1);
  GDVars.eclEntryPoints.entries[1] := EclMenu.CombineBytesToWord(GDVars.varLo[1], GDVars.varHi[1]);
  EclMenu.LoadEclVars(1);
  GDVars.eclEntryPoints.entries[2] := EclMenu.CombineBytesToWord(GDVars.varLo[1], GDVars.varHi[1]);
  EclMenu.LoadEclVars(1);
  GDVars.eclEntryPoints.entries[3] := EclMenu.CombineBytesToWord(GDVars.varLo[1], GDVars.varHi[1]);
  EclMenu.LoadEclVars(1);
  GDVars.eclEntryPoints.entries[4] := EclMenu.CombineBytesToWord(GDVars.varLo[1], GDVars.varHi[1]);
  EclMenu.LoadEclVars(1);
  GDVars.eclEntryPoints.entries[5] := EclMenu.CombineBytesToWord(GDVars.varLo[1], GDVars.varHi[1]);
  if GDVars.loadedSave = 0 then begin
    for i := 1 to 32 do GDVars.zone0^.ecl[i + $4BFF] := 0;
    for i := 0 to 9 do GDVars.zone1^.newGameBytes[i + $7F79] := 0
  end
end;

procedure LoadEclScript(scriptId: Byte);
var
  { Unused in this version; see the other implementations of this routine. }
  scriptSize: Word;
  { Unused in this version; see the other implementations of this routine. }
  scriptOffset: Word;
  disk: String[1];
  sizeRead: Word;
  data: Types.PBytes;
begin
  FillChar(GDVars.zone3^, SizeOf(GDVars.zone3^), 0);
  GDVars.suppressDisk := 0;
  repeat
    MenuCore.ClearBottomLine;
    TextRend.DisplayString(GDConsts.messageColumn, GDConsts.messageRow, LightGreen, Black, GDConsts.loadingMessage);
    { disk 5's scripts are in ECL1.DAX }
    if GDVars.diskNumber = 5 then disk := '1'
    else Str(GDVars.diskNumber, disk);
    DaxIo.LoadDax('ECL' + disk, GDConsts.daxExtension, scriptId, sizeRead, data)
  until sizeRead >= 2;
  Move(data^[2], GDVars.zone3^, sizeRead - 2);
  FreeMem(data, sizeRead);
  MenuCore.ClearBottomLine
end;

procedure InitCreature(id: Byte; var cr: Types.PCharacter; var inventory: Types.PItem; var effects: Types.PEffect;
                       var spells: Types.PSpellBlock);
var
  { Unused in this version; see the other implementations of this routine. }
  item: Pointer;
begin
  cr := nil;
  GetMem(cr, SizeOf(Types.TCharacter));
  SaveLoad.LoadCreatureData(id, False, cr);
  inventory := cr^.items;
  effects := cr^.effects;
  spells := cr^.spells
end;

function MaxMonsterDist(x, y, facing: Byte): Byte;
var
  blocked: Boolean;
  dist: Byte;
begin
  dist := 0;
  blocked := False;
  MaxMonsterDist := 0;
  if GDVars.zone0^.inDungeon = 0 then begin
    MaxMonsterDist := 2;
    GDVars.zone1^.monsterDist[$7EC1] := 2
  end else
    while (dist < 2) and (not blocked) do begin
      if View3D.GetWallType(x, y, facing) = 0 then begin
        Inc(dist);
        MaxMonsterDist := dist;
        case facing of
          C_Dir.NORTH: Dec(y);
          C_Dir.EAST: Inc(x);
          C_Dir.SOUTH: Inc(y);
          C_Dir.WEST: Dec(x)
        end
      end else blocked := True
    end
end;

procedure DisplayMonster(spriteId, pictureId, dist: Byte; var flags: Types.TMonFlags);
var
  { Unused in this version; see the other implementations of this routine. }
  headPic: Pointer;
  { Unused in this version; see the other implementations of this routine. }
  bodyPic: Pointer;
  displayDist: Byte;
begin
  displayDist := dist + 1;
  if not flags[1] then
    if spriteId <> 255 then begin
      if not flags[0] then begin
        if GDVars.automapOn <> 0 then begin
          GDVars.automapOn := 0;
          GDVars.forceMapRedraw := 1;
          MapView.DisplayMapView
        end;
        if GDVars.zone0^.inDungeon <> 0 then begin
          Portrait.LoadAnimation('SPRIT', spriteId, GDConsts.iconFrame, GDVars.portraitAnimation);
          flags[0] := True;
          GDVars.spriteShown := 1
        end
      end else begin
        GDVars.forceMapRedraw := 1;
        MapView.DisplayMapView
      end;
      if GDVars.interfaceState = C_Ifc.VIEW_3D then Portrait.Show3DSprite(displayDist, GDVars.portraitAnimation)
    end;
  if not flags[1] then
    if pictureId <> 255 then
      if (dist = 0) or (spriteId = 255) then
        if GDVars.interfaceState = C_Ifc.VIEW_3D then
          if (GDVars.inEncounterMenu = 0) or (GDVars.monsterPictures <> 0) then begin
            GDVars.eclGraphics := 1;
            Portrait.LoadAnimation('PIC', pictureId, GDConsts.pictureMode, GDVars.portraitAnimation);
            flags[1] := True;
            Portrait.DisplayImageBuf(3, 3, True, GDVars.portraitAnimation.frames[1].pic)
          end
end;

function CombineBytesToWord(lower, upper: Byte): Word;
begin
  CombineBytesToWord := upper * 256 + lower
end;

function DecodeGameCharacter(c: Byte): Char;
begin
  if c > 31 then DecodeGameCharacter := Chr(c)
  else DecodeGameCharacter := Chr(c + 64)
end;

function GbvmZone(vmAddr: Word): Byte;
begin
  GbvmZone := 4;
  if (vmAddr >= $4B00) and (vmAddr <= $4EFF) then GbvmZone := 0;
  if (vmAddr >= $7C00) and (vmAddr <= $7FFF) then GbvmZone := 1;
  if (vmAddr >= $7A00) and (vmAddr <= $7BFF) then GbvmZone := 2;
  if (vmAddr >= $8000) and (vmAddr <= $9DFF) then GbvmZone := 3
end;

function PartyIndexOf(cr: Types.PCharacter): Byte;
var
  idx: Byte;
  p: Types.PCharacter;
  found: Boolean;
begin
  p := GDVars.partyHead;
  found := False;
  idx := 0;
  while (p <> nil) and (not found) do begin
    if p = cr then found := True
    else begin
      Inc(idx);
      p := p^.next
    end
  end;
  PartyIndexOf := idx
end;

function SpecialReadZ1(vmAddr: Word; var found: Boolean): Word;
var
  value: Word;
  coinIndex: ShortInt;
  { Unused in this version; see the other implementations of this routine. }
  zone: Byte;
begin
  found := True;
  vmAddr := vmAddr - $7C00;
  value := 0;
  with GDVars.currentCharacter^ do
  case vmAddr of
    { the count is the record's own iconDimensions byte }
    $00..$0F: Move(name[vmAddr + 1], value, iconDimensions);
    { [6] is past stats: exceptional strength }
    $14..$1A: value := stats[ShortInt(vmAddr - $14)].current;
    $1B..$64: if spells <> nil then
      value := spells^.memorized[vmAddr - $1B];
    { [6] likewise }
    $65..$6B: value := stats[ShortInt(vmAddr - $65)].base;
    $71: value := thac0Base;
    $72: value := race;
    $74: value := age;
    $76: value := maxHitPoints;
    $9A..$9E: value := saves[ShortInt(vmAddr - $9A)];
    $9F: value := currentMovement;
    $A5..$AC: begin
      value := thiefSkills[vmAddr - $A4]
    end;
    $B8: value := npc;
    $BB: value := robeOrder;
    $BC: value := deity;
    $BF: value := knightOrder;
    { steel, gems, jewelry: a word each }
    $C3..$C8: begin
      coinIndex := (vmAddr - $C3) div 2 + 4;
      value := coins[coinIndex]
    end;
    $D3: value := spellResistance;
    $D6: value := gender;
    $D8: value := alignment;
    { the classes held, a bit each }
    $EB: begin
      if classLevels[C_Class.MAGE] > 0 then Inc(value);
      if classLevels[C_Class.CLERIC] > 0 then Inc(value, 2);
      if classLevels[C_Class.THIEF] > 0 then Inc(value, 4);
      if classLevels[C_Class.FIGHTER] > 0 then Inc(value, 8);
      if classLevels[C_Class.KNIGHT] > 0 then Inc(value, $10);
      if classLevels[C_Class.PALADIN] > 0 then Inc(value, $40);
      if classLevels[C_Class.RANGER] > 0 then Inc(value, $80)
    end;
    { in play, or $80 once status disabled it }
    $100: if enabled = 0 then value := $80 else value := 1;
    $10E: value := thac0Adjusted;
    $10F: value := armorClass;
    $110: value := rearArmorClass;
    $119: value := hitPoints;
    $11A: value := currentMovement;
    $2B1: value := EclMenu.PartyIndexOf(GDVars.currentCharacter);
    $2B4: value := EclMenu.PartyIndexOf(GDVars.currentCharacter)
  else
    found := False
  end;
  SpecialReadZ1 := value
end;

procedure SpecialWriteZ1(vmAddr, value: Word);
var
  coinIndex: ShortInt;
begin
  vmAddr := vmAddr - $7C00;
  with GDVars.currentCharacter^ do
  case vmAddr of
    0: GDVars.nameCellWritten := 1;
    $1B..$64: if spells <> nil then
      spells^.memorized[vmAddr - $1B] := value;
    $B8: npc := value;
    $C3..$C8: begin
      coinIndex := (vmAddr - $C3) div 2 + 4;
      coins[coinIndex] := value
    end;
    { back in play }
    $100: if value = 1 then begin
      status := C_Status.OKAY;
      enabled := 1
    end;
    { 0 the party, $80 the party on quick fight, $81 a monster }
    $10C: case value of
      0, $80: begin
        side := C_Side.PLAYER;
        { stored as a Boolean into the Byte field }
        Boolean(quickFight) := value = $80
      end;
      $81: begin
        side := C_Side.ENEMY;
        Boolean(quickFight) := True
      end
    end;
    $119: hitPoints := value;
    { savedDisk at $7F12: swap to that disk }
    $312: DaxIo.PushState(value)
  end
end;

procedure WriteGbvm(vmAddr, value: Word; kind: Byte);
var
  zone: Byte;
  facingFound: Boolean;
  size: Byte;
begin
  if kind > 1 then size := 2 else size := 1;
  zone := EclMenu.GbvmZone(vmAddr);
  case zone of
    0: begin
      case vmAddr - $4B00 of
        { skyA, skyB }
        $FD, $FE: GDVars.skyChanged := True;
        $E6: if GDVars.zone0^.inDungeon <> value then begin
          GDVars.previousInterfaceState := GDVars.interfaceState;
          if value = 0 then GDVars.interfaceState := C_Ifc.OVERLAND
          else GDVars.interfaceState := C_Ifc.VIEW_3D
        end
      end;
      Move(value, GDVars.zone0^.ecl[vmAddr], size)
    end;
    1: begin
      Move(value, GDVars.zone1^.ecl[vmAddr], size);
      EclMenu.SpecialWriteZ1(vmAddr, value)
    end;
    2: Move(value, GDVars.zone2^[vmAddr], size);
    3: Move(value, GDVars.zone3^[vmAddr], size);
    4: if vmAddr > $BF68 then begin
      vmAddr := vmAddr - $BF68;
      case vmAddr of
        $E3: begin
          GDVars.partyMoved := True;
          GDVars.mapState.x := value
        end;
        $E4: begin
          GDVars.mapState.y := value;
          GDVars.partyMoved := True
        end;
        { 0..3 is a facing, reduced modulo 4 }
        $E5: begin
          repeat
            facingFound := True;
            case value of
              0: GDVars.mapState.facing := C_Dir.NORTH;
              1: GDVars.mapState.facing := C_Dir.EAST;
              2: GDVars.mapState.facing := C_Dir.SOUTH;
              3: GDVars.mapState.facing := C_Dir.WEST
            else
              facingFound := False;
              Dec(value, 4)
            end
          until facingFound = True;
          GDVars.partyMoved := True
        end;
        $F1: begin
          GDVars.wallColorSet := value;
          GDVars.wallColorsChanged := 1
        end;
        $F7: begin
          GDVars.ceilingFloorColorSet := value;
          GDVars.wallColorsChanged := 1
        end
      end
    end
  end
end;

function ReadGbvm(vmAddr: Word; kind: Byte): Word;
var
  zone: Byte;
  found: Boolean;
  { Unused in this version; see the other implementations of this routine. }
  zoneIndex: Byte;
  value: Word;
  size: Byte;
begin
  if kind > 1 then size := 2 else size := 1;
  zone := EclMenu.GbvmZone(vmAddr);
  found := False;
  value := 0;
  case zone of
    0: begin
      if vmAddr = $4BEA then value := GDVars.mapState.facing
      { firstMonsterDown reads as 1 }
      else if vmAddr = $4CF8 then value := 1
      else Move(GDVars.zone0^.ecl[vmAddr], value, size)
    end;
    1: begin
      value := EclMenu.SpecialReadZ1(vmAddr, found);
      if not found then Move(GDVars.zone1^.ecl[vmAddr], value, size)
    end;
    2: Move(GDVars.zone2^[vmAddr], value, size);
    3: Move(GDVars.zone3^[vmAddr], value, size);
    4: if vmAddr < $C04B then begin
      if vmAddr = $33D then value := GDVars.mapState.facing
    end else begin
      vmAddr := vmAddr - $C04B;
      case vmAddr of
        0: value := GDVars.mapState.x;
        1: value := GDVars.mapState.y;
        { 0..3 in the 3-D view }
        2: if GDVars.zone0^.inDungeon = 0 then value := GDVars.mapState.facing
          else value := Word(GDVars.mapState.facing) div 2;
        3: value := GDVars.mapState.wallAhead;
        4: value := GDVars.mapState.event
      end
    end
  end;
  ReadGbvm := value
end;

procedure WriteGbvmString(vmAddr: Word; s: String);
var
  zone: Byte;
  len: Byte;
  i: Byte;
begin
  zone := EclMenu.GbvmZone(vmAddr);
  len := Length(s);
  case ShortInt(zone) of
    0: begin
      if len > 0 then
        for i := 0 to len - 1 do GDVars.zone0^.ecl[vmAddr + i] := Ord(s[i + 1]);
      GDVars.zone0^.ecl[vmAddr + len] := 0
    end;
    1: if vmAddr = $7C00 then GDVars.currentCharacter^.name := s
      else begin
        if len > 0 then
          for i := 0 to len - 1 do GDVars.zone1^.ecl[vmAddr + i] := Ord(s[i + 1]);
        GDVars.zone1^.ecl[vmAddr + len] := 0
      end;
    2: begin
      if len > 0 then
        for i := 0 to len - 1 do GDVars.zone2^[vmAddr + i] := Ord(s[i + 1]);
      GDVars.zone2^[vmAddr + len] := 0
    end;
    3: begin
      if len > 0 then
        for i := 0 to len - 1 do GDVars.zone3^[vmAddr + i] := Ord(s[i + 1]);
      GDVars.zone3^[vmAddr + len] := 0
    end
  end
end;

procedure ConvGbString(len, strIdx: Byte);
var
  i: Byte;
  { Unused in this version; see the other implementations of this routine. }
  outPosition: Byte;
  cur: Byte;
  prev: Byte;
  sixBits: Byte;
  phase: Byte;
  ch: Char;
begin
  GDVars.gbStrings[strIdx] := '';
  i := 0;
  phase := 1;
  while i < len do begin
    if phase < 4 then begin
      Inc(GDVars.eclIp);
      prev := cur;
      cur := GDVars.zone3^[GDVars.eclIp];
      Inc(i)
    end;
    case phase of
      1: sixBits := cur shr 2;
      2: begin
        sixBits := Byte(prev shl 6) + Byte(cur shr 2);
        sixBits := sixBits shr 2
      end;
      3: begin
        sixBits := Byte(prev shl 4) + Byte(cur shr 4);
        sixBits := sixBits shr 2
      end;
      4: sixBits := cur and $3F
    end;
    if phase < 4 then Inc(phase) else phase := 1;
    if sixBits <> 0 then begin
      ch := EclMenu.DecodeGameCharacter(sixBits);
      GDVars.gbStrings[strIdx] := Concat(GDVars.gbStrings[strIdx], ch)
    end
  end;
  if phase = 4 then begin
    sixBits := cur and $3F;
    if sixBits <> 0 then begin
      ch := EclMenu.DecodeGameCharacter(sixBits);
      GDVars.gbStrings[strIdx] := Concat(GDVars.gbStrings[strIdx], ch)
    end
  end
end;

procedure DerefGbString(strIdx: Byte; vmAddr: Word);
var
  zone: Byte;
  i: Byte;
begin
  zone := EclMenu.GbvmZone(vmAddr);
  GDVars.gbStrings[strIdx] := '';
  i := 0;
  case ShortInt(zone) of
    0: while GDVars.zone0^.ecl[vmAddr + i] <> 0 do begin
      GDVars.gbStrings[strIdx] := Concat(GDVars.gbStrings[strIdx], Char(GDVars.zone0^.ecl[vmAddr + i]));
      Inc(i)
    end;
    1: if vmAddr = $7C00 then GDVars.gbStrings[strIdx] := GDVars.currentCharacter^.name
      else while GDVars.zone1^.ecl[vmAddr + i] <> 0 do begin
        GDVars.gbStrings[strIdx] := Concat(GDVars.gbStrings[strIdx], Char(GDVars.zone1^.ecl[vmAddr + i]));
        Inc(i)
      end;
    2: while GDVars.zone2^[vmAddr + i] <> 0 do begin
      GDVars.gbStrings[strIdx] := Concat(GDVars.gbStrings[strIdx], Char(GDVars.zone2^[vmAddr + i]));
      Inc(i)
    end;
    3: while GDVars.zone3^[vmAddr + i] <> 0 do begin
      GDVars.gbStrings[strIdx] := Concat(GDVars.gbStrings[strIdx], Char(GDVars.zone3^[vmAddr + i]));
      Inc(i)
    end
  end
end;

procedure MenuToOptions(var menu: String; var options: Types.TString40; var shortcutCount: Byte);
var
  i: Byte;
begin
  options := '';
  shortcutCount := 0;
  for i := 1 to Length(menu) do begin
    if menu[i] in ['0'..'9', 'A'..'Z'] then
      menu[i] := Chr(Ord(menu[i]) + 32);
    if menu[i] = '~' then begin
      Delete(menu, i, 1);
      menu[i] := UpCase(menu[i]);
      options := options + menu[i];
      Inc(shortcutCount)
    end
  end
end;

function MenuHorizontalCharacterSelect(query: Types.TString40; menu: String; qCol, mCol, hlCol: Byte; enterOk,
                                       animate: Boolean): Byte;
var
  options: Types.TString40;
  { Unused in this version; see the other implementations of this routine. }
  index: Byte;
  ch: Byte;
  shortcutCount: Byte;
begin
  EclMenu.MenuToOptions(menu, options, shortcutCount);
  MenuCore.EnableChoices(shortcutCount - 1);
  repeat
    ch := MenuCore.MenuHorizontal(query, menu, 1, Byte(animate));
    if (GDVars.menuExtendedKey <> 0) and (GDVars.interfaceState <> C_Ifc.OVERLAND) and
        (GDVars.zone0^.wildOn = 1) then begin
      CharHlp.DisplayRoster(GDVars.currentCharacter, False);
      ViewChar.SelectAdjacentCharacter(Char(ch));
      CharHlp.DisplayRoster(GDVars.currentCharacter, True);
      ch := 255
    end
  until (ch < shortcutCount) or ((ch = Ord(C_Keys.ESCAPE)) and enterOk);
  if ch = Ord(C_Keys.ESCAPE) then MenuHorizontalCharacterSelect := 0
  else MenuHorizontalCharacterSelect := ch
end;

procedure EclVerticalMenu(query: Types.TString40; menu: String; qCol, mCol, hlCol: Byte; ulCol, ulRow, lrCol,
                          lrRow: ShortInt; list: Types.PItem; addExit: Byte; var redraw: Byte; var idx: Integer;
                          var selected: Types.PItem);
var
  { Unused in this version; see the other implementations of this routine. }
  ch: Byte;
  options: Types.TString40;
  shortcutCount: Byte;
begin
  EclMenu.MenuToOptions(menu, options, shortcutCount);
  MenuCore.EnableChoices(1);
  ch := MenuCore.MenuVertical(query, GDConsts.selectMenuText, ulCol, ulRow, lrCol, lrRow, list, addExit, 1, redraw, idx,
                              selected)
end;

procedure EclCompareStr(leftOperand, rightOperand: String);
begin
  FillChar(GDVars.cmpFlags, SizeOf(GDVars.cmpFlags), 0);
  if leftOperand = rightOperand then GDVars.cmpFlags[0] := True;
  if leftOperand <> rightOperand then GDVars.cmpFlags[1] := True;
  if leftOperand < rightOperand then GDVars.cmpFlags[2] := True;
  if leftOperand > rightOperand then GDVars.cmpFlags[3] := True;
  if leftOperand <= rightOperand then GDVars.cmpFlags[4] := True;
  if leftOperand >= rightOperand then GDVars.cmpFlags[5] := True
end;

procedure EclCompareInt(leftOperand, rightOperand: Word);
begin
  FillChar(GDVars.cmpFlags, SizeOf(GDVars.cmpFlags), 0);
  if leftOperand = rightOperand then GDVars.cmpFlags[0] := True;
  if leftOperand <> rightOperand then GDVars.cmpFlags[1] := True;
  if leftOperand < rightOperand then GDVars.cmpFlags[2] := True;
  if leftOperand > rightOperand then GDVars.cmpFlags[3] := True;
  if leftOperand <= rightOperand then GDVars.cmpFlags[4] := True;
  if leftOperand >= rightOperand then GDVars.cmpFlags[5] := True
end;

procedure EclGosub(varIdx: Byte);
begin
  if GDVars.eclStack = nil then begin
    GetMem(GDVars.eclStack, SizeOf(Types.TEclStack));
    GDVars.eclStack^.next := nil
  end else begin
    GDVars.eclStackPrev := GDVars.eclStack;
    GetMem(GDVars.eclStack, SizeOf(Types.TEclStack));
    GDVars.eclStack^.next := GDVars.eclStackPrev
  end;
  GDVars.eclStack^.addr := GDVars.eclIp;
  GDVars.eclIp := EclMenu.CombineBytesToWord(GDVars.varLo[varIdx], GDVars.varHi[varIdx])
end;

procedure EclMoveForward;
begin
  case GDVars.mapState.facing of
    C_Dir.NORTH: if GDVars.mapState.y > 0 then Dec(GDVars.mapState.y) else GDVars.mapState.y := 15;
    C_Dir.EAST: if GDVars.mapState.x < 15 then Inc(GDVars.mapState.x) else GDVars.mapState.x := 0;
    C_Dir.SOUTH: if GDVars.mapState.y < 15 then Inc(GDVars.mapState.y) else GDVars.mapState.y := 0;
    C_Dir.WEST: if GDVars.mapState.x > 0 then Dec(GDVars.mapState.x) else GDVars.mapState.x := 15
  end;
  GDVars.mapState.event := View3D.GetMapEvent(GDVars.mapState.x, GDVars.mapState.y);
  GDVars.mapState.wallAhead := View3D.GetWallType(GDVars.mapState.x, GDVars.mapState.y, GDVars.mapState.facing);
  GDVars.partyMoved := True
end;

procedure RobMoney(fraction: Real; cr: Types.PCharacter);
begin
  cr^.coins[4] := Trunc(cr^.coins[4] * fraction);
  cr^.coins[5] := Trunc(cr^.coins[5] * fraction);
  cr^.coins[6] := Trunc(cr^.coins[6] * fraction)
end;

procedure RobItems(chance: Byte; cr: Types.PCharacter);
var
  roll: Byte;
  item: Types.PItem;
  nextItem: Types.PItem;
begin
  item := cr^.items;
  while item <> nil do begin
    { heavy items are harder to lift: -90, -50 }
    if item^.weight > 255 then begin
      if chance > 90 then chance := chance - 90
      else chance := 0
    end else if item^.weight > 24 then begin
      if chance > 50 then chance := chance - 50
      else chance := 0
    end;
    roll := FxEngine.RollDice(1, 100);
    nextItem := item^.next;
    if roll <= chance then begin
      if item^.equipped <> 0 then ViewChar.ToggleReadyItem(item);
      CharHlp.RemoveItem(cr, item)
    end;
    item := nextItem
  end
end;

procedure SkipEclCmd;
begin
  GDVars.curOpcode := GDVars.zone3^[GDVars.eclIp];
  case GDVars.curOpcode of
    1, 2, $A, $E, $11, $12, $1F, $20, $2C, $2D, $32, $34, $36, $38, $39, $3C, $3F, $40:
      EclMenu.LoadEclVars(1);
    3, 8, 9, $F, $10, $41: EclMenu.LoadEclVars(2);
    4..7, $B, $C, $21, $28, $2A, $2F, $30, $35, $37, $3B: EclMenu.LoadEclVars(3);
    $14: EclMenu.LoadEclVars(4);
    $2E: EclMenu.LoadEclVars(5);
    $1E, $2C: EclMenu.LoadEclVars(6)
  else
    Inc(GDVars.eclIp)
  end
end;

procedure EclInflictDamage(dmg: Word; cr: Types.PCharacter);
var
  { Unused in this version; see the other implementations of this routine. }
  damageType: Byte;
  msg: String;
  dmgStr: String[3];
  pause: Boolean;
begin
  if cr^.status = C_Status.DEAD_STATUS then Exit;
  pause := False;
  Str(dmg, dmgStr);
  if cr^.hitPoints + 10 < dmg then
    msg := '  ' + cr^.name + ' dies. '
  else
    msg := '  ' + cr^.name + ' is hit FOR ' + dmgStr + ' points of Damage.';
  if GDVars.currentRow > 22 then begin
    GDVars.currentRow := 17;
    pause := True;
    TextRend.DisplayAndPause(White, Black, 'press <enter>/<return> to continue')
  end else pause := False;
  GDVars.currentColumn := 38;
  TextRend.DisplayMessageWindow(1, 17, 38, 22, White, Black, pause, msg);
  CharHlp.InflictDamage(cr, dmg);
  TextRend.ClearRect(17, 1, 38, 15);
  CharHlp.DisplayParty(GDVars.currentCharacter)
end;

procedure UpdateEclDisplay;
begin
  GDVars.mapState.event := View3D.GetMapEvent(GDVars.mapState.x, GDVars.mapState.y);
  if (GDVars.eclGraphics <> 0) or (GDVars.spriteShown <> 0) or (GDVars.wallColorsChanged <> 0) or
      GDVars.partyMoved or GDVars.skyChanged then begin
    FillChar(GDVars.monsterFlags, SizeOf(GDVars.monsterFlags), 0);
    GDVars.forceMapRedraw := 1;
    MapView.DisplayMapView;
    CharHlp.PrintMiscInfo;
    GDVars.skyChanged := False;
    GDVars.wallColorsChanged := 0;
    GDVars.partyMoved := False;
    GDVars.eclGraphics := 0;
    GDVars.spriteShown := 0;
    GDVars.mapState.wallAhead := View3D.GetWallType(GDVars.mapState.x, GDVars.mapState.y,
                                                      GDVars.mapState.facing)
  end
end;

procedure NoopEclMenu;
begin
end;
begin
end.
