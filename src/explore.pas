{ Explore -- the party's movement commands between script events: the 3-D and overland menus EclVm runs, and the step
  that follows them. }
{$O+,F+}
unit Explore;
interface

{ Applies the pending move: in the dungeon, marks the map for redraw and steps forward when the way ahead is open; on
  the overland or area map, takes a MovePartyWilderness step; either way the position and time are redrawn. A suppressed
  movement state (255) is cleared instead in the dungeon and in any other interface state, but kept on the overland or
  area map. Finally frees the portrait animation. }
procedure ResolveMovement;

{ The movement menu, for EclVm; it returns the last choice or key. In the 3-D view choice 0 opens the arrow row, 1
  toggles the automap (refused while the zone locks it, unless the second command-line parameter is the debug password),
  2 casts if the current character is okay, 3 views, 4 ends the menu, 5 toggles the search bit, and 6 sets bit 1,
  advances time and resumes the script at its after-move entry; an extended key selects the adjacent character. In the
  arrow row up checks the map edge and ends the menu, down turns about, and left and right turn a quarter. Overland,
  while travel is on, the menu offers 0 and 4, and the arrow row picks one of eight facings from the keypad and ends it.
  The move lock is cleared first, and the bottom window cleared after if it is not.
  @returns(The last choice or key; 255 after a turn or a step in the 3-D view's arrow row.) }
function MapMainMenu: Char;
implementation
uses C_Dir, C_Ifc, C_Keys, C_Status, GDConsts, GDVars, CharHlp, MenuCore, Mouse, TextRend, Crt,
  Border, View3D, Music, GameTime, Camp, ViewChar, MapCurs, Portrait;

{ Clears the zone's leave-map flag, then, when the barrier ahead lets the party through and the step would leave the
  16x16 map, clamps the position to the edge and sets the flag. }
procedure MoveForward;
var
  nx: Integer;
  ny: Integer;
  face: Word;
begin
  nx := GDVars.mapState.x; ny := GDVars.mapState.y; face := GDVars.mapState.facing;
  GDVars.zone1^.leaveMap[GDConsts.leaveMapIndex + $7C00] := 0;
  if View3D.GetBarrierType(nx, ny, face) <> 0 then begin
    Inc(nx, GDConsts.combatTables.directionX[face]);
    Inc(ny, GDConsts.combatTables.directionY[face]);
    if nx > 15 then begin GDVars.mapState.x := 15; GDVars.zone1^.leaveMap[GDConsts.leaveMapIndex + $7C00] := 1 end;
    if nx < 0 then begin GDVars.mapState.x := 0; GDVars.zone1^.leaveMap[GDConsts.leaveMapIndex + $7C00] := 1 end;
    if ny > 15 then begin GDVars.mapState.y := 15; GDVars.zone1^.leaveMap[GDConsts.leaveMapIndex + $7C00] := 1 end;
    if ny < 0 then begin GDVars.mapState.y := 0; GDVars.zone1^.leaveMap[GDConsts.leaveMapIndex + $7C00] := 1 end;
  end;
end;

{ Takes one step forward with the step sound and a short pause, wrapping around the map edge, looks up the wall ahead
  and the new cell's event, and advances the clock: one minute, or ten while searching. }
procedure MovePartyForward3D;
begin
  Music.SendSoundCommand(GDConsts.stepSound);
  Delay(50);
  Inc(GDVars.mapState.x, GDConsts.combatTables.directionX[GDVars.mapState.facing]);
  Inc(GDVars.mapState.y, GDConsts.combatTables.directionY[GDVars.mapState.facing]);
  if GDVars.mapState.x < 0 then GDVars.mapState.x := 15;
  if GDVars.mapState.x > 15 then GDVars.mapState.x := 0;
  if GDVars.mapState.y < 0 then GDVars.mapState.y := 15;
  if GDVars.mapState.y > 15 then GDVars.mapState.y := 0;
  GDVars.mapState.wallAhead := View3D.GetWallType(GDVars.mapState.x, GDVars.mapState.y, GDVars.mapState.facing);
  GDVars.mapState.event := View3D.GetMapEvent(GDVars.mapState.x, GDVars.mapState.y);
  if GDVars.zone1^.searchFlags[GDConsts.searchFlagsIndex + $7C00] and GDConsts.searchMask[0] >
      0 then GameTime.AdvanceTime(1, 2)
  else GameTime.AdvanceTime(1, 1);
end;

{ Moves the party cursor one cell on the overland map in its facing, kept within columns 0..37 and rows 0..14, remembers
  the previous position, and advances the clock 12 hours. }
procedure MovePartyWilderness;
var
  { Unused in this version; see the other implementations of this routine. }
  column: Byte;
  nx: ShortInt;
  ny: ShortInt;
begin
  Mouse.HideMouse; MapCurs.RestoreCursorBackground;
  GDVars.zone0^.prevX := GDVars.zone0^.wildX; GDVars.zone0^.prevY := GDVars.zone0^.wildY;
  nx := GDVars.zone0^.wildX + GDConsts.combatTables.directionX[GDVars.mapState.facing];
  ny := GDVars.zone0^.wildY + GDConsts.combatTables.directionY[GDVars.mapState.facing];
  if nx < 0 then nx := 0; if nx > 37 then nx := 37;
  if ny < 0 then ny := 0; if ny > 14 then ny := 14;
  GDVars.zone0^.wildX := nx; GDVars.zone0^.wildY := ny;
  MapCurs.DrawCursor; Mouse.ShowMouse; GameTime.AdvanceTime(12, 3);
end;

function MapMainMenu: Char;
var
  done: Boolean;
  selection: Byte;
  c: Char;
  viewFlag: Boolean;
  { Unused in this version; see the other implementations of this routine. }
  menuList: Pointer;
  { Unused in this version; see the other implementations of this routine. }
  menuNode: Pointer;
  { Unused in this version; see the other implementations of this routine. }
  savedMenu: Pointer;
  savedChoice: Byte;
begin
  GDVars.zone1^.moveLocked[GDConsts.moveLockedIndex + $7C00] := 0;
  savedChoice := GDVars.selectedChoice;
  case GDVars.interfaceState of
    C_Ifc.VIEW_3D: begin
      done := False; c := #255;
      repeat
        if GDVars.extendedMode = 0 then begin
          MenuCore.EnableChoices(6); GDVars.selectedChoice := savedChoice;
          c := Char(MenuCore.MenuHorizontal(GDConsts.emptyQuery, GDConsts.dungeonMenu, 1, 0));
          savedChoice := GDVars.selectedChoice;
          if GDVars.menuExtendedKey = 0 then begin
            case c of
              #0: begin MenuCore.ClearBottomLine; GDVars.extendedMode := 1 end;
              #1: begin
                if (GDVars.zone0^.automapLock = 0) or (ParamStr(2) = GDVars.debugPassword) then begin
                  GDVars.automapOn := Ord(GDVars.automapOn = 0);
                  View3D.Display3DMapView(GDVars.mapState.x, GDVars.mapState.y, GDVars.mapState.facing)
                end else TextRend.PrintAndPause(GDConsts.notHere, Yellow, Black)
              end;
              #2: if GDVars.currentCharacter^.status = C_Status.OKAY then Camp.NoncombatCastMenu;
              #3: ViewChar.ViewCharMenu(viewFlag);
              #4: done := True;
              #5: begin
                GDVars.zone1^.searchFlags[GDConsts.searchFlagsIndex +
                                            $7C00] := GDVars.zone1^.searchFlags[GDConsts.searchFlagsIndex + $7C00] xor
                  GDConsts.searchMask[0];
                CharHlp.PrintMiscInfo
              end;
              #6: begin
                GDVars.zone1^.searchFlags[GDConsts.searchFlagsIndex +
                                            $7C00] := GDVars.zone1^.searchFlags[GDConsts.searchFlagsIndex + $7C00] or
                  $02;
                CharHlp.PrintMiscInfo;
                GameTime.AdvanceTime(1, 2); GDVars.eclIp := GDVars.eclEntryPoints.entryAfterMove; done := True
              end
            end
          end else begin
            CharHlp.DisplayRoster(GDVars.currentCharacter, False); ViewChar.SelectAdjacentCharacter(c);
            CharHlp.DisplayRoster(GDVars.currentCharacter, True); CharHlp.PrintMiscInfo
          end
        end else begin
          FillChar(GDVars.enabledChoices, SizeOf(GDVars.enabledChoices), $FF);
          MenuCore.EnableChoices(0);
          c := Char(MenuCore.MenuHorizontal(GDConsts.emptyQuery, GDConsts.exitMenu, 1, 0));
          if GDVars.menuExtendedKey = 0 then begin
            if c = #0 then GDVars.extendedMode := 0
          end else begin
            case c of
              C_Keys.UP: begin Explore.MoveForward; done := True; CharHlp.PrintMiscInfo; c := #255 end;
              C_Keys.DOWN: begin
                GDVars.mapState.facing := (GDVars.mapState.facing + 4) mod 8;
                GDVars.mapState.wallAhead := View3D.GetWallType(GDVars.mapState.x, GDVars.mapState.y,
                                                                  GDVars.mapState.facing);
                View3D.Display3DMapView(GDVars.mapState.x, GDVars.mapState.y,
                                        GDVars.mapState.facing); CharHlp.PrintMiscInfo; c := #255
              end;
              C_Keys.LEFT: begin
                GDVars.mapState.facing := (GDVars.mapState.facing + 6) mod
                  8; Music.SendSoundCommand(GDConsts.stepSound);
                GDVars.mapState.wallAhead := View3D.GetWallType(GDVars.mapState.x, GDVars.mapState.y,
                                                                  GDVars.mapState.facing);
                View3D.Display3DMapView(GDVars.mapState.x, GDVars.mapState.y,
                                        GDVars.mapState.facing); CharHlp.PrintMiscInfo; c := #255
              end;
              C_Keys.RIGHT: begin
                GDVars.mapState.facing := (GDVars.mapState.facing + 2) mod
                  8; Music.SendSoundCommand(GDConsts.stepSound);
                GDVars.mapState.wallAhead := View3D.GetWallType(GDVars.mapState.x, GDVars.mapState.y,
                                                                  GDVars.mapState.facing);
                View3D.Display3DMapView(GDVars.mapState.x, GDVars.mapState.y,
                                        GDVars.mapState.facing); CharHlp.PrintMiscInfo; c := #255
              end;
              C_Keys.ESCAPE: GDVars.extendedMode := 0
            end
          end
        end
      until done
    end;
    C_Ifc.OVERLAND: if GDVars.zone0^.wildOn <> 0 then begin
      done := False;
      repeat
        FillChar(GDVars.enabledChoices, SizeOf(GDVars.enabledChoices), $FF);
        if GDVars.extendedMode = 0 then begin
          selection := 0;
          MenuCore.AppendChoice(0, selection);
          MenuCore.AppendChoice(4, selection);
          GDVars.selectedChoice := savedChoice;
          c := Char(MenuCore.MenuHorizontal(GDConsts.emptyQuery, GDConsts.dungeonMenu, 1, 0));
          savedChoice := GDVars.selectedChoice;
          if GDVars.menuExtendedKey = 0 then begin
            case c of
              #0: begin MenuCore.ClearBottomLine; GDVars.extendedMode := 1 end;
              #4: done := True
            end
          end
        end else begin
          FillChar(GDVars.enabledChoices, SizeOf(GDVars.enabledChoices), $FF);
          GDVars.enabledChoices[0].ordinal := 0;
          c := Char(MenuCore.MenuHorizontal(GDConsts.emptyQuery, GDConsts.exitMenu, 1, 0));
          if GDVars.menuExtendedKey = 0 then begin if c = #0 then GDVars.extendedMode := 0 end
          else begin
            done := True;
            case c of
              C_Keys.UP: GDVars.mapState.facing := C_Dir.NORTH; C_Keys.PAGE_UP: GDVars.mapState.facing :=
                C_Dir.NORTHEAST; C_Keys.RIGHT:
                  GDVars.mapState.facing := C_Dir.EAST; C_Keys.PAGE_DOWN: GDVars.mapState.facing := C_Dir.SOUTHEAST;
              C_Keys.DOWN: GDVars.mapState.facing := C_Dir.SOUTH; C_Keys.END_KEY: GDVars.mapState.facing :=
                C_Dir.SOUTHWEST; C_Keys.LEFT:
                  GDVars.mapState.facing := C_Dir.WEST; C_Keys.HOME: GDVars.mapState.facing := C_Dir.NORTHWEST;
              C_Keys.ESCAPE: GDVars.extendedMode := 0
            end;
            CharHlp.PrintMiscInfo
          end
        end
      until done
    end
  end;
  if GDVars.bottomClear = 0 then begin Border.ClearBox(1, 17, 38, 22); GDVars.bottomClear := 1 end;
  MapMainMenu := c
end;

procedure ResolveMovement;
var
  { Unused in this version; see the other implementations of this routine. }
  moved: Boolean;
begin
  moved := False;
  case GDVars.interfaceState of
    C_Ifc.VIEW_3D: begin
      if GDVars.zone1^.moveLocked[GDConsts.moveLockedIndex + $7C00] < 255 then begin
        GDVars.forceMapRedraw := 1;
        if View3D.GetBarrierType(GDVars.mapState.x, GDVars.mapState.y,
                                 GDVars.mapState.facing) = 1 then begin moved := True; Explore.MovePartyForward3D end;
        CharHlp.PrintMiscInfo
      end else GDVars.zone1^.moveLocked[GDConsts.moveLockedIndex + $7C00] := 0
    end;
    C_Ifc.OVERLAND: begin
      if GDVars.zone1^.moveLocked[GDConsts.moveLockedIndex +
                                    $7C00] < 255 then begin Explore.MovePartyWilderness; CharHlp.PrintMiscInfo end
    end else GDVars.zone1^.moveLocked[GDConsts.moveLockedIndex + $7C00] := 0
  end;
  Portrait.FreeAnimation(GDVars.portraitAnimation);
end;
begin
end.
