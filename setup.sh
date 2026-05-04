#!/bin/bash
# Mault retail demo — one-time setup script
# Run once: bash setup.sh

set -e

YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

step() { echo -e "\n${YELLOW}▶ $1${NC}"; }
ok()   { echo -e "${GREEN}✓ $1${NC}"; }
fail() { echo -e "${RED}✗ $1${NC}"; exit 1; }

# ── PATH: add ~/bin and Python user bin ──────────────────────────────────────
export PATH="$HOME/bin:$HOME/Library/Python/3.9/bin:$PATH"

# ── 1. Check tools ────────────────────────────────────────────────────────────
step "Checking tools"
gh --version   >/dev/null 2>&1 || fail "gh not found — re-run setup or install manually"
pre-commit --version >/dev/null 2>&1 || fail "pre-commit not found — run: pip3 install pre-commit --user"
node --version >/dev/null 2>&1 || fail "node not found"
ok "All tools present"

# ── 2. npm install ────────────────────────────────────────────────────────────
step "Installing npm dependencies"
npm install --silent
ok "Dependencies installed"

# ── 3. GitHub auth ────────────────────────────────────────────────────────────
step "GitHub authentication"
if ! gh auth status >/dev/null 2>&1; then
  echo "You need to authenticate with GitHub. A browser window will open."
  gh auth login --web --git-protocol https
else
  ok "Already authenticated as $(gh api user -q .login)"
fi

# ── 4. Create GitHub repo ─────────────────────────────────────────────────────
step "Creating GitHub repository"
REPO_NAME="mault-retail-demo"
GH_USER=$(gh api user -q .login)

if gh repo view "$GH_USER/$REPO_NAME" >/dev/null 2>&1; then
  ok "Repo $GH_USER/$REPO_NAME already exists"
else
  gh repo create "$REPO_NAME" \
    --public \
    --description "Mault retail extension — demo project" \
    --push \
    --source=.
  ok "Created and pushed $GH_USER/$REPO_NAME"
fi

# Push if remote already set
if git remote get-url origin >/dev/null 2>&1; then
  git add package-lock.json 2>/dev/null || true
  git diff --cached --quiet || git commit -m "Add package-lock.json"
  git push -u origin main 2>/dev/null || ok "Already up to date"
else
  git remote add origin "https://github.com/$GH_USER/$REPO_NAME.git"
  git add package-lock.json 2>/dev/null || true
  git diff --cached --quiet || git commit -m "Add package-lock.json"
  git push -u origin main
fi
ok "Code pushed to github.com/$GH_USER/$REPO_NAME"

# ── 5. Branch protection ──────────────────────────────────────────────────────
step "Setting branch protection on main"
gh api \
  --method PUT \
  "repos/$GH_USER/$REPO_NAME/branches/main/protection" \
  --field 'required_status_checks={"strict":true,"contexts":["build-and-test","security-audit"]}' \
  --field 'enforce_admins=false' \
  --field 'required_pull_request_reviews={"required_approving_review_count":0,"dismiss_stale_reviews":false}' \
  --field 'restrictions=null' \
  >/dev/null 2>&1 && ok "Branch protection set on main" || echo "  (Note: branch protection requires repo to have at least one push — run after first push if this failed)"

# ── 6. Pre-commit hooks ───────────────────────────────────────────────────────
step "Installing pre-commit hooks"
pre-commit install
ok "Pre-commit hooks installed"

# ── 7. Initialise governance baselines ───────────────────────────────────────
step "Setting governance baselines"
mkdir -p .memory-layer/baselines
node scripts/governance/check-type-safety.js 2>/dev/null | head -3 || true
ok "Baselines ready"

# ── 8. Write REPO_URL for demo launcher ──────────────────────────────────────
echo "https://github.com/$GH_USER/$REPO_NAME" > .demo-repo-url
ok "Saved repo URL for demo launcher"

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  Setup complete!${NC}"
echo ""
echo "  GitHub repo:  https://github.com/$GH_USER/$REPO_NAME"
echo "  Issues:       https://github.com/$GH_USER/$REPO_NAME/issues"
echo "  Actions:      https://github.com/$GH_USER/$REPO_NAME/actions"
echo ""
echo "  → Screenshot branch protection for your pre-demo message:"
echo "    https://github.com/$GH_USER/$REPO_NAME/settings/branches"
echo ""
echo "  → When ready: bash start-demo.sh"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
