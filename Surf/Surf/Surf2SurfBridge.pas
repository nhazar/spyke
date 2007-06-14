unit Surf2SurfBridge;

interface

uses Windows,Messages,Graphics,Dialogs,SurfTypes,SurfPublicTypes,Sysutils,SurfShared,PahUnit;

VAR
  SurfBridgeFormHandle : integer;
  GlobData   : PGlobalDLLData;

  NumEventsSent : integer;
//Procedures for Surf
//writing
Procedure SendSpikeToSurfBridge(Spike : TSpike);
Procedure SendCrToSurfBridge(Cr : TCr);
Procedure SendSVToSurfBridge(SV : TSVal);
//Procedure SendEventToSurfBridge(SurfEvent : TSurfEvent);
Procedure SendEventArrayToSurfBridge(SurfEventArray : TSurfEventArray);
Procedure SendProbeArrayToSurfBridge(Probe : TProbeArray);
Procedure SendSpikeArrayToSurfBridge(SpikeArray : TSpikeArray);
Procedure SendCrArrayToSurfBridge(CrArray : TCrArray);
Procedure SendSValArrayToSurfBridge(SValArray : TSValArray);
Procedure SendMsgArrayToSurfBridge(SurfMsgArray : TSurfMsgArray);

Procedure StartFileSend;
Procedure EndFileSend;

//reading
Procedure GetSpikeFromSurfBridge(var Spike : TSpike; ReadIndex : integer);
Procedure GetSVFromSurfBridge(var Sv : TSVal; ReadIndex : integer);
Procedure GetDACFromSurfBridge(var DAC : TDAC; ReadIndex : integer);
Procedure GetDIOFromSurfBridge(var DIO : TDIO; ReadIndex : integer);
Procedure GetFileNameFromSurfBridge(var FileName : String; ReadIndex : integer);
{ Define the DLL's exported procedure }
procedure GetDLLData(var AGlobalData: PGlobalDLLData); StdCall External 'C:\Surf\Application\ShareLib.DLL';

{----------------------------------------------------------------------------}
implementation

{========================== WRITING ===========================================}
Procedure WriteToBuffer(data : pchar; buf : pchar; size : integer; var writeindex : integer);
begin
  Move(data^,buf^,size);
  inc(writeindex,size);
end;

Function NextWritePosition(size : integer) : integer;
var i : integer;
begin
  While GlobData^.Writing do;//pause if another process is currently writing
  GlobData^.Writing := TRUE;
  i := GlobData^.WriteIndex;
  if (i + size) > GLOBALDATARINGBUFSIZE-1 {wrap around}
    then i := 0;
  GlobData^.WriteIndex := i + size;
  RESULT := i;
  GlobData^.Writing := FALSE;
end;

{------------------------- SEND PROBE  ----------------------------------------}
Procedure SendProbeArrayToSurfBridge(Probe : TProbeArray);
var origindex,curindex : integer;
    size,p,i,j : integer;
    pc : array[0..SURF_MAX_PARAMS-1] of char;
    prb : TProbe;
Procedure CopyProbe(var srcprb,destprb : TProbe);
var c : integer;
begin
  DestPrb.ProbeSubType    := SrcPrb.ProbeSubType;
  DestPrb.numchans        := SrcPrb.numchans;
  DestPrb.pts_per_chan    := SrcPrb.pts_per_chan;
  DestPrb.trigpt          := SrcPrb.trigpt;
  DestPrb.lockout         := SrcPrb.lockout;
  DestPrb.intgain         := SrcPrb.intgain;
  DestPrb.threshold       := SrcPrb.threshold;
  DestPrb.skippts         := SrcPrb.skippts;
  DestPrb.sampfreqperchan := SrcPrb.sampfreqperchan;
  DestPrb.probe_descrip   := SrcPrb.probe_descrip;
  DestPrb.electrode_name  := SrcPrb.electrode_name;
  DestPrb.numspikes       := SrcPrb.numspikes;
  DestPrb.numcr           := SrcPrb.numcr;
  DestPrb.numparams       := SrcPrb.numparams;
  DestPrb.paramname       := nil;
  DestPrb.spike           := nil;
  DestPrb.cr              := nil;
  For c:= 0 to SURF_MAX_CHANNELS-1 do
  begin
    DestPrb.chanlist[c]     := SrcPrb.chanlist[c];
    DestPrb.extgain[c]      := SrcPrb.extgain[c];
  end;
  Move(SrcPrb.ProbewinLayout,DestPrb.ProbewinLayout,sizeof(TProbewinLayout));
end;
begin
  //can't copy pointers to the buffer--reading them later and
  For p := 0 to Length(Probe)-1 do
  begin
    Size :=  sizeof(TProbe) + probe[p].numparams * SURF_MAX_PARAMS;
    CurIndex := NextWritePosition(size);
    origindex := curindex;
    //copy the probe to the global data array
    CopyProbe(Probe[p],prb);
    WriteToBuffer(@prb,@GlobData^.data[curindex],sizeof(TProbe),curindex);
    //write the paramnames, if any
    for i := 0 to probe[p].numparams -1 do
    begin
      For j := 0 to SURF_MAX_PARAMS-1 do
        pc[j] := Probe[p].ParamName[i,j+1];
      WriteToBuffer(@pc,@GlobData^.data[curindex],SURF_MAX_PARAMS,curindex);
    end;
    //tell surfbridge it is there
    PostMessage(SurfBridgeFormHandle,WM_SURF_OUT,SURF_OUT_PROBE,origindex);
    //Now send spikes, and crs
    if Probe[p].NumSpikes > 0 then
      SendSpikeArrayToSurfBridge(Probe[p].Spike);
    if Probe[p].NumCr > 0 then
      SendCRArrayToSurfBridge(Probe[p].Cr);
  end;
end;

{------------------------  SEND SPIKE  ----------------------------------------}
Procedure SendSpikeToSurfBridge(Spike : TSpike);
var origindex,curindex : integer;
    size,c : integer;
    bufdesc : TBufDesc;
begin
  bufdesc.d1{nchans} := Length(Spike.Waveform);
  bufdesc.d2{npts} := Length(Spike.Waveform[0]);
  bufdesc.d3{nparams} := Length(Spike.Param);

  Size :=  sizeof(TBufDesc) //desc info
         + sizeof(TSpike) - 8 {the waveform and param pointers}
         + bufdesc.d1 * bufdesc.d2*2 //the waveform
         + bufdesc.d3*2;  //the parameters

  CurIndex := NextWritePosition(size);
  origindex := curindex;

  //copy the spike to the global data array

  WriteToBuffer(@Spike,@GlobData^.data[curindex],sizeof(TSpike) - 8,curindex);
  WriteToBuffer(@bufdesc,@GlobData^.data[curindex],sizeof(TBufDesc),curindex);
  For c := 0 to bufdesc.d1-1 do
    WriteToBuffer(@Spike.WaveForm[c,0],@GlobData^.data[curindex],bufdesc.d2*2,curindex);
  WriteToBuffer(@Spike.Param[0],@GlobData^.data[curindex],bufdesc.d3*2,curindex);

  //tell surfbridge it is there
  PostMessage(SurfBridgeFormHandle,WM_SURF_OUT,SURF_OUT_SPIKE,origindex);
end;

{------------------------  SEND SPIKE ARRAY ----------------------------------}
Procedure SendSpikeArrayToSurfBridge(SpikeArray : TSpikeArray);
const SPIKEBLOCKSIZE = 100;//send spikes 100 at a time
var origindex,curindex : integer;
    size,NumSends,i,j : integer;
    bufdesc : TBufDesc;
procedure WriteArray(s:integer);
var c : integer;
begin
  WriteToBuffer(@SpikeArray[s],@GlobData^.data[curindex],sizeof(TSpike) - 8,curindex);
  For c := 0 to bufdesc.d1-1 do
    WriteToBuffer(@SpikeArray[s].WaveForm[c,0],@GlobData^.data[curindex],bufdesc.d2*2,curindex);
  WriteToBuffer(@SpikeArray[s].Param[0],@GlobData^.data[curindex],bufdesc.d3*2,curindex);
end;
begin
  NumSends := Length(SpikeArray) div SPIKEBLOCKSIZE;

  bufdesc.d1{nchans}  := Length(SpikeArray[0].Waveform);
  bufdesc.d2{npts}    := Length(SpikeArray[0].Waveform[0]);
  bufdesc.d3{nparams} := Length(SpikeArray[0].Param);
  bufdesc.d4{nspikes} := SPIKEBLOCKSIZE;
  Size :=  sizeof(TBufDesc)
         + SPIKEBLOCKSIZE  * (Sizeof(TSpike) - 8 {the waveform and param pointers}
                              + bufdesc.d1 * bufdesc.d2*2 //the waveform
                              + bufdesc.d3*2);  //the parameters
  For i := 0 to NumSends-1 do
  begin
    CurIndex := NextWritePosition(size);
    origindex := curindex;
    WriteToBuffer(@bufdesc,@GlobData^.data[curindex],sizeof(TBufDesc),curindex);
    For j := 0 to SPIKEBLOCKSIZE-1 do
      WriteArray(i*SPIKEBLOCKSIZE+j);
    //tell surfbridge it is there
    PostMessage(SurfBridgeFormHandle,WM_SURF_OUT,SURF_OUT_SPIKE_ARRAY,origindex);
    Delay(0,1);
  end;
  bufdesc.d4{nspikes} := Length(SpikeArray) mod SPIKEBLOCKSIZE;
  if bufdesc.d4 = 0 then exit;
  Size :=  sizeof(TBufDesc) + bufdesc.d4
        * (Sizeof(TSpike) - 8 {the waveform and param pointers}
         + bufdesc.d1 * bufdesc.d2*2 //the waveform
         + bufdesc.d3*2);  //the parameters
  CurIndex := NextWritePosition(size);
  origindex := curindex;
  WriteToBuffer(@bufdesc,@GlobData^.data[curindex],sizeof(TBufDesc),curindex);
  For j := 0 to bufdesc.d4-1 do
    WriteArray(NumSends*SPIKEBLOCKSIZE+j);
  //tell surfbridge it is there
  PostMessage(SurfBridgeFormHandle,WM_SURF_OUT,SURF_OUT_SPIKE_ARRAY,origindex);
  Delay(0,1);
end;

{------------------------  SEND CR -----------------------------------------}
Procedure SendCrToSurfBridge(Cr : TCr);
var origindex,curindex : integer;
    size : integer;
    bufdesc : TBufDesc;
begin
  bufdesc.d1{nchans} := 0;
  bufdesc.d2{npts} := Length(Cr.Waveform);
  bufdesc.d3{nparams} := 0;

  Size :=  sizeof(TBufDesc)//desc info
         + sizeof(TCr) - 4 {the waveform and param pointers}
         + bufdesc.d2*2; //the waveform

  //get the next write position
  CurIndex := NextWritePosition(size);
  origindex := curindex;

  //copy the spike to the global data array
  WriteToBuffer(@Cr,@GlobData^.data[curindex],sizeof(TCr) - 4,curindex);
  WriteToBuffer(@bufdesc,@GlobData^.data[curindex],sizeof(TBufDesc),curindex);
  WriteToBuffer(@Cr.WaveForm[0],@GlobData^.data[curindex],bufdesc.d2*2,curindex);

  //tell surfbridge it is there
  PostMessage(SurfBridgeFormHandle,WM_SURF_OUT,SURF_OUT_CR,origindex);
end;

{------------------------  SEND CR ARRAY ----------------------------------}
Procedure SendCrArrayToSurfBridge(CrArray : TCrArray);
const CRBLOCKSIZE = 1000;//send crs 100 at a time
var origindex,curindex : integer;
    size,NumSends,i,j : integer;
    bufdesc : TBufDesc;
procedure WriteArray(c:integer);
begin
  WriteToBuffer(@CrArray[c],@GlobData^.data[curindex],sizeof(TCr) - 4,curindex);
  WriteToBuffer(@CrArray[c].WaveForm[0],@GlobData^.data[curindex],bufdesc.d2*2,curindex);
end;
begin
  NumSends := Length(CrArray) div CRBLOCKSIZE;

  bufdesc.d2{npts}    := Length(CrArray[0].Waveform);
  bufdesc.d4{ncr}     := CRBLOCKSIZE;

  Size :=  sizeof(TBufDesc)
         + bufdesc.d4  * (Sizeof(TCr) - 4 {the waveform pointer}
                       + bufdesc.d2*2);  //the waveform

  For i := 0 to NumSends-1 do
  begin
    CurIndex := NextWritePosition(size);
    origindex := curindex;
    WriteToBuffer(@bufdesc,@GlobData^.data[curindex],sizeof(TBufDesc),curindex);
    For j := 0 to CRBLOCKSIZE-1 do
      WriteArray(i*CRBLOCKSIZE+j);
    //tell surfbridge it is there
    PostMessage(SurfBridgeFormHandle,WM_SURF_OUT,SURF_OUT_CR_ARRAY,origindex);
    Delay(0,1);
  end;
  bufdesc.d4{ncrs} := Length(CrArray) mod CRBLOCKSIZE;
  if bufdesc.d4 = 0 then exit;
  Size :=  sizeof(TBufDesc)
         + bufdesc.d4  * (Sizeof(TCr) - 4 {the waveform pointer}
                       + bufdesc.d2*2);  //the waveform
  CurIndex := NextWritePosition(size);
  origindex := curindex;
  WriteToBuffer(@bufdesc,@GlobData^.data[curindex],sizeof(TBufDesc),curindex);
  For j := 0 to bufdesc.d4-1 do
    WriteArray(NumSends*CRBLOCKSIZE+j);
  //tell surfbridge it is there
  PostMessage(SurfBridgeFormHandle,WM_SURF_OUT,SURF_OUT_CR_ARRAY,origindex);
  Delay(0,1);
end;

{------------------------- SEND SV  ----------------------------------------}
Procedure SendSVToSurfBridge(SV : TSVal);
var origindex,curindex : integer;
    size : integer;
begin
  Size := sizeof(TSVal); //the sv record
  //get the next write position
  CurIndex := NextWritePosition(size);
  origindex := curindex;

  //copy the sv to the global data array
  WriteToBuffer(@Sv,@GlobData^.data[curindex],size,curindex);
  //tell surfbridge it is there
  PostMessage(SurfBridgeFormHandle,WM_SURF_OUT,SURF_OUT_SV,origindex);
end;

{------------------------- SEND SV ARRAY  ----------------------------------------}
Procedure SendSValArrayToSurfBridge(SValArray : TSValArray);
const SVBLOCKSIZE = 1000;//send svs 1000 at a time
var origindex,curindex : integer;
    size,NumSends,i,j : integer;
    bufdesc : TBufDesc;
procedure WriteArray(s:integer);
begin
  WriteToBuffer(@SValArray[s],@GlobData^.data[curindex],sizeof(TSVal),curindex);
end;
begin
  NumSends := Length(SValArray) div SVBLOCKSIZE;
  bufdesc.d4{nsv}     := SVBLOCKSIZE;
  Size :=  sizeof(TBufDesc) + bufdesc.d4  * Sizeof(TSVal);
  For i := 0 to NumSends-1 do
  begin
    CurIndex := NextWritePosition(size);
    origindex := curindex;
    WriteToBuffer(@bufdesc,@GlobData^.data[curindex],sizeof(TBufDesc),curindex);
    For j := 0 to SVBLOCKSIZE-1 do
      WriteArray(i*SVBLOCKSIZE+j);
    //tell surfbridge it is there
    PostMessage(SurfBridgeFormHandle,WM_SURF_OUT,SURF_OUT_SV_ARRAY,origindex);
    Delay(0,1);
  end;
  bufdesc.d4{ncrs} := Length(SValArray) mod SVBLOCKSIZE;
  if bufdesc.d4 = 0 then exit;
  Size :=  sizeof(TBufDesc) + bufdesc.d4  * Sizeof(TSVal);
  CurIndex := NextWritePosition(size);
  origindex := curindex;
  WriteToBuffer(@bufdesc,@GlobData^.data[curindex],sizeof(TBufDesc),curindex);
  For j := 0 to bufdesc.d4-1 do
    WriteArray(NumSends*SVBLOCKSIZE+j);
  //tell surfbridge it is there
  PostMessage(SurfBridgeFormHandle,WM_SURF_OUT,SURF_OUT_SV_ARRAY,origindex);
  Delay(0,1);
end;

{------------------------- SEND MSG ARRAY  ----------------------------------------}
Procedure SendMsgArrayToSurfBridge(SurfMsgArray : TSurfMsgArray);
const MSGBLOCKSIZE = 500;//send msg 100 at a time
var origindex,curindex : integer;
    size,NumSends,i,j : integer;
    bufdesc : TBufDesc;
procedure WriteArray(m:integer);
begin
  WriteToBuffer(@SurfMsgArray[m],@GlobData^.data[curindex],sizeof(TSurfMsg),curindex);
end;
begin
  NumSends := Length(SurfMsgArray) div MSGBLOCKSIZE;
  bufdesc.d4{nmsgs}     := MSGBLOCKSIZE;
  Size :=  sizeof(TBufDesc) + bufdesc.d4  * Sizeof(TSurfMsg);
  For i := 0 to NumSends-1 do
  begin
    CurIndex := NextWritePosition(size);
    origindex := curindex;
    WriteToBuffer(@bufdesc,@GlobData^.data[curindex],sizeof(TBufDesc),curindex);
    For j := 0 to MSGBLOCKSIZE-1 do
      WriteArray(i*MSGBLOCKSIZE+j);
    //tell surfbridge it is there
    PostMessage(SurfBridgeFormHandle,WM_SURF_OUT,SURF_OUT_MSG_ARRAY,origindex);
    Delay(0,1);
  end;

  bufdesc.d4{ncrs} := Length(SurfMsgArray) mod MSGBLOCKSIZE;

  if bufdesc.d4 = 0 then exit;

  Size :=  sizeof(TBufDesc) + bufdesc.d4  * Sizeof(TSurfMsg);
  CurIndex := NextWritePosition(size);
  origindex := curindex;
  WriteToBuffer(@bufdesc,@GlobData^.data[curindex],sizeof(TBufDesc),curindex);
    For j := 0 to bufdesc.d4-1 do
      WriteArray(NumSends*MSGBLOCKSIZE+j);
  //tell surfbridge it is there
  PostMessage(SurfBridgeFormHandle,WM_SURF_OUT,SURF_OUT_MSG_ARRAY,origindex);
  Delay(0,1);
end;

{------------------------- START FILESEND  ---------------------------------}
Procedure StartFileSend;
begin
  NumEventsSent := 0;
  PostMessage(SurfBridgeFormHandle,WM_SURF_OUT,SURF_OUT_FILESTART,0);
end;
{------------------------- END FILESEND  ---------------------------------}
Procedure EndFileSend;
begin
  PostMessage(SurfBridgeFormHandle,WM_SURF_OUT,SURF_OUT_FILEEND,0);
end;

{------------------------- SEND EVENT  ----------------------------------------}
(*Procedure SendEventToSurfBridge(SurfEvent : TSurfEvent);
  {TSurfEvent = record
    Time_Stamp    : LNG; //4 bytes
    EventType     : CHAR;//e.g., POLYTRODE, SINGLE VALUE, MESSAGE...
    SubType       : CHAR;//e.g., S,C for spike or continuous
    Probe         : SHRT;//if used, the probe number
    Index         : LNG;//the index into the data array-- e.g., prb[probe].spike[index]....
  end; }
var origindex,curindex : integer;
    size : integer;
begin
  Size :=  sizeof(TSurfEvent);

  //get the next write position
  CurIndex := NextWritePosition(size);
  origindex := curindex;
  //copy the surfevent to the global data array
  WriteToBuffer(@SurfEvent,@GlobData^.data[curindex],size,curindex);
  //tell surfbridge it is there
  PostMessage(SurfBridgeFormHandle,WM_SURF_OUT,SURF_OUT_SURFEVENT,origindex);
end; *)
{------------------------- SEND EVENTARRAY------------------------------------}
Procedure SendEventArrayToSurfBridge(SurfEventArray : TSurfEventArray);
{sends events to SurfBridge in large blocks.  This cuts down on the number of messages
  that surfbridge has to process.  If SurfBridge has to process 1000s of messages there
  will be a significant delay and some events would be lost}
const EVENTBLOCKSIZE = 5000;
  {TSurfEvent = record
    Time_Stamp    : LNG; //4 bytes
    EventType     : CHAR;//e.g., POLYTRODE, SINGLE VALUE, MESSAGE...
    SubType       : CHAR;//e.g., S,C for spike or continuous
    Probe         : SHRT;//if used, the probe number
    Index         : LNG;//the index into the data array-- e.g., prb[probe].spike[index]....
  end; }
var origindex,curindex,i : integer;
    size : integer;
    bufdesc : TBufDesc;
    numsends,len : integer;
procedure sendarray(e : integer);
begin
  //get the next write position
  CurIndex := NextWritePosition(size);
  origindex := curindex;
  //write the buf description
  WriteToBuffer(@bufdesc,@GlobData^.data[curindex],sizeof(TBufDesc),curindex);
  //copy the surfevent to the global data array
  WriteToBuffer(@SurfEventArray[e],@GlobData^.data[curindex],size,curindex);
  //tell surfbridge it is there
  PostMessage(SurfBridgeFormHandle,WM_SURF_OUT,SURF_OUT_SURFEVENT_ARRAY,origindex);
end;
begin
  NumSends := Length(SurfEventArray) div EVENTBLOCKSIZE;

  if NumSends > 0 then len := EVENTBLOCKSIZE else len := Length(SurfEventArray);
  Size :=  sizeof(Tbufdesc) + len * sizeof(TSurfEvent);
  bufdesc.d1{nevents} := len;
  For i := 0 to NumSends-1 do
  begin
    SendArray(i*EVENTBLOCKSIZE);
    Delay(0,1);
  end;
  len := Length(SurfEventArray) mod EVENTBLOCKSIZE;
  if len = 0 then exit;
  Size :=  sizeof(Tbufdesc) + len * sizeof(TSurfEvent);
  bufdesc.d1{nevents} := len;
  SendArray(NumSends*EVENTBLOCKSIZE);
  Delay(0,1);
end;

{========================== READING ===========================================}
Procedure ReadFromBuffer(data : pchar; buf : pchar; size : integer; var readindex : integer);
begin
  Move(buf^,data^,size);
  inc(readindex,size);
end;

{------------------------  READ SPIKE  ----------------------------------------}
Procedure GetSpikeFromSurfBridge(var Spike : TSpike; ReadIndex : integer);
var bufdesc : TBufDesc;
    c : integer;
begin
  ReadFromBuffer(@Spike,@GlobData^.data[readindex],sizeof(TSpike)-8,readindex);
  ReadFromBuffer(@bufdesc,@GlobData^.data[readindex],sizeof(TBufDesc),readindex);

  SetLength(Spike.waveform,bufdesc.d1{nchans});
  For c := 0 to bufdesc.d1{nchans}-1 do
  begin
    SetLength(Spike.WaveForm[c],bufdesc.d2{npts});
    ReadFromBuffer(@Spike.WaveForm[c,0],@GlobData^.data[readindex],bufdesc.d2{npts}*2,readindex);
  end;
  ReadFromBuffer(@Spike.Param[0],@GlobData^.data[readindex],bufdesc.d3{nparams}*2,readindex);
end;

{------------------------  READ SV  ----------------------------------------}
Procedure GetSVFromSurfBridge(var Sv : TSVal; ReadIndex : integer);
begin
  ReadFromBuffer(@Sv,@GlobData^.data[readindex],sizeof(TSVal),readindex);
end;

{------------------------  READ DAC  ----------------------------------------}
Procedure GetDACFromSurfBridge(var DAC : TDAC; ReadIndex : integer);
begin
  ReadFromBuffer(@DAC,@GlobData^.data[readindex],sizeof(TDAC),readindex);
end;
{------------------------  READ DIO  ----------------------------------------}
Procedure GetDIOFromSurfBridge(var DIO : TDIO; ReadIndex : integer);
begin
  ReadFromBuffer(@DIO,@GlobData^.data[readindex],sizeof(TDIO),readindex);
end;

{------------------------  READ FILENAME  ----------------------------------}
Procedure GetFileNameFromSurfBridge(var FileName : String; ReadIndex : integer);
var fn : array[0..255] of char;
    i : integer;
begin
  ReadFromBuffer(@fn,@GlobData^.data[readindex],sizeof(fn),readindex);
  Filename := '';
  For i := 0 to 255 do
    if fn[i] <> #0 then filename := filename + fn[i] else break;
end;

initialization
  GetDLLData(GlobData);
end.
