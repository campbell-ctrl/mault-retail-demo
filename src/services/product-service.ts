import { v4 as uuidv4 } from 'uuid';
import { Product, CreateProductDto } from '../models/product';

// In-memory store for demo — would be a DB in production
const products: Map<string, Product> = new Map();

export function getAllProducts(): Product[] {
  return Array.from(products.values());
}

export function getProductById(id: string): Product | undefined {
  return products.get(id);
}

export function getProductBySku(sku: string): Product | undefined {
  return Array.from(products.values()).find(p => p.sku === sku);
}

export function createProduct(dto: CreateProductDto): Product {
  const product: Product = {
    id: uuidv4(),
    sku: dto.sku,
    name: dto.name,
    price: dto.price,
    category: dto.category,
    stock: dto.stock,
    loyaltyPoints: dto.loyaltyPoints ?? Math.floor(dto.price),
    createdAt: new Date(),
    updatedAt: new Date(),
  };
  products.set(product.id, product);
  return product;
}

export function updateProductStock(id: string, delta: number): Product | null {
  const product = products.get(id);
  if (!product) return null;
  product.stock = Math.max(0, product.stock + delta);
  product.updatedAt = new Date();
  products.set(id, product);
  return product;
}

export function seedProducts(): void {
  const seeds: CreateProductDto[] = [
    { sku: 'SHIRT-BLK-M', name: 'Black Oxford Shirt (M)', price: 79.99, category: 'apparel', stock: 42 },
    { sku: 'JEAN-BLU-32', name: 'Slim Fit Jeans 32W', price: 119.99, category: 'apparel', stock: 28 },
    { sku: 'SHOE-WHT-10', name: 'White Canvas Sneakers 10', price: 149.99, category: 'footwear', stock: 15 },
    { sku: 'BAG-TAN-001', name: 'Tan Leather Tote', price: 249.99, category: 'accessories', stock: 8 },
    { sku: 'CAP-NVY-001', name: 'Navy Wool Cap', price: 39.99, category: 'accessories', stock: 60 },
  ];
  seeds.forEach(createProduct);
}
