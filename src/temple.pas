{ Temple -- the temple: its main menu (heal, view, take, pool, share, appraise, exit; take and share only while the
  treasure holds money) and the healing menu of eleven services, named from spellNames through
  GDConsts.templeMenuSpells. Each service asks before working on a character who does not need it. No service takes
  payment. }
{$O+,F+}
unit Temple;
interface
uses C_Effect, C_Ifc, C_Race, C_Spell, C_Stat, C_Status, Crt, C_Keys, GDConsts, GDVars, Types,
  FxEngine, CharHlp, TextRend, MenuCore, Magic, Border, ViewChar, Money;

{ The temple's main loop, for EclVm: it empties the pool, offers the main menu and asks before leaving money behind. }
procedure TempleMainMenu;
implementation

{ Reports that the current character does not need the cure and asks whether to cast it anyway, with No as the default.
  @param(msg The report, printed after the character's name.)
  @returns(The answer, Yes or No.) }
function ConfirmCureAnyway(msg: String): Char;
begin
  CharHlp.PrintCreatureMessage(GDVars.currentCharacter, msg, 0, False);
  ConfirmCureAnyway := Chr(MenuCore.YesNoMenu(GDConsts.castAnywayPrompt, GDConsts.noKey));
  CharHlp.ClearMessageWindow;
end;

{ Removes the character's blindness, asking first when the character is not blind. }
procedure CureBlindness;
var
  eff: Types.PEffect;
  { Unused in this version; see the other implementations of this routine. }
  s: String;
  c: Char;
begin
  c := Chr(GDConsts.yesKey);
  if not CharHlp.HasEffect(GDVars.currentCharacter, C_Effect.BLIND, eff) then
    c := Temple.ConfirmCureAnyway(GDConsts.notBlindMessage);
  if c = Chr(GDConsts.yesKey) then FxEngine.RemoveEffect(GDVars.currentCharacter, C_Effect.BLIND, nil);
end;

{ Cure Disease: does nothing. }
procedure CureDisease;
begin
end;

{ Kind 1 restores 1d8 hit points, 2 restores 2d8 + 1, 3 restores 3d8 + 3; 4, Heal, restores all but 1d4 (nothing when
  that would pass the maximum), removes blindness and recalculates intelligence and wisdom.
  @param(kind The service, 1..4.) }
procedure CureWounds(kind: Byte);
var
  hp: Byte;
  { Unused in this version; see the other implementations of this routine. }
  i: Byte;
  { Unused in this version; see the other implementations of this routine. }
  restored: Byte;
  { Unused in this version; see the other implementations of this routine. }
  hpRestored: Boolean;
begin
  case kind of
    1: begin
         hp := FxEngine.RollDice(1, 8);
         hpRestored := FxEngine.RestoreHitPoints(GDVars.currentCharacter, hp, False);
       end;
    2: begin
         hp := FxEngine.RollDice(2, 8) + 1;
         hpRestored := FxEngine.RestoreHitPoints(GDVars.currentCharacter, hp, False);
       end;
    3: begin
         hp := FxEngine.RollDice(3, 8) + 3;
         hpRestored := FxEngine.RestoreHitPoints(GDVars.currentCharacter, hp, False);
       end;
    4: begin
         hp := FxEngine.RollDice(1, 4);
         if GDVars.currentCharacter^.hitPoints + hp > GDVars.currentCharacter^.maxHitPoints then hp := 0
         else hp := GDVars.currentCharacter^.maxHitPoints - GDVars.currentCharacter^.hitPoints - hp;
         hpRestored := FxEngine.RestoreHitPoints(GDVars.currentCharacter, hp, False);
         FxEngine.RemoveEffect(GDVars.currentCharacter, C_Effect.BLIND, nil);
         FxEngine.RecalcAbility(GDVars.currentCharacter, C_Stat.INTELLIGENCE);
         FxEngine.RecalcAbility(GDVars.currentCharacter, C_Stat.WISDOM);
       end;
  end;
end;

{ Raises a dead or animated character through spell service 75, unless it is a Silvanesti or Qualinesti elf; asks first
  otherwise, and only a dead, raisable character is raised. }
procedure RaiseDead;
var
  { Unused in this version; see the other implementations of this routine. }
  eff: Pointer;
  c: Char;
  wasDead: Boolean;
  { Unused in this version; see the other implementations of this routine. }
  hpLoss: Byte;
  { Unused in this version; see the other implementations of this routine. }
  hpBonus: Byte;
  { Unused in this version; see the other implementations of this routine. }
  i: ShortInt;
  cr: Types.PCharacter;
  cannotRaise: Boolean;
begin
  cr := GDVars.currentCharacter;
  wasDead := False;
  cannotRaise := False;
  c := Chr(GDConsts.yesKey);
  if (cr^.status = C_Status.DEAD_STATUS) or (cr^.status = C_Status.ANIMATED) then wasDead := True;
  if cr^.race < C_Race.HALF_ELF then cannotRaise := True;
  if (not wasDead) or cannotRaise then
    if cannotRaise then c := Temple.ConfirmCureAnyway(GDConsts.cannotRaiseMessage)
    else c := Temple.ConfirmCureAnyway(GDConsts.notDeadMessage);
  if (c = Chr(GDConsts.yesKey)) and wasDead and (not cannotRaise) then begin
    GDVars.spellTargetState.targets[1] := cr;
    GDVars.currentSpellIndex := C_Spell.RAISE_DEAD;
    GDVars.spellServices.handlers[C_Spell.RAISE_DEAD];
  end;
end;

{ Neutralizes poison: clears the poison effects of a poisoned character and brings it back into play with at least one
  hit point, asking first when the character is not poisoned (a Yes then changes nothing). }
procedure NeutralizePoison;
var
  eff: Types.PEffect;
  c: Char;
  found: Boolean;
begin
  found := False;
  c := Chr(GDConsts.yesKey);
  if CharHlp.HasEffect(GDVars.currentCharacter, C_Effect.POISONED, eff) then found := True;
  if not found then c := Temple.ConfirmCureAnyway('is not poisoned.');
  if (c = Chr(GDConsts.yesKey)) and found then begin
    if GDVars.currentCharacter^.hitPoints = 0 then GDVars.currentCharacter^.hitPoints := 1;
    GDVars.effectLock := 1;
    FxEngine.RemoveEffect(GDVars.currentCharacter, C_Effect.POISONED, nil);
    FxEngine.RemoveEffect(GDVars.currentCharacter, C_Effect.SLOW_POISON_END, nil);
    FxEngine.RemoveEffect(GDVars.currentCharacter, C_Effect.SLOW_POISON_HIT, nil);
    GDVars.effectLock := 0;
    GDVars.currentCharacter^.enabled := 1;
    GDVars.currentCharacter^.status := C_Status.OKAY;
  end;
end;

{ Casts Remove Curse on the character, asking first when the character has no cursed item and no curse effect. }
procedure RemoveCurse;
var
  cursed: Boolean;
  it: Types.PItem;
  eff: Types.PEffect;
  c: Char;
begin
  c := Chr(GDConsts.yesKey);
  cursed := False;
  it := GDVars.currentCharacter^.items;
  while (it <> nil) and not cursed do begin
    if it^.cursed <> 0 then cursed := True;
    it := it^.next;
  end;
  if not cursed then
    if not CharHlp.HasEffect(GDVars.currentCharacter, C_Effect.CURSED,
                             eff) then c := Temple.ConfirmCureAnyway(GDConsts.notCursedMessage);
  if c = Chr(GDConsts.yesKey) then begin
    GDVars.spellTargetState.targets[1] := GDVars.currentCharacter;
    Magic.SpellRemoveCurse
  end;
end;

{ Returns a petrified character to play with one hit point, asking first when the character is not petrified (a Yes then
  changes nothing). }
procedure StoneToFlesh;
var
  { Unused in this version; see the other implementations of this routine. }
  eff: Pointer;
  c: Char;
begin
  c := Chr(GDConsts.yesKey);
  if GDVars.currentCharacter^.status <>
      C_Status.STONED then c := Temple.ConfirmCureAnyway(GDConsts.notStonedMessage);
  if (c = Chr(GDConsts.yesKey)) and (GDVars.currentCharacter^.status = C_Status.STONED) then begin
    GDVars.currentCharacter^.status := C_Status.OKAY;
    GDVars.currentCharacter^.enabled := 1;
    GDVars.currentCharacter^.hitPoints := 1;
  end;
end;

{ Casts Restoration on the current character through the spell table, first asking to confirm when none of its class
  levels is below its old peak. }
procedure Restoration;
var
  c: Char;
  lower: Boolean;
  i: ShortInt;
begin
  lower := False;
  c := Chr(GDConsts.yesKey);
  with GDVars.currentCharacter^ do begin
    for i := 0 to 7 do
      if classLevels[i] < oldLevels[i] then lower := True;
    if not lower then c := Temple.ConfirmCureAnyway(GDConsts.noLostLevelsMessage);
    if c = Chr(GDConsts.yesKey) then begin
      GDVars.spellTargetState.targets[1] := GDVars.currentCharacter;
      GDVars.currentSpellIndex := C_Spell.RESTORATION;
      GDVars.spellServices.handlers[C_Spell.RESTORATION];
    end;
  end;
end;

{ Runs the cure menu for the current character, showing its hit points, with eleven entries named after the healing
  spells, until the player picks Exit or presses Escape. }
procedure HealMenu;
var
  list: Types.PMenuRow;
  sel: Types.PMenuRow;
  redraw: Boolean;
  redrawByte: Byte absolute redraw;
  i: Byte;
  idx: Integer;
  done: Boolean;
  s: Types.TString40;
  c: Char;
  num: String[10];
  numLen: Byte;
  color: Byte;
begin
  done := False;
  list := nil;
  sel := nil;
  MenuCore.AllocStringList(11, list);
  sel := list;
  i := 1;
  while list <> nil do begin
    list^.name := GDConsts.spellNames[GDConsts.templeMenuSpells[i]];
    list^.heading := 0;
    list := list^.next;
    Inc(i);
  end;
  list := sel;
  TextRend.ClearRect(0, 24, 39, 24);
  redraw := True;
  Border.DrawRowDivider;
  idx := 0;
  repeat
  TextRend.ClearRect(1, 19, 38, 19);
  TextRend.DisplayString(1, 19, White, Black, GDVars.currentCharacter^.name);
  num := CharHlp.WordToString(GDVars.currentCharacter^.hitPoints);
  numLen := Length(num);
  if GDVars.currentCharacter^.hitPoints <>
      GDVars.currentCharacter^.maxHitPoints then color := LightMagenta else color := White;
  TextRend.DisplayString(18, 19, color, Black, num);
  num := '/' + CharHlp.WordToString(GDVars.currentCharacter^.maxHitPoints);
  TextRend.DisplayString(numLen + 18, 19, White, Black, num);
  s := GDVars.currentCharacter^.name + GDConsts.howCanWeHelp;
  TextRend.DisplayString(1, 1, White, Black, s);
    MenuCore.EnableChoices(0);
    c := Chr(MenuCore.MenuVertical(GDConsts.emptyQuery, GDConsts.healOptions, 2, 3, 38, 15, list, 1, 0, redrawByte, idx,
                                   sel));
    if GDVars.menuExtendedKey <> 0 then begin
      if c = C_Keys.ESCAPE then done := True
    end else begin
      case c of
      #0:
        case idx of
          0: Temple.CureBlindness;
          1: Temple.CureDisease;
          2: Temple.CureWounds(1);
          3: Temple.CureWounds(2);
          4: Temple.CureWounds(3);
          5: Temple.CureWounds(4);
          6: Temple.NeutralizePoison;
          7: Temple.RaiseDead;
          8: Temple.RemoveCurse;
          9: Temple.StoneToFlesh;
          10: Temple.Restoration;
          11: done := True;
        end;
      #1: done := True;
      end;
    end;
  until done;
  MenuCore.FreeMenuRows(list);
  CharHlp.DisplayNoncombatInterface;
  CharHlp.DisplayParty(GDVars.currentCharacter);
end;

procedure TempleMainMenu;
var
  i: Byte;
  sub: Byte;
  key: Char;
  done: Boolean;
  { Unused in this version; see the other implementations of this routine. }
  menuChoice: Byte;
  coins: Boolean;
  items: Boolean;
  { Unused in this version; see the other implementations of this routine. }
  serviceIndex: Byte;
  changed: Boolean;
begin
  GDVars.interfaceState := C_Ifc.SHOP_TEMPLE;
  GDVars.noncombatPrepared := 0;
  CharHlp.DisplayNoncombatInterface;
  GDVars.noncombatPrepared := 1;
  CharHlp.DisplayParty(GDVars.currentCharacter);
  FillChar(GDVars.pooledMoney, SizeOf(GDVars.pooledMoney), 0);
  GDVars.treasureActive := 0;
  done := False;
  repeat
    Money.DetermineTreasure(coins, items);
    FillChar(GDVars.enabledChoices, SizeOf(GDVars.enabledChoices), $FF);
    sub := 0;
    for i := 0 to 6 do
      if (i = 2) or (i = 4) then begin
        if coins then MenuCore.AppendChoice(i, sub)
      end else
        MenuCore.AppendChoice(i, sub);
    key := Chr(MenuCore.MenuHorizontal(GDConsts.emptyQuery, GDConsts.templeMenu, 1, 0));
    if GDVars.menuExtendedKey <> 0 then begin
      case key of
        C_Keys.ESCAPE: key := #6;
        C_Keys.UP, C_Keys.DOWN: begin ViewChar.SelectAdjacentCharacter(key); key := #255 end;
      end
    end;
    case key of
      #0: Temple.HealMenu;
      #1: ViewChar.ViewCharMenu(Boolean(GDVars.menuExtendedKey));
      #2: Money.TakeMoneyMenu;
      #3: Money.PoolMoney;
      #4: Money.ShareMoney;
      #5: Money.AppraiseMenu(changed);
      #6: begin
           Money.DetermineTreasure(coins, items);
           if coins then begin
             TextRend.DisplayMessageWindow(1, 17, 38, 22, LightGreen, Black, True, GDConsts.leftMoney1);
             TextRend.DisplayMessageWindow(1, 17, 38, 22, LightGreen, Black, True, GDConsts.leftMoney2);
             if Chr(MenuCore.YesNoMenu(GDConsts.emptyQuery, GDConsts.noKey)) = Chr(GDConsts.noKey) then done := True
             else TextRend.ClearRect(1, 17, 38, 22);
           end else done := True;
         end;
    end;
    case key of
      #2: CharHlp.DisplayNoncombatInterface;
      #5: if changed then CharHlp.DisplayNoncombatInterface;
    end;
    CharHlp.DisplayParty(GDVars.currentCharacter);
  until done;
end;
begin
end.
