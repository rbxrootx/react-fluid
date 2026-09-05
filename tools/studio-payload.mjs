import { readFileSync, readdirSync } from 'node:fs';
import path from 'node:path';

const entries = [];
function visit(directory, relative = '') {
  for (const entry of readdirSync(directory, { withFileTypes: true })) {
    const filename = path.join(directory, entry.name);
    const key = relative ? `${relative}/${entry.name}` : entry.name;
    if (entry.isDirectory()) visit(filename, key);
    else if (entry.name.endsWith('.luau')) entries.push({ path: key, source: readFileSync(filename, 'utf8') });
  }
}
visit('src');
console.log(JSON.stringify({ entries, client: readFileSync('tests/studio.client.luau', 'utf8') }));
