@echo off
@rem Adapted from 'SetVersion.bat', part of WebEdit <https://github.com/alex-ilin/WebEdit>
@rem License(?): https://www.softpedia.com/user/licensing_free.php
where sed 2>NUL:
if %errorlevel% NEQ 0 ( goto :EOF )
setlocal
set MAJ=0
set MIN=0
set REV=0
set BUILD=0
IF "%1" NEQ "" ( set "MAJ=%1" ) else ( goto :EOF )
IF "%2" NEQ "" ( set "MIN=%2" ) else ( goto :EOF )
IF "%3" NEQ "" ( set "REV=%3" ) else ( goto :EOF )
IF "%4" NEQ "" ( set "BUILD=%4" )
FOR /F "tokens=* USEBACKQ" %%F IN (`git ls-files -- "**.rc" "**_release.cmd"`) DO (
  sed -i -e "/\(PRODUCT\)/! s/\(^.*VERSION.*[ =\x22]\)[0-9]*\(\([0-9]\([.,]\)\)\{1,4\}[0-9]\)\(.*\)/\1%MAJ%\4%MIN%\4%REV%\4%BUILD%\5/g" %%F
  unix2dos %%F
)
endlocal
:EOF
exit /B %errorlevel%
