unit GratAnalForm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  SurfPublicTypes, SurfAnal, ExtCtrls;

type
  TGratForm = class(TForm)
    SurfAnal: TSurfAnal;
    procedure SurfBridgeSurfFile(SurfFile: TSurfFileInfo);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  GratForm: TGratForm;

implementation

{$R *.DFM}

procedure TGratForm.SurfBridgeSurfFile(SurfFile: TSurfFileInfo);
begin
  ShowMEssage('here');
end;

end.