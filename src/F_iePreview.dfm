object frmIEPreview: TFrmIEPreview
  Left = 0
  Top = 0
  BorderStyle = bsSizeToolWin
  Caption = 'HTML preview'
  ClientHeight = 420
  ClientWidth = 504
  Color = clBtnFace
  ParentFont = True
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnHide = FormHide
  OnKeyPress = FormKeyPress
  OnShow = FormShow
  TextHeight = 25
  object pnlButtons: TPanel
    Left = 0
    Top = 364
    Width = 504
    Height = 56
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 0
    DesignSize = (
      504
      56)
    object btnRefresh: TButton
      Left = 8
      Top = 6
      Width = 75
      Height = 25
      Caption = '&Refresh'
      TabOrder = 0
      OnClick = btnRefreshClick
    end
    object btnClose: TButton
      Left = 410
      Top = 6
      Width = 75
      Height = 25
      Anchors = [akTop, akRight]
      Caption = 'Close'
      TabOrder = 4
      OnClick = btnCloseClick
    end
    object sbrIE: TStatusBar
      AlignWithMargins = True
      Left = 3
      Top = 34
      Width = 498
      Height = 19
      Panels = <>
      ExplicitTop = 42
      ExplicitWidth = 484
    end
    object btnAbout: TBitBtn
      Left = 347
      Top = 6
      Width = 58
      Height = 25
      Hint = 'About|About this plugin'
      Anchors = [akTop, akRight]
      Kind = bkHelp
      ParentShowHint = False
      ShowHint = True
      Spacing = 0
      Margin = 6
      TabOrder = 2
      OnClick = btnAboutClick
    end
    object chkFreeze: TCheckBox
      Left = 89
      Top = 10
      Width = 50
      Height = 17
      Caption = '&Freeze'
      TabOrder = 1
      OnClick = chkFreezeClick
    end
  end
  object pnlPreview: TPanel
    Left = 0
    Top = 0
    Width = 504
    Height = 364
    Align = alClient
    BevelOuter = bvNone
    Caption = '(no preview available)'
    TabOrder = 1
    ExplicitWidth = 490
    ExplicitHeight = 327
    object pnlHTML: TPanel
      Left = 0
      Top = 0
      Width = 504
      Height = 364
      Align = alClient
      BevelOuter = bvNone
      Caption = 'pnlHTML'
      TabOrder = 0
      ExplicitWidth = 490
      ExplicitHeight = 327
      object wbIE: TWebBrowser
        Left = 0
        Top = 0
        Width = 504
        Height = 364
        TabStop = False
        Align = alClient
        TabOrder = 0
        OnStatusTextChange = wbIEStatusTextChange
        OnTitleChange = wbIETitleChange
        OnBeforeNavigate2 = wbIEBeforeNavigate2
        OnDocumentComplete = wbIEDocumentComplete
        OnStatusBar = wbIEStatusBar
        OnNewWindow3 = wbIENewWindow3
        ExplicitWidth = 490
        ExplicitHeight = 327
        ControlData = {
          4C000000BA220000151900000000000000000000000000000000000000000000
          000000004C000000000000000000000001000000E0D057007335CF11AE690800
          2B2E12620B000000000000004C0000000114020000000000C000000000000046
          8000000000000000000000000000000000000000000000000000000000000000
          00000000000000000100000000000000000000000000000000000000}
      end
    end
  end
  object tmrAutorefresh: TTimer
    Enabled = False
    OnTimer = tmrAutorefreshTimer
    Left = 448
    Top = 16
  end
end
