unit U_Npp_PreviewHTML;

////////////////////////////////////////////////////////////////////////////////////////////////////
{$WARN SYMBOL_PLATFORM OFF}
interface

uses
  SysUtils, Windows, IniFiles,
  NppPlugin,
  F_About, F_PreviewHTML;

const
  SCLEX_HTML  = 4;
  SCLEX_XML   = 5;

type
  TNppPluginPreviewHTML = class(TNppPlugin)
  private
    FSettings: TIniFile;
    function Caption: nppString;
    function AddFuncItem(Name: nppString; Func: PFUNCPLUGINCMD; Checked: Boolean): Integer; overload;
    procedure AddFuncSeparator;
  public
    constructor Create;

    procedure SetInfo(NppData: TNppData); override;

    procedure CommandShowPreview;
    procedure CommandSetIEVersion(const BrowserEmulation: Integer);
    procedure CommandOpenFile(const Filename: nppString);
    procedure CommandShowAbout;

    procedure DoNppnToolbarModification; override;
    procedure DoNppnFileClosed(const BufferID: THandle); override;
    procedure DoNppnBufferActivated(const BufferID: THandle); override;
    procedure DoModified(const hwnd: HWND; const modificationType: Integer); override;

    function  GetSettings(const Name: string = 'Settings.ini'): TIniFile;

    property ConfigDir: nppString read GetPluginsConfigDir;
  end {TNppPluginPreviewHTML};

procedure _FuncShowPreview; cdecl;
procedure _FuncOpenSettings; cdecl;
procedure _FuncOpenFilters; cdecl;
procedure _FuncShowAbout; cdecl;

procedure _FuncSetIE7; cdecl;
procedure _FuncSetIE8; cdecl;
procedure _FuncSetIE9; cdecl;
procedure _FuncSetIE10; cdecl;
procedure _FuncSetIE11; cdecl;
procedure _FuncSetIE12; cdecl;
procedure _FuncSetIE13; cdecl;


var
  Npp: TNppPluginPreviewHTML;

////////////////////////////////////////////////////////////////////////////////////////////////////
implementation
uses
  Graphics,
  Imaging.pngimage,
  WebBrowser, Registry,
  ModulePath,
  Debug;

var
  ToolbarBmp: TBitMap;

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
procedure _FuncShowAbout; cdecl;
begin
  Npp.CommandShowAbout;
end;
{ ------------------------------------------------------------------------------------------------ }
procedure _FuncShowPreview; cdecl;
begin
  Npp.CommandShowPreview;
end;
{ ------------------------------------------------------------------------------------------------ }
procedure _FuncSetIE7; cdecl;
begin
  Npp.CommandSetIEVersion(7000);
end;
{ ------------------------------------------------------------------------------------------------ }
procedure _FuncSetIE8; cdecl;
begin
  Npp.CommandSetIEVersion(8000);
end;
{ ------------------------------------------------------------------------------------------------ }
procedure _FuncSetIE9; cdecl;
begin
  Npp.CommandSetIEVersion(9000);
end;
{ ------------------------------------------------------------------------------------------------ }
procedure _FuncSetIE10; cdecl;
begin
  Npp.CommandSetIEVersion(10000);
end;
{ ------------------------------------------------------------------------------------------------ }
procedure _FuncSetIE11; cdecl;
begin
  Npp.CommandSetIEVersion(11000);
end;
{ ------------------------------------------------------------------------------------------------ }
procedure _FuncSetIE12; cdecl;
begin
  Npp.CommandSetIEVersion(12000);
end;
{ ------------------------------------------------------------------------------------------------ }
procedure _FuncSetIE13; cdecl;
begin
  Npp.CommandSetIEVersion(13000);
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
  Result := StringReplace(Self.PluginName, '&', '', []);
end;

{ ------------------------------------------------------------------------------------------------ }
function TNppPluginPreviewHTML.AddFuncItem(Name: nppString; Func: PFUNCPLUGINCMD; Checked: Boolean): Integer;
begin
  Result := AddFuncItem(Name, Func);
  self.FuncArray[Result].Checked := Checked;
end;

{ ------------------------------------------------------------------------------------------------ }
procedure TNppPluginPreviewHTML.AddFuncSeparator;
begin
  AddFuncItem('-', nil);
end;

{ ------------------------------------------------------------------------------------------------ }
procedure TNppPluginPreviewHTML.SetInfo(NppData: TNppData);
var
  IEVersion: string;
  MajorIEVersion, Code, EmulatedVersion: Integer;
  Psk: PShortcutKey;
begin
  inherited;

  Psk := MakeShortcutKey(True, False, True, Ord('H'));   // Ctrl-Shift-H
  self.AddFuncItem('&Preview HTML', _FuncShowPreview, Psk);

  IEVersion := GetIEVersion;
  with GetSettings do begin
    IEVersion := ReadString('Emulation', 'Installed IE version', IEVersion);
    Free;
  end;
  Val(IEVersion, MajorIEVersion, Code);
  if Code <= 1 then
    MajorIEVersion := 0;

  EmulatedVersion := GetBrowserEmulation div 1000;

  if MajorIEVersion > 7 then begin
    self.AddFuncSeparator;
    self.AddFuncItem('View as IE&7', _FuncSetIE7, EmulatedVersion = 7);
  end;

  if MajorIEVersion >= 8 then
    self.AddFuncItem('View as IE&8', _FuncSetIE8, EmulatedVersion = 8);
  if MajorIEVersion >= 9 then
    self.AddFuncItem('View as IE&9', _FuncSetIE9, EmulatedVersion = 9);
  if MajorIEVersion >= 10 then
    self.AddFuncItem('View as IE1&0', _FuncSetIE10, EmulatedVersion = 10);
  if MajorIEVersion >= 11 then
    self.AddFuncItem('View as IE1&1', _FuncSetIE11, EmulatedVersion = 11);
  if MajorIEVersion >= 12 then
    self.AddFuncItem('View as IE1&2', _FuncSetIE12, EmulatedVersion = 12);
  if MajorIEVersion >= 13 then
    self.AddFuncItem('View as IE1&3', _FuncSetIE13, EmulatedVersion = 13);

  self.AddFuncSeparator;

  self.AddFuncItem('Edit &settings', _FuncOpenSettings);
  self.AddFuncItem('Edit &filter definitions', _FuncOpenFilters);

  self.AddFuncSeparator;

  self.AddFuncItem('&About', _FuncShowAbout);
end {TNppPluginPreviewHTML.SetInfo};

{ ------------------------------------------------------------------------------------------------ }
procedure TNppPluginPreviewHTML.CommandOpenFile(const Filename: nppString);
var
  FullPath: nppString;
  ConfigSample, DllSample: nppString;
begin
  try
    FullPath := Npp.ConfigDir + '\PreviewHTML\' + Filename;
    if not FileExists(FullPath) then begin
      ConfigSample := ChangeFileExt(Filename, '.sample' + ExtractFileExt(FullPath));
      DllSample := ExtractFilePath(TModulePath.DLLFullName) + ConfigSample;
      if FileExists(DllSample) then
        Win32Check(CopyFile(PChar(string(DllSample)), PChar(string(FullPath)), True));
    end;
    if DoOpen(FullPath) then
      MessageBox(Npp.NppData.NppHandle, PChar(Format('Unable to open "%s".', [FullPath])), PChar(Caption), MB_ICONWARNING);
  except
    ShowException(ExceptObject, ExceptAddr);
  end;
end {TNppPluginPreviewHTML.CommandOpenFilters};

{ ------------------------------------------------------------------------------------------------ }
procedure TNppPluginPreviewHTML.CommandSetIEVersion(const BrowserEmulation: Integer);
begin
  if GetBrowserEmulation <> BrowserEmulation then begin
    SetBrowserEmulation(BrowserEmulation);
    MessageBox(Npp.NppData.NppHandle,
                PChar(Format('The preview browser mode has been set to correspond to Internet Explorer version %d.'#13#10#13#10 +
                             'Please restart Notepad++ for the new browser mode to be taken into account.',
                             [BrowserEmulation div 1000])),
                PChar(Self.Caption), MB_ICONWARNING);
  end else begin
    MessageBox(Npp.NppData.NppHandle,
                PChar(Format('The preview browser mode was already set to Internet Explorer version %d.',
                             [BrowserEmulation div 1000])),
                PChar(Self.Caption), MB_ICONINFORMATION);
  end;
end {TNppPluginPreviewHTML.CommandSetIEVersion};

{ ------------------------------------------------------------------------------------------------ }
procedure TNppPluginPreviewHTML.CommandShowAbout;
begin
  with TAboutForm.Create(self) do begin
    ShowModal;
    Free;
  end;
end {TNppPluginPreviewHTML.CommandShowAbout};

{ ------------------------------------------------------------------------------------------------ }
procedure TNppPluginPreviewHTML.CommandShowPreview;
const
  ncDlgId = 0;
begin
  if (not Assigned(frmHTMLPreview)) then begin
    frmHTMLPreview := TfrmHTMLPreview.Create(self);
    frmHTMLPreview.Show(self, ncDlgId);
  end else begin
      frmHTMLPreview.Show
  end;
    frmHTMLPreview.btnRefresh.Click;
end {TNppPluginPreviewHTML.CommandShowPreview};

{ ------------------------------------------------------------------------------------------------ }
function TNppPluginPreviewHTML.GetSettings(const Name: string): TIniFile;
begin
  ForceDirectories(ConfigDir + '\PreviewHTML');
  Result := TIniFile.Create(ConfigDir + '\PreviewHTML\' + Name);
end {TNppPluginPreviewHTML.GetSettings};


{ ------------------------------------------------------------------------------------------------ }
procedure TNppPluginPreviewHTML.DoNppnToolbarModification;
const
  hNil = THandle(-1);
var
  tb: TToolbarIcons;
  tbDM: TTbIconsDarkMode;
  bmpData: TPngImage;
  hHDC: HDC;
  bmpX, bmpY, icoX, icoY: Integer;
begin
  hHDC := hNil;
  bmpData := TPngImage.Create;
  ToolbarBmp := TBitmap.Create;
  try
    hHDC := GetDC(hNil);
    bmpX := MulDiv(16, GetDeviceCaps(hHDC, LOGPIXELSX), 96);
    bmpY := MulDiv(16, GetDeviceCaps(hHDC, LOGPIXELSY), 96);
    icoX := MulDiv(32, GetDeviceCaps(hHDC, LOGPIXELSX), 96);
    icoY := MulDiv(32, GetDeviceCaps(hHDC, LOGPIXELSY), 96);
    try
      bmpData.LoadFromResourceName(HInstance, 'TB_BMP_DATA');
      ToolbarBmp.Assign(bmpData);
      ToolbarBmp.PixelFormat := pf32bit;
      tb.ToolbarBmp := CopyImage(ToolbarBmp.Handle, IMAGE_BITMAP, bmpX, bmpY, LR_COPYRETURNORG);
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
procedure TNppPluginPreviewHTML.DoNppnBufferActivated(const BufferID: THandle);
begin
  inherited;
  if Assigned(frmHTMLPreview) and frmHTMLPreview.Visible then begin
    frmHTMLPreview.btnRefresh.Click;
  end;
end {TNppPluginPreviewHTML.DoNppnBufferActivated};

{ ------------------------------------------------------------------------------------------------ }
procedure TNppPluginPreviewHTML.DoNppnFileClosed(const BufferID: THandle);
begin
  if Assigned(frmHTMLPreview) then begin
    frmHTMLPreview.ForgetBuffer(BufferID);
  end;
  inherited;
end {TNppPluginPreviewHTML.DoNppnFileClosed};

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
  try
    Npp := TNppPluginPreviewHTML.Create;
  except
    ShowException(ExceptObject, ExceptAddr);
  end;

finalization
  if Assigned(ToolbarBmp) then
    FreeAndNil(ToolbarBmp);
end.
