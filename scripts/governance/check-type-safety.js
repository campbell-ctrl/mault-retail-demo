#!/usr/bin/env node
/**
 * Type Safety Ratchet — blocks commits that introduce new `any` types.
 * Baseline is stored in .memory-layer/baselines/type-safety.json
 */

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const BASELINE_PATH = path.join(__dirname, '../../.memory-layer/baselines/type-safety.json');
const SRC_DIR = path.join(__dirname, '../../src');

function countAnyUsages() {
  try {
    const result = execSync(
      `grep -r --include="*.ts" -c ": any" "${SRC_DIR}" | awk -F: '{sum+=$2} END {print sum}'`,
      { encoding: 'utf8', stdio: ['pipe', 'pipe', 'pipe'] }
    ).trim();
    return parseInt(result) || 0;
  } catch {
    return 0;
  }
}

function loadBaseline() {
  if (!fs.existsSync(BASELINE_PATH)) return null;
  return JSON.parse(fs.readFileSync(BASELINE_PATH, 'utf8'));
}

function saveBaseline(count) {
  const dir = path.dirname(BASELINE_PATH);
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
  fs.writeFileSync(BASELINE_PATH, JSON.stringify({ anyCount: count, updatedAt: new Date().toISOString() }));
}

const current = countAnyUsages();
const baseline = loadBaseline();

if (baseline === null) {
  saveBaseline(current);
  console.log(`✓ Type safety baseline set: ${current} \`any\` usages`);
  process.exit(0);
}

if (current > baseline.anyCount) {
  console.error(`✗ Type safety gate FAILED`);
  console.error(`  Baseline: ${baseline.anyCount} \`any\` usages`);
  console.error(`  Current:  ${current} \`any\` usages`);
  console.error(`  New holes: ${current - baseline.anyCount}`);
  console.error(`  Fix: replace new \`any\` types with proper TypeScript types`);
  process.exit(1);
}

console.log(`✓ Type safety gate passed (${current}/${baseline.anyCount} \`any\` usages)`);
process.exit(0);
