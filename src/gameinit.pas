{ GameInit -- the game's initialization after start-up (InitializeGame, from FixMain) and the reset between games
  (ResetGameState). }
{$O+,F+,I-}
unit GameInit;
interface
uses C_Dir, C_Ifc, C_Music, C_Video, GDConsts, GDVars, Mouse, Blit, TextRend, MenuCore,
  Sym8x8, MapTiles, DaxIo, GameIo, Magic, EffHndlr, Crt, Types;

{ Sets the menu colors, clears the item pool, turns Num-Lock on and seeds Random. Sets up the mouse -- the cursor mask
  for the adapter, and mouseScaled set when the driver, placed at x 639, reads back below 321 -- and centers the
  joystick. Allocates the four GBVM zones, the font, the wall tiles, the dungeon map, the graphics buffers and the music
  buffers; builds the CGA, Tandy and frame-buffer row tables; clears the zones and sets the starting state (difficulty
  3, in the dungeon, every moon at phase 2, the party at (7, 13) facing north, wall set 0 loaded, disk 5) and the
  session's defaults. Then loads the font, the 8x8 symbols, 22 combat sprites, the cursor and sky pictures, the ITEMS
  base-item table (read whether or not the file was found), the spell services, the effect handlers and the item
  templates. }
procedure InitializeGame;

{ Resets for a new game as InitializeGame does, except that the party faces east, the disk is 1, and wall set 1 is
  marked loaded and 2..3 empty, set 0 left as it was. }
procedure ResetGameState;
implementation
var
  biosKbdFlags: Byte absolute $0000: $0417;

{ Copies the templates in ITEM0.DAX entry 1 into the item template table from 1, at most 127; aborts if the entry is
  missing. }
procedure LoadItems;
var
  size: Word;
  readOfs: Word;
  index: Byte;
  buf: Types.PBytes;
  item: Types.TItemTemplate;
begin
  FillChar(GDVars.itemTemplates, SizeOf(GDVars.itemTemplates), $FF);
  DaxIo.LoadDax('ITEM0', GDConsts.daxExtension, 1, size, buf);
  if size = 0 then begin
    TextRend.DisplayAndPause(White, Black, GDConsts.itemError);
    GameIo.ExitGame
  end;
  readOfs := 0;
  index := 1;
  repeat
    Move(buf^[readOfs], item, SizeOf(item));
    GDVars.itemTemplates[index] := item;
    Inc(index);
    Inc(readOfs, SizeOf(item))
  until (readOfs >= size) or (index > 127);
  FreeMem(buf, size)
end;

procedure InitializeGame;
var
  { Unused in this version; see the other implementations of this routine. }
  scratch: string;
begin
  GDVars.menuItemColor := LightGreen;
  GDVars.menuLabelColor := LightMagenta;
  GDVars.menuHighlightColor := White;
  FillChar(GDVars.itemPool, SizeOf(GDVars.itemPool), 0);
  biosKbdFlags := biosKbdFlags or GDConsts.numLockBit;
  Randomize;
  if GDVars.mousePresent <> 0 then begin
    GDVars.mouseMode := 1;
    GDVars.mouseButtonCount := 0;
    Mouse.InitMouse;
    if GDVars.mousePresent <> 0 then begin
      GDVars.mouseScaled := True;
      if GDVars.displayMode = Types.Cga then
        GDVars.activeCursorMask := @GDConsts.cursorMaskCga
      else
        GDVars.activeCursorMask := @GDConsts.cursorMaskEga;
      Mouse.SetMouseCursor(0, 0, Types.PCursorMask(GDVars.activeCursorMask));
      Mouse.SetMouse(639, 100);
      Mouse.GetMouse(GDVars.mouseButtons, GDVars.mouseSampleX, GDVars.mouseSampleY);
      GDVars.mouseScaled := (GDVars.mouseSampleX >= 321) = False;
      Mouse.ShowMouse;
    end;
    GDVars.mouseRawX := 160;
    GDVars.mouseRawY := 100;
    Mouse.SetMouse(GDVars.mouseRawX, GDVars.mouseRawY);
    GDVars.mouseCurrentX := 0;
    GDVars.mouseCurrentY := 0;
  end;
  if GDVars.joystickActive <> 0 then begin
    GDVars.joystickCenterX := 160;
    GDVars.joystickCenterY := 100;
  end;
  GetMem(GDVars.zone0, SizeOf(Types.TZone0));
  GetMem(GDVars.zone1, SizeOf(Types.TZone1));
  GetMem(GDVars.zone2, SizeOf(Types.TZone2));
  GetMem(GDVars.zone3, SizeOf(Types.TZone3));
  GetMem(GDVars.gameFont, 1416);
  GetMem(GDVars.wallTileBuf, 2340);
  GetMem(GDVars.dungeonMap, 1024);
  Blit.AllocPic(8, 1, 1, GDConsts.pictureMode, GDVars.symbolScratch);
  Blit.AllocPic(8, 1, 1, GDConsts.pictureMode, GDVars.viewCapture);
  Blit.AllocPic(8, 1, 1, GDConsts.pictureMode, GDVars.viewComposite);
  GDVars.cursorImage := nil;
  Blit.AllocPic(168, 21, 1, GDConsts.pictureMode, GDVars.compositeBuffer);
  Blit.AllocPic(24, 3, 1, GDConsts.pictureMode, GDVars.saveUnder);
  FillChar(GDVars.spanActive, SizeOf(GDVars.spanActive), 0);
  FillChar(GDVars.spanY, SizeOf(GDVars.spanY), 0);
  FillChar(GDVars.spanX0, SizeOf(GDVars.spanX0), $FF);
  FillChar(GDVars.spanX1, SizeOf(GDVars.spanX1), 0);
  for GDVars.initIndex := 0 to 199 do begin
    if Odd(GDVars.initIndex) then
      GDVars.cgaRowSeg[GDVars.initIndex] := (GDVars.initIndex div 2) * 5 + C_Video.GFX_BANK1_SEG
    else
      GDVars.cgaRowSeg[GDVars.initIndex] := (GDVars.initIndex div 2) * 5 + C_Video.GFX_BANK0_SEG;
    GDVars.fbRowOfs[GDVars.initIndex] := GDVars.initIndex * 40;
    case GDVars.initIndex mod 4 of
      0: GDVars.tandyRowSeg[GDVars.initIndex] := (GDVars.initIndex div 4) * 10 + C_Video.GFX_BANK0_SEG;
      1: GDVars.tandyRowSeg[GDVars.initIndex] := (GDVars.initIndex div 4) * 10 + C_Video.GFX_BANK1_SEG;
      2: GDVars.tandyRowSeg[GDVars.initIndex] := (GDVars.initIndex div 4) * 10 + C_Video.GFX_BANK2_SEG;
      3: GDVars.tandyRowSeg[GDVars.initIndex] := (GDVars.initIndex div 4) * 10 + C_Video.GFX_BANK3_SEG;
    end;
  end;
  GDVars.musicDriverBuf := nil;
  GDVars.musicDataBuf := nil;
  GetMem(GDVars.musicDriverBuf, C_Music.DRIVER_BUFFER_SIZE);
  GetMem(GDVars.musicDataBuf, C_Music.DATA_BUFFER_SIZE);
  FillChar(GDVars.backdrop, SizeOf(GDVars.backdrop) + SizeOf(GDVars.skyGround), 0);
  FillChar(GDVars.eveningSky, SizeOf(GDVars.eveningSky), 0);
  FillChar(GDVars.symbolSets, SizeOf(GDVars.symbolSets), 0);
  FillChar(GDVars.tileSheet, SizeOf(GDVars.tileSheet), 0);
  Blit.AllocPic(24, 3, 40, GDConsts.pictureMode, GDVars.tileSheet);
  FillChar(GDVars.zone0^, SizeOf(Types.TZone0), 0);
  GDVars.zone0^.difficulty := 3;
  GDVars.zone0^.inDungeon := 1;
  GDVars.zone0^.scriptId := 0;
  GDVars.zone0^.moonPhase[$4CF9] := 2;
  GDVars.zone0^.moonPhase[$4CFA] := 2;
  GDVars.zone0^.moonPhase[$4CFB] := 2;
  FillChar(GDVars.zone1^, SizeOf(Types.TZone1), 0);
  FillChar(GDVars.zone2^, SizeOf(Types.TZone2), 0);
  FillChar(GDVars.zone3^, SizeOf(Types.TZone3), 0);
  FillChar(GDVars.iconAnimations, SizeOf(GDVars.iconAnimations), 0);
  FillChar(GDVars.portraitAnimation, SizeOf(Types.TAnimRec), 0);
  GDVars.bigPic := nil;
  GDVars.treasureItems := nil;
  FillChar(GDVars.mapState, SizeOf(GDVars.mapState), 0);
  GDVars.mapState.x := 7;
  GDVars.mapState.y := 13;
  GDVars.mapState.facing := C_Dir.NORTH;
  GDVars.loadedWallSets[0].blockId := 0;
  GDVars.loadedWallSets[0].slot := 1;
  for GDVars.initIndex := 1 to 3 do begin
    GDVars.loadedWallSets[GDVars.initIndex].blockId := 65535;
    GDVars.loadedWallSets[GDVars.initIndex].slot := 65535;
  end;
  GDVars.gameUp := 0;
  GDVars.animationsEnabled := 1;
  GDVars.picturesEnabled := 1;
  GDVars.traceActive := 0;
  GDVars.slowText := 1;
  GDVars.loadedSave := 0;
  GDVars.restTicks := 0;
  GDVars.partyHead := nil;
  GDVars.currentCharacter := nil;
  GDVars.tradeCharacter := nil;
  GDVars.highlightedCharacter := nil;
  GDVars.mouseCharacter := nil;
  GDVars.eclIp := $8000;
  GDVars.textDelay := 4;
  GDVars.demoMode := 0;
  GDVars.diskNumber := 5;
  GDVars.previousDisk := 1;
  GDVars.automapOn := 0;
  LastMode := 1;
  GDVars.zone1^.partySize[$7F3E] := 0;
  GDVars.menuVerticalTop := 1;
  GDVars.duelFlag := 0;
  GDVars.noBorder := 0;
  GDVars.savedSearchFlag := 0;
  GDVars.boxCleared := 0;
  GDVars.printReturnFlag := 0;
  GDVars.eclGraphics := 0;
  GDVars.partyDefeated := 0;
  GDVars.soundInitByte := 1;
  GDVars.spriteShown := 0;
  GDVars.suppressDisk := 0;
  GDVars.pictureArchiveName[0] := #0;
  GDVars.savedPictureName[0] := #0;
  GDVars.pictureArchiveId := 255;
  GDVars.savedPictureId := 255;
  GDVars.recentlySaved := 0;
  GDVars.ceilingFloorColorSet := $E8;
  GDVars.wallColorSet := $DB;
  GDVars.inEncounterMenu := 0;
  GDVars.selectionMode := 0;
  GDVars.showTurn := 1;
  GDVars.bigId := 255;
  GDVars.markerInitByte := 0;
  GDVars.autoTraining := 0;
  GDVars.selectedChoice := 1;
  GDVars.interfaceState := C_Ifc.VIEW_3D;
  GDVars.previousInterfaceState := C_Ifc.MAIN_MENU;
  GDVars.handlerOverrideActive := 0;
  GDVars.bigPictureShown := 0;
  GDVars.eclInitByte := 0;
  GDVars.inMoveMenu := 0;
  GDVars.cursorActive := 0;
  GDVars.extendedMode := 0;
  GDVars.mouseClick := 0;
  GDVars.modifyActive := 0;
  GDVars.musicOn := 1;
  GDVars.savedSoundActive := 0;
  GDVars.soundActive := 0;
  GDVars.musicDriverLoaded := 0;
  GDVars.agePassFlag := 0;
  GDVars.campRestActive := False;
  GDVars.currentMusic := 255;
  GDVars.dungeonCombatLoaded := 0;
  GDVars.wildernessCombatLoaded := 0;
  GDVars.vaultPending := 0;
  GDVars.vaultLetter := 'Q';
  GDVars.musicData := nil;
  GDVars.musicDataSize := 0;
  TextRend.LoadGameFont;
  MenuCore.ClearBottomLine;
  TextRend.DisplayString(GDConsts.messageColumn, GDConsts.messageRow, LightGreen, Black, GDConsts.loadingMessage);
  Sym8x8.load8x8Set(202, 4);
  for GDVars.initIndex := 0 to 21 do
    MapTiles.loadIconAnim('COMSPR', GDVars.initIndex, GDVars.initIndex + 13);
  Blit.LoadPic('8x8d1', 204, Boolean(GDConsts.pictureMode), LightMagenta, GDVars.cursorImage);
  Blit.LoadPic('skygrnd', 1, Boolean(GDConsts.pictureMode), LightMagenta, GDVars.eveningSky);
  Blit.LoadPic('skygrnd', 2, Boolean(GDConsts.pictureMode), GDVars.paletteSky, GDVars.skyGround);
  GDVars.itemsOk := DaxIo.OpenWithRetry('ITEMS', GDConsts.insertDiskMessages[GDVars.diskNumber], #0, GDVars.itemsFile);
  Reset(GDVars.itemsFile, 1);
  Seek(GDVars.itemsFile, 2);
  BlockRead(GDVars.itemsFile, GDVars.baseItems, SizeOf(GDVars.baseItems), GDVars.itemsRead);
  Close(GDVars.itemsFile);
  GDVars.magicOn := 0;
  Magic.InitSpellFns;
  EffHndlr.InitEffectHandlers;
  GameInit.LoadItems;
end;

procedure ResetGameState;
begin
  FillChar(GDVars.itemPool, SizeOf(GDVars.itemPool), 0);
  GDVars.gameUp := 1;
  FillChar(GDVars.spanActive, SizeOf(GDVars.spanActive), 0);
  FillChar(GDVars.spanY, SizeOf(GDVars.spanY), 0);
  FillChar(GDVars.spanX0, SizeOf(GDVars.spanX0), $FF);
  FillChar(GDVars.spanX1, SizeOf(GDVars.spanX1), 0);
  FillChar(GDVars.zone0^, SizeOf(Types.TZone0), 0);
  GDVars.zone0^.difficulty := 3;
  GDVars.zone0^.inDungeon := 1;
  GDVars.zone0^.scriptId := 0;
  FillChar(GDVars.zone1^, SizeOf(Types.TZone1), 0);
  FillChar(GDVars.zone2^, SizeOf(Types.TZone2), 0);
  FillChar(GDVars.zone3^, SizeOf(Types.TZone3), 0);
  FillChar(GDVars.mapState, SizeOf(GDVars.mapState), 0);
  GDVars.mapState.x := 7;
  GDVars.mapState.y := 13;
  GDVars.mapState.facing := C_Dir.EAST;
  GDVars.mouseMode := 1;
  GDVars.loadedWallSets[1].blockId := 0;
  GDVars.loadedWallSets[1].slot := 1;
  for GDVars.initIndex := 2 to 3 do begin
    GDVars.loadedWallSets[GDVars.initIndex].blockId := 65535;
    GDVars.loadedWallSets[GDVars.initIndex].slot := 65535;
  end;
  GDVars.traceActive := 0;
  GDVars.zone0^.moonPhase[$4CF9] := 2;
  GDVars.zone0^.moonPhase[$4CFA] := 2;
  GDVars.zone0^.moonPhase[$4CFB] := 2;
  GDVars.slowText := 1;
  GDVars.loadedSave := 0;
  GDVars.restTicks := 0;
  GDVars.partyHead := nil;
  GDVars.currentCharacter := nil;
  GDVars.tradeCharacter := nil;
  GDVars.highlightedCharacter := nil;
  GDVars.mouseCharacter := nil;
  GDVars.eclIp := $8000;
  GDVars.textDelay := 4;
  GDVars.diskNumber := 1;
  GDVars.previousDisk := 1;
  GDVars.automapOn := 0;
  LastMode := 1;
  GDVars.zone1^.partySize[$7F3E] := 0;
  GDVars.menuVerticalTop := 1;
  GDVars.duelFlag := 0;
  GDVars.noBorder := 0;
  GDVars.savedSearchFlag := 0;
  GDVars.boxCleared := 0;
  GDVars.printReturnFlag := 0;
  GDVars.eclGraphics := 0;
  GDVars.partyDefeated := 0;
  GDVars.soundInitByte := 1;
  GDVars.spriteShown := 0;
  GDVars.suppressDisk := 0;
  GDVars.pictureArchiveName[0] := #0;
  GDVars.savedPictureName[0] := #0;
  GDVars.pictureArchiveId := 255;
  GDVars.savedPictureId := 255;
  GDVars.recentlySaved := 0;
  GDVars.ceilingFloorColorSet := $E8;
  GDVars.wallColorSet := $DB;
  GDVars.inEncounterMenu := 0;
  GDVars.showTurn := 1;
  GDVars.bigId := 255;
  GDVars.markerInitByte := 0;
  GDVars.autoTraining := 0;
  MenuCore.ClearBottomLine;
  GDVars.selectedChoice := 1;
  GDVars.interfaceState := C_Ifc.VIEW_3D;
  GDVars.previousInterfaceState := C_Ifc.MAIN_MENU;
  GDVars.handlerOverrideActive := 0;
  GDVars.eclInitByte := 0;
  GDVars.inMoveMenu := 0;
  GDVars.cursorActive := 0;
  GDVars.extendedMode := 0;
  GDVars.mouseClick := 0;
  GDVars.selectionMode := 0;
  GDVars.modifyActive := 0;
  GDVars.bigPictureShown := 0;
  GDVars.agePassFlag := 0;
  GDVars.vaultPending := 0;
  GDVars.vaultLetter := 'Q';
end;
begin
end.
