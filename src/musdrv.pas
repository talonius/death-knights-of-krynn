{ MusDrv -- the calls into the resident music driver. Music.StartMusic loads a disk's music (Music.LoadMusicBank),
  installs the driver image with StartDriver and starts it with StartPlayback; StopHook stops it, called by Music when
  the music changes or another sound needs the device, and by GameIo when the game ends or the music is toggled off.
  soundActive 2 means this driver is installed. }
{$F+,O-,S-,R-,V-,B-,I-}
unit MusDrv;
interface

{ Calls the driver's dispatch entry with a function code and a far argument; returns its status. Codes used: 0 install
  (StartDriver), 1 start (StartPlayback), 3 stop (StopHook).
  @param(code Driver function code.)
  @param(argOfs Offset of the far argument.)
  @param(argSeg Segment of the far argument.)
  @returns(The driver's status.) }
function DriverCall(code, argOfs, argSeg: Word): Word;

{ Marks the music driver installed and halts unless the image address is a paragraph multiple; turns the address into a
  far entry point whose segment starts 256 bytes below the image, as if the image had been loaded behind a PSP; saves
  the parameter block and sends the initialize event.
  @param(image Far address of the loaded driver image, as a LongInt.)
  @param(params The parameter block handed to the driver at install.) }
procedure StartDriver(image: LongInt; params: Pointer);

{ Calls driver code 1 when given 0; any other value does nothing.
  @param(mode 0 to start playback.) }
procedure StartPlayback(mode: Word);

{ When the music driver is installed, marks it idle and sends it the shutdown event. }
procedure StopHook;
implementation
uses GDVars;
var
  { StartDriver computes it as a number }
  driverDispatchAddress: LongInt absolute GDVars.driverDispatch;

function DriverCall(code, argOfs, argSeg: Word): Word;
begin
  DriverCall := GDVars.driverDispatch(argSeg, argOfs, code);
end;

procedure StartDriver(image: LongInt; params: Pointer);
begin
  GDVars.soundActive := 2;
  if Byte(image and $F) <> 0 then Halt;
  Inc(image, (image and $FFF0) shl 12);
  image := image and $FFFF0000;
  Inc(image, $100);
  Dec(image, $100000);
  driverDispatchAddress := image;
  Move(params, GDVars.driverParamsOfs, SizeOf(params));
  GDVars.driverArgOfs := GDVars.driverParamsOfs;
  GDVars.driverArgSeg := GDVars.driverParamsSeg;
  GDVars.driverStatus := MusDrv.DriverCall(0, GDVars.driverArgOfs, GDVars.driverArgSeg);
end;

procedure StartPlayback(mode: Word);
begin
  if mode <> 0 then Exit;
  GDVars.driverStatus := MusDrv.DriverCall(1, 0, 0);
end;

procedure StopHook;
begin
  if GDVars.soundActive = 2 then begin
    GDVars.soundActive := 0;
    GDVars.driverStatus := MusDrv.DriverCall(3, 0, 0);
  end;
end;
begin
end.
