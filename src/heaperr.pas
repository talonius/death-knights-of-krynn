{ HeapErr -- the out-of-memory handler. This unit's initialization installs HeapErrorHandler as System.HeapError, so a
  failed heap allocation lands here. While a game is up (GDVars.gameUp) it warns and saves through SaveLoad, repeating
  until GDVars.recentlySaved is set; otherwise it warns that the program is exiting. Either way it ends in
  GameIo.ExitGame, which restores the video mode and halts. A zero-size call returns at once. }
{$O+,F+}
unit HeapErr;
interface

{ Installed as HeapError, so the heap manager calls it when an allocation fails. For a nonzero request it shows an
  insufficient-memory warning; while a game is active it runs the save menu and repeats until a save sets the
  recently-saved flag, otherwise it says the program is exiting. Either way it then quits through GameIo.ExitGame. A
  zero-size request returns at once. Note: the saved flag is not cleared before the save, so a flag still set by an
  earlier save ends the loop even if this save failed; and the result is never assigned.
  @param(size Bytes requested; 0 does nothing.)
  @returns(Nothing: the result is never assigned.) }
function HeapErrorHandler(size: Word): Integer;
implementation
uses Crt, TextRend, GameIo, SaveLoad, GDVars;

function HeapErrorHandler(size: Word): Integer;
var
  exitFlag: Byte;
begin
  if size > 0 then begin
    exitFlag := 0;
    repeat
      TextRend.DisplayAndPause(Yellow, Black, 'WARNING: Insufficient Memory');
      if GDVars.gameUp <> 0 then begin
        SaveLoad.SaveGame;
        exitFlag := GDVars.recentlySaved;
      end else begin
        exitFlag := 1;
        TextRend.DisplayAndPause(Yellow, Black, 'Insufficient Memory. Exiting Program');
      end;
    until exitFlag <> 0;
    GameIo.ExitGame;
  end;
end;
begin
  HeapError := @HeapErr.HeapErrorHandler;
end.
