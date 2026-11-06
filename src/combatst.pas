{ CombatSt -- setting up a fight: the 50x25 arena built from the dungeon's walls around the party (or generated for the
  overland map), the creatures' combat blocks, and each side placed on the arena in front of the other. }
{$F+,O+,S-,R-,V-,B-,I-}
unit CombatSt;
interface

{ Starts a fight, for Combat: frees the pictures, says a battle begins, resets the round count (limit 15), the fallen,
  the clouds and the yell target, builds the arena, gives every creature a combat block, places them, allocates the
  moving icon, centers the view on the party, and fires everyone's combat-start (condition 8) and condition-22
  effects. }
procedure CombatStart;
implementation
uses C_Cond, C_Dir, C_Ifc, C_Npc, C_Side, C_Terr, Crt, GDConsts, GDVars, FxEngine, CbtMap, GameIo,
  CbtActs, Blit, View3D, MapTiles, CharHlp, CharGen, Portrait, MenuCore, TextRend, Types;

{ Sets one arena cell in the current dungeon cell's skewed six-by-five block, ignoring cells off the 50x25 arena.
  @param(yOffset Column within the block.)
  @param(xOffset Row within the block.)
  @param(value The terrain, stored plus 1.) }
procedure PlotCell(yOffset, xOffset, value: Byte);
var
  cellX: ShortInt;
  cellY: ShortInt;
begin
  cellX := GDVars.combatOriginX * 6 + GDVars.combatOriginY * 5 + 21 + yOffset;
  cellY := GDVars.combatOriginY * 5 + 10 + xOffset;
  if (cellX >= 0) and (cellX <= 49) and (cellY >= 0) and (cellY <= 24) then
    GDVars.arena^.cells[cellY, cellX] := value + 1
end;

{ Decorates the current dungeon cell's floor. It records whether the cell is enclosed: at least one solid wall, no door,
  and no opposed pair of solid walls unless all four are solid. When the caller's map-event decoration flag is set and
  the cell is enclosed, each of its six middle spots that is open floor (terrain 22) has an even chance of becoming
  terrain 26, and each open-floor spot beside such a spot a nine in ten chance of becoming terrain 27. }
procedure DecorateCell;
var
  xIndex: ShortInt;
  yIndex: ShortInt;
  cellX: ShortInt;
  cellY: ShortInt;
  adjacentX: ShortInt;
  adjacentY: ShortInt;
  direction: Byte;
begin
  GDVars.allowFeatures := Byte(((GDVars.edgeA = 1) or (GDVars.edgeC = 1) or (GDVars.edgeD = 1) or
                                (GDVars.edgeB = 1)) and
    ((GDVars.edgeA <> 1) or (GDVars.edgeD <> 1) or ((GDVars.edgeC = 1) and (GDVars.edgeB = 1))) and
    ((GDVars.edgeC <> 1) or (GDVars.edgeB <> 1) or ((GDVars.edgeA = 1) and (GDVars.edgeD = 1))) and
    (GDVars.edgeA <> 3) and (GDVars.edgeC <> 3) and (GDVars.edgeD <> 3) and (GDVars.edgeB <> 3));
  for xIndex := 2 to 3 do
    for yIndex := 2 to 4 do begin
      cellX := GDVars.combatOriginX * 6 + GDVars.combatOriginY * 5 + 21 + xIndex + yIndex;
      cellY := GDVars.combatOriginY * 5 + 10 + yIndex;
      if (cellX >= 0) and (cellX <= 49) and (cellY >= 0) and (cellY <= 24) then
        if GDConsts.terrain[GDVars.arena^.cells[cellY, cellX]].code = 22 then
          if (GDVars.featureSource <> 0) and (GDVars.allowFeatures <> 0) then
            if FxEngine.RollDice(1, 10) <= 5 then begin
              GDVars.arena^.cells[cellY, cellX] := 26;
              for direction := 1 to 4 do begin
                adjacentX := GDConsts.cardinalX[direction] + cellX;
                adjacentY := GDConsts.cardinalY[direction] + cellY;
                if (adjacentX >= 0) and (adjacentX <= 49) and (adjacentY >= 0) and (adjacentY <= 24) then
                  if GDConsts.terrain[GDVars.arena^.cells[adjacentY, adjacentX]].code = 22 then
                    if FxEngine.RollDice(1, 10) <= 9 then
                      GDVars.arena^.cells[adjacentY, adjacentX] := 27;
              end
            end;
    end
end;

{ Classifies the edge between a map cell and its neighbor in a direction, from both sides. Off the map it is open on the
  party's row going east or west, otherwise blocked.
  @param(x Map column.)
  @param(y Map row.)
  @param(direction Direction of the neighbor.)
  @returns(0 open, 1 blocked, 3 a wall that can be passed; the two sides' bits combined.) }
function WallBetween(x, y: ShortInt; direction: Byte): Byte;
var
  firstResult: Byte;
  secondResult: Byte;
  oppositeDirection: Byte;

  { Classifies one side of a map cell: 0 open, 1 blocked, 3 a passable wall. }
  function GetWallKind(x, y, kind: ShortInt): Byte;
  begin
    if (x >= 0) and (x <= 15) and (y >= 0) and (y <= 15) then begin
      if View3D.GetBarrierType(x, y, kind) = 0 then
        GetWallKind := 1
      else if View3D.GetWallType(x, y, kind) = 0 then
        GetWallKind := 0
      else GetWallKind := 3
    end else if (y = GDVars.mapState.y) and ((kind = C_Dir.EAST) or (kind = C_Dir.WEST)) then
      GetWallKind := 0
    else GetWallKind := 1
  end;
begin
  oppositeDirection := (direction + 4) mod 8;
  firstResult := GetWallKind(x, y, direction);
  secondResult := GetWallKind(x + GDConsts.directionX[direction], y + GDConsts.directionY[direction],
                              oppositeDirection);
  WallBetween := firstResult or secondResult
end;

{ Fills the arena with floor and draws the walls of the 13x5 map cells around the party into it, each from its four
  classified edges, then seeds terrain features. }
procedure BuildDungeonArena;
var
  pointX: ShortInt;
  pointY: ShortInt;
  { Unused in this version; see the other implementations of this routine. }
  cornerIndex: Word;

  { Draws the cell's three floor rows and its west wall or door. }
  procedure DrawFloorWestWall;
  var
    column: Byte;
    row: Byte;
  begin
    for row := 2 to 4 do
      for column := 0 to 5 do
        CombatSt.PlotCell(column, row, 22);
    if GDVars.edgeB = 1 then
      for row := 2 to 4 do begin
        CombatSt.PlotCell(row - 1, row, 4);
        CombatSt.PlotCell(row, row, 3);
        CombatSt.PlotCell(row + 1, row, 13)
      end else if GDVars.edgeB = 3 then begin
      CombatSt.PlotCell(1, 2, 8);
      CombatSt.PlotCell(5, 4, 0)
    end
  end;

  { Draws the current cell's north wall band (spots 3..4 on rows 0..1): wall terrain when solid, floor otherwise. }
  procedure DrawNorthWall;
  var
    { Unused in this version; see the other implementations of this routine. }
    column: Byte;
  begin
    if GDVars.edgeA = 1 then begin
      CombatSt.PlotCell(3, 0, 5);
      CombatSt.PlotCell(4, 0, 5);
      CombatSt.PlotCell(3, 1, 10);
      CombatSt.PlotCell(4, 1, 10)
    end else begin
      CombatSt.PlotCell(3, 0, 22);
      CombatSt.PlotCell(4, 0, 22);
      CombatSt.PlotCell(3, 1, 22);
      CombatSt.PlotCell(4, 1, 22)
    end
  end;

  { Fills the cell's northwest corner from its north and west walls and whether the edges beyond the corner are open. }
  procedure FillCornerNorthWest;
  var
    index: Byte;
    tile1: Byte;
    tile3: Byte;
    tile2: Byte;
    tile4: Byte;
    clear: Boolean;
  begin
  if (CombatSt.WallBetween(pointX, pointY - 1, C_Dir.WEST) = 0) and
      (CombatSt.WallBetween(pointX - 1, pointY, C_Dir.NORTH) = 0) then
    clear := True
  else
    clear := False;
  tile1 := 0;
  for index := 1 to 4 do
    case index of
      1:
        case GDVars.edgeA of
          0:
            case GDVars.edgeB of
              0: tile1 := 22;
              3, 1: if clear then tile1 := 0 else tile1 := 13
            end;
          3, 1:
            if GDVars.edgeB = 0 then begin
              if clear then tile1 := 15 else tile1 := 5
            end else begin
              if clear then tile1 := 18 else tile1 := 2
            end
        end;
      2:
        case GDVars.edgeA of
          0: tile2 := 22;
          3: tile2 := 17;
          1: tile2 := 5
        end;
      3:
        case GDVars.edgeB of
          0:
            if GDVars.edgeA = 0 then tile3 := 22
            else if clear then tile3 := 16 else tile3 := 10;
          3: if clear then tile3 := 20 else tile3 := 7;
          1: if clear then tile3 := 1 else tile3 := 3
        end;
      4:
        case GDVars.edgeB of
          0, 3:
            case GDVars.edgeA of
              0: tile4 := 22;
              3: tile4 := 23;
              1: tile4 := 10
            end;
          1:
            case GDVars.edgeA of
              0: tile4 := 13;
              3: tile4 := 21;
              1: tile4 := 6
            end
        end
    end;
  CombatSt.PlotCell(1, 0, tile1);
  CombatSt.PlotCell(2, 0, tile2);
  CombatSt.PlotCell(1, 1, tile3);
  CombatSt.PlotCell(2, 1, tile4)
  end;

  { Fills the cell's northeast corner, which spills one spot into the next cell's block. }
  procedure FillCornerNorthEast;
  var
    index: Byte;
    tile1: Byte;
    tile3: Byte;
    tile2: Byte;
    tile4: Byte;
    clear: Boolean;
    firstResult: Byte;
    secondResult: Byte;
    { Unused in this version; see the other implementations of this routine. }
    thirdResult: Byte;
  begin
    firstResult := CombatSt.WallBetween(pointX, pointY - 1, C_Dir.EAST);
    secondResult := CombatSt.WallBetween(pointX + 1, pointY, C_Dir.NORTH);
    if (firstResult = 0) and (secondResult = 0) then clear := True
    else clear := False;
    for index := 1 to 4 do
      case index of
        1:
          case GDVars.edgeA of
            0: if firstResult = 1 then tile1 := 4 else tile1 := 22;
            3: tile1 := 15;
            1: tile1 := 5
          end;
        2:
          if GDVars.edgeA = 0 then
            case firstResult of
              0: tile2 := 22;
              3:
                if (GDVars.edgeC = 0) and (secondResult <> 0) then tile2 := 24
                else if GDVars.edgeC = 0 then tile2 := 7 else tile2 := 1;
              1:
                if GDVars.edgeC = 0 then begin
                  if secondResult <> 0 then tile2 := 11 else tile2 := 7
                end else tile2 := 3
            end else if GDVars.edgeC <> 0 then tile2 := 9
          else if secondResult <> 0 then tile2 := 5
          else if clear then tile2 := 17 else tile2 := 19;
        3:
          case GDVars.edgeA of
            0: tile3 := 22;
            3: tile3 := 16;
            1: tile3 := 10
          end;
        4:
          if GDVars.edgeA = 0 then begin
            if firstResult = 0 then tile4 := 22
            else if GDVars.edgeC <> 0 then tile4 := 4
            else if secondResult = 0 then tile4 := 8 else tile4 := 12
          end else if GDVars.edgeC <> 0 then tile4 := 14
          else if secondResult = 0 then tile4 := 23 else tile4 := 10
      end;
    CombatSt.PlotCell(5, 0, tile1);
    CombatSt.PlotCell(6, 0, tile2);
    CombatSt.PlotCell(5, 1, tile3);
    CombatSt.PlotCell(6, 1, tile4)
  end;
begin
  FillChar(GDVars.arena^.cells[0, 0], SizeOf(GDVars.arena^.cells), 22);
  for GDVars.combatOriginY := -2 to 2 do
    for GDVars.combatOriginX := -6 to 6 do begin
      pointX := GDVars.mapState.x + GDVars.combatOriginX;
      pointY := GDVars.mapState.y + GDVars.combatOriginY;
      GDVars.edgeB := CombatSt.WallBetween(pointX, pointY, C_Dir.WEST);
      GDVars.edgeA := CombatSt.WallBetween(pointX, pointY, C_Dir.NORTH);
      GDVars.edgeC := CombatSt.WallBetween(pointX, pointY, C_Dir.EAST);
      GDVars.edgeD := CombatSt.WallBetween(pointX, pointY, C_Dir.SOUTH);
      DrawFloorWestWall;
      DrawNorthWall;
      FillCornerNorthWest;
      FillCornerNorthEast;
      GDVars.featureSource := View3D.GetMapEvent(pointX, pointY) and $40;
      CombatSt.DecorateCell
    end
end;

{ Returns the terrain flags of activeCombatantIndex's entry in combatantTiles.
  @returns(The terrain flags.) }
function CurrentCombatTile: Byte;
begin
  CurrentCombatTile := GDConsts.combatantTiles[GDVars.activeCombatantIndex]
end;

{ Lays a diagonal band of river tiles down the arena when the area calls for a river, crossed by fords at random rows;
  the chance of a ford grows with each row that has none. }
procedure PlaceRiver;
var
  chance: Byte;
  { Unused in this version; see the other implementations of this routine. }
  baseX: ShortInt;
  x: ShortInt;
  y: ShortInt;

  { Lays a ford across the road at a cell and resets the ford chance. }
  procedure PlotFord(x, y: ShortInt);
  begin
    GDVars.arena^.cells[y, x] := 58;
    if x < 49 then begin
      GDVars.arena^.cells[y, x + 1] := FxEngine.RollDice(1, 2) + 58;
      if x + 1 < 49 then
        GDVars.arena^.cells[y, x + 2] := FxEngine.RollDice(1, 2) + 58;
      if x + 2 < 49 then
        GDVars.arena^.cells[y, x + 3] := 61
    end;
    chance := 1
  end;
begin
  if GDVars.zone0^.combatDecor <> 0 then begin
    x := 34 - FxEngine.RollDice(5, 4);
    while ((x + 2) mod 7) > 0 do Dec(x);
    baseX := x;
    chance := 1;
    for y := 0 to 24 do
      if x <= 49 then begin
        GDVars.arena^.cells[y, x] := 52;
        if x < 49 then
          if FxEngine.RollDice(1, 20) <= chance then
            PlotFord(x + 1, y)
          else begin
            Inc(chance);
            GDVars.arena^.cells[y, x + 1] := FxEngine.RollDice(1, 2) + 52;
            if x + 1 < 49 then
              GDVars.arena^.cells[y, x + 2] := 55;
            if x + 2 < 49 then
              GDVars.arena^.cells[y, x + 3] := 55;
            if x + 3 < 49 then
              GDVars.arena^.cells[y, x + 4] := FxEngine.RollDice(1, 2) + 55
          end;
        if x + 4 < 49 then
          GDVars.arena^.cells[y, x + 5] := 52;
        Inc(x)
      end
  end
end;

{ Unless the terrain class has bit 7 set, replaces some vertical pairs of open-ground cells (tile 37) with features, at
  a chance the class raises or lowers. }
procedure PlaceTrees;
var
  { Unused in this version; see the other implementations of this routine. }
  roll: ShortInt;
  x: ShortInt;
  y: ShortInt;
  chance: ShortInt;
begin
  if (CombatSt.CurrentCombatTile and $80) = 0 then begin
    chance := 5;
    if (CombatSt.CurrentCombatTile and $02) <> 0 then Dec(chance, 3);
    if (CombatSt.CurrentCombatTile and $04) <> 0 then Dec(chance, 3);
    if (CombatSt.CurrentCombatTile and $40) <> 0 then Inc(chance, 2);
    if (CombatSt.CurrentCombatTile and $08) <> 0 then Inc(chance, 5);
    if chance < 0 then chance := 1;
    for x := 0 to 49 do
      for y := 1 to 24 do
        if GDConsts.terrain[GDVars.arena^.cells[y, x]].code = 37 then
          if GDConsts.terrain[GDVars.arena^.cells[y - 1, x]].code = 37 then
            if FxEngine.RollDice(1, 100) <= chance then
              if FxEngine.RollDice(1, 100) <= chance then
                GDVars.arena^.cells[y, x] := FxEngine.RollDice(1, 2) + 41
              else begin
                GDVars.arena^.cells[y - 1, x] := FxEngine.RollDice(1, 5) + 31;
                GDVars.arena^.cells[y, x] := FxEngine.RollDice(1, 5) + 36
              end
  end
end;

{ Scatters decorative terrain over open ground, the mix chosen by terrain class: five feature kinds by percentage
  chances. Note: the third kind's band is always 1 percent wide, and its chance widens the fourth kind's band instead. }
procedure ScatterFeatures;
var
  x: ShortInt;
  y: ShortInt;
  score: Integer;

  { Replaces one cell by a d100 roll against the five odds. }
  procedure ScatterOneCell(x, y: ShortInt; firstChance, secondChance, thirdChance, fourthChance, fifthChance: Byte);
  var roll: Byte;
  begin
    roll := FxEngine.RollDice(1, 100);
    if roll <= firstChance then
      GDVars.arena^.cells[y, x] := FxEngine.RollDice(1, 2) + 49
    else if roll <= firstChance + secondChance then
      GDVars.arena^.cells[y, x] := 44
    else if roll <= firstChance + secondChance + 1 then
      GDVars.arena^.cells[y, x] := FxEngine.RollDice(1, 5) + 44
    else if roll <= firstChance + secondChance + thirdChance + fourthChance then
      GDVars.arena^.cells[y, x] := 68
    else if roll <= firstChance + secondChance + thirdChance + fourthChance + fifthChance then
      GDVars.arena^.cells[y, x] := FxEngine.RollDice(1, 6) + 61
  end;
begin
  score := 50;
  if (CombatSt.CurrentCombatTile and $10) <> 0 then Inc(score, 10);
  if (CombatSt.CurrentCombatTile and $20) <> 0 then Inc(score, 30);
  if (CombatSt.CurrentCombatTile and $40) <> 0 then Inc(score, 20);
  if (CombatSt.CurrentCombatTile and $04) <> 0 then Dec(score, 10);
  if (CombatSt.CurrentCombatTile and $02) <> 0 then Dec(score, 20);
  if (CombatSt.CurrentCombatTile and $80) <> 0 then Dec(score, 50);
  for x := 0 to 49 do
    for y := 0 to 24 do
      if GDConsts.terrain[GDVars.arena^.cells[y, x]].code = 37 then
        case score of
          -30..9: ScatterOneCell(x, y, 0, 0, 0, 30, 15);
          10..29: ScatterOneCell(x, y, 0, 1, 5, 20, 10);
          30..69: ScatterOneCell(x, y, 0, 2, 5, 10, 5);
          70..89: ScatterOneCell(x, y, 10, 2, 10, 10, 1);
          90..110: ScatterOneCell(x, y, 15, 5, 15, 10, 1)
        end
end;

{ Fills the arena with wilderness ground, then adds the river, the trees and the scattered features. The terrain under
  the party is always taken as terrain 15. }
procedure BuildWildernessArena;
var
  { Unused in this version; see the other implementations of this routine. }
  configX: Byte;
  { Unused in this version; see the other implementations of this routine. }
  configY: Byte;
  { Unused in this version; see the other implementations of this routine. }
  mapIndex: Word;
begin
  FillChar(GDVars.arena^.cells[0, 0], SizeOf(GDVars.arena^.cells), 69);
  configX := GDVars.zone0^.wildX;
  configY := GDVars.zone0^.wildY;
  GDVars.activeCombatantIndex := 15;
  CombatSt.PlaceRiver;
  CombatSt.PlaceTrees;
  CombatSt.ScatterFeatures
end;

{ Loads the dungeon or wilderness combat tiles if not already loaded, allocates the arena and builds it. On the overland
  map the loaded flag is set to 0, not 1, so the wilderness tiles are loaded again for every fight. }
procedure LoadCombatTileSet;
begin
  if GDVars.zone0^.inDungeon <> 0 then begin
    if GDVars.dungeonCombatLoaded = 0 then begin
      MapTiles.Load24x24Set('DungCom', 1, 0, 25);
      GDVars.wildernessCombatLoaded := 0;
      GDVars.dungeonCombatLoaded := 1
    end
  end else if GDVars.wildernessCombatLoaded = 0 then begin
    MapTiles.Load24x24Set('WildCom', 1, 0, 38);
    GDVars.dungeonCombatLoaded := 0;
    GDVars.wildernessCombatLoaded := 0
  end;
  GetMem(GDVars.arena, SizeOf(Types.TArena));
  FillChar(GDVars.arena^, SizeOf(Types.TArena), 0);
  GDVars.arena^.cursorOn := 0;
  GDVars.arena^.cursorSize := 1;
  GDVars.arena^.distMode := 0;
  if GDVars.zone0^.inDungeon <> 0 then
    CombatSt.BuildDungeonArena
  else
    CombatSt.BuildWildernessArena
end;

{ Gives each creature a zeroed combat record after recalculating its statistics: creatures past the party's size are
  marked as non-party members, allies face the party's way and hostiles the other way, and a friendly non-party creature
  with no morale, or one above 102, takes the zone's base morale as a non-player. }
procedure InitCreatureCombatData;
var
  node: Types.PCharacter;
  count: Byte;
  maskedTile: Byte;
begin
  node := GDVars.partyHead;
  count := 0;
  while node <> nil do begin
    CharHlp.RecalcStats(node);
    Inc(count);
    GetMem(node^.combat, SizeOf(Types.TCombat));
    FillChar(node^.combat^, SizeOf(Types.TCombat), 0);
    if count > GDVars.zone1^.partySize[$7F3E] then node^.combat^.notPcNpc := 1;
    node^.combat^.direction := GDConsts.halfDirections[GDVars.mapState.facing div 2];
    if node^.side = C_Side.ENEMY then
      node^.combat^.direction := (node^.combat^.direction + 4) mod 8;
    maskedTile := node^.npc and C_Npc.MORALE_MASK;
    if (node^.side = C_Side.PLAYER) and (node^.combat^.notPcNpc = 1) and
        ((maskedTile = 0) or (maskedTile > 102)) then
      node^.npc := GDVars.zone1^.moraleBase[GDConsts.moraleBaseIndex + $7C00] + C_Npc.NON_PLAYER;
    node := node^.next
  end
end;

{ Tells whether a placement square lies off the 11x6 grid on both axes.
  @param(x The square's column.)
  @param(y The square's row.)
  @returns(True when both coordinates are off the grid.) }
function QuadFullyOff(x, y: ShortInt): Boolean;
begin
  if ((x >= 0) and (x < 11)) or ((y >= 0) and (y < 6)) then
    QuadFullyOff := False
  else
    QuadFullyOff := True
end;

{ Places creature entityIndex at free cell (gridX, gridY) of the side's placement grid, if its arena cell holds no
  creature and is passable, and marks the cell used.
  @param(entityIndex Creature's index in creatures.)
  @param(gridX Placement grid column.)
  @param(gridY Placement grid row.)
  @param(offsetA The anchor's map column offset from the party.)
  @param(offsetB The anchor's map row offset from the party.)
  @param(layer Placement grid layer.)
  @returns(True when the creature was placed.) }
function TryPlaceAt(entityIndex: Byte; gridX, gridY, offsetA, offsetB: ShortInt; layer: Byte): Boolean;
var
  probeA: Byte;
  probeB: Byte;
  probeC: Byte;
  probeD: Byte;
begin
  if (gridX < 0) or (gridY < 0) or (gridX > 10) or (gridY > 5) or
      (GDVars.combatOccupancy[GDVars.combatPlane, layer, gridY, gridX] = 0) then
    TryPlaceAt := False
  else begin
    GDVars.arenaLoc[entityIndex].x := gridX + offsetA * 6 + offsetB * 5 + 22;
    GDVars.arenaLoc[entityIndex].y := gridY + offsetB * 5 + 10;
    CbtMap.ProbeDirection(GDVars.creatures[entityIndex], C_Dir.CENTER, probeA, probeB, probeC, probeD);
    if (probeA = 0) and (probeB > 0) and (GDConsts.terrain[probeB].cost < C_Terr.TERRAIN_IMPASSABLE) then begin
      TryPlaceAt := True;
      GDVars.combatOccupancy[GDVars.combatPlane, layer, gridY, gridX] := 0
    end else
      TryPlaceAt := False
  end
end;

{ Searches the team's placement grid for a square for a creature, in zigzag legs from the ring's start square. A leg
  ends at a square partly off the grid or after a set number of tries, and the next leg starts a step further back; for
  team 0 facing diagonally, ring 0's first step back is doubled when any of the ring's three directions is not walled
  off (always outdoors). A square fully off the grid moves on to the next ring whose direction is not walled off (always
  outdoors), up to ring 3.
  @param(entityIndex The creature's combat slot.)
  @returns(True when the creature was placed; False when no ring is left.) }
function FindPlacement(entityIndex: Byte): Boolean;
var
  placed: Boolean;
  keepSearching: Boolean;
  failed: Boolean;
  outside: Boolean;
  foundDirection: Boolean;
  phase: Byte;
  probeDirection: Byte;
  direction: Byte;
  scanDirection: Byte;
  stepX: ShortInt;
  stepY: ShortInt;
  anchorX: ShortInt;
  anchorY: ShortInt;
  distance: Byte;
  radius: Byte;
  initialX: ShortInt;
  initialY: ShortInt;
  attempt: Byte;
  layer: Byte;
  candidateX: ShortInt;
  candidateY: ShortInt;
  finalX: ShortInt;
  finalY: ShortInt;
begin
  keepSearching := True;
  failed := False;
  phase := 1;
  distance := 0;
  layer := 0;
  initialX := GDVars.combatXByPlane[GDVars.combatPlane];
  initialY := GDVars.combatYByPlane[GDVars.combatPlane];
  repeat
    direction := GDConsts.combatApproachDirections[GDVars.combatHalfDirections[GDVars.combatPlane], layer]
               div 2;
    case phase of
      1: begin
          stepX := GDConsts.directionX[GDConsts.halfDirections[(direction + 2) mod 4]];
          stepY := GDConsts.directionY[GDConsts.halfDirections[(direction + 2) mod 4]];
          candidateX := GDConsts.approachOffsetX[Ord(layer > 0), direction] + stepX * distance;
          candidateY := GDConsts.approachOffsetY[Ord(layer > 0), direction] + stepY * distance;
          finalX := candidateX;
          finalY := candidateY;
          radius := 1;
          phase := 2;
          attempt := 1
        end;
      2: begin
          stepX := GDConsts.directionX[GDConsts.halfDirections[(direction + 1) mod 4]];
          stepY := GDConsts.directionY[GDConsts.halfDirections[(direction + 1) mod 4]];
          finalX := candidateX + stepX * radius;
          finalY := candidateY + stepY * radius;
          phase := 3;
          Inc(attempt)
        end;
      3: begin
          stepX := GDConsts.directionX[GDConsts.halfDirections[(direction + 3) mod 4]];
          stepY := GDConsts.directionY[GDConsts.halfDirections[(direction + 3) mod 4]];
          finalX := candidateX + stepX * radius;
          finalY := candidateY + stepY * radius;
          phase := 2;
          Inc(radius);
          Inc(attempt)
        end
    end;
    if (finalX < 0) or (finalY < 0) or (finalX > 10) or (finalY > 5) then
      outside := True
    else
      outside := False;
    if phase > 1 then begin
      if (outside and (not CombatSt.QuadFullyOff(finalX, finalY))) or
          (keepSearching and (attempt >= GDVars.placementAttemptLimits[GDVars.combatPlane])) or
          ((not keepSearching) and (attempt > 11)) then begin
        Inc(distance);
        if (GDVars.combatPlane = 0) and Odd(GDVars.combatHalfDirections[0]) and (layer = 0) and
            (distance = 1) then begin
          anchorX := GDVars.combatXByPlane[GDVars.combatPlane] + GDVars.mapState.x;
          anchorY := GDVars.combatYByPlane[GDVars.combatPlane] + GDVars.mapState.y;
          foundDirection := False;
          for scanDirection := 1 to 3 do begin
            probeDirection := GDConsts.placementDirections[GDVars.combatHalfDirections[GDVars.combatPlane],
                                                           scanDirection];
            if (GDVars.interfaceState = C_Ifc.OVERLAND) or
                (CombatSt.WallBetween(anchorX, anchorY, probeDirection) <> 1) then
              foundDirection := True
          end;
          if foundDirection then Inc(distance)
        end;
        phase := 1;
        keepSearching := False
      end
    end;
    if outside and CombatSt.QuadFullyOff(finalX, finalY) then begin
      placed := False;
      phase := 0;
      while (layer < 3) and (phase <> 1) do begin
        Inc(layer);
        anchorX := GDVars.combatXByPlane[GDVars.combatPlane] + GDVars.mapState.x;
        anchorY := GDVars.combatYByPlane[GDVars.combatPlane] + GDVars.mapState.y;
        probeDirection := GDConsts.placementDirections[GDVars.combatHalfDirections[GDVars.combatPlane], layer];
        if (GDVars.interfaceState = C_Ifc.OVERLAND) or
            (CombatSt.WallBetween(anchorX, anchorY, probeDirection) <> 1) then begin
          initialX := GDVars.combatXByPlane[GDVars.combatPlane] + GDConsts.directionX[probeDirection];
          initialY := GDVars.combatYByPlane[GDVars.combatPlane] + GDConsts.directionY[probeDirection];
          distance := 0;
          phase := 1
        end
      end;
      if phase <> 1 then failed := True
    end;
    if not outside then
      placed := CombatSt.TryPlaceAt(entityIndex, finalX, finalY, initialX, initialY, layer)
  until placed or failed;
  if failed then FindPlacement := False
  else FindPlacement := True
end;

{ Places every creature: the party at the anchor, the monsters at the monster distance ahead (rotating among the
  directions combatDirectionFlags allows). A monster that cannot be placed is removed; a disabled party member is placed
  as a body. }
procedure PlaceAllCreatures;
var
  previousNode: Types.PCharacter;
  currentNode: Types.PCharacter;
  entityIndex: Byte;
  selection: Byte;
  successCount: Byte;
  failureCount: Byte;
  savedDirection: Byte;
  lastDirection: Byte;
  rotation: Byte;
  entityX: ShortInt;
  entityY: ShortInt;
  entityDirection: Byte;
  bitCount: Byte;
  placed: Boolean;

  { Points both sides' placement grids along the current facing at the monster distance. }
  procedure PrepareCombatOccupancy;
  var
    group: Byte;
    column: ShortInt;
    row: ShortInt;
    mode: Byte;
  begin
    if (GDVars.zone1^.monsterDist[GDConsts.monsterDistIndex + $7C00] = 0) and
        (GDVars.mapState.facing <> savedDirection) then
      mode := 1
    else
      mode := GDVars.zone1^.monsterDist[GDConsts.monsterDistIndex + $7C00];
    if GDVars.demoMode <> 0 then mode := 2;
    if GDVars.mapState.facing <> lastDirection then begin
      lastDirection := GDVars.mapState.facing;
      GDVars.combatHalfDirections[0] := GDVars.mapState.facing div 2;
      GDVars.combatXByPlane[1] := GDConsts.directionX[GDVars.mapState.facing] * mode + GDVars.combatXByPlane[0];
      GDVars.combatYByPlane[1] := GDConsts.directionY[GDVars.mapState.facing] * mode + GDVars.combatYByPlane[0];
      GDVars.combatHalfDirections[1] := ((GDVars.mapState.facing + 4) mod 8) div 2;
      for GDVars.combatPlane := 0 to 1 do
        for group := 0 to 3 do begin
          if group = 1 then selection := 4
          else selection := GDVars.combatHalfDirections[GDVars.combatPlane];
          for row := 0 to 5 do
            for column := 0 to 10 do
              if (GDConsts.occupancyRanges[selection, row, 0] > column) or (GDConsts.occupancyRanges[selection, row,
                  1] < column) then
                GDVars.combatOccupancy[GDVars.combatPlane, group, row, column] := 0
              else
                GDVars.combatOccupancy[GDVars.combatPlane, group, row, column] := 1
        end
    end
  end;
begin
  savedDirection := GDVars.mapState.facing;
  lastDirection := 255;
  rotation := 0;
  CharHlp.CountTeams;
  failureCount := 0;
  successCount := 0;
  for entityIndex := 1 to 72 do
    GDVars.arenaLoc[entityIndex].size := 0;
  FillChar(GDVars.arenaIndex, SizeOf(GDVars.arenaIndex), 0);
  GDVars.combatXByPlane[0] := 0;
  GDVars.combatYByPlane[0] := 0;
  GDVars.placementAttemptLimits[0] := (GDVars.teamCount[C_Side.PLAYER] + 1) div 2;
  bitCount := 0;
  if (GDVars.combatDirectionFlags and $0F) = 0 then
    Inc(bitCount)
  else begin
    if (GDVars.combatDirectionFlags and $01) <> 0 then Inc(bitCount);
    if (GDVars.combatDirectionFlags and $02) <> 0 then Inc(bitCount);
    if (GDVars.combatDirectionFlags and $04) <> 0 then Inc(bitCount);
    if (GDVars.combatDirectionFlags and $08) <> 0 then Inc(bitCount)
  end;
  bitCount := bitCount * 2;
  GDVars.placementAttemptLimits[1] := (GDVars.teamCount[C_Side.ENEMY] + bitCount - 1) div bitCount;
  PrepareCombatOccupancy;
  entityIndex := 1;
  GDVars.creatureCount := 1;
  previousNode := GDVars.partyHead;
  currentNode := GDVars.partyHead;
  while currentNode <> nil do begin
    GameIo.DiscardPendingKeys;
    GDVars.creatures[entityIndex] := currentNode;
    GDVars.combatPlane := currentNode^.side;
    GDVars.arenaLoc[entityIndex].aux := entityIndex;
    GDVars.arenaLoc[entityIndex].size := currentNode^.iconDimensions and $07;
    if GDVars.combatDirectionFlags <> 0 then begin
      if currentNode^.side = C_Side.PLAYER then
        GDVars.mapState.facing := savedDirection
      else begin
        repeat
          rotation := (rotation + 1) and $03
        until Byte((1 shl rotation) and GDVars.combatDirectionFlags) <> 0;
        GDVars.mapState.facing := rotation * 2
      end;
      PrepareCombatOccupancy
    end;
    entityDirection := GDVars.mapState.facing;
    if currentNode^.side = C_Side.ENEMY then
      entityDirection := (entityDirection + 4) mod 8;
    currentNode^.combat^.direction := GDConsts.halfDirections[entityDirection div 2];
    if (GDVars.duelFlag <> 0) and (currentNode^.enabled = 0) then
      placed := False
    else
      placed := CombatSt.FindPlacement(entityIndex);
    if placed then begin
      previousNode := currentNode;
      if currentNode^.enabled = 0 then begin
        GDVars.arenaLoc[entityIndex].size := 0;
        if currentNode^.combat^.notPcNpc = 0 then begin
          entityX := GDVars.arenaLoc[entityIndex].x;
          entityY := GDVars.arenaLoc[entityIndex].y;
          Inc(GDVars.downedCount);
          GDVars.downed[GDVars.downedCount].terrain := CbtMap.ResolveTerrain(entityX, entityY);
          GDVars.arena^.cells[entityY, entityX] := C_Terr.TERRAIN_CORPSE;
          GDVars.downed[GDVars.downedCount].cr := currentNode;
          GDVars.downed[GDVars.downedCount].x := entityX;
          GDVars.downed[GDVars.downedCount].y := entityY
        end
      end;
      CbtMap.BuildArenaArrays;
      Inc(entityIndex);
      Inc(GDVars.creatureCount);
      Inc(successCount)
    end else begin
      GDVars.arenaLoc[entityIndex].size := 0;
      if currentNode^.combat^.notPcNpc = 1 then begin
        Inc(failureCount);
        GDVars.creatures[entityIndex] := nil;
        GDVars.currentCharacter := currentNode;
        CharGen.RemoveCreature(True, False);
        currentNode := previousNode
      end else begin
        previousNode := currentNode;
        Inc(entityIndex);
        Inc(GDVars.creatureCount)
      end
    end;
    currentNode := currentNode^.next
  end;
  previousNode^.next := nil;
  GDVars.mapState.facing := savedDirection
end;

procedure CombatStart;
var
  { Unused in this version; see the other implementations of this routine. }
  savedFlags: array[1..10] of Byte;
  node: Types.PCharacter;
begin
  GDVars.slowText := 0;
  Portrait.FreeAnimation(GDVars.portraitAnimation);
  Blit.FreePic(GDVars.bigPic);
  GDVars.bigId := 255;
  MenuCore.ClearBottomLine;
  TextRend.PauseOnly;
  TextRend.DisplayString(0, 24, LightGreen, Black, GDConsts.battleBegins);
  GDVars.roundNumber := 0;
  GDVars.roundLimit := 15;
  GDVars.currentAttackRoll := 0;
  GDVars.downedCount := 0;
  GDVars.cloudList := nil;
  GDVars.yellTarget := nil;
  GDVars.prevTreasure := nil;
  FillChar(GDVars.downed, SizeOf(GDVars.downed), 0);
  GDVars.zone1^.attackedAllies[GDConsts.attackedAlliesIndex + $7C00] := 0;
  CombatSt.LoadCombatTileSet;
  GameIo.DiscardPendingKeys;
  CombatSt.InitCreatureCombatData;
  GameIo.DiscardPendingKeys;
  CombatSt.PlaceAllCreatures;
  GameIo.DiscardPendingKeys;
  Blit.AllocPic(24, 3, 4, GDConsts.iconFrame, GDVars.movingIcon);
  GDVars.arena^.ox := CbtMap.CombatCellX(GDVars.partyHead) - 3;
  GDVars.arena^.oy := CbtMap.CombatCellY(GDVars.partyHead) - 3;
  CharHlp.DisplayCombatInterface;
  node := GDVars.partyHead;
  while node <> nil do begin
    node^.combat^.turnAttempts := 0;
    FxEngine.TriggerEffectsWithCondition(C_Cond.COMBAT_START, node);
    FxEngine.TriggerEffectsWithCondition(22, node);
    node := node^.next
  end;
  CbtActs.UpdateHostileHpPercent;
  GDVars.inMoveMenu := 0;
  GDVars.cursorActive := 0;
  GDVars.interfaceState := C_Ifc.IN_COMBAT;
  GDVars.extendedMode := 0
end;
begin
end.
