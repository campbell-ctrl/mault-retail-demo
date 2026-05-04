import { v4 as uuidv4 } from 'uuid';
import { Order, CreateOrderDto, OrderItem, OrderStatus } from '../models/order';
import { getProductById, updateProductStock } from './product-service';

const orders: Map<string, Order> = new Map();

export function getOrderById(id: string): Order | undefined {
  return orders.get(id);
}

export function getOrdersByCustomer(customerId: string): Order[] {
  return Array.from(orders.values()).filter(o => o.customerId === customerId);
}

export function createOrder(dto: CreateOrderDto): Order | { error: string } {
  const items: OrderItem[] = [];
  let totalAmount = 0;
  let totalLoyaltyPoints = 0;

  for (const lineItem of dto.items) {
    const product = getProductById(lineItem.productId);
    if (!product) return { error: `Product ${lineItem.productId} not found` };
    if (product.stock < lineItem.quantity) {
      return { error: `Insufficient stock for ${product.sku}` };
    }
    const lineTotal = product.price * lineItem.quantity;
    const linePoints = product.loyaltyPoints * lineItem.quantity;
    items.push({
      productId: product.id,
      sku: product.sku,
      quantity: lineItem.quantity,
      unitPrice: product.price,
      loyaltyPointsEarned: linePoints,
    });
    totalAmount += lineTotal;
    totalLoyaltyPoints += linePoints;
  }

  // Reserve stock
  for (const item of items) {
    updateProductStock(item.productId, -item.quantity);
  }

  const order: Order = {
    id: uuidv4(),
    customerId: dto.customerId,
    items,
    totalAmount,
    totalLoyaltyPoints,
    status: 'pending',
    createdAt: new Date(),
    updatedAt: new Date(),
  };

  orders.set(order.id, order);
  return order;
}

export function updateOrderStatus(id: string, status: OrderStatus): Order | null {
  const order = orders.get(id);
  if (!order) return null;
  order.status = status;
  order.updatedAt = new Date();
  orders.set(id, order);
  return order;
}
