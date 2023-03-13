const { Elm } = require('./SnapshotRunnerElm.js');
const xhr = require('./XMLHttpRequest.js');
const fs = require('fs');

global.XMLHttpRequest = xhr.XMLHttpRequest;

try {
    const apiKey = fs.readFileSync('./PERCY_TOKEN.txt').toString()

    // Original code found here https://stackoverflow.com/a/65571218
    const util = require('util');
    const exec = util.promisify(require('child_process').exec);

    async function runCommand(command) {
      const { stdout, stderr, error } = await exec(command);
      if(stderr){console.error('stderr:', stderr);}
      if(error){console.error('error:', error);}
      return stdout;
    }

    async function myFunction () {
        const command = 'git branch --show-current';
        const branch = await runCommand(command);

        const app = Elm.SnapshotRunner.init({
            flags: {
                    filepaths :
                        [ "anonymous.png"
                        , "favicon.ico"
                        , "homepage-hero.svg"
                        , "homepage-hero-dark.svg"
                        , "meetdown-logo.png"
                        ],
                    currentBranch : branch.trim(),
                    percyApiKey : apiKey.trim()
                }
            });

        app.ports.requestFile.subscribe((filepath) => {
            const buffer = fs.readFileSync("../public/" + filepath).buffer;
            app.ports.fileResponse.send(new DataView(buffer));
        });

        app.ports.writeLine.subscribe((text) => {
            console.log(text);
        });
    }

    myFunction();

}
catch {
    console.log("You need to add a PERCY_TOKEN.txt file containing your Percy API token in the same folder as SnapshotRunner.js");
}