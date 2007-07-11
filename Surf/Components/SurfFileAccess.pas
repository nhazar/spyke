{ (c) 2002-2003 Tim Blanche, University of British Columbia }
unit SurfFileAccess;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ExtCtrls, ShellAPI, FileProgressUnit, UFFTYPES, SURFTYPES, SURFPUBLICTYPES;

  {--- FOR BACKWARDS COMPATIBILITY ---------------------------------------------------------------}
CONST
   SURF_MAX_CHANNELS_V1 = 32;
TYPE
  TProbeWinLayout_V1 = array[0..SURF_MAX_CHANNELS_V1-1] of TPoint;
  TChanList_V1 = array[0..SURF_MAX_CHANNELS_V1-1] of SHRT;

  TEventTime = (Before, Exact, After);

  SURF_LAYOUT_REC_V1 = record { Type for all spike layout records }
    ufftype        : CHAR; // Record type  chr(234)
    time_stamp     : LNG;  // Time stamp
    surf_major     : BYTE; // SURF major version number
    surf_minor     : BYTE; // SURF minor version number

    probe          : SHRT; //Probe number
    ProbeSubType   : CHAR; //= E for spikeepoch, S for spikestream, and C for continuoustype
    nchans         : SHRT; //number of channels in the waveform
    pts_per_chan   : SHRT; //number of pts per waveform
    trigpt         : SHRT; // pts before trigger
    lockout        : SHRT; // Lockout in pts
    intgain        : SHRT; // A/D board internal gain
    threshold      : SHRT; // A/D board threshold for trigger
    skippts        : SHRT;
    sampfreqperchan: LNG;  // A/D sampling frequency
    chanlist       : TChanList_V1;
    //v1.0 had chanlist to be an array of 32 ints.  Now it is an array of 64, so delete 32*4=128 bytes from end
    ProbeWinLayout : TProbeWinLayout_V1;
    //v1.0 had ProbeWinLayout to be 4*32*2=256 bytes, now only 4*2=8 bytes, so add 248 bytes of pad

    probe_descrip  : ShortString;
    extgain        : array[0..SURF_MAX_CHANNELS_V1-1] of WORD;//added May21'99
    pad            : array[0..1023-64{959}] of byte;
  end;

  {--- END FOR BACKWARDS COMPATIBILITY-----------------------------------------------------------}

  SURF_FILE_HEADER          = UFF_FILE_HEADER; //2048 bytes
  SURF_DATA_REC_DESC_BLOCK  = UFF_DATA_REC_DESC_BLOCK;

  TProbeInfo = record
    iNumEpochs : integer;
    iNumChannels : integer;
    iPtsPerChannel : integer;
    iSamplesPerBuff : integer;
  end;

  THardwareInfo = record  //new Surf 2.0+
    iMasterClockFreq  : integer;
    iADCRetriggerFreq : integer;
  end;

  FlagType = array[0..1] of char; //this is probably PS, VD, etc?

  TSurfNewFileEvent = procedure(acFileName : wideString) of object;

  TFileStream64 = class(TFileStream)  //derived class has some support
  private                             //for files over 2^31 bytes
    function  GetPosition : Int64;    //nb: confirm locn of declarations!
    procedure SetPosition(Pos : Int64);
  public
    function Size : Int64; //read only, no 64bit SetSize
    function Seek64(Offset: Int64; Origin: Word): Int64;
    property Position: Int64 read GetPosition write SetPosition;
  end;

  {-------------------SufFileAccess class definition---------------------------}
  TSurfFileAccess = class(TComponent)//TPanel)
  private
      //SurfFile : TSurfFileInfo;//can be huge!
      m_PolytrodeRecord : array[0..SURF_MAX_PROBES] of SURF_SS_REC;

      //information about the file contents...
      m_ProbeIndexArray      : array of array of Int64; //for holding the file indicies of all epochs
      m_SValIndexArray       : array of Int64; //for holding the file indicies of all single values
      m_MsgIndexArray        : array of Int64; //for holding the file indicies of all messages
      m_StimIndexArray       : array of Int64; //for holding the file indicies of all stimulus headers
      m_SurfRecordIndexArray : array[0..SURF_MAX_PROBES] of Int64; //    "      "  "     "

      m_ProbeWaveFormLength : array[0..SURF_MAX_PROBES] of integer;

      m_iNumEvents : integer;
      m_iNumProbes : integer;
      m_iNumSVals  : integer;
      m_iNumMsgs   : integer;
      m_iNumStim   : integer;

      m_SurfEventArray : TSurfEventArray;
      m_HardwareInfo   : THardwareInfo;
      m_ProbeInfo : array[0..SURF_MAX_PROBES] of TProbeInfo;

      //file related...
      m_SurfStream : TFileStream64;//the handle to the data file
      m_iFileSize  : Int64;
      m_iFilePosition : Int64;
      m_bFileIsOpen : boolean;
      m_Header : UFF_FILE_HEADER;
      m_ptdrdb, m_lrdrdb, m_svdrdb, m_msgdrdb, m_dspdrdb : UFF_DATA_REC_DESC_BLOCK; //data record description blocks

      //declaration of an event call to the user
      FOnNewFile : TSurfNewFileEvent;

      FileProgressWin : TFileProgressWin;

      //Private function calls...
      Procedure m_Reset;
      Procedure m_AcceptFiles( var msg : TMsg{essage} );
      Procedure m_OnAppMessage(var Msg: TMsg; var Handled : Boolean);

      Function m_OpenSurfFileForReadWrite(Filename : wideString) : boolean;{success/nosuccess}
      Function m_GetSurfFileHeader(var Header : SURF_FILE_HEADER) : boolean;{success/nosuccess}
      Function m_GetSURFDRDB(var drdb : SURF_DATA_REC_DESC_BLOCK) : boolean;{success/nosuccess}

      Function m_UpdateSLR_V1(SurfRecord_V1 : SURF_LAYOUT_REC_V1; var slr : SURF_LAYOUT_REC) : boolean;{success/nosuccess}
      Function m_GetSurfLayoutRecord(var SurfRecord : SURF_LAYOUT_REC) : boolean;{success/nosuccess}

      Function m_GetNextFlag(var rt : flagtype) : boolean;{success/nosuccess}

      Function m_GetPolytrodeRecord(var PTRecord : SURF_SS_REC) : boolean;{success/nosuccess}
      Function m_GetSingleValueRecord(var SVRecord : SURF_SV_REC) : boolean;{success/nosuccess}
      Function m_GetDisplayHeaderRecord(var DSPRecord : SURF_DSP_REC) : boolean;{success/nosuccess}
      Function m_GetMessageRecord(var msg : SURF_MSG_REC) : boolean;{success/nosuccess}
  protected
    { Protected declarations }
      //still not entirely sure what the hell goes in here...
  public
    { Public declarations }
      Constructor Create(AOwner: TComponent); Override;

      Function Open(Filename : wideString) : boolean; //success/failure
      Procedure Close;

      Function Get64FileSize   : Int64; //handles huge (64bit) file sizes
      Function GetHardwareInfo : THardwareInfo;
      Function GetEventArray   : TSurfEventArray;

      Function GetNumProbes : integer;
      Function GetProbeRecord(iProbeIndex : integer; var Probe : TProbe) : boolean; //success/failure

      Function GetNumEpochs(iProbeIndex : integer) : integer; //either spikes or buffers (for CRs)

      Function GetSpike(iProbeIndex,iSpikeIndex : integer; var Spike : TSpike) : boolean; //success/failure
      Function GetClusterID(iProbeIndex, iSpikeIndex : integer) : integer; // tjb added 10/09/01
      Function SetSpikeClusterID(iProbeIndex,iSpikeIndex: integer; iClusterId : SHRT) : boolean; //success/failure

      //Function GetNumCrs(iProbeIndex : integer) : integer; ...redundant, replaced with GetNumEpochs
      Function GetCR(iProbeIndex, iCRIndex : integer; var Cr : TCr) : boolean; //success/failure

      Function GetNumSVals : integer;
      Function GetSVal(iSValIndex : integer; var SVal : TSVal) : boolean; //success/failure

      Function GetNumStimuli : integer;
      Function GetStimulusRecord(iStimIndex : integer; var StimulusHeader : TStimulusHeader) : boolean; //success/failure

      Function GetNumMessages : integer;
      Function GetSurfMsg(iMsgIndex : integer; var SurfMsg : TSurfMsg) : boolean; //success/failure
  published
    { Published declarations }
    property OnNewFile: TSurfNewFileEvent read FOnNewFile write FOnNewFile;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('SURF', [TSurfFileAccess]);
end;

{------------------------------------------------------------------------------}
Constructor TSurfFileAccess.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  if (csDesigning in ComponentState) then Exit;
  DragAcceptFiles( (AOwner as TForm).Handle, True );
  Application.OnMessage := m_OnAppMessage; //intercepts postmessages

  FileProgressWin:= TFileProgressWin.Create(AOwner);
  m_iNumProbes := 0;
  m_Reset;
end;

{-------------------------- Drag 'n' drop support -----------------------------}
procedure TSurfFileAccess.m_AcceptFiles( var msg : TMsg{essage} );
const
  cnMaxFileNameLen = 255;
var i, nCount : integer;
   acFileName : array [0..cnMaxFileNameLen] of char;
begin
  nCount:= DragQueryFile( msg.WParam,$FFFFFFFF,acFileName,cnMaxFileNameLen );
  //for i := 0 to nCount-1 do
  i:= nCount-1; //use the first file dropped on, ignore all others
  begin
    DragQueryFile( msg.WParam, i, acFileName, cnMaxFileNameLen );
    Open(acFileName);       //read file and get stats
    FOnNewFile(acFileName); //send update notice to user that file is available
    //SurfFile.FileName := acFileName;
  end;
  // let Windows know that you're done
  DragFinish( msg.WParam );
end;

{------------------------------------------------------------------------------}
Procedure TSurfFileAccess.m_OnAppMessage(var Msg: TMsg; var Handled : Boolean);
begin
  //Intercept only drag and drop events
  if Msg.Message = WM_DROPFILES then
  begin
    m_AcceptFiles(Msg);
    Handled := TRUE;
  end else Handled := FALSE;
end;

{------------------------------------------------------------------------------}
Procedure TSurfFileAccess.m_Reset;
var p : integer;
begin
  m_bFileIsOpen:= FALSE;
  m_iFilePosition:= 0;
  m_iFileSize:= 0;
  m_SurfStream:= nil;

  for p := 0 to m_iNumProbes -1 do
    m_ProbeIndexArray[p] := nil;
  m_ProbeIndexArray := nil; //for holding the file indicies of all probes
  m_SValIndexArray  := nil; //for holding the file indicies of all single values
  m_MsgIndexArray   := nil; //for holding the file indicies of all messages
  m_StimIndexArray  := nil; //for holding the file indicies of all stimulus headers
  m_SurfEventArray  := nil; //for holding a record of all events in the file in chronological order

  m_iNumProbes := 0;
  for p := 0 to SURF_MAX_PROBES do
  begin
    m_ProbeInfo[p].iNumEpochs:= 0;
    m_ProbeInfo[p].iPtsPerChannel:= 0;
    m_ProbeInfo[p].iNumChannels:= 0;
//    m_ProbeInfo[p].iNumCRs := 0;
  end;
  m_iNumSVals := 0;
  m_iNumMsgs  := 0;
  m_iNumStim  := 0;
end;

{------------------------------------------------------------------------------}
function TSurfFileAccess.m_OpenSurfFileForReadWrite(Filename : wideString) : boolean;{success/nosuccess}
var drdb : UFF_DATA_REC_DESC_BLOCK;
    ok : boolean;
begin
  //check to see if file exists
  m_SurfStream := TFileStream64.Create(Filename, fmShareDenyWrite);
  m_iFileSize  := m_SurfStream.Size; //handles 64 bit files

  //read the file header
  if not m_GetSurfFileHeader(m_Header) then
  begin
    Result := FALSE;
    m_SurfStream.Free;
    Exit;
  end;

  //read the DRDBs
  Result := TRUE;
  ok := TRUE;
  while ok do
  begin
    if m_GetSurfDRDB(drdb) then
    begin
      case drdb.DR_rec_type of
        SURF_PT_REC_UFFTYPE : Move(drdb, m_ptdrdb, SizeOf(drdb));
        SURF_SV_REC_UFFTYPE : Move(drdb, m_svdrdb, SizeOf(drdb));
        SURF_PL_REC_UFFTYPE : Move(drdb, m_lrdrdb, SizeOf(drdb));
        SURF_MSG_REC_UFFTYPE : Move(drdb, m_msgdrdb,SizeOf(drdb));
        SURF_DSP_REC_UFFTYPE : Move(drdb, m_dspdrdb,SizeOf(drdb));
      else begin
             ok := false;
             Result := FALSE;
             ShowMessage('Unknown data record found');
           end;
      end{case};
    end else
    begin
      //not a drdb, so backup read position
      m_SurfStream.Seek64(-SizeOf(drdb), soFromCurrent);
      ok:= False;
    end;
  end;
  m_iFilePosition:= m_SurfStream.Position;
end;

{------------------------------------------------------------------------------}
function TSurfFileAccess.m_GetSurfFileHeader(var Header : UFF_FILE_HEADER) : boolean;{success/nosuccess}
begin
  try
    m_SurfStream.ReadBuffer(header, SizeOf(SURF_FILE_HEADER)); //arg1 is what you read into, arg2 is how much you read
    if header.UFF_name <> 'UFF'
      then Result:= FALSE
      else Result:= TRUE;
  except
    {if EReadError}
    Result:= FALSE;
  end;
end;

{------------------------------------------------------------------------------}
function TSurfFileAccess.m_GetSurfDRDB(var drdb : UFF_DATA_REC_DESC_BLOCK) : boolean;{success/nosuccess}
begin
  try
    m_SurfStream.ReadBuffer(drdb, SizeOf(SURF_DATA_REC_DESC_BLOCK));
    if drdb.DRDB_rec_type <> 2
      then Result:= FALSE
      else Result:= TRUE;
  except
    {if EReadError}
    Result := FALSE;
  end;
end;

{------------------------------------------------------------------------------}
function TSurfFileAccess.m_GetNextFlag(var rt : flagtype) : boolean;{success/nosuccess}
begin
  try
    m_SurfStream.ReadBuffer(rt, 2); // grab the two character record tag
  except
    {if EReadError}
    Result:= False;
    Exit;
  end;
  Result:= True;
  m_SurfStream.Seek64(-2, soFromCurrent);
  m_iFilePosition:= m_SurfStream.Position;
  //dec(m_iFilePosition, 2);
end;

{------------------------------------------------------------------------------}
function TSurfFileAccess.m_UpdateSLR_V1(SurfRecord_V1 : SURF_LAYOUT_REC_V1; var slr : SURF_LAYOUT_REC) : boolean;
var i : integer;
begin
  try
    slr.ufftype        := SurfRecord_V1.ufftype;
    slr.TimeStamp      := SurfRecord_V1.time_stamp;
    slr.SurfMajor      := SurfRecord_V1.surf_major;
    slr.SurfMinor      := SurfRecord_V1.surf_minor;
    slr.probe          := SurfRecord_V1.probe;
    slr.ProbeSubType   := SurfRecord_V1.ProbeSubType;
    slr.nchans         := SurfRecord_V1.nchans;
    slr.pts_per_chan   := SurfRecord_V1.pts_per_chan;
    slr.trigpt         := SurfRecord_V1.trigpt;
    slr.lockout        := SurfRecord_V1.lockout;
    slr.intgain        := SurfRecord_V1.intgain;
    slr.threshold      := SurfRecord_V1.threshold;
    slr.skippts        := SurfRecord_V1.skippts;
    slr.sampfreqperchan:= SurfRecord_V1.sampfreqperchan;
    For i:= 0 to SURF_MAX_CHANNELS_V1 -1 do
    begin
      slr.chanlist[i]  := SurfRecord_V1.chanlist[i];
      slr.extgain[i]   := SurfRecord_V1.extgain[i];
    end;
    For i:= SURF_MAX_CHANNELS_V1 to SURF_MAX_CHANNELS-1 do//new since version 1: more channels
    begin
      slr.chanlist[i]  := -1;
      slr.extgain[i]   := 0;
    end;
    slr.ProbeWinLayout.left   := SurfRecord_V1.ProbeWinLayout[0].x; //new since version 1: one window per probe
    slr.ProbeWinLayout.top    := 0;//SurfRecord_V1.ProbeWinLayout[0].y;
    slr.ProbeWinLayout.width  := 0;
    slr.ProbeWinLayout.height := 0;
    slr.probe_descrip       := SurfRecord_V1.probe_descrip;
    slr.electrode_name      := 'UnDefined';  //new since version 1: electrode name
    Result := TRUE;
  except
    Result := FALSE;
  end;
end;

{------------------------------------------------------------------------------}
function TSurfFileAccess.m_GetSurfLayoutRecord(var SurfRecord : SURF_LAYOUT_REC) : boolean;{success/nosuccess}
var SlrV1 : SURF_LAYOUT_REC_V1;
begin
  try
    //is this a version 1?  if so, convert over...
    if m_lrdrdb.DR_name = 'SURF LAYOUT RECORD' then
    begin
      m_SurfStream.ReadBuffer(SlrV1, SizeOf(SURF_LAYOUT_REC_V1));
      m_UpdateSLR_V1(SlrV1, SurfRecord);
      if not ((SurfRecord.ProbeSubType = SPIKEEPOCH) or (SurfRecord.ProbeSubType = CONTINUOUS)) then
        if (SurfRecord.nchans > 1)
          then SurfRecord.ProbeSubType := SPIKEEPOCH;//this was #0 in 1.0
    end else
    if (m_lrdrdb.DR_name = 'SURF LAYOUT 1.1     ') or
       (m_lrdrdb.DR_name = 'SURF LAYOUT 2.0     ') then
    begin
      m_SurfStream.ReadBuffer(SurfRecord, SizeOf(SURF_LAYOUT_REC));
    end;

    with SurfRecord do
      m_ProbeWaveFormLength[probe]:= nchans * pts_per_chan; //necessary, others here too?

    Result:= True;
  except
    {if EReadError}
    ShowMessage('Exception raised reading Surf Records');
    Result:= False;
  end;
end;

{------------------------------------------------------------------------------}
function TSurfFileAccess.Open(Filename : wideString) : boolean; //success/failure
var rt : flagtype; // rt stands for record type?
  cUfftype, cSubtype : char;
  SurfRecord : SURF_LAYOUT_REC;
  PTRecord   : SURF_SS_REC;
  SVRecord   : SURF_SV_REC;
  MSGRecord  : SURF_MSG_REC;
  DSPRecord  : SURF_DSP_REC;
  prb        : integer;
  bHaltRead  : boolean;
begin
  Screen.Cursor := crHourGlass;
  m_Reset;

  if not m_OpenSurfFileForReadWrite(Filename) then
  begin
    Result := False;
    Screen.Cursor := crDefault;
    Exit;
  end;

  with FileProgressWin do
  begin
    FileProgress.MaxValue:= m_iFileSize div 100; //div prevents 32bit progressbar overflow with huge files
    FileProgress.Progress:= 0;
    Show;
    BringToFront;
    SetFocus;
  end;

  bHaltRead := FALSE;
  //reconstruct the whole file...
  while m_GetNextFlag(rt) and not bHaltRead do
  begin
    cUfftype := rt[0];
    cSubtype := rt[1];
    case cUfftype of
      SURF_PL_REC_UFFTYPE {'L'}: //probe layout record
        begin
          if not m_GetSurfLayoutRecord(SurfRecord) then
          begin
            ShowMessage('Error reading Spike Layout Record');
            bHaltRead := TRUE;
          end;

          with SurfRecord do
          begin
            if probe >= Length(m_ProbeIndexArray) then
              SetLength(m_ProbeIndexArray,probe + 1);
            SetLength(m_ProbeIndexArray[probe], 1000);

            m_ProbeInfo[probe].iNumEpochs:= 0;
            m_ProbeInfo[probe].iNumChannels:= nchans;
            m_ProbeInfo[probe].iPtsPerChannel:= pts_per_chan;
            m_ProbeInfo[probe].iSamplesPerBuff:= pts_per_buffer; //IS THIS SUPERFLUOUS??!!
            {cat9 only} //  m_ProbeInfo[probe].iSamplesPerBuff:= SampFreqPerChan div 10{BuffsPerSecond} * NChans;//THIS IS A TEMPORARY RECORD!

            m_HardwareInfo.iMasterClockFreq := MasterClockFreq;
            m_HardwareInfo.iADCRetriggerFreq:= BaseSampleFreq;

            m_SurfRecordIndexArray[probe]:= m_iFilePosition;

            inc(m_iNumProbes);
          end;
        end;
      SURF_PT_REC_UFFTYPE {'P'}: //handle spikes and continuous records
        case cSubtype of
          SPIKEEPOCH {'E'}: begin //spike-epoch record found...
                              try
                                m_SurfStream.ReadBuffer(PTRecord, SizeOf(SURF_SE_REC) - 4{the waveform pointer});
                                //Skip over the waveform
                                m_SurfStream.Seek64(m_ProbeWaveFormLength[PTRecord.probe] * 2, soFromCurrent);
                              except
                                Showmessage('Error reading spike epoch record');
                                bHaltRead := TRUE;
                              end;

                              inc(m_ProbeInfo[PTRecord.probe].iNumEpochs); //ie. NumSpikes

                              if m_ProbeInfo[PTRecord.probe].iNumEpochs >= Length(m_ProbeIndexArray[PTRecord.probe]) then
                                SetLength(m_ProbeIndexArray[PTRecord.probe],m_ProbeInfo[PTRecord.probe].iNumEpochs + 1000);

                              m_ProbeIndexArray[PTRecord.probe , m_ProbeInfo[PTRecord.probe].iNumEpochs-1] := m_iFilePosition;

                              if m_iNumEvents+1 > Length(m_SurfEventArray) then
                                SetLength(m_SurfEventArray,m_iNumEvents + 1000);
                              m_SurfEventArray[m_iNumEvents].Time_Stamp := PTRecord.TimeStamp;
                              m_SurfEventArray[m_iNumEvents].EventType :=  SURF_PT_REC_UFFTYPE;
                              m_SurfEventArray[m_iNumEvents].SubType := SPIKEEPOCH;
                              m_SurfEventArray[m_iNumEvents].Probe := PTRecord.probe;
                              m_SurfEventArray[m_iNumEvents].Index := m_ProbeInfo[PTRecord.probe].iNumEpochs-1;
                              inc(m_iNumEvents);
                            end;

         SPIKESTREAM {'S'}: begin //spike-stream record found... COLLAPSE WITH CONTINUOUS?
                              try
                                m_SurfStream.ReadBuffer(PTRecord, SizeOf(SURF_SS_REC) - 4{the waveform pointer});
                                //Skip over the waveform
                                PTRecord.NumSamples:= m_ProbeInfo[PTRecord.probe].iSamplesPerBuff;
                                m_SurfStream.Seek64(PTRecord.NumSamples * 2, soFromCurrent);
                              except
                                Showmessage('Error reading spike-stream record');
                                bHaltRead := TRUE;
                              end;

                              inc(m_ProbeInfo[PTRecord.probe].iNumEpochs); //ie. NumBuffers

                              if m_ProbeInfo[PTRecord.probe].iNumEpochs >= Length(m_ProbeIndexArray[PTRecord.probe]) then
                                SetLength(m_ProbeIndexArray[PTRecord.probe],m_ProbeInfo[PTRecord.probe].iNumEpochs + 1000);

                              m_ProbeIndexArray[PTRecord.probe, m_ProbeInfo[PTRecord.probe].iNumEpochs-1]:= m_iFilePosition;

                              if m_iNumEvents + 1 > Length(m_SurfEventArray) then
                                SetLength(m_SurfEventArray,m_iNumEvents + 1000);
                              //m_SurfEventArray[m_iNumEvents].Time_Stamp:= PTRecord.TimeStamp;
                              m_SurfEventArray[m_iNumEvents].EventType:=  SURF_PT_REC_UFFTYPE;
                              m_SurfEventArray[m_iNumEvents].SubType:= SPIKESTREAM;
                              m_SurfEventArray[m_iNumEvents].Probe:= PTRecord.Probe;
                              m_SurfEventArray[m_iNumEvents].Index:= m_ProbeInfo[PTRecord.probe].iNumEpochs - 1;
                              inc(m_iNumEvents);
                            end;

          CONTINUOUS {'C'}: begin //continuous record found
                              try
                                m_SurfStream.ReadBuffer(PTRecord, SizeOf(SURF_SS_REC) - 4{the waveform pointer});
                                //Skip over the waveform
                                PTRecord.NumSamples:= m_ProbeInfo[PTRecord.probe].iSamplesPerBuff {m_ProbeWaveFormLength};
                                m_SurfStream.Seek64(PTRecord.NumSamples * 2, soFromCurrent);
                              except
                                Showmessage('Error reading continuous record');
                                bHaltRead := TRUE;
                              end;

                              inc(m_ProbeInfo[PTRecord.probe].iNumEpochs); //ie. NumBuffers

                              if m_ProbeInfo[PTRecord.probe].iNumEpochs >= Length(m_ProbeIndexArray[PTRecord.probe]) then
                                SetLength(m_ProbeIndexArray[PTRecord.probe],m_ProbeInfo[PTRecord.probe].iNumEpochs + 100);

                              m_ProbeIndexArray[PTRecord.probe, m_ProbeInfo[PTRecord.probe].iNumEpochs-1]:= m_iFilePosition;

                              if m_iNumEvents + 1 > Length(m_SurfEventArray) then
                                SetLength(m_SurfEventArray,m_iNumEvents + 1000);
                              m_SurfEventArray[m_iNumEvents].Time_Stamp:= PTRecord.TimeStamp;
                              m_SurfEventArray[m_iNumEvents].EventType:=  SURF_PT_REC_UFFTYPE;
                              m_SurfEventArray[m_iNumEvents].SubType:= CONTINUOUS;
                              m_SurfEventArray[m_iNumEvents].Probe:= PTRecord.Probe;
                              m_SurfEventArray[m_iNumEvents].Index:= m_ProbeInfo[PTRecord.probe].iNumEpochs - 1;
                              inc(m_iNumEvents);
                            end;
          else Break;
        end;
      SURF_SV_REC_UFFTYPE {'V'}: //handle single values (including digital signals)
        case cSubtype of
          SURF_DIGITAL{'D'}:begin
                              try
                                m_SurfStream.ReadBuffer(SVRecord, SizeOf(SURF_SV_REC));
                              except
                                Showmessage('Error reading single value record');
                                bHaltRead := TRUE;
                              end;

                              inc(m_iNumSVals);
                              if m_iNumSVals >= Length(m_SValIndexArray) then
                                SetLength(m_SValIndexArray,m_iNumSVals + 1000);

                              m_SValIndexArray[m_iNumSVals - 1]:= m_iFilePosition;

                              if m_iNumEvents + 1 > Length(m_SurfEventArray) then
                                SetLength(m_SurfEventArray,m_iNumEvents + 1000);

                              m_SurfEventArray[m_iNumEvents].Time_Stamp:= SVRecord.TimeStamp;
                              m_SurfEventArray[m_iNumEvents].EventType:=  SURF_SV_REC_UFFTYPE;
                              m_SurfEventArray[m_iNumEvents].SubType:= SURF_DIGITAL;
                              m_SurfEventArray[m_iNumEvents].Probe:= -1;
                              m_SurfEventArray[m_iNumEvents].Index:= m_iNumSVals - 1;
                              inc(m_iNumEvents);
                            end;
          else Break;
        end;
      SURF_MSG_REC_UFFTYPE {'M'}: //handle messages (both Surf- and user-generated)
                            begin
                              try
                                //m_SurfStream.ReadBuffer(MSGRecord, {SizeOf(SURF_MSG_REC)-4}280);
                                m_SurfStream.ReadBuffer(MSGRecord, SizeOf(SURF_MSG_REC)-4);
                                //Skip over the message
                                m_SurfStream.Seek64(MSGRecord.MsgLength, soFromCurrent);
                              except
                                Showmessage('Error reading message record');
                                bHaltRead := TRUE;
                              end;

                              inc(m_iNumMsgs);
                              if m_iNumMsgs >= Length(m_MsgIndexArray) then
                                SetLength(m_MsgIndexArray, m_iNumMsgs + 100);

                              m_MsgIndexArray[m_iNumMsgs - 1]:= m_iFilePosition;

                              if m_iNumEvents + 1 > Length(m_SurfEventArray) then
                                SetLength(m_SurfEventArray,m_iNumEvents + 1000);

                              m_SurfEventArray[m_iNumEvents].Time_Stamp:= MSGRecord.TimeStamp;
                              m_SurfEventArray[m_iNumEvents].EventType:=  SURF_MSG_REC_UFFTYPE;
                              m_SurfEventArray[m_iNumEvents].SubType:= MSGRecord.SubType;
                              m_SurfEventArray[m_iNumEvents].Probe:= -1; //not applicable
                              m_SurfEventArray[m_iNumEvents].Index:= m_iNumMsgs - 1;
                              inc(m_iNumEvents);
                            end;
      SURF_DSP_REC_UFFTYPE {'D'}: //handle stimulus display header records
                            begin
                              try
                                m_SurfStream.ReadBuffer(DSPRecord, SizeOf(SURF_DSP_REC));
                              except
                                Showmessage('Error stimulus display header record');
                                bHaltRead := TRUE;
                              end;

                              inc(m_iNumStim);
                              if m_iNumStim >= Length(m_StimIndexArray) then
                                SetLength(m_StimIndexArray, m_iNumStim + 5);

                              m_StimIndexArray[m_iNumStim - 1]:= m_iFilePosition;

                              if m_iNumEvents + 1 > Length(m_SurfEventArray) then
                                SetLength(m_SurfEventArray,m_iNumEvents + 1000);

                              m_SurfEventArray[m_iNumEvents].Time_Stamp:= DSPRecord.TimeStamp;
                              m_SurfEventArray[m_iNumEvents].EventType:=  SURF_DSP_REC_UFFTYPE;
                              m_SurfEventArray[m_iNumEvents].SubType:= ' ';
                              m_SurfEventArray[m_iNumEvents].Probe:= -1;
                              m_SurfEventArray[m_iNumEvents].Index:= m_iNumStim - 1;
                              inc(m_iNumEvents);
                            end;
    end {main case};
    FileProgressWin.FileProgress.Progress:= m_iFilePosition div 100;
    if FileProgressWin.ESCPressed then Break;
    Application.ProcessMessages; //catch ESC key presses
  end {main loop};

  {shrink dynamic arrays to required size}
  SetLength(m_ProbeIndexArray, m_iNumProbes);
  for prb := 0 to m_iNumProbes -1 do
  {begin
    if m_PolytrodeRecord[prb].subtype = SPIKEEPOCH then}
      SetLength(m_ProbeIndexArray[prb], m_ProbeInfo[prb].iNumEpochs);
    {if m_PolytrodeRecord[prb].subtype = CONTINUOUS then
      SetLength(m_ProbeIndexArray[prb],m_ProbeInfo[prb].iNumEpochs);
  end;}
  SetLength(m_SValIndexArray, m_iNumSVals);
  SetLength(m_MsgIndexArray,  m_iNumMsgs);
  SetLength(m_StimIndexArray, m_iNumStim);
  SetLength(m_SurfEventArray, m_iNumEvents);

  FileProgressWin.Release;
  m_bFileIsOpen:= True;
  Result:= m_bFileIsOpen; //set return value to indicate success
  Screen.Cursor:= crDefault;
end;

{------------------------------------------------------------------------------}
function TSurfFileAccess.Get64FileSize : Int64;
begin
  if m_bFileIsOpen then
    Result:= m_iFileSize
  else
    Result:= 0;
end;

{------------------------------------------------------------------------------}
Procedure TSurfFileAccess.Close;
begin
  m_SurfStream.Free;
  m_Reset;
end;

{------------------------------------------------------------------------------}
function TSurfFileAccess.m_GetPolytrodeRecord(var PTRecord : SURF_SS_REC) : boolean;{success/nosuccess}
begin
  try
    //read the record w/o the waveform
    //m_SurfStream.ReadBuffer(PTRecord, SizeOf(SURF_SS_REC) - 4{the waveform pointer});
    //SetLength(PTRecord.ADCWaveform, m_ProbeInfo[iProbeIndex].iSamplesPerBuff{PTRecord.NumSamples});
    //now read the waveform
    //m_SurfStream.ReadBuffer(PTRecord.ADCWaveform, {m_ProbeWaveFormLength[PTRecord.probe]}
    //                        m_ProbeInfo[iProbeIndex].iSamplesPerBuff * 2);//PTRecord.NumSamples * 2{sizeof(SHRT)});
    //Result := True;
  except
    {if EReadError}
    Result:= False;
  end;
end;

{------------------------------------------------------------------------------}
function TSurfFileAccess.m_GetSingleValueRecord(var SVRecord : SURF_SV_REC) : boolean;{success/nosuccess}
begin
  try
    m_SurfStream.ReadBuffer(SVRecord, SizeOf(SURF_SV_REC));
    Result := TRUE;
  except
    {if EReadError}
    Result := FALSE;
  end;
end;

{------------------------------------------------------------------------------}
function TSurfFileAccess.m_GetDisplayHeaderRecord(var DSPRecord : SURF_DSP_REC) : boolean;{success/nosuccess}
begin
  try
    m_SurfStream.ReadBuffer(DSPRecord, SizeOf(SURF_DSP_REC));
    Result := TRUE;
  except
    {if EReadError}
    Result := FALSE;
  end;
end;


{------------------------------------------------------------------------------}
function TSurfFileAccess.m_GetMessageRecord(var msg : SURF_MSG_REC) : boolean;{success/nosuccess}
begin
  try
    m_SurfStream.ReadBuffer(Msg, SizeOf(SURF_MSG_REC) - 4{<-- remove - 4 for Cat 9}); //for fixed shortstrings --> m_SurfStream.ReadBuffer(Msg, SizeOf(SURF_MSG_REC));
    SetLength(Msg.Msg, msg.MsgLength);{remove preceeding for CAT 9, and change following line too...}
    m_SurfStream.ReadBuffer(Msg.msg[1]{Pointer(Msg.Msg)^}, msg.MsgLength{dynamic}); //for fixed shortstrings --> m_SurfStream.ReadBuffer(Msg.msg{Pointer(Msg.Msg)^}, 256{len}){dynamic};
    Result:= True;
  except
    {if EReadError}
    Result:= False;
  end;
end;

{------------------------------------------------------------------------------}
function TSurfFileAccess.GetEventArray : TSurfEventArray;
begin
  if m_bFileIsOpen then
    Result:= m_SurfEventArray
  else
    Result:= nil;
end;

{------------------------------------------------------------------------------}
function TSurfFileAccess.GetHardwareInfo : THardwareInfo;
begin
  if m_bFileIsOpen then
    Result:= m_HardwareInfo
  else
  begin
    Result.iMasterClockFreq:= 0;
    Result.iADCRetriggerFreq:= 0;
  end;
end;

{------------------------------------------------------------------------------}
function TSurfFileAccess.GetNumProbes : integer;
begin
  if m_bFileIsOpen then
    Result:= m_iNumProbes
  else
    Result:= 0;
end;

{------------------------------------------------------------------------------}
function TSurfFileAccess.GetNumEpochs(iProbeIndex : integer) : integer;
begin
  if m_bFileIsOpen then
  begin
     //check to make sure the probeid is valid
     if ((iProbeIndex <0) or (iProbeIndex >= m_iNumProbes)) then
     begin
       result:= 0;
       exit;
     end;
     Result:= m_ProbeInfo[iProbeIndex].iNumEpochs; //either spike-epochs or buffers
  end else
    Result:= 0;
end;

{------------------------------------------------------------------------------}
function TSurfFileAccess.GetProbeRecord(iProbeIndex : integer; var Probe : TProbe) : boolean; //success/failure
//fill in the surfrecord for a specified probe from the file
var SurfRecord : SURF_LAYOUT_REC;

Procedure FillInProbe(var prb : TProbe; sr : SURF_LAYOUT_REC);
var c : integer;
begin
  Prb.ProbeSubType    := sr.ProbeSubType;
  Prb.numchans        := sr.nchans;
  Prb.pts_per_chan    := sr.pts_per_chan;
  Prb.pts_per_buffer  := sr.pts_per_buffer; //new since v2 {not for cat 9!!!}
  Prb.trigpt          := sr.trigpt;
  Prb.skippts         := sr.skippts;
  Prb.lockout         := sr.lockout;
  Prb.threshold       := sr.threshold;
  Prb.sampfreqperchan := sr.sampfreqperchan;
  Prb.intgain         := sr.intgain;
  Prb.sh_delay_offset := sr.sh_delay_offset; //new since v2 {zero -->NOT IN CAT 9 !!!}
  Prb.probe_descrip   := sr.probe_descrip;
  Prb.electrode_name  := sr.electrode_name; //new since v1
  Prb.numspikes       := 0;
  Prb.numcr           := 0;
  Prb.Spike           := nil;
  Prb.CR              := nil;
  Prb.numparams       := 0;
  Prb.paramname       := nil;
  for c:= 0 to SURF_MAX_CHANNELS-1 do
  begin
    Prb.chanlist[c]   := sr.chanlist[c];
    Prb.extgain[c]    := sr.extgain[c];
  end;
  Move(sr.ProbeWinLayout, Prb.ProbeWinLayout, SizeOf(TProbeWinLayout));
end;
begin
  if m_bFileIsOpen then
  begin
     //check to make sure the probeid is valid
     if ((iProbeIndex <0) or (iProbeIndex >= m_iNumProbes)) then
     begin
       Result:= False;
       Showmessage('Probe out of range!');
       Exit;
     end;
     if m_SurfRecordIndexArray[iProbeIndex] <> m_SurfStream.Position then
       m_SurfStream.Position:= m_SurfRecordIndexArray[iProbeIndex];
     Result:= m_GetSurfLayoutRecord(SurfRecord);
     //copy over probe
     FillInProbe(Probe, SurfRecord);
  end else
    Result:= False;
end;

{------------------------------------------------------------------------------}
Function TSurfFileAccess.GetSpike(iProbeIndex, iSpikeIndex : integer; var Spike : TSpike) : boolean; //success/failure
var c,p : integer;
begin
  if m_bFileIsOpen then
  begin
     //check to make sure the probeid is valid
     if ((iProbeIndex <0) or (iProbeIndex >= m_iNumProbes)) then
     begin
       result := false;
       exit;
     end;
     if ((iSpikeIndex < 0) or (iSpikeIndex >= m_ProbeInfo[iProbeIndex].iNumEpochs)) then
     begin
       result := false;
       exit;
     end;

     //go to file location if it is not already there
     if m_ProbeIndexArray[iProbeIndex, iSpikeIndex] <> m_SurfStream.Position then
       m_SurfStream.Position:= m_ProbeIndexArray[iProbeIndex, iSpikeIndex];

     if not m_GetPolytrodeRecord(m_PolytrodeRecord[iProbeIndex]) then
     begin
       Result := false;
       exit;
     end;

     //Copy the polytrode record from the disk to the spike record from the user
     //Allocate memory for the waveform (dynamic, so won't crash if already allocated)
     Spike.time_stamp := m_PolytrodeRecord[iProbeIndex].TimeStamp;
     //Spike.cluster := m_PolytrodeRecord[iProbeIndex].cluster;
     Spike.EventNum := 0;//this was used for bidirectional indexing with the event array
     //Spike.param := ?

     //allocate and copy the waveform
     SetLength(Spike.waveform,m_ProbeInfo[iProbeIndex].iNumChannels);
     for c := 0 to m_ProbeInfo[iProbeIndex].iNumChannels-1 do
     begin
       SetLength(Spike.waveform[c],m_ProbeInfo[iProbeIndex].iPtsPerChannel);
//       for p := 0 to m_ProbeInfo[iProbeIndex].iPtsPerChannel-1 do
//         Spike.waveform[c,p] := m_PolytrodeRecord[iProbeIndex].ADCWaveform[p*m_ProbeInfo[iProbeIndex].iNumChannels+c];
     end;
     Result := True;
  end else Result := False;
end;

{------------------------------------------------------------------------------}
Function TSurfFileAccess.SetSpikeClusterId(iProbeIndex,iSpikeIndex: integer; iClusterId : smallint) : boolean; //success/failure
begin
  if m_bFileIsOpen then
  begin
     //check to make sure the probeid is valid
     if ((iProbeIndex <0) or (iProbeIndex >= m_iNumProbes)) then
     begin
       result := false;
       exit;
     end;
     if ((iSpikeIndex < 0) or (iSpikeIndex >= m_ProbeInfo[iProbeIndex].iNumEpochs)) then
     begin
       result := false;
       exit;
     end;

     //go to file location if it is not already there
     if m_ProbeIndexArray[iProbeIndex, iSpikeIndex] <> m_SurfStream.Position then
       m_SurfStream.Position:= m_ProbeIndexArray[iProbeIndex, iSpikeIndex];

     try
       m_SurfStream.Seek64(8, soFromCurrent); //to the cluster record
       m_SurfStream.Write(iClusterId, SizeOf(iClusterId));
       Result:= True;
     except
       result := FALSE;
     end;
  end else result := FALSE;
end;

{------------------------------------------------------------------------------}
{Function TSurfFileAccess.GetNumCrs(iProbeIndex : integer) : integer;
begin
  if m_bFileIsOpen then
  begin
     //check to make sure the probeid is valid
     if ((iProbeIndex <0) or (iProbeIndex >= m_iNumProbes)) then
     begin
       result := 0;
       exit;
     end;
     result := m_ProbeInfo[iProbeIndex].iNumEpochs;
  end else
    result := 0;
end;
}
{------------------------------------------------------------------------------}
Function TSurfFileAccess.GetClusterID(iProbeIndex, iSpikeIndex : integer) : integer;
begin
  if m_bFileIsOpen then
  begin
     //check to make sure the probeid is valid
     if ((iProbeIndex <0) or (iProbeIndex >= m_iNumProbes)) then
     begin
       result := -1;
       exit;
     end;
     if ((iSpikeIndex < 0) or (iSpikeIndex >= m_ProbeInfo[iProbeIndex].iNumEpochs)) then
     begin
       result := -1;
       exit;
     end;

     //go to file location if it is not already there
     if m_ProbeIndexArray[iProbeIndex, iSpikeIndex] <> m_SurfStream.Position then
       m_SurfStream.Position:= m_ProbeIndexArray[iProbeIndex, iSpikeIndex];

     if not m_GetPolytrodeRecord(m_PolytrodeRecord[iProbeIndex]) then
     begin
       Result := -1;
       exit;
     end;
//     Result := m_PolytrodeRecord[iProbeIndex].cluster;
  end else result := -1;
end;

{------------------------------------------------------------------------------}
function TSurfFileAccess.GetCR(iProbeIndex, iCrIndex : integer; var Cr : TCr) : boolean; //success/failure
var c, p : integer;
begin
  if m_bFileIsOpen then
  begin
     //check to make sure the probeid and CRIndex are valid
     if ((iProbeIndex <0) or (iProbeIndex >= m_iNumProbes)) then
     begin
       Result:= False;
       Showmessage('Probe index out of bounds');
       Exit;
     end;
     if ((iCrIndex < 0) or (iCrIndex >= m_ProbeInfo[iProbeIndex].iNumEpochs)) then
     begin
       Result:= False;
       Showmessage('CR index out of bounds');
       Exit;
     end;

     //jump to file location if it is not already there
     if m_ProbeIndexArray[iProbeIndex, iCrIndex] <> m_SurfStream.Position {+ SizeOf(SURF_SS_REC) - 4} then
       m_SurfStream.Position:= m_ProbeIndexArray[iProbeIndex, iCrIndex] {+ SizeOf(SURF_SS_REC) - 4}; //?????
     try
       //read the record w/o the waveform
       m_SurfStream.ReadBuffer(m_PolytrodeRecord[iProbeIndex], SizeOf(SURF_SS_REC) - 4{the waveform pointer});
       SetLength(CR.Waveform, m_ProbeInfo[iProbeIndex].iSamplesPerBuff{PTRecord.NumSamples});
       //now read the waveform
       m_SurfStream.ReadBuffer(CR.Waveform[0], {m_ProbeWaveFormLength[PTRecord.probe]}
                               m_ProbeInfo[iProbeIndex].iSamplesPerBuff * 2);//PTRecord.NumSamples * 2{sizeof(SHRT)});
       Result := True;
     except
       {if EReadError}
       Result := False;
     end;

     {if not m_GetPolytrodeRecord(m_PolytrodeRecord[iProbeIndex]) then
     begin
       Result:= False; //??????????IS THIS NEEDED? WHY WASN'T THIS READ WHEN INDEX TABLE WASS BUILT?
       Showmessage('m_GetPolytrodeRecord error');
       Exit;
     end;}

     CR.time_stamp:= m_PolytrodeRecord[iProbeIndex].TimeStamp;
     CR.EventNum:= 0;

     //Copy the polytrode record from the disk to the CR record given by the user
     //Allocate memory for the waveform (dynamic, so won't crash if already allocated)
     //allocate and copy the waveform
     //SetLength(CR.Waveform, m_ProbeInfo[iProbeIndex].iPtsPerChannel);
     {Setlength(CR.Waveform, m_ProbeInfo[iProbeIndex].iSamplesPerBuff{iPtsPerChannel}{);
     Move(m_PolytrodeRecord[iProbeIndex].ADCWaveform[0], CR.Waveform[0], m_PolytrodeRecord[iProbeIndex].NumSamples * 2);//m_ProbeInfo[iProbeIndex].iPtsPerChannel*sizeof(Cr.waveform[0]));}
     Result := True;
  end else Result := False;
end;

{------------------------------------------------------------------------------}
Function TSurfFileAccess.GetNumSVals : integer;
begin
  if m_bFileIsOpen then
    result := m_iNumSVals
  else
    result := 0;
end;

{------------------------------------------------------------------------------}
function TSurfFileAccess.GetSVal(iSValIndex : integer; var SVal : TSVal) : boolean; //success/failure
var SVRecord : SURF_SV_REC;
begin
  if m_bFileIsOpen then
  begin
     //check to make sure the probeid is valid
     if ((iSValIndex < 0) or (iSValIndex >= m_iNumSVals)) then
     begin
       Result:= False;
       Exit;
     end;
     //go to file location if it is not already there
     if m_SValIndexArray[iSValIndex] <> m_SurfStream.Position then
       m_SurfStream.Position:= m_SValIndexArray[iSValIndex];

     if not m_GetSingleValueRecord(SVRecord) then
     begin
       Result:= False;
       Exit;
     end;

     //Copy the single value from the disk to the single value record from the user
     SVal.Time_Stamp:= SVRecord.TimeStamp;
     SVal.SubType:= SVRecord.SubType;
     SVal.EventNum:= 0;
     SVal.SVal:= SVRecord.SVal;

     Result:= True;
  end else Result:= False;
end;

{------------------------------------------------------------------------------}
function TSurfFileAccess.GetNumMessages : integer;
begin
  if m_bFileIsOpen then
    result := m_iNumMsgs
  else
    result := 0;
end;

{------------------------------------------------------------------------------}
function TSurfFileAccess.GetNumStimuli;
begin
  if m_bFileIsOpen then
    result := m_iNumStim
  else
    result := 0;
end;

{------------------------------------------------------------------------------}
function TSurfFileAccess.GetStimulusRecord(iStimIndex : integer; var StimulusHeader : TStimulusHeader) : boolean; //success/failure;
var StimRecord : SURF_DSP_REC;
begin
  if m_bFileIsOpen then
  begin
     //check to make sure the index is valid
     if ((iStimIndex < 0) or (iStimIndex >= m_iNumStim)) then
     begin
       Result:= False;
       Exit;
     end;
     //go to file location if it is not already there
     if m_StimIndexArray[iStimIndex] <> m_SurfStream.Position then
       m_SurfStream.Position:= m_StimIndexArray[iStimIndex];

     if not m_GetDisplayHeaderRecord(StimRecord) then
     begin
       Result:= False;
       Exit;
     end;
     //Copy the stimlus header record from the disk to the stimulus record from the user
     StimulusHeader:= StimRecord.Header;
     //and what about the timestamp, datetime etc?!!!
     Result:= True;
  end else Result:= False;
end;

{------------------------------------------------------------------------------}
function TSurfFileAccess.GetSurfMsg(iMsgIndex : integer; var SurfMsg : TSurfMsg) : boolean; //success/failure
var MsgRecord : SURF_MSG_REC;
begin
  if m_bFileIsOpen then
  begin
     //check to make sure the probeID is valid
     if ((iMsgIndex <0) or (iMsgIndex >= m_iNumMsgs)) then
     begin
       Result:= False;
       Exit;
     end;
     //go to file location if it is not already there
     if m_MsgIndexArray[iMsgIndex] <> m_SurfStream.Position then
       m_SurfStream.Position:= m_MsgIndexArray[iMsgIndex];

     if not m_GetMessageRecord(MsgRecord) then
     begin
       Result:= False;
       Exit;
     end;

     //Copy the message from the file to the message record from the user
     SurfMsg.TimeStamp:= MsgRecord.TimeStamp;
     SurfMsg.DateTime:= MsgRecord.DateTime;
     SurfMsg.EventNum:= 0;
     SurfMsg.Msg:= MsgRecord.Msg;

     Result:= True;
  end else Result:= False;
end;

{------------------------------------------------------------------------------}
function TFileStream64.Size : Int64;
var i64 : record
      LoDWord: LongWord;
      HiDWord: LongWord;
    end;
begin
  i64.LoDWord:= GetFileSize(Handle, @i64.HiDWord);
  if (i64.LoDWord = MAXDWORD) and (GetLastError <> 0) then Result:= 0
    else Result:= PInt64(@i64)^;
end;

{------------------------------------------------------------------------------}
function TFileStream64.GetPosition : Int64;
{var
  Low, High : Int64;}
begin
  Result:= Seek64(0, FILE_CURRENT); //simpler method from Delphi 'Classes' unit
  {High:=0;
  Low:= SetFilePointer(Handle, 0, Ptr(High), FILE_CURRENT);
  High:= High shl 32;
  Result:= High + Low;}
end;

{------------------------------------------------------------------------------}
procedure TFileStream64.SetPosition(Pos : Int64);
begin
  Seek64(Pos, 0);
end;

{------------------------------------------------------------------------------}
function TFileStream64.Seek64(Offset: Int64; Origin: Word): Int64;
begin
  Result:= FileSeek(Handle, Offset, Origin); //---> D5 SysUtils ---> WinAPI
end;

end.