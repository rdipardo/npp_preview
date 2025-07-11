@Echo off

pushd %~dp0

where lazbuild >NUL: 2>&1
if %errorlevel%==0 ( goto :FPC )
if "%CI%" NEQ ""   ( goto :FPC )

:DELPHI
:: prepare to build the DLLs
call rsvars.bat

MSBuild /v:q /p:Config=Debug;Platform=Win32 /t:build src\prj\PreviewHTML.dproj > out\PreviewHTML_Win32_Debug.txt
if errorlevel 1 echo Compilation errors, aborting... && start "" out\PreviewHTML_Win32_Debug.txt && goto TheEnd

MSBuild /v:q /p:Config=Debug;Platform=Win64 /t:build src\prj\PreviewHTML.dproj > out\PreviewHTML_Win64_Debug.txt
if errorlevel 1 echo Compilation errors, aborting... && start "" out\PreviewHTML_Win64_Debug.txt && goto TheEnd

MSBuild /v:q /p:Config=Release;Platform=Win32 /t:build src\prj\PreviewHTML.dproj > out\PreviewHTML_Win32.txt
if errorlevel 1 echo Compilation errors, aborting... && start "" out\PreviewHTML_Win32.txt && goto TheEnd

MSBuild /v:q /p:Config=Release;Platform=Win64 /t:build src\prj\PreviewHTML.dproj > out\PreviewHTML_Win64.txt
if errorlevel 1 echo Compilation errors, aborting... && start "" out\PreviewHTML_Win64.txt && goto TheEnd

:FPC
SETLOCAL
set "FPC_PLATFORM=x86_64"
set "FPC_BUILD_TYPE=Debug"

if "%1" NEQ "" ( set "FPC_BUILD_TYPE=%1" )
if "%2" NEQ "" ( set "FPC_PLATFORM=%2" )
set "FPC_BUILD_ALL="
if "%3"=="clean" ( set "FPC_BUILD_ALL=-B" )

call :%FPC_PLATFORM% 2>NUL:
if %errorlevel%==1 ( goto :USAGE ) else ( goto :TheEnd )

:32
:i386
if "%FPC_BUILD_ALL%" NEQ "" ( rmdir /S /Q "out\i386-win32\%FPC_BUILD_TYPE%" 2>NUL: )
lazbuild %FPC_BUILD_ALL% --bm=%FPC_BUILD_TYPE% --cpu=i386 src\prj\PreviewHTML.lpi -q
goto :TheEnd

:64
:x86_64
if "%FPC_BUILD_ALL%" NEQ "" ( rmdir /S /Q "out\x86_64-win64\%FPC_BUILD_TYPE%" 2>NUL: )
lazbuild %FPC_BUILD_ALL% --bm=%FPC_BUILD_TYPE% --cpu=x86_64 src\prj\PreviewHTML.lpi -q
goto :TheEnd

:USAGE
echo Usage: ".\%~n0 [Debug,Release] [32,i386,64,x86_64] [clean]"

ENDLOCAL

:TheEnd
exit /B %errorlevel%
popd
