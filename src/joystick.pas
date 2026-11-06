{ Joystick -- the game-port joystick. ReadJoystick (joystick.asm) reads a stick's two axis counts and its buttons; the
  rest calibrates stick 1 into five thresholds per axis and turns a reading into one of the nine zones of
  joystickZoneMap, or a button. Only stick 1 is ever calibrated. }
{$F+,O-,S-,R-,V-,B-,I-}
unit Joystick;
interface
uses GDConsts, GDVars, Crt;

{ Clears both calibration records; when the joystick is enabled, keeps it enabled only if joystick 1 can be read. }
procedure ProbeJoystick;

{ Reads a joystick and places each axis among its calibrated boundaries 1..5, then looks the column and row up in the
  zone map.
  @param(joy Joystick 1 or 2.)
  @returns(The zone from the zone map, or the no-zone value when the joystick is off or cannot be read.) }
function JoyZone(joy: Byte): Byte;

{ Tells whether a joystick button is pressed. Joystick 1's buttons are bits 0 and 1 of the button byte, joystick 2's
  bits 2 and 3; another joystick or button number reads as not pressed.
  @param(joy Joystick 1 or 2.)
  @param(button Button 1 or 2.)
  @returns(True when the button is down; False when the joystick is off or cannot be read.) }
function JoyButton(joy, button: Byte): Boolean;

{ Reads joystick 1 as input: a pressed button and the stick's zone.
  @param(dir Receives 2 when button 2 is down, else 1 when button 1 is down, else 0.)
  @param(zone Receives the stick's zone, from JoyZone.) }
procedure GetJoystick(var dir: Integer; var zone: Byte);

{ Calibrates joystick 1 and enables it. The center is the average of 20 readings; the player then holds the stick at the
  upper-left and lower-right extremes with button 1 down, each taken as the extreme of 20 readings, and the boundaries
  lie a third and two thirds of the way from each extreme to the center. 20000 polls without a press, or a failed read,
  abort the calibration with a message. Does nothing when the joystick cannot be read. }
procedure CalibrateJoystick;

{ Reads a joystick from the game port, timing each axis's capacitor discharge.
  @param(joy Joystick 1 or 2; any other number fails.)
  @param(xRaw Receives the X axis count.)
  @param(yRaw Receives the Y axis count.)
  @param(buttons Receives all four button bits of both joysticks, inverted so a set bit is a pressed button and shifted
    to the low nibble.)
  @returns(True when the read succeeded; False for a bad joystick number or when an axis times out.) }
function ReadJoystick(joy: Byte; var xRaw, yRaw: Word; var buttons: Byte): Boolean;
implementation
{$L JOYSTICK.OBJ}

function ReadJoystick(joy: Byte; var xRaw, yRaw: Word; var buttons: Byte): Boolean;
  external;

procedure ProbeJoystick;
var
  x: Word;
  y: Word;
  b: Byte;
begin
  FillChar(GDVars.joyCalib, SizeOf(GDVars.joyCalib), 0);
  if GDVars.joystickActive <> 0 then
    GDVars.joystickActive := Ord(Joystick.ReadJoystick(1, x, y, b));
end;

function JoyZone(joy: Byte): Byte;
var
  x: Word;
  y: Word;
  col: Integer;
  row: Integer;
  b: Byte;
  { Unused in this version; see the other implementations of this routine. }
  threshold: array[0..1] of Byte;
begin
  JoyZone := 8;
  if GDVars.joystickActive = 0 then
    Exit;
  if not Joystick.ReadJoystick(joy, x, y, b) then
    Exit;
  col := 0;
  for GDVars.loopIndex := 1 to 5 do
    if GDVars.joyCalib[joy].x.thr[GDVars.loopIndex] < x then
      col := GDVars.loopIndex;
  row := 0;
  for GDVars.loopIndex := 1 to 5 do
    if GDVars.joyCalib[joy].y.thr[GDVars.loopIndex] < y then
      row := GDVars.loopIndex;
  JoyZone := GDConsts.joystickZoneMap[row, col];
end;

function JoyButton(joy, button: Byte): Boolean;
var
  mask: Byte;
  x: Word;
  y: Word;
  b: Byte;
begin
  JoyButton := False;
  if GDVars.joystickActive = 0 then
    Exit;
  mask := 0;
  b := 0;
  if Joystick.ReadJoystick(joy, x, y, b) then
    case joy of
      1: case button of
           1: mask := GDConsts.joystickButtonMasks[1, 1];
           2: mask := GDConsts.joystickButtonMasks[1, 2];
         end;
      2: case button of
           1: mask := GDConsts.joystickButtonMasks[2, 1];
           2: mask := GDConsts.joystickButtonMasks[2, 2];
         end;
    end;
  JoyButton := (b and mask) > 0;
end;

procedure GetJoystick(var dir: Integer; var zone: Byte);
begin
  dir := 0;
  if Joystick.JoyButton(1, 2) then
    dir := 2
  else if Joystick.JoyButton(1, 1) then
    dir := 1;
  zone := Joystick.JoyZone(1);
end;

procedure CalibrateJoystick;
var
  sumX: Word;
  sumY: Word;
  ok: Byte;
  x: Word;
  y: Word;
  { Unused in this version; see the other implementations of this routine. }
  reading: Byte;
  j: Word;
  buttons: Byte;
begin
  Joystick.ProbeJoystick;
  if GDVars.joystickActive = 0 then
    Exit;
  sumX := 0;
  sumY := 0;
  for j := 1 to 20 do begin
    ok := Byte(Joystick.ReadJoystick(1, x, y, buttons));
    Inc(sumX, x);
    Inc(sumY, y);
  end;
  GDVars.joyCalib[1].x.thr[3] := sumX div 20;
  GDVars.joyCalib[1].y.thr[3] := sumY div 20;
  repeat
    ClrScr;
    WriteLn(GDConsts.upperPrompt1 + ' ' + GDConsts.upperPrompt2);
    j := 0;
    repeat
      ok := Byte(Joystick.ReadJoystick(1, x, y, buttons));
      Inc(j);
    until (j > 20000) or ((ok <> 0) and ((buttons and GDConsts.joystickButtonMasks[1, 1]) <> 0));
    if j > 20000 then begin
      ClrScr;
      WriteLn(GDConsts.joystickReadError);
      Delay(2000);
      Exit;
    end;
    sumX := 65535;
    sumY := 65535;
    for GDVars.loopIndex := 1 to 20 do begin
      if Joystick.ReadJoystick(1, x, y, buttons) then begin
        if (buttons and GDConsts.joystickButtonMasks[1, 1]) <> 0 then begin
          if x < sumX then
            sumX := x;
          if y < sumY then
            sumY := y;
        end;
      end else begin
        ClrScr;
        WriteLn(GDConsts.joystickReadError);
        Delay(2000);
        Exit;
      end;
    end;
  until ok <> 0;
  GDVars.joyCalib[1].x.lo := sumX;
  GDVars.joyCalib[1].x.thr[1] :=
    GDVars.joyCalib[1].x.lo + (GDVars.joyCalib[1].x.thr[3] - GDVars.joyCalib[1].x.lo) div 3;
  GDVars.joyCalib[1].x.thr[2] :=
    GDVars.joyCalib[1].x.lo + (GDVars.joyCalib[1].x.thr[3] - GDVars.joyCalib[1].x.lo) * 2 div 3;
  GDVars.joyCalib[1].y.lo := sumY;
  GDVars.joyCalib[1].y.thr[1] :=
    GDVars.joyCalib[1].y.lo + (GDVars.joyCalib[1].y.thr[3] - GDVars.joyCalib[1].y.lo) div 3;
  GDVars.joyCalib[1].y.thr[2] :=
    GDVars.joyCalib[1].y.lo + (GDVars.joyCalib[1].y.thr[3] - GDVars.joyCalib[1].y.lo) * 2 div 3;
  repeat
  until not Joystick.JoyButton(1, 1);
  repeat
    ClrScr;
    WriteLn(GDConsts.lowerPrompt1 + ' ' + GDConsts.lowerPrompt2);
    j := 0;
    repeat
      ok := Byte(Joystick.ReadJoystick(1, x, y, buttons));
      Inc(j);
    until (j > 20000) or ((ok <> 0) and ((buttons and GDConsts.joystickButtonMasks[1, 1]) <> 0));
    if j > 20000 then begin
      ClrScr;
      WriteLn(GDConsts.joystickReadError);
      Delay(2000);
      Exit;
    end;
    sumX := 0;
    sumY := 0;
    for GDVars.loopIndex := 1 to 20 do begin
      if Joystick.ReadJoystick(1, x, y, buttons) then begin
        if (buttons and GDConsts.joystickButtonMasks[1, 1]) <> 0 then begin
          if x > sumX then
            sumX := x;
          if y > sumY then
            sumY := y;
        end;
      end else begin
        ClrScr;
        WriteLn(GDConsts.joystickReadError);
        Delay(2000);
        Exit;
      end;
    end;
  until ok <> 0;
  GDVars.joyCalib[1].x.hi := sumX;
  GDVars.joyCalib[1].x.thr[4] :=
    GDVars.joyCalib[1].x.thr[3] + (GDVars.joyCalib[1].x.hi - GDVars.joyCalib[1].x.thr[3]) div 3;
  GDVars.joyCalib[1].x.thr[5] :=
    GDVars.joyCalib[1].x.thr[3] + (GDVars.joyCalib[1].x.hi - GDVars.joyCalib[1].x.thr[3]) * 2 div 3;
  GDVars.joyCalib[1].y.hi := sumY;
  GDVars.joyCalib[1].y.thr[4] :=
    GDVars.joyCalib[1].y.thr[3] + (GDVars.joyCalib[1].y.hi - GDVars.joyCalib[1].y.thr[3]) div 3;
  GDVars.joyCalib[1].y.thr[5] :=
    GDVars.joyCalib[1].y.thr[3] + (GDVars.joyCalib[1].y.hi - GDVars.joyCalib[1].y.thr[3]) * 2 div 3;
  GDVars.joystickActive := 1;
end;
begin
end.
