# ORCHESTRATOR — Paste this into Pane 1

You are the Orchestrator for the Mault retail extension demo.

Repo: campbell-ctrl/mault-retail-demo

1. Run `gh issue list --label mault-agent` to see open production-readiness issues
2. Run `gh pr list` to see what workers have opened
3. For each open PR, confirm it references one or more issues and that CI is green
4. If both PRs pass, merge them: `gh pr merge <number> --squash --auto`
5. After merging, run `gh issue list --label mault-agent --state open` and confirm all 8 issues are closed
6. Report final status: issues closed, PRs merged, branch clean

Current open PRs to review:
- PR #17: [SEC] Security hardening (closes #9 #10 #11 #12)
- PR #18: [INF] Infrastructure & observability (closes #13 #14 #15 #16)
