*** Settings ***
Library    OperatingSystem
Library    String
Library    Collections

*** Variables ***

*** Test Cases ***
Test BlockParseTest
    [Documentation]    Ping the *IP address* from args, ping count # of times
    ${pingString}=     Run    ping -c ${count} ${IP}
    Log      ${pingString}
    
    FOR    ${ELEMENT}    IN    ${pingString}
        Log To Console    ${ELEMENT}
        # split it up to get the packet loss
        # there are three segments to look through:
        # section 1:
        #      PING 192.168.4.23 (192.168.4.23): 56 data bytes
        #      64 bytes from 192.168.4.23: icmp_seq=0 ttl=64 time=0.062 ms
        #      ...
        # section 2:
        #      --- 192.168.4.23 ping statistics ---
        # section 3:
        #      7 packets transmitted, 7 packets received, 0.0% packet loss
        #      round-trip min/avg/max/stddev = 0.062/0.089/0.104/0.019 ms

        # split the output around the triple-dashes in third section:
        ${lastline}=    Split String    ${ELEMENT}    ---
        ${thirdString}=    Get From List   ${lastline}    2

        # now take that section and split around the commas
        # take the first section
        #      7 packets transmitted, 7 packets received, 0.0% packet loss
        #      ...
        ${xmitInfo}=    Split String    ${thirdString}    ,
        ${xmitted}=    Get From List    ${xmitInfo}    0

        # now split that section out by the spaces, and take the first item
        #      7 packets transmitted
        ${xmitDetails}=    Split String    ${xmitted}    ${SPACE}
        ${pkts}=    Get From List    ${xmitDetails}    0
    END

    Should Be Equal As Integers    ${pkts}    ${count}
    Log to Console    \nexpected packets: ${count} \ntransmitted packets: ${pkts.strip()}
