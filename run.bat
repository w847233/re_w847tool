@echo off
setlocal

chcp 65001 >nul
cd /d "%~dp0"

set "FLUTTER_BIN=C:\tmp\flutter\bin\flutter.bat"
if not exist "%FLUTTER_BIN%" (
  set "FLUTTER_BIN=flutter"
)

echo [personal_toolbox] Running Flutter app on Windows...
echo [personal_toolbox] Project: %cd%
echo.

"%FLUTTER_BIN%" run -d windows %*
set "EXIT_CODE=%ERRORLEVEL%"

if not "%EXIT_CODE%"=="0" (
  echo.
  echo [personal_toolbox] Run failed with exit code %EXIT_CODE%.
  echo [personal_toolbox] If this is a toolchain error, run:
  echo   "%FLUTTER_BIN%" doctor -v
)

exit /b %EXIT_CODE%
