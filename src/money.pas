{ Money -- steel, gems and jewelry (coins 4, 5 and 6): carrying them, the pool (pooling, sharing out, taking), trading
  and dropping, appraising gems and jewelry, and the number prompt they use. One coin weighs one unit. }
{$F+,O+,S-,R-,V-,B-,I-}
unit Money;
interface
uses C_Ifc, C_Npc, Crt, C_Keys, GDConsts, GDVars, Types, TextRend, Border, GameIo, FxEngine, MenuCore, CharHlp;

{ Gives the most weight a character can carry: its weight allowance plus 1500.
  @param(character The character.)
  @returns(The capacity.) }
function CarryingCapacity(character: Types.PCharacter): Word;

{ Takes weight off a character's encumbrance.
  @param(character The character.)
  @param(weight The weight removed.) }
procedure RemoveWeight(character: Types.PCharacter; weight: Word);

{ Adds weight to a character's encumbrance.
  @param(character The character.)
  @param(weight The weight added.) }
procedure AddWeight(character: Types.PCharacter; weight: Word);

{ Tells whether more weight would overload a character.
  @param(character Character to test.)
  @param(weight Weight to add.)
  @param(takable Receives what it can still take when it would be overloaded (0 if already over), otherwise 0.)
  @returns(True when the weight would overload it.) }
function CheckOverload(character: Types.PCharacter; weight: Word; var takable: Word): Boolean;

{ Moves the money of each player character, and of each NPC with the value $B3, into the pool, taking its weight off,
  and marks the pool as holding money. }
procedure PoolMoney;

{ Counts the party members and animated creatures (NPC value 0 or $B3).
  @returns(The count.) }
function CountPoolers: Byte;

{ Divides the pool. Each money type's share is the pool divided by CountPoolers, the remainder held back. The first pass
  gives each member with an NPC value below $80, highest money type first, its share and one coin of the remainder while
  they fit, or as much of the share as it can carry, the rest going back to the remainder. The second pass hands what is
  left, type by type, to each member in list order as far as it can carry, and the rest stays in the pool, which is
  marked as holding money when anything stays. Note: the divisor counts animated members ($B3), whom the first pass
  skips, and not NPC values 1 to $7F, whom it pays. }
procedure ShareMoney;

{ Lists the money in the pool and lets the current character take an amount of the chosen type, until the pool is empty
  or the player leaves. Note: leaving the menu without choosing does not free the list it was built from. }
procedure TakeMoneyMenu;

{ Gives the current character steel pieces; what it cannot carry goes into the pool, after a pause and a message saying
  so.
  @param(amount The amount of steel.) }
procedure GiveSteel(amount: Word);

{ Reads a coin type from the first letter of source after spaces: G gems (5), S steel (4), J jewelry (6). Note: any
  other letter leaves the result unset.
  @param(source Text to read, a pool row's name.)
  @param(typeName Receives the coin type's name and a space.)
  @returns(The coin type.) }
function ParseMoneyType(source: String; var typeName: String): ShortInt;

{ Shows a question on the bottom row and reads a number up to the largest accepted: digits are echoed in white, a larger
  number is cut to the largest, and backspace takes off the last digit. Enter or Escape ends the input. Note: backspace
  blanks the column after the last digit, so the digit taken off stays on screen.
  @param(maximum The largest number accepted.)
  @param(query The question shown.)
  @param(color The question's color.)
  @returns(The number, or 0 on Escape.) }
function InputNumberMax(maximum: Word; query: Types.TString40; color: Byte): Word;

{ Moves coins of one type, with their weight, from one character to another when the receiver can carry them; otherwise
  shows "Overloaded", pauses and flushes the keyboard.
  @param(giver The character giving the coins.)
  @param(receiver The character receiving them.)
  @param(amount The amount.)
  @param(moneyType The money type.) }
procedure TradeMoney(var giver, receiver: Types.PCharacter; amount: Word; moneyType: ShortInt);

{ Takes money from a character; in the loot screen, in shops and temples and in the vault it goes into the pool,
  elsewhere it is lost.
  @param(character The character.)
  @param(amount The amount.)
  @param(moneyType The money type.) }
procedure DropMoney(character: Types.PCharacter; amount: Word; moneyType: ShortInt);

{ Tells whether the pool holds coins and whether there are treasure items.
  @param(coins Receives True when the pool holds coins.)
  @param(items Receives True when there are treasure items.) }
procedure DetermineTreasure(var coins, items: Boolean);

{ Appraises the current character's gems and jewelry one at a time: each gets a random value and is sold for its full
  value in steel, or, when the character has room and fewer than 16 items, kept as an item. Note: a kept gem or jewel is
  linked to the end of the item list without counting it or adding its weight, it is lost when the character carries no
  items, and leaving the Sell/Keep menu sells.
  @param(ok Set False when there is nothing to appraise, else True.) }
procedure AppraiseMenu(var ok: Boolean);
implementation
const OVERLOAD_MESSAGE = 'Overloaded.  Money will be put in Pool.';
      TRADE_OVERLOAD_MESSAGE = 'Overloaded';
      NO_GEMS_MESSAGE = 'No Gems or Jewelry';
      GOLD_VALUE_SUFFIX = ' steel.';

function CarryingCapacity(character: Types.PCharacter): Word;
begin
  CarryingCapacity := CharHlp.WeightAllowance(character) + 1500
end;

procedure RemoveWeight(character: Types.PCharacter; weight: Word);
begin
  character^.encumbrance := character^.encumbrance - weight
end;

procedure AddWeight(character: Types.PCharacter; weight: Word);
begin
  character^.encumbrance := character^.encumbrance + weight
end;

function CheckOverload(character: Types.PCharacter; weight: Word; var takable: Word): Boolean;
var capacity: Word;
begin
  capacity := Money.CarryingCapacity(character);
  if character^.encumbrance + weight > capacity then begin
    CheckOverload := True;
    if character^.encumbrance > capacity then
      takable := 0
    else
      takable := capacity - character^.encumbrance
  end else begin
    CheckOverload := False;
    takable := 0
  end
end;

procedure GiveSteel(amount: Word);
var takable: Word;
begin
  if Money.CheckOverload(GDVars.currentCharacter, amount, takable) then begin
    CharHlp.PrintBottomLine(Money.OVERLOAD_MESSAGE);
    TextRend.PauseOnly;
    GameIo.FlushKeys;
    Inc(GDVars.currentCharacter^.coins[4], takable);
    Money.AddWeight(GDVars.currentCharacter, takable);
    GDVars.pooledMoney[4] := amount + GDVars.pooledMoney[4] - takable
  end else begin
    Inc(GDVars.currentCharacter^.coins[4], amount);
    Money.AddWeight(GDVars.currentCharacter, amount)
  end
end;

function InputNumberMax(maximum: Word; query: Types.TString40; color: Byte): Word;
var
  column: Byte;
  { Unused in this version; see the other implementations of this routine. }
  maxLength: Byte;
  queryLength: Byte;
  maxText: String[5];
  numText: String[6];
  ch: Char;
  value: LongInt;
  code: Integer;
  result: Word;
begin
  TextRend.PrintSpaces(GDConsts.messageColumn, GDConsts.messageRow, Black, GDConsts.screenWidth);
  TextRend.DisplayString(GDConsts.messageColumn, GDConsts.messageRow, color, Black, query);
  queryLength := Length(query);
  column := queryLength;
  Str(maximum, maxText);
  numText := '';
  repeat
    ch := GameIo.ReadGameKey;
    case ch of
      '0'..'9': begin
        numText := Concat(numText, ch);
        Val(numText, value, code);
        if maximum >= value then
          Inc(column)
        else begin
          numText := maxText;
          column := queryLength + Length(maxText)
        end;
        TextRend.DisplayString(queryLength, GDConsts.messageRow, White, Black, numText)
      end;
      C_Keys.BACKSPACE:
        if Length(numText) > 0 then begin
          numText := Copy(numText, 1, Length(numText) - 1);
          TextRend.PrintSpaces(column, GDConsts.messageRow, Black, 1);
          Dec(column)
        end
    end
  until (ch = C_Keys.ENTER) or (ch = C_Keys.ESCAPE);
  TextRend.PrintSpaces(GDConsts.messageColumn, GDConsts.messageRow, Black, GDConsts.screenWidth);
  if ch = C_Keys.ESCAPE then
    result := 0
  else
    Val(numText, result, code);
  InputNumberMax := result
end;

procedure TradeMoney(var giver, receiver: Types.PCharacter; amount: Word; moneyType: ShortInt);
begin
  if receiver^.encumbrance + amount <= Money.CarryingCapacity(receiver) then begin
    giver^.coins[moneyType] := giver^.coins[moneyType] - amount;
    Money.RemoveWeight(giver, amount);
    receiver^.coins[moneyType] := receiver^.coins[moneyType] + amount;
    Money.AddWeight(receiver, amount)
  end else begin
    CharHlp.PrintBottomLine(Money.TRADE_OVERLOAD_MESSAGE);
    TextRend.PauseOnly;
    GameIo.FlushKeys
  end
end;

procedure PoolMoney;
var
  character: Types.PCharacter;
  { Unused in this version; see the other implementations of this routine. }
  coinIndex: ShortInt;
  moneyType: ShortInt;
begin
  character := GDVars.partyHead;
  GDVars.treasureActive := 1;
  while character <> nil do begin
    if (character^.npc = 0) or (character^.npc = C_Npc.ANIMATED_PLAYER) then begin
      for moneyType := 4 to 6 do begin
        GDVars.pooledMoney[moneyType] := character^.coins[moneyType] + GDVars.pooledMoney[moneyType];
        Money.RemoveWeight(character, character^.coins[moneyType])
      end;
      FillChar(character^.coins[4], SizeOf(character^.coins), 0)
    end;
    character := character^.next
  end
end;

function CountPoolers: Byte;
var
  character: Types.PCharacter;
  count: Byte;
begin
  character := GDVars.partyHead;
  count := 0;
  while character <> nil do begin
    if (character^.npc = 0) or (character^.npc = C_Npc.ANIMATED_PLAYER) then
      Inc(count);
    character := character^.next
  end;
  CountPoolers := count
end;

procedure ShareMoney;
var
  character: Types.PCharacter;
  { Unused in this version; see the other implementations of this routine. }
  receiver: Types.PCharacter;
  poolerCount: Byte;
  { Unused in this version; see the other implementations of this routine. }
  done: Boolean;
  takable: Word;
  share: array[4..6] of Word;
  remainder: array[4..6] of Word;
  moneyType: ShortInt;
begin
  character := GDVars.partyHead;
  done := False;
  poolerCount := Money.CountPoolers;
  FillChar(share, SizeOf(share), 0);
  FillChar(remainder, SizeOf(remainder), 0);
  for moneyType := 4 to 6 do
    if GDVars.pooledMoney[moneyType] > 0 then begin
      share[moneyType] := GDVars.pooledMoney[moneyType] div poolerCount;
      remainder[moneyType] := GDVars.pooledMoney[moneyType] mod poolerCount
    end else begin
      share[moneyType] := 0;
      remainder[moneyType] := 0
    end;
  while character <> nil do begin
    if character^.npc < C_Npc.NON_PLAYER then
      for moneyType := 6 downto 4 do
        if not Money.CheckOverload(character, share[moneyType], takable) then begin
          character^.coins[moneyType] := share[moneyType] + character^.coins[moneyType];
          Money.AddWeight(character, share[moneyType]);
          if remainder[moneyType] > 0 then
            if not Money.CheckOverload(character, 1, takable) then begin
              character^.coins[moneyType] := character^.coins[moneyType] + 1;
              Money.AddWeight(character, 1);
              Dec(remainder[moneyType])
            end
        end else begin
          character^.coins[moneyType] := character^.coins[moneyType] + takable;
          remainder[moneyType] := remainder[moneyType] + share[moneyType] - takable;
          Money.AddWeight(character, takable)
        end;
    character := character^.next
  end;
  for moneyType := 6 downto 4 do
    if remainder[moneyType] > 0 then begin
      character := GDVars.partyHead;
      while character <> nil do begin
        takable := Money.CarryingCapacity(character) - character^.encumbrance;
        if takable > 0 then
          if remainder[moneyType] > takable then begin
            character^.coins[moneyType] := character^.coins[moneyType] + takable;
            Money.AddWeight(character, takable);
            remainder[moneyType] := remainder[moneyType] - takable
          end else begin
            character^.coins[moneyType] := character^.coins[moneyType] + remainder[moneyType];
            Money.AddWeight(character, remainder[moneyType]);
            remainder[moneyType] := 0
          end;
        character := character^.next
      end
    end;
  GDVars.treasureActive := 0;
  for moneyType := 4 to 6 do begin
    GDVars.pooledMoney[moneyType] := remainder[moneyType];
    if GDVars.pooledMoney[moneyType] <> 0 then
      GDVars.treasureActive := 1
  end
end;

procedure DropMoney(character: Types.PCharacter; amount: Word; moneyType: ShortInt);
begin
  character^.coins[moneyType] := character^.coins[moneyType] - amount;
  Money.RemoveWeight(character, amount);
  if (GDVars.interfaceState = C_Ifc.LOOT) or (GDVars.interfaceState = C_Ifc.SHOP_TEMPLE) or
      (GDVars.interfaceState = C_Ifc.IN_VAULT) then
    GDVars.pooledMoney[moneyType] := GDVars.pooledMoney[moneyType] + amount
end;

{ Moves money from the pool to a character, at most what the pool holds; an amount that would overload the character is
  refused whole: "Overloaded" is shown, the game pauses and the keyboard is flushed. Note: the overload test uses the
  amount asked for, before it is cut down to what the pool holds.
  @param(character The character.)
  @param(amount The amount asked for.)
  @param(moneyType The money type.) }
procedure TakeMoney(character: Types.PCharacter; amount: Word; moneyType: ShortInt);
var takable: Word;
begin
  if Money.CheckOverload(character, amount, takable) then begin
    CharHlp.PrintBottomLine(Money.TRADE_OVERLOAD_MESSAGE);
    TextRend.PauseOnly;
    GameIo.FlushKeys
  end else begin
    if amount > GDVars.pooledMoney[moneyType] then
      amount := GDVars.pooledMoney[moneyType];
    GDVars.pooledMoney[moneyType] := GDVars.pooledMoney[moneyType] - amount;
    character^.coins[moneyType] := character^.coins[moneyType] + amount;
    Money.AddWeight(character, amount)
  end
end;

function ParseMoneyType(source: String; var typeName: String): ShortInt;
var index: Byte;
begin
  index := 1;
  while source[index] = ' ' do
    Inc(index);
  case source[index] of
    'G': begin
      ParseMoneyType := 5;
      typeName := 'Gems '
    end;
    'S': begin
      typeName := 'steel ';
      ParseMoneyType := 4
    end;
    'J': begin
      typeName := 'Jewelry ';
      ParseMoneyType := 6
    end
  end
end;

procedure TakeMoneyMenu;
var
  moneyTypeIndex: ShortInt;
  moneyType: ShortInt;
  { Unused in this version; see the other implementations of this routine. }
  weight: Word;
  list: Types.PMenuRow;
  selected: Types.PMenuRow;
  saved: Types.PMenuRow;
  count: Word;
  menuIndex: Integer;
  numberText: String;
  amount: Word;
  leaving: Boolean;
  redraw: Boolean;
  redrawByte: Byte absolute redraw;
  key: Char;
begin
  Border.DrawWindowFrame(0);
  menuIndex := 0;
  repeat
    redraw := True;
    list := nil;
    selected := nil;
    for moneyTypeIndex := 4 to 6 do
      if GDVars.pooledMoney[moneyTypeIndex] > 0 then begin
        Inc(count);
        if list = nil then begin
          GetMem(list, SizeOf(Types.TMenuRow));
          list^.next := nil
        end else begin
          selected := list;
          GetMem(list, SizeOf(Types.TMenuRow));
          list^.next := selected
        end;
        Str(GDVars.pooledMoney[moneyTypeIndex], numberText);
        list^.name := Concat(GDConsts.moneyNames[moneyTypeIndex], ' ', numberText);
        list^.heading := 0
      end;
    selected := list;
    saved := list;
    MenuCore.EnableChoices(1);
    key := Char(MenuCore.MenuVertical(GDConsts.selectCoinQuery, GDConsts.selectMenuText, 2, 2, 15, 8, list, 1, 1,
                                      redrawByte, menuIndex,
                                      selected));
    if (selected = nil) or (key = #1) or ((GDVars.menuExtendedKey <> 0) and (key = C_Keys.ESCAPE)) then
      leaving := True
    else begin
      leaving := False;
      moneyType := Money.ParseMoneyType(selected^.name, numberText);
      if moneyType = 5 then
        numberText := Concat(GDConsts.howMany, numberText, GDConsts.takePromptTail)
      else
        numberText := Concat(GDConsts.howMuch, numberText, GDConsts.takePromptTail);
      amount := Money.InputNumberMax(GDVars.pooledMoney[moneyType], numberText, LightGreen);
      Money.TakeMoney(GDVars.currentCharacter, amount, moneyType);
      MenuCore.FreeMenuRows(saved);
      GDVars.treasureActive := 0;
      leaving := True;
      for moneyTypeIndex := 4 to 6 do
        if GDVars.pooledMoney[moneyTypeIndex] > 0 then begin
          GDVars.treasureActive := 1;
          leaving := False
        end
    end
  until leaving
end;

procedure DetermineTreasure(var coins, items: Boolean);
var moneyType: ShortInt;
begin
  coins := False;
  items := False;
  for moneyType := 4 to 6 do
    if GDVars.pooledMoney[moneyType] <> 0 then
      coins := True;
  if GDVars.treasureItems <> nil then
    items := True
end;

procedure AppraiseMenu(var ok: Boolean);
var
  gemText: String[40];
  jewelryText: String[40];
  key: Char;
  { Unused in this version; see the other implementations of this routine. }
  menuText: String[40];
  { Unused in this version; see the other implementations of this routine. }
  actionText: String[40];
  roll: Byte;
  value: Word;
  takable: Word;
  item: Types.PItem;
  gem: Types.PItem;
  leaving: Boolean;
  { Unused in this version; see the other implementations of this routine. }
  isExtendedKey: Boolean;
  mustSell: Boolean;
  menuOption: Byte;
begin
  ok := True;
  if (GDVars.currentCharacter^.coins[5] = 0) and (GDVars.currentCharacter^.coins[6] = 0) then begin
    CharHlp.PrintBottomLine(Money.NO_GEMS_MESSAGE);
    ok := False
  end else
    repeat
      if (GDVars.currentCharacter^.coins[5] = 0) and (GDVars.currentCharacter^.coins[6] = 0) then
        leaving := True
      else begin
        leaving := False;
        Str(GDVars.currentCharacter^.coins[5], gemText);
        Str(GDVars.currentCharacter^.coins[6], jewelryText);
        gemText := Concat(GDConsts.gemsCountLabel, gemText);
        jewelryText := Concat(GDConsts.jewelryCountLabel, jewelryText);
        TextRend.ClearRect(1, 1, 38, 22);
        CharHlp.DisplayCreatureName(GDVars.currentCharacter, 1, 1, False);
        TextRend.DisplayString(1, 7, White, Black, GDConsts.collectionMessage);
        TextRend.DisplayString(1, 9, White, Black, gemText);
        TextRend.DisplayString(1, 10, White, Black, jewelryText);
        FillChar(GDVars.enabledChoices, SizeOf(GDVars.enabledChoices), $FF);
        menuOption := 0;
        if GDVars.currentCharacter^.coins[5] <> 0 then begin
          GDVars.enabledChoices[menuOption].ordinal := 0;
          Inc(menuOption)
        end;
        if GDVars.currentCharacter^.coins[6] <> 0 then begin
          GDVars.enabledChoices[menuOption].ordinal := 1;
          Inc(menuOption)
        end;
        GDVars.enabledChoices[menuOption].ordinal := 2;
        key := Char(MenuCore.MenuHorizontal(GDConsts.appraiseQuery, GDConsts.appraiseOptions, 1, 0));
        if (GDVars.menuExtendedKey <> 0) and (key = C_Keys.ESCAPE) then
          key := #2;
        case key of
          #0:
            if GDVars.currentCharacter^.coins[5] <> 0 then begin
              Dec(GDVars.currentCharacter^.coins[5]);
              roll := FxEngine.RollDice(1, 100);
              case roll of
                1..25: value := 5;
                26..50: value := 25;
                51..70: value := 50;
                71..90: value := 250;
                91..99: value := 500;
                100: value := 2500
              end;
              Str(value, gemText);
              gemText := Concat(GDConsts.gemValuePrefix, gemText, Money.GOLD_VALUE_SUFFIX);
              TextRend.DisplayString(1, 12, White, Black, gemText);
              FillChar(GDVars.enabledChoices, SizeOf(GDVars.enabledChoices), $FF);
              GDVars.enabledChoices[0].ordinal := 0;
              if Money.CheckOverload(GDVars.currentCharacter, 1,
                                     takable) or (GDVars.currentCharacter^.numberOfItems >= 16) then
                mustSell := True
              else begin
                GDVars.enabledChoices[1].ordinal := 1;
                mustSell := False
              end;
              key := Char(MenuCore.MenuHorizontal(GDConsts.emptyQuery, GDConsts.sellMenu, 0, 0));
              if (key = #1) and (not mustSell) then begin
                gem := GameIo.AllocSlot;
                FillChar(gem^, SizeOf(Types.TItem), 0);
                gem^.next := nil;
                gem^.equipped := 0;
                gem^.nameIds[3] := 122;
                gem^.nameIds[2] := 0;
                gem^.nameIds[1] := 0;
                gem^.itemType := 47;
                gem^.value := value;
                gem^.weight := 1;
                gem^.unidentifiedMask := 0;
                item := GDVars.currentCharacter^.items;
                if item = nil then
                  item := gem
                else begin
                  while item^.next <> nil do
                    item := item^.next;
                  item^.next := gem
                end
              end else
                Money.GiveSteel(value)
            end;
          #1:
            if GDVars.currentCharacter^.coins[6] <> 0 then begin
              Dec(GDVars.currentCharacter^.coins[6]);
              roll := FxEngine.RollDice(1, 100);
              case roll of
                1..10: value := Trunc(Random(450)) + 50;
                11..20: value := Trunc(Random(500)) + 100;
                21..40: value := Trunc(Random(750)) + 150;
                41..50: value := Trunc(Random(1250)) + 250;
                51..70: value := Trunc(Random(2500)) + 500;
                71..90: value := Trunc(Random(3000)) + 1000;
                91..100: value := Trunc(Random(5000)) + 1000
              end;
              Str(value, jewelryText);
              jewelryText := Concat(GDConsts.jewelValuePrefix, jewelryText, Money.GOLD_VALUE_SUFFIX);
              TextRend.DisplayString(1, 12, White, Black, jewelryText);
              FillChar(GDVars.enabledChoices, SizeOf(GDVars.enabledChoices), $FF);
              GDVars.enabledChoices[0].ordinal := 0;
              if Money.CheckOverload(GDVars.currentCharacter, 1,
                                     takable) or (GDVars.currentCharacter^.numberOfItems >= 16) then
                mustSell := True
              else begin
                GDVars.enabledChoices[1].ordinal := 1;
                mustSell := False
              end;
              key := Char(MenuCore.MenuHorizontal(GDConsts.emptyQuery, GDConsts.sellMenu, 0, 0));
              if (key = #1) and (not mustSell) then begin
                gem := GameIo.AllocSlot;
                FillChar(gem^, SizeOf(Types.TItem), 0);
                gem^.next := nil;
                gem^.equipped := 0;
                gem^.nameIds[3] := 123;
                gem^.nameIds[2] := 0;
                gem^.nameIds[1] := 0;
                gem^.itemType := 47;
                gem^.value := value;
                gem^.weight := 1;
                gem^.unidentifiedMask := 0;
                item := GDVars.currentCharacter^.items;
                if item = nil then
                  item := gem
                else begin
                  while item^.next <> nil do
                    item := item^.next;
                  item^.next := gem
                end
              end else
                Money.GiveSteel(value)
            end;
          #2: leaving := True
        end;
        CharHlp.RecalcStats(GDVars.currentCharacter)
      end
    until leaving
end;
begin
end.
