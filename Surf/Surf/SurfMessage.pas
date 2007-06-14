unit SurfMessage;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Buttons;

type
  TMesgQueryForm = class(TForm)
    Edit: TEdit;
    Label1: TLabel;
    okbut: TBitBtn;
    cancelbut: TBitBtn;
    procedure FormShow(Sender: TObject);
    procedure cancelbutClick(Sender: TObject);
    procedure okbutClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    procedure MessageSent(mesg : ShortString); virtual; abstract;
  end;

implementation

{$R *.DFM}

procedure TMesgQueryForm.FormShow(Sender: TObject);
begin
  Text := '';
end;

procedure TMesgQueryForm.cancelbutClick(Sender: TObject);
begin
  MessageSent('');
end;

procedure TMesgQueryForm.okbutClick(Sender: TObject);
begin
  MessageSent(Edit.Text);
end;

end.
