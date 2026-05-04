#!/bin/bash
# ─────────────────────────────────────────────────────────────────
#  Mault Demo Reset — run before every demo
#  Restores all intentional gaps and reopens GitHub issues
#  Usage: bash demo-reset.sh
# ─────────────────────────────────────────────────────────────────
set -e
DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DIR"

G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; B='\033[1m'; N='\033[0m'
ok()   { echo -e "${G}✓  $1${N}"; }
warn() { echo -e "${Y}⚠  $1${N}"; }
hdr()  { echo -e "\n${B}$1${N}"; }

hdr "Mault Demo Reset"
echo "────────────────────────────────────────────────────────────────"

# ── 1. Stash any local work ───────────────────────────────────────
if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
  git stash push -m "demo-autostash-$(date +%s)" --quiet
  warn "Stashed local changes (restore with: git stash pop)"
fi
git checkout main --quiet
git pull --ff-only --quiet 2>/dev/null || true
ok "On main, up to date"

# ── 2. Close stale PRs from previous demo runs ───────────────────
for branch in fix/sec-validation-hardening fix/infra-observability; do
  PR=$(gh pr list --head "$branch" --state open --json number -q '.[0].number' 2>/dev/null || true)
  if [ -n "$PR" ]; then
    gh pr close "$PR" --delete-branch 2>/dev/null && warn "Closed leftover PR #$PR ($branch)" || true
  fi
  # delete local branch if it exists
  git branch -D "$branch" 2>/dev/null || true
  # delete remote branch if it exists
  git push origin --delete "$branch" 2>/dev/null || true
done

# ── 3. Restore broken source files ───────────────────────────────
hdr "Restoring intentional gaps..."

# Remove files added by fix branches
rm -f src/middleware/auth.ts
rm -f src/utils/logger.ts
rm -f tests/unit/order-service.test.ts

# Re-create src/legacy/ dead-end directory
mkdir -p src/legacy
cat > src/legacy/old-product-helpers.ts << 'LEGACY'
// LEGACY — superseded by src/services/product-service.ts
// Dead-end directory: Mault will detect this as dead code (intentional gap)

export function formatPrice_OLD(price: any): string {
  return `$${price.toFixed(2)}`;
}

export function calcDiscount_OLD(price: any, pct: any): any {
  return price - (price * pct / 100);
}
LEGACY

# Restore src/index.ts — no helmet, no rate limiting, no health check
cat > src/index.ts << 'INDEXTS'
import express from 'express';
import dotenv from 'dotenv';
import productRoutes from './routes/products';
import inventoryRoutes from './routes/inventory';
import checkoutRoutes from './routes/checkout';
import orderRoutes from './routes/orders';
import { errorHandler } from './middleware/error-handler';
import { seedProducts } from './services/product-service';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

// NO helmet — missing security headers (intentional gap)
// NO rate limiting — intentional gap
app.use(express.json());

app.use('/api/products', productRoutes);
app.use('/api/inventory', inventoryRoutes);
app.use('/api/checkout', checkoutRoutes);
app.use('/api/orders', orderRoutes);

// NO health check endpoint — intentional gap
app.use(errorHandler);

seedProducts();

app.listen(PORT, () => {
  console.log(`Retail extension running on port ${PORT}`);
});

export default app;
INDEXTS

# Restore src/routes/products.ts — no validation
cat > src/routes/products.ts << 'PRODUCTSTS'
import { Router, Request, Response } from 'express';
import { getAllProducts, getProductById, createProduct } from '../services/product-service';

const router = Router();

// NO input validation — intentional gap for Mault Production Readiness demo
// NO rate limiting — intentional gap
router.get('/', (_req: Request, res: Response) => {
  const products = getAllProducts();
  res.json({ data: products, count: products.length });
});

router.get('/:id', (req: Request, res: Response) => {
  const product = getProductById(req.params.id);
  if (!product) {
    return res.status(404).json({ error: 'Product not found' });
  }
  res.json({ data: product });
});

// NO validation on body fields — intentional gap
router.post('/', (req: Request, res: Response) => {
  const product = createProduct(req.body);
  res.status(201).json({ data: product });
});

export default router;
PRODUCTSTS

# Restore src/routes/inventory.ts — no auth, console.log
cat > src/routes/inventory.ts << 'INVENTORYTS'
import { Router, Request, Response } from 'express';
import { getAllProducts, getProductById, updateProductStock } from '../services/product-service';

const router = Router();

router.get('/', (_req: Request, res: Response) => {
  const products = getAllProducts();
  const inventory = products.map(p => ({
    productId: p.id,
    sku: p.sku,
    quantityOnHand: p.stock,
    quantityReserved: 0,
    quantityAvailable: p.stock,
    reorderPoint: 10,
    lastUpdated: p.updatedAt,
  }));
  res.json({ data: inventory });
});

// NO auth check — protected route with no auth middleware (intentional gap)
router.post('/adjust', (req: Request, res: Response) => {
  const { productId, adjustment, reason } = req.body;
  const product = getProductById(productId);
  if (!product) {
    return res.status(404).json({ error: 'Product not found' });
  }
  const updated = updateProductStock(productId, adjustment);
  console.log(`Inventory adjusted: ${reason}`); // NO structured logging — intentional gap
  res.json({ data: updated });
});

export default router;
INVENTORYTS

# Restore src/routes/checkout.ts — no auth
cat > src/routes/checkout.ts << 'CHECKOUTTS'
import { Router, Request, Response } from 'express';
import { createOrder } from '../services/order-service';

const router = Router();

// NO auth middleware — checkout should require authenticated customer (intentional gap)
router.post('/', (req: Request, res: Response) => {
  const result = createOrder(req.body);
  if ('error' in result) {
    return res.status(400).json({ error: result.error });
  }
  res.status(201).json({ data: result });
});

export default router;
CHECKOUTTS

# Restore src/middleware/error-handler.ts — console.error
cat > src/middleware/error-handler.ts << 'ERRORHANDLER'
import { Request, Response, NextFunction } from 'express';

// Incomplete — does not distinguish operational vs programmer errors (intentional gap)
export function errorHandler(err: Error, _req: Request, res: Response, _next: NextFunction): void {
  console.error(err.stack);
  res.status(500).json({ error: 'Internal server error' });
}
ERRORHANDLER

ok "Source files restored to broken state"

# ── 4. Reopen GitHub issues ───────────────────────────────────────
hdr "Reopening GitHub issues..."
for n in 9 10 11 12 13 14 15 16; do
  STATE=$(gh issue view "$n" --json state -q '.state' 2>/dev/null || echo "UNKNOWN")
  if [ "$STATE" = "CLOSED" ]; then
    gh issue reopen "$n" --comment "Demo reset — reopened for next run." 2>/dev/null
    ok "Reopened issue #$n"
  else
    ok "Issue #$n already open"
  fi
done

# ── 5. Final check ────────────────────────────────────────────────
hdr "Verification"
npm install --silent 2>/dev/null
npx tsc --noEmit 2>/dev/null && ok "TypeScript: clean" || warn "TypeScript errors present (expected in demo state)"
npm test --silent 2>/dev/null | grep -E "passed|failed" | head -3

echo ""
echo -e "${B}════════════════════════════════════════════════════════════════${N}"
echo -e "${G}${B}  Demo reset complete. 8 issues open, code has all intentional gaps.${N}"
echo ""
echo "  Next:  open mault-demo.code-workspace in VS Code"
echo "         then type:  /project:demo"
echo -e "${B}════════════════════════════════════════════════════════════════${N}"
echo ""
