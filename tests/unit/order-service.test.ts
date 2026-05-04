import { createOrder, getOrderById, updateOrderStatus } from '../../src/services/order-service';
import { seedProducts } from '../../src/services/product-service';

beforeEach(() => {
  seedProducts();
});

describe('order-service', () => {
  describe('createOrder', () => {
    it('returns an error when a product does not exist', () => {
      const result = createOrder({ customerId: 'cust-1', items: [{ productId: 'nonexistent', quantity: 1 }] });
      expect('error' in result).toBe(true);
      if ('error' in result) {
        expect(result.error).toMatch(/not found/i);
      }
    });

    it('creates an order and calculates totals correctly', () => {
      const products = require('../../src/services/product-service').getAllProducts();
      const product = products[0];

      const result = createOrder({ customerId: 'cust-2', items: [{ productId: product.id, quantity: 1 }] });
      expect('error' in result).toBe(false);
      if (!('error' in result)) {
        expect(result.customerId).toBe('cust-2');
        expect(result.totalAmount).toBe(product.price);
        expect(result.status).toBe('pending');
        expect(result.items).toHaveLength(1);
      }
    });

    it('returns an error when stock is insufficient', () => {
      const products = require('../../src/services/product-service').getAllProducts();
      const product = products[0];

      const result = createOrder({ customerId: 'cust-3', items: [{ productId: product.id, quantity: 99999 }] });
      expect('error' in result).toBe(true);
      if ('error' in result) {
        expect(result.error).toMatch(/insufficient stock/i);
      }
    });
  });

  describe('updateOrderStatus', () => {
    it('returns null for an unknown order id', () => {
      const result = updateOrderStatus('no-such-id', 'confirmed');
      expect(result).toBeNull();
    });

    it('updates the status of an existing order', () => {
      const products = require('../../src/services/product-service').getAllProducts();
      const product = products[0];
      const created = createOrder({ customerId: 'cust-4', items: [{ productId: product.id, quantity: 1 }] });
      expect('error' in created).toBe(false);
      if (!('error' in created)) {
        const updated = updateOrderStatus(created.id, 'confirmed');
        expect(updated).not.toBeNull();
        expect(updated?.status).toBe('confirmed');
      }
    });
  });

  describe('getOrderById', () => {
    it('returns undefined for unknown id', () => {
      expect(getOrderById('missing')).toBeUndefined();
    });
  });
});
