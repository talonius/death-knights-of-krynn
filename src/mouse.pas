{ Mouse -- the INT 33h mouse driver calls, through mouseInterrupt, mouseFunctions and videoRegs. Each driver call but
  InitMouse does nothing when no mouse is present. }
{$F+,O-,S-,R-,V-,B-,I-}
unit Mouse;
interface
uses Dos, C_Dir, C_Keys, GDConsts, GDVars, Types;

{ Resets the mouse driver through INT 33h; when a driver answers, marks the mouse present and records the button count,
  otherwise marks it absent. }
procedure InitMouse;

{ Shows the mouse cursor. Does nothing without a mouse. }
procedure ShowMouse;

{ Hides the mouse cursor. Does nothing without a mouse. }
procedure HideMouse;

{ Reads the mouse buttons and position, halving the column unless the mouse's scale flag is set. Does nothing without a
  mouse.
  @param(buttons Receives the button state.)
  @param(x Receives the column.)
  @param(y Receives the row.) }
procedure GetMouse(var buttons, x, y: Integer);

{ Moves the mouse cursor, doubling the column unless the mouse's scale flag is set. Does nothing without a mouse.
  @param(x Column.)
  @param(y Row.) }
procedure SetMouse(x, y: Integer);

{ Sets the graphics cursor shape and hot spot. Does nothing without a mouse.
  @param(hotX Hot spot column within the cursor.)
  @param(hotY Hot spot row within the cursor.)
  @param(mask Screen and cursor masks of the shape.) }
procedure SetMouseCursor(hotX, hotY: Integer; mask: Types.PCursorMask);

{ Resets the mouse driver's software state. Does nothing without a mouse. }
procedure ResetMouse;

{ Classifies a mouse move into one of eight 45-degree sectors and returns the matching keypad key. The slopes 618/256
  and 106/256 stand for tan 67.5 and tan 22.5 degrees; the sectors are tried clockwise from up, so a move with no motion
  counts as up. Note: the horizontal change times 618 overflows an Integer for moves wider than 53 units, which can give
  the wrong direction.
  @param(oldX Starting column.)
  @param(oldY Starting row.)
  @param(newX Ending column.)
  @param(newY Ending row.)
  @returns(The scan code of the arrow, Home, End, Page Up or Page Down key for that direction.) }
function MouseDirection(oldX, oldY, newX, newY: Integer): Byte;
implementation

procedure InitMouse;
begin
  GDVars.videoRegs.AX := GDConsts.mouseFunctions[0];
  Intr(GDConsts.mouseInterrupt, Registers(GDVars.videoRegs));
  if GDVars.videoRegs.AX = $FFFF then begin
    GDVars.mouseButtonCount := GDVars.videoRegs.BX;
    GDVars.mousePresent := 1;
  end else
    GDVars.mousePresent := 0;
end;

procedure ShowMouse;
begin
  if GDVars.mousePresent = 0 then Exit;
  GDVars.videoRegs.AX := GDConsts.mouseFunctions[1];
  Intr(GDConsts.mouseInterrupt, Registers(GDVars.videoRegs));
end;

procedure HideMouse;
begin
  if GDVars.mousePresent = 0 then Exit;
  GDVars.videoRegs.AX := GDConsts.mouseFunctions[2];
  Intr(GDConsts.mouseInterrupt, Registers(GDVars.videoRegs));
end;

procedure GetMouse(var buttons, x, y: Integer);
begin
  if GDVars.mousePresent = 0 then Exit;
  GDVars.videoRegs.AX := GDConsts.mouseFunctions[3];
  Intr(GDConsts.mouseInterrupt, Registers(GDVars.videoRegs));
  buttons := GDVars.videoRegs.BX;
  x := GDVars.videoRegs.CX;
  if not GDVars.mouseScaled then x := x div 2;
  y := GDVars.videoRegs.DX;
end;

procedure SetMouse(x, y: Integer);
begin
  if GDVars.mousePresent = 0 then Exit;
  GDVars.videoRegs.AX := GDConsts.mouseFunctions[4];
  if not GDVars.mouseScaled then x := x shl 1;
  GDVars.videoRegs.CX := x;
  GDVars.videoRegs.DX := y;
  Intr(GDConsts.mouseInterrupt, Registers(GDVars.videoRegs));
end;

procedure SetMouseCursor(hotX, hotY: Integer; mask: Types.PCursorMask);
begin
  if GDVars.mousePresent = 0 then Exit;
  GDVars.videoRegs.AX := GDConsts.mouseFunctions[9];
  GDVars.videoRegs.BX := hotX;
  GDVars.videoRegs.CX := hotY;
  GDVars.videoRegs.ES := Seg(mask^);
  GDVars.videoRegs.DX := Ofs(mask^);
  Intr(GDConsts.mouseInterrupt, Registers(GDVars.videoRegs));
end;

procedure ResetMouse;
begin
  if GDVars.mousePresent = 0 then Exit;
  GDVars.videoRegs.AX := GDConsts.mouseFunctions[28];
  Intr(GDConsts.mouseInterrupt, Registers(GDVars.videoRegs));
end;

function MouseDirection(oldX, oldY, newX, newY: Integer): Byte;
var
  i: Byte;
  found: Boolean;
  sc: Byte;
  dx: Integer;
  dy: Integer;
begin
  dx := Abs(newX - oldX);
  dy := Abs(newY - oldY);
  i := C_Dir.NORTH;
  found := False;
  while not found do begin
    case i of
      C_Dir.NORTH: begin found := (newY <= oldY) and (dx * 618 div 256 <= dy); sc := Ord(C_Keys.UP) end;
      C_Dir.EAST: begin found := (newX >= oldX) and (dx * 106 div 256 >= dy); sc := Ord(C_Keys.RIGHT) end;
      C_Dir.SOUTH: begin found := (newY >= oldY) and (dx * 618 div 256 <= dy); sc := Ord(C_Keys.DOWN) end;
      C_Dir.WEST: begin found := (newX <= oldX) and (dx * 106 div 256 >= dy); sc := Ord(C_Keys.LEFT) end;
      C_Dir.NORTHEAST: begin
           found := (newY < oldY) and (newX > oldX) and (dx * 618 div 256 >= dy) and (dx * 106 div 256 <= dy);
           sc := Ord(C_Keys.PAGE_UP)
         end;
      C_Dir.SOUTHEAST: begin
           found := (newY > oldY) and (newX > oldX) and (dx * 618 div 256 >= dy) and (dx * 106 div 256 <= dy);
           sc := Ord(C_Keys.PAGE_DOWN)
         end;
      C_Dir.SOUTHWEST: begin
           found := (newY > oldY) and (newX < oldX) and (dx * 618 div 256 >= dy) and (dx * 106 div 256 <= dy);
           sc := Ord(C_Keys.END_KEY)
         end;
      C_Dir.NORTHWEST: begin
           found := (newY < oldY) and (newX < oldX) and (dx * 618 div 256 >= dy) and (dx * 106 div 256 <= dy);
           sc := Ord(C_Keys.HOME)
         end;
    end;
    if not found then Inc(i)
  end;
  MouseDirection := sc
end;
begin
end.
