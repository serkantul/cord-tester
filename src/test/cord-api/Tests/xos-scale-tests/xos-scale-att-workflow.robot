*** Settings ***
Documentation    Scale up models in a SEBA deployment with no backends
Library           KafkaLibrary
Library           RequestsLibrary
Library           HttpLibrary.HTTP
Library           Collections
Library           String
Library           OperatingSystem
Library           DateTime
Library           ./utils/devices.py
Suite Setup       Setup
Suite Teardown    Teardown

*** Variables ***
${xos_chameleon_url}    xos-chameleon
${xos_chameleon_port}   9101
${num_olts}             1
${num_pon_ports}        1
${num_onus}             1
${timeout}              300s

*** Test Cases ***
Check OLTs Created
    ${res} =   CORD Get    /xosapi/v1/volt/oltdevices
    ${jsondata} =    To Json    ${res.content}
    ${length} =    Get Length    ${jsondata['items']}
    ${total} =      Convert To Integer   ${num_olts}
    Should Be Equal    ${length}    ${total}

Check PON Ports Created
    ${res} =   CORD Get    /xosapi/v1/volt/ponports
    ${jsondata} =    To Json    ${res.content}
    ${length} =    Get Length    ${jsondata['items']}
    ${total} =      Evaluate  ${num_olts} * ${num_pon_ports}
    Should Be Equal    ${length}    ${total}

Check ONUs Created
    ${res} =   CORD Get    /xosapi/v1/volt/onudevices
    ${jsondata} =    To Json    ${res.content}
    ${length} =    Get Length    ${jsondata['items']}
    ${total} =      Evaluate  ${num_olts} * ${num_pon_ports} * ${num_onus}
    Should Be Equal    ${length}    ${total}

Check UNI Ports Created
    ${res} =   CORD Get    /xosapi/v1/volt/uniports
    ${jsondata} =    To Json    ${res.content}
    ${length} =    Get Length    ${jsondata['items']}
    ${total} =      Evaluate  ${num_olts} * ${num_pon_ports} * ${num_onus}
    Should Be Equal    ${length}    ${total}

Check Whitelist Created
    ${res} =   CORD Get    /xosapi/v1/att-workflow-driver/attworkflowdriverwhitelistentries
    ${jsondata} =    To Json    ${res.content}
    ${length} =    Get Length    ${jsondata['items']}
    ${total} =      Evaluate  ${num_olts} * ${num_pon_ports} * ${num_onus}
    Should Be Equal    ${length}    ${total}

Activate ONUs
    [Documentation]    Send activation events for all the ONUs and waits for the model_policies of ATT Workflow Driver Service Instances to have completed
    ${events} =     Generate Onu Events
    : FOR   ${e}  IN  @{events}
    \   Send Kafka Event    onu.events    ${e}
    ${start} =   Get Time
    Wait Until Keyword Succeeds    ${timeout}    5s    Validate ATT_SI Number    ${events}
    Wait Until Keyword Succeeds    ${timeout}    5s    ModelPolicy completed
    ${end} =   Get Time
    Log To Console      Test started at: ${start}
    Log To Console      Test ended at: ${end}
    ${duration} =       Subtract Date From Date    ${end}   ${start}
    Log To Console      Test duration: ${duration}

Authenticate Subscribers
    [Documentation]    Send authentication events for all the ONUs and waits for the model_policies of ATT Workflow Driver Service Instances to have completed
    ${events} =     Generate Auth Events
    : FOR   ${e}  IN  @{events}
    \   Send Kafka Event    authentication.events    ${e}
    ${start} =   Get Time
    Wait Until Keyword Succeeds    ${timeout}    5s    AuthCompleted
    Wait Until Keyword Succeeds    ${timeout}    5s    ModelPolicy completed
    # TODO validate that:
    # - subscriber status has changed
    # - vOLT SI have been created and policed (we can't test sync'ed without a backend)
    # - fabric-xconnect have been created and policed (we can't test sync'ed without a backend)
    ${end} =   Get Time
    Log To Console      Test started at: ${start}
    Log To Console      Test ended at: ${end}
    ${duration} =       Subtract Date From Date    ${end}   ${start}
    Log To Console      Test duration: ${duration}

DHCP Subscribers
    [Documentation]    Send dhcp events for all the ONUs and waits for the model_policies of ATT Workflow Driver Service Instances to have completed
    ${events} =     Generate Dhcp Events
    : FOR   ${e}  IN  @{events}
    \   Send Kafka Event    dhcp.events    ${e}
    ${start} =   Get Time
    Wait Until Keyword Succeeds    ${timeout}    5s    DHCPCompleted
    Wait Until Keyword Succeeds    ${timeout}    5s    ModelPolicy completed
    # TODO validate that:
    # - subscriber has an IP address
    ${end} =   Get Time
    Log To Console      Test started at: ${start}
    Log To Console      Test ended at: ${end}
    ${duration} =       Subtract Date From Date    ${end}   ${start}
    Log To Console      Test duration: ${duration}


*** Keywords ***

Validate ATT_SI Number
    [Arguments]    ${events}
    ${res} =   CORD Get    /xosapi/v1/att-workflow-driver/attworkflowdriverserviceinstances
    ${jsondata} =    To Json    ${res.content}
    ${length} =    Get Length    ${jsondata['items']}
    ${total} =    Get Length    ${events}
    Log To Console      ${length} Service Instances created, expecting ${total}
    Should Be Equal    ${length}    ${total}

DHCPCompleted
    [Documentation]     Check that all ATT_SI have an ip address
    ${res} =   CORD Get    /xosapi/v1/att-workflow-driver/attworkflowdriverserviceinstances
    ${jsondata} =    To Json    ${res.content}
    Log To Console      Checking DHCP
    : FOR   ${i}  IN  @{jsondata['items']}
    \   Should Not Be Empty     ${i['ip_address']}

AuthCompleted
    [Documentation]     Check that all ATT_SI have status=authenticated
    ${res} =   CORD Get    /xosapi/v1/att-workflow-driver/attworkflowdriverserviceinstances
    ${jsondata} =    To Json    ${res.content}
    Log To Console      Checking Authentication
    : FOR   ${i}  IN  @{jsondata['items']}
    \   Should Be Equal     ${i['authentication_state']}     APPROVED

ModelPolicy completed
    # TODO make this method configurable to check model_policies on arbitrary models
    [Documentation]    Check that model_policies had run for all the items in the list
    ${res} =   CORD Get    /xosapi/v1/att-workflow-driver/attworkflowdriverserviceinstances
    ${jsondata} =    To Json    ${res.content}
    Log To Console      Checking ModelPolicy
    : FOR   ${i}  IN  @{jsondata['items']}
    \   Should Be True      ${i['policed']} >= ${i['updated']}

Setup
    # TODO remove all JSON files that a previous run may have left around
    ${cord_kafka}=    Get Environment Variable    CORD_KAFKA_IP    cord-kafka
    ${target} =     Evaluate    ${num_olts} * ${num_pon_ports} * ${num_onus}
    Log     Testing with ${target} ONUs
    Log To Console      Testing with ${target} ONUs
    Connect Producer    ${cord_kafka}:9092    onu.events
    Connect Producer    ${cord_kafka}:9092    authentication.events
    Connect Producer    ${cord_kafka}:9092    dhcp.events
    ${auth} =    Create List    admin@opencord.org    letmein
    ${HEADERS}    Create Dictionary    Content-Type=application/json    allow_modify_feedback=True
    Create Session    XOS    http://${xos_chameleon_url}:${xos_chameleon_port}    auth=${AUTH}    headers=${HEADERS}
    Store Data
    Mock Data
    ${mock} =   Get Mock Data
    Log     ${mock}

Teardown
    [Documentation]    Delete all models created
    Log     Teardown
    Log To Console      Teardown
    Delete OLTs
    Delete Whitelist
    Delete ServiceInstances
    Delete All Sessions
    Clean Storage

Mock Data
    [Documentation]     Mock all the data needed from the test
    Create Mock Olts    ${num_olts}     ${voltservice_id}
    Create Olts
    Create Mock Pon Ports   ${num_pon_ports}
    Create Pon Ports
    Create Mock Onus        ${num_onus}
    Create Onus
    Create Mock Unis
    Create Unis
    Create Whitelist

Create Olts
    [Documentation]     Stub OLT for the test
    ${olts} =   Get Rest Olts
    : FOR   ${OLT}  IN  @{olts}
    \   Log     ${OLT}
    \   Log To Console      Creating OLT ${OLT['name']}
    \   ${res} =    CORD Post   /xosapi/v1/volt/oltdevices    ${OLT}
    \   ${jsondata} =    To Json    ${res.content}
    \   Update Olt Id       ${OLT}  ${jsondata['id']}

Create Pon Ports
    ${pon_ports} =   Get Rest Pon Ports
    : FOR   ${port}  IN  @{pon_ports}
    \   Log     ${port}
    \   Log To Console      Creating PON Port ${port['name']}
    \   ${res} =    CORD Post   /xosapi/v1/volt/ponports    ${port}
    \   ${jsondata} =    To Json    ${res.content}
    \   Update Pon Port Id       ${port}  ${jsondata['id']}

Create Onus
    ${onus} =   Get Rest Onus
    : FOR   ${onu}  IN  @{onus}
    \   Log     ${onu}
    \   Log To Console      Creating ONU ${onu['serial_number']}
    \   ${res} =    CORD Post   /xosapi/v1/volt/onudevices    ${onu}
    \   ${jsondata} =    To Json    ${res.content}
    \   Update Onu Id       ${onu}  ${jsondata['id']}

Create Unis
    ${unis} =   Get Rest Unis
    : FOR   ${uni}  IN  @{unis}
    \   Log     ${uni}
    \   Log To Console      Creating UNI ${uni['name']}
    \   ${res} =    CORD Post   /xosapi/v1/volt/uniports    ${uni}
    \   ${jsondata} =    To Json    ${res.content}
    \   Update Uni Id       ${uni}  ${jsondata['id']}

Create Whitelist
    [Documentation]     Create a whitelist for the tests
    ${whitelist} =      Create Mock Whitelist   ${attworkflowservice_id}
    : FOR   ${e}  IN  @{whitelist}
    \   Log     ${e}
    \   Log To Console      Creating Whitelist Entry ${e['serial_number']}
    \   ${res} =    CORD Post   /xosapi/v1/att-workflow-driver/attworkflowdriverwhitelistentries    ${e}

Delete Olts
    [Documentation]     Remove all the OLTs created for the test
    ${res} =    CORD Get    /xosapi/v1/volt/oltdevices
    ${jsondata} =    To Json    ${res.content}
    :FOR    ${ELEMENT}    IN  @{jsondata['items']}
    \   ${id}=    Get From Dictionary    ${ELEMENT}    id
    \   CORD Delete     /xosapi/v1/volt/oltdevices    ${id}

Delete Whitelist
    [Documentation]     Clean the whitelist
    ${res} =    CORD Get    /xosapi/v1/att-workflow-driver/attworkflowdriverwhitelistentries
    ${jsondata} =    To Json    ${res.content}
    :FOR    ${ELEMENT}    IN  @{jsondata['items']}
    \   ${id}=    Get From Dictionary    ${ELEMENT}    id
    \   CORD Delete     /xosapi/v1/att-workflow-driver/attworkflowdriverwhitelistentries    ${id}

Delete ServiceInstances
    [Documentation]     Clean the whitelist
    ${res} =    CORD Get    /xosapi/v1/att-workflow-driver/attworkflowdriverserviceinstances
    ${jsondata} =    To Json    ${res.content}
    :FOR    ${ELEMENT}    IN  @{jsondata['items']}
    \   ${id}=    Get From Dictionary    ${ELEMENT}    id
    \   CORD Delete     /xosapi/v1/att-workflow-driver/attworkflowdriverserviceinstances    ${id}

Store Data
    [Documentation]     Store all the ids needed for the test to work
    # Get AttWorkflowDriverService id
    ${resp}=    CORD Get    /xosapi/v1/att-workflow-driver/attworkflowdriverservices
    ${jsondata}=    To Json    ${resp.content}
    ${attworkflowservice}=    Get From List    ${jsondata['items']}    0
    ${attworkflowservice_id}=    Get From Dictionary    ${attworkflowservice}    id
    Set Suite Variable    ${attworkflowservice_id}

    # Get VoltService id
    ${resp}=    CORD Get    /xosapi/v1/volt/voltservices
    ${jsondata}=    To Json    ${resp.content}
    ${voltservice}=    Get From List    ${jsondata['items']}    0
    ${voltservice_id}=    Get From Dictionary    ${voltservice}    id
    Set Suite Variable    ${voltservice_id}

Send Kafka Event
    [Documentation]    Send event
    [Arguments]    ${topic}    ${message}
    Log    Sending event
    ${event}=    evaluate    json.dumps(${message})    json
    Send    ${topic}    ${event}
    Flush

CORD Get
    [Documentation]    Make a GET call to XOS
    [Arguments]    ${service}
    ${resp}=    Get Request    XOS    ${service}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    [Return]    ${resp}

CORD Post
    [Documentation]    Make a POST call to XOS
    [Arguments]    ${service}    ${data}
    ${data}=    Evaluate    json.dumps(${data})    json
    ${resp}=    Post Request    XOS    uri=${service}    data=${data}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    [Return]    ${resp}

CORD Delete
    [Documentation]    Make a DELETE call to the CORD controller
    [Arguments]    ${service}    ${data_id}
    ${resp}=    Delete Request    XOS    uri=${service}/${data_id}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    [Return]    ${resp}
