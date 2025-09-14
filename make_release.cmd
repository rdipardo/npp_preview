@echo off
::
:: Copyright (C) 2024,2025 Robert Di Pardo
::
:: Permission to use, copy, modify, and/or distribute this software for any purpose
:: with or without fee is hereby granted.
::
:: THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
:: REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
:: AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
:: INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
:: LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE
:: OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
:: PERFORMANCE OF THIS SOFTWARE.
::
SETLOCAL

set "VERSION=1.4.1.0"
set "PLUGIN=PreviewHTML"
set "CONFIG_DIR=.\src\Config"
set "FPC_DIR=.\out\3RD-PARTY"
set "PLUGIN_DLLS=.\out\Win32\Release\*.dll"
set "PLUGINX64_DLLS=.\out\Win64\Release\*.dll"
set "SLUG_NAME=.\out\%PLUGIN%_v%VERSION%_win32"
set "SLUGX64_NAME=.\out\%PLUGIN%_v%VERSION%_x64"
set "SLUG=%SLUG_NAME%.zip"
set "SLUGX64=%SLUGX64_NAME%.zip"

del /S /Q /F .\out\*.zip 2>NUL:
call %~dp0build.cmd

xcopy /DIY LICENSE.txt .\out
xcopy /DIY ReleaseNotes.txt .\out
xcopy /DIY src\common\COPYING* %FPC_DIR%
@rem echo D | xcopy /DIY src\Microsoft.Web.WebView2\ "%FPC_DIR%\Microsoft.Web.WebView2"
echo D | xcopy /DIY src\WebView4Delphi\LICENSE "%FPC_DIR%\WebView4Delphi"
7z a -tzip "%SLUG%" "%PLUGIN_DLLS%" .\out\*.txt %CONFIG_DIR%\*.ini %FPC_DIR% -y
7z a -tzip "%SLUGX64%" "%PLUGINX64_DLLS%" .\out\*.txt %CONFIG_DIR%\*.ini %FPC_DIR% -y

ENDLOCAL
