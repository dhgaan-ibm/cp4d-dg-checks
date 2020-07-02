#!/bin/bash

#output file
OUTPUT="/tmp/preInstallCheckResult"
ANSIBLEOUT="/tmp/preInstallAnsible"

rm -f ${OUTPUT}
rm -f ${ANSIBLEOUT}

#user variables
disk_storage_path="{{ disk_st_path }}"
PRE=0
POST=0
hosts=bastion

#global variables
GLOBAL=(3.11, 4.3)

function log() {
    if [[ "$1" =~ ^ERROR* ]]; then
	eval "$2='\033[91m\033[1m$1\033[0m'"
    elif [[ "$1" =~ ^Running* ]]; then
	eval "$2='\033[1m$1\033[0m'"
    elif [[ "$1" =~ ^WARNING* ]]; then
	eval "$2='\033[1m$1\033[0m'"
    else
	eval "$2='\033[92m\033[1m$1\033[0m'"
    fi
}

function printout() {
    echo -e "$1" | tee -a ${OUTPUT}
}

function check_openshift_version() {
    output=""
    echo -e "\nChecking Openshift Version" | tee -a ${OUTPUT}
    os_version = 
 
} 

function check_timeout_settings(){
    output=""
    echo -e "\nChecking Timeout Settings on Load Balancer" | tee -a ${OUTPUT}
    ansible-playbook -i hosts_openshift -l bastion playbook/dnsconfig_check.yml > ${ANSIBLEOUT}
 
}

function validate_internet_connectivity(){
    output=""
    echo -e "\nChecking Connection to Internet" | tee -a ${OUTPUT}
    ansible-playbook -i hosts_openshift -l ${hosts} playbook/internet_connect.yml > ${ANSIBLEOUT}

    if [[ `egrep 'unreachable=[1-9]|failed=[1-9]' ${ANSIBLEOUT}` ]]; then
	log "ERROR: Could not reach IBM.com. Check internet connection" result
	cat ${ANSIBLEOUT} >> ${OUTPUT}
	ERROR=1
    else
	log "[Passed]" result
    fi
    LOCALTEST=1
    output+="$result"

    if [[ ${LOCALTEST} -eq 1 ]]; then
	printout "$output"
    fi    
}

function validate_ips(){
    output=""
    echo -e "\nChecking for host IP Address" | tee -a ${OUTPUT}
    ansible-playbook -i hosts_openshift -l ${hosts} playbook/validate_ip_addresses.yml > ${ANSIBLEOUT}
    
    if [[ `egrep 'unreachable=[1-9]|failed=[1-9]' ${ANSIBLEOUT}` ]]; then
        log "ERROR: Host ip is not a valid ip." result
        cat ${ANSIBLEOUT} >> ${OUTPUT}
        ERROR=1
    else
        log "[Passed]" result
    fi
    LOCALTEST=1
    output+="$result"

    if [[ ${LOCALTEST} -eq 1 ]]; then
        printout "$output"
    fi
}

function validate_network_speed(){
    echo -e "test"
}

function check_subnet(){
    output=""
    echo -e "\nChecking subnet" | tee -a ${OUTPUT}
    ansible-playbook -i hosts_openshift -l ${hosts} playbook/check_subnet.yml > ${ANSIBLEOUT}
    
    if [[ `egrep 'unreachable=[1-9]|failed=[1-9]' ${ANSIBLEOUT}` ]]; then
        log "ERROR:." result
        cat ${ANSIBLEOUT} >> ${OUTPUT}
        ERROR=1
    else
        log "[Passed]" result
    fi
    LOCALTEST=1
    output+="$result"

    if [[ ${LOCALTEST} -eq 1 ]]; then
        printout "$output"
    fi

}

function check_dnsconfiguration(){
    output=""
    echo -e "\nChecking DNS Configuration" | tee -a ${OUTPUT}
    ansible-playbook -i hosts_openshift -l ${hosts} playbook/dnsconfig_check.yml > ${ANSIBLEOUT}

    if [[ `egrep 'unreachable=[1-9]|failed=[1-9]' ${ANSIBLEOUT}` ]]; then
        log "ERROR: DNS is not properly setup. Could not find a proper nameserver in /etc/resolv.conf " result
        cat ${ANSIBLEOUT} >> ${OUTPUT}
        ERROR=1
    else
        log "[Passed]" result
    fi
    LOCALTEST=1
    output+="$result"

    if [[ ${LOCALTEST} -eq 1 ]]; then
        printout "$output"
    fi
}

function check_processor() {
    output=""
    echo -e "\nChecking Processor Type" | tee -a ${OUTPUT}
    ansible-playbook -i hosts_openshift -l ${hosts} playbook/processor_check.yml > ${ANSIBLEOUT}

    if [[ `egrep 'unreachable=[1-9]|failed=[1-9]' ${ANSIBLEOUT}` ]]; then
	log "ERROR: Processor type must be x86_64" result
	cat ${ANSIBLEOUT} >> ${OUTPUT}
	ERROR=1
    else
	log "[PASSED]" result
    fi
    LOCALTEST=1
    output+="$result"

    if [[ ${LOCALTEST} -eq 1 ]]; then
	printout "$output"
    fi
}

function check_dockerdir_type(){
    output=""
    echo -e "\nChecking XFS FSTYPE for docker storage" | tee -a ${OUTPUT}
    ansible-playbook -i hosts_openshift -l ${hosts} playbook/dockerdir_type_check.yml > ${ANSIBLEOUT}

    if [[ `egrep 'unreachable=[1-9]|failed=[1-9]' ${ANSIBLEOUT}` ]]; then
        log "ERROR: Docker target filesystem must be formatted with ftype=1. Please reformat or move the docker location" result
        cat ${ANSIBLEOUT} >> ${OUTPUT}
        ERROR=1
    else
        log "[Passed]" result
    fi
    LOCALTEST=1
    output+="$result"

    if [[ ${LOCALTEST} -eq 1 ]]; then
        printout "$output"
    fi
}

function check_dnsresolve(){
    output=""
    echo -e "\nChecking hostname can resolve via  DNS" | tee -a ${OUTPUT}
    ansible-playbook -i hosts_openshift -l ${hosts} playbook/dnsresolve_check.yml > ${ANSIBLEOUT}

    if [[ `egrep 'unreachable=[1-9]|failed=[1-9]' ${ANSIBLEOUT}` ]]; then
	if [[ `grep 'host: command not found' ${ANSIBLEOUT}` ]]; then
	    log "ERROR: \"host\" command does not exist on this machine. Please install command to run this check." result
	    cat ${ANSIBLEOUT} >> ${OUTPUT}
	    ERROR=1
	else
            log "ERROR: hostname is not resolved via the DNS. Check /etc/resolve.conf " result
            cat ${ANSIBLEOUT} >> ${OUTPUT}
            ERROR=1
        fi
    else
        log "[Passed]" result
    fi
    LOCALTEST=1
    output+="$result"

    if [[ ${LOCALTEST} -eq 1 ]]; then
        printout "$output"
    fi
}

function check_gateway(){
    output=""
    echo -e "\nChecking Default Gateway" | tee -a ${OUTPUT}
    ansible-playbook -i hosts_openshift -l ${hosts} playbook/gateway_check.yml > ${ANSIBLEOUT}

    if [[ `egrep 'unreachable=[1-9]|failed=[1-9]' ${ANSIBLEOUT}` ]]; then
        log "ERROR: default gateway is not setup " result
        cat ${ANSIBLEOUT} >> ${OUTPUT}
        ERROR=1
    else
        log "[Passed]" result
    fi
    LOCALTEST=1
    output+="$result"

    if [[ ${LOCALTEST} -eq 1 ]]; then
        printout "$output"
    fi
}

function check_hostname(){
    output=""
    echo -e "\nChecking if hostname is in lowercase characters" | tee -a ${OUTPUT}
    ansible-playbook -i hosts_openshift -l ${hosts} playbook/hostname_check.yml > ${ANSIBLEOUT}

    if [[ `egrep 'unreachable=[1-9]|failed=[1-9]' ${ANSIBLEOUT}` ]]; then
        log "ERROR: Only lowercase characters are supported in the hostname" result
        cat ${ANSIBLEOUT} >> ${OUTPUT}
        ERROR=1
    else
        log "[Passed]" result
    fi
    LOCALTEST=1
    output+="$result"

    if [[ ${LOCALTEST} -eq 1 ]]; then
        printout "$output"
    fi
}

function check_disklatency(){
    output=""
    echo -e "\nChecking Disk Latency" | tee -a ${OUTPUT}
    ansible-playbook -i hosts_openshift -l ${hosts} playbook/disklatency_check.yml > ${ANSIBLEOUT}

    if [[ `egrep 'unreachable=[1-9]|failed=[1-9]' ${ANSIBLEOUT}` ]]; then
        log "ERROR: Disk latency test failed. By copying 512 kB, the time must be shorter than 60s, recommended to be shorter than 10s." result
        cat ${ANSIBLEOUT} >> ${OUTPUT}
        ERROR=1
    else
        log "[Passed]" result
    fi
    LOCALTEST=1
    output+="$result"

    if [[ ${LOCALTEST} -eq 1 ]]; then
        printout "$output"
    fi
}

function check_diskthroughput(){
    output=""
    echo -e "\nChecking Disk Throughput" | tee -a ${OUTPUT}
    ansible-playbook -i hosts_openshift -l ${hosts} playbook/diskthroughput_check.yml > ${ANSIBLEOUT}

    if [[ `egrep 'unreachable=[1-9]|failed=[1-9]' ${ANSIBLEOUT}` ]]; then
        log "ERROR: Disk throughput test failed. By copying 1.1 GB, the time must be shorter than 35s, recommended to be shorter than 5s" result
        cat ${ANSIBLEOUT} >> ${OUTPUT}
        ERROR=1
    else
        log "[Passed]" result
    fi
    LOCALTEST=1
    output+="$result"

    if [[ ${LOCALTEST} -eq 1 ]]; then
        printout "$output"
    fi
}

function check_unblocked_urls(){
    output=""
    echo -e "\nChecking connectivity to required links" | tee -a ${OUTPUT}
    BLOCKED=0
    URLS=(
	registry.redhat.io
	*.quay.io
	sso.redhat.com
	https://github.com/IBM
	cp.icr.io/cp/cpd
	us.icr.io
	gcr.io
	k8s.gcr.io
	quay.io
	docker.io
	https://raw.githubusercontent.com/IBM/cloud-pak/master/repo/cpd
	myibm.ibm.com
	https://www.ibm.com/software/passportadvantage/pao_customer.html
	https://www.ibm.com/support/knowledgecenter
	http://registry.ibmcloudpack.com/cpd/cpd-portworx-2.5.0.tar.gz
	https://docs.portworx.com
    )
    for i in "${URLS[@]}"
    do
       :
       ansible-playbook -i hosts_openshift -l ${hosts} playbook/url_check.yml -e "url=$i" > ${ANSIBLEOUT}

    if [[ `egrep 'unreachable=[1-9]|failed=[1-9]' ${ANSIBLEOUT}` ]]; then
        log "WARNING: $i is not reachable." result
        cat ${ANSIBLEOUT} >> ${OUTPUT}
        WARNING=1
        BLOCKED=1
        printout "$result"
    fi
    done

    if [[ ${BLOCKED} -eq 0 ]]; then
        log "[Passed]" result
    fi
    LOCALTEST=1
    output+="$result"
   
    if [[ ${LOCALTEST} -eq 1 && ${BLOCKED} -eq 0 ]]; then
        printout "$output"
    fi
}

function check_ibmartifactory(){
    output=""
    echo -e "\nChecking connectivity to IBM Artifactory servere" | tee -a ${OUTPUT}
    ansible-playbook -i hosts_openshift -l ${hosts} playbook/ibmregistry_check.yml > ${ANSIBLEOUT}

    if [[ `egrep 'unreachable=[1-9]|failed=[1-9]' ${ANSIBLEOUT}` ]]; then
        log "WARNING: cp.icr.io is not reachable. Enabling proxy might fix this issue." result
        cat ${ANSIBLEOUT} >> ${OUTPUT}
        WARNING=1
    else
        log "[Passed]" result
    fi
    LOCALTEST=1
    output+="$result"

    if [[ ${LOCALTEST} -eq 1 ]]; then
        printout "$output"
    fi
}

function check_redhatartifactory(){
    output=""
    echo -e "\nChecking connectivity to RedHat Artifactory servere" | tee -a ${OUTPUT}
    ansible-playbook -i hosts_openshift -l ${hosts} playbook/redhatregistry_check.yml > ${ANSIBLEOUT}

    if [[ `egrep 'unreachable=[1-9]|failed=[1-9]' ${ANSIBLEOUT}` ]]; then
        log "WARNING: registry.redhat.io is not reachable. Enabling proxy might fix this issue." result
        cat ${ANSIBLEOUT} >> ${OUTPUT}
        WARNING=1
    else
        log "[Passed]" result
    fi
    LOCALTEST=1
    output+="$result"

    if [[ ${LOCALTEST} -eq 1 ]]; then
        printout "$output"
    fi
}

if [[ $# -lt 1 ]]; then
    echo -e "Please specify pre/post. i.e. --phase=[pre_openshift|post_openshift]"
    exit 1
else
    for var in "$@"
	do
	case $var in

	    --phase=*)
		CHECKTYPE="${var#*=}"
                shift
                if [[ "$CHECKTYPE" = "pre_openshift" ]]; then
                    PRE=1
                elif [[ "$CHECKTYPE" = "post_openshift" ]]; then
                    POST=1
                else
                    echo "please only specify check type pre_openshift/post_openshift"
                    exit 1
                fi            
                ;;

            --host_type=*)
		HOSTTYPE="${var#*=}"
		shift
		hosts=${HOSTTYPE}
		;;

	esac
	done
fi

if [[ ${PRE} -eq 1 ]]; then
#    validate_internet_connectivity
#    validate_ips
#    check_dnsconfiguration
#    check_processor
#    check_dnsresolve
#    check_gateway
#    check_hostname
#    check_disklatency
#    check_diskthroughput
#    check_ibmartifactory
#    check_redhatartifactory
#    check_dockerdir_type
    check_unblocked_urls
elif [[ ${POST} -eq 1 ]]; then
    echo -e "\nNot implemented."
    exit 1
fi

if [[ ${ERROR} -eq 1 ]]; then
    echo -e "\nFinished with ERROR, please check ${OUTPUT}"
    exit 2
elif [[ ${WARNING} -eq 1 ]]; then
    echo -e "\nFinished with WARNING, please check ${OUTPUT}"
    exit 1
else
    echo -e "\nFinished successfully! This node meets the requirement" | tee -a ${OUTPUT}
    exit 0
fi
