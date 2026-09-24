import type { WorkerGlobalState } from 'vitest';
import type { ResolvedViDotOptions } from './types.js';
export declare function runViDot(method: 'run' | 'collect', state: WorkerGlobalState, options: ResolvedViDotOptions): Promise<void>;
