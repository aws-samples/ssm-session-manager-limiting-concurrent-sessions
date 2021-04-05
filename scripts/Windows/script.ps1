# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

[Console]::TreatControlCAsInput = $True  #disable ctrl+c

<# 
Required Library: aws and AWS Powershell tools
This section of the will check if AWS CLI is installed; if not, it will install it. it will NOT install AWS Powershell tools
#>
try
{
    ##Make sure to load latest env values
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User") 
    ##Check if command exist; otherwise cause an exception
    Get-Command aws -ErrorAction Stop | Out-Null
}
catch
{
    ##Install AWS CLI
    $dlurl = "https://awscli.amazonaws.com/AWSCLIV2.msi"
    $installerPath = Join-Path $env:TEMP (Split-Path $dlurl -Leaf)
    $logPath = $env:TEMP + '\awsInstall.log'
    Invoke-WebRequest $dlurl -OutFile $installerPath
    Start-Process "msiexec.exe" -ArgumentList "/i $installerPath /qn /L*V $logPath" -Wait
    Remove-Item $installerPath
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User") 
}


<# 
Script to check if exceeded maximum Session Manager Sessions and takes action
#>

###Configuration Options
$MAX_SESSIONS=3  #Number of maximum sessions allowed
$TERMINATE_SESSIONS=$true #This will terminate the sessions starting from the oldest; if set to false, it will list out the sessions IDs, but not terminate them
#possible values $true or $false
$TERMINATE_OLDEST=$true #true/false - if true, script will terminate the oldest session first. if false, the newest session will be terminated.
#Terminating the newest session may result in poor experiance as there will be no message provided to the user.

###Logic
$MESSAGE=$null #clears out message variable (mainly for debugging purposes in case script is run multiple times)

##Get Instance details and configure aws region
$EC2_INSTANCE_ID=Get-EC2InstanceMetadata -Category InstanceId
$REGION=Get-EC2InstanceMetadata -Category Region | Select-Object -ExpandProperty SystemName
aws configure set default.region $REGION

##Get All sessions for the instance and group by owner
$SESSION_INFO=(aws ssm describe-sessions --state "Active" --filter "key=Target,value=$EC2_INSTANCE_ID" | ConvertFrom-Json) 2>&1

if( $lastexitcode -gt 0 ) #An error has occured
{
    $MESSAGE="An Error has occured; ExitCode: $lastexitcode, Details: $SESSION_INFO"
} else
{
    
    $SESSIONS=$SESSION_INFO.Sessions | Group-Object -Property Owner
    $SESSIONS_GROUP=$SESSIONS.Length
    
    if ( $SESSIONS_GROUP -gt 0 )
    {
        $COUNTER=0
        $MESSAGE_HEADER="Too many sessions found:"
        :main while ( $COUNTER -lt $SESSIONS_GROUP )
        {
            $SESSION_COUNT=$SESSIONS[$COUNTER].Count
            if ( $SESSION_COUNT -gt $MAX_SESSIONS )
            {
                $SORTED=$SESSIONS[$COUNTER].Group | Sort-Object -Property @{Expression = "StartDate"; Descending = $TERMINATE_OLDEST}
                while ( $SESSION_COUNT -gt $MAX_SESSIONS )
                {
                    $TERMINATE_ROW=$SESSION_COUNT-1
                    $TERMINATE_SESSION=$SORTED[$TERMINATE_ROW].SessionId
                    
                    if ( $TERMINATE_SESSIONS -eq $true )
                    {
                        $TERMINATOR=aws ssm terminate-session --session-id $TERMINATE_SESSION 2>&1
                        if( $lastexitcode -gt 0 ) #An error has occured
                        {
                            $MESSAGE="An Error has occured; ExitCode: $lastexitcode, Details: $TERMINATOR"
                            break main
                        }
                        
                        $MESSAGE="$MESSAGE`n Terminated Session $TERMINATE_SESSION"
                    }
                    else
                    {
                        $MESSAGE="$MESSAGE`n$TERMINATE_SESSION"
                    }
                    
                    $SESSION_COUNT--
                }
            }
            $COUNTER++
        }
        
        if ( ![string]::IsNullOrEmpty($MESSAGE) )
        {
            $MESSAGE=$MESSAGE_HEADER+$MESSAGE
        }
    } else
    {
        $MESSAGE="No active sessions for this instance"
    }
}
[Console]::TreatControlCAsInput = $False #enable ctrl+c
Clear-Host; Write-Host $MESSAGE