import { Router, Request, Response } from 'express';
import { createOrder } from '../services/order-service';

const router = Router();

// NO auth middleware — checkout should require authenticated customer (intentional gap)
// NO idempotency key — double-submit could create duplicate orders (intentional gap)
router.post('/', (req: Request, res: Response) => {
  const result = createOrder(req.body);

  if ('error' in result) {
    return res.status(400).json({ error: result.error });
  }

  res.status(201).json({ data: result });
});

export default router;
