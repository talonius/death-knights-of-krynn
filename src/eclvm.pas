{ EclVm -- the ECL script interpreter: one handler per opcode, the dispatcher, running a script from one of its entry
  points, and the game loop that runs the area's scripts around each move. }
{$F+,O+,S-,R-,V-,B-,I-}
unit EclVm;
interface

{ The game, for FixMain: loads the zone's script (the start script for a new game, or a demo's), runs its main entry,
  then repeats the movement menu, camp or a search turn, the before-move entry, the step and the after-move entry,
  following NEWECL into new scripts; it restarts on restartLoop and, when the party is defeated or the demo ends,
  removes the party and returns. }
procedure GameLoop;

{ Runs the loaded script until a command stops it, the party is defeated or the script is aborted.
  @param(entry The address to start at.) }
procedure CallEclScript(entry: Word);
implementation
uses C_Ifc, C_Side, C_Stat, GDConsts, GDVars, Types, EclMenu, SaveLoad, CharHlp, TextRend, FxEngine,
  Portrait, MapView, MapCurs, Music, MenuCore, Crt, Mouse, Explore, MapTiles, Border, GameTime, Vault, View3D, Shop,
  Temple, PostCbt, Combat, Camp, CharGen, ViewChar;
type
  TString50 = String[50];
const PARTY_GAINS_TEXT = 'Congratulations the party gains experience!';
      GAINS_PREFIX = 'Congratulations ';
      GAINS_SUFFIX = ' gains experience!';
      JOURNAL_ENTRY_PREFIX = 'This is recorded as journal entry ';
      WHAT_DO_YOU_DO_TEXT = 'what do you do?';
      PRESS_BUTTON_TEXT = 'PRESS BUTTON OR RETURN TO CONTINUE.';
      PRESS_RETURN_TEXT = 'PRESS <ENTER>/<RETURN> TO CONTINUE';
      PARTY_KILLED_TEXT = 'The entire party is killed!';
      PRESS_ENTER_TEXT = 'press <enter>/<return> to continue';

{ EXIT, opcode $00: ends the script. Redraws the view frame if the copy protection showed, restores the saved current
  character, clears the monster flags and the graphics flag, stops the interpreter, empties the gosub stack and puts the
  text cursor back at row 17, column 1. }
procedure EclExit;
begin
  if GDVars.protectionShown <> 0 then Border.DrawViewFrame;
  if GDVars.restoreCharacter <> 0 then begin
    GDVars.currentCharacter := GDVars.savedCharacter;
    GDVars.restoreCharacter := 0
  end;
  FillChar(GDVars.monsterFlags, SizeOf(GDVars.monsterFlags), 0);
  GDVars.eclGraphics := 0;
  GDVars.protectionShown := 0;
  GDVars.eclStop := 1;
  Inc(GDVars.eclIp);
  while GDVars.eclStack <> nil do begin
    GDVars.eclStackPrev := GDVars.eclStack^.next;
    FreeMem(GDVars.eclStack, SizeOf(Types.TEclStack));
    GDVars.eclStack := GDVars.eclStackPrev
  end;
  GDVars.currentRow := 17;
  GDVars.currentColumn := 1;
  GDVars.boxCleared := 0
end;

{ GOTO, opcode $01: jumps to the address in its argument. }
procedure EclGoto;
begin
  EclMenu.LoadEclVars(1);
  GDVars.eclIp := EclMenu.CombineBytesToWord(GDVars.varLo[1], GDVars.varHi[1])
end;

{ GOSUB, opcode $02: pushes the return address and jumps to the address in its argument. }
procedure EclGosubCmd;
begin
  EclMenu.LoadEclVars(1);
  EclMenu.EclGosub(1)
end;

{ COMPARE, opcode $03: compares its two arguments, as strings when either is a string type ($80 and up), else as
  integers, and sets the comparison flags. }
procedure EclCompare;
var
  valueA: Word;
  valueB: Word;
  textA: String[255];
  textB: String[255];
begin
  EclMenu.LoadEclVars(2);
  if (GDVars.varTypes[1] >= $80) or (GDVars.varTypes[2] >= $80) then begin
    textA := GDVars.gbStrings[1];
    textB := GDVars.gbStrings[2];
    EclMenu.EclCompareStr(textA, textB)
  end else begin
    valueA := EclMenu.GetEclVar(1);
    valueB := EclMenu.GetEclVar(2);
    EclMenu.EclCompareInt(valueA, valueB)
  end
end;

{ ADD, SUBTRACT, DIVIDE and MULTIPLY, opcodes $04..$07: combines its first two arguments and stores the result at the
  GBVM address in its third. SUBTRACT takes the first from the second; DIVIDE leaves the remainder in the zone's
  division remainder. }
procedure EclArithmetic;
var address: Word;
    values: array[1..2] of Word;
    index: ShortInt;
    answer: Word;
begin
  EclMenu.LoadEclVars(3);
  for index := 1 to 2 do
    values[index] := EclMenu.GetEclVar(index);
  address := EclMenu.CombineBytesToWord(GDVars.varLo[3], GDVars.varHi[3]);
  case GDVars.curOpcode of
    4: answer := values[1] + values[2];
    5: answer := values[2] - values[1];
    6: begin
        answer := values[1] div values[2];
        GDVars.zone1^.divRemainder[GDConsts.divRemainderIndex + $7C00] := values[1] mod values[2]
      end;
    7: answer := values[1] * values[2]
  end;
  EclMenu.WriteGbvm(address, answer, GDVars.varTypes[3])
end;

{ RANDOM, opcode $08: stores a random number from 0 to its first argument (0 to 254 when that is 255) at the address in
  its second. }
procedure EclRandom;
var range: Byte;
    randomValue: Byte;
    address: Word;
begin
  EclMenu.LoadEclVars(2);
  range := EclMenu.GetEclVar(1);
  if range < 255 then Inc(range);
  address := EclMenu.CombineBytesToWord(GDVars.varLo[2], GDVars.varHi[2]);
  randomValue := Trunc(Random(range));
  EclMenu.WriteGbvm(address, randomValue, GDVars.varTypes[2])
end;

{ SAVE, opcode $09: stores its first argument, a number or a string (type bit 7 set), at the address in its second. }
procedure EclSave;
var value: Word;
    address: Word;
begin
  EclMenu.LoadEclVars(2);
  address := EclMenu.CombineBytesToWord(GDVars.varLo[2], GDVars.varHi[2]);
  if GDVars.varTypes[1] < $80 then begin
    value := EclMenu.GetEclVar(1);
    EclMenu.WriteGbvm(address, value, GDVars.varTypes[2])
  end else
    EclMenu.WriteGbvmString(address, GDVars.gbStrings[1])
end;

{ LOAD CHARACTER, opcode $0A: makes the party member at the position in the low 7 bits of its argument current, or sets
  the character-not-found flag when there is none. With bit 7 set and both removal flags raised, that member is removed
  from the party and the party redrawn. }
procedure EclLoadCharacter;
var cursor: Types.PCharacter;
    { Unused in this version; see the other implementations of this routine. }
    savedIndex: Byte;
    index: Byte;
    steps: Byte;
    refresh: Byte;
begin
  GDVars.restoreCharacter := 1;
  EclMenu.LoadEclVars(1);
  steps := 0;
  index := EclMenu.GetEclVar(1);
  cursor := GDVars.partyHead;
  refresh := index and $80;
  index := index and $7F;
  if index > 0 then
    while (steps < index) and (cursor <> nil) do begin
      cursor := cursor^.next;
      Inc(steps)
    end;
  if cursor <> nil then begin
    GDVars.currentCharacter := cursor;
    GDVars.characterNotFound := 0
  end else
    GDVars.characterNotFound := 1;
  if (refresh <> 0) and (GDVars.statusCellWritten <> 0) and (GDVars.nameCellWritten <> 0) then begin
    if GDVars.savedCharacter = GDVars.currentCharacter then GDVars.restoreCharacter := 0;
    CharGen.RemoveCreature(False, True);
    CharHlp.DisplayParty(GDVars.currentCharacter);
    GDVars.statusCellWritten := 0;
    GDVars.nameCellWritten := 0
  end
end;

{ SETUP MONSTER, opcode $0C: takes the monster's sprite, its greatest distance, its picture and the combat direction
  flags from its four arguments, and shows the monster at the nearer of that distance and the clear distance ahead. }
procedure EclSetupMonster;
var
  { Unused in this version; see the other implementations of this routine. }
  distance: Word;
begin
  EclMenu.LoadEclVars(4);
  GDVars.monsterSpriteId := EclMenu.GetEclVar(1);
  GDVars.zone1^.monsterMaxDist[GDConsts.monsterMaxDistIndex + $7C00] := EclMenu.GetEclVar(2);
  GDVars.monsterPictureId := EclMenu.GetEclVar(3);
  GDVars.combatDirectionFlags := EclMenu.GetEclVar(4);
  GDVars.zone1^.monsterDist[GDConsts.monsterDistIndex + $7C00] := EclMenu.MaxMonsterDist(GDVars.mapState.x,
                                                                                           GDVars.mapState.y,
                                                                                           GDVars.mapState.facing);
  if GDVars.zone1^.monsterMaxDist[GDConsts.monsterMaxDistIndex +
                                    $7C00] < GDVars.zone1^.monsterDist[GDConsts.monsterDistIndex + $7C00] then
    GDVars.zone1^.monsterDist[GDConsts.monsterDistIndex +
                                $7C00] := GDVars.zone1^.monsterMaxDist[GDConsts.monsterMaxDistIndex + $7C00];
  EclMenu.DisplayMonster(GDVars.monsterSpriteId, GDVars.monsterPictureId,
                         GDVars.zone1^.monsterDist[GDConsts.monsterDistIndex + $7C00], GDVars.monsterFlags)
end;

{ LOAD MONSTER, opcode $0B: adds the monster its first argument names to the party, its hit points scaled by the zone's
  difficulty when it is an enemy, with as many copies as its second argument asks (at least one, and at most 63 monsters
  in all), each with its own copies of the spells, items and effects. Its third argument picks the combat icon, loaded
  into the next icon slot. }
procedure EclLoadMonster;
var monsterId: Byte;
    count: Byte;
    pictureId: Byte;
    copies: Byte;
    tail: Types.PCharacter;
    clone: Types.PCharacter;
    creature: Types.PCharacter;
    saved: Types.PCharacter;
    template: Types.TCharacter;
    pictureName: String[12];
    itemsHead: Types.PItem;
    itemPrevious: Types.PItem;
    itemsStart: Types.PItem;
    effectsHead: Types.PEffect;
    effectPrevious: Types.PEffect;
    effectsStart: Types.PEffect;
    spellBlock: Types.PSpellBlock;
begin
  saved := GDVars.currentCharacter;
  copies := 1;
  EclMenu.LoadEclVars(3);
  if GDVars.loadedMonsterCount < 63 then begin
    tail := nil;
    clone := nil;
    monsterId := EclMenu.GetEclVar(1);
    EclMenu.InitCreature(monsterId, creature, itemsHead, effectsHead, spellBlock);
    if (creature^.side = C_Side.ENEMY) and (GDVars.zone0^.difficulty > 0) and
        (GDVars.zone0^.difficulty < 6) then begin
      creature^.hitPoints := creature^.hitPoints * (GDVars.zone0^.difficulty + 1) div 4;
      creature^.maxHitPoints := creature^.maxHitPoints * (GDVars.zone0^.difficulty + 1) div 4;
      if (creature^.hitPoints = 0) or (creature^.maxHitPoints = 0) then begin
        creature^.hitPoints := 1;
        creature^.maxHitPoints := 1
      end
    end;
    if creature^.levelUndead <> 0 then
      Inc(GDVars.undeadCount);
    template := creature^;
    itemsStart := itemsHead;
    effectsStart := effectsHead;
    count := EclMenu.GetEclVar(2);
    if count <= 0 then count := 1;
    pictureId := EclMenu.GetEclVar(3);
    tail := GDVars.partyHead;
    pictureName := 'CPIC';
    MapTiles.LoadIconAnim(pictureName, pictureId, GDVars.iconAnimation);
    while tail^.next <> nil do
      tail := tail^.next;
    tail^.next := creature;
    tail := tail^.next;
    { a creature's orderNumber is its icon slot }
    tail^.orderNumber := GDVars.iconAnimation;
    tail^.next := nil;
    Inc(GDVars.loadedMonsterCount);
    Inc(copies);
    while (copies <= count) and (GDVars.loadedMonsterCount < 63) do begin
      GetMem(clone, SizeOf(Types.TCharacter));
      tail^.next := clone;
      tail := tail^.next;
      tail^ := template;
      tail^.orderNumber := GDVars.iconAnimation;
      tail^.next := nil;
      tail^.effects := nil;
      tail^.items := nil;
      tail^.spells := nil;
      Inc(copies);
      Inc(GDVars.loadedMonsterCount);
      if spellBlock <> nil then begin
        GetMem(tail^.spells, SizeOf(Types.TSpellBlock));
        tail^.spells^ := spellBlock^
      end;
      while itemsHead <> nil do begin
        if tail^.items = nil then begin
          GetMem(tail^.items, SizeOf(Types.TItem));
          tail^.items^ := itemsHead^;
          tail^.items^.next := nil
        end else begin
          itemPrevious := tail^.items;
          GetMem(tail^.items, SizeOf(Types.TItem));
          tail^.items^ := itemsHead^;
          tail^.items^.next := itemPrevious
        end;
        itemsHead := itemsHead^.next
      end;
      itemsHead := itemsStart;
      while effectsHead <> nil do begin
        if tail^.effects = nil then begin
          GetMem(tail^.effects, SizeOf(Types.TEffect));
          tail^.effects^ := effectsHead^;
          tail^.effects^.next := nil
        end else begin
          effectPrevious := tail^.effects;
          GetMem(tail^.effects, SizeOf(Types.TEffect));
          tail^.effects^ := effectsHead^;
          tail^.effects^.next := effectPrevious
        end;
        effectsHead := effectsHead^.next
      end;
      effectsHead := effectsStart
    end;
    Inc(GDVars.iconAnimation);
    GDVars.monstersLoaded := 1;
    GDVars.currentCharacter := saved
  end
end;

{ APPROACH, opcode $0D: brings the monster one step nearer and redraws it, unless it is already adjacent. }
procedure EclApproach;
begin
  if GDVars.zone1^.monsterDist[GDConsts.monsterDistIndex + $7C00] > 0 then begin
    Dec(GDVars.zone1^.monsterDist[GDConsts.monsterDistIndex + $7C00]);
    EclMenu.DisplayMonster(GDVars.monsterSpriteId, GDVars.monsterPictureId,
                           GDVars.zone1^.monsterDist[GDConsts.monsterDistIndex + $7C00],
                           GDVars.monsterFlags)
  end;
  Inc(GDVars.eclIp)
end;

{ PICTURE, opcode $0E: shows a picture: 112 and above a big picture (112 being the overland map, with the party marker),
  others a PIC animation's first frame in the picture box. Picture 255 instead redraws the area view when a picture or
  sprite is up and clears the monster flags. }
procedure EclPicture;
var pictureId: Byte;
begin
  EclMenu.LoadEclVars(1);
  pictureId := EclMenu.GetEclVar(1);
  if pictureId <> 255 then begin
    GDVars.monsterFlags[1] := True;
    GDVars.eclGraphics := 1;
    if pictureId >= 112 then begin
      Portrait.LoadBigPic(pictureId);
      Portrait.DisplayBigPic;
      if pictureId = 112 then
        MapCurs.DrawCursor
      else
        GDVars.bigPictureShown := 1;
      GDVars.forceMapRedraw := 0
    end else begin
      Portrait.LoadAnimation('PIC', pictureId, GDConsts.pictureMode, GDVars.portraitAnimation);
      Portrait.DisplayImageBuf(3, 3, True, GDVars.portraitAnimation.frames[1].pic)
    end
  end else begin
    if (((GDVars.previousInterfaceState <> C_Ifc.VIEW_3D) or (GDVars.interfaceState = C_Ifc.VIEW_3D)) and
        ((GDVars.eclGraphics <> 0) or (GDVars.spriteShown <> 0))) then begin
      GDVars.forceMapRedraw := 1;
      MapView.DisplayMapView;
      GDVars.eclGraphics := 0;
      GDVars.spriteShown := 0
    end;
    GDVars.monsterFlags[0] := False;
    GDVars.monsterFlags[1] := False
  end
end;

{ INPUT NUMBER, opcode $0F: reads a number and stores it at the GBVM address in its second argument. }
procedure EclInputNumber;
var prompt: String[1];
    value: Word;
    address: Word;
begin
  EclMenu.LoadEclVars(2);
  prompt[0] := #0;
  address := EclMenu.CombineBytesToWord(GDVars.varLo[2], GDVars.varHi[2]);
  value := TextRend.ReadNumber(prompt, LightGreen, Black);
  EclMenu.WriteGbvm(address, value, GDVars.varTypes[2])
end;

{ INPUT STRING, opcode $10: reads up to 40 characters, a space when nothing is typed, and stores them at the GBVM
  address in its second argument. }
procedure EclInputString;
var prompt: String[1];
    address: Word;
    reply: String[255];
begin
  EclMenu.LoadEclVars(2);
  prompt[0] := #0;
  address := EclMenu.CombineBytesToWord(GDVars.varLo[2], GDVars.varHi[2]);
  reply := TextRend.ReadString(prompt, LightGreen, Black, 40);
  if reply = '' then reply := ' ';
  EclMenu.WriteGbvmString(address, reply)
end;

{ PRINT and PRINTCLEAR, opcodes $11 and $12: shows its argument, a number or a string, in the message window; PRINTCLEAR
  first clears the window and starts at its top. }
procedure EclPrint;
begin
  EclMenu.LoadEclVars(1);
  GDVars.bottomClear := 0;
  GDVars.slowText := 1;
  if GDVars.varTypes[1] < $80 then
    GDVars.gbStrings[1] := CharHlp.WordToString(EclMenu.GetEclVar(1));
  if GDVars.curOpcode = $11 then
    TextRend.DisplayMessageWindow(1, 17, 38, 22, LightGreen, Black, False, GDVars.gbStrings[1])
  else begin
    GDVars.currentRow := 17;
    GDVars.currentColumn := 1;
    TextRend.DisplayMessageWindow(1, 17, 38, 22, LightGreen, Black, True, GDVars.gbStrings[1])
  end;
  GDVars.slowText := 0
end;

{ RETURN, opcode $13: pops the gosub stack and returns to its address, or ends the script like EXIT when the stack is
  empty. }
procedure EclReturn;
begin
  Inc(GDVars.eclIp);
  if GDVars.eclStack <> nil then begin
    GDVars.eclIp := GDVars.eclStack^.addr;
    GDVars.eclStackPrev := GDVars.eclStack^.next;
    FreeMem(GDVars.eclStack, SizeOf(Types.TEclStack));
    GDVars.eclStack := GDVars.eclStackPrev
  end else
    EclVm.EclExit
end;

{ COMPARE AND, opcode $14: sets the equal flag when both pairs of its four arguments are equal, the not-equal flag
  otherwise. Note: with numbers in the first pair and strings in the second, the second test compares the first pair's
  strings. }
procedure EclCompareAnd;
var
  first: Boolean;
  second: Boolean;
begin
  FillChar(GDVars.cmpFlags, SizeOf(GDVars.cmpFlags), 0);
  EclMenu.LoadEclVars(4);
  if GDVars.varTypes[1] >= $80 then begin
    first := GDVars.gbStrings[1] = GDVars.gbStrings[2];
    if GDVars.varTypes[3] >= $80 then
      second := GDVars.gbStrings[3] = GDVars.gbStrings[4]
    else
      second := EclMenu.GetEclVar(3) = EclMenu.GetEclVar(4)
  end else begin
    first := EclMenu.GetEclVar(1) = EclMenu.GetEclVar(2);
    if GDVars.varTypes[3] >= $80 then
      second := GDVars.gbStrings[1] = GDVars.gbStrings[2]
    else
      second := EclMenu.GetEclVar(3) = EclMenu.GetEclVar(4)
  end;
  if first and second then
    GDVars.cmpFlags[0] := True
  else
    GDVars.cmpFlags[1] := True
end;

{ IF, opcodes $16..$1B (=, <>, <, >, <=, >=): skips the next command unless its comparison flag is set. }
procedure EclIf;
begin
  Inc(GDVars.eclIp);
  case GDVars.curOpcode of
    $16: if GDVars.cmpFlags[0] = False then EclMenu.SkipEclCmd;
    $17: if GDVars.cmpFlags[1] = False then EclMenu.SkipEclCmd;
    $18: if GDVars.cmpFlags[2] = False then EclMenu.SkipEclCmd;
    $19: if GDVars.cmpFlags[3] = False then EclMenu.SkipEclCmd;
    $1A: if GDVars.cmpFlags[4] = False then EclMenu.SkipEclCmd;
    $1B: if GDVars.cmpFlags[5] = False then EclMenu.SkipEclCmd
  end
end;

{ NEWECL, opcode $20: loads the script its argument names, remembering the current one in the zone, and stops the
  interpreter so the game loop starts the new script. }
procedure EclNewEcl;
var scriptId: Byte;
begin
  EclMenu.LoadEclVars(1);
  GDVars.zone0^.scriptId := GDVars.currentScriptId;
  scriptId := EclMenu.GetEclVar(1);
  GDVars.currentScriptId := scriptId;
  EclMenu.LoadEclScript(scriptId);
  EclMenu.EclInit;
  GDVars.eclStop := 1;
  GDVars.newEclFlag := 1;
  FillChar(GDVars.monsterFlags, SizeOf(GDVars.monsterFlags), 0)
end;

{ LOAD FILES and LOAD PIECES, opcodes $21 and $37. LOAD FILES loads the 3D map its first argument names (not 127 or 255,
  and only in a dungeon); LOAD PIECES loads the wall sets its three arguments name into their slots (127 loads the
  overland set, 255 empties a slot), slots 0 and 3 alone when both of the zone's target gates are set. Once both have
  run after the overland map, the view frame and the party are redrawn. }
procedure EclLoadFiles;
var fileIds: array[1..3] of Byte;
    index: Byte;
begin
  EclMenu.LoadEclVars(3);
  GDVars.filesLoaded := 1;
  for index := 1 to 3 do
    fileIds[index] := EclMenu.GetEclVar(index);
  if GDVars.curOpcode = $21 then begin
    GDVars.mapLoaded := 1;
    if (fileIds[1] <> 255) and (fileIds[1] <> 127) and (GDVars.zone0^.inDungeon <> 0) then begin
      GDVars.zone0^.geoMap := fileIds[1];
      View3D.Load3DMap(fileIds[1]);
      GDVars.zone1^.moveLocked[GDConsts.moveLockedIndex + $7C00] := 0
    end
  end else begin
    GDVars.piecesLoaded := 1;
    if fileIds[1] = 127 then
      View3D.LoadWallSet(0, 1)
    else if (GDVars.zone0^.targetGateA <> 0) and (GDVars.zone0^.targetGateB <> 0) then begin
      if fileIds[1] <> 255 then
        View3D.LoadWallSet(fileIds[1], 0)
      else begin
          GDVars.loadedWallSets[0].blockId := 65535;
          GDVars.loadedWallSets[0].slot := 65535
        end;
      if (fileIds[3] <> 255) and (fileIds[3] <> 127) then
        View3D.LoadWallSet(fileIds[3], 3)
      else begin
          GDVars.loadedWallSets[3].blockId := 65535;
          GDVars.loadedWallSets[3].slot := 65535
        end
    end else begin
      for index := 1 to 3 do
        if fileIds[index] <> 255 then
          View3D.LoadWallSet(fileIds[index], index)
        else begin
            GDVars.loadedWallSets[index].blockId := 65535;
            GDVars.loadedWallSets[index].slot := 65535
          end
    end
  end;
  if (GDVars.piecesLoaded <> 0) and (GDVars.mapLoaded <> 0) and
      (GDVars.previousInterfaceState = C_Ifc.OVERLAND) then begin
    if (GDVars.interfaceState <> C_Ifc.OVERLAND) and (GDVars.noncombatRedrawState <> 0) then begin
      Border.DrawViewFrame;
      CharHlp.DisplayParty(GDVars.currentCharacter);
      CharHlp.PrintMiscInfo
    end;
    GDVars.noncombatRedrawState := 0
  end
end;

{ AND and OR, opcodes $2F and $30: combines its first two arguments bitwise, truncates the result to a byte, sets the
  comparison flags as for COMPARE of 0 with the result, and stores it at the address in its third. }
procedure EclAndOr;
var address: Word;
    valueB: Word;
    valueA: Word;
    result: Byte;
begin
  EclMenu.LoadEclVars(3);
  valueA := EclMenu.GetEclVar(1);
  valueB := EclMenu.GetEclVar(2);
  address := EclMenu.CombineBytesToWord(GDVars.varLo[3], GDVars.varHi[3]);
  if GDVars.curOpcode = $2F then
    result := valueA and valueB
  else
    result := valueA or valueB;
  EclMenu.EclCompareInt(0, result);
  EclMenu.WriteGbvm(address, result, GDVars.varTypes[3])
end;

{ GETTABLE, opcode $2A: reads the GBVM entry at its first argument's address plus its second and stores it at the
  address in its third. }
procedure EclGetTable;
var tableAddress: Word;
    address: Word;
    entryAddress: Word;
    value: Word;
    offset: Byte;
begin
  EclMenu.LoadEclVars(3);
  tableAddress := EclMenu.CombineBytesToWord(GDVars.varLo[1], GDVars.varHi[1]);
  offset := EclMenu.GetEclVar(2);
  address := EclMenu.CombineBytesToWord(GDVars.varLo[3], GDVars.varHi[3]);
  entryAddress := offset + tableAddress;
  value := EclMenu.ReadGbvm(entryAddress, GDVars.varTypes[3]);
  EclMenu.WriteGbvm(address, value, GDVars.varTypes[3])
end;

{ SAVETABLE, opcode $35: stores its first argument at the GBVM entry at its second argument's address plus its third. }
procedure EclSaveTable;
var offset: Word;
    tableAddress: Word;
    value: Word;
    entryAddress: Word;
begin
  EclMenu.LoadEclVars(3);
  value := EclMenu.GetEclVar(1);
  tableAddress := EclMenu.CombineBytesToWord(GDVars.varLo[2], GDVars.varHi[2]);
  offset := EclMenu.GetEclVar(3);
  entryAddress := tableAddress + offset;
  EclMenu.WriteGbvm(entryAddress, value, GDVars.varTypes[1])
end;

{ VERTICAL MENU, opcode $15: shows its message, then a vertical menu of as many strings as its third argument says, and
  stores the choice at the GBVM address in its first. }
procedure EclVMenu;
var
  count: Byte;
  index: Byte;
  message: String;
  cursor: Pointer;
  saved: Pointer;
  { Unused in this version; see the other implementations of this routine. }
  menuIndex: Byte;
  zeroLength: Byte;
  choice: Word;
  redraw: Byte;
  address: Word;
  valueType: Byte;
  noQuery: Types.TString40 absolute zeroLength;
  noMenu: String absolute zeroLength;
  { the nodes as EclVerticalMenu reads them }
  menuList: Types.PItem absolute cursor;
  choiceIndex: Integer absolute choice;
  nodeList: Types.PMenuRow absolute cursor;
begin
  GDVars.selectedChoice := 1;
  GDVars.bottomClear := 0;
  redraw := 1;
  zeroLength := 0;
  index := 1;
  EclMenu.LoadEclVars(3);
  address := EclMenu.CombineBytesToWord(GDVars.varLo[1], GDVars.varHi[1]);
  valueType := GDVars.varTypes[1];
  message := GDVars.gbStrings[1];
  count := EclMenu.GetEclVar(3);
  Dec(GDVars.eclIp);
  EclMenu.LoadEclVars(count);
  MenuCore.AllocStringList(count, nodeList);
  saved := cursor;
  GDVars.currentColumn := 1;
  GDVars.currentRow := 17;
  TextRend.DisplayMessageWindow(1, 17, 38, 22, LightGreen, Black, True, message);
  while nodeList <> nil do begin
    nodeList^.name := GDVars.gbStrings[index];
    nodeList^.heading := 0;
    nodeList := nodeList^.next;
    Inc(index)
  end;
  cursor := saved;
  choice := 0;
  EclMenu.EclVerticalMenu(noQuery, noMenu, LightMagenta, LightGreen, White, 1, GDVars.currentRow + 1, 38, 22,
                          menuList, 0, redraw, choiceIndex, menuList);
  EclMenu.WriteGbvm(address, choice, valueType);
  MenuCore.FreeMenuRows(nodeList);
  TextRend.ClearRect(1, 17, 38, 22)
end;

{ HORIZONTAL MENU, opcode $2B, and $31 with a prompt: shows a horizontal menu of as many strings as its second argument
  says and stores the choice at the GBVM address in its first. A single choice is accepted with Enter, and one reading
  'PRESS BUTTON OR RETURN TO CONTINUE.' becomes 'PRESS <ENTER>/<RETURN> TO CONTINUE'.
  @param(withPrompt Non-zero to show 'what do you do?' first.) }
procedure EclHMenu(withPrompt: Byte);
var
  count: Byte;
  choice: Byte;
  index: Byte;
  { Unused in this version; see the other implementations of this routine. }
  menuIndex: Byte;
  zeroLength: Byte;
  menu: TString50;
  address: Word;
  enterOkByte: Byte;
  animateByte: Byte;
  highlightColor: Byte;
  menuColor: Byte;
  valueType: Byte;
  noQuery: Types.TString40 absolute zeroLength;
  menuString: String absolute menu;
  enterOk: Boolean absolute enterOkByte;
  animate: Boolean absolute animateByte;
begin
  if withPrompt <> 0 then
    TextRend.DisplayMessageWindow(1, 17, 38, 22, LightGreen, Black, False, EclVm.WHAT_DO_YOU_DO_TEXT);
  GDVars.selectedChoice := 1;
  zeroLength := 0;
  menu := '';
  EclMenu.LoadEclVars(2);
  address := EclMenu.CombineBytesToWord(GDVars.varLo[1], GDVars.varHi[1]);
  valueType := GDVars.varTypes[1];
  count := EclMenu.GetEclVar(2);
  Dec(GDVars.eclIp);
  EclMenu.LoadEclVars(count);
  menu := '';
  if count = 1 then begin
    enterOkByte := 1;
    highlightColor := White;
    menuColor := White;
    if GDVars.gbStrings[1] = EclVm.PRESS_BUTTON_TEXT then
      GDVars.gbStrings[1] := EclVm.PRESS_RETURN_TEXT
  end else begin
    enterOkByte := 0;
    highlightColor := White;
    menuColor := LightGreen
  end;
  animateByte := GDVars.eclGraphics;
  for index := 1 to count - 1 do
    menu := menu + '~' + GDVars.gbStrings[index] + ' ';
  menu := menu + '~' + GDVars.gbStrings[count];
  choice := EclMenu.MenuHorizontalCharacterSelect(noQuery, menuString, LightMagenta, menuColor, highlightColor, enterOk,
                                                  animate);
  EclMenu.WriteGbvm(address, choice, valueType);
  TextRend.ClearRect(0, 24, 39, 24)
end;

{ CLEAR MONSTERS, opcode $1C: forgets the loaded monsters and undead, resets the icon slots to 8, and empties the pool
  and the treasure. }
procedure EclClearMonsters;
var next: Types.PItem;
    { Unused in this version; see the other implementations of this routine. }
    monsterIndex: Word;
begin
  Inc(GDVars.eclIp);
  GDVars.undeadCount := 0;
  GDVars.loadedMonsterCount := 0;
  GDVars.monstersLoaded := 0;
  GDVars.iconAnimation := 8;
  FillChar(GDVars.pooledMoney, SizeOf(GDVars.pooledMoney), 0);
  while GDVars.treasureItems <> nil do begin
    next := GDVars.treasureItems^.next;
    FreeMem(GDVars.treasureItems, SizeOf(Types.TItem));
    GDVars.treasureItems := next
  end
end;

{ Empty routine with no callers. }
procedure NoopEclVmA; begin end;

{ PARTY CHECK, opcode $1E: measures the party on the attribute its first argument names -- with none, whether anyone
  carries the effect in its second; otherwise charisma, one of the eight thief skills or current movement -- and stores
  the lowest, highest and average values and the found flag at the GBVM addresses in its other four arguments. Other
  attributes do nothing. }
procedure EclCheckParty;
var attribute: Integer;
    sum: Integer;
    effectId: Byte;
    cursor: Types.PCharacter;
    found: ShortInt;
    scratch: Types.PEffect;
    { declared together, so one FillChar clears all three }
    average: Byte;
    maxValue: Byte;
    minValue: Byte;
    minAddress: Word;
    maxAddress: Word;
    averageAddress: Word;
    foundAddress: Word;
    count: Byte;
    skillIndex: Byte;

  { Stores the lowest, highest, average and found values at their GBVM addresses. }
  procedure Write4Gbvm;
  begin
    EclMenu.WriteGbvm(minAddress, minValue, GDVars.varTypes[3]);
    EclMenu.WriteGbvm(maxAddress, maxValue, GDVars.varTypes[4]);
    EclMenu.WriteGbvm(averageAddress, average, GDVars.varTypes[5]);
    EclMenu.WriteGbvm(foundAddress, found, GDVars.varTypes[6])
  end;
begin
  EclMenu.LoadEclVars(6);
  cursor := GDVars.partyHead;
  found := 0;
  if GDVars.varTypes[1] = 1 then
    attribute := EclMenu.CombineBytesToWord(GDVars.varLo[1], GDVars.varHi[1])
  else
    attribute := EclMenu.GetEclVar(1);
  effectId := EclMenu.GetEclVar(2);
  minAddress := EclMenu.CombineBytesToWord(GDVars.varLo[3], GDVars.varHi[3]);
  maxAddress := EclMenu.CombineBytesToWord(GDVars.varLo[4], GDVars.varHi[4]);
  averageAddress := EclMenu.CombineBytesToWord(GDVars.varLo[5], GDVars.varHi[5]);
  foundAddress := EclMenu.CombineBytesToWord(GDVars.varLo[6], GDVars.varHi[6]);
  sum := 0;
  count := 0;
  minValue := 255;
  maxValue := 0;
  Dec(attribute, $7C00);
  case attribute of
    { no attribute: does anyone carry the effect }
    -$7C00: begin
      while (cursor <> nil) and (found = 0) do begin
        found := Ord(CharHlp.HasEffect(cursor, effectId, scratch));
        cursor := cursor^.next
      end;
      FillChar(minValue, 3, 0);
      Write4Gbvm
    end;
    { charisma, the last of the current stats }
    $19: begin
      while cursor <> nil do begin
        Inc(count);
        if cursor^.stats[C_Stat.CHARISMA].current > maxValue then maxValue := cursor^.stats[C_Stat.CHARISMA].current;
        if cursor^.stats[C_Stat.CHARISMA].current < minValue then minValue := cursor^.stats[C_Stat.CHARISMA].current;
        Inc(sum, cursor^.stats[C_Stat.CHARISMA].current);
        cursor := cursor^.next
      end;
      average := sum div count;
      Write4Gbvm
    end;
    { the eight thief skills, $7CA5..$7CAC }
    $A5..$AC: begin
      skillIndex := attribute - $A4;
      while cursor <> nil do begin
        Inc(count);
        if cursor^.thiefSkills[skillIndex] < minValue then
          minValue := cursor^.thiefSkills[skillIndex];
        if cursor^.thiefSkills[skillIndex] > maxValue then
          maxValue := cursor^.thiefSkills[skillIndex];
        Inc(sum, cursor^.thiefSkills[skillIndex]);
        cursor := cursor^.next
      end;
      average := sum div count;
      Write4Gbvm
    end;
    { current movement }
    $9F: begin
      while cursor <> nil do begin
        Inc(count);
        if cursor^.currentMovement < minValue then minValue := cursor^.currentMovement;
        if cursor^.currentMovement > maxValue then maxValue := cursor^.currentMovement;
        Inc(sum, cursor^.currentMovement);
        cursor := cursor^.next
      end;
      average := sum div count;
      Write4Gbvm
    end
  end
end;

{ Empty routine with no callers. }
procedure NoopEclVmB; begin end;

{ Empty routine with no callers. }
procedure NoopEclVmC; begin end;

{ COMBAT, opcode $24: with no monsters loaded and no duel, runs the vault, the shop or the temple when the zone asks for
  one, and otherwise settles the encounter; with monsters it runs the fight and settles it. Then it returns to the
  overland or 3D view, keeps the search bit alone, clears the monster flags and redraws the interface (not after a shop
  or temple overland). }
procedure EclCombat;
var wallDist: Word;
    redrawInterface: Byte;
    savedExtendedMode: Byte;
begin
  GDVars.bigPictureShown := 0;
  savedExtendedMode := GDVars.extendedMode;
  GDVars.extendedMode := 0;
  Inc(GDVars.eclIp);
  redrawInterface := 1;
  if (GDVars.monstersLoaded = 0) and (GDVars.duelFlag = 0) then begin
    if GDVars.zone0^.enterVault = 1 then begin
      GDVars.zone0^.enterVault := 0;
      Vault.PoolVault
    end else if GDVars.zone1^.enterShop = 1 then begin
      GDVars.zone1^.enterShop := 0;
      Shop.ShopMainMenu;
      if GDVars.zone0^.inDungeon = 0 then redrawInterface := 0
    end else if GDVars.zone1^.enterTemple[GDConsts.enterTempleIndex + $7C00] = 1 then begin
      GDVars.zone1^.enterTemple[GDConsts.enterTempleIndex + $7C00] := 0;
      Temple.TempleMainMenu;
      if GDVars.zone0^.inDungeon = 0 then redrawInterface := 0
    end else
      PostCbt.PostCombat
  end else begin
    wallDist := EclMenu.MaxMonsterDist(GDVars.mapState.x, GDVars.mapState.y, GDVars.mapState.facing);
    if GDVars.zone1^.monsterDist[GDConsts.monsterDistIndex + $7C00] > wallDist then
      GDVars.zone1^.monsterDist[GDConsts.monsterDistIndex + $7C00] := wallDist;
    Combat.CombatMain;
    PostCbt.PostCombat;
    if GDVars.zone0^.inDungeon = 0 then Portrait.LoadBigPic(112);
    GDVars.duelFlag := 0
  end;
  if GDVars.zone0^.inDungeon = 0 then GDVars.interfaceState := C_Ifc.OVERLAND
  else GDVars.interfaceState := C_Ifc.VIEW_3D;
  GDVars.zone1^.searchFlags[GDConsts.searchFlagsIndex +
                              $7C00] := GDVars.zone1^.searchFlags[GDConsts.searchFlagsIndex + $7C00] and $01;
  FillChar(GDVars.monsterFlags, SizeOf(GDVars.monsterFlags), 0);
  GDVars.eclGraphics := 0;
  if redrawInterface <> 0 then begin
    CharHlp.DisplayNoncombatInterface;
    if (GDVars.zone0^.inDungeon = 0) and (GDVars.partyDefeated = 0) and (GDVars.zone0^.wildOn = 1) then
      MapCurs.DrawCursor
  end;
  GDVars.extendedMode := savedExtendedMode
end;

{ ON GOTO and ON GOSUB, opcodes $25 and $26: jumps to, or calls, the address its first argument picks from the list
  whose length its second gives; an index past the list does nothing. }
procedure EclOnGoto;
var choice: Byte;
    count: Byte;
    { Unused in this version; see the other implementations of this routine. }
    target: Byte;
    index: Byte;
    found: Byte;
begin
  found := 0;
  EclMenu.LoadEclVars(2);
  choice := EclMenu.GetEclVar(1);
  count := EclMenu.GetEclVar(2);
  Dec(GDVars.eclIp);
  EclMenu.LoadEclVars(count);
  index := 0;
  while (index < count) and (found = 0) do begin
    if choice = index then begin
      if GDVars.curOpcode = $25 then
        GDVars.eclIp := EclMenu.CombineBytesToWord(GDVars.varLo[index + 1], GDVars.varHi[index + 1])
      else
        EclMenu.EclGosub(index + 1);
      found := 1
    end else
      Inc(index)
  end
end;

{ TREASURE, opcode $27: adds the steel, gems and jewelry in its first three arguments to the pool, and to the treasure
  the items whose template ids follow, as many as its fourth says (templates of type 255 are skipped). }
procedure EclTreasure;
var count: Byte;
    index: Byte;
    itemId: Byte;
    item: Types.TItem;
    previous: Types.PItem;
begin
  EclMenu.LoadEclVars(4);
  { steel, gems, jewelry }
  Inc(GDVars.pooledMoney[4], EclMenu.GetEclVar(1));
  Inc(GDVars.pooledMoney[5], EclMenu.GetEclVar(2));
  Inc(GDVars.pooledMoney[6], EclMenu.GetEclVar(3));
  count := EclMenu.GetEclVar(4);
  Dec(GDVars.eclIp);
  EclMenu.LoadEclVars(count);
  for index := 1 to count do begin
    itemId := EclMenu.GetEclVar(index);
    if GDVars.itemTemplates[itemId].itemType <> 255 then begin
      { the template is TItem from itemType on }
      Move(GDVars.itemTemplates[itemId], item.itemType,
           SizeOf(Types.TItemTemplate));
      item.next := nil;
      item.inUse := 0;
      if GDVars.treasureItems = nil then begin
        New(GDVars.treasureItems);
        GDVars.treasureItems^ := item
      end else begin
        previous := GDVars.treasureItems;
        New(GDVars.treasureItems);
        GDVars.treasureItems^ := item;
        GDVars.treasureItems^.next := previous
      end
    end
  end
end;

{ ROB, opcode $28: takes the percentage of money in its second argument and, with the chance in its third, items from
  the current character, or from every member when its first is non-zero. }
procedure EclRob;
var wholeParty: Byte;
    percentMoney: Byte;
    itemChance: Byte;
    cursor: Types.PCharacter;
    { Unused in this version; see the other implementations of this routine. }
    items: Types.PItem;
    keepFraction: Real;
begin
  EclMenu.LoadEclVars(3);
  wholeParty := EclMenu.GetEclVar(1);
  percentMoney := EclMenu.GetEclVar(2);
  keepFraction := (100 - percentMoney) / 100;
  itemChance := EclMenu.GetEclVar(3);
  if wholeParty = 0 then begin
    EclMenu.RobMoney(keepFraction, GDVars.currentCharacter);
    EclMenu.RobItems(itemChance, GDVars.currentCharacter)
  end else begin
    cursor := GDVars.partyHead;
    while cursor <> nil do begin
      items := cursor^.items;
      EclMenu.RobMoney(keepFraction, cursor);
      EclMenu.RobItems(itemChance, cursor);
      cursor := cursor^.next
    end
  end
end;

{ Offers the continue menu and waits. }
procedure EclContinuePrompt;
var
  { Unused in this version; see the other implementations of this routine. }
  choice: Byte;
begin
  Inc(GDVars.eclIp);
  choice := EclMenu.MenuHorizontalCharacterSelect('', GDConsts.pressToContinueMenu, LightMagenta, LightGreen, White,
                                                  True, Boolean(GDVars.eclGraphics));
  MenuCore.ClearBottomLine
end;

{ YES/NO, opcode $22: asks yes or no and sets the equal flag for yes, the not-equal flag for no. }
procedure EclYesNo;
var
  { Unused in this version; see the other implementations of this routine. }
  answer: Word;
begin
  Inc(GDVars.eclIp);
  FillChar(GDVars.cmpFlags, SizeOf(GDVars.cmpFlags), 0);
  if MenuCore.YesNoMenu(GDConsts.emptyQuery, GDConsts.yesKey) = GDConsts.yesKey then
    GDVars.cmpFlags[0] := True
  else
    GDVars.cmpFlags[1] := True
end;

{ Empty routine with no callers. }
procedure NoopEclVmD; begin end;

{ Empty routine with no callers. }
procedure NoopEclVmE; begin end;

{ FIND ITEM, opcode $32: sets the equal flag when a party member carries an item of the type in its argument, the
  not-equal flag otherwise. }
procedure EclFindItem;
var itemType: Byte;
    { Unused in this version; see the other implementations of this routine. }
    itemCount: Byte;
    cursor: Types.PCharacter;
    item: Types.PItem;
    found: Byte;
begin
  EclMenu.LoadEclVars(1);
  found := 0;
  itemType := EclMenu.GetEclVar(1);
  FillChar(GDVars.cmpFlags, SizeOf(GDVars.cmpFlags), 0);
  GDVars.cmpFlags[1] := True;
  cursor := GDVars.partyHead;
  while (cursor <> nil) and (found = 0) do begin
    item := cursor^.items;
    while (item <> nil) and (found = 0) do begin
      if itemType = item^.itemType then begin
        GDVars.cmpFlags[0] := True;
        GDVars.cmpFlags[1] := False;
        found := 1
      end;
      item := item^.next
    end;
    cursor := cursor^.next
  end
end;

{ DELAY, opcode $3A: waits 600 milliseconds. }
procedure EclDelay;
begin
  Inc(GDVars.eclIp);
  Delay(600)
end;

{ DAMAGE ($2E) <attack> <dice> <sides> <bonus> <value>: rolls dice x sides + bonus of damage. With attack bit $80 set,
  the low four bits of attack are the saving-throw modifier and the low three bits of value the save type: bit $40 hits
  the whole party (bit $20 with no save), otherwise one target, the current character when value bit $80 is set (save
  type value - 1, none at 0) or else a random member. A made save halves the damage when attack bit $10 is set and
  cancels it when it is not. With bit $80 clear, attack is a number of separate attacks on random members, each rolled
  to hit against value and each with fresh damage. If that leaves the whole party out of play, the party is lost. }
procedure EclDamage;
var
  attack: Byte;
  dice: Byte;
  sides: Byte;
  index: Byte;
  saveModifier: Byte;
  attackVar: Byte;
  bonus: Byte;
  partyPosition: Byte;
  saveType: Byte;
  inner: Byte;
  amount: Word;
  cursor: Types.PCharacter;
  scanCursor: Types.PCharacter;
  saved: Types.PCharacter;
  { Unused in this version; see the other implementations of this routine. }
  damageType: Byte;
  allTargets: Byte;
  halfOnSave: Byte;
begin
  saved := GDVars.currentCharacter;
  damageType := 0;
  allTargets := 0;
  cursor := GDVars.partyHead;
  EclMenu.LoadEclVars(5);
  attack := EclMenu.GetEclVar(1);
  dice := EclMenu.GetEclVar(2);
  sides := EclMenu.GetEclVar(3);
  bonus := EclMenu.GetEclVar(4);
  attackVar := EclMenu.GetEclVar(5);
  amount := FxEngine.RollDice(dice, sides) + bonus;
  halfOnSave := attack and $10;
  if (attack and $40) <> 0 then
    allTargets := 1
  else
    partyPosition := FxEngine.RollDice(1, GDVars.zone1^.partySize[$7F3E]);
  { a saving throw, not an attack roll }
  if (attack and $80) <> 0 then begin
    saveModifier := attack and $0F;
    saveType := attackVar and $07;
    if allTargets <> 0 then begin
      while cursor <> nil do begin
        if (attack and $20) <> 0 then
          EclMenu.EclInflictDamage(amount, cursor)
        else if not FxEngine.RollSavingThrow(cursor, saveType, saveModifier) then
          EclMenu.EclInflictDamage(amount, cursor)
        else if halfOnSave <> 0 then
          EclMenu.EclInflictDamage(amount div 2, cursor);
        cursor := cursor^.next
      end
    end else if (attackVar and $80) <> 0 then begin
      if (saveType = 0) or not FxEngine.RollSavingThrow(GDVars.currentCharacter, saveType - 1, saveModifier) then
        EclMenu.EclInflictDamage(amount, GDVars.currentCharacter)
      else if halfOnSave <> 0 then
        EclMenu.EclInflictDamage(amount div 2, GDVars.currentCharacter)
    end else begin
      for index := 2 to partyPosition do cursor := cursor^.next;
      if not FxEngine.RollSavingThrow(cursor, saveType, saveModifier) then
        EclMenu.EclInflictDamage(amount, cursor)
      else if halfOnSave <> 0 then
        EclMenu.EclInflictDamage(amount div 2, cursor)
    end
  end else begin
    for index := 1 to attack do begin
      cursor := GDVars.partyHead;
      partyPosition := FxEngine.RollDice(1, GDVars.zone1^.partySize[$7F3E]);
      inner := 1;
      while inner < partyPosition do begin
        cursor := cursor^.next;
        Inc(inner)
      end;
      if FxEngine.AttackRollNoAttacker(cursor, attackVar) then
        EclMenu.EclInflictDamage(amount, cursor);
      amount := FxEngine.RollDice(dice, sides) + bonus
    end
  end;
  scanCursor := GDVars.partyHead;
  GDVars.partyDefeated := 1;
  while scanCursor <> nil do begin
    if scanCursor^.enabled <> 0 then GDVars.partyDefeated := 0;
    scanCursor := scanCursor^.next
  end;
  if GDVars.partyDefeated <> 0 then begin
    Border.DrawWindowFrame(0);
    GDVars.currentColumn := 2;
    GDVars.currentRow := 2;
    TextRend.DisplayMessageWindow(1, 1, 38, 22, LightGreen, Black, True, EclVm.PARTY_KILLED_TEXT);
    Delay(3000)
  end;
  GDVars.currentCharacter := saved;
  TextRend.DisplayAndPause(White, Black, EclVm.PRESS_ENTER_TEXT)
end;

{ Empty routine with no callers. }
procedure NoopEclVmF; begin end;

{ CLOCK, opcode $34: advances the clock by its first argument in the unit its second names. }
procedure EclClock;
var
  amount: Byte;
  timeUnit: Byte;
begin
  EclMenu.LoadEclVars(2);
  amount := EclMenu.GetEclVar(1);
  timeUnit := EclMenu.GetEclVar(2);
  GameTime.AdvanceTime(amount, ShortInt(timeUnit))
end;

{ PRINT RETURN, opcode $33: moves the message cursor to the start of the next line and clears the print-return flag. }
procedure EclPrintReturn;
begin
  Inc(GDVars.eclIp);
  if GDVars.printReturnFlag <> 0 then begin
    GDVars.currentColumn := 1;
    Inc(GDVars.currentRow);
    GDVars.printReturnFlag := 0
  end else begin
    GDVars.currentColumn := 1;
    Inc(GDVars.currentRow)
  end
end;

{ CLEAR BOX, opcode $3D: redraws the view frame, the party and the picture box (not in a demo). }
procedure EclClearBox;
begin
  Inc(GDVars.eclIp);
  GDVars.bigPictureShown := 0;
  Border.DrawViewFrame;
  CharHlp.DisplayParty(GDVars.currentCharacter);
  CharHlp.PrintMiscInfo;
  if GDVars.demoMode = 0 then
    Portrait.DisplayImageBuf(3, 3, True, GDVars.portraitAnimation.frames[1].pic);
  CharHlp.PrintMiscInfo;
  GDVars.noncombatRedrawState := 0;
  GDVars.boxCleared := 1
end;

{ WHO, opcode $39: asks the player to pick a party member, with its argument as the prompt, and makes that member
  current. }
procedure EclWho;
var prompt: String[255];
    savedExtendedMode: Byte;
begin
  savedExtendedMode := GDVars.extendedMode;
  GDVars.extendedMode := 0;
  GDVars.characterNotFound := 0;
  EclMenu.LoadEclVars(1);
  TextRend.ClearRect(1, 17, 38, 22);
  prompt := GDVars.gbStrings[1];
  CharHlp.SelectChar(prompt, False, 0, Pointer(GDVars.currentCharacter));
  GDVars.extendedMode := savedExtendedMode
end;

{ ADD NPC, opcode $36: adds the monster its first argument names to the party as a non-player character whose morale is
  half its second argument. }
procedure EclAddNpc;
var
  { Unused in this version; see the other implementations of this routine. }
  npc: Pointer;
  monsterId: Byte;
  morale: Byte;
begin
  EclMenu.LoadEclVars(2);
  monsterId := EclMenu.GetEclVar(1);
  SaveLoad.AddCreatureToParty(monsterId);
  morale := EclMenu.GetEclVar(2);
  morale := Integer(morale) div 2;
  morale := morale or $80;
  GDVars.currentCharacter^.npc := morale;
  CharHlp.RecalcStats(GDVars.currentCharacter);
  CharHlp.DisplayParty(GDVars.currentCharacter)
end;

{ SPELL, opcode $3B: looks for an enabled member with the spell in its first argument memorized, and stores the spell's
  slot (255 when none has it) and the member's position at the GBVM addresses in its second and third. }
procedure EclSpell;
var spellId: Byte;
    index: Byte;
    characterCount: Byte;
    cursor: Types.PCharacter;
    found: Byte;
    limitReached: Byte;
    indexAddress: Word;
    countAddress: Word;
begin
  limitReached := 0;
  found := 0;
  EclMenu.LoadEclVars(3);
  spellId := EclMenu.GetEclVar(1);
  indexAddress := EclMenu.CombineBytesToWord(GDVars.varLo[2], GDVars.varHi[2]);
  countAddress := EclMenu.CombineBytesToWord(GDVars.varLo[3], GDVars.varHi[3]);
  index := 1;
  characterCount := 0;
  cursor := GDVars.partyHead;
  while (cursor <> nil) and (found = 0) do begin
    index := 0;
    if (cursor^.spells <> nil) and (cursor^.enabled <> 0) then begin
      repeat
        if cursor^.spells^.memorized[index] = spellId then
          found := 1
        else if index < 73 then
          Inc(index)
        else
          limitReached := 1
      until (limitReached <> 0) or (found <> 0)
    end;
    limitReached := 0;
    cursor := cursor^.next;
    if (cursor <> nil) and (found = 0) then Inc(characterCount)
  end;
  if found = 0 then index := 255;
  EclMenu.WriteGbvm(indexAddress, index, GDVars.varTypes[2]);
  EclMenu.WriteGbvm(countAddress, characterCount, GDVars.varTypes[3])
end;

{ CALL, opcode $2D: runs the engine routine its address selects: the display update, a step or fireball sound, the
  forward move, the wall check overland, or the next frame of the picture box's animation. }
procedure EclCall;
var address: Word;
    selector: Word;
begin
  EclMenu.LoadEclVars(1);
  address := EclMenu.CombineBytesToWord(GDVars.varLo[1], GDVars.varHi[1]);
  selector := address - $7FFF;
  case selector of
    { CALL $2DCB }
    $ADCC: EclMenu.UpdateEclDisplay;
    { CALL $B203 }
    $3204: case GDVars.callSoundMode of
      8: Music.SendSoundCommand(GDConsts.stepSound);
      10: Music.SendSoundCommand(GDConsts.fireballSound)
      else Music.SendSoundCommand(GDConsts.stepSound)
    end;
    { CALL $C01E }
    $401F: EclMenu.EclMoveForward;
    { CALL $C018 }
    $4019: if GDVars.zone0^.inDungeon = 0 then
      GDVars.mapState.wallAhead := View3D.GetWallType(GDVars.mapState.x, GDVars.mapState.y,
                                                        GDVars.mapState.facing);
    { CALL $6803: show the next animation frame }
    $E804: begin
      Mouse.HideMouse;
      Portrait.DisplayImageBuf(3, 3, True,
                               GDVars.portraitAnimation.frames[GDVars.portraitAnimation.currentFrame].pic);
      Mouse.ShowMouse;
      Inc(GDVars.portraitAnimation.currentFrame);
      if GDVars.portraitAnimation.currentFrame > GDVars.portraitAnimation.count then
        GDVars.portraitAnimation.currentFrame := 1;
      TextRend.PauseOnly
    end
  end
end;

{ Runs the before-camp script entry (entry point 3) and the camp menu; if the rest was interrupted, repaints the
  non-combat interface and runs the camp-interrupted entry (entry point 4). Then requests a map redraw, redraws the map
  view, clears the recently-saved flag, and, when not in a dungeon and the map pane is on, draws the map cursor. }
procedure EnterCamp;
var interrupted: Byte;
begin
  interrupted := 0;
  EclVm.CallEclScript(GDVars.eclEntryPoints.entryBeforeCamp);
  Camp.CampMainMenu(Boolean(interrupted));
  if interrupted <> 0 then begin
    CharHlp.DisplayNoncombatInterface;
    EclVm.CallEclScript(GDVars.eclEntryPoints.entryAfterCamp)
  end;
  GDVars.forceMapRedraw := 1;
  MapView.DisplayMapView;
  GDVars.recentlySaved := 0;
  if (GDVars.zone0^.inDungeon = 0) and (GDVars.zone0^.wildOn = 1) then
    MapCurs.DrawCursor
end;

{ PROGRAM, opcode $38: after restoring the saved current character, runs the party menu (program 0) or camp (program 9,
  which ends the script on the overland map). }
procedure EclProgram;
var programId: Byte;
    savedIp: Word;
    { Unused in this version; see the other implementations of this routine. }
    key: array[0..4] of Byte;
    savedExtendedMode: Byte;
begin
  savedExtendedMode := GDVars.extendedMode;
  GDVars.extendedMode := 0;
  if GDVars.restoreCharacter <> 0 then begin
    GDVars.currentCharacter := GDVars.savedCharacter;
    GDVars.restoreCharacter := 0
  end;
  EclMenu.LoadEclVars(1);
  programId := EclMenu.GetEclVar(1);
  case programId of
    { the party menu }
    0: begin
      CharGen.MainMenu;
      if (GDVars.pictureArchiveId <> 9) and (GDVars.zone0^.inDungeon = 0) and (GDVars.zone0^.wildOn = 1) and
          (GDVars.restartLoop = 0) then begin
        CharHlp.DisplayNoncombatInterface;
        MapCurs.DrawCursor
      end
    end;
    { camp }
    9: begin
      savedIp := GDVars.eclIp;
      EclVm.EnterCamp;
      GDVars.eclIp := savedIp;
      if GDVars.zone0^.wildOn = 1 then EclVm.EclExit
    end
  end;
  GDVars.extendedMode := savedExtendedMode
end;

{ Empty routine with no callers. }
procedure NoopEclVmG; begin end;

{ DUMP, opcode $3E: removes the current character from the party, keeps the character that becomes current as the saved
  character to restore, and redraws the party. }
procedure EclDump;
begin
  Inc(GDVars.eclIp);
  CharGen.RemoveCreature(False, True);
  GDVars.savedCharacter := GDVars.currentCharacter;
  CharHlp.DisplayParty(GDVars.currentCharacter)
end;

{ FIND SPECIAL, opcode $3F: clears the compare flags, then sets the equal flag when the current character has the effect
  in its argument, the not-equal flag otherwise. }
procedure EclFindSpecial;
var scratch: Types.PEffect;
    effectId: Byte;
begin
  FillChar(GDVars.cmpFlags, SizeOf(GDVars.cmpFlags), 0);
  EclMenu.LoadEclVars(1);
  effectId := EclMenu.GetEclVar(1);
  if Ord(CharHlp.HasEffect(GDVars.currentCharacter, effectId, scratch)) <> 0 then
    GDVars.cmpFlags[0] := True
  else
    GDVars.cmpFlags[1] := True
end;

{ DESTROY ITEMS, opcode $40: removes each item matching its argument from every party member, unreadying it first when
  it is readied, and recalculates each member; the current character is restored afterwards. }
procedure EclDestroyItems;
var itemType: Byte;
    cursor: Types.PCharacter;
    savedCurrent: Types.PCharacter;
    item: Types.PItem;
    nextItem: Types.PItem;
begin
  EclMenu.LoadEclVars(1);
  itemType := EclMenu.GetEclVar(1);
  savedCurrent := GDVars.currentCharacter;
  cursor := GDVars.partyHead;
  while cursor <> nil do begin
    item := cursor^.items;
    while item <> nil do begin
      nextItem := item^.next;
      if itemType = item^.itemType then begin
        GDVars.currentCharacter := cursor;
        if item^.equipped <> 0 then ViewChar.ToggleReadyItem(item);
        CharHlp.RemoveItem(cursor, item)
      end;
      item := nextItem
    end;
    CharHlp.RecalcStats(cursor);
    cursor := cursor^.next
  end;
  GDVars.currentCharacter := savedCurrent
end;

{ AWARD EXPERIENCE, opcode $41: gives the experience in its second argument, split over each one's classes, to every
  enabled member when its first is non-zero, otherwise to the current character, and announces it. Note: for the current
  character the enabled test reads the member pointer before it is set. }
procedure EclAwardExperience;
var amount: Word;
    wholeParty: Byte;
    cursor: Types.PCharacter;
    index: ShortInt;
    classCount: Byte;
    share: Word;
begin
  EclMenu.LoadEclVars(2);
  amount := EclMenu.GetEclVar(2);
  wholeParty := EclMenu.GetEclVar(1);
  GDVars.currentRow := 17;
  GDVars.currentColumn := 1;
  if wholeParty <> 0 then begin
    TextRend.DisplayMessageWindow(1, 17, 38, 22, LightGreen, Black, True, EclVm.PARTY_GAINS_TEXT);
    TextRend.PauseOnly;
    cursor := GDVars.partyHead;
    while cursor <> nil do begin
      if cursor^.enabled <> 0 then begin
        classCount := 0;
        for index := 0 to 7 do
          if cursor^.classLevels[index] > 0 then Inc(classCount);
        share := amount div classCount;
        Inc(cursor^.experience, share);
        cursor^.levelUpReady := Ord(CharHlp.CanLevelUp(cursor))
      end;
      cursor := cursor^.next
    end
  end else begin
    { tested before cursor is set, so it holds whatever was left there }
    if cursor^.enabled <> 0 then begin
      cursor := GDVars.currentCharacter;
      TextRend.DisplayMessageWindow(1, 17, 38, 22, LightGreen, Black, True,
                                    EclVm.GAINS_PREFIX + cursor^.name + EclVm.GAINS_SUFFIX);
      TextRend.PauseOnly;
      classCount := 0;
      for index := 0 to 7 do
        if cursor^.classLevels[index] > 0 then Inc(classCount);
      share := amount div classCount;
      Inc(cursor^.experience, share);
      cursor^.levelUpReady := Ord(CharHlp.CanLevelUp(cursor))
    end
  end
end;

{ Opcode $1F <number>: tells the party which journal entry to read, then waits for a key or button. }
procedure EclJournalEntry;
var message: String;
    { Unused in this version; see the other implementations of this routine. }
    choice: Byte;
    entry: Word;
begin
  EclMenu.LoadEclVars(1);
  entry := EclMenu.GetEclVar(1);
  GDVars.currentRow := 17;
  GDVars.currentColumn := 1;
  message := EclVm.JOURNAL_ENTRY_PREFIX + CharHlp.ByteToString(entry) + '.';
  TextRend.DisplayMessageWindow(1, 17, 38, 22, LightGreen, Black, True, message);
  choice := EclMenu.MenuHorizontalCharacterSelect('', GDConsts.pressToContinueMenu, LightMagenta, LightGreen, White,
                                                  True, Boolean(GDVars.eclGraphics));
  MenuCore.ClearBottomLine
end;

{ Opcode $23: clears the message window, updates the display and ends the script. }
procedure EclRedrawExit;
begin
  TextRend.ClearRect(1, 17, 38, 22);
  EclMenu.UpdateEclDisplay;
  EclVm.EclExit
end;

{ SOUND, opcode $2C: with bit 7 of its argument set, starts the music for the disk in the low 7 bits; cues 1..6 play
  their sound from the cue table, and anything else does nothing. }
procedure EclPlaySound;
var cue: Byte;
begin
  EclMenu.LoadEclVars(1);
  cue := EclMenu.GetEclVar(1);
  if cue > $7F then
    { bit 7: a music file, not a cue }
    Music.StartMusic(cue and $7F)
  else if (cue < 7) and (cue > 0) then
    Music.SendSoundCommand(GDConsts.soundCueTable[cue])
end;

{ NO OPERATION, opcode $29: steps past the command. }
procedure EclNoOperation;
begin
  Inc(GDVars.eclIp)
end;

{ SHOP, opcode $3C: fills the treasure with the stock list its argument picks (1..8, any other value meaning 1), each
  item identified, and opens the shop. }
procedure EclShop;
var stockList: Byte;
    itemId: Byte;
    item: Types.TItem;
    previous: Types.PItem;
    first: Byte;
    last: Byte;
    index: Byte;
begin
  EclMenu.LoadEclVars(1);
  while GDVars.treasureItems <> nil do begin
    previous := GDVars.treasureItems;
    GDVars.treasureItems := GDVars.treasureItems^.next;
    FreeMem(previous, SizeOf(Types.TItem))
  end;
  stockList := EclMenu.GetEclVar(1);
  if (stockList > 8) or (stockList < 1) then stockList := 1;
  first := GDConsts.shopStockStart[stockList];
  last := first + GDConsts.shopStockCount[stockList] - 1;
  for index := first to last do begin
    itemId := GDConsts.shopStockItems[index];
    if GDVars.itemTemplates[itemId].itemType <> 255 then begin
      Move(GDVars.itemTemplates[itemId], item.itemType, SizeOf(Types.TItemTemplate));
      { bits 0..2 hide the name parts: stock sells identified }
      item.unidentifiedMask := item.unidentifiedMask and $F8;
      item.next := nil;
      item.inUse := 0;
      if GDVars.treasureItems = nil then begin
        New(GDVars.treasureItems);
        GDVars.treasureItems^ := item
      end else begin
        previous := GDVars.treasureItems;
        New(GDVars.treasureItems);
        GDVars.treasureItems^ := item;
        GDVars.treasureItems^.next := previous
      end
    end
  end;
  Shop.ShopMainMenu
end;

{ Runs the handler for the current opcode. }
procedure DispatchEclCommand;
begin
  case GDVars.curOpcode of
    $00: EclVm.EclExit;
    $01: EclVm.EclGoto;
    $02: EclVm.EclGosubCmd;
    $03: EclVm.EclCompare;
    $04, $05, $06, $07: EclVm.EclArithmetic;
    $08: EclVm.EclRandom;
    $09: EclVm.EclSave;
    $0A: EclVm.EclLoadCharacter;
    $0B: EclVm.EclLoadMonster;
    $0C: EclVm.EclSetupMonster;
    $0D: EclVm.EclApproach;
    $0E: EclVm.EclPicture;
    $0F: EclVm.EclInputNumber;
    $10: EclVm.EclInputString;
    $11, $12: EclVm.EclPrint;
    $13: EclVm.EclReturn;
    $14: EclVm.EclCompareAnd;
    $15: EclVm.EclVMenu;
    $16, $17, $18, $19, $1A, $1B: EclVm.EclIf;
    $1C: EclVm.EclClearMonsters;
    $1D: EclVm.EclContinuePrompt;
    $1E: EclVm.EclCheckParty;
    $1F: EclVm.EclJournalEntry;
    $20: EclVm.EclNewEcl;
    $21, $37: EclVm.EclLoadFiles;
    $22: EclVm.EclYesNo;
    $23: EclVm.EclRedrawExit;
    $24: EclVm.EclCombat;
    $25, $26: EclVm.EclOnGoto;
    $27: EclVm.EclTreasure;
    $28: EclVm.EclRob;
    $29: EclVm.EclNoOperation;
    $2A: EclVm.EclGetTable;
    $2B: EclVm.EclHMenu(0);
    $2C: EclVm.EclPlaySound;
    $2D: EclVm.EclCall;
    $2E: EclVm.EclDamage;
    $2F, $30: EclVm.EclAndOr;
    $31: EclVm.EclHMenu(1);
    $32: EclVm.EclFindItem;
    $33: EclVm.EclPrintReturn;
    $34: EclVm.EclClock;
    $35: EclVm.EclSaveTable;
    $36: EclVm.EclAddNpc;
    $38: EclVm.EclProgram;
    $39: EclVm.EclWho;
    $3A: EclVm.EclDelay;
    $3B: EclVm.EclSpell;
    $3C: EclVm.EclShop;
    $3D: EclVm.EclClearBox;
    $3E: EclVm.EclDump;
    $3F: EclVm.EclFindSpecial;
    $40: EclVm.EclDestroyItems;
    $41: EclVm.EclAwardExperience
  end
end;

procedure CallEclScript(entry: Word);
var
  { Unused in this version; see the other implementations of this routine. }
  savedIp: Word;
begin
  { never read }
  GDVars.loopIndex := 1;
  GDVars.eclIp := entry;
  GDVars.eclStop := 0;
  while (GDVars.eclStop = 0) and (GDVars.partyDefeated = 0) and (GDVars.restartLoop = 0) do begin
    GDVars.previousOpcode := GDVars.curOpcode;
    GDVars.curOpcode := GDVars.zone3^[GDVars.eclIp];
    EclVm.DispatchEclCommand
  end;
  GDVars.eclStop := 0
end;

{ Finishes a NEWECL: for each newly loaded block it frees the animation, forgets the saved picture, refreshes the cell
  event, clears the zone-1 leave-map word and runs the block's on-load entry script. If that loads no further block, it
  records the block as the last one entered, redraws the map view (when the view's files are loaded and the party has
  not just left the 3D view, or when it stays in the 3D view), runs two more of the block's entry scripts, then restores
  and redisplays the selected character. A NEWECL in any of those scripts repeats it for the next block. The interface
  state is remembered at the end. }
procedure NewEclDone;
begin
  repeat
    Portrait.FreeAnimation(GDVars.portraitAnimation);
    GDVars.savedPictureName[0] := #0;
    GDVars.savedPictureId := 255;
    GDVars.newEclFlag := 0;
    GDVars.mapState.event := View3D.GetMapEvent(GDVars.mapState.x, GDVars.mapState.y);
    GDVars.zone1^.leaveMap[$7ED5] := 0;
    GDVars.savedCharacter := GDVars.currentCharacter;
    EclVm.CallEclScript(GDVars.eclEntryPoints.entryMain);
    if GDVars.newEclFlag = 0 then GDVars.zone0^.scriptId := GDVars.currentScriptId;
    if GDVars.newEclFlag = 0 then begin
      if (((GDVars.previousInterfaceState <> C_Ifc.VIEW_3D) or (GDVars.interfaceState = C_Ifc.VIEW_3D)) and
          (GDVars.filesLoaded <> 0)) or
          ((GDVars.previousInterfaceState = C_Ifc.VIEW_3D) and (GDVars.interfaceState = C_Ifc.VIEW_3D)) then
        MapView.DisplayMapView;
      GDVars.newEclFlag := 0;
      EclVm.CallEclScript(GDVars.eclEntryPoints.entryBeforeMove);
      if GDVars.newEclFlag = 0 then begin
        EclVm.CallEclScript(GDVars.eclEntryPoints.entryAfterMove);
        if GDVars.newEclFlag = 0 then begin
          GDVars.currentCharacter := GDVars.savedCharacter;
          CharHlp.DisplayParty(GDVars.currentCharacter)
        end
      end
    end
  until GDVars.newEclFlag = 0;
  GDVars.previousInterfaceState := GDVars.interfaceState
end;

procedure GameLoop;
var
    { Explore.MapMainMenu's choice; 4 is Encamp }
    selection: Byte;
    cursor: Types.PCharacter;
    savedMenu: Byte;
begin
  repeat
    GDVars.restartLoop := 0;
    GDVars.savedCharacter := GDVars.currentCharacter;
    GDVars.forceMapRedraw := 1;
    GDVars.protectionShown := 0;
    GDVars.piecesLoaded := 0;
    GDVars.mapLoaded := 0;
    GDVars.restoreCharacter := 0;
    GDVars.filesLoaded := 0;
    GDVars.noncombatRedrawState := 1;
    GDVars.interfaceState := C_Ifc.VIEW_3D;
    GDVars.newEclFlag := 0;
    if GDVars.zone0^.scriptId = 0 then begin
      GDVars.noncombatRedrawState := 0;
      if GDVars.demoMode <> 0 then begin
        GDVars.currentScriptId := 2;
        GDVars.diskNumber := 5
      end else begin
        GDVars.diskNumber := 1;
        GDVars.currentScriptId := 16;
        CharHlp.DisplayParty(GDVars.currentCharacter)
      end
    end else
      GDVars.currentScriptId := GDVars.zone0^.scriptId;
    if GDVars.zone0^.inDungeon = 0 then GDVars.interfaceState := C_Ifc.OVERLAND;
    EclMenu.LoadEclScript(GDVars.currentScriptId);
    EclMenu.EclInit;
    EclVm.CallEclScript(GDVars.eclEntryPoints.entryMain);
    if GDVars.demoMode <> 0 then begin
      cursor := GDVars.partyHead;
      while cursor <> nil do begin
        GDVars.currentCharacter := cursor;
        cursor := cursor^.next;
        CharGen.RemoveCreature(True, True)
      end;
      Exit
    end;
    if GDVars.newEclFlag = 0 then
      GDVars.zone0^.scriptId := GDVars.currentScriptId
    else
      EclVm.NewEclDone;
    if (GDVars.interfaceState <> C_Ifc.OVERLAND) and (GDVars.loadedSave <> 0) then begin
      if GDVars.noncombatRedrawState = 1 then CharHlp.DisplayNoncombatInterface;
      GDVars.forceMapRedraw := 1;
      MapView.DisplayMapView
    end;
    GDVars.loadedSave := 0;
    GDVars.extendedMode := 0;
    savedMenu := 1;
    repeat
      GDVars.selectedChoice := savedMenu;
      selection := Ord(Explore.MapMainMenu);
      savedMenu := GDVars.selectedChoice;
      GDVars.savedCharacter := GDVars.currentCharacter;
      if GDVars.newEclFlag = 0 then GDVars.zone0^.scriptId := GDVars.currentScriptId;
      while ((GDVars.zone1^.searchFlags[GDConsts.searchFlagsIndex + $7C00] > 1) or (selection = 4)) and
          (GDVars.partyDefeated = 0) and
          (GDVars.restartLoop = 0) do begin
        if selection = 4 then
          EclVm.EnterCamp
        else begin
          GDVars.savedSearchFlag := GDVars.zone1^.searchFlags[GDConsts.searchFlagsIndex + $7C00] and $01;
          GDVars.zone1^.searchFlags[GDConsts.searchFlagsIndex + $7C00] := $01;
          GDVars.forceMapRedraw := 1;
          MapView.DisplayMapView;
          EclVm.CallEclScript(GDVars.eclEntryPoints.entryAfterMove);
          if GDVars.newEclFlag <> 0 then EclVm.NewEclDone;
          GDVars.zone1^.searchFlags[GDConsts.searchFlagsIndex + $7C00] := GDVars.savedSearchFlag
        end;
        if (GDVars.partyDefeated = 0) and (GDVars.restartLoop = 0) then begin
          GDVars.selectedChoice := savedMenu;
          selection := Ord(Explore.MapMainMenu);
          savedMenu := GDVars.selectedChoice;
          GDVars.savedCharacter := GDVars.currentCharacter
        end
      end;
      if (GDVars.partyDefeated = 0) and
          (GDVars.restartLoop = 0) then EclVm.CallEclScript(GDVars.eclEntryPoints.entryBeforeMove);
      if GDVars.newEclFlag <> 0 then
        EclVm.NewEclDone
      else if (GDVars.partyDefeated = 0) and (GDVars.restartLoop = 0) then begin
        GDVars.zone0^.prevX := GDVars.mapState.x;
        GDVars.zone0^.prevY := GDVars.mapState.y;
        Explore.ResolveMovement;
        MapView.DisplayMapView;
        if (GDVars.mapState.x <> GDVars.zone0^.prevX) or (GDVars.mapState.y <> GDVars.zone0^.prevY) then
          Music.SendSoundCommand(GDConsts.stepSound);
        GDVars.eclGraphics := 0;
        EclVm.CallEclScript(GDVars.eclEntryPoints.entryAfterMove);
        if GDVars.newEclFlag <> 0 then EclVm.NewEclDone
      end
    until (GDVars.partyDefeated <> 0) or (GDVars.restartLoop <> 0)
  until GDVars.partyDefeated <> 0;
  GDVars.partyDefeated := 0;
  cursor := GDVars.partyHead;
  while cursor <> nil do begin
    GDVars.currentCharacter := cursor;
    cursor := cursor^.next;
    CharGen.RemoveCreature(False, True)
  end
end;
begin
end.
