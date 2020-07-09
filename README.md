# cp4d-dg-checks
# Description
This project contains a set of pre-installation checks designed to validate that your system is compatible with RedHat Openshift 4.3.13+ and Cloud Pak 4 Data 3.0.1 installations.
# Setup
1. Clone git repository
2. Set up your hosts_openshift inventory file.
# Usage
This script checks if all nodes meet requirements for OpenShift and CPD installation.

Arguments: 

	--phase=[pre_ocp|post_ocp|pre_cpd]                       To specify installation type
	
	--host_type=[core|worker|master|bastion]                 To specify nodes to check (Default is bastion).
	The valid arguments to --host_type are the names of the groupings of nodes listed in hosts_openshift

	--compute=[worker|compute]                               To specify compute nodes as listed in hosts_openshift for kernel parameter checks (Default is worker)

Example Script Calls: 

	./pre_install_chk.sh --phase=pre_openshift

	./pre_install_chk.sh --phase=post_openshift --host_type=core

# Validation List
| Validation | Requirement | Pre-OCP | Post-OCP | Pre-CPD |
| --- | --- | --- | --- | --- |
| Processor Type | x86_64, ppc64 | X | X | |
| Disk Latency | 50 Kb/sec | X | | |
| Disk Throughput | 1 Gb/sec | X | | |
| DNS Configuration | DNS must be enabled | X | | |
| Resolving hostname via DNS | Hostname resolution enabled | X | X | |
| Default Gateway | Route for default gateway exists | X | | |
| Validate Internet Connectivity | | X | | |
| Valid IPs | | X | | |
| Validate Network Speed | | X | | |
| Check subnet | | X | | |
| Disk Type | Must be xfs file system | X | | |
| Unblocked urls | | X | | |
| Clock Sync | Synchronize computer system clock on all nodes within 500ms | | X | |
| Disk Encryption | LUKS enabled | | X | |
| Openshift Version | at least 4.3.13 | | X | |
| CRI-O Version | at least 1.13 | | X | |
| Timeout Settings (Load Balancer only) | HAProxy timeout should be set to 5 minutes | | X | |
| Max open files on compute | at least 66560 | | X | |
| Max process on compute | at least 12288 | | X | |
| Kernel Virtual Memory on compute | vm.max_map_count>=262144 | | | X |
| Message Limit on compute | kernel.msgmax >= 65536, kernel.msgmnb >= 65536, kernel.msgmni >= 32768 | | | X |
| Shared Memory Limit on compute | kernel.shmmax >= 68719476736, kernel.shmall >= 33554432, kernel.shmmni >= 16384 | | | X |
| Semaphore Limit on compute | kernel.sem >= 250 1024000 100 16384 | | | X |
| Cluster-admin account | | | | X |
| Cluster-admin user must grant the cpd-admin-role to the project administration | | | | X |
| No user group defined under scc anyuid | system:authenticated and system:serviceaccounts should not be in scc anyuid | | | X |

# Unblocked Urls
The machines that are being tested should be be able to reach these links:

	http://registry.ibmcloudpack.com/cpd301/
        https://registry.redhat.io
        https://quay.io
        https://sso.redhat.com
        https://github.com/IBM
        https://cp.icr.io
        https://us.icr.io
        https://gcr.io
        https://k8s.gcr.io
        https://quay.io
        https://docker.io
        https://raw.github.com
        https://myibm.ibm.com
        https://www.ibm.com/software/passportadvantage/pao_customer.html
        https://www.ibm.com/support/knowledgecenter
        http://registry.ibmcloudpack.com/
        https://docs.portworx.com
	
One of the pre-openshift tests will check that these are reachable.


# Helpful Links
If certain tests fail, these links should be able to help address some issues:

	https://www.ibm.com/support/knowledgecenter/SSQNUZ_3.0.1/cpd/install/node-settings.html#node-settings__lb-proxy for changing load balancer timeout settings and compute node docker container settings.
	https://www.ibm.com/support/knowledgecenter/SSEPGG_11.5.0/com.ibm.db2.luw.qb.server.doc/doc/t0008238.html for updating kernel parameters on compute nodes
