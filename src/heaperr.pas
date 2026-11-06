{ HeapErr -- the out-of-memory handler. This unit's initialization installs HeapErrorHandler as System.HeapError, so a
  failed heap allocation lands here. While a game is up (GDVars.gameUp) it warns and saves through SaveLoad, repeating
  until GDVars.recentlySaved is set; otherwise it warns that the program is exiting. Either way it ends in
  GameIo.ExitGame, which restores the video mode and halts. Every call, a zero-size one included, ends the game. }
{$O+,F+}
unit HeapErr;
interface

{ Warns that memory is short. While a game is in progress it saves the game, warning again until the saved flag shows
  the save went through; otherwise it says it is exiting. Note: the saved flag is not cleared before the save, so a flag
  still set by an earlier save ends the loop even if this save failed.
  @param(size Unused.)
  @returns(Never: ExitGame halts the program.) }
function HeapErrorHandler(size: Word): Integer;
implementation
uses Crt, TextRend, GameIo, SaveLoad, GDVars;

function HeapErrorHandler(size: Word): Integer;
var
  exitFlag: Byte;
begin
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
begin
  HeapError := @HeapErr.HeapErrorHandler;
end.
