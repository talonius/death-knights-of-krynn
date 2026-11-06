{ Pathing -- lines on the combat arena: a stepper that walks a line cell by cell and counts its length in half cells (2
  a straight step, 3 a diagonal), the line-of-fire walk that stops at blocking terrain, the test for whether a cell lies
  in a direction, and the target list in targetList, nearest first. }
{$O+,F+}
{$A-}
{$R-}
{$S-}
unit Pathing;
interface
uses C_Dir, Types, CbtMap, GDConsts, GDVars;

{ Gives the sign of a number.
  @param(v The number.)
  @returns(-1, 0 or 1.) }
function SignOf(v: Integer): Integer;

{ Starts a line walk from its start point to its end point: sets the current point, the deltas, the step signs, and zero
  error and distance.
  @param(req The walk, with its start and end points set.) }
procedure PathFind(var req: Types.TPathReq);

{ Takes one Bresenham step along a line walk, adding 2 to the doubled distance for a straight step and 3 for a diagonal,
  and records the step's direction.
  @param(req The walk, started by PathFind.)
  @returns(False, without moving, once the end point is reached.) }
function NextPathStep(var req: Types.TPathReq): Boolean;

{ Tells whether a direction leads from one arena cell toward another: the target must lie in the 90-degree cone around
  the cell one step away in that direction. A target on the start cell or on the cell one step away always counts.
  @param(x Arena column of the start cell.)
  @param(y Arena row of the start cell.)
  @param(tx Arena column of the target cell.)
  @param(ty Arena row of the target cell.)
  @param(dir The direction, 0 to 7; 8 or 255 for any direction, which always counts.)
  @returns(True when the direction leads toward the target; False when a cell lies outside the arena. Note: a direction
    from 9 to 254 matches no case and leaves the result unset.) }
function IsDirToward(x, y, tx, ty: ShortInt; dir: Byte): Boolean;

{ Walks a line between two arena cells until terrain or the range stops it. The walk stops once the doubled distance (2
  per straight step, 3 per diagonal) exceeds twice the range plus 1, or, when the arena's distance mode is 0, at a cell
  whose terrain rises above the line of sight from the start cell's clearance.
  @param(x Arena column of the start cell.)
  @param(y Arena row of the start cell.)
  @param(tx Arena column of the target cell; receives the cell where the walk stopped.)
  @param(ty Arena row of the target cell; receives the cell where the walk stopped.)
  @param(dist The range in cells; receives the doubled distance walked.)
  @param(view The arena.)
  @returns(True when the walk reached the target.) }
function WalkLine(x, y: ShortInt; var tx, ty: ShortInt; var dist: Word; view: Pointer): Boolean;

{ Builds the target list from an icon's position: each combatant with an icon on the arena is a target when a line from
  a tile of the icon reaches a tile of its icon within range, in the required direction. Each target keeps its shortest
  doubled distance and a direction toward it: the required direction itself when it is 0 to 7, otherwise the lowest
  direction that leads from the best pair of tiles. The list is then sorted by distance.
  @param(x Arena column of the icon's upper-left cell.)
  @param(y Arena row of the icon's upper-left cell.)
  @param(range The range in cells.)
  @param(filter The direction a target must lie in, 0 to 7; 8 or 255 for any direction.)
  @param(size The icon size.)
  @param(view The arena.) }
procedure BuildTargetList(x, y: ShortInt; range: Word; filter: Byte; size: Byte; view: Pointer);
implementation

function SignOf(v: Integer): Integer;
begin
  if v < 0 then
    SignOf := -1
  else if v > 0 then
    SignOf := 1
  else
    SignOf := 0;
end;

{ Sorts the target list nearest first; on equal distance a lower direction goes first unless it is diagonal and the
  other is not. }
procedure SortTargets;
var
  i: Byte;
  j: Byte;
  directionJ: Byte;
  directionI: Byte;
  tmp: Types.TTargetEntry;
begin
  if GDVars.targetCount <= 1 then Exit;
  for i := 1 to GDVars.targetCount - 1 do
    for j := i + 1 to GDVars.targetCount do begin
      directionI := GDVars.targetList[i].direction;
      directionJ := GDVars.targetList[j].direction;
      if (GDVars.targetList[j].distance < GDVars.targetList[i].distance) or
          ((GDVars.targetList[j].distance = GDVars.targetList[i].distance) and (directionJ < directionI) and
           (directionJ mod 2 <= directionI mod 2)) then begin
        tmp := GDVars.targetList[i];
        GDVars.targetList[i] := GDVars.targetList[j];
        GDVars.targetList[j] := tmp;
      end;
    end;
end;

procedure PathFind(var req: Types.TPathReq);
begin
  with req do begin
    cx := sx;
    cy := sy;
    adx := Abs(ex - sx);
    ady := Abs(ey - sy);
    stepX := Pathing.SignOf(ex - sx);
    stepY := Pathing.SignOf(ey - sy);
    err := 0;
    dist := 0;
  end;
end;

function NextPathStep(var req: Types.TPathReq): Boolean;
var
  dxi: ShortInt;
  dyi: ShortInt;
begin
  NextPathStep := False;
  dxi := 1;
  dyi := 1;
  with req do begin
    if adx >= ady then begin
      if cx <> ex then begin
        Inc(cx, stepX);
        dxi := stepX + 1;
        Inc(err, ady);
        Inc(err, ady);
        Inc(dist);
        Inc(dist);
        if err >= adx then begin
          Dec(err, adx);
          Dec(err, adx);
          Inc(cy, stepY);
          dyi := stepY + 1;
          Inc(dist);
        end;
        NextPathStep := True;
      end;
    end else begin
      if cy <> ey then begin
        Inc(cy, stepY);
        dyi := stepY + 1;
        Inc(err, adx);
        Inc(err, adx);
        Inc(dist);
        Inc(dist);
        if err >= ady then begin
          Dec(err, ady);
          Dec(err, ady);
          Inc(cx, stepX);
          dxi := stepX + 1;
          Inc(dist);
        end;
        NextPathStep := True;
      end;
    end;
    step := GDConsts.directionLegend.matrix[dyi, dxi];
  end;
end;

function WalkLine(x, y: ShortInt; var tx, ty: ShortInt; var dist: Word; view: Pointer): Boolean;
var
  walk: Types.TPathReq;
  meter: Types.TPathReq;
  done: Boolean;
  { Unused in this version; see the other implementations of this routine. }
  stepped: Boolean;
  maxDist: Word;
begin
  maxDist := dist * 2 + 1;
  walk.sx := x;
  walk.sy := y;
  walk.ex := tx;
  walk.ey := ty;
  Pathing.PathFind(walk);
  meter.sx := 0;
  meter.sy := GDConsts.combatTables.terrain[Types.PArena(view)^.cells[y, x]].clearance;
  if walk.adx > walk.ady then
    meter.ex := walk.adx
  else
    meter.ex := walk.ady;
  meter.ey := GDConsts.combatTables.terrain[Types.PArena(view)^.cells[y, x]].clearance;
  Pathing.PathFind(meter);
  done := False;
  repeat
    if ((Types.PArena(view)^.distMode = 0) and
        (GDConsts.combatTables.terrain[Types.PArena(view)^.cells[walk.cy, walk.cx]].blocking > meter.cy)) or
          (walk.dist > maxDist) then begin
      tx := walk.cx;
      ty := walk.cy;
      dist := walk.dist;
      WalkLine := False;
      Exit;
    end;
    stepped := Pathing.NextPathStep(meter);
    done := not Pathing.NextPathStep(walk);
  until done;
  dist := walk.dist;
  WalkLine := True;
end;

function IsDirToward(x, y, tx, ty: ShortInt; dir: Byte): Boolean;
var
  nx: ShortInt;
  ny: ShortInt;
begin
  if (x < 0) or (x > 49) or (y < 0) or (y > 24) or (tx < 0) or (tx > 49) or (ty < 0) or
      (ty > 24) then begin
    IsDirToward := False;
    Exit;
  end;
  if dir = GDConsts.combatTables.anyDirection then
    dir := C_Dir.CENTER;
  nx := x + GDConsts.combatTables.directionX[dir];
  ny := y + GDConsts.combatTables.directionY[dir];
  if ((x = tx) and (y = ty)) or ((nx = tx) and (ny = ty)) then begin
    IsDirToward := True;
    Exit;
  end;
  case dir of
    C_Dir.NORTH:
      IsDirToward := ((tx >= nx) and (ty <= (nx - tx) + ny)) or ((tx <= nx) and (ty <= (tx - nx) + ny));
    C_Dir.NORTHEAST:
      IsDirToward := ((tx >= nx) and (ty <= (nx - tx) + ny)) or ((tx >= (nx + ny) - ty) and (ty <= ny));
    C_Dir.EAST:
      IsDirToward := ((tx >= (nx + ny) - ty) and (ty <= ny)) or ((tx >= (nx + ty) - ny) and (ty >= ny));
    C_Dir.SOUTHEAST:
      IsDirToward := ((tx >= (nx + ty) - ny) and (ty >= ny)) or ((tx >= nx) and (ty >= (tx - nx) + ny));
    C_Dir.SOUTH:
      IsDirToward := ((tx >= nx) and (ty >= (tx - nx) + ny)) or ((tx <= nx) and (ty >= (nx - tx) + ny));
    C_Dir.SOUTHWEST:
      IsDirToward := ((tx <= nx) and (ty >= (nx - tx) + ny)) or ((tx <= (nx + ny) - ty) and (ty >= ny));
    C_Dir.WEST:
      IsDirToward := ((tx <= (nx + ny) - ty) and (ty >= ny)) or ((tx <= (nx + ty) - ny) and (ty <= ny));
    C_Dir.NORTHWEST:
      IsDirToward := ((tx <= (nx + ty) - ny) and (ty <= ny)) or ((tx <= nx) and (ty <= (tx - nx) + ny));
    C_Dir.CENTER: IsDirToward := True;
  end;
end;

procedure BuildTargetList(x, y: ShortInt; range: Word; filter: Byte; size: Byte; view: Pointer);
var
  i: Byte;
  bestDir: Byte;
  k: Byte;
  j: Byte;
  bestK: Byte;
  bestJ: Byte;
  found: Boolean;
  tx: ShortInt;
  ty: ShortInt;
  tileDx: ShortInt;
  tileDy: ShortInt;
  { the cells of the seeker's icon, -1 where its size has none }
  fromX: array[0..3] of ShortInt;
  fromY: array[0..3] of ShortInt;
  { the cells of the creature being measured }
  toX: array[0..3] of ShortInt;
  toY: array[0..3] of ShortInt;
  dist: Word;
  bestDist: Word;
begin
  for k := 0 to 3 do
    if CbtMap.GetIconTileDelta(size, k, tileDx, tileDy) then begin
      fromX[k] := x + tileDx;
      fromY[k] := y + tileDy;
    end else
      fromX[k] := -1;
  GDVars.targetCount := 0;
  for i := 1 to GDVars.creatureCount do
    if GDVars.arenaLoc[i].size > 0 then begin
      found := False;
      bestDist := 255;
      for j := 0 to 3 do
        if CbtMap.GetIconTileDelta(GDVars.arenaLoc[i].size, j, tileDx, tileDy) then begin
          toX[j] := GDVars.arenaLoc[i].x + tileDx;
          toY[j] := GDVars.arenaLoc[i].y + tileDy;
        end else
          toX[j] := -1;
      for j := 0 to 3 do
        if toX[j] >= 0 then
          for k := 0 to 3 do
            if fromX[k] >= 0 then
              if Pathing.IsDirToward(fromX[k], fromY[k], toX[j], toY[j], filter) then begin
                tx := toX[j];
                ty := toY[j];
                dist := range;
                if Pathing.WalkLine(fromX[k], fromY[k], tx, ty, dist, view) then begin
                  found := True;
                  if dist < bestDist then begin
                    bestDist := dist;
                    bestK := k;
                    bestJ := j;
                  end;
                end;
              end;
      if found then begin
        Inc(GDVars.targetCount);
        GDVars.targetList[GDVars.targetCount].characterIndex := i;
        GDVars.targetList[GDVars.targetCount].distance := bestDist;
        bestDir := C_Dir.NORTH;
        if filter < C_Dir.CENTER then
          bestDir := filter
        else
          while not Pathing.IsDirToward(fromX[bestK], fromY[bestK], toX[bestJ], toY[bestJ], bestDir) do
            Inc(bestDir);
        GDVars.targetList[GDVars.targetCount].direction := bestDir;
      end;
    end;
  Pathing.SortTargets;
end;
begin
end.
