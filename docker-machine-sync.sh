#!/bin/bash

SSH_TO_HOST=''
DOCKER_HOST_SSH_KEY=''
HOST=''
PIDS_FILE_PATH=~/.docker/unison
PIDS_FILE=$PIDS_FILE_PATH/RUNNING_PIDS
function umount_dirs() {
    local mounts=$($SSH_TO_HOST mount | grep 'type vboxsf' | awk '{print $3}')
    if [ -n "$mounts" ]; then
        echo "Will umount $mounts"
        $SSH_TO_HOST sudo umount $mounts
    fi



}

function check_install(){
    local unison=$($SSH_TO_HOST ls /var/lib/boot2docker/ | grep unison)

    if [ -z "$unison" ]; then
        #TODO
        echo "Unison not found, will install!"
        $SSH_TO_HOST << EOF
            wget https://raw.githubusercontent.com/juozapas/docker-machine-unison/master/install-unison.sh
            chmod +x install-unison.sh
            ./install-unison.sh
EOF
    fi


}

function create_dirs_on_vm(){
    $SSH_TO_HOST sudo mkdir -p $1
    $SSH_TO_HOST sudo chmod 777 $1
}



function start_sync(){

    create_dirs_on_vm $1

    local is_running=$(check_if_process_running ${1})
    if [ "$is_running" = false ] ; then
        echo "Starting to sync $1"

        local ssh_ops="-i $DOCKER_HOST_SSH_KEY -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null"
        #TODO learn bash, stop copying
        unison -batch $1 ssh://docker@$(docker-machine ip $HOST)/$1 \
            -confirmbigdel=false -ignorelocks \
            -sshargs "$ssh_ops" \
            -ignorearchives \
            -dontchmod -perms=0 \
            -fastercheckUNSAFE=true \
            -times \
            -prefer=$1 > $PIDS_FILE_PATH/unison.log 2>&1 &

        fswatch -o . | xargs -n1 -I{} unison -batch $1 ssh://docker@$(docker-machine ip $HOST)/$1 \
            -confirmbigdel=false -ignorelocks \
            -sshargs "$ssh_ops" \
            -ignorearchives \
            -dontchmod -perms=0 \
            -times \
            -prefer=$1 > $PIDS_FILE_PATH/unison.log 2>&1 &
        save_pid $! $1
    fi

}

function save_pid(){
    local pid=$(check_if_fswatch_pid_exists ${1})
    if [ -n "$pid" ]; then
        echo $2 | sed -e 's/[]\/$*.^|[]/\\&/g' | sed -i.bak "s/\($replaced *= *\).*/\1$1/" $PIDS_FILE
    else
        echo "$2=$1" > $PIDS_FILE
    fi

}


function check_if_fswatch_pid_exists() {
    local pid=$(grep $1 $PIDS_FILE | sed -e 's/.*=\(.*\)/\1/')
    echo $pid

}

function check_if_process_running(){
    create_PIDs_file_if_not_exists
    local pid=$(check_if_fswatch_pid_exists ${1})


    if [ -n "$pid" ]; then
        if ps -p $pid > /dev/null
        then
            echo true
        else
            echo false
        fi
    else
        echo false
    fi



}


function create_PIDs_file_if_not_exists() {
    if [ ! -f $PIDS_FILE ]; then
        echo "PIDs file not found, creating $PIDS_FILE"
        mkdir -p $PIDS_FILE_PATH
        touch $PIDS_FILE
    fi

}
function init() {
    HOST=$1
    SSH_TO_HOST="docker-machine ssh $1"
    DOCKER_HOST_SSH_KEY=$(docker-machine inspect $1 | grep "SSHKeyPath"  | sed -e 's/"SSHKeyPath": "\(.*\)"./\1/')
    umount_dirs
    check_install
}


function parse_compose(){

    local to_sync=$(docker-compose config | awk 'BEGIN{found=0}
                            {if (/volumes:/)
                                found=1;
                            else if(/-/ && found)
                                print $0;
                            else if(found)
                                found=0;
                            }' \
                          | grep ".*:.*:"  \
                          | sed -e 's/\s*\-\s*\(.*\):.*/\1/' \
                          | sed -e 's/\s*\(.*\):.*/\1/')

    echo $to_sync
}


function run(){
    if [ -z "$DOCKER_MACHINE_NAME" ]; then
        echo "variable DOCKER_MACHINE_NAME not set."
        echo "#Run this command to configure your shell"
        echo "eval $(docker-machine env default)"
        exit 1
    fi
    init $DOCKER_MACHINE_NAME
    local to_sync=($(parse_compose))

    for i in ${to_sync[@]}; do
        start_sync $i
    done

}

run $@
#parse_compose
#save_pid nothing /Users/juozas/Development/Personal/tracker/backups