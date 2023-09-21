*** Settings ***
Documentation   App keywords that are executed for Check in out tasks. 

Library  RPA.Browser.Selenium
Library  RPA.Excel.Files
Library  RPA.JSON
Library  Dialogs

Resource  ./src/common-keywords.robot
Variables  ./src/taskslocales.py


*** Variables ***
${BROWSER_TIMEOUT}  30s


*** Keywords ***
Check In App Task
    [Documentation]  Check in App task
    # activated from Level 2
    Open Checkin App

    # Do check in action with a click (e.g. a 'Check In' button) if the case, otherwise wait for user to click manually
    &{env}  Load JSON From File    %{VAULT_FILE}
    IF    ${env.LEVEL_3_ACTIONS.DO_CHECKIN_ACTION} == True
        # ... replace here this Pause Execution with the automatic check in action
        #Pause Execution    ${TRANS.get('Automatic check in action was not implemented.')}

        # Find first empty row and fill current checkin date and time in the 'Check In' column
        ${next} =    Find Empty Row
        ${date_now}    Get Current Date
        Set Cell Value    ${next}    1    ${date_now}
        Save Workbook
    ELSE
        #Pause Execution    ${TRANS.get('Please click [Check In] button and then press OK to continue.')}
        Pause Execution    ${TRANS.get('Please record the time and then press OK to continue')}
    END

Check Out App Task
    [Documentation]  Check out App task
    # activated from Level 2
    Open Checkin App

    # Do check in action with a click (e.g. a 'Check Out' button) if the case, otherwise wait for user to click manually
    &{env}  Load JSON From File    %{VAULT_FILE}
    IF    ${env.LEVEL_3_ACTIONS.DO_CHECKOUT_ACTION} == True
        # ... replace here this Pause Execution with the automatic check out action
        #Pause Execution    ${TRANS.get('Automatic check out action was not implemented.')}

        # Find first empty row and fill current checkout date and time in the 'Check Out' column
        ${next} =    Find Empty Row
        ${date_now}    Get Current Date
        Set Cell Value    ${next-1}    2    ${date_now}
        Save Workbook
    ELSE
        Pause Execution    ${TRANS.get('Please record the time and then press OK to continue')}
    END

Verify App Task
    [Documentation]  Verify App task
    # activated from Level 2
    &{env}  Load JSON From File    %{VAULT_FILE}
    IF    '${{ sys.platform }}' == 'win32'
        Log    ${{ os.startfile("${env.MY_DATA.CHECKIN.URL}") }}
    ELSE
        Log    ${{ subprocess.call(["open", "${env.MY_DATA.CHECKIN.URL}"]) }}
    END

Open Checkin App
    [Documentation]  Open a browser and go to check in URL
    &{env}  Load JSON From File    %{VAULT_FILE}

    # When level 3 is enabled, edit excel directly without opening it, otherwise open it with system default application
    IF    ${env.LEVEL_3_ACTIONS.DO_CHECKIN_ACTION} == True
        Open Workbook    ${env.MY_DATA.CHECKIN.URL}
    ELSE
        IF    '${{ sys.platform }}' == 'win32'
            Log    ${{ os.startfile("${env.MY_DATA.CHECKIN.URL}") }}
        ELSE
            Log    ${{ subprocess.call(["open", "${env.MY_DATA.CHECKIN.URL}"]) }}
        END
    END

Custom App Task
    [Documentation]  Custom App task
    # activated from Level 2
    Open Custom App

    &{env}  Load JSON From File    %{VAULT_FILE}
    IF    ${env.LEVEL_3_ACTIONS.DO_CUSTOM_ACTION} == True
        Pause Execution    ${TRANS.get('Custom task action was not implemented!')}
    ELSE
        Pause Execution    ${TRANS.get('Custom task message action was not defined.')}
    END

Open Custom App
    [Documentation]  Open a browser and go to custom URL
    &{env}  Load JSON From File    %{VAULT_FILE}
    Open Available Browser    ${env.MY_DATA.CUSTOM.URL}    maximized=True
    Set Selenium Timeout    ${BROWSER_TIMEOUT}

Fill Custom Credentials
    [Documentation]  Filling username and password

    # Note: Disable and restore log level while retrieving password, in order to protect logging passwords
    &{env}  Load JSON From File    %{VAULT_FILE}
    ${level}  Set Log Level  NONE
    ${user}  ${pw}  Retrieve Custom Credentials
    Set Log Level  ${level}

    # specific username and password input
    Log    Not implemented
