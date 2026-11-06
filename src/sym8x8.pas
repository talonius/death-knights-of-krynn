{ Sym8x8 -- the 8x8 symbol sets: the border, wall and map symbols drawn one 8x8 cell at a time. GameInit and View3D load
  the five sets into symbolSets; Border, GameTime and View3D draw from them. A symbol number picks its set by the
  symbolSetFirst and symbolSetLast ranges. }
{$O+,F+,I-}
unit Sym8x8;
interface

{ Loads block fileId of an 8x8d archive into set setId (0..4); any other setId does nothing. Set 0 takes the archive by
  fileId (the disk each block is on), the others the current disk's, disk 5 using disk 1's. Light magenta (13) is
  transparent except in set 4. If the load fails it restores the video mode, prints the file and block, waits for a key
  and aborts.
  @param(fileId Block number within the archive.)
  @param(setId Symbol set to load, 0..4.) }
procedure Load8x8Set(fileId, setId: Byte);

{ Draws symbol at cell (col, row). Symbol 0, one past every set, or one in a set not loaded draws nothing. With combat
  set it blits the symbol's frame `other` into the composite buffer; otherwise it copies the symbol into symbolScratch
  and shows it.
  @param(col Column, in character cells.)
  @param(row Row, in character cells.)
  @param(symbol Symbol number, which picks its set.)
  @param(combat True to draw into the composite buffer instead of the screen.)
  @param(other Bit 0 of the blit flag when combat is set: draw through the symbol's mask.) }
procedure Put8x8Sym(col, row: ShortInt; symbol: Word; combat, other: Boolean);
implementation
uses GDConsts, GDVars, Crt, Blit, GameIo;

procedure Load8x8Set(fileId, setId: Byte);
var
  suffix: String[1];
  { Unused in this version; see the other implementations of this routine. }
  dataSize: Word;
  { Unused in this version; see the other implementations of this routine. }
  ch: Char;
  transp: Byte;
begin
  if setId in [0..4] then begin
    { light magenta is the wall sets' transparent color }
    if setId = 4 then transp := Black else transp :=
        LightMagenta;
    if setId = 0 then begin
      { the disk each 8x8 block is on }
      case fileId of
        1: suffix := '1';
        2: suffix := '4';
        3, 4: suffix := '2';
        5, 6: suffix := '3';
        7: suffix := '5';
      else Str(GDVars.diskNumber, suffix)
      end
    end else begin
      if GDVars.diskNumber = 5 then suffix := '1'
      else Str(GDVars.diskNumber, suffix)
    end;
    Blit.LoadPic('8x8d' + suffix, fileId, Boolean(GDConsts.iconFrame), transp, GDVars.symbolSets[setId]);
    if GDVars.symbolSets[setId] = nil then begin
      Blit.RestoreVideoMode;
      WriteLn(Output, GDConsts.loadError, fileId, GDConsts.from8x8 + suffix);
      ch := GameIo.ReadGameKey;
      Blit.RestoreVideoMode;
      GameIo.ExitGame
    end
  end
end;

procedure Put8x8Sym(col, row: ShortInt; symbol: Word; combat, other: Boolean);
var
  setIdx: Byte;
  { Unused in this version; see the other implementations of this routine. }
  ch: Char;
begin
  setIdx := 0;
  while GDConsts.symbolSetLast[setIdx] < symbol do Inc(setIdx);
  if (symbol = 0) or (setIdx > 4) or (GDVars.symbolSets[setIdx] = nil) then
  else begin
    Dec(symbol, GDConsts.symbolSetFirst[setIdx]);
    if combat then
      Blit.BlitTileCell(col, row, symbol, Ord(other), GDVars.symbolSets[setIdx], GDVars.compositeBuffer)
    else begin
      with GDVars.symbolSets[setIdx]^ do
        Move(data[symbol * imgSize], GDVars.symbolScratch^.data, imgSize);
      Blit.ShowPic(col, row, GDVars.symbolScratch)
    end
  end
end;
begin end.
