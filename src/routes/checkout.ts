import { Router, Request, Response } from 'express';
import { createOrder } from '../services/order-service';
import { requireAuth } from '../middleware/auth';

const router = Router();

router.post('/', requireAuth, (req: Request, res: Response) => {
  const result = createOrder(req.body);

  if ('error' in result) {
    return res.status(400).json({ error: result.error });
  }

  res.status(201).json({ data: result });
});

export default router;
