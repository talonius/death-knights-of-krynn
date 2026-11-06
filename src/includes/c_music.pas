{ The music driver's heap buffers: their sizes, as GameInit allocates them and Music clears them. }
unit C_Music;

interface

const
  { musicDriverBuf, the driver's code and data }
  DRIVER_BUFFER_SIZE = 13000;
  { musicDataBuf, the score being played }
  DATA_BUFFER_SIZE = 6144;

implementation

end.
