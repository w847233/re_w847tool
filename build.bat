@echo off
setlocal

chcp 65001 >nul
cd /d "%~dp0"

set "FLUTTER_BIN=C:\tmp\flutter\bin\flutter.bat"
if not exist "%FLUTTER_BIN%" (
  set "FLUTTER_BIN=flutter"
)

echo [personal_toolbox] Building Windows release package...
echo [personal_toolbox] Project: %cd%
echo.

"%FLUTTER_BIN%" build windows %*
set "EXIT_CODE=%ERRORLEVEL%"

if "%EXIT_CODE%"=="0" (
  echo.
  echo [personal_toolbox] Build completed.
  echo [personal_toolbox] Output:
  echo   %cd%\build\windows\x64\runner\Release
) else (
  echo.
  echo [personal_toolbox] Build failed with exit code %EXIT_CODE%.
  echo [personal_toolbox] If this is a toolchain error, run:
  echo   "%FLUTTER_BIN%" doctor -v
)

exit /b %EXIT_CODE%
