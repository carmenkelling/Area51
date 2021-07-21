*** Settings ***
Library    OperatingSystem
Library    String

*** Test Cases ***
Test IPConfig
    ${frt}=     Run     ipconfig | find "IPv4"
    ${IP}=    Fetch From Right    ${frt}    ${SPACE}
    Log To Console     [${IP}]

Test Ping
    [Arguments]    ${ipaddr}
    ${count}=       4
    ${pingout}=    Ping    -c    ${count}    ${ipaddr}
