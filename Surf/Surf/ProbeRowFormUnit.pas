unit ProbeRowFormUnit;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Spin, ExtCtrls, SurfTypes, SurfPublicTypes, ElectrodeTypes;

type
  TProbeRowForm = class(TForm)
    ThresholdSpin: TSpinEdit;
    ADGainBox: TComboBox;
    TrigPtSpin: TSpinEdit;
    LockOutSpin: TSpinEdit;
    NptsSpin: TSpinEdit;
    ProbeDescription: TEdit;
    ActualTimeLabel: TLabel;
    ProbeNum: TLabel;
    SkipSpin: TSpinEdit;
    NumChanSpin: TSpinEdit;
    ChanStartSpin: TSpinEdit;
    ChanEndSpin: TSpinEdit;
    lblSampFreq: TLabel;
    Label2: TLabel;
    Label1: TLabel;
    View: TCheckBox;
    Save: TCheckBox;
    CElectrode: TComboBox;
    procedure FormCreate(Sender: TObject);
    procedure ChanStartSpinChange(Sender: TObject);
    procedure NumChanSpinChange(Sender: TObject);
    procedure ChanEndSpinChange(Sender: TObject);
    procedure SkipSpinChange(Sender: TObject);
    procedure NptsSpinChange(Sender: TObject);
    procedure CElectrodeChange(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    TotalADChannels : integer;
    ChannelsCreated : boolean;
    Probetype : char;
    procedure CheckProbeChannels(ProbeNum : integer); virtual; abstract;
  end;

implementation

{$R *.DFM}

procedure TProbeRowForm.FormCreate(Sender: TObject);
var e : integer;
begin
  ChannelsCreated := FALSE;
  NumChanSpin.Value := 0;
  CElectrode.Items.Clear;
  for e := 0 to KNOWNELECTRODES - 1 {from ElectrodeTypes} do
    CElectrode.Items.Add(KnownElectrode[e].Name);
  CElectrode.Items.Add('UnDefined');
  ProbeDescription.Text := 'UnDefined';
  ProbeDescription.Modified := True;
  CElectrode.ItemIndex:= KNOWNELECTRODES;
  TrigPtSpin.MaxValue:= NPtsSpin.Value - 4; //binds TrigPt to NumWavPts
end;

procedure TProbeRowForm.ChanStartSpinChange(Sender: TObject);
begin
  if not ChannelsCreated then exit;
  if ChanStartSpin.Value + NumChanSpin.Value-1 >= TotalADChannels then
    ChanStartSpin.Value := TotalADChannels - NumChanSpin.Value;
  if (NumChanSpin.value = 0) or (probetype=CONTINUOUS)
    then ChanEndSpin.Value := ChanStartSpin.Value
    else ChanEndSpin.Value := ChanStartSpin.Value + NumChanSpin.Value-1;
  if (ChanStartSpin.Value >= 0) and (ChanStartSpin.Value < TotalADChannels)
    then CheckProbeChannels(Tag);
end;

procedure TProbeRowForm.NumChanSpinChange(Sender: TObject);
begin
  if not ChannelsCreated then exit;
  if not ((ChanStartSpin.Value >= 0) and (NumChanSpin.Value <= TotalADChannels)) then exit;
  if ChanStartSpin.Value + NumChanSpin.Value-1 >= TotalADChannels then
    NumChanSpin.Value := TotalADChannels - ChanStartSpin.Value;
  ChanEndSpin.Value := ChanStartSpin.Value + NumChanSpin.Value-1;
  if (NumChanSpin.Value >= 0) and (NumChanSpin.Value < 32)
   then CheckProbeChannels(Tag);
  if (CElectrode.ItemIndex<KNOWNELECTRODES)
  and (CElectrode.ItemIndex>=0) then
    if (ChanEndSpin.Value-ChanStartSpin.Value+1) <> KnownElectrode[CElectrode.ItemIndex].NumSites then
    begin
      CElectrode.ItemIndex := KNOWNELECTRODES;
      ProbeDescription.Text := KnownElectrode[CElectrode.ItemIndex].Description;
      ProbeDescription.Modified:= True;
    end;
end;

procedure TProbeRowForm.ChanEndSpinChange(Sender: TObject);
begin
  if not ChannelsCreated then exit;

  if ChanEndSpin.Value < ChanStartSpin.Value then ChanEndSpin.Value := ChanStartSpin.Value;
  if (ChanEndSpin.Value = ChanStartSpin.Value)
    then begin if (probetype<>CONTINUOUS) then NumChanSpin.Value := 0; end
    else NumChanSpin.Value := ChanEndSpin.Value - ChanStartSpin.Value + 1;
  if (ChanEndSpin.Value >= 0) and (ChanEndSpin.Value < TotalADChannels)
    then CheckProbeChannels(Tag);

  if (CElectrode.ItemIndex<KNOWNELECTRODES)
  and (CElectrode.ItemIndex>=0) then
    if (ChanEndSpin.Value-ChanStartSpin.Value+1) <> KnownElectrode[CElectrode.ItemIndex].NumSites then
    begin
      CElectrode.ItemIndex := KNOWNELECTRODES;
      ProbeDescription.Text := 'Undefined';
      ProbeDescription.Modified:= True;
    end;
end;

procedure TProbeRowForm.SkipSpinChange(Sender: TObject);
var i: word;
begin
  try
    //if value is not a positive integer this will raise and exception and jump to 'except'.
    i := SkipSpin.Value;
    if i > SkipSpin.MinValue then CheckProbeChannels(Tag);
  except
  end;
end;

procedure TProbeRowForm.NptsSpinChange(Sender: TObject);
var i: integer;
begin
  try
    //if value is not an int this will raise and exception and bounce to 'except'.
    i := NPtsSpin.Value;
    if i > NPtsSpin.MinValue then CheckProbeChannels(Tag);
    TrigPtSpin.MaxValue:= NPtsSpin.Value - 4; //binds TrigPt to NumWavPts
    TrigPtSpin.Value:= TrigPtSpin.Value;
  except
  end;
end;

procedure TProbeRowForm.CElectrodeChange(Sender: TObject);
begin
  //ProbeDescription.Text := KnownElectrode[CElectrode.ItemIndex].Name;
  if (CElectrode.ItemIndex<KNOWNELECTRODES)
  and (CElectrode.ItemIndex>=0) then
  begin
    //if KnownElectrode[CElectrode.ItemIndex].Name <> 'UnDefined' then
    NumChanSpin.Value := KnownElectrode[CElectrode.ItemIndex].NumSites;
    ProbeDescription.Text := KnownElectrode[CElectrode.ItemIndex].Description;
    ProbeDescription.Modified:= True;
  end;
end;

end.
