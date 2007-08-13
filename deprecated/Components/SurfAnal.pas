unit SurfAnal;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls,
  extctrls, Forms, Dialogs,ShellApi,
  SurfTypes,SurfPublicTypes,SurfShared;

type
  TSurfNewFileEvent = Procedure(SurfFile : TSurfFileInfo) of Object;

  TSurfAnal = class(TPanel{WinControl})
  private
    { Private declarations }
    FOnNewFile : TSurfNewFileEvent;

    NumMsgs,ReadIndex : Integer;
    GlobData   : PGlobalDLLData;

    SurfParentExists,ReceivingFile : boolean;
    SurfHandle : THandle;
    SurfFile : TSurfFileInfo;//can be huge!

    procedure AcceptFiles( var msg : TMsg{essage} );
    Procedure OnAppMessage(var Msg: TMsg; var Handled : Boolean);
     Function NextWritePosition(size : integer) : integer;
    Procedure WriteToBuffer(data : pchar; buf : pchar; size : integer; var writeindex : integer);
    Procedure ReadFromBuffer(data : pchar; buf : pchar; size : integer; var readindex : integer);

    //Procedures for SurfBridge
    Procedure GetProbeFromSurf(var Probe : TProbe; ReadIndex : Integer);
    Procedure GetSpikeArrayFromSurf(var SpikeArray : TSpikeArray; ReadIndex : integer);
    Procedure GetCrArrayFromSurf(var CrArray : TCrArray; ReadIndex : Integer);
    Procedure GetSValArrayFromSurf(var SValArray : TSValArray; ReadIndex : integer);
    Procedure GetMsgArrayFromSurf(var SurfMsgArray : TSurfMsgArray; ReadIndex : integer);
    Procedure GetSurfEventArrayFromSurf(var SurfEventArray : TSurfEventArray; ReadIndex : integer);
  protected
    { Protected declarations }
  public
    { Public declarations }
    { Public declarations }
    Constructor Create(AOwner: TComponent); Override;
    Destructor  Destroy; Override;
    //Methods
    Procedure SendFileRequestToSurf(FileName : String);
  published
    { Published declarations }
    //Events
    property OnSurfFile: TSurfNewFileEvent read FOnNewFile write FOnNewFile;
  end;

procedure Register;
{ Define the DLL's exported procedure }
procedure GetDLLData(var AGlobalData: PGlobalDLLData); StdCall External 'C:\Surf\Application\ShareLib.dll';

implementation

procedure Register;
begin
  RegisterComponents('SURF', [TSurfAnal]);
end;

Destructor TSurfAnal.Destroy;
var s,c,w,p : integer;
begin
  Inherited Destroy;
  if (csDesigning in ComponentState) then exit;
  SurfFile.SurfEventArray := nil;
  SurfFile.SValArray := nil;
  SurfFile.SurfMsgArray := nil;
  For p := 0 to Length(SurfFile.ProbeArray)-1 do
  begin
    For s := 0 to Length(SurfFile.ProbeArray[p].Spike)-1 do
    begin
      SurfFile.ProbeArray[p].Spike[s].Param := nil;
      For w := 0 to Length(SurfFile.ProbeArray[p].Spike[s].WaveForm)-1 do
        SurfFile.ProbeArray[p].Spike[s].WaveForm[w] := nil;
      SurfFile.ProbeArray[p].Spike[s].WaveForm := nil;
    end;
    SurfFile.ProbeArray[p].Spike := nil;
    For c := 0 to Length(SurfFile.ProbeArray[p].Cr)-1 do
      SurfFile.ProbeArray[p].Cr[c].WaveForm := nil;
    SurfFile.ProbeArray[p].Cr := nil;
  end;
  SurfFile.ProbeArray := nil;
end;

{-----------------------------------------------------------------------------}
Constructor TSurfAnal.Create(AOwner: TComponent);
begin
  Inherited Create(AOwner);
  Height := 28;
  Width := 80;
  Color := $0028799B;
  Font.Color := clWhite;
  caption := 'SURF Analysis';
  //don't process anymore if just designing
  if (csDesigning in ComponentState) then exit;
  Visible := FALSE;
  
  ReadIndex := 0;

  //if running in standalone then getoutahere
  if ParamCount<>2 then //Looking for version info and Surf's handle
  begin
    beep;
    ShowMessage('SurfAnal will only run when the application is called from Surf.');
    Halt;
  end else
  begin
    if ParamStr(1) = 'SURFv1.0' then  //got the surf version
    begin
      ReceivingFile := FALSE;
      DragAcceptFiles( (AOwner as TForm).Handle, True );
      SurfHandle := strtoint(ParamStr(2)); //and now the handle
      if SurfHandle > 0 then SurfParentExists := TRUE;
      GetDllData(GlobData);
      //Intercept application messages and send them to SurfBridge message handler
      Application.OnMessage := OnAppMessage; //intercepts postmessages
      PostMessage(SurfHandle,WM_SURF_IN,SURF_IN_HANDLE,(AOwner as TForm).Handle);//send it back to Surf
    end;
  end;
end;

{-----------------------------------------------------------------------------}
Procedure TSurfAnal.OnAppMessage(var Msg: TMsg; var Handled : Boolean);
var SurfEventArray : TSurfEventArray;
    SpikeArray : TSpikeArray;
    CrArray : TCrArray;
    SValArray : TSValArray;
    SurfMsgArray : TSurfMsgArray;
    i,j,c,w,p,s,ReadIndex,len : integer;
begin
  Handled := FALSE;
  if Msg.Message = WM_DROPFILES then
  begin
    AcceptFiles(Msg);
    Handled := TRUE;
  end;
  if Msg.Message <> WM_SURF_OUT
    then exit//only handle those messages from surf
    else Handled := TRUE; //intercept
  ReadIndex := Msg.LParam;
  inc(NumMsgs);
  Case Msg.WParam of
    //Messages below are only called during file reading
    SURF_OUT_FILESTART:    begin
                             ReceivingFile := TRUE;
                             SurfFile.NEvents := 0;
                             SurfFile.SurfEventArray := nil;
                             SurfFile.ProbeArray := nil;
                             SurfFile.SValArray := nil;
                             SurfFile.SurfMsgArray := nil;
                             NumMsgs := 0;
                          end;
    SURF_OUT_FILEEND :    begin
                            ReceivingFile := FALSE;
                            FOnNewFile(SurfFile);
                            //clear the memory of all the dynamic arrays!
                            SurfFile.SurfEventArray := nil;
                            SurfFile.SValArray := nil;
                            SurfFile.SurfMsgArray := nil;
                            For p := 0 to Length(SurfFile.ProbeArray)-1 do
                            begin
                              SurfFile.ProbeArray[p].paramname := nil;
                              For s := 0 to Length(SurfFile.ProbeArray[p].spike)-1 do
                              begin
                                SurfFile.ProbeArray[p].spike[s].param := nil;
                                For c := 0 to Length(SurfFile.ProbeArray[p].spike[s].waveForm)-1 do
                                  SurfFile.ProbeArray[p].spike[s].waveForm[c] := nil;
                                SurfFile.ProbeArray[p].spike[s].waveForm := nil;
                              end;
                              SurfFile.ProbeArray[p].spike := nil;
                              For c := 0 to Length(SurfFile.ProbeArray[p].cr)-1 do
                                SurfFile.ProbeArray[p].cr[c].WaveForm := nil;
                              SurfFile.ProbeArray[p].cr := nil;
                            end;
                            SurfFile.ProbeArray := nil;
                          end;
    SURF_OUT_SURFEVENT_ARRAY:
                           begin
                             GetSurfEventArrayFromSurf(SurfEventArray,ReadIndex);
                             len := Length(SurfEventArray);
                             SetLength(SurfFile.SurfEventArray,Length(SurfFile.SurfEventArray)+len);
                             Move(SurfEventArray[0],SurfFile.SurfEventArray[SurfFile.NEvents],len*Sizeof(TSurfEvent));
                             inc(SurfFile.NEvents,len);
                           end;
    SURF_OUT_PROBE:        begin
                             i := Length(SurfFile.ProbeArray);
                             SetLength(SurfFile.ProbeArray,i+1);
                             GetProbeFromSurf(SurfFile.ProbeArray[i],ReadIndex);
                             //the spikes and crs of this probe will copy later
                           end;
    SURF_OUT_SPIKE_ARRAY:  begin
                             GetSpikeArrayFromSurf(SpikeArray,ReadIndex);
                             p := SurfFile.SurfEventArray[SpikeArray[0].EventNum].Probe;
                             len := Length(SurfFile.ProbeArray[p].Spike);
                             SetLength(SurfFile.ProbeArray[p].Spike,len+Length(SpikeArray));
                             For i := 0 to Length(SpikeArray)-1 do
                             begin
                               j := len+i;
                               Move(SpikeArray[i],SurfFile.ProbeArray[p].Spike[j],sizeof(TSpike)-8);
                               SetLength(SurfFile.ProbeArray[p].Spike[j].waveform,Length(SpikeArray[i].waveform));
                               SetLength(SurfFile.ProbeArray[p].Spike[j].param,Length(SpikeArray[i].param));
                               For w := 0 to Length(SpikeArray[i].waveform)-1 do
                               begin
                                 SetLength(SurfFile.ProbeArray[p].Spike[j].waveform[w],Length(SpikeArray[i].waveform[w]));
                                 Move(SpikeArray[i].waveform[w,0],SurfFile.ProbeArray[p].Spike[j].waveform[w,0],Length(SpikeArray[i].waveform[w])*2);
                                 SpikeArray[i].waveform[w] := nil;
                               end;
                               Move(SpikeArray[i].param[0],SurfFile.ProbeArray[p].Spike[j].param[0],Sizeof(SpikeArray[i].param));
                               SpikeArray[i].waveform := nil;
                               SpikeArray[i].param := nil;
                             end;
                           end;
    SURF_OUT_CR_ARRAY:     begin
                             GetCrArrayFromSurf(CrArray,ReadIndex);
                             p := SurfFile.SurfEventArray[CrArray[0].EventNum].Probe;
                             len := Length(SurfFile.ProbeArray[p].Cr);
                             SetLength(SurfFile.ProbeArray[p].Cr,Length(CrArray)+len);
                             For i := 0 to Length(CrArray)-1 do
                             begin
                               j := len+i;
                               Move(CrArray[i],SurfFile.ProbeArray[p].Cr[j],sizeof(TCr)-4);
                               SetLength(SurfFile.ProbeArray[p].Cr[j].waveform,Length(CrArray[i].waveform));
                               Move(CrArray[i].waveform[0],SurfFile.ProbeArray[p].Cr[j].waveform[0],Length(CrArray[i].waveform)*2);
                               CrArray[i].waveform := nil;
                             end;
                           end;
    SURF_OUT_SV_ARRAY:     begin
                             GetSValArrayFromSurf(SValArray,ReadIndex);
                             len := Length(SurfFile.SValArray);
                             SetLength(SurfFile.SValArray,Length(SValArray)+len);
                             Move(SValArray[0],SurfFile.SValArray[len],sizeof(TSVal)*Length(SValArray));
                           end;
    SURF_OUT_MSG_ARRAY:    begin
                             GetMsgArrayFromSurf(SurfMsgArray,ReadIndex);
                             len := Length(SurfFile.SurfMsgArray);
                             SetLength(SurfFile.SurfMsgArray,Length(SurfMsgArray)+len);
                             Move(SurfMsgArray[0],SurfFile.SurfMsgArray[len],sizeof(TSurfMsg)*Length(SurfMsgArray));
                           end;

  end{case};
end;

{----------------------------- DRAG AND DROP SUPPORT  -------------------------}
procedure TSurfAnal.AcceptFiles( var msg : TMsg{essage} );
const
  cnMaxFileNameLen = 255;var  i,  nCount     : integer;
  acFileName : array [0..cnMaxFileNameLen] of char;
begin
  nCount := DragQueryFile( msg.WParam,$FFFFFFFF,acFileName,cnMaxFileNameLen );
  //for i := 0 to nCount-1 do
  i := nCount-1;
  begin
    DragQueryFile( msg.WParam, i, acFileName, cnMaxFileNameLen );
    SendFileRequestToSurf(acFileName);
    SurfFile.FileName := acFileName;
  end;
  // let Windows know that you're done
  DragFinish( msg.WParam );
end;


{========================= WRITING FUNCTIONS ==================================}
Function TSurfAnal.NextWritePosition(size : integer) : integer;
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

Procedure TSurfAnal.WriteToBuffer(data : pchar; buf : pchar; size : integer; var writeindex : integer);
begin
  Move(data^,buf^,size);
  inc(writeindex,size);
end;
{------------------------- SEND NEW FILE REQUEST ------------------------------}
Procedure TSurfAnal.SendFileRequestToSurf(FileName : String);
var origindex,curindex : integer;
    size,i : integer;
    fn : array[0..255] of char;
begin
  size := sizeof(fn);
  //get the next write position
  CurIndex := NextWritePosition(size);
  origindex := curindex;

  for i := 0 to 255 do fn[i] := #0;
  for i := 0 to length(filename)-1 do fn[i] := filename[i+1];
  //fn := pchar(filename);
  //copy the Filename to the global data array
  WriteToBuffer(@fn,@GlobData^.data[curindex],size,curindex);
  //tell surf it is there
  PostMessage(SurfHandle,WM_SURF_IN,SURF_IN_READFILE,origindex);
end;

{========================= READING FUNCTIONS ==================================}
Procedure TSurfAnal.ReadFromBuffer(data : pchar; buf : pchar; size : integer; var readindex : integer);
begin
  Move(buf^,data^,size);
  inc(readindex,size);
end;

{------------------------  GET PROBE ------------------------------------------}
Procedure TSurfAnal.GetProbeFromSurf(var Probe : TProbe; ReadIndex : Integer);
var pc : array[0..31] of char;
    i : integer;
begin
  ReadFromBuffer(@Probe,@GlobData^.data[readindex],sizeof(TProbe),readindex);
  SetLength(Probe.paramname,probe.numparams);
  for i := 0 to probe.numparams -1 do
  begin
    ReadFromBuffer(@pc,@GlobData^.data[readindex],32,readindex);
    Probe.ParamName[i] := pc;
  end;
  Probe.Spike := nil;
  Probe.Cr := nil;
end;

{------------------------  GET SPIKEARRAY ------------------------------------------}
Procedure TSurfAnal.GetSpikeArrayFromSurf(var SpikeArray : TSpikeArray; ReadIndex : integer);
var bufdesc : TBufDesc;
    s,c : integer;
begin
  ReadFromBuffer(@bufdesc,@GlobData^.data[readindex],sizeof(TBufDesc),readindex);
  SetLength(SpikeArray,bufdesc.d4{nspikes});
  For s := 0 to bufdesc.d4-1 do
  begin
    ReadFromBuffer(@SpikeArray[s],@GlobData^.data[readindex],sizeof(TSpike)-8,readindex);
    SetLength(SpikeArray[s].waveform,bufdesc.d1{nchans});
    For c := 0 to bufdesc.d1-1 do
    begin
      SetLength(SpikeArray[s].waveform[c],bufdesc.d2{npts});
      ReadFromBuffer(@SpikeArray[s].WaveForm[c,0],@GlobData^.data[readindex],bufdesc.d2*2,readindex);
    end;
    SetLength(SpikeArray[s].Param,bufdesc.d3{nparams});
    ReadFromBuffer(@SpikeArray[s].Param[0],@GlobData^.data[readindex],bufdesc.d3*2,readindex);
  end;
end;

{------------------------  GET CRARRAY ------------------------------------------}
Procedure TSurfAnal.GetCrArrayFromSurf(var CrArray : TCrArray; ReadIndex : Integer);
var bufdesc : TBufDesc;
    c : integer;
begin
  ReadFromBuffer(@bufdesc,@GlobData^.data[readindex],sizeof(TBufDesc),readindex);
  SetLength(CrArray,bufdesc.d4{ncr});
  For c := 0 to bufdesc.d4-1 do
  begin
    ReadFromBuffer(@CrArray[c],@GlobData^.data[readindex],sizeof(TCr)-4,readindex);
    SetLength(CrArray[c].waveform,bufdesc.d2{npts});
    ReadFromBuffer(@CrArray[c].WaveForm[0],@GlobData^.data[readindex],bufdesc.d2*2,readindex);
  end;
end;

{------------------------  GET SVARRAY ---------------------------------------}
Procedure TSurfAnal.GetSValArrayFromSurf(var SValArray : TSValArray; ReadIndex : integer);
var bufdesc : TBufDesc;
begin
  ReadFromBuffer(@bufdesc,@GlobData^.data[readindex],sizeof(TBufDesc),readindex);
  SetLength(SValArray,bufdesc.d4);//nsv
  Move(GlobData^.data[readindex],SValArray[0],sizeof(TSVal)*bufdesc.d4);
end;

{------------------------  GET SURFMSG ARRAY---------------------------}
Procedure TSurfAnal.GetMsgArrayFromSurf(var SurfMsgArray : TSurfMsgArray; ReadIndex : integer);
var bufdesc : TBufDesc;
begin
  ReadFromBuffer(@bufdesc,@GlobData^.data[readindex],sizeof(TBufDesc),readindex);
  SetLength(SurfMsgArray,bufdesc.d4);//nsmsgs
  Move(GlobData^.data[readindex],SurfMsgArray[0],sizeof(TSurfMsg)*bufdesc.d4);
end;

{------------------------  GET SurfEventArray ------------------------------------------}
Procedure TSurfAnal.GetSurfEventArrayFromSurf(var SurfEventArray : TSurfEventArray; ReadIndex : integer);
var bufdesc : TBufDesc;
begin
  ReadFromBuffer(@bufdesc,@GlobData^.data[readindex],sizeof(TBufDesc),readindex);
  SetLength(SurfEventArray,bufdesc.d1);
  ReadFromBuffer(@SurfEventArray[0],@GlobData^.data[readindex],bufdesc.d1*sizeof(TSurfEvent),readindex);
end;

end.