You are the Orchestrator for the Mault retail extension demo. Work in the repo at the current directory.

## Step 1 — Verify demo state

Run `bash demo-reset.sh` to restore all intentional gaps and reopen issues. Wait for it to complete.

Then confirm:
- `gh issue list --label mault-agent --state open` shows 8 open issues
- `ls src/legacy/` shows `old-product-helpers.ts` exists
- `ls src/middleware/auth.ts` returns "No such file"
- `ls src/utils/logger.ts` returns "No such file"

## Step 2 — Spawn Worker A and Worker B in parallel

Use the Agent tool to launch BOTH workers at the same time (single message, two Agent calls).

**Worker A prompt** (security branch `fix/sec-validation-hardening`):
```
You are Worker Agent A for the Mault retail extension demo. Work in the repo at the current directory.

Do ALL of these on one branch called fix/sec-validation-hardening:

1. git checkout -b fix/sec-validation-hardening
2. npm install (helmet and express-rate-limit are already in package.json — just run install)

SEC-001 — src/routes/products.ts: add express-validator. Import body and validationResult. On POST /, add validators: body('name').notEmpty(), body('price').isFloat({min:0}), body('sku').notEmpty(). Return 422 with errors.array() if validation fails.

SEC-002 — Create src/middleware/auth.ts: export function requireAuth(req,res,next) that checks for Authorization header starting with "Bearer ", returns 401 if missing, calls next() if present. Apply requireAuth to POST /adjust in src/routes/inventory.ts and POST / in src/routes/checkout.ts.

SEC-003 — src/index.ts: import helmet from 'helmet' and add app.use(helmet()) before app.use(express.json()).

INF-002 — src/index.ts: import rateLimit from 'express-rate-limit'. Create apiLimiter with windowMs:15*60*1000, max:100, standardHeaders:true, legacyHeaders:false. Apply it: app.use('/api/products', apiLimiter, productRoutes).

After all changes:
- Run: npx tsc --noEmit (fix any errors before continuing)
- Run: npm test (fix any failures before continuing)
- Run: git add src/middleware/auth.ts src/routes/products.ts src/routes/inventory.ts src/routes/checkout.ts src/index.ts
- Run: git commit -m "[SEC] Security hardening: validation, auth, helmet, rate-limit (#9 #10 #11 #12)"
- Run: git push -u origin fix/sec-validation-hardening
- Run: gh pr create --title "[SEC] Security hardening: validation, auth, helmet, rate-limit (#9 #10 #11 #12)" --body "Closes #9, #10, #11, #12\n\n- SEC-001: express-validator on POST /api/products\n- SEC-002: requireAuth middleware on /api/inventory/adjust and /api/checkout\n- SEC-003: helmet() security headers\n- INF-002: express-rate-limit on /api/products"

Report back the PR URL when done.
```

**Worker B prompt** (infra branch `fix/infra-observability`):
```
You are Worker Agent B for the Mault retail extension demo. Work in the repo at the current directory.

Do ALL of these on one branch called fix/infra-observability:

1. git checkout -b fix/infra-observability

INF-001 — src/index.ts: Add this route before app.use('/api/products',...):
  app.get('/api/health', (_req, res) => { res.json({ status: 'ok', uptime: process.uptime(), timestamp: new Date().toISOString() }); });

LOG-001 — Create src/utils/logger.ts:
  type LogLevel = 'info'|'warn'|'error';
  function log(level: LogLevel, msg: string, meta?: object): void {
    const entry = JSON.stringify({ level, msg, ...(meta ? { meta } : {}), ts: new Date().toISOString() });
    if (level === 'error') { process.stderr.write(entry + '\n'); } else { process.stdout.write(entry + '\n'); }
  }
  export const logger = { info: (msg:string,meta?:object)=>log('info',msg,meta), warn: (msg:string,meta?:object)=>log('warn',msg,meta), error: (msg:string,meta?:object)=>log('error',msg,meta) };

Then replace console.log/console.error:
- src/index.ts: import logger, change console.log to logger.info
- src/routes/inventory.ts: import logger, change console.log to logger.info('Inventory adjusted', { reason, productId, adjustment })
- src/middleware/error-handler.ts: import logger, change console.error to logger.error(err.message, { stack: err.stack })

TST-001 — Create tests/unit/order-service.test.ts with jest tests covering createOrder (success, not-found error, insufficient-stock error) and updateOrderStatus (unknown id returns null, happy path). Read src/services/order-service.ts first to understand the real API.

ARCH-001 — Delete src/legacy/ (confirm no imports point to it first with: grep -r "legacy" src/ --include="*.ts")

After all changes:
- Run: npx tsc --noEmit (fix any errors)
- Run: npm test (fix any failures)
- Run: git add src/utils/logger.ts src/index.ts src/routes/inventory.ts src/middleware/error-handler.ts tests/unit/order-service.test.ts && git rm -r src/legacy/
- Run: git commit -m "[INF] Infrastructure & observability: health, logging, tests, arch cleanup (#13 #14 #15 #16)"
- Run: git push -u origin fix/infra-observability
- Run: gh pr create --title "[INF] Infrastructure & observability: health, logging, tests, arch cleanup (#13 #14 #15 #16)" --body "Closes #13, #14, #15, #16\n\n- INF-001: GET /api/health endpoint\n- LOG-001: src/utils/logger.ts, replaced all console.log/error\n- TST-001: tests/unit/order-service.test.ts (createOrder + updateOrderStatus)\n- ARCH-001: deleted src/legacy/"

Report back the PR URL when done.
```

## Step 3 — Wait for both workers, then review

After both agents complete, for each PR:

1. `gh pr checkout <number>`
2. `npx tsc --noEmit` — must be clean
3. `npm test` — must pass
4. Leave a comment: `gh pr comment <number> --body "Review Agent: TSC clean ✓ | tests pass ✓ | LGTM"`
5. `gh pr merge <number> --squash --admin --delete-branch`
6. `git checkout main && git pull`

If PR #17 merges cleanly, rebase PR #18 onto main before merging to resolve any conflicts.

## Step 4 — Close issues and report

```
gh issue close 9 10 11 12 13 14 15 16 --comment "Fixed and merged."
```

Print a final summary:
- Issues #9–16: closed ✓
- PR #17 [SEC]: merged ✓
- PR #18 [INF]: merged ✓
- Tests passing: X/X ✓
