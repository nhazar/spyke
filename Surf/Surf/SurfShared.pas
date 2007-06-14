unit SurfShared;
interface
uses SurfTypes,{SurfFile,}SysUtils;

const
  GLOBALDATARINGBUFSIZE = integer(1024*2000);//2.5 MB buffer

type
  //For SurfBridge only-------------------------
  PGlobalDLLData = ^TGlobalDLLData;
  TGlobalDLLData = record
    WriteIndex : integer;
    Writing : Boolean;
    data : array[0..GLOBALDATARINGBUFSIZE-1] of byte; //ring buffer
  end;

implementation

end.
