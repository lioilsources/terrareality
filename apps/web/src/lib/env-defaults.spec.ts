import { describe, expect, it } from 'vitest';
import {
	LOCAL_DEFAULTS,
	assertProductionEnv,
	missingProductionVars,
	strictEnv,
	withLocalDefault
} from './env-defaults';

describe('env defaults', () => {
	it('falls back to localhost defaults for unset values', () => {
		expect(withLocalDefault('CSP_MEDIA_ORIGINS', undefined)).toBe(LOCAL_DEFAULTS.CSP_MEDIA_ORIGINS);
		expect(withLocalDefault('API_URL', 'http://api:8080')).toBe('http://api:8080');
		expect(() => assertProductionEnv({ NODE_ENV: 'development' })).not.toThrow();
	});

	it('fails production startup and lists every missing variable', () => {
		const env = { NODE_ENV: 'production', API_URL: 'http://api:8080' };
		expect(missingProductionVars(env)).toEqual([
			'API_PUBLIC_URL',
			'CSP_MEDIA_ORIGINS',
			'CSP_REALTIME_ORIGIN'
		]);
		expect(() => assertProductionEnv(env)).toThrow(
			/API_PUBLIC_URL, CSP_MEDIA_ORIGINS, CSP_REALTIME_ORIGIN/
		);
		expect(() =>
			assertProductionEnv({
				NODE_ENV: 'production',
				API_URL: 'http://api:8080',
				API_PUBLIC_URL: 'https://api.example',
				CSP_MEDIA_ORIGINS: 'https://img.example',
				CSP_REALTIME_ORIGIN: 'wss://app.example'
			})
		).not.toThrow();
	});

	it('lets a local production preview opt in to localhost defaults', () => {
		const env = { NODE_ENV: 'production', ALLOW_LOCALHOST_DEFAULTS: '1' };
		expect(strictEnv(env)).toBe(false);
		expect(() => assertProductionEnv(env)).not.toThrow();
	});
});
