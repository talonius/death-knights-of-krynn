{ Saving and loading. A character is its .pc file (TCharacter whole) with a .wiz (the spell block), a .jnk (its items)
  and an .eff (its effects) beside it; a saved game is savgamX.pty (the zones, the map state and the members' CHRDATXn
  stems) with the members saved as .gam files and the pool vault as vaultX.dat. Imported characters come from
  championsSavePath: a .who is its own record, its items a .stf and its effects a .sfx, and its saved games are
  savgamX.dat with .sav members. Creatures come from the MON1CHA.DAX, MON1WIZ.DAX, MON1SPC.DAX and MON1ITM.DAX archives;
  a character's icon is CHEAD and CBODY merged. }
{$F+,O+,S-,R-,V-,B-,I-}
unit SaveLoad;
interface
uses C_Class, C_Ifc, C_Npc, C_Race, C_Stat, Crt, C_Keys, GDConsts, GDVars, Dos, DaxIo, GameIo,
  TextRend, MenuCore, MapTiles, Blit, Portrait, FxEngine, CharHlp, View3D, ClassCal, Types;

{ Lists the saved characters of the current file format (this game's or the imported one) whose files have the format's
  size: their names and file names, with the NPC byte read alongside.
  @param(characterNames Receives the list of names.)
  @param(fileNames Receives the matching file names.) }
procedure LoadCharlist(var characterNames, fileNames: Pointer);

{ Makes sure the save directory is there, asking for the save disk on a floppy and creating the directory when it is
  missing.
  @returns(True when the save directory is ready.) }
function CheckSaveDir: Boolean;

{ Builds the current character's combat icon in its slot (on disk 1): loads the head (CHEAD) icon into scratch slot 11
  and the body (CBODY) icon into the slot, both for its icon size, ORs the head's two frames onto the body's and,
  outside CGA, recolors color 8 to 0 in each; then frees slot 11 and discards pending keys.
  @param(loading Also recolors the icon with the character's six saved icon colors.) }
procedure LoadCharIconAnim(loading: Boolean);

{ Deletes character's character, spell, item and effect files.
  @param(character Character whose files are deleted.) }
procedure DeleteCharacterFiles(character: Types.PCharacter);

{ Saves character as its character file with its spell, item and effect files beside it, under fileName or its cleaned
  name, after checking the directory and the free space and asking before overwriting.
  @param(character Character to save.)
  @param(fileName File stem to save under; empty to use the cleaned name, asking before overwriting.) }
procedure SaveChar(character: Types.PCharacter; fileName: Types.TString8);

{ Loads character name in the current file format -- an imported character converted, its age checked against its race,
  and the items this game lacks dropped -- with its spells, items and effects.
  @param(name File name of the character.)
  @param(character Record receiving it.)
  @param(savedGame Unused.)
  @param(askDisk True to prompt for the save disk rather than the game disk.) }
procedure LoadChar(name: String; character: Types.PCharacter; savedGame, askDisk: Boolean);

{ Loads monster id from the MON archives of the current disk: its record (CHA), spells (WIZ), effects (SPC) and items
  (ITM), the items into pooled slots when allocSlots is set.
  @param(id Monster number.)
  @param(allocSlots True to put its items into pooled slots.)
  @param(character Record receiving it.) }
procedure LoadCreatureData(id: Byte; allocSlots: Boolean; character: Types.PCharacter);

{ Adds a monster to the party, unless it already has 8 members, with its combat icon from CPIC.
  @param(id The monster number, also kept as its creature ID.) }
procedure AddCreatureToParty(id: Byte);

{ Asks for a saved game (A..J) of the current format and loads it: the zones, the map state, the wall sets and every
  member, then the wall set, map and view for the area. }
procedure LoadGame;

{ Asks for a letter and saves the game as savgamX.pty -- disk number, zones 0..2, map state, interface states, wall sets
  and the members' file stems -- with each member saved beside it and the vault file renamed to the letter; refused when
  the disk is too full. }
procedure SaveGame;

{ Appends a character to the party, makes it current, gives it the first free order slot, and counts it in the party
  size; an NPC also has its class values recalculated. Note: with all eight order slots taken, the order slot is left at
  8.
  @param(character The character.) }
procedure AddCharToParty(character: Types.PCharacter);

{ Loads the vault: pooledMoney and the item list treasureItems from tmpvault.dat or vaultX.dat, or, with no file yet,
  the steel the game's vaultFunds word carries x100.
  @param(hasMoney Receives True when the vault holds money.)
  @param(hasItems Receives True when it holds items.) }
procedure LoadVault(var hasMoney, hasItems: Boolean);

{ Writes the vault file name afresh: pooledMoney, then treasureItems whole, and marks it pending. A full disk is
  reported but the file is written anyway.
  @param(name File to write.) }
procedure WriteVaultFile(name: String);
implementation
uses CharGen;
type
  PChampionsBytes = ^TChampionsBytes;
  TChampionsBytes = array[0..408] of Byte;
  TPartyFileNames = array[1..8] of String[40];

procedure LoadCharlist(var characterNames, fileNames: Pointer);

  { Adds the files matching a pattern and of the expected size to the name and file-name lists. }
  procedure ScanSaveFiles(pattern: Types.TString80; tag, position, expectedSize: Word; var characterNames,
                          fileNames: Pointer);
  var
    nameNode: Types.PMenuRow;
    nameTail: Types.PMenuRow;
    fileNode: Types.PMenuRow;
    fileTail: Types.PMenuRow;
    member: Types.PCharacter;
    search: SearchRec;
    bytesRead: Word;
    dataFile: file;
    { Unused in this version; see the other implementations of this routine. }
    sourceSuffix: String[80];
    npcFlag: Byte;
    { Unused in this version; see the other implementations of this routine. }
    matchCount: String[16];
  begin
    nameNode := nil;
    fileNode := nil;
    FindFirst(pattern, 0, search);
    while DosError = 0 do begin
      if GDVars.fileFormat = 1 then
        Assign(dataFile, GDVars.savePath + search.Name)
      else
        Assign(dataFile, GDVars.championsSavePath + search.Name);
      Reset(dataFile, 1);
      if FileSize(dataFile) = expectedSize then begin
        GetMem(nameNode, SizeOf(Types.TMenuRow));
        GetMem(fileNode, SizeOf(Types.TMenuRow));
        FillChar(nameNode^, SizeOf(Types.TMenuRow), 0);
        FillChar(fileNode^, SizeOf(Types.TMenuRow), 0);
        Seek(dataFile, tag);
        BlockRead(dataFile, nameNode^, 16, bytesRead);
        Seek(dataFile, position);
        BlockRead(dataFile, npcFlag, SizeOf(npcFlag));
        fileNode^.name := search.Name;
        nameNode^.name := nameNode^.name + Copy(GDConsts.nameBlanks, 1, 15 - Length(nameNode^.name));
        member := GDVars.partyHead;
        while (member <> nil) and
            (Copy(nameNode^.name, 1, 15) <> member^.name + Copy(GDConsts.nameBlanks, 1, 15 - Length(member^.name))) do
          member := member^.next;
        if (npcFlag > $7F) or (member <> nil) then begin
          FreeMem(nameNode, SizeOf(Types.TMenuRow));
          FreeMem(fileNode, SizeOf(Types.TMenuRow));
          nameNode := nil;
          fileNode := nil
        end;
        if nameNode <> nil then begin
          if characterNames = nil then begin
            characterNames := nameNode;
            nameTail := Types.PMenuRow(characterNames);
            fileNames := fileNode;
            fileTail := Types.PMenuRow(fileNames)
          end else begin
            nameTail^.next := nameNode;
            nameTail := nameTail^.next;
            fileTail^.next := fileNode;
            fileTail := fileTail^.next
          end
        end
      end;
      Close(dataFile);
      FindNext(search)
    end
  end;
begin
  characterNames := nil;
  fileNames := nil;
  if not SaveLoad.CheckSaveDir then Exit;
  case GDVars.fileFormat of
    0: ScanSaveFiles(GDVars.championsSavePath + '*.who', GDConsts.nameOffsetByFormat[GDVars.fileFormat],
                     GDConsts.npcOffsetByFormat[GDVars.fileFormat], GDConsts.fileSizeByFormat[GDVars.fileFormat],
                         characterNames,
                     fileNames);
    1: ScanSaveFiles(GDVars.savePath + '*.pc', GDConsts.nameOffsetByFormat[GDVars.fileFormat],
                     GDConsts.npcOffsetByFormat[GDVars.fileFormat], GDConsts.fileSizeByFormat[GDVars.fileFormat],
                         characterNames,
                     fileNames)
  end
end;

function CheckSaveDir: Boolean;
var errorCode: Integer;
    search: SearchRec;
    answer: Byte;
    path: String;
begin
  CheckSaveDir := False;
  if GDVars.fileFormat = 1 then
    path := GDVars.savePath
  else
    path := GDVars.championsSavePath;
  repeat
    while (DaxIo.GetVolumeLabel(path[1]) = 'CHAMP') and (path[1] < 'C') do
      TextRend.DisplayAndPause(Yellow, Black, GDConsts.saveDirectoryName + path[1] + ':');
    repeat
      FindFirst(Copy(path, 1, Length(path) - 1), Directory, search);
      errorCode := DosError;
      case errorCode of
        0: ;
        2, 18: begin
          if UpCase(path[1]) < 'C' then begin
            if GDVars.fileFormat = 1 then
              answer := MenuCore.YesNoMenu(GDConsts.askSaveDiskPrefix + path[1] + GDConsts.askDiskSuffix,
                                           GDConsts.yesKey)
            else
              answer := MenuCore.YesNoMenu(GDConsts.askChampionsDiskPrefix + path[1] + GDConsts.askDiskSuffix,
                                           GDConsts.yesKey);
            if answer <> GDConsts.yesKey then
              TextRend.DisplayAndPause(Yellow, Black, GDConsts.saveDirectoryName + path[1] + ':')
          end;
          if GDVars.fileFormat = 1 then
            MkDir(Copy(GDVars.savePath, 1, Length(GDVars.savePath) - 1))
          else
            MkDir(Copy(GDVars.championsSavePath, 1, Length(GDVars.championsSavePath) - 1));
          errorCode := DosError
        end else
        if UpCase(path[1]) < 'C' then
          TextRend.DisplayAndPause(Yellow, Black, GDConsts.saveDirectoryName + path[1] + ':')
        else begin
          if GDVars.fileFormat = 0 then
            TextRend.DisplayAndPause(Yellow, Black, GDConsts.noChampionsDirectoryMessage)
          else
            TextRend.DisplayAndPause(Yellow, Black, GDConsts.noSaveDirectoryMessage);
          Exit
        end
      end
    until errorCode in [0, 5]
  until errorCode in [0, 5];
  CheckSaveDir := True
end;

{ ORs one icon's pixels into another and ANDs its transparency mask into the other's.
  @param(source The icon to add.)
  @param(destination The icon that receives it.) }
procedure MergeIcon(source, destination: Types.PImgBuf);
var
  { Unused in this version; see the other implementations of this routine. }
  count: array[0..1] of Byte;
  index: Word;
begin
  for index := 0 to source^.imgSize - 1 do begin
    destination^.data[index] := destination^.data[index] or source^.data[index];
    destination^.transp^[index] := destination^.transp^[index] and source^.transp^[index]
  end
end;

procedure LoadCharIconAnim(loading: Boolean);
var
  { Unused in this version; see the other implementations of this routine. }
  animSlot: Byte;
  { Unused in this version; see the other implementations of this routine. }
  iconSlot: Byte;
  { Unused in this version; see the other implementations of this routine. }
  iconIds: Byte;
  fromColors: Types.TColorTab;
  toColors: Types.TColorTab;
  index: Byte;
  { Unused in this version; see the other implementations of this routine. }
  partIndex: Byte;
begin
  DaxIo.PushState(1);
  with GDVars.currentCharacter^ do begin
    MapTiles.LoadIconAnim('CHEAD' + GDConsts.iconSizeSuffix[iconSize], iconHead, 11);
    MapTiles.LoadIconAnim('CBODY' + GDConsts.iconSizeSuffix[iconSize], iconBody, orderNumber);
    SaveLoad.MergeIcon(GDVars.iconAnimations[11, 0], GDVars.iconAnimations[orderNumber, 0]);
    if GDVars.displayMode <> Types.Cga then
      Blit.RemapPic(GDConsts.iconRemapFrom, GDConsts.iconRemapTo, 0, False,
                    GDVars.iconAnimations[orderNumber, 0]);
    SaveLoad.MergeIcon(GDVars.iconAnimations[11, 1], GDVars.iconAnimations[orderNumber, 1]);
    if GDVars.displayMode <> Types.Cga then
      Blit.RemapPic(GDConsts.iconRemapFrom, GDConsts.iconRemapTo, 0, False,
                    GDVars.iconAnimations[orderNumber, 1]);
    if loading then begin
      for index := 0 to 15 do begin
        fromColors[index] := index;
        toColors[index] := index
      end;
      for index := 1 to 6 do begin
        toColors[GDConsts.iconColorSlots[index]] := iconColors[index] and $F;
        toColors[GDConsts.iconColorSlots[index] + 8] := (iconColors[index] and $F0) shr 4
      end;
      Blit.RemapPic(fromColors, toColors, 0, False, GDVars.iconAnimations[orderNumber, 0]);
      Blit.RemapPic(fromColors, toColors, 0, False, GDVars.iconAnimations[orderNumber, 1])
    end
  end;
  MapTiles.FreeIconAnim(11);
  DaxIo.PopState;
  GameIo.FlushKeys
end;

procedure DeleteCharacterFiles(character: Types.PCharacter);
var prefix: String[80];
    { Unused in this version; see the other implementations of this routine. }
    fileBuffer: array[0..127] of Byte;
begin
  prefix := GDVars.savePath + DaxIo.SanitizeFileName(Types.PCharacter(character)^.name);
  DaxIo.DeleteIfPresent(prefix + GDConsts.characterExtension);
  DaxIo.DeleteIfPresent(prefix + GDConsts.spellsExtension);
  DaxIo.DeleteIfPresent(prefix + GDConsts.itemsExtension);
  DaxIo.DeleteIfPresent(prefix + GDConsts.effectsExtension)
end;

procedure SaveChar(character: Types.PCharacter; fileName: Types.TString8);
var dataFile: file;
    cleanName: Types.TString40;
    extension: String[4];
    choice: Byte;
    { Unused in this version; see the other implementations of this routine. }
    response: Byte;
    item: Types.PItem;
    effect: Types.PEffect;
    { Unused in this version; see the other implementations of this routine. }
    nameBuffer: array[0..23] of Byte;
    errorCode: Integer;
    bytesNeeded: Word;
    { Unused in this version; see the other implementations of this routine. }
    redraw: Boolean;
begin
  GDVars.fileFormat := 1;
  repeat
    if not SaveLoad.CheckSaveDir then Exit;
    bytesNeeded := 0;
    Inc(bytesNeeded, 216);
    if Types.PCharacter(character)^.items <> nil then begin
      item := Types.PCharacter(character)^.items;
      while item <> nil do begin
        Inc(bytesNeeded, 63);
        item := item^.next
      end
    end;
    if Types.PCharacter(character)^.effects <> nil then begin
      effect := Types.PCharacter(character)^.effects;
      while effect <> nil do begin
        Inc(bytesNeeded, 9);
        effect := effect^.next
      end
    end;
    choice := 0;
    if bytesNeeded > DiskFree(Ord(UpCase(GDVars.savePath[1])) - 64) then begin
      TextRend.DisplayAndPause(Yellow, Black, GDConsts.diskFullMessage);
      MenuCore.EnableChoices(1);
      choice := MenuCore.MenuHorizontal(GDConsts.loseCharacterPrompt, GDConsts.tryAnotherDiskMenu, 0, 0)
    end
  until choice = 0;
  if Length(fileName) = 0 then begin
    extension := GDConsts.characterExtension;
    cleanName := DaxIo.SanitizeFileName(DaxIo.SanitizeString(Types.PCharacter(character)^.name, '.'))
  end else begin
    extension := GDConsts.savedCharacterExtension;
    cleanName := fileName
  end;
  repeat
    Assign(dataFile, GDVars.savePath + cleanName + extension);
    Reset(dataFile, 1);
    errorCode := DosError;
    if not (errorCode in [0, 2]) then
      if UpCase(GDVars.savePath[1]) < 'C' then
        TextRend.DisplayAndPause(Yellow, Black, GDConsts.saveDirectoryName + GDVars.savePath[1] + ':')
      else begin
        TextRend.DisplayAndPause(Yellow, Black, GDConsts.noSaveDirectoryMessage);
        Close(dataFile);
        Exit
      end
  until (errorCode = 0) or (errorCode = 2);
  Close(dataFile);
  choice := 1;
  while (choice = 1) and (Length(fileName) = 0) and DaxIo.FileExists(GDVars.savePath + cleanName + extension) do begin
    choice := MenuCore.YesNoMenu(GDConsts.overwritePrefix + cleanName + GDConsts.overwriteSuffix, GDConsts.noKey);
    if choice = 1 then begin
      cleanName := '';
      while Length(cleanName) = 0 do
        cleanName := TextRend.ReadString(GDConsts.newFileNamePrompt, LightGreen, Black, 8);
      Types.PCharacter(character)^.name := cleanName
    end
  end;
  Assign(dataFile, GDVars.savePath + cleanName + extension);
  Rewrite(dataFile, 1);
  BlockWrite(dataFile, Types.PCharacter(character)^, SizeOf(Types.TCharacter));
  Close(dataFile);
  DaxIo.DeleteIfPresent(GDVars.savePath + cleanName + GDConsts.spellsExtension);
  if Types.PCharacter(character)^.spells <> nil then begin
    Assign(dataFile, GDVars.savePath + cleanName + GDConsts.spellsExtension);
    Rewrite(dataFile, 1);
    BlockWrite(dataFile, Types.PCharacter(character)^.spells^, 220);
    Close(dataFile)
  end;
  DaxIo.DeleteIfPresent(GDVars.savePath + cleanName + GDConsts.itemsExtension);
  if Types.PCharacter(character)^.items <> nil then begin
    Assign(dataFile, GDVars.savePath + cleanName + GDConsts.itemsExtension);
    Rewrite(dataFile, 1);
    item := Types.PCharacter(character)^.items;
    while item <> nil do begin
      BlockWrite(dataFile, item^, SizeOf(Types.TItem));
      item := item^.next
    end;
    Close(dataFile)
  end;
  DaxIo.DeleteIfPresent(GDVars.savePath + cleanName + GDConsts.effectsExtension);
  if Types.PCharacter(character)^.effects <> nil then begin
    Assign(dataFile, GDVars.savePath + cleanName + GDConsts.effectsExtension);
    Rewrite(dataFile, 1);
    effect := Types.PCharacter(character)^.effects;
    while effect <> nil do begin
      BlockWrite(dataFile, effect^, SizeOf(Types.TEffect));
      effect := effect^.next
    end;
    Close(dataFile)
  end
end;

procedure LoadChar(name: String; character: Types.PCharacter; savedGame, askDisk: Boolean);
var dataFile: file;
    bytesRead: Word;
    itemTail: Types.PItem;
    itemBuffer: Types.PItem;
    effectTail: Types.PEffect;
    effectBuffer: Types.PEffect;
    diskPrompt: String[40];
    { Unused in this version; see the other implementations of this routine. }
    found: Boolean;
    { Unused in this version; see the other implementations of this routine. }
    nameLength: array[1..292] of Byte;
    itemCount: Byte;
    path: String;
    castClass: ShortInt;
    itemExt: String[4];
    effectExt: String[4];
    oldCharacter: PChampionsBytes;
begin
  if GDVars.fileFormat = 1 then begin
    path := GDVars.savePath;
    itemExt := GDConsts.itemsExtension;
    effectExt := GDConsts.effectsExtension
  end else begin
    path := GDVars.championsSavePath;
    itemExt := GDConsts.championsItemsExtension;
    effectExt := GDConsts.championsEffectsExtension
  end;
  if askDisk then
    diskPrompt := GDConsts.saveDirectoryName
  else
    diskPrompt := GDConsts.insertDiskMessages[GDVars.diskNumber];
  found := DaxIo.OpenWithRetry(path + name, diskPrompt, #0, dataFile);
  TextRend.DisplayString(GDConsts.messageColumn, GDConsts.messageRow, LightGreen, Black, GDConsts.loadingMessage);
  FillChar(Types.PCharacter(character)^, SizeOf(Types.TCharacter), 0);
  case GDVars.fileFormat of
    0: begin
      GetMem(oldCharacter, SizeOf(TChampionsBytes));
      FillChar(oldCharacter^, 409, 0);
      FillChar(Types.PCharacter(character)^, SizeOf(Types.TCharacter), 0);
      BlockRead(dataFile, oldCharacter^, 409, bytesRead);
      Move(oldCharacter^[0], PChampionsBytes(character)^[0], 30);
      Move(oldCharacter^[$58], PChampionsBytes(character)^[$1E], 11);
      Move(oldCharacter^[$CF], PChampionsBytes(character)^[$29], 8);
      Move(oldCharacter^[$DA], PChampionsBytes(character)^[$31], 12);
      Move(oldCharacter^[$F3], PChampionsBytes(character)^[$3F], 39);
      Move(oldCharacter^[$11A], PChampionsBytes(character)^[$6B], 2);
      Move(oldCharacter^[$130], PChampionsBytes(character)^[$6D], 3);
      Move(oldCharacter^[$135], PChampionsBytes(character)^[$70], 12);
      Move(oldCharacter^[$142], PChampionsBytes(character)^[$7C], 70);
      Move(oldCharacter^[$188], PChampionsBytes(character)^[$C7], 17);
      Types.PCharacter(character)^.items := nil;
      Types.PCharacter(character)^.effects := nil;
      Types.PCharacter(character)^.combat := nil;
      Types.PCharacter(character)^.next := nil;
      Types.PCharacter(character)^.spells := nil;
      if (Types.PCharacter(character)^.characterClass <> C_Class.FIGHTER) and
          (Types.PCharacter(character)^.characterClass <> C_Class.THIEF) and
          (Types.PCharacter(character)^.characterClass <> C_Class.FIGHTER_THIEF) then begin
        with Types.PCharacter(character)^ do begin
          GetMem(spells, SizeOf(Types.TSpellBlock));
          FillChar(spells^, 220, 0);
          Move(oldCharacter^[$1E], spells^, 58);
          Move(oldCharacter^[$63], PChampionsBytes(spells)^[$4A], 107);
          for castClass := 0 to 3 do
            Move(oldCharacter^[$11C + castClass * 5], spells^.slots[castClass, 1], 5)
        end
      end;
      case Types.PCharacter(character)^.race of
        C_Race.QUALINESTI_ELF, C_Race.SILVANESTI_ELF: if Types.PCharacter(character)^.age > 1200 then
              Types.PCharacter(character)^.age := 1200;
        C_Race.HALF_ELF: if Types.PCharacter(character)^.age > 200 then
            Types.PCharacter(character)^.age := 200;
        C_Race.MOUNTAIN_DWARF, C_Race.HILL_DWARF: if Types.PCharacter(character)^.age > 300 then
              Types.PCharacter(character)^.age := 300;
        C_Race.KENDER: if Types.PCharacter(character)^.age > 199 then
            Types.PCharacter(character)^.age := 70;
        C_Race.HUMAN: if Types.PCharacter(character)^.age > 50 then
            Types.PCharacter(character)^.age := 50
      end;
      FreeMem(oldCharacter, 409)
    end;
    1: begin
      BlockRead(dataFile, Types.PCharacter(character)^, SizeOf(Types.TCharacter), bytesRead);
      Close(dataFile);
      Types.PCharacter(character)^.items := nil;
      Types.PCharacter(character)^.effects := nil;
      Types.PCharacter(character)^.combat := nil;
      Types.PCharacter(character)^.next := nil
    end
  end;
  Delete(name, Pos('.', name), 4);
  if GDVars.fileFormat = 1 then
    if DaxIo.FileExists(path + name + GDConsts.spellsExtension) then begin
      GetMem(Types.PCharacter(character)^.spells, SizeOf(Types.TSpellBlock));
      found := DaxIo.OpenWithRetry(GDVars.savePath + name + GDConsts.spellsExtension, diskPrompt, #0, dataFile);
      BlockRead(dataFile, Types.PCharacter(character)^.spells^, 220, bytesRead);
      if bytesRead <> 220 then
        TextRend.DisplayAndPause(Yellow, Black, GDConsts.unexpectedErrorPrefix);
      Close(dataFile)
    end;
  itemCount := 0;
  if DaxIo.FileExists(path + name + itemExt) then begin
    GetMem(itemBuffer, SizeOf(Types.TItem));
    found := DaxIo.OpenWithRetry(path + name + itemExt, diskPrompt, #0, dataFile);
    repeat
      BlockRead(dataFile, itemBuffer^, SizeOf(Types.TItem), bytesRead);
      if bytesRead = 63 then begin
        if (GDVars.fileFormat <> 0) or not (itemBuffer^.itemType in [42, 47, 58, 60, 63, 69, 72]) then begin
          Inc(itemCount);
          if Types.PCharacter(character)^.items = nil then begin
            Types.PCharacter(character)^.items := GameIo.AllocSlot;
            itemTail := Types.PCharacter(character)^.items
          end else begin
            itemTail^.next := GameIo.AllocSlot;
            itemTail := itemTail^.next
          end;
          itemTail^ := itemBuffer^;
          itemTail^.next := nil
        end
      end
    until bytesRead <> 63;
    Close(dataFile);
    FreeMem(itemBuffer, SizeOf(Types.TItem))
  end;
  if DaxIo.FileExists(path + name + effectExt) then begin
    GetMem(effectBuffer, SizeOf(Types.TEffect));
    found := DaxIo.OpenWithRetry(path + name + effectExt, diskPrompt, #0, dataFile);
    repeat
      BlockRead(dataFile, effectBuffer^, SizeOf(Types.TEffect), bytesRead);
      if bytesRead = 9 then begin
        if Types.PCharacter(character)^.effects = nil then begin
          GetMem(Types.PCharacter(character)^.effects, SizeOf(Types.TEffect));
          effectTail := Types.PCharacter(character)^.effects
        end else begin
          GetMem(effectTail^.next, SizeOf(Types.TEffect));
          effectTail := effectTail^.next
        end;
        effectTail^ := effectBuffer^;
        effectTail^.next := nil
      end
    until bytesRead <> 9;
    Close(dataFile);
    FreeMem(effectBuffer, SizeOf(Types.TEffect))
  end;
  GameIo.FlushKeys;
  CharHlp.RecalcStats(character);
  FxEngine.RecalcAbility(character, C_Stat.STRENGTH);
  ClassCal.RecalcClassStats(Types.PCharacter(character))
end;

procedure LoadCreatureData(id: Byte; allocSlots: Boolean; character: Types.PCharacter);
var size: Word;
    data: Types.PBytes;
    offset: Word;
    item: Types.PItem;
    effect: Types.PEffect;
    archiveNumber: String[1];
    { Unused in this version; see the other implementations of this routine. }
    index: Byte;
    { Unused in this version; see the other implementations of this routine. }
    roll: Byte;
begin
  archiveNumber := '1';
  DaxIo.LoadDax('MON' + archiveNumber + 'CHA', GDConsts.daxExtension, id, size, data);
  if size = 0 then begin
    TextRend.DisplayAndPause(White, Black, GDConsts.unableToLoadMonster);
    GameIo.ExitGame
  end;
  Move(data^, Types.PCharacter(character)^, SizeOf(Types.TCharacter));
  with Types.PCharacter(character)^ do begin
    items := nil;
    effects := nil;
    next := nil;
    combat := nil;
    spells := nil
  end;
  FreeMem(data, size);
  GDVars.suppressDisk := 1;
  DaxIo.LoadDax('MON' + archiveNumber + 'WIZ', GDConsts.daxExtension, id, size, data);
  if size <> 0 then begin
    GetMem(Types.PCharacter(character)^.spells, SizeOf(Types.TSpellBlock));
    Move(data^, Types.PCharacter(character)^.spells^, 220);
    FreeMem(data, size)
  end;
  DaxIo.LoadDax('MON' + archiveNumber + 'SPC', GDConsts.daxExtension, id, size, data);
  if size <> 0 then begin
    offset := 0;
    GetMem(Types.PCharacter(character)^.effects, SizeOf(Types.TEffect));
    effect := Types.PCharacter(character)^.effects;
    repeat
      Move(data^[offset], effect^, SizeOf(Types.TEffect));
      effect^.next := nil;
      Inc(offset, 9);
      if offset < size then begin
        GetMem(effect^.next, SizeOf(Types.TEffect));
        effect := effect^.next
      end
    until offset >= size;
    FreeMem(data, size)
  end;
  DaxIo.LoadDax('MON' + archiveNumber + 'ITM', GDConsts.daxExtension, id, size, data);
  if size <> 0 then begin
    offset := 0;
    if allocSlots then
      Types.PCharacter(character)^.items := GameIo.AllocSlot
    else
      GetMem(Types.PCharacter(character)^.items, SizeOf(Types.TItem));
    item := Types.PCharacter(character)^.items;
    repeat
      Move(data^[offset], item^, SizeOf(Types.TItem));
      item^.next := nil;
      Inc(offset, 63);
      if offset < size then begin
        if allocSlots then
          item^.next := GameIo.AllocSlot
        else
          GetMem(item^.next, SizeOf(Types.TItem));
        item := item^.next
      end
    until offset >= size;
    FreeMem(data, size)
  end;
  GDVars.suppressDisk := 0;
  GameIo.FlushKeys
end;

procedure AddCreatureToParty(id: Byte);
var
  { Unused in this version; see the other implementations of this routine. }
  node: Pointer;
  character: Types.PCharacter;
  { Unused in this version; see the other implementations of this routine. }
  slot: Byte;
begin
  if GDVars.zone1^.partySize[$7F3E] > 7 then Exit;
  GetMem(character, SizeOf(Types.TCharacter));
  SaveLoad.LoadCreatureData(id, True, character);
  character^.identity := id;
  SaveLoad.AddCharToParty(character);
  MapTiles.LoadIconAnim('CPIC', id, character^.orderNumber)
end;

procedure AddCharToParty(character: Types.PCharacter);
var walk: Types.PCharacter;
    used: array[0..7] of Byte;
begin
  Types.PCharacter(character)^.orderNumber := 255;
  if GDVars.partyHead = nil then
    GDVars.partyHead := Types.PCharacter(character)
  else begin
    walk := GDVars.partyHead;
    while walk^.next <> nil do
      walk := walk^.next;
    walk^.next := Types.PCharacter(character)
  end;
  GDVars.currentCharacter := Types.PCharacter(character);
  FillChar(used, SizeOf(used), 0);
  walk := GDVars.partyHead;
  while walk <> nil do begin
    if walk^.orderNumber in [0..7] then
      used[walk^.orderNumber] := 1;
    walk := walk^.next
  end;
  with GDVars.currentCharacter^ do begin
    orderNumber := 0;
    while (orderNumber < 8) and (used[orderNumber] <> 0) do
      Inc(orderNumber)
  end;
  Inc(GDVars.zone1^.partySize[$7F3E]);
  if Types.PCharacter(character)^.npc > $7F then
    ClassCal.RecalcClassStats(Types.PCharacter(character))
end;

procedure LoadGame;
var names: TPartyFileNames;
    dataFile: file;
    index: Byte;
    character: Types.PCharacter;
    fileName: String[40];
    bytesRead: Word;
    characterCount: Byte;
    { Unused in this version; see the other implementations of this routine. }
    found: Boolean;
    letterIndex: Byte;
    choiceCount: Byte;
    choice: Char;
    letter: Char;
    { Unused in this version; see the other implementations of this routine. }
    isExtendedKey: Boolean;
    { Unused in this version; see the other implementations of this routine. }
    menu: String[20];
    saveExt: String[4];
    partyExt: String[4];
    nextEffect: Types.PEffect;
    nextItem: Types.PItem;
    path: String;
    fundByte: Byte;
begin
  TextRend.ClearRect(1, 1, 38, 22);
  MenuCore.EnableChoices(2);
  choice := Char(MenuCore.MenuHorizontal(GDConsts.loadFromWherePrompt, GDConsts.sourceGameMenu, 0, 0));
  case choice of
    #0: begin
      GDVars.fileFormat := 1;
      path := GDVars.savePath;
      partyExt := '.pty';
      saveExt := GDConsts.savedCharacterExtension
    end;
    #1: begin
      GDVars.fileFormat := 0;
      path := GDVars.championsSavePath;
      partyExt := '.dat';
      saveExt := GDConsts.championsSavedExtension
    end;
    #2: Exit
  else
    if (GDVars.menuExtendedKey <> 0) and (choice = C_Keys.ESCAPE) then Exit
  end;
  if not SaveLoad.CheckSaveDir then Exit;
  menu := '';
  FillChar(GDVars.enabledChoices, SizeOf(GDVars.enabledChoices), $FF);
  choiceCount := 0;
  letterIndex := 0;
  for letter := 'A' to 'J' do begin
    if DaxIo.FileExists(path + GDConsts.saveGameStem + letter + partyExt) then begin
      GDVars.enabledChoices[choiceCount].ordinal := letterIndex;
      Inc(choiceCount)
    end;
    Inc(letterIndex)
  end;
  if GDVars.enabledChoices[0].ordinal = 255 then Exit;
  repeat
    choice := Char(MenuCore.MenuHorizontal(GDConsts.loadWhichGamePrompt, GDConsts.saveSlotMenu, 0, 0));
    if (GDVars.menuExtendedKey <> 0) and (choice = C_Keys.ESCAPE) then
      letter := C_Keys.ESCAPE
    else
      letter := Chr(Ord(choice) + Ord('A'))
  until ((letter in ['A'..'J']) and DaxIo.FileExists(path + GDConsts.saveGameStem + letter + partyExt)) or
      (letter = C_Keys.ESCAPE);
  if letter = C_Keys.ESCAPE then Exit;
  found := DaxIo.OpenWithRetry(path + GDConsts.saveGameStem + letter + partyExt, GDConsts.saveDirectoryName + path, #1,
                               dataFile);
  MenuCore.ClearBottomLine;
  TextRend.DisplayString(GDConsts.messageColumn, GDConsts.messageRow, LightGreen, Black, GDConsts.loadingMessage);
  GDVars.loadedSave := Byte(GDVars.fileFormat = 1);
  if GDVars.fileFormat = 1 then begin
    GDVars.vaultLetter := letter;
    BlockRead(dataFile, GDVars.diskNumber, SizeOf(GDVars.diskNumber), bytesRead);
    BlockRead(dataFile, GDVars.zone0^, SizeOf(Types.TZone0), bytesRead);
    BlockRead(dataFile, GDVars.zone1^, SizeOf(Types.TZone1), bytesRead);
    BlockRead(dataFile, GDVars.zone2^, SizeOf(Types.TZone2), bytesRead);
    BlockRead(dataFile, GDVars.mapState, SizeOf(GDVars.mapState), bytesRead);
    BlockRead(dataFile, GDVars.previousInterfaceState, SizeOf(GDVars.previousInterfaceState), bytesRead);
    BlockRead(dataFile, GDVars.interfaceState, SizeOf(GDVars.interfaceState), bytesRead);
    for index := 0 to 3 do begin
      BlockRead(dataFile, GDVars.loadedWallSets[index].blockId, SizeOf(GDVars.loadedWallSets[index].blockId),
                bytesRead);
      BlockRead(dataFile, GDVars.loadedWallSets[index].slot, SizeOf(GDVars.loadedWallSets[index].slot), bytesRead)
    end
  end else begin
    Seek(dataFile, $267);
    BlockRead(dataFile, fundByte, SizeOf(fundByte), bytesRead);
    GDVars.zone0^.vaultFunds[$0] := fundByte;
    BlockRead(dataFile, fundByte, SizeOf(fundByte), bytesRead);
    GDVars.zone0^.vaultFunds[$1] := fundByte;
    Seek(dataFile, $1414)
  end;
  BlockRead(dataFile, characterCount, SizeOf(characterCount), bytesRead);
  BlockRead(dataFile, names, SizeOf(names), bytesRead);
  Close(dataFile);
  GDVars.picturesEnabled := GDVars.zone0^.savedOptions div 2;
  GDVars.animationsEnabled := GDVars.zone0^.savedOptions and $01;
  GDVars.textDelay := GDVars.zone0^.savedTextDelay;
  GDVars.zone1^.partySize[$7F3E] := 0;
  for index := 1 to characterCount do begin
    fileName := DaxIo.SanitizeFileName(DaxIo.SanitizeString(names[index], '.'));
    if DaxIo.FileExists(path + fileName + saveExt) then begin
      GetMem(character, SizeOf(Types.TCharacter));
      SaveLoad.LoadChar(fileName + saveExt, character, True, True);
      if (GDVars.fileFormat = 0) and (character^.npc >= C_Npc.NON_PLAYER) then begin
        nextItem := character^.items;
        while nextItem <> nil do begin
          nextItem := character^.items^.next;
          FreeMem(character^.items, SizeOf(Types.TItem));
          character^.items := nextItem
        end;
        nextEffect := character^.effects;
        while nextEffect <> nil do begin
          nextEffect := character^.effects^.next;
          FreeMem(character^.effects, SizeOf(Types.TEffect));
          character^.effects := nextEffect
        end;
        if character^.spells <> nil then
          FreeMem(character^.spells, 220);
        FreeMem(character, SizeOf(Types.TCharacter))
      end else
        SaveLoad.AddCharToParty(character);
      if not SaveLoad.CheckSaveDir then Exit
    end
  end;
  character := GDVars.partyHead;
  while character <> nil do begin
    SaveLoad.DeleteCharacterFiles(character);
    character := character^.next
  end;
  GDVars.currentCharacter := GDVars.partyHead;
  while GDVars.currentCharacter <> nil do begin
    if GDVars.currentCharacter^.npc < C_Npc.NON_PLAYER then
      SaveLoad.LoadCharIconAnim(True)
    else
      MapTiles.LoadIconAnim('CPIC', GDVars.currentCharacter^.identity, GDVars.currentCharacter^.orderNumber);
    GDVars.currentCharacter := GDVars.currentCharacter^.next
  end;
  GDVars.currentCharacter := GDVars.partyHead;
  if GDVars.fileFormat = 1 then begin
    GDVars.diskNumber := GDVars.zone1^.savedDisk;
    if GDVars.zone0^.inDungeon <> 0 then begin
      { block ids from $8000 up count as none, like 0 }
      if Integer(GDVars.loadedWallSets[0].blockId) > 0 then begin
        View3D.Load3DMap(GDVars.zone0^.geoMap);
        View3D.LoadWallSet(Byte(GDVars.loadedWallSets[0].blockId), Byte(GDVars.loadedWallSets[0].slot))
      end
    end else
      Portrait.LoadBigPic(112)
  end;
  GameIo.FlushKeys;
  MenuCore.ClearBottomLine;
  GDVars.interfaceState := C_Ifc.MAIN_MENU
end;

procedure SaveGame;
var names: TPartyFileNames;
    dataFile: file;
    { Unused in this version; see the other implementations of this routine. }
    pathBuffer: array[1..128] of Byte;
    count: Byte;
    character: Types.PCharacter;
    memberNumber: String[1];
    fileName: String[80];
    hasMoney: Boolean;
    hasItems: Boolean;
    { Unused in this version; see the other implementations of this routine. }
    isExtendedKey: Boolean;
    choice: Char;
    letter: Char;
    errorCode: Word;
    bytesNeeded: Word;

  { Returns the bytes the party's character, spell, item and effect files take. }
  function SaveSize: Word;
  var walk: Types.PCharacter;
      item: Types.PItem;
      effect: Types.PEffect;
      total: Word;
  begin
    total := 0;
    walk := GDVars.partyHead;
    while walk <> nil do begin
      Inc(total, 216);
      if walk^.spells <> nil then Inc(total, 220);
      if walk^.items <> nil then begin
        item := walk^.items;
        while item <> nil do begin
          Inc(total, 63);
          item := item^.next
        end
      end;
      if walk^.effects <> nil then begin
        effect := walk^.effects;
        while effect <> nil do begin
          Inc(total, 9);
          effect := effect^.next
        end
      end;
      walk := walk^.next
    end;
    SaveSize := total
  end;
begin
  repeat
    MenuCore.EnableChoices(9);
    choice := Char(MenuCore.MenuHorizontal(GDConsts.saveWhichGamePrompt, GDConsts.saveSlotMenu, 0,
                                           Ord(GDVars.interfaceState = C_Ifc.CAMPING)))
  until (Ord(choice) < 10) or ((GDVars.menuExtendedKey <> 0) and (Ord(choice) = Ord(C_Keys.ESCAPE)));
  if Ord(choice) > 9 then Exit;
  letter := Chr(Ord(choice) + Ord('A'));
  GDVars.fileFormat := 1;
  if not SaveLoad.CheckSaveDir then Exit;
  if DaxIo.FileExists(GDVars.savePath + GDConsts.saveGameStem + letter + '.pty') then
    bytesNeeded := 0
  else
    bytesNeeded := 2568;
  Inc(bytesNeeded, SaveSize);
  if LongInt(bytesNeeded) > DiskFree(Ord(UpCase(GDVars.savePath[1])) - 64) then begin
    TextRend.DisplayAndPause(Yellow, Black, GDConsts.diskFullMessage);
    Exit
  end;
  repeat
    Assign(dataFile, GDVars.savePath + GDConsts.saveGameStem + letter + '.pty');
    Rewrite(dataFile, 1);
    errorCode := DosError;
    if not (errorCode in [0, 2, 18]) then begin
      if UpCase(GDVars.savePath[1]) < 'C' then
        TextRend.DisplayAndPause(Yellow, Black, GDConsts.saveDirectoryName + GDVars.savePath[1] + ':')
      else begin
        TextRend.DisplayAndPause(Yellow, Black, GDConsts.noSaveDirectoryMessage);
        Close(dataFile);
        Exit
      end
    end
  until errorCode in [0, 2, 18];
  MenuCore.ClearBottomLine;
  TextRend.DisplayString(GDConsts.messageColumn, GDConsts.messageRow, LightGreen, Black, GDConsts.savingMessage);
  GDVars.zone0^.savedTextDelay := GDVars.textDelay;
  GDVars.zone0^.savedOptions := GDVars.picturesEnabled * 2 + GDVars.animationsEnabled;
  GDVars.zone1^.savedDisk := GDVars.diskNumber;
  BlockWrite(dataFile, GDVars.diskNumber, SizeOf(GDVars.diskNumber));
  BlockWrite(dataFile, GDVars.zone0^, SizeOf(Types.TZone0));
  BlockWrite(dataFile, GDVars.zone1^, SizeOf(Types.TZone1));
  BlockWrite(dataFile, GDVars.zone2^, SizeOf(Types.TZone2));
  BlockWrite(dataFile, GDVars.mapState, SizeOf(GDVars.mapState));
  BlockWrite(dataFile, GDVars.previousInterfaceState, SizeOf(GDVars.previousInterfaceState));
  BlockWrite(dataFile, GDVars.interfaceState, SizeOf(GDVars.interfaceState));
  for count := 0 to 3 do begin
    BlockWrite(dataFile, GDVars.loadedWallSets[count].blockId, SizeOf(GDVars.loadedWallSets[count].blockId));
    BlockWrite(dataFile, GDVars.loadedWallSets[count].slot, SizeOf(GDVars.loadedWallSets[count].slot))
  end;
  count := 0;
  character := GDVars.partyHead;
  if character = nil then
    TextRend.DisplayAndPause(Yellow, Black, GDConsts.warningSaving);
  while character <> nil do begin
    Inc(count);
    Str(count, memberNumber);
    names[count] := 'CHRDAT' + letter + memberNumber;
    character := character^.next
  end;
  BlockWrite(dataFile, count, SizeOf(count));
  BlockWrite(dataFile, names, SizeOf(names));
  Close(dataFile);
  character := GDVars.partyHead;
  count := 0;
  while character <> nil do begin
    Inc(count);
    Str(count, memberNumber);
    SaveLoad.SaveChar(character, 'CHRDAT' + letter + memberNumber);
    SaveLoad.DeleteCharacterFiles(character);
    character := character^.next
  end;
  fileName := GDVars.savePath + 'vault' + letter + '.dat';
  if GDVars.vaultPending <> 0 then begin
    DaxIo.DeleteIfPresent(fileName);
    DaxIo.RenameIfExists(GDVars.savePath + 'tmpvault.dat', GDVars.savePath + 'vault' + letter + '.dat')
  end else if GDVars.vaultLetter <> letter then begin
    SaveLoad.LoadVault(hasMoney, hasItems);
    SaveLoad.WriteVaultFile(GDVars.savePath + 'vault' + letter + '.dat')
  end;
  GDVars.vaultLetter := letter;
  GDVars.vaultPending := 0;
  GDVars.recentlySaved := 1;
  MenuCore.ClearBottomLine
end;

procedure LoadVault(var hasMoney, hasItems: Boolean);
var dataFile: file;
    path: String;
    prompt: String[40];
    { Unused in this version; see the other implementations of this routine. }
    errorCode: Word;
    buffer: Types.PItem;
    bytesRead: Word;
    { Unused in this version; see the other implementations of this routine. }
    opened: Boolean;
    vaultFunds: Word;
begin
  hasMoney := False;
  hasItems := False;
  if GDVars.vaultPending <> 0 then
    path := GDVars.savePath + 'tmpVault.dat'
  else begin
    path := GDVars.savePath + 'vault' + GDVars.vaultLetter + '.dat'
  end;
  if DaxIo.FileExists(path) then begin
    opened := DaxIo.OpenWithRetry(path, prompt, #0, dataFile);
    BlockRead(dataFile, GDVars.pooledMoney, SizeOf(GDVars.pooledMoney), bytesRead);
    hasItems := False;
    GetMem(buffer, SizeOf(Types.TItem));
    repeat
      BlockRead(dataFile, buffer^, SizeOf(Types.TItem), bytesRead);
      if bytesRead = 63 then begin
        if GDVars.treasureItems = nil then begin
          GetMem(GDVars.treasureItems, SizeOf(Types.TItem));
          GDVars.treasureItems^ := buffer^;
          GDVars.vaultCursor := GDVars.treasureItems
        end else begin
          GetMem(GDVars.vaultCursor^.next, SizeOf(Types.TItem));
          GDVars.vaultCursor := GDVars.vaultCursor^.next;
          GDVars.vaultCursor^ := buffer^
        end;
        hasItems := True
      end
    until bytesRead <> 63;
    Close(dataFile);
    FreeMem(buffer, SizeOf(Types.TItem))
  end else begin
    FillChar(GDVars.pooledMoney, SizeOf(GDVars.pooledMoney), 0);
    Move(GDVars.zone0^.vaultFunds[$0], vaultFunds, SizeOf(vaultFunds));
    if vaultFunds > 0 then begin
      GDVars.pooledMoney[4] := LongInt(vaultFunds) * 100;
      hasMoney := True
    end
  end
end;

procedure WriteVaultFile(name: String);
var dataFile: file;
    bytesNeeded: Word;
    { Unused in this version; see the other implementations of this routine. }
    oldTail: Types.PItem;
begin
  bytesNeeded := 0;
  Inc(bytesNeeded, 12);
  if GDVars.treasureItems <> nil then begin
    GDVars.vaultCursor := GDVars.treasureItems;
    while GDVars.vaultCursor <> nil do begin
      Inc(bytesNeeded, 63);
      GDVars.vaultCursor := GDVars.vaultCursor^.next
    end
  end;
  DaxIo.DeleteIfPresent(name);
  if bytesNeeded > DiskFree(Ord(UpCase(GDVars.savePath[1])) - Ord('@')) then begin
    TextRend.DisplayAndPause(Yellow, Black, GDConsts.noRoomMessage);
    TextRend.DisplayAndPause(Yellow, Black, GDConsts.insertDiskMessage)
  end;
  Assign(dataFile, name);
  Rewrite(dataFile, 1);
  BlockWrite(dataFile, GDVars.pooledMoney, SizeOf(GDVars.pooledMoney));
  GDVars.vaultCursor := GDVars.treasureItems;
  while GDVars.vaultCursor <> nil do begin
    BlockWrite(dataFile, GDVars.vaultCursor^, SizeOf(Types.TItem));
    oldTail := GDVars.vaultCursor;
    GDVars.vaultCursor := GDVars.vaultCursor^.next
  end;
  Close(dataFile);
  GDVars.vaultPending := 1
end;
begin
end.
