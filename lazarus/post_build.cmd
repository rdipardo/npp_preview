@echo off
::
:: Copyright (C) 2025 Robert Di Pardo
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
set "TARGET_PLATFORM=Win64"
set "TARGET_DIR="
if "%1" NEQ "" ( set "TARGET_PLATFORM=%1" )
if "%2" NEQ "" ( set "TARGET_DIR=%2" )
if NOT EXIST "%TARGET_DIR%" ( goto :USAGE )
call :%TARGET_PLATFORM% 2>NUL:
if %errorlevel% NEQ 0 ( goto :USAGE ) else ( goto :END )

:Win32
echo D | xcopy /DVY %~dp0..\src\WebView4Delphi\bin32\WebView2Loader.dll "%TARGET_DIR%"
goto :END

:Win64
echo D | xcopy /DVY %~dp0..\src\WebView4Delphi\bin64\WebView2Loader.dll "%TARGET_DIR%"
goto :END

:USAGE
echo Usage: ".\%~n0 [Win32,Win64] dll_target_path"

:END
exit /B %errorlevel%
ENDLOCAL
