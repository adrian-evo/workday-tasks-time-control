:: Run tasks from within working time tray icon menu
@echo off

:: Default env.json
set env=devdata/env.json

:: Edit this value for a custom wait time in seconds when executing tasks from tray icon
set wait=5

:: Set to true to use rcc silent flag otherwise set to false
set silent="true"

:: On first run, when Output folder does not exists, silent is false anyway to that to have progress visible
echo "%cd%\output"
if not exist "%cd%\output" (
  set silent="false"
)

:: If run without arguments, ask it
:ASK
set "MyChoice=%~1"
setlocal EnableDelayedExpansion

if "!MyChoice!"=="" ( 
  set MyChoice=Icon
  set /p MyChoice="Type the task to execute: In, Out, Verify, Custom, Icon [!MyChoice!]: "
  :: Check the choice is valid
  if "!MyChoice!" == "In" set valid=1
  if "!MyChoice!" == "Out" set valid=1
  if "!MyChoice!" == "Verify" set valid=1
  if "!MyChoice!" == "Custom" set valid=1
  if "!MyChoice!" == "Icon" set valid=1
  if "!MyChoice!" == "Startup" set valid=1
  if "!MyChoice!" == "Language" set valid=1
  if not defined valid (
    echo The !MyChoice! is invalid task. Please choose a valid task or close window to exit.
    goto ASK
  )
)

:: Startup choice will add or remove a shortcut to Windows Startup folder, that will automatically restart the Icon after computer restart
if "!MyChoice!" == "Startup" (
  if exist "%userprofile%\Start Menu\Programs\Startup\%~n0.lnk" (
    echo The file %userprofile%\Start Menu\Programs\Startup\%~n0.lnk will be deleted now.
    pause
    del "%userprofile%\Start Menu\Programs\Startup\%~n0.lnk"
  ) else (
    echo The file %userprofile%\Start Menu\Programs\Startup\%~n0.lnk will be created and will be executed at computer restart.
    pause
    powershell "$s=(New-Object -COM WScript.Shell).CreateShortcut('%userprofile%\Start Menu\Programs\Startup\%~n0.lnk');$s.TargetPath='%~f0';$s.WorkingDirectory='%~dp0';$s.Arguments='Icon';$s.Save()"
  )
  exit
)

echo .
echo .
echo The Check-!MyChoice! task will be executed in !wait! seconds. Press any key to continue.
echo .
timeout /t !wait!

:: During icon task, check and disable anonymous tracking if enabled.
if "!MyChoice!"=="Icon" ( 
	rcc configure identity --do-not-track
)

:: Read controller value from env.json
for /f "tokens=1,2 delims=:{} " %%A in (!env!) do (
    if "%%~A"=="CONTROLLER" set "%%~A=%%~B"
)
echo rcc controller is: !CONTROLLER!

:: execute the task choice
if !silent! == "true" (
  cmd /c rcc run -t !MyChoice! -e !env! --silent --controller !CONTROLLER!
) else (
  cmd /c rcc run -t !MyChoice! -e !env! --controller !CONTROLLER!
)
