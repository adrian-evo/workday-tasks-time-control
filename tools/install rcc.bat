:: This batch file will check and create Rcc folder and download rcc.exe if does not exists
@echo off

echo This script will download rcc.exe from Robocorp, copy it under %userprofile%\Rcc and set the Path to it. Close this window to exit.
timeout 10

:: save script path
set REL_PATH=%~dp0..\
set SCRIPTS_PATH=
:: Save current directory and change to target directory
pushd %REL_PATH%
:: Save value of CD variable (current directory)
set SCRIPTS_PATH=%CD%
:: Restore original directory
popd


if not exist %userprofile%\Rcc\rcc.exe (
  mkdir %userprofile%\Rcc
  cd /D %userprofile%\Rcc
  curl -o rcc.exe https://downloads.robocorp.com/rcc/releases/latest/windows64/rcc.exe
  cd /D %~dp0
  powershell -ExecutionPolicy RemoteSigned -File  ".\add rcc path.ps1"
  goto END
) else (
  echo rcc.exe already installed under %userprofile%\Rcc. Press enter to update or close this window to exit.
  pause
)

:UPDATE
cd /D %userprofile%\Rcc
curl -o rcc.exe https://downloads.robocorp.com/rcc/releases/latest/windows64/rcc.exe
echo Rcc updated to the latest version.

:END
cd /D %SCRIPTS_PATH%
echo %SCRIPTS_PATH%
rcc configure identity --do-not-track
rcc configure identity

pause
