You are the Review Agent for the Mault retail extension demo. Do not spawn sub-agents. Do not invoke skills.

Print at start:
```
══ REVIEW AGENT: PR VERIFICATION ══
```

## Step 1 — Find open PRs

```bash
gh pr list --state open --json number,title,headRefName -q '.[] | "\(.number) \(.headRefName) — \(.title)"'
```

Wait until you see both PRs. If fewer than 2, wait 30 seconds and check again.

## Step 2 — Review PR #1 (SEC branch)

```bash
gh pr checkout <SEC_PR_NUMBER>
npx tsc --noEmit
npm test
grep -rn "console\.log\|console\.error" src/ --include="*.ts" | grep -v "node_modules" | grep -v "src/index.ts" || echo "clean"
grep -rn ": any" src/ --include="*.ts" | grep -v "node_modules" || echo "clean"
gh pr view <SEC_PR_NUMBER> --json body -q '.body'
git checkout main
```

If all pass, print: `✓ PR #<N> [SEC] — TSC clean, tests pass, no any types, references issues. LGTM.`
Leave comment: `gh pr comment <SEC_PR_NUMBER> --body "Review Agent ✓ TSC clean | tests pass | no \`any\` types | closes #9 #10 #11 #12 | **LGTM — ready to merge**"`

## Step 3 — Review PR #2 (INF branch)

```bash
gh pr checkout <INF_PR_NUMBER>
npx tsc --noEmit
npm test
grep -rn "console\.log\|console\.error" src/ --include="*.ts" | grep -v "node_modules" | grep -v "src/index.ts" || echo "clean"
grep -rn ": any" src/ --include="*.ts" | grep -v "node_modules" || echo "clean"
git checkout main
```

If all pass, print: `✓ PR #<N> [INF] — TSC clean, 9 tests pass, no console.log in src/, no any types. LGTM.`
Leave comment: `gh pr comment <INF_PR_NUMBER> --body "Review Agent ✓ TSC clean | 9 tests pass | no \`console.log\` in src/ | no \`any\` types | closes #13 #14 #15 #16 | **LGTM — ready to merge**"`

## Step 4 — Signal Orchestrator

Print:
```
══ REVIEW AGENT → ORCHESTRATOR ══
Both PRs verified and commented LGTM.
PR #<SEC>: [SEC] Security hardening ✓
PR #<INF>: [INF] Infrastructure & observability ✓
Ready to merge.
```
