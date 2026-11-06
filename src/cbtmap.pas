{ CbtMap -- the combat map: the 7x7-cell view over the 50x25 arena, scrolled to keep a creature in sight, drawing
  terrain (with clouds and fallen bodies over it), creature icons and the target cursor; where each creature stands and
  which arena cells its icon covers; directions between cells; and a creature going down. }
{$O+,F+,A-}
unit CbtMap;
interface
uses C_Dir, C_Ifc, C_Terr, Types, GDConsts, GDVars, Blit, MapTiles, Music, TextRend, Crt;

{ Gives the direction from one combatant's arena cell to another's.
  @param(src The combatant looked from.)
  @param(dst The combatant looked at.)
  @returns(The direction 0..7.) }
function DirectionToward(src, dst: Types.PCharacter): Byte;

{ Gives the direction, clockwise from north, from one point to another: the first of the eight whose sector holds the
  second. The tests multiply by 106 or 618 and divide by 256: 106/256 and 618/256 approximate tan 22.5 and tan 67.5
  degrees.
  @param(x1 The column looked from.)
  @param(y1 The row looked from.)
  @param(x2 The column looked at.)
  @param(y2 The row looked at.)
  @returns(The direction 0..7.) }
function DirectionBetween(x1, y1, x2, y2: Integer): Byte;

{ Returns the terrain at an arena cell, looking under a cloud (28, 29) or a fallen body (31) to what lies beneath.
  @param(x Arena column.)
  @param(y Arena row.)
  @returns(The terrain index.) }
function ResolveTerrain(x, y: ShortInt): Byte;

{ Empty routine with no callers. }
procedure NoopCbtMapA;

{ Empty routine with no callers. }
procedure NoopCbtMapB;

{ Finds where one tile of a creature icon lies relative to the icon's upper-left cell.
  @param(size The icon size; 0 for no icon.)
  @param(idx The tile, 0 to 3.)
  @param(dx Receives the tile's column offset; left as it was for size 0.)
  @param(dy Receives the tile's row offset; left as it was for size 0.)
  @returns(True when the icon uses the tile; False for size 0 or an unused tile, whose column offset is negative.) }
function GetIconTileDelta(size, idx: Byte; var dx, dy: ShortInt): Boolean;

{ Recomputes each arena creature's view coordinates from its arena cell and the view's upper-left cell. }
procedure CalcGridDeltas;

{ Empty routine. }
procedure SetCombatPalette;

{ Empty routine. }
procedure SetNoncombatPalette;

{ Repaints the terrain under the cursor's footprint at an arena cell, draws the cursor there when it is on, then redraws
  the creature standing on the cell if it is visible.
  @param(x Arena column of the cell.)
  @param(y Arena row of the cell.) }
procedure DrawCursorCell(x, y: ShortInt);

{ Redraws one arena cell: repaints its terrain (the whole icon footprint when a creature stands there, through
  UpdateCombatMapTile), then the creature's sprite if it is visible.
  @param(x Arena column of the cell.)
  @param(y Arena row of the cell.) }
procedure RedrawArenaCell(x, y: ShortInt);

{ Rebuilds the arena's creature-index grid: clears it, then for each creature with a nonzero icon size marks every cell
  its icon covers with the creature's combat slot and recomputes the creature's view coordinates. }
procedure BuildArenaArrays;

{ Looks up what lies on an arena cell.
  @param(x Arena column of the cell.)
  @param(y Arena row of the cell.)
  @param(crIdx Receives the combat slot of the creature standing there; 0 for none or outside the arena.)
  @param(terrIdx Receives the cell's terrain; 0 outside the arena.) }
procedure GetArenaContents(x, y: ShortInt; var crIdx, terrIdx: Byte);

{ Repaints the terrain under each visible tile of a creature's icon, erasing its sprite, or under the single view cell
  when no creature is there.
  @param(x View column of the cell; the creature's own view column replaces it.)
  @param(y View row of the cell; the creature's own view row replaces it.)
  @param(crIdx The creature's combat slot, or 0 to look up the creature standing on the cell.) }
procedure UpdateCombatMapTile(x, y: ShortInt; crIdx: Byte);

{ Tells whether a view cell lies inside the 7x7 view.
  @param(x View column.)
  @param(y View row.)
  @returns(True when both coordinates lie inside the view.) }
function ViewCoordsValid(x, y: ShortInt): Boolean;

{ Tests whether a creature's icon is visible in the view.
  @param(cr The creature.)
  @param(whole Nonzero to require each tile of the icon in view, 0 to require one.)
  @returns(True when the icon is visible; False when the creature has no icon.) }
function CombatIconVisible(cr: Types.PCharacter; whole: Byte): Boolean;

{ Targets the arena cell one step in the given direction from a cell and redraws the whole view if needed
  (BuildViewBuffer), redrawing each visible icon of a creature in play after a full redraw. Then redraws the cell, draws
  the cursor at the target (kept inside the arena) and flushes the view.
  @param(x Arena column of the cell.)
  @param(y Arena row of the cell.)
  @param(delta How far the target may lie from the view center before the view moves; 255 forces a full redraw.)
  @param(dir Direction of the target, 0 to 7; 8 for the cell itself.) }
procedure ScrollView(x, y: ShortInt; delta, dir: Byte);

{ Turns a creature. While the combat map shows, it scrolls the creature into view unless it is wholly visible, and
  repaints its terrain when the facing crosses between 0 to 3 and 4 to 7 (the mirrored sprites) or `frame` or
  `eraseOnly` is nonzero. It stores the new facing and, unless `eraseOnly` is set, draws its sprite and flushes when it
  is visible and the map shows.
  @param(cr The creature.)
  @param(dir The new facing, 0 to 7.)
  @param(frame The animation frame to draw.)
  @param(eraseOnly Nonzero to erase the sprite without drawing it again.) }
procedure SetCreatureFacing(cr: Types.PCharacter; dir, frame, eraseOnly: Byte);

{ Finds a creature's arena column.
  @param(cr The creature.)
  @returns(The column of its icon's upper-left cell.) }
function CombatCellX(cr: Types.PCharacter): ShortInt;

{ Finds a creature's arena row.
  @param(cr The creature.)
  @returns(The row of its icon's upper-left cell.) }
function CombatCellY(cr: Types.PCharacter): ShortInt;

{ Finds a creature's icon size in the arena.
  @param(cr The creature.)
  @returns(The icon size; 0 when it has no icon.) }
function GetIconSize(cr: Types.PCharacter): Byte;

{ Finds a combatant's combat slot. Note: with no combatants, or more than 72, the search runs past the end of the table.
  @param(cr The combatant.)
  @returns(The slot, or 0 if it is not in the fight.) }
function CombatSlot(cr: Types.PCharacter): Byte;

{ Looks one step in direction dir from every cell of cr's icon: crIdx is a creature found there (other than cr), adj29
  and adj28 whether a cloud of either kind is, and terrIdx the costliest terrain -- 0 if any cell is off the arena.
  @param(cr The creature.)
  @param(dir Direction to look.)
  @param(crIdx Receives the creature found, 0 for none.)
  @param(terrIdx Receives the costliest terrain, 0 off the arena.)
  @param(adj29 Receives non-zero when a stinking cloud is there.)
  @param(adj28 Receives non-zero when a cloudkill is there.) }
procedure ProbeDirection(cr: Types.PCharacter; dir: Byte; var crIdx, terrIdx, adj29, adj28: Byte);

{ Outside combat it plays the downed sound and pauses. In combat, unless cr is already listed as fallen: scrolls it into
  view and flashes the body icon, and for a party member records the body with the terrain under it and marks the cell
  as a corpse (unless a cloud is there); then removes cr from the arena and clears its initiative, movement and
  guarding.
  @param(cr The creature going down.) }
procedure CreatureDowned(cr: Types.PCharacter);

{ Places a creature on an arena cell if it fits. Outside combat it does nothing. In combat it places the creature at the
  cell, probes its own cells and rejects the place, zeroing the icon size, on any creature, terrain 0 or impassable
  terrain. On success with `moving` set, for a party member it clears the creature's body entries and, unless another
  body lies on the cell, writes into it the terrain its last body covered, or the probed terrain when it has no body
  entry or the body covered a corpse cell. The creature grid is then refilled.
  @param(cr The creature.)
  @param(x Arena column of the cell.)
  @param(y Arena row of the cell.)
  @param(moving True when the creature moves there, so its bodies are cleared.)
  @returns(True outside combat or when the creature fits.) }
function IsValidCreatureLoc(cr: Types.PCharacter; x, y: Byte; moving: Boolean): Boolean;

{ Scrolls the view to the creature (ScrollView toward its own cell) when the combat map shows, drawing the cursor over
  its icon footprint when `cursor` is set; afterwards the cursor is off with size 1.
  @param(cr The creature.)
  @param(delta How far it may lie from the view center before the view moves; 255 forces a full redraw.)
  @param(cursor True to draw the cursor.) }
procedure DisplayMapViewCentered(cr: Types.PCharacter; delta: Byte; cursor: Boolean);

{ Draws arena cell (acol, arow) at view cell (vcol, vrow) into the composite buffer; a cloud, fallen body or code 30
  cell is drawn as the terrain beneath with the overlay's icon on top.
  @param(vcol View column.)
  @param(vrow View row.)
  @param(acol Arena column.)
  @param(arow Arena row.) }
procedure DrawTerrainCell(vcol, vrow, acol, arow: ShortInt);

{ Recenters the 7x7 view on a target cell when it lies farther from the view center than allowed, keeping the view
  inside the arena, then draws the view's terrain and recomputes the creatures' view coordinates.
  @param(x Arena column of the target.)
  @param(y Arena row of the target.)
  @param(delta How far the target may lie from the view center; 255 forces a redraw.)
  @returns(True when the view was redrawn.) }
function BuildViewBuffer(x, y: ShortInt; delta: Byte): Boolean;
implementation

function GetIconTileDelta(size, idx: Byte; var dx, dy: ShortInt): Boolean;
begin
  GetIconTileDelta := False;
  if size = 0 then Exit;
  dx := GDConsts.combatTables.iconDelta[size, idx].dx;
  dy := GDConsts.combatTables.iconDelta[size, idx].dy;
  if dx >= 0 then GetIconTileDelta := True
end;

procedure CalcGridDeltas;
var i: Byte;
begin
  for i := 1 to GDVars.creatureCount do begin
    GDVars.gridX[i] := GDVars.arenaLoc[i].x - GDVars.arena^.ox;
    GDVars.gridY[i] := GDVars.arenaLoc[i].y - GDVars.arena^.oy
  end
end;

procedure SetCombatPalette;
begin
end;

procedure SetNoncombatPalette;
begin
end;

procedure DrawTerrainCell(vcol, vrow, acol, arow: ShortInt);
var
  t: Byte;
  baseId: Byte;
  drawId: Byte;
  i: Byte;
  p: Types.PCloudNode;
begin
  vcol := vcol * 3;
  vrow := vrow * 3;
  t := GDVars.arena^.cells[arow, acol];
  if (t > 69) or (t = 0) then t := 21;
  baseId := GDConsts.combatTables.terrain[t].code;
  if t in [C_Terr.TERRAIN_CLOUDKILL..C_Terr.TERRAIN_CORPSE] then begin
    t := CbtMap.ResolveTerrain(acol, arow);
    drawId := GDConsts.combatTables.terrain[t].code;
    case t of
      C_Terr.TERRAIN_STINKING_CLOUD, C_Terr.TERRAIN_CLOUDKILL: begin
        p := GDVars.cloudList;
        while p <> nil do begin
          for i := 1 to 9 do
            if (p^.covered[i] <> 0) and (p^.x + GDConsts.combatTables.directionX[GDConsts.patchDir[i]] = acol) and
                (p^.y + GDConsts.combatTables.directionY[GDConsts.patchDir[i]] = arow) then
              t := p^.under[i];
          p := p^.next
        end
      end;
      C_Terr.TERRAIN_CORPSE: for i := 1 to GDVars.downedCount do
        if (GDVars.downed[i].x = acol) and (GDVars.downed[i].y = arow) then
          t := GDVars.downed[i].terrain
    end;
    if (t > 69) or (t = 0) then t := 21;
    drawId := GDConsts.combatTables.terrain[t].code;
    Blit.BlitTileCell(vcol, vrow, drawId, GDConsts.pictureMode, GDVars.tileSheet,
                      GDVars.compositeBuffer);
    Blit.BlitTileCell(vcol, vrow, 0, GDConsts.iconFrame, GDVars.iconAnimations[baseId + 13, 0],
                      GDVars.compositeBuffer)
  end else
    Blit.BlitTileCell(vcol, vrow, baseId, GDConsts.pictureMode, GDVars.tileSheet,
                      GDVars.compositeBuffer)
end;

procedure DrawCursorCell(x, y: ShortInt);
var
  relX: ShortInt;
  relY: ShortInt;
  tdx: ShortInt;
  tdy: ShortInt;
  i: Byte;
  c: Byte;
  t: Byte;
begin
  relX := x - GDVars.arena^.ox;
  relY := y - GDVars.arena^.oy;
  for i := 0 to 3 do
    if CbtMap.GetIconTileDelta(GDVars.arena^.cursorSize, i, tdx, tdy) then
      if CbtMap.ViewCoordsValid(relX + tdx, relY + tdy) then begin
        CbtMap.DrawTerrainCell(relX + tdx, relY + tdy, x + tdx, y + tdy);
        if GDVars.arena^.cursorOn <> 0 then
          MapTiles.drawIconAnimSprite(relX + tdx, relY + tdy, 0, 0, 28)
      end;
  CbtMap.GetArenaContents(x, y, c, t);
  if c > 0 then
    if CbtMap.CombatIconVisible(GDVars.creatures[c], 0) then
      MapTiles.drawIconAnimSprite(GDVars.gridX[c], GDVars.gridY[c], GDVars.creatures[c]^.combat^.direction, 0,
                                  GDVars.creatures[c]^.orderNumber)
end;

procedure RedrawArenaCell(x, y: ShortInt);
var
  relX: ShortInt;
  relY: ShortInt;
  c: Byte;
  t: Byte;
begin
  relX := x - GDVars.arena^.ox;
  relY := y - GDVars.arena^.oy;
  CbtMap.UpdateCombatMapTile(relX, relY, 0);
  CbtMap.GetArenaContents(x, y, c, t);
  if c > 0 then
    if CbtMap.CombatIconVisible(GDVars.creatures[c], 0) then
      MapTiles.drawIconAnimSprite(GDVars.gridX[c], GDVars.gridY[c], GDVars.creatures[c]^.combat^.direction, 0,
                                  GDVars.creatures[c]^.orderNumber)
end;

procedure BuildArenaArrays;
var
  i: Byte;
  j: Byte;
  tdx: ShortInt;
  tdy: ShortInt;
begin
  FillChar(GDVars.arenaIndex, SizeOf(GDVars.arenaIndex), 0);
  for i := 1 to GDVars.creatureCount do begin
    if GDVars.arenaLoc[i].size > 0 then begin
      for j := 0 to 3 do
        if CbtMap.GetIconTileDelta(GDVars.arenaLoc[i].size, j, tdx, tdy) then
          GDVars.arenaIndex[GDVars.arenaLoc[i].y + tdy, GDVars.arenaLoc[i].x + tdx] := i;
      GDVars.gridX[i] := GDVars.arenaLoc[i].x - GDVars.arena^.ox;
      GDVars.gridY[i] := GDVars.arenaLoc[i].y - GDVars.arena^.oy
    end
  end
end;

procedure GetArenaContents(x, y: ShortInt; var crIdx, terrIdx: Byte);
begin
  if (x >= 0) and (x <= 49) and (y >= 0) and (y <= 24) then begin
    terrIdx := GDVars.arena^.cells[y, x];
    crIdx := GDVars.arenaIndex[y, x]
  end else begin
    crIdx := 0;
    terrIdx := 0
  end
end;

procedure UpdateCombatMapTile(x, y: ShortInt; crIdx: Byte);
var
  absX: ShortInt;
  absY: ShortInt;
  tdx: ShortInt;
  tdy: ShortInt;
  i: Byte;
  t: Byte;
  size: Byte;
begin
  if crIdx = 0 then begin
    absX := x + GDVars.arena^.ox;
    absY := y + GDVars.arena^.oy;
    CbtMap.GetArenaContents(absX, absY, crIdx, t)
  end;
  if crIdx > 0 then begin
    x := GDVars.gridX[crIdx];
    y := GDVars.gridY[crIdx];
    absX := x + GDVars.arena^.ox;
    absY := y + GDVars.arena^.oy;
    size := GDVars.arenaLoc[crIdx].size;
    for i := 0 to 3 do
      if CbtMap.GetIconTileDelta(size, i, tdx, tdy) then
        if CbtMap.ViewCoordsValid(x + tdx, y + tdy) then
          CbtMap.DrawTerrainCell(x + tdx, y + tdy, absX + tdx, absY + tdy)
  end else if CbtMap.ViewCoordsValid(x, y) then
    CbtMap.DrawTerrainCell(x, y, absX, absY)
end;

function ViewCoordsValid(x, y: ShortInt): Boolean;
begin
  if (x < 0) or (x > 6) or (y < 0) or (y > 6) then
    ViewCoordsValid := False
  else
    ViewCoordsValid := True
end;

function CombatIconVisible(cr: Types.PCharacter; whole: Byte): Boolean;
var
  i: Byte;
  slot: Byte;
  tdx: ShortInt;
  tdy: ShortInt;
  { Unused in this version; see the other implementations of this routine. }
  visibleTiles: Integer;
begin
  CombatIconVisible := True;
  slot := CbtMap.CombatSlot(cr);
  if GDVars.arenaLoc[slot].size = 0 then
    CombatIconVisible := False
  else
    for i := 0 to 3 do begin
      if CbtMap.GetIconTileDelta(GDVars.arenaLoc[slot].size, i, tdx, tdy) then
        if not CbtMap.ViewCoordsValid(GDVars.gridX[slot] + tdx, GDVars.gridY[slot] + tdy) then begin
          CombatIconVisible := False;
          if whole <> 0 then Exit
        end else begin
          CombatIconVisible := True;
          if whole = 0 then Exit
        end
    end
end;

function BuildViewBuffer(x, y: ShortInt; delta: Byte): Boolean;
var d: Byte;
  { Unused in this version; see the other implementations of this routine. }
  pixX: ShortInt;
  { Unused in this version; see the other implementations of this routine. }
  pixY: ShortInt;
  i: Byte;
  j: Byte;
  cX: ShortInt;
  cY: ShortInt;
  minX: ShortInt;
  maxX: ShortInt;
  minY: ShortInt;
  maxY: ShortInt;
  { Unused in this version; see the other implementations of this routine. }
  bufferIndex: Integer;
begin
  BuildViewBuffer := False;
  cX := GDVars.arena^.ox + 3;
  cY := GDVars.arena^.oy + 3;
  d := delta;
  if delta = 255 then d := 0;
  minX := cX - d;
  maxX := cX + d;
  minY := cY - d;
  maxY := cY + d;
  if (delta <> 255) and (x >= minX) and (x <= maxX) and (y >= minY) and (y <= maxY) then Exit;
  if x < minX then
    while (x < cX) and (cX > 3) do Dec(cX)
  else if x > maxX then
    while (x > cX) and (cX < 46) do Inc(cX);
  if y < minY then
    while (y < cY) and (cY > 3) do Dec(cY)
  else if y > maxY then
    while (y > cY) and (cY < 21) do Inc(cY);
  GDVars.arena^.ox := cX - 3;
  GDVars.arena^.oy := cY - 3;
  cY := GDVars.arena^.oy;
  for j := 0 to 6 do begin
    cX := GDVars.arena^.ox;
    for i := 0 to 6 do begin
      CbtMap.DrawTerrainCell(i, j, cX, cY);
      Inc(cX)
    end;
    Inc(cY)
  end;
  CbtMap.CalcGridDeltas;
  BuildViewBuffer := True
end;

procedure ScrollView(x, y: ShortInt; delta, dir: Byte);
var
  p: Types.PCharacter;
  i: Byte;
  tx: ShortInt;
  ty: ShortInt;
begin
  tx := x + GDConsts.combatTables.directionX[dir];
  ty := y + GDConsts.combatTables.directionY[dir];
  if CbtMap.BuildViewBuffer(tx, ty, delta) then begin
    for i := 1 to GDVars.creatureCount do begin
      p := GDVars.creatures[i];
      if (p^.enabled <> 0) and (GDVars.arenaLoc[i].size > 0) then
        if CbtMap.CombatIconVisible(p, 0) then
          MapTiles.drawIconAnimSprite(GDVars.gridX[i], GDVars.gridY[i], p^.combat^.direction, 0, p^.orderNumber)
    end
  end;
  CbtMap.RedrawArenaCell(x, y);
  if not CbtMap.ViewCoordsValid(tx - GDVars.arena^.ox, ty - GDVars.arena^.oy) then begin
    if tx > 49 then tx := 49;
    if tx < 0 then tx := 0;
    if ty > 24 then ty := 24;
    if ty < 0 then ty := 0
  end;
  CbtMap.DrawCursorCell(tx, ty);
  Blit.FlushView
end;

procedure SetCreatureFacing(cr: Types.PCharacter; dir, frame, eraseOnly: Byte);
var slot: Byte;
begin
  slot := CbtMap.CombatSlot(cr);
  if not CbtMap.CombatIconVisible(cr, 1) then
    if GDVars.showTurn <> 0 then
      CbtMap.ScrollView(CbtMap.CombatCellX(cr), CbtMap.CombatCellY(cr), 3, C_Dir.CENTER);
  if (cr^.combat^.direction div 4 <> dir div 4) or (frame <> 0) or (eraseOnly <> 0) then
    if GDVars.showTurn <> 0 then
      CbtMap.UpdateCombatMapTile(0, 0, slot);
  cr^.combat^.direction := dir;
  if eraseOnly = 0 then
    if CbtMap.CombatIconVisible(cr, 0) then
      if GDVars.showTurn <> 0 then begin
        MapTiles.drawIconAnimSprite(GDVars.gridX[slot], GDVars.gridY[slot], dir, frame, cr^.orderNumber);
        Blit.FlushView
      end
end;

function CombatCellX(cr: Types.PCharacter): ShortInt;
begin
  CombatCellX := GDVars.arenaLoc[CbtMap.CombatSlot(cr)].x
end;

function CombatCellY(cr: Types.PCharacter): ShortInt;
begin
  CombatCellY := GDVars.arenaLoc[CbtMap.CombatSlot(cr)].y
end;

function GetIconSize(cr: Types.PCharacter): Byte;
begin
  GetIconSize := GDVars.arenaLoc[CbtMap.CombatSlot(cr)].size
end;

function CombatSlot(cr: Types.PCharacter): Byte;
var
  found: Boolean;
  i: Byte;
begin
  found := False;
  CombatSlot := 0;
  i := 0;
  repeat
    Inc(i);
    if GDVars.creatures[i] = cr then found := True
  until found or (i = GDVars.creatureCount);
  if found then CombatSlot := i
end;

procedure ProbeDirection(cr: Types.PCharacter; dir: Byte; var crIdx, terrIdx, adj29, adj28: Byte);
var
  i: Byte;
  slot: Byte;
  c: Byte;
  t: Byte;
  best: Byte;
  nx: ShortInt;
  ny: ShortInt;
  x: ShortInt;
  y: ShortInt;
  tdx: ShortInt;
  tdy: ShortInt;
begin
  crIdx := 0;
  terrIdx := 23;
  best := 1;
  adj28 := 0;
  adj29 := 0;
  slot := CbtMap.CombatSlot(cr);
  x := GDVars.arenaLoc[slot].x;
  y := GDVars.arenaLoc[slot].y;
  for i := 0 to 3 do begin
    if CbtMap.GetIconTileDelta(GDVars.arenaLoc[slot].size, i, tdx, tdy) then begin
      nx := x + tdx + GDConsts.combatTables.directionX[dir];
      ny := y + tdy + GDConsts.combatTables.directionY[dir];
      CbtMap.GetArenaContents(nx, ny, c, t);
      if c = slot then c := 0;
      if c > 0 then crIdx := c;
      if t = C_Terr.TERRAIN_STINKING_CLOUD then adj29 := 1
      else if t = C_Terr.TERRAIN_CLOUDKILL then adj28 := 1;
      if (t = 0) or (terrIdx = 0) then
        terrIdx := 0
      else if GDConsts.combatTables.terrain[t].cost >= best then begin
        best := GDConsts.combatTables.terrain[t].cost;
        terrIdx := t
      end
    end
  end
end;

procedure CreatureDowned(cr: Types.PCharacter);
var
  slot: Byte;
  k: Byte;
  frame: Byte;
  tdx: ShortInt;
  tdy: ShortInt;
  cellX: ShortInt;
  cellY: ShortInt;
  { Unused in this version; see the other implementations of this routine. }
  bodyCell: array[0..2] of Byte;
begin
  if GDVars.interfaceState <> C_Ifc.IN_COMBAT then begin
    Music.SendSoundCommand(GDConsts.downedSound);
    TextRend.PauseOnly
  end else begin
    k := 1;
    while (k < 9) and (GDVars.downed[k].cr <> cr) do Inc(k);
    if k < 9 then Exit;
    slot := CbtMap.CombatSlot(cr);
    cellX := CbtMap.CombatCellX(cr);
    cellY := CbtMap.CombatCellY(cr);
    if not CbtMap.CombatIconVisible(cr, 1) then
      CbtMap.ScrollView(cellX, cellY, 3, C_Dir.CENTER);
    CbtMap.UpdateCombatMapTile(0, 0, slot);
    Music.SendSoundCommand(GDConsts.downedSound);
    for frame := 0 to 8 do begin
      for k := 0 to 3 do
        if CbtMap.GetIconTileDelta(GDVars.arenaLoc[slot].size, k, tdx, tdy) then
          if CbtMap.ViewCoordsValid(GDVars.gridX[slot] + tdx, GDVars.gridY[slot] + tdy) then
            Blit.BlitTileClipped((GDVars.gridX[slot] + tdx) * 3, (GDVars.gridY[slot] + tdy) * 3, 0,
                                 GDConsts.saveUnderBit + GDConsts.iconFrame,
                                 GDVars.iconAnimations[23, frame mod 2], GDVars.compositeBuffer);
      Blit.FlushView;
      Delay(10)
    end;
    if cr^.combat^.notPcNpc = 0 then begin
      frame := CbtMap.ResolveTerrain(cellX, cellY);
      Inc(GDVars.downedCount);
      GDVars.downed[GDVars.downedCount].terrain := frame;
      if not (GDVars.arena^.cells[cellY, cellX] in [C_Terr.TERRAIN_CLOUDKILL, C_Terr.TERRAIN_STINKING_CLOUD]) then
        GDVars.arena^.cells[cellY, cellX] := C_Terr.TERRAIN_CORPSE;
      GDVars.downed[GDVars.downedCount].cr := cr;
      GDVars.downed[GDVars.downedCount].x := cellX;
      GDVars.downed[GDVars.downedCount].y := cellY
    end;
    TextRend.PauseOnly;
    CbtMap.UpdateCombatMapTile(0, 0, slot);
    GDVars.arenaLoc[CbtMap.CombatSlot(cr)].size := 0;
    CbtMap.BuildArenaArrays;
    CbtMap.ScrollView(GDVars.arena^.ox + 3, GDVars.arena^.oy + 3, 3, C_Dir.CENTER);
    cr^.combat^.initiative := 0;
    cr^.combat^.movement := 0;
    cr^.combat^.guarding := 0
  end
end;

function IsValidCreatureLoc(cr: Types.PCharacter; x, y: Byte; moving: Boolean): Boolean;
var
  slot: Byte;
  i: Byte;
  c: Byte;
  t: Byte;
  found: Boolean;
  adj29: Byte;
  adj28: Byte;
begin
  if GDVars.interfaceState = C_Ifc.IN_COMBAT then begin
    IsValidCreatureLoc := False;
    slot := CbtMap.CombatSlot(cr);
    GDVars.arenaLoc[slot].size := cr^.iconDimensions and $7F;
    GDVars.arenaLoc[slot].x := x;
    GDVars.arenaLoc[slot].y := y;
    CbtMap.ProbeDirection(cr, C_Dir.CENTER, c, t, adj29, adj28);
    if (c <> 0) or (t = 0) or (GDConsts.combatTables.terrain[t].cost = C_Terr.TERRAIN_IMPASSABLE) then
      GDVars.arenaLoc[slot].size := 0
    else begin
      IsValidCreatureLoc := True;
      if moving then
        if cr^.combat^.notPcNpc = 0 then begin
          for i := 1 to GDVars.downedCount do
            if GDVars.downed[i].cr = cr then begin
              if GDVars.downed[i].terrain <> C_Terr.TERRAIN_CORPSE then t := GDVars.downed[i].terrain;
              FillChar(GDVars.downed[i], SizeOf(GDVars.downed[i]), 0)
            end;
          found := False;
          for i := 1 to GDVars.downedCount do
            if (GDVars.downed[i].cr <> nil) and (GDVars.downed[i].x = x) and
                (GDVars.downed[i].y = y) then found := True;
          if not found then GDVars.arena^.cells[y, x] := t
        end;
      CbtMap.BuildArenaArrays
    end
  end else
    IsValidCreatureLoc := True
end;

procedure DisplayMapViewCentered(cr: Types.PCharacter; delta: Byte; cursor: Boolean);
begin
  GDVars.arena^.cursorOn := Byte(cursor);
  GDVars.arena^.cursorSize := GDVars.arenaLoc[CbtMap.CombatSlot(cr)].size;
  if GDVars.showTurn <> 0 then
    CbtMap.ScrollView(CbtMap.CombatCellX(cr), CbtMap.CombatCellY(cr), delta, C_Dir.CENTER);
  GDVars.arena^.cursorOn := 0;
  GDVars.arena^.cursorSize := 1
end;

function ResolveTerrain(x, y: ShortInt): Byte;
var
  t: Byte;
  i: Byte;
  p: Types.PCloudNode;
begin
  t := GDVars.arena^.cells[y, x];
  if t in [C_Terr.TERRAIN_CLOUDKILL, C_Terr.TERRAIN_STINKING_CLOUD] then begin
    p := GDVars.cloudList;
    while p <> nil do begin
      for i := 1 to 9 do
        if (p^.covered[i] <> 0) and (p^.x + GDConsts.combatTables.directionX[GDConsts.patchDir[i]] = x) and
            (p^.y + GDConsts.combatTables.directionY[GDConsts.patchDir[i]] = y) then
          t := p^.under[i];
      p := p^.next
    end
  end else if t = C_Terr.TERRAIN_CORPSE then begin
    for i := 1 to GDVars.downedCount do
      if (GDVars.downed[i].x = x) and (GDVars.downed[i].y = y) then
        t := GDVars.downed[i].terrain
  end;
  ResolveTerrain := t
end;

function DirectionBetween(x1, y1, x2, y2: Integer): Byte;
var
  d: Byte;
  found: Boolean;
  adx: Integer;
  ady: Integer;
begin
  adx := Abs(x2 - x1);
  ady := Abs(y2 - y1);
  d := C_Dir.NORTH;
  found := False;
  while not found do begin
    case d of
      C_Dir.NORTHEAST:
        found := (y2 < y1) and (x2 > x1) and ((618 * adx) div 256 >= ady) and ((106 * adx) div 256 <= ady);
      C_Dir.SOUTHEAST:
        found := (y2 > y1) and (x2 > x1) and ((618 * adx) div 256 >= ady) and ((106 * adx) div 256 <= ady);
      C_Dir.SOUTHWEST:
        found := (y2 > y1) and (x2 < x1) and ((618 * adx) div 256 >= ady) and ((106 * adx) div 256 <= ady);
      C_Dir.NORTHWEST:
        found := (y2 < y1) and (x2 < x1) and ((618 * adx) div 256 >= ady) and ((106 * adx) div 256 <= ady);
      C_Dir.NORTH: found := (y2 <= y1) and ((618 * adx) div 256 <= ady);
      C_Dir.EAST: found := (x2 >= x1) and ((106 * adx) div 256 >= ady);
      C_Dir.SOUTH: found := (y2 >= y1) and ((618 * adx) div 256 <= ady);
      C_Dir.WEST: found := (x2 <= x1) and ((106 * adx) div 256 >= ady)
    end;
    if not found then Inc(d)
  end;
  DirectionBetween := d
end;

function DirectionToward(src, dst: Types.PCharacter): Byte;
begin
  DirectionToward := CbtMap.DirectionBetween(CbtMap.CombatCellX(src), CbtMap.CombatCellY(src), CbtMap.CombatCellX(dst),
                                             CbtMap.CombatCellY(dst))
end;

procedure NoopCbtMapA;
begin
end;

procedure NoopCbtMapB;
begin
end;
begin
end.
