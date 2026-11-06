{ Magic: the choose-a-spell menu (cast, memorize, scribe, learn, keep), the cast itself, and one handler per spell id
  installed into GDVars.spellServices.handlers[1..114] by InitSpellFns. GDConsts.spellTable's comments give each id its
  name. }
{$F+,O+,S-,R-,V-,B-,I-}
unit Magic;
interface
uses C_Class, C_Cond, C_Dir, C_Effect, C_Ifc, C_Keys, C_Npc, C_Race, C_Spell, C_Stat, C_Status, C_Terr, Crt, GDConsts,
  GDVars, FxEngine, CharHlp, TextRend, CbtMap, Pathing, MenuCore, Music, Border, ClassCal, Types;

{ Runs the spell menu over the list GenerateSpellList built and returns the chosen spell id, or 0 when the player leaves
  it. The selection type names the menu's action: 1 Cast, 2 Memorize, 3 Scribe (which also records the scroll being
  read), 4 Learn, 5 Keep; any other shows the bare list.
  @param(selectionType The menu's action.)
  @param(index The highlighted entry, kept between calls; negative asks for a full redraw.)
  @returns(The chosen spell id, or 0.) }
function SpellSelection(selectionType: Byte; var index: Integer): Byte;

{ Builds the spell list for SpellSelection under level headings (scroll lists in scroll order): 0 the memorized spells
  it can cast, 1 the known spells it can cast that are not deity gifts already memorized, 2 the current scroll's, 3
  every readable scroll's, 4 the spells a mage may learn by its robe and levels, 5 the spells still being memorized, 6
  the spells marked on scrolls.
  @param(mode The list wanted.)
  @returns(1 when the list is not empty, 0 otherwise.) }
function GenerateSpellList(mode: Byte): Byte;

{ Computes a spell's range.
  @param(spellId The spell.)
  @returns(Its base plus its per-level range times the caster level (an item casts at level 6); a spell with an area
    gets at least 1, and 255 becomes 1.) }
function CalcSpellRange(spellId: Byte): Byte;

{ Chooses the targets outside combat, as spellServices.selectTargets: the caster, a chosen character (none cancels) or
  the whole party, by the spell's camp target.
  @param(spellId The spell.)
  @param(mode Unused.)
  @param(result Set to 1, or 0 when the cast is canceled or the spell has no camp target.) }
procedure NoncombatCastTargetMenu(spellId, mode: Byte; var result: Byte);

{ Casts a spell: outside combat a spell with no camp target cannot be cast (the player may lose it, or use the item
  anyway); otherwise it is announced, its targets chosen through spellServices.selectTargets and, in combat, its missile
  and burst drawn; the caster turns visible, the memorized spell is spent and its handler runs. When aiming fails in
  combat, the player may abort the spell, which is then spent.
  @param(spellId The spell.)
  @param(noPrompt Non-zero to abort without asking, for the computer.)
  @param(announce Non-zero to announce the casting.)
  @param(cast Set when targets were chosen.) }
procedure CastSpell(spellId, noPrompt, announce: Byte; var cast: Byte);

{ Tells whether an item is readable.
  @param(item The item, or nil.)
  @returns(True for a scroll: item type 39 or 40.) }
function ItemReadable(item: Types.PItem): Boolean;

{ Removes a spell from a scroll: the scroll's spell-count name part drops by one, and the scroll goes when none are left
  (name id below 100).
  @param(owner The character carrying the scroll.)
  @param(item The scroll.)
  @param(spellId The spell to remove; bit 7 of the scroll's entries is ignored, and the last matching entry is
  cleared.) }
procedure RemoveSpellFromScroll(owner, item: Pointer; spellId: Byte);

{ Reports a cast: in combat "Casts a Spell" and the spell's name on row 23; outside combat the caster's name, the given
  text and the spell's name in the text window, then a pause.
  @param(character The caster.)
  @param(source Printed after the caster's name outside combat.)
  @param(spellId The spell cast.) }
procedure PrintCastSpellMsg(character: Types.PCharacter; source: Types.TString40; spellId: Byte);

{ Casts Remove Curse: lifts Bestow Curse from the target ("is un-cursed"), or else un-equips its first cursed item and,
  when that item's special effect is above $7F, removes that effect through the override handler and recalculates the
  target's abilities ("has an item un-cursed"). }
procedure SpellRemoveCurse;

{ Installs the spell handlers into GDVars.spellServices.handlers[1..114] and the camp target selector. }
procedure InitSpellFns;

{ Casts Bless on the caster's own side. }
procedure SpellBless;

{ Barkskin: gives the targets the barkskin effect. }
procedure SpellBarkskin;

{ Casts Cure Light Wounds: heals the target 1d8, or 2d8 when the caster's deity is 4. }
procedure SpellCureLightWounds;

{ Spell 4, Charm Person/Mammal: charms a person or mammal; other creatures are not charmed. }
procedure SpellCharmPersonOrMammal;

{ Applies a detection spell's effect to the targets. }
procedure SpellDetection;

{ Applies a protection spell's effect to the targets. }
procedure SpellProtection;

{ Resurrection: brings back a dead target that is not an elf and has constitution left, at full hit points and cured of
  poison. }
procedure SpellResurrection;

{ Applies Resist Cold's effect to the targets. }
procedure SpellResistCold;

{ Casts Burning Hands: fire damage of 1 point per caster level. }
procedure SpellBurningHands;

{ Casts Charm Person: a monster without the charmable flag, or a creature bigger than one combat cell, is unaffected.
  The charm records the caster's side. }
procedure SpellCharmPerson;

{ Spell 12, Enlarge: raises the target's strength by caster level, from 18/00 up to 22, unless it is already stronger. }
procedure SpellEnlarge;

{ Casts Reduce: removes Enlarge from the target unless it saves against spells ("has been reduced"). }
procedure SpellReduce;

{ Casts Friends: the effect with strength 2d4, then the caster's Charisma is recalculated. }
procedure SpellFriends;

{ Casts Magic Missile: (caster level + 1) div 2 missiles of 1d4 + 1 magic damage. }
procedure SpellMagicMissile;

{ Spell 17, Restoration: gives back one lost level, in the class needing the least experience for it, with a share of
  the lost hit points; experience returns to the old total when that was the only lost level. }
procedure SpellRestoration;

{ Applies Shield's effect to the targets. }
procedure SpellShield;

{ Casts Shocking Grasp: 1d8 plus the caster level in electrical damage. }
procedure SpellShockingGrasp;

{ Casts Sleep with a 4d4 hit-dice pool. Each target costs by its level: 0..1 costs 1, 2 costs 2, 3 costs 4, 4 costs 6, 5
  costs 10 for a creature of the monster race and 20 otherwise, and higher levels cost 20. Animated dead, targets
  already asleep and targets the remaining pool cannot pay for are dropped; the pool is spent greedily in target
  order. }
procedure SpellSleep;

{ Hold Person and Hold Monsters: puts the hold effect on up to four targets, with a save modifier by their number: -2 or
  -3 for one, depending on the spell, -1 for two and 0 for three or four. Note: more targets leave the modifier
  undefined. }
procedure SpellHold;

{ Applies Resist Fire's effect to the targets. }
procedure SpellResistFire;

{ Applies Silence's effect to the targets. }
procedure SpellSilence;

{ Casts Slow Poison: on a poisoned target that is not animated, raises 0 hit points to 1, sets it okay and in play,
  applies the spell and re-arms the poison damage for 10. }
procedure SpellSlowPoison;

{ Spell 27: does nothing. }
procedure SpellSnakeCharm;

{ Casts Spiritual Hammer: applies the spell's effect, then runs the Spiritual Hammer effect handler for the first
  target. }
procedure SpellSpiritualHammer;

{ Applies the Invisibility spells' effect to the targets. }
procedure SpellInvisibility;

{ Applies Knock's effect to the targets. }
procedure SpellKnock;

{ Casts Mirror Image: 1d4 images in the effect strength's high nibble, the caster level in the low one. }
procedure SpellMirrorImage;

{ Applies Ray of Enfeeblement's effect to the targets. }
procedure SpellRayOfEnfeeblement;

{ Spells 34, Stinking Cloud, and 91, Cloudkill: lays a cloud of 4 or 9 cells around the target cell, lasting a round per
  caster level, and catches the creatures in it. }
procedure SpellStinkingCloud;

{ Spell 35, Strength: raises the target's strength by d4 for a mage, d6 for a cleric or thief and d8 for a fighting
  class, into exceptional strength for the fighting classes. Note: for a character of none of those classes the bonus is
  undefined. }
procedure SpellStrength;

{ Does nothing: an unused spell slot. }
procedure SpellNoEffect;

{ Casts Cure Blindness: ends the first target's blindness ('can see'). }
procedure SpellCureBlindness;

{ Casts Cause Blindness: blinds the targets. }
procedure SpellCauseBlindness;

{ Spell 39, Cure Disease: does nothing, there being no disease to cure. }
procedure SpellCureDisease;

{ Spell 40, Harm: leaves the target d4 hit points or fewer. }
procedure SpellHarm;

{ Spells 41 and 46, Dispel Magic: each effect of the target with a strength below 255 ends on d100 within 50 plus 5 a
  caster level above its strength (2 less a level below), and clouds around the target cell end the same way. Note: each
  pass works on the first target. }
procedure SpellDispelMagic;

{ Casts Prayer: the effect with the caster's side in bit 4 and the caster level. }
procedure SpellPrayer;

{ Spells 44 and 100, Bestow Curse: curses the targets. }
procedure SpellBestowCurse;

{ Applies Blink's effect to the targets. }
procedure SpellBlink;

{ Spells 47, Fireball, 64, which has no name, and 108, Delay Blast Fireball: a caster level of d6 fire damage (2d3 + 1
  dice for spell 64, plus the dice count for Delay Blast), striking everyone within 2 cells of the target on the
  overland map. }
procedure SpellFireball;

{ Casts Haste on the caster's side; it removes Slow instead where there is one. }
procedure SpellHaste;

{ Casts Lightning Bolt: caster-level d6 electrical damage at the target cell, carried on as a 7-cell bolt that can
  bounce. }
procedure SpellLightningBolt;

{ Casts Heal: removes the target's diseases, blindness and feeblemindedness (recalculating Intelligence and Wisdom),
  then heals it to 1d4 below its maximum. Note: a target already within 1d4 of its maximum heals nothing. }
procedure SpellHeal;

{ Casts Slow on the caster's enemies; it removes Haste instead where there is one. }
procedure SpellSlow;

{ Casts Death Spell: spends a budget of 4d20 * 2 on the targets in list order, each costing 1, 2, 8, 16 or 20 by its
  highest level (at level 6, 20 above 51 maximum hit points; above level 8, 162). A target the budget covers drops dead;
  an immune target, or one the budget cannot cover, leaves the list. }
procedure SpellDeathSpell;

{ Removes Slow from the target, or else applies the Potion of Speed's effect. }
procedure SpellPotionOfSpeed;

{ Casts Cure Serious Wounds: heals the target 2d8 + 1, 1d8 more when the caster's deity is 4. }
procedure SpellCureSeriousWounds;

{ Gives the target frost giant strength: Strength 21 for 1d4 * 10 + 40, announced when that beats the target's own; the
  effect is added either way. }
procedure SpellGiantStrength;

{ Casts Disintegrate: unless the target's effects cancel it, the target disintegrates on a failed save against spells. }
procedure SpellDisintegrate;

{ Applies the Wand of Paralyzation's effect to the targets ("is paralyzed"). }
procedure SpellWandOfParalyzation;

{ Heals the first target 2d4 + 2 hit points for the Potion of Healing. }
procedure SpellPotionOfHealing;

{ Casts Globe of Invulnerability: applies its effect, protecting the targets. }
procedure SpellGlobeOfInvulnerability;

{ Deals the Wand of Magic Missiles' 2d4 + 2 magic damage. }
procedure SpellWandOfMagicMissiles;

{ Casts Stone to Flesh: restores a petrified target with 1 hit point; in combat it rises from among the downed. }
procedure SpellStoneToFlesh;

{ Casts Neutralize Poison: cures the poison of a target that is not animated (Poisoned and both slow-poison effects
  removed with the effect lock), raising 0 hit points to 1 and setting it okay; an unpoisoned target "is unaffected". }
procedure SpellNeutralizePoison;

{ Casts Poison: applies the spell, then, unless the effects of the caster's target cancel the poison attack, runs the
  poison attack's handler (a poison bite) for the caster. }
procedure SpellPoison;

{ Casts Sticks to Snakes: a target below attack level 6 fights snakes, with the caster level as the effect's strength; a
  stronger one "smashes them flat". }
procedure SpellSticksToSnakes;

{ Spell 71, Cure Critical Wounds: heals the target 3d8 + 3 hit points, d8 more when the caster's deity is 4. }
procedure SpellCureCriticalWounds;

{ Casts Flesh to Stone: unless the target's effects cancel it, the target turns to stone on a failed save against
  spells. }
procedure SpellFleshToStone;

{ Casts Dispel Evil: gives the caster the dispel evil effect for the spell's duration and applies the spell. }
procedure SpellDispelEvil;

{ Casts Flame Strike: deals 6d8 fire damage. }
procedure SpellFlameStrike;

{ Casts Raise Dead: raises a dead or animated target that is not an elf and has Constitution left: its poison is removed
  under the effect lock, it becomes okay with 1 hit point and loses a point of base Constitution ("is raised"). }
procedure SpellRaiseDead;

{ Casts Slay Living: unless the first target's effects cancel it (then it 'is unaffected'), the target is slain ('is
  slain') when it fails a saving throw (type 4) and lacks immunity bit 8; otherwise it takes 2d8 + 1 magic damage. }
procedure SpellSlayLiving;

{ Spell 78, Entangle: outdoors only, entangles the targets, a save resisting. }
procedure SpellEntangle;

{ Casts Faerie Fire: ApplyEffectToTargets ("is highlighted"). }
procedure SpellFaerieFire;

{ Casts Invisibility to Animals: makes the targets invisible to animals. }
procedure SpellInvisibilityToAnimals;

{ Casts Charm Monsters: ApplyEffectToTargets ("is charmed"), then the charm handler for each charmed target. }
procedure SpellCharmMonsters;

{ Casts Confusion: up to 2d8 targets save (type 4) or are confused. }
procedure SpellConfusion;

{ Casts Dimension Door: erases the caster's icon, places it on the target cell, scrolls the view to it and reports
  "teleports". Note: the placement's result is ignored. }
procedure SpellDimensionDoor;

{ Spell 84, Fear: everyone in a cone 6 cells long toward the target cell flees in terror unless they save. }
procedure SpellFear;

{ Casts Fire Shield: the caster picks hot or cold flames (the computer at random), which shield it and zap its
  attackers; declining asks whether to abort the spell. }
procedure SpellFireShield;

{ Casts Fumble: a first target that fails a save (type 4) becomes clumsy ('is clumsy'), one that saves is slowed ('is
  slowed'), each effect with its handler run; then the spell's table effect is resolved on the targets as well ('is
  clumsy'). }
procedure SpellFumble;

{ Spell 87, Ice Storm: 3d10 damage. }
procedure SpellIceStorm;

{ Casts Minor Globe of Invulnerability: applies its effect to the targets. }
procedure SpellMinorGlobeOfInvulnerability;

{ Iron Skin: protects the targets. }
procedure SpellIronSkin;

{ Casts Cone of Cold: a cone of 2 rays toward the target cell, reaching (caster level + 1) div 2 cells, at least 1,
  deals caster level + caster-level d4 cold damage. }
procedure SpellConeOfCold;

{ Casts Feeblemind: applies the spell with the target's saving throw against spells shifted for the save by its class
  (cleric -1, magic-user +4, others +2), then runs the feeblemind effect's handler. }
procedure SpellFeeblemind;

{ Gives the targets the spell's effect, immunity to breath. }
procedure SpellImmuneBreath;

{ Makes the caster 1d4 + 1 years younger, but no younger than 18. }
procedure SpellYouth;

{ Spell 97: gives the targets the spell's effect. }
procedure SpellTurnInvisible;

{ Fire Touch: covers the targets in flame. }
procedure SpellFireTouch;

{ Spell 99: heals the target 2d4 + 2 hit points. }
procedure SpellHealSelf;

{ Casts Power Word Stun: stuns the target for 4d4 rounds at up to 30 hit points, 2d4 up to 60, 1d4 up to 90, and not at
  all above. }
procedure SpellPowerWordStun;

{ Spell 111, Mass Charm: charms the targets, up to twice the caster level in levels, a save resisting; creatures too
  large or not charmable are unaffected. }
procedure SpellMassCharm;

{ Spell 113, Otto's Irresistible Dance: on a hit, the target is held and dances. }
procedure SpellIrresistibleDance;

{ Power Word Blind: blinds targets until their maximum hit points pass 100 in all. }
procedure SpellPowerWordBlind;

{ Effect 78: casts a stored Fireball, the effect ending once it is cast.
  @param(character Creature with the effect.)
  @param(state Unused.)
  @param(removed Unused.) }
procedure EffStoredFireball(var character: Types.PCharacter; state: Pointer; removed: Boolean);

{ Effect 81: a charming gaze, cast as Charm Person at a target.
  @param(character Creature with the effect.)
  @param(state Unused.)
  @param(removed Unused.) }
procedure EffGazeCharm(var character: Types.PCharacter; state: Pointer; removed: Boolean);

{ Lightning breath effect: three times a battle (the effect's strength is set to 3 in round 0 and counts the breaths
  left), the creature aims as for Lightning Bolt; if a target was chosen it prints "Breathes!", turns toward the target
  and breathes lightning at the target cell and along a 10-cell path, doing its maximum hit points (save type 3), then
  spends a breath and ends its turn.
  @param(character The creature that carries the effect.)
  @param(state The effect's node on the creature.)
  @param(removed Unused.) }
procedure EffBreatheLightning(var character: Types.PCharacter; state: Pointer; removed: Boolean);

{ Effects 90 (acid), 100 (death) and 104 (fire): a breath three times a fight, its reach and element by the effect.
  @param(character Creature breathing.)
  @param(state The effect record, counting the breaths left.)
  @param(removed Unused.) }
procedure EffDragonBreath(var character: Types.PCharacter; state: Pointer; removed: Boolean);

{ Tells whether a deity gift (cast class 2) is already in a character's memorized spells. Note: the first memorized slot
  is not searched.
  @param(character The character.)
  @param(spellId The spell; bit 7 is ignored.)
  @returns(True when it is there.) }
function SpellKnown(character: Types.PCharacter; spellId: Byte): Boolean;

{ Tells whether a character's classes and stats let it cast a spell, by its cast class: cleric spells and gifts need
  wisdom above 8 and cleric levels, knight above 5 or paladin above 8; druid spells wisdom above 8 and ranger above 7;
  magic-user spells intelligence above 8 and mage levels or ranger above 8, but not for a human in body armor below
  ranger 9 in combat; type 4 never.
  @param(character The character.)
  @param(spellId The spell; bit 7 is ignored.)
  @returns(True when it can.) }
function ClassCanCastSpell(character: Types.PCharacter; spellId: Byte): Boolean;

{ Resolves Haste or Slow for up to the casting level of targets on one team, dropping the rest. A kept target with the
  opposing effect only loses it; the others take the spell's effect and have their movement and attack-rate effects run
  again.
  @param(counterEffect The opposing effect, Slowed or Hasted.)
  @param(side The team to keep: 0 the party's side, 1 the hostiles.)
  @param(message The effect message.) }
procedure HasteSlowLogic(counterEffect, side: Byte; message: Types.TString40);

{ The holds, charms and Faerie Fire: gives each target the spell's effect, unless it saves (Faerie Fire's and Charm
  Monsters' last target never saves; a monster always saves against Hold Person), with the missile drawn to each target
  after the first.
  @param(saveModifier Bonus to the targets' saves.)
  @param(message Message for a target affected.) }
procedure ApplyEffectToTargets(saveModifier: Byte; message: Types.TString40);

{ Applies the current spell to the targets on one side -- in combat only those with no enemy adjacent.
  @param(side Side the spell is meant for.)
  @param(message Message for a target affected.) }
procedure CastOneSide(side: Byte; message: Types.TString40);

{ Appends a spell to the scroll spell list (and its id list), with a level heading when its level differs from the last
  spell's.
  @param(spellId The spell; bit 7 marks it with " *".) }
procedure AddScrollSpellLine(spellId: Byte);

{ Inserts a spell into the list sorted by level, a repeat counting up the row's (N); a marked spell gets a star.
  @param(spellId The spell; bit 7 marks it.) }
procedure InsertSpellEntry(spellId: Byte);

{ Adds the current scroll's spells when the caster can read it -- under Read Magic, or a cleric with a priest scroll,
  which identifies it -- recording the scroll for each.
  @param(markedOnly Non-zero for the spells marked for scribing alone.) }
procedure AddScrollSpells(markedOnly: Byte);

{ Adds the spells of the current character's readable scrolls that suit its robe order (bit $20 of a scroll's
  identification mask for order 1, $10 for order 2), through AddScrollSpells.
  @param(markedOnly Passed on to AddScrollSpells.) }
procedure AddAllScrollSpells(markedOnly: Byte);
implementation
const
  { Spell ids, in spellNames order. }
  SPELL_SLOW_POISON = 26;
  SPELL_DISPEL_EVIL = 73;
  SPELL_ENTANGLE = 78;
  SPELL_FUMBLE = 86;
  SPELL_OTTOS_IRRESISTIBLE_DANCE = 113;
type
  TScrollSpellsLocals = packed record
    effectLead: Byte;
    effect: Pointer;
    index: Byte
  end;
  TStoneToFleshLocals = packed record
    scan: Byte;
    index: Byte;
    indexTail: Byte
  end;
  TDispelLocals = packed record
    removedLead: Byte;
    removed: Byte
  end;
  TCounterLocals = packed record
    indexLead: Byte;
    index: Byte;
    countersLeft: Byte
  end;
  TBoltLocals = packed record
    used: Integer;
    remaining: Byte;
    cell: Byte;
    neighbor: Byte;
    prior: Byte;
    useRange: Byte;
    stepped: Byte;
    accepted: Byte;
    sign: ShortInt;
    savedY: ShortInt;
    savedX: ShortInt;
    originY: ShortInt;
    originX: ShortInt;
    returnPath: Types.TPathReq;
    path: Types.TPathReq
  end;
  TBoltCellLocals = packed record
    cellLead: array[0..1] of Byte;
    cell: Byte;
    neighbor: Byte;
    current: Pointer
  end;

procedure LightningAttackAt(x, y, damage, saveType, skipCreature: Byte; var bounced: Byte); forward;

procedure LightningPath(range, damage, saveType, doubleOnRebound: Byte); forward;

procedure CollectConeTargets(fromX, fromY, toX, toY, width, reach: Byte); forward;

function CalcSpellDuration(spellId: Byte): Word; forward;

procedure ResolveSpell(spellId, strength, onRemove, damage, damageElement: Byte; message: Types.TString40); forward;

function SpellKnown(character: Types.PCharacter; spellId: Byte): Boolean;
var index: Byte;
    found: Boolean;
begin
  spellId := spellId and $7F;
  SpellKnown := False;
  if (Types.PCharacter(character)^.spells <> nil) and (GDConsts.spellTable[spellId].castClass = 2) then begin
    index := 1;
    found := False;
    while not found and (index <= 73) do begin
      if (Types.PCharacter(character)^.spells^.memorized[index] and $7F) = spellId then
        found := True;
      Inc(index)
    end;
    SpellKnown := found
  end
end;

function ClassCanCastSpell(character: Types.PCharacter; spellId: Byte): Boolean;
begin
  spellId := spellId and $7F;
  ClassCanCastSpell := False;
  case GDConsts.spellTable[spellId].castClass of
      0, 2: ClassCanCastSpell := (Ord(Types.PCharacter(character)^.stats[C_Stat.WISDOM].current > 8) <> 0) and
        ((Types.PCharacter(character)^.classLevels[C_Class.CLERIC] > 0) or
         (Types.PCharacter(character)^.classLevels[C_Class.KNIGHT] > 5) or
         (Types.PCharacter(character)^.classLevels[C_Class.PALADIN] > 8));
      1: ClassCanCastSpell := (Ord(Types.PCharacter(character)^.stats[C_Stat.WISDOM].current > 8) <> 0) and
        (Types.PCharacter(character)^.classLevels[C_Class.RANGER] > 7);
      3: ClassCanCastSpell := (Types.PCharacter(character)^.stats[C_Stat.INTELLIGENCE].current > 8) and
        not ((Types.PCharacter(character)^.race = C_Race.HUMAN) and
             (Types.PCharacter(character)^.equipped[2] <> nil) and
             (Types.PCharacter(character)^.classLevels[C_Class.RANGER] <= 8) and
             (GDVars.interfaceState = C_Ifc.IN_COMBAT)) and
        ((Types.PCharacter(character)^.classLevels[C_Class.RANGER] > 8) or
         (Types.PCharacter(character)^.classLevels[C_Class.MAGE] > 0));
      4: ClassCanCastSpell := False
  end
end;

function SpellSelection(selectionType: Byte; var index: Integer): Byte;
var selected: Pointer;
    cursor: Types.PMenuRow;
    query: Types.TString40;
    menu: Types.TString40;
    { Unused in this version; see the other implementations of this routine. }
    spellLevel: Byte;
    count: Byte;
    rows: Byte;
    key: Byte;
    allowExit: Boolean;
    redraw: Byte;
    choiceCount: ShortInt;
begin
  query := GDConsts.chooseSpellQuery;
  rows := 22;
  choiceCount := 0;
  MenuCore.EnableChoices(0);
  redraw := 0;
  GDVars.selectedChoice := 1;
  case selectionType of
    1: menu := GDConsts.castMenu;
    2: begin
      menu := GDConsts.memorizeMenu;
      rows := 15;
      redraw := GDVars.specialSpellSelection
    end;
    3: menu := GDConsts.scribeMenu;
    4: menu := GDConsts.learnMenu;
    5: begin
      query := GDConsts.spellsOkQuery;
      menu := GDConsts.keepMenu
    end else
    choiceCount := -1;
    menu := GDConsts.emptyMenu;
    query := GDConsts.emptyQuery
  end;
  allowExit := selectionType <> 4;
  if index < 0 then begin
    redraw := 1;
    index := 0
  end;
  if (selectionType = 4) or (selectionType = 1) then redraw := 1;
  selected := nil;
  repeat
    key := MenuCore.MenuVertical(query, menu, 1, 5, 38, rows, GDVars.spellListHead, Ord(allowExit), choiceCount, redraw,
                                 index, selected)
  until (key = 0) or (key = Ord(C_Keys.ESCAPE));
  cursor := GDVars.spellListHead;
  count := 0;
  while cursor <> selected do begin
    if cursor^.heading = 0 then Inc(count);
    cursor := cursor^.next
  end;
  if key <> 0 then SpellSelection := 0
  else SpellSelection := GDVars.entrySpellIds[count];
  if selectionType = 3 then GDVars.scroll := GDVars.entryScrolls[count];
  MenuCore.FreeMenuRows(GDVars.spellListHead)
end;

const
  STAR_TEXT = ' *';
  BLANK_TEXT = '  ';

procedure AddScrollSpellLine(spellId: Byte);
var node: Types.PMenuRow;
    count: ShortInt;
    previousKind: Byte;
begin
  node := GDVars.spellListHead;
  if GDVars.spellListHead = nil then begin
    New(node);
    GDVars.spellListHead := node;
    previousKind := 0;
    count := 0
  end else begin
    count := 1;
    while node^.next <> nil do begin
      if node^.heading = 0 then Inc(count);
      node := node^.next
    end;
    previousKind := GDConsts.spellTable[GDVars.entrySpellIds[count - 1]].level;
    New(node^.next);
    node := node^.next
  end;
  node^.next := nil;
  if Byte(GDConsts.spellTable[spellId and $7F].level) <> previousKind then begin
    node^.name := GDConsts.spellLevelLabels[GDConsts.spellTable[spellId and $7F].level];
    node^.heading := 1;
    New(node^.next);
    node := node^.next;
    node^.next := nil
  end;
  if spellId > $7F then node^.name := Magic.STAR_TEXT
  else node^.name := Magic.BLANK_TEXT;
  node^.name := node^.name + GDConsts.spellNames[spellId and $7F];
  node^.heading := 0;
  GDVars.entrySpellIds[count] := spellId and $7F
end;

const
  OPEN_COUNT = ' (';
  CLOSE_COUNT = ')';

procedure InsertSpellEntry(spellId: Byte);
var
  saved: Byte;
  displaced: Byte;
  node: Types.PMenuRow;
  scan: Types.PMenuRow;
  inserted: Types.PMenuRow;
  position: ShortInt;
  index: Byte;
  found: Byte;
  kind: Byte;
begin
  node := GDVars.spellListHead;
  found := 0;
  kind := GDConsts.spellTable[spellId and $7F].level;
  if GDVars.spellListHead = nil then begin
    FillChar(GDVars.entryCopies, SizeOf(GDVars.entryCopies), 0);
    New(node);
    node^.next := nil;
    GDVars.spellListHead := node;
    position := 0;
    GDVars.entryCopies[position] := 1
  end else begin
    position := 0;
    while (node <> nil) and (found = 0) do
      if node^.heading = 0 then begin
        if (GDConsts.spellTable[GDVars.entrySpellIds[position]].level <= ShortInt(kind)) and
            (GDVars.entrySpellIds[position] <> (spellId and $7F)) then begin
          Inc(position);
          node := node^.next
        end else
          found := 1
      end else begin
        node := node^.next;
        Inc(position)
      end;
    if GDVars.entrySpellIds[position] <> (spellId and $7F) then begin
      scan := GDVars.spellListHead;
      if scan <> node then begin
        while scan^.next <> node do
          scan := scan^.next;
        New(inserted);
        inserted^.next := scan^.next;
        scan^.next := inserted;
        node := inserted
      end else begin
        New(inserted);
        inserted^.next := node;
        GDVars.spellListHead := inserted;
        node := inserted
      end;
      saved := 1;
      for index := position to 73 do begin
        displaced := GDVars.entryCopies[index];
        GDVars.entryCopies[index] := saved;
        saved := displaced
      end
    end else
      Inc(GDVars.entryCopies[position])
  end;
  if spellId > $7F then node^.name := Magic.STAR_TEXT
  else node^.name := Magic.BLANK_TEXT;
  node^.name := node^.name + GDConsts.spellNames[spellId and $7F];
  node^.heading := 0;
  if GDVars.entryCopies[position] > 1 then
    node^.name := node^.name + Magic.OPEN_COUNT + CharHlp.ByteToString(GDVars.entryCopies[position]) +
      Magic.CLOSE_COUNT;
  if GDVars.entrySpellIds[position] <> (spellId and $7F) then begin
    saved := GDVars.entrySpellIds[position];
    GDVars.entrySpellIds[position] := spellId and $7F;
    for index := position + 1 to 73 do begin
      displaced := GDVars.entrySpellIds[index];
      GDVars.entrySpellIds[index] := saved;
      saved := displaced
    end
  end
end;

procedure AddScrollSpells(markedOnly: Byte);
var local: TScrollSpellsLocals;
begin
  if CharHlp.HasEffect(GDVars.currentCharacter, C_Effect.READ_MAGIC, local.effect) or
      ((GDVars.currentCharacter^.classLevels[C_Class.CLERIC] > 0) and
       (GDVars.baseItems[GDVars.scroll^.itemType].slot = 12))
  then
    GDVars.scroll^.unidentifiedMask := GDVars.scroll^.unidentifiedMask and
      $F8;
  if (GDVars.scroll^.unidentifiedMask and $07) = 0 then begin
    for local.index := 1 to 3 do
      if (((markedOnly <> 0) and (GDVars.scroll^.scrollSpells[local.index] > $80)) or
          ((markedOnly = 0) and (GDVars.scroll^.scrollSpells[local.index] > 0))) then begin
        Magic.AddScrollSpellLine(GDVars.scroll^.scrollSpells[local.index]);
        GDVars.entryScrolls[GDVars.entryScrollCount] := GDVars.scroll;
        Inc(GDVars.entryScrollCount)
      end
  end
end;

procedure AddAllScrollSpells(markedOnly: Byte);
var index: Byte;
begin
  for index := 0 to 48 do
    GDVars.entryScrolls[index] := nil;
  GDVars.entryScrollCount := 0;
  GDVars.scroll := GDVars.currentCharacter^.items;
  while GDVars.scroll <> nil do begin
    if Magic.ItemReadable(GDVars.scroll) then
      if (((GDVars.currentCharacter^.robeOrder = 1) and
           ((GDVars.scroll^.unidentifiedMask and $20) <> 0)) or
             ((GDVars.currentCharacter^.robeOrder = 2) and
              ((GDVars.scroll^.unidentifiedMask and $10) <> 0)))
      then
        Magic.AddScrollSpells(markedOnly);
    GDVars.scroll := GDVars.scroll^.next
  end
end;

function GenerateSpellList(mode: Byte): Byte;
var
  index: Byte;
  selected: Byte;
  currentNode: Types.PMenuRow;
  newNode: Types.PMenuRow;
  savedKind: Byte;
  currentKind: ShortInt;
  buildGroups: Byte;
  tableRow: Byte;
begin
  buildGroups := 1;
  GenerateSpellList := 0;
  GDVars.spellListHead := nil;
  for index := 0 to 73 do
    GDVars.entrySpellIds[index] := 0;
  if (GDVars.currentCharacter^.spells = nil) and not (mode in [2, 3]) then begin
    Exit
  end;
  with GDVars.currentCharacter^ do
  case mode of
    0: for index := 0 to 73 do
        if (spells^.memorized[index] > 0) and
            Magic.ClassCanCastSpell(GDVars.currentCharacter, spells^.memorized[index] and $7F) and
            (spells^.memorized[index] < $80) then
          Magic.InsertSpellEntry(spells^.memorized[index]);
    5: for index := 0 to 73 do
        if (spells^.memorized[index] > $7F) and
            Magic.ClassCanCastSpell(GDVars.currentCharacter, spells^.memorized[index] and $7F) then
          Magic.InsertSpellEntry(spells^.memorized[index]);
    1: for index := 1 to SizeOf(GDConsts.spellTable) div SizeOf(GDConsts.spellTable[1]) do
        if (spells^.known[index] <> 0) and
            Magic.ClassCanCastSpell(GDVars.currentCharacter, index) and
            not Magic.SpellKnown(GDVars.currentCharacter, index) then
          Magic.InsertSpellEntry(index);
    2: begin
        Magic.AddScrollSpells(0);
        buildGroups := 0
      end;
    3: begin
        Magic.AddAllScrollSpells(0);
        buildGroups := 0
      end;
    6: begin
        Magic.AddAllScrollSpells(1);
        buildGroups := 0
      end;
    4: begin
        if robeOrder = 1 then
          tableRow := 2
        else
          tableRow := 3;
        for currentKind := 1 to 8 do
          if spells^.slots[3, currentKind] > 0 then begin
            index := 1;
            selected := 255;
            while (index <= 10) and (selected <> 0) do begin
              selected := GDConsts.spellsByLevel[tableRow, currentKind, index];
              if (selected <> 0) and (spells^.known[selected] = 0) then
                Magic.InsertSpellEntry(selected);
              Inc(index)
            end
          end
      end
  end;
  if GDVars.spellListHead = nil then begin
    Exit
  end;
  if buildGroups <> 0 then begin
    index := 0;
    currentKind := GDConsts.spellTable[GDVars.entrySpellIds[index]].level;
    New(newNode);
    newNode^.next := GDVars.spellListHead;
    GDVars.spellListHead := newNode;
    GDVars.spellListHead^.name := GDConsts.spellLevelLabels[GDConsts.spellTable[GDVars.entrySpellIds[index]].level];
    GDVars.spellListHead^.heading := 1;
    currentNode := GDVars.spellListHead;
    repeat
      savedKind := currentKind;
      if GDVars.entrySpellIds[index] <> 0 then
        currentKind := GDConsts.spellTable[GDVars.entrySpellIds[index]].level;
      if ShortInt(savedKind) < ShortInt(currentKind) then begin
        New(newNode);
        newNode^.next := currentNode^.next;
        currentNode^.next := newNode;
        currentNode := currentNode^.next;
        currentNode^.name := GDConsts.spellLevelLabels[ShortInt(currentKind)];
        currentNode^.heading := 1
      end;
      Inc(index);
      currentNode := currentNode^.next
    until currentNode = nil
  end;
  GenerateSpellList := 1
end;

function CalcSpellRange(spellId: Byte): Byte;
var resolved: Byte;
begin
  if GDVars.usingItem = 0 then
    resolved := GDConsts.spellTable[spellId].range +
      GDConsts.spellTable[spellId].rangePerLevel * CharHlp.GetCasterLevel(spellId)
  else
    resolved := GDConsts.spellTable[spellId].rangePerLevel * 6 + GDConsts.spellTable[spellId].range;
  if (resolved = 0) and (GDConsts.spellTable[spellId].targeting <> 0) then resolved := 1;
  if resolved = 255 then resolved := 1;
  CalcSpellRange := resolved
end;

{ Returns a spell's duration: fixed for Slow Poison, rolled for spells 57, 59 and 61, otherwise the table's duration
  plus its duration per level times the caster level.
  @param(spellId The spell.)
  @returns(The duration, in minutes.) }
function CalcSpellDuration(spellId: Byte): Word;
var resolved: Word;
begin
  case spellId of
    Magic.SPELL_SLOW_POISON: resolved := 3780;
    57, 61: resolved := FxEngine.RollDice(5, 4);
    59: resolved := FxEngine.RollDice(1, 4) * 10 + 40
  else
    resolved := GDConsts.spellTable[spellId].durationPerLevel * CharHlp.GetCasterLevel(spellId) +
      GDConsts.spellTable[spellId].duration
  end;
  CalcSpellDuration := resolved
end;

{ Applies a spell to each target. The save is rolled only when the spell has a saving throw. A spell of fixed range 255
  needs an attack roll as well; a miss counts as saved and zeroes the damage for this and each later target. The damage
  is dealt with the save reducing it, and the spell's effect, if any, is added. With no targets it returns at once,
  leaving the element mask set.
  @param(spellId The spell.)
  @param(strength The effect's strength; 0 for the casting level.)
  @param(onRemove True to call the effect's handler when it is removed.)
  @param(damage The damage; 0 for none.)
  @param(damageElement The damage's element mask.)
  @param(message Printed after each target's name when the effect takes hold.) }
procedure ResolveSpell(spellId, strength, onRemove, damage, damageElement: Byte; message: Types.TString40);
var
  value: Byte;
  index: Byte;
  { Unused in this version; see the other implementations of this routine. }
  target: array[1..4] of Byte;
  predicate: Byte;
  saved: Boolean absolute predicate;
begin
  if damage = 0 then
    GDVars.elementMask := 0
  else
    GDVars.elementMask := damageElement;
  if GDVars.spellTargetState.count <> 0 then begin
    if strength = 0 then value := CharHlp.GetCasterLevel(spellId)
    else value := strength;
    for index := 1 to GDVars.spellTargetState.count do
      if GDVars.spellTargetState.targets[index] <> nil then begin
        if GDConsts.spellTable[spellId].saveEffect = 0 then
          predicate := 0
        else
          predicate := Ord(FxEngine.RollSavingThrow(GDVars.spellTargetState.targets[index],
                                                    GDConsts.spellTable[spellId].saveType, 0));
        if GDConsts.spellTable[GDVars.currentSpellIndex].range = 255 then begin
          CharHlp.RecalcStats(GDVars.spellTargetState.targets[index]);
          FxEngine.TriggerEffectsWithCondition(C_Cond.DEFENDER_ARMOR_CLASS, GDVars.spellTargetState.targets[index]);
          if not FxEngine.AttackRoll(GDVars.currentCharacter, GDVars.spellTargetState.targets[index],
                                     GDVars.spellTargetState.targets[index]^.armorClass)
          then begin
            damage := 0;
            predicate := 1
          end
        end;
        if damage > 0 then
          FxEngine.InflictNonWeaponDamage(GDVars.spellTargetState.targets[index], damage,
                                          GDConsts.spellTable[spellId].saveEffect, saved);
        if GDConsts.spellTable[spellId].effectId > 0 then
          FxEngine.AddEffectWithMessage(GDVars.spellTargetState.targets[index], GDConsts.spellTable[spellId].effectId,
                                        Magic.CalcSpellDuration(spellId), value, onRemove,
                                        GDConsts.spellTable[spellId].saveEffect, predicate, message)
      end;
    GDVars.elementMask := 0
  end
end;

procedure NoncombatCastTargetMenu(spellId, mode: Byte; var result: Byte);
var
  { Unused in this version; see the other implementations of this routine. }
  target: LongInt;
begin
  if GDVars.spellTargetState.noncombatTarget =
      nil then GDVars.spellTargetState.noncombatTarget := GDVars.currentCharacter;
  GDVars.spellTargetState.targets[1] := GDVars.currentCharacter;
  GDVars.spellTargetState.count := 1;
  result := 1;
  case GDConsts.spellTable[spellId].campTarget of
    1: ;
    2: begin
      CharHlp.DisplayNoncombatInterface;
      CharHlp.SelectChar(GDConsts.spellTargetPrompt, True, 1, GDVars.spellTargetState.noncombatTarget);
      if GDVars.spellTargetState.noncombatTarget = nil then begin
        GDVars.spellTargetState.targets[1] := nil;
        GDVars.spellTargetState.count := 0;
        result := 0
      end else
        GDVars.spellTargetState.targets[1] := GDVars.spellTargetState.noncombatTarget
    end;
    3: begin
      GDVars.spellTargetState.targets[GDVars.spellTargetState.count] := GDVars.partyHead;
      while GDVars.spellTargetState.targets[GDVars.spellTargetState.count]^.next <>
          nil do begin
        GDVars.spellTargetState.targets[GDVars.spellTargetState.count + 1] :=
          GDVars.spellTargetState.targets[GDVars.spellTargetState.count]^.next;
        Inc(GDVars.spellTargetState.count)
      end
    end else
    result := 0
  end
end;

procedure CastSpell(spellId, noPrompt, announce: Byte; var cast: Byte);
var active: Byte;
    { Unused in this version; see the other implementations of this routine. }
    spellClass: Byte;
    x: Byte;
    y: Byte;
    value: Byte;
    { Unused in this version; see the other implementations of this routine. }
    magicResistance: Byte;
    character: Pointer;
    { Unused in this version; see the other implementations of this routine. }
    workBuffer: array[0..3] of Byte;
begin
  character := GDVars.currentCharacter;
  active := 1;
  if (GDVars.interfaceState <> C_Ifc.IN_COMBAT) and (GDConsts.spellTable[spellId].campTarget = 0) then begin
    if GDVars.usingItem = 0 then begin
      TextRend.DisplayString(1, 19, LightGreen, Black, GDConsts.spellNames[spellId]);
      TextRend.DisplayString(1, 20, LightGreen, Black, GDConsts.cantCastHereText);
      if MenuCore.YesNoMenu(GDConsts.loseQuery, GDConsts.yesKey) = GDConsts.yesKey then
        CharHlp.RemoveSpell(character, spellId)
    end else begin
      TextRend.DisplayString(1, 19, LightGreen, Black, GDConsts.itemLabel);
      TextRend.DisplayString(1, 20, LightGreen, Black, GDConsts.combatOnlyItemText);
      if MenuCore.YesNoMenu(GDConsts.useItemPrompt, GDConsts.yesKey) = GDConsts.yesKey then
        cast := 1
    end;
    announce := 0;
    active := 0
  end;
  if (announce <> 0) and (GDVars.usingItem = 0) then
    Magic.PrintCastSpellMsg(character, GDConsts.castsText, spellId);
  while active <> 0 do begin
    GDVars.spellServices.selectTargets(spellId, noPrompt, cast);
    if cast <> 0 then begin
      active := 0;
      if GDVars.interfaceState = C_Ifc.IN_COMBAT then begin
        CharHlp.BuildIconFacings(18);
        x := CbtMap.CombatCellX(character);
        y := CbtMap.CombatCellY(character);
        value := C_Dir.NORTH;
        while not Pathing.IsDirToward(x, y, GDVars.targetX, GDVars.targetY, value) do
          Inc(value);
        GDVars.showTurn := 1;
        CbtMap.SetCreatureFacing(character, value, 1, 0);
        case spellId of
          C_Spell.FIREBALL: Music.SendSoundCommand(GDConsts.fireballSound);
          C_Spell.LIGHTNING_BOLT: Music.SendSoundCommand(GDConsts.lightningSound)
        else
          Music.SendSoundCommand(GDConsts.spellSound)
        end;
        CharHlp.CombatAnimateMovingIcon(Integer(ShortInt(x)), Integer(ShortInt(y)), Integer(ShortInt(GDVars.targetX)),
                                        Integer(ShortInt(GDVars.targetY)), 4, 30);
        case spellId of
          C_Spell.STINKING_CLOUD: CharHlp.ScatterCombatIcon(1, 26, Byte(GDConsts.fireballSound));
          C_Spell.CLOUDKILL: CharHlp.ScatterCombatIcon(1, 27, Byte(GDConsts.fireballSound));
          64, C_Spell.FIREBALL, C_Spell.DELAY_BLAST_FIREBALL:
            if (GDVars.zone0^.inDungeon = 0) or (spellId = 64) then
              CharHlp.ScatterCombatIcon(2, 24, Byte(GDConsts.fireballSound))
            else
              CharHlp.ScatterCombatIcon(3, 24, Byte(GDConsts.fireballSound));
          C_Spell.ICE_STORM: CharHlp.ScatterCombatIcon(2, 25, Byte(GDConsts.fireballSound))
        end;
        if CbtMap.CombatIconVisible(character, 0) then begin
          CbtMap.SetCreatureFacing(character, Types.PCharacter(character)^.combat^.direction, 1, 1);
          CbtMap.SetCreatureFacing(character, Types.PCharacter(character)^.combat^.direction, 0, 0)
        end
      end;
      FxEngine.RemoveInvisibility(character);
      if GDVars.usingItem = 0 then
        CharHlp.RemoveSpell(character, spellId);
      GDVars.currentSpellIndex := spellId;
      GDVars.spellServices.handlers[GDVars.currentSpellIndex];
      GDVars.currentSpellIndex := 0;
      GDVars.areaSpellActive := 0
    end else if GDVars.interfaceState <> C_Ifc.IN_COMBAT then
      active := 0
    else begin
      if (noPrompt <> 0) or
          (MenuCore.YesNoMenu(GDConsts.abortSpellPrompt, GDConsts.yesKey) = GDConsts.yesKey) then begin
        CharHlp.PrintBottomLine(GDConsts.spellAbortedText);
        if GDVars.usingItem = 0 then
          CharHlp.RemoveSpell(character, spellId);
        active := 0
      end
    end
  end;
  CharHlp.ClearMessageWindow;
  if GDVars.interfaceState = C_Ifc.IN_COMBAT then
    Border.ClearBox(0, 23, 39, 23)
end;

{ Fills the spell targets with the creatures, other than the caster, on a line from the origin through the aimed cell,
  extended to the cone's length and cut short by walls, and with two or three rays on one or two more lines to cells
  beside its end; 255 rays take instead the creatures within 3 cells of the line's end. Note: once a creature has been
  met twice on the main line, no later creature on it is added; and the area list of 255 rays overwrites the line's list
  without ending it, so creatures past its length stay.
  @param(fromX The column of the cone's origin.)
  @param(fromY The row of the cone's origin.)
  @param(toX The column of the aimed cell.)
  @param(toY The row of the aimed cell.)
  @param(width The number of lines (1, 2 or 3), or 255 for an area at the end.)
  @param(reach The cone's length in cells.) }
procedure CollectConeTargets(fromX, fromY, toX, toY, width, reach: Byte);
var
  x1: Byte;
  y1: Byte;
  x2: Byte;
  y2: Byte;
  path: Types.TPathReq;
  done: Byte;
  { Unused in this version; see the other implementations of this routine. }
  probeResult: Byte;
  distance: Byte;
  pathIndex: Byte;
  lastIndex: Byte;
  directions: array[0..49] of Byte;
  candidates: array[0..30] of Byte;
  cell: Byte;
  candidateCount: Byte;
  outputIndex: Byte;
  finalDirection: Byte;
  range: Word;
  found: Boolean;

  { Starts the line walk from one cell to another. }
  procedure SetLine(sx, sy, ex, ey: Byte);
  begin
    path.sx := Integer(ShortInt(sx));
    path.sy := Integer(ShortInt(sy));
    path.ex := Integer(ShortInt(ex));
    path.ey := Integer(ShortInt(ey));
    Pathing.PathFind(path)
  end;

  { Clamps a cell to the arena. }
  procedure ClampCell(var x, y: ShortInt);
  begin
    if x > 49 then x := 49
    else if x < 0 then x := 0;
    if y > 24 then y := 24
    else if y < 0 then y := 0
  end;

  { Adds each creature on the rest of the walked line to the list, once. }
  procedure CollectAlong;
  var index: Byte;
    matched: Boolean;
  begin
    repeat
      done := Ord(not Pathing.NextPathStep(path));
      if done = 0 then begin
        CbtMap.GetArenaContents(Byte(path.cx), Byte(path.cy), candidates[0], cell);
        index := 1;
        matched := False;
        if candidates[0] > 0 then
          repeat
            if candidates[index] = candidates[0] then
              matched := True
            else if candidates[index] = 0 then begin
              candidates[index] := candidates[0];
              matched := True
            end else
              Inc(index)
          until matched
      end
    until done <> 0
  end;
begin
  pathIndex := 0;
  SetLine(fromX, fromY, toX, toY);
  repeat
    done := Ord(not Pathing.NextPathStep(path));
    if done = 0 then begin
      directions[pathIndex] := path.step;
      Inc(pathIndex)
    end
  until done <> 0;
  lastIndex := pathIndex - 1;
  pathIndex := 0;
  reach := reach * 2;
  distance := path.dist;
  done := 0;
  while (distance < reach) and (done = 0) do begin
    if (ShortInt(toX) < 49) and (ShortInt(toX) > 0) and (ShortInt(toY) < 24) and (ShortInt(toY) > 0) then begin
      case directions[pathIndex] of
        C_Dir.NORTH, C_Dir.EAST, C_Dir.SOUTH, C_Dir.WEST: Inc(distance, 2);
        C_Dir.NORTHEAST, C_Dir.SOUTHEAST, C_Dir.SOUTHWEST, C_Dir.NORTHWEST: Inc(distance, 3)
      end;
      Inc(toX, GDConsts.directionX[directions[pathIndex]]);
      Inc(toY, GDConsts.directionY[directions[pathIndex]]);
      if pathIndex = lastIndex then pathIndex := 0
      else Inc(pathIndex)
    end else
      done := 1
  end;
  ClampCell(ShortInt(toX), ShortInt(toY));
  range := reach;
  probeResult := Ord(Pathing.WalkLine(fromX, fromY, ShortInt(toX), ShortInt(toY), range, GDVars.arena));
  SetLine(fromX, fromY, toX, toY);
  FillChar(candidates[1], SizeOf(candidates) - 1, 0);
  candidateCount := 1;
  repeat
    done := Ord(not Pathing.NextPathStep(path));
    if done = 0 then begin
      CbtMap.GetArenaContents(Byte(path.cx), Byte(path.cy), candidates[0], cell);
      if candidates[0] > 0 then begin
        if candidateCount > 1 then begin
          for GDVars.loopIndex := 1 to candidateCount - 1 do
            if candidates[GDVars.loopIndex] = candidates[0] then found := True
        end else
          found := False;
        if not found then begin
          candidates[candidateCount] := candidates[0];
          Inc(candidateCount)
        end;
        finalDirection := path.step
      end
    end
  until done <> 0;
  if (width > 1) and (width <> 255) then begin
    x1 := Byte(ShortInt(toX) + GDConsts.directionNearX[finalDirection]);
    y1 := Byte(ShortInt(toY) + GDConsts.directionNearY[finalDirection]);
    ClampCell(ShortInt(x1), ShortInt(y1));
    x2 := Byte(ShortInt(toX) + GDConsts.directionFarX[finalDirection]);
    y2 := Byte(ShortInt(toY) + GDConsts.directionFarY[finalDirection]);
    ClampCell(ShortInt(x2), ShortInt(y2));
    SetLine(fromX, fromY, x2, y2);
    CollectAlong;
    if width > 2 then begin
      SetLine(fromX, fromY, x1, y1);
      CollectAlong
    end
  end;
  if width = 255 then begin
    Pathing.BuildTargetList(toX, toY, 3, GDConsts.anyDirection, 1, GDVars.arena);
    for GDVars.loopIndex := 1 to GDVars.targetCount do
      candidates[GDVars.loopIndex] := GDVars.targetList[GDVars.loopIndex].characterIndex
  end;
  candidateCount := 1;
  outputIndex := 1;
  GDVars.spellTargetState.count := 0;
  if candidates[1] <> 0 then
    repeat
      if GDVars.creatures[candidates[candidateCount]] <> GDVars.currentCharacter then begin
        Inc(GDVars.spellTargetState.count);
        GDVars.spellTargetState.targets[outputIndex] := GDVars.creatures[candidates[candidateCount]];
        Inc(outputIndex)
      end;
      Inc(candidateCount)
    until candidates[candidateCount] = 0
end;

procedure ApplyEffectToTargets(saveModifier: Byte; message: Types.TString40);
var current: Pointer;
    result: Byte;
    { Unused in this version; see the other implementations of this routine. }
    resultBoolean: Boolean absolute result;
    index: Byte;
    predicate: Byte;
    actionValue: Byte;
begin
  for index := GDVars.spellTargetState.count downto 1 do
    if GDVars.spellTargetState.targets[index] <> nil then begin
      current := GDVars.spellTargetState.targets[index];
      if index < GDVars.spellTargetState.count then begin
        Music.SendSoundCommand(GDConsts.spellSound);
        CharHlp.BuildIconFacings(18);
        CharHlp.CombatAnimateMovingIcon(Integer(ShortInt(CbtMap.CombatCellX(GDVars.currentCharacter))),
                                        Integer(ShortInt(CbtMap.CombatCellY(GDVars.currentCharacter))),
                                        Integer(ShortInt(CbtMap.CombatCellX(current))),
                                        Integer(ShortInt(CbtMap.CombatCellY(current))), 4, 30)
      end;
      if ((GDVars.currentSpellIndex = C_Spell.FAERIE_FIRE) or
          (GDVars.currentSpellIndex = C_Spell.CHARM_MONSTERS)) and
          (index = GDVars.spellTargetState.count) then begin
        result := 1;
        predicate := 1
      end else begin
        resultBoolean := FxEngine.RollSavingThrow(current, GDConsts.spellTable[GDVars.currentSpellIndex].saveType,
                                                  saveModifier);
        predicate := GDConsts.spellTable[GDVars.currentSpellIndex].saveEffect
      end;
      if (Types.PCharacter(current)^.race = C_Race.MONSTER) and
          ((GDVars.currentSpellIndex = C_Spell.HOLD_PERSON_CLERIC) or
           (GDVars.currentSpellIndex = C_Spell.HOLD_PERSON_MAGE)) then
        result := 1;
      if GDVars.currentSpellIndex = C_Spell.CHARM_MONSTERS then
        actionValue := CharHlp.GetCasterLevel(GDVars.currentSpellIndex) +
          GDVars.currentCharacter^.side * 128
      else
        actionValue := CharHlp.GetCasterLevel(GDVars.currentSpellIndex);
      FxEngine.AddEffectWithMessage(current, GDConsts.spellTable[GDVars.currentSpellIndex].effectId,
                                    Magic.CalcSpellDuration(GDVars.currentSpellIndex), actionValue, 0, predicate,
                                    result, message)
    end
end;

procedure CastOneSide(side: Byte; message: Types.TString40);
var index: Byte;
begin
  GDVars.areaSpellActive := 1;
  for index := 1 to GDVars.spellTargetState.count do
    if (Byte(GDVars.spellTargetState.targets[index]^.side) <> side) or
        ((GDVars.interfaceState = C_Ifc.IN_COMBAT) and
         (CharHlp.CountTargets(GDVars.spellTargetState.targets[index], 1, False) > 0)) then
      GDVars.spellTargetState.targets[index] := nil;
  Magic.ResolveSpell(GDVars.currentSpellIndex, 0, 0, 0, 0, message)
end;

procedure SpellBless;
begin
  Magic.CastOneSide(GDVars.currentCharacter^.side, GDConsts.isText + GDConsts.effectNames[C_Effect.BLESS])
end;

procedure SpellBarkskin;
begin
  Magic.ResolveSpell(GDVars.currentSpellIndex, 0, 0, 0, 0,
                     GDConsts.isText + GDConsts.effectNames[C_Effect.BARKSKIN])
end;

procedure SpellCureLightWounds;
var bonus: Byte;
begin
  if GDVars.spellTargetState.count = 0 then Exit;
  if GDVars.currentCharacter^.deity = 4 then
    bonus := FxEngine.RollDice(1, 8)
  else bonus := 0;
  if FxEngine.RestoreHitPoints(GDVars.spellTargetState.targets[1], bonus + FxEngine.RollDice(1, 8), False) then
    CharHlp.AnnounceHealStatus(GDVars.spellTargetState.targets[1])
end;

procedure SpellCharmPersonOrMammal;
var
  found: Pointer;
  target: Pointer;
begin
  target := GDVars.spellTargetState.targets[1];
  if target <> nil then begin
    if (Types.PCharacter(target)^.race < C_Race.MONSTER) or
        ((Types.PCharacter(target)^.typeFlags and $10) <> 0) then begin
      Magic.ResolveSpell(GDVars.currentSpellIndex,
                         CharHlp.GetCasterLevel(GDVars.currentSpellIndex) +
                         GDVars.currentCharacter^.side * 128, 1, 0, 0,
                         GDConsts.isText + GDConsts.effectNames[C_Effect.CHARM]);
      if CharHlp.HasEffect(target, C_Effect.CHARM, found) then
        FxEngine.CallEffectHandler(C_Effect.CHARM, target, found, False)
    end else
      CharHlp.PrintCreatureMessage(target, GDConsts.isText + GDConsts.notText + GDConsts.effectNames[C_Effect.CHARM],
                                   10, True)
  end
end;

procedure SpellDetection;
begin
  Magic.ResolveSpell(GDVars.currentSpellIndex, 0, 0, 0, 0, GDConsts.isAffectedText)
end;

procedure SpellProtection;
begin
  Magic.ResolveSpell(GDVars.currentSpellIndex, 0, 0, 0, 0, GDConsts.isProtectedText)
end;

procedure SpellResurrection;
var target: Pointer;
begin
  target := GDVars.spellTargetState.targets[1];
  if (Types.PCharacter(target)^.status = C_Status.DEAD_STATUS) and
      (Types.PCharacter(target)^.stats[C_Stat.CONSTITUTION].base > 0) and
      (Types.PCharacter(target)^.race > C_Race.QUALINESTI_ELF) then begin
    FxEngine.RemoveEffect(target, C_Effect.POISONED, nil);
    Types.PCharacter(target)^.status := C_Status.OKAY;
    Types.PCharacter(target)^.enabled := 1;
    Types.PCharacter(target)^.hitPoints := Types.PCharacter(target)^.maxHitPoints;
    CharHlp.PrintCreatureMessage(target, GDConsts.resurrectedText, 10, True)
  end
end;

procedure SpellResistCold;
begin
  Magic.ResolveSpell(GDVars.currentSpellIndex, 0, 0, 0, 0, GDConsts.coldResistantText)
end;

procedure SpellBurningHands;
begin
  Magic.ResolveSpell(GDVars.currentSpellIndex, 0, 0, CharHlp.GetCasterLevel(GDVars.currentSpellIndex), $09, '')
end;

procedure SpellCharmPerson;
var
  found: Pointer;
  target: Pointer;
begin
  target := GDVars.spellTargetState.targets[1];
  if target <> nil then begin
    if ((Types.PCharacter(target)^.race = C_Race.MONSTER) and
        ((Types.PCharacter(target)^.typeFlags and $02) = 0)) or
        (Types.PCharacter(target)^.iconDimensions > 1) then
      CharHlp.PrintCreatureMessage(target, GDConsts.unaffectedMessage, 10, True)
    else begin
      Magic.ResolveSpell(GDVars.currentSpellIndex,
                         CharHlp.GetCasterLevel(GDVars.currentSpellIndex) +
                         GDVars.currentCharacter^.side * 128, 1, 0, 0, GDConsts.charmedText);
      if CharHlp.HasEffect(target, C_Effect.CHARM, found) then
        FxEngine.CallEffectHandler(C_Effect.CHARM, target, found, False)
    end
  end
end;

procedure SpellEnlarge;
var result: Byte;
    character: Pointer;
begin
  character := GDVars.spellTargetState.targets[1];
  GDVars.spellBudget := 18;
  GDVars.spellCost := 0;
  case CharHlp.GetCasterLevel(GDVars.currentSpellIndex) of
    1: GDVars.spellCost := 0;
    2: GDVars.spellCost := 1;
    3: GDVars.spellCost := 51;
    4: GDVars.spellCost := 76;
    5: GDVars.spellCost := 91;
    6: GDVars.spellCost := 100;
    7: GDVars.spellBudget := 19;
    8: GDVars.spellBudget := 20;
    9: GDVars.spellBudget := 21
  else
    GDVars.spellBudget := 22
  end;
  if FxEngine.AdjustForNewStrength(character, GDVars.spellBudget, GDVars.spellCost, result) then begin
    CharHlp.PrintCreatureMessage(character, GDConsts.strongerText, 10, True);
    FxEngine.AddEffect(character, C_Effect.ENLARGE, Magic.CalcSpellDuration(GDVars.currentSpellIndex), result, True);
    FxEngine.RecalcAbility(character, C_Stat.STRENGTH)
  end else
    CharHlp.PrintCreatureMessage(character, GDConsts.unaffectedMessage, 10, True)
end;

procedure SpellReduce;
var
  found: Pointer;
  target: Pointer;
begin
  target := GDVars.spellTargetState.targets[1];
  if (target <> nil) and (GDVars.spellTargetState.count > 0) and not FxEngine.RollSavingThrow(target, 4, 0) and
      CharHlp.HasEffect(target, C_Effect.ENLARGE, found) then begin
    FxEngine.RemoveEffect(target, C_Effect.ENLARGE, nil);
    FxEngine.RecalcAbility(target, C_Stat.STRENGTH);
    CharHlp.PrintCreatureMessage(target, GDConsts.reducedText, 10, True)
  end
end;

procedure SpellFriends;
var
  { Unused in this version; see the other implementations of this routine. }
  oldCharisma: Byte;
begin
  Magic.ResolveSpell(GDVars.currentSpellIndex, FxEngine.RollDice(2, 4), 1, 0, 0, GDConsts.friendlyText);
  FxEngine.RecalcAbility(GDVars.currentCharacter, C_Stat.CHARISMA)
end;

procedure SpellMagicMissile;
var value: Byte;
begin
  value := CharHlp.GetCasterLevel(GDVars.currentSpellIndex) + 1;
  Magic.ResolveSpell(GDVars.currentSpellIndex, 0, 0, FxEngine.RollDamageDice(value div 2, 4) + (value div 2), $08, '')
end;

procedure SpellRestoration;
var
  bestIndex: ShortInt;
  index: ShortInt;
  bestValue: LongInt;
  character: Pointer;
  modeClass: ShortInt;
  difference: Byte;
  share: Byte;
  anyModes: Byte;
  reduction: Byte;
  activeCount: Byte;
begin
  anyModes := 0;
  character := GDVars.spellTargetState.targets[1];
  bestIndex := 17;
  bestValue := GDConsts.classProgression[5].experience[14];
  activeCount := 0;
  for index := 0 to 7 do
    if Types.PCharacter(character)^.oldLevels[index] > 0 then
      Inc(activeCount);
  for index := 0 to 7 do begin
    if Types.PCharacter(character)^.classLevels[index] < Types.PCharacter(character)^.oldLevels[index] then begin
      difference := Byte(Types.PCharacter(character)^.oldLevels[index]) -
          Byte(Types.PCharacter(character)^.classLevels[index]);
      Inc(anyModes, difference);
      modeClass := CharHlp.ClassSuborderIndex(character, index);
      if GDConsts.classProgression[modeClass].experience[Succ(Types.PCharacter(character)^.classLevels[index])] <=
          bestValue then begin
        bestValue :=
          GDConsts.classProgression[modeClass].experience[Succ(Types.PCharacter(character)^.classLevels[index])];
        bestIndex := index
      end
    end
  end;
  if bestIndex <> 17 then begin
    if Types.PCharacter(character)^.maxHitPoints < Types.PCharacter(character)^.oldMaxHitPoints then begin
      share := (Types.PCharacter(character)^.oldMaxHitPoints - Types.PCharacter(character)^.maxHitPoints) div
        anyModes;
      if Byte(Types.PCharacter(character)^.classLevels[bestIndex]) + 1 < GDConsts.firstFixedHpLevel[bestIndex] then
        reduction := CharHlp.ClassConAdj(character, bestIndex) div activeCount
      else
        reduction := 0;
      Inc(Types.PCharacter(character)^.hitPoints, share);
      Inc(Types.PCharacter(character)^.baseMaxHitPoints, share - reduction);
      Inc(Types.PCharacter(character)^.maxHitPoints, share)
    end;
    Types.PCharacter(character)^.classLevels[bestIndex] :=
      Succ(Types.PCharacter(character)^.classLevels[bestIndex]);
    ClassCal.RecalcClassStats(Types.PCharacter(character));
    if (anyModes = 1) and
        (Types.PCharacter(character)^.experience < Types.PCharacter(character)^.oldExperience) then
      Types.PCharacter(character)^.experience := Types.PCharacter(character)^.oldExperience
    else
      Types.PCharacter(character)^.experience := bestValue
  end;
  Types.PCharacter(character)^.levelUpReady := Ord(CharHlp.CanLevelUp(character))
end;

procedure SpellShield;
begin
  Magic.ResolveSpell(GDVars.currentSpellIndex, 0, 0, 0, 0, GDConsts.shieldedText)
end;

procedure SpellShockingGrasp;
begin
  Magic.ResolveSpell(GDVars.currentSpellIndex, 0, 0,
             FxEngine.RollDamageDice(1, 8) + CharHlp.GetCasterLevel(GDVars.currentSpellIndex), $0C, '')
end;

procedure SpellSleep;
var index: Byte;
    found: Pointer;
begin
  GDVars.areaSpellActive := 1;
  GDVars.spellBudget := FxEngine.RollDice(4, 4);
  for index := 1 to GDVars.spellTargetState.count do begin
    case GDVars.spellTargetState.targets[index]^.levelHighest of
      0..1: GDVars.spellCost := 1;
      2: GDVars.spellCost := 2;
      3: GDVars.spellCost := 4;
      4: GDVars.spellCost := 6;
      5: if GDVars.spellTargetState.targets[index]^.race = C_Race.MONSTER then
          GDVars.spellCost := 10
        else
          GDVars.spellCost := 20
    else
      GDVars.spellCost := 20
    end;
    if (GDVars.spellTargetState.targets[index]^.status <> C_Status.ANIMATED) and
        not CharHlp.HasEffect(GDVars.spellTargetState.targets[index], C_Effect.SLEEP, found) and
        (GDVars.spellBudget >= GDVars.spellCost) then
      Dec(GDVars.spellBudget, GDVars.spellCost)
    else
      GDVars.spellTargetState.targets[index] := nil
  end;
  Magic.ResolveSpell(GDVars.currentSpellIndex, 0, 0, 0, 0, GDConsts.fallsAsleepText)
end;

procedure SpellHold;
var value: Byte;
begin
  case GDVars.spellTargetState.count of
    1: if GDVars.currentSpellIndex = C_Spell.HOLD_PERSON_CLERIC then value := 254 else value := 253;
    2: value := 255;
    3, 4: value := 0
  end;
  Magic.ApplyEffectToTargets(value, GDConsts.heldText)
end;

procedure SpellResistFire;
begin
  Magic.ResolveSpell(GDVars.currentSpellIndex, 0, 0, 0, 0, GDConsts.fireResistantText)
end;

procedure SpellSilence;
begin
  Magic.ResolveSpell(GDVars.currentSpellIndex, 0, 0, 0, 0, GDConsts.silencedText)
end;

procedure SpellSlowPoison;
var found: Pointer;
    character: Pointer;
begin
  character := GDVars.spellTargetState.targets[1];
  if Types.PCharacter(character)^.status = C_Status.ANIMATED then
    GDVars.spellTargetState.targets[1] := nil
  else if CharHlp.HasEffect(character, C_Effect.POISONED, found) then begin
    if Types.PCharacter(character)^.hitPoints = 0 then
      Types.PCharacter(character)^.hitPoints := 1;
    Types.PCharacter(character)^.status := C_Status.OKAY;
    Types.PCharacter(character)^.enabled := 1;
    Magic.ResolveSpell(GDVars.currentSpellIndex, 255, 1, 0, 0, GDConsts.isAffectedText);
    FxEngine.AddEffect(character, C_Effect.SLOW_POISON_HIT, 10, 255, True)
  end
end;

procedure SpellSnakeCharm;
begin
end;

procedure SpellSpiritualHammer;
begin
  Magic.ResolveSpell(GDVars.currentSpellIndex, 0, 1, 0, 0, '');
  FxEngine.CallEffectHandler(C_Effect.SPIRITUAL_HAMMER, GDVars.spellTargetState.targets[1], nil, False)
end;

procedure SpellInvisibility;
begin
  Magic.ResolveSpell(GDVars.currentSpellIndex, 0, 0, 0, 0, GDConsts.invisibleText)
end;

procedure SpellKnock;
begin
  Magic.ResolveSpell(GDVars.currentSpellIndex, 0, 0, 0, 0, '')
end;

procedure SpellMirrorImage;
var value: Byte;
begin
  value := FxEngine.RollDice(1, 4) shl 4;
  value := value or CharHlp.GetCasterLevel(GDVars.currentSpellIndex);
  Magic.ResolveSpell(GDVars.currentSpellIndex, value, 0, 0, 0, GDConsts.duplicatedText)
end;

procedure SpellRayOfEnfeeblement;
begin
  Magic.ResolveSpell(GDVars.currentSpellIndex, 0, 0, 0, 0, GDConsts.weakenedText)
end;

procedure SpellStinkingCloud;
var
  cellX: Integer;
  cellY: Integer;
  node: Types.PCloudNode;
  direction: Byte;
  count: Byte;
  cell: Byte;
  scan: Byte;
  index: Byte;
  neighbor: Byte;
  candidates: array[1..9] of Byte;
begin
  FillChar(candidates, SizeOf(candidates), 0);
  New(node);
  FillChar(node^, SizeOf(Types.TCloudNode), 0);
  with node^ do begin
    x := GDVars.targetX;
    y := GDVars.targetY;
    caster := GDVars.currentCharacter;
    casterLevel := CharHlp.GetCasterLevel(GDVars.currentSpellIndex);
    countdown := casterLevel;
    if GDVars.currentSpellIndex = C_Spell.STINKING_CLOUD then begin
      count := 4;
      terrain := C_Terr.TERRAIN_STINKING_CLOUD
    end else begin
      count := 9;
      terrain := C_Terr.TERRAIN_CLOUDKILL
    end;
    for index := 1 to count do begin
      direction := GDConsts.patchDir[index];
      cellX := x + GDConsts.directionX[direction];
      cellY := y + GDConsts.directionY[direction];
      if (cellX >= 0) and (cellX <= 49) and (cellY >= 0) and (cellY <= 24) then begin
        CbtMap.GetArenaContents(cellX, cellY, neighbor, cell);
        for scan := 1 to index - 1 do
          if candidates[scan] = neighbor then neighbor := 0;
        candidates[index] := neighbor;
        cell := CbtMap.ResolveTerrain(cellX, cellY);
        covered[index] := Ord((cell > 0) and (GDConsts.terrain[cell].cost < C_Terr.TERRAIN_IMPASSABLE));
        under[index] := cell;
        if covered[index] <> 0 then
          GDVars.arena^.cells[cellY, cellX] := terrain
      end else
        covered[index] := 0
    end
  end;
  node^.next := GDVars.cloudList;
  GDVars.cloudList := node;
  CbtMap.ScrollView(GDVars.targetX, GDVars.targetY, 255, C_Dir.CENTER);
  for index := 1 to count do
    if candidates[index] > 0 then
      FxEngine.ConsiderTerrainEffects(GDVars.creatures[candidates[index]], 1)
end;

procedure SpellStrength;
var character: Pointer;
    percentage: Byte;
    bonus: Byte;
    value: Byte;
    result: Byte;
begin
  percentage := 0;
  character := GDVars.spellTargetState.targets[1];
  if Types.PCharacter(character)^.classLevels[C_Class.MAGE] > 0 then
    bonus := FxEngine.RollDice(1, 4);
  if (Types.PCharacter(character)^.classLevels[C_Class.CLERIC] > 0) or
      (Types.PCharacter(character)^.classLevels[C_Class.THIEF] > 0) then
    bonus := FxEngine.RollDice(1, 6);
  if (Types.PCharacter(character)^.classLevels[C_Class.FIGHTER] > 0) or
      (Types.PCharacter(character)^.classLevels[C_Class.RANGER] > 0) or
      (Types.PCharacter(character)^.classLevels[C_Class.KNIGHT] > 0) or
      (Types.PCharacter(character)^.classLevels[C_Class.PALADIN] > 0) then
    bonus := FxEngine.RollDice(1, 8);
  value := Types.PCharacter(character)^.stats[C_Stat.STRENGTH].current + bonus;
  if value > 18 then begin
    if (Types.PCharacter(character)^.classLevels[C_Class.FIGHTER] > 0) or
        (Types.PCharacter(character)^.classLevels[C_Class.RANGER] > 0) or
        (Types.PCharacter(character)^.classLevels[C_Class.KNIGHT] > 0) or
        (Types.PCharacter(character)^.classLevels[C_Class.PALADIN] > 0) then begin
      percentage := Types.PCharacter(character)^.exceptionalStrength + (value - 18) * 10;
      if percentage > 100 then percentage := 100;
      value := 18
    end else value := 18
  end;
  if FxEngine.AdjustForNewStrength(character, value, percentage, result) then begin
    result := bonus + 100;
    FxEngine.AddEffect(character, C_Effect.STRENGTH, Magic.CalcSpellDuration(GDVars.currentSpellIndex), result, True);
    FxEngine.RecalcAbility(character, C_Stat.STRENGTH)
  end
end;

procedure SpellNoEffect;
begin
end;

procedure SpellCureBlindness;
begin
  if FxEngine.RemoveEffectWithMessage(GDVars.spellTargetState.targets[1], C_Effect.BLIND) then
    CharHlp.PrintNameStringAnim(GDVars.spellTargetState.targets[1], True, GDConsts.canSeeText)
end;

procedure SpellCauseBlindness;
begin
  Magic.ResolveSpell(GDVars.currentSpellIndex, 0, 0, 0, 0, GDConsts.blindText)
end;

{ Cure disease's test: no disease exists in the game.
  @returns(0.) }
function CuredDisease: Byte;
begin
  CuredDisease := 0
end;

procedure SpellCureDisease;
var
  { Unused in this version; see the other implementations of this routine. }
  result: Byte;
begin
  result := Magic.CuredDisease
end;

procedure SpellHarm;
var character: Pointer;
begin
  character := GDVars.spellTargetState.targets[1];
  GDVars.elementMask := $08;
  FxEngine.InflictNonWeaponDamage(character, Types.PCharacter(character)^.hitPoints - FxEngine.RollDice(1, 4),
                                  0, False)
end;

procedure SpellDispelMagic;
var
  index: Byte;
  roll: Byte;
  character: Pointer;
  flags: TDispelLocals;
  link: Types.PEffect;
  next: Types.PEffect;
  x: ShortInt;
  y: ShortInt;
  cell: Byte;
  count: Byte;
  traversal: Types.PCloudNode;

  { Rolls whether a cloud cast at a given level is dispelled. }
  function CloudDispelled(value: Byte): Boolean;
  begin
    if roll > value then
      GDVars.spellBudget := (roll - value) * 5 + 50
    else if roll < value then
      GDVars.spellBudget := 50 - (GDVars.spellCost - roll) * 2
    else
      GDVars.spellBudget := 50;
    CloudDispelled := FxEngine.RollDice(1, 100) <= GDVars.spellBudget
  end;
begin
  GDVars.areaSpellActive := 1;
  roll := CharHlp.GetCasterLevel(GDVars.currentSpellIndex);
  for index := 1 to GDVars.spellTargetState.count do begin
    flags.removed := 0;
    character := GDVars.spellTargetState.targets[1];
    link := Types.PCharacter(character)^.effects;
    while link <> nil do begin
      next := link^.next;
      if link^.strength < 255 then begin
        GDVars.spellCost := link^.strength and $0F;
        if roll > GDVars.spellCost then
          GDVars.spellBudget := (roll - GDVars.spellCost) * 5 + 50
        else if roll < GDVars.spellCost then
          GDVars.spellBudget := 50 - (GDVars.spellCost - roll) * 2
        else
          GDVars.spellBudget := 50;
        if FxEngine.RollDice(1, 100) <= GDVars.spellBudget then begin
          FxEngine.RemoveEffect(character, link^.effectId, link);
          flags.removed := 1
        end
      end;
      link := next
    end;
    if flags.removed <> 0 then
      CharHlp.PrintNameStringAnim(character, True, GDConsts.isAffectedText)
  end;
  for GDVars.loopIndex := 0 to 8 do begin
    x := ShortInt(GDVars.targetX) + GDConsts.directionX[GDVars.loopIndex];
    y := ShortInt(GDVars.targetY) + GDConsts.directionY[GDVars.loopIndex];
    CbtMap.GetArenaContents(x, y, count, cell);
    if (cell = C_Terr.TERRAIN_STINKING_CLOUD) or (cell = C_Terr.TERRAIN_CLOUDKILL) then begin
      traversal := GDVars.cloudList;
      if cell = C_Terr.TERRAIN_STINKING_CLOUD then count := 4 else count := 9;
      while traversal <> nil do begin
        for index := 1 to count do
          if (x = traversal^.x + GDConsts.directionX[GDConsts.patchDir[index]]) and
              (y = traversal^.y + GDConsts.directionY[GDConsts.patchDir[index]]) and
              CloudDispelled(traversal^.casterLevel) then
            traversal^.countdown := -1;
        traversal := traversal^.next
      end;
      CbtMap.ScrollView(GDVars.targetX, GDVars.targetY, 3, C_Dir.CENTER)
    end
  end;
  FxEngine.CountDownAreaEffects(True)
end;

procedure SpellPrayer;
begin
  Magic.ResolveSpell(GDVars.currentSpellIndex,
                     CharHlp.GetCasterLevel(GDVars.currentSpellIndex) +
                     GDVars.currentCharacter^.side * 16, 0, 0, 0, GDConsts.prayingText)
end;

procedure SpellRemoveCurse;
var link: Types.PItem;
    found: Byte;
    index: Byte;
begin
  if FxEngine.RemoveEffectWithMessage(GDVars.spellTargetState.targets[1], 43) then
    CharHlp.PrintNameStringAnim(GDVars.spellTargetState.targets[1], True, GDConsts.uncursedText)
  else begin
    found := 0;
    link := GDVars.spellTargetState.targets[1]^.items;
    while (link <> nil) and (found = 0) do begin
      if link^.cursed <> 0 then begin
        found := 1;
        link^.equipped := 0;
        if link^.special > $7F then begin
          GDVars.handlerOverrideActive := 1;
          FxEngine.CallEffectHandler(link^.special, GDVars.spellTargetState.targets[1], link, True);
          for index := 0 to 5 do
            FxEngine.RecalcAbility(GDVars.spellTargetState.targets[1], index)
        end
      end;
      link := link^.next
    end;
    if found <> 0 then
      CharHlp.PrintNameStringAnim(GDVars.spellTargetState.targets[1], True, GDConsts.itemUncursedText)
  end
end;

procedure SpellBestowCurse;
begin
  Magic.ResolveSpell(GDVars.currentSpellIndex, 0, 0, 0, 0, GDConsts.cursedText)
end;

procedure SpellBlink;
begin
  Magic.ResolveSpell(GDVars.currentSpellIndex, 0, 0, 0, 0, GDConsts.blinkingText)
end;

procedure SpellFireball;
var
  value: Byte;
  other: Byte;
  index: Byte;
begin
  GDVars.areaSpellActive := 1;
  if GDVars.currentSpellIndex = 64 then
    value := FxEngine.RollDice(1, 3) * 2 + 1
  else
    value := CharHlp.GetCasterLevel(GDVars.currentSpellIndex);
  if GDVars.zone0^.inDungeon = 0 then begin
    Pathing.BuildTargetList(GDVars.targetX, GDVars.targetY, 2, GDConsts.anyDirection, 1, GDVars.arena);
    for index := 1 to GDVars.targetCount do
      GDVars.spellTargetState.targets[index] := GDVars.creatures[GDVars.targetList[index].characterIndex];
    GDVars.spellTargetState.count := GDVars.targetCount
  end;
  CbtMap.ScrollView(GDVars.targetX, GDVars.targetY, 0, C_Dir.CENTER);
  if GDVars.currentSpellIndex = C_Spell.DELAY_BLAST_FIREBALL then other := value else other := 0;
  Magic.ResolveSpell(GDVars.currentSpellIndex, 0, 0, FxEngine.RollDamageDice(value, 6) + other, $09, '')
end;

procedure HasteSlowLogic(counterEffect, side: Byte; message: Types.TString40);
var local: TCounterLocals;
begin
  GDVars.areaSpellActive := 1;
  local.countersLeft := CharHlp.GetCasterLevel(GDVars.currentSpellIndex);
  for local.index := 1 to GDVars.spellTargetState.count do
    if (Byte(GDVars.spellTargetState.targets[local.index]^.side) = side) and
        (local.countersLeft > 0) then begin
      Dec(local.countersLeft);
      if FxEngine.RemoveEffectWithMessage(GDVars.spellTargetState.targets[local.index], counterEffect) then
        GDVars.spellTargetState.targets[local.index] := nil
    end else
      GDVars.spellTargetState.targets[local.index] := nil;
  Magic.ResolveSpell(GDVars.currentSpellIndex, 0, 0, 0, 0, message);
  for local.index := 1 to GDVars.spellTargetState.count do
    if GDVars.spellTargetState.targets[local.index] <> nil then
      FxEngine.TriggerEffectsWithCondition(C_Cond.MOVE_ATTACK_RATE, GDVars.spellTargetState.targets[local.index])
end;

procedure SpellHaste;
begin
  Magic.HasteSlowLogic(C_Effect.SLOWED, GDVars.currentCharacter^.side, GDConsts.hastedText)
end;

{ One cell of a bolt: strikes the creature there (other than skipCreature), halved on a save, and notes a dungeon wall
  to rebound from.
  @param(x Column.)
  @param(y Row.)
  @param(damage Damage dealt.)
  @param(saveType The saving throw.)
  @param(skipCreature Creature index the bolt has just struck.)
  @param(bounced In: whether the bolt has rebounded. Out: set when it rebounds here.) }
procedure LightningAttackAt(x, y, damage, saveType, skipCreature: Byte; var bounced: Byte);
var local: TBoltCellLocals;
begin
  CbtMap.GetArenaContents(x, y, local.neighbor, local.cell);
  if (local.cell > 0) and (GDConsts.terrain[local.cell].cost = C_Terr.TERRAIN_IMPASSABLE) and
      (GDVars.zone0^.inDungeon = 1) and (bounced = 0) then
    bounced := 1
  else
    bounced := 0;
  if (local.neighbor > 0) and (local.neighbor <> skipCreature) then begin
    local.current := GDVars.creatures[local.neighbor];
    FxEngine.InflictNonWeaponDamage(local.current, damage, 2, FxEngine.RollSavingThrow(local.current, saveType, 0));
    CharHlp.BuildIconFacings(19)
  end
end;

{ Lightning Bolt and the lightning breath: the bolt runs from the target cell away from the caster for its range,
  rebounding off walls, striking each creature it passes.
  @param(range Length, in cells.)
  @param(damage Damage dealt.)
  @param(saveType The saving throw.)
  @param(doubleOnRebound Non-zero to double the length once after a near rebound.) }
procedure LightningPath(range, damage, saveType, doubleOnRebound: Byte);
var local: TBoltLocals;
begin
  local.accepted := 0;
  CharHlp.BuildIconFacings(19);
  CbtMap.GetArenaContents(GDVars.targetX, GDVars.targetY, local.prior, local.cell);
  local.used := 0;
  local.sign := 1;
  local.originX := CbtMap.CombatCellX(GDVars.currentCharacter);
  local.originY := CbtMap.CombatCellY(GDVars.currentCharacter);
  local.useRange := doubleOnRebound;
  if (local.originX = ShortInt(GDVars.targetX)) and (local.originY = ShortInt(GDVars.targetY)) then Exit;
  local.remaining := range * 2;
  GDVars.areaSpellActive := 1;
  while local.remaining > 0 do begin
    FillChar(local.path, SizeOf(local.path), 0);
    local.path.sx := ShortInt(GDVars.targetX);
    local.path.sy := ShortInt(GDVars.targetY);
    local.path.ex := (ShortInt(GDVars.targetX) - local.originX) * local.sign * local.remaining +
      ShortInt(GDVars.targetX);
    local.path.ey := (ShortInt(GDVars.targetY) - local.originY) * local.sign * local.remaining +
      ShortInt(GDVars.targetY);
    Pathing.PathFind(local.path);
    repeat
      local.savedX := local.path.cx;
      local.savedY := local.path.cy;
      if (local.path.sx <> local.path.ex) or (local.path.sy <> local.path.ey) then begin
        repeat
          local.stepped := Ord(Pathing.NextPathStep(local.path));
          CbtMap.GetArenaContents(local.path.cx, local.path.cy, local.neighbor, local.cell);
          if (local.cell = 0) or (GDConsts.terrain[local.cell].cost = 1) then
            local.accepted := 0
        until (local.stepped = 0) or ((local.neighbor > 0) and (local.neighbor <> local.prior)) or (local.cell = 0) or
            (GDConsts.terrain[local.cell].cost > 1) or (local.path.dist >= local.remaining)
      end;
      if local.cell = 0 then local.remaining := 0;
      CharHlp.CombatAnimateMovingIcon(local.savedX, local.savedY, local.path.cx, local.path.cy, 4, 50);
      Magic.LightningAttackAt(local.path.cx, local.path.cy, damage, saveType, local.prior, local.accepted);
      local.prior := local.neighbor;
      if local.accepted <> 0 then begin
        GDVars.targetX := local.path.cx;
        GDVars.targetY := local.path.cy;
        FillChar(local.returnPath, SizeOf(local.returnPath), 0);
        local.returnPath.sx := ShortInt(GDVars.targetX);
        local.returnPath.sy := ShortInt(GDVars.targetY);
        local.returnPath.ex := local.originX;
        local.returnPath.ey := local.originY;
        Pathing.PathFind(local.returnPath);
        while Pathing.NextPathStep(local.returnPath) do;
        if (local.useRange <> 0) and (local.returnPath.dist <= 8) then
          local.path.dist := local.path.dist * 2;
        local.sign := 0 - local.sign;
        local.useRange := 0;
        local.prior := 0
      end;
      local.used := local.path.dist - local.used;
      if local.used < 2 then local.used := 2;
      if local.remaining > local.used then
        Dec(local.remaining, local.used)
      else
        local.remaining := 0;
      local.used := local.path.dist
    until (local.accepted <> 0) or (local.remaining = 0)
  end;
  GDVars.areaSpellActive := 0
end;

procedure SpellLightningBolt;
var
  value: Byte;
  result: Byte;
begin
  value := FxEngine.RollDamageDice(CharHlp.GetCasterLevel(GDVars.currentSpellIndex), 6);
  GDVars.elementMask := $0C;
  Magic.LightningAttackAt(GDVars.targetX, GDVars.targetY, value, 4, 0, result);
  Magic.LightningPath(7, value, 4, 1)
end;

procedure SpellHeal;
var target: Pointer;
    value: Byte;
begin
  target := GDVars.spellTargetState.targets[1];
  if Magic.CuredDisease <> 0 then
    CharHlp.PrintCreatureMessage(target, GDConsts.isCuredText, 10, False);
  if FxEngine.RemoveEffectWithMessage(target, C_Effect.BLIND) then
    CharHlp.PrintCreatureMessage(target, GDConsts.canSeeText, 10, False);
  if FxEngine.RemoveEffectWithMessage(target, C_Effect.FEEBLEMINDED) then begin
    CharHlp.PrintCreatureMessage(target, GDConsts.regainsIntellectText, 10, False);
    FxEngine.RecalcAbility(target, C_Stat.INTELLIGENCE);
    FxEngine.RecalcAbility(target, C_Stat.WISDOM)
  end;
  value := FxEngine.RollDice(1, 4);
  if Types.PCharacter(target)^.hitPoints + value > Types.PCharacter(target)^.maxHitPoints then
    value := 0
  else
    value := Types.PCharacter(target)^.maxHitPoints - Types.PCharacter(target)^.hitPoints - value;
  if FxEngine.RestoreHitPoints(target, value, False) then
    CharHlp.PrintCreatureMessage(target, GDConsts.healedMessage, 10, False)
end;

procedure SpellSlow;
begin
  Magic.HasteSlowLogic(C_Effect.HASTED, Byte(CharHlp.EnemyTeam(GDVars.currentCharacter)), GDConsts.slowedText)
end;

procedure SpellDeathSpell;
var current: Pointer;
    index: Byte;
begin
  GDVars.areaSpellActive := 1;
  GDVars.elementMask := $40;
  GDVars.spellBudget := FxEngine.RollDice(4, 20) * 2;
  for index := 1 to GDVars.spellTargetState.count do begin
    current := GDVars.spellTargetState.targets[index];
    case Types.PCharacter(current)^.levelHighest of
      0: GDVars.spellCost := 1;
      1: GDVars.spellCost := 2;
      2..3: GDVars.spellCost := 8;
      4..5: GDVars.spellCost := 16;
      6: if Types.PCharacter(current)^.maxHitPoints <= 51 then
          GDVars.spellCost := 16
        else
          GDVars.spellCost := 20;
      7..8: GDVars.spellCost := 20
    else
      GDVars.spellCost := 162
    end;
    if ((Types.PCharacter(current)^.immunityFlags and $08) = 0) and (GDVars.spellBudget >= GDVars.spellCost) then begin
      Dec(GDVars.spellBudget, GDVars.spellCost);
      FxEngine.KillCreature(current, C_Status.DEAD_STATUS, GDConsts.dropsDeadText)
    end else
      GDVars.spellTargetState.targets[index] := nil
  end
end;

procedure SpellPotionOfSpeed;
begin
  if not FxEngine.RemoveEffectWithMessage(GDVars.spellTargetState.targets[1], C_Effect.SLOWED) then
    Magic.ResolveSpell(GDVars.currentSpellIndex, 0, 0, 0, 0, GDConsts.hastedText)
end;

procedure SpellCureSeriousWounds;
var bonus: Byte;
begin
  if GDVars.spellTargetState.count = 0 then Exit;
  if GDVars.currentCharacter^.deity = 4 then
    bonus := FxEngine.RollDice(1, 8)
  else bonus := 0;
  if FxEngine.RestoreHitPoints(GDVars.spellTargetState.targets[1], bonus + (FxEngine.RollDice(2, 8) + 1),
                               False) then
    CharHlp.AnnounceHealStatus(GDVars.spellTargetState.targets[1])
end;

procedure SpellGiantStrength;
var result: Byte;
begin
  if FxEngine.AdjustForNewStrength(GDVars.spellTargetState.targets[1], 21, 0, result) then
    CharHlp.PrintCreatureMessage(GDVars.spellTargetState.targets[1], GDConsts.strongerText, 10, True);
  FxEngine.AddEffect(GDVars.spellTargetState.targets[1], C_Effect.FROST_GIANT_STRENGTH,
                     FxEngine.RollDice(1, 4) * 10 + 40, result, True);
  FxEngine.RecalcAbility(GDVars.spellTargetState.targets[1], C_Stat.STRENGTH)
end;

procedure SpellDisintegrate;
var result: Boolean;
    character: Pointer;
begin
  GDVars.elementMask := $40;
  character := GDVars.spellTargetState.targets[1];
  GDVars.currentDamage := 255;
  FxEngine.TriggerEffectsWithCondition(C_Cond.EFFECT_ADDED, character);
  if GDVars.currentDamage <> 0 then begin
    result := FxEngine.RollSavingThrow(character, 4, 0);
    if not result then
      FxEngine.KillCreature(character, C_Status.DEAD_STATUS, GDConsts.disintegratesText)
  end
end;

procedure SpellWandOfParalyzation;
begin
  Magic.ResolveSpell(GDVars.currentSpellIndex, 0, 0, 0, 0, GDConsts.paralyzedText)
end;

procedure SpellPotionOfHealing;
begin
  if FxEngine.RestoreHitPoints(GDVars.spellTargetState.targets[1], FxEngine.RollDice(2, 4) + 2, False) then
    CharHlp.PrintNameStringAnim(GDVars.spellTargetState.targets[1], True, GDConsts.healedMessage)
end;

procedure SpellGlobeOfInvulnerability;
begin
  Magic.ResolveSpell(GDVars.currentSpellIndex, 0, 0, 0, 0, GDConsts.isProtectedText)
end;

procedure SpellWandOfMagicMissiles;
begin
  Magic.ResolveSpell(GDVars.currentSpellIndex, 0, 0, FxEngine.RollDamageDice(2, 4) + 2, $08, '')
end;

procedure SpellStoneToFlesh;
var target: Pointer;
    local: TStoneToFleshLocals;
begin
  target := GDVars.spellTargetState.targets[1];
  if Types.PCharacter(target)^.status = C_Status.STONED then begin
    Types.PCharacter(target)^.status := C_Status.OKAY;
    Types.PCharacter(target)^.enabled := 1;
    Types.PCharacter(target)^.hitPoints := 1;
    CharHlp.PrintCreatureMessage(target, GDConsts.noLongerStatusText, 10, False);
    if GDVars.interfaceState = C_Ifc.IN_COMBAT then begin
      local.index := 1;
      while GDVars.downed[local.index].cr <> target do Inc(local.index);
      GDVars.arena^.cells[GDVars.downed[local.index].y,
                                     GDVars.downed[local.index].x] := GDVars.downed[local.index].terrain;
      for local.scan := local.index to GDVars.downedCount - 1 do
        GDVars.downed[local.scan] := GDVars.downed[local.scan + 1];
      Dec(GDVars.downedCount);
      if CbtMap.IsValidCreatureLoc(target, CbtMap.CombatCellX(target), CbtMap.CombatCellY(target), Boolean(1)) then
        CbtMap.ScrollView(GDVars.targetX, GDVars.targetY, 0, C_Dir.CENTER)
    end
  end else if GDVars.interfaceState = C_Ifc.CAMPING then begin
  end;
  Magic.ResolveSpell(GDVars.currentSpellIndex, 0, 0, 0, 0, '')
end;

procedure SpellNeutralizePoison;
var
  target: Pointer;
  found: Pointer;
begin
  target := GDVars.spellTargetState.targets[1];
  if Types.PCharacter(target)^.status = C_Status.ANIMATED then
    GDVars.spellTargetState.targets[1] := nil
  else if CharHlp.HasEffect(target, C_Effect.POISONED, found) then begin
    if Types.PCharacter(target)^.hitPoints = 0 then
      Types.PCharacter(target)^.hitPoints := 1;
    GDVars.effectLock := 1;
    FxEngine.RemoveEffect(target, C_Effect.POISONED, nil);
    FxEngine.RemoveEffect(target, C_Effect.SLOW_POISON_END, nil);
    FxEngine.RemoveEffect(target, C_Effect.SLOW_POISON_HIT, nil);
    GDVars.effectLock := 0;
    CharHlp.PrintCreatureMessage(target, GDConsts.unpoisonedText, 10, True);
    Types.PCharacter(target)^.enabled := 1;
    Types.PCharacter(target)^.status := C_Status.OKAY
  end else
    CharHlp.PrintCreatureMessage(target, GDConsts.unaffectedMessage, 10, True)
end;

procedure SpellPoison;
var
  source: Pointer;
  target: Pointer;
begin
  Magic.ResolveSpell(GDVars.currentSpellIndex, 0, 0, 0, $08, '');
  target := GDVars.currentCharacter^.combat^.target;
  GDVars.currentEffectId := C_Effect.POISON_ATTACK;
  FxEngine.TriggerEffectsWithCondition(C_Cond.EFFECT_ADDED, target);
  if GDVars.currentEffectId = C_Effect.POISON_ATTACK then
    FxEngine.CallEffectHandler(C_Effect.POISON_ATTACK, GDVars.currentCharacter, source, False)
end;

procedure SpellSticksToSnakes;
var found: Pointer;
begin
  if GDVars.spellTargetState.targets[1]^.levelHighest < 6 then begin
    Magic.ResolveSpell(GDVars.currentSpellIndex, CharHlp.GetCasterLevel(GDVars.currentSpellIndex), 0, 0, $08, '');
    if CharHlp.HasEffect(GDVars.spellTargetState.targets[1], C_Effect.SNAKES, found) then
      FxEngine.CallEffectHandler(C_Effect.SNAKES, GDVars.spellTargetState.targets[1], found, False)
  end else
    CharHlp.PrintCreatureMessage(GDVars.spellTargetState.targets[1], GDConsts.smashesFlatText, 10, True)
end;

procedure SpellCureCriticalWounds;
var bonus: Byte;
begin
  if GDVars.currentCharacter^.deity = 4 then
    bonus := FxEngine.RollDice(1, 8) + 3
  else bonus := 3;
  if GDVars.spellTargetState.count = 0 then Exit;
  if FxEngine.RestoreHitPoints(GDVars.spellTargetState.targets[1], bonus + FxEngine.RollDice(3, 8), False) then
    CharHlp.AnnounceHealStatus(GDVars.spellTargetState.targets[1])
end;

procedure SpellFleshToStone;
var result: Boolean;
    character: Pointer;
begin
  GDVars.elementMask := $40;
  character := GDVars.spellTargetState.targets[1];
  GDVars.currentDamage := 255;
  FxEngine.TriggerEffectsWithCondition(C_Cond.EFFECT_ADDED, character);
  if GDVars.currentDamage <> 0 then begin
    result := FxEngine.RollSavingThrow(character, 4, 0);
    if not result then
      FxEngine.KillCreature(character, C_Status.STONED, GDConsts.turnedToStoneText)
  end
end;

procedure SpellDispelEvil;
begin
  FxEngine.AddEffectWithMessage(GDVars.currentCharacter, C_Effect.DISPELLING_EVIL,
                                Magic.CalcSpellDuration(Magic.SPELL_DISPEL_EVIL), 0, 0, 0, 0, '');
  Magic.ResolveSpell(GDVars.currentSpellIndex, 0, 0, 0, 0, GDConsts.isAffectedText)
end;

procedure SpellFlameStrike;
begin
  Magic.ResolveSpell(GDVars.currentSpellIndex, 0, 0, FxEngine.RollDamageDice(6, 8), $09, '')
end;

procedure SpellRaiseDead;
var character: Pointer;
begin
  character := GDVars.spellTargetState.targets[1];
  if ((Types.PCharacter(character)^.status = C_Status.DEAD_STATUS) or
      (Types.PCharacter(character)^.status = C_Status.ANIMATED)) and
      (Types.PCharacter(character)^.stats[C_Stat.CONSTITUTION].base > 0) and
      (Types.PCharacter(character)^.race <> C_Race.SILVANESTI_ELF) and
      (Types.PCharacter(character)^.race <> C_Race.QUALINESTI_ELF) then begin
    GDVars.effectLock := 1;
    FxEngine.RemoveEffect(character, C_Effect.POISONED, nil);
    GDVars.effectLock := 0;
    Types.PCharacter(character)^.status := C_Status.OKAY;
    Types.PCharacter(character)^.enabled := 1;
    Dec(Types.PCharacter(character)^.stats[C_Stat.CONSTITUTION].base);
    FxEngine.RecalcAbility(character, C_Stat.CONSTITUTION);
    Types.PCharacter(character)^.hitPoints := 1;
    CharHlp.PrintCreatureMessage(character, GDConsts.raisedText, 10, True)
  end
end;

procedure SpellSlayLiving;
var character: Pointer;
begin
  character := GDVars.spellTargetState.targets[1];
  GDVars.elementMask := $40;
  GDVars.currentDamage := 67;
  FxEngine.TriggerEffectsWithCondition(C_Cond.EFFECT_ADDED, character);
  if GDVars.currentDamage <> 0 then begin
    if (not FxEngine.RollSavingThrow(character, 4, 0)) and
        ((Types.PCharacter(character)^.immunityFlags and $08) = 0) then
      FxEngine.KillCreature(character, C_Status.DEAD_STATUS, GDConsts.slainText)
    else begin
      GDVars.elementMask := $08;
      FxEngine.InflictNonWeaponDamage(character, FxEngine.RollDamageDice(2, 8) + 1, 0, False)
    end
  end else
    CharHlp.PrintCreatureMessage(character, GDConsts.unaffectedMessage, 10, True)
end;

procedure SpellEntangle;
var character: Pointer;
    index: Byte;
    result: Boolean;
begin
  if GDVars.zone0^.inDungeon = 0 then
    for index := 1 to GDVars.spellTargetState.count do
      if GDVars.spellTargetState.targets[index] <> nil then begin
        character := GDVars.spellTargetState.targets[index];
        result := FxEngine.RollSavingThrow(character, 4, 0);
        FxEngine.AddEffectWithMessage(character, C_Effect.ENTANGLED, Magic.CalcSpellDuration(Magic.SPELL_ENTANGLE), 0,
                                      0, 1, Ord(result), GDConsts.entangledText)
      end
end;

procedure SpellFaerieFire;
begin
  Magic.ApplyEffectToTargets(0, GDConsts.highlightedText)
end;

procedure SpellInvisibilityToAnimals;
begin
  Magic.ResolveSpell(GDVars.currentSpellIndex, 0, 0, 0, 0, GDConsts.invisibleText)
end;

procedure SpellCharmMonsters;
var index: Byte;
    { Unused in this version; see the other implementations of this routine. }
    charmCount: Word;
    source: Pointer;
    { Unused in this version; see the other implementations of this routine. }
    tail: array[0..2] of Byte;
begin
  Magic.ApplyEffectToTargets(0, GDConsts.charmedText);
  for index := 1 to GDVars.spellTargetState.count do
    if CharHlp.HasEffect(GDVars.spellTargetState.targets[index], C_Effect.CHARM, source) then
      FxEngine.CallEffectHandler(C_Effect.CHARM, GDVars.spellTargetState.targets[index], source, False)
end;

procedure SpellConfusion;
var index: Byte;
    result: Boolean;
    character: Pointer;
    { Unused in this version; see the other implementations of this routine. }
    tail: array[0..3] of Byte;
    maximum: Byte;
begin
  maximum := FxEngine.RollDice(2, 8);
  if GDVars.spellTargetState.count > maximum then GDVars.spellTargetState.count := maximum;
  for index := 1 to GDVars.spellTargetState.count do
    if GDVars.spellTargetState.targets[index] <> nil then begin
      character := GDVars.spellTargetState.targets[index];
      result := FxEngine.RollSavingThrow(character, 4, 0);
      FxEngine.AddEffectWithMessage(character, C_Effect.CONFUSED, Magic.CalcSpellDuration(C_Spell.CONFUSION), 0,
                                    0, 1, Ord(result), GDConsts.confusedText)
    end
end;

procedure SpellDimensionDoor;
var character: Pointer;
    { Unused in this version; see the other implementations of this routine. }
    target: array[0..3] of Byte;
    { Unused in this version; see the other implementations of this routine. }
    result: Boolean;
    { Unused in this version; see the other implementations of this routine. }
    effect: array[0..4] of Byte;
begin
  character := GDVars.currentCharacter;
  CbtMap.UpdateCombatMapTile(0, 0, CbtMap.CombatSlot(character));
  result := CbtMap.IsValidCreatureLoc(character, GDVars.targetX, GDVars.targetY, False);
  CbtMap.ScrollView(CbtMap.CombatCellX(character), CbtMap.CombatCellY(character), 0, C_Dir.CENTER);
  CharHlp.PrintCreatureMessage(character, GDConsts.teleportsText, 10, True)
end;

procedure SpellFear;
var character: Pointer;
    current: Pointer;
    index: Byte;
    result: Boolean;
    found: Pointer;
begin
  character := GDVars.currentCharacter;
  Magic.CollectConeTargets(CbtMap.CombatCellX(character), CbtMap.CombatCellY(character), GDVars.targetX,
                           GDVars.targetY, 3, 6);
  for index := 1 to GDVars.spellTargetState.count do begin
    current := GDVars.spellTargetState.targets[index];
    result := FxEngine.RollSavingThrow(current, 4, 0);
    if not result then begin
      FxEngine.AddEffectWithMessage(current, C_Effect.FEAR, Magic.CalcSpellDuration(C_Spell.FEAR), 0, 1, 1,
                                    Ord(result), GDConsts.runsAwayText);
      if CharHlp.HasEffect(current, C_Effect.FEAR, found) then begin
        Types.PCharacter(current)^.combat^.panicked := 1;
        Types.PCharacter(current)^.quickFight := 1;
        if Types.PCharacter(current)^.npc <= $7F then
          Types.PCharacter(current)^.npc := C_Npc.ANIMATED_PLAYER;
        Types.PCharacter(current)^.combat^.target := nil
      end
    end else
      CharHlp.PrintCreatureMessage(current, GDConsts.unaffectedMessage, 10, True)
  end
end;

procedure SpellFireShield;
var choice: Byte;
    { Unused in this version; see the other implementations of this routine. }
    isExtended: Byte;
    done: Byte;
begin
  done := 0;
  repeat
    if GDVars.currentCharacter^.quickFight <> 0 then
      choice := FxEngine.RollDice(1, 2) - 1
    else begin
      MenuCore.EnableChoices(1);
      choice := MenuCore.MenuHorizontal(GDConsts.flameTypePrompt, GDConsts.flameTypeMenu, 0, 0)
    end;
    case choice of
      0: begin
        FxEngine.AddEffectWithMessage(GDVars.currentCharacter, C_Effect.FIRE_SHIELD_HOT,
                                      Magic.CalcSpellDuration(C_Spell.FIRE_SHIELD), 0, 0, 0, 0,
                                      GDConsts.isText + GDConsts.protectedText);
        FxEngine.AddEffectWithMessage(GDVars.currentCharacter, C_Effect.SHOCK_ATTACKER,
                                      Magic.CalcSpellDuration(C_Spell.FIRE_SHIELD), 0, 0, 0, 0, '');
        done := 1
      end;
      1: begin
        FxEngine.AddEffectWithMessage(GDVars.currentCharacter, C_Effect.FIRE_SHIELD_COLD,
                                      Magic.CalcSpellDuration(C_Spell.FIRE_SHIELD), 0, 0, 0, 0,
                                      GDConsts.isText + GDConsts.protectedText);
        FxEngine.AddEffectWithMessage(GDVars.currentCharacter, C_Effect.SHOCK_ATTACKER,
                                      Magic.CalcSpellDuration(C_Spell.FIRE_SHIELD), 0, 0, 0, 0, '');
        done := 1
      end else
      done := Ord(MenuCore.YesNoMenu(GDConsts.abortSpellPrompt, GDConsts.yesKey) = GDConsts.yesKey)
    end
  until done <> 0
end;

procedure SpellFumble;
var
  target: Pointer;
  found: Pointer;
begin
  target := GDVars.spellTargetState.targets[1];
  GDVars.elementMask := $40;
  if not FxEngine.RollSavingThrow(target, 4, 0) then begin
    FxEngine.AddEffectWithMessage(target, C_Effect.BEFUDDLED, Magic.CalcSpellDuration(Magic.SPELL_FUMBLE), 0, 0, 0, 0,
                                  GDConsts.clumsyText);
    if CharHlp.HasEffect(target, C_Effect.BEFUDDLED, found) then
      FxEngine.CallEffectHandler(C_Effect.BEFUDDLED, target, nil, False)
  end else begin
    FxEngine.AddEffectWithMessage(target, C_Effect.SLOWED, Magic.CalcSpellDuration(Magic.SPELL_FUMBLE), 0, 0, 0, 0,
                                  GDConsts.slowedText);
    if CharHlp.HasEffect(target, C_Effect.SLOWED, found) then
      FxEngine.CallEffectHandler(C_Effect.SLOWED, target, nil, False)
  end;
  Magic.ResolveSpell(GDVars.currentSpellIndex, 0, 1, 0, 0, GDConsts.clumsyText)
end;

procedure SpellIceStorm;
begin
  Magic.ResolveSpell(GDVars.currentSpellIndex, 0, 0, FxEngine.RollDamageDice(3, 10), $08, '')
end;

procedure SpellMinorGlobeOfInvulnerability;
begin
  Magic.ResolveSpell(GDVars.currentSpellIndex, 0, 0, 0, 0, GDConsts.isProtectedText)
end;

procedure SpellIronSkin;
begin
  Magic.ResolveSpell(GDVars.currentSpellIndex, 0, 0, 0, 0, GDConsts.isProtectedText)
end;

procedure SpellConeOfCold;
var character: Pointer;
    half: Byte;
    roll: Byte;
begin
  character := GDVars.currentCharacter;
  roll := CharHlp.GetCasterLevel(GDVars.currentSpellIndex);
  half := (CharHlp.GetCasterLevel(GDVars.currentSpellIndex) + 1) div 2;
  if half < 1 then half := 1;
  Magic.CollectConeTargets(CbtMap.CombatCellX(character), CbtMap.CombatCellY(character), GDVars.targetX,
                           GDVars.targetY, 2, half);
  Magic.ResolveSpell(GDVars.currentSpellIndex, 0, 0, FxEngine.RollDamageDice(roll, 4) + roll, $0A, '')
end;

procedure SpellFeeblemind;
var saved: Byte;
    character: Pointer;
    found: Pointer;
begin
  character := GDVars.spellTargetState.targets[1];
  saved := Types.PCharacter(character)^.saves[4];
  case Types.PCharacter(character)^.characterClass of
    C_Class.CLERIC: Dec(Types.PCharacter(character)^.saves[4]);
    C_Class.MAGE: Inc(Types.PCharacter(character)^.saves[4], 4)
  else
    Inc(Types.PCharacter(character)^.saves[4], 2)
  end;
  Magic.ResolveSpell(GDVars.currentSpellIndex, 0, 0, 0, 0, '');
  if CharHlp.HasEffect(character, C_Effect.DRAIN_TWO, found) then
    FxEngine.CallEffectHandler(C_Effect.DRAIN_TWO, character, nil, False);
  Types.PCharacter(character)^.saves[4] := saved
end;

procedure SpellImmuneBreath;
begin
  Magic.ResolveSpell(GDVars.currentSpellIndex, 0, 0, 0, 0, '')
end;

procedure SpellYouth;
var character: Pointer;
begin
  character := GDVars.currentCharacter;
  Types.PCharacter(character)^.age := Types.PCharacter(character)^.age - (FxEngine.RollDice(1, 4) + 1);
  if Types.PCharacter(character)^.age < 18 then begin
    Types.PCharacter(character)^.age := 18;
    CharHlp.PrintCreatureMessage(character, GDConsts.eighteenYearsOldText, 10, True)
  end else
    CharHlp.PrintCreatureMessage(character, GDConsts.youngerText, 10, True)
end;

procedure SpellTurnInvisible;
begin
  Magic.ResolveSpell(GDVars.currentSpellIndex, 0, 0, 0, 0, '')
end;

procedure SpellFireTouch;
begin
  Magic.ResolveSpell(GDVars.currentSpellIndex, 0, 0, 0, 0, GDConsts.coveredInFlameText)
end;

procedure SpellHealSelf;
begin
  if FxEngine.RestoreHitPoints(GDVars.spellTargetState.targets[1], FxEngine.RollDice(2, 4) + 2, False) then
    CharHlp.PrintNameStringAnim(GDVars.spellTargetState.targets[1], True, GDConsts.healedMessage)
end;

procedure SpellPowerWordStun;
var value: Byte;
    character: Pointer;
begin
  character := GDVars.spellTargetState.targets[1];
  case Types.PCharacter(character)^.hitPoints of
    1..30: value := FxEngine.RollDice(4, 4);
    31..60: value := FxEngine.RollDice(2, 4);
    61..90: value := FxEngine.RollDice(1, 4)
  else
    value := 0
  end;
  FxEngine.AddEffectWithMessage(character, GDConsts.spellTable[GDVars.currentSpellIndex].effectId, Word(value),
                                CharHlp.GetCasterLevel(GDVars.currentSpellIndex), 0,
                                GDConsts.spellTable[GDVars.currentSpellIndex].saveEffect, 0, GDConsts.stunnedText)
end;

procedure SpellMassCharm;
var found: Pointer;
    current: Pointer;
    done: Boolean;
    index: Byte;
    state: Byte;
    total: Byte;
    limit: Byte;
begin
  done := False;
  total := 0;
  index := 1;
  limit := CharHlp.GetCasterLevel(GDVars.currentSpellIndex) * 2;
  while (index <= GDVars.spellTargetState.count) and not done do begin
    current := GDVars.spellTargetState.targets[index];
    if current <> nil then begin
      if ((Types.PCharacter(current)^.typeFlags and $02) = 0) or
          (Types.PCharacter(current)^.iconDimensions > 1) then
        CharHlp.PrintCreatureMessage(current, GDConsts.unaffectedMessage, 10, True)
      else begin
        state := Types.PCharacter(current)^.levelHighest;
        if state + total <= limit then begin
          Inc(total, state);
          done := total = limit;
          FxEngine.AddEffectWithMessage(current, C_Effect.CHARM, Magic.CalcSpellDuration(GDVars.currentSpellIndex),
            CharHlp.GetCasterLevel(GDVars.currentSpellIndex) +
              (Integer(GDVars.currentCharacter^.side) * $80),
            1, 1, Ord(FxEngine.RollSavingThrow(current, 4, 0)), GDConsts.charmedText);
          if CharHlp.HasEffect(current, C_Effect.CHARM, found) then
            FxEngine.CallEffectHandler(C_Effect.CHARM, current, found, False)
        end
      end
    end;
    Inc(index)
  end
end;

procedure SpellIrresistibleDance;
var character: Pointer;
begin
  character := GDVars.spellTargetState.targets[1];
  CharHlp.RecalcStats(character);
  FxEngine.TriggerEffectsWithCondition(C_Cond.DEFENDER_ARMOR_CLASS, character);
  if FxEngine.AttackRoll(GDVars.currentCharacter, character, Types.PCharacter(character)^.armorClass) then begin
    FxEngine.AddEffectWithMessage(character, C_Effect.ENTANGLED,
                                  Magic.CalcSpellDuration(Magic.SPELL_OTTOS_IRRESISTIBLE_DANCE),
                                  CharHlp.GetCasterLevel(Magic.SPELL_OTTOS_IRRESISTIBLE_DANCE), 0, 0, 0,
                                  GDConsts.emptyQuery);
    FxEngine.AddEffectWithMessage(character, C_Effect.DANCING,
                                  Magic.CalcSpellDuration(Magic.SPELL_OTTOS_IRRESISTIBLE_DANCE),
                                  CharHlp.GetCasterLevel(Magic.SPELL_OTTOS_IRRESISTIBLE_DANCE), 0, 0, 0,
                                  GDConsts.dancingText)
  end
end;

procedure SpellPowerWordBlind;
var
  { Unused in this version; see the other implementations of this routine. }
  effect: Pointer;
  current: Pointer;
  threshold: Byte;
  index: Byte;
  total: Byte;
begin
  index := 1;
  total := 0;
  while (index <= GDVars.spellTargetState.count) and (total <= 100) do begin
    current := GDVars.spellTargetState.targets[index];
    if (Types.PCharacter(current)^.maxHitPoints <= 100) and
        (Types.PCharacter(current)^.maxHitPoints + total <= 100) then
      Inc(total, Types.PCharacter(current)^.maxHitPoints);
    Inc(index)
  end;
  threshold := FxEngine.RollDice(1, 4) + 1;
  if total < 51 then threshold := threshold * 10;
  index := 1;
  total := 0;
  while (index <= GDVars.spellTargetState.count) and (total <= 100) do begin
    current := GDVars.spellTargetState.targets[index];
    if (Types.PCharacter(current)^.maxHitPoints <= 100) and (Types.PCharacter(current)^.maxHitPoints +
                                                                total <= 100) then begin
      Inc(total, Types.PCharacter(current)^.maxHitPoints);
      FxEngine.AddEffectWithMessage(current, C_Effect.BLIND, Magic.CalcSpellDuration(GDVars.currentSpellIndex), 0, 0,
                                    0, 0, GDConsts.blindText)
    end;
    Inc(index)
  end
end;

procedure EffStoredFireball(var character: Types.PCharacter; state: Pointer; removed: Boolean);
var
  { Unused in this version; see the other implementations of this routine. }
  spellLevel: Byte;
  result: Byte;
begin
  Magic.CastSpell(C_Spell.FIREBALL, 1, 1, result);
  if result <> 0 then
    FxEngine.RemoveEffect(character, C_Effect.STORED_FIREBALL, nil)
end;

procedure EffGazeCharm(var character: Types.PCharacter; state: Pointer; removed: Boolean);
var selected: Byte;
    value: Byte;
begin
  GDVars.spellServices.selectTargets(C_Spell.CHARM_PERSON_MAGE, 1, selected);
  if selected <> 0 then begin
    CharHlp.PrintCreatureMessage(character, GDConsts.gazesText, 10, True);
    value := CbtMap.DirectionToward(character, GDVars.spellTargetState.targets[1]);
    CbtMap.SetCreatureFacing(character, value, 1, 0);
    CharHlp.BuildIconFacings(18);
    CharHlp.CombatAnimateMovingIcon(Integer(ShortInt(CbtMap.CombatCellX(character))),
                                    Integer(ShortInt(CbtMap.CombatCellY(character))),
                                    Integer(ShortInt(GDVars.targetX)), Integer(ShortInt(GDVars.targetY)), 4, 50);
    GDVars.currentSpellIndex := C_Spell.CHARM_PERSON_MAGE;
    GDVars.spellServices.handlers[C_Spell.CHARM_PERSON_MAGE]
  end
end;

procedure EffBreatheLightning(var character: Types.PCharacter; state: Pointer; removed: Boolean);
var result: Byte;
    fromX: Byte;
    fromY: Byte;
    value: Byte;
begin
  if GDVars.roundNumber = 0 then
    Types.PEffect(state)^.strength := 3;
  if Types.PEffect(state)^.strength > 0 then begin
    GDVars.elementMask := $24;
    fromX := CbtMap.CombatCellX(character);
    fromY := CbtMap.CombatCellY(character);
    GDVars.spellServices.selectTargets(C_Spell.LIGHTNING_BOLT, 1, GDVars.breathAim);
    if GDVars.breathAim <> 0 then begin
      CharHlp.PrintCreatureMessage(character, GDConsts.breathesText, 10, True);
      value := CbtMap.DirectionToward(character, GDVars.spellTargetState.targets[1]);
      CharHlp.CombatPrintCreatureInfo(character);
      CbtMap.SetCreatureFacing(character, value, 1, 0);
      CharHlp.BuildIconFacings(19);
      CharHlp.CombatAnimateMovingIcon(Integer(ShortInt(fromX)), Integer(ShortInt(fromY)),
                                      Integer(ShortInt(GDVars.targetX)), Integer(ShortInt(GDVars.targetY)), 4, 50);
      Magic.LightningAttackAt(GDVars.targetX, GDVars.targetY,
                              character^.maxHitPoints, 3, 0, result);
      Magic.LightningPath(10, character^.maxHitPoints, 3, 0);
      Dec(Types.PEffect(state)^.strength);
      result := Ord(CharHlp.EndActions(character))
    end
  end
end;

procedure EffDragonBreath(var character: Types.PCharacter; state: Pointer; removed: Boolean);
var
  { Unused in this version; see the other implementations of this routine. }
  result: Byte;
  fromX: Byte;
  fromY: Byte;
  index: Byte;
  current: Pointer;
  actionResult: Byte;
  kind: Byte;
  range: Byte;
  actionSaved: Boolean absolute actionResult;
  breathName: String[5];
  value: Byte;
begin
  if GDVars.roundNumber = 0 then
    Types.PEffect(state)^.strength := 3;
  if Types.PEffect(state)^.strength > 0 then begin
    case Types.PEffect(state)^.effectId of
      90: begin
        GDVars.elementMask := $30;
        kind := 1;
        range := 6;
        breathName := GDConsts.acidText
      end;
      100: begin
        GDVars.elementMask := $60;
        kind := 1;
        range := 8;
        breathName := GDConsts.deathText
      end;
      104: begin
        GDVars.elementMask := $21;
        kind := 3;
        range := 9;
        breathName := GDConsts.fireText
      end
    end;
    fromX := CbtMap.CombatCellX(character);
    fromY := CbtMap.CombatCellY(character);
    GDVars.spellServices.selectTargets(36, 1, GDVars.breathAim);
    if GDVars.breathAim <> 0 then begin
      Magic.CollectConeTargets(fromX, fromY, GDVars.targetX, GDVars.targetY, kind, range);
      for index := 1 to GDVars.spellTargetState.count do
        if Byte(GDVars.spellTargetState.targets[index]^.side) <>
            Byte(CharHlp.EnemyTeam(character)) then
          GDVars.breathAim := 0;
      if (GDVars.spellTargetState.count > 0) and (GDVars.breathAim <> 0) then begin
        CharHlp.PrintCreatureMessage(character, GDConsts.breathesText + breathName, 10, True);
        value := CbtMap.DirectionToward(character, GDVars.spellTargetState.targets[1]);
        CharHlp.CombatPrintCreatureInfo(character);
        CbtMap.SetCreatureFacing(character, value, 1, 0);
        CharHlp.BuildIconFacings(18);
        CharHlp.CombatAnimateMovingIcon(Integer(ShortInt(CbtMap.CombatCellX(character))),
                                        Integer(ShortInt(CbtMap.CombatCellY(character))),
                                        Integer(ShortInt(CbtMap.CombatCellX(GDVars.spellTargetState.targets[1]))),
                                        Integer(ShortInt(CbtMap.CombatCellY(GDVars.spellTargetState.targets[1]))), 1,
                                        30);
        for index := 1 to GDVars.spellTargetState.count do
          if GDVars.spellTargetState.targets[index] <> nil then begin
            current := GDVars.spellTargetState.targets[index];
            actionResult := Ord(FxEngine.RollSavingThrow(current, 3, 0));
            FxEngine.InflictNonWeaponDamage(current, character^.maxHitPoints, 2,
                                            actionSaved)
          end;
        Dec(Types.PEffect(state)^.strength);
        result := Ord(CharHlp.EndActions(character))
      end
    end
  end
end;

function ItemReadable(item: Types.PItem): Boolean;
begin
  if (item <> nil) and
      ((Types.PItem(item)^.itemType = 39) or (Types.PItem(item)^.itemType = 40)) then
    ItemReadable := True
  else
    ItemReadable := False
end;

procedure RemoveSpellFromScroll(owner, item: Pointer; spellId: Byte);
var saved: Byte;
    index: Byte;
    found: Byte;
begin
  saved := spellId;
  found := 0;
  for index := 1 to 3 do
    if (Types.PItem(item)^.scrollSpells[index] and $7F) = saved then
      found := index;
  if found = 0 then begin
  end else begin
    Types.PItem(item)^.scrollSpells[found] := 0;
    Dec(Types.PItem(item)^.nameIds[1]);
    if Types.PItem(item)^.nameIds[1] < 100 then
      CharHlp.RemoveItem(owner, Types.PItem(item))
  end
end;

procedure PrintCastSpellMsg(character: Types.PCharacter; source: Types.TString40; spellId: Byte);
begin
  if GDVars.interfaceState = C_Ifc.IN_COMBAT then begin
    CharHlp.PrintCreatureMessage(character, GDConsts.castsSpellText, 10, True);
    Border.ClearBox(0, 23, 39, 23);
    TextRend.DisplayString(0, 23, LightGreen, Black, GDConsts.spellLabel + GDConsts.spellNames[spellId])
  end else begin
    Border.ClearBox(1, 18, 38, 22);
    CharHlp.DisplayCreatureName(character, 1, 19, False);
    TextRend.DisplayString(Length(Types.PCharacter(character)^.name) + 2, 19, LightGreen, Black, source);
    TextRend.DisplayString(1, 20, LightGreen, Black, GDConsts.spellNames[spellId]);
    TextRend.PauseOnly;
    CharHlp.ClearMessageWindow
  end
end;

procedure InitSpellFns;
begin
  GDVars.spellServices.selectTargets := Magic.NoncombatCastTargetMenu;
  GDVars.effectLock := 0;
  GDVars.usingItem := 0;
  GDVars.spellTargetState.noncombatTarget := nil;
  GDVars.redrawInventory := 1;
  GDVars.spellServices.handlers[C_Spell.BLESS_CLERIC] := Magic.SpellBless;
  GDVars.spellServices.handlers[2] := Magic.SpellBarkskin;
  GDVars.spellServices.handlers[C_Spell.CURE_LIGHT_WOUNDS] := Magic.SpellCureLightWounds;
  GDVars.spellServices.handlers[C_Spell.CHARM_PERSON_MAMMAL] := Magic.SpellCharmPersonOrMammal;
  GDVars.spellServices.handlers[C_Spell.DETECT_MAGIC_CLERIC] := Magic.SpellDetection;
  GDVars.spellServices.handlers[6] := Magic.SpellProtection;
  GDVars.spellServices.handlers[7] := Magic.SpellResurrection;
  GDVars.spellServices.handlers[8] := Magic.SpellResistCold;
  GDVars.spellServices.handlers[9] := Magic.SpellBurningHands;
  GDVars.spellServices.handlers[C_Spell.CHARM_PERSON_MAGE] := Magic.SpellCharmPerson;
  GDVars.spellServices.handlers[C_Spell.DETECT_MAGIC_MAGE] := Magic.SpellDetection;
  GDVars.spellServices.handlers[C_Spell.ENLARGE] := Magic.SpellEnlarge;
  GDVars.spellServices.handlers[13] := Magic.SpellReduce;
  GDVars.spellServices.handlers[14] := Magic.SpellFriends;
  GDVars.spellServices.handlers[C_Spell.MAGIC_MISSILE] := Magic.SpellMagicMissile;
  GDVars.spellServices.handlers[C_Spell.PROTECTION_FROM_EVIL_MAGE] := Magic.SpellProtection;
  GDVars.spellServices.handlers[C_Spell.RESTORATION] := Magic.SpellRestoration;
  GDVars.spellServices.handlers[C_Spell.READ_MAGIC] := Magic.SpellDetection;
  GDVars.spellServices.handlers[C_Spell.SHIELD] := Magic.SpellShield;
  GDVars.spellServices.handlers[20] := Magic.SpellShockingGrasp;
  GDVars.spellServices.handlers[C_Spell.SLEEP] := Magic.SpellSleep;
  GDVars.spellServices.handlers[22] := Magic.SpellDetection;
  GDVars.spellServices.handlers[C_Spell.HOLD_PERSON_CLERIC] := Magic.SpellHold;
  GDVars.spellServices.handlers[24] := Magic.SpellResistFire;
  GDVars.spellServices.handlers[25] := Magic.SpellSilence;
  GDVars.spellServices.handlers[Magic.SPELL_SLOW_POISON] := Magic.SpellSlowPoison;
  GDVars.spellServices.handlers[27] := Magic.SpellSnakeCharm;
  GDVars.spellServices.handlers[28] := Magic.SpellSpiritualHammer;
  GDVars.spellServices.handlers[C_Spell.DETECT_INVISIBILITY] := Magic.SpellDetection;
  GDVars.spellServices.handlers[C_Spell.INVISIBILITY] := Magic.SpellInvisibility;
  GDVars.spellServices.handlers[C_Spell.KNOCK] := Magic.SpellKnock;
  GDVars.spellServices.handlers[C_Spell.MIRROR_IMAGE] := Magic.SpellMirrorImage;
  GDVars.spellServices.handlers[C_Spell.RAY_OF_ENFEEBLEMENT] := Magic.SpellRayOfEnfeeblement;
  GDVars.spellServices.handlers[C_Spell.STINKING_CLOUD] := Magic.SpellStinkingCloud;
  GDVars.spellServices.handlers[35] := Magic.SpellStrength;
  GDVars.spellServices.handlers[36] := Magic.SpellNoEffect;
  GDVars.spellServices.handlers[C_Spell.CURE_BLINDNESS] := Magic.SpellCureBlindness;
  GDVars.spellServices.handlers[38] := Magic.SpellCauseBlindness;
  GDVars.spellServices.handlers[39] := Magic.SpellCureDisease;
  GDVars.spellServices.handlers[40] := Magic.SpellHarm;
  GDVars.spellServices.handlers[41] := Magic.SpellDispelMagic;
  GDVars.spellServices.handlers[C_Spell.PRAYER] := Magic.SpellPrayer;
  GDVars.spellServices.handlers[C_Spell.REMOVE_CURSE_CLERIC] := Magic.SpellRemoveCurse;
  GDVars.spellServices.handlers[44] := Magic.SpellBestowCurse;
  GDVars.spellServices.handlers[C_Spell.BLINK_MAGE] := Magic.SpellBlink;
  GDVars.spellServices.handlers[C_Spell.DISPEL_MAGIC_MAGE] := Magic.SpellDispelMagic;
  GDVars.spellServices.handlers[C_Spell.FIREBALL] := Magic.SpellFireball;
  GDVars.spellServices.handlers[C_Spell.HASTE] := Magic.SpellHaste;
  GDVars.spellServices.handlers[C_Spell.HOLD_PERSON_MAGE] := Magic.SpellHold;
  GDVars.spellServices.handlers[C_Spell.INVISIBILITY_RADIUS] := Magic.SpellInvisibility;
  GDVars.spellServices.handlers[C_Spell.LIGHTNING_BOLT] := Magic.SpellLightningBolt;
  GDVars.spellServices.handlers[52] := Magic.SpellProtection;
  GDVars.spellServices.handlers[C_Spell.HEAL] := Magic.SpellHeal;
  GDVars.spellServices.handlers[54] := Magic.SpellProtection;
  GDVars.spellServices.handlers[55] := Magic.SpellSlow;
  GDVars.spellServices.handlers[C_Spell.DEATH_SPELL] := Magic.SpellDeathSpell;
  GDVars.spellServices.handlers[57] := Magic.SpellPotionOfSpeed;
  GDVars.spellServices.handlers[C_Spell.CURE_SERIOUS_WOUNDS] := Magic.SpellCureSeriousWounds;
  GDVars.spellServices.handlers[59] := Magic.SpellGiantStrength;
  GDVars.spellServices.handlers[60] := Magic.SpellDisintegrate;
  GDVars.spellServices.handlers[61] := Magic.SpellWandOfParalyzation;
  GDVars.spellServices.handlers[62] := Magic.SpellPotionOfHealing;
  GDVars.spellServices.handlers[63] := Magic.SpellGlobeOfInvulnerability;
  GDVars.spellServices.handlers[64] := Magic.SpellFireball;
  GDVars.spellServices.handlers[65] := Magic.SpellWandOfMagicMissiles;
  GDVars.spellServices.handlers[66] := Magic.SpellStoneToFlesh;
  GDVars.spellServices.handlers[67] := Magic.SpellNeutralizePoison;
  GDVars.spellServices.handlers[C_Spell.POISON] := Magic.SpellPoison;
  GDVars.spellServices.handlers[69] := Magic.SpellProtection;
  GDVars.spellServices.handlers[70] := Magic.SpellSticksToSnakes;
  GDVars.spellServices.handlers[C_Spell.CURE_CRITICAL_WOUNDS] := Magic.SpellCureCriticalWounds;
  GDVars.spellServices.handlers[72] := Magic.SpellFleshToStone;
  GDVars.spellServices.handlers[Magic.SPELL_DISPEL_EVIL] := Magic.SpellDispelEvil;
  GDVars.spellServices.handlers[C_Spell.FLAME_STRIKE] := Magic.SpellFlameStrike;
  GDVars.spellServices.handlers[C_Spell.RAISE_DEAD] := Magic.SpellRaiseDead;
  GDVars.spellServices.handlers[C_Spell.SLAY_LIVING] := Magic.SpellSlayLiving;
  GDVars.spellServices.handlers[C_Spell.DETECT_MAGIC_DRUID] := Magic.SpellDetection;
  GDVars.spellServices.handlers[Magic.SPELL_ENTANGLE] := Magic.SpellEntangle;
  GDVars.spellServices.handlers[C_Spell.FAERIE_FIRE] := Magic.SpellFaerieFire;
  GDVars.spellServices.handlers[80] := Magic.SpellInvisibilityToAnimals;
  GDVars.spellServices.handlers[C_Spell.CHARM_MONSTERS] := Magic.SpellCharmMonsters;
  GDVars.spellServices.handlers[C_Spell.CONFUSION] := Magic.SpellConfusion;
  GDVars.spellServices.handlers[C_Spell.DIMENSION_DOOR] := Magic.SpellDimensionDoor;
  GDVars.spellServices.handlers[C_Spell.FEAR] := Magic.SpellFear;
  GDVars.spellServices.handlers[C_Spell.FIRE_SHIELD] := Magic.SpellFireShield;
  GDVars.spellServices.handlers[Magic.SPELL_FUMBLE] := Magic.SpellFumble;
  GDVars.spellServices.handlers[C_Spell.ICE_STORM] := Magic.SpellIceStorm;
  GDVars.spellServices.handlers[88] := Magic.SpellMinorGlobeOfInvulnerability;
  GDVars.spellServices.handlers[89] := Magic.SpellRemoveCurse;
  GDVars.spellServices.handlers[90] := Magic.SpellIronSkin;
  GDVars.spellServices.handlers[C_Spell.CLOUDKILL] := Magic.SpellStinkingCloud;
  GDVars.spellServices.handlers[92] := Magic.SpellConeOfCold;
  GDVars.spellServices.handlers[93] := Magic.SpellFeeblemind;
  GDVars.spellServices.handlers[C_Spell.HOLD_MONSTERS] := Magic.SpellHold;
  GDVars.spellServices.handlers[95] := Magic.SpellImmuneBreath;
  GDVars.spellServices.handlers[96] := Magic.SpellYouth;
  GDVars.spellServices.handlers[97] := Magic.SpellTurnInvisible;
  GDVars.spellServices.handlers[98] := Magic.SpellFireTouch;
  GDVars.spellServices.handlers[99] := Magic.SpellHealSelf;
  GDVars.spellServices.handlers[100] := Magic.SpellBestowCurse;
  GDVars.spellServices.handlers[C_Spell.PROTECTION_FROM_EVIL_RADIUS_GIFT] := Magic.SpellProtection;
  GDVars.spellServices.handlers[C_Spell.SILENCE_RADIUS_GIFT] := Magic.SpellSilence;
  GDVars.spellServices.handlers[C_Spell.DETECT_MAGIC_GIFT] := Magic.SpellDetection;
  GDVars.spellServices.handlers[C_Spell.REMOVE_CURSE_GIFT] := Magic.SpellRemoveCurse;
  GDVars.spellServices.handlers[C_Spell.BLESS_GIFT] := Magic.SpellBless;
  GDVars.spellServices.handlers[C_Spell.CHARM_PERSON_GIFT] := Magic.SpellCharmPerson;
  GDVars.spellServices.handlers[C_Spell.BURNING_HANDS_GIFT] := Magic.SpellBurningHands;
  GDVars.spellServices.handlers[C_Spell.DELAY_BLAST_FIREBALL] := Magic.SpellFireball;
  GDVars.spellServices.handlers[109] := Magic.SpellInvisibility;
  GDVars.spellServices.handlers[110] := Magic.SpellPowerWordStun;
  GDVars.spellServices.handlers[C_Spell.MASS_CHARM] := Magic.SpellMassCharm;
  GDVars.spellServices.handlers[112] := Magic.SpellProtection;
  GDVars.spellServices.handlers[Magic.SPELL_OTTOS_IRRESISTIBLE_DANCE] := Magic.SpellIrresistibleDance;
  GDVars.spellServices.handlers[114] := Magic.SpellPowerWordBlind;
  @GDVars.effectServices.handlers[C_Effect.STORED_FIREBALL] := @Magic.EffStoredFireball;
  @GDVars.effectServices.handlers[C_Effect.GAZE_CHARM] := @Magic.EffGazeCharm;
  @GDVars.effectServices.handlers[C_Effect.BREATH_BOLT] := @Magic.EffBreatheLightning;
  @GDVars.effectServices.handlers[90] := @Magic.EffDragonBreath;
  @GDVars.effectServices.handlers[100] := @Magic.EffDragonBreath;
  @GDVars.effectServices.handlers[104] := @Magic.EffDragonBreath
end;
begin
end.
