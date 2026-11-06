{ The combat round's actions: a step and the free attacks that leaving a foe draws, melee and missile attacks with their
  sweeps and backstabs, turning undead, fleeing, aiming (the player's cursor and the AI's picks) and target selection
  for combat spells. A routine's attacker is the creature acting; its defender is the one hit. }
{$F+,O+,S-,R-,V-,B-,I-}
unit CbtActs;
interface
uses C_Class, C_Cond, C_Dir, C_Effect, C_Keys, C_Race, C_Side, C_Spell, C_Stat, C_Status, C_Terr, GDConsts, GDVars,
  Types, CharHlp, FxEngine, CbtMap, TextRend, Music, MenuCore, Pathing, Magic, Border, Crt, ViewChar, GameIo;

{ Readies a creature as a round starts: clears its spell, lets it cast unless it stands in a stinking cloud, gives it
  its attacks in both forms, rolls its initiative (d6 plus its dexterity missile adjustment, at least 1, 6 less when its
  side is surprised, 0 when out of range or disabled) and recalculates its movement.
  @param(creature The creature.) }
procedure BeginRound(creature: Types.PCharacter);

{ Moves a creature one step on the arena: spends the terrain's cost (times 2, times 3 diagonally; all its movement when
  that is more), moves its icon, scrolling the view for a quick-fighter, plays the step sound and lets guarding
  neighbors strike. A creature knocked down or left helpless loses its movement.
  @param(creature The creature.)
  @param(direction Direction of the step.) }
procedure CombatMoveCreature(creature: Types.PCharacter; direction: Byte);

{ Before a step, each adjacent foe the creature leaves behind -- not helpless, panicked or entangled, and not adjacent
  after the step -- attacks it once from behind, if it may target it, wields a melee or throwable weapon, and has
  initiative left, has not been attacked or faces the mover.
  @param(creature The creature about to step.)
  @param(direction Direction of the step.) }
procedure AttacksOfOpportunity(creature: Types.PCharacter; direction: Byte);

{ Tries to flee. It succeeds automatically with no enemy in the target list, and otherwise when the creature's movement
  in whole steps beats the fastest enemy's, or on 1 in 2 when they tie. Success takes the creature out of play as
  running, with 'Got Away'; failure prints 'Escape is blocked'. The creature's actions end either way.
  @param(creature The creature fleeing.)
  @returns(The result of ending its actions.) }
function AttemptFlee(creature: Types.PCharacter): Byte;

{ Sets a creature's current attacks for the round. It starts from the weapon's rate of fire (at least 2) when it has a
  ranged weapon with ammunition, else from its base attacks, both in half-attacks; applies its condition-18 effects and
  AttacksFromRate, and caps a ranged weapon by its ammunition. Once an attack has been made this round, the result only
  replaces the current attacks when it is lower.
  @param(creature The creature whose attacks are recalculated.) }
procedure RecalcAttacksLeft(creature: Types.PCharacter);

{ Sweeps level-0 enemies. When the defender is an adjacent level-0 enemy, the attacker's sweep budget exceeds its
  current attacks, and more adjacent level-0 enemies stand around it than it has current attacks, the attacker makes one
  attack on each of up to its sweep budget of them, the defender first.
  @param(character The creature attacking.)
  @param(foe The enemy chosen to attack.)
  @returns(True if the attacker swept.) }
function SweepAttack(character, foe: Types.PCharacter): Boolean;

{ Tells whether an attacker may target a creature: itself always; otherwise the target's and the attacker's veto effects
  may refuse, and a creature of its own side needs the ally flag.
  @param(attacker Creature targeting.)
  @param(target Creature targeted; nil is refused.)
  @param(allowAlly Nonzero to allow its own side.)
  @returns(True when it may.) }
function CanTarget(attacker, target: Types.PCharacter; allowAlly: Byte): Boolean;

{ The Turn command: a d20 against the turning table, the column from the cleric level (or paladin level less 2, two more
  for deity 2, the top levels folded into the last two columns, less the zone's column offset). The highest kind of
  undead in sight is tried first; one the roll beats is turned or destroyed, d12 creatures in all (d6 + 6 when
  destroyed), and a kind it fails lowers the cap. The turn ends.
  @param(creature Creature turning.) }
procedure CombatTurnUndead(creature: Types.PCharacter);

{ Finds the highest-level unturned undead in the target list (any range) at or below a level cap; equal levels keep the
  earlier one.
  @param(creature The creature turning undead.)
  @param(target Receives the undead found, or nil.)
  @param(levelCap The highest undead level allowed; receives the level found, or 0.)
  @returns(True if a target was found.) }
function FindTurnUndeadTarget(creature: Pointer; var target: Pointer; var levelCap: ShortInt): Boolean;

{ Records an attack on a defender for flanking: the defender's count of attackers goes up, and the angle between its
  facing and the attack's direction (0..4) is added to its spread, mod 8.
  @param(attacker The attacker.)
  @param(defender The defender.) }
procedure NoteAttackDirection(attacker, defender: Types.PCharacter);

{ Makes an attack, pushing the round limit 15 rounds on. Unless it comes from behind or the defender has already been
  attacked twice this round, the defender turns to face the attacker; otherwise, while the defender's icon is visible,
  an attack not from behind turns it around. The attacker turns toward the defender and takes it as its target, and
  missiles fly for the given weapon and for a readied weapon of type 28 or 29. If attacks remain, RollAttacks runs; the
  weapon then loses the primary attacks made from its quantity (not while a hoopak is readied), and once it is used up
  it is removed, an expended throwable weapon (other than a Spiritual Hammer) dropping into the treasure pile. Note: the
  readied weapon's type is read without checking that there is one.
  @param(attacker The creature attacking.)
  @param(defender The creature attacked.)
  @param(fromBehind Nonzero for an attack from behind: the defender keeps its facing.)
  @param(weapon The missile or thrown item, or nil for melee.)
  @param(done Set when the attacker's actions for the round are over.) }
procedure MakeAttack(attacker, defender: Types.PCharacter; fromBehind: Byte; weapon: Types.PItem; var done: Byte);

{ Builds the target list of a spell for the current caster, by the spell's area mode (the low nibble of its area byte):
  mode 0 is the caster alone; mode 5 a group picked one at a time until, from the second pick on, the creatures' weight
  exceeds a budget of 2d4, the weight counted by hit dice (for Faerie Fire by size, against a budget of the caster
  level); modes 8 to 14 everything within the radius (the area byte's low three bits) of a chosen point; mode 15 one
  creature, or everything within the radius (the area byte's high nibble) of a chosen point on the ground; any other
  mode the area byte's low two bits plus 1 separate creatures, never the same one twice, the Hold Person spells refusing
  the caster. A repeated pick is refused; for the computer it uses up a pick, or one point of the weight budget.
  @param(spellId The spell.)
  @param(aiMode Nonzero when the computer is choosing.)
  @param(outcome Receives False when nothing was targeted.) }
procedure SelectCombatTargets(spellId, aiMode: Byte; var outcome: Byte);

{ Picks (from the spell menu, when no spell is given) and checks a spell, rejecting those not allowed in combat ('Camp
  Only Spell'). A casting delay (the casting time div 3) of 0 casts it at once and ends the caster's actions; otherwise
  the caster 'Begins Casting': the spell is recorded as being cast, initiative drops by the delay (to at least 1), and
  the caster moves back in the combat order to its new initiative, a tie going either way on a 1d2, so it resolves on a
  later action. Note: after an immediate cast, the result is that of ending the caster's actions, whatever the cast
  itself reported.
  @param(spellId The spell to cast, or 0 to choose one from the menu.)
  @param(aiMode 0 redraws the combat screen first; passed on to the cast as its computer-controlled flag.)
  @param(outcome Set True when a spell was cast or begun, False otherwise.) }
procedure CastSpellCombat(spellId, aiMode: Byte; var outcome: Boolean);

{ Asks before attacking an ally unless the defender is an enemy or the attacker is on quick-fight; a yes sets the
  attacked-allies flags.
  @param(attacker Creature attacking.)
  @param(defender Creature attacked.)
  @returns(True when the attack goes ahead.) }
function CheckAttackAlly(attacker, defender: Types.PCharacter): Boolean;

{ The Aim command, and a spell's aim: Next and Prev step through the creatures the aimer may target, Manual walks a free
  cursor, Center centers the view and Exit or Escape leaves; Target takes the creature or cell, and for an attack
  ConfirmAttackTarget attacks it.
  @param(character Creature aiming.)
  @param(range Range allowed; 255 takes the readied weapon's.)
  @param(aimMode Attack or spell aim.)
  @param(emptyCellOk Non-zero when an empty cell may be taken.)
  @param(creatureOk Non-zero when a creature may be taken.)
  @param(done Set when a target was taken, and for an attack when the attack ends the turn.)
  @param(aim Receives the creature and cell taken.) }
procedure CombatAimMenu(character: Pointer; range, aimMode, emptyCellOk, creatureOk: Byte; var done: Byte; var aim);

{ Sets the hostiles' hit-point percentage: the enabled hostiles' current hit points as a percentage of the hostiles'
  combined maximum hit points, disabled ones included, rounded down to a multiple of five; it is left unchanged when
  there are no hostiles. Note: the totals are Words multiplied by 20, so above 3276 hit points the percentage wraps. }
procedure UpdateHostileHpPercent;

{ Finds the fastest enabled enemy's movement in whole steps, with no range or line-of-sight check.
  @param(creature The creature whose enemies are checked.)
  @returns(The highest enemy movement, in whole steps.) }
function HighestEnemyMovement(creature: Types.PCharacter): Byte;

{ Finds the computer's target: keeps the current one while it is an enabled enemy it may target, otherwise picks at
  random among those in range (the yell target first, for a creature under the yell), up to 20 tries. A second pass
  ignores terrain and, with anyReachable, takes whatever it finds.
  @param(character The creature.)
  @param(range Range to look in.)
  @param(anyReachable Non-zero to take any creature on the pass that ignores terrain.)
  @param(dropCurrent Non-zero to drop the current target first.)
  @param(allies Non-zero to look among its own side.)
  @returns(True when it has a target.) }
function AcquireTarget(character: Types.PCharacter; range, anyReachable, dropCurrent, allies: Byte): Boolean;

{ Debug victory: active when the second command-line parameter matches the debug password. Prints 'The Gods intervene!',
  kills each hostile, ends each creature's actions and rebuilds the view.
  @returns(True when the cheat ran.) }
function VictoryCheat: Boolean;

{ Rates a spell for the computer: the caster itself for a single-target spell, otherwise the creatures within the
  spell's range, nearest first, until one rates above 0. Each is judged against the caster's own side for a
  non-offensive spell and against its enemies otherwise.
  @param(character The caster.)
  @param(spellId The spell.)
  @returns(The score, above 0 when there is a worthwhile target.) }
function RateSpell(character: Types.PCharacter; spellId: Byte): Byte;

{ As a fight starts, NPCs of the party and the monsters go on quick-fight; then each knight of the party, conscious and
  not an NPC, may lead each NPC on quick-fight with intelligence above 3 -- on d100 under 20, 40 or 80 by order, plus 5
  a charisma point above 13 -- taking it off computer control. The first success is announced. }
procedure UseLeadership;
implementation
type
  { where an aim landed: the creature, if any, and the cell }
  TAimResult = record
    target: Pointer;
    x: Byte;
    y: Byte;
    yTail: Byte
  end;
  PByte = ^Byte;
  PLocalString = ^String;
  TMoveFrame = record
    baseYLead: Word;
    baseY: ShortInt;
    baseX: ShortInt;
    y: ShortInt;
    x: ShortInt;
    slot: Byte;
    cost: Byte
  end;
  TFreeAttackFrame = packed record
    { Unused in this version; see the other implementations of this routine. }
    leavingFoe: Byte;
    savedTarget: Pointer;
    attacker: Pointer;
    facingScan: Byte;
    phase: Byte;
    phasePos: Byte;
    index: Byte;
    scanPos: Byte;
    countAfter: Byte;
    candidateCount: Byte;
    { Unused in this version; see the other implementations of this routine. }
    count: Byte;
    slot: Byte;
    attacked: Byte;
    stillAdjacent: Byte;
    effect: Pointer;
    candidates: array[1..12] of Byte
  end;
  PArmorByFacing = ^TArmorByFacing;
  { a character read for its front and rear armor classes, indexed by the side attacked }
  TArmorByFacing = record
    armorClassLead: array[$00..$CB] of Byte;
    { armorClass, rearArmorClass }
    armorClass: array[0..1] of Byte
  end;
  TAimScoreGrid = array[-9..9, -9..9] of ShortInt;
  PAimScoreGrid = ^TAimScoreGrid;
  TAimBounds = packed record
    innerMinX: ShortInt;
    innerMinY: ShortInt;
    innerMaxX: ShortInt;
    innerMaxY: ShortInt;
    outerMinX: ShortInt;
    outerMinY: ShortInt;
    outerMaxX: ShortInt;
    outerMaxY: ShortInt
  end;
  TPickTargetFrame = packed record
    effect: Pointer;
    target: Pointer;
    retry: Byte;
    accepted: Byte;
    lastRetry: Byte;
    choice: Byte;
    attempts: Byte;
    count: Byte
  end;

procedure ManualAimCursor(character, target: Pointer; range, aimMode, emptyCellOk, creatureOk: Byte; var targetOk,
                          accepted: Byte; var aim; coordX, coordY: Byte); forward;

function AimAreaSpell(spellId: Byte; var aim): Byte; forward;

function RateSpellTarget(candidate: Types.PCharacter; spellId, team: Byte): ShortInt; forward;

function SelectSpellTarget(spellId, aiControlled, groundOk: Byte; var target): Boolean; forward;

function AimTargetMenu(character, target: Types.PCharacter; range, aimMode, emptyCellOk, creatureOk, targetOk, x,
                       y: Byte): Boolean; forward;

procedure ConfirmAttackTarget(character, target: Pointer; aiMode: Byte; var done: Byte; var aim); forward;

procedure AnimateMissile(attacker, defender, weapon: Pointer); forward;

procedure RollAttacks(attacker, defender: Pointer; fromBehind: Byte; done, thrown: Pointer); forward;

function AttacksFromRate(rate: Byte): Byte; forward;

function IsBackstab(attacker, defender: Types.PCharacter): Boolean; forward;

procedure ApplyRangePenalty(attacker, defender: Types.PCharacter; var armorClass: Byte); forward;

procedure BeginRound(creature: Types.PCharacter);
var
  { Unused in this version; see the other implementations of this routine. }
  i: Byte;
  cellIndex: Byte;
  inStinkingCloud: Byte;
  inCloudkill: Byte;
begin
  with Types.PCharacter(creature)^.combat^ do begin
    spellCast := 0;
    CbtMap.ProbeDirection(creature, C_Dir.CENTER, cellIndex, cellIndex, inStinkingCloud, inCloudkill);
    canCast := Byte(inStinkingCloud = 0);
    canUseItem := 1;
    attacked := 0;
    attackForm := 2;
    CbtActs.RecalcAttacksLeft(creature);
    GDVars.adjustedAttackRate := Types.PCharacter(creature)^.attackRate2;
    GDVars.attackInitByte := 0;
    FxEngine.TriggerEffectsWithCondition(C_Cond.MOVE_ATTACK_RATE, creature);
    Types.PCharacter(creature)^.attacksLeft[2] := CbtActs.AttacksFromRate(GDVars.adjustedAttackRate);
    if Types.PCharacter(creature)^.enabled <> 0 then begin
      initiative := FxEngine.RollDice(1, 6) + CharHlp.DexMissileAdjust(creature);
      if initiative < 1 then initiative := 1;
      if Byte(GDVars.zone1^.surprise[GDConsts.surpriseIndex + $7C00] and
              (Types.PCharacter(creature)^.side + 1)) <> 0 then
        Dec(initiative, 6);
      if (initiative < 0) or (initiative > 20) then initiative := 0
    end else
      initiative := 0
  end;
  Types.PCharacter(creature)^.combat^.movement := CharHlp.RecalcMovement(creature)
end;

{ Rolls the damage of one hit in an attack form into currentDamage: dice plus modifier (not below 0), after the
  attacker's and the defender's weapon-damage conditions; a backstab multiplies it by 2 + (thief level - 1) div 4.
  @param(attacker Creature attacking.)
  @param(defender Creature hit.)
  @param(phase Attack form, 1 or 2.) }
procedure CalcWeaponDamage(attacker, defender: Types.PCharacter; phase: Byte);
begin
  GDVars.currentDamage := Types.PCharacter(attacker)^.currentModifiers[phase] +
    FxEngine.RollDamageDice(Types.PCharacter(attacker)^.currentRolls[phase],
                            Types.PCharacter(attacker)^.currentDice[phase]);
  if GDVars.currentDamage < 0 then GDVars.currentDamage := 0;
  FxEngine.TriggerEffectsWithCondition(C_Cond.WEAPON_DAMAGE_ATTACKER, attacker);
  FxEngine.TriggerEffectsWithCondition(C_Cond.WEAPON_DAMAGE_DEFENDER, defender);
  if CbtActs.IsBackstab(attacker, defender) then
    GDVars.currentDamage := GDVars.currentDamage *
      (((Byte(Types.PCharacter(attacker)^.classLevels[C_Class.THIEF]) - 1) div 2 div 2) + 2);
  GDVars.elementMask := 0
end;

{ Reports one attack and applies its result. Damage interrupts a spell being cast. A creature that goes down is
  announced as dying or killed (unless bit 3 of its immunities is set), its hit-point effects run, and it is removed
  from the map. The hit or miss line is not printed for a defender that is already gone.
  @param(attacker The attacker.)
  @param(defender The defender.)
  @param(manner How the attack was made: 0 a normal attack, 1 from behind, 2 a backstab, 3 slaying a helpless creature.)
  @param(damage The damage inflicted.)
  @param(shownDamage The damage printed.)
  @param(isHit Set for a hit.) }
procedure ProcessAttackResult(attacker, defender: Types.PCharacter; manner, damage, shownDamage, isHit: Byte);
var row: Byte;
    message: String[80];
  { Unused in this version; see the other implementations of this routine. }
  isDone: Byte;
begin
  case manner of
    2: message := GDConsts.backstabsText;
    3: message := GDConsts.slaysHelplessText
  else
    message := GDConsts.attacksText
  end;
  CharHlp.PrintCreatureMessage(attacker, message, 10, False);
  row := 12;
  CharHlp.DisplayCreatureName(defender, 23, row, False);
  Inc(row);
  if manner = 1 then
    message := GDConsts.fromBehindText
  else
    message := '';
  if isHit <> 0 then begin
    if manner = 3 then
      message := 'with one cruel blow'
    else begin
      message := message + 'Hitting for ' + CharHlp.ByteToString(shownDamage);
      if shownDamage = 1 then
        message := message + GDConsts.damagePointText
      else
        message := message + GDConsts.damagePointsText;
      message := message + GDConsts.damageSuffix
    end;
    CharHlp.InflictDamage(defender, damage)
  end else
    message := message + GDConsts.missesText;
  if Types.PCharacter(defender)^.status <> C_Status.GONE then begin
    TextRend.DisplayMessageWindow(23, row, 38, row + 3, LightGreen, Black, True, message)
  end;
  row := GDVars.currentRow + 1;
  if damage > 0 then begin
    Types.PCharacter(defender)^.combat^.canCast := 0;
    if Types.PCharacter(defender)^.combat^.spellCast > 0 then begin
      TextRend.PauseOnly;
      CharHlp.PrintCreatureMessage(defender, GDConsts.lostSpellMessage, 12, True);
      CharHlp.RemoveSpell(defender, Types.PCharacter(defender)^.combat^.spellCast);
      isDone := Byte(CharHlp.EndActions(defender))
    end else
      TextRend.PauseOnly
  end else
    TextRend.PauseOnly;
  if Types.PCharacter(defender)^.enabled = 0 then begin
    CharHlp.PrintCreatureMessage(defender, GDConsts.goesDown, row, False);
    if (Types.PCharacter(defender)^.immunityFlags and $08) = 0 then begin
      Inc(row, 2);
      if Types.PCharacter(defender)^.status = C_Status.DYING then
        TextRend.DisplayString(23, row, LightGreen, Black, GDConsts.dyingSuffix);
      if Types.PCharacter(defender)^.status in
          [C_Status.DEAD_STATUS, C_Status.STONED, C_Status.GONE] then
        CharHlp.PrintCreatureMessage(defender, GDConsts.killedMessage, row, False);
      Inc(row, 2)
    end;
    FxEngine.RemoveEffectsHp0(defender);
    FxEngine.TriggerEffectsWithCondition(C_Cond.HIT_POINTS_ZERO, defender);
    if (Types.PCharacter(defender)^.enabled = 0) and (Types.PCharacter(defender)^.status <> 10) then
      CbtMap.CreatureDowned(defender)
    else
      TextRend.PauseOnly
  end;
  CharHlp.ClearMessageWindow
end;

{ Lets guarding enemies strike a creature that moved next to them: each adjacent enemy that is guarding and not helpless
  spends its guard on one free attack, while the mover stays up.
  @param(creature The creature that moved.) }
procedure GuardersAttack(creature: Types.PCharacter);
var
  count: Byte;
  index: Byte;
  guarder: Pointer;
  done: Byte;
begin
  count := CharHlp.CountTargets(creature, 1, False);
  for index := 1 to count do begin
    if Types.PCharacter(creature)^.enabled <> 0 then begin
      guarder := GDVars.creatures[GDVars.targetIndices[index]];
      if Types.PCharacter(guarder)^.combat^.guarding <> 0 then
        if not CharHlp.IsHelpless(guarder) then begin
          CbtMap.ScrollView(CbtMap.CombatCellX(creature), CbtMap.CombatCellY(creature), 2, C_Dir.CENTER);
          Types.PCharacter(guarder)^.combat^.guarding := 0;
          CbtActs.NoteAttackDirection(guarder, creature);
          CbtActs.MakeAttack(guarder, creature, 0, nil, done)
        end
    end
  end
end;

procedure CombatMoveCreature(creature: Types.PCharacter; direction: Byte);
var local: TMoveFrame;
begin
  local.slot := CbtMap.CombatSlot(creature);
  local.baseX := GDVars.arenaLoc[local.slot].x;
  local.baseY := GDVars.arenaLoc[local.slot].y;
  local.x := local.baseX + GDConsts.directionX[direction];
  local.y := local.baseY + GDConsts.directionY[direction];
  if Odd(direction) then
    local.cost := GDConsts.terrain[GDVars.arena^.cells[local.y, local.x]].cost * 3
  else
    local.cost := GDConsts.terrain[GDVars.arena^.cells[local.y, local.x]].cost * 2;
  if local.cost > Types.PCharacter(creature)^.combat^.movement then
    Types.PCharacter(creature)^.combat^.movement := 0
  else
    Dec(Types.PCharacter(creature)^.combat^.movement, local.cost);
  local.cost := 1;
  if Types.PCharacter(creature)^.quickFight <> 0 then begin
    local.cost := 3;
    if not CbtMap.ViewCoordsValid(local.x - GDVars.arena^.ox,
                                  local.y - GDVars.arena^.oy) then
      if GDVars.showTurn <> 0 then
        CbtMap.ScrollView(local.baseX, local.baseY, 2, C_Dir.CENTER)
  end;
  if GDVars.showTurn <> 0 then
    CbtMap.UpdateCombatMapTile(0, 0, local.slot);
  GDVars.arenaLoc[local.slot].x := local.x;
  GDVars.arenaLoc[local.slot].y := local.y;
  CbtMap.BuildArenaArrays;
  if GDVars.showTurn <> 0 then
    CbtMap.ScrollView(local.x, local.y, local.cost, C_Dir.CENTER);
  Types.PCharacter(creature)^.combat^.attacksTaken := 0;
  Types.PCharacter(creature)^.combat^.attackAngles := 0;
  Music.SendSoundCommand(GDConsts.stepSound);
  CbtActs.GuardersAttack(creature);
  if (Types.PCharacter(creature)^.enabled = 0) or CharHlp.IsHelpless(creature) then
    Types.PCharacter(creature)^.combat^.movement := 0
end;

procedure AttacksOfOpportunity(creature: Types.PCharacter; direction: Byte);
var local: TFreeAttackFrame;
begin
  local.leavingFoe := 0;
  FillChar(local.candidates, SizeOf(local.candidates), 0);
  local.slot := CbtMap.CombatSlot(creature);
  local.candidateCount := CharHlp.CountTargets(creature, 1, False);
  if local.candidateCount <> 0 then begin
    local.index := 1;
    for local.scanPos := 1 to local.candidateCount do begin
      if not CharHlp.IsHelpless(GDVars.creatures[GDVars.targetIndices[local.scanPos]]) then
        if Types.PCharacter(GDVars.creatures[GDVars.targetIndices[local.scanPos]])^.combat^.panicked = 0 then
          if not CharHlp.HasEffect(GDVars.creatures[GDVars.targetIndices[local.scanPos]], C_Effect.ENTANGLED,
                                   local.effect) then begin
            local.candidates[local.index] := GDVars.targetIndices[local.scanPos];
            Inc(local.index)
          end
    end;
    local.candidateCount := local.index - 1;
    Inc(GDVars.arenaLoc[local.slot].x, GDConsts.directionX[direction]);
    Inc(GDVars.arenaLoc[local.slot].y, GDConsts.directionY[direction]);
    local.countAfter := CharHlp.CountTargets(creature, 1, False);
    Dec(GDVars.arenaLoc[local.slot].x, GDConsts.directionX[direction]);
    Dec(GDVars.arenaLoc[local.slot].y, GDConsts.directionY[direction]);
    for local.index := 1 to local.candidateCount do begin
      local.stillAdjacent := 0;
      for local.scanPos := 1 to local.countAfter do
        if GDVars.targetIndices[local.scanPos] = local.candidates[local.index] then
          local.stillAdjacent := 1;
      if local.stillAdjacent <> 0 then
        local.candidates[local.index] := 0
    end;
    if Types.PCharacter(creature)^.side = C_Side.PLAYER then
      for local.index := 1 to local.candidateCount do
        if (local.candidates[local.index] > 0) and (Types.PCharacter(creature)^.enabled <> 0) then
          local.leavingFoe := 1;
    for local.index := 1 to local.candidateCount do
      if (local.candidates[local.index] > 0) and (Types.PCharacter(creature)^.enabled <> 0) then begin
        GDVars.combatInfoDirty := 1;
        GDVars.showTurn := 1;
        local.attacked := 0;
        local.attacker := GDVars.creatures[local.candidates[local.index]];
        if CbtActs.CanTarget(local.attacker, creature, 0) then
          if (not CharHlp.HasRangedWeapon(local.attacker)) or CharHlp.HasThrowableWeapon(local.attacker) then
            for local.facingScan := Types.PCharacter(local.attacker)^.combat^.direction + 6 to
                Types.PCharacter(local.attacker)^.combat^.direction + 10 do
              if local.attacked = 0 then
                if (Types.PCharacter(local.attacker)^.combat^.initiative > 0) or
                    (Types.PCharacter(local.attacker)^.combat^.attacksTaken = 0) or
                    Pathing.IsDirToward(CbtMap.CombatCellX(local.attacker), CbtMap.CombatCellY(local.attacker),
                                        CbtMap.CombatCellX(creature), CbtMap.CombatCellY(creature),
                                        local.facingScan mod 8) then begin
                  local.phase := 1;
                  if Types.PCharacter(local.attacker)^.attackRate = 0 then
                    local.phase := 2;
                  for local.phasePos := 1 to 2 do
                    if Types.PCharacter(local.attacker)^.
                         attacksLeft[local.phasePos] > 0 then
                      local.phase := local.phasePos;
                  if Types.PCharacter(local.attacker)^.
                       attacksLeft[local.phase] = 0 then
                    Types.PCharacter(local.attacker)^.
                      attacksLeft[local.phase] := 1;
                  Types.PCharacter(local.attacker)^.combat^.attackForm := local.phase;
                  local.savedTarget := Types.PCharacter(local.attacker)^.combat^.target;
                  CbtActs.MakeAttack(local.attacker, creature, 1, nil, GDVars.attackDone);
                  local.attacked := 1;
                  Types.PCharacter(local.attacker)^.combat^.target := local.savedTarget;
                  if Types.PCharacter(creature)^.enabled <> 0 then begin
                    GDVars.combatInfoDirty := 1;
                    CharHlp.CombatPrintCreatureInfo(creature)
                  end
                end
      end
  end
end;

function AttemptFlee(creature: Types.PCharacter): Byte;
var
  hasEscaped: Byte;
  enemyMove: Byte;
  creatureMove: Byte;
begin
  hasEscaped := 0;
  if CharHlp.CountTargets(creature, 255, False) = 0 then
    hasEscaped := 1
  else begin
    creatureMove := CharHlp.RecalcMovement(creature) div 2;
    enemyMove := CbtActs.HighestEnemyMovement(creature);
    if enemyMove < creatureMove then
      hasEscaped := 1
    else if (enemyMove = creatureMove) and (FxEngine.RollDice(1, 2) = 1) then
      hasEscaped := 1
  end;
  if hasEscaped <> 0 then
    FxEngine.PutOutOfPlayWithStatus(creature, C_Status.RUNNING, GDConsts.gotAwayText)
  else
    CharHlp.PrintBottomLine(GDConsts.escapeBlockedText);
  AttemptFlee := Byte(CharHlp.EndActions(creature))
end;

procedure RecalcAttacksLeft(creature: Types.PCharacter);
var
  attacks: Byte;
  previous: Byte;
  ammoLimit: Byte;
  rate: Byte;
  ranged: Byte;
  weapon: Types.PItem;
begin
  ranged := 0;
  previous := Types.PCharacter(creature)^.attacksLeft[1];
  Types.PCharacter(creature)^.attacksLeft[1] := Types.PCharacter(creature)^.attackRate;
  if CharHlp.HasRangedWeapon(creature) and CharHlp.FindDamagingRangedWeapon(creature, weapon) then begin
    ranged := 1;
    rate := GDVars.baseItems[Types.PCharacter(creature)^.equipped[0]^. itemType].rateOfFire;
    if rate < 2 then rate := 2;
    GDVars.adjustedAttackRate := rate
  end else
    GDVars.adjustedAttackRate := Types.PCharacter(creature)^.attacksLeft[1];
  GDVars.attackInitByte := 0;
  FxEngine.TriggerEffectsWithCondition(C_Cond.MOVE_ATTACK_RATE, creature);
  attacks := CbtActs.AttacksFromRate(GDVars.adjustedAttackRate);
  if (ranged <> 0) and (weapon <> nil) then begin
    ammoLimit := 1;
    if (weapon <> nil) and (weapon^.quantity > ammoLimit) then
      ammoLimit := weapon^.quantity;
    if (ammoLimit < attacks) and (weapon^.quantity > 0) then
      attacks := ammoLimit
  end;
  if (Types.PCharacter(creature)^.combat^.attacked = 0) or (attacks < previous) then
    Types.PCharacter(creature)^.attacksLeft[1] := attacks
  else
    Types.PCharacter(creature)^.attacksLeft[1] := previous
end;

{ Converts half-attacks to attacks: adds 1 on odd rounds, then halves.
  @param(rate The rate in half-attacks.)
  @returns(The whole attacks for this round.) }
function AttacksFromRate(rate: Byte): Byte;
var adjusted: Byte;
begin
  adjusted := rate;
  if Odd(GDVars.roundNumber) then Inc(adjusted);
  AttacksFromRate := adjusted div 2
end;

function SweepAttack(character, foe: Types.PCharacter): Boolean;
var
  count: Byte;
  available: Byte;
  index: Byte;
  sourceIndex: Byte;
  target: Pointer;
begin
  SweepAttack := False;
  if Types.PCharacter(character)^.attacksLeft[1] < Types.PCharacter(character)^.combat^.sweepTargets then
    if Types.PCharacter(foe)^.levelHighest = 0 then
      if CharHlp.CalcDistance(character, foe) = 1 then begin
        count := CharHlp.CountTargets(character, 1, False);
        available := 0;
        for index := 1 to count do begin
          target := GDVars.creatures[GDVars.targetIndices[index]];
          if target = foe then sourceIndex := index;
          if Types.PCharacter(target)^.levelHighest = 0 then Inc(available)
        end;
        if available > Types.PCharacter(character)^.attacksLeft[1] then begin
          if available > Types.PCharacter(character)^.combat^.sweepTargets then
            available := Types.PCharacter(character)^.combat^.sweepTargets;
          CharHlp.PrintCreatureMessage(character, GDConsts.sweepsText, 10, True);
          target := GDVars.creatures[GDVars.targetIndices[1]];
          if target <> foe then begin
            GDVars.targetIndices[sourceIndex] := GDVars.targetIndices[1];
            GDVars.targetIndices[1] := CbtMap.CombatSlot(foe)
          end;
          for index := 1 to count do
            if available > 0 then begin
              if Types.PCharacter(GDVars.creatures[GDVars.targetIndices[index]])^.levelHighest = 0 then begin
                target := GDVars.creatures[GDVars.targetIndices[index]];
                CbtActs.NoteAttackDirection(character, target);
                Types.PCharacter(character)^.attacksLeft[1] := 1;
                CbtActs.MakeAttack(character, target, 0, nil, GDVars.attackDone);
                Dec(available)
              end
            end;
          SweepAttack := True
        end
      end
end;

function CanTarget(attacker, target: Types.PCharacter; allowAlly: Byte): Boolean;
var
  savedCharacter: Pointer;
  savedTarget: Pointer;
begin
  CanTarget := False;
  if target <> nil then
    if attacker = target then
      CanTarget := True
    else begin
      GDVars.targetRefused := 0;
      savedCharacter := GDVars.currentCharacter;
      GDVars.currentCharacter := attacker;
      FxEngine.TriggerEffectsWithCondition(C_Cond.TARGET_VETO, target);
      GDVars.currentCharacter := savedCharacter;
      if (GDVars.targetRefused = 0) and
          ((Types.PCharacter(target)^.side <> Types.PCharacter(attacker)^.side) or (allowAlly <> 0)) then begin
        savedTarget := Types.PCharacter(attacker)^.combat^.target;
        Types.PCharacter(attacker)^.combat^.target := target;
        FxEngine.TriggerEffectsWithCondition(C_Cond.ATTACKER_VETO, attacker);
        Types.PCharacter(attacker)^.combat^.target := savedTarget
      end else
        GDVars.targetRefused := 1;
      CanTarget := GDVars.targetRefused = 0
    end
end;

procedure CombatTurnUndead(creature: Types.PCharacter);
var
  roll: Byte;
  affectedLeft: Byte;
  minimumLeft: Byte;
  needed: ShortInt;
  turnedAny: Byte;
  { Unused in this version; see the other implementations of this routine. }
  stop: Byte;
  target: Pointer;
  tableColumn: ShortInt;
  levelCap: ShortInt;
begin
  CharHlp.PrintCreatureMessage(creature, GDConsts.turnsUndeadText, 10, False);
  MenuCore.ClearBottomLine;
  TextRend.PauseOnly;
  turnedAny := 0;
  stop := 0;
  Inc(Types.PCharacter(creature)^.combat^.turnAttempts);
  levelCap := 13;
  minimumLeft := 6;
  roll := FxEngine.RollDice(1, 20);
  tableColumn := Types.PCharacter(creature)^.classLevels[C_Class.CLERIC];
  if Types.PCharacter(creature)^.classLevels[C_Class.PALADIN] - 2 > tableColumn then
    tableColumn := Types.PCharacter(creature)^.classLevels[C_Class.PALADIN] - 2;
  if Types.PCharacter(creature)^.deity = 2 then Inc(tableColumn, 2);
  if tableColumn > 8 then
    if tableColumn < 14 then tableColumn := 9 else tableColumn := 10;
  if GDVars.zone0^.columnOffset > tableColumn then
    tableColumn := 0
  else
    Dec(tableColumn, GDVars.zone0^.columnOffset);
  affectedLeft := 255;
  while CbtActs.FindTurnUndeadTarget(creature, target, levelCap) and (affectedLeft > 0) do begin
    needed := GDConsts.turnUndeadTable[ShortInt(Types.PCharacter(target)^.levelUndead), tableColumn];
    if affectedLeft = 255 then
      if needed < 0 then
        affectedLeft := FxEngine.RollDice(1, 6) + 6
      else
        affectedLeft := FxEngine.RollDice(1, 12);
    if roll >= Abs(needed) then begin
      turnedAny := 1;
      CbtMap.DisplayMapViewCentered(target, 3, False);
      GDVars.combatInfoDirty := 1;
      CharHlp.CombatPrintCreatureInfo(target);
      if needed > 0 then
        FxEngine.PutOutOfPlayWithStatus(target, C_Status.RUNNING, GDConsts.turnedText)
      else begin
        CharHlp.PrintCreatureMessage(target, GDConsts.destroyedText, 10, False);
        CbtMap.CreatureDowned(target);
        Types.PCharacter(target)^.status := C_Status.GONE;
        Types.PCharacter(target)^.enabled := 0
      end;
      if minimumLeft > 0 then Dec(minimumLeft);
      Dec(affectedLeft);
      if (affectedLeft = 0) and (minimumLeft > 0) and (needed < 0) then Inc(affectedLeft);
      CharHlp.ClearMessageWindow
    end else
      Dec(levelCap)
  end;
  if turnedAny = 0 then CharHlp.PrintBottomLine(GDConsts.nothingHappensText);
  CharHlp.CountTeams;
  GDVars.attackDone := Byte(CharHlp.EndActions(creature));
  CharHlp.ClearMessageWindow
end;

function FindTurnUndeadTarget(creature: Pointer; var target: Pointer; var levelCap: ShortInt): Boolean;
var
  count: Byte;
  index: Byte;
  bestLevel: ShortInt;
  candidate: Pointer;
begin
  bestLevel := 0;
  target := nil;
  count := CharHlp.CountTargets(creature, 255, False);
  FindTurnUndeadTarget := False;
  for index := 1 to count do begin
    candidate := GDVars.creatures[GDVars.targetIndices[index]];
    if Types.PCharacter(candidate)^.combat^.panicked = 0 then
      if ShortInt(Types.PCharacter(candidate)^.levelUndead) > 0 then
        if ShortInt(Types.PCharacter(candidate)^.levelUndead) > bestLevel then
          if ShortInt(Types.PCharacter(candidate)^.levelUndead) <= levelCap then begin
            bestLevel := Types.PCharacter(candidate)^.levelUndead;
            target := candidate;
            FindTurnUndeadTarget := True
          end
  end;
  levelCap := bestLevel
end;

{ Rolls every attack the attacker has left, second form first, against the defender's armor class -- the rear armor
  class less 4 for a backstab, the rear one from behind or when attacked from several sides -- with the range penalty;
  each hit deals CalcWeaponDamage's damage. A weapon uses its large-creature damage against a large defender, and a
  helpless defender is slain outright.
  @param(attacker Creature attacking.)
  @param(defender Creature attacked.)
  @param(fromBehind Non-zero for an attack from behind.)
  @param(done Set when the attacker has no attacks left and its turn is over.)
  @param(thrown Unused.) }
procedure RollAttacks(attacker, defender: Pointer; fromBehind: Byte; done, thrown: Pointer);
var weapon: Types.TBaseItem;
    acted: Byte;
    stopped: Byte;
    modeCopy: Byte;
    selected: Byte;
    index: Byte;
    count: Byte;
    phase: Byte;
    choice: ShortInt;
begin
  modeCopy := fromBehind;
  PByte(done)^ := 0;
  GDVars.hitsMade[1] := 0;
  GDVars.hitsMade[2] := 0;
  GDVars.attacksMade[1] := 0;
  GDVars.attacksMade[2] := 0;
  acted := 0;
  stopped := 0;
  GDVars.currentDamage := 0;
  Types.PCharacter(attacker)^.combat^.attacked := 1;
  if CharHlp.IsHelpless(defender) then begin
    Music.SendSoundCommand(GDConsts.hitSound);
    while Types.PCharacter(attacker)^.attacksLeft[Types.PCharacter(attacker)^.combat^.attackForm] = 0 do
      Dec(Types.PCharacter(attacker)^.combat^.attackForm);
    Inc(GDVars.attacksMade[Types.PCharacter(attacker)^.combat^.attackForm]);
    CbtActs.ProcessAttackResult(attacker, defender, 3, Types.PCharacter(defender)^.hitPoints + 5, 1, 1);
    FxEngine.RemoveInvisibility(attacker);
    for index := 1 to 2 do Types.PCharacter(attacker)^.attacksLeft[index] := 0;
    acted := 1;
    PByte(done)^ := 1
  end else begin
    if (Types.PCharacter(attacker)^.equipped[0] <> nil) and
        ((Types.PCharacter(defender)^.iconDimensions > $80) or ((Types.PCharacter(defender)^.iconDimensions and
                                                                    $07) > 1)) then begin
      weapon := GDVars.baseItems[Types.PCharacter(attacker)^.equipped[0]^.itemType];
      Types.PCharacter(attacker)^.currentRolls[1] := weapon.damageRollsLarge;
      Types.PCharacter(attacker)^.currentDice[1] := weapon.damageDiceLarge;
      Types.PCharacter(attacker)^.currentModifiers[1] := (Types.PCharacter(attacker)^.currentModifiers[1] -
                                                          ShortInt(weapon.damageModifier)) +
        ShortInt(weapon.damageModifierLarge)
    end;
    CharHlp.RecalcStats(defender);
    FxEngine.TriggerEffectsWithCondition(C_Cond.DEFENDER_ARMOR_CLASS, defender);
    choice := 0;
    if CbtActs.IsBackstab(attacker, defender) then
      selected := Types.PCharacter(defender)^.rearArmorClass - 4
    else begin
      if (Types.PCharacter(defender)^.combat^.attacksTaken > 1) and
          (CharHlp.DirTowardTarget(attacker, defender) = Types.PCharacter(defender)^.combat^.direction) and
          (Types.PCharacter(defender)^.combat^.attackAngles > 4)
      then
        modeCopy := 1;
      if modeCopy <> 0 then choice := 1;
      selected := PArmorByFacing(defender)^.armorClass[choice]
    end;
    CbtActs.ApplyRangePenalty(attacker, defender, selected);
    phase := 0;
    if modeCopy <> 0 then phase := 1;
    if CbtActs.IsBackstab(attacker, defender) then phase := 2;
    count := Types.PCharacter(attacker)^.combat^.attackForm;
    for index := count downto 1 do
      while (Types.PCharacter(attacker)^.attacksLeft[index] > 0) and (stopped = 0) do begin
        Dec(Types.PCharacter(attacker)^.attacksLeft[index]);
        Types.PCharacter(attacker)^.combat^.attackForm := index;
        Inc(GDVars.attacksMade[index]);
        if FxEngine.AttackRoll(attacker, defender, selected) or CharHlp.IsHelpless(defender) then begin
          Inc(GDVars.hitsMade[index]);
          Music.SendSoundCommand(GDConsts.hitSound);
          acted := 1;
          CbtActs.CalcWeaponDamage(attacker, defender, index);
          if Types.PCharacter(defender)^.enabled <> 0 then
            CbtActs.ProcessAttackResult(attacker, defender, phase, GDVars.currentDamage, GDVars.currentDamage, 1);
          if (Types.PCharacter(defender)^.enabled <> 0) and (GDVars.currentDamage > 0) then
            FxEngine.TriggerEffectsWithCondition(index + 1, attacker);
          if Types.PCharacter(defender)^.enabled = 0 then stopped := 1;
          if Types.PCharacter(attacker)^.enabled = 0 then begin
            count := 0;
            Types.PCharacter(attacker)^.attacksLeft[index] := 0
          end
        end
      end;
    if acted = 0 then begin
      Music.SendSoundCommand(GDConsts.damageSound);
      CbtActs.ProcessAttackResult(attacker, defender, phase, 0, 0, 0)
    end;
    PByte(done)^ := 1;
    for index := 1 to 2 do
      if Types.PCharacter(attacker)^.attacksLeft[index] > 0 then PByte(done)^ := 0;
    Types.PCharacter(attacker)^.combat^.sweepTargets := 0
  end;
  if Types.PCharacter(attacker)^.enabled = 0 then PByte(done)^ := 1;
  if PByte(done)^ <> 0 then PByte(done)^ := Byte(CharHlp.EndActions(attacker))
end;

procedure NoteAttackDirection(attacker, defender: Types.PCharacter);
var angle: Byte;
    attackDirection: Byte;
begin
  Inc(Types.PCharacter(defender)^.combat^.attacksTaken);
  attackDirection := CharHlp.DirTowardTarget(defender, attacker);
  angle := (attackDirection - Types.PCharacter(defender)^.combat^.direction + 8) mod 8;
  if angle > 4 then angle := 8 - angle;
  Types.PCharacter(defender)^.combat^.attackAngles := (Types.PCharacter(defender)^.combat^.attackAngles +
    angle) mod 8
end;

procedure MakeAttack(attacker, defender: Types.PCharacter; fromBehind: Byte; weapon: Types.PItem; var done: Byte);
var
  thrownCopy: Pointer;
  walker: Pointer;
  savedCharacter: Pointer;
  direction: Byte;
begin
  GDVars.showTurn := 1;
  GDVars.combatInfoDirty := 1;
  GDVars.roundLimit := GDVars.roundNumber + 15;
  if (Types.PCharacter(defender)^.combat^.attacksTaken < 2)
     and (fromBehind = 0) then begin
    direction := CharHlp.DirTowardTarget(defender, attacker);
    Types.PCharacter(defender)^.combat^.direction := (direction + 4) mod 8
  end else if CbtMap.CombatIconVisible(defender, 0) then begin
    direction := Types.PCharacter(defender)^.combat^.direction;
    if fromBehind = 0 then
      Types.PCharacter(defender)^.combat^.direction := (direction + 4) mod 8
  end;
  if CbtMap.CombatIconVisible(defender, 0) then
    CbtMap.SetCreatureFacing(defender, direction, 0, 0);
  direction := CharHlp.DirTowardTarget(attacker, defender);
  CharHlp.CombatPrintCreatureInfo(attacker);
  CbtMap.SetCreatureFacing(attacker, direction, 1, 0);
  Types.PCharacter(attacker)^.combat^.target := defender;
  Delay(100);
  if weapon <> nil then CbtActs.AnimateMissile(attacker, defender, weapon);
  if (Types.PCharacter(attacker)^.equipped[0]^.itemType = 28)
     or (Types.PCharacter(attacker)^.equipped[0]^.itemType = 29)
  then
    CbtActs.AnimateMissile(attacker, defender, Types.PCharacter(attacker)^.equipped[0]);
  done := 1;
  if (Types.PCharacter(attacker)^.attacksLeft[1] > 0) or
      (Types.PCharacter(attacker)^.attacksLeft[2] > 0) then begin
    savedCharacter := GDVars.currentCharacter;
    GDVars.currentCharacter := attacker;
    CbtActs.RollAttacks(attacker, defender, fromBehind, @done, weapon);
    if weapon <> nil then
      if not CharHlp.HasReadiedHoopak(attacker) then begin
        if Types.PItem(weapon)^.quantity > 0 then
          Dec(Types.PItem(weapon)^.quantity, GDVars.attacksMade[1]);
        if Types.PItem(weapon)^.quantity = 0 then
          if CharHlp.HasThrowableWeapon(attacker) and
              (Types.PItem(weapon)^.effect <> C_Effect.SPIRITUAL_HAMMER) then begin
            GetMem(thrownCopy, SizeOf(Types.TItem));
            Move(PByte(weapon)^, PByte(thrownCopy)^, SizeOf(Types.TItem));
            walker := GDVars.treasureItems;
            if walker = nil then begin
              GDVars.treasureItems := thrownCopy;
              Types.PItem(thrownCopy)^.next := nil
            end else begin
              while (Types.PItem(walker)^.next <> nil) and (walker <> GDVars.prevTreasure) do
                walker := Types.PItem(walker)^.next;
              Types.PItem(thrownCopy)^.next := Types.PItem(walker)^.next;
              Types.PItem(walker)^.next := thrownCopy
            end;
            Types.PItem(thrownCopy)^.equipped := 0;
            CharHlp.RemoveItem(attacker, Types.PItem(weapon));
            GDVars.prevTreasure := thrownCopy
          end else
            CharHlp.RemoveItem(attacker, Types.PItem(weapon))
      end;
    CharHlp.RecalcStats(attacker);
    GDVars.currentCharacter := savedCharacter
  end;
  if done <> 0 then
    done := Byte(CharHlp.EndActions(attacker));
  if CbtMap.CombatIconVisible(attacker, 0) then begin
    CbtMap.SetCreatureFacing(attacker, Types.PCharacter(attacker)^.combat^.direction, 1, 1);
    CbtMap.SetCreatureFacing(attacker, Types.PCharacter(attacker)^.combat^.direction, 0, 0)
  end
end;

{ Raises a defense value for range. With a ranged weapon the band is (range - 1) div 3 steps; a defender more than one
  band away adds 2 and more than two bands away 3 more. A weapon of range 3 or less has a band of 0, so any distance
  adds both. Melee adds nothing.
  @param(attacker The creature attacking.)
  @param(defender The creature attacked.)
  @param(armorClass The defense value, raised in place.) }
procedure ApplyRangePenalty(attacker, defender: Types.PCharacter; var armorClass: Byte);
var
  band: ShortInt;
  distance: ShortInt;
begin
  distance := CharHlp.CalcDistance(attacker, defender);
  if CharHlp.HasRangedWeapon(attacker) then
    band := (GDVars.baseItems[Types.PCharacter(attacker)^.equipped[0]^. itemType].range - 1) div 3
  else
    band := distance;
  if distance - band > 0 then begin
    distance := distance - band;
    armorClass := armorClass + 2
  end;
  if distance - band > 0 then begin
    distance := distance - band;
    armorClass := armorClass + 3
  end
end;

{ Chooses one target for a spell and moves the cast position to it. The player aims with the aim menu. The computer
  picks a creature, or for an area spell that may be aimed at the ground the best spot. On failure the target is
  cleared.
  @param(spellId The spell.)
  @param(aiControlled Nonzero when the computer is choosing.)
  @param(groundOk Nonzero allows an area spell to be aimed at the ground.)
  @param(target Receives the target.)
  @returns(True when a target was chosen.) }
function SelectSpellTarget(spellId, aiControlled, groundOk: Byte; var target): Boolean;
var found: Byte;
    acceptable: Byte;
    candidate: Pointer;
    { Unused in this version; see the other implementations of this routine. }
    i: Byte;
    creatureOk: Byte;
    team: Byte;

  { Picks the nearest suitable creature and accepts it when RateSpellTarget rates it above 0. }
  function PickSpellTarget: Boolean;
  var innerFound: Byte;
      tableFlag: Byte;
  begin
    innerFound := 0;
    acceptable := 1;
    tableFlag := Byte(GDConsts.spellTable[spellId].hostile = 0);
    if CbtActs.AcquireTarget(GDVars.currentCharacter, Magic.CalcSpellRange(spellId), 0, 1, tableFlag) then begin
      candidate := GDVars.currentCharacter^.combat^.target;
      if tableFlag <> 0 then
        team := Byte(GDVars.currentCharacter^.side)
      else
        team := Byte(CharHlp.EnemyTeam(GDVars.currentCharacter));
      acceptable := Byte(CbtActs.RateSpellTarget(candidate, spellId, team) > 0);
      if acceptable <> 0 then begin
        TAimResult(target).target := GDVars.currentCharacter^.combat^.target;
        TAimResult(target).x := CbtMap.CombatCellX(TAimResult(target).target);
        TAimResult(target).y := CbtMap.CombatCellY(TAimResult(target).target);
        innerFound := 1
      end
    end;
    PickSpellTarget := Boolean(innerFound)
  end;
begin
  found := 0;
  if aiControlled = 0 then begin
    creatureOk := Byte(spellId <> C_Spell.DIMENSION_DOOR);
    CbtActs.CombatAimMenu(GDVars.currentCharacter, Magic.CalcSpellRange(spellId), GDConsts.spellAimMode, groundOk,
                          creatureOk, found, target);
    GDVars.currentCharacter^.combat^.target := TAimResult(target).target
  end else begin
    if groundOk = 0 then
      found := Byte(PickSpellTarget)
    else if GDConsts.spellTable[spellId].targeting = 8 then
      found := Byte(PickSpellTarget)
    else
      found := CbtActs.AimAreaSpell(spellId, target)
  end;
  if found <> 0 then begin
    SelectSpellTarget := True;
    GDVars.targetX := TAimResult(target).x;
    GDVars.targetY := TAimResult(target).y
  end else begin
    SelectSpellTarget := False;
    FillChar(target, 7, 0)
  end
end;

procedure SelectCombatTargets(spellId, aiMode: Byte; var outcome: Byte);
var
  total: Byte;
  count: Byte;
  scanIndex: Byte;
  threshold: Byte;
  cost: Byte;
  { Unused in this version; see the other implementations of this routine. }
  candidateSlots: array[1..3] of Byte;
  target: Pointer;
  duplicateFlag: Byte;
  resultFlag: Byte;
begin
  FillChar(GDVars.spellTargetState.targets, SizeOf(GDVars.spellTargetState.targets), 0);
  outcome := 1;
  GDVars.spellTargetState.count := 0;
  GDVars.areaSpellActive := 0;
  GDVars.targetX := CbtMap.CombatCellX(GDVars.currentCharacter);
  GDVars.targetY := CbtMap.CombatCellY(GDVars.currentCharacter);
  case GDConsts.spellTable[spellId].targeting and $0F of
  0: begin
    GDVars.spellTargetState.targets[1] := GDVars.currentCharacter;
    GDVars.spellTargetState.count := 1
  end;
  5: begin
    cost := 0;
    count := 0;
    if spellId = C_Spell.FAERIE_FIRE then
      threshold := CharHlp.GetCasterLevel(C_Spell.FAERIE_FIRE)
    else
      threshold := FxEngine.RollDice(2, 4);
    resultFlag := 0;
    repeat
      if CbtActs.SelectSpellTarget(spellId, aiMode, 0, target) then begin
        duplicateFlag := 0;
        for scanIndex := 1 to count do
          if GDVars.spellTargetState.targets[scanIndex] = target then duplicateFlag := 1;
        if duplicateFlag = 0 then begin
          Inc(count);
          GDVars.spellTargetState.targets[count] := target;
          GDVars.targetX := CbtMap.CombatCellX(target);
          GDVars.targetY := CbtMap.CombatCellY(target);
          Inc(GDVars.spellTargetState.count);
          if spellId <> C_Spell.FAERIE_FIRE then
            case GDVars.spellTargetState.targets[count]^.levelHighest of
              0, 1: Inc(cost, 1);
              2: Inc(cost, 2);
              3: Inc(cost, 4)
              else Inc(cost, 8)
            end else
            case GDVars.spellTargetState.targets[count]^.iconDimensions of
              1: Inc(cost, 1);
              2, 3: Inc(cost, 2);
              4: Inc(cost, 4)
            end;
          if (count > 1) and (cost > threshold) then resultFlag := 1
        end else begin
          if aiMode <> 0 then
            Dec(threshold)
          else
            CharHlp.PrintBottomLine('Already been targeted')
        end;
        CbtMap.RedrawArenaCell(CbtMap.CombatCellX(target), CbtMap.CombatCellY(target))
      end else
        resultFlag := 1
    until (resultFlag <> 0) or (threshold = 0)
  end;
  8..14: begin
    if CbtActs.SelectSpellTarget(spellId, aiMode, 1, target) then begin
      Pathing.BuildTargetList(GDVars.targetX, GDVars.targetY, GDConsts.spellTable[spellId].targeting and $07,
                              GDConsts.anyDirection, 1, GDVars.arena);
      for count := 1 to GDVars.targetCount do
        GDVars.spellTargetState.targets[count] := GDVars.creatures[GDVars.targetList[count].characterIndex];
      GDVars.spellTargetState.count := GDVars.targetCount;
      GDVars.areaSpellActive := 1
    end else
      outcome := 0
  end;
  15: begin
    if CbtActs.SelectSpellTarget(spellId, aiMode, 0, target) then begin
      if GDVars.currentCharacter^.combat^.target <> nil then begin
        GDVars.spellTargetState.targets[1] := GDVars.currentCharacter^.combat^.target;
        GDVars.spellTargetState.count := 1
      end else begin
        Pathing.BuildTargetList(GDVars.targetX, GDVars.targetY, GDConsts.spellTable[spellId].targeting shr 4,
                                GDConsts.anyDirection, 1, GDVars.arena);
        for count := 1 to GDVars.targetCount do
          GDVars.spellTargetState.targets[count] := GDVars.creatures[GDVars.targetList[count].characterIndex];
        GDVars.spellTargetState.count := GDVars.targetCount;
        GDVars.areaSpellActive := 1
      end
    end else
      outcome := 0
  end;
  else begin
    total := (GDConsts.spellTable[spellId].targeting and $03) + 1;
    count := 0;
    while total > 0 do begin
      if CbtActs.SelectSpellTarget(spellId, aiMode, 0, target) then begin
        duplicateFlag := 0;
        for scanIndex := 1 to count do
          if GDVars.spellTargetState.targets[scanIndex] = target then duplicateFlag := 1;
        if (spellId = C_Spell.HOLD_PERSON_CLERIC) or (spellId = C_Spell.HOLD_PERSON_MAGE) then
          if target = GDVars.currentCharacter then duplicateFlag := 1;
        if duplicateFlag = 0 then begin
          Inc(count);
          GDVars.spellTargetState.targets[count] := target;
          Dec(total);
          GDVars.targetX := CbtMap.CombatCellX(target);
          GDVars.targetY := CbtMap.CombatCellY(target)
        end else begin
          if aiMode = 0 then begin
            if target = GDVars.currentCharacter then
              CharHlp.PrintBottomLine('Cannot target yourself')
            else
              CharHlp.PrintBottomLine('Already been targeted')
          end else
            Dec(total)
        end;
        CbtMap.RedrawArenaCell(CbtMap.CombatCellX(target), CbtMap.CombatCellY(target))
      end else
        total := 0
    end;
    GDVars.spellTargetState.count := count;
    if count = 0 then
      outcome := 0
    else begin
      GDVars.targetX := CbtMap.CombatCellX(GDVars.spellTargetState.targets[count]);
      GDVars.targetY := CbtMap.CombatCellY(GDVars.spellTargetState.targets[count])
    end
  end
  end
end;

procedure CastSpellCombat(spellId, aiMode: Byte; var outcome: Boolean);
var kindLocal: Byte;
    outcomeByte: Byte absolute outcome;
    { Unused in this version; see the other implementations of this routine. }
    spellLevel: Byte;
    remainder: Byte;
    scanIndex: Byte;
    wordOut: Word;
    byteOut: Byte;
    spellIndex: Integer absolute wordOut;
    hasSpells: Boolean absolute byteOut;
    current: Pointer;
    entryPointer: Pointer;
begin
  current := GDVars.currentCharacter;
  byteOut := 1;
  wordOut := 65535;
  outcome := False;
  kindLocal := spellId;
  if kindLocal = 0 then
    kindLocal := ViewChar.SpellMenu(0, 1, spellIndex, hasSpells);
  if kindLocal > 0 then
    if GDConsts.spellTable[kindLocal].combatOk = 0 then begin
      CharHlp.PrintBottomLine('Camp Only Spell');
      kindLocal := 0
    end;
  if aiMode = 0 then begin
    CharHlp.DisplayCombatInterface;
    GDVars.showTurn := 1;
    GDVars.combatInfoDirty := 1;
    CbtMap.DisplayMapViewCentered(current, 3, True);
    CharHlp.CombatPrintCreatureInfo(current)
  end;
  if kindLocal > 0 then begin
    remainder := GDConsts.spellTable[kindLocal].castingTime div 3;
    if remainder = 0 then begin
      Magic.CastSpell(kindLocal, aiMode, 1, outcomeByte);
      outcome := CharHlp.EndActions(current)
    end else begin
      outcome := True;
      CharHlp.PrintCreatureMessage(current, 'Begins Casting', 10, True);
      Types.PCharacter(current)^.combat^.spellCast := kindLocal;
      if Types.PCharacter(current)^.combat^.initiative > remainder then
        Dec(Types.PCharacter(current)^.combat^.initiative, remainder)
      else
        Types.PCharacter(current)^.combat^.initiative := 1;
      scanIndex := GDVars.turnIndex;
      entryPointer := GDVars.combatOrder[scanIndex + 1];
      while (entryPointer <> nil) and
          ((Types.PCharacter(entryPointer)^.combat^.initiative > Types.PCharacter(current)^.combat^.initiative) or
           ((Types.PCharacter(entryPointer)^.combat^.initiative =
             Types.PCharacter(current)^.combat^.initiative) and (FxEngine.RollDice(1, 2) = 1))) do begin
        GDVars.combatOrder[scanIndex] := entryPointer;
        Inc(scanIndex);
        entryPointer := GDVars.combatOrder[scanIndex + 1]
      end;
      GDVars.combatOrder[scanIndex] := current;
      Dec(GDVars.turnIndex);
      outcome := True
    end
  end
end;

{ Tells whether an attack is a backstab: a thief with no weapon or a small blade (item types 3, 4, 17..19, 67), next to
  a defender of icon size 1 that has been attacked more than once, striking from behind it.
  @param(attacker Creature attacking.)
  @param(defender Creature attacked.)
  @returns(True for a backstab.) }
function IsBackstab(attacker, defender: Types.PCharacter): Boolean;
var
  weapon: Pointer;
  { Unused in this version; see the other implementations of this routine. }
  armor: Pointer;
  weaponType: Byte;
  canBackstab: Boolean;
begin
  canBackstab := False;
  weapon := Types.PCharacter(attacker)^.equipped[0];
  if weapon <> nil then
    weaponType := Types.PItem(weapon)^.itemType;
  armor := Types.PCharacter(attacker)^.equipped[2];
  if Types.PCharacter(attacker)^.classLevels[C_Class.THIEF] > 0 then
    if (weapon = nil) or (weaponType = 67) or (weaponType = 3) or (weaponType = 4) or
        ((weaponType > 16) and (weaponType < 20)) then
      canBackstab := True;
  if canBackstab and (Types.PCharacter(defender)^.combat^.attacksTaken > 1) and
      (CharHlp.CalcDistance(attacker, defender) < 2) and
      ((Types.PCharacter(defender)^.iconDimensions and $7F) <= 1) and
      (CharHlp.DirTowardTarget(attacker, defender) = Types.PCharacter(defender)^.combat^.direction) then
    IsBackstab := True
  else
    IsBackstab := False
end;

{ Flies a missile's icon from the attacker to the defender with its sound, the icon and pace by the weapon's item type:
  arrows and bolts drawn by direction, spinning icons for the thrown weapons.
  @param(attacker Creature shooting.)
  @param(defender Creature shot at.)
  @param(weapon The missile or thrown weapon.) }
procedure AnimateMissile(attacker, defender, weapon: Pointer);
var
  frames: Byte;
  direction: Byte;
  pace: Byte;
  { Unused in this version; see the other implementations of this routine. }
  imageSize: Word;
begin
  Music.SendSoundCommand(GDConsts.missileSound);
  direction := CharHlp.DirTowardTarget(attacker, defender);
  frames := 1;
  pace := 10;
  imageSize := GDVars.movingIcon^.imgSize;
  case Types.PItem(weapon)^.itemType of
    5, 7, 12, 30, 66: begin
      if Odd(direction) then
        if (direction = C_Dir.SOUTHEAST) or (direction = C_Dir.SOUTHWEST) then
          CharHlp.CopyIconFacing(14, 1, 0, direction = C_Dir.SOUTHWEST)
        else
          CharHlp.CopyIconFacing(14, 0, 0, direction = C_Dir.NORTHWEST)
      else
        CharHlp.CopyIconFacing((direction mod 4) + 13, direction div 4, 0, False);
      Music.SendSoundCommand(GDConsts.missileSound)
    end;
    2, 3, 6: begin
      CharHlp.BuildIconFacings(16);
      frames := 4;
      pace := 50;
      Music.SendSoundCommand(GDConsts.damageSound)
    end;
    54, 55: begin
      CharHlp.BuildIconFacings(17);
      frames := 4;
      pace := 50;
      Music.SendSoundCommand(GDConsts.missileSound2)
    end;
    28, 29, 67: begin
      CharHlp.CopyIconFacing(21, 0, 0, False);
      CharHlp.CopyIconFacing(21, 1, 1, False);
      frames := 2;
      pace := 10;
      Music.SendSoundCommand(GDConsts.missileSound2)
    end;
    else begin
      CharHlp.CopyIconFacing(20, 0, 0, False);
      CharHlp.CopyIconFacing(20, 1, 1, False);
      frames := 2;
      pace := 20;
      Music.SendSoundCommand(GDConsts.damageSound)
    end
  end;
  CharHlp.CombatAnimateMovingIcon(ShortInt(CbtMap.CombatCellX(attacker)), ShortInt(CbtMap.CombatCellY(attacker)),
                                  ShortInt(CbtMap.CombatCellX(defender)), ShortInt(CbtMap.CombatCellY(defender)),
                                  frames, pace)
end;

procedure UpdateHostileHpPercent;
var
  maximumTotal: Word;
  hitPointTotal: Word;
  combatant: Pointer;
begin
  maximumTotal := 0;
  hitPointTotal := 0;
  combatant := GDVars.partyHead;
  while combatant <> nil do begin
    if Byte(Types.PCharacter(combatant)^.side) = 1 then begin
      if Types.PCharacter(combatant)^.enabled <> 0 then
        hitPointTotal := hitPointTotal + Types.PCharacter(combatant)^.hitPoints;
      maximumTotal := maximumTotal + Types.PCharacter(combatant)^.maxHitPoints
    end;
    combatant := Types.PCharacter(combatant)^.next
  end;
  if maximumTotal > 0 then
    GDVars.hostileHpPercent := ((20 * hitPointTotal) div maximumTotal) * 5
end;

function HighestEnemyMovement(creature: Types.PCharacter): Byte;
var
  highest: Byte;
  movement: Byte;
  combatant: Pointer;
begin
  highest := 0;
  combatant := GDVars.partyHead;
  while combatant <> nil do begin
    if (Byte(CharHlp.EnemyTeam(creature)) = Byte(Types.PCharacter(combatant)^.side)) and
        (Types.PCharacter(combatant)^.enabled <> 0) then begin
      movement := CharHlp.RecalcMovement(combatant) div 2;
      if movement > highest then highest := movement
    end;
    combatant := Types.PCharacter(combatant)^.next
  end;
  HighestEnemyMovement := highest
end;

function CheckAttackAlly(attacker, defender: Types.PCharacter): Boolean;
var
  { Unused in this version; see the other implementations of this routine. }
  combatant: Pointer;
begin
  if (Byte(CharHlp.EnemyTeam(defender)) = Byte(Types.PCharacter(attacker)^.side)) or
      (Types.PCharacter(attacker)^.quickFight <> 0) then
    CheckAttackAlly := True
  else if MenuCore.YesNoMenu(GDConsts.attackAllyPrompt, GDConsts.noKey) <> GDConsts.yesKey then
    CheckAttackAlly := False
  else begin
    CheckAttackAlly := True;
    GDVars.attackedAlly := 1;
    GDVars.zone1^.attackedAllies[GDConsts.attackedAlliesIndex + $7C00] := 1
  end
end;

{ Shows the range to the creature under aim and the aim menu (Next Prev Manual Target Center Exit), enabling Target
  within range and, for an attack, when the readied weapon can be used on it; centers the view on the creature.
  @param(character Creature aiming.)
  @param(target Creature under aim.)
  @param(range Range allowed.)
  @param(aimMode Attack or spell aim.)
  @param(emptyCellOk Unused.)
  @param(creatureOk Unused.)
  @param(targetOk Non-zero when the creature may be taken.)
  @param(x Column under aim.)
  @param(y Row under aim.)
  @returns(The menu choice, read as a Boolean.) }
function AimTargetMenu(character, target: Types.PCharacter; range, aimMode, emptyCellOk, creatureOk, targetOk, x,
                       y: Byte): Boolean;
var
  index: Byte;
  choice: Byte;
  selected: Types.PItem;
  distance: Word;
  { Unused in this version; see the other implementations of this routine. }
  mapResult: Byte;
  savedDisplay: Byte;
  coordBShort: ShortInt absolute x;
  coordAShort: ShortInt absolute y;
begin
  distance := 255;
  savedDisplay := GDVars.arena^.distMode;
  GDVars.arena^.distMode := 1;
  mapResult := Byte(Pathing.WalkLine(CbtMap.CombatCellX(character), CbtMap.CombatCellY(character), coordBShort,
                                     coordAShort, distance, GDVars.arena));
  GDVars.arena^.distMode := savedDisplay;
  distance := distance div 2;
  if aimMode <> GDConsts.spellAimMode then
    TextRend.DisplayString(0, 23, LightGreen, Black, GDConsts.rangeLabel + CharHlp.WordToString(distance) + '  ');
  FillChar(GDVars.enabledChoices, SizeOf(GDVars.enabledChoices), $FF);
  choice := 0;
  for index := 0 to 5 do begin
    if index = 3 then begin
      if (range >= distance) and (targetOk <> 0) then begin
        if aimMode = GDConsts.spellAimMode then
          MenuCore.AppendChoice(3, choice)
        else if character <> target then begin
          if not CharHlp.HasRangedWeapon(character) then
            MenuCore.AppendChoice(3, choice)
          else if CharHlp.FindDamagingRangedWeapon(character, selected) then begin
            if (CharHlp.CountTargets(character, 1, False) = 0) or CharHlp.HasThrowableWeapon(character) then
              MenuCore.AppendChoice(3, choice)
          end
        end
      end
    end else
      MenuCore.AppendChoice(index, choice)
  end;
  if target <> nil then begin
    CbtMap.DisplayMapViewCentered(target, 3, True);
    GDVars.combatInfoDirty := 1;
    CharHlp.CombatPrintCreatureInfo(target)
  end;
  AimTargetMenu := Boolean(MenuCore.MenuHorizontal(GDConsts.aimPrompt, GDConsts.aimMenuOptions, 1, 0));
end;

{ Confirms an aim selection: weapon mode 1 makes a weapon attack, anything else selects a spell target. A weapon attack
  on an ally needs CheckAttackAlly's consent, otherwise the selection is cleared and the done flag is False. The attack
  tries a sweep first; a throwable ranged weapon used at distance 1 strikes as melee.
  @param(character The creature aiming.)
  @param(target The creature chosen.)
  @param(aiMode 1 for a weapon attack.)
  @param(done False when the attack was declined; otherwise True or the attack's result.)
  @param(aim Receives the target and its cell; cleared when declined.) }
procedure ConfirmAttackTarget(character, target: Pointer; aiMode: Byte; var done: Byte; var aim);
var
  { Unused in this version; see the other implementations of this routine. }
  targetDir: Byte;
  selected: Types.PItem;
begin
  selected := nil;
  done := 1;
  if aiMode = GDConsts.attackAimMode then
    if not CbtActs.CheckAttackAlly(character, target) then done := 0;
  if done <> 0 then begin
    TAimResult(aim).target := target;
    TAimResult(aim).x := CbtMap.CombatCellX(target);
    TAimResult(aim).y := CbtMap.CombatCellY(target);
    GDVars.arena^.cursorOn := 0;
    CbtMap.ScrollView(GDVars.arena^.ox + 3, GDVars.arena^.oy + 3, 3, C_Dir.CENTER);
    if aiMode = GDConsts.attackAimMode then begin
      if CbtActs.SweepAttack(character, target) then
        done := Byte(CharHlp.EndActions(character))
      else begin
        CbtActs.NoteAttackDirection(character, target);
        if CharHlp.HasRangedWeapon(character) then
          if CharHlp.FindDamagingRangedWeapon(character, selected) then
            if CharHlp.HasThrowableWeapon(character) then
              if CharHlp.CalcDistance(character, target) = 1 then selected := nil;
        CbtActs.MakeAttack(character, target, 0, selected, done)
      end
    end
  end else
    FillChar(aim, 7, 0)
end;

{ Runs the manual aim cursor. Starting at the given cell, the player moves a cursor over the arena with the keypad; for
  each cell it shows the creature or corpse there and the range, and marks the cell valid when it is within range and
  line of sight, not impassable, and holds a creature the aimer may target (or is open ground, when ground is allowed).
  With the creature flag 0 a creature is an invalid target. For an attack the aimer itself, a corpse, and creatures out
  of reach of its weapon are invalid too. Target (or the confirm key) returns the cell and creature with the done flag
  set; Exit or Escape returns the starting cell with it clear. Space recenters the view.
  @param(character The combatant aiming.)
  @param(target Overwritten: holds the creature under the cursor.)
  @param(range The range.)
  @param(aimMode 1 for an attack, 0 for a spell.)
  @param(emptyCellOk Nonzero allows open ground.)
  @param(creatureOk 0 makes a creature an invalid target.)
  @param(targetOk Receives whether the cell under the cursor is a valid target.)
  @param(accepted Receives True when a target was chosen.)
  @param(aim Receives the target.)
  @param(coordX The starting column.)
  @param(coordY The starting row.) }
procedure ManualAimCursor(character, target: Pointer; range, aimMode, emptyCellOk, creatureOk: Byte; var targetOk,
                          accepted: Byte; var aim; coordX, coordY: Byte);
var
  activeKey: Byte;
  menuResult: Byte;
  selected: Types.PItem;
  direction: Byte;
  index: Byte;
  mapX: Byte;
  mapY: Byte;
  candidateY: Byte;
  candidateX: Byte;
  mapXShort: ShortInt absolute mapX;
  mapYShort: ShortInt absolute mapY;
  savedX: Byte;
  savedY: Byte;
  distance: Word;
begin
  GDVars.cursorActive := 1;
  savedX := coordX;
  savedY := coordY;
  GDVars.cursorX := coordX;
  GDVars.cursorY := coordY;
  FillChar(aim, 7, 0);
  GDVars.arena^.cursorOn := 1;
  GDVars.arena^.cursorSize := 1;
  menuResult := 255;
  direction := C_Dir.CENTER;
  GDVars.breathAim := 0;
  while menuResult > 1 do begin
    CbtMap.ScrollView(Byte(GDVars.cursorX), Byte(GDVars.cursorY), 2, direction);
    Inc(GDVars.cursorX, GDConsts.directionX[direction]);
    Inc(GDVars.cursorY, GDConsts.directionY[direction]);
    if GDVars.cursorX < 0 then GDVars.cursorX := 0;
    if GDVars.cursorY < 0 then GDVars.cursorY := 0;
    if GDVars.cursorX > 49 then GDVars.cursorX := 49;
    if GDVars.cursorY > 24 then GDVars.cursorY := 24;
    CbtMap.GetArenaContents(Byte(GDVars.cursorX), Byte(GDVars.cursorY), candidateY, candidateX);
    GameIo.FlushKeys;
    targetOk := 0;
    distance := 255;
    mapX := Byte(GDVars.cursorX);
    mapY := Byte(GDVars.cursorY);
    if Pathing.WalkLine(CbtMap.CombatCellX(character), CbtMap.CombatCellY(character), mapXShort, mapYShort, distance,
                        GDVars.arena) then begin
      targetOk := 1;
      if aimMode <> GDConsts.spellAimMode then
        TextRend.DisplayString(0, 23, LightGreen, Black,
                               GDConsts.rangeLabel + CharHlp.WordToString(distance div 2) + '  ')
    end else begin
      if aimMode <> GDConsts.spellAimMode then
        Border.ClearBox(0, 23, 39, 23)
    end;
    distance := distance div 2;
    target := nil;
    if targetOk <> 0 then begin
      if candidateY > 0 then
        target := GDVars.creatures[candidateY]
      else if candidateX = C_Terr.TERRAIN_CORPSE then begin
        for index := 1 to GDVars.downedCount do
          if (GDVars.downed[index].x = GDVars.cursorX) and (GDVars.downed[index].y = GDVars.cursorY) then
            target := GDVars.downed[index].cr
      end
    end;
    if target <> nil then begin
      GDVars.combatInfoDirty := 1;
      CharHlp.CombatPrintCreatureInfo(target)
    end else
      Border.ClearBox(23, 1, 38, 21);
    if (range < distance) or (GDConsts.terrain[candidateX].cost = C_Terr.TERRAIN_IMPASSABLE) then
      targetOk := 0;
    if target <> nil then begin
      if (not CbtActs.CanTarget(character, target, 1)) or (creatureOk = 0) then
        targetOk := 0;
      if aimMode = GDConsts.attackAimMode then begin
        if (character = target) or ((candidateY = 0) and (candidateX = C_Terr.TERRAIN_CORPSE)) then
          targetOk := 0
        else if CharHlp.HasRangedWeapon(character) and
          ((not CharHlp.FindDamagingRangedWeapon(character, selected)) or
           ((CharHlp.CountTargets(character, 1, False) > 0) and (not CharHlp.HasThrowableWeapon(character)))) then
          targetOk := 0
      end
    end else if emptyCellOk = 0 then
      targetOk := 0;
    FillChar(GDVars.enabledChoices, SizeOf(GDVars.enabledChoices), $FF);
    activeKey := 0;
    if targetOk <> 0 then MenuCore.AppendChoice(0, activeKey)
    else MenuCore.AppendChoice(1, activeKey);
    menuResult := MenuCore.MenuHorizontal(GDConsts.cursorPrompt, GDConsts.cursorMenu, 1, 0);
    if GDVars.menuExtendedKey <> 0 then begin
      case menuResult of
        Ord(C_Keys.UP): direction := C_Dir.NORTH;
        Ord(C_Keys.PAGE_UP): direction := C_Dir.NORTHEAST;
        Ord(C_Keys.RIGHT): direction := C_Dir.EAST;
        Ord(C_Keys.PAGE_DOWN): direction := C_Dir.SOUTHEAST;
        Ord(C_Keys.DOWN): direction := C_Dir.SOUTH;
        Ord(C_Keys.END_KEY): direction := C_Dir.SOUTHWEST;
        Ord(C_Keys.LEFT): direction := C_Dir.WEST;
        Ord(C_Keys.HOME): direction := C_Dir.NORTHWEST;
        32: begin
          CbtMap.ScrollView(Byte(GDVars.cursorX), Byte(GDVars.cursorY), 0, C_Dir.CENTER);
          direction := C_Dir.CENTER
        end;
        Ord(C_Keys.ESCAPE): begin
          accepted := 0;
          CbtMap.RedrawArenaCell(Byte(GDVars.cursorX), Byte(GDVars.cursorY));
          FillChar(aim, 7, 0);
          TAimResult(aim).x := savedX;
          TAimResult(aim).y := savedY;
          CbtMap.ScrollView(savedX, savedY, 0, C_Dir.CENTER);
          GDVars.arena^.cursorOn := 0;
          CbtMap.RedrawArenaCell(savedX, savedY);
          GDVars.breathAim := 0;
          menuResult := 1
        end else direction := C_Dir.CENTER
      end
    end else begin
      case menuResult of
        0: begin
          accepted := 1;
          TAimResult(aim).x := Byte(GDVars.cursorX);
          TAimResult(aim).y := Byte(GDVars.cursorY);
          if target <> nil then
            TAimResult(aim).target := target
          else
            TAimResult(aim).target := nil;
          GDVars.arena^.cursorOn := 0;
          CbtMap.RedrawArenaCell(Byte(GDVars.cursorX), Byte(GDVars.cursorY));
          GDVars.breathAim := 0
        end;
        1: begin
          accepted := 0;
          CbtMap.RedrawArenaCell(Byte(GDVars.cursorX), Byte(GDVars.cursorY));
          FillChar(aim, 7, 0);
          TAimResult(aim).x := savedX;
          TAimResult(aim).y := savedY;
          CbtMap.ScrollView(savedX, savedY, 0, C_Dir.CENTER);
          GDVars.arena^.cursorOn := 0;
          CbtMap.RedrawArenaCell(savedX, savedY);
          GDVars.breathAim := 0
        end;
        else direction := C_Dir.CENTER
      end
    end
  end;
  GDVars.cursorActive := 0
end;

procedure CombatAimMenu(character: Pointer; range, aimMode, emptyCellOk, creatureOk: Byte; var done: Byte; var aim);
var targets: array[1..72] of Types.TTargetEntry;
    localRoll: Byte;
    targetCount: Byte;
    selectedIndex: Byte;
    { Unused in this version; see the other implementations of this routine. }
    skipStep: Byte;
    oldX: ShortInt;
    oldY: ShortInt;
    newX: ShortInt;
    newY: ShortInt;
    selected: Pointer;
    menuResult: Byte;
    active: Byte;
    accepted: Byte;
    stop: Byte;
    currentX: ShortInt;
    currentY: ShortInt;
    originalX: ShortInt;
    originalY: ShortInt;
    { Unused in this version; see the other implementations of this routine. }
    originalFacing: Byte;

  { Moves the selection by delta through the aim list, wrapping, and returns the creature selected. }
  function AdvanceAimTarget(delta: ShortInt): Pointer;
  var
    previousTarget: Pointer;
    nextTarget: Pointer;
  begin
    previousTarget := GDVars.creatures[targets[selectedIndex].characterIndex];
    if previousTarget = nil then previousTarget := character;
    if targetCount < 1 then GameIo.ExitGame;
    oldX := GDVars.arenaLoc[targets[selectedIndex].characterIndex].x;
    oldY := GDVars.arenaLoc[targets[selectedIndex].characterIndex].y;
    Inc(selectedIndex, delta);
    if selectedIndex = 0 then selectedIndex := targetCount;
    if selectedIndex > targetCount then selectedIndex := 1;
    nextTarget := GDVars.creatures[targets[selectedIndex].characterIndex];
    newX := GDVars.arenaLoc[targets[selectedIndex].characterIndex].x;
    newY := GDVars.arenaLoc[targets[selectedIndex].characterIndex].y;
    if (nextTarget = nil) or (newX < 0) or (newY < 0) then begin
      AdvanceAimTarget := previousTarget;
      newX := oldX;
      newY := oldY
    end else begin
      AdvanceAimTarget := nextTarget;
      CharHlp.CombatAnimateMovingIcon(oldX, oldY, newX, newY, 1, 0);
      oldX := newX;
      oldY := newY
    end;
  end;

  { Lists the creatures the aimer may target, nearest first, starting at its current target. }
  procedure BuildAimTargets;
  var index: Byte;
      candidate: Pointer;
  begin
    selectedIndex := 1;
    Pathing.BuildTargetList(CbtMap.CombatCellX(character), CbtMap.CombatCellY(character), 255, GDConsts.anyDirection,
                            CbtMap.GetIconSize(character), GDVars.arena);
    targetCount := 0;
    for index := 1 to GDVars.targetCount do begin
      candidate := GDVars.creatures[GDVars.targetList[index].characterIndex];
      if CbtActs.CanTarget(character, candidate, 0) then begin
        Inc(targetCount);
        targets[targetCount] := GDVars.targetList[index];
        if candidate = Types.PCharacter(character)^.combat^.target then
          selectedIndex := targetCount
      end
    end;
    selected := AdvanceAimTarget(0);
    if selected <> character then begin
      GDVars.menuResetByte := 255;
      GDVars.selectedChoice := 4
    end
  end;
begin
  CharHlp.CopyIconFacing(28, 0, 0, False);
  FillChar(aim, 7, 0);
  done := 0;
  localRoll := range;
  if localRoll = 255 then begin
    if Types.PCharacter(character)^.equipped[0] <> nil then
      localRoll := GDVars.baseItems[Types.PCharacter(character)^.equipped[0]^.itemType].range
    else
      localRoll := 1
  end;
  if (localRoll = 0) or (localRoll = 255) then localRoll := 1;
  originalX := CbtMap.CombatCellX(character);
  originalY := CbtMap.CombatCellY(character);
  CbtMap.RedrawArenaCell(originalX, originalY);
  BuildAimTargets;
  currentX := CbtMap.CombatCellX(selected);
  currentY := CbtMap.CombatCellY(selected);
  active := 1;
  stop := 0;
  while stop = 0 do begin
    menuResult := Byte(CbtActs.AimTargetMenu(character, selected, localRoll, aimMode, emptyCellOk, creatureOk, active,
                                             currentX, currentY));
    if GDVars.menuExtendedKey = 0 then begin
      case menuResult of
        0: begin active := 1; selected := AdvanceAimTarget(1) end;
        1: begin active := 1; selected := AdvanceAimTarget(-1) end;
        2: begin
          CbtActs.ManualAimCursor(character, selected, localRoll, aimMode, emptyCellOk, creatureOk, active, accepted,
                                  aim, currentX, currentY);
          selected := TAimResult(aim).target;
          currentX := TAimResult(aim).x;
          currentY := TAimResult(aim).y;
          if (active <> 0) and (accepted <> 0) then begin
            menuResult := 3;
            stop := 1;
            GDVars.selectedChoice := 4;
            if selected <> nil then
              TAimResult(aim).target := selected
            else
              TAimResult(aim).target := nil;
            done := 1;
            if aimMode = GDConsts.attackAimMode then
              CbtActs.ConfirmAttackTarget(character, selected, aimMode, done, aim);
            if done = 0 then begin
              GDVars.arena^.cursorOn := 0;
              CbtMap.ScrollView(currentX, currentY, 0, C_Dir.CENTER)
            end
          end else
            GDVars.selectedChoice := 3
        end;
        3: begin
          TAimResult(aim).x := currentX;
          TAimResult(aim).y := currentY;
          if selected <> nil then
            TAimResult(aim).target := selected
          else
            TAimResult(aim).target := nil;
          done := 1;
          if aimMode = GDConsts.attackAimMode then
            CbtActs.ConfirmAttackTarget(character, selected, aimMode, done, aim);
          if done = 0 then begin
            GDVars.arena^.cursorOn := 0;
            CbtMap.ScrollView(currentX, currentY, 0, C_Dir.CENTER)
          end;
          stop := 1
        end;
        4: begin
          GDVars.arena^.cursorOn := 1;
          GDVars.arena^.cursorSize := 1;
          CbtMap.ScrollView(currentX, currentY, 0, C_Dir.CENTER);
          GDVars.arena^.cursorOn := 0
        end;
        5: begin
          GDVars.arena^.cursorOn := 0;
          CbtMap.ScrollView(currentX, currentY, 0, C_Dir.CENTER);
          stop := 1
        end
      end
    end else if menuResult = Ord(C_Keys.ESCAPE) then begin
      GDVars.arena^.cursorOn := 0;
      CbtMap.RedrawArenaCell(currentX, currentY);
      CbtMap.ScrollView(originalX, originalY, 0, C_Dir.CENTER);
      menuResult := 5;
      stop := 1
    end;
    if (menuResult in [0, 1, 3]) and (selected <> nil) then begin
      currentX := CbtMap.CombatCellX(selected);
      currentY := CbtMap.CombatCellY(selected)
    end
  end;
  if aimMode <> GDConsts.spellAimMode then
    Border.ClearBox(0, 23, 39, 23)
end;

function AcquireTarget(character: Types.PCharacter; range, anyReachable, dropCurrent, allies: Byte): Boolean;
var local: TPickTargetFrame;
    { Unused in this version; see the other implementations of this routine. }
    retryPass: Byte;
begin
  local.effect := nil;
  local.retry := 0;
  local.accepted := 0;
  local.lastRetry := 0;
  local.target := Types.PCharacter(character)^.combat^.target;
  if (dropCurrent <> 0) or
      ((local.target <> nil) and
       ((Types.PCharacter(local.target)^.side = Types.PCharacter(character)^.side) or
        (Types.PCharacter(local.target)^.enabled = 0) or
        (not CbtActs.CanTarget(character, local.target, allies)))) then
    Types.PCharacter(character)^.combat^.target := nil;
  if Types.PCharacter(character)^.combat^.target <> nil then
    local.accepted := 1;
  while (local.accepted = 0) and (local.lastRetry = 0) do begin
    local.lastRetry := local.retry;
    if (local.retry <> 0) and (dropCurrent = 0) then
      GDVars.arena^.distMode := 1;
    local.attempts := 20;
    local.count := CharHlp.CountTargets(character, range, Boolean(allies));
    while (local.attempts > 0) and (local.accepted = 0) and (local.count > 0) do begin
      Dec(local.attempts);
      if CharHlp.HasEffect(character, 91, local.effect) and
          (GDVars.creatures[GDVars.targetIndices[1]] = GDVars.yellTarget) and (local.attempts = 19) then
        local.choice := 1
      else
        local.choice := FxEngine.RollDice(1, local.count);
      if GDVars.targetIndices[local.choice] > 0 then begin
        local.target := GDVars.creatures[GDVars.targetIndices[local.choice]];
        if ((anyReachable <> 0) and (GDVars.arena^.distMode <> 0)) or
            CbtActs.CanTarget(character, local.target, allies) then begin
          local.accepted := 1;
          Types.PCharacter(character)^.combat^.target := local.target
        end else begin
          GDVars.targetIndices[local.choice] := 0;
          for local.choice := 1 to local.count do
            if GDVars.targetIndices[local.choice] > 0 then local.accepted := 1;
          if local.accepted <> 0 then
            local.accepted := 0
          else
            local.count := 0
        end
      end
    end;
    if local.retry = 0 then local.retry := 1
  end;
  GDVars.arena^.distMode := 0;
  AcquireTarget := Boolean(local.accepted)
end;

function VictoryCheat: Boolean;
var
  { Unused in this version; see the other implementations of this routine. }
  completed: Boolean;
  current: Pointer;
begin
  VictoryCheat := False;
  if ParamStr(2) <> PLocalString(@GDVars.debugPassword)^ then
    Exit;
  VictoryCheat := True;
  CharHlp.PrintBottomLine('The Gods intervene!');
  current := GDVars.partyHead;
  while current <> nil do begin
    if Byte(Types.PCharacter(current)^.side) = 1 then begin
      Types.PCharacter(current)^.enabled := 0;
      Types.PCharacter(current)^.status := C_Status.DEAD_STATUS;
      GDVars.arenaLoc[CbtMap.CombatSlot(current)].size := 0
    end;
    completed := CharHlp.EndActions(current);
    current := Types.PCharacter(current)^.next
  end;
  CbtMap.ScrollView(GDVars.arena^.ox + 3, GDVars.arena^.oy + 3, 255, C_Dir.CENTER)
end;

{ Rates a creature as a target for a spell: -10 on the wrong team (or healed by fire, for a fire spell); 1 when the
  spell would affect it, by the spell's own test or, for the rest, when it lacks the spell's effect; 0 otherwise. A
  minor globe stops spells below level 4, a major globe below level 5, and spell resistance above 50 every spell.
  @param(candidate The creature.)
  @param(spellId The spell.)
  @param(team Team the spell is meant for.)
  @returns(1, 0 or -10.) }
function RateSpellTarget(candidate: Types.PCharacter; spellId, team: Byte): ShortInt;
var resultValue: ShortInt;
    found: Pointer;
    gate: ShortInt;
    action: Byte;
begin
  RateSpellTarget := 0;
  if Byte(Types.PCharacter(candidate)^.side) <> team then begin
    RateSpellTarget := -10;
    Exit
  end;
  resultValue := 0;
  action := GDConsts.spellTable[spellId].effectId;
  case spellId of
  C_Spell.BLESS_GIFT, C_Spell.BLESS_CLERIC: begin
    if not CharHlp.HasEffect(candidate, C_Effect.BLESS, found) then
      if CharHlp.CountTargets(candidate, 1, False) = 0 then resultValue := 1
  end;
  C_Spell.PRAYER: begin
    if not CharHlp.HasEffect(GDVars.currentCharacter, C_Effect.PRAYER, found) then resultValue := 1
  end;
  C_Spell.CURE_LIGHT_WOUNDS, C_Spell.CURE_SERIOUS_WOUNDS, C_Spell.CURE_CRITICAL_WOUNDS,
    C_Spell.HEAL: begin
    if Byte(Types.PCharacter(candidate)^.maxHitPoints > Types.PCharacter(candidate)^.hitPoints) <> 0 then
        resultValue := 1
  end;
  C_Spell.CHARM_PERSON_MAMMAL: begin
    if Byte((Types.PCharacter(candidate)^.race < C_Race.MONSTER) or
            ((Types.PCharacter(candidate)^.typeFlags and $10) <> 0)) <> 0 then
      resultValue := 1
  end;
  C_Spell.CHARM_PERSON_GIFT, C_Spell.CHARM_PERSON_MAGE: begin
    if ((Types.PCharacter(candidate)^.typeFlags and $02) <> 0) or
        (Byte(Types.PCharacter(candidate)^.iconDimensions = 1) <> 0) then resultValue := 1
  end;
  65, C_Spell.MAGIC_MISSILE: begin
    if not CharHlp.HasEffect(candidate, C_Effect.SHIELD, found) then resultValue := 1
  end;
  C_Spell.SLEEP: begin
    if Byte(Types.PCharacter(candidate)^.levelHighest < 5) <> 0 then
      if not CharHlp.HasEffect(candidate, C_Effect.IMMUNE_CHARM_SLEEP, found) then
        if not CharHlp.HasEffect(candidate, C_Effect.SLEEP, found) then resultValue := 1
  end;
  C_Spell.HOLD_PERSON_CLERIC, C_Spell.HOLD_PERSON_MAGE: begin
    if Byte(Types.PCharacter(candidate)^.race < C_Race.MONSTER) <> 0 then
      if not CharHlp.HasEffect(candidate, C_Effect.IMMUNE_HOLD, found) then
        if not CharHlp.HasEffect(candidate, C_Effect.HELD, found) then resultValue := 1
  end;
  C_Spell.CURE_BLINDNESS: begin
    if CharHlp.HasEffect(candidate, C_Effect.BLIND, found) then resultValue := 1
  end;
  C_Spell.REMOVE_CURSE_GIFT, C_Spell.REMOVE_CURSE_CLERIC: begin
    if CharHlp.HasEffect(candidate, C_Effect.CURSED, found) then resultValue := 1
  end;
  C_Spell.FIREBALL, 64, C_Spell.FLAME_STRIKE, C_Spell.DELAY_BLAST_FIREBALL: begin
    if CharHlp.HasEffect(candidate, C_Effect.HEALED_BY_FIRE, found) then resultValue := -10
    else resultValue := 1
  end;
  C_Spell.LIGHTNING_BOLT: begin
    if not CharHlp.HasEffect(candidate, C_Effect.IMMUNE_ELECTRICITY, found) then resultValue := 1
  end;
  C_Spell.SLAY_LIVING, C_Spell.DEATH_SPELL: begin
    if (Types.PCharacter(candidate)^.immunityFlags and $08) = 0 then resultValue := 1
  end;
  61: begin
    if not CharHlp.HasEffect(candidate, C_Effect.IMMUNE_HOLD, found) then resultValue := 1
  end;
  C_Spell.POISON: begin
    if not CharHlp.HasEffect(candidate, C_Effect.IMMUNE_POISON_HOLD, found) then resultValue := 1
  end;
  C_Spell.MASS_CHARM, C_Spell.CHARM_MONSTERS: begin
    if (Types.PCharacter(candidate)^.typeFlags and $02) <> 0 then resultValue := 1
  end;
  C_Spell.CONFUSION: begin
    if not CharHlp.HasEffect(candidate, C_Effect.IMMUNE_CONFUSION, found) then resultValue := 1
  end;
  C_Spell.FEAR: begin
    if not CharHlp.HasEffect(candidate, C_Effect.IMMUNE_FEAR, found) then resultValue := 1
  end;
  C_Spell.CLOUDKILL: begin
    if Types.PCharacter(candidate)^.levelHighest < 6 then resultValue := 1
  end;
  C_Spell.HOLD_MONSTERS: begin
    if not CharHlp.HasEffect(candidate, C_Effect.IMMUNE_HOLD, found) then resultValue := 1
  end;
  else begin
    if action = 0 then
      resultValue := 1
    else if Byte(not CharHlp.HasEffect(candidate, action, found)) <> 0 then
      resultValue := 1
  end
  end;
  gate := GDConsts.spellTable[spellId].level;
  if resultValue > 0 then begin
    if gate < 5 then
      if CharHlp.HasEffect(candidate, C_Effect.MAJOR_GLOBE, found) then resultValue := 0;
    if gate < 4 then
      if CharHlp.HasEffect(candidate, C_Effect.MINOR_GLOBE, found) then resultValue := 0;
    if Types.PCharacter(candidate)^.spellResistance > 50 then resultValue := 0
  end;
  RateSpellTarget := resultValue
end;

function RateSpell(character: Types.PCharacter; spellId: Byte): Byte;
var resultValue: ShortInt;
    team: Byte;
    index: Byte;
    count: Byte;
    roll: Byte;
    { Unused in this version; see the other implementations of this routine. }
    bestScore: Word;
begin
  RateSpell := 0;
  if GDConsts.spellTable[spellId].hostile = 0 then
    team := Types.PCharacter(character)^.side
  else
    team := Byte(CharHlp.EnemyTeam(character));
  if GDConsts.spellTable[spellId].targeting = 0 then
    resultValue := CbtActs.RateSpellTarget(character, spellId, team)
  else begin
    roll := Magic.CalcSpellRange(spellId);
    Pathing.BuildTargetList(CbtMap.CombatCellX(character), CbtMap.CombatCellY(character), roll, GDConsts.anyDirection,
                            CbtMap.GetIconSize(character), GDVars.arena);
    count := GDVars.targetCount;
    index := 1;
    resultValue := 0;
    if count > 0 then
      while (index <= count) and (resultValue <= 0) do begin
        resultValue := CbtActs.RateSpellTarget(GDVars.creatures[GDVars.targetList[index].characterIndex], spellId,
                                               team);
        Inc(index)
      end
  end;
  RateSpell := resultValue
end;

{ For the computer, scores each cell an area spell could be centered on by the targets its area would cover, and aims at
  the best one the caster reaches along a clear line, a tie taken one time in four. A fireball's radius shrinks by one
  outside the dungeon.
  @param(spellId The spell.)
  @param(aim Receives the cell.)
  @returns(1 when a cell was found, 0 otherwise.) }
function AimAreaSpell(spellId: Byte; var aim): Byte;
var grid: PAimScoreGrid;
    baseRange: Byte;
    outerRange: Byte;
    innerRange: Byte;
    { Unused in this version; see the other implementations of this routine. }
    savedTarget: array[1..4] of Byte;
    current: Pointer;
    baseX: ShortInt;
    baseY: ShortInt;
    candidateX: ShortInt;
    candidateY: ShortInt;
    bestDx: ShortInt;
    bestDy: ShortInt;
    selectorX: ShortInt;
    selectorY: ShortInt;
    x: ShortInt;
    y: ShortInt;
    minX: ShortInt;
    maxX: ShortInt;
    minY: ShortInt;
    maxY: ShortInt;
    rankResult: ShortInt;
    bestScore: ShortInt;
    bounds: TAimBounds;
    { Unused in this version; see the other implementations of this routine. }
    gridMinY: Byte;
    roll: Word;
    { Unused in this version; see the other implementations of this routine. }
    cellScores: array[1..8] of Byte;
    team: Byte;
begin
  if GDConsts.spellTable[spellId].hostile = 0 then
    team := GDVars.currentCharacter^.side
  else
    team := Byte(CharHlp.EnemyTeam(GDVars.currentCharacter));
  AimAreaSpell := 0;
  baseRange := GDConsts.spellTable[spellId].targeting - 8;
  if ((spellId = C_Spell.FIREBALL) or (spellId = C_Spell.DELAY_BLAST_FIREBALL)) and
      (GDVars.zone0^.inDungeon = 0) then Dec(baseRange);
  current := nil;
  outerRange := Magic.CalcSpellRange(spellId) + baseRange;
  if outerRange > 9 then begin
    outerRange := 9;
    current := GDVars.currentCharacter^.combat^.target
  end;
  innerRange := outerRange - baseRange;
  if current = nil then current := GDVars.currentCharacter;
  baseX := ShortInt(CbtMap.CombatCellX(current));
  baseY := ShortInt(CbtMap.CombatCellY(current));
  bounds.outerMinX := baseX - outerRange;
  bounds.outerMaxX := baseX + outerRange;
  bounds.outerMinY := baseY - outerRange;
  bounds.outerMaxY := baseY + outerRange;
  bounds.innerMinX := baseX - innerRange;
  bounds.innerMaxX := baseX + innerRange;
  bounds.innerMinY := baseY - innerRange;
  bounds.innerMaxY := baseY + innerRange;
  GetMem(grid, SizeOf(TAimScoreGrid));
  FillChar(grid^, SizeOf(TAimScoreGrid), 0);
  current := GDVars.partyHead;
  while current <> nil do begin
    candidateX := ShortInt(CbtMap.CombatCellX(current));
    candidateY := ShortInt(CbtMap.CombatCellY(current));
    if (Types.PCharacter(current)^.enabled <> 0) and (candidateX >= bounds.outerMinX) and
        (candidateX <= bounds.outerMaxX) and
        (candidateY >= bounds.outerMinY) and (candidateY <= bounds.outerMaxY) then begin
      rankResult := CbtActs.RateSpellTarget(current, spellId, team);
      minY := -baseRange;
      maxY := baseRange;
      if minY + candidateY < bounds.innerMinY then
        minY := bounds.innerMinY - candidateY;
      if maxY + candidateY > bounds.innerMaxY then
        maxY := bounds.innerMaxY - candidateY;
      for y := minY to maxY do begin
        minX := candidateX - GDConsts.areaHalfWidths[y, baseRange];
        maxX := candidateX + GDConsts.areaHalfWidths[y, baseRange];
        if minX < bounds.innerMinX then minX := bounds.innerMinX;
        if maxX > bounds.innerMaxX then maxX := bounds.innerMaxX;
        for x := minX to maxX do
          Inc(grid^[x - baseX, y + candidateY - baseY], rankResult)
      end
    end;
    current := Types.PCharacter(current)^.next
  end;
  selectorX := ShortInt(CbtMap.CombatCellX(GDVars.currentCharacter));
  selectorY := ShortInt(CbtMap.CombatCellY(GDVars.currentCharacter));
  bestScore := 0;
  for x := -innerRange to innerRange do
    for y := -innerRange to innerRange do begin
      rankResult := grid^[x, y];
      if (rankResult > bestScore) or
          ((rankResult = bestScore) and (rankResult > 0) and CharHlp.PercentileRoll(25)) then begin
        candidateX := selectorX;
        candidateY := selectorY;
        roll := Magic.CalcSpellRange(spellId);
        if (baseX + x >= 0) and (baseX + x <= 49) and (baseY + y >= 0) and (baseY + y < 24) then
          if Pathing.WalkLine(baseX + x, baseY + y, candidateX, candidateY, roll, GDVars.arena) then begin
            bestDx := x;
            bestDy := y;
            bestScore := rankResult
          end
      end
    end;
  TAimResult(aim).target := nil;
  if bestScore > 0 then begin
    AimAreaSpell := 1;
    TAimResult(aim).x := Byte(bestDx + baseX);
    TAimResult(aim).y := Byte(bestDy + baseY)
  end else begin
    AimAreaSpell := 0;
    TAimResult(aim).target := nil
  end;
  FreeMem(grid, SizeOf(TAimScoreGrid))
end;

procedure UseLeadership;
var
  leader: Pointer;
  candidate: Pointer;
  active: Byte;
  { Unused in this version; see the other implementations of this routine. }
  effect: Types.PEffect;

  { Rolls a knight's leadership: 1 when d100 is under its order's base plus its charisma bonus. }
  function LeadershipRoll(info: Pointer): Byte;
  var
    bonus: Byte;
    base: Byte;
  begin
    case Types.PCharacter(info)^.knightOrder of
      1: base := 20;
      2: base := 40;
      3: base := 80
    end;
    if Types.PCharacter(info)^.stats[C_Stat.CHARISMA].current > 13 then
      bonus := (Types.PCharacter(info)^.stats[C_Stat.CHARISMA].current - 13) * 5
    else
      bonus := 0;
    if base + bonus > FxEngine.RollDice(1, 100) then
      LeadershipRoll := 1
    else
      LeadershipRoll := 0
  end;
begin
  active := 0;
  candidate := GDVars.partyHead;
  while candidate <> nil do begin
    if Types.PCharacter(candidate)^.side = C_Side.PLAYER then
      Types.PCharacter(candidate)^.quickFight := Byte(Types.PCharacter(candidate)^.npc > $7F)
    else
      Types.PCharacter(candidate)^.quickFight := 1;
    candidate := Types.PCharacter(candidate)^.next
  end;
  leader := GDVars.partyHead;
  while leader <> nil do begin
    if (Types.PCharacter(leader)^.side = C_Side.PLAYER) and (Types.PCharacter(leader)^.npc <= $7F) and
        (Types.PCharacter(leader)^.classLevels[C_Class.KNIGHT] > 0) and
        (Types.PCharacter(leader)^.status = C_Status.OKAY) then begin
      candidate := GDVars.partyHead;
      while candidate <> nil do begin
        if (Types.PCharacter(candidate)^.side = C_Side.PLAYER) and
            (Types.PCharacter(candidate)^.npc > $7F) and (Types.PCharacter(candidate)^.quickFight <> 0) and
            (Types.PCharacter(candidate)^.status = C_Status.OKAY) and
            (Types.PCharacter(candidate)^.stats[C_Stat.INTELLIGENCE].current > 3) then begin
          if LeadershipRoll(leader) <> 0 then begin
            if active = 0 then begin
              active := 1;
              Border.DrawWindowFrame(0);
              TextRend.DisplayMessageWindow(1, 1, 38, 22, LightMagenta, Black, True, '  Using leadership ability ');
              TextRend.DisplayMessageWindow(1, 3, 38, 22, White, Black, True,
                                            PLocalString(leader)^ + ' leads ' + PLocalString(candidate)^ + '.')
            end;
            Types.PCharacter(candidate)^.quickFight := 0
          end
        end;
        candidate := Types.PCharacter(candidate)^.next
      end
    end;
    leader := Types.PCharacter(leader)^.next
  end;
  if active <> 0 then
    TextRend.DisplayAndPause(LightMagenta, Black, GDConsts.pressToContinue)
end;
begin
end.
