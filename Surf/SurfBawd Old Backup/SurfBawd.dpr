program SurfBawd;

uses
  Forms,
  SurfBawdMain in 'SurfBawdMain.pas' {SurfBawdForm},
  SurfPublicTypes in '..\Public\SurfPublicTypes.pas',
  WaveFormPlotUnit in '..\Public\WaveFormPlotUnit.pas' {WaveFormPlotForm},
  ElectrodeTypes in '..\Surf\ElectrodeTypes.pas',
  SurfMathLibrary in '..\Public\SurfMathLibrary.pas',
  InfoWinUnit in '..\Public\InfoWinUnit.pas' {InfoWin},
  SurfLocateAndSort in '..\Anal3DPredict\SurfLocateAndSort.pas' {LocSortForm},
  RasterPlotUnit in '..\Public\RasterPlotUnit.pas' {RasterForm};

{$R *.RES}

begin
  Application.Initialize;
  Application.Title := 'SurfBawd';
  Application.CreateForm(TSurfBawdForm, SurfBawdForm);
  Application.CreateForm(TLocSortForm, LocSortForm);
  Application.CreateForm(TRasterForm, RasterForm);
  Application.Run;
end.
