import { readFileSync, readdirSync } from 'node:fs';
import path from 'node:path';

// All string requires in the library are relative module paths. Validate
// them against source, including the Wally-provided sibling dependency aliases.
let resolved = 0;
const files = new Set();
function visit(dir) {
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    const file = path.join(dir, entry.name);
    if (entry.isDirectory()) visit(file);
    else if (/\.luau?$/.test(file)) files.add(path.resolve(file));
  }
}
visit('src');
const dependencies = new Set(['React', 'Promise', 'ReactRoblox'].map(name => path.resolve(name)));
const missing = [];
for (const file of files) {
  const source = readFileSync(file, 'utf8');
  for (const [, relative] of source.matchAll(/require\(["']([^"']+)["']\)/g)) {
    const target = path.resolve(path.dirname(file), relative);
    if (dependencies.has(target) || files.has(`${target}.luau`) || files.has(`${target}.lua`) || files.has(path.join(target, 'init.luau'))) resolved++;
    else missing.push(`${file}: ${relative}`);
  }
}
// Public entry-point script paths must also refer to actual modules.
for (const [, suffix] of readFileSync('src/init.luau', 'utf8').matchAll(/require\(script\.([\w.]+)\)/g)) {
  const target = path.resolve('src', ...suffix.split('.'));
  if (files.has(`${target}.luau`) || files.has(path.join(target, 'init.luau'))) resolved++;
  else missing.push(`src/init.luau: script.${suffix}`);
}
if (missing.length) throw new Error(missing.join('\n'));
console.log(`${resolved} library imports resolve, including public exports and Wally dependency aliases.`);
