import { randomUUID } from 'crypto';

const handlers = new Map();
const jobs = new Map();

let mode = 'inline';
let queue = null;
let worker = null;

export function registerHandler(name, fn) {
  handlers.set(name, fn);
}

export async function initQueue() {
  if (!process.env.REDIS_URL) {
    mode = 'inline';
    console.log('🟡 Job queue running inline (no REDIS_URL)');
    return;
  }
  try {
    const bullmq = await import('bullmq');
    queue = new bullmq.Queue('darak', { connection: process.env.REDIS_URL });
    worker = new bullmq.Worker(
      'darak',
      async (job) => {
        const fn = handlers.get(job.name);
        if (!fn) return;
        jobs.set(job.id, { name: job.name, state: 'active', progress: job.progress });
        try {
          const result = await fn(job.data, (p) => job.updateProgress(p));
          jobs.set(job.id, { name: job.name, state: 'completed', progress: 100, result });
        } catch (err) {
          console.error(`Job ${job.name} failed:`, err.message);
          jobs.set(job.id, { name: job.name, state: 'failed', error: err.message });
        }
      },
      { connection: process.env.REDIS_URL }
    );
    mode = 'redis';
    console.log('🟢 BullMQ queue connected (redis)');
  } catch (err) {
    mode = 'inline';
    console.log('🟡 BullMQ unavailable, processing inline:', err.message);
  }
}

async function runInline(name, data, jobId) {
  const fn = handlers.get(name);
  jobs.set(jobId, { name, state: 'active', progress: 5 });
  try {
    const result = await fn(data, (p) => {
      const cur = jobs.get(jobId);
      if (cur) jobs.set(jobId, { ...cur, progress: p });
    });
    jobs.set(jobId, { name, state: 'completed', progress: 100, result });
  } catch (err) {
    console.error(`Job ${name} failed:`, err.message);
    jobs.set(jobId, { name, state: 'failed', error: err.message });
  }
}

export function enqueueJob(name, data) {
  const fn = handlers.get(name);
  if (!fn) throw new Error(`No handler registered for job: ${name}`);
  if (mode === 'redis' && queue) {
    const jobId = randomUUID();
    jobs.set(jobId, { name, state: 'queued', progress: 0 });
    queue.add(name, data, { jobId });
    return { jobId, mode: 'redis' };
  }
  const jobId = randomUUID();
  jobs.set(jobId, { name, state: 'queued', progress: 0 });
  setImmediate(() => runInline(name, data, jobId));
  return { jobId, mode: 'inline' };
}

export async function processJob(name, data) {
  const fn = handlers.get(name);
  if (!fn) throw new Error(`No handler registered for job: ${name}`);
  if (mode === 'redis' && queue) {
    const job = await queue.add(name, data);
    return job.waitUntilFinished(120000, 2000);
  }
  return fn(data);
}

export function getJobStatus(jobId) {
  const job = jobs.get(jobId);
  if (!job) return null;
  return job;
}

export function getQueueMode() {
  return mode;
}
