*** Settings ***
Documentation     Basic REST AAA Tests for IdMLight
...	   	  
...	   	  Author: Carmen Kelling
...	   	  Copyright (c) 2021 Alpha Mobility, LLC - All rights reserved.
...	   	  
...	   	  This program and the accompanying materials are made available under the
...	   	  terms of the Eclipse Public License v1.0 which accompanies this distribution,
...	   	  and is available at http://www.eclipse.org/legal/ep1-v10.html
Suite Setup       IdMLight Suite Setup
Suite Teardown    IdMLight Suite Teardown
Library           Collections
Library           RequestsLibrary
Library           OperatingSystem
Library           String
Library           HttpLibrary.HTTP
Library           DateTime
Library           ../../../libraries/RequestsLibrary.py
Library           ../../../libraries/Common.py
Library           ../../../libraries/AAAJsonUtils.py
Resource          ../../../libraries/Utils.txt
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/AAAKeywords.txt


*** Variables ***
# port is fixed in Jetty configuration, as well
${URI}=    http://${CONTROLLER}:8282

# create lists for Domains, Roles and Users - by names - that can be cleaned up upon Teardown
@{cleanup_domain_list}
@{cleanup_role_list}
@{cleanup_user_list}

${headers}

*** Test Cases ***
Test Post New Domain
    [Documentation]    Create a domain using REST POST command. 
    Create Session    httpbin    ${URI}
    
    # create a temp name, set it to domainName 
    ${domainName}=    Create Random Name    domain-Other
    
    
    # Create the new domain, initialize some values to test against
    ${domaindesc}=    Set Variable    "testdomain other"
    ${domainstatus}=    Set Variable    "true"
    
    ${data}=    Set Variable    {"description":${domaindesc},"domainid":"7","name":\"${domainName}\","enabled":${domainstatus}}
    Log    ${data}
    ${domain}=    Post New Domain    ${domainName}    ${data} 
    Log    ${domain}
    
    # parse out the domain-id from the domain info we just created
    ${x}=    Split String    ${domain}    ,
    ${y}=    Get From List   ${x}    0
    ${z}=    Split String    ${y}    :
    ${domainid_}=    Get From List   ${z}    1
    ${domainid}=    Replace String    ${domainid_}    "    ${EMPTY}
    Log    ${domainid}
    
    # get the domain to verify
    ${fetched_domain}=    Get Specific Domain    ${domainid}

    # add new domain json string to the cleanup list for later cleanup 
    Append To List    ${cleanup_domain_list}    ${fetched_domain}
    
    # count the number of domainid's that appear in this block of JSON
    ${depth}=    Fieldcount    ${fetched_domain}    "domainid"
    ${fetchedDomStatus}=    Get Domain State By Domainid    ${domain}    ${domainid}    ${depth}
    ${fetchedDomDesc}=    Get Domain Description By Domainid    ${domain}    ${domainid}    ${depth}

    # Set Test Disposition based on comparison of what was posted and what was fetched
    # if checks MAGIC
    ${testdisposition}=    Set Variable If    '${fetched_domain}' == '${domain}'    '${fetchedDomStatus}' == '${domainstatus}'    '${fetchedDomDesc}' == '${domaindesc}'
    Log    ${testdisposition}
    
Test Get Domains
    [Documentation]    Exercise REST command for domains GET command.
    Create Session    httpbin    ${URI}
    
    # rely on the creation of a test role in the Setup routine
    # pop item off of end of the list, for use (does not alter list)
    Log    ${cleanup_domain_list}
    ${domain_item}=     Get From List    ${cleanup_domain_list}    -1
    Log    ${domain_item}
 
    # parse out the userid from the user info we just grabbed
    ${x}=    Split String    ${domain_item}    ,
    ${y}=    Get From List   ${x}    0
    ${z}=    Split String    ${y}    :
    ${domainid_}=    Get From List   ${z}    1
    ${domainid}=    Replace String    ${domainid_}    "    ${EMPTY}
    Log    ${domainid}
  
    # parse out the name from the same info
    ${x}=    Split String    ${domain_item}    ,
    ${y}=    Get From List   ${x}    1
    ${z}=    Split String    ${y}    :
    ${domain_}=    Get From List   ${z}    1
    ${domainname}=    Replace String    ${domain_}    "    ${EMPTY}
    Log    ${domainname}

    # get the entire blob of domains
    ${content}=    Get Domains

    # parse through that massive blob and get the individual name
    ${node_count}=     Nodecount    ${content}    domains    domainid
    ${domainid}=    Convert To Integer    ${domainid}
    ${domainentry}=    Get Domain Name By Domainid    ${content}    ${domainid}    ${node_count}
    Log    ${domainentry}
    
    # compare to see if the parsed user id matches the one we grabbed from list
    Should Be Equal    ${domainentry}   ${domainname}   

Test Get Specific Domain
    [Documentation]    Get a specific domain using REST GET command.   
    Log    "Leverage an available domain created in Suite Setup."
    Create Session    httpbin    ${URI}

    # from the pre-created (see Setup routine) list, grab a domain id for testing
    ${llength}=    Get Length    ${cleanup_domain_list}
    # pop item off of end of the list, for use (does not alter list)
    Log    ${cleanup_domain_list}
    ${domain_item}=     Get From List    ${cleanup_domain_list}    -1
    ${item}=    Pop Name Off Json    ${domain_item}
    # convert this crap to unicode
    # ${item}=    Convert To String    ${item}
    Log    ${item}
    # make a GET call to find the material we want to delete
    ${domains}=    Get Domains

    # convert name on the list to an ID, by which we delete this stuff
    ${node_count}=    Nodecount    ${domains}    domains    domainid
    ${node_count}=    Convert To Integer    ${node_count}
    ${domainid}=    Get Domain Id By Domainname    ${domains}    ${item}    ${node_count} 

    # now, get the specific domain by it's domainid
    ${domaininfo}=    Get Specific Domain    ${domainid}
    Should Contain    ${domaininfo}    ${item}
    Log    ${domaininfo}


Test Update Single Domain
    [Documentation]    Update a specific domain using REST PUT command.
    Create Session     httpbin    ${URI}

    # FIX THIS:   Don't use #1, instead take one from test list, and update it
    ${domid}=    Get Specific Domain    1
    ${data}=    Set Variable    {"name":"MasterTest Domain"}
    Update Single Domain    ${data}   1

    ${domname}=    Get Specific Domain Name    1
    Log    ${domname}

    ${z}=    Split String    ${data}    :
    ${dname}=    Get From List   ${z}    1
    ${dname}=    Replace String    ${dname}    "    ${EMPTY}
    ${dname}=    Replace String    ${dname}    }    ${EMPTY}
    Log    ${dname}
    ${modified_name}=    Pop Name Off Json    ${domname}
    Log    ${modified_name}

    Should Be Equal   ${dname}    ${modified_name}

Test Delete Domain
    [Documentation]    Delete a specific domain using REST DELETE command.
    Create Session     httpbin    ${URI}
    #
    # create a temporary test domain
    ${tempdomain}=    Create Random Name    temp-domain-name 
    ${domaindata}=    Set Variable    {"description":"temporary test domain","domainid":"1","name":"${tempdomain}","enabled":"true"}
    ${newdomain}=    Post New Domain    ${tempdomain}    ${domaindata}
    Log    ${newdomain}  

    # parse out the domain-id from the domain info we just created
    ${x}=    Split String    ${newdomain}    ,
    ${y}=    Get From List   ${x}    0
    ${z}=    Split String    ${y}    :
    ${domainid_}=    Get From List   ${z}    1
    ${domainid}=    Replace String    ${domainid_}    "    ${EMPTY}
    Log    ${domainid}

    # now wipe if off the map
    Delete Domain    ${domainid}
    
    # should fail...
    ${content}=    Negative Get Specific Domain    ${domainid}
    Log    ${content}
    # FIX THIS:  get rid of Negative Get Specific Domain, have the Tests Parse and test the output


Test Get Specific Role
    [Documentation]    Exercise REST command for roles GET command.
    Create Session    httpbin    ${URI}

    # from the pre-created (see Setup routine) list, grab a role id for testing
    ${llength}=    Get Length    ${cleanup_role_list}

    # pop item off of end of the list, for use (does not alter list)
    Log    ${cleanup_role_list}
    ${role_item}=     Get From List    ${cleanup_role_list}    -1
    Log    ${role_item}
    # parse out the role-id from the role info we just created
    ${x}=    Split String    ${role_item}    ,
    ${y}=    Get From List   ${x}    0
    ${z}=    Split String    ${y}    :
    ${roleid_}=    Get From List   ${z}    1
    ${roleid}=    Replace String    ${roleid_}    "    ${EMPTY}
    Log    ${roleid}

    # make a GET call to find the material we want 
    ${existing_roleitem}=    Get Specific Role    ${roleid}
    ${a}=    Split String    ${existing_roleitem}    ,
    ${b}=    Get From List   ${a}    0
    ${c}=    Split String    ${b}    :
    ${eroleid_}=    Get From List   ${c}    1
    ${eroleid}=    Replace String    ${eroleid_}    "    ${EMPTY}
    Log    ${eroleid}
    
    # compare to see if the GOTTEN role id matches the one we grabbed from list
    Should Be Equal    ${eroleid}   ${roleid}   


Test Get Roles
    [Documentation]    Exercise REST command for roles GET command.
    Create Session    httpbin    ${URI}
    
    # rely on the creation of a test role in the Setup routine
    # pop item off of end of the list, for use (does not alter list)
    Log    ${cleanup_role_list}
    ${role_item}=     Get From List    ${cleanup_role_list}    -1
    Log    ${role_item}
 
    # parse out the userid from the user info we just grabbed
    ${x}=    Split String    ${role_item}    ,
    ${y}=    Get From List   ${x}    0
    ${z}=    Split String    ${y}    :
    ${roleid_}=    Get From List   ${z}    1
    ${roleid}=    Replace String    ${roleid_}    "    ${EMPTY}
    Log    ${roleid}
  
    # parse out the name from the same info
    ${x}=    Split String    ${role_item}    ,
    ${y}=    Get From List   ${x}    1
    ${z}=    Split String    ${y}    :
    ${role_}=    Get From List   ${z}    1
    ${rolename}=    Replace String    ${role_}    "    ${EMPTY}
    Log    ${rolename}

    # get the entire blob of roles
    ${content}=    Get Roles

    # parse through that massive blob and get the individual name
    ${node_count}=     Nodecount    ${content}    roles    roleid
    ${roleid}=    Convert To Integer    ${roleid}
    ${roleentry}=    Get Role Name By Roleid    ${content}    ${roleid}    ${node_count}
    Log    ${roleentry}
    
    # compare to see if the parsed user id matches the one we grabbed from list
    Should Be Equal    ${roleentry}   ${rolename}   


Test Update Role
    [Documentation]    Exercise PUT command against an existing Role ID.
    Create Session    httpbin    ${URI}

    # pop item off of end of the list, for use (does not alter list)
    Log    ${cleanup_role_list}
    ${role_item}=     Get From List    ${cleanup_role_list}    -1
    Log    ${role_item}

    # parse out the role-id from the role info we just created
    ${x}=    Split String    ${role_item}    ,
    ${y}=    Get From List   ${x}    0
    ${z}=    Split String    ${y}    :
    ${roleid_}=    Get From List   ${z}    1
    ${roleid}=    Replace String    ${roleid_}    "    ${EMPTY}
    Log    ${roleid}

    # update the information for the roleid
    ${testrolename}=    Create Random Name    force-accomplish
    ${data}=    Set Variable    {"description":"sample test description", "name":"${testrolename}"}
    ${content}=    Update Specific Role    ${data}    ${roleid}
    Log    ${testrolename}

    # now, make a GET call to find the material we modified
    ${existing_roleitem}=    Get Specific Role    ${roleid}
    ${a}=    Split String    ${existing_roleitem}    ,
    ${b}=    Get From List   ${a}    1
    ${c}=    Split String    ${b}    :
    ${expected_rolename}=    Get From List   ${c}    1
    ${expected_rolename}=    Replace String    ${expected_rolename}    "    ${EMPTY}
    Log    ${expected_rolename}
    
    # compare to see if the GOTTEN role id matches the one we grabbed from list
    Should Be Equal    ${expected_rolename}   ${testrolename}   


Test Post New Role
    [Documentation]    Exercise POST command to create a new Role.
    Create Session    httpbin    ${URI}

    # create information for a new role (for the test)
    ${testrolename}=    Create Random Name    force-brother-cousin
    ${data}=    Set Variable    {"description":"sample test description", "name":"${testrolename}", "roleid":1}
    Log    ${testrolename}

    # Post this puppy
    ${content}=    Post New Role    ${data}

    # parse out the role-id from the content we just created
    ${x}=    Split String    ${content}    ,
    ${y}=    Get From List   ${x}    0
    ${z}=    Split String    ${y}    :
    ${roleid}=    Get From List   ${z}    1
    Log    ${roleid}

    # now got GET the roleid info and compare to the name we fabricated
    # and parse out role name
    ${existing_roleitem}=    Get Specific Role    ${roleid}
    ${a}=    Split String    ${existing_roleitem}    ,
    ${b}=    Get From List   ${a}    1
    ${c}=    Split String    ${b}    :
    ${expected_rolename}=    Get From List   ${c}    1
    ${expected_rolename}=    Replace String    ${expected_rolename}    "    ${EMPTY}
    Log    ${expected_rolename}
    
    # compare to see if the GOTTEN role id matches the one we grabbed from list
    Should Be Equal    ${expected_rolename}   ${testrolename}   


Test Delete Role
    [Documentation]    Exercise REST command for DELETE role command.
    Create Session    httpbin    ${URI}
    # create a role and then delete it.  Use Get to verify it's gone

    # create information for a new role (for the test)
    ${testrolename}=    Create Random Name    force-usurper
    ${data}=    Set Variable    {"description":"sample test description", "name":"${testrolename}", "roleid":1}
    Log    ${testrolename}

    # Post this disposable role
    ${content}=    Post New Role    ${data}

    # parse out the role-id from the content we just created
    ${x}=    Split String    ${content}    ,
    ${y}=    Get From List   ${x}    0
    ${z}=    Split String    ${y}    :
    ${roleid}=    Get From List   ${z}    1
    Log    ${roleid}

    # now delete it...
    ${content2}=    Delete Role    ${roleid}

    # should fail...
    ${content}=    Negative Get Specific Role    ${roleid}
    Log    ${content}
    # FIX THIS:  get rid of Negative Get Specific Role, have the Tests Parse and test the output


Test Get Users
    [Documentation]    Exercise REST command for users GET command.
    Create Session    httpbin    ${URI}
    
    # rely on the creation of a test user in the Setup routine
    # pop item off of end of the list, for use (does not alter list)
    Log    ${cleanup_user_list}
    ${user_item}=     Get From List    ${cleanup_user_list}    -1
    Log    ${user_item}
 
    # parse out the userid from the user info we just grabbed
    ${x}=    Split String    ${user_item}    ,
    ${y}=    Get From List   ${x}    0
    ${z}=    Split String    ${y}    :
    ${userid_}=    Get From List   ${z}    1
    ${userid}=    Replace String    ${userid_}    "    ${EMPTY}
    Log    ${userid}
  
    # parse out the name from the same info
    ${x}=    Split String    ${user_item}    ,
    ${y}=    Get From List   ${x}    1
    ${z}=    Split String    ${y}    :
    ${user_}=    Get From List   ${z}    1
    ${username}=    Replace String    ${user_}    "    ${EMPTY}
    Log    ${username}

    # get the entire blob of users
    ${content}=    Get Users

    # parse through that massive blob and get the individual name
    ${node_count}=     Nodecount    ${content}    users    userid
    ${userid}=    Convert To Integer    ${userid}
    ${userentry}=    Get User Name By Userid    ${content}    ${userid}    ${node_count}
    Log    ${userentry}
    
    # compare to see if the parsed user id matches the one we grabbed from list
    Should Be Equal    ${userentry}   ${username}   


Test Get Specific User
    [Documentation]    Exercise REST command for users GET command against a single user, based on userid.

    # Leverage the available user created in Suite Setup.
    Create Session    httpbin    ${URI}

    # from the pre-created (see Setup routine) list, grab a user id for testing
    ${llength}=    Get Length    ${cleanup_user_list}
    # pop item off of end of the list, for use (does not alter list)
    Log    ${cleanup_user_list}

    ${user_item}=     Get From List    ${cleanup_user_list}    -1
    ${item}=    Pop Name Off Json    ${user_item}
    # convert this to unicode
    # ${item}=    Convert To String    ${item}
    Log    ${item}

    # parse out the userid from the user info we just grabbed
    ${x}=    Split String    ${user_item}    ,
    ${y}=    Get From List   ${x}    0
    ${z}=    Split String    ${y}    :
    ${userid_}=    Get From List   ${z}    1
    ${userid}=    Replace String    ${userid_}    "    ${EMPTY}
    Log    ${userid}
  
    # parse out the name from the same info
    ${x}=    Split String    ${user_item}    ,
    ${y}=    Get From List   ${x}    1
    ${z}=    Split String    ${y}    :
    ${user_}=    Get From List   ${z}    1
    ${username}=    Replace String    ${user_}    "    ${EMPTY}
    Log    ${username}

    # make a GET call to find the material we want 
    ${content}=   Get Specific User   ${userid}

    # parse out the user name from the content we just fetched
    ${x}=    Split String    ${content}    ,
    ${y}=    Get From List   ${x}    1
    ${z}=    Split String    ${y}    :
    ${fetched_username}=    Get From List   ${z}    1
    Log    ${fetched_username}

    # compare to see if the parsed user name matches the one we grabbed from list
    Should Contain   ${fetched_username}       ${username}


Test Post New User
    [Documentation]    Test the POST command to create a new user.
    Create Session    httpbin    ${URI}

    # create information for a new role (for the test)
    ${testusername}=    Create Random Name    Darth-Maul
    ${data}=    Set Variable    {"description":"sample user description", "name":"${testusername}", "userid":1}
    Log    ${testusername}

    # Post this puppy
    ${content}=    Post New User    ${testusername}    ${data}

    # parse out the userid from the content we just created
    ${x}=    Split String    ${content}    ,
    ${y}=    Get From List   ${x}    0
    ${z}=    Split String    ${y}    :
    ${userid}=    Get From List   ${z}    1
    Log    ${userid}

    # now got GET the userid info and compare to the name we fabricated
    # and parse out user name
    ${existing_useritem}=    Get Specific User    ${userid}
    ${a}=    Split String    ${existing_useritem}    ,
    ${b}=    Get From List   ${a}    1
    ${c}=    Split String    ${b}    :
    ${expected_username}=    Get From List   ${c}    1
    ${expected_username}=    Replace String    ${expected_username}    "    ${EMPTY}
    Log    ${expected_username}
    
    # compare to see if the GOTTEN role id matches the one we grabbed from list
    Should Be Equal    ${expected_username}   ${testusername}   

Delete Domain User
Delete Domain User Role

Test Grant Role To Domain And User 
    # rely on the creation of a test role, user and domain in the Setup routine
    # pop item off of end of the list, for use (does not alter list)
    ${role_item}=     Get From List    ${cleanup_role_list}    -1
    Log    ${role_item}
    ${user_item}=     Get From List    ${cleanup_user_list}    -1
    Log    ${user_item}
    ${domain_item}=     Get From List    ${cleanup_domain_list}    -1
    Log    ${domain_item}
 
    # parse out the userid from the role info we just grabbed
    ${x}=    Split String    ${role_item}    ,
    ${y}=    Get From List   ${x}    0
    ${z}=    Split String    ${y}    :
    ${roleid_}=    Get From List   ${z}    1
    ${roleid}=    Replace String    ${roleid_}    "    ${EMPTY}
    Log    ${roleid}
  
    # parse out the name from the same info
    ${x}=    Split String    ${role_item}    ,
    ${y}=    Get From List   ${x}    1
    ${z}=    Split String    ${y}    :
    ${role_}=    Get From List   ${z}    1
    ${rolename}=    Replace String    ${role_}    "    ${EMPTY}
    Log    ${rolename}

    # parse out the userid from the user info we just grabbed
    ${x}=    Split String    ${user_item}    ,
    ${y}=    Get From List   ${x}    0
    ${z}=    Split String    ${y}    :
    ${userid_}=    Get From List   ${z}    1
    ${userid}=    Replace String    ${userid_}    "    ${EMPTY}
    Log    ${userid}
  
    # parse out the name from the same info
    ${x}=    Split String    ${user_item}    ,
    ${y}=    Get From List   ${x}    1
    ${z}=    Split String    ${y}    :
    ${user_}=    Get From List   ${z}    1
    ${username}=    Replace String    ${user_}    "    ${EMPTY}
    Log    ${username}

    # parse out the userid from the domain info we just grabbed
    ${x}=    Split String    ${domain_item}    ,
    ${y}=    Get From List   ${x}    0
    ${z}=    Split String    ${y}    :
    ${domainid_}=    Get From List   ${z}    1
    ${domainid}=    Replace String    ${domainid_}    "    ${EMPTY}
    Log    ${domainid}
  
    # parse out the name from the same info
    ${x}=    Split String    ${domain_item}    ,
    ${y}=    Get From List   ${x}    1
    ${z}=    Split String    ${y}    :
    ${domain_}=    Get From List   ${z}    1
    ${domainname}=    Replace String    ${domain_}    "    ${EMPTY}
    Log    ${domainname}

    # generate the data payload that we wish to post
    ${data}=    Set Variable    {"roleid":"${roleid}", "description":"fabricated test roleid"}

    # post this monster 
    ${content}=    Post Role To Domain And User    ${data}    ${domainid}    ${userid}

    Should Contain    ${content}    ${domainid}
    Should Contain    ${content}    ${roleid}
    Should Contain    ${content}    ${userid}
   

Test Get Role For Domain And User 
    # rely on the creation of a test role, user and domain in the Setup routine
    # pop item off of end of the list, for use (does not alter list)
    ${role_item}=     Get From List    ${cleanup_role_list}    -1
    Log    ${role_item}
    ${user_item}=     Get From List    ${cleanup_user_list}    -1
    Log    ${user_item}
    ${domain_item}=     Get From List    ${cleanup_domain_list}    -1
    Log    ${domain_item}
 
    # parse out the roleid from the role info we just grabbed
    ${x}=    Split String    ${role_item}    ,
    ${y}=    Get From List   ${x}    0
    ${z}=    Split String    ${y}    :
    ${roleid_}=    Get From List   ${z}    1
    ${roleid}=    Replace String    ${roleid_}    "    ${EMPTY}
    Log    ${roleid}
  
    # parse out the name from the same info
    ${x}=    Split String    ${role_item}    ,
    ${y}=    Get From List   ${x}    1
    ${z}=    Split String    ${y}    :
    ${role_}=    Get From List   ${z}    1
    ${rolename}=    Replace String    ${role_}    "    ${EMPTY}
    Log    ${rolename}

    # parse out the userid from the user info we just grabbed
    ${x}=    Split String    ${user_item}    ,
    ${y}=    Get From List   ${x}    0
    ${z}=    Split String    ${y}    :
    ${userid_}=    Get From List   ${z}    1
    ${userid}=    Replace String    ${userid_}    "    ${EMPTY}
    Log    ${userid}
  
    # parse out the name from the same info
    ${x}=    Split String    ${user_item}    ,
    ${y}=    Get From List   ${x}    1
    ${z}=    Split String    ${y}    :
    ${user_}=    Get From List   ${z}    1
    ${username}=    Replace String    ${user_}    "    ${EMPTY}
    Log    ${username}

    # parse out the userid from the domain info we just grabbed
    ${x}=    Split String    ${domain_item}    ,
    ${y}=    Get From List   ${x}    0
    ${z}=    Split String    ${y}    :
    ${domainid_}=    Get From List   ${z}    1
    ${domainid}=    Replace String    ${domainid_}    "    ${EMPTY}
    Log    ${domainid}
  
    # parse out the name from the same info
    ${x}=    Split String    ${domain_item}    ,
    ${y}=    Get From List   ${x}    1
    ${z}=    Split String    ${y}    :
    ${domain_}=    Get From List   ${z}    1
    ${domainname}=    Replace String    ${domain_}    "    ${EMPTY}
    Log    ${domainname}

    # generate the data payload that we wish to post
    ${data}=    Set Variable    {"roleid":"${roleid}", "description":"fabricated test roleid"}

    # post this monster 
    ${content}=    Post Role To Domain And User    ${data}    ${domainid}    ${userid}

    # now, Get that monster back and verify
    ${get_content}=    Get Roles For Specific Domain And User   ${domainid}    ${userid}

    # verify that what was posted is GOTTEN
    Should Contain    ${get_content}    ${rolename}

Test Delete A Grant
    # rely on the creation of a test role, user and domain in the Setup routine
    # pop item off of end of the list, for use (does not alter list)
    ${role_item}=     Get From List    ${cleanup_role_list}    -1
    Log    ${role_item}
    ${user_item}=     Get From List    ${cleanup_user_list}    -1
    Log    ${user_item}
    ${domain_item}=     Get From List    ${cleanup_domain_list}    -1
    Log    ${domain_item}
 
    # parse out the roleid from the role info we just grabbed
    ${x}=    Split String    ${role_item}    ,
    ${y}=    Get From List   ${x}    0
    ${z}=    Split String    ${y}    :
    ${roleid_}=    Get From List   ${z}    1
    ${roleid}=    Replace String    ${roleid_}    "    ${EMPTY}
    Log    ${roleid}
  
    # parse out the name from the same info
    ${x}=    Split String    ${role_item}    ,
    ${y}=    Get From List   ${x}    1
    ${z}=    Split String    ${y}    :
    ${role_}=    Get From List   ${z}    1
    ${rolename}=    Replace String    ${role_}    "    ${EMPTY}
    Log    ${rolename}

    # parse out the userid from the user info we just grabbed
    ${x}=    Split String    ${user_item}    ,
    ${y}=    Get From List   ${x}    0
    ${z}=    Split String    ${y}    :
    ${userid_}=    Get From List   ${z}    1
    ${userid}=    Replace String    ${userid_}    "    ${EMPTY}
    Log    ${userid}
  
    # parse out the name from the same info
    ${x}=    Split String    ${user_item}    ,
    ${y}=    Get From List   ${x}    1
    ${z}=    Split String    ${y}    :
    ${user_}=    Get From List   ${z}    1
    ${username}=    Replace String    ${user_}    "    ${EMPTY}
    Log    ${username}

    # parse out the userid from the domain info we just grabbed
    ${x}=    Split String    ${domain_item}    ,
    ${y}=    Get From List   ${x}    0
    ${z}=    Split String    ${y}    :
    ${domainid_}=    Get From List   ${z}    1
    ${domainid}=    Replace String    ${domainid_}    "    ${EMPTY}
    Log    ${domainid}
  
    # parse out the name from the same info
    ${x}=    Split String    ${domain_item}    ,
    ${y}=    Get From List   ${x}    1
    ${z}=    Split String    ${y}    :
    ${domain_}=    Get From List   ${z}    1
    ${domainname}=    Replace String    ${domain_}    "    ${EMPTY}
    Log    ${domainname}

    # generate the data payload that we wish to post
    ${data}=    Set Variable    {"roleid":"${roleid}", "description":"fabricated test roleid"}

    # post this monster 
    ${content}=    Post Role To Domain And User    ${data}    ${domainid}    ${userid}

    # now, Get that monster back and verify
    ${get_content}=    Delete Specific Grant    ${domainid}    ${userid}    ${roleid}

    # verify that what was posted is GOTTEN
    Should Not Contain    ${get_content}    ${rolename}


Test Get Roles For Domain With User And Password
    # rely on the creation of a test role, user and domain in the Setup routine
    # pop item off of end of the list, for use (does not alter list)
    ${role_item}=     Get From List    ${cleanup_role_list}    -1
    Log    ${role_item}
    ${user_item}=     Get From List    ${cleanup_user_list}    -1
    Log    ${user_item}
    ${domain_item}=     Get From List    ${cleanup_domain_list}    -1
    Log    ${domain_item}
 
    # parse out the roleid from the role info we just grabbed
    ${x}=    Split String    ${role_item}    ,
    ${y}=    Get From List   ${x}    0
    ${z}=    Split String    ${y}    :
    ${roleid_}=    Get From List   ${z}    1
    ${roleid}=    Replace String    ${roleid_}    "    ${EMPTY}
    Log    ${roleid}
  
    # parse out the name from the same info
    ${x}=    Split String    ${role_item}    ,
    ${y}=    Get From List   ${x}    1
    ${z}=    Split String    ${y}    :
    ${role_}=    Get From List   ${z}    1
    ${rolename}=    Replace String    ${role_}    "    ${EMPTY}
    Log    ${rolename}

    # parse out the userid from the user info we just grabbed
    ${x}=    Split String    ${user_item}    ,
    ${y}=    Get From List   ${x}    0
    ${z}=    Split String    ${y}    :
    ${userid_}=    Get From List   ${z}    1
    ${userid}=    Replace String    ${userid_}    "    ${EMPTY}
    Log    ${userid}
  
    # parse out the name from the same info
    ${x}=    Split String    ${user_item}    ,
    ${y}=    Get From List   ${x}    1
    ${z}=    Split String    ${y}    :
    ${user_}=    Get From List   ${z}    1
    ${username}=    Replace String    ${user_}    "    ${EMPTY}
    Log    ${username}

    # parse out the user password from the same info
    ${x}=    Split String    ${user_item}    ,
    ${y}=    Get From List   ${x}    -1
    ${z}=    Split String    ${y}    :
    ${user_}=    Get From List   ${z}    1
    ${userpwd}=    Replace String    ${user_}    "    ${EMPTY}
    ${userpwd}=    Replace String    ${user_}    }    ${EMPTY}
    Log    ${userpwd}

    # parse out the userid from the domain info we just grabbed
    ${x}=    Split String    ${domain_item}    ,
    ${y}=    Get From List   ${x}    0
    ${z}=    Split String    ${y}    :
    ${domainid_}=    Get From List   ${z}    1
    ${domainid}=    Replace String    ${domainid_}    "    ${EMPTY}
    Log    ${domainid}
  
    # parse out the name from the same info
    ${x}=    Split String    ${domain_item}    ,
    ${y}=    Get From List   ${x}    1
    ${z}=    Split String    ${y}    :
    ${domain_}=    Get From List   ${z}    1
    ${domainname}=    Replace String    ${domain_}    "    ${EMPTY}
    Log    ${domainname}

    # generate the data payload that we wish to post
    ${data}=    Set Variable    {"roleid":"${roleid}", "description":"fabricated test roleid"}

    # post this monster 
    ${content}=    Post Role To Domain And User    ${data}    ${domainid}    ${userid}

    ${data}=    Set Variable    {"name":"${username}", "password":"${userpwd}"}
    ${content}=    Post Role To Domain With User And Password   ${data}    ${domainid}    ${userid}   ${roleid}

    # verify that what was posted is GOTTEN




*** Keywords ***
Validate That Authentication Fails With Wrong Token
    ${bad_token}=    Set Variable    notARealToken
    Make REST Transaction    401    ${bad_token}

Make REST Transaction
    [Arguments]    ${expected_status_code}    ${auth_data}=${EMPTY}
    Create Session    ODL_SESSION    ${URI}
    #  application/x-www-form-urlencoded
    Run Keyword If    "${auth_data}" != "${EMPTY}"    Set To Dictionary    ${headers}    Authorization    Bearer ${auth_data}
    ${resp}=    RequestsLibrary.Get    ODL_SESSION    ${OPERATIONAL_NODES_API}    headers=${headers}
    Log    STATUS_CODE: ${resp.status_code} CONTENT: ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    ${expected_status_code}
    Should Contain    ${resp.content}    nodes

IdMLight Suite Setup
    Log    Suite Setup
    # create a domain, role and user for testing.
    ${headers}=    Create Dictionary    Content-Type    application/json
    Log    ${headers}
    Set Global Variable    ${headers}
    # create a name to use in each case
    ${testdomain}=    Create Random Name    Alderaan
    Log    ${testdomain}
    ${testuser}=    Create Random Name    Leia
    Log    ${testuser}
    ${testrole}=    Create Random Name    Force-User
    Log    ${testrole}
    
    # now create the domain, role and userid
    # create the test domain
    Create Session    httpbin    ${URI}
    ${domaindata}=    Set Variable    {"description":"planetary domain","domainid":"7","name":"${testdomain}","enabled":"true"}
    ${newdomain}=    Post New Domain    ${testdomain}    ${domaindata}
    Log    ${newdomain}
    # add new domain name to the cleanup list for later cleanup 
    Append To List    ${cleanup_domain_list}    ${newdomain}
    
    # now create the test user
    ${userdata}=    Set Variable    {"description":"User-of-the-Force","name":"${testuser}","enabled":"true"}
    ${newuser}=    Post New User    ${testuser}    ${userdata}
    Log    ${newuser}
    # add new user name to the cleanup list for later cleanup 
    Append To List    ${cleanup_user_list}    ${newuser}
    
    # now create the test role
    ${roledata}=    Set Variable    {"name":"${testrole}","description":"Force User"}
    ${newrole}=    Post New Role    ${roledata}
    # add new role name to the cleanup list for later cleanup 
    Append To List    ${cleanup_role_list}    ${newrole}
    #
    # return the three item names to the caller of setup
    [Return]    ${newdomain}    ${newuser}    ${newrole}


IdMLight Suite Teardown
    Log    Suite Teardown
    ${ELEMENT}=    Create Session    httpbin    ${URI}

    # make a GET call to find the material we want to delete
    #${domains}=    Get Domains
    #Log    ${domains}
    #${node_count}=     Nodecount    ${domains}    domains    "domainid"

    # if the test domain, role or user exists, wipe it out.
    :FOR    ${ELEMENT}    IN    @{cleanup_domain_list}
    \    ${ELEMENT}    Replace String    ${ELEMENT}    ${SPACE}    ${EMPTY}
    \	 Log    ${ELEMENT}
    \    # split it up to get the domainid
    \    ${x}=    Split String    ${ELEMENT}    ,
    \    ${y}=    Get From List   ${x}    0
    \    ${z}=    Split String    ${y}    :
    \    ${domainid}=    Get From List   ${z}    1
    \    Log    ${domainid}
    \    # convert name on the list to an ID, by which we delete this stuff
    \    Delete Domain    ${domainid}
    Log    ${cleanup_domain_list}
    
    # Cleanup roles that were created during testing
    :FOR    ${ELEMENT}    IN    @{cleanup_role_list}
    \    Log    ${ELEMENT}
    \    ${ELEMENT}    Replace String    ${ELEMENT}    ${SPACE}    ${EMPTY}
    \    Log    ${ELEMENT}
    \    # split it up to get the roleid
    \    ${x}=    Split String    ${ELEMENT}    ,
    \    ${y}=    Get From List   ${x}    0
    \    ${z}=    Split String    ${y}    :
    \    ${roleid}=    Get From List   ${z}    1
    \    Log    ${roleid}
    \    # convert name on the list to an ID, by which we delete this stuff
    \    Delete Role    ${roleid}
    Log    ${cleanup_role_list}
    
    # Cleanup users that were created during testing
    :FOR    ${ELEMENT}    IN    @{cleanup_user_list}
    \    Log    ${ELEMENT}
    \    ${ELEMENT}    Replace String    ${ELEMENT}    ${SPACE}    ${EMPTY}
    \    Log    ${ELEMENT}
    \    # split it up to get the roleid
    \    ${x}=    Split String    ${ELEMENT}    ,
    \    ${y}=    Get From List   ${x}    0
    \    ${z}=    Split String    ${y}    :
    \    ${userid}=    Get From List   ${z}    1
    \    Log    ${userid}
    \    Delete User    ${userid}
    Log    ${cleanup_user_list}
    
    Delete All Sessions
    
Negative Get Specific Domain
    [Arguments]    ${domainid}
    [Documentation]    Execute GET command on specified single domain
    ${n1}=    Set Variable    auth/v1/domains/${domainid}
    ${resp}    RequestsLibrary.Get    httpbin    ${n1}    headers=${headers}
    Should Be Equal As Strings    ${resp.status_code}    404
    ${domainid_string}=    Convert To String    ${domainid}
    Should Contain    ${resp.content}    ${domainid_string}
    [Return]    ${resp.content}


Negative Get Specific Role
    [Arguments]    ${roleid}
    [Documentation]    Execute GET command on specified single role
    ${n1}=    Set Variable    auth/v1/roles/${roleid}
    ${resp}    RequestsLibrary.Get    httpbin    ${n1}    headers=${headers}
    Should Be Equal As Strings    ${resp.status_code}    404
    ${roleid_string}=    Convert To String    ${roleid}
    Should Contain    ${resp.content}    ${roleid_string}
    [Return]    ${resp.content}


Get Specific Domain
    [Arguments]    ${domainid}
    [Documentation]    Execute GET command on specified single domain
    ${n1}=    Set Variable    auth/v1/domains/${domainid}
    ${resp}    RequestsLibrary.Get    httpbin    ${n1}    headers=${headers}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${domainid_string}=    Convert To String    ${domainid}
    Should Contain    ${resp.content}    ${domainid_string}
    [Return]    ${resp.content}

Get Specific Domain Name
    [Arguments]    ${domainid}
    [Documentation]    Execute GET command on specified single domain
    ${n1}=    Set Variable    auth/v1/domains/${domainid}
    ${resp}    RequestsLibrary.Get    httpbin    ${n1}    headers=${headers}
    Log    ${resp.content}
    [Return]    ${resp.content}


Get Specific Role
    [Arguments]    ${roleid}
    [Documentation]    Exercise REST command to GET a specific role, based on role-id
    ${n1}=    Set Variable    auth/v1/roles/${roleid}
    ${resp}    RequestsLibrary.Get    httpbin    ${n1}    headers=${headers}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    ${roleid}
    [Return]    ${resp.content}

Get Domains
    [Documentation]    Execute getdomains GET command.
    ${n1}=    Set Variable    auth/v1/domains
    ${resp}    RequestsLibrary.Get    httpbin    ${n1}    headers=${headers}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    "domains"
    [Return]    ${resp.content}

Get Roles
    [Documentation]    Execute GET command to obtain list of roles.
    ${n1}=    Set Variable    auth/v1/roles
    ${resp}    RequestsLibrary.Get    httpbin    ${n1}    headers=${headers}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    "roles"
    [Return]    ${resp.content}


Get Specific User
    [Arguments]    ${user}
    [Documentation]    Exercise REST command for users GET command.
    ${n1}=    Set Variable    auth/v1/users/${user}
    ${resp}    RequestsLibrary.Get    httpbin    ${n1}    headers=${headers}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    ${user}
    [Return]    ${resp.content}


Get Users
    [Documentation]    GET the complete set of users.
    ${n1}=    Set Variable    auth/v1/users
    ${resp}    RequestsLibrary.Get    httpbin    ${n1}    headers=${headers}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    ${user}
    [Return]    ${resp.content}


Post New Domain
    [Arguments]    ${domain}    ${data}
    [Documentation]    Exercise REST command for domains POST command.
    ${n1}=    Set Variable    auth/v1/domains
    ${resp}    RequestsLibrary.Post    httpbin    ${n1}    headers=${headers}    data=${data}
    Should Be Equal As Strings    ${resp.status_code}    201
    Should Contain    ${resp.content}    ${domain}
    [Return]    ${resp.content}


Post New Role
    [Arguments]    ${data}
    [Documentation]    Use POST REST command to create specified Role.
    ${n1}=    Set Variable    auth/v1/roles
    ${resp}    RequestsLibrary.Post    httpbin    ${n1}    headers=${headers}    data=${data}
    #    HTTP/1.1 201 Created
    Should Be Equal As Strings    ${resp.status_code}    201
    [Return]    ${resp.content}


Post New User
    [Arguments]    ${username}    ${data}
    [Documentation]    Exercise REST command for users POST command.
    Create Session    httpbin    ${URI}
    ${n1}=    Set Variable    auth/v1/users
    ${resp}    RequestsLibrary.Post    httpbin    ${n1}    headers=${headers}    data=${data}
    
    # grab the list of users, count the list, and then search the list for the specific user id
    ${users}=    Get Users
    ${depth}=    Nodecount    ${users}    users    userid
    ${abc}=    Get User Id By Username    ${users}    ${username}    ${depth}
    
    Should Be Equal As Strings    ${resp.status_code}    201
    Should Contain    ${resp.content}    ${username}
    [Return]    ${resp.content}


Get User By Name
    [Arguments]    ${jsonblock}    ${property}
    [Documentation]    hand this function a block of Json, and it will find your
    ...    user by name and return userid
    ${foundit}=    Get From Dictionary    ${jsonblock}    ${property}


Update Single Domain 
    [Arguments]    ${data}    ${domainid}
    [Documentation]    Update the specified domainid with a new name specified in domain-name
    Create Session    httpbin    ${URI}
    ${n1}=    Set Variable    auth/v1/domains/${domainid}
    ${resp}    RequestsLibrary.Put     httpbin    ${n1}    headers=${headers}    data=${data}
    # Should Be Equal As Strings    ${resp.status_code}    201
    Log    ${resp.content}


Update Specific Role
    [Arguments]    ${data}    ${roleid}
    [Documentation]    Update the specified roleid with a new information name specified 
    Create Session    httpbin    ${URI}
    ${n1}=    Set Variable    auth/v1/roles/${roleid}
    ${resp}    RequestsLibrary.Put     httpbin    ${n1}    headers=${headers}    data=${data}
    # Should Be Equal As Strings    ${resp.status_code}    201
    Log    ${resp.content}


Delete Domain
    [Arguments]    ${domainid}
    [Documentation]    Delete the specified domain, by id
    Create Session    httpbin    ${URI}
    ${n1}=    Set Variable    auth/v1/domains/${domainid}
    Log    ${n1}
    ${resp}    RequestsLibrary.Delete    httpbin    ${n1}    headers=${headers}
    Should Be Equal As Strings    ${resp.status_code}    204
    Log    ${resp.content}


Delete User
    [Arguments]    ${userid}
    [Documentation]    Delete the specified user, by id
    Create Session    httpbin    ${URI}
    ${n1}=    Set Variable    auth/v1/users/${userid}
    ${resp}    RequestsLibrary.Delete    httpbin    ${n1}    headers=${headers}
    Should Be Equal As Strings    ${resp.status_code}    204
    Log    ${resp.content}


Delete Role
    [Arguments]    ${roleid}
    [Documentation]    Use DELETE REST command to wipe out a Role created for testing.
    ${n1}=    Set Variable    auth/v1/roles/${roleid}
    ${resp}    RequestsLibrary.Delete    httpbin    ${n1}    headers=${headers} 
    Should Be Equal As Strings    ${resp.status_code}    204
    Should NOT Contain    ${resp.content}    ${roleid}
    [Return]    ${resp.content}


Post Role To Domain And User
    [Arguments]    ${data}    ${domainid}    ${userid}
    [Documentation]    Exercise REST POST command for posting a role to particular domain and user 
    ${n1}=    Set Variable    auth/v1/domains/${domainid}/users/${userid}/roles

    # now post it
    ${resp}    RequestsLibrary.Post    httpbin    ${n1}    headers=${headers}    data=${data}

    Should Be Equal As Strings    ${resp.status_code}    201
    [Return]    ${resp.content}


Get Roles For Specific Domain And User
    [Arguments]    ${domainid}    ${userid}
    [Documentation]    Exercise REST GET command for roles in a specific domain and user 
    ${n1}=    Set Variable    auth/v1/domains/${domainid}/users/${userid}/roles

    # now get it
    ${resp}    RequestsLibrary.Get    httpbin    ${n1}    headers=${headers}

    Should Be Equal As Strings    ${resp.status_code}    200
    [Return]    ${resp.content}


Delete Specific Grant    
    [Arguments]    ${domainid}    ${userid}    ${roleid}
    [Documentation]    Exercise REST DELETE command for a grant by roleid
    ${n1}=    Set Variable    auth/v1/domains/${domainid}/users/${userid}/roles/${roleid}

    # now delete it
    ${resp}    RequestsLibrary.Delete    httpbin    ${n1}    headers=${headers}

    Should Be Equal As Strings    ${resp.status_code}    204
    [Return]    ${resp.content}


Post Role To Domain With User And Password
    [Arguments]   ${data}    ${domainid}    ${userid}   ${roleid}
    [Documentation]    Exercise REST GET command for roles in a specific domain and user 
    ${n1}=    Set Variable    auth/v1/domains/${domainid}/users/${userid}/roles/${roleid}

    # now post it
    ${resp}    RequestsLibrary.Post    httpbin    ${n1}    headers=${headers}    data=${data}

    Should Be Equal As Strings    ${resp.status_code}    201
    [Return]    ${resp.content}


Create Random Name
    [Arguments]    ${basename}
    [Documentation]    Take the basename given and return a new name with date-time-stamp appended.
    ${datetime}=    Get Current Date     result_format=%Y-%m-%d-%H-%M
    Log    ${datetime}
    ${newname}=    Catenate    SEPARATOR=-    ${basename}    ${datetime}
    [Return]    ${newname}

Pop Name Off Json
    [Arguments]    ${jsonstring}
    [Documentation]   Pop the name item out of the Json string 
    # split it up to get the id
    ${x}=    Split String    ${jsonstring}    ,
    ${y}=    Get From List   ${x}    1
    ${z}=    Split String    ${y}    :
    ${name}=    Get From List   ${z}    1
    ${name}=    Replace String    ${name}    "    ${EMPTY}
    Log    ${name}
    [Return]    ${name}

    

Verify Contents
    [Arguments]    ${content_block}    ${keyvar}
    [Documentation]    Verify that the content block passed in, contains the variable identified in second argument
    Should Contain    ${content_block}    ${keyvar}
