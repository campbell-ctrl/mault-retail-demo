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

# ── Open browser tabs ─────────────────────────────────────────────────────────
echo -e "${YELLOW}▶ Opening browser tabs...${NC}"
open "$REPO_URL/issues" 2>/dev/null || true
open "$REPO_URL/actions" 2>/dev/null || true
echo -e "${GREEN}✓  GitHub Issues + Actions tabs opened${NC}"

# ── Open VS Code ──────────────────────────────────────────────────────────────
echo -e "${YELLOW}▶ Opening VS Code...${NC}"
code . 2>/dev/null || open -a "Visual Studio Code" . 2>/dev/null || echo "  Open VS Code manually and open this folder"
echo -e "${GREEN}✓  VS Code launched${NC}"

# ── Print demo agenda ─────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}  DEMO AGENDA${NC}"
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  ${CYAN}PART 1 — Production Readiness (< 5 min)${NC}"
echo "  1. Show Mault Panel sidebar (VS Code) — 8 findings detected"
echo "  2. Walk Production Readiness tree view — Steps 4-9 unlocked"
echo "  3. Show .pre-commit-config.yaml and ci.yml as proof artifacts"
echo "  4. Transition: 'Now the orchestrator picks this up'"
echo ""
echo -e "  ${CYAN}PART 2 — Multi-Agent Orchestration (< 10 min)${NC}"
echo "  5. Terminal 1 (Orchestrator): run 'claude', paste ORCHESTRATOR prompt"
echo "  6. Watch GitHub Issues tab — 8 issues appear live"
echo "  7. Terminal 2 (Worker A): run 'claude', paste WORKER A prompt"
echo "  8. Terminal 3 (Worker B): run 'claude', paste WORKER B prompt"
echo "  9. When Worker A opens PR: paste REVIEW AGENT prompt, approve, MERGE"
echo ""
echo -e "  ${CYAN}Prompts are in: CLAUDE.md${NC}"
echo ""
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "  Issues tab: $REPO_URL/issues"
echo "  Actions:    $REPO_URL/actions"
echo "  Settings:   $REPO_URL/settings/branches  ← screenshot for pre-demo message"
echo ""
echo -e "${BOLD}  Good luck.${NC}"
echo ""
