{ CharGen -- the party menu and what it reaches: creating, adding, dropping, modifying and training characters, their
  combat icons, a knight's order, the starting kit, the input devices, and removing a member from the party. }
{$F+,O+,S-,R-,V-,B-,I-}
unit CharGen;
interface
uses C_Class, C_Effect, C_Ifc, C_Keys, C_Npc, C_Race, C_Spell, C_Stat, C_Status, GDConsts, GDVars, Types, MenuCore,
  TextRend, CharHlp, ViewChar, SaveLoad, Border, FxEngine, Mouse, Joystick, GameIo, MapTiles, ClassCal, Blit, CbtMap,
  Crt, GameInit;

{ The party menu, for FixMain: Create, Drop, Modify, Train, Knight Change Order, View, Add, Remove, Load Saved Game,
  Save Current Game, Begin Adventuring, Initialize Mouse/Joystick and Exit to DOS, each enabled as the party allows; it
  runs until the adventure begins. }
procedure MainMenu;

{ Adds saved characters to the party. Asks where to load from, then lists the saved characters and adds each one picked,
  marking it with '*'. A character already in the party is refused, as are a seventh player character, a ninth member,
  and a fourth ranger. }
procedure AddCharacterMenu;

{ Unlinks the current character from the party roster and frees it. Its predecessor, or else the roster head, becomes
  the current character. A character that is not in the roster is left untouched.
  @param(keepCount True leaves the party size alone.)
  @param(freeIcon True also frees the character's icon animation.) }
procedure RemoveCreature(keepCount, freeIcon: Boolean);

{ The icon editor: head, body, colors and size for the current character, previewed as it changes. }
procedure CustomizeIcon;

{ Training at a hall: levels in the classes the hall trains, when the character has the experience and is conscious; the
  zone's train mask limits the classes. }
procedure TrainingMenu;

{ The current character's default icon head (by race, gender and size) and body (by class). }
procedure SetDefaultIcon;

{ Creates a character: race, gender, class, alignment, deity or order, rolled abilities (rerolled on request), name and
  icon, and saves it. Note: the racial ability adjustments test the race menu's loop counter, which that loop leaves at
  human, instead of the race chosen, so no race adjusts the rolls. }
procedure CreateCharacterMenu;

{ Deletes a chosen character's files and removes it, after asking twice. }
procedure DropCharacterMenu;

{ Lets the player set a new character's abilities and hit points by hand. }
procedure ModifyCharacterMenu;

{ Works out the lowest maximum hit points a character may be given: one point per level of each class (a level more for
  a ranger or knight) plus each class's Constitution bonus, averaged over the classes, at least 1 when the bonus is
  negative.
  @param(character The character.)
  @returns(The minimum.) }
function HpMinimum(character: Types.PCharacter): Byte;

{ Gives a new character the starting kit for its class group (knight, warriors, thief, cleric, other), readied except
  item 91; numberOfItems is then set to 3 whatever the kit held.
  @param(character The new character.) }
procedure CreateStartingItems(character: Pointer);

{ A knight's petition to rise to the next order (Crown, Sword, Rose) when it meets the order's requirements. }
procedure KnightPromotionMenu;

{ Lets the player turn the mouse or joystick on or off, or disable both, calibrating the joystick when it is turned on.
  Each change rewrites the configuration file: line 3 holds the input mode (M, J, or N) and the joystick calibration, or
  zeros, follow the five header lines. }
procedure InitMouseJoystick;

{ Calibrates joystick 1 in the text window, like Joystick.CalibrateJoystick: exits at once when Joystick.ProbeJoystick
  finds no stick; otherwise the center from 20 readings, then the upper-left and lower-right extremes with button 1
  down, and boundaries a third and two thirds of the way to the center. 20000 polls without a press, or a failed read,
  abort with "Unable to read joystick"; success enables the joystick. }
procedure CalibrateJoystickInWindow;

{ Frees character's combat block, spell block, items and effects and the record itself, and sets it to nil.
  @param(character Character to free; nil on return.) }
procedure FreeCreature(var character: Types.PCharacter);
implementation
const
  { Multiclass values, in classNames order. }
  CLASS_CLERIC_MAGE = 11;
  CLASS_CLERIC_THIEF = 12;
  CLASS_FIGHTER_MAGE = 13;
  { the Delete key, an extended scan code }
  KEY_DEL = #83;
type
  TTrainMaskIndex = $8400..$FFFF;
  { CreateCharacterMenu's working values, three readings of one variable }
  TCreateWorkspace = record
    case Byte of
      { unused }
      0: (allowedLead: Byte;
         { the class's alignment bits, masked and shifted }
         allowed: Byte;
         { alignments the chosen deity permits, one bit each }
         deityAlignments: Byte;
         optionValues: array[0..5] of Byte;
         optionValuesTail: array[9..52] of Byte);
      1: (savedSettingLead: array[0..8] of Byte; savedSetting: Byte);
      2: (savedSettingTail: array[0..9] of Byte;
         line: String[40];
         keepFlag: Boolean)
  end;
var trainMaskIndex: TTrainMaskIndex absolute GDConsts.trainMaskIndex;

procedure FreeCreature(var character: Types.PCharacter);
var
  oldItem: Types.PItem;
  item: Types.PItem;
  oldEffect: Types.PEffect;
  effect: Types.PEffect;
begin
  with character^ do begin
    if combat <> nil then FreeMem(combat, SizeOf(Types.TCombat));
    if spells <> nil then FreeMem(spells, SizeOf(Types.TSpellBlock));
    item := items;
    while item <> nil do begin
      oldItem := item;
      item := item^.next;
      GameIo.FreeSlot(oldItem)
    end;
    effect := effects;
    while effect <> nil do begin
      oldEffect := effect;
      effect := effect^.next;
      FreeMem(oldEffect, SizeOf(Types.TEffect))
    end
  end;
  FreeMem(character, SizeOf(Types.TCharacter));
  character := nil
end;

procedure MainMenu;
var
  index: Byte;
  searchIndex: Byte;
  { Unused in this version; see the other implementations of this routine. }
  key: Char;
  { Unused in this version; see the other implementations of this routine. }
  menuChoice: array[0..1] of Byte;
  redraw: Boolean;
  redrawByte: Byte absolute redraw;
  { Unused in this version; see the other implementations of this routine. }
  needsRebuild: array[0..8] of Byte;
  count: ShortInt;
  loopActive: Byte;
  { Unused in this version; see the other implementations of this routine. }
  before: Byte;
  list: Pointer;
  listNode: Types.PMenuRow absolute list;
  selected: Pointer;
  current: Types.PMenuRow;
  saved: Word;
  savedInteger: Integer absolute saved;
  found: Boolean;
  { Unused in this version; see the other implementations of this routine. }
  other: Byte;
begin
  GDVars.mouseMode := 0;
  GDVars.previousInterfaceState := GDVars.interfaceState;
  GDVars.interfaceState := C_Ifc.MAIN_MENU;
  loopActive := 1;
  GDVars.testTrainMode := 0;
  saved := 0;
  other := 0;
  repeat
    if loopActive <> 0 then begin
      Border.DrawWindowFrame(0);
      if GDVars.currentCharacter <> nil then begin
      CharHlp.DisplayParty(GDVars.currentCharacter);
      GDConsts.partyMenuItems[1].enabled := 1;
      GDConsts.partyMenuItems[2].enabled := 1;
      GDConsts.partyMenuItems[3].enabled := Byte((GDVars.zone1^.trainMask[trainMaskIndex + $7C00] > 0) or
                                  (GDVars.testTrainMode <> 0));
      GDConsts.partyMenuItems[4].enabled := GDConsts.partyMenuItems[3].enabled;
      GDConsts.partyMenuItems[5].enabled := 1;
      GDConsts.partyMenuItems[7].enabled := 1;
      GDConsts.partyMenuItems[8].enabled := 0;
      GDConsts.partyMenuItems[9].enabled := 1;
      GDConsts.partyMenuItems[10].enabled := 1;
      GDConsts.partyMenuItems[11].enabled := 0
      end else begin
      GDConsts.partyMenuItems[1].enabled := 0;
      GDConsts.partyMenuItems[2].enabled := 0;
      GDConsts.partyMenuItems[3].enabled := 0;
      GDConsts.partyMenuItems[4].enabled := 0;
      GDConsts.partyMenuItems[5].enabled := 0;
      GDConsts.partyMenuItems[7].enabled := 0;
      GDConsts.partyMenuItems[8].enabled := 1;
      GDConsts.partyMenuItems[9].enabled := 0;
      GDConsts.partyMenuItems[10].enabled := 0;
      GDConsts.partyMenuItems[11].enabled := 1
      end;
      count := 0;
      for index := 0 to 12 do
        if GDConsts.partyMenuItems[index].enabled <> 0 then
          Inc(count);
      MenuCore.AllocStringList(count, listNode);
      current := list;
      for index := 0 to 12 do
        if GDConsts.partyMenuItems[index].enabled <> 0 then begin
          current^.name := GDConsts.partyMenuItems[index].caption;
          current := current^.next
        end
      end;
    redraw := True;
    MenuCore.EnableChoices(0);
    key := Char(MenuCore.MenuVertical(GDConsts.emptyQuery, GDConsts.selectMenuText, 9, 12, 38, 22, list, 0, 0,
                                      redrawByte, savedInteger,
                                      selected));
    searchIndex := 0;
    found := False;
    while (searchIndex < 13) and not found do begin
      found := GDConsts.partyMenuItems[searchIndex].caption = Types.PMenuRow(selected)^.name;
      if not found then
        Inc(searchIndex)
    end;
    if loopActive <> 0 then
      MenuCore.FreeMenuRows(listNode);
    if (searchIndex <> 9) and (searchIndex <> 12) then
      GDVars.recentlySaved := 0;
    case searchIndex of
      0: if GDConsts.partyMenuItems[0].enabled <> 0 then CharGen.CreateCharacterMenu;
      1: if GDConsts.partyMenuItems[1].enabled <> 0 then CharGen.DropCharacterMenu;
      2: if GDConsts.partyMenuItems[2].enabled <> 0 then CharGen.ModifyCharacterMenu;
      3: if GDConsts.partyMenuItems[3].enabled <> 0 then CharGen.TrainingMenu;
      4: if GDConsts.partyMenuItems[4].enabled <> 0 then CharGen.KnightPromotionMenu;
      5: if GDConsts.partyMenuItems[5].enabled <> 0 then
          if ViewChar.PickCharacter then
            ViewChar.ViewCharMenu(redraw);
      6: if GDConsts.partyMenuItems[6].enabled <> 0 then CharGen.AddCharacterMenu;
      7: if (GDConsts.partyMenuItems[7].enabled <> 0) and (GDVars.currentCharacter <> nil) and
        ViewChar.PickCharacter then
          if GDVars.currentCharacter^.npc < C_Npc.NON_PLAYER then begin
            SaveLoad.SaveChar(GDVars.currentCharacter, '');
            CharGen.RemoveCreature(False, True)
          end else
            CharGen.DropCharacterMenu;
      8: if GDConsts.partyMenuItems[8].enabled <> 0 then SaveLoad.LoadGame;
      9: if (GDConsts.partyMenuItems[9].enabled <> 0) and (GDVars.partyHead <> nil) then SaveLoad.SaveGame;
      10: if GDConsts.partyMenuItems[10].enabled <> 0 then begin
           GDVars.mouseMode := 1;
           if (GDVars.partyHead <> nil) or (GDVars.demoMode <> 0) then begin
             GDVars.interfaceState := GDVars.previousInterfaceState;
             if (GDVars.loadedSave = 0) or (GDVars.pictureArchiveId = 9) then begin
               if (GDVars.interfaceState = C_Ifc.OVERLAND) and (GDVars.zone0^.wildOn = 1) then
                 Border.DrawRowDivider
               else
                 Border.DrawViewFrame;
               CharHlp.DisplayParty(GDVars.currentCharacter)
             end else
               case GDVars.interfaceState of
                 C_Ifc.MAIN_MENU, C_Ifc.VIEW_3D: begin
                       Border.DrawViewFrame;
                       CharHlp.DisplayParty(GDVars.currentCharacter)
                     end;
                 C_Ifc.OVERLAND: Border.DrawRowDivider
               end;
             MenuCore.ClearBottomLine;
             GDVars.zone1^.trainMask[trainMaskIndex + $7C00] := 0;
             Exit
           end
         end;
      11: if GDConsts.partyMenuItems[11].enabled <> 0 then CharGen.InitMouseJoystick;
      12: if GDConsts.partyMenuItems[12].enabled <> 0 then
           if Char(MenuCore.YesNoMenu(GDConsts.quitToDosPrompt, GDConsts.noKey)) = Chr(GDConsts.yesKey) then begin
             if (GDVars.partyHead <> nil) and (GDVars.recentlySaved = 0) then begin
               if Char(MenuCore.YesNoMenu(GDConsts.quitUnsavedQuery, GDConsts.noKey)) = Chr(GDConsts.noKey) then
                 SaveLoad.SaveGame
               else
                 GameIo.ExitGame
             end;
             GameIo.ExitGame
           end
    end;
    if ((searchIndex = 1) or (searchIndex = 7)) and (GDVars.currentCharacter = nil) and
        (GDVars.partyHead = nil) then begin
      GameInit.ResetGameState;
      GDVars.mouseMode := 0;
      GDVars.previousInterfaceState := GDVars.interfaceState;
      GDVars.interfaceState := C_Ifc.MAIN_MENU;
      loopActive := 1;
      GDVars.testTrainMode := 0;
      saved := 0;
      other := 1;
      GDVars.restartLoop := 1
    end;
  until GDConsts.gameDone <> 0
end;

procedure CreateCharacterMenu;
var newCharacter: Types.PCharacter;
    savedCharacter: Types.PCharacter;
    menu: Pointer;
    menuNode: Types.PMenuRow absolute menu;
    item: Pointer;
    selected: Integer;
    index: Byte;
    optionCount: Byte;
    roll: Byte;
    key: Char;
    { Unused in this version; see the other implementations of this routine. }
    raceChoice: Byte;
    raceIndex: ShortInt;
    genderIndex: ShortInt;
    scanIndex: ShortInt;
    scanIndex2: ShortInt;
    choiceCount: Byte;
    { Unused in this version; see the other implementations of this routine. }
    alignmentIndex: Byte;
    { Unused in this version; see the other implementations of this routine. }
    conBonus: Byte;
    { Unused in this version; see the other implementations of this routine. }
    classCount: Byte;
    abilityCount: Byte;
    { Unused in this version; see the other implementations of this routine. }
    abilityScratch: Byte;
    other: Boolean;
    redraw: Boolean;
    otherByte: Byte absolute other;
    redrawByte: Byte absolute redraw;
    workspace: TCreateWorkspace;
begin
  GetMem(newCharacter, SizeOf(Types.TCharacter));
  FillChar(newCharacter^, SizeOf(Types.TCharacter), 0);
  with newCharacter^ do begin
  for index := 1 to 6 do
    iconColors[index] := GDConsts.iconColorSlots[index] + (GDConsts.iconColorSlots[index] + 8) * 16;
  baseArmorClass := 50;
  thac0Base := 40;
  status := C_Status.OKAY;
  enabled := 1;
  iconDimensions := 1;
  identity := Random(256);
  orderNumber := 10;
  end;
  MenuCore.AllocStringList(8, menuNode);
  Types.PMenuRow(menu)^.heading := 1;
  Types.PMenuRow(menu)^.name := GDConsts.pickRaceMenu;
  for raceIndex := 0 to 6 do begin
    item := MenuCore.MenuRowAt(raceIndex + 1, menuNode);
    Types.PMenuRow(item)^.name := '  ' + GDConsts.raceNames[raceIndex]
  end;
  item := menu;
  selected := 1;
  redraw := True;
  other := True;
  MenuCore.EnableChoices(0);
  repeat
    key := Char(MenuCore.MenuVertical(GDConsts.emptyQuery, GDConsts.selectMenuText, 1, 2, 38, 22, menu, otherByte, 0,
                                      redrawByte,
                                      selected, item));
    if ((GDVars.menuExtendedKey <> 0) and (key = C_Keys.ESCAPE)) or
        ((GDVars.menuExtendedKey = 0) and (key > #0)) then begin
      MenuCore.FreeMenuRows(menuNode);
      CharGen.FreeCreature(newCharacter);
      Exit
    end
  until key = #0;
  with newCharacter^ do begin
  race := selected - 1;
  case race of
    C_Race.KENDER: begin
        iconSize := 1;
        FxEngine.AddEffect(newCharacter, C_Effect.IMMUNE_FEAR, 0, 255, False);
        FxEngine.AddEffect(newCharacter, C_Effect.CONSTITUTION_SAVE_BONUS, 0, 255, False)
      end;
    C_Race.MOUNTAIN_DWARF, C_Race.HILL_DWARF: begin
          iconSize := 1;
          FxEngine.AddEffect(newCharacter, C_Effect.CONSTITUTION_SAVE_BONUS, 0, 255, False);
          FxEngine.AddEffect(newCharacter, C_Effect.DWARF_THAC0, 0, 255, False);
          FxEngine.AddEffect(newCharacter, C_Effect.DWARF_ARMOR_CLASS_VS_GIANTS, 0, 255, False)
        end;
    C_Race.SILVANESTI_ELF, C_Race.QUALINESTI_ELF: begin
          iconSize := 2;
          FxEngine.AddEffect(newCharacter, C_Effect.ELF_RESISTANCE, 0, 255, False)
        end;
    C_Race.HALF_ELF: begin
        iconSize := 2;
        FxEngine.AddEffect(newCharacter, C_Effect.HALF_ELF_RESISTANCE, 0, 255, False)
      end else
      iconSize := 2
  end;
  end;
  MenuCore.FreeMenuRows(menuNode);
  MenuCore.AllocStringList(3, menuNode);
  Types.PMenuRow(menu)^.heading := 1;
  Types.PMenuRow(menu)^.name := GDConsts.pickGenderMenu;
  for genderIndex := 0 to 1 do begin
    item := MenuCore.MenuRowAt(genderIndex + 1, menuNode);
    Types.PMenuRow(item)^.name := '  ' + GDConsts.genderNames[genderIndex]
  end;
  item := menu;
  selected := 1;
  other := True;
  redraw := True;
  repeat
    key := Char(MenuCore.MenuVertical(GDConsts.emptyQuery, GDConsts.selectMenuText, 1, 2, 38, 22, menu, otherByte, 0,
                                      redrawByte,
                                      selected, item));
    if ((GDVars.menuExtendedKey <> 0) and (key = C_Keys.ESCAPE)) or
        ((GDVars.menuExtendedKey = 0) and (key > #0)) then begin
      MenuCore.FreeMenuRows(menuNode);
      CharGen.FreeCreature(newCharacter);
      Exit
    end
  until key = #0;
  newCharacter^.gender := selected - 1;
  MenuCore.FreeMenuRows(menuNode);
  choiceCount := GDConsts.raceClasses[newCharacter^.race].count;
  MenuCore.AllocStringList(choiceCount + 1, menuNode);
  Types.PMenuRow(menu)^.heading := 1;
  Types.PMenuRow(menu)^.name := GDConsts.pickClassMenu;
  for index := 1 to choiceCount do begin
    item := MenuCore.MenuRowAt(index, menuNode);
    Types.PMenuRow(item)^.name := '  ' + GDConsts.classNames[GDConsts.raceClasses[newCharacter^.race].classId[index]]
  end;
  item := menu;
  selected := 1;
  other := True;
  redraw := True;
  repeat
    key := Char(MenuCore.MenuVertical(GDConsts.emptyQuery, GDConsts.selectMenuText, 1, 2, 38, 22, menu, otherByte, 0,
                                      redrawByte,
                                      selected, item));
    if ((GDVars.menuExtendedKey <> 0) and (key = C_Keys.ESCAPE)) or
        ((GDVars.menuExtendedKey = 0) and (key > #0)) then begin
      MenuCore.FreeMenuRows(menuNode);
      CharGen.FreeCreature(newCharacter);
      Exit
    end
  until key = #0;
  with newCharacter^ do begin
  experience := 0;
  characterClass := GDConsts.raceClasses[race].classId[selected];
  if (characterClass = C_Class.FIGHTER) or (characterClass = C_Class.THIEF) or
      (characterClass = C_Class.FIGHTER_THIEF) then
    spells := nil
  else begin
    GetMem(spells, SizeOf(Types.TSpellBlock));
    FillChar(spells^, SizeOf(Types.TSpellBlock), 0)
  end;
  case characterClass of
    C_Class.CLERIC: begin
        classLevels[C_Class.CLERIC] := 1;
        experience := 210003
      end;
    C_Class.THIEF: begin
        classLevels[C_Class.THIEF] := 1;
        experience := 210003
      end;
    C_Class.FIGHTER: begin
        classLevels[C_Class.FIGHTER] := 1;
        experience := 210003
      end;
    C_Class.MAGE: begin
        classLevels[C_Class.MAGE] := 1;
        experience := 210003
      end;
    C_Class.RANGER: begin
        classLevels[C_Class.RANGER] := 2;
        experience := 210003;
        FxEngine.AddEffect(newCharacter, C_Effect.RANGER_BONUS_DAMAGE, 0, 255, False)
      end;
    C_Class.KNIGHT: begin
        classLevels[C_Class.KNIGHT] := 1;
        experience := 210003;
        knightOrder := 1
      end;
    C_Class.PALADIN: begin
        classLevels[C_Class.PALADIN] := 1;
        experience := 210003;
        FxEngine.AddEffect(newCharacter, C_Effect.PROTECTION_FROM_EVIL_RADIUS, 0, 255, False)
      end;
    C_Class.CLERIC_FIGHTER: begin
        classLevels[C_Class.CLERIC] := 1;
        classLevels[C_Class.FIGHTER] := 1;
        experience := 105002
      end;
    C_Class.CLERIC_FIGHTER_MAGE: begin
        classLevels[C_Class.CLERIC] := 1;
        classLevels[C_Class.FIGHTER] := 1;
        classLevels[C_Class.MAGE] := 1;
        experience := 70001
      end;
    C_Class.CLERIC_RANGER: begin
         classLevels[C_Class.CLERIC] := 1;
         classLevels[C_Class.RANGER] := 1;
         FxEngine.AddEffect(newCharacter, C_Effect.RANGER_BONUS_DAMAGE, 0, 255, False);
         experience := 105002
       end;
    CharGen.CLASS_CLERIC_MAGE: begin
         classLevels[C_Class.CLERIC] := 1;
         classLevels[C_Class.MAGE] := 1;
         experience := 105002
       end;
    CharGen.CLASS_CLERIC_THIEF: begin
         classLevels[C_Class.CLERIC] := 1;
         classLevels[C_Class.THIEF] := 1;
         experience := 105002
       end;
    CharGen.CLASS_FIGHTER_MAGE: begin
         classLevels[C_Class.FIGHTER] := 1;
         classLevels[C_Class.MAGE] := 1;
         experience := 105002
       end;
    C_Class.FIGHTER_THIEF: begin
         classLevels[C_Class.FIGHTER] := 1;
         classLevels[C_Class.THIEF] := 1;
         experience := 105002
       end;
    C_Class.FIGHTER_MAGE_THIEF: begin
         classLevels[C_Class.FIGHTER] := 1;
         classLevels[C_Class.MAGE] := 1;
         classLevels[C_Class.THIEF] := 1;
         experience := 70001
       end;
    C_Class.MAGE_THIEF: begin
         classLevels[C_Class.MAGE] := 1;
         classLevels[C_Class.THIEF] := 1;
         experience := 105002
       end
  end;
  if classLevels[C_Class.THIEF] > 0 then
    ClassCal.RecalcThiefSkills(newCharacter);
  classMask := 0;
  thac0Base := 0;
  for scanIndex := 0 to 7 do
    if classLevels[scanIndex] > 0 then begin
      if GDConsts.thac0Table[scanIndex, classLevels[scanIndex]] > thac0Base then
        thac0Base := GDConsts.thac0Table[scanIndex, classLevels[scanIndex]];
      Inc(classMask, GDConsts.classMaskBits[scanIndex])
    end;
  ClassCal.RecalcSaves(newCharacter);
  end;
  if newCharacter^.classLevels[C_Class.CLERIC] > 0 then begin
    MenuCore.FreeMenuRows(menuNode);
    if (newCharacter^.race = C_Race.MOUNTAIN_DWARF) or (newCharacter^.race = C_Race.HILL_DWARF) then begin
      MenuCore.AllocStringList(2, menuNode);
      Types.PMenuRow(menu)^.heading := 1;
      Types.PMenuRow(menu)^.name := GDConsts.pickDeityMenu;
      item := MenuCore.MenuRowAt(1, menuNode);
      Types.PMenuRow(item)^.name := '  ' + GDConsts.deityNames[6]
    end else begin
      MenuCore.AllocStringList(8, menuNode);
      Types.PMenuRow(menu)^.heading := 1;
      Types.PMenuRow(menu)^.name := GDConsts.pickDeityMenu;
      for index := 1 to 7 do begin
        item := MenuCore.MenuRowAt(index, menuNode);
        Types.PMenuRow(item)^.name := '  ' + GDConsts.deityNames[ShortInt(index)]
      end
    end;
    item := menu;
    selected := 1;
    other := True;
    redraw := True;
    repeat
      key := Char(MenuCore.MenuVertical(GDConsts.emptyQuery, GDConsts.selectMenuText, 1, 2, 38, 22, menu, otherByte, 0,
                                        redrawByte,
                                        selected, item));
      if ((GDVars.menuExtendedKey <> 0) and (key = C_Keys.ESCAPE)) or
          ((GDVars.menuExtendedKey = 0) and (key > #0)) then begin
        MenuCore.FreeMenuRows(menuNode);
        CharGen.FreeCreature(newCharacter);
        Exit
      end
    until key = #0;
    if (newCharacter^.race = C_Race.MOUNTAIN_DWARF) or (newCharacter^.race = C_Race.HILL_DWARF) then
      newCharacter^.deity := 6
    else
      newCharacter^.deity := selected;
    case newCharacter^.deity of
      1: begin
          workspace.deityAlignments := $15;
          newCharacter^.spells^.known[C_Spell.PROTECTION_FROM_EVIL_RADIUS_GIFT] := 1
        end;
      2: begin
          workspace.deityAlignments := $15;
          newCharacter^.spells^.known[C_Spell.SILENCE_RADIUS_GIFT] := 1
        end;
      3: begin
          workspace.deityAlignments := $15;
          newCharacter^.spells^.known[C_Spell.DETECT_MAGIC_GIFT] := 1;
          Inc(newCharacter^.thac0Base)
        end;
      4: begin
          workspace.deityAlignments := $15;
          newCharacter^.spells^.known[C_Spell.REMOVE_CURSE_GIFT] := 1;
          newCharacter^.spells^.known[C_Spell.BLESS_GIFT] := 1;
          newCharacter^.spells^.known[C_Spell.CHARM_PERSON_GIFT] := 1
        end;
      5: begin
          workspace.deityAlignments := $2E;
          newCharacter^.spells^.known[C_Spell.BURNING_HANDS_GIFT] := 1
        end;
      6: begin
          workspace.deityAlignments := $2E;
          if (newCharacter^.race = C_Race.MOUNTAIN_DWARF) or (newCharacter^.race = C_Race.HILL_DWARF) then
            Inc(newCharacter^.thac0Base)
        end;
      7: begin
          workspace.deityAlignments := $2E;
          newCharacter^.spells^.known[C_Spell.CHARM_PERSON_GIFT] := 1
        end;
    end
  end else begin
    newCharacter^.deity := 0;
    workspace.deityAlignments := $FF
  end;
  MenuCore.FreeMenuRows(menuNode);
  GetMem(menu, SizeOf(Types.TMenuRow));
  Types.PMenuRow(menu)^.next := nil;
  Types.PMenuRow(menu)^.heading := 1;
  Types.PMenuRow(menu)^.name := GDConsts.pickAlignmentMenu;
  item := menu;
  optionCount := 0;
  for index := 0 to 5 do begin
    workspace.allowed := (GDConsts.classAlignments[newCharacter^.characterClass] and workspace.deityAlignments) shr
      index;
    if (workspace.allowed and $01) <> 0 then begin
      GetMem(Types.PMenuRow(item)^.next, SizeOf(Types.TMenuRow));
      item := Types.PMenuRow(item)^.next;
      Types.PMenuRow(item)^.next := nil;
      Types.PMenuRow(item)^.heading := 0;
      Types.PMenuRow(item)^.name := '  ' + GDConsts.alignmentNames[GDConsts.alignmentChoices[index]];
      workspace.optionValues[optionCount] := GDConsts.alignmentChoices[index];
      Inc(optionCount)
    end
  end;
  item := menu;
  selected := 1;
  other := True;
  redraw := True;
  repeat
    key := Char(MenuCore.MenuVertical(GDConsts.emptyQuery, GDConsts.selectMenuText, 1, 2, 38, 22, menu, otherByte, 0,
                                      redrawByte,
                                      selected, item));
    if ((GDVars.menuExtendedKey <> 0) and (key = C_Keys.ESCAPE)) or
        ((GDVars.menuExtendedKey = 0) and (key > #0)) then begin
      MenuCore.FreeMenuRows(menuNode);
      CharGen.FreeCreature(newCharacter);
      Exit
    end
  until key = #0;
  newCharacter^.alignment := workspace.optionValues[selected - 1];
  case newCharacter^.alignment of
    0, 3, 6:
      if newCharacter^.classLevels[C_Class.MAGE] > 0 then
        newCharacter^.robeOrder := 1;
    1, 4, 7:
      if newCharacter^.classLevels[C_Class.MAGE] > 0 then
        newCharacter^.robeOrder := 2
  end;
  MenuCore.FreeMenuRows(menuNode);
  if newCharacter^.characterClass <= C_Class.KNIGHT then begin
    with GDConsts.startingAges[newCharacter^.race, newCharacter^.characterClass] do
      newCharacter^.age := base + FxEngine.RollDice(dice, sides)
  end else begin
    with newCharacter^ do
    case characterClass of
      C_Class.CLERIC_FIGHTER, C_Class.CLERIC_FIGHTER_MAGE, CharGen.CLASS_CLERIC_MAGE,
        C_Class.CLERIC_RANGER:
        age := GDConsts.startingAges[race, C_Class.CLERIC].base +
          GDConsts.startingAges[race, C_Class.CLERIC].sides *
          GDConsts.startingAges[race, C_Class.CLERIC].dice;
      CharGen.CLASS_FIGHTER_MAGE, C_Class.FIGHTER_MAGE_THIEF, C_Class.MAGE_THIEF,
        CharGen.CLASS_CLERIC_THIEF:
        age := GDConsts.startingAges[race, C_Class.MAGE].base +
          GDConsts.startingAges[race, C_Class.MAGE].sides * GDConsts.startingAges[race, C_Class.MAGE].dice;
      C_Class.FIGHTER_THIEF:
        age := GDConsts.startingAges[race, C_Class.FIGHTER].base +
          GDConsts.startingAges[race, C_Class.FIGHTER].sides *
          GDConsts.startingAges[race, C_Class.FIGHTER].dice
    end
  end;
  savedCharacter := GDVars.currentCharacter;
  GDVars.currentCharacter := newCharacter;
  ViewChar.DisplayChar;
  repeat
    for scanIndex := 0 to 7 do
      if GDVars.currentCharacter^.classLevels[scanIndex] > 0 then
        GDVars.currentCharacter^.classLevels[scanIndex] := 1;
    newCharacter^.exceptionalStrength := 0;
    for scanIndex2 := 0 to 5 do begin
      newCharacter^.stats[scanIndex2].current := 0;
      for optionCount := 1 to 6 do begin
        roll := FxEngine.RollDice(3, 6) + 1;
        case raceIndex of
          C_Race.MOUNTAIN_DWARF, C_Race.HILL_DWARF:
            case scanIndex2 of
              C_Stat.CONSTITUTION: Inc(roll);
              C_Stat.CHARISMA: Dec(roll)
            end;
          C_Race.SILVANESTI_ELF, C_Race.QUALINESTI_ELF:
            case scanIndex2 of
              C_Stat.DEXTERITY: Inc(roll);
              C_Stat.CONSTITUTION: Dec(roll)
            end;
          C_Race.HALF_ELF:
            case scanIndex2 of
              C_Stat.DEXTERITY: Inc(roll, 2)
            end;
          C_Race.KENDER:
            case scanIndex2 of
              C_Stat.STRENGTH: Dec(roll);
              C_Stat.DEXTERITY: Inc(roll, 2)
            end
        end;
        if newCharacter^.stats[scanIndex2].current < roll then
          newCharacter^.stats[scanIndex2].current := roll
      end;
      with newCharacter^ do begin
      case scanIndex2 of
        C_Stat.STRENGTH: begin
            if (stats[scanIndex2].current > 0) and (GDConsts.ageThresholds[race, 0] < age) then
              Inc(stats[scanIndex2].current);
            if (stats[scanIndex2].current > 0) and (GDConsts.ageThresholds[race, 1] < age) then
              Dec(stats[scanIndex2].current);
            if (stats[scanIndex2].current > 0) and (GDConsts.ageThresholds[race, 2] < age) then
              Dec(stats[scanIndex2].current, 2);
            if (stats[scanIndex2].current > 0) and (GDConsts.ageThresholds[race, 3] < age) then
              Dec(stats[scanIndex2].current);
            if stats[scanIndex2].current < GDConsts.raceStatLimits[race].strengthMinimum[gender] then
              stats[scanIndex2].current := GDConsts.raceStatLimits[race].strengthMinimum[gender];
            if stats[scanIndex2].current > GDConsts.raceStatLimits[race].strengthMaximum[gender] then
              stats[scanIndex2].current := GDConsts.raceStatLimits[race].strengthMaximum[gender];
            if stats[scanIndex2].current < GDConsts.classStatMinimums[characterClass, scanIndex2] then
              stats[scanIndex2].current := GDConsts.classStatMinimums[characterClass, scanIndex2];
            if (stats[C_Stat.STRENGTH].current = 18) and
                ((classLevels[C_Class.FIGHTER] > 0) or (classLevels[C_Class.RANGER] > 0) or
                 (classLevels[C_Class.PALADIN] > 0) or (classLevels[C_Class.KNIGHT] > 0)) then begin
              exceptionalStrength := Random(100) + 1;
              if GDConsts.raceStatLimits[race].exceptionalMaximum[gender] < exceptionalStrength then
                exceptionalStrength := GDConsts.raceStatLimits[race].exceptionalMaximum[gender]
            end
          end;
        C_Stat.INTELLIGENCE: begin
            if GDConsts.ageThresholds[race, 1] < age then
              Inc(stats[scanIndex2].current);
            if GDConsts.ageThresholds[race, 3] < age then
              Inc(stats[scanIndex2].current);
            if stats[scanIndex2].current < GDConsts.raceStatLimits[race].range[C_Stat.INTELLIGENCE].minimum then
              stats[scanIndex2].current := GDConsts.raceStatLimits[race].range[C_Stat.INTELLIGENCE].minimum;
            if stats[scanIndex2].current > GDConsts.raceStatLimits[race].range[C_Stat.INTELLIGENCE].maximum then
              stats[scanIndex2].current := GDConsts.raceStatLimits[race].range[C_Stat.INTELLIGENCE].maximum;
            if stats[scanIndex2].current < GDConsts.classStatMinimums[characterClass, scanIndex2] then
              stats[scanIndex2].current := GDConsts.classStatMinimums[characterClass, scanIndex2]
          end;
        C_Stat.WISDOM: begin
            if GDConsts.ageThresholds[race, 0] >= age then
              Dec(stats[scanIndex2].current);
            if GDConsts.ageThresholds[race, 1] < age then
              Inc(stats[scanIndex2].current);
            if GDConsts.ageThresholds[race, 2] < age then
              Inc(stats[scanIndex2].current);
            if GDConsts.ageThresholds[race, 3] < age then
              Inc(stats[scanIndex2].current);
            if stats[scanIndex2].current < GDConsts.raceStatLimits[race].range[C_Stat.WISDOM].minimum then
              stats[scanIndex2].current := GDConsts.raceStatLimits[race].range[C_Stat.WISDOM].minimum;
            if stats[scanIndex2].current > GDConsts.raceStatLimits[race].range[C_Stat.WISDOM].maximum then
              stats[scanIndex2].current := GDConsts.raceStatLimits[race].range[C_Stat.WISDOM].maximum;
            if stats[scanIndex2].current < GDConsts.classStatMinimums[characterClass, scanIndex2] then
              stats[scanIndex2].current := GDConsts.classStatMinimums[characterClass, scanIndex2];
            if (stats[scanIndex2].current < 13) and
                (characterClass in [C_Class.CLERIC_FIGHTER..CharGen.CLASS_CLERIC_THIEF]) then
              stats[scanIndex2].current := 13
          end;
        C_Stat.DEXTERITY: begin
            if GDConsts.ageThresholds[race, 2] < age then
              Dec(stats[scanIndex2].current, 2);
            if GDConsts.ageThresholds[race, 3] < age then
              Dec(stats[scanIndex2].current);
            if stats[scanIndex2].current < GDConsts.raceStatLimits[race].range[C_Stat.DEXTERITY].minimum then
              stats[scanIndex2].current := GDConsts.raceStatLimits[race].range[C_Stat.DEXTERITY].minimum;
            if stats[scanIndex2].current > GDConsts.raceStatLimits[race].range[C_Stat.DEXTERITY].maximum then
              stats[scanIndex2].current := GDConsts.raceStatLimits[race].range[C_Stat.DEXTERITY].maximum;
            if stats[scanIndex2].current < GDConsts.classStatMinimums[characterClass, scanIndex2] then
              stats[scanIndex2].current := GDConsts.classStatMinimums[characterClass, scanIndex2]
          end;
        C_Stat.CONSTITUTION: begin
            if GDConsts.ageThresholds[race, 1] < age then
              Dec(stats[scanIndex2].current);
            if GDConsts.ageThresholds[race, 2] < age then
              Dec(stats[scanIndex2].current);
            if GDConsts.ageThresholds[race, 3] < age then
              Dec(stats[scanIndex2].current);
            if stats[scanIndex2].current < GDConsts.raceStatLimits[race].range[C_Stat.CONSTITUTION].minimum then
              stats[scanIndex2].current := GDConsts.raceStatLimits[race].range[C_Stat.CONSTITUTION].minimum;
            if stats[scanIndex2].current > GDConsts.raceStatLimits[race].range[C_Stat.CONSTITUTION].maximum then
              stats[scanIndex2].current := GDConsts.raceStatLimits[race].range[C_Stat.CONSTITUTION].maximum;
            if stats[scanIndex2].current < GDConsts.classStatMinimums[characterClass, scanIndex2] then
              stats[scanIndex2].current := GDConsts.classStatMinimums[characterClass, scanIndex2]
          end;
        C_Stat.CHARISMA: begin
            if stats[scanIndex2].current < GDConsts.raceStatLimits[race].range[C_Stat.CHARISMA].minimum then
              stats[scanIndex2].current := GDConsts.raceStatLimits[race].range[C_Stat.CHARISMA].minimum;
            if stats[scanIndex2].current > GDConsts.raceStatLimits[race].range[C_Stat.CHARISMA].maximum then
              stats[scanIndex2].current := GDConsts.raceStatLimits[race].range[C_Stat.CHARISMA].maximum;
            if stats[scanIndex2].current < GDConsts.classStatMinimums[characterClass, scanIndex2] then
              stats[scanIndex2].current := GDConsts.classStatMinimums[characterClass, scanIndex2]
          end
      end;
      newCharacter^.stats[scanIndex2].base := newCharacter^.stats[scanIndex2].current;
      if scanIndex2 = 0 then
        newCharacter^.exceptionalStrengthBase := newCharacter^.exceptionalStrength;
      ViewChar.PrintStat(ShortInt(scanIndex2), False)
      end
    end;
    with newCharacter^ do begin
    hitPoints := maxHitPoints;
    attackRate := 2;
    unarmedRolls[1] := 1;
    unarmedDice[1] := 2;
    strengthBonusEnabled := 1;
    baseMovement := 12;
    abilityScratch := 0;
    abilityCount := 0;
    for scanIndex := 0 to 7 do
      if classLevels[scanIndex] > 0 then begin
        case scanIndex of
          C_Class.CLERIC: if deity <= 4 then
              spells^.slots[0, 1] := 1
            else
              spells^.slots[0, 1] := 2;
          C_Class.MAGE: spells^.slots[3, 1] := 1
        end;
        case scanIndex of
          C_Class.CLERIC: begin
              ClassCal.RecalcClericSlots(newCharacter);
              index := 1;
              optionCount := 255;
              while (index <= 10) and (optionCount <> 0) do begin
                optionCount := GDConsts.spellsByLevel[1, 1, index];
                if optionCount <> 0 then
                  spells^.known[optionCount] := 1;
                Inc(index)
              end
            end;
          C_Class.MAGE: begin
              spells^.known[C_Spell.CHARM_PERSON_MAGE] := 1;
              spells^.known[C_Spell.DETECT_MAGIC_MAGE] := 1;
              spells^.known[C_Spell.ENLARGE] := 1;
              spells^.known[C_Spell.MAGIC_MISSILE] := 1;
              spells^.known[C_Spell.PROTECTION_FROM_EVIL_MAGE] := 1;
              spells^.known[C_Spell.READ_MAGIC] := 1;
              spells^.known[C_Spell.SHIELD] := 1
            end
        end;
        Inc(abilityCount)
      end;
    coins[4] := 500;
    newCharacter^.maxHitPoints := 0;
    newCharacter^.baseMaxHitPoints := 0;
    newCharacter^.hitPoints := 0;
    ViewChar.AdjustLevelHitPoints(newCharacter, 255, abilityCount, True);
    workspace.savedSetting := GDVars.zone1^.trainMask[trainMaskIndex + $7C00];
    GDVars.zone1^.trainMask[trainMaskIndex + $7C00] := $FF;
    GDVars.trainingDone := 0;
    GDVars.autoTraining := 1;
    repeat
      CharGen.TrainingMenu
    until GDVars.trainingDone <> 0;
    GDVars.zone1^.trainMask[trainMaskIndex + $7C00] := workspace.savedSetting;
    GDVars.autoTraining := 0;
    end;
    workspace.keepFlag := False;
    workspace.line := '';
    for scanIndex := 0 to 7 do
      if GDVars.currentCharacter^.classLevels[scanIndex] > 0 then begin
        if workspace.keepFlag then workspace.line := workspace.line + '/';
        workspace.line := workspace.line + CharHlp.ByteToString(GDVars.currentCharacter^.classLevels[scanIndex]);
        workspace.keepFlag := True
      end;
    TextRend.DisplayString(7, 7, White, Black, workspace.line);
    ViewChar.PrintCombatStats;
    ViewChar.PrintMoney;
    GDVars.selectedChoice := 1
  until Char(MenuCore.YesNoMenu(GDConsts.rerollStatsQuery, GDConsts.noKey)) = Chr(GDConsts.noKey);
  ViewChar.DisplayChar;
  repeat
    newCharacter^.name := TextRend.ReadString(GDConsts.characterNameQuery, LightMagenta, Black, 15)
  until newCharacter^.name <> '';
  CharGen.SetDefaultIcon;
  CharGen.CustomizeIcon;
  for scanIndex2 := 0 to 5 do
    newCharacter^.stats[scanIndex2].base := newCharacter^.stats[scanIndex2].current;
  newCharacter^.exceptionalStrengthBase := newCharacter^.exceptionalStrength;
  if Char(MenuCore.YesNoMenu(GDConsts.saveCharacterQuery, GDConsts.yesKey)) = Chr(GDConsts.noKey) then begin
    CharGen.FreeCreature(newCharacter);
    GDVars.currentCharacter := savedCharacter
  end else begin
    CharGen.CreateStartingItems(newCharacter);
    SaveLoad.SaveChar(newCharacter, '');
    CharGen.FreeCreature(newCharacter);
    GDVars.currentCharacter := savedCharacter
  end
end;

procedure DropCharacterMenu;
var
  { Unused in this version; see the other implementations of this routine. }
  answer: Byte;
begin
  if ViewChar.PickCharacter then begin
    if GDVars.currentCharacter <> nil then
      with GDVars.currentCharacter^ do begin
      if (Char(MenuCore.YesNoMenu(GDConsts.dropPrefix + name + GDConsts.foreverText, GDConsts.noKey)) =
          Chr(GDConsts.yesKey)) and
          (Char(MenuCore.YesNoMenu(GDConsts.areYouSureQuery, GDConsts.noKey)) = Chr(GDConsts.yesKey)) then begin
          if enabled = 0 then
            CharHlp.PrintBottomLine(name + GDConsts.dumpedOutBackText)
          else
            CharHlp.PrintBottomLine(name + GDConsts.bidsFarewellText);
          SaveLoad.DeleteCharacterFiles(GDVars.currentCharacter);
          CharGen.RemoveCreature(False, True)
        end else
        CharHlp.PrintBottomLine(name + GDConsts.sighOfReliefText)
      end;
    CharHlp.DisplayParty(GDVars.currentCharacter)
  end
end;

procedure ModifyCharacterMenu;
var savedStats: array[0..5] of Byte;
    savedStrength: Byte;
    savedHitPoints: Byte;
    savedName: String[40];
    { Unused in this version; see the other implementations of this routine. }
    nameIndex: Byte;
    classIndex: ShortInt;
    index: ShortInt;
    choice: Char;
    key: Char;
    isExtendedKey: Boolean;
    field: Byte;
    { Unused in this version; see the other implementations of this routine. }
    cursorCol: array[1..7] of Byte;
    cursorColumn: Byte;
    scan: Byte;

  { Draws the field being modified, highlighted when active is non-zero. }
  procedure DisplayModifyField(active: Byte);
  begin
    case field of
      0..5: ViewChar.PrintStat(ShortInt(field), Boolean(active));
      7: CharHlp.PrintHitPoints(GDVars.currentCharacter, 31, 3, Boolean(active), False);
      6: if active <> 0 then begin
          TextRend.PrintSpaces(Length(GDVars.currentCharacter^.name) + 1, 1, Black, 1);
          TextRend.DisplayString(1, 1, LightMagenta, Black, GDVars.currentCharacter^.name);
          if GDVars.currentCharacter^.name[cursorColumn] = ' ' then
            TextRend.DisplayString(cursorColumn, 1, White, Black, '%')
          else
            TextRend.DisplayString(cursorColumn, 1, White, Black, GDVars.currentCharacter^.name[cursorColumn])
        end else
          TextRend.DisplayString(1, 1, LightGreen, Black, GDVars.currentCharacter^.name)
    end
  end;
begin
  if ViewChar.PickCharacter then begin
    if not ((GDVars.currentCharacter^.experience = 210003) or
            (GDVars.currentCharacter^.experience = 105002) or
            (GDVars.currentCharacter^.experience = 70001)) then begin
      TextRend.PrintAndPause(GDVars.currentCharacter^.name + GDConsts.cantBeModifiedText, Yellow, Black);
      Exit
    end;
    GDVars.modifyMouseRow := 255;
    GDVars.modifyActive := 1;
    ViewChar.DisplayChar;
    for index := 0 to 5 do
      savedStats[index] := GDVars.currentCharacter^.stats[index].current;
    savedStrength := GDVars.currentCharacter^.exceptionalStrength;
    savedHitPoints := GDVars.currentCharacter^.maxHitPoints;
    savedName := GDVars.currentCharacter^.name;
    cursorColumn := 1;
    field := 7;
    DisplayModifyField(0);
    field := 0;
    DisplayModifyField(1);
    with GDVars.currentCharacter^ do
    repeat
      if field = 6 then begin
        isExtendedKey := False;
        repeat until GameIo.InputPending;
        key := GameIo.ReadGameKey;
        if key in ['1'..'9', '\'] then begin
          if key = '\' then key := '7'
          else key := Chr(GDConsts.digitKeys[Ord(key) - Ord('1')]);
          isExtendedKey := True
        end;
        if key = #0 then begin
          key := GameIo.ReadGameKey;
          isExtendedKey := True
        end;
        if key = C_Keys.ESCAPE then key := #0;
        if not isExtendedKey then
          case key of
          C_Keys.BACKSPACE: begin
            if cursorColumn > 1 then begin
              for scan := cursorColumn to
                  Length(GDVars.currentCharacter^.name) do
                GDVars.currentCharacter^.name[scan - 1] := GDVars.currentCharacter^.name[scan];
              Dec(GDVars.currentCharacter^.name[0]);
              if cursorColumn > Length(GDVars.currentCharacter^.name) then
                cursorColumn := Length(GDVars.currentCharacter^.name)
            end
          end;
          #32..#122: begin
            if cursorColumn <= 15 then begin
              GDVars.currentCharacter^.name[cursorColumn] := key;
              Inc(cursorColumn);
              if cursorColumn > 15 then cursorColumn := 15;
              if cursorColumn > Length(GDVars.currentCharacter^.name) then begin
                Inc(GDVars.currentCharacter^.name[0]);
                GDVars.currentCharacter^.name[cursorColumn] := ' '
              end
            end
          end
          end
      end else begin
        MenuCore.EnableChoices(3);
        choice := Char(MenuCore.MenuHorizontal(GDConsts.modifyQuery, GDConsts.modifyMenu, 1, 0));
        isExtendedKey := Boolean(GDVars.menuExtendedKey);
        if isExtendedKey then key := choice
      end;
      DisplayModifyField(0);
      if isExtendedKey then
        case key of
          CharGen.KEY_DEL: if (field = 6) and (Length(GDVars.currentCharacter^.name) > 1) then begin
              if cursorColumn = Length(GDVars.currentCharacter^.name) then begin
                Dec(GDVars.currentCharacter^.name[0]);
                cursorColumn := Length(GDVars.currentCharacter^.name)
              end else begin
                for scan := cursorColumn to
                    Length(GDVars.currentCharacter^.name) - 1 do
                  GDVars.currentCharacter^.name[scan] := GDVars.currentCharacter^.name[scan + 1];
                Dec(GDVars.currentCharacter^.name[0])
              end
            end;
          C_Keys.DOWN: begin
              GDVars.modifyMouseRow := 255;
              Inc(field);
              if field > 7 then field := 0
            end;
          C_Keys.UP: begin
              GDVars.modifyMouseRow := 255;
              Dec(field);
              if field = 255 then field := 7
            end;
          C_Keys.HOME: if (GDVars.mouseClick <> 0) and (GDVars.modifyMouseRow <> 255) then
                  field := GDVars.modifyMouseRow;
          C_Keys.ESCAPE: begin
              for index := 0 to 5 do
                GDVars.currentCharacter^.stats[index].current := savedStats[index];
              GDVars.currentCharacter^.exceptionalStrength := savedStrength;
              GDVars.currentCharacter^.maxHitPoints := savedHitPoints;
              GDVars.currentCharacter^.name := savedName;
              GDVars.currentCharacter^.hitPoints := maxHitPoints;
              CharHlp.RecalcStats(GDVars.currentCharacter);
              GDVars.modifyActive := 0;
              Exit
            end
        end else
        case choice of
          #1: if field < 6 then begin
              index := field;
              Dec(stats[index].current);
              case index of
                C_Stat.STRENGTH: begin
                    if exceptionalStrength > 0 then begin
                      Dec(exceptionalStrength);
                      Inc(stats[index].current)
                    end else if stats[index].current < GDConsts.raceStatLimits[race].strengthMinimum[gender] then
                      stats[index].current := GDConsts.raceStatLimits[race].strengthMinimum[gender];
                    if stats[index].current < GDConsts.classStatMinimums[characterClass, C_Stat.STRENGTH] then
                      stats[index].current := GDConsts.classStatMinimums[characterClass, C_Stat.STRENGTH]
                  end;
                C_Stat.INTELLIGENCE: begin
                    if stats[index].current < GDConsts.raceStatLimits[race].range[C_Stat.INTELLIGENCE].minimum then
                      stats[index].current := GDConsts.raceStatLimits[race].range[C_Stat.INTELLIGENCE].minimum;
                    if stats[index].current < GDConsts.classStatMinimums[characterClass, C_Stat.INTELLIGENCE] then
                      stats[index].current := GDConsts.classStatMinimums[characterClass, C_Stat.INTELLIGENCE]
                  end;
                C_Stat.WISDOM: begin
                    if stats[index].current < GDConsts.raceStatLimits[race].range[C_Stat.WISDOM].minimum then
                      stats[index].current := GDConsts.raceStatLimits[race].range[C_Stat.WISDOM].minimum;
                    if stats[index].current < GDConsts.classStatMinimums[characterClass, C_Stat.WISDOM] then
                      stats[index].current := GDConsts.classStatMinimums[characterClass, C_Stat.WISDOM];
                    if (spells <> nil) and (spells^.slots[0, 1] > 0) then
                      spells^.slots[0, 1] := 1
                  end;
                C_Stat.DEXTERITY: begin
                    if stats[index].current < GDConsts.raceStatLimits[race].range[C_Stat.DEXTERITY].minimum then
                      stats[index].current := GDConsts.raceStatLimits[race].range[C_Stat.DEXTERITY].minimum;
                    if stats[index].current < GDConsts.classStatMinimums[characterClass, C_Stat.DEXTERITY] then
                      stats[index].current := GDConsts.classStatMinimums[characterClass, C_Stat.DEXTERITY]
                  end;
                C_Stat.CONSTITUTION: begin
                    if stats[index].current < GDConsts.raceStatLimits[race].range[C_Stat.CONSTITUTION].minimum then
                      stats[index].current := GDConsts.raceStatLimits[race].range[C_Stat.CONSTITUTION].minimum;
                    if stats[index].current < GDConsts.classStatMinimums[characterClass, C_Stat.CONSTITUTION] then
                      stats[index].current := GDConsts.classStatMinimums[characterClass, C_Stat.CONSTITUTION];
                    if ViewChar.HitPointCap(GDVars.currentCharacter) < maxHitPoints then
                      maxHitPoints := ViewChar.HitPointCap(GDVars.currentCharacter);
                    hitPoints := maxHitPoints;
                    field := 6;
                    DisplayModifyField(0);
                    field := C_Stat.CONSTITUTION
                  end;
                C_Stat.CHARISMA: begin
                    if (race = C_Race.MOUNTAIN_DWARF) and (characterClass = C_Class.PALADIN) then begin
                      if stats[index].current < 17 then
                        stats[index].current := 17
                    end else if stats[index].current < GDConsts.raceStatLimits[race].range[C_Stat.CHARISMA].minimum then
                      stats[index].current := GDConsts.raceStatLimits[race].range[C_Stat.CHARISMA].minimum;
                    if stats[index].current < GDConsts.classStatMinimums[characterClass, C_Stat.CHARISMA] then
                      stats[index].current := GDConsts.classStatMinimums[characterClass, C_Stat.CHARISMA]
                  end
              end
            end else if field = 7 then begin
              Dec(maxHitPoints);
              if CharGen.HpMinimum(GDVars.currentCharacter) > maxHitPoints then
                maxHitPoints := CharGen.HpMinimum(GDVars.currentCharacter);
              hitPoints := maxHitPoints
            end else if cursorColumn = 1 then
              cursorColumn := Length(GDVars.currentCharacter^.name)
            else Dec(cursorColumn);
          #0: if field < 6 then begin
              index := field;
              Inc(stats[index].current);
              case index of
                C_Stat.STRENGTH:
                  if stats[index].current > GDConsts.raceStatLimits[race].strengthMaximum[gender] then begin
                    if stats[index].current > 18 then
                      if (classLevels[C_Class.FIGHTER] > 0) or (classLevels[C_Class.KNIGHT] > 0) or
                          (classLevels[C_Class.PALADIN] > 0) or (classLevels[C_Class.RANGER] > 0) then
                        if GDConsts.raceStatLimits[race].exceptionalMaximum[gender] >
                           exceptionalStrength then Inc(exceptionalStrength);
                    stats[index].current := GDConsts.raceStatLimits[race].strengthMaximum[gender]
                  end;
                C_Stat.INTELLIGENCE:
                  if stats[index].current > GDConsts.raceStatLimits[race].range[C_Stat.INTELLIGENCE].maximum then
                    stats[index].current := GDConsts.raceStatLimits[race].range[C_Stat.INTELLIGENCE].maximum;
                C_Stat.WISDOM: begin
                    if stats[index].current > GDConsts.raceStatLimits[race].range[C_Stat.WISDOM].maximum then
                      stats[index].current := GDConsts.raceStatLimits[race].range[C_Stat.WISDOM].maximum;
                    if (spells <> nil) and (spells^.slots[0, 1] > 0) then
                      spells^.slots[0, 1] := 1
                  end;
                C_Stat.DEXTERITY:
                  if stats[index].current > GDConsts.raceStatLimits[race].range[C_Stat.DEXTERITY].maximum then
                    stats[index].current := GDConsts.raceStatLimits[race].range[C_Stat.DEXTERITY].maximum;
                C_Stat.CONSTITUTION: begin
                    if stats[index].current > GDConsts.raceStatLimits[race].range[C_Stat.CONSTITUTION].maximum then
                      stats[index].current := GDConsts.raceStatLimits[race].range[C_Stat.CONSTITUTION].maximum;
                    if CharGen.HpMinimum(GDVars.currentCharacter) > maxHitPoints then
                      maxHitPoints := CharGen.HpMinimum(GDVars.currentCharacter);
                    hitPoints := maxHitPoints;
                    field := 6;
                    DisplayModifyField(0);
                    field := C_Stat.CONSTITUTION
                  end;
                C_Stat.CHARISMA: begin
                    if (race = C_Race.MOUNTAIN_DWARF) and (characterClass = C_Class.PALADIN) then begin
                      if stats[index].current > 17 then
                        stats[index].current := 17
                    end else if stats[index].current > GDConsts.raceStatLimits[race].range[C_Stat.CHARISMA].maximum then
                      stats[index].current := GDConsts.raceStatLimits[race].range[C_Stat.CHARISMA].maximum
                  end
              end
            end else if field = 7 then begin
              Inc(maxHitPoints);
              if ViewChar.HitPointCap(GDVars.currentCharacter) < maxHitPoints then
                maxHitPoints := ViewChar.HitPointCap(GDVars.currentCharacter);
              hitPoints := maxHitPoints
            end else if cursorColumn = Length(GDVars.currentCharacter^.name) then
              cursorColumn := 1
            else Inc(cursorColumn);
          #3: begin
              for index := 0 to 5 do
                GDVars.currentCharacter^.stats[index].current := savedStats[index];
              GDVars.currentCharacter^.exceptionalStrength := savedStrength;
              GDVars.currentCharacter^.maxHitPoints := savedHitPoints;
              GDVars.currentCharacter^.hitPoints := maxHitPoints;
              GDVars.currentCharacter^.name := savedName;
              CharHlp.RecalcStats(GDVars.currentCharacter);
              GDVars.modifyActive := 0;
              Exit
            end
        end;
      CharHlp.RecalcStats(GDVars.currentCharacter);
      ViewChar.PrintCombatStats;
      DisplayModifyField(1)
    until (not isExtendedKey) and (choice = #2);
    ClassCal.RecalcClericSlots(GDVars.currentCharacter);
    with GDVars.currentCharacter^ do begin
    savedHitPoints := 0;
    scan := 0;
    for classIndex := 0 to 7 do
      if classLevels[classIndex] > 0 then begin
        if Byte(classLevels[classIndex]) < GDConsts.firstFixedHpLevel[classIndex] then begin
          if classIndex = C_Class.RANGER then
            Inc(savedHitPoints,
                CharHlp.ClassConAdj(GDVars.currentCharacter, classIndex) *
                (classLevels[classIndex] + 1))
          else
            Inc(savedHitPoints,
                CharHlp.ClassConAdj(GDVars.currentCharacter, classIndex) * classLevels[classIndex])
        end else
          Inc(savedHitPoints,
              CharHlp.ClassConAdj(GDVars.currentCharacter,
                                  classIndex) * (GDConsts.firstFixedHpLevel[classIndex] - 1));
        Inc(scan)
      end;
    savedHitPoints := savedHitPoints div scan;
    baseMaxHitPoints := maxHitPoints - savedHitPoints;
    for index := 0 to 5 do
      GDVars.currentCharacter^.stats[index].base := GDVars.currentCharacter^.stats[index].current;
    GDVars.currentCharacter^.exceptionalStrengthBase := GDVars.currentCharacter^.exceptionalStrength;
    GDVars.modifyActive := 0
    end
  end
end;

const
  TOO_MANY_RANGERS = 'too many rangers in party';

procedure AddCharacterMenu;
var
  list: Pointer;
  files: Pointer;
  listNode: Types.PMenuRow absolute list;
  selected: Types.PMenuRow;
  fileNode: Types.PMenuRow;
  newCharacter: Types.PCharacter;
  walk: Types.PCharacter;
  index: Integer;
  choice: Char;
  { Unused in this version; see the other implementations of this routine. }
  addExit: Boolean;
  redraw: Boolean;
  redrawByte: Byte absolute redraw;
  nonNpc: Byte;
  rangerCount: Byte;
  { Unused in this version; see the other implementations of this routine. }
  evilFlag: Byte;
begin
  rangerCount := 0;
  Border.ClearBox(1, 1, 38, 22);
  MenuCore.EnableChoices(2);
  choice := Char(MenuCore.MenuHorizontal(GDConsts.addFromWhereQuery, GDConsts.sourceGameMenu, 0, 0));
  if (GDVars.menuExtendedKey <> 0) and (choice = C_Keys.ESCAPE) then choice := #2;
  case choice of
    #0: GDVars.fileFormat := 1;
    #1: GDVars.fileFormat := 0;
    #2: Exit
  end;
  SaveLoad.LoadCharlist(list, files);
  if list = nil then Exit;
  index := 0;
  selected := Types.PMenuRow(list);
  redraw := True;
  repeat
    MenuCore.EnableChoices(0);
    choice := Char(MenuCore.MenuVertical(GDConsts.addCharacterQuery, GDConsts.addMenu, 1, 2, 38, 22, list, 1, 0,
                                         redrawByte, index,
                                         Pointer(selected)));
    if (GDVars.menuExtendedKey <> 0) and (choice = C_Keys.ESCAPE) then choice := #1;
    if (choice = #0) and (selected^.name[1] <> '*') then begin
      MenuCore.ClearBottomLine;
      GetMem(newCharacter, SizeOf(Types.TCharacter));
      fileNode := MenuCore.MenuRowAt(index, Types.PMenuRow(files));
      SaveLoad.LoadChar(fileNode^.name, newCharacter, False, True);
      selected^.name := '* ' + selected^.name;
      nonNpc := 0;
      if GDVars.partyHead = nil then begin
        GDVars.zone1^.partySize[$7F3E] := 0;
        SaveLoad.AddCharToParty(newCharacter);
        SaveLoad.LoadCharIconAnim(True)
      end else begin
        walk := GDVars.partyHead;
        rangerCount := 0;
        while (walk <> nil) and
            ((walk^.name <> newCharacter^.name) or (walk^.identity <> newCharacter^.identity)) do begin
          if walk^.npc < C_Npc.NON_PLAYER then Inc(nonNpc);
          if walk^.classLevels[C_Class.RANGER] > 0 then Inc(rangerCount);
          walk := walk^.next
        end;
        if (walk = nil) and
            (((newCharacter^.npc < C_Npc.NON_PLAYER) and (nonNpc < 6)) or
             ((newCharacter^.npc > $7F) and (GDVars.zone1^.partySize[$7F3E] < 8))) and
            ((newCharacter^.classLevels[C_Class.RANGER] = 0) or (rangerCount < 3)) then begin
          SaveLoad.AddCharToParty(newCharacter);
          SaveLoad.LoadCharIconAnim(True);
          if newCharacter^.npc < C_Npc.NON_PLAYER then Inc(nonNpc)
        end else begin
          if (newCharacter^.classLevels[C_Class.RANGER] > 0) and (rangerCount > 2) then
            CharHlp.PrintBottomLine(CharGen.TOO_MANY_RANGERS);
          FreeMem(newCharacter, SizeOf(Types.TCharacter))
        end
      end
    end
  until (choice = #1) or (nonNpc > 5) or (GDVars.zone1^.partySize[$7F3E] > 7);
  MenuCore.FreeMenuRows(listNode)
end;

procedure RemoveCreature(keepCount, freeIcon: Boolean);
var previous: Types.PCharacter;
begin
  if GDVars.partyHead <> nil then begin
    previous := GDVars.partyHead;
    if previous <> GDVars.currentCharacter then begin
      while (previous^.next <> GDVars.currentCharacter) and (previous^.next <> nil) do
        previous := previous^.next;
      if previous^.next <> nil then begin
        if freeIcon then
          MapTiles.FreeIconAnim(GDVars.currentCharacter^.orderNumber);
        previous^.next := GDVars.currentCharacter^.next;
        CharGen.FreeCreature(GDVars.currentCharacter);
        GDVars.currentCharacter := previous;
        if not keepCount then Dec(GDVars.zone1^.partySize[$7F3E])
      end
    end else begin
      if freeIcon then
        MapTiles.FreeIconAnim(GDVars.currentCharacter^.orderNumber);
      GDVars.partyHead := GDVars.currentCharacter^.next;
      previous := GDVars.currentCharacter^.next;
      CharGen.FreeCreature(GDVars.currentCharacter);
      GDVars.currentCharacter := previous;
      if not keepCount then Dec(GDVars.zone1^.partySize[$7F3E])
    end;
    if GDVars.currentCharacter = nil then GDVars.currentCharacter := GDVars.partyHead
  end
end;

procedure SetDefaultIcon;
begin
  with GDVars.currentCharacter^ do begin
    if race = C_Race.KENDER then iconHead := 3
    else if gender = 1 then
      if iconSize = 2 then iconHead := 9 else iconHead := 7
    else if iconSize = 2 then iconHead := 5
    else iconHead := 0;
    if classLevels[C_Class.CLERIC] > 0 then iconBody := 23
    else if classLevels[C_Class.RANGER] > 0 then iconBody := 1
    else if (classLevels[C_Class.KNIGHT] > 0) or (classLevels[C_Class.PALADIN] > 0) or
      (classLevels[C_Class.FIGHTER] > 0) then iconBody := 24
    else if classLevels[C_Class.MAGE] > 0 then iconBody := 29
    else iconBody := 5
  end
end;

procedure CustomizeIcon;
var
  { Unused in this version; see the other implementations of this routine. }
  oldState: Byte;
  key: Char;
  savedHead: Byte;
  savedBody: Byte;
  savedSize: Byte;
  savedOrder: Byte;
  state: Byte;
  { Unused in this version; see the other implementations of this routine. }
  iconState: Byte;
  savedColors: Types.TIconColors;
  slot: Byte;
  which: Byte;
  lowColor: Byte;
  highColor: Byte;
  lastState: Byte;
  partKey: Byte;
  iconDone: Byte;

  { Switches the icon editor's menu to a state and enables its choices. }
  procedure SetIconMenu(newState: Byte);
  var
    start: Byte;
    index: Byte;
  begin
    state := newState;
    MenuCore.EnableChoices(GDConsts.iconMenuModes[newState]);
    case newState of
      3: begin
          if which <> 0 then start := 2 else start := 3;
          for index := start to 6 do
            GDVars.enabledChoices[index].ordinal := index + 1;
          GDVars.enabledChoices[7].ordinal := 255
        end;
      4: begin
          if GDVars.currentCharacter^.iconSize = 2 then start := 1
          else start := 0;
          for index := start to 2 do
            GDVars.enabledChoices[index].ordinal := index + 1;
          GDVars.enabledChoices[3].ordinal := 255
        end
    end
  end;

  { Draws both frames of the icon being edited at a cell over its background and flushes the view. }
  procedure ShowIconFrames(y, x: Byte);
  begin
    if GDVars.displayMode = Types.Cga then
      Blit.FillPicRect(y * 3, x * 24, 12, 24, 3, GDConsts.cgaColorMap, GDVars.compositeBuffer)
    else begin
      Blit.FillPicRect(y * 3, x * 24, 12, 24, 0, GDConsts.cgaColorMap, GDVars.compositeBuffer);
      MapTiles.DrawIconAnimSprite(y, x, 0, 0, 28);
      MapTiles.DrawIconAnimSprite(y + 3, x, 0, 0, 28)
    end;
    MapTiles.DrawIconAnimSprite(y, x, 0, 0, 12);
    MapTiles.DrawIconAnimSprite(y + 3, x, 0, 1, 12);
    Blit.FlushView
  end;

  { Copies one icon slot's frames and masks into another, recolored with the icon colors when asked. }
  procedure CopyIconPics(source, destination: Byte; applyColors: Boolean);
  var index: Byte;
      { Unused in this version; see the other implementations of this routine. }
      colorIndex: Byte;
      fromColors: Types.TColorTab;
      toColors: Types.TColorTab;
      imageSize: Word;
  begin
    imageSize := GDVars.iconAnimations[destination, 0]^.imgSize;
    Move(GDVars.iconAnimations[source, 0]^.data, GDVars.iconAnimations[destination, 0]^.data,
         GDVars.iconAnimations[destination, 0]^.imgSize);
    Move(GDVars.iconAnimations[source, 1]^.data, GDVars.iconAnimations[destination, 1]^.data,
         GDVars.iconAnimations[destination, 1]^.imgSize);
    Move(GDVars.iconAnimations[source, 0]^.transp^, GDVars.iconAnimations[destination, 0]^.transp^, imageSize);
    Move(GDVars.iconAnimations[source, 1]^.transp^, GDVars.iconAnimations[destination, 1]^.transp^, imageSize);
    if applyColors then
      with GDVars.currentCharacter^ do begin
      for index := 0 to 15 do begin
        fromColors[index] := index;
        toColors[index] := index
      end;
      for index := 1 to 6 do begin
        toColors[GDConsts.iconColorSlots[index]] := iconColors[index] and $0F;
        toColors[GDConsts.iconColorSlots[index] + 8] := (iconColors[index] and $F0) shr 4
      end;
      Blit.RemapPic(fromColors, toColors, 0, False, GDVars.iconAnimations[destination, 0]);
      Blit.RemapPic(fromColors, toColors, 0, False, GDVars.iconAnimations[destination, 1])
      end
  end;
begin
  Border.DrawWindowFrame(0);
  CbtMap.SetCombatPalette;
  repeat
  SaveLoad.LoadCharIconAnim(False);
  with GDVars.currentCharacter^ do begin
  SetIconMenu(1);
  savedColors := iconColors;
  savedOrder := orderNumber;
  orderNumber := 12;
  SaveLoad.LoadCharIconAnim(False);
  orderNumber := savedOrder;
  savedHead := iconHead;
  savedBody := iconBody;
  savedSize := iconSize;
  CopyIconPics(orderNumber, 12, True);
  ShowIconFrames(1, 2);
  TextRend.DisplayString(8, 6, White, Black, GDConsts.oldText);
  TextRend.DisplayString(3, 10, White, Black, GDConsts.readyActionHeading);
  TextRend.DisplayString(8, 12, White, Black, GDConsts.newText);
  TextRend.DisplayString(3, 16, White, Black, GDConsts.readyActionHeading);
  iconDone := 0;
  repeat
  ShowIconFrames(1, 4);
  key := Char(MenuCore.MenuHorizontal(GDConsts.emptyQuery, GDConsts.iconMenus[state], 0, 0));
  if GDVars.menuExtendedKey = 0 then
    case state of
      1: begin
          lastState := 1;
          case key of
            #0: SetIconMenu(2);
            #1: if GDVars.displayMode = Types.Cga then
                 TextRend.PrintAndPause(GDConsts.sorryNotInCgaText, Yellow, Black)
               else begin
                 which := 0;
                 SetIconMenu(3)
               end;
            #2: if GDVars.displayMode = Types.Cga then
                 TextRend.PrintAndPause(GDConsts.sorryNotInCgaText, Yellow, Black)
               else begin
                 which := 1;
                 SetIconMenu(3)
               end;
            #3: SetIconMenu(4);
            #4: iconDone := 1
          end
        end;
      2: begin
          lastState := 2;
          if (key = #2) or ((GDVars.menuExtendedKey <> 0) and (key = C_Keys.ESCAPE)) then
            SetIconMenu(1)
          else begin
            partKey := Ord(key);
            SetIconMenu(5)
          end
        end;
      3: begin
          lastState := 3;
          if (GDVars.menuExtendedKey <> 0) and (key = C_Keys.ESCAPE) then key := #7;
          state := 5;
          case key of
            #0: slot := 6;
            #1: slot := 1;
            #2, #3: slot := 4;
            #4: slot := 5;
            #5: slot := 2;
            #6: slot := 3;
            #7: begin
                slot := 1;
                state := 1
              end
          end;
          SetIconMenu(state)
        end;
      4: begin
          if (GDVars.menuExtendedKey <> 0) and (key = C_Keys.ESCAPE) then key := #3;
          case key of
            #0: begin
                iconSize := 1;
                SaveLoad.LoadCharIconAnim(False);
                SetIconMenu(4)
              end;
            #1: begin
                iconSize := 2;
                SaveLoad.LoadCharIconAnim(False);
                SetIconMenu(4)
              end;
            #2: begin
                savedSize := iconSize;
                SetIconMenu(1)
              end;
            #3: begin
                iconSize := savedSize;
                SetIconMenu(1)
              end
          end;
          SaveLoad.LoadCharIconAnim(False)
        end;
      5: case lastState of
          2: begin
              if (GDVars.menuExtendedKey <> 0) and (key = C_Keys.ESCAPE) then key := #3;
              case partKey of
                0: begin
                    case key of
                      #0: if iconHead < GDConsts.maximumIconHead then
                           Inc(iconHead)
                         else iconHead := 0;
                      #1: if iconHead > 0 then
                           Dec(iconHead)
                         else iconHead := GDConsts.maximumIconHead;
                      #2: begin
                          with GDVars.currentCharacter^ do
                            savedHead := iconHead;
                          SetIconMenu(lastState)
                        end;
                      #3: begin
                          iconHead := savedHead;
                          SetIconMenu(lastState)
                        end
                    end;
                    SaveLoad.LoadCharIconAnim(False)
                  end;
                1: begin
                    case key of
                      #0: if iconBody < GDConsts.maximumIconBody then
                           Inc(iconBody)
                         else iconBody := 0;
                      #1: if iconBody > 0 then
                           Dec(iconBody)
                         else iconBody := GDConsts.maximumIconBody;
                      #2: begin
                          with GDVars.currentCharacter^ do
                            savedBody := iconBody;
                          SetIconMenu(lastState)
                        end;
                      #3: begin
                          iconBody := savedBody;
                          SetIconMenu(lastState)
                        end
                    end;
                    SaveLoad.LoadCharIconAnim(False)
                  end
              end
            end;
          3: begin
              lowColor := iconColors[slot] and $0F;
              highColor := (iconColors[slot] and $F0) shr 4;
              if (GDVars.menuExtendedKey <> 0) and (key = C_Keys.ESCAPE) then key := #3;
              case key of
                #0: begin
                    if which <> 0 then highColor := (highColor + 1) mod 16
                    else lowColor := (lowColor + 1) mod 16;
                    iconColors[slot] := highColor shl 4 + lowColor
                  end;
                #1: begin
                    if which <> 0 then highColor := (highColor - 1) and $0F
                    else lowColor := (lowColor - 1) and $0F;
                    iconColors[slot] := highColor shl 4 + lowColor
                  end;
                #2: begin
                    savedColors := iconColors;
                    SetIconMenu(lastState)
                  end;
                #3: begin
                    iconColors := savedColors;
                    SetIconMenu(lastState)
                  end
              end
            end
        end;
    end;
    CopyIconPics(orderNumber, 12, True)
  until iconDone <> 0;
  iconHead := savedHead;
  iconBody := savedBody;
  iconSize := savedSize;
  iconColors := savedColors;
  CopyIconPics(orderNumber, 12, True);
  CopyIconPics(12, orderNumber, False);
  end;
  MenuCore.ClearBottomLine;
  MapTiles.FreeIconAnim(12);
  until Char(MenuCore.YesNoMenu(GDConsts.iconOkQuery, GDConsts.yesKey)) = Chr(GDConsts.yesKey);
  CbtMap.SetNoncombatPalette
end;

function HpMinimum(character: Types.PCharacter): Byte;
var classCount: Byte;
    adjustment: ShortInt;
    total: Byte;
    classIndex: ShortInt;
begin
  with character^ do begin
    adjustment := 0;
    classCount := 0;
    total := 0;
    for classIndex := 0 to 7 do
      if classLevels[classIndex] > 0 then begin
        Inc(total, classLevels[classIndex]);
        Inc(classCount);
        case classIndex of
          C_Class.RANGER: Inc(total);
          C_Class.KNIGHT: Inc(total)
        end;
        Inc(adjustment, ViewChar.ClassConHpBonus(character, classIndex))
      end;
  end;
  if adjustment < 0 then begin
    if total > Abs(adjustment) + classCount then
      total := (total + adjustment) div classCount
    else
      total := 1
  end else
    total := (total + adjustment) div classCount;
  HpMinimum := total
end;

const
  PROBE_TEXT = 'TEST';
  UNAVAILABLE_MESSAGE = 'we only train conscious people';
  RESTRICTED_MESSAGE = 'We don''t train that class here';

procedure TrainingMenu;
var eligible: Boolean;
    words: LongInt;
    nextThreshold: LongInt;
    readyClassBits: Byte;
    heldClassBits: Byte;
    allowedClasses: Byte;
    levelCount: Byte;
    { Unused in this version; see the other implementations of this routine. }
    hpDelta: array[0..4] of Byte;
    classIndex: ShortInt;
    { Unused in this version; see the other implementations of this routine. }
    conBonus: array[0..1] of Byte;
    row: Byte;
    savedClass5: ShortInt;
    savedClass4: ShortInt;
    abilityLevel: ShortInt;
    selectionResult: Byte;
    selection: Integer;
    selectionActive: Boolean;
    { Unused in this version; see the other implementations of this routine. }
    selectedClass: Byte;
    savedSetting: Byte;
    bestThreshold: LongInt;
    chosenClass: ShortInt;
    classLevel: ShortInt;
begin
  GDVars.testTrainMode := Byte(Boolean(ParamStr(3) = CharGen.PROBE_TEXT) and (GDVars.autoTraining = 0));
  if (GDVars.autoTraining = 0) and (not ViewChar.PickCharacter) then
    Exit;
  if (GDVars.currentCharacter^.status <> C_Status.OKAY) and (GDVars.testTrainMode = 0) then begin
    TextRend.PrintAndPause(CharGen.UNAVAILABLE_MESSAGE, Yellow, Black);
    Exit
  end;
  readyClassBits := 0;
  heldClassBits := 0;
  words := 0;
  savedSetting := GDVars.zone1^.trainMask[trainMaskIndex + $7C00];
  with GDVars.currentCharacter^ do begin
  words := 0;
  for classIndex := 0 to 7 do
      if classLevels[classIndex] > 0 then begin
        Inc(heldClassBits, GDConsts.trainingClassBits[classIndex]);
        eligible := False;
        abilityLevel := classLevels[classIndex];
        eligible := GDConsts.racialLevelCaps[race, classIndex] <= Byte(abilityLevel);
        classLevel := CharHlp.ClassSuborderIndex(GDVars.currentCharacter, classIndex);
        if not eligible then
          if (GDConsts.classProgression[classLevel].experience[Succ(abilityLevel)] <= experience) or
              (GDVars.testTrainMode <> 0) then
            if GDConsts.classProgression[classLevel].experience[Succ(abilityLevel)] > 0 then begin
              if GDVars.testTrainMode <> 0 then
                if (GDConsts.classProgression[classLevel].experience[Succ(abilityLevel)] > 0) and
                    (GDConsts.classProgression[classLevel].experience[Succ(abilityLevel)] > experience) then
                  experience := GDConsts.classProgression[classLevel].experience[Succ(abilityLevel)];
              Inc(readyClassBits, GDConsts.trainingClassBits[classIndex]);
              nextThreshold := GDConsts.classProgression[classLevel].experience[Succ(Succ(abilityLevel))];
              if (nextThreshold > 0) and (experience >= nextThreshold) and (nextThreshold > words) then
                words := nextThreshold - 1
            end
      end;
  if GDVars.autoTraining = 0 then begin
    bestThreshold := 0;
    nextThreshold := 0;
    for classIndex := 0 to 7 do
      if (GDConsts.trainingClassBits[classIndex] and readyClassBits) <> 0 then
        if GDConsts.classProgression[classLevel].experience[Succ(abilityLevel)] > bestThreshold then begin
          bestThreshold := GDConsts.classProgression[classLevel].experience[Succ(abilityLevel)];
          chosenClass := classIndex
        end;
    if bestThreshold > 0 then begin
      readyClassBits := GDConsts.trainingClassBits[chosenClass] or readyClassBits;
      nextThreshold := GDConsts.classProgression[classLevel].experience[Succ(Succ(abilityLevel))];
      if (nextThreshold > 0) and (experience >= nextThreshold) and (nextThreshold > words) then
        words := nextThreshold - 1
    end
  end;
  if (words > 0) and (GDVars.autoTraining = 0) then
    experience := words;
  if GDVars.testTrainMode = 0 then begin
    if ((heldClassBits and savedSetting) = 0) and (GDVars.autoTraining = 0) then begin
      TextRend.PrintAndPause(CharGen.RESTRICTED_MESSAGE, Yellow, Black);
      Exit
    end else if (readyClassBits and savedSetting) = 0 then begin
      GDVars.trainingDone := 1;
      if GDVars.autoTraining = 0 then
        TextRend.PrintAndPause(GDConsts.notEnoughExperienceText, Yellow, Black);
      Exit
    end
  end;
  if GDVars.testTrainMode = 0 then
    allowedClasses := readyClassBits and savedSetting
  else
    allowedClasses := readyClassBits;
  if GDVars.autoTraining = 0 then begin
    Border.ClearBox(1, 1, 38, 22);
    row := 4;
    CharHlp.DisplayCreatureName(GDVars.currentCharacter, 4, row, False);
    TextRend.DisplayString(Length(name) + 4, row, LightGreen, Black, GDConsts.willBecomeText);
    for classIndex := 0 to 7 do
      if (classLevels[classIndex] > 0) and ((GDConsts.trainingClassBits[classIndex] and allowedClasses) > 0) then begin
        Inc(row);
        if row = 5 then
          TextRend.DisplayString(6, row, LightGreen, Black,
                                 GDConsts.aLevelText + CharHlp.ByteToString(classLevels[classIndex] + 1) + ' ' +
                                   GDConsts.classNames[classIndex])
        else
          TextRend.DisplayString(6, row, LightGreen, Black,
                                 GDConsts.andALevelText + CharHlp.ByteToString(classLevels[classIndex] + 1) + ' ' +
                                   GDConsts.classNames[classIndex])
      end;
    if Char(MenuCore.YesNoMenu(GDConsts.wishToTrainQuery, GDConsts.yesKey)) <> Chr(GDConsts.yesKey) then
      Exit;
    CharHlp.PrintBottomLine(GDConsts.congratulationsText)
  end;
  levelCount := 0;
  savedClass5 := classLevels[C_Class.MAGE];
  savedClass4 := classLevels[C_Class.RANGER];
  classMask := 0;
  for classIndex := 0 to 7 do
    if classLevels[classIndex] > 0 then begin
      Inc(levelCount);
      if (GDConsts.trainingClassBits[classIndex] and allowedClasses) > 0 then
        Inc(classLevels[classIndex])
    end;
  ClassCal.RecalcClassStats(GDVars.currentCharacter);
  if GDVars.autoTraining = 0 then
    if (classLevels[C_Class.MAGE] > savedClass5) or
        ((classLevels[C_Class.RANGER] > 8) and (classLevels[C_Class.RANGER] > savedClass4)) then begin
      selection := -1;
      repeat
        selectionResult := ViewChar.SpellMenu(4, 4, selection, selectionActive)
      until (selectionResult > 0) or not selectionActive;
      if selectionResult > 0 then
        spells^.known[selectionResult] := 1
    end;
  if GDVars.autoTraining <> 0 then begin
    if robeOrder = 1 then
      case classLevels[C_Class.MAGE] of
        3: begin
            spells^.known[C_Spell.DETECT_INVISIBILITY] := 1;
            spells^.known[C_Spell.RAY_OF_ENFEEBLEMENT] := 1;
            spells^.known[C_Spell.STINKING_CLOUD] := 1
          end;
        5: begin
            spells^.known[C_Spell.DISPEL_MAGIC_MAGE] := 1;
            spells^.known[C_Spell.FIREBALL] := 1;
            spells^.known[C_Spell.LIGHTNING_BOLT] := 1
          end;
        7: begin
            spells^.known[C_Spell.CHARM_MONSTERS] := 1;
            spells^.known[C_Spell.CONFUSION] := 1;
            spells^.known[C_Spell.FIRE_SHIELD] := 1;
            spells^.known[C_Spell.ICE_STORM] := 1
          end
      end else
      case classLevels[C_Class.MAGE] of
        3: begin
            spells^.known[C_Spell.INVISIBILITY] := 1;
            spells^.known[C_Spell.KNOCK] := 1;
            spells^.known[C_Spell.MIRROR_IMAGE] := 1;
            spells^.known[C_Spell.STINKING_CLOUD] := 1
          end;
        5: begin
            spells^.known[C_Spell.BLINK_MAGE] := 1;
            spells^.known[C_Spell.FIREBALL] := 1;
            spells^.known[C_Spell.HASTE] := 1;
            spells^.known[C_Spell.INVISIBILITY_RADIUS] := 1
          end;
        7: begin
            spells^.known[C_Spell.DIMENSION_DOOR] := 1;
            spells^.known[C_Spell.FIRE_SHIELD] := 1;
            spells^.known[C_Spell.FEAR] := 1;
            spells^.known[C_Spell.ICE_STORM] := 1
          end
      end
  end;
  end;
  ViewChar.AdjustLevelHitPoints(GDVars.currentCharacter, allowedClasses, levelCount, True);
  GDVars.currentCharacter^.levelUpReady := Ord(CharHlp.CanLevelUp(GDVars.currentCharacter))
end;

procedure CreateStartingItems(character: Pointer);
var
  oldItem: Types.PItem;
  newItem: Types.PItem;
  itemClass: Byte;
  itemKind: Byte;
  itemIndex: Byte;
  typedCharacter: Types.PCharacter absolute character;
begin
  if typedCharacter^.classLevels[C_Class.KNIGHT] > 0 then
    itemClass := 1
  else if (typedCharacter^.classLevels[C_Class.FIGHTER] > 0) or
    (typedCharacter^.classLevels[C_Class.RANGER] > 0) or
    (typedCharacter^.classLevels[C_Class.PALADIN] > 0) then
    itemClass := 2
  else if typedCharacter^.classLevels[C_Class.THIEF] > 0 then
    itemClass := 3
  else if typedCharacter^.classLevels[C_Class.CLERIC] > 0 then
    itemClass := 4
  else
    itemClass := 5;
  for itemIndex := 1 to 4 do begin
    newItem := GameIo.AllocSlot;
    FillChar(newItem^, SizeOf(Types.TItem), 0);
    if (itemClass = 3) and (itemIndex = 1) and (typedCharacter^.classLevels[C_Class.CLERIC] > 0) then
      itemKind := GDConsts.startingItems[4, 1]
    else
      itemKind := GDConsts.startingItems[itemClass, itemIndex];
    if (itemKind <> 0) and (GDVars.itemTemplates[itemKind].itemType <> 255) then begin
      Move(GDVars.itemTemplates[itemKind], newItem^.itemType, SizeOf(Types.TItemTemplate));
      newItem^.next := nil;
      newItem^.inUse := 0;
      if typedCharacter^.items = nil then
        typedCharacter^.items := newItem
      else begin
        oldItem := typedCharacter^.items;
        typedCharacter^.items := newItem;
        typedCharacter^.items^.next := oldItem
      end;
      typedCharacter^.items^.unidentifiedMask := typedCharacter^.items^.unidentifiedMask and $F8;
      if itemKind <> 91 then
        typedCharacter^.items^.equipped := 1
    end
  end;
  CharHlp.RecalcStats(character);
  typedCharacter^.numberOfItems := 3
end;

{ A private routine nothing calls. }
procedure NoopCharGen; forward;

{ Takes a knight back a level when its experience no longer reaches it for its order, with the hit points that level
  gave.
  @param(character The knight.) }
procedure AdvanceKnightOrder(character: Pointer);
var
  oldLevel: ShortInt;
  thresholdClass: ShortInt;
  hitPointLoss: Byte;
  adjustment: ShortInt;
  typedCharacter: Types.PCharacter absolute character;
begin
  oldLevel := typedCharacter^.classLevels[C_Class.KNIGHT];
  if typedCharacter^.knightOrder = 1 then
    thresholdClass := 4
  else
    thresholdClass := 5;
  if GDConsts.classProgression[thresholdClass].experience[oldLevel] > typedCharacter^.experience then begin
    Dec(typedCharacter^.classLevels[C_Class.KNIGHT]);
    if oldLevel > 9 then begin
      hitPointLoss := 2;
      adjustment := 0
    end else begin
      hitPointLoss := typedCharacter^.baseMaxHitPoints div (oldLevel + 1);
      adjustment := CharHlp.ClassConAdj(GDVars.currentCharacter, C_Class.KNIGHT)
    end;
    Dec(typedCharacter^.baseMaxHitPoints, hitPointLoss);
    Dec(typedCharacter^.maxHitPoints, hitPointLoss + adjustment);
    if typedCharacter^.hitPoints >= typedCharacter^.maxHitPoints then
      typedCharacter^.hitPoints := typedCharacter^.maxHitPoints
  end;
  Inc(typedCharacter^.knightOrder);
  ClassCal.RecalcClassStats(Types.PCharacter(character));
  typedCharacter^.levelUpReady := Ord(CharHlp.CanLevelUp(character))
end;

const
  EXIT_TEXT = 'Exit';

procedure KnightPromotionMenu;
var orderName: String[5];
    { Unused in this version; see the other implementations of this routine. }
    inputText: String[11];
    scanIndex: ShortInt;
    requirementsMet: Byte;
    choice: Byte;
    done: Byte;
    { Unused in this version; see the other implementations of this routine. }
    isExtended: Byte;
    column: Byte;
    character: Types.PCharacter;
begin
  if not ViewChar.PickCharacter then
    Exit;
  character := GDVars.currentCharacter;
  Border.DrawWindowFrame(0);
  if (character^.classLevels[C_Class.KNIGHT] = 0) or
      ((character^.classLevels[C_Class.KNIGHT] > 0) and (character^.knightOrder = 3)) then
    Exit;
  done := 0;
  inputText := CharGen.EXIT_TEXT;
  with character^ do begin
    column := 19 - (Length(name) div 2);
    TextRend.DisplayString(column, 3, LightGreen, Black, name);
    TextRend.DisplayString(7, 5, LightGreen, Black, GDConsts.petitioningText);
    case knightOrder of
      1: orderName := GDConsts.swordText;
      2: orderName := GDConsts.roseText
    end;
    TextRend.DisplayString(10, 7, LightGreen, Black, GDConsts.knightOfTheText + orderName);
    case knightOrder of
      1: begin
    column := 19 - ((Length(name) + 21) div 2);
    if (classLevels[C_Class.KNIGHT] < 3) or (experience < GDConsts.classProgression[4].experience[3]) then
      TextRend.DisplayString(column, 9, LightGreen, Black, name + GDConsts.tooInexperiencedText)
    else begin
      column := 19 - ((Length(name) + 18) div 2);
      requirementsMet := 1;
      for scanIndex := 0 to 5 do
        if stats[scanIndex].base < GDConsts.knightRequirements[2, scanIndex] then
          requirementsMet := 0;
      if requirementsMet = 0 then
        TextRend.DisplayString(column, 9, LightGreen, Black, name + GDConsts.doesNotQualifyText)
      else begin
        column := 19 - ((Length(name) + 13) div 2);
        TextRend.DisplayString(column, 9, LightGreen, Black, name + GDConsts.mayBecomeText);
        TextRend.DisplayString(10, 11, LightGreen, Black, GDConsts.knightOfTheText + GDConsts.swordText)
      end
    end
      end;
      2: begin
    column := 20 - ((Length(name) + 21) div 2);
    if (classLevels[C_Class.KNIGHT] < 4) or (experience < GDConsts.classProgression[5].experience[4]) then
      TextRend.DisplayString(column, 9, LightGreen, Black, name + GDConsts.tooInexperiencedText)
    else begin
      column := 20 - ((Length(name) + 18) div 2);
      requirementsMet := 1;
      for scanIndex := 0 to 5 do
        if stats[scanIndex].base < GDConsts.knightRequirements[3, scanIndex] then
          requirementsMet := 0;
      if requirementsMet = 0 then
        TextRend.DisplayString(column, 9, LightGreen, Black, name + GDConsts.doesNotQualifyText)
      else begin
        column := 19 - ((Length(name) + 13) div 2);
        TextRend.DisplayString(column, 9, LightGreen, Black, name + GDConsts.mayBecomeText);
        TextRend.DisplayString(10, 11, LightGreen, Black, GDConsts.knightOfTheText + GDConsts.roseText)
      end
    end
      end
    end
  end;
  repeat
    MenuCore.EnableChoices(1);
    choice := MenuCore.MenuHorizontal(GDConsts.emptyQuery, GDConsts.changeExitMenu, 0, 0);
    case choice of
      0: begin
          CharGen.AdvanceKnightOrder(character);
          done := 1
        end;
      1: done := 1
    else
      if (GDVars.menuExtendedKey <> 0) and (choice = Ord(C_Keys.ESCAPE)) then
        done := 1
    end
  until done <> 0
end;

const
  CONFIG_NAME = 'krynn.cfg';
  MOUSE_ON = 'mouse ON';
  MOUSE_OFF = 'mouse OFF';
  JOYSTICK_ON = 'joystick ON';
  JOYSTICK_OFF = 'joystick OFF';
  DISABLE_BOTH = 'disable both';
  CONFIG_M = 'M';
  CONFIG_N = 'N';
  CONFIG_J = 'J';

procedure InitMouseJoystick;
var
  config: Pointer;
  walk: Pointer;
  configNode: Types.PMenuRow absolute config;
  choice: Byte;
  result: Char;
  done: Boolean;
  doneByte: Byte absolute done;
  selected: Word;
  selectedInteger: Integer absolute selected;
  x: Integer;
  y: Integer;
  z: Integer;
  configCopy: Pointer;
  configInput: Text;
  configOutput: Text;
  lineIndex: Byte;
  configLines: array[1..5] of String;
  partyMenuItems: array[1..3] of String[40];
begin
  MenuCore.AllocStringList(3, configNode);
  done := True;
  choice := 0;
  configCopy := config;
  selected := 0;
  repeat
    Assign(configInput, CharGen.CONFIG_NAME);
    Reset(configInput);
    for lineIndex := 1 to 5 do
      ReadLn(configInput, configLines[lineIndex]);
    Close(configInput);
    if GDVars.mousePresent <> 0 then
      partyMenuItems[1] := CharGen.MOUSE_ON
    else
      partyMenuItems[1] := CharGen.MOUSE_OFF;
    if GDVars.joystickActive <> 0 then
      partyMenuItems[2] := CharGen.JOYSTICK_ON
    else
      partyMenuItems[2] := CharGen.JOYSTICK_OFF;
    partyMenuItems[3] := CharGen.DISABLE_BOTH;
    walk := config;
    for lineIndex := 1 to 3 do begin
      Types.PMenuRow(walk)^.name := partyMenuItems[lineIndex];
      Types.PMenuRow(walk)^.heading := 0;
      walk := Types.PMenuRow(walk)^.next
    end;
    done := True;
    MenuCore.EnableChoices(0);
    result := Char(MenuCore.MenuVertical(GDConsts.initInputQuery, GDConsts.selectMenuText, 9, 12, 38, 22, config, 1, 0,
                                         doneByte,
                                         selectedInteger, configCopy));
    if result = #0 then
      case selected of
        0: begin
          GDVars.mousePresent := Ord(GDVars.mousePresent = 0);
          Assign(configOutput, CharGen.CONFIG_NAME);
          Rewrite(configOutput);
          if GDVars.mousePresent <> 0 then begin
            GDVars.mouseMode := 1;
            GDVars.mouseButtonCount := 0;
            Mouse.InitMouse;
            if GDVars.mousePresent <> 0 then begin
              if GDVars.displayMode = Types.Cga then
                GDVars.activeCursorMask := @GDConsts.cursorMaskCga
              else
                GDVars.activeCursorMask := @GDConsts.cursorMaskEga;
              Mouse.SetMouseCursor(0, 0, Types.PCursorMask(GDVars.activeCursorMask));
              GDVars.mouseScaled := True;
              Mouse.SetMouse(639, 100);
              Mouse.GetMouse(x, y, z);
              GDVars.mouseScaled := (y >= 321) = False;
              GDVars.joystickActive := 0;
              Mouse.ShowMouse;
              configLines[3] := CharGen.CONFIG_M;
              for lineIndex := 1 to 5 do
                WriteLn(configOutput, configLines[lineIndex]);
              for lineIndex := 0 to 13 do
                WriteLn(configOutput, '0');
              Close(configOutput);
              GDVars.mouseRawX := 160;
              GDVars.mouseRawY := 100;
              GDVars.mouseCurrentX := 0;
              GDVars.mouseCurrentY := 0
            end
          end;
          if GDVars.mousePresent = 0 then begin
            configLines[3] := CharGen.CONFIG_N;
            for lineIndex := 1 to 5 do
              WriteLn(configOutput, configLines[lineIndex]);
            for lineIndex := 0 to 13 do
              WriteLn(configOutput, '0');
            Close(configOutput);
            GDVars.mousePresent := 1;
            Mouse.HideMouse;
            GDVars.mousePresent := 0
          end
        end;
        1: begin
          GDVars.joystickActive := Ord(GDVars.joystickActive = 0);
          Assign(configOutput, CharGen.CONFIG_NAME);
          Rewrite(configOutput);
          if GDVars.joystickActive <> 0 then begin
            CharGen.CalibrateJoystickInWindow;
            if GDVars.joystickActive <> 0 then begin
              configLines[3] := CharGen.CONFIG_J;
              for lineIndex := 1 to 5 do
                WriteLn(configOutput, configLines[lineIndex]);
              for lineIndex := 0 to 6 do begin
                WriteLn(configOutput, GDVars.joyCalib[1].x.words[lineIndex]);
                WriteLn(configOutput, GDVars.joyCalib[1].y.words[lineIndex])
              end;
              Close(configOutput);
              if GDVars.joystickActive <> 0 then begin
                Mouse.HideMouse;
                GDVars.mousePresent := 0
              end
            end
          end;
          if GDVars.joystickActive = 0 then begin
            configLines[3] := CharGen.CONFIG_N;
            for lineIndex := 1 to 5 do
              WriteLn(configOutput, configLines[lineIndex]);
            for lineIndex := 0 to 13 do
              WriteLn(configOutput, '0');
            Close(configOutput)
          end
        end;
        2: begin
          GDVars.joystickActive := 0;
          Mouse.HideMouse;
          GDVars.mousePresent := 0;
          Assign(configOutput, CharGen.CONFIG_NAME);
          Rewrite(configOutput);
          configLines[3] := CharGen.CONFIG_N;
          for lineIndex := 1 to 5 do
            WriteLn(configOutput, configLines[lineIndex]);
          for lineIndex := 0 to 13 do
            WriteLn(configOutput, '0');
          Close(configOutput)
        end
      end else
      choice := 1
  until choice <> 0;
  MenuCore.FreeMenuRows(configNode)
end;

const
  UPPER_PROMPT1 = 'Push JOYSTICK #1 to the extreme upper';
  UPPER_PROMPT2 = 'left position and press button #1.';
  READ_ERROR = 'Unable to read joystick';
  LOWER_PROMPT1 = 'Push JOYSTICK #1 to the extreme lower';
  LOWER_PROMPT2 = 'right position and press button #1.';

procedure CalibrateJoystickInWindow;
var
  sumX: Word;
  sumY: Word;
  ok: Byte;
  x: Word;
  y: Word;
  { Unused in this version; see the other implementations of this routine. }
  reading: Byte;
  sample: Word;
  buttons: Byte;
begin
  Joystick.ProbeJoystick;
  if GDVars.joystickActive = 0 then
    Exit;
  sumX := 0;
  sumY := 0;
  for sample := 1 to 20 do begin
    ok := Ord(Joystick.ReadJoystick(1, x, y, buttons));
    Inc(sumX, x);
    Inc(sumY, y)
  end;
  GDVars.joyCalib[1].x.words[3] := sumX div 20;
  GDVars.joyCalib[1].y.words[3] := sumY div 20;
  repeat
    Border.ClearBox(1, 1, 38, 22);
    TextRend.DisplayString(1, 3, LightMagenta, Black, CharGen.UPPER_PROMPT1);
    TextRend.DisplayString(1, 5, LightMagenta, Black, CharGen.UPPER_PROMPT2);
    sample := 0;
    repeat
      ok := Ord(Joystick.ReadJoystick(1, x, y, buttons));
      Inc(sample)
    until (sample > 20000) or ((ok <> 0) and ((buttons and GDConsts.joystickButtonMasks[1, 1]) <> 0));
    if sample > 20000 then begin
      Border.ClearBox(1, 1, 38, 22);
      TextRend.DisplayString(1, 3, LightMagenta, Black, CharGen.READ_ERROR);
      Delay(2000);
      Exit
    end;
    sumX := 65535;
    sumY := 65535;
    for GDVars.loopIndex := 1 to 20 do
      if Joystick.ReadJoystick(1, x, y, buttons) then begin
        if (buttons and GDConsts.joystickButtonMasks[1, 1]) <> 0 then begin
          if x < sumX then sumX := x;
          if y < sumY then sumY := y
        end
      end else begin
        Border.ClearBox(1, 1, 38, 22);
        TextRend.DisplayString(1, 3, LightMagenta, Black, CharGen.READ_ERROR);
        Delay(2000);
        Exit
      end
  until ok <> 0;
  GDVars.joyCalib[1].x.words[0] := sumX;
  GDVars.joyCalib[1].x.words[1] :=
    GDVars.joyCalib[1].x.words[0] + (GDVars.joyCalib[1].x.words[3] - GDVars.joyCalib[1].x.words[0]) div 3;
  GDVars.joyCalib[1].x.words[2] :=
    GDVars.joyCalib[1].x.words[0] + (GDVars.joyCalib[1].x.words[3] - GDVars.joyCalib[1].x.words[0]) * 2 div 3;
  GDVars.joyCalib[1].y.words[0] := sumY;
  GDVars.joyCalib[1].y.words[1] :=
    GDVars.joyCalib[1].y.words[0] + (GDVars.joyCalib[1].y.words[3] - GDVars.joyCalib[1].y.words[0]) div 3;
  GDVars.joyCalib[1].y.words[2] :=
    GDVars.joyCalib[1].y.words[0] + (GDVars.joyCalib[1].y.words[3] - GDVars.joyCalib[1].y.words[0]) * 2 div 3;
  repeat
  until not Joystick.JoyButton(1, 1);
  repeat
    Border.ClearBox(1, 1, 38, 22);
    TextRend.DisplayString(1, 3, LightMagenta, Black, CharGen.LOWER_PROMPT1);
    TextRend.DisplayString(1, 5, LightMagenta, Black, CharGen.LOWER_PROMPT2);
    sample := 0;
    repeat
      ok := Ord(Joystick.ReadJoystick(1, x, y, buttons));
      Inc(sample)
    until (sample > 20000) or ((ok <> 0) and ((buttons and GDConsts.joystickButtonMasks[1, 1]) <> 0));
    if sample > 20000 then begin
      Border.ClearBox(1, 1, 38, 22);
      TextRend.DisplayString(1, 3, LightMagenta, Black, CharGen.READ_ERROR);
      Delay(2000);
      Exit
    end;
    sumX := 0;
    sumY := 0;
    for GDVars.loopIndex := 1 to 20 do
      if Joystick.ReadJoystick(1, x, y, buttons) then begin
        if (buttons and GDConsts.joystickButtonMasks[1, 1]) <> 0 then begin
          if x > sumX then sumX := x;
          if y > sumY then sumY := y
        end
      end else begin
        Border.ClearBox(1, 1, 38, 22);
        TextRend.DisplayString(1, 3, LightMagenta, Black, CharGen.READ_ERROR);
        Delay(2000);
        Exit
      end
  until ok <> 0;
  GDVars.joyCalib[1].x.words[6] := sumX;
  GDVars.joyCalib[1].x.words[4] :=
    GDVars.joyCalib[1].x.words[3] + (GDVars.joyCalib[1].x.words[6] - GDVars.joyCalib[1].x.words[3]) div 3;
  GDVars.joyCalib[1].x.words[5] :=
    GDVars.joyCalib[1].x.words[3] + (GDVars.joyCalib[1].x.words[6] - GDVars.joyCalib[1].x.words[3]) * 2 div 3;
  GDVars.joyCalib[1].y.words[6] := sumY;
  GDVars.joyCalib[1].y.words[4] :=
    GDVars.joyCalib[1].y.words[3] + (GDVars.joyCalib[1].y.words[6] - GDVars.joyCalib[1].y.words[3]) div 3;
  GDVars.joyCalib[1].y.words[5] :=
    GDVars.joyCalib[1].y.words[3] + (GDVars.joyCalib[1].y.words[6] - GDVars.joyCalib[1].y.words[3]) * 2 div 3;
  GDVars.joystickActive := 1
end;

{ Empty routine with no callers. }
procedure NoopCharGen;
begin
end;
begin
end.
