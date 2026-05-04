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
