{ Combat -- the fight loop: rounds in initiative order, each creature's turn (the command menu, or CombatAi for a
  quick-fighter), moving and attacking on the arena, the end of each round, and the cleanup after. }
{$O+,F+,A-}
unit Combat;
interface

{ Frees the spell clouds and the arena; a charmed member that is okay is set running while more than one monster stands;
  removes each member's effects that end when it goes down, frees the moving icon and restores camp targeting. }
procedure CombatDoneCleanup;

{ Runs a fight. Switches to the combat interface state and the combat cast-target menu, applies leadership, sets up the
  fight and fires each creature's condition-24 effects, then, unless a side starts empty, plays rounds: each round
  counts the sides, runs each creature's round-start setup, clears the surprise mask, sorts the creatures by initiative
  and lets them act in that order, recounting the sides after each turn and ending the fight once a side is empty or the
  round limit is reached, then ends the round. Afterwards it runs the aging deaths when aging is pending, cleans up and
  turns slow text (the message-delay flag) back on. }
procedure CombatMain;
implementation
uses C_Class, C_Cond, C_Dir, C_Effect, C_Ifc, C_Npc, C_Race, C_Side, C_Status, C_Terr, GDConsts, GDVars, C_Keys, CbtMap,
  CharHlp, MenuCore, CbtActs, FxEngine, Border, TextRend, GameTime, Magic, Blit, CombatSt, CombatAi, ViewChar, GameIo,
  Crt, Types;

procedure AgingDeaths; forward;

procedure OrderCreatures; forward;

procedure CreatureAction(cr: Types.PCharacter); forward;

procedure ManualControl(cr: Types.PCharacter); forward;

procedure CombatMenu(cr: Types.PCharacter; var key: Char); forward;

procedure EndOfRound(var done: Boolean); forward;

procedure MoveMenu(cr: Types.PCharacter; key: Char; var done: Boolean); forward;

procedure MeleeAttack(cr, foe: Types.PCharacter; var done: Boolean); forward;

procedure SpeedMenu; forward;

procedure ClearTarget(cr: Types.PCharacter); forward;

procedure CombatDoneCleanup;
var
  nxt: Types.PCloudNode;
  cur: Types.PCharacter;
  eff: Pointer;
  { Unused in this version; see the other implementations of this routine. }
  effectScan: Word;
begin
  while GDVars.cloudList <> nil do begin
    nxt := GDVars.cloudList^.next;
    FreeMem(GDVars.cloudList, SizeOf(Types.TCloudNode));
    GDVars.cloudList := nxt
  end;
  cur := GDVars.partyHead;
  while cur <> nil do begin
    if CharHlp.HasEffect(cur, C_Effect.CHARM, eff) then
      if cur^.status = C_Status.OKAY then
        if GDVars.teamCount[C_Side.ENEMY] > 1 then cur^.status := C_Status.RUNNING
        else cur^.status := C_Status.OKAY;
    FxEngine.RemoveEffectsHp0(cur);
    cur := cur^.next
  end;
  FreeMem(GDVars.arena, SizeOf(Types.TArena));
  GDVars.arena := nil;
  Blit.FreePic(GDVars.movingIcon);
  CbtMap.SetNoncombatPalette;
  GDVars.spellServices.selectTargets := Magic.NoncombatCastTargetMenu
end;

procedure CombatMain;
var
  finished: Boolean;
  done: Boolean;
  cur: Types.PCharacter;
begin
  finished := False;
  GDVars.interfaceState := C_Ifc.IN_COMBAT;
  GDVars.spellServices.selectTargets := CbtActs.SelectCombatTargets;
  CbtActs.UseLeadership;
  CombatSt.CombatStart;
  done := False;
  if (GDVars.teamCount[C_Side.PLAYER] = 0) or (GDVars.teamCount[C_Side.ENEMY] = 0) then done := True;
  cur := GDVars.partyHead;
  while cur <> nil do begin
    FxEngine.TriggerEffectsWithCondition(24, cur);
    cur := cur^.next
  end;
  while not done do begin
    CharHlp.CountTeams;
    cur := GDVars.partyHead;
    while cur <> nil do begin
      CbtActs.BeginRound(cur);
      cur := cur^.next
    end;
    GDVars.zone1^.surprise[GDConsts.surpriseIndex + $7C00] := 0;
    Combat.OrderCreatures;
    cur := GDVars.combatOrder[1];
    GDVars.turnIndex := 1;
    while (cur <> nil) and not done do begin
      Combat.CreatureAction(cur);
      Inc(GDVars.turnIndex);
      if GDVars.turnIndex > 72 then cur := nil
      else cur := GDVars.combatOrder[GDVars.turnIndex];
      CharHlp.CountTeams;
      if (GDVars.teamCount[C_Side.PLAYER] = 0) or (GDVars.teamCount[C_Side.ENEMY] = 0) or
          (GDVars.roundNumber >= GDVars.roundLimit) then
        if not finished then begin
          done := True;
          finished := True
        end
    end;
    Combat.EndOfRound(done)
  end;
  if GDVars.agePassFlag <> 0 then Combat.AgingDeaths;
  Combat.CombatDoneCleanup;
  GDVars.slowText := 1
end;

{ After a fight in which someone aged: warns a member near its race's age limit, and one past it dies from age, with a
  witness line chosen by how many members can see. Note: the witness count is never zeroed first. }
procedure AgingDeaths;
var
  cur: Types.PCharacter;
  p: Types.PCharacter;
  witness: Types.PCharacter;
  isOld: Boolean;
  isWarning: Boolean;
  row: Byte;
  count: Byte;
  pronoun: String[4];
  message: String;
begin
  cur := GDVars.partyHead;
  while cur <> nil do begin
    if ShortInt(cur^.status) < C_Status.DEAD_STATUS then
      if cur^.combat^.notPcNpc <> 1 then with cur^ do begin
        isOld := False;
        isWarning := False;
        case race of
          C_Race.QUALINESTI_ELF, C_Race.SILVANESTI_ELF: if age > 1600 then isOld := True
              else if age > 1590 then isWarning := True;
          C_Race.HALF_ELF: if age > 325 then isOld := True
            else if age > 315 then isWarning := True;
          C_Race.MOUNTAIN_DWARF, C_Race.HILL_DWARF: if age > 525 then isOld := True
              else if age > 515 then isWarning := True;
          C_Race.KENDER: if age > 199 then isOld := True
            else if age > 189 then isWarning := True;
          C_Race.HUMAN: if age > 120 then isOld := True
            else if age > 110 then isWarning := True
        end;
        if isWarning then CharHlp.PrintCreatureMessage(cur, GDConsts.ageWarningMsg, 10, True);
        if isOld then begin
          row := 14;
          Border.ClearBox(23, row, 38, 21);
          TextRend.DisplayMessageWindow(23, row, 38, 21, White, Black, True, GDConsts.ageStrainMsg + name + '.  ');
          TextRend.DisplayAndPause(LightMagenta, Black, GDConsts.pressToContinue);
          Border.ClearBox(23, row, 38, 21);
          if gender = 0 then pronoun := GDConsts.heMsg else pronoun := GDConsts.sheMsg;
          TextRend.DisplayMessageWindow(23, row, 38, 21, White, Black, True, pronoun + GDConsts.lastBreathMsg);
          TextRend.DisplayAndPause(LightMagenta, Black, GDConsts.pressToContinue);
          Border.ClearBox(23, row, 38, 21);
          FxEngine.KillCreature(cur, C_Status.GONE, GDConsts.ageDeathMsg);
          p := GDVars.partyHead;
          while p <> nil do begin
            if (p^.enabled = 1) and (p^.status = C_Status.OKAY) and (p^.side <> C_Side.ENEMY) then begin
              Inc(count); witness := p
            end;
            p := p^.next
          end;
          case count of
            0: message := GDConsts.noWitnessMsg;
            1: message := witness^.name + GDConsts.oneWitnessMsg
          else
            message := GDConsts.manyWitnessMsg + name + GDConsts.bodySearchMsg
          end;
          Border.ClearBox(23, row, 38, 21);
          TextRend.DisplayMessageWindow(23, row, 38, 21, Yellow, Black, True, message);
          TextRend.DisplayAndPause(LightMagenta, Black, GDConsts.pressToContinue)
        end
      end;
    cur := cur^.next
  end;
  GDVars.agePassFlag := 0
end;

{ Insertion-sorts the combatants into the initiative queue by initiative, highest first; a tie goes either way on a coin
  flip, and an empty slot counts as initiative -1. Note: the insertion scan looks at the first 64 slots, while the shift
  that makes room runs to the end of the queue. }
procedure OrderCreatures;
var
  more: Boolean;
  cur: Types.PCharacter;
  saved: Types.PCharacter;
  nxt: Types.PCharacter;
  curInit: ShortInt;
  slotInit: ShortInt;
  i: Byte;
  j: Byte;
begin
  cur := GDVars.partyHead;
  FillChar(GDVars.combatOrder[1], SizeOf(GDVars.combatOrder), 0);
  while cur <> nil do begin
    i := 1;
    more := True;
    curInit := cur^.combat^.initiative;
    while (i < 65) and more do begin
      if GDVars.combatOrder[i] <> nil then
        slotInit := GDVars.combatOrder[i]^.combat^.initiative
      else slotInit := -1;
      if (curInit > slotInit) or ((curInit = slotInit) and (FxEngine.RollDice(1, 2) = 1)) then
        more := False
      else Inc(i)
    end;
    saved := GDVars.combatOrder[i];
    GDVars.combatOrder[i] := cur;
    if saved <> nil then begin
      j := i;
      more := True;
      while (j < 72) and more do begin
        Inc(j);
        nxt := GDVars.combatOrder[j];
        GDVars.combatOrder[j] := saved;
        saved := nxt;
        if nxt = nil then more := False
      end
    end;
    cur := cur^.next
  end
end;

{ Runs one creature's turn: resets its flanking counts and guard and fires its condition-7 effects. If it still has
  initiative (a finished turn's marker becomes 19), it becomes the current character, the map shows when it is friendly
  or a visible hostile, the view centers on it, its statistics are recalculated and shown, and its condition-15 effects
  fire (and its condition-21 effects when it is not casting). If initiative is still left, the AI (quick fight) or the
  player acts. Last, its cell is redrawn to erase the cursor.
  @param(cr The creature whose turn it is.) }
procedure CreatureAction(cr: Types.PCharacter);
var
  { Unused in this version; see the other implementations of this routine. }
  initiative: Word;
begin
  cr^.combat^.attacksTaken := 0;
  cr^.combat^.attackAngles := 0;
  cr^.combat^.guarding := 0;
  FxEngine.TriggerEffectsWithCondition(C_Cond.TURN_START, cr);
  if cr^.combat^.initiative > 0 then begin
    if cr^.combat^.initiative = 20 then
      cr^.combat^.initiative := 19;
    GDVars.currentCharacter := cr;
    GDVars.showTurn := Ord((cr^.side = C_Side.PLAYER) or CbtMap.CombatIconVisible(cr, 0));
    CbtMap.DisplayMapViewCentered(cr, 2, True);
    CharHlp.RecalcStats(cr);
    GDVars.combatInfoDirty := 1;
    CharHlp.CombatPrintCreatureInfo(cr);
    FxEngine.TriggerEffectsWithCondition(C_Cond.ACTION_START, cr);
    if cr^.combat^.spellCast = 0 then FxEngine.TriggerEffectsWithCondition(21, cr);
    if cr^.combat^.initiative > 0 then begin
      if cr^.quickFight <> 0 then
        CombatAi.CombatAiControl(Types.PCharacter(cr))
      else Combat.ManualControl(cr)
    end;
    CbtMap.RedrawArenaCell(CbtMap.CombatCellX(cr), CbtMap.CombatCellY(cr))
  end
end;

{ The command menu loop: a spell begun last turn is cast first; otherwise Move, Aim, Use, Cast, Turn (clerics, or
  paladins above level 2, while turns remain), Guard, Quick, Delay (to the end of the order), Bandage, Yell (kender),
  View, Speed and End, with extended keys for stopping quick-fight, toggling magic, ending the round for everyone and
  the gods' intervention.
  @param(cr Creature whose turn it is.) }
procedure ManualControl(cr: Types.PCharacter);
var
  key: Char;
  done: Boolean;
  p: Types.PCharacter;
  aimBuf: array[1..7] of Byte;
  spell: Byte;
  resultByte: Byte absolute done;
begin
  if cr^.enabled <> 0 then begin
    if cr^.combat^.spellCast > 0 then begin
      spell := cr^.combat^.spellCast;
      cr^.combat^.spellCast := 0;
      Magic.CastSpell(spell, 0, 1, resultByte);
      done := CharHlp.EndActions(cr)
    end else begin
      done := False;
      while not done do begin
        GDVars.selectedChoice := 1;
        Combat.CombatMenu(cr, key);
        if GDVars.menuExtendedKey = 0 then begin
          case key of
            #0: Combat.MoveMenu(cr, #255, done);
            #1: CbtActs.CombatAimMenu(cr, 255, GDConsts.attackAimMode, 0, 1, resultByte, aimBuf);
            #2: begin
                 GDVars.selectedChoice := 2;
                 ViewChar.UseItemMenu(done);
                 CbtActs.RecalcAttacksLeft(cr);
                 if not done then CharHlp.DisplayCombatInterface
               end;
            #3: CbtActs.CastSpellCombat(0, 0, done);
            #4: begin
                 if (cr^.classLevels[C_Class.CLERIC] > 0) or (cr^.classLevels[C_Class.PALADIN] > 2) then
                   if cr^.combat^.turnAttempts < GDVars.undeadCount then begin
                     CbtActs.CombatTurnUndead(cr);
                     done := CharHlp.EndActions(cr)
                   end
               end;
            #5: done := CharHlp.Guard(cr);
            #6: begin
                 Combat.ClearTarget(cr); MenuCore.ClearBottomLine; GameIo.FlushKeys;
                 Delay(200);
                 done := True; CombatAi.CombatAiControl(Types.PCharacter(cr))
               end;
            #7: begin
                 cr^.combat^.initiative := 1;
                 GDVars.loopIndex := GDVars.turnIndex;
                 p := GDVars.combatOrder[GDVars.loopIndex + 1];
                 while (p <> nil) and (GDVars.loopIndex < 72) do begin
                   GDVars.combatOrder[GDVars.loopIndex] := p;
                   Inc(GDVars.loopIndex);
                   p := GDVars.combatOrder[GDVars.loopIndex + 1]
                 end;
                 GDVars.combatOrder[GDVars.loopIndex] := cr;
                 Dec(GDVars.turnIndex); done := True
               end;
            #8: begin done := CharHlp.BandageDying(True); done := CharHlp.EndActions(cr) end;
            #9: begin FxEngine.YellTaunt(cr); done := CharHlp.EndActions(cr) end;
            #10: begin
                  ViewChar.ViewCharMenu(done); CbtActs.RecalcAttacksLeft(cr);
                  if not done then CharHlp.DisplayCombatInterface
                end;
            #11: Combat.SpeedMenu;
            #12: done := CharHlp.EndActions(cr)
          end
        end else begin
          case key of
            ' ': begin
                  p := GDVars.partyHead;
                  while p <> nil do begin
                    if p^.npc < C_Npc.NON_PLAYER then p^.quickFight := 0;
                    p := p^.next
                  end
                end;
            #50: begin
                   GDVars.magicOn := Ord(GDVars.magicOn = 0);
                   if GDVars.magicOn <> 0 then CharHlp.PrintBottomLine(GDConsts.magicOnMsg)
                   else CharHlp.PrintBottomLine(GDConsts.magicOffMsg)
                 end;
            #16, #30: begin
                   Dec(GDVars.turnIndex); cr^.combat^.initiative := 20;
                   p := GDVars.partyHead;
                   while p <> nil do begin Combat.ClearTarget(p); p := p^.next end;
                   MenuCore.ClearBottomLine; Delay(200); done := True
                 end;
            #45: if CbtActs.VictoryCheat then begin
                    CbtMap.DisplayMapViewCentered(cr, 3, False); done := True
                  end
          end
        end;
        if not done then begin
          CbtMap.DisplayMapViewCentered(cr, 2, True);
          GDVars.combatInfoDirty := 1; CharHlp.CombatPrintCreatureInfo(cr)
        end
      end
    end
  end else done := CharHlp.EndActions(cr)
end;

{ Enables the commands the creature can use now and waits for one, or one of the extended keys.
  @param(cr Creature whose turn it is.)
  @param(key Receives the command's index, or the extended key.) }
procedure CombatMenu(cr: Types.PCharacter; var key: Char);
var
  optionCount: Byte;
  i: Byte;
  flag: Boolean;
begin
  optionCount := 0;
  if cr^.combat^.movement > 0 then MenuCore.AppendChoice(0, optionCount);
  MenuCore.AppendChoice(1, optionCount);
  if cr^.numberOfItems > 0 then MenuCore.AppendChoice(2, optionCount);
  flag := False;
  if cr^.spells <> nil then
    for i := 0 to 73 do
      if (cr^.spells^.memorized[i] and $7F) > 0 then flag := True;
  if flag then
    if cr^.combat^.canCast <> 0 then
      if GDVars.zone0^.antiMagic = 0 then MenuCore.AppendChoice(3, optionCount);
  if (cr^.classLevels[C_Class.CLERIC] > 0) or (cr^.classLevels[C_Class.PALADIN] > 2) then
    if cr^.combat^.turnAttempts < GDVars.undeadCount then
      MenuCore.AppendChoice(4, optionCount);
  if not CharHlp.HasRangedWeapon(cr) or CharHlp.HasThrowableWeapon(cr) then
    MenuCore.AppendChoice(5, optionCount);
  MenuCore.AppendChoice(6, optionCount);
  MenuCore.AppendChoice(7, optionCount);
  if CharHlp.BandageDying(False) then MenuCore.AppendChoice(8, optionCount);
  if cr^.race = C_Race.KENDER then
    if GDVars.yellTarget = nil then MenuCore.AppendChoice(9, optionCount);
  for i := 10 to 12 do MenuCore.AppendChoice(i, optionCount);
  repeat
    key := Char(MenuCore.MenuHorizontal('', GDConsts.commandChoices, 1, 0));
    if GDVars.menuExtendedKey <> 0 then
      if not (key in [#16, #19, #30, ' ', #45, #50]) then key := #255
  until (Ord(key) < 13) or ((GDVars.menuExtendedKey <> 0) and (key in [#16, #19, #30, ' ', #45, #50]));
  Border.ClearBox(0, 23, 39, 24)
end;

{ Ends a round: advances the clock a minute, counts down the area effects, counts the round, refigures the hostiles'
  hit-point percentage, fires each creature's round-end (condition-19) effects and terrain effects, moves each dying
  creature a turn closer to death (dead once its count passes 9), warns when a party member is dying, counts the sides
  and rebuilds the view. The battle is done when a side is empty or the round limit is reached; when the party is left
  alone outside the demo, the player is asked whether to continue the battle.
  @param(done Set when the battle is over, and cleared when the player continues it; otherwise left as it was.) }
procedure EndOfRound(var done: Boolean);
var
  p: Types.PCharacter;
  { Unused in this version; see the other implementations of this routine. }
  status: Byte;
  n: Byte;
begin
  GameTime.AdvanceTime(1, 1);
  FxEngine.CountDownAreaEffects(False);
  Inc(GDVars.roundNumber);
  CbtActs.UpdateHostileHpPercent;
  p := GDVars.partyHead;
  n := 1;
  while p <> nil do begin
    FxEngine.TriggerEffectsWithCondition(C_Cond.ROUND_END, p);
    FxEngine.ConsiderTerrainEffects(p, 0);
    if p^.status = C_Status.DYING then begin
      Inc(p^.combat^.dyingTurns);
      if p^.combat^.dyingTurns > 9 then p^.status := C_Status.DEAD_STATUS
    end;
    Inc(n);
    p := p^.next
  end;
  if CharHlp.BandageDying(False) then CharHlp.PrintBottomLine(GDConsts.teammateDying);
  CharHlp.CountTeams;
  CbtMap.ScrollView(GDVars.arena^.ox + 3, GDVars.arena^.oy + 3, 255, C_Dir.CENTER);
  if (GDVars.teamCount[C_Side.PLAYER] = 0) or (GDVars.teamCount[C_Side.ENEMY] = 0) or
      (GDVars.roundNumber >= GDVars.roundLimit)
      then done := True;
  if (GDVars.teamCount[C_Side.PLAYER] > 0) and (GDVars.teamCount[C_Side.ENEMY] = 0) and
      (GDVars.demoMode = 0) then
    if Char(MenuCore.YesNoMenu(GDConsts.continueBattle, GDConsts.noKey)) = Chr(GDConsts.yesKey) then done := False
end;

{ The move menu: an arrow faces and steps -- attacking a creature there, offering flight off the arena, refusing what
  costs more than the movement left (cost x 2, x 3 diagonally), else taking attacks of opportunity and stepping; Escape
  puts the creature back where it started. Under 2 movement left counts as none.
  @param(cr Creature moving.)
  @param(key The first key to act on; 255 asks for one.)
  @param(done Set when the creature's turn is over.) }
procedure MoveMenu(cr: Types.PCharacter; key: Char; var done: Boolean);
var
  startMove: Byte;
  startFace: Byte;
  cellX: Byte;
  cellY: Byte;
  { Unused in this version; see the other implementations of this routine. }
  slot: Word;
  dir: Byte;
  crIdx: Byte;
  terrIdx: Byte;
  ch: Char;
  adjCorpse: Byte;
  adjWater: Byte;
  cost: Byte;

  { Puts the creature back where it started, with its movement and facing. }
  procedure UndoMove;
  begin
    cr^.combat^.movement := startMove;
    CbtMap.UpdateCombatMapTile(0, 0, CbtMap.CombatSlot(cr));
    done := not CbtMap.IsValidCreatureLoc(cr, cellX, cellY, False);
    CbtMap.ScrollView(CbtMap.CombatCellX(cr), CbtMap.CombatCellY(cr), 0, C_Dir.CENTER);
    cr^.combat^.direction := startFace;
    dir := C_Dir.CENTER
  end;
begin
  GDVars.inMoveMenu := 1;
  startMove := cr^.combat^.movement;
  startFace := cr^.combat^.direction;
  cellX := CbtMap.CombatCellX(cr);
  cellY := CbtMap.CombatCellY(cr);
  ch := key;
  done := False;
  dir := C_Dir.CENTER;
  repeat
    while (ch <> #0) and (ch <> C_Keys.ESCAPE) and not done do begin
      MenuCore.EnableChoices(0);
      Border.ClearBox(24, 24, 39, 24);
      if ch = #255 then
        ch := Char(MenuCore.MenuHorizontal(GDConsts.moveQueryLabel + CharHlp.ByteToString(cr^.combat^.movement div 2),
                                           GDConsts.moveChoices, 1, 0));
      dir := C_Dir.CENTER;
      if GDVars.menuExtendedKey <> 0 then
        case ch of
          C_Keys.ESCAPE: UndoMove;
          C_Keys.UP: dir := C_Dir.NORTH;
          C_Keys.PAGE_UP: dir := C_Dir.NORTHEAST;
          C_Keys.RIGHT: dir := C_Dir.EAST;
          C_Keys.PAGE_DOWN: dir := C_Dir.SOUTHEAST;
          C_Keys.DOWN: dir := C_Dir.SOUTH;
          C_Keys.END_KEY: dir := C_Dir.SOUTHWEST;
          C_Keys.LEFT: dir := C_Dir.WEST;
          C_Keys.HOME: dir := C_Dir.NORTHWEST
        end;
      if dir < C_Dir.CENTER then begin
        CbtMap.SetCreatureFacing(cr, dir, 0, 0);
        CbtMap.ProbeDirection(cr, dir, crIdx, terrIdx, adjCorpse, adjWater);
        if crIdx > 0 then Combat.MeleeAttack(cr, GDVars.creatures[crIdx], done)
        else if terrIdx = 0 then begin
          case Char(MenuCore.YesNoMenu(GDConsts.fleePrompt, GDConsts.noKey)) of
            #0: done := Boolean(CbtActs.AttemptFlee(cr));
            #1: done := False
          end
        end else begin
          if Odd(dir) then cost := GDConsts.terrain[terrIdx].cost * 3
          else cost := GDConsts.terrain[terrIdx].cost * 2;
          if GDConsts.terrain[terrIdx].cost = C_Terr.TERRAIN_IMPASSABLE then cost := C_Terr.TERRAIN_IMPASSABLE;
          if cost > cr^.combat^.movement then CharHlp.PrintBottomLine(GDConsts.cantGoThere)
          else begin
            CbtActs.AttacksOfOpportunity(cr, dir);
            if cr^.enabled = 0 then done := CharHlp.EndActions(cr)
            else begin
              if cr^.combat^.movement > 0 then CbtActs.CombatMoveCreature(cr, dir);
              if cr^.enabled = 0 then done := CharHlp.EndActions(cr);
              FxEngine.ConsiderTerrainEffects(cr, 1);
              if CharHlp.IsHelpless(cr) then done := CharHlp.EndActions(cr)
            end
          end
        end
      end;
      if (ch <> C_Keys.ESCAPE) or (GDVars.menuExtendedKey = 0) then
        if (GDVars.menuExtendedKey <> 0) or (ch <> #0) then ch := #255
    end
  until (ch <> #255) or done;
  if cr^.combat^.movement < 2 then cr^.combat^.movement := 0;
  GDVars.inMoveMenu := 0
end;

{ Makes MoveMenu's attack on a creature in the way, refused with a ranged weapon that cannot be thrown. Once an attack
  on an ally is confirmed, the target is locked, and a sweep is tried before a normal attack.
  @param(cr The attacker.)
  @param(foe The creature attacked.)
  @param(done Receives True when the attacker's actions are over; left as it was when the attack is refused.) }
procedure MeleeAttack(cr, foe: Types.PCharacter; var done: Boolean);
var resultByte: Byte absolute done;
begin
  if CharHlp.HasRangedWeapon(cr) and not CharHlp.HasThrowableWeapon(cr) then
    CharHlp.PrintBottomLine(GDConsts.notWithWeapon)
  else if CbtActs.CheckAttackAlly(cr, foe) then begin
    cr^.combat^.target := foe;
    if CbtActs.SweepAttack(cr, foe) then done := True
    else begin
      CbtActs.NoteAttackDirection(cr, foe);
      CbtActs.MakeAttack(cr, foe, 0, nil, resultByte)
    end
  end
end;

{ The Speed command: adjusts the game-speed setting, 0 to 9, until Exit. }
procedure SpeedMenu;
var
  query: String[40];
  optionCount: Byte;
  choice: ShortInt;
begin
  choice := -1;
  while choice <> 2 do begin
    query := GDConsts.gameSpeedLabel + '(' + CharHlp.ByteToString(GDVars.textDelay) + ') ';
    FillChar(GDVars.enabledChoices, SizeOf(GDVars.enabledChoices), $FF);
    optionCount := 0;
    if GDVars.textDelay > 0 then MenuCore.AppendChoice(0, optionCount);
    if GDVars.textDelay < 9 then MenuCore.AppendChoice(1, optionCount);
    MenuCore.AppendChoice(2, optionCount);
    choice := ShortInt(MenuCore.MenuHorizontal(query, GDConsts.speedChoices, 0, 0));
    case choice of
      0: Dec(GDVars.textDelay);
      1: Inc(GDVars.textDelay)
    end
  end
end;

{ Sets the creature to quick-fight and drops a target on its own side.
  @param(cr Creature to change.) }
procedure ClearTarget(cr: Types.PCharacter);
begin
  cr^.quickFight := 1;
  if cr^.combat^.target <> nil then
    if Types.PCharacter(cr^.combat^.target)^.side = cr^.side then
      cr^.combat^.target := nil
end;
begin
end.
