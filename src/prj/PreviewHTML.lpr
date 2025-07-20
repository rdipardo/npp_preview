{
  Copyright (C) 2025 Robert Di Pardo <dipardo.r@gmail.com>

  This program is free software: you can redistribute it and/or
  modify it under the terms of the GNU General Public License
  as published by the Free Software Foundation, either version
  3 of the License, or (at your option) any later version.

  This program is distributed in the hope that it will be
  useful, but WITHOUT ANY WARRANTY; without even the implied
  warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
  PURPOSE. See the GNU General Public License for more details.

  You should have received a copy of the GNU General
  Public License along with this program. If not, see
  <https:www.gnu.org/licenses/>.
}

{$mode Delphi}
{$warn 2025 OFF}

{$SetPEOSVersion 6.00}
{$SetPESubsysVersion 6.00}
{$ifdef CPUx86}
  {$ImageBase $00400000}
{$endif}
{$if NOT DECLARED(useheaptrace)}
  {$SetPEOptFlags $0040}
{$endif}

library PreviewHTML;

uses
  SysUtils,
  Windows,
  nppplugin in '..\lib\Source\Units\Common\nppplugin.pas',
  U_Npp_PreviewHTML in '..\U_Npp_PreviewHTML.pas';

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

procedure setInfo(NppData: TNppData); cdecl;
begin
  if Assigned(Npp) then
    Npp.SetInfo(NppData);
end;

function getName(): nppPchar; cdecl;
begin
  if Assigned(Npp) then
    Result := Npp.GetName
  else
    Result := '(plugin not initialized)';
end;

function getFuncsArray(var nFuncs:integer):Pointer; cdecl;
begin
  if Assigned(Npp) then
    Result := Npp.GetFuncsArray(nFuncs)
  else begin
    Result := nil;
    nFuncs := 0;
  end;
end;

procedure beNotified(sn: PSCiNotification); cdecl;
begin
  if Assigned(Npp) then
    Npp.BeNotified(sn);
end;

function messageProc(msg: UINT; _wParam: WPARAM; _lParam: LPARAM): LRESULT; cdecl;
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

function isUnicode : Boolean; cdecl;
begin
  Result := true;
end;

exports
  setInfo, getName, getFuncsArray, beNotified, messageProc, isUnicode;

begin
  DLL_PROCESS_DETACH_Hook := @DLLEntryPoint;
  DLLEntryPoint(DLL_PROCESS_ATTACH);
end.
