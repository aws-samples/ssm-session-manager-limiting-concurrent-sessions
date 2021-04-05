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

//Load All the session manager preference and scripts into memory
let basePreference = fs.readFileSync( __dirname + '/../scripts/BaseSessionManagerPreferences.json','utf8');
let linuxScript = fs.readFileSync( __dirname + '/../scripts/Linux/script.sh','utf8');
let windowsScript = fs.readFileSync( __dirname + '/../scripts/Windows/script.ps1','utf8');

//Convert the json into a dynamic object
let mergedPreference = JSON.parse(basePreference);


//add windows/linux script to json
mergedPreference.inputs.shellProfile.windows = windowsScript;
mergedPreference.inputs.shellProfile.linux = linuxScript;

//write out a merged session manager preference file and ready to be deployed
fs.writeFileSync( __dirname + '/MergedSessionManagerPreferences.json', JSON.stringify(mergedPreference, null, 2));

//copy policy file into the out folder
fs.copyFileSync(__dirname + '/../scripts/Policy.json', __dirname + '/Policy.json')

console.log('Merged Session Manager Preference & Request Created and ready to be deployed');