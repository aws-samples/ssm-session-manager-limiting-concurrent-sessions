
# Systems Manager Session Manager - Limiting Concurrent Sessions
The purpose of this project is to allow System Administrators to limit active concurrent Session Manager (SSM) sessions. This application uses TypeScript to configure the iAM Policy and Session Manager Preferences; The SSM Preferences include Windows and Linux Shell Profiles which run on the EC2 instance every time a new SSM session is started. Once these scripts execute, they check if concurrent session have been exceeded and terminates the oldest session.

Typescript portion of the application is used for setup. Users may choose NOT to use the script and apply the changes to Session Manager via the AWS console. All the required scripts are located in the **scripts** folder.

## Requirements
* [AWS SDK](https://github.com/aws/aws-sdk-js) 
* [Node.js/NPM](https://www.npmjs.com/get-npm)
* Linux Shell Profile:
	* [./jq](https://stedolan.github.io/jq/)
	* [wget](https://www.gnu.org/software/wget/)
	* [AWS CLI](https://aws.amazon.com/cli/)
* Windows Shell Profile:
	* [AWS CLI](https://aws.amazon.com/cli/)

## Configuring the application

<details><summary><b>Required: Configuration File: config.json</b></summary>

Please configure the AWS region and [Credentials](https://docs.aws.amazon.com/sdk-for-javascript/v2/developer-guide/setting-credentials-node.html) (leave empty if using CLI profile is configured) as required. This configuration will run this application in the specified region.

```json
{
  "region": "us-east-1",
  "credentials": {
    "accessKeyId": "",
    "secretAccessKey": "",
    "sessionToken ": ""
  }
}
```

</details>

<details><summary><b>(Recommended) Configuring Session Manager Preferences: scripts/BaseSessionManagerPreferences.json</b></summary>

This configuration file contains all the configurable preferences for SSM. These settings will replace any previously configured settings in the console. Please configure them as required. 

**Note:** The shell profile section will be replaced by the setup script.
</details>

<details><summary><b>(Optional) Shell Profiles: scripts/Windows, scripts/Linux</b></summary>

These folders contain the Shell Profile script which are executed every time the user starts an SSM session. You may configure the Max Session and Terminate Sessions values as required.

**Max Session**: Total number of sessions are allowed before taking action
**Terminate Session**: If the script should terminate the session or just notify the user.
**Terminate Oldest**: Determins if the terminated session is the oldest or the newest. Note: Terminating the newsest session may result in poor user experiance.

```powershell
###Configuration Options
$MAX_SESSIONS=3  #Number of maximum sessions allowed
$TERMINATE_SESSIONS=$true #This will terminate the sessions starting from the oldest; if set to false, it will list out the sessions IDs, but not terminate them
#possible values $true or $false
$TERMINATE_OLDEST=$true #true/false - if true, script will terminate the oldest session first. if false, the newest session will be terminated.
#Terminating the newest session may result in poor experiance as there will be no message provided to the user.
```

```bash
###Configuration Options
MAX_SESSIONS=3  #Number of maximum sessions allowed
TERMINATE_SESSIONS=true #This will terminate the sessions starting from the oldest; if set to false, it will list out the sessions IDs, but not terminate them
TERMINATE_OLDEST=true #true/false - if true, script will terminate the oldest session first. if false, the newest session will be terminated.
#Terminating the newest session may result in poor experiance as there will be no message provided to the user.
```
</details>


## Building the application

To build your application, run the following in your shell:

```bash
$ npm install
$ npm run compile
```
<details>
By executing the above commands, the system does the following:

1. Downloads all the development libraries.
2. Compiles all the TS code and JSON scripts required for deployment.

All of the compiled artifacts are stored in the **out** folder
</details>


### Deploying the application

To deploy your application for the first time, run the following in your shell:

```bash
$ npm run deploy
```

The command will deploy the SSM Preferences and create an iAM Policy (named *SSMConcurrentSessionsPolicy*).

**Common Failures**:
* **Policy Already Exist**: If the policy already exist, failure will be noted. Please delete the policy via the console
* **SSM Preference update failure**: This is caused if the application is run multiple times with no changes to the SSM Preferences.

## Required Manual Setup
The deployment process will only configure the SSM Preferences and iAM Policy. Administrator must still attach the created iAM Policy with the appropriate instance roles for the scripts to run.

## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## License

This library is licensed under the MIT-0 License. See the [LICENSE](/LICENSE) file.