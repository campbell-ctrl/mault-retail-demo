#!/usr/bin/env node
/**
 * Mock Tax (Rising Tide) — The 2x Rule.
 * If a test file is more than 2x the size of the source file it tests, fail.
 */

const fs = require('fs');
const path = require('path');

const TESTS_DIR = path.join(__dirname, '../../tests/unit');
const SRC_DIR = path.join(__dirname, '../../src');

function linesInFile(filePath) {
  if (!fs.existsSync(filePath)) return 0;
  return fs.readFileSync(filePath, 'utf8').split('\n').length;
}

function findSourceFile(testFile) {
  const name = path.basename(testFile, '.test.ts');
  const candidates = [
    path.join(SRC_DIR, 'services', `${name}.ts`),
    path.join(SRC_DIR, 'routes', `${name}.ts`),
    path.join(SRC_DIR, 'middleware', `${name}.ts`),
    path.join(SRC_DIR, `${name}.ts`),
  ];
  return candidates.find(fs.existsSync) || null;
}

if (!fs.existsSync(TESTS_DIR)) {
  console.log('✓ Mock tax: no unit tests directory found, skipping');
  process.exit(0);
}

let failed = false;
const testFiles = fs.readdirSync(TESTS_DIR).filter(f => f.endsWith('.test.ts'));

for (const testFile of testFiles) {
  const testPath = path.join(TESTS_DIR, testFile);
  const srcPath = findSourceFile(testFile);
  if (!srcPath) continue;

  const testLines = linesInFile(testPath);
  const srcLines = linesInFile(srcPath);
  if (srcLines === 0) continue;

  const ratio = testLines / srcLines;
  if (ratio > 2.0) {
    console.error(`✗ Mock tax EXCEEDED: ${testFile}`);
    console.error(`  Source: ${srcLines} lines | Test: ${testLines} lines | Ratio: ${ratio.toFixed(1)}x`);
    console.error(`  Action: Delete unit test and rewrite as integration test`);
    failed = true;
  } else {
    console.log(`✓ ${testFile}: ${ratio.toFixed(1)}x ratio (${testLines}/${srcLines} lines)`);
  }
}

process.exit(failed ? 1 : 0);
