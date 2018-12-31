# CORD Test Environment

Several jenkins based jobs are created to run tests on the following platforms

* Physical POD

* Seba-in-a-Box

* VMs 

## Test Beds

Following picture below describes various test environments that are used to
setup CORD and a brief overview on the type of tests that are performed on that
test bed.

![Test Beds](images/qa_testbed_diag.png)

## Physical POD Topology

Following diagram shows how the POD is configured for running system tests

![QA Physical POD](images/flex-qa-pod.png)

## Jenkins Test Setup

The following diagram shows how the test servers are interconnected

![QA Jenkins Setup](images/SEBA-QA-Jenkins.png)

* To view results from recent runs of the jenkins jobs, please view the
  [Jenkins dashboard](https://jenkins.opencord.org/)
