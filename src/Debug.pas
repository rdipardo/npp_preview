unit Debug;

interface
{$ifdef FPC}
uses streamex;
type TStreamWriter = TDelphiWriter;
{$endif}

procedure ODS(const DebugOutput: string); overload;
procedure ODS(const DebugOutput: string; const Args: array of const); overload;

implementation
uses
  Classes, SysUtils,
  Windows,
  ModulePath;

var
  OutputLog: TStreamWriter;
  OutputStream: TFileStream;

{ ------------------------------------------------------------------------------------------------ }
procedure ODS(const DebugOutput: string); overload;
{$ifdef DEBUG}
var
  LogFile: string;
{$endif}
begin
  OutputDebugString(PChar('PreviewHTML['+IntToHex(GetCurrentThreadId, 4)+']: ' + DebugOutput));
  {$IFDEF DEBUG}
  if OutputLog = nil then begin
    LogFile := ChangeFileExt({$ifdef FPC}UTF8Encode{$endif}(TModulePath.DLLFullName), '.log');
    OutputStream := TFileStream.Create(LogFile, fmCreate or fmShareDenyWrite);
    OutputLog := TStreamWriter.Create(OutputStream, {$ifndef FPC}TEncoding.UTF8{$else}BUFFER_SIZE{$endif});
{$ifndef FPC}
    OutputLog.OwnStream;
    OutputLog.BaseStream.Seek(0, soFromEnd);
{$endif}
  end;
  OutputLog.{$ifndef FPC}Write{$else}WriteStr{$endif}(FormatDateTime('yyyy-MM-dd hh:nn:ss.zzz: ', Now));
  OutputLog.{$ifndef FPC}WriteLine{$else}WriteStr{$endif}(DebugOutput.Replace(#10, #10 + StringOfChar(' ', 25)));
{$ifdef FPC}
  OutputLog.WriteStr(#13#10);
{$endif}
  {$ENDIF}
end {ODS};
{ ------------------------------------------------------------------------------------------------ }
procedure ODS(const DebugOutput: string; const Args: array of const); overload;
begin
  ODS(Format(DebugOutput, Args));
end{ODS};


initialization

finalization
  OutputLog.Free;
{$ifdef FPC}
  OutputStream.Free;
{$endif}

end.
