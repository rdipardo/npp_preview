unit F_About;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, NppForms, StdCtrls, ExtCtrls;

type
  TAboutForm = class(TNppForm)
    btnOK: TButton;
    lblWebViewLicense, lblWebView: TLabel;
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

{$ifdef FPC}
  TIdURI = object
    class function ParamsEncode(AParams: string): string; static;
  end;
{$endif}

var
  AboutForm: TAboutForm;

implementation
uses
  ShellAPI, StrUtils,
{$ifndef FPC}
  IdURI,
{$else}
  httpprotocol,
{$endif}
  VersionInfo, ModulePath, uWVLoader, uWVCoreWebView2Environment,
  NppPlugin;

{$R *.dfm}

{ ------------------------------------------------------------------------------------------------ }
procedure TAboutForm.FormCreate(Sender: TObject);
var
  wvEnvironment: TCoreWebView2Environment;
begin
  btnOK.Left := ((Self.Width div 2) - (btnOK.Width div 2) - 4);
  with TFileVersionInfo.Create(TModulePath.DLLFullName) do begin
    FVersionStr := Format('v%d.%d.%d.%d (%d-bit)', [MajorVersion, MinorVersion, Revision, Build, SizeOf(NativeInt)*8]);
    lblPlugin.Caption := Format(lblPlugin.Caption, [FVersionStr]);
    Free;
  end;

  if GlobalWebView2Loader.Initialized then begin
    try
      wvEnvironment := TCoreWebView2Environment.Create(GlobalWebView2Loader.Environment);
      if Assigned(wvEnvironment) and wvEnvironment.Initialized then
        lblIEVersion.Caption := Format(lblIEVersion.Caption, [wvEnvironment.BrowserVersionInfo])
    finally
      FreeAndNil(wvEnvironment);
    end;
  end else begin
    with TFileVersionInfo.Create(ChangeFilePath('WebView2Loader.dll', TModulePath.DLL)) do begin
      lblIEVersion.Caption := Format('Using embedded WebView2 browser version %s', [ProductVersion]);
      Free;
    end;
  end;
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

{$ifdef FPC}
{ ------------------------------------------------------------------------------------------------ }
class function TIdURI.ParamsEncode(AParams: string): string;
begin
  Result := HTTPEncode(AParams);
end;
{$endif}

end.
