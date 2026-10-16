import { m } from '#lib/paraglide/messages.js';

/** Closed-beta demo listings: shown with a label, cannot be contacted, applied for or booked. */
export const isDemo = (l: { is_demo?: boolean } | null | undefined): boolean => l?.is_demo === true;

/** Map marker text: the price, prefixed with the short demo label for demo listings. */
export function markerLabel(price: string, demo: boolean): string {
	return demo ? `${m.listing_demo_short()} · ${price}` : price;
}
