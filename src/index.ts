import express from 'express';
import dotenv from 'dotenv';
import productRoutes from './routes/products';
import inventoryRoutes from './routes/inventory';
import checkoutRoutes from './routes/checkout';
import orderRoutes from './routes/orders';
import { errorHandler } from './middleware/error-handler';
import { seedProducts } from './services/product-service';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

// NO helmet — missing security headers (intentional gap)
// NO rate limiting — intentional gap
// NO request ID middleware — intentional gap
app.use(express.json());

app.use('/api/products', productRoutes);
app.use('/api/inventory', inventoryRoutes);
app.use('/api/checkout', checkoutRoutes);
app.use('/api/orders', orderRoutes);

// NO health check endpoint — intentional gap (required for production)
app.use(errorHandler);

seedProducts();

app.listen(PORT, () => {
  console.log(`Retail extension running on port ${PORT}`);
});

export default app;
