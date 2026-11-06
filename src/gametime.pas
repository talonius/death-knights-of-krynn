{ GameTime -- the game clock and camp's rest. The zone clock counts rounds, minutes, turns, hours, days, months and
  years, each carried into the next by GDConsts.clockUnitScale; each new day steps the three moons, and every advance
  times the party's effects out. CampRest runs the rest in 5-minute steps: a hit point for everyone each day, spells
  memorized and scribed, and the zone's chance of an interruption. }
{$O+,F+}
unit GameTime;
interface
uses C_Ifc, Crt, C_Keys, GDConsts, GDVars, Types, Sym8x8, FxEngine, CharHlp, TextRend, MenuCore, Magic, GameIo;

{ Empty routine with no callers. }
procedure NoopGameTime;

{ Advances the game clock one unit at a time, carrying each component into the next, then ages the party's timed effects
  by the same span.
  @param(amount Number of units.)
  @param(tUnit Clock component counted: 1 minutes, 2 tens of minutes, 3 hours, 4 days, 5 months, 6 years.) }
procedure AdvanceTime(amount: Byte; tUnit: ShortInt);

{ Rests the party for the rest time. Interactive, it first runs the rest menu, redraws the rest time now and then and
  asks whether to stop when a key is pressed. Each five-minute step advances the clock, heals the party once a day,
  carries spell memorizing and scribing forward, and, once per rest period of the zone, rolls the zone's interruption
  chance. Silent rest skips the menu, the redraws and the key check.
  @param(interactive True to show the menu and the rest time.)
  @returns(True when a wandering encounter interrupted the rest.) }
function CampRest(interactive: Boolean): Boolean;
implementation

{ Steps the three moons: each has a day counter, and once it has reached its limit (8, 1 and 6) the counter restarts,
  the moon's phase steps through 0..3 and its phase symbol is redrawn in the top border at column 8, 19 or 30; below the
  limit the counter just counts up. }
procedure ClockDisplay;
var
  { Unused in this version; see the other implementations of this routine. }
  moonIndex: Byte;
  symCol: Byte;
  symByte: Byte;

  { Steps one moon's day count and, at its limit, its phase and border symbol. }
  procedure AdvanceTopJunction(n: Word; limit: Byte);
  begin
    if GDVars.zone0^.moonTimer[n + $4B00] >= limit then begin
      if GDVars.zone0^.moonPhase[n + $4B00 - 3] >= 3 then
        GDVars.zone0^.moonPhase[n + $4B00 - 3] := 0
      else
        Inc(GDVars.zone0^.moonPhase[n + $4B00 - 3]);
      case n of
        $1FC: begin symByte := GDVars.zone0^.moonPhase[$4CF9] + 21; symCol := 8; end;
        $1FD: begin symByte := GDVars.zone0^.moonPhase[$4CFA] + 13; symCol := 19; end;
        $1FE: begin symByte := GDVars.zone0^.moonPhase[$4CFB] + 17; symCol := 30; end;
      end;
      Sym8x8.Put8x8Sym(symCol, 0, symByte + 256, False, False);
      GDVars.zone0^.moonTimer[n + $4B00] := 0;
    end else
      Inc(GDVars.zone0^.moonTimer[n + $4B00]);
  end;
begin
  AdvanceTopJunction($1FC, 8);
  AdvanceTopJunction($1FD, 1);
  AdvanceTopJunction($1FE, 6);
end;

{ Ages the timed effects of the party by a span of time, in steps of at most ten minutes; an effect whose time runs out
  is removed, and one with no duration never runs out. A flag per member marks the members that still have timed
  effects. Outside camp every member is aged; in camp only flagged members are, and nothing happens when none is
  flagged. Note: when the effect that runs out is second in a list, aging resumes at the first effect, which is aged
  again.
  @param(count Number of units.)
  @param(tUnit Clock component counted.) }
procedure TimeOutEffects(count: Byte; tUnit: ShortInt);
var
  u: ShortInt;
  i: Byte;
  step: Byte;
  total: Word;
  cur: Types.PCharacter;
  done: Boolean;
  found: Boolean;
  tail: Types.PEffect;
  prev: Types.PEffect;
  e: Types.PEffect;
begin
  if GDVars.interfaceState <> C_Ifc.CAMPING then
    FillChar(GDVars.effectsRunning, SizeOf(GDVars.effectsRunning), 1)
  else begin
    found := False;
    i := 1;
    repeat
      if GDVars.effectsRunning[i] <> 0 then found := True;
      Inc(i);
    until found or (i > GDVars.zone1^.partySize[$7F3E]);
    if not found then Exit;
  end;
  total := count;
  u := tUnit;
  while u > 1 do begin
    total := GDConsts.clockUnitScale[Pred(u)] * total;
    u := Pred(u);
  end;
  while total > 0 do begin
    if total > 10 then step := 10 else step := total;
    i := 1;
    cur := GDVars.partyHead;
    while cur <> nil do begin
      if GDVars.effectsRunning[i] <> 0 then begin
        GDVars.effectsRunning[i] := 0;
        e := cur^.effects;
        tail := cur^.effects;
        prev := cur^.effects;
        if cur^.effects <> nil then
          while tail^.next <> nil do tail := tail^.next;
        done := False;
        while (e <> nil) and not done do begin
          if e = tail then done := True;
          if e^.duration = 0 then
            e := e^.next
          else if step < e^.duration then begin
            Dec(e^.duration, step);
            GDVars.effectsRunning[i] := 1;
            e := e^.next;
          end else begin
            FxEngine.RemoveEffect(cur, e^.effectId, e);
            if prev = cur^.effects then
              e := cur^.effects
            else
              e := prev^.next;
          end;
          prev := cur^.effects;
          while (prev <> nil) and (prev <> e) and (prev^.next <> e) do
            prev := prev^.next;
        end;
        while e <> nil do begin
          if e^.duration > 0 then GDVars.effectsRunning[i] := 1;
          e := e^.next;
        end;
      end;
      Inc(i);
      cur := cur^.next;
    end;
    if total > 10 then Dec(total, 10) else total := 0;
  end;
end;

{ Carries each unit of clock into the next, calling ClockDisplay for each new day. The year has nothing above it: once
  it reaches 256, every call ages each party member a year and clears agePassFlag, and the year is never reduced.
  @param(clock The clock to carry.) }
procedure ValidateClock(var clock: Types.TClock);
var
  i: ShortInt;
  cur: Types.PCharacter;
begin
  for i := 0 to 6 do
    if clock[i] >= GDConsts.clockUnitScale[i] then
      if i <> 6 then begin
        Inc(clock[Succ(i)]);
        clock[i] := clock[i] - GDConsts.clockUnitScale[i];
        if i = 3 then GameTime.ClockDisplay;
      end else begin
        cur := GDVars.partyHead;
        while cur <> nil do begin
          Inc(cur^.age);
          cur := cur^.next;
        end;
        GDVars.agePassFlag := 0;
      end;
end;

{ Normalizes the rest time, folds its months into days and caps it at 99 days. }
procedure ValidateRestTime;
begin
  GameTime.ValidateClock(GDVars.restTime);
  if GDVars.restTime[5] > 0 then begin
    Inc(GDVars.restTime[4], GDConsts.clockUnitScale[4] * GDVars.restTime[5]);
    GDVars.restTime[5] := 0;
    if GDVars.restTime[4] > 99 then GDVars.restTime[4] := 99;
  end;
end;

procedure AdvanceTime(amount: Byte; tUnit: ShortInt);
var
  clock: Types.TClock;
  i: ShortInt;
  j: Byte;
begin
  for i := 0 to 6 do
    clock[i] := GDVars.zone0^.clock[i + $4BC6];
  for j := 1 to amount do begin
    Inc(clock[tUnit]);
    GameTime.ValidateClock(clock);
  end;
  for i := 0 to 6 do
    GDVars.zone0^.clock[i + $4BC6] := clock[i];
  GameTime.TimeOutEffects(amount, tUnit);
end;

{ Takes a span off the rest time, borrowing from the larger components as needed; when there is nothing left to borrow,
  the rest time is cleared. Nothing happens when no days, hours or minutes are left.
  @param(count Number of units.)
  @param(tUnit Clock component counted.) }
procedure DecrementRestTime(count: Byte; tUnit: ShortInt);
var
  j: ShortInt;
  k: ShortInt;
begin
  if (GDVars.restTime[4] <> 0) or (GDVars.restTime[3] <> 0) or (GDVars.restTime[2] <> 0) or
      (GDVars.restTime[1] <> 0) then begin
    while count > GDVars.restTime[tUnit] do begin
      j := Succ(tUnit);
      while (GDVars.restTime[j] = 0) and (j < 5) do
        j := Succ(j);
      if j = 5 then begin
        FillChar(GDVars.restTime, SizeOf(GDVars.restTime), 0);
        count := 0;
      end else
        for k := j downto Succ(tUnit) do begin
          Dec(GDVars.restTime[k]);
          Inc(GDVars.restTime[Pred(k)], GDConsts.clockUnitScale[Pred(k)]);
        end;
    end;
    Dec(GDVars.restTime[tUnit], count);
    GameTime.ValidateRestTime;
  end;
end;

{ Formats a number with at least two digits, keeping the first two.
  @param(v The number.)
  @returns(The digits, with a leading zero below 10.) }
function TwoDigitStr(v: Byte): Types.TString40;
var
  s: Types.TString40;
begin
  s := CharHlp.ByteToString(v);
  if v < 10 then s := '0' + s;
  TwoDigitStr := Copy(s, 1, 2);
end;

{ Shows the rest time as days, hours and minutes on the message line, the selected field in white.
  @param(hl Clock component shown in white: 2 minutes, 3 hours, 4 days; 0 for none.) }
procedure DisplayRestTime(hl: ShortInt);
var
  i: ShortInt;
  colors: array[0..6] of Word;
  x: Byte;
begin
  for i := 0 to 6 do
    colors[i] := LightGreen;
  colors[hl] := White;
  TextRend.DisplayString(1, 17, LightGreen, Black, 'Rest Time:');
  x := 11;
  for i := 4 downto 3 do begin
    TextRend.DisplayString(x + 1, 17, colors[i], Black, GameTime.TwoDigitStr(GDVars.restTime[i]));
    TextRend.DisplayString(x + 1 + 2, 17, LightGreen, Black, ':');
    Inc(x, 3);
  end;
  TextRend.DisplayString(x + 1, 17, colors[2], Black,
                         GameTime.TwoDigitStr(10 * GDVars.restTime[2] + GDVars.restTime[1]));
end;

{ Runs the rest-time menu: Days, Hours or Mins picks the field, Add and Subtract change it (minutes move by five). The
  up arrow is Add, the down arrow is Subtract, left and right are ignored and any other extended key exits.
  @returns(True when the player chooses Rest.) }
function CampRestMenu: Boolean;
var
  choice: Byte;
  key: Char;
  sel: ShortInt;
begin
  CampRestMenu := False;
  sel := 2;
  repeat
    GameTime.DisplayRestTime(sel);
    MenuCore.EnableChoices(6);
    choice := MenuCore.MenuHorizontal(GDConsts.emptyQuery, GDConsts.restMenu, Ord(True), Ord(False));
    if (GDVars.menuExtendedKey <> 0) then begin
      key := Char(choice);
      case key of
        C_Keys.UP: choice := 4;
        C_Keys.DOWN: choice := 5;
        C_Keys.RIGHT, C_Keys.LEFT: choice := 255;
      else
        choice := 6;
      end;
    end;
    case choice of
      0: CampRestMenu := True;
      1: sel := 4;
      2: sel := 3;
      3: sel := 2;
      4: begin
             if sel = 2 then
               Inc(GDVars.restTime[1], 5)
             else
               Inc(GDVars.restTime[sel]);
             GameTime.ValidateRestTime;
           end;
      5: begin
             if sel = 2 then
               GameTime.DecrementRestTime(5, 1)
             else
               GameTime.DecrementRestTime(1, sel);
             GameTime.ValidateRestTime;
           end;
    end;
  until (choice = 6) or (choice = 0);
end;

{ Counts one five-minute rest step; once a day of steps has passed, restores a hit point to each party member, shows
  "The Whole Party Is Healed" and pauses, redrawing the party when anyone was healed.
  @param(interactive True to redraw the rest time first.) }
procedure CheckRestingHeal(interactive: Boolean);
var
  healed: Boolean;
  cur: Types.PCharacter;
begin
  Inc(GDVars.healTicks);
  if GDVars.healTicks >= 288 then begin
    healed := False;
    cur := GDVars.partyHead;
    while cur <> nil do begin
      if FxEngine.RestoreHitPoints(cur, 1, False) then healed := True;
      cur := cur^.next;
    end;
    if interactive then GameTime.DisplayRestTime(0);
    TextRend.DisplayString(1, 19, LightGreen, Black, 'The Whole Party Is Healed');
    if healed then CharHlp.DisplayParty(GDVars.currentCharacter);
    TextRend.PauseOnly;
    CharHlp.ClearMessageWindow;
    GDVars.healTicks := 0;
  end;
end;

{ The first spell cr has pending (bit 7 set): marks it memorized and announces it when done is False (then sets done),
  or returns its level when done is True.
  @param(cr Character to check.)
  @param(done True to only measure the next spell; False to finish it, and set True when one is finished.)
  @returns(The pending spell's level when measuring; 0 otherwise or while campRestActive is set.) }
function CheckMemorizeDone(cr: Types.PCharacter; var done: Boolean): Byte;
var
  lvl: Byte;
  i: Byte;
begin
  if GDVars.campRestActive then
    CheckMemorizeDone := 0
  else begin
    lvl := 0;
    i := 0;
    if (cr^.spells <> nil) and (cr^.enabled <> 0) then
      while (i <= 73) and (lvl = 0) do begin
        if cr^.spells^.memorized[i] > $7F then
          if done then
            lvl := GDConsts.spellTable[cr^.spells^.memorized[i] and $7F].level
          else begin
            Dec(cr^.spells^.memorized[i], $80);
            GameTime.DisplayRestTime(0);
            Magic.PrintCastSpellMsg(cr, 'has memorized', cr^.spells^.memorized[i]);
            done := True;
          end;
        Inc(i);
      end;
    CheckMemorizeDone := lvl;
  end;
end;

{ The same for a scroll spell cr is scribing: scribes it into known, removes it from the scroll and announces it, or
  returns its level. Note: while campRestActive is set it exits without setting its result.
  @param(cr Character to check.)
  @param(done True to only measure the next spell; False to finish it, and set True when one is finished.)
  @returns(The scroll spell's level when measuring; 0 otherwise.) }
function CheckScribeDone(cr: Types.PCharacter; var done: Boolean): Byte;
var
  j: Byte;
  sp: Byte;
  lvl: Byte;
  it: Types.PItem;
  { Unused in this version; see the other implementations of this routine. }
  found: Boolean;
begin
  if GDVars.campRestActive then Exit;
  lvl := 0;
  found := False;
  it := cr^.items;
  if cr^.spells <> nil then
  while (it <> nil) and (lvl = 0) do begin
    j := 1;
    if Magic.ItemReadable(it) then
      while (j <= 3) and (lvl = 0) do begin
        if it^.scrollSpells[j] > $80 then begin
          found := True;
          if done then
            lvl := GDConsts.spellTable[it^.scrollSpells[j] and $7F].level
          else begin
            sp := it^.scrollSpells[j] and $7F;
            cr^.spells^.known[sp] := 1;
            Magic.RemoveSpellFromScroll(cr, it, sp);
            GameTime.DisplayRestTime(0);
            Magic.PrintCastSpellMsg(cr, 'has scribed', sp);
            done := True;
          end;
        end;
        Inc(j);
      end;
    it := it^.next;
  end;
  CheckScribeDone := lvl;
end;

{ Counts down each party member's spell-preparation timer; when it runs out and the member's preparation wait is over,
  the next spell being scribed or else memorized is finished and the timer restarts at three times the following spell's
  level. }
procedure AdvanceSpellPrep;
var
  i: Byte;
  lvl: Byte;
  cur: Types.PCharacter;
  done: Boolean;
begin
  i := 1;
  cur := GDVars.partyHead;
  while cur <> nil do begin
    if GDVars.spellPrepTimers[i] > 0 then Dec(GDVars.spellPrepTimers[i]);
    if (GDVars.spellPrepTimers[i] = 0) and (cur^.spellPrep = 0) then begin
      done := False;
      lvl := GameTime.CheckScribeDone(cur, done);
      if lvl = 0 then lvl := GameTime.CheckMemorizeDone(cur, done);
      GDVars.spellPrepTimers[i] := lvl * 3;
    end;
    cur := cur^.next;
    Inc(i);
  end;
end;

{ Counts rest steps; every twelfth step, each party member's preparation wait drops by one, and when it reaches zero the
  member's spell-preparation timer starts at three times the level of the next spell to scribe or memorize.
  @param(tick The step counter, kept by the caller.) }
procedure AdvanceSpellPrepBase(var tick: Byte);
var
  i: Byte;
  lvl: Byte;
  cur: Types.PCharacter;
  done: Boolean;
begin
  Inc(tick);
  if tick >= 12 then begin
    tick := 0;
    i := 1;
    cur := GDVars.partyHead;
    while cur <> nil do begin
      if cur^.spellPrep > 0 then begin
        Dec(cur^.spellPrep);
        if cur^.spellPrep = 0 then begin
          done := True;
          lvl := GameTime.CheckScribeDone(cur, done);
          if lvl = 0 then lvl := GameTime.CheckMemorizeDone(cur, done);
          GDVars.spellPrepTimers[i] := lvl * 3;
        end;
      end;
      cur := cur^.next;
      Inc(i);
    end;
  end;
end;

function CampRest(interactive: Boolean): Boolean;
var
  cur: Types.PCharacter;
  { Unused in this version; see the other implementations of this routine. }
  member: Pointer;
  { Unused in this version; see the other implementations of this routine. }
  memberCount: Byte;
  i: Byte;
  tick: Byte;
  cnt: Byte;
  stop: Boolean;
  { Unused in this version; see the other implementations of this routine. }
  interrupted: Boolean;
begin
  CampRest := False;
  interrupted := False;
  i := 1;
  cur := GDVars.partyHead;
  while cur <> nil do begin
    GDVars.spellPrepTimers[i] := 0;
    Inc(i);
    cur := cur^.next;
  end;
  FillChar(GDVars.effectsRunning, SizeOf(GDVars.effectsRunning), 1);
  tick := 0;
  cnt := 0;
  if interactive then begin
    TextRend.ClearRect(1, 17, 38, 22);
    GameTime.DisplayRestTime(0);
  end;
  GDVars.noBorder := 1;
  if interactive then
    stop := not GameTime.CampRestMenu
  else
    stop := False;
  while (not stop) and ((GDVars.restTime[4] > 0) or (GDVars.restTime[3] > 0) or (GDVars.restTime[2] > 0) or
                        (GDVars.restTime[1] > 0)) do begin
    if interactive and GameIo.InputPending then begin
      GameTime.DisplayRestTime(0);
      if Char(MenuCore.YesNoMenu(GDConsts.stopRestPrompt, GDConsts.yesKey)) = Chr(GDConsts.yesKey) then
        stop := True
      else
        MenuCore.ClearBottomLine;
    end;
    if not stop then begin
      GameTime.DecrementRestTime(5, 1);
      Inc(cnt);
      if interactive and (cnt >= 5) then begin
        GameTime.DisplayRestTime(0);
        cnt := 0;
      end;
      GameTime.AdvanceTime(5, 1);
      GameTime.CheckRestingHeal(interactive);
      GameTime.AdvanceSpellPrep;
      GameTime.AdvanceSpellPrepBase(tick);
      if GDVars.zone1^.restPeriod[GDConsts.restPeriodIndex + $7C00] > 0 then begin
        Inc(GDVars.restTicks);
        if GDVars.restTicks >= GDVars.zone1^.restPeriod[GDConsts.restPeriodIndex + $7C00] then begin
          GDVars.restTicks := 0;
          if FxEngine.RollDice(1, 100) <=
              GDVars.zone1^.interruptPct[GDConsts.interruptPctIndex + $7C00] then begin
            CharHlp.ClearMessageWindow;
            GameTime.DisplayRestTime(0);
            TextRend.DisplayString(1, 19, White, Black, 'Your repose is suddenly interrupted!');
            stop := True;
            CampRest := True;
            TextRend.PauseOnly;
          end;
        end;
      end;
    end;
  end;
  TextRend.ClearRect(1, 17, 38, 22);
  GDVars.noBorder := 0;
end;

procedure NoopGameTime;
begin
end;
begin
end.
