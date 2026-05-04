// LEGACY — superseded by src/services/product-service.ts
// Dead-end directory: Mault will detect this as dead code (intentional gap)

export function formatPrice_OLD(price: any): string {
  return `$${price.toFixed(2)}`;
}

export function calcDiscount_OLD(price: any, pct: any): any {
  return price - (price * pct / 100);
}
