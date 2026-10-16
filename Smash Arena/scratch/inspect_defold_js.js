const fs = require('fs');

const path = 'build/default_html5/__htmlLaunchDir/Smash Arena/SmashArena_wasm.js';
const content = fs.readFileSync(path, 'utf8');

console.log('File size:', content.length);

function findMatches(pattern, contextLen = 200) {
  let idx = 0;
  let count = 0;
  while ((idx = content.indexOf(pattern, idx)) !== -1 && count < 5) {
    const start = Math.max(0, idx - 50);
    const end = Math.min(content.length, idx + contextLen);
    console.log(`\n--- Match "${pattern}" at ${idx} ---`);
    console.log(content.substring(start, end));
    idx += pattern.length;
    count++;
  }
}

console.log('Searching for AudioContext:');
findMatches('AudioContext');

console.log('\nSearching for pauseMainLoop:');
findMatches('pauseMainLoop');

console.log('\nSearching for _dmEngineSetUpdateEnabled:');
findMatches('_dmEngineSetUpdateEnabled');

console.log('\nSearching for _dmJSDeviceShared:');
findMatches('_dmJSDeviceShared');
