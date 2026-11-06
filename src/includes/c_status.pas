{ Creature status values (TCharacter.status), in statusNames order. }
unit C_Status;

interface

const
  OKAY = 0;
  { an animated corpse: it fights for the party but counts as dead }
  ANIMATED = 1;
  { fled combat }
  RUNNING = 3;
  UNCONSCIOUS = 4;
  DYING = 5;
  DEAD_STATUS = 6;
  STONED = 7;
  GONE = 8;

implementation

end.
