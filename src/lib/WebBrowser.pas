﻿unit WebBrowser;

interface
uses
  Classes, SHDocVw, MSHTML;

type

  TWBHelper = class helper for TWebBrowser
  public
    procedure CheckDocReady();
    procedure LoadBlankDoc();
    procedure LoadDocFromStream(Stream: TStream);
    procedure LoadDocFromString(const HTMLString: string);
    function  GetDocument(): IHTMLDocument2;
    function  GetRootElement(): IHTMLElement;
    procedure ExecJS(const Code: string);
  end;


function GetBrowserEmulation: Integer;
procedure SetBrowserEmulation(const Value: Integer);
function GetIEVersion: string;

implementation
uses
  SysUtils, Forms, ActiveX, Variants, Registry, Windows;

{ ------------------------------------------------------------------------------------------------ }
procedure TWBHelper.ExecJS(const Code: string);
begin
  GetDocument.parentWindow.execScript(Code, 'JScript');
end;

{ ------------------------------------------------------------------------------------------------ }
function TWBHelper.GetDocument: IHTMLDocument2;
begin
  Result := Self.Document as IHTMLDocument2;
end;

{ ------------------------------------------------------------------------------------------------ }
procedure TWBHelper.LoadBlankDoc();
begin
  Self.Navigate('about:blank');
  while not Self.ReadyState in [READYSTATE_INTERACTIVE, READYSTATE_COMPLETE] do begin
    Forms.Application.ProcessMessages;
    Sleep(0);
  end;
end;

{ ------------------------------------------------------------------------------------------------ }
procedure TWBHelper.CheckDocReady();
begin
  if not Assigned(Self.Document) then
    LoadBlankDoc();
end;

{ ------------------------------------------------------------------------------------------------ }
procedure TWBHelper.LoadDocFromStream(Stream: TStream);
begin
  CheckDocReady();
  (Self.Document as IPersistStreamInit).Load(TStreamAdapter.Create(Stream));
end;

{ ------------------------------------------------------------------------------------------------ }
procedure TWBHelper.LoadDocFromString(const HTMLString: string);
var
  v: OleVariant;
  HTMLDocument: IHTMLDocument2;
begin
  CheckDocReady();
  HTMLDocument := Self.Document as IHTMLDocument2;
  v := VarArrayCreate([0, 0], varVariant);
  v[0] := HTMLString;
  HTMLDocument.Write(PSafeArray(TVarData(v).VArray));
  HTMLDocument.Close;
end;

{ ------------------------------------------------------------------------------------------------ }
function TWBHelper.GetRootElement: IHTMLElement;
begin
  Result := Self.GetDocument.body;
  while Assigned(Result) and Assigned(Result.parentElement) do begin
    Result := Result.parentElement;
  end;
end;


(*
See http://msdn.microsoft.com/en-us/library/ee330730.aspx#BROWSER_EMULATION
*)

{ ------------------------------------------------------------------------------------------------ }
function GetExecutableFile: string;
begin
  SetLength(Result, MAX_PATH);
  SetLength(Result, GetModuleFileName(0, PChar(Result), Length(Result)));
  SetLength(Result, GetLongPathName(PChar(Result), nil, 0));
  SetLength(Result, GetLongPathName(PChar(Result), PChar(Result), Length(Result)));
  if Copy(Result, 1, 4) = '\\?\' then
    Result := Copy(Result, 5);
end {GetExecutableFile};

{ ------------------------------------------------------------------------------------------------ }
function GetBrowserEmulation: Integer;
var
  ExeName: string;
  RegKey: TRegistry;
begin
  Result := 0;
  ExeName := ExtractFileName(GetExecutableFile);

  try
    RegKey := TRegistry.Create;
    try
      RegKey.RootKey := HKEY_CURRENT_USER;
      if RegKey.OpenKey('SOFTWARE\Microsoft\Internet Explorer\Main\FeatureControl\FEATURE_BROWSER_EMULATION', True) then begin
        Result := RegKey.ReadInteger(ExeName);
      end;
    finally
      RegKey.Free;
    end;
  except
    Result := 0;
  end;

  if Result = 0 then
    Result := 7000; // Default value for applications hosting the WebBrowser Control.
end {GetBrowserEmulation};
{ ------------------------------------------------------------------------------------------------ }
procedure SetBrowserEmulation(const Value: Integer);
var
  ExeName: string;
  RegKey: TRegistry;
begin
  ExeName := ExtractFileName(GetExecutableFile);

  RegKey := TRegistry.Create;
  try
    RegKey.RootKey := HKEY_CURRENT_USER;
    if RegKey.OpenKey('SOFTWARE\Microsoft\Internet Explorer\Main\FeatureControl\FEATURE_BROWSER_EMULATION', True) then begin
      RegKey.WriteInteger(ExeName, Value);
    end;
  finally
    RegKey.Free;
  end;
end {SetBrowserEmulation};

{ ------------------------------------------------------------------------------------------------ }
function GetIEVersion: string;
var
  Reg: TRegistry;
begin
  try
    Reg := TRegistry.Create;
    try
      Reg.RootKey := HKEY_LOCAL_MACHINE;
      Reg.OpenKeyReadOnly('Software\Microsoft\Internet Explorer');
      Result := Reg.ReadString('Version');
      Reg.CloseKey;
    finally
      Reg.Free;
    end;
  except
    Result := '';
  end;
end {GetIEVersion};


end.
