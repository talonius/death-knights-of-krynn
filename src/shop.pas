{ Shop -- the shop: the main menu (buy, view, take, pool, share, appraise, exit) and the buy list, priced by the zone's
  price level and paid from the buyer's steel and then the pool. }
{$O+,F+}
unit Shop;
interface
uses C_Ifc, Crt, C_Keys, GDConsts, GDVars, CharHlp, TextRend, MenuCore, ViewChar, GameIo, Border, Money,
  Types;

{ Runs a store: the money pool starts empty and the store's goods are the treasure item list. The menu offers Buy, View,
  Pool, Appraise and Exit, plus Take and Share while the pool holds money; the up and down arrow keys change the current
  character; leaving with money in the pool asks first. Note: after Pool the interface is redrawn only when the last
  Appraise found something to appraise; Pool leaves that flag as it was. }
procedure ShopMainMenu;

{ Appends a copy of an item to the current character's items, joins a stackable item into matching stacks and
  recalculates the character's stats; a character who cannot carry it is reported as overloaded instead. Note: when the
  character had no items, the stack is joined through a pointer that was never set.
  @param(it The item to copy.)
  @param(failed Set when the character cannot carry the item, cleared otherwise.) }
procedure GiveItemCopyToCreature(it: Types.PItem; var failed: Boolean);
implementation

{ Shows the current character's funds and the pooled funds on rows 20 and 21. }
procedure DisplayShopMoney;
var s: Types.TString40;
begin
  Str(LongInt(GDVars.currentCharacter^.coins[4]), s);
  TextRend.RightAlignString(s, 10);
  TextRend.DisplayString(1, 20, White, Black, GDConsts.goldLabel + s);
  Str(GDVars.pooledMoney[4], s);
  TextRend.RightAlignString(s, 10);
  TextRend.DisplayString(1, 21, White, Black, GDConsts.poolLabel + s)
end;

{ Writes each item's price, right-aligned, into its name, runs the vertical menu over the shop's items and restores the
  names. Price level 1, 2, 4 or 8 divides the value by 16, 8, 4 or 2; $20, $40 or $80 multiplies it by 2, 4 or 8;
  anything else is the value. A stack costs its quantity times as much and nothing costs less than 1.
  @param(c Receives the key that ended the menu.)
  @param(itemToBuy Receives the item under the cursor when the menu ended.)
  @param(cursor The menu's cursor row, kept between calls.)
  @param(idx The menu's scroll position, kept between calls.) }
procedure ShopBuyItemSelection(var c: Char; var itemToBuy, cursor: Types.PItem; var idx: Integer);
var
  head: Types.PItem;
  p: Types.PItem;
  tmp: String[16];
  s: String[30];
  lenv: Byte;
  i: Byte;
  price: Word;
begin
  p := GDVars.treasureItems;
  while p <> nil do begin
    s := GDConsts.spaces30;
    if p^.value = 0 then p^.value := 1;
    case GDVars.zone1^.priceLevel[GDConsts.priceLevelIndex + $7C00] of
      1: price := p^.value div 16;
      2: price := p^.value div 8;
      4: price := p^.value div 4;
      8: price := p^.value div 2;
      $20: price := p^.value * 2;
      $40: price := p^.value * 4;
      $80: price := p^.value * 8
    else price := p^.value
    end;
    if p^.quantity > 1 then price := p^.quantity * price;
    if price = 0 then price := 1;
    Str(LongInt(price), tmp);
    lenv := Length(tmp);
    for i := 1 to lenv do s[30 - lenv + i] := tmp[i];
    lenv := Length(p^.name);
    for i := 1 to lenv do s[i] := p^.name[i];
    p^.name := s; p^.name[0] := #30; p := p^.next
  end;
  head := GDVars.treasureItems;
  GDVars.selectedChoice := 0;
  MenuCore.EnableChoices(0);
  c := Chr(MenuCore.MenuVertical(GDConsts.itemsQuery, GDConsts.buyMenu, 1, 1, 38, 18, head, 1, 0, GDVars.menuFlag, idx,
                                 cursor));
  itemToBuy := cursor;
  p := GDVars.treasureItems;
  while p <> nil do begin CharHlp.PrintItemString(nil, p, 0, 0, False, False); p := p^.next end
end;

procedure GiveItemCopyToCreature(it: Types.PItem; var failed: Boolean);
var
  p: Types.PItem;
  q: Types.PItem;
begin
  if ViewChar.CannotCarryItem(GDVars.currentCharacter, 1, it) then begin
    CharHlp.PrintBottomLine(GDConsts.tradeOverloadMessage); failed := True
  end else begin
    failed := False; p := GDVars.currentCharacter^.items;
    if p = nil then begin
      p := GameIo.AllocSlot; p^ := it^; p^.next := nil; GDVars.currentCharacter^.items := p
    end else begin
      while p^.next <> nil do p := p^.next;
      q := GameIo.AllocSlot; q^ := it^; q^.next := nil; p^.next := q
    end;
    if it^.quantity > 0 then ViewChar.JoinItem(q);
    CharHlp.RecalcStats(GDVars.currentCharacter)
  end
end;

{ Buys until Escape: the price as in the list, taken from the buyer's steel, or from all of it and the rest from the
  pool, and reported. Note: a price level other than the list's eight leaves the price unset, where the list shows the
  item's plain value. }
procedure ShopBuyMenu;
var
  itemToBuy: Types.PItem;
  c: Char;
  done: Boolean;
  price: Word;
  charGold: Word;
  pooled: LongInt;
  failed: Boolean;
  cursor: Types.PItem;
  idx: Integer;
begin
  itemToBuy := nil; cursor := GDVars.treasureItems; idx := 0;
  Border.DrawWindowFrame(0); GDVars.menuFlag := 1;
  repeat
    Shop.DisplayShopMoney;
    Shop.ShopBuyItemSelection(c, itemToBuy, cursor, idx);
    if (c = C_Keys.ESCAPE) and (GDVars.menuExtendedKey <> 0) then begin done := True end
    else begin
      done := False;
      case GDVars.zone1^.priceLevel[GDConsts.priceLevelIndex + $7C00] of
        1: price := itemToBuy^.value div 16;
        2: price := itemToBuy^.value div 8;
        4: price := itemToBuy^.value div 4;
        8: price := itemToBuy^.value div 2;
        $10: price := itemToBuy^.value;
        $20: price := itemToBuy^.value * 2;
        $40: price := itemToBuy^.value * 4;
        $80: price := itemToBuy^.value * 8
      end;
      if itemToBuy^.quantity > 1 then price := itemToBuy^.quantity * price;
      if price = 0 then price := 1;
      charGold := GDVars.currentCharacter^.coins[4]; pooled := GDVars.pooledMoney[4];
      if price <= charGold then begin
        Shop.GiveItemCopyToCreature(itemToBuy, failed);
        if not failed then begin
          Dec(GDVars.currentCharacter^.coins[4], price);
          if itemToBuy^.quantity > 0 then
            CharHlp.PrintBottomLine(GDVars.currentCharacter^.name + GDConsts.buysText + itemToBuy^.name)
          else CharHlp.PrintBottomLine(GDVars.currentCharacter^.name + GDConsts.buysAText + itemToBuy^.name)
        end
      end else if price <= charGold + pooled then begin
        Shop.GiveItemCopyToCreature(itemToBuy, failed);
        if not failed then begin
          GDVars.currentCharacter^.coins[4] := 0;
          Dec(GDVars.pooledMoney[4], price - charGold);
          if itemToBuy^.quantity > 0 then
            CharHlp.PrintBottomLine(GDVars.currentCharacter^.name + GDConsts.buysText + itemToBuy^.name)
          else CharHlp.PrintBottomLine(GDVars.currentCharacter^.name + GDConsts.buysAText + itemToBuy^.name)
        end
      end else CharHlp.PrintBottomLine(GDConsts.notEnoughMoneyText)
    end
  until done
end;

procedure ShopMainMenu;
var
  viewFlag: Boolean;
  done: Boolean;
  choiceState: Byte;
  i: Byte;
  c: Byte;
  hasMoney: Boolean;
  hasItems: Boolean;
  appraiseOk: Boolean;
  p: Types.PItem;
  menuState: Byte;
begin
  GDVars.previousInterfaceState := GDVars.interfaceState; GDVars.interfaceState := C_Ifc.SHOP_TEMPLE;
  GDVars.noncombatPrepared := 0; CharHlp.DisplayNoncombatInterface; GDVars.noncombatPrepared := 1;
      CharHlp.DisplayParty(GDVars.currentCharacter);
  FillChar(GDVars.pooledMoney, SizeOf(GDVars.pooledMoney), 0); GDVars.treasureActive := 0; done := False;
  p := GDVars.treasureItems;
  while p <> nil do begin CharHlp.PrintItemString(nil, p, 0, 0, False, False); p := p^.next end;
  menuState := 1;
  repeat
    Money.DetermineTreasure(hasMoney, hasItems);
    if hasMoney then MenuCore.EnableChoices(6)
    else begin
      choiceState := 0;
      for i := 0 to 6 do
        if (i <> 2) and (i <> 4) then MenuCore.AppendChoice(i, choiceState)
    end;
    GDVars.selectedChoice := menuState;
    c := MenuCore.MenuHorizontal(GDConsts.emptyQuery, GDConsts.shopMenu, 1, 0);
    menuState := GDVars.selectedChoice;
    if GDVars.menuExtendedKey <> 0 then begin
      case c of
        Ord(C_Keys.UP), Ord(C_Keys.DOWN): begin ViewChar.SelectAdjacentCharacter(Char(c)); c := 255 end;
        Ord(C_Keys.ESCAPE): c := 6
      end
    end;
    case c of
      0: Shop.ShopBuyMenu;
      1: ViewChar.ViewCharMenu(viewFlag);
      2: Money.TakeMoneyMenu;
      3: Money.PoolMoney;
      4: Money.ShareMoney;
      5: Money.AppraiseMenu(appraiseOk);
      6: begin
        Money.DetermineTreasure(hasMoney, hasItems);
        if hasMoney then begin
          TextRend.DisplayMessageWindow(1, 17, 38, 22, LightGreen, Black, True, GDConsts.leftMoney1);
          TextRend.DisplayMessageWindow(1, 17, 38, 22, White, Black, False, GDConsts.leftMoney2);
          if MenuCore.YesNoMenu(GDConsts.emptyQuery, GDConsts.yesKey) = GDConsts.noKey then done := True
          else TextRend.ClearRect(1, 17, 38, 22)
        end else done := True
      end
    end;
    case c of
      0, 2, 5: CharHlp.DisplayNoncombatInterface;
      3: if appraiseOk then CharHlp.DisplayNoncombatInterface
    end;
    CharHlp.DisplayParty(GDVars.currentCharacter)
  until done;
  GDVars.interfaceState := GDVars.previousInterfaceState
end;
begin
end.
