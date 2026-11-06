{ Music -- switches the speaker between SoundDrv's effects driver and MusDrv's resident music driver, and loads the
  music from MUSIC.DAX. soundActive says which is installed (1 SoundDrv's, 2 the music driver). }
{$F+,O+,S-,R-,V-,B-,I-}
unit Music;
interface
uses GDConsts, GDVars, DaxIo, GameIo, SoundDrv, MusDrv, C_Music, C_Sound, Types;

{ Plays a sound command: stops the music driver if it is installed, installs SoundDrv's driver if none is, then calls
  SoundCommand.
  @param(arg Sound command for SoundDrv.SoundCommand.) }
procedure SendSoundCommand(arg: Word);

{ Shuts down the music driver if it is installed, then calls SoundDrv.StartSound. }
procedure RestoreSoundDriver;

{ Starts the music described by a parameter block of MUSIC.dax. Nothing happens while sound is muted. SoundDrv's driver
  is reset if it is active, and a music driver installed with a different block is shut down; when no driver is
  installed the block is loaded and the driver installed with it. Then the driver is told to start (StartPlayback).
  @param(disk The parameter block's entry in MUSIC.dax.) }
procedure StartMusic(disk: Word);

{ Shuts down the music driver if it is installed. }
procedure StopMusic;

{ Loads the driver image, entry 0 of MUSIC.dax, into the driver buffer (cleared first) at its first paragraph boundary,
  and marks it loaded. A missing image stops the game with 'unable to load com file'. }
procedure LoadDriverCode;

{ Loads a parameter block of MUSIC.dax into the driver parameter buffer (cleared first) and points the driver's
  parameter pointer at it. Note: a missing block is not reported; the buffer is then left cleared.
  @param(fileId The block's entry in MUSIC.dax.) }
procedure LoadMusicBank(fileId: Word);
implementation

procedure SendSoundCommand(arg: Word);
begin
  if GDVars.soundActive = 2 then MusDrv.StopHook;
  if GDVars.soundActive = 0 then SoundDrv.StartSound;
  SoundDrv.SoundCommand(arg);
end;

procedure RestoreSoundDriver;
begin
  if GDVars.soundActive = 2 then MusDrv.StopHook;
  SoundDrv.StartSound;
end;

procedure StartMusic(disk: Word);
begin
  if GDVars.soundMode = C_Sound.OFF then Exit;
  if GDVars.soundActive = 1 then SoundDrv.SoundCommand(GDConsts.soundReset);
  if GDVars.currentMusic <> disk then
    if GDVars.soundActive = 2 then MusDrv.StopHook;
  if GDVars.soundActive = 0 then begin
    GDVars.currentMusic := disk;
    Music.LoadMusicBank(disk);
    MusDrv.StartDriver(GDVars.musicDriverImage, GDVars.musicData);
  end;
  MusDrv.StartPlayback(0);
end;

procedure StopMusic;
begin
  if GDVars.soundActive = 2 then MusDrv.StopHook;
end;

procedure LoadDriverCode;
var data: Types.PBytes;
begin
  data := nil;
  DaxIo.LoadDax('MUSIC', GDConsts.daxExtension, 0, GDVars.musicDriverSize, Types.PBytes(data));
  if GDVars.musicDriverSize = 0 then begin
    WriteLn('unable to load com file');
    GameIo.ExitGame;
  end;
  FillChar(GDVars.musicDriverBuf^, C_Music.DRIVER_BUFFER_SIZE, 0);
  GDVars.musicDriverImage := LongInt(GDVars.musicDriverBuf);
  while Lo(GDVars.musicDriverImage and $F) <> 0 do Inc(GDVars.musicDriverImage);
  Move(data^, Types.PBytes(GDVars.musicDriverImage)^, GDVars.musicDriverSize);
  FreeMem(data, GDVars.musicDriverSize);
  GDVars.musicDriverLoaded := 1;
end;

procedure LoadMusicBank(fileId: Word);
var
  data: Types.PBytes;
  { Unused in this version; see the other implementations of this routine. }
  n: Byte;
begin
  DaxIo.LoadDax('MUSIC', GDConsts.daxExtension, fileId, GDVars.musicDataSize, Types.PBytes(data));
  FillChar(GDVars.musicDataBuf^, C_Music.DATA_BUFFER_SIZE, 0);
  GDVars.musicData := GDVars.musicDataBuf;
  Move(data^, GDVars.musicData^, GDVars.musicDataSize);
  FreeMem(data, GDVars.musicDataSize);
end;
begin
end.
