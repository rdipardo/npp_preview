object AboutForm: TAboutForm
  BorderIcons = []
  BorderStyle = bsDialog
  Caption = 'About Preview HTML'
  ClientHeight = 261
  ClientWidth = 372
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  TextHeight = 19
  object lblPlugin: TLabel
    Left = 16
    Top = 8
    Width = 214
    Height = 15
    Caption = 'HTML Preview plugin for Notepad++ %s'
    ShowAccelChar = False
  end
  object lblAuthor: TLabel
    Left = 16
    Top = 33
    Width = 271
    Height = 15
    Caption = ''#169' 2011-2020 Martijn Coppoolse (v1.0.0.4 - v1.3.2.0)'
  end
  object lblBasedOn: TLabel
    Left = 16
    Top = 54
    Width = 212
    Height = 15
    Caption = ''#169' 2025                            (current version)'
  end
  object lblAuthorContact: TLabel
    Left = 61
    Top = 54
    Width = 83
    Height = 15
    Cursor = crHandPoint
    Hint = 'mailto:dipardo.r@gmail.com'
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
    Width = 224
    Height = 15
    Caption = 'Using the Delphi plugin template, '#169' 2008 '
  end
  object lblTributeContact: TLabel
    Left = 240
    Top = 78
    Width = 112
    Height = 15
    Cursor = crHandPoint
    Hint = 'https://github.com/zobo'
    Caption = 'Damjan Zobo Cvetko'
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
    Width = 259
    Height = 15
    Caption = 'Licensed under the GNU General Public License, Version 3 or later'
  end
  object lblFcl: TLabel
    Left = 16
    Top = 120
    Width = 256
    Height = 15
    Caption = 'Also using the Free Component Library (FCL)'
  end
  object lblFclAuthors: TLabel
    Left = 16
    Top = 138
    Width = 256
    Height = 15
    Caption = #169' 1999-2008 the Free Pascal development team'
  end
  object lblFclLicense: TLabel
    Left = 16
    Top = 156
    Width = 256
    Height = 15
    Caption = 'Licensed under the FPC modified LGPL Version 2'
  end
  object btnOK: TButton
    Left = 138
    Top = 224
    Width = 92
    Height = 25
    Cancel = True
    Caption = '&Close'
    Default = True
    ModalResult = 1
    TabOrder = 0
  end
  object lblURL: TLabel
    Left = 16
    Top = 178
    Width = 150
    Height = 15
    Cursor = crHandPoint
    Hint = 'https://github.com/rdipardo/npp_preview'
    Caption = 'View source code on GitHub'
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
    Top = 198
    Width = 207
    Height = 15
    Caption = 'Internet Explorer version %s is installed.'
  end
end
