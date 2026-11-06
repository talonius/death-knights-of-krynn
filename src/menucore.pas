{ MenuCore -- the game's menus: the horizontal menu on the bottom line (keyboard, mouse and joystick, with clicks on the
  party list, the combat map, the area map and the menu rows), the paged vertical list, the yes/no question, and the
  menu-row lists they are built from. }
{$F+,O+,S-,R-,V-,B-,I-}
unit MenuCore;
interface
uses C_Ifc, Crt, C_Keys, GDConsts, GDVars, Types, TextRend, Mouse, Border, CbtMap, GameIo,
  Joystick, Portrait;
type
  TMenuSpan = record
    first: Byte;
    last: Byte
  end;

{ Returns a row of a menu-row list by its 0-based index.
  @param(index Row index.)
  @param(head The list.)
  @returns(The row; nil past the list's end.) }
function MenuRowAt(index: Word; head: Types.PMenuRow): Types.PMenuRow;

{ Counts the rows of a menu-row list.
  @param(head The list.)
  @returns(The number of rows.) }
function MenuRowCount(head: Types.PMenuRow): Word;

{ Enables menu word ordinal as the next choice and counts it.
  @param(ordinal The menu word to enable.)
  @param(count Choices enabled so far; counted up.) }
procedure AppendChoice(ordinal: Byte; var count: Byte);

{ Enables menu words 0..maximum in order and no others.
  @param(maximum Last menu word to enable.) }
procedure EnableChoices(maximum: Byte);

{ The horizontal menu: shows query and the enabled words of menu on the bottom line and waits for a choice -- a word's
  capital, the arrows (Up and Down switch rows of a two-row menu), Enter, a mouse click on the party list, the combat or
  area map or a menu row, or the menu timeout, which answers menuTimeoutKey. Returns the chosen word's ordinal, or the
  key with menuExtendedKey set for Escape and the arrows; with allowExit the digit keys come back as arrow scan codes.
  Waits for the mouse button or joystick to be released.
  @param(query Question shown first.)
  @param(menu The menu words.)
  @param(allowExit Non-zero to return the digit keys as arrow scan codes.)
  @param(redraw Non-zero to keep the picture box animating.)
  @returns(The chosen word's ordinal, or the key with menuExtendedKey set.) }
function MenuHorizontal(query: Types.TString40; menu: String; allowExit, redraw: Byte): Byte;

{ Blanks the bottom text row. }
procedure ClearBottomLine;

{ The paged vertical menu of list in the window from (ulCol, ulRow) to (lrCol, lrRow): heading rows are drawn in the
  label color and skipped, the cursor and paging follow the keys and the mouse, and menu (with Exit when addExit is set)
  runs underneath; selected and menuIndex return the row.
  @param(query Question shown on the menu line.)
  @param(menu Menu words run underneath.)
  @param(ulCol Left column.)
  @param(ulRow Top row.)
  @param(lrCol Right column.)
  @param(lrRow Bottom row.)
  @param(list The rows.)
  @param(addExit Non-zero to offer Exit.)
  @param(choiceCount Ordinal of the last word in menu.)
  @param(redraw Non-zero to redraw the page; cleared on return.)
  @param(menuIndex The row under the cursor, kept between calls.)
  @param(selected Receives the row chosen, or nil.)
  @returns(The key or menu choice that ended the menu.) }
function MenuVertical(query: Types.TString40; menu: String; ulCol, ulRow, lrCol, lrRow: ShortInt; list: Pointer;
                      addExit: Byte; choiceCount: ShortInt; var redraw: Byte; var menuIndex: Integer;
                      var selected): Byte;

{ Asks a question with Yes and No.
  @param(query The question.)
  @param(defaultChoice 0 to highlight Yes first, 1 for No.)
  @returns(0 for Yes, 1 for No.) }
function YesNoMenu(query: Types.TString40; defaultChoice: Byte): Byte;

{ Allocates a list of empty members, as many as asked; the first is allocated before the count is read, so a count below
  1 gives one member.
  @param(count Members wanted.)
  @param(head Receives the first member.) }
procedure AllocStringList(count: Integer; var head: Types.PMenuRow);

{ Frees every row of the list; head is left as it was.
  @param(head The list.) }
procedure FreeMenuRows(var head: Types.PMenuRow);
implementation
const
  { a menu's no-selection result }
  KEY_NONE = #0;

function MenuRowAt(index: Word; head: Types.PMenuRow): Types.PMenuRow;
var
  node: Types.PMenuRow;
  count: Word;
begin
  count := 0;
  node := head;
  while (node <> nil) and (count <> index) do begin
    node := node^.next;
    Inc(count)
  end;
  if count = index then
    MenuRowAt := node
  else
    MenuRowAt := nil
end;

function MenuRowCount(head: Types.PMenuRow): Word;
var
  node: Types.PMenuRow;
  count: Word;
begin
  count := 0;
  node := head;
  while node <> nil do begin
    Inc(count);
    node := node^.next
  end;
  MenuRowCount := count
end;

procedure AppendChoice(ordinal: Byte; var count: Byte);
begin
  GDVars.enabledChoices[count].ordinal := ordinal;
  Inc(count)
end;

procedure EnableChoices(maximum: Byte);
var
  index: Byte;
begin
  FillChar(GDVars.enabledChoices, SizeOf(GDVars.enabledChoices), $FF);
  for index := 0 to maximum do
    GDVars.enabledChoices[index].ordinal := index
end;

function MenuHorizontal(query: Types.TString40; menu: String; allowExit, redraw: Byte): Byte;
var
  frameTick: LongInt;
  cursorOnTick: LongInt;
  { Unused in this version; see the other implementations of this routine. }
  cursorOffTick: LongInt;
  key: Char;
  mouseCol: Integer;
  mouseRow: Integer;
  scan: Byte;
  { Unused in this version; see the other implementations of this routine. }
  mouseClicked: Byte;
  done: Boolean;
  menuLength: Byte;
  queryLength: Byte;
  { [0].last counts them, [0].first says the menu is colored }
  spans: array[0..20] of TMenuSpan;
  node: Types.PCharacter;
  buttons: Integer;
  originX: Integer;
  originY: Integer;
  twoRows: Byte;
  menuRow: Byte;
  firstRowSpans: Byte;
  workMenu: String;
  { [2] the key mapped through enabledChoices; [1] set when a timeout answers with it }
  forcedKey: array[1..2] of Byte;

  { Finds each menu word's first and last character in workMenu, and where a two-row menu's second row starts. }
  procedure BuildSpans;
  var
    span: Byte;
    index: Byte;
    len: Byte;
  begin
    FillChar(spans[1], SizeOf(spans) - SizeOf(spans[0]), 0);
    span := 1;
    len := Length(workMenu);
    for index := 1 to len do
      if workMenu[index] in ['0'..'9', 'A'..'Z'] then begin
        if spans[span].first = 0 then
          spans[span].first := index
        else begin
          spans[span].last := index - 2;
          Inc(span);
          spans[span].first := index
        end
      end else if workMenu[index] = '@' then
        firstRowSpans := span;
    spans[span].last := len;
    spans[0].last := span
  end;

  { Draws the menu words, the current one highlighted. }
  procedure DisplayOption(current: Byte);
  var
    column: Byte;
    row: Byte;
    index: Byte;
  begin
    Mouse.HideMouse;
    column := 1;
    row := menuRow;
    if menuLength > 0 then
      for index := 1 to menuLength do begin
        if workMenu[index] = '@' then begin
          Border.ClearBox(queryLength + column - 1, row, 39, row);
          Inc(row);
          column := 1
        end else begin
          if (spans[current].first <= index) and (spans[current].last >= index) and
              (GDVars.menuHighlightColor <> 0) then
            TextRend.RenderChar(queryLength + column - 1, row, Black, GDVars.menuHighlightColor, 1,
                                Ord(workMenu[index]), GDConsts.asciiFlag)
          else if workMenu[index] in ['0'..'9', 'A'..'Z'] then
            TextRend.RenderChar(queryLength + column - 1, row, GDVars.menuHighlightColor, Black, 1,
                                Ord(workMenu[index]), GDConsts.asciiFlag)
          else
            TextRend.RenderChar(queryLength + column - 1, row, GDVars.menuItemColor, Black, 1, Ord(workMenu[index]),
                                GDConsts.asciiFlag);
          Inc(column)
        end
      end;
    if queryLength + column - 1 <= 39 then
      Border.ClearBox(queryLength + column - 1, row, 39, row);
    Mouse.ShowMouse
  end;

  { Answers with the current option's key (Enter for an empty one) and finishes. }
  procedure AcceptCurrent;
  begin
    GDVars.menuExtendedKey := 0;
    key := workMenu[spans[GDVars.selectedChoice].first];
    if key = #0 then
      key := C_Keys.ENTER;
    done := True
  end;

  { Tells whether the click falls on the party list and party clicks are allowed on this screen. }
  function PartyClick: Boolean;
  begin
    PartyClick := (GDVars.mouseMode <> 0) and
      not ((GDVars.interfaceState = C_Ifc.OVERLAND) and (GDVars.zone0^.wildOn = 1)) and
      not ((GDVars.extendedMode <> 0) and (GDVars.interfaceState = C_Ifc.VIEW_3D)) and
      (GDVars.interfaceState <> C_Ifc.IN_COMBAT) and (GDVars.partyPanelLeft <= mouseCol) and
      (GDVars.partyPanelRight >= mouseCol) and (GDVars.partyPanelTop <= mouseRow) and
      (GDVars.partyPanelBottom >= mouseRow)
  end;

  { Selects the clicked member, or accepts the current word when it is already selected. }
  procedure HandlePartyClick;
  var
    index: Byte;
  begin
    scan := mouseRow - GDVars.partyPanelTop;
    node := GDVars.partyHead;
    for index := 1 to scan do
      if node <> nil then
        node := node^.next;
    if node <> nil then
      if ((node <> GDVars.currentCharacter) and (GDVars.selectionMode = 0)) or
          ((node <> GDVars.selectionCharacter) and (GDVars.selectionMode <> 0)) then begin
        if GDVars.selectionMode <> 0 then
          GDVars.selectionCharacter := node
        else
          GDVars.mouseCharacter := node;
        key := C_Keys.UP;
        GDVars.menuExtendedKey := 1;
        done := True;
        Exit
      end;
    if (node <> nil) and ((node = GDVars.currentCharacter) or (node = GDVars.selectionCharacter)) then
      AcceptCurrent
  end;

  { Tells whether, in combat, the click falls inside the arena while the player is moving a combatant or aiming. }
  function ArenaClick: Boolean;
  begin
    ArenaClick := ((GDVars.inMoveMenu <> 0) or (GDVars.cursorActive <> 0)) and
      (GDVars.interfaceState = C_Ifc.IN_COMBAT) and (mouseCol >= 1) and (mouseCol <= 21) and (mouseRow >= 1) and
      (mouseRow <= 21)
  end;

  { Turns an arena click into the movement key toward the clicked cell, from the aim cursor or the combatant. }
  procedure HandleArenaClick;
  begin
    GDVars.menuExtendedKey := 1;
    if GDVars.cursorActive <> 0 then begin
      originX := GDVars.cursorX - GDVars.arena^.ox + 1;
      originY := GDVars.cursorY - GDVars.arena^.oy + 1
    end else begin
      scan := CbtMap.CombatSlot(GDVars.currentCharacter);
      originX := GDVars.arenaLoc[scan].x - GDVars.arena^.ox + 1;
      originY := GDVars.arenaLoc[scan].y - GDVars.arena^.oy + 1
    end;
    key := Chr(Mouse.MouseDirection(originX, originY, mouseCol div 3 + 1, mouseRow div 3 + 1));
    done := True
  end;

  { Tells whether the click falls inside the 3-D view and view clicks are enabled. }
  function ViewAreaClick: Boolean;
  begin
    ViewAreaClick := (GDVars.extendedMode <> 0) and (mouseCol >= 3) and (mouseCol <= 13) and (mouseRow >= 3)
        and (mouseRow <= 13) and (GDVars.interfaceState = C_Ifc.VIEW_3D)
  end;

  { Turns the click on the 3-D view into a direction key. }
  procedure HandleAreaMapClick;
  begin
    GDVars.menuExtendedKey := 1;
    key := Chr(GDConsts.directionKeys[mouseRow, mouseCol]);
    done := True
  end;

  { Tells whether the click is on the overland map while the arrow row is up. }
  function WildernessClick: Boolean;
  begin
    WildernessClick := (GDVars.extendedMode <> 0) and (GDVars.zone0^.inDungeon = 0) and
        (GDVars.interfaceState = C_Ifc.OVERLAND) and (mouseCol >= 1) and
      (mouseCol <= 38) and (mouseRow >= 1) and (mouseRow <= 15)
  end;

  { Turns the click on the overland map into a direction key. }
  procedure HandleWildernessClick;
  begin
    GDVars.menuExtendedKey := 1;
    key := Chr(Mouse.MouseDirection(GDVars.zone0^.wildX + 1, GDVars.zone0^.wildY + 1, mouseCol, mouseRow));
    done := True
  end;

  { Tells whether the click is on the menu line. }
  function MenuRowClicked: Boolean;
  begin
    MenuRowClicked := (menuRow <= mouseRow) and (not done)
  end;

  { Chooses the option under the clicked column, recording whether it was not already highlighted. }
  procedure HandleMenuRowClick;
  var
    current: Byte;
  begin
    Inc(mouseCol);
    if queryLength < mouseCol then begin
      mouseCol := mouseCol - queryLength;
      if twoRows <> 0 then
        if menuRow < mouseRow then
          Inc(mouseCol, Pos('@', workMenu))
        else if Pos('@', workMenu) <= mouseCol then
          Exit;
      for current := 1 to spans[0].last do
        if (spans[current].first <= mouseCol) and (spans[current].last >= mouseCol) then begin
          key := workMenu[spans[current].first];
          if current = GDVars.selectedChoice then
            GDVars.menuClickChanged := 0
          else
            GDVars.menuClickChanged := 1;
          GDVars.selectedChoice := current;
          DisplayOption(GDVars.selectedChoice);
          done := True
        end
    end
  end;

  { Tells whether a click could be on the modify screen's fields. }
  function ModifyScreenClicked: Boolean;
  begin
    ModifyScreenClicked := (GDVars.modifyActive <> 0) and (not done)
  end;

  { On the modify-character screen, reports the field clicked and returns the Home key. }
  procedure HandleModifyClick;
  begin
    done := True;
    case mouseRow of
      1:
        if (mouseCol >= 1) and (mouseCol <= 16) then
          GDVars.modifyMouseRow := 6;
      3:
        if (mouseCol >= 31) and (mouseCol <= 33) then
          GDVars.modifyMouseRow := 7;
      9..14: begin
        if (mouseCol >= 5) and (mouseCol <= 9) then
          GDVars.modifyMouseRow := mouseRow - 9
      end else
        done := False
    end;
    GDVars.menuExtendedKey := 1;
    key := C_Keys.HOME
  end;

  { Tells whether the click is within a vertical menu's columns. }
  function VerticalMenuClicked: Boolean;
  begin
    VerticalMenuClicked := (not done) and (GDVars.verticalMenuLeft <= mouseCol) and
      (GDVars.verticalMenuRight >= mouseCol)
  end;

  { Chooses the highlighted option on a click on a list row, and flags the click for the vertical menu. }
  procedure HandleHotspotClick;
  begin
    scan := 1;
    GDVars.menuClickChanged := 1;
    while (scan <= 25) and (GDVars.menuHotRows[scan] <> 255) and (not done) do begin
      if GDVars.menuHotRows[scan] <= mouseRow then
        done := True;
      Inc(scan)
    end;
    if done then
      AcceptCurrent
  end;

  { Highlights the previous option, wrapping to the last. }
  procedure MoveLeft;
  begin
    if GDVars.selectedChoice = 1 then
      GDVars.selectedChoice := spans[0].last
    else
      Dec(GDVars.selectedChoice);
    DisplayOption(GDVars.selectedChoice);
    done := False
  end;

  { Highlights the next option, wrapping to the first. }
  procedure MoveRight;
  begin
    if GDVars.selectedChoice = spans[0].last then
      GDVars.selectedChoice := 1
    else
      Inc(GDVars.selectedChoice);
    DisplayOption(GDVars.selectedChoice);
    done := False
  end;

  { Moves to the other line of a two-line menu, clamped to its options. }
  procedure MoveVertical;
  begin
    if GDVars.selectedChoice <= firstRowSpans then begin
      Inc(GDVars.selectedChoice, firstRowSpans);
      if GDVars.selectedChoice > spans[0].last then
        GDVars.selectedChoice := spans[0].last
    end else begin
      Dec(GDVars.selectedChoice, firstRowSpans);
      if GDVars.selectedChoice > firstRowSpans then
        GDVars.selectedChoice := firstRowSpans
    end;
    DisplayOption(GDVars.selectedChoice);
    done := False
  end;

  { Builds workMenu from a menu, keeping the registered options and recording each one's hotkey in the slot table. }
  procedure NormalizeMenu;
  var
    { Unused in this version; see the other implementations of this routine. }
    firstChar: Byte;
    ordinal: Byte;
    startAt: Byte;
    { Unused in this version; see the other implementations of this routine. }
    lastChar: Byte;
    index: Byte;
    slot: Byte;
    len: Byte;
  begin
    len := Length(menu);
    workMenu := '';
    slot := 0;
    ordinal := 0;
    index := 1;
    while index <= len do begin
      if menu[index] in ['0'..'9', 'A'..'Z'] then begin
        if GDVars.enabledChoices[slot].ordinal = ordinal then begin
          GDVars.enabledChoices[slot].key := menu[index];
          startAt := index;
          Inc(index);
          while not (menu[index] in ['0'..'9', 'A'..'Z']) and (index <= len) do
            Inc(index);
          workMenu := workMenu + Copy(menu, startAt, index - startAt);
          Inc(slot)
        end else
          Inc(index);
        Inc(ordinal)
      end else
        Inc(index)
    end;
    len := Length(workMenu);
    if workMenu[len] = ' ' then
      Delete(workMenu, len, 1)
  end;

  { Returns the registered choice for the key pressed, a special key's own code, or $FF when no hotkey matches. }
  function MapMenuKey: Byte;
  var
    index: Byte;
  begin
    if GDVars.menuExtendedKey <> 0 then
      MapMenuKey := Ord(key)
    else begin
      index := 0;
      while (index < 20) and (GDVars.enabledChoices[index].key <> key) do
        Inc(index);
      if index < 20 then
        MapMenuKey := GDVars.enabledChoices[index].ordinal
      else
        MapMenuKey := 255
    end
  end;
begin
  forcedKey[1] := 0;
  NormalizeMenu;
  if Pos('@', workMenu) > 0 then begin
    twoRows := 1;
    menuRow := 23
  end else begin
    twoRows := 0;
    menuRow := 24
  end;
  GDVars.menuExtendedKey := 0;
  spans[0].first := Ord((GDVars.menuItemColor <> 0) or (GDVars.menuHighlightColor <> 0));
  queryLength := Length(query) + 0;
  BuildSpans;
  if (GDVars.selectedChoice > spans[0].last) or (GDVars.selectedChoice = 0) then
    GDVars.selectedChoice := 1;
  menuLength := Length(workMenu);
  key := MenuCore.KEY_NONE;
  done := False;
  frameTick := TextRend.GetTicks;
  cursorOnTick := TextRend.GetTicks + 30;
  cursorOffTick := cursorOnTick + 50;
  if Length(query) <> 0 then
    TextRend.DisplayString(0, 24, GDVars.menuLabelColor, Black, query);
  DisplayOption(GDVars.selectedChoice);
  if (redraw <> 0) and (GDVars.portraitAnimation.currentFrame > 0) then begin
    Portrait.DisplayImageBuf(3, 3, Boolean(redraw),
                             GDVars.portraitAnimation.frames[GDVars.portraitAnimation.currentFrame].pic);
    if GDVars.portraitAnimation.count < 2 then
      redraw := 0
  end;
  repeat
  if (redraw <> 0) and (GDVars.portraitAnimation.currentFrame > 0) and
      (TextRend.GetTicks -
       frameTick >= GDVars.portraitAnimation.frames[GDVars.portraitAnimation.currentFrame].duration * 10) then begin
    Inc(GDVars.portraitAnimation.currentFrame);
    if GDVars.portraitAnimation.currentFrame > GDVars.portraitAnimation.count then
      GDVars.portraitAnimation.currentFrame := 1;
    Portrait.DisplayImageBuf(3, 3, Boolean(redraw),
                             GDVars.portraitAnimation.frames[GDVars.portraitAnimation.currentFrame].pic);
    frameTick := TextRend.GetTicks;
    if GDVars.portraitAnimation.frames[GDVars.portraitAnimation.currentFrame].duration = 99 then
      redraw := 0
  end;
  if (GDVars.menuTimeout > 0) and (TextRend.GetTicks - frameTick >= GDVars.menuTimeout) then begin
    forcedKey[2] := GDVars.menuTimeoutKey;
    forcedKey[1] := 1;
    done := True
  end;
  if GameIo.InputPending then begin
    key := GameIo.ReadGameKey;
    if key = #0 then begin
      key := GameIo.ReadGameKey;
      GDVars.menuExtendedKey := 1;
      done := True;
      if spans[0].last > 1 then
        case key of
          C_Keys.LEFT: MoveLeft;
          C_Keys.RIGHT: MoveRight;
          C_Keys.UP, C_Keys.DOWN:
            if twoRows <> 0 then
              MoveVertical
        end
    end else begin
      GDVars.menuExtendedKey := 0;
      case key of
        C_Keys.ESCAPE: begin
          GDVars.menuExtendedKey := 1;
          done := True
        end;
        C_Keys.ENTER: begin
          if GDVars.mouseClick <> 0 then begin
            mouseRow := GDVars.mouseRawY div 8;
            mouseCol := GDVars.mouseRawX div 8;
            if PartyClick then
              HandlePartyClick
            else if ArenaClick then
              HandleArenaClick
            else if ViewAreaClick then
              HandleAreaMapClick
            else if WildernessClick then
              HandleWildernessClick
            else if MenuRowClicked then
              HandleMenuRowClick
            else if ModifyScreenClicked then
              HandleModifyClick
            else if VerticalMenuClicked then
              HandleHotspotClick
            else if (GDVars.interfaceState = C_Ifc.IN_COMBAT) and (mouseRow <= 22) then begin
              if twoRows <> 0 then begin
                  key := #84;
                  done := True
              end else if query = 'Aim:' then begin
                key := #77;
                done := True
              end
            end else if spans[0].last > 1 then begin
              GDVars.menuExtendedKey := 1;
              key := C_Keys.ESCAPE
            end else
              done := True
          end else
            AcceptCurrent
        end;
        else begin
          key := UpCase(key);
          forcedKey[2] := MapMenuKey;
          if forcedKey[2] <> 255 then
            for scan := 1 to menuLength do
              if workMenu[scan] = key then begin
                done := True;
                mouseCol := 1;
                while scan <> spans[mouseCol].first do
                  Inc(mouseCol);
                GDVars.selectedChoice := mouseCol;
                DisplayOption(GDVars.selectedChoice)
              end;
          if (not done) and (spans[0].last > 1) then
            if key = #52 then
              MoveLeft
            else if key = #54 then
              MoveRight
            else if (key in [#50, #56, #72, #80]) and (twoRows <> 0) then
              MoveVertical;
          if (allowExit <> 0) and (key in ['1'..'9', '\']) then begin
            if key = '\' then
              key := '7'
            else
              key := Chr(GDConsts.digitKeys[Ord(key) - Ord('1')]);
            forcedKey[2] := Ord(key);
            GDVars.menuExtendedKey := 1;
            done := True
          end
        end
      end
    end
  end;
  until done;
  if forcedKey[1] <> 0 then
    MenuHorizontal := forcedKey[2]
  else
    MenuHorizontal := MapMenuKey;
  GameIo.FlushKeys;
  if GDVars.mouseClick <> 0 then
    repeat
      Mouse.GetMouse(buttons, originX, originY)
    until buttons = 0
  else if GDVars.joystickActive <> 0 then
    repeat
      Joystick.GetJoystick(buttons, scan)
    until buttons = 0
end;

procedure ClearBottomLine;
begin
  TextRend.PrintSpaces(0, 24, Black, 40)
end;

function MenuVertical(query: Types.TString40; menu: String; ulCol, ulRow, lrCol, lrRow: ShortInt; list: Pointer;
                      addExit: Byte; choiceCount: ShortInt; var redraw: Byte; var menuIndex: Integer;
                      var selected): Byte;
var
  width: Byte;
  line: Byte;
  count: Integer;
  rows: Integer;
  ch: Char;
  key: Char;
  menuLine: String;
  hasNext: Boolean;
  hasPrevious: Boolean;
  node: Types.PMenuRow;
  headerCount: Integer;
  total: Integer;
  mouseCol: Byte;
  mouseRow: Byte;
  menuChoiceCount: Byte;
  previousChoice: Byte;
  nextChoice: Byte;
  exitChoice: Byte;
  clickedIndex: Byte;

  { Returns the last heading row before row n of a list, or the list itself when it starts with one. }
  function LastLabelBefore(n: Integer; l: Types.PMenuRow): Types.PMenuRow;
  var
    node: Types.PMenuRow;
    found: Types.PMenuRow;
    index: Integer;
  begin
    index := 0;
    node := l;
    found := nil;
    while (node <> nil) and (index < n) do begin
      if node^.heading <> 0 then
        found := node;
      node := node^.next;
      Inc(index)
    end;
    if (found = nil) and (l^.heading <> 0) then
      LastLabelBefore := l
    else
      LastLabelBefore := found
  end;

  { Draws the page of rows from top and records each row's screen line for clicks. }
  procedure DrawPage(top: Integer);
  var
    node: Types.PMenuRow;
    { Unused in this version; see the other implementations of this routine. }
    labelNode: Types.PMenuRow;
    row: ShortInt;
  begin
    FillChar(GDVars.menuHotRows[1], SizeOf(GDVars.menuHotRows), $FF);
    Border.ClearBox(ulCol, ulRow, lrCol, lrRow);
    Mouse.HideMouse;
    node := MenuCore.MenuRowAt(top, Types.PMenuRow(list));
    labelNode := LastLabelBefore(top, Types.PMenuRow(list));
    row := ulRow;
    line := 1;
    while (node <> nil) and (row <= lrRow) do begin
      GDVars.menuHotRows[line] := row;
      if node^.heading <> 0 then
        TextRend.DisplayString(ulCol, row, GDVars.menuLabelColor, Black, node^.name)
      else
        TextRend.DisplayString(ulCol, row, GDVars.menuItemColor, Black, node^.name);
      if Length(node^.name) < width then
        TextRend.RenderChar(ulCol + Length(node^.name), row, Black, Black, width - Length(node^.name), 32, 1);
      node := node^.next;
      Inc(row);
      Inc(line)
    end;
    Mouse.ShowMouse
  end;

  { Returns the position of the first non-blank character of a row name. }
  function FirstNonBlank(value: Types.TString40): Byte;
  var
    index: Byte;
    lengthValue: Byte;
  begin
    index := 1;
    lengthValue := Length(value);
    while (index < lengthValue) and (value[index] = ' ') do
      Inc(index);
    FirstNonBlank := index
  end;

  { Returns the position of the last non-blank character of a row name. }
  function LastNonBlank(value: Types.TString40): Byte;
  var
    index: Byte;
  begin
    index := Length(value);
    while (index > 1) and (value[index] = ' ') do
      Dec(index);
    LastNonBlank := index
  end;

  { Draws a row highlighted. }
  procedure HighlightLine(index: Integer);
  var
    node: Types.PMenuRow;
    first: Byte;
    last: Byte;
  begin
    node := MenuCore.MenuRowAt(index, Types.PMenuRow(list));
    first := FirstNonBlank(node^.name);
    last := LastNonBlank(node^.name) - first + 1;
    TextRend.DisplayString(ulCol + first - 1, ulRow + (index - GDVars.menuVerticalTop), Black,
                           GDVars.menuHighlightColor, Copy(node^.name, first, last))
  end;

  { Draws a row in the item color. }
  procedure UnhighlightLine(index: Integer);
  var
    node: Types.PMenuRow;
    first: Byte;
    last: Byte;
  begin
    node := MenuCore.MenuRowAt(index, Types.PMenuRow(list));
    first := FirstNonBlank(node^.name);
    last := LastNonBlank(node^.name) - first + 1;
    if node^.heading <> 0 then
      TextRend.DisplayString(ulCol + first - 1, ulRow + (index - GDVars.menuVerticalTop), GDVars.menuItemColor,
                             Black, Copy(node^.name, first, last))
    else
      TextRend.DisplayString(ulCol + first - 1, ulRow + (index - GDVars.menuVerticalTop), GDVars.menuItemColor,
                             Black, Copy(node^.name, first, last))
  end;

  { Moves the cursor past heading rows in a direction, wrapping within the page. }
  procedure SkipLabels(down: Boolean);
  var
    skipped: Integer;
  begin
    skipped := 0;
    if down then begin
      while (skipped < rows) and (MenuCore.MenuRowAt(menuIndex, Types.PMenuRow(list))^.heading <> 0) do begin
        Inc(skipped);
        Inc(menuIndex);
        if GDVars.menuVerticalTop + rows - 1 < menuIndex then
          menuIndex := GDVars.menuVerticalTop
      end
    end else
      while (skipped < rows) and (MenuCore.MenuRowAt(menuIndex, Types.PMenuRow(list))^.heading <> 0) do begin
        Inc(skipped);
        Dec(menuIndex);
        if menuIndex < GDVars.menuVerticalTop then
          menuIndex := GDVars.menuVerticalTop + rows - 1
      end
  end;

  { Pages the list up or down and redraws it. }
  procedure MovePage(down: Boolean);
  var
    relativeIndex: Integer;
  begin
    relativeIndex := menuIndex - GDVars.menuVerticalTop;
    if down then begin
      Inc(GDVars.menuVerticalTop, rows);
      if count - rows < GDVars.menuVerticalTop then
        GDVars.menuVerticalTop := count - rows
    end else begin
      Dec(GDVars.menuVerticalTop, rows);
      if GDVars.menuVerticalTop < 0 then
        GDVars.menuVerticalTop := 0
    end;
    menuIndex := GDVars.menuVerticalTop + relativeIndex;
    SkipLabels(down);
    DrawPage(GDVars.menuVerticalTop)
  end;

  { Moves the cursor a row up or down, wrapping within the page and skipping headings. }
  procedure MoveLine(down: Boolean);
  var
    { Unused in this version; see the other implementations of this routine. }
    node: Types.PMenuRow;
    { Unused in this version; see the other implementations of this routine. }
    skipped: Integer;
    { Unused in this version; see the other implementations of this routine. }
    index: Integer;
  begin
    if down then begin
      Inc(menuIndex);
      if GDVars.menuVerticalTop + rows - 1 < menuIndex then
        menuIndex := GDVars.menuVerticalTop
    end else begin
      Dec(menuIndex);
      if menuIndex < GDVars.menuVerticalTop then
        menuIndex := GDVars.menuVerticalTop + rows - 1
    end;
    SkipLabels(down)
  end;

  { Returns the highlighted line as the selection, with the key that chose it. }
  procedure SelectLine;
  begin
    Pointer(selected) := MenuCore.MenuRowAt(menuIndex, Types.PMenuRow(list));
    MenuVertical := Ord(ch);
    GDVars.verticalMenuLeft := 127;
    GDVars.verticalMenuRight := -128
  end;
begin
  if list = nil then begin
    menuIndex := 0;
    Pointer(selected) := nil;
    GDVars.verticalMenuLeft := 127;
    GDVars.verticalMenuRight := -128;
    MenuVertical := 0
  end else begin
    GDVars.verticalMenuLeft := ulCol;
    GDVars.verticalMenuRight := lrCol;
    width := lrCol - ulCol + 1;
    count := MenuCore.MenuRowCount(Types.PMenuRow(list));
    rows := lrRow - ulRow + 1;
    node := Types.PMenuRow(list);
    headerCount := 0;
    while (node <> nil) and (node^.heading <> 0) do begin
      node := node^.next;
      Inc(headerCount)
    end;
    node := Types.PMenuRow(list);
    total := 0;
    while node <> nil do begin
      node := node^.next;
      Inc(total)
    end;
    if total <= rows then
      GDVars.menuVerticalTop := 0;
    if GDVars.menuVerticalTop > menuIndex then begin
      GDVars.menuVerticalTop := menuIndex;
      redraw := 1
    end;
    if GDVars.menuVerticalTop > total then begin
      GDVars.menuVerticalTop := 0;
      redraw := 1
    end;
    Inc(menuIndex);
    MoveLine(False);
    if redraw <> 0 then
      DrawPage(GDVars.menuVerticalTop);
    redraw := 0;
    repeat
      GDVars.menuClickChanged := 0;
      HighlightLine(menuIndex);
      menuLine := menu;
      hasNext := False;
      hasPrevious := False;
      menuChoiceCount := choiceCount + 1;
      if (not hasNext) and hasPrevious and (GDVars.selectedChoice > 1) then
        Inc(GDVars.selectedChoice);
      if count - rows > GDVars.menuVerticalTop then begin
        menuLine := menuLine + GDConsts.menuNextText;
        nextChoice := menuChoiceCount;
        MenuCore.AppendChoice(menuChoiceCount, menuChoiceCount);
        hasNext := True
      end;
      if GDVars.menuVerticalTop > headerCount then begin
        menuLine := menuLine + GDConsts.menuPrevText;
        previousChoice := menuChoiceCount;
        MenuCore.AppendChoice(menuChoiceCount, menuChoiceCount);
        hasPrevious := True
      end;
      if addExit <> 0 then begin
        menuLine := menuLine + GDConsts.menuExitText;
        exitChoice := menuChoiceCount;
        MenuCore.AppendChoice(menuChoiceCount, menuChoiceCount)
      end;
      ch := Chr(MenuCore.MenuHorizontal(query, menuLine, 1, 0));
      key := ch;
      if (GDVars.menuExtendedKey = 0) and (Ord(ch) > choiceCount) then begin
        GDVars.menuExtendedKey := 1;
        if (Ord(ch) = nextChoice) and hasNext then
          key := C_Keys.PAGE_DOWN
        else if (Ord(ch) = previousChoice) and hasPrevious then
          key := C_Keys.PAGE_UP
        else if Ord(ch) = exitChoice then
          key := C_Keys.ESCAPE
        else
          GDVars.menuExtendedKey := 0
      end;
      UnhighlightLine(menuIndex);
      if GDVars.menuExtendedKey <> 0 then begin
        case key of
          C_Keys.UP: MoveLine(False);
          C_Keys.DOWN: MoveLine(True);
          C_Keys.PAGE_UP: if hasPrevious then MovePage(False);
          C_Keys.PAGE_DOWN: if hasNext then MovePage(True);
          'P': MovePage(False);
          'N': MovePage(True);
          C_Keys.ESCAPE, 'E', #0: begin
            Pointer(selected) := nil;
            MenuVertical := Ord(C_Keys.ESCAPE);
            GDVars.verticalMenuLeft := 127;
            GDVars.verticalMenuRight := -128;
            Exit
          end
        end
      end else if (GDVars.mouseClick <> 0) and (GDVars.menuClickChanged <> 0) then begin
        mouseRow := GDVars.mouseRawY div 8;
        mouseCol := GDVars.mouseRawX div 8;
        if (mouseCol >= GDVars.verticalMenuLeft) and (mouseCol <= GDVars.verticalMenuRight) then begin
          line := 1;
          while (line <= 25) and (GDVars.menuHotRows[line] <> 255) do begin
            if GDVars.menuHotRows[line] = mouseRow then begin
              clickedIndex := line - 1 + GDVars.menuVerticalTop;
              if clickedIndex = menuIndex then begin
                SelectLine;
                Exit
              end else begin
                UnhighlightLine(menuIndex);
                menuIndex := line - 1 + GDVars.menuVerticalTop;
                HighlightLine(menuIndex)
              end
            end;
            Inc(line)
          end
        end
      end else begin
        SelectLine;
        Exit
      end
    until False
  end
end;

function YesNoMenu(query: Types.TString40; defaultChoice: Byte): Byte;
var
  choice: Byte;
begin
  GDVars.selectedChoice := defaultChoice + 1;
  MenuCore.EnableChoices(1);
  repeat
    choice := MenuCore.MenuHorizontal(query, GDConsts.yesNoOptions, 0, 0)
  until (choice >= 0) and (choice < 2);
  YesNoMenu := choice
end;

procedure AllocStringList(count: Integer; var head: Types.PMenuRow);
var
  node: Types.PMenuRow;
  index: Integer;
begin
  GetMem(head, SizeOf(Types.TMenuRow));
  head^.next := nil;
  head^.heading := 0;
  head^.name := '';
  node := head;
  for index := 2 to count do begin
    GetMem(node^.next, SizeOf(Types.TMenuRow));
    node := node^.next;
    node^.next := nil;
    node^.heading := 0;
    node^.name := ''
  end
end;

procedure FreeMenuRows(var head: Types.PMenuRow);
var
  node: Types.PMenuRow;
  nextNode: Types.PMenuRow;
begin
  node := head;
  while node <> nil do begin
    nextNode := node;
    node := node^.next;
    FreeMem(nextNode, SizeOf(Types.TMenuRow))
  end
end;
begin
end.
