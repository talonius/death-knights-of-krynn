{ GameBoot -- start-up, run from the unit's initialization. It hooks the overlay reader with GameIo.OverlayReadWithBeep
  and works out the master disk's path from where the program runs. On the first run it asks for the graphics adapter,
  the sound, the alternate input and two save paths (this game's and the imported characters'), calibrates the joystick
  and writes the answers to DKK.CFG; a typed path is kept only if it has at least four characters, a drive letter A..P
  and a colon, and is not on the floppy the program runs from. The sound menu accepts 6, for which no line is written,
  so every later line would be read one off. It then reads DKK.CFG back: it saves the BIOS video mode and sets the
  chosen one, sizes the overlay buffer to 160K bytes or halts for lack of memory, and sets the sound mode, the input
  device, the save paths and the joystick calibration. For Tandy it moves the free-list block at FreePtr 1024 paragraphs
  lower, points FreePtr there, stores GDConsts.tandyHeapReserve shl 3 in FreeMin, the word after FreePtr, and records
  FreePtr as GDVars.tandyGfxReserve. }
{$F+,O+,S-,R-,V-,B-,I-}
unit GameBoot;
interface
uses C_Sound, GDConsts, GDVars, Crt, Dos, Overlay, DaxIo, TextRend, Joystick, GameIo, Blit, Types;
implementation
const
  SOUND_CMS = 0;
  SOUND_ADLIB = 2;
  GFX_RESERVE_PARAS = 1024;
  OVERLAY_BUF_BYTES = 163840;
type
  TFreePtrW = record o: Word; s: Word; extra: Word; end;
var
  freePtrW: TFreePtrW absolute FreePtr;
  heapTopBlk: Types.PFreeBlk absolute FreePtr;

{ Waits for a digit key within a range and echoes it.
  @param(minDigit The lowest digit accepted.)
  @param(maxDigit The highest digit accepted.)
  @returns(The digit's value.) }
function ReadMenuChoice(minDigit, maxDigit: Byte): Byte;
begin
  repeat
    GDVars.configKey := ReadKey;
  until (GDVars.configKey in ['0'..'9']) and ((Ord(GDVars.configKey) - Ord('0')) in [minDigit..maxDigit]);
  Write(GDVars.configKey);
  ReadMenuChoice := Ord(GDVars.configKey) - Ord('0');
end;
begin
  CheckBreak := False;
  DaxIo.OverlayPrompt;
  OvrInit('GAME.OVR');
  GDVars.savedOvrRead := OvrReadBuf;
  OvrReadBuf := GameIo.OverlayReadWithBeep;
  FSplit(FExpand('*.exe'), GDVars.dataPath, GDVars.exeName, GDVars.exeExt);
  if GDVars.dataPath[1] < 'C' then
  begin
    if GDVars.dataPath[1] = 'A' then
      GDVars.masterPath := 'B:\'
    else
      GDVars.masterPath := 'A:\';
  end else
    GDVars.masterPath := GDVars.dataPath;
  GDVars.masterDrive := GDVars.masterPath[1];
  if not DaxIo.FileExists('dkk.cfg') then
  begin
    Assign(GDVars.configFile, 'dkk.cfg');
    Rewrite(GDVars.configFile);
    GDVars.configIoError := IOResult;
    if GDVars.configIoError <> 0 then begin
      ClrScr;
      WriteLn('Sorry, disk A can''t be write-protected.');
      WriteLn;
      WriteLn('If these are your masters, use DISKCOPY to make duplicates.');
      Halt(1);
    end;
    ClrScr;
    Write('GRAPHICS ADAPTER TYPE:  [1] CGA  [2] EGA  [3] Tandy  ');
    GDVars.menuChoice := GameBoot.ReadMenuChoice(1, 3);
    GDVars.tandySelected := 0;
    case GDVars.menuChoice of
      1: WriteLn(GDVars.configFile, 'C');
      2: WriteLn(GDVars.configFile, 'E');
      3: begin WriteLn(GDVars.configFile, 'T'); GDVars.tandySelected := 1; end;
    end;
    ClrScr;
    WriteLn('SOUND TYPE:  [1] C/MS');
    WriteLn('             [2] AdLib');
    WriteLn('             [3] Tandy 1000');
    WriteLn('             [4] PC');
    WriteLn('             [5] Silent');
    GDVars.menuChoice := GameBoot.ReadMenuChoice(1, 6);
    case GDVars.menuChoice of
      1: WriteLn(GDVars.configFile, 'C');
      2: WriteLn(GDVars.configFile, 'A');
      3: WriteLn(GDVars.configFile, 'T');
      4: WriteLn(GDVars.configFile, 'P');
      5: WriteLn(GDVars.configFile, 'S');
    end;
    GDVars.joystickActive := 0;
    ClrScr;
    Write('ALTERNATE INPUT TYPE:  [1] JOYSTICK  [2] MOUSE  [3] NEITHER  ');
    GDVars.menuChoice := GameBoot.ReadMenuChoice(1, 3);
    case GDVars.menuChoice of
      1: begin WriteLn(GDVars.configFile, 'J'); GDVars.joystickActive := 1; end;
      2: if GDVars.tandySelected <> 0 then
           WriteLn(GDVars.configFile, 'N')
         else
           WriteLn(GDVars.configFile, 'M');
      3: WriteLn(GDVars.configFile, 'N');
    end;
    ClrScr;
    GDVars.defaultPath := GDVars.masterPath + 'SAVE';
    Write('PATH TO SAVE DATA (DEFAULT - ' + GDVars.defaultPath + '):  ');
    ReadLn(GDVars.enteredPath);
    GDVars.enteredPath[1] := UpCase(GDVars.enteredPath[1]);
    if not ((Length(GDVars.enteredPath) >= 4) and (GDVars.enteredPath[2] = ':') and
            (not (GDVars.enteredPath[1] in ['A', 'B']) or (GDVars.enteredPath[1] <> GDVars.dataPath[1])) and
            (GDVars.enteredPath[1] in ['A'..'P'])) then
    begin
      GDVars.enteredPath := GDVars.defaultPath;
      WriteLn('USING DEFAULT PATH: ' + GDVars.enteredPath);
      Delay(2000);
    end;
    for GDVars.configIndex := 1 to Length(GDVars.enteredPath) do
      GDVars.enteredPath[GDVars.configIndex] := UpCase(GDVars.enteredPath[GDVars.configIndex]);
    if GDVars.enteredPath[Length(GDVars.enteredPath)] <> '\' then
      GDVars.enteredPath := GDVars.enteredPath + '\';
    WriteLn(GDVars.configFile, GDVars.enteredPath);
    ClrScr;
    GDVars.enteredPath := '';
    if GDVars.masterPath[1] < 'C' then
      GDVars.defaultPath := GDVars.masterPath[1] + ':\SAVE'
    else
      GDVars.defaultPath := GDVars.masterPath[1] + ':\KRYNN\SAVE';
    WriteLn('PATH TO SAVE DATA FOR CHAMPIONS OF KRYNN');
    Write('(DEFAULT - ' + GDVars.defaultPath + '):  ');
    ReadLn(GDVars.enteredPath);
    GDVars.enteredPath[1] := UpCase(GDVars.enteredPath[1]);
    if not ((Length(GDVars.enteredPath) >= 4) and (GDVars.enteredPath[2] = ':') and
            (not (GDVars.enteredPath[1] in ['A', 'B']) or (GDVars.enteredPath[1] <> GDVars.dataPath[1])) and
            (GDVars.enteredPath[1] in ['A'..'P'])) then
    begin
      GDVars.enteredPath := GDVars.defaultPath;
      WriteLn('USING DEFAULT PATH: ' + GDVars.enteredPath);
      Delay(2000);
    end;
    for GDVars.configIndex := 1 to Length(GDVars.enteredPath) do
      GDVars.enteredPath[GDVars.configIndex] := UpCase(GDVars.enteredPath[GDVars.configIndex]);
    if GDVars.enteredPath[Length(GDVars.enteredPath)] <> '\' then
      GDVars.enteredPath := GDVars.enteredPath + '\';
    WriteLn(GDVars.configFile, GDVars.enteredPath);
    WriteLn(GDVars.configFile, 'F');
    Joystick.CalibrateJoystick;
    for GDVars.configIndex := 0 to 6 do begin
      WriteLn(GDVars.configFile, GDVars.joyCalib[1].x.words[GDVars.configIndex]);
      WriteLn(GDVars.configFile, GDVars.joyCalib[1].y.words[GDVars.configIndex]);
    end;
    Close(GDVars.configFile);
  end;
  ClrScr;
  WriteLn('TANDY 1000 USERS - Make sure NUMLOCK is on.');
  Delay(2000);
  Assign(GDVars.configFile, 'dkk.cfg');
  Reset(GDVars.configFile);
  ReadLn(GDVars.configFile, GDVars.configKey);
  GDVars.videoRegs.ah := GDConsts.biosGetVideoMode;
  Intr(GDConsts.videoInterrupt, Registers(GDVars.videoRegs));
  GDVars.savedVideoMode := GDVars.videoRegs.al;
  GDVars.currentVideoMode := GDVars.savedVideoMode;
  case GDVars.configKey of
    'E': begin
      GDVars.displayMode := Types.Ega;
      Blit.SetVideoMode(GDConsts.egaVideoMode);
      GDVars.currentEgaPage := 0;
      GDVars.otherEgaPage := 0;
      TextRend.SetupEgaCurrentPage(GDVars.currentEgaPage);
      TextRend.SetupEgaOtherPage(GDVars.otherEgaPage);
    end;
    'T': begin
      GDVars.displayMode := Types.Tandy;
      GDVars.tandyFreeBlock := Ptr(freePtrW.s - GameBoot.GFX_RESERVE_PARAS, freePtrW.o);
      Move(heapTopBlk^, GDVars.tandyFreeBlock^, SizeOf(Types.TFreeBlk));
      FreePtr := GDVars.tandyFreeBlock;
      Blit.SetVideoMode(GDConsts.tandyVideoMode);
      freePtrW.extra := GDConsts.tandyHeapReserve shl 3;
      GDVars.tandyGfxReserve := FreePtr;
    end;
    else begin GDVars.displayMode := Types.Cga; Blit.SetVideoMode(GDConsts.cgaVideoMode); end;
  end;
  if GameBoot.OVERLAY_BUF_BYTES - OvrGetBuf <= MemAvail then
    OvrSetBuf(GameBoot.OVERLAY_BUF_BYTES)
  else begin
    Blit.RestoreVideoMode;
    WriteLn('Not enough memory to run game.  You need ', GameBoot.OVERLAY_BUF_BYTES - OvrGetBuf - MemAvail,
            ' more bytes.');
    Halt;
  end;
  if OvrResult <> 0 then begin
    Blit.RestoreVideoMode;
    WriteLn('Overlay error, program abort!');
    Halt;
  end;
  ReadLn(GDVars.configFile, GDVars.configKey);
  case GDVars.configKey of
    'C': GDVars.soundMode := GameBoot.SOUND_CMS;
    'A': GDVars.soundMode := GameBoot.SOUND_ADLIB;
    'T': GDVars.soundMode := C_Sound.TANDY;
    'P': GDVars.soundMode := C_Sound.SPEAKER;
    else GDVars.soundMode := C_Sound.OFF;
  end;
  ReadLn(GDVars.configFile, GDVars.configKey);
  case GDVars.configKey of
    'J': begin GDVars.joystickActive := 1; GDVars.mousePresent := 0; end;
    'M': begin GDVars.mousePresent := 1; GDVars.joystickActive := 0; end;
    'N': begin GDVars.mousePresent := 0; GDVars.joystickActive := 0; end;
  end;
  ReadLn(GDVars.configFile, GDVars.savePath);
  ReadLn(GDVars.configFile, GDVars.championsSavePath);
  ReadLn(GDVars.configFile, GDVars.configKey);
  Joystick.ProbeJoystick;
  if GDVars.joystickActive <> 0 then
    for GDVars.configIndex := 0 to 6 do begin
      ReadLn(GDVars.configFile, GDVars.joyCalib[1].x.words[GDVars.configIndex]);
      ReadLn(GDVars.configFile, GDVars.joyCalib[1].y.words[GDVars.configIndex]);
    end;
  Close(GDVars.configFile);
end.
