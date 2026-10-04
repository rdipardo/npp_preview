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
  WIRELOOM_SELECTOR = 'code.language-wireloom';
  MERMAID_SELECTOR = 'code.language-mermaid';
  MERMAID_JS =
    'mermaid.run({' +
    ' querySelector: "' + MERMAID_SELECTOR + '",' +
    ' suppressErrors: true' +
    '})' +
    '.then(() => true)' +
    '.catch(e => console.info(`mermaid: ${e}`));';

function RenderMarkdown(Markup, Title: TUnicodeStreamString; DarkTheme, Mermaid: Boolean):
  TUnicodeStreamString;
function RenderWireloom(Markup, Title: TUnicodeStreamString; DarkTheme: Boolean): TUnicodeStreamString;
function PrepareMDScript(Markup: TUnicodeStreamString): TUnicodeStreamString;
function PrepareWLScript(Markup: TUnicodeStreamString; DarkTheme: Boolean): TUnicodeStreamString;
function PrepareCodeBlockScript(const Theme: TUnicodeStreamString): TUnicodeStreamString;
function GetThemeName(PrefersDark: Boolean): TUnicodeStreamString;
function JsonEncode(const AString: TUnicodeStreamString): TUnicodeStreamString;

implementation
{$ifdef FPC}
uses
  fpjson;
{$endif}

const
  MARKDOWN =
    '<!DOCTYPE html>' +
    '<html>' +
    ' <head>' +
    '   <title>%s</title>' +
    '   <link rel="stylesheet" href="https://%s/highlightjs/styles/%s.css">' +
    '   <script src="https://%s/highlightjs/index.js"></script>' +
    '   <script src="https://%s/marked/gfm-alert.js"></script>' +
    '   <script src="https://%s/marked/gfm-footnote.js"></script>' +
    '   <script src="https://%s/marked/gfm-heading-id.js"></script>' +
    '   <script src="https://%s/marked/custom-heading-id.js"></script>' +
    '   <script src="https://%s/marked/highlight.js"></script>' +
    '   %s' + { load mermaid script }
    '   <style>' +
    '     pre,' +
          MERMAID_SELECTOR + '[data-processed=true] {' +
    '       background-color: inherit;' +
    '       border: 0;' +
    '     }' +
    '     pre code.hljs {' +
    '       overflow-x: scroll;' +
    '     }' +
    '   </style>' +
    ' </head>' +
    ' <body>' +
    '   <div id="content"></div>' +
    '   <script type="module">' +
    '    import("https://%s/marked/index.js").then(async (marked) => {' +
    '     try {' +
    '       const hljsConfig = { '+
    '         emptyLangClass: "hljs",' +
    '         langPrefix: "hljs language-",' +
    '         highlight: function (code, lang, info) {' +
    '           const res = hljs.highlight(code, { language: (hljs.getLanguage(lang) ? lang : "plaintext") }) || {};' +
    '           return res.value;' +
    '         }' +
    '       };' +
    '       marked.use({' +
    '         gfm: true,' +
    '         breaks: false,' +
    '         async: true,' +
    '         silent: true },' +
    '         markedAlert(),' +
    '         markedFootnote(),'+
    '         markedGfmHeadingId.gfmHeadingId(),' +
    '         markedCustomHeadingId(),' +
    '         markedHighlight.markedHighlight(hljsConfig)'+
    '       );' +
    '       window.marked = marked;' +
    '       document.getElementById("content").innerHTML = await marked.parse("%s");' +
    '       %s' + { render mermaid code blocks }
    '     } catch (e) {' +
    '       document.getElementById("content").innerHTML = `<p><kbd>${e}</kbd></p>`;' +
    '       console.error(e); '+
    '     }' +
    '    }).catch(err => {' +
    '       document.getElementById("content").innerHTML = `<p><kbd>${err}</kbd></p>`;' +
    '       console.error(err);' +
    '    });' +
    '   </script>' +
    '   <script type="module">' +
    '    import("https://%s/wireloom/index.js").then((wireloom) => {' +
    '     window.wireloom = wireloom;' +
    '     /* render wireloom code blocks */ %s'+
    '    }).catch(e => console.error(e));' +
    '   </script>' +
    ' </body>' +
    '</html>';

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

function RenderMarkdown(Markup, Title: TUnicodeStreamString; DarkTheme, Mermaid: Boolean):
  TUnicodeStreamString;
const
  LOAD_MERMAID =
    '<script src="https://' + EXT_DOMAIN + '/mermaid/index.js"' +
    '  onload="(function() {' +
    '    try {' +
    '      let style = document.createElement(''link'');' +
    '      let node = document.querySelector(''base'') || document.head.firstElementChild;' +
    '      style.rel = ''stylesheet'';' +
    '      style.href = ''https://cdn.jsdelivr.net/npm/@fontsource-variable/recursive@5/index.min.css'';' +
    '      node.after(style);' +
    '      mermaid.initialize({' +
    '        startOnLoad: false,' +
    '        securityLevel: ''loose'',' +
    '        theme: ''%s'',' +
    '        darkMode: %s' +
    '      });' +
    '    } catch (e) {' +
    '        console.info(`mermaid: ${e}`);' +
    '    }' +
    '  })()">' +
    '</script>';
var
  Theme, MermaidTheme, MermaidDarkMode, MermaidLoader, MermaidScript: TUnicodeStreamString;
begin
  Theme := GetThemeName(DarkTheme);
  MermaidLoader := '<!-- mermaid disabled by user -->';
  MermaidScript := '/* mermaid disabled by user */';
  if Mermaid then begin
    MermaidTheme := BoolToStr(DarkTheme, 'redux-dark-color', 'redux-color');
    MermaidDarkMode := BoolToStr(DarkTheme, 'true', 'false');
    MermaidLoader := WideFormat(LOAD_MERMAID, [MermaidTheme, MermaidDarkMode]);
    MermaidScript := MERMAID_JS;
  end;
  Result := WideFormat(
    {$ifdef FPC}WideStringReplace{$else}StringReplace{$endif}(MARKDOWN, 'https://%s', 'https://'+EXT_DOMAIN, [rfReplaceAll]),
    [Title, Theme, MermaidLoader, JsonEncode(Markup), MermaidScript, PrepareCodeBlockScript(Theme)]);
end;

function PrepareMDScript(Markup: TUnicodeStreamString): TUnicodeStreamString;
const
  JS =
    'marked.parse("%s")' +
    ' .then(res => document.getElementById("content").innerHTML = res)' +
    ' .catch(e => {' +
    '   document.getElementById("content").innerHTML = `<p><kbd>${e}</kbd></p>`;' +
    '   console.error(e);' +
    '});';
begin
  Result := WideFormat(JS, [JsonEncode(Markup)]);
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

function PrepareCodeBlockScript(const Theme: TUnicodeStreamString): TUnicodeStreamString;
const
  JS =
    '  try {' +
    '     Array.prototype.slice.call(document.querySelectorAll("%s")).reduce(async (n,c) => {' +
    '       const index = (typeof(n) === "number" ? n : await n);' +
    '       const { svg } = await wireloom.render(`wireframe-${index}`, c.innerText, { theme: "%s" });' +
    '       c.parentNode.innerHTML = svg;' +
    '       return n+1;' +
    '     }, 1);' +
    '  } catch (e) {' +
    '    console.error(e);' +
    '  }';
begin
  Result := WideFormat(JS, [WIRELOOM_SELECTOR, Theme]);
end;

function GetThemeName(PrefersDark: Boolean): TUnicodeStreamString;
begin
  Result := 'default';
  if PrefersDark then
    Result := 'dark';
end;

end.
