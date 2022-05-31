*** Settings ***
Documentation   Common keywords not related to url actions

Library  RPA.JSON
Library  Dialogs
Library  DateTime
Library  String
Library  Process

Library  trayicon.py
Library  taskslocales.py

Variables  taskslocales.py


*** Keywords ***
Display Check In Out Tray Icon
    [Documentation]  Display a tray icon with check-in and calculated check-out times as tooltip

    &{env}  Load JSON From File    %{JSON_FILE}
    ${running}    Is Tray Icon Running    ${env.OUTPUT.TRAY_ICON_PID}
    IF     not ${running}
        ${process}    Start Process    ${CURDIR}/run-tasks.bat    Icon
    END

Calculate Working Times
    [Documentation]  Return working times
    [Return]    ${today_working_time}    ${today_wt_diff}    ${total_wt_diff}

    # read today check-in date and time and standard working time from json file
    &{env}  Load JSON From File    %{JSON_FILE}

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

    &{env}  Load JSON From File    %{JSON_FILE}

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
    # fail if no user or password are retrieved
    IF    '${user}' == '${EMPTY}' or '${pw}' == '${EMPTY}'
        Pause Execution    ${TRANS.get('Cannot retrieve user or password. Check vault json file or the credential system under use.')}
        Fail
    END

Retrieve Custom Credentials
    [Documentation]  Get User and Password fields based on Title from vault json or Keepass database
    [Return]  ${user}  ${pw}

    &{env}  Load JSON From File    %{JSON_FILE}

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

