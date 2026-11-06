{ Vault -- the vault: the screen where the party stores money and items between adventures. EclVm opens it. }
{$O+,F+,I-,V+}
unit Vault;
interface

{ Draws the noncombat interface and the party, and leaves if the save directory is not ready. Empties the treasure list
  and loads the vault into it (SaveLoad.LoadVault), then loops on the vault menu -- view a character, take from the
  vault, pool the party's money, drop money, open the inventory, exit -- with the up and down arrows (extended scan
  codes H and P) moving to the previous or next character. On exit it writes the vault back as tmpvault.dat, which the
  next save renames over vault<letter>.dat. }
procedure PoolVault;
implementation
uses C_Ifc, C_Keys, Types, CharHlp, SaveLoad, MenuCore, Money, ViewChar, PostCbt, TextRend, GDConsts, GDVars;

procedure PoolVault;
var
  key: Byte;
  choice: Byte;
  { Unused in this version; see the other implementations of this routine. }
  moneyAmount: Word;
  leaveMenu: Boolean;
  hasMoney: Boolean;
  hasItems: Boolean;
  { Unused in this version; see the other implementations of this routine. }
  itemCount: Word;
  choiceCount: Byte;
  done: Boolean;
  savedChoice: Byte;
  old: Types.PItem;
begin
  GDVars.interfaceState := C_Ifc.IN_VAULT; GDVars.noncombatPrepared := 1;
  CharHlp.DisplayNoncombatInterface;
  GDVars.noncombatPrepared := 1;
  CharHlp.DisplayParty(GDVars.currentCharacter);
  if not SaveLoad.CheckSaveDir then Exit;
  while GDVars.treasureItems <> nil do begin
    old := GDVars.treasureItems; GDVars.treasureItems := GDVars.treasureItems^.next; Dispose(old)
  end;
  GDVars.treasureItems := nil;
  SaveLoad.LoadVault(hasMoney, hasItems);
  GDVars.treasureActive := 0;
  leaveMenu := False; savedChoice := 1;
  repeat
    FillChar(GDVars.enabledChoices, SizeOf(GDVars.enabledChoices), 0); choiceCount := 0;
    MenuCore.AppendChoice(0, choiceCount);
    Money.DetermineTreasure(hasMoney, hasItems);
    if hasMoney or hasItems then
      MenuCore.AppendChoice(1, choiceCount);
    MenuCore.AppendChoice(2, choiceCount);
    if (GDVars.currentCharacter^.coins[4] > 0) or (GDVars.currentCharacter^.coins[5] > 0) or
        (GDVars.currentCharacter^.coins[6] > 0) then
      MenuCore.AppendChoice(3, choiceCount);
    if GDVars.currentCharacter^.items <> nil then
      MenuCore.AppendChoice(4, choiceCount);
    MenuCore.AppendChoice(5, choiceCount);
    GDVars.selectedChoice := savedChoice;
    choice := MenuCore.MenuHorizontal('', GDConsts.vaultMenu, 1, 0);
    savedChoice := GDVars.selectedChoice;
    if (GDVars.menuExtendedKey <> 0) and (choice = Ord(C_Keys.ESCAPE)) then begin
      GDVars.menuExtendedKey := 0; choice := 5
    end;
    done := False;
    if GDVars.menuExtendedKey = 0 then begin
      case choice of
        0: ViewChar.ViewCharMenu(done);
        1: PostCbt.LootTakeMenu(hasMoney, hasItems);
        2: Money.PoolMoney;
        3: begin
            ViewChar.DropMoneyMenu(False);
            TextRend.ClearRect(1, 17, 38, 22)
          end;
        4: begin
            ViewChar.UseItemMenu(done);
            CharHlp.DisplayNoncombatInterface
          end;
        5: leaveMenu := True
      end
    end else begin
      key := choice;
      if (key = Ord(C_Keys.DOWN)) or (key = Ord(C_Keys.UP)) then begin
        CharHlp.DisplayRoster(GDVars.currentCharacter, False);
        ViewChar.SelectAdjacentCharacter(Char(choice));
        CharHlp.DisplayRoster(GDVars.currentCharacter, True)
      end
    end
  until leaveMenu;
  SaveLoad.WriteVaultFile
    (GDVars.savePath + 'tmpvault.dat')
end;
begin end.
