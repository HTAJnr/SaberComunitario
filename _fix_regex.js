const fs = require('fs');
let c = fs.readFileSync('./backend/routes/funcionarios.js', 'utf8');
const lines = c.split('\n');
// Replace line index 8 (line 9) with correct unicode escape
lines[8] = "  const partes = nome.normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase().split(/\\s+/).filter(Boolean);";
fs.writeFileSync('./backend/routes/funcionarios.js', lines.join('\n'), 'utf8');
console.log('done:', JSON.stringify(lines[8]));
