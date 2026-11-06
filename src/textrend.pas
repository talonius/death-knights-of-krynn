{ TextRend -- text on the graphics screen, in the 8x8 game font on a 40x25 cell grid: a character through TEXTREND.OBJ's
  CGA, EGA or Tandy blitter, strings, the word-wrapping message window, the message-line prompts and pauses, typed
  input, and clearing the screen or a rectangle of cells. }
{$O+,F+,S-,R-,V-,B-,I-}
unit TextRend;
interface
uses C_Keys, C_Ega, C_Video, GDConsts, GDVars, Mouse, DaxIo, GameIo, Crt, Dos, Types;

{ Resets the EGA graphics controller (registers 0 to 5 to 0, color don't-care $0F, bit mask $FF) and enables writes to
  the four planes. }
procedure ResetEgaGc;

{ Shows an EGA page (video BIOS function 5) and records its segment as the current page.
  @param(page The page to show.) }
procedure SetupEgaCurrentPage(page: Byte);

{ Records an EGA page's segment as the other page.
  @param(page The page.) }
procedure SetupEgaOtherPage(page: Byte);

{ Fills a character-cell rectangle of an EGA page with one color in write mode 2, then restores write mode 0 and points
  the other page back at the page number saved for it.
  @param(ulCol Left column.)
  @param(ulRow Top row.)
  @param(lrCol Right column.)
  @param(lrRow Bottom row.)
  @param(page The EGA page to fill.)
  @param(color The fill color.) }
procedure FillRectEga(ulCol, ulRow, lrCol, lrRow: ShortInt; page, color: Byte);

{ Loads the 8x8 game font (block 201 of 8X8D1.DAX) into the font buffer; nothing happens when it is missing. }
procedure LoadGameFont;

{ Draws a run of one character rightward from a cell, with the display mode's glyph routine. Nothing is drawn when the
  first cell is off the 40x25 screen or there is no font; the run itself is not clipped.
  @param(col The first cell's column.)
  @param(row The cell row.)
  @param(fg The character's color.)
  @param(bg The background color.)
  @param(count How many times to draw it.)
  @param(ch The character, or a font index when the translate flag is 0.)
  @param(isAscii Nonzero to upper-case the character and take it mod 64 as the font index.) }
procedure RenderChar(col, row, fg, bg, count, ch, isAscii: Byte);

{ Blanks a run of cells with the mouse cursor hidden. Note: a first cell off the screen exits early and leaves the mouse
  hidden.
  @param(col The first cell's column.)
  @param(row The cell row.)
  @param(color The color to blank to.)
  @param(count The number of cells.) }
procedure PrintSpaces(col, row, color, count: Byte);

{ Writes a string from a cell, one character per cell, with the mouse cursor hidden; characters off the screen are not
  drawn. Note: a column above 39 or a row above 39 exits early and leaves the mouse hidden.
  @param(col The first character's column.)
  @param(row The row.)
  @param(fg The text color.)
  @param(bg The background color.)
  @param(source The text.) }
procedure DisplayString(col, row, fg, bg: Byte; source: String);

{ Writes a string word-wrapped into a window, from the text cursor when it is inside the window, else, or after clearing
  when asked, from the top left. Punctuation stays with the word next to it. Characters appear one by one with a delay
  while slow text is on. When the window fills with text left over, it waits for a key and goes on in the cleared
  window. The text cursor is left after the text. Note: the check meant to keep a word whose trailing space alone
  overruns the right edge can never hold, so such a word wraps as well; and a window edge off the screen exits early
  with the mouse left hidden.
  @param(ulCol Left column of the window.)
  @param(ulRow Top row of the window.)
  @param(lrCol Right column of the window.)
  @param(lrRow Bottom row of the window.)
  @param(fg The text color.)
  @param(bg The background color.)
  @param(clearFirst True to clear the window and start at its top left.)
  @param(source The text.) }
procedure DisplayMessageWindow(ulCol, ulRow, lrCol, lrRow, fg, bg: Byte; clearFirst: Boolean; source: String);

{ Shows a prompt on the bottom row and reads text from the keyboard, echoed in white: a space through z is added while
  there is room and backspace deletes, until Enter or Escape, or after the first key while the demo runs. The row is
  cleared afterwards.
  @param(query The prompt.)
  @param(fg The prompt's color.)
  @param(bg The prompt's background color.)
  @param(maxLen The most characters accepted.)
  @returns(The text typed, upper-cased; Escape returns it too.) }
function ReadString(query: Types.TString40; fg, bg, maxLen: Byte): Types.TString40;

{ Reads numbers of up to six characters (ReadString) until one parses within 0 to 65536. Note: 65536 is accepted and
  becomes 0.
  @param(query The prompt.)
  @param(fg The prompt's color.)
  @param(bg The prompt's background color.)
  @returns(The number.) }
function ReadNumber(query: Types.TString40; fg, bg: Byte): Word;

{ Shows a message on the bottom row and waits for a key; the message stays.
  @param(fg The text color.)
  @param(bg The background color.)
  @param(msg The message.) }
procedure DisplayAndPause(fg, bg: Byte; msg: Types.TString40);

{ Reads the time of day.
  @returns(The time since midnight in hundredths of a second.) }
function GetTicks: LongInt;

{ Clears the whole screen to black: both EGA pages, or each CGA or Tandy bank. }
procedure ClearScreen;

{ Shows a message on the bottom row for the game-speed pause (PauseOnly), then clears the row.
  @param(msg The message.)
  @param(fg The text color.)
  @param(bg The background color.) }
procedure PrintAndPause(msg: Types.TString40; fg, bg: Byte);

{ Waits for the game-speed setting times 100 milliseconds. }
procedure PauseOnly;

{ Clears a character-cell rectangle to black, on both EGA pages, with the mouse cursor hidden.
  @param(ulCol Left column.)
  @param(ulRow Top row.)
  @param(lrCol Right column.)
  @param(lrRow Bottom row.) }
procedure ClearRect(ulCol, ulRow, lrCol, lrRow: ShortInt);

{ Pads a String[40] with spaces on the left to n characters.
  @param(source The string, padded in place.)
  @param(n Length to pad to.) }
procedure RightAlignString(var source; n: Byte);
implementation
var
  cgaBank0: array[0..255] of array[0..39] of Word absolute C_Video.GFX_BANK0_SEG: $0000;
  cgaBank1: array[0..255] of array[0..39] of Word absolute C_Video.GFX_BANK1_SEG: $0000;
  tandyBank0: array[0..255] of array[0..159] of Byte absolute C_Video.GFX_BANK0_SEG: $0000;
  tandyBank1: array[0..255] of array[0..159] of Byte absolute C_Video.GFX_BANK1_SEG: $0000;
  tandyBank2: array[0..255] of array[0..159] of Byte absolute C_Video.GFX_BANK2_SEG: $0000;
  tandyBank3: array[0..255] of array[0..159] of Byte absolute C_Video.GFX_BANK3_SEG: $0000;
{$F-}
{$L TEXTREND.OBJ}

{ Draws one character cell on CGA from the glyph rows that RenderChar staged.
  @param(col The cell column.)
  @param(row The cell row.)
  @param(fg The color of the glyph's set pixels.)
  @param(bg The color of its clear pixels.)
  @param(charIdx Unused.) }
procedure CgaGlyph(col, row: Word; fg, bg, charIdx: Byte); external;

{ Draws one character cell on EGA from the glyph rows that RenderChar staged.
  @param(col The cell column.)
  @param(row The cell row.)
  @param(fg The color of the glyph's set pixels.)
  @param(bg The color of its clear pixels.)
  @param(charIdx Unused.) }
procedure EgaGlyph(col, row: Word; fg, bg, charIdx: Byte); external;

{ Draws one character cell on Tandy from the glyph rows that RenderChar staged.
  @param(col The cell column.)
  @param(row The cell row.)
  @param(fg The color of the glyph's set pixels.)
  @param(bg The color of its clear pixels.)
  @param(charIdx Unused.) }
procedure TandyGlyph(col, row: Word; fg, bg, charIdx: Byte); external;
{$F+}

procedure ResetEgaGc;
begin
  Port[GDConsts.graphicsAddressPort] := GDConsts.setResetRegister;
  Port[GDConsts.graphicsDataPort] := 0;
  Port[GDConsts.graphicsAddressPort] := GDConsts.enableSetResetRegister;
  Port[GDConsts.graphicsDataPort] := 0;
  Port[GDConsts.graphicsAddressPort] := GDConsts.colorCompareRegister;
  Port[GDConsts.graphicsDataPort] := 0;
  Port[GDConsts.graphicsAddressPort] := GDConsts.dataRotateRegister;
  Port[GDConsts.graphicsDataPort] := 0;
  Port[GDConsts.graphicsAddressPort] := GDConsts.readMapRegister;
  Port[GDConsts.graphicsDataPort] := 0;
  Port[GDConsts.graphicsAddressPort] := GDConsts.graphicsModeRegister;
  Port[GDConsts.graphicsDataPort] := 0;
  Port[GDConsts.graphicsAddressPort] := GDConsts.colorDontCareRegister;
  Port[GDConsts.graphicsDataPort] := $0F;
  Port[GDConsts.graphicsAddressPort] := GDConsts.bitMaskRegister;
  Port[GDConsts.graphicsDataPort] := $FF;
  Port[GDConsts.sequencerAddressPort] := GDConsts.mapMaskRegister;
  Port[GDConsts.sequencerDataPort] := C_Ega.MAP_MASK_ALL_PLANES;
end;

procedure SetupEgaCurrentPage(page: Byte);
begin
  GDVars.videoRegs.ah := GDConsts.biosSetPage;
  GDVars.videoRegs.al := page;
  Intr(GDConsts.videoInterrupt, Registers(GDVars.videoRegs));
  GDVars.currentPageSegment := C_Video.EGA_VIDEO_SEG + (Word(page) shl 9);
end;

procedure SetupEgaOtherPage(page: Byte);
begin
  GDVars.otherPageSegment := C_Video.EGA_VIDEO_SEG + (Word(page) shl 9);
end;

procedure FillRectEga(ulCol, ulRow, lrCol, lrRow: ShortInt; page, color: Byte);
var
  savedPage: Byte;
  dstOff: Word;
  rowCount: Word;
  i: Word;
begin
  savedPage := GDVars.otherEgaPage;
  dstOff := Word(ulRow) * 40 * 8 + ulCol;
  rowCount := (lrRow - ulRow + 1) * 8 - 1;
  TextRend.SetupEgaOtherPage(page);
  TextRend.ResetEgaGc;
  Port[GDConsts.graphicsAddressPort] := GDConsts.graphicsModeRegister; Port[GDConsts.graphicsDataPort] :=
    GDConsts.writeMode2;
  for i := 0 to rowCount do begin
    FillChar(Mem[GDVars.otherPageSegment: dstOff], lrCol - ulCol + 1, color);
    Inc(dstOff, 40);
  end;
  Port[GDConsts.graphicsAddressPort] := GDConsts.graphicsModeRegister; Port[GDConsts.graphicsDataPort] :=
    GDConsts.writeMode0;
  GDVars.otherEgaPage := savedPage;
  TextRend.SetupEgaOtherPage(GDVars.otherEgaPage);
end;

procedure LoadGameFont;
var
  compSize: Word;
  dataPtr: Types.PBytes;
begin
  DaxIo.LoadDax('8X8d1', GDConsts.daxExtension, 201, compSize, dataPtr);
  if compSize = 0 then Exit;
  Move(dataPtr^, GDVars.gameFont^, compSize);
  FreeMem(dataPtr, compSize);
end;

procedure RenderChar(col, row, fg, bg, count, ch, isAscii: Byte);
var
  i: Byte;
  charIdx: Byte;
  { Unused in this version; see the other implementations of this routine. }
  dstOff: Word;
  { Unused in this version; see the other implementations of this routine. }
  cnt: Word;
  { Unused in this version; see the other implementations of this routine. }
  colBase: Word;
  { Unused in this version; see the other implementations of this routine. }
  cgaWord: Word;
  { Unused in this version; see the other implementations of this routine. }
  tandyPx: Byte;
  { Unused in this version; see the other implementations of this routine. }
  k: Byte;
  { Unused in this version; see the other implementations of this routine. }
  mask: Byte;
  { Unused in this version; see the other implementations of this routine. }
  bank: Byte;
  { Unused in this version; see the other implementations of this routine. }
  outerRow: Byte;
  { Unused in this version; see the other implementations of this routine. }
  plane: Byte;
begin
  if (col > 39) or (row > 24) or (GDVars.gameFont = nil) then Exit;
  if isAscii <> 0 then
    charIdx := Ord(UpCase(Chr(ch))) mod 64
  else
    charIdx := ch;
  Move(GDVars.gameFont^[charIdx], GDVars.currentGlyph, SizeOf(GDVars.currentGlyph));
  case GDVars.displayMode of
    Types.Cga: for i := 1 to count do begin
         TextRend.CgaGlyph(col, row, fg, bg, charIdx); Inc(col);
       end;
    Types.Ega: for i := 1 to count do begin
         TextRend.EgaGlyph(col, row, fg, bg, charIdx); Inc(col);
       end;
    Types.Tandy: for i := 1 to count do begin
         TextRend.TandyGlyph(col, row, fg, bg, charIdx); Inc(col);
       end;
  end;
end;

procedure PrintSpaces(col, row, color, count: Byte);
begin
  Mouse.HideMouse;
  if (col < 0) or (col > 39) or (row < 0) or (row > 24) then Exit;
  TextRend.RenderChar(col, row, color, color, count, 32, GDConsts.asciiFlag);
  Mouse.ShowMouse;
end;

procedure DisplayString(col, row, fg, bg: Byte; source: String);
var
  len: Byte;
  i: Byte;
begin
  Mouse.HideMouse;
  if (col > 39) or (row > 39) then Exit;
  len := Length(source);
  for i := 1 to len do begin
    TextRend.RenderChar(col, row, fg, bg, 1, Ord(source[i]), GDConsts.asciiFlag);
    Inc(col);
  end;
  Mouse.ShowMouse;
end;

procedure DisplayMessageWindow(ulCol, ulRow, lrCol, lrRow, fg, bg: Byte; clearFirst: Boolean; source: String);
var
  len: Byte;
  { Unused in this version; see the other implementations of this routine. }
  width: Byte;
  idx: Byte;
  lineEnd: Byte;
  { Unused in this version; see the other implementations of this routine. }
  lineStart: Byte;

  { Prints the current word at the text cursor, advancing it, with a delay after each character while slow text is on. }
  procedure PrintCharInWindow;
  begin
    while idx <= lineEnd do begin
      TextRend.RenderChar(GDVars.currentColumn, GDVars.currentRow, fg, bg, 1, Ord(source[idx]), GDConsts.asciiFlag);
      if GDVars.slowText <> 0 then Delay(GDVars.textDelay * 3);
      Inc(idx);
      Inc(GDVars.currentColumn);
    end;
  end;

  { Skips the spaces at the start of the next line. }
  procedure FindNewIndex;
  begin
    while (idx < len) and (source[idx] = ' ') do Inc(idx);
  end;
begin
  Mouse.HideMouse;
  if (ulCol > 39) or (ulRow > 24) or (lrCol > 39) or (lrRow > 39) then Exit;
  if (GDVars.currentColumn < ulCol) or (GDVars.currentColumn > lrCol) or (GDVars.currentRow < ulRow) or
      (GDVars.currentRow > lrRow) then begin
    GDVars.currentColumn := ulCol; GDVars.currentRow := ulRow;
  end;
  if clearFirst then begin
    TextRend.ClearRect(ulCol, ulRow, lrCol, lrRow);
    GDVars.currentColumn := ulCol; GDVars.currentRow := ulRow;
  end;
  idx := 1;
  len := Length(source);
  if len = 0 then begin Mouse.ShowMouse; Exit; end;
  width := lrCol - ulCol + 1;
  repeat
    lineEnd := idx;
    while (lineEnd < len) and (source[lineEnd] in GDConsts.breakChars) do Inc(lineEnd);
    while (lineEnd < len) and not (source[lineEnd] in GDConsts.breakChars) and (source[lineEnd] <> ' ') do Inc(lineEnd);
    if source[lineEnd] <> ' ' then
      while (lineEnd + 1 < len) and (source[lineEnd + 1] in GDConsts.breakChars) do Inc(lineEnd);
    if lineEnd - idx + GDVars.currentColumn > lrCol then begin
      if (lineEnd - idx + GDVars.currentColumn = lrCol) and (source[lineEnd] = ' ') then begin
        Dec(lineEnd); PrintCharInWindow;
      end;
      GDVars.currentColumn := ulCol; Inc(GDVars.currentRow);
      FindNewIndex;
      if (GDVars.currentRow > lrRow) and (idx < len) then begin
        GDVars.currentColumn := ulCol; GDVars.currentRow := ulRow;
        TextRend.DisplayAndPause(LightMagenta, Black, 'Press any key to continue');
        GameIo.FlushKeys;
        TextRend.ClearRect(ulCol, ulRow, lrCol, lrRow);
        PrintCharInWindow;
      end;
    end else
      PrintCharInWindow;
  until idx > len;
  if GDVars.currentColumn > lrCol then begin
    GDVars.currentColumn := ulCol; Inc(GDVars.currentRow);
  end;
  Mouse.ShowMouse;
end;

function ReadString(query: Types.TString40; fg, bg, maxLen: Byte): Types.TString40;
var
  col: Byte;
  reply: String;
  key: Char;
begin
  TextRend.PrintSpaces(GDConsts.messageColumn, GDConsts.messageRow, Black, GDConsts.screenWidth);
  TextRend.DisplayString(GDConsts.messageColumn, GDConsts.messageRow, fg, bg, query);
  col := Length(query);
  reply := '';
  repeat
    key := ReadKey;
    case key of
      ' '..'z':
        if Length(reply) < maxLen then begin
          reply := reply + key;
          Inc(col);
          TextRend.DisplayString(col, GDConsts.messageRow, White, Black, key);
        end;
      C_Keys.BACKSPACE:
        if Length(reply) > 0 then begin
          reply := Copy(reply, 1, Length(reply) - 1);
          TextRend.PrintSpaces(col, GDConsts.messageRow, Black, 1);
          Dec(col);
        end;
      #0:
        key := ReadKey;
    end;
  until (key = C_Keys.ENTER) or (key = C_Keys.ESCAPE) or (GDVars.demoMode <> 0);
  TextRend.PrintSpaces(GDConsts.messageColumn, GDConsts.messageRow, Black, GDConsts.screenWidth);
  for col := 1 to Length(reply) do
    reply[col] := UpCase(reply[col]);
  ReadString := reply;
end;

function ReadNumber(query: Types.TString40; fg, bg: Byte): Word;
var
  num: LongInt;
  numStr: Types.TString40;
  code: Integer;
begin
  repeat
    numStr := TextRend.ReadString(query, fg, bg, 6);
    Val(numStr, num, code);
    if code = 0 then
      if (num > 65536) or (num < 0) then code := 1;
  until code = 0;
  ReadNumber := num;
end;

procedure DisplayAndPause(fg, bg: Byte; msg: Types.TString40);
var
  { Unused in this version; see the other implementations of this routine. }
  key: Char;
begin
  TextRend.PrintSpaces(GDConsts.messageColumn, GDConsts.messageRow, Black, GDConsts.screenWidth);
  TextRend.DisplayString(GDConsts.messageColumn, GDConsts.messageRow, fg, bg, msg);
  key := GameIo.ReadGameKey;
end;

function GetTicks: LongInt;
var
  h: Word;
  m: Word;
  s: Word;
  hundredths: Word;
begin
  GetTime(h, m, s, hundredths);
  GetTicks := LongInt(h) * 360000 + LongInt(m) * 6000 + LongInt(s) * 100 + hundredths;
end;

procedure ClearScreen;
begin
  case GDVars.displayMode of
    Types.Cga: begin
         FillChar(cgaBank1, 8000, 0);
         FillChar(cgaBank0, 8000, 0);
       end;
    Types.Ega: begin
         TextRend.FillRectEga(0, 0, 39, 24, 0, Black);
         TextRend.FillRectEga(0, 0, 39, 24, 1, Black);
       end;
    Types.Tandy: begin
         FillChar(tandyBank0, 8000, 0);
         FillChar(tandyBank1, 8000, 0);
         FillChar(tandyBank2, 8000, 0);
         FillChar(tandyBank3, 8000, 0);
       end;
  end;
end;

procedure PrintAndPause(msg: Types.TString40; fg, bg: Byte);
begin
  TextRend.PrintSpaces(GDConsts.messageColumn, GDConsts.messageRow, Black, GDConsts.screenWidth);
  TextRend.DisplayString(GDConsts.messageColumn, GDConsts.messageRow, fg, bg, msg);
  TextRend.PauseOnly;
  TextRend.PrintSpaces(GDConsts.messageColumn, GDConsts.messageRow, Black, GDConsts.screenWidth);
end;

procedure PauseOnly;
begin
  Delay(GDVars.textDelay * 100);
end;

procedure ClearRect(ulCol, ulRow, lrCol, lrRow: ShortInt);
var
  firstRow: Word;
  lastRow: Word;
  firstByteColumn: Word;
  byteCount: Word;
  row: Word;
begin
  Mouse.HideMouse;
  case GDVars.displayMode of
    Types.Cga: begin
         firstRow := ulRow * 4;
         lastRow := lrRow * 4 + 3;
         byteCount := (lrCol - ulCol + 1) * 2;
         for row := firstRow to lastRow do begin
           FillChar(cgaBank0[row][ulCol], byteCount, 0);
           FillChar(cgaBank1[row][ulCol], byteCount, 0);
         end;
       end;
    Types.Ega: begin
         TextRend.FillRectEga(ulCol, ulRow, lrCol, lrRow, 0, Black);
         TextRend.FillRectEga(ulCol, ulRow, lrCol, lrRow, 1, Black);
       end;
    Types.Tandy: begin
         firstRow := ulRow * 2;
         lastRow := lrRow * 2 + 1;
         firstByteColumn := ulCol * 4;
         byteCount := (lrCol - ulCol + 1) * 4;
         for row := firstRow to lastRow do begin
           FillChar(tandyBank0[row][firstByteColumn], byteCount, 0);
           FillChar(tandyBank1[row][firstByteColumn], byteCount, 0);
           FillChar(tandyBank2[row][firstByteColumn], byteCount, 0);
           FillChar(tandyBank3[row][firstByteColumn], byteCount, 0);
         end;
       end;
  end;
  Mouse.ShowMouse;
end;

procedure RightAlignString(var source; n: Byte);
var s: Types.TString40 absolute source;
begin
  while Length(s) < n do
    s := ' ' + s;
end;
begin
end.
