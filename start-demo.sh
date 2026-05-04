#!/bin/bash
# Mault retail demo — launch script
# Run before every demo: bash start-demo.sh

export PATH="$HOME/bin:$HOME/Library/Python/3.9/bin:$PATH"

YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

REPO_URL=$(cat .demo-repo-url 2>/dev/null || echo "https://github.com/YOUR_USERNAME/mault-retail-demo")
GH_USER=$(echo "$REPO_URL" | sed 's|https://github.com/||' | cut -d'/' -f1)
REPO_NAME=$(echo "$REPO_URL" | sed 's|https://github.com/||' | cut -d'/' -f2)

# ── Pre-flight checks ─────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}Mault Demo Pre-Flight${NC}"
echo "──────────────────────────────────────────────"

FAIL=0

# Git state
if [ -n "$(git status --porcelain)" ]; then
  echo -e "${YELLOW}⚠  Uncommitted changes — stash or commit before demo${NC}"
  FAIL=1
else
  echo -e "${GREEN}✓  Git: clean state on $(git branch --show-current)${NC}"
fi

# npm deps
if [ ! -d "node_modules" ]; then
  echo -e "${YELLOW}⚠  node_modules missing — running npm install...${NC}"
  npm install --silent
fi
echo -e "${GREEN}✓  npm: dependencies installed${NC}"

# TypeScript
if npx tsc --noEmit >/dev/null 2>&1; then
  echo -e "${GREEN}✓  TypeScript: no errors${NC}"
else
  echo -e "${YELLOW}⚠  TypeScript errors — fix before demo${NC}"
  FAIL=1
fi

# Tests
if npm test --silent >/dev/null 2>&1; then
  echo -e "${GREEN}✓  Tests: passing${NC}"
else
  echo -e "${YELLOW}⚠  Tests failing — fix before demo${NC}"
  FAIL=1
fi

# GitHub reachability
if curl -s "https://api.github.com/repos/$GH_USER/$REPO_NAME" | python3 -c "import sys,json; r=json.load(sys.stdin); exit(0 if r.get('name') else 1)" 2>/dev/null; then
  echo -e "${GREEN}✓  GitHub: $REPO_URL reachable${NC}"
else
  echo -e "${YELLOW}⚠  GitHub: repo not reachable — check auth or run setup.sh${NC}"
  FAIL=1
fi

echo ""

if [ "$FAIL" = "1" ]; then
  echo -e "${YELLOW}Fix the issues above before going live.${NC}"
  echo ""
fi

# ── Open VS Code first (loads Mault panel) ───────────────────────────────────
echo -e "${YELLOW}▶ Opening VS Code with retail-extension...${NC}"
code . 2>/dev/null || open -a "Visual Studio Code" . 2>/dev/null || echo "  Open VS Code manually"
sleep 2
echo -e "${GREEN}✓  VS Code launched — Mault Panel loading${NC}"

# ── Open browser: Issues tab (left side of screen per demo layout) ────────────
echo -e "${YELLOW}▶ Opening GitHub Issues tab...${NC}"
open "$REPO_URL/issues?q=is%3Aopen+label%3Amault-agent" 2>/dev/null || true
sleep 1
# Also open Actions for CI visibility
open "$REPO_URL/actions" 2>/dev/null || true
echo -e "${GREEN}✓  GitHub Issues + Actions opened${NC}"

# ── Print screen layout instructions ─────────────────────────────────────────
echo ""
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}  ARRANGE YOUR SCREEN — match this layout:${NC}"
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "  ┌─────────────────────────────┬───────────────────────────────┐"
echo "  │  BROWSER (left half)        │  TERMINAL — Orchestrator      │"
echo "  │  GitHub Issues              │  \$ claude                     │"
echo "  │  ?q=is:open+label:mault-agent│  > paste orchestrator prompt  │"
echo "  │                             ├───────────────────────────────┤"
echo "  │                             │  TERMINAL — Worker A          │"
echo "  │                             │  \$ claude > paste Worker A    │"
echo "  ├─────────────────────────────┴───────────────────────────────┤"
echo "  │  VS CODE — bottom panels                                    │"
echo "  │  [MAULT tab: findings]       [AGENT WORKFLOWS sidebar]      │"
echo "  │   Monolith Violations (4)     Semi-Autonomous:              │"
echo "  │   Environment Issues (2)       Step 1: Planner              │"
echo "  │   Drift Detection (2)          Step 2: Orchestrator         │"
echo "  │   Directory Placement (1)      Step 3: Worker (Active)      │"
echo "  │   Config Chaos (1)             Step 4: Review Agent         │"
echo "  │   Naming Violations (1)        Step 5: Tester               │"
echo "  └─────────────────────────────────────────────────────────────┘"
echo ""
echo -e "${BOLD}  IN VS CODE — do this now:${NC}"
echo "  1. Cmd+Shift+P → 'Mault: Set Detection Level' → Full (3)"
echo "  2. Cmd+Shift+P → 'Mault: Refresh Panel'  (should show 6+ categories)"
echo "  3. Open AGENT WORKFLOWS panel in the sidebar (Mault icon)"
echo "  4. Click the MAULT tab in the bottom panel"
echo ""
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}  DEMO FLOW${NC}"
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  ${CYAN}PART 1 — Mault Panel walkthrough (< 5 min)${NC}"
echo "  1. Point to Mault Panel — 8 findings across 6 categories"
echo "  2. Walk Production Readiness tree — Steps 1+2 done, 4-9 pending"
echo "  3. Show ci.yml (Step 4) and .pre-commit-config.yaml (Step 6)"
echo "  4. Transition: 'The orchestrator reads this and creates the issues'"
echo ""
echo -e "  ${CYAN}PART 2 — Agent Workflows (< 10 min)${NC}"
echo "  5. Orchestrator terminal: 'claude' → paste ORCHESTRATOR prompt → issues appear"
echo "  6. Worker A terminal: 'claude' → paste WORKER A prompt"
echo "  7. Worker B terminal: 'claude' → paste WORKER B prompt"
echo "  8. Review Agent: paste prompt when Worker A opens PR → approve → MERGE"
echo ""
echo -e "  ${CYAN}All prompts: open CLAUDE.md in VS Code editor${NC}"
echo ""
echo "  Issues:   $REPO_URL/issues?q=is%3Aopen+label%3Amault-agent"
echo "  Actions:  $REPO_URL/actions"
echo "  Settings: $REPO_URL/settings/branches"
echo ""
echo -e "${BOLD}  You're live.${NC}"
echo ""
