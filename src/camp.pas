{ Camp -- the camp menu: Save (with the rule-book copy check every tenth save), View, Magic (cast, memorize, scribe, the
  spells in effect, rest), Rest, Alter (order, drop, speed, icon, level) and Fix, which heals the party with its
  memorized cures. }
{$F+,O+,S-,R-,V-,B-,I-}
unit Camp;
interface
uses C_Class, C_Effect, C_Ifc, C_Race, C_Stat, C_Status, Crt, C_Keys, GDConsts, GDVars, Types, CharHlp,
  GameIo, MenuCore, FxEngine, ViewChar, TextRend, Border, Magic, GameTime, SaveLoad, CharGen, Portrait;

{ The camp menu, for EclVm: the camping interface state while it is up, the party's scribing reset on the way in and
  out. Save counts the zone's quitCounter and every tenth save asks the copy question first, aborting on a wrong answer;
  then it saves and offers to quit. The encounter picture is reloaded on the way out.
  @param(interrupted Set when a rest is interrupted, which also ends the menu.) }
procedure CampMainMenu(var interrupted: Boolean);

{ Runs the noncombat Cast menu for the current character until no spell is picked, saying 'has no spells memorized' when
  the list is empty. Clears the remembered cast target on entry, and redraws the noncombat interface afterwards if a
  spell was cast or the spell list was not empty. }
procedure NoncombatCastMenu;
implementation
type
  TEncodedWord = record
    count: Byte;
    chars: array[1..9] of ShortInt;
    wordNo: Byte;
    wordNoTail: Byte
  end;
  TEncodedRow = record
    case Boolean of
      False: (data: array[0..81] of ShortInt);
      True: (dataTail: array[0..10] of Byte;
            words: array[0..4] of TEncodedWord);
      True: (metaWords: array[0..4] of TEncodedWord)
  end;
var copyProtectionTable: array[1..5] of TEncodedRow absolute GDConsts.copyProtectionData;

{ Returns the smaller of two counts.
  @param(a First count.)
  @param(b Second count.)
  @returns(The smaller count.) }
function Smaller(a, b: Word): Word;
begin
  Smaller := a;
  if b < a then Smaller := b
end;

{ Returns the time a character needs to finish memorizing its pending spells and scribing its marked scrolls: a base of
  4 hours when anything is pending, 6 when any of those spells is above level 2, plus 15 minutes a spell level (a level
  0 spell being memorized counts as level 1). Pending spells count only while the character is enabled. The base hours
  are stored in its spellPrep.
  @param(character Character to time.)
  @returns(The preparation time, in minutes.) }
function CampSpellPrepTime(character: Types.PCharacter): Word;
var
  maxMem: Byte;
  maxScroll: Byte;
  countMem: Byte;
  countScroll: Byte;
  item: Types.PItem;
  i: Byte;
  level: Byte;
  base: Byte;
begin
  maxMem := 0;
  maxScroll := 0;
  countMem := 0;
  countScroll := 0;
  if character^.spells <> nil then
    for i := 0 to 73 do
      if (character^.spells^.memorized[i] > $7F) and (character^.enabled <> 0) then begin
        level := GDConsts.spellTable[character^.spells^.memorized[i] and $7F].level;
        if level = 0 then level := 1;
        if level > maxMem then maxMem := level;
        Inc(countMem, level)
      end;
  item := character^.items;
  while item <> nil do begin
    if Magic.ItemReadable(item) then
      for i := 1 to 3 do
        if item^.scrollSpells[i] > $7F then begin
          level := GDConsts.spellTable[item^.scrollSpells[i] and $7F].level;
          if level > maxScroll then maxScroll := level;
          Inc(countScroll, level)
        end;
    item := item^.next
  end;
  base := 0;
  if (countMem > 0) or (countScroll > 0) then base := 4;
  if (maxMem > 2) or (maxScroll > 2) then base := 6;
  character^.spellPrep := base;
  CampSpellPrepTime := base * 60 + countMem * 15 + countScroll * 15
end;

{ The rule-book check: asks for one random word of one random heading, showing the heading and its page, up to three
  times.
  @returns(1 if the word was given, 0 after three wrong answers.) }
function RuleBookCheck: Byte;

  { Decodes a heading, or one of its words, from the copy-protection table. }
  function DecodeAnswer(tableIndex, wordIndex: Byte; useHeading: Boolean): String;
  var
    count: Byte;
    letterIndex: Byte;
    decodedLetter: Byte;
    answer: String;
  begin
    answer := '';
    with copyProtectionTable[tableIndex] do begin
      if useHeading then begin
        count := data[0];
        for letterIndex := 1 to count do begin
          decodedLetter := data[letterIndex] + 40 + count;
          answer := answer + Chr(decodedLetter)
        end
      end else begin
        count := words[wordIndex].count;
        for letterIndex := 1 to count do begin
          decodedLetter := words[wordIndex].chars[letterIndex] + 40 + count;
          answer := answer + Chr(decodedLetter)
        end
      end
    end;
    DecodeAnswer := answer
  end;
var
  { Unused in this version; see the other implementations of this routine. }
  charIndex: Byte;
  headingIndex: Byte;
  attempts: Byte;
  { Unused in this version; see the other implementations of this routine. }
  passed: Byte;
  correctAnswer: String;
  headingText: String;
  pageNumber: Byte;
  wordNumber: Byte;
  wordIndex: Byte;
  reply: String;
begin
  Border.DrawWindowFrame(0);
  attempts := 0;
  headingIndex := Random(5) + 1;
  wordIndex := Random(5) + 1;
  repeat
    Inc(attempts);
    correctAnswer := '';
    TextRend.DisplayString(3, 2, LightGreen, Black, GDConsts.promptWord);
    with copyProtectionTable[headingIndex] do begin
      wordNumber := metaWords[wordIndex].wordNo;
      pageNumber := data[21];
      headingText := DecodeAnswer(headingIndex, wordIndex, True);
      correctAnswer := DecodeAnswer(headingIndex, wordIndex, False);
      TextRend.DisplayString(19, 2, LightGreen, Black, CharHlp.ByteToString(wordNumber) + '    ');
      TextRend.DisplayString(3, 4, LightGreen, Black, GDConsts.promptHeading);
      TextRend.DisplayString(3, 6, LightGreen, Black, '                                  ');
      TextRend.DisplayString(3, 6, LightGreen, Black, '"' + headingText + '"');
      TextRend.DisplayString(3, 8, LightGreen, Black,
                             GDConsts.promptRuleBookPage + CharHlp.ByteToString(pageNumber) + ')?' + '     ')
    end;
    reply := TextRend.ReadString('Enter ', Yellow, Black, 20)
  until (attempts = 3) or (reply = correctAnswer);
  if reply = correctAnswer then RuleBookCheck := 1
  else RuleBookCheck := 0
end;

{ Drops the spells a character has pending and its preparation time.
  @param(character Character to reset.) }
procedure ResetMemorize(character: Types.PCharacter);
var i: Byte;
begin
  if character^.spells <> nil then
    for i := 0 to 73 do
      if character^.spells^.memorized[i] > $7F then
        character^.spells^.memorized[i] := 0;
  character^.spellPrep := 0
end;

{ Clears the pending flag of every scroll spell on a character's readable items.
  @param(character The character.) }
procedure ResetScribe(character: Types.PCharacter);
var i: Byte;
    item: Types.PItem;
begin
  item := character^.items;
  while item <> nil do begin
    if Magic.ItemReadable(item) then
      for i := 1 to 3 do item^.scrollSpells[i] := item^.scrollSpells[i] and $7F;
    item := item^.next
  end
end;

{ Clears every member's scribing marks. }
procedure ResetPartySpellActivities;
var character: Types.PCharacter;
begin
  character := GDVars.partyHead;
  while character <> nil do begin
    Camp.ResetScribe(character);
    character := character^.next
  end
end;

{ Returns the current character's free spell slots of one level and spell type, counting the memorized and pending
  spells against its slots. The special type counts a cleric's deity gifts instead: 3 for deity 4, none for deity 6, 1
  otherwise, less the special spells (ids 101..107) memorized. Note: for a character with no cleric levels the special
  count starts undefined.
  @param(spellLevel Spell level, 1..8; ignored for the special type.)
  @param(spellClass Spell type: 0 cleric, 1 druid, 2 special, 3 magic-user.)
  @param(usedSlots Receives the slots of that level and type already taken; left alone for the special type.)
  @returns(The number of free slots.) }
function SpellSlotsRemaining(spellLevel, spellClass: ShortInt; var usedSlots: Byte): Byte;
var
  count: Byte;
  i: Byte;
begin
  if GDVars.currentCharacter^.spells <> nil then
    if spellClass = 2 then begin
      if GDVars.currentCharacter^.classLevels[C_Class.CLERIC] > 0 then
        case GDVars.currentCharacter^.deity of
          4: count := 3;
          6: count := 0
        else
          count := 1
        end;
      for i := 0 to 73 do
        if ((GDVars.currentCharacter^.spells^.memorized[i] and $7F) > 100) and
            ((GDVars.currentCharacter^.spells^.memorized[i] and $7F) < 108) then
          Dec(count);
      SpellSlotsRemaining := count
    end else
      with GDVars.currentCharacter^ do begin
        count := 0;
        for i := 0 to 73 do
          if spells^.memorized[i] > 0 then
            if GDConsts.spellTable[spells^.memorized[i] and $7F].level = spellLevel then
              if GDConsts.spellTable[spells^.memorized[i] and $7F].castClass = spellClass then
                Inc(count);
        usedSlots := count;
        if spells^.slots[spellClass, spellLevel] < count then
          count := spells^.slots[spellClass, spellLevel];
        SpellSlotsRemaining := spells^.slots[spellClass, spellLevel] - count
      end
end;

{ Checks whether the current character can cast, memorize or scribe. The area's anti-magic flag blocks casting; animated
  or disabled characters can do none of them. On failure, prints the character's name and the reason.
  @param(activity The activity: cast, memorize or scribe.)
  @returns(True when the character can do it.) }
function CanDoSpellActivity(activity: Byte): Boolean;
var message: String[40];
begin
  message := '';
  if (activity = 1) and (GDVars.zone0^.antiMagic > 0) then
    message := 'cannot cast spells in this area'
  else if (GDVars.currentCharacter^.status = C_Status.ANIMATED) or
    (GDVars.currentCharacter^.enabled = 0) then begin
    message := 'is in no condition to ';
    case activity of
      1: message := message + 'cast any spells';
      2: message := message + 'memorize spells';
      3: message := message + 'scribe any scrolls'
    end
  end;
  if message = '' then CanDoSpellActivity := True
  else begin
    CanDoSpellActivity := False;
    CharHlp.PrintCreatureMessage(GDVars.currentCharacter, message, 10, True)
  end
end;

procedure NoncombatCastMenu;
var menuIndex: Integer;
    notEmpty: Boolean;
    needsRedraw: Boolean;
    castSelected: Boolean;
    spellId: Byte;
    castSelectedByte: Byte absolute castSelected;
begin
  needsRedraw := False;
  menuIndex := -1;
  GDVars.spellTargetState.noncombatTarget := nil;
  GDVars.selectedChoice := 1;
  if Camp.CanDoSpellActivity(1) then begin
    repeat
      spellId := ViewChar.SpellMenu(0, 1, menuIndex, notEmpty);
      if spellId <> 0 then begin
        needsRedraw := True;
        Border.ClearBox(1, 17, 38, 22);
        Magic.CastSpell(spellId, 0, 1, castSelectedByte)
      end else if notEmpty then needsRedraw := True
      else CharHlp.PrintCreatureMessage(GDVars.currentCharacter, 'has no spells memorized', 10, True)
    until spellId = 0
  end;
  if needsRedraw then CharHlp.DisplayNoncombatInterface
end;

{ Shows the current character's free spell slots in the message area, a row per spell type it can use and a column per
  level, and a magic-user's bonus slots from its robe's moon (one at phase 1, two at phase 2, less the slots already
  used beyond the normal count), which are left in bonusSpellSlots.
  @returns(True if the character has any slots or bonus to show.) }
function DisplaySpellSlots: Boolean;
var labelText: String[40];
    slotText: array[1..8, 0..3] of Types.TString2;
    available: array[0..3] of Byte;
    spellType: ShortInt;
    level: ShortInt;
    column: Byte;
    row: Byte;
    specialLeft: Byte;
    any: Boolean;
    mageSlots: Byte;
    mageUsed: Byte;
    scratch: Byte;
begin
  if GDVars.currentCharacter^.spells <> nil then begin
    GDVars.bonusSpellSlots := 0;
    any := False;
    for spellType := 0 to 3 do begin
      available[spellType] := 0;
      if spellType = 2 then begin
        if (GDVars.currentCharacter^.classLevels[C_Class.CLERIC] > 0) and
            (GDVars.currentCharacter^.deity <> 6) then begin
          available[2] := 1;
          any := True
        end;
        for level := 2 to 8 do slotText[level, 2] := ' ';
        specialLeft := Camp.SpellSlotsRemaining(0, 2, scratch);
        if (specialLeft > 0) or any then slotText[1, 2] := CharHlp.ByteToString(specialLeft)
        else slotText[1, 2] := ' '
      end else
        for level := 1 to 8 do begin
          slotText[level, spellType] := CharHlp.ByteToString(Camp.SpellSlotsRemaining(level, spellType, scratch));
          if GDVars.currentCharacter^.spells^.slots[spellType, level] = 0 then
            slotText[level, spellType] := ' '
          else begin
            available[spellType] := 1;
            any := True
          end
        end
    end;
    if (GDVars.currentCharacter^.classLevels[C_Class.MAGE] > 0) and
        (GDVars.currentCharacter^.robeOrder > 0) then begin
      case GDVars.zone0^.moonPhase[GDVars.currentCharacter^.robeOrder + $4CF8] of
        1: GDVars.bonusSpellSlots := 1;
        2: GDVars.bonusSpellSlots := 2
      else
        GDVars.bonusSpellSlots := 0
      end;
      if GDVars.bonusSpellSlots > 0 then
        for level := 1 to 8 do begin
          mageSlots := GDVars.currentCharacter^.spells^.slots[3, level];
          scratch := Camp.SpellSlotsRemaining(level, 3, mageUsed);
          if mageSlots < mageUsed then begin
            if mageUsed - mageSlots > GDVars.bonusSpellSlots then GDVars.bonusSpellSlots := 0
            else Dec(GDVars.bonusSpellSlots, mageUsed - mageSlots)
          end
        end;
      if GDVars.bonusSpellSlots > 0 then any := True
    end;
    if any then begin
      Border.ClearBox(1, 18, 38, 21);
      row := 1;
      for spellType := 0 to 3 do
        if available[spellType] <> 0 then begin
          case spellType of
            0: labelText := '    Cleric :';
            1: labelText := '     Druid :';
            2: labelText := '   Special :';
            3: labelText := 'Magic-User :'
          end;
          TextRend.DisplayString(1, row + 17, LightGreen, Black, labelText);
          column := 13;
          for level := 1 to 8 do begin
            TextRend.DisplayString(column + 1, row + 17, LightGreen, Black, slotText[level, spellType]);
            Inc(column, 3)
          end;
          Inc(row)
        end;
      if GDVars.bonusSpellSlots > 0 then begin
        TextRend.DisplayString(1, row + 17, LightGreen, Black, 'Bonus      :');
        TextRend.DisplayString(14, row + 17, LightGreen, Black, CharHlp.ByteToString(GDVars.bonusSpellSlots))
      end
    end;
    DisplaySpellSlots := any
  end
end;

{ Rests the party for the longest spell preparation time among its members, then clears the rest clock.
  @param(interrupted Set when the rest is interrupted.) }
procedure RestForSpellPrep(var interrupted: Boolean);
var character: Types.PCharacter;
    maxPrepMinutes: Word;
    prepMinutes: Word;
    { Unused in this version; see the other implementations of this routine. }
    hours: Word;
begin
  maxPrepMinutes := 0;
  character := GDVars.partyHead;
  while character <> nil do begin
    prepMinutes := Camp.CampSpellPrepTime(character);
    if maxPrepMinutes < prepMinutes then maxPrepMinutes := prepMinutes;
    character := character^.next
  end;
  GDVars.restTime[3] := maxPrepMinutes div 60;
  GDVars.restTime[2] := (maxPrepMinutes - 60 * GDVars.restTime[3]) div 10;
  GDVars.restTime[1] := maxPrepMinutes mod 10;
  interrupted := GameTime.CampRest(True);
  FillChar(GDVars.restTime, SizeOf(GDVars.restTime), 0);
  CharHlp.PrintMiscInfo
end;

{ Sorts the current character's memorized spells by id. }
procedure SortMemorizedSpells;
var
  i: Byte;
  j: Byte;
  temp: Byte;
begin
  if GDVars.currentCharacter^.spells <> nil then
    for i := 0 to 72 do
      for j := i to 73 do
        if (GDVars.currentCharacter^.spells^.memorized[i] and $7F) >
            (GDVars.currentCharacter^.spells^.memorized[j] and $7F) then begin
          temp := GDVars.currentCharacter^.spells^.memorized[i];
          GDVars.currentCharacter^.spells^.memorized[i] := GDVars.currentCharacter^.spells^.memorized[j];
          GDVars.currentCharacter^.spells^.memorized[j] := temp
        end
end;

{ Memorize: after offering to keep or clear the pending spells, adds spells from the list while slots (or the moon
  bonus) allow, each pending until rest. }
procedure CampMemorizeMenu;
var
  done: Boolean;
  notEmpty: Boolean;
  redraw: Boolean;
  spellId: Byte;
  i: Byte;
  index: Integer;
  used: Byte;
begin
  if (GDVars.currentCharacter^.spells <> nil) and Camp.CanDoSpellActivity(2) then begin
    done := False;
    index := -1;
    GDVars.selectedChoice := 1;
    spellId := ViewChar.SpellMenu(5, 5, index, notEmpty);
    redraw := True;
    if notEmpty then begin
      if spellId = 0 then Camp.ResetMemorize(GDVars.currentCharacter)
      else done := True
    end else redraw := False;
    index := -1;
    while done = False do begin
      done := Camp.DisplaySpellSlots = False;
      if done then
        CharHlp.PrintCreatureMessage(GDVars.currentCharacter, 'cannot memorize any spells', 10, True)
      else begin
        spellId := ViewChar.SpellMenu(1, 2, index, notEmpty);
        redraw := True;
        if spellId = 0 then done := True
        else if (Camp.SpellSlotsRemaining(GDConsts.spellTable[spellId].level,
                                          GDConsts.spellTable[spellId].castClass, used) > 0) or
          ((GDConsts.spellTable[spellId].castClass = 3) and (GDVars.bonusSpellSlots > 0)) then begin
          if GDConsts.spellTable[spellId].castClass = 2 then GDVars.specialSpellSelection := 1
          else GDVars.specialSpellSelection := 0;
          i := 0;
          while GDVars.currentCharacter^.spells^.memorized[i] <> 0 do Inc(i);
          GDVars.currentCharacter^.spells^.memorized[i] := spellId + $80;
          Camp.SortMemorizedSpells
        end
      end
    end;
    if index <> -1 then begin
      index := -1;
      spellId := ViewChar.SpellMenu(5, 5, index, notEmpty);
      if notEmpty and (spellId = 0) then Camp.ResetMemorize(GDVars.currentCharacter)
    end;
    if redraw then CharHlp.DisplayNoncombatInterface
  end else if GDVars.currentCharacter^.spells = nil then
    CharHlp.PrintCreatureMessage(GDVars.currentCharacter, 'cannot memorize any spells', 10, True)
end;

{ Runs the Scribe menu. The spells already pending are shown first: Yes keeps them and skips the choosing, No clears
  them. Then scroll spells are chosen and marked pending, refusing a spell already known or pending or beyond the
  character's slots, and when the scrolls were shown the pending spells are confirmed again. Note: the marking does not
  check that the item is readable; it marks the first unmarked spell byte equal to the spell on any item. Note: the
  spell's class and level index the slot table unchecked, so a spell an item alone provides can read past it. }
procedure CampScribeMenu;
var
  done: Boolean;
  notEmpty: Boolean;
  redraw: Boolean;
  spellId: Byte;
  { Unused in this version; see the other implementations of this routine. }
  spellClass: Byte;
  i: Byte;
  index: Integer;
  item: Types.PItem;
  found: Boolean;
begin
  if Camp.CanDoSpellActivity(3) then begin
    done := False;
    index := -1;
    spellId := ViewChar.SpellMenu(6, 0, index, notEmpty);
    redraw := True;
    if notEmpty then begin
      if Char(MenuCore.YesNoMenu(GDConsts.scribeConfirmPrompt, GDConsts.yesKey)) =
          Chr(GDConsts.noKey) then Camp.ResetScribe(GDVars.currentCharacter)
      else done := True
    end else redraw := False;
    index := -1;
    while done = False do begin
      spellId := ViewChar.SpellMenu(3, 3, index, notEmpty);
      if spellId = 0 then begin
        done := True;
        if notEmpty = False then
          CharHlp.PrintCreatureMessage(GDVars.currentCharacter, 'has no copyable scrolls', 10, True)
        else redraw := True
      end else begin
        redraw := True;
        if GDVars.currentCharacter^.spells^.known[spellId] <> 0 then
          CharHlp.PrintBottomLine('You already know that spell')
        else begin
          item := GDVars.currentCharacter^.items;
          found := False;
          while (item <> nil) and (found = False) do begin
            if Magic.ItemReadable(item) then
              for i := 1 to 3 do
                if (item^.scrollSpells[i] > $7F) and ((item^.scrollSpells[i] and $7F) = spellId) then begin
                  CharHlp.PrintBottomLine('You are already scribing that spell');
                  found := True
                end;
            item := item^.next
          end;
          if found = False then begin
            if GDVars.currentCharacter^.spells^.
                 slots[GDConsts.spellTable[spellId].castClass, GDConsts.spellTable[spellId].level] > 0 then begin
              item := GDVars.currentCharacter^.items;
              while (item <> nil) and (found = False) do begin
                i := 1;
                repeat
                  if item^.scrollSpells[i] = spellId then begin
                    item^.scrollSpells[i] := item^.scrollSpells[i] or $80;
                    found := True
                  end;
                  Inc(i)
                until (i > 3) or found;
                item := item^.next
              end
            end else CharHlp.PrintBottomLine('You can not scribe that spell.')
          end
        end
      end
    end;
    if index <> -1 then begin
      index := -1;
      spellId := ViewChar.SpellMenu(6, 0, index, notEmpty);
      if notEmpty then
        if Char(MenuCore.YesNoMenu(GDConsts.scribeConfirmPrompt, GDConsts.yesKey)) = Chr(GDConsts.noKey) then
          Camp.ResetScribe(GDVars.currentCharacter)
    end;
    if redraw then CharHlp.DisplayNoncombatInterface
  end
end;

{ Lists the spell effects on each party member under the member's name. Spell effects show the name of the first spell
  (1..56) producing them, or 'Funky--<id>' when none does; other visible effects have fixed labels, and the rest are
  hidden. A member with none shows '<No Spell Effects>'. Note: the labels for effects 61, 68, 69, 71 and 72 describe
  other effects than those ids carry, which are feeblemindedness, a two-level drain, a paralyzing touch, spell
  reflection and frightening adjacent foes. }
procedure CampDisplayMenu;
var effect: Types.PEffect;
    listHead: Types.PMenuRow;
    listTail: Types.PMenuRow;
    character: Types.PCharacter;
    effectId: Byte;
    spellIndex: Byte;
    effectCount: Byte;
    { Unused in this version; see the other implementations of this routine. }
    isHeading: Byte;
    effectNameFound: Boolean;
    displayEffect: Boolean;
    viewNeedsRedraw: Byte;
    effectName: Types.TString40;
    menuIndex: Integer;
    { Unused in this version; see the other implementations of this routine. }
    choice: Char;

  { Appends a row to the effect list. }
  procedure AddToList(isTitle: Boolean; displayText: Types.TString40);
  begin
    GetMem(listTail^.next, SizeOf(Types.TMenuRow));
    listTail := listTail^.next;
    listTail^.next := nil;
    listTail^.name := displayText;
    listTail^.heading := Ord(isTitle)
  end;
begin
  GetMem(listHead, SizeOf(Types.TMenuRow));
  listTail := listHead;
  listTail^.heading := 1;
  listTail^.name := ' ';
  listTail^.next := nil;
  character := GDVars.partyHead;
  while character <> nil do begin
    effectCount := 0;
    AddToList(True, character^.name);
    effect := character^.effects;
    while effect <> nil do begin
      displayEffect := True;
      effectId := effect^.effectId;
      case effectId of
        1, 5, 8, 10..12, 14, 16, 17, 19..25, 28, 29, 32..34, 36..39,
        41, 42, 45, 46, 49, 51..53:
          begin
            spellIndex := 1;
            effectNameFound := False;
            while (spellIndex <= 56) and (effectNameFound = False) do
              if GDConsts.spellTable[spellIndex].effectId = effectId then begin
                effectName := GDConsts.spellNames[spellIndex];
                effectNameFound := True
              end else Inc(spellIndex);
            if effectNameFound = False then effectName := 'Funky--' + CharHlp.ByteToString(effectId)
          end;
        2: effectName := 'olin''s quaterstaff';
        4: effectName := 'Dispel Evil';
        9: effectName := 'Boots Of Speed';
        27: effectName := 'Fumbling';
        31: effectName := 'Helpless';
        35: effectName := 'Confused';
        44: effectName := 'Cause Disease';
        50: effectName := 'Hot Fire Shield';
        54: effectName := 'Cold Fire Shield';
        55: effectName := 'Poisoned';
        59: effectName := 'Globe Of Invulnerability';
        60: effectName := 'iron skin';
        61: effectName := 'Fire Resistance';
        63: effectName := 'Minor Globe of Invulnerability';
        68: effectName := 'enfeebled';
        69: effectName := 'invisible to animals';
        71: effectName := 'Invisible';
        72: effectName := 'Camouflaged';
        73: effectName := 'protected from dragon breath';
        74: effectName := 'fire touch';
        77: effectName := 'berserk';
        89: effectName := 'Displaced'
      else
        displayEffect := False
      end;
      if displayEffect then begin
        Inc(effectCount);
        AddToList(False, ' ' + effectName)
      end;
      effect := effect^.next
    end;
    if effectCount = 0 then AddToList(False, ' <No Spell Effects>');
    AddToList(True, ' ');
    character := character^.next
  end;
  viewNeedsRedraw := 1;
  menuIndex := 0;
  Border.DrawWindowFrame(0);
  MenuCore.EnableChoices(0);
  choice := Char(MenuCore.MenuVertical(GDConsts.emptyQuery, GDConsts.emptyMenu, 1, 4, 38, 22, listHead, 1, -1,
                                       viewNeedsRedraw, menuIndex,
                                       Pointer(listTail)));
  MenuCore.FreeMenuRows(listHead);
  CharHlp.DisplayNoncombatInterface
end;

{ Magic: Cast, Memorize, Scribe, Display and Rest, until Exit or an interruption.
  @param(interrupted Set when a rest is interrupted, which also ends the menu.) }
procedure CampMagicMenu(var interrupted: Boolean);
var selected: Char;
    savedChoice: Byte;
begin
  selected := Chr(255);
  savedChoice := 1;
  while (interrupted = False) and (Ord(selected) <> 5) and
      ((GDVars.menuExtendedKey = 0) or (selected <> C_Keys.ESCAPE)) do begin
    FillChar(GDVars.enabledChoices, SizeOf(GDVars.enabledChoices), $FF);
    MenuCore.EnableChoices(5);
    GDVars.selectedChoice := savedChoice;
    selected := Char(MenuCore.MenuHorizontal('', GDConsts.magicMenu, 1, 1));
    savedChoice := GDVars.selectedChoice;
    if (GDVars.menuExtendedKey <> 0) then begin
      CharHlp.DisplayRoster(GDVars.currentCharacter, False);
      ViewChar.SelectAdjacentCharacter(selected);
      CharHlp.DisplayRoster(GDVars.currentCharacter, True)
    end else
      case Ord(selected) of
        0: Camp.NoncombatCastMenu;
        1: Camp.CampMemorizeMenu;
        2: Camp.CampScribeMenu;
        3: Camp.CampDisplayMenu;
        4: Camp.RestForSpellPrep(interrupted)
      end
  end
end;

{ Moves the current character one place earlier in the party; the first character moves to the end. }
procedure OrderMoveUp;
var
  previous: Types.PCharacter;
  character: Types.PCharacter;
  temp: Types.PCharacter;
begin
  character := GDVars.partyHead;
  previous := nil;
  if character = GDVars.currentCharacter then begin
    while character^.next <> nil do character := character^.next
  end else
    while character^.next <> GDVars.currentCharacter do begin
      previous := character;
      character := character^.next
    end;
  temp := GDVars.currentCharacter^.next;
  if GDVars.partyHead = GDVars.currentCharacter then begin
    if temp <> nil then GDVars.partyHead := temp;
    character^.next := GDVars.currentCharacter;
    GDVars.currentCharacter^.next := nil
  end else begin
    character^.next := temp;
    GDVars.currentCharacter^.next := character;
    if (character = GDVars.partyHead) or (previous = nil) then
      GDVars.partyHead := GDVars.currentCharacter
    else
      previous^.next := GDVars.currentCharacter
  end
end;

{ Moves the current character one place later in the party; the last character moves to the front. }
procedure OrderMoveDown;
var
  predecessor: Types.PCharacter;
  successor: Types.PCharacter;
begin
  predecessor := GDVars.partyHead;
  if predecessor <> GDVars.currentCharacter then
    while predecessor^.next <> GDVars.currentCharacter do
      predecessor := predecessor^.next;
  successor := GDVars.currentCharacter^.next;
  if successor = nil then begin
    GDVars.currentCharacter^.next := GDVars.partyHead;
    GDVars.partyHead := GDVars.currentCharacter;
    predecessor^.next := successor
  end else begin
    GDVars.currentCharacter^.next := successor^.next;
    if GDVars.partyHead = GDVars.currentCharacter then
      GDVars.partyHead := successor;
    if predecessor <> GDVars.currentCharacter then predecessor^.next := successor;
    successor^.next := GDVars.currentCharacter
  end
end;

{ Runs the party-order menu: in Select mode extended keys change the current character; choosing Select picks it
  (announcing it) and switches to Place mode, where the up and down arrows move it up or down the order, and choosing
  Place switches back. Ends on Exit or Escape. }
procedure PartyOrderMenu;
var selected: Byte;
    key: Char;
    choice: Char;
    savedChoice: Byte;
begin
  selected := 0;
  choice := Chr(255);
  savedChoice := 1;
  while (Ord(choice) <> 2) and ((GDVars.menuExtendedKey = 0) or (choice <> C_Keys.ESCAPE)) do begin
    FillChar(GDVars.enabledChoices, SizeOf(GDVars.enabledChoices), $FF);
    if selected <> 0 then GDVars.enabledChoices[0].ordinal := 1
    else GDVars.enabledChoices[0].ordinal := 0;
    GDVars.enabledChoices[1].ordinal := 2;
    GDVars.selectedChoice := savedChoice;
    choice := Char(MenuCore.MenuHorizontal(GDConsts.orderQuery, GDConsts.orderMenu, 1, 1));
    savedChoice := GDVars.selectedChoice;
    if (GDVars.menuExtendedKey <> 0) then begin
      if selected = 0 then begin
        CharHlp.DisplayRoster(GDVars.currentCharacter, False);
        ViewChar.SelectAdjacentCharacter(choice);
        CharHlp.DisplayRoster(GDVars.currentCharacter, True)
      end else begin
        key := choice;
        case key of
          C_Keys.UP: Camp.OrderMoveUp;
          C_Keys.DOWN: Camp.OrderMoveDown
        end;
        CharHlp.DisplayParty(GDVars.currentCharacter)
      end
    end else if (Ord(choice) < 2) or ((GDVars.menuExtendedKey <> 0) and (choice = C_Keys.ESCAPE)) then begin
      selected := Ord(selected = 0);
      if selected <> 0 then
        CharHlp.PrintCreatureMessage(GDVars.currentCharacter, GDConsts.hasBeenSelected, 10, False)
      else CharHlp.ClearMessageWindow
    end
  end;
  GDVars.selectionMode := 0
end;

{ Drops the current character from the party after confirmation, with a farewell that depends on whether it is enabled,
  and redraws the party. For the last party member it offers to quit to DOS instead. }
procedure CampDropMenu;
begin
  if (GDVars.currentCharacter^.next = nil) and (GDVars.currentCharacter = GDVars.partyHead) then begin
    if Char(MenuCore.YesNoMenu(GDConsts.quitToDosPrompt, GDConsts.noKey)) = Chr(GDConsts.yesKey) then begin
      CharGen.RemoveCreature(False, True);
      GameIo.ExitGame
    end else Exit;
    Exit
  end;
  CharHlp.PrintCreatureMessage(GDVars.currentCharacter, GDConsts.goneForever, 10, False);
  if Char(MenuCore.YesNoMenu('Drop from party? ', GDConsts.noKey)) = Chr(GDConsts.yesKey) then begin
    if GDVars.currentCharacter^.enabled <> 0 then
      CharHlp.PrintCreatureMessage(GDVars.currentCharacter, 'bids you farewell', 10, True)
    else
      CharHlp.PrintCreatureMessage(GDVars.currentCharacter, 'is dumped in a ditch', 10, True);
    CharGen.RemoveCreature(False, True);
    Border.ClearBox(17, 1, 38, 11);
    CharHlp.DisplayParty(GDVars.currentCharacter)
  end else
    CharHlp.PrintCreatureMessage(GDVars.currentCharacter, 'Breathes A sigh of relief', 10, True)
end;

{ Shows the level menu with the current difficulty preselected and stores the level picked as 1..5; extended keys change
  the current character instead. }
procedure CampDifficultyMenu;
var
  choice: Byte;
  difficulty: Byte;
begin
  difficulty := GDVars.zone0^.difficulty;
  GDVars.menuResetByte := 255;
  GDVars.selectedChoice := difficulty;
  MenuCore.EnableChoices(4);
  choice := MenuCore.MenuHorizontal(GDConsts.emptyQuery, GDConsts.levelMenu, 0, 1);
  if (GDVars.menuExtendedKey <> 0) then begin
    CharHlp.DisplayRoster(GDVars.currentCharacter, False);
    ViewChar.SelectAdjacentCharacter(Chr(choice));
    CharHlp.DisplayRoster(GDVars.currentCharacter, True)
  end else if choice < 5 then difficulty := choice + 1;
  GDVars.zone0^.difficulty := difficulty
end;

{ Runs the speed menu: shows the game delay, 0 fastest to 9 slowest, and steps it with Faster, Slower or the arrow keys;
  Escape or Exit ends it. }
procedure CampSpeedMenu;
var
  slotCount: Byte;
  choice: Byte;
  savedChoice: Byte;
begin
  savedChoice := 1;
  repeat
    TextRend.DisplayString(1, 18, LightGreen, Black,
                           GDConsts.gameSpeedPrompt + CharHlp.ByteToString(GDVars.textDelay));
    FillChar(GDVars.enabledChoices, SizeOf(GDVars.enabledChoices), $FF);
    slotCount := 0;
    if GDVars.textDelay > 0 then MenuCore.AppendChoice(0, slotCount);
    if GDVars.textDelay < 9 then MenuCore.AppendChoice(1, slotCount);
    MenuCore.AppendChoice(2, slotCount);
    GDVars.selectedChoice := savedChoice;
    choice := MenuCore.MenuHorizontal(GDConsts.gameSpeedLabel, GDConsts.speedChoices, 1, 1);
    savedChoice := GDVars.selectedChoice;
    if (GDVars.menuExtendedKey <> 0) then begin
      case choice of
        Ord(C_Keys.DOWN): if GDVars.textDelay > 0 then Dec(GDVars.textDelay);
        Ord(C_Keys.UP): if GDVars.textDelay < 9 then Inc(GDVars.textDelay);
        Ord(C_Keys.ESCAPE): choice := 2
      end
    end else
      case choice of
        0: Dec(GDVars.textDelay);
        1: Inc(GDVars.textDelay)
      end
  until choice = 2;
  CharHlp.ClearMessageWindow
end;

{ Alter: Order, Drop, Speed, Icon and Level, until Exit. }
procedure CampAlterMenu;
var
  choice: Byte;
  { Unused in this version; see the other implementations of this routine. }
  toggleChoice: Byte;
  { Unused in this version; see the other implementations of this routine. }
  savedChoice: Byte;
begin
  choice := 255;
  savedChoice := 1;
  while choice <> 5 do begin
    MenuCore.EnableChoices(5);
    GDVars.selectedChoice := 1;
    choice := MenuCore.MenuHorizontal('', GDConsts.alterMenu, 0, 1);
    savedChoice := GDVars.selectedChoice;
    if (GDVars.menuExtendedKey <> 0) then begin
      if choice = Ord(C_Keys.ESCAPE) then choice := 5
      else begin
        CharHlp.DisplayRoster(GDVars.currentCharacter, False);
        ViewChar.SelectAdjacentCharacter(Chr(choice));
        CharHlp.DisplayRoster(GDVars.currentCharacter, True)
      end
    end else
      case choice of
        0: Camp.PartyOrderMenu;
        1: Camp.CampDropMenu;
        2: Camp.CampSpeedMenu;
        3: begin
            CharGen.CustomizeIcon;
            CharHlp.DisplayNoncombatInterface
          end;
        4: Camp.CampDifficultyMenu
      end
  end
end;

const
  HEALED_MESSAGE = 'is healed';
  FLESH_MESSAGE = 'is changed back to flesh';
  DETOXIFIED_MESSAGE = 'is detoxified';
  RAISED_MESSAGE = 'has been raised from the dead';
  CURSE_MESSAGE = 'is relieved of a curse';
  SIGHT_MESSAGE = 'regains sight';

{ Fix: when the party has hit points missing, rolls what its members' memorized cures will heal, rests the time they
  take, and if not interrupted heals the party and applies the other memorized cures (raise dead, remove curse, cure
  blindness, heal, neutralize poison, stone to flesh), resting again for those. Note: cure blindness clears the current
  character's blindness rather than the blind member's, and never uses up a cure.
  @param(interrupted Set when either rest is interrupted.) }
procedure CampFixMenu(var interrupted: Boolean);
var healPool: Word;
    { the cure slots, by cleric spell level 1, 4, 5 and 6 }
    cureLightSlots: Word;
    cureSeriousSlots: Word;
    cureCriticalSlots: Word;
    healSlots: Word;
    raiseDeadCount: Word;
    resurrectionCount: Word;
    removeCurseCount: Word;
    cursedCount: Word;
    cureBlindnessCount: Word;
    blindCount: Word;
    { Heal lifts feeblemindedness, which Magic.SpellHeal reports as regaining intellect }
    healCount: Word;
    feeblemindedCount: Word;
    neutralizePoisonCount: Word;
    poisonedCount: Word;
    stoneToFleshCount: Word;
    petrifiedCount: Word;
    savedRestTime: Types.TClock;

  { Whether a character can cast: okay and with spells. }
  function CanCast(character: Types.PCharacter): Boolean;
  begin
    CanCast := (character^.status = C_Status.OKAY) and (character^.spells <> nil)
  end;

  { Rolls the healing of the party's memorized cure spells into healPool and counts its other memorized cures. }
  procedure RollMemorizedCures;
  var rolledHealing: Word;
      spellIndex: Byte;
      character: Types.PCharacter;
  begin
    rolledHealing := 0;
    character := GDVars.partyHead;
    while character <> nil do begin
      if CanCast(character) then begin
        for spellIndex := 0 to 73 do
          case character^.spells^.memorized[spellIndex] of
            3, 58: Inc(rolledHealing, FxEngine.RollDice(2, 8) + 1);
            71: Inc(rolledHealing, FxEngine.RollDice(3, 8) + 3);
            53: begin
                 Inc(rolledHealing, FxEngine.RollDice(4, 8) + 5);
                 Inc(healCount)
               end;
            67: Inc(neutralizePoisonCount);
            75: Inc(raiseDeadCount);
            43, 89: Inc(removeCurseCount);
            66: Inc(stoneToFleshCount);
            37: Inc(cureBlindnessCount)
          end
      end;
      character := character^.next
    end;
    Inc(healPool, rolledHealing)
  end;

  { Adds a cure roll for each counted cure slot to the healing pool. }
  procedure RollCureSlots;
  var rolledHealing: Word;
      rollIndex: Byte;
  begin
    rolledHealing := 0;
    for rollIndex := 1 to Lo(cureLightSlots) do
      Inc(rolledHealing, FxEngine.RollDice(1, 8));
    for rollIndex := 1 to Lo(cureSeriousSlots) do
      Inc(rolledHealing, FxEngine.RollDice(2, 8) + 1);
    for rollIndex := 1 to Lo(cureCriticalSlots) do
      Inc(rolledHealing, FxEngine.RollDice(3, 8) + 3);
    for rollIndex := 1 to Lo(healSlots) do
      Inc(rolledHealing, FxEngine.RollDice(4, 8) + 3);
    Inc(healPool, rolledHealing)
  end;

  { Returns the party's total missing hit points. }
  function PartyHitPointsMissing: Word;
  var totalDamage: Word;
      character: Types.PCharacter;
  begin
    totalDamage := 0;
    character := GDVars.partyHead;
    while character <> nil do begin
      Inc(totalDamage, character^.maxHitPoints - character^.hitPoints);
      character := character^.next
    end;
    PartyHitPointsMissing := totalDamage
  end;

  { Sets the rest clock to the cure slots' time, cut when less is needed. Note: score starts undefined. }
  procedure ComputeFixTime;
  var score: Word;
      character: Types.PCharacter;
      maximum: Word;
      clericLightMinutes: Word;
      druidLightMinutes: Word;
      seriousMinutes: Word;
      criticalMinutes: Word;
      healMinutes: Word;
      characterMinutes: Word;
      slotCount: Word;
      divisor: Byte;
  begin
    character := GDVars.partyHead;
    clericLightMinutes := 0;
    druidLightMinutes := 0;
    seriousMinutes := 0;
    criticalMinutes := 0;
    healMinutes := 0;
    cureLightSlots := 0;
    cureSeriousSlots := 0;
    cureCriticalSlots := 0;
    healSlots := 0;
    maximum := 0;
    while character <> nil do begin
      characterMinutes := 0;
      if CanCast(character) and (character^.stats[C_Stat.WISDOM].current > 3) then begin
        slotCount := character^.spells^.slots[0, 1];
        Inc(cureLightSlots, slotCount);
        clericLightMinutes := 15 * slotCount;
        slotCount := character^.spells^.slots[1, 2];
        Inc(cureLightSlots, slotCount);
        druidLightMinutes := 30 * slotCount;
        Inc(cureSeriousSlots, character^.spells^.slots[0, 4]);
        seriousMinutes := 60 * character^.spells^.slots[0, 4];
        Inc(cureCriticalSlots, character^.spells^.slots[0, 5]);
        criticalMinutes := 75 * character^.spells^.slots[0, 5];
        Inc(healSlots, character^.spells^.slots[0, 6]);
        healMinutes := 90 * character^.spells^.slots[0, 6]
      end;
      if clericLightMinutes > 0 then begin
        characterMinutes := 240;
        Inc(score, 27)
      end;
      if druidLightMinutes > 0 then begin
        characterMinutes := 240;
        Inc(score, 27)
      end;
      if seriousMinutes + criticalMinutes > 0 then begin
        characterMinutes := 360;
        if criticalMinutes > 0 then Inc(score, 78)
        else Inc(score, 34)
      end;
      if healMinutes > 0 then begin
        characterMinutes := 480;
        Inc(score, 90)
      end;
      Inc(characterMinutes, clericLightMinutes + druidLightMinutes + seriousMinutes + criticalMinutes + healMinutes);
      if maximum < characterMinutes then maximum := characterMinutes;
      character := character^.next
    end;
    if PartyHitPointsMissing < score then begin
      divisor := score div PartyHitPointsMissing;
      maximum := maximum div divisor
    end;
    GDVars.restTime[3] := maximum div 60;
    GDVars.restTime[2] := (maximum - 60 * GDVars.restTime[3]) div 10;
    GDVars.restTime[1] := maximum mod 10
  end;

  { Counts the casters' slots for the other cures and sets the rest clock to the time the cures needed take. }
  procedure ComputeCureTime;
  var character: Types.PCharacter;
      cureMinutes: Word;
      { Unused in this version; see the other implementations of this routine. }
      hours: Word;
  begin
    character := GDVars.partyHead;
    while character <> nil do begin
      if CanCast(character) then begin
        Inc(healCount, character^.spells^.slots[0, 6]);
        Inc(stoneToFleshCount, character^.spells^.slots[3, 6]);
        Inc(raiseDeadCount, character^.spells^.slots[0, 5]);
        Inc(neutralizePoisonCount, character^.spells^.slots[0, 4]);
        Inc(removeCurseCount, character^.spells^.slots[3, 4]);
        Inc(removeCurseCount, character^.spells^.slots[0, 3]);
        Inc(cureBlindnessCount, character^.spells^.slots[0, 3])
      end;
      character := character^.next
    end;
    cureMinutes := 0;
    cureMinutes := cureMinutes + Camp.Smaller(healCount, feeblemindedCount) * 90;
    cureMinutes := cureMinutes + Camp.Smaller(stoneToFleshCount, petrifiedCount) * 90;
    cureMinutes := cureMinutes + Camp.Smaller(raiseDeadCount, resurrectionCount) * 75;
    cureMinutes := cureMinutes + Camp.Smaller(neutralizePoisonCount, poisonedCount) * 60;
    cureMinutes := cureMinutes + Camp.Smaller(cureBlindnessCount, blindCount) * 45;
    cureMinutes := cureMinutes + Camp.Smaller(removeCurseCount, cursedCount) * 45;
    GDVars.restTime[3] := cureMinutes div 60;
    GDVars.restTime[2] := (cureMinutes - 60 * GDVars.restTime[3]) div 10;
    GDVars.restTime[1] := cureMinutes mod 10
  end;

  { Spends the healing pool on each member in party order, up to that member's missing hit points. }
  procedure HealParty;
  var character: Types.PCharacter;
      healingNeeded: Word;
  begin
    character := GDVars.partyHead;
    while character <> nil do begin
      if character^.maxHitPoints > character^.hitPoints then begin
        healingNeeded := character^.maxHitPoints - character^.hitPoints;
        if healingNeeded > healPool then healingNeeded := healPool;
        if healingNeeded < 1 then healingNeeded := 0;
        if healingNeeded > 0 then
          if FxEngine.RestoreHitPoints(character, healingNeeded, False) then
            if healingNeeded <= healPool then Dec(healPool, healingNeeded)
      end;
      character := character^.next
    end
  end;

  { Applies the counted cures to each member: heal, flesh, poison, raise dead, curse and sight. }
  procedure CureStatusEffects;
  var character: Types.PCharacter;
      effect: Types.PEffect;
      { Unused in this version; see the other implementations of this routine. }
      diseaseIndex: Byte;
      wasHealed: Boolean;
      bonusHitPoints: Byte;
      bonusDivisor: Byte;
      classIndex: ShortInt;
  begin
    character := GDVars.partyHead;
    while character <> nil do begin
      wasHealed := False;
      if healCount > 0 then
        if CharHlp.HasEffect(Pointer(character), C_Effect.FEEBLEMINDED, effect) then begin
          FxEngine.RemoveEffect(Pointer(character), C_Effect.FEEBLEMINDED, nil);
          if CharHlp.HasEffect(Pointer(character), C_Effect.BLIND, effect) then
            FxEngine.RemoveEffect(Pointer(character), C_Effect.BLIND, nil);
          wasHealed := True;
          CharHlp.PrintCreatureMessage(Pointer(character), Camp.HEALED_MESSAGE, 10, True);
          Dec(healCount)
        end;
      if (stoneToFleshCount > 0) and (character^.status = C_Status.STONED) then begin
        character^.status := C_Status.OKAY;
        character^.enabled := 1;
        character^.hitPoints := 1;
        CharHlp.PrintCreatureMessage(Pointer(character), Camp.FLESH_MESSAGE, 10, True);
        Dec(stoneToFleshCount)
      end;
      if neutralizePoisonCount > 0 then
        if CharHlp.HasEffect(Pointer(character), C_Effect.POISONED, effect) then begin
          if character^.hitPoints = 0 then character^.hitPoints := 1;
          GDVars.effectLock := 1;
          FxEngine.RemoveEffect(Pointer(character), C_Effect.POISONED, nil);
          FxEngine.RemoveEffect(Pointer(character), C_Effect.SLOW_POISON_END, nil);
          FxEngine.RemoveEffect(Pointer(character), C_Effect.SLOW_POISON_HIT, nil);
          GDVars.effectLock := 0;
          character^.enabled := 1;
          character^.status := C_Status.OKAY;
          CharHlp.PrintCreatureMessage(Pointer(character), Camp.DETOXIFIED_MESSAGE, 10, True);
          Dec(neutralizePoisonCount)
        end;
      if (raiseDeadCount > 0) and (character^.status = C_Status.DEAD_STATUS) and
          (character^.race <> C_Race.HALF_ELF) and (character^.race > C_Race.QUALINESTI_ELF) then begin
        GDVars.effectLock := 1;
        FxEngine.RemoveEffect(Pointer(character), C_Effect.POISONED, nil);
        GDVars.effectLock := 0;
        character^.hitPoints := 1;
        character^.status := C_Status.OKAY;
        character^.enabled := 1;
        if character^.stats[C_Stat.CONSTITUTION].current > 0 then Dec(character^.stats[C_Stat.CONSTITUTION].current);
        if character^.maxHitPoints > character^.baseMaxHitPoints then
          bonusHitPoints := character^.maxHitPoints - character^.baseMaxHitPoints
        else bonusHitPoints := 0;
        bonusDivisor := 0;
        if character^.stats[C_Stat.CONSTITUTION].current >= 14 then begin
          for classIndex := 0 to 6 do
            if character^.classLevels[classIndex] > 0 then
              if (classIndex = C_Class.FIGHTER) or (classIndex = C_Class.PALADIN) or
                  (classIndex = C_Class.RANGER) then
                Inc(bonusDivisor,
                    (character^.stats[C_Stat.CONSTITUTION].current - 14) * character^.classLevels[classIndex])
              else if character^.stats[C_Stat.CONSTITUTION].current > 15 then
                Inc(bonusDivisor, character^.classLevels[classIndex] * 2)
              else
                Inc(bonusDivisor, character^.classLevels[classIndex]);
          if bonusDivisor > 0 then bonusHitPoints := bonusHitPoints div bonusDivisor;
          if (character^.stats[C_Stat.CONSTITUTION].current < 17) or (character^.classLevels[C_Class.FIGHTER] > 0) or
              (character^.classLevels[C_Class.KNIGHT] > 0) or
              (character^.classLevels[C_Class.PALADIN] > 0) then
            Dec(character^.maxHitPoints, bonusHitPoints)
        end;
        CharHlp.PrintCreatureMessage(Pointer(character), Camp.RAISED_MESSAGE, 10, True);
        Dec(raiseDeadCount)
      end;
      if removeCurseCount > 0 then
        if CharHlp.HasEffect(Pointer(character), C_Effect.CURSED, effect) then begin
          GDVars.spellTargetState.targets[1] := character;
          Magic.SpellRemoveCurse;
          CharHlp.PrintCreatureMessage(Pointer(character), Camp.CURSE_MESSAGE, 10, True);
          Dec(removeCurseCount)
        end;
      if (not wasHealed) and (cureBlindnessCount > 0) then
        if CharHlp.HasEffect(Pointer(character), C_Effect.BLIND, effect) then begin
          FxEngine.RemoveEffect(Pointer(GDVars.currentCharacter), C_Effect.BLIND, nil);
          CharHlp.PrintCreatureMessage(Pointer(GDVars.currentCharacter), Camp.SIGHT_MESSAGE, 10, True)
        end;
      character := character^.next
    end
  end;

  { Counts the members needing each cure: dead, stoned, cursed, poisoned, feebleminded and otherwise blind. }
  procedure CountCureNeeds;
  var character: Types.PCharacter;
      effect: Types.PEffect;
  begin
    resurrectionCount := 0;
    cursedCount := 0;
    blindCount := 0;
    feeblemindedCount := 0;
    poisonedCount := 0;
    petrifiedCount := 0;
    character := GDVars.partyHead;
    while character <> nil do begin
      if (character^.status = C_Status.DEAD_STATUS) and
          (character^.race > C_Race.QUALINESTI_ELF) then Inc(resurrectionCount);
      if character^.status = C_Status.STONED then Inc(petrifiedCount);
      if CharHlp.HasEffect(Pointer(character), C_Effect.CURSED, effect) then Inc(cursedCount);
      if CharHlp.HasEffect(Pointer(character), C_Effect.POISONED, effect) then Inc(poisonedCount);
      if CharHlp.HasEffect(Pointer(character), C_Effect.FEEBLEMINDED, effect) then Inc(feeblemindedCount)
      else if CharHlp.HasEffect(Pointer(character), C_Effect.BLIND, effect) then Inc(blindCount);
      character := character^.next
    end
  end;
begin
  if GDVars.zone0^.antiMagic = 0 then begin
    raiseDeadCount := 0;
    removeCurseCount := 0;
    cureBlindnessCount := 0;
    healCount := 0;
    neutralizePoisonCount := 0;
    stoneToFleshCount := 0;
    interrupted := False;
    healPool := 0;
    if PartyHitPointsMissing <> 0 then begin
      RollMemorizedCures;
      savedRestTime := GDVars.restTime;
      ComputeFixTime;
      GDVars.campRestActive := True;
      interrupted := GameTime.CampRest(False);
      GDVars.campRestActive := False;
      if not interrupted then begin
        RollCureSlots;
        CureStatusEffects;
        HealParty;
        CharHlp.DisplayParty(Pointer(GDVars.currentCharacter));
        CharHlp.PrintMiscInfo;
        GDVars.restTime := savedRestTime;
        savedRestTime := GDVars.restTime;
        CountCureNeeds;
        ComputeCureTime;
        GDVars.campRestActive := True;
        interrupted := GameTime.CampRest(False);
        GDVars.campRestActive := False;
        if not interrupted then begin
          CureStatusEffects;
          CharHlp.DisplayParty(Pointer(GDVars.currentCharacter));
          CharHlp.PrintMiscInfo;
          GDVars.restTime := savedRestTime
        end
      end
    end
  end
end;

const
  PICTURE_MARKER = 'PIC';

procedure CampMainMenu(var interrupted: Boolean);
var
  savedMode: Byte;
  choice: Byte;
  key: Char;
  menuDone: Boolean absolute key;
  savedChoice: Byte;
begin
  savedMode := GDVars.interfaceState;
  GDVars.interfaceState := C_Ifc.CAMPING;
  GDVars.healTicks := 0;
  FillChar(GDVars.restTime, SizeOf(GDVars.restTime), 0);
  GDVars.savedPictureName := GDVars.pictureArchiveName;
  GDVars.savedPictureId := GDVars.pictureArchiveId;
  CharHlp.DisplayNoncombatInterface;
  Border.ClearBox(1, 17, 38, 22);
  TextRend.DisplayString(1, 18, LightGreen, Black, GDConsts.partyMakesCamp);
  Camp.ResetPartySpellActivities;
  interrupted := False;
  choice := 255;
  savedChoice := 1;
  while (not interrupted) and (choice <> 6) do begin
    MenuCore.EnableChoices(6);
    GDVars.selectedChoice := savedChoice;
    choice := MenuCore.MenuHorizontal(GDConsts.emptyQuery, GDConsts.campMenu, 1, 1);
    savedChoice := GDVars.selectedChoice;
    if (GDVars.menuExtendedKey <> 0) then begin
      if choice = Ord(C_Keys.ESCAPE) then choice := 6
      else begin
        CharHlp.DisplayRoster(Pointer(GDVars.currentCharacter), False);
        ViewChar.SelectAdjacentCharacter(Chr(choice));
        CharHlp.DisplayRoster(Pointer(GDVars.currentCharacter), True)
      end
    end else
      case choice of
        0: begin
            Inc(GDVars.zone0^.quitCounter);
            if GDVars.zone0^.quitCounter >= 10 then begin
              if Camp.RuleBookCheck = 0 then GameIo.ExitGame;
              CharHlp.DisplayNoncombatInterface;
              GDVars.zone0^.quitCounter := 0
            end;
            SaveLoad.SaveGame;
            if Char(MenuCore.YesNoMenu(GDConsts.quitToDosPrompt,
                                       GDConsts.noKey)) = Chr(GDConsts.yesKey) then GameIo.ExitGame
          end;
        1: ViewChar.ViewCharMenu(menuDone);
        2: Camp.CampMagicMenu(interrupted);
        3: Camp.RestForSpellPrep(interrupted);
        4: Camp.CampAlterMenu;
        5: Camp.CampFixMenu(interrupted)
      end
  end;
  if Copy(GDVars.savedPictureName, 1, 3) = Camp.PICTURE_MARKER then
    Portrait.LoadAnimation(GDVars.savedPictureName, GDVars.savedPictureId, GDConsts.pictureMode,
                           GDVars.portraitAnimation);
  Camp.ResetPartySpellActivities;
  GDVars.spellTargetState.noncombatTarget := nil;
  GDVars.interfaceState := savedMode;
  CharHlp.PrintMiscInfo;
  CharHlp.ClearMessageWindow;
  MenuCore.ClearBottomLine
end;
begin
end.
