{ Compass directions, clockwise from north: map facings, wall sides and arena moves; CENTER stays on the cell. }
unit C_Dir;

interface

const
  NORTH = 0;
  NORTHEAST = 1;
  EAST = 2;
  SOUTHEAST = 3;
  SOUTH = 4;
  SOUTHWEST = 5;
  WEST = 6;
  NORTHWEST = 7;
  { a creature's own cell: no step }
  CENTER = 8;

implementation

end.
