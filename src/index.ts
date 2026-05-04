import express from 'express';
import dotenv from 'dotenv';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import productRoutes from './routes/products';
import inventoryRoutes from './routes/inventory';
import checkoutRoutes from './routes/checkout';
import orderRoutes from './routes/orders';
import { errorHandler } from './middleware/error-handler';
import { seedProducts } from './services/product-service';
import { logger } from './utils/logger';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

app.use(helmet());
app.use(express.json());

app.get('/api/health', (_req, res) => {
  res.json({ status: 'ok', uptime: process.uptime(), timestamp: new Date().toISOString() });
});

const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
  standardHeaders: true,
  legacyHeaders: false,
});

app.use('/api/products', apiLimiter, productRoutes);
app.use('/api/inventory', inventoryRoutes);
app.use('/api/checkout', checkoutRoutes);
app.use('/api/orders', orderRoutes);

app.use(errorHandler);

seedProducts();

app.listen(PORT, () => {
  logger.info(`Retail extension running on port ${PORT}`);
});

export default app;
