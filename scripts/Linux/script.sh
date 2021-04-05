# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

{
    trap '' 2  #disable ctrl+c
    ### Remove this section if JQ & wget is already installed
    ### to install the packages, sudo or root privilages are required, otherwise the script will fail
    {
        YUM_PACKAGE_NAME="jq wget"
        DEB_PACKAGE_NAME="jq wget"
        YUM_CMD=$(which yum 2>/dev/null)
        APT_GET_CMD=$(which apt-get 2>/dev/null)
        
        #check for root; if not root setup sudo
        if [[ $EUID -gt 0 ]]
        then
            #do nothing
            INSTALL_COMMAND="sudo"
        fi
        
        if [[ ! -z $YUM_CMD ]]
        then
            INSTALL_COMMAND="$INSTALL_COMMAND yum install -y $YUM_PACKAGE_NAME"
        elif [[ ! -z $APT_GET_CMD ]]
        then
            INSTALL_COMMAND="$INSTALL_COMMAND apt-get install $DEB_PACKAGE_NAME"
        fi
         
         
        #install package
        eval $INSTALL_COMMAND
    }
    
    
    ###Script to check if exceeded maximum Session Manager Sessions and takes action
    {
        ###Configuration Options
        MAX_SESSIONS=3  #Number of maximum sessions allowed
        TERMINATE_SESSIONS=true #This will terminate the sessions starting from the oldest; if set to false, it will list out the sessions IDs, but not terminate them
        TERMINATE_OLDEST=true #true/false - if true, script will terminate the oldest session first. if false, the newest session will be terminated.
        #Terminating the newest session may result in poor experiance as there will be no message provided to the user.
        
        
        ###Logic
        MESSAGE="" #clears out message variable (mainly for debugging purposes in case script is run multiple times)
        
        ##Configure Reverse Logic
        REVERSE_LOGIC='| reverse'
        if [[ "$TERMINATE_OLDEST" = false ]]
        then
            REVERSE_LOGIC=''
        fi
        
        ##Get Instance details and configure aws region
        EC2_INSTANCE_ID=$(wget -q -O - http://169.254.169.254/latest/meta-data/instance-id || die \"wget instance-id has failed: $?\")
        REGION=$(wget -q -O - http://169.254.169.254/latest/meta-data/placement/region || die \"wget availability-zone has failed: $?\")
        aws configure set default.region $REGION
        
        
        ##Get All sessions for the instance and group by owner
        SESSION_INFO=$(aws ssm describe-sessions --state "Active" --filter "key=Target,value=$EC2_INSTANCE_ID" 2>&1)
        if [[ $? -gt 0 ]]  #An error has occured
        then
            MESSAGE="An Error has occured; ExitCode: $?, Details: $SESSION_INFO"
        else
            SESSIONS=$(jq '.Sessions | group_by(.Owner)' <<< $SESSION_INFO)
            SESSIONS_GROUP=$(jq 'length' <<< $SESSIONS)
            
            if [[ $SESSIONS_GROUP -gt 0 ]]
            then
                COUNTER=0
                MESSAGE_HEADER="Too many sessions found:"
                while [ $COUNTER -lt $SESSIONS_GROUP ]
                do
                    SESSION_COUNT=$(jq ".[$COUNTER] | length" <<< $SESSIONS)
                    if [ $SESSION_COUNT -gt $MAX_SESSIONS ]
                    then
                        SORTED=$(jq ".[$COUNTER] | sort_by(.StartDate) $REVERSE_LOGIC" <<< $SESSIONS)
                        while [ $SESSION_COUNT -gt $MAX_SESSIONS ]
                        do
                            TERMINATE_ROW=$(($SESSION_COUNT-1))
                            TERMINATE_SESSION=$(jq -r ".[$TERMINATE_ROW].SessionId" <<< $SORTED)
                            
                            if [[ "$TERMINATE_SESSIONS" = true ]]
                            then
                                TERMINATOR=$(aws ssm terminate-session --session-id $TERMINATE_SESSION 2>&1)
                                if [[ $? -gt 0 ]]  #An error has occured
                                then
                                    MESSAGE="An Error has occured; ExitCode: $?, Details: $TERMINATOR"
                                    break 2
                                fi
                                MESSAGE="$MESSAGE\n Terminated Session $TERMINATE_SESSION"
                            else
                                MESSAGE="$MESSAGE\n$TERMINATE_SESSION"
                            fi
                            
                            
                            SESSION_COUNT=$(($SESSION_COUNT-1))
                        done
                    fi
                    COUNTER=$((COUNTER+1))
                done
                if [[ ! -z "$MESSAGE" ]]
                then
                    MESSAGE=$MESSAGE_HEADER$MESSAGE
                fi
            else
                MESSAGE="No active sessions for this instance"
            fi
        fi
    }
    trap 2  #enable ctrl+c
    clear && echo -e $MESSAGE
    
}