*** Settings ***
Documentation   App keywords that are executed for Check in out tasks.

Library  RPA.Browser.Selenium
Library  RPA.JSON
Library  Dialogs

Resource  common-keywords.robot
Variables  taskslocales.py

*** Variables ***
${BROWSER_TIMEOUT}  30s


*** Keywords ***
Check In App Task
    [Documentation]  Check in App task
    # activated from Level 2
    Open Checkin App
    Fill Checkin Credentials

    # Do check in action with a click (e.g. a 'Check In' button) if the case, otherwise wait for user to click manually
    &{env}  Load JSON From File    %{VAULT_FILE}
    IF    ${env.LEVEL_3_ACTIONS.DO_CHECKIN_ACTION} == True
        # ... replace here this Pause Execution with the automatic check in action
        Pause Execution    ${TRANS.get('Automatic check in action was not implemented.')}
    ELSE
        Pause Execution    ${TRANS.get('Please click [Check In] button and then press OK to continue.')}
    END

Check Out App Task
    [Documentation]  Check out App task
    # activated from Level 2
    Open Checkin App
    Fill Checkin Credentials

    # Do check in action with a click (e.g. a 'Check Out' button) if the case, otherwise wait for user to click manually
    &{env}  Load JSON From File    %{VAULT_FILE}
    IF    ${env.LEVEL_3_ACTIONS.DO_CHECKOUT_ACTION} == True
        # ... replace here this Pause Execution with the automatic check out action
        Pause Execution    ${TRANS.get('Automatic check out action was not implemented.')}
    ELSE
        Pause Execution    ${TRANS.get('Please click [Check Out] button and then press OK to continue.')}
    END

Verify App Task
    [Documentation]  Verify App task
    # activated from Level 2
    Open Checkin App
    Fill Checkin Credentials

Open Checkin App
    [Documentation]  Open a browser and go to check in URL
    &{env}  Load JSON From File    %{VAULT_FILE}
    Open Available Browser    ${env.MY_DATA.CHECKIN.URL}    maximized=True
    Set Selenium Timeout    ${BROWSER_TIMEOUT}

Fill Checkin Credentials
    [Documentation]  Fill username and password

    # Note: Disable and restore log level while retrieving password, in order to protect logging passwords
    &{env}  Load JSON From File    %{VAULT_FILE}
    ${level}  Set Log Level  NONE
    ${user}  ${pw}  Retrieve Checkin Credentials
    Set Log Level  ${level}

    # in real situation it should fail if no user or password are retrieved
    IF    '${user}' == '${EMPTY}' or '${pw}' == '${EMPTY}' or '${user}' == 'None' or '${pw}' == 'None'
        Pause Execution    ${TRANS.get('Cannot retrieve user or password. Check vault json file or the credential system under use.')}
        #Fail
    ELSE
        Input Text    name:username    ${user}
        Click Button    id:login-signin

        Wait Until Element Is Visible    name:password
        Input Password    name:password    ${pw}
        Click Button    id:login-signin

        # Inbox should be visible
        Wait Until Element Is Visible    css=div[data-test-folder-container=Inbox]
    END

Custom App Task
    [Documentation]  Custom App task
    # activated from Level 2
    Open Custom App
    #Fill Custom Credentials

    # click "Log on" and wait for input or click "Enter regular hours"
    &{env}  Load JSON From File    %{VAULT_FILE}
    IF    ${env.LEVEL_3_ACTIONS.DO_CUSTOM_ACTION} == True
        Pause Execution    ${TRANS.get('Automatic custom action was not implemented.')}
        #Pause Execution    ${TRANS.get('Custom task action done!')}
    ELSE
        Pause Execution    ${TRANS.get('Please do custom task action and then press OK to continue!')}
    END

Open Custom App
    [Documentation]  Open a browser and go to custom URL
    &{env}  Load JSON From File    %{VAULT_FILE}
    Open Available Browser    ${env.MY_DATA.CUSTOM.URL}    maximized=True
    Set Selenium Timeout    ${BROWSER_TIMEOUT}

    # approve url cookie
    #Click Element When Visible    xpath=//button/span

Fill Custom Credentials
    [Documentation]  Filling username and password

    # Note: Disable and restore log level while retrieving password, in order to protect logging passwords
    &{env}  Load JSON From File    %{VAULT_FILE}
    ${level}  Set Log Level  NONE
    ${user}  ${pw}  Retrieve Custom Credentials
    Set Log Level  ${level}

    # Similar with above Fill Checkin Credentials if needed
    Log    do nothing
