import { Centrifuge, type PublicationContext, type Subscription } from 'centrifuge';
import type { Message } from '@terra/contracts';

/** Events the api publishes to conversation and user channels. */
export type RealtimeEvent =
	| { type: 'message'; conversation_id: string; message: Message }
	| { type: 'read'; conversation_id: string; user_id: string; role: 'seeker' | 'owner'; at: string }
	| { type: 'blocked' | 'removed'; conversation_id: string }
	| { type: 'notification'; id: string; conversation_id: string };

async function post<T>(url: string): Promise<T> {
	const res = await fetch(url, { method: 'POST' });
	if (!res.ok) throw new Error(`${url}: ${res.status}`);
	return (await res.json()) as T;
}

/** Delay before the n-th retry (0-based): 1 s, 2 s, 4 s … capped at 30 s, with ±20 % jitter. */
export function backoff(attempt: number, random: () => number = Math.random): number {
	const base = Math.min(30_000, 1000 * 2 ** attempt);
	return Math.round(base * (0.8 + 0.4 * random()));
}

/**
 * Connects to Centrifugo with tokens issued by the api (through this app's
 * server, which holds the session cookie). The connection joins the user's
 * own channel; `conversation` additionally subscribes to one thread. A failed
 * token request (api restart, network blip) is retried with backoff until the
 * returned cleanup runs; Centrifuge itself reconnects an established client.
 */
export function connect(opts: {
	conversation?: string;
	onEvent: (e: RealtimeEvent) => void;
	onState?: (connected: boolean) => void;
}): () => void {
	let client: Centrifuge | undefined;
	let sub: Subscription | undefined;
	let closed = false;
	let timer: ReturnType<typeof setTimeout> | undefined;
	const handle = (ctx: PublicationContext) => opts.onEvent(ctx.data as RealtimeEvent);

	const start = (attempt: number) => {
		post<{ url: string; token: string }>('/zpravy/api/token')
			.then(({ url, token }) => {
				if (closed) return;
				client = new Centrifuge(url, {
					token,
					getToken: async () => (await post<{ token: string }>('/zpravy/api/token')).token
				});
				client.on('connected', () => opts.onState?.(true));
				client.on('disconnected', () => opts.onState?.(false));
				client.on('publication', handle); // server-side user channel
				if (opts.conversation) {
					const id = opts.conversation;
					sub = client.newSubscription(`conv:${id}`, {
						getToken: async () => (await post<{ token: string }>(`/zpravy/api/${id}/token`)).token
					});
					sub.on('publication', handle);
					sub.subscribe();
				}
				client.connect();
			})
			.catch(() => {
				opts.onState?.(false);
				if (!closed) timer = setTimeout(() => start(attempt + 1), backoff(attempt));
			});
	};
	start(0);

	return () => {
		closed = true;
		clearTimeout(timer);
		if (sub) {
			sub.unsubscribe();
			client?.removeSubscription(sub);
		}
		client?.disconnect();
	};
}
