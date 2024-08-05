#!/bin/bash

## Ubah nilai disini:
SSH_USER="OMVUsername"
SSH_IDENTITY_FILE=".ssh/omv"
SSH_HOST="123.456.789.111" ## Openmediavault IP
SSH_PORT="22" ## Openmediavault-SSH-Port (Default 22)
BACKUP_DIRECTORIES="/your/source/backup/directory/webapp /your/source/backup/directory/database" ## Source backup folder.
TARGET_DIRECTORY="/your/target/directory/omv" ## Target folder di OMV

## Jangan ubah nilai atau apapun disini!

TIME=$(date +"%d-%m-%Y-%H:%M")

TEMP_LOGFILE="/tmp/tmp-backup-log-file.log"
REMOTE_LOGFILE="$TARGET_DIRECTORY/logs/$TIME.log"
ssh -p $SSH_PORT -i $SSH_IDENTITY_FILE $SSH_USER@$SSH_HOST mkdir -p "$TARGET_DIRECTORY/logs"
red="\e[0;91m"
green="\e[0;92m"
reset="\e[0m"

echo -e "-------------------------------------------------------------"
echo -e "${green}$TIME : Backup started${reset}" | tee -a $TEMP_LOGFILE
echo -e "-------------------------------------------------------------"
rsync -e "ssh -i $SSH_IDENTITY_FILE -p $SSH_PORT" --timeout=20 -q $TEMP_LOGFILE $SSH_USER@$SSH_HOST:$REMOTE_LOGFILE ## To be able to see that rsync-process was started. If the logs stay empty after, it means there was an error during backup, but the process started.
for SOURCE in $BACKUP_DIRECTORIES 
do
    echo -e "-------------------------------------------------------------"
    echo -e "${green}Starting: $SOURCE > $TARGET_DIRECTORY${reset}" | tee -a $TEMP_LOGFILE
    echo -e "-------------------------------------------------------------"
    rsync -e "ssh -i $SSH_IDENTITY_FILE -p $SSH_PORT" --timeout=20 --partial -avi -H $SOURCE $SSH_USER@$SSH_HOST:$TARGET_DIRECTORY | tee -a $TEMP_LOGFILE
    if [ $? -eq 0 ]
    then
        echo -e "-------------------------------------------------------------"
        echo -e "${green}Directory: $SOURCE successful synced${reset}" | tee -a $TEMP_LOGFILE
        echo -e "-------------------------------------------------------------"
    else
        echo -e "-------------------------------------------------------------"
        echo -e "${red}Something went wrong${reset}" | tee -a $TEMP_LOGFILE
        echo -e "-------------------------------------------------------------"
    fi
done
echo -e "-------------------------------------------------------------"
echo -e "${green}Backup finished. Sending logfile to $REMOTE_LOGFILE ${reset}" | tee -a $TEMP_LOGFILE
echo -e "-------------------------------------------------------------"
rsync -e "ssh -i $SSH_IDENTITY_FILE -p $SSH_PORT" --timeout=20 -q $TEMP_LOGFILE $SSH_USER@$SSH_HOST:$REMOTE_LOGFILE
rm $TEMP_LOGFILE
