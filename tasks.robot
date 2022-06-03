*** Settings ***
Documentation   Start and end of working day with Check in and out and Custom task actions

Library  RPA.JSON
Library  Dialogs
Library  DateTime

Variables  taskslocales.py

Resource  common-keywords.robot
Resource  %{APP_KEYWORDS}

*** Variables ***
${BROWSER_TIMEOUT}  30s


*** Tasks ***
Workday Check In
    [Documentation]  Check in and Custom daily tasks

     # verify if Check in App task should be performed and do it
    &{env}  Load JSON From File    %{VAULT_FILE}
    IF    ${env.LEVEL_2_ACTIONS.OPEN_CHECKIN_APP} == True
        Check In App Task
    END

    # save current check-in date and time to json file
    ${date_now}    Get Current Date
    ${new_env}    Update Value To JSON    ${env}    $.OUTPUT.CHECKIN_DATE    ${date_now}

    # save calculated check-out date to file
    ${date_out}  Add Time To Date    ${date_now}    ${env.MY_DATA.STANDARD_WORKING_TIME}
    ${new_env}    Update Value To JSON    ${new_env}    $.OUTPUT.CHECKOUT_CALC_DATE    ${date_out}
    Save JSON To File    ${new_env}    %{VAULT_FILE}    indent=4

    # display tray icon
    IF    ${env.LEVEL_1_ACTIONS.DISPLAY_TRAY_ICON} == True
        Display Check In Out Tray Icon
    END

    # if no over or undertime cumulated, assume 0 seconds
    ${text}    Set Variable If    '${env.OUTPUT.CUMULATED_OVER_UNDER_TIME}' == '${EMPTY}'
    ...    0 seconds
    ...    ${env.OUTPUT.CUMULATED_OVER_UNDER_TIME}

    # Welcome message
    IF    ${env.LEVEL_1_ACTIONS.SILENT_RUN} == False
        ${undover}    Set Variable If    '${text}[0]' == '-'    ${TRANS.get('You have total undertime:')}    ${TRANS.get('You have total overtime:')}
        Pause Execution     ${TRANS.get('Welcome!')} \n ${undover} ${text}
    ELSE
        Sleep    5s
    END

Workday Check Out
    [Documentation]  Check out task

    # verify if check-in was performed for today
    &{env}  Load JSON From File    %{VAULT_FILE}
    IF    '${env.OUTPUT.CHECKIN_DATE}' == '00:00' or '${env.OUTPUT.CHECKIN_DATE}' == ''
        Pause Execution    ${TRANS.get('Check-in time is not available for today (not performed or workday ended).')} ${TRANS.get('Cannot perform Check-out before Check-in.')}
        Pass Execution    pass
    END

     # verify if Check in App task should be performed and do it
    &{env}  Load JSON From File    %{VAULT_FILE}
    IF    ${env.LEVEL_2_ACTIONS.OPEN_CHECKOUT_APP} == True
        Check Out App Task
    END

    # calculate cumulated under or overtime to date
    ${today_working_time}    ${today_wt_diff}    ${total_wt_diff}    Calculate Working Times
    ${wt_text}    Convert Time    ${total_wt_diff}   verbose

    # save to json file
    ${new_env}    Update Value To JSON    ${env}    $.OUTPUT.CUMULATED_OVER_UNDER_TIME    ${wt_text}
    ${new_env}    Update Value To JSON    ${new_env}    $.OUTPUT.CHECKIN_DATE    00:00
    Save JSON To File    ${new_env}    %{VAULT_FILE}    indent=4

    IF    ${env.LEVEL_1_ACTIONS.DISPLAY_TRAY_ICON} == True
        Display Check In Out Tray Icon
    END

    # Goodbye message
    IF    ${env.LEVEL_1_ACTIONS.SILENT_RUN} == False
        ${undover}    Set Variable If    '${env.OUTPUT.CUMULATED_OVER_UNDER_TIME}[0]' == '-'    ${TRANS.get('You have total undertime:')}    ${TRANS.get('You have total overtime:')}
        Pause Execution     ${TRANS.get('Goodbye!')} \n ${undover} ${wt_text}
    ELSE
        Sleep    5s
    END
    
Workday Verify
    [Documentation]  Display check in App and calculated working times only (i.e. no actions)

    &{env}  Load JSON From File    %{VAULT_FILE}
    IF    ${env.LEVEL_2_ACTIONS.OPEN_CHECKIN_APP} == True
        Verify App Task
    END

    # verify if check-in was performed for today
    IF    '${env.OUTPUT.CHECKIN_DATE}' == '00:00' or '${env.OUTPUT.CHECKIN_DATE}' == ''
        Pause Execution    ${TRANS.get('Check-in time is not available for today (not performed or workday ended).')} ${TRANS.get('Please start with a Check-in task in the morning.')}
        Pass Execution    pass
    END

    # get working times
    ${today_working_time}    ${today_wt_diff}    ${total_wt_diff}    Calculate Working Times
    ${wt_text1}       Convert Time    ${today_wt_diff}   verbose
    ${wt_text2}       Convert Time    ${today_working_time}    verbose
    ${wt_text3}       Convert Time    ${total_wt_diff}   verbose

    ${text}    Set Variable If    ${today_wt_diff} < 0    ${TRANS.get('Today undertime')}    ${TRANS.get('Today overtime')}
    ${undover}    Set Variable If    '${wt_text3}[0]' == '-'    ${TRANS.get('You have total undertime:')}    ${TRANS.get('You have total overtime:')}

    # Message
    Pause Execution     ${TRANS.get('Worked so far:')} ${wt_text2} \n ${text}: ${wt_text1} \n ${undover} ${wt_text3}

Custom Task
    [Documentation]    Do Custom task only
    # verify if Custom task should be performed and do it
    &{env}  Load JSON From File    %{VAULT_FILE}
    IF    ${env.LEVEL_2_ACTIONS.OPEN_CUSTOM_APP} == True
        Custom App Task
    END
