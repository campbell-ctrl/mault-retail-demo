import { Router, Request, Response } from 'express';
import { getOrderById, getOrdersByCustomer, updateOrderStatus } from '../services/order-service';
import { OrderStatus } from '../models/order';

const router = Router();

// NO auth — any caller can read any customer's orders (intentional gap)
router.get('/customer/:customerId', (req: Request, res: Response) => {
  const orders = getOrdersByCustomer(req.params.customerId);
  res.json({ data: orders, count: orders.length });
});

router.get('/:id', (req: Request, res: Response) => {
  const order = getOrderById(req.params.id);
  if (!order) {
    return res.status(404).json({ error: 'Order not found' });
  }
  res.json({ data: order });
});

// NO validation that status is a valid OrderStatus value (intentional gap)
router.patch('/:id/status', (req: Request, res: Response) => {
  const updated = updateOrderStatus(req.params.id, req.body.status as OrderStatus);
  if (!updated) {
    return res.status(404).json({ error: 'Order not found' });
  }
  res.json({ data: updated });
});

export default router;
