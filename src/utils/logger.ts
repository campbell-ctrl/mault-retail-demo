type LogLevel = 'info' | 'warn' | 'error';

function log(level: LogLevel, msg: string, meta?: object): void {
  const entry = JSON.stringify({ level, msg, ...(meta ? { meta } : {}), ts: new Date().toISOString() });
  if (level === 'error') { process.stderr.write(entry + '\n'); } else { process.stdout.write(entry + '\n'); }
}

export const logger = {
  info: (msg: string, meta?: object) => log('info', msg, meta),
  warn: (msg: string, meta?: object) => log('warn', msg, meta),
  error: (msg: string, meta?: object) => log('error', msg, meta),
};
