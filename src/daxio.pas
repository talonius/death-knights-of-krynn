{ DaxIo -- disk access: the .DAX archive reader (an index of entries, each a run-length-compressed block), finding a
  file on the data or master path with an insert-disk prompt, the BIOS text writes that prompt uses, file-name cleaning,
  and saving and restoring the disk number. Sound is stopped while an archive loads. }
{$O+,F+}
{$R-,S-,V-,I-,B-}
unit DaxIo;
interface
uses Crt, GDConsts, GDVars, Dos, GameIo, SoundDrv, Types;
type
  TString20 = string[20];

{ Writes a run of one character in text mode through the video BIOS on page 0, placing the cursor first. On CGA the
  attribute is translated through the CGA attribute table.
  @param(col Text column.)
  @param(row Text row.)
  @param(attr Text attribute.)
  @param(count How many copies to write.)
  @param(ch The character.) }
procedure WriteChar(col, row, attr, count, ch: Byte);

{ Writes a string in text mode through the video BIOS, one character per column.
  @param(col Text column of the first character.)
  @param(row Text row.)
  @param(attr Text attribute.)
  @param(source The text.) }
procedure WriteString(col, row, attr: Byte; source: string);

{ Writes a run of solid block characters through the BIOS.
  @param(col Column of the first block.)
  @param(row Row of the run.)
  @param(attr Text attribute.)
  @param(count Number of blocks.) }
procedure WriteBlock(col, row, attr, count: Byte);

{ Shows a message on the bottom text row over a cleared bar, waits for a key, then clears the bar.
  @param(attr Attribute of the message.)
  @param(message The message.) }
procedure PromptBox(attr: Byte; message: Types.TString40);

{ Erases a file if it exists.
  @param(name The file's name.) }
procedure DeleteIfPresent(name: Types.TString80);

{ Renames a file if it exists.
  @param(oldName The file.)
  @param(newName Its new name.) }
procedure RenameIfExists(oldName, newName: Types.TString80);

{ Waits until GAME.OVR can be found, asking for the overlay disk and a key each time it is missing. }
procedure OverlayPrompt;

{ Reads a drive's volume label. The FindFirst status is not checked: the name buffer is cleared first, so a failed
  search leaves it empty.
  @param(drive The drive letter.)
  @returns(The label, or an empty string when it has none.) }
function GetVolumeLabel(drive: Types.TString2): Types.TString40;

{ Opens a file for reading in one-byte records. A name with no directory is looked for on the current data path; on a
  miss the two data paths are swapped, so later opens search the drive that held the file first. With prompts enabled, a
  file still missing on a floppy drive asks for the disk (the prompt plus the drive letter) and retries, and one missing
  on a hard drive reports a bad install and aborts.
  @param(fileName The file.)
  @param(promptMsg The disk prompt, before the drive letter.)
  @param(noPrompt Anything but zero returns False at once on a miss instead of prompting.)
  @param(f Receives the opened file.)
  @returns(True when the file was found and opened.) }
function OpenWithRetry(fileName, promptMsg: Types.TString80; noPrompt: Char; var f: file): Boolean;

{ Tells whether a normal file matching a name exists.
  @param(name The file name or pattern; an empty name never exists.)
  @returns(True when one exists.) }
function FileExists(name: Types.TString80): Boolean;

{ Removes the occurrences of one string from another. Note: the scan limit is computed once from the starting lengths
  and the scan moves on after each deletion, so a match shifted into the current position survives, and a substring
  longer than the string wraps the limit round to a large byte value.
  @param(src The string.)
  @param(del The text to remove.)
  @returns(The string without the text.) }
function SanitizeString(src, del: string): string;

{ Makes a file name from a string: removes the characters a DOS file name cannot hold, in SanitizeString's single pass,
  keeps the first eight characters and uppercases them.
  @param(name The string.)
  @returns(The file name.) }
function SanitizeFileName(name: string): Types.TString80;

{ Decodes a run-length packed entry. A control byte 0..$7E copies the next control+1 bytes; -127..-1 repeats the next
  byte -control times. Note: controls $7F and $80 do nothing, so a stream holding one makes no progress, and `outLen` is
  checked only between runs, so bad data can overrun the buffer by one run.
  @param(dst The buffer that receives the decoded bytes.)
  @param(outLen The number of bytes to decode.)
  @param(f The archive, positioned at the entry.) }
procedure DecompressDax(var dst: Types.PBytes; var outLen: Word; var f: file);

{ Opens an archive twice, one handle for its entry directory from the start and one positioned at the first data byte.
  Note: if the second open fails, the first handle is left open.
  @param(dirName The archive's base name.)
  @param(ext Its extension.)
  @param(headerSize Receives the offset of the first data byte.)
  @param(dataFile Receives the handle positioned at the data.)
  @param(indexFile Receives the handle that reads the directory.)
  @returns(True when both opens succeeded.) }
function OpenDax(dirName, ext: TString20; var headerSize: Word; var dataFile, indexFile: file): Boolean;

{ Closes both handles of a DAX archive.
  @param(dataFile The data handle.)
  @param(indexFile The directory handle.) }
procedure CloseDax(var dataFile, indexFile: file);

{ Loads and decodes one block of a DAX archive into a new buffer. The directory is searched for the block's ID; each
  entry gives the block's offset and its decoded and compressed sizes. Sound output is silenced during the load. A
  missing archive or block gives a size of 0 and nil.
  @param(fileName The archive's name.)
  @param(ext The archive's extension.)
  @param(fileId The block's ID.)
  @param(sizeRead Receives the decoded size, 0 on failure.)
  @param(data Receives the buffer, nil on failure.) }
procedure LoadDax(fileName, ext: Types.TString80; fileId: Byte; var sizeRead: Word; var data: Types.PBytes);

{ Remembers the current disk and switches to the disk that holds a given part of the game, two parts to a disk.
  @param(v The part, 1 up.) }
procedure PushState(v: Byte);

{ Returns to the disk PushState remembered. }
procedure PopState;
implementation

procedure PushSoundState; forward;

procedure PopSoundState; forward;

{ Stops the sound for a disk access: saves the resident driver mode for PopSoundState and, when the built-in driver is
  in use, sends it the reset request and marks no driver until then. }
procedure PushSoundState;
begin
  GDVars.savedSoundActive := GDVars.soundActive;
  if GDVars.soundActive = 1 then begin
    SoundDrv.SoundCommand(GDConsts.soundReset);
    GDVars.soundActive := 0;
  end;
end;

{ Restores the driver mode PushSoundState saved and, when it is the built-in driver, starts it again. }
procedure PopSoundState;
begin
  GDVars.soundActive := GDVars.savedSoundActive;
  if GDVars.soundActive = 1 then SoundDrv.StartSound;
end;

procedure WriteChar(col, row, attr, count, ch: Byte);
begin
  GDVars.videoRegs.ah := GDConsts.biosSetCursor;
  GDVars.videoRegs.bh := 0;
  GDVars.videoRegs.dh := row;
  GDVars.videoRegs.dl := col;
  Intr(GDConsts.videoInterrupt, Registers(GDVars.videoRegs));
  GDVars.videoRegs.ah := GDConsts.biosWriteChar;
  GDVars.videoRegs.al := ch;
  GDVars.videoRegs.bh := 0;
  if GDVars.displayMode = Types.Cga then
    GDVars.videoRegs.bl := GDConsts.cgaAttributeColors[attr]
  else
    GDVars.videoRegs.bl := attr;
  GDVars.videoRegs.cx := count;
  Intr(GDConsts.videoInterrupt, Registers(GDVars.videoRegs));
end;

procedure WriteString(col, row, attr: Byte; source: string);
var
  n: Byte;
  i: Byte;
begin
  n := Length(source);
  for i := 1 to n do begin
    DaxIo.WriteChar(col, row, attr, 1, Ord(source[i]));
    Inc(col);
  end;
end;

procedure WriteBlock(col, row, attr, count: Byte);
begin
  DaxIo.WriteChar(col, row, attr, count, 219);
end;

procedure PromptBox(attr: Byte; message: Types.TString40);
var
  { Unused in this version; see the other implementations of this routine. }
  key: Char;
begin
  DaxIo.WriteBlock(GDConsts.messageColumn, GDConsts.messageRow, Black, 40);
  DaxIo.WriteString(GDConsts.messageColumn, GDConsts.messageRow, attr, message);
  key := GameIo.ReadGameKey;
  DaxIo.WriteBlock(GDConsts.messageColumn, GDConsts.messageRow, Black, 40);
end;

procedure DeleteIfPresent(name: Types.TString80);
begin
  if DaxIo.FileExists(name) then begin
    Assign(GDVars.scratchFile, name);
    Close(GDVars.scratchFile);
    Erase(GDVars.scratchFile);
  end;
end;

procedure RenameIfExists(oldName, newName: Types.TString80);
begin
  if DaxIo.FileExists(oldName) then begin
    Assign(GDVars.scratchFile, oldName);
    Close(GDVars.scratchFile);
    Rename(GDVars.scratchFile, newName);
  end;
end;

procedure OverlayPrompt;
var
  { Unused in this version; see the other implementations of this routine. }
  key: Char;
  found: Boolean;
begin
  repeat
    found := DaxIo.FileExists('game.ovr');
    if not found then begin
      WriteLn('Please insert overlay disk.');
      key := GameIo.ReadGameKey;
    end;
  until found;
end;

function GetVolumeLabel(drive: Types.TString2): Types.TString40;
var sr: SearchRec;
begin
  FillChar(sr.Name, SizeOf(sr.Name), 0);
  FindFirst(drive + ':\*.*', VolumeID, sr);
  GetVolumeLabel := sr.Name;
end;

function OpenWithRetry(fileName, promptMsg: Types.TString80; noPrompt: Char; var f: file): Boolean;
var found: Boolean;
    swapTmp: string[79];
    dir: string[67];
    baseName: string[8];
    ext: string[4];
begin
  FSplit(fileName, dir, baseName, ext);
  if dir = '' then
    dir := GDVars.dataPath;
  repeat
    found := DaxIo.FileExists(dir + baseName + ext);
    if not found then
      if dir = GDVars.dataPath then begin
        swapTmp := GDVars.dataPath;
        GDVars.dataPath := GDVars.masterPath;
        GDVars.masterPath := swapTmp;
        dir := GDVars.dataPath;
        found := DaxIo.FileExists(dir + baseName + ext);
      end;
    if not found then
      if noPrompt = #0 then begin
        if dir[1] < 'C' then
          DaxIo.PromptBox(14, promptMsg + GDVars.masterDrive + ': <ENTER>')
        else begin
          DaxIo.PromptBox(14, 'Couldn''t find ' + baseName + ext + '. Check install.');
          GameIo.ExitGame;
        end;
      end;
  until found or (noPrompt <> #0);
  if found then begin
    Assign(f, dir + baseName + ext);
    Reset(f, 1);
  end;
  OpenWithRetry := found;
end;

function FileExists(name: Types.TString80): Boolean;
var sr: SearchRec;
begin
  FindFirst(name, 0, sr);
  FileExists := (DosError = 0) and (name <> '');
end;

function SanitizeString(src, del: string): string;
var
  limit: Byte;
  delLen: Byte;
  i: Byte;
begin
  delLen := Length(del);
  limit := Length(src) - delLen + 1;
  for i := 1 to limit do
    if Copy(src, i, delLen) = del then
      Delete(src, i, delLen);
  SanitizeString := src;
end;

function SanitizeFileName(name: string): Types.TString80;
var i: Byte;
begin
  for i := 1 to 10 do
    name := DaxIo.SanitizeString(name, GDConsts.invalidFileChars[i]);
  name := Copy(name, 1, 8);
  for i := 1 to Length(name) do
    name[i] := UpCase(name[i]);
  SanitizeFileName := name;
end;

procedure DecompressDax(var dst: Types.PBytes; var outLen: Word; var f: file);
var
  { Unused in this version; see the other implementations of this routine. }
  sourceIndex: Word;
  dstIdx: Word;
  b: ShortInt;
  fillByte: Byte;
  { Unused in this version; see the other implementations of this routine. }
  buf: array[0..511] of Byte;
begin
  sourceIndex := 0;
  dstIdx := 0;
  repeat
    BlockRead(f, b, SizeOf(b));
    case b of
      0..126: begin
        BlockRead(f, dst^[dstIdx], b + 1);
        Inc(dstIdx, b + 1);
      end;
      -127..-1: begin
        b := -b;
        BlockRead(f, fillByte, SizeOf(fillByte));
        FillChar(dst^[dstIdx], b, fillByte);
        Inc(dstIdx, b);
      end;
    end;
  until dstIdx >= outLen;
end;

function OpenDax(dirName, ext: TString20; var headerSize: Word; var dataFile, indexFile: file): Boolean;
var nread: Word;
    { Unused in this version; see the other implementations of this routine. }
    ioStatus: Word;
begin
  if DaxIo.OpenWithRetry(dirName + ext, GDConsts.insertDiskMessages[GDVars.diskNumber], Chr(GDVars.suppressDisk),
                         dataFile) then begin
    if not DaxIo.OpenWithRetry(dirName + ext, GDConsts.insertDiskMessages[GDVars.diskNumber],
                               Chr(GDVars.suppressDisk), indexFile) then begin
      OpenDax := False;
      Exit;
    end;
    BlockRead(indexFile, headerSize, SizeOf(headerSize), nread);
    Inc(headerSize, 2);
    Seek(dataFile, headerSize);
    OpenDax := True;
  end else
    OpenDax := False;
end;

procedure CloseDax(var dataFile, indexFile: file);
begin
  Close(dataFile);
  Close(indexFile);
end;

procedure LoadDax(fileName, ext: Types.TString80; fileId: Byte; var sizeRead: Word; var data: Types.PBytes);
var compSize: Word;
    offset: LongInt;
    id: Byte;
    n: Word;
    dataFile: file;
    indexFile: file;
    headerSize: Word;
    { Unused in this version; see the other implementations of this routine. }
    numberText: array[1..8] of Byte;
begin
  DaxIo.PushSoundState;
  if not DaxIo.OpenDax(fileName, ext, headerSize, dataFile, indexFile) then begin
    sizeRead := 0;
    data := nil;
    DaxIo.PopSoundState;
    Exit;
  end;
  repeat
    BlockRead(indexFile, id, SizeOf(id), n);
    BlockRead(indexFile, offset, SizeOf(offset), n);
    BlockRead(indexFile, sizeRead, SizeOf(sizeRead), n);
    BlockRead(indexFile, compSize, SizeOf(compSize), n);
  until (id = fileId) or (FilePos(indexFile) >= headerSize);
  if id <> fileId then begin
    sizeRead := 0;
    data := nil;
    DaxIo.CloseDax(dataFile, indexFile);
    DaxIo.PopSoundState;
  end else begin
    GetMem(data, sizeRead);
    Seek(dataFile, headerSize + offset);
    DaxIo.DecompressDax(data, sizeRead, dataFile);
    DaxIo.CloseDax(dataFile, indexFile);
    DaxIo.PopSoundState;
  end;
end;

procedure PushState(v: Byte);
begin
  GDVars.previousDisk := GDVars.diskNumber;
  GDVars.diskNumber := (v + 1) div 2;
end;

procedure PopState;
begin
  GDVars.diskNumber := GDVars.previousDisk;
end;
begin
end.
