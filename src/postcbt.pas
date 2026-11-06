{ PostCbt -- after a fight: who won, fled or fell, experience and treasure, the summary screen, the treasure menu, and
  clearing the monsters and the fight's zone flags. }
{$O+,F+,A-}
unit PostCbt;
interface
uses C_Class, C_Ifc, C_Npc, C_Side, C_Spell, C_Stat, C_Status, Crt, C_Keys, GDConsts, GDVars, Types,
  TextRend, CharHlp, MenuCore, Border, FxEngine, GameIo, Magic, CharGen, Shop, ViewChar, Money;

{ Settles a fight, for EclVm: the results (not in a demo), the monsters removed from the party, stats recalculated;
  then, unless the party was destroyed, the summary and the treasure menu, the treasure discarded if the party fled and
  freed afterwards -- or, if it was destroyed, the 'monsters rejoice' screen. Clears the fight's THAC0 and movement
  modifiers, noCombatItems, reviveFlag and mirrorDuel. }
procedure PostCombat;

{ Offers Money, Items and Exit for taking from the treasure while both remain, going straight to the one that is left
  otherwise. The cursor keys change the current character.
  @param(coins Whether the treasure holds money; updated after each choice while both remain.)
  @param(items Whether the treasure holds items; updated likewise.) }
procedure LootTakeMenu(var coins, items: Boolean);
implementation
const
  TAKE_BOTH_QUERY = 'Take: ';
  TAKE_BOTH_MENU = 'Money Items Exit';
  PARTY_DESTROYED = 'The monsters rejoice for the party has been destroyed';
  PRESS_ANY_KEY = 'Press any key to continue';

procedure DetermineLootExp(var share: LongInt); forward;

procedure AwardExperience(xp: LongInt); forward;

procedure DetermineCombatResults; forward;

procedure PostCombatSummary(xp: LongInt); forward;

procedure LootTakeItemSelection(var c: Char; var itemToTake, cursor: Types.PItem; var idx: Integer); forward;

procedure LootTakeItemMenu; forward;

procedure LootMenu; forward;

procedure PostCombatCreatureCleanup; forward;

{ Each party member's experience share: for a duel the current character's highest level x 100; otherwise every downed
  monster's XP award plus hit dice x XP per hit point, its money pooled (from a monster with notPcNpc 1) and its items
  added to the treasure unless noCombatItems is 1, plus 2 per steel, 250 per gem, 2200 per jewel and 400 per plus on the
  new items -- divided by the party size less the members out of the fight.
  @param(share Receives each member's share.) }
procedure DetermineLootExp(var share: LongInt);
var
  p: Types.PCharacter;
  i: ShortInt;
  expTotal: LongInt;
  q: Types.PItem;
  it: Types.PItem;
  cnt: Byte;
begin
  if GDVars.duelFlag <> 0 then share := GDVars.currentCharacter^.levelHighest * 100
  else begin
    expTotal := 0; p := GDVars.partyHead; cnt := 0;
    while p <> nil do begin
      it := p^.items;
      if (p^.side = C_Side.ENEMY) and (p^.status <> C_Status.OKAY) and
          (p^.status <> C_Status.RUNNING) then begin
        GDVars.monstersKilled := 1;
        if p^.combat^.notPcNpc = 1 then
          for i := 4 to 6 do Inc(GDVars.pooledMoney[i], p^.coins[i]);
        expTotal := expTotal + p^.xpAward + p^.hpRolled * p^.baseMaxHitPoints;
        if GDVars.zone1^.noCombatItems[GDConsts.noCombatItemsIndex + $7C00] <> 1 then
          while it <> nil do begin
            Inc(cnt);
            if GDVars.treasureItems = nil then begin
              GetMem(GDVars.treasureItems, SizeOf(Types.TItem));
              CharHlp.PrintItemString(p, it, 0, 0, False, False);
              GDVars.treasureItems^ := it^;
              GDVars.treasureItems^.equipped := 0;
              GDVars.treasureItems^.next := nil
            end else begin
              q := GDVars.treasureItems;
              GetMem(GDVars.treasureItems, SizeOf(Types.TItem));
              CharHlp.PrintItemString(p, it, 0, 0, False, False);
              GDVars.treasureItems^ := it^;
              GDVars.treasureItems^.equipped := 0;
              GDVars.treasureItems^.next := q
            end;
            it := it^.next
          end
      end;
      p := p^.next
    end;
    Inc(expTotal, GDVars.pooledMoney[4] * 2);
    Inc(expTotal, GDVars.pooledMoney[5] * 250);
    Inc(expTotal, GDVars.pooledMoney[6] * 2200);
    q := GDVars.treasureItems;
    while (q <> nil) and (q <> GDVars.prevTreasure) do begin
      if q^.plus > 0 then Inc(expTotal, q^.plus * 400);
      q := q^.next
    end;
    share := expTotal div (GDVars.zone1^.partySize[GDConsts.partySizeIndex + $7C00] - GDVars.nonAnimCount)
  end
end;

{ Gives experience to each party member still in play and not animated, unless the fight was a mirror duel, and then
  sets the member's level-up flag from CanLevelUp. A single-class character with a high prime requisite gets 10 percent
  more: Wisdom for a cleric, Strength for a fighter, Strength and Wisdom for a paladin, Strength, Intelligence and
  Wisdom for a ranger, Intelligence for a mage, Dexterity for a thief. A two-class character gets half, a three-class
  character a third. Note: the cleric's threshold is one lower than the others'.
  @param(xp Each member's share before the class adjustment.) }
procedure AwardExperience(xp: LongInt);
var
  p: Types.PCharacter;
  share: LongInt;
begin
  if GDVars.zone0^.mirrorDuel <> 0 then Exit;
  p := GDVars.partyHead;
  while p <> nil do begin
    if (p^.enabled <> 0) and (p^.status <> C_Status.ANIMATED) then begin
      share := xp;
      case p^.characterClass of
        C_Class.CLERIC: if p^.stats[C_Stat.WISDOM].current > 14 then share := xp div 10 + xp;
        C_Class.FIGHTER: if p^.stats[C_Stat.STRENGTH].current > 15 then share := xp div 10 + xp;
        C_Class.PALADIN: if (p^.stats[C_Stat.STRENGTH].current > 15) and
          (p^.stats[C_Stat.WISDOM].current > 15) then share := xp div 10 + xp;
        C_Class.RANGER: if (p^.stats[C_Stat.STRENGTH].current > 15) and
          (p^.stats[C_Stat.INTELLIGENCE].current > 15) and (p^.stats[C_Stat.WISDOM].current > 15) then
            share := xp div 10 + xp;
        C_Class.MAGE: if p^.stats[C_Stat.INTELLIGENCE].current > 15 then share := xp div 10 + xp;
        C_Class.THIEF: if p^.stats[C_Stat.DEXTERITY].current > 15 then share := xp div 10 + xp;
        C_Class.CLERIC_FIGHTER, C_Class.CLERIC_RANGER..C_Class.FIGHTER_THIEF,
          C_Class.MAGE_THIEF: share := xp div 2;
        C_Class.CLERIC_FIGHTER_MAGE, C_Class.FIGHTER_MAGE_THIEF: share := xp div 3
      end;
      Inc(p^.experience, share);
      p^.levelUpReady := Ord(CharHlp.CanLevelUp(p))
    end;
    p := p^.next
  end
end;

{ Decides whether the party fled, won or was defeated, clears the nineteen end-of-fight effects and awards experience on
  a win. Then, unless defeated, each member's status is settled: a running member is okay again; an unconscious one
  returns if it has hit points; unconscious and dying members return at 1 hit point when reviveFlag is set, and a dying
  one otherwise becomes unconscious. After a flight every member that is not running is removed instead. A defeated
  party is removed whole and partySize zeroed. In a duel during a demo only the winners' experience and statuses are
  settled. }
procedure DetermineCombatResults;
var
  p: Types.PCharacter;
  done: Boolean;
  i: Byte;
  alive: Boolean;
begin
  GDVars.nonAnimCount := 0;
  GDVars.partyDefeated := 1;
  GDVars.partyFled := False;
  p := GDVars.partyHead;
  while (p <> nil) and (p^.combat^.notPcNpc <> 1) do begin
    if p^.status = C_Status.RUNNING then GDVars.partyFled := True;
    p := p^.next
  end;
  p := GDVars.partyHead;
  alive := False;
  while (p <> nil) and not alive do begin
    if (p^.enabled <> 0) or (p^.status = C_Status.UNCONSCIOUS) or (p^.status = C_Status.RUNNING) or
        (p^.status = C_Status.DYING) then alive := True;
    p := p^.next
  end;
  if (GDVars.duelFlag <> 0) or ((GDVars.zone1^.reviveFlag[GDConsts.reviveFlagIndex + $7C00] <> 0) and alive) then
    GDVars.partyDefeated := 0;
  GDVars.combatWon := False;
  p := GDVars.partyHead;
  if (GDVars.duelFlag = 0) or (GDVars.demoMode = 0) then begin
    while (p <> nil) and (p^.combat^.notPcNpc <> 1) do begin
      if ((p^.status = C_Status.RUNNING) or (p^.status = C_Status.ANIMATED) or
          (p^.status = C_Status.OKAY)) and (p^.side = C_Side.PLAYER) and (p^.npc < C_Npc.NON_PLAYER)
          then GDVars.partyDefeated := 0;
      if (p^.status = C_Status.ANIMATED) or (p^.status = C_Status.OKAY) then begin
        GDVars.combatWon := True; GDVars.partyFled := False
      end;
      if (p^.enabled = 0) or (p^.status = C_Status.ANIMATED) then Inc(GDVars.nonAnimCount);
      for i := 1 to 19 do FxEngine.RemoveEffect(p, GDConsts.clearEffects[i], nil);
      p := p^.next
    end;
    if GDVars.combatWon then begin
      PostCbt.DetermineLootExp(GDVars.expShare); PostCbt.AwardExperience(GDVars.expShare)
    end;
    p := GDVars.partyHead;
    if GDVars.partyDefeated = 0 then begin
      while (p <> nil) and (p^.combat^.notPcNpc <> 1) do begin
        if not GDVars.partyFled then begin
          case p^.status of
            C_Status.RUNNING: begin p^.status := C_Status.OKAY; p^.enabled := 1 end;
            C_Status.DYING: if GDVars.zone1^.reviveFlag[GDConsts.reviveFlagIndex + $7C00] <> 0 then begin
                p^.status := C_Status.OKAY; p^.enabled := 1; p^.hitPoints := 1
              end else p^.status := C_Status.UNCONSCIOUS;
            C_Status.UNCONSCIOUS: if p^.hitPoints >
              0 then begin p^.status := C_Status.OKAY; p^.enabled := 1 end
              else if GDVars.zone1^.reviveFlag[GDConsts.reviveFlagIndex + $7C00] <> 0 then begin
                p^.status := C_Status.OKAY; p^.enabled := 1; p^.hitPoints := 1
              end
          end;
          p := p^.next
        end else begin
          GDVars.zone1^.combatResult[GDConsts.combatResultIndex + $7C00] := $81;
          if p^.status = C_Status.RUNNING then begin
            p^.status := C_Status.OKAY; p^.enabled := 1; p := p^.next
          end else begin
            GDVars.currentCharacter := p; p := p^.next; CharGen.RemoveCreature(False, True)
          end
        end
      end
    end else begin
      p := GDVars.partyHead; done := False;
      while (p <> nil) and not done do begin
        if p^.combat^.notPcNpc <> 1 then begin
          GDVars.currentCharacter := p; CharGen.RemoveCreature(False, True)
        end else done := True;
        p := p^.next
      end;
      GDVars.zone1^.partySize[GDConsts.partySizeIndex + $7C00] := 0
    end
  end else begin
    p := GDVars.partyHead;
    while p <> nil do begin
      if (p^.enabled = 1) and (p^.status = C_Status.OKAY) and (p^.side <> C_Side.ENEMY) then begin
        GDVars.combatWon :=
          True; PostCbt.DetermineLootExp(GDVars.expShare); PostCbt.AwardExperience(GDVars.expShare)
      end;
      p := p^.next
    end;
    p := GDVars.partyHead;
    while p <> nil do begin
      if (p^.status = C_Status.OKAY) or (p^.status = C_Status.ANIMATED) then p^.enabled := 1;
      if p^.status = C_Status.DYING then p^.status := C_Status.UNCONSCIOUS;
      p := p^.next
    end
  end
end;

{ The summary screen: fled (treasure and pool discarded, no experience), lost, won the duel or won, the experience each
  receives (not after a mirror duel), and whether there is treasure.
  @param(xp Experience each member receives; shown as 0 after a flight or a loss.) }
procedure PostCombatSummary(xp: LongInt);
var
  numStr: String[10];
  msg: String;
  { Unused in this version; see the other implementations of this routine. }
  c: Char;
  query: String[1];
  p: Types.PItem;
  q: Types.PItem;
begin
  query[0] := #0;
  Border.DrawWindowFrame(0);
  if (GDVars.monstersKilled <> 0) or (GDVars.duelFlag <> 0) then begin
    if GDVars.partyFled then begin
      TextRend.DisplayString(1, 3, LightGreen, Black, GDConsts.msgPartyFled);
      xp := 0;
      p := GDVars.treasureItems;
      while p <> nil do begin
        q := p^.next;
        GameIo.FreeSlot(p);
        p := q
      end;
      FillChar(GDVars.pooledMoney, SizeOf(GDVars.pooledMoney), 0)
    end else if ((GDVars.duelFlag <> 0) and not GDVars.combatWon) or
      (not GDVars.combatWon and (GDVars.zone1^.reviveFlag[GDConsts.reviveFlagIndex + $7C00] <> 0)) then begin
      GDVars.zone1^.combatResult[GDConsts.combatResultIndex + $7C00] := $80;
      TextRend.DisplayString(1, 3, LightGreen, Black, GDConsts.msgLostFight);
      xp := 0
    end else if GDVars.duelFlag <> 0 then
      TextRend.DisplayString(1, 3, LightGreen, Black, GDConsts.msgWonDuel)
    else
      TextRend.DisplayString(1, 3, LightGreen, Black, GDConsts.msgPartyWon)
  end else
    TextRend.DisplayString(1, 3, LightGreen, Black, GDConsts.msgPartyTreasure);
  Str(xp, numStr);
  if GDVars.duelFlag <> 0 then msg := GDConsts.duelistReceives + numStr
  else msg := GDConsts.eachReceives + numStr;
  if GDVars.zone0^.mirrorDuel = 0 then begin
    TextRend.DisplayString(1, 5, LightGreen, Black, msg);
    TextRend.DisplayString(1, 7, LightGreen, Black, GDConsts.experiencePoints)
  end;
  GDVars.treasureHasMoney := False;
  GDVars.treasureHasItems := False;
  Money.DetermineTreasure
    (GDVars.treasureHasMoney, GDVars.treasureHasItems);
  if GDVars.treasureHasMoney or GDVars.treasureHasItems then
    TextRend.DisplayString(1, 10, LightGreen, Black, GDConsts.msgPartyTreasure)
  else
    TextRend.DisplayString(1, 10, LightGreen, Black, GDConsts.msgNoTreasure);
  c := Char(MenuCore.MenuHorizontal(GDConsts.emptyQuery, GDConsts.pressToContinue, Ord(True), Ord(False)))
end;

{ Lists the treasure items in a vertical Take menu.
  @param(c Receives the key pressed.)
  @param(itemToTake Receives the chosen item.)
  @param(cursor The highlighted item, kept between calls; receives the chosen item.)
  @param(idx The highlighted item's position, kept between calls.) }
procedure LootTakeItemSelection(var c: Char; var itemToTake, cursor: Types.PItem; var idx: Integer);
var
  head: Types.PItem;
  { Unused in this version; see the other implementations of this routine. }
  tmp: String[16];
  { Unused in this version; see the other implementations of this routine. }
  lenv: Byte;
  { Unused in this version; see the other implementations of this routine. }
  i: Byte;
  redraw: Boolean;
  redrawByte: Byte absolute redraw;
  p: Types.PItem;
begin
  redraw := True;
  Border.DrawWindowFrame(0);
  p := GDVars.treasureItems;
  while p <> nil do begin
    CharHlp.PrintItemString(nil, p, 0, 0, False, False);
    p := p^.next
  end;
  head := GDVars.treasureItems;
  MenuCore.EnableChoices(0);
  c := Char(MenuCore.MenuVertical(GDConsts.itemsQuery, GDConsts.takeMenu, 1, 1, 38, 22, head, 1, 0, redrawByte, idx,
                                  cursor));
  itemToTake := cursor
end;

{ Gives the current character copies of the picked items, removing each taken one from the treasure, until it leaves or
  the treasure is empty. }
procedure LootTakeItemMenu;
var
  itemToTake: Types.PItem;
  p: Types.PItem;
  c: Char;
  done: Boolean;
  cursor: Types.PItem;
  idx: Integer;
  failed: Boolean;
begin
  itemToTake := nil;
  cursor := GDVars.treasureItems;
  idx := 0;
  GDVars.selectedChoice := 1;
  repeat
    PostCbt.LootTakeItemSelection(c, itemToTake, cursor, idx);
    if c <> #0 then done := True
    else begin
      done := False;
      Shop.GiveItemCopyToCreature(itemToTake, failed);
      if not failed then begin
        p := GDVars.treasureItems;
        if p = itemToTake then GDVars.treasureItems := itemToTake^.next
        else begin
          while p^.next <> itemToTake do p := p^.next;
          p^.next := itemToTake^.next
        end;
        itemToTake^.next := nil;
        if itemToTake <> nil then GameIo.FreeSlot(itemToTake);
        if GDVars.treasureItems = nil then done := True
      end
    end
  until done;
  CharHlp.DisplayNoncombatInterface
end;

procedure LootTakeMenu(var coins, items: Boolean);
var
  c: Char;
  done: Boolean;
  { Unused in this version; see the other implementations of this routine. }
  ext: Boolean;
begin
  GDVars.selectedChoice := 1;
  done := False;
  if coins then begin
    if items then begin
      repeat
        MenuCore.EnableChoices(2);
        c := Char(MenuCore.MenuHorizontal(PostCbt.TAKE_BOTH_QUERY, PostCbt.TAKE_BOTH_MENU, 1, 1));
        if GDVars.menuExtendedKey <> 0 then begin
          case c of
            C_Keys.ESCAPE: done := True;
            C_Keys.UP: ViewChar.SelectAdjacentCharacter(c);
            C_Keys.DOWN: ViewChar.SelectAdjacentCharacter(c)
          end
        end else begin
          case c of
            #0: begin
              Money.TakeMoneyMenu;
              CharHlp.DisplayNoncombatInterface
            end;
            #1: PostCbt.LootTakeItemMenu;
            #2: done := True
          end
        end;
        CharHlp.DisplayParty(GDVars.currentCharacter);

          Money.DetermineTreasure(coins, items);
        if not coins or not items then done := True
      until done
    end else begin
      Money.TakeMoneyMenu;
      CharHlp.DisplayNoncombatInterface
    end
  end else PostCbt.LootTakeItemMenu
end;

{ The treasure menu: View, Take, Pool, Share and Detect (when the current character has a Detect Magic memorized and the
  treasure has items), and Exit, which asks before leaving treasure behind. }
procedure LootMenu;
var
  { Unused in this version; see the other implementations of this routine. }
  hasMoney: Boolean;
  i: Byte;
  menuState: Byte;
  c: Char;
  done: Boolean;
  changed: Boolean;
  changedByte: Byte absolute changed;
  { Unused in this version; see the other implementations of this routine. }
  itemIndex: Byte;
  detectSpell: Byte;
  hasDetect: Boolean;
  savedMenuClear: Byte;
begin
  done := False;
  CharHlp.DisplayNoncombatInterface;
  savedMenuClear := 1;
  repeat
    FillChar(GDVars.enabledChoices, SizeOf(GDVars.enabledChoices), $FF);
    Money.DetermineTreasure
      (GDVars.treasureHasMoney, GDVars.treasureHasItems);
    i := 0;
    hasDetect := False;
    if GDVars.treasureHasItems then
      if GDVars.currentCharacter^.spells <> nil then
        while (i <= 73) and not hasDetect do begin
          if (GDVars.currentCharacter^.spells^.memorized[i] = C_Spell.DETECT_MAGIC_CLERIC) or
              (GDVars.currentCharacter^.spells^.memorized[i] = C_Spell.DETECT_MAGIC_MAGE) or
              (GDVars.currentCharacter^.spells^.memorized[i] = C_Spell.DETECT_MAGIC_DRUID) or
                  (GDVars.currentCharacter^.spells^.memorized[i] = C_Spell.DETECT_MAGIC_GIFT) then
            if GDVars.currentCharacter^.enabled <> 0 then begin
              hasDetect := True;
              detectSpell := GDVars.currentCharacter^.spells^.memorized[i]
            end;
          Inc(i)
        end;
    menuState := 0;
    for i := 0 to 5 do
      case i of
        1: if GDVars.treasureHasMoney or GDVars.treasureHasItems then
            MenuCore.AppendChoice(1, menuState);
        3: if GDVars.treasureHasMoney then MenuCore.AppendChoice(3, menuState);
        4: if hasDetect then MenuCore.AppendChoice(4, menuState);
      else MenuCore.AppendChoice(i, menuState)
      end;
    GDVars.selectedChoice := savedMenuClear;
    c := Char(MenuCore.MenuHorizontal(GDConsts.emptyQuery, GDConsts.treasureMenu, 1, 1));
    savedMenuClear := GDVars.selectedChoice;
    if GDVars.menuExtendedKey <> 0 then begin
      case c of
        C_Keys.ESCAPE: c := #5;
        C_Keys.UP, C_Keys.DOWN: begin
          CharHlp.DisplayRoster(GDVars.currentCharacter, False);
          ViewChar.SelectAdjacentCharacter(c);
          CharHlp.DisplayRoster(GDVars.currentCharacter, True);
          c := #255
        end
      end
    end;
    case c of
      #0: ViewChar.ViewCharMenu(changed);
      #1: PostCbt.LootTakeMenu(GDVars.treasureHasMoney, GDVars.treasureHasItems);
      #2: Money.PoolMoney;
      #3: Money.ShareMoney;
      #4: Magic.CastSpell(detectSpell, 0, 0, changedByte);
      #5: begin

          Money.DetermineTreasure(GDVars.treasureHasMoney, GDVars.treasureHasItems);
        if GDVars.treasureHasMoney or GDVars.treasureHasItems then begin
          TextRend.DisplayMessageWindow(1, 17, 38, 22, LightGreen, Black, True, GDConsts.treasureLeft1);
          TextRend.DisplayMessageWindow(1, 17, 38, 22, White, Black, False, GDConsts.treasureLeft2);
          if MenuCore.YesNoMenu(GDConsts.emptyQuery, GDConsts.noKey) = GDConsts.noKey then done := True
          else TextRend.ClearRect(1, 17, 38, 22)
        end else done := True
      end
    end
  until done
end;

{ Removes the monsters and hostile creatures from the creature list, recording each removal as a monster killed and
  counting those out of play for the zone, and frees the combat records of the party. The first one removed raises a
  zone flag when it is out of play, and a running one sets combat result 1 when none is set. The current character
  becomes the party's first member. }
procedure PostCombatCreatureCleanup;
var
  p: Types.PCharacter;
  next: Types.PCharacter;
  first: Boolean;
begin
  first := True;
  GDVars.zone1^.monstersDef[GDConsts.monstersDefIndex + $7C00] := 0;
  p := GDVars.partyHead;
  while p <> nil do begin
    if (p^.combat^.notPcNpc = 1) or (p^.side = C_Side.ENEMY) then begin
      GDVars.monstersKilled := 1;
      if p^.enabled <> 1 then begin
        Inc(GDVars.zone1^.monstersDef[GDConsts.monstersDefIndex + $7C00]);
        if first then GDVars.zone0^.firstMonsterDown := 1
      end;
      if (p^.status = C_Status.RUNNING) and
          (GDVars.zone1^.combatResult[GDConsts.combatResultIndex + $7C00] = 0) then
        GDVars.zone1^.combatResult[GDConsts.combatResultIndex + $7C00] := 1;
      first := False;
      next := p^.next;
      GDVars.currentCharacter := p;
      CharGen.RemoveCreature(p^.combat^.notPcNpc = 1, True);
      p := next
    end else begin
      if p^.combat <> nil then begin
        FreeMem(p^.combat, SizeOf(Types.TCombat));
        p^.combat := nil
      end;
      p := p^.next
    end
  end;
  GDVars.currentCharacter := GDVars.partyHead
end;

procedure PostCombat;
var
  p: Types.PItem;
  q: Types.PItem;
  cr: Types.PCharacter;
  { Unused in this version; see the other implementations of this routine. }
  itemCount: Word;
begin
  GDVars.zone1^.combatResult[GDConsts.combatResultIndex + $7C00] := 0;
  GDVars.monstersKilled := 0;
  if GDVars.demoMode = 0 then PostCbt.DetermineCombatResults;
  GDVars.interfaceState := C_Ifc.LOOT;
  PostCbt.PostCombatCreatureCleanup;
  if GDVars.demoMode <> 0 then Exit;
  cr := GDVars.partyHead;
  while cr <> nil do begin
    CharHlp.RecalcStats(cr);
    cr := cr^.next
  end;
  if (GDVars.partyDefeated = 0) or (GDVars.duelFlag <> 0) then begin
    if GDVars.partyFled then begin
      p := GDVars.treasureItems;
      while p <> nil do begin
        q := p;
        p := p^.next;
        GameIo.FreeSlot(q)
      end;
      GDVars.treasureItems := nil
    end;
    if GDVars.demoMode = 0 then begin
      PostCbt.PostCombatSummary(GDVars.expShare);
      if GDVars.treasureHasMoney or GDVars.treasureHasItems then PostCbt.LootMenu
    end;
    p := GDVars.treasureItems;
    while p <> nil do begin
      q := p;
      p := p^.next;
      GameIo.FreeSlot(q)
    end;
    GDVars.treasureItems := nil
  end else begin
    GDVars.zone1^.combatResult[GDConsts.combatResultIndex + $7C00] := $80;
    Border.DrawWindowFrame(0);
    GDVars.currentColumn := 2;
    GDVars.currentRow := 6;
    TextRend.DisplayMessageWindow(2, 5, 37, 22, LightGreen, Black, True, PostCbt.PARTY_DESTROYED);
    TextRend.DisplayAndPause(LightMagenta, Black, PostCbt.PRESS_ANY_KEY)
  end;
  GDVars.slowText := 1;
  GDVars.zone1^.modMonThac0[GDConsts.modMonThac0Index + $7C00] := 0;
  GDVars.zone1^.modPartyThac0[GDConsts.modPartyThac0Index + $7C00] := 0;
  GDVars.zone1^.modPartyMove[GDConsts.modPartyMoveIndex + $7C00] := 0;
  GDVars.zone1^.noCombatItems[GDConsts.noCombatItemsIndex + $7C00] := 0;
  GDVars.zone1^.reviveFlag[GDConsts.reviveFlagIndex + $7C00] := 0;
  GDVars.zone0^.mirrorDuel := 0
end;
begin
end.
