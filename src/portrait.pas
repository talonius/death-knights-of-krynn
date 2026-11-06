{ Portrait -- the picture window: loading and freeing the animations the picture box holds (the encounter pictures and
  sprites), drawing a frame, and the full-screen BIGPIC. }
{$O+,F+,I-}
unit Portrait;
interface
uses GDConsts, GDVars, Crt, Blit, Mouse, TextRend, DaxIo, GameIo, Border, Types;

{ Shows a picture at a character cell with the mouse cursor hidden: an animation frame is drawn clipped into the view
  buffer one cell up and left and the view flushed to the screen, any other picture is drawn straight to the screen.
  Nothing happens for nil.
  @param(col Character column.)
  @param(row Character row.)
  @param(anim True to draw through the view buffer.)
  @param(pic The picture.) }
procedure DisplayImageBuf(col, row: Integer; anim: Boolean; pic: Types.PImgBuf);

{ Loads picture picId of archive name into a, unless that picture is the one last loaded or picId is 255, showing the
  loading message while animations are enabled. SPRIT and PIC pictures listed below come from disks 4 to 7, everything
  else from the current disk's archive; a missing one reports 'PIC not found'. Each frame is a 4-byte header, its height
  and width, origin, an 8-byte map and the pixels; a PIC's later frames are XOR deltas against its first, and with
  animations off a PIC loads its first frame only. A frame is skipped when less than 3900 bytes are free, and count ends
  as the number loaded. Transparent sprites are remapped outside CGA mode. EclVm, EclMenu, CharHlp and Camp call it.
  @param(name Archive name, without the disk digit and extension.)
  @param(picId Picture block; 255 loads nothing.)
  @param(transp Bit 0 gives each frame a mask for color 0 and remaps it outside CGA.)
  @param(a Animation receiving the frames.) }
procedure LoadAnimation(name: Types.TString8; picId, transp: Byte; var a: Types.TAnimRec);

{ Frees each frame of an animation record, clears the record and forgets the last loaded picture.
  @param(a The animation record.) }
procedure FreeAnimation(var a: Types.TAnimRec);

{ Draws a 3D sprite frame transparently into the view buffer at its origin and flushes the view. A distance outside 1 to
  3 restores the video mode, prints an error and exits to DOS.
  @param(dist The view distance, 1 to 3, which is also the frame drawn.)
  @param(a The sprite's animation record; a missing frame draws nothing.) }
procedure Show3DSprite(dist: Byte; a: Types.TAnimRec);

{ Frees the picture box's animation, then, unless id is already loaded, loads it from the current disk's BIGPIC archive
  (BIGPIC1.DAX on disk 5) with the loading message. EclVm, MapView and SaveLoad call it.
  @param(id BIGPIC block to load.) }
procedure LoadBigPic(id: Byte);

{ Draws the window frame with its row divider and shows the big picture at cell (1, 1), with the mouse cursor hidden. }
procedure DisplayBigPic;
implementation

procedure DisplayImageBuf(col, row: Integer; anim: Boolean; pic: Types.PImgBuf);
begin
 if pic <> nil then begin
  if anim then begin
   Blit.BlitTileClipped(col - 1, row - 1, 0, 0, pic, GDVars.compositeBuffer);
   Mouse.HideMouse; Blit.FlushView;
   Mouse.ShowMouse
  end else begin Mouse.HideMouse; Blit.ShowPic(col, row, pic); Mouse.ShowMouse end
 end
end;

procedure LoadAnimation(name: Types.TString8; picId, transp: Byte; var a: Types.TAnimRec);
var
  sz: Word;
  buf: Types.PBytes;
  readOfs: Word;
  f: Byte;
  h: Word;
  w: Word;
  suffix: String[1];
 xorBuf: Types.PBytes;
 j: Word;
 planeSz: Word;
 isPic: Boolean;
 gotXor: Boolean;
 loaded: Byte;
begin
 if ((name = GDVars.pictureArchiveName) and (picId = GDVars.pictureArchiveId)) or (picId = 255) then Exit;
 if GDVars.animationsEnabled <> 0 then begin
  TextRend.PrintSpaces(GDConsts.messageColumn, GDConsts.messageRow, Black, GDConsts.screenWidth);
  TextRend.DisplayString(GDConsts.messageColumn, GDConsts.messageRow, LightGreen, Black, GDConsts.loadingMessage)
 end;
 Portrait.FreeAnimation(a); GDVars.pictureArchiveName := name; GDVars.pictureArchiveId := picId;
 isPic := name = 'PIC';
 { the disk each archive is on }
 if name = 'SPRIT' then begin
  if picId in [2, 64, 66, 70] then suffix := '4' else Str(GDVars.diskNumber, suffix)
 end else if name = 'PIC' then begin
  case picId of
   59, 60, 78: suffix := '4';
   5, 24, 77, 96: suffix := '5';
   16, 17, 19, 74, 80: suffix := '6';
   83: suffix := '7'
  else Str(GDVars.diskNumber, suffix) end
 end else Str(GDVars.diskNumber, suffix);
 DaxIo.LoadDax(name + suffix, GDConsts.daxExtension, picId, sz, buf);
 if sz = 0 then begin TextRend.DisplayAndPause(Yellow, Black, 'PIC not found'); Exit end;
 readOfs := 0; gotXor := False;
 with a do begin
  count := buf^[readOfs]; Inc(readOfs); currentFrame := 1; loaded := 0;
  if (GDVars.animationsEnabled = 0) and isPic then count := 1;
  for f := 1 to count do begin
   Move(buf^[readOfs], frames[f].duration, SizeOf(LongInt)); Inc(readOfs, SizeOf(LongInt));
   Move(buf^[readOfs], h, SizeOf(h)); Inc(readOfs, 2); Move(buf^[readOfs], w, SizeOf(w)); Inc(readOfs, 2);
   if MaxAvail >= 3900 then begin
    Inc(loaded); Blit.AllocPic(h, w, 1, transp, frames[f].pic);
    with frames[f].pic^ do begin
     Move(buf^[readOfs], originX, SizeOf(originX)); Inc(readOfs, 2);
     Move(buf^[readOfs], originY, SizeOf(originY)); Inc(readOfs, 3);
     Move(buf^[readOfs], map, SizeOf(map)); Inc(readOfs, 8)
    end;
    if GDVars.displayMode = Types.Cga then planeSz := frames[f].pic^.imgSize * 2 - 1
    else planeSz := frames[f].pic^.imgSize - 1;
    if isPic then
     if f = 1 then begin
      GetMem(xorBuf, planeSz + 1); Move(buf^[readOfs], xorBuf^, planeSz + 1); gotXor := True
     end else
      for j := readOfs to readOfs + planeSz do buf^[j] := buf^[j] xor xorBuf^[j - readOfs];
    Blit.ExpandPicFrames(buf, readOfs, Boolean(transp), 0, frames[f].pic);
    if (transp and GDConsts.iconFrame > 0) and (GDVars.displayMode <> Types.Cga) then
     Blit.RemapPic(GDConsts.animationRemapFrom, GDConsts.animationRemapTo, 0, False, frames[f].pic);
    Inc(readOfs, planeSz + 1)
   end else count := 1
  end;
  count := loaded
 end;
 if isPic and gotXor then FreeMem(xorBuf, planeSz + 1);
 FreeMem(buf, sz); GameIo.FlushKeys;
 if GDVars.animationsEnabled <> 0 then
     TextRend.PrintSpaces(GDConsts.messageColumn, GDConsts.messageRow, Black, GDConsts.screenWidth)
end;

procedure FreeAnimation(var a: Types.TAnimRec);
begin
 with a do for GDVars.loopIndex := 1 to count do Blit.FreePic(frames[GDVars.loopIndex].pic);
 FillChar(a, SizeOf(Types.TAnimRec), 0); GDVars.pictureArchiveName[0] := #0; GDVars.pictureArchiveId := 255
end;

procedure Show3DSprite(dist: Byte; a: Types.TAnimRec);
begin
 if (dist < 1) or (dist > 3) then begin
  Blit.RestoreVideoMode; WriteLn(Output, GDConsts.spriteError); GameIo.ExitGame
 end;
 if a.frames[dist].pic <> nil then
  with a.frames[dist].pic^ do
   Blit.BlitTileClipped(originX + 3 - 1, originY + 3 - 1, 0, GDConsts.iconFrame, a.frames[dist].pic,
                        GDVars.compositeBuffer)
 else Exit;
 Blit.FlushView
end;

procedure LoadBigPic(id: Byte);
var suffix: String[1];
begin
 Portrait.FreeAnimation(GDVars.portraitAnimation);
 if GDVars.bigId = id then Exit;
 if GDVars.diskNumber = 5 then suffix := '1' else Str(GDVars.diskNumber, suffix);
 TextRend.PrintSpaces(GDConsts.messageColumn, GDConsts.messageRow, Black, GDConsts.screenWidth);
 TextRend.DisplayString(GDConsts.messageColumn, GDConsts.messageRow, LightGreen, Black, GDConsts.loadingMessage);
 Blit.LoadPic('bigpic' + suffix, id, Boolean(GDConsts.pictureMode), Black, GDVars.bigPic);
 GDVars.bigId := id
end;

procedure DisplayBigPic;
begin Mouse.HideMouse; Border.DrawRowDivider; Blit.ShowPic(1, 1, GDVars.bigPic); Mouse.ShowMouse end;
begin end.
