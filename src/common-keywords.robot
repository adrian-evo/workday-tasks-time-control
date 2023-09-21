*** Settings ***
Documentation   Common keywords

Library  RPA.JSON
Library  Dialogs
Library  DateTime
Library  String
Library  Process

Library  taskslocales.py
Variables  taskslocales.py


*** Keywords ***
Calculate Working Times
    [Documentation]  Return working times
    [Return]    ${today_working_time}    ${today_wt_diff}    ${total_wt_diff}

    # read today check-in date and time and standard working time from json file
    &{env}  Load JSON From File    %{VAULT_FILE}

    # 1. calculate already worked time today compared with check-in time
    ${date_now}  Get Current Date
    ${today_working_time}   Subtract Date From Date    ${date_now}     ${env.OUTPUT.CHECKIN_DATE}    exclude_millis=True

    # 2. calculate today under or overtime compared with standard working time
    ${today_wt_diff}  Subtract Time From Time    ${today_working_time}    ${env.MY_DATA.STANDARD_WORKING_TIME}

    # 3. calculate cumulated under or overtime to date
    ${amount}    Set Variable If    '${env.OUTPUT.CUMULATED_OVER_UNDER_TIME}' == '${EMPTY}'
    ...    0 seconds
    ...    ${env.OUTPUT.CUMULATED_OVER_UNDER_TIME}
    ${total_wt_diff}    Add Time To Time    ${amount}    ${today_wt_diff}

Retrieve Checkin Credentials
    [Documentation]  Get User and Password fields based on Title from vault json or Keepass database
    [Return]  ${user}  ${pw}

    &{env}  Load JSON From File    %{VAULT_FILE}

    # if user field from json is empty, try to use keyring specific database (Credential Manager or Keychain)
    IF    '${env.MY_DATA.CHECKIN.USER}' == '${EMPTY}'
        ${user}    Retrieve Username    ${env.MY_DATA.CHECKIN.SYSTEM}
    ELSE
        ${user}    Set Variable  ${env.MY_DATA.CHECKIN.USER}
    END
    IF    '${env.MY_DATA.CHECKIN.PASSWORD}' == '${EMPTY}'
        ${pw}    Retrieve Password    ${env.MY_DATA.CHECKIN.SYSTEM}    ${user}
    ELSE
        ${pw}    Set Variable  ${env.MY_DATA.CHECKIN.PASSWORD}
    END

Retrieve Custom Credentials
    [Documentation]  Get User and Password fields based on Title from vault json or Keepass database
    [Return]  ${user}  ${pw}

    &{env}  Load JSON From File    %{VAULT_FILE}

    # if user field from json is empty, try to use keyring specific database (Credential Manager or Keychain)
    IF    '${env.MY_DATA.CUSTOM.USER}' == '${EMPTY}'
        ${user}    Retrieve Username    ${env.MY_DATA.CUSTOM.SYSTEM}
    ELSE
        ${user}    Set Variable  ${env.MY_DATA.CUSTOM.USER}
    END
    IF    '${env.MY_DATA.CUSTOM.PASSWORD}' == '${EMPTY}'
        ${pw}    Retrieve Password    ${env.MY_DATA.CUSTOM.SYSTEM}    ${user}
    ELSE
        ${pw}    Set Variable  ${env.MY_DATA.CUSTOM.PASSWORD}
    END
    # fail if no user or password are retrieved
    IF    '${user}' == '${EMPTY}' or '${pw}' == '${EMPTY}'
        Pause Execution    ${TRANS.get('Cannot retrieve user or password. Check vault json file or the credential system under use.')}
        Fail
    END

