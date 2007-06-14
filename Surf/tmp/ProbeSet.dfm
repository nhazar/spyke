�
 TPROBEWIN 0�  TPF0	TProbeWinProbeWinLeft� Top�HorzScrollBar.VisibleVertScrollBar.VisibleBorderIcons
biMinimize
biMaximize BorderStylebsSingleCaptionSURF Probe SetupClientHeight� ClientWidth�ColorclSilverFont.CharsetANSI_CHARSET
Font.ColorclWindowTextFont.Height�	Font.NameArial
Font.Style OldCreateOrder	ShowHint	OnCreate
FormCreate	OnDestroyFormDestroyOnHideFormHideOnResize
FormResizeOnShowFormShowPixelsPerInch`
TextHeight TLabelLabel22LeftTopWidth� HeightCaptionNumber of Spike Probes:Font.CharsetANSI_CHARSET
Font.ColorclBlueFont.Height�	Font.NameArial
Font.Style 
ParentFont  TLabelLabel11LeftgTop&Width� HeightHintwThe threshold point in A.D values at which spikes (if polytrode) are triggerred (set to zero for continuous acquisitionCaptionTotal Board Frequency:Font.CharsetANSI_CHARSET
Font.ColorclRedFont.Height�	Font.NameArial
Font.Style 
ParentFontWordWrap	  TLabelLabel1Left6Top#WidthHeightAutoSizeCaptionHzFont.CharsetANSI_CHARSET
Font.ColorclRedFont.Height�	Font.NameArial
Font.Style 
ParentFont  TLabelLabel2LeftTop$Width� HeightCaptionNumber of CR Probes:Font.CharsetANSI_CHARSET
Font.ColorclBlueFont.Height�	Font.NameArial
Font.Style 
ParentFont  TLabelLabel5LeftDTop
Width� HeightHintwThe threshold point in A.D values at which spikes (if polytrode) are triggerred (set to zero for continuous acquisitionCaptionSamp Freq Per Spike Chan:Font.CharsetANSI_CHARSET
Font.ColorclRedFont.Height�	Font.NameArial
Font.Style 
ParentFontWordWrap	  TLabelLabel6Left6Top	WidthHeightAutoSizeCaptionHzFont.CharsetANSI_CHARSET
Font.ColorclRedFont.Height�	Font.NameArial
Font.Style 
ParentFont  	TSpinEditNSpikeProbeSpinLeft� Top Width)HeightHintWThe number of probes which acquire only if one of its member channels passes threshold.AutoSizeEditorEnabledMaxValue MinValue TabOrder Value   TButtonOkButLeftYTop WidthKHeightCaption&OKTabOrderOnClick
OkButClick  TButton	CancelButLeftYTopWidthKHeightCaption&CancelTabOrderOnClickCancelButClick  TButtonCreateProbesLeft� TopWidthcHeightHint'Create the skeleton probe/channel list.CaptionC&reate ProbesTabOrderOnClickCreateProbesClick  
TScrollBox	ScrollBoxLeft Top`Width�HeightLVertScrollBar.Tracking	TabOrder TPanelPanelLeft TopWidth�HeightE	AlignmenttaLeftJustify
BevelOuterbvNoneTabOrder    TPanelPanel1LeftTop=Width�Height!	AlignmenttaLeftJustifyUseDockManagerTabOrder TLabelLabel15LeftTopWidth&HeightHint&The identification number of the probeCaptionProbe:Font.CharsetANSI_CHARSET
Font.ColorclRedFont.Height�	Font.NameArial
Font.Style 
ParentFont  TLabelLabel16Left�TopWidth)HeightHint"The internal gain of the A/D card.CaptionIntGainFont.CharsetANSI_CHARSET
Font.ColorclBlueFont.Height�	Font.NameArial
Font.Style 
ParentFont  TLabelLabel17Left� TopWidth/HeightHintjThe threshold point in A.D values at which spikes are triggerred (set to zero for continuous acquisition).CaptionA/D TrigFont.CharsetANSI_CHARSET
Font.ColorclBlueFont.Height�	Font.NameArial
Font.Style 
ParentFont  TLabelLabel18Left3TopWidth&HeightHintEThe point in the waveform at which the threshold crossing is reached.CaptionTrig PtFont.CharsetANSI_CHARSET
Font.ColorclBlueFont.Height�	Font.NameArial
Font.Style 
ParentFont  TLabelLabel19LeftaTopWidth.HeightHintyThe number of points after the threshold crossing after which another 
waveform belonging to this probe can be acquired.CaptionLockoutFont.CharsetANSI_CHARSET
Font.ColorclBlueFont.Height�	Font.NameArial
Font.Style 
ParentFont  TLabelLabel20Left� TopWidth!HeightHint8The length, in points, of the acquired wave per channel.CaptionN PtsFont.CharsetANSI_CHARSET
Font.ColorclBlueFont.Height�	Font.NameArial
Font.Style 
ParentFont  TLabelLabel23LeftTopWidthgHeightHint$A simple description for this probe.CaptionProbe DescriptionFont.CharsetANSI_CHARSET
Font.ColorclBlueFont.Height�	Font.NameArial
Font.Style 
ParentFont  TLabelLabel24LeftcTopWidth:HeightHint9The length in ms of the waveforms acquired by this probe.CaptionWaveform DurationFont.CharsetANSI_CHARSET
Font.ColorclRedFont.Height�	Font.NameArial
Font.Style 
ParentFontWordWrap	  TLabelLabel25LeftlTopWidth HeightHintIThe number of channels acquired for this probe.
Maximum=1 for CR Probes.CaptionNChsFont.CharsetANSI_CHARSET
Font.ColorclBlueFont.Height�	Font.NameArial
Font.Style 
ParentFontWordWrap	  TLabelLabel26Left�TopWidthHeightHint�The number of times this probe is skipped during acquisition.  This is the 
divisor when calculating the sampling frequency for this probeCaptionSkipFont.CharsetANSI_CHARSET
Font.ColorclBlueFont.Height�	Font.NameArial
Font.Style 
ParentFont  TLabelLabel27Left2TopWidth,HeightHint'The channel at which this probe begins.CaptionChStartFont.CharsetANSI_CHARSET
Font.ColorclBlueFont.Height�	Font.NameArial
Font.Style 
ParentFontWordWrap	  TLabelLabel3Left� TopWidth'HeightHint'The last channel aquired by this probe.CaptionChEndFont.CharsetANSI_CHARSET
Font.ColorclBlueFont.Height�	Font.NameArial
Font.Style 
ParentFont  TLabelLabel4Left	TopWidth@HeightHint9The length in ms of the waveforms acquired by this probe.CaptionSamp Freq Per ChanFont.CharsetANSI_CHARSET
Font.ColorclRedFont.Height�	Font.NameArial
Font.Style 
ParentFontWordWrap	  TLabelLabel7Left�TopWidthHeightHint�The number of times this probe is skipped during acquisition.  This is the 
divisor when calculating the sampling frequency for this probeCaptionViewFont.CharsetANSI_CHARSET
Font.ColorclBlueFont.Height�	Font.NameArial
Font.Style 
ParentFont  TLabelLabel8Left�TopWidthHeightHint�The number of times this probe is skipped during acquisition.  This is the 
divisor when calculating the sampling frequency for this probeCaptionSaveFont.CharsetANSI_CHARSET
Font.ColorclBlueFont.Height�	Font.NameArial
Font.Style 
ParentFont   	TSpinEditNCRProbesSpinLeft� TopWidth)HeightHintKThe number of probes which continuously acquire on all its member channels.AutoSizeEditorEnabledMaxValue MinValue TabOrderValue   	TSpinEditTotFreqLeft�Top WidthAHeightEnabledFont.CharsetANSI_CHARSET
Font.ColorclWindowTextFont.Height�	Font.NameArial
Font.Style 	Increment
MaxValue� MinValue 
ParentFontTabOrderValue�|OnChangeTotFreqChange  	TSpinEditSampFreqPerChanLeft�TopWidthAHeightEnabledFont.CharsetANSI_CHARSET
Font.ColorclWindowTextFont.Height�	Font.NameArial
Font.Style 	Increment
MaxValue`�� MinValue
ParentFontTabOrderValue�|OnChangeSampFreqPerChanChange  	TCheckBoxDinCheckBoxLeftZTop	Width� HeightCaptionCapture Digital PortsTabOrder	OnClickDinCheckBoxClick   