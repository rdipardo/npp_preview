unit F_wvPreview;

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
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Generics.Collections,
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
  extensions,
  U_CustomFilter;

type
  TBufferID = NativeInt;

  TFrmWebView2Preview = class(TNppDockingForm)
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
    FSciDirectPtr: HWND;
    FSciDirectFunc: TScintillaMessageFnc;
    FScrollPositions: TDictionary<TBufferID,TPoint>;
    FFilterThread: TCustomFilterThread;
    FRemoteAssets: TStringList;
    FDefaultStyleSheet, FDefaultScript: wvString;
    FHasDefaultStyle, FHasDefaultScript: Boolean;
    FEnsureRendered: Boolean;
    FReloadDOM: Boolean;
    FPreserveScrollPosition: Boolean;
    FRenderMarkdown: Boolean;
    FRenderWireloom: Boolean;

    procedure SaveScrollPos;
    procedure RestoreScrollPos;
    procedure GetDirectFunction;
    procedure UpdateNavButton(var ABtn: TBitBtn; NewState: Boolean);

    function  DetermineCustomFilter: string;
    function  ExecuteCustomFilter(const FilterName: string; const HTML: wvstring; const BufferID: TBufferID): Boolean;

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
    property  ReloadDOM: Boolean write FReloadDOM;
{$ifdef FPC}
    procedure SubclassAndTheme(DmfMask: Cardinal); override;
    procedure HandleCloseQuery({%H-}Sender: TObject; {%H-}var CanClose: Boolean); override;
{$endif}
  protected
    procedure WMMove({%H-}var AMessage : TWMMove); message WM_MOVE;
    procedure WMMoving({%H-}var AMessage : TMessage); message WM_MOVING;
  end;

var
  frmWV2Preview: TFrmWebView2Preview;

////////////////////////////////////////////////////////////////////////////////////////////////////
implementation
uses
  StrUtils, Masks,
  RegExpr,
  ShellAPI,
  Debug,
{$ifndef FPC}
  F_About,
{$endif}
  U_Npp_PreviewHTML;

const
  APP_DOMAIN = 'preview.host';
  ASSET_DOMAIN = 'preview.static';
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
  INJECT_USER_STYLE = 'window.setTimeout(() => {' +
    ' if (Array.prototype.slice.call(document.styleSheets).length > 0) {' +
    '   return;' +
    ' }' +
    ' try {' +
    '   let style = document.createElement("link");' +
    '   let node = document.querySelector("base") || document.head.firstElementChild;' +
    '   style.rel = "stylesheet";' +
    '   style.href = "%s";' +
    '   node.after(style);'+
    ' } catch (_) { }' +
    '}, 0);';
  INJECT_USER_SCRIPT = 'window.setTimeout(() => {' +
    ' try {' +
    '   let js = document.createElement("script");' +
    '   js.src = "%s";' +
    '   js.defer = true;' +
    '   document.body.insertAdjacentElement("beforeend", js);' +
    ' } catch (_) { }' +
    '}, 0);';
  INJECT_3RD_PARTY_SCRIPT = 'window.setTimeout(() => {' +
    ' try {' +
    '   let js = document.createElement("script");' +
    '   js.src = "https://cdn.jsdelivr.net/npm/%s";' +
    '   js.defer = true;' +
    '   js.onload = (e) => {' +
    '       if (/(katex).*\/auto\-render(\.min)?\.js$/i.test(e.target.src))' +
    '         renderMathInElement(document.body);' +
    '       };' +
    '   document.head.insertAdjacentElement("beforeend", js);' +
    ' } catch (_) { }' +
    '}, 0);';

procedure PreviewRefreshTimer(WndHandle: HWND; Msg: UINT; EventID: UINT; TimeMS: UINT); stdcall;
begin
  if Assigned(frmWV2Preview) then
  begin
    frmWV2Preview.btnRefresh.Click;
    KillTimer(frmWV2Preview.Handle, EventID);
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
      if (frmWV2Preview <> nil) then
      begin
        with frmWV2Preview do
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

constructor TFrmWebView2Preview.Create(AOwner: TComponent);
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
procedure TFrmWebView2Preview.ToggleDarkMode;
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

  ReloadSettings;
  FReloadDOM := True;
  BtnRefresh.Click;
end;

procedure TFrmWebView2Preview.SubclassAndTheme(DmfMask: Cardinal);
begin
  SendMessage(Npp.NppData.NppHandle, NPPM_DARKMODESUBCLASSANDTHEME, DmfMask, pnlButtons.Handle);
  SendMessage(Npp.NppData.NppHandle, NPPM_DARKMODESUBCLASSANDTHEME, DmfMask, sbrIE.Handle);
end;
{$endif}

procedure TFrmWebView2Preview.sbrIEDrawPanel(StatusBar: TStatusBar; Panel: TStatusPanel; const Rect: TRect);
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
procedure TFrmWebView2Preview.FormCreate(Sender: TObject);
begin
  FScrollPositions := TDictionary<TBufferID,TPoint>.Create;
  FRemoteAssets := TStringList.Create;
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
end {TFrmWebView2Preview.FormCreate};
{ ------------------------------------------------------------------------------------------------ }
procedure TFrmWebView2Preview.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FScrollPositions);
  FreeAndNil(FRemoteAssets);
  FreeAndNil(FFilterThread);
  WbHost.Browser.CoreWebView2Controller.Close;
  inherited;
end {TFrmWebView2Preview.FormDestroy};


{ ------------------------------------------------------------------------------------------------ }
procedure TFrmWebView2Preview.btnCloseStatusbarClick(Sender: TObject);
begin
  sbrIE.Visible := False;
end;

{ ------------------------------------------------------------------------------------------------ }
procedure TFrmWebView2Preview.tmrAutorefreshTimer(Sender: TObject);
begin
  tmrAutorefresh.Enabled := False;
  btnRefresh.Click;
end {TFrmWebView2Preview.tmrAutorefreshTimer};

{ ------------------------------------------------------------------------------------------------ }
procedure TFrmWebView2Preview.btnRefreshClick(Sender: TObject);
  function HasFileExt (const exts: array of nppString; BuffID: TBufferID): Boolean;
  var I: Integer;
  begin
    Result := False;
    for I:=0 to Length(exts) - 1 do
    begin
      if WideSameText(exts[i], Npp.GetCurrentFileExt(BuffID)) then
      begin
        Result := True;
        Break;
      end;
    end;
  end;
var
  BufferID: TBufferID;
  Lexer: TNppLang;
  IsHTML, IsXML, IsCustom, IsMarkdown, IsWireloom: Boolean;
  DarkTheme, PreserveDOM: Boolean;
  Size: WPARAM;
  HTML, PlainText: TUnicodeStreamString;
  FilterName: string;
  BufferName: array[0..MAX_PATH] of nppChar;
  CodePage: NativeInt;
begin
  if chkFreeze.Checked then
    Exit;

  try
    tmrAutorefresh.Enabled := False;
    PreserveDOM := False;
ODS('FreeAndNil(FFilterThread);');
    FreeAndNil(FFilterThread);
    SaveScrollPos;
    GetDirectFunction;
    ContentStream.Text := PLACEHOLDER_CONTENT;
    wbIE.ClearBrowsingData(COREWEBVIEW2_BROWSING_DATA_KINDS_BROWSING_HISTORY);

    BufferID := SendMessage(Self.Npp.NppData.NppHandle, NPPM_GETCURRENTBUFFERID, 0, 0);

    Lexer := TNppPluginPreviewHTML(Npp).FileType;
    IsHTML := Lexer in [ L_HTML, L_PHP, L_ASP, L_JSP ];
    IsXML := (Lexer = L_XML);

    Screen.Cursor := crHourGlass;
    try
      {--- MCO 22-01-2013: determine whether the current document matches a custom filter ---}
      FilterName := DetermineCustomFilter;
      IsCustom := Length(FilterName) > 0;
      IsWireloom := FRenderWireloom and HasFileExt(['.wireloom'], BufferID);
      IsMarkdown := (not IsCustom) and FRenderMarkdown and
        HasFileExt(['.markdown','.md','.mkd','.mkdn','.mdwn','.mdown','.mdoc','.mdtext','.mdtxt'], BufferID);

      {$MESSAGE HINT 'TODO: Find a way to communicate why there is no preview, depending on the situation — MCO 22-01-2013'}

      if IsXML or IsHTML or IsCustom or IsMarkdown or IsWireloom then begin
        CodePage := FSciDirectFunc(FSciDirectPtr, SCI_GETCODEPAGE, 0, 0);
        Size := FSciDirectFunc(FSciDirectPtr, SCI_GETTEXT, 0, 0);
        Inc(Size);
        ContentStream.Size := Size;
        ContentStream.CodePage := CodePage;
        FSciDirectFunc(FSciDirectPtr, SCI_GETTEXT, Size, LPARAM(ContentStream.Data));
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
      end else if IsMarkdown or IsWireloom then begin
        SendMessage(Self.Npp.NppData.NppHandle, NPPM_GETNAMEPART, MAX_PATH, LPARAM(@BufferName[0]));
        PlainText := Copy(HTML, 0, Length(HTML) - Length(TUnicodeStreamString(#$0000)));
        // TODO: Determine exactly which remote scripts need reloading to work (e.g., MathJax, KaTeX)
        PreserveDOM := (not FReloadDOM) and (FRemoteAssets.Count = 0) and FScrollPositions.ContainsKey(BufferID);
        DarkTheme := Npp.IsDarkModeEnabled;
        if not PreserveDOM then begin
          if IsWireloom then
            ContentStream.Text := Renderwireloom(PlainText, BufferName, DarkTheme)
          else if IsMarkdown then
            ContentStream.Text := RenderMarkdown(PlainText, BufferName, DarkTheme);
          FReloadDOM := False;
        end else begin
          if IsWireloom then
            wbIE.ExecuteScript(PrepareWLScript(PlainText, DarkTheme))
          else if IsMarkdown then begin
            wbIE.ExecuteScript(PrepareMDScript(PlainText));
            wbIE.ExecuteScript(PrepareCodeBlockScript(WL_CODE_BLOCK_CLASS, GetThemeName(DarkTheme)));
          end;
        end;
      end;

      if not PreserveDOM then
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
end {TFrmWebView2Preview.btnRefreshClick};

{ ------------------------------------------------------------------------------------------------ }
procedure TFrmWebView2Preview.chkFreezeClick(Sender: TObject);
begin
  with btnRefresh do begin
    Enabled := not chkFreeze.Checked;
    UpdateNavButton(BtnNavBack, Enabled);
    UpdateNavButton(BtnNavForward, Enabled);
    if Enabled then
      Click;
  end;
end {TFrmWebView2Preview.chkFreezeClick};

{ ------------------------------------------------------------------------------------------------ }
procedure TFrmWebView2Preview.btnNavBackClick(Sender: TObject);
begin
  if wbIE <> nil then
  begin
    wbIE.GoBack;
    wbIE.ExecuteScript(SET_DEFAULT_BACKGROUND_JS);
  end;
end;

{ ------------------------------------------------------------------------------------------------ }
procedure TFrmWebView2Preview.btnNavForwardClick(Sender: TObject);
begin
  if wbIE <> nil then
  begin
    wbIE.GoForward;
    wbIE.ExecuteScript(SET_DEFAULT_BACKGROUND_JS);
  end;
end;

{ ------------------------------------------------------------------------------------------------ }
procedure TFrmWebView2Preview.DisplayPreview(const BufferID: TBufferID);
var
  IsHTML: Boolean;
  HeadStart: Integer;
  Size: WPARAM;
  Filename, AssetURL: nppString;
  HTML: TUniCodeStreamString;
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
        if FHasDefaultStyle or FHasDefaultScript then
          wbIE.SetVirtualHostNameToFolderMapping(ASSET_DOMAIN,
            TNppPluginPreviewHTML(Npp).AssetDir, COREWEBVIEW2_HOST_RESOURCE_ACCESS_KIND_ALLOW);
        if FRenderMarkdown or FRenderWireloom then
          wbIE.SetVirtualHostNameToFolderMapping(EXT_DOMAIN,
            TNppPluginPreviewHTML(Npp).ExtAssetDir, COREWEBVIEW2_HOST_RESOURCE_ACCESS_KIND_ALLOW);
        ContentStream.Text := HTML;
      end;

      if FEnsureRendered then begin
        ResetTimer;
        FEnsureRendered := False;
      end;

      {--- 2013-01-26 Martijn: the WebBrowser control has a tendency to steal the focus. We'll let
                                  the editor take it back. ---}

      // A direct function SHOULD NOT be used here because this method may be
      // called from a different thread (via `TCustomFilterThread.DoSynchronize`);
      // see https://www.scintilla.org/ScintillaDoc.html#DirectAccess
      SendMessage(Npp.CurrentScintilla, SCI_GRABFOCUS, 0, 0);
    end else begin
      self.UpdateDisplayInfo('');
    end;

    wbIE.NavigateToString(ContentStream.Text);

    if IsHTML then
    begin
      wbIE.ExecuteScript(SET_DEFAULT_BACKGROUND_JS);
      if FRemoteAssets.Count > 0 then begin
        for HeadStart := 0 to FRemoteAssets.Count - 1 do begin
          AssetURL := {$ifdef FPC}UTF8ToString{$endif}(FRemoteAssets.Strings[HeadStart]);
          if WideSameText(RightStr(AssetURL, 4), '.css') then
            wbIE.ExecuteScript(WideFormat(INJECT_USER_STYLE,
              [WideFormat('https://cdn.jsdelivr.net/npm/%s', [AssetURL])]))
          else if (PosEx('auto-render', AssetURL, Pos('katex', AssetURL)) <> 0) then
            // Ensure KaTeX library has time to load before the auto-render script
            wbIE.ExecuteScript(WideFormat('window.setTimeout(() => { %s }, 800)',
              [WideFormat({$ifdef FPC}WideStringReplace{$else}StringReplace{$endif}(
                INJECT_3RD_PARTY_SCRIPT, 'defer = true', 'defer = false', []), [AssetURL])]))
          else
            wbIE.ExecuteScript(WideFormat(INJECT_3RD_PARTY_SCRIPT, [AssetURL]));
        end;
      end;
      if FHasDefaultStyle then
        wbIE.ExecuteScript(WideFormat(INJECT_USER_STYLE,
          [WideFormat('https://%s/%s', [ASSET_DOMAIN, ExtractFileName(FDefaultStyleSheet)])]));
      if FHasDefaultScript then
        wbIE.ExecuteScript(WideFormat(INJECT_USER_SCRIPT,
          [WideFormat('https://%s/%s', [ASSET_DOMAIN, ExtractFileName(FDefaultScript)])]));
      FBufferID := BufferID;
    end;
  except
    on E: Exception do begin
ODS('DisplayPreview ### %s: %s', [E.ClassName, StringReplace(E.Message, sLineBreak, '', [rfReplaceAll])]);
      sbrIE.Panels[0].Text := E.Message;
      sbrIE.Visible := True;
    end;
  end;
end {TFrmWebView2Preview.DisplayPreview};

{ ------------------------------------------------------------------------------------------------ }
function TFrmWebView2Preview.UpdatePreview(const BufferID: TBufferID): Boolean;
begin
  Result := FScrollPositions.ContainsKey(BufferID);
  if Result and (wbIE <> nil) then
    wbIE.ExecuteScript(WideFormat('document.body.innerHTML = "%s";', [JsonEncode(ContentStream.Text)]));
  SaveScrollPos;
end {TFrmWebView2Preview.UpdatePreview};

{ ------------------------------------------------------------------------------------------------ }
procedure TFrmWebView2Preview.wbIEExecuteScriptWithResultCompleted(Sender: TObject; ErrorCode: HResult;
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
procedure TFrmWebView2Preview.wbIEMoveFocusRequested(ASender: TObject; const AController: ICoreWebView2Controller;
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
procedure TFrmWebView2Preview.wbIENavigationStarting(ASender: TObject; const AWebView: ICoreWebView2;
  const Args: ICoreWebView2NavigationStartingEventArgs);
var
  EventArgs : TCoreWebView2NavigationStartingEventArgs;
begin
  try
    EventArgs := TCoreWebView2NavigationStartingEventArgs.Create(Args);
    if (EventArgs.NavigationKind = COREWEBVIEW2_NAVIGATION_KIND_BACK_OR_FORWARD) and
      WideSameText('data:text/html', Copy(EventArgs.Uri, 0, 14)) then
    begin
      FReloadDOM := True;
      FScrollPositions.Remove(FBufferID);
      PrevTimerID := SetTimer(Handle, 0, 100, @PreviewRefreshTimer);
    end
    else if (PosEx('#', EventArgs.Uri, Length(wbIe.Source)) <> 0) then
    begin
      EventArgs.Cancel := True;
      wbie.ExecuteScript(WideFormat('window.location.hash = "%s";',
        [wvString(StrRScan(@EventArgs.Uri[1], #$0023))]));
      // Target is an anchor within the same document -- reload user assets, if any
      if FHasDefaultStyle then
        wbIE.ExecuteScript(WideFormat(INJECT_USER_STYLE,
          [WideFormat('https://%s/%s', [ASSET_DOMAIN, ExtractFileName(FDefaultStyleSheet)])]));
      if FHasDefaultScript then
        wbIE.ExecuteScript(WideFormat(INJECT_USER_SCRIPT,
          [WideFormat('https://%s/%s', [ASSET_DOMAIN, ExtractFileName(FDefaultScript)])]));
    end;
  finally
    FreeAndNil(EventArgs);
  end;
end;

{ ------------------------------------------------------------------------------------------------ }
procedure TFrmWebView2Preview.SaveScrollPos;
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
end {TFrmWebView2Preview.SaveScrollPos};

{ ------------------------------------------------------------------------------------------------ }
procedure TFrmWebView2Preview.RestoreScrollPos;
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
end {TFrmWebView2Preview.RestoreScrollPos};

{ ------------------------------------------------------------------------------------------------ }
procedure TFrmWebView2Preview.GetDirectFunction;
var
  HScintilla: HWND;
  DirectFuncPtr: NativeInt;
begin
  HScintilla := Npp.CurrentScintilla;
  DirectFuncPtr := SendMessageW(HScintilla, SCI_GETDIRECTFUNCTION, 0, 0);
  FSciDirectPtr := SendMessageW(HScintilla, SCI_GETDIRECTPOINTER, 0, 0);
  if (DirectFuncPtr > 0) and (FSciDirectPtr > 0) then begin
    FSciDirectFunc := TScintillaMessageFnc(DirectFuncPtr);
  end else begin
    FSciDirectFunc := TScintillaMessageFnc(@Windows.SendMessageW);
    FSciDirectPtr := HScintilla;
  end;
end {TFrmWebView2Preview.GetDirectFunction};

{ ------------------------------------------------------------------------------------------------ }
procedure TFrmWebView2Preview.ForgetBuffer(const BufferID: TBufferID);
begin
  if (FBufferID = BufferID) or (Npp.GetCurrentBufferPath(BufferID) = '') then
    FBufferID := -1;
  if Assigned(FScrollPositions) then begin
    FScrollPositions.Remove(BufferID);
  end;
  ResetTimer;
end {TFrmWebView2Preview.ForgetBuffer};

{ ------------------------------------------------------------------------------------------------ }
procedure TFrmWebView2Preview.ReloadSettings;
var
  I: Integer;
  AssetName, AssetURL, ExtFilter: string;
begin
  with TNppPluginPreviewHTML(Npp).GetSettings() do begin
    FRenderMarkdown := ReadBool('Extensions', 'Markdown', True);
    FRenderWireloom := ReadBool('Extensions', 'Wireloom', True);
    FPreserveScrollPosition := ReadBool('Scroll', 'Sticky', True);
    tmrAutorefresh.Interval := ReadInteger('Autorefresh', 'Interval', tmrAutorefresh.Interval);
    try
      { User-defined CSS }
      if ReadBool(SECTION_CSS, 'Disable', False) then
        FDefaultStyleSheet := ''
      else begin
        if not SectionExists(SECTION_CSS) or not ValueExists(SECTION_CSS, VAL_FNAME) then begin
          AssetName := DEFAULT_STYLE_SHEET;
          if (wbIE <> nil) then begin
            case wbIE.PreferredColorScheme of
              COREWEBVIEW2_PREFERRED_COLOR_SCHEME_AUTO:
                if Npp.IsDarkModeEnabled then
                  AssetName := DEFAULT_DARK_STYLE_SHEET;
              COREWEBVIEW2_PREFERRED_COLOR_SCHEME_DARK:
                AssetName := DEFAULT_DARK_STYLE_SHEET;
            end;
          end;
          FDefaultStyleSheet := TNppPluginPreviewHTML(Npp).GetAssetPath(AssetName);
        end else begin
          AssetName := Trim(ReadString(SECTION_CSS, VAL_FNAME, ''));
          FDefaultStyleSheet := TNppPluginPreviewHTML(Npp).GetAssetPath(ExtractFileName(AssetName));
        end;
        { Check file extension filter }
        if ValueExists(SECTION_CSS, VAL_EXT) then begin
          ExtFilter := Trim(ReadString(SECTION_CSS, VAL_EXT, VAL_EXT_ANY));
          if (ExtFilter <> VAL_EXT_ANY) and (Pos(LowerCase(Npp.GetCurrentFileExt()), ExtFilter) = 0) then
            FDefaultStyleSheet := '';
        end;
      end;
      { User-defined JavaScript }
      if not SectionExists(SECTION_JS) or ReadBool(SECTION_JS, 'Disable', False) then
        FDefaultScript := ''
      else begin
        AssetName := Trim(ReadString(SECTION_JS, VAL_FNAME, ''));
        FDefaultScript := TNppPluginPreviewHTML(Npp).GetAssetPath(ExtractFileName(AssetName), '.js');
        if ValueExists(SECTION_JS, VAL_EXT) then begin
          ExtFilter := Trim(ReadString(SECTION_JS, VAL_EXT, VAL_EXT_ANY));
          if (ExtFilter <> VAL_EXT_ANY) and (Pos(LowerCase(Npp.GetCurrentFileExt()), ExtFilter) = 0) then
            FDefaultScript := '';
        end;
      end;
      { 3rd-party libraries }
      FRemoteAssets.Clear();
      if ValueExists('MathJax', 'Version') then begin
        AssetURL := 'mathjax@' + Trim(ReadString('MathJax', 'Version', '4'));
        with TStringList.Create do begin
          try
            CaseSensitive := False;
            Sorted := False;
            Delimiter := ',';
            DelimitedText := Trim(ReadString('MathJax', 'Components', 'tex-svg'));
            for i := 0 to Count - 1 do
              FRemoteAssets.Add(Format('%s/%s.min.js', [AssetURL, Strings[i]]));
          finally
            Free;
          end;
        end;
      end else if ValueExists('Katex', 'Version') then begin
        AssetURL := 'katex@' + Trim(ReadString('Katex', 'Version', '0.18'));
        FRemoteAssets.Add(Format('%s/dist/katex.min.css', [AssetURL]));
        FRemoteAssets.Add(Format('%s/dist/katex.min.js', [AssetURL]));
        if ReadBool('Katex', 'AutoRender', True) then
          FRemoteAssets.Add(Format('%s/dist/contrib/auto-render.min.js', [AssetURL]));
      end;
      if ValueExists('jQuery', 'Version') then begin
        AssetURL := 'jquery@' + Trim(ReadString('jQuery', 'Version', '3'));
        FRemoteAssets.Add(Format('%s/dist/jquery.min.js', [AssetURL]));
      end;
    finally
      Free;
    end;
    FHasDefaultStyle := FileExists(FDefaultStyleSheet);
    FHasDefaultScript := FileExists(FDefaultScript);
    if ((FRemoteAssets.Count > 0) or FHasDefaultScript) and (wbIE <> nil) then
      wbIE.ScriptEnabled := True;
  end;
end {TFrmWebView2Preview.ReloadSettings};

{ ------------------------------------------------------------------------------------------------ }
procedure TFrmWebView2Preview.ResetTimer;
begin
  tmrAutorefresh.Enabled := False;
  tmrAutorefresh.Enabled := True;
end {TFrmWebView2Preview.ResetTimer};

{ ------------------------------------------------------------------------------------------------ }
function TFrmWebView2Preview.DetermineCustomFilter: string;
var
  DocFileName: nppString;
  Filters: TUtf8IniFile;
  Names: TStringList;
  i: Integer;
  Match: Boolean;
  Ext, Language: string;
  DocLanguage: widestring;
  DocLangType, LangType: Integer;
  Extensions: TStringList;
  Filespec: string;
begin
  DocFileName := Npp.GetCurrentBufferPath;
  DocLangType := -1;
  DocLanguage := '';
  Result := String.Empty;
  Filters := TNppPluginPreviewHTML(Npp).GetSettings('Filters.ini');
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
      Filespec := Trim(Filters.ReadString(Names[i], VAL_FNAME, ''));
      if (Filespec <> '') then begin
        // http://docwiki.embarcadero.com/Libraries/XE2/en/System.Masks.MatchesMask#Description
        Match := Match or MatchesMask({$ifdef FPC}UTF8Encode{$endif}(ExtractFileName(DocFileName)), Filespec);
      end;

      {--- MCO 22-01-2013: Test extension ---}
      Ext := Trim(Filters.ReadString(Names[i], VAL_EXT, ''));
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
              SetLength(DocLanguage, SendMessage(Npp.NppData.NppHandle, NPPM_GETLANGUAGENAME, WPARAM(DocLangType), LPARAM(PWChar(DocLanguage))));
            end;
            if SameText(Language, {$ifdef FPC}UTF8Encode{$endif}(DocLanguage)) then begin
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
end {TFrmWebView2Preview.DetermineCustomFilter};

{ ------------------------------------------------------------------------------------------------ }
function TFrmWebView2Preview.ExecuteCustomFilter(const FilterName: string; const HTML: wvstring; const BufferID: TBufferID): Boolean;
var
  FilterData: TFilterData;
  DocFile: TFileName;
  Filters: TUtf8IniFile;
  BufferEncoding: NativeInt;
begin
  FilterData.Name := FilterName;
  FilterData.BufferID := BufferID;

  DocFile := Npp.GetCurrentBufferPath;
  FilterData.DocFile := DocFile;
  FilterData.Contents := HTML;

  BufferEncoding := SendMessage(Npp.NppData.NppHandle, NPPM_GETBUFFERENCODING, BufferID, 0);
  case BufferEncoding of
    1, 4: FilterData.Encoding := TEncoding.UTF8;
    2, 6: FilterData.Encoding := TEncoding.BigEndianUnicode;
    3, 7: FilterData.Encoding := TEncoding.Unicode;
    5:    FilterData.Encoding := TEncoding.UTF7;
    else  FilterData.Encoding := TEncoding.ANSI;
  end;
  FilterData.UseBOM := False; // BufferEncoding in [1, 2, 3];
  FilterData.Modified := FSciDirectFunc(FSciDirectPtr, SCI_GETMODIFY, 0, 0) <> 0;

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
end {TFrmWebView2Preview.ExecuteCustomFilter};

{ ------------------------------------------------------------------------------------------------ }
procedure TFrmWebView2Preview.FilterThreadTerminate(Sender: TObject);
begin
ODS('FilterThreadTerminate');
if (Sender as TThread).FatalException is Exception then
begin
  ODS('Fatal %s: "%s"', [((Sender as TThread).FatalException as Exception).ClassName, ((Sender as TThread).FatalException as Exception).Message]);
end else
begin
  { Thread started before the form was visible -- refresh preview }
  if FEnsureRendered then
   ResetTimer
  else
   PrevTimerID := SetTimer(Handle, 0, tmrAutorefresh.Interval, @PreviewRefreshTimer);
end;
  FFilterThread := nil;
end {TFrmWebView2Preview.FilterThreadTerminate};


{ ------------------------------------------------------------------------------------------------ }
procedure TFrmWebView2Preview.btnAboutClick(Sender: TObject);
const
  WikiPage = 'https://github.com/rdipardo/npp_preview/wiki';
begin
  if (not GlobalWebView2Loader.InitializationError) and (wbIE <> nil) then begin
    wbIE.Navigate(WikiPage)
  end else
    ShellAPI.ShellExecute(Self.Handle, 'Open', @WikiPage[1], Nil, Nil, SW_SHOWNORMAL);
end {TFrmWebView2Preview.btnAboutClick};

{ ------------------------------------------------------------------------------------------------ }
procedure TFrmWebView2Preview.btnCloseClick(Sender: TObject);
begin
  self.Hide;
end {TFrmWebView2Preview.btnCloseClick};

{ ------------------------------------------------------------------------------------------------ }
// special hack for input forms
// This is the best possible hack I could came up for
// memo boxes that don't process enter keys for reasons
// too complicated... Has something to do with Dialog Messages
// I sends a Ctrl+Enter in place of Enter
procedure TFrmWebView2Preview.FormKeyPress(Sender: TObject;
  var Key: Char);
begin
//  if (Key = #13) and (self.Memo1.Focused) then self.Memo1.Perform(WM_CHAR, 10, 0);
end;

{ ------------------------------------------------------------------------------------------------ }
// Docking code calls this when the form is hidden by either "x" or self.Hide
procedure TFrmWebView2Preview.FormHide(Sender: TObject);
begin
  SaveScrollPos;
  SendMessage(self.Npp.NppData.NppHandle, NPPM_SETMENUITEMCHECK, self.CmdID, 0);
{$ifdef FPC}
  self.Visible := False;
{$endif}
end;

{ ------------------------------------------------------------------------------------------------ }
procedure TFrmWebView2Preview.FormDock(Sender: TObject);
begin
  Enabled := True;
  pnlButtons.Enabled := True;
  ResetTimer;
end;

{ ------------------------------------------------------------------------------------------------ }
procedure TFrmWebView2Preview.FormFloat(Sender: TObject);
begin
  ResetTimer;
end;

{ ------------------------------------------------------------------------------------------------ }
procedure TFrmWebView2Preview.FormShow(Sender: TObject);
begin
  inherited;
  ToggleDarkMode;
  ReloadSettings;
  SendMessage(self.Npp.NppData.NppHandle, NPPM_SETMENUITEMCHECK, self.CmdID, 1);
  if wbIE.IsSuspended then
    wbIE.Resume;
  FEnsureRendered := True;
  FReloadDOM := True;
  ResetTimer;
end;

{ ------------------------------------------------------------------------------------------------ }
procedure TFrmWebView2Preview.UpdateNavButton(var ABtn: TBitBtn; NewState: Boolean);
begin
  ABtn.Enabled := NewState;
  ABtn.ShowHint := NewState;
end;

{ ------------------------------------------------------------------------------------------------ }
procedure TFrmWebView2Preview.wbIEStatusBar(ASender: TObject; const aWebView: ICoreWebView2);
begin
  wbIEStatusTextChange(ASender, TWVBrowser(ASender).StatusBarText);
end;

{ ------------------------------------------------------------------------------------------------ }
procedure TFrmWebView2Preview.wbIEStatusTextChange(ASender: TObject; const Text: WideString);
begin
  sbrIE.Panels[0].Text := {$ifdef FPC}UTf8Encode{$endif}(Text);
  sbrIE.Visible := Length(Text) > 0;
  if sbrIE.Visible then
  sbrIE.Invalidate;
end;

{ ------------------------------------------------------------------------------------------------ }
procedure TFrmWebView2Preview.wbIETitleChange(ASender: TObject);
var
  DocTitle: wvString;
begin
  DocTitle := wbIE.DefaultURL;
  if not WideSameText('data:text/html', Copy(wbIE.DocumentTitle, 0, 14)) then
     DocTitle := wbIE.DocumentTitle;
  self.UpdateDisplayInfo({$ifdef FPC}UTF8Encode{$endif}(DocTitle));
end;

{ ------------------------------------------------------------------------------------------------ }
procedure TFrmWebView2Preview.wbIENavigationHistoryChange(ASender: TObject);
begin
  if wbIE <> nil then begin
    UpdateNavButton(BtnNavBack, wbIE.CanGoBack);
    UpdateNavButton(BtnNavForward, wbIE.CanGoForward);
  end;
end;

{ ------------------------------------------------------------------------------------------------ }
procedure TFrmWebView2Preview.wbIEInitializationError(ASender: TObject;
  ErrorCode: HRESULT; const ErrorMessage: wvstring);
begin
  MessageBoxW(0, @ErrorMessage[1], PWChar(WideFormat('Error: %d', [ErrorCode])), MB_ICONERROR);
end;

{ ------------------------------------------------------------------------------------------------ }
procedure TFrmWebView2Preview.wbIEAfterCreated(ASender: TObject);
begin
  wbHost.UpdateSize;
  // wbHost.SetFocus; //< will hang on float!
  PrevTimerID := SetTimer(Handle, 0, 800, @PreviewRefreshTimer);
end;

procedure TFrmWebView2Preview.WMMove(var AMessage : TWMMove);
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

procedure TFrmWebView2Preview.WMMoving(var AMessage : TMessage);
begin
  inherited;
  if (wbIE <> nil) then
    wbIE.NotifyParentWindowPositionChanged;
end;

{$ifdef FPC}
procedure TFrmWebView2Preview.HandleCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  wbIE.TrySuspend;
  inherited;
end;
{$endif}

////////////////////////////////////////////////////////////////////////////////////////////////////
initialization

finalization
  if Assigned(frmWV2Preview) then
    KillTimer(frmWV2Preview.Handle, frmWV2Preview.PrevTimerID);

end.
