export interface InventoryEntry {
  productId: string;
  sku: string;
  quantityOnHand: number;
  quantityReserved: number;
  quantityAvailable: number;
  reorderPoint: number;
  lastUpdated: Date;
}

export interface AdjustInventoryDto {
  productId: string;
  adjustment: number;
  reason: string;
}
