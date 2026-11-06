{ GameBoot -- start-up, run from the unit's initialization. It hooks the overlay reader with GameIo.OverlayReadWithBeep
  and works out the master disk's path from where the program runs. On the first run it asks for the graphics adapter,
  the sound, the alternate input and two save paths (this game's and the imported characters'), calibrates the joystick
  and writes the answers to DKK.CFG; a typed path is kept only if it has at least four characters, a drive letter A..P
  and a colon, and is not on the floppy the program runs from. The sound menu accepts 6, for which no line is written,
  so every later line would be read one off. It then reads DKK.CFG back: it saves the BIOS video mode and sets the
  chosen one, sizes the overlay buffer to 160K bytes or halts for lack of memory, and sets the sound mode, the input
  device, the save paths and the joystick calibration. For Tandy it lowers HeapEnd by 1024 paragraphs. }
{$O+,F+}
{$I-}
unit GameBoot;
interface
uses C_Sound, GDConsts, GDVars, Crt, Dos, Overlay, DaxIo, Joystick, Blit, TextRend, GameIo, Types;
implementation
const
  SOUND_CMS = 0;
  SOUND_ADLIB = 2;
  GFX_RESERVE_PARAS = 1024;
  OVERLAY_BUF_BYTES = 163840;
type
  THeapEndW = record
    o: Word;
    s: Word;
  end;
var
  heapEndW: THeapEndW absolute HeapEnd;

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
  FSplit(FExpand('*.exe'), DirStr(GDVars.dataPath), NameStr(GDVars.exeName), ExtStr(GDVars.exeExt));
  if GDVars.dataPath[1] < 'C' then begin
    if GDVars.dataPath[1] = 'A' then
      GDVars.masterPath := 'B:\'
    else
      GDVars.masterPath := 'A:\';
  end else
    GDVars.masterPath := GDVars.dataPath;
  GDVars.masterDrive := GDVars.masterPath[1];
  if not DaxIo.FileExists('dkk.cfg') then begin
    Assign(GDVars.configFile, 'dkk.cfg');
    Rewrite(GDVars.configFile);
    GDVars.configIoError := IOResult;
    if GDVars.configIoError <> 0 then begin
      ClrScr;
      WriteLn(GDConsts.copyProtect1);
      WriteLn;
      WriteLn(GDConsts.copyProtect2);
      Halt(1);
    end;
    ClrScr;
    Write(GDConsts.graphicsPrompt);
    GDVars.menuChoice := GameBoot.ReadMenuChoice(1, 3);
    GDVars.tandySelected := 0;
    case GDVars.menuChoice of
      1: WriteLn(GDVars.configFile, 'C');
      2: WriteLn(GDVars.configFile, 'E');
      3: begin WriteLn(GDVars.configFile, 'T'); GDVars.tandySelected := 1; end;
    end;
    ClrScr;
    WriteLn(GDConsts.soundPrompt1);
    WriteLn(GDConsts.soundPrompt2);
    WriteLn(GDConsts.soundPrompt3);
    WriteLn(GDConsts.soundPrompt4);
    WriteLn(GDConsts.soundPrompt5);
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
    Write(GDConsts.inputPrompt);
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
    Write(GDConsts.pathPrompt + GDVars.defaultPath + '):  ');
    ReadLn(GDVars.enteredPath);
    GDVars.enteredPath[1] := UpCase(GDVars.enteredPath[1]);
    if not ((Length(GDVars.enteredPath) >= 4) and (GDVars.enteredPath[2] = ':') and
            (not (GDVars.enteredPath[1] in ['A', 'B']) or (GDVars.enteredPath[1] <> GDVars.dataPath[1])) and
            (GDVars.enteredPath[1] in ['A'..'P'])) then begin
      GDVars.enteredPath := GDVars.defaultPath;
      WriteLn(GDConsts.usingDefaultText + GDVars.enteredPath);
      Delay(2000);
    end;
    for GDVars.configIndex := 1 to Length(GDVars.enteredPath) do GDVars.enteredPath[GDVars.configIndex] :=
        UpCase(GDVars.enteredPath[GDVars.configIndex]);
    if GDVars.enteredPath[Length(GDVars.enteredPath)] <> '\' then GDVars.enteredPath := GDVars.enteredPath + '\';
    WriteLn(GDVars.configFile, GDVars.enteredPath);
    ClrScr;
    GDVars.enteredPath := '';
    if GDVars.masterPath[1] < 'C' then
      GDVars.defaultPath := GDVars.masterPath[1] + GDConsts.pathSuffixA
    else
      GDVars.defaultPath := GDVars.masterPath[1] + GDConsts.pathSuffixB;
    WriteLn(GDConsts.secondPathPrompt);
    Write('(DEFAULT - ' + GDVars.defaultPath + '):  ');
    ReadLn(GDVars.enteredPath);
    GDVars.enteredPath[1] := UpCase(GDVars.enteredPath[1]);
    if not ((Length(GDVars.enteredPath) >= 4) and (GDVars.enteredPath[2] = ':') and
            (not (GDVars.enteredPath[1] in ['A', 'B']) or (GDVars.enteredPath[1] <> GDVars.dataPath[1])) and
            (GDVars.enteredPath[1] in ['A'..'P'])) then begin
      GDVars.enteredPath := GDVars.defaultPath;
      WriteLn('USING DEFAULT PATH: ' + GDVars.enteredPath);
      Delay(2000);
    end;
    for GDVars.configIndex := 1 to Length(GDVars.enteredPath) do GDVars.enteredPath[GDVars.configIndex] :=
        UpCase(GDVars.enteredPath[GDVars.configIndex]);
    if GDVars.enteredPath[Length(GDVars.enteredPath)] <> '\' then GDVars.enteredPath := GDVars.enteredPath + '\';
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
  WriteLn(GDConsts.tandyNotice);
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
      GDVars.tandyFreeBlock := Ptr(heapEndW.s - GameBoot.GFX_RESERVE_PARAS, heapEndW.o);
      HeapEnd := GDVars.tandyFreeBlock;
      Blit.SetVideoMode(GDConsts.tandyVideoMode);
    end;
    else begin
      GDVars.displayMode := Types.Cga;
      Blit.SetVideoMode(GDConsts.cgaVideoMode);
    end;
  end;
  if GameBoot.OVERLAY_BUF_BYTES - OvrGetBuf <= MemAvail then
    OvrSetBuf(GameBoot.OVERLAY_BUF_BYTES)
  else begin
    Blit.RestoreVideoMode;
    WriteLn(GDConsts.memErrorText, GameBoot.OVERLAY_BUF_BYTES - OvrGetBuf - MemAvail, GDConsts.moreBytesText);
    Halt;
  end;
  if OvrResult <> 0 then begin
    Blit.RestoreVideoMode;
    WriteLn(GDConsts.overlayErrorText);
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
