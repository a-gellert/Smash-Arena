const fs = require('fs');

function checkLua(filePath) {
  const content = fs.readFileSync(filePath, 'utf8');
  const lines = content.split('\n');

  let inLongString = false;
  let inLongComment = false;
  const stack = [];

  for (let i = 0; i < lines.length; i++) {
    let line = lines[i];
    const lineNum = i + 1;

    let code = '';
    let j = 0;
    while (j < line.length) {
      if (inLongComment) {
        const idx = line.indexOf(']]', j);
        if (idx === -1) { j = line.length; } else { inLongComment = false; j = idx + 2; }
        continue;
      }
      if (inLongString) {
        const idx = line.indexOf(']]', j);
        if (idx === -1) { j = line.length; } else { inLongString = false; j = idx + 2; }
        continue;
      }

      if (line.substr(j, 4) === '--[[') {
        inLongComment = true;
        j += 4;
        continue;
      }
      if (line.substr(j, 2) === '--') {
        break; // rest is comment
      }
      if (line.substr(j, 2) === '[[') {
        inLongString = true;
        j += 2;
        continue;
      }

      if (line[j] === '"' || line[j] === "'") {
        const quote = line[j];
        j++;
        while (j < line.length && line[j] !== quote) {
          if (line[j] === '\\') j++;
          j++;
        }
        j++;
        continue;
      }

      code += line[j];
      j++;
    }

    // Now tokenize words in code
    const words = code.match(/[a-zA-Z_0-9]+/g);
    if (!words) continue;

    for (let w = 0; w < words.length; w++) {
      const word = words[w];
      if (word === 'function') {
        stack.push({ type: 'function', line: lineNum });
      } else if (word === 'if') {
        stack.push({ type: 'if', line: lineNum });
      } else if (word === 'do') {
        // 'for ... do' or 'while ... do' or standalone 'do'
        stack.push({ type: 'do', line: lineNum });
      } else if (word === 'repeat') {
        stack.push({ type: 'repeat', line: lineNum });
      } else if (word === 'until') {
        if (stack.length === 0) {
          console.error(`Unexpected 'until' at line ${lineNum}`);
        } else {
          const top = stack.pop();
          if (top.type !== 'repeat') {
            console.error(`Mismatched 'until' at line ${lineNum}, expected repeat but got ${top.type} from line ${top.line}`);
          }
        }
      } else if (word === 'end') {
        if (stack.length === 0) {
          console.error(`Unexpected 'end' at line ${lineNum}`);
        } else {
          const top = stack.pop();
          if (top.type === 'repeat') {
            console.error(`Mismatched 'end' at line ${lineNum}, expected until for repeat from line ${top.line}`);
          }
        }
      }
    }
  }

  if (stack.length > 0) {
    console.error(`❌ Unclosed blocks in ${filePath}:`, stack);
    return false;
  }
  console.log(`✅ ${filePath} is 100% balanced! (${lines.length} lines)`);
  return true;
}

checkLua('main/sdk.lua');
checkLua('main/game.gui_script');
checkLua('main/state.lua');
