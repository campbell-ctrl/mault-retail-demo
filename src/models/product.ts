export interface Product {
  id: string;
  sku: string;
  name: string;
  price: number;
  category: string;
  stock: number;
  loyaltyPoints: number;
  createdAt: Date;
  updatedAt: Date;
}

export interface CreateProductDto {
  sku: string;
  name: string;
  price: number;
  category: string;
  stock: number;
  loyaltyPoints?: number;
}
