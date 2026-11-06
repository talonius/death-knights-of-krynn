{ Intro -- the title sequence FixMain runs at start-up: four TITLE pictures with the opening music, then the credits
  screen; it ends by setting GDVars.gameUp. }
{$O+,F+,V+}
unit Intro;
interface

{ Frees the picture-box animation, hides the mouse, starts disk 1's music and shows TITLE pictures 1..4 (the first two
  full screen, the last two from row 11), holding each 5, 5, 5 and 20 seconds; a key during any of them skips to the
  credits. The credits always follow, then FinishIntroduction. }
procedure Introduction;

{ Does nothing; nothing calls it. }
procedure NoopIntro;
implementation
uses GDConsts, GDVars, Crt, TextRend, Blit, Mouse, Border, Music, Portrait, GameIo, Types;

{ Waits up to a number of seconds or until a key, flushing the keyboard before and after. A clock that runs backwards
  (midnight) also ends the wait.
  @param(ticks Seconds to wait.)
  @returns(True when the wait ended early, by a key or by the clock running backwards.) }
function DelayOrKey(ticks: Word): Boolean;
var
  base: LongInt;
  target: LongInt;
begin
 GameIo.FlushKeys;
 base := TextRend.GetTicks;
 target := base + ticks * 100;
 repeat until GameIo.InputPending or (TextRend.GetTicks >= target) or (TextRend.GetTicks < base);
 if TextRend.GetTicks >= target then DelayOrKey := False else DelayOrKey := True;
 GameIo.FlushKeys
end;

{ Shows the mouse again and sets GDVars.gameUp to mark the game running. }
procedure FinishIntroduction;
begin Mouse.ShowMouse; GDVars.gameUp := 1 end;

{ Draws the credits in a framed window and holds them until a key (10,000 seconds otherwise), then clears the screen. }
procedure Credits;
begin
 TextRend.ClearScreen; Border.DrawWindowFrame(0);
 TextRend.DisplayString(2, 1, Yellow, Black, 'CREATED BY:SSI SPECIAL PROJECTS TEAM');
 TextRend.DisplayString(11, 3, White, Black, 'GAME DEVELOPMENT:');
 TextRend.DisplayString(4, 4, LightGreen, Black, 'KEN HUMPHRIES     DAVE SHELLEY');
 TextRend.DisplayString(13, 5, White, Black, 'PROGRAMMING:');
 TextRend.DisplayString(14, 6, LightGreen, Black, 'RUSS BROWN');
 TextRend.DisplayString(1, 8, White, Black, 'ENCOUNTER CODE:');
 TextRend.DisplayString(4, 9, LightGreen, Black, 'RHONDA GILBERT    KEN EKLUND');
 TextRend.DisplayString(4, 10, LightGreen, Black, 'CAROLYN BICKFORD  GARY SHOCKLEY');
 TextRend.DisplayString(4, 11, LightGreen, Black, 'CYRUS HARRIS      ALAN MARENCO');
 TextRend.DisplayString(4, 12, LightGreen, Black, 'TERREA THOMPSON');
 TextRend.DisplayString(1, 13, White, Black, 'GRAPHIC ARTS:');
 TextRend.DisplayString(4, 14, LightGreen, Black, 'MAURINE STARKEY   MIKE PROVENZA');
 TextRend.DisplayString(4, 15, LightGreen, Black, 'LAURA BOWEN       CYRUS LUM');
 TextRend.DisplayString(4, 16, LightGreen, Black, 'FRED BUTTS        DANIEL COLON,JR.');
 TextRend.DisplayString(1, 17, White, Black, 'PLAYTEST:');
 TextRend.DisplayString(4, 18, LightGreen, Black, 'JOHN KIRK         JEFF SHOTWELL');
 TextRend.DisplayString(4, 19, LightGreen, Black, 'MIKE GILMARTIN    GLEN CURETON');
 TextRend.DisplayString(4, 20, LightGreen, Black, 'PHIL ALNE         ERIK FLOM');
 TextRend.DisplayString(1, 21, White, Black, 'MUSIC:');
 TextRend.DisplayString(4, 22, LightGreen, Black, '"THE FAT MAN"     DAVE GOVETT');
 if Intro.DelayOrKey(10000) then;
 TextRend.ClearScreen
end;

procedure Introduction;
var
  pic: Types.PImgBuf;
  { Unused in this version; see the other implementations of this routine. }
  keyed: Boolean;
begin
 pic := nil; Portrait.FreeAnimation(GDVars.portraitAnimation); Mouse.HideMouse; TextRend.ClearScreen;
     Music.StartMusic(1);
 Blit.LoadPic('title', 1, Boolean(GDConsts.pictureMode), Black, pic); Blit.ShowPic(0, 0, pic); Blit.FreePic(pic);
 if Intro.DelayOrKey(5) then begin Intro.Credits; Intro.FinishIntroduction; Exit end;
 Blit.LoadPic('title', 2, Boolean(GDConsts.pictureMode), Black, pic); TextRend.ClearScreen; Blit.ShowPic(0, 0,
                                                                                                pic); Blit.FreePic(pic);
 if Intro.DelayOrKey(5) then begin Intro.Credits; Intro.FinishIntroduction; Exit end;
 Blit.LoadPic('title', 3, Boolean(GDConsts.pictureMode), Black, pic); Blit.ShowPic(0, 11, pic); Blit.FreePic(pic);
 if Intro.DelayOrKey(5) then begin Intro.Credits; Intro.FinishIntroduction; Exit end;
 Blit.LoadPic('title', 4, Boolean(GDConsts.pictureMode), Black, pic); Blit.ShowPic(0, 11, pic); Blit.FreePic(pic);
 if Intro.DelayOrKey(20) then begin Intro.Credits; Intro.FinishIntroduction; Exit end;
 Intro.Credits; Intro.FinishIntroduction; Exit
end;

procedure NoopIntro;
begin end;
begin end.
