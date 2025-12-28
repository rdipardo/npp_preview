unit U_Npp_PreviewHTML;

////////////////////////////////////////////////////////////////////////////////////////////////////
{$WARN SYMBOL_PLATFORM OFF}
interface

uses
{$ifdef FPC}
  Interfaces,
  LCLIntf,
  LCLType,
  Forms,
{$endif}
  SysUtils, Windows, Utf8IniFiles,
  NppPlugin,
  F_About, F_PreviewHTML;

const
  SCLEX_HTML  = 4;
  SCLEX_XML   = 5;
  SECTION_CSS = 'Style';
  SECTION_JS  = 'JavaScript';
  VAL_FNAME   = 'Filename';
  VAL_EXT     = 'Extension';
  VAL_EXT_ANY = '*';
  DEFAULT_STYLE_SHEET      = 'style.css';
  DEFAULT_DARK_STYLE_SHEET = 'style-dark.css';

type
  TNppPluginPreviewHTML = class(TNppPlugin)
  private
    FSettingsDir, FStaticAssetsDir: nppString;
    function Caption: nppString;
    function UserAgentString: nppstring;
    procedure AddFuncSeparator;
    procedure SetMenuItemState(const Id: Integer; Disable: Boolean);
  public
    constructor Create;

    procedure SetInfo(NppData: TNppData); override;

    procedure CommandShowPreview;
    procedure CommandOpenFile(const Filename: nppString);
    procedure CommandShowAbout;

    procedure BeNotified(sn: PSciNotification); override;
    procedure DoNppnToolbarModification; override;
    procedure DoNppnFileClosed(const BufferID: NativeUInt); override;
    procedure DoNppnBufferActivated(const BufferID: NativeUInt); override;
    procedure DoModified(const hwnd: HWND; const modificationType: Integer); override;
    procedure DoNppnShutdown; override;

    function  GetAssetPath(const Name: string; const Mime: string = '.css'): WideString;
    function  GetSettings(const Name: WideString = 'Settings.ini'): TUtf8IniFile;

    property ConfigDir: nppString read FSettingsDir;
    property AssetDir: nppString read FStaticAssetsDir;
  end {TNppPluginPreviewHTML};

procedure _FuncShowPreview; cdecl;
procedure _FuncOpenSettings; cdecl;
procedure _FuncOpenFilters; cdecl;
procedure _FuncOpenDefaultStyleSheet; cdecl;
procedure _FuncOpenUserScript; cdecl;
procedure _FuncShowAbout; cdecl;



var
  Npp: TNppPluginPreviewHTML;

////////////////////////////////////////////////////////////////////////////////////////////////////
implementation
uses
  Classes,
  Graphics,
{$ifndef FPC}
  Imaging.pngimage,
{$endif}
  uWVLoader,
  uWVTypeLibrary,
  ModulePath,
  VersionInfo,
  Debug;

const
  ncDlgId = 0;

var
  StyleDlgId, ScriptDlgId: Integer;

{$ifdef FPC}
type
  TPngImage = TPortableNetworkGraphic;
var
  FauxModalTimerID: UIntPtr;
{$else}
var
  ToolbarBmp: TBitMap;
{$endif}

{ ------------------------------------------------------------------------------------------------ }
procedure _FuncOpenSettings; cdecl;
begin
  Npp.CommandOpenFile('Settings.ini');
end;
{ ------------------------------------------------------------------------------------------------ }
procedure _FuncOpenFilters; cdecl;
begin
  Npp.CommandOpenFile('Filters.ini');
end;
{ ------------------------------------------------------------------------------------------------ }
procedure _FuncOpenDefaultStyleSheet; cdecl;
var
  Fname: string;
begin
  with Npp.GetSettings() do begin
    Fname := Trim(ReadString(SECTION_CSS, VAL_FNAME, String.Empty));
    Free;
  end;
  if (Fname <> String.Empty) then
    Npp.DoOpen(Npp.GetAssetPath(Fname))
  else begin
    if Npp.IsDarkModeEnabled then
      Npp.DoOpen(Npp.GetAssetPath(DEFAULT_DARK_STYLE_SHEET))
    else
      Npp.DoOpen(Npp.GetAssetPath(DEFAULT_STYLE_SHEET));
  end
end;
{ ------------------------------------------------------------------------------------------------ }
procedure _FuncOpenUserScript; cdecl;
var
  Fname: string;
begin
  with Npp.GetSettings() do begin
    Fname := Trim(ReadString(SECTION_JS, VAL_FNAME, String.Empty));
    Free;
  end;
  if (Fname <> String.Empty) then
    Npp.DoOpen(Npp.GetAssetPath(Fname, '.js'));
end;
{ ------------------------------------------------------------------------------------------------ }
procedure _FuncShowAbout; cdecl;
begin
  Npp.CommandShowAbout;
end;
{ ------------------------------------------------------------------------------------------------ }
procedure _FuncShowPreview; cdecl;
begin
  Npp.CommandShowPreview;
end;


{ ================================================================================================ }
{ TNppPluginPreviewHTML }

{ ------------------------------------------------------------------------------------------------ }
constructor TNppPluginPreviewHTML.Create;
begin
  inherited;
  self.PluginName := '&Preview HTML'{$IFDEF DEBUG}+' (debug)'{$ENDIF};
end {TNppPluginPreviewHTML.Create};

{ ------------------------------------------------------------------------------------------------ }
function TNppPluginPreviewHTML.Caption: nppString;
begin
  Result := {$ifdef FPC}UnicodeStringReplace{$else}StringReplace{$endif}(Self.PluginName, '&', '', []);
end;

{ ------------------------------------------------------------------------------------------------ }
function TNppPluginPreviewHTML.UserAgentString: nppstring;
var
  NppVersion: Cardinal;
begin
  NppVersion := GetNppVersion;
  with TFileVersionInfo.Create(TModulePath.DLLFullName) do begin
    Result := WideFormat('%s/%d.%d.%d.%d (Notepad++ %d.%d %s)',
      [Self.Caption, MajorVersion, MinorVersion, Revision, Build,
      HiWord(NppVersion), LoWord(NppVersion),
      {$ifdef CPUx64}'x64'{$else}'x86'{$endif}]);
    Free;
  end;
end;

{ ------------------------------------------------------------------------------------------------ }
procedure TNppPluginPreviewHTML.AddFuncSeparator;
begin
  AddFuncItem('-', nil);
end;

{ ------------------------------------------------------------------------------------------------ }
procedure TNppPluginPreviewHTML.SetMenuItemState(const Id: Integer; Disable: Boolean);
var
  Flags: Cardinal;
begin
  Flags := MF_BYCOMMAND or MF_ENABLED;
  if Disable then
    Flags := MF_BYCOMMAND or MF_DISABLED or MF_GRAYED;
  EnableMenuItem(GetMenu(NppData.nppHandle), CmdIdFromDlgId(Id), Flags);
end;

{ ------------------------------------------------------------------------------------------------ }
procedure TNppPluginPreviewHTML.SetInfo(NppData: TNppData);
var
  UserDataDir: WideString;
  DefaultStyleSheet, DefaultDarkStyleSheet: WideString;
  Psk: PShortcutKey;
begin
  inherited;

  Psk := MakeShortcutKey(True, False, True, Ord('H'));   // Ctrl-Shift-H
  self.AddFuncItem('&Preview HTML', _FuncShowPreview, Psk);
  self.AddFuncItem('Edit &settings', _FuncOpenSettings);
  self.AddFuncItem('Edit &filter definitions', _FuncOpenFilters);
  StyleDlgId := self.AddFuncItem('Edit default &CSS', _FuncOpenDefaultStyleSheet);
  ScriptDlgId := self.AddFuncItem('Edit default &JavaScript', _FuncOpenUserScript);

  self.AddFuncSeparator;

  self.AddFuncItem('&About', _FuncShowAbout);

  FSettingsDir := GetPluginsConfigDir() + '\PreviewHTML\';
  FStaticAssetsDir := FSettingsDir + 'Static';
  UserDataDir := FSettingsDir + 'WebView2Cache';

  if not DirectoryExists(FSettingsDir) then
    CreateDir(FSettingsDir);

  if not DirectoryExists(FStaticAssetsDir) then
    CreateDir(FStaticAssetsDir);

  if not DirectoryExists(UserDataDir) then
    CreateDir(UserDataDir);

  DefaultStyleSheet := GetAssetPath(DEFAULT_STYLE_SHEET);
  DefaultDarkStyleSheet := GetAssetPath(DEFAULT_DARK_STYLE_SHEET);

  if not FileExists(DefaultStyleSheet) then
    CopyFileW(PWChar(ChangeFilePath(DEFAULT_STYLE_SHEET, TModulePath.DLL)),
      PWChar(DefaultStyleSheet), True);

  if not FileExists(DefaultDarkStyleSheet) then
    CopyFileW(PWChar(ChangeFilePath(DEFAULT_DARK_STYLE_SHEET, TModulePath.DLL)),
      PWChar(DefaultDarkStyleSheet), True);

  try
    GlobalWebView2Loader := TWVLoader.Create(nil);
    with GlobalWebView2Loader do begin
      UseInternalLoader := True;
      UserDataFolder := UserDataDir;
      UserAgent := UserAgentString;
      EnableGPU := False;
      AllowInsecureLocalhost := True;
      AllowFileAccessFromFiles := True;
      AllowOldRuntime := True;
      ScrollBarStyle := COREWEBVIEW2_SCROLLBAR_STYLE_FLUENT_OVERLAY;
      StartWebView2;
    end;
  except
    ShowException(ExceptObject, ExceptAddr);
  end;
end {TNppPluginPreviewHTML.SetInfo};

{ ------------------------------------------------------------------------------------------------ }
procedure TNppPluginPreviewHTML.CommandOpenFile(const Filename: nppString);
var
  HIniFile: THandle;
  FullPath: nppString;
  ConfigSample, DllSample: nppString;
begin
  try
    HIniFile := THandle(-1);
    FullPath := FSettingsDir + Filename;
    if not FileExists(FullPath) then begin
      ConfigSample := ChangeFileExt(Filename, '.sample' + ExtractFileExt(FullPath));
      DllSample := ExtractFilePath(TModulePath.DLLFullName) + ConfigSample;
      if FileExists(DllSample) then
        Win32Check(CopyFileW(PWChar(DllSample), PWChar(FullPath), True))
      else begin
        try
          HIniFile := FileCreate(FullPath, fmShareDenyWrite);
        finally
          if HIniFile <> THandle(-1) then
            FileClose(HIniFile);
        end;
      end;
    end;
    if DoOpen(FullPath) then
      MessageBoxW(Npp.NppData.NppHandle, PWChar(WideFormat('Unable to open "%s".', [FullPath])), PWChar(Caption), MB_ICONWARNING);
  except
    ShowException(ExceptObject, ExceptAddr);
  end;
end {TNppPluginPreviewHTML.CommandOpenFilters};
{ ------------------------------------------------------------------------------------------------ }
procedure TNppPluginPreviewHTML.CommandShowAbout;
{$ifdef FPC}
  procedure FauxModalTimer(WndHandle: HWND; Msg: UINT; EventID: UINT; TimeMS: UINT); stdcall;
  begin
    KillTimer(0, EventID);
    if Assigned(AboutForm) then
      AboutForm.SetFocus;
  end;
{$endif}
var
  FrmParent: TComponent;
  CheckState: Boolean;
begin
{$ifdef FPC}
  if Assigned(AboutForm) then
    Exit;
{$endif}
  FrmParent := Nil;
  CheckState := False;
  if Assigned(frmHTMLPreview) then
  begin
    FrmParent := TComponent(frmHTMLPreview);
    CheckState := frmHTMLPreview.chkFreeze.Checked;
    frmHTMLPreview.chkFreeze.Checked := True;
  end;
  AboutForm := TAboutForm.Create(FrmParent);
  with AboutForm do begin
    Npp := Self;
    ToggleDarkMode;
{$ifdef FPC}
    FauxModalTimerID := SetTimer(0, 0, 100, @FauxModalTimer);
{$endif}
    ShowModal;
    Free;
  end;
  AboutForm := nil;
  if Assigned(frmHTMLPreview) then
    frmHTMLPreview.chkFreeze.Checked := CheckState;
end {TNppPluginPreviewHTML.CommandShowAbout};

{ ------------------------------------------------------------------------------------------------ }
procedure TNppPluginPreviewHTML.CommandShowPreview;
begin
  if GlobalWebView2Loader.InitializationError then begin
    Exit;
  end;
  if (not Assigned(frmHTMLPreview)) then begin
{$ifdef FPC}
    Application.CreateForm(TfrmHTMLPreview, frmHTMLPreview);
{$else}
    frmHTMLPreview := TfrmHTMLPreview.Create(self);
{$endif}
    frmHTMLPreview.Show(self, ncDlgId);
  end else begin
      if frmHTMLPreview.Visible then begin
        frmHTMLPreview.btnClose.Click;
        Exit;
      end;
      frmHTMLPreview.Show
  end;
    frmHTMLPreview.btnRefresh.Click;
end {TNppPluginPreviewHTML.CommandShowPreview};

{ ------------------------------------------------------------------------------------------------ }
function TNppPluginPreviewHTML.GetSettings(const Name: WideString): TUtf8IniFile;
begin
  Result := TUtf8IniFile.Create(FSettingsDir + Name);
end {TNppPluginPreviewHTML.GetSettings};

{ ------------------------------------------------------------------------------------------------ }
function TNppPluginPreviewHTML.GetAssetPath(const Name, Mime: string): WideString;
begin
  Result := ChangeFilePath(nppString(ChangeFileExt(Name, Mime)), FStaticAssetsDir);
end {TNppPluginPreviewHTML.GetAssetPath};

{ ------------------------------------------------------------------------------------------------ }
procedure TNppPluginPreviewHTML.BeNotified(sn: PSciNotification);
begin
  inherited;
  if HWND(sn^.nmhdr.hwndFrom) = self.NppData.NppHandle then begin
    if (sn^.nmhdr.code = NPPN_READY) and GlobalWebView2Loader.InitializationError then
        EnableMenuItem(GetMenu(NppData.nppHandle), CmdIdFromDlgId(ncDlgId),
          MF_BYCOMMAND or MF_DISABLED or MF_GRAYED)
    else
    if (sn^.nmhdr.code = NPPN_DARKMODECHANGED) then begin
      if Assigned(FrmHTMLPreview) then FrmHTMLPreview.ToggleDarkMode;
      if Assigned(AboutForm) then AboutForm.ToggleDarkMode;
    end;
  end else if (sn^.nmhdr.code = SCN_AUTOCCOMPLETED) then begin
    if Assigned(frmHTMLPreview) and frmHTMLPreview.Visible then
      frmHTMLPreview.btnRefresh.Click;
  end;
end {TNppPluginPreviewHTML.BeNotified};

{ ------------------------------------------------------------------------------------------------ }
procedure TNppPluginPreviewHTML.DoNppnToolbarModification;
const
  hNil = THandle(-1);
var
  tb: TToolbarIcons;
  tbDM: TTbIconsDarkMode;
  bmpData: TPngImage;
  bmpResName: String;
  hHDC: HDC;
  bmpX, bmpY, icoX, icoY: Integer;
  WinVerMajor, WinVerMinor, BuildNr: DWORD;
begin
  hHDC := hNil;
  bmpData := TPngImage.Create;
{$ifdef FPC}
  bmpData.HandleType := TBitmapHandleType.bmDDB;
{$else}
  ToolbarBmp := TBitmap.Create;
{$endif}
  try
    hHDC := GetDC(hNil);
    bmpX := MulDiv(16, GetDeviceCaps(hHDC, LOGPIXELSX), 96);
    bmpY := MulDiv(16, GetDeviceCaps(hHDC, LOGPIXELSY), 96);
    icoX := MulDiv(32, GetDeviceCaps(hHDC, LOGPIXELSX), 96);
    icoY := MulDiv(32, GetDeviceCaps(hHDC, LOGPIXELSY), 96);
    try
      bmpResName := 'TB_BMP_DATA';
      if not IsAtLeastWindows11(WinVerMajor, WinVerMinor, BuildNr) then
        bmpResName := 'TB_BMP_16_DATA';
      bmpData.LoadFromResourceName(HInstance, bmpResName);
{$ifndef FPC}
      ToolbarBmp.Assign(bmpData);
      ToolbarBmp.PixelFormat := pf32bit;
      tb.ToolbarBmp := CopyImage(ToolbarBmp.Handle, IMAGE_BITMAP, bmpX, bmpY, LR_COPYRETURNORG);
{$else}
      tb.ToolbarBmp := CopyImage(bmpData.Handle, IMAGE_BITMAP, bmpX, bmpY, LR_COPYDELETEORG);
{$endif}
    except
      tb.ToolbarBmp := LoadImage(Hinstance, 'TB_PREVIEW_HTML', IMAGE_BITMAP, bmpX, bmpY, 0);
    end;
  finally
    ReleaseDC(hNil, hHDC);
    FreeAndNil(bmpData);
  end;
  tb.ToolbarIcon := LoadImage(Hinstance, 'TB_PREVIEW_HTML_ICO', IMAGE_ICON, icoX, icoY, (LR_DEFAULTSIZE or LR_LOADTRANSPARENT));
  if SupportsDarkMode then begin
    with tbDM do begin
      ToolbarBmp := tb.ToolbarBmp;
      ToolbarIcon := tb.ToolbarIcon;
      ToolbarIconDarkMode := LoadImage(Hinstance, 'TB_PREVIEW_HTML_ICO_DM', IMAGE_ICON, icoX, icoY, (LR_DEFAULTSIZE or LR_LOADTRANSPARENT));
    end;
    SendNppMessage(NPPM_ADDTOOLBARICON_FORDARKMODE, self.CmdIdFromDlgId(0), @tbDm);
  end else
    SendNppMessage(NPPM_ADDTOOLBARICON_DEPRECATED, self.CmdIdFromDlgId(0), @tb);
//  SendMessage(self.NppData.ScintillaMainHandle, SCI_SETMODEVENTMASK, SC_MOD_INSERTTEXT or SC_MOD_DELETETEXT, 0);
//  SendMessage(self.NppData.ScintillaSecondHandle, SCI_SETMODEVENTMASK, SC_MOD_INSERTTEXT or SC_MOD_DELETETEXT, 0);
end {TNppPluginPreviewHTML.DoNppnToolbarModification};

{ ------------------------------------------------------------------------------------------------ }
procedure TNppPluginPreviewHTML.DoNppnBufferActivated(const BufferID: NativeUInt);
begin
  inherited;
  if WideSameText(FSettingsDir+'Settings.ini', GetCurrentBufferPath(BufferID)) then
    Exit;
  if Assigned(frmHTMLPreview) and frmHTMLPreview.Visible then begin
    frmHTMLPreview.ReloadSettings;
    frmHTMLPreview.btnRefresh.Click;
  end;
  with GetSettings() do begin
    SetMenuItemState(StyleDlgId, ReadBool(SECTION_CSS, 'Disable', False));
    SetMenuItemState(ScriptDlgId, not SectionExists(SECTION_JS) or ReadBool(SECTION_JS, 'Disable', False));
    Free;
  end;
end {TNppPluginPreviewHTML.DoNppnBufferActivated};

{ ------------------------------------------------------------------------------------------------ }
procedure TNppPluginPreviewHTML.DoNppnFileClosed(const BufferID: NativeUInt);
begin
  if Assigned(frmHTMLPreview) then begin
    frmHTMLPreview.ForgetBuffer(BufferID);
  end;
  inherited;
end {TNppPluginPreviewHTML.DoNppnFileClosed};

{ ------------------------------------------------------------------------------------------------ }
procedure TNppPluginPreviewHTML.DoNppnShutdown;
var
  I: NativeUInt;
begin
  for I:=0 to SendNppMessage(NPPM_GETNBOPENFILES, 0, PRIMARY_VIEW) do
    DoNppnFileClosed(SendNppMessage(NPPM_GETBUFFERIDFROMPOS, I, PRIMARY_VIEW));
  for I:=0 to SendNppMessage(NPPM_GETNBOPENFILES, 0, SECOND_VIEW) do
    DoNppnFileClosed(SendNppMessage(NPPM_GETBUFFERIDFROMPOS, I, SECOND_VIEW));
  if Assigned(frmHTMLPreview) then
    KillTimer(frmHTMLPreview.Handle, frmHTMLPreview.PrevTimerID);
end {TNppPluginPreviewHTML.DoNppnShutdown};

{ ------------------------------------------------------------------------------------------------ }
procedure TNppPluginPreviewHTML.DoModified(const hwnd: HWND; const modificationType: Integer);
begin
  if Assigned(frmHTMLPreview) and frmHTMLPreview.Visible and (modificationType and (SC_MOD_INSERTTEXT or SC_MOD_DELETETEXT) <> 0) then begin
    frmHTMLPreview.ResetTimer;
  end;
  inherited;
end {TNppPluginPreviewHTML.DoModified};



////////////////////////////////////////////////////////////////////////////////////////////////////
initialization
{$ifdef FPC}
  Application.CaptureExceptions := True;
{$ifdef VER3_2}
  Application.Scaled := True;
{$endif}
  Application.Initialize;
{$endif}
  try
    Npp := TNppPluginPreviewHTML.Create;
  except
    ShowException(ExceptObject, ExceptAddr);
  end;

finalization
{$ifndef FPC}
  if Assigned(ToolbarBmp) then
    FreeAndNil(ToolbarBmp);
{$else}
  KillTimer(0, FauxModalTimerID);
  if Assigned(AboutForm) then
    FreeAndNil(AboutForm);
{$endif}
end.
