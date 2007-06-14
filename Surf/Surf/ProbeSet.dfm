�
 TPROBESETUPWIN 0�&  TPF0TProbeSetupWinProbeSetupWinLeft� Top(HorzScrollBar.VisibleVertScrollBar.VisibleBorderIcons
biMinimize
biMaximize BorderStylebsDialogCaptionSURF Probe SetupClientHeight_ClientWidthColorclSilverConstraints.MinHeightzDefaultMonitor
dmMainFormFont.CharsetANSI_CHARSET
Font.ColorclWindowTextFont.Height�	Font.NameArial
Font.Style OldCreateOrder	ShowHint	OnClose	FormCloseOnCreate
FormCreateOnResize
FormResizeOnShowFormShowPixelsPerInch`
TextHeight TLabelLabel22Left� TopWidth{HeightCaptionSpike Epoch Probes:Font.CharsetANSI_CHARSET
Font.ColorclBlueFont.Height�	Font.NameArial
Font.Style 
ParentFont  TLabelLabel2LeftTop$WidthMHeightCaptionEEG Probes:Font.CharsetANSI_CHARSET
Font.ColorclBlueFont.Height�	Font.NameArial
Font.Style 
ParentFont  TLabelLabel5Left�TopWidth_Height HintPDepending on hardware limitations, not every frequency can be achieved precisely	AlignmenttaRightJustifyCaptionBase Sampling Frequency/ChanFont.CharsetANSI_CHARSET
Font.ColorclRedFont.Height�	Font.NameArial
Font.Style 
ParentFontWordWrap	  TLabelLabel10LeftTopWidthRHeightCaptionSpike Probes:Font.CharsetANSI_CHARSET
Font.ColorclBlueFont.Height�	Font.NameArial
Font.Style 
ParentFont  TLabelLabel1LeftzTopWidthHeightCaptionHzFont.CharsetANSI_CHARSET
Font.ColorclRedFont.Height�	Font.NameArial
Font.Style 
ParentFontWordWrap	  	TSpinEditNSpikeProbeSpinLeftTopWidth)HeightHint\Multichannel probes that acquire an epoch of data only if one of its channels pass thresholdAutoSizeEditorEnabledMaxValue MinValue TabOrder Value OnChangeNSpikeProbeSpinChange  TButtonOkButLeft�TopWidthKHeightCaption&OKTabOrderOnClick
OkButClick  TButton	CancelButLeft�TopWidthKHeightCaption&CancelTabOrderOnClickCancelButClick  TButtonCreateProbesLeftPTopWidth_HeightHint&Create the skeleton probe/channel listTabOrderOnClickCreateProbesClick  
TScrollBox	ScrollBoxLeft TopaWidthHeightLVertScrollBar.Tracking	TabOrder TPanelPanelLeft TopWidth�HeightE	AlignmenttaLeftJustify
BevelOuterbvNoneTabOrder    TPanelProbeRowTitlePanelLeftTop>Width Height!	AlignmenttaLeftJustifyUseDockManagerTabOrder TLabelLabel15LeftTopWidth&HeightHint&The identification number of the probeCaptionProbe:Font.CharsetANSI_CHARSET
Font.ColorclRedFont.Height�	Font.NameArial
Font.Style 
ParentFont  TLabelLabel16Left�TopWidth)HeightHint!The internal gain of the A/D cardCaptionIntGainFont.CharsetANSI_CHARSET
Font.ColorclBlueFont.Height�	Font.NameArial
Font.Style 
ParentFont  TLabelLabel17Left� TopWidth/HeightHintRThe threshold point in A/D units at which spikes are detected (n/a for EEG probes)CaptionA/D TrigFont.CharsetANSI_CHARSET
Font.ColorclBlueFont.Height�	Font.NameArial
Font.Style 
ParentFont  TLabelLabel18Left3TopWidth&HeightHintDThe point in the waveform at which the threshold crossing is reachedCaptionTrig PtFont.CharsetANSI_CHARSET
Font.ColorclBlueFont.Height�	Font.NameArial
Font.Style 
ParentFont  TLabelLabel19LeftbTopWidth.HeightHint�The number of sample points after a trigger before which another 
waveform belonging to this probe can be acquired (epoch probes only)CaptionLockoutFont.CharsetANSI_CHARSET
Font.ColorclBlueFont.Height�	Font.NameArial
Font.Style 
ParentFont  TLabelLabel20Left� TopWidth!HeightHint@The length, in sample points, of the displayed/acquired waveformCaptionN PtsFont.CharsetANSI_CHARSET
Font.ColorclBlueFont.Height�	Font.NameArial
Font.Style 
ParentFont  TLabelLabel23LeftTopWidthgHeightHint#A simple description for this probeCaptionProbe DescriptionFont.CharsetANSI_CHARSET
Font.ColorclBlueFont.Height�	Font.NameArial
Font.Style 
ParentFont  TLabelLabel24Left�TopWidth:HeightHintBThe length in ms of the waveforms displayed/acquired by this probe	AlignmenttaCenterCaptionWaveform DurationFont.CharsetANSI_CHARSET
Font.ColorclRedFont.Height�	Font.NameArial
Font.Style 
ParentFontWordWrap	  TLabelLabel25LeftlTopWidth HeightHintNThe number of channels acquired for this probe.
Maximum of one for EEG ProbesCaptionNChsFont.CharsetANSI_CHARSET
Font.ColorclBlueFont.Height�	Font.NameArial
Font.Style 
ParentFontWordWrap	  TLabelLabel26Left�TopWidthHeightHint�The number of times this probe is skipped during acquisition.  This 
effectively decimates the sampling frequency for this probeCaptionSkipFont.CharsetANSI_CHARSET
Font.ColorclBlueFont.Height�	Font.NameArial
Font.Style 
ParentFont  TLabelLabel27Left2TopWidth,HeightHint&The channel at which this probe beginsCaptionChStartFont.CharsetANSI_CHARSET
Font.ColorclBlueFont.Height�	Font.NameArial
Font.Style 
ParentFontWordWrap	  TLabelLabel3Left� TopWidth'HeightHint&The last channel aquired by this probeCaptionChEndFont.CharsetANSI_CHARSET
Font.ColorclBlueFont.Height�	Font.NameArial
Font.Style 
ParentFont  TLabelLabel7LeftTopWidthHeightHint7Check to view this probe's waveforms during acquisitionCaptionViewFont.CharsetANSI_CHARSET
Font.ColorclBlueFont.Height�	Font.NameArial
Font.Style 
ParentFont  TLabelLabel8Left<TopWidthHeightHint3Check to save data from this probe during recordingCaptionSaveFont.CharsetANSI_CHARSET
Font.ColorclBlueFont.Height�	Font.NameArial
Font.Style 
ParentFont  TLabelLabel9Left�TopWidthWHeightHint-A pick list of known electrode configurationsCaptionElectrode TypeFont.CharsetANSI_CHARSET
Font.ColorclBlueFont.Height�	Font.NameArial
Font.Style 
ParentFont  TLabelLabel4Left_TopWidthYHeightHint`Precise sampling frequency per channel for this probe,
including any decimation (given by Skip)	AlignmenttaCenterAutoSizeCaptionSample Freq Per ChannelFont.CharsetANSI_CHARSET
Font.ColorclRedFont.Height�	Font.NameArial
Font.Style 
ParentFontWordWrap	   	TSpinEditNCRProbesSpinLefthTop Width)HeightHintMSingle channel probes that acquire continuously (non-spike, may be decimated)AutoSizeEditorEnabledMaxValue MinValue TabOrderValue OnChangeNCRProbesSpinChange  	TSpinEditSampFreqPerChanLeft8TopWidthAHeightHintPDepending on hardware limitations, not every frequency can be achieved preciselyEnabledFont.CharsetANSI_CHARSET
Font.ColorclWindowTextFont.Height�	Font.NameArial
Font.Style 	Increment�MaxValue`�� MinValue�
ParentFontTabOrderValue�|OnChangeSampFreqPerChanChange  	TCheckBoxDINCheckBoxLeft� Top$Width� Height	AlignmenttaLeftJustifyCaptionAcquire Stimulus DINTabOrderOnClickSampFreqPerChanChange  	TSpinEditNCRSpikeProbeSpinLefthTopWidth)HeightHint3Multichannel spike probes that acquire continuouslyAutoSizeEditorEnabledMaxValue MinValue TabOrder	Value OnChangeNCRSpikeProbeSpinChange  	TGroupBoxgb_HardwareCapsLeft�Top WidthHeight:Caption Hardware resourcesFont.CharsetANSI_CHARSET
Font.ColorclHighlightFont.Height	Font.NameArial
Font.Style 
ParentFontTabOrder
 TLabellb_DINSSLeft� TopWidthHeightCaptionnoneFont.CharsetANSI_CHARSET
Font.ColorclWindowTextFont.Height	Font.NameArial
Font.Style 
ParentFont  TLabelLabel14LeftTop(WidthmHeight	AlignmenttaRightJustifyBiDiModebdLeftToRightCaptionADC bandwidth:   MHzFont.CharsetANSI_CHARSET
Font.ColorclWindowTextFont.Height	Font.NameArial
Font.Style ParentBiDiMode
ParentFont  TLabelLabel12LeftTopWidthMHeight	AlignmenttaRightJustifyBiDiModebdLeftToRightCaptionDT3010 boards:Font.CharsetANSI_CHARSET
Font.ColorclWindowTextFont.Height	Font.NameArial
Font.Style ParentBiDiMode
ParentFont  TLabelLabel13LeftTopWidthDHeight	AlignmenttaRightJustifyBiDiModebdLeftToRightCaptionA/D channels:Font.CharsetANSI_CHARSET
Font.ColorclWindowTextFont.Height	Font.NameArial
Font.Style ParentBiDiMode
ParentFont  TLabelLabel21Left� TopWidthKHeight	AlignmenttaRightJustifyCaptionDIN subsystem:Font.CharsetANSI_CHARSET
Font.ColorclWindowTextFont.Height	Font.NameArial
Font.Style 
ParentFont  TLabelLabel28Left� TopWidthRHeight	AlignmenttaRightJustifyCaptionExperiment timer:Font.CharsetANSI_CHARSET
Font.ColorclWindowTextFont.Height	Font.NameArial
Font.Style 
ParentFont  TLabellb_ADCTotFreqLeft]Top(WidthHeightCaption0Font.CharsetANSI_CHARSET
Font.ColorclWindowTextFont.Height	Font.NameArial
Font.Style 
ParentFont  TLabelLabel29Left� Top(WidthMHeight	AlignmenttaRightJustifyCaptionMUX-80 control:Font.CharsetANSI_CHARSET
Font.ColorclWindowTextFont.Height	Font.NameArial
Font.Style 
ParentFont  TLabel
lb_ADChansLeft]TopWidthHeightCaption0Font.CharsetANSI_CHARSET
Font.ColorclWindowTextFont.Height	Font.NameArial
Font.Style 
ParentFont  TLabellb_NumADBoardsLeft]TopWidthHeightCaption0Font.CharsetANSI_CHARSET
Font.ColorclWindowTextFont.Height	Font.NameArial
Font.Style 
ParentFont  TLabellb_MUXSSLeft� Top(WidthHeightCaptionnoneFont.CharsetANSI_CHARSET
Font.ColorclWindowTextFont.Height	Font.NameArial
Font.Style 
ParentFont  TLabel
lb_TimerSSLeft� TopWidthHeightFont.CharsetANSI_CHARSET
Font.ColorclWindowTextFont.Height	Font.NameArial
Font.Style 
ParentFont    