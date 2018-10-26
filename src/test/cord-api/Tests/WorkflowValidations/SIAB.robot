# Copyright 2017-present Open Networking Foundation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

*** Settings ***
Documentation     Test various E2E conditions for seba-in-a-box
Suite Setup       Setup
Suite Teardown    Teardown
Test Setup        Setup Test
Test Teardown     Test Cleanup
Library           Collections
Library           String
Library           OperatingSystem
Library           XML
Library           RequestsLibrary
Library           ../../Framework/utils/utils.py
Resource          ../../Framework/utils/utils.robot
Library           ../../Framework/restApi.py
Resource          ../../Framework/Subscriber.robot
Resource          ../../Framework/ATTWorkFlowDriver.robot
Resource          ../../Framework/Kubernetes.robot
Resource          ../../Framework/ONU.robot
Resource          ../../Framework/DHCP.robot
Variables         ../../Properties/RestApiProperties.py

*** Variables ***
${WHITELIST_PATHFILE}      ${CURDIR}/data/SIABWhitelist.json
${SUBSCRIBER_PATHFILE}     ${CURDIR}/data/SIABSubscriber.json
${VOLT_DEVICE_PATHFILE}    ${CURDIR}/data/SIABOLTDevice.json
${export_kube_config}      export KUBECONFIG=/home/%{USER}/.kube/config
${kube_node_ip}            localhost
${dst_host_ip}             172.18.0.10
${local_user}              %{USER}
${local_pass}              %{USER}

*** Test Cases ***
ONU in Correct Location
    [Documentation]    Validates E2E Ping Connectivity and object states for the given scenario:
    ...    Configure whitelist with correct ONU location
    ...    Validate successful authentication/DHCP/E2E ping
    [Setup]    None
    [Tags]    stable    latest
    Wait Until Keyword Succeeds    60s    15s    Validate ONU States    ACTIVE    ENABLED    ${onu_device}
    Wait Until Keyword Succeeds    60s    2s    Validate ATT Workflow Driver SI    ENABLED    AWAITING    ${onu_device}
    Wait Until Keyword Succeeds    60s    2s    Validate Subscriber Status    awaiting-auth    ${onu_device}
    Validate Authentication    True    eth0    wpa_supplicant.conf    ${kube_node_ip}     ${local_user}    ${local_pass}    K8S    ${RG_CONTAINER}
    Wait Until Keyword Succeeds    60s    2s    Validate ATT Workflow Driver SI    ENABLED    APPROVED    ${onu_device}
    Wait Until Keyword Succeeds    60s    2s    Validate Subscriber Status    enabled    ${onu_device}
    Wait Until Keyword Succeeds    60s    2s    Validate Subscriber Service Chain    ${onu_device}    True
    Wait Until Keyword Succeeds    60s    2s    Validate Fabric CrossConnect SI    ${s_tag}    True
    Validate DHCP and Ping    True    True    eth0    ${s_tag}    ${c_tag}    ${dst_host_ip}    ${kube_node_ip}    ${local_user}    ${local_pass}    K8S    ${RG_CONTAINER}
    ${subscriber_id}=    Retrieve Subscriber    ${c_tag}
    CORD Put    ${VOLT_SUBSCRIBER}    {"status":"disabled"}    ${subscriber_id}
    Validate DHCP and Ping    True    False    eth0    ${s_tag}    ${c_tag}    ${dst_host_ip}    ${kube_node_ip}    ${local_user}    ${local_pass}    K8S    ${RG_CONTAINER}
    Restart RG Pod
    CORD Put    ${VOLT_SUBSCRIBER}    {"status":"enabled"}    ${subscriber_id}
    Validate Authentication    True    eth0    wpa_supplicant.conf    ${kube_node_ip}     ${local_user}    ${local_pass}    K8S    ${RG_CONTAINER}
    Validate DHCP and Ping    True    True    eth0    ${s_tag}    ${c_tag}    ${dst_host_ip}    ${kube_node_ip}    ${local_user}    ${local_pass}    K8S    ${RG_CONTAINER}

ONU in Correct Location -> Remove ONU from Whitelist -> Add ONU to Whitelist
    [Documentation]    Validates E2E Ping Connectivity and object states for the given scenario:
    ...    Configure whitelist with correct ONU location
    ...    Validate successful authentication/DHCP/E2E ping
    ...    Remove ONU from whitelist
    ...    Validate failed authentication/DHCP/E2E ping
    ...    Add ONU to whitelist
    ...    Validate successful authentication/DHCP/E2E ping
    [Tags]    latest
    Wait Until Keyword Succeeds    60s    15s    Validate ONU States    ACTIVE    ENABLED    ${onu_device}
    Wait Until Keyword Succeeds    60s    2s    Validate ATT Workflow Driver SI    ENABLED    AWAITING    ${onu_device}
    Wait Until Keyword Succeeds    60s    2s    Validate Subscriber Status    awaiting-auth    ${onu_device}
    Validate Authentication    True    eth0    wpa_supplicant.conf    ${kube_node_ip}     ${local_user}    ${local_pass}    K8S    ${RG_CONTAINER}
    Wait Until Keyword Succeeds    60s    2s    Validate ATT Workflow Driver SI    ENABLED    APPROVED    ${onu_device}
    Wait Until Keyword Succeeds    60s    2s    Validate Subscriber Status    enabled    ${onu_device}
    Wait Until Keyword Succeeds    60s    2s    Validate Subscriber Service Chain    ${onu_device}    True
    Wait Until Keyword Succeeds    60s    2s    Validate Fabric CrossConnect SI    ${s_tag}    True
    Validate DHCP and Ping    True    True    eth0    ${s_tag}    ${c_tag}    ${dst_host_ip}    ${kube_node_ip}    ${local_user}    ${local_pass}    K8S    ${RG_CONTAINER}
    Restart RG Pod
    Remove Whitelist
    Wait Until Keyword Succeeds    60s    2s    Validate ATT Workflow Driver SI    DISABLED    AWAITING    ${onu_device}
    Wait Until Keyword Succeeds    60s    2s    Validate Subscriber Status    awaiting-auth    ${onu_device}
    Validate Authentication    False    eth0    wpa_supplicant.conf    ${kube_node_ip}     ${local_user}    ${local_pass}    K8S    ${RG_CONTAINER}
    Wait Until Keyword Succeeds    60s    2s    Validate Subscriber Service Chain    ${onu_device}    False
    Wait Until Keyword Succeeds    60s    2s    Validate Fabric CrossConnect SI    ${s_tag}    False
    Validate DHCP and Ping    True    False    eth0    ${s_tag}    ${c_tag}    ${dst_host_ip}    ${kube_node_ip}    ${local_user}    ${local_pass}    K8S    ${RG_CONTAINER}
    Restart RG Pod
    Create Whitelist
    Wait Until Keyword Succeeds    60s    2s    Validate ATT Workflow Driver SI    ENABLED    AWAITING    ${onu_device}
    Wait Until Keyword Succeeds    60s    2s    Validate Subscriber Status    awaiting-auth    ${onu_device}
    Validate Authentication    True    eth0    wpa_supplicant.conf    ${kube_node_ip}     ${local_user}    ${local_pass}    K8S    ${RG_CONTAINER}
    Wait Until Keyword Succeeds    60s    2s    Validate ATT Workflow Driver SI    ENABLED    APPROVED    ${onu_device}
    Wait Until Keyword Succeeds    60s    2s    Validate Subscriber Status    enabled    ${onu_device}
    Wait Until Keyword Succeeds    60s    2s    Validate Subscriber Service Chain    ${onu_device}    True
    Wait Until Keyword Succeeds    60s    2s    Validate Fabric CrossConnect SI    ${s_tag}    True
    Validate DHCP and Ping    True    True    eth0    ${s_tag}    ${c_tag}    ${dst_host_ip}    ${kube_node_ip}    ${local_user}    ${local_pass}    K8S    ${RG_CONTAINER}

ONU in Correct Location -> ONU in Wrong Location -> ONU in Correct Location
    [Documentation]    Validates E2E Ping Connectivity and object states for the given scenario:
    ...    Configure whitelist with correct ONU location
    ...    Validate successful authentication/DHCP/E2E ping
    ...    Update whitelist with wrong ONU location
    ...    Validate failed authentication/DHCP/E2E ping
    ...    Update whitelist with correct ONU location
    ...    Validate successful authentication/DHCP/E2E ping
    [Tags]    latest
    Wait Until Keyword Succeeds    60s    15s    Validate ONU States    ACTIVE    ENABLED    ${onu_device}
    Wait Until Keyword Succeeds    60s    2s    Validate ATT Workflow Driver SI    ENABLED    AWAITING    ${onu_device}
    Wait Until Keyword Succeeds    60s    2s    Validate Subscriber Status    awaiting-auth    ${onu_device}
    Validate Authentication    True    eth0    wpa_supplicant.conf    ${kube_node_ip}     ${local_user}    ${local_pass}    K8S    ${RG_CONTAINER}
    Wait Until Keyword Succeeds    60s    2s    Validate ATT Workflow Driver SI    ENABLED    APPROVED    ${onu_device}
    Wait Until Keyword Succeeds    60s    2s    Validate Subscriber Status    enabled    ${onu_device}
    Wait Until Keyword Succeeds    60s    2s    Validate Subscriber Service Chain    ${onu_device}    True
    Wait Until Keyword Succeeds    60s    2s    Validate Fabric CrossConnect SI    ${s_tag}    True
    Validate DHCP and Ping    True    True    eth0    ${s_tag}    ${c_tag}    ${dst_host_ip}    ${kube_node_ip}    ${local_user}    ${local_pass}    K8S    ${RG_CONTAINER}
    Restart RG Pod
    Update Whitelist with Wrong Location
    Wait Until Keyword Succeeds    60s    2s    Validate ATT Workflow Driver SI    DISABLED    AWAITING    ${onu_device}
    Wait Until Keyword Succeeds    60s    2s    Validate Subscriber Status    awaiting-auth    ${onu_device}
    Wait Until Keyword Succeeds    60s    2s    Validate Subscriber Service Chain    ${onu_device}    False
    Wait Until Keyword Succeeds    60s    2s    Validate Fabric CrossConnect SI    ${s_tag}    False
    Validate Authentication    False    eth0    wpa_supplicant.conf    ${kube_node_ip}     ${local_user}    ${local_pass}    K8S    ${RG_CONTAINER}
    Validate DHCP and Ping    False    False    eth0    ${s_tag}    ${c_tag}    ${dst_host_ip}    ${kube_node_ip}    ${local_user}    ${local_pass}    K8S    ${RG_CONTAINER}
    Restart RG Pod
    Update Whitelist with Correct Location
    Wait Until Keyword Succeeds    60s    2s    Validate ATT Workflow Driver SI    ENABLED    AWAITING    ${onu_device}
    Wait Until Keyword Succeeds    60s    2s    Validate Subscriber Status    awaiting-auth    ${onu_device}
    Validate Authentication    True    eth0    wpa_supplicant.conf    ${kube_node_ip}     ${local_user}    ${local_pass}    K8S    ${RG_CONTAINER}
    Wait Until Keyword Succeeds    60s    2s    Validate ATT Workflow Driver SI    ENABLED    APPROVED    ${onu_device}
    Wait Until Keyword Succeeds    60s    2s    Validate Subscriber Status    enabled    ${onu_device}
    Wait Until Keyword Succeeds    60s    2s    Validate Subscriber Service Chain    ${onu_device}    True
    Wait Until Keyword Succeeds    60s    2s    Validate Fabric CrossConnect SI    ${s_tag}    True
    Validate DHCP and Ping    True    True    eth0    ${s_tag}    ${c_tag}    ${dst_host_ip}    ${kube_node_ip}    ${local_user}    ${local_pass}    K8S    ${RG_CONTAINER}

ONU in Correct Location -> Remove Subscriber -> Create Subscriber
    [Documentation]    Validates E2E Ping Connectivity and object states for the given scenario:
    ...    Configure whitelist with correct ONU location
    ...    Validate successful authentication/DHCP/E2E ping
    ...    Remove subscriber model
    ...    Validate failed authentication/DHCP/E2E ping
    ...    Recreate subscriber model
    ...    Validate successful authentication/DHCP/E2E ping
    [Tags]    latest
    Wait Until Keyword Succeeds    60s    15s    Validate ONU States    ACTIVE    ENABLED    ${onu_device}
    Wait Until Keyword Succeeds    60s    2s    Validate ATT Workflow Driver SI    ENABLED    AWAITING    ${onu_device}
    Wait Until Keyword Succeeds    60s    2s    Validate Subscriber Status    awaiting-auth    ${onu_device}
    Validate Authentication    True    eth0    wpa_supplicant.conf    ${kube_node_ip}     ${local_user}    ${local_pass}    K8S    ${RG_CONTAINER}
    Wait Until Keyword Succeeds    60s    2s    Validate ATT Workflow Driver SI    ENABLED    APPROVED    ${onu_device}
    Wait Until Keyword Succeeds    60s    2s    Validate Subscriber Status    enabled    ${onu_device}
    Wait Until Keyword Succeeds    60s    2s    Validate Subscriber Service Chain    ${onu_device}    True
    Wait Until Keyword Succeeds    60s    2s    Validate Fabric CrossConnect SI    ${s_tag}    True
    Validate DHCP and Ping    True    True    eth0    ${s_tag}    ${c_tag}    ${dst_host_ip}    ${kube_node_ip}    ${local_user}    ${local_pass}    K8S    ${RG_CONTAINER}
    Restart RG Pod
    Remove Subscriber
    Validate Authentication    False    eth0    wpa_supplicant.conf    ${kube_node_ip}     ${local_user}    ${local_pass}    K8S    ${RG_CONTAINER}
    Validate DHCP and Ping    False    False    eth0    ${s_tag}    ${c_tag}    ${dst_host_ip}    ${kube_node_ip}    ${local_user}    ${local_pass}    K8S    ${RG_CONTAINER}
    Restart RG Pod
    Create Subscriber
    Wait Until Keyword Succeeds    60s    2s    Validate Subscriber Status    pre-provisioned    ${onu_device}
    Validate Authentication    True    eth0    wpa_supplicant.conf    ${kube_node_ip}     ${local_user}    ${local_pass}    K8S    ${RG_CONTAINER}
    Wait Until Keyword Succeeds    60s    2s    Validate ATT Workflow Driver SI    ENABLED    APPROVED    ${onu_device}
    Wait Until Keyword Succeeds    60s    2s    Validate Subscriber Status    enabled    ${onu_device}
    Wait Until Keyword Succeeds    60s    2s    Validate Subscriber Service Chain    ${onu_device}    True
    Wait Until Keyword Succeeds    60s    2s    Validate Fabric CrossConnect SI    ${s_tag}    True
    Validate DHCP and Ping    True    True    eth0    ${s_tag}    ${c_tag}    ${dst_host_ip}    ${kube_node_ip}    ${local_user}    ${local_pass}    K8S    ${RG_CONTAINER}

ONU in Correct Location (Skip Subscriber Provisioning) -> Provision Subscriber
    [Documentation]    Validates E2E Ping Connectivity and object states for the given scenario:
    ...    Configure whitelist with correct ONU location and skip provisioning subscriber
    ...    Validate successful authentication (expected with the ONF pod setup) but failed DHCP/E2E ping
    ...    Provision subscriber
    ...    Validate successful authentication/DHCP/E2E ping
    [Tags]    latest
    Remove Subscriber
    Wait Until Keyword Succeeds    60s    15s    Validate ONU States    ACTIVE    ENABLED    ${onu_device}
    Wait Until Keyword Succeeds    60s    2s    Validate ATT Workflow Driver SI    ENABLED    AWAITING    ${onu_device}
    Validate Authentication    True    eth0    wpa_supplicant.conf    ${kube_node_ip}     ${local_user}    ${local_pass}    K8S    ${RG_CONTAINER}
    Wait Until Keyword Succeeds    60s    2s    Validate ATT Workflow Driver SI    ENABLED    APPROVED    ${onu_device}
    Validate DHCP and Ping    False    False    eth0    ${s_tag}    ${c_tag}    ${dst_host_ip}    ${kube_node_ip}    ${local_user}    ${local_pass}    K8S    ${RG_CONTAINER}
    Restart RG Pod
    Create Subscriber
    Wait Until Keyword Succeeds    60s    2s    Validate Subscriber Status    pre-provisioned    ${onu_device}
    Validate Authentication    True    eth0    wpa_supplicant.conf    ${kube_node_ip}     ${local_user}    ${local_pass}    K8S    ${RG_CONTAINER}
    Wait Until Keyword Succeeds    60s    2s    Validate ATT Workflow Driver SI    ENABLED    APPROVED    ${onu_device}
    Wait Until Keyword Succeeds    60s    2s    Validate Subscriber Status    enabled    ${onu_device}
    Wait Until Keyword Succeeds    60s    2s    Validate Subscriber Service Chain    ${onu_device}    True
    Wait Until Keyword Succeeds    60s    2s    Validate Fabric CrossConnect SI    ${s_tag}    True
    Validate DHCP and Ping    True    True    eth0    ${s_tag}    ${c_tag}    ${dst_host_ip}    ${kube_node_ip}    ${local_user}    ${local_pass}    K8S    ${RG_CONTAINER}

ONU in Correct Location (Skip Authentication)
    [Documentation]    Validates E2E Ping Connectivity and object states for the given scenario:
    ...    Configure whitelist with correct ONU location and skip RG authentication
    ...    Validate failed authentication/DHCP/E2E ping
    [Tags]    stable    latest
    Wait Until Keyword Succeeds    60s    15s    Validate ONU States    ACTIVE    ENABLED    ${onu_device}
    Wait Until Keyword Succeeds    60s    2s    Validate ATT Workflow Driver SI    ENABLED    AWAITING    ${onu_device}
    Wait Until Keyword Succeeds    60s    2s    Validate Subscriber Status    awaiting-auth    ${onu_device}
    Wait Until Keyword Succeeds    60s    2s    Validate Subscriber Service Chain    ${onu_device}    False
    Wait Until Keyword Succeeds    60s    2s    Validate Fabric CrossConnect SI    ${s_tag}    False
    Validate DHCP and Ping    False    False    eth0    ${s_tag}    ${c_tag}    ${dst_host_ip}    ${kube_node_ip}    ${local_user}    ${local_pass}    K8S    ${RG_CONTAINER}

ONU not in Whitelist
    [Documentation]    Validates E2E Ping Connectivity and object states for the given scenario:
    ...    Skip whitelist configuration for ONU
    ...    Validate failed authentication/DHCP/E2E ping
    [Tags]    stable    latest
    [Setup]    Simple Setup
    Wait Until Keyword Succeeds    60s    2s    Create Subscriber
    Wait Until Keyword Succeeds    60s    2s    Create VOLT
    Wait Until Keyword Succeeds    60s    15s    Validate ONU States    UNKNOWN    DISABLED    ${onu_device}
    Wait Until Keyword Succeeds    60s    2s    Validate ATT Workflow Driver SI    DISABLED    AWAITING    ${onu_device}
    Wait Until Keyword Succeeds    60s    2s    Validate Subscriber Status    awaiting-auth    ${onu_device}
    Validate Authentication    False    eth0    wpa_supplicant.conf    ${kube_node_ip}     ${local_user}    ${local_pass}    K8S    ${RG_CONTAINER}
    Wait Until Keyword Succeeds    60s    2s    Validate ATT Workflow Driver SI    DISABLED    AWAITING    ${onu_device}
    Wait Until Keyword Succeeds    60s    2s    Validate Subscriber Status    awaiting-auth    ${onu_device}
    Wait Until Keyword Succeeds    60s    2s    Validate Subscriber Service Chain    ${onu_device}    False
    Wait Until Keyword Succeeds    60s    2s    Validate Fabric CrossConnect SI    ${s_tag}    False
    Validate DHCP and Ping    False    False    eth0    ${s_tag}    ${c_tag}    ${dst_host_ip}    ${kube_node_ip}    ${local_user}    ${local_pass}    K8S    ${RG_CONTAINER}

ONU not in Whitelist (Skip Subscriber Provisioning) -> Add ONU to Whitelist -> Provision Subscriber
    [Documentation]    Validates E2E Ping Connectivity and object states for the given scenario:
    ...    Skip whitelist configuration for ONU and subscriber provisioning
    ...    Validate successful authentication but failed DHCP/E2E ping
    ...    Configure whitelist with correct ONU location
    ...    Validate successful authentication (expected with the ONF pod setup) but failed DHCP/E2E ping
    ...    Provision subscriber
    ...    Validate successful authentication/DHCP/E2E ping
    [Tags]    latest
    [Setup]    Simple Setup
    Wait Until Keyword Succeeds    60s    2s    Create VOLT
    Wait Until Keyword Succeeds    60s    15s    Validate ONU States    UNKNOWN    DISABLED    ${onu_device}
    Wait Until Keyword Succeeds    60s    2s    Validate ATT Workflow Driver SI    DISABLED    AWAITING    ${onu_device}
    Validate Authentication    False    eth0    wpa_supplicant.conf    ${kube_node_ip}     ${local_user}    ${local_pass}    K8S    ${RG_CONTAINER}
    Validate DHCP and Ping    False    False    eth0    ${s_tag}    ${c_tag}    ${dst_host_ip}    ${kube_node_ip}    ${local_user}    ${local_pass}    K8S    ${RG_CONTAINER}
    Restart RG Pod
    Create Whitelist
    Wait Until Keyword Succeeds    60s    15s    Validate ONU States    ACTIVE    ENABLED    ${onu_device}
    Wait Until Keyword Succeeds    60s    2s    Validate ATT Workflow Driver SI    ENABLED    AWAITING    ${onu_device}
    Validate Authentication    True    eth0    wpa_supplicant.conf    ${kube_node_ip}     ${local_user}    ${local_pass}    K8S    ${RG_CONTAINER}
    Wait Until Keyword Succeeds    60s    2s    Validate ATT Workflow Driver SI    ENABLED    APPROVED    ${onu_device}
    Validate DHCP and Ping    False    False    eth0    ${s_tag}    ${c_tag}    ${dst_host_ip}    ${kube_node_ip}    ${local_user}    ${local_pass}    K8S    ${RG_CONTAINER}
    Restart RG Pod
    Create Subscriber
    Wait Until Keyword Succeeds    60s    2s    Validate Subscriber Status    pre-provisioned    ${onu_device}
    Validate Authentication    True    eth0    wpa_supplicant.conf    ${kube_node_ip}     ${local_user}    ${local_pass}    K8S    ${RG_CONTAINER}
    Wait Until Keyword Succeeds    60s    2s    Validate ATT Workflow Driver SI    ENABLED    APPROVED    ${onu_device}
    Wait Until Keyword Succeeds    60s    2s    Validate Subscriber Status    enabled    ${onu_device}
    Wait Until Keyword Succeeds    60s    2s    Validate Subscriber Service Chain    ${onu_device}    True
    Wait Until Keyword Succeeds    60s    2s    Validate Fabric CrossConnect SI    ${s_tag}    True
    Validate DHCP and Ping    True    True    eth0    ${s_tag}    ${c_tag}    ${dst_host_ip}    ${kube_node_ip}    ${local_user}    ${local_pass}    K8S    ${RG_CONTAINER}

ONU in Wrong Location
    [Documentation]    Validates E2E Ping Connectivity and object states for the given scenario:
    ...    Configure whitelist with wrong ONU location
    ...    Validate failed authentication/DHCP/E2E ping
    [Tags]    latest
    Update Whitelist with Wrong Location
    Wait Until Keyword Succeeds    60s    15s    Validate ONU States    UNKNOWN    DISABLED    ${onu_device}
    Wait Until Keyword Succeeds    60s    2s    Validate ATT Workflow Driver SI    DISABLED    AWAITING    ${onu_device}
    Wait Until Keyword Succeeds    60s    2s    Validate Subscriber Status    awaiting-auth    ${onu_device}
    Validate Authentication    False    eth0    wpa_supplicant.conf    ${kube_node_ip}     ${local_user}    ${local_pass}    K8S    ${RG_CONTAINER}
    Wait Until Keyword Succeeds    60s    2s    Validate ATT Workflow Driver SI    DISABLED    AWAITING    ${onu_device}
    Wait Until Keyword Succeeds    60s    2s    Validate Subscriber Status    awaiting-auth    ${onu_device}
    Wait Until Keyword Succeeds    60s    2s    Validate Subscriber Service Chain    ${onu_device}    False
    Wait Until Keyword Succeeds    60s    2s    Validate Fabric CrossConnect SI    ${s_tag}    False
    Validate DHCP and Ping    False    False    eth0    ${s_tag}    ${c_tag}    ${dst_host_ip}    ${kube_node_ip}    ${local_user}    ${local_pass}    K8S    ${RG_CONTAINER}

ONU in Wrong Location (Skip Subscriber Provisioning) -> ONU in Correct Location -> Provision Subscriber
    [Documentation]    Validates E2E Ping Connectivity and object states for the given scenario:
    ...    Configure whitelist with wrong ONU location and skip subscriber provisioning
    ...    Validate failed authentication/DHCP/E2E ping
    ...    Configure whitelist with correct ONU location
    ...    Validate successful authentication (expected with the ONF pod setup) but failed DHCP/E2E ping
    ...    Provision subscriber
    ...    Validate successful authentication/DHCP/E2E ping
    [Tags]    latest
    [Setup]    Simple Setup
    Wait Until Keyword Succeeds    60s    2s    Create VOLT
    Wait Until Keyword Succeeds    60s    2s    Create Whitelist
    Update Whitelist with Wrong Location
    Wait Until Keyword Succeeds    60s    15s    Validate ONU States    UNKNOWN    DISABLED    ${onu_device}
    Wait Until Keyword Succeeds    60s    2s    Validate ATT Workflow Driver SI    DISABLED    AWAITING    ${onu_device}
    Validate Authentication    False    eth0    wpa_supplicant.conf    ${kube_node_ip}     ${local_user}    ${local_pass}    K8S    ${RG_CONTAINER}
    Wait Until Keyword Succeeds    60s    2s    Validate ATT Workflow Driver SI    DISABLED    AWAITING    ${onu_device}
    Validate DHCP and Ping    False    False    eth0    ${s_tag}    ${c_tag}    ${dst_host_ip}    ${kube_node_ip}    ${local_user}    ${local_pass}    K8S    ${RG_CONTAINER}
    Restart RG Pod
    Update Whitelist with Correct Location
    Wait Until Keyword Succeeds    60s    15s    Validate ONU States    ACTIVE    ENABLED    ${onu_device}
    Wait Until Keyword Succeeds    60s    2s    Validate ATT Workflow Driver SI    ENABLED    AWAITING    ${onu_device}
    Validate Authentication    True    eth0    wpa_supplicant.conf    ${kube_node_ip}     ${local_user}    ${local_pass}    K8S    ${RG_CONTAINER}
    Wait Until Keyword Succeeds    60s    2s    Validate ATT Workflow Driver SI    ENABLED    AWAITING    ${onu_device}
    Validate DHCP and Ping    False    False    eth0    ${s_tag}    ${c_tag}    ${dst_host_ip}    ${kube_node_ip}    ${local_user}    ${local_pass}    K8S    ${RG_CONTAINER}
    Restart RG Pod
    Create Subscriber
    Wait Until Keyword Succeeds    60s    2s    Validate Subscriber Status    awaiting-auth    ${onu_device}
    Validate Authentication    True    eth0    wpa_supplicant.conf    ${kube_node_ip}     ${local_user}    ${local_pass}    K8S    ${RG_CONTAINER}
    Wait Until Keyword Succeeds    60s    2s    Validate ATT Workflow Driver SI    ENABLED    APPROVED    ${onu_device}
    Wait Until Keyword Succeeds    60s    2s    Validate Subscriber Status    enabled    ${onu_device}
    Wait Until Keyword Succeeds    60s    2s    Validate Subscriber Service Chain    ${onu_device}    True
    Wait Until Keyword Succeeds    60s    2s    Validate Fabric CrossConnect SI    ${s_tag}    True
    Validate DHCP and Ping    True    True    eth0    ${s_tag}    ${c_tag}    ${dst_host_ip}    ${kube_node_ip}    ${local_user}    ${local_pass}    K8S    ${RG_CONTAINER}

*** Keywords ***
Setup
    ${auth} =    Create List    ${XOS_USER}    ${XOS_PASSWD}
    ${HEADERS}    Create Dictionary    Content-Type=application/json
    Create Session    ${server_ip}    http://${server_ip}:${server_port}    auth=${AUTH}    headers=${HEADERS}
    ${att_workflow_service_id}=    Get Service Owner Id    ${ATT_SERVICE}
    ${volt_service_id}=    Get Service Owner Id    ${VOLT_SERVICE}
    ${AttWhiteListList}=    utils.jsonToList    ${WHITELIST_PATHFILE}   AttWhiteListInfo
    Set Suite Variable    ${AttWhiteListList}
    ${AttWhiteListDict}=    utils.listToDict    ${AttWhiteListList}    0
    ${AttWhiteListDict}=    utils.setFieldValueInDict    ${AttWhiteListDict}    owner_id    ${att_workflow_service_id}
    ${onu_device}=   Get From Dictionary    ${AttWhiteListDict}    serial_number
    Log    ${onu_device}
    Set Global Variable    ${onu_device}
    ${onu_location}=   Get From Dictionary    ${AttWhiteListDict}    pon_port_id
    Set Global Variable    ${onu_location}
    ${SubscriberList}=    utils.jsonToList    ${SUBSCRIBER_PATHFILE}   SubscriberInfo
    Set Global Variable    ${SubscriberList}
    ${SubscriberDict}=    utils.listToDict    ${SubscriberList}    0
    ${s_tag}=    utils.getFieldValueFromDict    ${SubscriberDict}   s_tag
    ${c_tag}=    utils.getFieldValueFromDict    ${SubscriberDict}   c_tag
    ${VoltDeviceList}=    utils.jsonToList    ${VOLT_DEVICE_PATHFILE}   VOLTDeviceInfo
    Set Global Variable    ${VoltDeviceList}
    Set Suite Variable    ${s_tag}
    Set Suite Variable    ${c_tag}
    ${whitelist_id}=    Retrieve Whitelist Entry    ${onu_device}
    Set Suite Variable    ${whitelist_id}
    ${att_si_id}=    Retrieve ATT Service Instance ID    ${onu_device}
    Set Suite Variable    ${att_si_id}
    ${RG_CONTAINER}=    Run    kubectl -n voltha get pod|grep "^rg-"|cut -d' ' -f1
    Set Suite Variable    ${RG_CONTAINER}
    ## Validate ATT Workflow SI
    Wait Until Keyword Succeeds    60s    2s    Validate ATT Workflow Driver SI    ENABLED    AWAITING    ${onu_device}
    @{container_list}=    Create List
    Append To List    ${container_list}    att-workflow-att-workflow-driver
    Append To List    ${container_list}    xos-core
    Append To List    ${container_list}    vcore
    Set Suite Variable    ${container_list}
    ${datetime}=    Get Current Datetime On Kubernetes Node    localhost    ${local_user}    ${local_pass}
    Set Suite Variable    ${datetime}

Teardown
    Setup Test
    Delete All Sessions

Setup Test
    ${datetime}=    Get Current Datetime On Kubernetes Node    ${kube_node_ip}     ${local_user}    ${local_pass}
    Set Suite Variable    ${datetime}
    Wait Until Keyword Succeeds    60s    2s    Create Whitelist
    Wait Until Keyword Succeeds    60s    2s    Create Subscriber
    Wait Until Keyword Succeeds    60s    2s    Create VOLT
    Wait Until Keyword Succeeds    120s    2s    Validate ATT Workflow Driver SI    ENABLED    AWAITING    ${onu_device}
    Wait Until Keyword Succeeds    60s    15s    Validate ONU States    ACTIVE    ENABLED    ${onu_device}
    Wait Until Keyword Succeeds    60s    2s    Validate Subscriber Status    awaiting-auth    ${onu_device}
    ${RG_CONTAINER}=    Run    kubectl -n voltha get pod|grep "^rg-"|cut -d' ' -f1
    Set Suite Variable    ${RG_CONTAINER}

Simple Setup
    ${datetime}=    Get Current Datetime On Kubernetes Node    ${kube_node_ip}     ${local_user}    ${local_pass}
    Set Suite Variable    ${datetime}
    ${RG_CONTAINER}=    Run    kubectl -n voltha get pod|grep "^rg-"|cut -d' ' -f1
    Set Suite Variable    ${RG_CONTAINER}

Test Cleanup
    [Documentation]    Restore back to initial state per each test
    Log Kubernetes Containers Logs Since Time    ${datetime}    ${container_list}
    Wait Until Keyword Succeeds    60s    2s    Clean Up Objects    ${VOLT_SUBSCRIBER}
    Wait Until Keyword Succeeds    60s    2s    Clean Up Objects    ${VOLT_DEVICE}
    Wait Until Keyword Succeeds    60s    2s    Clean Up Objects    ${ATT_WHITELIST}
    Restart RG Pod

Restart RG Pod
    Run    kubectl -n voltha delete pod ${RG_CONTAINER}
    ${RG_CONTAINER}=    Wait Until Keyword Succeeds    60s    1s    Run    kubectl -n voltha get pod|grep "^rg-"|cut -d' ' -f1
    Set Suite Variable    ${RG_CONTAINER}
    Run    kubectl wait -n voltha pod/${RG_CONTAINER} --for condition=Ready --timeout=180s

Create Whitelist
    ${AttWhiteListDict}=    utils.listToDict    ${AttWhiteListList}    0
    ${resp}=    CORD Post    ${ATT_WHITELIST}    ${AttWhiteListDict}
    ${whitelist_id}=    Get Json Value    ${resp.content}    /id
    Set Global Variable    ${whitelist_id}

Remove Whitelist
    ${whitelist_id}=    Retrieve Whitelist Entry    ${onu_device}
    CORD Delete    ${ATT_WHITELIST}    ${whitelist_id}

Create Subscriber
    ${SubscriberDict}=    utils.listToDict    ${SubscriberList}    0
    CORD Post    ${VOLT_SUBSCRIBER}    ${SubscriberDict}

Remove Subscriber
    ${subscriber_id}=    Retrieve Subscriber    ${c_tag}
    CORD Delete    ${VOLT_SUBSCRIBER}    ${subscriber_id}

Create VOLT
    ${VoltDeviceDict}=    utils.listToDict    ${VoltDeviceList}    0
    CORD Post    ${VOLT_DEVICE}    ${VoltDeviceDict}

Update Whitelist with Wrong Location
    ${whitelist_id}=    Retrieve Whitelist Entry    ${onu_device}
    CORD Put    ${ATT_WHITELIST}    {"pon_port_id": 55 }    ${whitelist_id}

Update Whitelist with Correct Location
    ${whitelist_id}=    Retrieve Whitelist Entry    ${onu_device}
    CORD Put    ${ATT_WHITELIST}    {"pon_port_id": ${onu_location} }    ${whitelist_id}