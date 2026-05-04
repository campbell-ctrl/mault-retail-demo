#!/usr/bin/env node
/**
 * Coverage Ratchet — blocks commits that reduce test coverage below baseline.
 * Reads coverage/coverage-summary.json produced by `npm run test:coverage`.
 */

const fs = require('fs');
const path = require('path');

const COVERAGE_SUMMARY = path.join(__dirname, '../../coverage/coverage-summary.json');
const BASELINE_PATH = path.join(__dirname, '../../.memory-layer/baselines/coverage.json');

if (!fs.existsSync(COVERAGE_SUMMARY)) {
  console.log('✓ Coverage ratchet: no coverage report found, run npm run test:coverage first');
  process.exit(0);
}

const summary = JSON.parse(fs.readFileSync(COVERAGE_SUMMARY, 'utf8'));
const total = summary.total;
const current = {
  lines: total.lines.pct,
  statements: total.statements.pct,
  functions: total.functions.pct,
  branches: total.branches.pct,
};

function loadBaseline() {
  if (!fs.existsSync(BASELINE_PATH)) return null;
  return JSON.parse(fs.readFileSync(BASELINE_PATH, 'utf8'));
}

function saveBaseline(data) {
  const dir = path.dirname(BASELINE_PATH);
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
  fs.writeFileSync(BASELINE_PATH, JSON.stringify({ ...data, updatedAt: new Date().toISOString() }));
}

const baseline = loadBaseline();

if (baseline === null) {
  saveBaseline(current);
  console.log(`✓ Coverage baseline set:`);
  Object.entries(current).forEach(([k, v]) => console.log(`    ${k}: ${v}%`));
  process.exit(0);
}

let failed = false;
for (const metric of ['lines', 'statements', 'functions', 'branches']) {
  if (current[metric] < baseline[metric]) {
    console.error(`✗ Coverage ratchet FAILED for ${metric}: ${current[metric]}% < baseline ${baseline[metric]}%`);
    failed = true;
  } else {
    console.log(`✓ ${metric}: ${current[metric]}% (baseline: ${baseline[metric]}%)`);
  }
}

if (!failed && JSON.stringify(current) !== JSON.stringify({ lines: baseline.lines, statements: baseline.statements, functions: baseline.functions, branches: baseline.branches })) {
  saveBaseline(current);
  console.log('  Baseline updated with improved coverage.');
}

process.exit(failed ? 1 : 0);
