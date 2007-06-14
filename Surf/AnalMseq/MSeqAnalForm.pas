unit MSeqAnalForm;

interface

USES
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Gauges, ComCtrls, SurfFile, StdCtrls, SurfPublicTypes, Spin, Math, ExtCtrls,
  SurfAnal, SurfFileAccess;

CONST
  MAXLEN = 31;
  NOSTIMULUS = -999;
  POLYPRIMATIVES : array[1..MAXLEN,0..4] of longint
  = ((1,1, 0, 0, 0),{1}
     (2,1, 2, 0, 0),{2}
     (2,1, 3, 0, 0),{3}
     (2,1, 4, 0, 0),{4}
     (2,2, 5, 0, 0),{5}
     (2,1, 6, 0, 0),{6}
     (2,1, 7, 0, 0),{7}
     (4,2, 3, 4, 8),{8}
     (2,4, 9, 0, 0),{9}
     (2,6,10, 0, 0),{10 was (2,3,10, 0, 0)}
     (4,1, 2, 4,11),{11 was (2,2,11, 0, 0)}
     (4,1, 4, 6,12),{12}
     (4,1, 3, 4,13),{13}
     (4,1, 3, 5,14),{14}  //this is 16x16 (2^4 * 2^4) with an offset of 64 (2^6) = 2^14
     (2,1,15, 0, 0),{15}
     (4,2, 3, 5,16),{16}  //this is 32x32 (2^5 * 2^5) with an offset of 64 (2^6) = 2^16
     (2,3,17, 0, 0),{17}
     (4,1, 2, 5,18),{18}
     (4,1, 2, 5,19),{19}
     (2,3,20, 0, 0),{20 was (2,3,20, 0, 0)}
     (2,2,21, 0, 0),{21 was (2,2,21, 0, 0)}
     (2,1,22, 0, 0),{22}
     (2,5,23, 0, 0),{23}
     (4,1, 3, 4,24),{24}
     (2,3,25, 0, 0),{25}
     (4,1, 2, 6,26),{26}
     (4,1, 2, 5,27),{27}
     (2,3,28, 0, 0),{28}
     (2,2,29, 0, 0),{29}
     (4,1, 4, 6,30),{30}
     (2,3,31, 0, 0)){31};

     AD2DEG = 81.92;

type
  TMSeqForm = class(TForm)
    StatusBar: TStatusBar;
    Label4: TLabel;
    nspikes: TLabel;
    label13: TLabel;
    mseqval: TLabel;
    StopButton: TButton;
    Label7: TLabel;
    time: TLabel;
    Label6: TLabel;
    ndig: TLabel;
    Label1: TLabel;
    Label5: TLabel;
    NPixelPower: TSpinEdit;
    offset: TSpinEdit;
    mseqimg: TImage;
    DisplayMSeq: TCheckBox;
    Pause: TCheckBox;
    Label15: TLabel;
    Label16: TLabel;
    Label19: TLabel;
    SurfFileAccess1: TSurfFileAccess;
    Gauge: TGauge;
    Button1: TButton;
    procedure StopButtonClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure TimeSliceSpinChange(Sender: TObject);
    //procedure SpinEdit1Change(Sender: TObject);
    procedure SurfFileAccessNewFile(acFileName: WideString);
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
    HaltRead : boolean;
    mseq : array of smallint;
    Stimulus : TSValArray;//TStimulus;
    SpikeTimes : array of int64;
    nStimFrames : integer;
    NPixels,patno,morder,mlength,moffset,mask : integer{longword};
    //mousedown,hitstop : boolean;
    ms3d : array of array of array of ShortInt;
    mseqbm : Tbitmap;
    white, black : byte;
    wid,hei : integer;
    grayvals : array[0..255] of byte;
    procedure ComputeStimuli(SurfFile : TSurfFileInfo; var Stimulus : TStimulus);
    procedure GetStimuliRecords(FileName : string);
    function irbit2(var iseed: integer{longword}; loib,hiib : integer{longword}): SmallInt;
    function Color2Grey(col : TColor) : smallint;
    function Grey2Color (gval : smallint) : TColor;
    procedure GenerateMSeq;
    procedure DoMseq;
    procedure ShowMseq(index,ir : integer{longword});
  public
    { Public declarations }
  end;

var
  MSeqForm: TMSeqForm;

implementation

{$R *.DFM}

{---------------------------------------------------------------------------}
Function TMSeqForm.irbit2(var iseed: integer; loib,hiib : integer): SmallInt;
{returns as an integer a random bit, based on the hiib low-significance bits
 in iseed (which is modified for the next call}
begin
  if iseed and hiib <> 0 then
  begin
    iseed:= ((iseed xor mask) shl 1) or 1;
    irbit2:= 1;
  end else
  begin
    iseed:= iseed shl 1;
    irbit2:= 0;
  end;
end;

{---------------------------------------------------------------------------}
procedure TMSeqForm.DoMseq;
var x,t,i,b,hiib,loib : integer{longword};
    xysize : longint;
   s : string;
begin
  hiib := trunc(power(2,POLYPRIMATIVES[morder,POLYPRIMATIVES[morder,0]]-1));
  loib := trunc(power(2,POLYPRIMATIVES[morder,1]-1));
  mask := 0;
  for i := 1 to POLYPRIMATIVES[morder,0]-1 do mask := mask + trunc(power(2,POLYPRIMATIVES[morder,i]-1));

  b := 1;{seed}
  for t := 0 to mlength-1 do
    mseq[t] := irbit2(b,loib,hiib)*2-1;
  xysize := trunc(sqrt(npixels));
  if sqr(xysize) <> npixels then inc(xysize); //if npixels is not square rootable then make the display larger
end;

{---------------------------------------------------------------------------}
procedure TMSeqForm.GenerateMSeq;
var xysize : longint;
    p : PByteArray;
    i : integer;
begin
  npixels:= round(power(2,npixelpower.value));
  moffset:= trunc(power(2,offset.value));
  morder := round(log2(npixels * moffset));
  mlength:= trunc(power(2,morder)-1);
  offset.value:= round(log2(mlength/npixels));
  moffset:= trunc(power(2,offset.value));
  mseq   := nil;
  Setlength(mseq, mlength);

  DoMseq;
  //make the display the square root of the n of pixels
  xysize := trunc(sqrt(npixels));
  //if npixels is not square rootable then make the display larger
  if sqr(xysize) <> npixels then inc(xysize);
  wid := xysize;
  hei := xysize;

  mseqimg.width := 4*wid;
  mseqimg.height := 4*hei;
  patno := 0;

  mseqbm  := TBitmap.Create;
  mseqbm.width := mseqimg.width;
  mseqbm.height := mseqimg.width;
  mseqbm.PixelFormat := pf8bit;
  mseqimg.picture.assign(mseqbm);
  mseqbm.width := wid;
  mseqbm.height := hei;

  p := mseqbm.ScanLine[0];
  for i := 0 to 255 do
  begin
    mseqbm.canvas.pixels[0,0]:= RGB(i,i,i);
    grayvals[i]:= p[0];
  end;
  white:= grayvals[0];
  black:= grayvals[255];
end;

{---------------------------------------------------------------------------}
function TMSeqForm.Color2Grey(col : TColor) : smallint;
begin
  Color2Grey := round(255-sqrt(-ln(GetRValue(col)/255)*2)*64);
end;

{---------------------------------------------------------------------------}
function TMSeqForm.Grey2Color (gval : smallint) : TColor;
var gr,gg,gb,g : smallint;
begin
  g := 255-gval;
  gr:= g;
  gg:= g-127;
  gb:= g-255;

  Grey2Color:= RGB(round(255*exp(-sqr(gr/64)/2)),  {Color}
                    round(255*exp(-sqr(gg/64)/2)),
                    round(255*exp(-sqr(gb/64)/2)));
end;

{---------------------------------------------------------------------------}
procedure TMSeqForm.ShowMseq(index, ir : integer);
var  j,b,x,y : integer;
     p : PByteArray;
begin
  for y:= 0 to hei-1 do
  begin
    p:= mseqbm.scanline[y];
    for x:= 0 to wid-1 do
    begin
      j:= y*wid+x;
      b:= mseq[(j*moffset+index) mod mlength];
      if ir = 1 then b:= -b;
      if b = 1 then p[x]:= white else p[x]:= black;
    end;
  end;
  stretchblt(mseqimg.canvas.handle, 0, 0, mseqimg.width, mseqimg.height,
             mseqbm.canvas.handle, 0, 0, wid,hei,SRCCOPY);
  mseqimg.refresh;
end;

{---------------------------------------------------------------------------}
procedure TMSeqForm.ComputeStimuli(SurfFile : TSurfFileInfo; var Stimulus : TStimulus);
const FIRSTPOSITIONPROBE = 1;{this is for our setup only--refers to the first probe
                              that we used for position information}
var s,c,p,pr,begintime,y,tm,wavetime,pt : integer;
    f1,f2,f3,f4 : double;
begin
  with SurfFile do
  begin
    f1 := ProbeArray[FIRSTPOSITIONPROBE].pts_per_chan;
    f2 := ProbeArray[FIRSTPOSITIONPROBE].skippts;
    f3 := ProbeArray[FIRSTPOSITIONPROBE].sampfreqperchan;
    f4 := f1 * f2 / f3 * 10000;
    wavetime := round( f4 );

    Stimulus.timediv := f3 / (f2*10000);
    SetLength(Stimulus.time,round((SurfEventArray[NEvents-1].time_stamp+wavetime)*Stimulus.timediv)+1);
    for s := 0 to Length(Stimulus.time)-1 do
    begin
      Stimulus.time[s].posx := NOSTIMULUS;
      Stimulus.time[s].posy := NOSTIMULUS;
      Stimulus.time[s].contrast := NOSTIMULUS;
      Stimulus.time[s].sfreq := NOSTIMULUS;
      Stimulus.time[s].len := NOSTIMULUS;
      Stimulus.time[s].wid := NOSTIMULUS;
    end;

    For p := 1 to 6 do {number of position records}
    begin
      pr := FIRSTPOSITIONPROBE + p-1; //cr probe
      For c := 0 to ProbeArray[pr].NumCr-1 do
      begin
        begintime := ProbeArray[pr].cr[c].time_stamp;
        For pt := 0 to ProbeArray[pr].pts_per_chan-1 do
        begin
          tm := round(begintime*Stimulus.timediv + pt);
          y := ProbeArray[pr].cr[c].waveform[pt]-2047;
          if tm > Length(Stimulus.time)-1 then tm := Length(Stimulus.time)-1;
          case ProbeArray[pr].chanlist[0] of
              26{xpos}: Stimulus.Time[tm].posx     := y;
              27{ypos}: Stimulus.Time[tm].posy     := y;
              28{con} : Stimulus.Time[tm].contrast := y;
              29{sf}  : Stimulus.Time[tm].sfreq    := y;
              30{len} : Stimulus.Time[tm].len      := y;
              31{wid} : Stimulus.Time[tm].wid      := y;
          end;//case
        end;//pt loop
      end;//c loop
    end;//p loop
  end;//with surffile
end;//ComputeStimuli

{---------------------------------------------------------------------------}
(*const TIMESLICES = 32;//each slice is 1/75th sec, so 75=1 sec, and 35 about 500ms
var
  c,np,e,pr,nsp,ncp,OrigHeight,OrigWidth,tm : integer;
  m,w,msb,lsb : WORD;
  i,j,x,y,t,index,maxhist,minhist,g,b,modval,nresp : longint;
  col : TColor;
  onresp,offresp : boolean;
  hist : array of array of array of longint;
  ms3d : array of array of array of ShortInt;
  //histindex : array of TPoint;
  //rffield : array of array of longint;
  cenx,ceny,ran,hi : double;
  r,npix,radius,ir,inv,histrange : longint;
  s : string;
  p : pByteArray;
  blen,bwid,con,ori,ms : integer;
  maxh,minh : array of integer;
  range : integer;
  rfbm : TBitmap;
  Stimulus : TStimulus;

Procedure DisplayRecov;
var x,y,t,xoff,yoff : integer;
    p : PByteArray;
begin
    For t := 0 to TIMESLICES-1 do
    begin
      range := maxh[t]-minh[t];
      For y := 0 to hei-1 do
      begin
        p := rfbm.scanline[y];
        For x := 0 to wid-1 do
        begin
          g := round((hist[x,hei-y-1,t]-minh[t])/range*255);
          col := Grey2Color (g);
          p[x*3]   := GetBValue(col);
          p[x*3+1] := GetGValue(col);
          p[x*3+2] := GetRValue(col);
        end;
      end;
      xoff := (t mod 8)*68;
      yoff := (t div 8)*68;
      MSeqForm.Canvas.StretchDraw(rect(xoff+210,yoff+110,xoff+64+210,yoff+64+110),rfbm);
      //RecovAll.Canvas.StretchDraw(rect(xoff,yoff,xoff+64,yoff+64),rfbm);
    end;
    //recovall.refresh;
end;

begin
  MSeqForm.BringToFront;
  StatusBar.SimpleText := 'Filename : '+ SurfFile.Filename;

  GenerateMSeq;

  rfbm  := TBitmap.Create;
  rfbm.width := wid;
  rfbm.height := hei;
  rfbm.PixelFormat := pf24Bit;

  //build a stimulus record--what the stimulus was doing at every timestamp
  ComputeStimuli(SurfFile,Stimulus);

  SetLength(hist,wid,hei,TIMESLICES);
  SetLength(ms3d,wid,hei,TIMESLICES);
  SetLength(maxh,TIMESLICES);
  SetLength(minh,TIMESLICES);

  For x := 0 to wid-1 do
    For y := 0 to hei-1 do
      For t := 0 to TIMESLICES-1 do
      begin
        hist[x,y,t] := 0; //this will contain the actual receptive fields at different time slices
        ms3d[x,y,t] := 0; //this will contain the ongoing msequence for forward correlations
      end;
  //showmessage('here6');
  For t := 0 to TIMESLICES-1 do
  begin
    maxh[t] := 1;
    minh[t] := 0;
  end;
  //showmessage('here2');

  mseqval.caption := inttostr(0);
  digval.caption := inttostr(0);
  nspikes.caption := inttostr(0);
  ndig.caption := inttostr(0);

  OrigWidth := MSeqForm.ClientWidth;
  OrigHeight := MSeqForm.ClientHeight;

  //showmessage('here3');

  //tic.open;
  HaltRead := FALSE;
  With SurfFile do
  begin
    // Now read the data using the event array
    Guage.MinValue := 0;
    Guage.MaxValue := NEvents-1;
    for e := 0 to NEvents-1 do
    begin
      tm := round(SurfFile.SurfEventArray[e].Time_Stamp * Stimulus.Timediv);
      If tm > Length(Stimulus.Time)-1
        then tm := Length(Stimulus.Time)-1;
      pr := SurfEventArray[e].probe;
      i := SurfEventArray[e].Index;
      case SurfEventArray[e].EventType of
        SURF_PT_REC_UFFTYPE {'N'}: //handle spikes and continuous records
          case SurfEventArray[e].subtype of
            SPIKETYPE  {'S'}:
              begin //spike record found
                time.caption := inttostr(ProbeArray[pr].spike[i].time_stamp);
                //prb[p].spike[i].cluster
                nspikes.caption := inttostr(i+1);
                c := ProbeArray[pr].spike[i].cluster;

                //Stimulus.Time[tm]
                //if con > 0 then inv := 0 else inv := -1;
                //if DisplayMSeq.Checked then ShowMseq(m,inv);
                For t := 0 to TIMESLICES-1 do
                begin
                  ms := (m-t+TIMESLICES) mod TIMESLICES;
                  For x := 0 to wid-1 do
                    For y := 0 to hei-1 do
                    begin
                      hist[x,y,t] := hist[x,y,t] + ms3d[x,y,ms];
                      if maxh[t] < hist[x,y,t] then maxh[t] := hist[x,y,t];
                      if minh[t] > hist[x,y,t] then minh[t] := hist[x,y,t];
                    end;
                end;
                //if TicSound.Checked then tic.play;
                //if DisplayMSeq.Checked then
                DisplayRecov;
              end;
          end;
        SURF_SV_REC_UFFTYPE {'V'}: //handle single values (including digital signals)
          case SurfEventArray[e].subtype of
            SURF_DIGITAL {'D'}:
              begin
                //time.caption := inttostr(sval[i].time_stamp);
                w := SValArray[i].sval;
                //digval.caption := inttostr(w);
                msb := w and $00FF; {get the last byte of this word}
                lsb := w shr 8;      {get the first byte of this word}
                m := msb*256+lsb;
                mseqval.caption := inttostr(m);
                ndig.caption := inttostr(i+1);
                UpdateStimulus(Stimulus.Time[tm],SurfEventArray[e].Time_Stamp,x,y,blen,bwid,con,ori);
                //StatusBar.Simpletext := inttostr(tm)+','+inttostr(Event[e].Time_Stamp)+inttostr(Stimulus.Time[tm].Contrast);
                if con < 0 then inv := 1 else inv := -1;
                if DisplayMSeq.Checked then ShowMseq(m,inv);

                for y := 0 to hei-1 do
                  For x := 0 to wid-1 do
                  begin
                    j := y*wid+x;
                    b := mseq[(j*moffset+m) mod mlength];
                    if con < 0 then b := -b;
                    ms3d[x,y,m mod TIMESLICES] := b;
                  end;

                //ori.caption := inttostr((msb and $01) shl 8 + lsb); //get the last bit of the msb
                //phase.caption := inttostr(msb shr 1);//get the first 7 bits of the msb
              end;
          end;
        SURF_MSG_REC_UFFTYPE {'M'}://handle surf messages
          begin
            time.caption := inttostr(SurfMsgArray[i].time_stamp);
            StatusBar.SimpleText := SurfMsgArray[i].Msg;
          end;
      end {case};
      Guage.Progress := e;
      Application.ProcessMessages;
      if HaltRead then break;
      While pause.checked do
      begin
        Application.ProcessMessages;
        if HaltRead then break;
      end;
    end{event loop};
  end;
  //tic.close;

  MSeqForm.ClientWidth := OrigWidth;
  MSeqForm.ClientHeight := OrigHeight;
  Guage.Progress := 0;

  rfbm.Free;
end;
*)
(*
{---------------------------------------------------------------------------}
Procedure TMSeqForm.Analyze(FileName : String);
const TIMESLICES = 32;//each slice is 1/75th sec, so 75=1 sec, and 35 about 500ms
var
  ReadSurf : TSurfFile;
  c,np,e,pr,nsp,ncp,OrigHeight,OrigWidth,tm : integer;
  m,w,msb,lsb : WORD;
  i,j,x,y,t,index,maxhist,minhist,g,b,modval,nresp : longint;
  col : TColor;
  onresp,offresp : boolean;
  hist : array of array of array of longint;
  ms3d : array of array of array of ShortInt;
  //histindex : array of TPoint;
  //rffield : array of array of longint;
  cenx,ceny,ran,hi : double;
  r,npix,radius,ir,inv,histrange : longint;
  s : string;
  p : pByteArray;
  blen,bwid,con,ori,ms : integer;
  maxh,minh : array of integer;
  range : integer;
  rfbm : TBitmap;

Procedure DisplayRecov;
var x,y,t,xoff,yoff : integer;
    p : PByteArray;
begin
    For t := 0 to TIMESLICES-1 do
    begin
      range := maxh[t]-minh[t];
      For y := 0 to hei-1 do
      begin
        p := rfbm.scanline[y];
        For x := 0 to wid-1 do
        begin
          g := round((hist[x,hei-y-1,t]-minh[t])/range*255);
          col := Grey2Color (g);
          p[x*3]   := GetBValue(col);
          p[x*3+1] := GetGValue(col);
          p[x*3+2] := GetRValue(col);
        end;
      end;
      xoff := (t mod 8)*68;
      yoff := (t div 8)*68;
      RecovAll.Canvas.StretchDraw(rect(xoff,yoff,xoff+64,yoff+64),rfbm);
    end;
    recovall.refresh;
end;

begin
  ReadSurf := TSurfFile.Create;
  if not ReadSurf.ReadEntireSurfFile(FileName,FALSE{do not read the spike waveforms},FALSE{don't average the waveforms}) then //this reads everything
  begin
    ReadSurf.Free;
    ShowMessage('Error Reading '+ FileName);
    Exit;
  end;

  Show;

  MSeqForm.BringToFront;
  StatusBar.SimpleText := 'Filename : '+ Filename;

  GenerateMSeq;

  rfbm  := TBitmap.Create;
  rfbm.width := wid;
  rfbm.height := hei;
  rfbm.PixelFormat := pf24Bit;

  SetLength(hist,wid,hei,TIMESLICES);
  SetLength(ms3d,wid,hei,TIMESLICES);
  SetLength(maxh,TIMESLICES);
  SetLength(minh,TIMESLICES);

  For x := 0 to wid-1 do
    For y := 0 to hei-1 do
      For t := 0 to TIMESLICES-1 do
      begin
        hist[x,y,t] := 0; //this will contain the actual receptive fields at different time slices
        ms3d[x,y,t] := 0; //this will contain the ongoing msequence for forward correlations
      end;
  //showmessage('here6');
  For t := 0 to TIMESLICES-1 do
  begin
    maxh[t] := 1;
    minh[t] := 0;
  end;
  //showmessage('here2');

  mseqval.caption := inttostr(0);
  digval.caption := inttostr(0);
  nspikes.caption := inttostr(0);
  ndig.caption := inttostr(0);

  OrigWidth := MSeqForm.ClientWidth;
  OrigHeight := MSeqForm.ClientHeight;

  //showmessage('here3');

  //tic.open;
  HaltRead := FALSE;
  With ReadSurf do
  begin
    // Now read the data using the event array
    Guage.MinValue := 0;
    Guage.MaxValue := NEvents-1;
    for e := 0 to NEvents-1 do
    begin
      tm := round(SurfFile.Event[e].Time_Stamp * Stimulus.Timediv);
      If tm > Length(Stimulus.Time)-1
        then tm := Length(Stimulus.Time)-1;
      pr := Event[e].probe;
      i := Event[e].Index;
      case Event[e].EventType of
        SURF_PT_REC_UFFTYPE {'N'}: //handle spikes and continuous records
          case Event[e].subtype of
            SPIKETYPE  {'S'}:
              begin //spike record found
                time.caption := inttostr(prb[pr].spike[i].time_stamp);
                //prb[p].spike[i].cluster
                nspikes.caption := inttostr(i+1);
                c := prb[pr].spike[i].cluster;

                //Stimulus.Time[tm]
                //if con > 0 then inv := 0 else inv := -1;
                //if DisplayMSeq.Checked then ShowMseq(m,inv);
                For t := 0 to TIMESLICES-1 do
                begin
                  ms := (m-t+TIMESLICES) mod TIMESLICES;
                  For x := 0 to wid-1 do
                    For y := 0 to hei-1 do
                    begin
                      hist[x,y,t] := hist[x,y,t] + ms3d[x,y,ms];
                      if maxh[t] < hist[x,y,t] then maxh[t] := hist[x,y,t];
                      if minh[t] > hist[x,y,t] then minh[t] := hist[x,y,t];
                    end;
                end;
                //if TicSound.Checked then tic.play;
                //if DisplayMSeq.Checked then
                DisplayRecov;
              end;
          end;
        SURF_SV_REC_UFFTYPE {'V'}: //handle single values (including digital signals)
          case Event[e].subtype of
            SURF_DIGITAL {'D'}:
              begin
                //time.caption := inttostr(sval[i].time_stamp);
                w := sval[i].sval;
                //digval.caption := inttostr(w);
                msb := w and $00FF; {get the last byte of this word}
                lsb := w shr 8;      {get the first byte of this word}
                m := msb*256+lsb;
                mseqval.caption := inttostr(m);
                ndig.caption := inttostr(i+1);
                UpdateStimulus(Stimulus.Time[tm],Event[e].Time_Stamp,x,y,blen,bwid,con,ori);
                //StatusBar.Simpletext := inttostr(tm)+','+inttostr(Event[e].Time_Stamp)+inttostr(Stimulus.Time[tm].Contrast);
                if con < 0 then inv := 1 else inv := -1;
                if DisplayMSeq.Checked then ShowMseq(m,inv);

                for y := 0 to hei-1 do
                  For x := 0 to wid-1 do
                  begin
                    j := y*wid+x;
                    b := mseq[(j*moffset+m) mod mlength];
                    if con < 0 then b := -b;
                    ms3d[x,y,m mod TIMESLICES] := b;
                  end;

                //ori.caption := inttostr((msb and $01) shl 8 + lsb); //get the last bit of the msb
                //phase.caption := inttostr(msb shr 1);//get the first 7 bits of the msb
              end;
          end;
        SURF_MSG_REC_UFFTYPE {'M'}://handle surf messages
          begin
            time.caption := inttostr(msg[i].time_stamp);
            StatusBar.SimpleText := Msg[i].Msg;
          end;
      end {case};
      Guage.Progress := e;
      Application.ProcessMessages;
      if HaltRead then break;
      While pause.checked do
      begin
        Application.ProcessMessages;
        if HaltRead then break;
      end;
    end{event loop};
  end;
  //tic.close;

  MSeqForm.ClientWidth := OrigWidth;
  MSeqForm.ClientHeight := OrigHeight;
  Guage.Progress := 0;

  rfbm.Free;
  ReadSurf.CleanUp;
  ReadSurf.Free;
end;
*)

procedure TMSeqForm.StopButtonClick(Sender: TObject);
begin
  HaltRead := TRUE;
end;

procedure TMSeqForm.FormShow(Sender: TObject);
begin
  mseqimg.canvas.Brush.Color := clLtGray;
  mseqimg.canvas.FillRect(mseqimg.canvas.ClipRect);
  MSeqForm.BringToFront;
end;

procedure TMSeqForm.TimeSliceSpinChange(Sender: TObject);
begin
  //DisplayRecov;
end;

(*procedure TMSeqForm.SpinEdit1Change(Sender: TObject);
begin
  ShowMseq(SpinEdit1.Value, 0);
end;
*)

procedure TMSeqForm.GetStimuliRecords(FileName : string);
const BYTESPERSTIMREC = 10;
var fs : TFileStream;
  i, x, y, j, b : integer;
begin
  try
    fs:= TFileStream.Create(Filename, fmOpenRead);
  except
    MessageDlg('Cannot open stimulus file.', mtError, [mbOK], 0);
    Exit;
  end;
  fs.Seek{64}(3048, soFromBeginning); //ignore DS header
  i:= 0;
  nStimFrames:= (fs.Size - 3048) div 10;
  Setlength(Stimulus, nStimFrames);
  gauge.MinValue:= 0;
  gauge.MaxValue:= nStimFrames;
  StatusBar.SimpleText:= 'Reading stimulus information...';
  while (fs.Read(Stimulus[i].time_stamp, 8) + fs.Read(Stimulus[i].sval, 2) = BYTESPERSTIMREC) do
  begin
    inc(i);
    gauge.Progress:= i;
  end;
end;

{-----------------------------------------------------------------------------------}
procedure TMSeqForm.SurfFileAccessNewFile(acFileName: WideString);
const TIMESLICES = 16;//slice duration = frame rate * num frames per mseq
                      //so, for a 25Hz m-seq, TIMESLICES = 16 * 40 = 640ms revcor
var stimfilename : string;
  e, m : integer;
  i,j,x,y,t,index,maxhist,minhist,g,b,modval,nresp : longint;
  col : TColor;
  hist : array of array of array of longint;
  //histindex : array of TPoint;
  //rffield : array of array of longint;
  cenx,ceny,ran,hi : double;
  r,npix,radius,ir,inv,histrange : longint;
  s : string;
  p : pByteArray;
  blen,bwid,con,ori,ms : integer;
  maxh,minh : array of integer;
  range : integer;
  rfbm : TBitmap;
  spikestream : TFileStream;
//  spiketime : int64;
  n : integer;

procedure DisplayRecov;
var x,y,t,xoff,yoff : integer;
    p : PByteArray;
begin
    for t := 0 to TIMESLICES-1 do
    begin
      range := maxh[t]-minh[t];
      for y := 0 to hei-1 do
      begin
        p := rfbm.scanline[y];
        for x := 0 to wid-1 do
        begin
          g := round((hist[x,hei-y-1,t]-minh[t])/range*255);
          col := Grey2Color (g);
          p[x*3]   := GetBValue(col);
          p[x*3+1] := GetGValue(col);
          p[x*3+2] := GetRValue(col);
        end;
      end;
      xoff := (t mod 8)*68;
      yoff := (t div 8)*68;
      MSeqForm.Canvas.StretchDraw(rect(xoff+50,yoff+140,xoff+64+50,yoff+64+140),rfbm);
    end;
end;

begin
  if ExtractFileExt(acFileName) <> '.spk' then
  begin
    MessageDlg('Not a valid spiketime or stimulus file', mtError, [mbOK], 0);
    Exit;
  end;
  try
    spikestream:= TFileStream.Create(acFileName, fmOpenRead);
    spikestream.Seek{64}(0, soFromBeginning); //start of file
  except
    MessageDlg('Cannot open file.', mtError, [mbOK], 0);
    Exit;
  end;
  n:= spikestream.Size div 8;
  Setlength(SpikeTimes, n);
  for i:= 0 to n - 1 do //get all the spikes...
    spikestream.ReadBuffer(SpikeTimes[i], 8);
  { now look for corresponding stimulus file in same directory}
  stimfilename:= ExtractFileName(acFileName);
  Delete(stimfilename, Pos('_', stimfilename), length(stimfilename));
  stimfilename:= stimfilename + '_digital.bin';
  if not FileExists(ExtractFilePath(acFileName) + stimfilename) then
  begin
    MessageDlg('Associated stimulus file ''' + stimfilename + ''' not found', mtError, [mbOK], 0);
    Exit;
  end;
  GetStimuliRecords(ExtractFilePath(acFileName) + stimfilename);
  { update form with this neuron's stats }
  Caption:= Caption+ ': ' + ExtractFileName(acFileName);
  mseqval.caption := inttostr(0);
  nspikes.caption := inttostr(0);
  ndig.caption := inttostr(0);
  { calculate mseq bitmaps per user (spinedit) settings at time of drag'n'drop }
  GenerateMSeq; //ie. generates a 1D m-length array or binary m-seq numbers

  rfbm:= TBitmap.Create;
  rfbm.width := wid;
  rfbm.height := hei;
  rfbm.PixelFormat := pf24Bit;

  { allocate arrays and zero initialize them }
  SetLength(hist, wid, hei, TIMESLICES);
  SetLength(ms3d, wid, hei, TIMESLICES);
  SetLength(maxh, TIMESLICES);
  SetLength(minh, TIMESLICES);
  for x:= 0 to wid - 1 do
    for y:= 0 to hei - 1 do
      for t:= 0 to TIMESLICES - 1 do
      begin
        hist[x,y,t]:= 0; //this will contain the actual receptive fields at different time slices
        ms3d[x,y,t]:= 0; //this will contain the ongoing msequence for forward correlations
      end;
  for t:= 0 to TIMESLICES-1 do
  begin
    maxh[t]:= 1;
    minh[t]:= 0;
  end;

  { main loop for computing rf's at each timeslice }
  HaltRead:= False;
  Gauge.Progress:= 0;
  Gauge.MaxValue:= Length(Stimulus);
  StatusBar.SimpleText:= 'Generating receptive fields...';
  e:= 0;
  i:= 0;
  while SpikeTimes[i] < Stimulus[0].time_stamp do inc(i); //skip over spikes that fire before stimulus onset
  while e < Length(Stimulus) do
  begin
    m:= Stimulus[e].SVal;
    mseqval.caption := inttostr(m);
    ndig.caption:= inttostr(e + 1);
    time.caption:= inttostr(Stimulus[e].time_stamp);
    if DisplayMSeq.Checked then ShowMseq(m, 1); //or zero if inverted!
    { update ms3d array for current 'm' at t0 }
    for y:= 0 to hei - 1 do
      for x:= 0 to wid - 1 do
      begin
        j:= y*wid+x;
        b:= mseq[(j * moffset + m) mod mlength];
        ms3d[x, y, m mod TIMESLICES]:= b; //-b for inv, what was default?
      end;
    { skip over duplicate frames (for multi-frame m-sequences) }
    while Stimulus[e].sval = m do inc(e); //what about EOF?
    { read spikes relevant to current ms3d array }
    while SpikeTimes[i] < Stimulus[e].time_stamp{next m-seq frame} do //will miss last few spikes byond last frame
    begin
      { update rf's for each timeslice }
      for t:= 0 to TIMESLICES-1 do
      begin
        ms:= (m-t+TIMESLICES) mod TIMESLICES;
        for x:= 0 to wid-1 do
          for y:= 0 to hei-1 do
          begin
            hist[x,y,t]:= hist[x,y,t] + ms3d[x,y,ms];
            if maxh[t] < hist[x,y,t] then maxh[t]:= hist[x,y,t];
            if minh[t] > hist[x,y,t] then minh[t]:= hist[x,y,t];
          end;
      end;
      DisplayRecov;
      inc(i);
      nspikes.caption:= inttostr(i);
    end{while};
    Gauge.Progress:= e;
    Application.ProcessMessages;
    if HaltRead then break;
    while pause.checked do
    begin
      Application.ProcessMessages;
      if HaltRead then break;
    end;
  end{event loop};
  StatusBar.SimpleText:= 'Finished!';
  rfbm.Free;
end;

procedure TMSeqForm.Button1Click(Sender: TObject);
begin
  GenerateMSeq; //ie. generates a 1D m-length array or binary m-seq numbers
  if DisplayMSeq.Checked then ShowMseq(16381, 1); //or zero if inverted!
end;

end.
