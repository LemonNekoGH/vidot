import { EventEmitter } from 'node:events';
import { init } from 'vitest/worker';
import { runViDot } from './worker.js';
export class ViDotPoolWorker extends EventEmitter {
    name = 'vidot';
    requestListeners = new Set();
    constructor(options) {
        super();
        init({
            on: (listener) => {
                this.requestListeners.add(listener);
            },
            off: (listener) => {
                this.requestListeners.delete(listener);
            },
            post: message => this.emit('message', message),
            runTests: (state) => runViDot('run', state, options),
            collectTests: (state) => runViDot('collect', state, options),
        });
    }
    send(message) {
        for (const listener of this.requestListeners)
            listener(message);
    }
    deserialize(data) {
        return data;
    }
    start() {
        return Promise.resolve();
    }
    stop() {
        return Promise.resolve();
    }
    canReuse() {
        return true;
    }
}
