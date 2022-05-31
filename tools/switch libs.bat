:: This batch file switch the url-keywords.robot file and conda.yaml between Selenium and Playwright code based
@echo off

:: Move to root directory
cd ..

:: Assume if url-keywords.robot.sel file exists, then currently Playwright is used
if exist pw\url-keywords.robot.sel (
  goto :SELENIUM
) else (
  goto :PLAYWRIGHT
)

:PLAYWRIGHT
echo Switch Selenium environment to Playwright
:: Rename and move Selenium specific files
move url-keywords.robot pw\url-keywords.robot.sel
move conda.yaml pw\conda.yaml.sel

:: Copy Playwright files to current directory
copy pw\url-keywords.robot.pw url-keywords.robot /V
copy pw\conda.yaml.pw conda.yaml /V

goto :END


:SELENIUM
echo Switch Playwright environment to Selenium
:: Rename and move Playwright specific files
move url-keywords.robot pw\url-keywords.robot.pw
move conda.yaml pw\conda.yaml.pw

:: Move Selenium files to current directory
move pw\url-keywords.robot.sel url-keywords.robot
move pw\conda.yaml.sel conda.yaml


:END
pause