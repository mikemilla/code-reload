import {NativeModules, NativeEventEmitter} from 'react-native';
import {projectStore} from './store/ProjectStore';
import type {AiModel} from './ai/models';

const {CodeReloadModule} = NativeModules as {
  CodeReloadModule?: {
    initialize(): void;
    requestSync(): void;
    bootstrap(files: Record<string, string>, hash: string): void;
    configureAgent(config: {
      apiKey: string;
      provider: string;
      model: string;
      maxTokens?: number;
    }): void;
    onRuntimeError(message: string): void;
  };
};

interface CodeReloadEvent {
  type: string;
  payload?: any;
}

let emitter: NativeEventEmitter | null = null;
let initialized = false;

/// Subscribe to native -> JS events: native pushes the file set and reload
/// signals; the thin JS runtime reacts by re-evaluating the preview.
export function initBridge() {
  if (initialized || !CodeReloadModule) return;
  initialized = true;

  emitter = new NativeEventEmitter(CodeReloadModule as any);
  emitter.addListener('CodeReloadEvent', (event: CodeReloadEvent) => {
    switch (event.type) {
      case 'setFiles': {
        const files = event.payload?.files ?? {};
        if (Object.keys(files).length > 0) {
          projectStore.setFilesFromNative(files);
        }
        break;
      }
      case 'reload':
        projectStore.reload();
        break;
    }
  });

  installGlobalErrorHandler();
  try {
    CodeReloadModule.initialize();
    CodeReloadModule.requestSync?.();
  } catch (e) {
    console.warn('code-reload: native init failed', e);
  }
}

/// Forward uncaught JS errors to native so the editor/agent can react, and so
/// user-JS crashes never take down the process while CodeReload is mounted.
function installGlobalErrorHandler() {
  const g: any = global;
  if (!g.ErrorUtils || g.__codeReloadHandlerInstalled) return;
  g.__codeReloadHandlerInstalled = true;
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
  CodeReloadModule?.bootstrap(files, hashFiles(files));
}

export function configureAgent(config: {
  apiKey: string;
  model?: AiModel;
}) {
  CodeReloadModule?.configureAgent({
    apiKey: config.apiKey,
    provider: config.model?.provider ?? 'anthropic',
    model: config.model?.id ?? 'claude-sonnet-4-20250514',
    maxTokens: 4096,
  });
}

/// JS -> native: report an uncaught render/eval error in the preview.
export function reportRuntimeError(message: string) {
  CodeReloadModule?.onRuntimeError(message);
}

export const isNativeAvailable = !!CodeReloadModule;

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
