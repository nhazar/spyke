{ (c) 2003 Tim Blanche, University of British Columbia }
unit ChartFormUnit;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ExtCtrls, DTxPascal, SurfPublicTypes, StdCtrls, ToolWin, ComCtrls, ImgList,
  Menus;

const LEFTMARGIN = 25;
      //RIGHTMARGIN = 5;
      TOPMARGIN = 25;
      STATUSMARGIN = 10;

      COLOR_LUT_BITS = 8;
      LUT_ARRAY_SIZE = RESOLUTION_12_BIT;//LUT_ARRAY_SIZE = 1 shl COLOR_LUT_BITS;

      DEFAULT_AUTOSCALE_FACTOR = 1;

      CLDEFAULT = clLtGray; //default colour for traces, if not in multicolour mode
      { mappings below order channel traces for specific probe layouts ~ top left to bottom right }
      LAYOUT1A : array [0..53] of integer = (10, 25, 42, 11, 24, 41, 9, 27, 43, 12, 26,
        40, 8, 28, 44, 13, 23, 39, 7, 29, 45, 14, 22, 38, 6, 30, 46, 15, 21, 37, 16, 31,
        47, 17, 20, 36, 5, 32, 48, 4, 19, 49, 3, 33, 50, 2, 18, 53, 1, 34, 51, 0, 35, 52);
      LAYOUT1B : array [0..53] of integer = (16, 27, 38, 17, 25, 37, 15, 28, 39, 14, 24,
        36, 13, 29, 40, 12, 26, 41, 11, 30, 42, 10, 23, 43, 9, 31, 44, 8, 22, 45, 7, 32, 46,
        6, 21, 47, 5, 33, 48, 4, 20, 49, 3, 34, 50, 2, 19, 53, 1, 35, 51, 0, 18, 52);
      LAYOUT1C : array [0..53] of integer = (8, 27, 46, 9, 25, 45, 7, 28, 47, 10, 24,
        44, 6, 29, 48, 11, 26, 43, 5, 30, 49, 12, 23, 42, 4, 31, 50, 13, 22, 41, 3, 32, 53,
        14, 21, 40, 2, 33, 51, 15, 20, 39, 1, 34, 52, 16, 19, 38, 0, 35, 37, 17, 18, 36);
      LAYOUT2A : array [0..53] of integer = (34, 18, 35, 17, 36, 16, 37, 15, 38, 14, 39, 13,
        40, 12, 41, 11, 42, 10, 43, 9, 44, 8, 45, 7, 46, 6, 47, 5, 48, 4, 49, 3, 50, 2, 53,
        1, 51, 0, 52, 19, 33, 20, 32, 21, 31, 22, 30, 23, 29, 26, 28, 24, 27, 25);
      LAYOUT2B : array [0..53] of integer = (32, 20, 33, 19, 34, 18, 35, 17, 36, 16, 37, 15,
        38, 14, 39, 13, 40, 12, 41, 11, 42, 10, 43, 9, 44, 8, 45, 7, 46, 6, 47, 5, 48, 21,
        49, 4, 31, 22, 50, 3, 30, 23, 53, 2, 29, 26, 51, 1, 28, 24, 52, 0, 27, 25);

type
  TRGBQuadArray = array[word] of TRGBQuad;
  pRGBQuadArray = ^TRGBQuadArray;

  TSplineArray  = array of single; //nb: open array

  TChartWin = class(TForm)
    ToolBar: TToolBar;
    CElectrode: TComboBox;
    ilToolbar: TImageList;
    tbColour: TToolButton;
    spacer1: TToolButton;
    Menu: TPopupMenu;
    muContinuous: TMenuItem;
    muAverage: TMenuItem;
    muReset: TMenuItem;
    N1: TMenuItem;
    muProperties: TMenuItem;
    muCSD: TMenuItem;
    muLFP: TMenuItem;
    muLFPWave: TMenuItem;
    muLFPColMap: TMenuItem;
    muLFPDisabled: TMenuItem;
    muCSDWave: TMenuItem;
    muCSDColMap: TMenuItem;
    muCSDDisabled: TMenuItem;
    tbLUT: TToolButton;
    N3: TMenuItem;
    muInterpolation: TMenuItem;
    muSpline: TMenuItem;
    muLinear: TMenuItem;
    muNone: TMenuItem;
    tbStartStop: TToolButton;
    tbOpen: TToolButton;
    tbSave: TToolButton;
    OpenCSD: TOpenDialog;
    SaveCSD: TSaveDialog;
    tbFS: TToolButton;
    ToolButton4: TToolButton;
    muAutoScale: TMenuItem;
    muFS: TMenuItem;
    tbOneShot: TToolButton;
    procedure FormPaint(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure CElectrodeChange(Sender: TObject);
    procedure FormMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure tbColourClick(Sender: TObject);
    procedure muItemClick(Sender: TObject);
    procedure muResetClick(Sender: TObject);
    procedure tbLUTClick(Sender: TObject);
    procedure muToggleModeClick(Sender: TObject);
    procedure tbStartStopClick(Sender: TObject);
    procedure tbOpenClick(Sender: TObject);
    procedure tbSaveClick(Sender: TObject);
    procedure tbFSClick(Sender: TObject);
    procedure muFSClick(Sender: TObject);
    procedure muAutoScaleClick(Sender: TObject);
    procedure tbOneShotClick(Sender: TObject);
  private
    //WaveformBM : TBitmap;
    ScreenX, XScreen       : array of integer;
    LFPScreenY, CSDScreenY : array[0.. RESOLUTION_12_BIT - 1] of integer;
    LUT     : array[0.. LUT_ARRAY_SIZE - 1] of TRGBQuad;
    minY, maxY : integer;

    SplineX, SplineY, Spline2ndDeriv : TSplineArray;

    ScaledWaveformHeight, LFPScaleFactor, CSDScaleFactor : single;
    ChanYOrigin : array of TPoint;
    LastPosInBuffer : integer;
    PlotArea : TRect;
    SiteIndex : array [0..63{SURF_MAX_CHANNELS}] of integer;
    procedure AD2ScreenXY;
    procedure GScaleLUT(idxmin, idxmax : integer{byte};
                        var c: array of TRGBQuad);
    procedure SpectrumLUT(idxmin, idxmax : integer{byte};
                          var c: array of TRGBQuad);
    procedure FireLUT(idxmin, idxmax : integer{byte};
                      var c: array of TRGBQuad);
    procedure ChangeLUT(LUTidx : integer);

///////////////////   These should be from MathLibrary! /////////////////////////////
    procedure Spline (const x : TSplineArray;
                      const y : TSplineArray;
                       var y2 : TSplineArray);
    procedure Splint (var x : array of single;
                const y, y2 : array of single;
                         xa : single;
           var{const?} yint : single);
////////////////////////////////////////////////////////////////////////////////////

    procedure SetYOrigins;
    procedure PlotChanLabels;
    procedure PopulateComboBox;
    procedure InitialiseWaveformBM;
    { Private declarations }
  public
    AD2UV : single;

    WaveformBM : TBitmap;

    AvgRingBuffer : TWaveform;
    SumRingBuffer, CSDRingBuffer : array of integer;
    AvgBufferIndex, AvgTriggerOffset, n : integer;
    BuffersEmpty, StopAvgWhenFull, LeftButtonDown : boolean;
    ColourMap2D : TWaveformArray;

    ChartHintWindow : THintWindow;

    SitesSelected : array [0..63{SURF_MAX_CHANNELS}] of boolean;
    NumChans, NumWavPts   : integer; //number of sites/points per site to plot
    SampleRate            : integer;//assumed to be the same for all channels
    Running, ColourTraces : boolean;
    procedure BlankPlotArea;
    procedure PlotXAxis;
    procedure PlotChart(PDeMUXedBuffer : LPUSHRT; const SampPerChanPerBuff : integer);
    procedure PlotLFP(Buffer : LPSHRT; const SampPerChanPerBuff : integer);
    procedure PlotCSD(Buffer : LPLNG;  const SampPerChanPerBuff : integer); //MODIFY PLOTLFP TO COPE WITH PLOTCSD!
    procedure PlotColMap(const DataArray2D : TWaveformArray; DataBitRange : integer;
                         ChanOffset : single = 1.0; SkipLastChans : integer = 0);
    procedure PlotSpikeTemplate(const SpikeTemplate : TSpikeTemplate;
                                Offset : integer; const Colour : TColor);
    procedure PlotSpikeEpoch(const SpikeTemplate : TSpikeTemplate; const RawBuffer : TWaveform;
                                Offset : integer; const Colour : TColor);
    procedure PlotVertLine(PosInBuffer : integer);
    procedure PlotSpikeMarker(PosInBuffer, Chan : integer);
    procedure PlotStatusLabels;
    procedure LinInterpXChan(const Buffer : TWaveformArray; NumChans : integer);
    procedure SplineInterpXChan(const Buffer : TWaveformArray; NumChans : integer);
    procedure NoInterpXChan(const Buffer : TWaveformArray; NumChans : integer);
    procedure Compute1DCSD; //<-- this procedure should be in MATHLIBRARY!
    procedure InitialiseSplineArrays;

    procedure ResetAverager; //virtual; abstract;
    procedure SetAutoYScale;
    procedure RefreshChartPlot; virtual; abstract;
    procedure OneShotFillBuffers; virtual; abstract;
    procedure MoveTimeMarker(MouseXFraction : Single); virtual; abstract;
    procedure OpenCSDFile(OpenFilename : string);
    procedure SaveCSDFile(SaveFilename : string);
    destructor Destroy; override;
    { Public declarations }
  protected
    procedure WMEraseBkGnd(var Msg: TWMEraseBkGnd);  message WM_ERASEBKGND;
  end;

var
  ChartWin: TChartWin;

implementation

uses ElectrodeTypes;

{$R *.DFM}

{-------------------------------------------------------------------------------------}
procedure TChartWin.FormCreate(Sender: TObject);
begin
  try
    WaveformBM:= TBitmap.Create;
    WaveformBM.HandleType:= bmDIB;
    SetDIBColorTable(WaveformBM.Canvas.Handle, 0, 32{LUT_ARRAY_SIZE}, LUT);
  except
    Close;
  end;
  LFPScaleFactor:= 3;
  CSDScaleFactor:= 3;
  LastPosInBuffer:= -1;
  ControlStyle:= ControlStyle + [csOpaque]; //reduce flicker
  PopulateComboBox;
  ChartHintWindow:= THintWindow.Create(Self);
  ChartHintWindow.Color := clInfoBk;
  ChartHintWindow.Font.Size:= 8;
  InitialiseWaveformBM;
  Running:= True;
end;

{-------------------------------------------------------------------------------------}
procedure TChartWin.InitialiseWaveformBM;
begin
  with WaveformBM do
  begin
    Width:= ClientWidth;
    Height:= ClientHeight - TOPMARGIN;
    PixelFormat:= pf32bit;
    GScaleLUT(0, LUT_ARRAY_SIZE, LUT); //set default greyscale LUT, ADC range 0-4095
    Canvas.Brush.Color:= clBlack;
    Canvas.Pen.Color:= CLDEFAULT;
    {Canvas.Pen.Mode:= pmMerge; //ineffective, and slows plotting considerably!}
    Canvas.Font.Color:= clYellow;
    Canvas.Font.Name:= 'Small Fonts';
    Canvas.Font.Size:= 6;
  end;
end;

{-------------------------------------------------------------------------------------}
procedure TChartWin.InitialiseSplineArrays;
var c : integer;
begin
  Setlength(SplineX, NumChans);
  Setlength(SplineY, NumChans);
  Setlength(Spline2ndDeriv, NumChans);
  for c:= 0 to NumChans -1 do
  begin
    SplineX[c]:= c;
    Spline2ndderiv[c]:= 0;
  end;
end;

{-------------------------------------------------------------------------------------}
procedure TChartWin.PopulateComboBox;
var e : integer;
begin
  CElectrode.Items.Clear;
  For e := 0 to KNOWNELECTRODES-1{from ElectrodeTypes}do
    CElectrode.Items.Add(KnownElectrode[e].Name);
  CElectrode.Items.Add('Numerical');
  CElectrode.ItemIndex:= KNOWNELECTRODES;
end;

{-------------------------------------------------------------------------------------}
procedure TChartWin.FormPaint(Sender: TObject);
begin
  Canvas.Draw(0, TOPMARGIN, WaveformBM);
end;

{-------------------------------------------------------------------------------------}
procedure TChartWin.FormResize(Sender: TObject);
begin
  { user window resized, so resize BM, arrays, and recompute trace plotting arrays }
  BlankPlotArea;
  Constraints.MinHeight:= (Font.Size * 2) * (NumChans + 2) + TOPMARGIN;
  with WaveformBM do
  begin
    Width:= ClientWidth;
    Height:= ClientHeight - TOPMARGIN;
    PlotArea:= ClientRect;
    PlotArea.Left:= LEFTMARGIN;
    dec(PlotArea.Bottom, TOPMARGIN);
    ScaledWaveformHeight:= Height / (NumChans + 1);
  end;
  SetYOrigins; //compute y-axis trace origin for each channel
  AD2ScreenXY; //compute xy-axis waveform plotting LUT
  Setlength(ColourMap2D, Round(ScaledWaveformHeight) * NumChans, NumWavPts);
  PlotChanLabels;
  LastPosInBuffer:= -1;
  RefreshChartPlot; //replot buffer scaled to fit new chart form
end;

{-------------------------------------------------------------------------}
procedure TChartWin.SetYOrigins;
var c: integer;
begin
  SetLength(ChanYOrigin, NumChans);
  for c:= 0 to NumChans - 1 do
  begin
    ChanYOrigin[c].x:= LEFTMARGIN;
    ChanYOrigin[c].y:= Round((c + 1) * ScaledWaveformHeight);
  end;
end;

{-------------------------------------------------------------------------}
procedure TChartWin.AD2ScreenXY;
var i, plotwidth : integer;
begin //these LUTs optimise waveform plotting...
  for i:= 0 to RESOLUTION_12_BIT - 1 do
  begin
    LFPScreenY[i]:= Round((i-2047)/2047 * ScaledWaveformHeight * LFPScaleFactor);
    CSDScreenY[i]:= Round((i-2047)/2047 * ScaledWaveformHeight * CSDScaleFactor);
  end;
  plotwidth:= WaveformBM.Width - LEFTMARGIN;
  SetLength(ScreenX, NumWavPts);
  for i:= 0 to NumWavPts - 1 do
    ScreenX[i]:= LEFTMARGIN + Round(plotwidth/NumWavPts*i);

  SetLength(XScreen, plotwidth);
  for i:= 0 to plotwidth - 1 do
    XScreen[i]:= Trunc(NumWavPts*i/plotwidth);
end;

{-------------------------------------------------------------------------}
procedure TChartWin.LinInterpXChan(const Buffer : TWaveformArray; NumChans : integer);
var w, c, z, PtsInterpolate, PtsInterpDiv2 : integer;
  deltaC  : single;
begin
  PtsInterpolate:= Round(ScaledWaveformHeight);
  PtsInterpDiv2:=  PtsInterpolate div 2;
  for w:= 0 to NumWavPts - 1 do
  begin
    for z:= 0 to PtsInterpDiv2 - 1 do //extend colour map beyond first channel
      ColourMap2D[z, w]:= Buffer[0, w];
    for c:= 0 to NumChans - 2 do
    begin
      deltaC:= (Buffer[c + 1, w] - Buffer[c, w]) / PtsInterpolate;
      for z:= 0 to PtsInterpolate - 1 do
        ColourMap2D[PtsInterpDiv2 + c * PtsInterpolate + z, w]:= Buffer[c, w] + Round(deltaC * z);
    end{c};
    for z:= (PtsInterpolate * NumChans - PtsInterpDiv2) - 1{?} to (PtsInterpolate * NumChans) - 1 do
      ColourMap2D[z, w]:= Buffer[NumChans - 1, w]; //extend colour map beyond last channel
  end{w};
end;

{-------------------------------------------------------------------------}
procedure TChartWin.SplineInterpXChan(const Buffer : TWaveformArray; NumChans : integer);
var w, c, PtsPerSpline, PtsInterpDiv2 : integer;
  rx, ry : single;
begin
  PtsPerSpline := Round(ScaledWaveformHeight) * (NumChans - 1);
  PtsInterpDiv2:= Round(ScaledWaveformHeight) div 2;
  for w:= 0 to NumWavPts - 1 do
  begin
    for c:= 0 to NumChans - 1 do
      SplineY[c]:= Buffer[c, w];
    Spline(SplineX, SplineY, Spline2ndDeriv);
    for c:= 0 to PtsPerSpline - 1 do
    begin
      rx:= c/ScaledWaveformHeight;
      Splint(SplineX, SplineY, Spline2ndDeriv, rx, ry);
      ColourMap2D[PtsInterpDiv2 + c, w]:= Round(ry);
    end;
    for c:= 0 to PtsInterpDiv2 - 1 do //extend colour map around first/last channels...
      ColourMap2D[c, w]:= ColourMap2D[PtsInterpDiv2, w];
    for c:= PtsPerSpline + PtsInterpDiv2 to PtsPerSpline + PtsInterpDiv2 + PtsInterpDiv2 - 1 do
      ColourMap2D[c, w]:= ColourMap2D[c - 1, w];
  end{w};
end;

{-------------------------------------------------------------------------}
procedure TChartWin.NoInterpXChan(const Buffer : TWaveformArray; NumChans : integer);
var w, c, z, PtsPerChan : integer;
begin
  PtsPerChan:= Round(ScaledWaveformHeight);
  for w:= 0 to NumWavPts - 1 do
    for c:= 0 to NumChans - 1 do
      for z:= 0 to PtsPerChan - 1 do
        ColourMap2D[c * PtsPerChan + z, w]:= Buffer[c, w];
end;

{-------------------------------------------------------------------------}
procedure TChartWin.PlotChanLabels;
var c : integer; MarginRect : TRect;
begin
  with WaveformBM.Canvas do
  begin
    MarginRect:= ClientRect;
    MarginRect.Right:= LEFTMARGIN;
    MarginRect.Top:= STATUSMARGIN;
    FillRect(MarginRect); //clear left-margin of bitmap canvas
    for c:= 0 to NumChans - 1 do
    begin
      if ColourTraces then Font.Color:= COLORTABLE[c mod 8{Length(COLORTABLE)}];
      TextOut(2, ChanYOrigin[c].y + Font.Height div 2, 'ch ' + inttostr(SiteIndex[c]));
    end;
    Font.Color:= clYellow;
  end;
  //Paint; //blit to chartwin's canvas
end;


{-------------------------------------------------------------------------}
procedure TChartWin.PlotXAxis;
var x, xTickInterval : integer;
  Row : pRGBQuadArray;//pByteArray;
begin //ugly hack, could be cleaned up
  with WaveformBM do
  begin
    xTickInterval:= Width div 10;
    Row:= ScanLine[Height - 1 - Round(ScaledWaveformHeight/2)]; //get pointer to last scanline in bitmap
    for x:= LEFTMARGIN to Width - 1 do
    begin
      Row[x].rgbGreen:= 255;
      Row[x].rgbRed  := 255;
    end{x};
    Row:= ScanLine[Height - 2 - Round(ScaledWaveformHeight/2)]; //get pointer to last scanline in bitmap
    x:= LEFTMARGIN;
    while x < Width do
    begin
      Row[x].rgbGreen:= 255;
      Row[x].rgbRed  := 255;
      inc(x, xTickInterval);
      //Canvas.TextOut(x, Height - 15, inttostr(Round(x/Width*800)));
    end;{x}
  end;
end;


{-------------------------------------------------------------------------}
procedure TChartWin.PlotStatusLabels;
var FS : integer;
begin
  with WaveformBM.Canvas do
  begin
    if muContinuous.Checked then TextOut(3, 1, 'raw   ')
      else TextOut(3, 1, 'n=' + inttostr(n) +  '   ');
    FS:= Round(RESOLUTION_12_BIT * AD2uV / LFPScaleFactor);
    TextOut(PenPos.x, 1, 'FS=' + inttostr(FS) + '�V');
  end;
end;

{-------------------------------------------------------------------------------------}
procedure TChartWin.BlankPlotArea;
begin
  WaveformBM.Canvas.FillRect(PlotArea); //blank chart trace area
end;

{-------------------------------------------------------------------------------------}
procedure TChartWin.PlotChart(PDeMUXedBuffer : LPUSHRT; const SampPerChanPerBuff : integer);
var c, w, y : integer; displayptrbak : LPUSHRT;
//  sum  : integer;
//  mean : array of short;
begin
  //BlankPlotArea;
  with WaveformBM.Canvas do
  begin
    displayptrbak:= PDeMUXedBuffer;
    for c:= 0 to NumChans -1 do
    begin
      PDeMUXedBuffer:= displayptrbak;
      inc(PDeMUXedBuffer, SiteIndex[c] * SampPerChanPerBuff);
      y:= LFPScreenY[PDeMUXedBuffer^];
      MoveTo(ChanYOrigin[c].x{ScreenX[0]}, ChanYOrigin[c].y - y);
      if ColourTraces then Pen.Color:= COLORTABLE[c mod 8{Length(COLORTABLE)}];
      for w:= 1 to SampPerChanPerBuff -1 do
      begin //could be optimised, for example, reduce lineto call overhead with polyline/gon methods...
        inc(PDeMUXedBuffer{, skipraw});
        y:= LFPScreenY[PDeMUXedBuffer^];
        LineTo(ScreenX[w], ChanYOrigin[c].y - y);
      end{w};
    end{c};
    Pen.Color:= CLDEFAULT;
  end;
  (*setlength(mean, sampperchanperbuff); //plot waveform means...

  for w:= 0 to high(mean) do
  begin
    sum:= 0;
    PDeMUXedBuffer:= displayptrbak;
    inc(PDeMUXedBuffer, w);
    for c:= 0 to NumChans -1 do
    begin
      inc(sum, PDeMUXedBuffer^);
      inc(PDeMUXedBuffer, SampPerChanPerBuff);
    end;
    mean[w]:= sum div 54;
  end;

  with WaveformBM.Canvas do
  begin
    if ColourTraces then begin
    paint;
     Exit;
    end;
    moveto(ChanYOrigin[0].x{ScreenX[0]}, ChanYOrigin[0].y - mean[0]);
    for w:= 1 to high(mean) do
      lineto(ScreenX[w], ChanYOrigin[0].y - ScreenY[mean[w]]);
  end;*)
  Paint; //blit to Chartwin's canvas
  LastPosInBuffer:= -1;
end;

{-------------------------------------------------------------------------------------}
procedure TChartWin.PlotColMap(const DataArray2D : TWaveformArray; DataBitRange : integer;
                               ChanOffset : single {default = 1.0}; SkipLastChans : integer{default = 0});
var x, y : integer;
  Row    : pRGBQuadArray;//pByteArray;
  ROffset, RDelta : integer;
begin
  {if DataBitRange < COLOR_LUT_BITS then DataBitRange:= 0
    else dec(DataBitRange, COLOR_LUT_BITS); //scales data from nbits-> LUT bits, if nbits > LUT bits}
  ROffset:= Round(ScaledWaveformHeight * ChanOffset); //centre on channel labels
  Row:= WaveformBM.ScanLine[ROffset]; //get pointer to first scanline
  RDelta:= integer(WaveformBM.ScanLine[ROffset + 1]) - integer(Row);
  for y:= 0 to High(DataArray2D) - Round(ScaledWaveformHeight * (ChanOffset + SkipLastChans - 0.5)) do
  begin
    for x:= LEFTMARGIN to WaveformBM.Width - 1 do
      Row[x]:= LUT[{(}DataArray2D[y, XScreen[x-LEFTMARGIN]]{ shr DataBitRange) and (LUT_ARRAY_SIZE -1)}];
    inc(integer(Row), RDelta);
  end{y};
end;

{-------------------------------------------------------------------------------------}
procedure TChartWin.PlotLFP(Buffer : LPSHRT; const SampPerChanPerBuff : integer);
var c, w, y : integer;
begin
  with WaveformBM.Canvas do
  begin
    for c:= 0 to NumChans -1 do
    begin
      y:= LFPScreenY[Buffer^];
      MoveTo(ChanYOrigin[c].x{ScreenX[0]}, ChanYOrigin[c].y - y);
      if ColourTraces then Pen.Color:= COLORTABLE[c mod 8{Length(COLORTABLE)}];
      for w:= 1 to SampPerChanPerBuff -1 do
      begin //could be optimised, for example, reduce line to call overhead with polyline/gon methods...
        inc(Buffer {, skipraw});
        y:= LFPScreenY[integer(Buffer^)];
        LineTo(ScreenX[w], ChanYOrigin[c].y - y);
      end{w};
      inc(Buffer);
    end{c};
    Pen.Color:= CLDEFAULT;
  end;
end;

{-------------------------------------------------------------------------------------}
procedure TChartWin.PlotCSD(Buffer : LPLNG; const SampPerChanPerBuff : integer);
var c, w, y : integer; //differs from PlotLFP only in that it expects a LPLNG
begin
  with WaveformBM.Canvas do
  begin
    for c:= 1{nDeltaY} to NumChans -2{nDeltaY} do
    begin
      y:= CSDScreenY[Buffer^ and $FFF]; // and $FFF is hack to mask saturation
      MoveTo(ChanYOrigin[c].x{ScreenX[0]}, ChanYOrigin[c].y - y);
      if ColourTraces then Pen.Color:= COLORTABLE[c mod 8{Length(COLORTABLE)}];
      for w:= 1 to SampPerChanPerBuff -1 do
      begin //could be optimised, for example, reduce line to call overhead with polyline/gon methods...
        inc(Buffer {, skipraw});
        y:= CSDScreenY[Buffer^ and $FFF];  // and $FFF is hack to mask saturation
        LineTo(ScreenX[w], ChanYOrigin[c].y - y);
      end{w};
      inc(Buffer);
    end{c};
    Pen.Color:= CLDEFAULT;
  end;
end;

{-------------------------------------------------------------------------------------}
procedure TChartWin.PlotSpikeTemplate(const SpikeTemplate : TSpikeTemplate;
                                       Offset : integer; const Colour : TColor);
var tindex, c, w, wavptsperchan : integer; //this procedure unfinished / buggy
begin
  with SpikeTemplate, WaveformBM.Canvas do
  begin
    wavptsperchan:= Length(AvgWaveform) div NumSites;
    tindex:= 0;
    Pen.Color:= Colour;
    for c:= 0 to NumChans - 1 do
    begin
      if SiteIndex[c] in Sites then
      begin
        MoveTo(ScreenX[Offset], ChanYOrigin[c].y - LFPScreenY[AvgWaveform[0]]);
        for w:= 1 to wavptsperchan - 1 do
        begin
          LineTo(ScreenX[Offset + w], ChanYOrigin[c].y - LFPScreenY[AvgWaveform[tindex]]);
          inc(tindex);
        end{w};
      end;
    end{c};
    Pen.Color:= CLDEFAULT;
  end{SpikeTemplate};
  Paint; //blit to Chartwin's canvas
end;

{-------------------------------------------------------------------------------------}
procedure TChartWin.PlotSpikeEpoch(const SpikeTemplate : TSpikeTemplate; const RawBuffer : TWaveform;
                                   Offset : integer; const Colour : TColor);
var rawindex, c, w{, pts2plot} : integer;  //REMOVE HARDCODING!!!
begin
  with SpikeTemplate do
  begin
    Canvas.Pen.Color:= Colour;
    //pts2plot:= 25; //1ms, assuming 25kHz raw data
    if offset + 24 > 2499 then
      offset:= 2475; //paint last ms for peri/transbuffer spikes
    for c:= 0 to NumChans - 1 do
    begin
      if SiteIndex[c] in Sites{= MaxChan} then
      begin
        rawindex:= SiteIndex[c] * 2500{SampPerChanPerBuff} + Offset;
        Canvas.MoveTo(ScreenX[Offset], ChanYOrigin[c].y - LFPScreenY[RawBuffer[rawindex]] + TOPMARGIN);
        for w:= 1 to 24{Pts2Plot} do
        begin
          inc(rawindex);
          Canvas.LineTo(ScreenX[Offset + w], ChanYOrigin[c].y - LFPScreenY[RawBuffer[rawindex]] + TOPMARGIN);
        end{w};
        //Break;
      end;
    end{c};
    Canvas.Pen.Color:= clDEFAULT;
  end{SpikeTemplate};
end;

{-------------------------------------------------------------------------------------}
procedure TChartWin.PlotVertLine(PosInBuffer : integer);
begin
  with Canvas do
  begin
    Pen.Color:= clWhite;
    {if LastPosInBuffer >= 0 then //erase previous time marker...
    begin
      Pen.Mode:= pmNotMask;
      MoveTo(ScreenX[LastPosInBuffer], TOPMARGIN);
      LineTo(ScreenX[LastPosInBuffer], PlotArea.Bottom + TOPMARGIN);
    end;
    Pen.Mode:= pmCopy;}
    MoveTo(ScreenX[PosInBuffer], TOPMARGIN); //draw new time marker...
    LineTo(ScreenX[PosInBuffer], PlotArea.Bottom + TOPMARGIN);
    Pen.Color:= clDEFAULT;
  end;
  LastPosInBuffer:= PosInBuffer;
end;

{-------------------------------------------------------------------------------------}
procedure TChartWin.PlotSpikeMarker(PosInBuffer, Chan : integer);
var c : integer;
begin
  with Canvas do
  begin
    Pen.Color:= clRed;
    for c:= 0 to NumChans - 1 do
      if Chan = SiteIndex[c] then
      begin
        MoveTo(ScreenX[PosInBuffer], ChanYOrigin[c].y + TOPMARGIN - Round(ScaledWaveformHeight)); //draw spike marker...
        LineTo(ScreenX[PosInBuffer], ChanYOrigin[c].y + TOPMARGIN + Round(ScaledWaveformHeight));
        Break;
      end;
    Pen.Color:= CLDEFAULT;
  end;
end;

{-------------------------------------------------------------------------------------}
procedure TChartWin.CElectrodeChange(Sender: TObject);
var c, i, TotalChans : integer; ChanOrder : array [0..63{SURF_MAX_CHANNELS}] of Integer;
begin
  TotalChans:= 0;
  if CElectrode.Items[CElectrode.ItemIndex] = '�Map54_1a' then //re-map site channel order (of those selected in polytrodeGUI)
    Move(LAYOUT1A, ChanOrder[0], SizeOf(Layout1A)) else
  if CElectrode.Items[CElectrode.ItemIndex] = '�Map54_1b' then //re-map site channel order (of those selected in polytrodeGUI)
    Move(LAYOUT1B, ChanOrder[0], SizeOf(Layout1B)) else
  if CElectrode.Items[CElectrode.ItemIndex] = '�Map54_1c' then //re-map site channel order (of those selected in polytrodeGUI)
    Move(LAYOUT1C, ChanOrder[0], SizeOf(Layout1C)) else
  if CElectrode.Items[CElectrode.ItemIndex] = '�Map54_2a' then //re-map site channel order (of those selected in polytrodeGUI)
    Move(LAYOUT2A, ChanOrder[0], SizeOf(Layout2A)) else
  if CElectrode.Items[CElectrode.ItemIndex] = '�Map54_2b' then //re-map site channel order (of those selected in polytrodeGUI)
    Move(LAYOUT2B, ChanOrder[0], SizeOf(Layout2B)) else
    begin
      for c:= 0 to High(ChanOrder) do ChanOrder[c]:= c; //display channels in numerical order
      TotalChans:= High(ChanOrder);
    end;
  if TotalChans = 0 then TotalChans:= KnownElectrode[CElectrode.ItemIndex].NumSites;

  NumChans:= 0;
  for c:= 0 to TotalChans -1 do
    for i:= 0 to TotalChans -1 do
      if SitesSelected[i] then
        if i = ChanOrder[c] then
        begin
          SiteIndex[NumChans]:= i;
          inc(NumChans);
          Break;
        end;
  PlotChanLabels; //update channel labels
  RefreshChartPlot; //replot channels in correct order to match new layout
end;

{-------------------------------------------------------------------------------------}
procedure TChartWin.FormMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if Button = mbLeft then
  begin
    LeftButtonDown:= True;
    MoveTimeMarker((X - LEFTMARGIN) / (ClientWidth - LEFTMARGIN)); //jump to mouse location
  end;
end;

{-------------------------------------------------------------------------------------}
procedure TChartWin.FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
begin
  if LastPosInBuffer < 0 then Exit;
  if LeftButtonDown then
  begin
    Paint; //clear existing vertline
    MoveTimeMarker((X - LEFTMARGIN) / (ClientWidth - LEFTMARGIN));
  end;
end;

{-------------------------------------------------------------------------------------}
procedure TChartWin.FormMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if LeftButtonDown then Paint; //erase vertline
  LeftButtonDown:= False;
  ChartHintWindow.ReleaseHandle;
end;

{-------------------------------------------------------------------------------------}
procedure TChartWin.tbStartStopClick(Sender: TObject);
begin
  Running:= not Running;
  if Running then
  begin
    tbStartStop.ImageIndex:= 3;
    tbStartStop.Hint:= 'Stop';
  end else
  begin
    tbStartStop.ImageIndex:= 2;
    tbStartStop.Hint:= 'Start';
  end;
end;

{-------------------------------------------------------------------------------------}
procedure TChartWin.tbOneShotClick(Sender: TObject);
begin
  OneShotFillBuffers;
end;

{-------------------------------------------------------------------------------------}
procedure TChartWin.tbColourClick(Sender: TObject);
begin
  ColourTraces:= tbColour.Down;
  PlotChanLabels;   //update channel labels in colour/yellow
  RefreshChartPlot; //replot waveforms to reflect new colour selection
end;

{-------------------------------------------------------------------------------------}
procedure TChartWin.muItemClick(Sender: TObject);
begin
  with Sender as TMenuItem do Checked:= not(Checked);
  { set valid default menu setting if user unchecks all options }
  if not(muContinuous.Checked or muAverage.Checked) then muContinuous.Checked:= True;
  if not(muLFPWave.Checked or muLFPColMap.Checked) then muLFPDisabled.Checked:= True;
  if not(muCSDWave.Checked or muCSDColMap.Checked) then muCSDDisabled.Checked:= True;
  muReset.Enabled:= muAverage.Checked;
  BlankPlotArea;
  RefreshChartPlot;
end;

{-------------------------------------------------------------------------------------}
procedure TChartWin.muResetClick(Sender: TObject);
begin
  ResetAverager;
end;

{-------------------------------------------------------------------------------------}
procedure TChartWin.muFSClick(Sender: TObject);
var i : integer;
begin
  LFPScaleFactor:= 1;
  CSDScaleFactor:= 1;
  minY:= 0;
  maxY:= RESOLUTION_12_BIT - 1;
  for i:= 0 to RESOLUTION_12_BIT - 1 do
  begin
    LFPScreenY[i]:= Round((i-2048)/2048 * ScaledWaveformHeight * LFPScaleFactor);
    CSDScreenY[i]:= Round((i-2048)/2048 * ScaledWaveformHeight * CSDScaleFactor);
  end;
  ChangeLUT(tbLUT.Tag);// update LUT
  RefreshChartPlot;
end;

{-------------------------------------------------------------------------------------}
procedure TChartWin.muAutoScaleClick(Sender: TObject);
begin
  SetAutoYScale;
  RefreshChartPlot;
end;

{-------------------------------------------------------------------------------------}
procedure TChartWin.muToggleModeClick(Sender: TObject);
begin
  ResetAverager;
  muItemClick(Sender);
end;

{-------------------------------------------------------------------------}
procedure TChartWin.GScaleLUT(idxmin, idxmax : integer{byte};
                              var c: array of TRGBQuad);
{ Generates an 8 bit 'Grayscale' LUT given the range [idxmin, idxmax]
  In this case each colour component ranges from 0 (no contribution) to
  255 (fully saturated) }
var index   : integer;
  increment : single;
begin
  increment:= 255/(idxmax - idxmin);
  for index:= 0 to idxmin - 1 do
    with c[index] do
    begin
      rgbBlue    := 0;
      rgbGreen   := 0;
      rgbRed     := 0;
      rgbReserved:= 0;
    end;
  for index:= 0 to (idxmax - idxmin - 1) do
    with c[idxmin + index] do
    begin
      rgbBlue    := Round(index * increment);
      rgbGreen   := rgbBlue;
      rgbRed     := rgbBlue;
      rgbReserved:= 0;
    end;
  for index:= idxmax to high(c) do
    with c[index] do
    begin
      rgbBlue    := 255;
      rgbGreen   := 255;
      rgbRed     := 255;
      rgbReserved:= 0;
    end;
end;

{-------------------------------------------------------------------------}
procedure TChartWin.FireLUT(idxmin, idxmax : integer{byte};
                            var c: array of TRGBQuad);
{ Generates an 8-bit 'Fire' LUT given the range [idxmin, idxmax]
  In this case each colour component ranges from 0 (no contribution) to
  255 (fully saturated) }
var
  rangediv3 : single;
  index : integer;
begin
  rangediv3:= (idxmax - idxmin) / 3;
  for index:= 0 to idxmin - 1 do
    with c[index] do
    begin
      rgbBlue    := 0;
      rgbGreen   := 0;
      rgbRed     := 0;
      rgbReserved:= 0;
    end;
  for index:= idxmin to idxmax - 1 do
    with c[index] do
    begin
      if (index - idxmin) < rangediv3 then
      begin
        rgbRed:= Byte(Round((index - idxmin) / rangediv3 * 255));
        rgbGreen:= 0;
        rgbBlue := 0;
      end else if (index - idxmin) < (rangediv3 * 2) then
      begin
        rgbRed  := 255;
        rgbGreen:= Byte(1 + Round((index - idxmin) / rangediv3 * 255));
        rgbBlue := 0;
      end else
      begin
        rgbBlue:= Byte(2 + Round((index - idxmin) / rangediv3 * 255));
        rgbRed:= 255;
        rgbGreen:= 255;
      end;
      rgbReserved:= 0; //alpha not used
    end;
  for index:= idxmax to high(c) do
    with c[index] do
    begin
      rgbBlue    := 255;
      rgbGreen   := 255;
      rgbRed     := 255;
      rgbReserved:= 0;
    end;
end;

{-------------------------------------------------------------------------}
procedure TChartWin.SpectrumLUT(idxmin, idxmax : integer{byte};
                              var c: array of TRGBQuad);
{ Generates an 8 bit 'Rainbow' LUT given the range [idxmin, idxmax]
  In this case each colour component ranges from 0 (no contribution) to
  255 (fully saturated) }
var
  rangediv4 : single;
  index : integer;
begin
  rangediv4:= (idxmax - idxmin) / 4;
  for index:= 0 to idxmin - 1 do
    with c[index] do
    begin
      rgbBlue    := 255;
      rgbGreen   := 0;
      rgbRed     := 0;
      rgbReserved:= 0;
    end;
  for index:= idxmin to idxmax - 1 do
    with c[index] do
    begin
      if (index - idxmin) < rangediv4 then
      begin
        rgbRed  := 0;
        rgbGreen:= Byte(Round((index - idxmin) / rangediv4 * 255));
        rgbBlue := 255;
      end else if (index - idxmin) < (rangediv4 * 2) then
      begin
        rgbRed  := 0;
        rgbGreen:= 255;
        rgbBlue := Byte(-2 - Round((index - idxmin) / rangediv4 * 255));
      end else if (index - idxmin) < (rangediv4 * 3) then
      begin
        rgbRed  := Byte(2 + Round((index - idxmin) / rangediv4 * 255));
        rgbGreen:= 255;
        rgbBlue := 0;
      end else
      begin
        rgbRed  := 255;
        rgbGreen:= Byte(-4 - Round((index - idxmin) / rangediv4 * 255));
        rgbBlue := 0;
      end;
      rgbReserved := 0; //alpha not used
    end;
  for index:= idxmax to high(c) do
    with c[index] do
    begin
      rgbBlue    := 0;
      rgbGreen   := 0;
      rgbRed     := 255;
      rgbReserved:= 0;
    end;
end;

{-------------------------------------------------------------------------------------}
procedure TChartWin.tbLUTClick(Sender: TObject);
begin
  tbLUT.Tag:= (tbLUT.Tag + 1) mod 3; //toggle 3 button states
  ChangeLUT(tbLUT.Tag);
end;

{-------------------------------------------------------------------------------------}
procedure TChartWin.ChangeLUT(LUTidx : integer);
begin
  case LUTidx of
    0 : GScaleLUT(minY, maxY, LUT);// LUT_ARRAY_SIZE - 1, LUT);
    1 : FireLUT(minY, maxY, LUT);//(0, LUT_ARRAY_SIZE - 1, LUT);
    2 : SpectrumLUT(minY, maxY, LUT); //keep black ($00) and white ($FF) for labels
  end;
  if WaveformBM.PixelFormat <= pf8bit then
    SetDIBColorTable(WaveformBM.Canvas.Handle, 0, LUT_ARRAY_SIZE, LUT) //cycle colour palette...
  else RefreshChartPlot; //...for > 8bitpfs, need to replot bitmap (no colour table)
end;

{------------------------------------------------------------------------------}
procedure TChartWin.tbSaveClick(Sender: TObject);
begin
  if BuffersEmpty then Exit;
  if Running then StopAvgWhenFull:= True;
  if SaveCSD.Execute then
    SaveCSDFile(SaveCSD.FileName)
  else ShowMessage('File not saved');
end;

{------------------------------------------------------------------------------}
procedure TChartWin.SaveCSDFile(SaveFilename : string);
var fs : TFileStream;
begin
  try
    SaveFilename:= ExtractFileName(SaveFilename);
    fs:= TFileStream.Create(SaveFilename + '.csd', fmCreate);
    with fs do
    begin
      WriteBuffer('SCSD', 4); //header id
      WriteBuffer('v1.0', 4); //write version number
      WriteBuffer(AD2uV, SizeOf(AD2uV));
      WriteBuffer(NumChans, SizeOf(NumChans));
      WriteBuffer(SitesSelected, Length(SitesSelected));
      WriteBuffer(n, SizeOf(n)); //'n' samples in avg
      WriteBuffer(SumRingBuffer[0], Length(SumRingBuffer) * 4);
      Free;
    end{fs};
  except
    Showmessage('Error. File not saved');
    fs.Free;
    Exit;
  end;
  Caption:= 'CSDWin (' + SaveFilename + ')';
end;

{-------------------------------------------------------------------------------------}
procedure TChartWin.tbOpenClick(Sender: TObject);
begin
  if Running then tbStartStopClick(Self);
  if OpenCSD.Execute then
    OpenCSDFile(OpenCSD.FileName);
end;

{------------------------------------------------------------------------------}
procedure TChartWin.OpenCSDFile(OpenFilename : string);
var fs : TFilestream;//TextFile;
  s, c, idx : integer;
  id, ver : array [0..3] of char;
  fsites  : array [0..63{SURF_MAX_CHANNELS}] of boolean;
  fgain : single;
(*begin
  try
    AssignFile(fs, OpenFilename);
    Reset(fs);
  except
    Showmessage('Error opening file.');
    Exit;
  end;
  numchans:=  8;
  numwavpts:= 62;
  n:=1; //'n' samples in avg
  Setlength(SumRingBuffer, NumChans * NumWavPts);
  Setlength(AvgRingBuffer, NumChans * NumWavPts);
  Setlength(CSDRingBuffer, (NumChans - 2{should be - CSD_nDELTAY - CSD_nDELTAY}) * NumWavPts);
  BuffersEmpty:= False;
  for s:= 0 to 61 do
    for c:= 7 downto 0 do
      read(fs, SumRingBuffer[s+c*62]);
  CloseFile(fs);
  for s:= 0 to High(AvgRingBuffer) do AvgRingBuffer[s]:= Round(SumRingBuffer[s] / n);
  Compute1DCSD;
  Caption:= 'CSDWin (' + ExtractFileName(OpenFilename) + ')';
  if n > 1 then muAverage.Checked:= True;
  BlankPlotArea;
  //SetAutoYScale;
  RefreshChartPlot;
end; *)

begin
  try
    fs:= TFileStream.Create(OpenFilename, fmOpenRead);
  except
    Showmessage('Error reading file.');
    Exit;
  end;
  with fs do
  begin
    ReadBuffer(id, 4);
    ReadBuffer(ver, 4);
    if (id <> 'SCSD') or (ver <> 'v1.0') then
    begin
      Showmessage('Wrong file type or version.');
      Free;
      Exit;
    end;
    ReadBuffer(fgain, SizeOf(fgain));
    if fgain <> AD2uV then
      Showmessage('Warning: saved gain differs from current LFP channel gain. Using file gain.');
    AD2uV:= fgain;
    ReadBuffer(NumChans, SizeOf(NumChans));
    ReadBuffer(fsites, Length(fsites){bytes});
    for s:= 0 to high(SitesSelected) do
      if SitesSelected[s] xor fsites[s] then
      begin
        Showmessage('Warning: channels in file differ from current LFP channels.'
        + chr(13) + 'Mapping saved channels to current LFP channels.');
        Break;
      end;
    ReadBuffer(n, SizeOf(n)); //'n' samples in avg
    Setlength(SumRingBuffer, NumChans * NumWavPts);
    Setlength(AvgRingBuffer, NumChans * NumWavPts);
    Setlength(CSDRingBuffer, (NumChans - 2{should be - CSD_nDELTAY - CSD_nDELTAY}) * NumWavPts);
    ReadBuffer(SumRingBuffer[0], Length(SumRingBuffer) * 4);
    Free;
  end{fs};
  BuffersEmpty:= False;
  for s:= 0 to High(AvgRingBuffer) do AvgRingBuffer[s]:= Round(SumRingBuffer[s] / n);
  Compute1DCSD;
  Caption:= 'CSDWin (' + ExtractFileName(OpenFilename) + ')';
  if n > 1 then muAverage.Checked:= True;
  BlankPlotArea;
  SetAutoYScale;
  RefreshChartPlot;
end;

{------------------------------------------------------------------------------}
procedure TChartWin.tbFSClick(Sender: TObject);
begin
  BlankPlotArea;
  SetAutoYScale;
  RefreshChartPlot;
end;

{------------------------------------------------------------------------------}
procedure TChartWin.SetAutoYScale;
var min, max, range, i : integer;
begin //raw autoscale to max/min...
  min:= AvgRingBuffer[0]; //...first for LFP
  max:= min;
  for i:= 1 to high(AvgRingBuffer) do
    if AvgRingBuffer[i] < min then
      min:= AvgRingBuffer[i] else
    if AvgRingBuffer[i] > max then
      max:= AvgRingBuffer[i];
  range:= max - min;
  if range = 0 then
  begin
    LFPScaleFactor:= 1;
    min:= 0;
    max:= RESOLUTION_12_BIT - 1;
  end else
    LFPScaleFactor:= RESOLUTION_12_BIT / Range;
  for i:= 0 to RESOLUTION_12_BIT - 1 do
    LFPScreenY[i]:= Round((i-2048)/2048 * ScaledWaveformHeight * LFPScaleFactor);

  if muLFPColMap.Checked then
  begin
    minY:= min;
    maxY:= max;
  end;

  min:= CSDRingBuffer[0]; //...now for CSD
  max:= min;
  for i:= 1 to high(CSDRingBuffer) do
    if CSDRingBuffer[i] < min then
      min:= CSDRingBuffer[i] else
    if CSDRingBuffer[i] > max then
      max:= CSDRingBuffer[i];
  range:= max - min;
  if range = 0 then
  begin
    CSDScaleFactor:= 1;
    min:= 0;
    max:= RESOLUTION_12_BIT - 1;
  end else
    CSDScaleFactor:= RESOLUTION_12_BIT / Range;
  for i:= 0 to RESOLUTION_12_BIT - 1 do
    CSDScreenY[i]:= Round((i-2048)/2048 * ScaledWaveformHeight * CSDScaleFactor);

  if not(muLFPColMap.Checked) and muCSDColMap.Checked then
  begin
    minY:= min;
    maxY:= max;
  end;

  ChangeLUT(tbLUT.Tag);// update LUT (for CSD or LFP, not both)
end;

{-------------------------------------------------------------------------}
procedure TChartWin.ResetAverager;
var i : integer;
begin
  n:= 0;
  for i:= 0 to High(SumRingBuffer) do
  begin
    SumRingBuffer[i]:= 0;
    AvgRingBuffer[i]:= 0;
  end;
  for i:= 0 to High(CSDRingBuffer) do CSDRingBuffer[i]:= 0;
  AvgBufferIndex:= 0;
  BuffersEmpty:= True;
end;

{------------------------------------------------------------------------------}
procedure TChartWin.Spline (const x : TSplineArray;
                            const y : TSplineArray;
                             var y2 : TSplineArray);

{Given arrays x[0..n] and y[0..n] containing a tabulated function, i.e.
yi=f(xi) with x1<x2<x3<...xn, and given values yp1 and ypn for the first
derivatives of the interpolating function at points 1 and n, this routine
returns an array y2[1..n] that contains the second derivatives of the
interpolating function at the tabulated points xi.  If yp1 and/or yp2
are equal to 1x10^30 or larger, the routine is signalled to set the
corresponding boundary condition for a natural spline, with zero second
derivative on that boundary.}

{ 4.4.03: modified to Open array version }

var i, k           : integer;
    p, qn, sig, un : single;
    u              : TSplineArray;
    yp1, ypn       : single;

begin
  yp1:= 0.99E30+1;
  ypn:= 0.99E30+1;

  {New}Setlength(u, Length(x));
  if yp1>0.99E30 then
  begin
    y2[0]:= 0.0;
    u[0]:= 0.0;
  end else
  begin
    y2[0]:= -0.5;
    u[0]:= (3.0/(x[1]-x[0]))*((y[1]-y[0])/(x[1]-x[0])-yp1);
  end;

  for i:= Low(x) + 1 to High(x) - 1 do
  begin
    sig:=(x[i]-x[i-1])/(x[i+1]-x[i-1]);
    p:=sig*y2[i-1]+2.0;
    y2[i]:=(sig-1.0)/p;
    u[i]:=(y[i+1]-y[i])/(x[i+1]-x[i])-(y[i]-y[i-1])/(x[i]-x[i-1]);
    u[i]:=(6.0*u[i]/(x[i+1]-x[i-1])-sig*u[i-1])/p;
  end;

  if ypn>0.99E30 then
  begin
    qn:=0.0;
    un:=0.0;
  end else
  begin
    qn:=0.5;
    un:=(3.0/(x[High{?}(x)]-x[High{?}(x)-1]))*(ypn-
        (y[High(y)]-y[High(y)-1])/(x[High(x)]-x[High(x)-1]));
  end;

  y2[High(y2)]:=(un*u[High(y2)-1])/(qn*y2[High(y2)-1]+1.0);

  for k:=High(y2)-1 downto 1 do
    y2[k]:=y2[k]*y2[k+1]+u[k];

end;

{------------------------------------------------------------------------------}
procedure TChartWin.Splint (var x : array of single;
            const y, y2 : array of single;
                     xa : single;
       var{const?} yint : single);

{Given the arrays x[1..n] and y[1..n] which tabulate a function (with x's
in order), and given the array y2[1..n], which is the output from SPLINE
above, and given a value of 'x', this routine returns a cubic spline
interpolated value 'y'.}

var klo,khi,k : integer;
    h,b,a     : single;

begin
  klo:= Low(x);
  khi:= High(x);
  while khi-klo > 1 do
  begin
    k:=(khi+klo) div 2;
    if x[k] > xa then khi:=k
      else klo:=k;
  end;

  h:=x[khi]-x[klo];
  if h=0.0 then Exit;

  a:=(x[khi]-xa)/h;
  b:=(xa-x[klo])/h;
  yint:=a*y[klo]+b*y[khi]+((a*a*a-a)*y2[klo]+(b*b*b-b)*y2[khi])*(h*h)/6;
end;

{-----------------------------------------------------------------------------}
procedure TChartWin.Compute1DCSD; //  <----   should be in SURFMATHLIBRARY!
var i, j, w : integer;
begin
  i:= 0; //index into CSD array
  j:= NumWavPts * 1{CSD_nDeltaY}; //index into field pot. waveforms
  for w:= j to high(AvgRingBuffer) - j do
  begin
    CSDRingBuffer[i]:=
      Round((AvgRingBuffer[w + j] - (2 * AvgRingBuffer[w]) + AvgRingBuffer[w - j]) /
                             ({CSD_nDeltaY * CSD_nDeltaY}1)) + 2047;
    inc(i);
  end;
end;

{-------------------------------------------------------------------------------------}
procedure TChartWin.WMEraseBkgnd(var msg: TWMEraseBkGnd);
begin
 msg.Result:=-1;
end;

{-------------------------------------------------------------------------------------}
destructor TChartWin.Destroy;
begin
  FreeAndNil(WaveformBM);
  //dynamic arrays too?
  inherited Destroy;
end;

end.