library PreviewHTML;

{ Important note about DLL memory management: ShareMem must be the
  first unit in your library's USES clause AND your project's (select
  Project-View Source) USES clause if your DLL exports any procedures or
  functions that pass strings as parameters or function results. This
  applies to all strings passed to and from your DLL--even those that
  are nested in records and classes. ShareMem is the interface unit to
  the BORLNDMM.DLL shared memory manager, which must be deployed along
  with your DLL. To avoid using BORLNDMM.DLL, pass string information
  using PChar or ShortString parameters. }

{$IF CompilerVersion >= 21.0}
{$WEAKLINKRTTI ON}
{$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}
{$ENDIF}

uses
  SysUtils,
  Classes,
  Types,
  Windows,
  Messages,
  nppplugin in '..\lib\Source\Units\Common\nppplugin.pas',
  NppForms in '..\lib\Source\Forms\Common\NppForms.pas' {NppForm},
  NppDockingForms in '..\lib\Source\Forms\Common\NppDockingForms.pas' {NppDockingForm},
  U_Npp_PreviewHTML in '..\U_Npp_PreviewHTML.pas',
  F_About in '..\F_About.pas' {AboutForm},
  F_PreviewHTML in '..\F_PreviewHTML.pas' {frmHTMLPreview},
  WebBrowser in '..\common\WebBrowser.pas',
  VersionInfo in '..\lib\Source\Units\Common\VersionInfo.pas',
  ModulePath in '..\lib\Source\Units\Common\ModulePath.pas',
  Utf8IniFiles in '..\lib\Source\Units\Common\Utf8IniFiles.pas',
  RegExpr in '..\common\RegExpr.pas',
  U_CustomFilter in '..\U_CustomFilter.pas',
  Debug;

{$R *.res}

procedure DLLEntryPoint(dwReason: DWord);
begin
  case dwReason of
  DLL_PROCESS_ATTACH:
  begin
  end;
  DLL_PROCESS_DETACH:
  begin
    try
      if Assigned(Npp) then
        Npp.Free;
    except
      ShowException(ExceptObject, ExceptAddr);
    end;
  end;
  end;
end;

procedure setInfo(NppData: TNppData); cdecl; export;
begin
  if Assigned(Npp) then
    Npp.SetInfo(NppData);
end;

function getName(): nppPchar; cdecl; export;
begin
  if Assigned(Npp) then
    Result := Npp.GetName
  else
    Result := '(plugin not initialized)';
end;

function getFuncsArray(var nFuncs:integer):Pointer;cdecl; export;
begin
  if Assigned(Npp) then
    Result := Npp.GetFuncsArray(nFuncs)
  else begin
    Result := nil;
    nFuncs := 0;
  end;
end;

procedure beNotified(sn: PSCiNotification); cdecl; export;
begin
  if Assigned(Npp) then
    Npp.BeNotified(sn);
end;

function messageProc(msg: UINT; _wParam: WPARAM; _lParam: LPARAM): LRESULT; cdecl; export;
var xmsg:TMessage;
begin
  xmsg.Msg := msg;
  xmsg.WParam := _wParam;
  xmsg.LParam := _lParam;
  xmsg.Result := 0;
  if Assigned(Npp) then
    Npp.MessageProc(xmsg);
  Result := xmsg.Result;
end;

function isUnicode : Boolean; cdecl; export;
begin
  Result := true;
end;

exports
  setInfo, getName, getFuncsArray, beNotified, messageProc, isUnicode;

begin
{$IFDEF DEBUG}
  ReportMemoryLeaksOnShutdown := DebugHook <> 0;
{$ENDIF}
  { First, assign the procedure to the DLLProc variable }
  DllProc := @DLLEntryPoint;
  { Now invoke the procedure to reflect that the DLL is attaching to the process }
  DLLEntryPoint(DLL_PROCESS_ATTACH);
end.

