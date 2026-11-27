import { test } from 'node:test';
import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { mkdirSync, mkdtempSync, readFileSync, rmSync, utimesSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

test('publication replaces same-size same-time HTML while keeping cached hashed assets', () => {
  // Run the actual workflow copy commands against the worktree/build layout.
  const workflow = readFileSync(new URL('../../.github/workflows/publish-web.yml', import.meta.url), 'utf8');
  const copyCommands = workflow.split('\n').map(line => line.trim()).filter(line => /^(rsync|cmp) /.test(line));
  assert.ok(copyCommands.length > 0, 'The publication copy commands must be exercised');
  const root = mkdtempSync(join(tmpdir(), 'fidget-publish-'));
  const cwd = join(root, 'repo', 'web');
  const source = join(cwd, 'dist');
  const target = join(root, 'pages');
  const oldHTML = '<script src="./assets/old.js"></script>';
  const newHTML = '<script src="./assets/new.js"></script>';
  try {
    mkdirSync(join(source, 'assets'), { recursive: true });
    mkdirSync(join(target, 'assets'), { recursive: true });
    writeFileSync(join(source, 'index.html'), newHTML);
    writeFileSync(join(target, 'index.html'), oldHTML);
    // rsync's default quick check incorrectly treats these as identical.
    const sameTime = new Date('2026-01-01T00:00:00Z');
    for (const dir of [source, target]) utimesSync(join(dir, 'index.html'), sameTime, sameTime);
    writeFileSync(join(source, 'assets', 'new.js'), 'new build');
    writeFileSync(join(source, 'assets', 'new.css'), 'new styles');
    writeFileSync(join(target, 'assets', 'old.js'), 'cached build');
    writeFileSync(join(target, 'assets', 'old.css'), 'cached styles');
    writeFileSync(join(target, '.git'), 'keep worktree metadata');
    writeFileSync(join(target, 'retired.html'), 'remove obsolete root files');
    execFileSync('bash', ['-e', '-c', copyCommands.join('\n')], { cwd, stdio: 'pipe' });
    assert.equal(readFileSync(join(target, 'index.html'), 'utf8'), newHTML);
    assert.equal(readFileSync(join(target, 'assets', 'new.js'), 'utf8'), 'new build');
    assert.equal(readFileSync(join(target, 'assets', 'new.css'), 'utf8'), 'new styles');
    assert.equal(readFileSync(join(target, 'assets', 'old.js'), 'utf8'), 'cached build');
    assert.equal(readFileSync(join(target, 'assets', 'old.css'), 'utf8'), 'cached styles');
    assert.equal(readFileSync(join(target, '.git'), 'utf8'), 'keep worktree metadata');
    assert.throws(() => readFileSync(join(target, 'retired.html')), { code: 'ENOENT' });
  } finally { rmSync(root, { recursive: true, force: true }); }
});
