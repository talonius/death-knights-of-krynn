{ The combat round's actions: a step and the free attacks that leaving a foe draws, melee and missile attacks with their
  sweeps and backstabs, turning undead, fleeing, aiming (the player's cursor and the AI's picks) and target selection
  for combat spells. A routine's attacker is the creature acting; its defender is the one hit. }
{$F+,O+,S-,R-,V-,B-,I-}
unit CbtActs;
interface
uses C_Class, C_Cond, C_Dir, C_Effect, C_Keys, C_Race, C_Side, C_Spell, C_Stat, C_Status, C_Terr, GDConsts, GDVars,
  Types, CharHlp, FxEngine, CbtMap, TextRend, Music, MenuCore, Pathing, Magic, Border, GameIo, ViewChar, Crt;

{ Readies a creature as a round starts: clears its spell, lets it cast unless it stands in a stinking cloud, gives it
  its attacks in both forms, rolls its initiative (d6 plus its dexterity missile adjustment, at least 1, 6 less when its
  side is surprised, 0 when out of range or disabled) and recalculates its movement.
  @param(creature The creature.) }
procedure BeginRound(creature: Types.PCharacter);

{ Rolls the damage of one hit in an attack form into currentDamage: dice plus modifier (not below 0), after the
  attacker's and the defender's weapon-damage conditions; a backstab multiplies it by 2 + (thief level - 1) div 4.
  @param(attacker Creature attacking.)
  @param(defender Creature hit.)
  @param(phase Attack form, 1 or 2.) }
procedure CalcWeaponDamage(attacker, defender: Types.PCharacter; phase: Byte);

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

{ Converts half-attacks to attacks: adds 1 on odd rounds, then halves.
  @param(rate The rate in half-attacks.)
  @returns(The whole attacks for this round.) }
function AttacksFromRate(rate: Byte): Byte;

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
function FindTurnUndeadTarget(creature: Types.PCharacter; var target: Types.PCharacter;
                              var levelCap: ShortInt): Boolean;

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

{ Raises a defense value for range. With a ranged weapon the band is (range - 1) div 3 steps; a defender more than one
  band away adds 2 and more than two bands away 3 more. A weapon of range 3 or less has a band of 0, so any distance
  adds both. Melee adds nothing.
  @param(attacker The creature attacking.)
  @param(defender The creature attacked.)
  @param(armorClass The defense value, raised in place.) }
procedure ApplyRangePenalty(attacker, defender: Types.PCharacter; var armorClass: Byte);

{ Empty routine with no callers. }
procedure NoopCbtActs;

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
procedure CombatAimMenu(character: Types.PCharacter; range, aimMode, emptyCellOk, creatureOk: Byte; var done: Byte;
                        var aim: Types.TAimResult);

{ Tells whether an attack is a backstab: a thief with no weapon or a small blade (item types 3, 4, 17..19, 67), next to
  a defender of icon size 1 that has been attacked more than once, striking from behind it.
  @param(attacker Creature attacking.)
  @param(defender Creature attacked.)
  @returns(True for a backstab.) }
function IsBackstab(attacker, defender: Types.PCharacter): Boolean;

{ Flies a missile's icon from the attacker to the defender with its sound, the icon and pace by the weapon's item type:
  arrows and bolts drawn by direction, spinning icons for the thrown weapons.
  @param(attacker Creature shooting.)
  @param(defender Creature shot at.)
  @param(weapon The missile or thrown weapon.) }
procedure AnimateMissile(attacker, defender: Types.PCharacter; weapon: Types.PItem);

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

{ For the computer, scores each cell an area spell could be centered on by the targets its area would cover, and aims at
  the best one the caster reaches along a clear line, a tie taken one time in four. A fireball's radius shrinks by one
  outside the dungeon.
  @param(spellId The spell.)
  @param(aim Receives the cell.)
  @returns(1 when a cell was found, 0 otherwise.) }
function AimAreaSpell(spellId: Byte; var aim: Types.TAimResult): Byte;

{ As a fight starts, NPCs of the party and the monsters go on quick-fight; then each knight of the party, conscious and
  not an NPC, may lead each NPC on quick-fight with intelligence above 3 -- on d100 under 20, 40 or 80 by order, plus 5
  a charisma point above 13 -- taking it off computer control. The first success is announced. }
procedure UseLeadership;

{ Rates a creature as a target for a spell: -10 on the wrong team (or healed by fire, for a fire spell); 1 when the
  spell would affect it, by the spell's own test or, for the rest, when it lacks the spell's effect; 0 otherwise. A
  minor globe stops spells below level 4, a major globe below level 5, and spell resistance above 50 every spell.
  @param(candidate The creature.)
  @param(spellId The spell.)
  @param(team Team the spell is meant for.)
  @returns(1, 0 or -10.) }
function RateSpellTarget(candidate: Types.PCharacter; spellId, team: Byte): ShortInt;

{ Lets guarding enemies strike a creature that moved next to them: each adjacent enemy that is guarding and not helpless
  spends its guard on one free attack, while the mover stays up.
  @param(creature The creature that moved.) }
procedure GuardersAttack(creature: Types.PCharacter);

{ Rolls every attack the attacker has left, second form first, against the defender's armor class -- the rear armor
  class less 4 for a backstab, the rear one from behind or when attacked from several sides -- with the range penalty;
  each hit deals CalcWeaponDamage's damage. A weapon uses its large-creature damage against a large defender, and a
  helpless defender is slain outright.
  @param(attacker Creature attacking.)
  @param(defender Creature attacked.)
  @param(fromBehind Non-zero for an attack from behind.)
  @param(done Set when the attacker has no attacks left and its turn is over.)
  @param(thrown Unused.) }
procedure RollAttacks(attacker, defender: Types.PCharacter; fromBehind: Byte; var done: Byte; thrown: Types.PItem);

{ Chooses one target for a spell and moves the cast position to it. The player aims with the aim menu. The computer
  picks a creature, or for an area spell that may be aimed at the ground the best spot. On failure the target is
  cleared.
  @param(spellId The spell.)
  @param(aiControlled Nonzero when the computer is choosing.)
  @param(groundOk Nonzero allows an area spell to be aimed at the ground.)
  @param(target Receives the target.)
  @returns(True when a target was chosen.) }
function SelectSpellTarget(spellId, aiControlled, groundOk: Byte; var target: Types.TAimResult): Boolean;
implementation
type
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
    savedTarget: Pointer; attacker: Types.PCharacter;
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
    effect: Types.PEffect;
    candidates: array[1..12] of Byte
  end;
  PArmorByFacing = ^TArmorByFacing;
  { a character read for its front and rear armor classes, indexed by the side attacked }
  TArmorByFacing = record
    armorClassLead: array[$00..$CB] of Byte;
    { armorClass, rearArmorClass }
    armorClass: array[0..1] of Byte
  end;
  { AimAreaSpell's score per cell around its base }
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
  TTargetEntryList = array[1..72] of Types.TTargetEntry;
  TPickTargetFrame = packed record
    effect: Types.PEffect;
    target: Types.PCharacter;
    retry: Byte;
    accepted: Byte;
    lastRetry: Byte;
    choice: Byte;
    attempts: Byte;
    count: Byte
  end;

procedure BeginRound(creature: Types.PCharacter);
var
  { Unused in this version; see the other implementations of this routine. }
  i: Byte;
  cellIndex: Byte;
  inStinkingCloud: Byte;
  inCloudkill: Byte;
begin
  with creature^.combat^ do begin
    spellCast := 0;
    CbtMap.ProbeDirection(creature, C_Dir.CENTER, cellIndex, cellIndex, inStinkingCloud, inCloudkill);
    canCast := Byte(inStinkingCloud = 0);
    canUseItem := 1;
    attacked := 0;
    attackForm := 2;
    CbtActs.RecalcAttacksLeft(creature);
    GDVars.adjustedAttackRate := creature^.attackRate2;
    GDVars.attackInitByte := 0;
    FxEngine.TriggerEffectsWithCondition(C_Cond.MOVE_ATTACK_RATE, creature);
    creature^.attacksLeft[2] := CbtActs.AttacksFromRate(GDVars.adjustedAttackRate);
    if creature^.enabled <> 0 then begin
      initiative := FxEngine.RollDice(1, 6) + CharHlp.DexMissileAdjust(creature);
      if initiative < 1 then initiative := 1;
      if Byte(GDVars.zone1^.surprise[GDConsts.surpriseIndex + $7C00] and (creature^.side + 1)) <> 0 then
        Dec(initiative, 6);
      if (initiative < 0) or (initiative > 20) then initiative := 0
    end else
      initiative := 0
  end;
  creature^.combat^.movement := CharHlp.RecalcMovement(creature)
end;

procedure CalcWeaponDamage(attacker, defender: Types.PCharacter; phase: Byte);
begin
  GDVars.currentDamage := attacker^.currentModifiers[phase] + FxEngine.RollDamageDice(attacker^.currentRolls[phase],
                                                                                        attacker^.currentDice[phase]);
  if GDVars.currentDamage < 0 then GDVars.currentDamage := 0;
  FxEngine.TriggerEffectsWithCondition(C_Cond.WEAPON_DAMAGE_ATTACKER, attacker);
  FxEngine.TriggerEffectsWithCondition(C_Cond.WEAPON_DAMAGE_DEFENDER, defender);
  if CbtActs.IsBackstab(attacker, defender) then
    GDVars.currentDamage := GDVars.currentDamage *
      (((Byte(attacker^.classLevels[C_Class.THIEF]) - 1) div 4) + 2);
  GDVars.elementMask := 0
end;

procedure ProcessAttackResult(attacker, defender: Types.PCharacter; manner, damage, shownDamage, isHit: Byte);
var row: Byte;
    message: String[80];
    { Unused in this version; see the other implementations of this routine. }
    isDone: Byte;
begin
  case manner of
    2: message := '-Backstabs-';
    3: message := 'slays helpless'
  else
    message := 'Attacks'
  end;
  CharHlp.PrintCreatureMessage(attacker, message, 10, False);
  row := 12;
  CharHlp.DisplayCreatureName(defender, 23, row, False);
  Inc(row);
  if manner = 1 then
    message := '(from behind) '
  else
    message := '';
  if isHit <> 0 then begin
    if manner = 3 then
      message := 'with one cruel blow'
    else begin
      message := message + 'Hitting for ' + CharHlp.ByteToString(shownDamage);
      if shownDamage = 1 then
        message := message + ' point '
      else
        message := message + ' points ';
      message := message + 'of damage'
    end;
    CharHlp.InflictDamage(defender, damage)
  end else
    message := message + 'and Misses';
  if defender^.status <> C_Status.GONE then begin
    TextRend.DisplayMessageWindow(23, row, 38, row + 3, LightGreen, Black, True, message)
  end;
  row := GDVars.currentRow + 1;
  if damage > 0 then begin
    defender^.combat^.canCast := 0;
    if defender^.combat^.spellCast > 0 then begin
      TextRend.PauseOnly;
      CharHlp.PrintCreatureMessage(defender, 'lost a spell', 12, True);
      CharHlp.RemoveSpell(defender, defender^.combat^.spellCast);
      isDone := Byte(CharHlp.EndActions(defender))
    end else
      TextRend.PauseOnly
  end else
    TextRend.PauseOnly;
  if defender^.enabled = 0 then begin
    CharHlp.PrintCreatureMessage(defender, 'goes down', row, False);
    if (defender^.immunityFlags and $08) = 0 then begin
      Inc(row, 2);
      if defender^.status = C_Status.DYING then
        TextRend.DisplayString(23, row, LightGreen, Black, 'and is Dying');
      if defender^.status in [C_Status.DEAD_STATUS, C_Status.STONED, C_Status.GONE] then
        CharHlp.PrintCreatureMessage(defender, 'is killed', row, False);
      Inc(row, 2)
    end;
    FxEngine.RemoveEffectsHp0(defender);
    FxEngine.TriggerEffectsWithCondition(C_Cond.HIT_POINTS_ZERO, defender);
    if (defender^.enabled = 0) and (defender^.status <> 10) then
      CbtMap.CreatureDowned(defender)
    else
      TextRend.PauseOnly
  end;
  CharHlp.ClearMessageWindow
end;

procedure GuardersAttack(creature: Types.PCharacter);
var
  count: Byte;
  index: Byte;
  guarder: Types.PCharacter;
  done: Byte;
begin
  count := CharHlp.CountTargets(creature, 1, False);
  for index := 1 to count do begin
    if creature^.enabled <> 0 then begin
      guarder := GDVars.creatures[GDVars.targetIndices[index]];
      if guarder^.combat^.guarding <> 0 then
        if not CharHlp.IsHelpless(guarder) then begin
          CbtMap.ScrollView(CbtMap.CombatCellX(creature), CbtMap.CombatCellY(creature), 2, C_Dir.CENTER);
          guarder^.combat^.guarding := 0;
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
  local.x := local.baseX + GDConsts.combatTables.directionX[direction];
  local.y := local.baseY + GDConsts.combatTables.directionY[direction];
  if Odd(direction) then
    local.cost := GDConsts.combatTables.terrain[GDVars.arena^.cells[local.y, local.x]].cost * 3
  else
    local.cost := GDConsts.combatTables.terrain[GDVars.arena^.cells[local.y, local.x]].cost * 2;
  if local.cost > creature^.combat^.movement then
    creature^.combat^.movement := 0
  else
    Dec(creature^.combat^.movement, local.cost);
  local.cost := 1;
  if creature^.quickFight <> 0 then begin
    local.cost := 3;
    if not CbtMap.ViewCoordsValid(local.x - GDVars.arena^.ox, local.y - GDVars.arena^.oy) then
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
  creature^.combat^.attacksTaken := 0;
  creature^.combat^.attackAngles := 0;
  Music.SendSoundCommand(GDConsts.stepSound);
  CbtActs.GuardersAttack(creature);
  if (creature^.enabled = 0) or CharHlp.IsHelpless(creature) then
    creature^.combat^.movement := 0
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
        if GDVars.creatures[GDVars.targetIndices[local.scanPos]]^.combat^.panicked = 0 then
          if not CharHlp.HasEffect(GDVars.creatures[GDVars.targetIndices[local.scanPos]], C_Effect.ENTANGLED,
                                   local.effect) then begin
            local.candidates[local.index] := GDVars.targetIndices[local.scanPos];
            Inc(local.index)
          end
    end;
    local.candidateCount := local.index - 1;
    Inc(GDVars.arenaLoc[local.slot].x, GDConsts.combatTables.directionX[direction]);
    Inc(GDVars.arenaLoc[local.slot].y, GDConsts.combatTables.directionY[direction]);
    local.countAfter := CharHlp.CountTargets(creature, 1, False);
    Dec(GDVars.arenaLoc[local.slot].x, GDConsts.combatTables.directionX[direction]);
    Dec(GDVars.arenaLoc[local.slot].y, GDConsts.combatTables.directionY[direction]);
    for local.index := 1 to local.candidateCount do begin
      local.stillAdjacent := 0;
      for local.scanPos := 1 to local.countAfter do
        if GDVars.targetIndices[local.scanPos] = local.candidates[local.index] then
          local.stillAdjacent := 1;
      if local.stillAdjacent <> 0 then
        local.candidates[local.index] := 0
    end;
    if creature^.side = C_Side.PLAYER then
      for local.index := 1 to local.candidateCount do
        if (local.candidates[local.index] > 0) and (creature^.enabled <> 0) then
          local.leavingFoe := 1;
    for local.index := 1 to local.candidateCount do
      if (local.candidates[local.index] > 0) and (creature^.enabled <> 0) then begin
        GDVars.combatInfoDirty := 1;
        GDVars.showTurn := 1;
        local.attacked := 0;
        local.attacker := GDVars.creatures[local.candidates[local.index]];
        if CbtActs.CanTarget(local.attacker, creature, 0) then
          if (not CharHlp.HasRangedWeapon(local.attacker)) or CharHlp.HasThrowableWeapon(local.attacker) then
            for local.facingScan := local.attacker^.combat^.direction + 6 to
                local.attacker^.combat^.direction + 10 do
              if local.attacked = 0 then
                if (local.attacker^.combat^.initiative > 0) or (local.attacker^.combat^.attacksTaken = 0) or
                    Pathing.IsDirToward(CbtMap.CombatCellX(local.attacker), CbtMap.CombatCellY(local.attacker),
                                        CbtMap.CombatCellX(creature), CbtMap.CombatCellY(creature),
                                        local.facingScan mod 8) then begin
                  local.phase := 1;
                  if local.attacker^.attackRate = 0 then
                    local.phase := 2;
                  for local.phasePos := 1 to 2 do
                    if local.attacker^.attacksLeft[local.phasePos] > 0 then
                      local.phase := local.phasePos;
                  if local.attacker^.attacksLeft[local.phase] = 0 then
                    local.attacker^.attacksLeft[local.phase] := 1;
                  local.attacker^.combat^.attackForm := local.phase;
                  local.savedTarget := local.attacker^.combat^.target;
                  CbtActs.MakeAttack(local.attacker, creature, 1, nil, GDVars.attackDone);
                  local.attacked := 1;
                  local.attacker^.combat^.target := local.savedTarget;
                  if creature^.enabled <> 0 then begin
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
    FxEngine.PutOutOfPlayWithStatus(creature, C_Status.RUNNING, 'Got Away')
  else
    CharHlp.PrintBottomLine('Escape is blocked');
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
  previous := creature^.attacksLeft[1];
  creature^.attacksLeft[1] := creature^.attackRate;
  if CharHlp.HasRangedWeapon(creature) and CharHlp.FindDamagingRangedWeapon(creature, weapon) then begin
    ranged := 1;
    rate := GDVars.baseItems[creature^.equipped[0]^.itemType].rateOfFire;
    if rate < 2 then rate := 2;
    GDVars.adjustedAttackRate := rate
  end else
    GDVars.adjustedAttackRate := creature^.attacksLeft[1];
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
  if (creature^.combat^.attacked = 0) or (attacks < previous) then
    creature^.attacksLeft[1] := attacks
  else
    creature^.attacksLeft[1] := previous
end;

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
  foeIndex: Byte;
  target: Types.PCharacter;
begin
  SweepAttack := False;
  if character^.attacksLeft[1] < character^.combat^.sweepTargets then
    if foe^.levelHighest = 0 then
      if CharHlp.CalcDistance(character, foe) = 1 then begin
        count := CharHlp.CountTargets(character, 1, False);
        available := 0;
        for index := 1 to count do begin
          target := GDVars.creatures[GDVars.targetIndices[index]];
          if target = foe then foeIndex := index;
          if target^.levelHighest = 0 then Inc(available)
        end;
        if available > character^.attacksLeft[1] then begin
          if available > character^.combat^.sweepTargets then
            available := character^.combat^.sweepTargets;
          CharHlp.PrintCreatureMessage(character, 'sweeps', 10, True);
          target := GDVars.creatures[GDVars.targetIndices[1]];
          if target <> foe then begin
            GDVars.targetIndices[foeIndex] := GDVars.targetIndices[1];
            GDVars.targetIndices[1] := CbtMap.CombatSlot(foe)
          end;
          for index := 1 to count do
            if available > 0 then begin
              if GDVars.creatures[GDVars.targetIndices[index]]^.levelHighest = 0 then begin
                target := GDVars.creatures[GDVars.targetIndices[index]];
                CbtActs.NoteAttackDirection(character, target);
                character^.attacksLeft[1] := 1;
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
  savedCharacter: Types.PCharacter;
  savedTarget: Types.PCharacter;
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
      if (GDVars.targetRefused = 0) and ((target^.side <> attacker^.side) or (allowAlly <> 0)) then begin
        savedTarget := attacker^.combat^.target;
        attacker^.combat^.target := target;
        FxEngine.TriggerEffectsWithCondition(C_Cond.ATTACKER_VETO, attacker);
        attacker^.combat^.target := savedTarget
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
  target: Types.PCharacter;
  tableColumn: ShortInt;
  levelCap: ShortInt;
begin
  CharHlp.PrintCreatureMessage(creature, 'turns undead...', 10, False);
  MenuCore.ClearBottomLine;
  TextRend.PauseOnly;
  turnedAny := 0;
  stop := 0;
  Inc(creature^.combat^.turnAttempts);
  levelCap := 13;
  minimumLeft := 6;
  roll := FxEngine.RollDice(1, 20);
  tableColumn := creature^.classLevels[C_Class.CLERIC];
  if creature^.classLevels[C_Class.PALADIN] - 2 > tableColumn then
    tableColumn := creature^.classLevels[C_Class.PALADIN] - 2;
  if creature^.deity = 2 then Inc(tableColumn, 2);
  if tableColumn > 8 then
    if tableColumn < 14 then tableColumn := 9 else tableColumn := 10;
  if GDVars.zone0^.columnOffset > tableColumn then
    tableColumn := 0
  else
    Dec(tableColumn, GDVars.zone0^.columnOffset);
  affectedLeft := 255;
  while CbtActs.FindTurnUndeadTarget(creature, target, levelCap) and (affectedLeft > 0) do begin
    needed := GDConsts.turnUndeadTable[ShortInt(target^.levelUndead), tableColumn];
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
        FxEngine.PutOutOfPlayWithStatus(target, C_Status.RUNNING, 'is turned')
      else begin
        CharHlp.PrintCreatureMessage(target, 'Is destroyed', 10, False);
        CbtMap.CreatureDowned(target);
        target^.status := C_Status.GONE;
        target^.enabled := 0
      end;
      if minimumLeft > 0 then Dec(minimumLeft);
      Dec(affectedLeft);
      if (affectedLeft = 0) and (minimumLeft > 0) and (needed < 0) then Inc(affectedLeft);
      CharHlp.ClearMessageWindow
    end else
      Dec(levelCap)
  end;
  if turnedAny = 0 then CharHlp.PrintBottomLine('Nothing Happens...');
  CharHlp.CountTeams;
  GDVars.attackDone := Byte(CharHlp.EndActions(creature));
  CharHlp.ClearMessageWindow
end;

function FindTurnUndeadTarget(creature: Types.PCharacter; var target: Types.PCharacter;
                              var levelCap: ShortInt): Boolean;
var
  count: Byte;
  index: Byte;
  bestLevel: ShortInt;
  candidate: Types.PCharacter;
begin
  bestLevel := 0;
  target := nil;
  count := CharHlp.CountTargets(creature, 255, False);
  FindTurnUndeadTarget := False;
  for index := 1 to count do begin
    candidate := GDVars.creatures[GDVars.targetIndices[index]];
    if candidate^.combat^.panicked = 0 then
      if ShortInt(candidate^.levelUndead) > 0 then
        if ShortInt(candidate^.levelUndead) > bestLevel then
          if ShortInt(candidate^.levelUndead) <= levelCap then begin
            bestLevel := ShortInt(candidate^.levelUndead);
            target := candidate;
            FindTurnUndeadTarget := True
          end
  end;
  levelCap := bestLevel
end;

procedure RollAttacks(attacker, defender: Types.PCharacter; fromBehind: Byte; var done: Byte; thrown: Types.PItem);
var weapon: Types.TBaseItem;
    hitAny: Byte;
    stopped: Byte;
    behind: Byte;
    targetAc: Byte;
    form: Byte;
    forms: Byte;
    kind: Byte;
    armorSide: ShortInt;
begin
  behind := fromBehind;
  done := 0;
  GDVars.hitsMade[1] := 0;
  GDVars.hitsMade[2] := 0;
  GDVars.attacksMade[1] := 0;
  GDVars.attacksMade[2] := 0;
  hitAny := 0;
  stopped := 0;
  GDVars.currentDamage := 0;
  attacker^.combat^.attacked := 1;
  if CharHlp.IsHelpless(defender) then begin
    Music.SendSoundCommand(GDConsts.hitSound);
    while attacker^.attacksLeft[attacker^.combat^.attackForm] = 0 do
      Dec(attacker^.combat^.attackForm);
    Inc(GDVars.attacksMade[attacker^.combat^.attackForm]);
    CbtActs.ProcessAttackResult(attacker, defender, 3, defender^.hitPoints + 5, 1, 1);
    FxEngine.RemoveInvisibility(attacker);
    for form := 1 to 2 do attacker^.attacksLeft[form] := 0;
    hitAny := 1;
    done := 1
  end else begin
    if (attacker^.equipped[0] <> nil) and
        ((defender^.iconDimensions > $80) or ((defender^.iconDimensions and $07) > 1)) then begin
      weapon := GDVars.baseItems[attacker^.equipped[0]^.itemType];
      attacker^.currentRolls[1] := weapon.damageRollsLarge;
      attacker^.currentDice[1] := weapon.damageDiceLarge;
      attacker^.currentModifiers[1] :=
        (attacker^.currentModifiers[1] - ShortInt(weapon.damageModifier)) + ShortInt(weapon.damageModifierLarge)
    end;
    CharHlp.RecalcStats(defender);
    FxEngine.TriggerEffectsWithCondition(C_Cond.DEFENDER_ARMOR_CLASS, defender);
    armorSide := 0;
    if CbtActs.IsBackstab(attacker, defender) then
      targetAc := defender^.rearArmorClass - 4
    else begin
      if (defender^.combat^.attacksTaken > 1) and
          (CharHlp.DirTowardTarget(attacker, defender) = defender^.combat^.direction) and
          (defender^.combat^.attackAngles > 4)
      then
        behind := 1;
      if behind <> 0 then armorSide := 1;
      targetAc := PArmorByFacing(defender)^.armorClass[armorSide]
    end;
    CbtActs.ApplyRangePenalty(attacker, defender, targetAc);
    kind := 0;
    if behind <> 0 then kind := 1;
    if CbtActs.IsBackstab(attacker, defender) then kind := 2;
    forms := attacker^.combat^.attackForm;
    for form := forms downto 1 do
      while (attacker^.attacksLeft[form] > 0) and (stopped = 0) do begin
        Dec(attacker^.attacksLeft[form]);
        attacker^.combat^.attackForm := form;
        Inc(GDVars.attacksMade[form]);
        if FxEngine.AttackRoll(attacker, defender, targetAc) or CharHlp.IsHelpless(defender) then begin
          Inc(GDVars.hitsMade[form]);
          Music.SendSoundCommand(GDConsts.hitSound);
          hitAny := 1;
          CbtActs.CalcWeaponDamage(attacker, defender, form);
          if defender^.enabled <> 0 then
            CbtActs.ProcessAttackResult(attacker, defender, kind, GDVars.currentDamage, GDVars.currentDamage, 1);
          if (defender^.enabled <> 0) and (GDVars.currentDamage > 0) then
            FxEngine.TriggerEffectsWithCondition(form + 1, attacker);
          if defender^.enabled = 0 then stopped := 1;
          if attacker^.enabled = 0 then begin
            forms := 0;
            attacker^.attacksLeft[form] := 0
          end
        end
      end;
    if hitAny = 0 then begin
      Music.SendSoundCommand(GDConsts.damageSound);
      CbtActs.ProcessAttackResult(attacker, defender, kind, 0, 0, 0)
    end;
    done := 1;
    for form := 1 to 2 do
      if attacker^.attacksLeft[form] > 0 then done := 0;
    attacker^.combat^.sweepTargets := 0
  end;
  if attacker^.enabled = 0 then done := 1;
  if done <> 0 then done := Byte(CharHlp.EndActions(attacker))
end;

procedure NoteAttackDirection(attacker, defender: Types.PCharacter);
var angle: Byte;
    attackDirection: Byte;
begin
  Inc(defender^.combat^.attacksTaken);
  attackDirection := CharHlp.DirTowardTarget(defender, attacker);
  angle := (attackDirection - defender^.combat^.direction + 8) mod 8;
  if angle > 4 then angle := 8 - angle;
  defender^.combat^.attackAngles := (defender^.combat^.attackAngles + angle) mod 8
end;

procedure MakeAttack(attacker, defender: Types.PCharacter; fromBehind: Byte; weapon: Types.PItem; var done: Byte);
var
  thrownCopy: Types.PItem;
  walker: Types.PItem;
  savedCharacter: Types.PCharacter;
  direction: Byte;
begin
  GDVars.showTurn := 1;
  GDVars.combatInfoDirty := 1;
  GDVars.roundLimit := GDVars.roundNumber + 15;
  if (defender^.combat^.attacksTaken < 2)
     and (fromBehind = 0) then begin
    direction := CharHlp.DirTowardTarget(defender, attacker);
    defender^.combat^.direction := (direction + 4) mod 8
  end else if CbtMap.CombatIconVisible(defender, 0) then begin
    direction := defender^.combat^.direction;
    if fromBehind = 0 then
      defender^.combat^.direction := (direction + 4) mod 8
  end;
  if CbtMap.CombatIconVisible(defender, 0) then
    CbtMap.SetCreatureFacing(defender, direction, 0, 0);
  direction := CharHlp.DirTowardTarget(attacker, defender);
  CharHlp.CombatPrintCreatureInfo(attacker);
  CbtMap.SetCreatureFacing(attacker, direction, 1, 0);
  attacker^.combat^.target := defender;
  Delay(100);
  if weapon <> nil then CbtActs.AnimateMissile(attacker, defender, weapon);
  if (attacker^.equipped[0]^.itemType = 28)
     or (attacker^.equipped[0]^.itemType = 29)
  then
    CbtActs.AnimateMissile(attacker, defender, attacker^.equipped[0]);
  done := 1;
  if (attacker^.attacksLeft[1] > 0) or (attacker^.attacksLeft[2] > 0) then begin
    savedCharacter := GDVars.currentCharacter;
    GDVars.currentCharacter := attacker;
    CbtActs.RollAttacks(attacker, defender, fromBehind, done, weapon);
    if weapon <> nil then
      if not CharHlp.HasReadiedHoopak(attacker) then begin
        if weapon^.quantity > 0 then
          Dec(weapon^.quantity, GDVars.attacksMade[1]);
        if weapon^.quantity = 0 then
          if CharHlp.HasThrowableWeapon(attacker) and (weapon^.effect <> C_Effect.SPIRITUAL_HAMMER) then begin
            GetMem(thrownCopy, SizeOf(Types.TItem));
            Move(weapon^, thrownCopy^, SizeOf(Types.TItem));
            walker := GDVars.treasureItems;
            if walker = nil then begin
              GDVars.treasureItems := thrownCopy;
              thrownCopy^.next := nil
            end else begin
              while (walker^.next <> nil) and (walker <> GDVars.prevTreasure) do
                walker := walker^.next;
              thrownCopy^.next := walker^.next;
              walker^.next := thrownCopy
            end;
            thrownCopy^.equipped := 0;
            CharHlp.RemoveItem(attacker, weapon);
            GDVars.prevTreasure := thrownCopy
          end else
            CharHlp.RemoveItem(attacker, weapon)
      end;
    CharHlp.RecalcStats(attacker);
    GDVars.currentCharacter := savedCharacter
  end;
  if done <> 0 then
    done := Byte(CharHlp.EndActions(attacker));
  if CbtMap.CombatIconVisible(attacker, 0) then begin
    CbtMap.SetCreatureFacing(attacker, attacker^.combat^.direction, 1, 1);
    CbtMap.SetCreatureFacing(attacker, attacker^.combat^.direction, 0, 0)
  end
end;

procedure ApplyRangePenalty(attacker, defender: Types.PCharacter; var armorClass: Byte);
var
  band: ShortInt;
  distance: ShortInt;
begin
  distance := CharHlp.CalcDistance(attacker, defender);
  if CharHlp.HasRangedWeapon(attacker) then
    band := (GDVars.baseItems[attacker^.equipped[0]^.itemType].range - 1) div 3
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

procedure NoopCbtActs;
begin
end;

function SelectSpellTarget(spellId, aiControlled, groundOk: Byte; var target: Types.TAimResult): Boolean;
var found: Byte;
    acceptable: Byte;
    candidate: Types.PCharacter;
    { Unused in this version; see the other implementations of this routine. }
    i: Byte;
    creatureOk: Byte;
    team: Byte;

  { Picks the nearest suitable creature and accepts it when RateSpellTarget rates it above 0. }
  function PickSpellTarget: Boolean;
  var picked: Byte;
      friendly: Byte;
  begin
    picked := 0;
    acceptable := 1;
    friendly := Byte(GDConsts.spellTable[spellId].hostile = 0);
    if CbtActs.AcquireTarget(GDVars.currentCharacter, Magic.CalcSpellRange(spellId), 0, 1, friendly) then begin
      candidate := GDVars.currentCharacter^.combat^.target;
      if friendly <> 0 then
        team := Byte(GDVars.currentCharacter^.side)
      else
        team := Byte(CharHlp.EnemyTeam(GDVars.currentCharacter));
      acceptable := Byte(CbtActs.RateSpellTarget(candidate, spellId, team) > 0);
      if acceptable <> 0 then begin
        target.target := GDVars.currentCharacter^.combat^.target;
        target.x := CbtMap.CombatCellX(target.target);
        target.y := CbtMap.CombatCellY(target.target);
        picked := 1
      end
    end;
    PickSpellTarget := Boolean(picked)
  end;
begin
  found := 0;
  if aiControlled = 0 then begin
    creatureOk := Byte(spellId <> C_Spell.DIMENSION_DOOR);
    CbtActs.CombatAimMenu(GDVars.currentCharacter, Magic.CalcSpellRange(spellId), GDConsts.spellAimMode, groundOk,
                          creatureOk, found, target);
    GDVars.currentCharacter^.combat^.target := target.target
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
    GDVars.targetX := target.x;
    GDVars.targetY := target.y
  end else begin
    SelectSpellTarget := False;
    FillChar(target, SizeOf(target), 0)
  end
end;

function AimTargetMenu(character, target: Types.PCharacter; range, aimMode, emptyCellOk, creatureOk, targetOk, x,
                       y: Byte): Boolean; forward;

procedure ConfirmAttackTarget(character, target: Types.PCharacter; aiMode: Byte; var done: Byte;
                              var aim: Types.TAimResult); forward;

procedure ManualAimCursor(character, target: Types.PCharacter; range, aimMode, emptyCellOk, creatureOk: Byte;
                          var targetOk, accepted: Byte; var aim: Types.TAimResult; coordX, coordY: Byte); forward;

procedure SelectCombatTargets(spellId, aiMode: Byte; var outcome: Byte);
var
  total: Byte;
  count: Byte;
  scanIndex: Byte;
  budget: Byte;
  cost: Byte;
  { Unused in this version; see the other implementations of this routine. }
  candidateSlots: array[1..3] of Byte;
  target: Pointer;
  aim: Types.TAimResult absolute target;
  duplicate: Byte;
  stopped: Byte;
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
      budget := CharHlp.GetCasterLevel(C_Spell.FAERIE_FIRE)
    else
      budget := FxEngine.RollDice(2, 4);
    stopped := 0;
    repeat
      if CbtActs.SelectSpellTarget(spellId, aiMode, 0, aim) then begin
        duplicate := 0;
        for scanIndex := 1 to count do
          if GDVars.spellTargetState.targets[scanIndex] = target then duplicate := 1;
        if duplicate = 0 then begin
          Inc(count);
          GDVars.spellTargetState.targets[count] := target;
          GDVars.targetX := CbtMap.CombatCellX(target);
          GDVars.targetY := CbtMap.CombatCellY(target);
          Inc(GDVars.spellTargetState.count);
          if spellId <> C_Spell.FAERIE_FIRE then
            case Byte(GDVars.spellTargetState.targets[count]^.levelHighest) of
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
          if (count > 1) and (cost > budget) then stopped := 1
        end else begin
          if aiMode <> 0 then
            Dec(budget)
          else
            CharHlp.PrintBottomLine('Already been targeted')
        end;
        CbtMap.RedrawArenaCell(CbtMap.CombatCellX(target), CbtMap.CombatCellY(target))
      end else
        stopped := 1
    until (stopped <> 0) or (budget = 0)
  end;
  8..14: begin
    if CbtActs.SelectSpellTarget(spellId, aiMode, 1, aim) then begin
      Pathing.BuildTargetList(GDVars.targetX, GDVars.targetY, GDConsts.spellTable[spellId].targeting and $07,
                              GDConsts.combatTables.anyDirection,
                              1, GDVars.arena);
      for count := 1 to GDVars.targetCount do
        GDVars.spellTargetState.targets[count] := GDVars.creatures[GDVars.targetList[count].characterIndex];
      GDVars.spellTargetState.count := GDVars.targetCount;
      GDVars.areaSpellActive := 1
    end else
      outcome := 0
  end;
  15: begin
    if CbtActs.SelectSpellTarget(spellId, aiMode, 0, aim) then begin
      if GDVars.currentCharacter^.combat^.target <> nil then begin
        GDVars.spellTargetState.targets[1] := GDVars.currentCharacter^.combat^.target;
        GDVars.spellTargetState.count := 1
      end else begin
        Pathing.BuildTargetList(GDVars.targetX, GDVars.targetY, GDConsts.spellTable[spellId].targeting shr 4,
                                GDConsts.combatTables.anyDirection, 1, GDVars.arena);
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
      if CbtActs.SelectSpellTarget(spellId, aiMode, 0, aim) then begin
        duplicate := 0;
        for scanIndex := 1 to count do
          if GDVars.spellTargetState.targets[scanIndex] = target then duplicate := 1;
        if (spellId = C_Spell.HOLD_PERSON_CLERIC) or (spellId = C_Spell.HOLD_PERSON_MAGE) then
          if target = GDVars.currentCharacter then duplicate := 1;
        if duplicate = 0 then begin
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
var spell: Byte;
    outcomeByte: Byte absolute outcome;
    { Unused in this version; see the other implementations of this routine. }
    spellLevel: Byte;
    rounds: Byte;
    slot: Byte;
    wordOut: Word;
    byteOut: Byte;
    spellIndex: Integer absolute wordOut;
    hasSpells: Boolean absolute byteOut;
    caster: Types.PCharacter;
    entry: Types.PCharacter;
begin
  caster := GDVars.currentCharacter;
  byteOut := 1;
  wordOut := 65535;
  outcome := False;
  spell := spellId;
  if spell = 0 then
    spell := ViewChar.SpellMenu(0, 1, spellIndex, hasSpells);
  if spell > 0 then
    if GDConsts.spellTable[spell].combatOk = 0 then begin
      CharHlp.PrintBottomLine('Camp Only Spell');
      spell := 0
    end;
  if aiMode = 0 then begin
    CharHlp.DisplayCombatInterface;
    GDVars.showTurn := 1;
    GDVars.combatInfoDirty := 1;
    CbtMap.DisplayMapViewCentered(caster, 3, True);
    CharHlp.CombatPrintCreatureInfo(caster)
  end;
  if spell > 0 then begin
    rounds := GDConsts.spellTable[spell].castingTime div 3;
    if rounds = 0 then begin
      Magic.CastSpell(spell, aiMode, 1, outcomeByte);
      outcome := CharHlp.EndActions(caster)
    end else begin
      outcome := True;
      CharHlp.PrintCreatureMessage(caster, 'Begins Casting', 10, True);
      caster^.combat^.spellCast := spell;
      if caster^.combat^.initiative > rounds then
        Dec(caster^.combat^.initiative, rounds)
      else
        caster^.combat^.initiative := 1;
      slot := GDVars.turnIndex;
      entry := GDVars.combatOrder[slot + 1];
      while (entry <> nil) and
          ((entry^.combat^.initiative > caster^.combat^.initiative) or
           ((entry^.combat^.initiative = caster^.combat^.initiative) and
            (FxEngine.RollDice(1, 2) = 1))) do begin
        GDVars.combatOrder[slot] := entry;
        Inc(slot);
        entry := GDVars.combatOrder[slot + 1]
      end;
      GDVars.combatOrder[slot] := caster;
      Dec(GDVars.turnIndex);
      outcome := True
    end
  end
end;

function IsBackstab(attacker, defender: Types.PCharacter): Boolean;
var
  weapon: Types.PItem;
  { Unused in this version; see the other implementations of this routine. }
  armor: Types.PItem;
  weaponType: Byte;
  canBackstab: Boolean;
begin
  canBackstab := False;
  weapon := attacker^.equipped[0];
  if weapon <> nil then
    weaponType := weapon^.itemType;
  armor := attacker^.equipped[2];
  if attacker^.classLevels[C_Class.THIEF] > 0 then
    if (weapon = nil) or (weaponType = 67) or (weaponType = 3) or (weaponType = 4) or
        ((weaponType > 16) and (weaponType < 20)) then
      canBackstab := True;
  if canBackstab and (defender^.combat^.attacksTaken > 1) and (CharHlp.CalcDistance(attacker, defender) < 2) and
      ((defender^.iconDimensions and $7F) <= 1) and
      (CharHlp.DirTowardTarget(attacker, defender) = defender^.combat^.direction) then
    IsBackstab := True
  else
    IsBackstab := False
end;

procedure AnimateMissile(attacker, defender: Types.PCharacter;
                         weapon: Types.PItem);
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
  case weapon^.itemType of
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
  combatant: Types.PCharacter;
begin
  maximumTotal := 0;
  hitPointTotal := 0;
  combatant := GDVars.partyHead;
  while combatant <> nil do begin
    if Byte(combatant^.side) = 1 then begin
      if combatant^.enabled <> 0 then
        hitPointTotal := hitPointTotal + combatant^.hitPoints;
      maximumTotal := maximumTotal + combatant^.maxHitPoints
    end;
    combatant := combatant^.next
  end;
  if maximumTotal > 0 then
    GDVars.hostileHpPercent := ((20 * hitPointTotal) div maximumTotal) * 5
end;

function HighestEnemyMovement(creature: Types.PCharacter): Byte;
var
  highest: Byte;
  movement: Byte;
  combatant: Types.PCharacter;
begin
  highest := 0;
  combatant := GDVars.partyHead;
  while combatant <> nil do begin
    if (Byte(CharHlp.EnemyTeam(creature)) = Byte(combatant^.side)) and (combatant^.enabled <> 0) then begin
      movement := CharHlp.RecalcMovement(combatant) div 2;
      if movement > highest then highest := movement
    end;
    combatant := combatant^.next
  end;
  HighestEnemyMovement := highest
end;

function CheckAttackAlly(attacker, defender: Types.PCharacter): Boolean;
var
  { Unused in this version; see the other implementations of this routine. }
  combatant: Types.PCharacter;
begin
  if (Byte(CharHlp.EnemyTeam(defender)) = Byte(attacker^.side)) or (attacker^.quickFight <> 0) then
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
  optionCount: Byte;
  weapon: Types.PItem;
  distance: Word;
  { Unused in this version; see the other implementations of this routine. }
  reachable: Byte;
  savedDistMode: Byte;
  xSigned: ShortInt absolute x;
  ySigned: ShortInt absolute y;
begin
  distance := 255;
  savedDistMode := GDVars.arena^.distMode;
  GDVars.arena^.distMode := 1;
  reachable := Byte(Pathing.WalkLine(CbtMap.CombatCellX(character), CbtMap.CombatCellY(character), xSigned, ySigned,
                                     distance, GDVars.arena));
  GDVars.arena^.distMode := savedDistMode;
  distance := distance div 2;
  if aimMode <> GDConsts.spellAimMode then
    TextRend.DisplayString(0, 23, LightGreen, Black, GDConsts.rangeLabel + CharHlp.WordToString(distance) + '  ');
  FillChar(GDVars.enabledChoices, SizeOf(GDVars.enabledChoices), $FF);
  optionCount := 0;
  for index := 0 to 5 do begin
    if index = 3 then begin
      if (range >= distance) and (targetOk <> 0) then begin
        if aimMode = GDConsts.spellAimMode then
          MenuCore.AppendChoice(3, optionCount)
        else if character <> target then begin
          if not CharHlp.HasRangedWeapon(character) then
            MenuCore.AppendChoice(3, optionCount)
          else if CharHlp.FindDamagingRangedWeapon(character, weapon) then begin
            if (CharHlp.CountTargets(character, 1, False) = 0) or CharHlp.HasThrowableWeapon(character) then
              MenuCore.AppendChoice(3, optionCount)
          end
        end
      end
    end else
      MenuCore.AppendChoice(index, optionCount)
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
procedure ConfirmAttackTarget(character, target: Types.PCharacter; aiMode: Byte; var done: Byte;
                              var aim: Types.TAimResult);
var
  { Unused in this version; see the other implementations of this routine. }
  targetDir: Byte;
  thrown: Types.PItem;
begin
  thrown := nil;
  done := 1;
  if aiMode = GDConsts.attackAimMode then
    if not CbtActs.CheckAttackAlly(character, target) then done := 0;
  if done <> 0 then begin
    aim.target := target;
    aim.x := CbtMap.CombatCellX(target);
    aim.y := CbtMap.CombatCellY(target);
    GDVars.arena^.cursorOn := 0;
    CbtMap.ScrollView(GDVars.arena^.ox + 3, GDVars.arena^.oy + 3, 3, C_Dir.CENTER);
    if aiMode = GDConsts.attackAimMode then begin
      if CbtActs.SweepAttack(character, target) then
        done := Byte(CharHlp.EndActions(character))
      else begin
        CbtActs.NoteAttackDirection(character, target);
        if CharHlp.HasRangedWeapon(character) then
          if CharHlp.FindDamagingRangedWeapon(character, thrown) then
            if CharHlp.HasThrowableWeapon(character) then
              if CharHlp.CalcDistance(character, target) = 1 then thrown := nil;
        CbtActs.MakeAttack(character, target, 0, thrown, done)
      end
    end
  end else
    FillChar(aim, SizeOf(aim), 0)
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
procedure ManualAimCursor(character, target: Types.PCharacter; range, aimMode, emptyCellOk, creatureOk: Byte;
                          var targetOk, accepted: Byte; var aim: Types.TAimResult; coordX, coordY: Byte);
var
  optionCount: Byte;
  choice: Byte;
  weapon: Types.PItem;
  direction: Byte;
  index: Byte;
  mapX: Byte;
  mapY: Byte;
  creatureIndex: Byte;
  terrainIndex: Byte;
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
  FillChar(aim, SizeOf(aim), 0);
  GDVars.arena^.cursorOn := 1;
  GDVars.arena^.cursorSize := 1;
  choice := 255;
  direction := C_Dir.CENTER;
  GDVars.breathAim := 0;
  while choice > 1 do begin
    CbtMap.ScrollView(Byte(GDVars.cursorX), Byte(GDVars.cursorY), 2, direction);
    Inc(GDVars.cursorX, GDConsts.combatTables.directionX[direction]);
    Inc(GDVars.cursorY, GDConsts.combatTables.directionY[direction]);
    if GDVars.cursorX < 0 then GDVars.cursorX := 0;
    if GDVars.cursorY < 0 then GDVars.cursorY := 0;
    if GDVars.cursorX > 49 then GDVars.cursorX := 49;
    if GDVars.cursorY > 24 then GDVars.cursorY := 24;
    CbtMap.GetArenaContents(Byte(GDVars.cursorX), Byte(GDVars.cursorY), creatureIndex, terrainIndex);
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
      if creatureIndex > 0 then
        target := GDVars.creatures[creatureIndex]
      else if terrainIndex = C_Terr.TERRAIN_CORPSE then begin
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
    if (range < distance) or (GDConsts.combatTables.terrain[terrainIndex].cost = C_Terr.TERRAIN_IMPASSABLE) then
      targetOk := 0;
    if target <> nil then begin
      if (not CbtActs.CanTarget(character, target, 1)) or (creatureOk = 0) then
        targetOk := 0;
      if aimMode = GDConsts.attackAimMode then begin
        if (character = target) or ((creatureIndex = 0) and (terrainIndex = C_Terr.TERRAIN_CORPSE)) then
          targetOk := 0
        else if CharHlp.HasRangedWeapon(character) and
          ((not CharHlp.FindDamagingRangedWeapon(character, weapon)) or
           ((CharHlp.CountTargets(character, 1, False) > 0) and (not CharHlp.HasThrowableWeapon(character)))) then
          targetOk := 0
      end
    end else if emptyCellOk = 0 then
      targetOk := 0;
    FillChar(GDVars.enabledChoices, SizeOf(GDVars.enabledChoices), $FF);
    optionCount := 0;
    if targetOk <> 0 then MenuCore.AppendChoice(0, optionCount)
    else MenuCore.AppendChoice(1, optionCount);
    choice := MenuCore.MenuHorizontal(GDConsts.cursorPrompt, GDConsts.cursorMenu, 1, 0);
    if GDVars.menuExtendedKey <> 0 then begin
      case choice of
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
          FillChar(aim, SizeOf(aim), 0);
          aim.x := savedX;
          aim.y := savedY;
          CbtMap.ScrollView(savedX, savedY, 0, C_Dir.CENTER);
          GDVars.arena^.cursorOn := 0;
          CbtMap.RedrawArenaCell(savedX, savedY);
          GDVars.breathAim := 0;
          choice := 1
        end else direction := C_Dir.CENTER
      end
    end else begin
      case choice of
        0: begin
          accepted := 1;
          aim.x := Byte(GDVars.cursorX);
          aim.y := Byte(GDVars.cursorY);
          if target <> nil then
            aim.target := target
          else
            aim.target := nil;
          GDVars.arena^.cursorOn := 0;
          CbtMap.RedrawArenaCell(Byte(GDVars.cursorX), Byte(GDVars.cursorY));
          GDVars.breathAim := 0
        end;
        1: begin
          accepted := 0;
          CbtMap.RedrawArenaCell(Byte(GDVars.cursorX), Byte(GDVars.cursorY));
          FillChar(aim, SizeOf(aim), 0);
          aim.x := savedX;
          aim.y := savedY;
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

procedure CombatAimMenu(character: Types.PCharacter; range, aimMode, emptyCellOk, creatureOk: Byte; var done: Byte;
                        var aim: Types.TAimResult);
var aimList: TTargetEntryList;
    weaponRange: Byte;
    listCount: Byte;
    selectedIndex: Byte;
    { Unused in this version; see the other implementations of this routine. }
    skipStep: Byte;
    oldX: ShortInt;
    oldY: ShortInt;
    newX: ShortInt;
    newY: ShortInt;
    selected: Types.PCharacter;
    choice: Byte;
    targetOk: Byte;
    accepted: Byte;
    stop: Byte;
    currentX: ShortInt;
    currentY: ShortInt;
    originalX: ShortInt;
    originalY: ShortInt;
    { Unused in this version; see the other implementations of this routine. }
    originalFacing: Byte;

  { Moves the selection by delta through the aim list, wrapping, and returns the creature selected. }
  function AdvanceAimTarget(delta: ShortInt): Types.PCharacter;
  var
    previousTarget: Types.PCharacter;
    nextTarget: Types.PCharacter;
  begin
    previousTarget := GDVars.creatures[aimList[selectedIndex].characterIndex];
    if previousTarget = nil then previousTarget := character;
    if listCount < 1 then GameIo.ExitGame;
    oldX := GDVars.arenaLoc[aimList[selectedIndex].characterIndex].x;
    oldY := GDVars.arenaLoc[aimList[selectedIndex].characterIndex].y;
    Inc(selectedIndex, delta);
    if selectedIndex = 0 then selectedIndex := listCount;
    if selectedIndex > listCount then selectedIndex := 1;
    nextTarget := GDVars.creatures[aimList[selectedIndex].characterIndex];
    newX := GDVars.arenaLoc[aimList[selectedIndex].characterIndex].x;
    newY := GDVars.arenaLoc[aimList[selectedIndex].characterIndex].y;
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
      candidate: Types.PCharacter;
  begin
    selectedIndex := 1;
    Pathing.BuildTargetList(CbtMap.CombatCellX(character), CbtMap.CombatCellY(character), 255,
                            GDConsts.combatTables.anyDirection, CbtMap.GetIconSize(character), GDVars.arena);
    listCount := 0;
    for index := 1 to GDVars.targetCount do begin
      candidate := GDVars.creatures[GDVars.targetList[index].characterIndex];
      if CbtActs.CanTarget(character, candidate, 0) then begin
        Inc(listCount);
        aimList[listCount] := GDVars.targetList[index];
        if candidate = character^.combat^.target then
          selectedIndex := listCount
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
  FillChar(aim, SizeOf(aim), 0);
  done := 0;
  weaponRange := range;
  if weaponRange = 255 then begin
    if character^.equipped[0] <> nil then
      weaponRange := GDVars.baseItems[character^.equipped[0]^.itemType].range
    else
      weaponRange := 1
  end;
  if (weaponRange = 0) or (weaponRange = 255) then weaponRange := 1;
  originalX := CbtMap.CombatCellX(character);
  originalY := CbtMap.CombatCellY(character);
  CbtMap.RedrawArenaCell(originalX, originalY);
  BuildAimTargets;
  currentX := CbtMap.CombatCellX(selected);
  currentY := CbtMap.CombatCellY(selected);
  targetOk := 1;
  stop := 0;
  while stop = 0 do begin
    choice := Byte(CbtActs.AimTargetMenu(character, selected, weaponRange, aimMode, emptyCellOk, creatureOk, targetOk,
                                         currentX, currentY));
    if GDVars.menuExtendedKey = 0 then begin
      case choice of
        0: begin targetOk := 1; selected := AdvanceAimTarget(1) end;
        1: begin targetOk := 1; selected := AdvanceAimTarget(-1) end;
        2: begin
          CbtActs.ManualAimCursor(character, selected, weaponRange, aimMode, emptyCellOk, creatureOk, targetOk,
                                  accepted, aim, currentX, currentY);
          selected := aim.target;
          currentX := aim.x;
          currentY := aim.y;
          if (targetOk <> 0) and (accepted <> 0) then begin
            choice := 3;
            stop := 1;
            GDVars.selectedChoice := 4;
            if selected <> nil then
              aim.target := selected
            else
              aim.target := nil;
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
          aim.x := currentX;
          aim.y := currentY;
          if selected <> nil then
            aim.target := selected
          else
            aim.target := nil;
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
    end else if choice = Ord(C_Keys.ESCAPE) then begin
      GDVars.arena^.cursorOn := 0;
      CbtMap.RedrawArenaCell(currentX, currentY);
      CbtMap.ScrollView(originalX, originalY, 0, C_Dir.CENTER);
      choice := 5;
      stop := 1
    end;
    if (choice in [0, 1, 3]) and (selected <> nil) then begin
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
  local.target := character^.combat^.target;
  if (dropCurrent <> 0) or
      ((local.target <> nil) and
       ((local.target^.side = character^.side) or (local.target^.enabled = 0) or
        (not CbtActs.CanTarget(character, local.target, allies)))) then
    character^.combat^.target := nil;
  if character^.combat^.target <> nil then
    local.accepted := 1;
  while (local.accepted = 0) and (local.lastRetry = 0) do begin
    local.lastRetry := local.retry;
    if (local.retry <> 0) and (dropCurrent = 0) then
      GDVars.arena^.distMode := 1;
    local.attempts := 20;
    local.count := CharHlp.CountTargets(character, range, Boolean(allies));
    while (local.attempts > 0) and (local.accepted = 0) and (local.count > 0) do begin
      Dec(local.attempts);
      if CharHlp.HasEffect(character, 91,
                           local.effect) and (GDVars.creatures[GDVars.targetIndices[1]] = GDVars.yellTarget) and
          (local.attempts = 19) then
        local.choice := 1
      else
        local.choice := FxEngine.RollDice(1, local.count);
      if GDVars.targetIndices[local.choice] > 0 then begin
        local.target := GDVars.creatures[GDVars.targetIndices[local.choice]];
        if ((anyReachable <> 0) and (GDVars.arena^.distMode <> 0)) or CbtActs.CanTarget(character, local.target,
            allies) then begin
          local.accepted := 1;
          character^.combat^.target := local.target
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
  current: Types.PCharacter;
begin
  VictoryCheat := False;
  if ParamStr(2) <> GDVars.debugPassword then Exit;
  VictoryCheat := True;
  CharHlp.PrintBottomLine('The Gods intervene!');
  current := GDVars.partyHead;
  while current <> nil do begin
    if Byte(current^.side) = 1 then begin
      current^.enabled := 0;
      current^.status := C_Status.DEAD_STATUS;
      GDVars.arenaLoc[CbtMap.CombatSlot(current)].size := 0
    end;
    completed := CharHlp.EndActions(current);
    current := current^.next
  end;
  CbtMap.ScrollView(GDVars.arena^.ox + 3, GDVars.arena^.oy + 3, 255, C_Dir.CENTER)
end;

function RateSpellTarget(candidate: Types.PCharacter; spellId, team: Byte): ShortInt;
var score: ShortInt;
    effect: Types.PEffect;
    level: ShortInt;
    effectId: Byte;
begin
  RateSpellTarget := 0;
  if Byte(candidate^.side) <> team then begin
    RateSpellTarget := -10;
    Exit
  end;
  score := 0;
  effectId := GDConsts.spellTable[spellId].effectId;
  case spellId of
  C_Spell.BLESS_GIFT, C_Spell.BLESS_CLERIC: begin
    if not CharHlp.HasEffect(candidate, C_Effect.BLESS, effect) then
      if CharHlp.CountTargets(candidate, 1, False) = 0 then score := 1
  end;
  C_Spell.PRAYER: begin
    if not CharHlp.HasEffect(GDVars.currentCharacter, C_Effect.PRAYER, effect) then score := 1
  end;
  C_Spell.CURE_LIGHT_WOUNDS, C_Spell.CURE_SERIOUS_WOUNDS, C_Spell.CURE_CRITICAL_WOUNDS,
    C_Spell.HEAL: begin
    if Byte(candidate^.maxHitPoints > candidate^.hitPoints) <> 0 then score := 1
  end;
  C_Spell.CHARM_PERSON_MAMMAL: begin
    if Byte((candidate^.race < C_Race.MONSTER) or ((candidate^.typeFlags and $10) <> 0)) <> 0 then
      score := 1
  end;
  C_Spell.CHARM_PERSON_GIFT, C_Spell.CHARM_PERSON_MAGE: begin
    if ((candidate^.typeFlags and $02) <> 0) or (Byte(candidate^.iconDimensions = 1) <> 0) then score := 1
  end;
  65, C_Spell.MAGIC_MISSILE: begin
    if not CharHlp.HasEffect(candidate, C_Effect.SHIELD, effect) then score := 1
  end;
  C_Spell.SLEEP: begin
    if Byte(candidate^.levelHighest < 5) <> 0 then
      if not CharHlp.HasEffect(candidate, C_Effect.IMMUNE_CHARM_SLEEP, effect) then
        if not CharHlp.HasEffect(candidate, C_Effect.SLEEP, effect) then score := 1
  end;
  C_Spell.HOLD_PERSON_CLERIC, C_Spell.HOLD_PERSON_MAGE: begin
    if Byte(candidate^.race < C_Race.MONSTER) <> 0 then
      if not CharHlp.HasEffect(candidate, C_Effect.IMMUNE_HOLD, effect) then
        if not CharHlp.HasEffect(candidate, C_Effect.HELD, effect) then score := 1
  end;
  C_Spell.CURE_BLINDNESS: begin
    if CharHlp.HasEffect(candidate, C_Effect.BLIND, effect) then score := 1
  end;
  C_Spell.REMOVE_CURSE_GIFT, C_Spell.REMOVE_CURSE_CLERIC: begin
    if CharHlp.HasEffect(candidate, C_Effect.CURSED, effect) then score := 1
  end;
  C_Spell.FIREBALL, 64, C_Spell.FLAME_STRIKE, C_Spell.DELAY_BLAST_FIREBALL: begin
    if CharHlp.HasEffect(candidate, C_Effect.HEALED_BY_FIRE, effect) then score := -10
    else score := 1
  end;
  C_Spell.LIGHTNING_BOLT: begin
    if not CharHlp.HasEffect(candidate, C_Effect.IMMUNE_ELECTRICITY, effect) then score := 1
  end;
  C_Spell.SLAY_LIVING, C_Spell.DEATH_SPELL: begin
    if (candidate^.immunityFlags and $08) = 0 then score := 1
  end;
  61: begin
    if not CharHlp.HasEffect(candidate, C_Effect.IMMUNE_HOLD, effect) then score := 1
  end;
  C_Spell.POISON: begin
    if not CharHlp.HasEffect(candidate, C_Effect.IMMUNE_POISON_HOLD, effect) then score := 1
  end;
  C_Spell.MASS_CHARM, C_Spell.CHARM_MONSTERS: begin
    if (candidate^.typeFlags and $02) <> 0 then score := 1
  end;
  C_Spell.CONFUSION: begin
    if not CharHlp.HasEffect(candidate, C_Effect.IMMUNE_CONFUSION, effect) then score := 1
  end;
  C_Spell.FEAR: begin
    if not CharHlp.HasEffect(candidate, C_Effect.IMMUNE_FEAR, effect) then score := 1
  end;
  C_Spell.CLOUDKILL: begin
    if candidate^.levelHighest < 6 then score := 1
  end;
  C_Spell.HOLD_MONSTERS: begin
    if not CharHlp.HasEffect(candidate, C_Effect.IMMUNE_HOLD, effect) then score := 1
  end;
  else begin
    if effectId = 0 then
      score := 1
    else if Byte(not CharHlp.HasEffect(candidate, effectId, effect)) <> 0 then
      score := 1
  end
  end;
  level := GDConsts.spellTable[spellId].level;
  if score > 0 then begin
    if level < 5 then
      if CharHlp.HasEffect(candidate, C_Effect.MAJOR_GLOBE, effect) then score := 0;
    if level < 4 then
      if CharHlp.HasEffect(candidate, C_Effect.MINOR_GLOBE, effect) then score := 0;
    if candidate^.spellResistance > 50 then score := 0
  end;
  RateSpellTarget := score
end;

function RateSpell(character: Types.PCharacter; spellId: Byte): Byte;
var score: ShortInt;
    team: Byte;
    index: Byte;
    count: Byte;
    range: Byte;
    { Unused in this version; see the other implementations of this routine. }
    bestScore: Word;
begin
  RateSpell := 0;
  if GDConsts.spellTable[spellId].hostile = 0 then
    team := Byte(character^.side)
  else
    team := Byte(CharHlp.EnemyTeam(character));
  if GDConsts.spellTable[spellId].targeting = 0 then
    score := CbtActs.RateSpellTarget(character, spellId, team)
  else begin
    range := Magic.CalcSpellRange(spellId);
    Pathing.BuildTargetList(CbtMap.CombatCellX(character), CbtMap.CombatCellY(character), range,
                            GDConsts.combatTables.anyDirection, CbtMap.GetIconSize(character), GDVars.arena);
    count := GDVars.targetCount;
    index := 1;
    score := 0;
    if count > 0 then
      while (index <= count) and (score <= 0) do begin
        score := CbtActs.RateSpellTarget(GDVars.creatures[GDVars.targetList[index].characterIndex], spellId, team);
        Inc(index)
      end
  end;
  RateSpell := score
end;

function AimAreaSpell(spellId: Byte; var aim: Types.TAimResult): Byte;
var grid: PAimScoreGrid;
    radius: Byte;
    outerRange: Byte;
    innerRange: Byte;
    { Unused in this version; see the other implementations of this routine. }
    savedTarget: array[1..4] of Byte;
    current: Types.PCharacter;
    baseX: ShortInt;
    baseY: ShortInt;
    candidateX: ShortInt;
    candidateY: ShortInt;
    bestDx: ShortInt;
    bestDy: ShortInt;
    casterX: ShortInt;
    casterY: ShortInt;
    x: ShortInt;
    y: ShortInt;
    minX: ShortInt;
    maxX: ShortInt;
    minY: ShortInt;
    maxY: ShortInt;
    score: ShortInt;
    bestScore: ShortInt;
    bounds: TAimBounds;
    { Unused in this version; see the other implementations of this routine. }
    gridMinY: Byte;
    distance: Word;
    { Unused in this version; see the other implementations of this routine. }
    cellScores: array[1..8] of Byte;
    team: Byte;
begin
  if GDConsts.spellTable[spellId].hostile = 0 then
    team := Byte(GDVars.currentCharacter^.side)
  else
    team := Byte(CharHlp.EnemyTeam(GDVars.currentCharacter));
  AimAreaSpell := 0;
  radius := GDConsts.spellTable[spellId].targeting - 8;
  if ((spellId = C_Spell.FIREBALL) or (spellId = C_Spell.DELAY_BLAST_FIREBALL)) and
      (GDVars.zone0^.inDungeon = 0) then Dec(radius);
  current := nil;
  outerRange := Magic.CalcSpellRange(spellId) + radius;
  if outerRange > 9 then begin
    outerRange := 9;
    current := GDVars.currentCharacter^.combat^.target
  end;
  innerRange := outerRange - radius;
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
    if (current^.enabled <> 0) and (candidateX >= bounds.outerMinX) and (candidateX <= bounds.outerMaxX) and
        (candidateY >= bounds.outerMinY) and (candidateY <= bounds.outerMaxY) then begin
      score := CbtActs.RateSpellTarget(current, spellId, team);
      minY := -radius;
      maxY := radius;
      if minY + candidateY < bounds.innerMinY then
        minY := bounds.innerMinY - candidateY;
      if maxY + candidateY > bounds.innerMaxY then
        maxY := bounds.innerMaxY - candidateY;
      for y := minY to maxY do begin
        minX := candidateX - GDConsts.areaHalfWidths[y, radius];
        maxX := candidateX + GDConsts.areaHalfWidths[y, radius];
        if minX < bounds.innerMinX then minX := bounds.innerMinX;
        if maxX > bounds.innerMaxX then maxX := bounds.innerMaxX;
        for x := minX to maxX do
          Inc(grid^[x - baseX, y + candidateY - baseY], score)
      end
    end;
    current := current^.next
  end;
  casterX := ShortInt(CbtMap.CombatCellX(GDVars.currentCharacter));
  casterY := ShortInt(CbtMap.CombatCellY(GDVars.currentCharacter));
  bestScore := 0;
  for x := -innerRange to innerRange do
    for y := -innerRange to innerRange do begin
      score := grid^[x, y];
      if (score > bestScore) or ((score = bestScore) and (score > 0) and CharHlp.PercentileRoll(25)) then begin
        candidateX := casterX;
        candidateY := casterY;
        distance := Magic.CalcSpellRange(spellId);
        if (baseX + x >= 0) and (baseX + x <= 49) and (baseY + y >= 0) and (baseY + y < 24) then
          if Pathing.WalkLine(baseX + x, baseY + y, candidateX, candidateY, distance, GDVars.arena) then begin
            bestDx := x;
            bestDy := y;
            bestScore := score
          end
      end
    end;
  aim.target := nil;
  if bestScore > 0 then begin
    AimAreaSpell := 1;
    aim.x := Byte(bestDx + baseX);
    aim.y := Byte(bestDy + baseY)
  end else begin
    AimAreaSpell := 0;
    aim.target := nil
  end;
  FreeMem(grid, SizeOf(TAimScoreGrid))
end;

procedure UseLeadership;
var
  leader: Types.PCharacter;
  candidate: Types.PCharacter;
  shown: Byte;
  { Unused in this version; see the other implementations of this routine. }
  effect: Types.PEffect;

  { Rolls a knight's leadership: 1 when d100 is under its order's base plus its charisma bonus. }
  function LeadershipRoll(knight: Types.PCharacter): Byte;
  var
    bonus: Byte;
    base: Byte;
  begin
    case knight^.knightOrder of
      1: base := 20;
      2: base := 40;
      3: base := 80
    end;
    if knight^.stats[C_Stat.CHARISMA].current > 13 then
      bonus := (knight^.stats[C_Stat.CHARISMA].current - 13) * 5
    else
      bonus := 0;
    if base + bonus > FxEngine.RollDice(1, 100) then
      LeadershipRoll := 1
    else
      LeadershipRoll := 0
  end;
begin
  shown := 0;
  candidate := GDVars.partyHead;
  while candidate <> nil do begin
    if candidate^.side = C_Side.PLAYER then
      candidate^.quickFight := Byte(candidate^.npc > $7F)
    else
      candidate^.quickFight := 1;
    candidate := candidate^.next
  end;
  leader := GDVars.partyHead;
  while leader <> nil do begin
    if (leader^.side = C_Side.PLAYER) and (leader^.npc <= $7F) and
        (leader^.classLevels[C_Class.KNIGHT] > 0) and (leader^.status = C_Status.OKAY) then begin
      candidate := GDVars.partyHead;
      while candidate <> nil do begin
        if (candidate^.side = C_Side.PLAYER) and (candidate^.npc > $7F) and (candidate^.quickFight <> 0) and
            (candidate^.status = C_Status.OKAY) and (candidate^.stats[C_Stat.INTELLIGENCE].current > 3) then begin
          if LeadershipRoll(leader) <> 0 then begin
            if shown = 0 then begin
              shown := 1;
              Border.DrawWindowFrame(0);
              TextRend.DisplayMessageWindow(1, 1, 38, 22, LightMagenta, Black, True, '  Using leadership ability ');
              TextRend.DisplayMessageWindow(1, 3, 38, 22, White, Black, True,
                                            leader^.name + ' leads ' + candidate^.name + '.')
            end;
            candidate^.quickFight := 0
          end
        end;
        candidate := candidate^.next
      end
    end;
    leader := leader^.next
  end;
  if shown <> 0 then
    TextRend.DisplayAndPause(LightMagenta, Black, GDConsts.pressToContinue)
end;
begin
end.
