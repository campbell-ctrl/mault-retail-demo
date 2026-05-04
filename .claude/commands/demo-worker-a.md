You are Worker A for the Mault retail extension demo. Fix SEC-001, SEC-002, SEC-003, INF-002. Do not spawn sub-agents. Do not invoke skills. Use Bash, Read, Write, Edit tools directly.

Print at start:
```
══ WORKER A: SECURITY & VALIDATION ══
Assigned: SEC-001 SEC-002 SEC-003 INF-002
Branch: fix/sec-validation-hardening
```

## Setup
```bash
git checkout main
git checkout -b fix/sec-validation-hardening
```

## SEC-001 — Input validation on POST /api/products

Write `src/routes/products.ts`:
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
Print: `✓ SEC-001 done`

## SEC-002 — Auth middleware

Create `src/middleware/auth.ts`:
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

Read `src/routes/inventory.ts`. Add `import { requireAuth } from '../middleware/auth';` at the top. Change `router.post('/adjust', (req` to `router.post('/adjust', requireAuth, (req`.

Read `src/routes/checkout.ts`. Add `import { requireAuth } from '../middleware/auth';` at the top. Change `router.post('/', (req` to `router.post('/', requireAuth, (req`.

Print: `✓ SEC-002 done`

## SEC-003 + INF-002 — Helmet and rate limiting

Write `src/index.ts`:
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
Print: `✓ SEC-003 + INF-002 done`

## Verify and ship

```bash
npx tsc --noEmit
npm test
```

If any errors, fix them before continuing.

```bash
git add src/middleware/auth.ts src/routes/products.ts src/routes/inventory.ts src/routes/checkout.ts src/index.ts
git commit -m "[SEC] Security hardening: validation, auth, helmet, rate-limit (#9 #10 #11 #12)"
git push -u origin fix/sec-validation-hardening
gh pr create --title "[SEC] Security hardening: validation, auth, helmet, rate-limit (#9 #10 #11 #12)" --body "Closes #9, #10, #11, #12

- SEC-001: express-validator on POST /api/products (422 on invalid input)
- SEC-002: requireAuth middleware on /inventory/adjust and /checkout
- SEC-003: helmet() security headers
- INF-002: express-rate-limit 100 req/15min on /api/products"
git checkout main
```

Print: `✓ WORKER A DONE — PR open, waiting for Review Agent`
