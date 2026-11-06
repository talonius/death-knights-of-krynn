{ MapTiles -- loads the combat tile sheet and the combatants' icon animations, and draws an icon. The tile sheet and the
  icon slots (two frames each) are GDVars.tileSheet and GDVars.iconAnimations. }
{$O+,F+,I-}
unit MapTiles;
interface

{ Loads a picture of 24x24 map tiles and copies the given number of its tiles into the tile sheet from the given slot
  on, then drains pending keystrokes. A slot above 39 is a fatal error, reported in text mode.
  @param(name Base name of the DAX file.)
  @param(fileId Picture number within the file.)
  @param(slot First tile slot written.)
  @param(nTiles Number of tiles copied.) }
procedure Load24x24Set(name: String; fileId, slot, nTiles: Byte);

{ Frees both frames of an icon animation slot.
  @param(animIdx The slot.) }
procedure FreeIconAnim(animIdx: Byte);

{ Loads both frames of an icon into slot animIdx -- picture fileId and fileId + 128. CHEAD/CBODY names drop their last
  letter, and a final T adds 64 to fileId; ICON, COMSPR and CHEAD/CBODY load from the plain archive, CPIC from
  CPIC1.DAX, anything else from the current disk's; those last are remapped (dark gray to black) outside CGA mode.
  EclVm, GameInit and SaveLoad call it.
  @param(name Archive name.)
  @param(fileId Picture block of the first frame.)
  @param(animIdx Icon slot to fill.) }
procedure LoadIconAnim(name: String; fileId, animIdx: Byte);

{ Draws one frame of an icon animation into the view buffer, clipped, at three character cells per map cell, mirrored
  for facings past southeast. Nothing is drawn if the frame is not loaded.
  @param(col Map column.)
  @param(row Map row.)
  @param(facing Direction the icon faces.)
  @param(frame Frame to draw, 0 or 1.)
  @param(animIdx Animation slot.) }
procedure DrawIconAnimSprite(col, row: ShortInt; facing, frame, animIdx: Byte);
implementation
uses GDConsts, GDVars, Crt, Blit, GameIo, Types;

procedure Load24x24Set(name: String; fileId, slot, nTiles: Byte);
var
  pic: Types.PImgBuf;
  total: Word;
  destOfs: Word;
begin
 if slot > 39 then begin Blit.RestoreVideoMode; WriteLn(Output,
                                                        'Start range error in Load24x24Set'); GameIo.ExitGame end;
 pic := nil; Blit.LoadPic(name, fileId, Boolean(GDConsts.pictureMode), Black,
                          pic); total := nTiles * pic^.imgSize; destOfs := slot * pic^.imgSize;
 if GDVars.tileSheet <> nil then Move(pic^.data, GDVars.tileSheet^.data[destOfs],
                                        total); Blit.FreePic(pic); GameIo.FlushKeys
end;

procedure FreeIconAnim(animIdx: Byte);
var
  { Unused in this version; see the other implementations of this routine. }
  i: Integer;
begin
 if GDVars.iconAnimations[animIdx, 0] <> nil then Blit.FreePic(GDVars.iconAnimations[animIdx, 0]);
 if GDVars.iconAnimations[animIdx, 1] <> nil then Blit.FreePic(GDVars.iconAnimations[animIdx, 1])
end;

procedure LoadIconAnim(name: String; fileId, animIdx: Byte);
var
  suffix: String[1];
  { Unused in this version; see the other implementations of this routine. }
  ch: Char;
begin
 if (Copy(name, 1, 5) = 'CHEAD') or (Copy(name, 1, 5) = 'CBODY') then begin
  if UpCase(name[Length(name)]) = 'T' then Inc(fileId, 64); name := Copy(name, 1, Length(name) - 1); suffix := '';
  Blit.LoadPic(name + suffix, fileId, Boolean(GDConsts.iconFrame), Black, GDVars.iconAnimations[animIdx, 0]);
  Blit.LoadPic(name + suffix, fileId + 128, Boolean(GDConsts.iconFrame), Black, GDVars.iconAnimations[animIdx, 1])
 end else if name = 'ICON' then begin
  suffix := '';
  Blit.LoadPic(name + suffix, fileId, Boolean(GDConsts.iconFrame), Black, GDVars.iconAnimations[animIdx, 0]);
  Blit.LoadPic(name + suffix, fileId + 128, Boolean(GDConsts.iconFrame), Black, GDVars.iconAnimations[animIdx, 1]);
 end else begin
  if name = 'COMSPR' then suffix := ''
  else if name = 'CPIC' then suffix := '1'
  else Str(GDVars.diskNumber, suffix);
  Blit.LoadPic(name + suffix, fileId, Boolean(GDConsts.iconFrame), Black, GDVars.iconAnimations[animIdx, 0]);
  if GDVars.displayMode <> Types.Cga then
   Blit.RemapPic(GDConsts.iconRemapFrom, GDConsts.iconRemapTo, 0, False, GDVars.iconAnimations[animIdx, 0]);
  Blit.LoadPic(name + suffix, fileId + 128, Boolean(GDConsts.iconFrame), Black, GDVars.iconAnimations[animIdx, 1]);
  if GDVars.displayMode <>
      Types.Cga then Blit.RemapPic(GDConsts.iconRemapFrom, GDConsts.iconRemapTo, 0, False,
                                   GDVars.iconAnimations[animIdx, 1])
 end; GameIo.FlushKeys
end;

procedure DrawIconAnimSprite(col, row: ShortInt; facing, frame, animIdx: Byte); var work: Types.PImgBuf;
begin
 if GDVars.iconAnimations[animIdx, frame] = nil then Exit;
 with GDVars.iconAnimations[animIdx, frame]^ do begin
  Blit.AllocPic(height, width, 1, GDConsts.iconFrame, work);
  if facing > 3 then Blit.MirrorPic(GDVars.iconAnimations[animIdx, frame], work)
  else begin Move(data, work^.data, imgSize); Move(transp^, work^.transp^, imgSize) end
 end;
 Blit.BlitTileClipped(col * 3, row * 3, 0, GDConsts.iconFrame, work, GDVars.compositeBuffer); Blit.FreePic(work)
end;
begin end.
