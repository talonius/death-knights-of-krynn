{ View3D -- the dungeon view: the 3-D walls drawn from the GEO map (or the automap in their place), the backdrop and
  sky, the wall and cell queries Explore and EclVm use, and loading WALLDEF wall sets and GEO maps. }
{$O+,F+,I-}
unit View3D;
interface

{ Sets the sky, ceiling, floor and wall palette entries the backdrop is drawn in.
  @param(sky Sky color.)
  @param(ceiling Ceiling color.)
  @param(floor Floor color.)
  @param(wall Wall color.) }
procedure SetViewColors(sky, ceiling, floor, wall: Byte);

{ Fills the view's sky, floor and wall bands and draws the backdrop over them: the area's BACK picture when the
  current cell's event has bit 7 set, otherwise the sky-and-ground picture, with the evening sky over it from hour
  14. }
procedure DrawBackdrop;

{ Reads the wall type on one side of a cell: north and east share one map plane and south and west another, one nibble
  each. Off-map coordinates wrap around the 16x16 map, except in scripts 0 and 80, where they give 0.
  @param(col The map column.)
  @param(row The map row.)
  @param(side The side, one of the four compass points.)
  @returns(The wall type, 0 for none. Note: a facing other than the four compass points leaves it undefined.) }
function GetWallType(col, row: ShortInt; side: Byte): Byte;

{ Reads the barrier on one side of a cell. Off the 16x16 map it returns 0 while script 0 or 80 is loaded, and otherwise
  wraps around the edges.
  @param(col The map column.)
  @param(row The map row.)
  @param(side The side, one of the four compass points.)
  @returns(The two-bit barrier type of the wall there, or 1 when there is no wall.) }
function GetBarrierType(col, row: ShortInt; side: Byte): Byte;

{ Reads a cell's event from the 3D map. Off the 16x16 map it returns 0 while script 0 or 80 is loaded, and otherwise
  wraps around the edges.
  @param(tileX The map column.)
  @param(tileY The map row.)
  @returns(The cell event.) }
function GetMapEvent(tileX, tileY: ShortInt): Byte;

{ Draws the 3D view from a cell, or the automap while it is on. The view is the backdrop, then the walls row by row from
  two cells ahead to the party's own row: fronts, the corners between far fronts, and the side walls. It is flushed to
  the screen.
  @param(tileX Map column of the party's cell.)
  @param(tileY Map row of the party's cell.)
  @param(facing The direction the party faces.) }
procedure Display3DMapView(tileX, tileY, facing: Byte);

{ Loads a WALLDEF block, from the disk that holds it, into a wall set with its 8x8 symbol set and BACK picture, freeing
  the BIGPIC first. A missing block, or one that would run past set 4, restores the video mode, prints an error, waits
  for a key and aborts.
  @param(blockId WALLDEF block to load.)
  @param(wallset Wall set to fill, 0..3; above 3 nothing is loaded.) }
procedure LoadWallSet(blockId, wallset: Byte);

{ Loads a GEO block from the current disk's GEO archive (GEO1.DAX on disk 5) into the dungeon map and records it in zone
  0; a missing or wrong-sized block aborts as LoadWallSet does.
  @param(blockId GEO block to load.) }
procedure Load3DMap(blockId: Byte);

{ Empty routine with no callers. }
procedure NoopView3D;
implementation
uses C_Dir, GDConsts, GDVars, Crt, Sym8x8, Blit, TextRend, DaxIo, GameIo, Types;
type
  { one wall type's 156 symbol numbers, slot by slot }
  TWallSlice = array[0..155] of Byte;
  { by wall type, the nibble GetWallType returns }
  TWallSlices = array[1..20] of TWallSlice;
  PWallSlices = ^TWallSlices;
  { one WALLDEF block }
  TWallDef = array[1..5] of TWallSlice;
  { GameInit allocates three; the loader's guard admits a fourth }
  TWallDefs = array[1..4] of TWallDef;
  PWallDefs = ^TWallDefs;
var
  wallSlices: PWallSlices absolute GDVars.wallTileBuf;
  wallDefs: PWallDefs absolute GDVars.wallTileBuf;

{ The automap: the 11x11 cells around a map cell, kept on the map, each drawn as one of sixteen wall-combination
  symbols, and the party's arrow.
  @param(col Map column of the party.)
  @param(row Map row of the party.)
  @param(facing The party's facing.) }
procedure DrawAutoMap(col, row: ShortInt; facing: Byte);
var
  partyX: ShortInt;
  partyY: ShortInt;
  winX: ShortInt;
  winY: ShortInt;
  originX: ShortInt;
  originY: ShortInt;
  cellX: ShortInt;
  cellY: ShortInt;
  symbol: Integer;
  { Unused in this version; see the other implementations of this routine. }
  symbolText: array[1..256] of Byte;
begin
  originX := col - 5;
  if originX < 0 then originX := 0;
  if originX > 5 then originX := 5;
  partyX := col - originX;
  originY := row - 5;
  if originY < 0 then originY := 0;
  if originY > 5 then originY := 5;
  partyY := row - originY;
  for winY := 0 to 10 do begin
    cellY := winY + originY;
    for winX := 0 to 10 do begin
      cellX := winX + originX;
      { the sixteen wall-combination symbols, a bit per side }
      symbol := 281;
      if View3D.GetWallType(cellX, cellY, C_Dir.NORTH) > 0 then Inc(symbol);
      if View3D.GetWallType(cellX, cellY, C_Dir.EAST) > 0 then Inc(symbol, 2);
      if View3D.GetWallType(cellX, cellY, C_Dir.SOUTH) > 0 then Inc(symbol, 4);
      if View3D.GetWallType(cellX, cellY, C_Dir.WEST) > 0 then Inc(symbol, 8);
      Sym8x8.Put8x8Sym(winX + 3 - 1, winY + 3 - 1, symbol, True, Boolean(GDConsts.pictureMode));
    end;
  end;
  { the four party arrows }
  Sym8x8.Put8x8Sym(partyX + 3 - 1, partyY + 3 - 1, (facing div 2) + 297, True,
                   Boolean(GDConsts.pictureMode));
  Blit.FlushView;
end;

procedure SetViewColors(sky, ceiling, floor, wall: Byte);
begin
  GDVars.paletteSky := sky;
  GDVars.paletteCeil := ceiling;
  GDVars.paletteFloor := floor;
  GDVars.paletteWall := wall;
end;

procedure DrawBackdrop;
var
  { Unused in this version; see the other implementations of this routine. }
  hourOfDay: Word;
  boxX: Byte;
  boxY: Byte;
  { Unused in this version; see the other implementations of this routine. }
  boxRight: Byte;
  { Unused in this version; see the other implementations of this routine. }
  boxBottom: Byte;
begin
  Blit.FillPicRect(2, 16, 11, 44, GDVars.paletteSky, GDConsts.cgaColorMap, GDVars.compositeBuffer);
  Blit.FillPicRect(2, 60, 11, 2, GDVars.paletteFloor, GDConsts.cgaColorMap, GDVars.compositeBuffer);
  Blit.FillPicRect(2, 62, 11, 42, GDVars.paletteWall, GDConsts.cgaColorMap, GDVars.compositeBuffer);
  boxX := 2; boxY := 2; boxRight := 12; boxBottom := 12;
  if GDVars.mapState.event and $80 <> 0 then begin
    if GDVars.backdrop <> nil then
      Blit.BlitTileClipped(boxX, boxY, 0, GDConsts.pictureMode, GDVars.backdrop, GDVars.compositeBuffer)
  end else begin
    if GDVars.skyGround <> nil then begin
      Blit.BlitTileClipped(boxX, boxY, 0, GDConsts.pictureMode, GDVars.skyGround, GDVars.compositeBuffer);
      if GDVars.zone0^.clock[$4BC9] >= 14 then
        Blit.BlitTileClipped(boxX, boxY, 0, GDConsts.pictureMode, GDVars.eveningSky, GDVars.compositeBuffer)
    end
  end
end;

{ Draws a wall in one perspective form, its width by its height in symbols, clipped to the 11x11 view; symbol 0 is left
  transparent.
  @param(x The view column of its top left symbol.)
  @param(y The view row of its top left symbol.)
  @param(wallType The wall type, an index into the loaded wall graphics.)
  @param(slot The perspective form: 0, 3 and 6 a wall ahead at depth 2, 1 and 0; 1 and 2, 4 and 5, 7 and 8 the left and
    right side walls at those depths; 9 the far row's filler between walls.) }
procedure DrawWallSlice(x, y: ShortInt; wallType, slot: Byte);
var
  lastX: Integer;
  lastY: Integer;
  cellX: Integer;
  cellY: Integer;
  symbolIndex: Byte;
begin
  symbolIndex := GDConsts.sliceSymbolStart[slot];
  lastX := GDConsts.sliceColumns[slot] + x - 1;
  lastY := GDConsts.sliceRows[slot] + y - 1;
  for cellY := y to lastY do
    for cellX := x to lastX do begin
      if (cellY >= 0) and (cellY <= 10) and (cellX >= 0) and (cellX <= 10) then
        if wallSlices^[wallType][symbolIndex] > 0 then
          Sym8x8.Put8x8Sym(cellX + 3 - 1, cellY + 3 - 1, wallSlices^[wallType][symbolIndex], True,
                           Boolean(GDConsts.iconFrame));
      Inc(symbolIndex);
    end;
end;

{ Tells whether a cell is on the 16x16 map.
  @param(col The map column.)
  @param(row The map row.)
  @returns(True when the cell is on the map.) }
function Valid3DCoords(col, row: ShortInt): Boolean;
begin
  if (col > 15) or (col < 0) or (row > 15) or (row < 0) then
    Valid3DCoords := False
  else
    Valid3DCoords := True;
end;

function GetBarrierType(col, row: ShortInt; side: Byte): Byte;
var
  barrier: Byte;
begin
  if (not View3D.Valid3DCoords(col, row))
     and ((GDVars.currentScriptId = 0) or (GDVars.currentScriptId = 80)) then begin
    GetBarrierType := 0;
    Exit;
  end;
  if col > 15 then col := 0 else if col < 0 then col := 15;
  if row > 15 then row := 0 else if row < 0 then row := 15;
  barrier := 1;
  if View3D.GetWallType(col, row, side) > 0 then
    case side of
      C_Dir.WEST: barrier := (GDVars.dungeonMap^.barriers[row, col] and $C0) shr 6;
      C_Dir.SOUTH: barrier := (GDVars.dungeonMap^.barriers[row, col] and $30) shr 4;
      C_Dir.EAST: barrier := (GDVars.dungeonMap^.barriers[row, col] and $0C) shr 2;
      C_Dir.NORTH: barrier := GDVars.dungeonMap^.barriers[row, col] and $03;
    end;
  GetBarrierType := barrier;
end;

function GetWallType(col, row: ShortInt; side: Byte): Byte;
begin
  if (not View3D.Valid3DCoords(col, row))
     and ((GDVars.currentScriptId = 0) or (GDVars.currentScriptId = 80)) then begin
    GetWallType := 0;
    Exit;
  end;
  if col > 15 then col := 0 else if col < 0 then col := 15;
  if row > 15 then row := 0 else if row < 0 then row := 15;
  case side of
    C_Dir.NORTH: GetWallType := (GDVars.dungeonMap^.wallsNorthEast[row, col] and $F0) shr 4;
    C_Dir.EAST: GetWallType := GDVars.dungeonMap^.wallsNorthEast[row, col] and $0F;
    C_Dir.SOUTH: GetWallType := (GDVars.dungeonMap^.wallsSouthWest[row, col] and $F0) shr 4;
    C_Dir.WEST: GetWallType := GDVars.dungeonMap^.wallsSouthWest[row, col] and $0F;
  end;
end;

function GetMapEvent(tileX, tileY: ShortInt): Byte;
begin
  if (not View3D.Valid3DCoords(tileX, tileY))
     and ((GDVars.currentScriptId = 0) or (GDVars.currentScriptId = 80)) then begin
    GetMapEvent := 0;
    Exit;
  end;
  if tileX > 15 then tileX := 0 else if tileX < 0 then tileX := 15;
  if tileY > 15 then tileY := 0;
  if tileY < 0 then tileY := 15;
  GetMapEvent := GDVars.dungeonMap^.events[tileY, tileX];
end;

procedure Display3DMapView(tileX, tileY, facing: Byte);
var
  leftFacing: Byte;
  rightFacing: Byte;
  backFacing: Byte;
  currentX: Integer;
  currentY: Integer;
  forwardDx: Integer;
  forwardDy: Integer;
  cellX: Integer;
  cellY: Integer;
  lateral: Byte;
  xOffset: Integer;
  depth: Byte;
  frontWall: Byte;
  sideWall: Byte;
  { Unused in this version; see the other implementations of this routine. }
  wallBack: Byte;
  previousWall: Byte;
begin
  if GDVars.automapOn <> 0 then begin
    View3D.DrawAutoMap(tileX, tileY, facing);
    Exit;
  end;
  View3D.DrawBackdrop;
  leftFacing := (facing + 6) mod 8;
  backFacing := (facing + 4) mod 8;
  rightFacing := (facing + 2) mod 8;
  currentX := ShortInt(tileX);
  currentY := ShortInt(tileY);
  forwardDx := GDConsts.combatTables.directionX[facing];
  forwardDy := GDConsts.combatTables.directionY[facing];
  depth := 2;
  Inc(currentX, depth * forwardDx);
  Inc(currentY, depth * forwardDy);
  repeat
    case depth of
    2:
    begin
      cellX := currentX; cellY := currentY; lateral := 0; xOffset := 0; previousWall := 0;
      while lateral < 4 do begin
        frontWall := View3D.GetWallType(cellX, cellY, facing);
        if not View3D.Valid3DCoords(cellX, cellY) then
          if View3D.GetWallType(cellX, cellY, rightFacing) = 0 then previousWall := 0;
        if frontWall <> 0 then begin
          if previousWall >
              0 then View3D.DrawWallSlice(GDConsts.sliceX[9] + xOffset + 1, GDConsts.sliceY[9], previousWall, 9);
          previousWall := frontWall;
          View3D.DrawWallSlice(GDConsts.sliceX[0] + xOffset, GDConsts.sliceY[0], frontWall, 0);
        end else begin
          if previousWall > 0 then
            if View3D.GetWallType(cellX - GDConsts.combatTables.directionX[leftFacing],
                         cellY - GDConsts.combatTables.directionY[leftFacing], leftFacing) <> 0 then
              View3D.DrawWallSlice(GDConsts.sliceX[9] + xOffset + 1, GDConsts.sliceY[9], previousWall, 9);
          previousWall := 0;
        end;
        Inc(lateral); Dec(xOffset, 2);
        cellX := cellX + GDConsts.combatTables.directionX[leftFacing];
        cellY := cellY + GDConsts.combatTables.directionY[leftFacing];
      end;
      cellX := currentX; cellY := currentY; lateral := 0; xOffset := 0; previousWall := 0;
      while lateral < 4 do begin
        frontWall := View3D.GetWallType(cellX, cellY, facing);
        if not View3D.Valid3DCoords(cellX, cellY) then
          if View3D.GetWallType(cellX, cellY, leftFacing) = 0 then previousWall := 0;
        if frontWall <> 0 then begin
          if previousWall >
              0 then View3D.DrawWallSlice(GDConsts.sliceX[9] + xOffset - 1, GDConsts.sliceY[9], previousWall, 9);
          previousWall := frontWall;
          View3D.DrawWallSlice(GDConsts.sliceX[0] + xOffset, GDConsts.sliceY[0], frontWall, 0);
        end else begin
          if previousWall > 0 then
            if View3D.GetWallType(cellX - GDConsts.combatTables.directionX[rightFacing],
                         cellY - GDConsts.combatTables.directionY[rightFacing], rightFacing) <> 0 then
              View3D.DrawWallSlice(GDConsts.sliceX[9] + xOffset - 1, GDConsts.sliceY[9], previousWall, 9);
          previousWall := 0;
        end;
        Inc(lateral); Inc(xOffset, 2);
        cellX := cellX + GDConsts.combatTables.directionX[rightFacing];
        cellY := cellY + GDConsts.combatTables.directionY[rightFacing];
      end;
      cellX := currentX; cellY := currentY; lateral := 0; xOffset := 0;
      while lateral < 3 do begin
        sideWall := View3D.GetWallType(cellX, cellY, leftFacing);
        if sideWall <> 0 then
          if lateral = 0 then View3D.DrawWallSlice(GDConsts.sliceX[1] + xOffset, GDConsts.sliceY[1], sideWall, 1)
          else View3D.DrawWallSlice(GDConsts.sliceX[1] + xOffset - 1, GDConsts.sliceY[1], sideWall, 1);
        Inc(lateral); Dec(xOffset, 2);
        cellX := cellX + GDConsts.combatTables.directionX[leftFacing];
        cellY := cellY + GDConsts.combatTables.directionY[leftFacing];
      end;
      cellX := currentX; cellY := currentY; lateral := 0; xOffset := 0;
      while lateral < 3 do begin
        sideWall := View3D.GetWallType(cellX, cellY, rightFacing);
        if sideWall <> 0 then
          if lateral = 0 then View3D.DrawWallSlice(GDConsts.sliceX[2] + xOffset, GDConsts.sliceY[2], sideWall, 2)
          else View3D.DrawWallSlice(GDConsts.sliceX[2] + xOffset + 1, GDConsts.sliceY[2], sideWall, 2);
        Inc(lateral); Inc(xOffset, 2);
        cellX := cellX + GDConsts.combatTables.directionX[rightFacing];
        cellY := cellY + GDConsts.combatTables.directionY[rightFacing];
      end;
    end;
    1:
    begin
      cellX := currentX + GDConsts.combatTables.directionX[leftFacing];
      cellX := cellX + GDConsts.combatTables.directionX[leftFacing];
      cellY := currentY + GDConsts.combatTables.directionY[leftFacing];
      cellY := cellY + GDConsts.combatTables.directionY[leftFacing];
      lateral := 0;
      xOffset := -6;
      while lateral < 3 do begin
        frontWall := View3D.GetWallType(cellX, cellY, facing);
        if frontWall <> 0 then View3D.DrawWallSlice(GDConsts.sliceX[3] + xOffset, GDConsts.sliceY[3], frontWall, 3);
        sideWall := View3D.GetWallType(cellX, cellY, leftFacing);
        if sideWall <> 0 then View3D.DrawWallSlice(GDConsts.sliceX[4] + xOffset, GDConsts.sliceY[4], sideWall, 4);
        Inc(lateral); Inc(xOffset, 3);
        cellX := cellX + GDConsts.combatTables.directionX[rightFacing];
        cellY := cellY + GDConsts.combatTables.directionY[rightFacing];
      end;
      cellX := currentX + GDConsts.combatTables.directionX[rightFacing];
      cellX := cellX + GDConsts.combatTables.directionX[rightFacing];
      cellY := currentY + GDConsts.combatTables.directionY[rightFacing];
      cellY := cellY + GDConsts.combatTables.directionY[rightFacing];
      lateral := 0;
      xOffset := 6;
      while lateral < 3 do begin
        frontWall := View3D.GetWallType(cellX, cellY, facing);
        if frontWall <> 0 then View3D.DrawWallSlice(GDConsts.sliceX[3] + xOffset, GDConsts.sliceY[3], frontWall, 3);
        sideWall := View3D.GetWallType(cellX, cellY, rightFacing);
        if sideWall <> 0 then View3D.DrawWallSlice(GDConsts.sliceX[5] + xOffset, GDConsts.sliceY[5], sideWall, 5);
        Inc(lateral); Dec(xOffset, 3);
        cellX := cellX + GDConsts.combatTables.directionX[leftFacing];
        cellY := cellY + GDConsts.combatTables.directionY[leftFacing];
      end;
    end;
    0:
    begin
      cellX := currentX + GDConsts.combatTables.directionX[leftFacing];
      cellY := currentY + GDConsts.combatTables.directionY[leftFacing];
      lateral := 0; xOffset := -7;
      while lateral < 2 do begin
        frontWall := View3D.GetWallType(cellX, cellY, facing);
        if frontWall <> 0 then View3D.DrawWallSlice(GDConsts.sliceX[6] + xOffset, GDConsts.sliceY[6], frontWall, 6);
        sideWall := View3D.GetWallType(cellX, cellY, leftFacing);
        if sideWall <> 0 then View3D.DrawWallSlice(GDConsts.sliceX[7] + xOffset, GDConsts.sliceY[7], sideWall, 7);
        Inc(lateral); Inc(xOffset, 7);
        cellX := cellX + GDConsts.combatTables.directionX[rightFacing];
        cellY := cellY + GDConsts.combatTables.directionY[rightFacing];
      end;
      cellX := currentX + GDConsts.combatTables.directionX[rightFacing];
      cellY := currentY + GDConsts.combatTables.directionY[rightFacing];
      lateral := 0; xOffset := 7;
      while lateral < 2 do begin
        frontWall := View3D.GetWallType(cellX, cellY, facing);
        if frontWall <> 0 then View3D.DrawWallSlice(GDConsts.sliceX[6] + xOffset, GDConsts.sliceY[6], frontWall, 6);
        sideWall := View3D.GetWallType(cellX, cellY, rightFacing);
        if sideWall <> 0 then View3D.DrawWallSlice(GDConsts.sliceX[8] + xOffset, GDConsts.sliceY[8], sideWall, 8);
        Inc(lateral); Dec(xOffset, 7);
        cellX := cellX + GDConsts.combatTables.directionX[leftFacing];
        cellY := cellY + GDConsts.combatTables.directionY[leftFacing];
      end;
    end;
    end;
    currentX := currentX + GDConsts.combatTables.directionX[backFacing];
    currentY := currentY + GDConsts.combatTables.directionY[backFacing];
    Dec(depth);
  until depth = 255;
  Blit.FlushView;
end;

{ Loads the area's BACK picture, from the archive named by the suffix, as the backdrop.
  @param(blockId BACK block to load.)
  @param(suffix Disk digit of the archive.) }
procedure LoadBackdrop(blockId: Byte; suffix: Types.TString2);
var
  name: String[5];
begin
  name := 'back' + suffix;
  Blit.LoadPic(name, blockId, Boolean(GDConsts.pictureMode), GDVars.paletteSky, GDVars.backdrop);
end;

procedure NoopView3D;
begin
end;

procedure LoadWallSet(blockId, wallset: Byte);
var
  dataSize: Word;
  data: Types.PBytes;
  readOfs: Word;
  { Unused in this version; see the other implementations of this routine. }
  symbolSetDelta: Integer;
  { Unused in this version; see the other implementations of this routine. }
  row: Byte;
  defIndex: Word;
  { Unused in this version; see the other implementations of this routine. }
  column: Word;
  { Unused in this version; see the other implementations of this routine. }
  defCount: Byte;
  suffix: string[1];
  { Unused in this version; see the other implementations of this routine. }
  key: Byte;
begin
  if GDVars.bigPic <> nil then begin
    Blit.FreePic(GDVars.bigPic);
    GDVars.bigId := 255
  end;
  if wallset > 3 then Exit;
  { the disk each WALLDEF block is on }
  case blockId of
    1: suffix := '1';
    2: suffix := '4';
    3, 4: suffix := '2';
    5, 6: suffix := '3';
    7: suffix := '5';
  end;
  TextRend.PrintSpaces(GDConsts.messageColumn, GDConsts.messageRow, Black, GDConsts.screenWidth);
  TextRend.DisplayString(GDConsts.messageColumn, GDConsts.messageRow, LightGreen, Black, GDConsts.loadingMessage);
  DaxIo.LoadDax('WALLDEF' + suffix, GDConsts.daxExtension, blockId, dataSize, Types.PBytes(data));
  if (dataSize = 0) or ((dataSize div SizeOf(TWallDef)) + wallset > 4) then begin
    Blit.RestoreVideoMode;
    WriteLn('Unable to load ', blockId, ' from WALLDEF' + suffix + '.');
    key := Byte(GameIo.ReadGameKey);
    Blit.RestoreVideoMode;
    GameIo.ExitGame
  end;
  { computed, never read }
  symbolSetDelta := Integer(GDConsts.symbolSetFirst[wallset]) - Integer(GDConsts.symbolSetFirst[1]);
  readOfs := 0;
  defIndex := 1;
  repeat
    Move(data^[readOfs], wallDefs^[wallset + defIndex], SizeOf(TWallDef));
    Inc(readOfs, SizeOf(TWallDef));
    Inc(defIndex)
  until readOfs >= dataSize;
  FreeMem(data, dataSize);
  defCount := defIndex - 1;
  Sym8x8.Load8x8Set(blockId, wallset);
  View3D.LoadBackdrop(blockId, suffix);
  GDVars.loadedWallSets[wallset].blockId := blockId;
  GDVars.loadedWallSets[wallset].slot := wallset
end;

procedure Load3DMap(blockId: Byte);
var
  dataSize: Word;
  data: Types.PBytes;
  readOfs: Word;
  suffix: string[1];
  { Unused in this version; see the other implementations of this routine. }
  key: Byte;
begin
  if GDVars.diskNumber = 5 then suffix := '1'
  else Str(GDVars.diskNumber, suffix);
  DaxIo.LoadDax('GEO' + suffix, GDConsts.daxExtension, blockId, dataSize, Types.PBytes(data));
  if (dataSize = 0) or (dataSize <> SizeOf(Types.TGeoMap) + 2) then begin
    Blit.RestoreVideoMode;
    WriteLn('Unable to load geo in Load3DMap.');
    key := Byte(GameIo.ReadGameKey);
    Blit.RestoreVideoMode;
    GameIo.ExitGame;
  end;
  readOfs := 2;
  Move(data^[readOfs], GDVars.dungeonMap^.wallsNorthEast, SizeOf(Types.TGeoPlane)); Inc(readOfs,
                                                                                          SizeOf(Types.TGeoPlane));
  Move(data^[readOfs], GDVars.dungeonMap^.wallsSouthWest, SizeOf(Types.TGeoPlane)); Inc(readOfs,
                                                                                          SizeOf(Types.TGeoPlane));
  Move(data^[readOfs], GDVars.dungeonMap^.events, SizeOf(Types.TGeoPlane)); Inc(readOfs, SizeOf(Types.TGeoPlane));
  Move(data^[readOfs], GDVars.dungeonMap^.barriers, SizeOf(Types.TGeoPlane));
  FreeMem(data, dataSize);
  GDVars.zone0^.geoMap := blockId;
end;
begin
end.
