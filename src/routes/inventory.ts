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
// NO validation on adjustment value — could accept negative/NaN
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
