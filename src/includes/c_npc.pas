{ TCharacter.npc values: 0 for a party member; bit 7 marks a creature outside the party, and its low bits hold the
  creature's morale. }
unit C_Npc;

interface

const
  NON_PLAYER = $80;
  MORALE_MASK = $7F;
  { a party member the computer runs while it is charmed, confused, terrified or berserk; removal resets it to 0 }
  ANIMATED_PLAYER = $B3;

implementation

end.
