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
