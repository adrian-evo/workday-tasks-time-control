#!/bin/sh
# This script will switch the url-keywords.robot file and conda.yaml between Selenium and Playwright code based

# different current directory when the script is double click from Finder
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd "${DIR}"

# Move to root directory
cd ..

# Assume if url-keywords.robot.sel file exists, then currently Playwright is used
if [ -f "pw/url-keywords.robot.sel" ]; then
  echo Switch Playwright environment to Selenium
  # Rename and move Playwright specific files
  mv url-keywords.robot pw/url-keywords.robot.pw
  mv conda.yaml pw/conda.yaml.pw

  # Move Selenium files to current directory
  mv pw/url-keywords.robot.sel url-keywords.robot
  mv pw/conda.yaml.sel conda.yaml
else 
  echo Switch Selenium environment to Playwright
  # Rename and move Selenium specific files
  mv url-keywords.robot pw/url-keywords.robot.sel
  mv conda.yaml pw/conda.yaml.sel

  # Copy Playwright files to current directory
  cp -P pw/url-keywords.robot.pw url-keywords.robot
  cp -P pw/conda.yaml.pw conda.yaml
fi


read -n 1 -s -r -p "Press any key to continue"
