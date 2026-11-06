{ MapCurs -- the party marker on the overland map. DrawCursor grabs the map cell under the party (zone0's wildX/wildY)
  into viewCapture, composes GDVars.cursorImage over a copy of it in the composite, shows that, and clears the span
  list; RestoreCursorBackground shows the captured cell again to erase the marker. EclVm draws the marker; Explore
  erases it and draws it again around a wilderness step. }
{$O+,F+}
unit MapCurs;
interface

{ Draws the party cursor on the overland map: saves the map cell under the party (one cell in from the map's corner)
  into a buffer, lays the cursor image over a copy of it through its mask, shows the result and clears the dirty spans
  the drawing recorded. }
procedure DrawCursor;

{ Erases the party cursor by putting back the map cell DrawCursor saved. }
procedure RestoreCursorBackground;
implementation
uses Blit, GDConsts, GDVars;

procedure DrawCursor;
begin
  Blit.GrabPic(GDVars.zone0^.wildX + 1, GDVars.zone0^.wildY + 1, GDVars.viewCapture);
  Blit.BlitTileCell(0, 0, 0, 0, GDVars.viewCapture, GDVars.viewComposite);
  Blit.BlitTileCell(0, 0, 0, GDConsts.iconFrame, GDVars.cursorImage, GDVars.viewComposite);
  Blit.ShowPic(GDVars.zone0^.wildX + 1, GDVars.zone0^.wildY + 1, GDVars.viewComposite);
  FillChar(GDVars.spanActive, SizeOf(GDVars.spanActive), 0);
  FillChar(GDVars.spanY, SizeOf(GDVars.spanY), 0);
  FillChar(GDVars.spanX0, SizeOf(GDVars.spanX0), $FF);
  FillChar(GDVars.spanX1, SizeOf(GDVars.spanX1), 0);
end;

procedure RestoreCursorBackground;
begin
  Blit.ShowPic(GDVars.zone0^.wildX + 1, GDVars.zone0^.wildY + 1, GDVars.viewCapture);
end;
begin
end.
