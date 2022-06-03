*** Settings ***
Documentation   App keywords that are executed for Check in out tasks. 
...    Customised for a company specific application.

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
    #Fill Checkin Credentials

    # Do check in action with a click (e.g. a 'Check In' button) if the case, otherwise wait for user to click manually
    &{env}  Load JSON From File    %{VAULT_FILE}
    IF    ${env.LEVEL_3_ACTIONS.DO_CHECKIN_ACTION} == True
        # ... replace here this Pause Execution with the automatic check in action
        Pause Execution    ${TRANS.get('Automatic check in action was not implemented.')}
    ELSE
        Pause Execution    ${TRANS.get('Checkin message action was not defined.')}
    END

Check Out App Task
    [Documentation]  Check out App task
    # activated from Level 2
    Open Checkin App
    #Fill Checkin Credentials

    # Do check in action with a click (e.g. a 'Check Out' button) if the case, otherwise wait for user to click manually
    &{env}  Load JSON From File    %{VAULT_FILE}
    IF    ${env.LEVEL_3_ACTIONS.DO_CHECKOUT_ACTION} == True
        # ... replace here this Pause Execution with the automatic check out action
        Pause Execution    ${TRANS.get('Automatic check out action was not implemented.')}
    ELSE
        Pause Execution    ${TRANS.get('Checkout message action was not defined.')}
    END

Verify App Task
    [Documentation]  Verify App task
    # activated from Level 2
    Open Checkin App
    #Fill Checkin Credentials

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
        # specific username and password input
        Log    Not implemented
    END
    
Custom App Task
    [Documentation]  Custom App task
    # activated from Level 2
    Open Custom App
    #Fill Custom Credentials

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
