{ Menu key values. Enter, Escape and Backspace are ASCII; the arrow, Home and End keys are BIOS extended scan codes,
  returned with the menu routines' extended-key flag set. }
unit C_Keys;

interface

const
  BACKSPACE = #8;
  ENTER = #13;
  ESCAPE = #27;
  HOME = #71;
  UP = #72;
  PAGE_UP = #73;
  LEFT = #75;
  RIGHT = #77;
  END_KEY = #79;
  DOWN = #80;
  PAGE_DOWN = #81;

implementation

end.
