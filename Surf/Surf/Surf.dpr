program Surf;

uses
  Forms,
  About in 'ABOUT.PAS' {AboutBox},
  SurfTypes in 'SurfTypes.pas',
  UFFTYPES in 'UFFTYPES.pas',
  DTxPascal in 'DTxPascal.pas',
  ProbeSet in 'ProbeSet.pas' {ProbeSetupWin},
  PahUnit in 'PahUnit.pas',
  ProbeRowFormUnit in 'ProbeRowFormUnit.pas' {ProbeRowForm},
  InfoWinUnit in 'InfoWinUnit.pas' {InfoWin},
  FileProgressUnit in 'FileProgressUnit.pas' {FileProgressWin},
  SurfMessage in 'SurfMessage.pas' {MesgQueryForm},
  NumRecipies in 'NumRecipies.pas',
  EnterExtGain in 'EnterExtGain.pas' {ExtGainForm},
  Exec in 'Exec.pas',
  SurfPublicTypes in '..\Public\SurfPublicTypes.pas',
  WaveFormPlotUnit in '..\Public\WaveFormPlotUnit.pas' {colo},
  ElectrodeTypes in 'ElectrodeTypes.pas',
  VitalSigns in 'VitalSigns.pas' {VitalSignsForm},
  SURFContAcq in 'SURFContAcq.pas' {ContAcqForm},
  HardwareConfig in 'HardwareConfig.pas' {HardwareConfigWin},
  EEGUnit in 'EEGUnit.pas' {EEGWin},
  PolytrodeGUI in '..\SurfBawd\PolytrodeGUI.pas' {PolytrodeGUIForm},
  ChartFormUnit in '..\Public\ChartFormUnit.pas' {ChartWin};

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TContAcqForm, ContAcqForm);
  Application.Run;
end.

