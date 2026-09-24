import type { PoolWorker, WorkerRequest } from 'vitest/node';
import type { ResolvedViDotOptions } from './types.js';
import { EventEmitter } from 'node:events';
export declare class ViDotPoolWorker extends EventEmitter implements PoolWorker {
    readonly name = "vidot";
    private readonly requestListeners;
    constructor(options: ResolvedViDotOptions);
    send(message: WorkerRequest): void;
    deserialize(data: unknown): unknown;
    start(): Promise<void>;
    stop(): Promise<void>;
    canReuse(): boolean;
}
