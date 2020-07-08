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
