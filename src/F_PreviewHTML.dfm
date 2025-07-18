object frmHTMLPreview: TfrmHTMLPreview
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
  TextHeight = 15
  object pnlButtons: TPanel
    Left = 0
    Top = 364
    Width = 504
    Height = 56
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    ExplicitTop = 347
    ExplicitWidth = 498
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
      Left = 404
      Top = 6
      Width = 75
      Height = 25
      Anchors = [akTop, akRight]
      Caption = 'Close'
      TabOrder = 4
      OnClick = btnCloseClick
      ExplicitLeft = 398
    end
    object sbrIE: TStatusBar
      AlignWithMargins = True
      Left = 3
      Top = 34
      Width = 498
      Height = 19
      Panels = <>
      ExplicitWidth = 492
    end
    object btnAbout: TButton
      Left = 366
      Top = 6
      Width = 25
      Height = 25
      Hint = 'About|About this plugin'
      Anchors = [akTop, akRight]
      Caption = '?'
      TabOrder = 2
      OnClick = btnAboutClick
      ExplicitLeft = 360
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
  object wbHost: TWVWindowParent
    Left = 0
    Top = 0
    Width = 504
    Height = 364
    Align = alClient
    TabOrder = 0
    Browser = wbIE
    ExplicitWidth = 498
    ExplicitHeight = 347
  end
  object wbIE: TWVBrowser
    DefaultURL = 'about:blank'
    TargetCompatibleBrowserVersion = '95.0.1020.44'
    AllowSingleSignOnUsingOSPrimaryAccount = False
    OnInitializationError = wbIEInitializationError
    OnAfterCreated = wbIEAfterCreated
    OnDocumentTitleChanged = wbIETitleChange
    OnStatusBarTextChanged = wbIEStatusBar
    OnExecuteScriptWithResultCompleted = wbIEExecuteScriptWithResultCompleted
    Left = 8
    Top = 8
  end
  object tmrAutorefresh: TTimer
    Enabled = False
    OnTimer = tmrAutorefreshTimer
    Left = 448
    Top = 16
  end
end
