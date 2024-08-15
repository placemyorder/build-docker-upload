/**
 * Most of this code has been copied from the following GitHub Action
 * to make it simpler or not necessary to install a lot of
 * JavaScript packages to execute a shell script.
 *
 * https://github.com/ad-m/github-push-action/blob/fe38f0a751bf9149f0270cc1fe20bf9156854365/start.js
 */
const core = require('@actions/core');
const { execSync } = require('child_process');
const path = require("path");


const serviceName = core.getInput('serviceName');
const unittestpath = core.getInput('unittestpath');
const buildNumber = core.getInput('buildNumber');
const ecsRepoUrl = core.getInput('ecsRepoUrl');
const rununittests = core.getInput('rununittests');




const main = async () => {
    const scriptPath = path.join(__dirname, './entrypoint.sh');
    const command = `bash ${scriptPath} -s "${serviceName}" -u "${unittestpath}" -b "${buildNumber}" -e "${ecsRepoUrl}" -t "${rununittests}"`;

    const output = execSync(command,{ encoding: 'utf8' });
     // Log the output (for debugging)
     core.info('Output from bash: ' + output)
};

main().catch(err => {
    console.error(err);
    console.error(err.stack);
    process.exit(err.code || -1);
})