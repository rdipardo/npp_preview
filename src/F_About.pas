unit F_About;

interface

uses
  Windows, SysUtils, Variants, Classes, Graphics, Controls, Forms,
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

function IsAtLeastWindows11(var WinVerMajor, WinVerMinor, BuildNr: DWORD): Boolean;

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
  wvEnvironment: TCoreWebView2Environment;
  wvLoaderPath: WideString;
  wvLoaderAddr: NativeInt;
  WinVerMajor, WinVerMinor, BuildNr: DWORD;
begin
  btnOK.Left := ((Self.Width div 2) - (btnOK.Width div 2) - 4);
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
      end else
        Left := Left + 4;
    end;
  end;

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
    wvLoaderAddr := GetModuleHandleW(PWCHAR('WebView2Loader.dll'));
    SetLastError(0);
    if wvLoaderAddr <> 0 then begin
        SetLength(wvLoaderPath, (MAX_PATH + 1) * SizeOf(WChar));
        if GetModuleFileNameW(wvLoaderAddr, PWCHAR(wvLoaderPath), MAX_PATH * SizeOf(WChar)) > 0 then begin
          with TFileVersionInfo.Create(wvLoaderPath) do begin
            lblIEVersion.Caption := Format('Using embedded WebView2 browser version %s', [ProductVersion]);
            Free;
          end;
        end;
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
{$ifndef FPC}
begin
end;
{$else}
const
  clDarkModeLink = TColor($FFBF00);
var
  Palette : TDarkModeColors;
  Lbl : TLabel;
  I : Integer;
  IsDark : Boolean;
begin
  inherited;
  IsDark := False;
  Palette := Default(TDarkModeColors);
  if Npp.IsDarkModeEnabled then begin
    Npp.GetDarkModeColors(@Palette);
    IsDark := True;
  end;
  for I := 0 to self.ComponentCount - 1 do begin
    if (self.Components[i] is TLabel) then begin
      Lbl := TLabel(self.Components[I]);
      if Lbl.Hint <> '' then begin
        if IsDark then
          Lbl.Font.Color := clDarkModeLink
        else
          Lbl.Font.Color := clHotLight;
      end else begin
        if IsDark then
          Lbl.Font.Color := TColor(Palette.Text)
        else
          Lbl.Font.Color := clWindowText;
      end;
    end;
  end;
end;
{$endif}

{$ifdef FPC}
{ ------------------------------------------------------------------------------------------------ }
class function TIdURI.ParamsEncode(AParams: string): string;
begin
  Result := HTTPEncode(AParams);
end;
{$endif}

end.
