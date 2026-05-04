#!/bin/bash
# ─────────────────────────────────────────────────────────────────
#  Mault Demo Launcher — run this before every demo
#  Usage:  bash start-demo.sh   OR just type:  demo
# ─────────────────────────────────────────────────────────────────

export PATH="$HOME/.npm-global/bin:$HOME/bin:$HOME/Library/Python/3.9/bin:$PATH"

REPO_URL="https://github.com/campbell-ctrl/mault-retail-demo"
DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DIR"

G='\033[0;32m'; Y='\033[1;33m'; C='\033[0;36m'; B='\033[1m'; N='\033[0m'
ok()   { echo -e "${G}✓  $1${N}"; }
warn() { echo -e "${Y}⚠  $1${N}"; }
hdr()  { echo -e "\n${B}$1${N}"; }

# ── Pre-flight ────────────────────────────────────────────────────
hdr "Mault Demo Pre-Flight"
echo "────────────────────────────────────────────────────────────────"

# Git: auto-stash if dirty
DIRTY=$(git status --porcelain 2>/dev/null)
if [ -n "$DIRTY" ]; then
  git stash push -m "demo-autostash" --quiet
  warn "Changes stashed (restore after: git stash pop)"
else
  ok "Git: clean on $(git branch --show-current)"
fi

# Dependencies
[ ! -d "node_modules" ] && npm install --silent
ok "npm: dependencies ready"

# TypeScript
npx tsc --noEmit --silent 2>/dev/null && ok "TypeScript: clean" || warn "TypeScript errors — check before going live"

# Tests
npm test --silent 2>/dev/null | grep -q "passed" && ok "Tests: passing" || warn "Tests not all passing"

# ── Launch VS Code with everything pre-opened ─────────────────────
hdr "Opening VS Code..."

# Open VS Code pointing at this folder
code "$DIR" 2>/dev/null || open -a "Visual Studio Code" "$DIR"
sleep 3

# Use VS Code CLI to open files as editor tabs
# Tab 1: GitHub Issues via Simple Browser (left side — matches screenshot)
code --goto "$DIR" 2>/dev/null

# Open CLAUDE.md as an editor tab (agent prompts reference)
code "$DIR/CLAUDE.md" 2>/dev/null

ok "VS Code opened"

# ── Open GitHub Issues in browser (fallback view) ─────────────────
open "${REPO_URL}/issues?q=is%3Aopen+label%3Amault-agent+sort%3Acreated-asc" 2>/dev/null
ok "GitHub Issues opened in browser"

# ── Print setup steps ─────────────────────────────────────────────
echo ""
echo -e "${B}════════════════════════════════════════════════════════════════${N}"
echo -e "${B}  FINISH SETUP IN VS CODE (takes 60 seconds)${N}"
echo -e "${B}════════════════════════════════════════════════════════════════${N}"
echo ""
echo -e "  ${C}Step 1 — Open GitHub Issues inside VS Code${N}"
echo "  Cmd+Shift+P → type: Simple Browser"
echo "  → Click 'Simple Browser: Show'"
echo "  → Paste this URL:"
echo "    ${REPO_URL}/issues?q=is%3Aopen+label%3Amault-agent"
echo "  → Drag the Simple Browser tab to the LEFT half of the editor"
echo ""
echo -e "  ${C}Step 2 — Open the Mault bottom panel${N}"
echo "  Click the MAULT tab at the bottom of VS Code"
echo "  Should show: Monolith Violations, Environment Issues, etc."
echo "  If empty → Cmd+Shift+P → 'Mault: Refresh Panel'"
echo ""
echo -e "  ${C}Step 3 — Open Agent Workflows sidebar${N}"
echo "  Click the Mault icon in the left sidebar"
echo "  → AGENT WORKFLOWS panel should show Planner / Orchestrator / Worker"
echo ""
echo -e "  ${C}Step 4 — Open 3 integrated terminals (Ctrl+\`)${N}"
echo "  Terminal 1: type  claude  → this becomes the Orchestrator tab"
echo "  Ctrl+\` again → terminal 2: type  claude  → Worker A tab"
echo "  Ctrl+\` again → terminal 3: type  claude  → Worker B tab"
echo "  Each 'claude' opens as a new editor tab at the top"
echo ""
echo -e "${B}════════════════════════════════════════════════════════════════${N}"
echo -e "${B}  DEMO FLOW — once layout is set${N}"
echo -e "${B}════════════════════════════════════════════════════════════════${N}"
echo ""
echo -e "  ${C}PART 1 — Mault Panel walkthrough  (< 5 min)${N}"
echo "  • Point to Mault Panel — 6 finding categories visible"
echo "  • Show Production Readiness tree — Steps 1+2 done, 4-9 pending"
echo "  • Click ci.yml tab → 'Step 4 done — CI wired'"
echo "  • Click .pre-commit-config.yaml → 'Step 6 done — 5-layer enforcement'"
echo "  • Say: 'Orchestrator reads these findings, creates issues, assigns workers'"
echo ""
echo -e "  ${C}PART 2 — Agent Orchestration  (< 10 min)${N}"
echo "  • Click Orchestrator tab → paste ORCHESTRATOR prompt from CLAUDE.md"
echo "  • Watch GitHub Issues tab — 8 tasks appear (already pre-created)"
echo "  • Click Worker A tab → paste WORKER A prompt"
echo "  • Click Worker B tab → paste WORKER B prompt"
echo "  • When PR opens → click Review Agent tab → paste REVIEW prompt → MERGE"
echo ""
echo "  Issues: ${REPO_URL}/issues?q=is%3Aopen+label%3Amault-agent"
echo ""
echo -e "${G}${B}  Ready. You're on.${N}"
echo ""
