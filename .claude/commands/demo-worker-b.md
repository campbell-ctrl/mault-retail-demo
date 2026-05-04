You are Worker B for the Mault retail extension demo. Fix INF-001, LOG-001, TST-001, ARCH-001. Do not spawn sub-agents. Do not invoke skills. Use Bash, Read, Write, Edit tools directly.

Print at start:
```
══ WORKER B: INFRASTRUCTURE & OBSERVABILITY ══
Assigned: INF-001 LOG-001 TST-001 ARCH-001
Branch: fix/infra-observability
```

## Setup
```bash
git checkout main
git checkout -b fix/infra-observability
```

## LOG-001 — Structured logger

Create `src/utils/logger.ts`:
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
Print: `✓ LOG-001 logger created`

## INF-001 + LOG-001 — Health endpoint + replace console calls

Write `src/index.ts`:
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

Write `src/routes/inventory.ts`:
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

Write `src/middleware/error-handler.ts`:
```typescript
import { Request, Response, NextFunction } from 'express';
import { logger } from '../utils/logger';

export function errorHandler(err: Error, _req: Request, res: Response, _next: NextFunction): void {
  logger.error(err.message, { stack: err.stack });
  res.status(500).json({ error: 'Internal server error' });
}
```
Print: `✓ INF-001 + LOG-001 done`

## TST-001 — Order service tests

Create `tests/unit/order-service.test.ts`:
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
      if (!('error' in r)) { expect(updateOrderStatus(r.id, 'confirmed')?.status).toBe('confirmed'); }
    });
  });
  describe('getOrderById', () => {
    it('returns undefined for unknown id', () => { expect(getOrderById('x')).toBeUndefined(); });
  });
});
```
Print: `✓ TST-001 done`

## ARCH-001 — Delete legacy

```bash
grep -r "legacy" src/ --include="*.ts" -l || echo "no imports — safe to delete"
rm -rf src/legacy/
```
Print: `✓ ARCH-001 done`

## Verify and ship

```bash
npx tsc --noEmit
npm test
```

If any errors, fix them before continuing.

```bash
git add src/utils/logger.ts src/index.ts src/routes/inventory.ts src/middleware/error-handler.ts tests/unit/order-service.test.ts
git rm -r src/legacy/
git commit -m "[INF] Infrastructure & observability: health, logging, tests, arch cleanup (#13 #14 #15 #16)"
git push -u origin fix/infra-observability
gh pr create --title "[INF] Infrastructure & observability: health, logging, tests, arch cleanup (#13 #14 #15 #16)" --body "Closes #13, #14, #15, #16

- INF-001: GET /api/health endpoint
- LOG-001: src/utils/logger.ts, replaced all console.log/error
- TST-001: 6 new tests for order-service
- ARCH-001: deleted src/legacy/"
git checkout main
```

Print: `✓ WORKER B DONE — PR open, waiting for Review Agent`
