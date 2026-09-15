import { env } from 'cloudflare:workers';
export function plannerDb() {
 if (!env.DB) throw new Error('Planner database unavailable');
 return env.DB;
}
