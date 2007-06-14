program Anal3DPredict;

uses
  Forms,
  SurfLocateAndSort in 'SurfLocateAndSort.pas' {LocSortForm},
  SurfSortMain in 'SurfSortMain.pas' {SurfSortForm},
  SurfPublicTypes in '..\Public\SurfPublicTypes.pas',
  NumRecipies in '..\Surf\NumRecipies.pas',
  ElectrodeTypes in '..\Public\ElectrodeTypes.pas',
  WaveFormPlotUnit in '..\Public\WaveFormPlotUnit.pas' {WaveFormPlotForm};

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TSurfSortForm, SurfSortForm);
  Application.CreateForm(TLocSortForm, LocSortForm);
  Application.Run;
end.
