unit ExtGain;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Buttons, Mask, SurfTypes, SurfPublicTypes, {, RXSpin, RXCtrls, }Spin;

type
  TExtGainForm = class(TForm)
    AllSame: TCheckBox;
    Label1: TLabel;
    lprobe: TLabel;
    OkBut: TBitBtn;
    procedure OkButClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormPaint(Sender: TObject);
  private
    { Private declarations }
    procedure EditOnChange(Sender: TObject);
  public
    { Public declarations }
    Probe,NumChannels : integer;
    ExtGainArray : array[0..SURF_MAX_CHANNELS-1] of {TRx}TSpinEdit;
  end;

var
  ExtGainForm: TExtGainForm;

implementation

{$R *.DFM}

procedure TExtGainForm.OkButClick(Sender: TObject);
begin
  Close;
end;

procedure TExtGainForm.FormShow(Sender: TObject);
var i : integer;
begin
  lprobe.caption := inttostr(probe);
  Canvas.Font.Color := clBlue;
  for i := 0 to NumChannels-1 do
  begin
    ExtGainArray[i].Visible := TRUE;
    ExtGainArray[i].Enabled := TRUE;
  end;
  if ExtGainForm.ClientHeight < ExtGainArray[NumChannels-1].Top + ExtGainArray[NumChannels-1].Height
  then ExtGainForm.ClientHeight :=  ExtGainArray[NumChannels-1].Top + ExtGainArray[NumChannels-1].Height;
end;

procedure TExtGainForm.EditOnChange(Sender: TObject);
var i : integer;
begin
  if ExtGainArray[(Sender as {TRx}TSpinEdit).Tag].Value > 50000 then
    ExtGainArray[(Sender as {TRx}TSpinEdit).Tag].Value := 50000;
  if ExtGainArray[(Sender as {TRx}TSpinEdit).Tag].Value < 0 then
    ExtGainArray[(Sender as {TRx}TSpinEdit).Tag].Value := 0;

  if AllSame.Checked then
    for i := 0 to NumChannels-1 do
      ExtGainArray[i].Value := ExtGainArray[(Sender as {TRx}TSpinEdit).Tag].Value;
end;

procedure TExtGainForm.FormCreate(Sender: TObject);
var i : integer;
begin
  for i := 0 to SURF_MAX_CHANNELS-1 do
  begin
    ExtGainArray[i] := {TRx}TSpinEdit.CreateParented(ExtGainForm.Handle);
    ExtGainArray[i].Left := 50;
    ExtGainArray[i].Top := 75 + i * (ExtGainArray[i].Height + 2);
    ExtGainArray[i].Width := 70;
    ExtGainArray[i].Visible := FALSE;
    ExtGainArray[i].Enabled := FALSE;
    //ExtGainArray[i].ValueType := vtInteger;
    ExtGainArray[i].MinValue := 0;
    ExtGainArray[i].MaxValue := 50000;
    ExtGainArray[i].MaxLength := 5;
    ExtGainArray[i].Value := 0;
    ExtGainArray[i].BiDiMode := bdLeftToRight;
    ExtGainArray[i].Tag := i;
    ExtGainArray[i].OnChange := EditOnChange;
  end;
end;

procedure TExtGainForm.FormDestroy(Sender: TObject);
var i : integer;
begin
  for i := 0 to SURF_MAX_CHANNELS-1 do
    ExtGainArray[i].Free;
end;

procedure TExtGainForm.FormPaint(Sender: TObject);
var i : integer;
begin
  lprobe.caption := inttostr(probe);
  Canvas.Font.Color := clBlue;
  Canvas.Brush.Color := clLtGray;
  for i := 0 to NumChannels-1 do
    ExtGainForm.Canvas.TextOut(10,ExtGainArray[i].Top,'Ch'+inttostr(i)+':');
  Canvas.Refresh;
end;


end.