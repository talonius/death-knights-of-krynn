{ Seeds GDVars.debugPassword, the command-line password, with item name 41 ('Helm'). Explore compares it with
  ParamStr(2) to let the automap toggle in a locked area, and CbtActs to let the Gods intervene in combat. }
unit ModeInit;
interface
implementation
uses GDConsts, GDVars;
const
  { 'Helm' in the item-name table. }
  DEBUG_PASSWORD_NAME_ID = 41;
begin
  GDVars.debugPassword := GDConsts.itemNameParts[ModeInit.DEBUG_PASSWORD_NAME_ID];
end.
