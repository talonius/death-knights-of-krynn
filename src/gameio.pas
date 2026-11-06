{ GameIo -- keyboard, mouse and joystick input with the game's control-key toggles, the abort path, the overlay read
  retry, and the pool of item slots. }
{$F+,O+,S-,R-,V-,B-,I-}
unit GameIo;
interface
uses GDConsts, GDVars, Dos, Crt, Mouse, Joystick, SoundDrv, MusDrv, C_Keys, C_Sound, Types;

{ Hides and resets the mouse, shuts the music driver down, resets the sound card if one is active, restores the video
  mode the game started in and halts. }
procedure ExitGame;

{ Returns the next key. With a mouse or joystick in use it waits for a key or a device: a mouse button (1 Enter, 2
  Escape; sets the click flag) or, without a mouse, a joystick button (1 Enter, 2 Escape) or a stick zone 0..7 as its
  numpad digit. Without either it reads the keyboard, or returns #0 at once in a demo. Then Ctrl-S turns sound effects
  off or back to the saved Tandy or speaker mode, Ctrl-U toggles the music (shutting the driver down when off), Ctrl-D
  toggles the trace flag, Ctrl-Z walks each party member's effect list while it is on, and Ctrl-C aborts.
  @returns(The key, or the key the mouse or joystick input stands for.) }
function ReadGameKey: Char;

{ Tells whether input is waiting.
  @returns(True when a key is waiting, a mouse button is down, or -- without a mouse -- a joystick button is down or the
    stick is out of the center.) }
function InputPending: Boolean;

{ Reads and discards every key waiting in the keyboard buffer. }
procedure FlushKeys;

{ Reads and discards one waiting input through ReadGameKey, so its control-key commands still work. }
procedure DiscardPendingKeys;

{ Reads an overlay for the overlay manager, as installed by GameBoot: calls the saved reader until that succeeds,
  beeping (4000 Hz, 20 ms) after each failure.
  @param(ovrSeg The overlay to read, passed to the saved reader.)
  @returns(0, success.) }
function OverlayReadWithBeep(ovrSeg: Word): Integer;

{ Finds the first free record in the item pool (item type 0). It is not marked taken here: the caller's record fills it.
  @returns(The record, or nil when none is free.) }
function AllocSlot: Types.PItem;

{ Frees p: a pooled slot is marked free and p set to nil; anything else is a heap block, freed at an item's size and p
  left as it was.
  @param(p Item to free.) }
procedure FreeSlot(var p: Types.PItem);
implementation

procedure ExitGame;
var
  { Unused in this version; see the other implementations of this routine. }
  key: Char;
begin
  Mouse.HideMouse;
  Mouse.ResetMouse;
  MusDrv.StopHook;
  if GDVars.soundActive = 1 then
    SoundDrv.SoundCommand(GDConsts.soundReset);
  GDVars.videoRegs.ah := GDConsts.biosSetVideoMode;
  GDVars.videoRegs.al := GDVars.savedVideoMode;
  Intr(GDConsts.videoInterrupt, Registers(GDVars.videoRegs));
  Halt(0);
end;

{ Walks a character's effect list without acting on it; the Ctrl-Z trace calls it.
  @param(p Character whose effects are walked.) }
procedure WalkChildren(p: Types.PCharacter);
var cur: Types.PEffect;
begin
  cur := p^.effects;
  while cur <> nil do
    cur := cur^.next;
end;

function ReadGameKey: Char;
var
  key: Char;
  who: Types.PCharacter;
  jr: record flag: Byte; scan: Byte; special: Integer end;
  { Unused in this version; see the other implementations of this routine. }
  mouseButtons: Word;

  { Waits for a key or for joystick input, turning a button into Enter or Escape and a stick zone into its keypad key. }
  procedure TranslateJoystick;
  begin
    jr.special := 0;
    jr.flag := 0;
    while not (KeyPressed or (jr.flag <> 0)) do begin
      Joystick.GetJoystick(jr.special, jr.scan);
      if (jr.scan < 8) or Boolean(jr.special <> 0) then begin
        if jr.scan < 8 then
          key := Char(GDConsts.joystickZoneKeys[jr.scan])
        else
          case jr.special of
            1: key := C_Keys.ENTER;
            2: key := C_Keys.ESCAPE;
          end;
        jr.flag := 1;
      end;
    end;
  end;

  { Waits for a key or a mouse button, turning the button into Enter or Escape and noting the mouse click. }
  procedure TranslateMouse;
  begin
    jr.special := 0;
    jr.flag := 0;
    while not (KeyPressed or (jr.flag <> 0)) do begin
      Mouse.GetMouse(jr.special, GDVars.mouseRawX, GDVars.mouseRawY);
      if jr.special <> 0 then begin
        case jr.special of
          1: key := C_Keys.ENTER;
          2: key := C_Keys.ESCAPE;
        end;
        GDVars.mouseClick := 1;
        jr.flag := 1;
      end;
    end;
  end;
begin
  GDVars.mouseClick := 0;
  if KeyPressed then
    key := ReadKey
  else if (GDVars.joystickActive <> 0) or (GDVars.mousePresent <> 0) then begin
    if GDVars.mousePresent <> 0 then TranslateMouse else TranslateJoystick;
    if KeyPressed then key := ReadKey;
  end else begin
    if GDVars.demoMode <> 0 then key := #0 else key := ReadKey;
  end;
  if key = #19 then
    if GDVars.soundMode <> C_Sound.OFF then begin
      GDVars.savedSoundMode := GDVars.soundMode;
      if GDVars.soundActive = 1 then SoundDrv.SoundCommand(GDConsts.soundOff);
      GDVars.soundMode := C_Sound.OFF;
    end else if GDVars.savedSoundMode in [C_Sound.TANDY, C_Sound.SPEAKER] then begin
      GDVars.soundMode := GDVars.savedSoundMode;
      if GDVars.soundActive = 1 then SoundDrv.SoundCommand(GDConsts.soundOn);
    end;
  if key = #21 then begin
    GDVars.musicOn := Ord(GDVars.musicOn = 0);
    if GDVars.musicOn = 0 then MusDrv.StopHook;
  end;
  case key of
    #4: GDVars.traceActive := Ord(GDVars.traceActive = 0);
    #26:
      if GDVars.traceActive <> 0 then begin
        who := GDVars.partyHead;
        while who <> nil do begin
          GameIo.WalkChildren(who);
          who := who^.next;
        end;
      end;
    #3: GameIo.ExitGame;
  end;
  ReadGameKey := key;
end;

function InputPending: Boolean;
var
  special: Integer;
  scan: Byte;
begin
  InputPending := KeyPressed;
  if (GDVars.joystickActive <> 0) or (GDVars.mousePresent <> 0) then
    if GDVars.mousePresent <> 0 then begin
      Mouse.GetMouse(special, GDVars.mouseRawX, GDVars.mouseRawY);
      InputPending := KeyPressed or Boolean(special <> 0);
    end else begin
      Joystick.GetJoystick(special, scan);
      InputPending := KeyPressed or Boolean(special > 0) or Boolean(scan < 8);
    end;
end;

procedure FlushKeys;
var
  { Unused in this version; see the other implementations of this routine. }
  c: Char;
begin
  while KeyPressed do c := ReadKey;
end;

procedure DiscardPendingKeys;
var
  { Unused in this version; see the other implementations of this routine. }
  c: Char;
begin
  if GameIo.InputPending then c := GameIo.ReadGameKey;
end;

function OverlayReadWithBeep(ovrSeg: Word): Integer;
begin
  while GDVars.savedOvrRead(ovrSeg) <> 0 do begin
    Sound(4000);
    Delay(20);
    NoSound;
  end;
  OverlayReadWithBeep := 0;
end;

function AllocSlot: Types.PItem;
var
  i: Byte;
  found: Boolean;
  p: Types.PItem;
begin
  found := False;
  i := 1;
  p := nil;
  while (i <= SizeOf(GDVars.itemPool) div SizeOf(GDVars.itemPool[1])) and not found do
    if GDVars.itemPool[i].itemType = 0 then begin
      p := @GDVars.itemPool[i];
      found := True;
    end else
      Inc(i);
  AllocSlot := p;
end;

procedure FreeSlot(var p: Types.PItem);
var i: Byte;
begin
  i := 1;
  while (i <= SizeOf(GDVars.itemPool) div SizeOf(GDVars.itemPool[1])) and (p <> @GDVars.itemPool[i]) do Inc(i);
  if i <= SizeOf(GDVars.itemPool) div SizeOf(GDVars.itemPool[1]) then begin
    GDVars.itemPool[i].itemType := 0;
    p := nil;
  end else
    FreeMem(p, SizeOf(Types.TItem));
end;
begin
end.
