unit F_PreviewHTML;

{$ifdef FPC}
  {$unitpath common}
  {$ifndef DEBUG}
    {$define ODS:=//}
  {$endif}
{$endif}

////////////////////////////////////////////////////////////////////////////////////////////////////
interface

uses
{$ifdef FPC}
  Interfaces,
  LCLIntf,
  LCLType,
{$endif}
  Windows, Messages, SysUtils, Classes, Variants, Graphics, Controls, Forms, Generics.Collections,
  Dialogs, StdCtrls, ComCtrls, ExtCtrls, Buttons, Utf8IniFiles,
  NppPlugin, NppDockingForms,
  uWVWinControl,
  uWVBrowserBase,
  uWVBrowser,
  uWVWindowParent,
  uWVLoader,
  uWVTypes,
  uWVTypeLibrary,
  uWVCoreWebView2Args,
  uWVCoreWebView2ExecuteScriptResult,
  customstreams,
  U_CustomFilter;

type
  TBufferID = NativeInt;

  TfrmHTMLPreview = class(TNppDockingForm)
    wbHost: TWVWindowParent;
    wbIE: TWVBrowser;
    pnlButtons: TPanel;
    btnRefresh: TButton;
    btnClose: TButton;
    sbrIE: TStatusBar;
    btnAbout, btnNavBack, btnNavForward: TBitBtn;
    tmrAutorefresh: TTimer;
    chkFreeze: TCheckBox;
    procedure btnRefreshClick(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure FormHide(Sender: TObject);
    procedure FormFloat(Sender: TObject);
    procedure FormDock(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure wbIEAfterCreated({%H-}ASender: TObject);
    procedure wbIETitleChange({%H-}ASender: TObject);
    procedure wbIENavigationHistoryChange({%H-}ASender: TObject);
    procedure wbIEStatusTextChange({%H-}ASender: TObject; const Text: WideString);
    procedure wbIEStatusBar({%H-}ASender: TObject; {%H-}const aWebView: ICoreWebView2);
    procedure wbIEExecuteScriptWithResultCompleted({%H-}Sender: TObject; {%H-}ErrorCode: HResult;
      const AResult: ICoreWebView2ExecuteScriptResult; ExecutionID: integer);
    procedure wbIEMoveFocusRequested({%H-}ASender: TObject; {%H-}const AController: ICoreWebView2Controller;
      const Args: ICoreWebView2MoveFocusRequestedEventArgs);
    procedure wbIENavigationStarting({%H-}ASender: TObject; {%H-}const AWebView: ICoreWebView2;
      const Args: ICoreWebView2NavigationStartingEventArgs);
    procedure btnCloseStatusbarClick(Sender: TObject);
    procedure btnAboutClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure tmrAutorefreshTimer(Sender: TObject);
    procedure chkFreezeClick(Sender: TObject);
    procedure btnNavBackClick({%H-}Sender: TObject);
    procedure btnNavForwardClick({%H-}Sender: TObject);
    procedure sbrIEDrawPanel(StatusBar: TStatusBar; Panel: TStatusPanel; const Rect: TRect);
    procedure wbIEInitializationError({%H-}ASender: TObject; ErrorCode: HRESULT; const ErrorMessage: wvstring);
  private
    { Private declarations }
    FBufferID: TBufferID;
    FScrollPositions: TDictionary<TBufferID,TPoint>;
    FFilterThread: TCustomFilterThread;
    FEnsureRendered: Boolean;
    FPreserveScrollPosition: Boolean;

    procedure SaveScrollPos;
    procedure RestoreScrollPos;
    procedure UpdateNavButton(var ABtn: TBitBtn; NewState: Boolean);

    function  DetermineCustomFilter: string;
    function  ExecuteCustomFilter(const FilterName: string; const HTML: wvstring; const BufferID: TBufferID): Boolean;
    function  TransformXMLToHTML(const XML: WideString): WideString;

    procedure FilterThreadTerminate(Sender: TObject);
  public
    { Public declarations }
    PrevTimerID: UIntPtr;
    constructor Create(AOwner: TComponent); override;
    procedure ToggleDarkMode; override;
    procedure ResetTimer;
    procedure ReloadSettings;
    procedure ForgetBuffer(const BufferID: TBufferID);
    procedure DisplayPreview(const BufferID: TBufferID);
    function  UpdatePreview(const BufferID: TBufferID): Boolean;
  protected
    procedure WMMove({%H-}var AMessage : TWMMove); message WM_MOVE;
    procedure WMMoving({%H-}var AMessage : TMessage); message WM_MOVING;
{$ifdef FPC}
    procedure SubclassAndTheme(DmfMask: Cardinal); override;
    procedure HandleCloseQuery({%H-}Sender: TObject; {%H-}var CanClose: Boolean); override;
{$endif}
  end;

var
  ContentStream: TUnicodeStream;
  frmHTMLPreview: TfrmHTMLPreview;

////////////////////////////////////////////////////////////////////////////////////////////////////
implementation
uses
  ComObj, StrUtils, Masks,
  RegExpr,
  Registry,
  ShellAPI,
  Debug,
{$ifndef FPC}
  REST.Json,
  F_About,
{$else}
  fpjson,
{$endif}
  U_Npp_PreviewHTML;

const
  APP_DOMAIN = 'preview.host';
  RESTORE_SCRIPT_ID = $7F;
  PLACEHOLDER_CONTENT =
    '<html>' +
    ' <body style="background:#ececec;color:#999">' +
    '   <p align="center" style="margin:14em 0">(no preview available)</p>' +
    ' </body>' +
    '</html>';
  SET_DEFAULT_BACKGROUND_JS = 'window.setTimeout(() => {' +
    ' const bgc = getComputedStyle(document.body).getPropertyValue("background-color") || "";' +
    ' const clr = getComputedStyle(document.body).getPropertyValue("color") || "";' +
    ' /* black text on a black background? */' +
    ' if (!([bgc, clr].every(s => /rgba?\((0(, )?){3,}/.test(s))))' +
    '   return;' +
    ' document.body.style.setProperty("background-color", "#fff");' +
    '}, 120);';

function JsonEncode(const AString: wvstring): wvstring;
begin
  Result :=
{$ifdef FPC}
    UTF8ToString(StringToJSONString(UTF8Encode(AString)))
{$else}
    TJson.JsonEncode(AString)
{$endif};
end;

procedure PreviewRefreshTimer(WndHandle: HWND; Msg: UINT; EventID: UINT; TimeMS: UINT); stdcall;
begin
  if Assigned(frmHTMLPreview) then
  begin
    frmHTMLPreview.btnRefresh.Click;
    KillTimer(frmHTMLPreview.Handle, EventID);
  end;
end;

// A message deadlock will occur if:
// 1) the preview form is undocked, i.e., not anchored to the Notepad++ application window
// 2) the WebView component gains focus, e.g., by clicking in the browser content area (WM_PARENTNOTIFY)
// 3) the WebView then loses focus, e.g., by clicking outside the parent form's border
function SafeWindowProc(Hndl: HWND; Msg: Cardinal; _WParam: WPARAM; _LParam: LPARAM): LRESULT; stdcall;
begin
  case Msg of
    WM_PARENTNOTIFY:
    begin
      if (frmHTMLPreview <> nil) then
      begin
        with frmHTMLPreview do
        begin
          Enabled := (GetAncestor(Handle, GA_ROOT) = Npp.NppData.NppHandle);
          if (not Enabled) then
            MessageBoxW(GetForegroundWindow(),
              PWChar('Preview controls are now locked! Move the panel to a docked position to unlock them.'),
              @WideString(Npp.GetName)[2],
              MB_ICONWARNING or MB_OK);
          pnlButtons.Enabled := Enabled;
        end;
      end;
      Result := 0;
    end else
      Result := DefWindowProcW(Hndl, Msg, _WParam, _lParam);
  end;
end;

{$ifdef FPC}
{$R *.lfm}
{$else}
{$R *.dfm}
{$endif}

{ ================================================================================================ }

constructor TfrmHTMLPreview.Create(AOwner: TComponent);
{$ifndef FPC}
var
  WinVerMajor, WinVerMinor, BuildNr: DWORD;
{$endif}
begin
  inherited;
{$ifndef FPC}
  if not IsAtLeastWindows11(WinVerMajor, WinVerMinor, BuildNr) then
    btnAbout.Margin := 4;
{$endif}
  self.Icon.Handle := LoadImage(Hinstance, 'TB_PREVIEW_HTML_ICO', IMAGE_ICON, 0, 0, (LR_DEFAULTSIZE or LR_LOADTRANSPARENT));
  self.NppDefaultDockingMask := (DWS_DF_CONT_RIGHT {$ifndef FPC} or DWS_USEOWNDARKMODE {$endif});
  with sbrIE.Panels.Add do begin
    Bevel := pbNone;
    Width := sbrIE.Width;
{$ifdef FPC}
    Style := psOwnerDraw;
{$endif}
  end;
end;

{ ------------------------------------------------------------------------------------------------ }
// VCL components respond poorly to subclassing; see, e.g.,
// https://stackoverflow.com/a/15664777
// https://forum.lazarus.freepascal.org/index.php?topic=22366.0
procedure TfrmHTMLPreview.ToggleDarkMode;
{$ifndef FPC}
begin
end;
{$else}
var
  Palette: TDarkModeColors;
begin
  inherited; // implicit call to SubclassAndTheme()
  if Npp.IsDarkModeEnabled then begin
    Npp.GetDarkModeColors(@Palette);
    sbrIE.Canvas.Brush.Color := TColor(Palette.Background);
  end else
    sbrIE.Canvas.Brush.Color := GetRGBColorResolvingParent;
end;

procedure TfrmHTMLPreview.SubclassAndTheme(DmfMask: Cardinal);
begin
  SendMessage(Npp.NppData.NppHandle, NPPM_DARKMODESUBCLASSANDTHEME, DmfMask, pnlButtons.Handle);
  SendMessage(Npp.NppData.NppHandle, NPPM_DARKMODESUBCLASSANDTHEME, DmfMask, sbrIE.Handle);
end;
{$endif}

procedure TfrmHTMLPreview.sbrIEDrawPanel(StatusBar: TStatusBar; Panel: TStatusPanel; const Rect: TRect);
var
  Palette: TDarkModeColors;
  H, X, Y: Integer;
begin
  StatusBar.Canvas.FillRect(Rect);
  StatusBar.Canvas.Font := StatusBar.Font;
  if Npp.IsDarkModeEnabled then begin
    Npp.GetDarkModeColors(@Palette);
    StatusBar.Canvas.Font.Color := TColor(Palette.DarkerText);
  end else
    StatusBar.Canvas.Font.Color := clWindowText;
  // https://forum.lazarus.freepascal.org/index.php/topic,60834.msg456446.html#msg456446
  H := StatusBar.Canvas.TextHeight(Panel.Text);
  Y := Rect.Top + (Rect.Height - H) div 2;
  X := Rect.Left + 2;
  StatusBar.Canvas.TextOut(X, Y, Panel.Text);
end;

{ ------------------------------------------------------------------------------------------------ }
procedure TfrmHTMLPreview.FormCreate(Sender: TObject);
begin
  FScrollPositions := TDictionary<TBufferID,TPoint>.Create;
  FPreserveScrollPosition := True;
  //self.KeyPreview := true; // special hack for input forms
  self.OnFloat := self.FormFloat;
  self.OnDock := self.FormDock;
  inherited;
  FBufferID := -1;
  ContentStream.Text := PLACEHOLDER_CONTENT;
  if GlobalWebView2Loader.InitializationError then
    MessageBoxW(0, @GlobalWebView2Loader.ErrorMessage[1], nil, MB_ICONERROR)
  else begin
    if GlobalWebView2Loader.Initialized then
      wbIE.CreateBrowser(wbHost.Handle);
  end;
  if (wbHost <> nil) then
    SetWindowLongPtr(wbHost.ChildWindowHandle, GWLP_WNDPROC, NativeInt(@SafeWindowProc));
end {TfrmHTMLPreview.FormCreate};
{ ------------------------------------------------------------------------------------------------ }
procedure TfrmHTMLPreview.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FScrollPositions);
  FreeAndNil(FFilterThread);
  WbHost.Browser.CoreWebView2Controller.Close;
  inherited;
end {TfrmHTMLPreview.FormDestroy};


{ ------------------------------------------------------------------------------------------------ }
procedure TfrmHTMLPreview.btnCloseStatusbarClick(Sender: TObject);
begin
  sbrIE.Visible := False;
end;

{ ------------------------------------------------------------------------------------------------ }
procedure TfrmHTMLPreview.tmrAutorefreshTimer(Sender: TObject);
begin
  tmrAutorefresh.Enabled := False;
  btnRefresh.Click;
end {TfrmHTMLPreview.tmrAutorefreshTimer};

{ ------------------------------------------------------------------------------------------------ }
procedure TfrmHTMLPreview.btnRefreshClick(Sender: TObject);
var
  BufferID: TBufferID;
  hScintilla: THandle;
  Lexer: NativeInt;
  IsHTML, IsXML, IsCustom: Boolean;
  Size: WPARAM;
  HTML: TUnicodeStreamString;
  FilterName: string;
  CodePage: NativeInt;
begin
  if chkFreeze.Checked then
    Exit;

  try
    tmrAutorefresh.Enabled := False;
ODS('FreeAndNil(FFilterThread);');
    FreeAndNil(FFilterThread);
    SaveScrollPos;
    ContentStream.Text := PLACEHOLDER_CONTENT;
    wbIE.ClearBrowsingData(COREWEBVIEW2_BROWSING_DATA_KINDS_BROWSING_HISTORY);

    BufferID := SendMessage(Self.Npp.NppData.NppHandle, NPPM_GETCURRENTBUFFERID, 0, 0);
    hScintilla := Npp.CurrentScintilla;

    Lexer := SendMessage(hScintilla, SCI_GETLEXER, 0, 0);
    IsHTML := (Lexer = SCLEX_HTML);
    IsXML := (Lexer = SCLEX_XML);

    Screen.Cursor := crHourGlass;
    try
      {--- MCO 22-01-2013: determine whether the current document matches a custom filter ---}
      FilterName := DetermineCustomFilter;
      IsCustom := Length(FilterName) > 0;

      {$MESSAGE HINT 'TODO: Find a way to communicate why there is no preview, depending on the situation — MCO 22-01-2013'}

      if IsXML or IsHTML or IsCustom then begin
        CodePage := SendMessage(hScintilla, SCI_GETCODEPAGE, 0, 0);
        Size := SendMessage(hScintilla, SCI_GETTEXT, 0, 0);
        Inc(Size);
        ContentStream.Size := Size;
        ContentStream.CodePage := CodePage;
        SendMessage(hScintilla, SCI_GETTEXT, Size, LPARAM(ContentStream.Data));
      end;

      HTML := ContentStream.Text;
      if IsCustom then begin
//MessageBox(Npp.NppData.NppHandle, PChar(Format('FilterName: %s', [FilterName])), 'PreviewHTML', MB_ICONINFORMATION);
        wbIEStatusTextChange(wbIE, WideFormat('Running filter %s...', [FilterName]));
        if ExecuteCustomFilter(FilterName, HTML, BufferID) then begin
          if Assigned(FScrollPositions) then
            FScrollPositions.Remove(BufferID);
          PrevTimerID := SetTimer(Handle, 0, 800, @PreviewRefreshTimer);
          Exit;
        end else begin
          wbIEStatusTextChange(wbIE, WideFormat('Failed filter %s...', [FilterName]));
          ContentStream.Text := '<pre style="color: darkred">ExecuteCustomFilter returned False</pre>';
        end;
      end else if IsXML then begin
        ContentStream.Text := TransformXMLToHTML(HTML);
      end;

      DisplayPreview(BufferID);
    finally
      Screen.Cursor := crDefault;
    end;
  except
    on E: Exception do begin
ODS('btnRefreshClick ### %s: %s', [E.ClassName, StringReplace(E.Message, sLineBreak, '', [rfReplaceAll])]);
      sbrIE.Panels[0].Text := E.Message;
      sbrIE.Visible := True;
    end;
  end;
end {TfrmHTMLPreview.btnRefreshClick};

{ ------------------------------------------------------------------------------------------------ }
procedure TfrmHTMLPreview.chkFreezeClick(Sender: TObject);
begin
  with btnRefresh do begin
    Enabled := not chkFreeze.Checked;
    UpdateNavButton(BtnNavBack, Enabled);
    UpdateNavButton(BtnNavForward, Enabled);
    if Enabled then
      Click;
  end;
end {TfrmHTMLPreview.chkFreezeClick};

{ ------------------------------------------------------------------------------------------------ }
procedure TfrmHTMLPreview.btnNavBackClick(Sender: TObject);
begin
  if wbIE <> nil then
  begin
    wbIE.GoBack;
    wbIE.ExecuteScript(SET_DEFAULT_BACKGROUND_JS);
  end;
end;

{ ------------------------------------------------------------------------------------------------ }
procedure TfrmHTMLPreview.btnNavForwardClick(Sender: TObject);
begin
  if wbIE <> nil then
  begin
    wbIE.GoForward;
    wbIE.ExecuteScript(SET_DEFAULT_BACKGROUND_JS);
  end;
end;

{ ------------------------------------------------------------------------------------------------ }
procedure TfrmHTMLPreview.DisplayPreview(const BufferID: TBufferID);
var
  IsHTML: Boolean;
  HeadStart: Integer;
  Size: WPARAM;
  Filename: nppString;
  HTML: TUniCodeStreamString;
  hScintilla: THandle;
begin
  try
    IsHTML := not WideSameText(ContentStream.Text, PLACEHOLDER_CONTENT);
    sbrIE.Visible := IsHTML and (Length(sbrIE.Panels[0].Text) > 0);
    if IsHTML then begin
      HTML := ContentStream.Text;
ODS('DisplayPreview(HTML: "%s"(%d); BufferID: %x)', [StringReplace(Copy({$ifdef FPC}UTF8Encode{$endif}(HTML), 1, 10), #13#10, '', [rfReplaceAll]), Length(HTML), BufferID]);
      Size := SendMessage(Self.Npp.NppData.NppHandle, NPPM_GETFULLPATHFROMBUFFERID, BufferID, LPARAM(nil));
      SetLength(Filename, Size);
      SetLength(Filename, SendMessage(Self.Npp.NppData.NppHandle, NPPM_GETFULLPATHFROMBUFFERID, BufferID, LPARAM(nppPChar(Filename))));
      if (Pos('<base ', HTML) = 0) and FileExists(Filename) then begin
        HeadStart := Pos('<head>', HTML);
        if HeadStart > 0 then
          Inc(HeadStart, 6)
        else
          HeadStart := 1;
        Insert('<base href="' + WideFormat('https://%s/%s', [APP_DOMAIN, ExtractFileName(Filename)]) + '" />', HTML, HeadStart);
        wbIE.SetVirtualHostNameToFolderMapping(APP_DOMAIN, ExtractFileDir(Filename), COREWEBVIEW2_HOST_RESOURCE_ACCESS_KIND_ALLOW);
        ContentStream.Text := HTML;
      end;

      if FEnsureRendered then begin
        ResetTimer;
        FEnsureRendered := False;
      end;

      {--- 2013-01-26 Martijn: the WebBrowser control has a tendency to steal the focus. We'll let
                                  the editor take it back. ---}
      hScintilla := Npp.CurrentScintilla;
      SendMessage(hScintilla, SCI_GRABFOCUS, 0, 0);
    end else begin
      self.UpdateDisplayInfo('');
    end;

    wbIE.NavigateToString(ContentStream.Text);

    if IsHTML then
    begin
      wbIE.ExecuteScript(SET_DEFAULT_BACKGROUND_JS);
      FBufferID := BufferID;
    end;
  except
    on E: Exception do begin
ODS('DisplayPreview ### %s: %s', [E.ClassName, StringReplace(E.Message, sLineBreak, '', [rfReplaceAll])]);
      sbrIE.Panels[0].Text := E.Message;
      sbrIE.Visible := True;
    end;
  end;
end {TfrmHTMLPreview.DisplayPreview};

{ ------------------------------------------------------------------------------------------------ }
function TfrmHTMLPreview.UpdatePreview(const BufferID: TBufferID): Boolean;
begin
  Result := FScrollPositions.ContainsKey(BufferID);
  if Result and (wbIE <> nil) then
    wbIE.ExecuteScript(WideFormat('document.body.innerHTML = "%s";', [JsonEncode(ContentStream.Text)]));
  SaveScrollPos;
end {TfrmHTMLPreview.UpdatePreview};

{ ------------------------------------------------------------------------------------------------ }
procedure TfrmHTMLPreview.wbIEExecuteScriptWithResultCompleted(Sender: TObject; ErrorCode: HResult;
  const AResult: ICoreWebView2ExecuteScriptResult; ExecutionID : integer);
var
  P: TPoint;
  JSResult: TCoreWebView2ExecuteScriptResult;
  JSResultString: wvstring;
  JSIntValue, ParseResult: LongInt;
  IsStringResult: boolean;
begin
  JSResultString := '';
  JSIntValue := -1;
  JSResult := TCoreWebView2ExecuteScriptResult.Create(aResult);
  try
    if JSResult.Initialized and JSResult.Succeeded_ then
    begin
      if JSResult.TryGetResultAsString(JSResultString, IsStringResult) then
      begin
        if ExecutionID = RESTORE_SCRIPT_ID then
          ODS('RestoreScrollPos: done!')
        else
        if IsStringResult then
        begin
          Val (JSResultString, JSIntValue, ParseResult);
          if (ParseResult = 0) and (JSIntValue > -1) then
          begin
            P.Y := JSIntValue shr 11;
            P.X := JSIntValue and $000007ff;
            FScrollPositions.AddOrSetValue(FBufferID, P);
            RestoreScrollPos;
            ODS('SaveScrollPos[%x]: %dx%d', [FBufferID, P.X, P.Y]);
          end else
          begin
            FScrollPositions.Remove(FBufferID);
            ODS('SaveScrollPos[%x]: --', [FBufferID]);
          end;
        end;
      end;
    end;
  finally
    JSResult.Free
  end;
end;

{ ------------------------------------------------------------------------------------------------ }
procedure TfrmHTMLPreview.wbIEMoveFocusRequested(ASender: TObject; const AController: ICoreWebView2Controller;
  const Args: ICoreWebView2MoveFocusRequestedEventArgs);
var
  Reason: COREWEBVIEW2_MOVE_FOCUS_REASON;
begin
  Args.Get_reason(Reason);
  case Reason of
    COREWEBVIEW2_MOVE_FOCUS_REASON_NEXT: btnRefresh.SetFocus;
    COREWEBVIEW2_MOVE_FOCUS_REASON_PREVIOUS:  btnClose.SetFocus;
  end;
  Args.Set_Handled($00000001);
end;

{ ------------------------------------------------------------------------------------------------ }
procedure TfrmHTMLPreview.wbIENavigationStarting(ASender: TObject; const AWebView: ICoreWebView2;
  const Args: ICoreWebView2NavigationStartingEventArgs);
var
  EventArgs : TCoreWebView2NavigationStartingEventArgs;
begin
  try
    EventArgs := TCoreWebView2NavigationStartingEventArgs.Create(Args);
    if (EventArgs.NavigationKind = COREWEBVIEW2_NAVIGATION_KIND_BACK_OR_FORWARD) and
      WideSameText('data:text/html', Copy(EventArgs.Uri, 0, 14)) then
    begin
      FScrollPositions.Remove(FBufferID);
      PrevTimerID := SetTimer(Handle, 0, 100, @PreviewRefreshTimer);
    end;
  finally
    FreeAndNil(EventArgs);
  end;
end;

{ ------------------------------------------------------------------------------------------------ }
procedure TfrmHTMLPreview.SaveScrollPos;
const
  JS = '(() => {' +
        'let doc = Array.prototype.slice.call(document.getElementsByTagName("html"))[0];' +
        'return (doc) ? `${(parseInt(doc.scrollTop) << 11) | parseInt(doc.scrollLeft)}` : `${-1}`;' +
    '})();';
begin
  if (not FPreserveScrollPosition) or (FBufferID = -1) then
    Exit;

  if (wbIE <> nil) then
    wbIE.ExecuteScriptWithResult(JS);
end {TfrmHTMLPreview.SaveScrollPos};

{ ------------------------------------------------------------------------------------------------ }
procedure TfrmHTMLPreview.RestoreScrollPos;
const
  JS = 'window.setTimeout(() => {' +
      'let doc = Array.prototype.slice.call(document.getElementsByTagName("html"))[0];' +
      'if (doc) { doc.scroll(%d, %d); }' +
    '}, 0);';
var
  P: TPoint;
begin
  {--- MCO 22-01-2013: Look up this buffer's scroll position; if we know one, wait for the page
                          to finish loading, then restore the scroll position. ---}
  if FScrollPositions.TryGetValue(FBufferID, P) then begin
    ODS('RestoreScrollPos[%x]: %dx%d', [FBufferID, P.X, P.Y]);
    if (wbIE <> nil) then
      wbIE.ExecuteScriptWithResult(WideFormat(JS, [P.X, P.Y]), RESTORE_SCRIPT_ID);
  end else begin
    ODS('RestoreScrollPos[%x]: --', [FBufferID]);
  end;
end {TfrmHTMLPreview.RestoreScrollPos};

{ ------------------------------------------------------------------------------------------------ }
procedure TfrmHTMLPreview.ForgetBuffer(const BufferID: TBufferID);
begin
  if FBufferID = BufferID then
    FBufferID := -1;
  if Assigned(FScrollPositions) then begin
    FScrollPositions.Remove(BufferID);
  end;
  ResetTimer;
end {TfrmHTMLPreview.ForgetBuffer};

{ ------------------------------------------------------------------------------------------------ }
procedure TfrmHTMLPreview.ReloadSettings;
begin
  with TNppPluginPreviewHTML(Npp).GetSettings() do begin
    FPreserveScrollPosition := ReadBool('Scroll', 'Sticky', True);
    tmrAutorefresh.Interval := ReadInteger('Autorefresh', 'Interval', tmrAutorefresh.Interval);
    Free;
  end;
end {TfrmHTMLPreview.ReloadSettings};

{ ------------------------------------------------------------------------------------------------ }
procedure TfrmHTMLPreview.ResetTimer;
begin
  tmrAutorefresh.Enabled := False;
  tmrAutorefresh.Enabled := True;
end {TfrmHTMLPreview.ResetTimer};

{ ------------------------------------------------------------------------------------------------ }
function TfrmHTMLPreview.DetermineCustomFilter: string;
var
  DocFileName: nppString;
  Filters: TUtf8IniFile;
  Names: TStringList;
  i: Integer;
  Match: Boolean;
  Ext, Language, DocLanguage: string;
  DocLangType, LangType: Integer;
  Extensions: TStringList;
  Filespec: string;
begin
  DocFileName := Npp.GetCurrentBufferPath;

  DocLangType := -1;
  DocLanguage := '';
  Result := String.Empty;

  ForceDirectories(TNppPluginPreviewHTML(Npp).ConfigDir + '\PreviewHTML');
  Filters := TUtf8IniFile.Create(TNppPluginPreviewHTML(Npp).ConfigDir + '\PreviewHTML\Filters.ini');
  Names := TStringList.Create;
  try
    Filters.ReadSections(Names);
    for i := 0 to Names.Count - 1 do begin
      {--- 2013-02-15 Martijn: empty filters should be skipped, and
                      any filter can be disabled by putting a '-' in front of its name. ---}
      if (Length(Names[i]) = 0) or (Names[i][1] = '-') then
        Continue;

      Match := False;

      {--- Martijn 03-03-2013: Test file name ---}
      Filespec := Trim(Filters.ReadString(Names[i], 'Filename', ''));
      if (Filespec <> '') then begin
        // http://docwiki.embarcadero.com/Libraries/XE2/en/System.Masks.MatchesMask#Description
        Match := Match or MatchesMask({$ifdef FPC}UTF8Encode{$endif}(ExtractFileName(DocFileName)), Filespec);
      end;

      {--- MCO 22-01-2013: Test extension ---}
      Ext := Trim(Filters.ReadString(Names[i], 'Extension', ''));
      if (Ext <> '') then begin
        Extensions := TStringList.Create;
        try
          Extensions.CaseSensitive := False;
          Extensions.Delimiter := ',';
          Extensions.DelimitedText := Ext;
          Match := Match or (Extensions.IndexOf({$ifdef FPC}UTF8Encode{$endif}(ExtractFileExt(DocFileName))) > -1);
        finally
          Extensions.Free;
        end;
      end;

      {--- MCO 22-01-2013: Test highlighter language ---}
      Language := Filters.ReadString(Names[i], 'Language', '');
      if Language <> '' then begin
        if DocLangType = -1 then begin
          SendMessage(Npp.NppData.NppHandle, NPPM_GETCURRENTLANGTYPE, WPARAM(0), LPARAM(@DocLangType));
        end;
        if DocLangType > -1 then begin
          if TryStrToInt(Language, LangType) and (LangType = DocLangType) then begin
            Match := True;
          end else begin
            if DocLanguage = '' then begin
              SetLength(DocLanguage, SendMessage(Npp.NppData.NppHandle, NPPM_GETLANGUAGENAME, WPARAM(DocLangType), LPARAM(nil)));
              SetLength(DocLanguage, SendMessage(Npp.NppData.NppHandle, NPPM_GETLANGUAGENAME, WPARAM(DocLangType), LPARAM(PChar(DocLanguage))));
            end;
            if SameText(Language, DocLanguage) then begin
              Match := True;
            end;
          end;
        end;
      end;

      {$MESSAGE HINT 'TODO: Test lexer — MCO 22-01-2013'}

      if Match then
        SetString(Result, PChar(Names[i]), Length(Names[i]));
    end;
  finally
    Names.Free;
    Filters.Free;
  end;
end {TfrmHTMLPreview.DetermineCustomFilter};

{ ------------------------------------------------------------------------------------------------ }
function TfrmHTMLPreview.ExecuteCustomFilter(const FilterName: string; const HTML: wvstring; const BufferID: TBufferID): Boolean;
var
  FilterData: TFilterData;
  DocFile: TFileName;
  hScintilla: THandle;
  Filters: TUtf8IniFile;
  BufferEncoding: NativeInt;
begin
  FilterData.Name := FilterName;
  FilterData.BufferID := BufferID;

  DocFile := Npp.GetCurrentBufferPath;
  FilterData.DocFile := DocFile;
  FilterData.Contents := HTML;

  hScintilla := Npp.CurrentScintilla;
  BufferEncoding := SendMessage(Npp.NppData.NppHandle, NPPM_GETBUFFERENCODING, BufferID, 0);
  case BufferEncoding of
    1, 4: FilterData.Encoding := TEncoding.UTF8;
    2, 6: FilterData.Encoding := TEncoding.BigEndianUnicode;
    3, 7: FilterData.Encoding := TEncoding.Unicode;
    5:    FilterData.Encoding := TEncoding.UTF7;
    else  FilterData.Encoding := TEncoding.ANSI;
  end;
  FilterData.UseBOM := False; // BufferEncoding in [1, 2, 3];
  FilterData.Modified := SendMessage(hScintilla, SCI_GETMODIFY, 0, 0) <> 0;

  Filters := TNppPluginPreviewHTML(Npp).GetSettings('Filters.ini');
  try
    FilterData.FilterInfo := TStringList.Create;
    Filters.ReadSectionValues(FilterName, FilterData.FilterInfo);
  finally
    Filters.Free;
  end;

  FilterData.OnTerminate := FilterThreadTerminate;

  {--- 2013-01-26 Martijn: Create a new TCustomFilterThread ---}
  FFilterThread := TCustomFilterThread.Create(FilterData);
  Result := Assigned(FFilterThread);
end {TfrmHTMLPreview.ExecuteCustomFilter};

{ ------------------------------------------------------------------------------------------------ }
procedure TfrmHTMLPreview.FilterThreadTerminate(Sender: TObject);
begin
ODS('FilterThreadTerminate');
if (Sender as TThread).FatalException is Exception then
begin
  ODS('Fatal %s: "%s"', [((Sender as TThread).FatalException as Exception).ClassName, ((Sender as TThread).FatalException as Exception).Message]);
end else
begin
   PrevTimerID := SetTimer(Handle, 0, tmrAutorefresh.Interval, @PreviewRefreshTimer);
end;
  FFilterThread := nil;
end {TfrmHTMLPreview.FilterThreadTerminate};


{ ------------------------------------------------------------------------------------------------ }
procedure TfrmHTMLPreview.btnAboutClick(Sender: TObject);
const
  WikiPage = 'https://github.com/rdipardo/npp_preview/wiki';
begin
  if (not GlobalWebView2Loader.InitializationError) and (wbIE <> nil) then begin
    wbIE.Navigate(WikiPage)
  end else
    ShellAPI.ShellExecute(Self.Handle, 'Open', @WikiPage[1], Nil, Nil, SW_SHOWNORMAL);
end {TfrmHTMLPreview.btnAboutClick};

{ ------------------------------------------------------------------------------------------------ }
procedure TfrmHTMLPreview.btnCloseClick(Sender: TObject);
begin
  self.Hide;
end {TfrmHTMLPreview.btnCloseClick};

{ ------------------------------------------------------------------------------------------------ }
// special hack for input forms
// This is the best possible hack I could came up for
// memo boxes that don't process enter keys for reasons
// too complicated... Has something to do with Dialog Messages
// I sends a Ctrl+Enter in place of Enter
procedure TfrmHTMLPreview.FormKeyPress(Sender: TObject;
  var Key: Char);
begin
//  if (Key = #13) and (self.Memo1.Focused) then self.Memo1.Perform(WM_CHAR, 10, 0);
end;

{ ------------------------------------------------------------------------------------------------ }
// Docking code calls this when the form is hidden by either "x" or self.Hide
procedure TfrmHTMLPreview.FormHide(Sender: TObject);
begin
  SaveScrollPos;
  SendMessage(self.Npp.NppData.NppHandle, NPPM_SETMENUITEMCHECK, self.CmdID, 0);
  self.Visible := False;
end;

{ ------------------------------------------------------------------------------------------------ }
procedure TfrmHTMLPreview.FormDock(Sender: TObject);
begin
  Enabled := True;
  pnlButtons.Enabled := True;
  ResetTimer;
end;

{ ------------------------------------------------------------------------------------------------ }
procedure TfrmHTMLPreview.FormFloat(Sender: TObject);
begin
  ResetTimer;
end;

{ ------------------------------------------------------------------------------------------------ }
procedure TfrmHTMLPreview.FormShow(Sender: TObject);
begin
  inherited;
  ToggleDarkMode;
  ReloadSettings;
  SendMessage(self.Npp.NppData.NppHandle, NPPM_SETMENUITEMCHECK, self.CmdID, 1);
  if wbIE.IsSuspended then
    wbIE.Resume;
  FEnsureRendered := True;
  ResetTimer;
end;

{ ------------------------------------------------------------------------------------------------ }
function TfrmHTMLPreview.TransformXMLToHTML(const XML: WideString): WideString;
  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  function CreateDOMDocument: OleVariant;
  var
    RegKey: TRegistry;
    RegValues: TStringList;
    I: Integer;
    nVersion: Integer;
  begin
    VarClear(Result);
    RegValues := TStringList.Create;
    RegKey := TRegistry.Create;
    try
      RegKey.RootKey := HKEY_CLASSES_ROOT;
      if RegKey.OpenKeyReadOnly('CLSID\{2933BF90-7B36-11D2-B20E-00C04F983E60}\VersionList') then
        RegKey.GetValueNames(RegValues);
      if RegValues.Count <> 0 then begin
        for i := RegValues.Count - 1 downto 0 do
        begin
          Result := CreateOleObject(Format('MSXML2.DOMDocument.%s', [RegValues[i]]));
          if not VarIsClear(Result) and TryStrToInt(Copy(RegValues[i], 1, 1), nVersion) then
            Break;
        end;
      end;
      try
        if not VarIsClear(Result) then begin
          if nVersion >= 4 then begin
            Result.setProperty('NewParser', True);
          end;
          if nVersion >= 6 then begin
            Result.setProperty('AllowDocumentFunction', True);
            Result.setProperty('AllowXsltScript', True);
            Result.setProperty('ResolveExternals', True);
            Result.setProperty('UseInlineSchema', True);
            Result.setProperty('ValidateOnParse', False);
          end;
        end;
      except
        VarClear(Result);
      end;
    finally
      RegKey.Free;
      RegValues.Free;
    end;
  end {CreateDOMDocument};
  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
var
  bMethodHTML: Boolean;
  xDoc, xPI, xStylesheet, xOutput: OleVariant;
  rexHref: TRegExpr;
begin
  Result := PLACEHOLDER_CONTENT;
  try
    try
      {--- MCO 30-05-2012: Check to see if there's an xml-stylesheet to convert the XML to HTML. ---}
      xDoc := CreateDOMDocument;
      if VarIsClear(xDoc) then Exit;
      if not xDoc.LoadXML(XML) then Exit;

      xPI := xDoc.selectSingleNode('//processing-instruction("xml-stylesheet")');
      if VarIsClear(xPI) then Exit;

      rexHref := TRegExpr.Create;
      try
        rexHref.ModifierI := False;
        rexHref.Expression := '(^|\s+)href=["'']([^"'']*?)["'']';
        if not rexHref.Exec(xPI.nodeValue) then Exit;

        xStylesheet := CreateDOMDocument;
        if not xStylesheet.Load(rexHref.Match[2]) then Exit;
      finally
        rexHref.Free;
      end;

      bMethodHTML := SameText(xDoc.documentElement.nodeName, 'html');
      if not bMethodHTML then begin
        xStylesheet.setProperty('SelectionNamespaces', 'xmlns:xsl="http://www.w3.org/1999/XSL/Transform"');
        xOutput := xStylesheet.selectSingleNode('/*/xsl:output');
        if VarIsClear(xOutput) then
          Exit;

        bMethodHTML := SameStr(VarToStrDef(xOutput.getAttribute('method'), 'xml'), 'html');
      end;
      if not bMethodHTML then Exit;

      Result := xDoc.transformNode(xStylesheet.documentElement);
    except
      on E: Exception do begin
        {--- MCO 30-05-2012: Ignore any errors; we weren't able to perform the transformation ---}
        Result := WideFormat('<html><title>Error transforming XML to HTML</title><body><pre style="color: red">%s</pre></body></html>',
          [StringReplace(E.Message, '<', '&lt;', [rfReplaceAll])]);
      end;
    end;
  finally
    VarClear(xOutput);
    VarClear(xStylesheet);
    VarClear(xPI);
    VarClear(xDoc);
  end;
end {TfrmHTMLPreview.TransformXMLToHTML};

{ ------------------------------------------------------------------------------------------------ }
procedure TfrmHTMLPreview.UpdateNavButton(var ABtn: TBitBtn; NewState: Boolean);
begin
  ABtn.Enabled := NewState;
  ABtn.ShowHint := NewState;
end;

{ ------------------------------------------------------------------------------------------------ }
procedure TfrmHTMLPreview.wbIEStatusBar(ASender: TObject; const aWebView: ICoreWebView2);
begin
  wbIEStatusTextChange(ASender, TWVBrowser(ASender).StatusBarText);
end;

{ ------------------------------------------------------------------------------------------------ }
procedure TfrmHTMLPreview.wbIEStatusTextChange(ASender: TObject; const Text: WideString);
begin
  sbrIE.Panels[0].Text := {$ifdef FPC}UTf8Encode{$endif}(Text);
  sbrIE.Visible := Length(Text) > 0;
  if sbrIE.Visible then
  sbrIE.Invalidate;
end;

{ ------------------------------------------------------------------------------------------------ }
procedure TfrmHTMLPreview.wbIETitleChange(ASender: TObject);
var
  DocTitle: wvString;
begin
  DocTitle := wbIE.DefaultURL;
  if not WideSameText('data:text/html', Copy(wbIE.DocumentTitle, 0, 14)) then
     DocTitle := wbIE.DocumentTitle;
  self.UpdateDisplayInfo({$ifdef FPC}UTF8Encode{$endif}(DocTitle));
end;

{ ------------------------------------------------------------------------------------------------ }
procedure TfrmHTMLPreview.wbIENavigationHistoryChange(ASender: TObject);
begin
  if wbIE <> nil then begin
    UpdateNavButton(BtnNavBack, wbIE.CanGoBack);
    UpdateNavButton(BtnNavForward, wbIE.CanGoForward);
  end;
end;

{ ------------------------------------------------------------------------------------------------ }
procedure TfrmHTMLPreview.wbIEInitializationError(ASender: TObject;
  ErrorCode: HRESULT; const ErrorMessage: wvstring);
begin
  MessageBoxW(0, @ErrorMessage[1], PWChar(WideFormat('Error: %d', [ErrorCode])), MB_ICONERROR);
end;

{ ------------------------------------------------------------------------------------------------ }
procedure TfrmHTMLPreview.wbIEAfterCreated(ASender: TObject);
begin
  wbHost.UpdateSize;
  // wbHost.SetFocus; //< will hang on float!
  PrevTimerID := SetTimer(Handle, 0, 800, @PreviewRefreshTimer);
end;

procedure TfrmHTMLPreview.WMMove(var AMessage : TWMMove);
var
  M: TMessage;
begin
  inherited;
  with M do
  begin
    Msg := AMessage.Msg;
    lParamlo := AMessage.XPos;
    lParamhi := AMessage.YPos;
  end;
  WMMoving(M);
end;

procedure TfrmHTMLPreview.WMMoving(var AMessage : TMessage);
begin
  inherited;
  if (wbIE <> nil) then
    wbIE.NotifyParentWindowPositionChanged;
end;

{$ifdef FPC}
procedure TfrmHTMLPreview.HandleCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  wbIE.TrySuspend;
  inherited;
end;
{$endif}

////////////////////////////////////////////////////////////////////////////////////////////////////
initialization
  ContentStream := TUnicodeStream.Create;

finalization
  FreeAndNil(ContentStream);
  if Assigned(frmHTMLPreview) then
    KillTimer(frmHTMLPreview.Handle, frmHTMLPreview.PrevTimerID);

end.
