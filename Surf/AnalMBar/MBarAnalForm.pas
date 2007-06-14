unit MBarAnalForm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Gauges, ComCtrls, StdCtrls, SurfPublicTypes, Spin, Math, ExtCtrls,
  SurfAnal;

const AD2DEG = 81.92;
      DEGPERSCREEN = 20 {+/- 20};
      NOSTIMULUS = -999;
type
  TMBarForm = class(TForm)
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Screen: TPanel;
    Guage: TGauge;
    StatusBar: TStatusBar;
    StopButton: TButton;
    Pause: TCheckBox;
    Delayed: TCheckBox;
    PlotPositions: TCheckBox;
    Display: TImage;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    lxpos: TLabel;
    lypos: TLabel;
    llen: TLabel;
    lwid: TLabel;
    lcon: TLabel;
    lori: TLabel;
    Label10: TLabel;
    ltime: TLabel;
    SurfAnal1: TSurfAnal;
    CDumpText: TCheckBox;
    procedure StopButtonClick(Sender: TObject);
    procedure SurfAnal1SurfFile(SurfFile: TSurfFileInfo);
  private
    { Private declarations }
    DisplayScale : single;
    lastx,lasty,lastlen,lastwid,lastori,lastcon,HalfSize : integer;
    HaltRead : boolean;
    Procedure ComputeStimuli(SurfFile : TSurfFileInfo; var Stimulus : TStimulus);
    Procedure UpdateStimulus(var stim : TStim; timestamp : LNG; var x,y,blen,bwid,con,ori : integer);
    Procedure PlotBar(x,y,len,wid{all in pixels},ori {deg},con{?} : integer);
    Procedure PlotPixel(x,y,con : integer);
    Procedure Rotate(x,y,ori : integer; var pt : TPoint);
  public
    { Public declarations }
  end;

var
  MBarForm: TMBarForm;

implementation

{$R *.DFM}

{---------------------------------------------------------------------------}
Procedure TMBarForm.Rotate(x,y,ori : integer; var pt : TPoint);
var theta,costheta,sintheta : single;
begin
  theta := ori * PI/180;
  costheta := cos(theta);
  sintheta := sin(theta);
  pt.x := round(x*costheta - y*sintheta);
  pt.y := round(x*sintheta + y*costheta);
end;

{---------------------------------------------------------------------------}
Procedure TMBarForm.PlotBar(x,y,len,wid{all in pixels},ori {deg},con{?} : integer);
var pt : array{[0..4]} of TPoint;
    i : integer;
begin //plot the bar
  SetLength(pt,5);
  Rotate(-len div 2,-wid div 2,ori,pt[0]);
  Rotate(-len div 2,+wid div 2,ori,pt[1]);
  Rotate(+len div 2,+wid div 2,ori,pt[2]);
  Rotate(+len div 2,-wid div 2,ori,pt[3]);
  pt[4].x := pt[0].x;
  pt[4].y := pt[0].y;
  For i := 0 to 4 do
  begin
    pt[i].x := pt[i].x + x;
    pt[i].y := pt[i].y + y;
  end;

  Display.Canvas.Pen.Mode := pmXOR;
  Display.Canvas.Pen.Width := 1;
  if con > 0 then Display.Canvas.Pen.Color := clLIME
             else Display.Canvas.Pen.Color := clFUCHSIA;
  Display.Canvas.Brush.Color :=  Display.Canvas.Pen.Color;

  Display.Canvas.PolyGon([Point(pt[0].x, pt[0].y),
                          Point(pt[1].x, pt[1].y),
                          Point(pt[2].x, pt[2].y),
                          Point(pt[3].x, pt[3].y),
                          Point(pt[4].x, pt[4].y)]);
  lastx := x;
  lasty := y;
  lastlen := len;
  lastwid := wid;
  lastori := ori;
  lastcon := con;
end;

{---------------------------------------------------------------------------}
Procedure TMBarForm.PlotPixel(x,y,con : integer);
begin  //plot the point
  Display.Canvas.Pen.Mode := pmCopy;
  Display.Canvas.Pen.Width := 1;
  if plotpositions.Checked then
    if {(con > 0) and} (Display.Canvas.Pixels[x,y] = clBLACK)
      then Display.Canvas.Pixels[x,y] := clDkGray;//clLime
      //else Display.Canvas.Pixels[x,y] := clFuchsia;
end;

{---------------------------------------------------------------------------}
Procedure TMBarForm.ComputeStimuli(SurfFile : TSurfFileInfo; var Stimulus : TStimulus);
const FIRSTPOSITIONPROBE = 1;{this is for our setup only--refers to the first probe
                              that we used for position information}
var s,c,p,pr,begintime,y,tm,wavetime,pt : integer;
    f1,f2,f3,f4 : double;
begin
  With SurfFile do
  begin
    f1 := ProbeArray[FIRSTPOSITIONPROBE].pts_per_chan;
    f2 := ProbeArray[FIRSTPOSITIONPROBE].skippts;
    f3 := ProbeArray[FIRSTPOSITIONPROBE].sampfreqperchan;
    f4 := f1 * f2 / f3 * 10000;
    wavetime := round( f4 );

    Stimulus.timediv := f3 / (f2*10000);
    SetLength(Stimulus.time,round((SurfEventArray[NEvents-1].time_stamp+wavetime)*Stimulus.timediv)+1);
    For s := 0 to Length(Stimulus.time)-1 do
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
Procedure TMBarForm.UpdateStimulus(var stim : TStim; timestamp : LNG; var x,y,blen,bwid,con,ori : integer);
begin
  x := round(HalfSize + Stim.Posx * DisplayScale);
  y := round(HalfSize - Stim.Posy * DisplayScale);
  blen := round((Stim.Len+2047) * DisplayScale);//length of bar in pixels
  bwid := round((Stim.Wid+2047) * DisplayScale);//width of bar in pixels
  con := Stim.Contrast;

  if Delayed.Checked and (lastx <> NOSTIMULUS) then PlotBar(lastx,lasty,lastlen,lastwid,lastori,lastcon);
  if plotpositions.checked then PlotPixel(x,y,con);
  if not Delayed.Checked then exit;
  PlotBar(x,y,blen,bwid,ori,con);

  lxpos.caption := FloatToStrF(Stim.Posx/AD2DEG,fffixed,4,2);
  lypos.caption := FloatToStrF(Stim.Posy/AD2DEG,fffixed,4,2);
  llen.caption := FloatToStrF((Stim.Len+2047)/AD2DEG,fffixed,4,2);
  lwid.caption := FloatToStrF((Stim.Wid+2047)/AD2DEG,fffixed,4,2);
  lcon.caption := inttostr(con);
  lori.caption := inttostr(ori);
  ltime.caption := inttostr(timestamp);
  ShowMessage(inttostr(timestamp));

end;

procedure TMBarForm.StopButtonClick(Sender: TObject);
begin
  HaltRead := TRUE;
end;

procedure TMBarForm.SurfAnal1SurfFile(SurfFile: TSurfFileInfo);
var
  e,pr,cl,i,x,y,tm,t,con,ori,len,wid,lasttm,maxtm : integer;
  w,lsb,msb : WORD;
  Stimulus : TStimulus;

  Output : TextFile;
  OutFileName : string;

begin
  MBarForm.BringToFront;
  StatusBar.SimpleText := 'Filename : '+ SurfFile.Filename;

  if CDumpText.Checked then
  begin
    OutFileName := SurfFile.FileName;
    SetLength(OutFileName,Length(OutFileName)-3);
    OutFileName := OutFileName + 'stm';
    AssignFile(Output, OutFileName);
    if FileExists(OutFileName)
      then Append(Output)
      else Rewrite(Output);
  end;

  HalfSize := Display.Width div 2;
  DisplayScale := HalfSize/(DEGPERSCREEN*AD2DEG);

  Display.Canvas.Brush.Color := clBLACK;
  Display.Canvas.FillRect(Display.ClientRect);
  Display.Canvas.Pen.Style := psDot;
  Display.Canvas.Pen.Color := clDkGray;
  Display.Canvas.MoveTo(0,HalfSize);
  Display.Canvas.LineTo(Display.Width,HalfSize);
  Display.Canvas.MoveTo(HalfSize,0);
  Display.Canvas.LineTo(HalfSize,Display.Height);
  Display.Canvas.Pen.Style := psSolid;

  //build a stimulus record--what the stimulus was doing at every timestamp
  ComputeStimuli(SurfFile,Stimulus);

  x := NOSTIMULUS;
  y := NOSTIMULUS;
  lastx := NOSTIMULUS;
  lasttm := -1;
  HaltRead := FALSE;
  With SurfFile do
  begin
    // Now read the data using the event array
    Guage.MinValue := 0;
    Guage.MaxValue := Length(Stimulus.Time)-1;

    ori := 0;
    maxtm := Length(Stimulus.Time)-1;
    For e := 0 to NEvents-1 do
    begin
      //Figure out what the stimulus was doing
      tm := round(SurfEventArray[e].Time_Stamp * Stimulus.TimeDiv);
      if tm > maxtm then tm := maxtm;
      //if there were any stimuli before this event, update the stimulus window and values
      if tm > lasttm  then
        for t := lasttm+1 to tm do
          if Stimulus.Time[t].Posx <> NOSTIMULUS then
          begin
            UpdateStimulus(Stimulus.Time[t],round(t/Stimulus.TimeDiv),x,y,len,wid,con,ori);
//**************** TEXT DUMPING OF BAR INFO ************
            if CDumpText.Checked then
            begin
              Write(Output, 'X '+lxpos.caption+' Y '+lypos.caption,' ');//this is an x,y position record
              Write(Output, 'L '+llen.caption+ ' W '+lwid.caption,' ');//this is the len and wid of the bar
              Write(Output, 'C '+lcon.caption+ ' ');//this is the contrast
              Write(Output, 'O '+lori.caption+ ' ');//this is the orientation
              Writeln(Output);//end of line
            end;
//**************** END TEXT DUMPING ************
          end;
      lasttm := tm;
      //get fetch the event
      i := SurfEventArray[e].Index;
      pr := SurfEventArray[e].Probe;
      case SurfEventArray[e].EventType of
        SURF_PT_REC_UFFTYPE {'N'}: //handle spikes and continuous records
          case SurfEventArray[e].subtype of
            SPIKETYPE  {'S'}:
              begin //spike record found
                cl := ProbeArray[pr].spike[i].cluster;
                if (x<>NOSTIMULUS) and (y<>NOSTIMULUS) then
                begin
                   Display.Canvas.Pen.Mode := pmCopy;
                   Display.Canvas.Pen.Color := clRed;//COLORTABLE[cl];
                   Display.Canvas.Rectangle(x-1,y-1,x+1,y+1);
                end;
              end;
          end;
        SURF_SV_REC_UFFTYPE {'V'}: //handle single values (including digital signals)
          case SurfEventArray[e].subtype of
            SURF_DIGITAL {'D'}:
              begin
                w := SValArray[i].sval;
                msb := w and $00FF; //get the last byte of this word
                lsb := w shr 8;      //get the first byte of this word
                ori := (msb and $01) shl 8 + lsb; {get the last bit of the msb}
              end;
          end;
        SURF_MSG_REC_UFFTYPE {'M'}://handle surf messages
          begin
            ShowMessage(SurfMsgArray[i].Msg);
            StatusBar.SimpleText := SurfMsgArray[i].Msg;
          end;
      end {case};

      If Delayed.Checked then
      begin
        Application.ProcessMessages;
        Guage.Progress := tm;
      end;

      While pause.checked do
      begin
        Application.ProcessMessages;
        if HaltRead then break;
      end;
      if HaltRead then break;
    end;

    if CDumpText.Checked then
    begin
      CloseFile(Output);
    end;
  end;
  Stimulus.Time := nil;
  Guage.Progress := 0;
end;


end.
