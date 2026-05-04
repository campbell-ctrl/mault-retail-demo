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
