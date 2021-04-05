/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: MIT-0
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of this
 * software and associated documentation files (the "Software"), to deal in the Software
 * without restriction, including without limitation the rights to use, copy, modify,
 * merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
 * INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
 * PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
 * OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */
 
import * as fs from 'fs';
import AWS from 'aws-sdk';

let config = JSON.parse(fs.readFileSync( __dirname + '/../config.json','utf8'));
let mergedScript = fs.readFileSync( __dirname + '/MergedSessionManagerPreferences.json','utf8');
let policy = fs.readFileSync( __dirname + '/Policy.json','utf8');

//create a backup folder if it does not exist
let backupFolder = __dirname + '/../backup';
if (!fs.existsSync(backupFolder)){
    fs.mkdirSync(backupFolder);
}

//setup aws config
AWS.config.region = config.region
if (config.credentials.accessKeyId)
{
  AWS.config.credentials = new AWS.Credentials(config.credentials.accessKeyId, config.credentials.secretAccessKey, config.credentials.sessionToken)
}


//initialize SDK
let ssm = new AWS.SSM();
let iam = new AWS.IAM();


/* Policy Creation & Update */
let policyName = 'SSMConcurrentSessionsPolicy';

//If policy exist, this step will fail, however the rest of the script will continue -- Readme file has details on the content of the policy
let policyParms = {
  PolicyDocument: policy,
  PolicyName: policyName,
};

iam.createPolicy(policyParms, function(err, data) {
  if (err) {
    console.log("Unable to create Policy, please verify if the policy is correct:", err);
  } else {
    console.log("Policy Created Succesfully:", data);
  }
});





/* SSM Document Backup and Creation  */
//SSM Request to Get Existing document
let ssmParmExisting = {
    Name: 'SSM-SessionManagerRunShell', /* required */
    DocumentFormat:  'JSON',
    DocumentVersion: '$LATEST'
}

//take backup for what is already there
ssm.getDocument(ssmParmExisting, function(err, data) {
  if (err) console.log(err, err.stack); // an error occurred
  else
  { // successful response create a backup file
    let response = data.Content as string;
    let existingPreferences = JSON.parse(response);
    fs.writeFileSync( backupFolder + '/SessionManagerPreferences' + (new Date()).toISOString() + '.json', JSON.stringify(existingPreferences, null, 2));
  }
});

//SSM Request to update
let ssmParmUpdate = {
    Content: mergedScript,
    Name: 'SSM-SessionManagerRunShell',
    DocumentFormat:  'JSON',
    DocumentVersion: '$LATEST'
}

//update SSM document
ssm.updateDocument(ssmParmUpdate, function(err, data) {
  if (err) console.log('SSM Preferences update failed, please ensure correct Preferences are applied:', err); // an error occurred
  else     console.log('SSM Preferences updated succesfully:', data);           // successful response
});