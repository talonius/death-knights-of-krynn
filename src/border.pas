{ Border -- the screen frames, drawn in 8x8 symbols from set 4 (256 plus a table entry), with the three moons' phase
  symbols in the top row at columns 8, 19 and 30; and ClearBox, which blackens a rectangle of character cells in CGA,
  EGA or Tandy memory. Every routine hides the mouse while it draws. }
{$O+,F+,S-,R-,V-,B-,I-}
unit Border;
interface

{ Clears the window and draws the outer frame: row 0, whose junctions at columns 8, 19 and 30 show the phases of the
  three moons, the bottom row, and columns 0 and 39 between them.
  @param(layout 0 clears rows 1..22 inside the frame and puts the bottom row at row 23; 1 clears the whole screen and
    puts it at row 22; 2 clears rows 1..16 inside the frame, leaving the rows below as they were, with the bottom row at
    row 23.) }
procedure DrawWindowFrame(layout: Byte);

{ Draws the exploration layout: the outer frame, a horizontal rule across row 16, a vertical rule down column 16 from
  row 0 to row 16, and an inner box on columns and rows 2..14. }
procedure DrawViewFrame;

{ Draws the outer frame (layout 0) and a horizontal rule across row 16. }
procedure DrawRowDivider;

{ Draws the outer frame and a horizontal rule across row 16, but clears only rows 1..16 inside the frame, leaving rows
  17..22 as they were. }
procedure DrawMemorizeFrame;

{ Clears the whole screen and draws the combat layout: row 0, columns 0, 22 and 39 from row 0 to row 22, and a bottom
  row across row 22. Row 23 is left blank. }
procedure DrawCombatFrame;

{ Clears the whole screen and draws the character sheet layout: row 0 with the moon phase junctions, the bottom row at
  row 23, horizontal rules across rows 8, 16 and 20, columns 0 and 39 from row 1 to row 22, and a vertical rule down
  column 19 from row 8 to row 20. }
procedure DrawCharSheetFrame;

{ Draws the outer frame and a horizontal rule across row 2. }
procedure DrawTitleInset;

{ Clears a rectangle of character cells, corners included, to color 0 directly in video memory, with the mouse cursor
  hidden. CGA clears the four scanlines of each cell row in both of its banks, EGA clears both display pages, and Tandy
  clears two scanlines in each of its four banks.
  @param(x1 Left column.)
  @param(y1 Top row.)
  @param(x2 Right column.)
  @param(y2 Bottom row.) }
procedure ClearBox(x1, y1, x2, y2: ShortInt);
implementation
uses C_Video, Mouse, TextRend, Sym8x8, GDConsts, GDVars, Types;
type
  TCga = array[0..99, 0..79] of Byte;
  TTandy = array[0..49, 0..159] of Byte;
var
  { the even scan lines, then the odd }
  cgaBank0: TCga absolute C_Video.GFX_BANK0_SEG: 0;
  cgaBank1: TCga absolute C_Video.GFX_BANK1_SEG: 0;
  { scan lines 0, 1, 2, 3 mod 4 }
  tandyBank0: TTandy absolute C_Video.GFX_BANK0_SEG: 0;
  tandyBank1: TTandy absolute C_Video.GFX_BANK1_SEG: 0;
  tandyBank2: TTandy absolute C_Video.GFX_BANK2_SEG: 0;
  tandyBank3: TTandy absolute C_Video.GFX_BANK3_SEG: 0;

procedure DrawWindowFrame(layout: Byte);
var
  column: Byte;
  row: Byte;
  tile: Byte;
  bottomRow: Byte;
  { Unused in this version; see the other implementations of this routine. }
  tileBuffer: array[0..511] of Byte;
begin
  Mouse.HideMouse;
  case layout of
    0: begin bottomRow := 23; Border.ClearBox(1, 1, 38, 22) end;
    1: begin bottomRow := 22; Border.ClearBox(0, 0, 39, 23) end;
    2: begin bottomRow := 23; Border.ClearBox(1, 1, 38, 16) end;
  end;
  for column := 0 to 39 do begin
    case column of
      8: tile := GDVars.zone0^.moonPhase[$4CF9] + 21;
      19: tile := GDVars.zone0^.moonPhase[$4CFA] + 13;
      30: tile := GDVars.zone0^.moonPhase[$4CFB] + 17;
    else tile := GDConsts.borderTopRow[column] end;
    Sym8x8.Put8x8Sym(column, 0, 256 + tile, False, False);
    tile := GDConsts.borderBottomRow[column];
    Sym8x8.Put8x8Sym(column, bottomRow, 256 + tile, False, False);
  end;
  for row := 1 to bottomRow - 1 do begin
    Sym8x8.Put8x8Sym(0, row, 263, False, False);
    Sym8x8.Put8x8Sym(39, row, 263, False, False);
  end;
  Mouse.ShowMouse;
end;

procedure DrawViewFrame;
var
  i: Byte;
  j: Byte;
begin
  Mouse.HideMouse; Border.DrawWindowFrame(0);
  for i := 0 to 39 do Sym8x8.Put8x8Sym(i, 16, 256 + GDConsts.dividerRow[i], False, False);
  for j := 0 to 16 do Sym8x8.Put8x8Sym(16, j, 256 + GDConsts.insetColumn[j], False, False);
  Sym8x8.Put8x8Sym(2, 2, 256, False, False); Sym8x8.Put8x8Sym(14, 2, 257, False, False);
  Sym8x8.Put8x8Sym(2, 14, 258, False, False); Sym8x8.Put8x8Sym(14, 14, 259, False, False);
  for i := 3 to 13 do begin
    Sym8x8.Put8x8Sym(i, 2, 260, False, False); Sym8x8.Put8x8Sym(i, 14, 260, False, False)
  end;
  for j := 3 to 13 do begin
    Sym8x8.Put8x8Sym(2, j, 263, False, False); Sym8x8.Put8x8Sym(14, j, 263, False, False)
  end;
  Mouse.ShowMouse;
end;

procedure DrawRowDivider;
var column: Byte;
begin
  Mouse.HideMouse; Border.DrawWindowFrame(0);
  for column := 0 to 39 do Sym8x8.Put8x8Sym(column, 16, 256 + GDConsts.dividerRow[column], False, False);
  Mouse.ShowMouse
end;

procedure DrawMemorizeFrame;
var
  i: Byte;
  { Unused in this version; see the other implementations of this routine. }
  tileOffset: Word;
begin
  Border.DrawWindowFrame(2); Mouse.HideMouse;
  for i := 0 to 39 do Sym8x8.Put8x8Sym(i, 16, 256 + GDConsts.dividerRow[i], False, False);
  Mouse.ShowMouse
end;

procedure DrawCombatFrame;
var
  { Unused in this version; see the other implementations of this routine. }
  column: Byte;
  j: Byte;
  { Unused in this version; see the other implementations of this routine. }
  tileOffset: Word;
begin
  Border.DrawWindowFrame(1); Mouse.HideMouse;
  for j := 0 to 22 do Sym8x8.Put8x8Sym(22, j, 256 + GDConsts.dualPaneColumn[j], False, False);
  Mouse.ShowMouse
end;

procedure DrawCharSheetFrame;
var
  column: Byte;
  row: Byte;
  tile: Byte;
begin
  Mouse.HideMouse; Border.ClearBox(0, 0, 39, 23);
  for column := 0 to 39 do begin
    case column of
      8: tile := GDVars.zone0^.moonPhase[$4CF9] + 21;
      19: tile := GDVars.zone0^.moonPhase[$4CFA] + 13;
      30: tile := GDVars.zone0^.moonPhase[$4CFB] + 17;
    else tile := GDConsts.borderTopRow[column] end;
    Sym8x8.Put8x8Sym(column, 0, 256 + tile, False, False);
    tile := GDConsts.borderBottomRow[column]; Sym8x8.Put8x8Sym(column, 23, 256 + tile, False, False);
    if (column <> 0) and (column <> 39) then begin
      Sym8x8.Put8x8Sym(column, 8, 260, False, False);
      Sym8x8.Put8x8Sym(column, 16, 260, False, False);
      Sym8x8.Put8x8Sym(column, 20, 260, False, False)
    end
  end;
  for row := 1 to 22 do begin
    Sym8x8.Put8x8Sym(0, row, 256 + GDConsts.combatLeftColumn[row], False, False);
    Sym8x8.Put8x8Sym(39, row, 256 + GDConsts.combatRightColumn[row], False, False)
  end;
  for row := 8 to 20 do Sym8x8.Put8x8Sym(19, row, 256 + GDConsts.combatMidColumn[row], False, False);
  Mouse.ShowMouse
end;

procedure DrawTitleInset;
var column: Byte;
begin
  Mouse.HideMouse; Border.DrawWindowFrame(0);
  for column := 0 to 39 do Sym8x8.Put8x8Sym(column, 2, 256 + GDConsts.dividerRow[column], False, False);
  Mouse.ShowMouse
end;

procedure ClearBox(x1, y1, x2, y2: ShortInt);
var
  top: Word;
  bot: Word;
  colOff: Word;
  rowBytes: Word;
  { Unused in this version; see the other implementations of this routine. }
  cgaColumnOffset: Word;
  r: Word;
begin
  Mouse.HideMouse;
  case GDVars.displayMode of
    Types.Cga: begin
      top := y1 * 4; bot := y2 * 4 + 3; rowBytes := (x2 - x1 + 1) * 2;
      for r := top to bot do begin
        FillChar(cgaBank0[r, x1 * 2], rowBytes, 0); FillChar(cgaBank1[r, x1 * 2], rowBytes, 0)
      end
    end;
    Types.Ega: begin
      TextRend.FillRectEga(x1, y1, x2, y2, 0, 0); TextRend.FillRectEga(x1, y1, x2, y2, 1, 0)
    end;
    Types.Tandy: begin
      top := y1 * 2; bot := y2 * 2 + 1; colOff := x1 * 4; rowBytes := (x2 - x1 + 1) * 4;
      for r := top to bot do begin
        FillChar(tandyBank0[r, colOff], rowBytes, 0); FillChar(tandyBank1[r, colOff], rowBytes, 0);
        FillChar(tandyBank2[r, colOff], rowBytes, 0); FillChar(tandyBank3[r, colOff], rowBytes, 0)
      end
    end
  end;
  Mouse.ShowMouse
end;
begin
end.
