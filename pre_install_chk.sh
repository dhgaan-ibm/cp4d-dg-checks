#/bin/bash

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
    ansible-playbook -i hosts_openshift -l ${hosts} playbook/check_oc_ver.yml > ${ANSIBLEOUT}
 
    if [[ `egrep 'unreachable=[1-9]|failed=[1-9]' ${ANSIBLEOUT}` ]]; then
        log "ERROR: Your version of Openshift is not compatible with Cloud Pak 4 Data. Please update to either version 3.11 or 4.3." result
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

function check_crio_version() {
    output=""
    echo -e "\nChecking CRI-O Version" | tee -a ${OUTPUT}
    ansible-playbook -i hosts_openshift -l ${hosts} playbook/check_crio_version.yml > ${ANSIBLEOUT}

    if [[ `egrep 'unreachable=[1-9]|failed=[1-9]' ${ANSIBLEOUT}` ]]; then
        log "ERROR: Version of CRI-O must be at least 1.13." result
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

function check_timeout_settings(){
    output=""
    echo -e "\nChecking Timeout Settings on Load Balancer" | tee -a ${OUTPUT}
    ansible-playbook -i hosts_openshift -l bastion playbook/check_timeout_settings.yml > ${ANSIBLEOUT}

    if [[ `egrep 'unreachable=[1-9]|failed=[1-9]' ${ANSIBLEOUT}` ]]; then
        log "ERROR: Your HAProxy client and server timeout settings are below 5 minutes. 
Please update your /etc/haproxy/haproxy.cfg file. 
Visit https://www.ibm.com/support/knowledgecenter/SSQNUZ_3.0.1/cpd/install/node-settings.html#node-settings__lb-proxy for update commands." result
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
	http://registry.ibmcloudpack.com/cpd301/
	https://registry.redhat.io
	https://quay.io
	https://sso.redhat.com
	https://github.com/IBM
	https://cp.icr.io/cp/cpd
	https://us.icr.io
	https://gcr.io
	https://k8s.gcr.io
	https://quay.io
	https://docker.io
	https://raw.github.com/IBM/cloud-pak/master/repo/cpd3
	https://myibm.ibm.com
	https://www.ibm.com/software/passportadvantage/pao_customer.html
	https://www.ibm.com/support/knowledgecenter
	http://registry.ibmcloudpack.com/
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

function check_fix_clocksync(){
    output=""
    #if [[ ${FIX} -eq 1 ]]; then
    #    echo -e "\nFixing timesync status" | tee -a ${OUTPUT}
    #    ansible-playbook -i hosts_openshift -l ${hosts} playbook/clocksync_fix.yml > ${ANSIBLEOUT}
    #else
    echo -e "\nChecking timesync status" | tee -a ${OUTPUT}
    ansible-playbook -i hosts_openshift -l ${hosts} playbook/clocksync_check.yml > ${ANSIBLEOUT}
#    fi

    if [[ `egrep 'unreachable=[1-9]|failed=[1-9]' ${ANSIBLEOUT}` ]]; then
        log "ERROR: System clock is currently not synchronised, use ntpd or chrony to sync time" result
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

function check_kernel_vm(){
    output=""
    echo -e "\nChecking kernel virtual memory on compute nodes" | tee -a ${OUTPUT}
    ansible-playbook -i hosts_openshift -l worker playbook/kern_vm_check.yml > ${ANSIBLEOUT}

    if [[ `egrep 'unreachable=[1-9]|failed=[1-9]' ${ANSIBLEOUT}` ]]; then
        log "ERROR: Kernel virtual memory on compute nodes should be set to 262144. Please update the vm.max_map_count parameter in /etc/sysctl.conf" result
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

function check_message_limit(){
    output=""
    echo -e "\nChecking message limits on compute nodes" | tee -a ${OUTPUT}
    ansible-playbook -i hosts_openshift -l worker playbook/max_msg_size_check.yml > ${ANSIBLEOUT}

    if [[ `egrep 'unreachable=[1-9]|failed=[1-9]' ${ANSIBLEOUT}` ]]; then
        log "ERROR: Maximum allowable size of messages in bytes should be set to 65536. Please update the kernel.msgmax parameter in /etc/sysctl.conf" result
        cat ${ANSIBLEOUT} >> ${OUTPUT}
        ERROR=1
	ERR=1
	printout "$result"
    fi

    ansible-playbook -i hosts_openshift -l worker playbook/max_queue_size_check.yml > ${ANSIBLEOUT}

    if [[ `egrep 'unreachable=[1-9]|failed=[1-9]' ${ANSIBLEOUT}` ]]; then
        log "ERROR: Maximum allowable size of message queue in bytes should be set to 65536. Please update the kernel.msgmnb parameter in /etc/sysctl.conf" result
        cat ${ANSIBLEOUT} >> ${OUTPUT}
        ERROR=1
	ERR=1
	printout "$result"
    fi

    ansible-playbook -i hosts_openshift -l worker playbook/max_num_queue_check.yml > ${ANSIBLEOUT}

    if [[ `egrep 'unreachable=[1-9]|failed=[1-9]' ${ANSIBLEOUT}` ]]; then
        log "ERROR: Maximum number of queue identifiers should be set to 32768. Please update the kernel.msgmni parameter in /etc/sysctl.conf" result
        cat ${ANSIBLEOUT} >> ${OUTPUT}
        ERROR=1
	ERR=1
	printout "$result"
    fi

    if [[ ${ERR} -eq 0 ]]; then
        log "[Passed]" result
    fi


    LOCALTEST=1
    output+="$result"

    if [[ ${LOCALTEST} -eq 1 && ${ERR} -eq 0 ]]; then
        printout "$output"
    fi

}

function check_shm_limit(){
    output=""
    echo -e "\nChecking shared memory limits on compute nodes" | tee -a ${OUTPUT}
    ansible-playbook -i hosts_openshift -l worker playbook/tot_page_shm_check.yml > ${ANSIBLEOUT}

    if [[ `egrep 'unreachable=[1-9]|failed=[1-9]' ${ANSIBLEOUT}` ]]; then
        log "ERROR: kernel.shmall should be set to 33554432. Please update /etc/sysctl.conf" result
        cat ${ANSIBLEOUT} >> ${OUTPUT}
        ERROR=1
	ERR=1
	printout "$result"
    fi

    ansible-playbook -i hosts_openshift -l worker playbook/max_shm_check.yml > ${ANSIBLEOUT}

    if [[ `egrep 'unreachable=[1-9]|failed=[1-9]' ${ANSIBLEOUT}` ]]; then
        log "ERROR: kernel.shmmax should be set to 68719476736. Please update /etc/sysctl.conf" result
        cat ${ANSIBLEOUT} >> ${OUTPUT}
        ERROR=1
	ERR=1
	printout "$result"
    fi

    ansible-playbook -i hosts_openshift -l worker playbook/max_num_shm_check.yml > ${ANSIBLEOUT}

    if [[ `egrep 'unreachable=[1-9]|failed=[1-9]' ${ANSIBLEOUT}` ]]; then
        log "ERROR: kernel.shmmni should be set to 16384. Please update /etc/sysctl.conf" result
        cat ${ANSIBLEOUT} >> ${OUTPUT}
        ERROR=1
	ERR=1
	printout "$result"
    fi

    if [[ ${ERR} -eq 0 ]]; then
        log "[Passed]" result
    fi

    LOCALTEST=1
    output+="$result"

    if [[ ${LOCALTEST} -eq 1 && ${ERR} -eq 0 ]]; then
        printout "$output"
    fi

}

function check_disk_encryption() {
    output=""
    echo -e "\nChecking Disk Encryption" | tee -a ${OUTPUT}
    ansible-playbook -i hosts_openshift -l ${hosts} playbook/disk_encryption_check.yml > ${ANSIBLEOUT}

    if [[ `egrep 'unreachable=[1-9]|failed=[1-9]' ${ANSIBLEOUT}` ]]; then
        log "ERROR: LUKS Encryption is not enabled." result
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

function check_sem_limit() {
    output=""
    echo -e "\nChecking kernel semaphore limit on compute nodes" | tee -a ${OUTPUT}
    ansible-playbook -i hosts_openshift -l worker playbook/kern_sem_check.yml > ${ANSIBLEOUT}

    if [[ `egrep 'unreachable=[1-9]|failed=[1-9]' ${ANSIBLEOUT}` ]]; then
        log "ERROR: kernel.sem must equal 250 1024000 100 16384. Please update /etc/sysctl.conf" result
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

function check_max_files(){
    output=""
    echo -e "\nChecking maximum number of open files on compute nodes" | tee -a ${OUTPUT}
    ansible-playbook -i hosts_openshift -l worker playbook/max_files_compute_check.yml > ${ANSIBLEOUT}

    if [[ `egrep 'unreachable=[1-9]|failed=[1-9]' ${ANSIBLEOUT}` ]]; then
        log "ERROR: Maximum number of open files should equal 66560. Please update /etc/sysconfig/docker" result
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

function check_max_process(){
    output=""
    echo -e "\nChecking maximum number of processes on compute nodes" | tee -a ${OUTPUT}
    ansible-playbook -i hosts_openshift -l worker playbook/max_process_compute_check.yml > ${ANSIBLEOUT}

    if [[ `egrep 'unreachable=[1-9]|failed=[1-9]' ${ANSIBLEOUT}` ]]; then
        log "ERROR: Maximum number of processes should equal 12288. Please update /etc/sysconfig/docker" result
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
    check_fix_clocksync
    check_kernel_vm
    check_message_limit
    check_timeout_settings
    check_openshift_version
    check_crio_version
    check_shm_limit
    check_disk_encryption
    check_sem_limit
    check_max_files
    check_max_process
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
