{ CharHlp -- shared character routines: the derived figures (armor class, THAC0, damage, movement, encumbrance, strength
  and dexterity adjustments), item and spell bookkeeping, the party list and the message lines, damage and effects,
  combat counts and targeting, the screen layouts, and character selection. }
{$F+,O+,S-,R-,V-,B-,I-}
unit CharHlp;
interface
uses C_Class, C_Dir, C_Effect, C_Ifc, C_Keys, C_Race, C_Side, C_Spell, C_Stat, C_Status, GDConsts, GDVars, TextRend,
  CbtMap, Border, Blit, Pathing, Crt, Music, MapView, GameIo, MenuCore, Portrait, Types;

{ Rolls a percentile chance.
  @param(percent The chance in 100.)
  @returns(True with a chance of percent in 100.) }
function PercentileRoll(percent: Byte): Boolean;

{ Builds an item's display name in its own name field: a Yes/No readied column for the inventory view, '*' on a magical
  item (plus, save bonus or cursed) when any party member has Detect Magic, the quantity, then the identified name
  parts, at most one of them pluralized when the quantity is above 1.
  @param(character Unused.)
  @param(item The item to name.)
  @param(column Screen column for the printed name.)
  @param(row Screen row for the printed name.)
  @param(inventory Adds the readied column.)
  @param(draw Also prints the name at (column, row).) }
procedure PrintItemString(character, item: Pointer; column, row: Byte; inventory, draw: Boolean);

{ Redraws the party list (name, AC, HP) with highlight drawn bright and records its box for mouse clicks; nothing on the
  overland map or over a big picture.
  @param(highlight Party member drawn bright.) }
procedure DisplayParty(highlight: Types.PCharacter);

{ Does nothing on the map screen while the map is shown there, or while the party panel is hidden. Otherwise sets the
  party panel's bounds and repaints only the highlighted member's row (name, armor class and hit points, each placed by
  its digit-width band), leaving the other rows as they are, then clears the row after the last member and drops the
  highlight.
  @param(highlight Seeds the highlight when none is set.)
  @param(clearHighlight True draws the name plainly in white instead of in its condition color.) }
procedure DisplayRoster(highlight: Types.PCharacter; clearHighlight: Boolean);

{ Prints a creature's current hit points at a screen position: yellow when wounded, light green when whole, light
  magenta when asked. When asked, the maximum follows after a slash in light green.
  @param(character The creature.)
  @param(column The column.)
  @param(row The row.)
  @param(hotPink Set to print in light magenta.)
  @param(showMax Set to add the maximum after a slash.) }
procedure PrintHitPoints(character: Types.PCharacter; column, row: Byte; hotPink, showMax: Boolean);

{ Prints a character's armor class in light green: 60 minus the stored value, with a minus sign when the value is above
  60.
  @param(character The character.)
  @param(column Screen column.)
  @param(row Screen row.) }
procedure PrintArmorClass(character: Types.PCharacter; column, row: Byte);

{ Fills the combat side panel for a creature when the panel is marked dirty (and clears the mark): name, hit points,
  armor class, readied weapon, and the status name of a creature out of play, '(Helpless)' or '(Casting)'.
  @param(character The creature to show.) }
procedure CombatPrintCreatureInfo(character: Types.PCharacter);

{ Whether character has any of the helpless effects in helplessEffects.
  @param(character The creature.)
  @returns(True when it is helpless.) }
function IsHelpless(character: Types.PCharacter): Boolean;

{ Recomputes character's readied items, item count, hands, encumbrance, damage, THAC0, movement, AC and rear AC.
  @param(character The character.) }
procedure RecalcStats(character: Types.PCharacter);

{ Formats a number as decimal text.
  @param(value The number.)
  @returns(Its decimal text.) }
function LongIntToString(value: LongInt): String;

{ Formats a number as decimal text.
  @param(value The number.)
  @returns(Its decimal text.) }
function WordToString(value: Word): String;

{ Formats a number as decimal text.
  @param(value The number.)
  @returns(Its decimal text.) }
function ByteToString(value: Byte): String;

{ Computes the Dexterity missile adjustment from the current Dexterity: -4 at 0..2, -3..-1 at 3..5, +1..+3 at 16..18, 3
  at 19..20, 4 at 21..23, 5 at 24..25, else 0.
  @param(character The creature.)
  @returns(The adjustment.) }
function DexMissileAdjust(character: Types.PCharacter): ShortInt;

{ Computes the Strength to-hit bonus on TranslatedStrength's scale (-3 at 1..3 up to +7 at 30), or 0 unless the
  creature's Strength bonus applies.
  @param(character The creature.)
  @returns(The to-hit bonus.) }
function StrToHitAdjust(character: Types.PCharacter): ShortInt;

{ Computes the Strength damage bonus on TranslatedStrength's scale (-2 at 1..2 up to +14 at 30), or 0 unless the
  creature's Strength bonus applies.
  @param(character The creature.)
  @returns(The damage bonus.) }
function StrDamageAdjust(character: Types.PCharacter): ShortInt;

{ Computes the extra carrying allowance for a character's Strength on TranslatedStrength's scale, from -350 at 1..3 to
  15000 at 30, and 0 at 8..11.
  @param(character The character.)
  @returns(The allowance, which may be negative.) }
function WeightAllowance(character: Types.PCharacter): Integer;

{ Marks the first memorized spellId as cast (bit 7).
  @param(character The caster.)
  @param(spellId The spell cast.) }
procedure RemoveSpell(character: Types.PCharacter; spellId: Byte);

{ Takes an item out of a creature's items and frees it; a nil item, or one not in the list, only gets an error message.
  @param(character The creature.)
  @param(item The item.) }
procedure RemoveItem(character: Types.PCharacter; item: Types.PItem);

{ Appends a copy of an item to a creature's item list. A monster in combat takes its copy from the heap; everyone else
  uses the slot pool.
  @param(character The creature.)
  @param(item The item.) }
procedure AddItemCopy(character: Types.PCharacter; item: Types.PItem);

{ Shows a message on the bottom row in light green for the text delay, then clears the row.
  @param(message The message.) }
procedure PrintBottomLine(message: Types.TString40);

{ Prints a creature's name with a message under it: in combat in the side panel from the given row on, elsewhere in the
  text window from row 17, or 18 while the border is off.
  @param(character The creature.)
  @param(message The message.)
  @param(row The panel row of the name, read in combat.)
  @param(pause When set, pauses and then clears the message area.) }
procedure PrintCreatureMessage(character: Types.PCharacter; message: String; row: Byte; pause: Boolean);

{ Clears the message area: the side panel's rows 10..21 in combat, otherwise rows 18..22. }
procedure ClearMessageWindow;

{ Prints character's name in red when out of play, yellow for a monster in combat, magenta when it can level up, cyan
  otherwise.
  @param(character The creature.)
  @param(column Column to print at.)
  @param(row Row to print at.)
  @param(tail True to add 's.) }
procedure DisplayCreatureName(character: Types.PCharacter; column, row: Byte; tail: Boolean);

{ Copies one frame of an icon slot, mirrored or not, into one frame of the combat view picture.
  @param(cell The icon slot.)
  @param(half The icon frame to copy, 0 or 1.)
  @param(row The picture frame to fill.)
  @param(mirror Mirrors the frame.) }
procedure CopyIconFacing(cell, half, row: Byte; mirror: Boolean);

{ Builds the four-frame moving-icon sheet from an icon: frame 0 straight and mirrored, then frame 1 mirrored and
  straight.
  @param(cell The icon slot.) }
procedure BuildIconFacings(cell: Byte);

{ Animates the moving icon along the line from one arena cell to another, scrolling the view as it goes.
  @param(startX Arena column of the start.)
  @param(startY Arena row of the start.)
  @param(endX Arena column of the end.)
  @param(endY Arena row of the end.)
  @param(frames Number of icon frames to cycle.)
  @param(pace Delay between steps.) }
procedure CombatAnimateMovingIcon(startX, startY, endX, endY: Integer; frames, pace: Byte);

{ Prints character's name and message, in combat centering it and flashing for an effect.
  @param(character The creature named.)
  @param(effect True to flash for an effect.)
  @param(message The message.) }
procedure PrintNameStringAnim(character: Types.PCharacter; effect: Boolean; message: String);

{ Finds a creature's first copy of an effect.
  @param(character The creature.)
  @param(effectId The effect to look for.)
  @param(effect Receives that effect, or nil.)
  @returns(True when the creature has the effect.) }
function HasEffect(character: Pointer; effectId: Byte; var effect: Pointer): Boolean;

{ Subtracts damage from a creature's hit points. Falling more than 9 below 0, or an animated creature reaching 0, kills
  it; 1..9 below makes it dying (in combat the deficit is kept as overkill); landing on 0 makes it unconscious. A
  creature whose status is then anything but okay or animated is disabled at 0 hit points and, in combat, removed from
  its side's count and loses its initiative.
  @param(character The creature.)
  @param(damage The damage.) }
procedure InflictDamage(character: Types.PCharacter; damage: Byte);

{ Announces that a creature is fully or partially healed; out of combat, also repaints its party-panel row, plainly when
  it is the current character.
  @param(character The creature.) }
procedure AnnounceHealStatus(character: Types.PCharacter);

{ Finds a creature's opposing team.
  @param(character The creature.)
  @returns(1 for a creature that is not hostile, else 0.) }
function EnemyTeam(character: Types.PCharacter): ShortInt;

{ Recounts the creatures in play on each side. }
procedure CountTeams;

{ Counts the creatures within range of a creature on the wanted side: its own side when asked, else the enemy side. The
  ranked approach list is compacted in place to those creatures, their indices are copied into the target table, and the
  count is returned. Under effect 91 the preferred target is moved to the front of that list.
  @param(character The creature.)
  @param(range The range.)
  @param(sameSide True counts the creature's own side, False the enemy side.)
  @returns(The count.) }
function CountTargets(character: Types.PCharacter; range: Byte; sameSide: Boolean): Byte;

{ Measures the distance in whole steps from one creature to another, read from a fresh range-255 target list built
  ignoring terrain (the previous list is saved and restored). Note: an absent target gives the last entry's distance.
  @param(character The creature measuring.)
  @param(other The creature to find.)
  @returns(The distance.) }
function CalcDistance(character, other: Types.PCharacter): Byte;

{ Ends a creature's actions for the round: clears its initiative, casting, guarding and movement.
  @param(character The creature.)
  @returns(Always True.) }
function EndActions(character: Types.PCharacter): Boolean;

{ Ends a creature's actions and, unless it is turned, sets it guarding with a 'Guarding' message.
  @param(character The creature.)
  @returns(Always True.) }
function Guard(character: Types.PCharacter): Boolean;

{ The level at which the current character casts spellId: 6 for a character with no casting class; cleric spells (types
  0, 2) at the higher of its cleric and knight levels; druid spells (1) at ranger level - 7; mage spells (3) at the
  higher of its mage level (one less at its moon's phase 0, one more at phase 2 above level 5) and its ranger level;
  type 4 at 12. Spell 47 under effect 78 is 15, and an item's spell 6.
  @param(spellId The spell.)
  @returns(The caster level.) }
function GetCasterLevel(spellId: Byte): Byte;

{ Lets the player choose a party member (or none when allowNil) with prompt, by keys or mouse.
  @param(prompt The prompt.)
  @param(allowNil True to allow choosing no one.)
  @param(mode Selection mode, kept in selectionMode while choosing.)
  @param(selected Receives the member chosen, or nil.) }
procedure SelectChar(prompt: Types.TString40; allowNil: Boolean; mode: Byte; var selected: Pointer);

{ Redraws the screen for the interface state: frames, view or picture, party and info. }
procedure DisplayNoncombatInterface;

{ The status line: position (unless the automap is locked), facing, time, trace mark, and camping or searching. }
procedure PrintMiscInfo;

{ Switches to the combat palette, draws the combat frame and rebuilds the combat view. }
procedure DisplayCombatInterface;

{ Tells whether a creature's readied weapon has a range above 1.
  @param(character The creature.)
  @returns(True for a ranged weapon.) }
function HasRangedWeapon(character: Types.PCharacter): Boolean;

{ Tells whether a creature's readied weapon is ranged and either is thrown as its own missile or is item type 67.
  @param(character The creature.)
  @returns(True for a thrown weapon.) }
function HasThrowableWeapon(character: Types.PCharacter): Boolean;

{ Finds the item that does the damage in a ranged attack: the readied weapon itself when thrown, else the readied arrows
  for a bow or the readied quarrels for a crossbow, or nil when there is none.
  @param(character The creature.)
  @param(selected Receives the item, or nil.)
  @returns(True when an item is found, and also for a weapon whose properties are exactly $0A, which needs no
    ammunition.) }
function FindDamagingRangedWeapon(character: Types.PCharacter; var selected: Types.PItem): Boolean;

{ Checks whether a creature's readied weapon is a hoopak.
  @param(character The creature.)
  @returns(True for a hoopak.) }
function HasReadiedHoopak(character: Types.PCharacter): Boolean;

{ Works out a creature's movement: its base movement, limited by readied body armor and encumbrance, doubled by haste
  and halved by slow; it is stored as the creature's current movement and the global movement, where a party member gets
  the zone's party movement bonus, and the total is doubled into half-steps.
  @param(character The creature.)
  @returns(The movement in half-steps.) }
function RecalcMovement(character: Types.PCharacter): Byte;

{ Tells whether any party member (a player or non-player character on the player side) is dying. With `apply` set, the
  first dying member found is bandaged: it becomes unconscious, its overkill is cleared and the bandaging is announced.
  @param(apply Set to bandage the first dying member.)
  @returns(True when a member is dying.) }
function BandageDying(apply: Boolean): Boolean;

{ The progression row for classId, by deity, knightly order or robe order.
  @param(character The character.)
  @param(classId The class.)
  @returns(The progression row.) }
function ClassSuborderIndex(character: Types.PCharacter; classId: Byte): Byte;

{ Finds the compass direction (0 = N, 1 = NE, ... 7 = NW) from one creature to another on the combat grid, by octant:
  the slopes 618/256 and 106/256 are tan 67.5 and tan 22.5 degrees.
  @param(creature The creature looked from.)
  @param(other The creature looked at.)
  @returns(The direction.) }
function DirTowardTarget(creature, other: Types.PCharacter): Byte;

{ Whether character has the experience for its next level in some class below 18.
  @param(character The character.)
  @returns(True when it can level up.) }
function CanLevelUp(character: Types.PCharacter): Boolean;

{ Plays a scatter effect around the combat target point: issues the sound cue, builds the effect's four frames from an
  icon, then scatters frames over growing rings, each point at a random angle, clipped to the effect box and flushed
  ring by ring. Near an arena edge the pattern is offset toward that edge. The view is scrolled to the point before and
  after.
  @param(radius The number of rings, less 1, divided by 3.)
  @param(cell The icon the frames are built from.)
  @param(soundCue The sound cue.) }
procedure ScatterCombatIcon(radius, cell, soundCue: Byte);

{ The constitution hit-point adjustment, more for the fighting classes.
  @param(character The character.)
  @param(classId The class.)
  @returns(The adjustment.) }
function ClassConAdj(character: Types.PCharacter; classId: Byte): ShortInt;
implementation
type
  TArmorAdjustments = array[0..4] of ShortInt;

function DexterityArmorAdjustment(character: Types.PCharacter): ShortInt; forward;

function PercentileRoll(percent: Byte): Boolean;
begin
  PercentileRoll := percent > Random(100)
end;

{ Sets the readied weapon's THAC0 and damage. THAC0 starts from its base, plus the Dexterity missile adjustment for a
  missile weapon and the Strength to-hit bonus for a weapon that uses Strength, which also adds the Strength damage
  bonus. The damage modifier starts from the weapon's small-target modifier. The weapon's plus and its ammunition's plus
  (the readied quarrels or arrows it fires) are added to both the damage modifier and THAC0; a Silvanesti or Qualinesti
  elf adds 1 more to THAC0 alone with item types 18, 19 and 22..26, and a kender 2 more with a hoopak. The damage dice
  are the small-target dice. Does nothing without a readied weapon.
  @param(character The character.) }
procedure WeaponAdjust(character: Types.PCharacter);
var weapon: Types.PItem;
    weaponType: Byte;
    plus: ShortInt;
begin
  weapon := Types.PCharacter(character)^.equipped[0];
  if weapon = nil then Exit;
  weaponType := weapon^.itemType;
  Types.PCharacter(character)^.thac0Adjusted := Types.PCharacter(character)^.thac0Base;
  if (GDVars.baseItems[weaponType].flags and $02) <> 0 then
    Types.PCharacter(character)^.thac0Adjusted := CharHlp.DexMissileAdjust(character) +
        Types.PCharacter(character)^.thac0Adjusted;
  Types.PCharacter(character)^.currentModifiers[1] := GDVars.baseItems[weaponType].damageModifier;
  if (GDVars.baseItems[weaponType].flags and $04) <> 0 then begin
    Types.PCharacter(character)^.thac0Adjusted := CharHlp.StrToHitAdjust(character) +
        Types.PCharacter(character)^.thac0Adjusted;
    Types.PCharacter(character)^.currentModifiers[1] :=
      CharHlp.StrDamageAdjust(character) + Types.PCharacter(character)^.currentModifiers[1]
  end;
  plus := weapon^.plus;
  if GDVars.baseItems[weaponType].flags > $7F then
    if Types.PCharacter(character)^.equipped[12] <> nil then
      plus := plus + Types.PCharacter(character)^.equipped[12]^.plus;
  if (GDVars.baseItems[weaponType].flags and $01) > 0 then
    if Types.PCharacter(character)^.equipped[11] <> nil then
      plus := plus + Types.PCharacter(character)^.equipped[11]^.plus;
  Types.PCharacter(character)^.currentModifiers[1] := Types.PCharacter(character)^.currentModifiers[1] + plus;
  if ((Types.PCharacter(character)^.race = C_Race.SILVANESTI_ELF) or
      (Types.PCharacter(character)^.race = C_Race.QUALINESTI_ELF)) and
      (((weapon^.itemType > 21) and (weapon^.itemType < 27)) or (weapon^.itemType = 19) or (weapon^.itemType = 18)) then
    Inc(plus);
  if (Types.PCharacter(character)^.race = C_Race.KENDER) and (weapon^.itemType = 67) then
    Inc(plus, 2);
  Types.PCharacter(character)^.thac0Adjusted := Types.PCharacter(character)^.thac0Adjusted + plus;
  Types.PCharacter(character)^.currentRolls[1] := GDVars.baseItems[weaponType].damageRolls;
  Types.PCharacter(character)^.currentDice[1] := GDVars.baseItems[weaponType].damageDice
end;

{ Sets movement from readied body armor's weight: the base movement up to 150, 9 up to 399, else 6; magic armor adds 3
  when that leaves 9 or less.
  @param(character The character.)
  @param(item A readied item; anything but body armor is ignored.) }
procedure ArmorMoveAdjust(character, item: Pointer);
begin
  if GDVars.baseItems[Types.PItem(item)^.itemType].slot = 2 then begin
    case Types.PItem(item)^.weight of
      0..150:
        Types.PCharacter(character)^.currentMovement := Types.PCharacter(character)^.baseMovement;
      151..399:
        Types.PCharacter(character)^.currentMovement := 9
    else
      Types.PCharacter(character)^.currentMovement := 6
    end;
    if Types.PItem(item)^.plus <> 0 then
      if Types.PCharacter(character)^.currentMovement <= 9 then
        Types.PCharacter(character)^.currentMovement := Types.PCharacter(character)^.currentMovement + 3
  end
end;

{ Folds one readied item into the armor-class adjustments. Only an item whose base armor value has bit 7 set counts; the
  low seven bits are its own armor class. A shield sets the shield slot to its armor class plus its plus. An item with
  armor class 0 adds its save bonus to the creature's and its plus to the slot of armor-class-0 items, except a ring,
  which raises the best-ring slot to its plus. Any other item keeps the best armor class plus plus in the armor slot,
  marking magical body armor when that new best is body armor with a positive plus.
  @param(character The creature.)
  @param(item The item.)
  @param(adjustments The adjustments: 0 Dexterity, 1 shield, 2 pluses of armor-class-0 items, 3 best ring, 4 best
    armor.)
  @param(magicBody Set when the best armor becomes magical body armor.) }
procedure AddItemArmorAdjust(character, item: Pointer; var adjustments; var magicBody: Byte);
var
  points: Byte;
  slot: Byte;
begin
  points := GDVars.baseItems[Types.PItem(item)^.itemType].armorBonus;
  if points > $7F then begin
    points := points and $7F;
    slot := GDVars.baseItems[Types.PItem(item)^.itemType].slot;
    if slot = 1 then
      TArmorAdjustments(adjustments)[1] := points + Types.PItem(item)^.plus
    else if points = 0 then begin
      if slot = 9 then begin
        if Types.PItem(item)^.plus > TArmorAdjustments(adjustments)[3] then
          TArmorAdjustments(adjustments)[3] := Types.PItem(item)^.plus
      end else
        TArmorAdjustments(adjustments)[2] := TArmorAdjustments(adjustments)[2] + Types.PItem(item)^.plus;
      Types.PCharacter(character)^.saveBonus := Types.PCharacter(character)^.saveBonus +
          Types.PItem(item)^.saveBonus
    end else begin
      if points + Types.PItem(item)^.plus > TArmorAdjustments(adjustments)[4] then begin
        TArmorAdjustments(adjustments)[4] := points + Types.PItem(item)^.plus;
        if Types.PItem(item)^.plus > 0 then
          if slot = 2 then
            magicBody := 1
      end
    end
  end
end;

{ Lowers a creature's movement for the coins it carries past its weight allowance: up to 512 over changes nothing, and
  each further band of 256 steps down to 9, 6 and 3. The movement is only ever lowered.
  @param(character The creature.) }
procedure EncumbranceAdjust(character: Types.PCharacter);
var excess: Integer;
    movement: Byte;
begin
  excess := Types.PCharacter(character)^.encumbrance - CharHlp.WeightAllowance(character);
  if excess < 0 then
    excess := 0;
  case excess of
    0..512:
      movement := Types.PCharacter(character)^.currentMovement;
    513..768:
      movement := 9;
    769..1024:
      movement := 6
  else
    movement := 3
  end;
  if movement < Types.PCharacter(character)^.currentMovement then
    Types.PCharacter(character)^.currentMovement := movement
end;

procedure PrintItemString(character, item: Pointer; column, row: Byte; inventory, draw: Boolean);
var
  part: Byte;
  mask: Byte;
  effect: Pointer;
  found: Boolean;
  pluralAdded: Boolean;
  candidate: Types.PCharacter;
begin
  Types.PItem(item)^.name := '';
  if inventory then begin
    if Types.PItem(item)^.equipped <> 0 then
      Types.PItem(item)^.name := GDConsts.equippedText
    else
      Types.PItem(item)^.name := GDConsts.unequippedText
  end;
  found := False;
  candidate := GDVars.partyHead;
  while (candidate <> nil) and (not found) do begin
    if CharHlp.HasEffect(candidate, C_Effect.DETECT_MAGIC, effect) then
      found := True;
    candidate := candidate^.next
  end;
  if found then
    if (Types.PItem(item)^.plus > 0) or (Types.PItem(item)^.saveBonus > 0) or
        (Types.PItem(item)^.cursed <> 0) then
      Types.PItem(item)^.name := Types.PItem(item)^.name + '*' + ' ';
  if Types.PItem(item)^.quantity > 0 then
    Types.PItem(item)^.name := Types.PItem(item)^.name +
        CharHlp.ByteToString(Types.PItem(item)^.quantity) + ' ';
  mask := 0;
  for part := 1 to 3 do
    if Types.PItem(item)^.nameIds[part] <> 0 then
      if (Types.PItem(item)^.unidentifiedMask shr (3 - part)) and $01 = 0 then
        Inc(mask, 1 shl (part - 1));
  pluralAdded := False;
  for part := 3 downto 1 do
    if (mask shr (part - 1)) and $01 > 0 then begin
      Types.PItem(item)^.name := Types.PItem(item)^.name +
          GDConsts.itemNameParts[Types.PItem(item)^.nameIds[part]];
      if (Types.PItem(item)^.quantity < 2) or pluralAdded then
        Types.PItem(item)^.name := Types.PItem(item)^.name + ' '
      else if ((1 shl (part - 1)) = mask) or
        ((part = 1) and (mask > 4) and (Types.PItem(item)^.itemType <> 55)) or
        ((part = 2) and not Odd(mask)) or ((part = 3) and (Types.PItem(item)^.itemType = 55)) or
        (((Types.PItem(item)^.itemType = 30) or (Types.PItem(item)^.itemType = 5) or
          (Types.PItem(item)^.itemType = 12)) and (Types.PItem(item)^.nameIds[3] <> 93)) then begin
        Types.PItem(item)^.name := Types.PItem(item)^.name + 's ';
        pluralAdded := True
      end else
        Types.PItem(item)^.name := Types.PItem(item)^.name + ' '
    end;
  if draw then
    TextRend.DisplayString(column, row, LightGreen, Black, Types.PItem(item)^.name)
end;

procedure DisplayParty(highlight: Types.PCharacter);
var character: Types.PCharacter;
    column: Byte;
    row: Byte;
    shift: Byte;
begin
  if ((GDVars.interfaceState = C_Ifc.OVERLAND) and (GDVars.zone0^.wildOn = 1)) or
      (GDVars.bigPictureShown <> 0) then
    Exit;
  if GDVars.interfaceState = C_Ifc.MAIN_MENU then
    column := 1
  else
    column := 17;
  GDVars.partyPanelLeft := column;
  GDVars.partyPanelTop := 4;
  GDVars.partyPanelRight := 38;
  GDVars.partyPanelBottom := 3;
  row := 2;
  TextRend.DisplayString(column, row, White, Black, GDConsts.nameHeader);
  TextRend.DisplayString(33, row, White, Black, GDConsts.statsHeader);
  Inc(row, 2);
  character := GDVars.partyHead;
  while character <> nil do begin
    Inc(GDVars.partyPanelBottom);
    Border.ClearBox(column, row, 38, row);
    if character = highlight then
      TextRend.DisplayString(column, row, White, Black, character^.name)
    else
      CharHlp.DisplayCreatureName(character, column, row, False);
    case character^.armorClass of
      0..50: shift := 1;
      51..60: shift := 2;
      61..69: shift := 1
    else shift := 0
    end;
    CharHlp.PrintArmorClass(character, shift + 32, row);
    case character^.hitPoints of
      0..9: shift := 2;
      10..99: shift := 1
    else shift := 0
    end;
    CharHlp.PrintHitPoints(character, shift + 36, row, False, False);
    Inc(row);
    character := character^.next
  end;
  Border.ClearBox(column, row, 38, row)
end;

procedure DisplayRoster(highlight: Types.PCharacter; clearHighlight: Boolean);
var character: Types.PCharacter;
    { Unused in this version; see the other implementations of this routine. }
    numberText: array[1..4] of Byte;
    column: Byte;
    row: Byte;
    shift: Byte;
begin
  if ((GDVars.interfaceState = C_Ifc.OVERLAND) and (GDVars.zone0^.wildOn = 1)) or
      (GDVars.bigPictureShown <> 0) then
    Exit;
  if GDVars.highlightedCharacter = nil then
    GDVars.highlightedCharacter := highlight;
  if GDVars.interfaceState = C_Ifc.MAIN_MENU then
    column := 1
  else
    column := 17;
  GDVars.partyPanelLeft := column;
  GDVars.partyPanelTop := 4;
  GDVars.partyPanelRight := 38;
  GDVars.partyPanelBottom := 3;
  row := 4;
  character := GDVars.partyHead;
  while character <> nil do begin
    Inc(GDVars.partyPanelBottom);
    if character = GDVars.highlightedCharacter then begin
      if clearHighlight then
        TextRend.DisplayString(column, row, White, Black, character^.name)
      else
        CharHlp.DisplayCreatureName(character, column, row, False);
      case character^.armorClass of
        0..50: shift := 1;
        51..60: shift := 2;
        61..69: shift := 1
      else shift := 0
      end;
      CharHlp.PrintArmorClass(character, shift + 32, row);
      case character^.hitPoints of
        0..9: shift := 2;
        10..99: shift := 1
      else shift := 0
      end;
      CharHlp.PrintHitPoints(character, shift + 36, row, False, False)
    end;
    Inc(row);
    character := character^.next
  end;
  Border.ClearBox(column, row, 38, row);
  GDVars.highlightedCharacter := nil
end;

procedure PrintArmorClass(character: Types.PCharacter; column, row: Byte);
var value: String;
    { Unused in this version; see the other implementations of this routine. }
    color: Byte;
begin
  value := CharHlp.ByteToString(Abs(Types.PCharacter(character)^.armorClass - 60));
  if Types.PCharacter(character)^.armorClass > 60 then
    value := '-' + value;
  TextRend.DisplayString(column, row, LightGreen, Black, value)
end;

procedure PrintHitPoints(character: Types.PCharacter; column, row: Byte; hotPink, showMax: Boolean);
var value: String;
    color: Byte;
    textLength: ShortInt;
begin
  if Types.PCharacter(character)^.hitPoints < Types.PCharacter(character)^.maxHitPoints then
    color := Yellow
  else
    color := LightGreen;
  if hotPink then
    color := LightMagenta;
  value := CharHlp.ByteToString(Types.PCharacter(character)^.hitPoints);
  TextRend.DisplayString(column, row, color, Black, value);
  if showMax then begin
    textLength := Length(value);
    TextRend.DisplayString(column + textLength, row, LightGreen, Black,
                           '/' + CharHlp.ByteToString(Types.PCharacter(character)^.maxHitPoints))
  end
end;

procedure CombatPrintCreatureInfo(character: Types.PCharacter);
var
  { Unused in this version; see the other implementations of this routine. }
  column: Byte;
  row: Byte;
begin
  if GDVars.combatInfoDirty <> 0 then begin
    GDVars.combatInfoDirty := 0;
    Border.ClearBox(23, 1, 38, 21);
    row := 1;
    CharHlp.PrintCreatureMessage(character, ' ', row, False);
    Inc(row);
    TextRend.DisplayString(23, row + 1, LightGreen, Black, GDConsts.hitPointsHeader);
    CharHlp.PrintHitPoints(character, 33, row + 1, False, False);
    Inc(row, 2);
    TextRend.DisplayString(23, row + 1, LightGreen, Black, GDConsts.armorClassHeader);
    CharHlp.PrintArmorClass(character, 26, row + 1);
    GDVars.currentRow := row + 1;
    if Types.PCharacter(character)^.equipped[0] <> nil then begin
      Inc(row, 2);
      column := 23;
      CharHlp.PrintItemString(character, Types.PCharacter(character)^.equipped[0], 0, 0, False, False);
      TextRend.DisplayMessageWindow(23, row + 1, 38, row + 1 + 1 + 1, LightGreen, Black, True,
                                    Types.PCharacter(character)^.equipped[0]^.name)
    end;
    row := GDVars.currentRow + 1;
    if Types.PCharacter(character)^.enabled = 0 then
      TextRend.DisplayString(23, row + 1, White, Black,
                             GDConsts.statusNames[ShortInt(Types.PCharacter(character)^.status)])
    else if CharHlp.IsHelpless(character) then
      TextRend.DisplayString(23, row + 1, White, Black, GDConsts.helplessText)
    else if Types.PCharacter(character)^.combat^.spellCast > 0 then
      TextRend.DisplayString(23, row + 1, White, Black, GDConsts.castingText)
  end
end;

function IsHelpless(character: Types.PCharacter): Boolean;
var index: Byte;
    effect: Pointer;
begin
  IsHelpless := False;
  for index := 1 to 3 do
    if CharHlp.HasEffect(character, GDConsts.helplessEffects[index], effect) then
      IsHelpless := True
end;

procedure RecalcStats(character: Types.PCharacter);
var copyIndex: Byte;
    adjustIndex: ShortInt;
    item: Types.PItem;
    magicBody: Byte;
    { Unused in this version; see the other implementations of this routine. }
    bag: Boolean;
    adjustments: TArmorAdjustments;
    equippedIndex: ShortInt;
    { Unused in this version; see the other implementations of this routine. }
    propertySlot: Byte;
    coinIndex: ShortInt;
    itemWeight: Word;
    slot: Byte;
    { Unused in this version; see the other implementations of this routine. }
    weight: array[1..3] of Byte;
begin
  for equippedIndex := 0 to 12 do
    Types.PCharacter(character)^.equipped[equippedIndex] := nil;
  bag := False;
  Types.PCharacter(character)^.numberOfItems := 0;
  item := Types.PCharacter(character)^.items;
  Types.PCharacter(character)^.handsEquipped := 0;
  Types.PCharacter(character)^.encumbrance := 0;
  GDVars.equippedWeight := 0;
  while item <> nil do begin
    Inc(Types.PCharacter(character)^.numberOfItems);
    itemWeight := item^.weight;
    if item^.quantity > 0 then
      itemWeight := item^.quantity * itemWeight;
    Inc(Types.PCharacter(character)^.encumbrance, itemWeight);
    if item^.equipped <> 0 then begin
      Inc(GDVars.equippedWeight, itemWeight);
      slot := GDVars.baseItems[item^.itemType].slot;
      case slot of
        0..8: Types.PCharacter(character)^.equipped[ShortInt(slot)] := item;
        9: if Types.PCharacter(character)^.equipped[9] <> nil then begin
            if Types.PCharacter(character)^.equipped[10] = nil then
              Types.PCharacter(character)^.equipped[10] := item
          end else
            Types.PCharacter(character)^.equipped[9] := item
      end;
      if item^.itemType = 30 then
        Types.PCharacter(character)^.equipped[11] := item;
      if item^.itemType = 12 then
        Types.PCharacter(character)^.equipped[12] := item;
      Types.PCharacter(character)^.handsEquipped := Types.PCharacter(character)^.handsEquipped +
          GDVars.baseItems[item^.itemType].hands
    end;
    item := item^.next
  end;
  for coinIndex := 4 to 6 do
    Types.PCharacter(character)^.encumbrance := Types.PCharacter(character)^.encumbrance +
        Types.PCharacter(character)^.coins[coinIndex];
  for copyIndex := 1 to 2 do begin
    Types.PCharacter(character)^.currentRolls[copyIndex] := Types.PCharacter(character)^.unarmedRolls[copyIndex];
    Types.PCharacter(character)^.currentDice[copyIndex] := Types.PCharacter(character)^.unarmedDice[copyIndex];
    Types.PCharacter(character)^.currentModifiers[copyIndex] :=
      Types.PCharacter(character)^.unarmedModifiers[copyIndex]
  end;
  FillChar(adjustments, SizeOf(adjustments), 0);
  magicBody := 0;
  Types.PCharacter(character)^.saveBonus := 0;
  Types.PCharacter(character)^.armorClass := Types.PCharacter(character)^.baseArmorClass;
  Types.PCharacter(character)^.currentMovement := Types.PCharacter(character)^.baseMovement;
  Types.PCharacter(character)^.thac0Adjusted := Types.PCharacter(character)^.thac0Base;
  adjustments[0] := CharHlp.DexterityArmorAdjustment(character);
  if Types.PCharacter(character)^.equipped[0] = nil then begin
    Types.PCharacter(character)^.thac0Adjusted := CharHlp.StrToHitAdjust(character) +
        Types.PCharacter(character)^.thac0Adjusted;
    Types.PCharacter(character)^.currentModifiers[1] :=
      CharHlp.StrDamageAdjust(character) + Types.PCharacter(character)^.currentModifiers[1]
  end;
  CharHlp.WeaponAdjust(character);
  item := Types.PCharacter(character)^.items;
  while item <> nil do begin
    if item^.equipped <> 0 then begin
      CharHlp.ArmorMoveAdjust(character, item);
      CharHlp.AddItemArmorAdjust(character, item, adjustments, magicBody)
    end;
    item := item^.next
  end;
  if magicBody <> 0 then
    adjustments[3] := 0;
  Types.PCharacter(character)^.currentMovement := CharHlp.RecalcMovement(character) div 2;
  if adjustments[4] < Types.PCharacter(character)^.armorClass then
    adjustments[4] := Types.PCharacter(character)^.armorClass;
  Types.PCharacter(character)^.armorClass := 0;
  for adjustIndex := 4 downto 0 do
    Types.PCharacter(character)^.armorClass := Types.PCharacter(character)^.armorClass + adjustments[adjustIndex];
  Types.PCharacter(character)^.rearArmorClass := adjustments[4] + adjustments[2] + adjustments[3] - 1 - 1
end;

function RecalcMovement(character: Types.PCharacter): Byte;
var item: Types.PItem;
    effect: Pointer;
begin
  Types.PCharacter(character)^.currentMovement := Types.PCharacter(character)^.baseMovement;
  item := Types.PCharacter(character)^.items;
  while item <> nil do begin
    if item^.equipped <> 0 then
      CharHlp.ArmorMoveAdjust(character, item);
    item := item^.next
  end;
  CharHlp.EncumbranceAdjust(character);
  if CharHlp.HasEffect(character, C_Effect.HASTED, effect) then
    Types.PCharacter(character)^.currentMovement := Types.PCharacter(character)^.currentMovement * 2;
  if CharHlp.HasEffect(character, C_Effect.SLOWED, effect) then
    Types.PCharacter(character)^.currentMovement := Types.PCharacter(character)^.currentMovement div 2;
  if CharHlp.HasEffect(character, C_Effect.MAGIC_BOOTS, effect) then
    Types.PCharacter(character)^.currentMovement := Types.PCharacter(character)^.currentMovement * 2;
  GDVars.movementRate := Types.PCharacter(character)^.currentMovement;
  if Types.PCharacter(character)^.side = C_Side.PLAYER then
    GDVars.movementRate := GDVars.movementRate + GDVars.zone1^.modPartyMove[GDConsts.modPartyMoveIndex + $7C00];
  GDVars.movementRate := GDVars.movementRate * 2;
  RecalcMovement := GDVars.movementRate
end;

function ByteToString(value: Byte): String;
var resultText: String;
begin
  Str(value, resultText);
  ByteToString := resultText
end;

function WordToString(value: Word): String;
var resultText: String;
begin
  Str(value, resultText);
  WordToString := resultText
end;

function LongIntToString(value: LongInt): String;
var resultText: String;
begin
  Str(value, resultText);
  LongIntToString := resultText
end;

{ Computes the Dexterity defensive adjustment from the current Dexterity: -4 at 1..3, -3..-1 at 4..6, +1..+4 at 15..18,
  4 at 19..20, 5 at 21..23, 6 at 24..25, else 0.
  @param(character The creature.)
  @returns(The adjustment.) }
function DexterityArmorAdjustment(character: Types.PCharacter): ShortInt;
var dexterity: Byte;
begin
  dexterity := Types.PCharacter(character)^.stats[C_Stat.DEXTERITY].current;
  case dexterity of
    1..3: DexterityArmorAdjustment := -4;
    4..6: DexterityArmorAdjustment := dexterity - 7;
    15..18: DexterityArmorAdjustment := dexterity - 14;
    19..20: DexterityArmorAdjustment := 4;
    21..23: DexterityArmorAdjustment := 5;
    24..25: DexterityArmorAdjustment := 6
  else
    DexterityArmorAdjustment := 0
  end
end;

function DexMissileAdjust(character: Types.PCharacter): ShortInt;
var dexterity: Byte;
begin
  dexterity := Types.PCharacter(character)^.stats[C_Stat.DEXTERITY].current;
  case dexterity of
    0..2: DexMissileAdjust := -4;
    3..5: DexMissileAdjust := dexterity - 6;
    16..18: DexMissileAdjust := dexterity - 15;
    19..20: DexMissileAdjust := 3;
    21..23: DexMissileAdjust := 4;
    24..25: DexMissileAdjust := 5
  else
    DexMissileAdjust := 0
  end
end;

{ Converts Strength to one scale: 0..17 as is; 18 by exceptional Strength (without it 18, 01-50 19, 51-75 20, 76-90 21,
  91-99 22, 00 23); 19..25 become 24..30. Note: other values leave the result undefined.
  @param(character The creature.)
  @returns(Strength on that scale.) }
function TranslatedStrength(character: Types.PCharacter): Byte;
begin
  case Types.PCharacter(character)^.stats[C_Stat.STRENGTH].current of
    0..17: TranslatedStrength := Types.PCharacter(character)^.stats[C_Stat.STRENGTH].current;
    18: case Types.PCharacter(character)^.exceptionalStrength of
         0: TranslatedStrength := 18;
         1..50: TranslatedStrength := 19;
         51..75: TranslatedStrength := 20;
         76..90: TranslatedStrength := 21;
         91..99: TranslatedStrength := 22;
         100: TranslatedStrength := 23
       end;
    19..25: TranslatedStrength := Types.PCharacter(character)^.stats[C_Stat.STRENGTH].current + 5
  end
end;

function StrToHitAdjust(character: Types.PCharacter): ShortInt;
var strength: Byte;
begin
  StrToHitAdjust := 0;
  strength := CharHlp.TranslatedStrength(character);
  if Types.PCharacter(character)^.strengthBonusEnabled <> 0 then
    case strength of
      1..3: StrToHitAdjust := -3;
      4..5: StrToHitAdjust := -2;
      6..7: StrToHitAdjust := -1;
      17..19: StrToHitAdjust := 1;
      20..22: StrToHitAdjust := 2;
      23..25: StrToHitAdjust := 3;
      26..27: StrToHitAdjust := 4;
      28..30: StrToHitAdjust := strength - 23
    end
end;

function StrDamageAdjust(character: Types.PCharacter): ShortInt;
var strength: Byte;
begin
  StrDamageAdjust := 0;
  strength := CharHlp.TranslatedStrength(character);
  if Types.PCharacter(character)^.strengthBonusEnabled <> 0 then
    case strength of
      1..2: StrDamageAdjust := -2;
      3..5: StrDamageAdjust := -1;
      16: StrDamageAdjust := 1;
      17..19: StrDamageAdjust := strength - 16;
      20..29: StrDamageAdjust := strength - 17;
      30: StrDamageAdjust := 14
    end
end;

function WeightAllowance(character: Types.PCharacter): Integer;
var strength: Byte;
begin
  strength := CharHlp.TranslatedStrength(character);
  case strength of
    1..3: WeightAllowance := -350;
    4..5: WeightAllowance := -250;
    6..7: WeightAllowance := -150;
    12..13: WeightAllowance := 100;
    14..15: WeightAllowance := 200;
    16: WeightAllowance := 350;
    17..21: WeightAllowance := (strength - 17) * 250 + 500;
    22..26: WeightAllowance := (strength - 22) * 1000 + 2000;
    27: WeightAllowance := 7500;
    28..30: WeightAllowance := (strength - 28) * 3000 + 9000
  else
    WeightAllowance := 0
  end
end;

procedure RemoveSpell(character: Types.PCharacter; spellId: Byte);
var index: Byte;
begin
  if Types.PCharacter(character)^.spells = nil then
    Exit;
  index := 0;
  while index <= 73 do begin
    if Types.PCharacter(character)^.spells^.memorized[index] = spellId then begin
      Types.PCharacter(character)^.spells^.memorized[index] := spellId or $80;
      index := 74
    end;
    Inc(index)
  end
end;

procedure RemoveItem(character: Types.PCharacter; item: Types.PItem);
var current: Types.PItem;
begin
  if item = nil then
    TextRend.DisplayAndPause(Yellow, Black, GDConsts.nilItemText)
  else begin
    current := Types.PCharacter(character)^.items;
    if current = item then
      Types.PCharacter(character)^.items := item^.next
    else
      while (current <> nil) and (current^.next <> item) do
        current := current^.next;
    if current = nil then
      TextRend.DisplayAndPause(Yellow, Black, GDConsts.missingItemText)
    else begin
      current^.next := item^.next;
      item^.next := nil;
      GameIo.FreeSlot(item)
    end
  end
end;

procedure AddItemCopy(character: Types.PCharacter; item: Types.PItem);
var
  current: Types.PItem;
  newItem: Types.PItem;
begin
  if (GDVars.interfaceState = C_Ifc.IN_COMBAT) and (Types.PCharacter(character)^.combat <> nil) and
      (Types.PCharacter(character)^.combat^.notPcNpc = 1) then
    GetMem(newItem, SizeOf(Types.TItem))
  else
    newItem := GameIo.AllocSlot;
  Move(item^, newItem^, SizeOf(Types.TItem));
  newItem^.next := nil;
  current := Types.PCharacter(character)^.items;
  if current = nil then
    Types.PCharacter(character)^.items := newItem
  else begin
    while current^.next <> nil do
      current := current^.next;
    current^.next := newItem
  end
end;

procedure PrintBottomLine(message: Types.TString40);
begin
  Border.ClearBox(0, 24, 39, 24);
  TextRend.DisplayString(0, 24, LightGreen, Black, message);
  TextRend.PauseOnly;
  Border.ClearBox(0, 24, 39, 24)
end;

procedure PrintCreatureMessage(character: Types.PCharacter; message: String; row: Byte; pause: Boolean);
var column: Byte;
begin
  if GDVars.interfaceState = C_Ifc.IN_COMBAT then begin
    Border.ClearBox(23, row, 38, 21);
    CharHlp.DisplayCreatureName(character, 23, row, False);
    TextRend.DisplayMessageWindow(23, row + 1, 38, 21, LightGreen, Black, True, message)
  end else begin
    if GDVars.noBorder <> 0 then
      column := 18
    else
      column := 17;
    Border.ClearBox(1, column, 38, 22);
    CharHlp.DisplayCreatureName(character, 1, column + 1, False);
    TextRend.DisplayMessageWindow(1, column + 2, 38, 22, LightGreen, Black, True, message)
  end;
  if pause then begin
    TextRend.PauseOnly;
    CharHlp.ClearMessageWindow
  end
end;

procedure ClearMessageWindow;
begin
  if GDVars.interfaceState = C_Ifc.IN_COMBAT then
    Border.ClearBox(23, 10, 38, 21)
  else
    Border.ClearBox(1, 18, 38, 22)
end;

procedure DisplayCreatureName(character: Types.PCharacter; column, row: Byte; tail: Boolean);
var color: Byte;
begin
  if Types.PCharacter(character)^.enabled = 0 then
    color := LightRed
  else if (Types.PCharacter(character)^.side = C_Side.ENEMY) and
    (GDVars.interfaceState = C_Ifc.IN_COMBAT) then
    color := Yellow
  else if Types.PCharacter(character)^.levelUpReady <> 0 then
    color := LightMagenta
  else
    color := LightCyan;
  TextRend.DisplayString(column, row, color, Black, Types.PCharacter(character)^.name);
  if tail then
    TextRend.DisplayString(column + Length(Types.PCharacter(character)^.name), row, color, Black, '''s')
end;

procedure CopyIconFacing(cell, half, row: Byte; mirror: Boolean);
var temporary: Types.PImgBuf;
    stride: Word;
begin
  stride := GDVars.movingIcon^.imgSize;
  if mirror then begin
    Blit.AllocPic(24, 3, 1, GDConsts.iconFrame, temporary);
    Blit.MirrorPic(GDVars.iconAnimations[cell, half], temporary);
    Move(temporary^.data, GDVars.movingIcon^.data[row * stride], stride);
    Move(temporary^.transp^, GDVars.movingIcon^.transp^[row * stride], stride);
    Blit.FreePic(temporary)
  end else begin
    Move(GDVars.iconAnimations[cell, half]^.data, GDVars.movingIcon^.data[row * stride], stride);
    Move(GDVars.iconAnimations[cell, half]^.transp^, GDVars.movingIcon^.transp^[row * stride], stride)
  end
end;

procedure BuildIconFacings(cell: Byte);
begin
  CharHlp.CopyIconFacing(cell, 0, 0, False);
  CharHlp.CopyIconFacing(cell, 0, 1, True);
  CharHlp.CopyIconFacing(cell, 1, 2, True);
  CharHlp.CopyIconFacing(cell, 1, 3, False)
end;

procedure CombatAnimateMovingIcon(startX, startY, endX, endY: Integer; frames, pace: Byte);
var path: array[0..147] of Byte;
    walk: Types.TPathReq;
    { Unused in this version; see the other implementations of this routine. }
    boltLength: Integer;
    pathIndex: Byte;
    pathCount: Byte;
    frameIndex: Byte;
    { Unused in this version; see the other implementations of this routine. }
    lastFrame: Byte;
    lastPass: Boolean;
    done: Boolean;
    cameraX: Integer;
    cameraY: Integer;
    { Unused in this version; see the other implementations of this routine. }
    previousX: Integer;
    { Unused in this version; see the other implementations of this routine. }
    previousY: Integer;
    accumulatorX: Integer;
    accumulatorY: Integer;
    differenceX: Integer;
    differenceY: Integer;
    stepX: Integer;
    stepY: Integer;
    pixelX: Integer;
    pixelY: Integer;
    overshootX: Integer;
    overshootY: Integer;

  { Clamps an arena position to the 50x25 arena. }
  procedure ClampIconPosition(var x, y: Integer);
  begin
    if x < 0 then
      x := 0
    else if x > 49 then
      x := 49;
    if y < 0 then
      y := 0
    else if y > 24 then
      y := 24
  end;
begin
  ClampIconPosition(startX, startY);
  ClampIconPosition(endX, endY);
  previousX := startX;
  previousY := startY;
  FillChar(path, SizeOf(path), 8);
  FillChar(walk, SizeOf(walk), 0);
  pathIndex := 0;
  frameIndex := 0;
  walk.sx := startX * 3;
  walk.sy := startY * 3;
  walk.ex := endX * 3;
  walk.ey := endY * 3;
  Pathing.PathFind(walk);
  repeat
    done := not Pathing.NextPathStep(walk);
    path[pathIndex] := walk.step;
    Inc(pathIndex)
  until done;
  if pathIndex < 4 then Exit;
  pathCount := pathIndex - 2;
  differenceX := endX - startX;
  differenceY := endY - startY;
  if not CbtMap.ViewCoordsValid(startX - GDVars.arena^.ox, startY - GDVars.arena^.oy) or
      not CbtMap.ViewCoordsValid(endX - GDVars.arena^.ox, endY - GDVars.arena^.oy) then begin
    if (Abs(differenceX) <= 6) and (Abs(differenceY) <= 6) then begin
      lastPass := True;
      cameraX := startX + differenceX div 2;
      cameraY := startY + differenceY div 2
    end else begin
      lastPass := False;
      cameraX := GDVars.arena^.ox + 3;
      cameraY := GDVars.arena^.oy + 3
    end
  end else begin
    lastPass := True;
    cameraX := GDVars.arena^.ox + 3;
    cameraY := GDVars.arena^.oy + 3
  end;
  CbtMap.ScrollView(Byte(cameraX), Byte(cameraY), 255, C_Dir.CENTER);
  pathIndex := 0;
  accumulatorX := 0;
  accumulatorY := 0;
  repeat
    pixelX := (startX - GDVars.arena^.ox) * 3 + accumulatorX;
    pixelY := (startY - GDVars.arena^.oy) * 3 + accumulatorY;
    previousX := startX;
    previousY := startY;
    done := False;
    repeat
      stepX := GDConsts.directionX[path[pathIndex]];
      stepY := GDConsts.directionY[path[pathIndex]];
      Inc(pixelX, stepX);
      Inc(pixelY, stepY);
      if (pace > 0) or (pixelX mod 3 = 0) or (pixelY mod 3 = 0) then begin
        Blit.BlitTileClipped(pixelX, pixelY, frameIndex, GDConsts.saveUnderBit + GDConsts.iconFrame,
                             GDVars.movingIcon, GDVars.compositeBuffer);
        Blit.FlushView;
        Delay(pace);
        Blit.BlitTileClipped(pixelX, pixelY, 0, GDConsts.pictureMode, GDVars.saveUnder, GDVars.compositeBuffer);
        Inc(frameIndex);
        if frameIndex >= frames then frameIndex := 0
      end;
      Inc(pathIndex);
      if (pixelX < 0) or (pixelX > 18) or (pixelY < 0) or (pixelY > 18) then done := True;
      if (not done) and (pathIndex < pathCount) then begin
        Inc(accumulatorX, stepX);
        Inc(accumulatorY, stepY);
        if Abs(accumulatorX) = 3 then begin
          Inc(startX, Pathing.SignOf(accumulatorX));
          Inc(cameraX, Pathing.SignOf(accumulatorX));
          accumulatorX := 0
        end;
        if Abs(accumulatorY) = 3 then begin
          Inc(startY, Pathing.SignOf(accumulatorY));
          Inc(cameraY, Pathing.SignOf(accumulatorY));
          accumulatorY := 0
        end
      end
    until (pathIndex >= pathCount) or done;
    if pathIndex < pathCount then begin
      overshootX := 0;
      overshootY := 0;
      accumulatorY := 0;
      accumulatorX := 0;
      startX := endX;
      startY := endY;
      previousX := startX;
      previousY := startY;
      if endX + 3 > 49 then overshootX := endX - 49
      else if endX < 3 then overshootX := 3 - endX;
      if endY + 3 > 24 then overshootY := endY - 24
      else if endY < 3 then overshootY := 3 - endY;
      cameraX := endX + overshootX;
      cameraY := endY + overshootY;
      CbtMap.ScrollView(Byte(cameraX), Byte(cameraY), 255, C_Dir.CENTER);
      pixelX := (endX - GDVars.arena^.ox) * 3;
      pixelY := (endY - GDVars.arena^.oy) * 3;
      pathIndex := pathCount;
      done := False;
      repeat
        stepX := -GDConsts.directionX[path[pathIndex]];
        stepY := -GDConsts.directionY[path[pathIndex]];
        Inc(pixelX, stepX);
        Inc(pixelY, stepY);
        if pixelX > 18 then startX := GDVars.arena^.ox + 6
        else if pixelX < 0 then startX := GDVars.arena^.ox;
        if pixelY > 18 then startY := GDVars.arena^.oy + 6
        else if pixelY < 0 then startY := GDVars.arena^.oy;
        if (pixelX < 0) or (pixelX > 18) or (pixelY < 0) or (pixelY > 18) then done := True;
        if not done then begin
          Inc(accumulatorX, stepX);
          Inc(accumulatorY, stepY);
          if Abs(accumulatorX) = 3 then begin
            Inc(startX, Pathing.SignOf(accumulatorX));
            Inc(cameraX, Pathing.SignOf(accumulatorX));
            accumulatorX := 0
          end;
          if Abs(accumulatorY) = 3 then begin
            Inc(startY, Pathing.SignOf(accumulatorY));
            Inc(cameraY, Pathing.SignOf(accumulatorY));
            accumulatorY := 0
          end;
          Dec(pathIndex)
        end
      until done
    end else begin
      lastPass := True;
      if not CbtMap.ViewCoordsValid(endX - GDVars.arena^.ox, endY - GDVars.arena^.oy) then
        CbtMap.ScrollView(Byte(endX), Byte(endY), 3, C_Dir.CENTER);
      pixelX := (endX - GDVars.arena^.ox) * 3;
      pixelY := (endY - GDVars.arena^.oy) * 3;
      Blit.BlitTileClipped(pixelX, pixelY, frameIndex, GDConsts.saveUnderBit + GDConsts.iconFrame, GDVars.movingIcon,
                           GDVars.compositeBuffer);
      if pace > 0 then begin
        Blit.FlushView;
        Delay(pace);
        Blit.BlitTileClipped(pixelX, pixelY, 0, GDConsts.pictureMode, GDVars.saveUnder, GDVars.compositeBuffer)
      end
    end
  until lastPass;
  Blit.FlushView
end;

procedure PrintNameStringAnim(character: Types.PCharacter; effect: Boolean; message: String);
var
  gridColumn: ShortInt;
  gridRow: ShortInt;
  cell: Byte;
  frame: Byte;
  repetition: Byte;
  repetitions: Byte;
begin
  if GDVars.interfaceState = C_Ifc.IN_COMBAT then begin
    if effect then
      cell := 22
    else
      cell := 24;
    CharHlp.BuildIconFacings(cell);
    if not CbtMap.CombatIconVisible(character, 1) then
      CbtMap.ScrollView(CbtMap.CombatCellX(character), CbtMap.CombatCellY(character), 3, C_Dir.CENTER);
    if effect then
      Music.SendSoundCommand(GDConsts.effectSound)
    else
      Music.SendSoundCommand(GDConsts.damageSound);
    CharHlp.PrintCreatureMessage(character, message, 10, False);
    if effect then
      repetitions := GDVars.textDelay
    else
      repetitions := 0;
    gridColumn := GDVars.gridX[CbtMap.CombatSlot(character)] * 3;
    gridRow := GDVars.gridY[CbtMap.CombatSlot(character)] * 3;
    for repetition := 0 to repetitions do
      for frame := 0 to 3 do begin
        Blit.BlitTileClipped(gridColumn, gridRow, frame, GDConsts.saveUnderBit + GDConsts.iconFrame,
                             GDVars.movingIcon, GDVars.compositeBuffer);
        Blit.FlushView;
        Delay(70);
        Blit.BlitTileClipped(gridColumn, gridRow, 0, GDConsts.pictureMode, GDVars.saveUnder, GDVars.compositeBuffer)
      end;
    Blit.FlushView;
    if repetitions = 0 then
      TextRend.PauseOnly
  end else
    CharHlp.PrintCreatureMessage(character, message, 10, True)
end;

function HasEffect(character: Pointer; effectId: Byte; var effect: Pointer): Boolean;
var found: Boolean;
begin
  found := False;
  effect := Types.PCharacter(character)^.effects;
  while (effect <> nil) and not found do begin
    if Types.PEffect(effect)^.effectId = effectId then
      found := True
    else
      effect := Types.PEffect(effect)^.next
  end;
  HasEffect := found
end;

procedure InflictDamage(character: Types.PCharacter; damage: Byte);
var
  overkill: Byte;
  remaining: Byte;
begin
  overkill := 0;
  remaining := 0;
  if Types.PCharacter(character)^.hitPoints >= damage then
    remaining := Types.PCharacter(character)^.hitPoints - damage
  else
    overkill := damage - Types.PCharacter(character)^.hitPoints;
  if (overkill > 9) or ((remaining = 0) and (Types.PCharacter(character)^.status = C_Status.ANIMATED)) then
    Types.PCharacter(character)^.status := C_Status.DEAD_STATUS
  else if overkill > 0 then begin
    Types.PCharacter(character)^.status := C_Status.DYING;
    if GDVars.interfaceState = C_Ifc.IN_COMBAT then
      Types.PCharacter(character)^.combat^.dyingTurns := overkill
  end else if remaining = 0 then
    Types.PCharacter(character)^.status := C_Status.UNCONSCIOUS;
  if not (Types.PCharacter(character)^.status in [C_Status.OKAY, C_Status.ANIMATED]) then begin
    Types.PCharacter(character)^.enabled := 0;
    Types.PCharacter(character)^.hitPoints := 0;
    if GDVars.interfaceState = C_Ifc.IN_COMBAT then begin
      Dec(GDVars.teamCount[Types.PCharacter(character)^.side]);
      Types.PCharacter(character)^.combat^.initiative := 0
    end
  end else
    Types.PCharacter(character)^.hitPoints := remaining
end;

procedure AnnounceHealStatus(character: Types.PCharacter);
var message: Types.TString40;
begin
  if Types.PCharacter(character)^.hitPoints = Types.PCharacter(character)^.maxHitPoints then
    message := GDConsts.fullyHealedText
  else
    message := GDConsts.partiallyHealedText;
  CharHlp.PrintCreatureMessage(character, message, 10, True);
  if GDVars.interfaceState <> C_Ifc.IN_COMBAT then
    CharHlp.DisplayRoster(character, character = Pointer(GDVars.currentCharacter))
end;

function EnemyTeam(character: Types.PCharacter): ShortInt;
begin
  if Types.PCharacter(character)^.side = C_Side.PLAYER then
    EnemyTeam := 1
  else
    EnemyTeam := 0
end;

procedure CountTeams;
var character: Types.PCharacter;
begin
  GDVars.teamCount[C_Side.PLAYER] := 0;
  GDVars.teamCount[C_Side.ENEMY] := 0;
  character := GDVars.partyHead;
  while character <> nil do begin
    if character^.enabled <> 0 then
      Inc(GDVars.teamCount[character^.side]);
    character := character^.next
  end
end;

function CountTargets(character: Types.PCharacter; range: Byte; sameSide: Boolean): Byte;
var
  numberTargets: Byte;
  numberMatching: Byte;
  index: Byte;
  effect: Pointer;
  found: Boolean;
  targetSide: ShortInt;
begin
  Pathing.BuildTargetList(CbtMap.CombatCellX(character), CbtMap.CombatCellY(character), range, GDConsts.anyDirection,
                          CbtMap.GetIconSize(character), GDVars.arena);
  numberTargets := GDVars.targetCount;
  numberMatching := 0;
  if sameSide then
    targetSide := Types.PCharacter(character)^.side
  else
    targetSide := CharHlp.EnemyTeam(character);
  if numberTargets > 0 then begin
    for index := 1 to numberTargets do
      if Types.PCharacter(GDVars.creatures[GDVars.targetList[index].characterIndex])^.side = targetSide then begin
        Inc(numberMatching);
        Move(GDVars.targetList[index], GDVars.targetList[numberMatching], SizeOf(Types.TTargetEntry))
      end;
    numberTargets := numberMatching;
    GDVars.targetCount := numberMatching
  end;
  CountTargets := numberTargets;
  for index := 1 to numberTargets do
    GDVars.targetIndices[index] := GDVars.targetList[index].characterIndex;
  if CharHlp.HasEffect(character, 91, effect) then begin
    index := 1;
    found := False;
    while (index <= numberTargets) and not found do begin
      if GDVars.creatures[GDVars.targetIndices[index]] = GDVars.yellTarget then begin
        numberMatching := GDVars.targetIndices[1];
        GDVars.targetIndices[1] := GDVars.targetIndices[index];
        GDVars.targetIndices[index] := numberMatching;
        found := True
      end;
      Inc(index)
    end
  end
end;

function CalcDistance(character, other: Types.PCharacter): Byte;
var savedTargets: array[1..255] of Types.TTargetEntry;
    index: Byte;
begin
  Move(GDVars.targetList, savedTargets, SizeOf(GDVars.targetList));
  GDVars.arena^.distMode := 1;
  Pathing.BuildTargetList(CbtMap.CombatCellX(character), CbtMap.CombatCellY(character), 255, GDConsts.anyDirection,
                          CbtMap.GetIconSize(character), GDVars.arena);
  GDVars.arena^.distMode := 0;
  index := 1;
  while (GDVars.creatures[GDVars.targetList[index].characterIndex] <> other) and (index < GDVars.targetCount) do
    Inc(index);
  CalcDistance := GDVars.targetList[index].distance div 2;
  Move(savedTargets, GDVars.targetList, SizeOf(GDVars.targetList))
end;

function EndActions(character: Types.PCharacter): Boolean;
begin
  Types.PCharacter(character)^.combat^.initiative := 0;
  Types.PCharacter(character)^.combat^.spellCast := 0;
  Types.PCharacter(character)^.combat^.guarding := 0;
  Types.PCharacter(character)^.combat^.movement := 0;
  EndActions := True
end;

function Guard(character: Types.PCharacter): Boolean;
begin
  Guard := CharHlp.EndActions(character);
  if Types.PCharacter(character)^.combat^.panicked = 0 then begin
    Types.PCharacter(character)^.combat^.guarding := 1;
    CharHlp.PrintBottomLine(GDConsts.guardingText)
  end
end;

function GetCasterLevel(spellId: Byte): Byte;
var
  priestLevel: Byte;
  paladinLevel: Byte;
  moonIndex: Integer;
  effect: Pointer;
begin
  with GDVars.currentCharacter^ do begin
  if (classLevels[C_Class.CLERIC] = 0) and (classLevels[C_Class.MAGE] = 0) and
      (classLevels[C_Class.KNIGHT] < 9) and (classLevels[C_Class.RANGER] < 8) then
    GetCasterLevel := 6
  else
    case GDConsts.spellTable[spellId].castClass of
      0, 2: if classLevels[C_Class.CLERIC] > classLevels[C_Class.KNIGHT] then
            GetCasterLevel := classLevels[C_Class.CLERIC]
          else
            GetCasterLevel := classLevels[C_Class.KNIGHT];
      1: if classLevels[C_Class.RANGER] > 7 then
          GetCasterLevel := Byte(classLevels[C_Class.RANGER]) - 7
        else
          GetCasterLevel := 0;
      3: begin
        priestLevel := GDVars.currentCharacter^.classLevels[C_Class.MAGE];
        paladinLevel := GDVars.currentCharacter^.classLevels[C_Class.RANGER];
        if (classLevels[C_Class.MAGE] > 0) and (GDVars.currentCharacter^.robeOrder > 0) then begin
          moonIndex := robeOrder + $1F8;
          case GDVars.zone0^.ecl[moonIndex + $4B00] of
            0: Dec(priestLevel);
            2: if classLevels[C_Class.MAGE] > 5 then
                Inc(priestLevel)
          end
        end;
        if priestLevel > paladinLevel then
          GetCasterLevel := priestLevel
        else
          GetCasterLevel := paladinLevel
      end;
      4: GetCasterLevel := 12
    end;
  end;
  if (spellId = C_Spell.FIREBALL) and
      CharHlp.HasEffect(GDVars.currentCharacter, C_Effect.STORED_FIREBALL, effect) then
    GetCasterLevel := 15;
  if (GDVars.usingItem <> 0) and (GDConsts.spellTable[spellId].castClass <> 4) then
    GetCasterLevel := 6
end;

procedure DisplayNoncombatInterface;
begin
  GDVars.forceMapRedraw := 1;
  case GDVars.interfaceState of
    C_Ifc.MAIN_MENU: Border.DrawWindowFrame(0);
    C_Ifc.IN_VAULT, C_Ifc.SHOP_TEMPLE: begin
      if GDVars.noncombatPrepared <> 0 then Border.DrawViewFrame;
      Portrait.DisplayImageBuf(3, 3, True, GDVars.portraitAnimation.frames[1].pic);
      CharHlp.DisplayParty(GDVars.currentCharacter);
      CharHlp.PrintMiscInfo;
      if GDVars.interfaceState = C_Ifc.IN_VAULT then
        TextRend.DisplayString(1, 15, LightGreen, Black, GDConsts.noncombatMessage)
    end;
    C_Ifc.CAMPING: begin
      Border.DrawViewFrame;
      Portrait.LoadAnimation('PIC', 59, GDConsts.pictureMode, GDVars.portraitAnimation);
      CharHlp.DisplayParty(GDVars.currentCharacter);
      CharHlp.PrintMiscInfo
    end;
    C_Ifc.VIEW_3D: begin
      Border.DrawViewFrame;
      MapView.DisplayMapView;
      CharHlp.DisplayParty(GDVars.currentCharacter);
      CharHlp.PrintMiscInfo;
      GDVars.noncombatRedrawState := 0
    end;
    C_Ifc.OVERLAND: if (GDVars.pictureArchiveId <> 9) and (GDVars.zone0^.wildOn = 1) then
        MapView.DisplayMapView;
    C_Ifc.LOOT: begin
      Border.DrawViewFrame;
      Portrait.LoadAnimation('PIC', 60, GDConsts.pictureMode, GDVars.portraitAnimation);
      CharHlp.DisplayParty(GDVars.currentCharacter)
    end
  end
end;

procedure PrintMiscInfo;
var
  savedX: Byte;
  savedY: Byte;
  hourText: Types.TString2;
  minuteText: Types.TString2;
  infoText: String[40];
begin
  if GDVars.interfaceState = C_Ifc.OVERLAND then Exit;
  infoText := '';
  savedX := GDVars.mapState.x;
  savedY := GDVars.mapState.y;
  hourText := CharHlp.ByteToString(GDVars.zone0^.clock[$4BC9]);
  if Length(hourText) < 2 then hourText := '0' + hourText;
  minuteText := CharHlp.ByteToString(GDVars.zone0^.clock[$4BC8] * 10 + GDVars.zone0^.clock[$4BC7]);
  if Length(minuteText) < 2 then minuteText := '0' + minuteText;
  if GDVars.zone0^.automapLock = 0 then
    infoText := CharHlp.ByteToString(savedX) + ',' + CharHlp.ByteToString(savedY) + ' ';
  infoText := infoText + GDConsts.directionNames[GDVars.mapState.facing] + ' ';
  infoText := infoText + hourText + ':' + minuteText;
  if GDVars.traceActive <> 0 then infoText := infoText + '*';
  if GDVars.interfaceState = C_Ifc.CAMPING then
    infoText := infoText + GDConsts.combatInfoText
  else if (GDVars.zone1^.searchFlags[GDConsts.searchFlagsIndex + $7C00] and GDConsts.searchMask[0]) > 0 then
    infoText := infoText + GDConsts.exploreInfoText;
  Border.ClearBox(17, 15, 38, 15);
  TextRend.DisplayString(17, 15, LightGreen, Black, infoText)
end;

procedure DisplayCombatInterface;
begin
  CbtMap.SetCombatPalette;
  Border.DrawCombatFrame;
  CbtMap.ScrollView(GDVars.arena^.ox + 3, GDVars.arena^.oy + 3, 255, C_Dir.CENTER)
end;

function HasRangedWeapon(character: Types.PCharacter): Boolean;
begin
  if (Types.PCharacter(character)^.equipped[0] <> nil) and
      (GDVars.baseItems[Types.PCharacter(character)^.equipped[0]^.itemType].range > 1)
  then
    HasRangedWeapon := True
  else
    HasRangedWeapon := False
end;

function HasReadiedHoopak(character: Types.PCharacter): Boolean;
begin
  if (Types.PCharacter(character)^.equipped[0] <> nil) and
      (Types.PCharacter(character)^.equipped[0]^.itemType = 67) then
    HasReadiedHoopak := True
  else
    HasReadiedHoopak := False
end;

function HasThrowableWeapon(character: Types.PCharacter): Boolean;
begin
  if CharHlp.HasRangedWeapon(character) and
      (((GDVars.baseItems[Types.PCharacter(character)^.equipped[0]^.itemType].flags and $14) = $14) or
       (Types.PCharacter(character)^.equipped[0]^.itemType = 67)) then
    HasThrowableWeapon := True
  else
    HasThrowableWeapon := False
end;

function FindDamagingRangedWeapon(character: Types.PCharacter; var selected: Types.PItem): Boolean;
var weapon: Types.PItem;
    properties: Byte;
begin
  FindDamagingRangedWeapon := False;
  weapon := Types.PCharacter(character)^.equipped[0];
  selected := nil;
  properties := 0;
  if weapon <> nil then begin
    properties := GDVars.baseItems[weapon^.itemType].flags;
    if (properties and $10) <> 0 then
      selected := weapon;
    if (properties and $08) <> 0 then begin
      if (properties and $01) <> 0 then
        selected := Types.PCharacter(character)^.equipped[11];
      if (properties and $80) <> 0 then
        selected := Types.PCharacter(character)^.equipped[12]
    end
  end;
  if (selected <> nil) or (properties = $0A) then
    FindDamagingRangedWeapon := True
end;

function BandageDying(apply: Boolean): Boolean;
var character: Types.PCharacter;
    found: Boolean;
begin
  found := False;
  character := GDVars.partyHead;
  while character <> nil do begin
    if (character^.combat^.notPcNpc = 0) and (character^.side = C_Side.PLAYER) and
        (character^.status = C_Status.DYING) then begin
      found := True;
      if apply then begin
        character^.status := C_Status.UNCONSCIOUS;
        character^.combat^.dyingTurns := 0;
        CharHlp.PrintCreatureMessage(character, GDConsts.bandageText, 10, True);
        apply := False
      end
    end;
    character := character^.next
  end;
  BandageDying := found
end;

procedure SelectChar(prompt: Types.TString40; allowNil: Boolean; mode: Byte; var selected: Pointer);
var
  pressedKey: Byte;
  key: Byte;
  { Unused in this version; see the other implementations of this routine. }
  reinterpret: Byte;
  highlight: Boolean;
  cursor: Types.PCharacter;
  savedMessage: Byte;
  savedState: Byte;
begin
  savedMessage := GDVars.mouseMode;
  GDVars.selectionMode := mode;
  GDVars.selectionCharacter := GDVars.currentCharacter;
  key := 255;
  savedState := GDVars.extendedMode;
  GDVars.extendedMode := 0;
  while (key >= 2) and (key <> Ord(C_Keys.ESCAPE)) do begin
    CharHlp.DisplayParty(selected);
    if (GDVars.interfaceState = C_Ifc.CAMPING) or (GDVars.interfaceState = C_Ifc.LOOT) then
      highlight := True
    else
      highlight := False;
    if GDVars.interfaceState = C_Ifc.MAIN_MENU then GDVars.mouseMode := 1;
    if allowNil then MenuCore.EnableChoices(1)
    else MenuCore.EnableChoices(0);
    key := MenuCore.MenuHorizontal(prompt + ' ', GDConsts.selectMenuText, 1, Byte(highlight));
    GDVars.mouseMode := savedMessage;
    cursor := selected;
    if GDVars.menuExtendedKey <> 0 then begin
      pressedKey := key;
      case pressedKey of
        Ord(C_Keys.ESCAPE): if allowNil then cursor := nil;
        Ord(C_Keys.DOWN): begin
          cursor := cursor^.next;
          if cursor = nil then cursor := GDVars.partyHead
        end;
        Ord(C_Keys.UP):
          if GDVars.mouseClick <> 0 then begin
            if GDVars.selectionMode <> 0 then
              cursor := GDVars.selectionCharacter
            else begin
              cursor := GDVars.mouseCharacter;
              GDVars.currentCharacter := GDVars.mouseCharacter
            end
          end else begin
            cursor := GDVars.partyHead;
            if selected <> GDVars.partyHead then begin
              while cursor^.next <> Types.PCharacter(selected) do
                cursor := cursor^.next
            end else begin
              while cursor^.next <> nil do cursor := cursor^.next
            end
          end
      end
    end else if allowNil and (key = 1) then
      cursor := nil;
    selected := cursor
  end;
  GDVars.extendedMode := savedState;
  GDVars.selectionMode := 0
end;

function DirTowardTarget(creature, other: Types.PCharacter): Byte;
var dir: Byte;
    found: Boolean;
    x1: Integer;
    y1: Integer;
    x2: Integer;
    y2: Integer;
    deltaX: Integer;
    deltaY: Integer;
begin
  x1 := CbtMap.CombatCellX(creature);
  y1 := CbtMap.CombatCellY(creature);
  x2 := CbtMap.CombatCellX(other);
  y2 := CbtMap.CombatCellY(other);
  deltaX := Abs(x2 - x1);
  deltaY := Abs(y2 - y1);
  dir := C_Dir.NORTH;
  found := False;
  while not found do begin
    case dir of
      C_Dir.NORTH: found := (y2 <= y1) and ((618 * deltaX) div 256 <= deltaY);
      C_Dir.EAST: found := (x2 >= x1) and ((106 * deltaX) div 256 >= deltaY);
      C_Dir.SOUTH: found := (y2 >= y1) and ((618 * deltaX) div 256 <= deltaY);
      C_Dir.WEST: found := (x2 <= x1) and ((106 * deltaX) div 256 >= deltaY);
      C_Dir.NORTHEAST:
        found := (y2 < y1) and (x2 > x1) and ((618 * deltaX) div 256 >= deltaY) and ((106 * deltaX) div 256 <= deltaY);
      C_Dir.SOUTHEAST:
        found := (y2 > y1) and (x2 > x1) and ((618 * deltaX) div 256 >= deltaY) and ((106 * deltaX) div 256 <= deltaY);
      C_Dir.SOUTHWEST:
        found := (y2 > y1) and (x2 < x1) and ((618 * deltaX) div 256 >= deltaY) and ((106 * deltaX) div 256 <= deltaY);
      C_Dir.NORTHWEST:
        found := (y2 < y1) and (x2 < x1) and ((618 * deltaX) div 256 >= deltaY) and ((106 * deltaX) div 256 <= deltaY)
    end;
    if not found then Inc(dir)
  end;
  DirTowardTarget := dir
end;

function ClassSuborderIndex(character: Types.PCharacter; classId: Byte): Byte;
var index: Byte;
begin
  case classId of
    C_Class.CLERIC: if Types.PCharacter(character)^.deity <= 4 then
        index := 0
      else
        index := 1;
    C_Class.KNIGHT: case Types.PCharacter(character)^.knightOrder of
        1: index := 3;
        2: index := 4;
        3: index := 5
      end;
    C_Class.FIGHTER: index := 2;
    C_Class.RANGER: index := 6;
    C_Class.MAGE: if Types.PCharacter(character)^.robeOrder = 1 then
        index := 7
      else
        index := 8;
    C_Class.THIEF: index := 9;
    C_Class.PALADIN: index := 10
  end;
  ClassSuborderIndex := index
end;

function CanLevelUp(character: Types.PCharacter): Boolean;
var capped: Boolean;
    found: Boolean;
    classId: ShortInt;
    level: Byte;
    requiredExperience: LongInt;
begin
  found := False;
  classId := 0;
  while (classId <= 7) and not found do begin
    if (Types.PCharacter(character)^.classLevels[classId] > 0) and
        (Types.PCharacter(character)^.classLevels[classId] < 18) then begin
      level := Types.PCharacter(character)^.classLevels[classId];
      requiredExperience :=
        GDConsts.classProgression[ShortInt(CharHlp.ClassSuborderIndex(character,
                                                                      classId))].experience[ShortInt(Succ(level))];
      capped := GDConsts.racialLevelCaps[Types.PCharacter(character)^.race, classId] <= level;
      found := (Types.PCharacter(character)^.experience >= requiredExperience) and (requiredExperience > 0) and
        not capped
    end;
    Inc(classId)
  end;
  CanLevelUp := found
end;

procedure ScatterCombatIcon(radius, cell, soundCue: Byte);
var randomCell: Byte;
    ringReal: Real;
    angle: Real;
    maximumRing: Byte;
    ring: Byte;
    point: Byte;
    savedDisplayMode: Byte;
    savedX: ShortInt;
    savedY: ShortInt;
    drawX: ShortInt;
    drawY: ShortInt;
    offsetY: ShortInt;
    offsetX: ShortInt;
begin
  CbtMap.ScrollView(GDVars.targetX, GDVars.targetY, 255, C_Dir.CENTER);
  savedX := GDVars.targetX;
  savedY := GDVars.targetY;
  Music.SendSoundCommand(soundCue);
  CharHlp.CopyIconFacing(cell, 0, 0, False);
  CharHlp.CopyIconFacing(cell, 0, 1, True);
  CharHlp.CopyIconFacing(cell, 1, 2, False);
  CharHlp.CopyIconFacing(cell, 1, 3, True);
  savedDisplayMode := GDConsts.iconFrame;
  offsetX := 0;
  offsetY := 0;
  if savedX < 3 then
    offsetX := (savedX - 3) * 3
  else if savedX > 46 then
    offsetX := (savedX - 49 + 3) * 3;
  if savedY < 3 then
    offsetY := (savedY - 3) * 3
  else if savedY > 21 then
    offsetY := (savedY - 24 + 3) * 3;
  maximumRing := radius * 3 + 1;
  for ring := 1 to maximumRing do begin
    ringReal := ring;
    for point := ring * 2 - 2 downto 0 do begin
      angle := Random * 2 * Pi;
      drawX := Trunc(Cos(angle) * ringReal) + offsetX;
      drawY := Trunc(Sin(angle) * ringReal) + offsetY;
      if (drawX >= -9) and (drawX <= 9) and (drawY >= -9) and (drawY <= 9) then begin
        randomCell := Random(4);
        Blit.BlitTileClipped(drawX + 9, drawY + 9, randomCell, savedDisplayMode, GDVars.movingIcon,
                             GDVars.compositeBuffer)
      end
    end;
    Blit.FlushView
  end;
  CbtMap.ScrollView(GDVars.targetX, GDVars.targetY, 255, C_Dir.CENTER)
end;

function ClassConAdj(character: Types.PCharacter; classId: Byte): ShortInt;
var adjustment: ShortInt;
begin
  case Types.PCharacter(character)^.stats[C_Stat.CONSTITUTION].current of
    3: adjustment := -2;
    4..6: adjustment := -1;
    7..14: adjustment := 0;
    15: adjustment := 1;
    16: adjustment := 2;
    17..19:
      if (classId = C_Class.FIGHTER) or (classId = C_Class.RANGER) or (classId = C_Class.PALADIN) or
          (classId = C_Class.KNIGHT) then
        adjustment := Types.PCharacter(character)^.stats[C_Stat.CONSTITUTION].current - 14
      else
        adjustment := 2
  end;
  ClassConAdj := adjustment
end;
begin
end.
