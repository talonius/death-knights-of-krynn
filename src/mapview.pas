{ MapView -- redraws the area view: the 3D view off the overland map, the overland picture on it. CharHlp, EclMenu and
  EclVm call DisplayMapView. GDConsts.skyColors maps a zone's sky index to a palette color. }
{$O+,F+}
unit MapView;
interface

{ Drops the forced-redraw flag when picture archive 9 is up, and does nothing while the party is defeated. Off the
  overland map (in a dungeon, or the zone's wildOn not 1) it reads the party's cell event, takes the sky color from the
  zone's skyA or skyB by the event's high bit, recomputes ceiling, floor and wall colors from the script's color
  selectors when they changed in CGA mode (other modes fix the wall at dark gray), turns the automap off in a locked
  area and draws the 3D view. On the overland map it redraws the overland picture ($70) when a redraw was forced. Either
  way it clears the forced-redraw flag. }
procedure DisplayMapView;
implementation
uses Crt, View3D, Portrait, GDConsts, GDVars, Types;

procedure DisplayMapView;
var
  { Unused in this version; see the other implementations of this routine. }
  wx: Integer;
  { Unused in this version; see the other implementations of this routine. }
  wy: Integer;

  { Returns the ceiling color for a ceiling and floor color selector. }
  function HorizonUpperColorOf(w: Byte): Byte;
  begin
    case w of
      $08: HorizonUpperColorOf := Black;
      $41: HorizonUpperColorOf := Black;
      $E8: HorizonUpperColorOf := White;
    else HorizonUpperColorOf := White
    end
  end;

  { Returns the floor color for a ceiling and floor color selector. }
  function HorizonLowerColorOf(w: Byte): Byte;
  begin
    case w of
      $08: HorizonLowerColorOf := DarkGray;
      $41: HorizonLowerColorOf := LightGray;
      $E8: HorizonLowerColorOf := LightGray;
    else HorizonLowerColorOf := LightGray
    end
  end;

  { Returns the wall color for a wall color selector. }
  function FloorColorOf(w: Byte): Byte;
  begin
    case w of
      $0B: FloorColorOf := DarkGray;
      $09: FloorColorOf := Brown;
      $DB: FloorColorOf := Brown;
      $06: FloorColorOf := Blue;
    else FloorColorOf := Brown
    end
  end;
begin
  if GDVars.pictureArchiveId = 9 then GDVars.forceMapRedraw := 0;
  if GDVars.partyDefeated <> 0 then Exit;
  if (GDVars.zone0^.inDungeon <> 0) or (GDVars.zone0^.wildOn <> 1) then begin
    GDVars.mapState.event := View3D.GetMapEvent(Byte(GDVars.mapState.x), Byte(GDVars.mapState.y));
    if GDVars.mapState.event > $7F then
      GDVars.paletteSky := GDConsts.skyColors[GDVars.zone0^.skyA]
    else
      GDVars.paletteSky := GDConsts.skyColors[GDVars.zone0^.skyB];
    if GDVars.displayMode = Types.Cga then begin
      if GDVars.wallColorsChanged <> 0 then begin
        GDVars.paletteCeil := HorizonUpperColorOf(GDVars.ceilingFloorColorSet);
        GDVars.paletteFloor := HorizonLowerColorOf(GDVars.ceilingFloorColorSet);
        GDVars.paletteWall := FloorColorOf(GDVars.wallColorSet);
        View3D.SetViewColors(GDVars.paletteSky, GDVars.paletteCeil, GDVars.paletteFloor, GDVars.paletteWall)
      end
    end else
      GDVars.paletteWall := DarkGray;
    if GDVars.zone0^.automapLock <> 0 then GDVars.automapOn := 0;
    View3D.Display3DMapView(Byte(GDVars.mapState.x), Byte(GDVars.mapState.y), GDVars.mapState.facing)
  end else begin
    if GDVars.forceMapRedraw <> 0 then begin
      if (GDVars.bigPic = nil) or (GDVars.bigId <> 112) then
        Portrait.LoadBigPic(112);
      Portrait.DisplayBigPic
    end
  end;
  GDVars.forceMapRedraw := 0
end;
begin
end.
