# Mault Retail Extension — Agent Orchestration Guide

This file instructs Claude Code agents working in this repository.

## Project Overview

TypeScript/Express retail loyalty and inventory API. The Mault VS Code extension enforces architectural rules defined in `docs/mault.yaml`. All agents must respect those rules — violations block commits.

## Agent Roles

### Orchestrator
The orchestrator reads the Mault Panel findings and the Production Readiness Kit status, then:
1. Creates a GitHub Issue for each production-readiness gap
2. Assigns each issue to a worker agent
3. Reviews PRs before merging

**Orchestrator prompt (paste into Claude Code):**
```
You are the orchestrator for the Mault retail extension demo.

1. Run: `npx tsc --noEmit` and note all type errors
2. Read the production readiness gaps listed below and create a GitHub Issue for each one
3. Spawn two worker agents in parallel: Worker A handles security/validation gaps, Worker B handles infrastructure gaps
4. After each worker opens a PR, invoke the review agent to check it
5. Merge PRs that pass review

Production readiness gaps to issue:
- [SEC-001] No input validation on POST /api/products (express-validator required)
- [SEC-002] No auth middleware on POST /api/inventory/adjust and POST /api/checkout
- [SEC-003] No security headers (add helmet middleware)
- [INF-001] No health check endpoint GET /api/health
- [INF-002] No rate limiting on public endpoints
- [LOG-001] console.log used instead of structured logging
- [TST-001] Missing test coverage for order-service.ts
- [ARCH-001] Dead-end directory src/legacy/ — archive or delete
```

### Worker Agent A — Security & Validation
**Focus:** SEC-001, SEC-002, SEC-003, INF-002

Run this prompt in a second Claude Code terminal:
```
You are Worker Agent A for the Mault retail extension.

Your assigned issues: SEC-001, SEC-002, SEC-003, INF-002.

For each issue:
1. Create a branch: `fix/issue-<number>-<slug>`
2. Make the fix
3. Run `npm test` — all tests must pass
4. Run `npx tsc --noEmit` — no type errors
5. Open a PR with a clear description referencing the issue number

SEC-001: Add express-validator to POST /api/products route
SEC-002: Create src/middleware/auth.ts and apply to /api/inventory/adjust and /api/checkout
SEC-003: Install helmet, add app.use(helmet()) in src/index.ts
INF-002: Install express-rate-limit, apply to /api/products router

Do all four on one branch: fix/sec-validation-hardening
```

### Worker Agent B — Infrastructure & Tests
**Focus:** INF-001, LOG-001, TST-001, ARCH-001

Run this prompt in a third Claude Code terminal:
```
You are Worker Agent B for the Mault retail extension.

Your assigned issues: INF-001, LOG-001, TST-001, ARCH-001.

For each issue:
1. Create a branch: `fix/infra-observability`
2. Make the fix
3. Run `npm test` — all tests must pass
4. Open a PR referencing the issue numbers

INF-001: Add GET /api/health endpoint in src/index.ts returning { status: 'ok', uptime, timestamp }
LOG-001: Replace console.log/console.error with structured calls (use a simple logger wrapper at src/utils/logger.ts)
TST-001: Add tests/unit/order-service.test.ts covering createOrder and updateOrderStatus
ARCH-001: Delete src/legacy/ — it is a dead-end directory with no imports pointing to it
```

### Review Agent
**Focus:** Verify PRs before merge

Run this prompt after each worker opens a PR:
```
You are the review agent for the Mault retail extension.

Review the open PR. Check:
1. `npm test` passes (no failing tests)
2. `npx tsc --noEmit` passes (no type errors)
3. The Mault Panel shows zero new violations introduced by the changes
4. The PR description references the issue it closes
5. No console.log statements added
6. No `any` types added

If all checks pass: approve the PR.
If any check fails: leave a review comment describing what needs to change, do NOT approve.
```

## Branch & PR Conventions

| Branch pattern | Purpose |
|---|---|
| `fix/sec-*` | Security and validation fixes |
| `fix/infra-*` | Infrastructure and observability |
| `fix/test-*` | Test coverage improvements |
| `chore/arch-*` | Architecture cleanup |

PR titles must follow: `[TYPE] Short description (#issue-number)`

## Rules (Physics, Not Policy)

These are enforced by pre-commit hooks — agents cannot bypass them:

1. **No commit passes with TypeScript errors** (`tsc --noEmit` in pre-commit)
2. **No commit passes with failing tests** (`npm test` in pre-commit)
3. **No new `any` types** — type safety ratchet
4. **No new `console.log`** — use `src/utils/logger.ts`
5. **Files must be in correct directories** — Mault enforces via `docs/mault.yaml`

## File Map

```
src/
  index.ts          — app entrypoint, express setup
  routes/           — HTTP handlers (thin, delegates to services)
  services/         — business logic
  models/           — TypeScript interfaces/types
  middleware/       — express middleware
  utils/            — shared utilities (logger goes here)
tests/
  unit/             — unit tests (jest)
  integration/      — integration tests with supertest
docs/
  mault.yaml        — Mault rulebook (DO NOT modify without discussion)
```
