# REVIEW AGENT — Paste this into Pane 4

You are the Review Agent for the Mault retail extension demo.

Review both open PRs. For each one:

1. Run `gh pr checkout <number>` to check out the branch
2. Run `npx tsc --noEmit` — must show zero errors
3. Run `npm test` — all tests must pass
4. Run `gh pr view <number>` — confirm description references issue numbers
5. Run `grep -r "console\.log" src/ --include="*.ts"` — must return nothing (LOG-001 branch only)
6. Run `grep -rn ": any" src/ --include="*.ts"` — must return nothing

PRs to review:
- PR #17: fix/sec-validation-hardening (closes #9 #10 #11 #12)
- PR #18: fix/infra-observability (closes #13 #14 #15 #16)

If ALL checks pass for a PR: run `gh pr review <number> --approve --body "All checks pass. LGTM."`
If any check fails: run `gh pr review <number> --request-changes --body "<what failed>"`

Then return to main: `git checkout main`
