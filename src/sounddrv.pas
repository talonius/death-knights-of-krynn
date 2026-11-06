{ SoundDrv -- the Pascal side of SOUNDDRV.OBJ's resident sound driver. SoundCommand is the single entry point the game
  calls; StartSound saves the configured mode and starts the driver. GDVars holds soundMode (5 = no sound), the saved
  copy and soundActive, which driver is installed (1 this one, 2 MusDrv's music driver). }
{$F+}
unit SoundDrv;
interface

{ Does nothing while soundMode is 5, except command 15. 0 calls SetVoiceByte(1); 1 silences both voices; 2..14 start
  tune cmd - 1 on voice B under Tandy (mode 3), otherwise on voice A; 255, when the driver is installed, silences both
  voices and uninstalls it; 15 writes 5000 into the word at DriverData.
  @param(cmd Sound command.) }
procedure SoundCommand(cmd: Word);

{ Saves soundMode into savedSoundMode and, unless sound is off, installs the driver, marks it active and silences both
  voices. Music calls it before sounding a command and when it hands back from MusDrv's music driver; DaxIo's
  PopSoundState calls it again after a load when this driver was active. }
procedure StartSound;
implementation
uses GDVars, C_Sound;
const
  CMD_STOP = 255;
  DRIVER_TICK_VALUE = 5000;
{$L SOUNDDRV.OBJ}

{ Installs the driver's timer interrupt handler, saving the old one, and speeds up the timer. }
procedure InstallSoundTimer; external;

{ Restores the old timer interrupt handler and the BIOS timer rate, and silences both banks of voices. }
procedure UninstallSoundTimer; external;

{ Starts a tune on the PC-speaker voices; tune 0 silences them.
  @param(b The tune number.) }
procedure VoiceWriteA(b: Word); external;

{ Starts a tune on the Tandy voices; tune 0 silences them.
  @param(b The tune number.) }
procedure VoiceWriteB(b: Word); external;

{ Sets the voice byte; while it is 0 the timer interrupt keeps both banks quiet.
  @param(b The new voice byte, in its low byte.) }
procedure SetVoiceByte(b: Word); external;

{ Not code: the forced-exit countdown word that the driver's timer interrupt counts down. }
procedure DriverData; external;

procedure SoundCommand(cmd: Word);
var
  { Unused in this version; see the other implementations of this routine. }
  savedState: array[0..1] of Byte;
begin
  case cmd of
    1:
      if GDVars.soundMode <> C_Sound.OFF then begin
        SoundDrv.VoiceWriteB(0);
        SoundDrv.VoiceWriteA(0);
      end;
    0:
      if GDVars.soundMode <> C_Sound.OFF then SoundDrv.SetVoiceByte(1);
    SoundDrv.CMD_STOP:
      if GDVars.soundMode <> C_Sound.OFF then
        if GDVars.soundActive = 1 then begin
          GDVars.soundActive := 0;
          SoundDrv.VoiceWriteB(0);
          SoundDrv.VoiceWriteA(0);
          SoundDrv.UninstallSoundTimer;
        end;
    2..14:
      if GDVars.soundMode <> C_Sound.OFF then
        if GDVars.soundMode = C_Sound.TANDY then SoundDrv.VoiceWriteB(cmd - 1)
        else SoundDrv.VoiceWriteA(cmd - 1);
    15:
      Word(GDVars.driverDataPtr^) := SoundDrv.DRIVER_TICK_VALUE;
  end;
end;

procedure StartSound;
begin
  GDVars.savedSoundMode := GDVars.soundMode;
  if GDVars.soundMode = C_Sound.OFF then Exit;
  GDVars.soundActive := 1;
  SoundDrv.InstallSoundTimer;
  SoundDrv.VoiceWriteA(0);
  SoundDrv.VoiceWriteB(0);
end;
begin
  GDVars.driverDataPtr := @SoundDrv.DriverData;
  Word(GDVars.driverDataPtr^) := 0;
end.
