import {NativeModules, NativeEventEmitter} from 'react-native';
import {projectStore} from './store/ProjectStore';
import type {AiModel} from './ai/models';

const {BunbuModule} = NativeModules as {
  BunbuModule?: {
    initialize(): void;
    bootstrap(files: Record<string, string>, hash: string): void;
    configureAgent(config: {
      apiKey: string;
      provider: string;
      model: string;
      maxTokens?: number;
    }): void;
    configureGitHub(clientId: string): void;
    onRuntimeError(message: string): void;
  };
};

interface BunbuEvent {
  type: string;
  payload?: any;
}

let emitter: NativeEventEmitter | null = null;
let initialized = false;

/// Subscribe to native -> JS events: native pushes the file set and reload
/// signals; the thin JS runtime reacts by re-evaluating the preview.
export function initBridge() {
  if (initialized || !BunbuModule) return;
  initialized = true;

  emitter = new NativeEventEmitter(BunbuModule as any);
  emitter.addListener('BunbuEvent', (event: BunbuEvent) => {
    switch (event.type) {
      case 'setFiles':
        projectStore.setFiles(event.payload?.files ?? {});
        break;
      case 'reload':
        projectStore.reload();
        break;
    }
  });

  installGlobalErrorHandler();
  BunbuModule.initialize();
}

/// Forward uncaught JS errors to native so the editor/agent can react, and so
/// user-JS crashes never take down the process while Bunbu is mounted.
function installGlobalErrorHandler() {
  const g: any = global;
  if (!g.ErrorUtils || g.__bunbuHandlerInstalled) return;
  g.__bunbuHandlerInstalled = true;
  const previous = g.ErrorUtils.getGlobalHandler?.();
  g.ErrorUtils.setGlobalHandler((error: any, isFatal?: boolean) => {
    try {
      reportRuntimeError(String(error?.message ?? error));
    } catch {}
    // Keep the default (dev redbox) but treat as non-fatal so we stay alive.
    previous?.(error, false);
  });
}

/// Hand the build-time bundled snapshot to native so it can seed/reconcile the
/// on-device working tree, then push the authoritative files back to us.
export function bootstrap(files: Record<string, string>) {
  BunbuModule?.bootstrap(files, hashFiles(files));
}

export function configureAgent(config: {
  apiKey: string;
  model?: AiModel;
}) {
  BunbuModule?.configureAgent({
    apiKey: config.apiKey,
    provider: config.model?.provider ?? 'anthropic',
    model: config.model?.id ?? 'claude-sonnet-4-20250514',
    maxTokens: 4096,
  });
}

export function configureGitHub(clientId: string) {
  BunbuModule?.configureGitHub(clientId);
}

/// JS -> native: report an uncaught render/eval error in the preview.
export function reportRuntimeError(message: string) {
  BunbuModule?.onRuntimeError(message);
}

export const isNativeAvailable = !!BunbuModule;

/// Stable content hash so native can detect when a rebuild shipped new code.
function hashFiles(files: Record<string, string>): string {
  const keys = Object.keys(files).sort();
  let hash = 5381;
  for (const key of keys) {
    const entry = key + '\u0000' + files[key] + '\u0001';
    for (let i = 0; i < entry.length; i++) {
      hash = ((hash << 5) + hash + entry.charCodeAt(i)) | 0;
    }
  }
  return (hash >>> 0).toString(16);
}
