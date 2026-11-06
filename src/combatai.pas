{ CombatAi -- a turn under computer control, for monsters and for party members on quick-fight: morale, item use, spells
  and turning undead, then moving toward a target and attacking, and readying the best weapon and shield. }
{$O+,F+,S-,R-,V-,B-,I-}
unit CombatAi;
interface
uses C_Class, C_Cond, C_Dir, C_Effect, C_Npc, C_Side, C_Stat, C_Status, C_Terr, Crt, GDConsts, GDVars,
  Types, CharHlp, CbtActs, ViewChar, FxEngine, CbtMap, Magic, MenuCore, Pathing, TextRend, GameIo;

{ One turn under computer control: picks a target if there is none, reads a waiting key, rerolls the stance when it is
  outside 1..4 or on a 1 in 4 (1..4, or 5..6 one time in eight), checks morale, then uses an item, casts a spell begun
  earlier, turns undead or begins a spell -- the first that applies -- and otherwise readies its weapons and moves and
  attacks until the turn ends.
  @param(cr Creature whose turn it is.) }
procedure CombatAiControl(cr: Types.PCharacter);
implementation
const
  MOVE_TEXT = 'Move/Attack, Move Left = ';
  AI_DISPLAY_ON_TEXT = 'Magic On';
  AI_DISPLAY_OFF_TEXT = 'Magic Off';
  FORCED_FLEE_TEXT = 'is forced to flee';
  SURRENDER_TEXT = 'Surrenders';

function TurnUndeadAi(cr: Types.PCharacter): Boolean; forward;

function SelectItemToUse(cr: Types.PCharacter): Boolean; forward;

function SelectSpellToCast(cr: Types.PCharacter): Boolean; forward;

function AiMoveAttack(cr: Types.PCharacter): Boolean; forward;

function FinishRound(cr: Types.PCharacter): Boolean; forward;

function CheckKeystroke(cr: Types.PCharacter): Boolean; forward;

function CheckMorale(cr: Types.PCharacter): Boolean; forward;

procedure EquipWeaponAndArmor(cr: Types.PCharacter); forward;

procedure CombatAiControl(cr: Types.PCharacter);
var
  stance: Byte;
  done: Boolean;
  doneByte: Byte absolute done;
  { Unused in this version; see the other implementations of this routine. }
  discard: Boolean;
begin
  if cr^.combat^.target = nil then
    discard := CbtActs.AcquireTarget(cr, 255, 1, 0, 0);
  done := CombatAi.CheckKeystroke(cr);
  MenuCore.ClearBottomLine;
  CharHlp.ClearMessageWindow;
  if cr^.enabled = 0 then done := CharHlp.EndActions(cr);
  stance := cr^.combat^.aiStance;
  if (stance = 0) or (stance > 4) or (FxEngine.RollDice(1, 4) = 1) then begin
    stance := FxEngine.RollDice(1, 8);
    if stance = 8 then stance := FxEngine.RollDice(1, 2) + 4
    else stance := FxEngine.RollDice(1, 4)
  end;
  cr^.combat^.aiStance := stance;
  if not done then done := CombatAi.CheckMorale(cr);
  if (cr^.combat^.fleeing <> 0) and (cr^.combat^.panicked = 0) then
    CharHlp.PrintCreatureMessage(cr, 'flees in panic', 10, True);
  if done then Exit;
  if CombatAi.SelectItemToUse(cr) then done := CharHlp.EndActions(cr)
  else if cr^.combat^.spellCast > 0 then begin
    if cr^.combat^.target = nil then
      discard := CbtActs.AcquireTarget(cr, 255, 1, 1, 0);
    Magic.CastSpell(cr^.combat^.spellCast, 1, 1, doneByte);
    done := CharHlp.EndActions(cr)
  end else if CombatAi.TurnUndeadAi(cr) then done := CharHlp.EndActions(cr)
  else if CombatAi.SelectSpellToCast(cr) then done := True
  else begin
    CombatAi.EquipWeaponAndArmor(cr);
    done := CombatAi.CheckKeystroke(cr);
    while not done do
      if CbtActs.AcquireTarget(cr, 255, 1, 0, 0) and (cr^.combat^.initiative > 0) and (cr^.enabled <> 0) then
        done := CombatAi.AiMoveAttack(cr)
      else done := CombatAi.FinishRound(cr)
  end
end;

{ Turns undead when the creature is a cleric, or a paladin above level 2, with turns left and something to turn.
  @param(cr Creature acting.)
  @returns(True when it turned undead.) }
function TurnUndeadAi(cr: Types.PCharacter): Boolean;
var
  target: Types.PCharacter;
  best: ShortInt;
begin
  best := 13;
  if (cr^.combat^.turnAttempts < GDVars.undeadCount) and
      ((cr^.classLevels[C_Class.CLERIC] > 0) or (cr^.classLevels[C_Class.PALADIN] > 2)) and
      CbtActs.FindTurnUndeadTarget(cr, target, best) then begin
    TurnUndeadAi := True;
    CbtActs.CombatTurnUndead(cr)
  end else TurnUndeadAi := False
end;

{ Meant to pick an equipped magic item to use, but nothing ever sets chosen, so it always returns False.
  @param(cr Creature acting.)
  @returns(False.) }
function SelectItemToUse(cr: Types.PCharacter): Boolean;
var
  lowPriority: Byte;
  roll: Byte;
  i: Byte;
  { Unused in this version; see the other implementations of this routine. }
  itemCount: Integer;
  { Unused in this version; see the other implementations of this routine. }
  slot: Byte;
  effect: Byte;
  { Unused in this version; see the other implementations of this routine. }
  baseItem: Pointer;
  item: Types.PItem;
  chosen: Types.PItem;
  used: Boolean;
begin
  SelectItemToUse := False;
  chosen := nil;
  lowPriority := 7;
  roll := FxEngine.RollDice(1, 7);
  if (cr^.combat^.canUseItem <> 0) and (GDVars.teamCount[CharHlp.EnemyTeam(cr)] > 0) and
      (GDVars.zone0^.antiMagic = 0) then
    for i := 1 to roll do begin
      item := cr^.items;
      while (item <> nil) and (chosen = nil) do begin
        effect := item^.effect;
        slot := GDVars.baseItems[item^.itemType].slot;
        if (not Magic.ItemReadable(item)) and (item^.special < $80) and (item^.equipped <> 0) and (effect > 0) then
          if effect > 56 then effect := effect - 23;
        item := item^.next
      end;
      Dec(lowPriority)
    end;
  if chosen <> nil then begin
    ViewChar.UseItem(chosen, used);
    SelectItemToUse := True
  end
end;

{ Sorts the creature's memorized combat spells by AI priority, highest first, and returns the first one, repeats
  skipped, that RateSpell rates above 0. Note: the sort skips the first memorized slot.
  @param(cr The creature acting.)
  @param(spellCount Unused.)
  @returns(The spell, or 0 if none.) }
function PickCastableSpell(cr: Types.PCharacter; var spellCount: Byte): Byte;
var
  buffer: array[0..73] of Byte;
  position: Byte;
  lastSpell: Byte;
  valid: Byte;

  { Insertion-sorts the castable memorized spells into a buffer, highest AI priority first. }
  procedure SortCastableSpells;
  var
    value: Byte;
    temp: Byte;
    outer: Byte;
    inner: Byte;
    inserted: Boolean;
  begin
    for outer := 1 to 73 do begin
      value := cr^.spells^.memorized[outer];
      if (value > 0) and (value < $80) and (GDConsts.spellTable[value].combatOk <> 0) then begin
        inserted := False;
        inner := 0;
        repeat
          if buffer[inner] = 0 then begin
            buffer[inner] := value;
            inserted := True
          end else if GDConsts.spellTable[buffer[inner]].aiPriority >
            GDConsts.spellTable[value].aiPriority then Inc(inner)
          else begin
            repeat
              temp := buffer[inner];
              buffer[inner] := value;
              value := temp;
              Inc(inner)
            until (value = 0) or (inner > 73);
            inserted := True
          end
        until inserted
      end
    end
  end;

  { Advances to the next spell in the buffer that differs from lastSpell, or sets lastSpell to 0 at the end. }
  procedure NextDistinctSpell;
  var done: Boolean;
  begin
    done := False;
    repeat
      if buffer[position] = 0 then begin
        done := True;
        lastSpell := 0
      end else if buffer[position] <> lastSpell then begin
        lastSpell := buffer[position];
        done := True
      end else Inc(position)
    until done
  end;
begin
  PickCastableSpell := 0;
  FillChar(buffer, SizeOf(buffer), 0);
  SortCastableSpells;
  valid := 0;
  lastSpell := 0;
  position := 0;
  repeat
    NextDistinctSpell;
    if lastSpell <> 0 then
      valid := Byte(ShortInt(CbtActs.RateSpell(cr, lastSpell)) > 0)
  until (valid <> 0) or (lastSpell = 0);
  PickCastableSpell := lastSpell
end;

{ Begins PickCastableSpell's spell -- never under anti-magic, without spells or the ability to cast, or for a party
  member while magic is off -- when a d100 beats 4 x its fighter, knight, paladin and ranger levels and the spell's AI
  priority meets a d5.
  @param(cr Creature acting.)
  @returns(True when a spell was begun and the turn is over.) }
function SelectSpellToCast(cr: Types.PCharacter): Boolean;
var
  { Unused in this version; see the other implementations of this routine. }
  spellList: array[0..2] of Byte;
  spellCount: Byte;
  outcome: Boolean;
  spell: Byte;
  score: Byte;
begin
  SelectSpellToCast := False;
  if (GDVars.zone0^.antiMagic <> 0) or (cr^.spells = nil) or (cr^.combat^.canCast = 0) or
      ((cr^.npc < $7F) and (GDVars.magicOn = 0))
      then Exit;
  begin
    outcome := False;
    spell := CombatAi.PickCastableSpell(cr, spellCount);
    score := Byte(cr^.classLevels[C_Class.FIGHTER]) + Byte(cr^.classLevels[C_Class.KNIGHT]) +
      Byte(cr^.classLevels[C_Class.PALADIN]) + Byte(cr^.classLevels[C_Class.RANGER]);
    score := score * 4;
    if spell <> 0 then
      if FxEngine.RollDice(1, 100) > score then
        if GDConsts.spellTable[spell].aiPriority >= FxEngine.RollDice(1, 5) then
          CbtActs.CastSpellCombat(spell, 1, outcome);
    SelectSpellToCast := outcome
  end
end;

{ Checks a step in direction `baseDirection` plus the approach pattern's offset for `attempt`. Off the arena it sets
  `edge` and fails; an occupied or impassable cell fails. The step costs 2 (orthogonal) or 3 (diagonal) times the
  terrain cost and must be less than the movement left. Next to the first cloud kind ProbeDirection reports (a stinking
  cloud) the creature balks unless it has effect 32, 30, 99 or 63, is turned, or makes a saving throw; next to the
  second kind a creature below level 7 balks unless it has effect 99 or is turned.
  @param(cr The moving creature.)
  @param(attempt The attempt, 1..5, which picks the pattern's turn.)
  @param(baseDirection The wanted direction, 0..7.)
  @param(edge Set True when the step would leave the arena, else False.)
  @returns(True when the creature can take the step.) }
function AiCanStep(cr: Types.PCharacter; attempt, baseDirection: Byte; var edge: Boolean): Boolean;
var
  effect: Types.PEffect;
  directionOffset: Byte;
  direction: Byte;
  creatureIndex: Byte;
  terrainIndex: Byte;
  stepCost: Byte;
  adjacent1: Byte;
  adjacent2: Byte;
  ok: Boolean;
begin
  edge := False;
  ok := False;
  directionOffset := GDConsts.aiDirOffsets[cr^.combat^.aiStance, attempt];
  direction := (baseDirection + directionOffset) mod 8;
  CbtMap.ProbeDirection(Types.PCharacter(cr), direction, creatureIndex, terrainIndex, adjacent1, adjacent2);
  if terrainIndex = 0 then edge := True
  else begin
    if GDConsts.combatTables.terrain[terrainIndex].cost = C_Terr.TERRAIN_IMPASSABLE then begin
      AiCanStep := False;
      Exit
    end;
    if Odd(direction) then
      stepCost := GDConsts.combatTables.terrain[terrainIndex].cost * 3
    else stepCost := GDConsts.combatTables.terrain[terrainIndex].cost * 2;
    if creatureIndex = 0 then
      if stepCost < cr^.combat^.movement then begin
        if adjacent1 <> 0 then
          if (not CharHlp.HasEffect(cr, C_Effect.INVISIBLE_BY_FLAG, effect)) and
              (not CharHlp.HasEffect(cr, C_Effect.STINKING_COUGH, effect)) and
              (not CharHlp.HasEffect(cr, C_Effect.IMMUNE_POISON_HOLD, effect)) and
              (not CharHlp.HasEffect(cr, C_Effect.MINOR_GLOBE, effect)) and (cr^.combat^.panicked = 0) and
              (not FxEngine.RollSavingThrow(cr, 0, 0)) then
            stepCost := cr^.combat^.movement + 1;
        if adjacent2 <> 0 then
          if (cr^.levelHighest < 7) and (not CharHlp.HasEffect(cr, C_Effect.IMMUNE_POISON_HOLD, effect)) and
              (cr^.combat^.panicked = 0) then
            stepCost := cr^.combat^.movement + 1;
        if cr^.combat^.movement >= stepCost then ok := True
      end
  end;
  AiCanStep := ok
end;

{ One step: toward the target or, fleeing, away; up to five stance directions are tried, and a fleeing creature at the
  edge tries to flee the fight. Finding no step, or turning back on itself, counts as stuck -- the stance changes, the
  second time the target is dropped, the third ends the move. Then attacks of opportunity, the step and terrain effects.
  It moves only with movement and initiative left, and, unless fleeing, a weapon in slot 2 or a class other than mage.
  @param(cr Creature moving.) }
procedure AiMoveStep(cr: Types.PCharacter);
var
  direction: Byte;
  adjustedDirection: Byte;
  attempt: Byte;
  edge: Boolean;
  done: Boolean;
  { Unused in this version; see the other implementations of this routine. }
  combat: Pointer;
begin
  TextRend.DisplayString(0, 24, LightGreen, Black,
                         CombatAi.MOVE_TEXT + CharHlp.ByteToString(cr^.combat^.movement div 2) + ' ');
  if CombatAi.CheckKeystroke(cr) then Exit;
  if (cr^.combat^.movement div 2 > 0) and (cr^.combat^.initiative > 0) and
      ((cr^.npc < C_Npc.NON_PLAYER) or ((cr^.npc > $7F) and (GDVars.hostileHpPercent <= GDVars.moraleValue +
                                                FxEngine.RollDice(1, 100))) or
       (cr^.side = C_Side.ENEMY)) and
      ((cr^.combat^.fleeing <> 0) or (cr^.equipped[2] <> nil) or (cr^.characterClass <> C_Class.MAGE)) then begin
    if cr^.combat^.fleeing = 0 then
      direction := CharHlp.DirTowardTarget(cr, cr^.combat^.target)
    else begin
      cr^.combat^.aiStance := FxEngine.RollDice(1, 2);
      direction := GDVars.mapState.facing - ((GDVars.mapState.facing + 2) mod 4) div 2 + 1;
      if cr^.side = C_Side.PLAYER then direction := direction + 4;
      direction := direction mod 8
    end;
    edge := False;
    done := False;
    attempt := 1;
    while (attempt < 6) and (not done) and (not CombatAi.AiCanStep(cr, attempt, direction, edge)) do
      if (cr^.combat^.fleeing <> 0) and edge then
        done := Boolean(CbtActs.AttemptFlee(cr))
      else Inc(attempt);
    if done then begin
      cr^.combat^.movement := 0;
      cr^.combat^.fleeing := 0;
      done := CharHlp.EndActions(cr)
    end else begin
      if (attempt < 6) and (cr^.combat^.aiStance < 7) then
        adjustedDirection := (direction + GDConsts.aiDirOffsets[cr^.combat^.aiStance, attempt]) mod 8;
      if (attempt = 6) or (GDVars.lastMoveDirection = (adjustedDirection + 4) mod 8) then begin
        Inc(GDVars.stuckCount);
        cr^.combat^.aiStance := cr^.combat^.aiStance mod 6 + 1;
        if GDVars.stuckCount > 1 then begin
          cr^.combat^.target := nil;
          if GDVars.stuckCount > 2 then begin
            cr^.combat^.movement := 0;
            done := True
          end else if not CbtActs.AcquireTarget(cr, 255, 1, 0, 0) then
            done := CombatAi.FinishRound(cr)
        end
      end;
      if attempt < 6 then GDVars.lastMoveDirection := adjustedDirection
      else done := True
    end;
    if not done then begin
      GDVars.showTurn := Byte((GDVars.movementOption <> 0) or CbtMap.CombatIconVisible(Types.PCharacter(cr),
          0) or (cr^.side = C_Side.PLAYER));
      CbtMap.SetCreatureFacing(Types.PCharacter(cr), adjustedDirection, 0, 0);
      CbtActs.AttacksOfOpportunity(cr, cr^.combat^.direction);
      if cr^.enabled = 0 then done := CharHlp.EndActions(cr)
      else begin
        if cr^.combat^.movement > 0 then
          CbtActs.CombatMoveCreature(cr, cr^.combat^.direction);
        if (cr^.enabled = 0) or CharHlp.IsHelpless(cr) then
          done := CharHlp.EndActions(cr);
        FxEngine.ConsiderTerrainEffects(cr, 1)
      end
    end
  end else done := CombatAi.FinishRound(cr)
end;

{ Moves and attacks until the turn ends, at most 20 passes: a fleeing creature first spends its movement; a party member
  with someone to bandage stops; it attacks its target within weapon range along a clear line, else a random enemy in
  range, else moves toward one -- or rearms when a ranged weapon faces an adjacent enemy. True when the turn is over.
  @param(cr Creature acting.)
  @returns(True when the turn is over.) }
function AiMoveAttack(cr: Types.PCharacter): Boolean;
var
  done: Boolean;
  canAct: Boolean;
  weaponRange: Byte;
  distance: Word;
  count: Byte;
  pick: Byte;
  weapon: Pointer;
  weaponItem: Types.PItem absolute weapon;
  target: Types.PCharacter;
  targetCellX: ShortInt;
  targetCellY: ShortInt;
  loopCount: Byte;
begin
  GDVars.lastMoveDirection := C_Dir.CENTER;
  GDVars.stuckCount := 0;
  GDVars.aiInitByte := 0;
  loopCount := 0;
  canAct := True;
  done := False;
  FxEngine.TriggerEffectsWithCondition(C_Cond.MONSTER_SPECIAL, cr);
  if (cr^.side = C_Side.PLAYER) and CharHlp.BandageDying(True) then
    cr^.combat^.initiative := 0;
  if cr^.combat^.initiative = 0 then canAct := False;
  while (not done) and canAct do begin
    if cr^.combat^.fleeing <> 0 then
      while (cr^.combat^.movement > 0) and (cr^.combat^.initiative > 0) and
          (cr^.combat^.initiative < 20) do CombatAi.AiMoveStep(cr);
    if (cr^.combat^.initiative = 0) or (cr^.combat^.initiative = 20) then canAct := False
    else done := False;
    if (not done) and canAct then begin
      Inc(loopCount);
      if loopCount > 20 then begin
        done := True;
        canAct := CombatAi.FinishRound(cr) = False
      end;
      GDVars.movementOption := 0;
      weaponRange := 1;
      if cr^.equipped[0] <> nil then
        weaponRange := GDVars.baseItems[cr^.equipped[0]^.itemType].range;
      if (weaponRange = 0) or (weaponRange = 255) then weaponRange := 1;
      target := cr^.combat^.target;
      if (target^.enabled = 0) or (target^.side = C_Side.PLAYER) then target := nil;
      if target <> nil then
        if CbtActs.CanTarget(cr, target, 0) then begin
          targetCellX := CbtMap.CombatCellX(Types.PCharacter(target));
          targetCellY := CbtMap.CombatCellY(Types.PCharacter(target));
          distance := weaponRange;
          GDVars.arena^.distMode := 0;
          if Pathing.WalkLine(CbtMap.CombatCellX(Types.PCharacter(cr)), CbtMap.CombatCellY(Types.PCharacter(cr)),
                              targetCellX, targetCellY, distance, GDVars.arena) then
            if distance div 2 <= weaponRange then GDVars.movementOption := 1
        end;
      if GDVars.movementOption = 0 then begin
        count := CharHlp.CountTargets(cr, weaponRange, False);
        if count = 0 then begin
          if CbtActs.AcquireTarget(cr, 255, 0, 0, 0) then begin
            CombatAi.AiMoveStep(cr)
          end else done := CombatAi.FinishRound(cr)
        end else begin
          pick := FxEngine.RollDice(1, count);
          target := GDVars.creatures[GDVars.targetIndices[pick]];
          if CharHlp.HasRangedWeapon(cr) and (not CharHlp.HasThrowableWeapon(cr)) and
              (CharHlp.CountTargets(cr, 1, False) > 0) then begin
            CombatAi.EquipWeaponAndArmor(cr);
            done := True
          end else if (CharHlp.CalcDistance(cr, target) = 1) or
            CbtActs.CanTarget(cr, target, 0) then GDVars.movementOption := 1
        end
      end;
      if GDVars.movementOption <> 0 then
        CbtMap.ScrollView(CbtMap.CombatCellX(Types.PCharacter(cr)), CbtMap.CombatCellY(Types.PCharacter(cr)), 2,
                          CharHlp.DirTowardTarget(cr, target));
      if GDVars.movementOption <> 0 then begin
        if CbtActs.SweepAttack(cr, target) then done := CharHlp.EndActions(cr)
        else begin
          CbtActs.NoteAttackDirection(cr, target);
          weapon := nil;
          if CharHlp.HasRangedWeapon(cr) then begin
            GDVars.movementOption := Byte(CharHlp.FindDamagingRangedWeapon(cr, weaponItem));
            if CharHlp.HasThrowableWeapon(cr) then
              if CharHlp.CalcDistance(cr, target) = 1 then weapon := nil
          end;
          CbtActs.MakeAttack(cr, target, 0, weapon, Byte(done));
          if done then canAct := False
          else if target^.enabled = 0 then done := True
        end
      end
    end
  end;
  AiMoveAttack := canAct = False
end;

{ Ends the creature's round: a helpless, ranged-armed or out-of-initiative creature just ends its actions; others guard.
  @param(cr The creature.)
  @returns(What ending the actions or guarding returns.) }
function FinishRound(cr: Types.PCharacter): Boolean;
begin
  CharHlp.ClearMessageWindow;
  if CharHlp.IsHelpless(cr) or CharHlp.HasRangedWeapon(cr) or (cr^.combat^.initiative = 0) then
    FinishRound := CharHlp.EndActions(cr)
  else FinishRound := CharHlp.Guard(cr)
end;

{ Handles a key pressed during an AI turn: Alt-M toggles quick magic, space returns each creature that is neither a
  non-player character nor animated to manual control, and Alt-X tries the victory cheat. Pending keys are discarded
  afterwards. Note: the key is tested whether or not the extended-key prefix came first, so an unprefixed 2 also toggles
  quick magic and an unprefixed hyphen also tries the cheat.
  @param(cr The creature.)
  @returns(True when space put the creature itself back under manual control, which marks it to act again at once.) }
function CheckKeystroke(cr: Types.PCharacter): Boolean;
var
  scan: Types.PCharacter;
  key: Char;
begin
  CheckKeystroke := False;
  if GameIo.InputPending then begin
    key := GameIo.ReadGameKey;
    if key = #0 then key := GameIo.ReadGameKey;
    case key of
      '2': begin
        GDVars.magicOn := Ord(GDVars.magicOn = 0);
        if GDVars.magicOn <> 0 then CharHlp.PrintBottomLine(CombatAi.AI_DISPLAY_ON_TEXT)
        else CharHlp.PrintBottomLine(CombatAi.AI_DISPLAY_OFF_TEXT)
      end;
      ' ': begin
        scan := GDVars.partyHead;
        while scan <> nil do begin
          if (scan^.npc < C_Npc.NON_PLAYER) and (scan^.status <> C_Status.ANIMATED) then
            scan^.quickFight := 0;
          scan := scan^.next
        end;
        if cr^.quickFight = 0 then begin
          cr^.combat^.initiative := 20;
          CheckKeystroke := True
        end
      end;
      '-': if CbtActs.VictoryCheat then begin end
    end
  end;
  GameIo.FlushKeys
end;

{ Clears the creature's fleeing flag and AI effects, then checks a non-player character's morale (party characters never
  check; a turned creature is forced to flee). Morale is twice the low 7 bits of its non-player-character byte (0 above
  102), adjusted by condition-17 effects, and it holds when it is nonzero and covers the creature's own hit-point loss
  in percent. Failing that, a hostile still holds when the hostiles' remaining hit-point percentage, adjusted the same
  way, is nonzero and at least 100 less the zone's morale threshold. On a failure the creature flees if it is at least
  twice as fast as the fastest enemy; otherwise one with Intelligence above 5 surrenders.
  @param(cr The creature.)
  @returns(True on surrender.) }
function CheckMorale(cr: Types.PCharacter): Boolean;
var
  roll: Byte;
  { Unused in this version; see the other implementations of this routine. }
  savedMorale: Byte;
begin
  CheckMorale := False;
  cr^.combat^.fleeing := 0;
  FxEngine.RemoveAiEffects(cr);
  if cr^.combat^.panicked <> 0 then begin
    cr^.combat^.fleeing := 1;
    CharHlp.PrintCreatureMessage(cr, CombatAi.FORCED_FLEE_TEXT, 10, True)
  end else if cr^.npc > $7F then begin
    GDVars.moraleValue := (cr^.npc and C_Npc.MORALE_MASK) shl 1;
    if GDVars.moraleValue > 102 then GDVars.moraleValue := 0;
    FxEngine.TriggerEffectsWithCondition(C_Cond.MORALE_CHECK, cr);
    if (GDVars.moraleValue < 100 - (cr^.hitPoints * 100 div cr^.maxHitPoints)) or
        (GDVars.moraleValue = 0) then begin
      savedMorale := GDVars.moraleValue;
      GDVars.moraleValue := GDVars.hostileHpPercent;
      FxEngine.TriggerEffectsWithCondition(C_Cond.MORALE_CHECK, cr);
      if (GDVars.moraleValue < 100 - GDVars.zone1^.moraleBase[GDConsts.moraleBaseIndex + $7C00]) or
          (GDVars.moraleValue = 0) or
          (cr^.side = C_Side.PLAYER) then begin
        roll := CbtActs.HighestEnemyMovement(cr);
        if roll <= CharHlp.RecalcMovement(cr) div 2 then
          cr^.combat^.fleeing := 1
        else if cr^.stats[C_Stat.INTELLIGENCE].current > 5 then begin
          FxEngine.PutOutOfPlayWithStatus(cr, C_Status.UNCONSCIOUS, CombatAi.SURRENDER_TEXT);
          CheckMorale := CharHlp.EndActions(cr)
        end
      end
    end
  end
end;

{ Scores a weapon for EquipWeaponAndArmor: damage dice product, +8 per plus, +2 per damage bonus (holy water scores 8
  against an undead target), +2 per extra shot for a launcher, +3 one-handed. The score is zero when it would need more
  than 3 hands, for an aligned weapon of another alignment, for the Javelin of Lightning, and when cursed.
  @param(cr The creature that would wield the weapon.)
  @param(item The weapon.)
  @returns(The score.) }
function CalcWeaponPriority(cr: Types.PCharacter; item: Types.PItem): Byte;
var
  score: Byte;
  info: Types.TBaseItem;
begin
  info := GDVars.baseItems[item^.itemType];
  score := info.damageDice * info.damageRolls;
  if item^.plus > 0 then score := score + item^.plus * 8;
  if ShortInt(info.damageModifier) > 0 then score := score + ShortInt(info.damageModifier) * 2;
  if (item^.itemType = 54) and (cr^.combat^.target <> nil) then
    if ShortInt(Types.PCharacter(cr^.combat^.target)^.levelUndead) > 0 then score := 8;
  if info.flags and $08 > 0 then score := score + (info.rateOfFire - 1) * 2;
  if info.hands <= 1 then score := score + 3;
  if info.hands + cr^.handsEquipped > 3 then score := 0;
  if (item^.special = $84) and (item^.effect and $0F <> Byte(cr^.alignment)) then score := 0;
  if item^.effect = 83 then score := 0;
  if item^.cursed <> 0 then score := 0;
  CalcWeaponPriority := score
end;

{ Re-equips a creature with its best usable weapon (CalcWeaponPriority; its unarmed damage sets the bar for melee) and
  its best shield (plus + 1). The ranged pick wins when it scores above half the melee score, has ammunition, and is a
  true ranged weapon or no enemy is beside the creature. Cursed items are never swapped out; with too many hands in use
  the shield, or else the weapon, is unreadied. The creature's information is redrawn when anything changed.
  @param(cr The creature.) }
procedure EquipWeaponAndArmor(cr: Types.PCharacter);
var
  bestWeapon: Types.PItem;
  bestAlternative: Types.PItem;
  bestShield: Types.PItem;
  item: Types.PItem;
  selected: Types.PItem;
  bestWeaponScore: Byte;
  bestAlternativeScore: Byte;
  bestShieldScore: Byte;
  itemScore: Byte;
  itemType: Byte;
  flags: Byte;
  { Unused in this version; see the other implementations of this routine. }
  hands: Byte;
  validCurrent: Boolean;
  equipmentChanged: Boolean;
  specialWeapon: Boolean;
  selectionOk: Boolean;
begin
  if cr^.equipped[0] <> nil then
    cr^.handsEquipped := cr^.handsEquipped - GDVars.baseItems[cr^.equipped[0]^.itemType].hands;
  if cr^.equipped[1] <> nil then
    cr^.handsEquipped := cr^.handsEquipped - GDVars.baseItems[cr^.equipped[1]^.itemType].hands;
  bestWeapon := nil;
  bestAlternative := nil;
  bestShield := nil;
  bestWeaponScore := 1;
  bestAlternativeScore := cr^.unarmedDice[1] * cr^.unarmedRolls[1];
  if cr^.unarmedModifiers[1] > 0 then
    bestAlternativeScore := bestAlternativeScore + cr^.unarmedModifiers[1] * 2;
  bestShieldScore := 0;
  item := cr^.items;
  while item <> nil do begin
    itemType := item^.itemType;
    if (GDVars.baseItems[itemType].slot = 0) and
        (GDVars.baseItems[itemType].classMask and cr^.classMask <> 0) then begin
      itemScore := CombatAi.CalcWeaponPriority(cr, item);
      if ((GDVars.baseItems[itemType].flags and $08 <> 0) or (GDVars.baseItems[itemType].flags and $10 <> 0)) and
          (itemScore > bestWeaponScore) then begin
        bestWeapon := item;
        bestWeaponScore := itemScore
      end;
      if (GDVars.baseItems[itemType].flags and $08 = 0) and (itemScore > bestAlternativeScore) then begin
        bestAlternative := item;
        bestAlternativeScore := itemScore
      end
    end;
    if (GDVars.baseItems[itemType].slot = 1) and
        (GDVars.baseItems[itemType].classMask and cr^.classMask > 0) then begin
      if item^.plus >= 0 then itemScore := item^.plus + 1
      else itemScore := 0;
      if itemScore > bestShieldScore then begin
        bestShield := item;
        bestShieldScore := itemScore
      end
    end;
    item := item^.next
  end;
  if (bestWeapon <> nil) and (GDVars.baseItems[bestWeapon^.itemType].range > 1) and
      (GDVars.baseItems[bestWeapon^.itemType].flags and $14 = $14) then
    specialWeapon := True
  else specialWeapon := False;
  selectionOk := False;
  selected := nil;
  flags := 0;
  if bestWeapon <> nil then begin
    flags := GDVars.baseItems[bestWeapon^.itemType].flags;
    if flags and $10 <> 0 then selected := bestWeapon;
    if flags and $08 <> 0 then begin
      if flags and $01 <> 0 then selected := cr^.equipped[11];
      if flags and $80 <> 0 then selected := cr^.equipped[12]
    end
  end;
  if (selected <> nil) or (flags = $0A) then selectionOk := True;
  if (bestWeapon <> nil) and (bestWeaponScore > bestAlternativeScore div 2) and selectionOk and
      (specialWeapon or (CharHlp.CountTargets(cr, 1, False) = 0)) then
    item := bestWeapon
  else item := bestAlternative;
  equipmentChanged := False;
  validCurrent := True;
  if cr^.equipped[0] <> nil then
    if (cr^.equipped[0] = item) or (cr^.equipped[0]^.cursed <> 0) then
      validCurrent := False;
  if validCurrent then begin
    if cr^.equipped[0] <> nil then
      ViewChar.ToggleReadyItem(cr^.equipped[0]);
    CharHlp.RecalcStats(cr);
    if cr^.equipped[1] <> nil then
      if cr^.equipped[1]^.cursed = 0 then
        cr^.handsEquipped := cr^.handsEquipped - GDVars.baseItems[cr^.equipped[1]^.itemType].hands;
    if item <> nil then ViewChar.ToggleReadyItem(item);
    equipmentChanged := True
  end;
  CharHlp.RecalcStats(cr);
  CbtActs.RecalcAttacksLeft(cr);
  validCurrent := True;
  if cr^.equipped[1] <> nil then
    if (cr^.equipped[1] = bestShield) or (cr^.equipped[1]^.cursed <> 0) then validCurrent := False;
  if cr^.handsEquipped > 2 then begin
    if (cr^.equipped[1] = nil) or (cr^.equipped[1]^.cursed <> 0) then begin
      ViewChar.ToggleReadyItem(item);
      equipmentChanged := True
    end else begin
      ViewChar.ToggleReadyItem(cr^.equipped[1]);
      equipmentChanged := True
    end
  end else if (cr^.handsEquipped < 2) and validCurrent then begin
    if cr^.equipped[1] <> nil then
      ViewChar.ToggleReadyItem(cr^.equipped[1]);
    CharHlp.RecalcStats(cr);
    if bestShield <> nil then ViewChar.ToggleReadyItem(bestShield);
    equipmentChanged := True
  end;
  CharHlp.RecalcStats(cr);
  if equipmentChanged then CharHlp.CombatPrintCreatureInfo(cr)
end;
begin
end.
