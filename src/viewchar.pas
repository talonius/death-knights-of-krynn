{ The character sheet and the menus under it: View (items, spells, trade, deposit or drop coins, the paladin's lay on
  hands and cure disease), the Items menu (ready, use, trade, deposit, drop, halve, join, sell, identify), and the hit
  points a level gained or lost is worth. }
{$F+,O+,S-,R-,V-,B-,I-}
unit ViewChar;
interface
uses C_Class, C_Effect, C_Ifc, C_Npc, C_Race, C_Stat, C_Status, Crt, C_Keys, GDConsts, GDVars, Types, CharHlp, TextRend,
  MenuCore, Border, Magic, GameIo, CbtMap, Money, FxEngine;

{ Draws the current character's sheet -- name, status, age, alignment, race, class with deity, robe or knightly order,
  levels, experience, stats, money, combat figures and readied weapon and armor -- and makes it the viewed character. }
procedure DisplayChar;

{ Recalculates the current character's stats and shows its hit points, armor class, encumbrance, THAC0, movement and
  damage dice on the character sheet. }
procedure PrintCombatStats;

{ Draws one of the current character's abilities on its row of the character sheet, in light magenta while modifying and
  light green otherwise. Strength 18 with exceptional strength adds '(NN)', with 100 shown as '(00)'; a '*' marks a
  current value (or exceptional strength) that differs from its base.
  @param(statIndex The ability, 0 to 5.)
  @param(modifying True draws it in the modify color.) }
procedure PrintStat(statIndex: ShortInt; modifying: Boolean);

{ The current character's coins on the sheet. }
procedure PrintMoney;

{ The sheet's menu (Items Spells Trade Deposit Drop Heal Cure Exit): Trade gives coins, Deposit (in the vault) or Drop
  lets them go, and Heal and Cure are a paladin's outside combat.
  @param(done Set when an item use ends the turn.) }
procedure ViewCharMenu(var done: Boolean);

{ The Items menu (Ready Use Trade Deposit Drop Halve Join Sell Id Exit) over the current character's items, each word
  enabled where it applies.
  @param(done Set when an item use ends the turn.) }
procedure UseItemMenu(var done: Boolean);

{ Readies or unreadies item: cursed items will not come off; readying is refused for the wrong class, a full slot or
  hands, a robe of the wrong order (or too low a thief level), or an item only kender use.
  @param(itemPointer The item.) }
procedure ToggleReadyItem(itemPointer: Pointer);

{ Uses item: a scroll casts a spell from it (mages and clerics always, a thief above level 9 three times in four),
  another item casts its effect; a used charge, or the scroll's spell, is spent.
  @param(itemPointer The item.)
  @param(done Set when the use ends the turn.) }
procedure UseItem(itemPointer: Pointer; var done: Boolean);

{ Tells whether a character cannot take an item: the pack already holds 16 items and the item does not join an existing
  stack, or its weight would exceed the carrying allowance by more than 1500.
  @param(character The character.)
  @param(mayStack Nonzero enables the stack check.)
  @param(itemPointer The item.)
  @returns(True when the character cannot take it.) }
function CannotCarryItem(character: Types.PCharacter; mayStack: Byte; itemPointer: Pointer): Boolean;

{ Makes the previous (Up) or next (Down) party member current, or the one a mouse click picked.
  @param(key Up or Down, or the key a mouse click gives.) }
procedure SelectAdjacentCharacter(key: Char);

{ Lists the current character's spells of a kind (memorized, grimoire, scroll, scrolls, choose, memorize, scribe) under
  its name and lets the player pick one.
  @param(listMode The list kind, 0..6.)
  @param(selectionType How the list is drawn and chosen from, passed to Magic.SpellSelection.)
  @param(index The highlighted entry, kept between calls; negative redraws the frame.)
  @param(hasSpells Set True when the list has spells.)
  @returns(The spell picked, or 0.) }
function SpellMenu(listMode, selectionType: Byte; var index: Integer; var hasSpells: Boolean): Byte;

{ Tells whether a character is a paladin who may lay on hands: outside combat, okay, and not under effect 109.
  @param(character The character.)
  @returns(True when it may lay on hands.) }
function CanHeal(character: Types.PCharacter): Boolean;

{ Tells whether a character is a paladin with cure-disease uses left, outside combat and okay.
  @param(character The character.)
  @returns(True when it may cure disease.) }
function CanCure(character: Types.PCharacter): Boolean;

{ Heals a chosen character 2 x the paladin's level and puts the paladin under effect 109 for a day.
  @param(character The paladin.) }
procedure PaladinLayOnHands(character: Types.PCharacter);

{ Asks whom to cure and does nothing more: no cure is applied and no use spent.
  @param(character Unused.) }
procedure PaladinCureDisease(character: Types.PCharacter);

{ Empty routine with no callers. }
procedure NoopViewChar;

{ Lets the player move the highlight through the party list and choose a character.
  @returns(True when one is chosen, False on exit.) }
function PickCharacter: Boolean;

{ Returns the constitution hit-point bonus for a class, the fighting classes (fighter, paladin, ranger, knight) getting
  more from 17 up.
  @param(character The character.)
  @param(classId The class.)
  @returns(The bonus.) }
function ClassConHpBonus(character: Types.PCharacter; classId: Byte): ShortInt;

{ The hit points a level gained or lost is worth for the classes in classMask, divided among divisor classes: the better
  of two rolls plus constitution below the fixed-gain level, a fixed 1..3 above it (which replaces, not adds to, the
  running total); losing is limited by HitPointCap. divisor 0 zeroes the hit points.
  @param(character The character.)
  @param(classMask The classes whose level changes.)
  @param(divisor Number of classes sharing the hit points.)
  @param(gaining True for a level gained, False for one lost.) }
procedure AdjustLevelHitPoints(character: Types.PCharacter; classMask, divisor: Byte; gaining: Boolean);

{ Drops (or, in the vault, gives) coins of a chosen kind, on the sheet or in the lower window.
  @param(onSheet True on the character sheet, False in the lower window.) }
procedure DropMoneyMenu(onSheet: Boolean);

{ Returns the most hit points the character could have by its classes and levels, averaged over its classes.
  @param(character The character.)
  @returns(The cap.) }
function HitPointCap(character: Types.PCharacter): Byte;

{ Merges into an item each other stack of the current character's that has a quantity and the same name, type, plus,
  save bonus, curse and weight and fewer than 2 charges. When the total would pass 255, the item is filled to 255 and
  the merging goes on into the stack that keeps the excess. Note: the charges, effect and special tests compare a stack
  with itself, so they always pass.
  @param(item The item to merge into.) }
procedure JoinItem(item: Types.PItem);
implementation

procedure ItemTradeMenu(item: Types.PItem); forward;

procedure HalveItem(item: Types.PItem); forward;

procedure SellItem(item: Types.PItem); forward;

procedure IdentifyItem(item: Types.PItem; var redraw: Boolean); forward;

procedure TradeTreasureMenu; forward;

procedure DisplayChar;
var
  { Unused in this version; see the other implementations of this routine. }
  statRow: Byte;
  { Unused in this version; see the other implementations of this routine. }
  row: Byte;
  { Unused in this version; see the other implementations of this routine. }
  column: Byte;
  i: Byte;
  statIndex: ShortInt;
  j: ShortInt;
  s: String;
  found: Boolean;
  multiple: Boolean;
begin
  GDVars.viewedCharacter := GDVars.currentCharacter;
  Border.DrawCharSheetFrame;
  CharHlp.DisplayCreatureName(GDVars.viewedCharacter, 1, 1, False);
  TextRend.DisplayString(20, 1, White, Black, 'Status:');
  TextRend.DisplayString(27, 1, LightGreen, Black, GDConsts.statusNames[ShortInt(GDVars.viewedCharacter^.status)]);
  s := GDConsts.genderNames[GDVars.viewedCharacter^.gender];
  TextRend.DisplayString(1, 3, White, Black, s);
  TextRend.DisplayString(8, 3, White, Black, CharHlp.WordToString(GDVars.viewedCharacter^.age) + ' years');
  s := GDConsts.alignmentNames[GDVars.viewedCharacter^.alignment];
  TextRend.DisplayString(1, 4, White, Black, s);
  s := GDConsts.raceNames[GDVars.viewedCharacter^.race];
  TextRend.DisplayString(20, 4, White, Black, s);
  s := GDConsts.classNames[GDVars.viewedCharacter^.characterClass];
  if GDVars.viewedCharacter^.classLevels[C_Class.CLERIC] > 0 then
    s := GDConsts.deityNames[GDVars.viewedCharacter^.deity] + ' ' + s;
  if GDVars.viewedCharacter^.classLevels[C_Class.MAGE] > 0 then begin
    i := 0;
    repeat
      Inc(i)
    until ((s[i] = 'M') and (s[i + 2] = 'g')) or (i > Length(s));
    Insert(GDConsts.robeOrderNames[GDVars.viewedCharacter^.robeOrder] + ' ', s, i)
  end;
  if GDVars.viewedCharacter^.classLevels[C_Class.KNIGHT] > 0 then
    case GDVars.viewedCharacter^.knightOrder of
      1: s := s + ' of the Crown';
      2: s := s + ' of the Sword';
      3: s := s + ' of the Rose'
    end;
  TextRend.DisplayString(1, 5, White, Black, s);
  TextRend.DisplayString(1, 7, White, Black, 'Level');
  multiple := False;
  s := '';
  found := False;
  for j := 0 to 7 do
    if GDVars.viewedCharacter^.classLevels[j] > 0 then begin
      found := True;
      if multiple then
        s := s + '/';
      s := s + CharHlp.ByteToString(Byte(GDVars.viewedCharacter^.classLevels[j]));
      multiple := True
    end;
  if not found then
    s := '0';
  TextRend.DisplayString(7, 7, White, Black, s);
  TextRend.DisplayString(20, 7, White, Black,
                         'Experience ' + CharHlp.LongIntToString(GDVars.viewedCharacter^.experience));
  for statIndex := 0 to 5 do begin
    case statIndex of
      C_Stat.STRENGTH: s := 'STR ';
      C_Stat.INTELLIGENCE: s := 'INT ';
      C_Stat.WISDOM: s := 'WIS ';
      C_Stat.DEXTERITY: s := 'DEX ';
      C_Stat.CONSTITUTION: s := 'CON ';
      C_Stat.CHARISMA: s := 'CHA '
    end;
    TextRend.DisplayString(1, statIndex + 9, LightGreen, Black, s);
    ViewChar.PrintStat(statIndex, False)
  end;
  ViewChar.PrintMoney;
  ViewChar.PrintCombatStats;
  if GDVars.viewedCharacter^.equipped[0] <> nil then
    CharHlp.PrintItemString(GDVars.viewedCharacter, GDVars.viewedCharacter^.equipped[0], 1, 21, False, True);
  if GDVars.viewedCharacter^.equipped[2] <> nil then
    CharHlp.PrintItemString(GDVars.viewedCharacter, GDVars.viewedCharacter^.equipped[2], 1, 22, False, True)
end;

procedure PrintMoney;
var row: Byte;
    moneyType: ShortInt;
    s: Types.TString40;
begin
  Border.ClearBox(20, 9, 38, 15);
  row := 9;
  for moneyType := 4 to 6 do
    if GDVars.currentCharacter^.coins[moneyType] > 0 then begin
      s := GDConsts.moneyNames[moneyType];
      TextRend.DisplayString(20, row, LightGreen, Black, s);
      s := CharHlp.WordToString(GDVars.currentCharacter^.coins[moneyType]);
      TextRend.DisplayString(38 - Length(s), row, LightGreen, Black, s);
      Inc(row)
    end
end;

procedure PrintCombatStats;
var character: Types.PCharacter;
    { Unused in this version; see the other implementations of this routine. }
    row: Byte;
    col: Byte;
    { Unused in this version; see the other implementations of this routine. }
    movement: Byte;
    s: Types.TString40;
    { Unused in this version; see the other implementations of this routine. }
    effect: Pointer;

  { Pads a field on the left with spaces to a width. }
  procedure RightAlignField(var field: Types.TString40; width: Byte);
  begin
    while Length(field) < width do
      field := ' ' + field
  end;
begin
  character := GDVars.currentCharacter;
  CharHlp.RecalcStats(character);
  TextRend.DisplayString(20, 3, White, Black, 'Hit Points ');
  Border.ClearBox(31, 3, 37, 3);
  CharHlp.PrintHitPoints(character, 31, 3, False, True);
  TextRend.DisplayString(1, 17, White, Black, 'Armor Class');
  case GDVars.currentCharacter^.armorClass of
    1..50: col := 16;
    51..60: col := 17;
    61..69: col := 16
  else
    col := 15
  end;
  Border.ClearBox(15, 17, 17, 17);
  CharHlp.PrintArmorClass(character, col, 17);
  TextRend.DisplayString(20, 17, White, Black, 'Encumbrance');
  s := CharHlp.WordToString(character^.encumbrance);
  RightAlignField(s, 5);
  TextRend.DisplayString(33, 17, LightGreen, Black, s);
  TextRend.DisplayString(1, 18, White, Black, 'THAC0   ');
  s := CharHlp.LongIntToString(60 - character^.thac0Adjusted);
  RightAlignField(s, 2);
  TextRend.DisplayString(16, 18, LightGreen, Black, s);
  TextRend.DisplayString(20, 18, White, Black, 'Movement');
  movement := CharHlp.RecalcMovement(character);
  s := CharHlp.ByteToString(character^.currentMovement);
  RightAlignField(s, 3);
  TextRend.DisplayString(35, 18, LightGreen, Black, s);
  s := CharHlp.ByteToString(character^.currentRolls[1]) + 'd' + CharHlp.ByteToString(character^.currentDice[1]);
  if character^.currentModifiers[1] > 0 then
    s := s + '+' + CharHlp.ByteToString(Byte(character^.currentModifiers[1]));
  if character^.currentModifiers[1] < 0 then
    s := s + '-' + CharHlp.ByteToString(Byte(Abs(character^.currentModifiers[1])));
  TextRend.DisplayString(1, 19, White, Black, 'Damage');
  RightAlignField(s, 7);
  TextRend.DisplayString(11, 19, LightGreen, Black, s)
end;

procedure PrintStat(statIndex: ShortInt; modifying: Boolean);
var s: Types.TString40;
    column: Byte;
    highlight: Byte;
begin
  if modifying then
    highlight := LightMagenta
  else
    highlight := LightGreen;
  column := 5;
  Border.ClearBox(column, statIndex + 9, 11, statIndex + 9);
  if GDVars.currentCharacter^.stats[statIndex].current < 10 then
    Inc(column);
  TextRend.DisplayString(column, statIndex + 9, highlight, Black,
                         CharHlp.ByteToString(GDVars.currentCharacter^.stats[statIndex].current));
  if (statIndex = C_Stat.STRENGTH) and (GDVars.currentCharacter^.stats[C_Stat.STRENGTH].current = 18) and
      (GDVars.currentCharacter^.exceptionalStrength > 0) then begin
    s := CharHlp.ByteToString(GDVars.currentCharacter^.exceptionalStrength);
    if GDVars.currentCharacter^.exceptionalStrength < 10 then
      s := '0' + s;
    if GDVars.currentCharacter^.exceptionalStrength = 100 then
      s := '00';
    TextRend.DisplayString(7, 9, highlight, Black, '(' + s + ')')
  end;
  if (GDVars.currentCharacter^.stats[statIndex].current <> GDVars.currentCharacter^.stats[statIndex].base) or
      ((statIndex = C_Stat.STRENGTH) and
       (GDVars.currentCharacter^.exceptionalStrengthBase <> GDVars.currentCharacter^.exceptionalStrength)) then
    TextRend.DisplayString(12, statIndex + 9, highlight, Black, '*')
end;

procedure ViewCharMenu(var done: Boolean);
var ch: Char;
    { Unused in this version; see the other implementations of this routine. }
    choice: Byte;
    hasMoney: Boolean;
    hasSpells: Boolean;
    { Unused in this version; see the other implementations of this routine. }
    isExtended: Byte;
    i: Byte;
    j: ShortInt;
    index: Integer;
    options: Byte;
    savedChoice: Byte;
begin
  if GDVars.interfaceState = C_Ifc.IN_COMBAT then
    CbtMap.SetNoncombatPalette;
  done := False;
  ch := #255;
  GDVars.tradeCharacter := GDVars.currentCharacter;
  ViewChar.DisplayChar;
  FillChar(GDVars.enabledChoices, SizeOf(GDVars.enabledChoices), $FF);
  savedChoice := 1;
  while (ch <> #7) and not done do begin
    options := 0;
    hasSpells := False;
    hasMoney := False;
    if GDVars.viewedCharacter^.spells <> nil then begin
      for i := 0 to 73 do
        if (GDVars.viewedCharacter^.spells^.memorized[i] and $7F) > 0 then
          hasSpells := True
    end;
    for j := 4 to 6 do
      if GDVars.viewedCharacter^.coins[j] > 0 then
        hasMoney := True;
    if GDVars.viewedCharacter^.items <> nil then
      MenuCore.AppendChoice(0, options);
    if hasSpells then
      MenuCore.AppendChoice(1, options);
    if ((GDVars.viewedCharacter^.npc < C_Npc.NON_PLAYER) or (GDVars.viewedCharacter^.enabled = 0) or
        (GDVars.viewedCharacter^.status = C_Status.ANIMATED)) and hasMoney and
        (GDVars.interfaceState <> C_Ifc.IN_COMBAT) then
      MenuCore.AppendChoice(2, options);
    if hasMoney then begin
      if GDVars.interfaceState = C_Ifc.IN_VAULT then
        MenuCore.AppendChoice(3, options)
      else
        MenuCore.AppendChoice(4, options)
    end;
    if ViewChar.CanHeal(GDVars.currentCharacter) then
      MenuCore.AppendChoice(5, options);
    if ViewChar.CanCure(GDVars.currentCharacter) then
      MenuCore.AppendChoice(6, options);
    MenuCore.AppendChoice(7, options);
    GDVars.selectedChoice := savedChoice;
    ch := Char(MenuCore.MenuHorizontal('', GDConsts.viewMenu, Ord(False), Ord(False)));
    if (GDVars.menuExtendedKey <> 0) and (ch = C_Keys.ESCAPE) then
      ch := #7;
    savedChoice := GDVars.selectedChoice;
    index := -1;
    case ch of
      #0: ViewChar.UseItemMenu(done);
      #1: i := ViewChar.SpellMenu(0, 0, index, hasSpells);
      #2: ViewChar.TradeTreasureMenu;
      #3, #4: begin
        ViewChar.DropMoneyMenu(True);
        ViewChar.PrintMoney
      end;
      #5: ViewChar.PaladinLayOnHands(GDVars.currentCharacter);
      #6: ViewChar.PaladinCureDisease(GDVars.currentCharacter)
    end;
    if not done and (ch < #3) then
      ViewChar.DisplayChar
  end;
  if GDVars.interfaceState = C_Ifc.IN_COMBAT then
    CbtMap.SetCombatPalette;
  CharHlp.DisplayNoncombatInterface
end;

{ Tells whether an item may leave the current character's inventory: a readied item must be unreadied first, and a
  scroll with scribing pending (charges, effect or special above $7F) asks before that work is lost.
  @param(item The item.)
  @returns(True when the item may go.) }
function CheckItemAvail(item: Types.PItem): Boolean;
begin
  CheckItemAvail := False;
  if item^.equipped <> 0 then
    CharHlp.PrintBottomLine('Must be unreadied')
  else if not Magic.ItemReadable(item) then
    CheckItemAvail := True
  else if (item^.charges > $7F) or (item^.effect > $7F) or (item^.special > $7F) then begin
    CharHlp.DisplayCreatureName(GDVars.currentCharacter, 1, 21, False);
    GDVars.currentColumn := Length(GDVars.currentCharacter^.name) + 2;
    GDVars.currentRow := 21;
    TextRend.DisplayMessageWindow(1, 21, 38, 22, Yellow, Black, False, GDConsts.scribeMessage);
    if Char(MenuCore.YesNoMenu(GDConsts.loseQuery, GDConsts.noKey)) = Chr(GDConsts.yesKey) then
      CheckItemAvail := True
  end else
    CheckItemAvail := True;
  Border.ClearBox(1, 21, 38, 22)
end;

procedure UseItemMenu(var done: Boolean);
var options: Byte;
    ch: Char;
    { Unused in this version; see the other implementations of this routine. }
    menuState: Byte;
    needRedraw: Boolean;
    menuNeedsRedraw: Boolean;
    menuNeedsRedrawByte: Byte absolute menuNeedsRedraw;
    item: Types.PItem;
    selected: Types.PItem;
    index: Integer;
    { Unused in this version; see the other implementations of this routine. }
    previousItem: Types.PItem;
    character: Types.PCharacter;
    itemCount: Byte;
    { Unused in this version; see the other implementations of this routine. }
    itemTotal: Byte;
    savedChoice: Byte;
begin
  character := GDVars.currentCharacter;
  selected := character^.items;
  index := 0;
  menuNeedsRedraw := True;
  needRedraw := True;
  ch := #255;
  savedChoice := 1;
  while (ch <> #9) and not done and (character^.numberOfItems > 0) do begin
    itemCount := character^.numberOfItems;
    if character^.items <> nil then begin
      FillChar(GDVars.enabledChoices, SizeOf(GDVars.enabledChoices), $FF);
      options := 0;
      MenuCore.AppendChoice(0, options);
      if (character^.enabled <> 0) and (GDVars.zone0^.antiMagic = 0) and
          ((GDVars.interfaceState = C_Ifc.CAMPING) or (GDVars.interfaceState = C_Ifc.OVERLAND) or
           (GDVars.interfaceState = C_Ifc.VIEW_3D) or
           ((GDVars.interfaceState = C_Ifc.IN_COMBAT) and (character^.combat^.canUseItem <> 0))) then
        MenuCore.AppendChoice(1, options);
      if ((character^.npc < C_Npc.NON_PLAYER) or (character^.enabled = 0) or
          (character^.status = C_Status.ANIMATED)) and (GDVars.interfaceState <> C_Ifc.IN_COMBAT) then
        MenuCore.AppendChoice(2, options);
      if GDVars.interfaceState = C_Ifc.IN_VAULT then
        MenuCore.AppendChoice(3, options)
      else
        MenuCore.AppendChoice(4, options);
      if character^.numberOfItems < 16 then
        MenuCore.AppendChoice(5, options);
      MenuCore.AppendChoice(6, options);
      if ((character^.npc < C_Npc.NON_PLAYER) or (character^.enabled = 0) or
          (character^.status = C_Status.ANIMATED)) and (GDVars.interfaceState = C_Ifc.SHOP_TEMPLE) then
        MenuCore.AppendChoice(7, options);
      if GDVars.interfaceState = C_Ifc.SHOP_TEMPLE then
        MenuCore.AppendChoice(8, options);
      MenuCore.AppendChoice(9, options);
      item := character^.items;
      while item <> nil do begin
        CharHlp.PrintItemString(character, item, 0, 0, True, False);
        item := item^.next
      end;
      if needRedraw or (GDVars.redrawInventory <> 0) then begin
        Border.DrawTitleInset;
        CharHlp.DisplayCreatureName(character, 1, 1, True);
        TextRend.DisplayString(Length(character^.name) + 4, 1, LightGreen, Black, GDConsts.itemsLabel);
        TextRend.DisplayString(1, 3, White, Black, GDConsts.readyItemLabel);
        menuNeedsRedraw := True;
        needRedraw := False;
        GDVars.redrawInventory := 0
      end;
      GDVars.selectedChoice := savedChoice;
      ch := Char(MenuCore.MenuVertical(GDConsts.emptyQuery, GDConsts.itemsMenu, 1, 5, 38, 22, character^.items,
                                       Ord(True), 8, menuNeedsRedrawByte, index, selected));
      savedChoice := GDVars.selectedChoice;
      if (GDVars.menuExtendedKey <> 0) and (ch = C_Keys.ESCAPE) then
        ch := #9;
      if selected <> nil then
        case ch of
          #0: ViewChar.ToggleReadyItem(selected);
          #1: if selected^.equipped = 0 then begin
               CharHlp.PrintBottomLine(GDConsts.mustBeReadied);
               ch := #255
             end else if Magic.ItemReadable(selected) or
               ((selected^.effect > 0) and (selected^.special < $80)) then begin
               ViewChar.UseItem(selected, done);
               if GDVars.interfaceState <> C_Ifc.IN_COMBAT then
                 done := False;
               if not done then
                 needRedraw := True
             end;
          #2: begin
               if ViewChar.CheckItemAvail(selected) then
                 ViewChar.ItemTradeMenu(selected)
               else
                 ch := #255;
               needRedraw := True
             end;
          #3: begin
               if ViewChar.CheckItemAvail(selected) then begin
                 GDVars.vaultCursor := GDVars.treasureItems;
                 while (GDVars.vaultCursor <> nil) and (GDVars.vaultCursor^.next <> nil) do
                   GDVars.vaultCursor := GDVars.vaultCursor^.next;
                 CharHlp.PrintItemString(character, selected, 0, 0, False, False);
                 if GDVars.interfaceState = C_Ifc.IN_VAULT then begin
                   TextRend.DisplayMessageWindow(1, 21, 38, 22, Yellow, Black, True,
                                                 'Your ' + selected^.name + 'will be left in the vault');
                   TextRend.PauseOnly;
                   if GDVars.treasureItems = nil then begin
                     GetMem(GDVars.treasureItems, SizeOf(Types.TItem));
                     GDVars.vaultCursor := GDVars.treasureItems
                   end else begin
                     GetMem(GDVars.vaultCursor^.next, SizeOf(Types.TItem));
                     GDVars.vaultCursor := GDVars.vaultCursor^.next
                   end;
                   GDVars.vaultCursor^ := selected^;
                   GDVars.vaultCursor^.next := nil;
                   CharHlp.RemoveItem(character, selected);
                   menuNeedsRedraw := True
                 end
               end else
                 ch := #255;
             end;
          #4: begin
               if ViewChar.CheckItemAvail(selected) then begin
                 CharHlp.PrintItemString(character, selected, 0, 0, False, False);
                 TextRend.DisplayMessageWindow(1, 21, 38, 22, Yellow, Black, True,
                                               GDConsts.dropYour + selected^.name + GDConsts.goneForever);
                 if Char(MenuCore.YesNoMenu(GDConsts.loseQuery, GDConsts.noKey)) = Chr(GDConsts.yesKey) then begin
                   CharHlp.RemoveItem(GDVars.currentCharacter, selected);
                   menuNeedsRedraw := True
                 end;
                 Border.ClearBox(1, 21, 38, 22)
               end else
                 ch := #255;
             end;
          #5: ViewChar.HalveItem(selected);
          #6: ViewChar.JoinItem(selected);
          #7: if ViewChar.CheckItemAvail(selected) then
               ViewChar.SellItem(selected)
             else
               ch := #255;
          #8: ViewChar.IdentifyItem(selected, menuNeedsRedraw)
        end;
      CharHlp.RecalcStats(character)
    end;
    if character^.numberOfItems <> itemCount then
      menuNeedsRedraw := True
  end;
end;

{ Runs a special item's effect as it is readied or unreadied: its handler for kinds 0 and 2, a strength recalculation
  for 3 and 5, and effect 23 removed when kind 9 comes off.
  @param(item The item.)
  @param(equipping True when it is readied, False when it comes off.) }
procedure ToggleItemEffect(item: Types.PItem; equipping: Boolean);
var
  effectId: Byte;
  { Unused in this version; see the other implementations of this routine. }
  perClassLevel: Byte;
  { Unused in this version; see the other implementations of this routine. }
  damage: Byte;
  character: Types.PCharacter;
  { Unused in this version; see the other implementations of this routine. }
  classIndex: ShortInt;
  { Unused in this version; see the other implementations of this routine. }
  newLevel: Byte;
  { Unused in this version; see the other implementations of this routine. }
  levelIndex: ShortInt;
  { Unused in this version; see the other implementations of this routine. }
  bonus: Byte;
  { Unused in this version; see the other implementations of this routine. }
  oldLevel: Byte;
  { Unused in this version; see the other implementations of this routine. }
  levelText: array[1..5] of Byte;
begin
  character := GDVars.currentCharacter;
  effectId := item^.special and $7F;
  case effectId of
    0, 2: begin
          GDVars.handlerOverrideActive := 1;

          FxEngine.CallEffectHandler
            (item^.special, character, item, not equipping)
        end;
    1: ;
    3: FxEngine.RecalcAbility
        (character, C_Stat.STRENGTH);
    5: FxEngine.RecalcAbility
        (character, C_Stat.STRENGTH);
    8: ;
    9: if not equipping then
        FxEngine.RemoveEffect
          (character, C_Effect.SPIRITUAL_HAMMER, nil)
  end
end;

procedure ToggleReadyItem(itemPointer: Pointer);
var item: Types.PItem absolute itemPointer;
    hasSpecial: Boolean;
    error: Byte;
    slot: ShortInt;
    character: Types.PCharacter;
begin
  hasSpecial := item^.special > $7F;
  character := GDVars.currentCharacter;
  if item^.equipped <> 0 then begin
    if item^.cursed <> 0 then
      CharHlp.PrintBottomLine('It''s Cursed')
    else begin
      item^.equipped := 0;
      if hasSpecial then
        ViewChar.ToggleItemEffect(item, False)
    end
  end else begin
    error := 0;
    if character^.handsEquipped + GDVars.baseItems[item^.itemType].hands > 2 then
      error := 3;
    slot := GDVars.baseItems[item^.itemType].slot;
    case Byte(slot) of
      0..8: if character^.equipped[slot] <> nil then
             error := 2;
      9: if character^.equipped[10] <> nil then
          error := 2
    end;
    if item^.itemType = 39 then
      if not (((GDVars.currentCharacter^.robeOrder = 1) and ((item^.unidentifiedMask and $20) <> 0)) or
              ((GDVars.currentCharacter^.robeOrder = 2) and ((item^.unidentifiedMask and $10) <> 0))) then begin
        if GDVars.currentCharacter^.classLevels[C_Class.THIEF] <= 9 then
          if (GDVars.currentCharacter^.classLevels[C_Class.THIEF] < 10) and
              (GDVars.currentCharacter^.classLevels[C_Class.THIEF] > 0) then
            error := 6
          else
            error := 4
      end;
    if (item^.itemType = 67) and (GDVars.currentCharacter^.race <> C_Race.KENDER) then
      error := 5;
    if (item^.itemType = 30) and (character^.equipped[11] <> nil) then begin
      error := 2;
      slot := 11
    end;
    if (item^.itemType = 12) and (character^.equipped[12] <> nil) then begin
      error := 2;
      slot := 12
    end;
    if (GDVars.baseItems[item^.itemType].classMask and character^.classMask) = 0 then
      error := 1;
    case error of
      0: begin
          item^.equipped := 1;
          if hasSpecial then
            ViewChar.ToggleItemEffect(item, True)
        end;
      1: CharHlp.PrintBottomLine('Wrong Class');
      2: begin
          CharHlp.PrintItemString(character, character^.equipped[slot], 0, 0, False, False);
          CharHlp.PrintBottomLine('already using ' + character^.equipped[slot]^.name)
        end;
      3: if (GDVars.interfaceState <> C_Ifc.IN_COMBAT) or (character^.quickFight = 0) then
          CharHlp.PrintBottomLine('Your hands are full!');
      4: CharHlp.PrintBottomLine('Wrong Magical Order');
      5: CharHlp.PrintBottomLine('Usable Only By Kender');
      6: CharHlp.PrintBottomLine('Thief Level Too Low')
    end
  end
end;

{ Gives item to a chosen character who can carry it.
  @param(item The item.) }
procedure ItemTradeMenu(item: Types.PItem);
var target: Pointer;
begin
  if GDVars.tradeCharacter = nil then
    target := GDVars.currentCharacter
  else
    target := GDVars.tradeCharacter;
  CharHlp.DisplayNoncombatInterface;
  CharHlp.SelectChar('Trade with Whom?', True, 1, target);
  if target <> nil then begin
    GDVars.tradeCharacter := target;
    if ViewChar.CannotCarryItem(target, 0, item) then
      CharHlp.PrintBottomLine('Overloaded')
    else begin
      CharHlp.AddItemCopy(target, item);
      CharHlp.RemoveItem(GDVars.currentCharacter, item);
      CharHlp.RecalcStats(target)
    end
  end
end;

{ Splits a stack in two, the new half a pooled slot (heap for a monster in combat).
  @param(item The stack.) }
procedure HalveItem(item: Types.PItem);
var newItem: Types.PItem;
    half: Byte;
    remainder: Byte;
begin
  half := item^.quantity div 2;
  if half > 0 then begin
    remainder := item^.quantity - half;
    if (GDVars.interfaceState = C_Ifc.IN_COMBAT) and (GDVars.currentCharacter^.combat <> nil) and
        (GDVars.currentCharacter^.combat^.notPcNpc = 1)
    then
      GetMem(newItem, SizeOf(Types.TItem))
    else
      newItem := GameIo.AllocSlot;
    Move(item^, newItem^, SizeOf(Types.TItem));
    newItem^.quantity := half;
    newItem^.equipped := 0;
    newItem^.next := item^.next;
    item^.quantity := remainder;
    item^.next := newItem
  end else
    CharHlp.PrintBottomLine('Can''t halve that')
end;

procedure JoinItem(item: Types.PItem);
var
  current: Types.PItem;
  next: Types.PItem;
  destination: Types.PItem;
  quantity: Byte;
begin
  destination := item;
  quantity := destination^.quantity;
  current := GDVars.currentCharacter^.items;
  while current <> nil do begin
    next := current^.next;
    if (current <> destination) and (current^.quantity > 0) and (current^.nameIds[1] = destination^.nameIds[1]) and
        (current^.nameIds[2] = destination^.nameIds[2]) and (current^.nameIds[3] = destination^.nameIds[3]) and
        (current^.itemType = destination^.itemType) and (current^.plus = destination^.plus) and
        (current^.saveBonus = destination^.saveBonus) and (current^.cursed = destination^.cursed) and
        (current^.weight = destination^.weight) and (current^.charges = current^.charges) and (current^.charges < 2) and
        (current^.effect = current^.effect) and (current^.special = current^.special) then begin
      if quantity + current^.quantity <= 255 then begin
        Inc(quantity, current^.quantity);
        CharHlp.RemoveItem(GDVars.currentCharacter, current)
      end else begin
        destination^.quantity := 255;
        current^.quantity := current^.quantity - (255 - quantity);
        quantity := current^.quantity;
        destination := current
      end
    end;
    current := next
  end;
  destination^.quantity := quantity
end;

procedure UseItem(itemPointer: Pointer; var done: Boolean);
var item: Types.PItem absolute itemPointer;
    spell: Byte;
    index: Integer;
    notEmpty: Boolean;
    doneByte: Byte absolute done;
begin
  index := -1;
  GDVars.usingItem := 0;
  spell := 0;
  if Magic.ItemReadable(item) then begin
    GDVars.scroll := item;
    spell := ViewChar.SpellMenu(2, 1, index, notEmpty)
  end else if (item^.effect > 0) and (item^.special < $80) then begin
    GDVars.usingItem := 1;
    spell := item^.effect and $7F
  end;
  if spell = 0 then
    done := False
  else begin
    if (GDVars.interfaceState = C_Ifc.IN_COMBAT) and (GDVars.currentCharacter^.quickFight = 0) then
      CharHlp.DisplayCombatInterface;
    if GDVars.usingItem <> 0 then begin
      CharHlp.PrintCreatureMessage(GDVars.currentCharacter, 'uses an item', 10, False);
      if GDVars.interfaceState = C_Ifc.IN_COMBAT then begin
        TextRend.DisplayString(0, 23, LightGreen, Black, 'Item:');
        CharHlp.PrintItemString(GDVars.currentCharacter, item, 5, 23, False, True)
      end else
        CharHlp.PrintItemString(GDVars.currentCharacter, item, 1, 22, False, True);
      TextRend.PauseOnly;
      CharHlp.ClearMessageWindow
    end;
    GDVars.usingItem := 1;
    if Magic.ItemReadable(item) then begin
      if (GDVars.currentCharacter^.classLevels[C_Class.MAGE] > 0) or
          (GDVars.currentCharacter^.classLevels[C_Class.CLERIC] > 0) then
        Magic.CastSpell(spell, GDVars.currentCharacter^.quickFight, 0, doneByte)
      else if (GDVars.currentCharacter^.classLevels[C_Class.THIEF] > 9) and
        (FxEngine.RollDice(1, 100) <= 75) then
        Magic.CastSpell(spell, GDVars.currentCharacter^.quickFight, 0, doneByte)
      else
        CharHlp.PrintCreatureMessage(GDVars.currentCharacter, 'oops!', GDVars.currentRow + 1, True)
    end else
      Magic.CastSpell(spell, GDVars.currentCharacter^.quickFight, 0, doneByte);
    GDVars.usingItem := 0;
    if GDVars.interfaceState = C_Ifc.IN_COMBAT then
      if GDConsts.spellTable[spell].combatOk <> 0 then
        done := CharHlp.EndActions(GDVars.currentCharacter)
  end;
  if done then begin
    if Magic.ItemReadable(item) then
      Magic.RemoveSpellFromScroll(GDVars.currentCharacter, item, spell)
    else if item^.charges > 0 then begin
      if item^.quantity > 1 then
        Dec(item^.quantity)
      else begin
        Dec(item^.charges);
        if item^.charges = 0 then
          CharHlp.RemoveItem(GDVars.currentCharacter, item)
      end
    end
  end
end;

{ Offers half the item's value (per piece) and sells it for steel, the excess over what the character can carry going to
  the pool.
  @param(item The item.) }
procedure SellItem(item: Types.PItem);
var
  price: Word;
  amount: Word;
  takable: Word;
begin
  price := 0;
  if item^.value > 0 then
    price := item^.value div 2;
  if item^.quantity > 0 then
    price := price * item^.quantity;
  CharHlp.PrintItemString(GDVars.viewedCharacter, item, 0, 0, False, False);
  TextRend.DisplayMessageWindow(1, 21, 38, 22, Yellow, Black, True,
                                GDConsts.sellOfferPrefix + CharHlp.WordToString(price) + GDConsts.steelPiecesFor +
                                item^.name);
  if Char(MenuCore.YesNoMenu(GDConsts.dealQuery, GDConsts.yesKey)) = Chr(GDConsts.yesKey) then begin
    CharHlp.PrintBottomLine(GDConsts.soldText);
    CharHlp.RemoveItem(GDVars.currentCharacter, item);
    amount := price;
    if Money.CheckOverload(GDVars.currentCharacter, amount, takable) then begin
      CharHlp.PrintBottomLine(GDConsts.overloadPoolText);
      if takable > amount then
        Inc(GDVars.currentCharacter^.coins[4], amount)
      else begin
        Inc(GDVars.currentCharacter^.coins[4], takable);
        Inc(GDVars.pooledMoney[4], amount - takable)
      end
    end else
      Inc(GDVars.currentCharacter^.coins[4], amount)
  end;
  Border.ClearBox(1, 21, 38, 22)
end;

{ Identifies item for 100 steel, from the character or the pool.
  @param(item The item.)
  @param(redraw Set when the screen needs redrawing.) }
procedure IdentifyItem(item: Types.PItem; var redraw: Boolean);
var
  characterGold: LongInt;
  poolGold: LongInt;
  paid: Boolean;
begin
  paid := False;
  CharHlp.PrintItemString(GDVars.currentCharacter, item, 0, 0, False, False);
  TextRend.DisplayMessageWindow(1, 21, 38, 22, Yellow, Black, True, GDConsts.identifyOfferText + item^.name);
  if Char(MenuCore.YesNoMenu(GDConsts.dealQuery, GDConsts.yesKey)) = Chr(GDConsts.yesKey) then begin
    characterGold := GDVars.currentCharacter^.coins[4];
    poolGold := GDVars.pooledMoney[4];
    if characterGold >= 100 then begin
      paid := True;
      Dec(GDVars.currentCharacter^.coins[4], 100)
    end else if poolGold + characterGold >= 100 then begin
      paid := True;
      GDVars.currentCharacter^.coins[4] := 0;
      Dec(GDVars.pooledMoney[4], 100 - characterGold)
    end else
      CharHlp.PrintBottomLine(GDConsts.notEnoughMoneyText)
  end;
  if paid then begin
    if item^.unidentifiedMask and $07 = 0 then
      TextRend.DisplayMessageWindow(1, 21, 38, 22, Yellow, Black, True, GDConsts.identifyNoNewsText + item^.name)
    else begin
      item^.unidentifiedMask := item^.unidentifiedMask and $F8;
      CharHlp.PrintItemString(GDVars.viewedCharacter, item, 0, 0, False, False);
      TextRend.DisplayMessageWindow(1, 21, 38, 22, Yellow, Black, True, GDConsts.identifyKindText + item^.name);
      TextRend.PauseOnly;
      redraw := True
    end;
    TextRend.PauseOnly
  end;
  Border.ClearBox(1, 21, 38, 22)
end;

{ Gives coins of a chosen kind to a chosen character until the money runs out or the player leaves. }
procedure TradeTreasureMenu;
var target: Pointer;
    moneyTarget: Types.PCharacter absolute target;
    coin: ShortInt;
    coinType: ShortInt;
    column: Byte;
    menuRow: Byte;
    current: Types.PMenuRow;
    previous: Types.PMenuRow;
    list: Types.PMenuRow;
    count: Word;
    index: Integer;
    numberText: String[15];
    line: String[15];
    description: String;
    key: Char;
    amount: Word;
    exitOuter: Boolean;
    exitInner: Boolean;
    redraw: Boolean;
    redrawByte: Byte absolute redraw;
begin
  repeat
    target := GDVars.tradeCharacter;
    CharHlp.DisplayNoncombatInterface;
    CharHlp.SelectChar(GDConsts.tradeToText, True, 1, target);
    if target = nil then
      exitOuter := True
    else begin
      ViewChar.DisplayChar;
      repeat
        ViewChar.PrintMoney;
        GDVars.tradeCharacter := target;
        current := nil;
        previous := nil;
        list := nil;
        count := 0;
        for coin := 6 downto 4 do
          if GDVars.currentCharacter^.coins[coin] <> 0 then begin
            Inc(count);
            if current = nil then begin
              GetMem(current, SizeOf(Types.TMenuRow));
              current^.next := nil
            end else begin
              previous := current;
              GetMem(current, SizeOf(Types.TMenuRow));
              current^.next := previous
            end;
            numberText := CharHlp.WordToString(GDVars.currentCharacter^.coins[coin]);
            menuRow := 14 - Length(GDConsts.moneyNames[coin]);
            line := '';
            for column := 1 to menuRow do
              line := line + ' ';
            current^.name := GDConsts.moneyNames[coin] + line + numberText;
            current^.heading := 0
          end;
        list := current;
        index := 0;
        redraw := True;
        MenuCore.EnableChoices(0);
        key := Char(MenuCore.MenuVertical(GDConsts.selectCoinQuery, GDConsts.selectMenuText, 20, 9, 38, 15, current,
                                          Ord(True), Ord(False), redrawByte, index, previous));
        if (key = #1) or ((GDVars.menuExtendedKey <> 0) and (key = C_Keys.ESCAPE)) then
          previous := nil;
        if previous = nil then
          exitInner := True
        else begin
          description := '';
          coinType := Money.ParseMoneyType(previous^.name, description);
          description := GDConsts.howMuch + description + GDConsts.tradeAmountText;
          amount := Money.InputNumberMax(GDVars.currentCharacter^.coins[coinType], description, LightGreen);
          Money.TradeMoney(GDVars.currentCharacter, moneyTarget, amount, coinType);
          exitInner := True;
          exitOuter := True;
          for coin := 4 to 6 do
            if GDVars.currentCharacter^.coins[coin] > 0 then begin
              exitOuter := False;
              exitInner := False
            end
        end;
        if list <> nil then
          MenuCore.FreeMenuRows(list)
      until exitInner
    end
  until exitOuter
end;

procedure DropMoneyMenu(onSheet: Boolean);
var
  coin: ShortInt;
  coinType: ShortInt;
  menuRow: Byte;
  column: Byte;
  count: Word;
  index: Integer;
  current: Types.PMenuRow;
  previous: Types.PMenuRow;
  list: Types.PMenuRow;
  exitFlag: Boolean;
  redrawMenu: Boolean;
  redrawMenuByte: Byte absolute redrawMenu;
  numberText: String[15];
  line: String[15];
  description: String;
  key: Char;
  amount: Word;
  left: Byte;
  right: Byte;
  top: Byte;
  bottom: Byte;
begin
  repeat
    if onSheet then
      ViewChar.PrintMoney;
    current := nil;
    previous := nil;
    list := nil;
    count := 0;
    for coin := 6 downto 4 do
      if GDVars.currentCharacter^.coins[coin] <> 0 then begin
        Inc(count);
        if current = nil then begin
          GetMem(current, SizeOf(Types.TMenuRow));
          current^.next := nil
        end else begin
          previous := current;
          GetMem(current, SizeOf(Types.TMenuRow));
          current^.next := previous
        end;
        numberText := CharHlp.WordToString(GDVars.currentCharacter^.coins[coin]);
        menuRow := 18 - Length(GDConsts.moneyNames[coin]) - Length(numberText);
        line := '';
        for column := 1 to menuRow do
          line := line + ' ';
        current^.name := GDConsts.moneyNames[coin] + line + numberText;
        current^.heading := 0
      end;
    list := current;
    index := 0;
    redrawMenu := True;
    MenuCore.EnableChoices(1);
    if onSheet then begin
      left := 20;
      right := 38;
      top := 9;
      bottom := 15
    end else begin
      left := 1;
      right := 38;
      top := 17;
      bottom := 22
    end;
    key := Char(MenuCore.MenuVertical(GDConsts.selectCoinQuery, GDConsts.selectMenuText, left, top, right, bottom,
                                      current, Ord(True), Ord(True), redrawMenuByte, index, previous));
    if (previous = nil) or (key = #1) then
      exitFlag := True
    else begin
      description := '';
      coinType := Money.ParseMoneyType(previous^.name, description);
      if GDVars.interfaceState = C_Ifc.IN_VAULT then
        description := GDConsts.howMuch + description + GDConsts.giveAmountText
      else
        description := GDConsts.howMuch + description + GDConsts.dropAmountText;
      amount := Money.InputNumberMax(GDVars.currentCharacter^.coins[coinType], description, LightGreen);
      Money.DropMoney(GDVars.currentCharacter, amount, coinType);
      exitFlag := True;
      for coin := 4 to 6 do
        if GDVars.currentCharacter^.coins[coin] > 0 then
          exitFlag := False
    end;
    if list <> nil then
      MenuCore.FreeMenuRows(list)
  until exitFlag
end;

function CannotCarryItem(character: Types.PCharacter; mayStack: Byte; itemPointer: Pointer): Boolean;
var cannot: Boolean;
    weight: Word;
    current: Types.PItem;
    duplicate: Boolean;
    item: Types.PItem absolute itemPointer;
begin
  CharHlp.RecalcStats(character);
  cannot := False;
  duplicate := False;
  current := character^.items;
  if (item^.quantity > 0) and (mayStack <> 0) then
    while (not duplicate) and (current <> nil) do begin
    duplicate := (current^.nameIds[1] = item^.nameIds[1]) and (current^.nameIds[2] = item^.nameIds[2]) and
      (current^.nameIds[3] = item^.nameIds[3]) and (current^.itemType = item^.itemType) and
      (current^.plus = item^.plus) and (current^.saveBonus = item^.saveBonus) and (current^.cursed = item^.cursed) and
      (current^.weight = item^.weight) and (current^.charges = item^.charges) and (current^.charges < 2) and
      (current^.effect = item^.effect) and (current^.special = item^.special);
    current := current^.next
  end;
  if (character^.numberOfItems > 15) and (not duplicate) then
    cannot := True;
  weight := item^.weight;
  if item^.quantity > 0 then
    weight := weight * item^.quantity;
  if character^.encumbrance + weight > CharHlp.WeightAllowance(character) + 1500 then
    cannot := True;
  CannotCarryItem := cannot
end;

procedure SelectAdjacentCharacter(key: Char);
var current: Types.PCharacter;
    selector: Char;
begin
  if (GDVars.mousePresent <> 0) and (GDVars.mouseClick <> 0) and (GDVars.mouseCharacter <> nil) then begin
    GDVars.currentCharacter := GDVars.mouseCharacter;
    GDVars.mouseCharacter := nil
  end else begin
    selector := key;
    current := GDVars.partyHead;
    if current <> nil then
      case selector of
        C_Keys.UP: begin
          if Pointer(current) = Pointer(GDVars.currentCharacter) then begin
            while current^.next <> nil do
              current := current^.next
          end else
            while (current <> nil) and (Pointer(current^.next) <> Pointer(GDVars.currentCharacter)) do
              current := current^.next;
          GDVars.currentCharacter := current
        end;
        C_Keys.DOWN: begin
          if GDVars.currentCharacter^.next <> nil then
            current := GDVars.currentCharacter^.next
          else
            current := GDVars.partyHead;
          GDVars.currentCharacter := current
        end
      end
  end
end;

function SpellMenu(listMode, selectionType: Byte; var index: Integer; var hasSpells: Boolean): Byte;
var heading: Types.TString40;
    { Unused in this version; see the other implementations of this routine. }
    hasSpellsByte: Byte absolute hasSpells;
begin
  case listMode of
    0: heading := 'in Memory';
    1: heading := 'in Grimoire';
    2: heading := 'on Scroll';
    3: heading := 'on Scrolls';
    4: heading := 'to Choose';
    5: heading := 'to Memorize';
    6: heading := 'to Scribe'
  else
    heading := ''
  end;
  GDVars.selectedChoice := 1;
  hasSpellsByte := Magic.GenerateSpellList(listMode);
  if hasSpells then begin
    if (index < 0) or (selectionType = 1) then begin
      if selectionType = 2 then
        Border.DrawMemorizeFrame
      else
        Border.DrawTitleInset
    end;
    CharHlp.DisplayCreatureName(GDVars.currentCharacter, 1, 1, True);
    TextRend.DisplayString(Length(GDVars.currentCharacter^.name) + 4, 1, LightGreen, Black, 'Spells ' + heading);
    SpellMenu := Magic.SpellSelection(selectionType, index)
  end else
    SpellMenu := 0
end;

function CanHeal(character: Types.PCharacter): Boolean;
var found: Types.PEffect;
begin
  CanHeal := (character^.characterClass = C_Class.PALADIN) and
    (GDVars.interfaceState <> C_Ifc.IN_COMBAT) and (character^.status = C_Status.OKAY) and
    (not CharHlp.HasEffect(character, 109, found))
end;

function CanCure(character: Types.PCharacter): Boolean;
begin
  CanCure := (character^.characterClass = C_Class.PALADIN) and
    (GDVars.interfaceState <> C_Ifc.IN_COMBAT) and (character^.status = C_Status.OKAY) and
    (character^.cureAbility > 0)
end;

procedure PaladinLayOnHands(character: Types.PCharacter);
var target: Types.PCharacter;
begin
  CharHlp.DisplayNoncombatInterface;
  target := GDVars.partyHead;
  CharHlp.SelectChar('Heal whom? ', True, 1, Pointer(target));
  if target = nil then
    ViewChar.DisplayChar
  else begin
    if
       FxEngine.RestoreHitPoints(target, Byte(character^.classLevels[C_Class.PALADIN] * 2), True) then
      CharHlp.PrintBottomLine(target^.name + ' feels better')
    else
      CharHlp.PrintBottomLine(target^.name + ' is unaffected');
    FxEngine.AddEffect(character, 109, 1440, 0, False);
    ViewChar.DisplayChar
  end
end;

procedure PaladinCureDisease(character: Types.PCharacter);
var target: Types.PCharacter;
    { Unused in this version; see the other implementations of this routine. }
    effect: array[1..6] of Byte;
begin
  CharHlp.DisplayNoncombatInterface;
  target := GDVars.partyHead;
  CharHlp.SelectChar('Cure whom? ', True, 1, Pointer(target));
  ViewChar.DisplayChar;
  if target = nil then begin
    ViewChar.DisplayChar
  end else begin
  end
end;

function PickCharacter: Boolean;
var key: Char;
    saved: Byte;
begin
  saved := GDVars.mouseMode;
  GDVars.mouseMode := 1;
  repeat
    MenuCore.EnableChoices(1);
    key := Char(MenuCore.MenuHorizontal(GDConsts.pickCharacterText, GDConsts.selectMenuText, Ord(True), Ord(False)));
    if GDVars.menuExtendedKey <> 0 then begin
      if key = C_Keys.ESCAPE then begin
        key := #1;
        GDVars.menuExtendedKey := 0
      end else begin
        CharHlp.DisplayRoster(GDVars.currentCharacter, False);
        ViewChar.SelectAdjacentCharacter(key);
        CharHlp.DisplayRoster(GDVars.currentCharacter, True)
      end
    end
  until (GDVars.menuExtendedKey = 0) and (key <= #1);
  CharHlp.DisplayRoster(GDVars.currentCharacter, True);
  PickCharacter := key = #0;
  GDVars.mouseMode := saved
end;

function ClassConHpBonus(character: Types.PCharacter; classId: Byte): ShortInt;
var score: ShortInt;
    { Unused in this version; see the other implementations of this routine. }
    conScore: Byte;
begin
  score := 0;
  Inc(score, GDConsts.constitutionHitPointTable[character^.stats[C_Stat.CONSTITUTION].current]);
  { the fighting classes }
  if (classId = C_Class.FIGHTER) or (classId = C_Class.KNIGHT) or (classId = C_Class.PALADIN) or
      (classId = C_Class.RANGER) then
    case character^.stats[C_Stat.CONSTITUTION].current of
      17: Inc(score);
      18: Inc(score, 2);
      19, 20: Inc(score, 3);
      21..23: Inc(score, 4);
      24, 25: Inc(score, 5)
    end;
  ClassConHpBonus := score
end;

procedure AdjustLevelHitPoints(character: Types.PCharacter; classMask, divisor: Byte; gaining: Boolean);
var
  firstRoll: Byte;
  secondRoll: Byte;
  total: Byte;
  level: Byte;
  secondary: Byte;
  index: ShortInt;
  amount: Byte;
  cap: Byte;
begin
  total := 0;
  secondary := 0;
  for index := 0 to 7 do
    if (character^.classLevels[index] > 0) and (GDConsts.trainingClassBits[index] and classMask > 0) then begin
      if Byte(character^.classLevels[index]) < GDConsts.firstFixedHpLevel[index] then begin
        if character^.classLevels[index] > 1 then
          level := 1
        { Sirrion, Reorx, Shinare: one die }
        else if (index = C_Class.CLERIC) and (character^.deity > 4) then
          level := 1
        else
          level := GDConsts.firstLevelHitDice[index];
        firstRoll := FxEngine.RollDice(level, GDConsts.hitDieSides[index]);
        secondRoll := FxEngine.RollDice(level, GDConsts.hitDieSides[index]);
        if secondRoll > firstRoll then
          firstRoll := secondRoll;
        Inc(total, firstRoll);
        Inc(secondary, level * ViewChar.ClassConHpBonus(character, index))
      end else case index of
        C_Class.FIGHTER, C_Class.PALADIN, C_Class.KNIGHT: total := 3;
        C_Class.RANGER, C_Class.CLERIC, C_Class.THIEF: total := 2;
        C_Class.MAGE: total := 1
      end
    end;
  with character^ do begin
    if divisor > 0 then begin
      total := total div divisor;
      if total < 1 then total := 1;
      secondary := secondary div divisor;
      { reused for the damage taken }
      firstRoll := maxHitPoints - hitPoints;
      if gaining then begin
        Inc(baseMaxHitPoints, total);
        Inc(maxHitPoints, total + secondary);
        if firstRoll > maxHitPoints then
          hitPoints := 0
        else
          hitPoints := maxHitPoints - firstRoll
      end else begin
        if baseMaxHitPoints > total then
          Dec(baseMaxHitPoints, total)
        else
          baseMaxHitPoints := 0;
        amount := total + secondary;
        cap := ViewChar.HitPointCap(character);
        if maxHitPoints - amount > cap then
          amount := maxHitPoints - cap;
        if amount > maxHitPoints then
          maxHitPoints := 0
        else
          Dec(maxHitPoints, amount);
        if firstRoll > maxHitPoints then
          hitPoints := 0
        else
          hitPoints := maxHitPoints - firstRoll
      end
    end else begin
      hitPoints := 0;
      baseMaxHitPoints := 0;
      maxHitPoints := 0
    end
  end
end;

function HitPointCap(character: Types.PCharacter): Byte;
var count: Byte;
    sum: Word;
    modifier: ShortInt;
    index: ShortInt;
    excess: Byte;
begin
  with character^ do begin
    count := 0;
    sum := 0;
    for index := 0 to 7 do
      if classLevels[index] > 0 then begin
        modifier := CharHlp.ClassConAdj(character, index);
        if Byte(classLevels[index]) < GDConsts.firstFixedHpLevel[index] then begin
          Inc(count);
          case index of
            C_Class.CLERIC: if deity <= 4 then
                Inc(sum, (modifier + 8) * (classLevels[index] + 1))
              else
                Inc(sum, (modifier + 8) * classLevels[index]);
            1: Inc(sum, (modifier + 8) * classLevels[index]);
            C_Class.FIGHTER, C_Class.PALADIN: Inc(sum, (modifier + 10) * classLevels[index]);
            C_Class.KNIGHT: Inc(sum, (modifier + 10) * (classLevels[index] + 1));
            C_Class.RANGER: Inc(sum, (modifier + 8) * (classLevels[index] + 1));
            C_Class.MAGE: Inc(sum, (modifier + 4) * classLevels[index]);
            C_Class.THIEF: Inc(sum, (modifier + 6) * classLevels[index])
          end
        end else begin
          Inc(count);
          excess := classLevels[index] - GDConsts.firstFixedHpLevel[index] + 1;
          case index of
            C_Class.CLERIC: Inc(sum, (modifier * 9 + 72) + excess * 2);
            1: Inc(sum, 112);
            C_Class.FIGHTER, C_Class.PALADIN, C_Class.KNIGHT:
              Inc(sum, (modifier * 9 + 90) + excess * 3);
            C_Class.RANGER: Inc(sum, (modifier * 11 + 88) + excess * 2);
            C_Class.MAGE: Inc(sum, (modifier * 11 + 44) + excess);
            C_Class.THIEF: Inc(sum, (modifier * 10 + 60) + excess * 2)
          end
        end
      end;
    if count > 0 then
      sum := sum div count
    else
      sum := 0;
    HitPointCap := Lo(sum)
  end
end;

procedure NoopViewChar;
begin
end;
begin
end.
