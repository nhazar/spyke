�
 TSURFSORTFORM 0�  TPF0TSurfSortFormSurfSortFormLeft6Top� WidthLHeight8Caption	SURF SORTColor	clBtnFaceFont.CharsetDEFAULT_CHARSET
Font.ColorclWindowTextFont.Height�	Font.NameArial
Font.Style Menu	MainMenu1OldCreateOrder	OnCreate
FormCreatePixelsPerInch`
TextHeight TGaugeGuageLeft Top� WidthDHeightAlignalBottom	ForeColorclBlueProgress   TLabelLabel4LeftTopWidth'HeightCaptionNSpikes  TLabelnspikesLeft;TopWidthHeightCaption0  TLabelLabel7LeftTopWidthHeightCaptionTime  TLabeltimeLeft*TopWidthHeightCaption0  TLabelLabel1Left�Top�WidthHeight  
TStatusBar	StatusBarLeft Top� WidthDHeightAutoHint	Panels SimplePanel	  TButton
StopButtonLeftTopWidth<HeightCaptionSTOPTabOrderOnClickStopButtonClick  	TCheckBoxPauseLeft� Top+WidthAHeightCaptionPauseTabOrder  	TCheckBoxDisplayLeft Top/WidthpHeightCaptionDisplay WaveformsChecked	State	cbCheckedTabOrder  TPanel	WaveFormsLeft Top� WidthDHeight7AlignalBottomAnchorsakLeftakTopakRightakBottom TabOrder  	TSpinEditExtGainLeft� TopWidth<HeightHintThreshold in A/D Units	IncrementdMaxValue NMinValuedTabOrderValue'  TStaticTextStaticText3Left� Top�Width,HeightCaptionExt GainTabOrder  TButtonStepLeftTop3Width=HeightCaptionStepTabOrderOnClick	StepClick  TStaticTextLabel2Left�Top)WidthHeightCaptionm=TabOrder  TEditemLeft�Top(WidthHeightImeModeimAlphaTabOrder	Text25  	TComboBoxElectrodePickLeft� TopWidthPHeight
ItemHeightTabOrder
Text	PTRODE16a  TEditevoLeft�TopWidth'HeightImeModeimAlphaTabOrderText10000  TStaticTextStaticText1Left�TopWidthHeightCaptionp=TabOrder  	TCheckBoxLockVoLeft�TopWidth/HeightCaptionLockChecked	State	cbCheckedTabOrder  	TCheckBoxLockMLeft�Top(Width/HeightCaptionLockChecked	State	cbCheckedTabOrder  TRadioGroupFunctionNumLeftTopXWidthiHeightQCaptionFunctionFont.CharsetANSI_CHARSET
Font.ColorclWindowTextFont.Height�	Font.NameCourier New
Font.Style 	ItemIndex Items.Strings$Inv    : Vr = 1/4PI * Vo / ((d+o)/m)Exp    : Vr = Vo * e^(-(d+o)/m))Gaus   : Vr = Vo * e^(-0.5*((d+do)/m)^2) Tim's function 
ParentFontTabOrderOnClickFunctionNumClick  	TSurfAnalSurfAnalLeft�Top,WidthPHeightCaptionSURF AnalysisColor�y( Font.CharsetDEFAULT_CHARSET
Font.ColorclWhiteFont.Height�	Font.NameMS Sans Serif
Font.Style 
ParentFontTabOrder
OnSurfFileSurfAnalSurfFile  	TCheckBoxLockOLeft�Top=Width0HeightCaptionLockChecked	State	cbCheckedTabOrder  TEditeoLeft�Top=WidthHeightImeModeimAlphaTabOrderText10  TStaticTextStaticText2Left�Top>WidthHeightCaptionoff=TabOrder  	TCheckBoxLockZLeft�TopWidth/HeightCaptionLockTabOrder  TEditEzLeft�Top�WidthHeightImeModeimAlphaTabOrderText30  TStaticTextStaticText4Left�Top WidthHeightCaptionz=TabOrder  TButton
BLastSpikeLeftFTop3Width;HeightCaption
Last SpikeTabOrderOnClickBLastSpikeClick  TButtonBRepeatFileLeftFTopWidthAHeightCaptionRepeat FileTabOrderOnClickBRepeatFileClick  	TCheckBoxCWaveFormNormalizeLeft TopWidth� HeightCaptionWaveform NormalizeTabOrder  TButtonBDumpWaveformsLeft TopBWidthiHeightCaptionDump WaveformsTabOrderOnClickBDumpWaveformsClick  	TCheckBox	CDumpTextLeft�TopxWidthKHeightHint%Save data to text file "datafile.txt"Caption	Dump textFont.CharsetDEFAULT_CHARSET
Font.ColorclWindowTextFont.Height�	Font.NameArial
Font.Style 
ParentFontTabOrder  	TMainMenu	MainMenu1Left&Top 	TMenuItemFile1Caption&FileHintFile related commands 	TMenuItemFileOpenItemCaption&OpenHintOpen|Open a file
ImageIndexShortCutO@OnClickFileOpen1Execute  	TMenuItemFileSaveAsItemCaptionSave &As...Hint-Save As|Save current file with different nameOnClickFileSave1Execute  	TMenuItemN1Caption-  	TMenuItemFileExitItemCaptionE&xitHintExit|Exit applicationOnClickFileExit1Execute   	TMenuItemEdit1Caption&EditHintEdit commands 	TMenuItemCutItemCaptionCu&tHint3Cut|Cuts the selection and puts it on the Clipboard
ImageIndex ShortCutX@  	TMenuItemCopyItemCaption&CopyHint6Copy|Copies the selection and puts it on the Clipboard
ImageIndexShortCutC@  	TMenuItem	PasteItemCaption&PasteHint Paste|Inserts Clipboard contents
ImageIndexShortCutV@   	TMenuItemHelp1Caption&HelpHintHelp topics 	TMenuItemHelpAboutItemCaption	&About...HintAAbout|Displays program information, version number, and copyrightOnClickHelpAbout1Execute    TOpenDialog
OpenDialogFilterAll Files (*.*)|*.*LeftTop  TSaveDialog
SaveDialogFilterAll Files (*.*)|*.*Left�Top   