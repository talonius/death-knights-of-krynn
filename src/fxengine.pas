{ FxEngine -- effects and the dice: adding, triggering and removing a character's effects through effectServices'
  handler table, attack rolls and saving throws, damage that is not from a weapon, healing, putting a creature out of
  the fight or killing it, stat recalculation from items and effects, and the spell clouds' countdown. }
{$F+,O+,S-,R-,V-,B-,I-}
unit FxEngine;
interface
uses C_Class, C_Cond, C_Dir, C_Effect, C_Ifc, C_Npc, C_Side, C_Stat, C_Status, C_Terr, GDConsts, GDVars,
  CharHlp, CbtMap, TextRend, Blit, Pathing, Types;

{ Prints a message after a creature's name. Unless the creature is already stoned, dead or gone, it then gives it the
  status, takes it out of play at 0 hit points, removes its effects that end at 0 hit points, runs its condition-13
  (going down) effects, marks it downed on the combat map when those effects leave it out of play and it has not
  exploded, pauses, clears the message window and, outside combat, redraws the party.
  @param(character Creature being killed.)
  @param(status Status to give it.)
  @param(message Message printed after its name.) }
procedure KillCreature(character: Types.PCharacter; status: Byte; message: Types.TString40);

{ Calls an effect's handler, or the override handler instead while an override is active.
  @param(effectId Effect whose handler is called.)
  @param(character Creature the effect acts on.)
  @param(effect Node of the effect, passed on to the handler; may be nil.)
  @param(removed True when the call is for the effect's removal.) }
procedure CallEffectHandler(effectId: Byte; var character; effect: Pointer; removed: Boolean);

{ Unlinks an effect node from a creature's effect list and frees it, calling the effect's handler first when the node
  asks for it on removal. Removing Friends recalculates Charisma; removing Enlarge or Strength recalculates Strength.
  @param(character Creature whose effect is removed.)
  @param(effectId Effect looked for when no node is given; it also selects the handler and the ability recalculated.)
  @param(effect Node to remove, or nil for the creature's first copy of the effect; nothing happens when there is
  none.) }
procedure RemoveEffect(character: Types.PCharacter; effectId: Byte; effect: Types.PEffect);

{ Runs the handlers of the effects that answer to condition (1..21) on character; conditions 6 and 9 check spell
  resistance first.
  @param(condition The condition, 1..21.)
  @param(character The creature.) }
procedure TriggerEffectsWithCondition(condition: Byte; var character);

{ A creature standing in a cloud (when terrain is set): unless undead or protected by 31 or 99, coughing (30, losing its
  spell) if it saves, nausea (31) if not. In a deadly cloud: level 4 or below dies of poison, level 5 unless it saves at
  -4, level 6 unless it saves.
  @param(character The creature.)
  @param(terrain Non-zero when it stands in a cloud.) }
procedure ConsiderTerrainEffects(character: Types.PCharacter; terrain: Byte);

{ Rolls an attack that has no attacking creature: a d20, where 1 always misses and 20 counts as 100, adjusted by the
  defender's condition-16 effects.
  @param(defender Creature attacked.)
  @param(target The attack's to-hit value, 60 minus its THAC0.)
  @returns(True when the adjusted roll is not negative and the roll plus the to-hit value exceeds the defender's armor
    class.) }
function AttackRollNoAttacker(defender: Types.PCharacter; target: Byte): Boolean;

{ Rolls an attack by one creature on another. Makes the attacker visible, rolls a d20 (1 always misses, 20 counts as
  100), runs the attacker's condition-10 and the defender's condition-16 effects, and adds the to-hit modifier zone 1
  holds for the attacker's side. Note: the party's light-level adjustment selects on a constant that matches none of its
  cases, so it never applies.
  @param(attacker Creature attacking.)
  @param(defender Creature attacked.)
  @param(target Value the attack must reach, 60 minus the defender's armor class.)
  @returns(True when the adjusted roll is not negative and the roll plus the attacker's THAC0 adjustment and the
    modifier reaches the value needed.) }
function AttackRoll(attacker, defender: Types.PCharacter; target: Byte): Boolean;

{ A saving throw of type saveType: effect 57 makes the roll 1; 1 fails and 20 succeeds; otherwise d20 + save bonus
  + modifier (a mage of a robe order -1 or +1 by its moon's phase), after condition 12, against the save.
  @param(character The creature.)
  @param(saveType Saving throw, 0..4.)
  @param(modifier Bonus added to the roll.)
  @returns(True when the throw succeeds.) }
function RollSavingThrow(character: Types.PCharacter; saveType, modifier: Byte): Boolean;

{ Rolls a number of dice and adds them up.
  @param(count Number of dice; 0 rolls nothing.)
  @param(sides Faces per die.)
  @returns(The sum, kept in a Byte, so a total above 255 wraps.) }
function RollDice(count, sides: Byte): Byte;

{ Rolls damage dice, recording the number of dice for the resistances.
  @param(count Number of dice.)
  @param(sides Faces per die.)
  @returns(The sum, as RollDice returns it.) }
function RollDamageDice(count, sides: Byte): Byte;

{ Adds an effect node to the end of a creature's effect list. It neither checks for a node already there nor calls the
  effect's handler.
  @param(character The creature.)
  @param(effectId The effect.)
  @param(minutes Its duration in minutes; 0 for a permanent effect.)
  @param(strength Its strength.)
  @param(onRemove True to call the effect's handler when it is removed.) }
procedure AddEffect(character: Types.PCharacter; effectId: Byte; minutes: Word; strength: Byte; onRemove: Boolean);

{ Takes an enabled creature out of play: centers the map on it, prints a message after its name, disables it and sets
  its status. Its hit points drop to 0 unless it fled (running). Its icon is erased from the combat map and taken off
  the arena, and when its actions end the effects that end at 0 hit points are removed.
  @param(character The creature.)
  @param(status Its new status.)
  @param(message The message.) }
procedure PutOutOfPlayWithStatus(character: Types.PCharacter; status: Byte; message: Types.TString40);

{ Removes each invisibility node from a creature.
  @param(character The creature.) }
procedure RemoveInvisibility(character: Types.PCharacter);

{ Removes one copy of each of the sixteen effects that end when a creature goes down. A creature that still has the
  Berserk effect afterwards and is marked as an animated player character returns to the party's side.
  @param(character Creature that went down.) }
procedure RemoveEffectsHp0(character: Types.PCharacter);

{ Empty: no effects end with combat AI control.
  @param(character Unused.) }
procedure RemoveAiEffects(character: Types.PCharacter);

{ Cures a creature of an effect: when it has the effect, prints that it is cured and removes the node.
  @param(character The creature.)
  @param(effectId The effect.)
  @returns(True when the creature had the effect.) }
function RemoveEffectWithMessage(character: Types.PCharacter; effectId: Byte): Boolean;

{ Tells whether a Strength beats a creature's permanent one: a higher base Strength, or 18 with an exceptional Strength
  above its permanent exceptional Strength.
  @param(character Creature compared against.)
  @param(baseStrength Candidate base Strength.)
  @param(exceptional Candidate exceptional Strength.)
  @param(effectStrength Receives the candidate's effect encoding when it is better; unchanged otherwise.)
  @returns(True when the candidate is better.) }
function AdjustForNewStrength(character: Types.PCharacter; baseStrength, exceptional: Byte;
                              var effectStrength: Byte): Boolean;

{ Applies damage, reduced by spell resistance (condition 6), by reduction (1 none, 2 half) when saved, or condition 20
  when not; prints it with its element, interrupts a spell being cast, and reports a creature going down, dying or
  killed.
  @param(character The creature.)
  @param(damage Damage before reduction.)
  @param(reduction 1 none, 2 half, when saved.)
  @param(saved True when the creature saved.) }
procedure InflictNonWeaponDamage(character: Types.PCharacter; damage, reduction: Byte; saved: Boolean);

{ Applies an effect to a creature unless its condition-9 effects block it or a save negates it; then "is Unaffected" is
  printed instead. The creature's first copy of the effect, when it has time left, is replaced. The message, when not
  empty, is printed.
  @param(character Creature given the effect.)
  @param(effectId Effect to add.)
  @param(minutes Duration.)
  @param(strength Effect strength, read by its handler.)
  @param(onRemove Set to call the effect's handler when it is removed.)
  @param(saveNegates True (1) when a successful save cancels the effect.)
  @param(saved Set when the creature made its saving throw.)
  @param(message Message printed after its name, or empty.) }
procedure AddEffectWithMessage(character: Types.PCharacter; effectId: Byte; minutes: Word; strength: Byte; onRemove,
                               saveNegates, saved: Byte; message: Types.TString40);

{ Heals a creature that is okay, animated, unconscious or dying by the given hit points, capped at its maximum; when the
  flag is set, a creature already at its maximum is left alone. A healed creature out of play goes from dying to
  unconscious, and an unconscious one outside combat comes back into play okay. Note: the sum of the current and
  restored hit points is kept in a Byte, so a total above 255 wraps before the cap applies.
  @param(character Creature healed.)
  @param(hitPoints Hit points to restore.)
  @param(showMessage Set to leave a creature at its maximum unhealed.)
  @returns(True when it healed.) }
function RestoreHitPoints(character: Types.PCharacter; hitPoints: Byte; showMessage: Boolean): Boolean;

{ Recalculates an ability score (0 strength, 3 dexterity, 4 constitution, 5 charisma) from its base, the equipped magic
  items and the effects that change it; for constitution also the maximum hit points from the constitution bonus per
  class level, averaged over the classes, and effect 62 at 20 or more.
  @param(character The creature.)
  @param(stat The stat to recalculate.) }
procedure RecalcAbility(character: Types.PCharacter; stat: ShortInt);

{ Carries out the kender's yell: the yeller becomes the yell target, and each okay creature with Intelligence above 3 on
  another side that is not helpless and fails a saving throw (type 4) is taunted and "wants to kill" the yeller.
  @param(character The kender yelling.) }
procedure YellTaunt(character: Types.PCharacter);

{ Removes expired terrain patches (stinking clouds and the like) from the combat map, putting back the terrain they
  covered, or the occupied marker where a downed creature lies. Remaining patches are then repainted and the change
  announced.
  @param(immediate Set to remove only patches already marked expired, as dispelling does; clear to count each patch down
    and remove it when its time runs out.) }
procedure CountDownAreaEffects(immediate: Boolean);
implementation
const
  { The conditions TriggerEffectsWithCondition checks effects under. }
  COND_DAMAGE_TAKEN = 6;
  COND_ATTACK_ROLL_ATT = 10;
  COND_SAVING_THROW = 12;
  COND_ATTACK_ROLL_DEF = 16;
  COND_DAMAGE_NOT_SAVED = 20;

procedure YellTaunt(character: Types.PCharacter);
var candidate: Types.PCharacter;
begin
  GDVars.yellTarget := character;
  candidate := GDVars.partyHead;
  while candidate <> nil do begin
    if (candidate^.status = C_Status.OKAY) and (candidate^.stats[C_Stat.INTELLIGENCE].current > 3) and
        (candidate^.side <> Types.PCharacter(character)^.side) and (not CharHlp.IsHelpless(candidate)) and
        (not FxEngine.RollSavingThrow(candidate, 4, 0)) then begin
      FxEngine.AddEffectWithMessage(candidate, 91, 0, 255, 0, 0, 0,
                                    GDConsts.wantsToKill + Types.PCharacter(character)^.name)
    end;
    candidate := candidate^.next
  end
end;

procedure KillCreature(character: Types.PCharacter; status: Byte; message: Types.TString40);
begin
  CharHlp.PrintCreatureMessage(character, message, 10, False);
  case Types.PCharacter(character)^.status of
    C_Status.STONED, C_Status.DEAD_STATUS, C_Status.GONE: ;
  else begin
    Types.PCharacter(character)^.status := status;
    Types.PCharacter(character)^.enabled := 0;
    Types.PCharacter(character)^.hitPoints := 0;
    FxEngine.RemoveEffectsHp0(character);
    FxEngine.TriggerEffectsWithCondition(C_Cond.HIT_POINTS_ZERO, character);
    if (Types.PCharacter(character)^.enabled = 0) and (Types.PCharacter(character)^.status <> 10) then
      CbtMap.CreatureDowned(character);
    TextRend.PauseOnly;
    CharHlp.ClearMessageWindow;
    if GDVars.interfaceState <> C_Ifc.IN_COMBAT then
      CharHlp.DisplayParty(GDVars.currentCharacter)
  end
  end
end;

procedure CallEffectHandler(effectId: Byte; var character; effect: Pointer; removed: Boolean);
begin
  if GDVars.handlerOverrideActive <> 0 then
    GDVars.effectServices.itemHandler(character, effect, removed)
  else
    GDVars.effectServices.handlers[effectId](character, effect, removed)
end;

procedure RemoveEffect(character: Types.PCharacter; effectId: Byte; effect: Types.PEffect);
var
  previous: Types.PEffect;
  node: Types.PEffect;
begin
  node := effect;
  if node = nil then begin
    node := Types.PCharacter(character)^.effects;
    while (node <> nil) and (node^.effectId <> effectId) do
      node := node^.next
  end;
  if node = nil then Exit;
  if node^.onRemove <> 0 then
    FxEngine.CallEffectHandler(effectId, character, node, True);
  if Types.PCharacter(character)^.effects = node then
    Types.PCharacter(character)^.effects := node^.next
  else begin
    previous := Types.PCharacter(character)^.effects;
    while (previous <> nil) and (previous^.next <> node) do
      previous := previous^.next;
    previous^.next := node^.next
  end;
  FreeMem(node, SizeOf(Types.TEffect));
  if effectId = C_Effect.FRIENDS then
    FxEngine.RecalcAbility(character, C_Stat.CHARISMA);
  if (effectId = C_Effect.ENLARGE) or (effectId = C_Effect.STRENGTH) then
    FxEngine.RecalcAbility(character, C_Stat.STRENGTH)
end;

{ Fires one effect on a creature: calls its handler when the creature has the effect, or, for the aura effects Silence
  15', Protection from Evil 10', Protection from Good 10' and Prayer, when a creature carrying it has this one in range
  (6 cells for Prayer, else 1; outside combat any carrier counts). The handler gets the node found: the creature's own,
  or the carrier's for an aura. The range test builds a target list, and the caller's target list is kept around it.
  @param(character The creature.)
  @param(effectId The effect.) }
procedure TriggerEffect(var character; effectId: Byte);
var savedTargets: array[0..215] of Byte;
    candidate: Types.PCharacter;
    effect: Types.PEffect;
    effectArg: Pointer absolute effect;
    found: Boolean;
    index: Byte;
    range: Byte;
begin
  found := False;
  candidate := GDVars.partyHead;
  if CharHlp.HasEffect(Types.PCharacter(character), effectId, effectArg) then
    found := True
  else if effectId in [C_Effect.SILENCE, C_Effect.PROTECTION_FROM_EVIL_RADIUS, 46, C_Effect.PRAYER] then begin
    Move(GDVars.targetList, savedTargets, SizeOf(savedTargets));
    while (candidate <> nil) and (not found) do begin
      if CharHlp.HasEffect(candidate, effectId, effectArg) then begin
        if GDVars.interfaceState = C_Ifc.IN_COMBAT then begin
          if effectId = C_Effect.PRAYER then range := 6 else range := 1;
          Pathing.BuildTargetList
            (CbtMap.CombatCellX(candidate), CbtMap.CombatCellY(candidate), range, GDConsts.anyDirection,
             CbtMap.GetIconSize(candidate), GDVars.arena);
          for index := 1 to GDVars.targetCount do
            if GDVars.targetList[index].characterIndex = CbtMap.CombatSlot(Types.PCharacter(character)) then
              found := True
        end else
          found := True
      end;
      candidate := candidate^.next
    end;
    Move(savedTargets, GDVars.targetList, SizeOf(savedTargets))
  end;
  if found then
    FxEngine.CallEffectHandler(effectId, character, effect, False)
end;

{ Against a magical attack, a character with spell resistance resists on d100 <= resistance + (11 - caster level) x 5,
  zeroing the damage and, except for effects 91 and 82, the effect.
  @param(character The creature attacked.) }
procedure CheckSpellResistance(character: Types.PCharacter);
var
  resistance: Byte;
  chance: Byte;
  level: Byte;
begin
  resistance := character^.spellResistance;
  if (resistance <> 0) and ((GDVars.currentEffectId <> 0) or ((GDVars.elementMask and $08) <> 0)) then begin
    if GDVars.currentDamage <> 0 then
      if (GDVars.elementMask and $08) = 0 then Exit;
    level := CharHlp.GetCasterLevel(GDVars.currentSpellIndex);
    chance := resistance + (11 - level) * 5;
    if FxEngine.RollDice(1, 100) <= chance then begin
      GDVars.currentDamage := 0;
      if (GDVars.currentEffectId <> 91) and (GDVars.currentEffectId <> 82) then
        GDVars.currentEffectId := 0
    end
  end
end;

procedure TriggerEffectsWithCondition(condition: Byte; var character);
var
  { Unused in this version; see the other implementations of this routine. }
  effect: Pointer;
begin
  case condition of
    C_Cond.ATTACKER_VETO: ;
    C_Cond.TARGET_VETO: begin
        FxEngine.TriggerEffect(character, C_Effect.INVISIBLE);
        FxEngine.TriggerEffect(character, C_Effect.INVISIBLE_BY_FLAG);
        FxEngine.TriggerEffect(character, C_Effect.BLINKING)
      end;
    2: begin
        FxEngine.TriggerEffect(character, C_Effect.STUN_ON_HIT);
        FxEngine.TriggerEffect(character, C_Effect.POISON_ATTACK);
        FxEngine.TriggerEffect(character, C_Effect.DRAIN_ONE);
        FxEngine.TriggerEffect(character, C_Effect.DRAIN_TWO);
        FxEngine.TriggerEffect(character, C_Effect.PARALYZING_TOUCH);
        FxEngine.TriggerEffect(character, C_Effect.FIRE_TOUCH);
        FxEngine.TriggerEffect(character, C_Effect.STRONG_POISON_ATTACK);
        FxEngine.TriggerEffect(character, C_Effect.PARALYZE_NON_ELVES)
      end;
    3: begin
        FxEngine.TriggerEffect(character, C_Effect.POISON_ATTACK);
        FxEngine.TriggerEffect(character, C_Effect.DRAIN_ONE);
        FxEngine.TriggerEffect(character, C_Effect.DRAIN_TWO);
        FxEngine.TriggerEffect(character, C_Effect.PARALYZING_TOUCH);
        FxEngine.TriggerEffect(character, C_Effect.FIRE_TOUCH);
        FxEngine.TriggerEffect(character, C_Effect.STRONG_POISON_ATTACK)
      end;
    C_Cond.WEAPON_DAMAGE_ATTACKER: begin
        FxEngine.TriggerEffect(character, C_Effect.FIXED_DICE_ATTACK);
        FxEngine.TriggerEffect(character, C_Effect.ENFEEBLE);
        FxEngine.TriggerEffect(character, C_Effect.DISPEL_EVIL);
        FxEngine.TriggerEffect(character, C_Effect.RANGER_BONUS_DAMAGE);
        FxEngine.TriggerEffect(character, C_Effect.BLINDED_BY_SMOKE);
        FxEngine.TriggerEffect(character, C_Effect.DAMAGE_EQUALS_HIT_POINTS);
        FxEngine.TriggerEffect(character, C_Effect.BONUS_DAMAGE_VS_TYPE);
        FxEngine.TriggerEffect(character, C_Effect.DISRUPTION)
      end;
    C_Cond.WEAPON_DAMAGE_DEFENDER: begin
        FxEngine.TriggerEffect(character, C_Effect.MIRROR_IMAGE);
        FxEngine.TriggerEffect(character, C_Effect.PROTECTION_FROM_MISSILES);
        FxEngine.TriggerEffect(character, C_Effect.NEEDS_PLUS_THREE_WEAPON);
        FxEngine.TriggerEffect(character, C_Effect.NEEDS_MAGIC_WEAPON);
        FxEngine.TriggerEffect(character, C_Effect.HALF_DAMAGE_FROM_WEAPON_CLASS);
        FxEngine.TriggerEffect(character, C_Effect.SHOCK_ATTACKER)
      end;
    FxEngine.COND_DAMAGE_TAKEN: begin
        FxEngine.CheckSpellResistance(Types.PCharacter(character));
        FxEngine.TriggerEffect(character, C_Effect.RESIST_COLD);
        FxEngine.TriggerEffect(character, C_Effect.SHIELD);
        FxEngine.TriggerEffect(character, C_Effect.RESIST_FIRE);
        FxEngine.TriggerEffect(character, C_Effect.MIRROR_IMAGE);
        FxEngine.TriggerEffect(character, C_Effect.MAJOR_GLOBE);
        FxEngine.TriggerEffect(character, C_Effect.MINOR_GLOBE);
        FxEngine.TriggerEffect(character, C_Effect.IMMUNE_ELECTRICITY);
        FxEngine.TriggerEffect(character, C_Effect.REFLECT_SPELL);
        FxEngine.TriggerEffect(character, C_Effect.IMMUNE_DRAGON_BREATH);
        FxEngine.TriggerEffect(character, C_Effect.COLD_VULNERABLE);
        FxEngine.TriggerEffect(character, C_Effect.HEALED_BY_FIRE);
        FxEngine.TriggerEffect(character, C_Effect.RESIST_COLD_ELECTRICITY);
        FxEngine.TriggerEffect(character, C_Effect.FIRE_HEALS_SHOCK_SLOWS);
        FxEngine.TriggerEffect(character, C_Effect.IMMUNE_COLD);
        FxEngine.TriggerEffect(character, C_Effect.SHOCK_HEALS_FIRE_SLOWS)
      end;
    C_Cond.TURN_START: begin
        FxEngine.TriggerEffect(character, C_Effect.SNAKES);
        FxEngine.TriggerEffect(character, C_Effect.ENTANGLED);
        FxEngine.TriggerEffect(character, C_Effect.BEFUDDLED);
        FxEngine.TriggerEffect(character, C_Effect.HELPLESS);
        FxEngine.TriggerEffect(character, C_Effect.DANCING);
        FxEngine.TriggerEffect(character, C_Effect.HELD);
        FxEngine.TriggerEffect(character, C_Effect.SLEEP)
      end;
    C_Cond.COMBAT_START: FxEngine.TriggerEffect(character, C_Effect.MAGIC_CLOAK);
    C_Cond.EFFECT_ADDED: begin
        FxEngine.CheckSpellResistance(Types.PCharacter(character));
        FxEngine.TriggerEffect(character, C_Effect.HALF_ELF_RESISTANCE);
        FxEngine.TriggerEffect(character, C_Effect.DANCING);
        FxEngine.TriggerEffect(character, C_Effect.MAJOR_GLOBE);
        FxEngine.TriggerEffect(character, C_Effect.MINOR_GLOBE);
        FxEngine.TriggerEffect(character, C_Effect.REFLECT_SPELL);
        FxEngine.TriggerEffect(character, C_Effect.IMMUNE_CONFUSION);
        FxEngine.TriggerEffect(character, C_Effect.FIRE_HEALS_SHOCK_SLOWS);
        FxEngine.TriggerEffect(character, C_Effect.IMMUNE_FEAR);
        FxEngine.TriggerEffect(character, C_Effect.ELF_RESISTANCE);
        FxEngine.TriggerEffect(character, C_Effect.IMMUNE_CHARM_SLEEP);
        FxEngine.TriggerEffect(character, C_Effect.IMMUNE_HOLD);
        FxEngine.TriggerEffect(character, C_Effect.IMMUNE_COLD);
        FxEngine.TriggerEffect(character, C_Effect.IMMUNE_POISON_HOLD);
        FxEngine.TriggerEffect(character, C_Effect.SHOCK_HEALS_FIRE_SLOWS);
        FxEngine.TriggerEffect(character, 116)
      end;
    FxEngine.COND_ATTACK_ROLL_ATT: begin
        FxEngine.TriggerEffect(character, C_Effect.BLESS);
        FxEngine.TriggerEffect(character, C_Effect.FIXED_DICE_ATTACK);
        FxEngine.TriggerEffect(character, C_Effect.DWARF_THAC0);
        FxEngine.TriggerEffect(character, C_Effect.BLIND);
        FxEngine.TriggerEffect(character, C_Effect.CURSED);
        FxEngine.TriggerEffect(character, C_Effect.PRAYER);
        FxEngine.TriggerEffect(character, C_Effect.BLINDED_BY_SMOKE);
        FxEngine.TriggerEffect(character, C_Effect.EVIL_STENCH_PENALTY)
      end;
    C_Cond.DEFENDER_ARMOR_CLASS: begin
        FxEngine.TriggerEffect(character, C_Effect.DISPELLING_EVIL);
        FxEngine.TriggerEffect(character, C_Effect.PROTECTION_FROM_EVIL);
        FxEngine.TriggerEffect(character, C_Effect.HIGHLIGHTED);
        FxEngine.TriggerEffect(character, C_Effect.SHIELD);
        FxEngine.TriggerEffect(character, C_Effect.STINKING_COUGH);
        FxEngine.TriggerEffect(character, C_Effect.BLIND);
        FxEngine.TriggerEffect(character, C_Effect.PROTECTION_FROM_EVIL_RADIUS);
        FxEngine.TriggerEffect(character, C_Effect.BARKSKIN);
        FxEngine.TriggerEffect(character, C_Effect.DANCING);
        FxEngine.TriggerEffect(character, C_Effect.IRON_SKIN)
      end;
    FxEngine.COND_SAVING_THROW: begin
        FxEngine.TriggerEffect(character, C_Effect.PROTECTION_FROM_EVIL);
        FxEngine.TriggerEffect(character, C_Effect.RESIST_COLD);
        FxEngine.TriggerEffect(character, C_Effect.SHIELD);
        FxEngine.TriggerEffect(character, C_Effect.RESIST_FIRE);
        FxEngine.TriggerEffect(character, C_Effect.BLIND);
        FxEngine.TriggerEffect(character, C_Effect.CURSED);
        FxEngine.TriggerEffect(character, C_Effect.PROTECTION_FROM_EVIL_RADIUS);
        FxEngine.TriggerEffect(character, C_Effect.BARKSKIN);
        FxEngine.TriggerEffect(character, C_Effect.PRAYER);
        FxEngine.TriggerEffect(character, C_Effect.FIRE_SHIELD_HOT);
        FxEngine.TriggerEffect(character, C_Effect.FIRE_SHIELD_COLD);
        FxEngine.TriggerEffect(character, C_Effect.DANCING);
        FxEngine.TriggerEffect(character, C_Effect.CONSTITUTION_SAVE_BONUS);
        FxEngine.TriggerEffect(character, C_Effect.IMMUNE_POISON_HOLD)
      end;
    C_Cond.HIT_POINTS_ZERO: ;
    C_Cond.MONSTER_SPECIAL: begin
        FxEngine.TriggerEffect(character, C_Effect.GAZE_CHARM);
        FxEngine.TriggerEffect(character, C_Effect.BREATH_BOLT);
        FxEngine.TriggerEffect(character, C_Effect.STORED_FIREBALL);
        FxEngine.TriggerEffect(character, 90);
        FxEngine.TriggerEffect(character, 100);
        FxEngine.TriggerEffect(character, 104);
        FxEngine.TriggerEffect(character, C_Effect.SMOKE_BLINDS)
      end;
    C_Cond.ACTION_START: begin
        FxEngine.TriggerEffect(character, C_Effect.CHARM);
        FxEngine.TriggerEffect(character, C_Effect.SILENCE);
        FxEngine.TriggerEffect(character, C_Effect.STINKING_COUGH);
        FxEngine.TriggerEffect(character, C_Effect.FEEBLEMINDED);
        FxEngine.TriggerEffect(character, C_Effect.BURST_AROUND_SELF);
        FxEngine.TriggerEffect(character, C_Effect.FRIGHTEN_ADJACENT);
        FxEngine.TriggerEffect(character, C_Effect.EVIL_STENCH);
        FxEngine.TriggerEffect(character, C_Effect.BERSERK);
        FxEngine.TriggerEffect(character, C_Effect.REGENERATE_THREE)
      end;
    FxEngine.COND_ATTACK_ROLL_DEF: begin
        FxEngine.TriggerEffect(character, C_Effect.INVISIBLE);
        FxEngine.TriggerEffect(character, C_Effect.INVISIBLE_BY_FLAG);
        FxEngine.TriggerEffect(character, C_Effect.BLINKING);
        FxEngine.TriggerEffect(character, C_Effect.DWARF_ARMOR_CLASS_VS_GIANTS);
        FxEngine.TriggerEffect(character, C_Effect.MAGIC_CLOAK)
      end;
    C_Cond.MORALE_CHECK: begin
        FxEngine.TriggerEffect(character, C_Effect.BLESS);
        FxEngine.TriggerEffect(character, C_Effect.CHARM)
      end;
    C_Cond.MOVE_ATTACK_RATE: begin
        FxEngine.TriggerEffect(character, C_Effect.MAGIC_BOOTS);
        FxEngine.TriggerEffect(character, C_Effect.HASTED);
        FxEngine.TriggerEffect(character, C_Effect.SLOWED)
      end;
    C_Cond.ROUND_END: begin
        FxEngine.TriggerEffect(character, C_Effect.CHARM);
        FxEngine.TriggerEffect(character, C_Effect.SPIRITUAL_HAMMER)
      end;
    FxEngine.COND_DAMAGE_NOT_SAVED: begin
        FxEngine.TriggerEffect(character, C_Effect.FIRE_SHIELD_HOT);
        FxEngine.TriggerEffect(character, C_Effect.FIRE_SHIELD_COLD)
      end;
    21: FxEngine.TriggerEffect(character, C_Effect.CONFUSED);
    22: ;
    23: ;
    24: ;
  end
end;

procedure ConsiderTerrainEffects(character: Types.PCharacter; terrain: Byte);
var terrainIndex: Byte;
    creatureIndex: Byte;
    effect: Types.PEffect;
    effectArg: Pointer absolute effect;
    secondEffect: Types.PEffect;
    secondEffectArg: Pointer absolute secondEffect;
    saved: Boolean;
    cloud: Byte;
    harmful: Byte;
    savedCharacter: Types.PCharacter;
    { Unused in this version; see the other implementations of this routine. }
    savedTargets: Boolean;
begin
  if Types.PCharacter(character)^.enabled <> 0 then begin
    CbtMap.ProbeDirection(character, C_Dir.CENTER, creatureIndex, terrainIndex, cloud, harmful);
    if (cloud <> 0) and (terrain <> 0) then begin
      if (not CbtMap.CombatIconVisible(character, 1)) or (GDVars.showTurn = 0) then
        CbtMap.ScrollView(CbtMap.CombatCellX(character), CbtMap.CombatCellY(character), 255, C_Dir.CENTER);
      if (Types.PCharacter(character)^.levelUndead = 0) and
          (not CharHlp.HasEffect(character, C_Effect.HELPLESS, effectArg)) and
          (not CharHlp.HasEffect(character, C_Effect.IMMUNE_POISON_HOLD, effectArg)) then begin
        saved := FxEngine.RollSavingThrow(character, 0, 0);
        if saved then begin
          savedCharacter := GDVars.currentCharacter;
          FxEngine.AddEffectWithMessage(character, C_Effect.STINKING_COUGH, FxEngine.RollDice(1, 4) + 1, 255, 0,
                                        0, Ord(saved), GDConsts.startsCoughing);
          secondEffect := nil;
          if CharHlp.HasEffect(character, C_Effect.STINKING_COUGH, secondEffectArg) then begin
            FxEngine.CallEffectHandler(C_Effect.STINKING_COUGH, character, effect, False);
            if Types.PCharacter(character)^.combat^.spellCast > 0 then begin
              CharHlp.PrintCreatureMessage(character, GDConsts.lostSpellMessage, 12, True);
              CharHlp.RemoveSpell(character, Types.PCharacter(character)^.combat^.spellCast);
              savedTargets := CharHlp.EndActions(character)
            end
          end;
          GDVars.currentCharacter := savedCharacter
        end else begin
          savedCharacter := GDVars.currentCharacter;
          FxEngine.AddEffectWithMessage(character, C_Effect.HELPLESS, FxEngine.RollDice(1, 4) + 1, 255, 0, 0,
                                        Ord(saved), GDConsts.chokesFromNausea);
          if CharHlp.HasEffect(character, C_Effect.HELPLESS, effectArg) then
            FxEngine.CallEffectHandler(C_Effect.HELPLESS, character, effect, False);
          GDVars.currentCharacter := savedCharacter
        end
      end
    end;
    if harmful = 0 then Exit;
    if Types.PCharacter(character)^.enabled = 0 then Exit;
    case Types.PCharacter(character)^.levelHighest of
      0..4: begin
        CharHlp.PrintCreatureMessage(character, GDConsts.poisonedMessage, 10, False);
        TextRend.PauseOnly;
        FxEngine.AddEffect(character, C_Effect.POISONED, 0, 255, False);
        FxEngine.KillCreature(character, C_Status.DEAD_STATUS, GDConsts.killedMessage)
      end;
      5: if not FxEngine.RollSavingThrow(character, 0, 252) then begin
        CharHlp.PrintCreatureMessage(character, GDConsts.poisonedMessage, 10, False);
        TextRend.PauseOnly;
        FxEngine.AddEffect(character, C_Effect.POISONED, 0, 255, False);
        FxEngine.KillCreature(character, C_Status.DEAD_STATUS, GDConsts.killedMessage)
      end;
      6: if not FxEngine.RollSavingThrow(character, 0, 0) then begin
        CharHlp.PrintCreatureMessage(character, GDConsts.poisonedMessage, 10, False);
        TextRend.PauseOnly;
        FxEngine.AddEffect(character, C_Effect.POISONED, 0, 255, False);
        FxEngine.KillCreature(character, C_Status.DEAD_STATUS, GDConsts.killedMessage)
      end
    end
  end
end;

function AttackRollNoAttacker(defender: Types.PCharacter; target: Byte): Boolean;
begin
  AttackRollNoAttacker := False;
  GDVars.currentAttackRoll := FxEngine.RollDice(1, 20);
  if GDVars.currentAttackRoll > 1 then begin
    if GDVars.currentAttackRoll = 20 then
      GDVars.currentAttackRoll := 100;
    FxEngine.TriggerEffectsWithCondition(FxEngine.COND_ATTACK_ROLL_DEF, defender);
    if GDVars.currentAttackRoll >= 0 then
      if GDVars.currentAttackRoll + target > Types.PCharacter(defender)^.armorClass then
        AttackRollNoAttacker := True
  end
end;

const
  ATTACK_STYLE = 500;

function AttackRoll(attacker, defender: Types.PCharacter; target: Byte): Boolean;
var modifier: ShortInt;
begin
  AttackRoll := False;
  FxEngine.RemoveInvisibility(attacker);
  GDVars.currentAttackRoll := FxEngine.RollDice(1, 20);
  if GDVars.currentAttackRoll > 1 then begin
    if GDVars.currentAttackRoll = 20 then
      GDVars.currentAttackRoll := 100;
    FxEngine.TriggerEffectsWithCondition(FxEngine.COND_ATTACK_ROLL_ATT, attacker);
    FxEngine.TriggerEffectsWithCondition(FxEngine.COND_ATTACK_ROLL_DEF, defender);
    if Types.PCharacter(attacker)^.side = C_Side.PLAYER then begin
      modifier := GDVars.zone1^.modPartyThac0[GDConsts.modPartyThac0Index + $7C00];
      case FxEngine.ATTACK_STYLE of
        1: Inc(modifier, 2);
        2: Inc(modifier);
        4: Dec(modifier);
        5: Dec(modifier, 2)
      end
    end else
      modifier := GDVars.zone1^.modMonThac0[GDConsts.modMonThac0Index + $7C00];
    if GDVars.currentAttackRoll >= 0 then
      if GDVars.currentAttackRoll + Types.PCharacter(attacker)^.thac0Adjusted + modifier >= target then
        AttackRoll := True
  end
end;

function RollSavingThrow(character: Types.PCharacter; saveType, modifier: Byte): Boolean;
var tableIndex: Word;
    effect: Types.PEffect;
    effectArg: Pointer absolute effect;
begin
  GDVars.currentSaveResult := True;
  GDVars.currentSaveRoll := FxEngine.RollDice(1, 20);
  if CharHlp.HasEffect(character, C_Effect.DANCING, effectArg) then
    GDVars.currentSaveRoll := 1;
  case GDVars.currentSaveRoll of
    1: GDVars.currentSaveResult := False;
    20: GDVars.currentSaveResult := True;
  else begin
    if (Types.PCharacter(character)^.classLevels[C_Class.MAGE] > 0) and
        (Types.PCharacter(character)^.robeOrder > 0) then begin
      tableIndex := Types.PCharacter(character)^.robeOrder + $1F8;
      case GDVars.zone0^.ecl[tableIndex + $4B00] of
        0: Dec(modifier);
        2: Inc(modifier)
      end
    end;
    GDVars.currentSaveRoll := GDVars.currentSaveRoll + Types.PCharacter(character)^.saveBonus +
      ShortInt(modifier);
    GDVars.currentSaveType := saveType;
    FxEngine.TriggerEffectsWithCondition(FxEngine.COND_SAVING_THROW, character);
    if Types.PCharacter(character)^.saves[ShortInt(saveType)] <= GDVars.currentSaveRoll then
      GDVars.currentSaveResult := True
    else
      GDVars.currentSaveResult := False
  end
  end;
  RollSavingThrow := GDVars.currentSaveResult
end;

function RollDice(count, sides: Byte): Byte;
var
  index: Byte;
  total: Byte;
begin
  total := 0;
  if count > 0 then
    for index := 1 to count do
      Inc(total, Random(sides) + 1);
  RollDice := total
end;

function RollDamageDice(count, sides: Byte): Byte;
begin
  GDVars.currentDiceCount := count;
  RollDamageDice := FxEngine.RollDice(count, sides)
end;

procedure AddEffect(character: Types.PCharacter; effectId: Byte; minutes: Word; strength: Byte; onRemove: Boolean);
var
  newEffect: Types.PEffect;
  effect: Types.PEffect;
begin
  GetMem(newEffect, SizeOf(Types.TEffect));
  if Types.PCharacter(character)^.effects = nil then
    Types.PCharacter(character)^.effects := newEffect
  else begin
    effect := Types.PCharacter(character)^.effects;
    while effect^.next <> nil do
      effect := effect^.next;
    effect^.next := newEffect
  end;
  newEffect^.next := nil;
  newEffect^.effectId := effectId;
  newEffect^.duration := minutes;
  newEffect^.onRemove := Byte(onRemove);
  newEffect^.strength := strength
end;

procedure PutOutOfPlayWithStatus(character: Types.PCharacter; status: Byte; message: Types.TString40);
var slot: Byte;
begin
  if Types.PCharacter(character)^.enabled <> 0 then begin
    slot := CbtMap.CombatSlot(character);
    CbtMap.DisplayMapViewCentered(character, 3, False);
    CharHlp.PrintCreatureMessage(character, message, 10, True);
    Types.PCharacter(character)^.enabled := 0;
    Types.PCharacter(character)^.status := status;
    if Types.PCharacter(character)^.status <> C_Status.RUNNING then
      Types.PCharacter(character)^.hitPoints := 0;
    CbtMap.UpdateCombatMapTile(0, 0, slot);
    Blit.FlushView;
    GDVars.arenaLoc[slot].size := 0;
    CbtMap.BuildArenaArrays;
    if CharHlp.EndActions(character) then
      FxEngine.RemoveEffectsHp0(character)
  end
end;

procedure RemoveInvisibility(character: Types.PCharacter);
var effect: Types.PEffect;
    effectArg: Pointer absolute effect;
begin
  while CharHlp.HasEffect(character, C_Effect.INVISIBLE, effectArg) do
    FxEngine.RemoveEffect(character, C_Effect.INVISIBLE, effect)
end;

procedure RemoveEffectsHp0(character: Types.PCharacter);
var index: Byte;
    effect: Types.PEffect;
    effectArg: Pointer absolute effect;
begin
  for index := 1 to 16 do
    FxEngine.RemoveEffect(character, GDConsts.hitPointEffectIds[index], nil);
  if CharHlp.HasEffect(character, C_Effect.BERSERK, effectArg) then
    if Types.PCharacter(character)^.npc = C_Npc.ANIMATED_PLAYER then
      Types.PCharacter(character)^.side := C_Side.PLAYER
end;

procedure RemoveAiEffects(character: Types.PCharacter);
var
  { Unused in this version; see the other implementations of this routine. }
  effectIndex: Word;
begin
end;

function RemoveEffectWithMessage(character: Types.PCharacter; effectId: Byte): Boolean;
var effect: Types.PEffect;
    effectArg: Pointer absolute effect;
begin
  RemoveEffectWithMessage := False;
  if CharHlp.HasEffect(character, effectId, effectArg) then begin
    CharHlp.PrintCreatureMessage(character, GDConsts.isCuredText, 10, True);
    FxEngine.RemoveEffect(character, effectId, effect);
    RemoveEffectWithMessage := True
  end
end;

{ Encodes a Strength as an effect strength: 18 with exceptional Strength becomes the exceptional value + 1 (1..101), any
  other base Strength becomes the base + 100.
  @param(baseStrength Base Strength.)
  @param(exceptional Exceptional Strength, read when the base Strength is 18.)
  @returns(The encoded Strength.) }
function StrengthModifier(baseStrength, exceptional: Byte): Byte;
begin
  StrengthModifier := baseStrength + 100;
  if baseStrength = 18 then
    StrengthModifier := exceptional + 1
end;

{ Decodes an effect's strength byte, bit 7 aside, into Strength: up to 101 is Strength 18 with exceptional Strength of
  the value less 1, above it Strength of the value less 100 with no exceptional Strength.
  @param(effect The Strength effect.)
  @param(baseStrength Receives Strength.)
  @param(exceptional Receives exceptional Strength.) }
procedure StrengthEffectToStrength(effect: Types.PEffect; var baseStrength, exceptional: Byte);
begin
  exceptional := 0;
  baseStrength := effect^.strength and $7F;
  if baseStrength <= 101 then begin
    exceptional := baseStrength - 1;
    baseStrength := 18
  end else
    baseStrength := baseStrength - 100
end;

function AdjustForNewStrength(character: Types.PCharacter; baseStrength, exceptional: Byte;
                              var effectStrength: Byte): Boolean;
var
  { Unused in this version; see the other implementations of this routine. }
  encumbrance: array[1..11] of Byte;
begin
  if (baseStrength > Types.PCharacter(character)^.stats[C_Stat.STRENGTH].base) or
      ((baseStrength = 18) and (exceptional > Types.PCharacter(character)^.exceptionalStrengthBase)) then begin
    AdjustForNewStrength := True;
    effectStrength := FxEngine.StrengthModifier(baseStrength, exceptional)
  end else
    AdjustForNewStrength := False
end;

procedure RecalcAbility(character: Types.PCharacter; stat: ShortInt);
var
  bestBase: Byte;
  candidateBase: Byte;
  bestExceptional: Byte;
  candidateExceptional: Byte;
  effect: Types.PEffect;
  effectArg: Pointer absolute effect;
  oldMaxHitPoints: Byte;
  accumulatedBonus: Byte;
  factor: Byte;
  index: ShortInt;
  modifier: Types.PItem;
  overrideValue: Byte;
  modifierCode: Byte;
  factorCount: Byte;

  { Raises the strength being built to the candidate when higher, comparing exceptional strength only at 18. }
  procedure StrClamp;
  begin
    if (candidateBase > bestBase) or ((candidateBase = 18) and (candidateExceptional > bestExceptional)) then begin
      bestBase := candidateBase;
      bestExceptional := candidateExceptional
    end
  end;

  { Adds a class's constitution hit-point bonus for its levels to accumulatedBonus. }
  procedure StatBonus(targetStat: ShortInt; factor: Byte);
  begin
    if GDConsts.firstFixedHpLevel[targetStat] <= factor then
      factor := GDConsts.firstFixedHpLevel[targetStat] - 1;
    if targetStat = C_Class.RANGER then
      Inc(factor);
    if (targetStat = C_Class.FIGHTER) or (targetStat = C_Class.RANGER) or
        (targetStat = C_Class.PALADIN) or (targetStat = C_Class.KNIGHT) then begin
      case bestBase of
        15..19: Inc(accumulatedBonus, (bestBase - 14) * factor);
        20: Inc(accumulatedBonus, factor * 5);
        21..23: Inc(accumulatedBonus, factor * 6);
        24..25: Inc(accumulatedBonus, factor * 7)
      end
    end else if bestBase > 15 then
      Inc(accumulatedBonus, factor * 2)
    else if bestBase = 15 then
      Inc(accumulatedBonus, factor)
  end;
begin
  accumulatedBonus := 0;
  candidateBase := 0;
  candidateExceptional := 0;
  overrideValue := 255;
  modifier := Types.PCharacter(character)^.items;
  bestBase := Types.PCharacter(character)^.stats[stat].base;
  bestExceptional := Types.PCharacter(character)^.exceptionalStrengthBase;
  while modifier <> nil do begin
    if (modifier^.special > $80) and (modifier^.equipped <> 0) then begin
      modifierCode := modifier^.special and $7F;
      case stat of
        C_Stat.STRENGTH: begin
          case modifierCode of
            3: begin
              candidateBase := 18;
              candidateExceptional := 100
            end;
            5: case modifier^.effect of
                0: begin candidateBase := 18; candidateExceptional := 100 end;
                1: candidateBase := 19;
                2: candidateBase := 20;
                3: candidateBase := 21;
                4: candidateBase := 22;
                5: candidateBase := 23;
                6: candidateBase := 24
              end;
            8: if (Types.PCharacter(character)^.stats[C_Stat.STRENGTH].base < 18) and
              (modifier^.effect = C_Stat.STRENGTH) then begin
                candidateBase := Types.PCharacter(character)^.stats[C_Stat.STRENGTH].base + 1;
                candidateExceptional := 0
              end;
            13: overrideValue := 3
          end;
          StrClamp
        end;
        C_Stat.CONSTITUTION: begin
          if modifierCode = 6 then
            Inc(bestBase)
          else if (modifierCode = 8) and (Types.PCharacter(character)^.stats[C_Stat.CONSTITUTION].base < 18) and
            (modifier^.effect = C_Stat.CONSTITUTION) then
            Inc(bestBase)
        end;
        C_Stat.INTELLIGENCE: case modifierCode of
            8: if (Types.PCharacter(character)^.stats[C_Stat.INTELLIGENCE].base < 18) and
              (modifier^.effect = C_Stat.INTELLIGENCE) then Inc(bestBase);
            12: overrideValue := 7;
            13: overrideValue := 3
          end;
        C_Stat.WISDOM: if (modifierCode = 8) and (modifier^.effect = C_Stat.WISDOM) and
          (Types.PCharacter(character)^.stats[C_Stat.WISDOM].base < 18) then
            Inc(bestBase);
        C_Stat.DEXTERITY: case modifierCode of
            2: case Types.PCharacter(character)^.stats[C_Stat.DEXTERITY].base of
                0..6: Inc(bestBase, 4);
                7..13: Inc(bestBase, 2)
              else Inc(bestBase)
              end;
            8: if (Types.PCharacter(character)^.stats[C_Stat.DEXTERITY].base < 18) and
              (modifier^.effect = C_Stat.DEXTERITY) then Inc(bestBase);
            10: Dec(bestBase, 2)
          end;
        C_Stat.CHARISMA: case modifierCode of
            6: Dec(bestBase);
            8: if (Types.PCharacter(character)^.stats[C_Stat.CHARISMA].base < 18) and
              (modifier^.effect = C_Stat.CHARISMA) then Inc(bestBase)
          end
      end
    end;
    modifier := modifier^.next
  end;
  case stat of
    C_Stat.STRENGTH: begin
      if CharHlp.HasEffect(character, C_Effect.STRENGTH, effectArg) then begin
        FxEngine.StrengthEffectToStrength(effect, candidateBase, candidateExceptional);
        if (bestBase <= 18) and (bestExceptional < 100) then begin
          candidateBase := bestBase + candidateBase;
          if candidateBase > 18 then begin
            if (Types.PCharacter(character)^.classLevels[C_Class.FIGHTER] > 0) or
                (Types.PCharacter(character)^.classLevels[C_Class.PALADIN] > 0) or
                (Types.PCharacter(character)^.classLevels[C_Class.KNIGHT] > 0) or
                (Types.PCharacter(character)^.classLevels[C_Class.RANGER] > 0) then begin
              candidateExceptional := Types.PCharacter(character)^.exceptionalStrength + (candidateBase - 18) * 10;
              if candidateExceptional > 100 then
                candidateExceptional := 100;
              candidateBase := 18
            end else
              candidateBase := 18
          end
        end;
        StrClamp
      end;
      if CharHlp.HasEffect(character, C_Effect.FROST_GIANT_STRENGTH, effectArg) then begin
        FxEngine.StrengthEffectToStrength(effect, candidateBase, candidateExceptional);
        StrClamp
      end;
      if CharHlp.HasEffect(character, C_Effect.ENLARGE, effectArg) then begin
        FxEngine.StrengthEffectToStrength(effect, candidateBase, candidateExceptional);
        StrClamp
      end;
      if overrideValue <> 255 then begin
        Types.PCharacter(character)^.stats[C_Stat.STRENGTH].current := overrideValue;
        Types.PCharacter(character)^.exceptionalStrength := 0
      end else begin
        Types.PCharacter(character)^.stats[C_Stat.STRENGTH].current := bestBase;
        Types.PCharacter(character)^.exceptionalStrength := bestExceptional
      end
    end;
    C_Stat.CONSTITUTION: begin
      factorCount := 0;
      oldMaxHitPoints := Types.PCharacter(character)^.maxHitPoints;
      Types.PCharacter(character)^.maxHitPoints := Types.PCharacter(character)^.baseMaxHitPoints;
      for index := 0 to 7 do begin
        factor := Types.PCharacter(character)^.classLevels[index];
        if factor > 0 then
          Inc(factorCount);
        if GDConsts.firstFixedHpLevel[ShortInt(index)] < factor then
          factor := GDConsts.firstFixedHpLevel[ShortInt(index)];
        if factor > 0 then
          StatBonus(ShortInt(index), factor)
      end;
      accumulatedBonus := accumulatedBonus div factorCount;
      Inc(Types.PCharacter(character)^.maxHitPoints, accumulatedBonus);
      if Types.PCharacter(character)^.maxHitPoints > oldMaxHitPoints then
        Inc(Types.PCharacter(character)^.hitPoints, Types.PCharacter(character)^.maxHitPoints - oldMaxHitPoints);
      if Types.PCharacter(character)^.maxHitPoints < oldMaxHitPoints then begin
        if Types.PCharacter(character)^.hitPoints >
            oldMaxHitPoints - Types.PCharacter(character)^.maxHitPoints then
          Dec(Types.PCharacter(character)^.hitPoints, oldMaxHitPoints - Types.PCharacter(character)^.maxHitPoints)
        else
          Types.PCharacter(character)^.hitPoints := 0
      end;
      Types.PCharacter(character)^.stats[C_Stat.CONSTITUTION].current := bestBase;
      if Types.PCharacter(character)^.stats[C_Stat.CONSTITUTION].current >= 20 then begin
        if not CharHlp.HasEffect(character, C_Effect.CONSTITUTION_REGENERATION, effectArg) then
          FxEngine.AddEffect(character, C_Effect.CONSTITUTION_REGENERATION, 60, 255, True)
      end else
        FxEngine.RemoveEffect(character, C_Effect.CONSTITUTION_REGENERATION, nil)
    end;
    C_Stat.INTELLIGENCE: ;
    C_Stat.WISDOM: ;
    C_Stat.DEXTERITY: if overrideValue <> 255 then
        Types.PCharacter(character)^.stats[C_Stat.DEXTERITY].current := overrideValue
      else
        Types.PCharacter(character)^.stats[C_Stat.DEXTERITY].current := bestBase;
    C_Stat.CHARISMA: begin
      if CharHlp.HasEffect(character, C_Effect.FRIENDS, effectArg) then
        Inc(bestBase, effect^.strength);
      Types.PCharacter(character)^.stats[C_Stat.CHARISMA].current := bestBase
    end
  end
end;

procedure InflictNonWeaponDamage(character: Types.PCharacter; damage, reduction: Byte; saved: Boolean);
var message: String;
    { Unused in this version; see the other implementations of this routine. }
    endResult: Boolean;
begin
  GDVars.currentDamage := damage;
  FxEngine.TriggerEffectsWithCondition(FxEngine.COND_DAMAGE_TAKEN, character);
  if saved then
    case Char(reduction) of
      #1: GDVars.currentDamage := 0;
      #2: GDVars.currentDamage := GDVars.currentDamage div 2
    end else
    FxEngine.TriggerEffectsWithCondition(FxEngine.COND_DAMAGE_NOT_SAVED, character);
  if (GDVars.currentDamage > 0) and (Types.PCharacter(character)^.enabled <> 0) then begin
    if GDVars.currentDamage <> 1 then
      message := GDConsts.takesPrefix + CharHlp.ByteToString(GDVars.currentDamage) + GDConsts.pointsDamage
    else
      message := GDConsts.onePointDamage;
    case GDVars.elementMask and $F7 of
      $01: message := message + GDConsts.fromFire;
      $02: message := message + GDConsts.fromCold;
      $04: message := message + GDConsts.fromElectricity;
      $10: message := message + GDConsts.fromAcid
    end;
    if (GDVars.elementMask and $08) = GDVars.elementMask then
      message := message + GDConsts.fromMagic;
    CharHlp.PrintNameStringAnim(character, False, message);
    CharHlp.InflictDamage(character, GDVars.currentDamage);
    if GDVars.interfaceState = C_Ifc.IN_COMBAT then begin
      Types.PCharacter(character)^.combat^.canCast := 0;
      if Types.PCharacter(character)^.combat^.spellCast > 0 then begin
        CharHlp.PrintCreatureMessage(character, GDConsts.lostSpellMessage, 12, True);
        CharHlp.RemoveSpell(character, Types.PCharacter(character)^.combat^.spellCast);
        endResult := CharHlp.EndActions(character)
      end
    end;
    if Types.PCharacter(character)^.enabled = 0 then begin
      message := GDConsts.goesDown;
      if (Types.PCharacter(character)^.immunityFlags and $08) = 0 then begin
        if Types.PCharacter(character)^.status = C_Status.DYING then
          message := message + GDConsts.dyingSuffix;
        if Types.PCharacter(character)^.status in
            [C_Status.DEAD_STATUS, C_Status.STONED, C_Status.GONE] then
          message := GDConsts.killedMessage
      end;
      CharHlp.PrintCreatureMessage(character, message, GDVars.currentRow + 1, False);
      if GDVars.interfaceState <> C_Ifc.IN_COMBAT then
        TextRend.PauseOnly
      else begin
        FxEngine.RemoveEffectsHp0(character);
        FxEngine.TriggerEffectsWithCondition(C_Cond.HIT_POINTS_ZERO, character);
        if (Types.PCharacter(character)^.enabled = 0) and (Types.PCharacter(character)^.status <> 10) then
          CbtMap.CreatureDowned(character)
        else
          TextRend.PauseOnly
      end
    end;
    CharHlp.ClearMessageWindow
  end
end;

procedure AddEffectWithMessage(character: Types.PCharacter; effectId: Byte; minutes: Word; strength: Byte; onRemove,
                               saveNegates, saved: Byte; message: Types.TString40);
var effect: Types.PEffect;
    effectArg: Pointer absolute effect;
begin
  GDVars.currentEffectId := effectId;
  FxEngine.TriggerEffectsWithCondition(C_Cond.EFFECT_ADDED, character);
  if (GDVars.currentEffectId = 0) or ((saved <> 0) and (saveNegates = 1)) then
    CharHlp.PrintCreatureMessage(character, GDConsts.unaffectedMessage, 10, True)
  else begin
    if CharHlp.HasEffect(character, effectId, effectArg) then
      if effect^.duration > 0 then
        FxEngine.RemoveEffect(character, effectId, effect);
    FxEngine.AddEffect(character, effectId, minutes, strength, Boolean(onRemove));
    if message[0] <> #0 then begin
      CharHlp.PrintNameStringAnim(character, True, message);
      CharHlp.ClearMessageWindow
    end
  end
end;

function RestoreHitPoints(character: Types.PCharacter; hitPoints: Byte; showMessage: Boolean): Boolean;
var
  { Unused in this version; see the other implementations of this routine. }
  effect: array[1..5] of Byte;
begin
  RestoreHitPoints := False;
  if Types.PCharacter(character)^.status in
      [C_Status.OKAY, C_Status.ANIMATED, C_Status.UNCONSCIOUS, C_Status.DYING] then
    if ((Types.PCharacter(character)^.hitPoints < Types.PCharacter(character)^.maxHitPoints) and showMessage) or
        (not showMessage) then begin
      Types.PCharacter(character)^.hitPoints := Types.PCharacter(character)^.hitPoints + hitPoints;
      if Types.PCharacter(character)^.hitPoints > Types.PCharacter(character)^.maxHitPoints then
        Types.PCharacter(character)^.hitPoints := Types.PCharacter(character)^.maxHitPoints;
      if Types.PCharacter(character)^.enabled = 0 then begin
        if Types.PCharacter(character)^.status = C_Status.DYING then
          Types.PCharacter(character)^.status := C_Status.UNCONSCIOUS;
        if (Types.PCharacter(character)^.status = C_Status.UNCONSCIOUS) and
            (GDVars.interfaceState <> C_Ifc.IN_COMBAT) then begin
          Types.PCharacter(character)^.status := C_Status.OKAY;
          Types.PCharacter(character)^.enabled := 1
        end
      end;
      RestoreHitPoints := True
    end
end;

{ Redraws each spell cloud's covered cells on the arena. }
procedure RefreshExplosionMap;
var current: Types.PCloudNode;
    index: Byte;
begin
  current := GDVars.cloudList;
  while current <> nil do begin
    for index := 1 to 9 do
      if current^.covered[index] <> 0 then
        GDVars.arena^.cells[current^.y + GDConsts.directionY[GDConsts.patchDir[index]],
                                   current^.x + GDConsts.directionX[GDConsts.patchDir[index]]] := current^.terrain;
    current := current^.next
  end
end;

procedure CountDownAreaEffects(immediate: Boolean);
var
  previous: Types.PCloudNode;
  current: Types.PCloudNode;
  next: Types.PCloudNode;
  removed: Boolean;
  index: Byte;
  cellX: ShortInt;
  cellY: ShortInt;
  queueIndex: Byte;
  occupied: Boolean;
  eligible: Boolean;
begin
  previous := nil;
  current := GDVars.cloudList;
  removed := False;
  while current <> nil do begin
    next := current^.next;
    if immediate then
      eligible := current^.countdown = -1
    else
      eligible := current^.countdown <= 1;
    if eligible then begin
      with current^ do
      for index := 1 to 9 do
        if covered[index] <> 0 then begin
          cellX := x + GDConsts.directionX[GDConsts.patchDir[index]];
          cellY := y + GDConsts.directionY[GDConsts.patchDir[index]];
          occupied := False;
          for queueIndex := 1 to GDVars.downedCount do
            if (GDVars.downed[queueIndex].cr <> nil) and (GDVars.downed[queueIndex].x = cellX) and
                (GDVars.downed[queueIndex].y = cellY) then
              occupied := True;
          if occupied then
            GDVars.arena^.cells[cellY, cellX] := C_Terr.TERRAIN_CORPSE
          else
            GDVars.arena^.cells[cellY, cellX] := under[index]
        end;
      removed := True;
      if previous = nil then
        GDVars.cloudList := next
      else
        previous^.next := next;
      FreeMem(current, SizeOf(Types.TCloudNode))
    end else begin
      previous := current;
      if not immediate then
        Dec(current^.countdown)
    end;
    current := next
  end;
  if removed then begin
    FxEngine.RefreshExplosionMap;
    CharHlp.PrintBottomLine(GDConsts.explosionMessage)
  end
end;
begin
end.
