export type OrderStatus = 'pending' | 'confirmed' | 'shipped' | 'delivered' | 'cancelled';

export interface OrderItem {
  productId: string;
  sku: string;
  quantity: number;
  unitPrice: number;
  loyaltyPointsEarned: number;
}

export interface Order {
  id: string;
  customerId: string;
  items: OrderItem[];
  totalAmount: number;
  totalLoyaltyPoints: number;
  status: OrderStatus;
  createdAt: Date;
  updatedAt: Date;
}

export interface CreateOrderDto {
  customerId: string;
  items: { productId: string; quantity: number }[];
}
