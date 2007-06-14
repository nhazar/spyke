object DTConfig: TDTConfig
  Left = 301
  Top = 201
  Width = 292
  Height = 265
  Caption = 'DT A/D Config'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object GroupBox1: TGroupBox
    Left = 0
    Top = 0
    Width = 137
    Height = 41
    Caption = 'Board '
    TabOrder = 0
    object ListBox1: TListBox
      Left = 7
      Top = 16
      Width = 122
      Height = 20
      ItemHeight = 15
      Style = lbOwnerDrawFixed
      TabOrder = 0
      OnClick = ListBox1Click
    end
  end
  object RadioGroup1: TRadioGroup
    Left = 0
    Top = 48
    Width = 137
    Height = 49
    Caption = 'Interface Mode '
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ItemIndex = 0
    Items.Strings = (
      'Single Ended'
      'Differential')
    ParentFont = False
    TabOrder = 1
    OnClick = RadioGroup1Click
  end
  object RadioGroup2: TRadioGroup
    Left = 0
    Top = 104
    Width = 137
    Height = 49
    Caption = 'Encoding'
    ItemIndex = 0
    Items.Strings = (
      'Offset Binary'
      '2'#39's Complement')
    TabOrder = 2
    OnClick = RadioGroup2Click
  end
  object GroupBox2: TGroupBox
    Left = 0
    Top = 160
    Width = 137
    Height = 41
    Caption = 'Range'
    TabOrder = 3
    object ListBox2: TListBox
      Left = 7
      Top = 16
      Width = 122
      Height = 20
      ItemHeight = 15
      Style = lbOwnerDrawFixed
      TabOrder = 0
    end
  end
  object GroupBox3: TGroupBox
    Left = 144
    Top = 104
    Width = 137
    Height = 129
    Caption = 'Triggers '
    TabOrder = 4
    object Label1: TLabel
      Left = 6
      Top = 42
      Width = 72
      Height = 13
      Caption = 'Frequency (Hz)'
    end
    object CheckBox1: TCheckBox
      Left = 5
      Top = 19
      Width = 129
      Height = 17
      Caption = 'Enable Triggered Scan'
      Checked = True
      State = cbChecked
      TabOrder = 0
      OnClick = CheckBox1Click
    end
    object Edit1: TEdit
      Left = 82
      Top = 39
      Width = 47
      Height = 21
      TabOrder = 1
      Text = '50000'
      OnChange = Edit1Change
    end
    object RadioGroup4: TRadioGroup
      Left = 7
      Top = 71
      Width = 121
      Height = 49
      Caption = 'Source '
      ItemIndex = 0
      Items.Strings = (
        'Internal'
        'External')
      TabOrder = 2
      OnClick = RadioGroup4Click
    end
  end
  object Button1: TButton
    Left = 2
    Top = 206
    Width = 65
    Height = 27
    Caption = 'Config'
    TabOrder = 5
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 72
    Top = 206
    Width = 65
    Height = 27
    Caption = 'Quit'
    TabOrder = 6
    OnClick = Button2Click
  end
  object GroupBox4: TGroupBox
    Left = 144
    Top = 0
    Width = 137
    Height = 97
    Caption = 'Clocks '
    TabOrder = 7
    object Label2: TLabel
      Left = 5
      Top = 71
      Width = 72
      Height = 13
      Caption = 'Frequency (Hz)'
    end
    object Edit2: TEdit
      Left = 79
      Top = 68
      Width = 50
      Height = 21
      TabOrder = 0
      Text = '1000000'
      OnChange = Edit2Change
    end
    object RadioGroup3: TRadioGroup
      Left = 7
      Top = 13
      Width = 122
      Height = 49
      Caption = 'Source '
      ItemIndex = 0
      Items.Strings = (
        'Internal'
        'External')
      TabOrder = 1
      OnClick = RadioGroup3Click
    end
  end
end
