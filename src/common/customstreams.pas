{
  Custom byte streams for Win32.

  Copyright (C) 2025 Robert Di Pardo <dipardo.r@gmail.com>

  This unit is free software; you can redistribute it and/or modify it
  under the terms of the GNU Library General Public License as published by
  the Free Software Foundation; either version 2 of the License, or (at your
  option) any later version with the following modification:

  As a special exception, the copyright holders of this unit give you
  permission to link this unit with independent modules to produce an
  executable, regardless of the license terms of these independent modules,and
  to copy and distribute the resulting executable under terms of your choice,
  provided that you also meet, for each linked independent module, the terms
  and conditions of the license of that module. An independent module is a
  module which is not derived from or based on this unit. If you modify
  this unit, you may extend this exception to your version of the unit,
  but you are not obligated to do so. If you do not wish to do so, delete this
  exception statement from your version.

  This unit is distributed in the hope that it will be useful, but WITHOUT
  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
  FITNESS FOR A PARTICULAR PURPOSE. See the file COPYING for more details.
}

{$ifdef FPC}
{$mode delphi}
{$endif}

unit customstreams;

interface

uses
  Classes, SysUtils, Windows;

type
  TStreamSize = {$ifdef FPC} SizeInt {$else} NativeInt {$endif};
  TUnicodeStreamChar = {$ifdef FPC} UnicodeChar {$else} WideChar {$endif};
  PUnicodeStreamChar = {$ifdef FPC} PUnicodeChar {$else} PWideChar {$endif};
  TUnicodeStreamString = {$ifdef FPC} UnicodeString {$else} WideString {$endif};

  { A stream that stores Unicode text in a dynamic byte array }
  TUnicodeStream = class
  private
    FData: TBytes;
    FSize: TStreamSize;
    FCodePage: Cardinal;
    function GetData: PByte;
    function GetText: TUnicodeStreamString;
    function IsEmpty: Boolean;
    procedure WriteText(const AText: TUnicodeStreamString);
    procedure SetSize(const ASize: TStreamSize);
    procedure SetCodePage(const ACodePage: Cardinal);
  public
    constructor Create(const ACodePage: Cardinal = CP_UTF8);
    destructor Destroy; override;
    procedure Clear;
    procedure SaveToFile(const AFileName: TUnicodeStreamString);
    property Empty: Boolean read IsEmpty;
    property Data: PByte read GetData;
    property Size: TStreamSize read FSize write SetSize;
    property CodePage: Cardinal read FCodePage write SetCodePage;
    property Text: TUnicodeStreamString read GetText write WriteText;
  end;

function Pos(const Substr: String; const Source: TUnicodeStreamString;
  Offset: Integer = 1): TStreamSize; overload;

implementation

const
  SIZE_MIN = Sizeof(TUnicodeStreamChar);
  SIZE_MAX = 2 * 1024 * 1024;
  UNICODE_NULL = TUnicodeStreamChar(#$0000);

function Pos(const Substr: String; const Source: TUnicodeStreamString;
  Offset: Integer): TStreamSize;
begin
  Result := System.Pos(UTF8Encode(SubStr), UTF8Encode(Source), Offset);
end;

constructor TUnicodeStream.Create(const ACodePage: Cardinal);
begin
  SetCodePage(ACodePage);
  SetSize(SIZE_MIN);
end;

destructor TUnicodeStream.Destroy;
begin
  SetLength(FData, 0);
  inherited;
end;

procedure TUnicodeStream.SaveToFile(const AFileName: TUnicodeStreamString);
var
  hFStream: THandleStream;
  hDest: THandle;
  content: RawByteString;
begin
  if IsEmpty then
    Exit;

  hFStream := nil;
  hDest := THandle(-1);
  try
    hDest := FileOpen(AFileName, fmOpenWrite or fmShareExclusive);
    if hDest = THandle(-1) then
      hDest := FileCreate(AFileName);
    try
      content := UTF8Encode(GetText);
      hFStream := THandleStream.Create(hDest);
      hFStream.Write(content[1], Length(content));
    finally
      FileClose(hFStream.Handle);
      hFStream.Free;
    end;
  except
    on E: Exception do
    begin
      if (not Assigned(hFStream)) and (hDest <> THandle(-1)) then
        FileClose(hDest);
    end;
  end;
end;

procedure TUnicodeStream.Clear;
begin
  WriteText(UNICODE_NULL);
end;

function TUnicodeStream.GetText: TUnicodeStreamString;
var
  bufSize: TStreamSize;
  dwFlags: Cardinal;
begin
  if (FCodePage = CP_ACP) then
  begin
    // https://learn.microsoft.com/windows/apps/design/globalizing/use-utf8-code-page
    if (GetACP() = CP_UTF8) then
      Result := UTF8ToString(FData)
    else
      Result := TUnicodeStreamString(PAnsiChar(FData));
  end
  else
  begin
    // https://learn.microsoft.com/windows/win32/api/stringapiset/nf-stringapiset-multibytetowidechar
    if (FCodePage = CP_UTF8) or (FCodePage = 54936) then
      dwFlags := MB_ERR_INVALID_CHARS
    else
      dwFlags := 0;
    Result := '';
    bufSize := MultiByteToWideChar(FCodePage, dwFlags, PAnsiChar(FData), FSize, nil, 0);
    if bufSize > 0 then
    begin
      SetLength(Result, bufSize);
      SetLength(Result, MultiByteToWideChar(FCodePage, dwFlags,
        PAnsiChar(FData), FSize, PUnicodeStreamChar(Result), bufSize));
      SetLastError(0);
    end;
  end;
end;

procedure TUnicodeStream.WriteText(const AText: TUnicodeStreamString);
var
  bytes: TBytes;
begin
  bytes := BytesOf(UTF8Encode(AText));
  SetSize(Length(bytes));
  FData := Copy(bytes, 0, Length(bytes));
end;

procedure TUnicodeStream.SetSize(const ASize: TStreamSize);
var
  OldSize, I: TStreamSize;
begin
  if (ASize < SIZE_MIN) or (FSize = ASize) then
    Exit;

  OldSize := FSize;
  if ASize > SIZE_MAX then
    FSize := SIZE_MAX
  else
    FSize := ASize;

  if FSize < OldSize then begin
    // Zero out leftover space
    for I := (OldSize - 1) downto FSize do
      FData[i] := 0;
  end else
    SetLength(FData, FSize);
end;

procedure TUnicodeStream.SetCodePage(const ACodePage: Cardinal);
var
  cpi: TCpInfo;
begin
  cpi := Default(TCpInfo);
  if Boolean(GetCPInfo(ACodePage, cpi)) then
    FCodePage := ACodePage;
  SetLastError(0);
end;

function TUnicodeStream.IsEmpty: Boolean;
begin
  Result := Length(Trim(GetText)) < 1;
end;

function TUnicodeStream.GetData: PByte;
begin
  Result := @FData[0];
end;

end.
