object WaveFormPlotForm: TWaveFormPlotForm
  Left = 879
  Top = 158
  Anchors = []
  AutoSize = True
  BorderIcons = []
  BorderStyle = bsToolWindow
  Caption = 'WaveForm Plot Window'
  ClientHeight = 30
  ClientWidth = 197
  Color = clBlack
  Constraints.MaxWidth = 600
  DefaultMonitor = dmMainForm
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clYellow
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  PopupMenu = Menu
  Position = poDefault
  Visible = True
  OnCreate = FormCreate
  OnDblClick = FormDblClick
  OnHide = FormHide
  OnMouseDown = FormMouseDown
  OnMouseMove = FormMouseMove
  OnMouseUp = FormMouseUp
  OnPaint = FormPaint
  PixelsPerInch = 96
  TextHeight = 13
  object tbControl: TToolBar
    Left = 0
    Top = 0
    Width = 197
    Height = 30
    AutoSize = True
    ButtonHeight = 26
    ButtonWidth = 27
    Color = clSilver
    EdgeBorders = [ebTop, ebBottom]
    EdgeOuter = esNone
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    Images = tbImages
    ParentColor = False
    ParentFont = False
    TabOrder = 0
    Wrapable = False
    object tbOverlay: TToolButton
      Left = 0
      Top = 2
      Hint = 'Overlay'
      Caption = 'tbOverlay'
      ImageIndex = 0
      ParentShowHint = False
      ShowHint = True
      Style = tbsCheck
      OnClick = tbOverlayClick
    end
    object tbTrigger: TToolButton
      Left = 27
      Top = 2
      Hint = 'Trigger line'
      Caption = 'tbTrigger'
      Down = True
      ImageIndex = 1
      ParentShowHint = False
      ShowHint = True
      Style = tbsCheck
    end
    object tbZeroLine: TToolButton
      Left = 54
      Top = 2
      Hint = 'Zero line'
      Caption = 'tbZeroLine'
      Down = True
      ImageIndex = 2
      ParentShowHint = False
      ShowHint = True
      Style = tbsCheck
    end
    object spacer: TToolButton
      Left = 81
      Top = 2
      Width = 4
      ImageIndex = 3
      Style = tbsSeparator
    end
    object seThreshold: TSpinEdit
      Left = 85
      Top = 2
      Width = 55
      Height = 26
      Hint = 'Threshold'
      AutoSize = False
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -14
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      Increment = 5
      MaxValue = 2047
      MinValue = -2048
      ParentFont = False
      ParentShowHint = False
      ShowHint = True
      TabOrder = 0
      Value = 500
      OnChange = seThresholdChange
    end
    object CBZoom: TComboBox
      Left = 140
      Top = 3
      Width = 57
      Height = 24
      Hint = 'Zoom'
      Style = csDropDownList
      BiDiMode = bdLeftToRight
      DropDownCount = 7
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -14
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ItemHeight = 16
      ParentBiDiMode = False
      ParentFont = False
      ParentShowHint = False
      ShowHint = True
      TabOrder = 1
      OnChange = CBZoomChange
      Items.Strings = (
        '500%'
        '200%'
        '150%'
        '100%'
        '75%'
        '50%'
        '10%')
    end
  end
  object tbImages: TImageList
    Height = 20
    Width = 20
    Left = 16
    Top = 9
    Bitmap = {
      494C010103000400040014001400FFFFFFFFFF10FFFFFFFFFFFFFFFF424D3600
      0000000000003600000028000000500000001400000001002000000000000019
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000080808000808080000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000080808000808080000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000FF0000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000080808000808080000000
      00000000000000FF000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000FF0000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000FF00000000000000FF00000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000080808000808080000000
      000000FF00000000000000FF0000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000FF00000000000000FF00000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000FF00000000000000FF00000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000080808000808080000000
      000000FF00000000000000FF0000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000FF00000000000000FF00000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000000000000000000000FF
      00000000000000000000000000000000000000FF0000000000000000000000FF
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000FF00000000000080808000808080000000
      000000FF0000000000000000000000FF00000000000000000000000000000000
      00000000000000000000000000000000000000000000000000000000000000FF
      00000000000000000000000000000000000000FF0000000000000000000000FF
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000000000000000FF000000FF
      000000FF000000000000000000000000000000FF000000000000000000000000
      000000FF000000000000000000000000000000FF000000FF000000FF00000000
      0000000000000000000000FF000000FF000000FF000080808000808080000000
      000000FF000000000000000000000000000000FF000000000000000000000000
      000000FF000000FF000000FF000000000000000000000000000000FF000000FF
      000000FF000000000000000000000000000000FF000000000000000000000000
      000000FF000000000000000000000000000000FF000000FF000000FF00000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000FF000000FF00000000
      000000FF0000000000000000000000FF00000000000000000000000000000000
      000000FF0000000000000000000000FF0000FFFF0000000000000000000000FF
      00000000000000FF000000FF00000000000000FF0000808080008080800000FF
      00000000000000000000000000000000000000FF0000000000000000000000FF
      000000000000000000000000000000FF00000000000000FF000000FF00000000
      000000FF0000000000000000000000FF00000000000000000000000000000000
      000000FF0000000000000000000000FF000000000000000000000000000000FF
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000FF000000FF0000000000000000
      000000FF0000FFFF0000FFFF000000FF0000000000000000FF000000FF000000
      FF00FFFF000000FF000000FF00000000000000000000FFFF0000000000000000
      000000FF000000FF0000000000000000000000FF0000808080008080800000FF
      0000000000000000000000000000000000000000000000FF000000FF00000000
      00000000000000000000000000000000000000FF000000FF0000000000000000
      000000FF0000000000000000000000FF00000000000000000000000000000000
      00000000000000FF000000FF0000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000FF000000FF00FFFF0000FFFF
      000000FF0000000000000000000000FF00000000FF0000000000000000000000
      00000000FF000000FF00FFFF00000000000000000000FFFF0000FFFF0000FFFF
      00000000000000000000000000000000000000FF0000808080008080800000FF
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000008080800080808000808080008080
      800000FF0000808080008080800000FF00008080800080808000808080008080
      8000808080008080800080808000808080008080800080808000808080008080
      8000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000000000FF00000000000000
      000000FF0000000000000000000000FF0000FFFF00000000000000000000FFFF
      0000000000000000FF000000FF0000000000000000000000FF000000FF000000
      FF000000000000000000000000000000000000FF0000808080008080800000FF
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000FF0000000000000000000000FF00000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000000000FF00000000000000
      00000000000000FF00000000FF0000FF0000FFFF00000000000000000000FFFF
      00000000000000000000000000000000FF000000FF0000000000000000000000
      00000000000000000000000000000000000000000000808080008080800000FF
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000FF00000000000000FF00000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000000000000000FF000000
      00000000000000FF00000000000000FF0000FFFF00000000000000000000FFFF
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000808080008080800000FF
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000FF00000000000000FF00000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000000000000000FF000000
      00000000FF0000FF000000FF000000FF0000FFFF00000000000000000000FFFF
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000008080800000FF000000FF
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000FF000000FF000000FF00000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      FF000000000000FF000000FF000000FF000000000000FFFF000000000000FFFF
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000008080800000FF000000FF
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000FF000000FF000000FF00000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000FF000000FF00000000000000000000FFFF0000FFFF00000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000008080800000FF00000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000FF000000FF0000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000FF00000000000000000000FFFF0000FFFF00000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000008080800000FF00000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000FF0000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000FF00000000000000000000FFFF0000FFFF00000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000008080800000FF00000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000FF0000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000FF0000000000000000000000000000FFFF00000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000008080800000FF00000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000FF0000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000FF0000000000000000000000000000FFFF00000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000008080800000FF00000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000FF0000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000424D3E000000000000003E000000
      2800000050000000140000000100010000000000F00000000000000000000000
      000000000000000000000000FFFFFF0000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000}
  end
  object Menu: TPopupMenu
    Left = 48
    Top = 9
    object muOverlay: TMenuItem
      Caption = 'Overlay'
      OnClick = muOverlayClick
    end
    object muFreeze: TMenuItem
      Caption = 'Freeze'
      OnClick = FormDblClick
    end
    object muContDisp: TMenuItem
      Caption = 'Continuous'
      OnClick = muContDispClick
    end
    object muBipolarTrig: TMenuItem
      Caption = 'Bipolar Trigger'
      OnClick = muBipolarTrigClick
    end
    object N2: TMenuItem
      Caption = '-'
    end
    object muPolytrodeGUI: TMenuItem
      Caption = 'Polytrode GUI'
      OnClick = muPolytrodeGUIClick
    end
    object muAutoMUX: TMenuItem
      Caption = 'AutoMonitor'
      OnClick = muAutoMUXClick
    end
    object N1: TMenuItem
      Caption = '-'
    end
    object muProperties: TMenuItem
      Caption = 'Properties'
      Enabled = False
    end
  end
end