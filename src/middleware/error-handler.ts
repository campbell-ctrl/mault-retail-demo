import { Request, Response, NextFunction } from 'express';

// Incomplete — does not distinguish operational vs programmer errors (intentional gap)
export function errorHandler(err: Error, _req: Request, res: Response, _next: NextFunction): void {
  console.error(err.stack);
  res.status(500).json({ error: 'Internal server error' });
}
