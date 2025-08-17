object AboutForm: TAboutForm
  Left = 0
  Top = 0
  BorderIcons = []
  BorderStyle = bsDialog
  Caption = 'About Preview HTML'
  ClientHeight = 315
  ClientWidth = 372
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  TextHeight = 15
  object lblPlugin: TLabel
    Left = 16
    Top = 8
    Width = 215
    Height = 15
    Caption = 'HTML Preview plugin for Notepad++ %s'
    ShowAccelChar = False
  end
  object lblAuthor: TLabel
    Left = 16
    Top = 33
    Width = 268
    Height = 15
    Caption = #169' 2011-2020 Martijn Coppoolse (v1.0.0.4 - v1.3.2.0)'
  end
  object lblBasedOn: TLabel
    Left = 16
    Top = 54
    Width = 206
    Height = 15
    Caption = #169' 2025                           (current version)'
  end
  object lblAuthorContact: TLabel
    Left = 60
    Top = 54
    Width = 83
    Height = 15
    Cursor = crHandPoint
    Hint = 'https://github.com/rdipardo'
    Caption = 'Robert Di Pardo'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clHotLight
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = [fsUnderline]
    ParentFont = False
    OnClick = lblLinkClick
  end
  object lblTribute: TLabel
    Left = 16
    Top = 78
    Width = 298
    Height = 15
    Caption = 'Based on                         '#39's plugin template, GPLv3 License'
  end
  object lblTributeContact: TLabel
    Left = 68
    Top = 78
    Width = 81
    Height = 15
    Cursor = crHandPoint
    Hint = 'https://github.com/zobo'
    Caption = 'Damjan Cvetko'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clHotLight
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = [fsUnderline]
    ParentFont = False
    OnClick = lblLinkClick
  end
  object lblLicense: TLabel
    Left = 16
    Top = 96
    Width = 340
    Height = 15
    Caption = 'Using WebView4Delphi, '#169' 2025 Salvador D'#237'az Fau, MIT License'
  end
  object lblFcl: TLabel
    Left = 16
    Top = 120
    Width = 237
    Height = 15
    Caption = 'Also using the Free Component Library (FCL)'
  end
  object lblFclAuthors: TLabel
    Left = 16
    Top = 138
    Width = 251
    Height = 15
    Caption = #169' 1999-2008 the Free Pascal development team'
  end
  object lblFclLicense: TLabel
    Left = 16
    Top = 156
    Width = 255
    Height = 15
    Caption = 'Licensed under the FPC modified LGPL Version 2'
  end
  object lblURL: TLabel
    Left = 16
    Top = 242
    Width = 68
    Height = 15
    Cursor = crHandPoint
    Hint = 'https://github.com/rdipardo/npp_preview/issues'
    Caption = 'Report a bug'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clHotLight
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = [fsUnderline]
    ParentFont = False
    OnClick = lblLinkClick
  end
  object lblIEVersion: TLabel
    Left = 16
    Top = 222
    Width = 258
    Height = 15
    Caption = 'Microsoft Edge WebView2 version %s is installed.'
  end
  object lblWebView: TLabel
    Left = 16
    Top = 182
    Width = 235
    Height = 30
    Caption = 'Also using'#13#10#169' 2020 John Chadwick, ISC License'
  end
  object lblWebViewLicense: TLabel
    Left = 76
    Top = 182
    Width = 136
    Height = 15
    Cursor = crHandPoint
    Hint = 'https://github.com/jchv/OpenWebView2Loader'
    Caption = 'OpenWebView2Loader'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clHotLight
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = [fsUnderline]
    ParentFont = False
    OnClick = lblLinkClick
  end
  object btnOK: TButton
    Left = 138
    Top = 272
    Width = 92
    Height = 25
    Cancel = True
    Caption = '&Close'
    Default = True
    ModalResult = 1
    TabOrder = 0
  end
end
