{ ClassCal -- what a character's class levels give it: THAC0 base, attack rate, saves, thief skills, spell slots and
  known spells, the class mask (unequipping what it may no longer use) and its highest level. }
{$O+,F+}
unit ClassCal;
interface
uses C_Class, C_Race, GDConsts, GDVars, Types, C_Stat;

{ Recalculates from the class levels. thac0Base is the highest thac0Table entry over the classes, plus 1 for deity 3 or
  for deity 6 with a mountain or hill dwarf. Fighters, paladins and knights above level 6 get attack rate 3, above 12
  rate 4, and rangers above 7 rate 3; the rate is never lowered here. Then the spells, the saves and, with thief levels,
  the thief skills; the class mask, unequipping every equipped item it no longer allows unless the item is cursed; and
  levelHighest.
  @param(cr Character to recalculate.) }
procedure RecalcClassStats(cr: Types.PCharacter);

{ Row 0 of the spell slots from the cleric level: one first-level slot, two for a deity above 4, plus the progression's
  slots per level. Wisdom 13 and 14 each add a first-level slot, 15 and 16 a second-level, 17 a third-level and 18 a
  fourth-level, each only where that level already has one.
  @param(cr Character whose slots are recalculated; nothing happens without spells or cleric levels.) }
procedure RecalcClericSlots(cr: Types.PCharacter);

{ Each of the five saves is 20, lowered to the best savingThrows entry over the character's classes. Save 0 then rises
  by constitution: for a mountain dwarf, hill dwarf or kender, or with an equipped item whose special is 134, by 1 to 5
  over constitution 4..18; and for anyone by 1 to 4 over constitution 19..25.
  @param(cr Character whose saves are recalculated.) }
procedure RecalcSaves(cr: Types.PCharacter);

{ Each thief skill is the base for the thief level plus the race adjustment, and for skills 1..5 the dexterity
  adjustment, indexed by current dexterity without a range check.
  @param(cr Character whose thief skills are recalculated.) }
procedure RecalcThiefSkills(cr: Types.PCharacter);
implementation

{ Rebuilds the spell slots and the spells known from the class levels: a cleric through the progression and
  RecalcClericSlots; a paladin above level 8 (progression row 10, slot levels 1..4); a knight above level 5 of knight
  orders 2 and 3 (rows 4 and 5); a ranger above level 7 (row 6, its first four slot levels into slot row 1 and its next
  four into row 3, and every castClass-1 spell of a level with a row-1 slot becomes known); and a mage (row 7 for robe
  order 1, else 8, plus one first-level slot in row 3). Clerics, paladins and knights learn the spells of
  GDConsts.spellsByLevel's first list for each level they have a slot in.
  @param(cr Character whose spells are rebuilt; nothing happens without spells.) }
procedure RecalcSpellSlots(cr: Types.PCharacter);
var
  i: ShortInt;
  cls: ShortInt;
  sp: ShortInt;
  k: ShortInt;
  idx: ShortInt;
  j: ShortInt;
  m: Byte;
  { Unused in this version; see the other implementations of this routine. }
  item: Types.PItem;
begin
  if cr^.spells = nil then Exit;
  with cr^ do begin
  FillChar(spells^.slots, SizeOf(spells^.slots), 0);
  for i := 0 to 7 do begin
    sp := classLevels[i];
    if sp > 0 then
      case i of
        C_Class.CLERIC: begin
             if deity <= 4 then cls := 0 else cls := 1;
             Inc(spells^.slots[0, 1]);
             for k := 2 to sp do
               for j := 1 to 7 do
                 Inc(spells^.slots[0, j], GDConsts.classProgression[cls].spellSlots[k, j]);
             ClassCal.RecalcClericSlots(cr);
             for k := 1 to 7 do
               if spells^.slots[0, k] > 0 then begin
                 GDVars.loopIndex := 1;
                 m := 255;
                 while (GDVars.loopIndex <= 10) and (m <> 0) do begin
                   m := GDConsts.spellsByLevel[1, k, GDVars.loopIndex];
                   if m <> 0 then spells^.known[m] := 1;
                   Inc(GDVars.loopIndex);
                 end;
               end;
           end;
        C_Class.PALADIN: begin
             if sp > 8 then begin
               for k := 9 to sp do
                 for j := 1 to 4 do
                   Inc(spells^.slots[0, j], GDConsts.classProgression[10].spellSlots[k, j]);
               for k := 1 to 4 do
                 if spells^.slots[0, k] > 0 then begin
                   GDVars.loopIndex := 1;
                   m := 255;
                   while (GDVars.loopIndex <= 10) and (m <> 0) do begin
                     m := GDConsts.spellsByLevel[1, k, GDVars.loopIndex];
                     if m <> 0 then spells^.known[m] := 1;
                     Inc(GDVars.loopIndex);
                   end;
                 end;
             end;
           end;
        C_Class.KNIGHT: begin
             if sp > 5 then
               if knightOrder <> 1 then begin
                 if knightOrder = 2 then cls := 4 else cls := 5;
                 for k := 6 to sp do
                   for j := 1 to 7 do
                     Inc(spells^.slots[0, j], GDConsts.classProgression[cls].spellSlots[k, j]);
                 for k := 1 to 7 do
                   if spells^.slots[0, k] > 0 then begin
                     GDVars.loopIndex := 1;
                     m := 255;
                     while (GDVars.loopIndex <= 10) and (m <> 0) do begin
                       m := GDConsts.spellsByLevel[1, k, GDVars.loopIndex];
                       if m <> 0 then spells^.known[m] := 1;
                       Inc(GDVars.loopIndex);
                     end;
                   end;
               end;
           end;
        C_Class.RANGER: begin
             if sp > 7 then begin
               for k := 8 to sp do begin
                 for j := 1 to 4 do
                   Inc(spells^.slots[1, j], GDConsts.classProgression[6].spellSlots[k, j]);
                 for j := 5 to 8 do begin
                   idx := j - 4;
                   Inc(spells^.slots[3, idx], GDConsts.classProgression[6].spellSlots[k, j]);
                 end;
               end;
               for m := 1 to SizeOf(GDConsts.spellTable) div SizeOf(GDConsts.spellTable[1]) do
                 if GDConsts.spellTable[m].castClass = 1 then begin
                   k := GDConsts.spellTable[m].level;
                   if spells^.slots[1, k] > 0 then
                     spells^.known[m] := 1;
                 end;
             end;
           end;
        C_Class.MAGE: begin
             if robeOrder = 1 then cls := 7 else cls := 8;
             Inc(spells^.slots[3, 1]);
             for k := 2 to sp do
               for j := 1 to 8 do
                 Inc(spells^.slots[3, j], GDConsts.classProgression[cls].spellSlots[k, j]);
           end;
      end;
  end;
  item := items;
  end;
end;

procedure RecalcClassStats(cr: Types.PCharacter);
var
  i: ShortInt;
  { Unused in this version; see the other implementations of this routine. }
  levelIndex: ShortInt;
  { Unused in this version; see the other implementations of this routine. }
  spellLevel: ShortInt;
  clsLvl: ShortInt;
  { Unused in this version; see the other implementations of this routine. }
  spellIndex: ShortInt;
  k: ShortInt;
begin
  cr^.thac0Base := 0;
  for i := 0 to 7 do begin
    clsLvl := cr^.classLevels[i];
    if GDConsts.thac0Table[i, clsLvl] > cr^.thac0Base then
      cr^.thac0Base := GDConsts.thac0Table[i, clsLvl];
    case i of
      C_Class.FIGHTER, C_Class.KNIGHT, C_Class.PALADIN: if clsLvl > 6 then
                 if clsLvl > 12 then cr^.attackRate := 4
                 else cr^.attackRate := 3;
      C_Class.RANGER: if clsLvl > 7 then cr^.attackRate := 3;
    end;
  end;
  if ((cr^.deity = 6) and ((cr^.race = C_Race.MOUNTAIN_DWARF) or (cr^.race = C_Race.HILL_DWARF))) or
      (cr^.deity = 3) then
    Inc(cr^.thac0Base);
  ClassCal.RecalcSpellSlots(cr);
  ClassCal.RecalcSaves(cr);
  if cr^.classLevels[C_Class.THIEF] > 0 then
    ClassCal.RecalcThiefSkills(cr);
  cr^.classMask := 0;
  for i := 0 to 7 do
    if cr^.classLevels[i] > 0 then
      Inc(cr^.classMask, GDConsts.classMaskBits[i]);
  for k := 0 to 12 do
    if cr^.equipped[k] <> nil then
      if GDVars.baseItems[cr^.equipped[k]^.itemType].classMask and cr^.classMask = 0 then
        if cr^.equipped[k]^.cursed = 0 then
          cr^.equipped[k]^.equipped := 0;
  with cr^ do begin
    levelHighest := 0;
    for i := 0 to 7 do
      if classLevels[i] > levelHighest then
        levelHighest := classLevels[i];
  end;
end;

procedure RecalcClericSlots(cr: Types.PCharacter);
var
  k: ShortInt;
  ij: ShortInt;
  sp: ShortInt;
  cls: ShortInt;
begin
  sp := cr^.classLevels[C_Class.CLERIC];
  if (cr^.spells <> nil) and (sp > 0) then with cr^ do begin
    if deity <= 4 then cls := 0 else cls := 1;
    for ij := 2 to 7 do spells^.slots[0, ij] := 0;
    if cls = 0 then spells^.slots[0, 1] := 1 else spells^.slots[0, 1] := 2;
    for k := 2 to sp do
      for ij := 1 to 7 do
        Inc(spells^.slots[0, ij], GDConsts.classProgression[cls].spellSlots[k, ij]);
    if (stats[C_Stat.WISDOM].current > 12) and (spells^.slots[0, 1] > 0) then Inc(spells^.slots[0, 1]);
    if (stats[C_Stat.WISDOM].current > 13) and (spells^.slots[0, 1] > 0) then Inc(spells^.slots[0, 1]);
    if (stats[C_Stat.WISDOM].current > 14) and (spells^.slots[0, 2] > 0) then Inc(spells^.slots[0, 2]);
    if (stats[C_Stat.WISDOM].current > 15) and (spells^.slots[0, 2] > 0) then Inc(spells^.slots[0, 2]);
    if (stats[C_Stat.WISDOM].current > 16) and (spells^.slots[0, 3] > 0) then Inc(spells^.slots[0, 3]);
    if (stats[C_Stat.WISDOM].current > 17) and (spells^.slots[0, 4] > 0) then Inc(spells^.slots[0, 4]);
  end;
end;

procedure RecalcSaves(cr: Types.PCharacter);
var
  i: ShortInt;
  mm: ShortInt;
  { Unused in this version; see the other implementations of this routine. }
  level: ShortInt;
  tmp: ShortInt;
  it: Types.PItem;
  found: Boolean;
begin
  found := False;
  it := cr^.items;
  while (it <> nil) and not found do begin
    if (it^.special > $80) and (it^.equipped <> 0) then begin
      tmp := it^.special and $7F;
      found := tmp = 6;
    end;
    it := it^.next;
  end;
  for i := 0 to 4 do begin
    cr^.saves[i] := 20;
    for mm := 0 to 7 do
      if cr^.classLevels[mm] > 0 then
        if cr^.saves[i] > GDConsts.savingThrows[mm, cr^.classLevels[mm], i] then
          cr^.saves[i] := GDConsts.savingThrows[mm, cr^.classLevels[mm], i];
    if i = 0 then
      if (cr^.race = C_Race.MOUNTAIN_DWARF) or (cr^.race = C_Race.KENDER) or
          (cr^.race = C_Race.HILL_DWARF) or found then
        case cr^.stats[C_Stat.CONSTITUTION].current of
          4..6: Inc(cr^.saves[i]);
          7..10: Inc(cr^.saves[i], 2);
          11..13: Inc(cr^.saves[i], 3);
          14..17: Inc(cr^.saves[i], 4);
          18: Inc(cr^.saves[i], 5);
        end;
    if i = 0 then
      case cr^.stats[C_Stat.CONSTITUTION].current of
        19, 20: Inc(cr^.saves[i]);
        21, 22: Inc(cr^.saves[i], 2);
        23, 24: Inc(cr^.saves[i], 3);
        25: Inc(cr^.saves[i], 4);
      end;
  end;
end;

procedure RecalcThiefSkills(cr: Types.PCharacter);
var
  i: Byte;
  base: ShortInt;
begin
  with cr^ do begin
    base := cr^.classLevels[C_Class.THIEF];
    for i := 1 to 8 do begin
      thiefSkills[i] := GDConsts.thiefSkillBase[base, i] + GDConsts.thiefSkillRaceAdjust[race, i];
      if i < 6 then
        thiefSkills[i] := thiefSkills[i] + GDConsts.thiefSkillDexterityAdjust[stats[C_Stat.DEXTERITY].current, i];
    end;
  end;
end;
begin
end.
