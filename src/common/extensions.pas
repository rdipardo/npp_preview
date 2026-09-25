{
  SPDX-FileCopyrightText: (c) 2026 Robert Di Pardo
  SPDX-License-Identifier: GPL-3.0-or-later
}

{$ifdef FPC}
{$mode delphi}
{$endif}

unit extensions;

interface

uses
  sysutils,
  customstreams;

const
  EXT_DOMAIN = 'preview.extensions';

function RenderWireloom(Markup, Title: TUnicodeStreamString; DarkTheme: Boolean): TUnicodeStreamString;
function PrepareWLScript(Markup: TUnicodeStreamString; DarkTheme: Boolean): TUnicodeStreamString;
function GetThemeName(PrefersDark: Boolean): TUnicodeStreamString;
function JsonEncode(const AString: TUnicodeStreamString): TUnicodeStreamString;

implementation
{$ifdef FPC}
uses
  fpjson;
{$endif}

const
  WIRELOOM =
    '<!DOCTYPE html>' +
    '<html>' +
    ' <head>' +
    '  <title>%s</title>'+
    ' </head>' +
    ' <body>' +
    '   <div id="content"></div>' +
    '   <script type="module">' +
    '    import("https://%s/wireloom/index.js").then(async (wireloom) => {' +
    '     try {' +
    '       window.wireloom = wireloom;' +
    '       const { svg } = await wireloom.render(document.title || "wireframe", "%s", { theme: "%s" });' +
    '       document.getElementById("content").innerHTML = svg;' +
    '     } catch (e) {' +
    '       document.getElementById("content").innerHTML = `<p><kbd>${e}</kbd></p>`;' +
    '       console.error(e); '+
    '     }' +
    '    }).catch(err => {' +
    '       document.getElementById("content").innerHTML = `<p><kbd>${err}</kbd></p>`;' +
    '       console.error(err);' +
    '    });' +
    '   </script>' +
    ' </body>' +
    '</html>';

function JsonEncode(const AString: TUnicodeStreamString): TUnicodeStreamString;
begin
  Result :=
{$ifdef FPC}
    UTF8ToString(StringToJSONString(UTF8Encode(AString)))
{$else}
    StringReplace(
      StringReplace(
        StringReplace(
          StringReplace(
            StringReplace(
              StringReplace(
                StringReplace(
                  StringReplace(
                    AString, '\', '\\', [rfReplaceAll]),
                  '"', '\"', [rfReplaceAll]),
                ''#13#10, '\n', [rfReplaceAll]),
              ''#10, '\n', [rfReplaceAll]),
            ''#13, '\n', [rfReplaceAll]),
          ''#12, '\f', [rfReplaceAll]),
        ''#9, '\t', [rfReplaceAll]),
      ''#8, '\b', [rfReplaceAll])
{$endif};
end;

function RenderWireloom(Markup, Title: TUnicodeStreamString; DarkTheme: Boolean): TUnicodeStreamString;
begin
  Result := WideFormat(WIRELOOM, [Title, EXT_DOMAIN, JsonEncode(Markup), GetThemeName(DarkTheme)]);
end;

function PrepareWLScript(Markup: TUnicodeStreamString; DarkTheme: Boolean): TUnicodeStreamString;
const
  JS =
    'wireloom.render(document.title || "wireframe", "%s", { theme: "%s" })' +
    ' .then(res => document.getElementById("content").innerHTML = res.svg)' +
    ' .catch(e => {' +
    '   document.getElementById("content").innerHTML = `<p><kbd>${e}</kbd></p>`;' +
    '   console.error(e);' +
    '});';
begin
  Result := WideFormat(JS, [JsonEncode(Markup), GetThemeName(DarkTheme)]);
end;

function GetThemeName(PrefersDark: Boolean): TUnicodeStreamString;
begin
  Result := 'default';
  if PrefersDark then
    Result := 'dark';
end;

end.
