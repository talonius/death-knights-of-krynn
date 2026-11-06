{ The effect handlers: one per effect id, installed into GDVars.effectServices.handlers[1..120] by InitEffectHandlers,
  plus the item handler. FxEngine.TriggerEffectsWithCondition says at which moment each id runs; the status names are
  GDConsts.effectNames, one String[37] per id, and the spell table's effectId column names the rest. }
{$F+,O+,S-,R-,V-,B-,I-}
unit EffHndlr;
interface

{ Fills GDVars.effectServices' handler table: one handler per effect id 1..120 and the item handler. }
procedure InitEffectHandlers;

{ Helpless effect: ends the creature's actions for the round.
  @param(character The creature carrying the effect.)
  @param(resource Unused.)
  @param(removed Unused.) }
procedure EffHelpless(var character: Pointer; resource: Pointer; removed: Boolean);

{ Ends the creature's actions for the round.
  @param(character The creature carrying the effect.)
  @param(resource Unused.)
  @param(removed Unused.) }
procedure EffEndActions(var character: Pointer; resource: Pointer; removed: Boolean);

{ Applies the bless effect: adds 5 to morale and 1 to the attack roll.
  @param(character Unused.)
  @param(resource Unused.)
  @param(removed Unused.) }
procedure EffBless(var character: Pointer; resource: Pointer; removed: Boolean);

{ Effect 2: in combat, a hit entangles the creature's target for 3 rounds ('is stunned') unless it saves.
  @param(character Creature with the effect.)
  @param(resource Unused.)
  @param(removed True when the effect is being removed.) }
procedure EffStunOnHit(var character: Pointer; resource: Pointer; removed: Boolean);

{ Applies sticks to snakes: the snakes use up the creature's attacks this round, taking them off the effect's strength
  (the effect ends when it runs out); the creature is shown fighting with snakes and its actions end.
  @param(character The creature carrying the effect.)
  @param(resource The effect's node.)
  @param(removed Unused.) }
procedure EffSticksToSnakes(var character: Pointer; resource: Pointer; removed: Boolean);

{ Applies Dispel Evil: takes 7 from the attack roll when the current creature has creature-type flag bit 0, except on
  removal.
  @param(character Unused.)
  @param(resource Unused.)
  @param(removed True when the effect is being removed.) }
procedure EffDispelEvil(var character: Pointer; resource: Pointer; removed: Boolean);

{ Effect 7: in combat sets the creature's damage and THAC0 from its distance to the target: in melee d6 + 2 plus its
  strength damage and to-hit bonuses, at range d4 + 1 plus its missile adjustment, each with the readied weapon's plus.
  @param(character Creature with the effect.)
  @param(resource Unused.)
  @param(removed Unused.) }
procedure EffSetAttackDamage(var character: Pointer; resource: Pointer; removed: Boolean);

{ Applies protection from evil: against an evil attacker (the current character) adds 2 to the saving throw and takes 2
  from the attack roll.
  @param(character Unused.)
  @param(resource Unused.)
  @param(removed Unused.) }
procedure EffProtEvil(var character: Pointer; resource: Pointer; removed: Boolean);

{ Effect 9 (Wearing Magical Boots): does nothing.
  @param(character Unused.)
  @param(resource Unused.)
  @param(removed True when the effect is being removed.) }
procedure EffMagicalBoots(var character: Pointer; resource: Pointer; removed: Boolean);

{ Applies resist cold: halves cold damage and adds 3 to the saving throw against it.
  @param(character Unused.)
  @param(resource Unused.)
  @param(removed Unused.) }
procedure EffResistCold(var character: Pointer; resource: Pointer; removed: Boolean);

{ Applies charm: the first time (strength bit 5 marks it), saves the creature's side in strength bit 6, moves it to the
  side in bit 7, makes it a quick fighter (NPC value $B3 unless the value is above $7F), drops its target and recounts
  the sides; each call except a removal sets morale to 100. On removal the saved side returns and the NPC value $B3 is
  cleared.
  @param(character The creature carrying the effect.)
  @param(resource The effect's node.)
  @param(removed True when the effect is being removed.) }
procedure EffCharm(var character: Pointer; resource: Pointer; removed: Boolean);

{ Effect 13 (Magically Highlighted): lowers the armor class and rear armor class by 2.
  @param(character Creature with the effect.)
  @param(resource Unused.)
  @param(removed Unused.) }
procedure EffMagicallyHighlighted(var character: Pointer; resource: Pointer; removed: Boolean);

{ Effect 15 (Slow Poison): unless the effect lock is set, renews itself for 10 minutes and takes a hit point while the
  creature has more than 1.
  @param(character Creature with the effect.)
  @param(resource The effect record.)
  @param(removed Unused.) }
procedure EffSlowPoisonHit(var character: Pointer; resource: Pointer; removed: Boolean);

{ Applies shield: raises the creature's armor class value to at least 57 (armor class 3), adds 1 to the saving throw,
  and stops Magic Missile.
  @param(character The creature carrying the effect.)
  @param(resource Unused.)
  @param(removed Unused.) }
procedure EffShield(var character: Pointer; resource: Pointer; removed: Boolean);

{ Half-elven resistance: a 30 percent chance to resist sleep and charm.
  @param(character Unused.)
  @param(resource Unused.)
  @param(removed Unused.) }
procedure EffHalfElfResistance(var character: Pointer; resource: Pointer; removed: Boolean);

{ Applies resist fire: halves fire damage and adds 3 to the saving throw against it, except on removal.
  @param(character Unused.)
  @param(resource Unused.)
  @param(removed True when the effect is being removed.) }
procedure EffResistFire(var character: Pointer; resource: Pointer; removed: Boolean);

{ Effect 21 (Silenced): in combat, no items or spells, and a spell being cast is lost.
  @param(character Creature with the effect.)
  @param(resource Unused.)
  @param(removed Unused.) }
procedure EffSilence(var character: Pointer; resource: Pointer; removed: Boolean);

{ Effect 22, the end of Slow Poison: a creature still poisoned collapses, and the slow poison is removed under the
  effect lock.
  @param(character Creature with the effect.)
  @param(resource Unused.)
  @param(removed Unused.) }
procedure EffSlowPoisonEnd(var character: Pointer; resource: Pointer; removed: Boolean);

{ Spiritual Hammer effect: adding it gives the creature a +1 spiritual hammer, readied if it has no weapon ready, unless
  it already has one or its pack is full; removing it takes the hammer away. The creature's statistics are then
  recalculated. Note: the search after adding the hammer stops one item past it, so a different item can be readied.
  @param(character The creature the effect is on.)
  @param(resource Unused.)
  @param(removed True when the effect is being removed.) }
procedure EffSpiritualHammer(var character: Pointer; resource: Pointer; removed: Boolean);

{ Applies invisibility: unless the current character can see invisible, it may not target the creature and takes 4 from
  its attack roll, except on removal.
  @param(character Unused.)
  @param(resource Unused.)
  @param(removed True when the effect is being removed.) }
procedure EffInvisible(var character: Pointer; resource: Pointer; removed: Boolean);

{ Effect 26, the dwarves': in combat, 1 on the attack roll against a target of the kind flag $80 marks.
  @param(character Creature with the effect.)
  @param(resource Unused.)
  @param(removed Unused.) }
procedure EffDwarfHitBonus(var character: Pointer; resource: Pointer; removed: Boolean);

{ Applies mirror image: an attack has a chance (strength div 16 images in strength div 16 + 1) to hit an image instead,
  which cancels it and loses an image; the effect ends with the last one. A spell aimed at an area never strikes an
  image.
  @param(character The creature carrying the effect.)
  @param(resource The effect's node.)
  @param(removed Unused.) }
procedure EffMirrorImage(var character: Pointer; resource: Pointer; removed: Boolean);

{ Effect 29 (Weakened): takes a quarter off the damage the creature deals.
  @param(character Unused.)
  @param(resource Unused.)
  @param(removed Unused.) }
procedure EffWeakened(var character: Pointer; resource: Pointer; removed: Boolean);

{ Nauseated effect: in combat the creature's pending action is cleared, with a coughing message if it had one, and it
  suffers -2 on both defense values.
  @param(character The creature the effect is on.)
  @param(resource Unused.)
  @param(removed Unused.) }
procedure EffCoughing(var character: Pointer; resource: Pointer; removed: Boolean);

{ Effect 32: a creature with the invisible flag ($40) cannot be targeted by an attacker that does not see invisible,
  which takes 4 off its attack roll.
  @param(character Creature with the effect.)
  @param(resource Unused.)
  @param(removed True when the effect is being removed.) }
procedure EffInvisibleByFlag(var character: Pointer; resource: Pointer; removed: Boolean);

{ Applies blindness: the attack roll, armor class, armor class from behind and saving throw each lose 4.
  @param(character The creature with the effect.)
  @param(resource Unused.)
  @param(removed Unused.) }
procedure EffBlind(var character: Pointer; resource: Pointer; removed: Boolean);

{ Effect 34 (Dispel Evil): in combat, an evil target that fails its save is dispelled and the dispel effects end;
  otherwise it resists.
  @param(character Creature with the effect.)
  @param(resource Unused.)
  @param(removed True when the effect is being removed.) }
procedure EffDispelEvilTouch(var character: Pointer; resource: Pointer; removed: Boolean);

{ Effect 35 (Confused): in combat a d100 decides the turn -- 1..10 it runs away in fear, 11..60 it loses the turn,
  61..80 it goes berserk, 81..100 it is enraged and acts -- and a save at -2 ends the confusion.
  @param(character Creature with the effect.)
  @param(resource The effect record.)
  @param(removed Unused.) }
procedure EffConfusion(var character: Pointer; resource: Pointer; removed: Boolean);

{ Effect 36 (Accursed): 4 off the attack and save rolls.
  @param(character Unused.)
  @param(resource Unused.)
  @param(removed Unused.) }
procedure EffCursed(var character: Pointer; resource: Pointer; removed: Boolean);

{ Effect 37 (Blinking): in combat, a creature that has acted cannot be targeted.
  @param(character Creature with the effect.)
  @param(resource Unused.)
  @param(removed Unused.) }
procedure EffBlinking(var character: Pointer; resource: Pointer; removed: Boolean);

{ Haste effect: ages the creature a year the first time (strength bit 4 marks it, and aging is noted for after the
  battle) and doubles its movement and attacks, except on removal.
  @param(character The creature carrying the effect.)
  @param(resource The effect's node.)
  @param(removed True when the effect is being removed.) }
procedure EffHasted(var character: Pointer; resource: Pointer; removed: Boolean);

{ Does nothing.
  @param(character Unused.)
  @param(resource Unused.)
  @param(removed Unused.) }
procedure EffNoneB(var character: Pointer; resource: Pointer; removed: Boolean);

{ Protection from Normal Missiles effect: a missile without a plus is always avoided.
  @param(character The creature carrying the effect.)
  @param(resource Unused.)
  @param(removed Unused.) }
procedure EffProtNormalMissiles(var character: Pointer; resource: Pointer; removed: Boolean);

{ Applies Slow: halves the movement and attacks, except on removal.
  @param(character Unused.)
  @param(resource Unused.)
  @param(removed True when the effect is being removed.) }
procedure EffSlowed(var character: Pointer; resource: Pointer; removed: Boolean);

{ Effect 47, the dwarves': an attacker of the kind flag $04 marks takes 4 off its attack roll.
  @param(character Unused.)
  @param(resource Unused.)
  @param(removed Unused.) }
procedure EffDwarfDefenseBonus(var character: Pointer; resource: Pointer; removed: Boolean);

{ Effect 48 (Barkskin): the armor class and rear armor class 1 higher, and 1 on the save roll except against saving
  throw 4.
  @param(character Creature with the effect.)
  @param(resource Unused.)
  @param(removed Unused.) }
procedure EffBarkskin(var character: Pointer; resource: Pointer; removed: Boolean);

{ Applies prayer: gives the side named by strength bit 4 a 1 bonus to saving throws and attack rolls and the other side
  a 1 penalty.
  @param(character The creature carrying the effect.)
  @param(resource The effect's node.)
  @param(removed Passed on to the bonus routine.) }
procedure EffPrayer(var character: Pointer; resource: Pointer; removed: Boolean);

{ Effect 50 (Fire Shield, hot flames): 2 on the save roll against cold, and double damage from fire when the save fails.
  @param(character Unused.)
  @param(resource Unused.)
  @param(removed Unused.) }
procedure EffFireShieldHot(var character: Pointer; resource: Pointer; removed: Boolean);

{ Effect 54 (Fire Shield, cold flames): 2 on the save roll against fire, and double damage from cold. Note: the double
  damage tests GDVars.recentlySaved, the game-saved flag, instead of the saving throw.
  @param(character Unused.)
  @param(resource Unused.)
  @param(removed Unused.) }
procedure EffFireShieldCold(var character: Pointer; resource: Pointer; removed: Boolean);

{ Does nothing for the poisoned effect.
  @param(character Unused.)
  @param(resource Unused.)
  @param(removed Unused.) }
procedure EffPoisoned(var character: Pointer; resource: Pointer; removed: Boolean);

{ Does nothing.
  @param(character Unused.)
  @param(resource Unused.)
  @param(removed Unused.) }
procedure EffNoneC(var character: Pointer; resource: Pointer; removed: Boolean);

{ Forced to dance: the armor class and rear armor class 4 lower.
  @param(character The creature with the effect.)
  @param(resource Unused.)
  @param(removed Unused.) }
procedure EffDancing(var character: Pointer; resource: Pointer; removed: Boolean);

{ Mind Blank: cancels a charm, confusion, hold, feeblemind or fear.
  @param(character Unused.)
  @param(resource Unused.)
  @param(removed Unused.) }
procedure EffMindBlank(var character: Pointer; resource: Pointer; removed: Boolean);

{ Effect 59 (Major Globe of Invulnerability): cancels spells below level 5.
  @param(character Unused.)
  @param(resource Unused.)
  @param(removed Unused.) }
procedure EffMajorGlobe(var character: Pointer; resource: Pointer; removed: Boolean);

{ Iron Skin: the armor class and rear armor class 4 higher.
  @param(character The creature with the effect.)
  @param(resource Unused.)
  @param(removed Unused.) }
procedure EffIronSkin(var character: Pointer; resource: Pointer; removed: Boolean);

{ Constitution regeneration, for Constitution 20 and over: unless the effect lock is set, renews itself for an hour and
  heals a hit point.
  @param(character Creature with the effect.)
  @param(resource The effect record.)
  @param(removed Unused.) }
procedure EffConRegeneration(var character: Pointer; resource: Pointer; removed: Boolean);

{ Applies minor globe of invulnerability: cancels spells below level 4.
  @param(character Unused.)
  @param(resource Unused.)
  @param(removed Unused.) }
procedure EffMinorGlobe(var character: Pointer; resource: Pointer; removed: Boolean);

{ Makes a hit poisonous: the target saves against poison or dies.
  @param(character The creature the effect is on.)
  @param(resource Unused.)
  @param(removed Unused.) }
procedure EffPoisonAttack(var character: Pointer; resource: Pointer; removed: Boolean);

{ Effect 65: no electrical damage.
  @param(character Unused.)
  @param(resource Unused.)
  @param(removed Unused.) }
procedure EffImmuneElectricity(var character: Pointer; resource: Pointer; removed: Boolean);

{ Effect 66: only a weapon of +3 or better hurts the creature, unless the attacker is a monster of level 4 or more.
  @param(character Unused.)
  @param(resource Unused.)
  @param(removed Unused.) }
procedure EffRequirePlusThreeWeapon(var character: Pointer; resource: Pointer; removed: Boolean);

{ Effect 67: a hit drains a level from the target.
  @param(character Creature with the effect.)
  @param(resource Unused.)
  @param(removed Unused.) }
procedure EffDrainOne(var character: Pointer; resource: Pointer; removed: Boolean);

{ Effect 68: a hit drains two levels from the target.
  @param(character Creature with the effect.)
  @param(resource Unused.)
  @param(removed Unused.) }
procedure EffDrainTwo(var character: Pointer; resource: Pointer; removed: Boolean);

{ Paralyzing-hit effect: a hit paralyzes the target for 100 minutes unless it saves.
  @param(character The creature carrying the effect.)
  @param(resource Unused.)
  @param(removed Unused.) }
procedure EffParalyzingHit(var character: Pointer; resource: Pointer; removed: Boolean);

{ Effect 70: burns every creature beside the creature for d6 fire damage.
  @param(character Creature with the effect.)
  @param(resource Unused.)
  @param(removed Unused.) }
procedure EffImmolate(var character: Pointer; resource: Pointer; removed: Boolean);

{ Reflects a spell back at its caster (the current character): always one of area type above 14, one time in ten one of
  area type below 8.
  @param(character The creature carrying the effect.)
  @param(resource Unused.)
  @param(removed Unused.) }
procedure EffReflectSpell(var character: Pointer; resource: Pointer; removed: Boolean);

{ Effect 72: each enemy beside the creature that is not immune and fails its save is terrified and flees.
  @param(character Creature with the effect.)
  @param(resource Unused.)
  @param(removed Unused.) }
procedure EffDragonFear(var character: Pointer; resource: Pointer; removed: Boolean);

{ Effect 73, immune to dragon breath: cancels a breath attack.
  @param(character The creature with the effect.)
  @param(resource Unused.)
  @param(removed Unused.) }
procedure EffImmuneBreath(var character: Pointer; resource: Pointer; removed: Boolean);

{ Effect 74 (Fire Touch): in combat, a hit also burns the target for 2d6, halved when it saves.
  @param(character Creature with the effect.)
  @param(resource Unused.)
  @param(removed Unused.) }
procedure EffFireTouch(var character: Pointer; resource: Pointer; removed: Boolean);

{ Effect 75: double damage from cold.
  @param(character Unused.)
  @param(resource Unused.)
  @param(removed Unused.) }
procedure EffColdVulnerable(var character: Pointer; resource: Pointer; removed: Boolean);

{ Effect 76: fire does no harm, and magical fire heals the creature by the damage instead.
  @param(character Creature with the effect.)
  @param(resource Unused.)
  @param(removed Unused.) }
procedure EffHealedByFire(var character: Pointer; resource: Pointer; removed: Boolean);

{ Applies berserk: the creature fights under AI control (NPC value $B3, or $B2 for an NPC above $7F other than $B3); in
  combat it drops its target, takes the second creature of a full target list instead, may not cast, and joins the side
  opposed to that target, with a 'goes berserk' message. On removal a $B3 creature leaves AI control and the creature
  returns to the party's side.
  @param(character The creature carrying the effect.)
  @param(resource Unused.)
  @param(removed True when the effect is being removed.) }
procedure EffBerserk(var character: Pointer; resource: Pointer; removed: Boolean);

{ Applies evil stench: each enemy next to the creature that fails a saving throw (type 4) is affected. Note: the stench
  penalty goes on the creature emitting the stench, not on the enemy affected.
  @param(character The creature carrying the effect.)
  @param(resource Unused.)
  @param(removed Unused.) }
procedure EffEvilStench(var character: Pointer; resource: Pointer; removed: Boolean);

{ Effect 80: cancels confusion.
  @param(character Unused.)
  @param(resource Unused.)
  @param(removed Unused.) }
procedure EffImmuneConfusion(var character: Pointer; resource: Pointer; removed: Boolean);

{ Effect 83: halves cold and electrical damage.
  @param(character Unused.)
  @param(resource Unused.)
  @param(removed Unused.) }
procedure EffResistColdAndElectricity(var character: Pointer; resource: Pointer; removed: Boolean);

{ Effect 84: heals 3 hit points, up to the maximum.
  @param(character Creature with the effect.)
  @param(resource Unused.)
  @param(removed Unused.) }
procedure EffRegenerateThree(var character: Pointer; resource: Pointer; removed: Boolean);

{ Makes a hit strongly poisonous: the target saves against poison, at -2, or dies.
  @param(character The creature the effect is on.)
  @param(resource Unused.)
  @param(removed Unused.) }
procedure EffStrongPoisonAttack(var character: Pointer; resource: Pointer; removed: Boolean);

{ Applies the iron golem's immunity: a fire attack with element bit 3 heals the creature by the damage (to its maximum),
  an electrical attack slows it, and each attack is canceled, on removal too.
  @param(character The creature carrying the effect.)
  @param(resource Unused.)
  @param(removed Unused.) }
procedure EffIronGolem(var character: Pointer; resource: Pointer; removed: Boolean);

{ Applies ghoul touch: a hit paralyzes a target that is not a Silvanesti or Qualinesti elf for 100 minutes unless it
  saves.
  @param(character The creature carrying the effect.)
  @param(resource Unused.)
  @param(removed Unused.) }
procedure EffGhoulPara(var character: Pointer; resource: Pointer; removed: Boolean);

{ Applies displacement: the first attack on the creature misses; the mark in strength bit 4 is cleared only in round 0
  on a zero attack roll.
  @param(character Unused.)
  @param(resource The effect's node.)
  @param(removed Unused.) }
procedure EffDisplaced(var character: Pointer; resource: Pointer; removed: Boolean);

{ Effect 91: does nothing.
  @param(character Unused.)
  @param(resource Unused.)
  @param(removed Unused.) }
procedure EffWantsToKill(var character: Pointer; resource: Pointer; removed: Boolean);

{ Effect 92, the kender's: cancels fear.
  @param(character Unused.)
  @param(resource Unused.)
  @param(removed Unused.) }
procedure EffImmuneFear(var character: Pointer; resource: Pointer; removed: Boolean);

{ Halves the damage of weapons of class 0 and 1.
  @param(character Unused.)
  @param(resource Unused.)
  @param(removed Unused.) }
procedure EffHalfDamageFromWeaponClass(var character: Pointer; resource: Pointer; removed: Boolean);

{ Constitution save bonus: adds 1 to 5, for Constitution 4 to 20, to saving throws of types 0, 2 and 4. Note: other
  Constitution values leave the bonus undefined.
  @param(character The creature carrying the effect.)
  @param(resource Unused.)
  @param(removed Unused.) }
procedure EffConSpellSave(var character: Pointer; resource: Pointer; removed: Boolean);

{ Elven resistance: a 90 percent chance to resist sleep and charm.
  @param(character Unused.)
  @param(resource Unused.)
  @param(removed Unused.) }
procedure EffElfResistance(var character: Pointer; resource: Pointer; removed: Boolean);

{ Immunity to sleep and charm: charm and sleep have no effect.
  @param(character Unused.)
  @param(resource Unused.)
  @param(removed Unused.) }
procedure EffImmuneSleepCharm(var character: Pointer; resource: Pointer; removed: Boolean);

{ Immunity to paralysis: paralysis has no effect.
  @param(character Unused.)
  @param(resource Unused.)
  @param(removed Unused.) }
procedure EffImmuneParalysis(var character: Pointer; resource: Pointer; removed: Boolean);

{ Applies cold immunity: cancels the effect and the damage of cold attacks.
  @param(character Unused.)
  @param(resource Unused.)
  @param(removed Unused.) }
procedure EffImmuneCold(var character: Pointer; resource: Pointer; removed: Boolean);

{ Immunity to poison and paralysis: poison and paralysis have no effect, and saving throws of type 0 always succeed.
  @param(character Unused.)
  @param(resource Unused.)
  @param(removed Unused.) }
procedure EffImmuneParalysisPoison(var character: Pointer; resource: Pointer; removed: Boolean);

{ Effect 101: magical electricity heals the creature by the dice count, magical fire or cold slows it for 2d6 rounds,
  and no element harms it.
  @param(character Creature with the effect.)
  @param(resource Unused.)
  @param(removed Unused.) }
procedure EffShockHealsFireSlows(var character: Pointer; resource: Pointer; removed: Boolean);

{ Effect 103: only a magical weapon hurts the creature, unless the attacker is a monster of level 4 or more.
  @param(character Unused.)
  @param(resource Unused.)
  @param(removed Unused.) }
procedure EffWeaponResistance(var character: Pointer; resource: Pointer; removed: Boolean);

{ Effect 105: in combat, against a target of the kind flag $08 marks, adds the ranger level to the damage.
  @param(character Creature with the effect.)
  @param(resource Unused.)
  @param(removed Unused.) }
procedure EffRangerDamageBonus(var character: Pointer; resource: Pointer; removed: Boolean);

{ Effect 106: blinds with smoke the most dangerous enemy beside the creature that is not blinded already, unless it
  saves.
  @param(character Creature with the effect.)
  @param(resource Unused.)
  @param(removed Unused.) }
procedure EffSmokeBlinds(var character: Pointer; resource: Pointer; removed: Boolean);

{ Effect 107 (Berserk): in combat the creature fights on its own against the nearest creature, taking the other side;
  when removed it returns to the side kept in the effect's strength.
  @param(character Creature with the effect.)
  @param(resource The effect record.)
  @param(removed True when the effect is being removed.) }
procedure EffConfusedBerserk(var character: Pointer; resource: Pointer; removed: Boolean);

{ Effect 108 (Blinded by Smoke): 2 off the damage and the attack roll.
  @param(character Unused.)
  @param(resource Unused.)
  @param(removed Unused.) }
procedure EffBlindedBySmoke(var character: Pointer; resource: Pointer; removed: Boolean);

{ Effect 109, a paladin's lay on hands used for the day: does nothing.
  @param(character Unused.)
  @param(resource Unused.)
  @param(removed Unused.) }
procedure EffLayOnHandsUsed(var character: Pointer; resource: Pointer; removed: Boolean);

{ Effect 110: when removed, a paladin's cure-disease uses return to level div 5 + 1.
  @param(character Creature with the effect.)
  @param(resource Unused.)
  @param(removed True when the effect is being removed.) }
procedure EffPaladinCureReset(var character: Pointer; resource: Pointer; removed: Boolean);

{ Applies fear: on removal a $B3 creature leaves AI control and the creature is no longer forced to flee.
  @param(character The creature carrying the effect.)
  @param(resource Unused.)
  @param(removed True when the effect is being removed.) }
procedure EffFear(var character: Pointer; resource: Pointer; removed: Boolean);

{ Zaps an adjacent attacker (the current character): it 'gets zapped' for twice the pending damage, as magic.
  @param(character The creature carrying the effect.)
  @param(resource Unused.)
  @param(removed Unused.) }
procedure EffZapAttacker(var character: Pointer; resource: Pointer; removed: Boolean);

{ Effect 113 (Frost Giant Strength): does nothing.
  @param(character Unused.)
  @param(resource Unused.)
  @param(removed Unused.) }
procedure EffFrostGiantStrength(var character: Pointer; resource: Pointer; removed: Boolean);

{ Effect 114: in combat, against a target with immunity flag $01, the damage equals the creature's hit points.
  @param(character Creature with the effect.)
  @param(resource Unused.)
  @param(removed Unused.) }
procedure EffDamageEqualsHitPoints(var character: Pointer; resource: Pointer; removed: Boolean);

{ Effect 115: in combat, 3 more damage against a target of the kind flag $20 marks.
  @param(character Creature with the effect.)
  @param(resource Unused.)
  @param(removed Unused.) }
procedure EffTypeDamageBonus(var character: Pointer; resource: Pointer; removed: Boolean);

{ Effect 117: in combat, double damage against a target of the kind flag $02 marks, and undead are disrupted.
  @param(character Creature with the effect.)
  @param(resource Unused.)
  @param(removed True when the effect is being removed.) }
procedure EffDisruption(var character: Pointer; resource: Pointer; removed: Boolean);

{ Effect 118: 2 off the attack roll.
  @param(character Unused.)
  @param(resource Unused.)
  @param(removed Unused.) }
procedure EffEvilStenchPenalty(var character: Pointer; resource: Pointer; removed: Boolean);

{ Does nothing.
  @param(character Unused.)
  @param(resource Unused.)
  @param(removed Unused.) }
procedure EffNone(var character: Pointer; resource: Pointer; removed: Boolean);

{ The override handler for an item's special effect: adds the item's effect to the creature (removed through its
  handler) or, on removal, takes it away, and clears the override flag.
  @param(character The creature readying or unreadying the item.)
  @param(resource The item whose effect is granted.)
  @param(removed True when the item is unreadied.) }
procedure EffGrantItemEffect(var character: Pointer; resource: Pointer; removed: Boolean);
implementation
uses C_Class, C_Effect, C_Ifc, C_Npc, C_Race, C_Side, C_Spell, C_Stat, C_Status, GDConsts, GDVars,
  ClassCal, ViewChar, CharHlp, FxEngine, CbtMap, Pathing, TextRend, Types;
const
  { the effect id (TEffect.effectId) of seeing invisible creatures }
  SEE_INVISIBLE = 24;
  { TCharacter.npc of a creature outside the party that goes berserk }
  NPC_ANIMATED_NPC = $B2;
type
  { a class level, which is never negative }
  TLevel = 0..127;

{ In combat, holds the creature's target for some minutes unless it saves against paralysis.
  @param(character Creature striking.)
  @param(minutes How long the hold lasts.)
  @param(saveMod Unused.) }
procedure ParalyzeTarget(var character: Types.PCharacter; minutes: Word; saveMod: Byte);
begin
  if GDVars.interfaceState = C_Ifc.IN_COMBAT then begin
    GDVars.effectTarget := character^.combat^.target;
    if not FxEngine.RollSavingThrow(GDVars.effectTarget, 0, 0) then begin
      CharHlp.PrintNameStringAnim(GDVars.effectTarget, True, GDConsts.paralyzedText);
      FxEngine.AddEffect(GDVars.effectTarget, C_Effect.HELD, minutes, 12, False)
    end
  end
end;

{ Cancels the pending effect and the damage when the given effect is 0 or is the effect being applied.
  @param(effectId The effect to cancel, or 0 for whichever effect is pending.) }
procedure NullifyAttack(effectId: Byte);
begin
  if (effectId = 0) or (GDVars.currentEffectId = effectId) then begin
    GDVars.currentDamage := 0;
    GDVars.currentEffectId := 0
  end
end;

{ Adds an effect, removed through its handler, unless the effect lock is set.
  @param(character The creature given the effect.)
  @param(effectId The effect.)
  @param(strength Its strength.)
  @param(minutes Its duration.)
  @returns(True when the effect was added.) }
function AddEffectIfNoLock(var character: Pointer; effectId, strength: Byte; minutes: Word): Boolean;
begin
  if GDVars.effectLock <> 0 then AddEffectIfNoLock := False
  else begin
    AddEffectIfNoLock := True;
    FxEngine.AddEffect(character, effectId, minutes, strength, True)
  end
end;

procedure EffHelpless(var character: Pointer; resource: Pointer; removed: Boolean);
var
  { Unused in this version; see the other implementations of this routine. }
  status: Boolean;
begin
  status := CharHlp.EndActions(character)
end;

procedure EffEndActions(var character: Pointer; resource: Pointer; removed: Boolean);
var
  { Unused in this version; see the other implementations of this routine. }
  status: Boolean;
begin
  status := CharHlp.EndActions(character)
end;

{ Prayer, for an ally: adds 1 to the save and attack rolls.
  @param(character Unused.)
  @param(resource Unused.)
  @param(value Unused.) }
procedure ImproveRolls(var character: Pointer; resource: Pointer; value: Byte);
begin
  Inc(GDVars.currentSaveRoll);
  Inc(GDVars.currentAttackRoll)
end;

procedure EffBless(var character: Pointer; resource: Pointer; removed: Boolean);
begin
  Inc(GDVars.moraleValue, 5);
  Inc(GDVars.currentAttackRoll)
end;

procedure EffStunOnHit(var character: Pointer; resource: Pointer; removed: Boolean);
var target: Pointer;
begin
  if (GDVars.interfaceState = C_Ifc.IN_COMBAT) and not removed then begin
    target := Types.PCharacter(character)^.combat^.target;
    if not FxEngine.RollSavingThrow(target, 1, 0) then
      FxEngine.AddEffectWithMessage(target, C_Effect.ENTANGLED, 3, 0, 0, 0, 0, GDConsts.stunnedText)
  end
end;

procedure EffSticksToSnakes(var character: Pointer; resource: Pointer; removed: Boolean);
var amount: Byte;
    { Unused in this version; see the other implementations of this routine. }
    status: Boolean;
begin
  amount := Types.PCharacter(character)^.attacksLeft[1] + Types.PCharacter(character)^.attacksLeft[2];
  if Types.PEffect(resource)^.strength > amount then
    Dec(Types.PEffect(resource)^.strength, amount)
  else
    FxEngine.RemoveEffect(character, C_Effect.SNAKES, nil);
  CharHlp.PrintNameStringAnim(character, True, GDConsts.fightingSnakesText);
  CharHlp.ClearMessageWindow;
  status := CharHlp.EndActions(character)
end;

procedure EffDispelEvil(var character: Pointer; resource: Pointer; removed: Boolean);
begin
  if not removed and ((GDVars.currentCharacter^.typeFlags and $01) <> 0) then
    Dec(GDVars.currentAttackRoll, 7)
end;

procedure EffSetAttackDamage(var character: Pointer; resource: Pointer; removed: Boolean);
var target: Pointer;
    distance: Byte;
    weaponPlus: Byte;
begin
  if GDVars.interfaceState = C_Ifc.IN_COMBAT then begin
    if Types.PCharacter(character)^.equipped[0] <> nil then
      weaponPlus := Types.PCharacter(character)^.equipped[0]^.plus;
    target := Types.PCharacter(character)^.combat^.target;
    distance := CharHlp.CalcDistance(character, target);
    Types.PCharacter(character)^.thac0Adjusted := Types.PCharacter(character)^.thac0Base;
    if distance < 2 then begin
      GDVars.currentDamage := weaponPlus + (FxEngine.RollDamageDice(1,
                                                                      6) + CharHlp.StrDamageAdjust(character) + 2);
      Types.PCharacter(character)^.thac0Adjusted :=
        Types.PCharacter(character)^.thac0Adjusted + CharHlp.StrToHitAdjust(character)
    end else begin
      GDVars.currentDamage := weaponPlus + (FxEngine.RollDamageDice(1, 4) + 1);
      Types.PCharacter(character)^.thac0Adjusted := Types.PCharacter(character)^.thac0Adjusted +
          CharHlp.DexMissileAdjust(character)
    end
  end
end;

procedure EffProtEvil(var character: Pointer; resource: Pointer; removed: Boolean);
begin
  if (GDVars.currentCharacter^.alignment = 2) or
      (GDVars.currentCharacter^.alignment = 5) or
      (GDVars.currentCharacter^.alignment = 8) then begin
    Inc(GDVars.currentSaveRoll, 2);
    Dec(GDVars.currentAttackRoll, 2)
  end
end;

procedure EffMagicalBoots(var character: Pointer; resource: Pointer; removed: Boolean);
var
  { Unused in this version; see the other implementations of this routine. }
  effect: Pointer;
begin
  if not removed then begin end
end;

procedure EffResistCold(var character: Pointer; resource: Pointer; removed: Boolean);
begin
  if (GDVars.elementMask and $02) <> 0 then begin
    GDVars.currentDamage := GDVars.currentDamage div 2;
    Inc(GDVars.currentSaveRoll, 3)
  end
end;

procedure EffCharm(var character: Pointer; resource: Pointer; removed: Boolean);
begin
  if removed then begin
    Types.PCharacter(character)^.side := (Types.PEffect(resource)^.strength and $40) div $40;
    if Types.PCharacter(character)^.npc = C_Npc.ANIMATED_PLAYER then begin
      Types.PCharacter(character)^.npc := 0;
      Types.PCharacter(character)^.quickFight := 0
    end
  end else begin
    if (Types.PEffect(resource)^.strength and $20) = 0 then begin
      Types.PEffect(resource)^.strength := Types.PEffect(resource)^.strength + $20 +
          (Types.PCharacter(character)^.side * $40);
      Types.PCharacter(character)^.side := Types.PEffect(resource)^.strength div $80;
      Types.PCharacter(character)^.quickFight := 1;
      if Types.PCharacter(character)^.npc <= $7F then
        Types.PCharacter(character)^.npc := C_Npc.ANIMATED_PLAYER;
      Types.PCharacter(character)^.combat^.target := nil;
      CharHlp.CountTeams
    end;
    GDVars.moraleValue := 100
  end
end;

procedure EffMagicallyHighlighted(var character: Pointer; resource: Pointer; removed: Boolean);
begin
  Dec(Types.PCharacter(character)^.armorClass, 2);
  Dec(Types.PCharacter(character)^.rearArmorClass, 2)
end;

procedure EffSlowPoisonHit(var character: Pointer; resource: Pointer; removed: Boolean);
begin
  if EffHndlr.AddEffectIfNoLock(character, C_Effect.SLOW_POISON_HIT, Types.PEffect(resource)^.strength,
                                10) and (Types.PCharacter(character)^.hitPoints > 1) then begin
    GDVars.elementMask := 0;
    FxEngine.InflictNonWeaponDamage(character, 1, 0, False);
    if GDVars.interfaceState <> C_Ifc.IN_COMBAT then
      CharHlp.DisplayRoster(character, character = GDVars.currentCharacter)
  end
end;

procedure EffShield(var character: Pointer; resource: Pointer; removed: Boolean);
begin
  if Types.PCharacter(character)^.armorClass < 57 then
    Types.PCharacter(character)^.armorClass := 57;
  Inc(GDVars.currentSaveRoll);
  if GDVars.currentSpellIndex = C_Spell.MAGIC_MISSILE then GDVars.currentDamage := 0
end;

procedure EffHalfElfResistance(var character: Pointer; resource: Pointer; removed: Boolean);
begin
  if FxEngine.RollDice(1, 100) <= 30 then begin
    EffHndlr.NullifyAttack(C_Effect.CHARM);
    EffHndlr.NullifyAttack(C_Effect.SLEEP)
  end
end;

procedure EffResistFire(var character: Pointer; resource: Pointer; removed: Boolean);
begin
  if not removed and ((GDVars.elementMask and $01) <> 0) then begin
    GDVars.currentDamage := GDVars.currentDamage shr 1;
    Inc(GDVars.currentSaveRoll, 3)
  end
end;

procedure EffSilence(var character: Pointer; resource: Pointer; removed: Boolean);
var
  { Unused in this version; see the other implementations of this routine. }
  status: Boolean;
begin
  if GDVars.interfaceState = C_Ifc.IN_COMBAT then begin
    if Types.PCharacter(character)^.combat^.canUseItem <> 0 then
      CharHlp.PrintCreatureMessage(character, GDConsts.silencedText, 10, True);
    Types.PCharacter(character)^.combat^.canUseItem := 0;
    Types.PCharacter(character)^.combat^.canCast := 0;
    if Types.PCharacter(character)^.combat^.spellCast > 0 then begin
      CharHlp.PrintCreatureMessage(character, GDConsts.lostSpellMessage, 12, True);
      CharHlp.RemoveSpell(character, Types.PCharacter(character)^.combat^.spellCast);
      status := CharHlp.EndActions(character)
    end
  end
end;

procedure EffSlowPoisonEnd(var character: Pointer; resource: Pointer; removed: Boolean);
var node: Pointer;
begin
  if CharHlp.HasEffect(character, C_Effect.POISONED, node) then
    FxEngine.KillCreature(character, C_Status.UNCONSCIOUS, GDConsts.poisonCollapseText);
  GDVars.effectLock := 1;
  FxEngine.RemoveEffect(character, C_Effect.SLOW_POISON_HIT, nil);
  GDVars.effectLock := 0
end;

procedure EffSpiritualHammer(var character: Pointer; resource: Pointer; removed: Boolean);
var node: Types.PItem;
    found: Boolean;
    savedCharacter: Pointer;
begin
  node := Types.PCharacter(character)^.items;
  found := False;
  while (node <> nil) and not found do
    if (node^.itemType = 6) and (node^.nameIds[3] = 121) then found := True
    else node := node^.next;
  if (removed) and (node <> nil) then
    CharHlp.RemoveItem(character, Types.PItem(node));
  if (not removed) and not found and (Types.PCharacter(character)^.numberOfItems < 16) then begin
    GetMem(node, SizeOf(Types.TItem));
    FillChar(node^, SizeOf(Types.TItem), 0);
    node^.itemType := 6;
    node^.nameIds[2] := 6;
    node^.nameIds[3] := 121;
    node^.plus := 1;
    node^.effect := C_Effect.SPIRITUAL_HAMMER;
    node^.special := $80;
    CharHlp.AddItemCopy(character, Types.PItem(node));
    FreeMem(node, SizeOf(Types.TItem));
    node := Types.PCharacter(character)^.items;
    found := False;
    while (node <> nil) and not found do begin
      found := (node^.nameIds[3] = 121) and (node^.itemType = 6);
      node := node^.next
    end;
    savedCharacter := GDVars.currentCharacter;
    GDVars.currentCharacter := character;
    if (node <> nil) and (Types.PCharacter(character)^.equipped[0] = nil) then begin
      ViewChar.ToggleReadyItem(node);
      node^.equipped := 1
    end;
    GDVars.currentCharacter := savedCharacter;
    CharHlp.PrintCreatureMessage(character, GDConsts.gainsItemText, 10, True)
  end;
  CharHlp.RecalcStats(character)
end;

procedure EffInvisible(var character: Pointer; resource: Pointer; removed: Boolean);
var node: Pointer;
begin
  if (not removed) and not CharHlp.HasEffect(GDVars.currentCharacter, EffHndlr.SEE_INVISIBLE, node) then begin
    GDVars.targetRefused := 1;
    Dec(GDVars.currentAttackRoll, 4)
  end
end;

procedure EffDwarfHitBonus(var character: Pointer; resource: Pointer; removed: Boolean);
var
  { Unused in this version; see the other implementations of this routine. }
  foeIndex: Word;
begin
  if GDVars.interfaceState = C_Ifc.IN_COMBAT then begin
    GDVars.effectTarget := Types.PCharacter(character)^.combat^.target;
    if (GDVars.effectTarget^.typeFlags and $80) <> 0 then Inc(GDVars.currentAttackRoll)
  end
end;

procedure EffMirrorImage(var character: Pointer; resource: Pointer; removed: Boolean);
begin
  if (FxEngine.RollDice(1, (Types.PEffect(resource)^.strength div $10) + 1) > 1) and
      ((GDVars.currentSpellIndex <= 0) or (GDVars.areaSpellActive = 0)) then begin
    EffHndlr.NullifyAttack(0);
    CharHlp.PrintCreatureMessage(character, GDConsts.lostImageText, 10, True);
    Dec(Types.PEffect(resource)^.strength);
    if Types.PEffect(resource)^.strength = 0 then
      FxEngine.RemoveEffect(character, C_Effect.MIRROR_IMAGE, nil)
  end
end;

procedure EffWeakened(var character: Pointer; resource: Pointer; removed: Boolean);
begin
  GDVars.currentDamage := GDVars.currentDamage - (GDVars.currentDamage div 4)
end;

procedure EffCoughing(var character: Pointer; resource: Pointer; removed: Boolean);
begin
  if GDVars.interfaceState = C_Ifc.IN_COMBAT then begin
    if Types.PCharacter(character)^.combat^.canUseItem <> 0 then
      CharHlp.PrintCreatureMessage(character, GDConsts.coughingText, 10, True);
    Types.PCharacter(character)^.combat^.canUseItem := 0;
    Types.PCharacter(character)^.combat^.canCast := 0;
    CharHlp.RecalcStats(character);
    Dec(Types.PCharacter(character)^.armorClass, 2);
    Dec(Types.PCharacter(character)^.rearArmorClass, 2);
    if character = GDVars.currentCharacter then CharHlp.CombatPrintCreatureInfo(character)
  end
end;

procedure EffInvisibleByFlag(var character: Pointer; resource: Pointer; removed: Boolean);
var node: Pointer;
begin
  if (not removed) and ((Types.PCharacter(character)^.typeFlags and $40) <> 0) and
      not CharHlp.HasEffect(character, EffHndlr.SEE_INVISIBLE, node) then begin
    GDVars.targetRefused := 1;
    Dec(GDVars.currentAttackRoll, 4)
  end
end;

procedure EffBlind(var character: Pointer; resource: Pointer; removed: Boolean);
begin
  Dec(GDVars.currentAttackRoll, 4);
  Dec(Types.PCharacter(character)^.armorClass, 4);
  Dec(Types.PCharacter(character)^.rearArmorClass, 4);
  Dec(GDVars.currentSaveRoll, 4)
end;

procedure EffDispelEvilTouch(var character: Pointer; resource: Pointer; removed: Boolean);
begin
  if (not removed) and (GDVars.interfaceState = C_Ifc.IN_COMBAT) then begin
    GDVars.effectTarget := Types.PCharacter(character)^.combat^.target;
    if ((GDVars.effectTarget^.typeFlags and $01) <> 0) and
        not FxEngine.RollSavingThrow(GDVars.effectTarget, 4, 0) then begin
      FxEngine.KillCreature(GDVars.effectTarget, C_Status.GONE, GDConsts.dispelledText);
      FxEngine.RemoveEffect(character, C_Effect.DISPELLING_EVIL, nil);
      FxEngine.RemoveEffect(character, C_Effect.DISPEL_EVIL, nil)
    end else begin
      CharHlp.PrintCreatureMessage(GDVars.effectTarget, GDConsts.resistsDispelEvilText, 10, True);
      TextRend.PauseOnly
    end
  end
end;

procedure EffConfusion(var character: Pointer; resource: Pointer; removed: Boolean);
var roll: Byte;
    status: Boolean;
begin
  if GDVars.interfaceState = C_Ifc.IN_COMBAT then begin
    roll := FxEngine.RollDice(1, 100);
    case roll of
    1..10: begin
      FxEngine.RemoveEffect(character, C_Effect.CONFUSED, nil);
      Types.PCharacter(character)^.combat^.panicked := 1;
      Types.PCharacter(character)^.quickFight := 1;
      if Types.PCharacter(character)^.npc <= $7F then
        Types.PCharacter(character)^.npc := C_Npc.ANIMATED_PLAYER;
      Types.PCharacter(character)^.combat^.target := nil;
      FxEngine.AddEffectWithMessage(character, C_Effect.FEAR, 10, 0, 1, 1, 0, GDConsts.runsAwayText)
    end;
    11..60: begin
      CharHlp.PrintNameStringAnim(character, True, GDConsts.confusedText);
      CharHlp.ClearMessageWindow;
      EffHndlr.EffHelpless(character, resource, False)
    end;
    61..80: begin
      FxEngine.AddEffectWithMessage(character, C_Effect.BERSERK, 1, Types.PCharacter(character)^.side, 1, 1, 0,
                                    GDConsts.berserkText);
      FxEngine.CallEffectHandler(C_Effect.BERSERK, character, nil, False)
    end;
    81..100: begin
      CharHlp.PrintNameStringAnim(character, True, GDConsts.enragedText);
      CharHlp.ClearMessageWindow
    end
    end;
    status := FxEngine.RollSavingThrow(character, 4, 254);
    if status then FxEngine.RemoveEffect(character, C_Effect.CONFUSED, nil)
  end
end;

procedure EffCursed(var character: Pointer; resource: Pointer; removed: Boolean);
begin
  Dec(GDVars.currentAttackRoll, 4);
  Dec(GDVars.currentSaveRoll, 4)
end;

procedure EffBlinking(var character: Pointer; resource: Pointer; removed: Boolean);
begin
  if (GDVars.interfaceState = C_Ifc.IN_COMBAT) and (Types.PCharacter(character)^.combat^.initiative = 0) then begin
    GDVars.targetRefused := 1;
    GDVars.currentAttackRoll := -1
  end
end;

procedure EffHasted(var character: Pointer; resource: Pointer; removed: Boolean);
begin
  if not removed then begin
    if (Types.PEffect(resource)^.strength and $10) = 0 then begin
      Types.PEffect(resource)^.strength := Types.PEffect(resource)^.strength + $10;
      CharHlp.PrintCreatureMessage(character, GDConsts.agesText, 10, True);
      Inc(Types.PCharacter(character)^.age);
      GDVars.agePassFlag := 1
    end;
    GDVars.adjustedAttackRate := GDVars.adjustedAttackRate * 2;
    GDVars.movementRate := GDVars.movementRate * 2
  end
end;

procedure EffNoneB(var character: Pointer; resource: Pointer; removed: Boolean);
begin end;

{ Protection from missiles: in combat, an attack with a weapon from beyond an adjacent cell misses on d100 within the
  threshold.
  @param(target Creature protected.)
  @param(threshold Chance of avoiding it, in percent.) }
procedure AvoidMissile(var target: Pointer; threshold: Byte);
begin
  if (GDVars.interfaceState = C_Ifc.IN_COMBAT) and
      (GDVars.currentCharacter^.equipped[0] <> nil) and
      (CharHlp.CalcDistance(GDVars.currentCharacter, target) > 1) and
      (FxEngine.RollDice(1, 100) <= threshold) then begin
    CharHlp.PrintCreatureMessage(target, GDConsts.avoidsItText, 10, True);
    GDVars.currentDamage := 0;
    GDVars.currentAttackRoll := -1;
    Dec(GDVars.hitsMade[1])
  end
end;

{ Finds the item a creature attacks with: the missile its readied weapon fires or throws, else the readied weapon.
  @param(character The creature.)
  @returns(The item, or nil with no weapon readied.) }
function FindDamagingWeapon(character: Types.PCharacter): Types.PItem;
var candidate: Pointer;
    itemCandidate: Types.PItem absolute candidate;
    status: Boolean;
begin
  candidate := nil;
  if Types.PCharacter(character)^.equipped[0] <> nil then begin
    status := CharHlp.FindDamagingRangedWeapon(character, itemCandidate);
    if not status or (candidate = nil) then
      candidate := Types.PCharacter(character)^.equipped[0]
  end;
  FindDamagingWeapon := candidate
end;

procedure EffProtNormalMissiles(var character: Pointer; resource: Pointer; removed: Boolean);
begin
  if EffHndlr.FindDamagingWeapon(GDVars.currentCharacter) <> nil then
    if EffHndlr.FindDamagingWeapon(GDVars.currentCharacter)^.plus = 0 then
      EffHndlr.AvoidMissile(character, 100)
end;

procedure EffSlowed(var character: Pointer; resource: Pointer; removed: Boolean);
begin
  if removed then begin end
  else begin
    GDVars.adjustedAttackRate := GDVars.adjustedAttackRate div 2;
    GDVars.movementRate := GDVars.movementRate div 2
  end
end;

procedure EffDwarfDefenseBonus(var character: Pointer; resource: Pointer; removed: Boolean);
var
  { Unused in this version; see the other implementations of this routine. }
  foeIndex: Word;
begin
  if (GDVars.currentCharacter^.typeFlags and $04) <> 0 then Dec(GDVars.currentAttackRoll, 4)
end;

procedure EffBarkskin(var character: Pointer; resource: Pointer; removed: Boolean);
begin
  Inc(Types.PCharacter(character)^.armorClass);
  Inc(Types.PCharacter(character)^.rearArmorClass);
  if (GDVars.currentSpellIndex = 0) or
      (GDConsts.spellTable[GDVars.currentSpellIndex].saveType <> 4) then Inc(GDVars.currentSaveRoll)
end;

procedure EffPrayer(var character: Pointer; resource: Pointer; removed: Boolean);
var casterSide: Byte;
begin
  casterSide := (Types.PEffect(resource)^.strength and $10) div $10;
  if Byte(Types.PCharacter(character)^.side) = casterSide then
    EffHndlr.ImproveRolls(character, resource, Ord(removed))
  else begin
    Dec(GDVars.currentAttackRoll);
    Dec(GDVars.currentSaveRoll)
  end
end;

procedure EffFireShieldHot(var character: Pointer; resource: Pointer; removed: Boolean);
begin
  if (GDVars.elementMask and $02) <> 0 then Inc(GDVars.currentSaveRoll, 2)
  else if ((GDVars.elementMask and $01) <> 0) and (not GDVars.currentSaveResult) then
    GDVars.currentDamage := GDVars.currentDamage * 2
end;

procedure EffFireShieldCold(var character: Pointer; resource: Pointer; removed: Boolean);
begin
  if (GDVars.elementMask and $01) <> 0 then Inc(GDVars.currentSaveRoll, 2)
  else if ((GDVars.elementMask and $02) <> 0) and (GDVars.recentlySaved = 0) then
    GDVars.currentDamage := GDVars.currentDamage * 2
end;

procedure EffPoisoned(var character: Pointer; resource: Pointer; removed: Boolean);
begin end;

procedure EffNoneC(var character: Pointer; resource: Pointer; removed: Boolean);
begin end;

procedure EffDancing(var character: Pointer; resource: Pointer; removed: Boolean);
begin
  Dec(Types.PCharacter(character)^.armorClass, 4);
  Dec(Types.PCharacter(character)^.rearArmorClass, 4)
end;

procedure EffMindBlank(var character: Pointer; resource: Pointer; removed: Boolean);
begin
  EffHndlr.NullifyAttack(C_Effect.CHARM);
  EffHndlr.NullifyAttack(C_Effect.CONFUSED);
  EffHndlr.NullifyAttack(C_Effect.HELD);
  EffHndlr.NullifyAttack(C_Effect.FEEBLEMINDED);
  EffHndlr.NullifyAttack(C_Effect.FEAR)
end;

procedure EffMajorGlobe(var character: Pointer; resource: Pointer; removed: Boolean);
begin
  if (GDVars.currentSpellIndex > 0) and
      (GDConsts.spellTable[GDVars.currentSpellIndex].level < 5) then EffHndlr.NullifyAttack(0)
end;

procedure EffIronSkin(var character: Pointer; resource: Pointer; removed: Boolean);
begin
  Inc(Types.PCharacter(character)^.armorClass, 4);
  Inc(Types.PCharacter(character)^.rearArmorClass, 4)
end;

procedure EffConRegeneration(var character: Pointer; resource: Pointer; removed: Boolean);
begin
  if EffHndlr.AddEffectIfNoLock(character, C_Effect.CONSTITUTION_REGENERATION, Types.PEffect(resource)^.strength,
                                60) then
    if FxEngine.RestoreHitPoints(character, 1, True) then CharHlp.AnnounceHealStatus(character)
end;

procedure EffMinorGlobe(var character: Pointer; resource: Pointer; removed: Boolean);
begin
  if (GDVars.currentSpellIndex > 0) and
      (GDConsts.spellTable[GDVars.currentSpellIndex].level < 4) then EffHndlr.NullifyAttack(0)
end;

{ In combat, the creature's target dies of poison unless it saves (with saveModifier, plus the strength of its effect
  116, which a negative modifier waives) or is immune.
  @param(character Creature striking.)
  @param(saveModifier Bonus to the target's save.) }
procedure PoisonTarget(var character: Pointer; saveModifier: ShortInt);
var node: Pointer;
begin
  if GDVars.interfaceState = C_Ifc.IN_COMBAT then begin
    GDVars.effectTarget := Types.PCharacter(character)^.combat^.target;
    if CharHlp.HasEffect(GDVars.effectTarget, 116, node) then
      if saveModifier < 0 then saveModifier := 0
      else Inc(saveModifier, Types.PEffect(node)^.strength);
    if not FxEngine.RollSavingThrow(GDVars.effectTarget, 0, Byte(saveModifier)) and
        ((GDVars.effectTarget^.immunityFlags and $08) = 0) then begin
      CharHlp.PrintCreatureMessage(GDVars.effectTarget, GDConsts.poisonedMessage, 10, False);
      TextRend.PauseOnly;
      FxEngine.AddEffect(GDVars.effectTarget, C_Effect.POISONED, 0, 255, False);
      FxEngine.KillCreature(GDVars.effectTarget, C_Status.DEAD_STATUS, GDConsts.killedMessage)
    end
  end
end;

procedure EffPoisonAttack(var character: Pointer; resource: Pointer; removed: Boolean);
begin
  EffHndlr.PoisonTarget(character, 0)
end;

procedure EffImmuneElectricity(var character: Pointer; resource: Pointer; removed: Boolean);
begin
  if (GDVars.elementMask and $04) <> 0 then GDVars.currentDamage := 0
end;

procedure EffRequirePlusThreeWeapon(var character: Pointer; resource: Pointer; removed: Boolean);
var weapon: Types.PItem;
begin
  weapon := EffHndlr.FindDamagingWeapon(GDVars.currentCharacter);
  if ((weapon = nil) or (weapon^.plus < 3)) and
      ((GDVars.currentCharacter^.race < C_Race.MONSTER) or
       (GDVars.currentCharacter^.levelHighest < 4)) then
    GDVars.currentDamage := 0
end;

{ Drains levels from a creature, one per pass: its highest class (the one with more experience to reach its level on a
  tie) loses a level, its experience drops halfway into the level below, its hit points and class figures follow, and
  spells beyond its slots are forgotten. A creature left with no levels or hit points dies; one at no hit points
  collapses.
  @param(character Creature drained; nothing happens for nil.)
  @param(count Levels to drain.) }
procedure DrainLevels(character: Types.PCharacter; count: Byte);

  { Forgets the spells beyond the slots of each type and level, keeping a mage's moon bonus. }
  procedure ForgetExcessSpells;
  type TSlotCounts = array[1..4, -7..0] of Byte;
  var counts: TSlotCounts;
      moonBonus: Byte;
      spellId: Byte;
      index: Byte;
      castClass: ShortInt;
      level: ShortInt;
  begin
    if Types.PCharacter(character)^.spells <> nil then begin
      FillChar(counts, SizeOf(counts), 0);
      if Types.PCharacter(character)^.classLevels[C_Class.MAGE] > 0 then
        case GDVars.zone0^.ecl[Types.PCharacter(character)^.robeOrder + $4CF8] of
        1: moonBonus := 1;
        2: moonBonus := 2
        else moonBonus := 0
        end;
      for index := 0 to 73 do begin
        with Types.PCharacter(character)^.spells^ do
          if (memorized[index] > 0) and (memorized[index] < $80) then begin
            spellId := memorized[index] and $7F;
            castClass := GDConsts.spellTable[spellId].castClass;
            level := GDConsts.spellTable[spellId].level;
            if counts[castClass, level] >= slots[castClass, level] then begin
              if (slots[castClass, level] = 0) or (moonBonus = 0) or (castClass <> 3) then memorized[index] := 0
              else Dec(moonBonus)
            end else Inc(counts[castClass, level])
          end
      end;
      for index := 0 to 73 do begin
        with Types.PCharacter(character)^.spells^ do
          if memorized[index] > $7F then begin
            spellId := memorized[index] and $7F;
            castClass := GDConsts.spellTable[spellId].castClass;
            level := GDConsts.spellTable[spellId].level;
            if counts[castClass, level] >= slots[castClass, level] then
              memorized[index] := 0
            else Inc(counts[castClass, level])
          end
      end
    end
  end;
var
  bestClass: ShortInt;
  currentClass: ShortInt;
  candidate: ShortInt;
  bestLevel: ShortInt;
  index: ShortInt;
  bestIndex: ShortInt;
  upper: LongInt;
  lower: LongInt;
  reducedLevel: Byte;
  pass: Byte;
  activeCount: Byte;
  anyLevels: Boolean;
begin
  if character <> nil then begin
    CharHlp.PrintCreatureMessage(character, GDConsts.drainedText, 10, False);
    TextRend.PauseOnly;
    for pass := 1 to count do begin
      activeCount := 0;
      bestLevel := 0;
      for index := 0 to 7 do begin
        candidate := Types.PCharacter(character)^.classLevels[index];
        if (candidate > 0) or (Types.PCharacter(character)^.oldLevels[index] > 0) then
          Inc(activeCount);
        if candidate > bestLevel then begin
          bestLevel := candidate;
          bestIndex := index
        end else if (candidate = bestLevel) and (bestLevel <> 0) then begin
          bestClass := CharHlp.ClassSuborderIndex(character, Byte(bestIndex));
          currentClass := CharHlp.ClassSuborderIndex(character, Byte(index));
          if GDConsts.classProgression[currentClass].experience[candidate] >
              GDConsts.classProgression[bestClass].experience[bestLevel] then begin
            bestLevel := candidate;
            bestIndex := index
          end
        end
      end;
      if Types.PCharacter(character)^.oldLevels[bestIndex] <=
          Types.PCharacter(character)^.classLevels[bestIndex] then
        Types.PCharacter(character)^.oldLevels[bestIndex] := Types.PCharacter(character)^.classLevels[bestIndex];
      if Types.PCharacter(character)^.oldExperience <= Types.PCharacter(character)^.experience then
        Types.PCharacter(character)^.oldExperience := Types.PCharacter(character)^.experience;
      bestClass := CharHlp.ClassSuborderIndex(character, Byte(bestIndex));
      if Types.PCharacter(character)^.oldMaxHitPoints <= Types.PCharacter(character)^.maxHitPoints then
        Types.PCharacter(character)^.oldMaxHitPoints := Types.PCharacter(character)^.maxHitPoints;
      case bestLevel of
      1: begin lower := 0; upper := 0 end;
      2: begin
        lower := 0;
        upper := GDConsts.classProgression[bestClass].experience[bestLevel]
      end else begin
        lower := GDConsts.classProgression[bestClass].experience[Pred(bestLevel)];
        upper := GDConsts.classProgression[bestClass].experience[bestLevel]
      end
      end;
      Types.PCharacter(character)^.experience := lower + (upper - lower) div 2;
      reducedLevel := Types.PCharacter(character)^.classLevels[bestIndex];
      Dec(reducedLevel);
      Types.PCharacter(character)^.classLevels[bestIndex] := reducedLevel;
      ViewChar.AdjustLevelHitPoints(character, GDConsts.trainingClassBits[bestIndex], activeCount, False);
      ClassCal.RecalcClassStats(character);
      ForgetExcessSpells
    end;
    anyLevels := False;
    for index := 0 to 7 do
      if Types.PCharacter(character)^.classLevels[index] > 0 then
        anyLevels := True;
    if not anyLevels or (Types.PCharacter(character)^.maxHitPoints <= 0) then
      FxEngine.KillCreature(character, C_Status.GONE, GDConsts.drainDeathText)
    else if Types.PCharacter(character)^.hitPoints <= 0 then
      FxEngine.KillCreature(character, C_Status.UNCONSCIOUS, GDConsts.drainCollapseText)
  end
end;

procedure EffDrainOne(var character: Pointer; resource: Pointer; removed: Boolean);
begin
  EffHndlr.DrainLevels(Types.PCharacter(character)^.combat^.target, 1)
end;

procedure EffDrainTwo(var character: Pointer; resource: Pointer; removed: Boolean);
begin
  EffHndlr.DrainLevels(Types.PCharacter(character)^.combat^.target, 2)
end;

procedure EffParalyzingHit(var character: Pointer; resource: Pointer; removed: Boolean);
begin
  EffHndlr.ParalyzeTarget(Types.PCharacter(character), 100, 0)
end;

procedure EffImmolate(var character: Pointer; resource: Pointer; removed: Boolean);
var target: Pointer;
    { Unused in this version; see the other implementations of this routine. }
    nearbyTargets: array[0..3] of Byte;
begin
  GDVars.targetX := Byte(CbtMap.CombatCellX(character));
  GDVars.targetY := Byte(CbtMap.CombatCellY(character));
  CharHlp.ScatterCombatIcon(1, 24, GDConsts.fireballSound);
  Pathing.BuildTargetList(GDVars.targetX, GDVars.targetY, 1, GDConsts.anyDirection, CbtMap.GetIconSize(character),
                          GDVars.arena);
  for GDVars.loopIndex := 2 to GDVars.targetCount do begin
    target := GDVars.creatures[GDVars.targetList[GDVars.loopIndex].characterIndex];
    GDVars.elementMask := $01;
    FxEngine.InflictNonWeaponDamage(target, FxEngine.RollDamageDice(1, 6), 0, False)
  end
end;

procedure EffReflectSpell(var character: Pointer; resource: Pointer; removed: Boolean);
var index: Byte;
begin
  if ((FxEngine.RollDice(1, 10) = 1) and (GDConsts.spellTable[GDVars.currentSpellIndex].targeting < 8)) or
      (GDConsts.spellTable[GDVars.currentSpellIndex].targeting > 14) then begin
    CharHlp.PrintCreatureMessage(character, GDConsts.reflectsSpellText, 10, False);
    GDVars.targetX := Byte(CbtMap.CombatCellX(GDVars.currentCharacter));
    GDVars.targetY := Byte(CbtMap.CombatCellY(GDVars.currentCharacter));
    for index := 1 to GDVars.spellTargetState.count do
      if GDVars.spellTargetState.targets[index] = character
          then GDVars.spellTargetState.targets[index] := GDVars.currentCharacter;
    CharHlp.BuildIconFacings(18);
    CharHlp.CombatAnimateMovingIcon(ShortInt(Byte(CbtMap.CombatCellX(character))),
                                    ShortInt(Byte(CbtMap.CombatCellY(character))),
                                    ShortInt(Byte(CbtMap.CombatCellX(GDVars.spellTargetState.targets[1]))),
                                    ShortInt(Byte(CbtMap.CombatCellY(GDVars.spellTargetState.targets[1]))), 1, 30);
    character := GDVars.currentCharacter
  end
end;

procedure EffDragonFear(var character: Pointer; resource: Pointer; removed: Boolean);
var
  target: Pointer;
  node: Pointer;
begin
  Pathing.BuildTargetList(Byte(CbtMap.CombatCellX(character)), Byte(CbtMap.CombatCellY(character)), 1,
                          GDConsts.anyDirection, CbtMap.GetIconSize(character), GDVars.arena);
  for GDVars.loopIndex := 2 to GDVars.targetCount do begin
    target := GDVars.creatures[GDVars.targetList[GDVars.loopIndex].characterIndex];
    if (Types.PCharacter(target)^.side <> Types.PCharacter(character)^.side) and not CharHlp.HasEffect(target,
        C_Effect.IMMUNE_FEAR, node) and
        not FxEngine.RollSavingThrow(target, 4, 0) then begin
      FxEngine.AddEffectWithMessage(target, C_Effect.FEAR, 0, 0, 1, 1, 0, GDConsts.terrifiedText);
      if CharHlp.HasEffect(target, C_Effect.FEAR, node) then begin
        Types.PCharacter(target)^.quickFight := 1;
        if Types.PCharacter(target)^.npc <= $7F then
          Types.PCharacter(target)^.npc := C_Npc.ANIMATED_PLAYER;
        Types.PCharacter(target)^.combat^.target := nil;
        Types.PCharacter(target)^.combat^.panicked := 1
      end
    end
  end
end;

procedure EffImmuneBreath(var character: Pointer; resource: Pointer; removed: Boolean);
begin
  if (GDVars.elementMask and $20) > 0 then begin
    EffHndlr.NullifyAttack(0);
    CharHlp.PrintCreatureMessage(character, GDConsts.unaffectedMessage, 10, True)
  end
end;

procedure EffFireTouch(var character: Pointer; resource: Pointer; removed: Boolean);
var target: Pointer;
begin
  if GDVars.interfaceState = C_Ifc.IN_COMBAT then begin
    target := Types.PCharacter(character)^.combat^.target;
    if target <> nil then begin
      GDVars.elementMask := 0;
      FxEngine.InflictNonWeaponDamage(target, FxEngine.RollDamageDice(2, 6), 2, FxEngine.RollSavingThrow(target, 4, 0))
    end
  end
end;

procedure EffColdVulnerable(var character: Pointer; resource: Pointer; removed: Boolean);
begin
  if (GDVars.elementMask and $02) <> 0 then GDVars.currentDamage := GDVars.currentDamage * 2
end;

procedure EffHealedByFire(var character: Pointer; resource: Pointer; removed: Boolean);
begin
  if (GDVars.elementMask and $01) <> 0 then begin
    if (GDVars.elementMask and $08) <> 0 then begin
      CharHlp.PrintCreatureMessage(character, GDConsts.healedMessage, 10, True);
      Inc(Types.PCharacter(character)^.hitPoints, GDVars.currentDamage);
      if Types.PCharacter(character)^.hitPoints > Types.PCharacter(character)^.maxHitPoints then
        Types.PCharacter(character)^.hitPoints := Types.PCharacter(character)^.maxHitPoints
    end;
    EffHndlr.NullifyAttack(0)
  end
end;

procedure EffBerserk(var character: Pointer; resource: Pointer; removed: Boolean);
begin
  if not removed then begin
    Types.PCharacter(character)^.quickFight := 1;
    if (Types.PCharacter(character)^.npc <= $7F) or
        (Types.PCharacter(character)^.npc = C_Npc.ANIMATED_PLAYER) then
      Types.PCharacter(character)^.npc := C_Npc.ANIMATED_PLAYER
    else Types.PCharacter(character)^.npc := EffHndlr.NPC_ANIMATED_NPC;
    if GDVars.interfaceState = C_Ifc.IN_COMBAT then begin
      Types.PCharacter(character)^.combat^.target := nil;
      Pathing.BuildTargetList(Byte(CbtMap.CombatCellX(character)), Byte(CbtMap.CombatCellY(character)), 255,
                              GDConsts.anyDirection, CbtMap.GetIconSize(character), GDVars.arena);
      Types.PCharacter(character)^.combat^.target := GDVars.creatures[GDVars.targetList[2].characterIndex];
      Types.PCharacter(character)^.combat^.canCast := 0;
      Types.PCharacter(character)^.side :=
        Types.PCharacter(Types.PCharacter(character)^.combat^.target)^.side xor 1;
      CharHlp.PrintCreatureMessage(character, GDConsts.berserkText, 10, True)
    end
  end else begin
    if Types.PCharacter(character)^.npc = C_Npc.ANIMATED_PLAYER then begin
      Types.PCharacter(character)^.npc := 0;
      Types.PCharacter(character)^.quickFight := 0
    end;
    Types.PCharacter(character)^.side := C_Side.PLAYER
  end
end;

procedure EffEvilStench(var character: Pointer; resource: Pointer; removed: Boolean);
var
  target: Pointer;
  node: Pointer;
begin
  CharHlp.PrintCreatureMessage(character, GDConsts.evilStenchText, 10, False);
  Pathing.BuildTargetList(Byte(CbtMap.CombatCellX(character)), Byte(CbtMap.CombatCellY(character)), 1,
                          GDConsts.anyDirection, CbtMap.GetIconSize(character), GDVars.arena);
  for GDVars.loopIndex := 2 to GDVars.targetCount do begin
    target := GDVars.creatures[GDVars.targetList[GDVars.loopIndex].characterIndex];
    if (Types.PCharacter(target)^.side <> Types.PCharacter(character)^.side) and
        not FxEngine.RollSavingThrow(target, 4, 0) and
        not CharHlp.HasEffect(target, C_Effect.EVIL_STENCH_PENALTY, node) then begin
      CharHlp.PrintNameStringAnim(target, True, GDConsts.affectedText);
      FxEngine.AddEffect(character, C_Effect.EVIL_STENCH_PENALTY, 0, 255, False)
    end
  end
end;

procedure EffImmuneConfusion(var character: Pointer; resource: Pointer; removed: Boolean);
begin
  EffHndlr.NullifyAttack(C_Effect.CONFUSED)
end;

procedure EffResistColdAndElectricity(var character: Pointer; resource: Pointer; removed: Boolean);
begin
  if ((GDVars.elementMask and $04) <> 0) or ((GDVars.elementMask and $02) <> 0) then
    GDVars.currentDamage := GDVars.currentDamage div 2
end;

procedure EffRegenerateThree(var character: Pointer; resource: Pointer; removed: Boolean);
begin
  if Types.PCharacter(character)^.hitPoints < Types.PCharacter(character)^.maxHitPoints then begin
    Inc(Types.PCharacter(character)^.hitPoints, 3);
    if Types.PCharacter(character)^.hitPoints > Types.PCharacter(character)^.maxHitPoints then
      Types.PCharacter(character)^.hitPoints := Types.PCharacter(character)^.maxHitPoints
  end
end;

procedure EffStrongPoisonAttack(var character: Pointer; resource: Pointer; removed: Boolean);
begin
  EffHndlr.PoisonTarget(character, ShortInt(254))
end;

procedure EffIronGolem(var character: Pointer; resource: Pointer; removed: Boolean);
begin
  if ((GDVars.elementMask and $01) <> 0) and ((GDVars.elementMask and $08) <> 0) then begin
    CharHlp.PrintCreatureMessage(character, GDConsts.healedMessage, 10, True);
    Inc(Types.PCharacter(character)^.hitPoints, GDVars.currentDamage);
    if Types.PCharacter(character)^.hitPoints > Types.PCharacter(character)^.maxHitPoints then
      Types.PCharacter(character)^.hitPoints := Types.PCharacter(character)^.maxHitPoints;
    EffHndlr.NullifyAttack(0)
  end else if (GDVars.elementMask and $04) <> 0 then begin
    FxEngine.AddEffect(character, C_Effect.SLOWED, 3, 255, False);
    CharHlp.PrintCreatureMessage(character, GDConsts.isText + GDConsts.effectNames[C_Effect.SLOWED], 10, True);
    EffHndlr.NullifyAttack(0)
  end else EffHndlr.NullifyAttack(0)
end;

procedure EffGhoulPara(var character: Pointer; resource: Pointer; removed: Boolean);
begin
  if Types.PCharacter(Types.PCharacter(character)^.combat^.target)^.race > C_Race.QUALINESTI_ELF
  then EffHndlr.ParalyzeTarget(Types.PCharacter(character), 100, 0)
end;

procedure EffDisplaced(var character: Pointer; resource: Pointer; removed: Boolean);
begin
  if (GDVars.roundNumber = 0) and (GDVars.currentAttackRoll = 0) then
    Types.PEffect(resource)^.strength := Types.PEffect(resource)^.strength and $0F
  else if (Types.PEffect(resource)^.strength and $10) = 0 then begin
    GDVars.currentAttackRoll := -1;
    Types.PEffect(resource)^.strength := Types.PEffect(resource)^.strength or $10
  end
end;

procedure EffWantsToKill(var character: Pointer; resource: Pointer; removed: Boolean);
begin
end;

procedure EffImmuneFear(var character: Pointer; resource: Pointer; removed: Boolean);
begin
  EffHndlr.NullifyAttack(C_Effect.FEAR)
end;

procedure EffHalfDamageFromWeaponClass(var character: Pointer; resource: Pointer; removed: Boolean);
var weapon: Types.PItem;
begin
  weapon := EffHndlr.FindDamagingWeapon(GDVars.currentCharacter);
  if (weapon <> nil) and (Byte(GDVars.baseItems[weapon^.itemType].wpnClass <= 1) <> 0) then
    GDVars.currentDamage := GDVars.currentDamage div 2
end;

procedure EffConSpellSave(var character: Pointer; resource: Pointer; removed: Boolean);
var bonus: Byte;
begin
  if (GDVars.currentSaveType = 4) or (GDVars.currentSaveType = 2) or (GDVars.currentSaveType = 0) then begin
    case Types.PCharacter(character)^.stats[C_Stat.CONSTITUTION].current of
      4..6: bonus := 1;
      7..10: bonus := 2;
      11..13: bonus := 3;
      14..17: bonus := 4;
      18..20: bonus := 5
    end;
    GDVars.currentSaveRoll := GDVars.currentSaveRoll + bonus
  end
end;

procedure EffElfResistance(var character: Pointer; resource: Pointer; removed: Boolean);
begin
  if FxEngine.RollDice(1, 100) <= 90 then begin
    EffHndlr.NullifyAttack(C_Effect.SLEEP);
    EffHndlr.NullifyAttack(C_Effect.CHARM)
  end
end;

procedure EffImmuneSleepCharm(var character: Pointer; resource: Pointer; removed: Boolean);
begin
  EffHndlr.NullifyAttack(C_Effect.CHARM);
  EffHndlr.NullifyAttack(C_Effect.SLEEP)
end;

procedure EffImmuneParalysis(var character: Pointer; resource: Pointer; removed: Boolean);
begin
  EffHndlr.NullifyAttack(C_Effect.HELD)
end;

procedure EffImmuneCold(var character: Pointer; resource: Pointer; removed: Boolean);
begin
  if (GDVars.elementMask and $02) <> 0 then EffHndlr.NullifyAttack(0)
end;

procedure EffImmuneParalysisPoison(var character: Pointer; resource: Pointer; removed: Boolean);
begin
  EffHndlr.NullifyAttack(C_Effect.POISONED);
  EffHndlr.NullifyAttack(C_Effect.HELD);
  if GDVars.currentSaveType = 0 then GDVars.currentSaveRoll := 100
end;

procedure EffShockHealsFireSlows(var character: Pointer; resource: Pointer; removed: Boolean);
begin
  if ((GDVars.elementMask and $04) <> 0) and ((GDVars.elementMask and $08) <> 0) then begin
    CharHlp.PrintCreatureMessage(character, GDConsts.healedMessage, 10, True);
    Inc(Types.PCharacter(character)^.hitPoints, GDVars.currentDiceCount);
    if Types.PCharacter(character)^.hitPoints > Types.PCharacter(character)^.maxHitPoints then
      Types.PCharacter(character)^.hitPoints := Types.PCharacter(character)^.maxHitPoints;
    EffHndlr.NullifyAttack(0)
  end else if (((GDVars.elementMask and $01) <> 0) or ((GDVars.elementMask and $02) <> 0)) and
      ((GDVars.elementMask and $08) <> 0) then begin
    FxEngine.AddEffect(character, C_Effect.SLOWED, FxEngine.RollDice(2, 6), 255, False);
    CharHlp.PrintCreatureMessage(character, GDConsts.isText + GDConsts.effectNames[C_Effect.SLOWED], 10, True);
    EffHndlr.NullifyAttack(0)
  end else EffHndlr.NullifyAttack(0)
end;

procedure EffWeaponResistance(var character: Pointer; resource: Pointer; removed: Boolean);
var weapon: Types.PItem;
begin
  weapon := EffHndlr.FindDamagingWeapon(GDVars.currentCharacter);
  if ((weapon = nil) or (weapon^.plus = 0)) and
      ((GDVars.currentCharacter^.race < C_Race.MONSTER) or
       (GDVars.currentCharacter^.levelHighest < 4)) then
    GDVars.currentDamage := 0
end;

procedure EffRangerDamageBonus(var character: Pointer; resource: Pointer; removed: Boolean);
begin
  if GDVars.interfaceState = C_Ifc.IN_COMBAT then begin
    GDVars.effectTarget := Types.PCharacter(character)^.combat^.target;
    if (GDVars.effectTarget^.typeFlags and $08) <> 0 then
      Inc(GDVars.currentDamage, Types.PCharacter(character)^.classLevels[C_Class.RANGER])
  end
end;

procedure EffSmokeBlinds(var character: Pointer; resource: Pointer; removed: Boolean);
var
  score: Integer;
  bestScore: Integer;
  index: Byte;
  best: Pointer;
  target: Pointer;
  node: Pointer;
begin
  bestScore := 0;
  best := nil;
  Pathing.BuildTargetList(Byte(CbtMap.CombatCellX(character)), Byte(CbtMap.CombatCellY(character)), 1,
                          GDConsts.anyDirection, CbtMap.GetIconSize(character), GDVars.arena);
  for index := 2 to GDVars.targetCount do begin
    score := 0;
    target := GDVars.creatures[GDVars.targetList[index].characterIndex];
    with Types.PCharacter(target)^ do
      if (side <> Types.PCharacter(character)^.side) and
          not CharHlp.HasEffect(target, C_Effect.BLINDED_BY_SMOKE, node) then begin
        score := thac0Adjusted + attacksLeft[1] * (6 * currentRolls[1] + currentModifiers[1]);
        if score > bestScore then begin
          bestScore := score;
          best := target
        end
      end
  end;
  if best <> nil then
    FxEngine.AddEffectWithMessage(best, C_Effect.BLINDED_BY_SMOKE, 0, 0, 1, 1,
                                  Byte(FxEngine.RollSavingThrow(best, 3, 0)), GDConsts.blindedBySmokeText)
end;

procedure EffConfusedBerserk(var character: Pointer; resource: Pointer; removed: Boolean);
begin
  if (not removed) and (GDVars.interfaceState = C_Ifc.IN_COMBAT) then begin
    Types.PCharacter(character)^.quickFight := 1;
    if (Types.PCharacter(character)^.npc <= $7F) or
        (Types.PCharacter(character)^.npc = C_Npc.ANIMATED_PLAYER) then
      Types.PCharacter(character)^.npc := C_Npc.ANIMATED_PLAYER
    else Types.PCharacter(character)^.npc := EffHndlr.NPC_ANIMATED_NPC;
    Types.PCharacter(character)^.combat^.target := nil;
    Pathing.BuildTargetList(Byte(CbtMap.CombatCellX(character)), Byte(CbtMap.CombatCellY(character)), 255,
                            GDConsts.anyDirection, CbtMap.GetIconSize(character), GDVars.arena);
    Types.PCharacter(character)^.combat^.target := GDVars.creatures[GDVars.targetList[2].characterIndex];
    Types.PCharacter(character)^.side :=
      Types.PCharacter(Types.PCharacter(character)^.combat^.target)^.side xor 1
  end else begin
    if Types.PCharacter(character)^.npc = C_Npc.ANIMATED_PLAYER then
      Types.PCharacter(character)^.npc := 0;
    Types.PCharacter(character)^.side := Types.PEffect(resource)^.strength
  end
end;

procedure EffBlindedBySmoke(var character: Pointer; resource: Pointer; removed: Boolean);
begin
  Dec(GDVars.currentDamage, 2);
  Dec(GDVars.currentAttackRoll, 2)
end;

procedure EffLayOnHandsUsed(var character: Pointer; resource: Pointer; removed: Boolean);
begin
end;

procedure EffPaladinCureReset(var character: Pointer; resource: Pointer; removed: Boolean);
begin
  if removed then begin
    Types.PCharacter(character)^.cureAbility :=
      TLevel(Types.PCharacter(character)^.classLevels[C_Class.PALADIN]) div 5 + 1
  end
end;

procedure EffFear(var character: Pointer; resource: Pointer; removed: Boolean);
begin
  if removed then begin
    if Types.PCharacter(character)^.npc = C_Npc.ANIMATED_PLAYER then begin
      Types.PCharacter(character)^.npc := 0;
      Types.PCharacter(character)^.quickFight := 0
    end;
    Types.PCharacter(character)^.combat^.panicked := 0
  end
end;

procedure EffZapAttacker(var character: Pointer; resource: Pointer; removed: Boolean);
var
  savedState: Byte;
  savedFlags: Byte;
begin
  if CharHlp.CalcDistance(GDVars.currentCharacter, character) < 2 then begin
    savedState := GDVars.currentDamage;
    GDVars.currentDamage := GDVars.currentDamage * 2;
    savedFlags := GDVars.elementMask;
    GDVars.elementMask := $08;
    CharHlp.PrintCreatureMessage(GDVars.currentCharacter, GDConsts.zappedText, 10, True);
    FxEngine.InflictNonWeaponDamage(GDVars.currentCharacter, GDVars.currentDamage, 0, False);
    GDVars.currentDamage := savedState;
    GDVars.elementMask := savedFlags
  end
end;

procedure EffFrostGiantStrength(var character: Pointer; resource: Pointer; removed: Boolean);
begin
end;

procedure EffDamageEqualsHitPoints(var character: Pointer; resource: Pointer; removed: Boolean);
var target: Pointer;
begin
  if GDVars.interfaceState = C_Ifc.IN_COMBAT then begin
    target := Types.PCharacter(character)^.combat^.target;
    if (Types.PCharacter(target)^.immunityFlags and $01) <> 0 then
      GDVars.currentDamage := Types.PCharacter(character)^.hitPoints
  end
end;

procedure EffTypeDamageBonus(var character: Pointer; resource: Pointer; removed: Boolean);
var target: Pointer;
begin
  if GDVars.interfaceState = C_Ifc.IN_COMBAT then begin
    target := Types.PCharacter(character)^.combat^.target;
    if (Types.PCharacter(target)^.typeFlags and $20) <> 0 then Inc(GDVars.currentDamage, 3)
  end
end;

procedure EffDisruption(var character: Pointer; resource: Pointer; removed: Boolean);
var target: Pointer;
begin
  if (GDVars.interfaceState = C_Ifc.IN_COMBAT) and (not removed) then begin
    target := Types.PCharacter(character)^.combat^.target;
    if (Types.PCharacter(target)^.typeFlags and $02) <> 0 then
      GDVars.currentDamage := GDVars.currentDamage * 2
    else if Types.PCharacter(target)^.levelUndead <> 0 then
      FxEngine.KillCreature(target, C_Status.GONE, GDConsts.disruptedText)
  end
end;

procedure EffEvilStenchPenalty(var character: Pointer; resource: Pointer; removed: Boolean);
begin
  Dec(GDVars.currentAttackRoll, 2)
end;

procedure EffNone(var character: Pointer; resource: Pointer; removed: Boolean);
begin
end;

procedure EffGrantItemEffect(var character: Pointer; resource: Pointer; removed: Boolean);
var item: Types.PItem;
begin
  GDVars.handlerOverrideActive := 0;
  item := resource;
  if removed then
    FxEngine.RemoveEffect(character, item^.effect, nil)
  else
    FxEngine.AddEffect(character, item^.effect, 0, 255, True)
end;

procedure InitEffectHandlers;
begin
  @GDVars.effectServices.handlers[C_Effect.BLESS] := @EffHndlr.EffBless;
  @GDVars.effectServices.handlers[C_Effect.STUN_ON_HIT] := @EffHndlr.EffStunOnHit;
  @GDVars.effectServices.handlers[C_Effect.SNAKES] := @EffHndlr.EffSticksToSnakes;
  @GDVars.effectServices.handlers[C_Effect.DISPELLING_EVIL] := @EffHndlr.EffDispelEvil;
  @GDVars.effectServices.handlers[C_Effect.DETECT_MAGIC] := @EffHndlr.EffNone;
  @GDVars.effectServices.handlers[C_Effect.ENTANGLED] := @EffHndlr.EffEndActions;
  @GDVars.effectServices.handlers[C_Effect.FIXED_DICE_ATTACK] := @EffHndlr.EffSetAttackDamage;
  @GDVars.effectServices.handlers[C_Effect.PROTECTION_FROM_EVIL] := @EffHndlr.EffProtEvil;
  @GDVars.effectServices.handlers[C_Effect.MAGIC_BOOTS] := @EffHndlr.EffMagicalBoots;
  @GDVars.effectServices.handlers[C_Effect.RESIST_COLD] := @EffHndlr.EffResistCold;
  @GDVars.effectServices.handlers[C_Effect.CHARM] := @EffHndlr.EffCharm;
  @GDVars.effectServices.handlers[C_Effect.ENLARGE] := @EffHndlr.EffNone;
  @GDVars.effectServices.handlers[C_Effect.HIGHLIGHTED] := @EffHndlr.EffMagicallyHighlighted;
  @GDVars.effectServices.handlers[C_Effect.FRIENDS] := @EffHndlr.EffNone;
  @GDVars.effectServices.handlers[C_Effect.SLOW_POISON_HIT] := @EffHndlr.EffSlowPoisonHit;
  @GDVars.effectServices.handlers[C_Effect.READ_MAGIC] := @EffHndlr.EffNone;
  @GDVars.effectServices.handlers[C_Effect.SHIELD] := @EffHndlr.EffShield;
  @GDVars.effectServices.handlers[C_Effect.HALF_ELF_RESISTANCE] := @EffHndlr.EffHalfElfResistance;
  @GDVars.effectServices.handlers[19] := @EffHndlr.EffNone;
  @GDVars.effectServices.handlers[C_Effect.RESIST_FIRE] := @EffHndlr.EffResistFire;
  @GDVars.effectServices.handlers[C_Effect.SILENCE] := @EffHndlr.EffSilence;
  @GDVars.effectServices.handlers[C_Effect.SLOW_POISON_END] := @EffHndlr.EffSlowPoisonEnd;
  @GDVars.effectServices.handlers[C_Effect.SPIRITUAL_HAMMER] := @EffHndlr.EffSpiritualHammer;
  @GDVars.effectServices.handlers[EffHndlr.SEE_INVISIBLE] := @EffHndlr.EffNone;
  @GDVars.effectServices.handlers[C_Effect.INVISIBLE] := @EffHndlr.EffInvisible;
  @GDVars.effectServices.handlers[C_Effect.DWARF_THAC0] := @EffHndlr.EffDwarfHitBonus;
  @GDVars.effectServices.handlers[C_Effect.BEFUDDLED] := @EffHndlr.EffEndActions;
  @GDVars.effectServices.handlers[C_Effect.MIRROR_IMAGE] := @EffHndlr.EffMirrorImage;
  @GDVars.effectServices.handlers[C_Effect.ENFEEBLE] := @EffHndlr.EffWeakened;
  @GDVars.effectServices.handlers[C_Effect.STINKING_COUGH] := @EffHndlr.EffCoughing;
  @GDVars.effectServices.handlers[C_Effect.HELPLESS] := @EffHndlr.EffHelpless;
  @GDVars.effectServices.handlers[C_Effect.INVISIBLE_BY_FLAG] := @EffHndlr.EffInvisibleByFlag;
  @GDVars.effectServices.handlers[C_Effect.BLIND] := @EffHndlr.EffBlind;
  @GDVars.effectServices.handlers[C_Effect.DISPEL_EVIL] := @EffHndlr.EffDispelEvilTouch;
  @GDVars.effectServices.handlers[C_Effect.CONFUSED] := @EffHndlr.EffConfusion;
  @GDVars.effectServices.handlers[C_Effect.CURSED] := @EffHndlr.EffCursed;
  @GDVars.effectServices.handlers[C_Effect.BLINKING] := @EffHndlr.EffBlinking;
  @GDVars.effectServices.handlers[C_Effect.STRENGTH] := @EffHndlr.EffNone;
  @GDVars.effectServices.handlers[C_Effect.HASTED] := @EffHndlr.EffHasted;
  @GDVars.effectServices.handlers[40] := @EffHndlr.EffNoneB;
  @GDVars.effectServices.handlers[C_Effect.PROTECTION_FROM_MISSILES] := @EffHndlr.EffProtNormalMissiles;
  @GDVars.effectServices.handlers[C_Effect.SLOWED] := @EffHndlr.EffSlowed;
  @GDVars.effectServices.handlers[43] := @EffHndlr.EffNone;
  @GDVars.effectServices.handlers[44] := @EffHndlr.EffNone;
  @GDVars.effectServices.handlers[C_Effect.PROTECTION_FROM_EVIL_RADIUS] := @EffHndlr.EffProtEvil;
  @GDVars.effectServices.handlers[46] := @EffHndlr.EffNone;
  @GDVars.effectServices.handlers[C_Effect.DWARF_ARMOR_CLASS_VS_GIANTS] := @EffHndlr.EffDwarfDefenseBonus;
  @GDVars.effectServices.handlers[C_Effect.BARKSKIN] := @EffHndlr.EffBarkskin;
  @GDVars.effectServices.handlers[C_Effect.PRAYER] := @EffHndlr.EffPrayer;
  @GDVars.effectServices.handlers[C_Effect.FIRE_SHIELD_HOT] := @EffHndlr.EffFireShieldHot;
  @GDVars.effectServices.handlers[51] := @EffHndlr.EffNone;
  @GDVars.effectServices.handlers[C_Effect.HELD] := @EffHndlr.EffHelpless;
  @GDVars.effectServices.handlers[C_Effect.SLEEP] := @EffHndlr.EffHelpless;
  @GDVars.effectServices.handlers[C_Effect.FIRE_SHIELD_COLD] := @EffHndlr.EffFireShieldCold;
  @GDVars.effectServices.handlers[C_Effect.POISONED] := @EffHndlr.EffPoisoned;
  @GDVars.effectServices.handlers[56] := @EffHndlr.EffNoneC;
  @GDVars.effectServices.handlers[C_Effect.DANCING] := @EffHndlr.EffDancing;
  @GDVars.effectServices.handlers[58] := @EffHndlr.EffMindBlank;
  @GDVars.effectServices.handlers[C_Effect.MAJOR_GLOBE] := @EffHndlr.EffMajorGlobe;
  @GDVars.effectServices.handlers[C_Effect.IRON_SKIN] := @EffHndlr.EffIronSkin;
  @GDVars.effectServices.handlers[C_Effect.FEEBLEMINDED] := @EffHndlr.EffNone;
  @GDVars.effectServices.handlers[C_Effect.CONSTITUTION_REGENERATION] := @EffHndlr.EffConRegeneration;
  @GDVars.effectServices.handlers[C_Effect.MINOR_GLOBE] := @EffHndlr.EffMinorGlobe;
  @GDVars.effectServices.handlers[C_Effect.POISON_ATTACK] := @EffHndlr.EffPoisonAttack;
  @GDVars.effectServices.handlers[C_Effect.IMMUNE_ELECTRICITY] := @EffHndlr.EffImmuneElectricity;
  @GDVars.effectServices.handlers[C_Effect.NEEDS_PLUS_THREE_WEAPON] := @EffHndlr.EffRequirePlusThreeWeapon;
  @GDVars.effectServices.handlers[C_Effect.DRAIN_ONE] := @EffHndlr.EffDrainOne;
  @GDVars.effectServices.handlers[C_Effect.DRAIN_TWO] := @EffHndlr.EffDrainTwo;
  @GDVars.effectServices.handlers[C_Effect.PARALYZING_TOUCH] := @EffHndlr.EffParalyzingHit;
  @GDVars.effectServices.handlers[C_Effect.BURST_AROUND_SELF] := @EffHndlr.EffImmolate;
  @GDVars.effectServices.handlers[C_Effect.REFLECT_SPELL] := @EffHndlr.EffReflectSpell;
  @GDVars.effectServices.handlers[C_Effect.FRIGHTEN_ADJACENT] := @EffHndlr.EffDragonFear;
  @GDVars.effectServices.handlers[C_Effect.IMMUNE_DRAGON_BREATH] := @EffHndlr.EffImmuneBreath;
  @GDVars.effectServices.handlers[C_Effect.FIRE_TOUCH] := @EffHndlr.EffFireTouch;
  @GDVars.effectServices.handlers[C_Effect.COLD_VULNERABLE] := @EffHndlr.EffColdVulnerable;
  @GDVars.effectServices.handlers[C_Effect.HEALED_BY_FIRE] := @EffHndlr.EffHealedByFire;
  @GDVars.effectServices.handlers[C_Effect.BERSERK] := @EffHndlr.EffBerserk;
  @GDVars.effectServices.handlers[C_Effect.EVIL_STENCH] := @EffHndlr.EffEvilStench;
  @GDVars.effectServices.handlers[C_Effect.IMMUNE_CONFUSION] := @EffHndlr.EffImmuneConfusion;
  @GDVars.effectServices.handlers[82] := @EffHndlr.EffNone;
  @GDVars.effectServices.handlers[C_Effect.RESIST_COLD_ELECTRICITY] := @EffHndlr.EffResistColdAndElectricity;
  @GDVars.effectServices.handlers[C_Effect.REGENERATE_THREE] := @EffHndlr.EffRegenerateThree;
  @GDVars.effectServices.handlers[C_Effect.STRONG_POISON_ATTACK] := @EffHndlr.EffStrongPoisonAttack;
  @GDVars.effectServices.handlers[C_Effect.FIRE_HEALS_SHOCK_SLOWS] := @EffHndlr.EffIronGolem;
  @GDVars.effectServices.handlers[C_Effect.PARALYZE_NON_ELVES] := @EffHndlr.EffGhoulPara;
  @GDVars.effectServices.handlers[C_Effect.MAGIC_CLOAK] := @EffHndlr.EffDisplaced;
  @GDVars.effectServices.handlers[91] := @EffHndlr.EffWantsToKill;
  @GDVars.effectServices.handlers[C_Effect.IMMUNE_FEAR] := @EffHndlr.EffImmuneFear;
  @GDVars.effectServices.handlers[C_Effect.HALF_DAMAGE_FROM_WEAPON_CLASS] := @EffHndlr.EffHalfDamageFromWeaponClass;
  @GDVars.effectServices.handlers[C_Effect.CONSTITUTION_SAVE_BONUS] := @EffHndlr.EffConSpellSave;
  @GDVars.effectServices.handlers[C_Effect.ELF_RESISTANCE] := @EffHndlr.EffElfResistance;
  @GDVars.effectServices.handlers[C_Effect.IMMUNE_CHARM_SLEEP] := @EffHndlr.EffImmuneSleepCharm;
  @GDVars.effectServices.handlers[C_Effect.IMMUNE_HOLD] := @EffHndlr.EffImmuneParalysis;
  @GDVars.effectServices.handlers[C_Effect.IMMUNE_COLD] := @EffHndlr.EffImmuneCold;
  @GDVars.effectServices.handlers[C_Effect.IMMUNE_POISON_HOLD] := @EffHndlr.EffImmuneParalysisPoison;
  @GDVars.effectServices.handlers[C_Effect.SHOCK_HEALS_FIRE_SLOWS] := @EffHndlr.EffShockHealsFireSlows;
  @GDVars.effectServices.handlers[102] := @EffHndlr.EffNone;
  @GDVars.effectServices.handlers[C_Effect.NEEDS_MAGIC_WEAPON] := @EffHndlr.EffWeaponResistance;
  @GDVars.effectServices.handlers[C_Effect.RANGER_BONUS_DAMAGE] := @EffHndlr.EffRangerDamageBonus;
  @GDVars.effectServices.handlers[C_Effect.SMOKE_BLINDS] := @EffHndlr.EffSmokeBlinds;
  @GDVars.effectServices.handlers[107] := @EffHndlr.EffConfusedBerserk;
  @GDVars.effectServices.handlers[C_Effect.BLINDED_BY_SMOKE] := @EffHndlr.EffBlindedBySmoke;
  @GDVars.effectServices.handlers[109] := @EffHndlr.EffLayOnHandsUsed;
  @GDVars.effectServices.handlers[110] := @EffHndlr.EffPaladinCureReset;
  @GDVars.effectServices.handlers[C_Effect.FEAR] := @EffHndlr.EffFear;
  @GDVars.effectServices.handlers[C_Effect.SHOCK_ATTACKER] := @EffHndlr.EffZapAttacker;
  @GDVars.effectServices.handlers[C_Effect.FROST_GIANT_STRENGTH] := @EffHndlr.EffFrostGiantStrength;
  @GDVars.effectServices.handlers[C_Effect.DAMAGE_EQUALS_HIT_POINTS] := @EffHndlr.EffDamageEqualsHitPoints;
  @GDVars.effectServices.handlers[C_Effect.BONUS_DAMAGE_VS_TYPE] := @EffHndlr.EffTypeDamageBonus;
  @GDVars.effectServices.handlers[116] := @EffHndlr.EffNone;
  @GDVars.effectServices.handlers[C_Effect.DISRUPTION] := @EffHndlr.EffDisruption;
  @GDVars.effectServices.handlers[C_Effect.EVIL_STENCH_PENALTY] := @EffHndlr.EffEvilStenchPenalty;
  @GDVars.effectServices.handlers[119] := @EffHndlr.EffNone;
  @GDVars.effectServices.handlers[120] := @EffHndlr.EffNone;
  @GDVars.effectServices.itemHandler := @EffHndlr.EffGrantItemEffect
end;
begin
end.
