{ FixMain -- the program. The body initializes (GameInit.InitializeGame), loads the music driver and runs the title,
  then asks Play or Demo, answering itself after 30 seconds. Each pass of the main loop stops the music; a demo runs
  from disk 2 with slow text, a real game goes through CharGen's party menu and the journal-word copy protection --
  aborting unless CopyProt passes and sets all four GDVars.protectionMarks -- and draws the interface: the row divider
  on the overland map while GDVars.zone0^.wildOn is 1, else the inset picture. EclVm.GameLoop then plays until the party
  leaves, ResetGameState resets the session, and after a demo the title runs again and the Play/Demo menu returns with a
  10-second timeout. It repeats until GDConsts.gameDone is set. }
{$F+,O+}
program FixMain;
uses
  Overlay, Dos, Crt, ModeInit, Joystick, Mouse, SoundDrv, MusDrv,
  GameIo, DaxIo, Music, TextRend, Blit, GameBoot, Border,
  Sym8x8, MapTiles, CbtMap, Pathing,
  EmptyC,
  View3D, Portrait, MapView,
  MenuCore, ClassCal, MapCurs, CharHlp, FxEngine, Magic, Money,
  GameTime, ViewChar, CbtActs, EffHndlr, GameInit, SaveLoad, CharGen,
  Camp, Explore, CombatSt, CombatAi, Combat, EclMenu, Shop,
  PostCbt, Temple, CopyProt, Vault, EclVm, Intro, HeapErr,
  GDConsts, GDVars, C_Ifc, Types;
{$O HeapErr}
{$O Intro}
{$O EclVm}
{$O Vault}
{$O CopyProt}
{$O Temple}
{$O PostCbt}
{$O Shop}
{$O EclMenu}
{$O Combat}
{$O CombatAi}
{$O CombatSt}
{$O Explore}
{$O Camp}
{$O SaveLoad}
{$O CharGen}
{$O GameInit}
{$O EffHndlr}
{$O CbtActs}
{$O ViewChar}
{$O GameTime}
{$O Money}
{$O Magic}
{$O FxEngine}
{$O CharHlp}
{$O MapCurs}
{$O ClassCal}
{$O MenuCore}
{$O MapView}
{$O Portrait}
{$O View3D}
{$O Pathing}
{$O CbtMap}
{$O MapTiles}
{$O Sym8x8}
begin
  GameInit.InitializeGame;
  Music.LoadDriverCode;
  Intro.Introduction;
  GDVars.menuTimeout := 3000;
  GDVars.menuTimeoutKey := 1;
  MenuCore.EnableChoices(1);
  GDVars.menuResult := MenuCore.MenuHorizontal(GDConsts.gameTitle, GDConsts.playDemoMenu, 0, 0);
  GDVars.menuTimeout := 0;
  GDVars.menuTimeoutKey := 1;
  if GDVars.menuResult = 1 then GDVars.demoMode := 1;
  repeat
    Music.StopMusic;
    if GDVars.demoMode <> 0 then begin
      GDVars.diskNumber := 2;
      GDVars.textDelay := 9;
    end else
      GDVars.diskNumber := 1;
    if GDVars.demoMode = 0 then begin
      CharGen.MainMenu;
      if Ord(CopyProt.CopyProtection) <> 1 then GameIo.ExitGame;
      for GDVars.checkIdx := 1 to 4 do
        if GDVars.protectionMarks[GDVars.checkIdx] = 0 then GameIo.ExitGame;
      if (GDVars.interfaceState = C_Ifc.OVERLAND) and (GDVars.zone0^.wildOn = 1) then
        Border.DrawRowDivider
      else
        Border.DrawViewFrame;
      CharHlp.DisplayParty(GDVars.currentCharacter);
    end;
    View3D.SetViewColors(GDVars.paletteSky, GDVars.paletteCeil, GDVars.paletteFloor, GDVars.paletteWall);
    EclVm.GameLoop;
    GameInit.ResetGameState;
    if GDVars.demoMode <> 0 then begin
      Music.SendSoundCommand(GDConsts.soundReset);
      Intro.Introduction;
      Music.RestoreSoundDriver;
      GameIo.FlushKeys;
      GDVars.menuTimeout := 1000;
      GDVars.menuTimeoutKey := 1;
      MenuCore.EnableChoices(1);
      GDVars.menuResult := MenuCore.MenuHorizontal(GDConsts.gameTitle, GDConsts.playDemoMenu, 0, 0);
      GDVars.menuTimeout := 0;
      GDVars.menuTimeoutKey := 0;
      GDVars.demoMode := Ord(GDVars.menuResult = 1);
      Music.SendSoundCommand(GDConsts.soundOff);
    end;
  until GDConsts.gameDone <> 0;
end.
