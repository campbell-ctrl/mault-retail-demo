import { getAllProducts, getProductById, createProduct, seedProducts } from '../../src/services/product-service';

beforeEach(() => {
  seedProducts();
});

describe('product-service', () => {
  it('returns all seeded products', () => {
    const products = getAllProducts();
    expect(products.length).toBeGreaterThan(0);
  });

  it('creates a product and retrieves it by id', () => {
    const created = createProduct({
      sku: 'TEST-001',
      name: 'Test Product',
      price: 50,
      category: 'test',
      stock: 10,
    });
    const found = getProductById(created.id);
    expect(found).toBeDefined();
    expect(found?.sku).toBe('TEST-001');
  });

  it('returns undefined for unknown id', () => {
    expect(getProductById('does-not-exist')).toBeUndefined();
  });

  // Missing: tests for updateProductStock, getProductBySku (intentional gap — agents will add)
});
