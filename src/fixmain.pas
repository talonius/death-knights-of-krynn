{ FixMain -- the program. The body initializes (GameInit.InitializeGame), loads the music driver and runs the title,
  then asks Play or Demo, answering itself after 30 seconds. Each pass of the main loop stops the music; a demo runs
  from disk 2 with slow text, a real game goes through CharGen's party menu and the journal-word copy protection --
  aborting unless CopyProt passes and sets all four GDVars.protectionMarks -- and draws the interface: the row divider
  on the overland map while zone0^.wildOn is 1, else the inset picture. EclVm.GameLoop then plays until the party
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
  InitializeGame;
  LoadDriverCode;
  Introduction;
  GDVars.menuTimeout := 3000;
  GDVars.menuTimeoutKey := 1;
  EnableChoices(1);
  GDVars.menuResult := MenuHorizontal(GDConsts.gameTitle, GDConsts.playDemoMenu, 0, 0);
  GDVars.menuTimeout := 0;
  GDVars.menuTimeoutKey := 1;
  if GDVars.menuResult = 1 then GDVars.demoMode := 1;
  repeat
    StopMusic;
    if GDVars.demoMode <> 0 then begin
      GDVars.diskNumber := 2;
      GDVars.textDelay := 9;
    end else
      GDVars.diskNumber := 1;
    if GDVars.demoMode = 0 then begin
      MainMenu;
      if Ord(CopyProtection) <> 1 then ExitGame;
      for GDVars.checkIdx := 1 to 4 do
        if GDVars.protectionMarks[GDVars.checkIdx] = 0 then ExitGame;
      if (GDVars.interfaceState = C_Ifc.OVERLAND) and (GDVars.zone0^.wildOn = 1) then
        DrawRowDivider
      else
        DrawViewFrame;
      DisplayParty(GDVars.currentCharacter);
    end;
    SetViewColors(GDVars.paletteSky, GDVars.paletteCeil, GDVars.paletteFloor, GDVars.paletteWall);
    GameLoop;
    ResetGameState;
    if GDVars.demoMode <> 0 then begin
      SendSoundCommand(GDConsts.soundReset);
      Introduction;
      RestoreSoundDriver;
      FlushKeys;
      GDVars.menuTimeout := 1000;
      GDVars.menuTimeoutKey := 1;
      EnableChoices(1);
      GDVars.menuResult := MenuHorizontal(GDConsts.gameTitle, GDConsts.playDemoMenu, 0, 0);
      GDVars.menuTimeout := 0;
      GDVars.menuTimeoutKey := 0;
      GDVars.demoMode := Ord(GDVars.menuResult = 1);
      SendSoundCommand(GDConsts.soundOff);
    end;
  until GDConsts.gameDone <> 0;
end.
