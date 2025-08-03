unit F_About;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, NppForms, StdCtrls, ExtCtrls;

type
  TAboutForm = class(TNppForm)
    btnOK: TButton;
    lblBasedOn: TLabel;
    lblTribute, lblTributeContact: TLabel;
    lblPlugin: TLabel;
    lblAuthor, lblAuthorContact: TLabel;
    lblFcl, lblFclAuthors, lblLicense, lblFclLicense: TLabel;
    lblURL: TLabel;
    lblIEVersion: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure lblLinkClick(Sender: TObject);
  private
    { Private declarations }
    FVersionStr: string;
  public
    { Public declarations }
    procedure ToggleDarkMode; override;
  end;

function IsAtLeastWindows11(var WinVerMajor, WinVerMinor, BuildNr: DWORD): Boolean;

var
  AboutForm: TAboutForm;

implementation
uses
  ShellAPI, StrUtils,
  IdURI,
  VersionInfo, ModulePath, WebBrowser,
  NppPlugin;

{$R *.dfm}

procedure RtlGetNtVersionNumbers(var Maj, Min, Build: DWORD); stdcall;
  external 'ntdll.dll' Name 'RtlGetNtVersionNumbers';

function IsAtLeastWindows11(var WinVerMajor, WinVerMinor, BuildNr: DWORD): Boolean;
const
  BuildNrMask: DWORD = $F0000000;
begin
  WinVerMajor := 0; WinVerMinor := 0; BuildNr := 0;
  RtlGetNtVersionNumbers(WinVerMajor, WinVerMinor, BuildNr);
  BuildNr := BuildNr and (not BuildNrMask);
  Result := (WinVerMajor > 10) or ((WinVerMajor = 10) and (BuildNr >= 22000));
end;

{ ------------------------------------------------------------------------------------------------ }
procedure TAboutForm.FormCreate(Sender: TObject);
var
  WinVerMajor, WinVerMinor, BuildNr: DWORD;
begin
  btnOK.Left := ((Self.Width div 2) - (btnOK.Width div 2) - 12);
  IsAtLeastWindows11(WinVerMajor, WinVerMinor, BuildNr);
  // Older than Win11 ?
  if (WinVerMajor < 10) or (BuildNr < 22000) then
  begin
    with lblAuthorContact do
    begin
      Font.Height := -11;
      // Newer than Win7 ?
      if (BuildNr >= 9200) then
      begin
        Font.Name := 'Tahoma';
        Left := Left - 3;
      end;
    end;
    with lblTributeContact do
    begin
      Font.Height := -11;
      if (BuildNr >= 9200) then
      begin
        Font.Name := 'Tahoma';
        Left := Left - 2;
      end else begin
        Left := Left + 5;
        lblLicense.Font.Height := -11;
        lblFclLicense.Font.Height := -11;
      end;
    end;
  end;

 with TFileVersionInfo.Create(TModulePath.DLLFullName) do begin
    FVersionStr := Format('v%d.%d.%d.%d (%d-bit)', [MajorVersion, MinorVersion, Revision, Build, SizeOf(NativeInt)*8]);
    lblPlugin.Caption := Format(lblPlugin.Caption, [FVersionStr]);
    Free;
  end;

  lblIEVersion.Caption := Format(lblIEVersion.Caption, [GetIEVersion]);
end {TAboutForm.FormCreate};

{ ------------------------------------------------------------------------------------------------ }
procedure TAboutForm.lblLinkClick(Sender: TObject);
var
  URL, Subject: string;
begin
  URL := TLabel(Sender).Hint;
  if StartsText('mailto:', URL) then begin
    with TFileVersionInfo.Create(TModulePath.DLLFullName) do begin
      Subject := Self.Caption + Format(' %s', [FVersionStr]);
      Free;
    end;
    URL := URL + '?subject=' + TIdURI.ParamsEncode(Subject);
  end;
  ShellAPI.ShellExecute(Self.Handle, 'Open', PChar(URL), Nil, Nil, SW_SHOWNORMAL);
  ModalResult := mrCancel;
end {TAboutForm.lblLinkClick};

{ ------------------------------------------------------------------------------------------------ }
procedure TAboutForm.ToggleDarkMode;
begin
end;

end.
