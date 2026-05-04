#!/bin/bash
# ─────────────────────────────────────────────────────────────────
#  Mault Demo Launcher — run this before every demo
#  Usage: bash start-demo.sh   (or just: demo)
# ─────────────────────────────────────────────────────────────────

export PATH="$HOME/.npm-global/bin:$HOME/bin:$HOME/Library/Python/3.9/bin:$PATH"

REPO_URL="https://github.com/campbell-ctrl/mault-retail-demo"
DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DIR"

G='\033[0;32m'; Y='\033[1;33m'; C='\033[0;36m'; B='\033[1m'; R='\033[0;31m'; N='\033[0m'
ok()   { echo -e "${G}✓  $1${N}"; }
warn() { echo -e "${Y}⚠  $1${N}"; }
hdr()  { echo -e "\n${B}$1${N}"; }

# ── Pre-flight ────────────────────────────────────────────────────
hdr "Mault Demo Pre-Flight"
echo "────────────────────────────────────────────────────────────────"

FAIL=0

# 1. Git state
BRANCH=$(git branch --show-current 2>/dev/null)
DIRTY=$(git status --porcelain 2>/dev/null)
if [ -n "$DIRTY" ]; then
  warn "Uncommitted changes on branch '$BRANCH' — stashing now..."
  git stash push -m "demo-launcher-autostash" --quiet
  ok "Changes stashed (restore after demo: git stash pop)"
else
  ok "Git: clean on branch '$BRANCH'"
fi

# 2. Dependencies
if [ ! -d "node_modules" ]; then
  warn "node_modules missing — installing..."
  npm install --silent
fi
ok "npm: dependencies ready"

# 3. TypeScript
if npx tsc --noEmit --silent 2>/dev/null; then
  ok "TypeScript: no errors"
else
  warn "TypeScript errors detected — check before going live"
  FAIL=1
fi

# 4. Tests
if npm test --silent 2>/dev/null | grep -q "passed"; then
  ok "Tests: all passing"
else
  warn "Tests not all passing — check before going live"
fi

# 5. GitHub reachable
HTTP=$(curl -s -o /dev/null -w "%{http_code}" "$REPO_URL" 2>/dev/null)
if [ "$HTTP" = "200" ]; then
  ok "GitHub: repo reachable"
else
  warn "GitHub: repo returned $HTTP — check connection"
  FAIL=1
fi

if [ "$FAIL" = "1" ]; then
  echo ""
  warn "Fix the items above before going live."
fi

# ── Open everything ───────────────────────────────────────────────
echo ""
hdr "Launching demo environment..."

# VS Code — opens with Mault Full detection pre-configured
code "$DIR" 2>/dev/null || open -a "Visual Studio Code" "$DIR" 2>/dev/null
ok "VS Code opened (Mault Full detection pre-configured)"

# GitHub Issues — filtered to mault-agent label
open "${REPO_URL}/issues?q=is%3Aopen+label%3Amault-agent+sort%3Acreated-asc" 2>/dev/null
ok "GitHub Issues tab opened (8 tasks, mault-agent label)"

# GitHub Actions — for CI visibility during PR merges
open "${REPO_URL}/actions" 2>/dev/null
ok "GitHub Actions tab opened"

# ── Instructions ──────────────────────────────────────────────────
echo ""
echo -e "${B}════════════════════════════════════════════════════════════════${N}"
echo -e "${B}  SCREEN LAYOUT  (arrange before call)${N}"
echo -e "${B}════════════════════════════════════════════════════════════════${N}"
echo ""
echo "  LEFT HALF       │  RIGHT HALF TOP"
echo "  Browser         │  Terminal 1 — Orchestrator"
echo "  GitHub Issues   │  \$ claude"
echo "  (8 tasks open)  ├─────────────────────────────"
echo "                  │  Terminal 2 — Worker A"
echo "  ────────────────┤  \$ claude"
echo "  VS CODE bottom  ├─────────────────────────────"
echo "  MAULT tab       │  Terminal 3 — Worker B"
echo "  AGENT WORKFLOWS │  \$ claude"
echo ""
echo -e "${B}════════════════════════════════════════════════════════════════${N}"
echo -e "${B}  IN VS CODE — do once after it opens:${N}"
echo -e "${B}════════════════════════════════════════════════════════════════${N}"
echo ""
echo "  1. Click the MAULT tab in the bottom panel"
echo "     → Should show 6 finding categories"
echo "     → If empty: Cmd+Shift+P → 'Mault: Refresh Panel'"
echo ""
echo "  2. Click the Mault icon in the left sidebar"
echo "     → Open AGENT WORKFLOWS panel"
echo "     → Should show: Planner / Orchestrator / Worker / Review Agent"
echo ""
echo "  3. Open CLAUDE.md in the editor (has all agent prompts)"
echo ""
echo -e "${B}════════════════════════════════════════════════════════════════${N}"
echo -e "${B}  DEMO FLOW${N}"
echo -e "${B}════════════════════════════════════════════════════════════════${N}"
echo ""
echo -e "  ${C}PART 1 — Mault Panel  (< 5 min)${N}"
echo "  • Show 6 finding categories in Mault Panel"
echo "  • Walk Production Readiness tree — Steps 1+2 done, 4-9 pending"
echo "  • Show ci.yml → Step 4 done"
echo "  • Show .pre-commit-config.yaml → Step 6 done"
echo "  • Say: 'Orchestrator reads these findings and assigns workers'"
echo ""
echo -e "  ${C}PART 2 — Agent Orchestration  (< 10 min)${N}"
echo "  • Terminal 1: claude → paste ORCHESTRATOR prompt (top of CLAUDE.md)"
echo "  • Terminal 2: claude → paste WORKER A prompt"
echo "  • Terminal 3: claude → paste WORKER B prompt"
echo "  • When PR opens → paste REVIEW AGENT prompt → approve → MERGE live"
echo ""
echo -e "  ${C}All prompts in CLAUDE.md — already open in VS Code${N}"
echo ""
echo -e "${B}════════════════════════════════════════════════════════════════${N}"
echo ""
echo "  Issues:  ${REPO_URL}/issues?q=is%3Aopen+label%3Amault-agent"
echo "  Actions: ${REPO_URL}/actions"
echo ""
echo -e "${G}${B}  Ready. You're on.${N}"
echo ""
