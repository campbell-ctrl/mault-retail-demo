You are the Orchestrator for the Mault retail extension demo. The working directory is the repo root. Do all steps below in order. Use Bash, Read, Edit, and Write tools directly — do not spawn sub-agents, do not invoke skills.

---

## PHASE 1 — Confirm demo state

Run: `gh issue list --label mault-agent --state open --json number,title -q '.[] | "\(.number) \(.title)"'`

If fewer than 8 issues are open, run `bash demo-reset.sh` and wait for it to finish.

Confirm:
- `ls src/legacy/` → old-product-helpers.ts exists
- `ls src/middleware/auth.ts` → "No such file" (expected)
- `ls src/utils/logger.ts` → "No such file" (expected)

---

## PHASE 2 — Worker A: Security & Validation (branch fix/sec-validation-hardening)

```bash
git checkout main
git checkout -b fix/sec-validation-hardening
```

**SEC-001** — `src/routes/products.ts`: add express-validator on POST /

Replace the file with:
```typescript
import { Router, Request, Response } from 'express';
import { body, validationResult } from 'express-validator';
import { getAllProducts, getProductById, createProduct } from '../services/product-service';

const router = Router();

router.get('/', (_req: Request, res: Response) => {
  const products = getAllProducts();
  res.json({ data: products, count: products.length });
});

router.get('/:id', (req: Request, res: Response) => {
  const product = getProductById(req.params.id);
  if (!product) return res.status(404).json({ error: 'Product not found' });
  res.json({ data: product });
});

router.post(
  '/',
  body('name').notEmpty().withMessage('name is required'),
  body('price').isFloat({ min: 0 }).withMessage('price must be a non-negative number'),
  body('sku').notEmpty().withMessage('sku is required'),
  (req: Request, res: Response) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return res.status(422).json({ errors: errors.array() });
    const product = createProduct(req.body);
    res.status(201).json({ data: product });
  }
);

export default router;
```

**SEC-002** — Create `src/middleware/auth.ts`:
```typescript
import { Request, Response, NextFunction } from 'express';

export function requireAuth(req: Request, res: Response, next: NextFunction): void {
  const header = req.headers.authorization;
  if (!header || !header.startsWith('Bearer ')) {
    res.status(401).json({ error: 'Unauthorized' });
    return;
  }
  next();
}
```

Update `src/routes/inventory.ts` — add `import { requireAuth } from '../middleware/auth';` and change `router.post('/adjust', (req` to `router.post('/adjust', requireAuth, (req`.

Update `src/routes/checkout.ts` — add `import { requireAuth } from '../middleware/auth';` and change `router.post('/', (req` to `router.post('/', requireAuth, (req`.

**SEC-003 + INF-002** — `src/index.ts`: add helmet and rate limiting.

Replace the file with:
```typescript
import express from 'express';
import dotenv from 'dotenv';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import productRoutes from './routes/products';
import inventoryRoutes from './routes/inventory';
import checkoutRoutes from './routes/checkout';
import orderRoutes from './routes/orders';
import { errorHandler } from './middleware/error-handler';
import { seedProducts } from './services/product-service';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

app.use(helmet());
app.use(express.json());

const apiLimiter = rateLimit({ windowMs: 15 * 60 * 1000, max: 100, standardHeaders: true, legacyHeaders: false });

app.use('/api/products', apiLimiter, productRoutes);
app.use('/api/inventory', inventoryRoutes);
app.use('/api/checkout', checkoutRoutes);
app.use('/api/orders', orderRoutes);

app.use(errorHandler);
seedProducts();

app.listen(PORT, () => { console.log(`Retail extension running on port ${PORT}`); });

export default app;
```

**Verify Worker A:**
```bash
npx tsc --noEmit
npm test
```
Fix any errors before continuing.

**Commit and push Worker A:**
```bash
git add src/middleware/auth.ts src/routes/products.ts src/routes/inventory.ts src/routes/checkout.ts src/index.ts
git commit -m "[SEC] Security hardening: validation, auth, helmet, rate-limit (#9 #10 #11 #12)"
git push -u origin fix/sec-validation-hardening
gh pr create --title "[SEC] Security hardening: validation, auth, helmet, rate-limit (#9 #10 #11 #12)" --body "Closes #9, #10, #11, #12

- SEC-001: express-validator on POST /api/products (422 on invalid input)
- SEC-002: requireAuth middleware on /api/inventory/adjust and /api/checkout
- SEC-003: helmet() security headers
- INF-002: express-rate-limit (100 req/15 min) on /api/products"
```

Note the PR number. Then:
```bash
git checkout main
```

---

## PHASE 3 — Worker B: Infrastructure & Observability (branch fix/infra-observability)

```bash
git checkout -b fix/infra-observability
```

**LOG-001** — Create `src/utils/logger.ts`:
```typescript
type LogLevel = 'info' | 'warn' | 'error';

function log(level: LogLevel, msg: string, meta?: object): void {
  const entry = JSON.stringify({ level, msg, ...(meta ? { meta } : {}), ts: new Date().toISOString() });
  if (level === 'error') { process.stderr.write(entry + '\n'); } else { process.stdout.write(entry + '\n'); }
}

export const logger = {
  info: (msg: string, meta?: object) => log('info', msg, meta),
  warn: (msg: string, meta?: object) => log('warn', msg, meta),
  error: (msg: string, meta?: object) => log('error', msg, meta),
};
```

**INF-001 + LOG-001** — Replace `src/index.ts`:
```typescript
import express from 'express';
import dotenv from 'dotenv';
import productRoutes from './routes/products';
import inventoryRoutes from './routes/inventory';
import checkoutRoutes from './routes/checkout';
import orderRoutes from './routes/orders';
import { errorHandler } from './middleware/error-handler';
import { seedProducts } from './services/product-service';
import { logger } from './utils/logger';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());

app.get('/api/health', (_req, res) => {
  res.json({ status: 'ok', uptime: process.uptime(), timestamp: new Date().toISOString() });
});

app.use('/api/products', productRoutes);
app.use('/api/inventory', inventoryRoutes);
app.use('/api/checkout', checkoutRoutes);
app.use('/api/orders', orderRoutes);

app.use(errorHandler);
seedProducts();

app.listen(PORT, () => { logger.info(`Retail extension running on port ${PORT}`); });

export default app;
```

**LOG-001 continued** — Replace `src/routes/inventory.ts`:
```typescript
import { Router, Request, Response } from 'express';
import { getAllProducts, getProductById, updateProductStock } from '../services/product-service';
import { logger } from '../utils/logger';

const router = Router();

router.get('/', (_req: Request, res: Response) => {
  const products = getAllProducts();
  const inventory = products.map(p => ({
    productId: p.id, sku: p.sku, quantityOnHand: p.stock,
    quantityReserved: 0, quantityAvailable: p.stock, reorderPoint: 10, lastUpdated: p.updatedAt,
  }));
  res.json({ data: inventory });
});

router.post('/adjust', (req: Request, res: Response) => {
  const { productId, adjustment, reason } = req.body;
  const product = getProductById(productId);
  if (!product) return res.status(404).json({ error: 'Product not found' });
  const updated = updateProductStock(productId, adjustment);
  logger.info('Inventory adjusted', { reason, productId, adjustment });
  res.json({ data: updated });
});

export default router;
```

Replace `src/middleware/error-handler.ts`:
```typescript
import { Request, Response, NextFunction } from 'express';
import { logger } from '../utils/logger';

export function errorHandler(err: Error, _req: Request, res: Response, _next: NextFunction): void {
  logger.error(err.message, { stack: err.stack });
  res.status(500).json({ error: 'Internal server error' });
}
```

**TST-001** — Create `tests/unit/order-service.test.ts`:
```typescript
import { createOrder, getOrderById, updateOrderStatus } from '../../src/services/order-service';
import { seedProducts, getAllProducts } from '../../src/services/product-service';

beforeEach(() => { seedProducts(); });

describe('order-service', () => {
  describe('createOrder', () => {
    it('returns error when product not found', () => {
      const r = createOrder({ customerId: 'c1', items: [{ productId: 'bad', quantity: 1 }] });
      expect('error' in r).toBe(true);
    });
    it('creates order with correct totals', () => {
      const p = getAllProducts()[0];
      const r = createOrder({ customerId: 'c2', items: [{ productId: p.id, quantity: 1 }] });
      expect('error' in r).toBe(false);
      if (!('error' in r)) { expect(r.totalAmount).toBe(p.price); expect(r.status).toBe('pending'); }
    });
    it('returns error when stock insufficient', () => {
      const p = getAllProducts()[0];
      const r = createOrder({ customerId: 'c3', items: [{ productId: p.id, quantity: 99999 }] });
      expect('error' in r).toBe(true);
    });
  });
  describe('updateOrderStatus', () => {
    it('returns null for unknown id', () => { expect(updateOrderStatus('x', 'confirmed')).toBeNull(); });
    it('updates status on known order', () => {
      const p = getAllProducts()[0];
      const r = createOrder({ customerId: 'c4', items: [{ productId: p.id, quantity: 1 }] });
      if (!('error' in r)) {
        const u = updateOrderStatus(r.id, 'confirmed');
        expect(u?.status).toBe('confirmed');
      }
    });
  });
  describe('getOrderById', () => {
    it('returns undefined for unknown id', () => { expect(getOrderById('x')).toBeUndefined(); });
  });
});
```

**ARCH-001** — Delete legacy:
```bash
grep -r "legacy" src/ --include="*.ts" -l || echo "no imports found"
rm -rf src/legacy/
```

**Verify Worker B:**
```bash
npx tsc --noEmit
npm test
```
Fix any errors before continuing.

**Commit and push Worker B:**
```bash
git add src/utils/logger.ts src/index.ts src/routes/inventory.ts src/middleware/error-handler.ts tests/unit/order-service.test.ts
git rm -r src/legacy/
git commit -m "[INF] Infrastructure & observability: health, logging, tests, arch cleanup (#13 #14 #15 #16)"
git push -u origin fix/infra-observability
gh pr create --title "[INF] Infrastructure & observability: health, logging, tests, arch cleanup (#13 #14 #15 #16)" --body "Closes #13, #14, #15, #16

- INF-001: GET /api/health endpoint
- LOG-001: src/utils/logger.ts, replaced all console.log/error
- TST-001: tests/unit/order-service.test.ts (6 tests)
- ARCH-001: deleted src/legacy/"
```

Note the PR number. Then:
```bash
git checkout main
```

---

## PHASE 4 — Review and merge

For each PR (Worker A first, then Worker B):

1. Check it out and verify:
```bash
gh pr checkout <number>
npx tsc --noEmit
npm test
```

2. If Worker B conflicts with Worker A after merge, rebase:
```bash
git rebase main
# resolve any conflicts in src/index.ts: keep helmet+rate-limit from Worker A, add health endpoint and logger from Worker B
git rebase --continue
git push --force-with-lease origin fix/infra-observability
```

3. Merge:
```bash
git checkout main
gh pr merge <number> --squash --admin --delete-branch
git pull
```

---

## PHASE 5 — Close issues and report

```bash
gh issue close 9 10 11 12 13 14 15 16 --comment "Fixed and merged to main."
```

Print a final table:
- Issues #9–16 closed ✓
- PR [SEC] merged ✓
- PR [INF] merged ✓
- All N tests passing ✓
